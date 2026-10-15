#!/usr/bin/env python3

import hashlib
import re
from pathlib import Path


expected_commit = "296a77d141af59ab813439d44148b5ce5e100e11"
expected_hash = "385e7683c6f582a8edb7248efadc52193b89b819749005a5c7e9ebf4d684b268"
source_record = Path("OMIX_MODULE_SOURCE.md").read_text()

commit_match = re.search(
    r"Canonical source reference:\*\*\s*\[`([0-9a-f]{40})`\]", source_record
)
assert commit_match, "Canonical source reference is missing"
assert commit_match.group(1) == expected_commit

managed_files = sorted(
    path.relative_to("code/functions").as_posix()
    for path in Path("code/functions").rglob("*")
    if path.is_file()
)
assert managed_files == ["OMIX_Limma_Analysis.R"], managed_files

managed_path = Path("code/functions/OMIX_Limma_Analysis.R")
observed_hash = hashlib.sha256(managed_path.read_bytes()).hexdigest()
assert observed_hash == expected_hash, observed_hash
assert source_record.count(f"`{expected_hash}`") >= 1
assert "`R/OMIX_Limma_Analysis.R`" in source_record
assert "`code/functions/OMIX_Limma_Analysis.R`" in source_record
assert ".syncweaver-lock.json` **Pending** generation by Syncweaver" in source_record

print("OMIX Limma Analysis managed-source provenance passed")
