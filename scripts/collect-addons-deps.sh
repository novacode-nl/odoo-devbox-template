#!/usr/bin/env bash
# Collect the requirements.txt declared by each addon (resolved from odoo.conf's
# addons_path) and write them — COMMENTED OUT — into a managed, regenerable
# block at the end of the workspace-root requirements.txt, purely as an overview.
#
# Commented lines are NOT installed by pip. Review the block, then copy/pin the
# packages you actually want into the active (uncommented) part of the file —
# that curated list is the single source of truth installed by
# scripts/install-addons-deps.sh.
#
# Resolves both addons/<repo> (tracked) and external-addons/<repo> (ignored);
# the walk-up stops at the workspace root. Excludes odoo/requirements.txt.
# Re-running regenerates the managed block; your active pins outside it are kept.
set -euo pipefail

WORKSPACE="${PWD}"
CONF="${WORKSPACE}/odoo.conf"
ODOO_REQ="${WORKSPACE}/odoo/requirements.txt"
ROOT_REQ="${WORKSPACE}/requirements.txt"

BEGIN_MARK="# >>> addon-deps (AUTO-COLLECTED by scripts/collect-addons-deps.sh — DO NOT EDIT BY HAND, regenerated; commented, NOT installed) >>>"
END_MARK="# <<< addon-deps <<<"

if [ ! -f "${CONF}" ]; then
  echo "[collect-addons-deps] odoo.conf not found at ${CONF} — nothing to collect."
  exit 0
fi

ADDONS_PATH="$(awk -F= '
  /^[[:space:]]*addons_path[[:space:]]*=/ {
    sub(/^[[:space:]]+/, "", $2)
    print $2
    exit
  }' "${CONF}")"

if [ -z "${ADDONS_PATH}" ]; then
  echo "[collect-addons-deps] No addons_path in odoo.conf — nothing to collect."
  exit 0
fi

# Resolve unique addon requirements.txt files (walk up, dedupe, skip odoo).
reqs=()
processed=""
IFS=',' read -ra ENTRIES <<< "${ADDONS_PATH}"
for entry in "${ENTRIES[@]}"; do
  entry="$(printf '%s' "$entry" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  [ -z "$entry" ] && continue

  if [[ "$entry" = /* ]]; then dir="$entry"; else dir="${WORKSPACE}/${entry}"; fi

  req=""
  while [ "$dir" != "/" ] && [ "$dir" != "${WORKSPACE}" ]; do
    if [ -f "${dir}/requirements.txt" ]; then req="${dir}/requirements.txt"; break; fi
    dir="$(dirname "$dir")"
  done

  [ -z "$req" ] && continue
  [ "$req" = "${ODOO_REQ}" ] && continue
  case ":$processed:" in *":$req:"*) continue ;; esac
  processed="${processed:+$processed:}$req"
  reqs+=("$req")
done

# Build the managed block (everything commented).
block="$(mktemp)"
{
  echo "${BEGIN_MARK}"
  echo "# Requirements declared by your project addons, grouped by source — reference only."
  echo "# Copy/pin the lines you want into the active list above; commented lines are NOT installed."
  if [ "${#reqs[@]}" -eq 0 ]; then
    echo "#"
    echo "# (no addon requirements.txt found)"
  else
    for req in "${reqs[@]}"; do
      rel="${req#"${WORKSPACE}"/}"
      echo "#"
      echo "# --- ${rel} ---"
      while IFS= read -r line || [ -n "$line" ]; do
        [ -z "${line//[[:space:]]/}" ] && continue   # skip blank lines
        printf '# %s\n' "$line"
      done < "$req"
    done
  fi
  echo "${END_MARK}"
} > "${block}"

# Strip any existing managed block from ROOT_REQ, then append the fresh one.
tmp="$(mktemp)"
if [ -f "${ROOT_REQ}" ]; then
  awk -v b="${BEGIN_MARK}" -v e="${END_MARK}" '
    $0==b {skip=1}
    skip && $0==e {skip=0; next}
    !skip {print}
  ' "${ROOT_REQ}" > "${tmp}"
else
  : > "${tmp}"
fi

# Separate the block from any preceding active content with a blank line.
if [ -s "${tmp}" ] && [ -n "$(tail -c1 "${tmp}")" ]; then echo "" >> "${tmp}"; fi
cat "${block}" >> "${tmp}"
mv "${tmp}" "${ROOT_REQ}"
rm -f "${block}"

echo "[collect-addons-deps] Wrote commented addon-deps overview to ${ROOT_REQ} (${#reqs[@]} source file(s))."
echo "[collect-addons-deps] Review it; uncomment/pin what you need — only uncommented lines are installed."
