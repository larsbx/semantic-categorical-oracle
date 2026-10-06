-- | Advisory mirror of @Usul.Schema@ (Lean): the shapes under al-Saʿdī's readings.
-- Only the computable schemata are mirrored (S2 priority, S4 closure over a finite
-- carrier, S7 merge representatives); their laws are checked in test/Usul/Laws.hs.
module Oracle.Usul.Schema
  ( firstSome
  , resolveD
  , closure
  , reps
  , covers
  ) where

import Data.List (nub, sort)
import Data.Maybe (fromMaybe, listToMaybe, catMaybes)

-- | S2: the first defined source in priority order.
firstSome :: [Maybe a] -> Maybe a
firstSome = listToMaybe . catMaybes

-- | S2: resolve by priority, falling back to a default.
resolveD :: [Maybe a] -> a -> a
resolveD xs d = fromMaybe d (firstSome xs)

-- | S4: least superset of the seeds closed under the step relation (finite carrier).
closure :: Ord a => [(a, a)] -> [a] -> [a]
closure step = go . sort . nub
 where
  go s = let s' = sort (nub (s ++ [b | (a, b) <- step, a `elem` s])) in if s' == s then s else go s'

-- | S7: keep an act only if no kept act already discharges it (Lean @reps@).
reps :: (a -> a -> Bool) -> [a] -> [a]
reps r = foldr keep []
 where
  keep x ys = if any (`r` x) ys then ys else x : ys

-- | S7: every owed act is discharged by some performed one.
covers :: (a -> a -> Bool) -> [a] -> [a] -> Bool
covers r done owed = all (\o -> any (`r` o) done) owed
