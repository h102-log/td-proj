"""전체 색인: 저장소 → .brain/brain.db (임시 파일에 쓰고 바꿔 끼운다)."""
from __future__ import annotations

import json
import os
import re
import sqlite3
import time
from pathlib import Path

from . import VERSION, fts, gdscan, history, pyscan, resources, spec
from .graph import ENGINE_VIRTUALS, Graph, sym_id
from .util import (CODE_ROOTS, DB_PATH, DOC_ROOTS, EXTRA_FILES, LEDGERS, PY_ROOTS, RES_ROOTS, ROOT,
                   extract_ids, layer_of, read_text)

SCHEMA = """
CREATE TABLE meta(key TEXT PRIMARY KEY, value TEXT);
CREATE TABLE fp(path TEXT PRIMARY KEY, size INT, mtime_ns INT);
CREATE TABLE files(path TEXT PRIMARY KEY, layer TEXT, lines INT);
CREATE TABLE symbols(id TEXT PRIMARY KEY, file TEXT, qual TEXT, name TEXT, kind TEXT, cls TEXT, line INT, end_line INT,
  doc_line INT, head_line INT, head_end INT, static INT, signature TEXT, layer TEXT, hangul INT, ids TEXT, doc TEXT,
  notes TEXT, entry TEXT, fanin_files INT);
CREATE INDEX symbols_name ON symbols(name);
CREATE INDEX symbols_file ON symbols(file);
CREATE TABLE edges(src TEXT, dst TEXT, kind TEXT, conf TEXT, line INT, file TEXT, via TEXT);
CREATE INDEX edges_dst ON edges(dst);
CREATE INDEX edges_src ON edges(src);
CREATE TABLE patterns(src TEXT, file TEXT, line INT, kind TEXT, glob TEXT);
CREATE TABLE unresolved(src TEXT, file TEXT, line INT, category TEXT, detail TEXT, candidates TEXT);
CREATE TABLE blind(file TEXT, category TEXT, count INT);
CREATE TABLE spec(id TEXT PRIMARY KEY, kind TEXT, section TEXT, line INT, base TEXT, basis TEXT, changes TEXT, status TEXT);
CREATE TABLE spec_refs(id TEXT, path TEXT, start INT, end_line INT);
CREATE INDEX spec_refs_path ON spec_refs(path);
CREATE INDEX spec_refs_id ON spec_refs(id);
CREATE TABLE evals(id TEXT PRIMARY KEY, basis TEXT, descr TEXT, test TEXT, approval TEXT, merge_only INT, line INT);
CREATE INDEX evals_basis ON evals(basis);
CREATE TABLE eval_revs(id TEXT, hash TEXT, reason TEXT, date TEXT);
CREATE TABLE tests(eval_fn TEXT, suite TEXT, ev TEXT, py_file TEXT, py_test TEXT);
CREATE TABLE commits(hash TEXT PRIMARY KEY, short TEXT, date TEXT, author TEXT, subject TEXT, body TEXT, merge INT, files TEXT, ids TEXT);
CREATE TABLE commit_ids(id TEXT, short TEXT);
CREATE INDEX commit_ids_id ON commit_ids(id);
CREATE TABLE docs(rowid INTEGER PRIMARY KEY, kind TEXT, ref TEXT, title TEXT, body TEXT, date TEXT);
CREATE VIRTUAL TABLE fts USING fts5(title, body, ids, content='', tokenize="unicode61 remove_diacritics 0 tokenchars '_'");
"""

SKIP_DIRS = {".git", ".godot", ".brain", "__pycache__", "node_modules"}
STRKEY_RE = re.compile(r'\[\s*"[^"\n]+"\s*\]|\.(?:get|has|erase)\(\s*"[^"\n]+"')
NOTE_RE = re.compile(r"(ponytail:|\[이유\]|\[동작\]|\[의도\])")


def inputs() -> list[str]:
    """색인에 들어가는 파일(지문 대상)."""
    out = []

    def walk(root: str, exts: tuple):
        base = ROOT / root
        if not base.is_dir():
            return
        for dp, dns, fns in os.walk(base):
            dns[:] = [d for d in dns if d not in SKIP_DIRS]
            for fn in fns:
                if fn.endswith(exts):
                    out.append(Path(dp, fn).relative_to(ROOT).as_posix())

    for r in CODE_ROOTS:
        walk(r, (".gd",))
    for r in PY_ROOTS:
        walk(r, (".py",))
    for r in RES_ROOTS:
        walk(r, (".tres", ".tscn"))
    for r in DOC_ROOTS:
        walk(r, (".md",))
    for f in LEDGERS + EXTRA_FILES:
        if (ROOT / f).is_file():
            out.append(f)
    walk(".brain/brainlib", (".py",))  # 브레인 자신의 추출 규칙이 바뀌어도 다시 만든다
    out.append(".brain/brain.py")
    return sorted(set(out))


def fingerprint(paths: list[str]) -> dict[str, tuple]:
    fp = {}
    for p in paths:
        try:
            st = os.stat(ROOT / p)
            fp[p] = (st.st_size, st.st_mtime_ns)
        except OSError:
            pass
    return fp


def existing_files() -> set[str]:
    out = set()
    for dp, dns, fns in os.walk(ROOT):
        dns[:] = [d for d in dns if d not in SKIP_DIRS]
        rel_dir = Path(dp).relative_to(ROOT).as_posix()
        for fn in fns:
            out.add(fn if rel_dir == "." else f"{rel_dir}/{fn}")
    return out


def _comment_text(lines: list) -> str:
    return "\n".join(t.lstrip("#").strip() for _, t in lines).strip()


def _md_chunks(path: str, text: str) -> list[tuple]:
    """마크다운을 제목마다 자른다: [(제목, 본문)]."""
    chunks, title, buf = [], Path(path).stem, []
    for line in text.split("\n"):
        if re.match(r"^#{1,4} ", line):
            if "".join(buf).strip():
                chunks.append((title, "\n".join(buf)))
            title, buf = line.lstrip("# ").strip(), []
        else:
            buf.append(line)
    if "".join(buf).strip():
        chunks.append((title, "\n".join(buf)))
    return chunks


def build(quiet: bool = False) -> dict:
    t0 = time.time()
    timing = {}
    fp = fingerprint(inputs())
    paths = [p for p in fp if not p.startswith(".brain/")]  # 브레인 소스는 지문에만 쓴다
    existing = existing_files()

    # 1) GDScript
    t = time.time()
    scans = {}
    for p in paths:
        if p.endswith(".gd"):
            scans[p] = gdscan.scan(read_text(ROOT / p), p)
    timing["gdscan"] = time.time() - t

    t = time.time()
    g = Graph(scans, existing)
    g.build_tables()
    g.infer_returns()
    g.infer_member_types()
    g.infer_elems()  # for e in b.enemies — append(Enemy.new())에서 모은 원소 타입
    g.infer_returns()  # 멤버·원소 타입이 생긴 뒤 한 번 더(view.battle.f() 같은 사슬의 반환)
    g.resolve_all()
    timing["resolve"] = time.time() - t

    # 2) 파이썬 테스트 래퍼·res:// 문자열
    t = time.time()
    py_syms, tests = [], []
    merge_only = set()
    conftest = ROOT / "tests/eval/conftest.py"
    if conftest.is_file():
        merge_only = pyscan.merge_only(read_text(conftest))
    gd_funcs = {sid for sid, d in g.decl_of.items() if d.kind == "func"}
    for p in paths:
        if not p.endswith(".py"):
            continue
        text = read_text(ROOT / p)
        funcs = {n: (a, b) for n, a, b in pyscan.py_functions(text)}
        if p.startswith("tests/eval/test_"):
            for name, line, suite, ev in pyscan.eval_wrappers(text):
                src = f"{p}#{name}"
                a, b = funcs.get(name, (line, line))
                py_syms.append((src, p, name, "pytest", a, b))
                dst = f"tests/eval/gd/{suite}.gd#{ev.lower()}"
                if dst in gd_funcs:
                    g.add(src, dst, "runs", "static", line, p, "gd()")
                    tests.append((dst, suite, ev, p, name))
                else:
                    g.unresolved.append(_unres(src, p, line, "missing-eval", f'gd("{suite}", "{ev}") — 평가 함수가 없다'))
        elif p == "tests/unit/test_gdscript_suites.py":
            src = f"{p}#test_gd"
            a, b = funcs.get("test_gd", (1, 1))
            py_syms.append((src, p, "test_gd", "pytest", a, b))
            for q in paths:
                if q.startswith("tests/unit/gd/test_") and q.endswith(".gd"):
                    g.add(src, q, "runs", "static", a, p, "glob gd/test_*.gd")
        for line, lit in pyscan.res_literals(text):
            v = lit[len("res://"):]
            if v in existing:
                g.add(p, v, "references", "static", line, p, "py res://")
    timing["python"] = time.time() - t

    # 3) 리소스(.tres·.tscn·project.godot)
    t = time.time()
    def_scripts = set()
    for p in paths:
        if not p.endswith((".tres", ".tscn")):
            continue
        info = resources.parse_resource(read_text(ROOT / p))
        script = info["script"]
        if script and p.endswith(".tres"):
            def_scripts.add(script)
        for ref, typ in info["refs"]:
            if ref in existing:
                g.add(p, ref, "instance-of" if ref == script else "references", "static", 1, p, typ)
        if script and (script, "") in g.classes:
            for prop, line in info["props"]:
                hit = g.find_member((script, ""), prop)
                if hit is not None:
                    g.add(p, sym_id(hit[0][0], hit[1].qual), "sets", "static", line, p, "tres 속성")
    if (ROOT / "project.godot").is_file():
        ms = resources.main_scene(read_text(ROOT / "project.godot"))
        if ms:
            g.add("project.godot", ms, "references", "static", 1, "project.godot", "run/main_scene")
    g.mirror_fields(def_scripts)
    timing["resources"] = time.time() - t

    # 4) SPEC·EVAL
    t = time.time()
    sentences, srefs = spec.parse_spec(read_text(ROOT / "SPEC.md")) if (ROOT / "SPEC.md").is_file() else ([], [])
    evals, revs = spec.parse_eval(read_text(ROOT / "EVAL.md")) if (ROOT / "EVAL.md").is_file() else ([], [])
    merged = {}
    for s in sentences:  # U 문장은 §2.3 표와 §3.2 목록 둘 다에 있다 → 합친다
        if s["id"] in merged:
            merged[s["id"]]["base"] += " / " + s["base"]
        else:
            merged[s["id"]] = s
    sentences = list(merged.values())
    timing["ledgers"] = time.time() - t

    # 5) git
    t = time.time()
    commits = history.commits()
    shallow = history.is_shallow()
    head = history.head()
    dirty = history.dirty_files()
    timing["git"] = time.time() - t

    # 6) 심볼 행
    t = time.time()
    fanin: dict[str, set] = {}
    for e in g.edges:
        if e.kind in ("calls", "uses", "instantiates") and e.conf in ("static", "inferred"):
            fanin.setdefault(e.dst, set()).add(e.file)
    head_ranges = {}
    for p in dirty:  # 고친 파일은 HEAD 판의 줄 범위도 둔다(§3.1·git log -L은 HEAD 기준)
        if p.endswith(".gd") and p in scans:
            old = history.show_head(p)
            if old is not None:
                for d in gdscan.scan(old, p).decls:
                    head_ranges[sym_id(p, d.qual)] = (d.line, d.end)
    sym_rows = []
    for sid, d in g.decl_of.items():
        p = g.decl_file[sid]
        doc = _comment_text(d.doc)
        notes = [f"{ln}: {txt.lstrip('#').strip()}" for ln, txt in d.doc + d.comments if NOTE_RE.search(txt)]
        ids = extract_ids(doc + "\n" + _comment_text(d.comments))
        entry = ""
        if d.kind == "func":
            if d.name in ENGINE_VIRTUALS:
                entry = "engine"
            elif p.startswith("tests/eval/gd/") and re.fullmatch(r"ev\d+", d.name):
                entry = "eval"
            elif p.startswith("tests/unit/gd/test_") and d.name.startswith("test_"):
                entry = "unit"
        if p in dirty:
            hl, he = head_ranges.get(sid, (0, 0))
        else:
            hl, he = d.line, d.end
        sym_rows.append((sid, p, d.qual, d.name, d.kind, d.cls, d.line, d.end, d.doc[0][0] if d.doc else d.line, hl, he,
                         int(d.static), d.signature, layer_of(p), d.hangul, " ".join(ids), doc, "\n".join(notes), entry,
                         len(fanin.get(sid, ()))))
    for src, p, name, kind, a, b in py_syms:
        sym_rows.append((src, p, name, name, kind, "", a, b, a, a, b, 0, f"def {name}(…)", layer_of(p), 0, "", "", "", "pytest", 0))
    timing["symbols"] = time.time() - t

    # 7) 쓰기
    t = time.time()
    tmp = DB_PATH.with_suffix(".db.tmp")
    if tmp.exists():
        tmp.unlink()
    con = sqlite3.connect(tmp)
    con.executescript("PRAGMA journal_mode=OFF; PRAGMA synchronous=OFF;" + SCHEMA)
    con.executemany("INSERT INTO fp VALUES(?,?,?)", [(p, s, m) for p, (s, m) in fp.items()])
    con.executemany("INSERT OR REPLACE INTO files VALUES(?,?,?)",
                    [(p, layer_of(p), scans[p].lines if p in scans else 0) for p in paths])
    con.executemany("INSERT OR REPLACE INTO symbols VALUES(" + ",".join("?" * 20) + ")", sym_rows)
    con.executemany("INSERT INTO edges VALUES(?,?,?,?,?,?,?)",
                    [(e.src, e.dst, e.kind, e.conf, e.line, e.file, e.via) for e in g.edges])
    con.executemany("INSERT INTO patterns VALUES(?,?,?,?,?)", g.patterns)
    con.executemany("INSERT INTO unresolved VALUES(?,?,?,?,?,?)",
                    [(u.src, u.file, u.line, u.category, u.detail, u.candidates) for u in g.unresolved])
    blind = []
    for p in paths:
        if p.endswith(".gd"):
            n = len(STRKEY_RE.findall(read_text(ROOT / p)))
            if n:
                blind.append((p, "string-key", n))
    con.executemany("INSERT INTO blind VALUES(?,?,?)", blind)
    con.executemany("INSERT OR REPLACE INTO spec VALUES(?,?,?,?,?,?,?,?)",
                    [(s["id"], s["kind"], s["section"], s["line"], s["base"], s["basis"],
                      json.dumps(s["changes"], ensure_ascii=False), s["status"]) for s in sentences])
    con.executemany("INSERT INTO spec_refs VALUES(?,?,?,?)", srefs)
    con.executemany("INSERT OR REPLACE INTO evals VALUES(?,?,?,?,?,?,?)",
                    [(e["id"], e["basis"], e["desc"], e["test"], e["approval"], int(e["id"] in merge_only), e["line"]) for e in evals])
    con.executemany("INSERT INTO eval_revs VALUES(?,?,?,?)", [(r["id"], r["hash"], r["reason"], r["date"]) for r in revs])
    con.executemany("INSERT INTO tests VALUES(?,?,?,?,?)", tests)
    con.executemany("INSERT OR REPLACE INTO commits VALUES(?,?,?,?,?,?,?,?,?)",
                    [(c["hash"], c["short"], c["date"], c["author"], c["subject"], c["body"], int(c["merge"]),
                      "\n".join(c["files"]), " ".join(c["ids"])) for c in commits])
    con.executemany("INSERT INTO commit_ids VALUES(?,?)", [(i, c["short"]) for c in commits for i in c["ids"]])

    # 8) 전문 검색 문서
    docs = []
    for c in commits:
        docs.append(("commit", c["short"], c["subject"], c["body"] + "\n" + " ".join(c["files"]), c["date"], " ".join(c["ids"])))
    for s in sentences:
        full = s["base"] + "\n" + "\n".join(f"{d} {o} 변경: {txt}" for d, o, txt in s["changes"])
        docs.append(("spec", s["id"], s["id"] + " " + s["base"][:80], full, "", " ".join([s["id"]] + extract_ids(full))))
    rev_by = {}
    for r in revs:
        rev_by.setdefault(r["id"], []).append(f'{r["date"]} {r["reason"]}')
    for e in evals:
        body = e["desc"] + "\n" + "\n".join(rev_by.get(e["id"], []))
        docs.append(("eval", e["id"], f'{e["id"]} ({e["basis"]}) {e["desc"][:60]}', body, "", f'{e["id"]} {e["basis"]}'))
    for sid, d in g.decl_of.items():
        body = _comment_text(d.doc) + "\n" + _comment_text(d.comments)
        if len(body.strip()) >= 8:
            docs.append(("code", sid, sid, body, "", " ".join(extract_ids(body))))
    for p in paths:
        if p.endswith(".md") and p.split("/")[0] in DOC_ROOTS:
            kind = "insight" if p.startswith("insights/") else "review"
            m = re.match(r"(\d{4}-\d{2}-\d{2})", Path(p).name)
            for title, body in _md_chunks(p, read_text(ROOT / p)):
                docs.append((kind, f"{p}#{title[:60]}", title, body[:6000], m.group(1) if m else "", " ".join(extract_ids(title + body))))
    con.executemany("INSERT INTO docs(rowid, kind, ref, title, body, date) VALUES(?,?,?,?,?,?)",
                    [(i + 1, k, r, ti, b, dt) for i, (k, r, ti, b, dt, _ids) in enumerate(docs)])
    con.executemany("INSERT INTO fts(rowid, title, body, ids) VALUES(?,?,?,?)",
                    [(i + 1, fts.index_text(ti), fts.index_text(b), ids.lower()) for i, (k, r, ti, b, dt, ids) in enumerate(docs)])
    timing["write"] = time.time() - t

    stats = {
        "files": len(paths), "gd_files": len(scans), "symbols": len(sym_rows), "edges": len(g.edges),
        "edges_by_conf": _count(e.conf for e in g.edges), "unresolved": len(g.unresolved),
        "unresolved_by_cat": _count(u.category for u in g.unresolved), "patterns": len(g.patterns),
        "spec": len(sentences), "spec_refs": len(srefs), "evals": len(evals), "commits": len(commits),
        "docs": len(docs), "shallow": shallow, "head": head[:10], "dirty": sorted(dirty),
        "warnings": [f"{p}:{w}" for p, s in scans.items() for w in s.warnings],
        "timing": {k: round(v, 2) for k, v in timing.items()},
    }
    stats["seconds"] = round(time.time() - t0, 2)
    meta = {"version": str(VERSION), "built_at": time.strftime("%Y-%m-%d %H:%M:%S"), "head": head,
            "shallow": str(shallow), "stats": json.dumps(stats, ensure_ascii=False)}
    con.executemany("INSERT INTO meta VALUES(?,?)", list(meta.items()))
    con.commit()
    con.close()
    os.replace(tmp, DB_PATH)
    return stats


def _count(it) -> dict:
    out: dict = {}
    for x in it:
        out[x] = out.get(x, 0) + 1
    return dict(sorted(out.items(), key=lambda kv: -kv[1]))


def _unres(src, file, line, cat, detail):
    from .graph import Unres
    return Unres(src, file, line, cat, detail)
