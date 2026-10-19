# 실비아(취풍의 명사수. SPEC S157에서 궁수 자리를 이은 3성 원거리 영웅 sylvia)의 3D 형체와 스프라이트 굽기. 컨셉은 art/concept/sylvia/(사용자 승인 2026-10-19).
# 뼈대·배율과 걷기·쓰러짐 자세는 기사(hero.py) 것을 쓰고, 활을 든 팔과 쏘기 공격만 새로 정했다(WBS 4.1d 인간형 공용 뼈대). 왼손 장궁, 오른손 시위. 45°·외곽선 D·f24p·유닛 24px(사용자 2026-10-18)
# 사용: python tools/art/sylvia.py [preview]  → art/trial/sylvia/ 에 정지·걷기·공격·쓰러짐 시트(preview: art/trial/preview/sylvia_*). 검사: python tools/art/lint.py walk_45_D_f24p sylvia
from pathlib import Path

import numpy as np

import hero as H
import ignis as I
import render as R
import seraphina as S
import vesper as V

OUT = Path(__file__).resolve().parents[2] / "art" / "trial" / "sylvia"
# 값이 hex 하나면 자동 램프, 5개 목록이면 손 램프(안쪽 외곽선, 음영 0~3. hero.ramp)
BASE = {"skin": S.BASE["skin"],
        "hair": ["151a26", "262d3d", "262d3d", "3a4357", "3a4357"],  # 먹빛 흑발. 외곽선(151a26)에 묻히지 않게 262d3d부터
        "jade": ["183f39", "276468", "276468", "3c9f9c", "3c9f9c"],
        "cape": ["183f39", "183f39", "276468", "276468", "3c9f9c"],
        "leather": ["2a1d0d", "45230d", "724113", "a56243", "a56243"],
        "trouser": ["151a26", "262d3d", "262d3d", "3a4357", "3a4357"],
        "wood": ["2a1d0d", "724113", "a56243", "a56243", "a56243"],
        "silver": ["3a4357", "7a86a0", "a4aec2", "d0d6e0", "d0d6e0"]}
MATS = list(BASE)
PARTS = ["leg", "torso", "head", "arm", "bow", "arrow"]
SIZES = (24,)
TAG = f"m5 ppu{H.PPU24} sylvia1"  # 형체 크기를 바꾸면 이 꼬리표도 바꾼다(fit.json)

ARMS = dict(sh_l=10, el_l=25, ab_l=0.45, sh_r=10, el_r=25, ab_r=0.45)  # 활을 왼쪽에 세워 든다
IDLE = dict(H.IDLE, **ARMS)
WALK = [dict(w, **ARMS) for w in H.WALK]
# 공격은 원거리(S121 사거리 4): 앞 무릎을 굽힌 런지(컨셉 자세)로 활을 과녁 쪽에 세우고 시위를 뺨까지 당겼다가(준비, 화살 보임)
# 놓으며 오른손이 귀 뒤로 튄다(발사, 가운데가 타격 프레임, 시위가 곧게 돌아오고 화살 없음). 마무리는 활을 조금 내린다
LUNGE = dict(hip_l=18, knee_l=22, hip_r=-16, knee_r=6)
ATTACK = [dict(H.POSE, **LUNGE, sh_l=85, el_l=0, ab_l=0.15, sh_r=75, el_r=95, ab_r=0.1, aim=1, draw=1),
          dict(H.POSE, **LUNGE, sh_l=85, el_l=0, ab_l=0.15, sh_r=40, el_r=140, ab_r=0.5, aim=1, lean=-3),
          dict(H.POSE, **LUNGE, sh_l=60, el_l=10, ab_l=0.2, sh_r=30, el_r=60, ab_r=0.4, aim=1)]
FALL = [dict(H.FALL[0], **ARMS), dict(H.FALL[1], **ARMS)] + [dict(f, bow=0) for f in H.FALL[2:]]
ANIMS = {"idle": [IDLE], "walk": WALK, "attack": ATTACK, "fall": FALL}
BOW = [(0.0, -0.01), (0.25, 0.05), (0.42, 0.14), (0.48, 0.12)]  # 활 한쪽 팔: (손에서 위로, 시위 쪽으로). 끝이 앞으로 살짝 젖힌다(리커브)


def sylvia(pose, bob_unit):
    U, G, up_r, legs, arms = H.rig(pose, bob_unit)
    m = MATS.index
    up, fwd = up_r @ np.array([0, 0, 1.0]), up_r @ np.array([0, 1.0, 0])
    P = []  # (sdf, 재질, 부위)
    for side in "lr":  # 다리: 어두운 바지, 가죽 무릎 장화
        hip, knee, ankle = legs[side]
        P += [(R.capsule(G(hip), G(knee), 0.05), m("trouser"), "leg"), (R.capsule(G(knee), G(ankle), 0.048), m("leather"), "leg"),
              (R.ellipsoid(G(ankle + [0, 0.035, -0.005]), (0.042, 0.068, 0.032)), m("leather"), "leg")]
    P += [(R.box(U([0, 0, 0.575]), (0.11, 0.07, 0.12), up_r, 0.035), m("jade"), "torso"),  # 비취 웃옷
          (R.box(U([0, 0, 0.49]), (0.118, 0.077, 0.045), up_r, 0.01), m("leather"), "torso"),  # 가죽 코르셋
          (H.local(U, up_r, lambda q: H.flare(q, 0.45, 0.29, 0.115, 0.15)), m("jade"), "torso"),  # 웃옷 자락
          (H.local(U, up_r, lambda q: np.maximum(H.flare(q, 0.45, 0.29, 0.115, 0.15, 0.006), q[:, 2] - 0.32)), m("leather"), "torso"),  # 자락 가죽 띠
          (R.box(U([0, -0.1, 0.44]), (0.13, 0.012, 0.25), up_r, 0.01), m("cape"), "torso"),  # 망토
          (R.capsule(U([0.07, -0.1, 0.45]), U([-0.06, -0.1, 0.78]), 0.04), m("leather"), "torso")]  # 등의 화살통
    P.append((R.capsule(U([-0.06, -0.1, 0.78]), U([-0.08, -0.1, 0.86]), 0.03), m("silver"), "torso"))  # 화살 깃
    P += [(R.ellipsoid(U([0, 0, 0.80]), (0.12, 0.115, 0.125)), m("skin"), "head"),
          (lambda p: np.maximum(R.ellipsoid(U([0, -0.015, 0.815]), (0.126, 0.12, 0.12))(p), -R.box(U([0, 0.1, 0.76]), (0.09, 0.1, 0.08), up_r)(p)), m("hair"), "head"),
          (R.capsule(U([0, -0.13, 0.84]), U([0, -0.26, 0.7]), 0.04, 0.02), m("hair"), "head")]  # 바람에 날리는 포니테일
    for side, s in (("l", -1), ("r", 1)):  # 팔: 비취 소매, 가죽 팔 보호대
        sh, el, hd = arms[side]
        P += [(R.ellipsoid(U(sh), (0.065, 0.065, 0.05)), m("jade"), "torso"),
              (R.capsule(U(sh), U(el), 0.04), m("jade"), "arm"), (R.capsule(U(el), U(hd), 0.04), m("leather"), "arm"),
              (R.ellipsoid(U(hd), (0.036, 0.036, 0.036)), m("skin"), "arm")]
    if not pose.get("bow", 1):  # 쓰러짐 뒤쪽 프레임은 활을 놓친다(FALL)
        return P
    g = U(arms["l"][2])  # 줌통
    # 시위 쪽. 정지·걷기는 몸 왼쪽에 세우고 시위를 바깥으로 둔다. 몸 쪽으로 두면 남(정면)에서 시위가 몸통 위 은색 세로줄이 됐다
    back = -fwd if pose.get("aim") else up_r @ np.array([-1.0, 0, 0])
    tips = []
    for k in (1, -1):  # 위·아래 팔
        pts = [g + up * (a * k) + back * b for a, b in BOW]
        P += [(R.capsule(pts[i], pts[i + 1], 0.03), m("wood"), "bow") for i in range(len(pts) - 1)]
        tips.append(pts[2])
    nock = U(arms["r"][2]) if pose.get("draw") else (tips[0] + tips[1]) / 2
    P += [(R.capsule(t, nock, 0.028), m("silver"), "bow") for t in tips]  # 시위
    if pose.get("draw"):  # 당긴 화살: 시위에서 줌통 앞까지
        tip = g + (g - nock) / np.linalg.norm(g - nock) * 0.1
        P += [(R.capsule(nock, tip, 0.028), m("wood"), "arrow"), (R.capsule(tip, tip + (tip - nock) / np.linalg.norm(tip - nock) * 0.05, 0.03, 0.01), m("silver"), "arrow")]
    return P


def fits():
    return H.fits(OUT, [IDLE] + WALK, sylvia, TAG, SIZES)


def preview():
    """검수용 확대본 → art/trial/preview/sylvia_*. 정지 비교는 위부터 세라피나, 베스퍼, 이그니스, 실비아"""
    H.preview("sylvia", OUT, fits()[24], [(S.OUT, S.fits()[24]), (V.OUT, V.fits()[24]), (I.OUT, I.fits()[24])])


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
        H.save(anim, anim, 45, "D", "f24p", fts, sylvia, BASE, ANIMS, OUT, PARTS)
    print("ok")
