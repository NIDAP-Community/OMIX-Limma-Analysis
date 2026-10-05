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
stopifnot(all(file.exists(c(results_path, metadata_output, summary_path))))

results <- utils::read.csv(results_path, check.names = FALSE)
summary_lines <- readLines(summary_path)
stopifnot(
  all(c("B-A_FC", "B-A_logFC", "B-A_tstat", "B-A_pval", "B-A_adjpval") %in% names(results)),
  any(grepl("requested variance model: auto", summary_lines, fixed = TRUE)),
  any(grepl("manifest recommended variance model: ebayes_trend", summary_lines, fixed = TRUE)),
  any(grepl("variance model: ebayes_trend", summary_lines, fixed = TRUE)),
  any(grepl("model type: repeated_measures", summary_lines, fixed = TRUE))
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

message("OMIX Limma Analysis numeric-group workflow-handoff checks passed")
