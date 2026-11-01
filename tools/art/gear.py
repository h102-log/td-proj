# 전용장비 아이콘(S274, I209). 16×16 여섯 칸 줄과 8×8 여섯 칸 줄을 art/gear/gear.png 한 장(96×24)에 쓴다.
# 영웅 그림과 같은 f24p·fx 팔레트 색만 쓰고, 그린 칸 바깥 4방향 이웃을 외곽선 151a26으로 두른다. 안티에일리어싱은 없다.
# 사용: python tools/art/gear.py [미리보기.png]  → art/gear/gear.png. 미리보기 경로를 주면 어두운 바탕에 8배 키운 견본도 쓴다
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ORDER = ["aias", "chronos", "ignis", "seraphina", "sylvia", "vesper"]  # 열 차례. src/ui/hud_build.gd GEAR_ART와 같다
OUT = Path(__file__).resolve().parents[2] / "art/gear/gear.png"
LINE = "151a26"
C = {  # f24p·fx 팔레트에서 고른 램프(앞이 밝다)
    "steel": ["d0d6e0", "a4aec2", "7a86a0", "56607a"],
    "gold": ["efd8a1", "efac28", "ab5c1c", "724113"],
    "red": ["ef692f", "ef3a0c", "9b1a0a", "550f0a"],
    "wood": ["a56243", "773421", "45230d"],
    "cream": ["efd8a1", "efb775"],
    "teal": ["3c9f9c", "276468"],
    "glass": ["d0d6e0", "a4aec2", "7a86a0"],
    "bronze": ["927e6a", "684c3c", "392a1c"],
    "green": ["e6f7a8", "b6e357", "7fbf3b", "4a8c2a"],
}
INK = "392a1c"  # 시곗바늘


class Pic:
    """n×n 칸에 팔레트 색 글자를 찍고, 끝에 외곽선을 두른다"""

    def __init__(self, n):
        self.n = n
        self.px = [[None] * n for _ in range(n)]

    def put(self, x, y, c):
        x, y = int(np.floor(x)), int(np.floor(y))
        if 0 <= x < self.n and 0 <= y < self.n:
            self.px[y][x] = c

    def disc(self, cx, cy, r, ramp, light=(-0.6, -0.8)):
        """원을 칠한다. 왼쪽 위 빛을 마주한 쪽이 밝다"""
        for y in range(self.n):
            for x in range(self.n):
                dx, dy = x + 0.5 - cx, y + 0.5 - cy
                if dx * dx + dy * dy <= r * r:
                    t = (dx * light[0] + dy * light[1]) / max(r, 0.01)  # 1 = 빛 쪽 가장자리
                    i = int(np.clip((0.6 - t) * len(ramp) / 1.6, 0, len(ramp) - 1))
                    self.px[y][x] = ramp[i]

    def ring(self, cx, cy, r, c, w=1.0):
        for y in range(self.n):
            for x in range(self.n):
                if r - w < np.hypot(x + 0.5 - cx, y + 0.5 - cy) <= r:
                    self.px[y][x] = c

    def line(self, x0, y0, x1, y1, c):
        k = int(max(abs(x1 - x0), abs(y1 - y0))) + 1
        for t in np.linspace(0, 1, k):
            self.put(x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, c)

    def rows(self, x0, y0, rows, legend):
        """글자 격자를 (x0, y0)부터 찍는다. 범례에 없는 글자는 건너뛴다"""
        for j, row in enumerate(rows):
            for i, ch in enumerate(row):
                if ch in legend:
                    self.put(x0 + i, y0 + j, legend[ch])

    def image(self):
        a = [r[:] for r in self.px]
        for y in range(self.n):
            for x in range(self.n):
                if a[y][x] is None and any(0 <= x + dx < self.n and 0 <= y + dy < self.n and self.px[y + dy][x + dx] is not None
                                           for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                    a[y][x] = LINE
        img = Image.new("RGBA", (self.n, self.n))
        for y in range(self.n):
            for x in range(self.n):
                if a[y][x]:
                    img.putpixel((x, y), tuple(int(a[y][x][i:i + 2], 16) for i in (0, 2, 4)) + (255,))
        return img


def shield(n):
    """맹약의 철벽 방패(아이아스): 금 테 두른 강철 히터 방패, 가운데 붉은 보석"""
    p = Pic(n)
    s = C["steel"]
    if n == 16:
        top, mid, bot = 1, 8, 14  # 윗변, 옆선이 꺾이는 줄, 끝점
        for y in range(top, bot + 1):
            half = 6.0 if y <= mid else 6.0 * (bot - y + 0.6) / (bot - mid + 0.6)
            for x in range(n):
                dx = x + 0.5 - 8
                if abs(dx) <= half:
                    edge = abs(dx) > half - 1 or y == top
                    tone = min(3, max(0, int((dx + 6) / 4) + (y - top) // 7))
                    p.put(x, y, (C["gold"][1] if dx < 0 or y == top else C["gold"][2]) if edge else s[tone])
        p.rows(6, 5, [".rr.", "rRrr", "rrrx", ".xx."], {"r": C["red"][1], "R": C["red"][0], "x": C["red"][2]})
    else:
        p.rows(1, 1, ["gggggG", "gsmmdG", "gsrrdG", ".gmdG.", "..gG.."], {"g": C["gold"][1], "G": C["gold"][2], "s": s[0], "m": s[1], "d": s[2], "r": C["red"][1]})
    return p


def watch(n):
    """태엽 회중시계(크로노스): 금 뚜껑 테, 흰 문자판, 검은 바늘, 꼭지 고리"""
    p = Pic(n)
    if n == 16:
        p.ring(8, 2.5, 2.2, C["gold"][1])
        p.rows(7, 3, ["gG"], {"g": C["gold"][1], "G": C["gold"][2]})
        p.disc(8, 9.5, 6.0, C["gold"][1:4])
        p.disc(8, 9.5, 4.3, C["steel"][:2])
        for a in (0, 90, 180, 270):  # 3·6·9·12시 눈금
            t = np.radians(a)
            p.put(8 + 3.4 * np.sin(t), 9.5 - 3.4 * np.cos(t), C["gold"][2])
        p.line(7.5, 9, 7.5, 6.5, INK)  # 분침 12시
        p.line(7.5, 9, 9.6, 9, INK)  # 시침 3시
        p.put(7.5, 9, C["teal"][0])
    else:
        p.put(3.5, 0.5, C["gold"][1])
        p.disc(4, 4.5, 3.0, C["gold"][1:4])
        p.disc(4, 4.5, 1.8, C["steel"][:2])
        p.put(3.6, 4.0, INK)
        p.put(4.6, 4.0, INK)
    return p


def scepter(n):
    """잉걸불 왕홀(이그니스): 비스듬한 금 자루, 끝에 불붙은 붉은 구슬"""
    p = Pic(n)
    if n == 16:
        p.line(1.5, 14.5, 8.5, 7.5, C["gold"][2])
        p.line(2.5, 14.5, 9.5, 7.5, C["gold"][1])
        p.rows(6, 8, ["gg", "gG"], {"g": C["gold"][0], "G": C["gold"][2]})  # 자루 고리
        p.disc(10.5, 5.5, 3.2, C["red"][:3])
        p.rows(9, 0, ["...y", ".y.o", "yoro", ".rr."], {"y": C["gold"][1], "o": C["red"][0], "r": C["red"][1]})  # 불꽃 혀
        p.put(9.5, 4.5, C["gold"][0])
    else:
        p.line(1, 7, 4, 4, C["gold"][1])
        p.disc(5.3, 2.7, 1.8, C["red"][:3])
        p.put(5.5, 0.4, C["gold"][1])
    return p


def flask(n):
    """여명의 성수병(세라피나): 둥근 유리병 안에 빛나는 금빛 성수, 코르크 마개"""
    p = Pic(n)
    if n == 16:
        p.disc(8, 10.5, 4.8, C["glass"])
        p.disc(8, 11.3, 3.6, [C["cream"][0], C["gold"][1], C["gold"][1], C["gold"][2]])
        p.rows(6, 3, ["gmmd", "gmmd", "gmmd"], {"g": C["glass"][0], "m": C["glass"][1], "d": C["glass"][2]})  # 목
        p.rows(6, 1, ["wwWW", "wwWW"], {"w": C["wood"][0], "W": C["wood"][1]})  # 코르크
        p.put(5, 9, C["glass"][0])  # 유리 반짝임
        p.put(5, 10, C["glass"][0])
        p.rows(12, 1, [".y.", "yyy", ".y."], {"y": C["cream"][0]})  # 빛
    else:
        p.disc(4, 5, 2.6, [C["cream"][0], C["gold"][1], C["gold"][2]])
        p.rows(3, 0, ["ww", "gg"], {"w": C["wood"][0], "g": C["glass"][1]})
    return p


def bow(n):
    """취풍 장궁(실비아): 비스듬한 나무 활대와 시위, 시위에 건 화살, 위쪽에 바람 결"""
    p = Pic(n)
    s = n / 16
    a, b = np.array([2.0, 13.0]) * s, np.array([13.0, 2.0]) * s  # 활 끝 둘(왼쪽 아래·오른쪽 위)
    m, out = (a + b) / 2, np.array([0.707, 0.707])  # 시위 가운데, 활대가 휘는 쪽(오른쪽 아래)
    for t in np.linspace(0, 1, int(40 * s)):  # 활대: 두 끝을 잇는 2차 곡선
        q = (1 - t) ** 2 * a + 2 * (1 - t) * t * (m + out * 8.0 * s) + t * t * b
        p.put(q[0] + 0.5, q[1] + 0.5, C["wood"][0])
        if n == 16:
            p.put(q[0] + 1.5, q[1] + 0.5, C["wood"][1])
    p.line(a[0] + 0.5, a[1] + 0.5, b[0] + 0.5, b[1] + 0.5, C["cream"][0])  # 시위
    if n == 16:
        p.line(9.5, 9.5, 3.5, 3.5, C["wood"][2])  # 화살대
        p.rows(1, 1, ["ss.", "ss.", "..."], {"s": C["steel"][0]})  # 화살촉
        p.rows(1, 1, ["...", "..d"], {"d": C["steel"][2]})
        p.rows(9, 9, ["g.", ".G"], {"g": C["green"][1], "G": C["green"][2]})  # 깃
        p.rows(10, 12, ["gG"], {"g": C["green"][1], "G": C["green"][2]})
        p.rows(11, 1, [".gG", "g..", ".gg"], {"g": C["green"][1], "G": C["green"][0]})  # 바람 결
        p.rows(5, 7, ["tt"], {"t": C["teal"][0]})  # 손잡이 감개
    else:
        p.line(4.5, 4.5, 1.5, 1.5, C["wood"][2])
        p.put(1, 1, C["steel"][0])
    return p


def censer(n):
    """역병 향로(베스퍼): 사슬에 매단 청동 향로, 구멍과 위로 피는 녹색 연기"""
    p = Pic(n)
    if n == 16:
        p.line(7.5, 0, 7.5, 5, C["bronze"][1])  # 사슬
        p.put(7.5, 1, C["bronze"][0])
        p.put(7.5, 3, C["bronze"][0])
        p.disc(8, 10.5, 4.6, C["bronze"])
        p.rows(4, 8, ["gggggggg"], {"g": C["gold"][2]})  # 뚜껑 띠
        p.rows(5, 10, ["o.o.o.o"], {"o": C["green"][1]})  # 구멍으로 새는 빛
        p.rows(6, 15, ["xxxx"], {"x": C["bronze"][2]})  # 받침
        p.rows(1, 2, [".gg.", "gGGg", ".gG."], {"g": C["green"][1], "G": C["green"][2]})  # 연기
        p.rows(11, 3, ["..gg", ".gGg", "..G."], {"g": C["green"][1], "G": C["green"][3]})
    else:
        p.line(3.5, 0, 3.5, 2, C["bronze"][1])
        p.disc(4, 5, 2.4, C["bronze"])
        p.put(3.5, 4.5, C["green"][1])
        p.put(1, 1, C["green"][1])
    return p


DRAW = {"aias": shield, "chronos": watch, "ignis": scepter, "seraphina": flask, "sylvia": bow, "vesper": censer}


def sheet():
    img = Image.new("RGBA", (16 * len(ORDER), 24))
    for i, k in enumerate(ORDER):
        img.paste(DRAW[k](16).image(), (16 * i, 0))
        img.paste(DRAW[k](8).image(), (8 * i, 16))
    return img


if __name__ == "__main__":
    img = sheet()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT)
    if len(sys.argv) > 1:
        bg = Image.new("RGBA", img.size, (38, 45, 61, 255))
        bg.alpha_composite(img)
        bg.resize((img.width * 8, img.height * 8), Image.NEAREST).save(sys.argv[1])
    print(OUT)
