{-# LANGUAGE OverloadedStrings #-}

module Oracle.ProofGraph
  ( normalizeProofGraph
  , proofGraphAuthoritativeFor
  ) where

import Control.Monad (unless, when)
import Data.Aeson (Value (..))
import Data.Foldable (traverse_)
import qualified Data.Aeson.Key as Key
import qualified Data.Aeson.KeyMap as KeyMap
import Data.List (nub, sortOn)
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import Data.Text (Text)
import qualified Data.Vector as Vector
import Oracle.Result (AuthorityMode (NormativeSemantic), AuthorityQuestion (..), OracleResult, authoritativeFor)

-- | Authority is contract-local. In particular, observational equivalence is
-- not one of this contract's approved questions even though another semantic
-- contract may register it.
proofGraphAuthoritativeFor :: AuthorityQuestion -> OracleResult counterexample -> Bool
proofGraphAuthoritativeFor question result =
  question `elem` [ContractInterpretation, NormalForm, CompositionPreservation]
    && authoritativeFor NormativeSemantic question result

-- | Interpret and normalize only the registered
-- finite-proof-graph.normalization@1.0.0 contract. A refusal returns no graph.
-- Provenance labels are structural data: this function never decides whether
-- any theorem is proved or whether any certificate is acceptable.
normalizeProofGraph :: Value -> Either String Value
normalizeProofGraph (Object root) = do
  format <- textField "format" root
  unless (format == "finite typed relationship graph 1") $
    Left "unsupported proof-graph format"
  edgeTypes <- textArrayField "edge_types" root
  provenance <- textArrayField "provenance_classes" root
  unless (edgeTypes == canonicalEdgeTypes) $ Left "edge vocabulary is not canonical"
  unless (provenance == canonicalProvenance) $ Left "provenance vocabulary is not canonical"
  nodeValues <- arrayField "nodes" root
  edgeValues <- arrayField "edges" root
  nodes <- traverse objectValue nodeValues
  edges <- traverse objectValue edgeValues
  nodeIds <- traverse (textField "id") nodes
  when (length nodeIds /= length (nub nodeIds)) $
    Left "duplicate node identifier"
  traverse_ (validateNode provenance) nodes
  let claimIds = Set.fromList [unsafeText "id" node | node <- nodes, unsafeText "kind" node == "claim"]
      aliasIds = Set.fromList [unsafeText "id" node | node <- nodes, unsafeText "kind" node == "alias"]
  unless (Set.null (Set.intersection claimIds aliasIds)) $ Left "alias collides with claim identifier"
  traverse_ (validateEdge edgeTypes provenance (Set.fromList nodeIds) nodes) edges
  let ranked = Map.fromList (zip edgeTypes [(0 :: Int) ..])
      edgeRank edge = Map.findWithDefault (-1) (unsafeText "type" edge) ranked
      edgeKey edge = (edgeRank edge, unsafeText "source" edge, unsafeText "target" edge, optionalText "use_site" edge)
      nodeRank node = Map.findWithDefault (-1) (unsafeText "kind" node) (Map.fromList [("claim", 0 :: Int), ("alias", 1), ("assumption_set", 2)])
      nodeKey node = (nodeRank node, unsafeText "id" node)
      normalized = KeyMap.insert "nodes" (Array (Vector.fromList (map Object (sortOn nodeKey nodes))))
                 $ KeyMap.insert "edges" (Array (Vector.fromList (map Object (sortOn edgeKey edges))))
                 $ KeyMap.delete "generated" root
  pure (Object normalized)
normalizeProofGraph _ = Left "proof graph must be a JSON object"

validateNode :: [Text] -> KeyMap.KeyMap Value -> Either String ()
validateNode provenance node = do
  kind <- textField "kind" node
  mark <- textField "provenance" node
  unless (kind `elem` ["claim", "alias", "assumption_set"]) $ Left "node has unknown kind"
  unless (mark `elem` provenance) $ Left "node has undeclared provenance"

canonicalEdgeTypes :: [Text]
canonicalEdgeTypes = ["contradictory", "implicative", "hierarchical", "evolutionary", "analogous", "synonymous", "antonymous", "part-whole", "causal"]

canonicalProvenance :: [Text]
canonicalProvenance = ["theorem-backed", "conditional", "imported-theorem", "bounded-evidence", "open", "withdrawn", "declared"]

validateEdge :: [Text] -> [Text] -> Set.Set Text -> [KeyMap.KeyMap Value] -> KeyMap.KeyMap Value -> Either String ()
validateEdge edgeTypes provenance nodeIds nodes edge = do
  edgeType <- textField "type" edge
  source <- textField "source" edge
  target <- textField "target" edge
  mark <- textField "provenance" edge
  certainty <- field "certainty" edge
  unless (edgeType `elem` edgeTypes) $ Left "edge has undeclared type"
  unless (mark `elem` provenance) $ Left "edge has undeclared provenance"
  unless (Set.member source nodeIds && Set.member target nodeIds) $
    Left "edge endpoint is not a node"
  unless (certainty == Number 1) $ Left "edge certainty is not exact"
  when (mark == "theorem-backed" && edgeType `elem` ["implicative", "synonymous", "part-whole"]) $ do
    let backer = if edgeType == "synonymous" then target else source
        backingSource = [optionalText "source" node | node <- nodes, unsafeText "id" node == backer]
    unless (any (/= "") backingSource) $ Left "theorem-backed edge has no backing source"

field :: Key.Key -> KeyMap.KeyMap Value -> Either String Value
field name object = maybe (Left ("missing field: " ++ show name)) Right (KeyMap.lookup name object)

textField :: Key.Key -> KeyMap.KeyMap Value -> Either String Text
textField name object = field name object >>= asText name

asText :: Key.Key -> Value -> Either String Text
asText _ (String value) = Right value
asText name _ = Left ("field is not text: " ++ show name)

arrayField :: Key.Key -> KeyMap.KeyMap Value -> Either String [Value]
arrayField name object = do
  value <- field name object
  case value of
    Array values -> Right (Vector.toList values)
    _ -> Left ("field is not an array: " ++ show name)

textArrayField :: Key.Key -> KeyMap.KeyMap Value -> Either String [Text]
textArrayField name object = arrayField name object >>= traverse (asText name)

objectValue :: Value -> Either String (KeyMap.KeyMap Value)
objectValue (Object value) = Right value
objectValue _ = Left "node or edge is not an object"

unsafeText :: Key.Key -> KeyMap.KeyMap Value -> Text
unsafeText name object = case KeyMap.lookup name object of
  Just (String value) -> value
  _ -> ""

optionalText :: Key.Key -> KeyMap.KeyMap Value -> Text
optionalText = unsafeText
