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

