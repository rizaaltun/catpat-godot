"""Exercise the actual child-process/log boundary, including Godot's false-success case."""
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

WRAPPER = Path(__file__).resolve().parents[1] / "tools/run_godot_check.py"

class EngineLogGate(unittest.TestCase):
    def run_engine(self, message, code=0):
        with tempfile.TemporaryDirectory() as folder:
            engine = Path(folder) / "engine"
            engine.write_text(f"#!{sys.executable}\nimport sys\nprint({message!r})\nsys.exit({code})\n")
            engine.chmod(0o755)
            return subprocess.run([sys.executable, str(WRAPPER), "--headless"],
                                  env={**os.environ, "GODOT_BINARY": str(engine)}, capture_output=True, text=True)
    def test_script_error_with_zero_exit_is_rejected(self):
        result = self.run_engine("SCRIPT ERROR: Invalid access to a previously freed instance")
        self.assertEqual(result.returncode, 1)
        self.assertIn("process exit=0", result.stderr)
    def test_missing_resource_is_rejected(self):
        self.assertEqual(self.run_engine("ERROR: Failed loading resource: res://missing.webp").returncode, 1)
    def test_success_and_negative_fixture_text_pass(self):
        self.assertEqual(self.run_engine("PASS injected write failure is reported").returncode, 0)
    def test_engine_nonzero_exit_is_preserved(self):
        self.assertEqual(self.run_engine("assertion failed", 7).returncode, 7)

if __name__ == "__main__":
    unittest.main()
