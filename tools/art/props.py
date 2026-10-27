# 마을 일터 소품(S224): 수로 위 물레방아(방앗간 24×28 + 바퀴 16×16 네 장), 공동 화덕, 좌판 둘, 여관 간판. 팔레트 F24+ 색으로 찍는 픽셀 그림이다.
# 칸 안 자리는 battle_view.gd PROP_ART·PROP_AT이 정한다. 꾸밈만이고 시뮬레이션은 그대로다
# 사용: python tools/art/props.py → art/tiles/props.png
import math
from pathlib import Path

from PIL import Image

OUT = Path(__file__).resolve().parents[2] / "art" / "tiles" / "props.png"
INK, WOOD_D, WOOD, WOOD_L = "2a1d0d", "392a1c", "684c3c", "927e6a"
STONE_D, STONE, STONE_L = "3a4357", "56607a", "7a86a0"
ROOF, ROOF_D = "773421", "45230d"  # 집 지붕(facility.py 6e3a2e)에 가장 가까운 팔레트 적갈
CREAM, FIRE, EMBER, WATER, FOAM = "efd8a1", "efac28", "ab5c1c", "276468", "a4aec2"


def put(im, x, y, h):
    if 0 <= x < im.width and 0 <= y < im.height:
        im.putpixel((x, y), tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (255,))


def rect(im, x0, y0, x1, y1, h):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            put(im, x, y, h)


def mill(im, ox):
    """방앗간 24×28: 돌 기단 위 널벽, 박공 지붕, 문. 수로를 걸터앉아 양옆으로 4px 나온다"""
    rect(im, ox + 1, 21, ox + 22, 27, STONE)
    for x in range(ox + 1, ox + 23, 4):  # 기단 돌 줄눈
        rect(im, x, 21, x, 27, STONE_D)
    rect(im, ox + 1, 24, ox + 22, 24, STONE_D)
    rect(im, ox + 1, 27, ox + 22, 27, INK)
    rect(im, ox + 3, 11, ox + 20, 20, WOOD)
    for x in range(ox + 3, ox + 21, 3):  # 널 틈
        rect(im, x, 11, x, 20, WOOD_D)
    rect(im, ox + 3, 11, ox + 3, 20, INK)
    rect(im, ox + 20, 11, ox + 20, 20, INK)
    rect(im, ox + 10, 14, ox + 13, 20, INK)  # 문
    rect(im, ox + 11, 15, ox + 12, 20, WOOD_D)
    for y in range(1, 12):  # 박공 지붕: 가운데가 높다
        half = 1 + y * 11 // 11
        rect(im, ox + 12 - half, y, ox + 11 + half, y, ROOF)
        put(im, ox + 12 - half, y, INK)
        put(im, ox + 11 + half, y, INK)
    rect(im, ox + 11, 0, ox + 12, 0, INK)
    rect(im, ox + 1, 11, ox + 22, 11, ROOF_D)  # 처마 그늘


def wheel(im, ox, step):
    """물레방아 바퀴 16×16 한 장: 테 반지름 7, 살 여덟이 장마다 11.25°씩 돈다. 아래에 물보라"""
    cx, cy = ox + 7.5, 7.5
    for y in range(16):
        for x in range(16):
            r = math.hypot(ox + x - cx, y - cy)
            if 6.0 <= r < 7.5:
                put(im, ox + x, y, INK if r >= 6.9 else WOOD)
    for k in range(8):
        a = math.radians(k * 45 + step * 11.25)
        for t in range(2, 7):
            put(im, round(cx + math.cos(a) * t), round(cy + math.sin(a) * t), WOOD_L if t == 6 else WOOD_D)
    rect(im, ox + 7, 7, ox + 8, 8, INK)
    for x in range(ox + 2, ox + 14):
        put(im, x, 15, WATER)
    for x in range(ox + 3 + step % 2, ox + 13, 3):  # 물보라: 장마다 자리를 옮긴다
        put(im, x, 14, FOAM)


def oven(im, ox):
    """공동 화덕 16×16: 돌 둥근 지붕, 어두운 아궁이 속 불"""
    for y in range(4, 15):
        for x in range(16):
            dx, dy = (x - 7.5) / 7.5, (y - 14.5) / 10.5
            if dx * dx + dy * dy <= 1.0:
                edge = dx * dx + dy * dy > 0.78
                put(im, ox + x, y, INK if edge else (STONE_L if y < 8 and x < 8 else STONE))
    for y in range(9, 15):
        for x in range(5, 11):
            if (x - 7.5) ** 2 / 9 + (y - 15) ** 2 / 36 <= 1.0:
                put(im, ox + x, y, INK)
    rect(im, ox + 6, 13, ox + 9, 14, EMBER)
    rect(im, ox + 7, 12, ox + 8, 13, FIRE)
    rect(im, ox + 0, 15, ox + 15, 15, STONE_D)


def stall(im, ox, stripe):
    """좌판 16×16: 줄무늬 차양(위 6줄), 기둥 둘, 나무 판 위 물건"""
    for x in range(1, 15):
        put(im, ox + x, 1, INK)
        for y in range(2, 6):
            put(im, ox + x, y, CREAM if (x // 2) % 2 else stripe)
        put(im, ox + x, 6, INK if x % 2 else stripe)
    rect(im, ox + 2, 6, ox + 2, 14, WOOD_D)
    rect(im, ox + 13, 6, ox + 13, 14, WOOD_D)
    rect(im, ox + 1, 10, ox + 14, 11, WOOD)
    rect(im, ox + 1, 12, ox + 14, 12, INK)
    for x, h in ((4, FIRE), (6, EMBER), (9, "4f78ad"), (11, CREAM)):  # 물건
        rect(im, ox + x, 8, ox + x + 1, 9, h)


def sign(im, ox):
    """여관 간판 10×12: 벽에서 나온 쇠 막대에 매단 판, 판에 잔"""
    rect(im, ox + 0, 1, ox + 9, 1, INK)
    rect(im, ox + 2, 2, ox + 2, 3, INK)
    rect(im, ox + 7, 2, ox + 7, 3, INK)
    rect(im, ox + 1, 4, ox + 8, 10, INK)
    rect(im, ox + 2, 5, ox + 7, 9, WOOD)
    rect(im, ox + 3, 6, ox + 5, 8, FIRE)  # 잔
    put(im, ox + 6, 7, FIRE)
    rect(im, ox + 3, 6, ox + 5, 6, CREAM)


def build():
    im = Image.new("RGBA", (160, 28), (0, 0, 0, 0))
    mill(im, 0)
    for k in range(4):
        wheel(im, 24 + 16 * k, k)
    oven(im, 88)
    stall(im, 104, "a56243")
    stall(im, 120, "4f78ad")
    sign(im, 136)
    im.save(OUT)


if __name__ == "__main__":
    build()
