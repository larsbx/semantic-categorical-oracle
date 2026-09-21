# Semantic Categorical Oracle

A standalone Haskell oracle for executable semantic models, categorical laws,
model comparison, and counterexample discovery across the estate.

## Spike scope

The first spike provides:

- an explicit non-authoritative result vocabulary;
- bounded identity and composition checks;
- QuickCheck properties;
- a machine-readable law registry;
- authority and spike-lifecycle policies.

Run it with:

```sh
cabal test all
cabal run semantic-categorical-oracle
```

Expected executable result:

```text
LawHoldsForTestDomain
```

That verdict is evidence over the declared domain, not a proof. This repository
cannot accept certificates, establish theorems, authorize governed effects, or
replace a domain's canonical implementation.

Future artifacts must be labelled `authored_oracle`, `extracted_artifact`, or
`vendored_reference`; manual translations are never described as extracted.
