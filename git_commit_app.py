"""
Quick Git Commit - a small desktop app for committing and pushing a local repo.
Requires: Python 3.8+ (tkinter is included with the standard Windows installer) and Git.
"""
import json
import os
from pathlib import Path
import subprocess
import sys
import threading
import tkinter as tk
from datetime import datetime
from tkinter import filedialog, messagebox, ttk

sys.path.insert(0, str(Path(__file__).resolve().parent / "tools"))
from git_commit_backend import is_versioned_repository, read_build_info, run_versioned_commit

CONFIG = os.path.join(os.path.expanduser("~"), ".git_commit_app.json")
NO_WINDOW = subprocess.CREATE_NO_WINDOW if sys.platform == "win32" else 0
DATE_FMT = "%Y-%m-%d %H:%M:%S"
CHECKED, UNCHECKED = "\u2611", "\u2610"

THEMES = {
    "Light": dict(bg="#f3f4f6", fg="#1b1f24", muted="#667085", field="#ffffff", border="#d0d5dd",
                  accent="#2563eb", accent_fg="#ffffff", select="#dbe7ff",
                  btn="#e8eaee", btn_active="#d9dce2"),
    "Dark": dict(bg="#14171c", fg="#e8eaee", muted="#9aa3b2", field="#0e1116", border="#2e3540",
                 accent="#5b8def", accent_fg="#0b1020", select="#2b3a5c",
                 btn="#262c36", btn_active="#323a47"),
    "Forest green": dict(bg="#0f2a1d", fg="#e3f1e6", muted="#9dbba8", field="#0b2016", border="#24533a",
                         accent="#4caf6a", accent_fg="#06180e", select="#1f5a3a",
                         btn="#1d4a31", btn_active="#26603f"),
    "Solarized": dict(bg="#fdf6e3", fg="#657b83", muted="#93a1a1", field="#eee8d5", border="#93a1a1",
                      accent="#268bd2", accent_fg="#fdf6e3", select="#cbdcbf", btn="#eee8d5", btn_active="#e0d9c8"),
    
}


def load_cfg():
    try:
        with open(CONFIG, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {}


def save_cfg(data):
    try:
        with open(CONFIG, "w", encoding="utf-8") as f:
            json.dump(data, f)
    except Exception:
        pass


def git(repo, *args, input=None, env=None):
    """Run git in repo. Returns (returncode, stdout, stderr)."""
    e = os.environ.copy()
    e["GIT_TERMINAL_PROMPT"] = "0"
    if env:
        e.update(env)
    try:
        p = subprocess.run(
            ["git", "-C", repo, *args],
            input=input, capture_output=True, text=True,
            encoding="utf-8", errors="replace", env=e, creationflags=NO_WINDOW,
        )
    except FileNotFoundError:
        return 127, "", "Git was not found. Install Git for Windows and try again."
    return p.returncode, p.stdout.strip(), p.stderr.strip()


STATUS_WORDS = {"M": "modified", "A": "added", "D": "deleted", "R": "renamed",
                "C": "copied", "?": "new", "U": "conflict", "T": "type changed"}


def get_change_entries(repo):
    """Return each displayed change with all literal paths needed for a rename."""
    process = subprocess.run(["git", "-C", repo, "status", "--porcelain", "-z"],
                             capture_output=True, creationflags=NO_WINDOW)
    if process.returncode:
        raise RuntimeError(process.stderr.decode("utf-8", errors="replace"))
    entries = process.stdout.decode("utf-8", errors="replace").split("\0")
    result, index = [], 0
    while index < len(entries):
        entry = entries[index]
        index += 1
        if len(entry) < 4:
            continue
        xy, path = entry[:2], entry[3:]
        related = [path]
        if any(code in "RC" for code in xy):
            if index < len(entries):
                related.append(entries[index])
                index += 1
        code = xy[1] if xy[1] != " " else xy[0]
        result.append((STATUS_WORDS.get(code, code), path, related))
    return result


def get_changes(repo):
    return [(status, path) for status, path, _ in get_change_entries(repo)]


class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("Quick Git Commit")
        self.geometry("780x820")
        self.minsize(640, 700)
        self.cfg = load_cfg()
        self.checks = {}  # tree item id -> bool
        self.selection_paths = {}
        self.busy = False
        self.style = ttk.Style(self)
        self.style.theme_use("clam")
        self._build()
        self.apply_theme(self.cfg.get("theme", "Light"))

        start = self.cfg.get("repo") or str(Path(__file__).resolve().parent)
        self.repo_var.set(start)
        self.refresh()

    # ---------- UI ----------
    def _build(self):
        pad = {"padx": 10, "pady": 4}
        root = ttk.Frame(self, padding=8)
        root.pack(fill="both", expand=True)
        root.columnconfigure(0, weight=1)
        root.rowconfigure(1, weight=1)

        # Repo
        top = ttk.LabelFrame(root, text="Repository")
        top.grid(row=0, column=0, sticky="ew", **{"pady": 4})
        top.columnconfigure(0, weight=1)
        self.repo_var = tk.StringVar()
        ttk.Entry(top, textvariable=self.repo_var).grid(row=0, column=0, sticky="ew", **pad)
        ttk.Button(top, text="Browse…", command=self.browse).grid(row=0, column=1, **pad)
        ttk.Button(top, text="Refresh", command=self.refresh).grid(row=0, column=2, **pad)
        self.info_var = tk.StringVar(value="")
        ttk.Label(top, textvariable=self.info_var, style="Muted.TLabel").grid(
            row=1, column=0, sticky="w", padx=10, pady=(0, 6))
        tf = ttk.Frame(top)
        tf.grid(row=1, column=1, columnspan=2, sticky="e", padx=10, pady=(0, 6))
        ttk.Label(tf, text="Theme").pack(side="left", padx=(0, 6))
        self.theme_var = tk.StringVar()
        self.theme_box = ttk.Combobox(tf, textvariable=self.theme_var, values=list(THEMES),
                                      state="readonly", width=13)
        self.theme_box.pack(side="left")
        self.theme_box.bind("<<ComboboxSelected>>",
                            lambda e: self.apply_theme(self.theme_var.get(), save=True))

        self.build_var = tk.StringVar()
        ttk.Label(top, textvariable=self.build_var, style="Muted.TLabel", wraplength=710).grid(
            row=2, column=0, columnspan=3, sticky="w", padx=10, pady=(0, 6))

        # Changed files
        mid = ttk.LabelFrame(root, text="Files to commit (click a row to tick or untick)")
        mid.grid(row=1, column=0, sticky="nsew", pady=4)
        mid.columnconfigure(0, weight=1)
        mid.rowconfigure(0, weight=1)
        self.tree = ttk.Treeview(mid, columns=("status", "path"), show="tree headings", height=8,
                                 selectmode="none")
        self.tree.heading("#0", text="")
        self.tree.heading("status", text="Status")
        self.tree.heading("path", text="File")
        self.tree.column("#0", width=40, stretch=False)
        self.tree.column("status", width=90, stretch=False)
        self.tree.column("path", width=560)
        sb = ttk.Scrollbar(mid, orient="vertical", command=self.tree.yview)
        self.tree.configure(yscrollcommand=sb.set)
        self.tree.grid(row=0, column=0, sticky="nsew", padx=(10, 0), pady=6)
        sb.grid(row=0, column=1, sticky="ns", pady=6, padx=(0, 6))
        self.tree.bind("<ButtonRelease-1>", self.toggle_row)
        btns = ttk.Frame(mid)
        btns.grid(row=1, column=0, columnspan=2, sticky="w", padx=10, pady=(0, 6))
        ttk.Button(btns, text="Select all", command=lambda: self.set_all(True)).pack(side="left")
        ttk.Button(btns, text="Select none", command=lambda: self.set_all(False)).pack(side="left", padx=6)
        self.count_var = tk.StringVar()
        ttk.Label(btns, textvariable=self.count_var).pack(side="left", padx=10)

        # Commit details
        box = ttk.LabelFrame(root, text="Commit details")
        box.grid(row=2, column=0, sticky="ew", pady=4)
        box.columnconfigure(1, weight=1)
        box.columnconfigure(3, weight=1)

        ttk.Label(box, text="Message").grid(row=0, column=0, sticky="w", **pad)
        self.msg_var = tk.StringVar()
        ttk.Entry(box, textvariable=self.msg_var).grid(row=0, column=1, columnspan=3, sticky="ew", **pad)

        ttk.Label(box, text="Description").grid(row=1, column=0, sticky="nw", **pad)
        self.desc = tk.Text(box, height=4, wrap="word", font=("Segoe UI", 10))
        self.desc.grid(row=1, column=1, columnspan=3, sticky="ew", **pad)

        ttk.Label(box, text="Author name").grid(row=2, column=0, sticky="w", **pad)
        self.name_var = tk.StringVar()
        ttk.Entry(box, textvariable=self.name_var).grid(row=2, column=1, sticky="ew", **pad)
        ttk.Label(box, text="Email").grid(row=2, column=2, sticky="w", **pad)
        self.email_var = tk.StringVar()
        ttk.Entry(box, textvariable=self.email_var).grid(row=2, column=3, sticky="ew", **pad)

        ttk.Label(box, text="Date / time").grid(row=3, column=0, sticky="w", **pad)
        self.date_var = tk.StringVar()
        ttk.Entry(box, textvariable=self.date_var, width=22).grid(row=3, column=1, sticky="w", **pad)
        drow = ttk.Frame(box)
        drow.grid(row=3, column=2, columnspan=2, sticky="w", **pad)
        ttk.Button(drow, text="Now", command=self.set_now).pack(side="left")
        self.use_date = tk.BooleanVar(value=False)
        ttk.Checkbutton(drow, text="Use this date (otherwise current time)",
                        variable=self.use_date).pack(side="left", padx=8)
        self.set_now()

        self.push_var = tk.BooleanVar(value=True)
        ttk.Checkbutton(box, text="Push to origin after committing",
                        variable=self.push_var).grid(row=4, column=1, columnspan=3, sticky="w", **pad)

        self.go = ttk.Button(root, text="Commit", command=self.commit, style="Accent.TButton")
        self.go.grid(row=3, column=0, sticky="ew", pady=6, ipady=6)

        # Log
        logf = ttk.LabelFrame(root, text="Output")
        logf.grid(row=4, column=0, sticky="nsew", pady=4)
        logf.columnconfigure(0, weight=1)
        self.log = tk.Text(logf, height=7, wrap="word", state="disabled", font=("Consolas", 9))
        self.log.grid(row=0, column=0, sticky="nsew", padx=8, pady=6)
        root.rowconfigure(4, weight=1)

    # ---------- theming ----------
    def apply_theme(self, name, save=False):
        if name not in THEMES:
            name = "Light"
        t = THEMES[name]
        self.theme_var.set(name)
        s = self.style
        self.configure(bg=t["bg"])

        s.configure(".", background=t["bg"], foreground=t["fg"], bordercolor=t["border"],
                    lightcolor=t["bg"], darkcolor=t["bg"], troughcolor=t["bg"],
                    focuscolor=t["bg"], fieldbackground=t["field"], insertcolor=t["fg"])
        s.configure("TFrame", background=t["bg"])
        s.configure("TLabel", background=t["bg"], foreground=t["fg"])
        s.configure("Muted.TLabel", background=t["bg"], foreground=t["muted"])
        s.configure("TLabelframe", background=t["bg"], bordercolor=t["border"],
                    lightcolor=t["border"], darkcolor=t["border"])
        s.configure("TLabelframe.Label", background=t["bg"], foreground=t["muted"])

        s.configure("TButton", background=t["btn"], foreground=t["fg"], bordercolor=t["border"],
                    lightcolor=t["btn"], darkcolor=t["btn"], padding=6, relief="flat")
        s.map("TButton", background=[("disabled", t["btn"]), ("active", t["btn_active"])],
              foreground=[("disabled", t["muted"])])
        s.configure("Accent.TButton", background=t["accent"], foreground=t["accent_fg"],
                    bordercolor=t["accent"], lightcolor=t["accent"], darkcolor=t["accent"],
                    font=("Segoe UI", 11, "bold"))
        s.map("Accent.TButton", background=[("disabled", t["btn"]), ("active", t["accent"])],
              foreground=[("disabled", t["muted"])])

        for w in ("TEntry", "TCombobox"):
            s.configure(w, fieldbackground=t["field"], foreground=t["fg"], insertcolor=t["fg"],
                        bordercolor=t["border"], lightcolor=t["border"], darkcolor=t["border"],
                        arrowcolor=t["fg"], padding=3)
        s.map("TCombobox", fieldbackground=[("readonly", t["field"])],
              foreground=[("readonly", t["fg"])],
              selectbackground=[("readonly", t["field"])],
              selectforeground=[("readonly", t["fg"])],
              background=[("active", t["btn_active"]), ("!active", t["btn"])])
        self.option_add("*TCombobox*Listbox.background", t["field"])
        self.option_add("*TCombobox*Listbox.foreground", t["fg"])
        self.option_add("*TCombobox*Listbox.selectBackground", t["select"])
        self.option_add("*TCombobox*Listbox.selectForeground", t["fg"])

        s.configure("TCheckbutton", background=t["bg"], foreground=t["fg"],
                    indicatorcolor=t["field"], indicatorbackground=t["field"])
        s.map("TCheckbutton", background=[("active", t["bg"])],
              indicatorcolor=[("selected", t["accent"])],
              indicatorbackground=[("selected", t["accent"])])

        s.configure("Treeview", background=t["field"], fieldbackground=t["field"],
                    foreground=t["fg"], bordercolor=t["border"], rowheight=24)
        s.map("Treeview", background=[("selected", t["select"])],
              foreground=[("selected", t["fg"])])
        s.configure("Treeview.Heading", background=t["btn"], foreground=t["fg"],
                    relief="flat", bordercolor=t["border"])
        s.map("Treeview.Heading", background=[("active", t["btn_active"])])
        s.configure("Vertical.TScrollbar", background=t["btn"], troughcolor=t["bg"],
                    arrowcolor=t["fg"], bordercolor=t["border"])

        for box in (self.desc, self.log):
            box.configure(bg=t["field"], fg=t["fg"], insertbackground=t["fg"],
                          selectbackground=t["select"], selectforeground=t["fg"],
                          relief="flat", highlightthickness=1,
                          highlightbackground=t["border"], highlightcolor=t["accent"])
        self.theme_box.selection_clear()

        if save:
            self.cfg["theme"] = name
            save_cfg(self.cfg)

    # ---------- helpers ----------
    def say(self, text):
        def _do():
            self.log.configure(state="normal")
            self.log.insert("end", text + "\n")
            self.log.see("end")
            self.log.configure(state="disabled")
        self.after(0, _do)

    def set_now(self):
        self.date_var.set(datetime.now().strftime(DATE_FMT))

    def browse(self):
        d = filedialog.askdirectory(title="Choose your repository folder",
                                    initialdir=self.repo_var.get() or None)
        if d:
            self.repo_var.set(os.path.normpath(d))
            self.refresh()

    def toggle_row(self, event):
        if self.tree.identify_region(event.x, event.y) != "cell" and \
           self.tree.identify_region(event.x, event.y) != "tree":
            return
        iid = self.tree.identify_row(event.y)
        if iid:
            self.checks[iid] = not self.checks[iid]
            self.tree.item(iid, text=CHECKED if self.checks[iid] else UNCHECKED)
            self.update_count()

    def set_all(self, value):
        for iid in self.checks:
            self.checks[iid] = value
            self.tree.item(iid, text=CHECKED if value else UNCHECKED)
        self.update_count()

    def update_count(self):
        n = sum(self.checks.values())
        self.count_var.set(f"{n} of {len(self.checks)} selected")

    def refresh(self):
        remembered = {self.tree.set(i, "path"): checked for i, checked in self.checks.items()}
        repo = self.repo_var.get().strip()
        self.tree.delete(*self.tree.get_children())
        self.checks.clear()
        self.selection_paths.clear()
        self.build_var.set("")
        self.update_count()
        if not repo or not os.path.isdir(repo):
            self.info_var.set("Choose a repository folder.")
            return
        rc, top, err = git(repo, "rev-parse", "--show-toplevel")
        if rc != 0:
            self.info_var.set("That folder is not a git repository." if rc != 127 else err)
            return
        repo = os.path.normpath(top)
        self.repo_var.set(repo)
        self.cfg["repo"] = repo
        save_cfg(self.cfg)

        _, branch, _ = git(repo, "rev-parse", "--abbrev-ref", "HEAD")
        _, remote, _ = git(repo, "remote", "get-url", "origin")
        self.info_var.set(f"Branch: {branch}    Remote: {remote or '(none)'}")

        if not self.name_var.get():
            self.name_var.set(git(repo, "config", "user.name")[1])
        if not self.email_var.get():
            self.email_var.set(git(repo, "config", "user.email")[1])

        try:
            if is_versioned_repository(repo):
                version = read_build_info(repo)
                self.build_var.set(f"Game build: {version['tag']} - version files are always included. "
                                   "No selected files + an empty message retries the current upload.")
                self.go.configure(text="Commit Build / Retry Upload")
            else:
                self.go.configure(text="Commit")
            for status, path, related in get_change_entries(repo):
                checked = remembered.get(path, True)
                iid = self.tree.insert("", "end", text=CHECKED if checked else UNCHECKED, values=(status, path))
                self.checks[iid] = checked
                self.selection_paths[iid] = related
        except Exception as ex:
            self.say(f"Error reading changes: {ex}")
        self.update_count()

    # ---------- commit ----------
    def commit(self):
        if self.busy:
            return
        repo = self.repo_var.get().strip()
        msg = self.msg_var.get().strip()
        paths = list(dict.fromkeys(path for i, on in self.checks.items() if on
                                   for path in self.selection_paths.get(i, [self.tree.set(i, "path")])))
        name, email = self.name_var.get().strip(), self.email_var.get().strip()

        if not paths and not self.push_var.get():
            return messagebox.showwarning("Nothing selected", "Tick files to commit, or enable Push to retry an upload.")
        if paths and not msg:
            return messagebox.showwarning("Message needed", "Enter a commit message.")
        if not name or not email:
            return messagebox.showwarning("Author needed", "Enter an author name and email.")

        date = None
        if self.use_date.get():
            try:
                date = datetime.strptime(self.date_var.get().strip(), DATE_FMT).strftime(DATE_FMT)
            except ValueError:
                return messagebox.showwarning("Bad date", "Use the format YYYY-MM-DD HH:MM:SS")

        desc = self.desc.get("1.0", "end").strip()
        self.busy = True
        self.go.configure(state="disabled", text="Working…")
        threading.Thread(target=self._run, args=(repo, msg, desc, paths, name, email, date,
                                                 self.push_var.get()), daemon=True).start()

    def _run(self, repo, msg, desc, paths, name, email, date, push):
        try:
            if is_versioned_repository(repo):
                success = run_versioned_commit(repo, msg, desc, paths, name, email, date, push, self.say)
                if success:
                    self.after(0, lambda: self.msg_var.set(""))
                    self.after(0, lambda: self.desc.delete("1.0", "end"))
                return
            if not paths:
                _, branch, _ = git(repo, "rev-parse", "--abbrev-ref", "HEAD")
                rc, out, err = git(repo, "push", "origin", branch)
                self.say((out + "\n" + err).strip())
                self.say("Pushed successfully." if rc == 0 else "Push failed (see above).")
                return
            git(repo, "reset", "-q")  # start from a clean index so only ticked files go in
            self.say(f"Staging {len(paths)} item(s)…")
            rc, out, err = git(repo, "add", "-A", "--pathspec-from-file=-", "--pathspec-file-nul",
                               input="\0".join(paths))
            if rc != 0:
                return self.say("Stage failed:\n" + (err or out))

            env = {"GIT_AUTHOR_NAME": name, "GIT_AUTHOR_EMAIL": email,
                   "GIT_COMMITTER_NAME": name, "GIT_COMMITTER_EMAIL": email}
            if date:
                env["GIT_AUTHOR_DATE"] = date
                env["GIT_COMMITTER_DATE"] = date
            args = ["commit", "-m", msg] + (["-m", desc] if desc else [])
            rc, out, err = git(repo, *args, env=env)
            self.say(out or err)
            if rc != 0:
                return self.say("Commit failed.")

            if push:
                _, branch, _ = git(repo, "rev-parse", "--abbrev-ref", "HEAD")
                self.say(f"Pushing to origin/{branch}…")
                rc, out, err = git(repo, "push", "origin", branch)
                self.say((out + "\n" + err).strip())
                self.say("Pushed successfully." if rc == 0 else "Push failed (see above).")
            else:
                self.say("Committed locally (not pushed).")

            self.after(0, lambda: self.msg_var.set(""))
            self.after(0, lambda: self.desc.delete("1.0", "end"))
        except Exception as ex:
            self.say(f"Stopped: {ex}")
        finally:
            def done():
                self.busy = False
                self.go.configure(state="normal", text="Commit")
                self.refresh()
            self.after(0, done)


if __name__ == "__main__":
    App().mainloop()
