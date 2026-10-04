#!/usr/bin/env Rscript

# Thin Code Ocean entry point for canonical OMIX Limma Analysis.
# Deployment discovery and path translation live in code/adapter/. The
# scientific function is sourced unchanged from code/functions/.

suppressPackageStartupMessages(library(optparse))

code_dir <- local({
  candidates <- commandArgs(FALSE)[grepl("^--file=", commandArgs(FALSE))]
  if (length(candidates) == 0L) normalizePath(getwd(), mustWork = TRUE) else
    dirname(normalizePath(sub("^--file=", "", candidates[[1L]]), mustWork = TRUE))
})
source(file.path(code_dir, "adapter", "Limma_Adapter.R"))
source(file.path(code_dir, "functions", "OMIX_Limma_Analysis.R"))

option_list <- list(
  make_option("--matrix", type = "character", default = "", help = "Continuous matrix; blank discovers one compatible input under /data"),
  make_option("--metadata", type = "character", default = "", help = "Sample metadata; blank discovers one compatible input under /data"),
  make_option("--pseudobulk_manifest", type = "character", default = "", help = "Optional Pseudobulk_Manifest.dcf; blank discovers zero or one under /data"),
  make_option("--gene_names_column", type = "character", default = "GeneName"),
  make_option("--sample_names_column", type = "character", default = "Sample"),
  make_option("--samples_to_include", type = "character", default = ""),
  make_option("--contrast_variable_columns", type = "character", default = "Group"),
  make_option("--contrasts", type = "character", default = "", help = "Required comma-separated limma contrasts, such as B-A"),
  make_option("--covariate_columns", type = "character", default = ""),
  make_option("--donor_variable_column", type = "character", default = ""),
  make_option("--summarization_method", type = "character", default = "mean", help = "mean, max, or sum"),
  make_option("--input_kind", type = "character", default = "log2_expression", help = "log2_expression, enrichment_score, or continuous_score"),
  make_option("--variance_model", type = "character", default = "auto", help = "auto, ebayes, or ebayes_trend"),
  make_option("--return_matrix", type = "character", default = "true", help = "true or false"),
  make_option("--output_dir", type = "character", default = "", help = "Platform-managed output directory; defaults to /results")
)

opt <- parse_args(OptionParser(
  usage = "Usage: %prog --contrasts B-A [input selectors] [options]",
  option_list = option_list,
  description = "Code Ocean adapter for canonical OMIX Limma Analysis."
))

contrasts <- omix_limma_split_csv(opt$contrasts)
if (length(contrasts) == 0L) stop("--contrasts is required.", call. = FALSE)
contrast_columns <- omix_limma_split_csv(opt$contrast_variable_columns)
if (!length(contrast_columns) %in% c(1L, 2L)) {
  stop("--contrast_variable_columns must name one or two metadata columns.", call. = FALSE)
}
if (!opt$summarization_method %in% c("mean", "max", "sum")) {
  stop("--summarization_method must be mean, max, or sum.", call. = FALSE)
}
if (!opt$input_kind %in% c("log2_expression", "enrichment_score", "continuous_score")) {
  stop("--input_kind must be log2_expression, enrichment_score, or continuous_score.", call. = FALSE)
}

resolved <- omix_limma_resolve_inputs(
  matrix = opt$matrix,
  metadata = opt$metadata,
  pseudobulk_manifest = opt$pseudobulk_manifest,
  gene_names_column = opt$gene_names_column,
  sample_names_column = opt$sample_names_column,
  input_kind = opt$input_kind,
  code_dir = code_dir
)
variance <- omix_limma_resolve_variance_model(opt$variance_model, resolved$manifest)

selected_samples <- omix_limma_split_csv(opt$samples_to_include)
if (length(selected_samples) == 0L) {
  selected_samples <- intersect(
    as.character(resolved$metadata[[opt$sample_names_column]]),
    names(resolved$matrix)
  )
}
if (length(selected_samples) == 0L) {
  stop("No metadata sample IDs occur as columns in the continuous matrix.", call. = FALSE)
}

output_dir <- omix_limma_output_dir(opt$output_dir, code_dir)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

results <- omix_limma_analysis(
  Dataset = resolved$matrix,
  Metadata_Table = resolved$metadata,
  sample_names_column = opt$sample_names_column,
  samples_to_include = selected_samples,
  gene_names_column = opt$gene_names_column,
  contrast_variable_columns = contrast_columns,
  contrasts = contrasts,
  covariate_columns = omix_limma_split_csv(opt$covariate_columns),
  donor_variable_column = omix_limma_split_csv(opt$donor_variable_column),
  summarization_method = opt$summarization_method,
  return_matrix = omix_limma_as_logical(opt$return_matrix, "return_matrix"),
  input_kind = opt$input_kind,
  variance_model = variance$resolved
)

utils::write.csv(
  results,
  file.path(output_dir, "Limma_Analysis.csv"),
  row.names = FALSE,
  na = ""
)
output_metadata <- resolved$metadata[
  match(selected_samples, as.character(resolved$metadata[[opt$sample_names_column]])),
  ,
  drop = FALSE
]
utils::write.csv(
  output_metadata,
  file.path(output_dir, "Sample_Metadata.csv"),
  row.names = FALSE,
  na = ""
)

run <- attr(results, "omix_limma_run")
writeLines(c(
  "OMIX Limma Analysis run summary",
  paste("matrix input:", resolved$matrix_path),
  paste("metadata input:", resolved$metadata_path),
  paste("pseudobulk manifest:", if (nzchar(resolved$manifest_path)) resolved$manifest_path else "<none>"),
  paste("pseudobulk matrix type:", if (is.null(resolved$manifest)) "<none>" else omix_limma_manifest_value(resolved$manifest, "matrix_type")),
  paste("input kind:", run$input_kind),
  paste("requested variance model:", variance$requested),
  paste("manifest recommended variance model:", if (nzchar(variance$recommended)) variance$recommended else "<none>"),
  paste("variance model:", run$variance_model),
  paste("model type:", run$model_type),
  paste("design formula:", run$design_formula),
  paste("contrasts:", paste(contrasts, collapse = ", ")),
  paste("genes modelled:", run$genes_modelled),
  paste("samples modelled:", run$samples_modelled),
  paste("consensus donor correlation:", run$consensus_correlation),
  "canonical module: OMIX-Limma-Analysis 0.1.0 (interface 1)",
  "canonical source: 5396be0203b94fc1e22cb2eaf74d8265a32466a7",
  "runtime profile: r-statistics r4.4.3-bioconductor3.20-v1"
), file.path(output_dir, "run_summary.txt"))

message("Wrote OMIX Limma Analysis results to ", normalizePath(output_dir, mustWork = TRUE))
