# 기본 적(basic) 고블린의 3D 형체와 스프라이트 굽기. 작은 몸(0.8배), 큰 머리·뾰족 귀, 앞으로 숙인 자세, 넝마 옷, 오른손 나무 몽둥이(사용자 2026-10-20 «판타지 괴물»).
# 뼈대·걷기·공격 자세는 기사(hero.py) 것에 숙임만 더했다. 게임은 C 절충안으로 4방향·걷기 2위상·공격 키 포즈만 쓴다(atlas.py)
# 피부는 잿빛, 넝마는 어두운 빨강이다(사용자 2026-10-20, art/trial/preview/goblin_skin_options.png). 초록 피부는 풀 타일(2d472d·39571c)과,
# 갈색 넝마는 흙 타일(684c3c)과 같은 색이라 바닥에 묻혔다
# 사용: python tools/art/goblin.py [preview]  → art/trial/goblin/. 검사: python tools/art/lint.py walk_45_D_f24p goblin
from pathlib import Path

import numpy as np

import hero as H
import render as R

OUT = Path(__file__).resolve().parents[2] / "art" / "trial" / "goblin"
BASE = {"skin": ["151a26", "3a4357", "56607a", "7a86a0", "a4aec2"],
        "rag": ["300f0a", "550f0a", "773421", "773421", "773421"],
        "wood": H.BASE["wood"],
        "eye": ["ab5c1c", "efac28", "efac28", "efac28", "efac28"]}
MATS = list(BASE)
PARTS = ["leg", "torso", "head", "arm", "club"]
SIZES = (24,)
SCALE = 0.8
TAG = f"m5 ppu{H.PPU24} goblin1 s{SCALE}"
HUNCH = 12  # 앞으로 숙인 각(도). 기사와 실루엣이 갈리게
IDLE = dict(H.IDLE, lean=HUNCH)
WALK = [dict(w, lean=HUNCH) for w in H.WALK]
ATTACK = [dict(a, lean=a["lean"] + HUNCH) for a in H.ATTACK]
ANIMS = {"idle": [IDLE], "walk": WALK, "attack": ATTACK, "fall": H.FALL}


def body(pose, bob_unit):
    U, G, up_r, legs, arms = H.rig(pose, bob_unit)
    m = MATS.index
    P = []
    for side in "lr":  # 맨다리
        hip, knee, ankle = legs[side]
        P += [(R.capsule(G(hip), G(knee), 0.045), m("skin"), "leg"), (R.capsule(G(knee), G(ankle), 0.04), m("skin"), "leg"),
              (R.ellipsoid(G(ankle + [0, 0.035, -0.005]), (0.04, 0.07, 0.03)), m("skin"), "leg")]
    P += [(R.box(U([0, 0, 0.57]), (0.105, 0.07, 0.11), up_r, 0.035), m("rag"), "torso"),  # 넝마 웃옷
          (R.box(U([0, 0, 0.42]), (0.105, 0.07, 0.05), up_r, 0.02), m("rag"), "torso"),
          (R.ellipsoid(U([0, 0.02, 0.80]), (0.145, 0.135, 0.125)), m("skin"), "head")]  # 큰 머리(비례 과장)
    for s in (-1, 1):  # 뾰족 귀: 옆으로 뻗어 실루엣을 가른다
        P.append((R.capsule(U([0.11 * s, 0, 0.82]), U([0.26 * s, -0.04, 0.9]), 0.035, 0.01), m("skin"), "head"))
        P.append((R.box(U([0.05 * s, 0.135, 0.815]), (0.025, 0.012, 0.018), up_r), m("eye"), "head"))
    for side in "lr":  # 맨팔
        sh, el, hd = arms[side]
        P += [(R.capsule(U(sh), U(el), 0.038), m("skin"), "arm"), (R.capsule(U(el), U(hd), 0.036), m("skin"), "arm"),
              (R.ellipsoid(U(hd), (0.04, 0.04, 0.04)), m("skin"), "arm")]
    hd = U(arms["r"][2])
    bd, _, _ = H.blade_axes(pose, up_r)
    P.append((R.capsule(hd - bd * 0.03, hd + bd * 0.3, 0.022, 0.055), m("wood"), "club"))  # 끝이 굵은 몽둥이
    return P


goblin = H.scaled(body, SCALE)


def fits():
    return H.fits(OUT, [IDLE] + WALK, goblin, TAG, SIZES)


def preview():
    """검수용 확대본 → art/trial/preview/goblin_*. 정지 비교 위 줄은 병사(soldier)"""
    import soldier as S
    H.preview("goblin", OUT, fits()[24], [(S.OUT, S.fits()[24])])


if __name__ == "__main__":
    import sys
    if sys.argv[1:] == ["preview"]:
        preview()
        sys.exit()
    OUT.mkdir(parents=True, exist_ok=True)
    fts = fits()
    for n, (ppu, anc, c) in fts.items():
        print(f"n={n} ppu={ppu:.2f} anchor={anc} canvas={c}")
    for anim in ANIMS:
        H.save(anim, anim, 45, "D", "f24p", fts, goblin, BASE, ANIMS, OUT, PARTS)
    print("ok")
