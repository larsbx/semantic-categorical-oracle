{-# LANGUAGE OverloadedStrings #-}

module Oracle.ProofGraph
  ( ProofNode (..)
  , ProofEdge (..)
  , normalizeNodes
  , normalizeEdges
  , normalizeGraph
  , normalizeGraphJson
  , canonicalEncode
  ) where

import Control.Monad (unless, when)
import Data.Aeson (Object, Value (..))
import qualified Data.Aeson as Aeson
import qualified Data.Aeson.Key as Key
import qualified Data.Aeson.KeyMap as KM
import qualified Data.ByteString.Lazy as BL
import qualified Data.ByteString.Lazy.Char8 as BL8
import Data.List (elemIndex, find, nub, sort, sortOn)
import qualified Data.Text as T
import qualified Data.Vector as V

-- | Small representation-only helpers retained for the original bounded
-- property tests. The normative contract path below operates on arbitrary
-- JSON values so no proof-record payload is lost.
data ProofNode = ProofNode
  { nodeId :: String
  , nodeKind :: String
  }
  deriving (Eq, Show, Ord)

data ProofEdge = ProofEdge
  { edgeType :: String
  , edgeSource :: String
  , edgeTarget :: String
  , edgeProvenance :: String
  , edgeUseSite :: String
  }
  deriving (Eq, Show, Ord)

normalizeNodes :: [ProofNode] -> [ProofNode]
normalizeNodes = collapseExact . sort

normalizeEdges :: [ProofEdge] -> [ProofEdge]
normalizeEdges = collapseExact . sort

collapseExact :: Eq a => [a] -> [a]
collapseExact [] = []
collapseExact (x : xs) = x : collapseExact (dropWhile (== x) xs)

data NodeInfo = NodeInfo
  { niId :: T.Text
  , niRank :: Int
  , niObject :: Object
  , niValue :: Value
  }

data EdgeInfo = EdgeInfo
  { eiRank :: Int
  , eiSource :: T.Text
  , eiTarget :: T.Text
  , eiUseSite :: T.Text
  , eiValue :: Value
  }

-- | Normalize a domain-owned finite typed relationship graph.
--
-- This function is authoritative only when the registry marks the
-- finite-proof-graph contract approved. It does not evaluate claim truth or
-- accept certificates; it validates and normalizes representation semantics.
normalizeGraph :: Value -> Either String Value
normalizeGraph (Object root) = do
  format <- fieldText root "format"
  unless (format == "finite typed relationship graph 1") $
    Left "input format is not finite typed relationship graph 1"

  edgeTypes <- fieldTextArray root "edge_types"
  provenanceClasses <- fieldTextArray root "provenance_classes"
  requireUnique "edge_types" edgeTypes
  requireUnique "provenance_classes" provenanceClasses

  nodeValues <- fieldArray root "nodes"
  nodes <- traverse (parseNode provenanceClasses) nodeValues
  let nodeIds = map niId nodes
  requireUnique "node identifiers" nodeIds

  edgeValues <- fieldArray root "edges"
  edges <- traverse (parseEdge edgeTypes provenanceClasses nodes) edgeValues

  let sortedNodes =
        map niValue $
          sortOn (\n -> (niRank n, niId n)) nodes
      sortedEdges =
        map eiValue $
          sortOn (\e -> (eiRank e, eiSource e, eiTarget e, eiUseSite e)) edges
      withoutGenerated = KM.delete "generated" root
      withNodes = KM.insert "nodes" (Array (V.fromList sortedNodes)) withoutGenerated
      withEdges = KM.insert "edges" (Array (V.fromList sortedEdges)) withNodes

  pure (Object withEdges)
normalizeGraph _ = Left "proof graph must be a JSON object"

-- | Parse, validate, normalize, and emit canonical newline-terminated JSON.
normalizeGraphJson :: BL.ByteString -> Either String BL.ByteString
normalizeGraphJson bytes = do
  input <- Aeson.eitherDecode bytes
  normalized <- normalizeGraph input
  pure (canonicalEncode normalized <> BL8.pack "\n")

parseNode :: [T.Text] -> Value -> Either String NodeInfo
parseNode provenanceClasses value@(Object obj) = do
  ident <- fieldText obj "id"
  kind <- fieldText obj "kind"
  provenance <- fieldText obj "provenance"
  unless (provenance `elem` provenanceClasses) $
    Left ("node " ++ T.unpack ident ++ " has undeclared provenance " ++ T.unpack provenance)
  rank <- kindRank kind
  pure NodeInfo
    { niId = ident
    , niRank = rank
    , niObject = obj
    , niValue = value
    }
parseNode _ _ = Left "every node must be a JSON object"

parseEdge :: [T.Text] -> [T.Text] -> [NodeInfo] -> Value -> Either String EdgeInfo
parseEdge edgeTypes provenanceClasses nodes value@(Object obj) = do
  relation <- fieldText obj "type"
  source <- fieldText obj "source"
  target <- fieldText obj "target"
  provenance <- fieldText obj "provenance"
  useSite <- fieldText obj "use_site"

  rank <-
    maybe
      (Left ("edge has undeclared type " ++ T.unpack relation))
      Right
      (elemIndex relation edgeTypes)

  unless (provenance `elem` provenanceClasses) $
    Left ("edge has undeclared provenance " ++ T.unpack provenance)

  certainty <- fieldValue obj "certainty"
  unless (certainty == Number 1) $
    Left "edge certainty must be exactly 1"

  sourceNode <- lookupNode source nodes
  targetNode <- lookupNode target nodes
  when (provenance == "theorem-backed" && relation `elem` theoremBackedSourceTypes) $ do
    let backing =
          if relation == "synonymous"
            then targetNode
            else sourceNode
    requireBackingSource backing relation

  pure EdgeInfo
    { eiRank = rank
    , eiSource = source
    , eiTarget = target
    , eiUseSite = useSite
    , eiValue = value
    }
parseEdge _ _ _ _ = Left "every edge must be a JSON object"

theoremBackedSourceTypes :: [T.Text]
theoremBackedSourceTypes = ["implicative", "synonymous", "part-whole"]

requireBackingSource :: NodeInfo -> T.Text -> Either String ()
requireBackingSource node relation =
  case KM.lookup "source" (niObject node) of
    Just (String sourceText)
      | not (T.null sourceText) -> Right ()
    _ ->
      Left
        ( "theorem-backed "
            ++ T.unpack relation
            ++ " edge lacks backing source evidence at node "
            ++ T.unpack (niId node)
        )

lookupNode :: T.Text -> [NodeInfo] -> Either String NodeInfo
lookupNode ident nodes =
  maybe
    (Left ("edge endpoint does not name a node: " ++ T.unpack ident))
    Right
    (find ((== ident) . niId) nodes)

kindRank :: T.Text -> Either String Int
kindRank "claim" = Right 0
kindRank "alias" = Right 1
kindRank "assumption_set" = Right 2
kindRank other = Left ("unknown node kind " ++ T.unpack other)

fieldValue :: Object -> Key.Key -> Either String Value
fieldValue obj key =
  maybe
    (Left ("missing field " ++ T.unpack (Key.toText key)))
    Right
    (KM.lookup key obj)

fieldText :: Object -> Key.Key -> Either String T.Text
fieldText obj key = do
  value <- fieldValue obj key
  case value of
    String text -> Right text
    _ -> Left ("field " ++ T.unpack (Key.toText key) ++ " must be a string")

fieldArray :: Object -> Key.Key -> Either String [Value]
fieldArray obj key = do
  value <- fieldValue obj key
  case value of
    Array values -> Right (V.toList values)
    _ -> Left ("field " ++ T.unpack (Key.toText key) ++ " must be an array")

fieldTextArray :: Object -> Key.Key -> Either String [T.Text]
fieldTextArray obj key = do
  values <- fieldArray obj key
  traverse asText values
 where
  asText (String text) = Right text
  asText _ = Left ("field " ++ T.unpack (Key.toText key) ++ " must contain only strings")

requireUnique :: (Eq a) => String -> [a] -> Either String ()
requireUnique label values =
  unless (length values == length (nub values)) $
    Left (label ++ " must be unique")

-- | Canonical JSON: recursively lexicographic object keys, original array
-- order, no insignificant whitespace. Strings and numbers use Aeson's JSON
-- scalar encoder.
canonicalEncode :: Value -> BL.ByteString
canonicalEncode Null = BL8.pack "null"
canonicalEncode value@(Bool _) = Aeson.encode value
canonicalEncode value@(Number _) = Aeson.encode value
canonicalEncode value@(String _) = Aeson.encode value
canonicalEncode (Array values) =
  BL8.pack "["
    <> BL.intercalate (BL8.pack ",") (map canonicalEncode (V.toList values))
    <> BL8.pack "]"
canonicalEncode (Object obj) =
  let fields = sortOn (Key.toText . fst) (KM.toList obj)
      encodeField (key, value) =
        Aeson.encode (String (Key.toText key))
          <> BL8.pack ":"
          <> canonicalEncode value
   in BL8.pack "{"
        <> BL.intercalate (BL8.pack ",") (map encodeField fields)
        <> BL8.pack "}"
