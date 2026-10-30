#!/usr/bin/env python3
"""Validate the generated HTML/resources, plus fail-closed export parsing cases."""
import argparse
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from prepare_web_export import ASSETS, ROOT, parse_export, prepare, render, validate_prepared, validate_resources


class WebExportContract(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.folder = Path(self.temp.name)
        self.name = "catpat-0123456789abcdef"
        self.payloads = {"js": b"// engine fixture\n", "wasm": b"\0asm\x01\0\0\0", "pck": b"GDPCfixture"}
        for ext, data in self.payloads.items():
            (self.folder / f"{self.name}.{ext}").write_bytes(data)
        self.config = {"args": [], "canvasResizePolicy": 2, "executable": self.name,
                       "fileSizes": {f"{self.name}.wasm": len(self.payloads["wasm"]), f"{self.name}.pck": len(self.payloads["pck"])},
                       "focusCanvas": True, "gdextensionLibs": []}
        self.source = self.folder / f"{self.name}.html"
        self.source.write_text('<!doctype html><html><head>\\n<title>Çatpat: Festival Yolu</title></head><body><canvas id="canvas"></canvas>'
                               f'<script src="{self.name}.js"></script><script>\nconst GODOT_CONFIG = {json.dumps(self.config)};\n'
                               'const GODOT_THREADS_ENABLED = false;\nconst engine = new Engine(GODOT_CONFIG);\n</script></body></html>', encoding="utf-8")

    def tearDown(self):
        self.temp.cleanup()

    def test_prepare_preserves_hashed_engine_payload_and_config(self):
        before = {ext: hashlib.sha256((self.folder / f"{self.name}.{ext}").read_bytes()).hexdigest() for ext in self.payloads}
        result = prepare(self.source, self.folder / "index.html")
        self.assertEqual(result, self.config)
        for ext, digest in before.items():
            self.assertEqual(hashlib.sha256((self.folder / f"{self.name}.{ext}").read_bytes()).hexdigest(), digest)
        page = (self.folder / "index.html").read_text()
        self.assertEqual(validate_prepared(page), self.config)
        self.assertIn('<html lang="tr">', page)
        self.assertNotIn('<head>\\n', page)
        self.assertIn("Cihazını yatay çevir", page)
        self.assertEqual(self.source.read_text(), page)

    def test_required_image_and_font_files_are_real_copies(self):
        prepare(self.source, self.folder / "index.html")
        asset_folder=self.folder / "web-assets" / self.name
        for name, original in ASSETS.items():
            self.assertEqual((asset_folder / name).read_bytes(), (ROOT / original).read_bytes())
        css = (asset_folder / "shell.css").read_text()
        self.assertTrue(all(f"safe-area-inset-{edge}" in css for edge in ("top", "right", "bottom", "left")))
        self.assertIn('url("panel.webp")', css)
        self.assertIn('url("button.webp")', css)

    def test_preparation_is_idempotent(self):
        first = prepare(self.source, self.folder / "index.html")
        page = self.source.read_text()
        self.assertEqual(prepare(self.source, self.folder / "index.html"), first)
        self.assertEqual(self.source.read_text(), page)

    def test_missing_payload_rejects_export(self):
        (self.folder / f"{self.name}.pck").unlink()
        with self.assertRaisesRegex(ValueError, "missing or empty"):
            prepare(self.source, self.folder / "index.html")
        self.assertFalse((self.folder / "index.html").exists())

    def test_size_mismatch_rejects_export(self):
        (self.folder / f"{self.name}.wasm").write_bytes(b"wrong payload")
        with self.assertRaisesRegex(ValueError, "size disagrees"):
            prepare(self.source, self.folder / "index.html")

    def test_mismatched_loader_and_unsafe_basename_reject(self):
        text = self.source.read_text().replace(f'src="{self.name}.js"', 'src="different.js"')
        with self.assertRaisesRegex(ValueError, "matching hashed"):
            parse_export(text)
        text = self.source.read_text().replace(f'"executable": "{self.name}"', '"executable": "../private"')
        with self.assertRaisesRegex(ValueError, "safe basename"):
            parse_export(text)

    def test_missing_feature_declaration_rejects_instead_of_assuming(self):
        with self.assertRaisesRegex(ValueError, "thread feature"):
            parse_export(self.source.read_text().replace("const GODOT_THREADS_ENABLED = false;", ""))

    def test_title_and_script_strings_are_escaped(self):
        config = dict(self.config, args=["</script><script>bad()</script>"])
        page = render(config, False, "Çatpat <oyun>")
        self.assertIn("Çatpat &lt;oyun&gt;", page)
        self.assertNotIn("<script>bad()", page)
        self.assertEqual(parse_export(page)[0], config)


def check_actual_export(path):
    page = path.read_text(encoding="utf-8")
    config = validate_prepared(page)
    validate_resources(path.parent, config)
    for asset in (*ASSETS, "shell.css", "shell.js"):
        candidate = path.parent / "web-assets" / config["executable"] / asset
        if not candidate.is_file() or not candidate.stat().st_size:
            raise ValueError(f"Prepared presentation asset missing: {asset}")
    print(f"WEB ARTIFACT CONTRACT: actual generated HTML, config and hashed payload sizes verified ({config['executable']})")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("--html", type=Path)
    args, remaining = parser.parse_known_args()
    result = unittest.main(argv=[sys.argv[0]] + remaining, exit=False).result
    if not result.wasSuccessful():
        raise SystemExit(1)
    if args.html:
        check_actual_export(args.html)
