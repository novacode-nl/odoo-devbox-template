# Odoo Devbox — Copier template

A [Copier](https://copier.readthedocs.io/) template that scaffolds a reproducible
[Devbox](https://www.jetify.com/devbox) development environment for
[Odoo](https://www.odoo.com), with Jinja-templated support for **Odoo 17.0,
18.0 and 19.0**.

It pins a reproducible toolchain (Python, PostgreSQL, Node.js, `wkhtmltopdf`,
`lessc`, `rtlcss`, build/native libs) in `devbox.json`, ships VS Code workspace
tasks and launch configs (`F5` "just works"), socket-only PostgreSQL, and a
curated addons-`requirements.txt` workflow.

This template is **not OCA-specific** — it works for any Odoo project (own
addons, third-party clones, with or without Enterprise). The structure is
inspired in part by
[oca-addons-repo-template](https://github.com/OCA/oca-addons-repo-template).

## Usage

Install Copier (`pipx install copier` or `uv tool install copier`), then:

```bash
# Generate a new project
copier copy gh:<org>/odoo-devbox path/to/my-odoo-project

# …or from a local clone of this template
copier copy /path/to/odoo-devbox path/to/my-odoo-project
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
| `nodejs_version` | `20` | Pinned in `devbox.json`. |
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
    ├── scripts/
    └── …
```

Files ending in `.jinja` are rendered (suffix stripped); everything else under
`src/` is copied verbatim. `devbox.lock` is intentionally not shipped — it is
version-pinned and regenerated per project by `devbox install`.

## License

See [src/LICENSE](src/LICENSE) (AGPL-3.0), which is also shipped into generated
projects.
