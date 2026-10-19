# 베스퍼(그림자 역병의 설계자. SPEC S157에서 축성가 자리를 이은 3성 디버퍼 vesper)의 3D 형체와 스프라이트 굽기. 컨셉은 art/concept/vesper/(사용자 승인 2026-10-19).
# 뼈대·배율과 정지·걷기·쓰러짐 자세는 기사(hero.py) 것을 쓰고, 향로·컴퍼스 팔과 원거리 공격만 새로 정했다(WBS 4.1d 인간형 공용 뼈대). 오른손 사슬 향로, 왼손 컴퍼스. 45°·외곽선 D·f24p·유닛 24px(사용자 2026-10-18)
# 사용: python tools/art/vesper.py [preview]  → art/trial/vesper/ 에 정지·걷기·공격·쓰러짐 시트(preview: art/trial/preview/vesper_*). 검사: python tools/art/lint.py walk_45_D_f24p vesper
from pathlib import Path

import numpy as np

import aias as A
import chronos as C
import hero as H
import render as R
import seraphina as S

OUT = Path(__file__).resolve().parents[2] / "art" / "trial" / "vesper"
# 값이 hex 하나면 자동 램프, 5개 목록이면 손 램프(안쪽 외곽선, 음영 0~3. hero.ramp). f24p에 밝은 연두가 없어 독빛은 39571c, 그늘은 2d472d다(컨셉 README)
BASE = {"leather": ["2a1d0d", "392a1c", "684c3c", "684c3c", "927e6a"],
        "hat": ["2a1d0d", "2a1d0d", "392a1c", "392a1c", "684c3c"],
        "bone": ["684c3c", "927e6a", "927e6a", "efd8a1", "efd8a1"],
        "toxin": ["1f240a", "2d472d", "39571c", "39571c", "39571c"],
        "brass": ["2a1d0d", "724113", "ab5c1c", "ab5c1c", "efac28"]}
MATS = list(BASE)
PARTS = ["leg", "torso", "head", "arm", "censer", "compass"]
SIZES = (24,)
TAG = f"m5 ppu{H.PPU24} vesper1"  # 형체 크기를 바꾸면 이 꼬리표도 바꾼다(fit.json)

CENSER = dict(sh_r=10, el_r=30, ab_r=0.6, sword=175, sword_side=0)  # 향로 사슬은 손에서 곧장 아래로 늘어진다(sword 180 = 아래)
L_ARM = dict(sh_l=25, el_l=60, ab_l=0.3)  # 컴퍼스를 가슴 높이 앞에 든다
IDLE = dict(H.IDLE, **CENSER, **L_ARM)
WALK = [dict(w, **CENSER, **L_ARM) for w in H.WALK]
# 공격은 원거리(S121 사거리 3.5): 향로를 뒤로 낮게 젖혔다가(준비) 팔을 곧게 들어 머리 위로 휘돌리며 독빛을 키우고(발사, 가운데가 타격 프레임)
# 앞으로 내린다(마무리). 과녁 쪽 앞 위로 던지면(sword 20) 남·남동·남서에서 향로가 모자에 겹쳐 안 보였다. 바깥으로 20° 눕혀 머리와 띄운다
ATTACK = [dict(H.POSE, **L_ARM, sh_r=-40, el_r=20, ab_r=0.5, sword=215, lean=-5),
          dict(H.POSE, **L_ARM, sh_r=165, el_r=5, ab_r=0.5, sword=0, sword_side=20, lean=8, glow=1.4),
          dict(H.POSE, **L_ARM, sh_r=80, el_r=20, ab_r=0.45, sword=110, lean=4)]
FALL = [dict(H.FALL[0], sword=175), dict(H.FALL[1], sword=175, compass=0)] + [dict(f, compass=0, censer=0) for f in H.FALL[2:]]
ANIMS = {"idle": [IDLE], "walk": WALK, "attack": ATTACK, "fall": FALL}


def vesper(pose, bob_unit):
    U, G, up_r, legs, arms = H.rig(pose, bob_unit)
    m = MATS.index
    up = up_r @ np.array([0, 0, 1.0])

    def coat(q, grow=0.0):  # 허리에서 정강이까지 벌어지는 코트 자락
        return H.flare(q, 0.5, 0.12, 0.12, 0.19, grow)

    def opened(fn):  # 앞이 아래로 갈수록 벌어진다
        return lambda q: np.maximum(fn(q), -np.maximum(np.abs(q[:, 0]) - 0.03 - 0.12 * (0.5 - q[:, 2]), -q[:, 1]))

    P = []  # (sdf, 재질, 부위)
    for side in "lr":  # 다리: 가죽 바지, 무릎 장화
        hip, knee, ankle = legs[side]
        P += [(R.capsule(G(hip), G(knee), 0.05), m("leather"), "leg"), (R.capsule(G(knee), G(ankle), 0.048), m("hat"), "leg"),
              (R.ellipsoid(G(ankle + [0, 0.035, -0.005]), (0.042, 0.068, 0.032)), m("hat"), "leg")]
    P += [(R.box(U([0, 0, 0.575]), (0.12, 0.075, 0.12), up_r, 0.035), m("leather"), "torso"),  # 코트 윗몸
          (R.box(U([0, 0.06, 0.53]), (0.045, 0.02, 0.09), up_r), m("bone"), "torso"),  # 앞섶 사이 뼈색 조끼
          (R.box(U([0, 0, 0.47]), (0.125, 0.08, 0.02), up_r), m("hat"), "torso"),  # 허리띠
          (R.box(U([0, 0.082, 0.47]), (0.025, 0.01, 0.02), up_r), m("brass"), "torso"),  # 놋쇠 버클
          (H.local(U, up_r, opened(lambda q: np.maximum(coat(q), -coat(q, -0.015)))), m("leather"), "torso"),  # 코트 자락
          (H.local(U, up_r, opened(lambda q: np.maximum(coat(q, -0.015), -coat(q, -0.03)))), m("toxin"), "torso"),  # 독녹 안감
          (lambda p: np.maximum(R.ellipsoid(U([0, -0.01, 0.64]), (0.2, 0.14, 0.09))(p), -((p - U([0, 0, 0.56])) @ up)), m("leather"), "torso")]  # 어깨 망토
    P += [(R.ellipsoid(U([0, -0.01, 0.80]), (0.125, 0.12, 0.13)), m("hat"), "head"),  # 두건
          (R.ellipsoid(U([0, 0.05, 0.79]), (0.1, 0.08, 0.1)), m("bone"), "head"),  # 가면
          (R.capsule(U([0, 0.1, 0.77]), U([0, 0.29, 0.62]), 0.05, 0.014), m("bone"), "head")]  # 새부리: 남(정면)에서는 화면 아래로 짧아져 가슴 위 뼈색 세로줄이 된다. 동·서에서 앞으로 나온다
    P += [(R.ellipsoid(U([0.05 * s, 0.115, 0.815]), (0.028, 0.02, 0.028)), m("toxin"), "head") for s in (-1, 1)]  # 독녹 렌즈
    P += [(R.ellipsoid(U([0, 0, 0.9]), (0.2, 0.2, 0.02)), m("hat"), "head"),  # 챙
          (lambda p: np.maximum(R.ellipsoid(U([0, -0.01, 0.9]), (0.095, 0.095, 0.11))(p), -((p - U([0, 0, 0.9])) @ up)), m("hat"), "head"),  # 모자 꼭대기
          (R.box(U([0, 0.09, 0.925]), (0.03, 0.008, 0.02), up_r), m("brass"), "head")]  # 모자 버클
    for side, s in (("l", -1), ("r", 1)):  # 팔: 가죽 소매, 장갑
        sh, el, hd = arms[side]
        P += [(R.capsule(U(sh), U(el), 0.044), m("leather"), "arm"), (R.capsule(U(el), U(hd), 0.042), m("leather"), "arm"),
              (R.ellipsoid(U(hd), (0.04, 0.04, 0.04)), m("hat"), "arm")]
    hd = U(arms["r"][2])
    bd, _, _ = H.blade_axes(pose, up_r)  # 사슬은 기사의 검과 같은 방향 값으로 늘어진다
    glow = pose.get("glow", 1)  # 공격 발사 프레임만 향로 독빛을 키운다
    c = hd + bd * 0.24
    P += [] if not pose.get("censer", 1) else [
          (R.capsule(hd, hd + bd * 0.18, 0.03), m("brass"), "censer"),  # 사슬
          (R.ellipsoid(c, (0.06, 0.06, 0.07)), m("brass"), "censer"),  # 향로
          (R.ellipsoid(c, (0.065 * glow, 0.065 * glow, 0.02)), m("toxin"), "censer")]  # 독빛 구멍 띠
    hl = U(arms["l"][2])
    side = up_r @ np.array([1.0, 0, 0])
    P += [] if not pose.get("compass", 1) else [
          (R.capsule(hl, hl + up * 0.13 + side * 0.03, 0.028), m("brass"), "compass"),
          (R.capsule(hl, hl + up * 0.13 - side * 0.03, 0.028), m("brass"), "compass")]
    return P


def fits():
    return H.fits(OUT, [IDLE] + WALK, vesper, TAG, SIZES)


def preview():
    """검수용 확대본 → art/trial/preview/vesper_*. 정지 비교는 위부터 크로노스, 아이아스, 세라피나, 베스퍼"""
    H.preview("vesper", OUT, fits()[24], [(C.OUT, C.fits()[24]), (A.OUT, A.fits()[24]), (S.OUT, S.fits()[24])])


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
        H.save(anim, anim, 45, "D", "f24p", fts, vesper, BASE, ANIMS, OUT, PARTS)
    print("ok")
