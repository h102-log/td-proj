# 크로노스(시간 지휘자. SPEC S157에서 장군 자리를 이은 금 등급 chronos)의 3D 형체와 스프라이트 굽기. 컨셉은 art/concept/chronos/(사용자 2026-10-18: 장군 외형으로 쓴다).
# 뼈대·배율과 정지·걷기·쓰러짐 자세는 기사(hero.py)와 같고, 공격만 원거리 동작이다(WBS 4.1d 인간형 공용 뼈대). 45°·외곽선 D·f24p·유닛 24px(사용자 2026-10-18)
# 사용: python tools/art/chronos.py [preview]  → art/trial/chronos/ 에 정지·걷기·공격·쓰러짐 시트(preview: art/trial/preview/chronos_*). 검사: python tools/art/lint.py walk_45_D_f24p chronos
from pathlib import Path

import numpy as np

import hero as H
import render as R

OUT = Path(__file__).resolve().parents[2] / "art" / "trial" / "chronos"
# 값이 hex 하나면 자동 램프, 5개 목록이면 손 램프(안쪽 외곽선, 음영 0~3. hero.ramp)
BASE = {"skin": "e8b090",
        "hair": "b8c0d0",  # 은발. c8cede는 밝은 면이 크림(efd8a1)이 돼서 차가운 회색만 쓰는 값으로 낮췄다
        # 자동(33446e)은 그늘이 외곽선 색(151a26)이라 실루엣이 녹았다. 밝은 면을 파랑(4f78ad)으로 두니 북동 등판만 파랗고
        # 북은 회색이라 다른 옷처럼 보여(Gemini 3차 2026-10-19) 회청(7a86a0)으로 바꿨다
        "coat": ["151a26", "262d3d", "3a4357", "56607a", "7a86a0"],
        # 하의는 외곽선과 비슷해 어두운 바닥에서 하반신이 묻힐 수 있다(Gemini 3차 2026-10-19). 바지·부츠 모두 한 단계 밝혔다
        "trouser": ["151a26", "262d3d", "3a4357", "3a4357", "56607a"],
        "boot": ["151a26", "262d3d", "262d3d", "3a4357", "3a4357"],  # 외곽선 D(151a26)에 묻히지 않게 262d3d부터
        "teal": "3c9f9c",  # 아군 팀 색(art_direction_research README 결론 2 B): 조끼·가슴 시계·지휘봉 끝·모래시계 유리
        "gold": ["2a1d0d", "724113", "ab5c1c", "efac28", "efd8a1"],  # 자동(d0a038)은 넓은 금속 면의 그늘이 탁한 갈색(684c3c·927e6a)이었다
        "ivory": ["262d3d", "7a86a0", "a4aec2", "efd8a1", "efd8a1"],  # 장갑·지휘봉·크라바트. 자동은 안쪽 외곽선이 짙은 초록(183f39)이었다
        "eye": "1b2030"}
MATS = list(BASE)
PARTS = ["leg", "torso", "head", "arm", "baton", "hourglass"]
SIZES = (24,)  # 유닛 24px(사용자 2026-10-18). 16·32는 시험 비교용이었다
TAG = f"m5 ppu{H.PPU24} tails hourglass1.3"  # 형체 크기를 바꾸면 이 꼬리표도 바꾼다(fit.json)

# 모래시계를 띄우는 왼팔: 앞보다 옆으로 벌린다. 앞으로 내밀면(sh_l 30, ab_l 0.5) 북동·북에서 모래시계가 화면상 머리 바로 뒤에 와서
# 받침이 머리 위로 나와 왕관처럼 보였다. 옆으로 벌려도 손 위 0.18에 띄우면 동·북동에서 몸 뒤(북쪽)에 있는 모래시계가 머리 위로
# 2px 나와 왕관·뿔처럼 보였다(Gemini 3차 2026-10-19). 팔을 조금 펴(el_l 40 → 20) 손을 낮추고 모래시계를 손 바로 위(0.04)에 둔다.
# 이러면 8방향 모두 모래시계 꼭대기가 머리 꼭대기보다 높지 않다
L_ARM = dict(sh_l=15, el_l=20, ab_l=0.8)
HG_UP = 0.04  # 왼손에서 모래시계 가운데까지 높이
# 정지·걷기의 지휘봉은 기사의 검 자세(앞 18°, 바깥 45°)에서 앞으로 더 기울인다. 18°면 동에서는 지휘봉이 몸 앞에 묻혀
# 맨손처럼 보였고 서에서는 수직으로 섰다(Gemini 3차 2026-10-19). 35°에서 동은 앞으로 뻗고 서는 대각선이 된다
BATON = dict(sword=35)
IDLE = dict(H.IDLE, **L_ARM, **BATON)
WALK = [dict(w, **L_ARM, **BATON) for w in H.WALK]
# 공격은 원거리(S121 사거리 3, 사용자 2026-10-18): 지휘봉을 곧게 치켜들었다가(준비) 팔과 함께 과녁 쪽으로 곧게 뻗어 쏘고(발사, 가운데가
# 타격 프레임) 조금 더 내린다(마무리). 기사의 내려치기와 달리 발을 내딛지 않는다. 각도는 지휘봉이 몸 실루엣 밖으로 나온 픽셀이 8방향 중
# 가장 적은 방향에서도 3·5·3px가 되게 격자로 재서 골랐다(기사 자세를 빌렸을 때는 0·1·2px). 팔을 벌려 비스듬히 들면(sh_r 150·ab_r 0.5)
# 45°에서 팔이 화면 아래로 내려와 동·북에서 지휘봉이 머리에 묻혔다. 발사 프레임만 끝 구슬을 1.6배로 키운다. 2배는 철퇴 머리처럼 보였다.
# 준비 프레임은 2026-10-19에 지휘봉을 뒤(-30°)·바깥(20°)으로 눕혔다. 곧게 세우면(sword -5) 북에서 준비·발사가 둘 다 위를 가리켜
# 구분되지 않았다(Gemini 3차). 이제 남·북에서 준비는 대각선, 발사는 과녁 쪽 수직이다. 바깥으로만 눕히면(30°) 동에서 지휘봉이 사라졌다
ATTACK = [dict(H.POSE, **L_ARM, sh_r=180, el_r=0, ab_r=0.4, sword=-30, sword_side=20, lean=-6),
          dict(H.POSE, **L_ARM, sh_r=85, el_r=0, ab_r=0.35, sword=85, lean=8, tip=1.6),
          dict(H.POSE, **L_ARM, sh_r=70, el_r=15, ab_r=0.35, sword=100, sword_side=15, lean=4)]
# 쓰러짐은 기사 자세를 쓰되, 모래시계는 둘째 프레임부터 사라지고 지휘봉은 셋째 프레임부터 놓친다. 기사 그대로면 누운 몸에서
# 지휘봉이 검처럼 꺾여 나오고, 모래시계가 머리에 노란 혹처럼 붙어 있었다(Gemini 3차 2026-10-19)
FALL = [H.FALL[0], dict(H.FALL[1], hg=0)] + [dict(f, hg=0, baton=0) for f in H.FALL[2:]]
ANIMS = {"idle": [IDLE], "walk": WALK, "attack": ATTACK, "fall": FALL}


def chronos(pose, bob_unit):
    U, G, up_r, legs, arms = H.rig(pose, bob_unit)
    m = MATS.index
    up = up_r @ np.array([0, 0, 1.0])
    P = []  # (sdf, 재질, 부위)
    for side in "lr":  # 다리: 바지, 부츠. 무릎 금 덮개는 24px에서 다리 위 금 점 잡음이라 뺐다
        hip, knee, ankle = legs[side]
        P += [(R.capsule(G(hip), G(knee), 0.052), m("trouser"), "leg"), (R.capsule(G(knee), G(ankle), 0.05), m("boot"), "leg"),
              (R.ellipsoid(G(ankle + [0, 0.035, -0.005]), (0.042, 0.068, 0.032)), m("boot"), "leg")]
    P += [(R.box(U([0, 0, 0.575]), (0.12, 0.075, 0.12), up_r, 0.035), m("coat"), "torso"),  # 몸통(코트)
          (R.box(U([0, 0.07, 0.555]), (0.034, 0.012, 0.085), up_r), m("teal"), "torso"),  # 조끼
          (R.box(U([0, 0, 0.455]), (0.125, 0.08, 0.022), up_r), m("trouser"), "torso"),  # 허리띠
          (R.box(U([0, 0.082, 0.455]), (0.03, 0.01, 0.02), up_r), m("gold"), "torso"),  # 버클
          (R.box(U([0, 0, 0.415]), (0.11, 0.07, 0.04), up_r, 0.02), m("coat"), "torso")]
    for s in (-1, 1):  # 연미복 꼬리: 허리 뒤에서 정강이까지, 아래가 바깥·뒤로 벌어진다
        ez = np.array([-0.18 * s, 0.2, 1.0]) / np.linalg.norm([0.18, 0.2, 1.0])
        ey = np.array([0, 1.0, 0]) - ez[1] * ez
        ey /= np.linalg.norm(ey)
        ax = np.stack([up_r @ np.cross(ey, ez), up_r @ ey, up_r @ ez])
        P.append((R.box(U([0.062 * s, -0.1, 0.31]), (0.06, 0.012, 0.16), ax, 0.01), m("coat"), "torso"))
    P += [(R.box(U([0, -0.03, 0.715]), (0.095, 0.03, 0.05), up_r, 0.015), m("coat"), "torso"),  # 높은 목깃(목 뒤)
          (R.ellipsoid(U([0, 0.055, 0.645]), (0.09, 0.04, 0.045)), m("gold"), "torso"),  # 금 목가리개
          (R.ellipsoid(U([0, 0.092, 0.64]), (0.03, 0.012, 0.03)), m("teal"), "torso"),  # 가슴 시계
          (R.box(U([0, 0.075, 0.69]), (0.03, 0.02, 0.025), up_r), m("ivory"), "torso")]  # 크라바트
    # 머리: 투구 없이 쓸어 넘긴 은발. 45°에서는 정수리가 머리 화면의 위 절반을 차지해서, 이마까지 덮으면 얼굴이 1.5px만 남았다.
    # 그래서 머리칼은 높이 0.88 위의 정수리 뒤와 옆만 덮고, 눈·외알 안경·수염도 기사 눈구멍처럼 위로 올렸다
    P.append((R.ellipsoid(U([0, 0, 0.80]), (0.125, 0.12, 0.13)), m("skin"), "head"))
    hair = R.ellipsoid(U([0, -0.022, 0.818]), (0.138, 0.135, 0.128))
    face = R.box(U([0, 0.1, 0.775]), (0.1, 0.1, 0.105), up_r)
    P.append((lambda p: np.maximum(hair(p), -face(p)), m("hair"), "head"))
    P += [(R.ellipsoid(U([0.045, 0.113, 0.82]), (0.02, 0.012, 0.022)), m("eye"), "head"),  # 오른눈
          (R.ellipsoid(U([-0.045, 0.115, 0.82]), (0.028, 0.012, 0.028)), m("gold"), "head"),  # 외알 안경(왼눈)
          (R.box(U([0, 0.112, 0.77]), (0.045, 0.01, 0.01), up_r), m("hair"), "head"),  # 콧수염
          (R.ellipsoid(U([0, 0.09, 0.72]), (0.03, 0.025, 0.035)), m("hair"), "head")]  # 턱수염
    for side, s in (("l", -1), ("r", 1)):  # 팔: 금 견갑 원반, 남색 소매, 오른손 흰 장갑·왼손 금 장갑
        sh, el, hd = arms[side]
        P += [(R.ellipsoid(U(sh + [0.008 * s, 0, 0.012]), (0.088, 0.085, 0.045)), m("gold"), "torso"),
              (R.capsule(U(sh), U(el), 0.042), m("coat"), "arm"), (R.capsule(U(el), U(hd), 0.04), m("coat"), "arm"),
              (R.ellipsoid(U(hd), (0.042, 0.042, 0.042)), m("ivory" if side == "r" else "gold"), "arm")]
    hd = U(arms["r"][2])
    bd, _, _ = H.blade_axes(pose, up_r)  # 지휘봉은 기사의 검과 같은 방향으로 든다
    tip = 0.038 * pose.get("tip", 1)  # 끝 청록 구슬. 공격 발사 프레임만 키워 쏘는 순간을 보인다(기본 1배면 값이 그대로다)
    if pose.get("baton", 1):  # 쓰러짐 뒤쪽 프레임은 지휘봉을 놓친다(FALL)
        P += [(R.capsule(hd - bd * 0.04, hd + bd * 0.3, 0.024), m("ivory"), "baton"),
              (R.ellipsoid(hd + bd * (0.33 + (tip - 0.038)), (tip, tip, tip)), m("teal"), "baton")]
    # 왼손 위에 뜬 모래시계: 금 받침 둘, 청록 유리 둘. 컨셉 비례(약 0.26)로는 2×3px이라 1.3배로 키웠다
    hc = U(arms["l"][2]) + up * HG_UP
    for k in (-1, 1) if pose.get("hg", 1) else ():  # 쓰러지면 모래시계가 사라진다(FALL)
        P += [(R.box(hc + up * 0.135 * k, (0.072, 0.072, 0.02), up_r, 0.01), m("gold"), "hourglass"),
              (R.ellipsoid(hc + up * 0.065 * k, (0.055, 0.055, 0.075)), m("teal"), "hourglass")]
    # 광륜(등 뒤 천문시계 고리)은 넣지 않는다. 몸을 두르는 고리(반지름 0.29)는 인물보다 먼저 읽혔고, 머리 뒤 반원(0.2)은
    # 머리에서 1px 떨어진 금테가 돼 투구 테두리처럼 보였다(2026-10-18). 광륜은 이펙트(오라 원, S113)에서 살린다
    return P


def fits():
    return H.fits(OUT, [IDLE] + WALK, chronos, TAG, SIZES)


def preview():
    """검수용 확대본 → art/trial/preview/chronos_*. 정지 비교는 위 기사, 아래 크로노스"""
    H.preview("chronos", OUT, fits()[24], [(H.OUT, H.fits()[24])])

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
        H.save(anim, anim, 45, "D", "f24p", fts, chronos, BASE, ANIMS, OUT, PARTS)
    print("ok")
