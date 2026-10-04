# Deployment Adapter Agent Instructions

This repository is the Code Ocean deployment adapter for the canonical
[OMIX Limma Analysis](https://github.com/NIDAP-Community/OMIX/tree/main/modules/OMIX-Limma-Analysis)
module recorded in [OMIX_MODULE_SOURCE.md](OMIX_MODULE_SOURCE.md).

## Ownership

- Canonical OMIX owns scientific functions, defaults, the portable CLI,
  schemas, tests, and scientific documentation.
- This repository owns Code Ocean UI, attached-input discovery, `/results`
  routing, runtime selection, and adapter tests.
- `code/functions/` is a managed byte-identical export of the canonical
  module's complete `R/` directory. Never edit it directly.
- Scientific or reusable-interface changes must be made, reviewed, and tested
  in canonical OMIX before the managed export is refreshed.

## Working rules

1. Read this file, `README.md`, `OMIX_MODULE_SOURCE.md`, and the canonical
   interface schema before editing.
2. Expose every user-settable canonical parameter in the App Panel. The
   platform-managed `output_dir` is the only hidden canonical field.
3. Discover mounted inputs only when exactly one compatible candidate exists;
   otherwise list candidates and require explicit selection.
4. Preserve the canonical scientific defaults and stable output filenames.
5. Reject raw-count pseudobulk and direct users to OMIX DEG Analysis.
6. Use the pinned `r-statistics` runtime. Never use `latest`.
7. Do not commit inputs, results, credentials, caches, or package inventories.
8. Run local adapter checks and a representative Code Ocean workflow handoff.
   Report those evidence classes separately.

## Release discipline

Do not infer an adapter tag, Code Ocean release, run status, or immutable
runtime identity. Keep unavailable evidence marked Pending. A platform release
requires a clean merged commit, representative platform validation, and
explicit approval.
