# 영웅 컨셉 아트 — 세라피나, 새벽빛의 성녀(Seraphina, Saint of the Dawnlight). 해 원반 지팡이를 든 힐러
# 형체를 SVG 벡터로 직접 그리고(Claude 제작) shot.py로 PNG를 찍는다. 그리는 도구(곡선·셀 음영·글자)는 chronos.py의 것을 쓴다.
# 색 뼈대는 상아·금·새벽 주황이다(K에 f24p 색을 표시했다). f24p에는 흰색이 없어 24px로 옮길 때 상아는 efd8a1, 그늘은 927e6a를 쓰려는 것이다
# 사용: python tools/art/concept/seraphina.py [--out 폴더] [--scale 2] [--no-png]
#   → seraphina.svg(컨셉 시트)·seraphina_clean.svg(그림만)와 PNG(가로 1920 × scale px: 2 = 4K, 4 = 8K)
import argparse
import math
import random
from pathlib import Path

import chronos
import shot
from chronos import W, H, along, catmull, cel, circ, diamond, label, limb, lin, mirror, path, poly, pol, pt, rad, ribbon, sector, smooth, unit

OUT = Path(__file__).resolve().parents[3] / "art" / "concept" / "seraphina"

K = {
    "ink": "#24150f",  # 따뜻한 먹선
    "iv5": "#fffaf0", "iv4": "#f5ecd9", "iv3": "#e4d4b6", "iv2": "#c8b18e", "iv1": "#927e6a", "iv0": "#5c4838",  # 상아. iv1 = f24p
    "gold0": "#4a2a0c", "gold1": "#ab5c1c", "gold2": "#d48b24", "gold3": "#efac28", "gold4": "#efd8a1", "gold5": "#fff5da",  # gold1·3·4 = f24p
    "or1": "#a5401c", "or2": "#ef692f", "or3": "#efb775", "or4": "#ffdcb4",  # 새벽 주황. or2·3 = f24p
    "skin": "#f6d3b4", "skin_s": "#dca88a", "skin_d": "#a56243", "skin_h": "#fde8d4", "lip": "#e08e78",  # skin_d = f24p
    "hair": "#a56243", "hair_s": "#773421", "hair_d": "#45230d", "hair_h": "#efb775",  # 모두 f24p
    "glass0": "#1d1838", "glass1": "#3e2650", "glass2": "#7a2e3e",
    "stone": "#120e18", "stone_h": "#2e2536",
}
RW, RR = (960, 330), 210  # 등 뒤 장미창 중심·반지름
STAFF_B, STAFF_T = (786, 998), (762, 214)  # 지팡이 물미 끝, 자루 위끝(초승달 받침)
SUN = along(STAFF_B, STAFF_T, 1.06)  # 지팡이 해 원반 중심
ORB = (1126, 406)  # 왼손바닥 위에 뜬 빛 구슬


def strip(pts, w):
    """점을 지나는 고른 폭(반폭 w) 띠의 양쪽 가장자리 점"""
    q = catmull(pts)
    L, R = [], []
    for i, p in enumerate(q):
        ux, uy = unit(q[max(i - 1, 0)], q[min(i + 1, len(q) - 1)])
        L.append((p[0] - uy * w, p[1] + ux * w))
        R.append((p[0] + uy * w, p[1] - ux * w))
    return L, R


def sunburst(c, r0, long, short, n, a0=0.0, a1=360.0, half=6.0):
    """c 둘레의 햇살 삼각형들(a0~a1도, 길이는 long·short 번갈아)"""
    out = []
    for i in range(n):
        a = a0 + (a1 - a0) * i / (n - 1 if a1 - a0 < 360 else n)
        out.append(poly([pol(c, r0, a - half), pol(c, long if i % 2 == 0 else short, a), pol(c, r0, a + half)]))
    return out


# ── SVG 정의 ─────────────────────────────────────────────────────────

def defs():
    d = [
        lin("gIvory", [(0, K["iv5"]), (.35, K["iv4"]), (.75, K["iv3"]), (1, K["iv2"])], x2=1, y2=1),
        lin("gIvoryV", [(0, K["iv4"]), (.55, K["iv3"]), (1, K["iv2"])]),
        lin("gVeil", [(0, K["iv5"], .97), (.5, K["iv4"], .9), (1, K["iv3"], .6)]),
        lin("gGold", [(0, K["gold5"]), (.3, K["gold3"]), (.7, K["gold2"]), (1, K["gold1"])]),
        lin("gGoldS", [(0, K["gold3"]), (.6, K["gold2"]), (1, K["gold0"])]),
        lin("gShaft", [(0, K["gold2"]), (.35, K["gold5"]), (.6, K["gold3"]), (1, K["gold1"])], x2=1, y2=0),
        lin("gStole", [(0, K["or3"]), (.4, K["or2"]), (1, K["or1"])], x2=1, y2=1),
        lin("gHair", [(0, K["hair_h"]), (.3, K["hair"]), (1, K["hair_s"])]),
        lin("gWin", [(0, K["glass0"]), (.4, K["glass1"]), (.62, K["glass2"]), (.8, K["or2"]), (.93, K["or3"]), (1, K["gold4"])],
            RW[0], RW[1] - RR, RW[0], RW[1] + RR, user=True),
        rad("gBg", [(0, "#2a2134"), (.4, "#171221"), (.75, "#0b0911"), (1, "#050408")], 960, 520, 1150),
        rad("gSunrise", [(0, K["gold5"], .95), (.25, K["or3"], .7), (.6, K["or2"], .25), (1, K["or2"], 0)], RW[0], RW[1] + RR - 20, 320),
        rad("gFloor", [(0, K["gold3"], .3), (.5, K["or2"], .08), (1, K["or1"], 0)], 960, 994, 560),
        rad("gVig", [(0, "#000", 0), (.62, "#000", 0), (1, "#040308", .72)], 960, 520, 1150),
        rad("gGlow", [(0, "#ffffff", .95), (.3, K["gold5"], .6), (.6, K["or3"], .2), (1, K["or2"], 0)], 0, 0, 1),
        rad("gSpark", [(0, "#ffffff"), (.25, K["gold4"], .9), (1, K["gold3"], 0)], 0, 0, 1),
        rad("gSunDisk", [(0, "#ffffff"), (.45, K["gold5"]), (.8, K["gold4"]), (1, K["gold3"])], SUN[0], SUN[1], 22),
        rad("gCrown", [(0, "#ffffff"), (.5, K["gold5"]), (1, K["gold3"])], 960, 208, 14),
        rad("gOrb", [(0, "#ffffff"), (.5, K["gold5"]), (1, K["or3"])], ORB[0], ORB[1], 13),
        rad("gRimMask", [(0, "#fff"), (.55, "#bdbdbd"), (1, "#303030")], 960, 520, 650),
    ]
    for i, sd in (("fB2", 2), ("fB4", 4), ("fB8", 8)):
        d.append(f'<filter id="{i}" filterUnits="userSpaceOnUse" x="-200" y="-200" width="{W + 400}" height="{H + 400}">'
                 f'<feGaussianBlur stdDeviation="{sd}"/></filter>')
    # 역광 테두리: aias.py fRim과 같은 방식. 빛은 등 뒤 장미창의 해에서 온다
    d.append(f'<filter id="fRim" filterUnits="userSpaceOnUse" x="0" y="0" width="{W}" height="{H}" color-interpolation-filters="sRGB">'
             '<feMorphology in="SourceAlpha" operator="erode" radius="1.1" result="a1"/>'
             '<feMorphology in="SourceAlpha" operator="erode" radius="2.6" result="e"/>'
             '<feOffset in="e" dx="0" dy="2" result="e2"/>'
             '<feComposite in="a1" in2="e2" operator="out" result="edge"/>'
             '<feGaussianBlur in="edge" stdDeviation="0.5" result="eb"/>'
             '<feComposite in="eb" in2="a1" operator="in" result="eb2"/>'
             f'<feFlood flood-color="{K["gold5"]}" flood-opacity=".9"/><feComposite in2="eb2" operator="in"/></filter>')
    d.append(f'<mask id="mRim" maskUnits="userSpaceOnUse" x="0" y="0" width="{W}" height="{H}">'
             f'<rect width="{W}" height="{H}" fill="url(#gRimMask)"/></mask>')
    d.append(f'<clipPath id="cWin"><circle cx="{RW[0]}" cy="{RW[1]}" r="{RR}"/></clipPath>')
    return "<defs>" + "".join(d) + "</defs>"


# ── 배경·효과 ────────────────────────────────────────────────────────

def background():
    s = [f'<rect width="{W}" height="{H}" fill="url(#gBg)"/>']
    for x in (640, 1230):  # 장미창 양옆 기둥
        s.append(path(poly([(x, 60), (x + 50, 60), (x + 50, 1000), (x, 1000)]), K["stone"]))
        s.append(path(f"M{x + 6} 60L{x + 6} 1000", stroke=K["stone_h"], sw=3, op=.8))
    arch = f"M665 120Q690 -60 960 -120Q1230 -60 1255 120"  # 뾰족 아치(꼭대기는 화면 밖)
    s.append(path(arch, stroke=K["stone"], sw=50) + path(arch, stroke=K["stone_h"], sw=2.4, op=.8))
    return "".join(s)


def rose_window():
    """등 뒤 장미창: 아래에서 새벽 해가 떠올라 위는 밤, 아래는 주황으로 물든다"""
    s = [path(circ(RW, RR + 24), K["stone"]), path(circ(RW, RR), "url(#gWin)")]
    tint = []
    for i in range(12):
        tint.append(path(sector(RW, 60, 140, i * 30, i * 30 + 30), K["glass0"] if i % 2 else K["glass2"], op=.28))
        tint.append(path(circ(pol(RW, 176, i * 30 + 15), 30), K["glass1"] if i % 2 else K["or1"], op=.25))
    tint.append(f'<ellipse cx="{RW[0]}" cy="{RW[1] + RR - 20}" rx="320" ry="320" fill="url(#gSunrise)"/>')
    s.append('<g clip-path="url(#cWin)">' + "".join(tint) + "</g>")
    s.append(tracery(K["stone"], 1) + f'<g opacity=".35">{tracery(K["gold1"], .2)}</g>')  # 납선 위의 가는 금빛
    s.append(path(circ(RW, RR + 24), stroke=K["stone_h"], sw=2))
    return "".join(s)


def tracery(col, k):
    """장미창 납선(굵기 k배)"""
    s = [path(circ(RW, r), stroke=col, sw=w * k) for r, w in ((RR, 8), (140, 7), (60, 7), (22, 6))]
    for i in range(12):
        s.append(path(f"M{pt(pol(RW, 60, i * 30))}L{pt(pol(RW, RR, i * 30))}", stroke=col, sw=6 * k))
        s.append(path(circ(pol(RW, 176, i * 30 + 15), 30), stroke=col, sw=5 * k))
    for i in range(6):
        s.append(path(circ(pol(RW, 40, i * 60), 18), stroke=col, sw=4 * k))
    return "".join(s)


def rays():
    """장미창에서 바닥으로 퍼지는 빛줄기"""
    s = []
    for x1, w, op in ((520, 30, .06), (700, 60, .1), (880, 40, .08), (1060, 46, .08), (1230, 64, .1), (1420, 34, .06)):
        x0 = RW[0] + (x1 - RW[0]) * .25
        s.append(path(poly([(x0 - w / 5, 430), (x0 + w / 5, 430), (x1 + w, 1000), (x1 - w, 1000)]), K["gold4"], op=op))
    s.append(f'<ellipse cx="{RW[0]}" cy="{RW[1] + RR - 20}" rx="300" ry="260" fill="url(#gSunrise)" opacity=".55"/>')
    return f'<g filter="url(#fB8)">{"".join(s)}</g>'


def floor():
    """정화의 성역(W) 문양: 고리·꽃잎·햇살"""
    s = ['<ellipse cx="960" cy="996" rx="640" ry="96" fill="url(#gFloor)"/>']
    for k, rx in enumerate((300, 390, 490, 600)):
        dash = ' stroke-dasharray="14 10"' if k % 2 else ""
        s.append(f'<ellipse cx="960" cy="994" rx="{rx}" ry="{rx * .12:.1f}" fill="none" stroke="{K["gold3"] if k % 2 else K["or3"]}" '
                 f'stroke-width="{2.2 - k * .4:.2f}" opacity="{.7 - k * .15:.2f}"{dash}/>')
    ns = ' vector-effect="non-scaling-stroke"'
    g = [f'<circle r="262" fill="none" stroke="{K["gold3"]}" stroke-width="2.2"{ns}/>',
         f'<circle r="236" fill="none" stroke="{K["gold3"]}" stroke-width="1.2"{ns}/>',
         f'<circle r="140" fill="none" stroke="{K["or3"]}" stroke-width="1.2"{ns}/>']
    for i in range(24):  # 고리 사이 꽃잎
        a = i * 15
        g.append(f'<path d="M{pt(pol((0, 0), 236, a))}Q{pt(pol((0, 0), 262, a + 7.5))} {pt(pol((0, 0), 236, a + 15))}" fill="none" '
                 f'stroke="{K["gold4"]}" stroke-width="1.2"{ns}/>')
    star = poly([pol((0, 0), 220 if i % 2 == 0 else 150, i * 15) for i in range(24)])
    g.append(f'<path d="{star}" fill="none" stroke="{K["gold4"]}" stroke-width="1.1"{ns}/>')
    for r in sunburst((0, 0), 264, 316, 290, 16, half=3):
        g.append(f'<path d="{r}" fill="{K["gold3"]}" opacity=".8"/>')
    ring = f'<g transform="translate(960 994) scale(1 .15)">{"".join(g)}</g>'
    sg = "".join(s)
    return f'<g filter="url(#fB4)">{sg}{ring}</g>{sg}{ring}'


def motes():
    """떠다니는 빛 알갱이와 빛 깃털(E 수호 천사의 날개)"""
    rnd = random.Random(5)
    s, n = [], 0
    while n < 140:
        p = (rnd.uniform(380, 1540), rnd.uniform(360, 1040)) if rnd.random() < .7 else (rnd.uniform(300, 1620), rnd.uniform(60, 1040))
        if 900 < p[0] < 1020 and 180 < p[1] < 340:  # 얼굴 앞에는 두지 않는다
            continue
        n += 1
        col = rnd.choice((K["gold4"], K["gold5"], K["or3"], K["or4"]))
        s.append(path(circ(p, rnd.uniform(.7, 2.3)), col, op=round(rnd.uniform(.35, 1), 2)))
    g = "".join(s)
    feathers = []
    for _ in range(9):
        x, y, a, sc = rnd.uniform(420, 1500), rnd.uniform(380, 900), rnd.uniform(-60, 60), rnd.uniform(.7, 1.2)
        if 860 < x < 1060:
            x += 220
        f = smooth([(0, -16, 1), (5, -8), (6, 4), (2, 14, 1), (-3, 6), (-4, -6)])
        feathers.append(f'<g transform="translate({x:.0f} {y:.0f}) rotate({a:.0f}) scale({sc:.2f})">'
                        + path(f, K["gold5"], op=.55) + path("M0 -14L1 14", stroke=K["gold3"], sw=.8, op=.7) + "</g>")
    sp = []
    for p, r in ((SUN, 26), (ORB, 22), ((960, 186), 12), ((1330, 520), 9), ((560, 640), 8), ((960, 990), 12)):
        star = poly([pol(p, r if i % 2 == 0 else r * .14, i * 45) for i in range(8)])
        sp.append(f'<g transform="translate({p[0]:.1f} {p[1]:.1f}) scale({r:.1f})"><circle r=".55" fill="url(#gSpark)"/></g>')
        sp.append(path(star, "#ffffff", op=.95))
    return f'<g filter="url(#fB2)">{g}</g>{g}' + "".join(feathers) + "".join(sp)


# ── 인물 ─────────────────────────────────────────────────────────────

def veil_back():
    """등 뒤로 흘러내린 베일. 바람에 화면 왼쪽으로 날린다"""
    pts = [(960, 200), (930, 208), (906, 232), (892, 276), (884, 340), (868, 420), (846, 500), (818, 580), (790, 650), (758, 716, 1),
           (796, 706), (832, 724), (870, 708), (900, 722), (1020, 712), (1050, 702), (1080, 710, 1), (1068, 620), (1056, 540),
           (1042, 460), (1030, 380), (1020, 300), (1012, 250), (992, 214)]
    folds = "".join(path(smooth(f, False), stroke=K["iv2"], sw=2, op=.6) for f in (
        [(900, 380), (860, 520), (800, 690)], [(920, 430), (884, 570), (846, 712)], [(1040, 420), (1056, 560), (1066, 700)]))
    return cel(smooth(pts), "url(#gVeil)", [(smooth([(1000, 300), (1090, 300), (1100, 730), (1010, 730)]), K["iv2"], .5)], 1.8, inner=folds)


def shoes():
    return "".join(f'<ellipse cx="{x}" cy="996" rx="15" ry="6" fill="url(#gGold)" stroke="{K["ink"]}" stroke-width="1.4"/>' for x in (930, 994))


HEM = [(1128, 982, 1), (1094, 992), (1058, 985), (1022, 993), (986, 986), (950, 994), (914, 987), (878, 993), (842, 986), (806, 992), (792, 982, 1)]


def skirt():
    pts = [(918, 524, 1), (1002, 524, 1), (1022, 590), (1046, 680), (1074, 780), (1100, 880)] + HEM + [(816, 880), (844, 780), (872, 680), (898, 590)]
    shades = [(smooth([(992, 524), (1050, 520), (1160, 1000), (1030, 1000), (1010, 800), (996, 640)]), K["iv2"], .55),
              (smooth([(900, 560), (914, 560), (858, 990), (816, 990), (850, 800)]), K["iv5"], .6)]
    folds = "".join(path(smooth(f, False), stroke=K["iv2"], sw=2, op=.7) for f in (
        [(940, 560), (918, 760), (900, 986)], [(1000, 600), (1030, 800), (1054, 984)], [(1020, 640), (1062, 820), (1090, 986)],
        [(910, 620), (870, 820), (846, 986)]))
    band = [(p[0], p[1] - 24) for p in HEM]
    trim = (path(smooth(band, False), stroke=K["gold1"], sw=13) + path(smooth(band, False), stroke=K["gold3"], sw=8)
            + path(smooth([(p[0], p[1] - 3) for p in band], False), stroke=K["gold5"], sw=1.2, op=.7))
    for x in range(816, 1110, 34):  # 금 띠의 새벽 해 무늬
        y = min(band, key=lambda p: abs(p[0] - x))[1]
        trim += diamond((x, y), 5, K["or2"]) + diamond((x, y), 2, K["gold5"])
    return cel(smooth(pts), "url(#gIvory)", shades, 2.2, inner=folds + trim)


def bodice():
    pts = [(902, 376, 1), (926, 362), (960, 358), (994, 362), (1018, 376, 1), (1024, 420), (1016, 470), (1006, 530, 1), (960, 536),
           (914, 530, 1), (904, 470), (896, 420)]
    shades = [(smooth([(990, 360), (1040, 360), (1040, 540), (1000, 540), (1010, 470), (1006, 420)]), K["iv2"], .5),
              (smooth([(910, 380), (936, 372), (930, 420), (912, 440)]), K["iv5"], .7)]
    lines = "".join(path(smooth(l, False), stroke=K["iv2"], sw=1.6, op=.8) for l in (
        [(960, 380), (958, 450), (960, 526)], [(954, 400), (950, 470), (952, 526)], [(966, 400), (970, 470), (968, 526)]))
    return cel(smooth(pts), "url(#gIvory)", shades, 2.2, inner=lines)


STOLE = [(934, 360), (938, 420), (941, 500), (940, 600), (937, 720), (934, 840), (932, 880)]


def stole():
    """목에 건 영대(새벽 주황) 두 자락. 끝에 금실 해 문양과 술"""
    s = []
    for k, pts in enumerate((STOLE, mirror(STOLE))):
        L, R = strip(pts, 12)
        end = pts[-1]
        body = poly(L + [(end[0], end[1] + 12)] + R[::-1])
        shade = [(smooth([(end[0] + (2 if k == 0 else -24), 350), (end[0] + (24 if k == 0 else -2), 350),
                          (end[0] + (24 if k == 0 else -2), 900), (end[0] + (6 if k == 0 else -20), 900)]), K["or1"], .45 if k else .3)]
        iL, iR = strip(pts, 9)
        trim = path("M" + "L".join(pt(p) for p in iL), stroke=K["gold3"], sw=2) + path("M" + "L".join(pt(p) for p in iR), stroke=K["gold3"], sw=2)
        s.append(cel(body, "url(#gStole)", shade, 1.8, inner=trim))
        c = (end[0], end[1] - 36)
        s.append("".join(path(r, K["gold3"]) for r in sunburst(c, 6, 12, 9, 8, half=14)) + path(circ(c, 5.5), "url(#gGold)", K["ink"], .9))
        for dx in range(-10, 11, 4):  # 술
            s.append(path(f"M{end[0] + dx} {end[1] + 6 - abs(dx) * .6:.1f}L{end[0] + dx * 1.1:.1f} {end[1] + 26}", stroke=K["gold3"], sw=1.6))
    return "".join(s)


def belt():
    cord = smooth([(910, 526), (960, 534), (1010, 526)], False)
    s = path(cord, stroke=K["ink"], sw=7.5) + path(cord, stroke=K["gold3"], sw=4.6) + path(cord, stroke=K["gold5"], sw=1.2, op=.7)
    for pts in ([(948, 538), (944, 590), (946, 640)], [(952, 538), (958, 596), (955, 654)]):
        d = smooth(pts, False)
        s += path(d, stroke=K["ink"], sw=5) + path(d, stroke=K["gold3"], sw=2.8)
        e = pts[-1]
        s += path(smooth([(e[0] - 4, e[1], 1), (e[0] + 4, e[1], 1), (e[0] + 6, e[1] + 16), (e[0], e[1] + 20), (e[0] - 6, e[1] + 16)]), "url(#gGold)", K["ink"], 1)
    s += path(circ((950, 534), 6.5), "url(#gGold)", K["ink"], 1.2)
    return s


def arm_upper(sh, el):
    # along()의 off는 위→아래로 내려가는 팔에서 +가 화면 왼쪽이다. 빛은 화면 왼쪽 위에서 온다
    return cel(limb(sh, el, 25, 23, 4), "url(#gIvory)", [(limb(along(sh, el, 0, -12), along(sh, el, 1, -10), 13, 12), K["iv2"], .5)], 2)


def sleeve(pts, inner_pts, cuff):
    """종 모양 소매: 몸통 → 안쪽 그늘 → 금 소맷단"""
    s = cel(smooth(pts), "url(#gIvory)", [(smooth(inner_pts), K["iv0"], .8)], 2)
    return s + path(smooth(cuff, False), stroke=K["ink"], sw=8.5) + path(smooth(cuff, False), stroke=K["gold3"], sw=5.5)


def veil_cap():
    """머리를 덮고 어깨에 내려앉은 베일"""
    left = [(960, 198), (936, 201), (916, 214), (902, 238), (896, 272), (894, 312), (886, 350), (870, 384), (858, 416, 1),
            (890, 404), (916, 384), (930, 362), (944, 350), (960, 346)]
    pts = left + mirror(left[1:-1])[::-1]
    folds = "".join(path(smooth(f, False), stroke=K["iv2"], sw=1.8, op=.7) for f in (
        [(1012, 280), (1022, 340), (1046, 396)], [(908, 280), (900, 340), (878, 396)], [(926, 214), (912, 250), (906, 300)]))
    return cel(smooth(pts), "url(#gVeil)", [(smooth([(972, 196), (1040, 196), (1070, 420), (1000, 400), (1012, 300), (998, 230)]), K["iv2"], .55)],
               2, inner=folds)


def hair_back():
    pts = [(960, 222), (936, 226), (920, 244), (914, 274), (914, 310), (918, 340), (930, 354), (960, 352), (990, 354), (1002, 340),
           (1006, 310), (1006, 274), (1000, 244), (984, 226)]
    return cel(smooth(pts), "url(#gHair)", [(smooth([(984, 220), (1010, 240), (1012, 360), (980, 360), (994, 300)]), K["hair_d"], .5)], 1.6)


def neck():
    return cel(smooth([(948, 306, 1), (972, 306, 1), (974, 352, 1), (946, 352, 1)]), K["skin"],
               [(smooth([(940, 300), (980, 300), (980, 322), (960, 330), (940, 322)]), K["skin_s"], .9),
                (smooth([(966, 300), (980, 300), (980, 356), (966, 356)]), K["skin_s"], .7)], 1.6)


def collar():
    c = smooth([(938, 346, 1), (960, 352), (982, 346, 1), (988, 362), (960, 372), (932, 362)])
    return cel(c, "url(#gIvory)", [], 1.6) + path(smooth([(934, 360), (960, 370), (986, 360)], False), stroke=K["gold3"], sw=3)


def face():
    s = []
    fc = smooth([(933, 258), (933, 276), (936, 292), (943, 306), (951, 316), (960, 320), (969, 316), (977, 306), (984, 292), (987, 276),
                 (987, 258), (980, 242), (960, 236), (940, 242)])
    s.append(cel(fc, K["skin"], [(smooth([(978, 240), (983, 258), (983, 274), (980, 290), (975, 304), (967, 314), (958, 324), (1004, 336), (1006, 230)]), K["skin_s"], .6),
                                 (circ((944, 293), 7), K["or3"], .3), (circ((976, 293), 7), K["or3"], .22),
                                 (smooth([(938, 258), (946, 250), (954, 254), (944, 264)]), K["skin_h"], .6)], 1.7))
    for sg in (1, -1):  # 감은 눈(눈꺼풀·속눈썹)·눈썹. sg = -1은 거울
        X = (lambda x: x) if sg == 1 else (lambda x: W - x)
        s.append(path(smooth([(X(939.5), 280), (X(944), 283.4), (X(950), 284.2), (X(955.5), 281.6)], False), stroke=K["ink"], sw=1.9))
        for x0, y0, dx, dy in ((942, 282.4, -2.2, 3), (946, 283.8, -1, 3.4), (950.5, 284.2, 0, 3.4)):
            s.append(path(f"M{X(x0):.1f} {y0}l{dx * sg:.1f} {dy}", stroke=K["ink"], sw=1))
        s.append(path(smooth([(X(941), 276.4), (X(948), 274.8), (X(955), 277)], False), stroke=K["skin_s"], sw=1.1))
        s.append(path(smooth([(X(937.5), 270.5), (X(946), 266.4), (X(955.5), 268.4)], False), stroke=K["hair_s"], sw=1.7))
    s.append(path(smooth([(961, 282, 1), (963.5, 292), (965, 298), (961.5, 300.5, 1), (961, 291)]), K["skin_s"]))
    s.append(path(smooth([(958.6, 284), (958.4, 294)], False), stroke=K["skin_h"], sw=1.1))
    s.append(path(smooth([(955.5, 307), (960, 310.6), (964.5, 307)]), K["lip"]))  # 아랫입술
    s.append(path(smooth([(952.5, 305), (956, 306.6), (960, 307), (964, 306.6), (967.5, 305)], False), stroke="#a8503e", sw=1.3))  # 입꼬리가 올라간 옅은 미소
    s.append(path(smooth([(958, 309.4), (960, 309.9), (962, 309.4)], False), stroke=K["skin_h"], sw=.9, op=.8))
    return "".join(s)


def hair_front():
    """가운데 가르마의 앞머리와 어깨 앞으로 내린 두 가닥"""
    s = []
    bang = [(960, 230, 1), (944, 234), (932, 246), (927, 268, 1), (934, 256), (946, 247), (960, 244, 1), (974, 247), (986, 256), (993, 268, 1),
            (988, 246), (976, 234)]
    s.append(cel(smooth(bang), "url(#gHair)", [(smooth([(962, 228), (996, 240), (996, 272), (968, 250)]), K["hair_s"], .6)], 1.4))
    for pts in ([(930, 262), (922, 300), (920, 344), (924, 388), (932, 424)], [(990, 262), (998, 300), (1000, 344), (996, 388), (988, 424)]):
        s.append(cel(ribbon(pts, 8, head=.1, tail=.3), "url(#gHair)", [], 1.4,
                     inner=path(smooth([(p[0] + (1 if p[0] < 960 else -1), p[1]) for p in pts], False), stroke=K["hair_s"], sw=1, op=.8)))
    return "".join(s)


def diadem():
    """새벽 해 관: 이마 띠 + 위로 뻗는 햇살"""
    c = (960, 208)
    band = smooth([(922, 248), (936, 232), (960, 226), (984, 232), (998, 248)], False)
    s = [f'<g filter="url(#fB4)" opacity=".8">{path(circ(c, 30), K["gold5"])}</g>']
    s += [path(r, "url(#gGold)", K["gold0"], .7) for r in sunburst(c, 12, 54, 38, 9, -80, 80, half=9)]
    s.append(path(band, stroke=K["ink"], sw=7.5) + path(band, stroke=K["gold3"], sw=4.6) + path(band, stroke=K["gold5"], sw=1.2, op=.8))
    s.append(path(circ(c, 14), "url(#gCrown)", K["gold1"], 1.6) + path(circ(c, 9.5), stroke=K["gold3"], sw=1.2, op=.8))
    for x in (938, 982):
        s.append(path(circ((x, 233), 3), K["or2"], K["ink"], .8))
    return "".join(s)


def staff():
    """자루·물미·감은 끈·초승달 받침·해 원반·주황 리본. 쥔 손은 따로 위에 얹는다"""
    s = []
    s.append(path(poly([along(STAFF_B, STAFF_T, 0, -4.6), along(STAFF_B, STAFF_T, 0, 4.6), along(STAFF_B, STAFF_T, 1, 4), along(STAFF_B, STAFF_T, 1, -4)]),
                  "url(#gShaft)", K["ink"], 1.2))
    for t in (.3, .34, .72, .76, .97):
        s.append(path(f"M{pt(along(STAFF_B, STAFF_T, t, -6))}L{pt(along(STAFF_B, STAFF_T, t, 6))}", stroke=K["ink"], sw=4.4)
                 + path(f"M{pt(along(STAFF_B, STAFF_T, t, -5.4))}L{pt(along(STAFF_B, STAFF_T, t, 5.4))}", stroke=K["gold3"], sw=2.6))
    for t in (.52, .55, .58, .66, .69):  # 손잡이 감은 끈
        s.append(path(f"M{pt(along(STAFF_B, STAFF_T, t, -5))}L{pt(along(STAFF_B, STAFF_T, t + .012, 5))}", stroke=K["or1"], sw=2.4))
    s.append(path(poly([along(STAFF_B, STAFF_T, .05, -6.5), along(STAFF_B, STAFF_T, .05, 6.5), along(STAFF_B, STAFF_T, 0, 2), along(STAFF_B, STAFF_T, 0, -2)]),
                  "url(#gGold)", K["ink"], 1.2))
    tie = along(STAFF_T, STAFF_B, .03)  # 리본: 받침 아래에서 바람 쪽(화면 왼쪽)으로 날린다
    for k, (dx, dy, w) in enumerate(((-40, 86, 6), (-56, 64, 5), (-26, 100, 5))):
        pts = [tie, (tie[0] - 6 + dx * .3, tie[1] + dy * .4), (tie[0] + dx * .8, tie[1] + dy * .8), (tie[0] + dx, tie[1] + dy)]
        s.append(path(ribbon(pts, w, head=.05, tail=.4), "url(#gStole)" if k != 1 else K["or1"], K["ink"], .8))
    s.append(f'<g transform="translate({SUN[0]:.1f} {SUN[1]:.1f}) scale(70)" opacity=".75"><circle r="1" fill="url(#gGlow)"/></g>')
    s += [path(r, "url(#gGold)", K["ink"], 1) for r in sunburst(SUN, 24, 56, 42, 16, half=5)]
    cres = [pol(SUN, 38, a) for a in range(100, 261, 10)]
    cres = [cres[0] + (1,)] + cres[1:-1] + [cres[-1] + (1,)] + [pol((SUN[0], SUN[1] - 8), 30, a) for a in range(250, 109, -10)]
    s.append(cel(smooth(cres), "url(#gGold)", [(smooth([(SUN[0] + 4, SUN[1]), (SUN[0] + 44, SUN[1]), (SUN[0] + 44, SUN[1] + 44), (SUN[0] + 4, SUN[1] + 44)]), K["gold1"], .4)], 1.6))
    s.append(path(circ(STAFF_T, 6.5), "url(#gGold)", K["ink"], 1.2))
    s.append(path(circ(SUN, 22), "url(#gSunDisk)", K["gold1"], 2) + path(circ(SUN, 16), stroke=K["gold3"], sw=1.2, op=.7))
    return "".join(s)


def fist():
    """지팡이를 감싼 오른손(엄지가 위)"""
    cx = along(STAFF_B, STAFF_T, (STAFF_B[1] - 520) / (STAFF_B[1] - STAFF_T[1]))[0]
    g = cel(smooth([(cx - 11, 508), (cx, 504), (cx + 13, 507), (cx + 16, 520), (cx + 13, 534), (cx, 538), (cx - 11, 535), (cx - 14, 521)]), K["skin"],
            [(smooth([(cx + 3, 500), (cx + 22, 500), (cx + 22, 542), (cx + 3, 542)]), K["skin_s"], .55)], 1.6,
            inner="".join(path(f"M{cx - 13} {y}Q{cx - 6} {y + 1.6} {cx + 1} {y + .6}", stroke=K["skin_d"], sw=1, op=.75) for y in (516, 524.5, 532)))
    g += cel(smooth([(cx + 11, 509, 1), (cx + 2, 499), (cx - 8, 500), (cx - 11, 507, 1), (cx, 510)]), K["skin"], [], 1.3)
    return g


def arm_staff():
    """오른 아래팔(화면 왼쪽): 지팡이를 팔 길이만큼 옆에 세워 쥔다"""
    return (sleeve([(836, 450), (810, 472), (784, 496, 1), (780, 530), (784, 566), (796, 602, 1), (820, 584), (846, 550), (866, 510), (862, 474)],
                     [(784, 498), (796, 514), (802, 552), (796, 596), (788, 566), (782, 530)],
                     [(784, 496), (780, 530), (784, 566), (796, 602)]))


def arm_bless():
    """왼 아래팔(화면 오른쪽): 손바닥을 위로 펴 빛 구슬을 띄운다"""
    s = sleeve([(1040, 462), (1066, 448), (1094, 436, 1), (1104, 470), (1104, 516), (1094, 562, 1), (1070, 546), (1052, 518), (1040, 492)],
                [(1094, 438), (1102, 470), (1100, 520), (1094, 560), (1088, 520), (1090, 470)],
                [(1094, 436), (1104, 470), (1104, 516), (1094, 562)])
    palm = smooth([(1098, 440), (1116, 436), (1134, 437), (1146, 441), (1152, 446), (1142, 452), (1120, 455), (1100, 454)])
    s += cel(palm, K["skin"], [(smooth([(1096, 448), (1156, 446), (1156, 460), (1096, 460)]), K["skin_s"], .6)], 1.5)
    for x0, y0, x1, y1 in ((1128, 441, 1148, 441.6), (1126, 446, 1150, 447)):
        s += path(f"M{x0} {y0}L{x1} {y1}", stroke=K["skin_d"], sw=.9, op=.75)
    s += cel(smooth([(1104, 440, 1), (1108, 428), (1115, 421), (1121, 424), (1118, 436, 1)]), K["skin"], [], 1.3)
    return s


def orb():
    s = [f'<g transform="translate({ORB[0]} {ORB[1]}) scale(84)" opacity=".85"><circle r="1" fill="url(#gGlow)"/></g>']
    s.append(f'<ellipse cx="{ORB[0]}" cy="{ORB[1]}" rx="30" ry="9" transform="rotate(-16 {ORB[0]} {ORB[1]})" fill="none" '
             f'stroke="{K["gold4"]}" stroke-width="1.4" opacity=".85"/>')
    s.append(path(circ(ORB, 13), "url(#gOrb)"))
    star = poly([pol(ORB, 30 if i % 2 == 0 else 3.4, i * 45) for i in range(8)])
    s.append(path(star, "#ffffff", op=.9))
    return "".join(s)


def hero():
    parts = [veil_back(), shoes(), skirt(), bodice(), stole(), belt(), arm_upper((904, 388), (846, 466)), arm_upper((1016, 388), (1058, 468)),
             veil_cap(), hair_back(), neck(), collar(), face(), hair_front(), diadem(),
             arm_staff(), staff(), fist(), arm_bless()]
    return '<g id="hero">' + "".join(parts) + "</g>"


def fill_light():
    """인물 실루엣 안에만 왼쪽 위 채움빛과 아래 금빛 반사광을 얹어 부피를 살린다"""
    return (f'<filter id="fWhite"><feColorMatrix type="matrix" values="0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 1 0"/></filter>'
            f'<mask id="mHero" maskUnits="userSpaceOnUse" x="0" y="0" width="{W}" height="{H}"><use href="#hero" filter="url(#fWhite)"/></mask>'
            + rad("gFillC", [(0, K["or4"], .14), (.6, K["or3"], .04), (1, K["or3"], 0)], 820, 300, 520)
            + rad("gFillG", [(0, K["gold4"], .2), (.5, K["gold3"], .07), (1, K["gold3"], 0)], 960, 1000, 380)
            + f'<g mask="url(#mHero)" style="mix-blend-mode:screen"><rect width="{W}" height="{H}" fill="url(#gFillC)"/>'
              f'<rect width="{W}" height="{H}" fill="url(#gFillG)"/></g>')


# ── 컨셉 시트 ─────────────────────────────────────────────────────────

def ornament(x0, x1, y):
    m = (x0 + x1) / 2
    return (path(f"M{x0} {y}L{m - 16} {y}M{m + 16} {y}L{x1} {y}", stroke=K["gold3"], sw=1.2, op=.8)
            + diamond((m, y), 7, K["gold3"]) + diamond((m, y), 3, K["or2"])
            + diamond((m - 24, y), 3, K["gold4"]) + diamond((m + 24, y), 3, K["gold4"]))


INSETS = [  # (원 중심, 반지름, 보는 곳, 배율, 제목, 설명)
    ((1716, 236), 92, (960, 256), 1.6, "THE DAWN DIADEM", "sunburst crown · veil of light"),
    ((1716, 520), 92, SUN, 1.45, "SUNDISC STAFF", "risen sun · crescent cradle"),
    ((1716, 804), 92, (1124, 428), 1.6, "BLESSED PALM", "mending light · open hand"),
]
PALETTE = [("IVORY", K["gold4"], True), ("SHADE", K["iv1"], True), ("GOLD", K["gold3"], True),
           ("PEACH", K["or3"], True), ("DAWN", K["or2"], True), ("HALO", K["gold5"], False)]


def sheet():
    s = [label("HERO CONCEPT", 74, 104, 14, K["or3"], 700, 5),
         rad("gTitle", [(0, K["gold5"]), (.5, K["gold3"]), (1, K["gold2"])], 200, 130, 300),
         f'<g filter="url(#fB8)" opacity=".5">{label("SERAPHINA", 70, 184, 60, K["gold3"], 700, 7)}</g>',
         label("SERAPHINA", 70, 184, 60, "url(#gTitle)", 700, 7),
         label("SAINT OF THE DAWNLIGHT", 74, 220, 19, K["gold5"], 700, 4.4),
         ornament(74, 426, 244),
         label("HOLY HEALER · SUPPORT", 74, 278, 15, K["or3"], 700, 4),
         label("“Every night yields to the dawn.”", 74, 308, 15, K["gold5"], 500, 1, op=.78)]
    for k, (c, r, f, z, t, sub) in enumerate(INSETS):
        s.append(f'<clipPath id="ins{k}"><circle cx="{c[0]}" cy="{c[1]}" r="{r}"/></clipPath>')
        s.append(path(circ(c, r + 18), K["iv3"], op=.08))
        s.append(f'<circle cx="{c[0]}" cy="{c[1]}" r="{r}" fill="#0b0911"/>')
        s.append(f'<g clip-path="url(#ins{k})"><use href="#scene" transform="translate({c[0]} {c[1]}) scale({z}) translate({-f[0]:.1f} {-f[1]:.1f})"/></g>')
        s.append(path(circ(c, r), stroke=K["gold3"], sw=2.6))
        s.append(path(circ(c, r + 7), stroke=K["gold3"], sw=.9, op=.6))
        for i in range(24):
            s.append(path(f"M{pt(pol(c, r + 3, i * 15))}L{pt(pol(c, r + 7 + (3 if i % 6 == 0 else 0), i * 15))}", stroke=K["gold4"], sw=1.6 if i % 6 == 0 else .9))
        s.append(diamond((c[0], c[1] - r - 7), 6, K["gold3"]))
        s.append(label(t, c[0], c[1] + r + 38, 15, K["gold4"], 700, 3, "middle"))
        s.append(label(sub, c[0], c[1] + r + 60, 13, K["gold5"], 500, 1.2, "middle", op=.72))
    s.append(label("PALETTE", 74, 930, 13, K["or3"], 700, 4))
    for k, (n, col, f24) in enumerate(PALETTE):
        x = 74 + k * 62
        s.append(f'<rect x="{x}" y="944" width="44" height="44" rx="6" fill="{col}" stroke="{K["gold3"]}" stroke-width="1.2"/>')
        if f24:
            s.append(diamond((x + 37, 951), 3.6, K["ink"]) + diamond((x + 37, 951), 2.2, K["gold5"]))
        s.append(label(col.upper(), x + 22, 1006, 10, K["gold5"], 500, .6, "middle", op=.8))
        s.append(label(n, x + 22, 1022, 9, K["gold4"], 700, .8, "middle", op=.8))
    s.append(diamond((80, 1046), 3.6, K["ink"]) + diamond((80, 1046), 2.2, K["gold5"]))
    s.append(label("= f24p in-game palette color", 92, 1050, 10, K["gold5"], 500, .6, op=.6))
    return "".join(s)


def build(sheet_on=True):
    chronos._cid[0] = 0
    scene = [background(), rose_window(), rays(), floor(),
             '<ellipse cx="960" cy="996" rx="190" ry="15" fill="#02040a" opacity=".6" filter="url(#fB4)"/>',
             hero(),
             '<g mask="url(#mRim)" style="mix-blend-mode:screen"><use href="#hero" filter="url(#fRim)"/></g>',
             fill_light(), orb(), motes(),
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
    for name, on in (("seraphina", True), ("seraphina_clean", False)):  # 컨셉 시트 / 그림만
        svg = out / f"{name}.svg"
        svg.write_text(build(on), encoding="utf-8")
        print(svg)
        if not a.no_png:
            print(shot.shot(svg, out / f"{name}_{W * a.scale}.png", a.scale))
