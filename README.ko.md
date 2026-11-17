# qera4mgln

QERA 논문의 **ASK → ANSWER → CHECK → GUARDED REPAIR** 절차를 적용하는 이식 가능한 [Agent Skill](https://agentskills.io/specification)입니다. 표준 라이브러리만 쓰는 Python 도우미, 선택형 텍스트 전용 API 러너, A/B 평가 하네스가 들어 있습니다. Claude Code, Codex 등 `.agents/skills`를 읽는 에이전트에서 쓸 수 있습니다. English: [README.md](README.md)

> **상태: 성능 미검증.** QERA에서 *영감을 받은* 독립 구현이며 논문 저자의 코드가 아닙니다. 프롬프트는 논문 본문을 바탕으로 재구성한 것이고 원문 그대로가 아닙니다. **논문의 이득이 재현되는지는 아직 측정하지 않았습니다.** 직접 확인할 수 있도록 평가 하네스를 넣었습니다. [상태와 한계](#상태와-한계)를 보세요.

논문: Qi 외, *Ask Before You Answer: A Question-Driven Evidence Reasoning Architecture (QERA) for In-Context Learning*, [arXiv:2610.35083v2](https://arxiv.org/html/2610.35083v2).

## 설치

한 줄 설치(사용자 레벨: `~/.claude/skills`, `~/.agents/skills`):

```bash
curl -fsSL https://raw.githubusercontent.com/4mGLn/qera4mgln/main/install.sh | bash
```

먼저 미리보기(아무것도 바꾸지 않음):

```bash
curl -fsSL https://raw.githubusercontent.com/4mGLn/qera4mgln/main/install.sh | bash -s -- --dry-run
```

더 안전한 2단계(스크립트를 읽고 나서 실행):

```bash
curl -fsSLo install.sh https://raw.githubusercontent.com/4mGLn/qera4mgln/main/install.sh
less install.sh
bash install.sh --test
```

설치 후 새 에이전트 세션을 시작해야 스킬이 로드됩니다.

| 옵션 | 동작 |
|---|---|
| `--claude` / `--agents` | `~/.claude/skills`만 / `~/.agents/skills`만(Codex 등) |
| `--project PATH` | `PATH/.claude/skills`와 `PATH/.agents/skills`에 설치 |
| `--dest DIR` | `DIR/qera4mgln`에 설치(여러 번 지정 가능) |
| `--ref REF` | 설치할 브랜치·태그·커밋(기본 `main`, 재현성을 위해 태그 고정 권장) |
| `--from DIR` | 로컬 체크아웃에서 설치(다운로드 없음) |
| `--force` | 기존 설치 교체(이전 것은 `*.bak-<시각>`으로 보관) |
| `--test` | 설치 후 번들 단위 테스트 실행 |
| `--uninstall` | 설치된 스킬 제거(먼저 확인) |
| `--dry-run` | 할 일만 보여 줌. 패키지 설치 포함 아무것도 바꾸지 않음 |
| `--yes` | 패키지 설치·제거를 묻지 않고 승인 |

**패키지는 승인 없이 설치하지 않습니다.** 설치에는 `tar`, `sha256sum`/`shasum`, `curl` 또는 `wget`, `python3 >= 3.10`(번들 스크립트용)이 필요합니다. 빠진 것이 있으면 패키지 관리자의 정확한 명령을 보여 주고 승인을 묻습니다(`/dev/tty`를 쓰므로 파이프로 실행해도 됩니다). 터미널이 없고 `--yes`도 없으면 아무것도 바꾸지 않고 종료 코드 4로 끝납니다.

**신뢰 관련 주의.** `curl | bash`는 URL이 주는 내용을 그대로 실행합니다. 설치 스크립트는 내려받은 스킬을 `MANIFEST.sha256`으로 검증하지만, 이는 파일 손상 방지용이며 코드와 같은 곳에 있어 작성자의 독립 증명은 아닙니다. 중요하면 `--ref`로 태그를 고정하고 스크립트를 먼저 읽으세요.

### 에이전트에게 설치시키기

[INSTALL_PROMPT.md](INSTALL_PROMPT.md)의 프롬프트(영어·한국어)를 붙여 넣으세요. 에이전트가 설치 스크립트를 내려받아 읽고, dry-run을 하고, **패키지를 설치하기 전에 먼저 묻도록** 되어 있습니다. 요약본:

```text
https://github.com/4mGLn/qera4mgln 의 "qera4mgln" 스킬을 설치해 줘. install.sh는 셸로 파이프하지 말고
파일로 받아 읽고 요약한 뒤 --dry-run으로 실행해. 패키지 설치나 sudo 전에는 반드시 나에게 묻고,
그다음 --test로 실행해서 실제 출력을 보고해 줘.
```

## 사용

- **스킬로:** 스킬을 색인하는 에이전트가 `skills/qera4mgln/SKILL.md`를 읽고, 복합·정정이 많은·전수 조사형 요청에 절차를 적용합니다. 단순 요청은 바로 답합니다.
- **결정적 도우미**(네트워크 없음):
  ```bash
  S=~/.agents/skills/qera4mgln
  python3 $S/scripts/qera.py demo
  python3 $S/scripts/qera.py filter|measure|audit|guard --help
  ```
- **선택형 텍스트 전용 API 러너**(대화를 지정한 엔드포인트로 보냅니다. 도구는 실행하지 않습니다):
  ```bash
  export QERA_API_BASE=https://provider.example/v1 QERA_MODEL=... QERA_API_KEY=...
  python3 $S/scripts/qera.py run --conversation conv.json --mode adaptive --output out.json
  ```
- **A/B 평가**(직접 답변 대 QERA, rubric judge, paired bootstrap, `--repeats`): [`skills/qera4mgln/references/eval.md`](skills/qera4mgln/references/eval.md)를 보세요. 공개 CL-bench-Life 변환기와 rubric lint도 들어 있습니다. **데이터셋은 포함하지 않으며** 평가 전용 라이선스(학습·파인튜닝·증류 금지)이므로 Hugging Face에서 직접 받으세요.

## 상태와 한계

- 프롬프트는 논문이 설명한 절차(답변 6규칙, Ask/Check/Repair 구조, 필터·audit·guard 개념)를 따르지만 본문을 바탕으로 재구성했고 원문 그대로가 아닙니다.
- 오프라인 테스트 81개가 통과합니다(가짜 모델과 로컬 mock HTTP). **실제 모델 제공자로는 실행한 적이 없으며** 벤치마크 점수도 주장하지 않습니다.
- 논문은 이득이 주로 *암묵적* 요구에서 나온다고 보고합니다. 명시적 rubric이 대부분인 태스크 세트에서는 이점이 안 보일 수 있습니다. 논문은 CHECK/REPAIR 단계가 일부 설정에서 점수를 낮출 수 있다고도 보고합니다.
- 텍스트 답변만 다룹니다. 도구를 쓰는 에이전트 작업(파일, 셸, API)은 하네스가 채점하지 않습니다.
- Python 도우미는 인용 존재, 단순 산술, 텍스트 크기 가드 같은 좁은 관측 가능 속성만 검사하며 의미적 진실을 보장하지 않습니다. 샌드박스나 권한 계층이 아니므로 호스트 에이전트의 권한 규칙이 그대로 적용됩니다.

## 저장소 구성

```
install.sh                 설치 스크립트(curl | bash 지원)
INSTALL_PROMPT.md          에이전트에 붙여 넣는 설치 프롬프트
skills/qera4mgln/          스킬 본체(SKILL.md, scripts/, references/, assets/, tests/, MANIFEST.sha256)
tools/make-manifest.sh     스킬 수정 후 MANIFEST.sha256 재생성
.github/workflows/ci.yml   테스트 + manifest 점검
```

## 개발

```bash
python3 -W ignore -m unittest discover -s skills/qera4mgln/tests
tools/make-manifest.sh      # skills/qera4mgln 아래를 바꾼 뒤
```

## 라이선스

MIT([LICENSE](LICENSE)). 독립적으로 작성했으며 논문 저자와 무관하고 보증받은 것이 아닙니다. CL-bench-Life 데이터셋은 별도의 평가 전용 라이선스를 따릅니다.
