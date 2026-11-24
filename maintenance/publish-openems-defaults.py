"""Preflight and verify publication of the exact tested openEMS archives."""

from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
import os
from pathlib import Path
import sys
import time
from urllib.error import HTTPError, URLError
from urllib.parse import quote
from urllib.request import Request, urlopen

OWNER = "unic-cass"
# Leave room for channel metadata changes or concurrent uploads.
TARGET = 2_985_000_000
HERE = Path(__file__).parent


def read(name):
    return json.loads((HERE / name).read_text())


def api(path):
    headers = {"Accept": "application/json", "Cache-Control": "no-cache"}
    url = f"https://api.anaconda.org/{path}?check={time.time_ns()}"
    for attempt in range(4):
        try:
            with urlopen(Request(url, headers=headers), timeout=45) as resp:
                return json.load(resp)
        except HTTPError as exc:
            if exc.code not in (429, 500, 502, 503, 504) or attempt == 3:
                raise RuntimeError(f"GET {path}: HTTP {exc.code}") from None
        except (URLError, TimeoutError):
            if attempt == 3:
                raise RuntimeError(f"GET {path}: request failed") from None
        time.sleep(2 ** attempt)


def inventory():
    names = [d["name"] for d in api(f"packages/{OWNER}")]
    with ThreadPoolExecutor(max_workers=8) as pool:
        data = pool.map(lambda name: api(f"package/{OWNER}/{quote(name, safe='')}"), names)
        return {x["basename"]: x for package in data for x in package["files"]}


def verify(row, live, label="main"):
    if not live or any(live.get(key) != row[key] for key in ("basename", "sha256", "size", "version")):
        raise ValueError("File absent or changed: " + row["basename"])
    if label not in live["labels"]:
        raise ValueError(f"File is not on {label}: " + row["basename"])


def count_bytes(live):
    return sum(x["size"] for x in live.values())


def plan(artifacts, protected):
    files = {p["basename"]: HERE / "artifacts" / Path(p["basename"]).name for p in artifacts}
    for p in artifacts:
        file = files[p["basename"]]
        digest = hashlib.sha256()
        with file.open("rb") as stream:
            for block in iter(lambda: stream.read(2 ** 20), b""):
                digest.update(block)
        if file.stat().st_size != p["size"] or digest.hexdigest() != p["sha256"]:
            raise ValueError("Archive checksum mismatch: " + p["basename"])
    live = inventory()
    for p in protected:
        verify(p, live.get(p["basename"]))
    pending = []
    new_bytes = 0
    for p in artifacts:
        current = live.get(p["basename"])
        if current and "main" in current["labels"]:
            verify(p, current)
            continue
        if current:
            label = f"ci-openems-defaults-{os.environ['GITHUB_RUN_ID']}"
            verify(p, current, label)
            if set(current["labels"]) != {label}:
                raise ValueError("Unexpected labels for " + p["basename"])
        else:
            new_bytes += p["size"]
        pending.append(Path(p["basename"]).name)
    today = count_bytes(live)
    projected = today + new_bytes
    print(f"Channel: {today:,} bytes; upload {len(pending)} builds; projected {projected:,} bytes")
    if projected > TARGET:
        raise ValueError("Channel does not have enough free space for the remaining builds")
    with open(os.environ["GITHUB_OUTPUT"], "a") as output:
        print("pending=" + " ".join(pending), file=output)


def verify_channel(artifacts, protected):
    for attempt in range(10):
        live = inventory()
        if all("main" in live.get(p["basename"], {}).get("labels", []) for p in artifacts):
            break
        time.sleep(3)
    for p in artifacts + protected:
        verify(p, live.get(p["basename"]))
    final = count_bytes(live)
    if final >= 3_000_000_000:
        raise ValueError(f"Final channel is over quota: {final:,} bytes")
    print(f"Verified all three builds on main; final channel size {final:,} bytes")


if __name__ == "__main__":
    artifacts = read("openems-artifacts.json")
    if len(artifacts) != 3 or {p["basename"] for p in artifacts} != {
        f"linux-64/openems-0.37.0-py{py}_defaults_1.conda" for py in (313, 314, 315)
    }:
        raise ValueError("Unexpected build artifacts")
    {"plan": plan, "verify": verify_channel}[sys.argv[1]](artifacts, read("protected.json"))
