"""공통 손잡이: 저장소 경로, 레이어 분류, SPEC·EVAL ID 뽑기."""
from __future__ import annotations

import os
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]  # .brain/brainlib/util.py → 저장소 루트
DB_PATH = ROOT / ".brain" / "brain.db"

# 색인 범위. 제외한 곳과 이유는 SKILL.md «색인 범위»에 있다
CODE_ROOTS = ("src", "tests", "tools")  # .gd 전부(그래프)
PY_ROOTS = ("tests", "tools")  # .py는 테스트 래퍼(gd 호출)와 res:// 문자열만 본다
RES_ROOTS = ("data", "src")  # .tres·.tscn
DOC_ROOTS = ("insights", "play_review")  # why 검색용 설계 기록(.md)
LEDGERS = ("SPEC.md", "EVAL.md")
EXTRA_FILES = ("project.godot", "locale/en.po", "tests/eval/conftest.py")

# 레이어: impact 출력의 묶음 이름. 앞에서부터 처음 맞는 것
LAYERS = (
    ("src/sim/", "sim"),
    ("src/ui/", "ui"),
    ("src/data/", "data-def"),
    ("src/", "app"),
    ("data/", "data"),
    ("tests/eval/", "eval"),
    ("tests/unit/", "unit"),
    ("tools/balance/", "bot"),
    ("tools/play/", "play"),
    ("tools/bench/", "bench"),
    ("tools/", "tools"),
    ("locale/", "locale"),
    ("art/", "asset"),
    ("audio/", "asset"),
)


def layer_of(path: str) -> str:
    for prefix, name in LAYERS:
        if path.startswith(prefix):
            return name
    if path.endswith(".tscn") or path == "project.godot":
        return "scene"
    return "other"


def rel(p: os.PathLike | str) -> str:
    return Path(p).resolve().relative_to(ROOT).as_posix()


def read_text(path: Path) -> str:
    with open(path, encoding="utf-8", errors="replace") as f:  # 줄 끝(CRLF)은 여기서 \n으로 바뀐다
        return f.read()


# SPEC·EVAL ID: S12 · I3 · U9 · EV804, 범위(S299~S302, EV780~788)도 펼친다
ID_RE = re.compile(r"(?<![A-Za-z0-9_])(EV|S|I|U)(\d{1,4})(?:\s*~\s*(?:EV|S|I|U)?(\d{1,4}))?(?![A-Za-z0-9_])")
PR_RE = re.compile(r"(?<![\w&])#(\d{2,4})(?!\d)")
MAX_RANGE = 60  # 이보다 넓은 범위는 펼치지 않는다(오타·무관한 수 방지)


def extract_ids(text: str) -> list[str]:
    out: list[str] = []
    seen = set()
    for m in ID_RE.finditer(text):
        kind, a, b = m.group(1), int(m.group(2)), m.group(3)
        nums = [a]
        if b is not None and a < int(b) <= a + MAX_RANGE:
            nums = list(range(a, int(b) + 1))
        for n in nums:
            key = f"{kind}{n}"
            if key not in seen:
                seen.add(key)
                out.append(key)
    return out


def extract_prs(text: str) -> list[str]:
    return sorted({f"PR{m.group(1)}" for m in PR_RE.finditer(text)})


def git(*args: str, check: bool = False, timeout: int = 60) -> str:
    r = subprocess.run(
        ["git", "-C", str(ROOT), "-c", "core.quotepath=off", "-c", "i18n.logOutputEncoding=UTF-8", *args],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, encoding="utf-8", errors="replace", timeout=timeout,
    )
    if check and r.returncode != 0:
        raise RuntimeError(f"git {' '.join(args)}: {r.stderr.strip()}")
    return r.stdout if r.returncode == 0 else ""


def short(text: str, n: int) -> str:
    text = " ".join(text.split())
    return text if len(text) <= n else text[: n - 1] + "…"
