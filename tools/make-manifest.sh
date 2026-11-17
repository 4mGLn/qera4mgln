#!/usr/bin/env bash
# Regenerate skills/qera4mgln/MANIFEST.sha256 (run after any change under skills/qera4mgln).
set -euo pipefail
cd "$(dirname "$0")/../skills/qera4mgln"
find . -type f ! -name MANIFEST.sha256 ! -path '*/__pycache__/*' -print0 | LC_ALL=C sort -z | xargs -0 sha256sum > MANIFEST.sha256
echo "wrote $(wc -l < MANIFEST.sha256) entries"
