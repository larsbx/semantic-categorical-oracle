-- | Bounded laws for the concept pre-filter migrated from tui-story. Success is
-- 'LawHoldsForTestDomain' over small generated graphs, never proof.
module Concept.Laws (conceptProperties) where

import Data.Either (isLeft)
import Data.Maybe (fromJust)
import Oracle.Concept.Assertion
import Oracle.Concept.Filter
import Oracle.Concept.Relation
import Oracle.Concept.Validate
import Test.QuickCheck hiding (certainty)

concept :: String -> Concept
concept = either (error . show) id . validateConcept

-- | A five-letter universe keeps collisions, cycles, and conflicts frequent.
universe :: [String]
universe = ["alpha", "beta", "gamma", "delta", "eps"]

relations :: [Relation]
relations = [minBound .. maxBound]

assertion :: Gen Assertion
assertion =
  Assertion
    <$> elements (map concept universe)
    <*> elements (map concept universe)
    <*> elements relations
    <*> elements (map (fromJust . certainty) [0, 0.25, 0.5, 0.75, 1])
    <*> elements ["", "x", "y"]

forGraph :: Testable p => ([Assertion] -> p) -> Property
forGraph = forAllShow (resize 12 (listOf assertion)) show

forAllOf :: (Show a, Testable p) => [a] -> (a -> p) -> Property
forAllOf xs f = conjoin [counterexample (show x) (f x) | x <- xs]

flipSymmetric :: Assertion -> Assertion
flipSymmetric a
  | isSymmetric (assertionRelation a) = a {assertionSource = assertionTarget a, assertionTarget = assertionSource a}
  | otherwise = a

admit :: [Assertion] -> Admission
admit = filterConcepts defaultPolicy universe

rel :: String -> Relation -> String -> Double -> Assertion
rel s r t p = Assertion (concept s) (concept t) r (fromJust (certainty p)) ""

conceptProperties :: [(String, Property)]
conceptProperties =
  [ ("concept.relation.tag-roundtrip", forAllOf relations $ \r ->
      parseRelation (relationTag r) === Just r)
  , ("concept.relation.unknown-tag-fails-closed",
      parseRelation "friendship" === Nothing)
  , ("concept.relation.table (SEMANTIC_ANALYSIS.md s2)",
      ( filter isSymmetric relations, filter isTransitive relations )
        === ([Contradictory, Analogous, Synonymous, Antonymous], [Implicative, Hierarchical, Synonymous]))
  , ("concept.relation.incompatible-symmetric-irreflexive", forAllOf relations $ \a -> forAllOf relations $ \b ->
      incompatible a b === incompatible b a .&&. not (incompatible a a))
  , ("concept.validate.normal-form", property $ \s ->
      either (const True) (\c -> validateConcept (conceptText c) == Right c) (validateConcept s))
  , ("concept.validate.s1-s4", property $ \s -> case validateConcept s of
      Left _ -> True
      Right c -> let t = conceptText c in not (null t) && length t <= maxConceptLength && notElem '\0' t)
  , ("concept.validate.vectors",
      map validateConcept ["  ", replicate 1001 'a', "a\0b", "a\ESCb"]
        === map Left [EmptyConcept, ConceptTooLong 1001, NullByte, ControlCharacter]
        .&&. validateConcept "  Free\tWill " === Right (concept "free will"))
  , ("concept.raw.fails-closed",
      map (isLeft . fromRaw)
        [ RawAssertion "a" "b" "friendship" 0.9 ""
        , RawAssertion "a" "b" "causal" 1.5 ""
        , RawAssertion "a" "b" "causal" (0 / 0) ""
        , RawAssertion "" "b" "causal" 0.5 ""
        ]
        === replicate 4 True)
  , ("concept.normalize.idempotent", forGraph $ \xs ->
      normalizeAssertions (normalizeAssertions xs) === normalizeAssertions xs)
  , ("concept.normalize.order-and-orientation-invariant", forGraph $ \xs ->
      normalizeAssertions (map flipSymmetric (reverse xs)) === normalizeAssertions xs)
  , ("concept.normalize.keeps-max-certainty (edge.ex duplicate rule)", forGraph $ \xs ->
      all (\a -> all (\b -> assertionCertainty b <= assertionCertainty a)
                     [b | b <- normalizeAssertions xs, key b == key a])
          (normalizeAssertions xs)
        && all (\(s, t) -> s /= t) (map endpoints (normalizeAssertions xs)))
  , ("concept.saturate.closed", forGraph $ \xs ->
      let ys = saturate xs in saturate ys === ys)
  , ("concept.filter.sound", forGraph $ \xs ->
      let a = admit xs
       in all (`notElem` admitted a) [canonicalOf' a c | Conflict (s, t) _ <- conflicts a, c <- [s, t]]
            && all (\x -> all (`elem` admitted a) [assertionSource x, assertionTarget x]) (retained a)
            && notElem Synonymous (map assertionRelation (retained a)))
  , ("concept.filter.idempotent", forGraph $ \xs ->
      let a = admit xs
          b = filterConcepts defaultPolicy (map conceptText (admitted a)) (retained a)
       in (admitted b, retained b, conflicts b) === (admitted a, retained a, []))
  , ("concept.filter.synonyms-collapse",
      let a = filterConcepts defaultPolicy ["Car", "automobile", "wheel"]
                [rel "car" Synonymous "automobile" 0.9, rel "wheel" PartWhole "car" 0.8]
       in (admitted a, aliases a, retained a)
            === ( map concept ["automobile", "wheel"]
                , [(concept "car", concept "automobile")]
                , [rel "wheel" PartWhole "automobile" 0.8] ))
  , ("concept.filter.below-threshold-ignored",
      admitted (filterConcepts defaultPolicy ["car", "automobile"] [rel "car" Synonymous "automobile" 0.4])
        === map concept ["automobile", "car"])
  , ("concept.filter.synonym-antonym-quarantined",
      let a = filterConcepts defaultPolicy ["cat", "feline", "dog"]
                [rel "cat" Synonymous "feline" 0.9, rel "feline" Antonymous "cat" 0.6]
       in (admitted a, quarantined a) === ([concept "dog"], [concept "cat"]))
  , ("concept.filter.derived-contradiction (C2 over closure)",
      let a = filterConcepts defaultPolicy ["p", "q", "r"]
                [rel "p" Implicative "q" 0.9, rel "q" Implicative "r" 0.9, rel "r" Contradictory "p" 0.9]
       in (admitted a, quarantined a, retained a) === ([concept "q"], map concept ["p", "r"], []))
  , ("concept.filter.foreign-endpoints-discarded",
      retained (filterConcepts defaultPolicy ["a"] [rel "a" Causal "b" 1]) === [])
  ]
 where
  key a = (assertionSource a, assertionTarget a, assertionRelation a)
  canonicalOf' a c = maybe c id (lookup c (aliases a))
