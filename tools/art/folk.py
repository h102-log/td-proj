# 마을 주민 가족(S221, S172 2026-10-26 변경): 몸 여섯 × 색 프리셋 여덟의 24px 4방향 시트. 정지 한 장과 걷기 2위상(접지·통과)만 굽는다.
# 몸·색은 시안 (나) v2(insights/2026-10-26_villager_looks.md)다. 뼈대·자세는 기사(hero.py), 굽기는 render.py다
# 시트 한 장이 몸 하나다: look마다 가로 2칸 폭 띠, 위 4행은 정지(1열)·아래 4행은 걷기(2열), 행은 S·E·N·W. atlas.py가 그대로 붙인다
# 사용: python tools/art/folk.py → art/trial/folk/<몸>.png, art/trial/folk/fit.json
import json
from pathlib import Path

import numpy as np
from PIL import Image

import hero as H
import render as R

OUT = Path(__file__).resolve().parents[2] / "art" / "trial" / "folk"
PAL = R.PALETTES["f24p"]
MATS = ["skin", "hair", "cloth", "lower", "scarf", "wood", "shoe"]
PARTS = ["leg", "torso", "head", "arm", "tool"]
ARMS = dict(sh_l=8, el_l=15, ab_l=0.15, sh_r=8, el_r=15, ab_r=0.15)  # 빈손을 내린다(resident.py)
POSES = [dict(H.IDLE, **ARMS)] + [dict(w, **ARMS) for w in H.WALK[:2]]  # 정지, 걷기 접지·통과(atlas.py FOUR_COLS walk)
DIRS = [R.DIRS[d] for d in ("S", "E", "N", "W")]
BIG, BIG_ANC = 40, (20, 28)  # 굽는 캔버스. 모든 몸·프레임이 든 사각형으로 잘라 시트 칸(c)을 정한다

# 몸: 성별(남 바지·맨머리 / 여 발목 치마·머릿수건, 앞머리가 보임), 나이(아이 축소·큰 머리, 여자아이는 치마·맨머리 / 노인 굽은 등·회색 머리·지팡이)
BODIES = {"man": dict(skirt=False, scarf=False, scale=0.9, head=1.0, lean=0, cane=False),
          "woman": dict(skirt=True, scarf=True, scale=0.88, head=1.0, lean=0, cane=False),
          "boy": dict(skirt=False, scarf=False, scale=0.66, head=1.2, lean=0, cane=False),
          "girl": dict(skirt=True, scarf=False, scale=0.66, head=1.2, lean=0, cane=False),
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


def colors(p, old):
    return {"skin": SKIN[p % 3], "hair": OLD_HAIR if old else HAIR[p % 5], "cloth": CLOTH[p % 7], "lower": LOWER[p % 5],
            "scarf": OLD_HAIR if old else SCARF[p % 2], "wood": "8a5530", "shoe": "45230d"}


def make(kind):
    b = BODIES[kind]
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
        if b["skirt"]:  # 발목까지 오는 치마: 허리에서 넓어진다
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
        if b["cane"]:  # 지팡이: 왼손에서 앞아래 땅으로
            hd = U(arms["l"][2])
            P.append((R.capsule(hd + [0, 0, 0.06], np.array([hd[0] - 0.02, hd[1] + 0.06, 0.0]), 0.03), m("wood"), "tool"))
        return P

    return H.scaled(body, b["scale"])


def frame(kind, pose, g, look):
    ramps = [H.ramp(c, PAL) for c in colors(look, kind.startswith("old")).values()]
    idx, _ = H.bake(pose, 45, g, BIG, H.PPU24, BIG_ANC, ramps, "D", R.darkest(PAL), make(kind), PARTS)
    return R.rgba(idx, PAL)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    frames = {k: [[[frame(k, pose, g, p) for pose in POSES] for g in DIRS] for p in range(LOOKS)] for k in BODIES}
    box = None  # 모든 프레임의 불투명 픽셀을 덮는 사각형
    for k in frames:
        for look in frames[k]:
            for row in look:
                for im in row:
                    bb = im.getbbox()
                    box = bb if box is None else (min(box[0], bb[0]), min(box[1], bb[1]), max(box[2], bb[2]), max(box[3], bb[3]))
    c = max(box[2] - box[0], box[3] - box[1])
    x0, y0 = box[0] - (c - (box[2] - box[0])) // 2, box[3] - c
    for k in frames:
        sheet = Image.new("RGBA", (LOOKS * 2 * c, 8 * c))
        for p, look in enumerate(frames[k]):
            for d, row in enumerate(look):
                cells = [row[0].crop((x0, y0, x0 + c, y0 + c))] + [im.crop((x0, y0, x0 + c, y0 + c)) for im in row[1:]]
                sheet.paste(cells[0], (p * 2 * c, d * c))
                for q, cell in enumerate(cells[1:]):
                    sheet.paste(cell, (p * 2 * c + q * c, (4 + d) * c))
        sheet.save(OUT / f"{k}.png")
    (OUT / "fit.json").write_text(json.dumps({"c": c, "anchor": [BIG_ANC[0] - x0, BIG_ANC[1] - y0]}) + "\n", encoding="utf-8")
    print("c", c, "anchor", BIG_ANC[0] - x0, BIG_ANC[1] - y0)


if __name__ == "__main__":
    main()
