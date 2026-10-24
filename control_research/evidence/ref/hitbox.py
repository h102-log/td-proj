# 일회성: 유닛 정지 그림(남쪽)의 불투명 픽셀 중 클릭 판정 칸(발밑 중심 ±8px) 안에 드는 비율
import json, sys
from PIL import Image

snap = sys.argv[1]
d = json.load(open(snap + "/art/units/heroes.json", encoding="utf-8"))
im = Image.open(snap + "/art/units/heroes.png").convert("RGBA")
for k, a in d.items():
    c = int(a["c"]); ax, ay = a["anchor"]
    y0 = a["idle"]  # 방향 0(S), 열 0
    tot = inside = 0
    ys = []
    for y in range(c):
        for x in range(c):
            if im.getpixel((x, y0 + y))[3] > 0:
                tot += 1
                ys.append(y)
                if ax - 8 <= x < ax + 8 and ay - 8 <= y < ay + 8:
                    inside += 1
    if tot:
        print(f"{k:10s} 그림 높이 {max(ys)-min(ys)+1:2d}px (발밑 위 {ay-min(ys):4.0f}px, 아래 {max(ys)-ay+1:3.0f}px)  판정 칸 안 {inside/tot*100:5.1f}%")

# 조준 대상 판정(controls.gd _closest: 클릭 지점에서 0.7칸 = 11.2px 안의 발밑)
print("--- 조준 0.7칸 원 안 비율")
for k, a in d.items():
    c = int(a["c"]); ax, ay = a["anchor"]
    y0 = a["idle"]
    tot = inside = 0
    for y in range(c):
        for x in range(c):
            if im.getpixel((x, y0 + y))[3] > 0:
                tot += 1
                if ((x + 0.5 - ax) ** 2 + (y + 0.5 - ay) ** 2) ** 0.5 <= 11.2:
                    inside += 1
    if tot:
        print(f"{k:10s} {inside/tot*100:5.1f}%")
