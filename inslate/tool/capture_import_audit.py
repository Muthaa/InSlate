"""Read-only ADB capture for the opt-in Phase 11 host replay test.

Private SMS and DB copies go to an OS temporary directory, never the repository.
This does not start, update, stop or write to the installed application.
Delete the printed temporary directory after validation.
"""
import hashlib
import json
import pathlib
import re
import subprocess
import tempfile


def adb(*args):
    return subprocess.run(["adb", *args], check=True, capture_output=True).stdout


remote = "app_flutter/InSlate.db"
listing = adb("exec-out", "run-as", "com.example.inslate", "ls", "app_flutter").decode("utf-8").splitlines()
assert "InSlate.db-wal" not in listing and "InSlate.db-journal" not in listing, "Live journal present; do not copy only the main database"
before = adb("shell", "run-as", "com.example.inslate", "sha256sum", remote).split()[0]
database = adb("exec-out", "run-as", "com.example.inslate", "cat", remote)
after = adb("shell", "run-as", "com.example.inslate", "sha256sum", remote).split()[0]
assert before == after == hashlib.sha256(database).hexdigest().encode(), "Database changed during capture"
# `adb shell` uses terminal CRLF conversion on this device, including SMS
# embedded newlines. exec-out preserves provider bytes; never normalize bodies.
output = adb("exec-out", 'content query --uri content://sms/inbox --projection _id:address:date:body --where "address=char(77,80,69,83,65)"').decode("utf-8")
assert "Error while accessing" not in output, "SMS query failed"
rows = re.split(r"(?m)^Row: \d+ ", output)[1:]
messages = []
for row in rows:
    match = re.fullmatch(r"_id=(\d+), address=([^\n,]+), date=(\d+), body=(.*)\r?\n", row, re.S)
    assert match is not None, "Unrecognized content-provider output; no silent omissions"
    messages.append({"id": match[1], "sender": match[2], "receivedMillis": int(match[3]), "body": match[4]})
directory = pathlib.Path(tempfile.mkdtemp(prefix="inslate_phase11_private_"))
(directory / "device.db").write_bytes(database)
(directory / "messages.json").write_text(json.dumps(messages), encoding="utf-8")
print(json.dumps({"privateDirectory": str(directory), "eligibleSms": len(messages), "stableDatabaseCapture": True}))
