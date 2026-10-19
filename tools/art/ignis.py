# 이그니스(원소의 지배자. SPEC S157에서 마도사 자리를 이은 3성 마법사 ignis)의 3D 형체와 스프라이트 굽기. 컨셉은 art/concept/ignis/(사용자 승인 2026-10-19).
# 뼈대·배율과 걷기·쓰러짐 자세는 기사(hero.py) 것을 쓰고, 화염구를 든 오른팔과 원거리 공격만 새로 정했다(WBS 4.1d 인간형 공용 뼈대). 오른손 위 화염구, 왼손 서리. 45°·외곽선 D·f24p·유닛 24px(사용자 2026-10-18)
# 사용: python tools/art/ignis.py [preview]  → art/trial/ignis/ 에 정지·걷기·공격·쓰러짐 시트(preview: art/trial/preview/ignis_*). 검사: python tools/art/lint.py walk_45_D_f24p ignis
from pathlib import Path

import numpy as np

import aias as A
import hero as H
import render as R
import seraphina as S
import vesper as V

OUT = Path(__file__).resolve().parents[2] / "art" / "trial" / "ignis"
# 값이 hex 하나면 자동 램프, 5개 목록이면 손 램프(안쪽 외곽선, 음영 0~3. hero.ramp)
BASE = {"skin": S.BASE["skin"],
        "robe": ["300f0a", "9b1a0a", "ef3a0c", "ef3a0c", "ef692f"],
        "char": ["151a26", "262d3d", "3a4357", "3a4357", "56607a"],  # 숯빛 안감·바지·장화·깃
        "gold": ["2a1d0d", "724113", "ab5c1c", "efac28", "efd8a1"],
        "ember": ["550f0a", "9b1a0a", "ef3a0c", "ef3a0c", "ef692f"],  # 불꽃 머리 뿌리
        "flame": ["9b1a0a", "ef692f", "ef692f", "efac28", "efac28"],  # 불꽃 머리 가운데·화염구 겉
        "flare": ["ef692f", "efac28", "efac28", "efd8a1", "efd8a1"],  # 불꽃 끝·화염구 속
        "frost": ["262d3d", "4f78ad", "a4aec2", "d0d6e0", "d0d6e0"]}
MATS = list(BASE)
PARTS = ["leg", "torso", "head", "arm", "fireball", "frost"]
SIZES = (24,)
TAG = f"m5 ppu{H.PPU24} ignis3"  # 형체 크기를 바꾸면 이 꼬리표도 바꾼다(fit.json)

R_ARM = dict(sh_r=100, el_r=60, ab_r=1.3)  # 화염구를 머리 옆으로 든다. 머리 위로 들면(sh_r 150, ab_r 0.6) 노란 화염구가 불꽃 머리와 붙어 한 덩어리였다
L_ARM = dict(sh_l=20, el_l=30, ab_l=0.5)  # 서리를 흘리는 내린 손
IDLE = dict(H.IDLE, **R_ARM, **L_ARM)
WALK = [dict(w, **R_ARM, **L_ARM) for w in H.WALK]
# 공격은 원거리(S121 사거리 4): 화염구를 머리 뒤로 젖혔다가(준비) 반 발 내디디며 앞으로 던지고(발사, 가운데가 타격 프레임, 화염구 1.5배)
# 빈손으로 거둔다(마무리, 화염구 없음). 마무리에서 화염구를 지워 «던졌다»가 읽히게 했다
ATTACK = [dict(H.POSE, **L_ARM, sh_r=175, el_r=70, ab_r=0.5, lean=-6),
          # 발사는 팔을 바깥으로 45° 벌려 화염구를 몸 실루엣 밖에 둔다. 앞으로만 뻗으면(ab_r 0.35) 남쪽 방향들에서 화염구가 주홍 로브에 묻혀
          # 배가 불룩한 것처럼 보였다(Gemini 4차 2026-10-19)
          dict(H.POSE, **L_ARM, sh_r=85, el_r=0, ab_r=1.0, lean=10, hip_r=14, knee_r=10, hip_l=-10, knee_l=10, ball=1.5),
          dict(H.POSE, **L_ARM, sh_r=55, el_r=15, ab_r=0.4, lean=5, ball=0)]
FALL = [dict(H.FALL[0], **L_ARM, ball=0)] + [dict(f, ball=0, frost=0) for f in H.FALL[1:]]
ANIMS = {"idle": [IDLE], "walk": WALK, "attack": ATTACK, "fall": FALL}
# 불꽃 머리: (뿌리, 꺾임, 끝) 윗몸 좌표. 높이가 다른 세 갈래가 위로 솟다가 뒤로 휜다. 대칭 다섯 갈래는 정면·뒷면에서
# 노란 왕관·성게처럼 보였다(Gemini 4차 2026-10-19). 노랑(flare)은 끝에만 둔다
# 가운데는 0.06(약 1px) 더 높이고 왼쪽 갈래는 가운데로 붙였다. 높이·간격이 고르면 SE에서 빨간 삼지창으로 보였다(Gemini 5차 2026-10-19).
# 가운데 끝 높이는 1.23이다. 1.21·1.22·1.24·1.25는 걷기 1px 오르내림에서 가는 끝이 2px 깜빡여 lint H3(W 또는 SW)를 넘었다
LOCKS = [((0.0, 0.02, 0.9), (0.03, -0.04, 1.07), (-0.01, -0.1, 1.23)),
         ((-0.045, 0.02, 0.88), (-0.08, -0.03, 0.97), (-0.1, -0.11, 1.03)),
         ((0.06, -0.02, 0.89), (0.11, -0.07, 1.0), (0.09, -0.15, 1.08))]


def ignis(pose, bob_unit):
    U, G, up_r, legs, arms = H.rig(pose, bob_unit)
    m = MATS.index
    up = up_r @ np.array([0, 0, 1.0])

    def robe(q, grow=0.0):  # 허리에서 발목까지 넓게 퍼지는 로브 자락
        return H.flare(q, 0.5, 0.04, 0.12, 0.2, grow)

    def opened(fn):  # 앞 트임이 아래로 갈수록 넓어진다
        return lambda q: np.maximum(fn(q), -np.maximum(np.abs(q[:, 0]) - 0.04 - 0.16 * (0.5 - q[:, 2]), -q[:, 1]))

    P = []  # (sdf, 재질, 부위)
    for side in "lr":  # 다리: 숯빛 바지·장화
        hip, knee, ankle = legs[side]
        P += [(R.capsule(G(hip), G(knee), 0.05), m("char"), "leg"), (R.capsule(G(knee), G(ankle), 0.046), m("char"), "leg"),
              (R.ellipsoid(G(ankle + [0, 0.035, -0.005]), (0.042, 0.068, 0.032)), m("char"), "leg")]
    P += [(R.box(U([0, 0, 0.575]), (0.115, 0.072, 0.12), up_r, 0.035), m("robe"), "torso"),
          (R.box(U([0, 0, 0.48]), (0.135, 0.105, 0.022), up_r, 0.01), m("gold"), "torso"),  # 보석 허리띠. 로브 자락(앞 반지름 0.096)보다 커야 보인다
          (H.local(U, up_r, opened(lambda q: np.maximum(robe(q), -robe(q, -0.015)))), m("robe"), "torso"),
          (H.local(U, up_r, opened(lambda q: np.maximum(robe(q, -0.015), -robe(q, -0.03)))), m("char"), "torso"),  # 숯빛 안감
          (H.local(U, up_r, opened(lambda q: np.maximum(robe(q, 0.006), q[:, 2] - 0.08))), m("gold"), "torso"),  # 금 단
          (R.box(U([0, -0.02, 0.71]), (0.085, 0.045, 0.045), up_r, 0.015), m("char"), "torso"),  # 높은 깃
          (R.box(U([0, 0.05, 0.665]), (0.075, 0.035, 0.025), up_r, 0.01), m("char"), "torso")]  # 앞 목깃: 불꽃 머리와 주홍 로브를 가른다(Gemini 4차 2026-10-19)
    P += [(R.ellipsoid(U([0, 0, 0.80]), (0.12, 0.115, 0.125)), m("skin"), "head"),
          (lambda p: np.maximum(R.ellipsoid(U([0, -0.02, 0.82]), (0.13, 0.125, 0.12))(p), -R.box(U([0, 0.1, 0.77]), (0.09, 0.1, 0.09), up_r)(p)), m("ember"), "head")]
    for a, b, c in LOCKS:  # 뿌리 주홍 → 가운데 주황 → 끝 노랑
        a, b, c = np.array(a), np.array(b), np.array(c)
        t = b + 0.6 * (c - b)
        P += [(R.capsule(U(a), U(b), 0.05, 0.035), m("ember"), "head"), (R.capsule(U(b), U(t), 0.035, 0.022), m("flame"), "head"),
              (R.capsule(U(t), U(c), 0.022, 0.008), m("flare"), "head")]
    for side, s in (("l", -1), ("r", 1)):  # 팔: 주홍 종 소매, 금 소맷단, 맨손
        sh, el, hd = arms[side]
        P += [(R.ellipsoid(U(sh), (0.07, 0.07, 0.055)), m("robe"), "torso"),
              (R.capsule(U(sh), U(el), 0.042), m("robe"), "arm"), (R.capsule(U(el), U(el + 0.8 * (hd - el)), 0.042, 0.07), m("robe"), "arm"),
              (R.capsule(U(el + 0.7 * (hd - el)), U(el + 0.8 * (hd - el)), 0.072), m("gold"), "arm"),
              (R.ellipsoid(U(hd), (0.038, 0.038, 0.038)), m("skin"), "arm")]
    ball = 0.07 * pose.get("ball", 1)  # 화염구. 공격 발사 프레임만 키우고, 마무리에서는 던져서 없다
    if ball:
        c = U(arms["r"][2]) + up * (0.03 + ball)
        P += [(R.ellipsoid(c, (ball, ball, ball)), m("flame"), "fireball"), (R.ellipsoid(c + up * 0.01, (ball * 0.7, ball * 0.7, ball * 0.7)), m("flare"), "fireball")]
    if pose.get("frost", 1):  # 왼손 아래로 흘러내리는 서리 파편
        hl = U(arms["l"][2])
        P.append((R.capsule(hl - up * 0.05, hl - up * 0.16, 0.03, 0.012), m("frost"), "frost"))
    return P


def fits():
    return H.fits(OUT, [IDLE] + WALK, ignis, TAG, SIZES)


def preview():
    """검수용 확대본 → art/trial/preview/ignis_*. 정지 비교는 위부터 아이아스, 세라피나, 베스퍼, 이그니스"""
    H.preview("ignis", OUT, fits()[24], [(A.OUT, A.fits()[24]), (S.OUT, S.fits()[24]), (V.OUT, V.fits()[24])])


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
        H.save(anim, anim, 45, "D", "f24p", fts, ignis, BASE, ANIMS, OUT, PARTS)
    print("ok")
