#!/usr/bin/env python3
"""Run concept-filter against fixtures/concept-filter/*: exit code must match
`exit-code`, and stdout must equal `expected.json` as JSON (absent on exit 1,
where stdout must be empty)."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "fixtures" / "concept-filter"


def run(binary: str, case: Path) -> list[str]:
    result = subprocess.run(
        [binary], stdin=(case / "input.json").open("rb"), capture_output=True, check=False
    )
    want_code = int((case / "exit-code").read_text())
    errors = []
    if result.returncode != want_code:
        errors.append(f"exit {result.returncode}, expected {want_code}: {result.stderr.decode()}")
    expected = case / "expected.json"
    if expected.exists():
        if json.loads(result.stdout or b"null") != json.loads(expected.read_text()):
            errors.append("stdout differs from expected.json:\n" + result.stdout.decode())
    elif result.stdout:
        errors.append("expected no stdout")
    return errors


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("usage: golden_concept_filter.py <concept-filter binary>")
    cases = sorted(path for path in ROOT.iterdir() if path.is_dir())
    failed = False
    for case in cases:
        errors = run(sys.argv[1], case)
        print(f"{'FAIL' if errors else 'ok  '} {case.name}")
        for error in errors:
            print(f"     {error}")
        failed |= bool(errors)
    if failed or not cases:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
