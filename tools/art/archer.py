# 용병 궁수(archer)의 3D 형체와 스프라이트 굽기. 수수한 민병: 회색 두건·가죽 조끼, 등에 화살통, 왼손 활(사용자 2026-10-20).
# 자세(활 든 팔·쏘기 공격)와 활은 실비아(sylvia.py) 것을 가져와 재질만 이 모듈 번호로 바꾼다. 게임은 C 절충안으로 4방향·걷기 2위상·공격 키 포즈만 쓴다(atlas.py)
# 사용: python tools/art/archer.py [preview]  → art/trial/archer/. 검사: python tools/art/lint.py walk_45_D_f24p archer
from pathlib import Path

import numpy as np

import hero as H
import render as R
import sylvia as S

OUT = Path(__file__).resolve().parents[2] / "art" / "trial" / "archer"
# 두건은 따뜻한 회갈색 손 램프다. 자동 램프(927e6a)는 회청색이라 잿빛 고블린 피부(goblin.py)와 같은 계열이 됐다
BASE = {"skin": H.BASE["skin"], "hair": H.BASE["hair"], "leather": "70462a", "cloth": ["2a1d0d", "684c3c", "684c3c", "927e6a", "927e6a"],
        "trouser": ["151a26", "262d3d", "262d3d", "3a4357", "3a4357"],
        "wood": S.BASE["wood"], "silver": S.BASE["silver"], "string": S.BASE["string"]}
MATS = list(BASE)
PARTS = S.PARTS
SIZES = (24,)
TAG = f"m5 ppu{H.PPU24} archer1"
WALK = S.WALK
ANIMS = S.ANIMS


def archer(pose, bob_unit):
    U, G, up_r, legs, arms = H.rig(pose, bob_unit)
    m = MATS.index
    P = []
    for side in "lr":  # 다리: 바지, 가죽 장화
        hip, knee, ankle = legs[side]
        P += [(R.capsule(G(hip), G(knee), 0.05), m("trouser"), "leg"), (R.capsule(G(knee), G(ankle), 0.046), m("leather"), "leg"),
              (R.ellipsoid(G(ankle + [0, 0.035, -0.005]), (0.042, 0.068, 0.032)), m("leather"), "leg")]
    P += [(R.box(U([0, 0, 0.575]), (0.11, 0.07, 0.12), up_r, 0.035), m("cloth"), "torso"),  # 웃옷
          (R.box(U([0, 0, 0.56]), (0.117, 0.077, 0.08), up_r, 0.03), m("leather"), "torso"),  # 가죽 조끼
          (R.box(U([0, 0, 0.415]), (0.105, 0.068, 0.045), up_r, 0.02), m("cloth"), "torso"),
          (R.capsule(U([0.07, -0.1, 0.45]), U([-0.06, -0.1, 0.78]), 0.04), m("leather"), "torso"),  # 등의 화살통
          (R.capsule(U([-0.06, -0.1, 0.78]), U([-0.08, -0.1, 0.86]), 0.03), m("silver"), "torso"),  # 화살 깃
          (R.ellipsoid(U([0, 0, 0.80]), (0.12, 0.115, 0.125)), m("skin"), "head")]
    hood = R.ellipsoid(U([0, -0.015, 0.81]), (0.14, 0.135, 0.14))  # 두건: 얼굴만 연다
    face = R.box(U([0, 0.1, 0.77]), (0.085, 0.1, 0.07), up_r)
    P.append((lambda p: np.maximum(hood(p), -face(p)), m("cloth"), "head"))
    for side in "lr":  # 팔: 회색 소매, 가죽 팔 보호대, 맨손
        sh, el, hd = arms[side]
        P += [(R.ellipsoid(U(sh), (0.065, 0.065, 0.05)), m("cloth"), "torso"), (R.capsule(U(sh), U(el), 0.04), m("cloth"), "arm"),
              (R.capsule(U(el), U(hd), 0.04), m("leather"), "arm"), (R.ellipsoid(U(hd), (0.036, 0.036, 0.036)), m("skin"), "arm")]
    return P + [(f, m(S.MATS[k]), part) for f, k, part in S.sylvia(pose, bob_unit) if part in ("bow", "arrow")]


def fits():
    return H.fits(OUT, [S.IDLE] + WALK, archer, TAG, SIZES)


def preview():
    """검수용 확대본 → art/trial/preview/archer_*. 정지 비교 위부터 실비아, 병사"""
    import soldier as D
    H.preview("archer", OUT, fits()[24], [(S.OUT, S.fits()[24]), (D.OUT, D.fits()[24])])


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
        H.save(anim, anim, 45, "D", "f24p", fts, archer, BASE, ANIMS, OUT, PARTS)
    print("ok")
