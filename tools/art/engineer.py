# 용병 공병(engineer)의 3D 형체와 스프라이트 굽기. 수수한 민병: 맨머리, 크림색 셔츠·가죽 앞치마, 오른손 망치(사용자 2026-10-20).
# 뼈대·자세는 기사(hero.py) 것을 그대로 쓴다(검 자리에 망치). 공병은 싸우지 않지만 아틀라스 칸을 맞추려고 공격도 굽는다.
# 게임은 C 절충안으로 4방향·걷기 2위상·공격 키 포즈만 쓴다(atlas.py)
# 사용: python tools/art/engineer.py [preview]  → art/trial/engineer/. 검사: python tools/art/lint.py walk_45_D_f24p engineer
from pathlib import Path

import numpy as np

import hero as H
import render as R

OUT = Path(__file__).resolve().parents[2] / "art" / "trial" / "engineer"
BASE = {"skin": H.BASE["skin"], "hair": H.BASE["hair"], "leather": "70462a", "shirt": "efd8a1",
        "trouser": ["151a26", "262d3d", "262d3d", "3a4357", "3a4357"],
        "wood": H.BASE["wood"], "steel": H.BASE["steel"]}
MATS = list(BASE)
PARTS = ["leg", "torso", "head", "arm", "hammer"]
SIZES = (24,)
TAG = f"m5 ppu{H.PPU24} engineer1"
WALK = H.WALK
ANIMS = H.ANIMS


def engineer(pose, bob_unit):
    U, G, up_r, legs, arms = H.rig(pose, bob_unit)
    m = MATS.index
    P = []
    for side in "lr":  # 다리: 바지, 가죽 장화
        hip, knee, ankle = legs[side]
        P += [(R.capsule(G(hip), G(knee), 0.052), m("trouser"), "leg"), (R.capsule(G(knee), G(ankle), 0.048), m("leather"), "leg"),
              (R.ellipsoid(G(ankle + [0, 0.035, -0.005]), (0.042, 0.068, 0.032)), m("leather"), "leg")]
    P += [(R.box(U([0, 0, 0.575]), (0.12, 0.075, 0.12), up_r, 0.035), m("shirt"), "torso"),  # 셔츠
          (R.box(U([0, 0.07, 0.5]), (0.1, 0.018, 0.13), up_r, 0.01), m("leather"), "torso"),  # 앞치마: 가슴에서 허벅지까지
          (R.box(U([0, 0, 0.455]), (0.125, 0.08, 0.022), up_r), m("leather"), "torso"),  # 허리띠
          (R.box(U([0, 0, 0.415]), (0.11, 0.07, 0.04), up_r, 0.02), m("trouser"), "torso"),
          (R.ellipsoid(U([0, 0, 0.80]), (0.125, 0.12, 0.13)), m("skin"), "head"),
          (lambda p: np.maximum(R.ellipsoid(U([0, -0.015, 0.815]), (0.13, 0.125, 0.12))(p), -R.box(U([0, 0.1, 0.76]), (0.09, 0.1, 0.08), up_r)(p)), m("hair"), "head")]
    for side in "lr":  # 팔: 걷어 올린 셔츠 소매, 맨 아래팔·손
        sh, el, hd = arms[side]
        P += [(R.ellipsoid(U(sh), (0.065, 0.065, 0.05)), m("shirt"), "torso"), (R.capsule(U(sh), U(el), 0.042), m("shirt"), "arm"),
              (R.capsule(U(el), U(hd), 0.038), m("skin"), "arm"), (R.ellipsoid(U(hd), (0.04, 0.04, 0.04)), m("skin"), "arm")]
    hd = U(arms["r"][2])
    bd, side, third = H.blade_axes(pose, up_r)
    P += [(R.capsule(hd - bd * 0.05, hd + bd * 0.24, 0.022), m("wood"), "hammer"),  # 자루
          (R.box(hd + bd * 0.24, (0.075, 0.04, 0.04), np.stack([third, bd, side]), 0.01), m("steel"), "hammer")]  # 머리: 자루에 가로
    return P


def fits():
    return H.fits(OUT, [H.IDLE] + WALK, engineer, TAG, SIZES)


def preview():
    """검수용 확대본 → art/trial/preview/engineer_*. 정지 비교 위 줄은 병사"""
    import soldier as D
    H.preview("engineer", OUT, fits()[24], [(D.OUT, D.fits()[24])])


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
        H.save(anim, anim, 45, "D", "f24p", fts, engineer, BASE, ANIMS, OUT, PARTS)
    print("ok")
