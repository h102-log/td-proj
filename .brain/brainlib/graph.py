"""심볼 표와 이름 해석 → 엣지.

확실도(conf):
  static    문법·타입만으로 정해진다(같은 클래스 안 호출, self/super, 별칭 상수·class_name, 타입 붙은 변수·매개변수, A.new()).
  inferred  추정이다. 대입 추론(x = A.new()), 이름 지도(이 프로젝트에서 'battle'은 늘 battle.gd), 프로젝트 안에 그 이름이 하나뿐.
  ambiguous 받는 쪽 타입을 몰라 같은 이름 후보가 여럿이다. 후보마다 엣지를 두고 미확인(unresolved)에도 적는다.
  dynamic   문자열로 정해진다(call("이름"), Callable(obj, "이름"), has_method, load("..%s"), 코드 생성).
엔진 API로 보이는 참조(프로젝트에 그 이름이 없음)는 엣지를 만들지 않는다.
"""
from __future__ import annotations

import fnmatch
from collections import defaultdict
from dataclasses import dataclass, field

from .gdscan import Decl, FileScan

ENGINE_VIRTUALS = frozenset((
    "_ready", "_process", "_physics_process", "_draw", "_input", "_unhandled_input", "_unhandled_key_input",
    "_gui_input", "_notification", "_enter_tree", "_exit_tree", "_init", "_initialize", "_finalize", "_to_string",
    "_get", "_set", "_get_property_list", "_has_point", "_make_custom_tooltip", "_get_message", "_get_plural_message",
))
# 엔진 객체(Tween·Timer·AudioStreamPlayer·Node·Array…)에서 흔히 부르는 이름. 받는 쪽 타입을 모를 때
# 프로젝트에 같은 이름이 하나뿐이어도 «추론»으로 잇지 않고 «미확인(엔진일 수도)»으로 둔다
ENGINE_COMMON = frozenset((
    # 메서드: Array·Dictionary·String·Vector·Rect2·Tween·Timer·AudioStreamPlayer·Node·FileAccess·AStarGrid2D
    "stop", "play", "start", "seek", "kill", "clear", "update", "show", "hide", "open", "close", "load", "save",
    "get", "set", "has", "erase", "append", "size", "find", "free", "queue_free", "add_child", "remove_child",
    "connect", "emit", "call", "duplicate", "push_back", "pop_back", "pop_front", "insert", "remove_at", "merge",
    "keys", "values", "sort", "sort_custom", "filter", "map", "reduce", "any", "all", "is_empty", "count",
    "front", "back", "begins_with", "ends_with", "format", "join", "split", "length", "abs", "floor", "ceil",
    "round", "clamp", "lerp", "distance_to", "normalized", "rotated", "set_process", "get_rect", "grab_focus",
    "has_point", "intersects", "encloses", "grow", "get_center", "move_toward", "angle", "dot", "cross",
    # 속성: Control·Node2D·CanvasItem·Camera2D·Label·Button·AudioStreamPlayer
    "text", "visible", "position", "scale", "rotation", "modulate", "color", "name", "value", "pressed",
    "disabled", "frame", "volume_db", "stream", "zoom", "offset", "tooltip_text", "self_modulate",
))


@dataclass
class Edge:
    src: str
    dst: str
    kind: str  # calls uses instantiates emits connects handles extends preloads loads reads-text scans-dir sets runs overrides
    conf: str
    line: int
    file: str
    via: str = ""


@dataclass
class Unres:
    src: str
    file: str
    line: int
    category: str
    detail: str
    candidates: str = ""


@dataclass
class ClassInfo:
    path: str
    inner: str
    base_text: str
    members: dict = field(default_factory=dict)  # 이름 → Decl
    base: object = None  # ClassKey | 'ENGINE' | None


def sym_id(path: str, qual: str) -> str:
    return f"{path}#{qual}" if qual else path


def class_id(key) -> str:
    path, inner = key
    return sym_id(path, inner)


class Graph:
    def __init__(self, scans: dict[str, FileScan], existing: set[str]):
        self.scans = scans
        self.existing = existing  # 저장소에 있는 파일(res:// 확인용)
        self.classes: dict[tuple, ClassInfo] = {}
        self.class_names: dict[str, tuple] = {}
        self.by_member: dict[str, list] = defaultdict(list)  # 이름 → [(ClassKey, Decl)]
        self.decl_of: dict[str, Decl] = {}  # 심볼 id → Decl
        self.decl_file: dict[str, str] = {}
        self.member_types: dict[tuple, set] = defaultdict(set)  # (ClassKey, 멤버) → 대입으로 본 타입
        self.name_map: dict[str, set] = defaultdict(set)  # 변수 이름 → 그 이름이 가리킨 클래스들
        self.edges: list[Edge] = []
        self.unresolved: list[Unres] = []
        self.patterns: list[tuple] = []  # (src, file, line, kind, glob)
        self._edge_seen: set = set()
        self._chain_cache: dict = {}
        self.reflect_targets: set = set()  # set(키 변수, …)로 자기 필드를 채우는 클래스
        self.elem_types: dict = defaultdict(set)  # (ClassKey, 컨테이너 멤버) → 원소 타입(append·사전 저장에서 모은다)

    # ── 컨테이너 원소 타입 ────────────────────────────────────
    def infer_elems(self) -> None:
        for _ in range(2):
            for path, fs in self.scans.items():
                funcs = {d.qual: d for d in fs.decls if d.kind == "func"}
                for src_q, cont, shape in fs.adds:
                    d = funcs.get(src_q)
                    ctx = (path, d.cls if d else "")
                    vt = self._shape_type(shape, d, ctx)
                    if not isinstance(vt, set):
                        continue
                    for key in self._container_keys(cont, d, ctx):
                        self.elem_types[key] |= vt

    def _shape_type(self, shape, d, ctx):
        kind, val = shape
        if kind == "type":
            r = self.resolve_type(val, ctx)
            return {r} if isinstance(r, tuple) else None
        if kind == "call":
            return self.call_ret(val, d, ctx)
        if kind == "name" and d is not None:
            t, _ = self.type_of_name(val, d, ctx)
            return t if isinstance(t, set) else None
        return None

    def _container_keys(self, cont: tuple, d, ctx) -> list:
        """컨테이너 사슬 → [(ClassKey, 멤버 이름)]. 지역 컨테이너면 []."""
        if len(cont) == 1:
            if d is not None and cont[0] in d.locals:
                return []
            hit = self.find_in_scope(ctx, cont[0])
            return [(hit[0], cont[0])] if hit is not None and hit[1].kind in ("var", "const") else []
        types, _ = self.type_of_chain(cont[:-1], d, ctx, "")
        out = []
        if isinstance(types, set):
            for k in types:
                hit = self.find_member(k, cont[-1])
                if hit is not None and hit[1].kind in ("var", "const"):
                    out.append((hit[0], cont[-1]))
        return out

    def elem_of(self, cont: tuple, d, ctx, depth: int = 0):
        if depth > 4:
            return None
        if len(cont) == 1 and d is not None and cont[0] in d.elem_alias:
            return self.elem_of(d.elem_alias[cont[0]], d, ctx, depth + 1)
        out = set()
        for key in self._container_keys(cont, d, ctx):
            out |= self.elem_types.get(key, set())
        return out or None

    def mirror_fields(self, def_scripts: set[str]) -> None:
        """데이터 정의(.tres의 스크립트) 필드 → 리플렉션으로 채워지는 클래스의 같은 이름 필드(동적, 이름 대응)."""
        for dpath in sorted(def_scripts):
            ci = self.classes.get((dpath, ""))
            if ci is None:
                continue
            for name, d in ci.members.items():
                if d.kind != "var":
                    continue
                for rk in sorted(self.reflect_targets):
                    hit = self.find_member(rk, name)
                    if hit is not None and hit[1].kind == "var" and hit[0][0] != dpath:
                        src = sym_id(hit[0][0], hit[1].qual)
                        self.add(src, sym_id(dpath, d.qual), "mirrors", "dynamic", hit[1].line, hit[0][0],
                                 f"리플렉션: {class_id(rk)} set(키, …)")

    # ── 표 만들기 ─────────────────────────────────────────────
    def build_tables(self) -> None:
        for path, fs in self.scans.items():
            fk = (path, "")
            self.classes[fk] = ClassInfo(path, "", fs.extends)
            if fs.class_name:
                self.class_names[fs.class_name] = fk
            for d in fs.decls:
                if d.kind == "class":
                    self.classes[(path, d.name)] = ClassInfo(path, d.name, d.base)
            for d in fs.decls:
                key = (path, d.cls)
                ci = self.classes.get(key)
                if ci is None:
                    continue
                ci.members[d.name] = d
                sid = sym_id(path, d.qual)
                self.decl_of[sid] = d
                self.decl_file[sid] = path
                if d.kind != "class":
                    self.by_member[d.name].append((key, d))
        for key, ci in self.classes.items():
            ci.base = self._resolve_base(ci.base_text, key)

    def _resolve_base(self, text: str, key) -> object:
        if not text:
            return None
        if text.startswith("res://"):
            p = text[len("res://"):]
            return (p, "") if (p, "") in self.classes else None
        r = self.resolve_type(text, (key[0], ""))
        return r if r else "ENGINE"

    def chain(self, key) -> list:
        """key와 그 부모들(프로젝트 안)."""
        c = self._chain_cache.get(key)
        if c is not None:
            return c
        out, k, guard = [], key, 0
        while isinstance(k, tuple) and k in self.classes and guard < 20:
            out.append(k)
            k = self.classes[k].base
            guard += 1
        self._chain_cache[key] = out
        return out

    def extends_engine(self, key) -> bool:
        ch = self.chain(key)
        return bool(ch) and self.classes[ch[-1]].base in ("ENGINE", None)

    def find_member(self, key, name: str):
        for k in self.chain(key):
            d = self.classes[k].members.get(name)
            if d is not None:
                return k, d
        return None

    def find_in_scope(self, ctx, name: str):
        """맨 이름: 지금 클래스 사슬 → (안쪽 클래스면) 바깥 파일 클래스 사슬."""
        r = self.find_member(ctx, name)
        if r is None and ctx[1]:
            r = self.find_member((ctx[0], ""), name)
        return r

    def resolve_type(self, text: str, ctx) -> object:
        """타입 글 → ClassKey | 'ENGINE' | None."""
        text = text.strip()
        if not text:
            return None
        if text.startswith("res://"):
            p = text[len("res://"):]
            return (p, "") if (p, "") in self.classes else None
        if text.startswith("Array[") and text.endswith("]"):
            return "ENGINE"
        parts = text.split(".")
        k = self._head(parts[0], ctx)
        for p in parts[1:]:
            if isinstance(k, tuple) and k[1] == "" and (k[0], p) in self.classes:
                k = (k[0], p)
            elif isinstance(k, tuple):
                return None
            else:
                return k
        return k

    def _head(self, head: str, ctx) -> object:
        path = ctx[0]
        if (path, head) in self.classes:
            return (path, head)
        scopes = self.chain(ctx) + (self.chain((path, "")) if ctx[1] else [])
        for k in scopes:
            d = self.classes[k].members.get(head)
            if d is not None and d.kind == "const" and d.alias:
                return (d.alias, "") if (d.alias, "") in self.classes else "ENGINE"
            if d is not None and d.kind == "class":
                return (k[0], d.name)
        if head in self.class_names:
            return self.class_names[head]
        if head[:1].isupper():
            return "ENGINE"
        return None

    # ── 타입 추론 ─────────────────────────────────────────────
    def infer_member_types(self) -> None:
        """멤버 선언 타입과 대입(x = A.new())으로 멤버 타입·이름 지도를 만든다."""
        for path, fs in self.scans.items():
            for d in fs.decls:
                if d.kind != "var":
                    continue
                ctx = (path, d.cls)
                t = self.resolve_type(d.type_text or d.infer_text, ctx) if (d.type_text or d.infer_text) else None
                if isinstance(t, tuple):
                    self.member_types[(ctx, d.name)].add(t)
                    self.name_map[d.name].add(t)
            for d in fs.decls:
                if d.kind != "func":
                    continue
                ctx = (path, d.cls)
                for name in list(d.locals):
                    t, _ = self.local_type(name, d, ctx)
                    if isinstance(t, set):
                        self.name_map[name] |= t
        for _ in range(2):  # 사슬(view.battle = ...)은 앞 단계 결과를 쓴다
            for path, fs in self.scans.items():
                funcs = {d.qual: d for d in fs.decls if d.kind == "func"}
                for a in fs.assigns:
                    d = funcs.get(a.src)
                    ctx = (path, d.cls if d else "")
                    t = self.resolve_type(a.rhs, ctx)
                    if not isinstance(t, tuple):
                        continue
                    target = a.target
                    if target[0] == "self":
                        target = target[1:]
                    if not target:
                        continue
                    if len(target) == 1:
                        if d is not None and target[0] in d.locals:
                            self.name_map[target[0]].add(t)
                            continue
                        hit = self.find_in_scope(ctx, target[0])
                        if hit is not None and hit[1].kind == "var":
                            self.member_types[(hit[0], target[0])].add(t)
                        self.name_map[target[0]].add(t)
                    else:
                        owner, _ = self.type_of_chain(target[:-1], d, ctx, "")
                        for ok in owner or ():
                            hit = self.find_member(ok, target[-1])
                            if hit is not None and hit[1].kind == "var":
                                self.member_types[(hit[0], target[-1])].add(t)
                        self.name_map[target[-1]].add(t)

    def infer_returns(self) -> None:
        """함수 반환 타입: 선언(-> T) → 반환문(return A.new() / return f() / return 지역)을 고정점까지 돌린다."""
        self.ret_types: dict[str, tuple] = {}
        funcs = [(sid, d) for sid, d in self.decl_of.items() if d.kind == "func"]
        for _ in range(5):
            changed = False
            for sid, d in funcs:
                if sid in self.ret_types:
                    continue
                ctx = (self.decl_file[sid], d.cls)
                got = None
                if d.type_text:
                    r = self.resolve_type(d.type_text, ctx)
                    if isinstance(r, tuple):
                        got = ({r}, "static")
                    elif r == "ENGINE":
                        got = ("ENGINE", "static")
                if got is None and d.returns:
                    acc: set = set()
                    for kind, val in d.returns:
                        if kind == "type":
                            r = self.resolve_type(val, ctx)
                            if isinstance(r, tuple):
                                acc.add(r)
                        elif kind == "call":
                            rt = self.call_ret(val, d, ctx)
                            if isinstance(rt, set):
                                acc |= rt
                        elif kind == "name":
                            lt, _ = self.local_type(val, d, ctx)
                            if isinstance(lt, set):
                                acc |= lt
                    if acc:
                        got = (acc, "inferred")
                if got is not None:
                    self.ret_types[sid] = got
                    changed = True
            if not changed:
                break

    def call_ret(self, dotted: str, fdecl, ctx):
        """'f' 또는 'b.spawn_enemy' 호출의 반환 타입(set|None)."""
        parts = dotted.split(".")
        name = parts[-1]
        if len(parts) == 1:
            hit = self.find_in_scope(ctx, name)
            hits = [hit] if hit is not None else []
        else:
            types, _ = self.type_of_chain(tuple(parts[:-1]), fdecl, ctx, "")
            hits = [self.find_member(k, name) for k in types] if isinstance(types, set) else []
        out = set()
        for h in hits:
            if h is not None and h[1].kind == "func":
                rt = getattr(self, "ret_types", {}).get(sym_id(h[0][0], h[1].qual))
                if rt and isinstance(rt[0], set):
                    out |= rt[0]
        return out or None

    def local_type(self, name: str, fdecl: Decl, ctx):
        typ, how = fdecl.locals.get(name, ("", ""))
        if typ:
            t = self.resolve_type(typ, ctx)
            if isinstance(t, tuple):
                return {t}, ("static" if how == "static" else "inferred")
            if t == "ENGINE":
                return "ENGINE", "static"
        f = fdecl.local_calls.get(name)
        if f:
            rt = self.call_ret(f, fdecl, ctx)
            if rt:
                return rt, "inferred"
        cont = fdecl.elem_src.get(name)
        if cont:  # for e in b.enemies: / .filter(func(e): …)
            et = self.elem_of(cont, fdecl, ctx)
            if et:
                return et, "inferred"
        return None, ""

    def member_type(self, key, d: Decl):
        ctx = key
        if d.type_text or d.infer_text:
            t = self.resolve_type(d.type_text or d.infer_text, ctx)
            if isinstance(t, tuple):
                return {t}, "static"
            if t == "ENGINE":
                return "ENGINE", "static"
        got = self.member_types.get((key, d.name))
        if got:
            return set(got), "inferred"
        return None, ""

    def from_name_map(self, name: str):
        got = self.name_map.get(name)
        if got:
            return set(got), "name-map"
        return None, ""

    def type_of_name(self, name: str, fdecl: Decl | None, ctx):
        if fdecl is not None and name in fdecl.locals:
            t, how = self.local_type(name, fdecl, ctx)
            if t:
                return t, how
            return self.from_name_map(name)
        hit = self.find_in_scope(ctx, name)
        if hit is not None:
            k, d = hit
            if d.kind == "const" and d.alias:
                return ({(d.alias, "")}, "static") if (d.alias, "") in self.classes else ("ENGINE", "static")
            if d.kind in ("var", "const"):
                t, how = self.member_type(k, d)
                if t:
                    return t, how
                return self.from_name_map(name) if d.kind == "var" else (None, "")
            if d.kind == "class":
                return {(k[0], d.name)}, "static"
            return None, ""
        h = self._head(name, ctx)
        if isinstance(h, tuple):
            return {h}, "static"
        if h == "ENGINE":
            return "ENGINE", "static"
        return self.from_name_map(name)

    def type_of_chain(self, chain: tuple, fdecl, ctx, expr_path: str):
        head = chain[0]
        rest = chain[1:]
        if head == "self":
            t, how = {ctx}, "static"
        elif head == "super":
            b = self.classes[ctx].base if ctx in self.classes else None
            t, how = ({b}, "static") if isinstance(b, tuple) else ("ENGINE", "static")
        elif head == "<lit>":
            return "ENGINE", "static"
        elif head == "<expr>":
            t, how = None, ""
            if expr_path.startswith("res://") and (expr_path[len("res://"):], "") in self.classes:
                t, how = {(expr_path[len("res://"):], "")}, "static"
            elif expr_path.startswith("type:"):  # A.new().f()
                r = self.resolve_type(expr_path[5:], ctx)
                if isinstance(r, tuple):
                    t, how = {r}, "static"
                elif r == "ENGINE":
                    return "ENGINE", "static"
            elif expr_path.startswith("call:"):  # f().g() — f의 반환 타입
                rt = self.call_ret(expr_path[5:], fdecl, ctx)
                if rt:
                    t, how = rt, "inferred"
        else:
            t, how = self.type_of_name(head, fdecl, ctx)
        for p in rest:
            if t == "ENGINE":
                return "ENGINE", how
            if not t:
                t, how = self.from_name_map(p)
                continue
            nt, nhow = set(), how
            engine = False
            for k in t:
                hit = self.find_member(k, p)
                if hit is None:
                    engine = engine or self.extends_engine(k)
                    continue
                hk, d = hit
                if d.kind == "class":
                    nt.add((hk[0], d.name))
                elif d.kind == "var":
                    mt, mhow = self.member_type(hk, d)
                    if mt == "ENGINE":
                        engine = True
                    elif mt:
                        nt |= mt
                        nhow = _worse(nhow, mhow)
                    else:
                        nm, _ = self.from_name_map(p)
                        if nm:
                            nt |= nm
                            nhow = _worse(nhow, "name-map")
                elif d.kind == "const" and d.alias and (d.alias, "") in self.classes:
                    nt.add((d.alias, ""))
            if nt:
                t, how = nt, nhow
            elif engine:
                return "ENGINE", how
            else:
                t, how = self.from_name_map(p)
        return t, how

    # ── 엣지 ─────────────────────────────────────────────────
    def add(self, src, dst, kind, conf, line, file, via=""):
        key = (src, dst, kind, conf, line)
        if key in self._edge_seen:
            return
        self._edge_seen.add(key)
        self.edges.append(Edge(src, dst, kind, conf, line, file, via))

    def resolve_all(self) -> None:
        for path, fs in self.scans.items():
            funcs = {d.qual: d for d in fs.decls}
            for r in fs.refs:
                d = funcs.get(r.src)
                ctx = (path, d.cls if d else "") if d else (path, r.src if (path, r.src) in self.classes else "")
                if d is not None and d.kind == "class":
                    ctx = (path, d.name)
                fdecl = d if (d is not None and d.kind == "func") else None
                src = sym_id(path, r.src)
                self._ref(r, src, fdecl, ctx, path)
            for lit in fs.lits:
                self._lit(lit, sym_id(path, lit.src), path)
            for src_q, line, names in fs.codegen:
                self._codegen(sym_id(path, src_q), path, line, names, fs.codegen_bases)
            self._file_edges(path, fs)

    def _file_edges(self, path: str, fs: FileScan) -> None:
        ci = self.classes[(path, "")]
        if isinstance(ci.base, tuple):
            self.add(path, class_id(ci.base), "extends", "static", 1, path)
        for d in fs.decls:
            if d.kind == "class":
                b = self.classes[(path, d.name)].base
                if isinstance(b, tuple):
                    self.add(sym_id(path, d.qual), class_id(b), "extends", "static", d.line, path)
            if d.kind == "const" and d.alias:
                dst = d.alias
                if dst in self.existing:
                    self.add(sym_id(path, d.qual), dst, "preloads", "static", d.line, path)
            # 덮어쓴 함수: 부모 사슬의 같은 이름(가상 호출이라 부모 쪽 호출자도 이 함수에 닿을 수 있다)
            if d.kind == "func":
                own = (path, d.cls)
                base = self.classes[own].base if own in self.classes else None
                if isinstance(base, tuple):
                    hit = self.find_member(base, d.name)
                    if hit is not None and hit[1].kind == "func":
                        self.add(sym_id(path, d.qual), sym_id(hit[0][0], hit[1].qual), "overrides", "static", d.line, path)

    def _kinds_ok(self, d: Decl, call: bool) -> bool:
        if call:  # GDScript는 변수를 x()로 부르지 못한다(Callable은 .call()) → 호출은 함수에만 잇는다
            return d.kind == "func"
        return True

    def _ref(self, r, src, fdecl, ctx, path) -> None:
        sp = r.special
        if sp == "super_call":
            if fdecl is None:
                return
            base = self.classes[ctx].base if ctx in self.classes else None
            if isinstance(base, tuple):
                hit = self.find_member(base, fdecl.name)
                if hit is not None:
                    self.add(src, sym_id(hit[0][0], hit[1].qual), "calls", "static", r.line, path, "super")
            return
        if sp in ("dyncall", "has_method", "callable"):
            self._dynamic(r, src, fdecl, ctx, path)
            return
        if sp == "reflect_set":
            self.reflect_targets.add(ctx)
            self.unresolved.append(Unres(src, path, r.line, "reflection",
                                         "set(키 변수, 값) — 필드를 이름 문자열로 채운다. 어느 필드가 채워지는지는 데이터(사전 키)가 정한다"))
            return
        if sp == "reflect_list":
            self.unresolved.append(Unres(src, path, r.line, "reflection",
                                         "get_property_list() — 스크립트 변수를 이름으로 읽어 옮긴다(데이터 정의 → 사전 → 런타임 필드)"))
            return
        if sp == "callable_invoke":
            recv = ".".join(r.chain)
            self.unresolved.append(Unres(src, path, r.line, "callable-invoke", f"{recv}.{r.name}(…) — Callable 변수를 부른다. 무엇을 담았는지는 실행 흐름에 달렸다"))
            return
        if sp == "getset":
            types, how = self.type_of_chain(r.chain, fdecl, ctx, r.expr_path)
            if isinstance(types, set):
                for k in types:
                    hit = self.find_member(k, r.arg)
                    if hit is not None:
                        self.add(src, sym_id(hit[0][0], hit[1].qual), "uses", "dynamic", r.line, path, f'{r.name}("{r.arg}")')
            return
        if sp == "new":
            types, how = self.type_of_chain(r.chain, fdecl, ctx, r.expr_path)
            if isinstance(types, set):
                conf = "static" if how == "static" else "inferred"
                for k in types:
                    self.add(src, class_id(k), "instantiates", conf, r.line, path, how)
                    hit = self.find_member(k, "_init")
                    if hit is not None:
                        self.add(src, sym_id(hit[0][0], hit[1].qual), "calls", conf, r.line, path, "new")
            return
        kind = {"emit": "emits", "connect": "connects"}.get(sp) or ("calls" if r.call else "uses")
        target = None
        if r.chain is None:
            if fdecl is not None and r.name in fdecl.locals:
                return
            hit = self.find_in_scope(ctx, r.name)
            if hit is not None:
                target = (sym_id(hit[0][0], hit[1].qual), "static", "scope")
                self.add(src, target[0], kind, "static", r.line, path, "scope")
            elif r.name in self.class_names:
                self.add(src, class_id(self.class_names[r.name]), "uses", "static", r.line, path, "class_name")
            elif (path, r.name) in self.classes:
                self.add(src, class_id((path, r.name)), "uses", "static", r.line, path, "inner")
        else:
            target = self._member(r, src, fdecl, ctx, path, kind)
        if sp == "connect" and target is not None:
            self._handler(r, target, src, fdecl, ctx, path)

    def _member(self, r, src, fdecl, ctx, path, kind):
        types, how = self.type_of_chain(r.chain, fdecl, ctx, r.expr_path)
        if types == "ENGINE":
            return None
        if types:
            found = {}
            for k in types:
                hit = self.find_member(k, r.name)
                if hit is not None and self._kinds_ok(hit[1], r.call):
                    found[sym_id(hit[0][0], hit[1].qual)] = hit
            if len(found) == 1:
                dst = next(iter(found))
                conf = "static" if how == "static" else "inferred"
                self.add(src, dst, kind, conf, r.line, path, how)
                return dst, conf, how
            if len(found) > 1:
                return self._ambiguous(r, src, path, kind, sorted(found), "받는 쪽이 여러 클래스일 수 있다")
            if how == "static":
                return None  # 정적 타입에 없는 멤버 → 엔진 API
        cands = [(k, d) for k, d in self.by_member.get(r.name, ()) if self._kinds_ok(d, r.call)]
        if not cands:
            return None
        ids = sorted({sym_id(k[0], d.qual) for k, d in cands})
        recv = ".".join(r.chain)
        if len(ids) == 1 and r.name not in ENGINE_COMMON:
            self.add(src, ids[0], kind, "inferred", r.line, path, "unique-name")
            return ids[0], "inferred", "unique-name"
        if r.name in ENGINE_COMMON:
            return self._ambiguous(r, src, path, kind, ids, "엔진 API와 이름이 같다(Array·Dictionary·Node…)", "engine-name")
        return self._ambiguous(r, src, path, kind, ids, f"받는 쪽 «{recv}»의 타입을 몰라 같은 이름 후보 {len(ids)}개")

    def _ambiguous(self, r, src, path, kind, ids, why, category="ambiguous"):
        for dst in ids:
            self.add(src, dst, kind, "ambiguous", r.line, path, category)
        recv = ".".join(r.chain) if r.chain else ""
        self.unresolved.append(Unres(src, path, r.line, category, f"{recv}.{r.name} — {why}", " ".join(ids)))
        return None

    def _handler(self, r, target, src, fdecl, ctx, path) -> None:
        sig_id = target[0]
        if r.arg_kind == "lambda":
            self.add(sig_id, src, "handles", target[1], r.line, path, "lambda")
            return
        if r.arg_kind == "name":
            if fdecl is not None and r.arg in fdecl.locals:
                self.unresolved.append(Unres(src, path, r.line, "callable-invoke", f"{r.name}.connect({r.arg}) — 지역 Callable을 잇는다"))
                return
            hit = self.find_in_scope(ctx, r.arg)
            if hit is not None:
                self.add(sig_id, sym_id(hit[0][0], hit[1].qual), "handles", target[1], r.line, path, "connect")
            return
        if r.arg_kind == "member":
            types, how = self.type_of_chain(r.arg_chain, fdecl, ctx, "")
            if isinstance(types, set):
                for k in types:
                    hit = self.find_member(k, r.arg)
                    if hit is not None:
                        self.add(sig_id, sym_id(hit[0][0], hit[1].qual), "handles", "inferred", r.line, path, "connect")
                return
        self.unresolved.append(Unres(src, path, r.line, "signal-handler", f"{r.name}.connect(…) — 받는 함수를 정적으로 정하지 못했다"))

    def _dynamic(self, r, src, fdecl, ctx, path) -> None:
        label = {"dyncall": f'{r.name}("{r.arg}")', "has_method": f'has_method("{r.arg}")', "callable": f'Callable(…, "{r.arg}")'}[r.special]
        if r.arg_kind != "str" or not r.arg:
            what = {"dyncall": "call(이름 변수)", "has_method": "has_method(이름 변수)", "callable": "Callable(대상, 이름 변수)"}[r.special]
            self.unresolved.append(Unres(src, path, r.line, "dynamic-method", f"{what} — 부를 함수 이름이 실행 중에 정해진다"))
            return
        types, how = (({ctx}, "static") if r.chain in (None, ("self",)) else self.type_of_chain(r.chain, fdecl, ctx, r.expr_path))
        ids = []
        if isinstance(types, set):
            for k in types:
                hit = self.find_member(k, r.arg)
                if hit is not None:
                    ids.append(sym_id(hit[0][0], hit[1].qual))
        if not ids:
            ids = sorted({sym_id(k[0], d.qual) for k, d in self.by_member.get(r.arg, ())})
        kind = "checks" if r.special == "has_method" else "calls"
        for dst in ids:
            self.add(src, dst, kind, "dynamic", r.line, path, label)
        cat = "duck-typing" if r.special == "has_method" else "dynamic-method"
        self.unresolved.append(Unres(src, path, r.line, cat, f"{label} — 문자열 이름이라 바꾸면 조용히 어긋난다", " ".join(ids)))

    def _lit(self, lit, src, path) -> None:
        v = lit.value[len("res://"):]
        kind = {"preload": "preloads", "load": "loads", "extends": "extends", "text": "reads-text", "dir": "scans-dir"}.get(lit.ctx, "references")
        if lit.pattern:
            pat = lit.pattern[len("res://"):]
            self.patterns.append((src, path, lit.line, "loads-pattern", pat))
            self.unresolved.append(Unres(src, path, lit.line, "dynamic-load", f'"{lit.value}" 틀 — 어느 파일인지는 실행 중 값이 정한다(glob {pat})'))
            return
        is_dir = v == "" or v.endswith("/") or "." not in v.rsplit("/", 1)[-1]
        if is_dir:
            d = v.rstrip("/")
            self.patterns.append((src, path, lit.line, "scans-dir", (d + "/**") if d else "**"))
            return
        if v in self.existing:
            if kind != "extends":  # extends는 _file_edges가 클래스로 잇는다
                self.add(src, v, kind, "static", lit.line, path)
        elif not v.endswith(".import"):
            self.unresolved.append(Unres(src, path, lit.line, "missing-path", f'"{lit.value}" — 저장소에 없는 경로(만들어지는 파일이거나 오래된 참조)'))

    def _codegen(self, src, path, line, names, bases=()) -> None:
        ids = []
        roots = [(b, "") for b in bases if (b, "") in self.classes]
        for n in names:
            if roots:  # 같은 파일의 'extends "res://x.gd"' 글이 만든 스크립트의 부모다 → 그 사슬에서만 찾는다
                for rk in roots:
                    hit = self.find_member(rk, n)
                    if hit is not None and hit[1].kind == "func":
                        ids.append(sym_id(hit[0][0], hit[1].qual))
            else:
                ids.extend(sorted({sym_id(k[0], d.qual) for k, d in self.by_member.get(n, ()) if d.kind == "func"}))
        for dst in ids:
            self.add(src, dst, "overrides", "dynamic", line, path, "codegen")
        self.unresolved.append(Unres(src, path, line, "codegen", f"문자열로 만든 GDScript가 func {', '.join(names)}를 정의(실행 중 컴파일·덮어쓰기)", " ".join(ids)))

    # ── 패턴 → 파일 ──────────────────────────────────────────
    def pattern_hits(self, path: str) -> list[tuple]:
        out = []
        for src, f, line, kind, pat in self.patterns:
            if pat.endswith("/**"):
                if path.startswith(pat[:-2]):
                    out.append((src, f, line, kind, pat))
            elif fnmatch.fnmatchcase(path, pat):
                out.append((src, f, line, kind, pat))
        return out


def _worse(a: str, b: str) -> str:
    order = {"static": 0, "inferred": 1, "name-map": 2, "": 3}
    return a if order.get(a, 3) >= order.get(b, 3) else b
