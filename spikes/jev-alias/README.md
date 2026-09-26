# Spike: Jev as an advisory alias oracle

[Jev](https://docs.typesafe.ai/) (TypeSafe's System One model) answers typed
questions (Noul / Choice / Score) with calibrated probabilities and confidence.
This spike puts a typed Haskell boundary around it and uses it for one narrow
semantic question over the proof-record graph.

## Declaration (per `spikes/README.md`)

| Item | Value |
|---|---|
| Semantic question | For distinct proof-graph node ids `a ≠ b`: do `a` and `b` name the same mathematical object? |
| Compared models | (1) domain declaration: equivalence closure of `synonymous` edges; (2) Jev `jev-latest` (`jev-1.13.x` at time of writing) via `POST /v1/systemone` |
| Domain | Unordered pairs of distinct node ids, `n(n-1)/2` Choice questions per request; vector ids from the root suite |
| Preconditions | Response answer ids = request question ids; every Choice answer has exactly the option set `{same_object, distinct_object}`, a distribution (Σ = 1 ± 10⁻³, pᵢ ≥ 0) and confidence ∈ [0, 1] |
| Reproducibility | `request` mode prints the exact request body; `replay` decodes a stored response; QuickCheck seeds are printed on failure |
| Result vocabulary | `ModelsAgree` · `ModelsDisagree [Disagreement]` · `Inconclusive` (some answer below the confidence floor, 0.8) · `OracleError` (contract violation) |
| Authority | `advisory_oracle` only (`spikeAuthority = AdvisoryOracle`). The result is never authoritative for any question and never feeds `Oracle.ProofGraph` normalization |
| Promotion / deletion | Promote to a registered advisory candidate if a live run over the domain-owned relationship graph surfaces at least one confirmed missing or spurious `synonymous` edge. Delete if live runs only ever agree (no information) or disagreements are all Jev errors |

## Shape

```
state ⊕ {pairᵢ ↦ Choice @Relation}  ──POST──▶  Jev
                                                  │
Response ─ decodeChoice @Relation (total, fail-closed) ─▶ Decision Relation
         ─ gate floor ─▶ Act r | Escalate r c
         ─ compare with declaredRelation ─▶ OracleResult [Disagreement]
```

- `Jev.Wire`: the documented HTTP contract (authored from `docs.typesafe.ai/api.md`).
- `Jev.Typed`: `class (Bounded a, Enum a) => Option a`; a sum type *is* the
  option set, so `choice @a` is total and `decodeChoice @a` returns either an
  `a` or a precise `DecodeError`.
- `Jev.Gate`: confidence-gated routing; monotone in the floor.
- `Jev.Alias`: the use case: candidate pairs, declared equivalence, `probe`, `judge`.

Arithmetic, counting, and the equivalence closure stay in Haskell; Jev only
supplies the per-pair semantic judgment (see Jev 1.13's known weak spots).

## Run

```sh
cabal test jev-alias-laws
cabal run jev-alias-spike -- request                                   # dry run: request body
cabal run jev-alias-spike -- replay spikes/jev-alias/fixtures/synthetic-response.json
TYPESAFE_API_KEY=… cabal run jev-alias-spike -- live
```

`fixtures/synthetic-response.json` is **hand-authored**, not a recorded Jev
response (its `model` is `synthetic-not-jev`). It exercises the escalation
path, `Inconclusive "1 of 15 pairs below confidence floor"`. Replace it with a
recorded live response before drawing any conclusion about Jev.
