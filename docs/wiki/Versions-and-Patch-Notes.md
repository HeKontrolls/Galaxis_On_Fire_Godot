# Versions and Patch Notes

Galaxis on Fire is in active alpha development. Build identities help match a game session, bug report, or source checkpoint to the work it contains.

## Current prepared build

**v0.3.0-alpha+build.4 - Mining Guardian and Planet Danger**

**Build date:** November 5, 2026

**Status:** Prepared locally for commit; this page does not imply the build has been uploaded or released.

- [Ruined Mining Guardian](Mining-Guardian): 360 HP, a warned drill charge and ground slam, recovery windows, larger new-game chambers, and a boss HUD.
- Aseprite guardian animations, the unique Faultline Hammer, and the Survey Core.
- An optional ship survey-array upgrade that reveals broad resource forecasts in planet selection.
- Climate-based Danger 1-3 ratings, stronger hostile creatures, and increased normal material drops on harsher planets.
- Persistent rewards, guardian state, and ship upgrades; safe legacy-save migration and host-authoritative multiplayer attacks.

Checks passed: 95 guardian/danger checks, 229 weapon/night assertions, 170 equipment assertions, 70 two-process multiplayer checks, and 3 generated-chamber checks. Aseprite sources and exports were compared pixel for pixel. Multiplayer verification used two local processes, not a cross-PC or larger-group test. The preceding build, **v0.2.0-alpha+build.3 - Arms, Armor and Night Encounters**, added melee weapons, night encounters, armor, shields, and accessories.

## Reading the version

The prepared version `v0.3.0-alpha+build.4` contains:

- **0.3.0:** Release version: major, minor, and patch numbers.
- **alpha:** Development channel. Beta and release-candidate channels are also supported.
- **build.4:** The increasing build number for that checkpoint.

The game version appears in its main menu and window title. It is separate from the Godot engine's version. Multiplayer checks the game build when joining.

## Patch notes

[CHANGELOG.md](https://github.com/HeKontrolls/Galaxis_On_Fire_Godot/blob/main/CHANGELOG.md) contains the numbered build history and notes about additions, improvements, fixes, and verification.

The earlier build, `v0.1.0-alpha+build.2`, added hosting/joining, shared-world synchronization, guest saves and reconnection, the combined HP/MP panel, and improved raised-ally spacing.

## For contributors: changing build info

`version.json` in the project root holds the release version, build number, name, and date. The preparation helper synchronizes that information into Godot's runtime settings and the changelog.

From the project folder:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\Prepare-Build.ps1 -Message "Name of the next build"
```

Use `-Bump Patch`, `-Bump Minor`, or `-Bump Major` for a release-number change. Use `-ReuseVersion` when revising an already-prepared build without advancing its number again.

## Keeping changes ready to commit

Each completed change batch includes synchronized version/build metadata, numbered patch notes, affected wiki pages, and the copy-and-paste pack. Follow-up edits reuse an already-prepared, uncommitted build rather than consuming another build number.

## Uploading a checkpoint

Git Commit App uses selected source files plus required version metadata. It commits the build and creates its annotated version tag when you submit the checkpoint. A prepared build is reused rather than incremented twice. The commit message becomes the final build name.

Preparing metadata does not upload it. A source tag also does not automatically produce a compiled game or publish a GitHub Release. GitHub wiki pages are maintained separately from the main project's files.

[Home](Home) · [Wiki Index](Wiki-Index) · [Game Repository](https://github.com/HeKontrolls/Galaxis_On_Fire_Godot)
