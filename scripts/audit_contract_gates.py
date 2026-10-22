#!/usr/bin/env python3
"""Fail-closed audit of source pins and normative semantic registrations."""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import re
import sys
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HEX40 = re.compile(r"^[0-9a-f]{40}$")
EXCLUDED = {
    "mathematical_proof",
    "certificate_acceptance",
    "effect_authorization",
    "persisted_state",
}
SEMANTIC = {
    "contract_interpretation",
    "normal_form",
    "observational_equivalence",
    "composition_preservation",
}


def load(name: str):
    with (ROOT / "registry" / name).open("rb") as handle:
        return tomllib.load(handle)


def fail(message: str) -> None:
    raise SystemExit(message)


def audit_proof_graph_evidence(contract, review, root=ROOT, domain_checkout=None):
    """Check bytes, pair coverage, rule declarations, and immutable source pins."""
    identity = ["type", "source", "target", "provenance", "use_site"]
    order = ["declared_edge_type_rank", *identity[1:]]
    doc = (root / "docs/contract-gate-audit.md").read_text()
    for field, expected in (("edge_identity", identity), ("edge_order", order)):
        if contract.get(field) != expected:
            fail(f"proof graph: inconsistent {field}")
        declarations = re.findall(rf'{field} = (\[[^\n]+\])', doc)
        if len(declarations) != 1 or json.loads(declarations[0]) != expected:
            fail(f"proof graph: documented {field} differs from target rule")
    revision = contract.get("domain_revision", "")
    if not HEX40.fullmatch(revision) or revision != review["revision"]:
        fail("proof graph: domain revision differs from reviewed immutable revision")
    reviewed = {item["path"]: item["blob"] for item in review["files"]}
    if reviewed.get(contract.get("domain_schema_path")) != contract.get("domain_schema_blob"):
        fail("proof graph: schema pin differs from source review")
    pairs = contract.get("vector_pairs", [])
    required = {
        ("conformance/oracle/typed-proof-graph-minimal-v1.input.json",
         "conformance/oracle/typed-proof-graph-minimal-v1.expected.json"),
        ("conformance/ledger/relationship-graph.json",
         "conformance/oracle/typed-proof-graph-normalization-v1.json"),
    }
    if len(pairs) != 2 or {(p["input_path"], p["expected_path"]) for p in pairs} != required:
        fail("proof graph: both domain-owned input/output pairs are required")
    source_pins = {contract["domain_schema_path"]: contract["domain_schema_blob"]}
    seen_local = set()
    for pair in pairs:
        for role in ("input", "expected"):
            path, blob, local = (pair[role + suffix] for suffix in ("_path", "_blob", "_local"))
            if not HEX40.fullmatch(blob) or reviewed.get(path) != blob:
                fail(f"proof graph: {role} pin differs from source review")
            local_path = (root / local).resolve()
            if not local_path.is_relative_to((root / "fixtures/proof-graph").resolve()) or local in seen_local:
                fail("proof graph: invalid or reused local fixture path")
            seen_local.add(local)
            raw = local_path.read_bytes()
            actual = hashlib.sha1(b"blob " + str(len(raw)).encode() + b"\0" + raw).hexdigest()
            if actual != blob:
                fail(f"proof graph: {local} bytes differ from domain blob")
            graph = json.loads(raw)
            if graph.get("format") != "finite typed relationship graph 1" or not all(isinstance(graph.get(k), list) for k in ("nodes", "edges", "edge_types", "provenance_classes")):
                fail(f"proof graph: {role} artifact is not a graph vector")
            if role == "expected":
                canonical = (json.dumps(graph, sort_keys=True, separators=(",", ":"), ensure_ascii=False) + "\n").encode()
                if raw != canonical or "generated" in graph:
                    fail("proof graph: expected artifact is not canonical output bytes")
            source_pins[path] = blob
    if domain_checkout is not None:
        for path, blob in source_pins.items():
            actual = subprocess.check_output(
                ["git", "-C", str(domain_checkout), "rev-parse", f"{revision}:{path}"], text=True
            ).strip()
            if actual != blob:
                fail(f"proof graph: immutable domain path/blob mismatch: {path}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--domain-checkout", type=Path)
    args = parser.parse_args()
    inventory = load("extraction-candidates.toml")["candidate"]
    reviews = load("source-review.toml")["review"]
    contracts_doc = load("normative-contracts.toml")
    contracts = contracts_doc["contract"]

    by_candidate = {item["id"]: item for item in inventory}
    by_review = {item["candidate_id"]: item for item in reviews}
    if set(by_candidate) != set(by_review):
        fail("every inventory candidate must have exactly one pinned source review")

    for candidate_id, candidate in by_candidate.items():
        review = by_review[candidate_id]
        if review["repository"] != candidate["repository"]:
            fail(f"{candidate_id}: reviewed repository differs from inventory")
        if not HEX40.fullmatch(review["revision"]):
            fail(f"{candidate_id}: review revision is not a full commit SHA")
        reviewed_paths = [item["path"] for item in review["files"]]
        if reviewed_paths != candidate.get("source_paths", []):
            fail(f"{candidate_id}: pinned paths differ from the inventory")
        for item in review["files"]:
            if not HEX40.fullmatch(item["blob"]):
                fail(f"{candidate_id}:{item['path']}: blob is not a full SHA")

    normative = {
        item["id"]
        for item in inventory
        if item["authority_mode"] == "normative_semantic_candidate"
    }
    by_contract = {item["candidate_id"]: item for item in contracts}
    if set(by_contract) != normative:
        fail("every normative candidate must have exactly one contract audit")

    if set(contracts_doc["globally_excluded"]) != EXCLUDED:
        fail("global authority exclusions changed")

    contract_ids = [item["contract_id"] for item in contracts]
    if len(contract_ids) != len(set(contract_ids)):
        fail("contract identifiers must be unique")

    for candidate_id, contract in by_contract.items():
        if contract["domain_repository"] != by_candidate[candidate_id]["repository"]:
            fail(f"{candidate_id}: contract registered to the wrong domain")
        if not set(contract["questions"]) <= SEMANTIC:
            fail(f"{candidate_id}: contract requests non-semantic authority")
        if set(contract["excluded"]) != EXCLUDED:
            fail(f"{candidate_id}: contract must retain every global exclusion")
        if contract["status"] not in {"pending_domain_contract", "pending_domain_merge", "pending_implementation_update", "pending_domain_update", "pending_conformance_validation", "approved"}:
            fail(f"{candidate_id}: unknown fail-closed status")
        if contract["status"] == "approved":
            for field in (
                "canonical_vectors_path",
                "canonical_vectors_revision",
                "canonical_vectors_blob",
                "approval_evidence",
            ):
                if not contract.get(field):
                    fail(f"{candidate_id}: approved contract lacks {field}")

    proof_graph = by_contract["finite-proof-graph"]
    audit_proof_graph_evidence(proof_graph, by_review["finite-proof-graph"], domain_checkout=args.domain_checkout)
    if proof_graph["status"] != "pending_domain_update":
        fail("proof graph must remain non-normative until the finite-math-kernels 1.0.1 domain update merges and is re-pinned")
    if proof_graph["contract_id"] != "finite-proof-graph.normalization":
        fail("proof graph contract identifier changed")
    if proof_graph.get("domain_contract_version") != "1.0.0":
        fail("proof graph currently pinned domain contract version changed")
    if proof_graph.get("target_domain_contract_version") != "1.0.1":
        fail("proof graph target domain contract version changed")
    if "observational_equivalence" in proof_graph["questions"]:
        fail("proof graph v1 does not define observational equivalence")

    print(
        f"audited {len(inventory)} candidates, "
        f"{sum(len(item['files']) for item in reviews)} pinned paths, "
        f"{len(contracts)} normative contract boundaries"
    )


if __name__ == "__main__":
    try:
        main()
    except (KeyError, TypeError, ValueError, OSError, subprocess.CalledProcessError, tomllib.TOMLDecodeError) as error:
        print(f"audit registry invalid: {error}", file=sys.stderr)
        raise SystemExit(1) from error
