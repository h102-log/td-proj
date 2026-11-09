"""한국어 전문 검색: 색인 글을 미리 토큰으로 펼쳐 FTS5(BM25)에 넣는다.

SQLite 기본 토크나이저(unicode61)는 띄어쓰기로만 끊어 «수리비는»에서 «수리비»를 못 찾는다.
trigram은 두 글자 낱말(공병·성문·수리)을 못 찾는다. 그래서 한글 덩어리는 «통째 + 두 글자씩(bigram)»으로,
식별자는 «통째 + _로 나눈 조각»으로 펼친다. 질의도 같은 규칙으로 펼쳐 구(phrase)로 찾는다.
"""
from __future__ import annotations

import re

WORD = re.compile(r"[A-Za-z_][A-Za-z0-9_]*|\d+|[가-힣]+")
ID_TOKEN = re.compile(r"^(?:ev|s|i|u|pr)\d+$")
# 질의 끝 조사(색인 쪽은 bigram이라 남겨도 되지만, 질의에 붙으면 구 검색이 좁아진다)
PARTICLES = ("에서", "으로", "에게", "까지", "부터", "마다", "처럼", "보다", "이나", "이랑", "하고",
             "은", "는", "이", "가", "을", "를", "에", "의", "로", "도", "만", "와", "과", "랑")


def _is_hangul(w: str) -> bool:
    return "가" <= w[0] <= "힣"


def index_text(text: str) -> str:
    out = []
    for m in WORD.finditer(text):
        w = m.group()
        if _is_hangul(w):
            out.append(w)
            if len(w) > 2:
                out.extend(w[i:i + 2] for i in range(len(w) - 1))
        else:
            lw = w.lower()
            out.append(lw)
            core = lw.strip("_")
            if "_" in core:
                out.extend(p for p in core.split("_") if len(p) > 1)
    return " ".join(out)


def _strip_particle(w: str) -> str:
    if len(w) >= 3:
        for p in PARTICLES:
            if w.endswith(p) and len(w) - len(p) >= 2:
                return w[: -len(p)]
    return w


def query_terms(q: str) -> list[str]:
    terms = []
    for m in WORD.finditer(q):
        w = m.group()
        if _is_hangul(w):
            w = _strip_particle(w)
            if len(w) == 1:
                terms.append(f"{w}*")
            elif len(w) == 2:
                terms.append(f'"{w}"')
            else:
                # 활용으로 끝 글자가 바뀐다(비켜서며·비켜선다) → 전체 구 OR 끝 글자를 뗀 어간. 전체가 맞으면 BM25가 더 높다
                full = '"' + " ".join(w[i:i + 2] for i in range(len(w) - 1)) + '"'
                stem = w[:-1]
                stem_q = '"' + " ".join(stem[i:i + 2] for i in range(len(stem) - 1)) + '"'
                terms.append(f"({full} OR {stem_q})")
        else:
            lw = w.lower()
            if ID_TOKEN.match(lw) or len(lw) < 3:
                terms.append(f'"{lw}"')
            else:
                terms.append(f'"{lw}"*')
    return terms


def match_expr(q: str, mode: str = "and") -> str:
    terms = query_terms(q)
    return (" AND " if mode == "and" else " OR ").join(terms)


def snippet(text: str, q: str, width: int = 110) -> str:
    """질의 낱말이 처음 나오는 곳 둘레를 보인다."""
    flat = " ".join(text.split())
    words = [_strip_particle(m.group()) for m in WORD.finditer(q)]
    pos = -1
    for w in words:
        i = flat.lower().find(w.lower())
        if i >= 0 and (pos < 0 or i < pos):
            pos = i
    if pos < 0:
        return flat[:width] + ("…" if len(flat) > width else "")
    a = max(0, pos - width // 3)
    b = min(len(flat), a + width)
    return ("…" if a > 0 else "") + flat[a:b] + ("…" if b < len(flat) else "")
