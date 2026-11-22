"""Check a clean LibreLane environment uses the intended native variants."""

import json
import sys
from pathlib import Path

import klayout.db
import libparse

version = sys.argv[1]
actual = f"{sys.version_info.major}.{sys.version_info.minor}"
if actual != version:
    sys.exit(f"Expected Python {version}, got {actual}")

suffix = "_py" + version.replace(".", "")
records = (json.loads(path.read_text()) for path in Path(sys.prefix, "conda-meta").glob("*.json"))
builds = {record["name"]: record["build"] for record in records}
for name in ("yosys", "openroad", "klayout", "libparse", "symbiyosys"):
    build = builds.get(name, "not installed")
    if not build.endswith(suffix):
        sys.exit(f"Expected {name} build ending in {suffix}, got {build}")
    print(f"{name}: {build}")
