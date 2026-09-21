module Oracle.Result
  ( OracleResult (..)
  , isAuthoritative
  ) where

-- | Evidence vocabulary deliberately excludes proof, acceptance, and
-- authorization verdicts.
data OracleResult counterexample
  = LawHoldsForTestDomain
  | Counterexample counterexample
  | ModelsAgree
  | ModelsDisagree counterexample
  | Inconclusive String
  | OracleError String
  deriving stock (Eq, Show)

-- | The semantic oracle is never an authority, regardless of its result.
isAuthoritative :: OracleResult counterexample -> Bool
isAuthoritative _ = False
