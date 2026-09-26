-- | Spike: Jev as an advisory alias oracle over proof-graph node labels.
--
-- Semantic question: for two distinct node ids, do they name the same
-- mathematical object? The domain declares aliasing with @synonymous@ edges;
-- Jev answers independently; disagreements are counterexamples to one side.
-- The result is advisory by construction ('spikeAuthority') and never feeds
-- 'Oracle.ProofGraph' normalization, proof status, or acceptance.
module Jev.Alias
  ( Relation (..)
  , Pair
  , pairIds
  , mkPair
  , Probe (..)
  , Disagreement (..)
  , spikeAuthority
  , candidatePairs
  , declaredRelation
  , probe
  , judge
  ) where

import Data.Aeson (object, (.=))
import Data.List (partition, sortOn)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Set (Set)
import Data.Set qualified as Set
import Data.Text (Text)
import Data.Text qualified as Text
import Jev.Gate (Floor, Gated (..), gate)
import Jev.Typed (Decision (..), Option (..), choice, decodeChoice)
import Jev.Wire (Request (..), Response (..))
import Oracle.ProofGraph (ProofEdge (..), ProofNode (..), normalizeNodes)
import Oracle.Result (AuthorityMode (..), OracleResult (..))
import Text.Printf (printf)

data Relation = SameObject | DistinctObject
  deriving (Eq, Ord, Show, Bounded, Enum)

instance Option Relation where
  optionKey SameObject = "same_object"
  optionKey DistinctObject = "distinct_object"
  rubric SameObject =
    Just "Both labels name the same mathematical object, result, or census, differing only in wording or abbreviation."
  rubric DistinctObject =
    Just "The labels name different objects, even if one depends on, implies, or is closely related to the other."

-- | Unordered pair of distinct node ids, stored canonically (left < right).
data Pair = Pair String String
  deriving (Eq, Ord, Show)

mkPair :: String -> String -> Maybe Pair
mkPair a b = case compare a b of
  LT -> Just (Pair a b)
  GT -> Just (Pair b a)
  EQ -> Nothing

pairIds :: Pair -> (String, String)
pairIds (Pair a b) = (a, b)

data Probe = Probe
  { probeRequest :: Request
  , probePairs :: Map Text Pair
  }
  deriving (Eq, Show)

data Disagreement = Disagreement
  { disputed :: Pair
  , declared :: Relation
  , jev :: Relation
  , jevConfidence :: Double
  }
  deriving (Eq, Show)

-- | A probabilistic model never holds semantic authority in this estate.
spikeAuthority :: AuthorityMode
spikeAuthority = AdvisoryOracle

-- | Every unordered pair of distinct ids, in canonical order; invariant under
-- permutation and duplication of the input.
candidatePairs :: [ProofNode] -> [Pair]
candidatePairs nodes =
  [Pair a b | (i, a) <- indexed, (j, b) <- indexed, i < j]
 where
  indexed = zip [0 :: Int ..] (Set.toAscList (Set.fromList (nodeId <$> normalizeNodes nodes)))

-- | Declared aliasing is the equivalence closure of @synonymous@ edges.
declaredRelation :: [ProofEdge] -> Pair -> Relation
declaredRelation edges (Pair a b)
  | any (\cls -> a `Set.member` cls && b `Set.member` cls) classes = SameObject
  | otherwise = DistinctObject
 where
  classes = aliasClasses edges

aliasClasses :: [ProofEdge] -> [Set String]
aliasClasses = foldr merge [] . filter ((== "synonymous") . edgeType)
 where
  merge e classes =
    let ends = Set.fromList [edgeSource e, edgeTarget e]
        (touching, rest) = partition (not . Set.disjoint ends) classes
     in Set.unions (ends : touching) : rest

-- | One speculative fan-out request: a Choice per candidate pair.
probe :: Text -> [ProofNode] -> Probe
probe modelName nodes =
  Probe
    { probeRequest =
        Request
          { state = object ["context" .= ("Node labels from a typed proof-record relationship graph." :: Text)]
          , model = modelName
          , questions = question <$> keyed
          }
    , probePairs = keyed
    }
 where
  keyed = Map.fromList (zip (Text.pack . printf "pair-%04d" <$> [0 :: Int ..]) (candidatePairs nodes))
  question (Pair a b) =
    choice @Relation $
      object
        [ "left" .= a
        , "right" .= b
        , "question" .= ("Do `left` and `right` name the same mathematical object?" :: Text)
        ]

-- | Fail-closed comparison: a malformed response is an 'OracleError', any
-- confident disagreement is a counterexample, and sub-floor answers make an
-- otherwise agreeing run 'Inconclusive' rather than 'ModelsAgree'.
judge :: Floor -> [ProofEdge] -> Probe -> Response -> OracleResult [Disagreement]
judge floor' edges (Probe _ pairs) response
  | Map.keysSet (answers response) /= Map.keysSet pairs =
      OracleError "answer ids differ from question ids"
  | otherwise =
      either (OracleError . show) verdict (traverse (decodeChoice @Relation) (answers response))
 where
  verdict decisions =
    let judged = [(pairs Map.! k, d) | (k, d) <- Map.toList decisions]
        disagreements =
          sortOn disputed
            [ Disagreement p expected r (confidence d)
            | (p, d) <- judged
            , Act r <- [gate floor' d]
            , let expected = declaredRelation edges p
            , r /= expected
            ]
        escalated = [p | (p, d) <- judged, Escalate _ _ <- [gate floor' d]]
     in case (disagreements, escalated) of
          (_ : _, _) -> ModelsDisagree disagreements
          ([], _ : _) ->
            Inconclusive (show (length escalated) <> " of " <> show (length judged) <> " pairs below confidence floor")
          ([], []) -> ModelsAgree
