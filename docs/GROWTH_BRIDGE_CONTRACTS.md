# Growth Bridge semantic-contract scaffold

## Purpose

Specify semantic contracts for finite packet/cocycle objects used by the post-PSC Growth Bridge programme.

This repository may be authoritative only for explicitly registered semantic questions. It remains non-authoritative for mathematical proof, certificate acceptance, spectral truth, and persisted operational state.

## Candidate normative contracts

### GB-CYCLE-BASIS-001

**Question:** do two valid cycle presentations of the same weighted recurrent component denote the same generated loop-gain subgroup?

Inputs:

- finite directed component identity;
- edge identities and exact labels;
- two cycle presentations;
- two generated-module presentations.

Output:

- equivalent;
- not equivalent;
- malformed / outside contract.

The mathematical computation remains in the domain/kernel implementations. This contract defines the semantic notion being compared.

### GB-COCYCLE-TRANSPORT-001

**Question:** does a declared packet normalization or quotient transport preserve the additive cocycle according to its registered map?

The contract checks declared source/target identities, edge mapping, and composition preservation. It does not infer that the quotient is mathematically appropriate.

### GB-FIXTURE-EQUIVALENCE-001

**Question:** do two serialized loop-gain fixtures encode the same finite weighted graph and arithmetic gain assignment up to the explicitly allowed renaming relation?

This allows PSC and Julia fixtures to be compared without making byte identity the only notion of sameness.

## Non-contracts

Do not register any of these as Haskell authority:

- whether PSC is true;
- whether a measurable eigenvalue exists;
- whether a character kernel excludes a loop-gain subgroup;
- whether pure point spectrum follows;
- whether a finite empirical result promotes to a class theorem.

Those remain mathematical/domain claims.

## Integration

PSC owns contract identifiers when they become dependencies of a claim. This repository owns the executable semantics only after the contract is explicitly reviewed and registered.

The first implementation should target `GB-CYCLE-BASIS-001`, because it is finite, exact, and independent of spectral assumptions.
