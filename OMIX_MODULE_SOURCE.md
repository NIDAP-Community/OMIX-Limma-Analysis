# Canonical OMIX Module Source

## Canonical module

- **Module:** [OMIX Limma Analysis](https://github.com/NIDAP-Community/OMIX/tree/main/modules/OMIX-Limma-Analysis)
- **Canonical path:** `modules/OMIX-Limma-Analysis/`
- **Canonical module version:** `0.1.2`
- **Canonical interface version:** `2`
- **Canonical release tag:** **Pending** — no validated namespaced module tag is established.
- **Canonical source reference:** [`a25d57bcb75b0461648a60833f1957444a47ba28`](https://github.com/NIDAP-Community/OMIX/commit/a25d57bcb75b0461648a60833f1957444a47ba28)
- **Interface schema:** [schemas/interface.yml](https://github.com/NIDAP-Community/OMIX/blob/a25d57bcb75b0461648a60833f1957444a47ba28/modules/OMIX-Limma-Analysis/schemas/interface.yml)
- **Module contract:** [OMIX module contract](https://github.com/NIDAP-Community/OMIX/blob/main/docs/module-contract.md)

## Adapter release record

| Field | Recorded value |
| --- | --- |
| Adapter version | `0.1.0` |
| Adapter release tag | `v0.1.0`; finalized from the merged post-release evidence commit. |
| Platform release | Code Ocean Standard Capsule release `1.0`: [`ffab7e89-72c4-4271-b888-b02a1e06db7c/tree/v1`](https://poc-nci.codeocean.io/capsule/ffab7e89-72c4-4271-b888-b02a1e06db7c/tree/v1), created 2026-10-04 from source capsule `8635652`. |
| Canonical runtime profile | `r-statistics` |
| Published OMIX runtime | `ghcr.io/nidap-community/omix-r-statistics@sha256:1325722877fec5167d171aa766ddf7bbfd056e4999bf40fd8c1eabee495da667` |
| Runtime lockfile | `starter-environments/r-statistics/renv.lock`, SHA-256 `e86f6e0c2175bff1b4c1d73be67928fa9d808e78f325f407b3b7d278c1c71156` |
| Adapter-selected base image | `codeocean/omix-r-statistics:r4.4.3-bioconductor3.20-v1` |
| Code Ocean environment identity | Starter Environment `OMIX Statistics (1)`, selected and validated in capsule `8635652`; this platform identity is recorded separately from the public GHCR digest. |
| Capsule run | Release-producing run `1134919` in capsule `8635652`, completed successfully on 2026-10-04 using an attached OMIX Seurat Pseudobulk SCT mean-expression result. |
| Syncweaver mapping | `.syncweaver-lock.json` **Pending** generation by Syncweaver; the initial interim export and hash are recorded below. |

The canonical source commit, adapter tag, public OCI digest, Code Ocean
environment, capsule run, and platform release are separate facts.

## Representative platform validation

Code Ocean capsule [`8635652`](https://poc-nci.codeocean.io/capsule/8635652/tree)
completed release-producing run `1134919` with the attached result asset
`OMIX Seurat Pseudobulk SCT Mean Demo`. The adapter discovered
`SCT_Mean_Log2_Expression.csv`, `Pseudobulk_Sample_Metadata.csv`, and
`Pseudobulk_Manifest.dcf` without explicit file selections. The validation used
metadata field `My_Variable_1` and contrast `M-F` because the five treatment
labels in this small demonstration result each had only one sample and therefore
did not provide replication for a treatment contrast.

The run modeled 12,584 genes across five samples and wrote
`Limma_Analysis.csv`, `Sample_Metadata.csv`, and `run_summary.txt`. The summary
records pseudobulk matrix type `sctransform_mean_log2_expression`, requested
variance model `auto`, manifest recommendation `ebayes_trend`, and resolved
variance model `ebayes_trend`. The run emitted the expected warning that zero
sample variances were offset away from zero for this small demonstration input;
it did not fail. This evidence validates the adapter handoff and manifest-based
variance routing, not the biological interpretation of the demonstration
contrast. The successful run produced Standard Capsule release
[`1.0`](https://poc-nci.codeocean.io/capsule/ffab7e89-72c4-4271-b888-b02a1e06db7c/tree/v1).

### Version 0.1.1 pre-release equivalence validation

Code Ocean run `1216757` in source capsule
[`8635652`](https://poc-nci.codeocean.io/capsule/8635652/tree) validated the
canonical `0.1.1` numeric-group-label behavior with the OMIX Seurat Pseudobulk
Harmony handoff. The run used `Harmony_Mean_Expression.csv`,
`Pseudobulk_Sample_Metadata.csv`, and `Pseudobulk_Manifest.dcf`; modeled
metadata field `Group`; requested contrast `1-0`; and resolved
`variance_model = auto` to `ebayes`. It modeled 200 genes across five samples
and completed successfully. The run summary records canonical source
`db70975167807d10634d5af33fc49828e32be633` and module version `0.1.1`
(interface `1`).

The Code Ocean results were compared with a local run of the exact published
runtime image
`ghcr.io/nidap-community/omix-r-statistics@sha256:1325722877fec5167d171aa766ddf7bbfd056e4999bf40fd8c1eabee495da667`
using the same inputs, canonical source, and parameters. Both outputs contained
the same 200 genes and 16 columns with identical names, gene order, statistical
rankings, nominal and adjusted significance classifications, and byte-identical
`Sample_Metadata.csv`. The maximum absolute numeric difference across 3,000
values was `1.07e-14`; no scientific result changed. Two repeated local
container runs produced byte-identical outputs. The small cross-host difference
is within floating-point tolerance for the Code Ocean host versus local Docker
x86 emulation on Apple ARM hardware. Full commands, checksums, and acceptance
criteria are recorded in
[`validation/limma-0.1.1-equivalence.md`](validation/limma-0.1.1-equivalence.md).

## Exported scientific files

| Canonical file | Adapter copy | SHA-256 | Purpose |
| --- | --- | --- | --- |
| `R/OMIX_Limma_Analysis.R` | `code/functions/OMIX_Limma_Analysis.R` | `fb48597b758f5acd3339157afc96110d07ba8351a6da7b9be81ed4e4e489ce11` | Canonical Limma model and result construction. |

The complete canonical `R/` tree contains this one file at the recorded source
commit. The adapter copy is byte-identical; no scientific edit was applied.

## Interface translation

- Canonical `matrix`, `metadata`, and optional `pseudobulk_manifest` paths are
  Code Ocean file selectors. Blank selectors trigger content-based discovery
  under `/data` and must be unambiguous.
- Canonical `output_dir` is platform-managed as `/results` and is intentionally
  hidden from the App Panel.
- Comma-separated App Panel fields are translated into canonical character
  vectors without changing order.
- A blank contrast is passed to canonical OMIX unchanged. Canonical OMIX alone
  decides whether one replicated two-group comparison is unambiguous; the
  adapter never chooses among biological contrasts.
- `return_matrix` is translated from the App Panel string to an R logical.
- Manifest validation and `variance_model = auto` match the canonical CLI
  handoff behavior. The adapter does not introduce another statistical model.

## Synchronization

- **Canonical source directory:** `modules/OMIX-Limma-Analysis/R/`
- **Adapter destination:** `code/functions/`
- **Generated lockfile:** **Pending** Syncweaver generation. Do not hand-author
  `.syncweaver-lock.json`.
- **Interim content verification:** exact file-set and SHA-256 checks are in
  `tests/test-source-parity.py`.
- **Host-side drift:** None in the initial export.

Scientific or reusable-interface changes must be made and validated in
canonical OMIX first. Until Syncweaver onboards the mapping, Harbor may refresh
the managed export only by copying the complete canonical `R/` tree
byte-for-byte from a reviewed immutable source. Beacon verifies parity,
interface translation, runtime provenance, and representative outputs before
release.
