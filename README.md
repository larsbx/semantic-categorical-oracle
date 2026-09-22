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

Run the initial spike with:

```sh
cabal test all
cabal run semantic-categorical-oracle
```

Future artifacts must be labelled `authored_oracle`, `extracted_artifact`, or
`vendored_reference`. Manual translations are never described as extracted,
and semantic authority requires a separate versioned contract registration.
