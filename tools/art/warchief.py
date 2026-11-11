# 6라운드 오크 대족장 군단 그림(I287)의 3D 형체와 스프라이트 굽기: 오크 대족장(warchief, 전쟁 늑대를 탄 모습)·내린 대족장(warchief_foot)·
# 대족장 근위대(warguard)·전쟁 깃발(warbanner). 대족장은 장갑 오크(orc.py)의 몸에 길게 휜 뼈 뿔과 붉은 볏의 투구, 금 테와 금 허리띠, 늑대 털 깃과
# 붉은 망토, 가시 돋친 어깨 철판, 두 날 전쟁 도끼를 더한 생김새다. 전쟁 늑대는 늑대 기수(rider.py)의 늑대에 짙은 회갈 털·붉은 눈(알파 늑대 재질),
# 쇠 이마 가리개와 가시 목걸이, 붉은 안장 깔개를 더했다. 근위대는 검은 철 온몸 갑옷에 닫힌 투구(붉은 눈 틈)·붉은 볏, 큰 방패와 미늘창이다.
# 깃발은 가로대에 건 붉은 천(해골 문양, 두 갈래 끝)과 뼈 뿔 꼭대기의 장대다. 뼈대·자세는 기사(hero.py) 것이고 늑대 다리는 rider.py와 같다.
# 게임은 C 절충안으로 4방향·걷기 2위상·공격 키 포즈와 스킬 자세 2열(예고 끝·발동)만 쓴다(atlas.py). 깃발은 남쪽 한 행만 쓴다
# 사용: python tools/art/warchief.py [preview]  → art/trial/<종류>/. 검사: python tools/art/warchief.py lint
from pathlib import Path

import numpy as np

import hero as H
import orc as O
import render as R
import wolf as W

TRIAL = Path(__file__).resolve().parents[2] / "art" / "trial"
_FUR = W.base("alpha_wolf")
BASE = {"fur": _FUR["fur"], "pale": _FUR["pale"], "nose": _FUR["nose"], "eye": _FUR["eye"],
        "skin": O.BASE["skin"], "iron": O.BASE["iron"], "black": ["151a26", "151a26", "262d3d", "3a4357", "56607a"],  # 검은 철(근위대): 장갑 오크보다 한 단계 어둡다
        "gold": ["724113", "ab5c1c", "efac28", "efac28", "efd8a1"], "red": ["300f0a", "550f0a", "9b1a0a", "9b1a0a", "ef3a0c"],
        "bone": ["684c3c", "927e6a", "efd8a1", "efd8a1", "efd8a1"], "blade": H.BASE["blade"], "leather": O.BASE["leather"],
        "wood": H.BASE["wood"], "dark": ["151a26"] * 5}
MATS = list(BASE)
PARTS = ["leg", "torso", "head", "arm", "sword", "shield"]
SIZES = (24,)
SEAT = 1.1  # 탄 대족장의 크기: 형체 배율 2.0을 곱하면 내린 대족장(2.2)과 같다
WOLF = 1.2  # 전쟁 늑대의 크기(늑대 기수의 늑대 = 1). 대족장을 태운 큰 늑대로 읽히게
TAG = f"m5 ppu{H.PPU24} warchief3"
VERS = {"warchief": " wolf1.2", "warbanner": " tails2"}  # 종류마다 형체를 바꾼 때 맞춤 꼬리표에 더하는 말(그 종류만 다시 맞춘다)

# ── 자세 ── 기사 자세에 더한 칸: gait·tuck·lunge·jaw(늑대, rider.py), low 늑대가 몸을 낮춘 높이, roll 늑대가 옆으로 누운 각(도), rider 탄 대족장을 그리나,
# (rider가 거짓이면 늑대를 옆모습으로 돌려 놓는다), horn 왼손 뿔나팔, pole 두 손에 쥔 깃대(0 치켜듦, 1 땅에 꽂음), roar 벌린 입, sway 깃발 천이 흔들린 쪽(−1·0·1)
RIDE = dict(H.IDLE, sh_l=45, el_l=45, ab_l=0.1, gait=0, tuck=0, lunge=0.0, jaw=0, low=0.0, roll=0, rider=True)  # 왼손은 앞으로 내려 갈기를 쥔다
RIDE_WALK = [dict(RIDE, gait=24), dict(RIDE, tuck=1, bob=1), dict(RIDE, gait=-24), dict(RIDE, tuck=-1, bob=1)]
_GRIP = dict(sh_l=45, el_l=45, ab_l=0.1, tuck=0, low=0.0, roll=0, rider=True)
RIDE_ATTACK = [dict(H.ATTACK[0], gait=10, lunge=-0.02, jaw=15, **_GRIP),
               dict(H.ATTACK[1], gait=-14, lunge=0.1, jaw=45, **_GRIP),  # 타격: 대족장은 내려찍고 늑대는 고개를 내밀어 문다
               dict(H.ATTACK[2], gait=0, lunge=0.03, jaw=10, **_GRIP)]
# 스킬 자세 [예고 끝, 발동]. 돌진: 늑대가 몸을 낮추고 도끼를 앞으로 겨눈다 → 길게 뻗어 달린다
RIDE_CHARGE = [dict(RIDE, low=0.07, lunge=-0.03, jaw=12, lean=22, sh_r=60, el_r=20, ab_r=0.3, sword=75, sword_side=10),
               dict(RIDE, gait=30, lunge=0.1, jaw=40, lean=28, sh_r=80, el_r=5, ab_r=0.3, sword=92, sword_side=5)]
_HORN = [dict(horn=True, sh_l=70, el_l=70, ab_l=-0.2),  # 뿔나팔을 가슴 앞에 든다
         dict(horn=True, sh_l=105, el_l=70, ab_l=-0.45, lean=-8, sh_r=165, el_r=10, ab_r=0.4, sword=-5, sword_side=10)]  # 입에 대고 불며 도끼를 치켜든다
RIDE_ORDER = [dict(RIDE, **h) for h in _HORN]
# 겨눔(사슬 갈고리·사슬 족쇄·결투 신청): 도끼를 어깨 뒤로 젖힌다 → 도끼와 왼손을 앞으로 뻗는다
_AIM = [dict(sh_r=150, el_r=20, sword=-70, sword_side=0, lean=-6, sh_l=30, el_l=40),
        dict(sh_r=82, el_r=5, ab_r=0.2, sword=95, sword_side=0, lean=10, sh_l=95, el_l=5, ab_l=0.25)]
RIDE_AIM = [dict(RIDE, **a) for a in _AIM]
RIDE_FALL = [dict(RIDE, rider=False, roll=r, jaw=25, gait=g) for r, g in ((0, 0), (20, 5), (45, 10), (70, 15), (88, 20))]  # 내린 뒤 쓰러진 전쟁 늑대: 옆으로 누워 다리가 벌어진다(게임은 마지막 칸만 쓴다)

FOOT = dict(H.IDLE)
FOOT_HORN = [dict(FOOT, **h) for h in _HORN]
FOOT_BANNER = [dict(H.POSE, pole=0, sh_l=120, el_l=40, ab_l=-0.45, sh_r=120, el_r=40, ab_r=-0.45, lean=-5),  # 깃대를 두 손으로 치켜든다
               dict(H.POSE, pole=1, sh_l=60, el_l=50, ab_l=-0.45, sh_r=60, el_r=50, ab_r=-0.45, lean=14, hip_r=14, knee_r=10, hip_l=-10, knee_l=10)]  # 땅에 내리꽂는다
FOOT_ROAR = [dict(FOOT, lean=-12, sh_l=-25, el_l=20, sh_r=-25, el_r=20, sword=30),  # 몸을 젖혀 숨을 들이쉰다
             dict(FOOT, roar=True, lean=16, sh_l=35, el_l=30, ab_l=1.3, sh_r=35, el_r=30, ab_r=1.3, sword=40, sword_side=70, hip_l=-12, knee_l=8, hip_r=12, knee_r=8)]  # 두 팔을 벌리고 포효한다
FOOT_VERDICT = [dict(H.POSE, sh_r=85, el_r=5, ab_r=0.2, sword=95, sword_side=0, lean=4, sh_l=10, el_l=30), H.ATTACK[1]]  # 도끼로 가리킨다 → 내려찍는다(처형)

GUARD = dict(H.IDLE, sword=6, sword_side=18)  # 미늘창을 곧게 세워 든다
GUARD_WALK = [dict(w, sword=6, sword_side=18) for w in H.WALK]

FLAG = dict(sway=0, bob=0)
FLAG_SWAY = [dict(sway=-1, bob=0), dict(sway=1, bob=0)]


def _axe(P, hd, pose, up_r):
    """오른손 두 날 전쟁 도끼: 나무 자루, 금 고리, 양쪽 날, 꼭대기 창끝"""
    m = MATS.index
    bd, side, third = H.blade_axes(pose, up_r)
    ax = np.stack([side, bd, third])
    P += [(R.capsule(hd - bd * 0.14, hd + bd * 0.47, 0.02), m("wood"), "sword"),
          (R.capsule(hd + bd * 0.47, hd + bd * 0.57, 0.022, 0.004), m("blade"), "sword"),
          (R.capsule(hd + bd * 0.25, hd + bd * 0.29, 0.03), m("gold"), "sword")]
    for s in (-1, 1):
        plate = R.box(hd + bd * 0.38 + side * 0.09 * s, (0.075, 0.12, 0.014), ax, 0.012)
        bite_a = R.ellipsoid(hd + bd * 0.52 + side * 0.035 * s, (0.05, 0.05, 0.05))  # 자루 쪽 위아래를 둥글게 파 초승달 날로
        bite_b = R.ellipsoid(hd + bd * 0.24 + side * 0.035 * s, (0.05, 0.05, 0.05))
        P.append((lambda p, f=plate, a=bite_a, b=bite_b: np.maximum(f(p), -np.minimum(a(p), b(p))), m("blade"), "sword"))


def _upper(P, U, up_r, arms, pose):
    """대족장 윗몸(탄 모습·내린 모습 공용): 가슴 철판·금 허리띠·붉은 망토·늑대 털 깃, 뿔 투구, 가시 어깨, 도끼, 왼손 뿔나팔·두 손 깃대"""
    m = MATS.index
    P += [(R.box(U([0, 0, 0.58]), (0.145, 0.095, 0.13), up_r, 0.04), m("iron"), "torso"),  # 가슴 철판
          (R.box(U([0, 0, 0.455]), (0.135, 0.09, 0.028), up_r), m("gold"), "torso"),  # 금 허리띠
          (R.box(U([0, -0.105, 0.5]), (0.16, 0.022, 0.2), up_r, 0.02), m("red"), "torso"),  # 붉은 망토
          (R.ellipsoid(U([0, -0.02, 0.705]), (0.15, 0.13, 0.06)), m("pale"), "torso"),  # 늑대 털 깃
          (R.ellipsoid(U([0, 0.01, 0.79]), (0.12, 0.12, 0.12)), m("skin"), "head")]
    helm = R.ellipsoid(U([0, -0.01, 0.815]), (0.14, 0.135, 0.13))  # 투구: 얼굴 아래쪽(턱·엄니)은 드러낸다
    face = R.box(U([0, 0.1, 0.75]), (0.085, 0.1, 0.06), up_r)
    P += [(lambda p: np.maximum(helm(p), -face(p)), m("iron"), "head"),
          (R.ellipsoid(U([0, -0.01, 0.865]), (0.147, 0.142, 0.03)), m("gold"), "head"),  # 금 테
          (R.box(U([0, -0.03, 0.955]), (0.024, 0.1, 0.04), up_r, 0.01), m("red"), "head")]  # 붉은 볏
    if pose.get("roar"):
        P.append((R.box(U([0, 0.125, 0.735]), (0.055, 0.02, 0.04), up_r), m("dark"), "head"))  # 벌린 입
    for s in (-1, 1):
        a, b, c = U([0.11 * s, 0, 0.86]), U([0.26 * s, -0.01, 0.95]), U([0.3 * s, 0.03, 1.1])
        P += [(R.capsule(a, b, 0.045, 0.032), m("bone"), "head"), (R.capsule(b, c, 0.032, 0.008), m("bone"), "head"),  # 길게 휜 뿔
              (R.capsule(U([0.045 * s, 0.11, 0.725]), U([0.06 * s, 0.14, 0.8]), 0.018, 0.008), m("bone"), "head")]  # 큰 엄니
    for side, s in (("l", -1), ("r", 1)):
        sh, el, hd = arms[side]
        top = U(sh) + up_r @ np.array([0, 0, 0.03])
        P += [(R.ellipsoid(top, (0.11, 0.1, 0.075)), m("iron"), "torso"),  # 어깨 철판
              (R.capsule(top + up_r @ np.array([0.03 * s, 0, 0.05]), top + up_r @ np.array([0.1 * s, 0, 0.16]), 0.028, 0.006), m("bone"), "torso"),  # 어깨 가시
              (R.capsule(U(sh), U(el), 0.052), m("skin"), "arm"),
              (R.capsule(U(el), U(hd), 0.055, 0.045), m("iron"), "arm"),  # 쇠 팔 보호대. 손목 쪽을 손보다 가늘게: 굵기가 같으면 맞닿는 px이 걷기 프레임마다 바뀐다(H3)
              (R.ellipsoid(U(hd), (0.054, 0.054, 0.054)), m("leather"), "arm")]
    hl, hr = U(arms["l"][2]), U(arms["r"][2])
    if pose.get("pole") is None:
        _axe(P, hr, pose, up_r)
    else:  # 두 손에 쥔 깃대와 작은 깃발(전쟁 깃발 세우기). 도끼는 그리지 않는다
        mid = (hl + hr) / 2
        z = np.array([0, 0, 1.0])
        lo = np.array([mid[0], mid[1], 0.0]) if pose["pole"] else mid - z * 0.25
        hi = lo + z * 1.15 if pose["pole"] else mid + z * 0.8
        right, front = up_r @ np.array([1.0, 0, 0]), up_r @ np.array([0, 1.0, 0])
        P += [(R.capsule(lo, hi, 0.022), m("wood"), "sword"),
              (R.capsule(hi - z * 0.06 - right * 0.2, hi - z * 0.06 + right * 0.2, 0.018), m("wood"), "sword"),
              (R.box(hi - z * 0.3 + front * 0.03, (0.18, 0.012, 0.22), np.stack([right, front, z])), m("red"), "sword"),
              (R.box(hi - z * 0.1 + front * 0.034, (0.18, 0.014, 0.03), np.stack([right, front, z])), m("gold"), "sword"),
              (R.capsule(hi, hi + z * 0.1, 0.024, 0.004), m("bone"), "sword")]
    if pose.get("horn"):  # 왼손 뿔나팔: 손에서 앞·위·바깥으로 벌어진다
        d = up_r @ (np.array([-0.25, 0.75, 0.6]) / np.linalg.norm([-0.25, 0.75, 0.6]))
        P += [(R.capsule(hl - d * 0.04, hl + d * 0.24, 0.02, 0.062), m("bone"), "arm"),
              (R.capsule(hl + d * 0.225, hl + d * 0.25, 0.068), m("gold"), "arm")]


def foot(pose, bob_unit):
    """내린 대족장: 쇠 정강이의 두 다리로 선 대족장"""
    U, G, up_r, legs, arms = H.rig(pose, bob_unit)
    m = MATS.index
    P = []
    for side in "lr":
        hip, knee, ankle = legs[side]
        P += [(R.capsule(G(hip), G(knee), 0.06), m("leather"), "leg"), (R.capsule(G(knee), G(ankle), 0.058), m("iron"), "leg"),
              (R.ellipsoid(G(ankle + [0, 0.035, -0.005]), (0.05, 0.075, 0.035)), m("iron"), "leg")]
    P.append((R.box(U([0, 0.065, 0.4]), (0.085, 0.025, 0.1), up_r, 0.01), m("red"), "torso"))  # 붉은 앞자락
    _upper(P, U, up_r, arms, pose)
    return P


def _warwolf(pose, bob):
    """전쟁 늑대(rider.py의 늑대 몸): 짙은 털·붉은 눈, 쇠 이마 가리개와 뿔, 가시 목걸이, 붉은 안장 깔개. low만큼 몸을 낮춘다"""
    m = MATS.index
    low = pose["low"]
    drop = np.array([0, 0, -low])
    P = []

    def B(p):  # 몸통·꼬리: 대족장과 함께 정수 px만 오르내린다
        return np.asarray(p, float) + bob + drop

    stand = max(8.0, 2 * np.degrees(np.arccos(min(1.0, (0.3 - low) / 0.3))))  # 몸을 낮추면 무릎을 그만큼 굽힌다
    for sx in (-1, 1):  # 다리 넷. 발은 오르내리지 않는다
        for y, front in ((0.16, 1), (-0.2, -1)):
            pair = sx * front  # −1 왼앞·오른뒤, +1 오른앞·왼뒤
            lifted = pose["tuck"] != 0 and pair == pose["tuck"]
            a = -pair * pose["gait"] + (12 if lifted else 0)
            bend = 60 if lifted else stand
            hip = np.array([0.085 * sx, y, 0.3 - low])
            knee = hip + 0.15 * H.down(a + bend / 2)
            ft = knee + 0.15 * H.down(a - bend / 2)
            P += [(R.capsule(hip, knee, 0.052, 0.042), m("fur"), "leg"), (R.capsule(knee, ft, 0.04, 0.032), m("fur"), "leg"),
                  (R.ellipsoid(ft + [0, 0.03, 0.012], (0.038, 0.058, 0.028)), m("pale"), "leg")]
    tail = np.array([0.035, -0.49, 0.5])
    P += [(R.capsule(B([0, -0.22, 0.37]), B([0, 0.17, 0.39]), 0.12, 0.135), m("fur"), "torso"),  # 몸통: 가슴 쪽이 조금 굵다
          (R.ellipsoid(B([0, 0.21, 0.35]), (0.1, 0.085, 0.115)), m("pale"), "torso"),  # 밝은 가슴 털
          (R.capsule(B([0, -0.3, 0.4]), B(tail), 0.05, 0.042), m("fur"), "torso"),  # 굵은 꼬리
          (R.ellipsoid(B(tail + [0.005, -0.015, 0.0]), (0.045, 0.045, 0.05)), m("pale"), "torso"),  # 꼬리 끝
          (R.box(B([0, -0.04, 0.42]), (0.15, 0.1, 0.105), np.eye(3), 0.03), m("red"), "torso")]  # 붉은 안장 깔개
    reach = np.array([0, pose["lunge"], -0.3 * pose["lunge"]]) + bob + drop  # 물기: 머리를 앞·아래로 내민다

    def Hd(p):
        return np.asarray(p, float) + reach
    P += [(R.capsule(B([0, 0.2, 0.45]), Hd([0, 0.33, 0.56]), 0.09, 0.08), m("fur"), "head"),  # 목
          (R.ellipsoid(Hd([0, 0.27, 0.52]), (0.118, 0.05, 0.112)), m("iron"), "head"),  # 가시 목걸이
          (R.ellipsoid(Hd([0, 0.37, 0.58]), (0.095, 0.1, 0.09)), m("fur"), "head"),  # 머리통
          (R.capsule(Hd([0, 0.43, 0.565]), Hd([0, 0.56, 0.545]), 0.052, 0.038), m("fur"), "head"),  # 짧고 굵은 주둥이
          (R.ellipsoid(Hd([0, 0.575, 0.553]), (0.026, 0.02, 0.02)), m("nose"), "head"),
          (R.box(Hd([0, 0.43, 0.632]), (0.05, 0.085, 0.018), np.eye(3), 0.01), m("iron"), "head"),  # 쇠 이마 가리개
          (R.capsule(Hd([0, 0.4, 0.65]), Hd([0, 0.45, 0.76]), 0.022, 0.004), m("bone"), "head")]  # 이마 뿔
    for ang in (-70, 0, 70):  # 목걸이 가시 셋: 왼쪽·위·오른쪽
        t = np.radians(ang)
        out = np.array([np.sin(t), 0, np.cos(t)])
        P.append((R.capsule(Hd([0, 0.27, 0.52]) + out * 0.1, Hd([0, 0.27, 0.52]) + out * 0.185, 0.02, 0.004), m("bone"), "head"))
    hinge = np.array([0, 0.42, 0.535])  # 아래턱: 밝은 털, jaw도만큼 벌린다
    P.append((R.capsule(Hd(hinge), Hd(hinge + H.rx(pose["jaw"]) @ [0, 0.13, -0.01]), 0.04, 0.028), m("pale"), "head"))
    for s in (-1, 1):
        P.append((R.box(Hd([0.052 * s, 0.455, 0.605]), (0.02, 0.012, 0.016)), m("eye"), "head"))
        P.append((R.capsule(Hd([0.06 * s, 0.34, 0.65]), Hd([0.078 * s, 0.32, 0.82]), 0.04, 0.008), m("fur"), "head"))  # 곧게 선 귀
    return P


def rider(pose, bob_unit):
    """오크 대족장: 전쟁 늑대 등에 앉은 대족장. rider가 거짓이면 늑대만이고, roll도만큼 옆으로 눕는다(내린 뒤 쓰러진 늑대)"""
    m = MATS.index
    P = _warwolf(pose, np.array([0, 0, pose["bob"] * bob_unit / WOLF]))
    if pose["roll"]:  # 등 높이(0.3)를 축으로 모델 오른쪽으로 굴려 옆구리로 눕힌다. 다 누우면 몸통 가운데가 땅에서 0.14 위다
        f = np.radians(pose["roll"])
        rot = np.array([[np.cos(f), 0, np.sin(f)], [0, 1, 0], [-np.sin(f), 0, np.cos(f)]])
        pivot = np.array([0, 0, 0.3])
        rest = np.array([0, 0, 0.3 * np.cos(f) + 0.14 * np.sin(f)])
        P = [(lambda q, fn=fn: fn((q - rest) @ rot + pivot), mat, part) for fn, mat, part in P]
    P = [(lambda q, fn=fn: fn(q / WOLF) * WOLF, mat, part) for fn, mat, part in P]
    if not pose["rider"]:  # 쓰러진 늑대는 옆모습으로 돌려 놓는다(다리가 화면 반대쪽): 누운 자세는 남쪽 한 행만 구워서(H.save), 그대로면 화면 쪽으로 누워
        # 짧게 뭉치고, 다리가 화면 쪽이면 45° 내려다본 그림에서 선 늑대와 같아 보인다
        turn = np.array([[0, -1.0, 0], [1.0, 0, 0], [0, 0, 1.0]])
        return [(lambda q, fn=fn: fn(q @ turn), mat, part) for fn, mat, part in P]
    U, _, up_r, _, arms = H.rig(pose, bob_unit / SEAT)
    Q = []
    for s in (-1, 1):  # 다리는 늑대 옆구리를 감싸 내린다
        Q += [(R.capsule(U([0.075 * s, 0, 0.42]), U([0.17 * s, 0.1, 0.3]), 0.058), m("leather"), "torso"),
              (R.capsule(U([0.17 * s, 0.1, 0.3]), U([0.18 * s, 0.04, 0.16]), 0.055), m("iron"), "torso"),
              (R.ellipsoid(U([0.18 * s, 0.07, 0.14]), (0.05, 0.072, 0.035)), m("iron"), "torso")]
    _upper(Q, U, up_r, arms, pose)
    off = WOLF * np.array([0, -0.05, 0.48 - pose["low"]]) - SEAT * np.array([0, 0, 0.41])  # 대족장 골반(0, 0, 0.41)이 안장 위에 온다
    return P + [(lambda q, fn=fn: fn((q - off) / SEAT) * SEAT, mat, part) for fn, mat, part in Q]


def guard(pose, bob_unit):
    """대족장 근위대: 검은 철 온몸 갑옷, 닫힌 투구의 붉은 눈 틈과 붉은 볏, 왼팔 큰 방패, 오른손 미늘창"""
    U, G, up_r, legs, arms = H.rig(pose, bob_unit)
    m = MATS.index
    P = []
    for side in "lr":
        hip, knee, ankle = legs[side]
        P += [(R.capsule(G(hip), G(knee), 0.06), m("black"), "leg"), (R.capsule(G(knee), G(ankle), 0.056), m("black"), "leg"),
              (R.ellipsoid(G(ankle + [0, 0.035, -0.005]), (0.05, 0.074, 0.035)), m("black"), "leg")]
    P += [(R.box(U([0, 0, 0.58]), (0.145, 0.095, 0.13), up_r, 0.04), m("black"), "torso"),  # 가슴 철판
          (R.box(U([0, 0, 0.455]), (0.135, 0.09, 0.026), up_r), m("gold"), "torso"),  # 금 허리띠
          (R.box(U([0, 0.065, 0.4]), (0.08, 0.025, 0.09), up_r, 0.01), m("red"), "torso"),  # 붉은 앞자락
          (R.box(U([0, -0.105, 0.53]), (0.15, 0.02, 0.16), up_r, 0.02), m("red"), "torso"),  # 짧은 붉은 망토
          (R.ellipsoid(U([0, -0.005, 0.815]), (0.14, 0.135, 0.135)), m("black"), "head"),  # 닫힌 투구
          (R.ellipsoid(U([0, -0.005, 0.87]), (0.146, 0.141, 0.026)), m("gold"), "head"),  # 금 테
          (R.box(U([0, 0.118, 0.8]), (0.09, 0.022, 0.02), up_r), m("dark"), "head"),  # 눈 틈
          (R.box(U([0, -0.02, 0.965]), (0.024, 0.11, 0.05), up_r, 0.01), m("red"), "head")]  # 붉은 볏
    for s in (-1, 1):
        P.append((R.box(U([0.042 * s, 0.136, 0.8]), (0.02, 0.012, 0.013), up_r), m("eye"), "head"))  # 붉은 눈
    for side in "lr":
        sh, el, hd = arms[side]
        P += [(R.ellipsoid(U(sh) + up_r @ np.array([0, 0, 0.02]), (0.105, 0.095, 0.072)), m("black"), "torso"),
              (R.capsule(U(sh), U(el), 0.052), m("black"), "arm"), (R.capsule(U(el), U(hd), 0.05), m("black"), "arm"),
              (R.ellipsoid(U(hd), (0.048, 0.048, 0.048)), m("leather"), "arm")]
    hd = U(arms["r"][2])
    bd, side, third = H.blade_axes(pose, up_r)
    P += [(R.capsule(hd - bd * 0.32, hd + bd * 0.62, 0.018), m("wood"), "sword"),  # 미늘창 자루
          (R.capsule(hd + bd * 0.62, hd + bd * 0.78, 0.028, 0.004), m("blade"), "sword"),  # 창끝
          (R.box(hd + bd * 0.53 + side * 0.07, (0.06, 0.075, 0.012), np.stack([side, bd, third]), 0.01), m("blade"), "sword")]  # 도끼날
    _, el_l, hd_l = arms["l"]
    n = up_r @ (np.array([-0.4, 1.0, 0]) / np.linalg.norm([-0.4, 1.0, 0]))  # 방패 앞면: 앞·왼쪽
    zz = up_r @ np.array([0, 0, 1.0])
    ax = np.stack([zz, n, np.cross(zz, n)])
    at = U((el_l + hd_l) / 2) + n * 0.04 - zz * 0.03
    P += [(R.box(at, (0.215, 0.024, 0.13), ax, 0.02), m("black"), "shield"),  # 큰 방패
          (R.box(at + zz * 0.17 + n * 0.006, (0.03, 0.024, 0.13), ax), m("gold"), "shield"),  # 금 띠
          (R.ellipsoid(at + n * 0.03 - zz * 0.02, (0.05, 0.05, 0.05)), m("gold"), "shield")]  # 금 돌기
    return P


def banner(pose, _bob_unit):
    """전쟁 깃발: 돌무더기에 꽂은 장대, 가로대에 건 붉은 천(금 윗단·해골 문양·두 갈래 끝), 꼭대기의 뼈 뿔. sway만큼 천 아래쪽이 옆으로 쏠린다"""
    m = MATS.index
    w = pose["sway"]
    cloth = np.eye(3)
    P = [(R.ellipsoid([0, 0, 0.03], (0.2, 0.17, 0.075)), m("iron"), "torso"),  # 돌무더기
         (R.ellipsoid([0.13, 0.08, 0.05], (0.075, 0.07, 0.06)), m("black"), "torso"),
         (R.ellipsoid([-0.12, 0.09, 0.05], (0.06, 0.055, 0.055)), m("bone"), "torso"),  # 발치의 해골
         (R.capsule([0, 0, 0], [0, 0, 1.95], 0.035), m("wood"), "torso"),  # 장대
         (R.capsule([-0.36, 0, 1.74], [0.36, 0, 1.74], 0.028), m("wood"), "torso"),  # 가로대
         (R.box([0, 0.035, 1.67], (0.31, 0.016, 0.035), cloth), m("gold"), "torso"),  # 금 윗단
         (R.box([0.006 * w, 0.03, 1.38], (0.3, 0.012, 0.27), cloth), m("red"), "torso"),  # 천 위쪽
         (R.box([0.02 * w, 0.03, 1.0], (0.3, 0.012, 0.13), cloth), m("red"), "torso"),  # 천 아래쪽
         (R.ellipsoid([0.008 * w, 0.045, 1.36], (0.13, 0.02, 0.13)), m("bone"), "head"),  # 해골 문양
         (R.box([0.01 * w, 0.045, 1.2], (0.065, 0.016, 0.045), cloth), m("bone"), "head"),
         (R.capsule([0, 0, 1.95], [0, 0, 2.14], 0.032, 0.005), m("bone"), "torso")]  # 꼭대기 창끝
    for s in (-1, 1):
        P += [(R.box([0.2 * s + 0.045 * w, 0.03, 0.72], (0.1, 0.012, 0.16), cloth), m("red"), "torso"),  # 두 갈래 끝
              (R.box([0.05 * s + 0.008 * w, 0.062, 1.39], (0.034, 0.008, 0.04), cloth), m("dark"), "head"),  # 눈구멍
              (R.capsule([0, 0, 1.9], [0.19 * s, 0, 2.06], 0.03, 0.008), m("bone"), "torso")]  # 꼭대기 뿔
    return P


# 종류 → (그림 폴더, 형체, 크기 배율, 맞춤 폭 span, 자세들). 정지·걷기와 스킬 자세로 캔버스를 맞춘다(스킬 자세는 치켜든 도끼·깃대가 잘리지 않게).
# 공격·쓰러짐은 2배 캔버스로 따로 굽는다(H.save). 대족장 둘은 장갑 오크·늑대 기수의 2배 몸이다(빌린 그림을 2배로 키워 그리던 크기 그대로)
KINDS = {"warchief": ("warchief", rider, 2.0, 8.0,
                      {"idle": [RIDE], "walk": RIDE_WALK, "attack": RIDE_ATTACK, "charge": RIDE_CHARGE, "order": RIDE_ORDER, "aim": RIDE_AIM, "fall": RIDE_FALL}),
         "warchief_foot": ("warchief_foot", foot, 2.2, 8.0,
                           {"idle": [FOOT], "walk": H.WALK, "attack": H.ATTACK, "horn": FOOT_HORN, "banner": FOOT_BANNER, "roar": FOOT_ROAR, "verdict": FOOT_VERDICT, "fall": H.FALL}),
         "warguard": ("warguard", guard, 1.25, 5.0, {"idle": [GUARD], "walk": GUARD_WALK, "attack": H.ATTACK, "fall": H.FALL}),
         "warbanner": ("warbanner", banner, 1.4, 7.0, {"idle": [FLAG], "sway": FLAG_SWAY})}


def model(kind):
    return H.scaled(KINDS[kind][1], KINDS[kind][2])


def fits(kind):
    _, _, scale, span, anims = KINDS[kind]
    poses = [p for a, ps in anims.items() if a not in ("attack", "fall") for p in ps]
    return H.fits(TRIAL / kind, poses, model(kind), f"{TAG} {kind} s{scale}" + VERS.get(kind, ""), SIZES, span=span)


def bake(kind):
    """시트와 fit.json → art/trial/<종류>/. → 24px 맞춤"""
    out = TRIAL / kind
    out.mkdir(parents=True, exist_ok=True)
    fts = fits(kind)
    anims = KINDS[kind][4]
    for a in anims:
        H.save(a, a, 45, "D", "f24p", fts, model(kind), BASE, anims, out, PARTS)
    return fts[24]


def lint():
    """H5(팔레트·반투명·잘림)는 모든 시트, H3·H4(걷기 윗몸 고정·다리 다름)는 걷기 시트"""
    import types

    import lint as L
    pal = R.PALETTES["f24p"]
    for kind, (_, _, _, _, anims) in KINDS.items():
        out, c = TRIAL / kind, fits(kind)[24][2]
        for a in anims:
            n = 2 * c if a in ("attack", "fall") else c
            print(f"{kind} {a} H5:", L.h5(out / f"{a}_45_D_f24p_24.png", pal, n) or "통과")
        if "walk" in anims:
            L.use(types.SimpleNamespace(PARTS=PARTS))
            img, part = L.frames(out / "walk_45_D_f24p_24.png", c), L.frames(out / "parts" / "walk_45_D_f24p_24.png", c)
            bobs = [p["bob"] for p in anims["walk"]]
            rows = [(d, L.h3(img[r], part[r], bobs), L.h4(part[r])) for r, d in enumerate(R.DIRS)]
            print("  H3 (윗몸 변화, 다리 행 밖 변화):", " ".join(f"{d}{b}" for d, b, _ in rows))
            print("  H4 (머리 높이 같음, 다리 다름):", " ".join(f"{d}{'OK' if all(q) else q}" for d, _, q in rows))


def preview():
    """검수용 확대본 → art/trial/preview/warhost_24.png(크기 비교: 남·동·북·서 줄마다 장갑 오크·근위대·늑대 기수·오크 대족장·내린 대족장·깃발·오우거)와
    warhost_moves_24.png(걷기 2위상·공격·스킬 자세·누운 자세, 동쪽과 남쪽)"""
    from PIL import Image

    import ogre as G
    import preview as V
    import rider as RD
    import slime as S
    fts = {k: fits(k)[24] if (TRIAL / k / "idle_45_D_f24p_24.png").exists() else bake(k) for k in KINDS}  # 구운 시트가 있으면 다시 굽지 않는다(네 종류 약 5분)
    pv = TRIAL / "preview"
    rows = [0, list(R.DIRS).index("E"), list(R.DIRS).index("N"), list(R.DIRS).index("W")]

    def cell(folder, anim, c, row, col=0):
        n = c * (2 if anim in ("attack", "fall") else 1)
        return S.cells(folder / f"{anim}_45_D_f24p_24.png", n, row)[col]

    others = {"orc": (O.OUT, O.fits()[24]), "rider": (RD.OUT, RD.fits()[24]), "ogre": (G.OUT, G.fits()[24])}
    lines = []
    for r in rows:
        items = [(cell(others["orc"][0], "idle", others["orc"][1][2], r), others["orc"][1]),
                 (cell(TRIAL / "warguard", "idle", fts["warguard"][2], r), fts["warguard"]),
                 (cell(others["rider"][0], "idle", others["rider"][1][2], r), others["rider"][1]),
                 (cell(TRIAL / "warchief", "idle", fts["warchief"][2], r), fts["warchief"]),
                 (cell(TRIAL / "warchief_foot", "idle", fts["warchief_foot"][2], r), fts["warchief_foot"]),
                 (cell(TRIAL / "warbanner", "idle", fts["warbanner"][2], 0), fts["warbanner"]),
                 (cell(others["ogre"][0], "idle", others["ogre"][1][2], r), others["ogre"][1])]
        lines.append(V.up(S.lineup(items), 4))
    V.stack(lines, gap=8).save(pv / "warhost_24.png")
    lines = []
    for kind in ("warchief", "warchief_foot", "warguard", "warbanner"):
        c, anims = fts[kind][2], KINDS[kind][4]
        for r in ([0] if kind == "warbanner" else rows[:2]):
            frames = []
            for a, poses in anims.items():
                if a == "idle":
                    continue
                cols = [4] if a == "fall" else ([1] if a == "attack" else list(range(min(len(poses), 2))))
                for q in cols:
                    g = Image.new("RGBA", (2 * c, 2 * c), (0, 0, 0, 0))  # 2배 칸에 발밑을 맞춘다
                    g.alpha_composite(cell(TRIAL / kind, a, c, 0 if a == "fall" else r, q), (0, 0) if a in ("attack", "fall") else (c // 2, c // 2))
                    frames.append(g)
            lines.append(V.up(V.on(R.sheet(frames, len(frames), gap=2), pad=4), 3))
    V.stack(lines, gap=8).save(pv / "warhost_moves_24.png")
    print(pv / "warhost_24.png", pv / "warhost_moves_24.png")


if __name__ == "__main__":
    import sys
    if sys.argv[1:] == ["preview"]:
        preview()
    elif sys.argv[1:] == ["lint"]:
        lint()
    else:
        for k in KINDS:
            ppu, anc, c = bake(k)
            print(f"{k} ppu={ppu:.2f} anchor={anc} canvas={c}")
        print("ok")
