# Agent install prompt

Paste the block below into Claude Code, Codex, or any coding agent that can run shell commands. It makes the agent read the installer before running it and ask you before it installs anything.

## English

```text
Install the "qera4mgln" agent skill from https://github.com/4mGLn/qera4mgln for me.

Follow these steps in order and do not skip any:
1. Download the installer to a file (do NOT pipe it into a shell):
   curl -fsSLo ./qera4mgln-install.sh https://raw.githubusercontent.com/4mGLn/qera4mgln/main/install.sh
2. Read the file. Summarize in 3 bullets what it will do and flag anything that
   writes outside ~/.claude/skills, ~/.agents/skills or a temp directory.
3. Run: bash ./qera4mgln-install.sh --dry-run   and show me the output.
4. If it reports missing packages, show me the exact command it would run and WAIT for
   my explicit approval. Never use sudo or --yes without that approval.
5. After I approve, run: bash ./qera4mgln-install.sh --test
   (user level: ~/.claude/skills and ~/.agents/skills. Add `--claude` or `--agents` to
   limit it, or `--project .` to install into the current project.)
6. Report the real output. Say the install succeeded only if the command exited 0 and
   printed "Smoke check: OK". If anything failed, show the error and stop; do not work
   around it by editing files or fetching from other sources.
7. Tell me to start a new session so the skill is loaded, then delete ./qera4mgln-install.sh.
```

## 한국어

```text
https://github.com/4mGLn/qera4mgln 의 "qera4mgln" 에이전트 스킬을 설치해 줘.

아래 순서를 건너뛰지 말고 따라 줘:
1. 설치 스크립트를 파일로 내려받아 (셸로 바로 파이프하지 말 것):
   curl -fsSLo ./qera4mgln-install.sh https://raw.githubusercontent.com/4mGLn/qera4mgln/main/install.sh
2. 파일을 읽고 하는 일을 3줄로 요약해 줘. ~/.claude/skills, ~/.agents/skills, 임시 폴더
   밖에 쓰는 동작이 있으면 알려 줘.
3. bash ./qera4mgln-install.sh --dry-run 을 실행하고 출력을 보여 줘.
4. 누락된 패키지가 있다고 나오면 실행될 정확한 명령을 보여 주고, 내가 명시적으로
   승인할 때까지 기다려 줘. 내 승인 없이 sudo나 --yes를 쓰지 마.
5. 승인하면 bash ./qera4mgln-install.sh --test 를 실행해 줘.
   (기본은 사용자 레벨 ~/.claude/skills 와 ~/.agents/skills. --claude / --agents 로
   한쪽만, --project . 로 현재 프로젝트에 설치할 수 있어.)
6. 실제 출력을 그대로 보고해 줘. 종료 코드가 0이고 "Smoke check: OK"가 나왔을 때만
   성공이라고 말해. 실패하면 오류를 보여 주고 멈춰. 파일을 직접 고치거나 다른 출처에서
   받아서 우회하지 마.
7. 스킬이 로드되도록 새 세션을 시작하라고 알려 주고, ./qera4mgln-install.sh 는 삭제해 줘.
```

## Notes

- The installer never installs system packages without approval: it lists them, prints the exact command, and asks (through `/dev/tty` even when piped). `--yes` is your explicit approval for unattended use.
- It refuses to overwrite an existing install unless you pass `--force` (the old copy is kept as `*.bak-<timestamp>`).
- Uninstall: `bash ./qera4mgln-install.sh --uninstall` (asks first).
