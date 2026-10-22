# 들판 장식(S197, 사용자 2026-10-23 — 농경지·전장 흔적·숲 가장자리 시안 가운데 «전장 흔적»). 꾸밈만이고 시뮬레이션은 그대로다.
# 바위·그루터기는 시설(facility.py)과 같은 카메라·외곽선으로 굽고, 그을음·구덩이·자갈·풀은 바닥에 찍는 픽셀 그림이다.
# 배치는 battle_view.gd(bake_ground·field_props)가 정한다. 0행 16×16: 바위 3·그루터기 2·구덩이 2·자갈 2·풀 2,
# 1행 48×32: 그을음 3, 2행 48×48: 맵 아래 맵 밖 띠의 마른 나무 4(줄기 밑동이 그림의 (24, 44))
# 사용: python tools/art/decor.py → art/tiles/decor.png
from pathlib import Path

import numpy as np
from PIL import Image

import render as R

GAME = Path(__file__).resolve().parents[2] / "art" / "tiles" / "decor.png"
PAL = R.PALETTES["f24p"]
HEX = ["%02x%02x%02x" % tuple(c) for c in PAL]
T = 16
D = 1 / np.sin(np.radians(45))  # 칸 바닥 깊이(모델 단위). 화면에서 16px
CY = D / 2
# 2026-10-23
# [동작] 재질 램프 [외곽선, 음영 0..3]을 팔레트 색으로 직접 정한다
# [이유] 자동 램프(render.ramp)가 나무를 주황으로, 바위를 밝은 청회색으로 골라 시안에서 아이템처럼 튀었다(사용자가 본 1차 시안)
RAMPS = {"stone": ["1f240a", "262d3d", "3a4357", "56607a", "56607a"], "wood": ["1f240a", "2a1d0d", "392a1c", "684c3c", "684c3c"],
         "dead": ["1f240a", "2a1d0d", "392a1c", "684c3c", "927e6a"]}
MAT = list(RAMPS)
RAMP_IDX = np.array([[HEX.index(h) for h in v] for v in RAMPS.values()])
SMALL, SCORCH, TREE = (16, 16), (48, 32), (48, 48)  # 행마다 한 칸 크기


def col(h):
    return np.array(list(PAL[HEX.index(h)]) + [255], np.uint8)


def render(parts, n, anchor):
    pid, lam, depth = R.trace([(f, MAT.index(m), "") for f, m in parts], R.Cam(45), (0, 1), n, 16, anchor)
    mat = np.where(pid >= 0, np.array([MAT.index(m) for _, m in parts])[np.maximum(pid, 0)], -1)
    return np.asarray(R.rgba(R.shade(mat, lam, depth, RAMP_IDX, "D", R.darkest(PAL), edge=0.35), PAL))


def cyl(c, r, half):
    """세로 원기둥"""
    c = np.asarray(c, float)
    return lambda p: np.maximum(np.hypot(p[:, 0] - c[0], p[:, 1] - c[1]) - r, np.abs(p[:, 2] - c[2]) - half)


def cell_sprite(parts):
    """칸 하나(16×16)에 들어가는 소품. 32px 캔버스에서 칸 앞쪽 아래 왼쪽 모서리를 (8, 28)에 두고 칸 자리만 자른다"""
    img = render(parts, 32, (8, 28))
    assert not img[..., 3][:, :8].any() and not img[..., 3][:, 24:].any() and not img[..., 3][:12].any() and not img[..., 3][28:].any()
    return img[12:28, 8:24]


def rock(s, extra):
    P = [(R.cut_above(R.ellipsoid([0.48, CY, 0.0], [0.3 * s, 0.24 * s, 0.3 * s]), 0), "stone")]
    if extra:
        P.append((R.cut_above(R.ellipsoid([0.78, CY - 0.25, 0.0], [0.13, 0.11, 0.14]), 0), "stone"))
    return cell_sprite(P)


def stump(lean):
    return cell_sprite([(cyl([0.5, CY, 0.11], 0.2, 0.11), "wood"),
                        (R.capsule([0.5, CY, 0.04], [0.5 + 0.32 * lean, CY - 0.1, 0.0], 0.06), "wood")])


def dead_tree(rng):
    a, b = rng.uniform(0.95, 1.15), rng.uniform(1.15, 1.45)
    P = [(R.capsule([0.5, CY, 0], [0.5, CY, rng.uniform(1.1, 1.4)], 0.12, 0.05), "dead"),
         (R.capsule([0.5, CY, 0.7], [0.15, CY, a], 0.05, 0.02), "dead"),
         (R.capsule([0.5, CY, 0.9], [0.85, CY, b], 0.05, 0.02), "dead")]
    return render(P, 48, (16, 44))


def blob(rng, r, sy=1.4, k=1.0):
    yy, xx = np.mgrid[-r:r + 1, -r:r + 1]
    ang = np.arctan2(yy, xx)
    wob = 1 + k * (0.25 * np.sin(3 * ang + rng.uniform(0, 6)) + 0.15 * np.sin(5 * ang + rng.uniform(0, 6)))
    return np.hypot(xx, yy * sy) / (r * wob)


def scorch(rng):
    """그을린 풀: 가운데는 1f240a, 가장자리 0.3은 바깥으로 갈수록 성기게, 재 점 조금"""
    out = np.zeros(SCORCH[::-1] + (4,), np.uint8)
    d = blob(rng, 15)
    noise = rng.uniform(0, 1, d.shape)
    on = (d < 0.7) | ((d < 1.0) & (noise < (1.0 - d) / 0.3))
    sub = np.where(on[..., None], col("1f240a"), 0)
    sub = np.where(((d < 0.4) & (noise < 0.08))[..., None], col("392a1c"), sub)
    ys, xs = slice(16 - 15, 16 + 16), slice(24 - 15, 24 + 16)
    out[ys, xs] = sub
    return out


def crater(rng, r):
    out = np.zeros(SMALL + (4,), np.uint8)
    d = blob(rng, r, k=0.4)
    c = np.zeros(d.shape + (4,), np.uint8)
    j = np.arange(d.shape[0])[:, None]
    c[d < 1.0] = np.where(((j < r) & (d >= 0.8))[d < 1.0][:, None], col("684c3c"), col("392a1c"))  # 위쪽 테두리는 빛 받는 흙더미
    c[d < 0.55] = col("2a1d0d")
    out[8 - r:8 + r + 1, 8 - r:8 + r + 1] = c
    return out


def pebbles(rng):
    out = np.zeros(SMALL + (4,), np.uint8)
    for _ in range(rng.integers(2, 4)):
        x, y = rng.integers(3, 12, 2)
        out[y, x:x + 2] = col("927e6a")
        out[y + 1, x:x + 2] = col("2a1d0d")
    return out


def tuft(rng):
    """풀 포기. 줄기는 바닥 풀 점과 같은 밝은 풀색이라 바탕(2d472d) 위에서 보인다"""
    out = np.zeros(SMALL + (4,), np.uint8)
    for _ in range(rng.integers(1, 3)):
        x, y = rng.integers(4, 12), rng.integers(5, 13)
        for dx, h in ((-2, 2), (0, 3), (2, 2)):
            for k in range(h):
                out[y - k, x + dx + (np.sign(dx) if k == h - 1 else 0)] = col("39571c")
        out[y + 1, x - 2:x + 3] = col("183f39")
    return out


def sheet():
    rng = np.random.default_rng(23)
    row0 = [rock(1.0, True), rock(0.85, False), rock(1.15, False), stump(1), stump(-1),
            crater(rng, 5), crater(rng, 6), pebbles(rng), pebbles(rng), tuft(rng), tuft(rng)]
    row1 = [scorch(rng) for _ in range(3)]
    row2 = [dead_tree(rng) for _ in range(4)]
    out = np.zeros((SMALL[1] + SCORCH[1] + TREE[1], TREE[0] * len(row2), 4), np.uint8)
    for y, (w, _), row in ((0, SMALL, row0), (SMALL[1], SCORCH, row1), (SMALL[1] + SCORCH[1], TREE, row2)):
        for i, im in enumerate(row):
            out[y:y + im.shape[0], i * w:i * w + im.shape[1]] = im
    return Image.fromarray(out, "RGBA")


if __name__ == "__main__":
    s = sheet()
    s.save(GAME)
    print(s.size)
