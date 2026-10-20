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
  make_option("--contrasts", type = "character", default = "", help = "Optional comma-separated limma contrasts; blank infers the only replicated two-group comparison"),
  make_option("--covariate_columns", type = "character", default = ""),
  make_option("--batch_effect_columns", type = "character", default = "", help = "Optional comma-separated technical batch columns included in the model and eligible for downstream removal"),
  make_option("--donor_variable_column", type = "character", default = ""),
  make_option("--summarization_method", type = "character", default = "mean", help = "mean, max, or sum"),
  make_option("--input_data_type", type = "character", default = "auto", help = "Scientific matrix type or auto; see the canonical interface schema"),
  make_option("--input_kind", type = "character", default = "auto", help = "auto, log2_expression, enrichment_score, or continuous_score"),
  make_option("--measurement_scale", type = "character", default = "", help = "Required description for other_continuous inputs"),
  make_option("--fraction_transform", type = "character", default = "auto", help = "auto, none, arcsin_sqrt, or logit"),
  make_option("--fraction_pseudocount", type = "double", default = 1e-04, help = "Boundary value used only for an explicit logit fraction transform"),
  make_option("--variance_model", type = "character", default = "auto", help = "auto, ebayes, or ebayes_trend"),
  make_option("--return_matrix", type = "character", default = "true", help = "true or false"),
  make_option("--return_batch_corrected_values", type = "character", default = "false", help = "true writes Batch_Corrected_Expression.csv when batch columns are declared"),
  make_option("--output_dir", type = "character", default = "", help = "Platform-managed output directory; defaults to /results")
)

opt <- parse_args(OptionParser(
  usage = "Usage: %prog [--contrasts B-A] [input selectors] [options]",
  option_list = option_list,
  description = "Code Ocean adapter for canonical OMIX Limma Analysis."
))

contrasts <- omix_limma_split_csv(opt$contrasts)
contrast_columns <- omix_limma_split_csv(opt$contrast_variable_columns)
if (!length(contrast_columns) %in% c(1L, 2L)) {
  stop("--contrast_variable_columns must name one or two metadata columns.", call. = FALSE)
}
if (!opt$summarization_method %in% c("mean", "max", "sum")) {
  stop("--summarization_method must be mean, max, or sum.", call. = FALSE)
}
resolved <- omix_limma_resolve_inputs(
  matrix = opt$matrix,
  metadata = opt$metadata,
  pseudobulk_manifest = opt$pseudobulk_manifest,
  gene_names_column = opt$gene_names_column,
  sample_names_column = opt$sample_names_column,
  code_dir = code_dir
)
input_contract <- omix_limma_resolve_input_contract(
  input_data_type = opt$input_data_type,
  input_kind = opt$input_kind,
  variance_model = opt$variance_model,
  fraction_transform = opt$fraction_transform,
  manifest_matrix_type = omix_limma_manifest_value(resolved$manifest, "matrix_type"),
  manifest_recommended_variance_model = omix_limma_manifest_value(
    resolved$manifest,
    "recommended_variance_model"
  )
)
declared_input_kind <- omix_limma_manifest_value(resolved$manifest, "downstream_input_kind")
if (nzchar(declared_input_kind) && !identical(declared_input_kind, input_contract$input_kind)) {
  stop(
    "Resolved input_kind ('", input_contract$input_kind,
    "') does not match the pseudobulk manifest ('", declared_input_kind, "').",
    call. = FALSE
  )
}

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
  batch_effect_columns = omix_limma_split_csv(opt$batch_effect_columns),
  donor_variable_column = omix_limma_split_csv(opt$donor_variable_column),
  summarization_method = opt$summarization_method,
  return_matrix = omix_limma_as_logical(opt$return_matrix, "return_matrix"),
  return_batch_corrected_values = omix_limma_as_logical(opt$return_batch_corrected_values, "return_batch_corrected_values"),
  input_kind = input_contract$input_kind,
  variance_model = input_contract$variance_model,
  input_data_type = input_contract$input_data_type,
  measurement_scale = opt$measurement_scale,
  fraction_transform = input_contract$fraction_transform,
  fraction_pseudocount = opt$fraction_pseudocount
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
if (isTRUE(run$return_batch_corrected_values) && length(run$adjusted_batch_columns) > 0L) {
  downstream_expression <- attr(results, "omix_limma_downstream_expression")
  downstream_table <- data.frame(
    Gene = rownames(downstream_expression),
    as.data.frame(downstream_expression, check.names = FALSE),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  utils::write.csv(
    downstream_table,
    file.path(output_dir, "Batch_Corrected_Expression.csv"),
    row.names = FALSE,
    na = ""
  )
}
variance_diagnostic <- attr(results, "omix_limma_variance_diagnostic")
utils::write.csv(
  variance_diagnostic,
  file.path(output_dir, "Variance_Diagnostic.csv"),
  row.names = FALSE,
  na = ""
)
grDevices::png(
  file.path(output_dir, "variance_diagnostic.png"),
  width = 1400,
  height = 1000,
  res = 160
)
graphics::plot(
  variance_diagnostic$Average_Signal,
  variance_diagnostic$Residual_SD,
  pch = 16,
  col = grDevices::adjustcolor("#2C7FB8", alpha.f = 0.55),
  xlab = "Average feature signal",
  ylab = "Residual standard deviation",
  main = "Residual variance diagnostic"
)
if (nrow(variance_diagnostic) >= 5L && length(unique(variance_diagnostic$Average_Signal)) >= 5L) {
  variance_trend <- stats::lowess(
    variance_diagnostic$Average_Signal,
    variance_diagnostic$Residual_SD
  )
  graphics::lines(variance_trend, col = "#D7301F", lwd = 3)
}
grDevices::dev.off()
writeLines(c(
  "OMIX Limma Analysis run summary",
  paste("matrix input:", resolved$matrix_path),
  paste("metadata input:", resolved$metadata_path),
  paste("pseudobulk manifest:", if (nzchar(resolved$manifest_path)) resolved$manifest_path else "<none>"),
  paste("pseudobulk matrix type:", if (is.null(resolved$manifest)) "<none>" else omix_limma_manifest_value(resolved$manifest, "matrix_type")),
  paste("requested input data type:", input_contract$requested_input_data_type),
  paste("input data type:", run$input_data_type),
  paste("input data type source:", input_contract$input_data_type_source),
  paste("input kind:", run$input_kind),
  paste("measurement scale:", if (nzchar(run$measurement_scale)) run$measurement_scale else "<not supplied>"),
  paste("requested fraction transform:", input_contract$requested_fraction_transform),
  paste("fraction transform:", run$fraction_transform),
  paste("fraction pseudocount:", if (is.na(run$fraction_pseudocount)) "<not used>" else run$fraction_pseudocount),
  paste("requested variance model:", input_contract$requested_variance_model),
  paste("recommended variance model:", if (is.na(input_contract$recommended_variance_model)) "<none>" else input_contract$recommended_variance_model),
  paste("variance model source:", input_contract$variance_model_source),
  paste("variance model:", run$variance_model),
  paste("model type:", run$model_type),
  paste("design formula:", run$design_formula),
  paste("batch effect columns:", if (length(run$batch_effect_columns)) paste(run$batch_effect_columns, collapse = ",") else "<none>"),
  paste("return batch-corrected values:", run$return_batch_corrected_values),
  paste("adjusted batch columns:", if (length(run$adjusted_batch_columns)) paste(run$adjusted_batch_columns, collapse = ",") else "<none>"),
  paste("requested contrasts:", if (length(run$requested_contrasts)) paste(run$requested_contrasts, collapse = ",") else "<blank>"),
  paste("resolved contrasts:", paste(run$contrasts, collapse = ",")),
  paste("contrast source:", run$contrast_source),
  paste("group replicate counts:", paste0(names(run$group_replicate_counts), "=", as.integer(run$group_replicate_counts), collapse = ",")),
  paste("genes modelled:", run$genes_modelled),
  paste("samples modelled:", run$samples_modelled),
  paste("consensus donor correlation:", run$consensus_correlation),
  "canonical module: OMIX-Limma-Analysis 1.1.0 (interface 3)",
  "canonical source: 8ad4cdb4ee92aff9f2b53f69a2e33137a4e1886c",
  "runtime profile: r-statistics r4.4.3-bioconductor3.20-v1"
), file.path(output_dir, "run_summary.txt"))

message("Wrote OMIX Limma Analysis results to ", normalizePath(output_dir, mustWork = TRUE))
