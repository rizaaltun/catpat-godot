#!/usr/bin/env python3
"""Run Godot with deterministic audio; an engine error cannot pass with exit code zero."""
from __future__ import annotations
import os
import re
import subprocess
import sys

ENGINE_ERROR = re.compile(r"(?:^|\s)(?:SCRIPT ERROR:|ERROR:|Parse Error:)")

def main(argv: list[str]) -> int:
    binary = os.environ.get("GODOT_BINARY", "godot")
    args = list(argv)
    if "--audio-driver" not in args:
        args = ["--audio-driver", "Dummy", *args]
    errors = 0
    try:
        process = subprocess.Popen([binary, *args], stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                   text=True, encoding="utf-8", errors="replace", bufsize=1)
    except OSError as exc:
        print(f"Godot could not start: {exc}", file=sys.stderr)
        return 127
    assert process.stdout is not None
    for line in process.stdout:
        sys.stdout.write(line)
        sys.stdout.flush()
        if ENGINE_ERROR.search(line):
            errors += 1
    result = process.wait()
    if errors:
        print(f"GODOT CHECK FAILED: {errors} engine error line(s), process exit={result}", file=sys.stderr)
        return result if result > 0 else 1
    return result if result >= 0 else 128 - result

if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
