#!/usr/bin/env python3
"""Mutation tests for evidence acceptance, independent of the pending-status lock."""
import unittest
from pathlib import Path
from unittest.mock import patch

import audit_contract_gates as audit


class EvidenceTests(unittest.TestCase):
    def setUp(self):
        self.contract = next(c for c in audit.load("normative-contracts.toml")["contract"] if c["candidate_id"] == "finite-proof-graph")
        self.review = next(c for c in audit.load("source-review.toml")["review"] if c["candidate_id"] == "finite-proof-graph")

    def check_evidence(self):
        audit.audit_proof_graph_evidence(self.contract, self.review)

    def test_valid_pending_evidence(self):
        self.check_evidence()

    def test_evidence_checks_are_not_bypassed_by_approval(self):
        self.contract["status"] = "approved"
        self.contract["vector_pairs"][0]["expected_blob"] = "0" * 40
        with self.assertRaisesRegex(SystemExit, "pin differs"):
            self.check_evidence()

    def test_schema_cannot_replace_expected_output(self):
        self.contract["vector_pairs"][0]["expected_path"] = self.contract["domain_schema_path"]
        self.contract["vector_pairs"][0]["expected_blob"] = self.contract["domain_schema_blob"]
        with self.assertRaisesRegex(SystemExit, "both domain-owned"):
            self.check_evidence()

    def test_missing_pair(self):
        self.contract["vector_pairs"].pop()
        with self.assertRaisesRegex(SystemExit, "both domain-owned"):
            self.check_evidence()

    def test_wrong_input_pin(self):
        self.contract["vector_pairs"][1]["input_blob"] = "0" * 40
        with self.assertRaisesRegex(SystemExit, "pin differs"):
            self.check_evidence()

    def test_wrong_local_output(self):
        self.contract["vector_pairs"][0]["expected_local"] = "fixtures/proof-graph/relationship-graph-v1.expected.json"
        with self.assertRaisesRegex(SystemExit, "bytes differ"):
            self.check_evidence()

    def test_wrong_revision(self):
        self.contract["domain_revision"] = "0" * 40
        with self.assertRaisesRegex(SystemExit, "revision differs"):
            self.check_evidence()

    def test_identity_requires_provenance(self):
        self.contract["edge_identity"].remove("provenance")
        with self.assertRaisesRegex(SystemExit, "inconsistent edge_identity"):
            self.check_evidence()

    def test_order_requires_provenance_before_use_site(self):
        self.contract["edge_order"][-2:] = ["use_site", "provenance"]
        with self.assertRaisesRegex(SystemExit, "inconsistent edge_order"):
            self.check_evidence()

    def test_documentation_rule_drift(self):
        original = Path.read_text
        def altered(path, *args, **kwargs):
            return original(path, *args, **kwargs).replace('"target", "provenance", "use_site"', '"target", "use_site"')
        with patch.object(Path, "read_text", altered):
            with self.assertRaisesRegex(SystemExit, "documented edge_identity"):
                self.check_evidence()

    def test_source_path_not_at_revision(self):
        with patch.object(audit.subprocess, "check_output", return_value="0" * 40):
            with self.assertRaisesRegex(SystemExit, "immutable domain path/blob mismatch"):
                audit.audit_proof_graph_evidence(self.contract, self.review, domain_checkout=Path("unused"))


if __name__ == "__main__":
    unittest.main()
