-- | Advisory mirror of @Usul.Sadi@ (Lean): the computable readings of al-Saʿdī's
-- qawāʿid. Rule numbers follow corpus/proposals/sadi_qawaid.json in the domain repo.
module Oracle.Usul.Sadi
  ( operative
  , voids
  , best
  , dependsOn
  , Context (..)
  , NounForm (..)
  , isGeneral
  ) where

import Oracle.Usul.Hukm (Hukm (..))

-- | Q4: no obligation with inability, no prohibition with necessity.
operative :: Bool -> Bool -> Hukm -> Hukm
operative capable _ Wajib = if capable then Wajib else Mubah
operative _ darura Haram = if darura then Mubah else Haram
operative _ _ h = h

-- | Q22/Q23: a settlement or stipulation that permits the forbidden or forbids the permitted.
voids :: Hukm -> Hukm -> Bool
voids before after = (before == Haram) /= (after == Haram)

-- | Q33: the first element of maximal key (higher benefit; lighter harm via negated key).
-- Mirrors Lean @best@, which scans from the end and keeps the earlier element on ties.
best :: (a -> Integer) -> [a] -> Maybe a
best key = foldr step Nothing
 where
  step x Nothing = Just x
  step x (Just b) = Just (if key b <= key x then x else b)

-- | Q58: the ruling depends only on the ʿilla, checked over a finite list of cases.
dependsOn :: Eq f => [c] -> (c -> Hukm) -> (c -> f) -> Bool
dependsOn cases h e = and [h x == h y | x <- cases, y <- cases, e x == e y]

data Context = Affirmation | Negation | Prohibition | Condition | Question
  deriving (Eq, Show, Enum, Bounded)

data NounForm = Nakira | Particle | DefiniteAl | SingularAnnexed
  deriving (Eq, Show, Enum, Bounded)

-- | Q59/Q60: generality markers.
isGeneral :: NounForm -> Context -> Bool
isGeneral Nakira c = c `elem` [Negation, Prohibition, Condition]
isGeneral _ _ = True

