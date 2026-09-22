module Oracle.Result
  ( AuthorityMode (..)
  , AuthorityQuestion (..)
  , OracleResult (..)
  , authoritativeFor
  ) where

-- | Whether a registered model is normative for its declared semantic contract
-- or is only an advisory comparison model.
data AuthorityMode
  = NormativeSemantic
  | AdvisoryOracle
  deriving (Eq, Show)

-- | Questions are typed so semantic authority cannot silently widen into proof,
-- acceptance, authorization, or custody of operational state.
data AuthorityQuestion
  = ContractInterpretation
  | NormalForm
  | ObservationalEquivalence
  | CompositionPreservation
  | MathematicalProof
  | CertificateAcceptance
  | EffectAuthorization
  | PersistedState
  deriving (Eq, Show)

data OracleResult counterexample
  = LawHoldsForTestDomain
  | Counterexample counterexample
  | ModelsAgree
  | ModelsDisagree counterexample
  | Inconclusive String
  | OracleError String
  deriving (Eq, Show)

-- | A normative, registered contract may authoritatively answer semantic
-- questions when the result is conclusive. Advisory models and excluded
-- authority questions never acquire authority from a successful run.
authoritativeFor
  :: AuthorityMode
  -> AuthorityQuestion
  -> OracleResult counterexample
  -> Bool
authoritativeFor NormativeSemantic question result =
  isSemanticQuestion question && isConclusive result
authoritativeFor AdvisoryOracle _ _ = False

isSemanticQuestion :: AuthorityQuestion -> Bool
isSemanticQuestion ContractInterpretation = True
isSemanticQuestion NormalForm = True
isSemanticQuestion ObservationalEquivalence = True
isSemanticQuestion CompositionPreservation = True
isSemanticQuestion MathematicalProof = False
isSemanticQuestion CertificateAcceptance = False
isSemanticQuestion EffectAuthorization = False
isSemanticQuestion PersistedState = False

isConclusive :: OracleResult counterexample -> Bool
isConclusive (Inconclusive _) = False
isConclusive (OracleError _) = False
isConclusive _ = True
