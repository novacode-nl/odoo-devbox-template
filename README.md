# Odoo Devbox

## First-time setup

Required once per checkout, before either the VS Code or CLI workflow below.

**1. Install [Devbox](https://www.jetify.com/docs/devbox/installing-devbox/index)**

**2. Copy the Odoo config:**
```bash
cp odoo.conf.example odoo.conf
```
Edit `addons_path`, `http_port`, etc. as needed (see [odoo.conf](#odooconf) below).

**3. Provide the Odoo source** (and optionally Enterprise):

Odoo 19 must be available at `<workspace>/odoo`.\
Enterprise modules are optional — if you have access, make the repo available at `<workspace>/enterprise`.

**Pick one of:**

- **Clone directly into the workspace:**
  ```bash
  git clone --branch 19.0 https://github.com/odoo/odoo.git odoo
  git clone --branch 19.0 git@github.com:odoo/enterprise.git enterprise   # optional, private repo
  ```
- **Symlink an existing checkout:**
  ```bash
  ln -s /path/to/your/odoo-19 odoo
  ln -s /path/to/your/enterprise-19 enterprise   # optional
  ```
- **Auto-symlink via `devbox run setup`:** if you keep clones at `~/odoo/repos/odoo-19` and `~/odoo/repos/enterprise-19` (relative to the workspace), [devbox-setup.sh](devbox-setup.sh) creates the symlinks for you on the first run.

**4. Clone any additional addons repos** (optional):

Project-local or third-party addons live under `<workspace>/addons/<repo>`. Clone (or symlink) each one there, then add the path to `addons_path` in `odoo.conf`. Example:
```bash
git clone --branch 19.0 https://github.com/<org>/<repo>.git addons/<repo>
```
Their Python deps (any `requirements.txt` at the repo root) are picked up automatically by `devbox run update-deps` — see [Addons deps install ↓](#addons-deps-install).

## Usage — VS Code

Recommended workflow when developing from VS Code.

### 1. Open the workspace in VS Code:
```bash
code .
```
    Or directly open the workspace file for automatic extension recommendations and settings:
```bash
code main.code-workspace
```

Recommended extensions (surfaced as workspace recommendations on open):

- **[Jetify Devbox](https://marketplace.visualstudio.com/items?itemName=jetpack-io.devbox)** — *always recommended*

    Devbox integration commands and terminal shell activation.

- **[mkhl.direnv](https://marketplace.visualstudio.com/items?itemName=mkhl.direnv)** — *only if you launch VS Code outside the devbox shell/PATH*

    Loads [.envrc](.envrc) on folder open so VS Code (and its Python extension) inherits the devbox env (`python3.x.x` on PATH, `PYTHON_BIN`, etc.). Without it, VS Code scans `.venv` outside devbox and may pin to the OS system Python version instead of the version declared in [devbox.json](devbox.json).
    - **Need `mkhl.direnv`:** opening VS Code via `code .` from a plain terminal, or from your OS's app launcher when the `devbox shell` isn't loaded.
    - **Skip `mkhl.direnv`:** if you always run `devbox shell` first and launch VS Code from inside it.

	After installing `mkhl.direnv`, approve the workspace's `.envrc` once so the extension is allowed to source it:
	```bash
	direnv allow .
	```

### 2. Automatic tasks run in sequence on folder open (defined in [.vscode/tasks.json](.vscode/tasks.json)):
- `Devbox Setup: once` — runs `devbox run setup` if `.devbox/.setup-done` is missing (creates the venv, installs Odoo + pip deps, initializes PostgreSQL), then writes the marker so it doesn't re-run on subsequent opens.
- `Start Services` — runs `devbox services up` (PostgreSQL and any other services via process-compose). Depends on the setup task above.

### 3. Start Odoo via Run and Debug (`F5`):
Use the `Start Odoo` launch config in [.vscode/launch.json](.vscode/launch.json) — it runs `odoo/odoo-bin` with `odoo.conf` using `.venv/bin/python` as the interpreter, and supports breakpoints. A second config, `Unittests Odoo`, runs the test suite with `--test-enable --stop-after-init`.

### VS Code tasks reference

Available via **Terminal → Run Task…** ([.vscode/tasks.json](.vscode/tasks.json)):

| Task | What it does |
| --- | --- |
| `Devbox Setup: once` | <ul><li>Runs `devbox run setup` only if `.devbox/.setup-done` is absent.</li><li>Then [**installs addons deps** ↓](#addons-deps-install).</li><li>Auto-runs on folder open.</li></ul> |
| `Devbox Setup: force re-run` | <ul><li>Removes the marker `.devbox/.setup-done` and re-runs setup `devbox run setup`.</li><li>Then [**installs addons deps** ↓](#addons-deps-install).</li><li>Use after pulling Odoo changes or editing `devbox.json`, `devbox-setup.sh`, or `odoo.conf`.</li></ul> |
| `Start Services` | <ul><li>Runs `devbox services up` (process-compose).</li><li>Auto-runs on folder open after setup.</li></ul> |
| `Stop Services` | Runs `devbox services stop`. |

Both `Devbox Setup` tasks are also reachable from the CLI as `devbox run setup-once` and `devbox run setup-force`.

#### Addons deps install

Both `Devbox Setup` tasks finish by invoking [scripts/install-addons-deps.sh](scripts/install-addons-deps.sh) (via [devbox-setup.sh](devbox-setup.sh) as the last step of `devbox run setup`); `devbox run update-deps` calls it directly too, so the same install is reachable from the CLI. The script:

- Reads `addons_path` from [odoo.conf](odoo.conf).
- For each entry, walks up to the nearest `requirements.txt` and runs `pip install -r` against it.
- **Dynamic** — adding a new addons repo to `addons_path` is enough; no script edits needed.
- Excludes `odoo/requirements.txt` (handled separately by `devbox-setup.sh` with the `psycopg2-binary` substitution).

## Usage — CLI (devbox shell)

Use this path when you prefer the terminal over VS Code, or for CI / remote sessions.

### 1. Start the shell (from the project root):

With [direnv](https://direnv.net/) installed, the [.envrc](.envrc) auto-activates the devbox shell on `cd`:

```bash
cd ~/odoo/odoo-devbox
```

Without direnv, activate it manually:

```bash
cd ~/odoo/odoo-devbox
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
devbox run update-deps
```

### 5. After editing `odoo.conf` (e.g. adding a repo to `addons_path`)

Run the same command — it installs the new addons' Python deps (see [Addons deps install ↑](#addons-deps-install)):

```bash
devbox run update-deps
```

## odoo.conf

#### addons_path

Must include the Odoo core addons paths first. `enterprise` is a symlink to a sibling checkout, and `addons/` holds project-local modules.

Example (matches [odoo.conf.example](odoo.conf.example)):

`addons_path = odoo/addons,enterprise`

#### http_port

Example:\
`8069`

#### db_host

PostgreSQL runs on a Unix socket only (no TCP). `db_host` must be an absolute path to the socket directory, so we expose a stable short alias under `/tmp` whose name matches the devbox project root basename.

For this checkout (`odoo-devbox-19`):

`db_host = /tmp/odoo-devbox-19`

The alias is (re)created automatically by `devbox run setup` and on every `devbox services up` (see [scripts/write-process-compose-pg.sh](scripts/write-process-compose-pg.sh)). If you rename or clone the project directory under a different name, update `db_host` in `odoo.conf` to match the new basename.

## PostgreSQL

PostgreSQL listens on a Unix socket only. Connect using the socket directory as the host:

`psql -h /tmp/odoo-devbox-19 -U odoo postgres`

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
❯  /usr/bin source ~/odoo/odoo-devbox-19/.venv/bin/activate
zsh: permission denied: /usr/bin
```

Or ...

```bash
❯  /usr/bin/env  source ~/odoo/odoo-devbox-19/.venv/bin/activate
env: source: No such file or directory
```

Or ...

```bash
❯ devbox  /usr/bin/env ~/odoo/odoo-devbox-19/.venv/bin/python
Error: unknown command "/usr/bin/env" for "devbox"
```

### Solution:

See also: install the `mkhl.direnv` extension (see [Usage — VS Code ↑](#usage--vs-code)) so VS Code inherits the devbox env on folder open — this resolves most of the underlying interpreter-mismatch causes.

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
