module Oracle.Category
  ( FiniteMap (..)
  , identityLaw
  , compositionLaw
  ) where

-- | A finite observation domain makes every spike result explicitly bounded.
newtype FiniteMap a b = FiniteMap { runFiniteMap :: a -> b }

identityLaw :: Eq a => [a] -> FiniteMap a a -> Bool
identityLaw domain candidate =
  all (\x -> runFiniteMap candidate x == x) domain

compositionLaw
  :: Eq d
  => [a]
  -> FiniteMap a b
  -> FiniteMap b c
  -> FiniteMap c d
  -> Bool
compositionLaw domain (FiniteMap f) (FiniteMap g) (FiniteMap h) =
  all
    (\x -> h (g (f x)) == (h . g . f) x)
    domain
