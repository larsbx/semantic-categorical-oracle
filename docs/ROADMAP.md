# Roadmap

Status as of 2026-10-21 (`main` at the #38 merge). Every item stays inside
`docs/authority-boundary.md`: nothing here moves proof, certificate,
authorization, or persisted-state authority into this repository.

## Shipped

| Area | State | Where |
|---|---|---|
| Authority model and registry audit | Fail-closed audit runs in CI | `Oracle.Result`, `scripts/audit_contract_gates.py` |
| Bounded categorical laws | Spike | `Oracle.Category` |
| Proof-graph normal form | Pending domain merge | `Oracle.ProofGraph` |
| PSC growth-bridge contracts | Proposed | `Oracle.GrowthBridge`, `docs/GROWTH_BRIDGE_CONTRACTS.md` |
| Ḥanbalī uṣūl kernel mirror | Advisory, pinned to Lean | `Oracle.Usul.*` |
| Concept pre-filter (from `tui-story`) | Advisory | `Oracle.Concept.*`, `docs/concept-prefilter.md` |
| `concept-filter` CLI and container | Published from `main` | `cli/`, `Dockerfile`, `.github/workflows/container.yml` |

## Next: concept pre-filter

1. **Image access.** New GHCR packages default to private. Decide on
   visibility for `ghcr.io/larsbx/semantic-categorical-oracle/concept-filter`,
   and cut a first `v*` tag so consumers can pin a version, not `main`.
2. **Consumer wiring.** Put the filter in front of the first real oracle call
   (LLM extraction → `concept-filter` → oracle). Gate on exit code `2`.
3. **Scale.** Saturation and conflict search are quadratic over lists.
   That is fine for one LLM batch. Move to `Data.Map`/`Data.Set` before
   inputs reach thousands of concepts, with the existing laws as the
   regression oracle.
4. **Agent access (optional).** A thin MCP tool over the binary, so an agent
   filters concepts before it calls an oracle.
5. **Archive `tui-story`.** Its `MIGRATION.md` maps every migrated piece.
   Archiving is the owner's call.

## Next: normative contracts

Each contract becomes normative only through the promotion gates in
`docs/extraction-candidate-inventory.md`. Status is from
`registry/normative-contracts.toml`.

| Contract | Status | Unblocks when |
|---|---|---|
| `finite-proof-graph-normalization` | `pending_domain_merge` | The finite-math-kernels PR merges and the vector pin advances |
| `sprucegoose-deployment-transition` | `pending_domain_contract` | The domain supplies canonical vectors and approval |
| `cooperative-rule-replay` | `pending_domain_contract` | The domain defines replay inputs, equivalence, and ordering |
| `objective-review-decision-plan` | `pending_domain_contract` | The domain names its semantic branches, binders, and sequencing |
| `senad-transcript-structure` | `pending_domain_contract` | The production verifier boundary is settled |

## Advisory oracles still to build

From `registry/extraction-candidates.toml`: `psc-balanced-pair-semantics` and
`finite-substitution-automaton` (P0), `finite-mandelbrot-structural-model`
(P1), and `agent-icm-command-policy` (P2).

## On hold or excluded

`closure-fiber-semantics` and `height-pairing-semantics` are blocked on
executable sources. `keel-deontic-semantics` is greenfield and waits for a
domain contract. `icm-hub-event-replay` is excluded: no owned replay core.

## Infrastructure

- **CI queueing.** On 2026-10-20 the #38 runs sat queued for hours and the PR
  merged before its CI ran. The post-merge `main` runs passed. Consider
  requiring both workflows as status checks on `main`.
- **Toolchain parity.** CI and the container both use GHC 9.12.4. Keep
  them pinned together.
