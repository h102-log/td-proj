"""GDScript 토큰 스캐너.

문법 전체를 파싱하지 않는다. 토큰(문자열·주석·이름·연산자)과 들여쓰기만으로
① 선언(클래스·함수·변수·상수·시그널)의 줄 범위와 주석,
② 함수 몸통 안의 이름 참조(받는 쪽 사슬 + 호출 여부),
③ res:// 문자열, ④ 받는 쪽 타입을 짐작할 대입(x = A.new())을 뽑는다.
받는 쪽의 타입은 여기서 정하지 않는다(graph.py가 프로젝트 전체 표를 보고 정한다).
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field

# 자주 나오는 토큰을 앞에 둔다(정규식은 대안을 차례로 시도한다).
# 이름 뒤에 따옴표가 붙으면(r"..." 날 문자열) 이름으로 끊지 않고 str로 넘긴다
TOKEN_RE = re.compile(
    r"""
  (?P<ws>[ \t\f]+)
| (?P<name>[A-Za-z_]\w*(?!["']))
| (?P<num>0[xX][0-9A-Fa-f_]+|0[bB][01_]+|(?:\d[\d_]*\.?[\d_]*|\.\d[\d_]*)(?:[eE][+-]?\d+)?)
| (?P<str>(?:[&^]|[rR])?(?:\"\"\"[\s\S]*?\"\"\"|'''[\s\S]*?'''|"(?:\\.|[^"\\\r\n])*"|'(?:\\.|[^'\\\r\n])*'))
| (?P<op>->|:=|==|!=|<=|>=|&&|\|\||\*\*=?|<<=?|>>=?|[-+*/%&|^]=|\.\.\.|[-+*/%<>=!&|^~.,:;()\[\]{}@?])
| (?P<nl>\r?\n)
| (?P<comment>\#[^\r\n]*)
| (?P<node>\$(?:"(?:\\.|[^"\\\r\n])*"|[A-Za-z_][\w/]*))
| (?P<cont>\\\r?\n)
| (?P<name2>[A-Za-z_]\w*)
| (?P<other>.)
""",
    re.X,
)

KEYWORDS = frozenset(
    "if elif else for while match when break continue pass return class class_name extends is in as "
    "signal func static const enum var breakpoint preload await yield assert void and or not "
    "true false null PI TAU INF NAN self super".split()
)
DECL_WORDS = frozenset("func var const signal class class_name extends enum".split())
SIGNAL_METHODS = frozenset(("emit", "connect", "disconnect", "is_connected"))
DYN_CALLS = frozenset(("call", "call_deferred", "callv"))
TEXT_FUNCS = frozenset(("get_file_as_string", "get_file_as_bytes", "file_exists"))
DIR_FUNCS = frozenset(("get_files_at", "get_directories_at", "list_directory", "dir_exists_absolute", "open"))
RECV_STOP = KEYWORDS - {"self", "super"}
HANGUL = re.compile(r"[가-힣]")
CODEGEN_FUNC = re.compile(r"(?m)^\s*(?:static\s+)?func\s+(\w+)\s*\(")
CODEGEN_BASE = re.compile(r'extends\s+\\?"res://([\w./-]+\.gd)\\?"')
RES_PATH = re.compile(r"res://[\w./%*-]*")


class Tok:
    __slots__ = ("kind", "text", "line")

    def __init__(self, kind: str, text: str, line: int) -> None:
        self.kind = kind
        self.text = text
        self.line = line


@dataclass
class LL:  # 논리 줄: 괄호 안 줄바꿈과 \ 이음을 한 줄로 친다
    start: int
    end: int
    indent: int
    code: list
    comments: list


@dataclass
class Decl:
    kind: str  # class / func / var / const / signal
    name: str
    qual: str  # 안쪽 클래스면 Inner.name
    cls: str  # 이 선언을 품은 안쪽 클래스('' = 파일 클래스)
    line: int
    end: int
    indent: int
    static: bool = False
    type_text: str = ""  # 선언 타입(var x: T), 함수 반환 타입
    infer_text: str = ""  # := 오른쪽이 A.new(...)·preload(...)면 그 타입
    params: list = field(default_factory=list)  # [(이름, 타입 글)]
    locals: dict = field(default_factory=dict)  # 이름 → (타입 글, 'static'|'inferred'|'')
    local_calls: dict = field(default_factory=dict)  # 지역 이름 → 오른쪽이 부른 함수 이름(var b = battle(...))
    returns: list = field(default_factory=list)  # [('type', 글) | ('call', 함수 이름) | ('name', 지역 이름)]
    elem_src: dict = field(default_factory=dict)  # 반복 변수·람다 매개변수 → 원소를 꺼낸 컨테이너 사슬
    elem_alias: dict = field(default_factory=dict)  # 지역 컨테이너 → 원래 컨테이너 사슬(var hit := b.units.filter(...))
    base: str = ""  # class X extends Y
    alias: str = ""  # const X := preload("res://...") 의 저장소 경로
    doc: list = field(default_factory=list)  # [(줄, 글)] 바로 위 주석
    comments: list = field(default_factory=list)  # [(줄, 글)] 몸통·줄 끝 주석
    signature: str = ""
    hangul: int = 0  # 한글 문자열 리터럴 수(번역 평가 EV373 대상)
    owner_block: bool = False  # 아래 줄을 품는 블록(class·func·setget var)


@dataclass
class Ref:
    src: str  # 둘러싼 선언 qual('' = 파일 머리)
    line: int
    name: str
    call: bool
    chain: tuple | None  # None = 맨 이름, ('self',) ('super',) ('a', 'b') ('<expr>', ...)
    special: str = ""  # new / emit / connect / dyncall / callable_invoke / has_method / callable / getset / super_call
    arg: str = ""  # 특수 호출의 첫 인자(문자열 값 또는 이름)
    arg_kind: str = ""  # str / name / member / lambda / other
    arg_chain: tuple = ()
    expr_path: str = ""  # 받는 쪽이 load("res://x.gd") 같은 식일 때 그 경로


@dataclass
class Lit:
    src: str
    line: int
    value: str  # 따옴표를 뗀 값
    ctx: str  # preload / load / extends / text / dir / ref
    pattern: str = ""  # % 틀이나 + 이음이면 glob


@dataclass
class Assign:
    src: str
    line: int
    target: tuple  # ('battle',) ('view', 'battle') ('self', 'x')
    rhs: str  # 'Alias.new' 꼴 타입 글이거나 'res://x.gd'
    static: bool  # := 로 받은 것


@dataclass
class FileScan:
    path: str
    class_name: str = ""
    extends: str = ""
    decls: list = field(default_factory=list)
    refs: list = field(default_factory=list)
    lits: list = field(default_factory=list)
    assigns: list = field(default_factory=list)
    adds: list = field(default_factory=list)  # [(src, 컨테이너 사슬, 값 모양)] append·push_back·사전[키] = 값
    codegen: list = field(default_factory=list)  # [(src, line, [정의한 func 이름])]
    codegen_bases: list = field(default_factory=list)  # 문자열 GDScript의 extends 경로
    warnings: list = field(default_factory=list)
    hangul: dict = field(default_factory=dict)  # 선언 qual → 한글 문자열 리터럴 수
    lines: int = 0


def tokenize(src: str) -> list[Tok]:
    """공백 토큰은 버리고 줄 머리 공백(들여쓰기)만 'ind' 토큰으로 남긴다."""
    toks: list[Tok] = []
    append = toks.append
    line = 1
    bol = True
    for m in TOKEN_RE.finditer(src):
        kind = m.lastgroup
        text = m.group()
        if kind == "ws":
            if bol:
                append(Tok("ind", text, line))
            continue
        if kind == "name2":
            kind = "name"
        append(Tok(kind, text, line))
        if kind == "nl" or kind == "cont":
            line += 1
            bol = kind == "nl"
            continue
        bol = False
        if kind == "str" and "\n" in text:
            line += text.count("\n")
    return toks


def _width(ws: str) -> int:
    return len(ws) + 3 * ws.count("\t")


TOP_WORDS = frozenset(("func", "class", "static", "signal", "const", "class_name", "extends"))


def logical_lines(toks: list[Tok], warnings: list) -> list[LL]:
    out: list[LL] = []
    code: list = []
    comments: list = []
    depth = 0
    indent = pending = 0
    at_bol = True
    start = None
    end = 0
    for t in toks:
        k = t.kind
        if k == "nl":
            at_bol = True
            pending = 0
            if depth > 0:
                continue
            if code or comments:
                out.append(LL(start, end, indent, code, comments))
            code, comments, start = [], [], None
            continue
        if k == "cont":
            at_bol = False
            continue
        if k == "ind":
            if at_bol:
                pending = _width(t.text)
            continue
        if at_bol and depth > 0 and pending == 0 and k == "name" and t.text in TOP_WORDS:
            # 괄호 짝이 어긋나 줄이 끝없이 이어지는 것을 막는다(복구). 정상 파일에서는 일어나지 않는다
            warnings.append(f"{t.line}: 괄호 짝이 맞지 않아 여기서 줄을 끊었다")
            if code or comments:
                out.append(LL(start, end, indent, code, comments))
            code, comments, start, depth = [], [], None, 0
        if start is None:
            start = t.line
            indent = pending
        at_bol = False
        end = t.line + t.text.count("\n") if k == "str" else t.line
        if k == "comment":
            comments.append((t.line, t.text))
            continue
        code.append(t)
        if k == "op":
            if t.text in "([{":
                depth += 1
            elif t.text in ")]}":
                depth = max(0, depth - 1)
    if code or comments:
        out.append(LL(start, end, indent, code, comments))
    return out


def lit_value(text: str) -> str:
    s = text.lstrip("&^rR")
    q = 3 if s[:3] in ('"""', "'''") else 1
    return s[q:-q] if len(s) >= 2 * q else s


def _strip_annotations(code: list) -> list:
    i = 0
    while i < len(code) and code[i].kind == "op" and code[i].text == "@":
        i += 2  # @ 이름
        if i < len(code) and code[i].text == "(":
            depth = 0
            while i < len(code):
                if code[i].text == "(":
                    depth += 1
                elif code[i].text == ")":
                    depth -= 1
                    if depth == 0:
                        i += 1
                        break
                i += 1
    return code[i:]


def _match_paren(code: list, i: int) -> int:
    """code[i]가 여는 괄호일 때 짝 닫는 괄호의 위치(없으면 len-1)."""
    depth = 0
    for j in range(i, len(code)):
        t = code[j]
        if t.kind == "op":
            if t.text in "([{":
                depth += 1
            elif t.text in ")]}":
                depth -= 1
                if depth == 0:
                    return j
    return len(code) - 1


def _open_of(code: list, j: int) -> int:
    """code[j]가 닫는 괄호일 때 짝 여는 괄호의 위치."""
    depth = 0
    for k in range(j, -1, -1):
        t = code[k]
        if t.kind == "op":
            if t.text in ")]}":
                depth += 1
            elif t.text in "([{":
                depth -= 1
                if depth == 0:
                    return k
    return 0


def _split_args(code: list, open_i: int) -> list[list]:
    close = _match_paren(code, open_i)
    args, cur, depth = [], [], 0
    for t in code[open_i + 1 : close]:
        if t.kind == "op" and t.text in "([{":
            depth += 1
        elif t.kind == "op" and t.text in ")]}":
            depth -= 1
        if depth == 0 and t.kind == "op" and t.text == ",":
            args.append(cur)
            cur = []
            continue
        cur.append(t)
    if cur:
        args.append(cur)
    return args


def _type_text(toks: list) -> str:
    return "".join(t.text for t in toks).strip()


def _rhs_type(rhs: list) -> str:
    """오른쪽 식이 A.new(...) / A.B.new(...) / preload("x.gd") / load("x.gd").new() 이면 타입 글.
    {…}·[…] 리터럴은 Dictionary·Array(엔진 타입)라 그 멤버 접근은 사전 키·배열 메서드다."""
    if rhs and rhs[0].kind == "op" and rhs[0].text in "{[" and _match_paren(rhs, 0) == len(rhs) - 1:
        return "Dictionary" if rhs[0].text == "{" else "Array"
    if len(rhs) >= 4 and rhs[0].kind == "name" and rhs[1].text == "." :
        names = [rhs[0].text]
        i = 1
        while i + 1 < len(rhs) and rhs[i].text == "." and rhs[i + 1].kind == "name":
            names.append(rhs[i + 1].text)
            i += 2
        if len(names) >= 2 and names[-1] == "new" and i < len(rhs) and rhs[i].text == "(":
            return ".".join(names[:-1])
    if len(rhs) >= 4 and rhs[0].kind == "name" and rhs[0].text in ("preload", "load") and rhs[1].text == "(" and rhs[2].kind == "str":
        v = lit_value(rhs[2].text)
        close = _match_paren(rhs, 1)
        is_new = close + 3 < len(rhs) and rhs[close + 1].text == "." and rhs[close + 2].text == "new"
        if v.startswith("res://") and v.endswith(".gd") and (is_new or close == len(rhs) - 1 or rhs[0].text == "preload"):
            return v
    return ""


def _rhs_call(rhs: list) -> str:
    """오른쪽 식이 호출 하나뿐이면 'f' 또는 'b.spawn_enemy'(반환 타입 추론용). self.f(...)는 'f'."""
    names, i = [], 0
    while i < len(rhs) and rhs[i].kind == "name":
        names.append(rhs[i].text)
        if i + 1 < len(rhs) and rhs[i + 1].text == ".":
            i += 2
            continue
        i += 1
        break
    if not names or i >= len(rhs) or rhs[i].text != "(" or _match_paren(rhs, i) != len(rhs) - 1:
        return ""
    if names[0] in KEYWORDS and names[0] != "self":
        return ""
    if names[0] == "self":
        names = names[1:]
    return ".".join(names)


def _params(code: list, open_i: int) -> list:
    out = []
    for arg in _split_args(code, open_i):
        if not arg or arg[0].kind != "name":
            continue
        name = arg[0].text
        typ = ""
        if len(arg) >= 3 and arg[1].text == ":":
            stop = next((j for j in range(2, len(arg)) if arg[j].text in ("=",)), len(arg))
            typ = _type_text(arg[2:stop])
        out.append((name, typ))
    return out


def _receiver(code: list, dot: int) -> tuple:
    """code[dot]가 '.'일 때 그 앞 받는 쪽 사슬. ('a','b') / ('self',) / ('<expr>', ...)."""
    chain = []
    k = dot - 1
    while k >= 0:
        t = code[k]
        if t.kind == "name" and t.text not in RECV_STOP:
            chain.append(t.text)
            if k - 1 >= 0 and code[k - 1].kind == "op" and code[k - 1].text == ".":
                k -= 2
                continue
            break
        if t.kind == "op" and t.text in ")]":
            chain.append("<expr>")
            break
        chain.append("<lit>" if t.kind in ("str", "num") else "<expr>")
        break
    chain.reverse()
    return tuple(chain) if chain else ("<expr>",)


def _expr_path(code: list, dot: int) -> str:
    """받는 쪽 사슬이 호출 결과로 시작하면 그 식: 'res://x.gd'(load·preload) · 'type:A.B'(A.B.new()) · 'call:f'|'call:b.f'(반환 타입)."""
    k = dot
    while k - 2 >= 0 and code[k - 1].kind == "name" and code[k - 2].text == ".":
        k -= 2  # a().b.c 의 c 앞 점에서 a() 뒤 점까지
    j = k - 1
    if j < 0 or code[j].text != ")":
        return ""
    o = _open_of(code, j)
    if o < 1 or code[o - 1].kind != "name":
        return ""
    head = code[o - 1].text
    if head in ("load", "preload") and o + 1 < j and code[o + 1].kind == "str":
        v = lit_value(code[o + 1].text)
        return v if v.startswith("res://") else ""
    names = [head]
    m = o - 2
    while m >= 1 and code[m].text == "." and code[m - 1].kind == "name":
        names.append(code[m - 1].text)
        m -= 2
    names.reverse()
    if m >= 0 and code[m].text == ".":
        return ""  # 더 깊은 식(x().y.z())
    if names[0] in RECV_STOP:
        return ""
    if names[-1] == "new" and len(names) >= 2:
        return "type:" + ".".join(names[:-1])
    names = [x for x in names if x != "self"]
    return "call:" + ".".join(names) if names else ""


def _arg_summary(arg: list) -> tuple:
    if not arg:
        return "", "other", ()
    if arg[0].kind == "str":
        return lit_value(arg[0].text), "str", ()
    if arg[0].kind == "name" and arg[0].text == "func":
        return "", "lambda", ()
    names = []
    i = 0
    while i < len(arg) and arg[i].kind == "name":
        names.append(arg[i].text)
        if i + 1 < len(arg) and arg[i + 1].text == ".":
            i += 2
            continue
        break
    if names and names[-1] in ("bind", "unbind"):
        names = names[:-1]
    if not names:
        return "", "other", ()
    if len(names) == 1:
        return names[0], "name", ()
    if names[0] == "self" and len(names) == 2:
        return names[1], "name", ()
    return names[-1], "member", tuple(names[:-1])


PASS_METHODS = frozenset(("duplicate", "filter", "slice", "values"))  # 원소 타입을 그대로 넘기는 메서드
ELEM_LAMBDAS = {"filter": (0,), "map": (0,), "any": (0,), "all": (0,), "sort_custom": (0, 1), "reduce": (1,)}
ADD_METHODS = frozenset(("append", "push_back", "push_front"))


def container_chain(toks: list) -> tuple:
    """'b.enemies' · 'enemies.duplicate()' · 'structures.values()' · 'b.units.filter(...)' → ('b', 'enemies') 같은 사슬.
    원소 타입을 넘기지 않는 식이면 ()."""
    names, i = [], 0
    while i < len(toks) and toks[i].kind == "name":
        names.append(toks[i].text)
        if i + 1 < len(toks) and toks[i + 1].text == ".":
            i += 2
            continue
        i += 1
        break
    if not names or names[0] in KEYWORDS - {"self"}:
        return ()
    # 끝의 넘기는 메서드 호출(.values() .duplicate() .filter(...))은 떼고, 그 밖의 호출이면 포기
    while len(names) >= 2 and names[-1] in PASS_METHODS and i < len(toks) and toks[i].text == "(":
        close = _match_paren(toks, i)
        names = names[:-1]
        i = close + 1
        if i < len(toks) and toks[i].text == "." and i + 1 < len(toks) and toks[i + 1].kind == "name" and toks[i + 1].text in PASS_METHODS:
            names.append(toks[i + 1].text)
            i += 2
            continue
    if i < len(toks) and toks[i].text not in (":",):
        return ()
    if names[0] == "self":
        names = names[1:]
    return tuple(names)


def scan_refs(code: list, src: str, fs: FileScan, locals_sink: dict | None = None, elem_sink: dict | None = None) -> None:
    """코드 토큰에서 이름 참조·문자열·지역 선언을 뽑는다."""
    n = len(code)
    brackets: list = []
    for i, t in enumerate(code):
        k = t.kind
        if k == "op":
            if t.text in "([{":
                brackets.append(t.text)
            elif t.text in ")]}" and brackets:
                brackets.pop()
            continue
        if k == "str":
            _scan_lit(code, i, src, fs)
            continue
        if k != "name":
            continue
        name = t.text
        prev = code[i - 1] if i else None
        nxt = code[i + 1] if i + 1 < n else None
        if prev is not None and prev.kind == "name" and prev.text in DECL_WORDS:
            if prev.text == "func" and locals_sink is not None:  # 이름 붙은 람다는 드물다
                pass
            continue
        member = prev is not None and prev.kind == "op" and prev.text == "."
        call = nxt is not None and nxt.kind == "op" and nxt.text == "("
        if not member:
            if name == "super" and call:  # super(...) — 덮어쓴 부모 함수
                fs.refs.append(Ref(src, t.line, "", True, ("super",), special="super_call"))
                continue
            if name in KEYWORDS:
                if name == "func" and nxt is not None and nxt.text == "(" and locals_sink is not None:
                    params = _params(code, i + 1)
                    for pn, pt in params:  # 람다 매개변수는 지역 이름
                        locals_sink.setdefault(pn, (pt, "static" if pt else ""))
                    # recv.filter(func(e): …) — e는 recv의 원소
                    if elem_sink is not None and i >= 3 and code[i - 1].text == "(" and code[i - 2].kind == "name" \
                            and code[i - 2].text in ELEM_LAMBDAS and code[i - 3].text == ".":
                        o = i - 3
                        start = o
                        while start - 2 >= 0 and code[start - 1].kind == "name" and (start - 2 < 0 or code[start - 2].text == "."):
                            start -= 2
                        if start - 1 >= 0 and code[start - 1].kind == "name":
                            start -= 1
                        chain = container_chain(code[start:o] + [Tok("op", ":", 0)])
                        if chain:
                            for idx in ELEM_LAMBDAS[code[i - 2].text]:
                                if idx < len(params) and not params[idx][1]:
                                    elem_sink.setdefault(params[idx][0], chain)
                if name == "for" and locals_sink is not None and nxt is not None and nxt.kind == "name":
                    typ = ""
                    stop = next((j for j in range(i + 2, n) if code[j].kind == "name" and code[j].text == "in"), n)
                    if i + 3 < n and code[i + 2].text == ":":
                        typ = _type_text(code[i + 3 : stop])
                    locals_sink.setdefault(nxt.text, (typ, "static" if typ else ""))
                    if not typ and elem_sink is not None and stop < n:
                        chain = container_chain(code[stop + 1 :])
                        if chain:
                            elem_sink.setdefault(nxt.text, chain)
                continue
            if brackets and brackets[-1] == "{" and nxt is not None and nxt.kind == "op" and nxt.text == "=":
                continue  # {이름 = 값} 사전 키
            if call and name in DYN_CALLS:  # 자기 자신의 call("이름")
                args = _split_args(code, i + 1)
                a, ak, _ = _arg_summary(args[0] if args else [])
                fs.refs.append(Ref(src, t.line, name, True, ("self",), special="dyncall", arg=a, arg_kind=ak))
                continue
            if call and name == "has_method":
                args = _split_args(code, i + 1)
                a, ak, _ = _arg_summary(args[0] if args else [])
                fs.refs.append(Ref(src, t.line, name, True, ("self",), special="has_method", arg=a, arg_kind=ak))
                continue
            if call and name == "set":  # self.set(키 변수, 값): 필드 이름을 데이터가 정한다(리플렉션)
                args = _split_args(code, i + 1)
                close = _match_paren(code, i + 1)
                setter_decl = close + 1 < n and code[close + 1].text == ":"  # setget 블록의 set(v): 선언
                if args and not setter_decl and len(args) >= 2 and not (args[0] and args[0][0].kind == "str"):
                    fs.refs.append(Ref(src, t.line, name, True, ("self",), special="reflect_set"))
                    continue
            if call and name == "get_property_list":
                fs.refs.append(Ref(src, t.line, name, True, ("self",), special="reflect_list"))
                continue
            if call and name == "Callable":
                args = _split_args(code, i + 1)
                if len(args) >= 2:
                    a, ak, _ = _arg_summary(args[1])
                    recv = tuple(x.text for x in args[0] if x.kind == "name" and x.text != ".") or ("<expr>",)
                    fs.refs.append(Ref(src, t.line, name, True, recv if recv != ("self",) else ("self",), special="callable", arg=a, arg_kind=ak))
                continue
            chain = None
        else:
            chain = _receiver(code, i - 1)
            if call and name == "new":
                fs.refs.append(Ref(src, t.line, name, True, chain, special="new", expr_path=_expr_path(code, i - 1)))
                continue
            if call and name in ADD_METHODS and chain[0] not in ("<expr>", "<lit>"):  # 원소 타입 모으기
                args = _split_args(code, i + 1)
                shape = _value_shape(args[0]) if args else None
                cont = tuple(c for c in chain if c != "self")
                if shape and cont:
                    fs.adds.append((src, cont, shape))
            if call and name in DYN_CALLS:
                args = _split_args(code, i + 1)
                a, ak, _ = _arg_summary(args[0] if args else [])
                special = "dyncall" if ak == "str" else "callable_invoke"
                fs.refs.append(Ref(src, t.line, name, True, chain, special=special, arg=a, arg_kind=ak, expr_path=_expr_path(code, i - 1)))
                continue
            if call and name == "has_method":
                args = _split_args(code, i + 1)
                a, ak, _ = _arg_summary(args[0] if args else [])
                fs.refs.append(Ref(src, t.line, name, True, chain, special="has_method", arg=a, arg_kind=ak))
                continue
            if call and name in ("get", "set") and i + 2 < n and code[i + 2].kind == "str":
                fs.refs.append(Ref(src, t.line, name, True, chain, special="getset", arg=lit_value(code[i + 2].text), arg_kind="str"))
                continue
            if call and name == "get_property_list":
                fs.refs.append(Ref(src, t.line, name, True, chain, special="reflect_list"))
                continue
            if name in SIGNAL_METHODS and call:
                continue  # 시그널 쪽(앞 이름)에서 처리했다
        # 시그널: 이름 . emit/connect (
        special = arg = arg_kind = ""
        arg_chain = ()
        if (not call and i + 3 < n and code[i + 1].text == "." and code[i + 2].kind == "name"
                and code[i + 2].text in SIGNAL_METHODS and code[i + 3].text == "("):
            special = "emit" if code[i + 2].text == "emit" else "connect"
            if special == "connect" and code[i + 2].text == "connect":
                args = _split_args(code, i + 3)
                arg, arg_kind, arg_chain = _arg_summary(args[0] if args else [])
        fs.refs.append(Ref(src, t.line, name, call, chain, special=special, arg=arg, arg_kind=arg_kind,
                           arg_chain=arg_chain, expr_path=_expr_path(code, i - 1) if member else ""))


def _scan_lit(code: list, i: int, src: str, fs: FileScan) -> None:
    t = code[i]
    v = lit_value(t.text)
    if HANGUL.search(v):
        fs.hangul[src] = fs.hangul.get(src, 0) + 1
    if "func " in v:
        # 한 줄 문자열의 \n·\t 이스케이프로 쓴 코드도 있다(show.gd BARS_SRC) → 풀어서 본다
        code_v = v.replace("\\n", "\n").replace("\\t", "\t").replace('\\"', '"') if "\\" in v else v
        names = CODEGEN_FUNC.findall(code_v)
        if names:
            fs.codegen.append((src, t.line, names))
    for base in CODEGEN_BASE.findall(v):  # 'extends "res://x.gd"\n' + code — 만든 스크립트의 부모
        fs.codegen_bases.append(base)
    if not v.startswith("res://") or not RES_PATH.fullmatch(v):
        return  # 경로 모양이 아닌 글(«res://…가 없다» 같은 오류 문구)은 경로로 치지 않는다
    prev = code[i - 1] if i else None
    prev2 = code[i - 2] if i > 1 else None
    nxt = code[i + 1] if i + 1 < len(code) else None
    ctx = "ref"
    if prev is not None and prev.kind == "name" and prev.text == "extends":
        ctx = "extends"
    elif prev is not None and prev.text == "(" and prev2 is not None and prev2.kind == "name":
        f = prev2.text
        recv = code[i - 4].text if i >= 4 and code[i - 3].text == "." else ""
        if f == "preload":
            ctx = "preload"
        elif f == "load" and recv in ("", "ResourceLoader"):
            ctx = "load"
        elif f in TEXT_FUNCS or (f == "open" and recv == "FileAccess"):
            ctx = "text"
        elif f in DIR_FUNCS and (f != "open" or recv == "DirAccess"):
            ctx = "dir"
    pattern = ""
    if nxt is not None and nxt.kind == "op" and nxt.text == "%":
        pattern = re.sub(r"%[-+ 0#]*\d*(?:\.\d+)?[sdifxXc]", "*", v)
    elif nxt is not None and nxt.kind == "op" and nxt.text == "+":
        pattern = v + "*"
    fs.lits.append(Lit(src, t.line, v, ctx, pattern))


def _value_shape(toks: list):
    """원소로 넣는 값: ('name', 지역) · ('type', 타입 글) · ('call', 'f'|'b.f')."""
    if len(toks) == 1 and toks[0].kind == "name" and toks[0].text not in KEYWORDS:
        return ("name", toks[0].text)
    t = _rhs_type(toks)
    if t and t not in ("Dictionary", "Array"):
        return ("type", t)
    f = _rhs_call(toks)
    if f:
        return ("call", f)
    return None


def _store(code: list, src: str, fs: FileScan) -> None:
    """문장 맨 앞의 a[.b][키] = 값 (사전에 넣기) — values() 원소 타입 모으기."""
    names, i = [], 0
    while i < len(code) and code[i].kind == "name":
        names.append(code[i].text)
        if i + 1 < len(code) and code[i + 1].text == ".":
            i += 2
            continue
        i += 1
        break
    if not names or i >= len(code) or code[i].text != "[":
        return
    close = _match_paren(code, i)
    if close + 1 < len(code) and code[close + 1].text == "=":
        shape = _value_shape(code[close + 2 :])
        cont = tuple(c for c in names if c != "self")
        if shape and cont:
            fs.adds.append((src, cont, shape))


def _assign(code: list, src: str, fs: FileScan) -> None:
    """문장 맨 앞의 [self.]a[.b] = A.new(...) 를 적는다."""
    names = []
    i = 0
    while i < len(code) and code[i].kind == "name":
        names.append(code[i].text)
        if i + 1 < len(code) and code[i + 1].text == ".":
            i += 2
            continue
        i += 1
        break
    if not names or i >= len(code) or code[i].kind != "op" or code[i].text not in ("=", ":="):
        return
    rhs = _rhs_type(code[i + 1 :])
    if rhs:
        fs.assigns.append(Assign(src, code[0].line, tuple(names), rhs, code[i].text == ":="))


def scan(text: str, path: str) -> FileScan:
    fs = FileScan(path)
    src_lines = text.split("\n")
    toks = tokenize(text)
    fs.lines = text.count("\n") + 1
    lls = logical_lines(toks, fs.warnings)
    stack: list[Decl] = []
    doc_buf: list = []  # 바로 위 주석 줄들
    for ll in lls:
        if not ll.code:
            owner = stack[-1] if stack else None
            if owner is not None and owner.kind in ("func", "var") and ll.indent > owner.indent:
                owner.comments.extend(ll.comments)  # 몸통 안 주석
            else:
                if doc_buf and ll.start != doc_buf[-1][0] + 1:
                    doc_buf = []
                doc_buf.extend(ll.comments)
            continue
        while stack and stack[-1].indent >= ll.indent:
            stack.pop()
        for d in stack:
            d.end = max(d.end, ll.end)
        doc = doc_buf if doc_buf and doc_buf[-1][0] == ll.start - 1 else []
        doc_buf = []
        code = _strip_annotations(ll.code)
        if not code:
            continue
        owner = stack[-1] if stack else None
        cls = next((d.name for d in reversed(stack) if d.kind == "class"), "")
        in_body = owner is not None and owner.kind in ("func", "var")
        if not in_body:
            d = _decl(code, ll, cls, doc, fs, src_lines[ll.start - 1].strip()[:200])
            if d is not None:
                fs.decls.append(d)
                if d.owner_block:
                    stack.append(d)
                for d2 in stack:
                    if d2 is not d:
                        d2.end = max(d2.end, ll.end)
            continue
        # 함수 몸통
        func = owner
        func.comments.extend(ll.comments)
        if code[0].kind == "name" and code[0].text == "var" and len(code) >= 2 and code[1].kind == "name":
            name = code[1].text
            typ, how = "", ""
            if len(code) >= 4 and code[2].text == ":":
                stop = next((j for j in range(3, len(code)) if code[j].text in ("=",)), len(code))
                typ, how = _type_text(code[3:stop]), "static"
            elif len(code) >= 3 and code[2].text in (":=", "="):
                typ = _rhs_type(code[3:])
                how = ("static" if code[2].text == ":=" else "inferred") if typ else ""
                if not typ:
                    f = _rhs_call(code[3:])
                    if f:
                        func.local_calls[name] = f
                if typ in ("", "Array"):
                    cc = container_chain(code[3:] + [Tok("op", ":", 0)])
                    if cc:
                        func.elem_alias[name] = cc
            func.locals[name] = (typ, how)
        elif code[0].kind == "name" and code[0].text == "return" and len(code) > 1:
            rhs = code[1:]
            t = _rhs_type(rhs)
            if t:
                func.returns.append(("type", t))
            else:
                f = _rhs_call(rhs)
                if f:
                    func.returns.append(("call", f))
                elif len(rhs) == 1 and rhs[0].kind == "name":
                    func.returns.append(("name", rhs[0].text))
        else:
            _assign(code, func.qual, fs)
            _store(code, func.qual, fs)
        scan_refs(code, func.qual, fs, func.locals, func.elem_src)
    for d in fs.decls:
        d.hangul = fs.hangul.get(d.qual, 0)
    return fs


def _decl(code: list, ll: LL, cls: str, doc: list, fs: FileScan, sig: str) -> Decl | None:
    first = code[0].text
    static = False
    if first == "static" and len(code) > 1:
        static = True
        code = code[1:]
        first = code[0].text
    q = (lambda n: f"{cls}.{n}" if cls else n)
    trailing = ll.comments
    if first == "class_name" and len(code) > 1:
        fs.class_name = code[1].text
        if len(code) > 3 and code[2].text == "extends":
            fs.extends = _base(code[3:])
        return None
    if first == "extends" and len(code) > 1:
        if not cls:
            fs.extends = _base(code[1:])
        return None
    if first == "class" and len(code) > 1 and code[1].kind == "name":
        base = ""
        if len(code) > 3 and code[2].text == "extends":
            base = _base(code[3:])
        return Decl("class", code[1].text, q(code[1].text), cls, ll.start, ll.end, ll.indent, base=base,
                    doc=doc, comments=list(trailing), signature=sig, owner_block=True)
    if first == "func" and len(code) > 1 and code[1].kind == "name":
        name = code[1].text
        d = Decl("func", name, q(name), cls, ll.start, ll.end, ll.indent, static=static, doc=doc,
                 comments=list(trailing), signature=sig, owner_block=True)
        if len(code) > 2 and code[2].text == "(":
            close = _match_paren(code, 2)
            d.params = _params(code, 2)
            j = close + 1
            if j < len(code) and code[j].text == "->":
                stop = next((x for x in range(j + 1, len(code)) if code[x].text == ":"), len(code))
                d.type_text = _type_text(code[j + 1 : stop])
                scan_refs(code[j + 1 : stop], d.qual, fs, d.locals)
                j = stop
            while j < len(code) and code[j].text != ":":
                j += 1
            for pn, pt in d.params:
                d.locals.setdefault(pn, (pt, "static" if pt else ""))
            # 매개변수 기본값과 한 줄 몸통의 참조
            scan_refs(code[2 : close + 1], d.qual, fs, d.locals)
            body = code[j + 1 :]
            if body:
                if body[0].text == "return" and len(body) > 1:  # 한 줄 함수의 반환
                    t = _rhs_type(body[1:])
                    f = "" if t else _rhs_call(body[1:])
                    if t or f:
                        d.returns.append(("type", t) if t else ("call", f))
                _assign(body, d.qual, fs)
                scan_refs(body, d.qual, fs, d.locals, d.elem_src)
        return d
    if first in ("var", "const") and len(code) > 1 and code[1].kind == "name":
        name = code[1].text
        d = Decl(first, name, q(name), cls, ll.start, ll.end, ll.indent, static=static, doc=doc,
                 comments=list(trailing), signature=sig)
        j = 2
        if j < len(code) and code[j].text == ":" and j + 1 < len(code) and code[j + 1].text not in ("=",):
            stop = next((x for x in range(j + 1, len(code)) if code[x].text in ("=", ":")), len(code))
            d.type_text = _type_text(code[j + 1 : stop])
            j = stop
        if j < len(code) and code[j].text in ("=", ":="):
            rhs = code[j + 1 :]
            d.infer_text = _rhs_type(rhs)
            if first == "const" and len(rhs) >= 4 and rhs[0].kind == "name" and rhs[0].text in ("preload", "load") and rhs[2].kind == "str":
                v = lit_value(rhs[2].text)
                if v.startswith("res://"):
                    d.alias = v[len("res://") :]
            scan_refs(rhs, d.qual, fs)
        if code[-1].text == ":" and first == "var":  # setget 블록
            d.owner_block = True
        return d
    if first == "signal" and len(code) > 1 and code[1].kind == "name":
        return Decl("signal", code[1].text, q(code[1].text), cls, ll.start, ll.end, ll.indent, doc=doc,
                    comments=list(trailing), signature=sig)
    if first == "enum":
        name = code[1].text if len(code) > 1 and code[1].kind == "name" else ""
        if name:
            return Decl("const", name, q(name), cls, ll.start, ll.end, ll.indent, doc=doc, comments=list(trailing),
                        signature=sig)
        return None
    # 클래스 몸 수준의 다른 코드(드묾): 파일 머리 참조로 둔다
    scan_refs(code, cls, fs)
    return None


def _base(toks: list) -> str:
    if toks and toks[0].kind == "str":
        return lit_value(toks[0].text)
    names = []
    for t in toks:
        if t.kind == "name" or t.text == ".":
            names.append(t.text)
        else:
            break
    return "".join(names)
