module Main (main) where

import Oracle.Category (FiniteMap (..), compositionLaw, identityLaw)
import Oracle.Result
  ( AuthorityMode (..)
  , AuthorityQuestion (..)
  , OracleResult (..)
  , authoritativeFor
  )
import Oracle.SpruceGoose.DeploymentLifecycle
  ( DeploymentState (..)
  , Environment (..)
  , TransitionError (..)
  , allStates
  , allowedTransitions
  , isTerminal
  , replayTransitions
  , requiresRouting
  , transition
  )
import Test.QuickCheck
  ( Property
  , (===)
  , conjoin
  , counterexample
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

acceptedLifecycleEdgesProperty :: Property
acceptedLifecycleEdgesProperty =
  conjoin
    [ counterexample (show from ++ " -> " ++ show to) (transition from to === Right to)
    | from <- allStates
    , to <- allowedTransitions from
    ]

unlistedLifecycleEdgesFailClosedProperty :: Property
unlistedLifecycleEdgesFailClosedProperty =
  conjoin
    [ counterexample
        (show from ++ " -/-> " ++ show to)
        (transition from to === Left (IllegalTransition from to))
    | from <- allStates
    , to <- allStates
    , to `notElem` allowedTransitions from
    ]

canonicalReplayProperty :: Property
canonicalReplayProperty =
  conjoin
    [ replayTransitions [Building, Staged, Deploying, Verifying, Ready] === Right Ready
    , replayTransitions [Building, Failed, RollingBack, RolledBack] === Right RolledBack
    , replayTransitions [Cancelled] === Right Cancelled
    , replayTransitions [Building, Ready] === Left (IllegalTransition Building Ready)
    ]

terminalClassificationProperty :: Property
terminalClassificationProperty =
  conjoin
    [ isTerminal Ready === True
    , isTerminal Failed === True
    , isTerminal RolledBack === True
    , isTerminal Cancelled === True
    , isTerminal Queued === False
    , isTerminal RollingBack === False
    , transition Ready RollingBack === Right RollingBack
    , transition Failed RollingBack === Right RollingBack
    ]

routingRequirementProperty :: Property
routingRequirementProperty =
  conjoin
    [ requiresRouting Preview === False
    , requiresRouting Staging === False
    , requiresRouting Production === True
    ]

main :: IO ()
main = do
  quickCheck identityProperty
  quickCheck compositionProperty
  quickCheck normativeSemanticAuthorityProperty
  quickCheck advisoryNeverAuthoritativeProperty
  quickCheck excludedAuthorityProperty
  quickCheck inconclusiveNeverAuthoritativeProperty
  quickCheck acceptedLifecycleEdgesProperty
  quickCheck unlistedLifecycleEdgesFailClosedProperty
  quickCheck canonicalReplayProperty
  quickCheck terminalClassificationProperty
  quickCheck routingRequirementProperty
