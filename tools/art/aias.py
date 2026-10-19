# 아이아스(강철의 성채. SPEC S157에서 기사 자리를 이은 3성 탱커 aias)의 3D 형체와 스프라이트 굽기. 컨셉은 art/concept/aias/(사용자 승인 2026-10-19).
# 뼈대·배율과 정지·걷기·쓰러짐 자세는 기사(hero.py) 것을 쓰고, 창 기울기와 찌르기 공격만 새로 정했다(WBS 4.1d 인간형 공용 뼈대). 오른손 창, 왼손 탑 방패. 45°·외곽선 D·f24p·유닛 24px(사용자 2026-10-18)
# 사용: python tools/art/aias.py [preview]  → art/trial/aias/ 에 정지·걷기·공격·쓰러짐 시트(preview: art/trial/preview/aias_*). 검사: python tools/art/lint.py walk_45_D_f24p aias
from pathlib import Path

import numpy as np

import chronos as C
import hero as H
import render as R

OUT = Path(__file__).resolve().parents[2] / "art" / "trial" / "aias"
# 값이 hex 하나면 자동 램프, 5개 목록이면 손 램프(안쪽 외곽선, 음영 0~3. hero.ramp)
# 강철: 자동(98a2b4, 기사 강철)은 음영 1단이 파랑(4f78ad)이라 탑 방패가 파란 방패로 보였다. 컨셉 강철색(7a86a0·3a4357)으로 바꿨다
BASE = {"steel": ["262d3d", "3a4357", "7a86a0", "a4aec2", "d0d6e0"],
        "dark": "56607a",
        # 진홍: 자동(9b1a0a)은 음영 1단이 갈색(773421)이라 북동 망토가 갈색이었고, 밝은 단계 ef3a0c는 몸을 젖힌 공격 준비에서 망토를 주황으로 칠했다
        "crimson": ["300f0a", "300f0a", "550f0a", "9b1a0a", "9b1a0a"],
        "gold": ["2a1d0d", "724113", "ab5c1c", "efac28", "efd8a1"],
        "wood": ["2a1d0d", "45230d", "724113", "a56243", "a56243"],
        "visor": "1b2030"}
MATS = list(BASE)
PARTS = ["leg", "torso", "head", "arm", "spear", "shield"]
SIZES = (24,)
TAG = f"m5 ppu{H.PPU24} aias2"  # 형체 크기를 바꾸면 이 꼬리표도 바꾼다(fit.json)

# 창은 거의 세워 들고 앞으로 5°만 기울인다. 15°였을 때 남동·동에서 창이 몸통·방패 앞을 대각선으로 가로질렀다(Gemini 4차 2026-10-19).
# 창 든 오른손을 바깥으로 1.5px쯤 더 벌려(ab_r 0.7 → 1.1) 창 자루가 오른팔 바깥 실루엣에 붙어 내려오게 한다.
# 바깥 기울기는 0이다. 10°면 동에서 창이 카메라 쪽으로 누워 짧아지고 창끝이 투구 높이에 붙었다. -8°는 남에서 창 밑동이 바깥으로 삐져나왔다
SPEAR = dict(sword=5, sword_side=0)
IDLE = dict(H.IDLE, **SPEAR, ab_r=1.1)
WALK = [dict(w, **SPEAR, ab_r=1.1) for w in H.WALK]
# 공격은 창 찌르기: 창을 허리 높이에서 뒤로 당겼다가(준비) 팔을 뻗고 반 발 내디디며 찌르고(가운데가 타격 프레임) 반쯤 거둔다(마무리).
# 방패 팔은 정지 자세 그대로 앞을 막는다
ATTACK = [dict(IDLE, sh_r=-60, el_r=55, ab_r=0.3, sword=88, sword_side=-5, lean=-6),
          # 찌르기 프레임은 창을 손 안에서 앞으로 0.15 밀어낸다(reach). S·N은 찌르는 방향이 카메라 축이라 창끝 이동이 짧아 보였다(Gemini 4차 2026-10-19)
          dict(IDLE, sh_r=80, el_r=0, ab_r=0.2, sword=84, sword_side=-5, lean=12, hip_r=14, knee_r=10, hip_l=-10, knee_l=10, reach=0.15),
          dict(IDLE, sh_r=-25, el_r=95, ab_r=0.25, sword=95, sword_side=-5, lean=3)]
# 쓰러짐은 기사 자세를 쓰되, 창은 셋째 프레임부터 놓치고 방패는 넷째 프레임부터 몸 옆 바닥에 눕는다. 방패를 팔에 둔 채 누우면
# 누운 몸 위에 금테 상자가 얹힌 것처럼 보였다
FALL = [dict(f, **SPEAR) for f in H.FALL[:2]] + [dict(H.FALL[2], spear=0)] + [dict(f, spear=0, shield="ground") for f in H.FALL[3:]]
TIP = 0.96  # 손에서 창끝까지. 컨셉 비례보다 길게 해 남(정면)에서도 창끝이 깃 위로 나온다
SMEAR = "d0d6e0"  # 찌르기 잔상 색
ANIMS = {"idle": [IDLE], "walk": WALK, "attack": ATTACK, "fall": FALL}


def aias(pose, bob_unit):
    U, G, up_r, legs, arms = H.rig(pose, bob_unit)
    m = MATS.index
    P = []  # (sdf, 재질, 부위)
    for side in "lr":  # 다리: 판금, 철신
        hip, knee, ankle = legs[side]
        P += [(R.capsule(G(hip), G(knee), 0.055), m("steel"), "leg"), (R.capsule(G(knee), G(ankle), 0.05), m("steel"), "leg"),
              (R.ellipsoid(G(ankle + [0, 0.035, -0.005]), (0.044, 0.07, 0.034)), m("dark"), "leg")]
    P += [(R.box(U([0, 0, 0.575]), (0.125, 0.08, 0.12), up_r, 0.035), m("steel"), "torso"),  # 흉갑
          (R.box(U([0, 0, 0.455]), (0.13, 0.085, 0.022), up_r), m("gold"), "torso"),  # 금 허리띠
          (R.box(U([0, 0, 0.40]), (0.125, 0.08, 0.05), up_r, 0.02), m("crimson"), "torso"),  # 진홍 띠 치마
          (R.box(U([0, -0.1, 0.43]), (0.14, 0.012, 0.25), up_r, 0.01), m("crimson"), "torso")]  # 망토
    helm = R.ellipsoid(U([0, -0.005, 0.81]), (0.145, 0.14, 0.14))  # 얼굴을 가린 투구
    cut_p, cut_n = U([0, 0, 0.70]), up_r @ [0, 0, 1]
    P.append((lambda p: np.maximum(helm(p), -((p - cut_p) @ cut_n)), m("steel"), "head"))
    P += [(R.box(U([0, 0.125, 0.815]), (0.08, 0.025, 0.03), up_r), m("visor"), "head"),  # T자 눈구멍: 가로
          (R.box(U([0, 0.13, 0.75]), (0.025, 0.02, 0.05), up_r), m("visor"), "head"),  # 세로
          (R.ellipsoid(U([0, -0.03, 0.96]), (0.035, 0.15, 0.075)), m("crimson"), "head")]  # 진홍 깃
    for side, s in (("l", -1), ("r", 1)):  # 팔: 견갑, 판금 팔, 건틀릿
        sh, el, hd = arms[side]
        P += [(R.ellipsoid(U(sh + [0.01 * s, 0, 0.015]), (0.085, 0.08, 0.06)), m("steel"), "torso"),
              (R.capsule(U(sh), U(el), 0.044), m("steel"), "arm"), (R.capsule(U(el), U(hd), 0.042), m("steel"), "arm"),
              (R.ellipsoid(U(hd), (0.045, 0.045, 0.045)), m("dark"), "arm")]
    bd, _, _ = H.blade_axes(pose, up_r)  # 창은 기사의 검과 같은 방향 값으로 든다
    hd = U(arms["r"][2]) + bd * pose.get("reach", 0)  # 창 기준점. 찌르기에서 손 안의 창을 앞으로 민다
    P += [] if not pose.get("spear", 1) else [
          (R.capsule(hd - bd * 0.5, hd + bd * 0.76, 0.03), m("wood"), "spear"),  # 자루: 반지름 0.03이면 폭이 1px을 넘어 화소 사이로 빠지지 않는다
          (R.capsule(hd + bd * 0.74, hd + bd * 0.82, 0.014, 0.032), m("steel"), "spear"),
          (R.capsule(hd + bd * 0.82, hd + bd * TIP, 0.032, 0.004), m("steel"), "spear"),
          (R.ellipsoid(hd + bd * 0.71, (0.03, 0.03, 0.03)), m("crimson"), "spear")]  # 진홍 술
    _, el_l, hd_l = arms["l"]
    n = up_r @ (np.array([-0.3, 1.0, 0]) / np.linalg.norm([-0.3, 1.0, 0]))  # 방패 앞면
    zz = up_r @ np.array([0, 0, 1.0])
    c = U((el_l + hd_l) / 2 + [0, 0, -0.14]) + n * 0.04
    ax = np.stack([zz, n, np.cross(zz, n)])
    shield = pose.get("shield", "arm")
    if shield == "ground":  # 놓친 방패가 몸 왼쪽 바닥에 눕는다(쓰러짐)
        n, ax = np.array([0, 0, 1.0]), np.array([[0, 1.0, 0], [0, 0, 1.0], [1.0, 0, 0]])
        c = np.array([-0.27, 0.12, 0.026])
    if not shield:
        return P
    P += [(R.box(c, (0.30, 0.025, 0.13), ax, 0.015), m("gold"), "shield"),  # 금 테두리
          (R.box(c + n * 0.008, (0.26, 0.025, 0.095), ax, 0.01), m("steel"), "shield"),
          (R.ellipsoid(c + n * 0.035, (0.045, 0.045, 0.045)), m("gold"), "shield")]  # 성채 문장
    return P


def tip(pose):
    """창끝의 모델 좌표"""
    U, _, up_r, _, arms = H.rig(pose, 0)
    bd, _, _ = H.blade_axes(pose, up_r)
    return U(arms["r"][2]) + bd * (TIP + pose.get("reach", 0))


def screen(p, g, ppu, anchor, elev=45):
    """모델 좌표 → 시트 프레임 안 픽셀 좌표(render.trace와 같은 사영)"""
    cam = R.Cam(elev)
    face = cam.facing(*g)
    w = np.stack([[face[1], -face[0], 0], [face[0], face[1], 0], [0, 0, 1.0]]).T @ p
    return np.array([anchor[0] + (w @ cam.u) * ppu - 0.5, anchor[1] - (w @ cam.v) * ppu - 0.5])


def smear(fts):
    """찌르기 프레임(가운데)에 준비 → 찌르기 창끝 길을 따라 밝은 잔상 두 줄을 빈칸에만 긋는다.
    Gemini가 기사 공격을 두고 «공격 잔상이 없다», «3프레임 사이 검이 90° 넘게 뛰어 방향이 안 읽힌다»고 했고(2026-10-18 1차·10-19 3차),
    근접 영웅을 만들 때 넣기로 했다(사용자 2026-10-19).
    반투명은 lint H5가 막아서 팔레트의 가장 밝은 강철색으로 칠하고 외곽선은 두지 않는다"""
    from PIL import Image
    pal = R.PALETTES["f24p"]
    color = [int(SMEAR[i:i + 2], 16) for i in (0, 2, 4)] + [255]
    for n, (ppu, anc, c) in fts.items():
        c2, a = 2 * c, (anc[0] + c / 2, anc[1] + c / 2)
        path = OUT / f"attack_45_D_f24p_{n}.png"
        im = np.array(Image.open(path))
        for r, g in enumerate(R.DIRS.values()):
            p0, p1 = screen(tip(ATTACK[0]), g, ppu, a), screen(tip(ATTACK[1]), g, ppu, a)
            u = (p1 - p0) / np.linalg.norm(p1 - p0)
            # 자루 외곽선과 잔상 사이에 바탕 1px을 띄운다(±3.5). 외곽선에 붙이면(±1.5) 창끝이 삼지창처럼 보였고, ±2.5는 S·N에서 자루에 붙은
            # 흰 얼룩으로 읽혔다(Gemini 4차 2026-10-19). 준비 창끝 4px 뒤에서 찌르기 창끝 2px 앞까지
            for off in (-3.5, 3.5):
                for t in np.arange(-4, np.linalg.norm(p1 - p0) - 2, 0.25):
                    x, y = np.round(p0 + u * t + np.array([-u[1], u[0]]) * off).astype(int)
                    if 0 < x < c2 - 1 and 0 < y < c2 - 1 and im[r * c2 + y, c2 + x, 3] == 0:
                        im[r * c2 + y, c2 + x] = color
        assert {tuple(q) for q in im[im[..., 3] == 255][:, :3]} <= {tuple(q) for q in pal}
        Image.fromarray(im).save(path)


def fits():
    return H.fits(OUT, [IDLE] + WALK, aias, TAG, SIZES)


def preview():
    """검수용 확대본 → art/trial/preview/aias_*. 정지 비교는 위부터 기사, 크로노스, 아이아스"""
    H.preview("aias", OUT, fits()[24], [(H.OUT, H.fits()[24]), (C.OUT, C.fits()[24])])


if __name__ == "__main__":
    import sys
    if sys.argv[1:] == ["preview"]:
        preview()
        sys.exit()
    OUT.mkdir(parents=True, exist_ok=True)
    fts = fits()
    for n, (ppu, anc, c) in fts.items():
        print(f"n={n} ppu={ppu:.2f} anchor={anc} canvas={c}")
    for anim in ANIMS:
        H.save(anim, anim, 45, "D", "f24p", fts, aias, BASE, ANIMS, OUT, PARTS)
    smear(fts)
    print("ok")
