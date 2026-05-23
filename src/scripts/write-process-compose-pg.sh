#!/usr/bin/env bash
set -euo pipefail

# Write a socket-only process-compose.yaml for PostgreSQL (for devbox)
mkdir -p .devbox/virtenv/postgresql
cat > .devbox/virtenv/postgresql/process-compose.yaml <<'EOF'
version: "0.5"

processes:
  postgresql:
    command: >
      sh -c 'ln -sfn "$PGHOST" "/tmp/$(basename "$PWD")"; exec postgres -c unix_socket_directories="$PGHOST" -c listen_addresses="" -D "$PGDATA"'
    is_daemon: false
    shutdown:
      command: "pg_ctl -D \"$PGDATA\" stop -m fast"
    availability:
      restart: "always"
    readiness_probe:
      exec:
        command: >
          sh -c 'pg_isready -h "$PGHOST" -d postgres'
EOF
