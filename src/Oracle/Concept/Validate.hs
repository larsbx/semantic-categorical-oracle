module Oracle.Concept.Validate
  ( Concept
  , ConceptError (..)
  , conceptText
  , maxConceptLength
  , validateConcept
  ) where

import Data.Char (isControl, isSpace, toLower)

-- | A validated concept in normal form: whitespace-collapsed and case-folded,
-- so equality is the case-insensitive, trimmed match tui-story used to bind
-- LLM output back to vertices. The constructor is hidden.
newtype Concept = Concept String
  deriving (Eq, Ord, Show)

conceptText :: Concept -> String
conceptText (Concept text) = text

-- | Failure classes of tui-story @specs/ValidationLayer.tla@ that remain
-- meaningful for 'String' input (UTF-8 validity is the decoder's concern).
data ConceptError
  = EmptyConcept
  | ConceptTooLong Int
  | NullByte
  | ControlCharacter
  deriving (Eq, Ord, Show)

maxConceptLength :: Int
maxConceptLength = 1000

-- | Checks run in the specification's order: empty, length, null, control.
-- Whitespace controls (tab, newline) are normalised away, not rejected.
validateConcept :: String -> Either ConceptError Concept
validateConcept raw
  | null normal = Left EmptyConcept
  | length normal > maxConceptLength = Left (ConceptTooLong (length normal))
  | '\0' `elem` raw = Left NullByte
  | any (\c -> isControl c && not (isSpace c)) raw = Left ControlCharacter
  | otherwise = Right (Concept normal)
 where
  normal = map toLower (unwords (words raw))
