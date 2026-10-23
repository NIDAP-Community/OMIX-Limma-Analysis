work_dir <- tempfile("omix-limma-handoff-")
dir.create(work_dir)
on.exit(unlink(work_dir, recursive = TRUE), add = TRUE)

matrix <- data.frame(
  GeneName = c("Gene1", "Gene2", "Gene3"),
  D1__A = c(4.8, 6.1, 7.2), D2__A = c(5.0, 6.0, 7.3), D3__A = c(4.9, 6.2, 7.1),
  D1__B = c(5.8, 6.4, 7.0), D2__B = c(6.0, 6.5, 7.1), D3__B = c(5.9, 6.3, 7.2),
  check.names = FALSE
)
metadata <- data.frame(
  Sample = names(matrix)[-1L],
  Group = rep(c("A", "B"), each = 3L),
  Donor = rep(paste0("D", seq_len(3L)), 2L),
  stringsAsFactors = FALSE
)
matrix_path <- file.path(work_dir, "SCT_Mean_Log2_Expression.csv")
metadata_path <- file.path(work_dir, "Pseudobulk_Sample_Metadata.csv")
manifest_path <- file.path(work_dir, "Pseudobulk_Manifest.dcf")
output_dir <- file.path(work_dir, "results")
utils::write.csv(matrix, matrix_path, row.names = FALSE)
utils::write.csv(metadata, metadata_path, row.names = FALSE)
base::write.dcf(data.frame(
  matrix_type = "sctransform_mean_log2_expression",
  expected_downstream_module = "OMIX-Limma-Analysis",
  expected_downstream_mode = "continuous_expression",
  downstream_input_kind = "log2_expression",
  recommended_variance_model = "ebayes_trend",
  stringsAsFactors = FALSE
), manifest_path)

output <- system2(
  file.path(R.home("bin"), "Rscript"),
  c(
    "code/main.R",
    "--matrix", matrix_path,
    "--metadata", metadata_path,
    "--pseudobulk_manifest", manifest_path,
    "--contrasts", "B-A",
    "--donor_variable_column", "Donor",
    "--output_dir", output_dir
  ),
  stdout = TRUE,
  stderr = TRUE
)
if (!is.null(attr(output, "status"))) {
  stop("Adapter command failed:\n", paste(output, collapse = "\n"))
}

results_path <- file.path(output_dir, "Limma_Analysis.csv")
metadata_output <- file.path(output_dir, "Sample_Metadata.csv")
summary_path <- file.path(output_dir, "run_summary.txt")
diagnostic_path <- file.path(output_dir, "Variance_Diagnostic.csv")
diagnostic_plot_path <- file.path(output_dir, "variance_diagnostic.png")
stopifnot(all(file.exists(c(
  results_path, metadata_output, summary_path, diagnostic_path, diagnostic_plot_path
))))

results <- utils::read.csv(results_path, check.names = FALSE)
summary_lines <- readLines(summary_path)
stopifnot(
  all(c("B-A_FC", "B-A_logFC", "B-A_tstat", "B-A_pval", "B-A_adjpval") %in% names(results)),
  any(grepl("requested input data type: auto", summary_lines, fixed = TRUE)),
  any(grepl("input data type: sctransform_mean_expression", summary_lines, fixed = TRUE)),
  any(grepl("input data type source: manifest", summary_lines, fixed = TRUE)),
  any(grepl("requested variance model: auto", summary_lines, fixed = TRUE)),
  any(grepl("recommended variance model: ebayes_trend", summary_lines, fixed = TRUE)),
  any(grepl("variance model: ebayes_trend", summary_lines, fixed = TRUE)),
  any(grepl("model type: repeated_measures", summary_lines, fixed = TRUE)),
  any(grepl("requested contrasts: B-A", summary_lines, fixed = TRUE)),
  any(grepl("resolved contrasts: B-A", summary_lines, fixed = TRUE)),
  any(grepl("contrast source: explicit", summary_lines, fixed = TRUE)),
  any(grepl("canonical module: OMIX-Limma-Analysis 1.2.0 (interface 3)", summary_lines, fixed = TRUE)),
  any(grepl("canonical source: 54da7cf6f7d775211ad1e9e6a9fb5b850f91fcc5", summary_lines, fixed = TRUE))
)

# Declared technical batches are retained in the DE model and, only when
# explicitly requested, produce a separate matrix for downstream continuous
# workflows. The biological comparison remains protected during removal.
batch_metadata_path <- file.path(work_dir, "Batch_Pseudobulk_Sample_Metadata.csv")
batch_output_dir <- file.path(work_dir, "batch-results")
utils::write.csv(
  transform(metadata, Batch = c("Batch1", "Batch2", "Batch1", "Batch2", "Batch1", "Batch2")),
  batch_metadata_path,
  row.names = FALSE
)
batch_output <- system2(
  file.path(R.home("bin"), "Rscript"),
  c(
    "code/main.R",
    "--matrix", matrix_path,
    "--metadata", batch_metadata_path,
    "--pseudobulk_manifest", manifest_path,
    "--contrasts", "B-A",
    "--batch_effect_columns", "Batch",
    "--return_batch_corrected_values", "true",
    "--output_dir", batch_output_dir
  ),
  stdout = TRUE,
  stderr = TRUE
)
if (!is.null(attr(batch_output, "status"))) {
  stop("Batch-corrected adapter command failed:\n", paste(batch_output, collapse = "\n"))
}
batch_matrix <- utils::read.csv(
  file.path(batch_output_dir, "Batch_Corrected_Expression.csv"),
  check.names = FALSE
)
batch_summary <- readLines(file.path(batch_output_dir, "run_summary.txt"))
stopifnot(
  identical(names(batch_matrix), c("Gene", metadata$Sample)),
  any(grepl("batch effect columns: Batch", batch_summary, fixed = TRUE)),
  any(grepl("return batch-corrected values: TRUE", batch_summary, fixed = TRUE)),
  any(grepl("adjusted batch columns: Batch", batch_summary, fixed = TRUE))
)

# A blank contrast must infer the sole replicated two-group comparison and
# record the decision rather than imposing a deployment-specific default.
inferred_output_dir <- file.path(work_dir, "inferred-results")
inferred_output <- system2(
  file.path(R.home("bin"), "Rscript"),
  c(
    "code/main.R",
    "--matrix", matrix_path,
    "--metadata", metadata_path,
    "--pseudobulk_manifest", manifest_path,
    "--output_dir", inferred_output_dir
  ),
  stdout = TRUE,
  stderr = TRUE
)
if (!is.null(attr(inferred_output, "status"))) {
  stop("Inferred-contrast adapter command failed:\n", paste(inferred_output, collapse = "\n"))
}
inferred_summary <- readLines(file.path(inferred_output_dir, "run_summary.txt"))
stopifnot(
  any(grepl("requested contrasts: <blank>", inferred_summary, fixed = TRUE)),
  any(grepl("resolved contrasts: B-A", inferred_summary, fixed = TRUE)),
  any(grepl("contrast source: inferred", inferred_summary, fixed = TRUE)),
  any(grepl("group replicate counts: A=3,B=3", inferred_summary, fixed = TRUE))
)

message("OMIX Limma Analysis pseudobulk workflow-handoff checks passed")

# Seurat metadata commonly encodes biological groups as numeric cluster-like
# values. The canonical module maps those values to valid internal design
# names while preserving the natural requested contrast in result columns.
numeric_metadata_path <- file.path(work_dir, "Numeric_Pseudobulk_Sample_Metadata.csv")
numeric_output_dir <- file.path(work_dir, "numeric-results")
utils::write.csv(
  transform(metadata, Group = ifelse(Group == "A", "0", "1")),
  numeric_metadata_path,
  row.names = FALSE
)
numeric_output <- system2(
  file.path(R.home("bin"), "Rscript"),
  c(
    "code/main.R",
    "--matrix", matrix_path,
    "--metadata", numeric_metadata_path,
    "--pseudobulk_manifest", manifest_path,
    "--contrast_variable_columns", "Group",
    "--contrasts", "1-0",
    "--output_dir", numeric_output_dir
  ),
  stdout = TRUE,
  stderr = TRUE
)
if (!is.null(attr(numeric_output, "status"))) {
  stop("Numeric-group adapter command failed:\n", paste(numeric_output, collapse = "\n"))
}
numeric_results <- utils::read.csv(
  file.path(numeric_output_dir, "Limma_Analysis.csv"),
  check.names = FALSE
)
stopifnot(all(c(
  "0_Mean", "1_Mean", "1-0_FC", "1-0_logFC", "1-0_pval", "1-0_adjpval"
) %in% names(numeric_results)))
numeric_summary <- readLines(file.path(numeric_output_dir, "run_summary.txt"))
stopifnot(
  any(grepl("canonical module: OMIX-Limma-Analysis 1.2.0 (interface 3)", numeric_summary, fixed = TRUE)),
  any(grepl("canonical source: 54da7cf6f7d775211ad1e9e6a9fb5b850f91fcc5", numeric_summary, fixed = TRUE))
)

# Numeric-looking arithmetic is invalid when the modeled groups are not
# numeric labels; this protects the App Panel from silently fitting nonsense.
invalid_numeric_output <- system2(
  file.path(R.home("bin"), "Rscript"),
  c(
    "code/main.R",
    "--matrix", matrix_path,
    "--metadata", metadata_path,
    "--pseudobulk_manifest", manifest_path,
    "--contrast_variable_columns", "Group",
    "--contrasts", "1-0",
    "--output_dir", file.path(work_dir, "invalid-numeric-results")
  ),
  stdout = TRUE,
  stderr = TRUE
)
stopifnot(
  identical(attr(invalid_numeric_output, "status"), 1L),
  any(grepl("do not compare modeled group coefficients", invalid_numeric_output, fixed = TRUE))
)

message("OMIX Limma Analysis numeric-group workflow-handoff checks passed")

# The deployment entry point must pass the new interface-3 CIBERSORT controls
# to the canonical function rather than implementing its own transformation.
fraction_matrix <- data.frame(
  GeneName = c("CellType1", "CellType2", "CellType3"),
  D1__A = c(0.20, 0.30, 0.50), D2__A = c(0.25, 0.25, 0.50),
  D3__A = c(0.30, 0.20, 0.50), D1__B = c(0.50, 0.20, 0.30),
  D2__B = c(0.55, 0.15, 0.30), D3__B = c(0.60, 0.10, 0.30),
  check.names = FALSE
)
fraction_matrix_path <- file.path(work_dir, "CIBERSORT_Relative_Fractions.csv")
fraction_output_dir <- file.path(work_dir, "fraction-results")
utils::write.csv(fraction_matrix, fraction_matrix_path, row.names = FALSE)
fraction_output <- system2(
  file.path(R.home("bin"), "Rscript"),
  c(
    "code/main.R",
    "--matrix", fraction_matrix_path,
    "--metadata", metadata_path,
    "--input_data_type", "cibersort_relative_fractions",
    "--contrasts", "B-A",
    "--output_dir", fraction_output_dir
  ),
  stdout = TRUE,
  stderr = TRUE
)
if (!is.null(attr(fraction_output, "status"))) {
  stop("CIBERSORT adapter command failed:\n", paste(fraction_output, collapse = "\n"))
}
fraction_results <- utils::read.csv(
  file.path(fraction_output_dir, "Limma_Analysis.csv"),
  check.names = FALSE
)
fraction_summary <- readLines(file.path(fraction_output_dir, "run_summary.txt"))
stopifnot(
  "B-A_effect" %in% names(fraction_results),
  any(grepl("input data type: cibersort_relative_fractions", fraction_summary, fixed = TRUE)),
  any(grepl("fraction transform: arcsin_sqrt", fraction_summary, fixed = TRUE)),
  any(grepl("variance model: ebayes", fraction_summary, fixed = TRUE))
)

message("OMIX Limma Analysis CIBERSORT interface-3 handoff checks passed")
