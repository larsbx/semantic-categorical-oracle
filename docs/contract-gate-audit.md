# Normative contract gate audit

Audit date: 2026-09-22

## Result

Every migration-candidate source path is pinned to a full review commit and an
observed content blob in `registry/source-review.toml`. The executable audit
requires exact path agreement with the inventory, so paths cannot be added,
removed, or silently retargeted without updating the review record.

Only the finite proof-graph normalization contract advances to implementation.
The domain-owned contract has since been approved in finite-math-kernels, so the
old merge blocker is closed. The oracle remains non-normative under
`pending_implementation_update` until its source/vector pins are refreshed and
`Oracle.ProofGraph` conforms to the current domain-owned canonical vectors.

## Contract boundary findings

| Candidate | Identifier | Question-set result | Gate |
|---|---|---|---|
| finite proof graph | `finite-proof-graph-normalization/v1` | Interpretation, normal form, and composition preservation are representation semantics. Observational equivalence is deliberately omitted. | Domain contract approved; Haskell implementation and pins must be updated to the current canonical normal form before promotion |
| SpruceGoose deployment | `sprucegoose-deployment-transition/v1` | Transition interpretation and replay normalization are plausible. They must not authorize deployment or report current state. | Domain vectors and approval required |
| cooperative replay | `cooperative-rule-replay/v1` | Replay/equivalence questions need domain definitions for ordering and inputs. | Domain vectors and approval required |
| objective-review plan | `objective-review-decision-plan/v1` | Sequencing, branching, and binder preservation need a domain-owned syntax contract. | Domain vectors and approval required |
| Senad+ structure | `senad-transcript-structure/v1` | Structural encoding and equivalence are eligible; certificate acceptance remains with the production verifier. | Domain vectors and approval required |

## Authority firewall

All registrations must exclude exactly:

- mathematical proof;
- certificate acceptance;
- effect authorization;
- persisted operational state.

The audit fails if a contract requests a question outside the four semantic
question classes or omits any exclusion. An implementation with pending status
is executable advisory code only; its presence cannot activate normative
authority.

## First implementation

`Oracle.ProofGraph` currently implements deterministic natural ordering and exact-duplicate
collapse for a narrow representation-only node/edge model. That is useful advisory code,
but it is not yet the complete current domain contract: the approved finite-math-kernels
normalizer fixes kind-group node ordering, declared edge-type ordering, canonical JSON
object encoding, payload preservation, and fail-closed preconditions. The module therefore
remains non-normative until those semantics and vectors are implemented. It neither
evaluates claim truth nor accepts proof records.

The property suite exercises the three domain-owned vectors:

1. unordered independent records;
2. provenance is semantic;
3. exact duplicates collapse.

GitHub-hosted CI remains an advisory mirror gate. Canonical source/merge and CI
remain Forgejo and Woodpecker where applicable.

## Usul lane-D integration (2026-10-11)

The advisory usul dependency is pinned to merged PR #62 revision
`8cd49f89389823a20b9c622891bd00250e42072d`, replacing the temporary unmerged head.
All 28 usul paths were checked against that revision’s Git tree. The corrected
reconciliation report blob is pinned together with the previously omitted
ledger, contradiction validator, schema, six-case acceptance audit and
qualified-evidence archive. The inventory and review registry agree on all
65 pinned paths across 15 candidates and retain five normative boundaries.

The domain retains 162 entries, 414 active evidence items and 73 residues.
Two qualified passages remain in the archive rather than active grading.
All six discrepancies remain candidate interpretations, including the recorded
owner-knownness, theft-category and bequest-qarina scope limitations. This
repin does not grant the Haskell mirror scholarly or proof authority.
