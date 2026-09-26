-- | Type-directed Choice questions: a finite Haskell sum type is the option
-- set, so encoding is total and decoding either yields a value of that type
-- or a precise wire-contract violation. Nothing here interprets confidence.
module Jev.Typed
  ( Option (..)
  , Decision (..)
  , DecodeError (..)
  , universe
  , choice
  , decodeChoice
  ) where

import Data.Aeson (Value)
import Data.List (find)
import Data.Map.Strict qualified as Map
import Data.Set qualified as Set
import Data.Text (Text)
import Jev.Wire (Answer (..), Question (..))

class (Bounded a, Enum a) => Option a where
  optionKey :: a -> Text
  rubric :: a -> Maybe Value
  rubric = const Nothing

universe :: (Bounded a, Enum a) => [a]
universe = [minBound .. maxBound]

data Decision a = Decision
  { selected :: a
  , distribution :: [(a, Double)]
  -- ^ in 'universe' order
  , confidence :: Double
  }
  deriving (Eq, Show)

data DecodeError
  = NotAChoice Answer
  | UnknownOption Text
  | OptionSetMismatch [Text] [Text]
  -- ^ expected keys, received keys
  | NotADistribution Double
  | ConfidenceOutOfRange Double
  deriving (Eq, Show)

choice :: forall a. Option a => Value -> Question
choice prompt =
  Choice prompt (Map.fromList [(optionKey o, rubric o) | o <- universe @a])

-- | Accepts exactly the documented Choice answer over exactly the option set
-- of @a@; any other shape is a contract violation, never a silent default.
decodeChoice :: forall a. Option a => Answer -> Either DecodeError (Decision a)
decodeChoice (ChoiceAnswer key probabilities conf) = do
  let expected = Set.fromList (optionKey <$> universe @a)
      received = Map.keysSet probabilities
      total = sum probabilities
  check (expected == received) (OptionSetMismatch (Set.toList expected) (Set.toList received))
  check (abs (total - 1) <= 1e-3 && all (>= 0) probabilities) (NotADistribution total)
  check (0 <= conf && conf <= 1) (ConfidenceOutOfRange conf)
  pick <- maybe (Left (UnknownOption key)) Right (find ((== key) . optionKey) (universe @a))
  pure
    Decision
      { selected = pick
      , distribution = [(o, probabilities Map.! optionKey o) | o <- universe @a]
      , confidence = conf
      }
 where
  check ok failure = if ok then Right () else Left failure
decodeChoice other = Left (NotAChoice other)
