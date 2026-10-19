# 게임 화면이 쓰는 영웅 스프라이트 아틀라스(S165): 영웅 6명의 24px 시트(정지·걷기·공격·쓰러짐)를 한 장에 세로로 쌓고,
# 영웅마다 캔버스 크기·발밑 기준점·시트가 시작하는 y를 json으로 쓴다. 한 장이어야 유닛이 늘어도 draw call이 늘지 않는다
# (insights/2026-10-20_render_spike.md P4).
# 사용: python tools/art/atlas.py → art/units/heroes.png, art/units/heroes.json
import json
from pathlib import Path

from PIL import Image

HEROES = ["aias", "sylvia", "seraphina", "vesper", "ignis", "chronos"]
ANIMS = ["idle", "walk", "attack", "fall"]


def main():
    sheets, meta, y = [], {}, 0
    for h in HEROES:
        fit = json.loads(Path(f"art/trial/{h}/fit.json").read_text(encoding="utf-8"))["fits"]["24"]
        m = {"c": int(fit[2]), "anchor": [fit[1][0], fit[1][1]]}
        for a in ANIMS:
            im = Image.open(f"art/trial/{h}/{a}_45_D_f24p_24.png").convert("RGBA")
            sheets.append((im, y))
            m[a] = y
            y += im.height
        meta[h] = m
    out = Image.new("RGBA", (max(im.width for im, _ in sheets), y))
    for im, oy in sheets:
        out.paste(im, (0, oy))
    Path("art/units").mkdir(exist_ok=True)
    out.save("art/units/heroes.png")
    Path("art/units/heroes.json").write_text(json.dumps(meta, indent=1) + "\n", encoding="utf-8")
    print(out.size)


if __name__ == "__main__":
    main()
