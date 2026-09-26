-- | Confidence-gated routing (https://docs.typesafe.ai/patterns/confidence-routing.md):
-- the answer says what, confidence says whether code may act on it.
module Jev.Gate
  ( Floor
  , mkFloor
  , Gated (..)
  , gate
  ) where

import Jev.Typed (Decision (..))

-- | A confidence floor in [0, 1].
newtype Floor = Floor Double
  deriving (Eq, Ord, Show)

mkFloor :: Double -> Maybe Floor
mkFloor f
  | 0 <= f && f <= 1 = Just (Floor f)
  | otherwise = Nothing

data Gated a
  = Act a
  | Escalate a Double
  -- ^ tentative answer and the confidence that fell short
  deriving (Eq, Show)

gate :: Floor -> Decision a -> Gated a
gate (Floor f) d
  | confidence d >= f = Act (selected d)
  | otherwise = Escalate (selected d) (confidence d)
