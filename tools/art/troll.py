# 5라운드 트롤(troll 싸움꾼·twin_troll 쌍둥이, I274)의 3D 형체와 스프라이트 굽기. 오우거만 한 몸(아군의 약 1.7배), 굽은 등·긴 팔·큰 주먹,
# 큰 코와 아래 엄니, 허리 가죽, 맨손. 피부는 풀밭·오우거(붉은 갈색)·오크(회갈색)와 갈리게 청록 도는 잿빛이다.
# 뼈대·자세는 기사(hero.py) 것이다. 게임은 C 절충안으로 4방향·걷기 2위상·공격 키 포즈만 쓴다(atlas.py)
# 사용: python tools/art/troll.py [preview]  → art/trial/troll/. 검사: python tools/art/lint.py walk_45_D_f24p troll
from pathlib import Path

import hero as H
import render as R

OUT = Path(__file__).resolve().parents[2] / "art" / "trial" / "troll"
BASE = {"skin": "5f8f8a", "hide": "70462a", "tusk": ["2a1d0d", "efd8a1", "efd8a1", "efd8a1", "efd8a1"], "dark": ["151a26", "262d3d", "262d3d", "3a4357", "3a4357"], "eye": ["efac28"] * 5}
MATS = list(BASE)
PARTS = ["leg", "torso", "head", "arm"]
SIZES = (24,)
SCALE = 1.7
TAG = f"m5 ppu{H.PPU24} troll1 s{SCALE} span5"
LEAN = 14  # 굽은 등
ARMS = dict(sh_l=10, el_l=25, sh_r=10, el_r=25, ab_l=0.3, ab_r=0.3)  # 팔을 길게 늘어뜨린다
IDLE = dict(H.IDLE, lean=LEAN, **ARMS)
WALK = [dict(w, lean=LEAN, **ARMS) for w in H.WALK]
ATTACK = [dict(a, lean=a["lean"] + LEAN) for a in H.ATTACK]
ANIMS = {"idle": [IDLE], "walk": WALK, "attack": ATTACK, "fall": H.FALL}


def body(pose, bob_unit):
    U, G, up_r, legs, arms = H.rig(pose, bob_unit)
    m = MATS.index
    P = []
    for side in "lr":  # 짧고 굵은 맨다리
        hip, knee, ankle = legs[side]
        P += [(R.capsule(G(hip), G(knee), 0.06), m("skin"), "leg"), (R.capsule(G(knee), G(ankle), 0.052), m("skin"), "leg"),
              (R.ellipsoid(G(ankle + [0, 0.04, -0.005]), (0.055, 0.085, 0.034)), m("skin"), "leg")]
    P += [(R.ellipsoid(U([0, 0.0, 0.55]), (0.14, 0.12, 0.16)), m("skin"), "torso"),  # 몸통
          (R.box(U([0, 0, 0.42]), (0.125, 0.09, 0.055), up_r, 0.03), m("hide"), "torso"),  # 허리 가죽
          (R.ellipsoid(U([0, -0.04, 0.68]), (0.14, 0.13, 0.085)), m("skin"), "torso"),  # 굽은 등·넓은 어깨
          (R.ellipsoid(U([0, 0.08, 0.765]), (0.085, 0.09, 0.082)), m("skin"), "head"),  # 앞으로 내민 머리
          (R.ellipsoid(U([0, 0.175, 0.74]), (0.03, 0.045, 0.035)), m("skin"), "head"),  # 큰 코
          (R.box(U([0, 0.15, 0.685]), (0.05, 0.02, 0.012), up_r), m("dark"), "head")]  # 입
    for s in (-1, 1):
        P.append((R.capsule(U([0.07 * s, 0.15, 0.655]), U([0.078 * s, 0.165, 0.71]), 0.017), m("tusk"), "head"))  # 아래 엄니
        P.append((R.ellipsoid(U([0.04 * s, 0.175, 0.77]), (0.02, 0.014, 0.016)), m("eye"), "head"))  # 눈
    for side in "lr":  # 긴 팔과 큰 주먹
        sh, el, hd = arms[side]
        P += [(R.capsule(U(sh), U(el), 0.055), m("skin"), "arm"), (R.capsule(U(el), U(hd), 0.055, 0.05), m("skin"), "arm"),
              (R.ellipsoid(U(hd), (0.1, 0.1, 0.1)), m("skin"), "arm")]
    return P


troll = H.scaled(body, SCALE)


def fits():
    return H.fits(OUT, [IDLE] + WALK, troll, TAG, SIZES, span=5.0)


def preview():
    """검수용 확대본 → art/trial/preview/troll_*. 정지 비교 위 줄은 오우거"""
    import ogre as B
    H.preview("troll", OUT, fits()[24], [(B.OUT, B.fits()[24])])


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
        H.save(anim, anim, 45, "D", "f24p", fts, troll, BASE, ANIMS, OUT, PARTS)
    print("ok")
