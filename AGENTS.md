# Project instructions

Address the user as John occasionally. The assistant's name is Galaxis bot.

This is the active Godot rebuild of Galaxis on Fire. The neighboring `D:\galaxy_game\Galaxis_On_Fire` directory contains the original Python/Pygame game.

## Sprite workflow

John requires Aseprite for all sprite design and editing from now on.

- Installed executable: `C:\Program Files\Aseprite\Aseprite.exe`.
- Create and revise sprite artwork, palettes, animation frames, and sprite sheets in Aseprite, using its editor, scripting, or batch tools.
- Keep editable `.aseprite` sources under `assets/sprites/source/`, with layers and animation tags. Export runtime PNGs/sheets into the appropriate `assets/sprites/` subdirectory, with animation metadata when needed.
- Match the existing pixel scale, transparency, sprite dimensions, frame order, and gameplay pivots when revising an asset.
- Apply this workflow to new and revised sprites; bring existing art into Aseprite when it is next edited.

## Build and wiki completion requirement

John requires version/build metadata, patch notes, and wiki pages to be kept ready for his Git Commit App after every completed batch of changes.

- Before calling work complete, inspect `version.json` and the version committed at HEAD. Prepare the next build with `tools/Prepare-Build.ps1`; use a minor release increment for a feature milestone, a patch increment for fixes, and a build-only increment for documentation-only work. Keep the current development channel unless John requests a change.
- If the next build is already prepared and uncommitted, reuse that identity with `-ReuseVersion` and accumulate its notes instead of incrementing again for follow-up edits or validation. Never overwrite a committed/published build identity.
- Synchronize `version.json` and `project.godot`, including build name and date (America/New_York), and move completed Unreleased notes into the prepared build's `CHANGELOG.md` entry. Preserve earlier build history.
- Update the affected `docs/wiki/` pages, including version/release notes, and keep `docs/WIKI_COPY_PASTE.md` identical to the standalone pages. Add navigation links when adding pages; verify internal links and version metadata.
- Report the prepared version/build and readiness to commit. John uploads with `Git Commit App.bat` / `git_commit_app.py`; do not commit, tag, push, or publish the wiki unless explicitly asked. The app reuses prepared metadata, so do not prepare a second build just for upload.
