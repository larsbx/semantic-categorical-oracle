# Semantic Categorical Oracle

A standalone Haskell home for executable semantic contracts, categorical laws,
model comparison, and counterexample discovery across the estate.

The repository supports two modes:

- **normative semantic contracts**, authoritative for explicitly registered
  questions such as interpretation, normal form, observational equivalence, and
  composition preservation;
- **advisory oracles**, which independently compare implementations without
  acquiring domain authority.

It never derives authority over mathematical proof, certificate acceptance,
effect authorization, or persisted operational state.

## Active research integrations

- **Ḥanbalī uṣūl kernel (advisory):** `Oracle.Usul.{Hukm,Argumentation,Taarud,Sadi}`
  mirror the Lean kernel in `larsbx/usul-al-fiqh-deontic-circuits` (registered as
  candidate `usul-argumentation-kernel`, pinned in `registry/source-review.toml`).
  Laws are bounded spikes; the grounded-extension vectors are generated from that
  repository's `formal/fixtures/grounded-v1.json`, which Lean also checks. Lean keeps
  proof authority, and nothing here decides a ḥukm.

- **PSC Tier 2 Growth Bridge:** `docs/GROWTH_BRIDGE_CONTRACTS.md` proposes
  versioned semantic contracts for cycle-basis equivalence, cocycle transport,
  and fixture equivalence. These contracts may become normative only for their
  explicitly registered semantic questions; they do not decide spectral truth.

Run the initial spike with:

```sh
cabal test all
cabal run semantic-categorical-oracle
```

Future artifacts must be labelled `authored_oracle`, `extracted_artifact`, or
`vendored_reference`. Manual translations are never described as extracted,
and semantic authority requires a separate versioned contract registration.
