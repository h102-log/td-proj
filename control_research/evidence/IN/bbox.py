import json, sys
from PIL import Image
snap = sys.argv[1]
art = json.load(open(snap + "/art/units/heroes.json", encoding="utf-8"))
img = Image.open(snap + "/art/units/heroes.png").convert("RGBA")
CELL = 16
for k, a in art.items():
    c = int(a["c"]); ax, ay = a["anchor"]
    # idle, dir 0 (south), col 0
    y0 = int(a["idle"])
    if "dirs" in a: pass
    crop = img.crop((0, y0, c, y0 + c))
    bb = crop.getchannel("A").getbbox()
    if not bb: print(k, "empty"); continue
    l, t, r, b = bb
    # foot point at cell center (8,8) within cell; sprite top-left = foot - anchor
    top_rel = t - ay   # px relative to foot (negative = above)
    bot_rel = b - ay
    left_rel = l - ax; right_rel = r - ax
    # cell spans -8..+8 around foot
    h = b - t; w = r - l
    in_cell_h = max(0, min(bot_rel, 8) - max(top_rel, -8))
    in_cell_w = max(0, min(right_rel, 8) - max(left_rel, -8))
    print(f"{k:10s} canvas {c} bbox w{w} h{h} top {top_rel:+.0f} bottom {bot_rel:+.0f} left {left_rel:+.0f} right {right_rel:+.0f}  area_in_cell {in_cell_w*in_cell_h/(w*h):.0%}")
