# 비행 적(flying) 하피의 3D 형체와 스프라이트 굽기. 사람 윗몸에 팔 대신 검은 날개, 접은 새 다리·발톱(사용자 2026-10-20 «판타지 괴물»).
# 늘 날고 있어서 정지도 날개를 편다. 걷기 2위상은 날갯짓(위·아래)이라 lint H3(윗몸 고정)·H4(다리 교차)는 이 모듈에 맞지 않는다.
# 뼈대는 기사(hero.py) rig()이고 날개는 위팔 방향을 따라 붙인 얇은 판이다. 게임은 C 절충안으로 4방향·날갯짓 2위상·공격 키 포즈만 쓴다(atlas.py)
# 사용: python tools/art/harpy.py [preview]  → art/trial/harpy/. 검사: python tools/art/lint.py idle_45_D_f24p harpy (H5만)
from pathlib import Path

import numpy as np

import hero as H
import render as R

OUT = Path(__file__).resolve().parents[2] / "art" / "trial" / "harpy"
BASE = {"skin": H.BASE["skin"], "hair": ["151a26", "262d3d", "262d3d", "3a4357", "3a4357"],
        "feather": ["151a26", "262d3d", "3a4357", "3a4357", "56607a"],
        "talon": ["ab5c1c", "efac28", "efac28", "efac28", "efac28"]}
MATS = list(BASE)
PARTS = ["leg", "torso", "head", "arm"]
SIZES = (24,)
SCALE = 0.9
TAG = f"m5 ppu{H.PPU24} harpy1 s{SCALE}"
TUCK = dict(hip_l=55, knee_l=90, hip_r=55, knee_r=90)  # 접은 다리
UP = dict(H.POSE, **TUCK, sh_l=150, el_l=0, ab_l=2.2, sh_r=150, el_r=0, ab_r=2.2)
DOWN = dict(H.POSE, **TUCK, sh_l=60, el_l=0, ab_l=2.2, sh_r=60, el_r=0, ab_r=2.2, bob=1)
IDLE = dict(H.POSE, **TUCK, sh_l=100, el_l=0, ab_l=2.6, sh_r=100, el_r=0, ab_r=2.6)  # 날개를 옆으로 편다
WALK = [UP, DOWN, UP, DOWN]
ATTACK = [dict(UP, lean=-10),
          dict(H.POSE, sh_l=140, el_l=0, ab_l=1.4, sh_r=140, el_r=0, ab_r=1.4, hip_l=85, knee_l=10, hip_r=85, knee_r=10, lean=-20),  # 발톱을 앞으로 내지른다
          dict(IDLE, lean=-5)]
ANIMS = {"idle": [IDLE], "walk": WALK, "attack": ATTACK, "fall": H.FALL}


def body(pose, bob_unit):
    U, G, up_r, legs, arms = H.rig(pose, bob_unit)
    m = MATS.index
    fwd = up_r @ np.array([0, 1.0, 0])
    P = []
    for side in "lr":  # 새 다리: 깃털 허벅지, 노란 정강이·발톱
        hip, knee, ankle = legs[side]
        P += [(R.capsule(G(hip), G(knee), 0.05), m("feather"), "leg"), (R.capsule(G(knee), G(ankle), 0.025), m("talon"), "leg"),
              (R.capsule(G(ankle), G(ankle) + fwd * 0.07, 0.022, 0.01), m("talon"), "leg")]
    P += [(R.box(U([0, 0, 0.57]), (0.1, 0.07, 0.12), up_r, 0.04), m("feather"), "torso"),
          (H.local(U, up_r, lambda q: H.flare(q, 0.47, 0.32, 0.1, 0.13)), m("feather"), "torso"),  # 깃털 자락
          (R.ellipsoid(U([0, 0, 0.80]), (0.115, 0.11, 0.12)), m("skin"), "head"),
          (lambda p: np.maximum(R.ellipsoid(U([0, -0.02, 0.815]), (0.125, 0.12, 0.12))(p), -R.box(U([0, 0.1, 0.76]), (0.085, 0.1, 0.08), up_r)(p)), m("hair"), "head"),
          (R.capsule(U([0, -0.1, 0.82]), U([0, -0.24, 0.66]), 0.06, 0.02), m("hair"), "head")]  # 늘어진 머리
    for side in "lr":  # 날개: 위팔 방향 a를 앞 가장자리로, 뒤로 넓은 판
        sh, el, _ = arms[side]
        s0 = U(sh)
        a = U(el) - s0
        a /= np.linalg.norm(a)
        n = np.cross(a, fwd)
        n /= np.linalg.norm(n)
        c = np.cross(n, a)
        P += [(R.capsule(s0, s0 + a * 0.42, 0.035, 0.015), m("feather"), "arm"),
              (R.box(s0 + a * 0.22 - c * 0.08, (0.21, 0.012, 0.085), np.stack([a, n, c]), 0.01), m("feather"), "arm")]
    return P


harpy = H.scaled(body, SCALE)


def fits():
    return H.fits(OUT, [IDLE] + WALK, harpy, TAG, SIZES)


def preview():
    """검수용 확대본 → art/trial/preview/harpy_*. 정지 비교 위 줄은 고블린"""
    import goblin as B
    H.preview("harpy", OUT, fits()[24], [(B.OUT, B.fits()[24])])


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
        H.save(anim, anim, 45, "D", "f24p", fts, harpy, BASE, ANIMS, OUT, PARTS)
    print("ok")
