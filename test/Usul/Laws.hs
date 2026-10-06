-- | Bounded laws for the usul advisory mirrors. Each law restates a Lean
-- theorem over the test domain; success is 'LawHoldsForTestDomain', never proof.
module Usul.Laws (usulProperties) where

import Data.List (isSubsequenceOf, sort)
import Oracle.Usul.Argumentation
import Oracle.Usul.Hukm
import Oracle.Usul.Sadi
import Oracle.Usul.Taarud
import Test.QuickCheck
import Usul.GroundedVectors (groundedVectors)

-- | Small frameworks: brute force over all 2^n subsets stays cheap.
af :: Gen AF
af = do
  n <- chooseInt (0, 6)
  AF n <$> sublistOf [(a, b) | a <- [0 .. n - 1], b <- [0 .. n - 1]]

-- | Hukm is finite: quantify exhaustively rather than by sampling.
forHukm :: Testable p => (Hukm -> p) -> Property
forHukm f = conjoin [counterexample (show h) (f h) | h <- [minBound .. maxBound]]

forHukm2 :: Testable p => (Hukm -> Hukm -> p) -> Property
forHukm2 f = forHukm (forHukm . f)

forAF :: Testable p => (AF -> p) -> Property
forAF = forAllShow af show

-- | Exhaustive over a small finite enumeration.
forAllOf :: (Show a, Testable p) => [a] -> (a -> p) -> Property
forAllOf xs f = conjoin [counterexample (show x) (f x) | x <- xs]

bools :: [Bool]
bools = [False, True]

usulProperties :: [(String, Property)]
usulProperties =
  [ ("usul.sadi.q04-no-wajib-with-inability (Lean: q04_no_wajib_with_inability)",
      forAllOf bools $ \d -> forHukm $ \h -> operative False d h /= Wajib)
  , ("usul.sadi.q04-no-haram-with-necessity (Lean: q04_no_haram_with_necessity)",
      forAllOf bools $ \c -> forHukm $ \h -> operative c True h /= Haram)
  , ("usul.sadi.q04-relief-never-binds (Lean: q04_relief_never_binds)",
      forAllOf bools $ \c -> forAllOf bools $ \d -> forHukm $ \h -> not (binding (operative c d h)) || binding h)
  , ("usul.sadi.q22-valid-iff-preserves-prohibition (Lean: q22_valid_iff_preserves_prohibition)",
      forHukm2 $ \a b -> not (voids a b) == ((a == Haram) == (b == Haram)))
  , ("usul.sadi.q33-higher-benefit (Lean: q33_higher_benefit)", property $ \(xs :: [(Int, Integer)]) ->
      case best snd xs of
        Nothing -> null xs
        Just b -> b `elem` xs && all (\y -> snd y <= snd b) xs)
  , ("usul.sadi.q33-lighter-harm (Lean: q33_lighter_harm)", property $ \(xs :: [(Int, Integer)]) ->
      maybe (null xs) (\b -> all (\y -> snd b <= snd y) xs) (best (negate . snd) xs))
  , ("usul.sadi.q58-factorisation (Lean: q58_factors)", property $ \(xs :: [(Int, Int)]) ->
      -- a ruling defined through the ʿilla depends only on it
      let ruling (_, f) = toEnum (f `mod` 5) :: Hukm in dependsOn xs ruling snd)
  , ("usul.sadi.q59-q60-generality (Lean: q59_*, q60_markers_general)",
      forAllOf [minBound .. maxBound] $ \f -> forAllOf [minBound .. maxBound] $ \c ->
        isGeneral f c == (f /= Nakira || c `elem` [Negation, Prohibition, Condition]))
  , ("usul.hukm.sigma-involutive (Lean: sigma_involutive)", forHukm $ \h -> sigma (sigma h) === h)
  , ("usul.hukm.sigma-antitone (Lean: sigma_antitone)", forHukm2 $ \a b -> not (a <= b) || sigma b <= sigma a)
  , ("usul.hukm.sigma-fixed-iff-mubah (Lean: sigma_fixed_iff)", forHukm $ \h -> (sigma h == h) === (h == Mubah))
  , ("usul.hukm.mode-binding-injective", forHukm2 $ \a b ->
      not (mode a == mode b && binding a == binding b) || a == b)
  , ("usul.af.grounded-conflict-free (Lean: approx_conflictFree)", forAF $ \f -> conflictFree f (grounded f))
  , ("usul.af.grounded-admissible (Lean: approx_admissible)", forAF $ \f -> admissible f (grounded f))
  , ("usul.af.grounded-complete", forAF $ \f -> complete f (grounded f))
  , ("usul.af.grounded-least-complete (Lean: approx_sub_complete)", forAF $ \f ->
      all (\e -> sort (grounded f) `isSubsequenceOf` sort e) (filter (complete f) (subsets f)))
  , ("usul.af.grounded-v1-vectors", conjoin
      [ counterexample name (sort (grounded (AF n att)) === g)
      | (name, n, att, g) <- groundedVectors
      ])
  , ("usul.taarud.jam-first (Lean: resolve_jam_first)", property $ \(p :: Int) n t ->
      resolve (Conflict (Just p) n t) === Jam p)
  , ("usul.taarud.tawaqquf-iff-exhausted (Lean: resolve_tawaqquf_iff)", property $ \(c :: (Maybe Int, Maybe Int, Maybe Int)) ->
      let (j, n, t) = c in (resolve (Conflict j n t) == Tawaqquf) === (j == Nothing && n == Nothing && t == Nothing))
  ]
