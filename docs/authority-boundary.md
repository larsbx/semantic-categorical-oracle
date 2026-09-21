# Authority boundary

This repository is an independent semantic and categorical oracle.

It may:

- evaluate laws over declared finite or generated domains;
- compare independently implemented models;
- emit minimized counterexamples;
- preserve vendored or mechanically extracted reference artifacts;
- produce canonical conformance vectors.

It may not:

- declare a theorem proved;
- accept a mathematical or cryptographic certificate;
- authorize a deployment, policy decision, or governed effect;
- silently become the canonical implementation of a domain rule.

A successful property run means only `law_holds_for_test_domain`. It is evidence,
not universal proof. A counterexample is meaningful only when its generated value
satisfies the registered law preconditions.

## Artifact classes

Every future domain model must be labelled as one of:

1. `authored_oracle` — independently implemented Haskell semantics;
2. `extracted_artifact` — mechanically generated from a named source and toolchain;
3. `vendored_reference` — immutable upstream source plus explicit local patches.

Manual translations must not be labelled as extracted.
