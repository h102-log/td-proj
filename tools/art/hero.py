# 시험 영웅(기사: 오른손 검, 왼손 방패)의 3D 형체와 자세, 그리고 스프라이트 굽기(art_source_research/08 §3 단계 1·2).
# 사용: python tools/art/hero.py  → art/trial/hero/ 에 변형마다 시트를 쓴다
from pathlib import Path

import numpy as np

import render as R

OUT = Path(__file__).resolve().parents[2] / "art" / "trial" / "hero"
BASE = {"skin": "e8b090", "hair": "4a2c18", "steel": "98a2b4", "cloth": "3c9f9c",  # cloth = 아군 팀 색(README 결론 2 B)
        "leather": "70462a", "blade": "b4bccb", "gold": "d0a038", "wood": "8a5530",  # 검날 dfe6ee는 밝은 면이 크림(efd8a1)이라 나무 막대 같았다
        "visor": "1b2030"}  # 투구 눈구멍. 151a26은 f24p 램프 밝은 쪽이 갈색(2a1d0d)이 됐다
MATS = list(BASE)
SIZES = (16, 24, 32)

# 공격·쓰러짐의 기준 자세. 검은 앞으로 18°: 수직이면 정측면(동·서)에서 1px 막대로 보였다(사용자 2026-10-18)
POSE = dict(hip_l=0, hip_r=0, knee_l=4, knee_r=4, sh_l=20, el_l=70, ab_l=0.12, sh_r=15, el_r=70, ab_r=0.35, sword=18, sword_side=0, lean=0, bob=0, fall=0)
# 정지·걷기는 오른팔을 더 벌리고 검을 바깥으로 45° 눕힌다. 8방향 모두 검 끝이 몸 실루엣 밖으로 3px 이상 나온다
# (24px, 방향별 7·3·3·8·7·7·8·7px). 남·남동·서·남서에서 검이 몸에 묻혔다(Gemini 2차 2026-10-18)
IDLE = dict(POSE, ab_r=0.7, sword_side=45)
# 걷기는 다리만 움직이고 윗몸(머리·몸통·팔·검·방패)은 통째로 정수 1px 오르내림만 한다. 방패 팔을 흔들면 윤곽이 프레임마다 깨졌다(사용자 2026-10-18)
WALK = [dict(IDLE, hip_r=24, knee_r=5, hip_l=-20, knee_l=12),  # 접지(오른발 앞)
        dict(IDLE, hip_r=-2, knee_r=2, hip_l=10, knee_l=40, bob=1),     # 통과
        dict(IDLE, hip_l=24, knee_l=5, hip_r=-20, knee_r=12),  # 반대 접지
        dict(IDLE, hip_l=-2, knee_l=2, hip_r=10, knee_r=40, bob=1)]
ATTACK = [dict(POSE, sh_r=150, el_r=20, sword=-100, lean=-6, sh_l=30, el_l=80),  # 들어올림
          dict(POSE, sh_r=75, el_r=5, sword=110, lean=12, hip_r=14, knee_r=10, hip_l=-10, knee_l=10),  # 내려침(타격 프레임)
          dict(POSE, sh_r=45, el_r=35, sword=60, lean=5)]
FALL = [dict(POSE, knee_l=25, knee_r=25, lean=10),
        dict(POSE, fall=20, knee_l=30, knee_r=30, sh_r=60),
        dict(POSE, fall=45, knee_l=20, knee_r=20, sh_r=90, sh_l=80, sword=60),
        dict(POSE, fall=70, knee_l=10, knee_r=10, sh_r=120, sh_l=110, sword=110),
        dict(POSE, fall=88, knee_l=5, knee_r=5, sh_r=150, sh_l=140, sword=160)]


def rx(a):
    """x축 회전. 양수면 위쪽 벡터가 앞(+y)으로 기운다"""
    c, s = np.cos(np.radians(a)), np.sin(np.radians(a))
    return np.array([[1, 0, 0], [0, c, s], [0, -s, c]])


def down(pitch, side=0.0):
    """곧장 아래에서 앞으로 pitch도 기운 단위 벡터"""
    a = np.radians(pitch)
    v = np.array([side, np.sin(a), -np.cos(a)])
    return v / np.linalg.norm(v)


def rig(pose, bob_unit):
    """인간형 공용 뼈대(WBS 4.1d). 자세 → (윗몸 변환 U, 다리 변환 G, 윗몸 회전 up_r, 다리 관절, 팔 관절).
    bob_unit: 화면 1px만큼 위로 올리는 월드 z. 몸통 오르내림을 정수 픽셀로 맞춰 H3(윤곽 흔들림)를 지킨다"""
    hip_z, pelvis = 0.41, np.array([0, 0, 0.41])
    # 옆(모델 오른쪽)으로 쓰러진다. 45°에서는 뒤로 누운 몸이 선 몸과 화면 높이가 같아(cos45 = sin45) 서 있는 것처럼 보였다(2026-10-18)
    f = np.radians(pose["fall"])
    fall = np.array([[np.cos(f), 0, np.sin(f)], [0, 1, 0], [-np.sin(f), 0, np.cos(f)]])
    lift = np.array([0, 0, 0.08 * np.sin(f)])
    up_r = fall @ rx(pose["lean"])
    bob = np.array([0, 0, pose["bob"] * bob_unit])

    def U(p):  # 윗몸: 기울기·오르내림 뒤 쓰러짐
        return fall @ (pelvis + rx(pose["lean"]) @ (np.asarray(p, float) - pelvis) + bob) + lift

    def G(p):  # 다리는 오르내리지 않는다. 통과 자세의 디딤발이 땅에 붙어 있게
        return fall @ np.asarray(p, float) + lift

    legs, arms = {}, {}  # 쪽마다 (엉덩이, 무릎, 발목) / (어깨, 팔꿈치, 손). 아직 U·G를 거치지 않은 좌표다
    for side, s in (("l", -1), ("r", 1)):
        hip = np.array([0.065 * s, 0, hip_z])
        knee = hip + 0.19 * down(pose["hip_" + side])
        legs[side] = (hip, knee, knee + 0.19 * down(pose["hip_" + side] - pose["knee_" + side]))
        sh = np.array([0.165 * s, 0, 0.655])
        el = sh + 0.15 * down(pose["sh_" + side], pose["ab_" + side] * s)
        arms[side] = (sh, el, el + 0.13 * down(pose["sh_" + side] + pose["el_" + side], 0.05 * s))
    return U, G, up_r, legs, arms


def blade_axes(pose, up_r):
    """손에 든 긴 물건(검·지휘봉)의 방향 bd와 축 행렬. 앞으로 sword도, 바깥(오른쪽)으로 sword_side도 기운다"""
    a, s = np.radians(pose["sword"]), np.radians(pose["sword_side"])
    bd = up_r @ np.array([np.sin(s), np.sin(a) * np.cos(s), np.cos(a) * np.cos(s)])
    side = up_r @ np.array([1.0, 0, 0])
    side = (side - (side @ bd) * bd) / np.linalg.norm(side - (side @ bd) * bd)
    third = np.cross(bd, side)
    return bd, side, third


def knight(pose, bob_unit):
    U, G, up_r, legs, arms = rig(pose, bob_unit)
    m = MATS.index
    P = []  # (sdf, 재질, 부위). 부위는 프레임 차이 검사(H3)가 머리·몸통과 팔다리를 가르는 데 쓴다
    for side in "lr":  # 다리: 허벅지 가죽, 정강이 강철, 발 가죽
        hip, knee, ankle = legs[side]
        P += [(R.capsule(G(hip), G(knee), 0.052), m("leather"), "leg"), (R.capsule(G(knee), G(ankle), 0.048), m("steel"), "leg"),
              (R.ellipsoid(G(ankle + [0, 0.035, -0.005]), (0.042, 0.068, 0.032)), m("leather"), "leg")]
    P += [(R.box(U([0, 0, 0.575]), (0.12, 0.075, 0.12), up_r, 0.035), m("cloth"), "torso"),  # 몸통(겉옷)
          (R.box(U([0, 0, 0.455]), (0.125, 0.08, 0.022), up_r), m("leather"), "torso"),  # 허리띠
          (R.box(U([0, 0, 0.415]), (0.11, 0.07, 0.04), up_r, 0.02), m("cloth"), "torso"),
          (R.ellipsoid(U([0, 0, 0.80]), (0.125, 0.12, 0.13)), m("skin"), "head"),  # 머리(비례 과장, 결론 1)
          (R.ellipsoid(U([0, -0.03, 0.78]), (0.12, 0.11, 0.11)), m("hair"), "head")]
    helm = R.ellipsoid(U([0, -0.005, 0.81]), (0.145, 0.14, 0.14))  # 투구: 목 위를 덮고 앞에 얼굴 창
    face = R.box(U([0, 0.09, 0.765]), (0.075, 0.08, 0.045), up_r)
    cut_p, cut_n = U([0, 0, 0.70]), up_r @ [0, 0, 1]
    P.append((lambda p: np.maximum(np.maximum(helm(p), -((p - cut_p) @ cut_n)), -face(p)), m("steel"), "head"))
    # 눈높이에 투구 면보다 살짝 나온 어두운 눈구멍. 얼굴 창의 살색이 강철 하이라이트와 섞여 투구 앞뒤가 안 갈렸다(Gemini 2026-10-18).
    # 얼굴 창 높이(z 0.72~0.81)에 두면 24px에서 목 그늘처럼 읽혔고, 뒤에서 보이는 머리카락 띠와 높이가 같았다
    P.append((R.box(U([0, 0.12, 0.815]), (0.08, 0.025, 0.035), up_r), m("visor"), "head"))
    for side in "lr":  # 팔: 어깨 강철, 윗팔 강철, 아래팔·손 가죽
        sh, el, hd = arms[side]
        P += [(R.ellipsoid(U(sh), (0.07, 0.07, 0.055)), m("steel"), "torso"), (R.capsule(U(sh), U(el), 0.042), m("steel"), "arm"),
              (R.capsule(U(el), U(hd), 0.04), m("leather"), "arm"), (R.ellipsoid(U(hd), (0.042, 0.042, 0.042)), m("leather"), "arm")]
    hd = U(arms["r"][2])
    bd, side, third = blade_axes(pose, up_r)  # 검날 방향: 앞으로 sword, 바깥(오른쪽)으로 sword_side
    ax = np.stack([side, bd, third])
    dia = np.stack([(side + third) / np.sqrt(2), bd, (third - side) / np.sqrt(2)])  # 검날 단면은 마름모: 두 면이 빛을 달리 받아 명암 2단이 된다
    P += [(R.box(hd + bd * 0.045, (0.065, 0.015, 0.022), ax), m("gold"), "sword"),
          # 검날 두께 1.2배·길이 1.3배(뿌리 0.06은 그대로). 1.5배는 흰 몽둥이처럼 보였다(Gemini 2차 2026-10-18)
          (R.box(hd + bd * 0.346, (0.036, 0.286, 0.036), dia), m("blade"), "sword"),
          (R.capsule(hd - bd * 0.05, hd, 0.022), m("leather"), "sword")]
    _, el_l, hd_l = arms["l"]
    n = up_r @ (np.array([-0.4, 1.0, 0]) / np.linalg.norm([-0.4, 1.0, 0]))  # 방패 앞면: 앞·왼쪽
    zz = up_r @ np.array([0, 0, 1.0])
    P.append((R.box(U((el_l + hd_l) / 2) + n * 0.035, (0.13, 0.022, 0.11), np.stack([zz, n, np.cross(zz, n)]), 0.015), m("wood"), "shield"))
    return P


PARTS = ["leg", "torso", "head", "arm", "sword", "shield"]


PPU24 = 17.47  # 유닛 24px의 배율. 사용자가 24px을 정할 때 본 몸 크기다(2026-10-18 1차 검수 전 맞춤값)


def fit(n, poses, model=knight):
    """배율은 PPU24에 비례해 고정하고, 모든 자세·방향·각도(45·60)가 들어가는 정사각 캔버스 크기와 기준점(발밑)을 구한다.
    검을 키우면 몸이 줄던 것(24px 배율 17.47 → 14.69)을 막는다(사용자 결정 2026-10-18). 기준점은 정수라 Godot에서 offset이 정수다"""
    lo, hi, wd = 0.0, 0.0, 0.0
    big, bp = 160, 160 / 3.0
    for elev in (45, 60):
        cam = R.Cam(elev)
        for g in R.DIRS.values():
            for pose in poses:
                pid, _, _ = R.trace(model(pose, 0), cam, cam.facing(*g), big, bp, (big / 2, big / 2))
                ys, xs = np.nonzero(pid >= 0)
                hi, lo = max(hi, (big / 2 - ys.min()) / bp), min(lo, (big / 2 - ys.max() - 1) / bp)
                wd = max(wd, abs(xs.min() - big / 2) / bp, abs(xs.max() + 1 - big / 2) / bp)
    ppu = PPU24 * n / 24
    c = 2 * int(np.ceil(max((hi - lo) * ppu + 5, 2 * wd * ppu + 4) / 2))  # 바깥 외곽선 1px + 반올림 1px씩 양쪽, 위는 걷기 오르내림 1px 더. 짝수라야 가운데가 정수
    return ppu, (c / 2, int(round(3 + hi * ppu))), c


def bake(pose, elev, g, n, ppu, anchor, ramps, outline, dark, model=knight, parts=PARTS):
    """→ (팔레트 번호 이미지, 부위 이미지: 0 빈칸, 1~ parts 순서)"""
    cam = R.Cam(elev)
    prims = model(pose, 1 / (ppu * cam.cos))
    pid, lam, depth = R.trace(prims, cam, cam.facing(*g), n, ppu, anchor)
    mats = np.array([q[1] for q in prims])
    part = np.array([1 + parts.index(q[2]) for q in prims])
    mat = np.where(pid >= 0, mats[pid], -1)
    # 안쪽 외곽선 문턱: 칸 하나의 깊이 차가 곡면에서 문턱을 넘지 않게 픽셀 크기에 비례해 키운다(16px에서 0.08이면 곡면 전체가 외곽선이 됐다)
    idx = R.shade(mat, lam, depth, ramps, outline, dark, edge=0.1 + 1.5 / ppu)
    return idx, np.where(pid >= 0, part[pid], 0)


ANIMS = {"idle": [IDLE], "walk": WALK, "attack": ATTACK, "fall": FALL}


def fits(out=None, poses=None, model=knight, tag=f"m5 ppu{PPU24} blade1.2x1.3", sizes=SIZES):
    """맞춤은 45초쯤 걸려서 자세가 같으면 저장해 둔 값을 쓴다. → {n: (배율, 기준점, 캔버스)}.
    공격·쓰러짐 자세는 넣지 않는다. 앞으로 뻗은 검까지 넣으면 캔버스가 커져서, 그 둘은 2배 캔버스로 따로 굽는다(save).
    기본값은 기사다. 다른 영웅은 자기 폴더·정지와 걷기 자세·형체·꼬리표로 부른다(general.py)"""
    import json
    out, poses = out or OUT, poses or [IDLE] + WALK
    f = out / "fit.json"
    key = repr(poses) + tag  # 여백이나 형체 크기를 바꾸면 꼬리표도 바꾼다
    if f.exists() and json.loads(f.read_text())["key"] == key:
        return {int(k): (v[0], tuple(v[1]), v[2]) for k, v in json.loads(f.read_text())["fits"].items()}
    res = {n: fit(n, poses, model) for n in sizes}
    f.write_text(json.dumps({"key": key, "fits": res}))
    return res


def ramp(v, pal):
    """재질 램프(팔레트 번호 5개: 안쪽 외곽선, 음영 0~3). 값이 hex 하나면 R.ramp가 고르고, 5개 목록이면 손으로 정한 팔레트 색이다.
    자동으로 고르면 금속 그늘이 탁한 갈색이 되는 등 맞지 않을 때 쓴다(tiles.py RAMPS와 같은 까닭)"""
    if isinstance(v, str):
        return R.ramp([int(v[i:i + 2], 16) for i in (0, 2, 4)], pal)
    hexes = ["%02x%02x%02x" % tuple(c) for c in pal]
    return [hexes.index(h) for h in v]


def save(name, anim, elev, outline, pname, fts, model=knight, base=BASE, anims=ANIMS, out=None, parts=PARTS):
    """시트: 행 = 8방향(DIRS 순서), 열 = 프레임. 부위 이미지는 parts/에 같은 이름으로. 기본값은 기사다"""
    from PIL import Image
    out = out or OUT
    pal = R.PALETTES[pname]
    ramps = [ramp(base[k], pal) for k in base]
    dirs = list(R.DIRS.values())[:1] if anim == "fall" else R.DIRS.values()  # 쓰러짐은 방향 없는 한 벌(06 §1)
    (out / "parts").mkdir(exist_ok=True)
    for n, (ppu, anc, c) in fts.items():
        imgs, prt = [], []
        big = anim in ("attack", "fall")  # 공격·쓰러짐은 2배 캔버스. 정지·걷기 캔버스로는 뻗은 검·누운 몸이 잘린다(2026-10-18 4.0)
        c, a = (2 * c, (anc[0] + c / 2, anc[1] + c / 2)) if big else (c, anc)
        for g in dirs:
            for pose in anims[anim]:
                idx, part = bake(pose, elev, g, c, ppu, a, ramps, outline, R.darkest(pal), model, parts)
                imgs.append(R.rgba(idx, pal))
                prt.append(Image.fromarray(part.astype(np.uint8), "L").convert("RGBA"))
        cols = len(anims[anim])
        R.sheet(imgs, cols).save(out / f"{name}_{elev}_{outline}_{pname}_{n}.png")
        R.sheet(prt, cols).getchannel("R").save(out / "parts" / f"{name}_{elev}_{outline}_{pname}_{n}.png")


if __name__ == "__main__":
    import sys
    OUT.mkdir(parents=True, exist_ok=True)
    fts = fits()
    for n, (ppu, anc, c) in fts.items():
        print(f"n={n} ppu={ppu:.2f} anchor={anc} canvas={c}")
    what = sys.argv[1] if len(sys.argv) > 1 else "idle"
    if what == "idle":  # 1단계: 각도·외곽선·팔레트 변형 8개
        for pname in R.PALETTES:
            for elev in (45, 60):
                for outline in "BD":
                    save("idle", "idle", elev, outline, pname, fts)
    else:  # 2단계 뒤: 한 변형으로 동작 굽기. 예) python hero.py walk 45 D f24p
        elev, outline, pname = int(sys.argv[2]), sys.argv[3], sys.argv[4]
        save(what, what, elev, outline, pname, fts)
    print("ok")
