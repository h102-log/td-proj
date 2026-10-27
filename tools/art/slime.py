# 1라운드 슬라임 4종(꼬마·보통·큰·킹)의 3D 형체와 스프라이트 굽기(insights/2026-10-27_round1_slime.md 3.5). 한 형체를 크기만 바꾸고,
# 킹은 큰 슬라임보다 키워 왕관을 얹는다. 크기가 곧 «몇 번 더 갈라지나»다(enemy_theme_research/06_readability.md 3·6장).
# 방향이 없어 게임은 남쪽 한 행만 쓴다(atlas.py ONE). 걷기는 눌림·늘어남, 공격은 크게 눌렸다 튀어 오름, 쓰러짐은 퍼져 납작해진다
# 사용: python tools/art/slime.py [preview]  → art/trial/<종류>/, 확대본은 art/trial/preview/slime_*
import shutil
import tempfile
from pathlib import Path

import numpy as np

import hero as H
import render as R

TRIAL = Path(__file__).resolve().parents[2] / "art" / "trial"
KINDS = {"slimelet": (0.18, False), "slime": (0.3, False), "big_slime": (0.45, False), "slime_king": (0.55, True)}  # 종류 → (게임 몸 반지름 칸, 왕관)
WIDE = 1.25  # 그림 반폭 = 게임 몸 반지름(칸 16px) × 이 배. 색 원(battle_view.gd _round_body)보다 조금 크게
# 몸 색 후보: (팔레트 램프 [안쪽 외곽선, 음영 0~3], 윤기 점 색). 공 모양은 밝은 칸(음영 3)이 몸 절반을 덮어 색이 바래서,
# 음영 2·3을 같은 본색으로 두고 왼쪽 위에 작은 윤기 점을 따로 얹는다
GELS = {"blue": (["262d3d", "3a4357", "56607a", "4f78ad", "4f78ad"], "d0d6e0"),
        "amber": (["724113", "ab5c1c", "ab5c1c", "efac28", "efac28"], "efd8a1"),
        "red": (["550f0a", "9b1a0a", "9b1a0a", "ef3a0c", "ef3a0c"], "efb775")}
GEL = "blue"


def base(gel=GEL):
    ramp, shine = GELS[gel]
    return {"gel": ramp, "shine": [shine] * 5, "eye": ["151a26"] * 5, "gold": ["724113", "ab5c1c", "efac28", "efac28", "efd8a1"]}


BASE = base()
MATS = list(BASE)
PARTS = ["body", "eye", "crown"]
SIZES = (24,)
IDLE = dict(sx=1.0, sz=1.0, up=0.0)  # sx 가로 배율, sz 세로 배율, up 뜬 높이(반폭 단위)
WALK = [dict(sx=1.12, sz=0.86, up=0.0), dict(sx=0.92, sz=1.12, up=0.0)] * 2  # 눌림·늘어남. 아틀라스는 0·1열
ATTACK = [dict(sx=1.25, sz=0.7, up=0.0), dict(sx=0.86, sz=1.2, up=0.12), dict(sx=1.1, sz=0.9, up=0.0)]  # 크게 눌림 → 튀어 오름(타격) → 내려앉음
FALL = [dict(sx=1.1 + 0.13 * k, sz=s, up=0.0, shut=k >= 2) for k, s in enumerate((0.8, 0.55, 0.35, 0.22, 0.14))]  # 퍼져 납작, 눈을 감는다. 아틀라스는 4열(웅덩이)
ANIMS = {"idle": [IDLE], "walk": WALK, "attack": ATTACK, "fall": FALL}


def blob(r_cells, crown):
    """게임 몸 반지름 r_cells칸 슬라임의 형체. 아래 20%를 잘라 바닥이 평평한 반타원 몸, 앞쪽 눈 둘, crown이면 왕관"""
    w = r_cells * WIDE * 16 / H.PPU24  # 모델 단위 반폭

    def model(pose, bob_unit):
        m = MATS.index
        a, h, z0 = w * pose["sx"], w * 0.85 * pose["sz"], w * pose["up"]
        cz = z0 + 0.8 * h
        r = np.array([a, 0.9 * a, h])
        P = [(R.cut_above(R.ellipsoid([0, 0, cz], r), z0), m("gel"), "body")]
        px = 0.7 / H.PPU24  # 0.7px. 꼬마도 눈·윤기가 1px은 남게
        e = max(0.1 * a, px)
        y = 0.9 * a * np.sqrt(1 - 0.33 ** 2 - 0.2 ** 2)  # 몸 앞면(눈 높이·옆 자리에서)
        for s in (-1, 1):  # 감은 눈은 가로 줄
            P.append((R.ellipsoid([0.33 * a * s, y, cz + 0.2 * h], (1.4 * e, 0.6 * e, px) if pose.get("shut") else (e, 0.6 * e, 1.4 * e)), m("eye"), "eye"))
        u = np.array([-0.45, 0.4, 0.65])  # 윤기 점: 빛 쪽(왼쪽 위·앞) 몸 겉면
        P.append((R.ellipsoid([0, 0, cz] + u / np.linalg.norm(u / r), (max(0.17 * a, px), max(0.1 * a, px), max(0.1 * h, px))), m("shine"), "body"))
        if crown:  # 정수리 앞쪽에 선 얇은 판과 뾰족 셋. 앞뒤로 두꺼운 띠는 45°에서 윗면이 네모로 읽혔다
            top, fy = cz + h, 0.2 * a
            P.append((R.box([0, fy, top - 0.05 * h], (0.32 * a, 0.05 * a, 0.14 * h), rnd=0.01), m("gold"), "crown"))
            for x in (-0.22 * a, 0.0, 0.22 * a):
                P.append((R.capsule([x, fy, top], [x, fy, top + 0.55 * h], 0.09 * a, 0.015 * a), m("gold"), "crown"))
        return P
    return model


def fits(kind, out=None):
    r, crown = KINDS[kind]
    return H.fits(out or TRIAL / kind, [IDLE] + WALK, blob(r, crown), f"m5 ppu{H.PPU24} slime1 {kind} w{WIDE}", SIZES)


def bake(kind, out=None, base=BASE, anims=tuple(ANIMS)):
    """종류 하나의 시트(anims)와 fit.json → out(기본 art/trial/<종류>/). → 24px 맞춤"""
    out = out or TRIAL / kind
    out.mkdir(parents=True, exist_ok=True)
    fts = fits(kind, out)
    for anim in anims:
        H.save(anim, anim, 45, "D", "f24p", fts, blob(*KINDS[kind]), base, ANIMS, out, PARTS)
    return fts[24]


def cells(path, n, row=0):
    """시트 한 행 → 프레임들"""
    from PIL import Image
    im = Image.open(path)
    return [im.crop((q * n, row * n, (q + 1) * n, (row + 1) * n)) for q in range(im.width // n)]


def idle(folder, c):
    return cells(folder / "idle_45_D_f24p_24.png", c)[0]


def lineup(items):
    """[(정지 남쪽 그림, 맞춤)]을 발밑 줄에 나란히. 왼쪽 반은 풀, 오른쪽 반은 흙 바닥(tools/art/tiles.py RAMPS 가운데 색)"""
    from PIL import Image
    gap = 4
    top = max(f[1][1] for _, f in items)
    bot = max(f[2] - f[1][1] for _, f in items)
    w = sum(im.width for im, _ in items) + gap * (len(items) + 1)
    g = Image.new("RGBA", (w, top + bot + 2 * gap), (0x2d, 0x47, 0x2d, 255))
    g.paste((0x68, 0x4c, 0x3c, 255), (w // 2, 0, w, g.height))
    x = gap
    for im, f in items:
        g.alpha_composite(im, (x, gap + top - f[1][1]))
        x += im.width + gap
    return g


def preview():
    """검수용 확대본 → art/trial/preview/slime_*: 색 후보, 크기 비교(고블린·오우거 곁), 동작 줄, 킹 웅크림·뜸·착지"""
    from PIL import Image, ImageDraw

    import goblin as B
    import ogre as O
    import preview as V
    pv = TRIAL / "preview"
    fts = {k: bake(k) for k in KINDS}
    others = [(idle(B.OUT, B.fits()[24][2]), B.fits()[24]), (idle(O.OUT, O.fits()[24][2]), O.fits()[24])]
    # 색 후보: 줄마다 GELS 하나로 정지만 굽는다(맞춤은 위에서 구한 것을 옮겨 쓴다)
    rows = []
    with tempfile.TemporaryDirectory() as tmp:
        for gel in GELS:
            items = []
            for k, f in fts.items():
                out = Path(tmp) / gel / k
                out.mkdir(parents=True)
                shutil.copy(TRIAL / k / "fit.json", out / "fit.json")
                bake(k, out, base(gel), ("idle",))
                items.append((idle(out, f[2]), f))
            rows.append(V.up(lineup(items + others[:1]), 5))
    V.label_rows(V.stack(rows, gap=8), list(GELS), rows[0].height + 8, width=60).save(pv / "slime_color_options.png")
    V.up(lineup([(idle(TRIAL / k, f[2]), f) for k, f in fts.items()] + others), 5).save(pv / "slime_sizes_24.png")
    # 동작 줄: 종류마다 정지·걷기 2·공격 3·쓰러짐 5. 캔버스가 달라서 가장 큰 칸(2c)에 발밑을 맞춰 넣는다
    c = max(f[2] for f in fts.values())
    rows = []
    for k, f in fts.items():
        n, fr = f[2], []
        for anim in ANIMS:
            big = anim in ("attack", "fall")
            for im in cells(TRIAL / k / f"{anim}_45_D_f24p_24.png", 2 * n if big else n)[:(2 if anim == "walk" else None)]:
                g = Image.new("RGBA", (2 * c, 2 * c), (0, 0, 0, 0))
                g.alpha_composite(im, (c - n, c - n) if big else (c - n // 2, c - n // 2))
                fr.append(g)
        rows.append(R.sheet(fr, len(fr), gap=2))
    V.up(V.on(V.stack(rows, gap=4, bg=V.FIELD), pad=4), 4).save(pv / "slime_anims_24.png")
    # 킹: 정지 / 웅크림 끝(그리기 변형 가로 1.15·세로 0.75, battle_view.gd CROUCH) / 뜬 한가운데(10px 위, 그림자) / 구운 크게 눌림(공격 0열)
    k = fts["slime_king"]
    n, anc = k[2], k[1]
    still = idle(TRIAL / "slime_king", n)
    foot = (n // 2 + int(anc[0]), n // 2 + int(anc[1]))
    g = Image.new("RGBA", (8 * n, 2 * n), V.FIELD)
    g.alpha_composite(still, (n // 2, n // 2))
    g.alpha_composite(still.resize((round(n * 1.15), round(n * 0.75)), Image.NEAREST),
                      (2 * n + foot[0] - round(anc[0] * 1.15), foot[1] - round(anc[1] * 0.75)))
    shadow = Image.new("RGBA", (n, n // 3), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).ellipse((0, 0, n - 1, n // 3 - 1), fill=(0, 0, 0, 77))
    g.alpha_composite(shadow, (4 * n + foot[0] - n // 2, foot[1] - n // 6))
    g.alpha_composite(still, (4 * n + n // 2, n // 2 - 10))
    g.alpha_composite(cells(TRIAL / "slime_king" / "attack_45_D_f24p_24.png", 2 * n)[0], (6 * n, 0))
    V.up(g, 5).save(pv / "slime_king_poses_24.png")
    print(*(pv / f"slime_{s}.png" for s in ("color_options", "sizes_24", "anims_24", "king_poses_24")))


if __name__ == "__main__":
    import sys
    if sys.argv[1:] == ["preview"]:
        preview()
        sys.exit()
    for kind in KINDS:
        ppu, anc, c = bake(kind)
        print(f"{kind} ppu={ppu:.2f} anchor={anc} canvas={c}")
    print("ok")
