# 영웅 컨셉 아트 — 실비아, 취풍의 명사수(Sylvia, the Jade-Wind Marksman). 장궁 시위를 당긴 원거리 영웅
# 형체를 SVG 벡터로 직접 그리고(Claude 제작) shot.py로 PNG를 찍는다. 그리는 도구(곡선·셀 음영·글자)는 chronos.py, 꺾은선은 vesper.py의 것을 쓴다.
# 색 뼈대는 비취 청록 망토·밝은 가죽·은이다(K에 f24p 색을 표시했다). 24px로 옮길 때 같은 색을 쓰려는 것이다
# 사용: python tools/art/concept/sylvia.py [--out 폴더] [--scale 2] [--no-png]
#   → sylvia.svg(컨셉 시트)·sylvia_clean.svg(그림만)와 PNG(가로 1920 × scale px: 2 = 4K, 4 = 8K)
import argparse
import math
import random
from pathlib import Path

import chronos
import shot
from chronos import W, H, along, catmull, cel, circ, diamond, label, limb, lin, path, poly, pol, pt, rad, ribbon, smooth, unit
from vesper import polyline

OUT = Path(__file__).resolve().parents[3] / "art" / "concept" / "sylvia"

K = {
    "ink": "#081214",
    "jd0": "#0c2420", "jd1": "#183f39", "jd2": "#276468", "jd3": "#3c9f9c", "jd4": "#86dccd", "jd5": "#dafff5",  # 비취 청록. jd1~3 = f24p
    "lt0": "#45230d", "lt1": "#724113", "lt2": "#a56243", "lt3": "#c98b5e", "lt4": "#e9b98e",  # 밝은 가죽. lt0~2 = f24p
    "sv1": "#7a86a0", "sv2": "#a4aec2", "sv3": "#d0d6e0", "sv4": "#f4f7fb",  # 은. sv1~3 = f24p
    "hr0": "#151a26", "hr1": "#262d3d", "hr2": "#3a4357",  # 먹빛 흑발. 모두 f24p
    "wood1": "#392a1c", "wood2": "#684c3c",  # 화살대. 모두 f24p
    "pant": "#1a2a2c",
    "skin": "#f4d0b2", "skin_s": "#d9a285", "skin_d": "#a56243", "skin_h": "#fde7d4", "lip": "#c7766a",  # skin_d = f24p
}
G = (1172, 342)  # 활 줌통(쥔 손) 중심
LIMB = [(0, -24), (8, -84), (8, -154), (-4, -214), (-24, -258), (-22, -284), (-10, -298)]  # 위 활대 중심선(줌통 기준, 끝은 앞으로 젖혀진다)
NOCK = 286  # 시위가 걸린 활고자의 줌통 기준 높이
D = (944, 324)  # 시위를 당긴 손(턱 밑 고정점) = 화살 오늬
TIP = (1252, 330)  # 화살촉 끝
SH_N, EL_N = (888, 370), (816, 338)  # 시위 당기는 오른팔(가까운 쪽, 화면 왼쪽): 어깨·팔꿈치
SH_F, EL_F, WR_F = (980, 362), (1070, 352), (1150, 344)  # 활을 든 왼팔(먼 쪽): 어깨·팔꿈치·손목


def taper(pts, w0, w1):
    """점을 지나며 반폭이 w0 → w1로 줄어드는 띠"""
    q = catmull(pts)
    L, R = [], []
    for i, p in enumerate(q):
        ux, uy = unit(q[max(i - 1, 0)], q[min(i + 1, len(q) - 1)])
        w = w0 + (w1 - w0) * i / (len(q) - 1)
        L.append((p[0] - uy * w, p[1] + ux * w))
        R.append((p[0] + uy * w, p[1] - ux * w))
    return poly(L + R[::-1])


def on_arrow(x):
    """화살 선 위 x 지점의 y"""
    return D[1] + (TIP[1] - D[1]) * (x - D[0]) / (TIP[0] - D[0])


def leaf(c, a, s, col, op=1.0):
    d = smooth([(0, -6, 1), (2.8, -1), (2.2, 3), (0, 6, 1), (-2.2, 3), (-2.8, -1)])
    return f'<g transform="translate({c[0]:.1f} {c[1]:.1f}) rotate({a:.0f}) scale({s:.2f})">' + path(d, col, op=op) + path("M0 -5L0 5", stroke=K["jd1"], sw=.6, op=op) + "</g>"


# ── SVG 정의 ─────────────────────────────────────────────────────────

def defs():
    d = [
        lin("gCloak", [(0, K["jd4"]), (.25, K["jd3"]), (.65, K["jd2"]), (1, K["jd1"])], x2=1, y2=1),
        lin("gCloakV", [(0, K["jd3"]), (.5, K["jd2"]), (1, K["jd1"])]),
        lin("gLeather", [(0, K["lt4"]), (.3, K["lt3"]), (.7, K["lt2"]), (1, K["lt1"])], x2=1, y2=1),
        lin("gSilver", [(0, K["sv4"]), (.4, K["sv3"]), (.8, K["sv2"]), (1, K["sv1"])], x2=1, y2=1),
        lin("gWood", [(0, K["lt4"]), (.4, K["lt2"]), (1, K["lt1"])], x2=1, y2=0),  # 어두운 하늘에서 활 호가 보이도록 밝은 나무
        lin("gHair", [(0, K["hr2"]), (.5, K["hr1"]), (1, K["hr0"])], x2=0, y2=1),
        lin("gPant", [(0, "#2c4245"), (.5, K["pant"]), (1, "#0f1a1c")], x2=1, y2=0),
        lin("gSky", [(0, "#071216"), (.45, "#0f272a"), (.75, "#1d4641"), (1, "#3a6a59")]),
        rad("gHorizon", [(0, "#8fd8bf", .3), (.4, K["jd3"], .12), (1, K["jd3"], 0)], 1300, 820, 720),
        rad("gGround", [(0, "#16312c"), (.6, "#0b1d1a"), (1, "#050d0c")], 960, 1000, 900),
        rad("gVig", [(0, "#000", 0), (.6, "#000", 0), (1, "#020807", .72)], 960, 520, 1150),
        rad("gGlowWind", [(0, "#ffffff", .9), (.25, K["jd5"], .6), (.6, K["jd4"], .2), (1, K["jd3"], 0)], 0, 0, 1),
        rad("gSpark", [(0, "#ffffff"), (.25, K["jd5"], .9), (1, K["jd4"], 0)], 0, 0, 1),
        rad("gIris", [(0, K["jd4"]), (.5, K["jd3"]), (1, K["jd1"])], 0, 0, 1),
        rad("gRimMask", [(0, "#fff"), (.5, "#c4c4c4"), (1, "#383838")], 1250, 330, 900),
    ]
    for i, sd in (("fB2", 2), ("fB4", 4), ("fB8", 8), ("fB16", 16)):
        d.append(f'<filter id="{i}" filterUnits="userSpaceOnUse" x="-200" y="-200" width="{W + 400}" height="{H + 400}">'
                 f'<feGaussianBlur stdDeviation="{sd}"/></filter>')
    # 역광 테두리: vesper.py fRim과 같은 방식. 빛은 화면 오른쪽의 하늘·바람에서 와서 오른쪽·위 가장자리에 걸린다
    d.append(f'<filter id="fRim" filterUnits="userSpaceOnUse" x="0" y="0" width="{W}" height="{H}" color-interpolation-filters="sRGB">'
             '<feMorphology in="SourceAlpha" operator="erode" radius="1.1" result="a1"/>'
             '<feMorphology in="SourceAlpha" operator="erode" radius="2.6" result="e"/>'
             '<feOffset in="e" dx="-1.8" dy="1.4" result="e2"/>'
             '<feComposite in="a1" in2="e2" operator="out" result="edge"/>'
             '<feGaussianBlur in="edge" stdDeviation="0.5" result="eb"/>'
             '<feComposite in="eb" in2="a1" operator="in" result="eb2"/>'
             f'<feFlood flood-color="{K["jd5"]}" flood-opacity=".85"/><feComposite in2="eb2" operator="in"/></filter>')
    d.append(f'<mask id="mRim" maskUnits="userSpaceOnUse" x="0" y="0" width="{W}" height="{H}">'
             f'<rect width="{W}" height="{H}" fill="url(#gRimMask)"/></mask>')
    return "<defs>" + "".join(d) + "</defs>"


# ── 배경·효과 ────────────────────────────────────────────────────────

def background():
    """해 질 녘 고원: 바람에 밀리는 구름 띠, 산줄기, 언덕"""
    s = [f'<rect width="{W}" height="{H}" fill="url(#gSky)"/>', f'<rect width="{W}" height="{H}" fill="url(#gHorizon)"/>']
    rnd = random.Random(3)
    clouds = []
    for _ in range(14):  # 오른쪽에서 왼쪽으로 밀리는 구름 띠
        x, y, w = rnd.uniform(-100, 1900), rnd.uniform(80, 640), rnd.uniform(220, 620)
        clouds.append(f'<ellipse cx="{x:.0f}" cy="{y:.0f}" rx="{w / 2:.0f}" ry="{rnd.uniform(6, 18):.0f}" fill="#8fd0bd" opacity="{rnd.uniform(.05, .16):.2f}"/>')
    s.append(f'<g filter="url(#fB8)">{"".join(clouds)}</g>')
    for base, col, amp, seed in ((820, "#132e2c", 110, 5), (880, "#0b2220", 60, 9)):  # 먼 산줄기 → 가까운 산줄기
        r2, pts, x = random.Random(seed), [(0, H)], 0
        while x <= W:
            pts.append((x, base - r2.uniform(0, amp)))
            x += r2.uniform(50, 130)
        pts.append((W, H))
        s.append(path(smooth(pts[1:-1], False) + f"L{W} {H}L0 {H}Z", col))
    s.append(path(f"M0 950Q480 900 960 928Q1440 950 {W} 930L{W} {H}L0 {H}Z", "url(#gGround)"))
    return "".join(s)


def grass(front):
    """바람에 왼쪽으로 눕는 풀. 앞줄은 인물 발 앞에 몇 가닥만 둔다"""
    rnd = random.Random(21 if front else 20)
    s = []
    for _ in range(40 if front else 300):
        x = rnd.uniform(760, 1140) if front else rnd.uniform(200, 1720)
        y = rnd.uniform(1000, 1060) if front else rnd.uniform(936, 1070)
        h, lean = rnd.uniform(20, 56), rnd.uniform(14, 40)
        col = rnd.choice((K["jd1"], K["jd2"], K["jd2"], K["jd3"], K["jd0"]))
        s.append(path(f"M{x:.1f} {y:.1f}Q{x - lean * .2:.1f} {y - h * .6:.1f} {x - lean:.1f} {y - h:.1f}", stroke=col, sw=round(rnd.uniform(1.4, 3), 1),
                      op=round(rnd.uniform(.6, 1), 2)))
    return "".join(s)


def trap():
    """숨긴 폭풍의 덫(E): 풀 사이로 희미한 바람 문양"""
    c = (1330, 1008)
    s = [f'<ellipse cx="{c[0]}" cy="{c[1]}" rx="{rx}" ry="{rx * .14:.1f}" fill="none" stroke="{K["jd4"]}" stroke-width="{w}" opacity="{o}"/>'
         for rx, w, o in ((96, 1.6, .5), (70, 1, .4), (40, 1.4, .55))]
    for k in range(3):  # 바람개비 세 갈래
        a = k * 120
        arm = [(c[0] + 40 * math.cos(math.radians(a + t)) * (1 - t / 200), c[1] + 5.6 * math.sin(math.radians(a + t)) * (1 - t / 200)) for t in range(0, 181, 30)]
        s.append(path(polyline(arm), stroke=K["jd5"], sw=1.4, op=.6))
    g = "".join(s)
    return f'<g filter="url(#fB2)">{g}</g>{g}'


def wind_streaks():
    """장면을 가로질러 왼쪽으로 흐르는 바람결과 날리는 잎"""
    rnd = random.Random(8)
    s = []
    for _ in range(16):
        x, y, ln = rnd.uniform(400, 1560), rnd.uniform(180, 900), rnd.uniform(140, 360)
        if 860 < x < 1000 and 220 < y < 340:  # 얼굴 앞은 비운다
            continue
        b = rnd.uniform(-18, 18)
        s.append(path(f"M{x:.0f} {y:.0f}q{-ln / 2:.0f} {b:.0f} {-ln:.0f} {b * .4:.0f}", stroke=K["jd5"], sw=round(rnd.uniform(1, 2.2), 1), op=round(rnd.uniform(.12, .32), 2)))
    leaves = []
    for _ in range(22):
        x, y = rnd.uniform(380, 1560), rnd.uniform(160, 960)
        if 880 < x < 1000 and 220 < y < 340:
            continue
        leaves.append(leaf((x, y), rnd.uniform(0, 360), rnd.uniform(.8, 1.6), rnd.choice((K["jd3"], K["jd4"], K["jd2"])), round(rnd.uniform(.6, 1), 2)))
    return "".join(s) + "".join(leaves)


def gale():
    """관통의 바람살(Q): 화살을 감고 앞으로 뻗는 두 겹 나선과 촉 앞의 바람 고리"""
    s = []
    for ph, col, w in ((0, K["jd5"], 2.4), (math.pi, K["jd4"], 1.8)):
        pts = []
        for i in range(61):
            t = i / 60
            x = 1060 + 330 * t
            pts.append((x, on_arrow(x) + (6 + 22 * t) * math.sin(2 * math.pi * 3.2 * t + ph)))
        s.append(f'<g filter="url(#fB4)">{path(smooth(pts, False), stroke=col, sw=w * 2.4, op=.45)}</g>' + path(smooth(pts, False), stroke=col, sw=w, op=.85))
    for x, ry in ((1276, 20), (1306, 28), (1340, 36)):
        s.append(f'<ellipse cx="{x}" cy="{on_arrow(x):.1f}" rx="{ry * .22:.1f}" ry="{ry}" fill="none" stroke="{K["jd5"]}" stroke-width="1.6" opacity=".7"/>')
    for k in range(7):  # 촉 앞으로 뻗는 바람결
        y = on_arrow(1360) + (k - 3) * 9
        s.append(path(f"M1360 {y:.1f}L{1440 + 60 * (k % 3)} {y + (k - 3) * 3:.1f}", stroke=K["jd5"], sw=1.2, op=.4))
    rnd = random.Random(14)
    for _ in range(7):  # 나선에 휘말린 잎
        x = rnd.uniform(1080, 1380)
        s.append(leaf((x, on_arrow(x) + rnd.uniform(-26, 26)), rnd.uniform(0, 360), rnd.uniform(.9, 1.3), K["jd4"]))
    s.append(f'<g transform="translate({TIP[0]} {TIP[1]}) scale(60)" opacity=".9"><circle r="1" fill="url(#gGlowWind)"/></g>')
    return "".join(s)


# ── 인물 ─────────────────────────────────────────────────────────────

CLOAK = [(906, 334), (860, 342), (800, 350), (730, 366), (660, 390), (590, 404, 1), (640, 440), (610, 480), (546, 516, 1), (610, 540), (600, 590),
         (556, 640, 1), (630, 650), (680, 690), (650, 740, 1), (730, 734), (800, 760), (850, 770, 1), (880, 700), (890, 600), (886, 480), (884, 380)]


def cloak():
    """등 뒤로 바람에 길게 날리는 망토. 갈라진 끝 넷"""
    shades = [(smooth([(560, 520), (900, 520), (900, 780), (620, 780)]), K["jd1"], .55),
              (smooth([(600, 400), (880, 340), (880, 380), (640, 440)]), K["jd4"], .4)]
    folds = "".join(path(smooth(f, False), stroke=K["jd1"], sw=2.2, op=.7) for f in (
        [(880, 400), (760, 420), (620, 470)], [(884, 480), (760, 520), (630, 570)], [(886, 580), (780, 620), (660, 690)], [(880, 680), (800, 720), (720, 734)]))
    hem = path(smooth([p[:2] for p in CLOAK[5:18]], False), stroke=K["sv3"], sw=1.4, op=.5, extra=' stroke-dasharray="8 6"')
    return cel(smooth(CLOAK), "url(#gCloak)", shades, 2.2, inner=folds + hem)


def hood():
    """등에 내린 후드"""
    d = smooth([(878, 336), (890, 312), (914, 302), (932, 318), (924, 346), (896, 356)])
    return cel(d, "url(#gCloakV)", [(smooth([(880, 330), (930, 330), (930, 360), (880, 360)]), K["jd1"], .5)], 1.8,
               inner=path(smooth([(890, 330), (908, 318), (924, 322)], False), stroke=K["jd0"], sw=2, op=.7))


def ponytail():
    """높이 묶어 바람에 뒤로 날리는 포니테일과 은 머리고리"""
    tie = (898, 246)
    main = [tie, (860, 236), (820, 246), (780, 236), (740, 250), (700, 244), (660, 260)]
    s = cel(ribbon(main, 20, head=.05, tail=.4), "url(#gHair)", [(ribbon([(p[0], p[1] - 5) for p in main], 7, head=.1, tail=.5), K["jd2"], .35)], 1.6)
    for pts in ([tie, (850, 226), (800, 228), (756, 218)], [tie, (858, 252), (812, 264), (770, 262)]):  # 갈라진 가닥
        s += cel(ribbon(pts, 6, head=.1, tail=.5), "url(#gHair)", [], 1.2)
    s += path(circ(tie, 6), "url(#gSilver)", K["ink"], 1.2) + path(circ(tie, 2.5), K["sv1"])
    return s


def scarf_tails():
    s = ""
    for pts, w in (([(908, 334), (860, 330), (810, 344), (760, 334), (712, 348)], 12), ([(906, 340), (866, 352), (820, 370), (772, 366)], 9)):
        s += cel(ribbon(pts, w, head=.05, tail=.35), "url(#gCloakV)", [], 1.6, inner=path(smooth(pts, False), stroke=K["jd4"], sw=1, op=.6))
    return s


def leg(hip, knee, ankle, foot):
    """바지(허벅지·볼록한 종아리) → 종아리 중간까지 오는 가죽 장화 → 발"""
    s = cel(limb(hip, knee, 24, 16, 5), "url(#gPant)", [(limb(along(hip, knee, 0, 11), along(hip, knee, 1, 8), 11, 8), "#0a1314", .5)], 2)
    s += cel(limb(knee, ankle, 16, 10, 5), "url(#gPant)", [(limb(along(knee, ankle, 0, 8), along(knee, ankle, 1, 5), 8, 5), "#0a1314", .5)], 2)
    top = along(knee, ankle, .42)
    s += cel(limb(top, ankle, 15.5, 12, 2), "url(#gLeather)", [(limb(along(top, ankle, 0, 7), along(top, ankle, 1, 6), 8, 6), K["lt1"], .55)], 2)
    s += cel(smooth(foot), "url(#gLeather)", [(smooth([(p[0], p[1] + 8) for p in foot]), K["lt1"], .55)], 2)
    cuff = (along(knee, ankle, .42, -17), along(knee, ankle, .42, 17))
    s += path(f"M{pt(cuff[0])}L{pt(cuff[1])}", stroke=K["ink"], sw=8) + path(f"M{pt(cuff[0])}L{pt(cuff[1])}", stroke=K["lt3"], sw=5)
    return s


SKIRT = [(902, 526, 1), (970, 526, 1), (984, 580), (994, 640, 1), (960, 646), (920, 652), (880, 660), (840, 668), (806, 664, 1), (850, 628), (878, 590)]


def skirt():
    """웃옷 자락: 허벅지 중간까지, 뒤가 바람에 날린다"""
    folds = "".join(path(smooth(f, False), stroke=K["jd1"], sw=1.8, op=.7) for f in ([(930, 540), (920, 600), (900, 650)], [(956, 540), (962, 600), (966, 644)], [(900, 560), (870, 610), (840, 660)]))
    trim = path(smooth([p[:2] for p in SKIRT[3:9]], False), stroke=K["sv3"], sw=2.4, op=.8)
    return cel(smooth(SKIRT), "url(#gCloak)", [(smooth([(800, 600), (900, 560), (900, 680), (800, 680)]), K["jd1"], .5)], 2, inner=folds + trim)


def arm_bow():
    """활을 든 왼팔(먼 쪽): 청록 소매 위팔, 가죽 팔찌를 찬 아래팔"""
    s = cel(limb(SH_F, EL_F, 15, 13, 2), "url(#gCloakV)", [(limb(along(SH_F, EL_F, 0, 7), along(SH_F, EL_F, 1, 6), 8, 7), K["jd1"], .5)], 2)
    s += cel(limb(EL_F, WR_F, 13, 10, 1), K["skin"], [(limb(along(EL_F, WR_F, 0, 6), along(EL_F, WR_F, 1, 5), 7, 5), K["skin_s"], .55)], 1.8)
    br = limb(along(EL_F, WR_F, .25), along(EL_F, WR_F, .9), 13.5, 11.5)  # 가죽 팔찌
    s += cel(br, "url(#gLeather)", [], 1.8, inner="".join(path(circ(along(EL_F, WR_F, t, -6), 1.8), K["sv3"]) for t in (.4, .58, .76)))
    return s


def torso():
    """청록 웃옷 위 끈 묶은 가죽 코르셋(가슴 아래~허리), 화살통 멜빵, 허리띠"""
    pts = [(914, 342), (944, 340), (972, 350), (988, 362, 1), (997, 396), (992, 428), (976, 466), (964, 528, 1), (906, 528, 1), (898, 474), (886, 420), (884, 366, 1)]
    tunic = cel(smooth(pts), "url(#gCloakV)", [(smooth([(876, 360), (912, 360), (906, 530), (876, 530)]), K["jd1"], .55),
                                              (smooth([(956, 360), (998, 380), (994, 420), (960, 410)]), K["jd4"], .4)], 2.2)
    cor = [(887, 418, 1), (936, 408), (993, 420, 1), (978, 466), (966, 530, 1), (904, 530, 1), (898, 476)]
    lace = "".join(path(f"M{972 - (y - 424) * .1:.1f} {y}L{986 - (y + 12 - 424) * .16:.1f} {y + 12}M{986 - (y - 424) * .16:.1f} {y}L{972 - (y + 12 - 424) * .1:.1f} {y + 12}",
                        stroke=K["sv3"], sw=1.2, op=.85) for y in range(426, 516, 14))
    stitch = path(smooth([(900, 430), (900, 476), (910, 522)], False), stroke=K["lt1"], sw=1.2, op=.8, extra=' stroke-dasharray="4 4"')
    strap = smooth([(978, 356), (950, 430), (904, 520)], False)
    s = tunic + cel(smooth(cor), "url(#gLeather)", [(smooth([(880, 410), (914, 410), (910, 534), (880, 534)]), K["lt1"], .5)], 2, inner=stitch + lace)
    s += path(strap, stroke=K["ink"], sw=10) + path(strap, stroke=K["lt1"], sw=7) + path(strap, stroke=K["lt3"], sw=1, op=.7)
    s += diamond((946, 438), 7, K["sv3"]) + diamond((946, 438), 3.4, K["jd2"])  # 멜빵 은 장식
    belt = smooth([(900, 524), (936, 532), (972, 524)], False)
    s += path(belt, stroke=K["ink"], sw=11) + path(belt, stroke=K["lt0"], sw=8) + path(belt, stroke=K["lt2"], sw=1.2, op=.7)
    s += f'<rect x="940" y="522" width="14" height="13" rx="2" fill="url(#gSilver)" stroke="{K["ink"]}" stroke-width="1.2"/>'
    return s


def quiver():
    """등에 비스듬히 멘 화살통. 몸통에 가려 아가리와 깃만 어깨 위로 보인다"""
    top, bot = (868, 318), (930, 520)
    s = ""
    for k in range(4):  # 화살 깃: 아가리에서 화면 왼쪽 위로
        b = along(top, bot, 0, -10 + k * 6.5)
        t = (b[0] - 14 - k * 2, b[1] - 34 + k * 3)
        s += path(f"M{pt(b)}L{pt(t)}", stroke=K["wood1"], sw=2.2)
        s += path(smooth([t, (t[0] + 4, t[1] + 7), (t[0] + 4, t[1] + 19, 1), (t[0] - 1, t[1] + 14), (t[0] - 3, t[1] + 3)]), K["jd3"] if k % 2 else K["sv3"], K["ink"], .8)
    s += cel(limb(top, bot, 14, 12), "url(#gLeather)", [(limb(along(top, bot, 0, -7), along(top, bot, 1, -6), 7, 6), K["lt1"], .55)], 2)
    a, b = along(top, bot, .04, -14), along(top, bot, .04, 14)
    s += path(f"M{pt(a)}L{pt(b)}", stroke=K["ink"], sw=5.4) + path(f"M{pt(a)}L{pt(b)}", stroke=K["sv3"], sw=3)
    return s


FACE = [(940, 234), (952, 242), (957, 256), (959, 264), (963, 272), (968, 281, 1), (961, 286, 1), (962, 292), (959, 296), (961, 300), (957, 309),
        (948, 317), (934, 316), (920, 308), (910, 294), (906, 276), (906, 256), (918, 240)]  # 화면 오른쪽을 본 반측면 얼굴


def face():
    """조준하는 얼굴: 가늘게 뜬 비취 눈, 곧은 눈썹, 다문 입"""
    s = [cel(smooth(FACE), K["skin"], [(smooth([(900, 250), (916, 250), (918, 300), (940, 322), (900, 322)]), K["skin_s"], .55),
                                       (circ((930, 290), 6), K["lip"], .14), (smooth([(950, 246), (958, 258), (954, 268), (946, 254)]), K["skin_h"], .55)], 1.7)]
    for c, w, iris_r, look in (((934, 268), 15.5, 3.6, 3.6), ((954.5, 266.6), 6.4, 2.3, .9)):  # 가까운 눈·먼 눈
        x0, x1 = c[0] - w / 2, c[0] + w / 2
        alm = smooth([(x0, c[1], 1), (x0 + w * .3, c[1] - 3.6), (x0 + w * .7, c[1] - 4), (x1, c[1] - 1.6, 1), (x0 + w * .65, c[1] + 2.8), (x0 + w * .3, c[1] + 2.8)])
        ic = (c[0] + look, c[1] - .6)
        iris = (f'<g transform="translate({ic[0]:.1f} {ic[1]:.1f}) scale({iris_r})"><circle r="1" fill="url(#gIris)"/></g>'
                + path(circ(ic, iris_r * .45), K["ink"]) + path(circ((ic[0] - iris_r * .3, ic[1] - iris_r * .35), iris_r * .26), "#ffffff"))
        s.append(cel(alm, "#fff4ea", [], 0, inner=iris))
        s.append(path(smooth([(x0 - .6, c[1] + .4), (x0 + w * .3, c[1] - 3.8), (x0 + w * .7, c[1] - 4.2), (x1 + .4, c[1] - 1.6)], False), stroke=K["ink"], sw=2.2 if w > 10 else 1.6))
        s.append(path(smooth([(x0 + w * .15, c[1] + 2.4), (x0 + w * .5, c[1] + 3.2), (x1 - w * .1, c[1] + 1.6)], False), stroke=K["skin_d"], sw=.8, op=.7))
    s.append(path(smooth([(924.5, 259.4), (934, 256.4), (943, 258.8)], False), stroke=K["hr1"], sw=2.3))  # 곧게 내린 눈썹
    s.append(path(smooth([(950.5, 258.4), (956, 257.4), (958.6, 258.8)], False), stroke=K["hr1"], sw=1.8))
    s.append(path("M959.5 284.6q2 1.2 3.6 .4", stroke=K["skin_d"], sw=1.1))  # 콧방울
    s.append(path(smooth([(947.5, 297.4), (953, 298.2), (958.6, 297)], False), stroke="#8f4a40", sw=1.4))  # 다문 입
    s.append(path(smooth([(950, 300.6), (954, 302.4), (957.6, 300.4)], False), stroke=K["lip"], sw=1.6, op=.8))
    return "".join(s)


def hair():
    """뒤로 쓸린 머리통·관자놀이 가닥·귀"""
    cap = [(912, 300), (900, 278), (896, 252), (904, 232), (922, 220), (944, 220), (960, 230), (967, 247, 1), (958, 243), (946, 238), (930, 240),
           (918, 250), (913, 266), (917, 288, 1)]
    s = cel(smooth(cap), "url(#gHair)", [(smooth([(930, 222), (960, 228), (962, 238), (934, 232)]), K["jd2"], .4)], 1.7,
            inner="".join(path(smooth(f, False), stroke=K["hr2"], sw=1.2, op=.8) for f in ([(960, 234), (930, 226), (904, 240)], [(950, 240), (920, 236), (902, 256)])))
    s += cel(smooth([(906, 270), (913, 268), (916, 278), (913, 289), (907, 287)]), K["skin"], [(circ((909, 280), 3), K["skin_s"], .7)], 1.4)  # 귀
    for pts in ([(918, 252), (906, 270), (900, 292), (888, 306)], [(962, 236), (944, 228), (918, 226), (892, 236)]):  # 바람에 뒤로 날리는 가닥
        s += cel(ribbon(pts, 4.5, head=.1, tail=.4), "url(#gHair)", [], 1.1)
    return s


def scarf_wrap():
    d = smooth([(912, 324), (930, 330), (948, 326), (952, 340), (934, 348), (912, 346), (904, 336)])
    return cel(d, "url(#gCloakV)", [(smooth([(900, 338), (956, 338), (956, 352), (900, 352)]), K["jd1"], .5)], 1.6)


def bow():
    """비취 장궁: 나무 활대(위·아래 젖힌 끝), 은 상감·활고자, 줌통의 은 바람 문장"""
    up = [(G[0] + dx, G[1] + dy) for dx, dy in LIMB]
    dn = [(G[0] + dx, G[1] - dy) for dx, dy in LIMB]
    s = []
    for pts in (up, dn):
        s.append(path(taper(pts, 10, 3.5), "url(#gWood)", K["ink"], 1.6))
        s.append(path(smooth(pts[1:5], False), stroke=K["sv3"], sw=1.4, op=.85))  # 은 상감
        s.append(path(taper(pts[-3:], 4, 2.4), "url(#gSilver)", K["ink"], 1.1))  # 은 끝
    s.append(path(smooth([(G[0] - 8, G[1] - 40, 1), (G[0] + 9, G[1] - 40, 1), (G[0] + 10, G[1] + 40, 1), (G[0] - 7, G[1] + 40, 1)]), "url(#gWood)", K["ink"], 1.6))
    c = (G[0] + 1, G[1] - 58)  # 바람 문장: 소용돌이 세 갈래
    s.append(path(circ(c, 9), "url(#gSilver)", K["ink"], 1.2))
    for k in range(3):
        a = k * 120
        s.append(path(f"M{pt(c)}Q{pt(pol(c, 6, a + 50))} {pt(pol(c, 8, a + 100))}", stroke=K["jd2"], sw=1.6))
    return "".join(s)


def string():
    top, bot = (G[0] - 22, G[1] - NOCK), (G[0] - 22, G[1] + NOCK)
    return path(f"M{pt(top)}L{pt(D)}L{pt(bot)}", stroke=K["sv4"], sw=1.4, op=.9)


def arrow():
    """화살: 대·깃(청록·은)·잎 모양 은 촉"""
    s = path(f"M{pt(D)}L{pt(along(D, TIP, .93))}", stroke=K["ink"], sw=4) + path(f"M{pt(D)}L{pt(along(D, TIP, .93))}", stroke=K["wood2"], sw=2.2)
    for k, sg in ((0, -1), (1, 1)):  # 깃 두 장
        b0, b1 = along(D, TIP, .03), along(D, TIP, .15)
        s += path(smooth([b0 + (1,), along(D, TIP, .02, sg * 9), along(D, TIP, .1, sg * 8), b1 + (1,)]), K["jd3"] if k else K["sv3"], K["ink"], .9)
    head = [along(D, TIP, .9, 0) + (1,), along(D, TIP, .94, 6), TIP + (1,), along(D, TIP, .94, -6)]
    s += path(smooth(head), "url(#gSilver)", K["ink"], 1.2)
    return s


def arm_draw():
    """시위 당긴 오른팔(가까운 쪽): 청록 소매, 은 소맷단, 턱 밑에 붙인 손"""
    fore_end = along(EL_N, D, .86)
    s = cel(limb(SH_N, EL_N, 17, 14, 2), "url(#gCloakV)", [(limb(along(SH_N, EL_N, 0, -8), along(SH_N, EL_N, 1, -6), 8, 7), K["jd1"], .5)], 2)
    s += cel(limb(EL_N, fore_end, 14, 11, 1), "url(#gCloakV)", [(limb(along(EL_N, fore_end, 0, -7), along(EL_N, fore_end, 1, -5), 7, 6), K["jd1"], .5)], 2)
    cuff = (along(EL_N, fore_end, .82, -13), along(EL_N, fore_end, .82, 13))
    s += path(f"M{pt(cuff[0])}L{pt(cuff[1])}", stroke=K["ink"], sw=7) + path(f"M{pt(cuff[0])}L{pt(cuff[1])}", stroke=K["sv3"], sw=4)
    fist = smooth([(D[0] - 22, D[1] - 8), (D[0] - 8, D[1] - 14), (D[0] + 4, D[1] - 11), (D[0] + 6, D[1] + 4), (D[0] - 2, D[1] + 13), (D[0] - 18, D[1] + 12)])
    s += cel(fist, K["skin"], [(smooth([(D[0] - 24, D[1] + 3), (D[0] + 10, D[1] + 3), (D[0] + 10, D[1] + 16), (D[0] - 24, D[1] + 16)]), K["skin_s"], .6)], 1.5,
             inner=path(f"M{D[0] - 16} {D[1] + 6}L{D[0] - 2} {D[1] + 5}", stroke=K["skin_d"], sw=.9, op=.7))
    for y0 in (-8, 0):  # 시위에 건 검지·중지
        s += cel(smooth([(D[0] + 2, D[1] + y0 - 2, 1), (D[0] + 9, D[1] + y0 - 1), (D[0] + 10, D[1] + y0 + 4), (D[0] + 4, D[1] + y0 + 6, 1)]), K["skin"], [], 1.2)
    return s


def hand_bow():
    """줌통을 감아쥔 왼손. 화살은 손등 위에 얹힌다"""
    d = smooth([(G[0] - 14, G[1] - 12), (G[0] + 6, G[1] - 14), (G[0] + 16, G[1] - 4), (G[0] + 16, G[1] + 10), (G[0] + 4, G[1] + 16), (G[0] - 14, G[1] + 12)])
    knuck = "".join(path(f"M{G[0] + 6} {G[1] + y}L{G[0] + 15} {G[1] + y + 1}", stroke=K["skin_d"], sw=.9, op=.75) for y in (-6, 0, 6))
    return cel(d, K["skin"], [(smooth([(G[0] - 16, G[1] + 2), (G[0] + 18, G[1] + 2), (G[0] + 18, G[1] + 18), (G[0] - 16, G[1] + 18)]), K["skin_s"], .55)], 1.5, inner=knuck)


def hero():
    parts = [cloak(), hood(), ponytail(), scarf_tails(),
             quiver(),
             leg((952, 596), (1010, 772), (1052, 950), [(1040, 940), (1070, 950), (1094, 974), (1098, 994, 1), (1040, 998, 1), (1034, 966)]),
             leg((912, 600), (872, 778), (838, 952), [(824, 942), (852, 944), (862, 976), (860, 996, 1), (798, 996, 1), (802, 978)]),
             skirt(), arm_bow(), torso(), face(), hair(), scarf_wrap(), bow(), string(), arrow(), arm_draw(), hand_bow()]
    return '<g id="hero">' + "".join(parts) + "</g>"


def fill_light():
    """인물 실루엣 안에만 오른쪽 위 하늘빛과 화살 끝 바람빛을 얹는다"""
    return (f'<filter id="fWhite"><feColorMatrix type="matrix" values="0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 1 0"/></filter>'
            f'<mask id="mHero" maskUnits="userSpaceOnUse" x="0" y="0" width="{W}" height="{H}"><use href="#hero" filter="url(#fWhite)"/></mask>'
            + rad("gFillS", [(0, K["jd5"], .16), (.5, K["jd4"], .05), (1, K["jd4"], 0)], 1300, 200, 700)
            + rad("gFillW", [(0, K["jd5"], .28), (.5, K["jd4"], .06), (1, K["jd4"], 0)], TIP[0], TIP[1], 360)
            + f'<g mask="url(#mHero)" style="mix-blend-mode:screen"><rect width="{W}" height="{H}" fill="url(#gFillS)"/>'
              f'<rect width="{W}" height="{H}" fill="url(#gFillW)"/></g>')


# ── 컨셉 시트 ─────────────────────────────────────────────────────────

def ornament(x0, x1, y):
    m = (x0 + x1) / 2
    return (path(f"M{x0} {y}L{m - 16} {y}M{m + 16} {y}L{x1} {y}", stroke=K["sv2"], sw=1.2, op=.8)
            + diamond((m, y), 7, K["sv3"]) + diamond((m, y), 3, K["jd3"])
            + diamond((m - 24, y), 3, K["jd4"]) + diamond((m + 24, y), 3, K["jd4"]))


INSETS = [  # (원 중심, 반지름, 보는 곳, 배율, 제목, 설명)
    ((1716, 236), 92, (940, 282), 1.6, "FOCUSED GAZE", "anchored draw · wind-swept tail"),
    ((1716, 520), 92, (1172, 330), 1.2, "JADE RECURVE", "silver wind crest · drawn limbs"),
    ((1716, 804), 92, (1262, 330), 1.35, "PIERCING GALE", "wind-wrapped arrowhead"),
]
PALETTE = [("JADE", K["jd2"], True), ("DEEP", K["jd1"], True), ("SHEEN", K["jd3"], True), ("LEATHER", K["lt2"], True),
           ("HIDE", K["lt1"], True), ("SILVER", K["sv3"], True), ("HAIR", K["hr1"], True), ("GALE", K["jd5"], False)]


def sheet():
    s = [label("HERO CONCEPT", 74, 104, 14, K["jd4"], 700, 5),
         lin("gTitle", [(0, K["sv4"]), (.5, K["jd4"]), (1, K["jd3"])], x2=0, y2=1),
         f'<g filter="url(#fB8)" opacity=".5">{label("SYLVIA", 70, 184, 60, K["jd3"], 700, 7)}</g>',
         label("SYLVIA", 70, 184, 60, "url(#gTitle)", 700, 7),
         label("THE JADE-WIND MARKSMAN", 74, 220, 19, K["sv3"], 700, 4.4),
         ornament(74, 426, 244),
         label("WIND RANGER · PRECISION", 74, 278, 15, K["jd4"], 700, 4),
         label("“Read the wind. Find the weakness.”", 74, 308, 15, K["sv4"], 500, 1, op=.78)]
    for k, (c, r, f, z, t, sub) in enumerate(INSETS):
        s.append(f'<clipPath id="ins{k}"><circle cx="{c[0]}" cy="{c[1]}" r="{r}"/></clipPath>')
        s.append(path(circ(c, r + 18), K["jd3"], op=.08))
        s.append(f'<circle cx="{c[0]}" cy="{c[1]}" r="{r}" fill="#04100e"/>')
        s.append(f'<g clip-path="url(#ins{k})"><use href="#scene" transform="translate({c[0]} {c[1]}) scale({z}) translate({-f[0]:.1f} {-f[1]:.1f})"/></g>')
        s.append(path(circ(c, r), stroke=K["sv2"], sw=2.6))
        s.append(path(circ(c, r + 7), stroke=K["sv2"], sw=.9, op=.6))
        for i in range(24):
            s.append(path(f"M{pt(pol(c, r + 3, i * 15))}L{pt(pol(c, r + 7 + (3 if i % 6 == 0 else 0), i * 15))}", stroke=K["jd4"], sw=1.6 if i % 6 == 0 else .9))
        s.append(diamond((c[0], c[1] - r - 7), 6, K["sv3"]))
        s.append(label(t, c[0], c[1] + r + 38, 15, K["sv3"], 700, 3, "middle"))
        s.append(label(sub, c[0], c[1] + r + 60, 13, K["sv4"], 500, 1.2, "middle", op=.72))
    s.append(label("PALETTE", 74, 930, 13, K["jd4"], 700, 4))
    for k, (n, col, f24) in enumerate(PALETTE):
        x = 74 + k * 62
        s.append(f'<rect x="{x}" y="944" width="44" height="44" rx="6" fill="{col}" stroke="{K["sv2"]}" stroke-width="1.2"/>')
        if f24:
            s.append(diamond((x + 37, 951), 3.6, K["ink"]) + diamond((x + 37, 951), 2.2, K["sv4"]))
        s.append(label(col.upper(), x + 22, 1006, 10, K["sv4"], 500, .6, "middle", op=.8))
        s.append(label(n, x + 22, 1022, 9, K["sv3"], 700, .8, "middle", op=.8))
    s.append(diamond((80, 1046), 3.6, K["ink"]) + diamond((80, 1046), 2.2, K["sv4"]))
    s.append(label("= f24p in-game palette color", 92, 1050, 10, K["sv4"], 500, .6, op=.6))
    return "".join(s)


def build(sheet_on=True):
    chronos._cid[0] = 0
    scene = [background(), grass(False), trap(),
             '<ellipse cx="940" cy="996" rx="150" ry="12" fill="#000" opacity=".55" filter="url(#fB4)"/>',
             hero(),
             '<g mask="url(#mRim)" style="mix-blend-mode:screen"><use href="#hero" filter="url(#fRim)"/></g>',
             fill_light(), grass(True), wind_streaks(), gale(),
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
    for name, on in (("sylvia", True), ("sylvia_clean", False)):  # 컨셉 시트 / 그림만
        svg = out / f"{name}.svg"
        svg.write_text(build(on), encoding="utf-8")
        print(svg)
        if not a.no_png:
            print(shot.shot(svg, out / f"{name}_{W * a.scale}.png", a.scale))
