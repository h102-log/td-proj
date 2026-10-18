# 성벽 높이 비교(WBS 4.0, art_direction_research README 결론 2): 정문이 있는 성벽 한 줄을 앞면 높이 16·24·32px(1·1.5·2칸)로 렌더하고
# 성벽 뒤(마을 첫 줄)·성벽 위·성문 앞에 기사를 세워 가림을 본다
# 사용: python tools/art/wall.py → art/trial/preview/s4_wall.png
import numpy as np
from PIL import Image

import preview as V
import render as R
import tiles as TL
from hero import OUT as HERO

W = 6  # 성벽 칸 수
GATES = {"open": 1.5, "closed": 4.5}  # 문 가운데 x(칸). 열림·닫힘을 한 장면에서 함께 본다(사용자 2026-10-18 ②)
BASE = {"stone": "7c8494", "wood": "8a5530", "iron": "4a5060"}
STONE, WOOD, IRON = 0, 1, 2


def arch(gx, gw, gh):
    """xz 평면의 아치(아래 사각 + 위 반원) 2D SDF. 폭 2gw, 꼭대기 높이 gh"""
    zc = gh - gw

    def f(p):
        x, z = p[:, 0] - gx, p[:, 2]
        qx, qz = np.abs(x) - gw, np.abs(z - zc / 2) - zc / 2
        rect = np.hypot(np.maximum(qx, 0), np.maximum(qz, 0)) + np.minimum(np.maximum(qx, qz), 0)
        return np.minimum(rect, np.hypot(x, z - zc) - gw)
    return f


def slab(f2, y0, y1):
    """2D 모양을 y0~y1 두께로 민다"""
    yc, yh = (y0 + y1) / 2, (y1 - y0) / 2
    return lambda p: np.maximum(f2(p), np.abs(p[:, 1] - yc) - yh)


def wall(elev, H, pal):
    """앞면 높이 H px. 원점 = 성벽 앞쪽 아래 왼쪽 모서리. → (팔레트 번호 이미지, 원점 픽셀, 흉벽·앞면 마스크)"""
    cam = R.Cam(elev)
    D, h = 1 / cam.sin, H / (16 * cam.cos)  # 바닥 깊이 1칸이 화면 16px이 되게(02 §2)
    gw, gh, rd = 0.36, min(h * 0.75, 1.15), 0.3 * D  # 문 반폭·높이, 닫힌 문이 앞면에서 들어간 깊이. 0.15D는 벽 안으로 든 깊이가 안 보였다(Gemini 2026-10-18)
    # 흉벽: 앞면과 같은 면에서 올라가는 두께 pd·높이 ph의 난간, 위를 cd만큼 판 총안. 윗면 한가운데 무늬처럼 보였다(사용자 2026-10-18 ③)
    pd, ph, cd = 0.12 * D, 0.32, 0.16
    body = R.box([W / 2, D / 2, h / 2], [W / 2, D / 2, h / 2])
    parapet = R.box([W / 2, pd / 2, h + ph / 2], [W / 2, pd / 2, ph / 2])
    crenels = [R.box([0.39 + k * 0.5, pd / 2, h + ph - cd / 2 + 0.01], [0.11, pd, cd / 2 + 0.01]) for k in range(W * 2 - 1)]
    # 열린 문 구멍은 땅 밑 0.1까지 판다. 구멍 밑면이 벽 밑면(z=0)과 겹치면 SDF가 0으로 수렴해 광선이 거기 맞고 돌 바닥이 생겼다
    go, gc = arch(GATES["open"], gw, gh + 0.1), arch(GATES["closed"], gw, gh)
    holes = [slab(lambda p: go(p + [0, 0, 0.1]), -0.1, D + 0.1), slab(gc, -0.1, rd)]

    def stone(p):
        top = np.maximum(parapet(p), -np.min([c(p) for c in crenels], axis=0))
        return np.maximum(np.minimum(body(p), top), -np.min([g(p) for g in holes], axis=0))

    # 닫힌 문. 열린 문 통로에는 바닥을 두지 않아 그 자리의 땅 타일이 비친다. 돌 바닥은 회색 홈처럼 보였다(Gemini 2026-10-18)
    P = [(stone, STONE), (slab(gc, rd - 0.05, rd), WOOD)]
    for zb in (0.22 * gh, 0.55 * gh):  # 닫힌 문의 철 빗장 2줄
        band = R.box([GATES["closed"], rd - 0.06, zb], [gw, 0.012, 0.035])
        P.append((lambda p, band=band: np.maximum(band(p), gc(p)), IRON))
    for sx in (-1, 1):  # 열린 문짝: 통로 양옆으로 젖혀 있다
        P.append((R.box([GATES["open"] + sx * (gw - 0.03), rd + gw / 2, (gh - gw) / 2], [0.02, gw / 2, (gh - gw) / 2]), WOOD))
    n = 104
    anchor = (4, n - 4)
    pid, lam, depth, pos = R.trace([(f, m, "") for f, m in P], cam, (0, 1), n, 16, anchor, with_pos=True)
    ramps = [R.ramp([int(BASE[k][i:i + 2], 16) for i in (0, 2, 4)], pal) for k in BASE]
    mat = np.where(pid >= 0, np.array([m for _, m in P])[np.maximum(pid, 0)], -1)
    # 윗면과 앞면이 같은 단계라 앞면을 한 단계 내려 가른다(Gemini 2026-10-18). 윗면을 올리면 흉벽 하이라이트와 같은 색이 됐다
    idx = R.shade(mat, lam, depth, ramps, "D", R.darkest(pal), edge=0.19)
    x, y, z = pos[..., 0], pos[..., 1], pos[..., 2]
    st, rp = mat == STONE, [np.array(r) for r in ramps]
    row = np.floor(z / 0.25).astype(int)
    mortar = (np.mod(z, 0.25) < 0.06) | (np.mod(x + 0.25 * (row % 2), 0.5) < 0.07)  # 앞면 벽돌 줄눈
    front = st & (y < 0.01)
    idx = np.where(front & mortar, rp[STONE][1], idx)
    idx = np.where(front & (idx == rp[STONE][3]), rp[STONE][2], idx)
    idx = np.where(st & (z > h + ph - 0.02), rp[STONE][4], idx)  # 흉벽 윗면 하이라이트
    inside = st & (y > 0.01) & (z < gh + 0.01) & (((np.abs(x - GATES["open"]) < gw + 0.01)) | ((np.abs(x - GATES["closed"]) < gw + 0.01) & (y < rd + 0.01)))
    idx = np.where(inside, rp[STONE][1], idx)  # 문 안쪽 통로·홈은 그늘
    plank = (mat == WOOD) & (np.abs(x - GATES["closed"]) < gw - 0.05) & (np.mod(x - (GATES["closed"] - gw), 2 * gw / 3) < 0.05)
    idx = np.where(plank, rp[WOOD][1], idx)  # 판자 줄 2개
    gate = inside | (mat == WOOD) | (mat == IRON)
    pf = np.pad(front, 1)
    near_front = pf[:-2, 1:-1] | pf[2:, 1:-1] | pf[1:-1, :-2] | pf[1:-1, 2:]
    idx = np.where(gate & near_front, R.darkest(pal), idx)  # 아치 테두리는 최암색
    return idx, anchor, st & (y < pd + 0.01)  # 흉벽·앞면: 성벽 위 유닛보다 나중에 그려 발을 가린다


def scene(elev, H, pname):
    pal = R.PALETTES[pname]
    T = 16
    at = TL.atlas(pname)
    rng = np.random.default_rng(2)
    grass = [at[:T, :T]] + [at[T:, k * T:(k + 1) * T] for k in range(3)]
    dirt = [at[:T, 15 * T:]] + [at[T:, k * T:(k + 1) * T] for k in range(3, 6)]
    rows = [[(dirt if y < 2 else grass)[rng.integers(4)] for _ in range(8)] for y in range(6)]  # 0~1행 마을(흙), 2행 성벽, 3~5행 들판
    img = R.rgba(np.block(rows), pal)
    knights = Image.open(HERO / f"idle_{elev}_D_{pname}_24.png")
    k = lambda d: knights.crop((0, d * 24, 24, d * 24 + 24))  # 시트 행 = 방향(DIRS 순서)
    put = lambda d, gp: img.alpha_composite(k(d), (int(gp[0] - 12), int(gp[1] - 19)))  # 발밑 기준점(12, 19)
    put(0, (5.5 * T, 1.5 * T))  # 성벽 바로 뒤 마을 첫 줄
    put(4, (2.5 * T, 0.5 * T))  # 마을 둘째 줄
    idx, anc, _ = wall(elev, H, pal)
    img.alpha_composite(R.rgba(idx, pal), (1 * T - anc[0], 3 * T - anc[1]))
    put(0, (2.5 * T, 2.5 * T - H))  # 성벽 위: 앞면 높이만큼 올려 그린다(02 §2)
    put(4, (5.5 * T, 3.5 * T))  # 닫힌 문 앞
    put(2, (6.5 * T, 4.5 * T))
    return img


if __name__ == "__main__":
    pname = "f24p"
    cells = []
    for elev in (45, 60):
        row = [V.up(scene(elev, H, pname), 3) for H in (16, 24, 32)]
        cells.append(R.sheet(row, 3, 6, (30, 30, 30, 255)))
    out = V.label_rows(V.stack(cells, 6), ["45°  16 / 24 / 32px", "60°  16 / 24 / 32px"], cells[0].height + 6)
    out.save(HERO.parent / "preview" / "s4_wall.png")
    walls = HERO.parent / "walls"  # 보기 화면(viewer.gd)용: 성벽만, 원점 픽셀 (4, 100). front_는 흉벽·앞면만 남긴 앞층
    walls.mkdir(exist_ok=True)
    for p in R.PALETTES:
        for elev in (45, 60):
            for H in (16, 24, 32):
                idx, _, front = wall(elev, H, R.PALETTES[p])
                R.rgba(idx, R.PALETTES[p]).save(walls / f"wall_{elev}_{p}_{H}.png")
                R.rgba(np.where(front, idx, -1), R.PALETTES[p]).save(walls / f"front_{elev}_{p}_{H}.png")
    print(out.size)
