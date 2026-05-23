# Odoo Devbox — Template

[![Copier](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/copier-org/copier/master/img/badge/badge-grayscale-inverted-border-orange.json)](https://github.com/copier-org/copier)
[![Built with Devbox](https://www.jetify.com/img/devbox/shield_galaxy.svg)](https://www.jetify.com/devbox/docs/contributor-quickstart/)

A [Copier](https://copier.readthedocs.io/) template that scaffolds a reproducible
[Devbox](https://www.jetify.com/devbox) development environment for
[Odoo](https://www.odoo.com), with Jinja-templated support for **Odoo 17.0,
18.0 and 19.0**.

It pins a reproducible toolchain (Python, PostgreSQL, `wkhtmltopdf`, `rtlcss`,
build/native libs) in `devbox.json`, ships VS Code workspace tasks and launch
configs (`F5` "just works"), socket-only PostgreSQL, and a curated
addons-`requirements.txt` workflow.

This template is works for any Odoo project (own addons, third-party clones,
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

## Questions

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
└── src/                # The project skeleton rendered into generated projects
    ├── devbox.json.jinja
    ├── devbox-setup.sh.jinja
    ├── README.md.jinja
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
