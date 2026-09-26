module Main (main) where

import Control.Exception (try)
import Data.Aeson (eitherDecode, encode)
import Data.ByteString.Char8 qualified as BS
import Data.ByteString.Lazy.Char8 qualified as LBS
import Data.Maybe (fromJust)
import Jev.Alias (Probe (..), judge, probe)
import Jev.Gate (Floor, mkFloor)
import Jev.Wire (Request, Response)
import Network.HTTP.Client qualified as HTTP
import Network.HTTP.Client.TLS (newTlsManager)
import Network.HTTP.Types (statusCode)
import Oracle.ProofGraph (ProofEdge (..), ProofNode (..))
import System.Environment (getArgs, lookupEnv)
import System.Exit (exitFailure)
import System.IO (hPutStrLn, stderr)

-- | Node ids from the domain-owned proof-graph vectors exercised in the root suite.
vectorNodes :: [ProofNode]
vectorNodes =
  [ProofNode i "claim" | i <- ["Census", "PIP census", "Lemma", "Proof", "Galois", "Conditional"]]

vectorEdges :: [ProofEdge]
vectorEdges =
  [ ProofEdge "synonymous" "PIP census" "Census" "theorem-backed" "aliases"
  , ProofEdge "implicative" "Galois" "Conditional" "open" "conditional/galois"
  ]

confidenceFloor :: Floor
confidenceFloor = fromJust (mkFloor 0.8)

main :: IO ()
main = do
  let spike = probe "jev-latest" vectorNodes
  getArgs >>= \case
    ["request"] -> LBS.putStrLn (encode (probeRequest spike))
    ["replay", path] -> LBS.readFile path >>= report spike . eitherDecode
    ["live"] -> live (probeRequest spike) >>= report spike
    _ -> die' "usage: jev-alias-spike (request | replay FILE | live)"

report :: Probe -> Either String Response -> IO ()
report spike = either die' (print . judge confidenceFloor vectorEdges spike)

-- | Single-shot POST; retries on 429/529 are deliberately left to a later
-- iteration so every transport failure stays visible in the spike.
live :: Request -> IO (Either String Response)
live body =
  lookupEnv "TYPESAFE_API_KEY" >>= \case
    Nothing -> pure (Left "TYPESAFE_API_KEY is not set")
    Just key -> do
      manager <- newTlsManager
      initial <- HTTP.parseRequest "POST https://api.typesafe.ai/v1/systemone"
      let request =
            initial
              { HTTP.requestHeaders =
                  [("Authorization", "Bearer " <> BS.pack key), ("Content-Type", "application/json")]
              , HTTP.requestBody = HTTP.RequestBodyLBS (encode body)
              }
      outcome <- try (HTTP.httpLbs request manager)
      pure $ case outcome of
        Left (failure :: HTTP.HttpException) -> Left (show failure)
        Right response -> case statusCode (HTTP.responseStatus response) of
          200 -> eitherDecode (HTTP.responseBody response)
          code -> Left ("HTTP " <> show code <> ": " <> LBS.unpack (HTTP.responseBody response))

die' :: String -> IO a
die' message = hPutStrLn stderr message >> exitFailure
