# Cross-estate Haskell candidate inventory

This inventory was derived from the open `polyglot/migration-v1` manifests and current default-branch source trees. Twelve repositories declare Haskell as a primary or supporting language.

Source-model extraction means isolating pure semantics and independently
reimplementing it as Haskell. Mechanical extraction means tool-generated
Haskell from a named formal source. No current candidate has been verified as
mechanically extractable.

| Priority | Repository | Proposed model | Initial authority posture |
|---|---|---|---|
| P0 | `sprucegoose` | Deployment transition and replay laws | Candidate normative semantic contract |
| P0 | `pisot-substitution-conjecture-research` | Balanced-pair/SCC/productivity semantics | Advisory mathematical oracle |
| P0 | `finite-math-kernels` proof graph | Claim-graph normalization | Candidate normative semantic contract |
| P0 | `finite-math-kernels` automaton | Bounded substitution automata | Advisory mathematical oracle |
| P1 | `coop_substrate` | Rule evaluation and event-fold equivalence | Candidate normative semantic contract |
| P1 | `objective-review-metasytem` | Decision-plan/path preservation | Candidate normative semantic contract |
| P1 | `finite-mandelbrot-research` | Structural comparison | Advisory mathematical oracle |
| P2 | `halaqa` | Senad+ transcript/disclosure structure | Candidate normative semantic contract |
| P2 | `agent-icm` | Narrow command-policy parser | Advisory until independently registered |
| Hold | `closure-fiber-of-multiplication-research` | Closure/Hurwitz model | Blocked: executable source is a placeholder |
| Hold | `keel` | Deontic and VCPlan/VCGraph semantics | Greenfield future normative contract |
| Hold | `height-pairings-bsd-interfaces` | Height/regulator interfaces | Await executable Julia/Lean model |
| Exclude | `icm-hub` | None | No owned replay core isolated |

## Promotion gates

Normative semantic authority requires:

1. a stable contract identifier and semantic version;
2. pinned sources, provenance, and license status;
3. explicit authoritative and excluded questions;
4. stated preconditions and canonical normal forms;
5. domain-owned conformance vectors;
6. fail-closed disagreement behavior;
7. approval at the domain's canonical authority boundary.

Haskell authority governs meaning within that registration. It does not establish
mathematical truth, accept certificates, authorize effects, or own persisted
operational state.
