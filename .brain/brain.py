"""td-proj 세컨드 브레인 CLI. 보통은 .brain/build · .brain/query · .brain/why 래퍼로 부른다.

  build                       전체 색인(.brain/brain.db). 질의는 색인이 오래되면 스스로 다시 만든다
  query impact <대상>          거꾸로 BFS: 바꾸면 영향받는 호출자·화면·봇·테스트와 돌릴 테스트
  query callers <대상>         한 단계 호출자만
  query find <이름>            심볼 id 찾기
  query unresolved [--file F] [--category C]   정적으로 못 정한 연결(미확인 경로)
  query stats                 색인 통계
  why <대상|S·I·U·EV ID|낱말>   SPEC 문장·변경 이력·지키는 평가·커밋·설계 기록

대상: 경로#심볼(src/sim/battle.gd#repair_cost), 경로#안쪽클래스.멤버, 경로:줄, 경로(파일 전체), 맨 이름(repair_cost)
"""
from __future__ import annotations

import argparse
import json
import sys
import time

sys.dont_write_bytecode = True  # 저장소에 __pycache__를 남기지 않는다

from brainlib import build, impact, store, why  # noqa: E402
from brainlib.util import short  # noqa: E402


def _out(text: str) -> None:
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")  # Windows 파이프(cp949)에서도 « » · → 를 낸다
    except Exception:
        pass
    print(text)


def _targets(con, text: str):
    ids, kind, cands = store.resolve(con, text)
    if not ids:
        if cands:
            msg = [f"«{text}»에 맞는 심볼이 {len(cands)}개다 — 경로#심볼로 다시 부른다:"]
            msg += [f"  {c}" for c in cands[:20]]
            if len(cands) > 20:
                msg.append(f"  … 외 {len(cands) - 20}개")
            _out("\n".join(msg))
            sys.exit(2)
        return None, kind
    return ids, kind


def cmd_build(a) -> int:
    t = time.time()
    st = build.build()
    if a.json:
        _out(json.dumps(st, ensure_ascii=False, indent=1))
        return 0
    e = st["edges_by_conf"]
    u = st["unresolved_by_cat"]
    lines = [
        f"[brain] 색인 완료 {time.time() - t:.1f}초 → .brain/brain.db",
        f"  파일 {st['files']}(GDScript {st['gd_files']}) · 심볼 {st['symbols']} · 엣지 {st['edges']}"
        f" (확정 {e.get('static', 0)} · 추론 {e.get('inferred', 0)} · 동적 {e.get('dynamic', 0)} · 미확인 {e.get('ambiguous', 0)})",
        f"  미확인 지점 {st['unresolved']}: " + " · ".join(f"{k} {v}" for k, v in u.items()),
        f"  SPEC 문장 {st['spec']}(§3.1 참조 {st['spec_refs']}) · EV {st['evals']} · 커밋 {st['commits']} · 검색 문서 {st['docs']}",
    ]
    if st["shallow"]:
        lines.append("  ⚠ 얕은 복제(shallow) — 오래된 커밋이 없다: git fetch --unshallow")
    if st["warnings"]:
        lines.append(f"  ⚠ 스캐너 경고 {len(st['warnings'])}: " + "; ".join(st["warnings"][:3]))
    _out("\n".join(lines))
    return 0


def cmd_query(a) -> int:
    con = store.open_db(not a.no_rebuild)
    if a.sub == "stats":
        m = store.meta(con)
        _out(json.dumps({k: v for k, v in m["stats"].items() if k != "dirty"}, ensure_ascii=False, indent=1))
        return 0
    if a.sub == "find":
        rows = con.execute("SELECT id, kind, line, end_line, signature FROM symbols WHERE name LIKE ? OR qual LIKE ? ORDER BY (name!=?), id LIMIT 40",
                           (a.target, a.target, a.target)).fetchall()
        _out("\n".join(f"{r[0]}  {r[1]} :{r[2]}-{r[3]}  {short(r[4], 80)}" for r in rows) or "없다")
        return 0
    if a.sub == "unresolved":
        sql = "SELECT category, file, line, src, detail, candidates FROM unresolved WHERE 1=1"
        args = []
        if a.file:
            sql += " AND file=?"
            args.append(a.file)
        if a.category:
            sql += " AND category=?"
            args.append(a.category)
        if not a.file and not a.category:
            rows = con.execute("SELECT category, COUNT(*), COUNT(DISTINCT file) FROM unresolved GROUP BY category ORDER BY COUNT(*) DESC").fetchall()
            lines = ["미확인 연결(정적으로 확정하지 못한 곳) — 범주 · 지점 · 파일"]
            lines += [f"  {c:16} {n:5}곳  {f}파일" for c, n, f in rows]
            blind = con.execute("SELECT SUM(count), COUNT(*) FROM blind WHERE category='string-key'").fetchone()
            if blind and blind[0]:
                lines.append(f"  {'string-key':16} {blind[0]:5}곳  {blind[1]}파일  (사전 문자열 키 d[\"k\"]·d.get(\"k\") — 지점 목록 없이 수만 센다)")
            lines.append("자세히: query unresolved --category <범주> [--file <경로>]")
            _out("\n".join(lines))
            return 0
        rows = con.execute(sql + " ORDER BY file, line LIMIT ?", (*args, a.max)).fetchall()
        _out("\n".join(f"{r[0]:14} {r[1]}:{r[2]}  {short(r[4], 120)}" + (f"\n{'':15}후보: {short(r[5], 140)}" if r[5] else "") for r in rows) or "없다")
        return 0
    ids, kind = _targets(con, a.target)
    if ids is None:
        _out(f"«{a.target}»를 찾지 못했다 — query find <이름>으로 찾는다")
        return 1
    if a.sub == "callers":
        rows = []
        for t in ids:
            rows += con.execute("SELECT src, kind, conf, file, line FROM edges WHERE dst=? ORDER BY conf, file, line", (t,)).fetchall()
        _out("\n".join(f"{r[2]:9} {r[1]:12} {r[3]}:{r[4]}  {r[0]}" for r in rows) or "호출자가 없다")
        return 0
    _out(impact.run(con, ids, kind, depth=a.depth, follow_ambiguous=a.follow_ambiguous, max_lines=a.max, show_all=a.all))
    return 0


def cmd_why(a) -> int:
    con = store.open_db(not a.no_rebuild)
    text = " ".join(a.target)
    ids = None
    if not why.ID_ONLY.match(text.strip().upper()) and (" " not in text.strip() or "#" in text or ":" in text):
        r = store.resolve(con, text)
        if r[0]:
            ids = r[0]
            if r[1] == "file":
                _out(f"why는 심볼 하나를 본다 — 파일 전체는 query impact {text}, 심볼은 {text}#이름")
                return 1
        elif r[2] and "#" in text:
            _out(f"«{text}»에 맞는 심볼이 여럿이다:\n" + "\n".join(f"  {c}" for c in r[2][:20]))
            return 2
        elif r[2] and len(r[2]) <= 3:
            ids = r[2][:1] if len(r[2]) == 1 else None
            if ids is None:
                _out(f"«{text}»는 심볼 {len(r[2])}개와 이름이 같다 — 경로#심볼로 다시 부르거나, 낱말 검색으로 본다:\n"
                     + "\n".join(f"  {c}" for c in r[2]) + "\n")
    _out(why.run(con, text, ids or [], limit=a.limit, use_git=not a.no_git))
    return 0


def main(argv=None) -> int:
    p = argparse.ArgumentParser(prog="brain", description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sp = p.add_subparsers(dest="cmd", required=True)
    b = sp.add_parser("build", help="전체 색인")
    b.add_argument("--json", action="store_true")
    q = sp.add_parser("query", help="impact · callers · find · unresolved · stats")
    q.add_argument("sub", choices=["impact", "callers", "find", "unresolved", "stats"])
    q.add_argument("target", nargs="?", default="")
    q.add_argument("--depth", type=int, default=6)
    q.add_argument("--max", type=int, default=40, help="경로 줄 수 상한")
    q.add_argument("--all", action="store_true", help="줄이지 않고 모두")
    q.add_argument("--follow-ambiguous", action="store_true", help="미확인(후보 여럿) 호출자도 거슬러 올라간다")
    q.add_argument("--file", default="")
    q.add_argument("--category", default="")
    q.add_argument("--no-rebuild", action="store_true")
    w = sp.add_parser("why", help="왜 이렇게 되어 있나")
    w.add_argument("target", nargs="+")
    w.add_argument("--limit", type=int, default=8)
    w.add_argument("--no-git", action="store_true", help="git log -L을 건너뛴다")
    w.add_argument("--no-rebuild", action="store_true")
    a = p.parse_args(argv)
    if a.cmd == "query" and a.sub not in ("stats", "unresolved") and not a.target:
        p.error("대상이 필요하다")
    return {"build": cmd_build, "query": cmd_query, "why": cmd_why}[a.cmd](a)


if __name__ == "__main__":
    sys.exit(main())
