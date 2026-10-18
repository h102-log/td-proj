# 바닥 타일(08 §3 단계 3a·3b): 풀 변종 4장 + 풀↔흙 꼭짓점 기준 16장 + 흙 변종.
# 모든 타일이 같은 주기 16px 노이즈를 쓰고, 변종 노이즈는 가장자리에서 0이 되게 창을 곱한다.
# 그래서 가장자리 픽셀은 그 변의 두 꼭짓점만으로 정해지고, 어떤 두 타일을 붙여도 이음매가 같다(T1)
# 사용: python tools/art/tiles.py → art/trial/tiles/ground_{팔레트}.png, T1 검사 결과 출력
from pathlib import Path

import numpy as np

import render as R

OUT = Path(__file__).resolve().parents[2] / "art" / "trial" / "tiles"
T = 16
# 2026-10-18
# [동작] 램프 [경계 그늘, 경계 띠, 바탕, 점 1, 점 2]. f24p 점은 바탕과 OKLab ΔE 약 0.05~0.065, 경계 그늘은 풀의 어두운 점 색이다
# [이유] F24는 초록이 한 색뿐이라 자동 램프(render.ramp)가 풀 밝은 쪽을 청록·회갈색으로 골라 손으로 정했다. 노란 풀 점(a58c27)은
#        방패·부츠 색과 겹쳤다(사용자). 2차에는 풀 채도가 높고 경계 그늘(1f240a·212528)이 거의 검다는 Gemini 지적으로 a58c27 자리에
#        바탕 2d472d를 넣고 그늘을 점 색으로 바꿨다. 흙 경계 띠는 773421·724113으로 밝히면 주황 테로 튀어 392a1c로 둔다
RAMPS = {"f24p": {"grass": ["183f39", "183f39", "2d472d", "183f39", "39571c"], "dirt": ["2a1d0d", "392a1c", "684c3c", "724113", "773421"]},
         "waldgeist": {"grass": ["32534a", "32534a", "5f7b53", "32534a", "3b6d62"], "dirt": ["382d35", "562923", "66352e", "562923", "825337"]}}
VARIANTS = 4
DENSITY = [1.0, 0.0, 0.0, 1.0]  # 변종별 무늬 수 배율. 0이면 민무늬: 들판 타일 절반을 비워 바닥이 덜 자글거린다(Gemini 2차 2026-10-18)


def periodic_noise(seed, cells):
    """주기 T의 값 노이즈, [-1, 1]. cells: 한 주기에 들어가는 격자 수"""
    g = np.random.default_rng(seed).uniform(-1, 1, (cells, cells))
    x = (np.arange(-1, T + 1) + 0.5) / T * cells  # 이웃 타일 가장자리(-1, T)까지 구한다
    i0 = np.floor(x).astype(int)
    f = x - i0
    f = f * f * (3 - 2 * f)
    i0, i1 = i0 % cells, (i0 + 1) % cells
    a = g[i0][:, i0] * (1 - f)[None, :] + g[i0][:, i1] * f[None, :]
    b = g[i1][:, i0] * (1 - f)[None, :] + g[i1][:, i1] * f[None, :]
    return a * (1 - f)[:, None] + b * f[:, None]  # (y, x), 크기 T+2


def window(band=3):
    """가장자리 band px은 0, 그 안 3px에 걸쳐 1로. 경계 음영은 가장자리 2px이 이웃 1px까지 보므로 3px을 비운다"""
    x = np.arange(-1, T + 1) + 0.5
    w = np.clip((np.minimum(x, T - x) - band) / 3, 0, 1)
    return w[:, None] * w[None, :]


def field(seed, var):
    """공유 노이즈 + 창 × 변종 노이즈"""
    shared = 0.6 * periodic_noise(seed, 4) + 0.4 * periodic_noise(seed + 1, 8)
    if var == 0:
        return shared
    own = 0.6 * periodic_noise(seed + 100 * var, 4) + 0.4 * periodic_noise(seed + 100 * var + 1, 8)
    return shared + window() * (own - shared)


def ramp01(t, a=0.2, b=0.8):
    """가장자리 띠(0~a, b~1)는 0·1로 고정하고 그 사이는 직선. smoothstep은 가운데가 가팔라 노이즈가 경계를 거의 못 밀었다(2회차).
    a는 2.5/16보다 커야 한다. 0.15면 3번째 픽셀이 맞은편 꼭짓점을 따라 바뀌어 T1이 깨졌다(3회차)"""
    return np.clip((t - a) / (b - a), 0, 1)


def tile(corners, var, ramps):
    """corners = (왼위, 오른위, 왼아래, 오른아래), 0 풀 1 흙 → 팔레트 번호 (T, T)"""
    tl, tr, bl, br = corners
    c = (np.arange(-1, T + 1) + 0.5) / T
    a, b = ramp01(c)[None, :], ramp01(c)[:, None]
    F = (1 - a) * (1 - b) * tl + a * (1 - b) * tr + (1 - a) * b * bl + a * b * br
    dirt = F + 0.45 * field(10, var) > 0.5  # (T+2, T+2), 이웃 가장자리 1px 포함
    g, d = ramps["grass"], ramps["dirt"]
    out = np.where(dirt, d[2], g[2])
    # 질감은 가장자리 2px을 비운 안쪽에 가로 2~3px 조각만 찍는다. 노이즈 덩어리(4~5px)는 점박이 격자로 튀었다(사용자 2026-10-18).
    # 자리는 타일(꼴·변종)마다 다르다. 변종마다 같은 자리면 16꼴이 모두 같은 «>» 무늬로 반복돼 보였다(Gemini 2차 2026-10-18)
    rng = np.random.default_rng(500 + 16 * var + tl + 2 * tr + 4 * bl + 8 * br)
    for k in range(round(3 * DENSITY[var])):
        y, x = rng.integers(3, T + 1 - 3, 2)  # 패딩 좌표 3~14 = 타일 픽셀 2~13
        kind = 3 + k % 2
        for xx in range(x, min(x + int(rng.integers(2, 4)), T - 1)):
            out[y, xx] = d[kind] if dirt[y, xx] else g[kind]
    grass_above = np.zeros_like(dirt)
    grass_above[1:] = ~dirt[:-1]
    near_grass = grass_above.copy()
    near_grass[:, 1:] |= ~dirt[:, :-1]
    near_grass[:, :-1] |= ~dirt[:, 1:]
    out = np.where(dirt & near_grass, d[1], out)  # 풀 둘레 흙은 어둡게(풀이 덮은 그늘)
    out = np.where(dirt & grass_above, g[0], out)
    return out[1:-1, 1:-1]


CONFIGS = [((k >> 0) & 1, (k >> 1) & 1, (k >> 2) & 1, (k >> 3) & 1) for k in range(16)]  # 번호 = 왼위 + 2오른위 + 4왼아래 + 8오른아래


def atlas(pname):
    """0행: 16꼴(변종 0). 1행: 풀 변종 1~3, 흙 변종 1~3"""
    pal = R.PALETTES[pname]
    hexes = ["%02x%02x%02x" % tuple(c) for c in pal]
    ramps = {k: [hexes.index(h) for h in v] for k, v in RAMPS[pname].items()}
    row0 = [tile(c, 0, ramps) for c in CONFIGS]
    row1 = [tile(CONFIGS[0], v, ramps) for v in range(1, VARIANTS)] + [tile(CONFIGS[15], v, ramps) for v in range(1, VARIANTS)]
    row1 += [np.full((T, T), -1)] * (16 - len(row1))
    return np.block([row0, row1])


def t1(at):
    """가장자리 일치: 같은 변(방향·꼭짓점 둘)을 가진 타일은 그 변의 픽셀 2줄이 모두 같아야 한다 → 불일치 수"""
    tiles = [(CONFIGS[k], at[:T, k * T:(k + 1) * T]) for k in range(16)]
    tiles += [(CONFIGS[0 if k < VARIANTS - 1 else 15], at[T:, k * T:(k + 1) * T]) for k in range(2 * (VARIANTS - 1))]
    sides = {"left": (lambda c: (c[0], c[2]), lambda t: t[:, :2]), "right": (lambda c: (c[1], c[3]), lambda t: t[:, -2:]),
             "top": (lambda c: (c[0], c[1]), lambda t: t[:2]), "bottom": (lambda c: (c[2], c[3]), lambda t: t[-2:])}
    bad = 0
    for side, (key, px) in sides.items():
        groups = {}
        for c, t in tiles:
            groups.setdefault(key(c), []).append(px(t))
        bad += sum(int((g != gs[0]).any()) for gs in groups.values() for g in gs[1:])
    return bad


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for pname, pal in R.PALETTES.items():
        at = atlas(pname)
        R.rgba(at, pal).save(OUT / f"ground_{pname}.png")
        print(pname, "T1 불일치:", t1(at))
