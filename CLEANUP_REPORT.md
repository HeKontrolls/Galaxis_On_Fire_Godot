# Generated-file cleanup

Scope: active Godot rebuild and original Python project.

Removed: 487.80 MiB across 295 target paths.

## Removed

- Rebuildable PyInstaller intermediate files: 54.85 MiB
- Old extracted/compiled Python build; packaged release ZIP retained: 345.55 MiB
- Regenerable Python bytecode cache: 2.27 MiB
- Temporary extracted video frame samples: 0.12 MiB
- Generated performance log: 0.00 MiB
- Generated test/preview log: 0.21 MiB
- Regenerable offline sound showcase, not gameplay audio: 1.83 MiB
- Unlinked generated preview; capture script retained: 5.57 MiB
- Import cache belonging to removed preview only: 3.80 MiB
- Hash cache belonging to removed preview only: 0.00 MiB
- Import metadata belonging to removed preview only: 0.04 MiB
- ZIP duplicate: every extracted file verified byte-identical by SHA-256: 73.55 MiB

## Preserved

- Game code, runtime assets, all editable Aseprite documents and art archives.
- Current/documented preview images, test scripts and recorded benchmark/reference JSON.
- The packaged Python release ZIP and unique RAR backups.
- Git history, SDKs, installed Godot addons, editor state and conflict-recovery snapshots.
- Existing project saves/settings and external Godot user data.

Rescued 6 packaged-build save/settings files into 3 unique verified copies under `D:\galaxy_game\Galaxis_On_Fire\saves\recovered_build_saves`.

Detailed paths and preserved-save checksums are recorded in `cleanup_manifest.json`.

## Verification

- Net space recovered after preserved save copies and cleanup reports: approximately **487.06 MiB (511 MB)**.
- Verified 733 protected script, runtime-asset, Aseprite-source and existing-save files against their original SHA-256 hashes: all unchanged.
- Confirmed all 295 selected cleanup targets were removed.
- Python source parsing passed for 42 main/system modules.
- Godot `ground_cover_check.gd` passed, including resource loading, mining, passability and save/load.
- Generated-file ignore rules were added for Python and Godot diagnostics.

## Largest material retained

- Original project's Git history: approximately 3,417 MiB.
- Original project's full RAR backup: approximately 2,424 MiB.
- Godot Ziva addon package: approximately 1,525 MiB.
- Original Discord SDK package: approximately 1,326 MiB.

These are history, backups or installed dependencies rather than disposable generated diagnostics. The non-identical Terraria source ZIP was also retained.
