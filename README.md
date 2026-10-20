# OMIX Limma Analysis — Code Ocean Adapter

Fit limma linear or donor-blocked models to a declared continuous
feature-by-sample matrix with aligned sample metadata.

## Canonical OMIX module

| Item | Location |
| --- | --- |
| Canonical module | [OMIX Limma Analysis](https://github.com/NIDAP-Community/OMIX/tree/main/modules/OMIX-Limma-Analysis) |
| Interface contract | [schemas/interface.yml](https://github.com/NIDAP-Community/OMIX/blob/main/modules/OMIX-Limma-Analysis/schemas/interface.yml) |
| Development contract | [OMIX module contract](https://github.com/NIDAP-Community/OMIX/blob/main/docs/module-contract.md) |
| Version and source record | [OMIX_MODULE_SOURCE.md](OMIX_MODULE_SOURCE.md) |

Canonical OMIX owns the scientific function, portable CLI, tests, and public
input/output contract. Its complete `R/` tree is exported byte-for-byte under
`code/functions/`. This repository owns only Code Ocean file discovery,
parameter translation, result placement, runtime selection, and adapter tests.

## Main uses

Use this capsule for declared continuous matrices such as:

- donor-level means from corrected `SCT/data` expression;
- donor-level means from a declared corrected expression assay such as
  `Harmony/data`;
- GSVA or ssGSEA enrichment scores; or
- CIBERSORT relative fractions or absolute scores;
- normalized microarray, bulk-expression, proteomics, metabolomics,
  methylation M-value, chromatin-accessibility, CRISPR-score, qPCR delta-Ct,
  or copy-number log2-ratio matrices; or
- another documented continuous feature score with aligned biological
  replicates.

Do not use it for raw RNA counts. Raw-count pseudobulk must be analyzed with
OMIX DEG Analysis so that library normalization and voom precision weights are
applied. CIBERSORT relative fractions are supported through the declared
fraction input type and transformation controls; do not pass other proportions
as generic continuous scores without a justified transformation.

## Inputs

| Input | Requirement |
| --- | --- |
| Continuous matrix | CSV, TSV, TXT, or RDS feature-by-sample table. The default feature column is `GeneName`. |
| Sample metadata | CSV, TSV, TXT, or RDS table with a unique `Sample` column aligned to matrix sample columns. |
| Pseudobulk manifest | Optional `Pseudobulk_Manifest.dcf` from OMIX Seurat Pseudobulk. Required for that workflow handoff. |

Each input can be selected explicitly. When a selector is blank, the adapter
recursively examines attached files under `/data` and proceeds only when one
compatible candidate is unambiguous. Multiple candidates are listed in the
error so the user can select the intended file.

For an OMIX Seurat Pseudobulk result, keep these three files together:

- `SCT_Mean_Log2_Expression.csv` or `Harmony_Mean_Expression.csv`;
- `Pseudobulk_Sample_Metadata.csv`; and
- `Pseudobulk_Manifest.dcf`.

The manifest verifies the matrix semantics and downstream route. With
**Variance Model** set to `auto`, Harmony means use `ebayes` and SCTransform
means use `ebayes_trend`. A raw-count manifest stops with instructions to use
OMIX DEG Analysis.

## Run the analysis

1. Attach an upstream Pseudobulk result or provide the continuous matrix and
   metadata files directly.
2. Enter one or two contrast-variable columns. Supply one or more
   comma-separated Limma contrasts, such as `B-A` or `1-0` when the modeled
   groups are numeric, or leave the field blank only when the selected model
   has exactly two groups with at least two samples each. In that one
   unambiguous case, the capsule infers and records the sole comparison.
3. Add covariates only when scientifically justified. Use **Batch Effect
   Columns** only for declared technical batches; they are modeled in the DE
   analysis and can be removed from the optional downstream expression matrix
   without changing DE statistics. Add a donor variable only when a donor
   contributes repeated modeled profiles.
4. Select the scientific **Input Data Type**, or keep `auto` only when a
   compatible Pseudobulk manifest or backward-compatible Input Kind supplies
   the declaration. The program never guesses SCT, Harmony, GSVA, or another
   assay type from numeric values alone.
5. Keep **Variance Model** at `auto` to use the documented default for the
   declared data type, or select an explicit model after reviewing the
   variance diagnostic. `other_continuous` requires both an explicit variance
   model and a Measurement Scale description.
6. For CIBERSORT relative fractions, `auto` uses an arcsine-square-root
   transform. An explicit logit transform uses the Fraction Pseudocount at
   zero and one boundaries.
7. Run the capsule.

`input_kind` controls effect-size naming and normally remains `auto`. Log2
expression returns signed `FC` and `logFC` columns; enrichment and continuous
scores return `effect` in the input units. See the
[canonical module guide](https://github.com/NIDAP-Community/OMIX/tree/main/modules/OMIX-Limma-Analysis)
for the variance-model recommendation for every supported data type.

## Outputs

| Output | Purpose |
| --- | --- |
| `Limma_Analysis.csv` | Contrast statistics and, by default, the aligned modeled matrix. |
| `Sample_Metadata.csv` | Metadata in modeled sample order. |
| `Batch_Corrected_Expression.csv` | Optional continuous matrix with declared technical batch effects removed while biological groups are protected. Written only when requested with at least one varying batch column. |
| `run_summary.txt` | Resolved inputs, variance model, design, contrasts, donor correlation, source, and runtime provenance. |
| `Variance_Diagnostic.csv` | Per-feature average signal and pre-moderation residual standard deviation. |
| `variance_diagnostic.png` | Visual check for a remaining mean-variance trend. |

## Environment and reproducibility

- **Runtime profile:** `r-statistics`
- **Code Ocean environment:**
  `codeocean/omix-r-statistics:r4.4.3-bioconductor3.20-v1`
- **Public immutable image:**
  `ghcr.io/nidap-community/omix-r-statistics@sha256:1325722877fec5167d171aa766ddf7bbfd056e4999bf40fd8c1eabee495da667`
- **Source and release record:** [OMIX_MODULE_SOURCE.md](OMIX_MODULE_SOURCE.md)

Record the adapter commit, selected parameters, input asset or checksums, and
the Code Ocean run or release identity with scientific results.

## Troubleshooting

| Message | Resolution |
| --- | --- |
| No compatible matrix or metadata | Attach the required file or select it explicitly. |
| Multiple compatible candidates | Select the intended file in the App Panel or attach only one input bundle. |
| `raw_integer_counts` | Run the bundle with OMIX DEG Analysis instead. |
| No metadata IDs match matrix columns | Check sample naming and the Sample ID Column setting. |
| Donor has no repeated profiles | Leave Donor Variable Column blank for an ordinary linear model. |
| Blank contrast is ambiguous | Select a replicated model variable and provide the intended contrast. The error lists group replicate counts. |
| Contrast is not estimable | Confirm group labels, contrast spelling, replicate counts, and confounded covariates. |

Numeric group labels such as `0` and `1` are supported directly. Enter the
natural contrast `1-0`; the adapter preserves that label in its result columns
while the canonical module uses valid internal R design names. `1-0` is
rejected when `1` and `0` are not actual modeled groups, so ordinary arithmetic
cannot silently become a biological contrast.

## For developers

Read [AGENTS.md](AGENTS.md) and [OMIX_MODULE_SOURCE.md](OMIX_MODULE_SOURCE.md)
before editing. Scientific changes belong in canonical OMIX and must reach
`code/functions/` as a complete byte-identical managed export.

## References and support

- [Canonical module documentation](https://github.com/NIDAP-Community/OMIX/tree/main/modules/OMIX-Limma-Analysis)
- [limma User's Guide](https://bioconductor.org/packages/limma)
- [OMIX issue tracker](https://github.com/NIDAP-Community/OMIX/issues)
