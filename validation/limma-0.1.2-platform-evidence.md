# OMIX Limma Analysis 0.1.2 platform evidence

## Scope

This record documents the Code Ocean Standard Capsule 2.0 release and the
GSVA-to-Limma workflow handoff for the deployment adapter. It changes no
scientific code, interface, App Panel parameter, runtime, or test behavior.

## Immutable source and runtime identity

| Item | Value |
| --- | --- |
| Canonical module | `OMIX-Limma-Analysis 0.1.2` (interface `2`) |
| Canonical source commit | `a25d57bcb75b0461648a60833f1957444a47ba28` |
| Validated adapter commit | `ed6d3cb058c9618dd18f14d9eaad4192e178bac7` |
| Proposed adapter tag | Annotated `v0.1.2` targeting `ed6d3cb058c9618dd18f14d9eaad4192e178bac7`; pending owner approval and creation |
| Source capsule | [`8635652`](https://poc-nci.codeocean.io/capsule/8635652/tree) |
| Standard Capsule release | [`2.0`](https://poc-nci.codeocean.io/capsule/ffab7e89-72c4-4271-b888-b02a1e06db7c/tree/v2) |
| Code Ocean environment | `OMIX Statistics (1)` |
| Adapter runtime label | `r-statistics r4.4.3-bioconductor3.20-v1` |
| Published runtime digest | `ghcr.io/nidap-community/omix-r-statistics@sha256:1325722877fec5167d171aa766ddf7bbfd056e4999bf40fd8c1eabee495da667` |

The platform environment name and public OCI digest are recorded as separate
facts; this evidence does not claim that Code Ocean exposes an immutable digest
for its imported Starter Environment.

## Validation runs

| Run | Purpose | Outcome |
| --- | --- | --- |
| `1216757` | Harmony mean-expression handoff and local-container equivalence | Passed; 200 genes, five samples, `1-0`, `ebayes`, maximum cross-host numeric difference `1.07e-14` |
| `1244387` | Release-producing safe blank-contrast inference | Passed; inferred `1-0`, replicate counts `0=2,1=3`, 12,584 genes, five samples, `ebayes_trend` |
| `1254366` | Upstream OMIX GSVA result generation | Passed; mouse Hallmark collection, 50 enrichment-score features, nine samples |
| `1254876` | GSVA enrichment-score input into OMIX Limma Analysis | Passed; ordered contrasts `B-A,C-A,C-B`, replicate counts `A=3,B=3,C=3`, 50 features, nine samples, `ebayes` |

Runs `1254681` and `1254820` were setup diagnostics rather than acceptance
evidence. They exposed, respectively, ambiguous metadata attachments and an
incorrect metadata-column selection. The final test detached unrelated assets,
attached a metadata-only asset, selected `Group`, and passed as run `1254876`.

## GSVA-to-Limma handoff details

Upstream GSVA run `1254366` completed in capsule
[`3631910`](https://poc-nci.codeocean.io/capsule/3631910/tree) and produced:

- `gsva_results.csv`
- `gsva_heatmap.png`
- `gsva_run_summary.txt`

The result was captured as data asset `OMIX GSVA Mouse Hallmark Scores for
Limma` in folder `omix-gsva-mouse-hallmark-limma`. Limma run `1254876` used:

- matrix: `/data/omix-gsva-mouse-hallmark-limma/gsva_results.csv`
- metadata: `/data/deg-training-metadata/metadata_ccbr_bulk_training.csv`
- input kind: `enrichment_score`
- model: `linear`
- design: `~0 + contmerge`
- requested and resolved contrasts: `B-A,C-A,C-B`
- contrast source: `explicit`
- requested and resolved variance model: `ebayes`

The run wrote:

- `Limma_Analysis.csv` (28.91 KB)
- `Sample_Metadata.csv` (207 B)
- `run_summary.txt` (786 B)

The terminal completed with `Wrote OMIX Limma Analysis results to /results`.

## Acceptance conclusion

The adapter at `ed6d3cb058c9618dd18f14d9eaad4192e178bac7` preserves canonical
scientific code and successfully supports SCT, Harmony, and GSVA continuous
matrix handoffs under the published `r-statistics` runtime. Standard Capsule
2.0 is therefore supported by the recorded release evidence. Tag creation
remains a separate owner-authorized action and must target the validated adapter
commit, not this later metadata-only evidence commit.
