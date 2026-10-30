#!/usr/bin/env python3
"""Prepare Catpat's image-backed web shell around an actual Godot4.4 export.

Only HTML and web presentation assets change. Hashed JS/WASM/PCK stay untouched.
The exported Godot config and feature requirements remain the startup authority.
"""
from __future__ import annotations

import argparse
import html
from html.parser import HTMLParser
import json
from pathlib import Path
import re
import shutil

ROOT = Path(__file__).resolve().parents[1]
TEMPLATE = ROOT / "tools" / "web_shell"
ASSETS = {
    "forest.webp": "assets/polish-v3/forest.webp",
    "panel.webp": "assets/polish-v3/panel.webp",
    "button.webp": "assets/polish-v3/button.webp",
    "catpat.webp": "assets/review-v2/catpat-idle-r2.webp",
    "Baloo2.ttf": "assets/fonts/Baloo2.ttf",
    "Baloo2-OFL.txt": "assets/fonts/Baloo2-OFL.txt",
}


class ExportDocument(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.script_sources: list[str] = []
        self.inline_scripts: list[str] = []
        self.title_parts: list[str] = []
        self.ids: set[str] = set()
        self.meta: list[dict[str, str | None]] = []
        self._script: list[str] | None = None
        self._in_title = False

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        data = dict(attrs)
        if data.get("id"):
            self.ids.add(str(data["id"]))
        if tag == "meta":
            self.meta.append(data)
        if tag == "title":
            self._in_title = True
        if tag == "script":
            if data.get("src"):
                self.script_sources.append(str(data["src"]))
            self._script = []

    def handle_endtag(self, tag: str) -> None:
        if tag == "title":
            self._in_title = False
        if tag == "script" and self._script is not None:
            self.inline_scripts.append("".join(self._script))
            self._script = None

    def handle_data(self, data: str) -> None:
        if self._in_title:
            self.title_parts.append(data)
        if self._script is not None:
            self._script.append(data)


def parse_export(source: str) -> tuple[dict, bool, str]:
    document = ExportDocument()
    document.feed(source)
    scripts = "\n".join(document.inline_scripts)
    assignment = re.search(r"\b(?:const|let|var)\s+GODOT_CONFIG\s*=\s*", scripts)
    if not assignment:
        raise ValueError("Expected Godot export GODOT_CONFIG assignment was not found")
    try:
        config, _ = json.JSONDecoder().raw_decode(scripts[assignment.end():])
    except json.JSONDecodeError as exc:
        raise ValueError("Godot export config is not valid JSON") from exc
    if not isinstance(config, dict):
        raise ValueError("Godot export config must be an object")
    executable = config.get("executable")
    if not isinstance(executable, str) or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,159}", executable):
        raise ValueError("Export executable must be a local safe basename")
    if executable + ".js" not in document.script_sources:
        raise ValueError("HTML does not load the matching hashed Godot JavaScript")
    thread_setting = re.search(r"\b(?:const|let|var)\s+GODOT_THREADS_ENABLED\s*=\s*(true|false)\s*;", scripts)
    if not thread_setting:
        raise ValueError("Godot thread feature declaration was not found")
    return config, thread_setting[1] == "true", "".join(document.title_parts) or "Çatpat: Festival Yolu"


def validate_resources(folder: Path, config: dict) -> None:
    executable = config["executable"]
    sizes = config.get("fileSizes", {})
    if not isinstance(sizes, dict):
        raise ValueError("Godot exported fileSizes must be an object")
    for extension in ("js", "wasm", "pck"):
        filename = executable + "." + extension
        path = folder / filename
        if not path.is_file() or path.stat().st_size == 0:
            raise ValueError(f"Godot export resource is missing or empty: {filename}")
        if filename in sizes and path.stat().st_size != sizes[filename]:
            raise ValueError(f"Godot exported file size disagrees with config: {filename}")


def render(config: dict, threads: bool, title: str) -> str:
    text = (TEMPLATE / "index.html").read_text(encoding="utf-8")
    # Escape '<' in JSON so any custom export string cannot terminate its script.
    config_json = json.dumps(config, ensure_ascii=False, separators=(",", ":")).replace("<", "\\u003c")
    replacements = {
        "__CATPAT_TITLE__": html.escape(title),
        "__CATPAT_ENGINE_URL__": html.escape(config["executable"] + ".js", quote=True),
        "__CATPAT_CONFIG__": config_json,
        "__CATPAT_THREADS__": "true" if threads else "false",
        "__CATPAT_ASSET_PREFIX__": "web-assets/" + config["executable"],
    }
    for token, value in replacements.items():
        text = text.replace(token, value)
    if "__CATPAT_" in text:
        raise ValueError("Unresolved web shell placeholder")
    return text


def validate_prepared(source: str) -> dict:
    document = ExportDocument()
    document.feed(source)
    required = {"canvas", "game-viewport", "loading-panel", "orientation-panel", "error-panel", "error-technical", "retry-button"}
    if not required <= document.ids:
        raise ValueError("Prepared web shell is missing required presentation nodes")
    viewport = next((m.get("content", "") for m in document.meta if m.get("name") == "viewport"), "")
    if "viewport-fit=cover" not in viewport:
        raise ValueError("Prepared shell must opt into real safe-area insets")
    no_cache = next((m.get("content", "") for m in document.meta if str(m.get("http-equiv", "")).lower() == "cache-control"), "")
    if "no-store" not in no_cache:
        raise ValueError("Prepared shell must retain no-cache metadata")
    if re.search(r"<(?:head|body)[^>]*>\s*\\n", source, re.I):
        raise ValueError("Literal backslash-n text was injected into the document")
    config, _, _ = parse_export(source)
    return config


def prepare(source_path: Path, output_path: Path, root: Path = ROOT) -> dict:
    source_path = source_path.resolve()
    output_path = output_path.resolve()
    if source_path.parent != output_path.parent:
        raise ValueError("HTML output must stay beside the matching Godot export files")
    config, threads, title = parse_export(source_path.read_text(encoding="utf-8-sig"))
    validate_resources(source_path.parent, config)
    prepared = render(config, threads, title)
    if validate_prepared(prepared) != config:
        raise ValueError("Prepared shell changed the exported Godot configuration")
    assets_folder = output_path.parent / "web-assets" / config["executable"]
    assets_folder.mkdir(parents=True, exist_ok=True)
    for name, relative_source in ASSETS.items():
        path = root / relative_source
        if not path.is_file() or not path.stat().st_size:
            raise ValueError(f"Required existing image/font asset is missing: {relative_source}")
        shutil.copy2(path, assets_folder / name)
    for name in ("shell.css", "shell.js"):
        shutil.copy2(TEMPLATE / name, assets_folder / name)
    # Use real newline characters. Never inject escaped text between HTML nodes.
    output_path.write_text(prepared, encoding="utf-8", newline="\n")
    if source_path != output_path:
        source_path.write_text(prepared, encoding="utf-8", newline="\n")
    return config


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    config = prepare(args.source, args.output)
    print(f"WEB SHELL: prepared {args.output}; preserved {config['executable']} JS/WASM/PCK and engine feature requirements")


if __name__ == "__main__":
    main()
