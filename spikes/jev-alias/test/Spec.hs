module Main (main) where

import Data.Aeson (Value, decode, eitherDecode, toJSON)
import Data.ByteString.Lazy.Char8 qualified as LBS
import Data.Either (isLeft)
import Data.List (nub)
import Data.Map.Strict qualified as Map
import Data.Maybe (fromJust, isJust)
import Jev.Alias
import Jev.Gate
import Jev.Typed
import Jev.Wire
import Oracle.ProofGraph (ProofEdge (..), ProofNode (..))
import Oracle.Result (AuthorityQuestion (..), OracleResult (..), authoritativeFor)
import System.Exit (exitFailure)
import Test.QuickCheck

-- Conformance: examples copied verbatim from https://docs.typesafe.ai/api.md.

docChoiceResponse :: LBS.ByteString
docChoiceResponse =
  "{\"model\":\"jev-1.13.0\",\"answers\":{\"department\":{\"type\":\"choice\",\"choice\":\"billing\",\
  \\"probabilities\":{\"billing\":0.88,\"technical\":0.12,\"sales\":0.0},\"confidence\":0.81}},\
  \\"usage\":{\"input_tokens\":318,\"output_tokens\":34}}"

docScoreAndNoulResponse :: LBS.ByteString
docScoreAndNoulResponse =
  "{\"model\":\"jev-1.13.0\",\"answers\":{\"frustration\":{\"type\":\"score\",\"score\":1.05,\
  \\"legend\":{\"0\":\"Calm\",\"1\":\"Frustrated\",\"2\":\"Very angry\"},\
  \\"probabilities\":{\"0\":0.0,\"1\":0.95,\"2\":0.05},\"confidence\":0.92},\
  \\"is_urgent\":{\"type\":\"noul\",\"noul\":0.95}},\"usage\":{\"input_tokens\":304,\"output_tokens\":18}}"

docChoiceRequest :: LBS.ByteString
docChoiceRequest =
  "{\"state\":\"Help! My payouts have been failing for 3 days.\",\"model\":\"jev-latest\",\
  \\"questions\":{\"department\":{\"type\":\"choice\",\"instructions\":\"Which team should handle this?\",\
  \\"criteria\":{\"billing\":\"Payments, invoicing, refunds\",\"technical\":\"Bugs, outages, integrations\",\
  \\"sales\":\"Pricing, upgrades, new accounts\"}}}}"

data Department = Billing | Technical | Sales
  deriving (Eq, Show, Bounded, Enum)

instance Option Department where
  optionKey Billing = "billing"
  optionKey Technical = "technical"
  optionKey Sales = "sales"
  rubric Billing = Just "Payments, invoicing, refunds"
  rubric Technical = Just "Bugs, outages, integrations"
  rubric Sales = Just "Pricing, upgrades, new accounts"

prop_docChoiceDecodes :: Property
prop_docChoiceDecodes =
  (decodeChoice @Department <$> (Map.lookup "department" . answers =<< decode docChoiceResponse))
    === Just (Right (Decision Billing [(Billing, 0.88), (Technical, 0.12), (Sales, 0.0)] 0.81))

prop_docScoreAndNoulDecode :: Property
prop_docScoreAndNoulDecode =
  (answers <$> eitherDecode docScoreAndNoulResponse)
    === Right
      ( Map.fromList
          [ ("frustration", ScoreAnswer 1.05 (Map.fromList [(0, 0.0), (1, 0.95), (2, 0.05)]) 0.92)
          , ("is_urgent", NoulAnswer 0.95)
          ]
      )

prop_typedRequestMatchesDoc :: Property
prop_typedRequestMatchesDoc =
  Just (toJSON (Request "Help! My payouts have been failing for 3 days." "jev-latest" questionMap))
    === (decode docChoiceRequest :: Maybe Value)
 where
  questionMap = Map.singleton "department" (choice @Department "Which team should handle this?")

-- Typed codec.

instance Arbitrary Relation where
  arbitrary = arbitraryBoundedEnum

newtype Unit = Unit Double deriving (Show)

instance Arbitrary Unit where
  arbitrary = Unit <$> choose (0, 1)

answerFor :: Relation -> Double -> Answer
answerFor r conf =
  ChoiceAnswer (optionKey r) (Map.fromList [(optionKey o, if o == r then 1 else 0) | o <- universe @Relation]) conf

prop_codecTotal :: Relation -> Unit -> Property
prop_codecTotal r (Unit c) = (selected <$> decodeChoice @Relation (answerFor r c)) === Right r

prop_rejectsForeignOptionSet :: Property
prop_rejectsForeignOptionSet =
  property (isLeft (decodeChoice @Relation =<< Right (fromJust (Map.lookup "department" . answers =<< decode docChoiceResponse))))

prop_rejectsNonDistribution :: Relation -> Property
prop_rejectsNonDistribution r =
  property (isLeft (decodeChoice @Relation (ChoiceAnswer (optionKey r) (Map.fromList [(optionKey o, 0.9) | o <- universe @Relation]) 0.5)))

-- Gate.

prop_gateMonotone :: Relation -> Unit -> Unit -> Unit -> Property
prop_gateMonotone r (Unit c) (Unit a) (Unit b) =
  let (lo, hi) = (min a b, max a b)
      d = Decision r [] c
      acts f = case gate (fromJust (mkFloor f)) d of Act _ -> True; Escalate _ _ -> False
   in acts hi ==> acts lo

prop_floorBounded :: Double -> Property
prop_floorBounded f = isJust (mkFloor f) === (0 <= f && f <= 1)

-- Alias oracle.

ids :: [String]
ids = ["Census", "PIP census", "Lemma", "Proof", "Galois", "Conditional"]

newtype Nodes = Nodes [ProofNode] deriving (Show)

instance Arbitrary Nodes where
  arbitrary = Nodes <$> listOf (ProofNode <$> elements ids <*> elements ["claim", "lemma"])

prop_pairsCanonical :: Nodes -> Property
prop_pairsCanonical (Nodes ns) =
  let n = length (nub (nodeId <$> ns))
   in (candidatePairs ns === candidatePairs (reverse ns <> ns))
        .&&. (length (candidatePairs ns) === n * (n - 1) `div` 2)

synonym :: String -> String -> ProofEdge
synonym a b = ProofEdge "synonymous" a b "theorem-backed" "aliases"

prop_declaredIsEquivalence :: Property
prop_declaredIsEquivalence =
  let edges = [synonym "PIP census" "Census", synonym "Census" "Census (2024)"]
      rel a b = declaredRelation edges (fromJust (mkPair a b))
   in (rel "PIP census" "Census (2024)" === SameObject)
        .&&. (rel "Census (2024)" "PIP census" === SameObject)
        .&&. (rel "Census" "Lemma" === DistinctObject)

vectorNodes :: [ProofNode]
vectorNodes = [ProofNode i "claim" | i <- ["Census", "PIP census", "Lemma"]]

vectorEdges :: [ProofEdge]
vectorEdges = [synonym "PIP census" "Census"]

respond :: (Pair -> (Relation, Double)) -> Probe -> Response
respond oracle p = Response "jev-1.13.0" (uncurry answerFor . oracle <$> probePairs p) (Usage 0 0)

floor80 :: Floor
floor80 = fromJust (mkFloor 0.8)

truthful :: Pair -> (Relation, Double)
truthful p = (declaredRelation vectorEdges p, 0.95)

prop_judgeAgrees :: Property
prop_judgeAgrees =
  let p = probe "jev-latest" vectorNodes
   in judge floor80 vectorEdges p (respond truthful p) === ModelsAgree

prop_judgeCounterexample :: Property
prop_judgeCounterexample =
  let p = probe "jev-latest" vectorNodes
      lemmaIsCensus = fromJust (mkPair "Census" "Lemma")
      oracle q = if q == lemmaIsCensus then (SameObject, 0.9) else truthful q
   in judge floor80 vectorEdges p (respond oracle p)
        === ModelsDisagree [Disagreement lemmaIsCensus DistinctObject SameObject 0.9]

prop_judgeEscalates :: Property
prop_judgeEscalates =
  let p = probe "jev-latest" vectorNodes
      oracle q = (fst (truthful q), 0.5)
   in judge floor80 vectorEdges p (respond oracle p)
        === Inconclusive "3 of 3 pairs below confidence floor"

prop_judgeFailsClosedOnMissingAnswer :: Property
prop_judgeFailsClosedOnMissingAnswer =
  let p = probe "jev-latest" vectorNodes
      r = respond truthful p
   in judge floor80 vectorEdges p r {answers = Map.deleteMin (answers r)}
        === OracleError "answer ids differ from question ids"

prop_neverAuthoritative :: Nodes -> Unit -> Property
prop_neverAuthoritative (Nodes ns) (Unit c) =
  let p = probe "jev-latest" ns
      result = judge floor80 vectorEdges p (respond (\q -> (fst (truthful q), c)) p)
   in conjoin
        [ authoritativeFor spikeAuthority q result === False
        | q <-
            [ ContractInterpretation, NormalForm, ObservationalEquivalence, CompositionPreservation
            , MathematicalProof, CertificateAcceptance, EffectAuthorization, PersistedState
            ]
        ]

main :: IO ()
main = do
  results <-
    traverse
      (\(name, prop) -> putStr (name <> ": ") >> quickCheckResult prop)
      [ ("doc choice response decodes", property prop_docChoiceDecodes)
      , ("doc score+noul response decodes", property prop_docScoreAndNoulDecode)
      , ("typed request matches doc", property prop_typedRequestMatchesDoc)
      , ("codec total", property prop_codecTotal)
      , ("rejects foreign option set", property prop_rejectsForeignOptionSet)
      , ("rejects non-distribution", property prop_rejectsNonDistribution)
      , ("gate monotone", property prop_gateMonotone)
      , ("floor bounded", property prop_floorBounded)
      , ("pairs canonical", property prop_pairsCanonical)
      , ("declared aliasing is an equivalence", property prop_declaredIsEquivalence)
      , ("judge agrees", property prop_judgeAgrees)
      , ("judge counterexample", property prop_judgeCounterexample)
      , ("judge escalates", property prop_judgeEscalates)
      , ("judge fails closed", property prop_judgeFailsClosedOnMissingAnswer)
      , ("never authoritative", property prop_neverAuthoritative)
      ]
  if all isSuccess results then pure () else exitFailure
