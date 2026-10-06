-- | Advisory mirror of @Usul.Qiyas@ (Lean): the computable masālik al-ʿilla (ṭard, ʿaks,
-- dawarān, al-sabr wa'l-taqsīm) and the naqḍ-family objections.
module Oracle.Usul.Qiyas
  ( tard
  , aks
  , dawaran
  , naqd
  , adamTathir
  , survivors
  ) where

-- | Ṭard: wherever the waṣf is found among the given cases, the ruling is found.
tard :: Eq b => (a -> Bool) -> b -> [(a, b)] -> Bool
tard w r = all (\(x, b) -> not (w x) || b == r)

-- | ʿAks: wherever the waṣf is absent, the ruling is absent.
aks :: Eq b => (a -> Bool) -> b -> [(a, b)] -> Bool
aks w r = all (\(x, b) -> w x || b /= r)

-- | Dawarān: the ruling turns with the waṣf, present and absent (Q58).
dawaran :: Eq b => (a -> Bool) -> b -> [(a, b)] -> Bool
dawaran w r known = tard w r known && aks w r known

-- | Naqḍ: a given case with the waṣf and a different ruling.
naqd :: Eq b => (a -> Bool) -> b -> [(a, b)] -> Bool
naqd w r = any (\(x, b) -> w x && b /= r)

-- | ʿAdam al-taʾthīr: the ruling found without the waṣf.
adamTathir :: Eq b => (a -> Bool) -> b -> [(a, b)] -> Bool
adamTathir w r = any (\(x, b) -> not (w x) && b == r)

-- | Al-sabr wa'l-taqsīm: the candidates a refutation test does not eliminate.
survivors :: (w -> Bool) -> [w] -> [w]
survivors refuted = filter (not . refuted)
