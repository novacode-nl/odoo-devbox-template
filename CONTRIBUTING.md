# Contributing to odoo-devbox-template

First off, thank you for taking the time to contribute! Contributions are
welcome and appreciated — bug reports, feature requests, documentation
improvements, and code.

This project is a [Copier](https://copier.readthedocs.io/) template that
scaffolds a reproducible [Devbox](https://www.jetify.com/devbox) development
environment for [Odoo](https://www.odoo.com) (17.0, 18.0 and 19.0). It is open
source and released under the [AGPL-3.0 License](LICENSE).

## Code of Conduct

Please be respectful and constructive in all interactions. We expect everyone
participating in this project to help keep the community welcoming and friendly.

## How to Contribute

### Reporting Bugs

Before opening a new issue, please search the
[existing issues](https://github.com/novacode-nl/odoo-devbox-template/issues) to
avoid duplicates.

When filing a bug report, include:

- A clear, descriptive title.
- Steps to reproduce the problem — ideally the exact `copier copy` / `copier
  update` command and the answers you gave.
- What you expected to happen and what actually happened.
- The `odoo_version` you targeted (`17.0`, `18.0` or `19.0`) and whether
  `use_enterprise` was on or off.
- Your [Copier](https://copier.readthedocs.io/) version (`copier --version`) and
  host OS.
- The relevant rendered output (e.g. the generated `devbox.json`, `devbox.lock`,
  `devbox-setup.sh` or `README.md`) or a snippet of the template that triggers
  the issue, if possible.

### Suggesting Enhancements

Open an issue describing the enhancement, the use case it addresses, and any
alternatives you have considered.

### Submitting Changes

1. Fork the repository and create your branch from `main`.
2. Set up a development environment (see below).
3. Make your changes, following the project's coding style and conventions.
4. Verify the template still renders cleanly for every supported Odoo version
   (see [Rendering & Testing](#rendering--testing)).
5. If you changed `src/README.md.jinja`, regenerate the committed preview with
   `scripts/render-readme.sh`.
6. Commit your work with clear, descriptive commit messages.
7. Open a pull request against the `main` branch, describing what your change
   does and why.

## Development Setup

Clone the repository and install Copier (no editable install is needed — this
repo *is* the template, not an installable package):

```sh
git clone git@github.com:novacode-nl/odoo-devbox-template.git
cd odoo-devbox-template
pipx install copier        # or: uv tool install copier
```

How the template is laid out:

- `src/` — the project skeleton. Files ending in `.jinja` are rendered (and the
  suffix stripped) into generated projects; everything else is copied verbatim.
  This is `_subdirectory` in `copier.yml`, so the repo root (this file, `LICENSE`,
  `copier.yml`) never ships into generated projects.
- `copier.yml` — template settings and the questions asked at generation time.
- `scripts/render-readme.sh` — regenerates `src/README-preview.md`, a committed,
  GitHub-browsable preview of `src/README.md.jinja` rendered with default answers.
- `.github/` — CI workflows and `.github/scripts/check_render.py`, the render
  validator.

## Rendering & Testing

There is no unit-test suite; the template is validated by rendering it and
checking the output. CI ([.github/workflows/render.yml](.github/workflows/render.yml))
runs the following for Odoo `17.0`, `18.0` and `19.0` on every push and PR —
please run the equivalent locally before opening a PR.

Render the template for a given version:

```sh
copier copy --defaults --vcs-ref=HEAD --data odoo_version=18.0 . /tmp/out
```

> `--vcs-ref=HEAD` renders the *current* source. Without it, once a release tag
> exists Copier defaults to the latest tag instead of your working tree.

Validate the rendered project (per-version Python/PostgreSQL, lock file, etc.):

```sh
# matrix: 17.0 → py 3.11 / pg 16   |   18.0 → py 3.12 / pg 16   |   19.0 → py 3.12 / pg 17
python .github/scripts/check_render.py /tmp/out 18.0 3.12 16
```

Check the generated shell scripts parse:

```sh
for f in /tmp/out/devbox-setup.sh /tmp/out/scripts/*.sh; do bash -n "$f"; done
```

Confirm the README preview is in sync with `src/README.md.jinja`:

```sh
scripts/render-readme.sh --check     # exits non-zero (and shows a diff) if stale
scripts/render-readme.sh             # regenerate src/README-preview.md in place
```

If your change touches Enterprise wiring, also render with
`--data use_enterprise=false` and confirm no Enterprise references leak into the
generated `devbox-setup.sh` or `README.md`.

## Coding Guidelines

- Keep changes focused; one logical change per pull request.
- Match the existing code style and naming conventions (linting is not currently
  enforced, but will be added later — we're aiming for consistency across the
  codebase).
- Remember the template is rendered with Jinja: changes to `.jinja` files must
  keep the **rendered** output valid for all supported Odoo versions
  (`17.0`/`18.0`/`19.0`) and for both `use_enterprise` settings.
- When you change `src/README.md.jinja`, regenerate `src/README-preview.md` with
  `scripts/render-readme.sh` and commit the result (CI fails on a stale preview).
- Include the project copyright header on new source files (keep the original
  year or add the current year, e.g. `2026-2027`):

  ```python
  # Copyright 2026 Nova Code (https://www.novaforms.io)
  # License AGPL-3.0 or later (https://www.gnu.org/licenses/agpl-3.0.html).
  ```

- Update documentation when you change behavior.

## Contributor License Agreement (CLA)

Before we can accept your contribution, we ask that you sign a Contributor
License Agreement (CLA). This protects both you and the project, and ensures we
have the rights necessary to distribute your contribution under the project's
license.

To request the Agreement, please send an email to
[cla@novaforms.io](mailto:cla@novaforms.io). We will reply with the appropriate
document to sign.

There are two forms of the Agreement:

- **Individual Contributor License Agreement (ICLA).** The ICLA
  (“CLA”) concerns a modified version of the
  [Apache Software Foundation Individual Contributor License Agreement v2.2](https://apache.org/licenses/icla.pdf).
  Sign this if you are contributing as an individual.

- **Corporate Contributor License Agreement (CCLA).** The CCLA
  (“CLA”) concerns a modified version of the
  [Apache Software Foundation Software Grant and Corporate Contributor License Agreement v r190612](https://apache.org/licenses/cla-corporate.pdf).
  Sign this if you are contributing on behalf of an employer or other
  organization.

We are unable to merge contributions until the relevant CLA has been signed.

## License

By contributing, you agree that your contributions will be licensed under the
[AGPL-3.0 License](LICENSE) that covers this project. Note that generated
projects do **not** inherit this LICENSE — each project ships its own.

Copyright 2026 Nova Code ([https://www.novaforms.io](https://www.novaforms.io))
