# 게임 화면이 쓰는 영웅 스프라이트 아틀라스(S165): 영웅 6명의 24px 시트(정지·걷기·공격·쓰러짐)를 한 장에 세로로 쌓고,
# 영웅마다 캔버스 크기·발밑 기준점·시트가 시작하는 y를 json으로 쓴다. 한 장이어야 유닛이 늘어도 draw call이 늘지 않는다
# (insights/2026-10-20_render_spike.md P4).
# 성곽 칸 조각(4.1c)도 같은 식으로 4.0 시험 성벽 그림에서 잘라 한 장에 모은다.
# 용병·적·주민(4.1d)은 C 절충안에 쓰는 칸만 골라 영웅 아래에 붙인다: 행 S·E·N·W, 정지 1열, 걷기 2위상 2열, 공격 키 포즈 1열, 누운 자세 1장
# 시설(4.1e)은 48×48 칸을 따로 한 장에 모은다(facility())
# 사용: python tools/art/atlas.py → art/units/heroes.png, art/units/heroes.json, art/castle/walls.png, art/castle/facility.png
import json
from pathlib import Path

from PIL import Image

HEROES = ["aias", "sylvia", "seraphina", "vesper", "ignis", "chronos"]
ANIMS = ["idle", "walk", "attack", "fall"]
FOUR = {"soldier": "soldier", "archer": "archer", "engineer": "engineer", "basic": "goblin", "fast": "kobold",  # 게임 종류 → 그림 폴더(art/trial/)
        "armored": "orc", "flying": "harpy", "boss": "ogre", "resident": "resident"}
FOUR_ROWS = [0, 2, 4, 6]  # 8방향 시트(render.DIRS 순서)에서 S·E·N·W
FOUR_COLS = {"idle": [0], "walk": [0, 1], "attack": [1], "fall": [4]}  # 걷기 접지·통과, 공격 내려침, 쓰러짐 마지막(누운 자세)


def main():
    sheets, meta, y = [], {}, 0
    for kind, folder in [(h, h) for h in HEROES] + list(FOUR.items()):
        fit = json.loads(Path(f"art/trial/{folder}/fit.json").read_text(encoding="utf-8"))["fits"]["24"]
        m = {"c": int(fit[2]), "anchor": [fit[1][0], fit[1][1]]}
        for a in ANIMS:
            im = Image.open(f"art/trial/{folder}/{a}_45_D_f24p_24.png").convert("RGBA")
            if kind in FOUR:
                n = m["c"] * (2 if a in ("attack", "fall") else 1)
                rows, cols = ([0] if a == "fall" else FOUR_ROWS), FOUR_COLS[a]
                cut = Image.new("RGBA", (n * len(cols), n * len(rows)))
                for r, row in enumerate(rows):
                    for q, col in enumerate(cols):
                        cut.paste(im.crop((col * n, row * n, (col + 1) * n, (row + 1) * n)), (q * n, r * n))
                im = cut
            sheets.append((im, y))
            m[a] = y
            y += im.height
        meta[kind] = m
    out = Image.new("RGBA", (max(im.width for im, _ in sheets), y))
    for im, oy in sheets:
        out.paste(im, (0, oy))
    Path("art/units").mkdir(exist_ok=True)
    out.save("art/units/heroes.png")
    Path("art/units/heroes.json").write_text(json.dumps(meta, indent=1) + "\n", encoding="utf-8")
    print(out.size)


# 성곽 조각(S217): 두께 3칸·문 폭 3칸 장면(원점 픽셀 (4, 그림 높이 − 4), tools/art/wall.py GAME_GATES)에서 자른다. 조각 맨 아랫줄이 원점 줄(앞줄 바닥선)이다.
# 행은 단계 1~3(S86)마다 몸체·앞층(흉벽·앞면, 성벽 위 유닛의 발을 가린다), 그다음 통로 그늘, 잔해(I88, 성벽 한 열만)다.
# 열은 성벽 한 열(16px)·열린 문(48px)·닫힌 문(48px)·문 왼쪽·오른쪽 탑(16px씩)이다. battle_view.gd WALL_COLS와 같다
# 거점 망루(tools/art/keep.py)는 마을 레벨 1·2를 80×80 두 칸으로 따로 모은다
WALL_LAYERS = ["wall_t3_L1", "front_t3_L1", "wall_t3_L2", "front_t3_L2", "wall_t3_L3", "front_t3_L3", "shade_t3", "rubble_t3"]
WALL_STRIPS = [(6, 1), (1, 3), (9, 3), (8, 1), (12, 1)]  # (시험 그림의 칸 번호, 폭 칸): 성벽 한 열, 열린 문, 닫힌 문, 문 왼쪽 탑, 문 오른쪽 탑
WALL_H = 105  # 조각 높이: 원점 줄부터 양옆 탑 뒤 모서리까지(문루·탑 전에는 통로 뒤 모서리까지 74)


def castle():
    h = WALL_H
    out = Image.new("RGBA", (16 * sum(w for _, w in WALL_STRIPS), h * len(WALL_LAYERS)))
    for r, layer in enumerate(WALL_LAYERS):
        im = Image.open(f"art/trial/walls/{layer}.png").convert("RGBA")
        base = im.height - 4
        x = 0
        for strip, w in ([(0, 1)] if layer.startswith("rubble") else WALL_STRIPS):  # 잔해는 0번 칸 하나만 그렸다
            out.paste(im.crop((4 + strip * 16, base - h + 1, 4 + (strip + w) * 16, base + 1)), (x, h * r))
            x += 16 * w
    Path("art/castle").mkdir(exist_ok=True)
    out.save("art/castle/walls.png")
    keep = Image.new("RGBA", (160, 80))
    for i in (1, 2):
        keep.paste(Image.open(f"art/trial/walls/keep_45_f24p_L{i}.png").convert("RGBA"), (80 * (i - 1), 0))
    keep.save("art/castle/keep.png")
    print(out.size, keep.size)


# 시설 시트: 열은 facility.KINDS 순서, 0행 그림, 1행 청사진 바탕(회색). json은 종류 → [열, 그림 맨 윗줄, 맨 아랫줄 + 1]이다.
# 게임은 진행률만큼 그 줄 범위의 아래부터 그림을 채운다(battle_view.gd _facility)
def facility():
    import facility as F
    out = Image.new("RGBA", (F.N * len(F.KINDS), 2 * F.N))
    meta = {}
    for c, k in enumerate(F.KINDS):
        im = Image.open(f"art/trial/facility/{k}.png").convert("RGBA")
        out.paste(im, (F.N * c, 0))
        out.paste(F.gray(im), (F.N * c, F.N))
        box = im.getbbox()
        meta[k] = [c, box[1], box[3]]
    out.save("art/castle/facility.png")
    Path("art/castle/facility.json").write_text(json.dumps(meta) + "\n", encoding="utf-8")
    print(out.size)


if __name__ == "__main__":
    main()
    castle()
    facility()
