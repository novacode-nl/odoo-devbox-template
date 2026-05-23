#!/usr/bin/env python3
"""Validate a Copier-rendered project. Usage:

    check_render.py <rendered_dir> <odoo_version> <expected_python> <expected_pg>

Mirrors the checks we run by hand: correct per-version python/postgresql,
nodejs/lessc dropped, rtlcss kept, exactly one valid-JSON devbox.lock, no
LICENSE shipped, answers file present, and no leftover .jinja files.
"""
import glob
import json
import os
import sys

out, odoo, expect_py, expect_pg = sys.argv[1:5]
errs = []

# --- devbox.json ---
dj = json.load(open(f"{out}/devbox.json"))["packages"]
if dj.get("python") != expect_py:
    errs.append(f"devbox.json python={dj.get('python')!r} (expected {expect_py})")
if dj.get("postgresql") != expect_pg:
    errs.append(f"devbox.json postgresql={dj.get('postgresql')!r} (expected {expect_pg})")
for pkg in ("nodejs", "lessc"):
    if pkg in dj:
        errs.append(f"devbox.json should not contain {pkg}")
if "rtlcss" not in dj:
    errs.append("devbox.json missing rtlcss")

# --- devbox.lock: exactly one file, valid JSON, version-correct ---
locks = sorted(glob.glob(f"{out}/devbox.lock*"))
if locks != [f"{out}/devbox.lock"]:
    errs.append(f"expected only devbox.lock, found {[os.path.basename(p) for p in locks]}")
else:
    dl = json.load(open(f"{out}/devbox.lock"))["packages"]
    if f"python@{expect_py}" not in dl:
        errs.append(f"lock missing python@{expect_py}")
    if f"postgresql@{expect_pg}" not in dl:
        errs.append(f"lock missing postgresql@{expect_pg}")
    if "gcc@latest" not in dl:
        errs.append("lock missing gcc@latest")
    leaked = [k for k in dl if k.startswith(("nodejs@", "lessc@"))]
    if leaked:
        errs.append(f"lock still contains {leaked}")

# --- other invariants ---
if os.path.exists(f"{out}/LICENSE"):
    errs.append("LICENSE should not be shipped into generated projects")
if not os.path.exists(f"{out}/.copier-answers.yml"):
    errs.append(".copier-answers.yml missing")
leftover = glob.glob(f"{out}/**/*.jinja", recursive=True)
if leftover:
    errs.append(f"leftover .jinja files: {leftover}")

if errs:
    print(f"FAIL (Odoo {odoo}):")
    for e in errs:
        print("  -", e)
    sys.exit(1)
print(f"OK: Odoo {odoo} -> python {expect_py}, postgresql {expect_pg}")
