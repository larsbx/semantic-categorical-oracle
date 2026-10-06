-- | Bounded laws for the usul advisory mirrors. Each law restates a Lean
-- theorem over the test domain; success is 'LawHoldsForTestDomain', never proof.
module Usul.Laws (usulProperties) where

import Data.List (isSubsequenceOf, sort)
import Oracle.Usul.Argumentation
import Oracle.Usul.Hukm
import Oracle.Usul.Sadi
import qualified Oracle.Usul.Schema as S
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
  , ("usul.sadi.q13-q36-consistent (Lean: q13_q36_consistent)",
      forAllOf [minBound .. maxBound] $ \p -> itlafLiable (withRight p) === (p == Benefit))
  , ("usul.sadi.q42-instance-of-q21 (Lean: q42_instance_of_q21)",
      forAllOf [minBound .. maxBound] $ \k -> forAllOf bools $ \kn ->
        reservationValid k kn === not (ghararForbidden k (not kn)))
  , ("usul.sadi.q29-qualifiers-narrow (Lean: q29_attach_narrows)", property $ \(x :: Int) (ms :: [Int]) m ->
      let q d y = y `mod` (1 + abs d) == 0
       in not (meaning even (map q (m : ms)) x) || meaning even (map q ms) x)
  , ("usul.sadi.q48-custom-monotone (Lean: q48_custom_monotone)", property $ \(ts :: [Integer]) (NonNegative g) (NonNegative d) ->
      not (continuous g ts) || continuous (g + d) ts)
  , ("usul.sadi.q34-best-admissible (Lean: q34_best_admissible)", property $ \(xs :: [(Int, Integer)]) ->
      maybe (null xs) (admissibleForOther snd xs) (best snd xs))
  , ("usul.schema.s2-first-monoid-hom (Lean: first_append)", property $ \(xs :: [Maybe Int]) ys ->
      S.firstSome (xs ++ ys) === maybe (S.firstSome ys) Just (S.firstSome xs))
  , ("usul.schema.s2-conservative (Lean: first_conservative)", property $ \(xs :: [Maybe Int]) ys ->
      maybe True (\a -> S.firstSome (xs ++ ys) == Just a) (S.firstSome xs))
  , ("usul.schema.s2-naturality (Lean: first_map, resolveD_map)", property $ \(xs :: [Maybe Int]) d ->
      let f = (* 3) . (+ 1) in f (S.resolveD xs d) === S.resolveD (map (fmap f) xs) (f d))
  , ("usul.schema.s2-taarud-is-priority (Lean: taarud_is_priority)", property $ \(j :: Maybe Int) n t ->
      resolve (Conflict j n t) === S.resolveD [Jam <$> j, Naskh <$> n, Tarjih <$> t] Tawaqquf)
  , ("usul.schema.s4-closure-laws (Lean: extensive, idem, mono, least)", property $ \(es :: [(Small Int, Small Int)]) (ss :: [Small Int]) extra ->
      let step = [(getSmall a `mod` 8, getSmall b `mod` 8) | (a, b) <- es]
          seed = map ((`mod` 8) . getSmall) ss
          c = S.closure step seed
       in all (`elem` c) seed
            && S.closure step c == c
            && all (`elem` S.closure step (getSmall extra `mod` 8 : seed)) c
            && and [b `elem` c | (a, b) <- step, a `elem` c])
  , ("usul.schema.s7-reps (Lean: reps_covers, reps_length_le, reps_sub)", property $ \(xs :: [(Small Int, Small Int)]) ->
      let r a b = fst a `mod` 3 == fst b `mod` 3   -- same kind, any occasion
          rs = S.reps r xs
       in S.covers r rs xs && length rs <= length xs && all (`elem` xs) rs)
  , ("usul.schema.s8-optimal (Lean: best_optimal, Optimal.key_unique, Optimal.restrict, Optimal.mono)", property $ \(xs :: [(Int, Integer)]) (ys :: [Bool]) ->
      case best snd xs of
        Nothing -> null xs
        Just b ->
          let others = [x | (x, keep) <- zip xs (ys ++ repeat True), keep || x == b]
           in S.optimal snd xs b
                && and [snd o == snd b | o <- xs, S.optimal snd xs o]
                && S.optimal snd others b
                && S.optimal ((* 2) . (+ 1) . snd) xs b)
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
