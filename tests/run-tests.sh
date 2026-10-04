#!/usr/bin/env bash
set -euo pipefail

Rscript -e 'invisible(parse(file = "code/functions/OMIX_Limma_Analysis.R")); invisible(parse(file = "code/adapter/Limma_Adapter.R")); invisible(parse(file = "code/main.R"))'
Rscript tests/test-adapter-inputs.R
Rscript tests/test-pseudobulk-handoff.R
python3 tests/test-app-panel.py
python3 tests/test-source-parity.py

echo "All local OMIX Limma Analysis adapter checks passed"
