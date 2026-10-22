# Proof-graph conformance fixtures

Artifact class: **vendored_reference**.

These four files are byte-for-byte copies of domain-owned canonical inputs and
expected outputs from `larsbx/finite-math-kernels`, pinned by
`registry/source-review.toml` at revision
`d4445ff59e7b5036081f56f066525ad7b60003fe`.

| Local file | Domain source |
|---|---|
| `typed-proof-graph-minimal-v1.input.json` | `conformance/oracle/typed-proof-graph-minimal-v1.input.json` |
| `typed-proof-graph-minimal-v1.expected.json` | `conformance/oracle/typed-proof-graph-minimal-v1.expected.json` |
| `relationship-graph-v1.input.json` | `conformance/ledger/relationship-graph.json` |
| `relationship-graph-v1.expected.json` | `conformance/oracle/typed-proof-graph-normalization-v1.json` |

They are test inputs, not extracted Haskell artifacts and not independently
authored semantics. A change to the domain contract requires a deliberate
re-pin and byte-for-byte fixture refresh before normative authority can remain
active.
