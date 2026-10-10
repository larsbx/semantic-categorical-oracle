module Oracle.Concept.Relation
  ( Relation (..)
  , relationTag
  , relationSymbol
  , parseRelation
  , isSymmetric
  , isTransitive
  , incompatible
  ) where

import Data.Char (toLower)

-- | The nine semantic relation types migrated from tui-story
-- (@semantic_graph/lib/semantic_graph/resources/edge.ex@).
data Relation
  = Contradictory
  | Implicative
  | Hierarchical
  | Evolutionary
  | Analogous
  | Synonymous
  | Antonymous
  | PartWhole
  | Causal
  deriving (Eq, Ord, Show, Enum, Bounded)

relationTag :: Relation -> String
relationTag Contradictory = "contradictory"
relationTag Implicative = "implicative"
relationTag Hierarchical = "hierarchical"
relationTag Evolutionary = "evolutionary"
relationTag Analogous = "analogous"
relationTag Synonymous = "synonymous"
relationTag Antonymous = "antonymous"
relationTag PartWhole = "part_whole"
relationTag Causal = "causal"

relationSymbol :: Relation -> String
relationSymbol Contradictory = "⊥"
relationSymbol Implicative = "→"
relationSymbol Hierarchical = "⊆"
relationSymbol Evolutionary = "⟿"
relationSymbol Analogous = "≈"
relationSymbol Synonymous = "≡"
relationSymbol Antonymous = "≠"
relationSymbol PartWhole = "∈"
relationSymbol Causal = "⇒"

-- | Fail-closed inverse of 'relationTag'. Unknown tags are rejected rather
-- than interned, unlike the original @String.to_atom@.
parseRelation :: String -> Maybe Relation
parseRelation tag =
  lookup (map toLower tag) [(relationTag r, r) | r <- [minBound .. maxBound]]

-- | Directionality and transitivity, per tui-story @specs/SEMANTIC_ANALYSIS.md@ §2.
isSymmetric :: Relation -> Bool
isSymmetric = (`elem` [Contradictory, Analogous, Synonymous, Antonymous])

isTransitive :: Relation -> Bool
isTransitive = (`elem` [Implicative, Hierarchical, Synonymous])

-- | Relations that cannot both hold on one unordered pair of concepts:
-- constraint C2 (implication excludes contradiction) plus the definitional
-- exclusions of synonymy. Symmetric and irreflexive by construction.
incompatible :: Relation -> Relation -> Bool
incompatible a b = (min a b, max a b) `elem` exclusions
 where
  exclusions =
    [ (Contradictory, Implicative)
    , (Contradictory, Synonymous)
    , (Synonymous, Antonymous)
    ]
