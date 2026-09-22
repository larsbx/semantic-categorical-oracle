# SpruceGoose deployment transition contract v1

Status: implementation spike; domain approval pending.

## Plan

1. Pin the source lifecycle and distinguish semantic authority from operational authority.
2. Encode the lifecycle as a total, fail-closed Haskell transition relation.
3. Exercise every accepted and rejected state pair plus canonical replay vectors.
4. Add certified-event chain and operation-phase replay only after this contract is approved.

## Provenance

- Source repository: `larsbx/sprucegoose`
- Reviewed revision: `c211ff67f244d92351a7bdf270987bbb619a6b0d`
- Primary source: `lib/spruce_goose/deployment/lifecycle.ex`
- Context sources: `lib/spruce_goose/deployment/projection.ex` and
  `lib/spruce_goose/deployment/record.ex`
- Artifact class: `authored_oracle` (manual independent implementation, not
  mechanical extraction)

## Implemented semantic surface

The Haskell module fixes the v1 state vocabulary, initial state, legal transition
relation, terminal classification, state-name parser, environment vocabulary,
production routing requirement, and fail-closed transition replay.

The review vectors cover a successful deployment, failure followed by rollback,
cancellation, and an illegal skipped transition. Tests also enumerate every
state pair, so an unlisted edge must be refused.

## Authority boundary

This spike remains a `normative_semantic_candidate` until SpruceGoose's domain
authority approves the contract identifier and vectors. If promoted, it may be
authoritative only for interpretation and composition of
`deployment-transition-v1`.

SpruceGoose remains authoritative for persisted deployment records, event
admission, authorization, routing evidence, and effect execution. This module
does not claim that a transition occurred; it only interprets whether a proposed
state edge is legal under the pinned contract.
