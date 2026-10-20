# Concept pre-filter

`Oracle.Concept.*` is the useful core of `larsbx/tui-story`, migrated out of a
TUI/Phoenix/Graphiti application that had drifted from its purpose. It runs
*before* any oracle: it decides which concepts are admissible inputs, never
whether a relation between them is true.

Pipeline, for raw strings `R` and LLM-style assertions `A`:

```
validate : R → Concept ⊎ ConceptError            -- ValidationLayer.tla
fromRaw  : RawAssertion → Assertion ⊎ AssertionError  -- fail-closed llm/client.ex
normalize: [Assertion] → [Assertion]              -- edge.ex duplicate rule
filter   : Policy → R → A → Admission
```

`filterConcepts` performs, in order:

1. **validate** concepts to a case-folded, whitespace-collapsed normal form;
2. **threshold** assertions by certainty (default `0.5`, the TLA+ `MinCertainty`)
   and relation, discarding those naming a concept outside the supplied set;
3. **collapse** synonymy: `≡` is an equivalence, each class is represented by
   its least member, and every other member is reported as an alias;
4. **saturate** transitive relations (`→`, `⊆`) to a fixpoint, certainty `min`;
5. **detect** conflicts: incompatible relations on one unordered pair, where
   `incompatible = {(⊥,→), (⊥,≡), (≡,≠)}` and collapsing a class counts as `≡`;
6. **quarantine** every class touching a conflict. The filter never picks a side;
7. **retain** the saturated assertions among admitted classes, so downstream
   oracles receive derived links too (provenance `Derived`, certainty = weakest premise).

Laws (`test/Concept/Laws.hs`, registered in `registry/laws.toml`): normal form
is idempotent and order/orientation invariant; saturation is a fixpoint; no
admitted concept lies in a conflict; retained assertions stay inside the
admitted set and are transitively closed; and the filter is idempotent on its own output.

## Running it: `concept-filter`

A stateless executable: JSON on stdin, the admission as JSON on stdout.

```sh
cabal run -v0 concept-filter < fixtures/concept-filter/synonyms-and-derived/input.json
```

Input is either a request object or a bare assertion array (the tui-story LLM
shape, whose concept set is then every endpoint of a well-typed assertion):

```json
{
  "concepts": ["Car", "automobile", "wheel"],
  "assertions": [{"from": "car", "to": "automobile", "type": "synonymous", "certainty": 0.9, "description": "optional"}],
  "policy": {"min_certainty": 0.5, "relations": ["synonymous", "part_whole"]}
}
```

Output keys: `admitted`, `aliases` (`alias` → `canonical`), `retained` (each with
`type`, `symbol`, `certainty`, `description`, `derived`), `conflicts`,
`quarantined`, `invalid_concepts`, `invalid_assertions` (by input `index`).

| Exit | Meaning |
|---|---|
| `0` | admitted, nothing quarantined |
| `2` | admitted, but some concepts were quarantined: treat as fail-closed |
| `1` | malformed request or policy; nothing on stdout, reason on stderr |

A malformed *assertion* is reported in `invalid_assertions` and skipped; a
malformed *request or policy* rejects everything. Golden cases live in
`fixtures/concept-filter/` and run in CI via `scripts/golden_concept_filter.py`.

### Container

Published to `ghcr.io/larsbx/semantic-categorical-oracle/concept-filter` from
`main` (tag `main`), release tags `v*` (tag = version), and every push (`sha-…`).
Pull requests build the image and run the golden fixtures against it without
publishing.

```sh
docker run --rm -i --network none --read-only \
  ghcr.io/larsbx/semantic-categorical-oracle/concept-filter:main < request.json
```

The image is stateless and runs as an unprivileged user, so `--network none`
and `--read-only` are safe to enforce.

Pipeline use:

```sh
llm-extract | docker run --rm -i --network none --read-only "$IMAGE" > admission.json
case $? in
  0) oracle < admission.json ;;
  2) echo "quarantined concepts; see admission.json" >&2; exit 2 ;;
  *) exit 1 ;;
esac
```

## What was not migrated

The terminal UI, force-directed layout, Phoenix/JSON:API surface, ETS storage,
Graphiti/Neo4j service, `auto_agent`, HTTP retry plumbing, and manifestos.
These are presentation, transport, or persisted state, none of which this
repository may own (`docs/authority-boundary.md`).

## Authority

Registered as candidate `tui-story-concept-filter`, `advisory_oracle`, with no
authoritative questions. An admission is input hygiene for downstream oracles,
not a semantic contract.
