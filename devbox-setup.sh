#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${PWD}"

echo "=== Odoo 19 Devbox Setup ==="


# --- Verify Odoo symlink ---
ODOO_SRC="${WORKSPACE}/../../repos/odoo-19"
if [ ! -e "${WORKSPACE}/odoo" ]; then
  if [ ! -d "$ODOO_SRC" ]; then
    echo "ERROR: Odoo source directory '$ODOO_SRC' does not exist. Please clone or fix the path before running this setup." >&2
    exit 1
  fi
  echo "Notice: '${WORKSPACE}/odoo' not found. Creating symlink to $ODOO_SRC"
  ln -s "$ODOO_SRC" "${WORKSPACE}/odoo"
fi

# --- Verify Enterprise symlink ---
ENTERPRISE_SRC="${WORKSPACE}/../../repos/enterprise-19"
if [ ! -e "${WORKSPACE}/enterprise" ]; then
  if [ ! -d "$ENTERPRISE_SRC" ]; then
    echo "ERROR: Enterprise source directory '$ENTERPRISE_SRC' does not exist. Please clone or fix the path before running this setup." >&2
    exit 1
  fi
  echo "Notice: '${WORKSPACE}/enterprise' not found. Creating symlink to $ENTERPRISE_SRC"
  ln -s "$ENTERPRISE_SRC" "${WORKSPACE}/enterprise"
fi

# --- Verify Enterprise symlink ---
if [ ! -e "${WORKSPACE}/enterprise" ]; then
  echo "Notice: '${WORKSPACE}/enterprise' not found. Creating symlink to ../../repos/enterprise-19"
  ln -s ../../repos/odoo-19 "${WORKSPACE}/odoo"
fi

# --- Python virtualenv ---
echo "[1/4] Setting up Python virtualenv..."
python3 -m venv "${WORKSPACE}/.venv"
. "${WORKSPACE}/.venv/bin/activate"
pip install --upgrade pip setuptools wheel

# --- Install Odoo + Python dependencies ---
echo "[2/4] Installing Odoo 19 and Python dependencies..."
# Use psycopg2-binary (prebuilt) instead of psycopg2 (requires pg_config + libpq headers)
sed 's/psycopg2==/psycopg2-binary==/' "${WORKSPACE}/odoo/requirements.txt" \
  | pip install -r /dev/stdin
if [ -f "${WORKSPACE}/requirements.txt" ]; then
  pip install -r "${WORKSPACE}/requirements.txt"
fi

# --- Ensure odoo-data directory exists for filestore/attachments ---
mkdir -p "${WORKSPACE}/odoo-data"

# --- PostgreSQL ---
echo "[3/4] Initializing PostgreSQL (socket only)..."

# Ensure process-compose.yaml is correct for socket-only PG
scripts/write-process-compose-pg.sh

# Set socket dir and data dir (align with nix-odoo/dev-server.sh)
PGSOCKDIR="${PGHOST:-$PWD/.devbox/virtenv/postgresql}"
PGDATA="${PGDATA:-$PWD/.devbox/virtenv/postgresql/data}"

# Purge command for devs (optional)
if [ "${1:-}" = "purge-pg" ]; then
  echo "[devbox-setup] Purging PostgreSQL data directory at $PGDATA ..."
  rm -rf "$PGDATA"
  echo "[devbox-setup] Purged."
  exit 0
fi

# Robust init: re-init if missing or empty
if [ ! -d "$PGDATA" ] || [ -z "$(ls -A "$PGDATA" 2>/dev/null)" ]; then
  echo "[devbox-setup] Initializing PostgreSQL data directory at $PGDATA ..."
  rm -rf "$PGDATA"
  initdb -D "$PGDATA" -E UTF8 --no-locale -A trust
fi

# Stable short alias for the socket dir, so odoo.conf can use a portable path.
# The alias name matches the devbox project root basename, so multiple checkouts don't collide.
ln -sfn "$PGSOCKDIR" "/tmp/$(basename "$WORKSPACE")"

# Start PostgreSQL only on Unix socket (no TCP)
pg_ctl -D "$PGDATA" -l "$PGDATA/logfile" \
  -o "-c unix_socket_directories='$PGSOCKDIR' -c listen_addresses=''" start || true
sleep 2

# Create odoo database user (peer auth, no password needed)
createuser -h "$PGSOCKDIR" odoo --createdb --no-superuser --no-createrole 2>/dev/null || true

pg_ctl -D "$PGDATA" stop || true

# --- Install requirements.txt for each addons_path root ---
echo "[4/4] Installing addons requirements (from odoo.conf addons_path)..."
bash "${WORKSPACE}/scripts/install-addons-deps.sh"

echo ""
echo "=== Setup complete ==="
echo "  Recommended:     devbox services up      # start all services (Odoo, PostgreSQL, etc.) with process-compose"
echo "  Or:              devbox services start   # start PostgreSQL only (background)"
echo "                   devbox run start-odoo   # start Odoo manually"
echo "  Or use the VS Code launch configuration (F5)"
