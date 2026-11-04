"""Two real Godot processes, loopback ENet/discovery, no firewall changes or real saves."""
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import sys
import time
import uuid

ROOT = Path(__file__).resolve().parents[1]
GODOT = Path(os.environ.get("GODOT", r"D:\Godot\4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe"))
CASE = ROOT / ".godot" / "multiplayer-checks" / uuid.uuid4().hex
CASE.mkdir(parents=True)
PROJECT = CASE / "project"
PROJECT.mkdir()
for name in ("project.godot", "main.tscn", "version.json"):
    shutil.copy2(ROOT / name, PROJECT / name)


def link_directory(target, source):
    if os.name == "nt":
        subprocess.run(["cmd.exe", "/c", "mklink", "/J", str(target), str(source)],
                       check=True, capture_output=True,
                       creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
    else:
        target.symlink_to(source, target_is_directory=True)


for name in ("scripts", "assets", "tests", "tools"):
    link_directory(PROJECT / name, ROOT / name)
(PROJECT / ".godot").mkdir()
if (ROOT / ".godot" / "imported").is_dir():
    link_directory(PROJECT / ".godot" / "imported", ROOT / ".godot" / "imported")
else:
    subprocess.run([str(GODOT), "--headless", "--path", str(PROJECT), "--editor", "--quit"],
                   check=True, capture_output=True)
uid_cache = ROOT / ".godot" / "uid_cache.bin"
if uid_cache.exists():
    shutil.copy2(uid_cache, PROJECT / ".godot" / "uid_cache.bin")
BASE = CASE / "network"
with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as first, socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as second:
    first.bind(("127.0.0.1", 0))
    port = first.getsockname()[1]
    if port == 65535:
        raise RuntimeError("Retry with another test port")
    second.bind(("127.0.0.1", port + 1))

processes = []
logs = []
preview = "--preview" in sys.argv
startupinfo = None
if preview and os.name == "nt":
    startupinfo = subprocess.STARTUPINFO()
    startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startupinfo.wShowWindow = 0
try:
    for role in ("host", "client"):
        log = (CASE / (role + ".log")).open("w", encoding="utf-8")
        logs.append(log)
        command = [str(GODOT)] + ([] if preview else ["--headless"]) + ["--path", str(PROJECT), "--script",
                   "res://tests/multiplayer_peer_check.gd", "--", role, str(port), str(BASE)] + (["preview"] if preview else [])
        processes.append(subprocess.Popen(command, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT,
                                          creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0), startupinfo=startupinfo))
        if role == "host":
            deadline = time.monotonic() + 25
            while not Path(str(BASE) + "-ready").exists():
                if processes[0].poll() is not None or time.monotonic() > deadline:
                    raise RuntimeError("Host did not start; inspect " + str(CASE / "host.log"))
                time.sleep(0.1)
    for process in processes:
        process.wait(timeout=300)
    results = []
    for role in ("host", "client"):
        result_file = Path(str(BASE) + "-" + role + ".json")
        result = json.loads(result_file.read_text()) if result_file.exists() else {"checks": 0, "failures": 1}
        print(role.upper(), result)
        text = (CASE / (role + ".log")).read_text(encoding="utf-8", errors="replace")
        if "SCRIPT ERROR" in text or "ERROR:" in text:
            print(text[-10000:])
            result["failures"] += 1
        results.append(result)
    print("Logs:", CASE)
    raise SystemExit(1 if any(r["failures"] for r in results) or any(p.returncode for p in processes) else 0)
finally:
    for process in processes:
        if process.poll() is None:
            process.terminate()
            process.wait(timeout=10)
    for log in logs:
        log.close()
