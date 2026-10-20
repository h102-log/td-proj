# 보스 적(boss) 오우거의 3D 형체와 스프라이트 굽기. 아군의 약 1.7배, 불룩한 배·작은 머리, 붉은 갈색 피부, 오른손 큰 몽둥이(사용자 2026-10-20 «판타지 괴물»).
# 뼈대·자세는 기사(hero.py) 것이다. 게임은 C 절충안으로 4방향·걷기 2위상·공격 키 포즈만 쓴다(atlas.py)
# 사용: python tools/art/ogre.py [preview]  → art/trial/ogre/. 검사: python tools/art/lint.py walk_45_D_f24p ogre
from pathlib import Path

import numpy as np

import hero as H
import render as R

OUT = Path(__file__).resolve().parents[2] / "art" / "trial" / "ogre"
BASE = {"skin": ["300f0a", "550f0a", "773421", "a56243", "a56243"],
        "rag": ["151a26", "262d3d", "262d3d", "3a4357", "3a4357"],
        "wood": H.BASE["wood"], "iron": ["151a26", "3a4357", "56607a", "7a86a0", "a4aec2"]}
MATS = list(BASE)
PARTS = ["leg", "torso", "head", "arm", "club"]
SIZES = (24,)
SCALE = 1.7
TAG = f"m5 ppu{H.PPU24} ogre1 s{SCALE} span5"
LEAN = 6
IDLE = dict(H.IDLE, lean=LEAN)
WALK = [dict(w, lean=LEAN) for w in H.WALK]
ATTACK = [dict(a, lean=a["lean"] + LEAN) for a in H.ATTACK]
ANIMS = {"idle": [IDLE], "walk": WALK, "attack": ATTACK, "fall": H.FALL}


def body(pose, bob_unit):
    U, G, up_r, legs, arms = H.rig(pose, bob_unit)
    m = MATS.index
    P = []
    for side in "lr":  # 굵은 맨다리
        hip, knee, ankle = legs[side]
        P += [(R.capsule(G(hip), G(knee), 0.062), m("skin"), "leg"), (R.capsule(G(knee), G(ankle), 0.055), m("skin"), "leg"),
              (R.ellipsoid(G(ankle + [0, 0.035, -0.005]), (0.05, 0.075, 0.034)), m("skin"), "leg")]
    P += [(R.ellipsoid(U([0, 0.02, 0.56]), (0.16, 0.14, 0.17)), m("skin"), "torso"),  # 불룩한 배
          (R.box(U([0, 0, 0.42]), (0.13, 0.09, 0.05), up_r, 0.03), m("rag"), "torso"),  # 허리 천
          (R.ellipsoid(U([0, -0.02, 0.69]), (0.17, 0.12, 0.07)), m("skin"), "torso"),  # 굽은 어깨
          (R.ellipsoid(U([0, 0.04, 0.79]), (0.09, 0.09, 0.09)), m("skin"), "head"),  # 작은 머리
          (R.box(U([0, 0.11, 0.765]), (0.05, 0.02, 0.02), up_r), m("rag"), "head")]  # 입
    for side in "lr":
        sh, el, hd = arms[side]
        P += [(R.capsule(U(sh), U(el), 0.06), m("skin"), "arm"), (R.capsule(U(el), U(hd), 0.055), m("skin"), "arm"),
              (R.ellipsoid(U(hd), (0.055, 0.055, 0.055)), m("skin"), "arm")]
    hd = U(arms["r"][2])
    bd, _, _ = H.blade_axes(pose, up_r)
    P += [(R.capsule(hd - bd * 0.04, hd + bd * 0.34, 0.03, 0.075), m("wood"), "club"),  # 큰 몽둥이
          (R.capsule(hd + bd * 0.26, hd + bd * 0.33, 0.08), m("iron"), "club")]  # 쇠테
    return P


ogre = H.scaled(body, SCALE)


def fits():
    return H.fits(OUT, [IDLE] + WALK, ogre, TAG, SIZES, span=5.0)


def preview():
    """검수용 확대본 → art/trial/preview/ogre_*. 정지 비교 위 줄은 고블린"""
    import goblin as B
    H.preview("ogre", OUT, fits()[24], [(B.OUT, B.fits()[24])])


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
        H.save(anim, anim, 45, "D", "f24p", fts, ogre, BASE, ANIMS, OUT, PARTS)
    print("ok")
