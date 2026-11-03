# 3라운드 고블린 약탈단 새 적 9종의 3D 형체와 스프라이트 굽기(insights/2026-10-27_round3_goblin.md 3.11). 시안 단계라 정지만 굽고, MOVES에 둔 종류는 걷기·공격도 굽는다.
# 사람형(폭파병·글라이더·대장)은 고블린 시트(goblin.py) 몸에 부착물을 붙이고, 기계·하늘 탈것은 상자·캡슐·타원체로 짓고 작은 고블린을 태운다.
# 색은 고블린 테마(잿빛 피부·어두운 빨강 넝마)에 나무·쇠·기운 천을 더한다. 마법 표지는 두지 않는다(사용자 2026-10-27 결정 0)
# 사용: python tools/art/raid.py [preview]  → art/trial/<종류>/, 확대본은 art/trial/preview/raid_*
from pathlib import Path

import numpy as np

import goblin as B
import hero as H
import render as R

TRIAL = Path(__file__).resolve().parents[2] / "art" / "trial"
GOB = {"skin": B.BASE["skin"], "rag": B.BASE["rag"], "wood": B.BASE["wood"], "eye": B.BASE["eye"]}  # 고블린 몸 재질(순서가 B.MATS와 같아야 한다)
BASE = dict(GOB,
            plank=["151a26", "2a1d0d", "45230d", "724113", "724113"],  # 그을린 판자. 천·판자는 v2보다 두 칸 어둡게(Gemini 2026-11-02 «유원지 목재 장난감»)
            dark=["151a26", "2a1d0d", "36170c", "45230d", "45230d"],  # 바퀴·화약통
            iron=["151a26", "262d3d", "3a4357", "56607a", "7a86a0"],
            canvas=["151a26", "2a1d0d", "392a1c", "684c3c", "684c3c"],  # 기운 천(지붕·풍선·날개), 회갈색
            red=["300f0a", "300f0a", "550f0a", "9b1a0a", "9b1a0a"],  # 대장·전쟁 기계에만 쓴다(Gemini 2026-11-02 «강조색 남발»).
            # 음영 2칸을 탁한 적갈색(773421)으로 바꿨더니 «빨강 = 보스» 신호가 약해져(Gemini 2026-11-02 v5·v6 평가) 되돌렸다. 넓은 천의 단조로움은 얼룩·땜질·찢김으로 깬다
            brass=["2a1d0d", "724113", "ab5c1c", "efac28", "efd8a1"],
            rope=["392a1c", "684c3c", "927e6a", "efb775", "efb775"],
            light=["7a86a0", "a4aec2", "d0d6e0", "d0d6e0", "d0d6e0"],  # 밝은 쇠·돌(쇠테·돌·가시·프로펠러)
            horn=["392a1c", "927e6a", "efd8a1", "efd8a1", "efd8a1"],
            flame=["ab5c1c", "ef692f", "efac28", "efd8a1", "efd8a1"],
            bomb=["151a26", "151a26", "262d3d", "3a4357", "56607a"],
            smoke=["3a4357", "56607a", "7a86a0", "a4aec2", "a4aec2"],  # 전쟁 기계 연기: 검은 배기통·쇠 차체와 명도가 갈리게 밝게
            hole=["151a26", "151a26", "151a26", "151a26", "151a26"],  # 포구 구멍: 빛을 받아도 검게
            ember=["550f0a", "ab5c1c", "ef692f", "efac28", "efac28"],  # 화실 불씨: flame은 정면에서 크림색 네모로 떴다
            copper=["2a1d0d", "550f0a", "773421", "a56243", "a56243"],  # 보일러 통
            soot=["151a26", "151a26", "151a26", "262d3d", "3a4357"])  # 배기통. 보일러·배기통·팔이 모두 쇠색이면 뒷모습에서 뭉쳤다(Gemini 2026-11-02 v7 평가)
MATS = list(BASE)
assert MATS[:len(B.MATS)] == B.MATS
PARTS = B.PARTS + ["gear", "hull"]
SIZES = (24,)
TAG = f"m5 ppu{H.PPU24} raid30"
IDLE = B.IDLE
# 종류 → (형체를 만드는 함수 이름, 크기 배율, 맞춤 폭 span, 나는가). 망치·공성탑 배율과 전쟁 기계·비행선 형체 크기는
# Gemini 권장(art/trial/preview/gemini_raid/feedback_3.md 표)을 따랐고, 대장 배율은 사용자 값, 나머지는 Claude 시안 값이다
KINDS = {"sapper": ("sapper", 0.8, 3.0, False), "ram": ("ram", 1.25, 5.0, False), "catapult": ("catapult", 1.0, 4.0, False),
         "siege_tower": ("tower", 1.3, 8.5, False), "glider": ("glider", 0.8, 4.0, True), "balloon": ("balloon", 1.0, 5.0, True),
         "airship": ("airship", 1.0, 8.0, True), "war_machine": ("war_machine", 1.0, 8.0, False), "chief": ("chief", 4.0, 11.0, False),  # 대장 4배: 2페이즈는 홀로 남은 왕이라 «엄청 강하게»(사용자 2026-11-02 «크기 4배»). 앞 값 2.5는 Gemini 권장 가로 2칸 × 세로 2.5칸이었다
         "wreck": ("wreck", 1.0, 8.0, False)}  # 전쟁 기계 잔해: 전쟁 기계와 같은 배율


def m(name):
    return MATS.index(name)


def place(prims, s, at, yaw=0.0):
    """형체 목록을 s배로 키워 at에 놓는다. yaw는 위에서 본 반시계 회전(도)"""
    c, sn = np.cos(np.radians(yaw)), np.sin(np.radians(yaw))
    rot = np.array([[c, -sn, 0], [sn, c, 0], [0, 0, 1.0]])
    at = np.asarray(at, float)
    return [(lambda p, f=f: s * f(((p - at) @ rot) / s), mat, part) for f, mat, part in prims]


def lift(P, dz):
    """형체 목록을 dz만큼 올린다. 걷기 통과 자세(bob)에서 바퀴 위 차체·하늘 탈것을 1px 덜컹·출렁이게 한다"""
    return [(lambda p, f=f: f(p - np.array([0, 0, dz])), mat, part) for f, mat, part in P] if dz else P


def crew(s, at, yaw=0.0, pose=IDLE, club=False):
    """작은 고블린 하나(고블린 시트 몸, 고블린 기본 0.8배에 s를 곱한 크기)"""
    body = [q for q in B.body(pose, 0) if club or q[2] != "club"]
    return place(body, 0.8 * s, at, yaw)


def tilt_y(a):
    """y축 회전 행렬의 행(상자 축). 양수면 상자 x축이 아래로 기운다"""
    c, s = np.cos(np.radians(a)), np.sin(np.radians(a))
    return np.array([[c, 0, -s], [0, 1, 0], [s, 0, c]])


def tilt_x(a):
    """x축 회전 행렬의 행(상자 축). 양수면 상자 y축이 위로 든다"""
    c, s = np.cos(np.radians(a)), np.sin(np.radians(a))
    return np.array([[1, 0, 0], [0, c, s], [0, -s, c]])


def wheel(x, y, r, w=0.045, hub=True, mat="dark"):
    """x 방향으로 납작한 바퀴와 쇠 굴대"""
    P = [(R.ellipsoid([x, y, r], (w, r, r)), m(mat), "hull")]
    if hub:
        P.append((R.ellipsoid([x + np.sign(x) * w, y, r], (0.02, 0.35 * r, 0.35 * r)), m("iron"), "hull"))
    return P


def flag(x, y, z0, h, side=1, mat="rag", size=1.0):
    """막대 끝 깃발(약탈단 표지). 빨강은 전쟁 기계만 쓴다"""
    return [(R.capsule([x, y, z0], [x, y, z0 + h], 0.016 * size), m("wood"), "gear"),
            (R.box([x + side * 0.1 * size, y, z0 + h - 0.07 * size], (0.1 * size, 0.012, 0.065 * size)), m(mat), "gear")]


def patch(shell, c, half, axes=np.eye(3)):
    """곡면 위 덧댄 천 조각: 조금 큰 껍질(shell)과 상자 영역이 겹친 부분. 평평한 판은 곡면에서 모서리가 뜬다"""
    reg = R.box(c, half, axes)
    return lambda p: np.maximum(shell(p), reg(p))


# ── 사람형 ───────────────────────────────────────────

def keg(at, spark=0.035):
    """화약통(밝은 쇠테·넝마 띠)과 도화선 불꽃. at: 통 가운데 기준 오프셋 → 월드 좌표"""
    return ([(R.ellipsoid(at([0, 0, 0]), (0.17, 0.155, 0.23)), m("dark"), "gear")]  # 화약통: 시안 v1의 1.3배(Gemini 2026-11-02)
            + [(R.ellipsoid(at([0, 0, dz]), (0.175, 0.16, 0.025)), m("light"), "gear") for dz in (-0.13, 0.13)]
            + [(R.ellipsoid(at([0, 0, 0]), (0.176, 0.161, 0.03)), m("rag"), "gear"),  # 넝마 띠
               (R.capsule(at([0, 0, 0.22]), at([0.05, -0.06, 0.32]), 0.014), m("rope"), "gear"),  # 도화선
               (R.ellipsoid(at([0.055, -0.07, 0.35]), (spark, spark, spark + 0.005)), m("flame"), "gear")])


def sapper(pose, bob_unit):
    """폭파병: 고블린 + 등에 진 큰 화약통(밝은 쇠테·넝마 띠, 머리 위로 솟음), 몸 밖으로 내민 왼손 횃불(몽둥이 없음).
    공격(pose에 fuse)은 화약통을 앞 왼쪽 땅에 내려놓고 그 곁에 쪼그린다(설계 문서 3.11 «도화선이 타는 동안 쪼그린 자세»). 팔과 횃불 방향(torch)은 자세가 정한다"""
    fuse = pose.get("fuse")
    p = pose if fuse else dict(pose, sh_l=35, el_l=40, ab_l=0.9)
    U, G, _, legs, arms = H.rig(p, bob_unit)
    P = [q for q in B.body(p, bob_unit) if q[2] != "club"]
    if not fuse:
        P += keg(lambda v: U(np.array([0, -0.23, 0.76]) + v))
    hd = U(arms["l"][2])
    t = np.asarray(pose["torch"], float) if fuse else np.array([0, 0.03, 0.2])
    P += [(R.capsule(hd - [0, 0, 0.05] if not fuse else hd - t * 0.25, hd + t, 0.024), m("wood"), "gear"),
          (R.ellipsoid(hd + [0, 0.04, 0.3] if not fuse else hd + t * 1.5, (0.075, 0.075, 0.11)), m("flame"), "gear")]  # 횃불을 키워 몸 밖으로
    if fuse:  # 쪼그림: 낮은 발목이 선 자세의 발목 높이(0.03)에 오게 몸 전체를 내린다(folk.py drop과 같다)
        drop = min(G(legs[s][2])[2] for s in "lr") - 0.03
        P = [(lambda q, f=f: f(q + np.array([0, 0, drop])), mat, part) for f, mat, part in P]
        P += keg(lambda v: np.array([*pose["keg"], 0.23]) + v, spark=fuse)
    return P


def glider(pose, bob_unit):
    """글라이더 고블린: 가로대를 쥐고 매달린 고블린 + 위의 뒤로 꺾인 삼각 천 날개(안쪽 기운 천, 날개 끝 넝마), 가운데 용골.
    걷기 통과 자세(bob)에서 1px 출렁이며 늘어뜨린 다리를 바꾼다. 공격(pose의 landed)은 내린 뒤 날개를 등에 접어 멘 고블린의 몽둥이 내려치기다(사용자 2026-11-02)"""
    if pose.get("landed"):
        U = H.rig(pose, bob_unit)[0]
        return B.body(pose, bob_unit) + [(R.capsule(U([-0.16, -0.21, 0.3]), U([0.2, -0.24, 1.25]), 0.06), m("canvas"), "gear"),  # 접은 날개 묶음
                                         (R.capsule(U([-0.2, -0.25, 0.22]), U([0.24, -0.28, 1.36]), 0.018), m("wood"), "gear"),  # 용골
                                         (R.ellipsoid(U([0.02, -0.22, 0.78]), (0.07, 0.07, 0.03)), m("rag"), "gear")]  # 묶은 넝마 띠
    legs = dict(hip_l=10, hip_r=-15, knee_l=25, knee_r=40) if pose["bob"] else dict(hip_l=-15, hip_r=10, knee_l=40, knee_r=25)
    p = dict(pose, sh_l=165, el_l=10, ab_l=0.3, sh_r=165, el_r=10, ab_r=0.3, bob=0, **legs)
    P = [q for q in B.body(p, bob_unit) if q[2] != "club"]
    z = 1.2
    nose = np.array([0, 0.38, z + 0.06])
    P.append((R.capsule([-0.3, 0.05, z - 0.05], [0.3, 0.05, z - 0.05], 0.018), m("wood"), "gear"))  # 가로대
    P.append((R.capsule(nose, [0, -0.35, z], 0.02), m("wood"), "gear"))  # 용골
    # 삼각 날개: 코에서 뒤·바깥으로 뻗은 판 둘. 옆(동·서)에서도 앞뒤 폭이 보여 막대로 읽히지 않는다(Gemini 2026-11-02 «델타익»)
    for s in (-1, 1):
        d = np.array([s * 0.82, -0.6, 0.1])
        d /= np.linalg.norm(d)
        y = np.cross([0, 0, 1.0], d)
        y /= np.linalg.norm(y)
        ax = np.stack([d, y, np.cross(d, y)])
        for k, (a, b) in enumerate(((0.0, 0.6), (0.6, 1.0))):  # 안쪽 천, 바깥 넝마
            c = nose + d * 1.02 * (a + b) / 2 - y * s * 0.14
            P.append((R.box(c, (1.02 * (b - a) / 2, 0.15 - 0.05 * k, 0.014), ax), m("canvas" if k == 0 else "rag"), "gear"))
        P += [(R.box(nose + d * 1.02 * t - y * s * 0.14 + ax[2] * 0.016, (0.09, 0.07, 0.006), ax), m(mat), "gear")
              for t, mat in {-1: ((0.27, "dark"),), 1: ((0.15, "dark"), (0.42, "iron"))}[s]]  # 기운 조각: 좌우 다르게(Gemini 2026-11-02 «패치워크»)
        P.append((R.capsule(nose, nose + d * 1.02, 0.018), m("wood"), "gear"))  # 앞 날개살
    return lift(P, pose["bob"] * bob_unit)


SEATED = dict(IDLE, lean=0, hip_l=80, hip_r=80, knee_l=80, knee_r=80)  # 왕좌에 앉은 왕(전쟁 기계 위)


def chief(pose, bob_unit):
    """전쟁 기계 2페이즈 대장(고블린 왕): 더 구부정한 큰 고블린 + 왼 어깨에서 비스듬히 걸친 무릎까지의 찢어진 붉은 망토(얼룩·땜질),
    등에 진 짐승 두개골, 왕관 옆으로 길게 뻗은 귀, 금관, 금 어깨, 오른손에 세워 쥔 거대 철퇴, 왼 허리 폭탄. 가로 폭은 망토·귀로, 비대칭은 철퇴·망토로 낸다.
    v2의 놋쇠 흉갑은 «노란 멜빵바지 인부»로, v3의 바닥까지 끌리는 매끈한 망토와 곧은 등은 «인간 성기사»로 읽혔다(Gemini 2026-11-02)"""
    swing = pose.get("swing")  # 공격: 고블린 공격 자세의 오른팔·무기 각(sword)을 따라 철퇴를 휘두른다
    p = dict(pose, lean=pose["lean"] + 10)
    if not swing:
        p.update(sh_r=10, el_r=30, ab_r=0.6)  # 철퇴 쥔 손을 옆구리로. 손이 몸 앞에 있으면 북쪽(뒷모습)에서 철퇴가 높이 솟아 남쪽보다 1.5배 컸다
    if pose.get("claw", True):
        p.update(ab_l=pose.get("claw_ab", 0.7), el_l=10)  # 집게 낀 왼팔을 옆으로 벌려 늘어뜨린다. 몸에 붙이면 북쪽(뒷모습)에서 집게가 망토에 가렸고, 아래팔을 앞으로 들면 북쪽에서 짧은 토막으로 보였다
    U, G, up_r, legs, arms = H.rig(p, bob_unit)
    P = [q for q in B.body(p, bob_unit) if q[2] != "club"]
    bites = [R.box([0.27 * np.sin(a), -0.19 * np.cos(a), 0.22], (w, 0.3, h), np.array([[np.cos(a), np.sin(a), 0], [-np.sin(a), np.cos(a), 0], [0, 0, 1.0]]))
             for a, w, h in ((np.radians(-55), 0.04, 0.1), (0.0, 0.03, 0.2), (np.radians(30), 0.04, 0.08), (np.radians(70), 0.035, 0.12))]
    def cape(q):  # 망토: 넓어지는 원뿔의 뒤 반, 무릎까지. 자락을 물어뜯고, 왼 어깨에서 비스듬히 걸쳐 오른쪽 등·다리를 드러낸다
        d = np.maximum(np.maximum(H.flare(q, 0.7, 0.22, 0.2, 0.27, depth=0.7), q[:, 1] + 0.01), -np.min([b(q) for b in bites], 0))
        return np.maximum(d, q[:, 0] - (-0.1 + 0.46 * (q[:, 2] - 0.22)))  # 등 전체를 덮으면 북쪽에서 «중갑 전사»로 읽혔다(Gemini 2026-11-02)
    if pose.get("cape", True):  # 분노(체력 25% 아래)에는 망토를 찢어 던진다(설계 문서 3.9)
        P.append((H.local(U, up_r, cape), m("red"), "torso"))
        P += [(H.local(U, up_r, patch(lambda q: cape(q) - 0.008, c, h)), m(mat), "torso") for c, h, mat in
              (([-0.16, -0.2, 0.45], (0.06, 0.15, 0.07), "dark"), ([-0.04, -0.2, 0.63], (0.05, 0.15, 0.04), "rag"))]  # 망토 얼룩·땜질
    P += [(R.ellipsoid(U([0.02, -0.16, 0.62]), (0.07, 0.05, 0.065)), m("horn"), "torso")]  # 등에 진 짐승 두개골과 뿔
    P += [(R.capsule(U([0.02 + 0.05 * s, -0.18, 0.66]), U([0.02 + 0.13 * s, -0.2, 0.78]), 0.022, 0.006), m("horn"), "torso") for s in (-1, 1)]
    P += [(R.box(U([0.02 + 0.025 * s, -0.212, 0.63]), (0.015, 0.006, 0.012), up_r), m("dark"), "torso") for s in (-1, 1)]
    P += [(R.capsule(U([0.12 * s, 0, 0.84]), U([0.38 * s, -0.06, 0.98]), 0.045, 0.012), m("skin"), "head") for s in (-1, 1)]  # 긴 귀: 왕관 옆으로 고블린임을 알린다
    crown = H.local(U, up_r, lambda q: np.maximum(H.flare(q, 0.93, 0.86, 0.13, 0.125, depth=0.95), -H.flare(q, 0.96, 0.83, 0.105, 0.1, depth=0.95)))
    P.append((crown, m("brass"), "head"))  # 금관: 속이 빈 띠 안에 붉은 모자. 꽉 찬 관은 노란 대머리로, 빈 띠만은 후광으로 읽혔다
    P.append((R.ellipsoid(U([0, 0.02, 0.9]), (0.1, 0.095, 0.075)), m("red"), "head"))
    P += [(R.capsule(U([0.12 * np.sin(a), 0.02 + 0.115 * np.cos(a), 0.91]), U([0.13 * np.sin(a), 0.02 + 0.125 * np.cos(a), 1.01]), 0.024, 0.006), m("brass"), "head")
          for a in np.radians([-70, -35, 0, 35, 70, 180])]  # 관 뾰족이
    P += [(R.ellipsoid(U(arms[s][0] + [0, 0, 0.02]), (0.085, 0.08, 0.06)), m("brass"), "torso") for s in "lr"]  # 금 어깨
    hd = U(arms["r"][2])
    d = up_r @ (np.array([0.06, -0.6, 1.0]) / np.linalg.norm([0.06, -0.6, 1.0]))  # 숙인 윗몸보다 조금 더 뒤로 젖힌다. 앞으로 기울면 남쪽에서 짧고 북쪽에서 높이 솟았다
    if swing:
        d = H.blade_axes(p, up_r)[0]
    head = hd + d * 0.55
    P.append((R.capsule(hd - d * 0.14, head, 0.026), m("dark"), "gear"))  # 철퇴 자루
    P.append((R.ellipsoid(head, (0.1, 0.1, 0.11)), m("iron"), "gear"))
    P += [(R.capsule(head + v * 0.07, head + v * 0.16, 0.03, 0.006), m("light"), "gear")
          for v in (np.array(u) / np.linalg.norm(u) for u in ((1, 0, 0.2), (-1, 0, 0.2), (0, 1, 0.1), (0, -1, 0.1), (0, 0, 1), (0.6, 0.6, -0.5)))]  # 철퇴 가시
    P += [(R.ellipsoid(U([-0.12, 0.05 + 0.07 * k, 0.43 - 0.03 * k]), (0.05, 0.05, 0.05)), m("bomb"), "gear") for k in (0, 1)]  # 허리 폭탄(2페이즈 폭탄 흩뿌리기)
    P.append((R.ellipsoid(U([-0.13, 0.12, 0.47]), (0.02, 0.02, 0.025)), m("flame"), "gear"))
    if pose.get("claw", True):  # 2페이즈: 부서진 전쟁 기계에서 뜯은 집게팔을 왼 아래팔에 낀다(설계 문서 3.9, 사용자 2026-11-02 승인). 기계 위 왕은 맨손이다
        el, hd_l = U(arms["l"][1]), U(arms["l"][2])
        d = (hd_l - el) / np.linalg.norm(hd_l - el)
        side = np.cross(d, [0, 1.0, 0])  # 손가락은 몸 좌우로 벌린다: 게임에서 주로 보이는 남·북 그림에서 집게 틈이 보이게
        side = side / np.linalg.norm(side) if np.linalg.norm(side) > 0.3 else np.cross(d, [0, 0, 1.0]) / np.linalg.norm(np.cross(d, [0, 0, 1.0]))
        P += [(R.capsule(el + d * 0.03, hd_l, 0.065), m("iron"), "gear"),  # 쇠 토시(아래팔)
              (R.capsule(hd_l - side * 0.06, hd_l + side * 0.06, 0.035), m("hole"), "gear"),  # 손목 경첩
              (R.box(hd_l + d * 0.05, (0.075, 0.075, 0.06), np.array([side, np.cross(d, side), d]), 0.01), m("bomb"), "gear")]  # 손바닥 뭉치
        for k in (-1, 1):  # 집게 두 손가락: 기계 집게와 같은 꼴(쇠 뿌리, 검은 마디, 밝은 끝). 늘어뜨린 손 높이라 길이 0.36이면 끝이 땅에 닿기 직전이다
            base, mid, tip = hd_l + d * 0.09 + side * k * 0.05, hd_l + d * 0.22 + side * k * 0.12, hd_l + d * 0.36 + side * k * 0.035
            P += [(R.capsule(base, mid, 0.042, 0.036), m("iron"), "gear"), (R.ellipsoid(mid, (0.03, 0.03, 0.03)), m("hole"), "gear"),
                  (R.capsule(mid, tip, 0.034, 0.008), m("light"), "gear")]
        if pose.get("held"):  # 폭탄 흩뿌리기: 불붙은 폭탄 셋을 두 손가락 사이에 쥔다. 불꽃은 늘 위로 둔다. 폭탄 하나는 손바닥 뭉치와 같은 색이라 남쪽에서 묻혔다
            for c in (hd_l + d * 0.2 - side * 0.06, hd_l + d * 0.2 + side * 0.06, hd_l + d * 0.3):
                P += [(R.ellipsoid(c, (0.065, 0.065, 0.065)), m("bomb"), "gear"), (R.ellipsoid(c + [0, 0, 0.085], (0.032, 0.032, 0.04)), m("flame"), "gear")]
    if pose.get("ground"):  # 다리를 굽힌 자세: 낮은 발목이 선 자세의 발목 높이(0.03)에 오게 몸 전체를 내린다(폭파병 쪼그림과 같다)
        drop = min(G(legs[s][2])[2] for s in "lr") - 0.03
        P = [(lambda q, f=f: f(q + np.array([0, 0, drop])), mat, part) for f, mat, part in P]
    return P


# ── 땅 기계 ───────────────────────────────────────────

def ram(pose, bob_unit):
    """공성 망치: 바퀴 넷 위 그을린 가죽 맞배지붕(비대칭으로 덧댄 판) 아래 큰 숫양 쇠머리 통나무(지붕 앞으로 길게 나옴), 뒤에서 미는 고블린.
    밝은 천 지붕과 줄무늬는 «푸드트럭 포장마차»로 읽혔다(Gemini 2026-11-02).
    걷기 통과 자세(bob)에서 바퀴 위 차체가 1px 덜컹이고, 공격(pose의 ram)은 통나무를 앞(+)·뒤(−)로 민다"""
    W = []
    for x in (-0.4, 0.4):
        for y in (-0.42, 0.42):
            W += wheel(x, y, 0.15)
    push = np.array([0, pose.get("ram", 0.0), 0])
    P = [(R.box([0, 0, 0.29], (0.36, 0.62, 0.045)), m("plank"), "hull")]
    for x in (-0.32, 0.32):
        for y in (-0.55, 0.5):
            P.append((R.capsule([x, y, 0.3], [x, y, 0.55], 0.03), m("plank"), "hull"))
    for s in (-1, 1):  # 맞배지붕: 용마루 z 0.8, 처마 폭 0.42
        ax = np.array([[np.cos(np.radians(35)), 0, -s * np.sin(np.radians(35))], [0, 1, 0], [s * np.sin(np.radians(35)), 0, np.cos(np.radians(35))]])
        c = [s * 0.25 * np.cos(np.radians(35)), -0.03, 0.8 - 0.25 * np.sin(np.radians(35))]
        P.append((R.box(c, (0.25, 0.64, 0.03), ax, 0.01), m("dark"), "hull"))  # 그을린 가죽
        boards = {-1: ((0.06, -0.3, 0.13, 0.16, "canvas"), (-0.08, 0.38, 0.1, 0.12, "iron")), 1: ((-0.04, 0.12, 0.16, 0.1, "canvas"),)}[s]
        P += [(R.box(np.asarray(c) + ax[0] * u + ax[1] * v + ax[2] * 0.035, (hu, hv, 0.012), ax), m(mat), "hull") for u, v, hu, hv, mat in boards]  # 덧댄 판: 좌우가 다르게
    P.append((R.capsule(push + [0, -0.62, 0.42], push + [0, 1.02, 0.42], 0.085), m("wood"), "gear"))  # 통나무: 북쪽에서도 쇠머리가 지붕 너머로 보이게 길게(Gemini 2026-11-02)
    P.append((R.ellipsoid(push + [0, 1.12, 0.44], (0.17, 0.13, 0.17)), m("iron"), "gear"))  # 숫양 쇠머리: 크게, 둥글게 만 뿔
    for s in (-1, 1):
        horn = [push + p for p in ([s * 0.1, 1.1, 0.56], [s * 0.24, 1.02, 0.6], [s * 0.3, 1.04, 0.44], [s * 0.22, 1.13, 0.36])]
        P += [(R.capsule(a, b, 0.05 - 0.01 * i, 0.04 - 0.01 * i), m("iron"), "gear") for i, (a, b) in enumerate(zip(horn, horn[1:]))]
    W += crew(0.85 / KINDS["ram"][1], [0, -0.92 + 0.5 * push[1], 0], pose=pose)  # 망치를 키워도 미는 고블린은 보통 크기. 땅을 걸으니 덜컹이지 않는다
    return W + lift(P, pose["bob"] * bob_unit)


def catapult(pose, bob_unit):
    """투석기: 낮은 바퀴 틀, 꼬인 밧줄 굴대, 뒤 위로 치켜든 팔 끝 큰 바구니의 불붙은 타르 통, 옆에 고블린.
    팔을 틀 위로 들어 북쪽 뒷모습에서도 바구니와 돌이 틀 밖으로 솟는다(Gemini 2026-11-02 «개집»).
    걷기 통과 자세(bob)에서 바퀴 위 틀이 1px 덜컹이고, 공격(pose의 throw)은 팔이 앞으로 넘어가 앞 가로대에 부딪히며 타르 통이 앞 위로 날아간다"""
    W = []
    for x in (-0.34, 0.34):
        for y in (-0.36, 0.36):
            W += wheel(x, y, 0.13)
    P = []
    for x in (-0.28, 0.28):
        P.append((R.box([x, 0, 0.22], (0.04, 0.5, 0.04)), m("plank"), "hull"))
    for y in (-0.4, 0.4):
        P.append((R.box([0, y, 0.22], (0.3, 0.04, 0.04)), m("plank"), "hull"))
    for x in (-0.22, 0.22):
        P.append((R.capsule([x, 0.14, 0.24], [x, 0.14, 0.58], 0.035), m("plank"), "hull"))
    P.append((R.capsule([-0.25, 0.14, 0.56], [0.25, 0.14, 0.56], 0.03), m("plank"), "hull"))
    P.append((R.ellipsoid([0, 0.0, 0.28], (0.24, 0.06, 0.06)), m("rope"), "hull"))  # 꼬인 밧줄 굴대
    throw = pose.get("throw")
    end = np.array([0, 0.27, 1.03] if throw else [0, -0.48, 0.82])  # 던진 팔: 굴대에서 거의 곧게 서서 앞 가로대(y 0.14, z 0.56)에 닿는다
    P.append((R.capsule([0, 0.08, 0.26], end, 0.045), m("wood"), "gear"))  # 치켜든 팔
    P.append((R.cut_above(R.ellipsoid(end + [0, -0.02, 0.03], (0.2, 0.2, 0.12)), end[2] - 0.06), m("dark"), "gear"))  # 큰 바구니(1.5배)
    keg = np.array([0, 0.8, 1.35]) if throw else end + [0, -0.02, 0.12]  # 던지면 통이 앞 위로 날고 불은 뒤로 끌린다
    P.append((R.ellipsoid(keg, (0.13, 0.13, 0.11)), m("bomb"), "gear"))  # 타르 통: 흰 돌은 «눈알»로 읽혔다(Gemini 2026-11-02)
    P.append((R.ellipsoid(keg + ([0, -0.17, -0.04] if throw else [0, 0, 0.15]), (0.08, 0.08, 0.11)), m("flame"), "gear"))
    W += crew(0.85, [0.5, -0.3, 0], yaw=20, pose=pose)  # 땅을 걸으니 덜컹이지 않는다
    return W + lift(P, pose["bob"] * bob_unit)


TOWER_TOP = 3.2 / KINDS["siege_tower"][1]  # 공성탑 꼭대기 바닥 높이. 배율을 곱한 3.2(모델 단위)가 성벽 윗면(약 2.4)보다 화면에서 10px쯤 위다(Gemini 2026-11-02 «8~12px»).
# 배율 1.3은 폭만 Gemini 권장(가로 2칸)으로 넓히려는 것이라 꼭대기 높이는 그대로 둔다


def tower(pose, bob_unit):
    """공성탑: 바퀴 위 위로 좁아지는 세 단 판자 탑(가운데 단은 옆으로 비껴 쌓고 아래 단 옆에 덧붙인 상자), 옆·뒤 X자 버팀목, 뒷면 들쭉날쭉한 사다리,
    앞면 아래는 천, 가운데는 큰 철판 방패, 위는 쇠 이빨 달린 접은 다리판과 사슬, 꼭대기 난간에 고블린·깃발·앞 횃불 둘(Gemini 2026-11-02).
    매끈한 대칭 상자는 «옷장·아파트»로 읽혔고, 횃불은 밤에도 보이게 한다.
    걷기 통과 자세(bob)에서 바퀴 위 탑이 1px 덜컹이고, 공격(pose의 bridge, 도)은 다리판을 위 끝 경첩으로 앞으로 들어 걸친다(설계 문서 3.5 «사다리를 내린다»)"""
    W = []
    for x in (-0.49, 0.49):
        for y in (-0.3, 0.3):
            W += wheel(x, y, 0.14)
    P = []
    T = TOWER_TOP
    stages = ((0.15, 0.375 * T, 0.46, 0.0), (0.375 * T, 0.7 * T, 0.4, 0.07), (0.7 * T, T, 0.34, 0.0))  # (아래 z, 위 z, 반폭, 옆으로 비낀 x)
    for z0, z1, w, dx in stages:
        P.append((R.box([dx, 0, (z0 + z1) / 2], (w, w, (z1 - z0) / 2)), m("plank"), "hull"))
        P.append((R.box([dx, 0, z0 + 0.03], (w + 0.005, w + 0.005, 0.025)), m("iron"), "hull"))  # 단 사이 쇠띠
    for (z0, z1, w, dx), k in zip(stages[:2], (0.06, 0.06)):  # 옆·뒤 X자 버팀목(아래 두 단)
        for a, b in (((-1, z0 + k), (1, z1 - k)), ((-1, z1 - k), (1, z0 + k))):
            for s in (-1, 1):
                P.append((R.capsule([dx + s * (w + 0.015), a[0] * (w - 0.06), a[1]], [dx + s * (w + 0.015), b[0] * (w - 0.06), b[1]], 0.022), m("dark"), "hull"))
            P.append((R.capsule([dx + a[0] * (w - 0.06), -(w + 0.015), a[1]], [dx + b[0] * (w - 0.06), -(w + 0.015), b[1]], 0.022), m("dark"), "hull"))
    P += [(R.box([-0.58, 0.08, 0.9], (0.11, 0.22, 0.2)), m("plank"), "hull"), (R.box([-0.58, 0.08, 0.98], (0.115, 0.225, 0.025)), m("iron"), "hull")]  # 덧붙인 상자
    P.append((R.box([0.1, 0.43, 1.72], (0.3, 0.02, 0.36), tilt_y(6)), m("iron"), "hull"))  # 큰 철판 방패
    P += [(R.ellipsoid([x, 0.45, z], (0.025, 0.02, 0.025)), m("light"), "hull") for x, z in ((-0.13, 1.98), (0.33, 1.94), (-0.11, 1.45), (0.35, 1.42))]  # 징
    for x, dx in ((-0.12, 0.0), (0.12, 0.03)):  # 뒷면 사다리: 아래 단 앞에서 꼭대기까지 기대 세움, 오른 기둥은 비뚤게
        P.append((R.capsule([x, -0.52, 0.12], [x + dx, -0.37, T], 0.022), m("wood"), "gear"))
    P += [(R.capsule([-0.12, -0.52 + 0.15 * t, 0.12 + (T - 0.12) * t - k], [0.12 + 0.03 * t, -0.52 + 0.15 * t, 0.12 + (T - 0.12) * t + k], 0.016), m(mat), "gear")
          for t, k, mat in ((0.05, 0.0, "rope"), (0.14, 0.02, "wood"), (0.22, -0.015, "rope"), (0.33, 0.0, "rope"), (0.41, 0.02, "wood"),
                            (0.6, -0.02, "rope"), (0.68, 0.0, "wood"), (0.79, 0.015, "rope"), (0.93, -0.01, "wood"))]  # 가로대: 간격·기울기·색이 들쭉날쭉, 가운데 하나 빠짐.
    # 반듯한 밝은 사다리는 «급조한 병기답지 않게 단정»했다(Gemini 2026-11-02). 북쪽에서 사다리가 보여야 해서(v2 지적) 밝은 가로대는 남긴다
    P.append((R.box([0, 0.465, 0.6], (0.38, 0.02, 0.4)), m("canvas"), "hull"))  # 앞면 아래 천
    P += [(R.box([x, 0.49, z], (hx, 0.012, hz)), m(mat), "hull") for x, z, hx, hz, mat in
          ((-0.17, 0.82, 0.14, 0.1, "dark"), (0.19, 0.42, 0.12, 0.15, "dark"), (-0.05, 0.3, 0.08, 0.07, "iron"))]  # 덧댄 판: 비대칭
    # 경첩은 다리판 위 끝. 아래 끝 경첩으로 내리면 다리판(z+y 2.7)이 북쪽 그림에서 탑 꼭대기 앞 모서리(z+y 2.8)에 늘 가렸다
    hinge, rot = np.array([0, 0.37, T - 0.13]), tilt_x(-pose.get("bridge", 0))
    board = [(R.box([0, 0.37, T - 0.55], (0.26, 0.04, 0.42)), m("dark"), "gear")]  # 접은 다리판(줄무늬 없음)
    board += [(R.box([0, 0.41, T - z], (0.27, 0.015, 0.018)), m("iron"), "gear") for z in (0.8, 0.4)]
    board += [(R.capsule([x, 0.41, T - 0.15], [x, 0.47, T - 0.03], 0.022, 0.006), m("light"), "gear") for x in (-0.18, -0.06, 0.06, 0.18)]  # 쇠 이빨
    P += [(lambda p, f=f: f(hinge + (p - hinge) @ rot), mat, part) for f, mat, part in board]
    P += [(R.capsule([s * 0.3, 0.32, T], hinge + rot @ (np.array([s * 0.24, 0.41, T - 0.17]) - hinge), 0.012), m("iron"), "gear") for s in (-1, 1)]  # 사슬
    P.append((R.box([0, 0, T + 0.02], (0.36, 0.36, 0.03)), m("dark"), "hull"))  # 꼭대기 바닥
    for x in (-0.31, 0.31):
        for y in (-0.31, 0.31):
            P.append((R.box([x, y, T + 0.13], (0.045, 0.045, 0.1)), m("plank"), "hull"))
    for k in (-0.31, 0.31):  # 난간
        P += [(R.box([0, k, T + 0.2], (0.31, 0.02, 0.022)), m("plank"), "hull"), (R.box([k, 0, T + 0.2], (0.02, 0.31, 0.022)), m("plank"), "hull")]
    P += crew(0.9 / KINDS["siege_tower"][1], [0.06, 0.02, T - 0.37])
    P += flag(-0.31, -0.31, T + 0.03, 0.55)
    for x in (-0.38, 0.38):  # 앞 횃불 둘
        P += [(R.capsule([x, 0.36, T], [x, 0.4, T + 0.42], 0.022), m("wood"), "gear"),
              (R.ellipsoid([x, 0.41, T + 0.5], (0.06, 0.06, 0.09)), m("flame"), "gear")]
    return W + lift(P, pose["bob"] * bob_unit)


KING_ON_MACHINE = 1.6  # 전쟁 기계 위 왕의 크기 배율(내린 대장은 KINDS의 값). Claude 시안 값


def war_machine(pose, bob_unit):
    """고블린 전쟁 기계(보스 1페이즈): 왕이 탄 세 단 고철 성채(Gemini 2026-11-02 «움직이는 고철 성채 + 위 왕좌 + 큰 깃발»).
    아래 단: 쇠바퀴 여섯, 앞 가시 파쇄기, 비스듬한 앞 철판, 덧댄 판·옆 가시. 가운데 단: 쇠 성채와 흉벽, 검은 주철 큰 대포 하나. 아래 단 앞 모서리: 앞 아래로 뻗은 집게 기계팔 둘, 그 안쪽에 앞을 겨눈 기관총 둘과 고블린 사수 둘.
    위 단: 붉은 천막 아래 금 왕좌에 앉은 왕(대장 그림), 가운데 단 앞 모서리 큰 붉은 깃발 둘. 차체 크기는 Gemini 권장 가로 3.5칸 × 세로 4.5칸(약 56×72px). 기계팔까지 넣으면 남쪽 약 78×81px.
    뒷면(게임에서 주로 보이는 북쪽 그림): 아가리에 불이 비치는 검은 배기통 둘과 밝은 연기, 엔진 화로, 덧댄 철판·징, 뒤로 뻗은 가시, 늘어진 사슬,
    휘장 위 가시 윤곽·뒤 해골 문장, 휘장의 찢김·얼룩. 민무늬 뒷벽은 «깃발 꽂은 보급 마차»로, 배기통이 쇠 차체와 같은 색이면 묻혀 읽혔다(Gemini 2026-11-02)
    동작(pose): bob 걷기 덜컹, cannon 1 조준·2 발사, mg 기관총 좌우 각(도, 있으면 쏜다), arm_l·arm_r 기계팔 자세(ARM 참고), dust 내려찍은 흙먼지,
    wreck 잔해(왕·왼 기계팔·사수·앞 깃발·앞 왼바퀴를 빼고 포신을 처뜨린다. 더하는 것은 wreck 함수)"""
    P, wheels = [], []
    wreck = pose.get("wreck")
    W = 1.28  # 아래 단 반폭. 1.08이면 공성탑과 체급이 비슷해 보였다(Gemini 2026-11-02 «좌우 3~4px씩»)
    for x in (-(W + 0.14), W + 0.14):  # 아래 단
        for y in (-0.75, 0.0, 0.75):
            if not (wreck and x < 0 and y > 0):  # 잔해: 앞 왼바퀴가 빠졌다
                wheels += wheel(x, y, 0.36, 0.1, mat="iron")
    P.append((R.box([0, 0, 0.62], (W, 1.05, 0.3), rnd=0.03), m("plank"), "hull"))
    P += [(R.box([0, y, 0.62], (W + 0.01, 0.05, 0.305)), m("iron"), "hull") for y in (-0.55, 0.35)]  # 쇠띠
    P += [(R.box([s * (W + 0.02), y, z], (0.012, hy, hz)), m(mat), "hull") for s, y, z, hy, hz, mat in
          ((-1, 0.0, 0.66, 0.22, 0.16, "dark"), (1, -0.25, 0.72, 0.18, 0.12, "dark"), (1, 0.7, 0.55, 0.2, 0.15, "iron"))]  # 덧댄 판: 좌우 다르게
    P += [(R.capsule([s * W, y, 0.8], [s * (W + 0.42), y, 0.86], 0.045, 0.006), m("light"), "hull") for s, y in ((-1, -0.4), (-1, 0.45), (1, 0.15))]  # 옆 가시
    P.append((R.box([0, 1.08, 0.6], (W + 0.02, 0.07, 0.32), tilt_x(-25), 0.01), m("iron"), "hull"))  # 비스듬한 앞 철판
    P += [(R.capsule([x, 1.05, 0.62], [x, 1.25, 0.6], 0.05, 0.008), m("light"), "hull") for x in (-0.75, -0.2, 0.5)]
    for s in (-1, 1):  # 파쇄기 팔
        P.append((R.capsule([s * 0.85, 0.9, 0.45], [s * 0.98, 1.4, 0.28], 0.05), m("dark"), "hull"))
    P.append((R.capsule([-1.1, 1.4, 0.28], [1.1, 1.4, 0.28], 0.24), m("iron"), "hull"))  # 가시 파쇄기(쇠 굴림대)
    P += [(R.capsule([x, 1.4, 0.28], [x, 1.4 + 0.52 * np.cos(np.radians(a)), 0.28 + 0.52 * np.sin(np.radians(a))], 0.06, 0.006), m("light"), "hull")
          for i, x in enumerate(np.linspace(-0.8, 0.8, 5)) for a in ((40, 100) if i % 2 else (65,))]  # 남쪽에서 굴림대 위로 솟아 보이게
    P.append((R.box([0, -0.2, 1.22], (0.7, 0.6, 0.3), rnd=0.04), m("iron"), "hull"))  # 가운데 단: 쇠 성채
    P += [(R.box([x, 0.38, 1.6], (0.09, 0.05, 0.08)), m("iron"), "hull") for x in (-0.6, 0.6)]  # 앞 흉벽
    P += [(R.box([x, 0.41, z], (hx, 0.012, hz)), m("dark"), "hull") for x, z, hx, hz in ((-0.35, 1.15, 0.2, 0.14), (0.42, 1.3, 0.14, 0.1))]
    # [의도] 정면에 큰 주철 대포 하나, 양옆에 앞을 겨눈 기관총 둘(사용자 2026-11-02). 가는 쌍열 대포(굵기 0.13)는 «너무 작고 조잡해» 보였다
    P.append((R.box([0, 0.47, 1.36], (0.36, 0.12, 0.3), rnd=0.05), m("iron"), "gear"))  # 포 방패
    P += [(R.ellipsoid([x, 0.59, z], (0.03, 0.02, 0.03)), m("light"), "gear") for x in (-0.28, 0.28) for z in (1.14, 1.58)]  # 징
    cannon = pose.get("cannon", 0)
    ax = np.array([0, np.cos(np.radians(-12 if wreck else 3)), np.sin(np.radians(-12 if wreck else 3))])  # 포신을 거의 수평으로 둔다. 12° 들면 북쪽 그림에서 포구 끝이 휘장 위로 솟아 «투구 쓴 머리»로 읽혔다(Gemini 2026-11-02 v7 평가)
    b0 = np.array([0, 0.5, 1.38]) - ax * (0.15 if cannon == 2 else 0)  # 쏘면 포신이 뒤로 밀린다
    b1 = b0 + ax * 1.15

    def cyl(c, r, h):  # 포신 축을 따른 납작한 원통(반지름 r, 반길이 h)
        def f(q):
            d = q - c
            t = d @ ax
            a, b = np.linalg.norm(d - np.outer(t, ax), axis=1) - r, np.abs(t) - h
            return np.minimum(np.maximum(a, b), 0) + np.hypot(np.maximum(a, 0), np.maximum(b, 0))
        return f
    P.append((R.capsule(b0, b1 - ax * 0.25, 0.25, 0.21), m("bomb"), "gear"))  # 둥근 끝이 포구 밖으로 나오지 않게
    P += [(cyl(b0 + ax * t, r, 0.04), m("iron"), "gear") for t, r in ((0.4, 0.28), (0.78, 0.25))]  # 포신 쇠테
    P += [(cyl(b1, 0.31, 0.12), m("iron"), "gear"),  # 포구: 둥근 공 모양 테는 북쪽에서 휘장 위로 솟은 «투구»로 읽혔다
          (cyl(b1 + ax * 0.12, 0.23, 0.012), m("hole"), "gear")]  # 포구 구멍: 반지름 0.18이면 남쪽에서 «막힌 쇠기둥 끝»으로 읽혔다(Gemini 2026-11-02 v8 평가)
    if cannon == 1:  # 조준: 포미 도화선에 불꽃(배기통도 불을 뿜는다, 아래)
        P.append((R.ellipsoid(b0 + [0, -0.05, 0.3], (0.06, 0.06, 0.07)), m("flame"), "gear"))
    if cannon == 2:  # 발사: 포구 앞 큰 불꽃과 연기. 북쪽 그림에서는 차양이 포신을 가리므로 불꽃을 차양 위·옆으로 크게 낸다(Gemini 2026-11-02 v8 평가)
        P += [(R.ellipsoid(b1 + ax * 0.45, (0.42, 0.32, 0.34)), m("flame"), "gear"), (R.ellipsoid(b1 + ax * 0.72, (0.17, 0.1, 0.15)), m("light"), "gear")]  # 남쪽에서 흰 속불이 보이게 앞에 둔다
        P.append((R.ellipsoid(b1 + ax * 0.55 + [0, 0, 0.45], (0.3, 0.26, 0.42)), m("flame"), "gear"))  # 위로 솟는 불기둥: 북쪽에서 차양 위로 보인다
        P += [(R.ellipsoid(b1 + ax * 0.3 + [x, 0, z], (0.2, 0.18, 0.17)), m("smoke"), "gear") for x, z in ((-0.5, 0.12), (0.48, 0.2), (0.0, 0.95))]  # 연기는 불꽃 옆·위: 앞에 두면 남쪽에서 불꽃을 가렸다
    mg = pose.get("mg")  # 기관총 좌우 각(도, 반시계): 두 총이 사수와 함께 같이 돌아 부채꼴로 쓸고(와이퍼), 쏘는 동안 총구에 불꽃
    for s in (-1, 1):  # 기관총: 아래 단 앞 모서리, 사수가 뒤에 서서 앞을 겨눈다
        c = np.array([s * 0.8, 0.86, 1.22])
        P.append((R.capsule([s * 0.8, 0.86, 0.92], c, 0.05), m("dark"), "gear"))  # 받침 기둥
        gun = [(R.box([0, 0.02, 0], (0.13, 0.22, 0.11), rnd=0.02), m("iron"), "gear"),  # 기관부
               (R.ellipsoid([s * 0.2, -0.02, -0.02], (0.07, 0.13, 0.13)), m("brass"), "gear"),  # 원통 탄창
               (R.box([0, 0.3, 0.14], (0.24, 0.025, 0.16), tilt_x(-15)), m("dark"), "gear"),  # 방패판: 쇠색이면 차체에 묻혀 «난간 기둥»으로 읽혔다(Gemini 2026-11-02 v6 평가)
               (R.capsule([0, 0.2, 0.03], [0, 0.62, 0.03], 0.075), m("bomb"), "gear")]  # 총열 덮개
        gun += [(R.capsule([dx, 0.6, 0.03 + dz], [dx, 0.86, 0.04 + dz], 0.032), m("bomb"), "gear") for dx, dz in ((-0.04, -0.02), (0.04, -0.02), (0.0, 0.05))]  # 총열 셋
        gun.append((R.ellipsoid([0, 0.82, 0.04], (0.085, 0.03, 0.085)), m("light"), "gear"))  # 총구 테
        if mg is not None:  # 총구 불꽃: 짧으면(길이 0.22) 북쪽(뒷모습)에서 차체·기계팔에 가려 난사가 «반쯤» 읽혔다(Gemini 2026-11-03 v10 평가)
            gun += [(R.ellipsoid([0, 1.3, 0.07], (0.24, 0.5, 0.24)), m("flame"), "gear"), (R.ellipsoid([0, 1.68, 0.07], (0.09, 0.09, 0.09)), m("light"), "gear")]
        yaw = mg or 0.0
        P += place(gun, 1.0, c, yaw)
        a = np.radians(yaw)
        P += [] if wreck else crew(0.95, c + np.array([[np.cos(a), -np.sin(a), 0], [np.sin(a), np.cos(a), 0], [0, 0, 1]]) @ [-s * 0.02, -0.31, -0.3], yaw)  # 사수
    # [의도] 가까이 온 아군을 치거나 집어 던지는 기능을 나중에 더하려는 기계팔(사용자 2026-11-02). 아래 단 앞 모서리에 달아 양옆으로 벌려 앞으로 뻗는다.
    # 어깨가 가운데 단 옆구리에 높이 있으면 북쪽에서 차체 윗부분·배기통을 가리고 땅의 적을 집으려면 팔이 기형적으로 꺾였다(Gemini 2026-11-02 v5·v6 평가).
    # 팔·집게는 일부러 과장해 키운다(집게 하나가 사수 고블린보다 크다): 굵기 0.1·집게 길이 0.44일 때는 «사람 손»처럼 읽혔다(사용자 2026-11-02,
    # 참고로 준 헬다이버즈2 복스 엔진의 덩치감). 둥근 캡슐 팔은 «배관»으로 읽혀 모난 쇠 들보로 짓고, 마디는 들보보다 가는 검은 경첩으로 끊는다.
    # 들보와 같은 회색의 굵은 관절은 팔 전체가 «회색 바위·풍선»으로 뭉쳐 읽혔다(Gemini 2026-11-02 v6 평가)
    def beam(a, b, hw, hh, mat):
        x = (b - a) / np.linalg.norm(b - a)
        y = np.cross([0, 0, 1.0], x)
        y /= np.linalg.norm(y)
        return (R.box((a + b) / 2, (np.linalg.norm(b - a) / 2, hw, hh), np.array([x, y, np.cross(x, y)]), 0.03), m(mat), "gear")

    def pin(c, axis, r, h=0.24):  # 검은 경첩
        return (R.capsule(c - axis * h, c + axis * h, r), m("hole"), "gear")

    # 팔은 게 집게처럼 양옆 바깥으로 벌려 앞으로 뻗고, 집게는 옆으로 벌린다. 위로 들었다 앞 아래로 꺾으면 북쪽에서 집게날이 차체에 가려
    # «양쪽 굴뚝·로켓 포대»로 읽혔다(Gemini 2026-11-02 v7 평가)
    for s, el, wr, spread in ((-1, [-1.72, 1.05, 1.48], [-1.76, 1.6, 1.22], 0.5), (1, [1.7, 1.0, 1.4], [1.74, 1.55, 1.15], 0.44)):  # 왼 집게를 조금 더 벌려 좌우를 다르게
        if wreck and s < 0:  # 잔해: 왼팔은 대장이 뜯어 왼 아래팔에 꼈다(설계 문서 3.9)
            continue
        sh, el, wr = np.array([s * 1.36, 0.8, 1.2]), np.array(el), np.array(wr)
        cd = np.array([-s * 0.15, 0.9, -0.12])  # 집게는 앞 안쪽 조금 아래를 겨눈다. 더 숙이면(z −0.38) 북쪽에서 두 손가락이 손바닥 위로 짧게 뭉쳐 «드릴·쇠뿔»로 읽혔다(Gemini 2026-11-02 v8 평가)
        tip_w = 0.2  # 손가락 끝의 벌림(뿌리와 같으면 끝이 안으로 굽은 열린 집게)
        spec = pose.get("arm_l" if s < 0 else "arm_r")
        if spec:  # 동작 자세: 정지 그림의 팔 길이(윗팔 약 0.48, 아래팔 0.61)를 지키며 각으로 놓는다
            def out(a, p):  # 앞(+y)에서 바깥으로 돈 각 a, 든 각 p(도) → 단위 벡터
                a, p = np.radians(a), np.radians(p)
                return np.array([s * np.sin(a) * np.cos(p), np.cos(a) * np.cos(p), np.sin(p)])
            a1, p1, a2, p2, a3, p3, spread, tip_w = spec
            el = sh + out(a1, p1) * 0.48
            wr = el + out(a2, p2) * 0.61
            cd = out(a3, p3)
        cd /= np.linalg.norm(cd)
        side = np.cross(cd, [0, 0, 1.0])
        side /= np.linalg.norm(side)
        up = np.cross(cd, side)
        u1, u2 = (el - sh) / np.linalg.norm(el - sh), (wr - el) / np.linalg.norm(wr - el)
        hinge = np.cross(u1, u2)
        hinge /= np.linalg.norm(hinge)
        root = np.array([s * 1.36, 0.6, 1.0])  # 유압 실린더 뿌리
        rod = el - u1 * 0.18 + [0, 0, -0.16]
        P += [(R.box([s * 1.25, 0.8, 1.0], (0.2, 0.24, 0.16), rnd=0.03), m("iron"), "gear"),  # 어깨 받침
              pin(sh, hinge, 0.17),  # 어깨 경첩
              beam(sh + u1 * 0.12, el - u1 * 0.14, 0.2, 0.22, "iron"),  # 윗팔: 검은 들보는 북쪽 그늘에서 검은 덩어리로 뭉쳤다
              (R.capsule(root, root + (rod - root) * 0.55, 0.1), m("bomb"), "gear"),  # 유압 실린더와 막대
              (R.capsule(root + (rod - root) * 0.5, rod, 0.055), m("light"), "gear"),
              pin(el, hinge, 0.16),  # 팔꿈치 경첩
              beam(el + u2 * 0.13, wr - u2 * 0.12, 0.17, 0.19, "iron"),  # 아래팔
              pin(wr, hinge, 0.14, 0.22),  # 손목 경첩
              (R.box(wr + cd * 0.12, (0.2, 0.26, 0.16), np.array([cd, side, up]), 0.04), m("bomb"), "gear")]  # 손바닥 뭉치
        for k in (-1, 1):  # 집게 두 손가락: 크게 벌렸다가 끝이 안으로 굽는다
            base = wr + cd * 0.28 + side * k * 0.2
            mid = wr + cd * 0.72 + side * k * spread
            tip = wr + cd * 1.2 + side * k * tip_w
            P += [(R.capsule(base, mid, 0.16, 0.13), m("iron"), "gear"), (R.ellipsoid(mid, (0.11, 0.11, 0.11)), m("hole"), "gear"),
                  (R.capsule(mid, tip, 0.12, 0.03), m("light"), "gear")]
        if pose.get("dust"):  # 내려찍은 집게 둘레의 흙먼지
            hit = wr + cd * 1.0
            P += [(R.ellipsoid([hit[0] + dx, hit[1] + dy, 0.08 + dz], (r, r * 0.8, r * 0.5)), m("canvas"), "gear")
                  for dx, dy, dz, r in ((-0.35, 0.05, 0, 0.2), (0.35, -0.05, 0.02, 0.22), (0.05, 0.35, 0, 0.17), (0.1, -0.3, 0.1, 0.14))]
    # [의도] 게임에서 가장 오래 보이는 뒷모습(북쪽 그림)을 채운다. 넓은 판자 벽과 가는 배기통 둘뿐이라 «많이 허전하다»(사용자 2026-11-02 v7).
    #        가운데 구리 보일러 통과 빛나는 화실 문, 높이가 다른 배기통 셋과 연기, 큰 황동 톱니 바퀴, 약탈품 자루·술통·포탄, 오른쪽 뒤 붉은 깃발
    P.append((R.capsule([-0.75, -0.98, 1.16], [0.75, -0.98, 1.16], 0.26), m("copper"), "hull"))  # 보일러 통
    P += [(R.capsule([x - 0.03, -0.98, 1.16], [x + 0.03, -0.98, 1.16], 0.275), m("iron"), "hull") for x in (-0.45, 0.0, 0.45)]  # 보일러 쇠테
    P += [(R.ellipsoid([x, -0.98 - 0.26 * np.cos(np.radians(a)), 1.16 + 0.26 * np.sin(np.radians(a))], (0.025, 0.02, 0.025)), m("light"), "hull")
          for x in (-0.62, -0.22, 0.22, 0.62) for a in (10, 50)]  # 보일러 징
    P += [(R.box([x, -1.235, 1.14], (0.1, 0.012, 0.035)), m("ember"), "hull") for x in (-0.22, 0.22)]  # 보일러 통풍구의 불빛
    P += [(R.box([0, -1.07, 0.6], (0.34, 0.03, 0.22), rnd=0.02), m("iron"), "hull"), (R.box([0, -1.09, 0.59], (0.27, 0.02, 0.16)), m("ember"), "hull")]  # 뒤 화실 문
    P += [(R.box([x, -1.12, 0.59], (0.016, 0.012, 0.16)), m("hole"), "hull") for x in (-0.18, -0.06, 0.06, 0.18)]  # 화실 창살
    for x, y, r, top, lean in ((-0.6, -0.98, 0.15, 2.45, 0.0), (-0.88, -1.0, 0.1, 1.95, -0.12), (0.64, -0.98, 0.13, 2.2, 0.05)):  # 배기통 셋: 왼쪽에 둘, 오른쪽에 하나
        t = np.array([x + lean, y, top])
        P += [(R.capsule([x, y, 1.2], t, r), m("soot"), "gear"), (R.ellipsoid(t + [0, 0, 0.01], (r + 0.05, r + 0.05, 0.05)), m("iron"), "gear")]
        if cannon == 1:  # 대포 조준: 배기통이 불을 뿜는다. 게임에서 주로 보이는 북쪽 그림의 예고
            P.append((R.ellipsoid(t + [0, 0, 0.14], (r * 1.1, r * 1.1, 0.16)), m("flame"), "gear"))
        else:
            P.append((R.ellipsoid(t + [0, 0, 0.04], (r * 0.75, r * 0.75, 0.035)), m("flame"), "gear"))  # 아가리의 불
        P += [(R.ellipsoid(t + [lean + np.sign(x) * (0.08 + 0.14 * i), -0.03 * i, 0.2 + 0.24 * i + 0.1 * pose["bob"]], (rr, rr * 0.8, rr * 0.7)), m("smoke"), "gear")
              for i, rr in enumerate((r * 0.8, r * 1.2))]  # 연기: 작게, 바깥으로 흘린다(걷기 통과 자세에서 더 오른다). 굵은 연기 기둥은 북쪽에서 붉은 휘장 양옆을 가리는 회색 기둥이 됐다
    cog = np.array([0.74, -1.12, 0.62])  # 큰 황동 톱니 바퀴(뒷벽 오른쪽). 쇠색이면 바퀴·차체에 묻혔다
    P += [(R.capsule(cog + [0, -0.03, 0], cog + [0, 0.03, 0], 0.28), m("brass"), "hull"), (R.ellipsoid(cog + [0, -0.06, 0], (0.09, 0.03, 0.09)), m("bomb"), "hull")]
    P += [(R.box(cog + [0.33 * np.cos(np.radians(a)), 0, 0.33 * np.sin(np.radians(a))], (0.055, 0.035, 0.055), tilt_y(-a)), m("brass"), "hull") for a in range(0, 360, 40)]
    P += [(R.ellipsoid(c, rr), m(mat), "hull") for c, rr, mat in
          (([-0.92, -1.17, 0.52], (0.17, 0.12, 0.2), "canvas"), ([-0.62, -1.15, 0.47], (0.13, 0.1, 0.15), "rag"), ([-1.1, -1.12, 0.42], (0.1, 0.08, 0.12), "canvas"))]  # 약탈품 자루
    P += [(R.capsule([x, -1.1, 0.78], [x, -1.16, 0.68], 0.022), m("rope"), "hull") for x in (-0.92, -0.62, -1.1)]  # 자루 끈
    P += [(R.capsule([1.02, -0.86, 0.95], [1.02, -0.86, 1.28], 0.15), m("plank"), "hull")] +          [(R.capsule([1.02, -0.86, z - 0.01], [1.02, -0.86, z + 0.01], 0.16), m("iron"), "hull") for z in (1.02, 1.21)]  # 술통
    P += flag(1.12, -0.62, 0.92, 1.45, -1, mat="red", size=1.6)  # 오른쪽 뒤 붉은 깃발: 그 자리의 경비 고블린은 실제 크기에서 배기통에 묻혔다(Gemini 2026-11-02 v7 평가)
    P += [(R.ellipsoid([-1.0 + dx, -0.45 + dy, 1.03 + dz], (0.11, 0.11, 0.11)), m("bomb"), "hull") for dx, dy, dz in
          ((-0.11, -0.07, 0), (0.11, -0.07, 0), (0, 0.12, 0), (0, 0.0, 0.17))]  # 왼쪽 갑판의 포탄 더미
    P.append((R.box([-1.0, -0.88, 1.08], (0.17, 0.14, 0.16), rnd=0.02), m("plank"), "hull"))  # 나무 상자
    P += [(R.box([-1.0, -1.025, 1.08], (hx, 0.006, hz)), m("iron"), "hull") for hx, hz in ((0.17, 0.025), (0.025, 0.16))]  # 상자 쇠띠
    P += [(R.box([x, -1.065, z], (hx, 0.012, hz), tilt_y(a)), m(mat), "hull") for x, z, hx, hz, a, mat in
          ((-0.55, 0.7, 0.28, 0.18, 6, "iron"), (0.92, 0.62, 0.15, 0.2, -5, "dark"))]  # 뒤 덧댄 철판
    P += [(R.ellipsoid([x, -1.08, z], (0.025, 0.02, 0.025)), m("light"), "hull") for x, z in ((-0.78, 0.84), (-0.3, 0.86), (-0.76, 0.56), (0.82, 0.8), (1.0, 0.45))]  # 징
    P += [(R.capsule([x, -1.05, 0.85], [x * 1.1, -1.42, 0.9], 0.05, 0.006), m("light"), "hull") for x in (-0.88, -0.1, 0.55)]  # 뒤로 뻗은 가시
    P += [(R.ellipsoid([x, -1.09, 0.9 - 0.3 * (1 - ((x + 0.35) / 0.6) ** 2)], (0.035, 0.02, 0.03)), m("iron"), "hull") for x in np.linspace(-0.95, 0.25, 11)]  # 늘어진 사슬
    P.append((R.box([0, -0.35, 1.6], (0.5, 0.42, 0.08)), m("dark"), "hull"))  # 위 단: 단상
    P.append((R.box([0, -0.62, 2.02], (0.24, 0.05, 0.34)), m("brass"), "hull"))  # 왕좌 등받이
    P.append((R.box([0, -0.45, 1.76], (0.22, 0.17, 0.08)), m("brass"), "hull"))
    k = KING_ON_MACHINE
    P += [] if wreck else [(R.cut_above(f, 1.68), mat, part) for f, mat, part in place(chief(dict(SEATED, claw=False), 0), k, [0, -0.47, 1.84 - (0.41 - 0.04) * k])]  # 단상 아래로 내려간 망토·정강이는 자른다
    drape = R.box([0, -0.74, 2.45], (0.42, 0.025, 0.75))
    rips = [R.box(c, h, tilt_y(45)) for c, h in (([-0.25, -0.74, 1.72], (0.06, 0.05, 0.06)), ([0.08, -0.74, 1.74], (0.05, 0.05, 0.05)), ([0.3, -0.74, 1.7], (0.07, 0.05, 0.07)))]
    P.append((lambda p: np.maximum(drape(p), -np.min([r(p) for r in rips], 0)), m("red"), "hull"))  # 붉은 천막: 왕 뒤 높은 휘장(자락이 찢김)과 앞으로 기운 차양.
    # [의도] 높고 넓은 붉은 차양이 북쪽 그림에서 대포 포구 끝을 가린다(Gemini 2026-11-02 v7 평가 «투구 쓴 머리»). 왕 머리 위 3.1 높이의 지붕은 왕 머리·철퇴가 뚫고 나와
    #        뒤쪽만 덮는 작은 차양으로 줄였었다. 포신을 수평으로 낮춰도 포구 끝은 북쪽에서 휘장 위로 나와 차양 앞 끝을 3.5 위로 올린다
    # 차양은 용마루를 둔 천막 지붕 두 면이다. 판 한 장(앞으로 12° 기울임)은 북쪽에서 한 색으로 칠해져 휘장과 이어진 «세운 붉은 현수막»으로 읽혔다
    # (Gemini 2026-11-02 v8 평가). 앞면을 28°로 기울이면 북쪽 그림에서 뒷면(9b1a0a)보다 어둡게(300f0a·550f0a) 칠해진다. 앞 끝은 판 한 장일 때 자리다
    roof = np.array([[-0.79, 3.69], [-0.55, 3.85], [0.09, 3.51]])  # 지붕 단면 (y, z): 뒤 처마, 용마루, 앞 끝

    def panel(a, b):  # 단면 두 점 사이의 천 한 면 → (형체, 축)
        d = b - a
        t = tilt_x(np.degrees(np.arctan2(d[1], d[0])))
        return R.box([0, *(a + b) / 2], (0.52, np.linalg.norm(d) / 2 + 0.02, 0.03), t), t
    (back, tb), (front_p, tf) = panel(roof[0], roof[1]), panel(roof[1], roof[2])
    P += [(back, m("red"), "hull"), (front_p, m("red"), "hull")]
    P += [(R.capsule([-0.54, *roof[i]], [0.54, *roof[i]], r), m("dark"), "hull") for i, r in ((0, 0.045), (1, 0.035))]  # 뒤 처마 들보·용마루: 휘장과 차양 사이를 어둡게 끊는다
    P += [(R.box([x, y, z], (hx, 0.006, hz)), m(mat), "hull") for x, y, z, hx, hz, mat in
          ((-0.15, -0.768, 2.05, 0.12, 0.16, "dark"), (0.18, -0.768, 2.9, 0.1, 0.09, "rag"), (0.12, -0.768, 2.25, 0.07, 0.1, "rag"),
           (0.27, -0.712, 2.6, 0.1, 0.12, "dark"), (-0.3, -0.712, 2.2, 0.08, 0.1, "rag"))]  # 휘장 얼룩·땜질: 깨끗한 붉은 네모를 깬다(Gemini 2026-11-02)
    P += [(R.box([x, *(roof[i] + (roof[i + 1] - roof[i]) * f)] + t[2] * 0.035, (hx, hy, 0.008), t), m(mat), "hull") for i, t, x, f, hx, hy, mat in
          ((0, tb, -0.28, 0.5, 0.1, 0.07, "rag"), (1, tf, 0.22, 0.6, 0.08, 0.07, "rag"))]  # 차양 땜질. 앞면의 큰 검은 얼룩은 어두운 앞면을 갈색 덩어리로 만들었다
    front, rise = np.array([0, *roof[2]]), np.array([0, 0.53, 0.81])  # 앞 끝 가시는 판 한 장일 때처럼 앞 위로 솟는다
    P += [(R.capsule(front + [x, 0, 0], front + [x * 1.15, 0, 0] + rise * h, 0.045, 0.006), m("iron"), "hull")
          for x, h in ((-0.46, 0.2), (-0.23, 0.3), (0.0, 0.4), (0.23, 0.26), (0.46, 0.18))]  # 차양 앞 끝 가시: 매끈한 붉은 판을 깨고 북쪽에서 위 윤곽을 들쭉날쭉하게
    P += [(R.capsule([x, y, 1.68], [x, y, np.interp(y, roof[:, 0], roof[:, 1]) - 0.03], 0.03), m("dark"), "hull") for x in (-0.48, 0.48) for y in (-0.38, 0.02)]  # 차양 기둥
    P += [(R.capsule([x, -0.74, 3.15], [x * 1.3, -0.78, 3.15 + h], 0.045, 0.006), m("iron"), "hull")
          for x, h in ((-0.38, 0.22), (-0.19, 0.32), (0.0, 0.42), (0.19, 0.28), (0.38, 0.18))]  # 휘장 위 가시 돋친 고철 왕좌 윤곽(Gemini 2026-11-02 «사각형 등받이»)
    P += [(R.box([x, -0.77, 2.45], (0.025, 0.012, 0.75)), m("iron"), "hull") for x in (-0.3, 0.3)]  # 휘장 뒤 쇠띠
    P += [(R.ellipsoid([0, -0.77, 2.62], (0.09, 0.015, 0.08)), m("horn"), "hull")] + [(R.box([x, -0.785, 2.63], (0.025, 0.006, 0.02)), m("dark"), "hull") for x in (-0.035, 0.035)]  # 뒤 해골 문장
    for x, side, h in () if wreck else ((-0.66, -1, 2.63), (0.66, 1, 2.3)):  # 가운데 단 앞 모서리의 큰 붉은 깃발 둘(키를 달리해 비대칭).
        P += flag(x, 0.3, 1.52, h, side, mat="red", size=3.0)  # 뒤에 두면 북쪽(뒷모습)에서 낮아 기계가 47px로 작았다
        if side < 0:  # 군기의 해골 자리(뼈색 점)
            P.append((R.box([x - 0.3, 0.3, 1.52 + h - 0.21], (0.08, 0.016, 0.07)), m("horn"), "gear"))
    return wheels + lift(P, pose["bob"] * bob_unit)  # 걷기 통과 자세에서 바퀴 위 차체가 1px 덜컹인다(망치·투석기·공성탑과 같다)


SLUMP = (70, -20, 30, -55, 20, -15, 0.45, 0.3)  # 잔해의 오른 기계팔: 힘없이 늘어져 집게가 땅에 눕는다(기계팔 자세 꼴은 REACH 참고)


def wreck(pose, bob_unit):
    """전쟁 기계 잔해(2페이즈로 바뀔 때 잠시, 설계 문서 3.9): 대장이 뛰어내린 빈 수레.
    왕·왼 기계팔(대장이 뜯어 감)·사수·앞 왼바퀴가 없고 포신이 처진다(war_machine의 wreck). 오른 기계팔은 땅에 늘어진다.
    뜯긴 왼 어깨의 토막과 불꽃, 바깥으로 꺾여 쓰러진 큰 깃발과 부러진 깃대, 갑판의 불과 피어오르는 검은 연기"""
    P = war_machine(dict(pose, wreck=True, arm_r=SLUMP), bob_unit)
    P += [(R.box([-1.25, 0.8, 1.0], (0.2, 0.24, 0.16), rnd=0.03), m("iron"), "gear"),  # 왼 어깨 받침
          (R.capsule([-1.36, 0.8, 1.2], [-1.58, 1.02, 1.3], 0.15, 0.11), m("iron"), "gear"),  # 뜯긴 윗팔 토막
          (R.capsule([-1.5, 0.95, 1.25], [-1.66, 1.08, 1.0], 0.04), m("bomb"), "gear"),  # 끊겨 늘어진 유압 관
          (R.ellipsoid([-1.66, 1.08, 1.42], (0.13, 0.13, 0.18)), m("flame"), "gear")]  # 끊긴 자리의 불꽃
    base = np.array([-0.66, 0.3, 1.52])  # 왼 깃발: 깃대 뿌리에서 바깥 아래로 꺾여 차체 옆에 늘어진다
    fall = tilt_y(-115)
    P += [(lambda p, f=f: f((p - base) @ fall.T + base), mat, part) for f, mat, part in flag(*base, 1.7, -1, mat="red", size=3.0)]
    P.append((R.capsule([0.66, 0.3, 1.52], [0.72, 0.28, 2.05], 0.048), m("wood"), "gear"))  # 오른 깃발은 부러진 깃대만 남았다
    P += [(R.ellipsoid(c, r), m("flame"), "gear") for c, r in
          (([0.35, 0.5, 1.62], (0.16, 0.14, 0.2)), ([-0.5, -1.05, 1.5], (0.14, 0.12, 0.18)), ([0.9, -0.5, 1.1], (0.12, 0.12, 0.15)))]  # 갑판·보일러 위 불
    for x, y, z, s in ((0.35, 0.5, 1.85, 1.0), (-1.7, 1.1, 1.6, 0.8)):  # 연기 기둥(갑판 앞, 뜯긴 어깨): 밑동만 검고 위로 갈수록 크고 밝게. 모두 검은 공이면 남쪽에서 포탄 더미로 읽혔다
        P += [(R.ellipsoid([x + dx * s, y, z + dz * s], (r * s, r * s * 0.9, r * s * 0.85)), m(mat), "gear") for dx, dz, r, mat in
              ((0.0, 0.0, 0.16, "soot"), (-0.1, 0.32, 0.22, "smoke"), (0.05, 0.7, 0.28, "smoke"))]
    return P


# ── 하늘 ───────────────────────────────────────────

def balloon(pose, bob_unit):
    """폭탄 열기구: 회갈색 천 풍선에 비대칭으로 기워 붙인 조각, 불씨, 밧줄, 고리버들 바구니의 고블린, 양옆 긴 밧줄에 늘어뜨린 폭탄.
    걷기 통과 자세(bob)에서 1px 출렁이며 불씨가 커진다. 공격(pose의 drop)은 0이면 고블린이 오른쪽으로 몸을 내밀어 밧줄을 잡고, 1이면 그 폭탄이 떨어진다"""
    z0 = 0.25
    drop = pose.get("drop", -1)
    env = R.ellipsoid([0, 0, 1.32], (0.42, 0.42, 0.48))
    shell = R.ellipsoid([0, 0, 1.32], (0.428, 0.428, 0.488))
    fl = 0.01 * pose["bob"]
    P = [(env, m("canvas"), "hull"),
         (R.ellipsoid([0, 0, 0.86], (0.05 + fl, 0.05 + fl, 0.07 + 2 * fl)), m("flame"), "gear")]
    P += [(patch(shell, c, h), m(mat), "hull") for c, h, mat in
          (([0.2, 0.3, 1.5], (0.14, 0.2, 0.11), "dark"), ([-0.32, -0.1, 1.2], (0.2, 0.14, 0.13), "iron"),
           ([0.1, -0.35, 1.62], (0.16, 0.2, 0.09), "dark"))]  # 기운 조각(Gemini 2026-11-02 «패치워크»)
    for x in (-0.15, 0.15):
        for y in (-0.15, 0.15):
            P.append((R.capsule([x, y, z0 + 0.26], [x * 1.7, y * 1.7, 0.98], 0.012), m("rope"), "gear"))
    P.append((R.box([0, 0, z0 + 0.13], (0.17, 0.17, 0.13), rnd=0.02), m("plank"), "hull"))
    P += crew(0.85, [0, -0.02, 0.02]) if drop < 0 else crew(0.85, [0.03, -0.02, 0.02], yaw=-90, pose=dict(IDLE, lean=35, sh_l=90, el_l=10, sh_r=90, el_r=10))
    for s in (-1, 1):  # 바구니 밑 장식으로 읽히지 않게 옆으로 빼서 길게 늘어뜨린다(Gemini 2026-11-02)
        if s == 1 and drop == 1:  # 놓은 밧줄은 짧게 늘어지고 폭탄은 바구니 아래로 떨어진다
            P += [(R.capsule([0.17, 0, z0 + 0.2], [0.21, 0, z0 + 0.02], 0.01), m("rope"), "gear"),
                  (R.ellipsoid([0.3, 0, z0 - 0.6], (0.075, 0.075, 0.075)), m("bomb"), "gear")]
            continue
        P += [(R.capsule([s * 0.17, 0, z0 + 0.2], [s * 0.27, 0, z0 - 0.12], 0.01), m("rope"), "gear"),
              (R.ellipsoid([s * 0.28, 0, z0 - 0.2], (0.075, 0.075, 0.075)), m("bomb"), "gear")]
    return lift(P, pose["bob"] * bob_unit)


def airship(pose, bob_unit):
    """수송 비행선(떼를 나르는 모함): 크기가 다른 두 풍선을 벌려 묶은 들보, 풍선보다 긴 나무 배의 고블린 넷, 뒤 돛대의 찢어진 돛,
    선미 나무 프로펠러 둘, 오른쪽 뱃전의 밧줄 사다리. 크기는 Gemini 권장 가로 2.5칸 × 세로 4칸(약 40×64px).
    풍선 하나에 작은 배는 «1인승 카누»로, 붙은 같은 풍선 둘은 북쪽에서 배를 가려 «소시지 두 개»로 읽혔다(Gemini 2026-11-02, 사용자 «웅장한 느낌이 안 듬»).
    그래서 풍선 사이를 벌려 갑판·돛이 보이게 하고, 배를 풍선보다 길게 해 선미·프로펠러가 북쪽 그림에서 밖으로 나오게 한다.
    걷기 통과 자세(bob)에서 1px 출렁이며 프로펠러가 45° 돈다. 공격(pose의 drop)은 사다리 곁 고블린이 0이면 밧줄 사다리에 매달려 내려가고, 1이면 그 아래로 떨어진다"""
    zd = 0.91  # 갑판 높이
    drop = pose.get("drop", -1)
    envs = ((-0.72, 2.1, (0.36, 1.3, 0.38)), (0.74, 2.2, (0.42, 1.45, 0.44)))  # (x, z, 반지름): 작은 왼쪽, 큰 오른쪽
    P = []
    for x, z, r in envs:
        P.append((R.ellipsoid([x, 0, z], r), m("canvas"), "hull"))
        ty = -r[1] + 0.08
        P += [(R.box([x, ty, z + 0.2], (0.012, 0.18, 0.18)), m("rag"), "gear"), (R.box([x + 0.18 * np.sign(x), ty, z], (0.18, 0.16, 0.012)), m("rag"), "gear")]  # 꼬리 깃
    shells = [R.ellipsoid([x, 0, z], (r[0] + 0.008, r[1] + 0.008, r[2] + 0.008)) for x, z, r in envs]
    P += [(patch(shells[i], c, h), m(mat), "hull") for i, c, h, mat in
          ((0, [-0.95, 0.5, 2.2], (0.12, 0.28, 0.12), "dark"), (0, [-0.6, -0.7, 2.42], (0.15, 0.22, 0.1), "iron"),
           (1, [1.0, -0.3, 2.15], (0.1, 0.35, 0.15), "dark"), (1, [0.62, 0.95, 2.5], (0.14, 0.2, 0.1), "iron"))]  # 기운 조각
    P += [(R.capsule([-0.72, y, 1.75], [0.74, y, 1.75], 0.035), m("plank"), "hull") for y in (-0.8, 0.0, 0.8)]  # 두 풍선을 묶는 들보
    P.append((lambda p: np.maximum(R.ellipsoid([0, 0, zd - 0.04], (0.42, 1.65, 0.3))(p), p[:, 2] - zd), m("plank"), "hull"))  # 긴 배
    P.append((R.ellipsoid([0, 0, zd], (0.4, 1.6, 0.025)), m("dark"), "hull"))  # 갑판
    P += [(R.box([s * 0.36, 0, zd + 0.06], (0.02, 1.1, 0.05)), m("plank"), "hull") for s in (-1, 1)]  # 뱃전
    P += [(R.capsule([s * 0.36, t * 1.0, zd + 0.06], [envs[(s + 1) // 2][0], t * 0.95, 1.75], 0.012), m("rope"), "gear") for s in (-1, 1) for t in (-1, 1)]
    for x, y in ((-0.15, 1.0), (-0.18, -0.15), (0.15, -0.7)) + (((0.18, 0.45),) if drop < 0 else ()):  # 탄 고블린 넷
        P += crew(0.8, [x, y, zd])
    if drop >= 0:  # 사다리(x 0.41) 바깥에 매달린 고블린, 이어서 떨어지는 고블린
        P += crew(0.8, [0.5, 0.45, 0.15] if drop == 0 else [0.55, 0.45, -0.5], yaw=90,
                  pose=dict(IDLE, lean=0, sh_l=170, el_l=10, sh_r=170, el_r=10, hip_l=30, knee_l=60, hip_r=10, knee_r=30) if drop == 0
                  else dict(IDLE, lean=-10, sh_l=150, el_l=30, ab_l=0.8, sh_r=150, el_r=30, ab_r=0.8, hip_l=-20, hip_r=30, knee_l=40, knee_r=40))
    sy = -1.2
    sail = R.box([0, sy, 1.45], (0.28, 0.012, 0.28))
    tears = [R.box(c, h, tilt_y(45)) for c, h in (([0.1, sy, 1.18], (0.07, 0.05, 0.07)), ([-0.18, sy, 1.2], (0.05, 0.05, 0.05)), ([0.26, sy, 1.62], (0.05, 0.05, 0.05)))]
    P += [(R.capsule([0, sy, zd], [0, sy, 1.85], 0.025), m("wood"), "gear"),
          (lambda p: np.maximum(sail(p), -np.min([t(p) for t in tears], 0)), m("rag"), "gear")]  # 뒤 돛대의 찢어진 돛(두 풍선 사이)
    for s in (-1, 1):  # 선미 나무 프로펠러
        P += [(R.capsule([s * 0.12, -1.45, zd - 0.08], [s * 0.24, -1.74, 0.82], 0.025), m("wood"), "gear"),
              (R.ellipsoid([s * 0.24, -1.76, 0.82], (0.04, 0.04, 0.04)), m("iron"), "gear")]
        P += [(R.box([s * 0.24, -1.79, 0.82], (0.17, 0.012, 0.035), tilt_y(a + 45 * pose["bob"])), m("wood"), "gear") for a in (45, -45)]
    P += [(R.capsule([0.4, y, zd], [0.42, y, 0.05], 0.012), m("rope"), "gear") for y in (0.35, 0.55)]  # 밧줄 사다리
    P += [(R.capsule([0.41, 0.35, z], [0.41, 0.55, z], 0.01), m("rope"), "gear") for z in np.linspace(0.15, 0.8, 6)]
    return lift(P, pose["bob"] * bob_unit)


def model(kind):
    fn, s, _, _ = KINDS[kind]
    return H.scaled(globals()[fn], s)


LADDER_W = 14  # 사다리 띠 폭(px). 기둥이 가운데 ±4.5px이고 외곽선까지 들어간다. ±3px에 가로대 4.6px 간격이면 기둥 사이가 외곽선으로 거의 다 메워졌다


def ladder(out=None):
    """사다리 그림(S172 2026-11-03 둘째 변경 ④) → art/trial/ladder/ladder_45_D_f24p.png. 성벽에 45° 기댄 사다리를 카메라 위쪽 축을 따라 세워
    줄어들지 않게 3칸(16px × 3) 띠로 굽는다. 게임은 성벽 열 칸마다 이 띠의 한 칸을 차례로 잘라 잇는다(battle_view.gd _ladders).
    기둥은 곧게 두어 칸 경계에서 이어지고, 공성탑 뒷면 사다리처럼 가로대의 간격·기울기·재질(나무·밧줄)이 들쭉날쭉하고 하나가 빠졌다"""
    n, ppu = 48, 16.0  # 모델 단위 1 = 칸 하나
    cam = R.Cam(45)

    def at(x, s):
        return x * cam.u + s * cam.v

    P = [(R.capsule(at(x, -0.5), at(x, 3.5), 0.05), m("wood"), "gear") for x in (-0.28, 0.28)]
    P += [(R.capsule(at(-0.28, s - k), at(0.28, s + k), 0.035 if mat == "wood" else 0.03), m(mat), "gear")
          for s, k, mat in ((0.18, 0.0, "rope"), (0.55, 0.04, "wood"), (0.93, -0.03, "rope"), (1.3, 0.0, "wood"),
                            (2.05, 0.03, "rope"), (2.42, -0.04, "wood"), (2.79, 0.0, "rope"))]  # 1.68 자리가 빠졌다
    pal = R.PALETTES["f24p"]
    ramps = [H.ramp(BASE[k], pal) for k in BASE]
    pid, lam, depth = R.trace(P, cam, cam.facing(0, 1), n, ppu, (n / 2, n))
    mats = np.array([q[1] for q in P])
    idx = R.shade(np.where(pid >= 0, mats[pid], -1), lam, depth, ramps, "D", R.darkest(pal), edge=0.1 + 1.5 / ppu)
    out = out or TRIAL / "ladder"
    out.mkdir(parents=True, exist_ok=True)
    R.rgba(idx, pal).crop((n // 2 - LADDER_W // 2, 0, n // 2 + LADDER_W // 2, n)).save(out / "ladder_45_D_f24p.png")


# 공격 자세: 게임은 둘째 자세(행동의 정점)만 쓴다(atlas.py FOUR_COLS). 대장은 고블린 공격(들어 올림·내려침)에 철퇴를 쥐인다
# 폭파병: 쪼그림 다리는 folk.py squat. 화약통(keg, 발밑 기준 x·y)은 오른쪽 앞에 둔다. 북쪽(뒷모습)에서 횃불·몸·화약통이 왼쪽부터 나란히 갈린다
CROUCH = dict(IDLE, hip_l=105, hip_r=95, knee_l=145, knee_r=135, lean=15, sh_r=60, el_r=40, ab_r=0.2, keg=(0.28, 0.26))
SAPPER_FUSE = [dict(CROUCH, sh_l=100, el_l=20, ab_l=-0.6, torch=(0.22, -0.06, 0.1), fuse=0.035),  # 왼손 횃불을 도화선 끝에 댄다
               dict(CROUCH, sh_l=35, el_l=40, ab_l=0.9, torch=(0, 0.03, 0.2), fuse=0.06)]  # 도화선이 탄다(불꽃을 키운다)
# 대장 내려침: 철퇴 머리가 오른쪽 앞 땅에 닿는다. 고블린 몽둥이 각(110)이면 땅을 뚫었고, 바깥 기울기(sword_side)가 0이면 북쪽에서 철퇴가 몸에 가렸다
CHIEF_SWING = [dict(B.ATTACK[0], swing=True), dict(B.ATTACK[1], sword=90, sword_side=45, swing=True)]
# 2페이즈 스킬(설계 문서 3.9, 자세는 Claude 안). 2배 캔버스는 attack·fall 이름만이라 정지 캔버스(94px)에 맞춘다
# 휘두르기: 오른쪽 뒤로 젖힘 → 앞을 쓸어 왼쪽 앞에서 멈춤. 손을 더 벌리거나(ab_r 0.5) 앞으로 들면(sh_r 80) 철퇴가 칸을 5~7px 넘었다
CHIEF_CLEAVE = [dict(B.ATTACK[1], sh_r=-25, el_r=20, ab_r=0.3, sword=-78, sword_side=25, lean=B.ATTACK[1]["lean"] - 10, swing=True),
                dict(B.ATTACK[1], sh_r=60, el_r=10, ab_r=-0.3, sword=80, sword_side=-75, swing=True)]
# 집게 팔 sh_l = 세상 각(0 아래, 90 앞, 180 위, 270 뒤) + lean. 집게는 아래팔 방향으로만 뻗는다(옆 벌림은 위팔 길이뿐).
# 앞 수평으로 뻗으면 동쪽 칸을, 앞 아래로 깊이 뻗으면 남쪽 발밑(22px)을, 앞 위로 들면 북쪽 칸 위를 넘었다. 그래서 앞 아래 얕게, 곧장 위, 뒤 위로만 둔다
# 돌진: 웅크려 집게를 뒤로 → 앞으로 크게 기울어 내닫고 집게를 치켜든다
CHIEF_CHARGE = [dict(B.IDLE, hip_l=65, knee_l=90, hip_r=40, knee_r=110, lean=37, sh_l=27, claw_ab=0.4, ground=True),
                dict(B.IDLE, hip_l=55, knee_l=50, hip_r=-55, knee_r=10, lean=40, sh_l=220, claw_ab=0.2, ground=True)]
# 집게 던지기: 숙여 옆 아래를 집음 → 다리를 벌려 버티고 집게를 머리 왼쪽 위로 곧게 치켜듦(집힌 유닛은 게임이 집게에 붙인다).
# 덜 벌리고(claw_ab 1.0) 어깨 뒤 위로 젖히면(sh_l 254) 북쪽에서 집게가 망토와 겹치고 1→2 변화가 작아 «안 읽힘»이었다(Gemini 2026-11-03 v10 평가).
# 선 채 곧게 들면 동쪽 칸 위를 7px 넘어 다리를 굽혀 몸을 낮췄다
CHIEF_FLING = [dict(B.IDLE, lean=42, sh_l=62, claw_ab=2.2, hip_l=45, knee_l=70, hip_r=-10, knee_r=30, ground=True),
               dict(B.IDLE, sh_l=200, claw_ab=1.0, hip_l=60, knee_l=100, hip_r=-30, knee_r=70, ground=True)]
# 폭탄 흩뿌리기: 불붙은 폭탄 셋을 쥔 집게를 옆으로 벌려 어깨 높이 뒤로 → 앞 아래로 내던짐. 허리 뒤로 낮게 쥐면 남쪽에서 몸에 가렸고,
# 덜 벌리면(claw_ab 0.3) 북쪽에서 폭탄이 몸에 묻혀 «안 읽힘»이었다(Gemini 2026-11-03 v10 평가). 덜 벌린 채 뒤 위 45°(sh_l 237~)면 남쪽 칸 위를 넘었다
CHIEF_BOMBS = [dict(B.IDLE, sh_l=245, claw_ab=1.1, held=True),
               dict(B.IDLE, lean=17, sh_l=67, claw_ab=0.8, hip_l=-10, hip_r=14, knee_l=10, knee_r=10)]
# 등장: 공중(다리 웅크림, 철퇴를 머리 위 뒤로) → 착지 웅크림(집게를 뒤로 뻗어 균형). 곧장 아래로 두면 집게가 땅을 뚫었다
CHIEF_LEAP = [dict(B.IDLE, hip_l=80, knee_l=100, hip_r=60, knee_r=90, lean=6, sh_l=-34, claw_ab=0.6, sh_r=150, el_r=20, ab_r=0.35, sword=-100, sword_side=0, swing=True),
              dict(B.IDLE, hip_l=100, knee_l=130, hip_r=80, knee_r=120, lean=42, sh_l=-28, claw_ab=0.8, ground=True)]
# 기계 셋(사용자 2026-11-02 Claude 안 승인): 걷기는 고블린 걷기 그대로 넘겨 통과 자세(bob)에서 차체가 1px 덜컹이고 땅의 고블린은 걷는다
RAM_HIT = [dict(IDLE, ram=-0.18, lean=-5, sh_l=60, el_l=60, sh_r=60, el_r=60),  # 통나무를 뒤로 당긴다
           dict(IDLE, ram=0.3, lean=30, sh_l=85, el_l=10, sh_r=85, el_r=10, hip_r=30, hip_l=-25, knee_l=10)]  # 앞으로 내지르고 미는 고블린이 숙인다
CATAPULT_THROW = [dict(IDLE, lean=20, sh_r=60, el_r=60), dict(IDLE, throw=True, sh_r=150, el_r=20)]  # 장전한 채 버틴다 → 던지고 팔을 든다
TOWER_DROP = [dict(IDLE, bridge=45), dict(IDLE, bridge=90)]  # 다리판을 반쯤 → 수평으로 걸친다. 성벽 윗면까지 기울이면 북쪽 그림에서 다시 가린다
# 하늘 셋(사용자 2026-11-02 Claude 안 승인): 걷기는 정지와 1px 출렁임을 번갈아. 글라이더 공격은 내린 뒤의 고블린 공격, 열기구·비행선은 투하
SWAY = [IDLE, dict(IDLE, bob=1)] * 2
DROP = [dict(IDLE, drop=0), dict(IDLE, drop=1)]
# 전쟁 기계 1페이즈(사용자 2026-11-02: 대포는 논타겟 범위 공격, 기관총은 제자리에서 부채꼴로 좌우 와이퍼처럼 빠르게 난사, 가까이 오면 휘둘러 집어 멀리 던지기, 내려찍기).
# 자세는 Claude 안이다. 기계팔 자세 = (윗팔, 아래팔, 집게 방향 각 쌍 셋 — 앞에서 바깥으로 돈 각·든 각(도), 집게 가운데 벌림, 끝 벌림)
REACH = (75, 5, 35, -40, 25, -40, 0.6, 0.25)  # 바깥 앞 아래로 휘둘러 집게를 크게 벌린다
GRIP = (75, 5, 35, -40, 25, -30, 0.2, 0.04)  # 집게를 닫아 집는다(집힌 유닛은 게임이 그린다)
FLING = (70, 50, 60, 55, 35, 30, 0.55, 0.3)  # 바깥 위로 높이 들어 집게를 벌린다(놓는다)
RAISE = (70, 45, 40, 45, 20, 35, 0.2, 0.04)  # 집게를 닫고 높이 든다. 더 들면(아래팔 60°·집게 60°) 동쪽 그림 위가 캔버스 밖으로 잘렸다
SMASH = (45, -5, 5, -45, 0, -35, 0.2, 0.04)  # 앞 땅을 내려찍는다
WAR = {"cannon": [dict(IDLE, cannon=1), dict(IDLE, cannon=2)],  # 조준 → 발사
       "mgun": [dict(IDLE, mg=a) for a in (40, 0, -40)],  # 왼쪽 → 가운데 → 오른쪽(게임이 오가며 돌린다)
       "grab": [dict(IDLE, arm_r=a) for a in (REACH, GRIP, FLING)],  # 휘둘러 벌림 → 집음 → 들어 놓음
       "slam": [dict(IDLE, arm_l=RAISE, arm_r=RAISE), dict(IDLE, arm_l=SMASH, arm_r=SMASH, dust=True)]}  # 들어 올림 → 내려찍음
MOVES = {"sapper": {"walk": B.WALK, "attack": SAPPER_FUSE, "fall": H.FALL}, "chief": {"walk": B.WALK, "attack": CHIEF_SWING, "cleave": CHIEF_CLEAVE, "charge": CHIEF_CHARGE, "fling": CHIEF_FLING,
                   "bombs": CHIEF_BOMBS, "leap": CHIEF_LEAP,
                   "rage_idle": [dict(IDLE, cape=False)], "rage_walk": [dict(w, cape=False) for w in B.WALK]},  # 분노: 망토를 찢어 던진 정지·걷기. 붉은 칠은 게임 몫
         "war_machine": {"walk": B.WALK, **WAR},
         "ram": {"walk": B.WALK, "attack": RAM_HIT}, "catapult": {"walk": B.WALK, "attack": CATAPULT_THROW},
         "siege_tower": {"walk": B.WALK, "attack": TOWER_DROP},
         "glider": {"walk": SWAY, "attack": [dict(a, landed=True) for a in B.ATTACK],  # 내려앉은 뒤(S283)의 정지·걷기·쓰러짐은 날개를 등에 접은 고블린(S172 2026-11-03 변경)
                    "land_idle": [dict(IDLE, landed=True)], "land_walk": [dict(w, landed=True) for w in B.WALK], "fall": [dict(f, landed=True) for f in H.FALL]},
         "balloon": {"walk": SWAY, "attack": DROP}, "airship": {"walk": SWAY, "attack": DROP}}  # 종류 → 정지 말고 더 굽는 동작


def fits(kind, out=None):
    poses = [IDLE] + MOVES.get(kind, {}).get("walk", [])  # 공격 자세는 넣지 않는다(H.save가 2배 캔버스로 굽는다)
    return H.fits(out or TRIAL / kind, poses, model(kind), f"{TAG} {kind} {KINDS[kind][1]}", SIZES, span=KINDS[kind][2])


def bake(kind, out=None):
    """정지 시트(8방향)와 fit.json, MOVES에 둔 동작(걷기·공격·쓰러짐 등) 시트도 → art/trial/<종류>/. → 24px 맞춤"""
    out = out or TRIAL / kind
    out.mkdir(parents=True, exist_ok=True)
    fts = fits(kind, out)
    anims = {"idle": [IDLE], **MOVES.get(kind, {})}
    for a in anims:
        H.save(a, a, 45, "D", "f24p", fts, model(kind), BASE, anims, out, PARTS)
    return fts[24]


def preview():
    """검수용 확대본 → art/trial/preview/raid_*: 크기 비교(고블린·오크·오우거 곁, 회색조), 종류마다 4방향, 밤 불빛 가장자리"""
    from PIL import Image, ImageDraw, ImageOps

    import ogre as O
    import orc as C
    import preview as V
    import slime as S
    pv = TRIAL / "preview"
    fts = {k: bake(k) for k in KINDS}
    E, N, W = (list(R.DIRS).index(d) for d in ("E", "N", "W"))

    def frame(k, row=0):
        return S.cells(TRIAL / k / "idle_45_D_f24p_24.png", fts[k][2], row)[0]

    def lineup(items):
        """[(그림, 맞춤, 나는가)]를 발밑 줄에 나란히. 나는 것은 게임처럼 발 자리 0.4칸 아래에 그림자 원을 깐다(battle_view.gd 비행 적)"""
        gap, sh = 4, 7
        top = max(f[1][1] for _, f, _ in items)
        bot = max(f[2] - f[1][1] for _, f, _ in items) + sh
        w = sum(im.width for im, _, _ in items) + gap * (len(items) + 1)
        g = Image.new("RGBA", (w, top + bot + 2 * gap), (0x2d, 0x47, 0x2d, 255))
        g.paste((0x68, 0x4c, 0x3c, 255), (w // 2, 0, w, g.height))
        x = gap
        for im, f, fly in items:
            if fly:
                d = ImageDraw.Draw(g, "RGBA")
                cx, cy = x + f[1][0], gap + top + 6
                d.ellipse((cx - 6, cy - 2, cx + 6, cy + 2), fill=(0, 0, 0, 90))
            g.alpha_composite(im, (x, gap + top - f[1][1]))
            x += im.width + gap
        return g

    others = [(S.idle(M.OUT, M.fits()[24][2]), M.fits()[24], False) for M in (B, C, O)]
    rows = []
    for d in (0, E, N):
        line = lineup([(frame(k, d), f, KINDS[k][3]) for k, f in fts.items()] + others)
        rows += [V.up(line, 4), V.up(ImageOps.grayscale(line.convert("RGB")).convert("RGBA"), 4)]
    V.stack(rows, gap=8).save(pv / "raid_sizes_24.png")
    rows = []
    for k, f in fts.items():  # 종류마다 한 줄: 남·동·북·서
        fr = [frame(k, d) for d in (0, E, N, W)]
        x0, y0, x1, y1 = zip(*[g.getbbox() for g in fr])
        row = V.up(V.on(R.sheet([g.crop((min(x0) - 1, min(y0) - 1, max(x1) + 1, max(y1) + 1)) for g in fr], 4, gap=3), pad=2), 5)
        rows.append(V.label_rows(row, [k], row.height, width=110))
    V.stack(rows, gap=6).save(pv / "raid_dirs_24.png")
    line = lineup([(frame(k, 0), f, KINDS[k][3]) for k, f in fts.items()] + others[:1])
    night = [line] + [Image.alpha_composite(line, Image.new("RGBA", line.size, (0x0b, 0x10, 0x30, round(255 * 0.85 * dk * 0.5)))) for dk in (0.5, 1.0)]
    V.up(V.stack(night, gap=4), 4).save(pv / "raid_night_24.png")
    print(*(pv / f"raid_{s}" for s in ("sizes_24.png", "dirs_24.png", "night_24.png")))


if __name__ == "__main__":
    import sys
    if sys.argv[1:] == ["preview"]:
        preview()
        sys.exit()
    for kind in KINDS:
        ppu, anc, c = bake(kind)
        print(f"{kind} ppu={ppu:.2f} anchor={anc} canvas={c}")
    ladder()
    print("ok")
