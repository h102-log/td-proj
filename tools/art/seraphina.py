# 세라피나(새벽빛의 성녀. SPEC S157에서 사제 자리를 이은 3성 힐러 seraphina)의 3D 형체와 스프라이트 굽기. 컨셉은 art/concept/seraphina/(사용자 승인 2026-10-19).
# 뼈대·배율과 정지·걷기·쓰러짐 자세는 기사(hero.py) 것을 쓰고, 지팡이·빛 구슬 팔과 원거리 공격만 새로 정했다(WBS 4.1d 인간형 공용 뼈대). 오른손 해 원반 지팡이, 왼손 빛 구슬. 45°·외곽선 D·f24p·유닛 24px(사용자 2026-10-18)
# 사용: python tools/art/seraphina.py [preview]  → art/trial/seraphina/ 에 정지·걷기·공격·쓰러짐 시트(preview: art/trial/preview/seraphina_*). 검사: python tools/art/lint.py walk_45_D_f24p seraphina
from pathlib import Path

import numpy as np

import aias as A
import chronos as C
import hero as H
import render as R

OUT = Path(__file__).resolve().parents[2] / "art" / "trial" / "seraphina"
# 값이 hex 하나면 자동 램프, 5개 목록이면 손 램프(안쪽 외곽선, 음영 0~3. hero.ramp). f24p에 흰색이 없어 상아는 efd8a1, 그늘은 927e6a다(컨셉 README)
BASE = {"skin": ["684c3c", "927e6a", "efb775", "efb775", "efb775"],  # 자동(e8b090)은 밝은 면이 상아 efd8a1이라 얼굴이 베일에 묻혔다
        "hair": ["2a1d0d", "45230d", "773421", "a56243", "a56243"],
        "ivory": ["684c3c", "927e6a", "927e6a", "efd8a1", "efd8a1"],
        "dawn": ["550f0a", "9b1a0a", "ef692f", "ef692f", "efb775"],
        "gold": ["2a1d0d", "724113", "ab5c1c", "efac28", "efd8a1"],
        "light": ["ab5c1c", "efac28", "efac28", "efd8a1", "efd8a1"]}  # 해 원반·빛 구슬. 상아로 칠하면 소매와 같은 색이라 묻혔다
MATS = list(BASE)
PARTS = ["leg", "torso", "head", "arm", "staff", "orb"]
SIZES = (24,)
TAG = f"m5 ppu{H.PPU24} seraphina1"  # 형체 크기를 바꾸면 이 꼬리표도 바꾼다(fit.json)

STAFF = dict(sword=10, sword_side=10)
L_ARM = dict(sh_l=25, el_l=55, ab_l=0.3)  # 빛 구슬을 가슴 높이 앞에 든다
IDLE = dict(H.IDLE, **STAFF, **L_ARM)
WALK = [dict(w, **STAFF, **L_ARM) for w in H.WALK]
# 공격은 원거리(S121 사거리 3): 지팡이를 뒤로 눕혀 낮게 들었다가(준비) 머리 위로 곧게 치켜들며 해 원반을 키우고 왼손을 과녁 쪽으로 뻗는다(발사,
# 가운데가 타격 프레임). 마무리는 반쯤 내린다. 과녁 쪽으로 겨누면(sword 25) 남·남동에서 앞으로 기운 지팡이가 화면에서 짧아져 안 보였다
ATTACK = [dict(H.POSE, **L_ARM, sh_r=30, el_r=40, ab_r=0.5, sword=-35, sword_side=10, lean=-5),
          dict(H.POSE, sh_l=75, el_l=5, ab_l=0.2, sh_r=165, el_r=5, ab_r=0.4, sword=-5, sword_side=5, lean=6, sun=1.6),
          dict(H.POSE, **L_ARM, sh_r=100, el_r=20, ab_r=0.45, sword=0, sword_side=10, lean=3)]
FALL = [dict(H.FALL[0], **L_ARM), dict(H.FALL[1], orb=0)] + [dict(f, orb=0, staff=0) for f in H.FALL[2:]]
ANIMS = {"idle": [IDLE], "walk": WALK, "attack": ATTACK, "fall": FALL}


def seraphina(pose, bob_unit):
    U, G, up_r, legs, arms = H.rig(pose, bob_unit)
    m = MATS.index
    o = U([0, 0, 0])

    def local(fn):  # 윗몸 자기 좌표(x 오른쪽, y 앞, z 위)로 쓴 sdf. U는 up_r 회전 + 평행 이동이다
        return lambda p: fn((p - o) @ up_r)

    def skirt(q, grow=0.0):  # 허리에서 발목까지 아래로 넓어지는 타원 원뿔(앞뒤는 0.8배)
        t = np.clip((0.47 - q[:, 2]) / 0.44, 0, 1)
        rx = 0.11 + 0.06 * t + grow
        d = (np.hypot(q[:, 0] / rx, q[:, 1] / (0.8 * rx)) - 1) * 0.8 * rx
        return np.maximum(d, np.maximum(q[:, 2] - 0.47, 0.035 - q[:, 2]))

    P = []  # (sdf, 재질, 부위)
    for side in "lr":  # 다리는 치마에 가리고 금 신발만 앞뒤로 나온다
        hip, knee, ankle = legs[side]
        P += [(R.capsule(G(hip), G(knee), 0.05), m("ivory"), "leg"), (R.capsule(G(knee), G(ankle), 0.045), m("ivory"), "leg"),
              (R.ellipsoid(G(ankle + [0, 0.035, -0.005]), (0.04, 0.065, 0.03)), m("gold"), "leg")]
    P += [(R.box(U([0, 0, 0.575]), (0.115, 0.07, 0.12), up_r, 0.035), m("ivory"), "torso"),  # 몸판
          (local(skirt), m("ivory"), "torso"),
          (local(lambda q: np.maximum(skirt(q, 0.006), q[:, 2] - 0.075)), m("gold"), "torso"),  # 겉치마 금 단
          (local(lambda q: np.maximum(np.maximum(skirt(q, 0.008), np.abs(q[:, 0]) - 0.035), -q[:, 1])), m("dawn"), "torso"),  # 앞자락 사이 새벽 주황 속치마
          (R.box(U([0, 0.066, 0.58]), (0.03, 0.012, 0.11), up_r), m("dawn"), "torso"),  # 영대
          (R.box(U([0, 0, 0.465]), (0.12, 0.078, 0.016), up_r), m("gold"), "torso"),  # 금 허리끈
          (R.box(U([0, -0.105, 0.55]), (0.13, 0.012, 0.24), up_r, 0.01), m("ivory"), "torso")]  # 등 뒤 베일
    P.append((R.ellipsoid(U([0, 0, 0.80]), (0.12, 0.115, 0.125)), m("skin"), "head"))
    hair = R.ellipsoid(U([0, -0.015, 0.805]), (0.13, 0.125, 0.13))
    veil = R.ellipsoid(U([0, -0.02, 0.81]), (0.14, 0.14, 0.14))
    face = R.box(U([0, 0.1, 0.78]), (0.08, 0.1, 0.1), up_r)
    opening = R.box(U([0, 0.1, 0.78]), (0.11, 0.12, 0.12), up_r)
    cut_p, cut_n = U([0, 0, 0.70]), up_r @ [0, 0, 1]
    P += [(lambda p: np.maximum(hair(p), -face(p)), m("hair"), "head"),
          (lambda p: np.maximum(np.maximum(veil(p), -opening(p)), -((p - cut_p) @ cut_n)), m("ivory"), "head"),
          (R.ellipsoid(U([0, 0.02, 0.955]), (0.06, 0.03, 0.04)), m("gold"), "head")]  # 해 모양 관
    for s in (-1, 1):  # 얼굴 양옆에서 가슴 앞으로 내려오는 긴 머리
        P.append((R.capsule(U([0.085 * s, 0.04, 0.76]), U([0.095 * s, 0.075, 0.58]), 0.032, 0.026), m("hair"), "head"))
    for side, s in (("l", -1), ("r", 1)):  # 팔: 상아 종 소매, 맨손
        sh, el, hd = arms[side]
        P += [(R.ellipsoid(U(sh), (0.07, 0.07, 0.055)), m("ivory"), "torso"),
              (R.capsule(U(sh), U(el), 0.042), m("ivory"), "arm"), (R.capsule(U(el), U(el + 0.8 * (hd - el)), 0.042, 0.07), m("ivory"), "arm"),
              (R.capsule(U(el + 0.7 * (hd - el)), U(el + 0.8 * (hd - el)), 0.072), m("gold"), "arm"),  # 소매 금 단
              (R.ellipsoid(U(hd), (0.038, 0.038, 0.038)), m("skin"), "arm")]
    hd = U(arms["r"][2])
    bd, _, _ = H.blade_axes(pose, up_r)  # 지팡이는 기사의 검과 같은 방향 값으로 든다
    sun = 0.05 * pose.get("sun", 1)  # 해 원반. 공격 발사 프레임만 키운다
    P += [] if not pose.get("staff", 1) else [
          (R.capsule(hd - bd * 0.48, hd + bd * 0.6, 0.03), m("gold"), "staff"),
          (R.ellipsoid(hd + bd * 0.63, (0.07, 0.03, 0.03)), m("gold"), "staff"),  # 초승달 받침
          (R.ellipsoid(hd + bd * (0.67 + sun), (sun, sun, sun)), m("light"), "staff")]
    up = up_r @ np.array([0, 0, 1.0])
    if pose.get("orb", 1):  # 왼 손바닥 위의 빛 구슬. 쓰러지면 사라진다(FALL)
        P.append((R.ellipsoid(U(arms["l"][2]) + up * 0.07, (0.04, 0.04, 0.04)), m("light"), "orb"))
    return P


def fits():
    return H.fits(OUT, [IDLE] + WALK, seraphina, TAG, SIZES)


def preview():
    """검수용 확대본 → art/trial/preview/seraphina_*. 정지 비교는 위부터 기사, 크로노스, 아이아스, 세라피나"""
    H.preview("seraphina", OUT, fits()[24], [(H.OUT, H.fits()[24]), (C.OUT, C.fits()[24]), (A.OUT, A.fits()[24])])


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
        H.save(anim, anim, 45, "D", "f24p", fts, seraphina, BASE, ANIMS, OUT, PARTS)
    print("ok")
