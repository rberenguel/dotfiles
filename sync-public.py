#!/usr/bin/env python3
"""Copy the public portions of config files to this repo, using # PUBLIC BELOW as the marker."""

import sys
from pathlib import Path

DOTFILES = Path(__file__).parent
HOME = Path.home()
MARKER = "# PUBLIC BELOW"

FILES = [
    (HOME / ".config/jj/config.toml", DOTFILES / "jj/config.toml"),
    (HOME / ".gitconfig",             DOTFILES / "git/.gitconfig"),
]

errors = False
for src, dst in FILES:
    lines = src.read_text().splitlines()
    try:
        idx = next(i for i, l in enumerate(lines) if l.strip() == MARKER)
    except StopIteration:
        print(f"ERROR: marker '{MARKER}' not found in {src}", file=sys.stderr)
        errors = True
        continue
    dst.write_text("\n".join(lines[idx:]) + "\n")
    print(f"Wrote {dst}")

if errors:
    sys.exit(1)
