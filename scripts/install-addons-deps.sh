#!/usr/bin/env bash
# Install requirements.txt for each top-level (repo-root) dir derived from
# `addons_path` in odoo.conf. Walks up from each addons_path entry to the
# nearest enclosing dir that contains requirements.txt, dedupes, and runs
# `pip install -r` against each.
#
# Excludes odoo/requirements.txt — odoo's deps are installed separately
# (psycopg2-binary substitution) by devbox-setup.sh and the devbox
# `update-deps` script. Also excludes the workspace-root requirements.txt
# (already handled by devbox-setup.sh).
set -euo pipefail

WORKSPACE="${PWD}"
CONF="${WORKSPACE}/odoo.conf"
VENV="${WORKSPACE}/.venv"
ODOO_REQ="${WORKSPACE}/odoo/requirements.txt"

if [ ! -d "${VENV}" ]; then
  echo "[install-addons-deps] .venv not found at ${VENV} — skipping."
  exit 0
fi
if [ ! -f "${CONF}" ]; then
  echo "[install-addons-deps] odoo.conf not found at ${CONF} — skipping."
  exit 0
fi

# shellcheck disable=SC1091
. "${VENV}/bin/activate"

ADDONS_PATH="$(awk -F= '
  /^[[:space:]]*addons_path[[:space:]]*=/ {
    sub(/^[[:space:]]+/, "", $2)
    print $2
    exit
  }' "${CONF}")"

if [ -z "${ADDONS_PATH}" ]; then
  echo "[install-addons-deps] No addons_path in odoo.conf — skipping."
  exit 0
fi

echo "[install-addons-deps] Resolving addons_path roots..."

processed=""
IFS=',' read -ra ENTRIES <<< "${ADDONS_PATH}"
for entry in "${ENTRIES[@]}"; do
  entry="$(printf '%s' "$entry" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  [ -z "$entry" ] && continue

  if [[ "$entry" = /* ]]; then
    dir="$entry"
  else
    dir="${WORKSPACE}/${entry}"
  fi

  req=""
  while [ "$dir" != "/" ] && [ "$dir" != "${WORKSPACE}" ]; do
    if [ -f "${dir}/requirements.txt" ]; then
      req="${dir}/requirements.txt"
      break
    fi
    dir="$(dirname "$dir")"
  done

  [ -z "$req" ] && continue
  [ "$req" = "${ODOO_REQ}" ] && continue

  case ":$processed:" in
    *":$req:"*) continue ;;
  esac
  processed="${processed:+$processed:}$req"

  echo "[install-addons-deps] pip install -r $req"
  pip install -r "$req"
done

echo "[install-addons-deps] Done."
