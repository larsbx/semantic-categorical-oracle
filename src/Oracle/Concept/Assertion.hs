module Oracle.Concept.Assertion
  ( Certainty
  , certainty
  , certaintyValue
  , Assertion (..)
  , RawAssertion (..)
  , AssertionError (..)
  , fromRaw
  , endpoints
  , normalizeAssertions
  , saturate
  ) where

import Data.Function (on)
import Data.List (groupBy, maximumBy, sortOn)
import Data.Ord (comparing)
import Oracle.Concept.Relation (Relation, isSymmetric, isTransitive, parseRelation)
import Oracle.Concept.Validate (Concept, ConceptError, validateConcept)

-- | A confidence in the closed unit interval; NaN is unrepresentable.
newtype Certainty = Certainty Double
  deriving (Eq, Ord, Show)

certainty :: Double -> Maybe Certainty
certainty x
  | 0 <= x && x <= 1 = Just (Certainty x)
  | otherwise = Nothing

certaintyValue :: Certainty -> Double
certaintyValue (Certainty x) = x

-- | A claimed relation between two concepts. Representation only: an
-- assertion is evidence offered to the filter, never a decided fact.
data Assertion = Assertion
  { assertionSource :: Concept
  , assertionTarget :: Concept
  , assertionRelation :: Relation
  , assertionCertainty :: Certainty
  , assertionNote :: String
  }
  deriving (Eq, Ord, Show)

-- | The untyped record an LLM emits (tui-story @llm/client.ex@ JSON shape).
data RawAssertion = RawAssertion
  { rawFrom :: String
  , rawTo :: String
  , rawType :: String
  , rawCertainty :: Double
  , rawDescription :: String
  }
  deriving (Eq, Show)

data AssertionError
  = InvalidSource ConceptError
  | InvalidTarget ConceptError
  | UnknownRelation String
  | CertaintyOutOfRange Double
  deriving (Eq, Show)

-- | Fail-closed typing of raw model output.
fromRaw :: RawAssertion -> Either AssertionError Assertion
fromRaw raw =
  Assertion
    <$> either (Left . InvalidSource) Right (validateConcept (rawFrom raw))
    <*> either (Left . InvalidTarget) Right (validateConcept (rawTo raw))
    <*> maybe (Left (UnknownRelation (rawType raw))) Right (parseRelation (rawType raw))
    <*> maybe (Left (CertaintyOutOfRange (rawCertainty raw))) Right (certainty (rawCertainty raw))
    <*> pure (rawDescription raw)

endpoints :: Assertion -> (Concept, Concept)
endpoints a = (assertionSource a, assertionTarget a)

-- | Symmetric relations carry their endpoints in canonical order.
orient :: Assertion -> Assertion
orient a
  | isSymmetric (assertionRelation a) && assertionTarget a < assertionSource a =
      a {assertionSource = assertionTarget a, assertionTarget = assertionSource a}
  | otherwise = a

key :: Assertion -> (Concept, Concept, Relation)
key a = (assertionSource a, assertionTarget a, assertionRelation a)

-- | Canonical form: self-loops dropped, symmetric relations oriented, and one
-- assertion per (source, target, relation) keeping the highest certainty
-- (tui-story @edge.ex@ duplicate rule). Sorted, hence order-independent.
normalizeAssertions :: [Assertion] -> [Assertion]
normalizeAssertions =
  map (maximumBy (comparing strength))
    . groupBy ((==) `on` key)
    . sortOn key
    . filter (uncurry (/=) . endpoints)
    . map orient
 where
  strength a = (assertionCertainty a, assertionNote a)

-- | Least fixpoint of transitive composition, with the weaker premise as the
-- derived certainty (Gödel t-norm). Terminates: keys and certainties range
-- over finite sets and the per-key certainty only increases.
saturate :: [Assertion] -> [Assertion]
saturate = go . normalizeAssertions
 where
  go xs = let next = normalizeAssertions (xs ++ compose xs) in if next == xs then xs else go next
  compose xs =
    [ Assertion a c r (min p q) "derived"
    | Assertion a b r p _ <- views xs
    , isTransitive r
    , Assertion b' c r' q _ <- views xs
    , r' == r
    , b' == b
    ]
  views xs = xs ++ [Assertion t s r p n | Assertion s t r p n <- xs, isSymmetric r]
