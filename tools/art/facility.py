# 시설 9종과 접힌 대포(4.1e, 사용자 2026-10-20 — 칸 폭에 위로 솟게). 망루(keep.py)와 같은 카메라·재질로 그린다.
# 종류는 실루엣으로 가른다: 집 박공지붕·굴뚝, 교회 첨탑·십자가, 병영 천막·깃발, 작업장 톱니바퀴·굴뚝, 궁수 훈련소 과녁,
# 방벽 뾰족 말뚝, 타워 다리 달린 망대, 마법 타워 둥근 탑·떠 있는 수정, 대포 바퀴·포신
# 원점 = 시설 칸(차지 칸의 앞 왼쪽 칸, S216) 앞쪽 아래 왼쪽 모서리 = 캔버스 픽셀 ANCHOR. 칸 하나 시설의 폭은 칸(16px) 안이다
# 사용: python tools/art/facility.py → art/trial/facility/<종류>.png, art/trial/preview/facility_options.png
import numpy as np
from PIL import Image

import preview as V
import render as R
import tiles as TL
from hero import OUT as HERO

N, ANCHOR = 96, (16, 92)  # 차지 칸이 큰 시설(S216)도 들어가게 모든 시설을 같은 캔버스에 그린다
D = 1 / np.sin(np.radians(45))  # 칸 바닥 깊이(모델 단위). 화면에서 16px
COLORS = {"stone": "7c8494", "wood": "8a5530", "iron": "4a5060", "gold": "d0a040", "team": "3c9f9c",
          "roof": "8a2018", "plaster": "e0d4b0", "canvas": "d8c8a0", "blue": "70a0e0", "red": "c03020"}
MAT = list(COLORS)
EDGE = 0.35  # 안쪽 외곽선을 긋는 깊이 차. 망루의 0.19는 천막·첨탑처럼 가파른 면 전체를 외곽선으로 칠했다
PAL = R.PALETTES["f24p"]
RAMPS = np.array([R.ramp([int(c[i:i + 2], 16) for i in (0, 2, 4)], PAL) for c in COLORS.values()])
DARK = R.darkest(PAL)
KINDS = ["house", "church", "barracks", "workshop", "archery", "wall", "tower", "magic", "cannon", "cannon_folded"]
VILLAGE = {"house", "church", "barracks", "workshop", "archery"}  # 마을(흙) 안에만 짓는다(S43)
# 2026-10-26
# [동작] 칸을 여럿 차지하는 시설(S216)은 모델을 (가로, 깊이, 높이) 배율로 키워 같은 화소 밀도로 그린다
# [이유] 사용자가 «차지하는 칸도 키우기»와 이 방식으로 그린 시안 A를 골랐다(next/2026-10-26/r1.md §1).
#        사격장은 과녁 둘이 3칸 폭을 채우게 고르게 2배다. 배율의 가로·깊이는 data/structures/*.tres의 size와 맞춘다
SCALE = {"house": (2, 2, 2), "church": (2, 3, 2.5), "barracks": (3, 2, 2), "workshop": (3, 2, 2), "archery": (2, 2, 2)}
FACE = np.array([0, -np.cos(np.radians(45)), np.sin(np.radians(45))])  # 카메라를 보는 면의 법선(과녁·톱니바퀴)
GEAR = np.array([0.6, 0.3, 0.64])


def m(name):
    return MAT.index(name)


def gable(x0, x1, y0, y1, z0, h, ridge="x"):
    """박공지붕: 용마루가 ridge 축을 따라 가는 삼각 기둥. 높이 z0~z0+h"""
    box = R.box([(x0 + x1) / 2, (y0 + y1) / 2, z0 + h / 2], [(x1 - x0) / 2, (y1 - y0) / 2, h / 2])
    a, c, w = (1, (y0 + y1) / 2, (y1 - y0) / 2) if ridge == "x" else (0, (x0 + x1) / 2, (x1 - x0) / 2)

    def f(p):
        slope = (np.abs(p[:, a] - c) / w + (p[:, 2] - z0) / h - 1) / np.sqrt(1 / w ** 2 + 1 / h ** 2)
        return np.maximum(box(p), slope)
    return f


def pyramid(cx, cy, w, d, z0, h):
    """밑변 반폭 w·반깊이 d, 높이 h인 사각뿔"""
    def f(p):
        sx = (np.abs(p[:, 0] - cx) / w + (p[:, 2] - z0) / h - 1) / np.sqrt(1 / w ** 2 + 1 / h ** 2)
        sy = (np.abs(p[:, 1] - cy) / d + (p[:, 2] - z0) / h - 1) / np.sqrt(1 / d ** 2 + 1 / h ** 2)
        return np.maximum(np.maximum(sx, sy), z0 - p[:, 2])
    return f


def cyl(c, axis, r, half):
    """가운데 c, 축 axis(단위 벡터), 반지름 r, 반길이 half인 원기둥"""
    c, n = np.asarray(c, float), np.asarray(axis, float) / np.linalg.norm(axis)

    def f(p):
        q = p - c
        a = q @ n
        return np.maximum(np.linalg.norm(q - a[:, None] * n, axis=1) - r, np.abs(a) - half)
    return f


def octa(c, a, b):
    """가로 반지름 a, 세로 반지름 b인 팔면체(수정)"""
    c = np.asarray(c, float)

    def f(p):
        q = np.abs(p - c)
        return (q[:, 0] / a + q[:, 1] / a + q[:, 2] / b - 1) / np.sqrt(2 / a ** 2 + 1 / b ** 2)
    return f


def swap(idx, mask, src, dst):
    """mask 안에서 src 재질 램프 색을 같은 단계의 dst 재질 색으로 바꾼다"""
    for k in range(5):
        idx = np.where(mask & (idx == RAMPS[m(src)][k]), RAMPS[m(dst)][k], idx)
    return idx


WHEEL = (0.42, 0.3, 0.27)  # 앞 바퀴 가운데 x·y와 반지름. 뒤 바퀴는 y 1.02


def wheels():
    x, y, r = WHEEL
    return [(cyl([x, yy, r], [0, 1, 0], r, 0.045), "wood") for yy in (y, 1.02)]


def spokes(idx, mat, x, y, z):
    """앞 바퀴의 바퀴살 8개와 굴대. 살 사이는 최암색"""
    cx, cy, r = WHEEL
    q = np.hypot(x - cx, z - r)
    on = (mat == m("wood")) & (np.abs(y - cy) < 0.06) & (q < r - 0.06)
    gap = on & (np.abs(np.sin(4 * np.arctan2(z - r, x - cx))) > 0.45) & (q > 0.07)
    return np.where(gap, DARK, np.where(on & (q < 0.07), RAMPS[m("iron")][3], idx))


def house():
    """박공 끝이 카메라를 본다(집 모양 오각형). 지붕은 위만 남긴 껍데기라 앞 박공의 회벽이 보인다"""
    roof = gable(0.04, 0.96, 0.22, 1.2, 0.5, 0.58, ridge="y")
    P = [(R.box([0.5, 0.72, 0.28], [0.36, 0.42, 0.28]), "plaster"),
         (gable(0.14, 0.86, 0.3, 1.14, 0.54, 0.44, ridge="y"), "plaster"),
         (lambda p: np.maximum(roof(p), -roof(p + [0, 0, 0.14])), "roof"),
         (R.box([0.74, 0.9, 0.95], [0.07, 0.07, 0.3]), "stone"),
         (R.box([0.5, 0.29, 0.2], [0.1, 0.02, 0.2]), "wood")]

    def paint(idx, mat, x, y, z):
        front = (mat == m("plaster")) & (y < 0.32)
        win = front & (z > 0.64) & (z < 0.8) & (np.abs(x - 0.5) < 0.07)
        win |= front & (z > 0.18) & (z < 0.32) & (np.abs(np.abs(x - 0.5) - 0.25) < 0.06)  # 문 양옆 창(2×2로 키우며 빈 면, S173)
        return np.where(win, RAMPS[m("iron")][1], idx)
    return P, paint


def church():
    P = [(R.box([0.5, 0.97, 0.36], [0.3, 0.35, 0.36]), "plaster"),
         (gable(0.14, 0.86, 0.6, 1.36, 0.68, 0.42, ridge="y"), "roof"),
         (R.box([0.5, 0.42, 0.62], [0.18, 0.17, 0.62]), "plaster"),
         (pyramid(0.5, 0.42, 0.22, 0.21, 1.22, 0.8), "iron"),
         (R.box([0.5, 0.42, 2.18], [0.035, 0.035, 0.17]), "gold"),
         (R.box([0.5, 0.42, 2.22], [0.11, 0.035, 0.035]), "gold"),
         (R.box([0.5, 0.25, 0.2], [0.08, 0.02, 0.2]), "wood")]

    def paint(idx, mat, x, y, z):
        bell = (mat == m("plaster")) & (y < 0.27) & (z > 0.82) & (z < 1.08) & (np.abs(x - 0.5) < 0.07)
        return np.where(bell, RAMPS[m("iron")][0], idx)
    return P, paint


def barracks():
    P = [(gable(0.06, 0.94, 0.2, 1.25, 0.0, 0.95, ridge="y"), "canvas"),
         (R.capsule([0.5, 0.72, 0.85], [0.5, 0.72, 1.7], 0.04), "wood"),
         (R.box([0.64, 0.72, 1.56], [0.14, 0.025, 0.1]), "team")]

    def paint(idx, mat, x, y, z):
        cv = mat == m("canvas")
        idx = swap(idx, cv & (np.mod(x + 0.06, 0.22) < 0.11), "canvas", "team")  # 팀 색 줄무늬
        door = cv & (y < 0.22) & (np.abs(x - 0.5) < 0.2 * (1 - z / 0.62))  # 앞 입구
        return np.where(door, RAMPS[m("iron")][0], idx)
    return P, paint


def workshop():
    P = [(R.box([0.5, 0.78, 0.28], [0.4, 0.43, 0.28]), "wood"),
         (gable(0.06, 0.94, 0.28, 1.28, 0.52, 0.32), "iron"),
         (R.box([0.24, 1.0, 0.8], [0.09, 0.09, 0.42]), "stone"),
         (cyl(GEAR, FACE, 0.27, 0.05), "gold")]
    u, v = np.array([1.0, 0, 0]), np.cross(FACE, [1.0, 0, 0])  # 톱니바퀴 면의 두 축
    for k in range(8):  # 톱니
        a = k * np.pi / 4
        r = np.cos(a) * u + np.sin(a) * v
        P.append((R.box(GEAR + 0.31 * r, [0.07, 0.07, 0.05], [r, np.cross(FACE, r), FACE]), "gold"))

    def paint(idx, mat, x, y, z):
        hub = np.linalg.norm(np.stack([x, y, z], -1) - GEAR, axis=-1) < 0.1
        idx = np.where((mat == m("gold")) & hub, RAMPS[m("iron")][1], idx)
        door = (mat == m("wood")) & (y < 0.36) & (z < 0.36) & (np.abs(x - 0.36) < 0.12)
        return np.where(door, RAMPS[m("wood")][1], idx)
    return P, paint


def archery():
    """과녁 둘. SCALE 2배로 3칸 폭(S216)을 채운다. 과녁마다 앞다리 둘과 뒷다리 하나"""
    n, cs = FACE, [np.array([x, 0.7, 0.6]) for x in (0.38, 1.12)]
    P = []
    for c in cs:
        P += [(cyl(c, n, 0.32, 0.05), "plaster"),
              (R.capsule([c[0] - 0.2, 1.05, 0.0], [c[0] - 0.13, 0.8, 0.45], 0.05), "wood"),
              (R.capsule([c[0] + 0.2, 1.05, 0.0], [c[0] + 0.13, 0.8, 0.45], 0.05), "wood"),
              (R.capsule([c[0], 0.4, 0.0], [c[0], 0.62, 0.26], 0.05), "wood")]

    def paint(idx, mat, x, y, z):
        q = np.stack([x, y, z], -1) - np.where((x < 0.75)[..., None], cs[0], cs[1])
        r = np.linalg.norm(q - (q @ n)[..., None] * n, axis=-1)
        face = mat == m("plaster")
        idx = swap(idx, face & ((r < 0.26) & (r > 0.18) | (r < 0.09)), "plaster", "red")  # 과녁 고리
        return swap(idx, face & (r < 0.04), "red", "gold")
    return P, paint


def wall():
    P = []
    for k in range(4):
        cx = 0.14 + 0.24 * k
        h = 0.62 + 0.12 * (k % 2)
        P.append((R.box([cx, 0.62, h / 2], [0.09, 0.09, h / 2]), "wood"))
        P.append((pyramid(cx, 0.62, 0.09, 0.09, h, 0.34), "wood"))
    P.append((R.box([0.5, 0.52, 0.42], [0.48, 0.03, 0.05]), "iron"))  # 묶은 띠
    return P, None


def tower():
    P = []
    for sx in (-1, 1):
        for sy in (-1, 1):
            P.append((R.capsule([0.5 + sx * 0.36, 0.72 + sy * 0.4, 0.0], [0.5 + sx * 0.28, 0.72 + sy * 0.32, 1.3], 0.05), "wood"))
            P.append((R.capsule([0.5 + sx * 0.33, 0.72 + sy * 0.36, 1.6], [0.5 + sx * 0.33, 0.72 + sy * 0.36, 1.9], 0.03), "wood"))
    P.append((R.capsule([0.16, 0.34, 0.2], [0.8, 0.38, 1.05], 0.03), "wood"))  # 앞 X 버팀대
    P.append((R.capsule([0.84, 0.34, 0.2], [0.2, 0.38, 1.05], 0.03), "wood"))
    P.append((R.box([0.5, 0.72, 1.46], [0.42, 0.44, 0.16]), "wood"))  # 망대 난간
    P.append((pyramid(0.5, 0.72, 0.47, 0.5, 1.88, 0.55), "roof"))

    def paint(idx, mat, x, y, z):
        plank = (mat == m("wood")) & (z > 1.3) & (z < 1.62) & (np.mod(z - 1.3, 0.1) < 0.03)
        return np.where(plank, RAMPS[m("wood")][1], idx)
    return P, paint


def magic():
    P = [(cyl([0.5, 0.72, 0.68], [0, 0, 1], 0.3, 0.68), "stone"),
         (cyl([0.5, 0.72, 1.42], [0, 0, 1], 0.37, 0.08), "stone"),
         (octa([0.5, 0.72, 2.0], 0.24, 0.4), "blue")]

    def paint(idx, mat, x, y, z):
        slit = (mat == m("stone")) & (y < 0.5) & (np.abs(x - 0.5) < 0.04) & (z > 0.55) & (z < 0.95)
        idx = np.where(slit, RAMPS[m("blue")][3], idx)  # 빛나는 창
        return np.where((mat == m("blue")) & (z > 2.05) & (x < 0.5), RAMPS[m("blue")][4], idx)
    return P, paint


def cannon():
    P = wheels() + [(R.box([0.42, 0.66, 0.32], [0.3, 0.3, 0.07]), "wood"),
                    (R.capsule([0.1, 0.66, 0.45], [0.94, 0.66, 0.68], 0.15, 0.11), "iron"),
                    (cyl([0.92, 0.66, 0.67], [0.84, 0, 0.23], 0.13, 0.04), "iron")]
    return P, spokes


def cannon_folded():
    """옮기려고 접은 대포(I74): 포신을 수레 위에 뒤쪽(왼쪽)으로 눕혀 끈 두 줄로 묶었다.
    천을 덮은 첫 그림은 Gemini가 부서진 잔해 더미로 읽었다(2026-10-20, 사용자가 포신이 보이게 고르기로 함)"""
    P = wheels() + [(R.box([0.45, 0.66, 0.32], [0.33, 0.3, 0.07]), "wood"),
                    (R.capsule([0.92, 0.66, 0.5], [0.04, 0.66, 0.5], 0.15, 0.11), "iron"),
                    (cyl([0.06, 0.66, 0.5], [1, 0, 0], 0.13, 0.04), "iron")]
    for bx in (0.3, 0.66):  # 묶은 끈
        P.append((cyl([bx, 0.66, 0.5], [1, 0, 0], 0.165, 0.035), "canvas"))
    return P, spokes


def draw(kind):
    P, paint = globals()[kind]()
    S = np.array(SCALE.get(kind, (1, 1, 1)), float)
    k = S.min()  # 고르지 않은 배율은 거리를 작은 쪽 배율로 줄여 광선이 면을 넘지 않게 한다
    prims = [((lambda f: lambda p: k * f(p / S))(f), m(name), "") for f, name in P]
    pid, lam, depth, pos = R.trace(prims, R.Cam(45), (0, 1), N, 16, ANCHOR, with_pos=True)
    mat = np.where(pid >= 0, np.array([m(name) for _, name in P])[np.maximum(pid, 0)], -1)
    idx = R.shade(mat, lam, depth, RAMPS, "D", DARK, edge=EDGE * k)
    if paint:
        idx = paint(idx, mat, pos[..., 0] / S[0], pos[..., 1] / S[1], pos[..., 2] / S[2])
    return R.rgba(idx, PAL)


BLUEPRINT = (0.55, 0.78, 1.0, 0.6)  # 청사진 색(사용자 2026-10-20, 림월드 설계도). battle_view.gd BLUEPRINT와 같다


def gray(img):
    """청사진 바탕: 밝기만 남겨 0.4~1로 올린 회색. 게임은 이 그림에 BLUEPRINT를 곱해 그린다(atlas.py facility)"""
    a = np.asarray(img, float) / 255
    g = 0.4 + 0.6 * (a[..., :3] @ [0.3, 0.59, 0.11])
    return Image.fromarray(np.round(np.dstack([g, g, g, a[..., 3]]) * 255).astype(np.uint8), "RGBA")


def blueprint(img):
    a = np.asarray(gray(img), float) * BLUEPRINT
    return Image.fromarray(np.round(a).astype(np.uint8), "RGBA")


def built(img, t):
    """진행률 t: 청사진 위에 아래부터 t만큼 실제 그림"""
    a = np.asarray(img)[..., 3]
    rows = np.nonzero(a.any(1))[0]
    cut = int(round(rows.max() + 1 - t * (rows.max() + 1 - rows.min())))
    out = blueprint(img)
    out.alpha_composite(img.crop((0, cut, N, N)), (0, cut))
    return out


def ground(kind, at):
    """시설 하나를 놓을 캔버스 크기 바닥(흙: 마을, 풀: 들판). 그림을 (0, 0)에 겹치면 시설 칸이 (1, 5)다"""
    T = TL.T
    tile = at[:T, 15 * T:] if kind in VILLAGE else at[:T, :T]
    return R.rgba(np.tile(tile, (N // T + 1, N // T))[:N + 8], PAL)


if __name__ == "__main__":
    out = HERO.parent / "facility"
    out.mkdir(exist_ok=True)
    at = TL.atlas("f24p")
    imgs = {k: draw(k) for k in KINDS}
    for k, im in imgs.items():
        im.save(out / f"{k}.png")
    cells = []
    for k in KINDS:
        g = ground(k, at)
        g.alpha_composite(imgs[k], (0, 0))
        cells.append(g)
    row = R.sheet(cells, len(cells), 2, (30, 30, 30, 255))
    sil = R.sheet([V.silhouette(imgs[k]) for k in KINDS], len(KINDS), 2, (30, 30, 30, 255))
    states = []
    for k in ("house", "tower", "cannon"):
        for t in (0.0, 0.35, 0.7):
            g = ground(k, at)
            g.alpha_composite(built(imgs[k], t), (0, 0))
            states.append(g)
    st = R.sheet(states, len(states), 2, (30, 30, 30, 255))
    sheet = V.stack([V.up(row, 3), V.up(sil, 3), V.up(st, 3)], 8)
    sheet.save(HERO.parent / "preview" / "facility_options.png")
    print(sheet.size)
