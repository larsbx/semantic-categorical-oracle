# Authority boundary

This repository may be authoritative for explicitly registered, versioned
executable semantic contracts. Authority is assigned per contract and per
question; it is never inferred merely because a Haskell implementation exists.

A normative semantic contract may decide:

- contract interpretation;
- canonical normal form;
- observational equivalence;
- preservation of sequencing, branching, binders, provenance, or composition.

It may not decide:

- whether a mathematical proposition is proved;
- whether a mathematical or cryptographic certificate is accepted;
- whether a deployment, policy decision, or governed effect is authorized;
- what persisted operational state currently exists.

Lean retains proof authority. Designated Mojo or Rust checkers retain certificate
acceptance. Keel, SpruceGoose, Ash resources, and their ledgers retain
authorization and operational-state authority.

## Authority modes

- `normative_semantic`: canonical executable meaning for a registered contract
  version and its declared semantic questions.
- `advisory_oracle`: independent comparison, counterexample generation, or
  bounded testing without normative authority.

Only a conclusive result from a `normative_semantic` contract is authoritative
within that contract's declared scope. `inconclusive` and `oracle_error` are
never authoritative.

A bounded property success is not automatically a universal theorem. Its
authority can establish behavior over the registered domain or contract
interpretation, but cannot promote itself to mathematical proof.

## Artifact classes

Every model must be labelled as one of:

1. `authored_oracle` — independently implemented Haskell semantics;
2. `extracted_artifact` — mechanically generated from a named source and toolchain;
3. `vendored_reference` — immutable upstream source plus explicit local patches.

Any artifact class may be advisory. Normative authority additionally requires an
approved contract registration, version, questions, provenance, and conformance
suite. Manual translations must not be labelled as extracted.
