# Odoo Devbox

[![Built with Devbox](https://www.jetify.com/img/devbox/shield_galaxy.svg)](https://www.jetify.com/devbox/docs/contributor-quickstart/)

## Introduction

This is a [**Devbox**](https://www.jetify.com/devbox) project for [**Odoo 19.0**](https://www.odoo.com) development.

**Scaffolded with the [odoo-devbox-template](https://github.com/novacode-nl/odoo-devbox-template) ([Copier](https://copier.readthedocs.io/)):**

- Run `copier update` to pull in template improvements.

**What this provides:**

- **Reproducible toolchain** — pins Python, PostgreSQL, `wkhtmltopdf`, `rtlcss` and build/native libs in [devbox.json](devbox.json), with exact versions and hashes auto-tracked in [devbox.lock](devbox.lock), so every deployment (e.g. developer, CI) gets the same environment.
- **VS Code integration** — ships workspace tasks and launch configs so `F5` "just works".
- **One-command setup** — on first run, devbox downloads all declared Nix packages and drops you into an isolated shell with everything on PATH. `devbox run setup` then creates the Python venv, installs Odoo + pip deps, and initializes PostgreSQL.

> **Apple Silicon (aarch64-darwin):** `wkhtmltopdf` is **excluded** from the devbox profile because nixpkgs has no working build for it on ARM macOS. Odoo PDF reports won't render until you install it manually — e.g. `brew install --cask wkhtmltopdf`, or any other source — and ensure `wkhtmltopdf` is on your PATH (system PATH is fine; devbox shell inherits it).

## First-time setup

Required once per checkout, before either the VS Code or CLI workflow below.

> **Workspace** (and **`<workspace>`** in path examples) — the root of this checkout, where `devbox.json` lives.

### 1. Install [Devbox](https://www.jetify.com/docs/devbox/installing-devbox/index)

### 2. Add the Odoo config:

The root `odoo.conf` is in [.gitignore](.gitignore) — it's never committed, whether it's a regular file you created (e.g. `cp odoo.conf.example odoo.conf`) or a symlink to `devbox.d/odoo.conf` that `devbox run setup` created for you.\
Use the `devbox.d/odoo.conf` option below if you want the config tracked in git (shared per-project).

All consumers (devbox scripts, `.vscode/launch.json`, `scripts/install-addons-deps.sh`) read from `<workspace>/odoo.conf`.\
The active `odoo.conf` file is resolved by `devbox run setup` in this order:

1. **`<workspace>/devbox.d/odoo.conf`** (the per-project config) — intended to be Git committed so the whole team shares the same `addons_path`, `http_port`, etc.\
When **no real root `odoo.conf` exists**, `devbox run setup` creates a symlink `<workspace>/odoo.conf → devbox.d/odoo.conf` so every tool sees the same file at the standard path.
2. **`<workspace>/odoo.conf`** (real root file) — a regular file at the workspace root (e.g. `cp odoo.conf.example odoo.conf`).\
Lets developers spin up a local devbox environment quickly with their own tweaks without committing anything.

**If a real root file exists, it wins** over `devbox.d/odoo.conf` — `devbox run setup` leaves it alone and prints a warning that the `devbox.d` override is being ignored. Delete the root file to activate the override.

Notes:
- A stale symlink (target gone) is cleaned up automatically by `devbox run setup`.

Edit `addons_path`, `http_port`, etc. as needed (see [odoo.conf ↓](#odooconf) for property docs).

### 3. Provide the Odoo source (and optionally Enterprise):

Odoo 19.0 must be available at `<workspace>/odoo`. Enterprise modules are optional — if you have access, make the repo available at `<workspace>/enterprise`.

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
- **Auto-symlink via `devbox run setup`:** if you keep clones at `../repos/odoo-19` and `../repos/enterprise-19` (relative to the workspace), [devbox-setup.sh](devbox-setup.sh) creates the symlinks for you on the first run.

### 4. Add any additional addons repos (optional):

Addons live in two sibling directories, depending on whether you want them versioned with *this* project:

1. **`<workspace>/addons/<repo>`** — **tracked** by git. Use for this project's own addons, committed here (as a git submodule or a vendored directory).
   ```bash
   git submodule add -b 19.0 https://github.com/<org>/<repo>.git addons/<repo>
   ```
2. **`<workspace>/external-addons/<repo>`** — **not tracked** (the `external-addons/` tree is in [.gitignore](.gitignore)). Use for third-party clones you don't want to commit here.
   ```bash
   git clone --branch 19.0 https://github.com/<org>/<repo>.git external-addons/<repo>
   ```

Either way, add the module path(s) to `addons_path` in `odoo.conf`. Their Python deps (any `requirements.txt` at the repo root) are picked up automatically by `devbox run update-deps` — see [Addons deps install ↓](#addons-deps-install).

#### Git subtrees

Also addons under `addons/` can be administered as **git subtrees**. The set of those repos is registered in the top-level [addons.json](addons.json).

**Example:**

```json
{
  "subtrees": [
    { "prefix": "addons/queue", "url": "git@github.com:OCA/queue.git", "branch": "19.0" }
  ]
}
```

**To sync them all, run:**

```sh
devbox run update-subtrees
```

**Alternatively,** you can:

- Run [scripts/update-subtrees.sh](scripts/update-subtrees.sh) directly
- Use the **Update Subtrees - VS Code task**.

For each `addons.json` entry the script `git subtree add`s the repo if its `prefix` doesn't exist yet, and `git subtree pull`s it (squashed) otherwise.

So the same command both onboards a newly registered repo and updates existing ones. **To add an addon repo, just add an entry to `addons.json`** and re-run; no script edits needed.

The working tree must be clean (subtree add/pull create commits).

## Addons deps install

A curated, pinned **workspace-root `requirements.txt` is the single source of truth** for addon Python deps. Keeping all deps in one committed file prevents version collisions and regressions when an addon updates its own `requirements.txt`.

**Install** — [scripts/install-addons-deps.sh](scripts/install-addons-deps.sh) installs that `requirements.txt`. It runs at the end of `devbox run setup` (and on the `Devbox Setup` tasks), and `devbox run update-deps` calls it too. Only the active (uncommented) lines are installed; if there's no `requirements.txt`, it's skipped.

**Collect** — `devbox run collect-deps` ([scripts/collect-addons-deps.sh](scripts/collect-addons-deps.sh)) discovers each addon's `requirements.txt` (resolved from `addons_path`, walking up — handles both `addons/` and `external-addons/`, excluding `odoo/`) and writes them as a **commented** `# >>> addons-deps >>>` block at the end of `requirements.txt`, purely as an overview. Commented lines are **not** installed; review the block and copy/pin the packages you want into the active list above it. Re-running regenerates the block and preserves your active pins.

Typical flow: `devbox run collect-deps` → review the overview → uncomment/pin what you need → commit `requirements.txt` → `devbox run update-deps`.

`odoo/requirements.txt` is handled separately by `devbox-setup.sh` (with the `psycopg2-binary` substitution).

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
| `Devbox Setup: once` | <ul><li>Runs `devbox run setup` only if `.devbox/.setup-done` is absent.</li><li>Then [**installs addons deps** ↑](#addons-deps-install).</li><li>Auto-runs on folder open.</li></ul> |
| `Devbox Setup: force re-run` | <ul><li>Removes the marker `.devbox/.setup-done` and re-runs setup `devbox run setup`.</li><li>Then [**installs addons deps** ↑](#addons-deps-install).</li><li>Use after pulling Odoo changes or editing `devbox.json`, `devbox-setup.sh`, or `odoo.conf`.</li></ul> |
| `Start Services` | <ul><li>Runs `devbox services up` (process-compose).</li><li>Auto-runs on folder open after setup.</li></ul> |
| `Stop Services` | Runs `devbox services stop`. |

Both `Devbox Setup` tasks are also reachable from the CLI as `devbox run setup-once` and `devbox run setup-force`.

## Usage — CLI (devbox shell)

Use this path when you prefer the terminal over VS Code, or for CI / remote sessions.

### 1. Start the shell (from the project root):

With [direnv](https://direnv.net/) installed, the [.envrc](.envrc) auto-activates the devbox shell on `cd`:

```bash
cd <workspace>
```

Without direnv, activate it manually:

```bash
cd <workspace>
devbox shell
```

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

See [step 2 ↑](#2-add-the-odoo-config) for the file location and cascade.

### addons_path

Must include the Odoo core addons paths first. `enterprise` is a symlink to a sibling checkout; `addons/<repo>` holds this project's tracked addons, and `external-addons/<repo>` holds untracked third-party clones.

Example (matches [odoo.conf.example](odoo.conf.example)):

`addons_path = odoo/addons,enterprise`

### http_port

Example:\
`8069`

### db_host

PostgreSQL runs on a Unix socket only (no TCP). `db_host` must be an absolute path to the socket directory, so we expose a stable short alias under `/tmp` whose name matches the devbox project root basename.

For a checkout in a directory named `<project-dir-basename>`:

`db_host = /tmp/<project-dir-basename>`

The alias is (re)created automatically by `devbox run setup` and on every `devbox services up` (see [scripts/write-process-compose-pg.sh](scripts/write-process-compose-pg.sh)). If you rename or clone the project directory under a different name, update `db_host` in `odoo.conf` to match the new basename.

## PostgreSQL

PostgreSQL listens on a Unix socket only. Connect using the socket directory as the host:

`psql -h /tmp/<project-dir-basename> -U odoo postgres`

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

## Troubleshooting - VS Code (terminal errors) using launch.json

### Starting VS Code shows a popup alert:

> **Error refreshing packages**
> Source: *Python Environments (Extension)*

Raised by the `ms-python.vscode-python-envs` extension on workspace load. It tries to enumerate the Python environment outside the devbox shell and fails. See [Solution ↓](#solution) — disabling `ms-python.vscode-python-envs` for this workspace clears it.

### F5 (Start Odoo) results in shell error(s):

```bash
❯  /usr/bin source <workspace>/.venv/bin/activate
zsh: permission denied: /usr/bin
```

Or ...

```bash
❯  /usr/bin/env  source <workspace>/.venv/bin/activate
env: source: No such file or directory
```

Or ...

```bash
❯ devbox  /usr/bin/env <workspace>/.venv/bin/python
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
