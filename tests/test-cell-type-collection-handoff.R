write_bundle_manifest <- function(path) {
  base::write.dcf(data.frame(
    matrix_type = "sctransform_mean_log2_expression",
    expected_downstream_module = "OMIX-Limma-Analysis",
    expected_downstream_mode = "continuous_expression",
    downstream_input_kind = "log2_expression",
    recommended_variance_model = "ebayes_trend",
    stringsAsFactors = FALSE
  ), path)
}

make_collection <- function(root) {
  ids <- c(
    "ct-t-cells-11111111111111111111111111111111",
    "ct-monocytes-22222222222222222222222222222222"
  )
  labels <- c("T cells", "Monocytes")
  catalog_rows <- list()
  for (index in seq_along(ids)) {
    id <- ids[[index]]
    bundle_dir <- file.path(root, "cell_types", id)
    dir.create(bundle_dir, recursive = TRUE, showWarnings = FALSE)
    samples <- c(paste0("M", seq_len(3L)), paste0("F", seq_len(3L)))
    matrix <- data.frame(
      GeneName = c("Gene1", "Gene2", "Gene3"),
      setNames(lapply(seq_along(samples), function(sample_index) {
        c(5, 6, 7) + (sample_index <= 3L) * (index / 3)
      }), samples),
      check.names = FALSE
    )
    metadata <- data.frame(
      Sample = samples,
      Donor = samples,
      Group = c(rep("M", 3L), rep("F", 3L)),
      CellType = labels[[index]],
      Cells = 40L,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
    utils::write.csv(matrix, file.path(bundle_dir, "SCT_Mean_Log2_Expression.csv"), row.names = FALSE)
    utils::write.csv(metadata, file.path(bundle_dir, "Pseudobulk_Sample_Metadata.csv"), row.names = FALSE)
    write_bundle_manifest(file.path(bundle_dir, "Pseudobulk_Manifest.dcf"))
    catalog_rows[[index]] <- data.frame(
      CellTypeID = id,
      CellType = labels[[index]],
      SelectionMode = "selected",
      Donor = metadata$Donor,
      Group = metadata$Group,
      Cells = metadata$Cells,
      MinCells = 20L,
      ProfileEligibility = "eligible",
      MatrixPath = file.path("cell_types", id, "SCT_Mean_Log2_Expression.csv"),
      MetadataPath = file.path("cell_types", id, "Pseudobulk_Sample_Metadata.csv"),
      BundleManifestPath = file.path("cell_types", id, "Pseudobulk_Manifest.dcf"),
      AggregationMethod = "mean_sctransform_expression",
      SourceAssay = "SCT",
      SourceLayer = "data",
      SourceSeuratRds = "/not-a-real-study-object.rds",
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  }
  utils::write.csv(
    do.call(rbind, catalog_rows),
    file.path(root, "Cell_Type_Profile_Catalog.csv"),
    row.names = FALSE
  )
  manifest_path <- file.path(root, "Pseudobulk_Collection_Manifest.dcf")
  base::write.dcf(data.frame(
    format_version = "1",
    collection_kind = "cell_type_pseudobulk",
    cell_type_selection_mode = "selected",
    selected_cell_type_count = "2",
    aggregation_method = "mean_sctransform_expression",
    source_assay = "SCT",
    source_layer = "data",
    source_seurat_rds = "/not-a-real-study-object.rds",
    min_cells = "20",
    on_insufficient_cells = "error",
    profile_catalog = "Cell_Type_Profile_Catalog.csv",
    stringsAsFactors = FALSE
  ), manifest_path)
  manifest_path
}

work_dir <- tempfile("omix-limma-collection-adapter-")
dir.create(work_dir)
on.exit(unlink(work_dir, recursive = TRUE), add = TRUE)
collection_root <- file.path(work_dir, "collection")
dir.create(collection_root)
collection_manifest <- make_collection(collection_root)
output_dir <- file.path(work_dir, "results")

# The adapter selects a route and resolves the mounted top-level manifest; the
# canonical export owns all collection validation and Limma/L2P science.
output <- system2(
  file.path(R.home("bin"), "Rscript"),
  c(
    "code/main.R",
    "--analysis_route", "cell_type_collection",
    "--pseudobulk_collection_manifest", collection_manifest,
    "--contrast", "M-F",
    "--output_dir", output_dir
  ),
  stdout = TRUE,
  stderr = TRUE
)
if (!is.null(attr(output, "status"))) {
  stop("Cell-type collection adapter command failed:\n", paste(output, collapse = "\n"))
}

expected_comparisons <- c(
  "ct-t-cells-11111111111111111111111111111111__M-F",
  "ct-monocytes-22222222222222222222222222222222__M-F"
)
expected_outputs <- c(
  "L2P_Multi_Input.csv",
  "L2P_Multi_Input_Provenance.csv",
  "Limma_Cell_Type_Collection_Catalog.csv",
  "Limma_Cell_Type_Collection_Run_Summary.txt"
)
stopifnot(all(file.exists(file.path(output_dir, expected_outputs))))
wide <- utils::read.csv(file.path(output_dir, "L2P_Multi_Input.csv"), check.names = FALSE)
expected_columns <- c("GeneName", unlist(lapply(expected_comparisons, function(comparison) {
  paste0(comparison, c("_tstat", "_pval", "_FC"))
}), use.names = FALSE))
stopifnot(
  identical(names(wide), expected_columns),
  identical(as.character(wide$GeneName), c("Gene1", "Gene2", "Gene3")),
  all(vapply(wide[-1L], is.numeric, logical(1))),
  all(is.finite(as.matrix(wide[-1L])))
)
provenance <- utils::read.csv(
  file.path(output_dir, "L2P_Multi_Input_Provenance.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
stopifnot(
  identical(provenance$Comparison, expected_comparisons),
  identical(provenance$SelectionMode, c("selected", "selected"))
)

# Rejecting legacy matrix selectors in this route prevents an accidental
# one-matrix bundle from being silently reinterpreted as a collection.
invalid <- system2(
  file.path(R.home("bin"), "Rscript"),
  c(
    "code/main.R",
    "--analysis_route", "cell_type_collection",
    "--pseudobulk_collection_manifest", collection_manifest,
    "--matrix", file.path(collection_root, "cell_types", "ct-t-cells-11111111111111111111111111111111", "SCT_Mean_Log2_Expression.csv"),
    "--output_dir", file.path(work_dir, "invalid-results")
  ),
  stdout = TRUE,
  stderr = TRUE
)
stopifnot(
  identical(attr(invalid, "status"), 1L),
  any(grepl("cell_type_collection does not accept", invalid, fixed = TRUE))
)

# The converse route guard is equally important because the static App Panel
# shows both manifest selectors. A collection manifest must never be silently
# ignored by the default legacy route.
invalid_single_matrix <- system2(
  file.path(R.home("bin"), "Rscript"),
  c(
    "code/main.R",
    "--analysis_route", "single_matrix",
    "--pseudobulk_collection_manifest", collection_manifest,
    "--output_dir", file.path(work_dir, "invalid-single-matrix-results")
  ),
  stdout = TRUE,
  stderr = TRUE
)
stopifnot(
  identical(attr(invalid_single_matrix, "status"), 1L),
  any(grepl("single_matrix does not accept --pseudobulk_collection_manifest", invalid_single_matrix, fixed = TRUE))
)

message("OMIX Limma Analysis cell-type collection adapter handoff checks passed")
