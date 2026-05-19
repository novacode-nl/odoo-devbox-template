#!/usr/bin/env bash
# Print the python binary name (e.g. "python3.12") derived from devbox.json's
# packages list. Used by devbox.json init_hook and devbox-setup.sh so the
# version declared in devbox.json is the only place to change.
# Handles both devbox package forms:
#   - keyed-object:  "packages": { "python": "3.12", ... }
#   - string-array:  "packages": [ "python@3.12", ... ]
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
DEVBOX_JSON="${HERE}/../devbox.json"

# Keyed-object form: "python": "3.12"
ver=$(grep -oE '"python"[[:space:]]*:[[:space:]]*"[0-9]+\.[0-9]+"' "$DEVBOX_JSON" \
        | head -1 | sed -E 's/.*"([0-9.]+)"/\1/' || true)

# Fallback to string-array form: "python@3.12"
if [ -z "$ver" ]; then
  ver=$(grep -oE '"python@[0-9]+\.[0-9]+"' "$DEVBOX_JSON" \
          | head -1 | sed -E 's/.*@([0-9.]+)".*/\1/' || true)
fi

if [ -z "$ver" ]; then
  echo "ERROR: Could not derive python version from devbox.json packages (expected '\"python\": \"X.Y\"' or '\"python@X.Y\"')." >&2
  exit 1
fi
echo "python${ver}"
