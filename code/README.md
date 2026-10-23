# Deployment code

- `main.R` translates Code Ocean named parameters and invokes either the
  canonical legacy single-matrix function or its collection entry point. Its
  adapter-owned `analysis_route` controls that dispatch; collection routing
  consumes only a top-level `Pseudobulk_Collection_Manifest.dcf` and does not
  add scientific behavior.
- `adapter/Limma_Adapter.R` owns mounted-input discovery, table reading,
  manifest validation, and deployment output paths. It discovers a collection
  manifest only when exactly one file named
  `Pseudobulk_Collection_Manifest.dcf` is mounted.
- `functions/` is a managed byte-identical export of the canonical module's
  complete `R/` directory. Do not edit it directly.
- `run` is the Code Ocean launcher.
