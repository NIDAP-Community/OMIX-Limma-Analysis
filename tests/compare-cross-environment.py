#!/usr/bin/env python3
"""Compare local and Code Ocean OMIX Limma result directories.

This script is deliberately independent of R packages. It validates scientific
tables and stable provenance fields, records plot structure, and writes a JSON
report suitable for review. It does not treat a successful platform job as
equivalence evidence by itself.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
import struct
import sys
from pathlib import Path


REQUIRED_FILES = (
    "Limma_Analysis.csv",
    "Sample_Metadata.csv",
    "run_summary.txt",
    "Variance_Diagnostic.csv",
    "variance_diagnostic.png",
)
DEFAULT_SUMMARY_KEYS = (
    "canonical module",
    "canonical source",
    "input data type",
    "input data type source",
    "requested variance model",
    "variance model",
    "model type",
    "requested contrasts",
    "resolved contrasts",
    "contrast source",
    "group replicate counts",
)
MISSING_TOKENS = {"", "na", "nan", "null", "none"}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def read_csv(path: Path) -> tuple[list[str], list[list[str]]]:
    with path.open(newline="", encoding="utf-8-sig") as handle:
        reader = csv.reader(handle)
        try:
            header = next(reader)
        except StopIteration as error:
            raise ValueError(f"{path} is empty") from error
        return header, list(reader)


def numeric_value(value: str) -> float | None:
    if value.strip().lower() in MISSING_TOKENS:
        return math.nan
    try:
        return float(value)
    except ValueError:
        return None


def values_equal(left: str, right: str, tolerance: float) -> tuple[bool, float | None]:
    left_number = numeric_value(left)
    right_number = numeric_value(right)
    if left_number is None or right_number is None:
        return left == right, None
    if math.isnan(left_number) or math.isnan(right_number):
        return math.isnan(left_number) and math.isnan(right_number), None
    difference = abs(left_number - right_number)
    return difference <= tolerance, difference


def compare_table(
    local_path: Path,
    platform_path: Path,
    tolerance: float,
) -> tuple[dict[str, object], list[str]]:
    local_header, local_rows = read_csv(local_path)
    platform_header, platform_rows = read_csv(platform_path)
    failures: list[str] = []
    report: dict[str, object] = {
        "local_sha256": sha256(local_path),
        "platform_sha256": sha256(platform_path),
        "local_dimensions": [len(local_rows), len(local_header)],
        "platform_dimensions": [len(platform_rows), len(platform_header)],
        "headers_identical": local_header == platform_header,
        "maximum_absolute_numeric_difference": 0.0,
        "numeric_values_compared": 0,
        "mismatched_cells": 0,
    }
    if local_header != platform_header:
        failures.append(f"{local_path.name}: column names or order differ")
        return report, failures
    if len(local_rows) != len(platform_rows):
        failures.append(f"{local_path.name}: row counts differ")
        return report, failures

    max_difference = 0.0
    numeric_count = 0
    mismatches = 0
    examples: list[dict[str, object]] = []
    for row_index, (local_row, platform_row) in enumerate(
        zip(local_rows, platform_rows), start=2
    ):
        if len(local_row) != len(local_header) or len(platform_row) != len(local_header):
            failures.append(f"{local_path.name}: malformed row {row_index}")
            continue
        for column_index, (left, right) in enumerate(zip(local_row, platform_row)):
            # The leading column is the ordered row identity for every stable
            # OMIX Limma CSV. Never coerce numeric-looking identifiers such as
            # "001" and "1" into an apparent match.
            if column_index == 0:
                equal, difference = left == right, None
            else:
                equal, difference = values_equal(left, right, tolerance)
            if difference is not None:
                numeric_count += 1
                max_difference = max(max_difference, difference)
            if not equal:
                mismatches += 1
                if len(examples) < 10:
                    examples.append(
                        {
                            "row": row_index,
                            "column": local_header[column_index],
                            "local": left,
                            "platform": right,
                            "absolute_difference": difference,
                        }
                    )

    report.update(
        {
            "maximum_absolute_numeric_difference": max_difference,
            "numeric_values_compared": numeric_count,
            "mismatched_cells": mismatches,
            "mismatch_examples": examples,
        }
    )
    if mismatches:
        failures.append(
            f"{local_path.name}: {mismatches} cells differ beyond tolerance {tolerance:g}"
        )
    return report, failures


def read_summary(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        key, separator, value = line.partition(":")
        if separator:
            values[key.strip().lower()] = value.strip()
    return values


def compare_summary(
    local_path: Path,
    platform_path: Path,
    keys: tuple[str, ...],
) -> tuple[dict[str, object], list[str]]:
    local = read_summary(local_path)
    platform = read_summary(platform_path)
    failures: list[str] = []
    comparisons: dict[str, object] = {}
    for key in keys:
        left = local.get(key)
        right = platform.get(key)
        matches = left is not None and left == right
        comparisons[key] = {"local": left, "platform": right, "matches": matches}
        if not matches:
            failures.append(f"run_summary.txt: stable field {key!r} differs or is missing")
    return {
        "local_sha256": sha256(local_path),
        "platform_sha256": sha256(platform_path),
        "stable_fields": comparisons,
    }, failures


def png_dimensions(path: Path) -> tuple[int, int]:
    data = path.read_bytes()
    if len(data) < 24 or data[:8] != b"\x89PNG\r\n\x1a\n" or data[12:16] != b"IHDR":
        raise ValueError(f"{path} is not a valid PNG with an IHDR chunk")
    return struct.unpack(">II", data[16:24])


def compare_png(local_path: Path, platform_path: Path) -> tuple[dict[str, object], list[str]]:
    local_dimensions = png_dimensions(local_path)
    platform_dimensions = png_dimensions(platform_path)
    failures: list[str] = []
    if local_dimensions != platform_dimensions:
        failures.append(
            f"{local_path.name}: PNG dimensions differ "
            f"({local_dimensions} versus {platform_dimensions})"
        )
    return {
        "local_sha256": sha256(local_path),
        "platform_sha256": sha256(platform_path),
        "local_dimensions": list(local_dimensions),
        "platform_dimensions": list(platform_dimensions),
        "byte_identical": sha256(local_path) == sha256(platform_path),
        "structurally_equivalent": local_dimensions == platform_dimensions,
    }, failures


def significance_and_rank_checks(
    local_path: Path,
    platform_path: Path,
) -> tuple[dict[str, object], list[str]]:
    local_header, local_rows = read_csv(local_path)
    platform_header, platform_rows = read_csv(platform_path)
    failures: list[str] = []
    checks: dict[str, object] = {}
    if local_header != platform_header or len(local_rows) != len(platform_rows):
        return checks, ["Limma_Analysis.csv: cannot compare calls/ranks after shape mismatch"]

    identifier_index = 0
    local_ids = [row[identifier_index] for row in local_rows]
    platform_ids = [row[identifier_index] for row in platform_rows]
    if local_ids != platform_ids:
        failures.append("Limma_Analysis.csv: feature identifiers or row order differ")

    for column_index, column in enumerate(local_header):
        lower = column.lower()
        if lower.endswith(("_pval", "_adjpval")):
            local_values = [numeric_value(row[column_index]) for row in local_rows]
            platform_values = [numeric_value(row[column_index]) for row in platform_rows]
            local_calls = [value is not None and not math.isnan(value) and value < 0.05 for value in local_values]
            platform_calls = [value is not None and not math.isnan(value) and value < 0.05 for value in platform_values]
            call_match = local_calls == platform_calls
            local_rank = sorted(
                range(len(local_rows)),
                key=lambda index: (
                    math.inf if local_values[index] is None or math.isnan(local_values[index]) else local_values[index],
                    local_ids[index],
                ),
            )
            platform_rank = sorted(
                range(len(platform_rows)),
                key=lambda index: (
                    math.inf if platform_values[index] is None or math.isnan(platform_values[index]) else platform_values[index],
                    platform_ids[index],
                ),
            )
            rank_match = local_rank == platform_rank
            checks[column] = {
                "threshold": 0.05,
                "significance_classifications_identical": call_match,
                "rank_order_identical": rank_match,
            }
            if not call_match:
                failures.append(f"{column}: p < 0.05 classifications differ")
            if not rank_match:
                failures.append(f"{column}: rank order differs")
    return checks, failures


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Compare local and Code Ocean OMIX Limma outputs"
    )
    parser.add_argument("--local-dir", required=True, type=Path)
    parser.add_argument("--code-ocean-dir", required=True, type=Path)
    parser.add_argument("--tolerance", type=float, default=1e-12)
    parser.add_argument("--report", required=True, type=Path)
    parser.add_argument(
        "--summary-key",
        action="append",
        dest="summary_keys",
        help="Stable run-summary key to compare; repeat as needed",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.tolerance < 0:
        raise SystemExit("--tolerance must be non-negative")
    local_dir = args.local_dir.resolve()
    platform_dir = args.code_ocean_dir.resolve()
    summary_keys = tuple(
        key.strip().lower() for key in (args.summary_keys or DEFAULT_SUMMARY_KEYS)
    )
    failures: list[str] = []
    for root, label in ((local_dir, "local"), (platform_dir, "Code Ocean")):
        if not root.is_dir():
            failures.append(f"{label} output directory does not exist: {root}")
            continue
        for filename in REQUIRED_FILES:
            if not (root / filename).is_file():
                failures.append(f"{label} output is missing {filename}")

    report: dict[str, object] = {
        "contract": "omix-limma-cross-environment-v1",
        "local_directory": str(local_dir),
        "code_ocean_directory": str(platform_dir),
        "numeric_tolerance": args.tolerance,
        "required_files": list(REQUIRED_FILES),
        "files": {},
    }
    if not failures:
        for filename in ("Limma_Analysis.csv", "Sample_Metadata.csv", "Variance_Diagnostic.csv"):
            result, file_failures = compare_table(
                local_dir / filename,
                platform_dir / filename,
                args.tolerance,
            )
            report["files"][filename] = result
            failures.extend(file_failures)

        summary_result, summary_failures = compare_summary(
            local_dir / "run_summary.txt",
            platform_dir / "run_summary.txt",
            summary_keys,
        )
        report["files"]["run_summary.txt"] = summary_result
        failures.extend(summary_failures)

        png_result, png_failures = compare_png(
            local_dir / "variance_diagnostic.png",
            platform_dir / "variance_diagnostic.png",
        )
        report["files"]["variance_diagnostic.png"] = png_result
        failures.extend(png_failures)

        call_checks, call_failures = significance_and_rank_checks(
            local_dir / "Limma_Analysis.csv",
            platform_dir / "Limma_Analysis.csv",
        )
        report["statistical_checks"] = call_checks
        failures.extend(call_failures)

    report["passed"] = not failures
    report["failures"] = failures
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    if failures:
        print("Cross-environment comparison FAILED:", file=sys.stderr)
        for failure in failures:
            print(f"- {failure}", file=sys.stderr)
        print(f"Reviewable report: {args.report}", file=sys.stderr)
        return 1
    print(f"Cross-environment comparison passed: {args.report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
