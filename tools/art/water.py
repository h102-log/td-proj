# 수로·연못(S220, 시안 A2): 마을 북동 바닥 위 물 덮개와 북벽 수문 덮개를 맵 px 좌표로 그린다.
# 청록 물 + 진흙 기슭의 자연 연못, 돌 갓돌 수로, 수문 앞 박석 덮개, 바깥 고리 길의 나무 다리, 서쪽 기슭 빨래터, 남쪽 기슭 말뚝 잔교, 갈대·연잎.
# 물 칸·다리 칸 표는 battle_view.gd(_plan)가, 얹는 자리는 battle_view.gd(WATER_AT·CULVERT_AT)가 정한다
# 사용: python tools/art/water.py → art/tiles/water.png, art/castle/culvert.png
from pathlib import Path

import numpy as np
from PIL import Image

ART = Path(__file__).resolve().parents[2] / "art"
X0, Y0, W, H = 672, 0, 160, 340  # 덮개 영역(맵 px)
CX0, CY0, CW, CH = 712, 16, 32, 34  # 수문 덮개 영역
PAL = {"deep": "183f39", "base": "276468", "light": "3c9f9c", "spark": "a4aec2"}
STONE = {"hi": "7a86a0", "mid": "56607a", "lo": "3a4357", "edge": "151a26"}
WOOD = {"hi": "a56243", "mid": "773421", "lo": "45230d"}
DIRT = "684c3c"  # 흙 타일 바탕(tiles.py f24p dirt). 광장 박석(battle_view.gd _pave)의 틈에 비치는 색
CANAL = (720, 736)  # 45열
POND = (706, 212, 790, 318)  # 44~49열·13~19행 안쪽


def rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


class Canvas:
    def __init__(self, x0, y0, w, h):
        self.x0, self.y0 = x0, y0
        self.a = np.zeros((h, w, 4), np.uint8)

    def put(self, x, y, h, a=255):
        x, y = int(x) - self.x0, int(y) - self.y0
        if 0 <= x < self.a.shape[1] and 0 <= y < self.a.shape[0]:
            self.a[y, x] = rgb(h) + (a,)

    def shade(self, x, y, k):  # 덮개 위 그늘(검정 반투명). 이미 칠한 칸이면 어둡게 섞는다
        x, y = int(x) - self.x0, int(y) - self.y0
        if 0 <= x < self.a.shape[1] and 0 <= y < self.a.shape[0]:
            p = self.a[y, x]
            if p[3] == 255:
                p[:3] = (p[:3] * (1 - k)).astype(np.uint8)
            else:
                self.a[y, x] = (0, 0, 0, max(p[3], int(255 * k)))

    def save(self, p):
        Image.fromarray(self.a, "RGBA").save(p)


def pond_mask(rng):
    """연못 물 픽셀: 가장자리가 흔들리는 둥근 사각"""
    x0, y0, x1, y1 = POND
    cx, cy, rx, ry = (x0 + x1) / 2, (y0 + y1) / 2, (x1 - x0) / 2, (y1 - y0) / 2
    ang = np.linspace(0, 2 * np.pi, 10)
    amp = rng.uniform(-0.16, 0.12, 10)
    amp[-1] = amp[0]
    m = set()
    for y in range(y0 - 2, y1 + 2):
        for x in range(x0 - 2, x1 + 2):
            dx, dy = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
            r = 1.0 + np.interp(np.arctan2(dy, dx) % (2 * np.pi), ang, amp)
            if abs(dx) ** 2.6 + abs(dy) ** 2.6 <= r ** 2.6:
                m.add((x, y))
    return m


def water(cv, cells, rng):
    """물 픽셀: 위(북쪽) 기슭 바로 밑과 서쪽 가장자리는 깊은 색, 안쪽은 바탕, 잔물결 짧은 가로선과 반짝임"""
    for (x, y) in cells:
        top = sum((x, y - k) in cells for k in range(1, 4))
        cv.put(x, y, PAL["deep"] if top < 3 or (x - 1, y) not in cells else PAL["base"])
    pts = sorted(cells)
    for _ in range(len(cells) // 110):  # 잔물결: 3~5px 가로 밝은 선
        x, y = pts[rng.integers(len(pts))]
        n = int(rng.integers(3, 6))
        if all((x + k, y) in cells and (x + k, y - 3) in cells for k in range(n)):
            for k in range(n):
                cv.put(x + k, y, PAL["light"])
    for _ in range(len(cells) // 250):  # 반짝임 한 점
        x, y = pts[rng.integers(len(pts))]
        if (x, y - 4) in cells and (x - 1, y) in cells and (x + 1, y) in cells:
            cv.put(x, y, PAL["spark"])


def stone_line(cv, xs, ys):
    """세로 돌 갓돌 띠(폭 3px): 바깥 외곽, 가운데 돌, 물 쪽 어두운 줄. 6px마다 줄눈"""
    for y in ys:
        for j, x in enumerate(xs):
            joint = y % 6 == 0
            cv.put(x, y, STONE["edge"] if j == 0 else STONE["lo"] if (j == len(xs) - 1 or joint) else (STONE["hi"] if y % 6 == 1 else STONE["mid"]))


def canal(cv, rng, y_end):
    lo, hi = CANAL
    water(cv, {(x, y) for y in range(48, y_end) for x in range(lo + 3, hi - 3)}, rng)
    for y in range(48, y_end):  # 서쪽 갓돌 그늘이 물 위 1px
        cv.shade(lo + 3, y, 0.35)
    stone_line(cv, [lo, lo + 1, lo + 2], range(48, y_end))
    stone_line(cv, [hi - 1, hi - 2, hi - 3], range(48, y_end))


# 2026-10-26
# [동작] 수문 앞 박석 덮개를 광장 박석과 같은 규칙(9×7 격자 점의 보로노이, 오른쪽·아래가 같은 돌일 때만 돌색)으로 칠한다
# [이유] 시안 A2의 틈 151a26과 밝은 테가 광장보다 진해 «돌무더기»로 떴다(Gemini 3단계, art/trial/preview/canal_pond/feedback_3.md).
#        광장(battle_view.gd _pave)은 돌 56607a에 틈으로 흙이 비친다. 수로 위에는 흙이 없어 틈을 흙 바탕색으로 칠한다
def cobble_bridge(cv, rng, y0, y1):
    lo, hi = CANAL
    a, b = lo - 6, hi + 6
    pts = [(x + rng.uniform(1.5, 7.5), y + rng.uniform(1.0, 6.0)) for y in range(y0 - 7, y1 + 7, 7) for x in range(a - 9, b + 9, 9)]

    def stone(x, y):
        return min(range(len(pts)), key=lambda i: (x + 0.5 - pts[i][0]) ** 2 + (y + 0.5 - pts[i][1]) ** 2)

    for y in range(y0, y1):
        for x in range(a, b):
            if x in (a, b - 1) and not (lo <= x < hi) and rng.random() < 0.5:
                continue  # 흙길 쪽 끝은 들쭉날쭉
            k = stone(x, y)
            on_water = lo <= x < hi
            if stone(x + 1, y) == k and stone(x, y + 1) == k:
                cv.put(x, y, STONE["mid"])
            elif on_water:
                cv.put(x, y, DIRT)
    for x in range(lo, hi):
        cv.shade(x, y1, 0.5)
        cv.shade(x, y1 + 1, 0.25)


def wood_bridge(cv, y0, y1):
    """바깥 고리 길이 건너는 나무 다리: 남북으로 놓은 널 3px, 위·아래 난간, 끝 기둥"""
    lo, hi = CANAL
    a, b = lo - 4, hi + 4
    for y in range(y0, y1):
        for x in range(a, b):
            k = (x - a) % 3
            cv.put(x, y, WOOD["lo"] if k == 2 else (WOOD["hi"] if k == 0 and (y + x // 3) % 5 else WOOD["mid"]))
    for x in range(a, b):
        cv.put(x, y0, WOOD["lo"])
        cv.put(x, y0 + 1, WOOD["mid"])
        cv.put(x, y1 - 2, WOOD["mid"])
        cv.put(x, y1 - 1, WOOD["lo"])
    for px in (a, a + 1, b - 2, b - 1):
        for py in (y0 - 2, y0 - 1, y1, y1 + 1):
            cv.put(px, py, WOOD["lo"])
    for x in range(lo, hi):
        cv.shade(x, y1 + 2, 0.45)
        cv.shade(x, y1 + 3, 0.2)


def natural_bank(cv, cells, rng):
    """자연 연못 기슭: 물 바로 밖 1~2px 진흙, 바깥 1px 어두운 테. 북쪽 기슭은 물 안쪽 3px에 흙 면이 보인다"""
    ring1, ring2 = set(), set()
    for (x, y) in cells:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            if (x + dx, y + dy) not in cells:
                ring1.add((x + dx, y + dy))
    for (x, y) in ring1:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            q = (x + dx, y + dy)
            if q not in cells and q not in ring1:
                ring2.add(q)
    for (x, y) in ring1:
        cv.put(x, y, "684c3c" if rng.random() < 0.8 else "927e6a")
    for (x, y) in ring2:
        cv.put(x, y, "392a1c" if rng.random() < 0.7 else "684c3c")
    for (x, y) in cells:
        for k, c in ((1, "392a1c"), (2, "2a1d0d")):
            if (x, y - k) not in cells and all((x, y - j) in cells for j in range(0, k)):
                cv.put(x, y, c)


def pier(cv, x, y_top, y_bot):
    """낚시 잔교: 널 3px + 틈 1px(다리와 같은 결), 물 끝 양옆에 말뚝 둘"""
    for y in range(y_top, y_bot):
        for xx in range(x, x + 10):
            k = (y - y_top) % 4
            cv.put(xx, y, WOOD["lo"] if k == 3 or xx in (x, x + 9) else (WOOD["hi"] if k == 0 else WOOD["mid"]))
    for px in (x - 1, x + 10):  # 말뚝: 데크 끝 바깥에 2×3
        for py in range(y_top - 1, y_top + 3):
            cv.put(px, py, WOOD["lo"] if py > y_top - 1 else WOOD["mid"])
    for y in range(y_top, y_bot):
        cv.shade(x + 10, y + 1, 0.4)


# 2026-10-26
# [동작] 빨래 판석은 물에 걸친 쪽에만 두께(아래 두 줄)와 그늘을 두고, 땅 쪽 끝은 흙 점으로 덮는다
# [이유] 시안 A2는 네 변 외곽선 때문에 판석이 기슭에 «얹힌» 듯 보였다(Gemini 3단계, art/trial/preview/canal_pond/feedback_3.md)
def wash_place(cv):
    """서쪽 기슭 빨래터: 반쯤 물에 걸친 넓적한 판석, 그 위 흰 천, 뭍 쪽 나무 대야"""
    x0, y0 = 700, 258
    shore = POND[0]
    for y in range(y0, y0 + 7):
        for x in range(x0, x0 + 12):
            if (x - x0, y - y0) in ((0, 0), (11, 0), (0, 6), (11, 6)):
                continue
            if x < shore and y >= y0 + 5:
                continue  # 땅에 묻힌 쪽은 두께가 보이지 않는다
            cv.put(x, y, STONE["edge"] if y == y0 + 6 else STONE["lo"] if y == y0 + 5 else STONE["hi"] if y == y0 else STONE["mid"])
    for (x, y) in ((x0, y0 + 1), (x0, y0 + 3), (x0 + 1, y0 + 4), (x0 + 1, y0)):
        cv.put(x, y, DIRT)
    for x in range(shore, x0 + 11):
        cv.shade(x, y0 + 7, 0.4)
    cv.put(x0 + 10, y0 + 7, PAL["light"])
    for (x, y) in ((x0 + 6, y0 + 2), (x0 + 7, y0 + 2), (x0 + 8, y0 + 2), (x0 + 6, y0 + 3), (x0 + 7, y0 + 3)):
        cv.put(x, y, "d0d6e0")
    tx, ty = 692, 262  # 대야: 둥근 나무 통 6×5
    for y in range(ty, ty + 5):
        for x in range(tx, tx + 6):
            if (x - tx, y - ty) in ((0, 0), (5, 0), (0, 4), (5, 4)):
                continue
            rim = y in (ty, ty + 4) or x in (tx, tx + 5)
            cv.put(x, y, WOOD["lo"] if rim else ("d0d6e0" if y == ty + 1 else WOOD["mid"]))
    for x in range(tx + 1, tx + 5):
        cv.shade(x, ty + 5, 0.35)


def reeds(cv, rng, cx, cy, n):
    for _ in range(n):
        x = cx + int(rng.integers(-5, 6))
        y = cy + int(rng.integers(-3, 4))
        h = int(rng.integers(4, 9))
        for k in range(h):
            cv.put(x, y - k, "1f240a" if k == 0 else ("39571c" if k < h - 1 else "927e6a" if rng.random() < 0.4 else "39571c"))


def lily(cv, x, y, flower):
    for dy in range(3):
        for dx in range(5):
            if (dx, dy) in ((0, 0), (4, 0), (0, 2), (4, 2), (2, 0)):
                continue
            cv.put(x + dx, y + dy, "183f39" if dy == 2 else "39571c")
    if flower:
        cv.put(x + 2, y + 1, "efd8a1")


def culvert():
    """북벽 마을 쪽 앞면(맵 y 24~48)의 수문: 아치 테 돌, 안은 어둠, 쇠창살, 바닥에 나오는 물"""
    cv = Canvas(CX0, CY0, CW, CH)
    cx = (CANAL[0] + CANAL[1]) / 2
    for y in range(CY0, CY0 + CH):
        for x in range(CX0, CX0 + CW):
            dx, dy = x + 0.5 - cx, y + 0.5 - 38
            r = (dx * dx + min(dy, 0) ** 2) ** 0.5
            if y < 48 and r <= 9.5 and abs(dx) <= 9:
                if r <= 6.5 and abs(dx) <= 6:
                    c = "151a26"
                    if y >= 45:
                        c = PAL["deep"] if y == 45 else PAL["base"]
                    elif int(x - cx + 6) % 3 == 1 or y == 41:
                        c = STONE["lo"]  # 쇠창살
                    cv.put(x, y, c)
                else:
                    seg = int((np.degrees(np.arctan2(dy, dx)) + 360) // 30) if dy < 0 else int(y // 4)
                    cv.put(x, y, STONE["hi"] if seg % 2 else STONE["mid"])
                    if r > 8.8 or (y >= 38 and abs(dx) > 8.5):
                        cv.put(x, y, STONE["edge"])
    return cv


def build():
    rng = np.random.default_rng(5)
    cv = Canvas(X0, Y0, W, H)
    cells = pond_mask(rng)
    natural_bank(cv, cells, rng)
    water(cv, cells, rng)
    canal(cv, rng, POND[1] + 6)
    cobble_bridge(cv, rng, 48, 66)
    wood_bridge(cv, 166, 186)
    for (x, y) in [(712, 246), (709, 290)]:
        reeds(cv, rng, x, y, 14)
    reeds(cv, rng, 784, 268, 12)
    reeds(cv, rng, 776, 222, 10)
    lily(cv, 760, 236, True)
    lily(cv, 768, 246, False)
    lily(cv, 727, 296, False)
    wash_place(cv)
    pier(cv, 746, 298, 322)
    cv.save(ART / "tiles" / "water.png")
    culvert().save(ART / "castle" / "culvert.png")


if __name__ == "__main__":
    build()
