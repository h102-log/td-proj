"""파이썬 쪽: 평가 래퍼(gd("스위트", "EV번호")), conftest의 MERGE_ONLY, res:// 문자열.

파이썬 호출 그래프 전체는 만들지 않는다. tools/art·audio의 생성 스크립트는 그림·소리를 굽는 독립 도구라
코드 그래프에 넣어도 얻는 것이 적다(SKILL.md «색인 범위»).
"""
from __future__ import annotations

import ast
import re

RES_RE = re.compile(r"res://[\w./%-]+")


def eval_wrappers(text: str) -> list[tuple]:
    """[(테스트 함수 이름, 줄, 스위트, EV)] — tests/eval/test_*.py."""
    out = []
    try:
        tree = ast.parse(text)
    except SyntaxError:
        return out
    for node in tree.body:
        if not isinstance(node, ast.FunctionDef) or not node.name.startswith("test"):
            continue
        for sub in ast.walk(node):
            if (isinstance(sub, ast.Call) and isinstance(sub.func, ast.Name) and sub.func.id == "gd"
                    and len(sub.args) >= 2 and all(isinstance(a, ast.Constant) and isinstance(a.value, str) for a in sub.args[:2])):
                out.append((node.name, node.lineno, sub.args[0].value, sub.args[1].value))
    return out


def merge_only(text: str) -> set[str]:
    """conftest.py의 MERGE_ONLY = {f"EV{n}" for n in (...)} 를 읽는다."""
    try:
        tree = ast.parse(text)
    except SyntaxError:
        return set()
    for node in ast.walk(tree):
        if isinstance(node, ast.Assign) and any(isinstance(t, ast.Name) and t.id == "MERGE_ONLY" for t in node.targets):
            v = node.value
            if isinstance(v, ast.SetComp) and v.generators and isinstance(v.generators[0].iter, ast.Tuple):
                nums = [e.value for e in v.generators[0].iter.elts if isinstance(e, ast.Constant) and isinstance(e.value, int)]
                return {f"EV{n}" for n in nums}
            try:
                return {str(x) for x in ast.literal_eval(v)}
            except Exception:
                return set()
    return set()


def py_functions(text: str) -> list[tuple]:
    """[(이름, 시작 줄, 끝 줄)] 맨 위 함수만(래퍼 심볼용)."""
    try:
        tree = ast.parse(text)
    except SyntaxError:
        return []
    return [(n.name, n.lineno, getattr(n, "end_lineno", n.lineno)) for n in tree.body if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef))]


def res_literals(text: str) -> list[tuple]:
    """[(줄, res:// 경로)]"""
    out = []
    for i, line in enumerate(text.split("\n"), 1):
        for m in RES_RE.finditer(line):
            out.append((i, m.group()))
    return out
