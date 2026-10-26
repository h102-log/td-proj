# 성벽 높이 비교(WBS 4.0, art_direction_research README 결론 2): 정문이 있는 성벽 한 줄을 앞면 높이 16·24·32px(1·1.5·2칸)로 렌더하고
# 성벽 뒤(마을 첫 줄)·성벽 위·성문 앞에 기사를 세워 가림을 본다
# 사용: python tools/art/wall.py → art/trial/preview/s4_wall.png
import numpy as np
from PIL import Image

import preview as V
import render as R
import tiles as TL
from hero import OUT as HERO, fits

W = 6  # 성벽 칸 수
GATES = {"open": 1.5, "closed": 4.5}  # 문 가운데 x(칸). 열림·닫힘을 한 장면에서 함께 본다(사용자 2026-10-18 ②)
GAME_GATES = {"open": 2.5, "closed": 9.5}  # 게임 성곽(두께 3, 문 폭 3) 12칸 장면의 문 가운데 x(칸)
BASE = {"stone": "7c8494", "wood": "8a5530", "iron": "4a5060", "gold": "d0a040"}
STONE, WOOD, IRON, GOLD = 0, 1, 2, 3


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


def wall(elev, H, pal, level=1, thick=1, gate_w=1, W=W, gates=GATES):
    """앞면 높이 H px. 원점 = 성벽 앞쪽 아래 왼쪽 모서리. → (팔레트 번호 이미지, 원점 픽셀, 흉벽·앞면 마스크, 통로 그늘 불투명도).
    level은 성곽 업그레이드 단계(1~3, S86): 2부터 앞면에 쇠 띠 두 줄, 3은 흉벽 윗면을 금빛으로(4.1c, 사용자 2026-10-20).
    thick은 성벽 두께(칸), gate_w는 문 폭(칸)이다. 게임은 3·3(S217, 사용자 2026-10-26 «성벽 3칸 정도, 성문도 더 크게»)"""
    cam = R.Cam(elev)
    D1 = 1 / cam.sin  # 바닥 깊이 1칸이 화면 16px이 되게(02 §2)
    D, h = thick * D1, H / (16 * cam.cos)
    gw, gh, rd = 0.36 + 0.5 * (gate_w - 1), min(h * 0.75, 1.15), 0.3 * D1  # 문 반폭·높이, 닫힌 문이 앞면에서 들어간 깊이. 0.15D는 벽 안으로 든 깊이가 안 보였다(Gemini 2026-10-18)
    # 흉벽: 앞면과 같은 면에서 올라가는 두께 pd·높이 ph의 난간, 위를 cd만큼 판 총안. 윗면 한가운데 무늬처럼 보였다(사용자 2026-10-18 ③)
    pd, ph, cd = 0.12 * D1, 0.32, 0.16
    GATES = gates
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
        lh = gh - gw if gate_w == 1 else 0.7 * gh  # 문짝 높이. 넓은 문은 아치가 낮은 반원 조각이라 그 아래 사각 부분이 없다
        P.append((R.box([GATES["open"] + sx * (gw - 0.03), rd + gw / 2, lh / 2], [0.02, gw / 2, lh / 2]), WOOD))
    if level >= 2:  # 앞면 쇠 띠: 문 아치 위 한 줄, 밑동 한 줄(문 구멍은 피한다)
        for zb in (gh + 0.3, 0.3):
            band = R.box([W / 2, -0.03, zb], [W / 2, 0.04, 0.11])
            P.append((lambda p, band=band: np.maximum(band(p), -np.min([g(p) for g in holes], axis=0)), IRON))
    n = max(104, W * 16 + 8)
    anchor = (4, n - 4)
    pid, lam, depth, pos = R.trace([(f, m, "") for f, m in P], cam, (0, 1), n, 16, anchor, with_pos=True)
    ramps = [R.ramp([int(BASE[k][i:i + 2], 16) for i in (0, 2, 4)], pal) for k in BASE]
    mat = np.where(pid >= 0, np.array([m for _, m in P])[np.maximum(pid, 0)], -1)
    # 윗면과 앞면이 같은 단계라 앞면을 한 단계 내려 가른다(Gemini 2026-10-18). 윗면을 올리면 흉벽 하이라이트와 같은 색이 됐다
    idx = R.shade(mat, lam, depth, ramps, "D", R.darkest(pal), edge=0.19)
    x, y, z = pos[..., 0], pos[..., 1], pos[..., 2]
    st, rp = mat == STONE, [np.array(r) for r in ramps]
    row = np.floor(z / 0.35).astype(int)
    # 앞면 벽돌 줄눈. 0.25×0.5칸 벽돌은 줄이 빽빽해 철망 같았다(Gemini 2차 2026-10-18). 줄눈 색은 이미 앞면보다 램프 한 단계 아래다
    mortar = (np.mod(z, 0.35) < 0.06) | (np.mod(x + 0.35 * (row % 2), 0.7) < 0.07)
    front = st & (y < 0.01)
    idx = np.where(front & mortar, rp[STONE][1], idx)
    idx = np.where(front & (idx == rp[STONE][3]), rp[STONE][2], idx)
    idx = np.where(st & (z > h + ph - 0.02), rp[GOLD if level >= 3 else STONE][4], idx)  # 흉벽 윗면 하이라이트. 3단계는 금빛 장식
    if level >= 2:  # 쇠 띠 리벳: 0.25칸마다 밝은 점. 띠만으로는 줌 2에서 앞면 줄눈과 섞였다
        idx = np.where((mat == IRON) & (y < -0.01) & (np.mod(x + 0.06, 0.25) < 0.09), rp[IRON][4], idx)
    if level >= 3:
        idx = np.where(st & (z > h + ph - cd - 0.02) & (z <= h + ph - 0.02) & (y < 0.01), rp[GOLD][2], idx)  # 총안 사이 앞면도 금빛
    inside = st & (y > 0.01) & (z < gh + 0.01) & (((np.abs(x - GATES["open"]) < gw + 0.01)) | ((np.abs(x - GATES["closed"]) < gw + 0.01) & (y < rd + 0.01)))
    idx = np.where(inside, rp[STONE][1], idx)  # 문 안쪽 통로·홈은 그늘
    plank = (mat == WOOD) & (np.abs(x - GATES["closed"]) < gw - 0.05) & (np.mod(x - (GATES["closed"] - gw), 2 * gw / 3) < 0.05)
    idx = np.where(plank, rp[WOOD][1], idx)  # 판자 줄 2개
    gate = inside | (mat == WOOD) | (mat == IRON)
    pf = np.pad(front, 1)
    near_front = pf[:-2, 1:-1] | pf[2:, 1:-1] | pf[1:-1, :-2] | pf[1:-1, 2:]
    idx = np.where(gate & near_front, R.darkest(pal), idx)  # 아치 테두리는 최암색
    # 옥상 뒤 모서리: 최암색 외곽선이 성벽 뒤 유닛을 날카롭게 잘라 보여, 앞면 바탕색 선 + 바로 아래 하이라이트로 바꾼다(Gemini 2차 2026-10-18)
    walk_top = st & (z > h - 0.01) & (y > pd + 0.01)
    if thick > 1:  # 두꺼운 성벽(S217): 통로 윗면에 칸마다 판석 줄눈. 넓은 윗면이 한 색이라 밋밋했고, 유닛이 설 칸이 보인다
        idx = np.where(walk_top & ((np.mod(x, 1.0) < 0.06) | (np.mod(y, D1) < 0.05)), rp[STONE][2], idx)
    edge = (pid < 0) & np.pad(walk_top, ((0, 1), (0, 0)))[1:]
    idx = np.where(edge, rp[STONE][2], idx)
    idx = np.where(np.pad(edge, ((1, 0), (0, 0)))[:-1] & walk_top, rp[STONE][4], idx)
    # 2026-10-18
    # [동작] 열린 문 통로 그늘의 불투명도(위 85% → 아래 25%, 0~255). 통로 픽셀은 바닥을 깔고 한 번 더 그려서 구한다
    # [이유] 그늘 없이 땅 타일이 그대로 비쳐 성벽에 구멍이 난 것처럼 보였다(Gemini 2차). 최암색 디더는 창살문처럼 보여서,
    #        발밑 그림자처럼 반투명 층으로 따로 그린다. 성벽 그림에는 반투명을 굽지 않는다
    floor = R.box([GATES["open"], D / 2, -0.02], [gw, D / 2, 0.02])
    passage = (pid < 0) & (R.trace([(f, m, "") for f, m in P + [(floor, STONE)]], cam, (0, 1), n, 16, anchor)[0] >= 0)
    rows = np.nonzero(passage.any(1))[0]
    t = (np.arange(n)[:, None] - rows.min()) / (rows.max() - rows.min())
    shade = np.where(passage, np.round(255 * (0.85 - 0.6 * t)), 0).astype(np.uint8)
    return idx, anchor, (st | (mat == IRON)) & (y < pd + 0.01), shade  # 흉벽·앞면(쇠 띠 포함): 성벽 위 유닛보다 나중에 그려 발을 가린다


def rubble(elev, H, pal, thick=1, n=104):
    """무너진 성곽 칸(잔해, I88): 들쭉날쭉한 낮은 밑동과 흩어진 돌. 지나갈 수 있게 보이도록 낮게 그린다.
    한 칸(x 0~1)만 그리고 원점은 wall과 같다. thick은 성벽 두께(칸)다"""
    cam = R.Cam(elev)
    D = thick / cam.sin
    rng = np.random.default_rng(7)
    parts = [R.box([0.125 + 0.25 * k, D * 0.6, hz / 2], [0.125, D * 0.25, hz / 2]) for k, hz in enumerate(rng.uniform(0.08, 0.3, 4))]
    for _ in range(12 * thick):  # 두꺼운 성벽(S217)은 칸 수만큼 돌을 더 흩는다
        a = rng.uniform(0, np.pi)
        axes = [[np.cos(a), np.sin(a), 0], [-np.sin(a), np.cos(a), 0], [0, 0, 1]]
        half = rng.uniform(0.04, 0.1, 3)
        parts.append(R.box([rng.uniform(0.08, 0.92), rng.uniform(0.05, D - 0.05), half[2]], half, axes, rnd=0.015))
    stone = lambda p: np.min([f(p) for f in parts], axis=0)
    anchor = (4, n - 4)
    pid, lam, dist = R.trace([(stone, STONE, "")], cam, (0, 1), n, 16, anchor)
    ramps = [R.ramp([int(BASE[k][i:i + 2], 16) for i in (0, 2, 4)], pal) for k in BASE]
    return R.shade(np.where(pid >= 0, STONE, -1), lam, dist, ramps, "D", R.darkest(pal), edge=0.19)


def shade_img(a):
    """불투명도 → 검정 반투명 RGBA"""
    return Image.fromarray(np.dstack([np.zeros_like(a)] * 3 + [a]), "RGBA")


def scene(elev, H, pname):
    pal = R.PALETTES[pname]
    T = 16
    at = TL.atlas(pname)
    rng = np.random.default_rng(2)
    grass = [at[:T, :T]] + [at[T:2 * T, k * T:(k + 1) * T] for k in range(3)]
    dirt = [at[:T, 15 * T:]] + [at[T:2 * T, k * T:(k + 1) * T] for k in range(3, 6)]
    rows = [[(dirt if y < 2 else grass)[rng.integers(4)] for _ in range(8)] for y in range(6)]  # 0~1행 마을(흙), 2행 성벽, 3~5행 들판
    img = R.rgba(np.block(rows), pal)
    _, (ax, ay), c = fits()[24]
    knights = Image.open(HERO / f"idle_{elev}_D_{pname}_24.png")
    k = lambda d: knights.crop((0, d * c, c, d * c + c))  # 시트 행 = 방향(DIRS 순서), 프레임은 c×c
    put = lambda d, gp: img.alpha_composite(k(d), (int(gp[0] - ax), int(gp[1] - ay)))  # 발밑 기준점
    put(0, (5.5 * T, 1.5 * T))  # 성벽 바로 뒤 마을 첫 줄
    put(4, (2.5 * T, 0.5 * T))  # 마을 둘째 줄
    idx, anc, _, shade = wall(elev, H, pal)
    img.alpha_composite(R.rgba(idx, pal), (1 * T - anc[0], 3 * T - anc[1]))
    img.alpha_composite(shade_img(shade), (1 * T - anc[0], 3 * T - anc[1]))
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
    walls = HERO.parent / "walls"  # 보기 화면(viewer.gd)용: 성벽만, 원점 픽셀 (4, 100). front_는 흉벽·앞면만 남긴 앞층, shade_는 통로 그늘
    walls.mkdir(exist_ok=True)
    for p in R.PALETTES:
        for elev in (45, 60):
            for H in (16, 24, 32):
                idx, _, front, shade = wall(elev, H, R.PALETTES[p])
                R.rgba(idx, R.PALETTES[p]).save(walls / f"wall_{elev}_{p}_{H}.png")
                R.rgba(np.where(front, idx, -1), R.PALETTES[p]).save(walls / f"front_{elev}_{p}_{H}.png")
                shade_img(shade).save(walls / f"shade_{elev}_{H}.png")  # 팔레트와 무관하다
    pal = R.PALETTES["f24p"]  # 게임 값(4.0 확정: 45°, F24+, 앞면 24px)만 단계·잔해를 그린다(4.1c)
    for level in (2, 3):
        idx, _, front, _ = wall(45, 24, pal, level)
        R.rgba(idx, pal).save(walls / f"wall_45_f24p_24_L{level}.png")
        R.rgba(np.where(front, idx, -1), pal).save(walls / f"front_45_f24p_24_L{level}.png")
    R.rgba(rubble(45, 24, pal), pal).save(walls / "rubble_45_f24p_24.png")
    # 게임 성곽(S217): 두께 3칸, 문 폭 3칸. 12칸 장면에 열린 문(1~4칸)·닫힌 문(8~11칸)을 두고 그 사이를 성벽 칸으로 자른다(atlas.py castle)
    for level in (1, 2, 3):
        idx, anc, front, shade = wall(45, 24, pal, level, thick=3, gate_w=3, W=12, gates=GAME_GATES)
        R.rgba(idx, pal).save(walls / f"wall_t3_L{level}.png")
        R.rgba(np.where(front, idx, -1), pal).save(walls / f"front_t3_L{level}.png")
    shade_img(shade).save(walls / "shade_t3.png")
    R.rgba(rubble(45, 24, pal, thick=3, n=idx.shape[0]), pal).save(walls / "rubble_t3.png")
    print(out.size)
