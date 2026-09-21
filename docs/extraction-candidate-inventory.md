# Cross-estate Haskell candidate inventory

This inventory was derived from the open `polyglot/migration-v1` manifests and current default-branch source trees. Twelve repositories declare Haskell as a primary or supporting language.

Two meanings must remain separate:

- **Source-model extraction**: isolate pure semantics from operational code and independently reimplement them as an authored Haskell oracle.
- **Mechanical extraction**: tool-generated Haskell from a named formal source.

No current candidate has been verified as mechanically extractable. Lean, Mojo, Python, Elixir, and prose sources do not become “extracted artifacts” through manual translation.

| Priority | Repository | Evidence-backed source | Proposed oracle | Status |
|---|---|---|---|---|
| P0 | `sprucegoose` | deployment lifecycle, projection, record, and tests | Deployment transition and replay laws | Authored oracle |
| P0 | `pisot-substitution-conjecture-research` | BPA, overlap graph, Mojo certificate modules | Balanced-pair/SCC/productivity semantics | Authored oracle |
| P0 | `finite-math-kernels` | typed proof graph, substitution automaton, fixtures | Graph normalization and bounded automata | Authored oracle |
| P1 | `coop_substrate` | rule modules, event store, replay tests | Rule evaluation and event-fold equivalence | Authored oracle |
| P1 | `objective-review-metasytem` | advisor and decision-data builder | Decision-plan/path preservation | Authored oracle |
| P1 | `finite-mandelbrot-research` | projective multiset, C1 status, regime fixtures | Structural comparison only | Authored oracle; never acceptance |
| P2 | `halaqa` | Senad+ and effect-ledger specifications | Transcript/disclosure/effect semantics | Specification-derived oracle |
| P2 | `agent-icm` | Syncthing policy guard and tests | Narrow command-policy parser | Authored oracle; not ICM state semantics |
| Hold | `closure-fiber-of-multiplication-research` | executable is currently a placeholder | Closure/Hurwitz model | Blocked |
| Hold | `keel` | README only | Deontic and VCPlan/VCGraph semantics | Greenfield |
| Hold | `height-pairings-bsd-interfaces` | computation/example README files only | Height/regulator interfaces | Await executable Julia/Lean model |
| Exclude | `icm-hub` | aggregated workspaces and vendored material | None | No owned replay core isolated |

## Promotion gates

A candidate may enter `domains/` only after it has a pinned source revision and paths, stated preconditions, canonical vectors owned by the domain repository, a named authoritative peer, fail-closed disagreement behavior, artifact classification, and license/provenance clearance.

The Haskell oracle cannot replace proof, certificate acceptance, authorization, or deployment authority.
