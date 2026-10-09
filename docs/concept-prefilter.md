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
   oracles receive derived links too (note `"derived"`, certainty = weakest premise).

Laws (`test/Concept/Laws.hs`, registered in `registry/laws.toml`): normal form
is idempotent and order/orientation invariant; saturation is a fixpoint; no
admitted concept lies in a conflict; retained assertions stay inside the
admitted set and are transitively closed; and the filter is idempotent on its own output.

## What was not migrated

The terminal UI, force-directed layout, Phoenix/JSON:API surface, ETS storage,
Graphiti/Neo4j service, `auto_agent`, HTTP retry plumbing, and manifestos.
These are presentation, transport, or persisted state, none of which this
repository may own (`docs/authority-boundary.md`).

## Authority

Registered as candidate `tui-story-concept-filter`, `advisory_oracle`, with no
authoritative questions. An admission is input hygiene for downstream oracles,
not a semantic contract.
