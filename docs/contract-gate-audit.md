# Normative contract gate audit

Audit date: 2026-09-22

## Result

Every migration-candidate source path is pinned to a full review commit and an
observed content blob in `registry/source-review.toml`. The executable audit
requires exact path agreement with the inventory, so paths cannot be added,
removed, or silently retargeted without updating the review record.

Only the finite proof-graph normalization contract advances to implementation.
It remains `pending_domain_merge`, not normative, until the domain-owned vector
PR is merged and the registry is repinned to the canonical domain revision.

## Contract boundary findings

| Candidate | Identifier | Question-set result | Gate |
|---|---|---|---|
| finite proof graph | `finite-proof-graph-normalization/v1` | Interpretation, normal form, and composition preservation are representation semantics. Observational equivalence is deliberately omitted. | Pending merge of finite-math-kernels PR #22 |
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

`Oracle.ProofGraph` implements deterministic ordering and exact-duplicate
collapse for representation-only nodes and edges. Provenance and use-site are
part of the edge key, so open evidence cannot normalize into theorem-backed
evidence. The module neither evaluates claim truth nor accepts proof records.

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
