"""why: 이 코드(또는 SPEC 문장·EV·낱말)가 왜 이렇게 되어 있나 — SPEC 문장·변경 이력·지키는 평가·커밋·설계 기록."""
from __future__ import annotations

import json
import re

from . import fts, history
from .impact import _id_key, _sentence_tests
from .spec import strip_basis
from .store import meta, sym
from .util import short

ID_ONLY = re.compile(r"^(S|I|U|EV)\d+$")


def run(con, text: str, targets: list[str], limit: int = 8, use_git: bool = True) -> str:
    q = text.strip()
    if ID_ONLY.match(q.upper()):
        q = q.upper()
        return why_eval(con, q, limit) if q.startswith("EV") else why_sentence(con, q, limit)
    if targets:
        return why_symbol(con, targets[0], limit, use_git)
    return search(con, q, limit)


# ── SPEC 문장 ─────────────────────────────────────────────────
def _sentence(con, sid: str):
    r = con.execute("SELECT id, kind, section, line, base, basis, changes, status FROM spec WHERE id=?", (sid,)).fetchone()
    if not r:
        return None
    return {"id": r[0], "kind": r[1], "section": r[2], "line": r[3], "base": r[4], "basis": r[5],
            "changes": json.loads(r[6] or "[]"), "status": r[7]}


def _sentence_line(con, sid: str, src: str = "", width: int = 150) -> list[str]:
    s = _sentence(con, sid)
    out = []
    if s is None:
        return [f"  {sid} — SPEC에 없다(지운 문장이거나 오타)"]
    tag = f"[{src}] " if src else ""
    status = {"removed": " (없어진 문장)", "archived": " (아카이브)"}.get(s["status"], "")
    out.append(f"  {tag}{sid}{status} {short(strip_basis(s['base']), width)}")
    if s["changes"]:
        last = s["changes"][-1]
        dates = ", ".join(f"{d}{(' ' + o) if o else ''}" for d, o, _ in s["changes"])
        out.append(f"      변경 {len(s['changes'])}회({dates}) — 최근: {short(last[2], width - 20)}")
    evs = con.execute("SELECT id, test, merge_only FROM evals WHERE basis=? AND approval!='기각' ORDER BY line", (sid,)).fetchall()
    if evs:
        tests = sorted({re.sub(r"^tests/eval/test_(\w+)\.py$", r"\1", t or "") for _, t, _ in evs})
        mo = [e for e, _, m in evs if m]
        out.append(f"      평가 {' '.join(e for e, _, _ in evs[:8])}{' …' if len(evs) > 8 else ''} ({', '.join(tests)})"
                   + (f" · 머지 전용 {' '.join(mo[:4])}" if mo else ""))
    elif s["kind"] in "SI" and not s["status"]:
        out.append("      평가 없음 ⚠ — 이 동작을 지우거나 바꿔도 테스트가 못 잡는다")
    return out


def why_sentence(con, sid: str, limit: int) -> str:
    s = _sentence(con, sid)
    if s is None:
        return f"{sid}: SPEC에 없다"
    out = [f"why {sid} — SPEC §{s['section']} (SPEC.md:{s['line']}){' · 없어진 문장' if s['status'] == 'removed' else ''}"]
    out.append(f"  {short(strip_basis(s['base']), 400)}")
    if s["basis"]:
        out.append(f"  근거: {short(s['basis'], 200)}")
    for d, o, txt in s["changes"]:
        out.append(f"  → {d}{(' ' + o) if o else ''} 변경: {short(txt, 200)}")
    refs = con.execute("SELECT path, start, end_line FROM spec_refs WHERE id=? ORDER BY path, start", (sid,)).fetchall()
    if refs:
        out.append("")
        out.append("[코드] §3.1 문장 대조")
        for path, a, b in refs[:limit * 2]:
            names = [r[0].split("#")[-1] for r in con.execute(
                "SELECT id FROM symbols WHERE file=? AND kind!='class' AND head_line - (line - doc_line)<=? AND head_end>=? ORDER BY head_line",
                (path, b, a))]
            out.append(f"  {path}:{a}{'-' + str(b) if b != a else ''}" + (f" → {', '.join(names[:4])}" if names else ""))
        if len(refs) > limit * 2:
            out.append(f"  … 외 {len(refs) - limit * 2}곳")
    mentions = [r[0] for r in con.execute("SELECT id FROM symbols WHERE (' ' || ids || ' ') LIKE ?", (f"% {sid} %",))]
    if mentions:
        out.append(f"  주석에 {sid}가 적힌 심볼 {len(mentions)}개: " + ", ".join(mentions[:limit]) + (" …" if len(mentions) > limit else ""))
    evs = con.execute("SELECT id, descr, test, merge_only FROM evals WHERE basis=? AND approval!='기각' ORDER BY line", (sid,)).fetchall()
    out.append("")
    if evs:
        out.append(f"[평가] {sid}를 지키는 EV {len(evs)}개")
        for ev, desc, test, mo in evs[:limit]:
            nrev = con.execute("SELECT COUNT(*) FROM eval_revs WHERE id=?", (ev,)).fetchone()[0]
            out.append(f"  {ev}{' (머지 전용)' if mo else ''} {short(desc, 120)} — {test}" + (f" · 개정 {nrev}회" if nrev else ""))
    else:
        out.append(f"[평가] {sid}를 지키는 EV가 없다 ⚠")
    _commits_mentioning(con, sid, limit, out)
    _related_docs(con, sid, limit, out, exclude_kinds=("spec", "eval", "commit", "code"))
    return "\n".join(out)


def why_eval(con, ev: str, limit: int) -> str:
    r = con.execute("SELECT id, basis, descr, test, approval, merge_only, line FROM evals WHERE id=?", (ev,)).fetchone()
    if not r:
        return f"{ev}: EVAL에 없다"
    out = [f"why {ev} — EVAL.md:{r[6]} · 근거 {r[1]} · {r[4]}{' · 머지 전용(C)' if r[5] else ''}"]
    out.append(f"  잼: {short(r[2], 300)}")
    t = con.execute("SELECT eval_fn, py_file, py_test FROM tests WHERE ev=?", (ev,)).fetchone()
    if t:
        s = sym(con, t[0])
        out.append(f"  테스트: {t[1]}::{t[2]} → {t[0]}" + (f" ({s['file']}:{s['line']}-{s['end_line']})" if s else ""))
    elif r[3]:
        out.append(f"  테스트 파일: {r[3]}")
    revs = con.execute("SELECT date, reason FROM eval_revs WHERE id=? ORDER BY date", (ev,)).fetchall()
    if revs:
        out.append(f"  개정 {len(revs)}회:")
        for d, why in revs[-limit:]:
            out.append(f"    {d} {short(why, 150)}")
    if r[1]:
        out.append("")
        out.append("[근거 문장]")
        out += _sentence_line(con, r[1], width=200)
    _commits_mentioning(con, ev, limit, out)
    return "\n".join(out)


def _commits_mentioning(con, key: str, limit: int, out: list) -> None:
    rows = con.execute(
        "SELECT c.short, c.date, c.subject FROM commit_ids i JOIN commits c ON c.short=i.short WHERE i.id=? AND c.merge=0 ORDER BY c.date DESC",
        (key,)).fetchall()
    if rows:
        out.append("")
        out.append(f"[커밋] 메시지에 {key}가 나오는 커밋 {len(rows)}개(새것부터)")
        for h, d, s in rows[:limit]:
            out.append(f"  {h} {d} {short(s, 120)}")
        if len(rows) > limit:
            out.append(f"  … 외 {len(rows) - limit}개 (가장 오래된 것: {rows[-1][0]} {rows[-1][1]})")


def _related_docs(con, q: str, limit: int, out: list, exclude_kinds=(), header="[설계 기록]") -> None:
    hits = _fts(con, q, limit * 3)
    hits = [h for h in hits if h[1] not in exclude_kinds][:limit]
    if hits:
        out.append("")
        out.append(header)
        for rowid, kind, ref, title, body, date, score in hits:
            out.append(f"  {kind:7} {ref if kind != 'commit' else ref + ' ' + date} — {short(fts.snippet(title + ' ' + body, q, 100), 120)}")


# ── 심볼 ─────────────────────────────────────────────────────
def why_symbol(con, sid: str, limit: int, use_git: bool) -> str:
    s = sym(con, sid)
    if s is None:
        return f"{sid}: 색인에 없는 심볼"
    m = meta(con)
    out = [f"why {sid}"]
    out.append(f"  {s['kind']} · {s['file']}:{s['doc_line']}-{s['end_line']} · {short(s['signature'], 110)}")
    if s["doc"]:
        out.append("  주석: " + short(s["doc"].replace("\n", " "), 300))
    if s["notes"]:
        for n in s["notes"].split("\n")[:6]:
            out.append("  메모: " + short(n, 200))
    dirty = s["file"] in set(m["stats"].get("dirty", []))
    if dirty:
        out.append("  (작업 트리가 HEAD와 다르다 — SPEC §3.1·커밋은 HEAD 판 줄로 찾는다)")

    ids, evs = _sentence_tests(con, [s])
    if ids:
        out.append("")
        out.append(f"[SPEC] 이 코드가 구현하는 문장 {len(ids)}개 (§3.1 = 문장 대조 줄 겹침, 주석 = 코드 주석의 ID)")
        order = sorted(ids, key=lambda k: (-len(ids[k]), _id_key(k)))
        for k in order[:limit]:
            out += _sentence_line(con, k, "·".join(sorted(ids[k])))
        if len(order) > limit:
            out.append(f"  … 외 {len(order) - limit}개: {' '.join(order[limit:limit + 12])}")
        unguarded = [k for k in order if k[0] in "SI" and not any(e[0] == k for e in evs) and not _sentence_status(con, k)]
        if unguarded:
            out.append(f"  ⚠ 평가 없는 문장 {len(unguarded)}개: {' '.join(unguarded[:10])} — 이 부분을 지우면 테스트가 못 잡는다")
    else:
        out.append("")
        out.append("[SPEC] 이 코드에 이어진 SPEC 문장이 없다(§3.1·주석 둘 다)")

    if use_git and (s["head_line"] or not dirty):
        hs = s["head_line"] - (s["line"] - s["doc_line"]) if s["head_line"] else s["doc_line"]
        he = s["head_end"] or s["end_line"]
        rows = history.line_history(s["file"], max(1, hs), max(hs, he), limit=60)
        out.append("")
        if rows:
            out.append(f"[커밋] git log -L {s['file']}:{hs}-{he} — 이 줄들을 바꾼 커밋 {len(rows)}개(새것부터, 맨 아래가 도입)")
            keys = [s["name"], s["file"].split("/")[-1].replace(".gd", "")] + sorted(ids)[:12]
            shown = rows if len(rows) <= limit else rows[: limit - 1] + [rows[-1]]
            for i, (h, d, subj) in enumerate(shown):
                tag = " [도입]" if (h, d, subj) == rows[-1] and len(rows) < 60 else ""
                if i == limit - 1 and len(rows) > limit:
                    out.append(f"  … 사이 {len(rows) - limit}개")
                out.append(f"  {h} {d}{tag} {short(subj, 115)}")
                for line in _relevant_lines(con, h, keys)[:2]:
                    out.append(f"      · {short(line, 150)}")
            if m.get("shallow") == "True":
                out.append("  (얕은 복제라 이보다 오래된 커밋은 없다: git fetch --unshallow)")
        else:
            out.append("[커밋] 이 줄들의 커밋 히스토리를 찾지 못했다(새로 만든 코드이거나 HEAD에 없다)")

    q = s["name"] if len(s["name"]) >= 4 and s["name"] not in ("_init", "_ready", "_process", "_draw") else ""
    if q:
        _related_docs(con, q, min(limit, 5), out, exclude_kinds=("code", "eval", "spec"),
                      header=f"[관련 기록] «{q}»가 나오는 커밋·설계 기록(BM25)")
    return "\n".join(out)


def _sentence_status(con, sid: str) -> str:
    r = con.execute("SELECT status FROM spec WHERE id=?", (sid,)).fetchone()
    return r[0] if r else ""


def _relevant_lines(con, short_hash: str, keys: list[str]) -> list[str]:
    r = con.execute("SELECT body FROM commits WHERE short=?", (short_hash,)).fetchone()
    if not r or not r[0]:
        return []
    out = []
    for line in r[0].split("\n"):
        t = line.strip().lstrip("-").strip()
        if not t or t.startswith(("Co-Authored-By", "Claude-Session", "https://")):
            continue
        if any(k and (k in t) for k in keys):
            out.append(t)
    return out


# ── 낱말 검색 ─────────────────────────────────────────────────
def _fts(con, q: str, limit: int):
    rows = []
    for mode in ("and", "or"):
        expr = fts.match_expr(q, mode)
        if not expr:
            return []
        try:
            rows = con.execute(
                "SELECT d.rowid, d.kind, d.ref, d.title, d.body, d.date, bm25(fts, 4.0, 1.0, 6.0) AS score "
                "FROM fts JOIN docs d ON d.rowid = fts.rowid WHERE fts MATCH ? ORDER BY score LIMIT ?",
                (expr, limit)).fetchall()
        except Exception:
            rows = []
        if len(rows) >= 3 or mode == "or":
            break
    return rows


def search(con, q: str, limit: int) -> str:
    hits = _fts(con, q, max(40, limit * 5))
    if not hits:
        return f"why «{q}» — 찾은 기록이 없다"
    out = [f"why «{q}» — 기록 {len(hits)}건(BM25, 종류마다 위에서부터)"]
    groups = {}
    for h in hits:
        groups.setdefault(h[1], []).append(h)
    names = {"commit": "커밋", "spec": "SPEC 문장", "eval": "평가", "code": "코드 주석", "insight": "인사이트", "review": "플레이 후기"}
    for kind in ("spec", "commit", "code", "eval", "insight", "review"):
        g = groups.get(kind)
        if not g:
            continue
        out.append("")
        out.append(f"[{names[kind]}]")
        for rowid, k, ref, title, body, date, score in g[:limit]:
            label = f"{ref} {date}" if k == "commit" else ref
            text = title + " — " + body if k in ("commit", "insight", "review") else body
            out.append(f"  {label} — {short(fts.snippet(text, q, 120), 140)}")
        if len(g) > limit:
            out.append(f"  … 외 {len(g) - limit}건")
    return "\n".join(out)
