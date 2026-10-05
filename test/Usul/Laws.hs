-- | Bounded laws for the usul advisory mirrors. Each law restates a Lean
-- theorem over the test domain; success is 'LawHoldsForTestDomain', never proof.
module Usul.Laws (usulProperties) where

import Data.List (isSubsequenceOf, sort)
import Oracle.Usul.Argumentation
import Oracle.Usul.Hukm
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

usulProperties :: [(String, Property)]
usulProperties =
  [ ("usul.hukm.sigma-involutive (Lean: sigma_involutive)", forHukm $ \h -> sigma (sigma h) === h)
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
