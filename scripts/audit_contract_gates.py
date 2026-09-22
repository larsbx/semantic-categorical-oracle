#!/usr/bin/env python3
"""Fail-closed audit of source pins and normative semantic registrations."""

from __future__ import annotations

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


def main() -> None:
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
        if contract["status"] not in {"pending_domain_contract", "pending_domain_merge", "approved"}:
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
    if proof_graph["status"] != "pending_domain_merge":
        fail("proof graph must remain non-normative until its domain PR merges")
    if proof_graph["contract_id"] != "finite-proof-graph-normalization":
        fail("proof graph contract identifier changed")
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
    except (KeyError, TypeError, tomllib.TOMLDecodeError) as error:
        print(f"audit registry invalid: {error}", file=sys.stderr)
        raise SystemExit(1) from error
