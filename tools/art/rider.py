# 6라운드 늑대 기수(wolf_rider, S335·I279 ⑤)의 3D 형체와 스프라이트 굽기. 네발로 달리는 늑대 등에 오크 상반신이 앉아 있다.
# 늑대의 털·밝은 가슴·짧고 굵은 주둥이·곧게 선 귀·끝이 밝은 꼬리는 늑대(wolf.py)의 재질과 생김새를, 오크의 가슴 철판·뿔 투구·넓은 칼은
# 장갑 오크(orc.py)의 것을 그대로 쓴다. 오크의 팔·검 자세는 기사(hero.py) 뼈대다. 다리 넷은 대각선 짝(왼앞·오른뒤)이 함께 움직인다.
# 게임은 C 절충안으로 4방향·걷기 2위상·공격 키 포즈만 쓴다(atlas.py). 쓰러지지 않고 오크가 내리므로(S335 ②) 누운 그림은 굽지 않는다
# 사용: python tools/art/rider.py [preview]  → art/trial/wolf_rider/. 검사: python tools/art/lint.py walk_45_D_f24p wolf_rider
from pathlib import Path

import numpy as np

import hero as H
import orc as O
import render as R
import wolf as W

OUT = Path(__file__).resolve().parents[2] / "art" / "trial" / "wolf_rider"
_FUR = W.base("wolf")
BASE = {"fur": _FUR["fur"], "pale": _FUR["pale"], "nose": _FUR["nose"], "eye": _FUR["eye"],
        "skin": O.BASE["skin"], "iron": O.BASE["iron"], "blade": O.BASE["blade"], "leather": O.BASE["leather"], "horn": O.BASE["horn"]}
MATS = list(BASE)
PARTS = ["leg", "torso", "head", "arm", "sword"]
SIZES = (24,)
SEAT = 0.9  # 탄 오크의 크기(장갑 오크 1.1배보다 작게: 늑대와 한 몸으로 읽히게)
TAG = f"m5 ppu{H.PPU24} rider1 seat{SEAT}"
# 자세: 기사 자세에 늑대 것을 더한다. gait 다리 흔들기(도, 양수면 왼앞·오른뒤가 앞), tuck 들어 올린 대각선 짝(±1), lunge 늑대가 머리를 내미는 거리, jaw 턱 벌림(도)
RIDE = dict(H.IDLE, sh_l=45, el_l=45, ab_l=0.1, gait=0, tuck=0, lunge=0.0, jaw=0)  # 왼손은 앞으로 내려 갈기를 쥔다
WALK = [dict(RIDE, gait=24), dict(RIDE, tuck=1, bob=1), dict(RIDE, gait=-24), dict(RIDE, tuck=-1, bob=1)]  # 접지·통과·반대 접지·통과. 윗몸은 통과에서 1px만 오른다(H3)
ATTACK = [dict(H.ATTACK[0], sh_l=45, el_l=45, ab_l=0.1, gait=10, tuck=0, lunge=-0.02, jaw=15),
          dict(H.ATTACK[1], sh_l=45, el_l=45, ab_l=0.1, gait=-14, tuck=0, lunge=0.1, jaw=45),  # 타격 프레임: 오크는 내려치고 늑대는 고개를 내밀어 문다
          dict(H.ATTACK[2], sh_l=45, el_l=45, ab_l=0.1, gait=0, tuck=0, lunge=0.03, jaw=10)]
ANIMS = {"idle": [RIDE], "walk": WALK, "attack": ATTACK}


def body(pose, bob_unit):
    m = MATS.index
    bob = np.array([0, 0, pose["bob"] * bob_unit])
    P = []

    def B(p):  # 늑대 몸통·꼬리: 오크와 함께 정수 px만 오르내린다
        return np.asarray(p, float) + bob

    for sx in (-1, 1):  # 다리 넷. 발은 오르내리지 않는다
        for y, front in ((0.16, 1), (-0.2, -1)):
            pair = sx * front  # −1 왼앞·오른뒤, +1 오른앞·왼뒤
            lifted = pose["tuck"] != 0 and pair == pose["tuck"]
            a = -pair * pose["gait"] + (12 if lifted else 0)
            bend = 60 if lifted else 8
            hip = np.array([0.085 * sx, y, 0.3])
            knee = hip + 0.15 * H.down(a + bend / 2)
            foot = knee + 0.15 * H.down(a - bend / 2)
            P += [(R.capsule(hip, knee, 0.052, 0.042), m("fur"), "leg"), (R.capsule(knee, foot, 0.04, 0.032), m("fur"), "leg"),
                  (R.ellipsoid(foot + [0, 0.03, 0.012], (0.038, 0.058, 0.028)), m("pale"), "leg")]
    tail = np.array([0.035, -0.49, 0.5])
    P += [(R.capsule(B([0, -0.22, 0.37]), B([0, 0.17, 0.39]), 0.12, 0.135), m("fur"), "torso"),  # 몸통: 가슴 쪽이 조금 굵다
          (R.ellipsoid(B([0, 0.21, 0.35]), (0.1, 0.085, 0.115)), m("pale"), "torso"),  # 밝은 가슴 털
          (R.capsule(B([0, -0.3, 0.4]), B(tail), 0.05, 0.042), m("fur"), "torso"),  # 굵은 꼬리
          (R.ellipsoid(B(tail + [0.005, -0.015, 0.0]), (0.045, 0.045, 0.05)), m("pale"), "torso"),  # 꼬리 끝
          (R.box(B([0, -0.04, 0.42]), (0.142, 0.075, 0.1), np.eye(3), 0.03), m("leather"), "torso")]  # 안장 깔개
    reach = np.array([0, pose["lunge"], -0.3 * pose["lunge"]]) + bob  # 물기: 머리를 앞·아래로 내민다

    def Hd(p):
        return np.asarray(p, float) + reach
    P += [(R.capsule(B([0, 0.2, 0.45]), Hd([0, 0.33, 0.56]), 0.09, 0.08), m("fur"), "head"),  # 목
          (R.ellipsoid(Hd([0, 0.3, 0.6]), (0.1, 0.08, 0.06)), m("pale"), "head"),  # 목 갈기
          (R.ellipsoid(Hd([0, 0.37, 0.58]), (0.095, 0.1, 0.09)), m("fur"), "head"),  # 머리통
          (R.capsule(Hd([0, 0.43, 0.565]), Hd([0, 0.56, 0.545]), 0.052, 0.038), m("fur"), "head"),  # 짧고 굵은 주둥이
          (R.ellipsoid(Hd([0, 0.575, 0.553]), (0.026, 0.02, 0.02)), m("nose"), "head")]
    hinge = np.array([0, 0.42, 0.535])  # 아래턱: 밝은 털, jaw도만큼 벌린다
    P.append((R.capsule(Hd(hinge), Hd(hinge + H.rx(pose["jaw"]) @ [0, 0.13, -0.01]), 0.04, 0.028), m("pale"), "head"))
    for s in (-1, 1):
        P.append((R.box(Hd([0.052 * s, 0.455, 0.615]), (0.02, 0.012, 0.016)), m("eye"), "head"))
        P.append((R.capsule(Hd([0.06 * s, 0.34, 0.65]), Hd([0.078 * s, 0.32, 0.82]), 0.04, 0.008), m("fur"), "head"))  # 곧게 선 귀

    # 탄 오크: 장갑 오크(orc.py)의 윗몸을 SEAT배로 줄여 안장 위에 앉힌다. 다리는 늑대 옆구리를 감싸 내린다
    U, _, up_r, _, arms = H.rig(pose, bob_unit / SEAT)
    Q = [(R.box(U([0, 0, 0.58]), (0.14, 0.09, 0.13), up_r, 0.04), m("iron"), "torso"),  # 가슴 철판
         (R.box(U([0, 0, 0.455]), (0.13, 0.085, 0.025), up_r), m("leather"), "torso"),
         (R.ellipsoid(U([0, 0.01, 0.79]), (0.12, 0.12, 0.12)), m("skin"), "head")]
    helm = R.ellipsoid(U([0, -0.01, 0.815]), (0.14, 0.135, 0.13))  # 투구: 얼굴 아래쪽(턱·엄니)은 드러낸다
    face = R.box(U([0, 0.1, 0.75]), (0.085, 0.1, 0.06), up_r)
    Q.append((lambda p: np.maximum(helm(p), -face(p)), m("iron"), "head"))
    for s in (-1, 1):
        Q.append((R.capsule(U([0.11 * s, 0, 0.86]), U([0.2 * s, 0.02, 0.99]), 0.035, 0.012), m("horn"), "head"))  # 뿔
        Q.append((R.capsule(U([0.04 * s, 0.11, 0.73]), U([0.05 * s, 0.13, 0.78]), 0.014, 0.008), m("horn"), "head"))  # 엄니
        Q += [(R.capsule(U([0.075 * s, 0, 0.42]), U([0.17 * s, 0.1, 0.3]), 0.058), m("leather"), "torso"),  # 허벅지
              (R.capsule(U([0.17 * s, 0.1, 0.3]), U([0.18 * s, 0.04, 0.16]), 0.052), m("iron"), "torso"),  # 쇠 정강이
              (R.ellipsoid(U([0.18 * s, 0.07, 0.14]), (0.048, 0.07, 0.034)), m("iron"), "torso")]
    for side in "lr":  # 팔: 큰 어깨 철판, 맨 아래팔
        sh, el, hd = arms[side]
        Q += [(R.ellipsoid(U(sh) + up_r @ [0, 0, 0.02], (0.1, 0.09, 0.07)), m("iron"), "torso"),
              (R.capsule(U(sh), U(el), 0.05), m("skin"), "arm"), (R.capsule(U(el), U(hd), 0.048), m("skin"), "arm"),
              (R.ellipsoid(U(hd), (0.048, 0.048, 0.048)), m("leather"), "arm")]
    hd = U(arms["r"][2])
    bd, side, third = H.blade_axes(pose, up_r)
    Q += [(R.box(hd + bd * 0.24, (0.06, 0.2, 0.014), np.stack([side, bd, third]), 0.01), m("blade"), "sword"),  # 넓은 칼
          (R.capsule(hd - bd * 0.05, hd + bd * 0.04, 0.024), m("leather"), "sword")]
    off = np.array([0, -0.05, 0.48]) - SEAT * np.array([0, 0, 0.41])  # 오크 골반(0, 0, 0.41)이 안장 위에 온다
    return P + [(lambda q, f=f: f((q - off) / SEAT) * SEAT, mat, part) for f, mat, part in Q]


def fits():
    return H.fits(OUT, [RIDE] + WALK, body, TAG, SIZES, span=4.0)


def bake():
    """정지·걷기·공격 시트와 fit.json → art/trial/wolf_rider/. → 24px 맞춤"""
    OUT.mkdir(parents=True, exist_ok=True)
    fts = fits()
    for anim in ANIMS:
        H.save(anim, anim, 45, "D", "f24p", fts, body, BASE, ANIMS, OUT, PARTS)
    return fts[24]


def preview():
    """검수용 확대본 → art/trial/preview/wolf_rider_24.png: 위 줄은 정지 남·동·북·서와 늑대·오크·오우거(동), 아래 줄은 걷기 2위상·공격 타격(동·남)"""
    from PIL import Image

    import ogre as G
    import preview as V
    import slime as S
    ppu, anc, c = bake()
    E = list(R.DIRS).index("E")

    def cell(folder, anim, n, row, col=0):
        return S.cells(folder / f"{anim}_45_D_f24p_24.png", n * (2 if anim == "attack" else 1), row)[col]

    def frame(anim, row, col=0):  # 2배 칸에 발밑을 맞춘다
        g = Image.new("RGBA", (2 * c, 2 * c), (0, 0, 0, 0))
        g.alpha_composite(cell(OUT, anim, c, row, col), (0, 0) if anim == "attack" else (c // 2, c // 2))
        return g
    wolf = W.fits("wolf")[24]
    others = [(cell(W.TRIAL / "wolf", "idle", wolf[2], E), wolf), (cell(O.OUT, "idle", O.fits()[24][2], E), O.fits()[24]), (cell(G.OUT, "idle", G.fits()[24][2], E), G.fits()[24])]
    top = S.lineup([(cell(OUT, "idle", c, d), (ppu, anc, c)) for d in (0, E, 4, 6)] + others)
    low = R.sheet([frame("walk", E, 0), frame("walk", E, 1), frame("attack", E, 1), frame("walk", 0, 0), frame("walk", 0, 1), frame("attack", 0, 1)], 6, gap=2)
    pv = OUT.parent / "preview"
    V.stack([V.up(V.on(top, pad=4), 6), V.up(V.on(low, pad=4), 6)], gap=8).save(pv / "wolf_rider_24.png")
    print(pv / "wolf_rider_24.png")


if __name__ == "__main__":
    import sys
    if sys.argv[1:] == ["preview"]:
        preview()
        sys.exit()
    ppu, anc, c = bake()
    print(f"wolf_rider ppu={ppu:.2f} anchor={anc} canvas={c}")
    print("ok")
