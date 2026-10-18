# 영웅 컨셉 아트 — 크로노스, 시간 지휘자(Chronos, the Chrono Conductor). 시간을 다루는 전술가·버퍼
# 형체를 SVG 벡터로 직접 그리고(Claude 제작) shot.py로 PNG를 찍는다. 색 뼈대는 f24p(tools/art/palettes.json)의
# 남색·금색·청록이다(K에 f24p 색을 표시했다). 24px 유닛으로 옮길 때 같은 램프를 쓰려는 것이다
# 사용: python tools/art/concept/chronos.py [--out 폴더] [--scale 2] [--no-png]
#   → chronos.svg(컨셉 시트)·chronos_clean.svg(그림만)와 PNG(가로 1920 × scale px: 2 = 4K, 4 = 8K)
import argparse
import math
import random
import re
import urllib.request
from pathlib import Path

import shot

W, H = 1920, 1080
HC = (960, 430)  # 광륜(천문시계) 중심
OUT = Path(__file__).resolve().parents[3] / "art" / "concept" / "chronos"
FONT = "Cinzel, Caladea, Cambria, 'Liberation Serif', serif"
FONTS = Path.home() / ".cache" / "td-proj" / "fonts"  # Cinzel(OFL, The Cinzel Project Authors)을 받아 두는 곳. 저장소에는 넣지 않는다
CINZEL = "https://fonts.googleapis.com/css2?family=Cinzel:wght@500;700"

K = {
    "ink": "#080c18",
    "navy0": "#0c1325", "navy1": "#141e39", "navy2": "#1d2b50", "navy3": "#2b406c", "navy4": "#4f78ad",  # navy4 = f24p
    "gold0": "#4a2a0c", "gold1": "#ab5c1c", "gold2": "#d48b24", "gold3": "#efac28", "gold4": "#efd8a1", "gold5": "#fff5da",  # gold1·3·4 = f24p
    "cyan0": "#276468", "cyan1": "#3c9f9c", "cyan2": "#45d2e4", "cyan3": "#9ef2ff", "cyan4": "#e9fdff",  # cyan0·1 = f24p
    "lining": "#163b47", "lining2": "#21596a",
    "ivory": "#f2ead8", "ivory_s": "#c7bb9f",
    "skin": "#f1c8a2", "skin_s": "#d29c78", "skin_d": "#a56243", "skin_h": "#fbe2c8",  # skin_d = f24p
    "hair": "#e4e8f0", "hair_s": "#a4aec2", "hair_d": "#6e7893",  # hair_s = f24p
    "vest": "#111a2d", "trouser": "#131b31", "boot": "#0e1323", "boot_h": "#33415f", "leather": "#1b1626",
}


# ── 기하 ─────────────────────────────────────────────────────────────

def pt(p):
    return f"{p[0]:.1f} {p[1]:.1f}"


def pol(c, r, a):
    """c에서 반지름 r, 각 a도(12시 = 0, 시계 방향)"""
    t = math.radians(a)
    return c[0] + r * math.sin(t), c[1] - r * math.cos(t)


def poly(pts):
    return "M" + "L".join(pt(p) for p in pts) + "Z"


def circ(c, r):
    x, y = c
    return f"M{x - r:.2f} {y:.2f}a{r:.2f} {r:.2f} 0 1 0 {2 * r:.2f} 0a{r:.2f} {r:.2f} 0 1 0 {-2 * r:.2f} 0Z"


def sector(c, r1, r2, a0, a1):
    """r1~r2 고리의 a0~a1 조각"""
    big = 1 if a1 - a0 > 180 else 0
    return (f"M{pt(pol(c, r2, a0))}A{r2:.1f} {r2:.1f} 0 {big} 1 {pt(pol(c, r2, a1))}"
            f"L{pt(pol(c, r1, a1))}A{r1:.1f} {r1:.1f} 0 {big} 0 {pt(pol(c, r1, a0))}Z")


def arc(c, r, a0, a1):
    big = 1 if a1 - a0 > 180 else 0
    return f"M{pt(pol(c, r, a0))}A{r:.1f} {r:.1f} 0 {big} 1 {pt(pol(c, r, a1))}"


def smooth(pts, closed=True, k=1 / 6):
    """점을 지나는 매끈한 곡선(Catmull-Rom → 3차 베지어). (x, y, 1)은 꺾이는 점"""
    n = len(pts)
    P = [(p[0], p[1]) for p in pts]
    corner = [len(p) > 2 and p[2] for p in pts]

    def get(i):
        return P[i % n] if closed else P[min(max(i, 0), n - 1)]

    d = f"M{pt(P[0])}"
    for i in range(n if closed else n - 1):
        p0, p1, p2, p3 = get(i - 1), get(i), get(i + 1), get(i + 2)
        i1, i2 = i % n, (i + 1) % n
        c1 = ((p1[0] + (p2[0] - p1[0]) / 3, p1[1] + (p2[1] - p1[1]) / 3) if corner[i1]
              else (p1[0] + (p2[0] - p0[0]) * k, p1[1] + (p2[1] - p0[1]) * k))
        c2 = ((p2[0] - (p2[0] - p1[0]) / 3, p2[1] - (p2[1] - p1[1]) / 3) if corner[i2]
              else (p2[0] - (p3[0] - p1[0]) * k, p2[1] - (p3[1] - p1[1]) * k))
        d += f"C{pt(c1)} {pt(c2)} {pt(p2)}"
    return d + ("Z" if closed else "")


def mirror(pts):
    return [(W - p[0], p[1]) + tuple(p[2:]) for p in pts]


def unit(a, b):
    dx, dy = b[0] - a[0], b[1] - a[1]
    n = math.hypot(dx, dy)
    return dx / n, dy / n


def along(a, b, t, off=0.0):
    """a→b의 t 지점에서 오른손 쪽(화면 기준)으로 off만큼"""
    ux, uy = unit(a, b)
    return a[0] + (b[0] - a[0]) * t - uy * off, a[1] + (b[1] - a[1]) * t + ux * off


def limb(p0, p1, w0, w1, b=0.0):
    """p0(반폭 w0) → p1(반폭 w1) 팔다리. 양 끝은 둥글고 옆선은 b만큼 부푼다"""
    ux, uy = unit(p0, p1)
    nx, ny = -uy, ux
    a0, a1 = (p0[0] + nx * w0, p0[1] + ny * w0), (p1[0] + nx * w1, p1[1] + ny * w1)
    c0, c1 = (p0[0] - nx * w0, p0[1] - ny * w0), (p1[0] - nx * w1, p1[1] - ny * w1)
    ma = ((a0[0] + a1[0]) / 2 + nx * b, (a0[1] + a1[1]) / 2 + ny * b)
    mc = ((c0[0] + c1[0]) / 2 - nx * b, (c0[1] + c1[1]) / 2 - ny * b)
    return (f"M{pt(a0)}Q{pt(ma)} {pt(a1)}A{w1:.1f} {w1:.1f} 0 0 0 {pt(c1)}"
            f"Q{pt(mc)} {pt(c0)}A{w0:.1f} {w0:.1f} 0 0 0 {pt(a0)}Z")


def catmull(pts, n=14):
    """점을 지나는 곡선을 촘촘한 점으로"""
    P = [pts[0]] + list(pts) + [pts[-1]]
    out = []
    for i in range(1, len(P) - 2):
        p0, p1, p2, p3 = P[i - 1], P[i], P[i + 1], P[i + 2]
        for s in range(n):
            t = s / n
            out.append(tuple(0.5 * (2 * p1[j] + (-p0[j] + p2[j]) * t + (2 * p0[j] - 5 * p1[j] + 4 * p2[j] - p3[j]) * t * t
                                    + (-p0[j] + 3 * p1[j] - 3 * p2[j] + p3[j]) * t ** 3) for j in (0, 1)))
    out.append(pts[-1])
    return out


def ribbon(pts, w, head=0.08, tail=0.25):
    """점을 지나는 띠. 폭 w, 앞·뒤 끝은 가늘어진다"""
    q = catmull(pts)
    n = len(q)
    L, R = [], []
    for i, p in enumerate(q):
        a, b = q[max(i - 1, 0)], q[min(i + 1, n - 1)]
        ux, uy = unit(a, b)
        t = i / (n - 1)
        ww = w * min(1, t / head) * min(1, (1 - t) / tail) * (0.6 + 0.4 * math.sin(math.pi * t))
        L.append((p[0] - uy * ww, p[1] + ux * ww))
        R.append((p[0] + uy * ww, p[1] - ux * ww))
    return poly(L + R[::-1])


# ── 글자 ─────────────────────────────────────────────────────────────
# 글자는 Cinzel 윤곽(path)으로 넣어 폰트 없이도 어디서나 같게 보인다. fontTools나 폰트를 못 구하면 시스템 세리프 <text>로 그린다

def cinzel(weight):
    f = FONTS / f"Cinzel-{weight}.ttf"
    if not f.exists():
        try:
            req = urllib.request.Request(CINZEL, headers={"User-Agent": "Mozilla/4.0"})  # 옛 UA에는 TTF 주소를 준다
            css = urllib.request.urlopen(req, timeout=20).read().decode()
            url = re.search(rf"font-weight: {weight};\s*src: url\((\S+?\.ttf)\)", css).group(1)
            FONTS.mkdir(parents=True, exist_ok=True)
            f.write_bytes(urllib.request.urlopen(url, timeout=30).read())
        except Exception as e:
            print(f"Cinzel {weight}을 못 받았다({e}). 시스템 세리프로 그린다")
            return None
    return f


_fonts = {}


def outline(text, size, weight, spacing, anchor):
    """글자 → (기준선이 y=0인 path d, 대문자 높이). 못 하면 None"""
    try:
        from fontTools.pens.svgPathPen import SVGPathPen
        from fontTools.pens.transformPen import TransformPen
        from fontTools.ttLib import TTFont
    except ImportError:
        return None
    fp = cinzel(weight)
    if fp is None:
        return None
    f = _fonts.setdefault(fp, TTFont(fp))
    gs, cmap, sc = f.getGlyphSet(), f.getBestCmap(), size / f["head"].unitsPerEm
    if any(ord(ch) not in cmap for ch in text):
        return None
    names = [cmap[ord(ch)] for ch in text]
    total = sum(gs[n].width * sc for n in names) + spacing * (len(text) - 1)
    x = {"start": 0, "middle": -total / 2, "end": -total}[anchor]
    d = ""
    for n in names:
        pen = SVGPathPen(gs, ntos=lambda v: f"{v:.2f}")
        gs[n].draw(TransformPen(pen, (sc, 0, 0, -sc, x, 0)))
        d += pen.getCommands()
        x += gs[n].width * sc + spacing
    return d, f["OS/2"].sCapHeight * sc


def label(text, x, y, size, fill, weight=700, spacing=0.0, anchor="start", rot=0.0, central=False, op=None):
    o = outline(text, size, weight, spacing, anchor)
    opa = f' opacity="{op}"' if op is not None else ""
    if o is None:
        base = ' dominant-baseline="central"' if central else ""
        return (f'<text x="{x:.1f}" y="{y:.1f}" transform="rotate({rot:.1f} {x:.1f} {y:.1f})" text-anchor="{anchor}"{base} '
                f'font-family="{FONT}" font-weight="{weight}" font-size="{size}" letter-spacing="{spacing}" fill="{fill}"{opa}>{text}</text>')
    d, cap = o
    return f'<path d="{d}" fill="{fill}" transform="translate({x:.1f} {y:.1f}) rotate({rot:.1f}) translate(0 {cap / 2 if central else 0:.1f})"{opa}/>'


# ── SVG 조각 ─────────────────────────────────────────────────────────

def lin(i, stops, x1=0, y1=0, x2=0, y2=1, user=False):
    u = ' gradientUnits="userSpaceOnUse"' if user else ""
    st = "".join(f'<stop offset="{o}" stop-color="{c}"' + (f' stop-opacity="{a}"' if a is not None else "") + "/>"
                 for o, c, *rest in stops for a in [rest[0] if rest else None])
    return f'<linearGradient id="{i}" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}"{u}>{st}</linearGradient>'


def rad(i, stops, cx, cy, r):
    st = "".join(f'<stop offset="{o}" stop-color="{c}"' + (f' stop-opacity="{a}"' if a is not None else "") + "/>"
                 for o, c, *rest in stops for a in [rest[0] if rest else None])
    return f'<radialGradient id="{i}" cx="{cx}" cy="{cy}" r="{r}" gradientUnits="userSpaceOnUse">{st}</radialGradient>'


def path(d, fill="none", stroke=None, sw=1.0, op=None, extra=""):
    s = f'<path d="{d}" fill="{fill}"'
    if stroke:
        s += f' stroke="{stroke}" stroke-width="{sw}" stroke-linejoin="round" stroke-linecap="round"'
    if op is not None:
        s += f' opacity="{op}"'
    return s + extra + "/>"


_cid = [0]


def cel(d, fill, shades=(), lw=2.0, line=None, inner=""):
    """채움 → 그 안에 잘린 음영·빛 → 외곽선(셀 셰이딩)"""
    _cid[0] += 1
    c = f"k{_cid[0]}"
    s = f'<clipPath id="{c}"><path d="{d}"/></clipPath>' + path(d, fill)
    body = "".join(path(sd, sf, op=so) for sd, sf, so in shades) + inner
    if body:
        s += f'<g clip-path="url(#{c})">{body}</g>'
    if lw:
        s += path(d, stroke=line or K["ink"], sw=lw)
    return s


def tf(c, rot=0.0, sy=1.0):
    return f'translate({c[0]:.1f} {c[1]:.1f}) rotate({rot:.1f}) scale(1 {sy:.3f})'


def defs():
    d = [
        lin("gGold", [(0, K["gold5"]), (.3, K["gold3"]), (.7, K["gold2"]), (1, K["gold1"])]),
        lin("gGoldS", [(0, K["gold3"]), (.6, K["gold2"]), (1, K["gold0"])]),
        lin("gGoldX", [(0, K["gold4"]), (.45, K["gold3"]), (1, K["gold1"])], x2=1, y2=0),
        lin("gNavy", [(0, K["navy3"]), (.45, K["navy2"]), (1, K["navy1"])], x2=1, y2=1),
        lin("gNavyV", [(0, K["navy2"]), (1, K["navy0"])]),
        lin("gLining", [(0, K["lining2"]), (1, K["lining"])]),
        lin("gCollar", [(0, K["lining"]), (.55, K["navy1"]), (1, K["navy0"])]),
        lin("gIvory", [(0, "#fffaf0"), (1, K["ivory_s"])], x2=1, y2=1),
        lin("gBoot", [(0, K["boot_h"]), (.35, K["boot"]), (1, "#06080f")], x2=1, y2=0),
        lin("gBaton", [(0, "#ffffff"), (.6, K["ivory"]), (1, K["ivory_s"])], x2=1, y2=0),
        lin("gSand", [(0, K["gold5"]), (.5, K["gold3"]), (1, K["gold1"])]),
        lin("gGlass", [(0, K["cyan3"], .30), (1, K["cyan2"], .08)], x2=1, y2=0),
        rad("gBg", [(0, "#2c3f68"), (.32, "#1a2646"), (.7, "#0e1529"), (1, "#070a14")], HC[0], HC[1] + 40, 1150),
        rad("gHaloGlow", [(0, K["gold3"], .16), (.6, K["gold2"], .1), (.82, K["gold3"], .14), (1, K["gold2"], 0)], HC[0], HC[1], 470),
        rad("gHeadGlow", [(0, K["gold4"], .62), (.3, K["gold3"], .34), (.65, K["gold2"], .1), (1, K["gold2"], 0)], 960, 290, 260),
        rad("gFloor", [(0, K["cyan2"], .30), (.5, K["cyan1"], .10), (1, K["cyan0"], 0)], 960, 995, 560),
        rad("gVig", [(0, "#000", 0), (.62, "#000", 0), (1, "#03050b", .72)], 960, 520, 1150),
        rad("gDial", [(0, K["cyan4"]), (.45, K["cyan2"]), (1, K["cyan0"])], 0, 0, 1),
        rad("gRimMask", [(0, "#fff"), (.55, "#9a9a9a"), (1, "#202020")], HC[0], HC[1] - 30, 600),
        rad("gSpark", [(0, "#ffffff"), (.25, K["cyan3"], .9), (1, K["cyan2"], 0)], 0, 0, 1),
        rad("gSparkG", [(0, "#ffffff"), (.25, K["gold4"], .9), (1, K["gold3"], 0)], 0, 0, 1),
    ]
    for i, sd in (("fB2", 2), ("fB4", 4), ("fB8", 8)):
        d.append(f'<filter id="{i}" filterUnits="userSpaceOnUse" x="-200" y="-200" width="{W + 400}" height="{H + 400}">'
                 f'<feGaussianBlur stdDeviation="{sd}"/></filter>')
    # 역광 테두리: 알파를 깎아 남은 가장자리 띠를 금빛으로. 아래로 밀어 위쪽 가장자리가 더 두껍다(광륜이 등 뒤 위에 있다).
    # 띠는 외곽선(약 1px) 안쪽에서 시작하고 흐림도 그 안으로 자른다. 외곽선 위에 얹으면 8K에서 선이 회색으로 떴다
    d.append(f'<filter id="fRim" filterUnits="userSpaceOnUse" x="0" y="0" width="{W}" height="{H}" color-interpolation-filters="sRGB">'
             '<feMorphology in="SourceAlpha" operator="erode" radius="1.1" result="a1"/>'
             '<feMorphology in="SourceAlpha" operator="erode" radius="2.6" result="e"/>'
             '<feOffset in="e" dx="0.4" dy="2" result="e2"/>'
             '<feComposite in="a1" in2="e2" operator="out" result="edge"/>'
             '<feGaussianBlur in="edge" stdDeviation="0.5" result="eb"/>'
             '<feComposite in="eb" in2="a1" operator="in" result="eb2"/>'
             f'<feFlood flood-color="{K["gold4"]}" flood-opacity=".85"/><feComposite in2="eb2" operator="in"/></filter>')
    d.append(f'<mask id="mRim" maskUnits="userSpaceOnUse" x="0" y="0" width="{W}" height="{H}">'
             f'<rect width="{W}" height="{H}" fill="url(#gRimMask)"/></mask>')
    return "<defs>" + "".join(d) + "</defs>"


# ── 부품 ─────────────────────────────────────────────────────────────

def gear_d(c, r, n, rot=0.0, depth=0.17, spokes=5, hub=0.24, windows=True):
    ro, ri = r, r * (1 - depth)
    step = 360 / n
    pts = []
    for i in range(n):
        a = rot + i * step
        for da, rr in ((-0.29, ri), (-0.17, ro), (0.17, ro), (0.29, ri)):
            pts.append(pol(c, rr, a + da * step))
    d = poly(pts)
    if windows:
        r1, r2 = r * (hub + 0.1), ri - r * 0.15
        sw = 360 / spokes
        for k in range(spokes):
            d += sector(c, r1, r2, rot + k * sw + sw * 0.15, rot + (k + 1) * sw - sw * 0.15)
    return d + circ(c, r * hub * 0.42)


def gear(c, r, n, rot=0.0, fill="url(#gGold)", spokes=5):
    s = path(gear_d(c, r, n, rot, spokes=spokes), fill, K["gold0"], 1.4, extra=' fill-rule="evenodd"')
    s += path(circ(c, r * 0.71), stroke=K["gold4"], sw=0.8, op=.55)
    s += path(circ(c, r * 0.24), stroke=K["gold0"], sw=1.2)
    s += path(circ(c, r * 0.24 * 0.72), stroke=K["gold5"], sw=0.7, op=.7)
    return s


GLYPHS = [  # 광륜 안쪽 고리의 천문·원소 기호(지름 약 15)
    circ((0, 0), 6) + circ((0, 0), 1.2),
    "M3 -6.5A6.5 6.5 0 1 0 3 6.5A5 5 0 1 1 3 -6.5Z",
    "M0 -6.5L6 5L-6 5Z",
    "M0 6.5L6 -5L-6 -5Z",
    "M0 -6.5L6 5L-6 5ZM-4.5 1.2L4.5 1.2",
    "M0 6.5L6 -5L-6 -5ZM-4.5 -1.2L4.5 -1.2",
    circ((0, -2.5), 4.5) + "M0 2L0 8M-3 5L3 5",
    circ((-1.5, 1.5), 4.5) + "M1.8 -1.8L6.5 -6.5M2.5 -6.5L6.5 -6.5L6.5 -2.5",
    circ((0, -1), 3.8) + "M0 2.8L0 8M-2.8 5.4L2.8 5.4M-3.5 -8.5A3.5 3 0 0 0 3.5 -8.5",
    "M-2 -7L-2 6M-5 -4L1 -4M-2 1C2 -2 7 2 2 7",
    "M0 -7L1.6 -1.6L7 0L1.6 1.6L0 7L-1.6 1.6L-7 0L-1.6 -1.6Z",
    "M-5 -6.5L5 -6.5L-5 6.5L5 6.5Z",
]
ROMAN = ["XII", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI"]


def background():
    s = [f'<rect width="{W}" height="{H}" fill="url(#gBg)"/>']
    for r, op, dash in ((470, .2, "2 9"), (528, .13, ""), (600, .1, "1 13"), (720, .07, "")):
        s.append(path(circ(HC, r), stroke=K["navy4"], sw=1.2, op=op, extra=f' stroke-dasharray="{dash}"' if dash else ""))
    for a in range(0, 360, 15):  # 아주 옅은 방사선
        s.append(path(f"M{pt(pol(HC, 470, a))}L{pt(pol(HC, 720, a))}", stroke=K["navy4"], sw=0.8, op=.05))
    s.append('<ellipse cx="960" cy="996" rx="560" ry="86" fill="url(#gFloor)"/>')
    return "".join(s)


def halo():
    s = [path(circ(HC, 470), "url(#gHaloGlow)"), path(circ((960, 290), 260), "url(#gHeadGlow)")]
    gears = [((620, 430), 58, 16, 8), ((1246, 596), 48, 14, -6), ((1226, 206), 34, 11, 12),
             ((772, 702), 40, 12, 3), ((566, 515), 24, 9, 20), ((1297, 668), 22, 8, 0)]
    gg = "".join(gear(c, r, n, rot) for c, r, n, rot in gears)
    s.append(f'<g filter="url(#fB8)" opacity=".5">{gg}</g>{gg}')
    for (c, r, n, rot) in gears[:2]:  # 도는 톱니의 잔상 호
        for k, (a0, a1) in enumerate(((20, 110), (200, 290))):
            s.append(path(arc(c, r + 9 + k * 2, a0 + rot, a1 + rot), stroke=K["gold4"], sw=1.2, op=.35))
    band = path(circ(HC, 327) + circ(HC, 292), K["navy1"], op=.86, extra=' fill-rule="evenodd"')
    band += path(circ(HC, 284) + circ(HC, 238), K["navy1"], op=.5, extra=' fill-rule="evenodd"')
    s.append(band)
    g = []
    for r, w, op in ((343, 2.4, 1), (333, 1.1, .8), (327, 2.2, 1), (292, 2.2, 1), (286, 1.0, .7), (238, 1.8, 1)):
        g.append(path(circ(HC, r), stroke=K["gold3"], sw=w, op=op))
    for i in range(60):
        a = i * 6
        r0 = 327 if i % 5 == 0 else 333.5
        g.append(path(f"M{pt(pol(HC, r0, a))}L{pt(pol(HC, 342, a))}", stroke=K["gold4"], sw=2.2 if i % 5 == 0 else 1.0))
    for i, t in enumerate(ROMAN):
        x, y = pol(HC, 309.5, i * 30)
        rot = i * 30 + (180 if 3 < i < 9 else 0)  # 아래쪽 숫자는 바로 세운다
        g.append(label(t, x, y, 24, K["gold4"], 700, 1.0, "middle", rot, True))
        g.append(path(circ(pol(HC, 289, i * 30 + 15), 1.6), K["gold4"]))
    for i in range(12):
        a = 15 + 30 * i
        g.append(path(f"M{pt(pol(HC, 240, a))}L{pt(pol(HC, 283, a))}", stroke=K["gold3"], sw=1.1, op=.85))
    ec = (HC[0], HC[1] - 32)  # 황도 고리(중심이 어긋난 고리)
    g.append(path(circ(ec, 176), stroke=K["gold3"], sw=2.4))
    g.append(path(circ(ec, 169), stroke=K["gold3"], sw=0.8, op=.7))
    for i in range(72):
        g.append(path(f"M{pt(pol(ec, 169, i * 5))}L{pt(pol(ec, 176, i * 5))}", stroke=K["gold4"], sw=0.9 if i % 6 else 1.8))
    g.append(path(circ(HC, 207), stroke=K["gold3"], sw=1.2, op=.6, extra=' stroke-dasharray="5 7"'))
    g.append(clock_hands())
    gold = "".join(g)
    cy = []
    for i, gd in enumerate(GLYPHS):
        x, y = pol(HC, 261, i * 30)
        cy.append(f'<path d="{gd}" transform="translate({x:.1f} {y:.1f}) rotate({i * 30}) scale(1.15)" fill="none" '
                  f'stroke="{K["cyan3"]}" stroke-width="1.4" stroke-linejoin="round"/>')
    cyan = "".join(cy)
    s.append(f'<g filter="url(#fB4)" opacity=".9">{gold}</g>{gold}')
    s.append(f'<g filter="url(#fB4)">{cyan}</g><g filter="url(#fB2)">{cyan}</g>{cyan}')
    return "".join(s)


def clock_hands():
    s = []
    a = 325  # 시침: 끝에 해 원반
    v = (math.cos(math.radians(a)), math.sin(math.radians(a)))
    b, m, t = pol(HC, 120, a), pol(HC, 150, a), pol(HC, 190, a)
    s.append(path(poly([b, (m[0] + v[0] * 8, m[1] + v[1] * 8), t, (m[0] - v[0] * 8, m[1] - v[1] * 8)]), "url(#gGold)", K["gold0"], 1.2))
    sc = pol(HC, 207, a)
    for i in range(16):
        r1 = 25 if i % 2 == 0 else 20
        s.append(path(poly([pol(sc, 15, i * 22.5 - 5), pol(sc, r1, i * 22.5), pol(sc, 15, i * 22.5 + 5)]), K["gold3"], K["gold0"], 0.8))
    s.append(path(circ(sc, 15), "url(#gGold)", K["gold0"], 1.4))
    s.append(path(circ(sc, 10), stroke=K["gold1"], sw=1.1))
    s.append(path(circ(sc, 4), K["gold5"]))
    a = 38  # 분침: 끝에 화살촉
    v = (math.cos(math.radians(a)), math.sin(math.radians(a)))
    b, m, t = pol(HC, 120, a), pol(HC, 175, a), pol(HC, 288, a)
    s.append(path(poly([b, (m[0] + v[0] * 6, m[1] + v[1] * 6), t, (m[0] - v[0] * 6, m[1] - v[1] * 6)]), "url(#gGold)", K["gold0"], 1.2))
    m2, t2 = pol(HC, 296, a), pol(HC, 318, a)
    s.append(path(poly([pol(HC, 284, a), (m2[0] + v[0] * 9, m2[1] + v[1] * 9), t2, (m2[0] - v[0] * 9, m2[1] - v[1] * 9)]), "url(#gGold)", K["gold0"], 1.2))
    s.append(path(circ(pol(HC, 268, a), 6), "url(#gGold)", K["gold0"], 1.2))
    return "".join(s)


def dial(r, col, hands=(305, 60), detail=2, glow=K["cyan2"]):
    """원점에 놓인 홀로그램 시계 문자판(국소 좌표). detail 0~2"""
    ns = ' vector-effect="non-scaling-stroke"'
    s = [f'<circle r="{r}" fill="{glow}" opacity=".07"/>',
         f'<circle r="{r}" fill="none" stroke="{col}" stroke-width="2"{ns}/>',
         f'<circle r="{r * .86}" fill="none" stroke="{col}" stroke-width="1"{ns} opacity=".8"/>']
    for i in range(60 if detail else 12):
        a = i * (6 if detail else 30)
        big = detail == 0 or i % 5 == 0
        r0 = r * (.74 if big else .8)
        s.append(f'<path d="M{pt(pol((0, 0), r0, a))}L{pt(pol((0, 0), r * .86, a))}" stroke="{col}" '
                 f'stroke-width="{1.6 if big else .8}"{ns}/>')
    if detail >= 2:
        s.append(f'<circle r="{r * .52}" fill="none" stroke="{col}" stroke-width=".8" stroke-dasharray="3 4"{ns} opacity=".8"/>')
        s.append(f'<path d="{arc((0, 0), r * 1.12, 200, 290)}" fill="none" stroke="{col}" stroke-width="1.6"{ns} opacity=".8"/>')
        s.append(f'<path d="{arc((0, 0), r * 1.12, 20, 70)}" fill="none" stroke="{col}" stroke-width="1.6"{ns} opacity=".8"/>')
        s.append(f'<path d="{arc((0, 0), r * 1.2, 100, 125)}" fill="none" stroke="{col}" stroke-width="3"{ns} opacity=".6"/>')
    h, m = hands
    s.append(f'<path d="M0 0L{pt(pol((0, 0), r * .5, h))}" stroke="{col}" stroke-width="2.4" stroke-linecap="round"{ns}/>')
    s.append(f'<path d="M0 0L{pt(pol((0, 0), r * .74, m))}" stroke="{col}" stroke-width="1.5" stroke-linecap="round"{ns}/>')
    s.append(f'<circle r="{max(1.5, r * .05)}" fill="{col}"/>')
    return "".join(s)


HOLO = [  # (중심, 반지름, 색, 세로 눌림, 기울기, 바늘, 세부)
    ((540, 612), 74, "cyan3", .42, -16, (300, 75), 2),
    ((1376, 318), 56, "gold4", .62, 22, (20, 150), 2),
    ((1392, 772), 86, "cyan3", .36, -7, (230, 15), 2),
    ((556, 868), 40, "gold4", .5, 14, (120, 0), 1),
    ((712, 92), 28, "cyan3", .78, 4, (330, 200), 0),
    ((1296, 914), 34, "cyan3", .45, 10, (60, 280), 1),
    ((450, 410), 44, "gold4", .66, -24, (180, 300), 1),
]


def holo():
    g = "".join(f'<g transform="{tf(c, rot, sy)}">{dial(r, K[col], hands, det, K["cyan2"] if col.startswith("cyan") else K["gold3"])}</g>'
                for c, r, col, sy, rot, hands, det in HOLO)
    return f'<g filter="url(#fB4)" opacity=".9">{g}</g><g opacity=".92">{g}</g>'


def ripples():
    s = []
    c = (960, 994)
    for k, rx in enumerate((92, 150, 220, 300, 390, 488, 590)):
        op = .75 * (1 - k / 8)
        dash = ' stroke-dasharray="14 9"' if k % 2 else ""
        s.append(f'<ellipse cx="{c[0]}" cy="{c[1]}" rx="{rx}" ry="{rx * .115:.1f}" fill="none" stroke="{K["cyan2"]}" '
                 f'stroke-width="{2 - k * .17:.2f}" opacity="{op:.2f}"{dash}/>')
    for cc, rs in (((1206, 372), (66, 96, 130)), ((652, 125), (20, 36, 56))):  # 공중 물결(모래시계·지휘봉 끝)
        for k, r in enumerate(rs):
            s.append(path(circ(cc, r), stroke=K["cyan3"], sw=1.4 - k * .3, op=.5 - k * .13,
                          extra=' stroke-dasharray="22 10 4 10"'))
    g = "".join(s)
    return f'<g filter="url(#fB4)">{g}</g>{g}'


RIBBONS = [  # (지나는 점, 폭, 색)
    ([(652, 125), (594, 150), (546, 212), (520, 300), (524, 392), (552, 474), (604, 542), (664, 590)], 7, "cyan2"),
    ([(656, 121), (722, 70), (826, 40), (960, 31), (1098, 44), (1208, 94), (1276, 168)], 3.5, "gold3"),
    ([(1242, 410), (1302, 470), (1332, 560), (1312, 660), (1252, 742), (1172, 802)], 6, "cyan2"),
]


def ribbons():
    g = "".join(path(ribbon(p, w), K[col], op=.85) for p, w, col in RIBBONS)
    return f'<g filter="url(#fB8)">{g}</g><g opacity=".9">{g}</g>'


def particles():
    rnd = random.Random(7)
    s = []
    n = 0
    while n < 170:
        if rnd.random() < .6:
            p = pol(HC, rnd.uniform(250, 470), rnd.uniform(0, 360))
        else:
            p = (rnd.uniform(380, 1540), rnd.uniform(40, 1040))
        r = math.dist(p, HC)
        if 284 < r < 336 or (895 < p[0] < 1025 and 200 < p[1] < 350):  # 숫자 띠·얼굴 위에는 두지 않는다
            continue
        n += 1
        col = K["gold4"] if rnd.random() < .5 else K["cyan3"]
        s.append(path(circ(p, rnd.uniform(.7, 2.4)), col, op=round(rnd.uniform(.35, 1), 2)))
    g = "".join(s)
    sp = []
    for p, r, gid in (((652, 125), 26, "gSpark"), ((1206, 372), 15, "gSparkG"), ((960, 388), 14, "gSpark"),
                      ((606, 300), 10, "gSpark"), ((1300, 470), 9, "gSparkG"), ((842, 262), 12, "gSparkG"),
                      ((1145, 194), 10, "gSparkG"), ((700, 880), 8, "gSpark")):
        star = poly([pol(p, r if i % 2 == 0 else r * .14, i * 45) for i in range(8)])
        sp.append(f'<g transform="translate({p[0]} {p[1]}) scale({r:.1f})"><circle r=".55" fill="url(#{gid})"/></g>')
        sp.append(path(star, "#ffffff", op=.95))
    return f'<g filter="url(#fB2)">{g}</g>{g}' + "".join(sp)


# ── 인물 ─────────────────────────────────────────────────────────────

def back_hair():
    s = []
    hair = [(926, 312, 1), (920, 290), (918, 264), (923, 240), (938, 223), (960, 215), (982, 218), (998, 230),
                 (1006, 250), (1007, 270), (1013, 282), (1022, 294, 1), (1010, 294), (1004, 299), (995, 312, 1)]
    locks = "".join(path(smooth(l, False), stroke=K["hair_d"], sw=1.2, op=.8) for l in (
        [(1000, 246), (1006, 266), (1016, 288)], [(924, 262), (922, 282), (926, 304)], [(992, 262), (998, 284), (994, 304)]))
    s.append(cel(smooth(hair), K["hair_s"], [(smooth([(992, 222), (1012, 250), (1030, 300), (984, 318)]), K["hair_d"], .55)], 1.6, inner=locks))
    return "".join(s)


def face():
    s = []
    ear = [(931, 268, 1), (924, 266), (921, 277), (924, 288), (931, 294, 1)]
    s.append(cel(smooth(ear), K["skin"], [(smooth([(925, 270), (929, 282), (926, 292)], False), K["skin_s"], 1)], 1.4))
    s.append(cel(smooth(mirror(ear)), K["skin_s"], (), 1.4))
    neck = smooth([(946, 298, 1), (946, 352, 1), (974, 352, 1), (974, 298, 1)])
    s.append(cel(neck, K["skin"], [(smooth([(938, 294), (982, 294), (982, 318), (968, 326), (952, 326), (938, 318)]), K["skin_s"], 1),
                                   (smooth([(966, 300), (980, 300), (980, 356), (966, 356)]), K["skin_s"], .8)], 1.6))
    fc = smooth([(930, 252), (930, 272), (933, 290), (940, 305), (950, 318), (960, 324), (970, 318), (980, 305),
                 (987, 290), (990, 272), (990, 252), (982, 236), (960, 230), (938, 236)])
    shade = smooth([(978, 234), (983, 252), (983, 268), (980, 284), (975, 300), (967, 314), (958, 327), (1004, 340), (1006, 228)])
    s.append(cel(fc, K["skin"], [(shade, K["skin_s"], .72),
                                 (smooth([(937, 271), (947, 268), (957, 271), (947, 275)]), K["skin_s"], .45),
                                 (smooth([(963, 271), (973, 268), (983, 271), (973, 275)]), K["skin_s"], .55),
                                 (smooth([(934, 258), (942, 250), (950, 254), (940, 262)]), K["skin_h"], .6)], 1.8))
    for eye, iris in (([(939, 277, 1), (944, 273), (951, 273), (955.5, 276.5, 1), (951, 279), (944, 279.5)], (947.6, 276.2)),
                      (mirror([(939, 277, 1), (944, 273), (951, 273), (955.5, 276.5, 1), (951, 279), (944, 279.5)]), (972.4, 276.2))):
        s.append(cel(smooth(eye), "#eef4f7", [(circ(iris, 3.1), K["cyan2"], 1), (circ(iris, 1.25), K["ink"], 1),
                                             (circ((iris[0] - .9, iris[1] - 1), .7), "#ffffff", 1)], 0))
    s.append(path(smooth([(938.5, 277.5), (943, 272.2), (951, 272.2), (956.3, 276)], False), stroke=K["ink"], sw=1.9))
    s.append(path(smooth([(981.5, 277.5), (977, 272.2), (969, 272.2), (963.7, 276)], False), stroke=K["ink"], sw=1.9))
    s.append(path(smooth([(941, 279.6), (947, 280.4), (953, 279)], False), stroke=K["skin_d"], sw=.8, op=.8))
    s.append(path(smooth([(979, 279.6), (973, 280.4), (967, 279)], False), stroke=K["skin_d"], sw=.8, op=.8))
    brow = [(936, 269.5, 1), (941, 265), (949, 263.6), (956, 265.6, 1), (955, 268.2), (948, 267.1), (941, 268.6), (937, 271.4, 1)]
    s.append(path(smooth(brow), K["hair_d"], K["ink"], .6))
    s.append(path(smooth([(p[0], p[1] - (1.6 if p[0] < 942 else .6)) + tuple(p[2:]) for p in mirror(brow)]), K["hair_d"], K["ink"], .6))
    s.append(path(smooth([(961, 279, 1), (963.5, 287), (966, 295), (964, 298.5, 1), (961.5, 291)]), K["skin_s"]))
    s.append(path(smooth([(958.6, 281), (958.2, 290)], False), stroke=K["skin_h"], sw=1.1))
    s.append(path(smooth([(954.5, 296), (957, 299), (960, 299.6), (963, 299), (965.5, 296.5)], False), stroke=K["skin_d"], sw=1.2))
    s.append(path(smooth([(953, 309.5), (957, 310.6), (963, 310.4), (967.5, 309)], False), stroke=K["skin_d"], sw=1.3))
    s.append(path(smooth([(955, 312.3), (960, 313.4), (965, 312.3)], False), stroke=K["skin_h"], sw=.9, op=.7))
    stache = [(960, 302.5, 1), (953, 301.2), (946, 302.8), (941, 306.8, 1), (946, 305.2), (952, 305.6), (960, 305.2, 1),
              (968, 305.6), (974, 305.2), (979, 306.8, 1), (974, 302.8), (967, 301.2)]
    s.append(path(smooth(stache), K["hair"], K["hair_d"], .8))
    goatee = [(953.5, 313, 1), (957, 315.2), (963, 315.2), (966.5, 313, 1), (964.5, 320), (961, 328), (960, 335, 1), (959, 328), (955.5, 320)]
    s.append(cel(smooth(goatee), K["hair"], [(smooth([(961, 312), (970, 312), (962, 336)]), K["hair_s"], 1)], .9, K["hair_d"]))
    front = [(929, 266, 1), (927, 248), (934, 232), (950, 222), (970, 220), (987, 228), (995, 243), (993, 263, 1),
             (988, 251), (980, 243.5), (970, 241.5), (963.5, 243), (960, 247, 1), (956, 243), (948, 241), (940, 245), (934, 254)]
    s.append(cel(smooth(front), K["hair"], [(smooth([(975, 222), (998, 236), (996, 266), (982, 246), (968, 240)]), K["hair_s"], .9),
                                            (smooth([(936, 236), (948, 226), (962, 223), (950, 232), (940, 246)]), "#ffffff", .7)], 1.7))
    for st in ([(941, 244), (946, 233), (958, 226), (972, 225)], [(952, 242), (958, 233.5), (970, 229.5), (984, 232)],
               [(966, 242), (975, 236), (986, 238), (992, 247)], [(934, 252), (933, 240), (940, 230)]):
        s.append(path(smooth(st, False), stroke=K["hair_s"], sw=1.1))
    s.append(cel(smooth([(947, 242, 1), (940, 248), (936, 257), (937, 269, 1), (941, 258), (946, 251), (953, 246, 1)]),
                 K["hair"], (), 1.1, K["hair_d"]))
    # 외알 안경(왼눈 = 화면 오른쪽)과 사슬
    s.append(path(circ((972.4, 276.4), 10.4), K["cyan2"], op=.22))
    s.append(path(arc((972.4, 276.4), 7.5, 290, 350), stroke="#ffffff", sw=1.2, op=.85))
    s.append(path(circ((972.4, 276.4), 10.4), stroke=K["gold0"], sw=3.6))
    s.append(path(circ((972.4, 276.4), 10.4), stroke=K["gold3"], sw=2.2))
    s.append(path(smooth([(982.5, 281), (991, 298), (996, 322), (993, 346)], False), stroke=K["gold3"], sw=1.3,
                  extra=' stroke-dasharray="2.2 1.4"'))
    return "".join(s)


def coat_tails():
    s = []
    L = [(903, 545, 1), (884, 585), (862, 640), (840, 700), (818, 765), (798, 830), (778, 880), (760, 912, 1),
         (790, 902), (822, 893), (856, 888), (884, 882), (900, 874, 1), (906, 800), (916, 700), (930, 610, 1)]
    R = [(1017, 545, 1), (1038, 585), (1062, 640), (1088, 700), (1114, 765), (1140, 830), (1164, 880), (1190, 916, 1),
         (1156, 906), (1120, 896), (1084, 889), (1052, 883), (1026, 874, 1), (1016, 800), (1006, 700), (990, 610, 1)]
    for pts, sign in ((L, -1), (R, 1)):
        tip = pts[7]
        lining = smooth([tip, pts[8], pts[9], pts[10], pts[11], pts[12], (pts[12][0] - sign * 4, pts[12][1] - 14),
                         (pts[11][0], pts[11][1] - 13), (pts[10][0], pts[10][1] - 12), (pts[9][0], pts[9][1] - 9)])
        inner = smooth([pts[12], pts[13], pts[14], pts[15], (pts[15][0] + sign * 30, 610), (pts[13][0] + sign * 22, 800),
                        (pts[12][0] + sign * 18, 880)])
        folds = "".join(path(smooth(f, False), stroke=K["navy0"], sw=3, op=.55) for f in (
            [(pts[1][0] - sign * 6, 600), (pts[3][0] - sign * 4, 700), (pts[4][0] + sign * 18, 790), (pts[6][0] + sign * 40, 880)],
            [(pts[2][0] - sign * 24, 640), (pts[4][0] - sign * 26, 760), (pts[5][0] - sign * 4, 860)]))
        lights = path(smooth([(pts[1][0] + sign * 4, 595), (pts[3][0] + sign * 8, 700), (pts[4][0] + sign * 6, 775)], False),
                      stroke=K["navy3"], sw=4, op=.6)
        s.append(cel(smooth(pts), "url(#gNavy)", [(lining, "url(#gLining)", 1), (inner, K["navy0"], .65)], 2.0, inner=folds + lights))
        s.append(path(smooth(pts[:8], False), stroke=K["gold3"], sw=2.4))
        s.append(path(smooth(pts[7:13], False), stroke=K["gold3"], sw=2))
        mc = (pts[5][0] + sign * 46, 806)  # 꼬리 자수: 작은 시계
        s.append(f'<g transform="{tf(mc, sign * -14, .78)}" opacity=".9">{dial(19, K["gold3"], (330, 120), 0, K["gold3"])}</g>')
    return "".join(s)


BOOTS = {  # 무릎부터 발끝까지 한 윤곽(이음선이 없게). 앞을 보는 발(화면 왼쪽) / 바깥으로 벌린 발(화면 오른쪽)
    "L": dict(out=[(884, 778, 1), (880, 828), (884, 880), (888, 922), (889, 944), (881, 962), (874, 978), (874, 990),
                   (888, 997), (906, 997), (920, 991), (922, 978), (918, 962), (917, 944), (920, 900), (927, 840), (928, 780, 1)],
              hl=[(890, 800), (888, 850), (893, 905), (893, 940)], dk=[(916, 790), (922, 840), (914, 900), (912, 950), (902, 960)],
              toe=[(874, 979, 1), (874, 990), (888, 997), (906, 997), (920, 991), (921, 981, 1), (906, 986), (888, 986)]),
    "R": dict(out=[(1008, 774, 1), (1009, 830), (1028, 890), (1040, 932), (1042, 958), (1044, 980), (1056, 992),
                   (1080, 997), (1100, 994), (1110, 985), (1104, 974), (1088, 962), (1076, 948), (1074, 930), (1067, 878),
                   (1058, 818), (1052, 768, 1)],
              hl=[(1015, 790), (1018, 840), (1034, 892), (1046, 935)], dk=[(1048, 780), (1056, 830), (1062, 880), (1066, 930), (1058, 950)],
              toe=[(1086, 996, 1), (1100, 994), (1110, 985), (1104, 974), (1096, 968, 1), (1100, 980), (1092, 990)]),
}


def boot(side):
    b = BOOTS[side]
    dk = smooth(b["dk"] + [(b["dk"][-1][0] + 30, b["dk"][-1][1]), (b["dk"][0][0] + 30, b["dk"][0][1])])
    sole = smooth([(850, 990), (1130, 990), (1130, 1010), (850, 1010)])
    s = cel(smooth(b["out"]), "url(#gBoot)", [(dk, "#000", .45), (sole, "#000", .5)], 2,
            inner=path(smooth(b["hl"], False), stroke=K["boot_h"], sw=3.4, op=.9))
    return s + cel(smooth(b["toe"]), "url(#gGold)", [], 1.2)


LEG = {  # 엉덩이·무릎·발목. 체중은 오른다리(화면 왼쪽)에 싣고 왼발(화면 오른쪽)은 바깥으로 벌린다
    "L": ((926, 586), (906, 780), (902, 946)),
    "R": ((996, 586), (1030, 772), (1060, 940)),
}


def legs():
    s = []
    crotch = smooth([(904, 556, 1), (1016, 556, 1), (1012, 600), (982, 622), (960, 630, 1), (938, 622), (908, 600)])
    s.append(cel(crotch, K["trouser"], [(smooth([(960, 560), (1030, 560), (1030, 640), (960, 640)]), K["navy0"], .45)], 0))
    for side in ("R", "L"):
        # along()의 off는 위→아래로 내려가는 팔다리에서 +가 화면 왼쪽이다. 빛은 화면 왼쪽에서 온다
        hp, kn, an = LEG[side]
        thigh = limb(hp, kn, 31, 20, 5)
        if side == "L":
            sh = [(limb(along(hp, kn, 0, -17), along(hp, kn, 1, -10), 14, 9), K["navy0"], .7),
                  (limb(along(hp, kn, 0, 16), along(hp, kn, 1, 10), 11, 6), K["navy3"], .5)]
        else:
            sh = [(limb(along(hp, kn, 0, 18), along(hp, kn, .8, 8), 14, 6), K["navy0"], .65),
                  (limb(along(hp, kn, 0, -17), along(hp, kn, 1, -10), 13, 8), K["navy0"], .55)]
        s.append(cel(thigh, K["trouser"] if side == "L" else "url(#gNavyV)", sh, 2))
        outer = 1 if side == "L" else -1  # 바깥 솔기(금줄) 쪽
        s.append(path(f"M{pt(along(hp, kn, .06, 29 * outer))}Q{pt(along(hp, kn, .5, 31.5 * outer))} {pt(along(hp, kn, .97, 19.5 * outer))}",
                      stroke=K["gold2"] if side == "L" else K["gold1"], sw=2.6))
        s.append(boot(side))
        cuff = smooth([along(kn, an, -.04, 23.5) + (1,), along(kn, an, -.04, -23.5) + (1,),
                       along(kn, an, .05, -23.5) + (1,), along(kn, an, .05, 23.5) + (1,)])
        s.append(cel(cuff, "url(#gGold)", [], 1.4))
    for kc in (along(*LEG["L"][1:], -.02), along(*LEG["R"][1:], -.02)):
        sh = [(kc[0], kc[1] - 23, 1), (kc[0] + 16, kc[1] - 15), (kc[0] + 22, kc[1]), (kc[0] + 15, kc[1] + 16),
              (kc[0], kc[1] + 22, 1), (kc[0] - 15, kc[1] + 16), (kc[0] - 22, kc[1]), (kc[0] - 16, kc[1] - 15)]
        s.append(cel(smooth(sh), "url(#gGold)", [(smooth([(kc[0] + 2, kc[1] - 30), (kc[0] + 30, kc[1] - 10), (kc[0] + 26, kc[1] + 30), (kc[0] + 2, kc[1] + 30)]), K["gold1"], .45)], 1.6))
        s.append(gear(kc, 8.5, 10, 6))
    return "".join(s)


def collar():
    """높이 세운 목깃. 앞에서는 안쪽(안감) 면이 보인다"""
    s = []
    pts = [(917, 362, 1), (911, 342), (908, 320), (910, 300, 1), (923, 305), (935, 313), (943, 322), (948, 334, 1),
              (972, 334, 1), (977, 322), (985, 313), (997, 305), (1010, 300, 1), (1012, 320), (1009, 342), (1003, 362, 1)]
    s.append(cel(smooth(pts), "url(#gCollar)", [(smooth([(988, 296), (1030, 296), (1030, 370), (998, 370)]), K["navy0"], .55)], 1.8))
    s.append(path(smooth([(910, 300), (923, 305), (935, 313), (943, 322), (948, 334)], False), stroke=K["gold3"], sw=2.6))
    s.append(path(smooth([(1010, 300), (997, 305), (985, 313), (977, 322), (972, 334)], False), stroke=K["gold3"], sw=2.6))
    return "".join(s)


def bodice():
    s = []
    vest = smooth([(928, 340, 1), (992, 340, 1), (967, 498, 1), (953, 498, 1)])
    stripes = "".join(path(f"M{x} 330L{x} 500", stroke=K["gold1"], sw=.9, op=.45) for x in range(936, 990, 8))
    s.append(cel(vest, K["vest"], [], 1.4, inner=stripes))
    coat = [(931, 344, 1), (906, 349), (884, 356), (866, 367, 1), (861, 390), (866, 418), (874, 446), (884, 480),
            (892, 512), (897, 540), (900, 561, 1), (930, 567), (960, 577, 1), (990, 567), (1020, 561, 1), (1023, 540),
            (1028, 512), (1036, 480), (1046, 446), (1054, 418), (1059, 390), (1054, 367, 1), (1036, 356), (1014, 349),
            (989, 344, 1), (963, 482, 1), (957, 482, 1)]
    shades = [
        (smooth([(1004, 344), (1064, 344), (1064, 590), (1018, 590), (1024, 540), (1026, 470), (1018, 410)]), K["navy0"], .55),
        (smooth([(957, 486), (946, 458), (930, 430), (912, 404), (902, 412), (924, 444), (944, 474)]), K["navy0"], .5),
        (smooth([(869, 372), (884, 368), (897, 382), (901, 420), (899, 470), (901, 522), (893, 522), (884, 470), (873, 420)]), K["navy3"], .55),
        (smooth([(864, 366), (930, 342), (990, 342), (1056, 366), (1056, 384), (990, 360), (930, 360), (864, 386)]), K["navy0"], .45),
    ]
    folds = "".join(path(smooth(f, False), stroke=K["navy0"], sw=2.2, op=.6) for f in
                    ([(906, 548), (912, 522), (915, 496)], [(1014, 548), (1008, 522), (1004, 496)], [(925, 560), (935, 532)]))
    s.append(cel(smooth(coat), "url(#gNavy)", shades, 2.1, inner=folds))
    s.append(path(smooth([(900, 561), (930, 567), (960, 577)], False), stroke=K["gold3"], sw=2.6))  # 앞자락 끝 금선. 그늘 쪽은 한 단계 어둡게
    s.append(path(smooth([(960, 577), (990, 567), (1020, 561)], False), stroke=K["gold2"], sw=2.6))
    s.append(path(smooth([(963, 482), (965, 530), (968, 576)], False), stroke=K["ink"], sw=1.4))
    s.append(path(smooth([(966, 482), (968, 530), (971, 574)], False), stroke=K["gold3"], sw=1.4))
    lap = [(931, 344, 1), (957, 482, 1), (943, 452), (926, 422), (908, 398, 1), (918, 388, 1), (906, 372, 1), (919, 356)]
    for pts, fill in ((lap, K["navy3"]), (mirror(lap), K["navy2"])):
        s.append(cel(smooth(pts), fill, [], 1.8))
        s.append(path(smooth(pts[1:5], False), stroke=K["gold3"], sw=2.2))
        s.append(path(smooth(pts[5:] + [pts[0]], False), stroke=K["gold3"], sw=2.2))
    for x in (912, 1008):  # 앞자락 금실 자수
        s.append(scroll((x, 466), 1) + scroll((x, 466), -1) + path(circ((x, 468), 1.8), K["gold4"]))
    for b in ((940, 497), (980, 497), (943, 522), (977, 522)):
        s.append(path(circ(b, 4.4), "url(#gGold)", K["ink"], 1.1) + path(circ((b[0] - 1.3, b[1] - 1.3), 1.3), K["gold5"]))
    return "".join(s)


def scroll(c, sgn):
    """금실 덩굴 자수 반쪽(sgn = 좌우). 두 번 겹쳐 좌우 대칭 꽃무늬를 만든다"""
    x, y = c
    d = (f"M{x:.1f} {y + 10:.1f}C{x + 2 * sgn:.1f} {y + 2:.1f} {x + 9 * sgn:.1f} {y - 2:.1f} {x + 11 * sgn:.1f} {y - 8:.1f}"
         f"C{x + 12 * sgn:.1f} {y - 13:.1f} {x + 6 * sgn:.1f} {y - 14:.1f} {x + 5 * sgn:.1f} {y - 10:.1f}"
         f"M{x:.1f} {y - 2:.1f}C{x + 1 * sgn:.1f} {y - 9:.1f} {x + 2 * sgn:.1f} {y - 13:.1f} {x:.1f} {y - 17:.1f}")
    return path(d, stroke=K["gold3"], sw=1.3, op=.9)


def belt():
    s = []
    bt = [(896, 533, 1), (930, 539), (960, 541), (990, 539), (1024, 533, 1), (1025, 553, 1), (990, 559), (960, 561), (930, 559), (895, 553, 1)]
    st = path(smooth([(898, 537), (930, 543), (960, 545), (990, 543), (1022, 537)], False), stroke=K["gold2"], sw=.9, extra=' stroke-dasharray="3 3"')
    st += path(smooth([(898, 549), (930, 555), (960, 557), (990, 555), (1022, 549)], False), stroke=K["gold2"], sw=.9, extra=' stroke-dasharray="3 3"')
    s.append(cel(smooth(bt), K["leather"], [(smooth([(990, 520), (1040, 520), (1040, 570), (990, 570)]), "#000", .35)], 1.6, inner=st))
    s.append(gear((960, 550), 13.5, 12, 4, spokes=4))
    s.append(path(circ((960, 550), 4), K["cyan2"]) + path(circ((959, 549), 1.5), "#ffffff"))
    s.append(path(smooth([(929, 557), (925, 570), (920, 586)], False), stroke=K["gold3"], sw=1.6, extra=' stroke-dasharray="2.4 1.6"'))
    wc = (918, 597)
    s.append(path(circ((wc[0], wc[1] - 12.5), 2.6), stroke=K["gold3"], sw=1.4))
    s.append(path(circ(wc, 10.5), "url(#gGold)", K["ink"], 1.4))
    s.append(f'<g transform="translate({wc[0]} {wc[1]}) scale(7.5)"><circle r="1" fill="url(#gDial)"/></g>')
    s.append(path(f"M{pt(wc)}L{pt(pol(wc, 5, 300))}M{pt(wc)}L{pt(pol(wc, 6.5, 50))}", stroke=K["ink"], sw=1.1))
    return "".join(s)


def chest():
    s = []
    gorget = [(911, 360, 1), (935, 352), (960, 350), (985, 352), (1009, 360, 1), (1002, 382), (984, 398), (960, 406, 1), (936, 398), (918, 382)]
    s.append(cel(smooth(gorget), "url(#gGold)", [(smooth([(962, 340), (1020, 340), (1020, 412), (962, 412)]), K["gold1"], .38),
                                                (smooth([(915, 362), (960, 354), (1005, 362), (960, 358)]), K["gold5"], .8)], 1.8))
    s.append(path(smooth([(919, 366), (935, 360), (960, 358), (985, 360), (1001, 366), (995, 382), (980, 394), (960, 399), (940, 394), (925, 382)]),
                  stroke=K["gold1"], sw=1.1))
    for r in ((919, 367), (1001, 367), (930, 386), (990, 386)):
        s.append(path(circ(r, 2.2), K["gold5"], K["gold0"], .8))
    knot = [(947, 326, 1), (973, 326, 1), (976, 341, 1), (960, 347), (944, 341, 1)]
    falls = [(950, 343, 1), (944, 352), (938, 364), (935, 377, 1), (946, 375), (954, 369), (960, 361, 1), (966, 369),
             (974, 375), (985, 377, 1), (982, 364), (976, 352), (970, 343, 1)]
    s.append(cel(smooth(falls), "url(#gIvory)", [(smooth([(960, 340), (990, 340), (990, 380), (960, 380)]), K["ivory_s"], .7)], 1.5,
                 inner=path(smooth([(950, 350), (946, 362), (943, 372)], False), stroke=K["ivory_s"], sw=1) +
                 path(smooth([(970, 350), (974, 362), (977, 372)], False), stroke="#9b8f74", sw=1)))
    s.append(cel(smooth(knot), "url(#gIvory)", [(smooth([(962, 322), (980, 322), (980, 350), (962, 350)]), K["ivory_s"], .7)], 1.5))
    s.append(path(circ((960, 344), 3.8), "url(#gGold)", K["ink"], .9) + path(circ((960, 344), 1.9), K["cyan2"]))
    cc = (960, 388)  # 가슴의 태엽 시계
    s.append(path(circ(cc, 15.5), "url(#gGold)", K["ink"], 1.6))
    s.append(f'<g transform="translate({cc[0]} {cc[1]}) scale(11.5)"><circle r="1" fill="url(#gDial)"/></g>')
    for i in range(12):
        s.append(path(f"M{pt(pol(cc, 8.6, i * 30))}L{pt(pol(cc, 11, i * 30))}", stroke=K["navy1"], sw=1 if i % 3 else 1.6))
    s.append(path(f"M{pt(cc)}L{pt(pol(cc, 6, 305))}M{pt(cc)}L{pt(pol(cc, 9, 62))}", stroke=K["navy0"], sw=1.4))
    s.append(path(arc(cc, 9.5, 290, 345), stroke="#ffffff", sw=1.4, op=.8))
    return "".join(s)


def pauldron(c, rot, gearish, sign):
    """어깨 원반. gearish = 톱니 테두리(오른쪽 어깨), 아니면 시계 문자판(왼쪽 어깨)"""
    s = []
    for k, (dx, r, sy) in enumerate(((30, 24, .5), (18, 30, .55))):  # 원반 밑으로 겹친 판 두 장(팔 쪽)
        s.append(f'<g transform="{tf(c, rot, 1)}"><g transform="translate({dx * sign} {6 + k * 3}) scale(1 {sy})">'
                 + path(circ((0, 0), r), "url(#gGoldS)", K["ink"], 1.6, extra=' vector-effect="non-scaling-stroke"')
                 + path(circ((0, 0), r * .8), stroke=K["gold4"], sw=.8, op=.6, extra=' vector-effect="non-scaling-stroke"')
                 + "</g></g>")
    inner = []
    if gearish:
        inner.append(path(gear_d((0, 0), 38, 14, 0, windows=False), "url(#gGold)", K["ink"], 1.8, extra=' vector-effect="non-scaling-stroke"'))
        inner.append(path(circ((0, 0), 27), stroke=K["gold1"], sw=2, extra=' vector-effect="non-scaling-stroke"'))
        inner.append(path(gear_d((0, 0), 17, 10, 10, spokes=6, hub=.3), "url(#gGoldS)", K["gold0"], 1, extra=' fill-rule="evenodd" vector-effect="non-scaling-stroke"'))
        inner.append(path(circ((0, 0), 4.5), K["cyan2"]))
    else:
        inner.append(path(circ((0, 0), 37), "url(#gGold)", K["ink"], 1.8, extra=' vector-effect="non-scaling-stroke"'))
        inner.append(path(circ((0, 0), 31), stroke=K["gold1"], sw=1.4, extra=' vector-effect="non-scaling-stroke"'))
        for i in range(12):
            inner.append(path(f"M{pt(pol((0, 0), 26, i * 30))}L{pt(pol((0, 0), 31, i * 30))}", stroke=K["gold0"],
                              sw=2 if i % 3 == 0 else 1, extra=' vector-effect="non-scaling-stroke"'))
        inner.append('<circle r="1" fill="url(#gDial)" transform="scale(20)"/>')
        inner.append(path(circ((0, 0), 20), stroke=K["gold0"], sw=1.6, extra=' vector-effect="non-scaling-stroke"'))
        inner.append(path(f"M0 0L{pt(pol((0, 0), 11, 320))}M0 0L{pt(pol((0, 0), 16, 75))}", stroke=K["navy0"], sw=2, extra=' vector-effect="non-scaling-stroke"'))
        for i in range(8):
            inner.append(path(circ(pol((0, 0), 34, i * 45 + 22.5), 1.6), K["gold5"]))
    s.append(f'<g transform="{tf(c, rot, .74)}">' + "".join(inner) + "</g>")
    s.append(f'<g transform="{tf(c, rot, .74)}">' + path(arc((0, 0), 35, 300, 380), stroke=K["gold5"], sw=2, op=.8,
                                                       extra=' vector-effect="non-scaling-stroke"') + "</g>")
    return "".join(s)


def arm_raised():
    """오른팔(화면 왼쪽): 지휘봉을 든 팔"""
    s = []
    sh, el, wr = (868, 380), (786, 344), (748, 268)
    s.append(cel(limb(sh, el, 24, 18.5, 3), "url(#gNavy)", [(limb(along(sh, el, 0, -12), along(sh, el, 1, -9), 13, 10), K["navy0"], .55)], 2))
    s.append(cel(limb(el, wr, 18.5, 14, 2), "url(#gNavy)", [(limb(along(el, wr, 0, 9), along(el, wr, 1, 7), 10, 7), K["navy0"], .5)], 2))
    c0, c1 = along(el, wr, .5), along(el, wr, 1.02)
    s.append(cel(limb(c0, c1, 19.5, 24, 1), K["navy3"], [(limb(along(c0, c1, 0, 10), along(c0, c1, 1, 12), 9, 12), K["navy1"], .6)], 1.9))
    for t in (.3, .55, .8):
        s.append(path(circ(along(c0, c1, t, -13 - t * 4), 2.8), "url(#gGold)", K["ink"], .8))
    s.append(path(f"M{pt(along(c0, c1, .05, -19.5))}L{pt(along(c0, c1, .05, 19.5))}", stroke=K["gold3"], sw=2.4))
    s.append(path(f"M{pt(along(c0, c1, 1.0, -24))}L{pt(along(c0, c1, 1.0, 24))}", stroke=K["gold3"], sw=2.6))
    return "".join(s)


def baton_and_glove():
    s = []
    g, tip = (741, 255), (652, 125)
    ux, uy = unit(g, tip)
    butt = (g[0] - ux * 13, g[1] - uy * 13)
    s.append(path(circ(butt, 5.4), "url(#gIvory)", K["ink"], 1.2))
    s.append(path(poly([along(butt, tip, .02, -3.2), along(butt, tip, .02, 3.2), along(butt, tip, 1, .8), along(butt, tip, 1, -.8)]),
                  "url(#gBaton)", K["ink"], 1.1))
    for t in (.16, .2):
        s.append(path(f"M{pt(along(butt, tip, t, -3.3))}L{pt(along(butt, tip, t, 3.3))}", stroke=K["gold3"], sw=2.2))
    ang = math.degrees(math.atan2(268 - 344, 748 - 786))  # 아래팔 방향. 국소 +x = 손끝 쪽, +y = 화면 오른쪽 위
    fist = [(-2, -14, 1), (12, -16), (26, -14), (34, -6), (34, 6), (27, 14), (12, 16), (-2, 15, 1)]
    fingers = "".join(cel(smooth([(x0, 1, 1), (x0 + 7, 0), (x0 + 8, 8), (x0 + 6, 17), (x0, 18, 1), (x0 - 1, 9)]), "url(#gIvory)",
                          [(smooth([(x0 - 2, 10), (x0 + 10, 10), (x0 + 10, 20), (x0 - 2, 20)]), K["ivory_s"], .7)], 1.2)
                      for x0 in (9, 16, 23, 29))
    thumb = cel(smooth([(4, -13, 1), (14, -19), (27, -19), (33, -15), (30, -11), (18, -10), (7, -7, 1)]), "url(#gIvory)",
                [(smooth([(4, -9), (34, -12), (34, -6), (4, -4)]), K["ivory_s"], .6)], 1.3)
    s.append(f'<g transform="translate(748 268) rotate({ang:.1f})">'
             + cel(smooth(fist), "url(#gIvory)", [(smooth([(-4, 4), (36, 4), (36, 18), (-4, 18)]), K["ivory_s"], .65)], 1.7)
             + fingers + thumb
             + path(smooth([(-3, -15), (-3, 15)], False), stroke=K["gold3"], sw=2.4)
             + "</g>")
    return "".join(s)


def arm_down():
    """왼팔(화면 오른쪽): 모래시계를 띄운 팔"""
    s = []
    sh, el, wr = (1052, 380), (1108, 466), (1178, 452)
    s.append(cel(limb(sh, el, 24, 18.5, 3), "url(#gNavy)", [(limb(along(sh, el, 0, -12), along(sh, el, 1, -9), 13, 10), K["navy0"], .6)], 2))
    s.append(cel(limb(el, wr, 18.5, 14, 2), "url(#gNavy)", [(limb(along(el, wr, 0, 9), along(el, wr, 1, 7), 10, 7), K["navy0"], .55)], 2))
    c0, c1 = along(el, wr, .45), along(el, wr, 1.0)
    s.append(cel(limb(c0, c1, 19.5, 24, 1), K["navy3"], [(limb(along(c0, c1, 0, 10), along(c0, c1, 1, 12), 9, 12), K["navy1"], .6)], 1.9))
    for t in (.3, .55, .8):
        s.append(path(circ(along(c0, c1, t, -13 - t * 4), 2.8), "url(#gGold)", K["ink"], .8))
    s.append(path(f"M{pt(along(c0, c1, .03, -19.5))}L{pt(along(c0, c1, .03, 19.5))}", stroke=K["gold3"], sw=2.4))
    s.append(path(f"M{pt(along(c0, c1, 1.0, -24))}L{pt(along(c0, c1, 1.0, 24))}", stroke=K["gold3"], sw=2.6))
    # 태엽 장갑: 손바닥을 위로. 국소 +x = 손끝 쪽, +y = 손등 쪽(아래)
    ang = math.degrees(math.atan2(wr[1] - el[1], wr[0] - el[0]))
    g = []
    g.append(cel(smooth([(-4, -8, 1), (14, -10), (28, -9), (31, 0), (28, 9), (12, 11), (-4, 10, 1)]), "url(#gGold)",
                 [(smooth([(-6, 3), (34, 3), (34, 14), (-6, 14)]), K["gold1"], .55)], 1.6))
    for k, (dy, ln, curl) in enumerate(((5, 24, 7), (0, 26, 9), (-5, 25, 10))):  # 뒤 손가락부터
        f = [(26, dy - 4, 1), (26 + ln * .5, dy - 5), (26 + ln * .85, dy - 5 - curl * .5), (26 + ln, dy - 4 - curl, 1),
             (26 + ln * .92, dy + 1 - curl * .6), (26 + ln * .5, dy + 3), (26, dy + 4, 1)]
        joints = "".join(path(f"M{26 + ln * t:.1f} {dy - 7}L{26 + ln * t:.1f} {dy + 5}", stroke=K["gold0"], sw=1, op=.8) for t in (.38, .72))
        g.append(cel(smooth(f), "url(#gGold)" if k == 2 else "url(#gGoldS)", [], 1.3, inner=joints))
    g.append(cel(smooth([(8, -7, 1), (12, -17), (18, -24), (24, -26, 1), (23, -20), (17, -12), (15, -5, 1)]), "url(#gGold)", [], 1.4))
    g.append(path(circ((10, 4), 3.4), K["cyan2"], K["ink"], .9))
    s.append(f'<g transform="translate({wr[0]} {wr[1]}) rotate({ang:.1f}) scale(1.25)">' + "".join(g) + "</g>")
    return "".join(s)


def hourglass():
    s = []
    c = (1206, 372)
    s.append(f'<ellipse cx="{c[0]}" cy="436" rx="38" ry="8" fill="none" stroke="{K["cyan3"]}" stroke-width="1.6" opacity=".9"/>')
    s.append(f'<ellipse cx="{c[0]}" cy="438" rx="26" ry="5" fill="none" stroke="{K["cyan3"]}" stroke-width="1" opacity=".7"/>')
    glass = [(1186, 331, 1), (1226, 331, 1), (1231, 348), (1224, 362), (1209, 372, 1), (1224, 382), (1231, 397), (1226, 413, 1),
             (1186, 413, 1), (1181, 397), (1188, 382), (1203, 372, 1), (1188, 362), (1181, 348)]
    sand = (path(smooth([(1178, 357), (1194, 352), (1218, 352), (1234, 357), (1234, 374), (1178, 374)]), "url(#gSand)")
            + path(smooth([(1182, 414), (1192, 401), (1201, 393), (1206, 391, 1), (1211, 393), (1220, 401), (1230, 414)]), "url(#gSand)"))
    s.append(path(smooth(glass), K["navy0"], op=.55))
    s.append(cel(smooth(glass), "url(#gGlass)", [], 0, inner=sand))
    for k, y in enumerate((376, 380.5, 384.5, 388)):
        s.append(path(circ((1206 + (k % 2) * 1.2 - .6, y), 1.3 - k * .1), K["gold5"]))
    s.append(path(smooth(glass), stroke=K["cyan3"], sw=1.4))
    s.append(path(smooth([(1189, 336), (1185, 348), (1191, 361)], False), stroke="#ffffff", sw=2, op=.75))
    s.append(path(smooth([(1189, 386), (1185, 398), (1190, 409)], False), stroke="#ffffff", sw=1.6, op=.6))
    for x in (1180, 1232):  # 꼬인 기둥
        s.append(cel(smooth([(x - 3.4, 330, 1), (x + 3.4, 330, 1), (x + 3.4, 414, 1), (x - 3.4, 414, 1)]), "url(#gGoldX)", [], 1.2,
                     inner="".join(path(f"M{x - 4} {y}L{x + 4} {y - 5}", stroke=K["gold1"], sw=1.2) for y in range(334, 418, 7))))
    for y0 in (318, 414):  # 위·아래 받침
        cap = [(1170, y0, 1), (1242, y0, 1), (1238, y0 + 12, 1), (1174, y0 + 12, 1)]
        s.append(cel(smooth(cap), "url(#gGold)", [(smooth([(1206, y0 - 2), (1246, y0 - 2), (1246, y0 + 14), (1206, y0 + 14)]), K["gold1"], .35)], 1.6))
        s.append(path(f"M1174 {y0 + 6}L1238 {y0 + 6}", stroke=K["gold0"], sw=.9, op=.7))
    s.append(gear((1206, 310), 9, 9, 10, spokes=4))
    s.append(path(smooth([(1199, 426, 1), (1213, 426, 1), (1206, 440, 1)]), "url(#gGold)", K["ink"], 1.2))
    return "".join(s)


def hero():
    big = 'transform="translate(960 336) scale(1.1) translate(-960 -336)"'  # 얼굴이 읽히게 머리만 키운다
    parts = [f"<g {big}>{back_hair()}</g>", coat_tails(), legs(), collar(), f"<g {big}>{face()}</g>", bodice(), belt(), chest(),
             arm_down(), pauldron((1070, 386), 30, False, 1), hourglass(),
             arm_raised(), pauldron((852, 364), -28, True, -1), baton_and_glove()]
    return '<g id="hero">' + "".join(parts) + "</g>"


def eyes_glow():
    g = path(circ((947.6, 276.2), 3), K["cyan2"]) + path(circ((972.4, 276.2), 3.4), K["cyan2"])
    return f'<g filter="url(#fB2)" opacity=".9" transform="translate(960 336) scale(1.1) translate(-960 -336)">{g}</g>'


def fill_light():
    """인물 실루엣 안에만 왼쪽 위 청록 채움빛과 머리·어깨 금빛 역광을 얹어 부피를 살린다"""
    return (f'<filter id="fWhite"><feColorMatrix type="matrix" values="0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 1 0"/></filter>'
            f'<mask id="mHero" maskUnits="userSpaceOnUse" x="0" y="0" width="{W}" height="{H}"><use href="#hero" filter="url(#fWhite)"/></mask>'
            + rad("gFillC", [(0, K["cyan3"], .2), (.6, K["cyan2"], .06), (1, K["cyan2"], 0)], 820, 360, 480)
            + rad("gFillG", [(0, K["gold4"], .22), (.5, K["gold3"], .08), (1, K["gold3"], 0)], 960, 300, 200)
            + f'<g mask="url(#mHero)" style="mix-blend-mode:screen"><rect width="{W}" height="{H}" fill="url(#gFillC)"/>'
              f'<rect width="{W}" height="{H}" fill="url(#gFillG)"/></g>')


def diamond(c, r, fill):
    x, y = c
    return path(f"M{x:.1f} {y - r:.1f}L{x + r * .7:.1f} {y:.1f}L{x:.1f} {y + r:.1f}L{x - r * .7:.1f} {y:.1f}Z", fill)


def ornament(x0, x1, y):
    m = (x0 + x1) / 2
    return (path(f"M{x0} {y}L{m - 16} {y}M{m + 16} {y}L{x1} {y}", stroke=K["gold3"], sw=1.2, op=.8)
            + diamond((m, y), 7, K["gold3"]) + diamond((m, y), 3, K["navy0"])
            + diamond((m - 24, y), 3, K["gold4"]) + diamond((m + 24, y), 3, K["gold4"]))


INSETS = [  # (원 중심, 반지름, 보는 곳, 배율, 제목, 설명)
    ((1716, 236), 92, (961, 292), 1.75, "THE MONOCLE", "a lens that reads every second"),
    ((1716, 520), 92, (960, 372), 1.6, "CLOCKWORK HEART", "gorget chronometer · cyan core"),
    ((1716, 804), 92, (1209, 378), 1.3, "STILLED HOURGLASS", "frozen sand · the time-stop"),
]
PALETTE = [("NAVY", K["navy2"], False), ("MIDNIGHT", K["navy0"], False), ("GOLD", K["gold3"], True),
           ("PALE GOLD", K["gold4"], True), ("TEAL", K["cyan1"], True), ("CYAN GLOW", K["cyan2"], False)]


def sheet():
    s = [label("HERO CONCEPT", 74, 104, 14, K["cyan3"], 700, 5),
         rad("gTitle", [(0, K["gold5"]), (.5, K["gold3"]), (1, K["gold2"])], 250, 130, 300),
         f'<g filter="url(#fB8)" opacity=".5">{label("CHRONOS", 70, 184, 72, K["gold3"], 700, 8)}</g>',
         label("CHRONOS", 70, 184, 72, "url(#gTitle)", 700, 8),
         label("THE CHRONO CONDUCTOR", 74, 220, 19, K["ivory"], 700, 5.2),
         ornament(74, 426, 244),
         label("TIME TACTICIAN · BUFFER", 74, 278, 15, K["cyan3"], 700, 4),
         label("“Every second answers to his baton.”", 74, 308, 15, K["ivory"], 500, 1, op=.78)]
    for k, (c, r, f, z, t, sub) in enumerate(INSETS):
        s.append(f'<clipPath id="ins{k}"><circle cx="{c[0]}" cy="{c[1]}" r="{r}"/></clipPath>')
        s.append(path(circ(c, r + 18), K["navy4"], op=.08))
        s.append(f'<circle cx="{c[0]}" cy="{c[1]}" r="{r}" fill="{K["navy0"]}"/>')
        s.append(f'<g clip-path="url(#ins{k})"><use href="#scene" transform="translate({c[0]} {c[1]}) scale({z}) translate({-f[0]} {-f[1]})"/></g>')
        s.append(path(circ(c, r), stroke=K["gold3"], sw=2.6))
        s.append(path(circ(c, r + 7), stroke=K["gold3"], sw=.9, op=.6))
        for i in range(24):
            s.append(path(f"M{pt(pol(c, r + 3, i * 15))}L{pt(pol(c, r + 7 + (3 if i % 6 == 0 else 0), i * 15))}", stroke=K["gold4"], sw=1.6 if i % 6 == 0 else .9))
        s.append(diamond((c[0], c[1] - r - 7), 6, K["gold3"]))
        s.append(label(t, c[0], c[1] + r + 38, 15, K["gold4"], 700, 3, "middle"))
        s.append(label(sub, c[0], c[1] + r + 60, 13, K["ivory"], 500, 1.2, "middle", op=.72))
    s.append(label("PALETTE", 74, 930, 13, K["cyan3"], 700, 4))
    for k, (n, col, f24) in enumerate(PALETTE):
        x = 74 + k * 62
        s.append(f'<rect x="{x}" y="944" width="44" height="44" rx="6" fill="{col}" stroke="{K["gold3"]}" stroke-width="1.2"/>')
        if f24:
            s.append(diamond((x + 37, 951), 3.6, K["ink"]) + diamond((x + 37, 951), 2.2, K["ivory"]))
        s.append(label(col.upper(), x + 22, 1006, 10, K["ivory"], 500, .6, "middle", op=.8))
        s.append(label(n, x + 22, 1022, 9, K["gold4"], 700, .8, "middle", op=.8))
    s.append(diamond((80, 1046), 3.6, K["ink"]) + diamond((80, 1046), 2.2, K["ivory"]))
    s.append(label("= f24p in-game palette color", 92, 1050, 10, K["ivory"], 500, .6, op=.6))
    return "".join(s)


def build(sheet_on=True):
    _cid[0] = 0
    scene = [background(), halo(), ribbons(), ripples(),
             '<ellipse cx="978" cy="992" rx="142" ry="14" fill="#02040a" opacity=".7" filter="url(#fB4)"/>',
             hero(),
             '<g mask="url(#mRim)" style="mix-blend-mode:screen"><use href="#hero" filter="url(#fRim)"/></g>',
             fill_light(), eyes_glow(), holo(), particles(),
             f'<rect width="{W}" height="{H}" fill="url(#gVig)"/>']
    body = [defs(), '<g id="scene">', *scene, "</g>"] + ([sheet()] if sheet_on else [])
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">'
            + "".join(body) + "</svg>")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=str(OUT))
    ap.add_argument("--scale", type=int, default=2)
    ap.add_argument("--no-png", action="store_true")
    a = ap.parse_args()
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    for name, on in (("chronos", True), ("chronos_clean", False)):  # 컨셉 시트 / 그림만
        svg = out / f"{name}.svg"
        svg.write_text(build(on), encoding="utf-8")
        print(svg)
        if not a.no_png:
            print(shot.shot(svg, out / f"{name}_{W * a.scale}.png", a.scale))
