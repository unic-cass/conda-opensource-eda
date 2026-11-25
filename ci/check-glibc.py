#!/usr/bin/env python3
"""Check that installed Linux ELF files can use the EL8 glibc (2.28)."""

import argparse
import json
import os
import re
import subprocess
from pathlib import Path


def required_glibc(path):
    with path.open("rb") as stream:
        if stream.read(4) != b"\x7fELF":
            return set()
    output = subprocess.check_output(["readelf", "-VW", path], text=True, env={**os.environ, "LC_ALL": "C"})
    # These are imported versions; do not count definitions exported by a DSO.
    needs = output.partition("Version needs section")[2]
    return set(re.findall(r"\bName: GLIBC_([\w.]+)", needs))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("prefix", type=Path)
    parser.add_argument("--package", help="Check just this Conda package")
    args = parser.parse_args()
    records = [json.loads(path.read_text()) for path in (args.prefix / "conda-meta").glob("*.json")]
    if args.package:
        records = [record for record in records if record["name"] == args.package]
    if not records:
        parser.error(f"No matching Conda package records under {args.prefix}")

    failed = False
    for record in records:
        for file in record["files"]:
            # This glibc is compiler input, not the installer's runtime loader.
            if file.startswith("x86_64-conda-linux-gnu/sysroot/"):
                continue
            path = args.prefix / file
            if path.is_symlink() or not path.is_file():
                continue
            for version in sorted(required_glibc(path)):
                if not re.fullmatch(r"\d+(\.\d+)+", version) or tuple(map(int, version.split("."))) > (2, 28):
                    print(f"{record['name']}: {file} requires GLIBC_{version}")
                    failed = True
    if not failed:
        print(f"EL8 glibc check passed: {args.package or args.prefix} ({len(records)} packages)")
    return int(failed)


if __name__ == "__main__":
    raise SystemExit(main())
