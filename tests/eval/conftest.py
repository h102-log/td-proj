import glob
import os
import re
import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]


def _godot():
    # GODOT 환경변수 → PATH → winget 설치 위치 순으로 찾는다
    found = os.environ.get("GODOT") or shutil.which("godot")
    if found:
        return found
    hits = sorted(glob.glob(os.path.expandvars(
        r"%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.*\Godot_v4*_console.exe")))
    return hits[-1] if hits else "godot"


# 2026-10-20
# [동작] 스위트를 처음 부를 때 그 스위트의 ev 전부를 Godot 한 프로세스로 돌리고, EV별 출력 조각을 둔다
# [이유] EV마다 Godot를 띄우면 기동 약 0.5초 × 282번이라 final이 119초로 eval-run 한도(120초)에 닿았다(실측 2026-10-20)
_suites = {}


def _run_suite(suite):
    src = (ROOT / "tests" / "eval" / "gd" / f"{suite}.gd").read_text(encoding="utf-8")
    pending = [e.upper() for e in re.findall(r"^func (ev\d+)\(", src, re.M)]
    got, tail = {}, ""
    while pending:
        r = subprocess.run(
            [_godot(), "--headless", "--path", str(ROOT), "-s", "res://tests/eval/gd/runner.gd", "--", suite, *pending],
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, encoding="utf-8", errors="replace", timeout=180,
        )
        tail = r.stdout[-3000:]
        parts = re.split(r"^== (EV\d+)\r?$", r.stdout, flags=re.M)  # [머리, EV, 조각, EV, 조각, ...]
        got.update(zip(parts[1::2], (parts[0] + p for p in parts[2::2])))
        if len(parts) == 1:
            break
        # 런타임 오류는 _initialize를 통째로 멈춘다 — 멈춘 EV 다음부터 새 프로세스로 잇는다
        pending = pending[pending.index(parts[-2]) + 1:]
    return got, f"실행기가 이 EV에 닿기 전에 끝났다\n{tail}"


@pytest.fixture
def gd():
    """tests/eval/gd/<suite>.gd 의 ev<번호>()를 headless Godot로 돌린다. 그 EV 출력 조각에 PASS 줄이 있으면 통과다."""
    def run(suite, ev):
        if suite not in _suites:
            _suites[suite] = _run_suite(suite)
        got, missing = _suites[suite]
        out = got.get(ev, missing)
        assert f"PASS {ev}" in out, out[-3000:]
    return run
