# Code Ocean App Panel normalization evidence

Date: 2026-10-15

Capsule: OMIX Limma Analysis (`8635652`)

## Finding

Code Ocean rejected the repository App Panel after the Interface 3 controls
were added. Rebuilding the four controls in the Code Ocean App Builder showed
that a floating-point input is serialized as a text control with numeric value
semantics:

```json
{
  "type": "text",
  "value_type": "number",
  "default_value": "0.0001"
}
```

The repository had used `"type": "number"` and a JSON numeric default. The
other three Interface 3 controls were accepted with their existing list or
text representations.

The platform-normalized JSON was downloaded from the held workstation result
snapshot and had SHA-256:

```text
7e3065c937570175946a46952fec2f7b2beba305dd7c4a152ce74d1a71e99d38
```

## Repair boundary

This adapter change updates only the Code Ocean representation of
`fraction_pseudocount`. It does not change the parameter name, numeric value
semantics, scientific default, adapter CLI, canonical scientific source, or
runtime image.

The App Panel test now asserts the platform-supported representation so that a
future schema refresh cannot silently restore the rejected form.

## Verification

- Code Ocean rendered all four Interface 3 controls: Input Data Type,
  Measurement Scale, Fraction Transform, and Fraction Pseudocount.
- Fraction Pseudocount rendered as a numeric stepper with value `0.0001`.
- The five declared result files were accepted by the App Builder.
- `bash tests/run-tests.sh` passed after the repository normalization.

## Post-merge synchronized capsule run

After pull requests 11 and 12 were merged, capsule `8635652` was synchronized
to adapter merge commit `96659ba573ee982daa33f974d17671e6fc9a11a0`. The
provisional App Builder edit was discarded before synchronization, so this run
exercised the repository-owned App Panel rather than a capsule-local copy.

Code Ocean run `2119697` completed on 2026-10-15 in five seconds with the same
deterministic SCTransform pseudobulk fixture used for the recorded interface-3
equivalence check. The run summary recorded:

- requested input data type `auto`;
- resolved input data type `sctransform_mean_expression`, sourced from the
  pseudobulk manifest;
- resolved input kind `log2_expression`;
- requested fraction transform `auto`, resolved to `none` for this non-fraction
  matrix;
- requested variance model `auto`;
- recommended and applied variance model `ebayes_trend`, sourced from the
  pseudobulk manifest;
- repeated-measures model; and
- explicit and resolved contrast `B-A`.

The synchronized capsule emitted all five declared artifacts:

- `Limma_Analysis.csv`;
- `Sample_Metadata.csv`;
- `run_summary.txt`;
- `Variance_Diagnostic.csv`; and
- `variance_diagnostic.png`.

The run log ended with `Wrote OMIX Limma Analysis results to /results`. This
post-merge run closes the App Panel schema-acceptance boundary identified in
the earlier interface-3 equivalence record. It does not create or imply an
adapter tag, Code Ocean release, or new runtime publication.

## Standard Capsule release

After this evidence was merged, source capsule `8635652` was synchronized to
merge commit `ae0a0b4cd52ce13573e093e80fc5615046410209`. Code Ocean required a
fresh run because the capsule state had changed, even though the final change
was evidence documentation only.

Run `2121757` completed successfully in four seconds and emitted the same five
declared artifacts. With explicit release authorization, that run produced
immutable Standard Capsule release
[`3.0`](https://poc-nci.codeocean.io/capsule/ffab7e89-72c4-4271-b888-b02a1e06db7c/tree/v3)
on 2026-10-15. The release action did not create an adapter Git tag or publish
a runtime container.
