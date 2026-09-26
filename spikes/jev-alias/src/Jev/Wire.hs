-- | Wire model of TypeSafe's System One endpoint (@POST /v1/systemone@),
-- transcribed from https://docs.typesafe.ai/api.md. Authored, not generated.
module Jev.Wire
  ( Question (..)
  , Answer (..)
  , Request (..)
  , Response (..)
  , Usage (..)
  ) where

import Data.Aeson
import Data.Aeson.Types (Parser)
import Data.Map.Strict (Map)
import Data.Text (Text)

-- | Instructions and rubrics accept a string, object, or array, so they stay
-- as JSON values.
data Question
  = Noul
      { instructions :: Value
      , noulCriteria :: Maybe (Value, Value)
      -- ^ (meaning of yes, meaning of no)
      }
  | Choice
      { instructions :: Value
      , options :: Map Text (Maybe Value)
      -- ^ 1..255 options mapped to optional rubric
      }
  | Score
      { instructions :: Value
      , levels :: [Value]
      -- ^ 2..10 ordered level descriptions
      }
  deriving (Eq, Show)

data Answer
  = NoulAnswer Double
  | ChoiceAnswer
      { chosen :: Text
      , choiceProbabilities :: Map Text Double
      , choiceConfidence :: Double
      }
  | ScoreAnswer
      { expectedLevel :: Double
      , levelProbabilities :: Map Int Double
      , scoreConfidence :: Double
      }
  deriving (Eq, Show)

data Request = Request
  { state :: Value
  , model :: Text
  , questions :: Map Text Question
  }
  deriving (Eq, Show)

data Usage = Usage {inputTokens :: Int, outputTokens :: Int}
  deriving (Eq, Show)

data Response = Response
  { servedModel :: Text
  , answers :: Map Text Answer
  , usage :: Usage
  }
  deriving (Eq, Show)

instance ToJSON Question where
  toJSON (Noul i c) =
    object $
      ["type" .= ("noul" :: Text), "instructions" .= i]
        <> foldMap (\(yes, no) -> ["criteria" .= object ["true" .= yes, "false" .= no]]) c
  toJSON (Choice i o) =
    object ["type" .= ("choice" :: Text), "instructions" .= i, "criteria" .= o]
  toJSON (Score i l) =
    object ["type" .= ("score" :: Text), "instructions" .= i, "criteria" .= l]

instance ToJSON Request where
  toJSON (Request s m q) = object ["state" .= s, "model" .= m, "questions" .= q]

instance FromJSON Answer where
  parseJSON = withObject "Answer" $ \o -> o .: "type" >>= answerOf o
   where
    answerOf :: Object -> Text -> Parser Answer
    answerOf o "noul" = NoulAnswer <$> o .: "noul"
    answerOf o "choice" =
      ChoiceAnswer <$> o .: "choice" <*> o .: "probabilities" <*> o .: "confidence"
    answerOf o "score" =
      ScoreAnswer <$> o .: "score" <*> o .: "probabilities" <*> o .: "confidence"
    answerOf _ other = fail ("unknown answer type: " <> show other)

instance FromJSON Usage where
  parseJSON = withObject "Usage" $ \o ->
    Usage <$> o .: "input_tokens" <*> o .: "output_tokens"

instance FromJSON Response where
  parseJSON = withObject "Response" $ \o ->
    Response <$> o .: "model" <*> o .: "answers" <*> o .: "usage"
