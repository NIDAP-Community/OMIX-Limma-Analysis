# OMIX Limma Analysis 0.1.1 equivalence evidence

## Scope

This record compares the OMIX Limma Analysis `0.1.1` Harmony handoff in Code
Ocean with the same analysis executed locally in the exact published
`r-statistics` image. It validates deployment equivalence; it does not make a
biological claim about the demonstration contrast.

## Immutable identities

| Item | Identity |
| --- | --- |
| Canonical OMIX source | `db70975167807d10634d5af33fc49828e32be633` |
| Canonical module | `OMIX-Limma-Analysis 0.1.1` (interface `1`) |
| Adapter merge containing corrected provenance | `e3085e46fcba7bf810bd6938475e8eafb1e302df` |
| Published runtime | `ghcr.io/nidap-community/omix-r-statistics@sha256:1325722877fec5167d171aa766ddf7bbfd056e4999bf40fd8c1eabee495da667` |
| Runtime R / limma | R `4.4.3`; limma `3.62.2` |
| Code Ocean capsule | `8635652` |
| Code Ocean run | `1216757`, completed 2026-10-05 |

The Code Ocean App Panel reported runtime profile
`r-statistics r4.4.3-bioconductor3.20-v1`. The public digest above is the
corresponding OMIX runtime recorded by this adapter.

## Inputs and parameters

- Matrix: `Harmony_Mean_Expression.csv`
- Metadata: `Pseudobulk_Sample_Metadata.csv`
- Manifest: `Pseudobulk_Manifest.dcf`
- Feature ID: `GeneName`
- Sample ID: `Sample`
- Modeled metadata field: `Group`
- Contrast: `1-0`
- Input kind: `log2_expression`
- Requested variance model: `auto`
- Manifest recommendation and resolved variance model: `ebayes`
- Duplicate-feature summarization: `mean`
- Append modeled matrix: `true`

Both executions emitted the expected warning that zero sample variances in the
small demonstration input were offset away from zero.

## Local pinned-container command

```bash
docker run --rm --platform linux/amd64 \
  -v "$OMIX_ROOT/modules/OMIX-Limma-Analysis:/module:ro" \
  -v "$INPUT_DIR:/input:ro" \
  -v "$OUTPUT_DIR:/output" \
  ghcr.io/nidap-community/omix-r-statistics@sha256:1325722877fec5167d171aa766ddf7bbfd056e4999bf40fd8c1eabee495da667 \
  Rscript /module/scripts/run_limma_analysis.R \
    --matrix /input/Harmony_Mean_Expression.csv \
    --metadata /input/Pseudobulk_Sample_Metadata.csv \
    --gene_names_column GeneName \
    --sample_names_column Sample \
    --contrast_variable_columns Group \
    --contrasts 1-0 \
    --input_kind log2_expression \
    --variance_model auto \
    --pseudobulk_manifest /input/Pseudobulk_Manifest.dcf \
    --summarization_method mean \
    --return_matrix true \
    --output_dir /output
```

## Comparison results

| Check | Result |
| --- | --- |
| Result dimensions | 200 rows by 16 columns in both runs |
| Column names | Identical |
| Gene identity and order | Identical |
| Numeric values compared | 3,000 |
| Maximum absolute difference | `1.0658141036401503e-14` |
| Maximum relative difference | `2.0391139071322415e-14` |
| Values differing by more than `1e-12` | 0 |
| Nominal `p < 0.05` classifications | Identical |
| Adjusted `p < 0.05` classifications | Identical |
| t-statistic and p-value rankings | Identical |
| Sample metadata | Byte-identical |
| Repeated local pinned-container runs | Byte-identical |

The Code Ocean and local result CSV files are not byte-identical because 21 of
3,000 numeric values differ below `1.1e-14`. This is accepted as cross-host
floating-point variation and is far below the `1e-12` numerical-equivalence
threshold. No reported scientific conclusion, ordering, or significance call
changed.

## Recorded checksums

| Artifact | SHA-256 |
| --- | --- |
| Code Ocean `Limma_Analysis.csv` | `cf60ef60e567d46c73ee87a2fc5c881565c484abfed05a252c5f2f655607b817` |
| Local pinned-container `Limma_Analysis.csv` | `80c9944e8ab72daea5f24041d4d01d36e9442ecbf8979a2ba9f1e5ec0fe50c2b` |
| Code Ocean and local `Sample_Metadata.csv` | `9ab6a2d6ff01f6a2e591801414ffdf5f27651492f593538cb3deea6cb42f05a8` |

These checksums identify the compared artifacts. Numerical equivalence, not
cross-host byte identity, is the acceptance criterion for the analysis table.
