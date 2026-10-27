# 이펙트 도트 조각 아틀라스(4.1s fx-1): 조각마다 한 줄에 프레임을 가로로 잇고, 이름 → [x, y, 폭, 높이, 프레임 수]를 json으로 쓴다.
# 색은 F24+(palettes.json f24p)와 이펙트 확장 램프(fx, 보라 5색)만 쓴다. 출발점은 시안 C(insights/2026-10-27_hero_fx_mockup.md)이고,
# Gemini 고칠 점대로 폭발은 밝은 섬광부터 시작하며 연기는 따로 떼어(puff) 유닛 아래 층에 그린다
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
VIO = [rgb(c) for c in PAL["fx"]]
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
    "link": [ascii([".A.", "A.A", ".A."], {"A": rgb("a4aec2")})],  # 사슬 고리
    "guard": [ascii(["SSSSS", "SWBBS", "SWBBS", "SBBBS", ".SBS.", "..S.."], {"S": rgb("3a4357"), "W": rgb("d0d6e0"), "B": rgb("4f78ad")})],  # 받는 피해 감소: 작은 방패
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
