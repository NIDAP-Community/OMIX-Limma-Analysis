#!/usr/bin/env python3
"""Self-test the cross-environment comparator with deterministic fixtures."""

from __future__ import annotations

import json
import struct
import subprocess
import tempfile
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
COMPARATOR = ROOT / "tests" / "compare-cross-environment.py"


def png(path: Path, width: int = 640, height: int = 480) -> None:
    def chunk(kind: bytes, data: bytes) -> bytes:
        body = kind + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body))

    row = b"\x00" + b"\xff\xff\xff" * width
    path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(row * height))
        + chunk(b"IEND", b"")
    )


def write_fixture(root: Path, numeric_delta: float = 0.0) -> None:
    root.mkdir(parents=True, exist_ok=True)
    (root / "Limma_Analysis.csv").write_text(
        "GeneName,B-A_logFC,B-A_tstat,B-A_pval,B-A_adjpval\n"
        f"Gene1,{1.0 + numeric_delta},5,0.001,0.003\n"
        "Gene2,-0.5,-2,0.04,0.06\n",
        encoding="utf-8",
    )
    (root / "Sample_Metadata.csv").write_text(
        "Sample,Group\nS1,A\nS2,A\nS3,B\nS4,B\n", encoding="utf-8"
    )
    (root / "Variance_Diagnostic.csv").write_text(
        "bin,mean,variance\n1,2.0,0.5\n2,4.0,0.75\n", encoding="utf-8"
    )
    (root / "run_summary.txt").write_text(
        "input data type: sctransform_mean_expression\n"
        "input data type source: explicit\n"
        "requested variance model: auto\n"
        "variance model: ebayes_trend\n"
        "model type: linear\n"
        "requested contrasts: B-A\n"
        "resolved contrasts: B-A\n"
        "contrast source: explicit\n"
        "group replicate counts: A=2,B=2\n",
        encoding="utf-8",
    )
    png(root / "variance_diagnostic.png")


with tempfile.TemporaryDirectory(prefix="omix-limma-comparator-") as temp:
    temp_root = Path(temp)
    local = temp_root / "local"
    platform = temp_root / "platform"
    write_fixture(local)
    write_fixture(platform, numeric_delta=5e-13)
    passing_report = temp_root / "passing.json"
    passed = subprocess.run(
        [
            "python3",
            str(COMPARATOR),
            "--local-dir",
            str(local),
            "--code-ocean-dir",
            str(platform),
            "--tolerance",
            "1e-12",
            "--report",
            str(passing_report),
        ],
        check=False,
    )
    assert passed.returncode == 0
    assert json.loads(passing_report.read_text())["passed"] is True

    write_fixture(platform, numeric_delta=5e-6)
    failing_report = temp_root / "failing.json"
    failed = subprocess.run(
        [
            "python3",
            str(COMPARATOR),
            "--local-dir",
            str(local),
            "--code-ocean-dir",
            str(platform),
            "--tolerance",
            "1e-12",
            "--report",
            str(failing_report),
        ],
        check=False,
    )
    assert failed.returncode == 1
    failure_data = json.loads(failing_report.read_text())
    assert failure_data["passed"] is False
    assert failure_data["files"]["Limma_Analysis.csv"]["mismatched_cells"] == 1

print("OMIX Limma cross-environment comparator self-test passed")
