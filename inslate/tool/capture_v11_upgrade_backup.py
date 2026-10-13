"""Read-only, stable database backup for v11 upgrade verification.

Keeps private evidence outside the repository. Never starts/stops the app,
queries SMS bodies, installs an APK, or changes device data.
"""
import hashlib
import json
import pathlib
import sqlite3
import subprocess
import tempfile


def adb(*args):
    return subprocess.run(["adb", *args], check=True, capture_output=True).stdout


remote = "app_flutter/InSlate.db"
listing = adb("exec-out", "run-as", "com.example.inslate", "ls", "app_flutter").decode().splitlines()
assert "InSlate.db-wal" not in listing and "InSlate.db-journal" not in listing, "Active journal: wait for a quiescent database before capture"
before = adb("shell", "run-as", "com.example.inslate", "sha256sum", remote).split()[0]
data = adb("exec-out", "run-as", "com.example.inslate", "cat", remote)
after = adb("shell", "run-as", "com.example.inslate", "sha256sum", remote).split()[0]
digest = hashlib.sha256(data).hexdigest()
assert before == after == digest.encode(), "Database changed during capture"
db = sqlite3.connect(":memory:")
db.deserialize(data)
db.execute("PRAGMA query_only=ON")
schema = db.execute("PRAGMA user_version").fetchone()[0]
assert schema == 10, f"Expected v10 device database, got v{schema}; review before upgrading"
assert db.execute("PRAGMA integrity_check").fetchone()[0] == "ok"
assert not db.execute("PRAGMA foreign_key_check").fetchall()
tables = [r[0] for r in db.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")]
columns = {t: [r[1] for r in db.execute(f'PRAGMA table_info("{t}")')] for t in tables}
counts = {t: db.execute(f'SELECT COUNT(*) FROM "{t}"').fetchone()[0] for t in tables}
# Expected row contents stay private; the host test compares them without printing.
rows = {t: [dict(zip(columns[t], r)) for r in db.execute(f'SELECT * FROM "{t}" ORDER BY ' + ', '.join(f'"{c}"' for c in columns[t]))] for t in tables}
directory = pathlib.Path(tempfile.mkdtemp(prefix="inslate_v11_private_"))
(directory / "before-v10.db").write_bytes(data)
(directory / "validation.db").write_bytes(data)
(directory / "expected.json").write_text(json.dumps(rows), encoding="utf-8")
(directory / "manifest.json").write_text(json.dumps({"schema": schema, "sha256": digest, "counts": counts, "columns": columns}), encoding="utf-8")
db.close()
print(json.dumps({"privateDirectory": str(directory), "stableCapture": True, "schema": schema, "counts": counts}))
