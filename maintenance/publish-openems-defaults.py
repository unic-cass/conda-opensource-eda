"""Publish the exact tested archives without deleting any existing files."""

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


def api(path, method="GET", payload=None):
    if method != "GET" and (DRY_RUN or not TOKEN):
        raise RuntimeError("Anaconda writes are disabled")
    headers = {"Accept": "application/json", "Cache-Control": "no-cache"}
    if TOKEN:
        headers["Authorization"] = "token " + TOKEN
    body = None
    if payload is not None:
        headers["Content-Type"] = "application/json"
        body = json.dumps(payload).encode()
    url = "https://api.anaconda.org/" + path
    if method == "GET":
        url += "?check=" + str(time.time_ns())
    for attempt in range(4):
        try:
            with urlopen(Request(url, body, headers=headers, method=method), timeout=45) as resp:
                return json.load(resp) if method == "GET" else None
        except HTTPError as exc:
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


def check_credentials():
    if not TOKEN:
        raise ValueError("ANACONDA_TOKEN is empty")
    api("user")
    print("Anaconda.org accepted the token for the current-user endpoint")
    try:
        scopes = api("authentication").get("scopes")
    except RuntimeError as error:
        print(f"Token scope lookup unavailable: {error}")
        return
    if isinstance(scopes, list):
        documented = {"all", "api", "api:write", "conda"}
        print("Recognized upload-related scopes:", ", ".join(s for s in sorted(documented) if s in scopes) or "none")
    else:
        print("Anaconda.org did not return a token scope list")


def verify(row, live):
    if not live or any(live.get(key) != row[key] for key in ("basename", "sha256", "size", "version")):
        raise ValueError("File absent or changed: " + row["basename"])
    if "main" not in live["labels"]:
        raise ValueError("File is not on main: " + row["basename"])


def count_bytes(live):
    return sum(x["size"] for x in live.values())


def publish():
    artifacts = read("openems-artifacts.json")
    protected = read("protected.json")
    if {p["basename"] for p in artifacts} != {
        f"linux-64/openems-0.37.0-py{py}_defaults_1.conda" for py in (313, 314, 315)
    } or len(artifacts) != 3:
        raise ValueError("Unexpected build artifacts")

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
        check_credentials()

    live = inventory()
    for p in protected:
        verify(p, live.get(p["basename"]))
    pending = []
    staged = []
    for p in artifacts:
        if p["basename"] in live:
            if "main" in live[p["basename"]]["labels"]:
                verify(p, live[p["basename"]])
            elif live[p["basename"]]["labels"] == ["ci-openems-defaults"]:
                verify(p, {**live[p["basename"]], "labels": ["main"]})
                staged.append(p)
            else:
                raise ValueError("Unexpected labels for " + p["basename"])
        else:
            pending.append(p)
    today = count_bytes(live)
    projected = today + sum(x["size"] for x in pending)
    print(f"Channel: {today:,} bytes; upload {len(pending)} builds; projected {projected:,} bytes")
    if projected > TARGET:
        raise ValueError("Channel does not have enough free space for the remaining builds")
    if DRY_RUN:
        return

    for p in pending:
        subprocess.run(["python3", str(HERE / "upload-openems.py"), str(files[p["basename"]])], check=True)
    for p in pending + staged:
        api(f"channels/{OWNER}/main", "POST", payload={"package": "openems", "version": p["version"], "basename": p["basename"]})
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
    publish()
