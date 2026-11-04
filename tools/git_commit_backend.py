"""Bridge between the desktop commit app and the shared versioned-build uploader."""
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

NO_WINDOW = getattr(subprocess, "CREATE_NO_WINDOW", 0) if os.name == "nt" else 0
VERSION_FILES = ("version.json", "project.godot", "CHANGELOG.md")


def is_versioned_repository(repo):
    root = Path(repo)
    return all((root / name).is_file() for name in (
        "version.json", "tools/Commit-And-Push.ps1", "tools/Build-Version.psm1"))


def read_build_info(repo):
    if not is_versioned_repository(repo):
        return None
    with (Path(repo) / "version.json").open(encoding="utf-8-sig") as source:
        data = json.load(source)
    if not re.fullmatch(r"(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)(?:-(?:alpha|beta|rc))?", str(data.get("version", ""))):
        raise ValueError("Invalid game release version in version.json")
    build = data.get("build")
    if type(build) is not int or build < 1:
        raise ValueError("Invalid build number in version.json")
    return dict(data, tag=f"v{data['version']}+build.{build}")


def run_versioned_commit(repo, message, description, paths, name, email, date, push, log):
    """Use a structured request, with no shell interpolation of user text or paths."""
    root = Path(repo).resolve()
    read_build_info(root)
    executable = shutil.which("powershell.exe") or shutil.which("pwsh")
    if not executable:
        raise RuntimeError("PowerShell is required for this game's versioned uploader.")
    environment = os.environ.copy()
    environment.update(GIT_TERMINAL_PROMPT="0", GIT_AUTHOR_NAME=name,
                       GIT_AUTHOR_EMAIL=email, GIT_COMMITTER_NAME=name,
                       GIT_COMMITTER_EMAIL=email)
    if date:
        environment.update(GIT_AUTHOR_DATE=date, GIT_COMMITTER_DATE=date)
    request = dict(repository=str(root), message=message, description=description,
                   paths=list(paths), push=bool(push), mode="commit" if paths or message else "push")
    filename = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", prefix="galaxis-commit-",
                                         suffix=".json", delete=False) as target:
            filename = target.name
            json.dump(request, target, ensure_ascii=False)
        command = [executable, "-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
                   str(root / "tools/Commit-And-Push.ps1"), "-RequestFile", filename,
                   "-NoPause", "-NoElevate"]
        log("Version metadata and CHANGELOG.md are included automatically.")
        if not paths:
            log("No source files selected: checking the existing checkpoint for upload.")
        with subprocess.Popen(command, cwd=root, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                              text=True, encoding="utf-8", errors="replace", env=environment,
                              creationflags=NO_WINDOW) as process:
            for line in process.stdout:
                if line.strip():
                    log(line.rstrip())
            code = process.wait()
        if code:
            log("Upload/checkpoint stopped. Details are above; existing commits are preserved.")
            return False
        return True
    finally:
        if filename:
            Path(filename).unlink(missing_ok=True)
