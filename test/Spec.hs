module Main (main) where

import Oracle.Category (FiniteMap (..), compositionLaw, identityLaw)
import Oracle.Result
  ( AuthorityMode (..)
  , AuthorityQuestion (..)
  , OracleResult (..)
  , authoritativeFor
  )
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

normativeSemanticAuthorityProperty :: Property
normativeSemanticAuthorityProperty =
  authoritativeFor
    NormativeSemantic
    CompositionPreservation
    (ModelsAgree :: OracleResult String)
    === True

advisoryNeverAuthoritativeProperty :: String -> Property
advisoryNeverAuthoritativeProperty detail =
  authoritativeFor
    AdvisoryOracle
    ObservationalEquivalence
    (ModelsDisagree detail :: OracleResult String)
    === False

excludedAuthorityProperty :: Property
excludedAuthorityProperty =
  authoritativeFor
    NormativeSemantic
    CertificateAcceptance
    (ModelsAgree :: OracleResult String)
    === False

inconclusiveNeverAuthoritativeProperty :: String -> Property
inconclusiveNeverAuthoritativeProperty detail =
  authoritativeFor
    NormativeSemantic
    ContractInterpretation
    (Inconclusive detail :: OracleResult String)
    === False

main :: IO ()
main = do
  quickCheck identityProperty
  quickCheck compositionProperty
  quickCheck normativeSemanticAuthorityProperty
  quickCheck advisoryNeverAuthoritativeProperty
  quickCheck excludedAuthorityProperty
  quickCheck inconclusiveNeverAuthoritativeProperty
