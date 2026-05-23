#!/usr/bin/env bash
#
# Regenerate src/README-preview.md — a committed, GitHub-browsable preview of
# src/README.md.jinja rendered with Copier's *default* answers (Odoo 19.0,
# Enterprise on). The .jinja stays the source of truth; this preview just makes
# the generated README readable on GitHub without running Copier.
#
# Usage:
#   scripts/render-readme.sh           regenerate src/README-preview.md in place
#   scripts/render-readme.sh --check   exit non-zero if the preview is stale
#                                      (used by CI; does not modify the tree)
#
# Copier renders the whole skeleton; we lift its rendered README.md out into the
# preview file. The preview's own name (README-preview.md) is _exclude'd in
# copier.yml so it never ships into generated projects.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

check=false
[[ "${1:-}" == "--check" ]] && check=true

if ! command -v copier >/dev/null 2>&1; then
  echo "error: copier not found. Install it, e.g.:" >&2
  echo "         pipx install copier   # or: uv tool install copier" >&2
  exit 2
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
out="$tmp/render"

# --defaults: no prompts; --trust: allow _message_after_copy etc.
# Copier is chatty (per-file progress, the post-copy message, and a
# DirtyLocalWarning when run against an uncommitted tree) — keep it quiet and
# only surface its output if the render actually fails.
if ! copier copy --defaults --trust . "$out" >"$tmp/copier.log" 2>&1; then
  cat "$tmp/copier.log" >&2
  echo "error: copier failed to render the template." >&2
  exit 1
fi

if "$check"; then
  if ! diff -u src/README-preview.md "$out/README.md"; then
    {
      echo
      echo "error: src/README-preview.md is out of date with src/README.md.jinja."
      echo "       Run scripts/render-readme.sh and commit the result."
    } >&2
    exit 1
  fi
  echo "ok: src/README-preview.md is in sync with src/README.md.jinja"
else
  cp "$out/README.md" src/README-preview.md
  echo "ok: regenerated src/README-preview.md"
fi
