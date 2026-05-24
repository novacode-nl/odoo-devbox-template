#!/usr/bin/env bash
# Add/update the third-party addon repos vendored under addons/ as git subtrees.
#
# The registry lives in the top-level addons.json. For each entry this script
# runs "git subtree add" when the prefix doesn't exist yet, and "git subtree
# pull" to fetch upstream changes when it does — both squashed. To vendor a new
# repo, add an entry to addons.json; no need to touch this script.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

REGISTRY="addons.json"

if [ ! -f "${REGISTRY}" ]; then
  echo "[update-subtrees] ${REGISTRY} not found at repo root." >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "[update-subtrees] jq is required (declared in devbox.json); run inside 'devbox shell'." >&2
  exit 1
fi

# git subtree add/pull create commits, so the working tree must be clean.
if ! git diff-index --quiet HEAD --; then
  echo "[update-subtrees] Working tree has uncommitted changes — commit or stash first." >&2
  exit 1
fi

while IFS=$'\t' read -r prefix url branch; do
  if [ -d "${prefix}" ] && [ -n "$(ls -A "${prefix}" 2>/dev/null)" ]; then
    echo "[update-subtrees] Pulling ${prefix} from ${url} (${branch})"
    git subtree pull --prefix="${prefix}" "${url}" "${branch}" --squash
  else
    echo "[update-subtrees] Adding ${prefix} from ${url} (${branch})"
    git subtree add --prefix="${prefix}" "${url}" "${branch}" --squash
  fi
done < <(jq -r '.subtrees[] | [.prefix, .url, .branch] | @tsv' "${REGISTRY}")

echo "[update-subtrees] Done."
