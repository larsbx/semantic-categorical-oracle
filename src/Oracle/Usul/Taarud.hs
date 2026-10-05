-- | Advisory mirror of @Usul.Taarud@ (Lean): jamʿ, then naskh, then tarjīḥ,
-- else tawaqquf.
module Oracle.Usul.Taarud
  ( Conflict (..)
  , Resolution (..)
  , resolve
  ) where

import Control.Applicative ((<|>))
import Data.Maybe (fromMaybe)

data Conflict p = Conflict {jam :: Maybe p, naskh :: Maybe p, tarjih :: Maybe p}
  deriving (Eq, Show)

data Resolution p = Jam p | Naskh p | Tarjih p | Tawaqquf
  deriving (Eq, Show)

resolve :: Conflict p -> Resolution p
resolve c = fromMaybe Tawaqquf (Jam <$> jam c <|> Naskh <$> naskh c <|> Tarjih <$> tarjih c)
