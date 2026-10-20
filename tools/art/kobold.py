# 빠른 적(fast) 코볼트의 3D 형체와 스프라이트 굽기. 마른 몸(0.85배), 앞으로 뻗은 주둥이·꼬리, 붉은 비늘, 맨손(발톱)으로 친다(사용자 2026-10-20 «판타지 괴물»).
# 성벽을 기어오르는 적이다(S107). 뼈대·자세는 기사(hero.py) 것에 깊은 숙임을 더했다. 게임은 C 절충안으로 4방향·걷기 2위상·공격 키 포즈만 쓴다(atlas.py)
# 사용: python tools/art/kobold.py [preview]  → art/trial/kobold/. 검사: python tools/art/lint.py walk_45_D_f24p kobold
from pathlib import Path

import numpy as np

import hero as H
import render as R

OUT = Path(__file__).resolve().parents[2] / "art" / "trial" / "kobold"
BASE = {"scale": ["300f0a", "550f0a", "9b1a0a", "9b1a0a", "ef692f"],
        "rag": ["151a26", "262d3d", "262d3d", "3a4357", "3a4357"],
        "eye": ["ab5c1c", "efac28", "efac28", "efac28", "efac28"]}
MATS = list(BASE)
PARTS = ["leg", "torso", "head", "arm"]
SIZES = (24,)
SCALE = 0.85
TAG = f"m5 ppu{H.PPU24} kobold1 s{SCALE}"
HUNCH = 16  # 고블린(12°)보다 깊이 숙여 달리는 꼴. 22°는 0.75배에서 몸이 붉은 점으로 뭉쳤다
ARMS = dict(sh_l=35, el_l=60, sh_r=35, el_r=60, ab_l=0.25, ab_r=0.25)  # 팔을 앞으로 든다(발톱)
IDLE = dict(H.POSE, **ARMS, lean=HUNCH)
WALK = [dict(w, **ARMS, lean=HUNCH) for w in H.WALK]
ATTACK = [dict(H.POSE, lean=HUNCH, sh_l=110, el_l=30, sh_r=110, el_r=30, ab_l=0.2, ab_r=0.2),  # 두 팔 치켜듦
          dict(H.POSE, lean=HUNCH + 15, sh_l=70, el_l=5, sh_r=70, el_r=5, ab_l=0.1, ab_r=0.1, hip_r=14, knee_r=10, hip_l=-10, knee_l=10),  # 할퀴기
          dict(H.POSE, **ARMS, lean=HUNCH + 5)]
ANIMS = {"idle": [IDLE], "walk": WALK, "attack": ATTACK, "fall": H.FALL}


def body(pose, bob_unit):
    U, G, up_r, legs, arms = H.rig(pose, bob_unit)
    m = MATS.index
    P = []
    for side in "lr":
        hip, knee, ankle = legs[side]
        P += [(R.capsule(G(hip), G(knee), 0.042), m("scale"), "leg"), (R.capsule(G(knee), G(ankle), 0.036), m("scale"), "leg"),
              (R.ellipsoid(G(ankle + [0, 0.04, -0.005]), (0.038, 0.075, 0.028)), m("scale"), "leg")]
    P += [(R.box(U([0, 0, 0.56]), (0.095, 0.065, 0.12), up_r, 0.04), m("scale"), "torso"),
          (R.box(U([0, 0, 0.43]), (0.1, 0.068, 0.04), up_r, 0.02), m("rag"), "torso"),  # 허리 천
          (R.capsule(U([0, -0.06, 0.42]), U([0, -0.38, 0.18]), 0.055, 0.02), m("scale"), "torso"),  # 꼬리
          (R.ellipsoid(U([0, 0.0, 0.79]), (0.105, 0.11, 0.1)), m("scale"), "head"),
          (R.capsule(U([0, 0.06, 0.77]), U([0, 0.25, 0.74]), 0.065, 0.035), m("scale"), "head")]  # 주둥이
    for s in (-1, 1):
        P.append((R.capsule(U([0.06 * s, -0.04, 0.85]), U([0.1 * s, -0.16, 0.92]), 0.03, 0.01), m("scale"), "head"))  # 뒤로 뻗은 뿔
        P.append((R.box(U([0.06 * s, 0.07, 0.82]), (0.02, 0.012, 0.016), up_r), m("eye"), "head"))
    for side in "lr":
        sh, el, hd = arms[side]
        P += [(R.capsule(U(sh), U(el), 0.034), m("scale"), "arm"), (R.capsule(U(el), U(hd), 0.032), m("scale"), "arm"),
              (R.ellipsoid(U(hd), (0.038, 0.038, 0.038)), m("scale"), "arm")]
    return P


kobold = H.scaled(body, SCALE)


def fits():
    return H.fits(OUT, [IDLE] + WALK, kobold, TAG, SIZES)


def preview():
    """검수용 확대본 → art/trial/preview/kobold_*. 정지 비교 위 줄은 고블린"""
    import goblin as B
    H.preview("kobold", OUT, fits()[24], [(B.OUT, B.fits()[24])])


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
        H.save(anim, anim, 45, "D", "f24p", fts, kobold, BASE, ANIMS, OUT, PARTS)
    print("ok")
