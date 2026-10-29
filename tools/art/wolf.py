# 2라운드 늑대 4종(늑대·도약 늑대·밤 늑대·알파 늑대)의 3D 형체와 스프라이트 굽기. 무장한 늑대 수인이다(사용자 2026-10-29 «동물이 아니라 무장한 수인»).
# 4종 공통으로 곧게 선 귀·짧고 굵은 주둥이·목 갈기·끝이 밝은 굵은 꼬리·가죽 허리띠를 두고, 종마다 실루엣 특징 하나를 크게 둔다
# (enemy_theme_research/wolf_beastman/05_proposal.md, 사용자 2026-10-29 D1~D8 권장안 수락). 뼈대·자세는 기사(hero.py) 것이다.
# 게임은 C 절충안으로 4방향·걷기 2위상·공격 키 포즈만 쓴다(atlas.py). 도약 늑대·알파는 웅크림, 알파는 뜀 한 장을 더 굽는다
# 사용: python tools/art/wolf.py [preview]  → art/trial/<종류>/, 확대본은 art/trial/preview/wolf_*. 검사: python tools/art/lint.py walk_45_D_f24p wolf
from pathlib import Path

import numpy as np

import hero as H
import render as R

TRIAL = Path(__file__).resolve().parents[2] / "art" / "trial"
# 종류 → 형체 손잡이. s 크기(무장한 전사라 코볼트 0.85배보다 조금 크게, 밤·알파는 몸 반지름 비례), gear 장비, squat 무릎 접기(도), splay 다리 벌림
KINDS = {"wolf": dict(s=0.95, gear="blade"),
         "leap_wolf": dict(s=0.95, gear="daggers", squat=45, splay=0.08, extra=("crouch",)),  # 30°·0.06은 동·서·북에서 «작고 마른 늑대»로 읽혔다(Gemini 10/29)
         "night_wolf": dict(s=1.05, gear="sickle"),
         "alpha_wolf": dict(s=1.7, gear="axe", extra=("crouch", "air"))}
MATS = ["fur", "pale", "nose", "eye", "armor", "belt", "steel", "wood", "mane", "scar"]
STEEL = ["262d3d", "56607a", "a4aec2", "d0d6e0", "d0d6e0"]
BELT = ["36170c", "45230d", "45230d", "724113", "724113"]  # 4종 공통 허리띠(씨족 표지)
# 재질 램프 [안쪽 외곽선, 음영 0~3](hero.ramp). 늑대 털은 흙 타일(684c3c)과 겹쳐 밝은 주둥이·가슴·갈기를 넓게 둔다(D8).
# 도약 늑대는 늑대와 회색조 명도가 같아 한 단계 밝혔다(D2). 밝은 칸(efb775)이 둘이면 맨살처럼 읽혀 하나만 둔다. 밤 늑대 털 맨 위 칸은 밤 덮개 아래 윗면 테다.
# 밤 늑대 두건·망토는 털보다 한 단계 어둡게, 밝은 털(꼬리 끝·턱·목)은 한 단계 밝게 둔다. 셋이 같은 램프면 몸·망토·귀가 한 덩어리였다(Gemini 10/29 2회차)
# 알파 털은 고블린 피부·오크 철 램프(잿빛)를 피해 짙은 회갈로, 철은 털보다 어둡게, 눈은 고블린·코볼트(efac28)를 피해 붉게 둔다(D5·D6)
COLORS = {"wolf": dict(fur=["2a1d0d", "392a1c", "684c3c", "927e6a", "927e6a"], pale=["392a1c", "927e6a", "a4aec2", "d0d6e0", "d0d6e0"],
                       eye=["151a26"] * 5, armor=["2a1d0d", "36170c", "45230d", "45230d", "724113"]),
          "leap_wolf": dict(fur=["36170c", "724113", "a56243", "a56243", "efb775"], pale=["724113", "a56243", "efd8a1", "efd8a1", "efd8a1"],
                            eye=["151a26"] * 5, armor=["2a1d0d", "392a1c", "392a1c", "684c3c", "684c3c"]),  # armor = 다리 감개
          "night_wolf": dict(fur=["151a26", "151a26", "262d3d", "3a4357", "56607a"], pale=["151a26", "262d3d", "3a4357", "56607a", "7a86a0"],
                             eye=["efac28", "efd8a1", "efd8a1", "efd8a1", "efd8a1"], armor=["151a26", "151a26", "151a26", "262d3d", "56607a"]),  # armor = 두건·망토. 맨 위 칸은 윗면 테
          "alpha_wolf": dict(fur=["2a1d0d", "392a1c", "392a1c", "684c3c", "927e6a"], pale=["392a1c", "927e6a", "a4aec2", "d0d6e0", "d0d6e0"],
                             eye=["9b1a0a", "ef3a0c", "ef3a0c", "ef3a0c", "ef3a0c"], armor=["151a26", "151a26", "262d3d", "3a4357", "3a4357"])}


def base(kind):
    c = COLORS[kind]
    return {"fur": c["fur"], "pale": c["pale"], "nose": ["151a26"] * 5, "eye": c["eye"], "armor": c["armor"], "belt": BELT,
            "steel": STEEL, "wood": H.BASE["wood"], "mane": ["56607a", "a4aec2", "d0d6e0", "d0d6e0", "d0d6e0"], "scar": ["efb775"] * 5}


PARTS = ["leg", "torso", "head", "arm", "weapon"]
SIZES = (24,)
TAG = f"m5 ppu{H.PPU24} wolfkin6"
LEAN = 5  # 오우거(6°)쯤. 고블린(12°)·코볼트(16°)의 사선을 피한다
# 정지·걷기·공격은 기사 자세에 숙임만 더한다. 칼·도끼는 기사 검처럼 바깥으로 눕혀 방향마다 몸 밖으로 나오게 든다
IDLE = dict(H.IDLE, lean=LEAN)
WALK = [dict(w, lean=LEAN) for w in H.WALK]
ATTACK = [dict(a, lean=a["lean"] + LEAN) for a in H.ATTACK]
# 도약 늑대 공격: 오른손 역수 단검 찌르기, 왼손은 뒤로. 밤 늑대 공격: 고개를 내밀어 물기(bite 앞으로 옮김, jaw 턱 벌림), 낫 든 손은 옆으로
STAB = [dict(H.POSE, lean=LEAN, sh_r=40, el_r=80, sh_l=-20, el_l=40),
        dict(H.POSE, lean=LEAN + 12, sh_r=85, el_r=5, ab_r=0.15, sh_l=-35, el_l=30, hip_r=14, knee_r=10, hip_l=-10, knee_l=10),
        dict(H.POSE, lean=LEAN + 4, sh_r=50, el_r=40, sh_l=-15, el_l=40)]
BITE = [dict(H.POSE, lean=LEAN - 4, jaw=10, sh_l=10, el_l=60, ab_l=0.5),
        dict(H.POSE, lean=LEAN + 18, bite=0.1, jaw=45, sh_l=20, el_l=40, ab_l=0.7, hip_r=14, knee_r=10, hip_l=-10, knee_l=10),
        dict(H.POSE, lean=LEAN + 6, bite=0.02, jaw=10, sh_l=10, el_l=60, ab_l=0.5)]
# 웅크림: 몸통은 세운 채 무릎을 더 접어 낮추고 팔을 뒤로 젖힌다(도약 늑대 성벽 앞 0.8초, 알파 덮치기 예고). 뜀: 몸을 펴고 다리를 아래로 뻗고,
# 도끼를 머리 위로 치켜든다. 팔을 앞으로 뻗은 낮은 뜀은 웅크림과 실루엣이 같았다(Gemini 10/29).
# 웅크림 숙임 25°·뜀 숙임 20°는 둘 다 대각선 막대로 읽혀 서로, 그리고 누운 자세와 헷갈렸다(Gemini 10/29 2회차)
CROUCH = dict(H.POSE, lean=LEAN, squat=55, sh_l=-40, el_l=30, sh_r=-40, el_r=30, ab_l=0.5, ab_r=0.5, sword=-60, sword_side=30)
AIR = dict(H.POSE, lean=-5, jaw=30, hip_l=-5, knee_l=5, hip_r=-20, knee_r=5, sh_l=160, el_l=10, sh_r=170, el_r=10, sword=-20, sword_side=10)
# 높이 드는 걸음: 통과 위상에서 든 발을 더 높이 든다(다리만, 윗몸 고정은 H3 그대로). 벌린 다리·망토 밑 다리는 남·북에서 발끝만 1px 까딱였다(Gemini 10/29 2회차)
WALK_HI = [dict(WALK[0], hip_r=30, hip_l=-26), dict(WALK[1], hip_l=35, knee_l=80),
           dict(WALK[2], hip_l=30, hip_r=-26), dict(WALK[3], hip_r=35, knee_r=80)]
ANIMS = {"idle": [IDLE], "walk": WALK, "attack": ATTACK, "fall": H.FALL, "crouch": [CROUCH], "air": [AIR]}
POSES = {"leap_wolf": dict(attack=STAB, walk=WALK_HI), "night_wolf": dict(attack=BITE, walk=WALK_HI)}  # 종류별로 바꾼 동작


def anims_of(kind):
    return dict(ANIMS, **POSES.get(kind, {}))


def kin(kind):
    """종류 하나의 늑대 수인 형체(크기 1 기준). 크기는 hero.scaled로 맞춘다"""
    k = dict(dict(squat=0, splay=0.0), **KINDS[kind])

    def model(pose, bob_unit):
        m = MATS.index
        p = dict(pose)
        sq = p.get("squat", 0) + k["squat"]
        for s in "lr":  # 무릎 접기: 허벅지를 앞으로, 정강이를 그 두 배 뒤로 꺾고 몸 전체를 내려 발을 땅에 둔다
            p["hip_" + s] += sq
            p["knee_" + s] += 2 * sq
        drop = 0.19 * (1 + np.cos(np.radians(4)) - np.cos(np.radians(sq)) - np.cos(np.radians(sq + 4)))
        U, G, up_r, legs, arms = H.rig(p, bob_unit)
        tail = np.array([0.09, -0.36, 0.14] if kind == "night_wolf" else [0.05, -0.26, 0.2])  # 밤 늑대는 망토 밑으로 꼬리 끝이 나오게 길게
        P = []
        for side, s in (("l", -1), ("r", 1)):
            hip, knee, ankle = legs[side]
            knee, ankle = knee + [s * k["splay"], 0, 0], ankle + [s * 1.5 * k["splay"], 0, 0]  # 다리 벌림(도약 늑대의 넓은 꼴)
            shin = "armor" if kind == "leap_wolf" else "fur"  # 도약 늑대 다리 감개
            P += [(R.capsule(G(hip), G(knee), 0.05), m("fur"), "leg"), (R.capsule(G(knee), G(ankle), 0.04), m(shin), "leg"),
                  (R.ellipsoid(G(ankle + [0, 0.04, -0.005]), (0.042, 0.075, 0.03)), m("fur"), "leg")]
        chest = (0.015, 0.105) if kind == "leap_wolf" else (0, 0.075)  # (앞으로 옮김, 앞뒤 반두께). 도약 늑대 0.075는 동·서에서 2~3px로 얇아 여우처럼 읽혔다(Gemini 10/29 2회차)
        P += [(R.box(U([0, chest[0], 0.57]), (0.12, chest[1], 0.12), up_r, 0.04), m("fur"), "torso"),
              (R.box(U([0, 0, 0.455]), (0.125, 0.08, 0.025), up_r), m("belt"), "torso"),
              (R.box(U([0, 0, 0.415]), (0.11, 0.07, 0.04), up_r, 0.02), m("fur"), "torso"),
              (R.capsule(U([0, -0.07, 0.43]), U(tail), 0.05, 0.045), m("fur"), "torso"),  # 굵은 꼬리. 조금 옆으로 늘어뜨린다
              (R.ellipsoid(U(tail + [0.005, -0.015, -0.03]), (0.045, 0.045, 0.05)), m("pale"), "torso")]  # 꼬리 끝
        if kind == "wolf":  # 가죽 흉갑
            P.append((R.box(U([0, 0.005, 0.585]), (0.13, 0.085, 0.1), up_r, 0.035), m("armor"), "torso"))
        if kind == "alpha_wolf":  # 어두운 철 흉갑. 어깨는 갈기가 덮는다
            P.append((R.box(U([0, 0.01, 0.57]), (0.135, 0.09, 0.11), up_r, 0.03), m("armor"), "torso"))
        if kind == "alpha_wolf":  # 목·어깨를 두른 흰 갈기. 등까지 덮으면 안장 무늬처럼 읽혔다(네발 시안)
            P += [(R.ellipsoid(U([0, -0.01, 0.69]), (0.21, 0.15, 0.1)), m("mane"), "torso"),
                  (R.ellipsoid(U([0, -0.04, 0.76]), (0.15, 0.12, 0.08)), m("mane"), "torso")]
        else:  # 목 갈기: 밝은 털 깃
            P.append((R.ellipsoid(U([0, 0.03, 0.68]), (0.12, 0.1, 0.06)), m("pale"), "torso"))
        if kind == "night_wolf":  # 등 뒤 망토: 어깨에서 아래로 퍼지는 원뿔의 뒤쪽 반. 정면은 열어 몸과 낫이 보인다
            cloak = H.local(U, up_r, lambda q: np.maximum(H.flare(q, 0.72, 0.25, 0.15, 0.24, depth=0.75), q[:, 1] - 0.02))
            P.append((cloak, m("armor"), "torso"))

        bite = up_r @ np.array([0, 1.0, -0.3]) * p.get("bite", 0.0)  # 물기: 머리를 앞·아래로 내민다

        def Hd(q):
            return U(q) + bite
        P += [(R.ellipsoid(Hd([0, 0.01, 0.79]), (0.12, 0.115, 0.105)), m("fur"), "head"),  # 머리통(비례 과장)
              (R.capsule(Hd([0, 0.06, 0.775]), Hd([0, 0.19, 0.76]), 0.055, 0.04), m("fur"), "head"),  # 짧고 굵은 주둥이(코볼트는 길고 가늘다)
              (R.ellipsoid(Hd([0, 0.2, 0.768]), (0.026, 0.02, 0.02)), m("nose"), "head")]
        hinge = np.array([0, 0.05, 0.745])  # 아래턱: 밝은 털, jaw도만큼 벌린다
        P.append((R.capsule(Hd(hinge), Hd(hinge + H.rx(p.get("jaw", 0)) @ [0, 0.13, -0.01]), 0.042, 0.03), m("pale"), "head"))
        for s in (-1, 1):
            # 밤 늑대는 두건 그늘 속 밝은 두 점이 특징이라 조금 크게, 사이를 벌린다. 0.05면 남쪽에서 두 눈이 붙어 외눈으로 읽혔고(Gemini 10/29 2회차), 폭 0.016이면 24px에서 사라졌다
            eye = (0.022, 0.012, 0.018) if kind == "night_wolf" else (0.02, 0.012, 0.016)
            ex = 0.062 if kind == "night_wolf" else 0.05
            P.append((R.box(Hd([ex * s, 0.105 if kind != "night_wolf" else 0.112, 0.82]), eye, up_r), m("eye"), "head"))  # 머리 겉면 밖으로. 0.085면 머리통에 묻혔다
            # 곧게 선 삼각 귀. 고블린(옆)·코볼트 뿔(뒤)·오크 뿔(바깥 위)과 방향으로 갈린다. 끝 0.99면 앞뒤에서 머리에 묻혔다.
            # 밤 늑대도 두건 밖으로 낸다(사용자 10/29, Gemini 판정 «귀·꼬리가 묻혀 수인으로 안 읽힘»)
            P.append((R.capsule(Hd([0.065 * s, -0.01, 0.86]), Hd([0.08 * s, -0.03, 1.08]), 0.042, 0.008), m("fur"), "head"))
        if kind == "alpha_wolf":  # 얼굴 왼쪽을 세로로 지나는 흉터
            P.append((R.box(Hd([-0.075, 0.07, 0.82]), (0.012, 0.03, 0.05), up_r), m("scar"), "head"))
        if kind == "night_wolf":  # 귀를 내놓는 두건. 얼굴 앞은 뚫려 주둥이와 눈이 나온다
            hood = R.ellipsoid(Hd([0, -0.015, 0.8]), (0.14, 0.14, 0.135))
            face = R.box(Hd([0, 0.13, 0.8]), (0.085, 0.09, 0.08), up_r)  # 위 45°에서 눈이 챙에 가리지 않게 구멍을 높인다
            P.append((lambda q: np.maximum(hood(q), -face(q)), m("armor"), "head"))

        for side in "lr":
            sh, el, hd = arms[side]
            P += [(R.capsule(U(sh), U(el), 0.042), m("fur"), "arm"), (R.capsule(U(el), U(hd), 0.04), m("fur"), "arm"),
                  (R.ellipsoid(U(hd), (0.045, 0.045, 0.045)), m("fur"), "arm")]
        P += weapon(k["gear"], p, U, up_r, arms, m)
        if drop:
            P = [(lambda q, f=f: f(q + [0, 0, drop]), mat, part) for f, mat, part in P]
        return P
    return H.scaled(model, k["s"])


def weapon(gear, pose, U, up_r, arms, m):
    """손에 든 무기 부품들"""
    hd = U(arms["r"][2])
    bd, side, third = H.blade_axes(pose, up_r)
    ax = np.stack([side, bd, third])
    if gear == "blade":  # 짧은 휜 칼: 곧은 날 뒤로 끝이 날 쪽(third)으로 휜다
        tip = (bd * np.cos(0.5) + third * np.sin(0.5))
        tx = np.stack([side, tip, np.cross(tip, side)])
        return [(R.capsule(hd - bd * 0.04, hd + bd * 0.02, 0.02), m("wood"), "weapon"),
                (R.box(hd + bd * 0.13, (0.016, 0.1, 0.03), ax), m("steel"), "weapon"),
                (R.box(hd + bd * 0.22 + tip * 0.06, (0.014, 0.065, 0.025), tx), m("steel"), "weapon")]
    if gear == "axe":  # 큰 도끼: 긴 자루 끝에 바깥·앞 사이로 나온 한쪽 날. 앞(third)으로만 내면 북쪽에서 몸에 가려 몽둥이로 보였다(Gemini 10/29)
        e = (side + third) / np.sqrt(2)
        ex = np.stack([np.cross(bd, e), bd, e])
        return [(R.capsule(hd - bd * 0.08, hd + bd * 0.42, 0.024), m("wood"), "weapon"),
                (R.box(hd + bd * 0.34 + e * 0.07, (0.016, 0.1, 0.075), ex, 0.01), m("steel"), "weapon")]
    out = []
    if gear == "daggers":  # 쌍단검 역수: 손에서 아래·뒤·바깥으로 날이 나와 몸 실루엣 밖으로 뻗는다. 날 0.09·바깥 0이면 손끝 점으로 뭉갰다(Gemini 10/29)
        for s, x in (("l", -1), ("r", 1)):
            h = U(arms[s][2])
            v = up_r @ (np.array([0.45 * x, -0.2, -0.85]) / np.linalg.norm([0.45, -0.2, -0.85]))  # 뒤로 -0.5면 동·서에서 날이 꼬리 끝과 나란히 붙었다(Gemini 10/29 2회차)
            sd = up_r @ np.array([1.0, 0, 0])
            sd = (sd - (sd @ v) * v) / np.linalg.norm(sd - (sd @ v) * v)
            out.append((R.box(h + v * 0.14, (0.014, 0.13, 0.028), np.stack([sd, v, np.cross(v, sd)])), m("steel"), "weapon"))
        return out
    if gear == "sickle":  # 왼손 짧은 낫: 아래로 든 자루 끝에서 바깥·위로 뻗은 날이 끝에서 아래로 꺾인다. 앞으로만 뻗으면 «ㄱ»자가 안 보였다(Gemini 10/29)
        # 날 0.14·꺾임 0.045는 2회차에도 «단검 끝 2px»로 읽혀 둘 다 늘렸다
        h = U(arms["l"][2])
        d = up_r @ np.array([0, 0.25, -0.97])
        end = h + d * 0.1
        o = up_r @ (np.array([-0.85, 0.25, 0.45]) / np.linalg.norm([-0.85, 0.25, 0.45]))
        hk = up_r @ (np.array([-0.3, 0.2, -0.93]) / np.linalg.norm([-0.3, 0.2, -0.93]))
        tip = end + o * 0.19
        return [(R.capsule(h - d * 0.02, end, 0.018), m("wood"), "weapon"),
                (R.box(end + o * 0.095, (0.014, 0.095, 0.024), frame(o, up_r @ [0, 1.0, 0])), m("steel"), "weapon"),
                (R.box(tip + hk * 0.06, (0.014, 0.065, 0.022), frame(hk, up_r @ [0, 1.0, 0])), m("steel"), "weapon")]
    return out


def frame(v, ref):
    """긴 축이 v인 상자 축 행렬. 첫 축은 ref를 v에 수직으로 맞춘 것이다"""
    a = ref - (ref @ v) * v
    a = a / np.linalg.norm(a)
    return np.stack([a, v, np.cross(v, a)])


def fits(kind, out=None):
    a = anims_of(kind)
    poses = [IDLE] + a["walk"] + [a[x][0] for x in KINDS[kind].get("extra", ())]
    return H.fits(out or TRIAL / kind, poses, kin(kind), f"{TAG} {kind} {KINDS[kind]}", SIZES, span=4.0)


def bake(kind, out=None):
    """종류 하나의 시트와 fit.json → out(기본 art/trial/<종류>/). → 24px 맞춤"""
    out = out or TRIAL / kind
    out.mkdir(parents=True, exist_ok=True)
    fts = fits(kind, out)
    for anim in ["idle", "walk", "attack", "fall"] + list(KINDS[kind].get("extra", ())):
        H.save(anim, anim, 45, "D", "f24p", fts, kin(kind), base(kind), anims_of(kind), out, PARTS)
    return fts[24]


def preview():
    """검수용 확대본 → art/trial/preview/wolf_*: 크기 비교(고블린·코볼트·오크·오우거 곁)와 회색조, 종류마다 4방향·동작, 밤 불빛 가장자리, 걷기 gif"""
    from PIL import Image, ImageOps

    import goblin as B
    import kobold as K
    import ogre as O
    import orc as C
    import preview as V
    import slime as S
    pv = TRIAL / "preview"
    fts = {k: bake(k) for k in KINDS}
    E = list(R.DIRS).index("E")

    def frame(k, anim, row=0, col=0):
        n = fts[k][2] * (2 if anim in ("attack", "fall") else 1)
        return S.cells(TRIAL / k / f"{anim}_45_D_f24p_24.png", n, row)[col]

    others = [(S.idle(M.OUT, M.fits()[24][2]), M.fits()[24]) for M in (B, K, C, O)]
    rows = []
    for d in (0, E, 4):  # 남·동·북
        line = S.lineup([(frame(k, "idle", d), f) for k, f in fts.items()] + others)
        rows += [V.up(line, 5), V.up(ImageOps.grayscale(line.convert("RGB")).convert("RGBA"), 5)]
    V.stack(rows, gap=8).save(pv / "wolf_sizes_24.png")
    # 종류마다 한 줄: 정지 S·E·N·W, 걷기 2위상(E), 공격 타격(E), 누운 자세, 웅크림·뜀(E). 그 종류의 2배 칸에 발밑을 맞춰 넣고 빈 테두리는 자른다
    rows = []
    for k, f in fts.items():
        n, fr = f[2], []
        cells = [("idle", d, 0) for d in (0, E, 4, 6)] + [("walk", E, 0), ("walk", E, 1), ("attack", E, 1), ("fall", 0, 4)]
        cells += [(a, E, 0) for a in KINDS[k].get("extra", ())]
        for anim, row, col in cells:
            g = Image.new("RGBA", (2 * n, 2 * n), (0, 0, 0, 0))
            g.alpha_composite(frame(k, anim, row, col), (0, 0) if anim in ("attack", "fall") else (n // 2, n // 2))
            fr.append(g)
        x0, y0, x1, y1 = zip(*[g.getbbox() for g in fr])
        rows.append(V.up(V.on(R.sheet([g.crop((min(x0) - 1, min(y0) - 1, max(x1) + 1, max(y1) + 1)) for g in fr], len(fr), gap=3), pad=2), 6))
    V.stack(rows, gap=6).save(pv / "wolf_poses_24.png")
    # 밤: 불빛 가장자리(덮개 S212의 4단계 가운데 반쯤 밝은 칸)에서 어둠 0.5·1. 덮개 색 0b1030, 불투명도 0.85 × 어둠 × 0.5
    line = S.lineup([(frame(k, "idle", 0), f) for k, f in fts.items()] + others[:2])
    night = [line]
    for dark in (0.5, 1.0):
        night.append(Image.alpha_composite(line, Image.new("RGBA", line.size, (0x0b, 0x10, 0x30, round(255 * 0.85 * dark * 0.5)))))
    V.up(V.stack(night, gap=4), 5).save(pv / "wolf_night_24.png")
    # 걷기 gif: 종류마다 한 줄, 4방향(S·E·N·W). 초당 8(S172)
    c = max(f[2] for f in fts.values())
    frames = []
    for q in range(2):
        rows = []
        for k, f in fts.items():
            n, r = f[2], []
            for d in (0, E, 4, 6):
                g = Image.new("RGBA", (c, c), (0, 0, 0, 0))
                g.alpha_composite(S.cells(TRIAL / k / "walk_45_D_f24p_24.png", n, d)[q], ((c - n) // 2, (c - n) // 2))
                r.append(g)
            rows.append(R.sheet(r, 4, gap=2))
        frames.append(V.up(V.on(V.stack(rows, gap=2, bg=V.FIELD), pad=4), 5))
    frames[0].save(pv / "wolf_walk.gif", save_all=True, append_images=frames[1:], duration=125, loop=0, disposal=2)
    print(*(pv / f"wolf_{s}" for s in ("sizes_24.png", "poses_24.png", "night_24.png", "walk.gif")))


if __name__ == "__main__":
    import sys
    if sys.argv[1:] == ["preview"]:
        preview()
        sys.exit()
    for kind in KINDS:
        ppu, anc, c = bake(kind)
        print(f"{kind} ppu={ppu:.2f} anchor={anc} canvas={c}")
    print("ok")
