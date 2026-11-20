# Changelog

## Unreleased — 2026-11-20
- Bind evaluation results to task inputs, effective prompts/implementation, models, endpoints, temperature and judge context. Resume preflights before calls; reports reject stale/mixed results and mismatched rubric counts. Legacy results without fingerprints require a new results file.
- Detect missing, duplicate and malformed CHECK entries against requirement/need IDs. Return `check_incomplete` without repair when coverage is incomplete, while retaining deterministic measurements.
- Reject repairs that introduce a minimum-word violation or worsen an existing one, including short drafts and contracts with maximum-word limits.
- Add regression coverage for the above, preserving matching-run resume, added repeats, offline reporting and credential rotation.

## 1.0.0
- Skill `qera4mgln`: ASK -> ANSWER -> CHECK -> guarded REPAIR workflow, stdlib-only helpers (`filter`, `measure`, `audit`, `guard`), optional text-only OpenAI-compatible runner.
- Prompts aligned to the paper's six-rule answer protocol; host safety rules separated into `safety.txt`.
- A/B evaluation harness (`qera_eval.py`): direct vs QERA arms, rubric judge (rubrics + response only by default), `--repeats`, paired bootstrap and sign test, resumable.
- `clbench_convert.py` (CL-bench-Life converter with `<|TASK|>` request split) and `qera_rubric_lint.py` (explicit/implicit rubric share; 82.4% on CL-bench-Life vs the paper's 82%).
- HTTP adapter hardening: no redirects, clean timeout errors, key never in error text; judge key not reused across hosts; strict judge verdict parsing.
- `install.sh` (curl-friendly; approval before any package install) and `INSTALL_PROMPT.md`.
- Not done: no run against a real model provider; no benchmark score is claimed.
