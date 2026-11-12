# 새 용병 여덟(S355~S363)의 3D 형체와 스프라이트 굽기. 모두 아군이라 팀 색(청록 3c9f9c)이나 밝은 색 하나를 몸에 둔다.
#   방패병(shieldman): 병사(soldier.py) 몸에 쇠 투구·쇠미늘 위 청록 겉옷, 왼팔에 무릎부터 턱까지 가리는 큰 사각 방패(청록 면·쇠 테·금 돌기), 오른손 짧은 검.
#   창병(spearman): 병사 몸에 챙 넓은 쇠 모자·붉은 누비옷, 오른손 긴 창(정지·걷기는 곧게 세우고 공격은 앞으로 찌른다).
#   불·번개·얼음 마법사(fire_mage·thunder_mage·frost_mage): 이그니스(ignis.py)의 퍼지는 로브 자락과 두건, 세라피나(seraphina.py)의 지팡이 자세.
#     불은 주홍 로브·금 단·불 구슬, 번개는 남색 로브·금 단·노란 번개 구슬과 가지, 얼음은 옅은 회청 로브·푸른 단·얼음 결정이다(f24p에 보라가 없다).
#   사제(cleric): 상아 로브·붉은 영대(앞에 늘어뜨린 띠), 나무 지팡이 끝의 금 십자. 세라피나(금 지팡이·해 원반·베일)와 지팡이·머리로 가른다.
#   기병(cavalry): 늑대 기수(rider.py) 틀로 갈색 말 등에 병사 윗몸(쇠 투구·청록 겉옷)을 앉히고, 오른손에 청록 깃발을 단 긴 창을 든다.
#     말 다리 넷은 대각선 짝이 함께 움직인다. 쓰러지면 말과 기병이 함께 옆으로 눕는다.
#   그물 사수(netter): 궁수(archer.py) 몸·활·화살통을 그대로 쓰고 두건·웃옷을 초록으로, 오른 허리에 감은 그물 밧줄 타래를 단다.
# 게임은 C 절충안으로 4방향·걷기 2위상·공격 키 포즈·누운 자세만 쓴다(atlas.py)
# 사용: python tools/art/troops.py [preview|lint] [종류...]  → art/trial/<종류>/
from pathlib import Path

import numpy as np

import archer as A
import hero as H
import ignis as I
import render as R
import seraphina as E
import soldier as D
import sylvia as S

TRIAL = Path(__file__).resolve().parents[2] / "art" / "trial"
# 값이 hex 하나면 자동 램프, 5개 목록이면 손 램프(안쪽 외곽선, 음영 0~3. hero.ramp). 모두 f24p 팔레트 색이다
BASE = {"skin": H.BASE["skin"], "hair": H.BASE["hair"], "leather": "70462a", "trouser": D.BASE["trouser"],
        "steel": H.BASE["steel"], "blade": H.BASE["blade"], "wood": H.BASE["wood"],
        "team": H.BASE["cloth"],  # 아군 팀 색: 방패병·기병의 겉옷·방패·깃발
        "gold": E.BASE["gold"],
        "red": ["300f0a", "550f0a", "9b1a0a", "9b1a0a", "ef3a0c"],  # 창병 누비옷·사제 영대
        "fire": I.BASE["robe"], "char": I.BASE["char"], "flame": I.BASE["flame"], "flare": I.BASE["flare"],
        "storm": ["151a26", "262d3d", "3a4357", "56607a", "7a86a0"],  # 번개마법사 남색 로브
        "spark": ["ab5c1c", "efac28", "efac28", "efd8a1", "efd8a1"],  # 노란 번개 구슬·가지
        "snow": ["3a4357", "7a86a0", "a4aec2", "a4aec2", "d0d6e0"],  # 얼음 마법사 옅은 로브
        "ice": I.BASE["frost"],  # 얼음 결정·단
        "ivory": E.BASE["ivory"],  # 사제 로브
        "green": ["1f240a", "183f39", "2d472d", "39571c", "39571c"],  # 그물 사수 두건·웃옷
        "rope": ["45230d", "ab5c1c", "efb775", "efb775", "efd8a1"],  # 그물 밧줄
        "silver": S.BASE["silver"], "string": S.BASE["string"], "bowwood": S.BASE["wood"],
        "horse": ["2a1d0d", "45230d", "724113", "a56243", "a56243"],  # 말 털
        "mane": ["151a26", "2a1d0d", "392a1c", "392a1c", "684c3c"]}  # 갈기·꼬리·발굽
MATS = list(BASE)
PARTS = H.PARTS  # leg·torso·head·arm·sword·shield. 지팡이·창·구슬은 sword, 방패·활은 shield
SIZES = (24,)
TAG = f"m5 ppu{H.PPU24} troops1"

# ── 자세 ──
SPEAR = dict(sword=0, sword_side=10)  # 창을 몸 옆에 곧게 세운다
SPEAR_IDLE = dict(H.IDLE, **SPEAR)
SPEAR_WALK = [dict(w, **SPEAR) for w in H.WALK]
SPEAR_ATTACK = [dict(H.POSE, sh_r=35, el_r=75, sword=80, sword_side=5, lean=-4),  # 당김
                dict(H.POSE, sh_r=80, el_r=5, sword=90, sword_side=0, lean=12, hip_r=14, knee_r=10, hip_l=-10, knee_l=10),  # 찌름(타격 프레임)
                dict(H.POSE, sh_r=55, el_r=30, sword=85, sword_side=0, lean=5)]
SPEAR_FALL = H.FALL[:2] + [dict(f, spear=0) for f in H.FALL[2:]]  # 쓰러지며 창을 놓친다
MAGE_FALL = [dict(f, sun=0) for f in E.FALL]  # 지팡이 끝 구슬은 쓰러지면 꺼진다(지팡이는 세라피나처럼 놓친다)
SEAT = 0.85  # 탄 기병의 크기: 말과 한 몸으로 읽히게 조금 작게(rider.py SEAT 0.9)
RIDE = dict(H.IDLE, sh_l=45, el_l=45, ab_l=0.1, sword=35, sword_side=12, gait=0, tuck=0)  # 왼손은 고삐, 오른손 창은 앞·위로 세운다
RIDE_WALK = [dict(RIDE, gait=24), dict(RIDE, tuck=1, bob=1), dict(RIDE, gait=-24), dict(RIDE, tuck=-1, bob=1)]  # rider.py와 같은 걸음
RIDE_ATTACK = [dict(RIDE, sh_r=60, el_r=50, sword=70, sword_side=4, lean=-4, gait=10),  # 창을 낮춘다
               dict(RIDE, sh_r=80, el_r=5, sword=92, sword_side=0, lean=10, gait=-14),  # 찌름(타격 프레임)
               dict(RIDE, sh_r=70, el_r=25, sword=80, sword_side=4, lean=4, gait=0)]
RIDE_FALL = [dict(RIDE, fall=f, gait=g) for f, g in ((15, 10), (35, 20), (55, 24), (75, 24), (88, 24))]  # 말과 함께 옆으로 눕는다


def _man(pose, bob_unit, coat, sleeve=None, boots="leather"):
    """병사·궁수 계열 몸: 바지·장화 다리, coat 웃옷, 맨머리·머리카락, coat 소매(sleeve가 있으면 아래팔)·맨손. → (부품, U, up_r, arms)"""
    U, G, up_r, legs, arms = H.rig(pose, bob_unit)
    m = MATS.index
    P = []
    for side in "lr":
        hip, knee, ankle = legs[side]
        P += [(R.capsule(G(hip), G(knee), 0.052), m("trouser"), "leg"), (R.capsule(G(knee), G(ankle), 0.048), m(boots), "leg"),
              (R.ellipsoid(G(ankle + [0, 0.035, -0.005]), (0.042, 0.068, 0.032)), m(boots), "leg")]
    P += [(R.box(U([0, 0, 0.575]), (0.12, 0.075, 0.12), up_r, 0.035), m(coat), "torso"),
          (R.box(U([0, 0, 0.455]), (0.125, 0.08, 0.022), up_r), m("leather"), "torso"),  # 허리띠
          (R.box(U([0, 0, 0.415]), (0.11, 0.07, 0.04), up_r, 0.02), m(coat), "torso"),
          (R.ellipsoid(U([0, 0, 0.80]), (0.125, 0.12, 0.13)), m("skin"), "head"),
          (R.ellipsoid(U([0, -0.03, 0.78]), (0.12, 0.11, 0.11)), m("hair"), "head")]
    for side in "lr":
        sh, el, hd = arms[side]
        P += [(R.ellipsoid(U(sh), (0.065, 0.065, 0.05)), m(coat), "torso"), (R.capsule(U(sh), U(el), 0.042), m(coat), "arm"),
              (R.capsule(U(el), U(hd), 0.04), m(sleeve or coat), "arm"), (R.ellipsoid(U(hd), (0.04, 0.04, 0.04)), m("skin"), "arm")]
    return P, U, up_r, arms


def _helm(U, up_r, brim=0.0):
    """쇠 투구: 눈썹 위만 덮는다. brim이 있으면 그만큼 넓은 챙(창병의 챙 넓은 모자)"""
    m = MATS.index
    cap = R.ellipsoid(U([0, -0.005, 0.825]), (0.137, 0.132, 0.125))
    cut_p, cut_n = U([0, 0, 0.83]), up_r @ [0, 0.3, 1]
    P = [(lambda p: np.maximum(cap(p), -((p - cut_p) @ cut_n)), m("steel"), "head")]
    if brim:
        zz = up_r @ np.array([0, 0, 1.0])
        c = U([0, 0, 0.845])
        P.append((lambda p: np.maximum(np.linalg.norm((p - c) - ((p - c) @ zz)[:, None] * zz, axis=1) - brim, np.abs((p - c) @ zz) - 0.014), m("steel"), "head"))
    return P


def shieldman(pose, bob_unit):
    """방패병: 쇠미늘 위 청록 겉옷, 쇠 투구, 오른손 짧은 검, 왼팔의 큰 사각 방패"""
    P, U, up_r, arms = _man(pose, bob_unit, "steel", "leather")
    m = MATS.index
    P += [(R.box(U([0, 0.004, 0.56]), (0.125, 0.08, 0.1), up_r, 0.03), m("team"), "torso")]  # 겉옷: 쇠미늘이 어깨·허리 아래로 보인다
    P += _helm(U, up_r)
    hd = U(arms["r"][2])
    bd, side, third = H.blade_axes(pose, up_r)
    ax = np.stack([side, bd, third])
    P += [(R.box(hd + bd * 0.045, (0.055, 0.015, 0.02), ax), m("steel"), "sword"),
          (R.box(hd + bd * 0.24, (0.03, 0.18, 0.03), ax), m("blade"), "sword"),
          (R.capsule(hd - bd * 0.05, hd, 0.022), m("leather"), "sword")]
    _, el_l, hd_l = arms["l"]
    n = up_r @ (np.array([-0.4, 1.0, 0]) / np.linalg.norm([-0.4, 1.0, 0]))  # 방패 앞면: 앞·왼쪽(soldier.py)
    zz = up_r @ np.array([0, 0, 1.0])
    axes = np.stack([np.cross(zz, n), n, zz])
    at = U((el_l + hd_l) / 2) + n * 0.05 - zz * 0.06
    P += [(R.box(at, (0.13, 0.02, 0.23), axes, 0.02), m("steel"), "shield"),  # 쇠 테
          (R.box(at + n * 0.008, (0.11, 0.02, 0.21), axes, 0.02), m("team"), "shield"),  # 청록 면
          (R.ellipsoid(at + n * 0.03, (0.045, 0.045, 0.045)), m("gold"), "shield")]  # 금 돌기
    return P


def spearman(pose, bob_unit):
    """창병: 붉은 누비옷, 챙 넓은 쇠 모자, 긴 창(나무 자루, 쇠 촉)"""
    P, U, up_r, arms = _man(pose, bob_unit, "red", "leather")
    m = MATS.index
    P += _helm(U, up_r, brim=0.17)
    if pose.get("spear", 1):
        hd = U(arms["r"][2])
        bd, _, _ = H.blade_axes(pose, up_r)
        P += [(R.capsule(hd - bd * 0.42, hd + bd * 0.72, 0.022), m("wood"), "sword"),
              (R.capsule(hd + bd * 0.7, hd + bd * 0.9, 0.04, 0.006), m("blade"), "sword")]  # 잎 모양 촉
    return P


def _robe(pose, bob_unit, robe, trim, hood=True):
    """마법사·사제 몸: 숯빛 바지·장화, robe 웃옷과 허리에서 발목까지 퍼지는 자락(ignis.py), trim 허리띠·단·소맷단, 두건, 맨손"""
    U, G, up_r, legs, arms = H.rig(pose, bob_unit)
    m = MATS.index

    def skirt(q, grow=0.0):
        return H.flare(q, 0.5, 0.04, 0.12, 0.2, grow)

    P = []
    for side in "lr":
        hip, knee, ankle = legs[side]
        P += [(R.capsule(G(hip), G(knee), 0.05), m("char"), "leg"), (R.capsule(G(knee), G(ankle), 0.046), m("char"), "leg"),
              (R.ellipsoid(G(ankle + [0, 0.035, -0.005]), (0.042, 0.068, 0.032)), m("char"), "leg")]
    P += [(R.box(U([0, 0, 0.575]), (0.115, 0.072, 0.12), up_r, 0.035), m(robe), "torso"),
          (R.box(U([0, 0, 0.48]), (0.135, 0.105, 0.022), up_r, 0.01), m(trim), "torso"),  # 허리띠: 자락보다 커야 보인다
          (H.local(U, up_r, lambda q: np.maximum(skirt(q), -skirt(q, -0.015))), m(robe), "torso"),
          (H.local(U, up_r, lambda q: np.maximum(skirt(q, 0.006), q[:, 2] - 0.08)), m(trim), "torso"),  # 아랫단
          (R.ellipsoid(U([0, 0, 0.80]), (0.12, 0.115, 0.125)), m("skin"), "head")]
    if hood:
        hd = R.ellipsoid(U([0, -0.015, 0.815]), (0.142, 0.137, 0.14))
        face = R.box(U([0, 0.1, 0.77]), (0.085, 0.1, 0.07), up_r)
        P.append((lambda p: np.maximum(hd(p), -face(p)), m(robe), "head"))
    else:
        P.append((R.ellipsoid(U([0, -0.03, 0.78]), (0.12, 0.11, 0.11)), m("hair"), "head"))
    for side in "lr":  # 종 소매와 소맷단
        sh, el, h = arms[side]
        P += [(R.ellipsoid(U(sh), (0.07, 0.07, 0.055)), m(robe), "torso"),
              (R.capsule(U(sh), U(el), 0.042), m(robe), "arm"), (R.capsule(U(el), U(el + 0.8 * (h - el)), 0.042, 0.07), m(robe), "arm"),
              (R.capsule(U(el + 0.7 * (h - el)), U(el + 0.8 * (h - el)), 0.072), m(trim), "arm"),
              (R.ellipsoid(U(h), (0.038, 0.038, 0.038)), m("skin"), "arm")]
    return P, U, up_r, arms


def _staff(pose, U, up_r, arms, shaft="wood"):
    """오른손 지팡이(seraphina.py와 같은 방향 값). → (부품, 끝 자리, 끝 쪽 방향, 구슬 배율). 쓰러지면 놓친다"""
    if not pose.get("staff", 1):
        return [], None, None, 0.0
    hd = U(arms["r"][2])
    bd, _, _ = H.blade_axes(pose, up_r)
    return [(R.capsule(hd - bd * 0.48, hd + bd * 0.6, 0.026), MATS.index(shaft), "sword")], hd + bd * 0.66, bd, pose.get("sun", 1)


def fire_mage(pose, bob_unit):
    """불마법사: 주홍 로브·금 단·두건, 지팡이 끝 불 구슬(겉 주황·속 노랑). 공격 발사 프레임에 커진다"""
    P, U, up_r, arms = _robe(pose, bob_unit, "fire", "gold")
    m = MATS.index
    S_, tip, _, k = _staff(pose, U, up_r, arms)
    P += S_
    if tip is not None and k:
        r = 0.065 * k
        P += [(R.ellipsoid(tip + up_r @ [0, 0, r * 0.4], (r, r, r)), m("flame"), "sword"), (R.ellipsoid(tip + up_r @ [0, 0.01, r * 0.5], (r * 0.6,) * 3), m("flare"), "sword")]
    return P


def thunder_mage(pose, bob_unit):
    """번개마법사: 남색 로브·금 단·두건, 지팡이 끝 노란 번개 구슬과 위·옆으로 튀는 번개 가지 둘"""
    P, U, up_r, arms = _robe(pose, bob_unit, "storm", "gold")
    m = MATS.index
    S_, tip, bd, k = _staff(pose, U, up_r, arms)
    P += S_
    if tip is not None and k:
        r = 0.055 * k
        c = tip + up_r @ [0, 0, r * 0.4]
        side = up_r @ np.array([1.0, 0, 0])
        zz = up_r @ np.array([0, 0, 1.0])
        P += [(R.ellipsoid(c, (r, r, r)), m("spark"), "sword"),
              (R.capsule(c + side * r, c + side * (r + 0.05) + zz * 0.06, 0.016, 0.008), m("spark"), "sword"),  # 꺾인 번개 가지
              (R.capsule(c + side * (r + 0.05) + zz * 0.06, c + side * (r + 0.02) + zz * 0.12, 0.012, 0.006), m("spark"), "sword"),
              (R.capsule(c - side * r, c - side * (r + 0.05) - zz * 0.02, 0.014, 0.006), m("spark"), "sword")]
    return P


def frost_mage(pose, bob_unit):
    """얼음 마법사: 옅은 회청 로브·푸른 단·두건, 지팡이 끝 길쭉한 얼음 결정"""
    P, U, up_r, arms = _robe(pose, bob_unit, "snow", "ice")
    m = MATS.index
    S_, tip, bd, k = _staff(pose, U, up_r, arms)
    P += S_
    if tip is not None and k:
        c = tip + bd * 0.05 * k
        P += [(R.capsule(c - bd * 0.06 * k, c + bd * 0.08 * k, 0.045 * k, 0.008), m("ice"), "sword"),
              (R.capsule(c - bd * 0.02, c + up_r @ np.array([0.07, 0, 0.03]) * k, 0.02 * k, 0.005), m("ice"), "sword")]  # 곁 결정
    return P


def cleric(pose, bob_unit):
    """사제: 상아 로브·금 단·두건, 앞에 늘어뜨린 붉은 영대, 나무 지팡이 끝의 금 십자"""
    P, U, up_r, arms = _robe(pose, bob_unit, "ivory", "gold")
    m = MATS.index
    for s in (-1, 1):  # 영대: 목에서 무릎까지 앞으로 늘어뜨린 두 띠
        P.append((R.box(U([0.045 * s, 0.085, 0.47]), (0.022, 0.012, 0.2), up_r, 0.005), m("red"), "torso"))
    S_, tip, bd, k = _staff(pose, U, up_r, arms)
    P += S_
    if tip is not None:
        side = up_r @ np.array([1.0, 0, 0])
        g = 1.0 + 0.4 * (k - 1)  # 공격 발사 프레임에 조금 커진다
        P += [(R.capsule(tip - bd * 0.02, tip + bd * 0.14 * g, 0.022 * g), m("gold"), "sword"),
              (R.capsule(tip + bd * 0.07 * g - side * 0.065 * g, tip + bd * 0.07 * g + side * 0.065 * g, 0.02 * g), m("gold"), "sword")]
    return P


def netter(pose, bob_unit):
    """그물 사수: 궁수(archer.py) 몸·활·화살통에 초록 두건·웃옷, 오른 허리에 감은 그물 밧줄 타래"""
    names = {"cloth": "green", "wood": "bowwood"}
    parts = {"bow": "shield", "arrow": "sword"}  # 궁수(sylvia.PARTS)의 활·화살 부위를 이 모듈의 부위로
    m = MATS.index
    P = [(f, m(names.get(A.MATS[k], A.MATS[k])), parts.get(part, part)) for f, k, part in A.archer(pose, bob_unit)]
    U, _, up_r, _, _ = H.rig(pose, bob_unit)
    c = U([0.17, -0.03, 0.44])  # 오른 허리 옆
    for i in range(8):  # 밧줄 타래: 옆을 보는 고리 하나를 마디 여덟으로
        a, b = np.radians(45 * i), np.radians(45 * (i + 1))
        p = c + up_r @ np.array([0.02, 0.1 * np.cos(a), 0.1 * np.sin(a)])
        q = c + up_r @ np.array([0.02, 0.1 * np.cos(b), 0.1 * np.sin(b)])
        P.append((R.capsule(p, q, 0.034), m("rope"), "torso"))
    P.append((R.ellipsoid(c + up_r @ np.array([0.04, 0, 0]), (0.035, 0.06, 0.06)), m("rope"), "torso"))  # 타래 가운데 매듭
    return P


def cavalry(pose, bob_unit):
    """기병: 갈색 말(갈기·꼬리·발굽 짙은 갈색, 청록 안장 깔개)에 앉은 병사 윗몸(쇠 투구·청록 겉옷), 청록 깃발을 단 긴 창.
    쓰러짐(fall)은 말과 기병이 함께 모델 오른쪽으로 눕는다(hero.rig의 쓰러짐과 같은 축)"""
    m = MATS.index
    bob = np.array([0, 0, pose["bob"] * bob_unit])
    P = []

    def B(p):  # 말 몸통·목·머리·꼬리: 기병과 함께 정수 px만 오르내린다
        return np.asarray(p, float) + bob

    for sx in (-1, 1):  # 다리 넷. 발굽은 오르내리지 않는다
        for y, front in ((0.17, 1), (-0.21, -1)):
            pair = sx * front
            lifted = pose["tuck"] != 0 and pair == pose["tuck"]
            a = -pair * pose["gait"] + (12 if lifted else 0)
            bend = 60 if lifted else 8
            hip = np.array([0.09 * sx, y, 0.42])
            knee = hip + 0.21 * H.down(a + bend / 2)
            foot = knee + 0.2 * H.down(a - bend / 2)
            P += [(R.capsule(hip, knee, 0.05, 0.036), m("horse"), "leg"), (R.capsule(knee, foot, 0.03, 0.026), m("horse"), "leg"),
                  (R.ellipsoid(foot + [0, 0.01, 0.012], (0.034, 0.042, 0.026)), m("mane"), "leg")]
    P += [(R.capsule(B([0, -0.26, 0.5]), B([0, 0.2, 0.52]), 0.13, 0.14), m("horse"), "torso"),  # 몸통
          (R.box(B([0, -0.03, 0.6]), (0.15, 0.13, 0.05), np.eye(3), 0.03), m("team"), "torso"),  # 안장 깔개
          (R.box(B([0, -0.03, 0.645]), (0.1, 0.09, 0.03), np.eye(3), 0.02), m("leather"), "torso"),  # 안장
          (R.capsule(B([0, -0.34, 0.56]), B([0, -0.43, 0.32]), 0.045, 0.03), m("mane"), "torso"),  # 꼬리
          (R.capsule(B([0, 0.2, 0.56]), B([0, 0.33, 0.78]), 0.085, 0.065), m("horse"), "head"),  # 목
          (R.capsule(B([0, 0.17, 0.66]), B([0, 0.3, 0.86]), 0.03, 0.03), m("mane"), "head"),  # 갈기
          (R.capsule(B([0, 0.34, 0.82]), B([0, 0.5, 0.72]), 0.065, 0.048), m("horse"), "head"),  # 머리
          (R.ellipsoid(B([0, 0.51, 0.715]), (0.04, 0.03, 0.035)), m("mane"), "head")]  # 콧등 끝
    for s in (-1, 1):
        P.append((R.capsule(B([0.035 * s, 0.32, 0.88]), B([0.045 * s, 0.31, 0.96]), 0.02, 0.006), m("horse"), "head"))  # 귀

    rp = dict(pose, fall=0)  # 기병 윗몸: 병사 윗몸을 SEAT배로 줄여 안장 위에 앉힌다. 쓰러짐은 아래에서 통째로 돌린다
    U, _, up_r, _, arms = H.rig(rp, bob_unit / SEAT)
    Q = [(R.box(U([0, 0, 0.575]), (0.12, 0.075, 0.12), up_r, 0.035), m("steel"), "torso"),
         (R.box(U([0, 0.004, 0.56]), (0.125, 0.08, 0.1), up_r, 0.03), m("team"), "torso"),  # 청록 겉옷
         (R.box(U([0, 0, 0.455]), (0.125, 0.08, 0.022), up_r), m("leather"), "torso"),
         (R.ellipsoid(U([0, 0, 0.80]), (0.125, 0.12, 0.13)), m("skin"), "head"),
         (R.ellipsoid(U([0, -0.03, 0.78]), (0.12, 0.11, 0.11)), m("hair"), "head")]
    Q += _helm(U, up_r)
    for s in (-1, 1):  # 말 옆구리를 감싸 내린 다리
        Q += [(R.capsule(U([0.075 * s, 0, 0.42]), U([0.18 * s, 0.1, 0.3]), 0.05), m("trouser"), "torso"),
              (R.capsule(U([0.18 * s, 0.1, 0.3]), U([0.19 * s, 0.04, 0.16]), 0.046), m("leather"), "torso"),
              (R.ellipsoid(U([0.19 * s, 0.07, 0.14]), (0.042, 0.066, 0.032)), m("leather"), "torso")]
    for side in "lr":
        sh, el, hd = arms[side]
        Q += [(R.ellipsoid(U(sh), (0.065, 0.065, 0.05)), m("steel"), "torso"), (R.capsule(U(sh), U(el), 0.042), m("steel"), "arm"),
              (R.capsule(U(el), U(hd), 0.04), m("leather"), "arm"), (R.ellipsoid(U(hd), (0.04, 0.04, 0.04)), m("leather"), "arm")]
    hd = U(arms["r"][2])
    bd, side, third = H.blade_axes(rp, up_r)
    Q += [(R.capsule(hd - bd * 0.35, hd + bd * 0.95, 0.022), m("wood"), "sword"),  # 긴 창
          (R.capsule(hd + bd * 0.93, hd + bd * 1.1, 0.036, 0.006), m("blade"), "sword"),
          (R.box(hd + bd * 0.82 + side * 0.05, (0.05, 0.07, 0.008), np.stack([side, bd, third])), m("team"), "sword")]  # 깃발
    off = np.array([0, -0.04, 0.66]) - SEAT * np.array([0, 0, 0.41])  # 기병 골반이 안장 위에 온다
    P += [(lambda q, f=f: f((q - off) / SEAT) * SEAT, mat, part) for f, mat, part in Q]
    f = np.radians(pose.get("fall", 0))
    if not f:
        return P
    rot = np.array([[np.cos(f), 0, np.sin(f)], [0, 1, 0], [-np.sin(f), 0, np.cos(f)]])  # hero.rig의 쓰러짐과 같은 축
    lift = np.array([0, 0, 0.14 * np.sin(f)])
    return [(lambda q, g=g: g((q - lift) @ rot), mat, part) for g, mat, part in P]


# 종류 → (형체, 크기 배율, 맞춤 폭 span, 자세들). 정지·걷기로 캔버스를 맞춘다. 공격·쓰러짐은 2배 캔버스로 따로 굽는다(H.save)
KINDS = {"shieldman": (shieldman, 1.0, 3.0, {"idle": [H.IDLE], "walk": H.WALK, "attack": H.ATTACK, "fall": H.FALL}),
         "fire_mage": (fire_mage, 1.0, 3.0, {"idle": [E.IDLE], "walk": E.WALK, "attack": E.ATTACK, "fall": MAGE_FALL}),
         "thunder_mage": (thunder_mage, 1.0, 3.0, {"idle": [E.IDLE], "walk": E.WALK, "attack": E.ATTACK, "fall": MAGE_FALL}),
         "spearman": (spearman, 1.0, 3.6, {"idle": [SPEAR_IDLE], "walk": SPEAR_WALK, "attack": SPEAR_ATTACK, "fall": SPEAR_FALL}),
         "frost_mage": (frost_mage, 1.0, 3.0, {"idle": [E.IDLE], "walk": E.WALK, "attack": E.ATTACK, "fall": MAGE_FALL}),
         "cleric": (cleric, 1.0, 3.0, {"idle": [E.IDLE], "walk": E.WALK, "attack": E.ATTACK, "fall": MAGE_FALL}),
         "cavalry": (cavalry, 1.0, 4.4, {"idle": [RIDE], "walk": RIDE_WALK, "attack": RIDE_ATTACK, "fall": RIDE_FALL}),
         "netter": (netter, 1.0, 3.0, {"idle": [S.IDLE], "walk": S.WALK, "attack": S.ATTACK, "fall": S.FALL})}


def model(kind):
    return H.scaled(KINDS[kind][0], KINDS[kind][1])


def fits(kind):
    _, scale, span, anims = KINDS[kind]
    poses = [p for a, ps in anims.items() if a not in ("attack", "fall") for p in ps]
    return H.fits(TRIAL / kind, poses, model(kind), f"{TAG} {kind} s{scale}", SIZES, span=span)


def bake(kind):
    """시트와 fit.json → art/trial/<종류>/. → 24px 맞춤"""
    out = TRIAL / kind
    out.mkdir(parents=True, exist_ok=True)
    fts = fits(kind)
    anims = KINDS[kind][3]
    for a in anims:
        H.save(a, a, 45, "D", "f24p", fts, model(kind), BASE, anims, out, PARTS)
    return fts[24]


def lint(kinds=None):
    """H5(팔레트·반투명·잘림)는 모든 시트, H3·H4(걷기 윗몸 고정·다리 다름)는 걷기 시트(trio.py와 같다)"""
    import types

    import lint as L
    pal = R.PALETTES["f24p"]
    for kind in kinds or KINDS:
        anims = KINDS[kind][3]
        out, c = TRIAL / kind, fits(kind)[24][2]
        for a in anims:
            n = 2 * c if a in ("attack", "fall") else c
            print(f"{kind} {a} H5:", L.h5(out / f"{a}_45_D_f24p_24.png", pal, n) or "통과")
        L.use(types.SimpleNamespace(PARTS=PARTS))
        img, part = L.frames(out / "walk_45_D_f24p_24.png", c), L.frames(out / "parts" / "walk_45_D_f24p_24.png", c)
        bobs = [p["bob"] for p in anims["walk"]]
        rows = [(d, L.h3(img[r], part[r], bobs), L.h4(part[r])) for r, d in enumerate(R.DIRS)]
        print("  H3 (윗몸 변화, 다리 행 밖 변화):", " ".join(f"{d}{b}" for d, b, _ in rows))
        print("  H4 (머리 높이 같음, 다리 다름):", " ".join(f"{d}{'OK' if all(q) else q}" for d, _, q in rows))


def preview():
    """검수용 확대본 → art/trial/preview/troops_24.png(남·동·북·서 줄마다 병사·궁수와 새 여덟의 정지)와
    troops_moves_24.png(종류마다 남쪽·동쪽 줄: 걷기 2위상·공격 타격·누운 자세)"""
    from PIL import Image

    import preview as V
    import slime as M
    fts = {k: fits(k)[24] if (TRIAL / k / "fall_45_D_f24p_24.png").exists() else bake(k) for k in KINDS}
    pv = TRIAL / "preview"
    rows = [0, list(R.DIRS).index("E"), list(R.DIRS).index("N"), list(R.DIRS).index("W")]

    def cell(folder, anim, c, row, col=0):
        n = c * (2 if anim in ("attack", "fall") else 1)
        return M.cells(folder / f"{anim}_45_D_f24p_24.png", n, row)[col]

    sol, arc = D.fits()[24], A.fits()[24]
    lines = [V.up(M.lineup([(cell(D.OUT, "idle", sol[2], r), sol), (cell(A.OUT, "idle", arc[2], r), arc)]
                           + [(cell(TRIAL / k, "idle", f[2], r), f) for k, f in fts.items()]), 6) for r in rows]
    V.stack(lines, gap=8).save(pv / "troops_24.png")
    lines = []
    for kind in KINDS:
        c = fts[kind][2]
        for r in rows[:2]:
            frames = []
            for a, cols in (("walk", [0, 1]), ("attack", [1]), ("fall", [4])):
                for q in cols:
                    g = Image.new("RGBA", (2 * c, 2 * c), (0, 0, 0, 0))  # 2배 칸에 발밑을 맞춘다
                    g.alpha_composite(cell(TRIAL / kind, a, c, 0 if a == "fall" else r, q), (0, 0) if a in ("attack", "fall") else (c // 2, c // 2))
                    frames.append(g)
            lines.append(V.up(V.on(R.sheet(frames, len(frames), gap=2), pad=4), 4))
    V.stack(lines, gap=8).save(pv / "troops_moves_24.png")
    print(pv / "troops_24.png", pv / "troops_moves_24.png")


if __name__ == "__main__":
    import sys
    args = sys.argv[1:]
    if args[:1] == ["preview"]:
        preview()
    elif args[:1] == ["lint"]:
        lint(args[1:] or None)
    else:
        for k in args or KINDS:
            ppu, anc, c = bake(k)
            print(f"{k} ppu={ppu:.2f} anchor={anc} canvas={c}")
        print("ok")
