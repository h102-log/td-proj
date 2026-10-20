# 장갑 적(armored) 중갑 오크의 3D 형체와 스프라이트 굽기. 큰 몸(1.1배), 넓은 어깨 철판, 뿔 투구, 붉은 앞자락, 오른손 넓은 칼(사용자 2026-10-20 «판타지 괴물»).
# 피부는 풀색을 피해 회갈색이다(고블린과 같은 까닭, goblin.py). 뼈대·자세는 기사(hero.py) 것이다. 게임은 C 절충안으로 4방향·걷기 2위상·공격 키 포즈만 쓴다(atlas.py)
# 사용: python tools/art/orc.py [preview]  → art/trial/orc/. 검사: python tools/art/lint.py walk_45_D_f24p orc
from pathlib import Path

import numpy as np

import hero as H
import render as R

OUT = Path(__file__).resolve().parents[2] / "art" / "trial" / "orc"
BASE = {"skin": ["2a1d0d", "684c3c", "684c3c", "927e6a", "927e6a"],
        "iron": ["151a26", "262d3d", "3a4357", "56607a", "7a86a0"],
        "tabard": ["300f0a", "550f0a", "773421", "773421", "773421"],
        "blade": H.BASE["blade"], "leather": "70462a",
        "horn": ["2a1d0d", "927e6a", "927e6a", "efd8a1", "efd8a1"]}
MATS = list(BASE)
PARTS = ["leg", "torso", "head", "arm", "sword"]
SIZES = (24,)
SCALE = 1.1
TAG = f"m5 ppu{H.PPU24} orc1 s{SCALE}"
ANIMS = H.ANIMS
WALK = H.WALK


def body(pose, bob_unit):
    U, G, up_r, legs, arms = H.rig(pose, bob_unit)
    m = MATS.index
    P = []
    for side in "lr":  # 다리: 쇠 정강이
        hip, knee, ankle = legs[side]
        P += [(R.capsule(G(hip), G(knee), 0.058), m("leather"), "leg"), (R.capsule(G(knee), G(ankle), 0.055), m("iron"), "leg"),
              (R.ellipsoid(G(ankle + [0, 0.035, -0.005]), (0.048, 0.072, 0.034)), m("iron"), "leg")]
    P += [(R.box(U([0, 0, 0.58]), (0.14, 0.09, 0.13), up_r, 0.04), m("iron"), "torso"),  # 가슴 철판
          (R.box(U([0, 0.06, 0.4]), (0.08, 0.025, 0.1), up_r, 0.01), m("tabard"), "torso"),  # 붉은 앞자락
          (R.box(U([0, 0, 0.455]), (0.13, 0.085, 0.025), up_r), m("leather"), "torso"),
          (R.ellipsoid(U([0, 0.01, 0.79]), (0.12, 0.12, 0.12)), m("skin"), "head")]
    helm = R.ellipsoid(U([0, -0.01, 0.815]), (0.14, 0.135, 0.13))  # 투구: 얼굴 아래쪽(턱·엄니)은 드러낸다
    face = R.box(U([0, 0.1, 0.75]), (0.085, 0.1, 0.06), up_r)
    P.append((lambda p: np.maximum(helm(p), -face(p)), m("iron"), "head"))
    for s in (-1, 1):
        P.append((R.capsule(U([0.11 * s, 0, 0.86]), U([0.2 * s, 0.02, 0.99]), 0.035, 0.012), m("horn"), "head"))  # 뿔
        P.append((R.capsule(U([0.04 * s, 0.11, 0.73]), U([0.05 * s, 0.13, 0.78]), 0.014, 0.008), m("horn"), "head"))  # 엄니
    for side in "lr":  # 팔: 큰 어깨 철판, 맨 아래팔
        sh, el, hd = arms[side]
        P += [(R.ellipsoid(U(sh) + up_r @ [0, 0, 0.02], (0.1, 0.09, 0.07)), m("iron"), "torso"),
              (R.capsule(U(sh), U(el), 0.05), m("skin"), "arm"), (R.capsule(U(el), U(hd), 0.048), m("skin"), "arm"),
              (R.ellipsoid(U(hd), (0.048, 0.048, 0.048)), m("leather"), "arm")]
    hd = U(arms["r"][2])
    bd, side, third = H.blade_axes(pose, up_r)
    ax = np.stack([side, bd, third])
    P += [(R.box(hd + bd * 0.24, (0.06, 0.2, 0.014), ax, 0.01), m("blade"), "sword"),  # 넓은 칼
          (R.capsule(hd - bd * 0.05, hd + bd * 0.04, 0.024), m("leather"), "sword")]
    return P


orc = H.scaled(body, SCALE)


def fits():
    return H.fits(OUT, [H.IDLE] + WALK, orc, TAG, SIZES)


def preview():
    """검수용 확대본 → art/trial/preview/orc_*. 정지 비교 위 줄은 고블린"""
    import goblin as B
    H.preview("orc", OUT, fits()[24], [(B.OUT, B.fits()[24])])


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
        H.save(anim, anim, 45, "D", "f24p", fts, orc, BASE, ANIMS, OUT, PARTS)
    print("ok")
