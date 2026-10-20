# 용병 병사(soldier)의 3D 형체와 스프라이트 굽기. 수수한 민병: 가죽 모자·가죽 조끼·회색 웃옷, 오른손 검, 왼손 나무 방패(사용자 2026-10-20).
# 뼈대·자세는 기사(hero.py) 것을 그대로 쓰고 투구 대신 가죽 모자를 씌웠다. 게임은 C 절충안으로 4방향·걷기 2위상·공격 키 포즈만 쓴다(atlas.py)
# 사용: python tools/art/soldier.py [preview]  → art/trial/soldier/. 검사: python tools/art/lint.py walk_45_D_f24p soldier
from pathlib import Path

import numpy as np

import hero as H
import render as R

OUT = Path(__file__).resolve().parents[2] / "art" / "trial" / "soldier"
BASE = {"skin": H.BASE["skin"], "hair": H.BASE["hair"], "leather": "70462a", "cloth": "927e6a",
        "trouser": ["151a26", "262d3d", "262d3d", "3a4357", "3a4357"],
        "blade": H.BASE["blade"], "steel": H.BASE["steel"], "wood": H.BASE["wood"]}
MATS = list(BASE)
PARTS = H.PARTS
SIZES = (24,)
TAG = f"m5 ppu{H.PPU24} soldier1"
WALK = H.WALK
ANIMS = H.ANIMS


def soldier(pose, bob_unit):
    U, G, up_r, legs, arms = H.rig(pose, bob_unit)
    m = MATS.index
    P = []
    for side in "lr":  # 다리: 바지, 가죽 장화
        hip, knee, ankle = legs[side]
        P += [(R.capsule(G(hip), G(knee), 0.052), m("trouser"), "leg"), (R.capsule(G(knee), G(ankle), 0.048), m("leather"), "leg"),
              (R.ellipsoid(G(ankle + [0, 0.035, -0.005]), (0.042, 0.068, 0.032)), m("leather"), "leg")]
    P += [(R.box(U([0, 0, 0.575]), (0.12, 0.075, 0.12), up_r, 0.035), m("cloth"), "torso"),  # 웃옷
          (R.box(U([0, 0, 0.59]), (0.127, 0.082, 0.095), up_r, 0.03), m("leather"), "torso"),  # 가죽 조끼
          (R.box(U([0, 0, 0.455]), (0.125, 0.08, 0.022), up_r), m("leather"), "torso"),  # 허리띠
          (R.box(U([0, 0, 0.415]), (0.11, 0.07, 0.04), up_r, 0.02), m("cloth"), "torso"),
          (R.ellipsoid(U([0, 0, 0.80]), (0.125, 0.12, 0.13)), m("skin"), "head"),
          (R.ellipsoid(U([0, -0.03, 0.78]), (0.12, 0.11, 0.11)), m("hair"), "head")]
    cap = R.ellipsoid(U([0, -0.01, 0.815]), (0.135, 0.13, 0.125))  # 가죽 모자: 눈썹 위만 덮는다
    cut_p, cut_n = U([0, 0, 0.83]), up_r @ [0, 0.35, 1]
    P.append((lambda p: np.maximum(cap(p), -((p - cut_p) @ cut_n)), m("leather"), "head"))
    for side in "lr":  # 팔: 회색 소매, 가죽 팔 보호대, 맨손
        sh, el, hd = arms[side]
        P += [(R.ellipsoid(U(sh), (0.065, 0.065, 0.05)), m("cloth"), "torso"), (R.capsule(U(sh), U(el), 0.042), m("cloth"), "arm"),
              (R.capsule(U(el), U(hd), 0.04), m("leather"), "arm"), (R.ellipsoid(U(hd), (0.04, 0.04, 0.04)), m("skin"), "arm")]
    hd = U(arms["r"][2])
    bd, side, third = H.blade_axes(pose, up_r)
    ax = np.stack([side, bd, third])
    dia = np.stack([(side + third) / np.sqrt(2), bd, (third - side) / np.sqrt(2)])
    P += [(R.box(hd + bd * 0.045, (0.06, 0.015, 0.02), ax), m("steel"), "sword"),
          (R.box(hd + bd * 0.32, (0.034, 0.26, 0.034), dia), m("blade"), "sword"),
          (R.capsule(hd - bd * 0.05, hd, 0.022), m("leather"), "sword")]
    _, el_l, hd_l = arms["l"]
    n = up_r @ (np.array([-0.4, 1.0, 0]) / np.linalg.norm([-0.4, 1.0, 0]))  # 방패 앞면: 앞·왼쪽
    zz = up_r @ np.array([0, 0, 1.0])
    P.append((R.box(U((el_l + hd_l) / 2) + n * 0.035, (0.12, 0.022, 0.12), np.stack([zz, n, np.cross(zz, n)]), 0.04), m("wood"), "shield"))
    return P


def fits():
    return H.fits(OUT, [H.IDLE] + WALK, soldier, TAG, SIZES)


def preview():
    """검수용 확대본 → art/trial/preview/soldier_*. 정지 비교 위 줄은 아이아스(기사 계열 영웅)"""
    import aias as A
    H.preview("soldier", OUT, fits()[24], [(A.OUT, A.fits()[24])])


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
        H.save(anim, anim, 45, "D", "f24p", fts, soldier, BASE, ANIMS, OUT, PARTS)
    print("ok")
