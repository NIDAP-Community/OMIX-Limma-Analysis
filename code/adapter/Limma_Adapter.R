# Code Ocean-only input, manifest, and output translation for OMIX Limma.
# Scientific modeling remains in code/functions/OMIX_Limma_Analysis.R.

omix_limma_split_csv <- function(value) {
  if (is.null(value) || length(value) == 0L || is.na(value) || !nzchar(trimws(value))) {
    return(character())
  }
  values <- trimws(strsplit(value, ",", fixed = TRUE)[[1L]])
  unique(values[nzchar(values)])
}

omix_limma_as_logical <- function(value, argument) {
  normalized <- tolower(trimws(as.character(value)))
  if (normalized %in% c("true", "t", "1", "yes")) return(TRUE)
  if (normalized %in% c("false", "f", "0", "no")) return(FALSE)
  stop("--", argument, " must be true or false.", call. = FALSE)
}

omix_limma_code_dir <- function() {
  candidates <- commandArgs(FALSE)[grepl("^--file=", commandArgs(FALSE))]
  if (length(candidates) == 0L) return(getwd())
  dirname(normalizePath(sub("^--file=", "", candidates[[1L]]), mustWork = TRUE))
}

omix_limma_data_roots <- function(code_dir) {
  configured <- getOption("omix.limma.data_roots")
  roots <- if (is.null(configured)) {
    c("/data", file.path(dirname(code_dir), "data"))
  } else {
    as.character(configured)
  }
  unique(roots[dir.exists(roots)])
}

omix_limma_output_dir <- function(requested = "", code_dir = getwd()) {
  if (!is.null(requested) && length(requested) == 1L && !is.na(requested) &&
      nzchar(trimws(requested))) {
    return(requested)
  }
  if (dir.exists("/results")) "/results" else file.path(dirname(code_dir), "results")
}

omix_limma_validate_file <- function(path, label, extensions) {
  if (!is.character(path) || length(path) != 1L || is.na(path) || !nzchar(trimws(path))) {
    stop(label, " must be one non-empty path.", call. = FALSE)
  }
  if (!file.exists(path)) stop(label, " was not found: ", path, call. = FALSE)
  if (dir.exists(path)) stop(label, " must be a file, not a directory: ", path, call. = FALSE)
  extension <- tolower(tools::file_ext(path))
  if (!extension %in% extensions) {
    stop(
      label, " must use one of these extensions: ",
      paste(extensions, collapse = ", "), ". Observed: ", path,
      call. = FALSE
    )
  }
  normalizePath(path, mustWork = TRUE)
}

omix_limma_read_table <- function(path) {
  extension <- tolower(tools::file_ext(path))
  if (extension == "rds") {
    object <- readRDS(path)
    if (is.matrix(object)) return(as.data.frame(object, check.names = FALSE))
    if (is.data.frame(object)) return(as.data.frame(object, check.names = FALSE))
    stop("RDS input must contain a data frame or matrix: ", path, call. = FALSE)
  }
  if (extension == "csv") {
    return(utils::read.csv(path, check.names = FALSE, stringsAsFactors = FALSE))
  }
  if (extension %in% c("tsv", "txt")) {
    return(utils::read.delim(path, check.names = FALSE, stringsAsFactors = FALSE))
  }
  stop("Unsupported table extension: ", path, call. = FALSE)
}

omix_limma_candidate_files <- function(code_dir, extensions = c("csv", "tsv", "txt", "rds")) {
  roots <- omix_limma_data_roots(code_dir)
  candidates <- unlist(lapply(roots, function(root) {
    list.files(root, recursive = TRUE, full.names = TRUE, include.dirs = FALSE)
  }), use.names = FALSE)
  candidates <- candidates[tolower(tools::file_ext(candidates)) %in% extensions]
  if (length(candidates) == 0L) return(character())
  sort(unique(normalizePath(candidates, mustWork = TRUE)))
}

omix_limma_safe_table <- function(path) {
  tryCatch(omix_limma_read_table(path), error = function(error) NULL)
}

omix_limma_is_matrix_candidate <- function(path, gene_names_column) {
  table <- omix_limma_safe_table(path)
  if (is.null(table) || !gene_names_column %in% names(table) || ncol(table) < 2L) return(FALSE)
  values <- table[, setdiff(names(table), gene_names_column), drop = FALSE]
  numeric_columns <- vapply(values, is.numeric, logical(1))
  any(numeric_columns) && all(numeric_columns)
}

omix_limma_is_metadata_candidate <- function(path, sample_names_column) {
  table <- omix_limma_safe_table(path)
  if (is.null(table) || !sample_names_column %in% names(table) || nrow(table) == 0L) return(FALSE)
  ids <- as.character(table[[sample_names_column]])
  !anyNA(ids) && all(nzchar(ids)) && !anyDuplicated(ids)
}

omix_limma_choose_one <- function(candidates, label, hint) {
  if (length(candidates) == 0L) {
    stop(
      "No compatible ", label, " was found under /data. ", hint,
      call. = FALSE
    )
  }
  if (length(candidates) > 1L) {
    stop(
      "Multiple compatible ", label, " candidates were found. Select one explicitly:\n- ",
      paste(candidates, collapse = "\n- "),
      call. = FALSE
    )
  }
  candidates[[1L]]
}

omix_limma_read_manifest <- function(path) {
  manifest <- base::read.dcf(path)
  if (nrow(manifest) != 1L) {
    stop("Pseudobulk manifest must contain exactly one record: ", path, call. = FALSE)
  }
  as.list(manifest[1L, , drop = TRUE])
}

omix_limma_manifest_value <- function(manifest, field) {
  if (is.null(manifest) || !field %in% names(manifest)) return("")
  trimws(as.character(manifest[[field]]))
}

omix_limma_resolve_manifest <- function(requested, code_dir) {
  if (!is.null(requested) && length(requested) == 1L && !is.na(requested) &&
      nzchar(trimws(requested))) {
    return(omix_limma_validate_file(requested, "Selected pseudobulk manifest", "dcf"))
  }
  roots <- omix_limma_data_roots(code_dir)
  candidates <- unlist(lapply(roots, function(root) {
    list.files(
      root,
      pattern = "^Pseudobulk_Manifest\\.dcf$",
      recursive = TRUE,
      full.names = TRUE,
      ignore.case = TRUE,
      include.dirs = FALSE
    )
  }), use.names = FALSE)
  candidates <- sort(unique(normalizePath(candidates, mustWork = TRUE)))
  if (length(candidates) == 0L) return("")
  if (length(candidates) > 1L) {
    stop(
      "Multiple Pseudobulk manifest candidates were found. Select one explicitly:\n- ",
      paste(candidates, collapse = "\n- "),
      call. = FALSE
    )
  }
  candidates[[1L]]
}

omix_limma_validate_manifest <- function(manifest, input_kind) {
  if (is.null(manifest)) return(invisible(NULL))
  matrix_type <- omix_limma_manifest_value(manifest, "matrix_type")
  if (identical(matrix_type, "raw_integer_counts")) {
    stop(
      "Pseudobulk_Manifest.dcf declares raw_integer_counts. Run OMIX-DEG-Analysis ",
      "in raw-count mode so edgeR TMM and limma-voom are used instead.",
      call. = FALSE
    )
  }
  supported <- c("harmony_corrected_mean_expression", "sctransform_mean_log2_expression")
  if (!matrix_type %in% supported) {
    stop("Unsupported Pseudobulk matrix_type for direct limma: ", matrix_type, call. = FALSE)
  }
  downstream_module <- omix_limma_manifest_value(manifest, "expected_downstream_module")
  if (nzchar(downstream_module) && !identical(downstream_module, "OMIX-Limma-Analysis")) {
    stop(
      "Pseudobulk manifest expects downstream module '", downstream_module,
      "', not OMIX-Limma-Analysis.", call. = FALSE
    )
  }
  downstream_mode <- omix_limma_manifest_value(manifest, "expected_downstream_mode")
  if (nzchar(downstream_mode) && !identical(downstream_mode, "continuous_expression")) {
    stop("Pseudobulk manifest does not declare a continuous-expression handoff.", call. = FALSE)
  }
  declared_input_kind <- omix_limma_manifest_value(manifest, "downstream_input_kind")
  if (nzchar(declared_input_kind) && !identical(declared_input_kind, input_kind)) {
    stop(
      "--input_kind ('", input_kind, "') does not match the pseudobulk manifest ('",
      declared_input_kind, "').", call. = FALSE
    )
  }
  invisible(NULL)
}

omix_limma_resolve_inputs <- function(
  matrix = "",
  metadata = "",
  pseudobulk_manifest = "",
  gene_names_column = "GeneName",
  sample_names_column = "Sample",
  input_kind = "log2_expression",
  code_dir = getwd()
) {
  manifest_path <- omix_limma_resolve_manifest(pseudobulk_manifest, code_dir)
  manifest <- if (nzchar(manifest_path)) omix_limma_read_manifest(manifest_path) else NULL
  omix_limma_validate_manifest(manifest, input_kind)

  table_files <- omix_limma_candidate_files(code_dir)

  matrix_path <- if (!is.null(matrix) && length(matrix) == 1L && !is.na(matrix) &&
                     nzchar(trimws(matrix))) {
    omix_limma_validate_file(matrix, "Selected continuous matrix", c("csv", "tsv", "txt", "rds"))
  } else {
    candidates <- table_files[vapply(
      table_files,
      omix_limma_is_matrix_candidate,
      logical(1),
      gene_names_column = gene_names_column
    )]
    matrix_type <- omix_limma_manifest_value(manifest, "matrix_type")
    preferred_name <- switch(
      matrix_type,
      harmony_corrected_mean_expression = "Harmony_Mean_Expression",
      sctransform_mean_log2_expression = "SCT_Mean_Log2_Expression",
      ""
    )
    if (nzchar(preferred_name)) {
      preferred <- candidates[grepl(preferred_name, basename(candidates), fixed = TRUE)]
      if (length(preferred) > 0L) candidates <- preferred
    }
    omix_limma_choose_one(
      candidates,
      "continuous matrix",
      "Upload it explicitly or attach one compatible continuous-expression asset."
    )
  }

  metadata_path <- if (!is.null(metadata) && length(metadata) == 1L && !is.na(metadata) &&
                       nzchar(trimws(metadata))) {
    omix_limma_validate_file(metadata, "Selected sample metadata", c("csv", "tsv", "txt", "rds"))
  } else {
    candidates <- table_files[vapply(
      table_files,
      omix_limma_is_metadata_candidate,
      logical(1),
      sample_names_column = sample_names_column
    )]
    preferred <- candidates[grepl(
      "^(Pseudobulk_)?Sample_Metadata\\.(csv|tsv|txt|rds)$",
      basename(candidates),
      ignore.case = TRUE
    )]
    if (length(preferred) > 0L) candidates <- preferred
    omix_limma_choose_one(
      candidates,
      "sample metadata table",
      "Upload it explicitly or attach one compatible metadata asset."
    )
  }

  matrix_table <- omix_limma_read_table(matrix_path)
  metadata_table <- omix_limma_read_table(metadata_path)
  if (!gene_names_column %in% names(matrix_table)) {
    stop("Feature ID column '", gene_names_column, "' was not found in the matrix.", call. = FALSE)
  }
  if (!sample_names_column %in% names(metadata_table)) {
    stop("Sample ID column '", sample_names_column, "' was not found in metadata.", call. = FALSE)
  }
  overlap <- intersect(
    as.character(metadata_table[[sample_names_column]]),
    names(matrix_table)
  )
  if (length(overlap) == 0L) {
    stop("No metadata sample IDs occur as columns in the continuous matrix.", call. = FALSE)
  }

  list(
    matrix_path = matrix_path,
    metadata_path = metadata_path,
    manifest_path = manifest_path,
    manifest = manifest,
    matrix = matrix_table,
    metadata = metadata_table
  )
}

omix_limma_resolve_variance_model <- function(requested, manifest) {
  requested <- tolower(trimws(requested))
  if (!requested %in% c("auto", "ebayes", "ebayes_trend")) {
    stop("--variance_model must be auto, ebayes, or ebayes_trend.", call. = FALSE)
  }
  recommended <- omix_limma_manifest_value(manifest, "recommended_variance_model")
  resolved <- if (identical(requested, "auto")) {
    if (recommended %in% c("ebayes", "ebayes_trend")) recommended else "ebayes"
  } else {
    requested
  }
  list(requested = requested, recommended = recommended, resolved = resolved)
}
