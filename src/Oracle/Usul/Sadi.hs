-- | Advisory mirror of @Usul.Sadi@, @Usul.Muamalat@ and @Usul.Kulliyyat@ (Lean): the computable readings of al-Saʿdī's
-- qawāʿid. Rule numbers follow corpus/proposals/sadi_qawaid.json in the domain repo.
module Oracle.Usul.Sadi
  ( operative
  , voids
  , best
  , dependsOn
  , Context (..)
  , NounForm (..)
  , isGeneral
  , Purpose (..)
  , itlafLiable
  , withRight
  , ContractKind (..)
  , ghararForbidden
  , reservationValid
  , meaning
  , continuous
  , admissibleForOther
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


-- | Q36: destroying to repel the thing's own harm is destruction with right.
data Purpose = Benefit | RepelHarm
  deriving (Eq, Show, Enum, Bounded)

withRight :: Purpose -> Bool
withRight = (== RepelHarm)

-- | Q13: destruction without right is compensable, whatever the mental state.
itlafLiable :: Bool -> Bool
itlafLiable = not

data ContractKind = Exchange | Contest | Gift
  deriving (Eq, Show, Enum, Bounded)

-- | Q21: gharar is forbidden in exchanges and contests.
ghararForbidden :: ContractKind -> Bool -> Bool
ghararForbidden k g = g && k /= Gift

-- | Q42: a reserved usufruct must be known, except in gifts.
reservationValid :: ContractKind -> Bool -> Bool
reservationValid k known = known || k == Gift

-- | Q29: an utterance's base extension narrowed by its qualifiers.
meaning :: (a -> Bool) -> [a -> Bool] -> a -> Bool
meaning base qs x = base x && all ($ x) qs

-- | Q48: consecutive parts lie within the customary gap.
continuous :: Integer -> [Integer] -> Bool
continuous g ts = and (zipWith (\a b -> b - a <= g) ts (drop 1 ts))

-- | Q34: a choice for another's benefit must pick a best option.
admissibleForOther :: (a -> Integer) -> [a] -> a -> Bool
admissibleForOther v os p = all (\o -> v o <= v p) os
