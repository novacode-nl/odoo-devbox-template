#!/usr/bin/env bash
# Add/update the third-party addon repos registered in the top-level addons.json:
# "subtrees" (vendored into this repo's own history) and "submodules" (pointers
# to their own repos). To onboard a repo, add an entry; no need to touch this
# script. The same command both adds a new entry and updates the existing ones.
#
#   bash scripts/update-addon-repos.sh               both       (devbox run update-addon-repos)
#   bash scripts/update-addon-repos.sh subtrees      subtrees   (devbox run update-subtrees)
#   bash scripts/update-addon-repos.sh submodules    submodules (devbox run update-submodules)
#
# Subtrees run first: git subtree add/pull create commits and need a clean
# working tree. Submodules run after, because `git submodule add` and the
# pointer updates leave .gitmodules and the submodule path staged. This script
# never commits those — it prints what is left to commit.
set -euo pipefail

MODE="${1:-all}"
case "${MODE}" in
  all | subtrees | submodules) ;;
  *)
    echo "[addon-repos] usage: $(basename "$0") [all|subtrees|submodules]" >&2
    exit 2
    ;;
esac

cd "$(git rev-parse --show-toplevel)"

REGISTRY="addons.json"

if [ ! -f "${REGISTRY}" ]; then
  echo "[addon-repos] ${REGISTRY} not found at repo root." >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "[addon-repos] jq is required (declared in devbox.json); run inside 'devbox shell'." >&2
  exit 1
fi

# A prefix can be vendored or linked, not both: whichever ran last would fight
# the other on every run.
both="$(jq -r '
  [(.subtrees // [])[].prefix] as $s
  | [(.submodules // [])[].prefix] as $m
  | $s | map(select(. as $p | $m | index($p))) | unique | .[]
' "${REGISTRY}")"
if [ -n "${both}" ]; then
  echo "[addon-repos] These prefixes are listed as both subtree and submodule:" >&2
  echo "${both}" | sed 's/^/  - /' >&2
  echo "[addon-repos] Keep each prefix in one list only." >&2
  exit 1
fi

n_subtrees="$(jq '(.subtrees // []) | length' "${REGISTRY}")"
n_submodules="$(jq '(.submodules // []) | length' "${REGISTRY}")"

# --- subtrees ----------------------------------------------------------------
if [ "${MODE}" != "submodules" ] && [ "${n_subtrees}" -gt 0 ]; then
  # git subtree add/pull create commits, so the working tree must be clean.
  # Refresh the index first so stale stat info (e.g. mtimes bumped by the devbox
  # shell init hook) doesn't produce a false "dirty" result.
  git update-index -q --refresh || true
  if [ -n "$(git status --porcelain)" ]; then
    echo "[addon-repos] Working tree has uncommitted changes — commit or stash first" >&2
    echo "[addon-repos] (git subtree add/pull commit, so they need a clean tree)." >&2
    exit 1
  fi

  while IFS=$'\t' read -r prefix url branch; do
    if [ -d "${prefix}" ] && [ -n "$(ls -A "${prefix}" 2>/dev/null)" ]; then
      echo "[addon-repos] subtree: pulling ${prefix} from ${url} (${branch})"
      git subtree pull --prefix="${prefix}" "${url}" "${branch}" --squash
    else
      echo "[addon-repos] subtree: adding ${prefix} from ${url} (${branch})"
      git subtree add --prefix="${prefix}" "${url}" "${branch}" --squash
    fi
  done < <(jq -r '(.subtrees // [])[] | [.prefix, .url, .branch] | @tsv' "${REGISTRY}")
fi

# --- submodules --------------------------------------------------------------
if [ "${MODE}" != "subtrees" ] && [ "${n_submodules}" -gt 0 ]; then
  # Check out whatever is already recorded (a fresh clone has empty directories).
  # No --remote here: this only materializes the committed pointers.
  if [ -f .gitmodules ]; then
    git submodule update --init --recursive
  fi

  while IFS=$'\t' read -r prefix url branch; do
    if [ -z "$(git config -f .gitmodules --get "submodule.${prefix}.url" 2>/dev/null || true)" ]; then
      if [ -d "${prefix}" ] && [ -n "$(ls -A "${prefix}" 2>/dev/null)" ]; then
        echo "[addon-repos] submodule: ${prefix} exists but is not a submodule — skipped." >&2
        echo "[addon-repos]            Move it aside (or list it under 'subtrees') and re-run." >&2
        continue
      fi
      echo "[addon-repos] submodule: adding ${prefix} from ${url} (${branch})"
      git submodule add -b "${branch}" "${url}" "${prefix}"
      continue
    fi

    # Follow the branch from addons.json, so changing it there is enough.
    recorded="$(git config -f .gitmodules --get "submodule.${prefix}.branch" 2>/dev/null || true)"
    if [ "${recorded}" != "${branch}" ]; then
      echo "[addon-repos] submodule: ${prefix} branch ${recorded:-<unset>} -> ${branch}"
      git submodule set-branch --branch "${branch}" -- "${prefix}"
    fi

    before="$(git -C "${prefix}" rev-parse --short HEAD 2>/dev/null || true)"
    echo "[addon-repos] submodule: updating ${prefix} to the ${branch} tip"
    git submodule update --init --remote --merge -- "${prefix}"
    after="$(git -C "${prefix}" rev-parse --short HEAD 2>/dev/null || true)"
    if [ "${before}" = "${after}" ]; then
      echo "[addon-repos]            already at ${after}"
    else
      echo "[addon-repos]            ${before:-<none>} -> ${after}"
    fi
  done < <(jq -r '(.submodules // [])[] | [.prefix, .url, .branch] | @tsv' "${REGISTRY}")

  # Submodule work is staged, never committed here: the pointer bump belongs in
  # a commit of your own, next to whatever made you update.
  git update-index -q --refresh || true
  if [ -n "$(git status --porcelain)" ]; then
    echo ""
    echo "[addon-repos] Submodule changes left for you to commit:"
    git status --short | sed 's/^/  /'
    # A newly added submodule is staged, a moved pointer is not: -a covers both.
    echo "[addon-repos] e.g. git commit -a -m 'Update addon submodules'"
  fi
fi

echo "[addon-repos] Done."
