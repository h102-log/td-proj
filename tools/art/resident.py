# 마을 주민(I46)의 3D 형체와 스프라이트 굽기. 무기 없는 평민: 맨머리, 파란 웃옷, 갈색 바지(사용자 2026-10-20 «수수한 민병»).
# 마을 흙(684c3c) 위를 돌아다녀서 웃옷은 흙과 갈리는 파랑이다. 작게(0.9배) 그린다. 뼈대·자세는 기사(hero.py) 것이다.
# 게임은 걷기 2위상과 4방향만 쓰고(battle_view.gd), 공격·쓰러짐은 아틀라스 칸을 맞추려고 굽는다
# 사용: python tools/art/resident.py [preview]  → art/trial/resident/. 검사: python tools/art/lint.py walk_45_D_f24p resident
from pathlib import Path

import numpy as np

import hero as H
import render as R

OUT = Path(__file__).resolve().parents[2] / "art" / "trial" / "resident"
BASE = {"skin": H.BASE["skin"], "hair": H.BASE["hair"], "cloth": "4f78ad", "trouser": "70462a"}
MATS = list(BASE)
PARTS = ["leg", "torso", "head", "arm"]
SIZES = (24,)
SCALE = 0.9
TAG = f"m5 ppu{H.PPU24} resident1 s{SCALE}"
ARMS = dict(sh_l=8, el_l=15, ab_l=0.15, sh_r=8, el_r=15, ab_r=0.15)  # 빈손을 내린다
IDLE = dict(H.IDLE, **ARMS)
WALK = [dict(w, **ARMS) for w in H.WALK]
ANIMS = {"idle": [IDLE], "walk": WALK, "attack": H.ATTACK, "fall": H.FALL}


def body(pose, bob_unit):
    U, G, up_r, legs, arms = H.rig(pose, bob_unit)
    m = MATS.index
    P = []
    for side in "lr":
        hip, knee, ankle = legs[side]
        P += [(R.capsule(G(hip), G(knee), 0.05), m("trouser"), "leg"), (R.capsule(G(knee), G(ankle), 0.045), m("trouser"), "leg"),
              (R.ellipsoid(G(ankle + [0, 0.035, -0.005]), (0.04, 0.065, 0.03)), m("trouser"), "leg")]
    P += [(R.box(U([0, 0, 0.56]), (0.11, 0.07, 0.13), up_r, 0.035), m("cloth"), "torso"),
          (H.local(U, up_r, lambda q: H.flare(q, 0.46, 0.36, 0.11, 0.125)), m("cloth"), "torso"),  # 웃옷 자락
          (R.ellipsoid(U([0, 0, 0.80]), (0.12, 0.115, 0.125)), m("skin"), "head"),
          (lambda p: np.maximum(R.ellipsoid(U([0, -0.015, 0.815]), (0.127, 0.122, 0.12))(p), -R.box(U([0, 0.1, 0.76]), (0.09, 0.1, 0.08), up_r)(p)), m("hair"), "head")]
    for side in "lr":
        sh, el, hd = arms[side]
        P += [(R.capsule(U(sh), U(el), 0.04), m("cloth"), "arm"), (R.capsule(U(el), U(hd), 0.036), m("skin"), "arm"),
              (R.ellipsoid(U(hd), (0.036, 0.036, 0.036)), m("skin"), "arm")]
    return P


resident = H.scaled(body, SCALE)


def fits():
    return H.fits(OUT, [IDLE] + WALK, resident, TAG, SIZES)


def preview():
    """검수용 확대본 → art/trial/preview/resident_*. 정지 비교 위 줄은 공병"""
    import engineer as E
    H.preview("resident", OUT, fits()[24], [(E.OUT, E.fits()[24])])


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
        H.save(anim, anim, 45, "D", "f24p", fts, resident, BASE, ANIMS, OUT, PARTS)
    print("ok")
