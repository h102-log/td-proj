extends RefCounted
# 마을 돌길(S202)이 성문 셋의 안쪽과 거점 문 앞을 덮고, 마을 위쪽 빈 땅은 흙으로 두는지 본다(WBS 4.1h).
# 지키는 요구:
#   S202. 마을(S43)은 흙바닥(S169) 위에 «돌길·광장»으로 꾸민다. 성벽 안쪽을 따라 돌길이 마을 폭 전체에 나서 성문 셋을 잇고,
#         정문 앞에서 거점 앞까지 광장으로 넓어진다. 거점 옆에 우물을 두고 … 시설이 선 칸의 우물은 그리지 않는다.
#         → 2026-10-23 변경: 큰 박석으로 깔고 줄눈은 칠하지 않는다. 그래서 한 점이 아니라 둘레 9×7px에서 칠한 비율을 본다.

const Main := preload("res://src/main.gd")
const View := preload("res://src/ui/battle_view.gd")

# 가운데 c 둘레 9×7px 가운데 칠한(투명하지 않은) 픽셀 비율
static func _paved(img: Image, c: Vector2i) -> float:
	var n := 0
	for dy in range(-3, 4):
		for dx in range(-4, 5):
			n += int(img.get_pixelv(c + Vector2i(dx, dy)).a > 0.0)
	return n / 63.0

func test_pave_covers_gates_and_keep_front_only():
	var b = load("res://src/sim/battle.gd").new(Main.stage())
	var img := Image.create_empty(b.size.x * View.CELL, b.size.y * View.CELL, false, Image.FORMAT_RGBA8)  # 칠하지 않은 픽셀은 투명
	var rng := RandomNumberGenerator.new()
	View._pave(b, img, rng)
	var wall_top: int = b.village.end.y * View.CELL
	for g in b.castle:
		if b.castle[g].kind == "gate" and _paved(img, Vector2i(g.x * View.CELL + 8, wall_top - 34)) < 0.5:
			return "성문 %s 안쪽(성벽 그림 바로 위)에 돌길이 없다" % g
	var door := Vector2i(b.base.cell.x * View.CELL + 8, (b.base.cell.y + 1) * View.CELL + 4)
	if _paved(img, door) < 0.5:
		return "거점 문 앞 %s에 광장이 없다" % door
	for bare in [Vector2i(5, 2) * View.CELL, Vector2i(5, 5) * View.CELL]:  # 마을 위쪽, 거점에서 먼 광장 높이
		if _paved(img, bare) > 0.0:
			return "마을 %s까지 돌을 깔았다(흙이어야 한다)" % bare
	return ""

func test_well_beside_keep():
	var b = load("res://src/sim/battle.gd").new(Main.stage())
	var wells: Array = View.ground_props(b).filter(func(p): return p[1] == 12)
	if wells.size() != 1 or not b.village.has_point(wells[0][0]) or wells[0][0] == b.base.cell:
		return "우물이 %s다(거점이 아닌 마을 칸 하나여야 한다)" % [wells]
	return ""
