# 게임 화면이 쓰는 영웅 스프라이트 아틀라스(S165): 영웅 6명의 24px 시트(정지·걷기·공격·쓰러짐)를 한 장에 세로로 쌓고,
# 영웅마다 캔버스 크기·발밑 기준점·시트가 시작하는 y를 json으로 쓴다. 한 장이어야 유닛이 늘어도 draw call이 늘지 않는다
# (insights/2026-10-20_render_spike.md P4).
# 성곽 칸 조각(4.1c)도 같은 식으로 4.0 시험 성벽 그림에서 잘라 한 장에 모은다.
# 사용: python tools/art/atlas.py → art/units/heroes.png, art/units/heroes.json, art/castle/walls.png
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


# 성곽 칸 조각: 시험 그림(6칸 장면, 원점 픽셀 (4, 100), tools/art/wall.py)에서 칸 하나 폭으로 자른다. 조각 맨 아랫줄이 원점 줄이다.
# 행은 단계 1~3(S86)마다 몸체·앞층(흉벽·앞면, 성벽 위 유닛의 발을 가린다), 그다음 통로 그늘, 잔해(I88, 0열만)다. 열은 성벽·열린 문·닫힌 문이다.
# 거점 망루(tools/art/keep.py)는 마을 레벨 1·2를 80×80 두 칸으로 따로 모은다
WALL_LAYERS = ["wall_45_f24p_24", "front_45_f24p_24", "wall_45_f24p_24_L2", "front_45_f24p_24_L2",
               "wall_45_f24p_24_L3", "front_45_f24p_24_L3", "shade_45_24", "rubble_45_f24p_24"]
WALL_STRIPS = [3, 1, 4]  # 시험 그림의 칸 번호(wall.py GATES: 열린 문 1.5, 닫힌 문 4.5)
WALL_TOP = 59  # 시험 그림에서 성벽 픽셀이 시작하는 줄. 조각 높이는 100 - 59 + 1 = 42


def castle():
    h = 100 - WALL_TOP + 1
    out = Image.new("RGBA", (16 * len(WALL_STRIPS), h * len(WALL_LAYERS)))
    for r, layer in enumerate(WALL_LAYERS):
        im = Image.open(f"art/trial/walls/{layer}.png").convert("RGBA")
        for c, strip in enumerate([0] if layer.startswith("rubble") else WALL_STRIPS):  # 잔해는 0번 칸 하나만 그렸다
            out.paste(im.crop((4 + strip * 16, WALL_TOP, 4 + strip * 16 + 16, 101)), (16 * c, h * r))
    Path("art/castle").mkdir(exist_ok=True)
    out.save("art/castle/walls.png")
    keep = Image.new("RGBA", (160, 80))
    for i in (1, 2):
        keep.paste(Image.open(f"art/trial/walls/keep_45_f24p_L{i}.png").convert("RGBA"), (80 * (i - 1), 0))
    keep.save("art/castle/keep.png")
    print(out.size, keep.size)


if __name__ == "__main__":
    main()
    castle()
