# Odoo 19 Devbox

## Quick start (VS Code)

Recommended workflow when developing from VS Code with the [Jetify Devbox](https://marketplace.visualstudio.com/items?itemName=jetpack-io.devbox) extension.

1. **Copy the Odoo config** (first time only):
    ```bash
    cp odoo.conf.example odoo.conf
    ```
    Edit `addons_path`, `http_port`, etc. as needed (see [odoo.conf](#odooconf) below).

2. **Open the workspace in VS Code**:
    ```bash
    code .
    ```
	 Or directly open the workspace file for automatic extension recommendations and settings:
    ```bash
    code main.code-workspace
    ```
    Make sure the Jetify Devbox extension is installed so the integrated terminal activates the devbox shell automatically.

3. **Automatic tasks run in sequence on folder open** (defined in [.vscode/tasks.json](.vscode/tasks.json)):
    - `Devbox Setup: once` — runs `devbox run setup` if `.devbox/.setup-done` is missing (creates the venv, installs Odoo + pip deps, initializes PostgreSQL), then writes the marker so it doesn't re-run on subsequent opens.
    - `Start Services` — runs `devbox services up` (PostgreSQL and any other services via process-compose). Depends on the setup task above.

4. **Start Odoo via Run and Debug** (`F5`):
    Use the `Start Odoo` launch config in [.vscode/launch.json](.vscode/launch.json) — it runs `odoo/odoo-bin` with `odoo.conf` using `.venv/bin/python` as the interpreter, and supports breakpoints. A second config, `Unittests Odoo`, runs the test suite with `--test-enable --stop-after-init`.

### VS Code tasks reference

Available via **Terminal → Run Task…** ([.vscode/tasks.json](.vscode/tasks.json)):

| Task | What it does |
| --- | --- |
| `Devbox Setup: once` | Runs `devbox run setup` only if `.devbox/.setup-done` is absent. Auto-runs on folder open. |
| `Devbox Setup: force re-run` | Removes the marker and re-runs setup. Use after pulling Odoo changes or editing `devbox.json` / `devbox-setup.sh`. |
| `Start Services` | `devbox services up` (process-compose). Auto-runs on folder open after setup. |
| `Stop Services` | `devbox services stop`. |

## CLI usage (devbox shell)

Use this path when you prefer the terminal over VS Code, or for CI / remote sessions.

### 1. Start the shell (from the project root):

With [direnv](https://direnv.net/) installed, the [.envrc](.envrc) auto-activates the devbox shell on `cd`:

```bash
cd ~/odoo/devbox/devbox-odoo-19
```

Without direnv, activate it manually:

```bash
cd ~/odoo/devbox/devbox-odoo-19
devbox shell
```

This downloads all Nix packages on first run (Python, PostgreSQL, wkhtmltopdf, etc.) and drops you into an isolated shell with everything on PATH.

### 2. Run the setup (first time only, inside the devbox shell):

```bash
devbox run setup
```

This creates the Python venv, installs Odoo + pip deps, and initializes PostgreSQL with the odoo user.

### 3. Start services

Every time you open a new terminal for this project, run `devbox shell` first (or use direnv to auto-activate it).

**Recommended — process-compose for unified logs and monitoring:**
This launches all services (PostgreSQL, etc.) together using process-compose, with unified logs and monitoring. Press <Ctrl+C> to stop all.

```bash
devbox services up
```

Or start services individually:

```bash
devbox services start   # starts PostgreSQL in background
devbox run start-odoo   # starts Odoo (port 8069 by default, see http_port in odoo.conf)
```

Or just use F5 in VS Code (the `Start Odoo` launch config runs `odoo/odoo-bin` with `.venv/bin/python`).

### 4. Update Odoo dependencies after Git pulling changes

```bash
cd odoo
git pull
devbox run setup
```

## odoo.conf

#### addons_path

Must include the Odoo core addons paths first. `enterprise` is a symlink to a sibling checkout, and `addons/` holds project-local modules.

Example (matches [odoo.conf.example](odoo.conf.example)):

`addons_path = odoo/odoo/addons,odoo/addons,enterprise,addons/odoo-formio,addons/odoo-formio-premium`

#### http_port

Example:\
`8069`

#### db_host

PostgreSQL runs on a Unix socket only (no TCP). `db_host` must be an absolute path to the socket directory, so we expose a stable short alias under `/tmp` whose name matches the devbox project root basename.

For this checkout (`devbox-odoo-19`):

`db_host = /tmp/devbox-odoo-19`

The alias is (re)created automatically by `devbox run setup` and on every `devbox services up` (see [scripts/write-process-compose-pg.sh](scripts/write-process-compose-pg.sh)). If you rename or clone the project directory under a different name, update `db_host` in `odoo.conf` to match the new basename.

## PostgreSQL

PostgreSQL listens on a Unix socket only. Connect using the socket directory as the host:

`psql -h /tmp/devbox-odoo-19 -U odoo postgres`

## Technologies and tools

**Devbox**

- GitHub: https://github.com/jetify-com/devbox
- Docs: https://www.jetify.com/docs/devbox
- Official website: https://www.jetify.com/devbox

## Monitoring services with process-compose

To list the process-compose processes:
```bash
devbox services ls
```

To attach the process-compose processes:
```bash
devbox services attach
```

## Troubleshooting - VS Code terminal errors (using launch.json)

## F5 (Start Odoo) results in shell error(s):

```bash
❯  /usr/bin source /Users/bob/odoo/devbox/devbox-odoo-19/.venv/bin/activate
zsh: permission denied: /usr/bin
```

Or ...

```bash
❯  /usr/bin/env  source /Users/bob/odoo/devbox/devbox-odoo-19/.venv/bin/activate
env: source: No such file or directory
```

### Solution:

Disable `ms-python.vscode-python-envs` for just this workspace (the actual disable state can't be set via settings JSON — VS Code stores it per-user).

This workspace already ships an `extensions.unwantedRecommendations` entry for `ms-python.vscode-python-envs` in [`main.code-workspace`](main.code-workspace). When you open the workspace, VS Code should surface a notification recommending you disable it — please follow that prompt.

If you missed the notification, disable it manually:

1. Open the Extensions sidebar (Cmd+Shift+X)
2. Search for `Python Environments` (publisher: Microsoft, id: `ms-python.vscode-python-envs`)
3. Click the gear icon → "Disable (Workspace)"
4. Reload the window when prompted

## Troubleshooting - PostgreSQL data directory errors

### If you see startup errors, try:

1. Stopping all devbox services:
    ```bash
    devbox services stop
    ```
2. Removing any leftover .devbox/virtenv/postgresql/data/postmaster.pid file if it exists

3. Starting services again:
    ```bash
    devbox services up
    ```

### If you see errors like:

	 postgres: could not access the server configuration file .../postgresql.conf
	 postgres: could not access directory .../data: No such file or directory

This means the PostgreSQL data directory is missing or empty. To fix:

1. Stop all services:
	```bash
	devbox services stop
	```
2. Remove the broken data directory:
	```bash
	rm -rf .devbox/virtenv/postgresql/data
	```
3. Re-run setup or start services:
	```bash
	devbox run setup
	# or
	devbox services up
	```
This will re-initialize the database and fix the error.
