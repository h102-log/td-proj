# 5라운드 오크 넷(I288)의 3D 형체와 스프라이트 굽기: 방패벽 오크(shield_orc)·광전사 오크(berserker)·전쟁 북 고수(drummer)·사슬 오크(chain_orc).
# 넷 다 장갑 오크(orc.py)의 몸(크기 1.1배, 회갈색 피부, 엄니)이고 든 것과 차림으로 가른다.
#   방패벽 오크: 뿔 투구·가슴 철판 그대로, 왼팔에 몸을 가리는 큰 나무 방패(쇠 띠·쇠 돌기), 오른손에 곧게 세운 창.
#   광전사 오크: 투구도 갑옷도 없는 맨몸, 붉은 볏 머리와 가슴의 붉은 칠, 두 손에 손도끼 하나씩.
#   전쟁 북 고수: 가죽 조끼와 누런 앞자락, 배 앞에 멘 큰 북(나무 통·흰 가죽), 두 손에 뼈 북채. 걷기 2위상과 정지 중 2열(sway)이 북채를 번갈아 내리친다.
#   사슬 오크: 가죽 두건(뿔 없음), 몸에 사선으로 두른 쇠사슬, 오른손에 늘어뜨린 갈고리. 스킬 자세 hook 2열(머리 위로 돌림 → 앞으로 던짐).
# 뼈대·자세는 기사(hero.py) 것이다. 게임은 C 절충안으로 4방향·걷기 2위상·공격 키 포즈만 쓴다(atlas.py)
# 사용: python tools/art/horde.py [preview]  → art/trial/<종류>/. 검사: python tools/art/horde.py lint
from pathlib import Path

import numpy as np

import hero as H
import orc as O
import render as R

TRIAL = Path(__file__).resolve().parents[2] / "art" / "trial"
BASE = {"skin": O.BASE["skin"], "iron": O.BASE["iron"], "tabard": O.BASE["tabard"], "blade": H.BASE["blade"], "leather": O.BASE["leather"], "horn": O.BASE["horn"],
        "wood": H.BASE["wood"], "hide": ["684c3c", "927e6a", "efd8a1", "efd8a1", "efd8a1"],  # 북 가죽·북채(뼈)
        "ochre": ["45230d", "ab5c1c", "efac28", "efac28", "efd8a1"],  # 북 고수의 누런 앞자락
        "paint": ["300f0a", "550f0a", "9b1a0a", "9b1a0a", "ef3a0c"],  # 광전사의 붉은 볏과 칠
        "chain": ["262d3d", "56607a", "a4aec2", "d0d6e0", "d0d6e0"]}  # 사슬: 갑옷 철 위에서 보이게 밝은 강철(늑대 무기와 같은 램프). 어두운 철은 갑옷에 묻혔다
MATS = list(BASE)
PARTS = ["leg", "torso", "head", "arm", "sword", "shield"]
SIZES = (24,)
SCALE = 1.1
TAG = f"m5 ppu{H.PPU24} horde1 s{SCALE}"
VERS = {"shield_orc": " pavise2", "berserker": " arms3", "chain_orc": " chain2"}  # 종류마다 형체를 바꾼 때 맞춤 꼬리표에 더하는 말(그 종류만 다시 맞춘다)

# ── 자세 ── 기사 자세에 더한 칸: beat 북채(0 오른손이 내리침, 1 왼손이 내리침), chain 갈고리 사슬(hang 늘어뜨림, whirl 머리 위로 돌림, throw 앞으로 던짐)
SPEAR = dict(sword=8, sword_side=20)  # 창을 곧게 세워 든다
WALL = dict(H.IDLE, **SPEAR)
WALL_WALK = [dict(w, **SPEAR) for w in H.WALK]
_TWIN = dict(sh_l=15, el_l=70, ab_l=0.4, ab_r=0.4, sword=5, sword_side=20, lean=6)  # 두 팔을 조금 벌려 도끼를 위로 세워 든다. 앞으로 조금 숙인다.
# 팔을 0.7만큼 벌리거나 도끼를 앞으로 35° 기울이면(화면에서는 위로 선 것과 앞으로 기운 것이 상쇄된다) 남·북에서 도끼가 수평이 되어 허수아비처럼 보였다
FURY = dict(H.IDLE, **_TWIN)
FURY_WALK = [dict(w, **_TWIN) for w in H.WALK]
FURY_ATTACK = [dict(H.ATTACK[0], sh_l=150, el_l=20, ab_l=0.35), dict(H.ATTACK[1], sh_l=75, el_l=5, ab_l=0.35, lean=18), dict(H.ATTACK[2], sh_l=45, el_l=35, ab_l=0.35)]  # 두 도끼를 함께 내려친다
_UP, _DOWN = (105, 55), (58, 52)  # 북채 든 팔(어깨, 팔꿈치): 치켜듦 / 내리침
_BEATS = [dict(sh_r=_DOWN[0], el_r=_DOWN[1], sh_l=_UP[0], el_l=_UP[1], ab_l=-0.35, ab_r=-0.35, beat=0),
          dict(sh_l=_DOWN[0], el_l=_DOWN[1], sh_r=_UP[0], el_r=_UP[1], ab_l=-0.35, ab_r=-0.35, beat=1)]
DRUM = dict(H.IDLE, **_BEATS[0])
DRUM_SWAY = [dict(H.IDLE, **b) for b in _BEATS]
DRUM_WALK = [dict(w, **_BEATS[k % 2]) for k, w in enumerate(H.WALK)]  # 걷기 2위상(접지·통과)이 북채를 번갈아 내리친다
HOOK = dict(H.IDLE, ab_r=0.35, chain="hang")
HOOK_WALK = [dict(w, ab_r=0.35, chain="hang") for w in H.WALK]
HOOK_CAST = [dict(H.POSE, sh_r=165, el_r=15, ab_r=0.3, lean=-6, sh_l=40, el_l=40, chain="whirl"),  # 갈고리를 머리 위로 돌린다
             dict(H.POSE, sh_r=85, el_r=5, ab_r=0.15, lean=12, sh_l=-10, el_l=30, hip_r=14, knee_r=10, hip_l=-10, knee_l=10, chain="throw")]  # 앞으로 던진다


def _legs(P, G, legs, thigh, shin, foot):
    m = MATS.index
    for side in "lr":
        hip, knee, ankle = legs[side]
        P += [(R.capsule(G(hip), G(knee), 0.058), m(thigh), "leg"), (R.capsule(G(knee), G(ankle), 0.055), m(shin), "leg"),
              (R.ellipsoid(G(ankle + [0, 0.035, -0.005]), (0.048, 0.072, 0.034)), m(foot), "leg")]


def _head(P, U, up_r, helm=True, horns=True):
    """오크 머리: 회갈 피부와 엄니. helm이면 뿔 투구(orc.py와 같다)"""
    m = MATS.index
    P.append((R.ellipsoid(U([0, 0.01, 0.79]), (0.12, 0.12, 0.12)), m("skin"), "head"))
    if helm:
        shell = R.ellipsoid(U([0, -0.01, 0.815]), (0.14, 0.135, 0.13))  # 투구: 얼굴 아래쪽(턱·엄니)은 드러낸다
        face = R.box(U([0, 0.1, 0.75]), (0.085, 0.1, 0.06), up_r)
        P.append((lambda p: np.maximum(shell(p), -face(p)), m("iron"), "head"))
    for s in (-1, 1):
        if horns:
            P.append((R.capsule(U([0.11 * s, 0, 0.86]), U([0.2 * s, 0.02, 0.99]), 0.035, 0.012), m("horn"), "head"))
        P.append((R.capsule(U([0.04 * s, 0.11, 0.73]), U([0.05 * s, 0.13, 0.78]), 0.014, 0.008), m("horn"), "head"))  # 엄니


def _arms(P, U, up_r, arms, plate=True, upper="skin", hand=0.05):
    m = MATS.index
    for side in "lr":
        sh, el, hd = arms[side]
        if plate:
            P.append((R.ellipsoid(U(sh) + up_r @ np.array([0, 0, 0.02]), (0.1, 0.09, 0.07)), m("iron"), "torso"))  # 어깨 철판
        P += [(R.capsule(U(sh), U(el), 0.05), m(upper), "arm"), (R.capsule(U(el), U(hd), 0.047, 0.043), m("skin"), "arm"),
              (R.ellipsoid(U(hd), (hand, hand, hand)), m("leather"), "arm")]  # 손목을 손보다 가늘게: 굵기가 같으면 맞닿는 px이 걷기 프레임마다 바뀐다(H3)


def _left_axes(pose, up_r):
    """왼손에 든 것의 방향: blade_axes를 좌우로 뒤집는다"""
    a, s = np.radians(pose["sword"]), np.radians(pose["sword_side"])
    bd = up_r @ np.array([-np.sin(s), np.sin(a) * np.cos(s), np.cos(a) * np.cos(s)])
    side = up_r @ np.array([-1.0, 0, 0])
    side = (side - (side @ bd) * bd) / np.linalg.norm(side - (side @ bd) * bd)
    return bd, side, np.cross(bd, side)


def wall(pose, bob_unit):
    """방패벽 오크: 장갑 오크 몸에 왼팔 큰 나무 방패, 오른손 창"""
    U, G, up_r, legs, arms = H.rig(pose, bob_unit)
    m = MATS.index
    P = []
    _legs(P, G, legs, "leather", "iron", "iron")
    P += [(R.box(U([0, 0, 0.58]), (0.14, 0.09, 0.13), up_r, 0.04), m("iron"), "torso"),  # 가슴 철판
          (R.box(U([0, 0.06, 0.4]), (0.08, 0.025, 0.1), up_r, 0.01), m("tabard"), "torso"),  # 붉은 앞자락
          (R.box(U([0, 0, 0.455]), (0.13, 0.085, 0.025), up_r), m("leather"), "torso")]
    _head(P, U, up_r)
    _arms(P, U, up_r, arms)
    hd = U(arms["r"][2])
    bd, side, third = H.blade_axes(pose, up_r)
    P += [(R.capsule(hd - bd * 0.3, hd + bd * 0.55, 0.017), m("wood"), "sword"),  # 창 자루
          (R.capsule(hd + bd * 0.55, hd + bd * 0.72, 0.03, 0.004), m("blade"), "sword")]  # 창날
    _, el_l, hd_l = arms["l"]
    n = up_r @ (np.array([-0.5, 1.0, 0]) / np.linalg.norm([-0.5, 1.0, 0]))  # 방패 앞면: 앞·왼쪽
    zz = up_r @ np.array([0, 0, 1.0])
    ax = np.stack([zz, n, np.cross(zz, n)])
    at = U((el_l + hd_l) / 2) + n * 0.06 - zz * 0.07
    P += [(R.box(at, (0.31, 0.026, 0.18), ax, 0.02), m("wood"), "shield"),  # 무릎에서 턱까지 가리는 큰 나무 방패
          (R.box(at + zz * 0.25 + n * 0.006, (0.03, 0.028, 0.182), ax), m("iron"), "shield"),  # 위 쇠 띠
          (R.box(at - zz * 0.25 + n * 0.006, (0.03, 0.028, 0.182), ax), m("iron"), "shield"),  # 아래 쇠 띠
          (R.ellipsoid(at + n * 0.03, (0.065, 0.065, 0.065)), m("iron"), "shield")]  # 쇠 돌기
    return P


def fury(pose, bob_unit):
    """광전사 오크: 맨몸에 붉은 볏과 가슴 칠, 두 손에 손도끼"""
    U, G, up_r, legs, arms = H.rig(pose, bob_unit)
    m = MATS.index
    P = []
    _legs(P, G, legs, "leather", "skin", "leather")
    P += [(R.box(U([0, 0, 0.58]), (0.14, 0.09, 0.13), up_r, 0.04), m("skin"), "torso"),  # 맨 가슴
          (R.box(U([0, 0.005, 0.63]), (0.144, 0.094, 0.022), up_r), m("paint"), "torso"),  # 가슴의 붉은 칠
          (R.box(U([0, 0.06, 0.4]), (0.08, 0.025, 0.1), up_r, 0.01), m("tabard"), "torso"),  # 붉은 앞자락
          (R.box(U([0, 0, 0.455]), (0.13, 0.085, 0.025), up_r), m("leather"), "torso")]
    _head(P, U, up_r, helm=False, horns=False)
    P.append((R.box(U([0, -0.02, 0.905]), (0.026, 0.11, 0.05), up_r, 0.012), m("paint"), "head"))  # 붉은 볏 머리
    _arms(P, U, up_r, arms, plate=False, hand=0.052)
    for side, axes in (("r", H.blade_axes(pose, up_r)), ("l", _left_axes(pose, up_r))):
        hd = U(arms[side][2])
        bd, out, third = axes
        P += [(R.capsule(hd - bd * 0.06, hd + bd * 0.26, 0.018), m("wood"), "sword"),  # 손도끼 자루
              (R.box(hd + bd * 0.21 + out * 0.07, (0.065, 0.07, 0.013), np.stack([out, bd, third]), 0.012), m("blade"), "sword")]  # 날은 바깥쪽
    return P


def _cyl(c, axis, r, h):
    """축 axis, 반지름 r, 반높이 h인 원통"""
    c, axis = np.asarray(c, float), np.asarray(axis, float)

    def f(p):
        q = p - c
        t = q @ axis
        return np.maximum(np.abs(t) - h, np.linalg.norm(q - t[:, None] * axis, axis=1) - r)
    return f


def drum(pose, bob_unit):
    """전쟁 북 고수: 가죽 조끼·누런 앞자락, 배 앞의 큰 북, 두 손의 뼈 북채"""
    U, G, up_r, legs, arms = H.rig(pose, bob_unit)
    m = MATS.index
    P = []
    _legs(P, G, legs, "leather", "iron", "iron")
    zz, front = up_r @ np.array([0, 0, 1.0]), up_r @ np.array([0, 1.0, 0])
    P += [(R.box(U([0, 0, 0.58]), (0.14, 0.09, 0.13), up_r, 0.04), m("leather"), "torso"),  # 가죽 조끼
          (R.box(U([0, 0.06, 0.4]), (0.08, 0.025, 0.1), up_r, 0.01), m("ochre"), "torso"),  # 누런 앞자락
          (R.box(U([0, 0, 0.455]), (0.13, 0.085, 0.025), up_r), m("ochre"), "torso")]
    _head(P, U, up_r)
    _arms(P, U, up_r, arms, plate=False, upper="leather")
    top = U([0, 0.2, 0.585])  # 북 윗면 가운데
    P += [(_cyl(top - zz * 0.085, zz, 0.14, 0.085), m("wood"), "torso"),  # 북통
          (_cyl(top - zz * 0.085, zz, 0.146, 0.018), m("iron"), "torso"),  # 가운데 쇠 띠
          (_cyl(top, zz, 0.128, 0.012), m("hide"), "torso")]  # 흰 가죽 윗면
    beat = pose.get("beat")
    for k, side in enumerate("rl"):
        hd = U(arms[side][2])
        if beat is None:  # 공격·쓰러짐: 오른손 북채는 휘두르는 쪽, 왼손 북채는 앞 아래로
            d = H.blade_axes(pose, up_r)[0] if side == "r" else (front * 0.8 - zz * 0.6)
        elif beat == k:  # 내리친 북채: 손에서 북 윗면 쪽으로
            d = top + (U(arms[side][0]) - U([0, 0, 0.655])) * 0.35 - hd
        else:  # 치켜든 북채: 위·앞으로
            d = zz * 0.85 + front * 0.5
        d = d / np.linalg.norm(d)
        P += [(R.capsule(hd - d * 0.03, hd + d * 0.15, 0.015), m("hide"), "sword"), (R.ellipsoid(hd + d * 0.16, (0.028, 0.028, 0.028)), m("hide"), "sword")]  # 뼈 북채와 둥근 끝
    return P


def _hook_tip(P, end, d, out):
    """갈고리: 사슬 끝에서 d 쪽으로 뻗다 out 쪽으로 휘어 되돌아온다"""
    m = MATS.index
    a, b = end + d * 0.09, end + d * 0.12 + out * 0.1
    P += [(R.capsule(end, a, 0.026), m("blade"), "sword"), (R.capsule(a, b, 0.026, 0.022), m("blade"), "sword"),
          (R.capsule(b, b - d * 0.1 + out * 0.03, 0.022, 0.005), m("blade"), "sword")]


def hook(pose, bob_unit):
    """사슬 오크: 가죽 두건, 몸에 사선으로 두른 쇠사슬, 오른손 갈고리 사슬"""
    U, G, up_r, legs, arms = H.rig(pose, bob_unit)
    m = MATS.index
    P = []
    _legs(P, G, legs, "leather", "iron", "iron")
    P += [(R.box(U([0, 0, 0.58]), (0.14, 0.09, 0.13), up_r, 0.04), m("iron"), "torso"),  # 가슴 철판
          (R.box(U([0, 0.06, 0.4]), (0.08, 0.025, 0.1), up_r, 0.01), m("tabard"), "torso"),  # 붉은 앞자락
          (R.box(U([0, 0, 0.455]), (0.13, 0.085, 0.025), up_r), m("leather"), "torso"),
          (R.capsule(U([-0.15, 0.09, 0.69]), U([0.13, 0.1, 0.47]), 0.04), m("chain"), "torso"),  # 사선으로 두른 사슬(앞)
          (R.capsule(U([-0.15, -0.09, 0.69]), U([0.13, -0.1, 0.47]), 0.04), m("chain"), "torso")]  # (뒤)
    _head(P, U, up_r, helm=False, horns=False)
    hood = R.ellipsoid(U([0, -0.015, 0.815]), (0.142, 0.14, 0.135))  # 가죽 두건: 얼굴은 드러낸다
    face = R.box(U([0, 0.1, 0.77]), (0.09, 0.1, 0.075), up_r)
    P.append((lambda p: np.maximum(hood(p), -face(p)), m("leather"), "head"))
    _arms(P, U, up_r, arms)
    hd = U(arms["r"][2])
    zz, front, right = up_r @ np.array([0, 0, 1.0]), up_r @ np.array([0, 1.0, 0]), up_r @ np.array([1.0, 0, 0])
    how = pose.get("chain")
    if how == "whirl":  # 머리 위에서 도는 사슬 고리와 갈고리
        c, r = hd + zz * 0.06 - right * 0.1, 0.2
        ring = [c + (right * np.cos(t) + front * np.sin(t)) * r for t in np.radians(np.arange(0, 360, 45))]
        for a, b in zip(ring, ring[1:]):  # 한 칸은 비워 둔다: 갈고리가 달린 끝
            P.append((R.capsule(a, b, 0.022), m("chain"), "sword"))
        _hook_tip(P, ring[-1], front, right)
    else:
        d, n = {"hang": (-zz, 0.16), "throw": (front, 0.34)}.get(how, (H.blade_axes(pose, up_r)[0], 0.22))  # 공격·쓰러짐: 휘두르는 쪽
        P.append((R.capsule(hd, hd + d * n, 0.022), m("chain"), "sword"))
        _hook_tip(P, hd + d * n, d, right if how != "hang" else front)
    return P


# 종류 → (형체, 맞춤 폭 span, 자세들). 정지·걷기와 스킬 자세로 캔버스를 맞춘다. 공격·쓰러짐은 2배 캔버스로 따로 굽는다(H.save)
KINDS = {"shield_orc": (wall, 4.0, {"idle": [WALL], "walk": WALL_WALK, "attack": H.ATTACK, "fall": H.FALL}),
         "berserker": (fury, 4.0, {"idle": [FURY], "walk": FURY_WALK, "attack": FURY_ATTACK, "fall": H.FALL}),
         "drummer": (drum, 4.0, {"idle": [DRUM], "walk": DRUM_WALK, "attack": H.ATTACK, "sway": DRUM_SWAY, "fall": H.FALL}),
         "chain_orc": (hook, 5.0, {"idle": [HOOK], "walk": HOOK_WALK, "attack": H.ATTACK, "hook": HOOK_CAST, "fall": H.FALL})}


def model(kind):
    return H.scaled(KINDS[kind][0], SCALE)


def fits(kind):
    _, span, anims = KINDS[kind]
    poses = [p for a, ps in anims.items() if a not in ("attack", "fall") for p in ps]
    return H.fits(TRIAL / kind, poses, model(kind), f"{TAG} {kind}" + VERS.get(kind, ""), SIZES, span=span)


def bake(kind):
    """시트와 fit.json → art/trial/<종류>/. → 24px 맞춤"""
    out = TRIAL / kind
    out.mkdir(parents=True, exist_ok=True)
    fts = fits(kind)
    anims = KINDS[kind][2]
    for a in anims:
        H.save(a, a, 45, "D", "f24p", fts, model(kind), BASE, anims, out, PARTS)
    return fts[24]


def lint():
    """H5(팔레트·반투명·잘림)는 모든 시트, H3·H4(걷기 윗몸 고정·다리 다름)는 걷기 시트. 북 고수는 걷기에서 북채 든 팔이 번갈아 움직이므로 H3의 윗몸 변화가 0이 아니다"""
    import types

    import lint as L
    pal = R.PALETTES["f24p"]
    for kind, (_, _, anims) in KINDS.items():
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
    """검수용 확대본 → art/trial/preview/horde_24.png(남·동·북·서 줄마다 장갑 오크·방패벽 오크·광전사·북 고수·사슬 오크)와
    horde_moves_24.png(걷기 2위상·공격·정지 중 2열·스킬 자세·누운 자세, 남쪽과 동쪽)"""
    from PIL import Image

    import preview as V
    import slime as S
    fts = {k: fits(k)[24] if (TRIAL / k / "idle_45_D_f24p_24.png").exists() else bake(k) for k in KINDS}  # 구운 시트가 있으면 다시 굽지 않는다
    pv = TRIAL / "preview"
    rows = [0, list(R.DIRS).index("E"), list(R.DIRS).index("N"), list(R.DIRS).index("W")]

    def cell(folder, anim, c, row, col=0):
        n = c * (2 if anim in ("attack", "fall") else 1)
        return S.cells(folder / f"{anim}_45_D_f24p_24.png", n, row)[col]

    orc = O.fits()[24]
    lines = [V.up(S.lineup([(cell(O.OUT, "idle", orc[2], r), orc)] + [(cell(TRIAL / k, "idle", f[2], r), f) for k, f in fts.items()]), 6) for r in rows]
    V.stack(lines, gap=8).save(pv / "horde_24.png")
    lines = []
    for kind, (_, _, anims) in KINDS.items():
        c = fts[kind][2]
        for r in rows[:2]:
            frames = []
            for a, poses in anims.items():
                if a == "idle":
                    continue
                cols = [4] if a == "fall" else ([1] if a == "attack" else list(range(min(len(poses), 2))))
                for q in cols:
                    g = Image.new("RGBA", (2 * c, 2 * c), (0, 0, 0, 0))  # 2배 칸에 발밑을 맞춘다
                    g.alpha_composite(cell(TRIAL / kind, a, c, 0 if a == "fall" else r, q), (0, 0) if a in ("attack", "fall") else (c // 2, c // 2))
                    frames.append(g)
            lines.append(V.up(V.on(R.sheet(frames, len(frames), gap=2), pad=4), 4))
    V.stack(lines, gap=8).save(pv / "horde_moves_24.png")
    print(pv / "horde_24.png", pv / "horde_moves_24.png")


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
