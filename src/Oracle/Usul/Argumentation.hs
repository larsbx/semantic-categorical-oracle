-- | Advisory mirror of @Usul.Dung@ / @Usul.Grounded@ (Lean) over finite
-- argumentation frameworks on @[0 .. n-1]@.
module Oracle.Usul.Argumentation
  ( AF (..)
  , characteristic
  , conflictFree
  , admissible
  , complete
  , grounded
  , subsets
  ) where

import Data.List (nub, sort, subsequences)

data AF = AF {afSize :: Int, afAttacks :: [(Int, Int)]}
  deriving (Eq, Show)

attackers :: AF -> Int -> [Int]
attackers af a = [b | (b, x) <- afAttacks af, x == a]

-- | Arguments defended by @s@.
characteristic :: AF -> [Int] -> [Int]
characteristic af s =
  [a | a <- [0 .. afSize af - 1], all (any (`elem` s) . attackers af) (attackers af a)]

conflictFree :: AF -> [Int] -> Bool
conflictFree af s = null [() | (a, b) <- afAttacks af, a `elem` s, b `elem` s]

admissible :: AF -> [Int] -> Bool
admissible af s = conflictFree af s && all (`elem` characteristic af s) s

-- | Extensions are sets: duplicate entries in @s@ are ignored.
complete :: AF -> [Int] -> Bool
complete af s = admissible af s && sort (characteristic af s) == sort (nub s)

-- | Least fixed point of 'characteristic', by iteration from the empty set.
grounded :: AF -> [Int]
grounded af = go []
 where
  go s = let s' = characteristic af s in if s' == s then s else go s'

subsets :: AF -> [[Int]]
subsets af = subsequences [0 .. afSize af - 1]
