# OMIX Limma Analysis interface-3 equivalence evidence

## Scope

This record compares an interface-3 SCTransform mean-expression analysis run
locally in the pinned `r-statistics` runtime with the corresponding Code Ocean
execution. It validates numerical and decision equivalence for the scientific
handoff. It does not establish a new adapter tag or Code Ocean release, and it
does not close the separate App Panel compatibility review.

## Source, runtime, and platform identity

| Item | Identity |
| --- | --- |
| Canonical module | `OMIX-Limma-Analysis 1.0.0` (interface `3`) |
| Canonical source | `296a77d141af59ab813439d44148b5ce5e100e11` |
| Adapter merge tested | `d33b1a06f488b00224919f328d1e592f1b334620` |
| Published runtime | `ghcr.io/nidap-community/omix-r-statistics@sha256:1325722877fec5167d171aa766ddf7bbfd056e4999bf40fd8c1eabee495da667` |
| Code Ocean capsule | `8635652` |
| Code Ocean run | `2087235`, completed 2026-10-15 in 1 minute 34 seconds |
| Comparison contract | `omix-limma-cross-environment-v1` |
| Numeric tolerance | `1e-12` |

The adapter and canonical source identities are recorded separately from the
Code Ocean platform configuration and runtime profile. No tag or release is
inferred from this validation run.

## Deterministic fixture and model

The synthetic fixture contained 120 features and eight samples. Its three
inputs had these SHA-256 checksums:

| Input | SHA-256 |
| --- | --- |
| `SCT_Mean_Log2_Expression.csv` | `07876358078e370df78c3e7987fecbd0b3ae6133eca841398433b77bf99707d5` |
| `Pseudobulk_Sample_Metadata.csv` | `4df670a03667895abf6926c9d2ab8949e2488cdc027f20aeb3e8b88200fa4687` |
| `Pseudobulk_Manifest.dcf` | `d11b8d6bb4c37ec6a251ddd5215ec45775fd8379b87770ec207b042ce360f2f2` |

Both executions resolved the same scientific contract:

- requested input data type: `auto`;
- resolved input data type: `sctransform_mean_expression`, from the manifest;
- requested variance model: `auto`;
- resolved variance model: `ebayes_trend`, from the manifest;
- model type: repeated measures;
- explicit contrast: `B-A`;
- group replicate counts: `A=4,B=4`; and
- consensus donor correlation: `0.0804143064354035` locally and
  `0.0804143064354037` in Code Ocean.

## Comparison results

The repository comparator completed successfully:

```bash
python3 tests/compare-cross-environment.py \
  --local-dir /path/to/local-results \
  --code-ocean-dir /path/to/code-ocean-results \
  --tolerance 1e-12 \
  --report comparison-report.json
```

| Check | Result |
| --- | --- |
| `Limma_Analysis.csv` dimensions | 120 rows by 19 columns in both runs |
| Result headers | Identical |
| Result numeric values compared | 2,160 |
| Maximum result-table absolute difference | `1.9984014443252818e-14` |
| Cells outside tolerance | 0 |
| `Variance_Diagnostic.csv` dimensions | 120 rows by 3 columns in both runs |
| Maximum diagnostic absolute difference | `9.992007221626409e-16` |
| Nominal-p significance classifications | Identical |
| Adjusted-p significance classifications | Identical |
| Nominal-p and adjusted-p rank order | Identical |
| `Sample_Metadata.csv` | Byte-identical |
| `variance_diagnostic.png` | Byte-identical, 1400 by 1000 pixels |
| Overall comparison | Passed |

The analysis and diagnostic CSV files are not byte-identical because of
cross-host floating-point formatting below `2e-14`. These differences are far
below the `1e-12` acceptance threshold and did not alter rankings,
significance classifications, resolved methods, or output structure.

## Recorded output checksums

| Artifact | Local SHA-256 | Code Ocean SHA-256 |
| --- | --- | --- |
| `Limma_Analysis.csv` | `c8fd5fceba2e15ce186ab546a3fc755f805175eb46bd1dc0d0591eeb445f94df` | `64820539bc2c941c324b345c0664af2b3c7bae3e6d4531a776ebab10754b5236` |
| `Sample_Metadata.csv` | `4df670a03667895abf6926c9d2ab8949e2488cdc027f20aeb3e8b88200fa4687` | `4df670a03667895abf6926c9d2ab8949e2488cdc027f20aeb3e8b88200fa4687` |
| `Variance_Diagnostic.csv` | `47db2d733160a0a497edd913f9894456121ba368367f532071716b8dfae2470e` | `071dd48b4b5521bcb0ae8869f389aac2733b7140af91a9e0767974ea432d35c2` |
| `run_summary.txt` | `abafb93652281c3410e32c0caf7ae649120ba92a52b9e57386e85c0bd564f67c` | `2a05ab7f29b62854d73a97a03a270fe626c713a84ac8f65646a66d55b59c5b8c` |
| `variance_diagnostic.png` | `519d95f0b65e745aab66b9aaedee216413199b1746cfcdc29a3b5b56b72d8e3e` | `519d95f0b65e745aab66b9aaedee216413199b1746cfcdc29a3b5b56b72d8e3e` |

The run-summary checksums differ because input paths and platform provenance
are environment-specific. The comparator verified all stable scientific
fields individually.

## Acceptance conclusion and remaining boundary

Run `2087235` satisfies the interface-3 scientific reproducibility criterion
for this representative SCTransform repeated-measures handoff. The complete
machine-readable comparison is stored in
[`limma-interface3-run2087235-comparison.json`](limma-interface3-run2087235-comparison.json).

During capsule preparation, Code Ocean rejected the repository-synchronized
App Panel as improperly modified and the run used Code Ocean's accepted panel
state after **Revert and Run**. The run nevertheless resolved the interface-3
input type and variance model from the manifest and exercised current
scientific code. App Panel schema acceptance and exposure of all interface-3
controls therefore remain a separate deployment-UI requirement before a new
release decision.
