# Changelog

## Unreleased

### Changed

- Synchronizes the byte-identical canonical OMIX Limma Analysis `0.1.1`
  implementation, adding support for numeric modeled-group labels and natural
  contrasts such as `1-0`.
- Adds adapter workflow-handoff regression coverage for numeric `0`/`1`
  groups without changing Code Ocean input discovery, runtime, or outputs.
- Updates adapter-owned run-summary provenance to canonical module `0.1.1`
  and source commit `db70975167807d10634d5af33fc49828e32be633`, with regression
  assertions that prevent source and summary records from drifting.

### Validated

- Code Ocean run `1216757` exercised the Harmony mean-expression handoff with
  numeric contrast `1-0`, resolved `variance_model = auto` to `ebayes`, and
  recorded the corrected canonical `0.1.1` provenance.
- Comparison against the exact published `r-statistics` image digest found
  identical structure, ordering, rankings, significance classifications, and
  metadata. The largest numeric difference was `1.07e-14`; repeated local
  container runs were byte-identical.

## 0.1.0 - 2026-10-04

### Added

- Initial Code Ocean deployment adapter for canonical OMIX Limma Analysis
  `0.1.0`, interface version `1`.
- Byte-identical export of the canonical Limma scientific function.
- Explicit upload or unambiguous recursive discovery of a continuous matrix,
  aligned sample metadata, and optional Pseudobulk manifest.
- Raw-count handoff rejection with routing to OMIX DEG Analysis.
- Complete App Panel coverage of the canonical user-settable interface.
- Local input-discovery, workflow-handoff, App Panel, and source-parity tests.

### Validated

- Code Ocean release-producing run `1134919` exercised the Seurat Pseudobulk
  SCTransform mean-expression handoff and resolved `variance_model = auto` to
  `ebayes_trend` from the attached manifest.
- Standard Capsule release `1.0` was created from source capsule `8635652` at
  `ffab7e89-72c4-4271-b888-b02a1e06db7c/tree/v1`.
