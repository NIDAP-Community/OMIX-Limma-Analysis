source(file.path("code", "adapter", "Limma_Adapter.R"))

root <- tempfile("omix-limma-inputs-")
dir.create(file.path(root, "bundle"), recursive = TRUE)
old_roots <- getOption("omix.limma.data_roots")
options(omix.limma.data_roots = root)
on.exit({
  options(omix.limma.data_roots = old_roots)
  unlink(root, recursive = TRUE)
}, add = TRUE)

matrix_path <- file.path(root, "bundle", "SCT_Mean_Log2_Expression.csv")
metadata_path <- file.path(root, "bundle", "Pseudobulk_Sample_Metadata.csv")
manifest_path <- file.path(root, "bundle", "Pseudobulk_Manifest.dcf")

matrix <- data.frame(
  GeneName = c("Gene1", "Gene2"),
  D1__A = c(4.8, 6.1),
  D1__B = c(5.8, 6.4),
  check.names = FALSE
)
metadata <- data.frame(
  Sample = c("D1__A", "D1__B"),
  Group = c("A", "B"),
  stringsAsFactors = FALSE
)
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

resolved <- omix_limma_resolve_inputs(code_dir = file.path(getwd(), "code"))
stopifnot(
  identical(resolved$matrix_path, normalizePath(matrix_path)),
  identical(resolved$metadata_path, normalizePath(metadata_path)),
  identical(resolved$manifest_path, normalizePath(manifest_path)),
  identical(
    omix_limma_resolve_variance_model("auto", resolved$manifest)$resolved,
    "ebayes_trend"
  )
)

explicit <- omix_limma_resolve_inputs(
  matrix = matrix_path,
  metadata = metadata_path,
  pseudobulk_manifest = manifest_path,
  code_dir = file.path(getwd(), "code")
)
stopifnot(identical(explicit$matrix_path, normalizePath(matrix_path)))

second_matrix <- file.path(root, "another_matrix.csv")
utils::write.csv(matrix, second_matrix, row.names = FALSE)
unlink(manifest_path)
ambiguous <- tryCatch(
  omix_limma_resolve_inputs(
    metadata = metadata_path,
    code_dir = file.path(getwd(), "code")
  ),
  error = conditionMessage
)
stopifnot(
  grepl("Multiple compatible continuous matrix candidates", ambiguous, fixed = TRUE),
  grepl(normalizePath(matrix_path), ambiguous, fixed = TRUE),
  grepl(normalizePath(second_matrix), ambiguous, fixed = TRUE)
)

raw_manifest <- file.path(root, "Pseudobulk_Manifest.dcf")
base::write.dcf(data.frame(
  matrix_type = "raw_integer_counts",
  expected_downstream_module = "OMIX-DEG-Analysis",
  expected_downstream_mode = "raw_counts",
  stringsAsFactors = FALSE
), raw_manifest)
raw_error <- tryCatch(
  omix_limma_resolve_inputs(
    matrix = matrix_path,
    metadata = metadata_path,
    pseudobulk_manifest = raw_manifest,
    code_dir = file.path(getwd(), "code")
  ),
  error = conditionMessage
)
stopifnot(
  grepl("raw_integer_counts", raw_error, fixed = TRUE),
  grepl("OMIX-DEG-Analysis", raw_error, fixed = TRUE)
)

message("OMIX Limma Analysis adapter input-discovery checks passed")
