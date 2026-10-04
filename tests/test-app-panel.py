#!/usr/bin/env python3

import json
import re
from pathlib import Path


panel_path = Path(".codeocean/app-panel.json")
panel_text = panel_path.read_text()
panel = json.loads(panel_text)

assert panel["named_parameters"] is True
assert "help_text" not in panel_text
# Code Ocean removes an empty top-level datasets array when it normalizes the
# App Panel. Attached data assets are recorded separately in datasets.json, so
# an omitted key and an explicit empty array are equivalent here.
assert panel.get("datasets", []) == []

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
    "input_kind",
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
    "covariate_columns": "",
    "donor_variable_column": "",
    "input_kind": "log2_expression",
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
assert by_name["contrasts"]["required"] is True
assert "default_value" not in by_name["contrasts"]
assert by_name["input_kind"]["extra_data"] == [
    "log2_expression",
    "enrichment_score",
    "continuous_score",
]
assert by_name["variance_model"]["extra_data"] == [
    "auto",
    "ebayes",
    "ebayes_trend",
]
assert by_name["summarization_method"]["extra_data"] == ["mean", "max", "sum"]
assert by_name["return_matrix"]["extra_data"] == ["true", "false"]
assert "output_dir" not in names

environment = json.loads(Path(".codeocean/environment.json").read_text())
assert environment["base_image"] == "codeocean/omix-r-statistics:r4.4.3-bioconductor3.20-v1"
assert ":latest" not in environment["base_image"]

print("OMIX Limma Analysis App Panel and runtime bindings passed")
