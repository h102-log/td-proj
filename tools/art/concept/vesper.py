# 영웅 컨셉 아트 — 베스퍼, 그림자 역병의 설계자(Vesper, Architect of the Shadow Plague). 독 향로와 컴퍼스를 든 디버퍼
# 형체를 SVG 벡터로 직접 그리고(Claude 제작) shot.py로 PNG를 찍는다. 그리는 도구(곡선·셀 음영·글자)는 chronos.py의 것을 쓴다.
# 색 뼈대는 흑갈 가죽·뼈색 부리·독 녹이다(K에 f24p 색을 표시했다). f24p에는 밝은 연두가 없어 24px로 옮길 때 독빛은 39571c, 그늘은 2d472d를 쓰려는 것이다
# 사용: python tools/art/concept/vesper.py [--out 폴더] [--scale 2] [--no-png]
#   → vesper.svg(컨셉 시트)·vesper_clean.svg(그림만)와 PNG(가로 1920 × scale px: 2 = 4K, 4 = 8K)
import argparse
import math
import random
from pathlib import Path

import chronos
import shot
from chronos import W, H, along, catmull, cel, circ, diamond, label, limb, lin, mirror, path, poly, pol, pt, rad, ribbon, smooth

OUT = Path(__file__).resolve().parents[3] / "art" / "concept" / "vesper"

K = {
    "ink": "#0b0906",
    "lea0": "#140d07", "lea1": "#2a1d0d", "lea2": "#392a1c", "lea3": "#4e3a28", "lea4": "#684c3c",  # 흑갈 가죽. lea1·2·4 = f24p
    "bn0": "#5a4a3c", "bn1": "#927e6a", "bn2": "#c9b48a", "bn3": "#efd8a1", "bn4": "#fbf0d4",  # 뼈색. bn1·3 = f24p
    "tx0": "#1f240a", "tx1": "#2d472d", "tx2": "#39571c", "tx3": "#6f9a2c", "tx4": "#b6e04a", "tx5": "#efffc0",  # 독 녹. tx0·1·2 = f24p
    "br1": "#724113", "br2": "#ab5c1c", "br3": "#d48b24",  # 바랜 놋쇠. br1·2 = f24p
    "glove": "#17100a", "glove_h": "#3a2b1e",
}
HAT, TILT = (960, 228), 6  # 모자 중심, 기울기(도, + = 화면 오른쪽이 내려간다)
L1, L2 = (946, 280), (988, 280)  # 가면 렌즈: 가까운 눈(화면 왼쪽)·먼 눈
CEN = (780, 776)  # 향로 몸통 중심
HINGE, TIP_A, TIP_B = (1134, 438), (1112, 580), (1178, 562)  # 컴퍼스 경첩, 받침 다리 끝, 긋는 다리 끝
BP_C = (1264, 400)  # 공중 저주 도면(W 쇠약의 저주)의 중심. 원은 긋는 다리 끝을 지난다
BP_R = math.dist(BP_C, TIP_B)
BP_A0 = math.degrees(math.atan2(TIP_B[0] - BP_C[0], -(TIP_B[1] - BP_C[1])))  # 긋는 다리 끝의 각(12시 = 0, 시계 방향)
BP_A1 = BP_A0 - 238  # 원호가 그려진 끝(반시계로 돌아 올라간다)


def rot(pts, c, a):
    """c 둘레로 a도(시계 방향) 돌린 점"""
    r = math.radians(a)
    co, si = math.cos(r), math.sin(r)
    return [(c[0] + (p[0] - c[0]) * co - (p[1] - c[1]) * si, c[1] + (p[0] - c[0]) * si + (p[1] - c[1]) * co) + tuple(p[2:]) for p in pts]


def ell(c, rx, ry, a0=0.0, a1=360.0, n=24):
    """c 중심 타원 둘레의 점. 0도 = 오른쪽 끝, 90도 = 아래(앞쪽)"""
    m = n if a1 - a0 >= 360 else n + 1
    return [(c[0] + rx * math.cos(math.radians(a0 + (a1 - a0) * i / n)), c[1] + ry * math.sin(math.radians(a0 + (a1 - a0) * i / n))) for i in range(m)]


def polyline(pts):
    return "M" + "L".join(pt(p) for p in pts)


# ── SVG 정의 ─────────────────────────────────────────────────────────

def defs():
    d = [
        lin("gLeather", [(0, K["lea3"]), (.35, K["lea2"]), (.75, K["lea1"]), (1, K["lea0"])], x2=1, y2=1),
        lin("gLeatherV", [(0, K["lea3"]), (.5, K["lea2"]), (1, K["lea1"])]),
        lin("gHat", [(0, K["lea2"]), (.5, K["lea1"]), (1, K["lea0"])], x2=1, y2=1),
        lin("gBone", [(0, K["bn4"]), (.35, K["bn3"]), (.75, K["bn2"]), (1, K["bn1"])], x2=.6, y2=1),
        lin("gBrass", [(0, K["bn3"]), (.3, K["br3"]), (.7, K["br2"]), (1, K["br1"])], x2=1, y2=1),
        lin("gCenser", [(0, K["br3"]), (.3, K["br2"]), (.7, K["br1"]), (1, "#3a2008")], x2=1, y2=1),
        lin("gGlove", [(0, K["glove_h"]), (.5, K["glove"]), (1, "#0a0704")], x2=1, y2=1),
        lin("gVial", [(0, K["tx4"], .95), (.6, K["tx3"], .9), (1, K["tx2"], .9)]),
        rad("gBg", [(0, "#253019"), (.35, "#141a0d"), (.7, "#080a05"), (1, "#030402")], 1020, 520, 1150),
        rad("gFogBand", [(0, "#3a4a24", .55), (.5, "#1f2a14", .3), (1, "#1f2a14", 0)], 960, 740, 900),
        rad("gSwamp", [(0, K["tx1"], .85), (.45, K["tx0"], .7), (.8, "#0b0f05", .5), (1, "#0b0f05", 0)], 960, 1000, 640),
        rad("gVig", [(0, "#000", 0), (.6, "#000", 0), (1, "#020301", .78)], 960, 520, 1150),
        rad("gGlow", [(0, K["tx5"], .95), (.25, K["tx4"], .6), (.6, K["tx3"], .2), (1, K["tx2"], 0)], 0, 0, 1),
        rad("gSpark", [(0, "#ffffff"), (.25, K["tx5"], .9), (1, K["tx4"], 0)], 0, 0, 1),
        rad("gLens1", [(0, K["tx5"]), (.4, K["tx4"]), (.85, K["tx3"]), (1, K["tx2"])], L1[0] - 3, L1[1] - 3, 13),
        rad("gLens2", [(0, K["tx5"]), (.4, K["tx4"]), (.85, K["tx3"]), (1, K["tx2"])], L2[0] - 2, L2[1] - 3, 10),
        rad("gCenserIn", [(0, K["tx5"]), (.4, K["tx4"]), (1, K["tx3"])], CEN[0], CEN[1], 30),
        rad("gRimMask", [(0, "#fff"), (.55, "#bdbdbd"), (1, "#303030")], 1100, 520, 700),
    ]
    for i, sd in (("fB2", 2), ("fB4", 4), ("fB8", 8), ("fB16", 16)):
        d.append(f'<filter id="{i}" filterUnits="userSpaceOnUse" x="-200" y="-200" width="{W + 400}" height="{H + 400}">'
                 f'<feGaussianBlur stdDeviation="{sd}"/></filter>')
    # 역광 테두리: seraphina.py fRim과 같은 방식. 빛은 화면 오른쪽 위의 저주 도면에서 와서 오른쪽·위 가장자리에 걸린다
    d.append(f'<filter id="fRim" filterUnits="userSpaceOnUse" x="0" y="0" width="{W}" height="{H}" color-interpolation-filters="sRGB">'
             '<feMorphology in="SourceAlpha" operator="erode" radius="1.1" result="a1"/>'
             '<feMorphology in="SourceAlpha" operator="erode" radius="2.6" result="e"/>'
             '<feOffset in="e" dx="-1.8" dy="1.2" result="e2"/>'
             '<feComposite in="a1" in2="e2" operator="out" result="edge"/>'
             '<feGaussianBlur in="edge" stdDeviation="0.5" result="eb"/>'
             '<feComposite in="eb" in2="a1" operator="in" result="eb2"/>'
             f'<feFlood flood-color="{K["tx4"]}" flood-opacity=".85"/><feComposite in2="eb2" operator="in"/></filter>')
    d.append(f'<mask id="mRim" maskUnits="userSpaceOnUse" x="0" y="0" width="{W}" height="{H}">'
             f'<rect width="{W}" height="{H}" fill="url(#gRimMask)"/></mask>')
    return "<defs>" + "".join(d) + "</defs>"


# ── 배경·효과 ────────────────────────────────────────────────────────

def background():
    """안개 낀 역병 도시의 첨탑 실루엣"""
    s = [f'<rect width="{W}" height="{H}" fill="url(#gBg)"/>',
         f'<rect width="{W}" height="{H}" fill="url(#gFogBand)"/>']
    rnd = random.Random(11)
    for base, col, hmin, hmax in ((800, "#10150b", 90, 200), (860, "#090c06", 40, 150)):  # 먼 줄 → 가까운 줄
        pts, x = [(0, H)], 0
        while x < W:
            w, h = rnd.uniform(36, 90), rnd.uniform(hmin, hmax)
            if 820 < x < 1100:  # 인물 뒤는 낮게 둔다
                h *= .45
            top = base - h
            pts += [(x, top), (x + w * .2, top)]
            if rnd.random() < .35:  # 첨탑
                pts += [(x + w * .35, top - rnd.uniform(30, 90)), (x + w * .5, top)]
            pts += [(x + w, top)]
            x += w
        pts.append((W, H))
        s.append(path(poly(pts), col))
    return "".join(s)


def blueprint():
    """컴퍼스 끝에서 그어지는 공중의 저주 도면: 원호·육각별·눈금·로마 숫자"""
    c, r = BP_C, BP_R
    arc = [pol(c, r, BP_A0 + (BP_A1 - BP_A0) * i / 80) for i in range(81)]
    g = [path(polyline(arc), stroke=K["tx4"], sw=2.6)]
    g.append(path(circ(c, r * .7), stroke=K["tx3"], sw=1.4, extra=' stroke-dasharray="10 7"'))
    g.append(path(circ(c, r * .36), stroke=K["tx4"], sw=1.6))
    # 2026-10-19
    # [동작] 도면 가운데 별은 7각 별({7/3}) 한 붓 그리기
    # [이유] 첫 시안의 육각별(삼각형 둘)은 다윗의 별과 모양이 같아, 역병을 퍼뜨리는 쪽 상징으로 쓰면 오해를 살 수 있어 바꿨다
    g.append(path(poly([pol(c, r * .7, k * 360 / 7 * 3) for k in range(7)]), stroke=K["tx4"], sw=1.6))
    for a in range(math.ceil(BP_A1), math.floor(BP_A0) + 1, 1):  # 원호 바깥 눈금(6도마다, 30도마다 길게)
        if a % 6:
            continue
        big = a % 30 == 0
        g.append(path(f"M{pt(pol(c, r + 4, a))}L{pt(pol(c, r + (16 if big else 9), a))}", stroke=K["tx3"], sw=1.6 if big else 1))
    for k, n in enumerate(("I", "II", "III", "IV", "V", "VI")):
        a = 30 + k * 60
        if (a - BP_A1) % 360 <= BP_A0 - BP_A1:  # 그려진 원호 위에만
            g.append(label(n, *pol(c, r + 34, a), 13, K["tx4"], 700, 1, "middle", central=True, op=.75))
    g.append(path(f"M{pt(c)}L{pt(TIP_B)}", stroke=K["tx3"], sw=1.2, extra=' stroke-dasharray="4 6"'))  # 컴퍼스 반지름
    g.append(path(f"M{c[0] - 14} {c[1]}L{c[0] + 14} {c[1]}M{c[0]} {c[1] - 14}L{c[0]} {c[1] + 14}", stroke=K["tx4"], sw=1.6))
    g.append(path(circ(c, 5), K["tx5"]))
    y = c[1] + r + 54  # 아래 치수선
    g.append(path(f"M{c[0] - r} {y}L{c[0] + r} {y}M{c[0] - r} {y - 8}L{c[0] - r} {y + 8}M{c[0] + r} {y - 8}L{c[0] + r} {y + 8}",
                  stroke=K["tx3"], sw=1.1, op=.7))
    g.append(path(f"M{c[0] - r} {c[1]}L{c[0] - r} {y + 8}M{c[0] + r} {c[1]}L{c[0] + r} {y + 8}", stroke=K["tx3"], sw=.8, op=.35,
                  extra=' stroke-dasharray="3 6"'))
    gg = "".join(g)
    return f'<g filter="url(#fB4)" opacity=".9">{gg}</g><g opacity=".85">{gg}</g>'


def swamp():
    """심연의 늪(R): 발밑 웅덩이·물결·거품"""
    s = ['<ellipse cx="960" cy="1002" rx="640" ry="84" fill="url(#gSwamp)"/>']
    for k, rx in enumerate((150, 230, 330, 450)):
        s.append(f'<ellipse cx="960" cy="996" rx="{rx}" ry="{rx * .11:.1f}" fill="none" stroke="{K["tx3"] if k % 2 else K["tx4"]}" '
                 f'stroke-width="{1.8 - k * .3:.2f}" opacity="{.55 - k * .1:.2f}"/>')
    rnd = random.Random(3)
    for _ in range(26):
        x, y, r = rnd.uniform(420, 1500), rnd.uniform(978, 1030), rnd.uniform(2, 6)
        s.append(f'<ellipse cx="{x:.0f}" cy="{y:.0f}" rx="{r:.1f}" ry="{r * .6:.1f}" fill="none" stroke="{K["tx4"]}" stroke-width="1" opacity=".55"/>')
    g = "".join(s)
    return f'<g filter="url(#fB2)">{g}</g>{g}'


PLUMES = [  # 향로의 독안개(Q) 연기 줄기: (지나는 점, 덩어리 수, 시작·끝 반지름)
    ([(780, 728), (766, 680), (736, 630), (700, 600), (672, 556)], 16, 8, 40),  # 뚜껑 숨구멍에서 피어오른다
    ([(780, 800), (764, 856), (726, 912), (660, 956), (560, 984)], 18, 10, 60),  # 무거워 바닥으로 흘러내린다
]


def mist():
    rnd = random.Random(9)
    soft, puffs = [], []
    for pts, n, r0, r1 in PLUMES:
        q = catmull(pts)
        for i in range(n):
            t = i / (n - 1)
            x, y = q[round(t * (len(q) - 1))]
            r = (r0 + (r1 - r0) * t) * rnd.uniform(.7, 1.2)
            x, y = x + rnd.uniform(-.7, .7) * r, y + rnd.uniform(-.5, .5) * r  # 끝으로 갈수록 넓게 흩어진다
            soft.append(path(circ((x, y), r * 1.8), K["tx3"], op=round(.24 - .12 * t, 2)))
            puffs.append(path(circ((x, y), r), K["tx3"], op=round(.3 - .2 * t, 2))
                         + path(circ((x - r * .3, y - r * .35), r * .5), K["tx4"], op=round(.22 - .16 * t, 2)))
    for x, rx, op in ((620, 280, .4), (1280, 220, .3)):  # 바닥에 깔린 안개
        soft.append(f'<ellipse cx="{x}" cy="996" rx="{rx}" ry="34" fill="{K["tx2"]}" opacity="{op}"/>')
    return f'<g filter="url(#fB16)">{"".join(soft)}</g><g filter="url(#fB8)">{"".join(puffs)}</g>'


def front_fog():
    """인물 앞으로 깔린 늪 안개. 코트 아랫단의 넓은 면을 끊는다"""
    s = "".join(f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="{K[c]}" opacity="{o}"/>' for x, y, rx, ry, c, o in (
        (900, 990, 200, 26, "tx2", .55), (1040, 984, 150, 20, "tx3", .3), (760, 1000, 160, 22, "tx3", .35)))
    return f'<g filter="url(#fB8)">{s}</g>'


def spores():
    """떠다니는 독 포자"""
    rnd = random.Random(7)
    s, n = [], 0
    while n < 130:
        p = (rnd.uniform(360, 1560), rnd.uniform(320, 1040)) if rnd.random() < .75 else (rnd.uniform(300, 1620), rnd.uniform(60, 1040))
        if 910 < p[0] < 1090 and 230 < p[1] < 380:  # 얼굴 앞에는 두지 않는다
            continue
        n += 1
        col = rnd.choice((K["tx3"], K["tx4"], K["tx4"], K["tx5"]))
        s.append(path(circ(p, rnd.uniform(.8, 2.6)), col, op=round(rnd.uniform(.3, .9), 2)))
    g = "".join(s)
    sp = []
    for p, r in ((TIP_B, 26), (BP_C, 10), (pol(BP_C, BP_R, BP_A1), 12)):
        star = poly([pol(p, r if i % 2 == 0 else r * .14, i * 45) for i in range(8)])
        sp.append(f'<g transform="translate({p[0]:.1f} {p[1]:.1f}) scale({r:.1f})"><circle r=".6" fill="url(#gSpark)"/></g>')
        sp.append(path(star, "#ffffff", op=.9))
    return f'<g filter="url(#fB2)">{g}</g>{g}' + "".join(sp)


# ── 인물 ─────────────────────────────────────────────────────────────

def boots():
    s = []
    for x in (934, 990):
        d = smooth([(x - 13, 976, 1), (x + 13, 976, 1), (x + 16, 992), (x + 8, 1000), (x - 8, 1000), (x - 16, 992)])
        s.append(cel(d, "url(#gGlove)", [(smooth([(x, 976), (x + 30, 976), (x + 30, 1004), (x, 1004)]), "#000", .35)], 1.6))
        s.append(path(f"M{x - 13} 986L{x + 13} 986", stroke=K["bn1"], sw=2.4))
    return "".join(s)


COAT_L = [(902, 372), (894, 430), (900, 500), (912, 562, 1), (898, 640), (876, 740), (852, 840), (830, 930), (816, 980, 1)]
HEM = [(816, 980, 1), (850, 988), (884, 982), (918, 990), (952, 984), (986, 990), (1020, 984), (1054, 990), (1088, 982), (1104, 980, 1)]
OPEN = [(960, 600, 1), (968, 680), (982, 800), (996, 920), (1006, 988, 1), (914, 988, 1), (924, 920), (938, 800), (952, 680)]


def coat():
    """밀랍 먹인 긴 가죽 코트. 허리 아래가 갈라져 안감이 보인다"""
    pts = COAT_L + HEM[1:-1] + mirror(COAT_L)[::-1] + [(990, 342), (960, 338), (930, 342)]
    shades = [(smooth([(968, 340), (1060, 340), (1130, 1000), (1000, 1000), (990, 700), (976, 500)]), K["lea0"], .55),
              (smooth([(900, 380), (916, 380), (904, 600), (848, 960), (826, 960), (870, 700)]), K["lea4"], .45)]
    sheen = "".join(path(smooth(p, False), stroke=K["lea4"], sw=w, op=o) for p, w, o in (  # 밀랍 광택
        ([(906, 620), (884, 760), (862, 900)], 5, .35), ([(918, 640), (900, 780), (884, 920)], 2, .4), ([(1030, 680), (1048, 800)], 3, .2)))
    folds = "".join(path(smooth(f, False), stroke=K["lea0"], sw=2.2, op=.8) for f in (
        [(930, 620), (906, 800), (888, 980)], [(1000, 640), (1030, 820), (1050, 984)], [(1020, 660), (1062, 840), (1080, 984)]))
    stitch = path(smooth([(p[0], p[1] - 14) for p in HEM], False), stroke=K["lea4"], sw=1.2, op=.7, extra=' stroke-dasharray="5 5"')
    inner = cel(smooth(OPEN), K["lea0"], [(smooth([(960, 600), (1010, 600), (1010, 990), (966, 990)]), "#000", .4)], 1.8,
                inner="".join(path(smooth(f, False), stroke=K["lea2"], sw=1.6, op=.6) for f in ([(952, 720), (944, 860), (936, 980)], [(970, 740), (982, 880), (990, 980)])))
    edge = (path(smooth(OPEN[1:5], False), stroke=K["lea4"], sw=1.4, op=.7, extra=' stroke-dasharray="5 5"')
            + path(smooth(OPEN[5:] + [OPEN[0]], False), stroke=K["lea4"], sw=1.4, op=.7, extra=' stroke-dasharray="5 5"'))
    return cel(smooth(pts), "url(#gLeather)", shades, 2.2, inner=sheen + folds + stitch) + inner + edge


def straps():
    """가슴 끈 둘·허리띠·약병"""
    s = [path("M960 486L960 602", stroke=K["lea0"], sw=2.4)]
    for y in (518, 546):
        d = smooth([(906, y - 2), (960, y + 4), (1014, y - 2)], False)
        s.append(path(d, stroke=K["ink"], sw=9) + path(d, stroke=K["lea1"], sw=6.5) + path(d, stroke=K["lea4"], sw=1, op=.6))
        s.append(f'<rect x="955" y="{y - 2}" width="11" height="11" rx="2" fill="url(#gCenser)" stroke="{K["ink"]}" stroke-width="1.3"/>'
                 f'<rect x="958.5" y="{y + 1.5}" width="4" height="4" fill="{K["lea0"]}"/>')
    belt = smooth([(906, 562), (960, 572), (1014, 562)], False)
    s.append(path(belt, stroke=K["ink"], sw=15) + path(belt, stroke=K["lea1"], sw=11.5) + path(belt, stroke=K["lea4"], sw=1.2, op=.6))
    s.append(f'<rect x="949" y="562" width="22" height="20" rx="3" fill="url(#gBrass)" stroke="{K["ink"]}" stroke-width="1.6"/>'
             f'<rect x="955" y="567" width="10" height="10" rx="1" fill="{K["lea0"]}"/>')
    for x, y, h in ((992, 578, 26), (1008, 574, 22), (1022, 568, 18)):  # 오른 허리의 약병
        s.append(f'<g filter="url(#fB4)" opacity=".6">{path(circ((x, y + h * .6), 9), K["tx4"])}</g>')
        s.append(f'<rect x="{x - 4.5}" y="{y}" width="9" height="{h}" rx="4" fill="#0e140a" fill-opacity=".7" stroke="{K["ink"]}" stroke-width="1.4"/>'
                 f'<rect x="{x - 3}" y="{y + h * .35:.1f}" width="6" height="{h * .6:.1f}" rx="3" fill="url(#gVial)"/>'
                 f'<rect x="{x - 3.5}" y="{y - 5}" width="7" height="6" rx="1" fill="{K["br2"]}" stroke="{K["ink"]}" stroke-width="1"/>'
                 + path(f"M{x - 2} {y + 4}L{x - 2} {y + h - 6}", stroke="#ffffff", sw=1, op=.5))
    return "".join(s)


def sleeve(sh, el, wr):
    """위팔(망토 아래)·아래팔 소매. 헐렁한 코트 소매라 굵다"""
    up = cel(limb(sh, el, 28, 26, 4), "url(#gLeather)", [(limb(along(sh, el, 0, 13), along(sh, el, 1, 12), 14, 13), K["lea0"], .5)], 2)
    lo = cel(limb(el, wr, 26, 20, 3), "url(#gLeather)", [(limb(along(el, wr, 0, 12), along(el, wr, 1, 9), 13, 10), K["lea0"], .5),
                                                         (limb(along(el, wr, .1, -16), along(el, wr, .7, -13), 3, 2), K["lea4"], .5)], 2)
    return up + lo


def cuff(el, wr):
    """벌어진 장갑 소맷부리"""
    d = poly([along(el, wr, .76, -22), along(el, wr, .76, 22), along(el, wr, 1.05, 15), along(el, wr, 1.05, -15)])
    return cel(d, "url(#gGlove)", [], 1.8, inner=path(f"M{pt(along(el, wr, .82, -21))}L{pt(along(el, wr, .82, 21))}", stroke=K["glove_h"], sw=1.6))


ARM_C = ((884, 420), (850, 518), (812, 592))  # 향로를 든 오른팔(화면 왼쪽): 어깨·팔꿈치·손목
ARM_P = ((1036, 420), (1084, 522), (1120, 470))  # 컴퍼스를 든 왼팔(화면 오른쪽)


def fist(c, r, rot_):
    """가죽 장갑 주먹. 손가락 마디 선 셋"""
    pts = rot([(c[0] - r, c[1] - r * .7), (c[0], c[1] - r), (c[0] + r * .9, c[1] - r * .6), (c[0] + r, c[1] + r * .2),
               (c[0] + r * .6, c[1] + r * .9), (c[0] - r * .3, c[1] + r), (c[0] - r * .95, c[1] + r * .4)], c, rot_)
    knuck = "".join(path(polyline(rot([(c[0] - r * .9, c[1] + y), (c[0] - r * .1, c[1] + y + 1.5)], c, rot_)), stroke=K["glove_h"], sw=1.2)
                    for y in (-r * .35, r * .1, r * .55))
    return cel(smooth(pts), "url(#gGlove)", [(circ((c[0] - r * .35, c[1] - r * .45), r * .4), K["glove_h"], .5)], 1.6, inner=knuck)


def capelet():
    """어깨 망토. 아랫단에 뼈색 징"""
    left = [(960, 330), (934, 334), (906, 348), (878, 370), (858, 402), (848, 442), (842, 486, 1), (872, 492), (900, 482), (930, 494), (960, 486)]
    pts = left + mirror(left[1:-1])[::-1]
    shades = [(smooth([(966, 326), (1050, 340), (1100, 500), (972, 500)]), K["lea0"], .6),
              (smooth([(880, 372), (920, 350), (912, 380), (870, 430)]), K["lea4"], .55)]
    hem = [p[:2] for p in left[6:]] + [p[:2] for p in mirror(left[6:-1])[::-1]]
    stitch = path(smooth([(x, y - 12) for x, y in hem], False), stroke=K["lea4"], sw=1.2, op=.7, extra=' stroke-dasharray="5 5"')
    s = cel(smooth(pts), "url(#gLeather)", shades, 2.2, inner=stitch)
    for x, y in hem[::2]:
        s += path(circ((x, y - 5), 2.6), K["bn2"], K["ink"], .8)
    return s


def hood():
    """가면 뒤를 감싼 가죽 두건. 위는 모자 챙 그늘"""
    pts = [(924, 236), (918, 270), (920, 302), (930, 328), (950, 344), (974, 344), (994, 330), (1002, 302), (1002, 268), (996, 236)]
    shades = [(smooth([(900, 230), (1020, 230), (1020, 276), (900, 268)]), "#000", .55),
              (smooth([(976, 230), (1010, 230), (1010, 350), (980, 350)]), K["lea0"], .5)]
    seam = path(smooth([(926, 300), (940, 320), (960, 330)], False), stroke=K["lea4"], sw=1.2, op=.6, extra=' stroke-dasharray="4 4"')
    return cel(smooth(pts), "url(#gLeatherV)", shades, 2, inner=seam)


def lenses():
    s = []
    for c, rx, ry, g in ((L1, 12, 12, "gLens1"), (L2, 7.5, 11, "gLens2")):
        s.append(f'<g filter="url(#fB4)">{path(smooth(ell(c, rx + 6, ry + 6)), K["tx4"], op=.7)}</g>')
        s.append(cel(smooth(ell(c, rx + 3.5, ry + 3.5)), "url(#gBrass)", [], 1.6))
        s.append(cel(smooth(ell(c, rx, ry)), f"url(#{g})", [(smooth(ell((c[0] + 3, c[1] + 4), rx, ry)), K["tx2"], .45)], 1.2))
        s.append(path(circ((c[0] - rx * .35, c[1] - ry * .4), rx * .22), "#ffffff", op=.85))
    return "".join(s)


BEAK = [(962, 282), (986, 290), (1010, 304), (1034, 320), (1054, 338), (1068, 356), (1076, 370, 1), (1062, 362), (1042, 350),
        (1016, 338), (992, 328), (970, 318), (956, 304)]


def beak():
    """뼈색 새부리 가면. 아래쪽 그늘, 가운데 솔기, 숨구멍, 뿌리를 감은 가죽 띠"""
    shades = [(smooth([(956, 306), (1000, 318), (1080, 368), (1080, 390), (950, 340)]), K["bn1"], .75),
              (smooth([(964, 284), (1010, 302), (1050, 330), (1048, 336), (1004, 310), (962, 292)]), K["bn4"], .7)]
    seam = path(smooth([(962, 296), (1000, 314), (1040, 338), (1072, 366)], False), stroke=K["bn0"], sw=1.4, op=.8)
    holes = "".join(f'<ellipse cx="{x}" cy="{y}" rx="2.6" ry="1.6" transform="rotate(30 {x} {y})" fill="{K["ink"]}"/>' for x, y in ((990, 300), (999, 305)))
    s = cel(smooth(BEAK), "url(#gBone)", shades, 1.8, inner=seam + holes)
    strap = smooth([(968, 281, 1), (975, 283, 1), (969, 322, 1), (962, 319, 1)])  # 부리 뿌리를 감은 좁은 가죽 띠
    s += cel(strap, K["lea2"], [], 1.2) + path(circ((970.5, 301), 1.8), K["bn2"], K["ink"], .6)
    return s


def hat():
    """챙 넓은 모자: 처진 챙 → 높은 운두(윗면이 살짝 꺼졌다) → 띠·버클"""
    brim = [(x, y + 9 * (math.cos(math.radians(i * 15))) ** 2) for i, (x, y) in enumerate(ell(HAT, 162, 30))]  # 양옆이 처진다
    brim = rot(brim, HAT, TILT)
    under = rot([(800, 236), (960, 250), (1122, 236), (1122, 270), (800, 270)], HAT, TILT)
    s = [cel(smooth(brim), "url(#gHat)", [(smooth(under), "#000", .5),
                                          (smooth(rot([(830, 220), (900, 206), (900, 214), (840, 232)], HAT, TILT)), K["lea4"], .6)], 2.2)]
    front = ell(HAT, 60, 11, 0, 180, 10)
    crown = [(900, 228, 1), (903, 186), (909, 150), (918, 128), (940, 117), (960, 126), (980, 117), (1002, 128), (1011, 150), (1017, 186), (1020, 228, 1)] + front[1:-1]
    s.append(cel(smooth(rot(crown, HAT, TILT)), "url(#gHat)",
                 [(smooth(rot([(975, 110), (1030, 110), (1030, 240), (985, 240)], HAT, TILT)), K["lea0"], .6),
                  (smooth(rot([(912, 140), (924, 126), (930, 200), (914, 210)], HAT, TILT)), K["lea4"], .5)], 2.2))
    band = rot(ell(HAT, 60.5, 11, 0, 180, 12) + [(x, y - 17) for x, y in ell(HAT, 59.5, 11, 0, 180, 12)][::-1], HAT, TILT)
    s.append(cel(poly(band), K["lea0"], [], 1.6, inner=path(polyline(rot([(x, y - 15) for x, y in ell(HAT, 59.5, 11, 0, 180, 12)], HAT, TILT)), stroke=K["lea3"], sw=1.2)))
    b = rot([(918, 231)], HAT, TILT)[0]  # 앞 왼쪽 버클
    s.append(f'<rect x="{b[0] - 8:.1f}" y="{b[1] - 9:.1f}" width="16" height="16" rx="2" transform="rotate({TILT} {b[0]:.1f} {b[1]:.1f})" '
             f'fill="none" stroke="url(#gBrass)" stroke-width="3.2"/>')
    return "".join(s)


def censer():
    """사슬에 매달린 독 향로. 구멍마다 독빛이 샌다"""
    hand = (806, 618)
    top = (CEN[0], CEN[1] - 52)
    s = []
    n = int(math.dist(hand, top) // 9)
    for i in range(n + 1):  # 사슬 고리(앞면·옆면 번갈아)
        p = along(hand, top, i / n)
        ang = math.degrees(math.atan2(top[1] - hand[1], top[0] - hand[0]))
        rx, ry = (5, 3) if i % 2 == 0 else (5, 1.2)
        s.append(f'<ellipse cx="{p[0]:.1f}" cy="{p[1]:.1f}" rx="{rx}" ry="{ry}" transform="rotate({ang:.1f} {p[0]:.1f} {p[1]:.1f})" '
                 f'fill="none" stroke="{K["br2"]}" stroke-width="1.8"/>')
    s.append(f'<g transform="translate({CEN[0]} {CEN[1]}) scale(110)" opacity=".7"><circle r="1" fill="url(#gGlow)"/></g>')
    body = smooth(ell(CEN, 31, 27))
    holes = ""
    for a in range(-60, 61, 30):  # 띠 위아래로 뚫린 물방울 구멍
        for dy, sz in ((-11, 1), (12, .8)):
            x, y = CEN[0] + a * .4, CEN[1] + dy * (1 - abs(a) / 200)
            drop = smooth([(x, y - 5 * sz, 1), (x + 3 * sz, y + 1), (x, y + 4 * sz), (x - 3 * sz, y + 1)])
            holes += path(drop, K["ink"]) + path(smooth([(x, y - 3 * sz, 1), (x + 1.8 * sz, y + 1), (x, y + 2.6 * sz), (x - 1.8 * sz, y + 1)]), "url(#gCenserIn)")
    s.append(cel(body, "url(#gCenser)", [(smooth(ell((CEN[0] + 10, CEN[1] + 8), 30, 25)), "#2a1606", .6)], 1.8, inner=holes))
    s.append(path(smooth(ell(CEN, 31, 5, 0, 180, 10), False), stroke=K["ink"], sw=5) + path(smooth(ell(CEN, 31, 5, 0, 180, 10), False), stroke=K["br2"], sw=2.4))
    lid = smooth([(CEN[0] - 24, CEN[1] - 18, 1), (CEN[0] - 18, CEN[1] - 34), (CEN[0], CEN[1] - 44), (CEN[0] + 18, CEN[1] - 34), (CEN[0] + 24, CEN[1] - 18, 1)])
    s.append(cel(lid, "url(#gCenser)", [(smooth([(CEN[0] + 2, CEN[1] - 50), (CEN[0] + 30, CEN[1] - 40), (CEN[0] + 30, CEN[1] - 14), (CEN[0] + 2, CEN[1] - 14)]), "#2a1606", .5)], 1.6))
    for a in (-60, -20, 20, 60):  # 뚜껑 숨구멍
        p = (CEN[0] + a * .28, CEN[1] - 30 - (1 - abs(a) / 60) * 6)
        s.append(f'<ellipse cx="{p[0]:.1f}" cy="{p[1]:.1f}" rx="2" ry="4" fill="url(#gCenserIn)"/>')
    s.append(path(circ(top, 5), "none", K["br3"], 2.2) + path(circ(top, 5), "none", K["ink"], .8))
    s.append(path(poly([(CEN[0] - 6, CEN[1] + 25), (CEN[0] + 6, CEN[1] + 25), (CEN[0], CEN[1] + 44)]), "url(#gCenser)", K["ink"], 1.2))
    return "".join(s)


def compass():
    """도면을 긋는 놋쇠 컴퍼스: 경첩·뼈 손잡이·두 다리·바늘 끝"""
    s = []
    for tip, w in ((TIP_A, 4.5), (TIP_B, 4.5)):
        d = poly([along(HINGE, tip, 0, -w), along(HINGE, tip, 0, w), along(HINGE, tip, .86, 2), along(HINGE, tip, .86, -2)])
        s.append(path(d, "url(#gBrass)", K["ink"], 1.3))
        s.append(path(f"M{pt(along(HINGE, tip, .86))}L{pt(tip)}", stroke=K["ink"], sw=3.2) + path(f"M{pt(along(HINGE, tip, .86))}L{pt(tip)}", stroke=K["bn4"], sw=1.4))
    arc = [along(HINGE, TIP_A, .55), along(HINGE, (HINGE[0] + 6, HINGE[1] + 80), .55), along(HINGE, TIP_B, .55)]  # 벌림 고정 원호
    s.append(path(smooth(arc, False), stroke=K["ink"], sw=3.4) + path(smooth(arc, False), stroke=K["br3"], sw=1.6))
    s.append(path(circ(HINGE, 8), "url(#gBrass)", K["ink"], 1.4) + path(circ(HINGE, 3), K["br1"]))
    s.append(cel(limb((HINGE[0] + 1, HINGE[1] - 8), (HINGE[0] + 3, HINGE[1] - 30), 4.2, 5), "url(#gBone)", [], 1.3))
    s.append(f'<g transform="translate({TIP_B[0]} {TIP_B[1]}) scale(40)" opacity=".9"><circle r="1" fill="url(#gGlow)"/></g>')
    return "".join(s)


def hero():
    parts = [boots(), coat(), straps(), sleeve(*ARM_C), sleeve(*ARM_P), capelet(), cuff(*ARM_C[1:]), cuff(*ARM_P[1:]),
             hood(), lenses(), beak(), hat(), censer(), fist((806, 606), 17, 20), compass(), fist((1130, 448), 16, -30)]
    return '<g id="hero">' + "".join(parts) + "</g>"


def fill_light():
    """인물 실루엣 안에만 오른쪽 도면빛과 왼쪽 아래 향로빛을 얹어 부피를 살린다"""
    return (f'<filter id="fWhite"><feColorMatrix type="matrix" values="0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 1 0"/></filter>'
            f'<mask id="mHero" maskUnits="userSpaceOnUse" x="0" y="0" width="{W}" height="{H}"><use href="#hero" filter="url(#fWhite)"/></mask>'
            + rad("gFillR", [(0, K["tx4"], .2), (.5, K["tx3"], .06), (1, K["tx3"], 0)], BP_C[0], BP_C[1], 520)
            + rad("gFillC", [(0, K["tx4"], .3), (.5, K["tx3"], .08), (1, K["tx3"], 0)], CEN[0], CEN[1], 300)
            + f'<g mask="url(#mHero)" style="mix-blend-mode:screen"><rect width="{W}" height="{H}" fill="url(#gFillR)"/>'
              f'<rect width="{W}" height="{H}" fill="url(#gFillC)"/></g>')


# ── 컨셉 시트 ─────────────────────────────────────────────────────────

def ornament(x0, x1, y):
    m = (x0 + x1) / 2
    return (path(f"M{x0} {y}L{m - 16} {y}M{m + 16} {y}L{x1} {y}", stroke=K["bn2"], sw=1.2, op=.8)
            + diamond((m, y), 7, K["bn3"]) + diamond((m, y), 3, K["tx3"])
            + diamond((m - 24, y), 3, K["tx4"]) + diamond((m + 24, y), 3, K["tx4"]))


INSETS = [  # (원 중심, 반지름, 보는 곳, 배율, 제목, 설명)
    ((1716, 236), 92, (994, 300), 1.6, "THE BEAKED MASK", "venom lenses · bone beak"),
    ((1716, 520), 92, (784, 740), 1.45, "PLAGUE CENSER", "corrosive mist · soul chain"),
    ((1716, 804), 92, (1150, 500), 1.3, "CURSE COMPASS", "blueprint of ruin"),
]
PALETTE = [("LEATHER", K["lea1"], True), ("HIDE", K["lea2"], True), ("WAX", K["lea4"], True), ("BONE", K["bn3"], True),
           ("SHADE", K["bn1"], True), ("TOXIN", K["tx2"], True), ("MIRE", K["tx1"], True), ("VENOM", K["tx4"], False)]


def sheet():
    s = [label("HERO CONCEPT", 74, 104, 14, K["tx4"], 700, 5),
         lin("gTitle", [(0, K["bn4"]), (.55, K["bn3"]), (1, K["tx4"])], x2=0, y2=1),
         f'<g filter="url(#fB8)" opacity=".5">{label("VESPER", 70, 184, 60, K["tx3"], 700, 7)}</g>',
         label("VESPER", 70, 184, 60, "url(#gTitle)", 700, 7),
         label("ARCHITECT OF THE SHADOW PLAGUE", 74, 220, 19, K["bn3"], 700, 3.4),
         ornament(74, 470, 244),
         label("PLAGUE DEBUFFER · CONTROL", 74, 278, 15, K["tx4"], 700, 4),
         label("“Every plague begins on paper.”", 74, 308, 15, K["bn4"], 500, 1, op=.78)]
    for k, (c, r, f, z, t, sub) in enumerate(INSETS):
        s.append(f'<clipPath id="ins{k}"><circle cx="{c[0]}" cy="{c[1]}" r="{r}"/></clipPath>')
        s.append(path(circ(c, r + 18), K["tx3"], op=.08))
        s.append(f'<circle cx="{c[0]}" cy="{c[1]}" r="{r}" fill="#050604"/>')
        s.append(f'<g clip-path="url(#ins{k})"><use href="#scene" transform="translate({c[0]} {c[1]}) scale({z}) translate({-f[0]:.1f} {-f[1]:.1f})"/></g>')
        s.append(path(circ(c, r), stroke=K["bn2"], sw=2.6))
        s.append(path(circ(c, r + 7), stroke=K["bn2"], sw=.9, op=.6))
        for i in range(24):
            s.append(path(f"M{pt(pol(c, r + 3, i * 15))}L{pt(pol(c, r + 7 + (3 if i % 6 == 0 else 0), i * 15))}", stroke=K["tx4"], sw=1.6 if i % 6 == 0 else .9))
        s.append(diamond((c[0], c[1] - r - 7), 6, K["bn3"]))
        s.append(label(t, c[0], c[1] + r + 38, 15, K["bn3"], 700, 3, "middle"))
        s.append(label(sub, c[0], c[1] + r + 60, 13, K["bn4"], 500, 1.2, "middle", op=.72))
    s.append(label("PALETTE", 74, 930, 13, K["tx4"], 700, 4))
    for k, (n, col, f24) in enumerate(PALETTE):
        x = 74 + k * 62
        s.append(f'<rect x="{x}" y="944" width="44" height="44" rx="6" fill="{col}" stroke="{K["bn2"]}" stroke-width="1.2"/>')
        if f24:
            s.append(diamond((x + 37, 951), 3.6, K["ink"]) + diamond((x + 37, 951), 2.2, K["bn4"]))
        s.append(label(col.upper(), x + 22, 1006, 10, K["bn4"], 500, .6, "middle", op=.8))
        s.append(label(n, x + 22, 1022, 9, K["bn3"], 700, .8, "middle", op=.8))
    s.append(diamond((80, 1046), 3.6, K["ink"]) + diamond((80, 1046), 2.2, K["bn4"]))
    s.append(label("= f24p in-game palette color", 92, 1050, 10, K["bn4"], 500, .6, op=.6))
    return "".join(s)


def build(sheet_on=True):
    chronos._cid[0] = 0
    scene = [background(), blueprint(), swamp(), mist(),
             '<ellipse cx="960" cy="998" rx="180" ry="14" fill="#000" opacity=".6" filter="url(#fB4)"/>',
             hero(),
             '<g mask="url(#mRim)" style="mix-blend-mode:screen"><use href="#hero" filter="url(#fRim)"/></g>',
             fill_light(), front_fog(), spores(),
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
    for name, on in (("vesper", True), ("vesper_clean", False)):  # 컨셉 시트 / 그림만
        svg = out / f"{name}.svg"
        svg.write_text(build(on), encoding="utf-8")
        print(svg)
        if not a.no_png:
            print(shot.shot(svg, out / f"{name}_{W * a.scale}.png", a.scale))
