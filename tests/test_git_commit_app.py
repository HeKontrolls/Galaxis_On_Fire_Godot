"""Integration tests use disposable Git repositories and a local file remote only."""
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import sys
import unittest
import uuid
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from git_commit_backend import read_build_info, run_versioned_commit


def git(repo, *args, check=True):
    result = subprocess.run(["git", "-C", str(repo), *args], capture_output=True, text=True,
                            encoding="utf-8", errors="replace",
                            creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
    if check and result.returncode:
        raise AssertionError(result.stderr)
    return result.stdout.strip()


class CommitAppTests(unittest.TestCase):
    def setUp(self):
        self.case = ROOT / ".godot" / "commit-app-checks" / uuid.uuid4().hex
        self.repo = self.case / "working copy"
        self.remote = self.case / "origin.git"
        (self.repo / "tools").mkdir(parents=True)
        for path in ("version.json", "project.godot", "CHANGELOG.md", "tools/Build-Version.psm1",
                     "tools/Commit-And-Push.ps1"):
            shutil.copy2(ROOT / path, self.repo / path)
        self.selected = 'selected [hero] $coins.txt'
        (self.repo / self.selected).write_text("old selection", encoding="utf-8")
        (self.repo / "unchecked.txt").write_text("old unchecked", encoding="utf-8")
        git(self.repo, "init", "-q", "-b", "main")
        git(self.repo, "config", "user.name", "Fixture Identity")
        git(self.repo, "config", "user.email", "fixture@example.invalid")
        git(self.repo, "config", "core.autocrlf", "false")
        git(self.repo, "add", ".")
        git(self.repo, "commit", "-q", "-m", "Baseline")
        git(self.repo, "tag", "-a", "v0.1.0-alpha+build.1", "-m", "Baseline build")
        self.base = git(self.repo, "rev-parse", "HEAD")
        git(self.case, "init", "--bare", "-q", str(self.remote))
        git(self.repo, "remote", "add", "origin", str(self.remote))
        git(self.repo, "push", "-q", "origin", "main", "refs/tags/v0.1.0-alpha+build.1")
        self.logs = []

    def submit(self, paths, message="Improve selected files", description="Detailed changes", push=False):
        return run_versioned_commit(str(self.repo), message, description, paths, "App Test Author",
                                    "app-author@example.invalid", "2026-11-04 09:13:22", push,
                                    self.logs.append)

    def prepare_partial(self):
        (self.repo / self.selected).write_text("new selection", encoding="utf-8")
        (self.repo / "unchecked.txt").write_text("staged unchecked work", encoding="utf-8")
        git(self.repo, "add", "unchecked.txt")
        (self.repo / "not selected.txt").write_text("leave me alone", encoding="utf-8")

    def test_selected_files_metadata_and_custom_fields(self):
        self.prepare_partial()
        message = 'Fix "quoted" menus; $coins and `ticks` $(literal)'
        description = "First line\nSecond line - caf\u00e9 and preserved details"
        self.assertTrue(self.submit([self.selected], message, description), "\n".join(self.logs))
        changed = set(git(self.repo, "diff-tree", "--no-commit-id", "--name-only", "-r", "HEAD").splitlines())
        self.assertEqual(changed, {self.selected, "version.json", "project.godot", "CHANGELOG.md"})
        self.assertEqual(git(self.repo, "diff", "--cached", "--name-only"), "unchecked.txt")
        self.assertEqual(git(self.repo, "show", ":unchecked.txt"), "staged unchecked work")
        self.assertEqual(git(self.repo, "show", "HEAD:unchecked.txt"), "old unchecked")
        self.assertTrue((self.repo / "not selected.txt").exists())
        body = git(self.repo, "log", "-1", "--format=%B")
        self.assertIn(message, body)
        self.assertIn(description, body)
        self.assertEqual(git(self.repo, "log", "-1", "--format=%an|%ae"),
                         "App Test Author|app-author@example.invalid")
        self.assertTrue(git(self.repo, "log", "-1", "--format=%ai").startswith("2026-11-04 09:13:22"))
        self.assertEqual(read_build_info(self.repo)["build"], 2)
        self.assertEqual(git(self.repo, "cat-file", "-t", "v0.1.0-alpha+build.2"), "tag")
        self.assertFalse(list((self.repo / ".git").glob("galaxis-index-*")))

    def test_retry_push_preserves_unchecked_staging(self):
        self.prepare_partial()
        self.assertTrue(self.submit([self.selected]), "\n".join(self.logs))
        checkpoint = git(self.repo, "rev-parse", "HEAD")
        self.assertTrue(self.submit([], "", "", True), "\n".join(self.logs))
        self.assertEqual(git(self.repo, "rev-parse", "HEAD"), checkpoint)
        self.assertEqual(git(self.remote, "rev-parse", "refs/heads/main"), checkpoint)
        self.assertEqual(read_build_info(self.repo)["build"], 2)
        self.assertEqual(git(self.repo, "diff", "--cached", "--name-only"), "unchecked.txt")
        self.assertIn("v0.1.0-alpha+build.2", git(self.remote, "tag", "--list"))

    def test_failed_push_does_not_bump_again(self):
        self.prepare_partial()
        self.assertTrue(self.submit([self.selected]))
        checkpoint = git(self.repo, "rev-parse", "HEAD")
        git(self.repo, "remote", "set-url", "origin", str(self.case / "missing.git"))
        self.assertFalse(self.submit([], "", "", True))
        self.assertEqual(git(self.repo, "rev-parse", "HEAD"), checkpoint)
        self.assertEqual(read_build_info(self.repo)["build"], 2)
        self.assertEqual(git(self.repo, "diff", "--cached", "--name-only"), "unchecked.txt")

    def test_rename_has_both_paths(self):
        module = load_app()
        (self.repo / self.selected).rename(self.repo / "renamed hero.txt")
        git(self.repo, "add", "-A")
        entry = next(e for e in module.get_change_entries(str(self.repo)) if e[1] == "renamed hero.txt")
        self.assertEqual(set(entry[2]), {self.selected, "renamed hero.txt"})
        self.assertTrue(self.submit(entry[2]), "\n".join(self.logs))
        self.assertEqual(git(self.repo, "show", "HEAD:renamed hero.txt"), "old selection")
        self.assertNotIn(self.selected, git(self.repo, "ls-tree", "-r", "--name-only", "HEAD").splitlines())

    def test_deleted_selection(self):
        (self.repo / self.selected).unlink()
        self.assertTrue(self.submit([self.selected]), "\n".join(self.logs))
        self.assertNotIn(self.selected, git(self.repo, "ls-tree", "-r", "--name-only", "HEAD").splitlines())
        self.assertEqual(git(self.repo, "status", "--porcelain"), "")

    def test_invalid_paths_do_not_create_build(self):
        for path in ("../outside.txt", r".git\config"):
            with self.subTest(path=path):
                self.assertFalse(self.submit([path]))
                self.assertEqual(git(self.repo, "rev-parse", "HEAD"), self.base)
                self.assertEqual(read_build_info(self.repo)["build"], 1)

    def test_desktop_fields_themes_and_unchecked_choices(self):
        module = load_app()
        with mock.patch.object(module, "CONFIG", str(self.case / "app-config.json")):
            app = module.App()
            app.withdraw()
            try:
                app.repo_var.set(str(self.repo))
                self.prepare_partial()
                app.refresh()
                for iid in app.checks:
                    app.checks[iid] = app.tree.set(iid, "path") == self.selected
                app.refresh()
                excluded = [iid for iid in app.checks if app.tree.set(iid, "path") == "unchecked.txt"]
                self.assertFalse(app.checks[excluded[0]])
                self.assertIn("v0.1.0-alpha+build.1", app.build_var.get())
                for theme in module.THEMES:
                    app.apply_theme(theme)
                captured = []
                app.msg_var.set("My message")
                app.desc.insert("1.0", "My detailed notes")
                with mock.patch.object(module, "run_versioned_commit", side_effect=lambda *args: captured.append(args) or True):
                    app._run(str(self.repo), "My message", "My detailed notes", [self.selected],
                             "My author", "my-author@example.invalid", "2026-11-04 09:13:22", False)
                    app.update()
                self.assertEqual(captured[0][1:8], ("My message", "My detailed notes", [self.selected],
                                                  "My author", "my-author@example.invalid", "2026-11-04 09:13:22", False))
                self.assertFalse(app.busy)
                self.assertEqual(app.msg_var.get(), "")
                self.assertIn("Game build:", app.build_var.get())
            finally:
                app.destroy()


def load_app():
    spec = importlib.util.spec_from_file_location("galaxis_commit_app", ROOT / "git_commit_app.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


if __name__ == "__main__":
    unittest.main(verbosity=2)
