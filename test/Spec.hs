module Main (main) where

import Oracle.Category (FiniteMap (..), compositionLaw, identityLaw)
import Oracle.GrowthBridge
  ( GrowthBridgeContract (..)
  , ModuleWitness (..)
  , contractId
  , contractQuestion
  , cycleBasisEquivalent
  )
import Oracle.ProofGraph
  ( ProofEdge (..)
  , ProofNode (..)
  , normalizeEdges
  , normalizeNodes
  )
import Oracle.Result
  ( AuthorityMode (..)
  , AuthorityQuestion (..)
  , OracleResult (..)
  , authoritativeFor
  )
import Control.Monad (unless)
import System.Exit (exitFailure)
import Test.QuickCheck
  ( Property
  , Testable
  , isSuccess
  , quickCheckResult
  , (===)
  )
import Usul.Laws (usulProperties)

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

excludedAuthorityProperty :: AuthorityQuestion -> Property
excludedAuthorityProperty question =
  authoritativeFor
    NormativeSemantic
    question
    (ModelsAgree :: OracleResult String)
    === False

inconclusiveNeverAuthoritativeProperty :: String -> Property
inconclusiveNeverAuthoritativeProperty detail =
  authoritativeFor
    NormativeSemantic
    ContractInterpretation
    (Inconclusive detail :: OracleResult String)
    === False

proofGraphNodeVector :: Property
proofGraphNodeVector =
  normalizeNodes
    [ ProofNode "Lemma" "claim"
    , ProofNode "Census" "claim"
    , ProofNode "Proof" "claim"
    ]
    === [ ProofNode "Census" "claim"
        , ProofNode "Lemma" "claim"
        , ProofNode "Proof" "claim"
        ]

proofGraphProvenanceVector :: Property
proofGraphProvenanceVector =
  normalizeEdges
    [ ProofEdge "implicative" "Galois" "Conditional" "open" "conditional/galois"
    , ProofEdge "implicative" "Galois" "Conditional" "theorem-backed" "conditional/galois"
    ]
    === [ ProofEdge "implicative" "Galois" "Conditional" "open" "conditional/galois"
        , ProofEdge "implicative" "Galois" "Conditional" "theorem-backed" "conditional/galois"
        ]

growthBridgeCycleBasisVector :: Property
growthBridgeCycleBasisVector =
  cycleBasisEquivalent left right === ModelsAgree
 where
  left = ModuleWitness "H_tail" "power-basis-phi" "module:abc"
  right = ModuleWitness "H_tail" "power-basis-phi" "module:abc"

growthBridgeRejectsDifferentModule :: Property
growthBridgeRejectsDifferentModule =
  cycleBasisEquivalent left right === ModelsDisagree "generated module identity differs"
 where
  left = ModuleWitness "H_tail" "power-basis-phi" "module:abc"
  right = ModuleWitness "H_tail" "power-basis-phi" "module:def"

growthBridgeRejectsCrossBasisComparison :: Property
growthBridgeRejectsCrossBasisComparison =
  cycleBasisEquivalent left right === ModelsDisagree "arithmetic basis identity differs"
 where
  left = ModuleWitness "H_tail" "power-basis-phi" "module:abc"
  right = ModuleWitness "H_tail" "another-basis" "module:abc"

growthBridgeEmptyIdentityFailsClosed :: Property
growthBridgeEmptyIdentityFailsClosed =
  cycleBasisEquivalent left right === OracleError "left.generated_module_id is empty"
 where
  left = ModuleWitness "H_tail" "power-basis-phi" ""
  right = ModuleWitness "H_tail" "power-basis-phi" "module:abc"

growthBridgeContractIsSemanticOnly :: Property
growthBridgeContractIsSemanticOnly =
  let result = cycleBasisEquivalent witness witness
   in ( contractId GBCycleBasis001 == "GB-CYCLE-BASIS-001"
          && contractQuestion GBCycleBasis001 == NormalForm
          && authoritativeFor NormativeSemantic NormalForm result
          && not (authoritativeFor NormativeSemantic MathematicalProof result)
      )
        === True
 where
  witness = ModuleWitness "H_tail" "power-basis-phi" "module:abc"

proofGraphDuplicateVector :: Property
proofGraphDuplicateVector =
  normalizeEdges [aliasEdge, aliasEdge] === [aliasEdge]
 where
  aliasEdge =
    ProofEdge "synonymous" "PIP census" "Census" "theorem-backed" "aliases"

-- | Run every property; exit non-zero if any fails (QuickCheck's 'quickCheck'
-- alone always exits 0, so a failing law would not fail the suite).
check :: Testable p => p -> IO Bool
check = fmap isSuccess . quickCheckResult

main :: IO ()
main = do
  results <-
    sequence
      [ check identityProperty
      , check compositionProperty
      , check normativeSemanticAuthorityProperty
      , check advisoryNeverAuthoritativeProperty
      ]
  exclusions <-
    mapM
      (check . excludedAuthorityProperty)
      [MathematicalProof, CertificateAcceptance, EffectAuthorization, PersistedState]
  rest <-
    sequence
      [ check inconclusiveNeverAuthoritativeProperty
      , check proofGraphNodeVector
      , check proofGraphProvenanceVector
      , check proofGraphDuplicateVector
      , check growthBridgeCycleBasisVector
      , check growthBridgeRejectsDifferentModule
      , check growthBridgeRejectsCrossBasisComparison
      , check growthBridgeEmptyIdentityFailsClosed
      , check growthBridgeContractIsSemanticOnly
      ]
  usul <- mapM (\(name, p) -> putStrLn name >> check p) usulProperties
  unless (and (results ++ exclusions ++ rest ++ usul)) exitFailure
