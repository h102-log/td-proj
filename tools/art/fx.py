# 이펙트 도트 조각 아틀라스(4.1s fx-1): 조각마다 한 줄에 프레임을 가로로 잇고, 이름 → [x, y, 폭, 높이, 프레임 수]를 json으로 쓴다.
# 색은 F24+(palettes.json f24p)와 이펙트 확장 램프(fx, 보라 5색 + 연두 5색)만 쓴다. 출발점은 시안 C(insights/2026-10-27_hero_fx_mockup.md)이고,
# Gemini 고칠 점대로 폭발은 밝은 섬광부터 시작하며 연기는 따로 떼어(puff) 유닛 아래 층에 그린다.
# fx-2(아이아스·실비아)·fx-3(세라피나·베스퍼)의 조각은 맨 뒤에 붙여 앞 조각의 자리가 그대로다
# 사용: python tools/art/fx.py [preview]  → art/fx/fx.png, art/fx/fx.json (preview면 art/trial/preview/fx_atlas_x6.png)
import json
import math
import random
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
PAL = json.loads((Path(__file__).parent / "palettes.json").read_text(encoding="utf-8"))
ALLOWED = set(PAL["f24p"]) | set(PAL["fx"])


def rgb(h):
    assert h in ALLOWED, h
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


FIRE = [rgb(c) for c in ["efd8a1", "efac28", "ef692f", "ef3a0c", "9b1a0a"]]  # 밝음 → 어두움
SMOKE = [rgb(c) for c in ["927e6a", "684c3c", "392a1c", "2a1d0d"]]
ICE = [rgb(c) for c in ["d0d6e0", "a4aec2", "7a86a0", "4f78ad", "3a4357"]]
LAVA = [rgb(c) for c in ["efac28", "ef692f", "ef3a0c", "9b1a0a", "550f0a", "300f0a", "2a1d0d"]]
VIO = [rgb(c) for c in PAL["fx"][:5]]  # 블랙홀·아이아스
LIME = [rgb(c) for c in PAL["fx"][5:]]  # 실비아(fx-2)
HOLY = [rgb(c) for c in ["efd8a1", "efac28", "efb775", "ab5c1c"]]  # 세라피나(fx-3): 크림 → 금 → 모래 → 구리
TEAL = [rgb(c) for c in ["3c9f9c", "276468", "183f39"]]  # 베스퍼(fx-3): 밝음 → 어두움
NIGHT = rgb("151a26")


def canvas(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def put(im, x, y, c):
    if 0 <= x < im.width and 0 <= y < im.height:
        im.putpixel((int(x), int(y)), c)


def bubble(im, cx, cy, r, ramp, hollow=0.0, light=(-0.45, -0.5)):
    """음영 있는 덩어리: 왼쪽 위에서 빛. hollow > 0이면 왼쪽 위를 파내 초승달이 된다. 가장자리 한 칸은 한 단계 어둡게"""
    for y in range(int(cy - r - 1), int(cy + r + 2)):
        for x in range(int(cx - r - 1), int(cx + r + 2)):
            nx, ny = (x + 0.5 - cx) / r, (y + 0.5 - cy) / r
            d = math.hypot(nx, ny)
            if d > 1.0 or (hollow and math.hypot(nx + 0.35, ny + 0.35) < hollow):
                continue
            i = min(int(math.hypot(nx - light[0], ny - light[1]) * len(ramp) / 1.7), len(ramp) - 1)
            put(im, x, y, ramp[min(i + 1, len(ramp) - 1)] if d > 0.82 else ramp[i])


def disc(im, cx, cy, r, col):
    for y in range(im.height):
        for x in range(im.width):
            if math.hypot(x + 0.5 - cx, y + 0.5 - cy) <= r:
                im.putpixel((x, y), col)


def star(im, cx, cy, r0, r1, n, ramp, rot=0.0):
    for y in range(im.height):
        for x in range(im.width):
            dx, dy = x + 0.5 - cx, y + 0.5 - cy
            d, a = math.hypot(dx, dy), math.atan2(dy, dx) + rot
            lim = r0 + (r1 - r0) * abs(math.cos(a * n / 2)) ** 6
            if d <= lim:
                k = d / lim
                im.putpixel((x, y), ramp[0] if k < 0.35 else ramp[1] if k < 0.75 else ramp[2])


def ascii(rows, pal):
    im = canvas(len(rows[0]), len(rows))
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch != ".":
                im.putpixel((x, y), pal[ch])
    return im


def flame(w, h, frames, seed):
    """불꽃(아래가 바닥). 가운데 축에서 멀수록, 위로 갈수록 어둡다. 끝이 좌우로 흔들린다"""
    out, r = [], random.Random(seed)
    for f in range(frames):
        im = canvas(w, h)
        sway = [0, 1, 0, -1][f % 4]
        for y in range(h):
            t = 1 - (y + 0.5) / h  # 0 바닥 → 1 끝
            half = (w / 2 - 0.3) * math.sin(math.pi * min(1.0, (1 - t) ** 0.55)) * (1 - t * 0.15)
            cx = w / 2 + sway * t * t * 1.6
            for x in range(w):
                dx = abs(x + 0.5 - cx)
                if dx <= half + (0.6 if r.random() < 0.15 else 0):
                    k = dx / max(half, 0.5) * 0.6 + t * 0.8
                    i = 0 if k < 0.35 else 1 if k < 0.65 else 2 if k < 0.95 else 3
                    im.putpixel((x, y), FIRE[min(i + 1, 4)] if y == h - 1 else FIRE[i])
        out.append(im)
    return out


def boom():
    """폭발 6프레임 40×40: 흰 섬광 → 날카로운 터짐 → 불 덩어리 → 파이는 덩어리 → 초승달 → 부스러기(Saint11 순서에서 대비 섬광을 뺐다)"""
    r = random.Random(7)
    blobs = [(r.uniform(-9, 9), r.uniform(-8, 7), r.uniform(5, 8)) for _ in range(6)]
    out = []
    for f in range(6):
        im = canvas(40, 40)
        if f == 0:
            disc(im, 20, 20, 12, FIRE[1])
            disc(im, 20, 20, 10, FIRE[0])
            for a in range(4):  # 빛줄기
                for t in range(13, 18):
                    put(im, 20 + math.cos(a * math.pi / 2 + 0.6) * t, 20 + math.sin(a * math.pi / 2 + 0.6) * t, FIRE[0])
        elif f == 1:
            star(im, 20, 20, 7, 19, 8, FIRE, 0.3)
        else:
            g = f - 2  # 0..3
            for bx, by, br in blobs:
                bubble(im, 20 + bx * (1 + 0.2 * g), 20 + by * (1 + 0.2 * g) - g, br * (1 - 0.15 * g), FIRE[g // 2:], hollow=0.0 if g == 0 else 0.4 + 0.2 * g)
        out.append(im)
    return out


def lava(seed):
    """용암 자국 48×48: 들쭉날쭉한 굳은 껍질(바깥 3px는 체커로 성기게) + 가운데서 가지 치는 균열(밝은 심 + 붉은 테) + 뜨거운 점"""
    im, r = canvas(48, 48), random.Random(seed)
    edge = [21 + r.uniform(-2.5, 1.5) for _ in range(16)]
    for y in range(48):
        for x in range(48):
            dx, dy = x + 0.5 - 24, y + 0.5 - 24
            a = (math.atan2(dy, dx) / (2 * math.pi) + 1) % 1 * 16
            e = edge[int(a)] * (1 - a % 1) + edge[(int(a) + 1) % 16] * (a % 1)
            d = math.hypot(dx, dy)
            if d <= e and ((x + y) % 2 == 0 or d < e - 3):
                im.putpixel((x, y), LAVA[5] if d < e - 6 else LAVA[6])
    paths = [(k * math.pi * 2 / 5 + r.uniform(-0.4, 0.4), 24.0, 24.0, 17) for k in range(5)]
    while paths:
        ang, x, y, n = paths.pop()
        for s in range(n):
            ang += r.uniform(-0.9, 0.9)
            x, y = x + math.cos(ang), y + math.sin(ang)
            if s == 5 and n > 8 and r.random() < 0.6:  # 가지
                paths.append((ang + r.choice([-1, 1]) * 0.9, x, y, n - 9))
            px, py = int(x), int(y)
            for ox, oy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                if 0 <= px + ox < 48 and 0 <= py + oy < 48 and im.getpixel((px + ox, py + oy))[3]:
                    im.putpixel((px + ox, py + oy), LAVA[3])
            put(im, px, py, LAVA[1] if s < 10 else LAVA[2])
    for _ in range(5):
        bubble(im, 24 + r.uniform(-8, 8), 24 + r.uniform(-8, 8), 1.8, LAVA[:3])
    return im


def eye(f):
    """블랙홀 눈 15×15: 어두운 가운데, 도는 소용돌이 팔 둘"""
    im = canvas(15, 15)
    for y in range(15):
        for x in range(15):
            dx, dy = x + 0.5 - 7.5, y + 0.5 - 7.5
            d = math.hypot(dx, dy)
            if d > 7.2:
                continue
            arm = (math.cos(2 * (math.atan2(dy, dx) - f * math.pi / 8) + d * 0.9) + 1) / 2
            if d < 2.2:
                c = NIGHT
            elif arm > 0.72:
                c = VIO[0] if d < 3.6 else VIO[1] if d < 5.5 else VIO[2]
            elif arm > 0.4:
                c = VIO[2] if d < 5 else VIO[3]
            else:
                c = VIO[3] if d < 4.5 else VIO[4]
            im.putpixel((x, y), c)
    return im


def meteor(f):
    """운석 11×11: 왼쪽 아래 돌, 오른쪽 위 불꽃 머리(오른쪽 위에서 떨어진다)"""
    im = canvas(11, 11)
    bubble(im, 7.5, 3.5, 3.4 + 0.3 * f, FIRE[1:])
    bubble(im, 8.6 + 0.4 * f, 2.4, 2.4 + 0.3 * f, FIRE)
    bubble(im, 4.3, 6.7, 3.6, SMOKE)
    return im


def shield_mask(w, h):
    """연 모양 방패: 위 7줄은 폭 그대로(위 모서리만 깎음), 그 아래는 끝으로 좁아진다"""
    cells = set()
    for y in range(h):
        half = (w / 2 - 0.5) if y < h * 0.55 else (w / 2 - 0.5) * (h - 0.5 - y) / (h * 0.45)
        if y == 0:
            half -= 1
        for x in range(w):
            if abs(x + 0.5 - w / 2) <= half + 0.01:
                cells.add((x, y))
    return cells


def aegis(f):
    """반격의 태세(아이아스 E) 11×13: 흰 방패 번쩍 → 보라 방패(크림 테, 가운데 문장) → 테만 남음"""
    im, cells = canvas(11, 13), shield_mask(11, 13)
    rim = {c for c in cells if any((c[0] + dx, c[1] + dy) not in cells for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))}
    for x, y in cells:
        if f == 0:
            im.putpixel((x, y), VIO[0] if (x, y) in rim else rgb("efd8a1"))
        elif f == 1:
            emblem = x == 5 and 2 <= y <= 9 or y == 4 and 2 <= x <= 8
            im.putpixel((x, y), rgb("efd8a1") if (x, y) in rim else VIO[0] if emblem else VIO[1] if x < 5 else VIO[2])
        elif (x, y) in rim:
            im.putpixel((x, y), VIO[1])
    return im


def spike(im, cx, cy, ang, r0, r1, ramp):
    """가운데에서 ang 쪽 r0~r1 사이의 짧은 조각. 바깥 끝일수록 어둡다"""
    n = max(int((r1 - r0) * 2), 1)
    for i in range(n + 1):
        r = r0 + (r1 - r0) * i / n
        put(im, cx + math.cos(ang) * r, cy + math.sin(ang) * r, ramp[min(int(i / (n + 1) * len(ramp)), len(ramp) - 1)])


def burst(f):
    """반격의 태세 터뜨림(아이아스 E) 5프레임 32×32: 크림 섬광 → 보라 8각 별 → 바깥으로 튀는 조각 → 흩어지는 점"""
    im = canvas(32, 32)
    if f == 0:
        disc(im, 16, 16, 11, VIO[0])
        disc(im, 16, 16, 9, rgb("efd8a1"))
    elif f == 1:
        star(im, 16, 16, 6, 15, 8, [rgb("efd8a1"), VIO[0], VIO[1]], 0.4)
    else:
        g = f - 2  # 0..2
        for k in range(8):
            a = k * math.pi / 4 + 0.4 + (math.pi / 8 if k % 2 else 0)
            r0 = 7 + 3 * g + (2 if k % 2 else 0)
            spike(im, 16, 16, a, r0, r0 + 4 - g, VIO[g:g + 3])
        if g == 0:
            disc(im, 16, 16, 3, VIO[1])
    return im


def ward(f):
    """에너지 성벽 한 칸(아이아스 R) 16×22: 위 16줄은 칸 윗면, 아래 6줄은 앞면. 안쪽은 체커로 성기게 칠해 비쳐 보이고,
    테두리가 없어 이웃 칸과 한 벽으로 이어진다(윗면 끝의 밝은 선은 벽 줄의 바깥 끝에만 battle_view가 긋는다).
    0~2프레임은 옅은 줄이 앞면에서 윗면 위로 지나가고, 3프레임은 끝나 갈 때 금 간 모습이다"""
    im = canvas(16, 22)
    scan = [19, 10, 3][f] if f < 3 else -9
    for y in range(22):
        for x in range(16):
            if f == 3 and (x * 7 + y * 3) % 5 == 0:
                continue
            if y == 21:
                c = ICE[4]
            elif y == scan:
                c = ICE[1]
            elif (x + y) % 2 == 0:
                c = ICE[1] if y < 16 and (x + 2 * y) % 7 == 0 else ICE[3] if y < 16 else ICE[2]
            else:
                continue
            im.putpixel((x, y), c)
    if f == 3:  # 금: 위에서 아래로 꺾이며 내려온다
        x = 6
        for y in range(1, 21):
            x += (1 if y % 5 == 2 else -1 if y % 5 == 4 else 0)
            im.putpixel((x, y), rgb("262d3d"))
    return im


def gust(f):
    """돌풍 갈래살이 켜진 실비아 발밑(실비아 W) 13×5: 발 둘레를 도는 바람 줄 둘. 머리가 밝고 꼬리가 어둡다. 프레임마다 45°씩 돈다"""
    im = canvas(13, 5)
    for j in range(2):
        for i in range(30):
            t = i / 29
            a = f * math.pi / 4 + j * math.pi + t * 2.2
            put(im, int(6.5 + math.cos(a) * 6.0), int(2.5 + math.sin(a) * 2.2), LIME[0] if t > 0.8 else LIME[1] if t > 0.45 else LIME[2])
    return im


def outline(im, col):
    """칠한 칸 가운데 빈 칸(또는 가장자리)에 닿은 칸만 col로 남긴다"""
    out = canvas(im.width, im.height)
    for y in range(im.height):
        for x in range(im.width):
            if im.getpixel((x, y))[3] and any(not (0 <= x + dx < im.width and 0 <= y + dy < im.height) or not im.getpixel((x + dx, y + dy))[3]
                                              for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                out.putpixel((x, y), col)
    return out


def wing(f):
    """수호 천사의 날개(세라피나 E) 21×9: 몸 자리(가운데 5칸)를 비우고 어깨에서 위·바깥으로 펼친 양 날개.
    크림 번쩍 → 날개(위 가장자리 크림, 덮깃 금, 깃 모래, 깃 끝 구리) → 테만"""
    left = ["CCC.....", "CGGCCC..", "CGGGGGCC", "TGGGGGGC", "TTTTTGG.", "TTTTTT..", "BTTTB...", "BTB.....", "B......."]
    rows = [row + "....." + row[::-1] for row in left]
    full = ascii(rows, {"C": HOLY[0], "G": HOLY[1], "T": HOLY[2], "B": HOLY[3]})
    if f == 1:
        return full
    if f == 0:
        return ascii([row.replace("G", "C").replace("T", "C").replace("B", "G") for row in rows], {"C": HOLY[0], "G": HOLY[1]})
    return outline(full, HOLY[2])


def glyph(f):
    """성역 가운데 성휘(세라피나 W) 11×11: 금 고리 안 크림 십자(아래가 긴 십자). 1프레임은 고리가 크림으로 반짝인다"""
    im = canvas(11, 11)
    for y in range(11):
        for x in range(11):
            d = math.hypot(x + 0.5 - 5.5, y + 0.5 - 5.5)
            if 4.3 < d <= 5.5:
                im.putpixel((x, y), HOLY[0] if f else HOLY[1])
    for y in range(2, 9):
        im.putpixel((5, y), HOLY[0])
    for x in range(3, 8):
        im.putpixel((x, 4), HOLY[0])
    return im


def fog(f):
    """독안개 조각(베스퍼 Q) 11×5: 체커로 성기게 칠한 납작한 안개(가운데 밝음). 프레임마다 체커가 엇갈려 일렁인다"""
    im = canvas(11, 5)
    for y in range(5):
        for x in range(11):
            d = math.hypot((x + 0.5 - 5.5) / 5.5, (y + 0.5 - 2.5) / 2.5)
            if d <= 1.0 and (x + y + f) % 2 == 0:
                im.putpixel((x, y), TEAL[0] if d < 0.5 else TEAL[1])
    return im

IP = {"W": ICE[0], "I": ICE[1], "i": ICE[2], "D": ICE[3], "N": ICE[4]}
SP = {"W": FIRE[0], "Y": FIRE[1], "O": FIRE[2]}
RP = {"A": SMOKE[0], "S": SMOKE[1], "D": SMOKE[2]}
sprites = {
    "boom": boom(),
    "puff": [],
    "flame": flame(5, 7, 4, 5),  # 불길 장판
    "flame_s": flame(3, 5, 4, 9),  # 발화 상태(고블린 키의 절반 아래, Gemini 고칠 점 2)
    "shard": [ascii(rows, IP) for rows in (
        [".....", ".....", ".....", "..W..", ".WIi.", ".WIiD", ".WIiN", ".WiN.", "..N.."],
        ["..W..", ".WWi.", ".WIi.", "WWIiD", "WIIiD", "WIIiD", ".WIiN", ".WiN.", "..N.."],
        ["..W..", ".W.i.", ".WI..", "W.Ii.", "WI..D", ".II.D", ".W.iN", "..iN.", "....."])],
    "frost": [ascii(["..W...W..", ".WIW.WIi.", "WIIiIIIiD", ".NiNNiNN."], IP)],  # 둔화: 발밑 서리 껍질(Gemini 고칠 점 3)
    "star": [ascii(["..Y..", "..W..", "YWWWY", "..W..", "..Y.."], SP), ascii([".....", ".Y.Y.", "..W..", ".Y.Y.", "....."], SP)],
    "rock": [ascii(["AS.", "SSD", ".DD"], RP), ascii([".A.", "ASD", "SD."], RP)],
    "meteor": [meteor(0), meteor(1)],
    "lava": [lava(11), lava(12)],
    "pop": [],
    "eye": [eye(f) for f in range(4)],
    # 상태 아이콘(I101 2026-10-27 변경): 1차 상태는 머리 위 기호, 2차는 몸·발에 붙는 작은 조각
    "bind": [ascii([".T.....T.", ".T.....T.", "RTRRRRRTR", "r.......r", ".rrrrrrr."],
                   {"T": rgb("927e6a"), "R": rgb("efb775"), "r": rgb("a56243")})],  # 속박: 발밑 밧줄 고리 + 말뚝 둘
    "taunt": [ascii([".DDD.", ".DRD.", ".DRD.", ".DRD.", ".DDD.", ".DRD.", ".DDD."], {"D": rgb("300f0a"), "R": rgb("ef3a0c")})],  # 도발: 빨간 느낌표
    "seal": [ascii(["..SSS..", ".S...S.", ".S...S.", "LLLLLLL", "LLLDLLL", "LLLDLLL", "LLLLLLL"],
                   {"S": rgb("a4aec2"), "L": rgb("efac28"), "D": rgb("2a1d0d")})],  # 봉인: 자물쇠
    "expose": [ascii([".SSSSS.", "SSSRSSS", "SSRSSSS", "SSSRSSS", ".SSRSS.", "..SSS..", "...S..."],
                     {"S": rgb("a4aec2"), "R": rgb("9b1a0a")})],  # 받는 피해 증가: 금 간 방패
    "link": [ascii([".A.", "A.A", ".A."], {"A": rgb("3c9f9c")})],  # 사슬 고리(베스퍼 청록, fx-3)
    "guard": [ascii(["SSSSS", "SWBBS", "SWBBS", "SBBBS", ".SBS.", "..S.."], {"S": rgb("3a4357"), "W": rgb("d0d6e0"), "B": rgb("4f78ad")})],  # 받는 피해 감소: 작은 방패
    # fx-2: 아이아스(보라)·실비아(연두)
    "spark": [ascii(rows, {"W": rgb("efd8a1"), "I": ICE[0]}) for rows in (  # 스킬에 맞은 적의 작은 섬광(방패 강타·관통의 바람살)
        ["...I...", "...W...", "..WWW..", "IWWWWWI", "..WWW..", "...W...", "...I..."],
        [".I...I.", "..I.I..", ".......", "...W...", ".......", "..I.I..", ".I...I."],
        ["I.....I", ".......", ".......", ".......", ".......", ".......", "I.....I"])],
    "aegis": [aegis(f) for f in range(3)],
    "burst": [burst(f) for f in range(5)],
    "ward": [ward(f) for f in range(4)],
    "trap": [ascii(rows, {"I": ICE[1], "i": ICE[3], "S": ICE[0], "L": LIME[1], "G": LIME[0]}) for rows in (  # 폭풍의 덫: 쇠 테 + 안쪽 이빨 + 가운데 바람 문양(1프레임은 반짝)
        ["...IIIIIII...", ".IIiSiSiSiII.", "Ii.........iI", "I....LLL....I", "I...LGGGL...I", "I....LLL....I", "Ii.........iI", ".IIiSiSiSiII.", "...IIIIIII..."],
        ["...IIIIIII...", ".IISiSiSiSII.", "Ii.........iI", "I....GGG....I", "I...GGGGG...I", "I....GGG....I", "Ii.........iI", ".IISiSiSiSII.", "...IIIIIII..."])],
    "gust": [gust(f) for f in range(4)],
    "stuck": [ascii(["L.L", ".L.", ".B.", ".B.", ".B.", ".N."], {"L": LIME[1], "B": rgb("efb775"), "N": rgb("392a1c")})],  # 화살비: 땅에 꽂힌 화살
    # fx-3: 세라피나(크림·금)·베스퍼(청록)
    "mend": [ascii(rows, {"C": HOLY[0], "G": HOLY[1], "T": HOLY[2]}) for rows in (  # 회복 반짝(빛줄기·기적): 십자가 작아지며 식는다
        ["...G...", "...C...", "..GCG..", "GCCCCCG", "..GCG..", "...C...", "...G..."],
        [".......", "...G...", "...C...", ".GCCCG.", "...C...", "...G...", "......."],
        [".......", ".......", "...T...", "..TGT..", "...T...", ".......", "......."])],
    "wing": [wing(f) for f in range(3)],
    "glyph": [glyph(f) for f in range(2)],
    "fog": [fog(f) for f in range(2)],
    "fizz": [ascii(rows, {"T": TEAL[0], "t": TEAL[1], "H": rgb("d0d6e0")}) for rows in (  # 독 거품: 바닥에서 부풀어 올라 터진다
        [".....", ".....", ".....", ".....", ".....", "..t.."],
        [".....", ".....", ".....", "..T..", ".tHt.", "..t.."],
        [".....", ".TTT.", "TH..T", "T...T", ".TTT.", "....."],
        ["t...t", ".....", ".....", ".....", "t...t", "....."])],
    "hex": [ascii(rows, {"T": c}) for c in TEAL for rows in (  # 쇠약의 저주: 머리 위로 가라앉는 아래 겹화살(밝음 → 어두움)
        ["T.....T", ".T...T.", "..T.T..", "T..T..T", ".T...T.", "..T.T..", "...T..."],)],
}
for f in range(3):
    im = canvas(9, 9)
    bubble(im, 4.5, 4.5, 4.2 - f * 0.9, SMOKE, hollow=0.0 if f < 2 else 0.6)
    sprites["puff"].append(im)
for f in range(3):
    im = canvas(5, 5)
    if f < 2:
        bubble(im, 2.5, 3 - f * 0.5, 1.3 + f * 0.7, LAVA[:4])
    else:
        for x, y in ((0, 2), (4, 2), (2, 0), (1, 4), (3, 4)):
            im.putpixel((x, y), LAVA[2])
    sprites["pop"].append(im)

W = max(sum(f.width for f in fr) for fr in sprites.values())
atlas = canvas(W, sum(fr[0].height for fr in sprites.values()))
meta, y = {}, 0
for name, fr in sprites.items():
    x = 0
    for im in fr:
        assert im.size == fr[0].size, name
        atlas.paste(im, (x, y))
        x += im.width
    meta[name] = [0, y, fr[0].width, fr[0].height, len(fr)]
    y += fr[0].height
out = ROOT / "art" / "fx"
out.mkdir(parents=True, exist_ok=True)
atlas.save(out / "fx.png")
(out / "fx.json").write_text(json.dumps(meta, ensure_ascii=False) + "\n", encoding="utf-8")
if "preview" in sys.argv[1:]:
    atlas.resize((atlas.width * 6, atlas.height * 6), Image.NEAREST).save(ROOT / "art" / "trial" / "preview" / "fx_atlas_x6.png")
print("art/fx/fx.png", atlas.size, len(meta), "조각")
