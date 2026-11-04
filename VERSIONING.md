# Build versions and GitHub checkpoints

The first numbered Godot build is **v0.1.0-alpha+build.1**, named **Alchemy and Spellcraft**. It starts from the existing game; earlier commits remain unchanged in history. This version belongs to the game, independently of the Godot engine version.

## Normal uploads

Keep using **Git Commit App.bat**. The existing `.git/Git Commit App.bat` launches the maintained app in the project root, so existing shortcuts still work. The root `Git Commit App.bat`, `git_commit_app.py`, and `tools/git_commit_backend.py` are tracked with the game so the uploader is included in future checkouts.

In the app, select the files to include, enter the commit message and optional detailed description, then click **Commit Build / Retry Upload**. Your author name, email, optional commit timestamp, theme, and Push checkbox still work. The current game version appears below the repository details. Other repositories without this game's versioning helpers retain the app's ordinary Git workflow.

The launcher:

1. Checks that this is the main branch and that GitHub main has no newer work to reconcile.
2. Uses your selected files, commit message, description, author, and optional timestamp.
3. Prepares the next numbered build, synchronizing `version.json`, Godot's application metadata and `CHANGELOG.md`.
4. Commits your selected files and the three required version files with a subject such as `[v0.1.0-alpha+build.2] Improve farming`.
5. Creates an annotated tag with that same version, identifying the exact source checkpoint.
6. Pushes main and pending reachable build tags together with one atomic push.

`version.json`, `project.godot`, and `CHANGELOG.md` are always included, even if their checkboxes are off. All changes in those files are included. Other unchecked files stay out of the commit, and their existing staged changes are preserved. Renames and deletions are supported.

The first upload uses the already-prepared build 1. Later changed uploads advance to build 2, 3, and so on. To retry an upload without making another build, deselect all files, leave the message empty, keep Push enabled, and click **Commit Build / Retry Upload**. Unchecked source changes can remain in your working folder. Prepared version files must be committed before a push-only retry. Uncheck Push to create a local checkpoint without uploading.

If you manually prepared the next version first, the uploader uses it without incrementing twice. If ordinary commits have been added after the last tagged build, a subsequent build commit creates a new numbered checkpoint around those changes.

**Console alternative:** double-click **Commit-And-Push.cmd** in the project root. It asks for a description and includes all changed project files. The existing `.git/Commit-And-Push.cmd` shortcut delegates to that tracked launcher. Its interactive admin-mode behavior is retained; the desktop app does not require elevation.

The game shows the full version in its main menu and window title. Runtime/export metadata comes from `project.godot`, so the version remains available in an exported game without relying on Git or an extra JSON export filter.

This setup does not commit or upload anything until you run the launcher. A tag is a source checkpoint; it does not create a compiled executable or a GitHub Releases page.

## Version format

`0.1.0-alpha+build.1` contains:

- **0.1.0:** major, minor and patch release numbers.
- **alpha:** development channel; beta and rc are also supported. Stable releases omit this part.
- **build.1:** a global increasing build number. It is not reset when the release version or channel changes.

Use build increments for routine uploads, patch increments for a bugfix milestone, minor increments for a feature milestone, and major increments for a major release milestone. Dates are recorded in America/New_York. Build dates and change descriptions are in both the manifest and changelog; Git also records commit author and time.

`version.json` is the source of truth. The helper generates these Godot settings from it:

- `application/config/version`
- `application/config/build_number`
- `application/config/build_name`
- `application/config/build_date`

Do not reuse published build numbers/tags for different contents. The uploader does not force pushes, overwrite remote tags, reset your branch, or discard working changes.

## Preparing a feature or bugfix version

From PowerShell in the project folder:

```powershell
# Feature milestone: 0.1.0-alpha -> 0.2.0-alpha, with the next build number
.\tools\Prepare-Build.ps1 -Bump Minor -Message "Add another planet biome"

# Bugfix milestone: advance the patch release and build number
.\tools\Prepare-Build.ps1 -Bump Patch -Message "Fix cave water rendering"

# Change the release channel while preparing the next build
.\tools\Prepare-Build.ps1 -Channel beta -Message "Begin beta testing"

# Promote a milestone to stable
.\tools\Prepare-Build.ps1 -Bump Minor -Channel stable -Message "First stable release"
```

Preparing only edits version metadata and the changelog. It makes no commit, tag or upload. Review those files, then use the normal upload launcher. A plain `Prepare-Build.ps1 -Message "..."` advances only the build number. For revising notes on a build already prepared but not committed/published, `-ReuseVersion` keeps its existing identity.

If PowerShell's script policy prevents a direct invocation, run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\Prepare-Build.ps1 -Bump Minor -Message "Add another planet biome"
```

## Local checkpoints and recovery

A local-only checkpoint can be made without an upload:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\Commit-And-Push.ps1 -Message "Improve farming" -NoPush -NoPause -NoElevate
```

Run the normal launcher later to upload that same commit and tag. A failed upload preserves local checkpoints. If GitHub has newer commits, the launcher stops before creating the checkpoint so you can pull and reconcile first. A conflicting remote tag is reported and never overwritten; resolve the version collision before publishing.

For a previous build's source, use GitHub's **Tags** list and select the full version, or inspect it locally with:

```powershell
git show 'v0.1.0-alpha+build.1'
```

The tag will exist after that checkpoint is committed by the launcher. Preparing the initial files alone does not create it.

## Checks

`tools/Test-BuildVersioning.ps1` exercises the workflow in isolated repositories and a local bare remote under ignored `.godot/versioning-checks/`. It does not commit, tag or push the real game repository. Tests cover literal commit text, first-build reuse, automatic increments, annotated tags, prepared feature versions, pending tag upload, offline retry, newer remote work, manual commits, patch/stable promotion, conflicting remote tags, wrong branches, invalid manifests and synchronized Godot metadata.

`python tests/test_git_commit_app.py` checks the desktop integration in isolated repositories under `.godot/commit-app-checks/`. It covers selective commits with unchecked staged work, custom author/time/description, literal paths, renames, deletions, upload retry, rejected paths, and the Tk interface and themes. Upload checks use a local bare remote, never the game's GitHub repository.

`tests/build_version_check.gd` verifies the manifest matches Godot runtime/export settings and that the menu label fits. `tests/build_version_preview.gd` renders the menu and reports its window title.
