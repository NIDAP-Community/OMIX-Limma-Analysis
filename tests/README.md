# Adapter validation

Run all local contract checks from the repository root:

```bash
bash tests/run-tests.sh
```

These checks cover syntax, attached-input discovery, raw-count rejection,
SCT-manifest variance routing, output names, App Panel coverage/defaults, and
the managed scientific file hash. Code Ocean validation is recorded separately
and is not implied by local success.
