# 거점 돌 망루(4.1c, 사용자 2026-10-20 — 목조 회관·돌 망루·깃발 광장 가운데 고름). 마을 레벨 1~4(S99)마다 한 장.
# 성벽(wall.py)과 같은 카메라·재질·벽돌 줄눈으로 그리고, 앞면 휘장과 꼭대기 깃발은 아군 팀 색(S166)이다.
# 레벨이 오를수록 커진다: 2는 앞 모서리 작은 탑, 3은 더 넓고 높은 몸통·큰 문·앞면 쇠 띠·탑 휘장, 4는 3에 가운데 높은 본성과 금빛 흉벽.
# 쇠 띠·금빛 흉벽은 성곽 단계 그림(wall.py 2·3단계)과 같은 꼴이다(S99 2026-11-14 변경, 사용자 «따로 그리자»)
# 원점 = 거점 칸 앞쪽 아래 왼쪽 모서리 = 캔버스 픽셀 ANCHOR. 칸보다 크게 그려 칸 밖으로 나간다(유닛과 같다)
# 사용: python tools/art/keep.py → art/trial/walls/keep_45_f24p_L{1,2,3,4}.png
import numpy as np

import render as R
from hero import OUT as HERO
from wall import BASE, STONE, WOOD, IRON, arch, slab

N, ANCHOR = 80, (32, 72)
TEAM, GOLD = 3, 4  # 재질 번호: BASE의 돌·나무·쇠 다음
COLORS = list(BASE.values())[:3] + ["3c9f9c", BASE["gold"]]
SIZE = {1: (0.62, 2.3), 2: (0.9, 2.6), 3: (1.1, 2.8), 4: (1.1, 2.8)}  # 몸통 반폭, 높이
TURRET, KEEP_UP = 0.55, 0.95  # 모서리 탑·가운데 본성이 몸통보다 솟는 높이


def tower(cx, cy, w, d, h, parts, teeth=None):
    """반폭 w, 반깊이 d, 높이 h인 탑 몸통과 꼭대기 흉벽 이(앞·뒤·양옆)를 parts에 더한다. teeth를 주면 흉벽 이만 거기에도 더한다"""
    parts.append(R.box([cx, cy, h / 2], [w, d, h / 2]))
    m, mh = 0.09, 0.18  # 흉벽 이 반폭, 높이
    for side in (-1, 1):
        for i in range(max(2, int(round(w / 0.22)))):
            x = cx - w + m + i * (2 * w - 2 * m) / (max(2, int(round(w / 0.22))) - 1)
            parts.append(R.box([x, cy + side * (d - m), h + mh / 2], [m, m, mh / 2]))
            if teeth is not None:
                teeth.append(parts[-1])
        for i in range(1, max(2, int(round(d / 0.22))) - 1):
            y = cy - d + m + i * (2 * d - 2 * m) / (max(2, int(round(d / 0.22))) - 1)
            parts.append(R.box([cx + side * (w - m), y, h + mh / 2], [m, m, mh / 2]))
            if teeth is not None:
                teeth.append(parts[-1])


def keep(level, pal):
    cam = R.Cam(45)
    D = 1 / cam.sin
    w, h = SIZE[level]
    x0, d = 0.5, D * 0.42
    y0 = D / 2 - d  # 몸통 앞면
    parts, teeth = [], []
    tower(x0, D / 2, w, d, h, parts, teeth)
    if level >= 2:  # 앞 모서리 두 곳에 몸통보다 높이 솟은 작은 탑
        for sx in (-1, 1):
            tower(x0 + sx * (w - 0.05), y0 + 0.2, 0.26, 0.26, h + TURRET, parts, teeth)
    if level >= 4:  # 가운데 높은 본성
        tower(x0, D / 2 + 0.1, 0.42, 0.36, h + KEEP_UP, parts, teeth)
    door = arch(x0, 0.22, 0.75) if level <= 2 else arch(x0, 0.28, 0.9)
    hole = slab(door, y0 - 0.2, y0 + 0.12)

    def stone(p):
        return np.maximum(np.min([f(p) for f in parts], axis=0), -hole(p))

    P = [(stone, STONE), (slab(door, y0 + 0.08, y0 + 0.12), WOOD)]
    if level <= 2:
        P.append((R.box([x0, y0 - 0.015, h * 0.62], [0.2, 0.02, h * 0.2]), TEAM))  # 앞면 휘장
    else:
        P.append((R.box([x0, y0 - 0.015, h * 0.66], [0.2, 0.02, h * 0.17]), TEAM))  # 앞면 휘장(쇠 띠 위)
        for sx in (-1, 1):  # 앞 탑 휘장
            P.append((R.box([x0 + sx * (w - 0.05), y0 + 0.2 - 0.26 - 0.015, h * 0.72], [0.12, 0.02, h * 0.13]), TEAM))
        for zb in (0.9 + 0.17, 0.3):  # 앞면 쇠 띠: 문 아치 위 한 줄, 밑동 한 줄(문 구멍은 피한다, wall.py 2단계와 같다)
            band = R.box([x0, y0 - 0.03, zb], [w, 0.04, 0.11])
            P.append((lambda p, band=band: np.maximum(band(p), -hole(p)), IRON))
    top = h + (KEEP_UP if level >= 4 else TURRET if level >= 2 else 0.0)  # 깃대가 선 지붕 높이
    pole = top + 0.18
    base_y = D / 2 + 0.1 if level >= 4 else D / 2
    P.append((R.capsule([x0, base_y, h], [x0, base_y, pole + 1.0], 0.06), WOOD))  # 깃대
    P.append((R.box([x0 + 0.3, base_y, pole + 0.78], [0.26, 0.03, 0.17]), TEAM))  # 깃발
    pid, lam, depth, pos = R.trace([(f, m, "") for f, m in P], cam, (0, 1), N, 16, ANCHOR, with_pos=True)
    ramps = [R.ramp([int(c[i:i + 2], 16) for i in (0, 2, 4)], pal) for c in COLORS]
    mat = np.where(pid >= 0, np.array([m for _, m in P])[np.maximum(pid, 0)], -1)
    idx = R.shade(mat, lam, depth, ramps, "D", R.darkest(pal), edge=0.19)
    x, y, z = pos[..., 0], pos[..., 1], pos[..., 2]
    st, rp = mat == STONE, [np.array(r) for r in ramps]
    row = np.floor(z / 0.35).astype(int)
    mortar = (np.mod(z, 0.35) < 0.06) | (np.mod(x + 0.35 * (row % 2), 0.7) < 0.07)  # wall.py와 같은 벽돌 줄눈
    front = st & (np.abs(lam) < 2) & (z < h - 0.05) & (y < y0 + 0.02)
    idx = np.where(front & mortar, rp[STONE][1], idx)
    idx = np.where(front & (idx == rp[STONE][3]), rp[STONE][2], idx)
    if level >= 3:  # 쇠 띠 리벳: 0.25칸마다 밝은 점(wall.py와 같다)
        idx = np.where((mat == IRON) & (y < y0 - 0.01) & (np.mod(x + 0.06, 0.25) < 0.09), rp[IRON][4], idx)
    if level >= 4:  # 금빛 흉벽(wall.py 3단계와 같다): 흉벽 이 겉면은 금빛 중간, 윗면은 금빛 하이라이트
        flat = pos.reshape(-1, 3)
        on = (np.min([f(flat) for f in teeth], axis=0).reshape(x.shape) < 0.02) & st & (idx != R.darkest(pal))  # 외곽선은 둔다
        idx = np.where(on, rp[GOLD][2], idx)
        tops = np.zeros(x.shape, bool)
        for t in (h, h + TURRET, h + KEEP_UP):
            tops |= on & (np.abs(z - t - 0.18) < 0.02)
        idx = np.where(tops, rp[GOLD][4], idx)
    return idx


if __name__ == "__main__":
    pal = R.PALETTES["f24p"]
    for level in (1, 2, 3, 4):
        R.rgba(keep(level, pal), pal).save(HERO.parent / "walls" / f"keep_45_f24p_L{level}.png")
    print("ok")
