module Oracle.GrowthBridge
  ( GrowthBridgeContract (..)
  , ModuleWitness (..)
  , contractId
  , contractQuestion
  , cycleBasisEquivalent
  ) where

import Oracle.Result
  ( AuthorityQuestion (..)
  , OracleResult (..)
  )

data GrowthBridgeContract
  = GBCycleBasis001
  | GBCocycleTransport001
  | GBFixtureEquivalence001
  deriving (Eq, Ord, Show)

data ModuleWitness = ModuleWitness
  { componentId :: String
  , arithmeticBasisId :: String
  , generatedModuleId :: String
  }
  deriving (Eq, Ord, Show)

contractId :: GrowthBridgeContract -> String
contractId GBCycleBasis001 = "GB-CYCLE-BASIS-001"
contractId GBCocycleTransport001 = "GB-COCYCLE-TRANSPORT-001"
contractId GBFixtureEquivalence001 = "GB-FIXTURE-EQUIVALENCE-001"

contractQuestion :: GrowthBridgeContract -> AuthorityQuestion
contractQuestion GBCycleBasis001 = NormalForm
contractQuestion GBCocycleTransport001 = CompositionPreservation
contractQuestion GBFixtureEquivalence001 = ObservationalEquivalence

-- | Interpret two domain-validated cycle presentations.
--
-- The mathematical checker that produced 'generatedModuleId' remains
-- authoritative for the finite algebra. This semantic contract only decides
-- whether two witnesses denote the same registered component, arithmetic
-- coordinate basis, and generated-module identity.
cycleBasisEquivalent
  :: ModuleWitness
  -> ModuleWitness
  -> OracleResult String
cycleBasisEquivalent left right
  | nullField "left.component_id" (componentId left) = OracleError "left.component_id is empty"
  | nullField "right.component_id" (componentId right) = OracleError "right.component_id is empty"
  | nullField "left.arithmetic_basis_id" (arithmeticBasisId left) = OracleError "left.arithmetic_basis_id is empty"
  | nullField "right.arithmetic_basis_id" (arithmeticBasisId right) = OracleError "right.arithmetic_basis_id is empty"
  | nullField "left.generated_module_id" (generatedModuleId left) = OracleError "left.generated_module_id is empty"
  | nullField "right.generated_module_id" (generatedModuleId right) = OracleError "right.generated_module_id is empty"
  | componentId left /= componentId right =
      ModelsDisagree "component identity differs"
  | arithmeticBasisId left /= arithmeticBasisId right =
      ModelsDisagree "arithmetic basis identity differs"
  | generatedModuleId left /= generatedModuleId right =
      ModelsDisagree "generated module identity differs"
  | otherwise = ModelsAgree
 where
  nullField _ value = null value
