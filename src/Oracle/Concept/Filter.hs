module Oracle.Concept.Filter
  ( FilterPolicy (..)
  , defaultPolicy
  , Conflict (..)
  , Admission (..)
  , filterConcepts
  , canonicalOf
  ) where

import Data.Either (partitionEithers)
import Data.List (nub, partition, sort)
import Oracle.Concept.Assertion
import Oracle.Concept.Relation (Relation (..), incompatible)
import Oracle.Concept.Validate (Concept, ConceptError, validateConcept)

-- | Which assertions may shape the concept set before any oracle sees it.
data FilterPolicy = FilterPolicy
  { minimumCertainty :: Double
  , admitsRelation :: Relation -> Bool
  }

-- | tui-story's @MinCertainty = 0.5@ (SemanticGraphConstraints.tla), all relations.
defaultPolicy :: FilterPolicy
defaultPolicy = FilterPolicy 0.5 (const True)

-- | Two incompatible relations on one unordered pair, named by the concepts
-- that carried them. Collapsing synonyms counts as asserting 'Synonymous'.
data Conflict = Conflict
  { conflictPair :: (Concept, Concept)
  , conflictRelations :: (Relation, Relation)
  }
  deriving (Eq, Ord, Show)

-- | The pre-oracle concept set. Every concept that took part in a conflict is
-- quarantined rather than resolved: the filter never picks a side.
data Admission = Admission
  { admitted :: [Concept]
  , aliases :: [(Concept, Concept)]
  , retained :: [Assertion]
  , conflicts :: [Conflict]
  , quarantined :: [Concept]
  , invalid :: [(String, ConceptError)]
  }
  deriving (Eq, Show)

-- | Validate, threshold, collapse synonymy classes onto their least member,
-- detect conflicts over the transitive closure, and quarantine. Assertions
-- naming a concept outside the supplied set are discarded.
filterConcepts :: FilterPolicy -> [String] -> [Assertion] -> Admission
filterConcepts policy raws claims =
  Admission
    { admitted = filter (`notElem` blocked) classes
    , aliases = [(c, canon c) | c <- concepts, canon c /= c]
    , retained = [a | a <- graph, all (`notElem` blocked) (pair a)]
    , conflicts = found
    , quarantined = blocked
    , invalid = rejected
    }
 where
  (rejected, concepts) = fmap (nub . sort) (partitionEithers (map validate raws))
  validate raw = either (Left . (,) raw) Right (validateConcept raw)
  evidence =
    [ a
    | a <- normalizeAssertions claims
    , all (`elem` concepts) (pair a)
    , certaintyValue (assertionCertainty a) >= minimumCertainty policy
    , admitsRelation policy (assertionRelation a)
    ]
  (synonyms, others) = partition ((== Synonymous) . assertionRelation) evidence
  canon = canonicalOf (map endpoints synonyms)
  classes = nub (sort (map canon concepts))
  rebase a = a {assertionSource = canon (assertionSource a), assertionTarget = canon (assertionTarget a)}
  graph = normalizeAssertions (map rebase others)
  collapsed =
    [ Conflict (endpoints a) (Synonymous, assertionRelation a)
    | a <- others
    , uncurry (==) (endpoints (rebase a))
    , incompatible Synonymous (assertionRelation a)
    ]
  closed = saturate graph
  clashing =
    [ Conflict (endpoints a) (assertionRelation a, assertionRelation b)
    | a <- closed
    , b <- closed
    , a < b
    , unordered (endpoints a) == unordered (endpoints b)
    , incompatible (assertionRelation a) (assertionRelation b)
    ]
  found = nub (sort (collapsed ++ clashing))
  blocked = nub (sort [canon c | Conflict (s, t) _ <- found, c <- [s, t]])
  pair a = let (s, t) = endpoints a in [s, t]
  unordered (s, t) = (min s t, max s t)

-- | Representative map for the equivalence closure of the given pairs: each
-- concept maps to the least member of its class (identity elsewhere).
canonicalOf :: [(Concept, Concept)] -> Concept -> Concept
canonicalOf pairs c = minimum (component [c])
 where
  component seen =
    let next = nub (sort (seen ++ [y | (a, b) <- pairs, (x, y) <- [(a, b), (b, a)], x `elem` seen]))
     in if next == sort seen then next else component next
