module Main (main) where

import qualified Data.Aeson as Aeson
import qualified Data.ByteString.Lazy as LazyBytes
import Oracle.Category (FiniteMap (..), compositionLaw, identityLaw)
import Oracle.ProofGraph (normalizeProofGraph, proofGraphAuthoritativeFor)
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

proofGraphVector :: IO ()
proofGraphVector = do
  inputBytes <- LazyBytes.readFile "test-vectors/finite-proof-graph/minimal-v1.input.json"
  expectedBytes <- LazyBytes.readFile "test-vectors/finite-proof-graph/minimal-v1.expected.json"
  let input = Aeson.eitherDecode inputBytes
      expected = Aeson.eitherDecode expectedBytes
  case (input, expected) of
    (Right source, Right answer) -> do
      normalized <- either fail pure (normalizeProofGraph source)
      if normalized /= answer
        then fail "finite-proof-graph normalization disagrees with the domain-owned vector"
        else either fail (\again -> if again == answer then pure () else fail "normalization is not idempotent")
             (normalizeProofGraph normalized)
    (Left problem, _) -> fail ("invalid input vector: " ++ problem)
    (_, Left problem) -> fail ("invalid expected vector: " ++ problem)

proofGraphRefusesAuthorityLeak :: IO ()
proofGraphRefusesAuthorityLeak = do
  inputBytes <- LazyBytes.readFile "test-vectors/finite-proof-graph/minimal-v1.input.json"
  case Aeson.eitherDecode inputBytes of
    Left problem -> fail problem
    Right source -> case normalizeProofGraph source of
      Left problem -> fail problem
      Right _ ->
        if proofGraphAuthoritativeFor ObservationalEquivalence (ModelsAgree :: OracleResult String)
          || proofGraphAuthoritativeFor MathematicalProof (ModelsAgree :: OracleResult String)
          || proofGraphAuthoritativeFor CertificateAcceptance (ModelsAgree :: OracleResult String)
          || proofGraphAuthoritativeFor EffectAuthorization (ModelsAgree :: OracleResult String)
          || proofGraphAuthoritativeFor PersistedState (ModelsAgree :: OracleResult String)
          then fail "proof-graph contract widened into an excluded authority question"
          else pure ()

main :: IO ()
main = do
  quickCheck identityProperty
  quickCheck compositionProperty
  quickCheck normativeSemanticAuthorityProperty
  quickCheck advisoryNeverAuthoritativeProperty
  quickCheck excludedAuthorityProperty
  quickCheck inconclusiveNeverAuthoritativeProperty
  proofGraphVector
  proofGraphRefusesAuthorityLeak
