#!/usr/bin/env python3

import json
import re
from pathlib import Path


panel_path = Path(".codeocean/app-panel.json")
panel_text = panel_path.read_text()
panel = json.loads(panel_text)

assert panel["named_parameters"] is True
assert "help_text" not in panel_text
# A workflow-ready capsule declares the same representative bundle both as an
# attached `/data` mount and as a visible, replaceable workflow input node.
datasets = json.loads(Path(".codeocean/datasets.json").read_text())
assert panel["datasets"] == [
    {"id": "3766a754-c931-4ff7-9e7b-83ffb64e7ea8", "name": "Pseudobulk Expression Bundle"}
]
assert [item["id"] for item in panel["datasets"]] == [
    item["id"] for item in datasets["attached_datasets"]
]

parameters = panel["parameters"]
names = [parameter.get("param_name") for parameter in parameters]
expected = [
    "matrix",
    "metadata",
    "pseudobulk_manifest",
    "gene_names_column",
    "sample_names_column",
    "contrast_variable_columns",
    "contrasts",
    "covariate_columns",
    "donor_variable_column",
    "input_data_type",
    "input_kind",
    "measurement_scale",
    "fraction_transform",
    "fraction_pseudocount",
    "variance_model",
    "summarization_method",
    "samples_to_include",
    "return_matrix",
]
assert names == expected, (names, expected)
assert len(names) == len(set(names))

main_text = Path("code/main.R").read_text()
cli_names = set(re.findall(r'make_option\("--([a-z0-9_]+)"', main_text))
assert cli_names == set(expected) | {"output_dir"}, sorted(cli_names)

by_name = {parameter["param_name"]: parameter for parameter in parameters}
expected_defaults = {
    "gene_names_column": "GeneName",
    "sample_names_column": "Sample",
    "contrast_variable_columns": "Group",
    "contrasts": "",
    "covariate_columns": "",
    "donor_variable_column": "",
    "input_data_type": "auto",
    "input_kind": "auto",
    "measurement_scale": "",
    "fraction_transform": "auto",
    "fraction_pseudocount": "0.0001",
    "variance_model": "auto",
    "summarization_method": "mean",
    "samples_to_include": "",
    "return_matrix": "true",
}
for name, default in expected_defaults.items():
    # Code Ocean omits empty-string defaults when it normalizes text fields.
    # An omitted optional text default and an explicit empty default both map
    # to the same blank CLI value.
    actual = by_name[name].get("default_value", "" if default == "" else None)
    assert actual == default, (
        name,
        actual,
    )

for name in ["matrix", "metadata", "pseudobulk_manifest"]:
    assert by_name[name]["type"] == "file"
assert "required" not in by_name["contrasts"]
assert "default_value" not in by_name["contrasts"]
assert by_name["input_kind"]["extra_data"] == [
    "auto",
    "log2_expression",
    "enrichment_score",
    "continuous_score",
]
assert by_name["input_data_type"]["extra_data"] == [
    "auto",
    "microarray_log2_expression",
    "normalized_bulk_expression",
    "log2_cpm_without_voom_weights",
    "sctransform_mean_expression",
    "harmony_corrected_mean_expression",
    "gsva_enrichment_scores",
    "cibersort_relative_fractions",
    "cibersort_absolute_scores",
    "methylation_m_values",
    "normalized_proteomics",
    "normalized_metabolomics",
    "qpcr_delta_ct",
    "copy_number_log2_ratios",
    "normalized_chromatin_accessibility",
    "normalized_crispr_scores",
    "other_continuous",
]
assert by_name["fraction_transform"]["extra_data"] == [
    "auto",
    "none",
    "arcsin_sqrt",
    "logit",
]
assert by_name["fraction_pseudocount"]["type"] == "text"
assert by_name["fraction_pseudocount"]["value_type"] == "number"
assert by_name["variance_model"]["extra_data"] == [
    "auto",
    "ebayes",
    "ebayes_trend",
]
assert by_name["summarization_method"]["extra_data"] == ["mean", "max", "sum"]
assert by_name["return_matrix"]["extra_data"] == ["true", "false"]
assert "output_dir" not in names

result_names = [result["file_name"] for result in panel["results"]]
assert result_names == [
    "Limma_Analysis.csv",
    "Sample_Metadata.csv",
    "run_summary.txt",
    "Variance_Diagnostic.csv",
    "variance_diagnostic.png",
]

environment = json.loads(Path(".codeocean/environment.json").read_text())
assert environment["base_image"] == "codeocean/omix-r-statistics:r4.4.3-bioconductor3.20-v1"
assert ":latest" not in environment["base_image"]

print("OMIX Limma Analysis App Panel and runtime bindings passed")
