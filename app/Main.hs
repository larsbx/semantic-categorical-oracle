module Main (main) where

import Oracle.Category (FiniteMap (..), compositionLaw)
import Oracle.Result (OracleResult (..))

main :: IO ()
main = do
  let domain = [-8 .. 8 :: Int]
      f = FiniteMap (+ 1)
      g = FiniteMap (* 2)
      h = FiniteMap (subtract 3)
      result =
        if compositionLaw domain f g h
          then LawHoldsForTestDomain
          else ModelsDisagree "composition law failed"
  print (result :: OracleResult String)
