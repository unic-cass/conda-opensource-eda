"""Run the Anaconda client and report safe stage-endpoint diagnostics."""

import os
import re
import sys

from binstar_client import Binstar
from binstar_client.scripts.cli import main


def show_stage_failure(self, response, *args, **kwargs):
    if response.status_code >= 400 and response.request.url.startswith("https://api.anaconda.org/stage/unic-cass/openems/"):
        print("Stage response:", response.status_code, {key: response.headers.get(key) for key in (
            "content-type", "cf-ray", "cf-mitigated", "x-request-id", "x-anaconda-lockdown",
        )}, file=sys.stderr)
        title = re.search(r"<title>([^<]{1,120})</title>", response.text, flags=re.IGNORECASE)
        if title:
            print("Stage response title:", title[1], file=sys.stderr)
    return original(self, response, *args, **kwargs)


original = Binstar._check_response
Binstar._check_response = show_stage_failure
sys.argv = ["anaconda", "-t", os.environ["ANACONDA_TOKEN"], "upload", "--no-progress", "--user", "unic-cass",
            "--label", "ci-openems-defaults", sys.argv[1]]
raise SystemExit(main())
