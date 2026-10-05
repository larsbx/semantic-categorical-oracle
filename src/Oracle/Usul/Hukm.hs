-- | Advisory mirror of @Usul.Hukm@ (Lean). Constructors are declared in
-- valence order, so the derived 'Ord' is the valence order Ḥ < K < M < N < W.
module Oracle.Usul.Hukm
  ( Hukm (..)
  , Mode (..)
  , sigma
  , mode
  , binding
  ) where

data Hukm = Haram | Makruh | Mubah | Mandub | Wajib
  deriving (Eq, Ord, Show, Enum, Bounded)

data Mode = TalabFil | TalabTark | Takhyir
  deriving (Eq, Show)

-- | Status of an act's omission: /al-amr bi'l-shayʾ nahy ʿan ḍiddih/.
sigma :: Hukm -> Hukm
sigma = toEnum . (fromEnum (maxBound :: Hukm) -) . fromEnum

mode :: Hukm -> Mode
mode h
  | h > Mubah = TalabFil
  | h < Mubah = TalabTark
  | otherwise = Takhyir

binding :: Hukm -> Bool
binding = (`elem` [Wajib, Haram])
