# 색 원으로 그리던 적 셋(I291)의 3D 형체와 스프라이트 굽기: 방패 고블린(shieldbearer)·불화살 고블린(fire_archer)·둥지(nest).
# 고블린 둘은 기본 고블린(goblin.py)의 몸(잿빛 피부, 큰 머리·뾰족 귀, 붉은 넝마, 숙인 자세)이고 든 것과 차림으로 가른다.
#   방패 고블린: 기본 고블린보다 조금 큰 몸(0.9배), 쇠 모자, 왼팔에 몸을 가리는 둥근 방패(앞은 밝은 강철 면, 뒤는 나무 판, 어두운 쇠 테·쇠 돌기), 오른손에 짧은 칼.
#   불화살 고블린: 기본 고블린과 같은 크기의 몸(0.8배), 붉은 두건(귀는 밖으로), 등에 화살통, 왼손에 짧은 활, 오른손에 횃불처럼 세워 든 불붙은 화살.
#                  스킬 자세 shoot 2열(시위를 당김 → 놓음).
#   둥지: 나뭇가지를 엮은 둥근 둥지에 알 셋과 하피 깃털. 방향이 없어 남쪽 한 행만 쓴다(정지 1열뿐).
# 뼈대·자세는 기사(hero.py) 것이다. 게임은 C 절충안으로 4방향·걷기 2위상·공격 키 포즈만 쓴다(atlas.py)
# 사용: python tools/art/trio.py [preview]  → art/trial/<종류>/. 검사: python tools/art/trio.py lint
from pathlib import Path

import numpy as np

import goblin as B
import harpy as Y
import hero as H
import orc as O
import render as R
import sylvia as S

TRIAL = Path(__file__).resolve().parents[2] / "art" / "trial"
BASE = {"skin": B.BASE["skin"], "rag": B.BASE["rag"], "wood": H.BASE["wood"], "eye": B.BASE["eye"], "iron": O.BASE["iron"], "blade": H.BASE["blade"],
        "leather": ["2a1d0d", "45230d", "724113", "a56243", "a56243"],  # 화살통
        "steel": ["262d3d", "56607a", "a4aec2", "d0d6e0", "d0d6e0"],  # 방패 고블린의 방패 면: 잿빛 피부·쇠 모자보다 밝은 강철이라 풀·흙 어디서나 방패가 먼저 보인다
        "bowwood": S.BASE["wood"],  # 활대: 몽둥이 나무보다 밝다
        "hood": ["300f0a", "550f0a", "773421", "9b1a0a", "9b1a0a"],  # 불화살 고블린의 붉은 두건. 밝은 주홍(ef3a0c)까지 쓰면 두건이 불처럼 보여 화살의 불이 묻혔다
        "flame": ["ef692f", "efac28", "efac28", "efd8a1", "efd8a1"],  # 화살 끝의 불: 노란 속불
        "ember": ["ef3a0c", "ef692f", "ef692f", "ef692f", "efac28"],  # 속불 위로 솟은 주황 불꽃 끝
        "twig": ["2a1d0d", "45230d", "724113", "724113", "a56243"],  # 둥지의 나뭇가지
        "straw": ["45230d", "ab5c1c", "efb775", "efb775", "efd8a1"],  # 둥지 안쪽의 마른 풀
        "egg": ["684c3c", "927e6a", "efd8a1", "efd8a1", "efd8a1"],  # 알
        "feather": Y.BASE["feather"]}  # 둥지에 꽂힌 하피 깃털
MATS = list(BASE)
PARTS = ["leg", "torso", "head", "arm", "sword", "shield"]
SIZES = (24,)
TAG = f"m5 ppu{H.PPU24} trio1"

# ── 자세 ── 기사 자세에 고블린의 숙임(goblin.HUNCH)을 더한다
GUARD = dict(B.IDLE)
GUARD_WALK = list(B.WALK)
_BOW = dict(S.ARMS, sword=4, sword_side=22)  # 활을 왼쪽에 세워 들고, 오른손의 불화살은 곧게 세운다
ARCH = dict(B.IDLE, **_BOW)
ARCH_WALK = [dict(w, **_BOW) for w in B.WALK]
ARCH_ATTACK = [dict(a, sh_l=S.ARMS["sh_l"], el_l=S.ARMS["el_l"], ab_l=S.ARMS["ab_l"]) for a in B.ATTACK]  # 근접(길을 막는 구조물·성문·거점, S302): 불화살을 내리찍는다
ARCH_SHOOT = [dict(S.ATTACK[0], lean=S.ATTACK[0]["lean"] + B.HUNCH), dict(S.ATTACK[1], lean=S.ATTACK[1]["lean"] + B.HUNCH)]  # 시위를 당김(불화살이 활 앞에) → 놓음(화살 없음)
ARCH_FALL = [dict(f, bow=0) for f in H.FALL]  # 쓰러지면 활과 화살을 놓친다
NEST = dict(nest=1)
ROUND = (0.31, 0.03, 0.0)  # 방패 고블린의 둥근 방패: 반지름, 왼팔에서 내린 높이, 몸 가운데 쪽으로 옮긴 거리
PERCH = 0.45  # 둥지를 발밑 기준점 위로 올리는 높이(모델 단위, 화면에서 약 6px)
SHORT_BOW = [(0.0, -0.01), (0.2, 0.04), (0.33, 0.11), (0.37, 0.095)]  # 짧은 활 한쪽 팔: (손에서 위로, 시위 쪽으로). 실비아 장궁(sylvia.BOW)의 0.8배


def _goblin(pose, bob_unit):
    """고블린 몸(goblin.py body와 같은 형체, 이 모듈의 재질 번호). → (부품, 윗몸 변환 U, 윗몸 회전, 팔 관절)"""
    U, G, up_r, legs, arms = H.rig(pose, bob_unit)
    m = MATS.index
    P = []
    for side in "lr":  # 맨다리
        hip, knee, ankle = legs[side]
        P += [(R.capsule(G(hip), G(knee), 0.045), m("skin"), "leg"), (R.capsule(G(knee), G(ankle), 0.04), m("skin"), "leg"),
              (R.ellipsoid(G(ankle + [0, 0.035, -0.005]), (0.04, 0.07, 0.03)), m("skin"), "leg")]
    P += [(R.box(U([0, 0, 0.57]), (0.105, 0.07, 0.11), up_r, 0.035), m("rag"), "torso"),  # 넝마 웃옷
          (R.box(U([0, 0, 0.42]), (0.105, 0.07, 0.05), up_r, 0.02), m("rag"), "torso"),
          (R.ellipsoid(U([0, 0.02, 0.80]), (0.145, 0.135, 0.125)), m("skin"), "head")]  # 큰 머리
    for s in (-1, 1):  # 뾰족 귀와 눈
        P.append((R.capsule(U([0.11 * s, 0, 0.82]), U([0.26 * s, -0.04, 0.9]), 0.035, 0.01), m("skin"), "head"))
        P.append((R.box(U([0.05 * s, 0.135, 0.815]), (0.025, 0.012, 0.018), up_r), m("eye"), "head"))
    for side in "lr":  # 맨팔
        sh, el, hd = arms[side]
        P += [(R.capsule(U(sh), U(el), 0.038), m("skin"), "arm"), (R.capsule(U(el), U(hd), 0.036), m("skin"), "arm"),
              (R.ellipsoid(U(hd), (0.04, 0.04, 0.04)), m("skin"), "arm")]
    return P, U, up_r, arms


def _disc(c, axis, r, h):
    """축 axis, 반지름 r, 반두께 h인 원판"""
    c, axis = np.asarray(c, float), np.asarray(axis, float)

    def f(p):
        q = p - c
        t = q @ axis
        return np.maximum(np.abs(t) - h, np.linalg.norm(q - t[:, None] * axis, axis=1) - r)
    return f


def guard(pose, bob_unit):
    """방패 고블린: 쇠 모자, 왼팔의 둥근 방패(앞 강철 면·뒤 나무 판·쇠 테·쇠 돌기), 오른손 짧은 칼"""
    P, U, up_r, arms = _goblin(pose, bob_unit)
    m = MATS.index
    cap = R.ellipsoid(U([0, 0.01, 0.83]), (0.155, 0.145, 0.115))  # 쇠 모자: 눈 위만 덮고 귀는 밖으로
    brim, zz = U([0, 0, 0.85]), up_r @ np.array([0, 0, 1.0])
    P.append((lambda p: np.maximum(cap(p), -((p - brim) @ zz)), m("iron"), "head"))
    hd = U(arms["r"][2])
    bd, side, third = H.blade_axes(pose, up_r)
    P += [(R.capsule(hd - bd * 0.04, hd + bd * 0.05, 0.022), m("wood"), "sword"),  # 손잡이
          (R.box(hd + bd * 0.19, (0.04, 0.14, 0.014), np.stack([side, bd, third]), 0.01), m("blade"), "sword")]  # 넓고 짧은 칼날
    _, el_l, hd_l = arms["l"]
    n = up_r @ (np.array([-0.5, 1.0, 0]) / np.linalg.norm([-0.5, 1.0, 0]))  # 방패 앞면: 앞·왼쪽(horde.py wall과 같다)
    r, drop, inward = ROUND
    at = U((el_l + hd_l) / 2) + n * 0.07 - zz * drop + up_r @ np.array([inward, 0, 0])
    P += [(_disc(at, n, r, 0.02), m("iron"), "shield"),  # 쇠 테: 무릎에서 턱까지 가린다
          (_disc(at + n * 0.006, n, r - 0.05, 0.024), m("steel"), "shield"),  # 강철 면
          (_disc(at - n * 0.006, n, r - 0.05, 0.024), m("wood"), "shield"),  # 뒷면의 나무 판: 성 쪽으로 걸어갈 때(북쪽을 볼 때) 보이는 면
          (R.ellipsoid(at + n * 0.03, (0.08, 0.08, 0.08)), m("iron"), "shield")]  # 쇠 돌기
    return P


def archer(pose, bob_unit):
    """불화살 고블린: 붉은 두건, 등의 화살통, 왼손 짧은 활, 오른손 불화살"""
    P, U, up_r, arms = _goblin(pose, bob_unit)
    m = MATS.index
    up, fwd, left = up_r @ np.array([0, 0, 1.0]), up_r @ np.array([0, 1.0, 0]), up_r @ np.array([-1.0, 0, 0])
    zz = up  # 곧은 위쪽. up은 아래에서 활을 눕힌 만큼(cant) 기운다
    hood = R.ellipsoid(U([0, 0.005, 0.815]), (0.16, 0.152, 0.14))  # 두건: 얼굴은 드러내고 귀는 밖으로
    face = R.box(U([0, 0.12, 0.79]), (0.105, 0.1, 0.07), up_r)
    P += [(lambda p: np.maximum(hood(p), -face(p)), m("hood"), "head"),
          (R.capsule(U([0.07, -0.1, 0.45]), U([-0.06, -0.1, 0.76]), 0.04), m("leather"), "torso"),  # 등의 화살통
          (R.capsule(U([-0.06, -0.1, 0.76]), U([-0.08, -0.1, 0.85]), 0.03), m("egg"), "torso")]  # 화살 깃
    if not pose.get("bow", 1):  # 누운 자세: 활과 화살을 놓쳤다
        return P
    g = U(arms["l"][2])  # 줌통
    back = -fwd if pose.get("aim") else left  # 시위 쪽. 정지·걷기는 몸 왼쪽에 세우고 시위를 바깥으로 둔다(sylvia.py)
    c = np.radians(pose.get("cant", 0))
    up = np.cos(c) * up + np.sin(c) * left
    back = back - (back @ up) * up
    back /= np.linalg.norm(back)
    for k in (1, -1):  # 활 위·아래 팔. 시위는 그리지 않는다(활대와 시위 사이가 메워져 방패처럼 보인다, sylvia.py)
        pts = [g + up * (a * k) + back * b for a, b in SHORT_BOW]
        P += [(R.capsule(pts[i], pts[i + 1], 0.034), m("bowwood"), "shield") for i in range(len(pts) - 1)]
    hd = U(arms["r"][2])
    fire = None  # 불이 붙은 화살 끝
    if pose.get("draw"):  # 당긴 자세: 줌통 앞으로 나온 화살대와 불
        d = (g - hd) / np.linalg.norm(g - hd)
        fire = g + d * 0.18
        P.append((R.capsule(g, g + d * 0.1, 0.026), m("wood"), "sword"))
    elif not pose.get("aim"):  # 정지·걷기·근접: 오른손에 불화살을 횃불처럼 세워 든다. 놓은 자세(aim만)는 화살이 없다
        bd = H.blade_axes(pose, up_r)[0]
        fire = hd + bd * 0.42
        P.append((R.capsule(hd - bd * 0.05, hd + bd * 0.34, 0.026), m("wood"), "sword"))
    if fire is not None:  # 노란 속불 위로 주황 불꽃 끝이 솟는다(화살이 어느 쪽을 보든 위로)
        P += [(R.ellipsoid(fire, (0.088, 0.088, 0.088)), m("flame"), "sword"), (R.capsule(fire + zz * 0.06, fire + zz * 0.23, 0.064, 0.012), m("ember"), "sword")]
    return P


def nest(_pose, _bob_unit):
    """둥지: 나뭇가지를 엮은 둥근 테, 안쪽의 마른 풀, 알 셋, 테에 꽂힌 하피 깃털 둘. 방향이 없다.
    발밑 기준점이 둥지의 앞 가장자리에 오게 PERCH만큼 올린다: 성벽 위에 선 몸처럼 흉벽 뒤에 얹히고, 가운데에 두면 아래 반이 성벽 앞면에 가렸다"""
    m = MATS.index
    lift = np.array([0, 0, PERCH])
    rim = R.ellipsoid(lift + [0, 0, 0.1], (0.37, 0.37, 0.16))
    bowl = R.ellipsoid(lift + [0, 0, 0.26], (0.26, 0.26, 0.15))
    P = [(lambda p: np.maximum(rim(p), -bowl(p)), m("twig"), "torso"),  # 테
         (R.ellipsoid(lift + [0, 0, 0.1], (0.25, 0.25, 0.05)), m("straw"), "torso")]  # 안쪽 마른 풀
    for a in np.radians(np.arange(0, 360, 40)):  # 테 밖으로 삐져나온 가지
        c, s = np.cos(a), np.sin(a)
        t = np.array([-s, c, 0.0])
        o = lift + [c * 0.34, s * 0.34, 0.15]
        P.append((R.capsule(o - t * 0.14, o + t * 0.14 + np.array([c * 0.05, s * 0.05, 0.05]), 0.024), m("twig"), "torso"))
    for x, y in ((-0.12, 0.06), (0.12, 0.07), (0.0, -0.11)):  # 알 셋
        P.append((R.ellipsoid(lift + [x, y, 0.17], (0.066, 0.066, 0.088)), m("egg"), "head"))
    for x, y, lean in ((-0.3, 0.12, -0.12), (0.27, 0.18, 0.1)):  # 하피 깃털
        P.append((R.capsule(lift + [x, y, 0.2], lift + [x + lean, y + 0.02, 0.46], 0.034, 0.012), m("feather"), "torso"))
    return P


# 종류 → (형체, 크기 배율, 맞춤 폭 span, 자세들). 정지·걷기와 스킬 자세로 캔버스를 맞춘다. 공격·쓰러짐은 2배 캔버스로 따로 굽는다(H.save)
KINDS = {"shieldbearer": (guard, 0.9, 3.0, {"idle": [GUARD], "walk": GUARD_WALK, "attack": B.ATTACK, "fall": H.FALL}),
         "fire_archer": (archer, 0.8, 3.0, {"idle": [ARCH], "walk": ARCH_WALK, "attack": ARCH_ATTACK, "shoot": ARCH_SHOOT, "fall": ARCH_FALL}),
         "nest": (nest, 1.0, 3.0, {"idle": [NEST]})}


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


def lint():
    """H5(팔레트·반투명·잘림)는 모든 시트, H3·H4(걷기 윗몸 고정·다리 다름)는 걷기 시트"""
    import types

    import lint as L
    pal = R.PALETTES["f24p"]
    for kind, (_, _, _, anims) in KINDS.items():
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
    """검수용 확대본 → art/trial/preview/trio_24.png(남·동·북·서 줄마다 기본 고블린·방패 고블린·불화살 고블린·둥지·하피)와
    trio_moves_24.png(걷기 2위상·공격·스킬 자세·누운 자세, 남쪽과 동쪽)"""
    from PIL import Image

    import preview as V
    import slime as M
    fts = {k: fits(k)[24] if (TRIAL / k / "idle_45_D_f24p_24.png").exists() else bake(k) for k in KINDS}  # 구운 시트가 있으면 다시 굽지 않는다
    pv = TRIAL / "preview"
    rows = [0, list(R.DIRS).index("E"), list(R.DIRS).index("N"), list(R.DIRS).index("W")]

    def cell(folder, anim, c, row, col=0):
        n = c * (2 if anim in ("attack", "fall") else 1)
        return M.cells(folder / f"{anim}_45_D_f24p_24.png", n, row)[col]

    gob, harpy = B.fits()[24], Y.fits()[24]
    lines = [V.up(M.lineup([(cell(B.OUT, "idle", gob[2], r), gob)] + [(cell(TRIAL / k, "idle", f[2], r), f) for k, f in fts.items()]
                           + [(cell(Y.OUT, "idle", harpy[2], r), harpy)]), 6) for r in rows]
    V.stack(lines, gap=8).save(pv / "trio_24.png")
    lines = []
    for kind, (_, _, _, anims) in KINDS.items():
        if "walk" not in anims:
            continue
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
    V.stack(lines, gap=8).save(pv / "trio_moves_24.png")
    print(pv / "trio_24.png", pv / "trio_moves_24.png")


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
