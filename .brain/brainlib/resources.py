"""Godot 리소스 연결: .tres·.tscn의 스크립트·외부 리소스, [resource] 속성 이름, project.godot 진입 장면."""
from __future__ import annotations

import re

EXT_RE = re.compile(r'^\[ext_resource\b([^\]]*)\]', re.M)
ATTR_RE = re.compile(r'(\w+)="([^"]*)"')
SCRIPT_RE = re.compile(r'^script\s*=\s*ExtResource\(\s*"([^"]+)"\s*\)', re.M)
SECTION_RE = re.compile(r'^\[(\w+)[^\]]*\]\s*$', re.M)
PROP_RE = re.compile(r'^([A-Za-z_]\w*)\s*=', re.M)


def parse_resource(text: str) -> dict:
    """{'script': 경로|None, 'refs': [(경로, 타입)], 'props': [(이름, 줄)]}"""
    ext = {}
    refs = []
    for m in EXT_RE.finditer(text):
        attrs = dict(ATTR_RE.findall(m.group(1)))
        path = attrs.get("path", "")
        if path.startswith("res://"):
            ext[attrs.get("id", "")] = path[len("res://"):]
            refs.append((path[len("res://"):], attrs.get("type", "")))
    script = None
    sm = SCRIPT_RE.search(text)
    if sm:
        script = ext.get(sm.group(1))
    props = []
    # [resource] 절의 맨 앞 속성 이름(값이 여러 줄이어도 이름은 줄 머리에 있다)
    sections = list(SECTION_RE.finditer(text))
    for i, sec in enumerate(sections):
        if sec.group(1) != "resource":
            continue
        start = sec.end()
        end = sections[i + 1].start() if i + 1 < len(sections) else len(text)
        body = text[start:end]
        base_line = text.count("\n", 0, start) + 1
        for pm in PROP_RE.finditer(body):
            name = pm.group(1)
            if name in ("script", "resource_name", "metadata"):
                continue
            props.append((name, base_line + body.count("\n", 0, pm.start())))
    return {"script": script, "refs": refs, "props": props}


def main_scene(text: str) -> str | None:
    m = re.search(r'^run/main_scene\s*=\s*"res://([^"]+)"', text, re.M)
    return m.group(1) if m else None
