"""impact: 거꾸로 BFS — 이 심볼을 바꾸면 영향을 받는 호출자·화면·봇·테스트, 그리고 돌릴 테스트."""
from __future__ import annotations

import fnmatch
import re
from collections import defaultdict

from .store import sym
from .util import layer_of, short

HUB_FILES = 15  # 이만큼 많은 파일에서 불리는 함수(테스트용 API·메인 루프)는 «허브». 허브를 거쳐 닿는 곳은 따로 센다
NEAR_HOPS = 3  # 테스트 2순위: 허브를 거치지 않고 이 hop 안에서 닿는 평가·유닛
LAYER_ORDER = ("ui", "app", "bot", "play", "bench", "scene", "data", "data-def", "sim", "eval", "unit", "tools", "locale", "asset", "other")
TRAVERSE = ("calls", "uses", "instantiates", "emits", "connects", "handles", "checks", "sets", "runs", "preloads",
            "loads", "references", "reads-text", "instance-of", "extends", "overrides", "mirrors")
CONF_KO = {"static": "확정", "inferred": "추론", "dynamic": "동적", "ambiguous": "미확인", "virtual": "가상호출"}


def _edges_into(con, node: str):
    return con.execute("SELECT src, kind, conf, line, file, via FROM edges WHERE dst=?", (node,)).fetchall()


def _parents_of_override(con, node: str):
    return [r[0] for r in con.execute("SELECT dst FROM edges WHERE src=? AND kind='overrides' AND conf='static'", (node,))]


def _hub(con, node: str, starts: set) -> bool:
    """허브: 아주 많은 파일에서 불리는 함수(테스트용 API·메인 루프)거나, 테스트가 프레임을 돌리려고 직접 부르는 엔진 콜백."""
    if node in starts or "#" not in node:
        return False
    r = con.execute("SELECT fanin_files, entry FROM symbols WHERE id=?", (node,)).fetchone()
    return bool(r) and (r[0] >= HUB_FILES or r[1] == "engine")


def _is_test(node: str) -> bool:
    return node.startswith(("tests/eval/", "tests/unit/"))


def _is_leaf(node: str) -> bool:
    """테스트 진입 함수(ev123·test_*)와 pytest 래퍼: 여기에 기대는 코드는 없으니 더 펴지 않는다(헬퍼는 편다)."""
    if node.startswith("tests/eval/test_") or node.startswith("tests/unit/test_"):
        return True
    return bool(re.match(r"tests/eval/gd/\w+\.gd#ev\d+$", node) or re.match(r"tests/unit/gd/test_\w+\.gd#test_\w+$", node))


def bfs(con, starts: list[str], depth: int, follow_ambiguous: bool = False):
    """→ (seen: node → 정보, ambiguous: [(src, dst, kind, line, file, via)], hubs: [node])."""
    start_set = set(starts)
    seen = {s: {"hop": 0, "parent": None, "kind": "", "conf": "", "line": 0, "file": "", "via": "", "hubbed": False, "hub": False}
            for s in starts}
    ambiguous = []
    hubs = []

    def expand(frontier, hubbed):
        hop = 0
        while frontier and hop < depth:
            hop += 1
            nxt = []
            for node in frontier:
                base_hop = seen[node]["hop"]
                rows = list(_edges_into(con, node))
                for parent in _parents_of_override(con, node):  # 덮어쓴 함수: 부모 쪽 호출이 가상 호출로 여기에 닿는다
                    rows += [(s, k, "virtual" if c == "static" else c, ln, f, f"덮어씀: {parent}")
                             for s, k, c, ln, f, v in _edges_into(con, parent) if k == "calls"]
                for src, kind, conf, line, file, via in rows:
                    if kind not in TRAVERSE or src in seen:
                        continue
                    if conf == "ambiguous" and not follow_ambiguous:
                        # 대상과 그 바로 위(hop ≤ 1)의 미확인만 모은다. 엔진 콜백(_process 등)을 부르는 테스트 구동은 뺀다
                        if base_hop <= 1 and (base_hop == 0 or not _hub(con, node, start_set)):
                            ambiguous.append((src, node, kind, line, file, via))
                        continue
                    h = _hub(con, src, start_set)
                    seen[src] = {"hop": base_hop + 1, "parent": node, "kind": kind, "conf": conf, "line": line,
                                 "file": file, "via": via, "hubbed": hubbed, "hub": h}
                    if _is_leaf(src):
                        continue
                    if h and not hubbed:
                        hubs.append(src)  # 허브는 기록만 하고 2단계에서 편다
                    else:
                        nxt.append(src)
            frontier = nxt

    expand(list(starts), False)
    expand(list(hubs), True)
    return seen, ambiguous, hubs


def _sentence_tests(con, targets: list[dict]) -> tuple[dict, list]:
    """대상 코드가 구현하는 SPEC 문장(§3.1 줄 겹침 + 주석 ID) → 그 문장을 지키는 EV와 테스트 파일."""
    ids: dict = {}
    for t in targets:
        if not t or (t["kind"] == "class" and t["end_line"] - t["line"] > 400):
            continue
        hs, he = t["head_line"], t["head_end"]
        if hs and he:
            hs = hs - (t["line"] - t["doc_line"])
            for (sid,) in con.execute("SELECT DISTINCT id FROM spec_refs WHERE path=? AND start<=? AND end_line>=?", (t["file"], he, hs)):
                ids.setdefault(sid, set()).add("§3.1")
        for sid in (t["ids"] or "").split():
            if sid[0] in "SIU" and not sid.startswith("EV"):
                ids.setdefault(sid, set()).add("주석")
    evs = []
    for sid in sorted(ids, key=_id_key):
        for ev, test, mo in con.execute("SELECT id, test, merge_only FROM evals WHERE basis=? AND approval!='기각'", (sid,)):
            evs.append((sid, ev, test, mo))
    return ids, evs


def _id_key(x: str):
    m = re.match(r"([A-Z]+)(\d+)", x)
    return (m.group(1), int(m.group(2))) if m else (x, 0)


def _suite_of(node: str):
    m = re.match(r"tests/eval/gd/(\w+)\.gd#(ev\d+)$", node)
    if m:
        return "eval", m.group(1), m.group(2).upper()
    m = re.match(r"(tests/unit/gd/test_\w+\.gd)(?:#.*)?$", node)
    if m:
        return "unit", m.group(1), ""
    return None


def _textdeps(con, files: list[str]) -> list[tuple]:
    out, seen = [], set()
    pats = con.execute("SELECT src, file, line, kind, glob FROM patterns").fetchall()
    for f in files:
        for src, pf, line, pk, glob in pats:
            if (glob.endswith("/**") and f.startswith(glob[:-2])) or fnmatch.fnmatchcase(f, glob):
                if (src, line) not in seen:
                    seen.add((src, line))
                    out.append((src, pf, line, pk, glob))
        for src, k, line, pf in con.execute("SELECT src, kind, line, file FROM edges WHERE dst=? AND kind IN ('reads-text','references')", (f,)):
            if (src, line) not in seen:
                seen.add((src, line))
                out.append((src, pf, line, k, f))
    return out


def run(con, targets: list[str], kind: str, depth: int = 6, follow_ambiguous: bool = False, max_lines: int = 40,
        show_all: bool = False) -> str:
    out: list[str] = []
    tsyms = [sym(con, t) for t in targets if "#" in t]
    seen, ambiguous, hubs = bfs(con, targets, depth, follow_ambiguous)
    uniq = {}
    for a in ambiguous:  # 한 지점이 후보 여럿으로 갈라져 여러 번 잡힌다 → 지점마다 한 번
        uniq.setdefault((a[0], a[3], a[1].split("#")[-1].split(".")[-1]), a)
    ambiguous = list(uniq.values())
    files = sorted({t.split("#")[0] for t in targets})
    reached = {n: i for n, i in seen.items() if i["hop"] > 0}
    direct = {n: i for n, i in reached.items() if not i["hubbed"]}
    code = {n: i for n, i in direct.items() if not _is_test(n)}
    tests_reached = {n: i for n, i in reached.items() if _suite_of(n)}

    t0 = tsyms[0] if tsyms else None
    if kind == "symbol" and t0:
        out.append(f"impact {targets[0]}")
        out.append(f"  {t0['kind']} · {t0['file']}:{t0['line']}-{t0['end_line']} · {short(t0['signature'], 110)}")
    else:
        out.append(f"impact {files[0]} (파일 전체: 심볼 {len(targets) - 1}개)")
    cc = defaultdict(int)
    for i in code.values():
        cc[i["conf"]] += 1
    out.append("  코드 %d곳(%s) · 테스트 함수 %d개(허브 경유 포함) · 허브 경유 %d곳 · 미확인 %d곳 · 깊이 ≤%d" % (
        len(code), " · ".join(f"{CONF_KO.get(c, c)} {n}" for c, n in sorted(cc.items(), key=lambda kv: -kv[1])) or "없음",
        len(tests_reached), sum(1 for i in reached.values() if i["hubbed"]), len(ambiguous), depth))

    # ── 경로(테스트 제외) ──
    rows = sorted(((i["hop"], LAYER_ORDER.index(layer_of(n)) if layer_of(n) in LAYER_ORDER else 99, n, i) for n, i in code.items()),
                  key=lambda r: (r[0], r[1], r[2]))
    if rows:
        out.append("")
        out.append("[경로] hop 레이어 심볼 :줄 엣지(확실도) ← 거쳐 온 곳   (테스트는 아래 [테스트])")
        shown = rows if show_all else rows[:max_lines]
        for hop, _, n, i in shown:
            par = i["parent"]
            extra = ""
            if hop > 1 and par:
                extra = f"  ← {par.split('#')[-1] if par.split('#')[0] == n.split('#')[0] else par}"
            if i["conf"] in ("dynamic", "virtual") or i["via"] == "codegen":
                extra += f"  ({short(i['via'], 50)})"
            hub = " [허브]" if i.get("hub") else ""
            out.append(f"  {hop} {layer_of(n):5} {n} :{i['line']} {i['kind']}({CONF_KO.get(i['conf'], i['conf'])}){hub}{extra}")
        if len(rows) > len(shown):
            rest = rows[len(shown):]
            by_file = defaultdict(int)
            for _, _, n, _ in rest:
                by_file[n.split("#")[0]] += 1
            out.append(f"  … 외 {len(rest)}곳: " + ", ".join(f"{f} {c}" for f, c in sorted(by_file.items(), key=lambda kv: -kv[1])[:8])
                       + ("" if len(by_file) <= 8 else f" 외 파일 {len(by_file) - 8}개") + "  (--all로 모두)")
        lay = defaultdict(set)
        for n in code:
            lay[layer_of(n)].add(n.split("#")[0])
        out.append("")
        out.append("[레이어] " + " · ".join(f"{l} {len(lay[l])}파일" for l in LAYER_ORDER if l in lay))
        for l in ("ui", "app", "bot", "play", "bench", "data", "scene"):
            if l in lay:
                out.append(f"  {l}: " + ", ".join(sorted(lay[l])))
    else:
        out.append("")
        out.append("[경로] 이 심볼을 쓰는 코드를 정적으로 찾지 못했다" + (" (미확인 후보는 아래)" if ambiguous else ""))

    # ── 미확인·동적·글 의존 ──
    dyn = sorted(((n, i) for n, i in code.items() if i["conf"] in ("dynamic", "virtual")), key=lambda x: x[0])
    textdeps = _textdeps(con, files)
    if ambiguous or dyn or textdeps:
        out.append("")
        out.append("[미확인·동적] 정적으로 확정하지 못한 연결 — 사람이 열어 볼 곳")
    for n, i in dyn[:12]:
        what = "이름 대응" if i["kind"] == "mirrors" else i["kind"]
        out.append(f"  동적({what}) {n} :{i['line']} — {short(i['via'], 80)}")
    if ambiguous:
        eng = [a for a in ambiguous if a[5] == "engine-name"]
        amb = [a for a in ambiguous if a[5] != "engine-name"]
        lim = len(amb) if show_all else 10
        for src, dst, k, line, file, via in sorted(amb, key=lambda a: (a[4], a[3]))[:lim]:
            name = dst.split("#")[-1].split(".")[-1]
            det = con.execute("SELECT detail FROM unresolved WHERE src=? AND line=? AND category='ambiguous' AND detail LIKE ? LIMIT 1",
                              (src, line, f"%.{name} —%")).fetchone()
            out.append(f"  후보 {file}:{line} {short(det[0] if det else via, 90)}")
        if len(amb) > lim:
            by_file = defaultdict(int)
            for a in amb[lim:]:
                by_file[a[4]] += 1
            out.append(f"  … 후보 {len(amb) - lim}곳 더: " + ", ".join(f"{f} {c}" for f, c in sorted(by_file.items(), key=lambda kv: -kv[1])[:5]) + "  (--all)")
        if eng:
            by_file = defaultdict(int)
            for a in eng:
                by_file[a[4]] += 1
            out.append(f"  엔진 API와 이름이 같은 호출 {len(eng)}곳(대부분 Array·Dictionary·Node 메서드로 보인다): "
                       + ", ".join(f"{f} {c}" for f, c in sorted(by_file.items(), key=lambda kv: -kv[1])[:5]))
        out.append("  (미확인 호출자는 더 거슬러 올라가지 않는다. 따라가려면 --follow-ambiguous)")
    for src, pf, line, pk, glob in textdeps:
        what = {"scans-dir": "폴더째 읽음", "loads-pattern": "경로 틀로 불러옴", "reads-text": "소스 글을 읽음", "references": "경로 문자열"}.get(pk, pk)
        out.append(f"  글 {pf}:{line} {src.split('#')[-1]} — {what}({glob})")
    # 데이터 정의 필드·리플렉션으로 이어진 필드는 사전 키(stats.guard, d.get("guard"))로도 읽힌다 — 색인이 못 잇는 사각지대
    keyed = []
    defs = {r[0] for r in con.execute("SELECT DISTINCT dst FROM edges WHERE kind='instance-of'")}
    for t in tsyms:
        if t and t["kind"] == "var" and (t["file"] in defs or con.execute(
                "SELECT 1 FROM edges WHERE kind='mirrors' AND (src=? OR dst=?) LIMIT 1", (t["id"], t["id"])).fetchone()):
            keyed.append(t["name"])
    if keyed:
        if not (ambiguous or dyn or textdeps):
            out.append("")
            out.append("[미확인·동적] 정적으로 확정하지 못한 연결 — 사람이 열어 볼 곳")
        for name in sorted(set(keyed)):
            out.append(f"  사전 키 «{name}»로 읽는 곳은 잇지 못한다(데이터 정의 → *_KINDS 사전). 확인:")
            out.append(f"    grep -rnE '\\.{name}\\b|\"{name}\"' src tools tests --include=*.gd")

    # ── 테스트 ──
    near, far = defaultdict(set), defaultdict(set)
    units_near, units_far = set(), set()
    for n, i in tests_reached.items():
        s = _suite_of(n)
        close = not i["hubbed"] and i["hop"] <= NEAR_HOPS
        if s[0] == "eval":
            (near if close else far)[s[1]].add(s[2])
        else:
            (units_near if close else units_far).add(s[1])
    sids, sevs = _sentence_tests(con, tsyms) if tsyms and kind == "symbol" else ({}, [])
    spec_suites = defaultdict(set)
    for sid, ev, test, mo in sevs:
        m = re.match(r"tests/eval/test_(\w+)\.py", test or "")
        if m:
            spec_suites[m.group(1)].add(ev)
    locale = any(t and t["hangul"] for t in tsyms)
    out.append("")
    out.append("[테스트]")
    if sids:
        links = ", ".join(f"{s}({'·'.join(sorted(src))})" for s, src in sorted(sids.items(), key=lambda kv: _id_key(kv[0]))[:10])
        out.append(f"  1순위 SPEC 연결 — 이 코드가 구현하는 문장: {links}" + (" …" if len(sids) > 10 else ""))
        for s, evs in sorted(spec_suites.items()):
            out.append(f"    {s}: " + " ".join(sorted(evs, key=_id_key)))
        no_ev = [s for s in sorted(sids, key=_id_key) if s[0] in "SI" and not any(x[0] == s for x in sevs)]
        if no_ev:
            out.append(f"    ⚠ 지키는 EV가 없는 문장: {', '.join(no_ev[:8])} — 이 동작은 테스트가 못 잡는다(why로 확인)")
    if near or units_near:
        out.append(f"  2순위 호출 그래프(hop ≤{NEAR_HOPS}, 허브 미경유): "
                   + ", ".join(f"{s}({' '.join(sorted(e, key=_id_key)[:4])}{' …' if len(e) > 4 else ''})" for s, e in sorted(near.items()))
                   + ("" if not units_near else (" · 유닛 " + ", ".join(sorted(u.split('/')[-1] for u in units_near)))))
    far_only = {s for s in far if s not in near and s not in spec_suites}
    units_far -= units_near
    if far_only or units_far:
        hub_names = sorted({h.split("#")[-1] for h in hubs})[:6]
        out.append(f"  그 밖: 더 먼 경로·허브({', '.join(hub_names) or '없음'}) 경유로 스위트 {len(far_only)}개·유닛 {len(units_far)}개가 더 닿는다 → 커밋 전 전체 pytest가 맡는다")
    if locale:
        out.append("  한글 리터럴이 있다 → locale(EV373: 코드의 한글 글이 모두 en.po를 거친다)")
    pick = set(spec_suites) | set(near)
    if locale:
        pick.add("locale")
    if pick or units_near:
        out.append("  돌릴 것(작업 중):")
        if pick:
            out.append("    pytest " + " ".join(f"tests/eval/test_{s}.py" for s in sorted(pick)))
        for u in sorted(units_near):
            out.append(f'    "$G" --headless --path . -s res://tests/unit/gd/runner.gd -- res://{u}')
        mo = sorted({e for evs in list(spec_suites.values()) + list(near.values()) for e in evs} & _merge_only(con), key=_id_key)
        if mo:
            out.append(f"    머지 전용(C) {' '.join(mo[:8])}{' …' if len(mo) > 8 else ''}: 평소 pytest는 건너뛴다 → EVAL_FULL=1로 돌리거나 머지 전 eval-run final")
    else:
        out.append("  이 심볼에 가깝게 닿는 평가·유닛 테스트가 없다" + (" — 허브 경유분은 커밋 전 전체 pytest" if far_only or units_far else ""))
    return "\n".join(out)


def _merge_only(con) -> set:
    return {r[0] for r in con.execute("SELECT id FROM evals WHERE merge_only=1")}
