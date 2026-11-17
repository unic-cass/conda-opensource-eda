# Adding lln-libparse recipe (draft — recipe.yaml pending the license question)

See `lln-libparse-pr.md` for the PR description.

Open items before the recipe.yaml can be finalized:
1. License file handling for the sdist (no LICENSE file shipped; Apache-2.0
   per Readme/PKG-INFO).
2. Whether to depend on `yosys` for the build (the wrapper only needs
   headers bundled in the sdist — no).
