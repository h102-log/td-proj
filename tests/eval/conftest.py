import glob
import os
import re
import shutil
import subprocess
import threading
from concurrent.futures import ThreadPoolExecutor
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
        timed_out = False
        try:
            out = subprocess.run(
                [_godot(), "--headless", "--path", str(ROOT), "-s", "res://tests/eval/gd/runner.gd", "--", suite, *pending],
                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, encoding="utf-8", errors="replace", timeout=180,
            ).stdout
        except subprocess.TimeoutExpired as ex:  # 스위트 하나가 180초를 넘었다(2026-10-27 hud 약 180초) — 끊긴 데까지 받고 잇는다
            timed_out = True
            out = ex.stdout or b""
            out = out.decode("utf-8", "replace") if isinstance(out, bytes) else out
        tail = out[-3000:]
        parts = re.split(r"^== (EV\d+)\r?$", out, flags=re.M)  # [머리, EV, 조각, EV, 조각, ...]
        got.update(zip(parts[1::2], (parts[0] + p for p in parts[2::2])))
        if len(parts) == 1:
            break
        # 런타임 오류는 _initialize를 통째로 멈춘다 — 멈춘 EV 다음부터 새 프로세스로 잇는다.
        # 시간이 다 돼 끊긴 EV는 그 EV부터 다시 돌린다. 그 EV 혼자 시간을 다 썼으면(앞으로 나아가지 못함) 다음부터 잇는다
        last = pending.index(parts[-2])
        pending = pending[last if timed_out and last > 0 else last + 1:]
    return got, f"실행기가 이 EV에 닿기 전에 끝났다\n{tail}"


# 2026-11-01
# [동작] 이번 실행이 부를 스위트를 Godot EVAL_JOBS개(기본 2)로 동시에 미리 돌린다. 평가용 저장·설정 파일(user://eval_*)을 함께 쓰는 스위트는 한 작업으로 묶어 차례로 돈다
# [이유] 차례로 돌리면 이 PC에서 평가가 386초라 eval-run 한도(300초)를 넘었다(실측 2026-11-01). 동시 수는 사용자 요청으로 2026-10-22 sweep 상한 4보다 적게 둔다(Godot 16개 동시 실행에 PC가 버거웠다)
JOBS = max(1, int(os.environ.get("EVAL_JOBS", "2")))
_ready = {}  # 미리 돌리는 스위트 → threading.Event
_pool = None


def _src(suite):
    return (ROOT / "tests" / "eval" / "gd" / f"{suite}.gd").read_text(encoding="utf-8")


def _shares_files(suite):  # save.gd를 (거쳐서라도) 이어받거나(_save()가 평가용 파일 경로를 건다) user://를 직접 쓴다
    src = _src(suite)
    if suite == "save" or "user://" in src:
        return True
    up = re.match(r'extends "res://tests/eval/gd/(\w+)\.gd"', src)
    return bool(up) and up.group(1) != "lib" and _shares_files(up.group(1))


def _job(suites):
    for s in suites:
        try:
            _suites[s] = _run_suite(s)
        except Exception as ex:  # 스레드 안의 예외는 테스트에 보이지 않아 결과로 넘긴다
            _suites[s] = ({}, f"스위트 실행 실패: {ex!r}")
        _ready[s].set()


def pytest_collection_finish(session):
    global _pool
    here = ROOT / "tests" / "eval"
    suites = sorted({Path(str(i.fspath)).stem[len("test_"):] for i in session.items if Path(str(i.fspath)).parent == here})
    if JOBS < 2 or not suites:
        return
    shared = [s for s in suites if _shares_files(s)]
    jobs = ([shared] if shared else []) + [[s] for s in suites if s not in shared]
    jobs.sort(key=lambda j: -sum(len(re.findall(r"^func ev\d+\(", _src(s), re.M)) for s in j))  # EV가 많은 작업부터. 끝에 큰 작업 하나만 남아 기다리지 않게
    for s in suites:
        _ready[s] = threading.Event()
    _pool = ThreadPoolExecutor(max_workers=JOBS)
    for j in jobs:
        _pool.submit(_job, j)


def pytest_sessionfinish(session):
    if _pool:
        _pool.shutdown(wait=False, cancel_futures=True)


@pytest.fixture
def gd():
    """tests/eval/gd/<suite>.gd 의 ev<번호>()를 headless Godot로 돌린다. 그 EV 출력 조각에 PASS 줄이 있으면 통과다."""
    def run(suite, ev):
        if suite in _ready:
            _ready[suite].wait()
        elif suite not in _suites:
            _suites[suite] = _run_suite(suite)
        got, missing = _suites[suite]
        out = got.get(ev, missing)
        assert f"PASS {ev}" in out, out[-3000:]
    return run
