# Deployment code

- `main.R` translates Code Ocean named parameters and invokes the canonical
  Limma function.
- `adapter/Limma_Adapter.R` owns mounted-input discovery, table reading,
  manifest validation, and deployment output paths.
- `functions/` is a managed byte-identical export of the canonical module's
  complete `R/` directory. Do not edit it directly.
- `run` is the Code Ocean launcher.
