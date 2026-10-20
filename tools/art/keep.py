# 거점 돌 망루(4.1c, 사용자 2026-10-20 — 목조 회관·돌 망루·깃발 광장 가운데 고름). 마을 레벨 1·2(S99)마다 한 장.
# 성벽(wall.py)과 같은 카메라·재질·벽돌 줄눈으로 그리고, 앞면 휘장과 꼭대기 깃발은 아군 팀 색(S166)이다.
# 원점 = 거점 칸 앞쪽 아래 왼쪽 모서리 = 캔버스 픽셀 ANCHOR. 칸보다 크게 그려 칸 밖으로 나간다(유닛과 같다)
# 사용: python tools/art/keep.py → art/trial/walls/keep_45_f24p_L{1,2}.png
import numpy as np

import render as R
from hero import OUT as HERO
from wall import BASE, STONE, WOOD, arch, slab

N, ANCHOR = 80, (32, 72)
TEAM = 3  # 재질 번호: BASE의 돌·나무·쇠 다음
COLORS = list(BASE.values())[:3] + ["3c9f9c"]


def tower(cx, cy, w, d, h, parts):
    """반폭 w, 반깊이 d, 높이 h인 탑 몸통과 꼭대기 흉벽 이(앞·뒤·양옆)를 parts에 더한다"""
    parts.append(R.box([cx, cy, h / 2], [w, d, h / 2]))
    m, mh = 0.09, 0.18  # 흉벽 이 반폭, 높이
    for side in (-1, 1):
        for i in range(max(2, int(round(w / 0.22)))):
            x = cx - w + m + i * (2 * w - 2 * m) / (max(2, int(round(w / 0.22))) - 1)
            parts.append(R.box([x, cy + side * (d - m), h + mh / 2], [m, m, mh / 2]))
        for i in range(1, max(2, int(round(d / 0.22))) - 1):
            y = cy - d + m + i * (2 * d - 2 * m) / (max(2, int(round(d / 0.22))) - 1)
            parts.append(R.box([cx + side * (w - m), y, h + mh / 2], [m, m, mh / 2]))


def keep(level, pal):
    cam = R.Cam(45)
    D = 1 / cam.sin
    w, h = (0.62, 2.3) if level == 1 else (0.9, 2.6)  # 몸통 반폭, 높이
    x0, d = 0.5, D * 0.42
    y0 = D / 2 - d  # 몸통 앞면
    parts = []
    tower(x0, D / 2, w, d, h, parts)
    if level == 2:  # 앞 모서리 두 곳에 몸통보다 높이 솟은 작은 탑
        for sx in (-1, 1):
            tower(x0 + sx * (w - 0.05), y0 + 0.2, 0.26, 0.26, h + 0.55, parts)
    door = arch(x0, 0.22, 0.75)

    def stone(p):
        return np.maximum(np.min([f(p) for f in parts], axis=0), -slab(door, y0 - 0.2, y0 + 0.12)(p))

    P = [(stone, STONE), (slab(door, y0 + 0.08, y0 + 0.12), WOOD)]
    P.append((R.box([x0, y0 - 0.015, h * 0.62], [0.2, 0.02, h * 0.2]), TEAM))  # 앞면 휘장
    pole = h + 0.18 + (0.55 if level == 2 else 0.0)
    P.append((R.capsule([x0, D / 2, h], [x0, D / 2, pole + 1.0], 0.06), WOOD))  # 깃대
    P.append((R.box([x0 + 0.3, D / 2, pole + 0.78], [0.26, 0.03, 0.17]), TEAM))  # 깃발
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
    return idx


if __name__ == "__main__":
    pal = R.PALETTES["f24p"]
    for level in (1, 2):
        R.rgba(keep(level, pal), pal).save(HERO.parent / "walls" / f"keep_45_f24p_L{level}.png")
    print("ok")
