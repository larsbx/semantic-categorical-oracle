module Main (main) where

import Oracle.Category (FiniteMap (..), compositionLaw, identityLaw)
import Oracle.Result (OracleResult (..), isAuthoritative)
import Test.QuickCheck
  ( Property
  , (===)
  , quickCheck
  )

identityProperty :: [Int] -> Property
identityProperty xs =
  identityLaw xs (FiniteMap id) === True

compositionProperty :: [Int] -> Property
compositionProperty xs =
  let f = FiniteMap (+ 1)
      g = FiniteMap (* 2)
      h = FiniteMap (subtract 3)
   in compositionLaw xs f g h === True

authorityProperty :: String -> Property
authorityProperty detail =
  isAuthoritative (ModelsDisagree detail :: OracleResult String) === False

main :: IO ()
main = do
  quickCheck identityProperty
  quickCheck compositionProperty
  quickCheck authorityProperty
