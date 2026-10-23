# Adapter validation

Run all local contract checks from the repository root:

```bash
bash tests/run-tests.sh
```

These checks cover syntax, attached-input discovery, raw-count rejection,
SCT-manifest variance routing, legacy one-matrix output names, collection
manifest discovery, a representative collection-to-ordered-L2P-Multi CLI
handoff, App Panel coverage/defaults, and the managed scientific file hash.
They also self-test the reusable
cross-environment comparator. Code Ocean validation is recorded separately and
is not implied by local success.

## Local-versus-Code Ocean comparison

After running one reviewed fixture locally in the exact published runtime and
through the synchronized Code Ocean capsule, download both complete result
directories and run:

```bash
python3 tests/compare-cross-environment.py \
  --local-dir /path/to/local-results \
  --code-ocean-dir /path/to/code-ocean-results \
  --tolerance 1e-12 \
  --report /path/to/limma-cross-environment-report.json
```

The command compares table dimensions, columns, feature order, categorical and
missing values, numerical results, significance classifications, p-value
rankings, stable scientific run-summary fields, variance diagnostics, and PNG
dimensions. The JSON report records checksums and maximum numerical difference.
It exits nonzero when the declared contract fails. Record the exact fixture,
parameters, commits, runtime identities, capsule/run IDs, tolerance, report
checksum, and independent review in `validation/` before proposing `active`
canonical status.
