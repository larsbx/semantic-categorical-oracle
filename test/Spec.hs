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
  , normalizeGraphJson
  , normalizeNodes
  )
import Oracle.Result
  ( AuthorityMode (..)
  , AuthorityQuestion (..)
  , OracleResult (..)
  , authoritativeFor
  )
import Control.Monad (unless)
import qualified Data.ByteString.Lazy as BL
import qualified Data.ByteString.Lazy.Char8 as BL8
import Paths_semantic_categorical_oracle (getDataFileName)
import System.Exit (exitFailure)
import Test.QuickCheck
  ( Property
  , Testable
  , isSuccess
  , quickCheckResult
  , (===)
  )
import Concept.Laws (conceptProperties)
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


proofGraphRejectsWrongFormat :: Property
proofGraphRejectsWrongFormat =
  case normalizeGraphJson (BL8.pack "{\"format\":\"wrong\"}") of
    Left _ -> True === True
    Right _ -> False === True

proofGraphRejectsConflictingCanonicalEdgeIdentity :: Property
proofGraphRejectsConflictingCanonicalEdgeIdentity =
  case normalizeGraphJson (BL8.pack conflictingGraph) of
    Left _ -> True === True
    Right _ -> False === True
 where
  conflictingGraph =
    "{\"format\":\"finite typed relationship graph 1\","
      ++ "\"edge_types\":[\"implicative\"],"
      ++ "\"provenance_classes\":[\"theorem-backed\"],"
      ++ "\"nodes\":["
      ++ "{\"id\":\"Premise\",\"kind\":\"claim\",\"provenance\":\"theorem-backed\",\"source\":\"proof\"},"
      ++ "{\"id\":\"Result\",\"kind\":\"claim\",\"provenance\":\"theorem-backed\",\"source\":\"proof\"}],"
      ++ "\"edges\":["
      ++ "{\"type\":\"implicative\",\"source\":\"Premise\",\"target\":\"Result\",\"provenance\":\"theorem-backed\",\"certainty\":1,\"use_site\":\"result/premise\"},"
      ++ "{\"type\":\"implicative\",\"source\":\"Premise\",\"target\":\"Result\",\"provenance\":\"theorem-backed\",\"certainty\":1,\"use_site\":\"result/premise\",\"leaks\":\"different payload\"}]}"

proofGraphRequiresTheoremBackingSource :: Property
proofGraphRequiresTheoremBackingSource =
  case normalizeGraphJson (BL8.pack missingSourceGraph) of
    Left _ -> True === True
    Right _ -> False === True
 where
  missingSourceGraph =
    "{\"format\":\"finite typed relationship graph 1\","
      ++ "\"edge_types\":[\"implicative\"],"
      ++ "\"provenance_classes\":[\"theorem-backed\"],"
      ++ "\"nodes\":["
      ++ "{\"id\":\"Premise\",\"kind\":\"claim\",\"provenance\":\"theorem-backed\"},"
      ++ "{\"id\":\"Result\",\"kind\":\"claim\",\"provenance\":\"theorem-backed\",\"source\":\"proof\"}],"
      ++ "\"edges\":[{\"type\":\"implicative\",\"source\":\"Premise\",\"target\":\"Result\","
      ++ "\"provenance\":\"theorem-backed\",\"certainty\":1,\"use_site\":\"result/premise\"}]}"

proofGraphDomainVectors :: IO Bool
proofGraphDomainVectors = do
  results <-
    mapM
      checkPair
      [ ( "minimal"
        , "fixtures/proof-graph/typed-proof-graph-minimal-v1.input.json"
        , "fixtures/proof-graph/typed-proof-graph-minimal-v1.expected.json"
        )
      , ( "relationship graph"
        , "fixtures/proof-graph/relationship-graph-v1.input.json"
        , "fixtures/proof-graph/relationship-graph-v1.expected.json"
        )
      ]
  pure (and results)
 where
  checkPair (label, inputRel, expectedRel) = do
    inputPath <- getDataFileName inputRel
    expectedPath <- getDataFileName expectedRel
    input <- BL.readFile inputPath
    expected <- BL.readFile expectedPath
    case normalizeGraphJson input of
      Left err -> do
        putStrLn ("proof-graph " ++ label ++ " refused: " ++ err)
        pure False
      Right actual ->
        if actual == expected
          then pure True
          else do
            putStrLn ("proof-graph " ++ label ++ " canonical bytes differ from the domain vector")
            pure False

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
      , check proofGraphRejectsWrongFormat
      , check proofGraphRejectsConflictingCanonicalEdgeIdentity
      , check proofGraphRequiresTheoremBackingSource
      , check growthBridgeCycleBasisVector
      , check growthBridgeRejectsDifferentModule
      , check growthBridgeRejectsCrossBasisComparison
      , check growthBridgeEmptyIdentityFailsClosed
      , check growthBridgeContractIsSemanticOnly
      ]
  let named = mapM (\(name, p) -> putStrLn name >> check p)
  usul <- named usulProperties
  concepts <- named conceptProperties
  domainVectors <- proofGraphDomainVectors
  unless (and (results ++ exclusions ++ rest ++ usul ++ concepts ++ [domainVectors])) exitFailure
