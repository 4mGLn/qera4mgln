# qera4mgln

A portable [Agent Skill](https://agentskills.io/specification) that applies the **ASK → ANSWER → CHECK → GUARDED REPAIR** pattern from the QERA paper, plus stdlib-only Python helpers, an optional text-only API runner, and an A/B evaluation harness. Works with Claude Code, Codex and other `.agents/skills`-aware agents. 한국어: [README.ko.md](README.ko.md)

> **Status: unvalidated.** This is an independent, QERA-*inspired* implementation. It is not the paper authors' code, and its prompts are reconstructed from the paper's text, not copied. **Nobody has measured here whether it matches the paper's gains**; the evaluation harness exists so you can check on your own data. See [Status and limits](#status-and-limits).

Paper: Qi et al., *Ask Before You Answer: A Question-Driven Evidence Reasoning Architecture (QERA) for In-Context Learning*, [arXiv:2610.35083v2](https://arxiv.org/html/2610.35083v2).

## Install

One line (user level: `~/.claude/skills` and `~/.agents/skills`):

```bash
curl -fsSL https://raw.githubusercontent.com/4mGLn/qera4mgln/main/install.sh | bash
```

Preview first, change nothing:

```bash
curl -fsSL https://raw.githubusercontent.com/4mGLn/qera4mgln/main/install.sh | bash -s -- --dry-run
```

Safer two-step (read the script, then run it):

```bash
curl -fsSLo install.sh https://raw.githubusercontent.com/4mGLn/qera4mgln/main/install.sh
less install.sh
bash install.sh --test
```

Then start a new agent session so the skill is loaded.

| Option | Effect |
|---|---|
| `--claude` / `--agents` | only `~/.claude/skills` / only `~/.agents/skills` (Codex etc.) |
| `--project PATH` | install into `PATH/.claude/skills` and `PATH/.agents/skills` |
| `--dest DIR` | install into `DIR/qera4mgln` (repeatable) |
| `--ref REF` | branch, tag or commit to install (default `main`; pin a tag for reproducibility) |
| `--from DIR` | install from a local checkout (no download) |
| `--force` | replace an existing install; the old one is kept as `*.bak-<timestamp>` |
| `--test` | run the bundled unit tests after installing |
| `--uninstall` | remove the installed skill (asks first) |
| `--dry-run` | show what would happen; changes nothing, not even packages |
| `--yes` | approve package installation/removal without prompting |

**Packages are never installed behind your back.** The installer needs `tar`, `sha256sum`/`shasum`, `curl` or `wget`, and `python3 >= 3.10` (for the bundled scripts). If something is missing it prints the exact package-manager command and asks for approval (through `/dev/tty`, so it also works when piped). With no terminal and no `--yes`, it exits with code 4 without changing anything.

**Trust note.** `curl | bash` runs whatever the URL serves. The installer verifies the downloaded skill against `MANIFEST.sha256`, which protects against corruption but is hosted with the code, so it is not independent proof of authorship. Pin `--ref` to a tag and read the script if that matters to you.

### Let your agent install it

Paste the prompt from [INSTALL_PROMPT.md](INSTALL_PROMPT.md) (English and Korean). It tells the agent to download and read the installer, dry-run it, and **ask you before installing any package**. Short version:

```text
Install the "qera4mgln" agent skill from https://github.com/4mGLn/qera4mgln: download install.sh
to a file (don't pipe to a shell), read and summarize it, run it with --dry-run, ask me before
installing any package or using sudo, then run it with --test and report the real output.
```

## Use

- **As a skill:** agents that index skills read `skills/qera4mgln/SKILL.md` and apply the workflow to complex, multi-part, correction-heavy or exhaustive requests. Trivial requests are answered directly.
- **Deterministic helpers** (no network):
  ```bash
  S=~/.agents/skills/qera4mgln
  python3 $S/scripts/qera.py demo
  python3 $S/scripts/qera.py filter|measure|audit|guard --help
  ```
- **Optional text-only API runner** (sends the conversation to the endpoint you configure; executes no tools):
  ```bash
  export QERA_API_BASE=https://provider.example/v1 QERA_MODEL=... QERA_API_KEY=...
  python3 $S/scripts/qera.py run --conversation conv.json --mode adaptive --output out.json
  ```
- **A/B evaluation** (direct answer vs QERA arms, rubric judge, paired bootstrap, `--repeats`): see [`skills/qera4mgln/references/eval.md`](skills/qera4mgln/references/eval.md). It also contains a converter for the public CL-bench-Life dataset and a rubric lint. **The dataset is not included** and is licensed for evaluation only (no training, fine-tuning or distillation); download it yourself from its Hugging Face page.

## Status and limits

- Prompts follow the paper's described protocol (six answer rules, Ask/Check/Repair structure, filter/audit/guard idea) but were reconstructed from the paper text; they are not verbatim.
- 81 offline tests pass (fake and local mock-HTTP models). **No run against a real model provider has been made**, and no benchmark score is claimed.
- The paper reports its gain mainly on *implicit* requirements; sets of mostly explicit rubrics may show no advantage. The paper also reports that the CHECK/REPAIR stages can lower scores on some settings.
- Text answers only: tool-using agent tasks (files, shell, APIs) are not scored by the harness.
- Python helpers check narrow observable properties (quote presence, simple arithmetic, text-size guards), not semantic truth. They are not a sandbox or an authorization layer: the host agent's own permission rules still apply.

## Repository layout

```
install.sh                 installer (curl | bash friendly)
INSTALL_PROMPT.md          copy-paste prompt for agents
skills/qera4mgln/          the skill (SKILL.md, scripts/, references/, assets/, tests/, MANIFEST.sha256)
tools/make-manifest.sh     regenerate MANIFEST.sha256 after editing the skill
.github/workflows/ci.yml   tests + manifest check
```

## Development

```bash
python3 -W ignore -m unittest discover -s skills/qera4mgln/tests
tools/make-manifest.sh      # after changing anything under skills/qera4mgln
```

## License

MIT (see [LICENSE](LICENSE)). Independently authored; not affiliated with or endorsed by the paper's authors. The CL-bench-Life dataset has its own evaluation-only license.
