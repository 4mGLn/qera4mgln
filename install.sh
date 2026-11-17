#!/usr/bin/env bash
# qera4mgln installer: installs the qera4mgln Agent Skill for Claude Code, Codex and other
# `.agents/skills`-aware agents.
#
#   curl -fsSL https://raw.githubusercontent.com/4mGLn/qera4mgln/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/4mGLn/qera4mgln/main/install.sh | bash -s -- --dry-run
#
# Safer: download, read, then run:   curl -fsSLo install.sh <url>; less install.sh; bash install.sh
#
# Nothing is installed on your system (packages included) without your approval:
# missing tools are listed with the exact command, and you are asked first (via /dev/tty
# when piped). `--yes` is your explicit approval for non-interactive use.
set -euo pipefail

REPO="${QERA4MGLN_REPO:-4mGLn/qera4mgln}"
NAME="qera4mgln"
REF="main"
FROM=""
YES=0; FORCE=0; DRY=0; UNINSTALL=0; RUNTESTS=0; VERIFY=1
WANT_CLAUDE=0; WANT_AGENTS=0
DESTS=()      # explicit --dest / --project targets (skills directories)

usage() {
  cat <<EOF
Usage: install.sh [options]
  (default)           install to ~/.claude/skills/$NAME and ~/.agents/skills/$NAME
  --claude            only ~/.claude/skills/$NAME
  --agents            only ~/.agents/skills/$NAME  (Codex and other .agents/skills clients)
  --project PATH      install into PATH/.claude/skills and PATH/.agents/skills
  --dest DIR          install into DIR/$NAME (DIR is a skills directory); repeatable
  --ref REF           git branch, tag or commit to install (default: $REF)
  --from DIR          install from a local checkout instead of downloading
  --force             replace an existing install (old one is moved to *.bak-<timestamp>)
  --uninstall         remove the installed skill from the selected targets
  --test              also run the bundled unit tests after installing (a few seconds)
  --no-verify         skip the post-install smoke check
  --dry-run           show what would happen; change nothing (not even packages)
  --yes, -y           approve package installation and removal without prompting
  -h, --help          this help
Exit codes: 0 ok, 2 bad usage, 3 target exists (use --force), 4 approval needed,
            5 missing dependency not installed, 6 integrity/verification failure.
EOF
}

die() { printf 'qera4mgln: %s\n' "$*" >&2; exit "${2:-1}"; }
say() { printf '%s\n' "$*"; }

while [ $# -gt 0 ]; do
  case "$1" in
    --claude) WANT_CLAUDE=1 ;;
    --agents) WANT_AGENTS=1 ;;
    --project) [ $# -ge 2 ] || die "--project needs a path" 2; shift
               [ -d "$1" ] || die "project directory not found: $1" 2
               p="$(cd "$1" && pwd)"; DESTS+=("$p/.claude/skills" "$p/.agents/skills") ;;
    --dest)    [ $# -ge 2 ] || die "--dest needs a directory" 2; shift; DESTS+=("$1") ;;
    --ref)     [ $# -ge 2 ] || die "--ref needs a value" 2; shift; REF="$1" ;;
    --from)    [ $# -ge 2 ] || die "--from needs a directory" 2; shift
               [ -d "$1" ] || die "--from directory not found: $1" 2; FROM="$(cd "$1" && pwd)" ;;
    --force) FORCE=1 ;;
    --uninstall) UNINSTALL=1 ;;
    --test) RUNTESTS=1 ;;
    --no-verify) VERIFY=0 ;;
    --dry-run) DRY=1 ;;
    --yes|-y) YES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; die "unknown option: $1" 2 ;;
  esac
  shift
done

case "$REF" in *[!A-Za-z0-9._/-]*|"") die "invalid --ref: $REF" 2 ;; esac

TARGETS=()
if [ ${#DESTS[@]} -eq 0 ]; then
  [ $WANT_CLAUDE -eq 1 ] || [ $WANT_AGENTS -eq 1 ] || { WANT_CLAUDE=1; WANT_AGENTS=1; }
  [ $WANT_CLAUDE -eq 1 ] && TARGETS+=("$HOME/.claude/skills/$NAME")
  [ $WANT_AGENTS -eq 1 ] && TARGETS+=("$HOME/.agents/skills/$NAME")
else
  for d in "${DESTS[@]}"; do TARGETS+=("$d/$NAME"); done
  [ $WANT_CLAUDE -eq 1 ] && TARGETS+=("$HOME/.claude/skills/$NAME")
  [ $WANT_AGENTS -eq 1 ] && TARGETS+=("$HOME/.agents/skills/$NAME")
fi

# ---- approval helper: reads from the terminal even when the script is piped ----------
have_tty() { { : </dev/tty; } 2>/dev/null; }
ask() {  # ask "question" -> 0 if approved
  [ $YES -eq 1 ] && return 0
  if have_tty; then
    printf '%s [y/N] ' "$1" >/dev/tty
    local a=""; read -r a </dev/tty || a=""
    case "$a" in y|Y|yes|YES) return 0 ;; esac
    return 1
  fi
  return 4
}
need_approval() {  # need_approval "question" ; exits 4 when no tty and no --yes
  local rc=0; ask "$1" || rc=$?
  if [ $rc -eq 4 ]; then die "approval required but no terminal available; rerun with --yes to approve" 4; fi
  return $rc
}

# ---- uninstall -----------------------------------------------------------------------
if [ $UNINSTALL -eq 1 ]; then
  for t in "${TARGETS[@]}"; do
    if [ ! -e "$t" ]; then say "not installed: $t"; continue; fi
    grep -q "^name: $NAME\$" "$t/SKILL.md" 2>/dev/null || die "refusing to remove $t: not a $NAME skill directory" 6
    if [ $DRY -eq 1 ]; then say "[dry-run] would remove $t"; continue; fi
    if need_approval "Remove $t ?"; then rm -rf -- "$t"; say "removed: $t"; else say "kept: $t"; fi
  done
  exit 0
fi

# ---- dependency check (with approval) ------------------------------------------------
have() { command -v "$1" >/dev/null 2>&1; }
py_ok() { have python3 && python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3,10) else 1)' 2>/dev/null; }

MISSING=()          # human-readable names
PKGS=()             # package-manager package names
PM=""
for pm in apt-get dnf yum pacman zypper apk brew; do have "$pm" && { PM="$pm"; break; }; done

pkg_for() {  # pkg_for <tool>
  case "$PM:$1" in
    apt-get:python3|dnf:python3|yum:python3|zypper:python3|apk:python3|brew:python3) echo python3 ;;
    pacman:python3) echo python ;;
    brew:curl) echo curl ;;
    *:curl) echo curl ;;
    *:tar) echo tar ;;
    brew:sha256) echo coreutils ;;
    *:sha256) echo coreutils ;;
    *) echo "" ;;
  esac
}
add_missing() { MISSING+=("$1"); local p; p="$(pkg_for "$2")"; [ -n "$p" ] && PKGS+=("$p"); return 0; }

[ -n "$FROM" ] || have curl || have wget || add_missing "curl (or wget)" curl
have tar || add_missing "tar" tar
have sha256sum || have shasum || add_missing "sha256sum/shasum" sha256
if ! py_ok; then
  if have python3; then
    say "note: python3 is older than 3.10; the bundled scripts need Python 3.10+. The skill text still installs."
  else
    add_missing "python3 (>=3.10, for the bundled scripts)" python3
  fi
fi

if [ ${#MISSING[@]} -gt 0 ]; then
  say "Missing: ${MISSING[*]}"
  if [ -z "$PM" ] || [ ${#PKGS[@]} -eq 0 ]; then
    die "cannot determine a package manager for these; install them yourself and rerun" 5
  fi
  SUDO=""; [ "$(id -u)" -ne 0 ] && [ "$PM" != brew ] && SUDO="sudo "
  case "$PM" in
    apt-get) CMD="${SUDO}apt-get install -y ${PKGS[*]}" ;;
    dnf|yum) CMD="${SUDO}$PM install -y ${PKGS[*]}" ;;
    pacman)  CMD="${SUDO}pacman -S --needed --noconfirm ${PKGS[*]}" ;;
    zypper)  CMD="${SUDO}zypper install -y ${PKGS[*]}" ;;
    apk)     CMD="${SUDO}apk add ${PKGS[*]}" ;;
    brew)    CMD="brew install ${PKGS[*]}" ;;
  esac
  say "Command that would run: $CMD"
  if [ $DRY -eq 1 ]; then
    say "[dry-run] packages not installed"
  else
    if need_approval "Install the missing packages with the command above?"; then
      [ -z "$SUDO" ] || have sudo || die "sudo not found; run as root or install manually: $CMD" 5
      # shellcheck disable=SC2086
      $CMD || die "package installation failed: $CMD" 5
    else
      die "required packages not installed; aborting (nothing was changed)" 5
    fi
  fi
fi

# ---- fetch source --------------------------------------------------------------------
WORK="$(mktemp -d "${TMPDIR:-/tmp}/qera4mgln.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
SRC=""
if [ -n "$FROM" ]; then
  [ -d "$FROM/skills/$NAME" ] || die "no skills/$NAME in $FROM" 2
  SRC="$FROM/skills/$NAME"
else
  URL="https://codeload.github.com/$REPO/tar.gz/$REF"
  say "Downloading $URL"
  if [ $DRY -eq 1 ] && ! have curl && ! have wget; then say "[dry-run] skipping download"; exit 0; fi
  if have curl; then curl -fsSL --proto '=https' --tlsv1.2 -o "$WORK/src.tgz" "$URL" || die "download failed: $URL" 6
  else wget -q --https-only -O "$WORK/src.tgz" "$URL" || die "download failed: $URL" 6; fi
  # Downloaded content is untrusted: reject absolute or parent-relative member paths, extract into an empty dir.
  if tar -tzf "$WORK/src.tgz" | grep -Eq '(^/|(^|/)\.\.(/|$))'; then die "archive has unsafe paths; aborting" 6; fi
  mkdir "$WORK/x"; tar -xzf "$WORK/src.tgz" -C "$WORK/x"
  SRC="$(find "$WORK/x" -maxdepth 3 -type d -path "*/skills/$NAME" | head -n 1)"
  [ -n "$SRC" ] || die "skills/$NAME not found in the downloaded archive" 6
fi

# ---- integrity ----------------------------------------------------------------------
grep -q "^name: $NAME\$" "$SRC/SKILL.md" || die "SKILL.md name does not match '$NAME'" 6
if [ -f "$SRC/MANIFEST.sha256" ]; then
  if have sha256sum; then (cd "$SRC" && sha256sum -c --quiet MANIFEST.sha256) || die "MANIFEST check failed" 6
  elif have shasum; then (cd "$SRC" && shasum -a 256 -c --quiet MANIFEST.sha256) || die "MANIFEST check failed" 6
  fi
  say "Integrity: MANIFEST.sha256 OK (guards against corruption; it is hosted with the code, so it is not independent proof of authorship)"
else
  die "MANIFEST.sha256 missing; refusing to install" 6
fi

# ---- install ------------------------------------------------------------------------
TS="$(date +%Y%m%d%H%M%S)"
INSTALLED=()
for t in "${TARGETS[@]}"; do
  if [ -e "$t" ] || [ -L "$t" ]; then
    if [ $FORCE -ne 1 ]; then say "exists, not overwriting: $t  (use --force; the old copy is kept as a backup)"; exit 3; fi
    if [ $DRY -eq 1 ]; then say "[dry-run] would back up $t -> $t.bak-$TS and reinstall"; continue; fi
    mv -- "$t" "$t.bak-$TS"; say "backup: $t.bak-$TS"
  elif [ $DRY -eq 1 ]; then say "[dry-run] would install to $t"; continue; fi
  mkdir -p -- "$(dirname -- "$t")"
  tmp="$t.tmp.$$"; rm -rf -- "$tmp"; cp -R -- "$SRC" "$tmp"
  find "$tmp" -name __pycache__ -prune -exec rm -rf {} + 2>/dev/null || true
  mv -- "$tmp" "$t"; INSTALLED+=("$t"); say "installed: $t"
done
[ $DRY -eq 1 ] && { say "[dry-run] done; nothing was changed"; exit 0; }

# ---- verify -------------------------------------------------------------------------
if [ $VERIFY -eq 1 ] && py_ok && [ ${#INSTALLED[@]} -gt 0 ]; then
  first="${INSTALLED[0]}"
  PYTHONDONTWRITEBYTECODE=1 python3 "$first/scripts/qera.py" demo >/dev/null || die "smoke check failed (qera.py demo)" 6
  say "Smoke check: OK (qera.py demo)"
  if [ $RUNTESTS -eq 1 ]; then
    PYTHONDONTWRITEBYTECODE=1 python3 -W ignore -m unittest discover -s "$first/tests" >/dev/null 2>&1 \
      || die "unit tests failed in $first" 6
    say "Unit tests: OK"
  fi
fi

say ""
say "Done. Start a new agent session so it picks up the '$NAME' skill."
say "Optional text-only API runner needs QERA_API_BASE / QERA_MODEL / QERA_API_KEY (see README)."
