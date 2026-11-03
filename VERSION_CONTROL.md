# Version control

This active Godot rebuild has its own local Git repository on `main`. The neighboring original Python project already has a separate Git repository. Keep their histories independent.

Track game scripts, scenes, project settings, tests, documentation, layered Aseprite sources, exported PNG sheets, animation metadata and Godot `.uid` files. The `.godot` cache, regenerated imports, exports, temporary files, local credentials and the independently installed `addons/ziva_agent` editor package are ignored. That optional package is not required to run the game.

The initial commit captures the working game before the furnishings feature. Later feature commits provide reviewable checkpoints. The `origin` remote is [HeKontrolls/Galaxis_On_Fire_Godot](https://github.com/HeKontrolls/Galaxis_On_Fire_Godot). Its starter README commit is merged with the local game history; `main` tracks `origin/main`.

Useful commands from this project folder:

```powershell
git status
git diff
git log --oneline --decorate -8
git add scripts assets tools tests README.md
git commit -m "Describe the gameplay change"
git push
```

Create a feature branch before a larger experiment with `git switch -c feature/short-name`. Switch back with `git switch main`. Inspect changes before committing; Git history does not include user saves stored in Godot's app-data directory. Commits are local until `git push` uploads them. Use `git pull --ff-only` to receive remote updates when the branch has not diverged.
