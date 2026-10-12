# tests/unit/gd/test_*.gd 를 파일마다 headless Godot로 돌린다. 루트에서 `pytest` 한 줄이면 평가 테스트와 함께 돈다.
# 지키는 요구:
#   S32. 테스트는 headless 테스트 러너로 돌린다.
#   I31. 테스트 러너는 명령 한 줄로 전체 테스트를 돌리고, 하나라도 실패하면 0이 아닌 종료 코드를 낸다.
import glob
import os
import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
SUITES = sorted(Path(__file__).parent.glob("gd/test_*.gd"))


def _godot():
    # tests/eval/conftest.py 의 _godot()과 같은 순서: GODOT 환경변수 → PATH → winget 설치 위치
    # ponytail: 평가 쪽은 동결 파일이라 가져다 쓰지 않고 복사했다
    found = os.environ.get("GODOT") or shutil.which("godot")
    if found:
        return found
    hits = sorted(glob.glob(os.path.expandvars(
        r"%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.*\Godot_v4*_console.exe")))
    return hits[-1] if hits else "godot"


@pytest.mark.parametrize("suite", SUITES, ids=lambda p: p.stem)
def test_gd(suite):
    r = subprocess.run(
        [_godot(), "--headless", "--path", str(ROOT), "-s", "res://tests/unit/gd/runner.gd",
         "--", "res://" + suite.relative_to(ROOT).as_posix()],
        capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=180,
    )
    out = r.stdout + r.stderr
    assert r.returncode == 0 and "ALL PASS" in out, out[-3000:]
