# 마을 주민 가족(S221, S172 2026-10-26·27 변경): 몸 여덟 × 색 프리셋 여덟의 24px 시트. 정지·걷기 2위상(4방향)과 직업의 일 자세(S223)를 굽는다.
# 몸·색·자세는 시안 (나) v2(insights/2026-10-26_villager_looks.md)다. 뼈대는 기사(hero.py), 굽기는 render.py다
# 시트 한 장이 몸 하나다: look마다 가로 2칸 폭 띠. 0~3행 정지(1열)·4~7행 걷기(2열)이고 행은 S·E·N·W다. 그 아래로 몸이 쓰는 일 자세가
# 차례로 붙는다: 제자리 자세는 동·서 2행, 들고 걷기(carry_)는 S·E·N·W 4행이고 모두 2열(2프레임)이다. 자세별 첫 행은 fit.json의 rows다.
# 남자 시트에는 아홉째 띠(look 8)로 사제(검은 겉옷)의 정지·걷기·서서 젓기를 더한다. atlas.py가 그대로 붙인다
# 사용: python tools/art/folk.py → art/trial/folk/<몸>.png, art/trial/folk/fit.json
import json
from pathlib import Path

import numpy as np
from PIL import Image

import hero as H
import render as R

OUT = Path(__file__).resolve().parents[2] / "art" / "trial" / "folk"
PAL = R.PALETTES["f24p"]
MATS = ["skin", "hair", "cloth", "lower", "scarf", "wood", "shoe", "iron", "clay", "sack", "flame"]
PARTS = ["leg", "torso", "head", "arm", "tool"]
ARMS = dict(sh_l=8, el_l=15, ab_l=0.15, sh_r=8, el_r=15, ab_r=0.15)  # 빈손을 내린다(resident.py)
POSES = [dict(H.IDLE, **ARMS)] + [dict(w, **ARMS) for w in H.WALK[:2]]  # 정지, 걷기 접지·통과(atlas.py FOUR_COLS walk)
DIRS = [R.DIRS[d] for d in ("S", "E", "N", "W")]
SIDE = [R.DIRS[d] for d in ("E", "W")]  # 제자리 일 자세는 일터 쪽 동·서만 본다(I182 ⑧)
BIG, BIG_ANC = 48, (24, 34)  # 굽는 캔버스. 모든 몸·프레임이 든 사각형으로 잘라 시트 칸(c)을 정한다


def P(**kw):
    return dict(H.IDLE, **dict(ARMS, sword_side=0, **kw))  # 도구는 앞으로 든다. 기사 정지의 바깥 45°를 물려받으면 동쪽에서 카메라 쪽으로 누워 몸에 묻혔다


# 일 자세(S172 2026-10-27 변경): 이름 → 2프레임. tool은 손에 든 것, drop이면 발이 땅에 닿게 몸 전체를 내린다(쪼그림·앉음), stool이면 엉덩이 밑에 걸상
STRIKE = [dict(sh_r=150, el_r=20, sh_l=140, el_l=25, ab_l=0.05, ab_r=0.05, lean=-4, sword=-80),  # 내려치기: 들어 올림
          dict(sh_r=62, el_r=8, sh_l=58, el_l=12, ab_l=0.05, ab_r=0.05, lean=14, sword=105, hip_r=14, knee_r=10)]  # 내려침
WORK = {
    "hoe": [P(tool="hoe", **k) for k in STRIKE],
    "hammer": [P(tool="hammer", **k) for k in STRIKE],
    "axe": [P(tool="axe", **k) for k in STRIKE],
    "squat": [P(drop=True, hip_l=105, hip_r=95, knee_l=145, knee_r=135, lean=28, sh_l=80, el_l=10, sh_r=85, el_r=5),
              P(drop=True, hip_l=105, hip_r=95, knee_l=145, knee_r=135, lean=24, sh_l=60, el_l=35, sh_r=95, el_r=0)],
    "sit": [P(drop=True, stool=True, hip_l=88, hip_r=88, knee_l=90, knee_r=90, sh_l=35, el_l=70, sh_r=40, el_r=75, tool="spindle", sword=20),
            P(drop=True, stool=True, hip_l=88, hip_r=88, knee_l=90, knee_r=90, sh_l=40, el_l=60, sh_r=55, el_r=55, tool="spindle", sword=35)],
    "stir": [P(sh_r=70, el_r=40, sh_l=30, el_l=50, lean=4), P(sh_r=100, el_r=10, sh_l=40, el_l=40, lean=2)],
    "saw": [P(tool="saw", log=True, sh_r=75, el_r=15, sh_l=40, el_l=50, lean=18, sword=120, hip_r=20, knee_r=10),
            P(tool="saw", log=True, sh_r=35, el_r=75, sh_l=40, el_l=50, lean=10, sword=95, hip_r=20, knee_r=10)],
    "fish": [P(drop=True, hip_l=85, hip_r=85, knee_l=8, knee_r=8, lean=-6, sh_r=55, el_r=20, sh_l=50, el_l=30, tool="rod", sword=35),
             P(drop=True, hip_l=85, hip_r=85, knee_l=8, knee_r=8, lean=-6, sh_r=62, el_r=15, sh_l=55, el_l=25, tool="rod", sword=48)],
}
CARRY = {  # 들고 걷기: 걷기 2위상에 팔·짐만 바꾼다
    "carry_water": dict(sh_l=168, el_l=25, ab_l=0.35, load="jar"),
    "carry_sack": dict(sh_r=165, el_r=70, ab_r=0.3, load="sack"),
    "carry_basket": dict(sh_r=14, el_r=40, ab_r=0.35, load="basket"),
    "carry_lantern": dict(sh_r=50, el_r=35, ab_r=0.2, load="lantern"),
    "carry_stick": dict(sh_r=30, el_r=20, ab_r=0.3, load="stick", sword=150),
}
for k, v in CARRY.items():
    WORK[k] = [dict(w, **dict(ARMS, sword_side=0, **v)) for w in H.WALK[:2]]
ADULT = ["hoe", "fish", "axe", "saw", "hammer", "sit", "stir", "carry_sack", "carry_lantern", "carry_water", "squat", "carry_basket"]
# 몸이 굽는 일 자세: 그 몸의 역할(I182 ①)이 맡는 직업의 자세(battle_view.gd POSE). man·woman은 가장·배우자, 아이, 노인. 청소년은 어른 직업을 얻는다(S232)
USES = {"man": ADULT, "woman": ADULT, "boy": ["squat", "carry_stick", "carry_water"], "girl": ["squat", "carry_stick", "carry_water"],
        "old_man": ["sit", "squat", "carry_basket"], "old_woman": ["sit", "squat", "carry_basket"], "lad": ADULT, "lass": ADULT}
PRIEST = 8  # 남자 시트 아홉째 띠: 사제(S222)

# 몸: 성별(남 바지·맨머리 / 여 발목 치마·머릿수건, 앞머리가 보임)은 아이 때부터 같다(S172 2026-10-27 둘째 변경),
# 나이(아이 축소·큰 머리 / 청소년은 아이와 어른 사이(S232) / 노인 굽은 등·회색 머리·지팡이)
BODIES = {"man": dict(skirt=False, scarf=False, scale=0.9, head=1.0, lean=0, cane=False),
          "woman": dict(skirt=True, scarf=True, scale=0.88, head=1.0, lean=0, cane=False),
          "boy": dict(skirt=False, scarf=False, scale=0.66, head=1.2, lean=0, cane=False),
          "girl": dict(skirt=True, scarf=True, scale=0.66, head=1.2, lean=0, cane=False),
          "lad": dict(skirt=False, scarf=False, scale=0.78, head=1.1, lean=0, cane=False),
          "lass": dict(skirt=True, scarf=True, scale=0.77, head=1.1, lean=0, cane=False),
          "old_man": dict(skirt=False, scarf=False, scale=0.86, head=1.0, lean=16, cane=True),
          "old_woman": dict(skirt=True, scarf=True, scale=0.84, head=1.0, lean=16, cane=True)}

# 2026-10-26
# [동작] 색 프리셋 p(0~7)는 피부 p%3·머리 p%5·웃옷 p%7·바지나 치마 p%5·머릿수건 p%2로 고른다. 노인은 머리·머릿수건이 회색이다
# [의도] 한 가족이 피부색을 같이 쓰게(S221) 피부를 p%3에 묶었다. battle.gd가 가족의 look을 같은 나머지에서 고른다
# [이유] 웃옷은 아군 청록·흙·물과, 적 빨강·풀에 묻히는 초록을 뺀 시안 v2 색이다(Gemini 2단계, art/trial/preview/villager_looks/feedback_2.md).
#        773421은 자동 램프가 빨강을 섞어 황토 ab5c1c로 바꿨다
SKIN = ["e8b090", "c8906a", "a56243"]
HAIR = ["4a2c18", "2a1d0d", "ab5c1c", "efac28", "927e6a"]
CLOTH = ["4f78ad", "a56243", "efd8a1", "7a86a0", "ab5c1c", "927e6a", "efb775"]
LOWER = ["70462a", "262d3d", "3a4357", "392a1c", "45230d"]
SCARF = ["efd8a1", "d0d6e0"]  # 젊은 여자는 따뜻한 크림·회백, 노인 머리·머릿수건은 차가운 회색(OLD_HAIR)과 가른다
OLD_HAIR = "a4aec2"
LOOKS = 8
TOOLS = {"wood": "8a5530", "iron": "56607a", "clay": "a56243", "sack": "927e6a", "flame": "efac28"}  # 도구·짐 색(F24+ 근처)


def colors(p, old):
    if p == PRIEST:  # 사제: 검은 겉옷이 발목까지(S172 2026-10-27 변경)
        return dict({"skin": SKIN[0], "hair": HAIR[1], "cloth": "262d3d", "lower": "262d3d", "scarf": SCARF[0], "shoe": "45230d"}, **TOOLS)
    c = {"skin": SKIN[p % 3], "hair": OLD_HAIR if old else HAIR[p % 5], "cloth": CLOTH[p % 7], "lower": LOWER[p % 5],
         "scarf": OLD_HAIR if old else SCARF[p % 2], "shoe": "45230d"}
    return dict(c, **TOOLS)


def make(kind, robe=False):
    b = dict(BODIES[kind], skirt=BODIES[kind]["skirt"] or robe)
    m = MATS.index

    def body(pose, bob_unit):
        pose = dict(pose, lean=pose.get("lean", 0) + b["lean"])
        U, G, up_r, legs, arms = H.rig(pose, bob_unit)
        P = []
        for side in "lr":
            hip, knee, ankle = legs[side]
            P += [(R.capsule(G(hip), G(knee), 0.05), m("lower"), "leg"), (R.capsule(G(knee), G(ankle), 0.045), m("lower"), "leg"),
                  (R.ellipsoid(G(ankle + [0, 0.035, -0.005]), (0.04, 0.065, 0.03)), m("shoe"), "leg")]
        hk = b["head"]
        P.append((R.box(U([0, 0, 0.56]), (0.11, 0.07, 0.13), up_r, 0.035), m("cloth"), "torso"))
        if b["skirt"]:  # 발목까지 오는 치마(사제는 겉옷): 허리에서 넓어진다
            P.append((H.local(U, up_r, lambda q: H.flare(q, 0.47, 0.03, 0.11, 0.19)), m("lower"), "torso"))
        else:  # 웃옷 자락
            P.append((H.local(U, up_r, lambda q: H.flare(q, 0.46, 0.36, 0.11, 0.125)), m("cloth"), "torso"))
        hc = U([0, 0, 0.69 + 0.11 * hk])
        P.append((R.ellipsoid(hc, (0.12 * hk, 0.115 * hk, 0.125 * hk)), m("skin"), "head"))
        face = R.box(U([0, 0.1, 0.69 + 0.07 * hk]), (0.09 * hk, 0.1, 0.08 * hk), up_r)
        hair = R.ellipsoid(U([0, -0.015, 0.69 + 0.125 * hk]), (0.127 * hk, 0.122 * hk, 0.12 * hk))
        P.append((lambda p: np.maximum(hair(p), -face(p)), m("hair"), "head"))
        if b["scarf"]:  # 머릿수건: 뒤로 물러 앞머리가 이마에 1~2px 보이고, 뒤로 목까지 내려온다
            cap = R.ellipsoid(U([0, -0.05, 0.69 + 0.115 * hk]), (0.138 * hk, 0.125 * hk, 0.138 * hk))
            tail = R.ellipsoid(U([0, -0.08, 0.66]), (0.1, 0.065, 0.09))
            P.append((lambda p: np.maximum(np.minimum(cap(p), tail(p)), -face(p)), m("scarf"), "head"))
        for side in "lr":
            sh, el, hd = arms[side]
            P += [(R.capsule(U(sh), U(el), 0.04), m("cloth"), "arm"), (R.capsule(U(el), U(hd), 0.036), m("skin"), "arm"),
                  (R.ellipsoid(U(hd), (0.036, 0.036, 0.036)), m("skin"), "arm")]
        if b["cane"] and not pose.get("tool") and not pose.get("load"):  # 지팡이: 왼손에서 앞아래 땅으로. 일할 때는 내려놓는다
            hd = U(arms["l"][2])
            P.append((R.capsule(hd + [0, 0, 0.06], np.array([hd[0] - 0.02, hd[1] + 0.06, 0.0]), 0.03), m("wood"), "tool"))
        P += gear(pose, U, up_r, arms, hk, m)
        drop = 0.0
        if pose.get("drop"):  # 쪼그림·앉음: 낮은 발목이 선 자세의 발목 높이(0.03)에 오게 몸 전체를 내린다
            drop = min(G(legs[s][2])[2] for s in "lr") - 0.03
        if pose.get("stool"):  # 걸상: 내린 뒤의 땅에서 엉덩이 밑까지
            P.append((R.box([0, -0.03, (drop + 0.35) / 2], (0.075, 0.07, (0.35 - drop) / 2)), m("wood"), "tool"))
        if drop:
            P = [(lambda p, f=f: f(p + np.array([0, 0, drop])), mat, part) for f, mat, part in P]
        return P

    return H.scaled(body, b["scale"])


def gear(pose, U, up_r, arms, hk, m):
    """손에 든 도구와 짐(S172 2026-10-27 변경)"""
    out = []
    hd = U(arms["r"][2])
    bd, side, third = H.blade_axes(pose, up_r)
    axes = np.array([side, third, bd])
    tool, load = pose.get("tool"), pose.get("load")
    if tool in ("hoe", "hammer", "axe"):  # 자루 + 쇠 머리. 괭이는 길고 머리가 앞으로 꺾이고, 망치·도끼는 짧다
        n = {"hoe": 0.42, "hammer": 0.2, "axe": 0.3}[tool]
        out.append((R.capsule(hd - bd * 0.05, hd + bd * n, 0.018), m("wood"), "tool"))
        head = {"hoe": (0.02, 0.07, 0.025), "hammer": (0.035, 0.055, 0.035), "axe": (0.015, 0.06, 0.05)}[tool]
        out.append((R.box(hd + bd * n + third * (0.04 if tool == "hoe" else 0.0), head, axes), m("iron"), "tool"))
    elif tool == "saw":  # 톱날 + 받침 위 통나무
        out.append((R.box(hd + bd * 0.14, (0.008, 0.035, 0.14), axes), m("iron"), "tool"))
    elif tool == "spindle":  # 실 감는 가락
        out.append((R.capsule(hd - bd * 0.04, hd + bd * 0.12, 0.014), m("wood"), "tool"))
        out.append((R.ellipsoid(hd + bd * 0.06, (0.03, 0.03, 0.03)), m("sack"), "tool"))
    elif tool == "rod":  # 낚싯대와 늘어진 줄
        tip = hd + bd * 0.4
        out.append((R.capsule(hd - bd * 0.05, tip, 0.014), m("wood"), "tool"))
        out.append((R.capsule(tip, tip + np.array([0, 0.02, -0.3]), 0.008), m("sack"), "tool"))
    if pose.get("log"):
        out.append((R.box([0, 0.3, 0.3], (0.17, 0.05, 0.05)), m("wood"), "tool"))
        out.append((R.box([0, 0.3, 0.13], (0.03, 0.04, 0.13)), m("wood"), "tool"))
    if load == "jar":  # 머리에 인 물동이
        out.append((R.ellipsoid(U([0, 0, 0.69 + 0.235 * hk + 0.06]), (0.075, 0.075, 0.065)), m("clay"), "tool"))
    elif load == "sack":  # 어깨에 멘 자루
        out.append((R.ellipsoid(U([0.1, -0.02, 0.86]), (0.1, 0.09, 0.08)), m("sack"), "tool"))
    elif load == "basket":  # 손에 든 바구니
        out.append((R.box(hd + np.array([0, 0.01, -0.06]), (0.06, 0.05, 0.04), np.eye(3), 0.01), m("wood"), "tool"))
    elif load == "lantern":  # 앞으로 든 등불: 쇠테 안 불
        out.append((R.box(hd + np.array([0, 0.02, -0.07]), (0.03, 0.03, 0.04), np.eye(3), 0.005), m("iron"), "tool"))
        out.append((R.ellipsoid(hd + np.array([0, 0.05, -0.07]), (0.022, 0.022, 0.028)), m("flame"), "tool"))
    elif load == "stick":  # 거위 모는 막대
        out.append((R.capsule(hd - bd * 0.05, hd + bd * 0.42, 0.014), m("wood"), "tool"))
    return out


def frame(kind, pose, g, look):
    ramps = [H.ramp(c, PAL) for c in colors(look, kind.startswith("old")).values()]
    idx, _ = H.bake(pose, 45, g, BIG, H.PPU24, BIG_ANC, ramps, "D", R.darkest(PAL), make(kind, look == PRIEST), PARTS)
    return R.rgba(idx, PAL)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    frames, rows = {}, {}
    for k in BODIES:
        looks = list(range(LOOKS)) + ([PRIEST] if k == "man" else [])
        poses = [(p, WORK[p], DIRS if p.startswith("carry") else SIDE) for p in USES[k]]
        rows[k], r = {}, 8
        for p, _, dirs in poses:
            rows[k][p] = r
            r += len(dirs)
        frames[k] = {"rows": r, "looks": {}}
        for p in looks:
            band = {"idle": [frame(k, POSES[0], g, p) for g in DIRS], "walk": [[frame(k, w, g, p) for w in POSES[1:]] for g in DIRS]}
            for name, two, dirs in poses:
                if p != PRIEST or name == "stir":
                    band[name] = [[frame(k, w, g, p) for w in two] for g in dirs]
            frames[k]["looks"][p] = band
    box = None  # 모든 프레임의 불투명 픽셀을 덮는 사각형
    for k in frames:
        for band in frames[k]["looks"].values():
            for name, v in band.items():
                for im in (v if name == "idle" else [x for row in v for x in row]):
                    bb = im.getbbox()
                    box = bb if box is None else (min(box[0], bb[0]), min(box[1], bb[1]), max(box[2], bb[2]), max(box[3], bb[3]))
    c = max(box[2] - box[0], box[3] - box[1])
    x0, y0 = box[0] - (c - (box[2] - box[0])) // 2, box[3] - c
    cut = lambda im: im.crop((x0, y0, x0 + c, y0 + c))
    for k in frames:
        sheet = Image.new("RGBA", (len(frames[k]["looks"]) * 2 * c, frames[k]["rows"] * c))
        for b, band in enumerate(frames[k]["looks"].values()):
            ox = b * 2 * c
            for d, im in enumerate(band["idle"]):
                sheet.paste(cut(im), (ox, d * c))
            for d, row in enumerate(band["walk"]):
                for q, im in enumerate(row):
                    sheet.paste(cut(im), (ox + q * c, (4 + d) * c))
            for name in band:
                if name in ("idle", "walk"):
                    continue
                for d, row in enumerate(band[name]):
                    for q, im in enumerate(row):
                        sheet.paste(cut(im), (ox + q * c, (rows[k][name] + d) * c))
        sheet.save(OUT / f"{k}.png")
    (OUT / "fit.json").write_text(json.dumps({"c": c, "anchor": [BIG_ANC[0] - x0, BIG_ANC[1] - y0], "rows": rows}) + "\n", encoding="utf-8")
    print("c", c, "anchor", BIG_ANC[0] - x0, BIG_ANC[1] - y0)


if __name__ == "__main__":
    main()
