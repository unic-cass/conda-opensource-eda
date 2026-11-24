"""Publish exact tested archives after pruning only approved, backed-up rebuilds."""

from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
import os
from pathlib import Path
import subprocess
import time
from urllib.error import HTTPError, URLError
from urllib.parse import quote
from urllib.request import Request, urlopen

OWNER = "unic-cass"
# Leave room for channel metadata changes or concurrent uploads.
TARGET = 2_985_000_000
HERE = Path(__file__).parent
DRY_RUN = os.environ.get("ACT") == "true"
TOKEN = "" if DRY_RUN else os.environ["ANACONDA_TOKEN"]


def read(name):
    return json.loads((HERE / name).read_text())


def api(path, method="GET", missing_ok=False):
    if method != "GET" and (DRY_RUN or not TOKEN):
        raise RuntimeError("Anaconda writes are disabled")
    headers = {"Accept": "application/json", "Cache-Control": "no-cache"}
    if TOKEN:
        headers["Authorization"] = "token " + TOKEN
    url = "https://api.anaconda.org/" + path
    if method == "GET":
        url += "?check=" + str(time.time_ns())
    for attempt in range(4):
        try:
            with urlopen(Request(url, headers=headers, method=method), timeout=45) as resp:
                return json.load(resp) if method == "GET" else None
        except HTTPError as exc:
            if exc.code == 404 and missing_ok:
                return None
            if exc.code not in (429, 500, 502, 503, 504) or attempt == 3:
                raise RuntimeError(f"{method} {path}: HTTP {exc.code}") from None
        except (URLError, TimeoutError):
            if attempt == 3:
                raise RuntimeError(f"{method} {path}: request failed") from None
        time.sleep(2 ** attempt)


def inventory():
    names = [d["name"] for d in api(f"packages/{OWNER}")]
    with ThreadPoolExecutor(max_workers=8) as pool:
        data = pool.map(lambda name: api(f"package/{OWNER}/{quote(name, safe='')}"), names)
        return {x["basename"]: x for package in data for x in package["files"]}


def package_path(row):
    return "dist/" + "/".join(quote(piece, safe="") for piece in (
        OWNER, row["package"], row["version"], *row["basename"].split("/"),
    ))


def verify(row, live):
    if not live or any(live.get(key) != row[key] for key in ("basename", "sha256", "size", "version")):
        raise ValueError("File absent or changed: " + row["basename"])
    if "main" not in live["labels"]:
        raise ValueError("File is not on main: " + row["basename"])


def count_bytes(live):
    return sum(x["size"] for x in live.values())


def publish():
    candidates, receipt = read("candidates.json"), read("verified-backup.json")
    artifacts = read("openems-artifacts.json")
    protected = read("protected.json")
    if {p["basename"] for p in artifacts} != {
        f"linux-64/openems-0.37.0-py{py}_defaults_1.conda" for py in (313, 314, 315)
    } or len(artifacts) != 3:
        raise ValueError("Unexpected build artifacts")
    if receipt != {x["basename"]: x["sha256"] for x in candidates}:
        raise ValueError("Backup receipt does not cover all deletion candidates")
    if {p["basename"] for p in protected} & receipt.keys():
        raise ValueError("Protected file in candidate list")

    files = {p["basename"]: HERE / "artifacts" / Path(p["basename"]).name for p in artifacts}
    for p in artifacts:
        file = files[p["basename"]]
        digest = hashlib.sha256()
        with file.open("rb") as stream:
            for block in iter(lambda: stream.read(2 ** 20), b""):
                digest.update(block)
        if file.stat().st_size != p["size"] or digest.hexdigest() != p["sha256"]:
            raise ValueError("Archive checksum mismatch: " + p["basename"])
    if not DRY_RUN:
        # Fail before deleting if the publishing token cannot authenticate.
        api("user")

    live = inventory()
    for p in protected:
        verify(p, live.get(p["basename"]))
    pending = []
    for p in artifacts:
        if p["basename"] in live:
            verify(p, live[p["basename"]])
        else:
            pending.append(p)
    today = count_bytes(live)
    projected = today + sum(x["size"] for x in pending)
    remove = []
    for row in candidates:
        if projected <= TARGET:
            break
        name = row["basename"]
        if name not in live:
            continue
        verify(row, live[name])
        if set(live[name]["labels"]) != set(row["labels"]):
            raise ValueError("File labels changed: " + name)
        keep = row["replacement"]
        verify(keep, live.get(keep["basename"]))
        if keep["basename"] in receipt:
            raise ValueError("Required replacement is a deletion candidate")
        remove.append(row)
        projected -= row["size"]
    if projected > TARGET:
        raise ValueError("Approved duplicates cannot reclaim sufficient storage")
    print(f"Channel: {today:,} bytes; plan: remove {len(remove)} files; publish {len(pending)} builds; final {projected:,} bytes")
    if DRY_RUN:
        for row in remove:
            print("Would remove", row["basename"], "keeping", row["replacement"]["basename"])
        return

    for row in remove:
        path = package_path(row)
        current = api(path, missing_ok=True)
        if current is None:
            continue
        verify(row, current)
        if set(current["labels"]) != set(row["labels"]):
            raise ValueError("File labels changed before deletion: " + row["basename"])
        verify(row["replacement"], api(package_path(row["replacement"])))
        api(path, "DELETE", missing_ok=True)
        print("Removed", row["basename"])
    before_upload = inventory()
    if count_bytes(before_upload) + sum(x["size"] for x in pending) >= 3_000_000_000:
        raise ValueError("Channel does not have room after pruning")
    for p in pending:
        subprocess.run(["anaconda", "-t", TOKEN, "upload", "--no-progress", "--user", OWNER,
                        "--label", "main", str(files[p["basename"]])], check=True)
    for attempt in range(10):
        live = inventory()
        if all(p["basename"] in live for p in artifacts):
            break
        time.sleep(3)
    for p in artifacts + protected:
        verify(p, live.get(p["basename"]))
    final = count_bytes(live)
    if final >= 3_000_000_000:
        raise ValueError(f"Final channel is over quota: {final:,} bytes")
    print(f"Verified all three builds on main; final channel size {final:,} bytes")


if __name__ == "__main__":
    publish()
