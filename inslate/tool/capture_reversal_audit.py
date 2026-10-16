"""Read-only Phase 11R capture. Private databases stay in OS temporary storage.

Run once before the device update; run with --after <privateDirectory> after
the five-source operation. Neither mode changes device data or imports SMS.
"""
import argparse
import hashlib
import json
import pathlib
import sqlite3
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument('--after')
parser.add_argument('--adb', default='adb')
args = parser.parse_args()

def adb(*arguments):
    return subprocess.run([args.adb, *arguments], check=True, capture_output=True).stdout

remote = 'app_flutter/InSlate.db'
listing = adb('exec-out', 'run-as', 'com.example.inslate', 'ls', 'app_flutter').decode().splitlines()
assert 'InSlate.db-wal' not in listing and 'InSlate.db-journal' not in listing, 'Live journal: capture refused'
before = adb('shell', 'run-as', 'com.example.inslate', 'sha256sum', remote).split()[0]
data = adb('exec-out', 'run-as', 'com.example.inslate', 'cat', remote)
after = adb('shell', 'run-as', 'com.example.inslate', 'sha256sum', remote).split()[0]
assert before == after == hashlib.sha256(data).hexdigest().encode(), 'Database changed during capture'
db = sqlite3.connect(':memory:')
db.deserialize(data)
db.execute('PRAGMA query_only=ON')
counts = {table: db.execute(f'SELECT COUNT(*) FROM {table}').fetchone()[0] for table in ['raw_messages', 'financial_records', 'balance_evidence']}
count = db.execute("SELECT COUNT(*) FROM raw_messages WHERE upper(trim(sender))='MPESA' AND lower(body) LIKE '%reversal of transaction%'").fetchone()[0]
directory = pathlib.Path(args.after) if args.after else pathlib.Path(tempfile.mkdtemp(prefix='inslate_phase11r_private_'))
name = 'after.db' if args.after else 'before.db'
assert not (directory / name).exists(), 'Capture already exists; refusing overwrite'
(directory / name).write_bytes(data)
print(json.dumps({'privateDirectory': str(directory), 'capture': name, 'schema': db.execute('PRAGMA user_version').fetchone()[0], 'retainedConfirmations': count, 'counts': counts, 'stableCapture': True}))
