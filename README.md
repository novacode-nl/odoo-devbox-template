# Odoo Devbox Template

[![Copier](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/copier-org/copier/master/img/badge/badge-grayscale-inverted-border-orange.json)](https://github.com/copier-org/copier)
[![Built with Devbox](https://www.jetify.com/img/devbox/shield_galaxy.svg)](https://www.jetify.com/devbox/docs/contributor-quickstart/)

A [Copier](https://copier.readthedocs.io/) template that scaffolds a reproducible
[Devbox](https://www.jetify.com/devbox) development environment for
[Odoo](https://www.odoo.com), with Jinja-templated support for **Odoo 17.0,
18.0 and 19.0**.

## What you'll actually get

Browse the generated project's README at [src/README-preview.md](src/README-preview.md).\
It's a pre-rendered preview (defaults: Odoo 19.0, Enterprise on) of
[README.md.jinja](src/README.md.jinja) — the README that ships into every new
project, describing day-to-day usage of the scaffolded environment.

**This Devbox setup:**
- Pins a reproducible toolchain (Python, PostgreSQL, `wkhtmltopdf`, `rtlcss`,
build/native libs) in `devbox.json`.
- Ships VS Code workspace tasks and launch configs (`F5` "just works"), socket-only PostgreSQL.
- A curated addons-`requirements.txt` workflow.

This template works for any Odoo project (own addons, third-party clones,
with or without Enterprise).

## Usage

Install Copier with a package manager — e.g. `pipx install copier` or `uv tool install copier` — then:

```bash
# Generate a new project
copier copy gh:<org>/odoo-devbox-template path/to/my-odoo-project

# ...or from a local clone of this template
copier copy /path/to/odoo-devbox-template path/to/my-odoo-project
```

Copier asks a few questions; answer them and the project skeleton is rendered
into the target directory. Afterwards, follow the generated `README.md` for
first-time setup (`devbox run setup`).

### Updating a generated project

When this template gains improvements, pull them into an existing project:

```bash
cd path/to/my-odoo-project
copier update
```

This replays your recorded answers (stored in `.copier-answers.yml`) and
merges template changes, prompting only on conflicts.

## Copier questions

| Question | Default | Notes |
| --- | --- | --- |
| `project_name` | `Odoo Devbox` | README title and shell welcome banner. |
| `odoo_version` | `19.0` | One of `17.0`, `18.0`, `19.0`. Drives clone branches, symlink targets and the version-derived defaults below. |
| `python_version` | `3.11` (17.0) / `3.12` (18.0, 19.0) | Pinned in `devbox.json`. |
| `postgresql_version` | `16` (17.0, 18.0) / `17` (19.0) | Pinned in `devbox.json`. |
| `use_enterprise` | `true` | When false, drops the Enterprise symlink wiring (setup script, README, `addons_path` example). |

The Python/PostgreSQL defaults are computed from `odoo_version` but can be
overridden at the prompt.

## Layout

```
.
├── copier.yml          # Template config + questions
├── README.md           # This file (about the template)
├── scripts/
│   └── render-readme.sh   # regenerates src/README.md from src/README.md.jinja
└── src/                # The project skeleton rendered into generated projects
    ├── devbox.json.jinja
    ├── devbox-setup.sh.jinja
    ├── README.md.jinja    # source of truth for the generated project's README
    ├── README-preview.md  # rendered preview of the above (browsable on GitHub; not copied)
    ├── .copier-answers.yml.jinja
    ├── devbox.lock.jinja        # dispatcher: includes the per-version lock
    ├── devbox.lock.17.0.jinja   # real, full lock for Odoo 17.0  (not copied as-is)
    ├── devbox.lock.18.0.jinja   # real, full lock for Odoo 18.0  (not copied as-is)
    ├── devbox.lock.19.0.jinja   # real, full lock for Odoo 19.0  (not copied as-is)
    ├── scripts/
    └── …
```

Files ending in `.jinja` are rendered (suffix stripped); everything else under
`src/` is copied verbatim.

[src/README-preview.md](src/README-preview.md) is the one file that isn't really
"verbatim": it's a **rendered preview** of [src/README.md.jinja](src/README.md.jinja)
(with default answers) committed only so the generated README is browsable on
GitHub. It never reaches generated projects — its name is `_exclude`d in
`copier.yml` (no `.jinja` renders to that name, so excluding it leaves the real
`README.md` untouched). Regenerate it after editing the `.jinja`:

```bash
scripts/render-readme.sh          # rewrite src/README-preview.md
scripts/render-readme.sh --check  # CI uses this to fail on a stale preview
```

The `README preview in sync` CI job ([.github/workflows/render.yml](.github/workflows/render.yml))
runs `--check` on every push/PR, so a forgotten regeneration fails the build.

`devbox.lock` is shipped **version-specific** so the first `direnv`/devbox entry
is fast for every Odoo version. There is one real, self-contained lock per
version (`devbox.lock.<ver>.jinja`); a tiny dispatcher
([src/devbox.lock.jinja](src/devbox.lock.jinja)) `{% include %}`s the one
matching `odoo_version`, falling back to the 19.0 lock for any unknown version.
The per-version files are excluded from being copied on their own (`_exclude` in
`copier.yml`) — only the dispatcher renders, to a single `devbox.lock`. Across
versions only the `python`/`postgresql` entries differ; the heavier `@latest`
packages (e.g. `gcc`) are identical and stay pinned.

## License

This template is licensed under [AGPL-3.0](LICENSE). Generated projects do **not**
inherit a LICENSE — each project ships its own.
