module Oracle.ProofGraph
  ( ProofNode (..)
  , ProofEdge (..)
  , normalizeNodes
  , normalizeEdges
  ) where

import Data.List (sort)

-- | Representation-only node. This type carries ledger data; it does not decide
-- whether a statement is proved or whether any certificate is accepted.
data ProofNode = ProofNode
  { nodeId :: String
  , nodeKind :: String
  }
  deriving (Eq, Ord, Show)

-- | Representation-only edge. Provenance and use-site participate in the
-- normal form, so an open premise cannot collapse into theorem-backed evidence.
data ProofEdge = ProofEdge
  { edgeType :: String
  , edgeSource :: String
  , edgeTarget :: String
  , edgeProvenance :: String
  , edgeUseSite :: String
  }
  deriving (Eq, Ord, Show)

-- | Canonical ordering with exact duplicate collapse. Conflicting payloads
-- remain distinct and therefore visible to the caller.
normalizeNodes :: [ProofNode] -> [ProofNode]
normalizeNodes = uniqueSorted

normalizeEdges :: [ProofEdge] -> [ProofEdge]
normalizeEdges = uniqueSorted

uniqueSorted :: Ord value => [value] -> [value]
uniqueSorted = deduplicate . sort
 where
  deduplicate [] = []
  deduplicate (first : rest) = first : after first rest
  after _ [] = []
  after previous (current : rest)
    | previous == current = after previous rest
    | otherwise = current : after current rest
