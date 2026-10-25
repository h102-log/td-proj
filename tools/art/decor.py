# 들판 장식(S201, 사용자 2026-10-23 — 농경지·전장 흔적·숲 가장자리 시안 가운데 «전장 흔적»)과 마을 장식(S202 — 돌길·광장·생활·보급 시안 가운데
# «돌길·광장»). 꾸밈만이고 시뮬레이션은 그대로다. 바위·그루터기는 시설(facility.py)과 같은 카메라·외곽선으로, 우물은 같은 카메라에 갈색 외곽선으로 굽고,
# 그을음·구덩이·자갈·풀·풀꽃은 바닥에 찍는 픽셀 그림이다. 마을 돌길은 그림 없이 battle_view.gd(_pave)가 칠한다.
# 배치는 battle_view.gd(bake_ground·ground_props)가 정한다. 0행 16×16: 바위 3·그루터기 2·구덩이 2·자갈 2·풀 2·풀꽃 1·우물 1,
# 1행 48×32: 그을음 3, 2행 48×48: 맵 아래 맵 밖 띠의 마른 나무 4(줄기 밑동이 그림의 (24, 44)),
# 3행 16×16: 마을 시설 마당 소품(S215) 텃밭 2·울타리 2·장작더미·목재 더미·톱밥·판석
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
         "dead": ["1f240a", "2a1d0d", "392a1c", "684c3c", "927e6a"], "water": ["151a26", "151a26", "262d3d", "262d3d", "3a4357"],
         "rim": ["151a26", "3a4357", "3a4357", "56607a", "56607a"]}
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


def flower_patch(rng):
    """마을 풀꽃(S202): 풀 포기 사이에 연한 꽃 몇 점"""
    out = tuft(rng)
    for _ in range(rng.integers(2, 4)):
        x, y = rng.integers(3, 13), rng.integers(4, 13)
        out[y, x] = col(["efd8a1", "a4aec2"][rng.integers(0, 2)])
    return out


# 2026-10-23
# [동작] 마을 우물(S202): 낮고 어두운 돌 고리 안 어두운 물. 바깥 외곽선은 짙은 갈색이고 둘레에 풀 몇 점
# [의도] 우물이 누를 수 있는 물건이나 시설로 읽히지 않고 바닥 장식으로 보이게 한다
# [이유] Gemini가 시설과 같은 짙은 남색 외곽선 때문에 «한 번쯤 눌러보게 생겼다»고 했고, 사용자가 시안 «조합 1a + 2 + 3a»를 골랐다
#        (insights/2026-10-23_village_decor.md). 기둥·가로대는 그 전에 솥 손잡이로 읽혀 뺐다
def well():
    outer, inner = cyl([0.5, CY, 0.04], 0.42, 0.04), cyl([0.5, CY, 0.04], 0.27, 0.3)
    img = cell_sprite([(lambda p: np.maximum(outer(p), -inner(p)), "rim"), (cyl([0.5, CY, 0.03], 0.28, 0.01), "water")]).copy()
    a = img[..., 3] > 0
    pad = np.pad(a, 1)
    img[a & ~(pad[:-2, 1:-1] & pad[2:, 1:-1] & pad[1:-1, :-2] & pad[1:-1, 2:])] = col("392a1c")
    for x, y in ((1, 12), (2, 13), (14, 11), (13, 13), (12, 14)):
        if not a[y, x]:
            img[y, x] = col("39571c")
    return img


# 2026-10-26
# [동작] 마을 시설 마당 소품(S215): 외곽선 없이 땅에 붙은 흙 계열 픽셀 그림. 그림은 칸의 왼쪽 위에 붙인다
# [의도] 건물이 자기 마당을 데리고 와 마을로 읽히게 한다
# [이유] 마을다움 조사의 시각 문법(village_research/03 «외곽선 없음, 땅에 붙음, 흙 계열»)을 따른 시안 B′를 사용자가 골랐다
#        (insights/2026-10-25_village_research_mockup.md). 텃밭 새싹은 바탕 풀(2d472d)과 다른 색이다(B′ 고친 점)
def yard_props(rng):
    def new(w, h):
        return np.zeros((h, w, 4), np.uint8)

    def garden(n):
        """텃밭 이랑 3줄: 위 1px 새싹(띄엄띄엄)과 작물 점, 아래 1px 갈아엎은 흙. 줄 길이가 들쭉날쭉"""
        a = new(14, 9)
        for r in range(3):
            y = 1 + r * 3
            for x in range(int(rng.integers(0, 2)), 14 - int(rng.integers(0, 3))):
                a[y + 1, x] = col("392a1c")
                if (x + r + n) % 2 == 0 and rng.random() < 0.85:
                    a[y, x] = col("39571c" if rng.random() < 0.75 else "efb775")
        return a

    def fence(flip):
        """낮은 울타리 L자: 가로 13px(기둥 3개, 가로대 1줄) + 세로 10px. 키 4px"""
        a = new(14, 12)
        a[1, :13] = col("724113")
        for x in (0, 6, 12):
            a[0, x] = col("927e6a")
            a[1:4, x] = col("392a1c")
        for y in range(1, 11):
            a[y, 0] = col("724113" if y % 4 else "392a1c")
        return a[:, ::-1] if flip else a

    def woodpile():
        """장작더미 7×5: 통나무 마구리 셋 + 위에 둘"""
        a = new(7, 5)
        for cx, cy in ((1, 3), (3, 3), (5, 3), (2, 1), (4, 1)):
            a[cy, cx], a[cy, cx - 1], a[cy + 1, cx] = col("ab5c1c"), col("724113"), col("392a1c")
        return a

    def lumber():
        """목재 더미 11×5: 엇갈려 쌓은 판자 셋"""
        a = new(11, 5)
        for k, (x0, x1) in enumerate(((0, 9), (2, 11), (1, 10))):
            a[3 - k, x0:x1] = col("ab5c1c" if k == 2 else "724113")
            a[3 - k, x0] = col("392a1c")
        a[4, a[4, :, 3] == 0] = col("392a1c")
        return a

    def sawdust():
        """톱밥 얼룩 12×7: 밝은 점을 성기게"""
        a = new(12, 7)
        for _ in range(14):
            x, y = int(rng.integers(0, 12)), int(rng.integers(0, 7))
            if ((x - 6) / 6) ** 2 + ((y - 3) / 3.5) ** 2 < 1:
                a[y, x] = col("efb775" if rng.random() < 0.4 else "927e6a")
        return a

    def flags():
        """판석 넷 14×6: 회갈 돌, 아래 1px 그늘"""
        a = new(14, 6)
        for x0, y0, w in ((0, 0, 4), (5, 1, 4), (10, 0, 4), (3, 3, 4)):
            a[y0:y0 + 2, x0:x0 + w] = col("927e6a")
            a[y0 + 2, x0:x0 + w] = col("392a1c")
            a[y0 + 2, [x0, x0 + w - 1]] = col("684c3c")
        return a

    out = []
    for a in (garden(0), garden(1), fence(False), fence(True), woodpile(), lumber(), sawdust(), flags()):
        cell = np.zeros(SMALL + (4,), np.uint8)
        cell[:a.shape[0], :a.shape[1]] = a
        out.append(cell)
    return out


def sheet():
    rng = np.random.default_rng(23)
    row0 = [rock(1.0, True), rock(0.85, False), rock(1.15, False), stump(1), stump(-1),
            crater(rng, 5), crater(rng, 6), pebbles(rng), pebbles(rng), tuft(rng), tuft(rng),
            flower_patch(np.random.default_rng(24)), well()]  # 마을 그림은 따로 씨앗을 써서 들판 그림이 그대로다
    row1 = [scorch(rng) for _ in range(3)]
    row2 = [dead_tree(rng) for _ in range(4)]
    row3 = yard_props(np.random.default_rng(5))
    out = np.zeros((SMALL[1] * 2 + SCORCH[1] + TREE[1], max(SMALL[0] * len(row0), TREE[0] * len(row2)), 4), np.uint8)
    for y, (w, _), row in ((0, SMALL, row0), (SMALL[1], SCORCH, row1), (SMALL[1] + SCORCH[1], TREE, row2),
                           (SMALL[1] + SCORCH[1] + TREE[1], SMALL, row3)):
        for i, im in enumerate(row):
            out[y:y + im.shape[0], i * w:i * w + im.shape[1]] = im
    return Image.fromarray(out, "RGBA")


if __name__ == "__main__":
    s = sheet()
    s.save(GAME)
    print(s.size)
