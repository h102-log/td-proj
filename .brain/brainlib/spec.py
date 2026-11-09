"""SPEC.md·EVAL.md 장부 읽기(읽기만 한다).

SPEC: §1·§2.2 문장(S·I), §2.3 표·§3.2 목록(U), §3.1 문장 대조(문장 → 코드 줄), §4 아카이브.
EVAL: §1 평가 항목(EV → 근거 문장·테스트 파일), 개정 표(EV → 바뀐 사유·날짜).
"""
from __future__ import annotations

import re

ITEM_RE = re.compile(r"^- ([SIU]\d+)\.\s*(.*)$")
ROW_RE = re.compile(r"^\|\s*([SIU]\d+)\s*\|(.*)\|\s*$")
REF_RE = re.compile(r"([\w./-]+\.\w+):(\d+)(?:-(\d+))?")
CHANGE_RE = re.compile(r"(?:→\s*)?\*\*(\d{4}-\d{2}-\d{2})\s*(둘째|셋째|넷째|다섯째)?\s*변경:?\*\*:?")
EV_ROW_RE = re.compile(r"^\|\s*(EV\d+(?:\s*·\s*EV\d+)*)\s*\|(.*)\|\s*$")


def basis_span(text: str) -> tuple[int, int] | None:
    """«(근거: …)»의 [시작, 끝) — 안쪽 괄호 짝을 센다."""
    i = text.find("(근거:")
    if i < 0:
        return None
    depth = 0
    for j in range(i, len(text)):
        if text[j] == "(":
            depth += 1
        elif text[j] == ")":
            depth -= 1
            if depth == 0:
                return i, j + 1
    return i, len(text)


def strip_basis(text: str) -> str:
    while True:
        sp = basis_span(text)
        if sp is None:
            return text
        text = (text[: sp[0]].rstrip() + " " + text[sp[1]:].lstrip()).strip()


def _split_changes(text: str) -> tuple[str, list]:
    """문장 글 → (처음 글, [(날짜, 차례, 바뀐 글)])."""
    marks = list(CHANGE_RE.finditer(text))
    if not marks:
        return text.strip(), []
    base = text[: marks[0].start()].strip()
    changes = []
    for i, m in enumerate(marks):
        end = marks[i + 1].start() if i + 1 < len(marks) else len(text)
        changes.append((m.group(1), m.group(2) or "", text[m.end():end].strip()))
    return base, changes


def parse_spec(text: str) -> tuple[list[dict], list[tuple]]:
    """→ (문장들, §3.1 참조들 [(ID, 경로, 시작, 끝)])."""
    sentences: list[dict] = []
    refs: list[tuple] = []
    section = ""
    cur = None
    for no, line in enumerate(text.split("\n"), 1):
        if line.startswith("#"):
            m = re.match(r"^#{2,3}\s*([\d.]+)", line)
            section = m.group(1).rstrip(".") if m else line.strip("# ").split()[0]
            cur = None
            continue
        m = ITEM_RE.match(line)
        if m and section in ("1", "2.2", "3.2"):
            sid, body = m.groups()
            cur = {"id": sid, "kind": sid[0], "section": section, "line": no, "text": body}
            sentences.append(cur)
            continue
        if cur is not None and line.startswith("  ") and line.strip():
            cur["text"] += "\n" + line.strip()
            continue
        if not line.strip():
            cur = None
        r = ROW_RE.match(line)
        if not r:
            continue
        rid, rest = r.groups()
        cols = [c.strip() for c in rest.split("|")]
        if section == "3.1":
            cell = cols[0] if cols else ""
            for rm in REF_RE.finditer(cell):
                a = int(rm.group(2))
                b = int(rm.group(3) or a)
                refs.append((rid, rm.group(1), a, b))
            if "없어짐" in cell:
                refs.append((rid, "", 0, 0))  # 표시만(없어진 문장)
        elif section == "2.3":
            # | U# | 침묵 지점 | 적용한 기본값 | 대안 | 상태 | 번복 조건 |
            txt = " / ".join(c for c in cols[:2] if c)
            status = cols[3] if len(cols) > 3 else ""
            sentences.append({"id": rid, "kind": "U", "section": section, "line": no, "text": f"{txt} (상태: {status})"})
        elif section == "4":
            sentences.append({"id": rid, "kind": rid[0], "section": section, "line": no,
                              "text": (cols[0] if cols else "") + " (아카이브)"})
    for s in sentences:
        base, changes = _split_changes(s["text"])
        s["base"] = base
        s["changes"] = changes
        sp = basis_span(base)
        s["basis"] = base[sp[0] + len("(근거:"): sp[1] - 1].strip() if sp else ""
        s["status"] = "archived" if s["section"] == "4" else ""
    gone = {rid for rid, p, a, b in refs if not p}
    for s in sentences:
        if s["id"] in gone:
            s["status"] = "removed"
    return sentences, [r for r in refs if r[1]]


def parse_eval(text: str) -> tuple[list[dict], list[dict]]:
    """→ (평가 항목들, 개정 행들)."""
    items, revs = [], []
    section = ""
    for no, line in enumerate(text.split("\n"), 1):
        if line.startswith("## "):
            section = "1" if line.startswith("## 1.") else line[3:].split()[0]
            continue
        m = EV_ROW_RE.match(line)
        if not m:
            continue
        ids = [x.strip() for x in m.group(1).split("·")]
        cols = [c.strip() for c in m.group(2).split("|")]
        if section == "1" and len(ids) == 1 and len(cols) >= 5:
            # | ID | 근거 | 근거 해시 | 무엇을 어떻게 재나 | 테스트 | 승인 |
            items.append({"id": ids[0], "basis": cols[0], "hash": cols[1], "desc": cols[2], "test": cols[3],
                          "approval": cols[4] if len(cols) > 4 else "", "line": no})
        elif section == "개정" and len(cols) >= 3:
            for ev in ids:
                revs.append({"id": ev, "hash": cols[0], "reason": cols[1], "date": cols[2], "line": no})
        elif section in ("기각",) and cols:
            for ev in ids:
                items.append({"id": ev, "basis": "", "hash": "", "desc": cols[0], "test": "", "approval": "기각", "line": no})
    return items, revs
