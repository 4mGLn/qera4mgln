# Changelog

## 1.0.0
- Skill `qera4mgln`: ASK -> ANSWER -> CHECK -> guarded REPAIR workflow, stdlib-only helpers (`filter`, `measure`, `audit`, `guard`), optional text-only OpenAI-compatible runner.
- Prompts aligned to the paper's six-rule answer protocol; host safety rules separated into `safety.txt`.
- A/B evaluation harness (`qera_eval.py`): direct vs QERA arms, rubric judge (rubrics + response only by default), `--repeats`, paired bootstrap and sign test, resumable.
- `clbench_convert.py` (CL-bench-Life converter with `<|TASK|>` request split) and `qera_rubric_lint.py` (explicit/implicit rubric share; 82.4% on CL-bench-Life vs the paper's 82%).
- HTTP adapter hardening: no redirects, clean timeout errors, key never in error text; judge key not reused across hosts; strict judge verdict parsing.
- `install.sh` (curl-friendly; approval before any package install) and `INSTALL_PROMPT.md`.
- Not done: no run against a real model provider; no benchmark score is claimed.
