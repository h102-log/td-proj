"""세컨드 브레인 자체 테스트: python -m pytest .brain/tests -q

가상 GDScript로 추출·해석 규칙을 하나씩 보고, 실제 저장소로 색인·질의가 끝까지 도는지 본다.
"""
from __future__ import annotations

import sqlite3
import subprocess
import sys
import time
from pathlib import Path

import pytest

BRAIN = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BRAIN))

from brainlib import fts, gdscan, spec  # noqa: E402
from brainlib.graph import Graph  # noqa: E402
from brainlib.util import extract_ids  # noqa: E402


def _graph(files: dict[str, str]) -> Graph:
    scans = {p: gdscan.scan(src, p) for p, src in files.items()}
    g = Graph(scans, set(files))
    g.build_tables()
    g.infer_returns()
    g.infer_member_types()
    g.infer_elems()
    g.infer_returns()
    g.resolve_all()
    return g


def _edges(g: Graph, src: str = None, dst: str = None) -> list:
    return [(e.src, e.dst, e.kind, e.conf) for e in g.edges if (src is None or e.src == src) and (dst is None or e.dst == dst)]


# ── 스캐너 ────────────────────────────────────────────────────
def test_decl_ranges_doc_and_inner_class():
    src = (
        "extends RefCounted\n"
        "# 수리비(S114, I85)\n"
        "func repair_cost(t: Block) -> int:\n"
        "\tvar owed := 1.0\n"
        "\n"
        "\t# 몸통 주석 ponytail: 올림\n"
        "\treturn ceili(owed)\n"
        "\n"
        "class Block:\n"
        "\tvar hp: float\n"
        "\tfunc _init(h: float) -> void:\n"
        "\t\thp = h\n"
        "var after := 1\n"
    )
    fs = gdscan.scan(src, "a.gd")
    d = {x.qual: x for x in fs.decls}
    assert (d["repair_cost"].line, d["repair_cost"].end) == (3, 7)
    assert d["repair_cost"].doc and "S114" in d["repair_cost"].doc[0][1]
    assert any("ponytail" in c for _, c in d["repair_cost"].comments)
    assert d["repair_cost"].params == [("t", "Block")] and d["repair_cost"].type_text == "int"
    assert (d["Block"].line, d["Block"].end) == (9, 12)
    assert d["Block._init"].cls == "Block" and d["Block.hp"].type_text == "float"
    assert d["after"].cls == ""


def test_receiver_chains_and_specials():
    src = (
        "signal done\n"
        "func f(b):\n"
        "\tview.battle.begin_hiring()\n"
        "\tdone.emit()\n"
        "\tb.died.connect(_on_died)\n"
        "\tb.call(\"step\", 0.1)\n"
        "\tcond.call()\n"
        "\tif b.has_method(\"price\"): pass\n"
        "\tvar x := Foo.new(1)\n"
        "\tsuper(1)\n"
    )
    fs = gdscan.scan(src, "a.gd")
    refs = [(r.name, r.chain, r.call, r.special, r.arg) for r in fs.refs if r.src == "f"]
    assert ("begin_hiring", ("view", "battle"), True, "", "") in refs
    assert ("done", None, False, "emit", "") in refs
    assert ("died", ("b",), False, "connect", "_on_died") in refs
    assert ("call", ("b",), True, "dyncall", "step") in refs
    assert ("call", ("cond",), True, "callable_invoke", "") in refs
    assert ("has_method", ("b",), True, "has_method", "price") in refs
    assert ("new", ("Foo",), True, "new", "") in refs
    assert any(r[3] == "super_call" for r in refs)


def test_reflection_vs_setget_declaration():
    src = (
        "var shown = null:\n"
        "\tset(v):\n"
        "\t\tshown = v\n"
        "func _init(stats: Dictionary) -> void:\n"
        "\tfor key in stats:\n"
        "\t\tset(key, stats[key])\n"
    )
    fs = gdscan.scan(src, "a.gd")
    specials = [(r.src, r.special) for r in fs.refs if r.special.startswith("reflect")]
    assert specials == [("_init", "reflect_set")]  # set(v): 선언은 리플렉션이 아니다


def test_string_literal_contexts():
    src = (
        "const A := preload(\"res://a.gd\")\n"
        "func f(r):\n"
        "\tload(\"res://data/waves/%s.tres\" % r)\n"
        "\tFileAccess.get_file_as_string(\"res://src/x.gd\")\n"
        "\t_files(\"res://src\", \".gd\")\n"
        "\treturn \"res://src/sim/tuning.gd가 없다\"\n"
    )
    fs = gdscan.scan(src, "a.gd")
    lits = [(l.value, l.ctx, l.pattern) for l in fs.lits]
    assert ("res://a.gd", "preload", "") in lits
    assert ("res://data/waves/%s.tres", "load", "res://data/waves/*.tres") in lits
    assert ("res://src/x.gd", "text", "") in lits
    assert ("res://src", "ref", "") in lits
    assert not any("없다" in v for v, _, _ in lits)  # 오류 문구는 경로가 아니다


def test_codegen_detected_with_base():
    src = (
        "func make():\n"
        "\tvar code := \"\"\"\n"
        "func build(kind: String):\n"
        "\treturn super(kind)\n"
        "\"\"\"\n"
        "\tvar s := GDScript.new()\n"
        "\ts.source_code = 'extends \"res://b.gd\"\\n' + code\n"
    )
    fs = gdscan.scan(src, "bot.gd")
    assert fs.codegen and fs.codegen[0][2] == ["build"]
    assert fs.codegen_bases == ["b.gd"]


def test_codegen_in_escaped_one_line_string():
    # tests/eval/gd/show.gd BARS_SRC 꼴: 한 줄 문자열 안 \n 이스케이프로 쓴 GDScript
    src = 'const SRC := "extends \\"res://v.gd\\"\\nvar asked := []\\n\\nfunc hp_bar_rect(u = null):\\n\\treturn Rect2()\\n"\n'
    fs = gdscan.scan(src, "t.gd")
    assert fs.codegen and fs.codegen[0][2] == ["hp_bar_rect"]
    assert fs.codegen_bases == ["v.gd"]


def test_container_chains_for_loops_and_lambdas():
    src = (
        "func f(b):\n"
        "\tfor e in b.enemies:\n"
        "\t\tpass\n"
        "\tfor k in castle.values():\n"
        "\t\tpass\n"
        "\tvar hit := b.units.filter(func(u): return u.alive)\n"
        "\tb.units.sort_custom(func(x, y): return x.hp < y.hp)\n"
    )
    fs = gdscan.scan(src, "a.gd")
    d = next(x for x in fs.decls if x.name == "f")
    assert d.elem_src["e"] == ("b", "enemies")
    assert d.elem_src["k"] == ("castle",)
    assert d.elem_src["u"] == ("b", "units")
    assert d.elem_src["x"] == ("b", "units") and d.elem_src["y"] == ("b", "units")
    assert d.elem_alias["hit"] == ("b", "units")


# ── 해석 ─────────────────────────────────────────────────────
MINI = {
    "b.gd": (
        "extends RefCounted\n"
        "signal died\n"
        "var items := []\n"
        "class Item:\n"
        "\tvar v := 0\n"
        "func add() -> void:\n"
        "\titems.append(Item.new())\n"
        "\tdied.emit()\n"
        "func foo() -> int:\n"
        "\treturn 1\n"
        "func step(dt):\n"
        "\tpass\n"
    ),
    "c.gd": (
        "extends RefCounted\n"
        "func step(dt):\n"
        "\tpass\n"
    ),
    "a.gd": (
        "extends RefCounted\n"
        "const B := preload(\"res://b.gd\")\n"
        "var b\n"
        "func _init():\n"
        "\tb = B.new()\n"
        "\tb.died.connect(_on_died)\n"
        "func make():\n"
        "\treturn load(\"res://b.gd\").new()\n"
        "func use(x):\n"
        "\tB.new().foo()\n"
        "\tb.foo()\n"
        "\tvar m = make()\n"
        "\tm.add()\n"
        "\tfor it in m.items:\n"
        "\t\tprint(it.v)\n"
        "\tx.step(0.1)\n"
        "\tx.keys()\n"
        "func _on_died():\n"
        "\tpass\n"
    ),
}


def test_alias_assignment_return_and_elements():
    g = _graph(MINI)
    e = _edges(g, src="a.gd#use")
    assert ("a.gd#use", "b.gd#foo", "calls", "static") in e  # B.new().foo() — 별칭 상수
    assert ("a.gd#use", "b.gd#add", "calls", "inferred") in e  # var m = make() ← return load(...).new()
    assert ("a.gd#use", "b.gd#Item.v", "uses", "inferred") in e  # for it in m.items ← items.append(Item.new())
    assert ("a.gd#_init", "b.gd#_init", "calls", "static") not in e  # b.gd에는 _init이 없다


def test_ambiguous_and_engine_names():
    g = _graph(MINI)
    e = _edges(g, src="a.gd#use")
    steps = {d for s, d, k, c in e if c == "ambiguous" and d.endswith("#step")}
    assert steps == {"b.gd#step", "c.gd#step"}  # 받는 쪽 x의 타입을 모르고 후보가 둘
    assert not any(d.endswith("#keys") for s, d, k, c in e)  # 프로젝트에 keys가 없으면 엔진 호출로 본다
    cats = {u.category for u in g.unresolved}
    assert "ambiguous" in cats


def test_signals_emit_connect_handles():
    g = _graph(MINI)
    assert ("b.gd#add", "b.gd#died", "emits", "static") in _edges(g, src="b.gd#add")
    handles = _edges(g, src="b.gd#died")
    assert ("b.gd#died", "a.gd#_on_died", "handles", "inferred") in handles  # b는 대입 추론(b = B.new())


def test_reflection_mirrors_data_field():
    files = {
        "def.gd": "class_name ThingDef\nextends Resource\n@export var guard := 0.0\n",
        "run.gd": (
            "extends RefCounted\n"
            "class Thing:\n"
            "\tvar guard := 0.0\n"
            "\tfunc _init(stats: Dictionary) -> void:\n"
            "\t\tfor key in stats:\n"
            "\t\t\tset(key, stats[key])\n"
        ),
    }
    g = _graph(files)
    g.mirror_fields({"def.gd"})
    assert ("run.gd#Thing.guard", "def.gd#guard", "mirrors", "dynamic") in _edges(g, dst="def.gd#guard")


# ── 장부·검색 ─────────────────────────────────────────────────
def test_spec_parse_nested_basis_changes_and_refs():
    text = (
        "## 1. 명시된 것\n\n"
        "- S9. 수리비는 값이다. (근거: 사용자 — 세 안(가 / 나) 가운데 고름) → **2026-11-07 변경:** ×1.25다. "
        "→ **2026-11-08 둘째 변경:** 상한.\n\n"
        "### 3.1 문장 대조\n\n| 문장 | 코드 위치 |\n| --- | --- |\n"
        "| S9 | src/sim/battle.gd:69-72 · src/sim/battle.gd:2481 |\n"
    )
    sents, refs = spec.parse_spec(text)
    s = sents[0]
    assert s["basis"] == "사용자 — 세 안(가 / 나) 가운데 고름"
    assert [c[:2] for c in s["changes"]] == [("2026-11-07", ""), ("2026-11-08", "둘째")]
    assert spec.strip_basis(s["base"]) == "수리비는 값이다."
    assert refs == [("S9", "src/sim/battle.gd", 69, 72), ("S9", "src/sim/battle.gd", 2481, 2481)]


def test_extract_ids_ranges():
    assert extract_ids("S299~S302, EV780~788 · I246") == ["S299", "S300", "S301", "S302"] + [f"EV{n}" for n in range(780, 789)] + ["I246"]


def test_korean_fts_bigram_particles_and_stems():
    con = sqlite3.connect(":memory:")
    con.execute("CREATE VIRTUAL TABLE t USING fts5(body, tokenize=\"unicode61 remove_diacritics 0 tokenchars '_'\")")
    docs = ["공병은 차지 칸 둘레로 비켜선다", "수리비는 잃은 체력 × 단가다", "repair_cost는 올림한다", "적이 성문을 부순다"]
    for i, d in enumerate(docs):
        con.execute("INSERT INTO t(rowid, body) VALUES(?, ?)", (i, fts.index_text(d)))

    def hits(q):
        return {r[0] for r in con.execute("SELECT rowid FROM t WHERE t MATCH ?", (fts.match_expr(q),))}

    assert hits("수리비") == {1}  # 조사가 붙은 «수리비는»
    assert hits("공병 비켜서") == {0}  # 활용(비켜선다) — 어간으로
    assert hits("repair") == {2}  # 식별자 조각
    assert hits("성문") == {3}
    assert hits("적") == {3}  # 한 글자는 앞 글자 일치


# ── 실제 저장소 ───────────────────────────────────────────────
ROOT = BRAIN.parent
needs_repo = pytest.mark.skipif(not (ROOT / "SPEC.md").is_file() or not (ROOT / "src").is_dir(), reason="td-proj 저장소가 아니다")


@needs_repo
def test_real_repo_build_and_queries():
    from brainlib import build, impact, store, why

    t = time.time()
    st = build.build()
    assert time.time() - t < 15
    assert st["gd_files"] > 50 and st["symbols"] > 1000 and st["edges_by_conf"].get("static", 0) > 1000
    assert st["spec"] > 100 and st["evals"] > 100 and st["commits"] > 50
    con = store.open_db(rebuild=False)
    # 모든 평가 래퍼가 평가 함수로 이어진다(missing-eval 없음)
    assert con.execute("SELECT COUNT(*) FROM unresolved WHERE category='missing-eval'").fetchone()[0] == 0
    # 가장 많이 불리는 battle.gd 함수 하나로 impact·why가 끝까지 돈다
    sid = con.execute("SELECT id FROM symbols WHERE file='src/sim/battle.gd' AND kind='func' ORDER BY fanin_files DESC LIMIT 1").fetchone()[0]
    out = impact.run(con, [sid], "symbol")
    assert out.startswith(f"impact {sid}") and "[테스트]" in out
    w = why.run(con, sid, [sid], limit=3, use_git=True)
    assert w.startswith(f"why {sid}")


@needs_repo
def test_cli_wrappers_run():
    r = subprocess.run(["sh", str(BRAIN / "query"), "stats"], capture_output=True, text=True, encoding="utf-8", cwd=ROOT, timeout=120)
    assert r.returncode == 0 and '"symbols"' in r.stdout
    r = subprocess.run(["sh", str(BRAIN / "query"), "impact", "this_name_does_not_exist_xyz"], capture_output=True, text=True,
                       encoding="utf-8", cwd=ROOT, timeout=60)
    assert r.returncode == 1 and "찾지 못했다" in r.stdout
