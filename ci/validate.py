#!/usr/bin/env python3
"""Check the native recipes selected by Build.yml without rendering sources."""

import re
import sys
from pathlib import Path

import yaml


class UniqueKeysLoader(yaml.SafeLoader):
    def construct_mapping(self, node, deep=False):
        self.flatten_mapping(node)
        result = {}
        for key_node, value_node in node.value:
            key = self.construct_object(key_node, deep=deep)
            if key in result:
                raise yaml.constructor.ConstructorError(
                    None, None, f"duplicate key {key!r}", key_node.start_mark
                )
            result[key] = self.construct_object(value_node, deep=deep)
        return result


def load_yaml(path):
    with path.open() as stream:
        return yaml.load(stream, Loader=UniqueKeysLoader)


def check_recipe(recipe):
    meta = recipe / "meta.yaml"
    if not meta.is_file():
        raise ValueError(f"missing {meta}")
    # A source-free check; conda-build handles Jinja, selectors and rendering.
    build = re.search(r"(?m)^build:[^\n]*\n(?:[ \t].*\n|\n|#.*\n)*", meta.read_text() + "\n")
    if (recipe / "build.sh").is_file() and build and re.search(r"(?m)^  script:", build[0]):
        raise ValueError(f"{meta}: use either build.sh or build/script, not both")
    for condarc in (recipe / "condarc", recipe / "condarc_linux"):
        if not condarc.exists():
            continue
        config = load_yaml(condarc)
        if not isinstance(config, dict):
            raise ValueError(f"{condarc}: expected a mapping")
        channels = config.get("channels")
        if not isinstance(channels, list) or not channels or not all(
            isinstance(channel, str) and channel.strip() for channel in channels
        ):
            raise ValueError(f"{condarc}: expected a non-empty list of channel names or URLs")
        if config.get("channel_priority", "strict") not in ("strict", "flexible", "disabled"):
            raise ValueError(f"{condarc}: invalid channel_priority")


def main():
    workflow = Path(".github/workflows/Build.yml")
    jobs = load_yaml(workflow)["jobs"]
    recipes = set()
    for name, job in jobs.items():
        if not any(step.get("uses") == "./ci" for step in job.get("steps", [])):
            continue
        package = job.get("env", {}).get("PACKAGE")
        if not isinstance(package, str):
            raise ValueError(f"{workflow}: {name} must set PACKAGE to a recipe directory")
        recipes.add(Path(package))
    for recipe in sorted(recipes):
        check_recipe(recipe)
    print(f"Checked {len(jobs)} workflow jobs and {len(recipes)} native recipes.")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, yaml.YAMLError) as exc:
        sys.exit(str(exc))
