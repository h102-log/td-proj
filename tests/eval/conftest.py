import glob
import os
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


@pytest.fixture
def gd():
    """tests/eval/gd/<suite>.gd 의 ev<번호>()를 headless Godot로 돌린다. 종료 코드 0 + PASS 줄이 통과다."""
    def run(suite, ev):
        r = subprocess.run(
            [_godot(), "--headless", "--path", str(ROOT), "-s", "res://tests/eval/gd/runner.gd", "--", suite, ev],
            capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=180,
        )
        out = r.stdout + r.stderr
        assert r.returncode == 0 and f"PASS {ev}" in out, out[-3000:]
    return run
