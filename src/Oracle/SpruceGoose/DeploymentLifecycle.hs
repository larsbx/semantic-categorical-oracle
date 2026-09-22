module Oracle.SpruceGoose.DeploymentLifecycle
  ( DeploymentState (..)
  , Environment (..)
  , TransitionError (..)
  , allStates
  , allowedTransitions
  , initialState
  , isTerminal
  , parseState
  , replayTransitions
  , requiresRouting
  , transition
  ) where

import Control.Monad (foldM)

-- | The state vocabulary of SpruceGoose deployment lifecycle contract v1.
data DeploymentState
  = Queued
  | Building
  | Staged
  | Deploying
  | Verifying
  | Ready
  | Failed
  | RollingBack
  | RolledBack
  | Cancelled
  deriving (Bounded, Enum, Eq, Ord, Show)

data Environment
  = Preview
  | Staging
  | Production
  deriving (Bounded, Enum, Eq, Ord, Show)

data TransitionError
  = UnknownState String
  | IllegalTransition DeploymentState DeploymentState
  deriving (Eq, Show)

allStates :: [DeploymentState]
allStates = [minBound .. maxBound]

initialState :: DeploymentState
initialState = Queued

allowedTransitions :: DeploymentState -> [DeploymentState]
allowedTransitions Queued = [Building, Cancelled]
allowedTransitions Building = [Staged, Failed, Cancelled]
allowedTransitions Staged = [Deploying, Cancelled]
allowedTransitions Deploying = [Verifying, Failed, RollingBack]
allowedTransitions Verifying = [Ready, Failed, RollingBack]
allowedTransitions Ready = [RollingBack]
allowedTransitions Failed = [RollingBack]
allowedTransitions RollingBack = [RolledBack, Failed]
allowedTransitions RolledBack = []
allowedTransitions Cancelled = []

transition :: DeploymentState -> DeploymentState -> Either TransitionError DeploymentState
transition from to
  | to `elem` allowedTransitions from = Right to
  | otherwise = Left (IllegalTransition from to)

-- | Replay is fail-closed: the first illegal edge stops the fold.
replayTransitions :: [DeploymentState] -> Either TransitionError DeploymentState
replayTransitions = foldM transition initialState

isTerminal :: DeploymentState -> Bool
isTerminal Ready = True
isTerminal Failed = True
isTerminal RolledBack = True
isTerminal Cancelled = True
isTerminal _ = False

requiresRouting :: Environment -> Bool
requiresRouting Production = True
requiresRouting _ = False

parseState :: String -> Either TransitionError DeploymentState
parseState "queued" = Right Queued
parseState "building" = Right Building
parseState "staged" = Right Staged
parseState "deploying" = Right Deploying
parseState "verifying" = Right Verifying
parseState "ready" = Right Ready
parseState "failed" = Right Failed
parseState "rolling_back" = Right RollingBack
parseState "rolled_back" = Right RolledBack
parseState "cancelled" = Right Cancelled
parseState value = Left (UnknownState value)
