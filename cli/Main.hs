{-# LANGUAGE OverloadedStrings #-}

-- | @concept-filter@: JSON on stdin, 'Admission' as JSON on stdout.
--
-- Exit 0: nothing quarantined. Exit 2: some concept was quarantined.
-- Exit 1: the request itself is malformed (nothing is written to stdout).
module Main (main) where

import Data.Aeson
import Data.Aeson.Types (Parser, parseEither)
import qualified Data.ByteString.Lazy.Char8 as BL
import Data.Either (partitionEithers)
import Oracle.Concept.Assertion
import Oracle.Concept.Filter
import Oracle.Concept.Relation
import Oracle.Concept.Validate
import System.Exit (ExitCode (..), exitWith)
import System.IO (hPutStrLn, stderr)

-- | 'Nothing' for concepts: take every endpoint of a well-typed assertion.
data Request = Request (Maybe [String]) [Value] FilterPolicy

-- | Either @{concepts, assertions, policy?}@ or a bare assertion array (the
-- tui-story LLM shape).
request :: Value -> Parser Request
request v@(Array _) = (\claims -> Request Nothing claims defaultPolicy) <$> parseJSON v
request v =
  flip (withObject "request") v $ \o ->
    Request
      <$> (Just <$> o .: "concepts")
      <*> o .: "assertions"
      <*> (maybe (pure defaultPolicy) policy =<< o .:! "policy")

-- | Operator configuration fails closed: an unknown relation, a null field
-- (@.:!@, unlike @.:?@, does not read null as absent), or an
-- out-of-range threshold rejects the whole request.
policy :: Value -> Parser FilterPolicy
policy = withObject "policy" $ \o -> do
  threshold <- o .:! "min_certainty" .!= minimumCertainty defaultPolicy
  _ <- maybe (fail "policy.min_certainty must lie in [0, 1]") pure (certainty threshold)
  tags <- o .:! "relations" :: Parser (Maybe [String])
  admits <- maybe (pure (admitsRelation defaultPolicy)) (fmap (flip elem) . traverse relation) tags
  pure (FilterPolicy threshold admits)
 where
  relation tag = maybe (fail ("policy.relations: unknown relation " ++ show tag)) pure (parseRelation tag)

rawAssertion :: Value -> Parser RawAssertion
rawAssertion = withObject "assertion" $ \o ->
  RawAssertion
    <$> o .: "from"
    <*> o .: "to"
    <*> o .: "type"
    <*> o .: "certainty"
    <*> o .:? "description" .!= ""

-- | Per-item leniency: one malformed assertion is reported, not fatal.
typed :: Value -> Either String Assertion
typed v = either (Left . ("schema: " ++)) (either (Left . assertionErrorText) Right . fromRaw) (parseEither rawAssertion v)

conceptErrorText :: ConceptError -> String
conceptErrorText EmptyConcept = "empty"
conceptErrorText (ConceptTooLong n) = "too_long:" ++ show n
conceptErrorText NullByte = "null_byte"
conceptErrorText ControlCharacter = "control_character"

assertionErrorText :: AssertionError -> String
assertionErrorText (InvalidSource e) = "from: " ++ conceptErrorText e
assertionErrorText (InvalidTarget e) = "to: " ++ conceptErrorText e
assertionErrorText (UnknownRelation t) = "type: unknown relation " ++ show t
assertionErrorText (CertaintyOutOfRange x) = "certainty: out of range " ++ show x

assertionJSON :: Assertion -> Value
assertionJSON a =
  object
    [ "from" .= conceptText (assertionSource a)
    , "to" .= conceptText (assertionTarget a)
    , "type" .= relationTag (assertionRelation a)
    , "symbol" .= relationSymbol (assertionRelation a)
    , "certainty" .= certaintyValue (assertionCertainty a)
    , "description" .= assertionNote a
    , "derived" .= (assertionProvenance a == Derived)
    ]

admissionJSON :: [(Int, String)] -> Admission -> Value
admissionJSON rejected a =
  object
    [ "admitted" .= map conceptText (admitted a)
    , "aliases" .= [object ["alias" .= conceptText x, "canonical" .= conceptText y] | (x, y) <- aliases a]
    , "retained" .= map assertionJSON (retained a)
    , "conflicts" .=
        [ object ["pair" .= map conceptText [s, t], "relations" .= map relationTag [r, q]]
        | Conflict (s, t) (r, q) <- conflicts a
        ]
    , "quarantined" .= map conceptText (quarantined a)
    , "invalid_concepts" .= [object ["input" .= s, "error" .= conceptErrorText e] | (s, e) <- invalid a]
    , "invalid_assertions" .= [object ["index" .= i, "error" .= e] | (i, e) <- rejected]
    ]

main :: IO ()
main = do
  input <- BL.getContents
  case eitherDecode input >>= parseEither request of
    Left err -> hPutStrLn stderr ("concept-filter: " ++ err) >> exitWith (ExitFailure 1)
    Right (Request concepts claims chosen) -> do
      let (rejected, good) = partitionEithers [either (Left . (,) i) Right (typed c) | (i, c) <- zip [0 ..] claims]
          endpointTexts = [conceptText c | a <- good, c <- [assertionSource a, assertionTarget a]]
          admission = filterConcepts chosen (maybe endpointTexts id concepts) good
      BL.putStrLn (encode (admissionJSON rejected admission))
      exitWith (if null (quarantined admission) then ExitSuccess else ExitFailure 2)
