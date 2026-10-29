# 게임 화면이 쓰는 영웅 스프라이트 아틀라스(S165): 영웅 6명의 24px 시트(정지·걷기·공격·쓰러짐)를 한 장에 세로로 쌓고,
# 영웅마다 캔버스 크기·발밑 기준점·시트가 시작하는 y를 json으로 쓴다. 한 장이어야 유닛이 늘어도 draw call이 늘지 않는다
# (insights/2026-10-20_render_spike.md P4).
# 성곽 칸 조각(4.1c)도 같은 식으로 4.0 시험 성벽 그림에서 잘라 한 장에 모은다.
# 용병·적(4.1d)은 C 절충안에 쓰는 칸만 골라 영웅 아래에 붙인다: 행 S·E·N·W, 정지 1열, 걷기 2위상 2열, 공격 키 포즈 1열, 누운 자세 1장
# 방향 없는 적(1라운드 슬라임, I189)은 남쪽 한 행만 잘라 용병·적 칸 구역 오른쪽에 쌓는다(x·one). 아래에 붙이면 Godot 텍스처 상한 16384px을 넘는다
# 2라운드 늑대(I189 2026-10-29 변경)는 4방향 칸을 같은 옆 열 슬라임 아래에 쌓는다(x만, one 없음). 도약 늑대는 웅크림, 알파는 웅크림·뜀 칸을 더한다(S244)
# 주민(S172 2026-10-26·27 변경)은 몸마다 folk.py 시트 한 장을 그대로 붙이고, look마다 x로 가른다(folk_<몸>_<look>). 일 자세는 자세 이름이 그 첫 행의 y다
# 시설(4.1e)은 48×48 칸을 따로 한 장에 모은다(facility())
# 사용: python tools/art/atlas.py → art/units/heroes.png, art/units/heroes.json, art/castle/walls.png, art/castle/facility.png
import json
from pathlib import Path

from PIL import Image

HEROES = ["aias", "sylvia", "seraphina", "vesper", "ignis", "chronos"]
ANIMS = ["idle", "walk", "attack", "fall"]
FOUR = {"soldier": "soldier", "archer": "archer", "engineer": "engineer", "basic": "goblin", "fast": "kobold",  # 게임 종류 → 그림 폴더(art/trial/)
        "armored": "orc", "flying": "harpy", "boss": "ogre"}
FOLK = ["man", "woman", "boy", "girl", "old_man", "old_woman", "lad", "lass"]  # 주민 몸(S221, 청소년 S232)
FOUR_ROWS = [0, 2, 4, 6]  # 8방향 시트(render.DIRS 순서)에서 S·E·N·W
FOUR_COLS = {"idle": [0], "walk": [0, 1], "attack": [1], "fall": [4], "crouch": [0], "air": [0]}  # 걷기 접지·통과, 공격 내려침, 쓰러짐 마지막(누운 자세)
ONE = {k: k for k in ("slimelet", "slime", "big_slime", "slime_king")}  # 방향 없는 적(S172 2026-10-27 넷째 변경): 게임 종류 → 그림 폴더
WOLVES = {"wolf": (), "leap_wolf": ("crouch",), "night_wolf": (), "alpha_wolf": ("crouch", "air")}  # 옆 열 4방향 적(S172 2026-10-29 변경) → 더 굽는 자세


def _sheet(folder, a):
    return Image.open(f"art/trial/{folder}/{a}_45_D_f24p_24.png").convert("RGBA")


def _fit(folder):
    fit = json.loads(Path(f"art/trial/{folder}/fit.json").read_text(encoding="utf-8"))["fits"]["24"]
    return {"c": int(fit[2]), "anchor": [fit[1][0], fit[1][1]]}


def _cut(im, c, a, rows):
    """8방향 시트에서 C 절충안 칸만: rows 행 × FOUR_COLS[a] 열. 공격·쓰러짐은 2배 칸"""
    n = c * (2 if a in ("attack", "fall") else 1)
    cols = FOUR_COLS[a]
    cut = Image.new("RGBA", (n * len(cols), n * len(rows)))
    for r, row in enumerate(rows):
        for q, col in enumerate(cols):
            cut.paste(im.crop((col * n, row * n, (col + 1) * n, (row + 1) * n)), (q * n, r * n))
    return cut


def main():
    sheets, meta, y = [], {}, 0  # sheets: (그림, x, y)
    for kind, folder in [(h, h) for h in HEROES] + list(FOUR.items()):
        m = _fit(folder)
        for a in ANIMS:
            im = _sheet(folder, a)
            if kind in FOUR:
                im = _cut(im, m["c"], a, [0] if a == "fall" else FOUR_ROWS)
            sheets.append((im, 0, y))
            m[a] = y
            y += im.height
        meta[kind] = m
    top = meta[next(iter(FOUR))]["idle"]  # 용병·적 칸 구역(top~y)의 오른쪽에 방향 없는 칸, 그 아래 늑대 칸을 위에서부터 쌓는다(I189)
    x = max(im.width for im, _, oy in sheets if oy >= top)
    oy = top
    for kind, folder in ONE.items():
        m = dict(_fit(folder), x=x, one=True)
        for a in ANIMS:
            im = _cut(_sheet(folder, a), m["c"], a, [0])
            sheets.append((im, x, oy))
            m[a] = oy
            oy += im.height
        meta[kind] = m
    for kind, extra in WOLVES.items():
        m = dict(_fit(kind), x=x)
        for a in ANIMS + list(extra):
            im = _cut(_sheet(kind, a), m["c"], a, [0] if a == "fall" else FOUR_ROWS)
            sheets.append((im, x, oy))
            m[a] = oy
            oy += im.height
        meta[kind] = m
    assert oy <= y, f"옆 열 칸({top}~{oy})이 용병·적 칸 구역({top}~{y})을 넘는다"
    fit = json.loads(Path("art/trial/folk/fit.json").read_text(encoding="utf-8"))
    c = fit["c"]
    for body in FOLK:  # look마다 가로 2칸 띠: 0~3행 정지(1열), 4~7행 걷기(2열), 그 아래 일 자세(S172 2026-10-27 변경, 첫 행은 fit.json rows)
        im = Image.open(f"art/trial/folk/{body}.png").convert("RGBA")
        for look in range(im.width // (2 * c)):
            m = {"c": c, "anchor": fit["anchor"], "x": 2 * c * look, "idle": y, "walk": y + 4 * c}
            have = {p: y + r * c for p, r in fit["rows"][body].items() if im.crop((2 * c * look, r * c, 2 * c * look + c, r * c + c)).getbbox()}
            meta[f"folk_{body}_{look}"] = dict(m, **have)  # 굽지 않은 자세(사제 띠의 일 자세·등짐, I187 ③)는 키를 두지 않는다
        sheets.append((im, 0, y))
        y += im.height
    out = Image.new("RGBA", (max(ox + im.width for im, ox, _ in sheets), y))
    for im, ox, oy in sheets:
        out.paste(im, (ox, oy))
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
# 사방 성곽(S219) 열: 남쪽 열 다음에 (그림 이름, 자를 칸들). 자를 칸이 None이면 wall.py가 이미 자른 48px 조각이다(side_piece).
# 북벽 열·닫힌 문루·양옆 탑, 남·북 모서리 탑(왼쪽·오른쪽), 서·동 성벽 행 띠, 서·동 닫힌 문루. battle_view.gd WALL_COLS와 같다
SQUARE = [("wall_n_t3", [(6, 1), (9, 3), (8, 1), (12, 1)]), ("corner_s", [(0, 3), (5, 3)]), ("corner_n", [(0, 3), (5, 3)]),
          ("side_w", None), ("side_e", None), ("gate_w", None), ("gate_e", None)]


def _layer(name, front):
    """사방 성곽 그림 파일 이름(단계 접미사 앞): 몸체는 name, 앞층은 wall_n_t3 → front_n_t3, 그 밖은 front_ + name"""
    if not front:
        return name
    return "front_n_t3" if name == "wall_n_t3" else "front_" + name


def castle():
    h = WALL_H
    out = Image.new("RGBA", (16 * sum(w for _, w in WALL_STRIPS) + 16 * sum(sum(w for _, w in st) if st else 3 for _, st in SQUARE), h * len(WALL_LAYERS)))
    for r, layer in enumerate(WALL_LAYERS):
        im = Image.open(f"art/trial/walls/{layer}.png").convert("RGBA")
        base = im.height - 4
        x = 0
        for strip, w in ([(0, 1)] if layer.startswith("rubble") else WALL_STRIPS):  # 잔해는 0번 칸 하나만 그렸다
            out.paste(im.crop((4 + strip * 16, base - h + 1, 4 + (strip + w) * 16, base + 1)), (x, h * r))
            x += 16 * w
    for r in range(6):  # 단계 1~3의 몸체·앞층. 통로 그늘·잔해 행은 비운다(닫힌 문루는 열리지 않고, 동·서 성벽은 남쪽 적이 부수지 못한다)
        level, front = r // 2 + 1, r % 2 == 1
        x = 16 * sum(w for _, w in WALL_STRIPS)
        for name, strips in SQUARE:
            if front and name.startswith("side_"):  # 동·서 성벽 띠는 발을 가릴 앞면이 없다
                x += 48
                continue
            im = Image.open(f"art/trial/walls/{_layer(name, front)}_L{level}.png").convert("RGBA")
            if strips is None:
                out.paste(im, (x, h * r))
                x += im.width
                continue
            base = im.height - 4
            for strip, w in strips:
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
