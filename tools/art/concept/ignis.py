# 영웅 컨셉 아트 — 이그니스, 원소의 지배자(Ignis, Master of the Elements). 맨손으로 원소를 부리는 마법사
# 형체를 SVG 벡터로 직접 그리고(Claude 제작) shot.py로 PNG를 찍는다. 그리는 도구(곡선·셀 음영·글자)는 chronos.py, 타원·회전은 vesper.py의 것을 쓴다.
# 색 뼈대는 주홍 로브·숯빛 안감·금이고, 구슬에 서리 청·비전 청록을 얹는다(K에 f24p 색을 표시했다). 24px로 옮길 때 같은 색을 쓰려는 것이다
# 사용: python tools/art/concept/ignis.py [--out 폴더] [--scale 2] [--no-png]
#   → ignis.svg(컨셉 시트)·ignis_clean.svg(그림만)와 PNG(가로 1920 × scale px: 2 = 4K, 4 = 8K)
import argparse
import math
import random
from pathlib import Path

import chronos
import shot
from chronos import W, H, along, catmull, cel, circ, diamond, label, limb, lin, path, poly, pol, pt, rad, ribbon, smooth, unit
from vesper import ell, polyline, rot

OUT = Path(__file__).resolve().parents[3] / "art" / "concept" / "ignis"

K = {
    "ink": "#12080a",
    "rb0": "#300f0a", "rb1": "#550f0a", "rb2": "#9b1a0a", "rb3": "#ef3a0c", "rb4": "#ff6e3c", "rb5": "#ffa47a",  # 주홍 로브. rb0~3 = f24p
    "or2": "#ef692f", "or3": "#efb775",  # 불꽃 주황. 모두 f24p
    "gold0": "#4a2a0c", "gold1": "#ab5c1c", "gold2": "#d48b24", "gold3": "#efac28", "gold4": "#efd8a1", "gold5": "#fff5da",  # gold1·3·4 = f24p
    "ch0": "#151a26", "ch1": "#262d3d", "ch2": "#3a4357", "ch3": "#56607a",  # 숯빛 안감. 모두 f24p
    "fr1": "#4f78ad", "fr2": "#a4aec2", "fr3": "#d0d6e0", "fr4": "#eef6ff",  # 서리. fr1~3 = f24p
    "ar0": "#276468", "ar1": "#3c9f9c", "ar2": "#7fe6dc", "ar3": "#e2fffb",  # 비전. ar0·1 = f24p
    "skin": "#f6d1b2", "skin_s": "#dca386", "skin_d": "#a56243", "skin_h": "#fde6d2", "lip": "#d9715e",  # skin_d = f24p
    "hair_s": "#ab5c1c",
}
FB, FB_R = (772, 206), 42  # 든 손 위에 뜬 화염구(Q)
ARM_UP = ((906, 386), (842, 352), (800, 282))  # 화염구를 든 오른팔(화면 왼쪽): 어깨·팔꿈치·손목
ARM_DN = ((1014, 386), (1066, 462), (1118, 526))  # 서리를 흘리는 왼팔(화면 오른쪽)
ORB_C, ORB_RX, ORB_RY, ORB_TILT = (960, 600), 270, 60, 10  # 원소 구슬 궤도(+ 기울기 = 화면 왼쪽이 올라간다)
ORBS = [(200, "arcane"), (100, "fire"), (20, "frost")]  # (궤도 각, 원소). 180~360은 인물 뒤쪽 반
HEAD_TILT = -4  # 고개를 화염구 쪽으로 기울인다


def tongue(b, w, t, sway=0.0, n=6):
    """밑 가운데 b(폭 w)에서 끝 t로 솟는 불꽃 혀 모양의 점. 끝은 꺾이고 몸통은 sway만큼 휜다"""
    ux, uy = unit(b, t)
    nx, ny = -uy, ux
    left, right = [], []
    for i in range(n):
        s = i / n
        bend = sway * math.sin(math.pi * s)
        cx, cy = b[0] + (t[0] - b[0]) * s + nx * bend, b[1] + (t[1] - b[1]) * s + ny * bend
        hw = w / 2 * (1 - s) ** .7
        left.append((cx - nx * hw, cy - ny * hw))
        right.append((cx + nx * hw, cy + ny * hw))
    return left + [(t[0], t[1], 1)] + right[::-1]


def ring_pt(t, dr=0.0):
    p = (ORB_C[0] + (ORB_RX + dr) * math.cos(math.radians(t)), ORB_C[1] + (ORB_RY + dr * .22) * math.sin(math.radians(t)))
    return rot([p], ORB_C, ORB_TILT)[0]


# ── SVG 정의 ─────────────────────────────────────────────────────────

def defs():
    d = [
        lin("gRobe", [(0, K["rb5"]), (.25, K["rb4"]), (.6, K["rb3"]), (1, K["rb2"])], x2=1, y2=1),
        lin("gRobeV", [(0, K["rb4"]), (.5, K["rb3"]), (1, K["rb2"])]),
        lin("gHemDark", [(0, K["rb1"], 0), (1, K["rb1"], .5)], 0, 740, 0, 1000, user=True),
        lin("gChar", [(0, K["ch2"]), (.5, K["ch1"]), (1, K["ch0"])], x2=1, y2=1),
        lin("gGold", [(0, K["gold5"]), (.3, K["gold3"]), (.7, K["gold2"]), (1, K["gold1"])]),
        lin("gHair", [(0, K["rb3"]), (.4, K["or2"]), (.78, K["gold3"]), (1, K["gold4"])], 0, 330, 0, 112, user=True),
        lin("gSky", [(0, "#090d1b"), (.5, "#131a2e"), (.78, "#2a1c2a"), (1, "#40211c")]),
        rad("gHorizon", [(0, K["or2"], .45), (.4, K["rb2"], .18), (1, K["rb2"], 0)], 1360, 870, 640),
        rad("gFireSky", [(0, K["or3"], .3), (.4, K["rb3"], .1), (1, K["rb3"], 0)], FB[0], FB[1], 620),
        rad("gGround", [(0, "#1d1418"), (.6, "#0d0b10"), (1, "#060508")], 960, 1000, 760),
        rad("gVig", [(0, "#000", 0), (.6, "#000", 0), (1, "#04050a", .74)], 960, 520, 1150),
        rad("gGlowFire", [(0, "#ffffff", .95), (.2, K["gold4"], .75), (.45, K["or2"], .35), (1, K["rb3"], 0)], 0, 0, 1),
        rad("gGlowFrost", [(0, "#ffffff", .9), (.3, K["fr3"], .55), (.6, K["fr1"], .2), (1, K["fr1"], 0)], 0, 0, 1),
        rad("gGlowArc", [(0, K["ar3"], .9), (.3, K["ar2"], .5), (.6, K["ar1"], .2), (1, K["ar0"], 0)], 0, 0, 1),
        rad("gSpark", [(0, "#ffffff"), (.25, K["gold5"], .9), (1, K["gold3"], 0)], 0, 0, 1),
        rad("gFireCore", [(0, "#ffffff"), (.35, K["gold5"]), (.7, K["gold3"]), (1, K["or2"])], FB[0], FB[1] + 4, FB_R * .62),
        rad("gIris", [(0, K["gold5"]), (.5, K["gold3"]), (1, K["gold1"])], 0, 0, 1),
        rad("gRimMask", [(0, "#fff"), (.5, "#c0c0c0"), (1, "#383838")], FB[0], FB[1], 900),
    ]
    for t, kind in ORBS:  # 구슬 몸통(원소마다 중심이 다르다)
        c = ring_pt(t)
        stops = {"fire": [(0, "#ffffff"), (.4, K["gold4"]), (.8, K["or2"]), (1, K["rb3"])],
                 "frost": [(0, "#ffffff"), (.45, K["fr3"]), (.85, K["fr2"]), (1, K["fr1"])],
                 "arcane": [(0, K["ch0"]), (.5, K["ch0"]), (.7, K["ar1"]), (1, K["ar2"])]}[kind]
        d.append(rad(f"gOrb_{kind}", stops, round(c[0] - 3, 1), round(c[1] - 3, 1), 15))
    for i, sd in (("fB2", 2), ("fB4", 4), ("fB8", 8), ("fB16", 16)):
        d.append(f'<filter id="{i}" filterUnits="userSpaceOnUse" x="-200" y="-200" width="{W + 400}" height="{H + 400}">'
                 f'<feGaussianBlur stdDeviation="{sd}"/></filter>')
    # 역광 테두리: vesper.py fRim과 같은 방식. 빛은 화면 왼쪽 위의 화염구에서 와서 왼쪽·위 가장자리에 걸린다
    d.append(f'<filter id="fRim" filterUnits="userSpaceOnUse" x="0" y="0" width="{W}" height="{H}" color-interpolation-filters="sRGB">'
             '<feMorphology in="SourceAlpha" operator="erode" radius="1.1" result="a1"/>'
             '<feMorphology in="SourceAlpha" operator="erode" radius="2.6" result="e"/>'
             '<feOffset in="e" dx="1.8" dy="1.6" result="e2"/>'
             '<feComposite in="a1" in2="e2" operator="out" result="edge"/>'
             '<feGaussianBlur in="edge" stdDeviation="0.5" result="eb"/>'
             '<feComposite in="eb" in2="a1" operator="in" result="eb2"/>'
             f'<feFlood flood-color="{K["gold4"]}" flood-opacity=".9"/><feComposite in2="eb2" operator="in"/></filter>')
    d.append(f'<mask id="mRim" maskUnits="userSpaceOnUse" x="0" y="0" width="{W}" height="{H}">'
             f'<rect width="{W}" height="{H}" fill="url(#gRimMask)"/></mask>')
    return "<defs>" + "".join(d) + "</defs>"


# ── 배경·효과 ────────────────────────────────────────────────────────

METEORS = [((1236, 300), 230, 9), ((1420, 186), 170, 7), ((1110, 118), 120, 5), ((1530, 400), 110, 5)]  # 운석우(R): (머리, 꼬리 길이, 폭)


def background():
    """밤하늘·별·운석우·산줄기·지평선의 용암빛"""
    s = [f'<rect width="{W}" height="{H}" fill="url(#gSky)"/>',
         f'<rect width="{W}" height="{H}" fill="url(#gHorizon)"/>', f'<rect width="{W}" height="{H}" fill="url(#gFireSky)"/>']
    rnd = random.Random(2)
    for _ in range(150):
        x, y = rnd.uniform(0, W), rnd.uniform(0, 700)
        s.append(path(circ((x, y), rnd.uniform(.5, 1.6)), K["fr3"], op=round(rnd.uniform(.2, .8) * (1 - y / 900), 2)))
    for k, (hd, ln, w) in enumerate(METEORS):
        tail = (hd[0] + ln * .8, hd[1] - ln * .6)
        s.append(lin(f"gMet{k}", [(0, K["or2"], 0), (.7, K["or3"], .55), (1, K["gold5"], 1)], tail[0], tail[1], hd[0], hd[1], user=True))
        nx, ny = .6, .8  # 꼬리 방향(.8, -.6)에 수직
        s.append(path(poly([tail, (hd[0] + nx * w, hd[1] + ny * w), (hd[0] - nx * w, hd[1] - ny * w)]), f"url(#gMet{k})"))
        s.append(f'<g transform="translate({hd[0]} {hd[1]}) scale({w * 4})"><circle r="1" fill="url(#gGlowFire)"/></g>')
    for base, col, amp, seed in ((800, "#121420", 70, 4), (860, "#0a0a12", 50, 8)):  # 먼 산줄기 → 가까운 산줄기
        r2, pts, x = random.Random(seed), [(0, H)], 0
        while x <= W:
            pts.append((x, base - r2.uniform(0, amp) - (40 if 1250 < x < 1500 else 0)))
            x += r2.uniform(40, 110)
        pts.append((W, H))
        s.append(path(poly(pts), col))
    s.append('<ellipse cx="1380" cy="852" rx="200" ry="40" fill="#ef692f" opacity=".3" filter="url(#fB16)"/>')  # 운석이 떨어진 자리
    s.append(f'<ellipse cx="960" cy="1010" rx="1100" ry="150" fill="url(#gGround)"/>')
    return "".join(s)


def floor():
    """발밑 원소 문양: 왼쪽 반은 불, 오른쪽 반은 서리(W 서리 고리). 왼쪽에 용암 균열, 오른쪽에 얼음 결정"""
    c = (960, 992)
    s = []
    for k, rx in enumerate((250, 330, 420)):
        ry = rx * .12
        sw = 2.2 - k * .5
        s.append(path(polyline(ell(c, rx, ry, 90, 270, 30)), stroke=K["gold3"] if k != 1 else K["or2"], sw=sw, op=.75 - k * .15))
        s.append(path(polyline(ell(c, rx, ry, -90, 90, 30)), stroke=K["fr3"] if k != 1 else K["fr1"], sw=sw, op=.75 - k * .15))
    for i in range(36):  # 고리 사이 눈금
        a = i * 10
        p0, p1 = ell(c, 330, 39.6, a, a, 1)[0], ell(c, 380, 45.6, a, a, 1)[0]
        warm = 90 < a < 270
        s.append(path(f"M{pt(p0)}L{pt(p1)}", stroke=K["gold4"] if warm else K["fr3"], sw=1.2, op=.6))
    rnd = random.Random(6)
    for _ in range(7):  # 용암 균열
        x, y = rnd.uniform(720, 900), rnd.uniform(984, 1040)
        pts = [(x, y)]
        for _ in range(5):  # 왼쪽 팔레트 글자(x ≤ 552)에 닿지 않게 짧게 뻗는다
            x, y = x - rnd.uniform(10, 28), y + rnd.uniform(-8, 8)
            pts.append((x, y))
        s.append(f'<g filter="url(#fB4)">{path(polyline(pts), stroke=K["or2"], sw=5, op=.7)}</g>' + path(polyline(pts), stroke=K["gold4"], sw=1.4))
    for _ in range(16):  # 얼음 결정
        x, y, h = rnd.uniform(1050, 1380), rnd.uniform(984, 1034), rnd.uniform(10, 30)
        a = rnd.uniform(-30, 30)
        s.append(f'<g transform="translate({x:.0f} {y:.0f}) rotate({a:.0f})">'
                 + path(poly([(0, -h), (h * .22, -h * .3), (0, 0), (-h * .22, -h * .3)]), K["fr3"], K["fr1"], .8, op=.85) + "</g>")
    g = "".join(s)
    return f'<g filter="url(#fB2)">{g}</g>{g}'


def orbit(front):
    """원소 구슬 궤도(뒤쪽 반 또는 앞쪽 반)"""
    a0, a1 = (0, 180) if front else (180, 360)
    pts = [ring_pt(a0 + (a1 - a0) * i / 40) for i in range(41)]
    s = [f'<g filter="url(#fB4)">{path(polyline(pts), stroke=K["gold3"], sw=4, op=.5)}</g>', path(polyline(pts), stroke=K["gold4"], sw=1.4, op=.8)]
    for t, kind in ORBS:
        if (0 <= t <= 180) == front:
            s.append(orb(t, kind))
    return "".join(s)


def orb(t, kind):
    c = ring_pt(t)
    col, glow = {"fire": (K["or2"], "gGlowFire"), "frost": (K["fr3"], "gGlowFrost"), "arcane": (K["ar2"], "gGlowArc")}[kind]
    s = []
    for k in range(10):  # 꼬리: 궤도를 따라 뒤로 흐려진다
        q0, q1 = ring_pt(t - 4 - k * 4), ring_pt(t - k * 4)
        s.append(path(f"M{pt(q0)}L{pt(q1)}", stroke=col, sw=7 - k * .6, op=round(.7 - k * .07, 2)))
    s.append(f'<g transform="translate({c[0]:.1f} {c[1]:.1f}) scale(46)"><circle r="1" fill="url(#{glow})"/></g>')
    if kind == "fire":
        for a in range(-60, 61, 30):
            s.append(path(smooth(tongue(pol(c, 8, a), 12, pol(c, 24 + (12 if a == 0 else 0), a * .6), 3 if a > 0 else -3)), K["or2"], op=.9))
    s.append(path(circ(c, 13), f"url(#gOrb_{kind})", K["ink"], 1.2))
    if kind == "frost":  # 얼음 결정 면
        for a in range(0, 360, 60):
            s.append(path(f"M{pt(c)}L{pt(pol(c, 12, a))}", stroke=K["fr1"], sw=1, op=.7))
        s.append(path(poly([pol(c, 21, a) for a in range(0, 360, 60)]), stroke=K["fr4"], sw=1.2, op=.7))
    if kind == "arcane":  # 블랙홀(E)의 강착 고리
        s.append(f'<ellipse cx="{c[0]:.1f}" cy="{c[1]:.1f}" rx="25" ry="6" transform="rotate(-20 {c[0]:.1f} {c[1]:.1f})" fill="none" '
                 f'stroke="{K["ar2"]}" stroke-width="2" opacity=".9"/>')
    s.append(path(circ((c[0] - 4, c[1] - 4), 2.6), "#ffffff", op=.9))
    return "".join(s)


def fireball():
    """든 손 위에 뜬 화염구: 바깥 혀 → 안쪽 혀 → 핵"""
    s = [f'<g transform="translate({FB[0]} {FB[1]}) scale(170)" opacity=".85"><circle r="1" fill="url(#gGlowFire)"/></g>']
    rnd = random.Random(4)
    for r_in, ln, w, col, op in ((.6, 2.2, 28, K["rb3"], .92), (.5, 1.7, 22, K["or2"], .95), (.35, 1.25, 15, K["gold3"], 1)):
        g = []
        for a in range(-140, 141, 20):
            a += rnd.uniform(-6, 6)
            up = (1 + math.cos(math.radians(a))) / 2  # 위로 갈수록 길다
            tip = pol(FB, FB_R * ln * (.5 + .5 * up) * rnd.uniform(.8, 1.15), a * .55 + 14)  # 끝은 화면 오른쪽 위로 쏠린다
            g.append(path(smooth(tongue(pol(FB, FB_R * r_in, a), w * rnd.uniform(.8, 1.1), tip, rnd.uniform(4, 10))), col, op=op))
        s.append("".join(g))
    for a, r in ((-10, 2.5), (24, 2.3), (6, 2.9)):  # 위로 떨어져 나간 불꽃 조각
        c = pol(FB, FB_R * r, a)
        s.append(path(smooth(tongue((c[0], c[1] + 8), 9, (c[0] + 5, c[1] - 12), 3)), K["or2"], op=.85))
    s.append(path(circ(FB, FB_R * .62), "url(#gFireCore)"))
    for _ in range(26):  # 튀는 불씨
        a, r = rnd.uniform(-80, 80), rnd.uniform(FB_R * 1.3, FB_R * 3.2)
        p = pol(FB, r, a)
        s.append(path(circ(p, rnd.uniform(1, 2.8)), rnd.choice((K["gold4"], K["gold3"], K["or2"])), op=round(rnd.uniform(.5, 1), 2)))
    return "".join(s)


FROST_PATH = [(1150, 566), (1192, 640), (1176, 720), (1214, 800), (1196, 880), (1236, 966)]


def frost():
    """내린 손에서 바닥의 서리 고리까지 휘감아 내리는 얼음 파편·눈발·서리 안개"""
    q = catmull(FROST_PATH)
    rnd = random.Random(12)
    mist = "".join(path(circ((x + rnd.uniform(-30, 30), y), rnd.uniform(18, 40)), K["fr2"], op=.18) for x, y in q[::6])
    s = [f'<g filter="url(#fB16)">{mist}</g>']
    for i in range(4, len(q) - 1, 4):  # 얼음 파편: 진행 방향으로 눕힌 마름모
        x, y = q[i]
        ux, uy = unit(q[i - 1], q[i + 1])
        x, y = x + rnd.uniform(-26, 26), y + rnd.uniform(-10, 10)
        h = rnd.uniform(8, 18)
        d = poly([(x + ux * h, y + uy * h), (x - uy * h * .28, y + ux * h * .28), (x - ux * h, y - uy * h), (x + uy * h * .28, y - ux * h * .28)])
        s.append(path(d, K["fr3"], K["fr1"], .9, op=.9) + path(f"M{x + ux * h:.1f} {y + uy * h:.1f}L{x - ux * h:.1f} {y - uy * h:.1f}", stroke=K["fr4"], sw=.8, op=.8))
    for _ in range(60):
        x, y = q[rnd.randrange(len(q))]
        s.append(path(circ((x + rnd.uniform(-50, 50), y + rnd.uniform(-20, 20)), rnd.uniform(.8, 2.2)), K["fr4"], op=round(rnd.uniform(.4, 1), 2)))
    flake = "".join(path(f"M{pt(pol((1170, 548), 3, a))}L{pt(pol((1170, 548), 14, a))}", stroke=K["fr4"], sw=1.6) for a in range(0, 360, 60))
    s.append(f'<g filter="url(#fB4)">{flake}</g>{flake}')
    return "".join(s)


# ── 인물 ─────────────────────────────────────────────────────────────

def boots():
    s = ""
    for x in (942, 980):
        d = smooth([(x - 10, 980, 1), (x + 10, 980, 1), (x + 12, 992), (x + 4, 1000), (x - 4, 1000), (x - 12, 992)])
        s += cel(d, "url(#gChar)", [], 1.4) + path(f"M{x - 9} 991Q{x} 986 {x + 9} 991", stroke=K["gold3"], sw=2)
    return s


SK_L = [(918, 530, 1), (904, 600), (880, 700), (848, 800), (808, 880), (770, 930), (738, 944, 1)]
SK_R = [(1004, 530, 1), (1022, 620), (1052, 720), (1090, 820), (1136, 890), (1188, 930, 1)]
HEM = [(738, 944, 1), (776, 968), (816, 966), (856, 984), (900, 976), (944, 990), (990, 980), (1036, 990), (1080, 974), (1124, 980), (1160, 958), (1188, 930, 1)]  # 양 끝이 마력에 들려 올라간다
OPEN = [(960, 560, 1), (970, 660), (988, 780), (1004, 900), (1012, 986, 1), (912, 986, 1), (918, 900), (934, 780), (950, 660)]


def skirt():
    """아래에서 치솟는 마력에 부푼 로브 자락. 앞이 갈라져 숯빛 속치마가 보인다"""
    pts = SK_L + HEM[1:-1] + SK_R[::-1]
    shades = [(smooth([(990, 530), (1060, 530), (1200, 960), (1030, 1000), (1010, 760)]), K["rb2"], .6),
              (smooth([(906, 560), (922, 560), (850, 980), (790, 980), (860, 760)]), K["rb5"], .35),
              (smooth([(700, 740), (1220, 740), (1220, 1000), (700, 1000)]), "url(#gHemDark)", 1)]  # 아래로 갈수록 어둡다
    folds = ""
    for f in ([(930, 580), (900, 780), (856, 980)], [(924, 620), (880, 800), (806, 960)], [(1000, 600), (1040, 800), (1080, 976)],
              [(1012, 620), (1066, 810), (1124, 976)], [(1020, 650), (1090, 830), (1160, 956)]):  # 어두운 골 + 옆의 밝은 마루
        folds += path(smooth(f, False), stroke=K["rb1"], sw=2.6, op=.7) + path(smooth([(x - 6, y) for x, y in f], False), stroke=K["rb5"], sw=1.6, op=.45)
    band = [(p[0], p[1] - 22) for p in HEM]
    trim = path(smooth(band, False), stroke=K["gold1"], sw=12) + path(smooth(band, False), stroke=K["gold3"], sw=7.5)
    for x in range(770, 1170, 42):  # 금 띠의 불꽃 무늬
        y = min(band, key=lambda p: abs(p[0] - x))[1]
        trim += path(smooth(tongue((x, y + 2), 9, (x + 2, y - 12), 2)), K["rb3"]) + path(circ((x, y + 1), 2), K["gold5"])
    inner = cel(smooth(OPEN), "url(#gChar)", [(smooth([(960, 560), (1014, 560), (1014, 990), (968, 990)]), K["ch0"], .5)], 1.8,
                inner=path(smooth([(p[0], p[1] - 14) for p in OPEN[4:6]], False), stroke=K["gold3"], sw=4))
    edge = path(smooth(OPEN[:5], False), stroke=K["gold3"], sw=3) + path(smooth([OPEN[0]] + OPEN[5:][::-1], False), stroke=K["gold3"], sw=3)
    return cel(smooth(pts), "url(#gRobe)", shades, 2.2, inner=folds + trim) + inner + edge


def bodice():
    """몸판: 숯빛 속옷 위 V 깃, 금 테, 불 보석 브로치"""
    under = cel(smooth([(940, 344, 1), (980, 344, 1), (984, 380), (960, 410), (936, 380)]), K["ch1"], [], 1.4)
    pts = [(898, 372, 1), (896, 420), (906, 470), (920, 528, 1), (1000, 528, 1), (1014, 470), (1024, 420), (1022, 372, 1), (996, 360),
           (976, 352, 1), (960, 404, 1), (944, 352, 1), (924, 360)]
    shades = [(smooth([(985, 356), (1040, 356), (1040, 532), (996, 532), (1006, 450)]), K["rb2"], .55),
              (smooth([(904, 380), (930, 366), (922, 430), (906, 440)]), K["rb5"], .5)]
    trim = (path(smooth([(944, 352, 1), (960, 404, 1), (976, 352, 1)], False), stroke=K["gold1"], sw=6) + path("M944 352L960 404L976 352", stroke=K["gold3"], sw=3.4)
            + path("M960 404L960 528", stroke=K["gold1"], sw=5) + path("M960 404L960 528", stroke=K["gold3"], sw=2.4))
    brooch = (path(circ((960, 410), 9), "url(#gGold)", K["ink"], 1.2) + path(circ((960, 410), 5.5), K["rb3"], K["gold0"], 1)
              + path(circ((958, 408), 1.8), "#ffffff", op=.9))
    return under + cel(smooth(pts), "url(#gRobe)", shades, 2.2, inner=trim) + brooch


def belt():
    band = smooth([(918, 526), (960, 538), (1002, 526)], False)
    s = path(band, stroke=K["ink"], sw=15) + path(band, stroke=K["gold2"], sw=11.5) + path(band, stroke=K["gold5"], sw=1.4, op=.7)
    for x, y, col in ((936, 532, K["rb3"]), (960, 537, K["ar1"]), (984, 532, K["fr1"])):  # 불·비전·서리 보석
        s += diamond((x, y), 8, K["gold0"]) + diamond((x, y), 6, col) + path(circ((x - 1.5, y - 2), 1.4), "#ffffff", op=.9)
    return s


def collar():
    """목 뒤로 선 숯빛 깃. 위 테두리는 금"""
    d = smooth([(924, 318, 1), (942, 334), (960, 338), (978, 334), (996, 318, 1), (1004, 342), (994, 364), (960, 372), (926, 364), (916, 342)])
    edge = smooth([(924, 318), (942, 334), (960, 338), (978, 334), (996, 318)], False)
    return cel(d, "url(#gChar)", [], 1.8) + path(edge, stroke=K["gold1"], sw=5) + path(edge, stroke=K["gold3"], sw=2.4)


def neck():
    return cel(smooth([(949, 304, 1), (971, 304, 1), (974, 352, 1), (946, 352, 1)]), K["skin"],
               [(smooth([(940, 298), (980, 298), (980, 322), (960, 330), (940, 322)]), K["skin_s"], .9)], 1.6)


HAIR = [(926, 318), (912, 290), (906, 256), (884, 222, 1), (910, 226), (910, 190), (896, 146, 1), (930, 176), (944, 132), (958, 100, 1),
        (972, 150), (998, 128), (1022, 108, 1), (1010, 160), (1036, 162), (1066, 152, 1), (1030, 204), (1060, 228, 1), (1014, 244),
        (1008, 280), (996, 318), (960, 302)]  # 위로 타오르는 뒷머리 한 덩어리: 끝 여섯이 화면 오른쪽으로 휜다
HAIR_FLOW = [[(930, 300), (920, 250), (900, 226)], [(940, 260), (928, 200), (904, 156)], [(956, 240), (952, 170), (958, 112)],
             [(972, 236), (990, 170), (1016, 118)], [(986, 250), (1020, 200), (1058, 160)], [(996, 280), (1024, 246), (1052, 230)]]


def hair_back():
    """불꽃처럼 위로 솟는 뒷머리. 결은 끝을 향해 흐르고 끝일수록 밝다"""
    flow = "".join(path(smooth(f, False), stroke=K["hair_s"], sw=1.6, op=.55) + path(smooth([(x + 5, y + 2) for x, y in f], False), stroke=K["gold4"], sw=1.4, op=.45)
                   for f in HAIR_FLOW)
    return cel(smooth(HAIR), "url(#gHair)", [(smooth([(990, 220), (1060, 220), (1060, 330), (990, 330)]), K["rb2"], .45)], 1.8, inner=flow)


def face():
    """자신만만한 청년 마법사: 뜬 눈(금빛 홍채, 눈꼬리 올림)·한쪽 올린 눈썹·한쪽 입꼬리 미소"""
    s = []
    fc = smooth([(933, 258), (933, 276), (936, 292), (943, 306), (951, 316), (960, 320), (969, 316), (977, 306), (984, 292), (987, 276),
                 (987, 258), (980, 242), (960, 236), (940, 242)])
    s.append(cel(fc, K["skin"], [(smooth([(978, 240), (983, 258), (983, 274), (980, 290), (975, 304), (967, 314), (958, 324), (1004, 336), (1006, 230)]), K["skin_s"], .55),
                                 (circ((943, 294), 6.5), K["rb4"], .18), (circ((977, 294), 6.5), K["rb4"], .14),
                                 (smooth([(938, 258), (946, 250), (954, 254), (944, 264)]), K["skin_h"], .6)], 1.7))
    for sg in (1, -1):  # sg = -1은 거울(화면 오른쪽 눈)
        X = (lambda x: x) if sg == 1 else (lambda x: W - x)
        alm = smooth([(X(938), 280, 1), (X(943), 275.6), (X(950), 274.8), (X(955.5), 277.6, 1), (X(950), 283), (X(943), 283.2)])
        ic = (X(947.6), 279.2)
        iris = (f'<g transform="translate({ic[0]:.1f} {ic[1]}) scale(4.5)"><circle r="1" fill="url(#gIris)"/></g>'
                + path(circ(ic, 4.5), stroke=K["gold0"], sw=.8) + path(circ(ic, 1.9), K["ink"]) + path(circ((ic[0] - 1.3, ic[1] - 1.6), 1.1), "#ffffff"))
        s.append(cel(alm, "#fff3e8", [], 0, inner=iris))
        s.append(path(smooth([(X(937), 280.6), (X(943), 275), (X(950), 274), (X(956.5), 277.2)], False), stroke=K["ink"], sw=2.3))
        s.append(path(f"M{X(937.4):.1f} 280.4L{X(932.6):.1f} 276.6", stroke=K["ink"], sw=1.6))  # 올린 눈꼬리
        s.append(path(smooth([(X(939.5), 282.4), (X(946), 284.2), (X(953), 282.6)], False), stroke=K["skin_d"], sw=.9, op=.7))
        lift = 2.2 if sg == -1 else 0  # 화면 오른쪽 눈썹을 올린다
        s.append(path(smooth([(X(936.5), 270.4 - lift * .4), (X(945), 265.4 - lift), (X(955.5), 267.4 - lift * .6)], False), stroke=K["hair_s"], sw=2.3))
    s.append(path(smooth([(961, 282, 1), (963.5, 292), (965, 298), (961.5, 300.5, 1), (961, 291)]), K["skin_s"]))
    s.append(path(smooth([(958.6, 284), (958.4, 294)], False), stroke=K["skin_h"], sw=1.1))
    s.append(path(smooth([(955, 307.6), (961, 311), (966.5, 307.6)]), K["lip"]))  # 아랫입술
    s.append(path(smooth([(952.5, 306.2), (957, 307.4), (962, 307.2), (966.5, 305.6), (969.5, 302.8)], False), stroke="#9a3a2c", sw=1.4))  # 한쪽 입꼬리를 올린 미소
    return "".join(s)


def hair_front():
    """한쪽으로 쓸어 넘긴 앞머리와 뺨을 감싸는 두 가닥(끝이 불꽃처럼 바깥으로 튄다)"""
    s = []
    bang = [(930, 270, 1), (933, 248), (946, 235), (962, 230), (980, 234), (992, 247), (995, 268, 1), (986, 252), (972, 245), (958, 250), (944, 262)]
    s.append(cel(smooth(bang), "url(#gHair)", [(smooth([(966, 228), (998, 240), (998, 270), (972, 248)]), K["hair_s"], .55)], 1.4))
    s.append(cel(smooth(tongue((976, 240), 22, (1008, 210), 6)), "url(#gHair)", [], 1.3))  # 앞머리에서 튀어 오른 한 가닥
    for pts in ([(934, 254), (928, 290), (926, 322), (916, 346)], [(986, 254), (992, 290), (994, 322), (1004, 346)]):  # 뺨을 따라 내린 가는 가닥
        s.append(cel(ribbon(pts, 5.5, head=.1, tail=.35), "url(#gHair)", [], 1.2))
    return "".join(s)


def hand_up():
    """들어 올린 오른손: 손바닥을 위로 펴 화염구를 받친다"""
    el, wr = ARM_UP[1], ARM_UP[2]
    s = cel(limb(along(el, wr, .4), wr, 10, 8), K["skin"], [(limb(along(el, wr, .4, -5), along(wr, el, 0, 5), 5, 4), K["skin_s"], .6)], 1.5)
    s += fingers([((781, 268), (776, 256), (774, 249)), ((788, 265), (786, 252), (786, 245)), ((795, 264), (796, 251), (797, 244)),
                  ((802, 266), (806, 255), (808, 249)), ((809, 273), (817, 268), (822, 263))])
    palm = smooth([(776, 268), (786, 262), (802, 263), (812, 271), (806, 281), (790, 281), (778, 277)])
    s += cel(palm, K["skin"], [(smooth([(776, 274), (814, 274), (814, 286), (776, 286)]), K["skin_s"], .6)], 1.5)
    return s


def fingers(fs, w=4.2):
    """손가락: (밑·마디·끝) 세 점마다 살짝 굽은 두 마디"""
    s = ""
    for b, m, t in fs:
        s += cel(limb(b, m, w, w * .9), K["skin"], [], 1.2) + cel(limb(m, t, w * .9, w * .75), K["skin"], [], 1.2)
    return s


def sleeve_up():
    """들어 올린 팔의 종 소매: 팔꿈치 쪽으로 흘러내려 아래로 늘어진다"""
    el, wr = ARM_UP[1], ARM_UP[2]
    m = along(el, wr, .4)
    a, b = along(el, wr, .4, 26), along(el, wr, .4, -26)  # 소맷부리 양끝(위·아래)
    pts = [a + (1,), (872, 334), (902, 364), (914, 410), (892, 448), (858, 462, 1), (826, 440), (808, 402), (800, 366), b + (1,)]
    lining = smooth([a, (m[0] + 6, m[1] + 10), b, (m[0] - 6, m[1] - 8)])
    shades = [(smooth([(800, 380), (860, 400), (912, 420), (892, 452), (858, 466), (820, 440)]), K["rb2"], .55),
              (smooth([(850, 330), (880, 336), (900, 362), (870, 350)]), K["rb5"], .5)]
    s = cel(smooth(pts), "url(#gRobe)", shades, 2, inner=path(smooth([(808, 400), (840, 420), (880, 440)], False), stroke=K["rb1"], sw=1.6, op=.7))
    s += cel(lining, "url(#gChar)", [], 1.6) + path(polyline([a, b]), stroke=K["gold3"], sw=3)
    s += path(smooth([(858, 462), (826, 440), (808, 402), (800, 366), b], False), stroke=K["gold3"], sw=3)
    return s


def sleeve_dn():
    """내린 팔의 종 소매: 아래팔 밑으로 크게 늘어진다"""
    el, wr = ARM_DN[1], ARM_DN[2]
    m = along(el, wr, .74)
    a, b = along(el, wr, .74, -30), along(el, wr, .74, 30)  # 소맷부리 위끝·아래끝
    pts = [(1010, 366), (1044, 380), (1080, 430), a + (1,), b + (1,), (1092, 584), (1066, 606, 1), (1044, 566), (1032, 500), (1012, 430)]
    lining = smooth([a, (m[0] + 8, m[1] - 4), b, (m[0] - 8, m[1] + 6)])
    shades = [(smooth([(1040, 470), (1090, 540), (1100, 600), (1060, 610), (1036, 540)]), K["rb2"], .6),
              (smooth([(1018, 372), (1046, 382), (1070, 420), (1030, 404)]), K["rb5"], .4)]
    s = cel(smooth(pts), "url(#gRobe)", shades, 2, inner=path(smooth([(1046, 500), (1060, 560), (1066, 600)], False), stroke=K["rb1"], sw=1.6, op=.7))
    s += cel(lining, "url(#gChar)", [], 1.6) + path(polyline([a, b]), stroke=K["gold3"], sw=3)
    s += path(smooth([b, (1092, 584), (1066, 606)], False), stroke=K["gold3"], sw=3)
    return s


def hand_dn():
    """내린 왼손: 손바닥을 아래로 펴 서리를 흘린다"""
    el, wr = ARM_DN[1], ARM_DN[2]
    s = cel(limb(along(el, wr, .74), wr, 9, 8), K["skin"], [], 1.5)
    s += fingers([((1144, 533), (1156, 539), (1164, 546)), ((1146, 540), (1156, 549), (1161, 557)), ((1142, 546), (1149, 556), (1151, 565)),
                  ((1135, 550), (1138, 560), (1139, 568))], 4)
    palm = smooth([(1112, 524), (1130, 520), (1146, 530), (1150, 546), (1138, 554), (1120, 546)])
    s += cel(palm, K["skin"], [(smooth([(1120, 542), (1156, 542), (1156, 562), (1120, 562)]), K["skin_s"], .6)], 1.5)
    return s


def hero():
    head_back = f'<g transform="rotate({HEAD_TILT} 960 340)">{hair_back()}</g>'
    head = f'<g transform="rotate({HEAD_TILT} 960 340)">{face()}{hair_front()}</g>'
    parts = [boots(), skirt(), bodice(), belt(), head_back, collar(), neck(), head, sleeve_up(), hand_up(), sleeve_dn(), hand_dn()]
    return '<g id="hero">' + "".join(parts) + "</g>"


def fill_light():
    """인물 실루엣 안에만 왼쪽 위 화염빛과 오른쪽 아래 서리빛을 얹는다"""
    return (f'<filter id="fWhite"><feColorMatrix type="matrix" values="0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 1 0"/></filter>'
            f'<mask id="mHero" maskUnits="userSpaceOnUse" x="0" y="0" width="{W}" height="{H}"><use href="#hero" filter="url(#fWhite)"/></mask>'
            + rad("gFillF", [(0, K["gold4"], .3), (.5, K["or2"], .08), (1, K["or2"], 0)], FB[0], FB[1], 520)
            + rad("gFillI", [(0, K["fr3"], .26), (.5, K["fr1"], .06), (1, K["fr1"], 0)], 1150, 600, 280)
            + f'<g mask="url(#mHero)" style="mix-blend-mode:screen"><rect width="{W}" height="{H}" fill="url(#gFillF)"/>'
              f'<rect width="{W}" height="{H}" fill="url(#gFillI)"/></g>')


# ── 컨셉 시트 ─────────────────────────────────────────────────────────

def ornament(x0, x1, y):
    m = (x0 + x1) / 2
    return (path(f"M{x0} {y}L{m - 16} {y}M{m + 16} {y}L{x1} {y}", stroke=K["gold3"], sw=1.2, op=.8)
            + diamond((m, y), 7, K["gold3"]) + diamond((m, y), 3, K["rb3"])
            + diamond((m - 24, y), 3, K["fr3"]) + diamond((m + 24, y), 3, K["ar1"]))


INSETS = [  # (원 중심, 반지름, 보는 곳, 배율, 제목, 설명)
    ((1716, 236), 92, (962, 262), 1.45, "FLAME-BORN", "living flame hair · ember gaze"),
    ((1716, 520), 92, FB, 1.25, "ROARING FIREBALL", "blazing core · ember trail"),
    ((1716, 804), 92, (1150, 610), 1.2, "ELEMENTAL ORBIT", "fire · frost · arcane"),
]
PALETTE = [("VERMILION", K["rb3"], True), ("CRIMSON", K["rb2"], True), ("EMBER", K["or2"], True), ("GOLD", K["gold3"], True),
           ("CHARCOAL", K["ch1"], True), ("FROST", K["fr1"], True), ("ARCANE", K["ar1"], True), ("FLARE", K["gold5"], False)]


def sheet():
    s = [label("HERO CONCEPT", 74, 104, 14, K["or3"], 700, 5),
         lin("gTitle", [(0, K["gold5"]), (.5, K["gold3"]), (1, K["or2"])], x2=0, y2=1),
         f'<g filter="url(#fB8)" opacity=".55">{label("IGNIS", 70, 184, 60, K["rb3"], 700, 7)}</g>',
         label("IGNIS", 70, 184, 60, "url(#gTitle)", 700, 7),
         label("MASTER OF THE ELEMENTS", 74, 220, 19, K["gold5"], 700, 4.4),
         ornament(74, 426, 244),
         label("ELEMENTAL MAGE · BURST", 74, 278, 15, K["or3"], 700, 4),
         label("“All elements answer to me.”", 74, 308, 15, K["gold5"], 500, 1, op=.78)]
    for k, (c, r, f, z, t, sub) in enumerate(INSETS):
        s.append(f'<clipPath id="ins{k}"><circle cx="{c[0]}" cy="{c[1]}" r="{r}"/></clipPath>')
        s.append(path(circ(c, r + 18), K["or2"], op=.08))
        s.append(f'<circle cx="{c[0]}" cy="{c[1]}" r="{r}" fill="#07080f"/>')
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
    scene = [background(), floor(), orbit(False),
             '<ellipse cx="960" cy="996" rx="170" ry="13" fill="#000" opacity=".6" filter="url(#fB4)"/>',
             hero(),
             '<g mask="url(#mRim)" style="mix-blend-mode:screen"><use href="#hero" filter="url(#fRim)"/></g>',
             fill_light(), orbit(True), frost(), fireball(),
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
    for name, on in (("ignis", True), ("ignis_clean", False)):  # 컨셉 시트 / 그림만
        svg = out / f"{name}.svg"
        svg.write_text(build(on), encoding="utf-8")
        print(svg)
        if not a.no_png:
            print(shot.shot(svg, out / f"{name}_{W * a.scale}.png", a.scale))
