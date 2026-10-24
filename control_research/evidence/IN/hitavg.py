import json, sys
from PIL import Image
snap = sys.argv[1]
art = json.load(open(snap + "/art/units/heroes.json", encoding="utf-8"))
img = Image.open(snap + "/art/units/heroes.png").convert("RGBA")
for k in ["aias","sylvia","seraphina","vesper","ignis","chronos","soldier","archer","engineer"]:
    a = art[k]; c = int(a["c"]); ax, ay = a["anchor"]
    crop = img.crop((0, int(a["idle"]), c, int(a["idle"]) + c))
    A = crop.getchannel("A").load()
    pix = [(x - ax, y - ay) for x in range(c) for y in range(c) if A[x, y] > 0]  # 발밑 기준 불투명 픽셀
    n = 0; tot = 0
    # 발밑이 칸 안 (fx, fy) ∈ [0,16)² 에 고르게 있을 때, 칸(0..16) 안에 드는 불투명 픽셀 비율
    for fx in range(16):
        for fy in range(16):
            for (dx, dy) in pix:
                X = fx + dx + 0.5; Y = fy + dy + 0.5
                tot += 1
                if 0 <= X < 16 and 0 <= Y < 16: n += 1
    center = sum(1 for (dx,dy) in pix if 0 <= 8+dx+0.5 < 16 and 0 <= 8+dy+0.5 < 16) / len(pix)
    print(f"{k:10s} 불투명 {len(pix)}px  칸 가운데 섰을 때 {center:.0%}  걷는 중 평균 {n/tot:.0%}")
