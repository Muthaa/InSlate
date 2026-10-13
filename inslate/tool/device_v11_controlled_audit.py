"""Private pre/post database evidence for an authorized device upgrade.

Captures only via read-only ADB operations. Never installs, launches, imports,
changes permissions or writes to the device. Private copies stay outside Git.
"""
import argparse
import hashlib
import json
import pathlib
import sqlite3
import subprocess


def adb(*args):
    return subprocess.run(["adb", *args], check=True, capture_output=True).stdout


def sha(data):
    return hashlib.sha256(data).hexdigest()


args_parser = argparse.ArgumentParser()
args_parser.add_argument("stage", choices=["pre", "post", "backup-only"])
args_parser.add_argument("directory", type=pathlib.Path)
args_parser.add_argument("--previous", type=pathlib.Path)
args = args_parser.parse_args()
folder = args.directory
if args.stage == "backup-only":
    assert args.previous is not None, "Existing backup required"
    manifest = json.loads((args.previous / "manifest.json").read_text())
    backup = (args.previous / "before-v10.db").read_bytes()
    assert sha(backup) == manifest["sha256"], "Existing backup checksum failed"
    check = sqlite3.connect(":memory:")
    check.deserialize(backup)
    check.execute("PRAGMA query_only=ON")
    assert check.execute("PRAGMA user_version").fetchone()[0] == 10
    assert check.execute("PRAGMA integrity_check").fetchone()[0] == "ok"
    assert not check.execute("PRAGMA foreign_key_check").fetchall()
    check.close()
    folder.mkdir(parents=True, exist_ok=False)
    (folder / "before-v10.db").write_bytes(backup)
    (folder / "manifest.json").write_text(json.dumps(manifest), encoding="utf-8")
    assert sha((folder / "before-v10.db").read_bytes()) == manifest["sha256"]
    print(json.dumps({"durableBackup": str(folder), "checksumVerified": True, "schema": 10, "integrity": "ok", "deviceOperations": 0}))
    raise SystemExit(0)
remote = "app_flutter/InSlate.db"
listing = adb("exec-out", "run-as", "com.example.inslate", "ls", "app_flutter").decode().splitlines()
assert not {"InSlate.db-wal", "InSlate.db-journal"}.intersection(listing), "Active journal; do not capture only the main DB"
before = adb("shell", "run-as", "com.example.inslate", "sha256sum", remote).split()[0]
data = adb("exec-out", "run-as", "com.example.inslate", "cat", remote)
after = adb("shell", "run-as", "com.example.inslate", "sha256sum", remote).split()[0]
assert before == after == sha(data).encode(), "Database changed during capture; stop"
db = sqlite3.connect(":memory:")
db.deserialize(data)
db.execute("PRAGMA query_only=ON")
schema = db.execute("PRAGMA user_version").fetchone()[0]
assert schema == (10 if args.stage == "pre" else 11), f"Unexpected schema v{schema}; stop"
assert db.execute("PRAGMA integrity_check").fetchone()[0] == "ok", "Integrity failure; stop"
assert not db.execute("PRAGMA foreign_key_check").fetchall(), "Foreign key failure; stop"
tables = [r[0] for r in db.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")]
columns = {t: [r[1] for r in db.execute(f'PRAGMA table_info("{t}")')] for t in tables}
counts = {t: db.execute(f'SELECT COUNT(*) FROM "{t}"').fetchone()[0] for t in tables}
rows = {t: [dict(zip(columns[t], r)) for r in db.execute(f'SELECT * FROM "{t}" ORDER BY ' + ', '.join(f'"{c}"' for c in columns[t]))] for t in tables}
if args.stage == "pre":
    assert args.previous is not None, "Existing backup required"
    old_manifest = json.loads((args.previous / "manifest.json").read_text())
    old_data = (args.previous / "before-v10.db").read_bytes()
    assert sha(old_data) == old_manifest["sha256"], "Existing backup checksum failed; stop"
    folder.mkdir(parents=True, exist_ok=False)
    (folder / "previous-v10.db").write_bytes(old_data)
    (folder / "previous-manifest.json").write_text(json.dumps(old_manifest), encoding="utf-8")
    (folder / "pre-v10.db").write_bytes(data)
    (folder / "validation.db").write_bytes(data)
    (folder / "expected.json").write_text(json.dumps(rows), encoding="utf-8")
    (folder / "manifest.json").write_text(json.dumps({"sha256": sha(data), "schema": schema, "columns": columns, "counts": counts}), encoding="utf-8")
    apk = pathlib.Path("build/app/outputs/flutter-apk/app-debug.apk")
    (folder / "apk-sha256.txt").write_text(sha(apk.read_bytes()), encoding="ascii")
else:
    expected = json.loads((folder / "expected.json").read_text(encoding="utf-8"))
    comparable = {t: list(r) for t, r in rows.items() if t != "instrument_mappings"}
    for row in comparable["financial_records"]:
        for column in ["interpreted_type", "interpreted_subtype", "interpretation_mapping_id"]:
            assert column in row and row.pop(column) is None, "Unexpected historical interpretation; stop"
    assert comparable == expected, "Existing rows changed unexpectedly; stop without further device operations"
    assert counts.get("instrument_mappings") == 0, "Unexpected mapping; stop"
    (folder / "post-v11.db").write_bytes(data)
    (folder / "post-manifest.json").write_text(json.dumps({"sha256": sha(data), "schema": schema, "counts": counts, "preserved": True}), encoding="utf-8")
registered = db.execute("SELECT COUNT(*) FROM accounts WHERE is_user_registered = 1").fetchone()[0]
links = db.execute("SELECT SUM(source_account_id IS NOT NULL), SUM(destination_account_id IS NOT NULL), SUM(reverses_record_id IS NOT NULL) FROM financial_records").fetchone()
db.close()
print(json.dumps({"stage": args.stage, "schema": schema, "integrity": "ok", "foreignKeyErrors": 0, "counts": counts, "registeredInstruments": registered, "sourceLinks": links[0], "destinationLinks": links[1], "reversalLinks": links[2], "backupDirectory": str(folder)}))
