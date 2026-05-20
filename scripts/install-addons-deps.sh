#!/usr/bin/env bash
# Install the project's Python deps from the workspace-root requirements.txt —
# the single, curated source of truth. Per-addon requirements are NOT installed
# directly; run `scripts/collect-addons-deps.sh` (devbox run collect-deps) to
# gather them into a commented overview in requirements.txt, then uncomment/pin
# the ones you want. Only uncommented lines are installed.
#
# odoo/requirements.txt is installed separately (psycopg2-binary substitution)
# by devbox-setup.sh and the devbox `update-deps` script.
set -euo pipefail

WORKSPACE="${PWD}"
VENV="${WORKSPACE}/.venv"
ROOT_REQ="${WORKSPACE}/requirements.txt"

if [ ! -d "${VENV}" ]; then
  echo "[install-addons-deps] .venv not found at ${VENV} — skipping."
  exit 0
fi
if [ ! -f "${ROOT_REQ}" ]; then
  echo "[install-addons-deps] No workspace-root requirements.txt — skipping."
  echo "[install-addons-deps] Tip: 'devbox run collect-deps' gathers addon requirements into a commented overview to curate."
  exit 0
fi

# shellcheck disable=SC1091
. "${VENV}/bin/activate"

echo "[install-addons-deps] pip install -r ${ROOT_REQ}"
pip install -r "${ROOT_REQ}"
echo "[install-addons-deps] Done."
