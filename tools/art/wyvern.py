# 4라운드 보스 와이번(S310)과 떨어진 와이번(S311)의 3D 형체와 스프라이트 굽기(insights/2026-11-09_round4_sky.md 3.10 «하피 뼈대 바탕으로
# 1페이즈의 나는 모습과 2페이즈의 찢긴 날개로 걷는 모습 두 벌»). 하피(harpy.py)처럼 늘 날고 있는 1페이즈는 정지도 날개를 펴고 걷기 2위상이 날갯짓이다.
# 몸은 사람형 뼈대(hero.rig)가 아니라 네 발 짐승처럼 앞으로 누운 몸통·긴 목·꼬리이고, 날개는 하피처럼 위팔 방향을 따라 붙인 얇은 판(박쥐 날개 막)이다.
# 2페이즈는 같은 몸이 두 발로 서고, 날개 막은 찢겨 구멍이 나고 늘어진다
# 사용: python tools/art/wyvern.py [preview]  → art/trial/wyvern/·art/trial/wyvern_fallen/, 확대본은 art/trial/preview/wyvern_*
from pathlib import Path

import numpy as np

import hero as H
import render as R

TRIAL = Path(__file__).resolve().parents[2] / "art" / "trial"
BASE = {"scale": ["151a26", "2a1d0d", "45230d", "773421", "a56243"],  # 녹슨 청동 비늘. 녹색은 들판 풀색에 묻히고, 자동 램프는 밝은 쪽이 회갈색이라 회색으로 읽혔다(시안 v1). 한 칸 밝은 램프는 연한 도마뱀 같았다(v2)
        "belly": ["392a1c", "684c3c", "927e6a", "efb775", "efb775"],
        "wing": ["151a26", "151a26", "300f0a", "550f0a", "773421"],  # 날개 막: 몸보다 어두운 검붉은 막
        "horn": ["392a1c", "927e6a", "efd8a1", "efd8a1", "efd8a1"],  # 뿔·발톱·날개 뼈 끝
        "eye": ["ab5c1c", "efac28", "efac28", "efd8a1", "efd8a1"],
        "mouth": ["151a26", "151a26", "300f0a", "550f0a", "550f0a"],
        "flame": ["ab5c1c", "ef692f", "efac28", "efd8a1", "efd8a1"]}
MATS = list(BASE)
PARTS = ["leg", "torso", "head", "arm", "tail"]
SIZES = (24,)
SCALE = 2.0  # 하피(0.9)의 두 배쯤. 게임 몸 반지름 0.6칸은 하피 0.3칸의 두 배다(S106)
SPAN = 6.0  # 맞춤이 재는 화면 폭(모델 단위, H.fit). 4.0이면 든 날개가 캔버스 위에서 잘렸다(시안 v1)
TAG = f"m5 ppu{H.PPU24} wyvern2 s{SCALE} span{SPAN}"

# 자세: wing 날개 위팔 높이(도, 0 수평·양수 위), fold 날개 접음(0 폄 ~ 1 접음), legs "tuck"(접음)·"stand"(섬), stride 걸음 위상 각(도, 왼다리 앞이 양수),
# lean 몸 앞숙임(도), neck 목 숙임(도), jaw 입 벌림(도), tail 꼬리 옆 휘두름(도, 오른쪽 양수), torn 찢긴 날개, flame 입 앞 불길, bob 오르내림(px)
FLY = dict(wing=10, fold=0.0, legs="tuck", stride=0, lift=0, lean=0, neck=0, jaw=0, tail=0, torn=False, flame=False, bob=0, fall=0)
UP = dict(FLY, wing=45)
DOWN = dict(FLY, wing=-25, bob=1)
STAND = dict(FLY, wing=-55, fold=0.55, legs="stand", torn=True)  # 2페이즈: 찢긴 날개를 반쯤 접어 늘어뜨린다
ANIMS1 = {"idle": [FLY], "walk": [UP, DOWN, UP, DOWN],
          "attack": [dict(UP, lean=-10, neck=-10, jaw=0), dict(FLY, lean=15, neck=20, jaw=35, legs="claw"), dict(FLY, lean=5)],  # 물어뜯기 공격 키 포즈
          "plunge": [dict(FLY, wing=70, fold=0.2, neck=-15), dict(FLY, wing=-40, fold=0.6, lean=30, neck=25, legs="claw")],  # 급강하: 날개를 높이 들어 → 접고 내리꽂음
          "carpet": [dict(FLY, wing=20, lean=10, neck=10, jaw=20), dict(FLY, wing=0, lean=15, neck=15, jaw=40, flame=True)]}  # 융단 폭격: 입을 벌림 → 불을 뿜으며 지나감
ANIMS2 = {"idle": [STAND], "walk": [dict(STAND, stride=45), dict(STAND, stride=0, bob=1, lift=1), dict(STAND, stride=-45), dict(STAND, stride=0, bob=1, lift=-1)],
          "attack": [dict(STAND, neck=-15, jaw=10), dict(STAND, lean=15, neck=25, jaw=40), dict(STAND, lean=5)],
          "breath": [dict(STAND, neck=-20, jaw=15, lean=-5), dict(STAND, neck=15, jaw=45, lean=10, flame=True)],  # 화염 숨결: 목을 젖혀 → 앞으로 뿜음
          "rush": [dict(STAND, lean=20, neck=20, stride=20), dict(STAND, lean=35, neck=30, jaw=25, stride=-25)],  # 맹진: 웅크림 → 내닫음
          "tail": [dict(STAND, tail=-60), dict(STAND, tail=70)],  # 꼬리 휘두르기: 왼쪽으로 감음 → 오른쪽으로 쓸기
          "fall": [dict(STAND, fall=f, neck=f / 3, jaw=f / 4) for f in (0, 20, 45, 65, 80)]}  # 쓰러짐: 옆으로 눕는다. 게임은 마지막 칸(누운 자세)만 쓴다(atlas.py FOUR_COLS)


def rx(a):
    """x축 회전(행렬을 오른쪽에서 곱하는 꼴이 아닌, 점에 왼쪽에서 곱하는 꼴). 양수면 앞(+y)이 아래로 숙는다"""
    c, s = np.cos(np.radians(a)), np.sin(np.radians(a))
    return np.array([[1, 0, 0], [0, c, -s], [0, s, c]])


def rz(a):
    """z축 회전. 양수면 위에서 볼 때 시계 방향(앞 +y가 오른쪽 +x로)"""
    c, s = np.cos(np.radians(a)), np.sin(np.radians(a))
    return np.array([[c, s, 0], [-s, c, 0], [0, 0, 1]])


def ell(c, r, axes=np.eye(3)):
    """축(행)이 axes인 타원체"""
    f = R.ellipsoid([0, 0, 0], r)
    c, axes = np.asarray(c, float), np.asarray(axes, float)
    return lambda p: f((p - c) @ axes.T)


def poly2d(q, V):
    """2D 다각형 V(꼭짓점 차례)까지의 부호 거리(안쪽 음수)"""
    d = ((q - V[0]) ** 2).sum(1)
    s = np.ones(len(q))
    for i in range(len(V)):
        e = V[i - 1] - V[i]
        w = q - V[i]
        b = w - e * np.clip((w @ e) / (e @ e), 0, 1)[:, None]
        d = np.minimum(d, (b * b).sum(1))
        c1, c2, c3 = q[:, 1] >= V[i][1], q[:, 1] < V[i - 1][1], e[0] * w[:, 1] > e[1] * w[:, 0]
        s = np.where((c1 & c2 & c3) | (~c1 & ~c2 & ~c3), -s, s)
    return s * np.sqrt(d)


def sheet(o, e1, e2, pts, t, holes=()):
    """o에서 정규 직교 e1·e2 평면 위 다각형 pts를 두께 t로 두른 판. holes [(가운데, 반지름)]은 뚫는다"""
    o, e1, e2 = (np.asarray(v, float) for v in (o, e1, e2))
    n = np.cross(e1, e2)
    V = np.asarray(pts, float)

    def f(p):
        q = p - o
        uv = np.stack([q @ e1, q @ e2], 1)
        d = poly2d(uv, V)
        for c, r in holes:
            d = np.maximum(d, r - np.linalg.norm(uv - np.asarray(c, float), axis=1))
        return np.maximum(d, np.abs(q @ n) - t)
    return f


# 날개 막 꼴(날개 평면 u 바깥·v 뒤): 어깨 → 팔꿈치 → 손목 → 손가락 끝 셋 사이가 오목하게 팬 박쥐 날개, 몸 옆구리에 붙는다
WING = [(0.0, 0.03), (0.34, 0.07), (0.58, 0.04), (0.92, -0.10), (0.78, -0.22), (0.72, -0.36), (0.56, -0.30), (0.42, -0.44), (0.30, -0.30), (0.0, -0.32)]
TORN = [(0.0, 0.03), (0.34, 0.07), (0.58, 0.04), (0.80, -0.06), (0.66, -0.14), (0.62, -0.30), (0.50, -0.20), (0.36, -0.36), (0.26, -0.22), (0.0, -0.30)]  # 손가락 끝이 꺾이고 막 끝이 찢겨 짧다
TIPS = [(0.92, -0.10), (0.72, -0.36), (0.42, -0.44)]
TORN_TIPS = [(0.80, -0.06), (0.62, -0.30), (0.36, -0.36)]
HOLES = [((0.46, -0.12), 0.06), ((0.20, -0.18), 0.045)]


def body(pose, bob_unit):
    m = MATS.index
    stand = pose["legs"] == "stand"
    lift = np.array([0, 0, 0.0 if stand else 0.08]) + np.array([0, 0, pose["bob"] * bob_unit])
    pivot = np.array([0, -0.05, 0.50])
    tilt = rx(pose["lean"] + (8 if stand else 0))  # 선 몸은 조금 앞으로 숙인다

    def T(p):  # 몸통·목·머리·날개·꼬리: 엉덩이를 축으로 앞숙임, 오르내림
        return pivot + tilt @ (np.asarray(p, float) - pivot) + lift

    P = []
    up = tilt @ np.array([0, 0, 1.0])
    fwd = tilt @ np.array([0, 1.0, 0])
    side = np.array([1.0, 0, 0])
    axes = np.stack([side, fwd, up])
    P += [(ell(T([0, 0.0, 0.52]), (0.19, 0.30, 0.18), axes), m("scale"), "torso"),  # 몸통. v1(0.15)은 앞에서 막대처럼 가늘었다
          (ell(T([0, 0.06, 0.43]), (0.14, 0.25, 0.11), axes), m("belly"), "torso"),  # 배
          (ell(T([0, 0.20, 0.60]), (0.17, 0.16, 0.17), axes), m("scale"), "torso")]  # 가슴
    for k in range(4):  # 등 가시
        P.append((R.capsule(T([0, 0.18 - 0.14 * k, 0.66 - 0.01 * k]), T([0, 0.12 - 0.14 * k, 0.74 - 0.01 * k]), 0.022, 0.006), m("horn"), "torso"))
    # 목·머리: 가슴 앞에서 위로. neck 양수면 머리를 앞아래로 숙인다
    nb = np.array([0, 0.26, 0.64])
    nr = rx(pose["neck"] - 20)
    neck_top = nb + nr @ np.array([0, 0.0, 0.26])
    head_r = rx(pose["neck"] * 0.6)
    hax = np.stack([side, tilt @ head_r @ [0, 1.0, 0], tilt @ head_r @ [0, 0, 1.0]])
    H0 = neck_top + head_r @ np.array([0, 0.06, 0.03])

    def Hd(q):  # 머리 자기 좌표 → 모델
        return T(H0 + head_r @ np.asarray(q, float))
    P += [(R.capsule(T(nb), T(neck_top), 0.10, 0.07), m("scale"), "head"),
          (ell(Hd([0, 0.0, 0.0]), (0.085, 0.11, 0.08), hax), m("scale"), "head"),  # 머리통
          (ell(Hd([0, 0.12, -0.005]), (0.05, 0.08, 0.04), hax), m("scale"), "head")]  # 위턱
    jr = rx(pose["jaw"])
    jax = np.stack([side, tilt @ head_r @ jr @ [0, 1.0, 0], tilt @ head_r @ jr @ [0, 0, 1.0]])
    j0 = np.array([0, 0.04, -0.035])
    P += [(ell(Hd(j0 + jr @ np.array([0, 0.07, -0.01])), (0.042, 0.075, 0.022), jax), m("belly"), "head")]  # 아래턱
    if pose["jaw"] > 15:  # 벌린 입 안
        P.append((ell(Hd([0, 0.10, -0.035]), (0.035, 0.06, 0.02), hax), m("mouth"), "head"))
    for s in (-1, 1):
        P += [(R.capsule(Hd([0.045 * s, -0.04, 0.05]), Hd([0.07 * s, -0.17, 0.10]), 0.022, 0.006), m("horn"), "head"),  # 뿔
              (ell(Hd([0.05 * s, 0.07, 0.025]), (0.016, 0.02, 0.014), hax), m("eye"), "head")]  # 눈
    if pose["flame"]:  # 입 앞 불길: 앞으로 넓어지는 불덩이 셋
        for k, r in enumerate((0.06, 0.09, 0.12, 0.14)):
            P.append((ell(Hd([0, 0.24 + 0.14 * k, -0.04 - 0.03 * k]), (r, r * 1.2, r * 0.8), hax), m("flame"), "head"))
    # 꼬리: 엉덩이 뒤에서 아래로 늘어진 마디 셋과 끝 가시판. tail이 옆으로 휘두른다
    tr = rz(pose["tail"])
    tail = [np.array(p) for p in ([0, -0.26, 0.50], [0, -0.46, 0.45], [0, -0.64, 0.39], [0, -0.80, 0.34])]  # v1(끝 −1.0)은 옆에서 꼬리가 몸을 덮었다
    base = tail[0]
    tail = [base + rz(pose["tail"] * k / 3) @ (p - base) for k, p in enumerate(tail)]
    for k, (a, b) in enumerate(zip(tail, tail[1:])):
        P.append((R.capsule(T(a), T(b), 0.11 - 0.028 * k, 0.082 - 0.028 * k), m("scale"), "tail"))
    tip = tail[-1]
    td = (tail[-1] - tail[-2]) / np.linalg.norm(tail[-1] - tail[-2])
    tside = np.cross(td, [0, 0, 1.0])
    tside /= np.linalg.norm(tside)
    P.append((sheet(T(tip), tilt @ tside, tilt @ td, [(-0.07, 0.0), (0.0, 0.14), (0.07, 0.0), (0.0, -0.03)], 0.012), m("wing"), "tail"))  # 끝 가시판
    # 날개: 어깨에서 날개 평면(바깥으로 wing도 들고, 뒤로 펼침). fold면 바깥 길이가 줄고 아래로 처진다
    for s in (-1, 1):
        sh = np.array([0.12 * s, 0.14, 0.66])
        a = np.radians(pose["wing"])
        out = np.array([s * np.cos(a), 0.10, np.sin(a)])
        out /= np.linalg.norm(out)
        back = np.array([0, -1.0, 0]) - out * (out @ [0, -1.0, 0])
        back /= np.linalg.norm(back)
        k = 1.0 - 0.45 * pose["fold"]
        pts = [(u * k, v * (1.0 - 0.3 * pose["fold"])) for u, v in (TORN if pose["torn"] else WING)]
        tips = [(u * k, v * (1.0 - 0.3 * pose["fold"])) for u, v in (TORN_TIPS if pose["torn"] else TIPS)]
        o, e1, e2 = T(sh), tilt @ out, tilt @ back
        holes = [((u * k, v * (1.0 - 0.3 * pose["fold"])), r) for (u, v), r in HOLES] if pose["torn"] else ()
        P.append((sheet(o, e1, e2, pts, 0.012, holes), m("wing"), "arm"))
        wp = lambda uv: o + e1 * uv[0] + e2 * uv[1]
        elbow, wrist = wp(pts[1]), wp(pts[2])
        P += [(R.capsule(o, elbow, 0.045, 0.035), m("scale"), "arm"), (R.capsule(elbow, wrist, 0.035, 0.028), m("scale"), "arm"),
              (R.capsule(wrist, wrist + e1 * 0.05 + np.array([0, 0.03, 0.03]), 0.02, 0.004), m("horn"), "arm")]  # 손목 발톱
        for tp in tips:
            P.append((R.capsule(wrist, wp(tp), 0.02, 0.008), m("scale"), "arm"))  # 손가락 뼈
    # 다리: 접은 새 다리(1페이즈) · 선 다리(2페이즈, stride로 앞뒤) · 발톱 내밂(claw, 1페이즈 공격·급강하)
    for s in (-1, 1):
        hip = np.array([0.11 * s, -0.08, 0.44])
        if pose["legs"] == "stand":
            sw = rx(-pose["stride"] * s)  # 왼다리(s −1) 앞이 양수
            up_k = 0.08 if pose["lift"] * s > 0 else 0.0  # 통과 자세에서 넘기는 다리(lift 쪽)는 무릎을 들어 굽힌다
            knee = hip + sw @ np.array([0.01 * s, 0.13 + up_k, -0.17 + up_k])
            ankle = hip + sw @ np.array([0.015 * s, 0.02 + up_k, -0.34 + 1.5 * up_k])
            if ankle[2] < 0.06:  # 디딘 발은 땅에, 넘기는 발은 무릎을 굽혀 든다
                ankle[2] = 0.06
            hip_m = T(hip)  # 엉덩이만 윗몸을 따르고, 무릎·발은 땅에 둔다
            foot = ankle + np.array([0, 0.10, -0.045])
        else:
            claw = pose["legs"] == "claw"
            knee = hip + (np.array([0.02 * s, 0.14, -0.10]) if claw else np.array([0.02 * s, 0.10, -0.06]))
            ankle = knee + (np.array([0, 0.10, -0.12]) if claw else np.array([0, -0.12, -0.03]))
            hip_m, knee, ankle = T(hip), T(knee), T(ankle)
            foot = ankle + (tilt @ np.array([0, 0.09, -0.02]))
        P += [(R.capsule(hip_m, knee, 0.07, 0.05), m("scale"), "leg"), (R.capsule(knee, ankle, 0.04, 0.03), m("belly"), "leg")]
        for d in (-0.035, 0.0, 0.035):  # 발가락 셋
            P.append((R.capsule(ankle, foot + np.array([d * 1.4, 0, 0]), 0.022, 0.008), m("horn"), "leg"))
    if pose["fall"]:  # 옆(모델 오른쪽)으로 굴러 눕는다. 땅 아래로 들어간 곳은 잘라 낸다
        f = np.radians(pose["fall"])
        roll = np.array([[np.cos(f), 0, np.sin(f)], [0, 1, 0], [-np.sin(f), 0, np.cos(f)]])
        sink = np.array([0.0, 0.0, 0.2 * np.sin(f)])
        P = [(lambda p, g=g: np.maximum(g((p - sink) @ roll), -p[:, 2]), mat, part) for g, mat, part in P]
    return P


wyvern = H.scaled(body, SCALE)


def fits(kind):
    anims = ANIMS1 if kind == "wyvern" else ANIMS2
    return H.fits(TRIAL / kind, [anims["idle"][0]] + anims["walk"], wyvern, f"{TAG} {kind}", SIZES, span=SPAN)


def bake(kind):
    """정지·걷기·공격과 스킬 자세 시트 → art/trial/<kind>/. 공격은 2배 캔버스(H.save), 스킬 자세는 1배 캔버스다"""
    out = TRIAL / kind
    out.mkdir(parents=True, exist_ok=True)
    fts = fits(kind)
    anims = ANIMS1 if kind == "wyvern" else ANIMS2
    for a in anims:
        H.save(a, a, 45, "D", "f24p", fts, wyvern, BASE, anims, out, PARTS)
    return fts[24]


def preview():
    """검수용 확대본 → art/trial/preview/wyvern_*: 하피·대장 곁 크기 비교와 4방향, 동작 시트"""
    from PIL import Image

    import preview as V
    import slime as S
    pv = TRIAL / "preview"
    fts = {k: fits(k)[24] for k in ("wyvern", "wyvern_fallen")}  # 굽기는 따로(python wyvern.py) 한 뒤 본다
    import json
    others = {k: tuple(json.loads((TRIAL / k / "fit.json").read_text())["fits"]["24"]) for k in ("harpy", "chief")}
    dirs = list(R.DIRS)

    def frame(k, a="idle", d="S", col=0, big=False):
        c = int((fts.get(k) or others[k])[2]) * (2 if big else 1)
        return S.cells(TRIAL / k / f"{a}_45_D_f24p_24.png", c, dirs.index(d))[col]

    rows = []
    for d in ("S", "E", "N", "W"):  # 크기 비교: 하피 · 와이번 · 떨어진 와이번 · 대장을 발밑 줄에
        items = [(frame(k, d=d), fts.get(k) or others[k]) for k in ("harpy", "wyvern", "wyvern_fallen", "chief")]
        top = max(int(f[1][1]) for _, f in items)
        bot = max(int(f[2] - f[1][1]) for _, f in items)
        g = Image.new("RGBA", (sum(im.width + 4 for im, _ in items) + 4, top + bot + 8), (0x2d, 0x47, 0x2d, 255))
        x = 4
        for im, f in items:
            g.alpha_composite(im, (x, 4 + top - int(f[1][1])))
            x += im.width + 4
        rows.append(V.up(g, 4))
    V.stack(rows, gap=6).save(pv / "wyvern_sizes_24.png")
    for k, anims in (("wyvern", ANIMS1), ("wyvern_fallen", ANIMS2)):
        rows = []
        for a in anims:
            big = a == "attack"
            fr = [frame(k, a, d, col, big) for d in ("S", "E", "N", "W") for col in range(len(anims[a]))]
            boxes = [f.getbbox() for f in fr if f.getbbox()]
            x0, y0, x1, y1 = (min(b[0] for b in boxes), min(b[1] for b in boxes), max(b[2] for b in boxes), max(b[3] for b in boxes))
            row = V.up(V.on(R.sheet([f.crop((x0 - 1, y0 - 1, x1 + 1, y1 + 1)) for f in fr], len(fr), gap=3), pad=2), 4)
            rows.append(V.label_rows(row, [a], row.height, width=80))
        V.stack(rows, gap=6).save(pv / f"{k}_sheets_24.png")
    print(*(pv / f"{s}" for s in ("wyvern_sizes_24.png", "wyvern_sheets_24.png", "wyvern_fallen_sheets_24.png")))


if __name__ == "__main__":
    import sys
    if sys.argv[1:] == ["preview"]:
        preview()
        sys.exit()
    for kind in ("wyvern", "wyvern_fallen"):
        ppu, anc, c = bake(kind)
        print(f"{kind} ppu={ppu:.2f} anchor={anc} canvas={c}")
    print("ok")
