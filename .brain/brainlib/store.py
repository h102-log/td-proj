"""색인 열기: 오래됐으면(파일 지문·HEAD·스키마 판이 다르면) 다시 만든다. 질의 대상 해석."""
from __future__ import annotations

import json
import re
import sqlite3
import sys
import time

from . import VERSION, build, history
from .util import DB_PATH, ROOT


def _stale_reason(con) -> str:
    meta = dict(con.execute("SELECT key, value FROM meta"))
    if meta.get("version") != str(VERSION):
        return "색인 판이 다르다"
    stored = {p: (s, m) for p, s, m in con.execute("SELECT path, size, mtime_ns FROM fp")}
    current = build.fingerprint(build.inputs())
    changed = [p for p, v in current.items() if stored.get(p) != v]
    gone = [p for p in stored if p not in current]
    if changed or gone:
        names = (changed + gone)[:3]
        more = len(changed) + len(gone) - len(names)
        return "바뀐 파일 " + ", ".join(names) + (f" 외 {more}개" if more > 0 else "")
    if history.head() != meta.get("head"):
        return "HEAD가 바뀌었다"
    return ""


def open_db(rebuild: bool = True) -> sqlite3.Connection:
    reason = ""
    if not DB_PATH.exists():
        reason = "색인이 없다"
    else:
        try:
            con = sqlite3.connect(DB_PATH)
            reason = _stale_reason(con)
            if not reason or not rebuild:
                if reason:
                    print(f"[brain] 색인이 오래됐다({reason}) — --no-rebuild라 그대로 쓴다", file=sys.stderr)
                return con
            con.close()
        except sqlite3.DatabaseError:
            reason = "색인 파일이 깨졌다"
    t = time.time()
    st = build.build()
    print(f"[brain] 색인을 다시 만들었다({reason}, {time.time() - t:.1f}초)", file=sys.stderr)
    if st.get("shallow"):
        print("[brain] 얕은 복제(shallow)라 오래된 커밋이 없다 — why 결과가 짧을 수 있다: git fetch --unshallow", file=sys.stderr)
    return sqlite3.connect(DB_PATH)


def meta(con) -> dict:
    m = dict(con.execute("SELECT key, value FROM meta"))
    m["stats"] = json.loads(m.get("stats", "{}"))
    return m


def symbol(con, sid: str):
    return con.execute("SELECT * FROM symbols WHERE id=?", (sid,)).fetchone()


SYM_COLS = ("id", "file", "qual", "name", "kind", "cls", "line", "end_line", "doc_line", "head_line", "head_end", "static",
            "signature", "layer", "hangul", "ids", "doc", "notes", "entry", "fanin_files")


def sym(con, sid: str) -> dict | None:
    row = symbol(con, sid)
    return dict(zip(SYM_COLS, row)) if row else None


def resolve(con, text: str) -> tuple[list[str], str, list[str]]:
    """질의 글 → (대상 id들, 대상 종류 'symbol'|'file', 고를 후보들)."""
    text = text.strip().replace("\\", "/")
    if text.startswith("./"):
        text = text[2:]
    if text.startswith("res://"):
        text = text[len("res://"):]
    if "#" in text:
        if sym(con, text):
            return [text], "symbol", []
        path, _, q = text.partition("#")
        name = q.split(".")[-1]
        cands = [r[0] for r in con.execute("SELECT id FROM symbols WHERE file=? AND (qual=? OR name=?)", (path, q, name))]
        if len(cands) == 1:
            return cands, "symbol", []
        if not cands:
            cands = [r[0] for r in con.execute("SELECT id FROM symbols WHERE name=? ORDER BY id", (name,))]
        return [], "symbol", cands
    m = re.match(r"^(.+?):(\d+)$", text)
    if m:
        path, line = m.group(1), int(m.group(2))
        rows = con.execute(
            "SELECT id, kind, end_line - doc_line FROM symbols WHERE file=? AND doc_line<=? AND end_line>=? ORDER BY (kind='class'), end_line - doc_line",
            (path, line, line)).fetchall()
        if rows:
            return [rows[0][0]], "symbol", []
        return [], "symbol", []
    if con.execute("SELECT 1 FROM files WHERE path=?", (text,)).fetchone() or (ROOT / text).is_file():
        ids = [r[0] for r in con.execute("SELECT id FROM symbols WHERE file=? AND cls='' ORDER BY line", (text,))]
        return [text] + ids, "file", []
    cands = [r[0] for r in con.execute("SELECT id FROM symbols WHERE name=? OR qual=? ORDER BY (kind!='func'), id", (text, text))]
    if len(cands) == 1:
        return cands, "symbol", []
    return [], "symbol", cands
