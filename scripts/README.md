# Scripts

Thin, sanitized helpers. They wrap the same commands the CI pipelines run, so you can
reproduce the gates locally before opening a PR. Placeholders (`REPLACE_*`, RFC 5737
documentation addresses) must be adapted to your environment.

> The deliverable is Terraform, so the toolchain is OpenTofu/Terraform — not a container builder.
> `preflight.sh` accepts **either** engine (`tofu` preferred, `terraform` accepted); `validate.sh`
> runs `fmt -check -recursive` + `init -backend=false` + `validate` against the `terraform/` dir.

| Script | Purpose | Used by |
|---|---|---|
| [`build_docs.py`](build_docs.py) | Inject `docs/diagrams/src/*.mermaid` into the `START/END_GENERATED` blocks across README + all `docs/*.md` (DRY). | docs build |
| [`preflight.sh`](preflight.sh) | Verify the toolchain (python3 + an HCL engine) is present; print install hints. | `validate.sh` step 0 |
| [`validate.sh`](validate.sh) | `tofu/terraform fmt -check + validate`, the doc-sync check, and a secret scan of tracked files. | `validate` CI gate |

## Typical local loop

```bash
# after editing the deliverable or a doc
scripts/validate.sh                  # same gate CI runs
python3 scripts/build_docs.py        # if you touched a diagram source
```

## Notes

- `validate.sh` exits non-zero on any failure — wire it as a required status check.
- None of these apply anything to a live environment. Applying is the reconciler's job (or a
  deliberate, runbook-driven apply).
