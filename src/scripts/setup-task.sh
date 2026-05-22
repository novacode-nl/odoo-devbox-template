#!/usr/bin/env bash
# Wrapper for the "Devbox Setup" VS Code tasks — adds a `.devbox/.setup-done`
# marker on top of `devbox run setup` so it doesn't re-run on every folder open.
#   once  — run devbox setup unless .devbox/.setup-done already exists
#   force — remove the flag and re-run devbox setup
# Addons-deps installation is part of `devbox run setup` itself (see
# devbox-setup.sh) — not handled here.
set -euo pipefail

MODE="${1:-once}"
WORKSPACE="${PWD}"
DONE_FLAG="${WORKSPACE}/.devbox/.setup-done"

run_devbox_setup() {
  devbox run setup
  mkdir -p "${WORKSPACE}/.devbox"
  touch "${DONE_FLAG}"
}

case "${MODE}" in
  once)
    if [ ! -f "${DONE_FLAG}" ]; then
      run_devbox_setup
    else
      echo "devbox setup already completed (.devbox/.setup-done exists) — skipping."
    fi
    ;;
  force)
    rm -f "${DONE_FLAG}"
    run_devbox_setup
    ;;
  *)
    echo "Usage: $0 [once|force]" >&2
    exit 2
    ;;
esac
