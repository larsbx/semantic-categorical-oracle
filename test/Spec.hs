module Main (main) where

import Oracle.Category (FiniteMap (..), compositionLaw, identityLaw)
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

proofGraphDuplicateVector :: Property
proofGraphDuplicateVector =
  normalizeEdges [aliasEdge, aliasEdge] === [aliasEdge]
 where
  aliasEdge =
    ProofEdge "synonymous" "PIP census" "Census" "theorem-backed" "aliases"

main :: IO ()
main = do
  quickCheck identityProperty
  quickCheck compositionProperty
  quickCheck normativeSemanticAuthorityProperty
  quickCheck advisoryNeverAuthoritativeProperty
  mapM_
    (quickCheck . excludedAuthorityProperty)
    [MathematicalProof, CertificateAcceptance, EffectAuthorization, PersistedState]
  quickCheck inconclusiveNeverAuthoritativeProperty
  quickCheck proofGraphNodeVector
  quickCheck proofGraphProvenanceVector
  quickCheck proofGraphDuplicateVector
