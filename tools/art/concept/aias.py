# 영웅 컨셉 아트 — 아이아스, 강철의 성채(Aias, the Steel Citadel). 탑 방패를 든 탱커
# 형체를 SVG 벡터로 직접 그리고(Claude 제작) shot.py로 PNG를 찍는다. 그리는 도구(곡선·셀 음영·글자)는 chronos.py의 것을 쓴다.
# 색 뼈대는 f24p(tools/art/palettes.json)의 강철 램프·금·진홍이다(K에 f24p 색을 표시했다). 24px 유닛으로 옮길 때 같은 램프를 쓰려는 것이다
# 사용: python tools/art/concept/aias.py [--out 폴더] [--scale 2] [--no-png]
#   → aias.svg(컨셉 시트)·aias_clean.svg(그림만)와 PNG(가로 1920 × scale px: 2 = 4K, 4 = 8K)
import argparse
import math
import random
from pathlib import Path

import chronos
import shot
from chronos import W, H, along, cel, circ, diamond, label, limb, lin, mirror, path, poly, pol, pt, rad, ribbon, smooth, unit

OUT = Path(__file__).resolve().parents[3] / "art" / "concept" / "aias"

K = {
    "ink": chronos.K["ink"],
    "s0": "#151a26", "s1": "#262d3d", "s2": "#3a4357", "s3": "#56607a", "s4": "#7a86a0", "s5": "#a4aec2", "s6": "#d0d6e0",  # 강철 = 모두 f24p
    "gold0": "#4a2a0c", "gold1": "#ab5c1c", "gold2": "#d48b24", "gold3": "#efac28", "gold4": "#efd8a1", "gold5": "#fff5da",  # gold1·3·4 = f24p
    "red0": "#300f0a", "red1": "#550f0a", "red2": "#9b1a0a", "red3": "#c8361c", "red4": "#ef7a5e",  # red0·1·2 = f24p
    "wood0": "#45230d", "wood1": "#724113", "wood2": "#a56243",  # 모두 f24p
    "ember": "#ffb35c", "void": "#05070c",
}
SHIELD = (1040, 1290, 432, 982)  # 방패 왼·오른·윗변(총안 바닥)·아랫변
EMB = (1165, 662)  # 방패 문장 중심
SP_B, SP_T = (798, 998), (744, 168)  # 창 물미 끝, 창날 슴베(자루 위끝)
LEG = {"L": ((930, 648), (914, 800), (906, 946)), "R": ((990, 648), (1012, 800), (1028, 946))}  # 엉덩이·무릎·발목


def crenel(x0, x1, y, mw, gap, mh):
    """x0→x1 성가퀴 윗선의 점들. y = 총안 바닥, 머리(merlon)는 y - mh"""
    pts, x = [], x0
    while x < x1 - 1e-6:
        e = min(x + mw, x1)
        pts += [(x, y - mh), (e, y - mh)]
        if e < x1:
            g = min(e + gap, x1)
            pts += [(e, y), (g, y)]
            x = g
        else:
            x = e
    return pts


def runes(n, seed):
    """룬 모양 기호(줄기 하나 + 가지 한두 개, 국소 좌표 약 10×14)"""
    rnd = random.Random(seed)
    out = []
    for _ in range(n):
        x = rnd.choice((-2.5, 0, 2.5))
        d = f"M{x} -7L{x} 7"
        for _ in range(rnd.randint(1, 2)):
            y0 = rnd.choice((-7, -3, 1))
            d += f"M{x} {y0}L{x + rnd.choice((-5, 5))} {y0 + rnd.choice((0, 4, 8))}"
        out.append(d)
    return out


# ── SVG 정의 ─────────────────────────────────────────────────────────

def defs():
    d = [
        lin("gSteel", [(0, K["s6"]), (.3, K["s5"]), (.65, K["s4"]), (1, K["s3"])], x2=1, y2=1),
        lin("gSteelV", [(0, K["s5"]), (.5, K["s4"]), (1, K["s2"])]),
        lin("gShield", [(0, K["s4"]), (.12, K["s6"]), (.3, K["s5"]), (.62, K["s4"]), (1, K["s2"])], x2=1, y2=0),
        lin("gGold", [(0, K["gold5"]), (.3, K["gold3"]), (.7, K["gold2"]), (1, K["gold1"])]),
        lin("gGoldS", [(0, K["gold3"]), (.6, K["gold2"]), (1, K["gold0"])]),
        lin("gRed", [(0, K["red3"]), (.45, K["red2"]), (1, K["red1"])], x2=1, y2=1),
        lin("gRedV", [(0, K["red2"]), (1, K["red0"])]),
        lin("gWood", [(0, K["wood2"]), (.5, K["wood1"]), (1, K["wood0"])], x2=1, y2=0),
        lin("gWall", [(0, K["gold5"], .5), (.1, K["gold3"], .26), (.55, K["gold2"], .1), (1, K["gold2"], .02)]),
        lin("gWallFade", [(0, "#000"), (.2, "#fff"), (.8, "#fff"), (1, "#000")], x2=1, y2=0),
        lin("gVoid", [(0, "#0b0f18"), (1, K["void"])]),
        rad("gBg", [(0, "#313b52"), (.35, "#1e2537"), (.72, "#10141f"), (1, "#07090f")], 960, 560, 1150),
        rad("gHorizon", [(0, K["gold3"], .3), (.45, K["gold2"], .1), (1, K["gold1"], 0)], 960, 780, 760),
        rad("gFloor", [(0, K["gold3"], .28), (.5, K["gold2"], .08), (1, K["gold1"], 0)], 960, 994, 560),
        rad("gVig", [(0, "#000", 0), (.62, "#000", 0), (1, "#03050b", .72)], 960, 520, 1150),
        rad("gGlow", [(0, K["gold5"], .9), (.35, K["ember"], .45), (1, K["gold2"], 0)], 0, 0, 1),
        rad("gSpark", [(0, "#ffffff"), (.25, K["gold4"], .9), (1, K["gold3"], 0)], 0, 0, 1),
        rad("gRimMask", [(0, "#fff"), (.55, "#9a9a9a"), (1, "#202020")], 960, 700, 650),
    ]
    for i, sd in (("fB2", 2), ("fB4", 4), ("fB8", 8)):
        d.append(f'<filter id="{i}" filterUnits="userSpaceOnUse" x="-200" y="-200" width="{W + 400}" height="{H + 400}">'
                 f'<feGaussianBlur stdDeviation="{sd}"/></filter>')
    # 역광 테두리: chronos.py fRim과 같은 방식(외곽선 안쪽 가장자리 띠). 빛은 등 뒤 성벽에서 온다
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


# ── 배경·효과 ────────────────────────────────────────────────────────

def background():
    s = [f'<rect width="{W}" height="{H}" fill="url(#gBg)"/>', f'<rect width="{W}" height="{H}" fill="url(#gHorizon)"/>']
    towers = [(170, 80, 612), (400, 96, 566), (1420, 96, 574), (1666, 80, 626)]  # 먼 성채 탑(왼 x, 폭, 꼭대기)
    pts, x = [(0, H)], 0
    for tx, tw, ty in towers:
        pts += crenel(x, tx, 760, 14, 12, 10) + crenel(tx, tx + tw, ty, 18, 12, 16)
        x = tx + tw
    pts += crenel(x, W, 760, 14, 12, 10) + [(W, H)]
    s.append(path(poly(pts), "#0d111b", op=.85))
    for tx, tw, ty in towers:  # 탑 창의 불빛
        for k in range(2):
            s.append(f'<rect x="{tx + tw / 2 - 3 + (k - .5) * tw * .4:.1f}" y="{ty + 40 + k * 46}" width="6" height="14" rx="3" '
                     f'fill="{K["ember"]}" opacity=".45"/>')
    s.append('<ellipse cx="960" cy="996" rx="620" ry="92" fill="url(#gFloor)"/>')
    return "".join(s)


def rampart():
    """등 뒤의 빛의 성벽(R 절대 방어선)"""
    x0, x1, base, top = 330, 1590, 905, 640
    crest = crenel(x0, x1, top, 66, 42, 46)
    bricks = []
    for k, y in enumerate(range(top + 36, base, 38)):
        bricks.append(f"M{x0} {y}L{x1} {y}")
        for x in range(x0 + (48 if k % 2 else 0), x1, 96):
            bricks.append(f"M{x} {y}L{x} {min(y + 38, base)}")
    top_line = "M" + "L".join(pt(p) for p in crest)
    body = (path(poly([(x0, base)] + crest + [(x1, base)]), "url(#gWall)")
            + path("".join(bricks), stroke=K["gold4"], sw=1.2, op=.28)
            + f'<g filter="url(#fB8)">{path(top_line, stroke=K["gold3"], sw=8, op=.7)}</g>'
            + path(top_line, stroke=K["gold4"], sw=2.4))
    return (f'<mask id="mWall" maskUnits="userSpaceOnUse" x="0" y="0" width="{W}" height="{H}">'
            f'<rect x="{x0}" y="0" width="{x1 - x0}" height="{H}" fill="url(#gWallFade)"/></mask>'
            f'<g mask="url(#mWall)">{body}</g>')


def floor():
    """요새화 룬 원과 반격의 충격파 고리(E)"""
    s = []
    for k, rx in enumerate((320, 410, 510, 620)):
        dash = ' stroke-dasharray="16 10"' if k % 2 else ""
        s.append(f'<ellipse cx="960" cy="994" rx="{rx}" ry="{rx * .12:.1f}" fill="none" stroke="{K["gold3"]}" '
                 f'stroke-width="{2.2 - k * .4:.2f}" opacity="{.7 - k * .15:.2f}"{dash}/>')
    ns = ' vector-effect="non-scaling-stroke"'
    g = [f'<circle r="262" fill="none" stroke="{K["gold3"]}" stroke-width="2.2"{ns}/>',
         f'<circle r="236" fill="none" stroke="{K["gold3"]}" stroke-width="1.2"{ns}/>']
    for i in range(48):
        g.append(f'<path d="M{pt(pol((0, 0), 254 if i % 4 else 246, i * 7.5))}L{pt(pol((0, 0), 262, i * 7.5))}" '
                 f'stroke="{K["gold4"]}" stroke-width="{1.6 if i % 4 == 0 else .8}"{ns}/>')
    for i, rd in enumerate(runes(16, 3)):
        x, y = pol((0, 0), 249, i * 22.5 + 11.25)
        g.append(f'<path d="{rd}" transform="translate({x:.1f} {y:.1f}) rotate({i * 22.5 + 11.25:.1f}) scale(1.2)" fill="none" '
                 f'stroke="{K["gold5"]}" stroke-width="1.4" stroke-linecap="round"{ns}/>')
    ring = f'<g transform="translate(960 992) scale(1 .15)">{"".join(g)}</g>'
    sg = "".join(s)
    return f'<g filter="url(#fB4)">{sg}{ring}</g>{sg}{ring}'


def embers():
    rnd = random.Random(11)
    s, n = [], 0
    while n < 150:
        p = (rnd.uniform(360, 1560), rnd.uniform(380, 1040)) if rnd.random() < .7 else (rnd.uniform(300, 1620), rnd.uniform(60, 1040))
        if 870 < p[0] < 1050 and 190 < p[1] < 360:  # 투구 앞에는 두지 않는다
            continue
        n += 1
        col = rnd.choice((K["gold4"], K["ember"], K["ember"], K["red4"]))
        s.append(path(circ(p, rnd.uniform(.7, 2.3)), col, op=round(rnd.uniform(.35, 1), 2)))
    g = "".join(s)
    sp = []
    for p, r in (((736, 52), 22), (EMB, 16), ((1290, 398), 9), ((430, 610), 8), ((1500, 640), 10), ((960, 990), 12)):
        star = poly([pol(p, r if i % 2 == 0 else r * .14, i * 45) for i in range(8)])
        sp.append(f'<g transform="translate({p[0]} {p[1]}) scale({r:.1f})"><circle r=".55" fill="url(#gSpark)"/></g>')
        sp.append(path(star, "#ffffff", op=.95))
    return f'<g filter="url(#fB2)">{g}</g>{g}' + "".join(sp)


# ── 인물 ─────────────────────────────────────────────────────────────

def cape():
    pts = [(872, 370, 1), (842, 382), (818, 414), (800, 476), (784, 560), (768, 660), (752, 760), (740, 850), (730, 914, 1),
           (762, 904), (792, 924), (828, 908), (862, 928), (900, 912), (940, 930), (980, 914), (1020, 930), (1062, 912),
           (1104, 926), (1150, 908, 1), (1132, 800), (1112, 660), (1092, 520), (1076, 420), (1048, 372, 1)]
    hem = smooth([(730, 914), (762, 904), (792, 924), (828, 908), (862, 928), (900, 912), (940, 930), (980, 914), (1020, 930),
                  (1062, 912), (1104, 926), (1150, 908), (1150, 868), (1000, 878), (860, 874), (736, 868)])
    folds = "".join(path(smooth(f, False), stroke=K["red0"], sw=3, op=.6) for f in (
        [(822, 440), (802, 600), (784, 760), (774, 890)], [(852, 480), (842, 640), (832, 800), (828, 905)],
        [(1080, 500), (1098, 700), (1108, 890)]))
    lights = path(smooth([(794, 486), (776, 640), (758, 800), (748, 880)], False), stroke=K["red3"], sw=5, op=.55)
    return cel(smooth(pts), "url(#gRed)", [(hem, K["red0"], .45)], 2.2, inner=folds + lights)


def crest_tail():
    """투구 깃의 꼬리: 뒤로 넘어가 화면 왼쪽 어깨 뒤로 흘러내린다"""
    spine = [(990, 146), (944, 146), (898, 172), (866, 222), (850, 284), (846, 352)]
    strands = "".join(path(smooth([(x + dx, y) for x, y in spine[1:]], False), stroke=K["red0"], sw=1.4, op=.7) for dx in (-6, 0, 7))
    return cel(ribbon(spine, 20, head=.12, tail=.35), "url(#gRedV)", [], 1.8, inner=strands)


def sabaton(side):
    if side == "L":
        out = [(886, 928, 1), (884, 950), (879, 966), (869, 980), (867, 992), (882, 999), (910, 999), (930, 994), (934, 980),
               (929, 962), (927, 944), (927, 928, 1)]
        lames = [(878, 962), (930, 962)], [(872, 977), (933, 977)]
    else:
        out = [(1009, 928, 1), (1011, 948), (1016, 962), (1028, 976), (1048, 990), (1068, 997), (1082, 993), (1076, 980),
               (1058, 966), (1050, 950), (1049, 928, 1)]
        lames = [(1014, 960), (1054, 958)], [(1024, 974), (1068, 984)]
    sh = smooth([(p[0] + 18, p[1] + 6) for p in out[3:9]] + [(out[8][0] + 30, 1004), (out[3][0] + 30, 1004)])
    inner = "".join(path(smooth(l, False), stroke=K["s2"], sw=1.6) for l in lames)
    return cel(smooth(out), "url(#gSteel)", [(sh, K["s2"], .6)], 2, inner=inner)


def legs():
    s = []
    for side in ("R", "L"):
        # along()의 off는 위→아래로 내려가는 팔다리에서 +가 화면 왼쪽이다. 빛은 화면 왼쪽에서 온다
        hp, kn, an = LEG[side]
        s.append(sabaton(side))
        s.append(cel(limb(hp, kn, 34, 24, 4), K["s1"], [(limb(along(hp, kn, 0, -18), along(hp, kn, 1, -11), 14, 10), K["s0"], .7)], 2))
        a, b = along(hp, kn, .2), along(hp, kn, .9)
        s.append(cel(limb(a, b, 31, 23, 3), "url(#gSteel)", [(limb(along(a, b, 0, -16), along(a, b, 1, -12), 14, 11), K["s2"], .6),
                                                           (limb(along(a, b, .1, 15), along(a, b, .9, 10), 5, 4), K["s6"], .55)], 2))
        s.append(path(f"M{pt(along(a, b, .98, -22))}L{pt(along(a, b, .98, 22))}", stroke=K["gold3"], sw=3.2))
        s.append(cel(limb(kn, an, 25, 17, 7), "url(#gSteel)", [(limb(along(kn, an, 0, -14), along(kn, an, 1, -9), 12, 9), K["s2"], .6),
                                                             (limb(along(kn, an, .15, 14), along(kn, an, .85, 9), 4, 3), K["s6"], .6)], 2))
        s.append(path(f"M{pt(along(kn, an, .12, 23))}Q{pt(along(kn, an, .5, 29))} {pt(along(kn, an, .96, 16))}", stroke=K["gold3"], sw=2.6))
        s.append(path(f"M{pt(along(kn, an, .12, -23))}Q{pt(along(kn, an, .5, -29))} {pt(along(kn, an, .96, -16))}", stroke=K["gold1"], sw=2.6))
        s.append(path(f"M{pt(along(kn, an, .96, -17))}L{pt(along(kn, an, .96, 17))}", stroke=K["gold3"], sw=3))
        kc = along(kn, an, -.03)
        cop = [(kc[0] + 24 * math.sin(math.radians(a)), kc[1] - 22 * math.cos(math.radians(a))) for a in range(0, 360, 45)]
        s.append(cel(smooth(cop), "url(#gSteel)", [(smooth([(kc[0] + 4, kc[1] - 30), (kc[0] + 30, kc[1] - 6), (kc[0] + 26, kc[1] + 30), (kc[0] + 4, kc[1] + 30)]), K["s2"], .55)], 2))
        s.append(path(smooth(cop), stroke=K["gold3"], sw=1.6, op=.9))
        s.append(path(circ(kc, 5.5), "url(#gGold)", K["ink"], 1.1))
    return "".join(s)


def skirt():
    """치마 끝단(진홍)과 가죽 띠 두 줄(pteruges)"""
    s = []
    hem = [(884, 560, 1), (1036, 560, 1), (1048, 640), (1056, 712, 1), (1030, 720), (1000, 712), (960, 722), (920, 712), (890, 720),
           (864, 712, 1), (872, 640)]
    pleats = "".join(path(f"M{x} 600L{x + (x - 960) * .1:.1f} 720", stroke=K["red0"], sw=1.6, op=.6) for x in range(880, 1050, 18))
    s.append(cel(smooth(hem), "url(#gRedV)", [], 1.8, inner=pleats))
    for y0, y1, n, x0, x1, fill in ((566, 694, 8, 880, 1040, "url(#gRedV)"), (570, 664, 7, 892, 1028, "url(#gRed)")):
        w = (x1 - x0) / n
        for i in range(n):
            cx = x0 + w * (i + .5)
            sp = (cx - 960) * .14  # 아래로 갈수록 바깥으로 벌어진다
            bot = y1 - abs(cx - 960) * .08
            strip = [(cx - w / 2 + 1, y0, 1), (cx + w / 2 - 1, y0, 1), (cx + w / 2 - 1 + sp, bot - 8), (cx + sp, bot + 2), (cx - w / 2 + 1 + sp, bot - 8)]
            s.append(cel(smooth(strip), fill, [(smooth([(cx + 2 + sp * .5, y0), (cx + w, y0), (cx + w + sp, bot + 4), (cx + 2 + sp, bot + 4)]), K["red0"], .45)], 1.5))
            s.append(path(smooth([(cx - w / 2 + 3 + sp * .9, bot - 7), (cx + sp, bot), (cx + w / 2 - 3 + sp * .9, bot - 7)], False), stroke=K["gold3"], sw=2.4))
            s.append(path(circ((cx + sp * .3, y0 + (y1 - y0) * .35), 2.2), "url(#gGold)", K["ink"], .7))
    return "".join(s)


def cuirass():
    """근육 흉갑(강철·금 테)"""
    left = [(930, 352, 1), (904, 356), (882, 364), (866, 382, 1), (862, 420), (868, 466), (882, 510), (893, 546), (889, 576, 1),
            (924, 580), (960, 588, 1)]
    pts = left + mirror(left[:-1])[::-1] + [(960, 358)]
    shades = [
        (smooth([(992, 350), (1080, 350), (1080, 600), (1000, 600), (1018, 540), (1030, 470), (1024, 410)]), K["s2"], .6),
        (smooth([(884, 440), (912, 456), (940, 454), (958, 440), (958, 462), (930, 470), (896, 462)]), K["s2"], .5),
        (smooth([(962, 440), (980, 454), (1010, 456), (1036, 440), (1030, 470), (990, 470)]), K["s1"], .5),
        (smooth([(880, 392), (906, 378), (940, 380), (952, 404), (930, 420), (896, 418)]), K["s6"], .45),
    ]
    lines = "".join(path(smooth(l, False), stroke=K["s2"], sw=1.6, op=.85) for l in (
        [(878, 434), (908, 452), (938, 450), (957, 436)], [(1042, 434), (1012, 452), (982, 450), (963, 436)],
        [(960, 376), (960, 560)], [(930, 486), (960, 494), (990, 486)], [(934, 524), (960, 530), (986, 524)]))
    s = [cel(smooth(pts), "url(#gSteel)", shades, 2.2, inner=lines)]
    s.append(path(smooth([(930, 352), (960, 358), (990, 352)], False), stroke=K["gold3"], sw=4))
    for side in (left, mirror(left)):
        s.append(path(smooth(side[:4], False), stroke=K["gold3"], sw=3.4))
    s.append(path(smooth(left[8:] + mirror(left[8:-1])[::-1], False), stroke=K["gold3"], sw=5))
    s.append(path(circ((960, 404), 13), "url(#gGold)", K["ink"], 1.4) + path(circ((960, 404), 6), K["ember"]) + path(circ((958, 402), 2), "#ffffff"))
    return "".join(s)


def neck():
    return cel(smooth([(930, 316, 1), (990, 316, 1), (994, 362, 1), (926, 362, 1)]), K["s0"], [], 1.6)


def arm_shield():
    """왼팔(화면 오른쪽): 방패 뒤로 들어간다"""
    sh, el, wr = (1062, 396), (1100, 494), (1114, 566)
    return (cel(limb(sh, el, 23, 19, 3), "url(#gRed)", [(limb(along(sh, el, 0, -11), along(sh, el, 1, -9), 12, 10), K["red1"], .6)], 2)
            + cel(limb(el, wr, 19, 16, 2), "url(#gSteel)", [], 2))


def arm_spear():
    """오른팔(화면 왼쪽): 세운 창을 가슴 높이에서 쥔다"""
    sh, el, wr = (858, 396), (822, 500), (772, 446)
    s = cel(limb(sh, el, 23, 19, 3), "url(#gRed)", [(limb(along(sh, el, 0, -11), along(sh, el, 1, -9), 12, 10), K["red1"], .6)], 2)
    s += cel(limb(el, wr, 19, 17, 2), "url(#gSteel)", [(limb(along(el, wr, 0, 9), along(el, wr, 1, 8), 10, 8), K["s2"], .55)], 2)
    for t in (.2, .82):
        s += path(f"M{pt(along(el, wr, t, -18.5))}L{pt(along(el, wr, t, 18.5))}", stroke=K["gold3"], sw=3)
    s += cel(circ(el, 15), "url(#gSteel)", [], 1.8) + path(circ(el, 15), stroke=K["gold3"], sw=1.6) + path(circ(el, 4), "url(#gGold)", K["ink"], 1)
    return s


def fist():
    """창을 감싼 장갑 주먹"""
    g = cel(smooth([(741, 418), (752, 410), (772, 410), (784, 418), (786, 436), (779, 451), (760, 455), (744, 449), (739, 434)]), "url(#gSteel)",
            [(smooth([(764, 404), (792, 404), (792, 460), (764, 460)]), K["s2"], .55)], 2,
            inner="".join(path(f"M740 {y}L786 {y}", stroke=K["s2"], sw=1.6) for y in (424, 433, 442)))
    g += path(smooth([(742, 416), (762, 410), (783, 416)], False), stroke=K["gold3"], sw=3)
    g += cel(smooth([(772, 408, 1), (758, 402), (746, 404), (742, 412, 1), (756, 412), (770, 416, 1)]), "url(#gSteel)", [], 1.4)
    return f'<g transform="translate(762 432) scale(1.3) translate(-762 -432)">{g}</g>'  # 어깨 갑옷에 맞춰 키운다


def spear():
    """자루·창날·술(진홍)·물미. 주먹은 따로 위에 얹는다"""
    s = []
    u = unit(SP_B, SP_T)
    ang = math.degrees(math.atan2(u[0], -u[1]))
    s.append(path(poly([along(SP_B, SP_T, 0, -4.6), along(SP_B, SP_T, 0, 4.6), along(SP_B, SP_T, 1, 4), along(SP_B, SP_T, 1, -4)]),
                  "url(#gWood)", K["ink"], 1.2))
    for t in (.45, .52, .59):  # 손잡이 감은 끈
        s.append(path(f"M{pt(along(SP_B, SP_T, t, -5))}L{pt(along(SP_B, SP_T, t, 5))}", stroke=K["red1"], sw=2.4))
    butt = [along(SP_B, SP_T, .045, -6), along(SP_B, SP_T, .045, 6), along(SP_B, SP_T, 0, 1.5), along(SP_B, SP_T, 0, -1.5)]
    s.append(path(poly(butt), "url(#gGold)", K["ink"], 1.2))
    blade = [(0, -118, 1), (8, -92), (14, -58), (12, -28), (5, -8), (5, 0, 1), (-5, 0, 1), (-5, -8), (-12, -28), (-14, -58), (-8, -92)]
    head = (cel(smooth(blade), "url(#gSteel)", [(smooth([(0, -120), (20, -60), (14, 4), (0, 4)]), K["s3"], .6)], 1.8)
            + path("M0 -6L0 -112", stroke=K["s6"], sw=1.6) + path("M1.6 -8L1.6 -104", stroke=K["s2"], sw=1.2)
            + cel(smooth([(-6, 0, 1), (6, 0, 1), (7, 30, 1), (-7, 30, 1)]), "url(#gGold)", [], 1.4)
            + "".join(path(f"M-7 {y}L7 {y}", stroke=K["gold0"], sw=1.4) for y in (8, 22)))
    s.append(f'<g transform="translate({SP_T[0]} {SP_T[1]}) rotate({ang:.1f})">{head}</g>')
    tie = along(SP_T, SP_B, .042)  # 술: 슴베 아래에서 바람 쪽(화면 왼쪽)으로 날린다
    for k, (dx, dy, w) in enumerate(((-34, 70, 6), (-46, 58, 5), (-24, 84, 5))):
        pts = [tie, (tie[0] - 6 + dx * .3, tie[1] + dy * .4), (tie[0] + dx * .8, tie[1] + dy * .8), (tie[0] + dx, tie[1] + dy)]
        s.append(path(ribbon(pts, w, head=.05, tail=.4), "url(#gRed)" if k != 1 else K["red1"], K["ink"], .8))
    s.append(path(circ(tie, 5), "url(#gGold)", K["ink"], 1.1))
    return "".join(s)


def pauldron(c, sign):
    """어깨 갑옷: 겹친 판 둘 + 성가퀴 머리 셋을 얹은 둥근 판. sign = 1이면 바깥이 화면 오른쪽"""
    def sx(pts):  # 화면 기준 좌표(+x = 화면 오른쪽)를 국소 좌표로. 그늘을 늘 화면 오른쪽에 두려는 것
        return [(x * sign, y) + tuple(r) for x, y, *r in pts]
    g = []
    for k in (2, 1):  # 아래 판부터
        dy, inn = 22 * k, 6 * k
        band = smooth([(-28 + inn, 22 + dy), (8, 34 + dy), (42, 32 + dy), (66 - k * 2, 18 + dy), (70 - k * 2, 34 + dy), (60 - k * 3, 52 + dy),
                       (28, 60 + dy), (-6, 56 + dy), (-26 + inn, 44 + dy)])
        g.append(cel(band, "url(#gSteelV)", [(smooth([(-40, 46 + dy), (80, 46 + dy), (80, 80 + dy), (-40, 80 + dy)]), K["s2"], .55)], 1.8,
                     inner=path(smooth([(-24 + inn, 40 + dy), (-4, 52 + dy), (28, 56 + dy), (58 - k * 3, 48 + dy)], False), stroke=K["gold3"], sw=2.4)))
    for x, y, a in ((-20, -42, -28), (12, -50, 2), (42, -38, 34)):
        m = smooth([(-10, 8, 1), (-10, -12, 1), (10, -12, 1), (10, 8, 1)])
        g.append(f'<g transform="translate({x} {y}) rotate({a})">'
                 + cel(m, "url(#gSteelV)", [(smooth(sx([(2, -16), (14, -16), (14, 10), (2, 10)])), K["s2"], .5)], 1.6)
                 + path("M-9 -11L9 -11", stroke=K["gold3"], sw=2.4) + "</g>")
    dome = smooth([(-46, 10), (-44, -16), (-30, -38), (-4, -50), (24, -50), (48, -36), (64, -10), (68, 16), (60, 36), (34, 44), (4, 42), (-26, 34)])
    g.append(cel(dome, "url(#gSteel)", [(smooth(sx([(14, -64), (90, -64), (90, 64), (20, 64), (34, 20), (30, -24)])), K["s2"], .55),
                                        (smooth(sx([(-34, -18), (-22, -36), (0, -46), (-10, -32), (-26, -12)])), K["s6"], .7)], 2.2))
    g.append(path(smooth([(68, 16), (60, 36), (34, 44), (4, 42), (-26, 34)], False), stroke=K["gold3"], sw=3.2))
    g.append(path(smooth([(-38, -6), (-26, -28), (-4, -40), (24, -40), (44, -26), (56, -4)], False), stroke=K["gold4"], sw=1.4, op=.7))
    for p in ((-28, 20), (2, 28), (30, 30), (52, 20)):
        g.append(path(circ(p, 3), "url(#gGold)", K["ink"], .8))
    return f'<g transform="translate({c[0]} {c[1]}) scale({sign} 1)">' + "".join(g) + "</g>"


HELM_OPEN = [(918, 268, 1), (930, 260), (946, 258), (954, 261, 1), (955, 275), (955.5, 290, 1), (958, 297), (962, 297), (964.5, 290, 1),
             (965, 275), (966, 261, 1), (974, 258), (990, 260), (1002, 268, 1), (992, 276), (978, 280), (970, 286, 1), (971, 310),
             (974, 346, 1), (946, 346, 1), (949, 310), (950, 286, 1), (942, 280), (928, 276)]


def helmet():
    """얼굴을 가린 코린트식 투구와 진홍 깃"""
    s = []
    plume = [(946, 210, 1), (941, 186), (937, 160), (940, 138), (951, 122), (966, 116), (980, 122), (990, 138), (991, 162), (985, 188), (974, 210, 1)]
    strands = "".join(path(smooth(l, False), stroke=K["red0"], sw=1.4, op=.7) for l in (
        [(948, 206), (944, 170), (950, 132)], [(958, 208), (956, 160), (962, 122)], [(968, 208), (972, 160), (976, 126)], [(978, 206), (984, 168), (984, 140)]))
    s.append(cel(smooth(plume), "url(#gRed)", [(smooth([(966, 112), (998, 130), (996, 214), (970, 214), (980, 170)]), K["red1"], .6)], 1.8, inner=strands))
    left = [(960, 203), (935, 208), (916, 222), (905, 245), (902, 272), (904, 298), (908, 320), (915, 338, 1), (931, 342), (946, 348), (960, 350)]
    shell = smooth(left + mirror(left[1:-1])[::-1])
    s.append(cel(shell, "url(#gSteel)", [
        (smooth([(968, 198), (1030, 198), (1030, 360), (976, 360), (994, 320), (1004, 270), (996, 230)]), K["s2"], .55),
        (smooth([(918, 240), (930, 220), (952, 210), (942, 226), (928, 244), (922, 262)]), K["s6"], .75),
        (smooth([(904, 300), (936, 306), (950, 330), (950, 356), (900, 356)]), K["s3"], .35)], 2.2))
    for side in (left, mirror(left)):
        s.append(path(smooth(side[7:10], False), stroke=K["gold3"], sw=2.6))
    s.append(path(smooth([(908, 258), (930, 250), (950, 250), (960, 255)], False), stroke=K["gold3"], sw=3.2))
    s.append(path(smooth([(1012, 258), (990, 250), (970, 250), (960, 255)], False), stroke=K["gold3"], sw=3.2))
    s.append(path(smooth([(960, 205), (960, 255)], False), stroke=K["gold3"], sw=2.4, op=.85))
    s.append(cel(smooth(HELM_OPEN), "url(#gVoid)", [], 1.6, line=K["gold1"]))
    for e in ((934, 269), (986, 269)):
        s.append(path(smooth([(e[0] - 7, e[1]), (e[0], e[1] - 2.6), (e[0] + 7, e[1]), (e[0], e[1] + 2.2)]), K["ember"]))
        s.append(path(circ(e, 1.6), "#ffffff"))
    s.append(cel(smooth([(944, 204, 1), (976, 204, 1), (974, 216, 1), (946, 216, 1)]), "url(#gGold)", [], 1.4))
    for x in (950, 960, 970):
        s.append(path(circ((x, 210), 1.6), K["gold5"]))
    return "".join(s)


def shield():
    """탑 방패: 윗변이 성가퀴, 왼쪽·아래 가장자리에 일곱 겹 판, 가운데 성채 문장과 룬 고리"""
    x0, x1, top, bot = SHIELD
    m, up = (x1 - x0) / 5, 34
    out = [(x0, top - up, 1), (x0 + m, top - up, 1), (x0 + m, top, 1), (x0 + 2 * m, top, 1), (x0 + 2 * m, top - up, 1), (x0 + 3 * m, top - up, 1),
           (x0 + 3 * m, top, 1), (x0 + 4 * m, top, 1), (x0 + 4 * m, top - up, 1), (x1, top - up, 1), (x1 + 4, 600), (x1 + 4, 830), (x1, bot - 34),
           (x1 - 34, bot - 6), ((x0 + x1) / 2, bot + 8), (x0 + 34, bot - 6), (x0, bot - 34), (x0 - 4, 830), (x0 - 4, 600)]
    d = smooth(out)
    s = []
    for k in range(7, 0, -1):  # 일곱 겹: 뒤 판일수록 왼쪽 아래로 밀린다
        s.append(f'<g transform="translate({-2.2 * k:.1f} {1.6 * k:.1f})">' + path(d, K["s3"] if k % 2 else K["s2"], K["ink"], 1) + "</g>")
    sheen = smooth([(x0 + 22, top - 40), (x0 + 50, top - 40), (x0 + 54, bot + 10), (x0 + 26, bot + 10)])
    inner = [path(d, stroke=K["ink"], sw=22), path(d, stroke=K["gold2"], sw=16), path(d, stroke=K["gold3"], sw=11)]
    for y in (520, 810):
        inner.append(path(f"M{x0} {y}L{x1 + 6} {y}", stroke=K["gold1"], sw=2.4) + path(f"M{x0} {y - 2.4}L{x1 + 6} {y - 2.4}", stroke=K["gold4"], sw=1, op=.6))
    inner.append(path(f"M{EMB[0]} {top - up}L{EMB[0]} {bot + 10}", stroke=K["gold2"], sw=8) + path(f"M{EMB[0] - 2} {top - up}L{EMB[0] - 2} {bot + 10}", stroke=K["gold4"], sw=1.6))
    s.append(cel(d, "url(#gShield)", [(sheen, K["s6"], .35), (smooth([(1225, 380), (1300, 380), (1300, 1000), (1215, 1000)]), K["s1"], .45)], 2.4,
                 inner="".join(inner)))
    for y in range(470, 960, 44):  # 테두리 리벳
        for x in (x0 + 4, x1 - 4):
            s.append(path(circ((x, y), 2.6), K["gold5"], K["gold0"], .8))
    s.append(emblem())
    return "".join(s)


def emblem():
    cx, cy = EMB
    s = [f'<g transform="translate({cx} {cy}) scale(110)" opacity=".55"><circle r="1" fill="url(#gGlow)"/></g>']
    s.append(path(circ(EMB, 92), K["s2"], op=.55))
    ring = [path(circ(EMB, 90), stroke=K["gold3"], sw=2.6), path(circ(EMB, 72), stroke=K["gold3"], sw=1.8)]
    for i, rd in enumerate(runes(18, 7)):
        x, y = pol(EMB, 81, i * 20)
        ring.append(f'<path d="{rd}" transform="translate({x:.1f} {y:.1f}) rotate({i * 20})" fill="none" stroke="{K["gold5"]}" '
                    'stroke-width="1.6" stroke-linecap="round"/>')
    rg = "".join(ring)
    s.append(f'<g filter="url(#fB4)">{rg}</g>{rg}')
    # 성채: 가운데 큰 탑 + 양옆 작은 탑 + 아래 성벽, 가운데 성문 아치에 불빛
    keep = [(cx - 20, cy + 46, 1), (cx - 20, cy - 52, 1)] + crenel(cx - 20, cx + 20, cy - 52, 9, 6.5, 10) + [(cx + 20, cy + 46, 1)]
    towers = []
    for sgn in (-1, 1):
        a, b = cx + sgn * 24, cx + sgn * 50
        lo, hi = min(a, b), max(a, b)
        towers.append([(lo, cy + 46, 1), (lo, cy - 26, 1)] + crenel(lo, hi, cy - 26, 8, 5, 9) + [(hi, cy + 46, 1)])
    wall = [(cx - 58, cy + 58, 1), (cx - 58, cy + 30, 1)] + crenel(cx - 58, cx + 58, cy + 30, 7, 5, 7) + [(cx + 58, cy + 58, 1)]
    for shape in towers + [keep, wall]:
        s.append(cel(poly(shape), "url(#gGold)", [(poly([(cx + 4, cy - 80), (cx + 70, cy - 80), (cx + 70, cy + 70), (cx + 4, cy + 70)]), K["gold1"], .35)], 1.6))
    gate = smooth([(cx - 11, cy + 58, 1), (cx - 11, cy + 30), (cx, cy + 18), (cx + 11, cy + 30), (cx + 11, cy + 58, 1)])
    s.append(path(gate, K["void"], K["ink"], 1.4))
    s.append(f'<g filter="url(#fB4)">{path(gate, K["ember"], op=.9)}</g>' + path(gate, K["ember"], op=.55))
    for x in (cx - 6, cx, cx + 6):
        s.append(path(f"M{x} {cy + 24}L{x} {cy + 58}", stroke=K["gold0"], sw=1.6))
    for x, y in ((cx, cy - 26), (cx - 37, cy - 6), (cx + 37, cy - 6)):
        s.append(path(smooth([(x - 2.4, y + 8, 1), (x - 2.4, y - 4), (x, y - 7), (x + 2.4, y - 4), (x + 2.4, y + 8, 1)]), K["ember"], K["gold0"], .8))
    return "".join(s)


def hero():
    parts = [cape(), crest_tail(), legs(), skirt(), neck(), cuirass(), arm_shield(), spear(), arm_spear(), helmet(),
             pauldron((852, 388), -1), pauldron((1068, 388), 1), fist(), shield()]
    return '<g id="hero">' + "".join(parts) + "</g>"


def eyes_glow():
    g = path(circ((934, 269), 6), K["ember"]) + path(circ((986, 269), 6), K["ember"])
    return f'<g filter="url(#fB4)" opacity=".9">{g}</g>'


def fill_light():
    """인물 실루엣 안에만 왼쪽 위 차가운 채움빛과 아래 금빛 반사광을 얹어 부피를 살린다"""
    return (f'<filter id="fWhite"><feColorMatrix type="matrix" values="0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 1 0"/></filter>'
            f'<mask id="mHero" maskUnits="userSpaceOnUse" x="0" y="0" width="{W}" height="{H}"><use href="#hero" filter="url(#fWhite)"/></mask>'
            + rad("gFillC", [(0, "#cfe0ff", .16), (.6, "#a4aec2", .05), (1, "#a4aec2", 0)], 800, 300, 520)
            + rad("gFillG", [(0, K["gold4"], .2), (.5, K["gold3"], .07), (1, K["gold3"], 0)], 960, 1000, 380)
            + f'<g mask="url(#mHero)" style="mix-blend-mode:screen"><rect width="{W}" height="{H}" fill="url(#gFillC)"/>'
              f'<rect width="{W}" height="{H}" fill="url(#gFillG)"/></g>')


# ── 컨셉 시트 ─────────────────────────────────────────────────────────

def ornament(x0, x1, y):
    m = (x0 + x1) / 2
    return (path(f"M{x0} {y}L{m - 16} {y}M{m + 16} {y}L{x1} {y}", stroke=K["gold3"], sw=1.2, op=.8)
            + diamond((m, y), 7, K["gold3"]) + diamond((m, y), 3, K["red2"])
            + diamond((m - 24, y), 3, K["gold4"]) + diamond((m + 24, y), 3, K["gold4"]))


INSETS = [  # (원 중심, 반지름, 보는 곳, 배율, 제목, 설명)
    ((1716, 236), 92, (960, 262), 1.7, "THE CRESTED HELM", "faceless steel · ember gaze"),
    ((1716, 520), 92, EMB, 1.0, "SEVENFOLD SHIELD", "seven plates · citadel crest"),
    ((1716, 804), 92, (740, 110), 1.45, "SPEAR OF THE LINE", "leaf blade · crimson tassel"),
]
PALETTE = [("STEEL", K["s4"], True), ("DEEP STEEL", K["s2"], True), ("GOLD", K["gold3"], True),
           ("PALE GOLD", K["gold4"], True), ("CRIMSON", K["red2"], True), ("EMBER GLOW", K["ember"], False)]


def sheet():
    s = [label("HERO CONCEPT", 74, 104, 14, K["red4"], 700, 5),
         rad("gTitle", [(0, K["gold5"]), (.5, K["gold3"]), (1, K["gold2"])], 200, 130, 260),
         f'<g filter="url(#fB8)" opacity=".5">{label("AIAS", 70, 184, 72, K["gold3"], 700, 10)}</g>',
         label("AIAS", 70, 184, 72, "url(#gTitle)", 700, 10),
         label("THE STEEL CITADEL", 74, 220, 19, K["gold5"], 700, 5.2),
         ornament(74, 426, 244),
         label("SHIELD-BEARER · TANK", 74, 278, 15, K["red4"], 700, 4),
         label("“Where I stand, the line holds.”", 74, 308, 15, K["gold5"], 500, 1, op=.78)]
    for k, (c, r, f, z, t, sub) in enumerate(INSETS):
        s.append(f'<clipPath id="ins{k}"><circle cx="{c[0]}" cy="{c[1]}" r="{r}"/></clipPath>')
        s.append(path(circ(c, r + 18), K["s4"], op=.08))
        s.append(f'<circle cx="{c[0]}" cy="{c[1]}" r="{r}" fill="{K["s0"]}"/>')
        s.append(f'<g clip-path="url(#ins{k})"><use href="#scene" transform="translate({c[0]} {c[1]}) scale({z}) translate({-f[0]} {-f[1]})"/></g>')
        s.append(path(circ(c, r), stroke=K["gold3"], sw=2.6))
        s.append(path(circ(c, r + 7), stroke=K["gold3"], sw=.9, op=.6))
        for i in range(24):
            s.append(path(f"M{pt(pol(c, r + 3, i * 15))}L{pt(pol(c, r + 7 + (3 if i % 6 == 0 else 0), i * 15))}", stroke=K["gold4"], sw=1.6 if i % 6 == 0 else .9))
        s.append(diamond((c[0], c[1] - r - 7), 6, K["gold3"]))
        s.append(label(t, c[0], c[1] + r + 38, 15, K["gold4"], 700, 3, "middle"))
        s.append(label(sub, c[0], c[1] + r + 60, 13, K["gold5"], 500, 1.2, "middle", op=.72))
    s.append(label("PALETTE", 74, 930, 13, K["red4"], 700, 4))
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
    scene = [background(), rampart(), floor(),
             '<ellipse cx="985" cy="994" rx="180" ry="15" fill="#02040a" opacity=".7" filter="url(#fB4)"/>',
             hero(),
             '<g mask="url(#mRim)" style="mix-blend-mode:screen"><use href="#hero" filter="url(#fRim)"/></g>',
             fill_light(), eyes_glow(), embers(),
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
    for name, on in (("aias", True), ("aias_clean", False)):  # 컨셉 시트 / 그림만
        svg = out / f"{name}.svg"
        svg.write_text(build(on), encoding="utf-8")
        print(svg)
        if not a.no_png:
            print(shot.shot(svg, out / f"{name}_{W * a.scale}.png", a.scale))
