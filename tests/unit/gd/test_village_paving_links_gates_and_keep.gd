extends RefCounted
# 마을 박석(S202)이 거점 광장·남쪽 큰길·정문 안 공터에만 깔리고, 우물이 광장 모서리에 있는지 본다(WBS 4.1h, 4.1o).
# 지키는 요구:
#   S202. 마을(S43)은 흙바닥(S169) 위에 «돌길·광장»으로 꾸민다 … 거점 옆에 우물을 두고 … 시설이 선 칸의 우물은 그리지 않는다.
#         → 2026-10-23 변경: 큰 박석으로 깔고 줄눈은 칠하지 않는다. 그래서 한 점이 아니라 둘레 9×7px에서 칠한 비율을 본다.
#         → 2026-10-26 둘째 변경: 박석은 거점 둘레 광장, 남쪽 큰길(박석–흙–박석), 정문 안 공터에만 깐다. 성벽 안쪽 박석 띠는 없앤다.
#           우물은 거점에서 오른쪽 5칸·아래 3칸(광장 오른쪽 아래 모서리)이다.

const Main := preload("res://src/main.gd")
const View := preload("res://src/ui/battle_view.gd")

# 가운데 c 둘레 9×7px 가운데 칠한(투명하지 않은) 픽셀 비율
static func _paved(img: Image, c: Vector2i) -> float:
	var n := 0
	for dy in range(-3, 4):
		for dx in range(-4, 5):
			n += int(img.get_pixelv(c + Vector2i(dx, dy)).a > 0.0)
	return n / 63.0

static func _mid(c: Vector2i) -> Vector2i:
	return c * View.CELL + Vector2i(8, 8)

func test_pave_only_plaza_south_road_and_gate_apron():
	var b = load("res://src/sim/battle.gd").new(Main.stage())
	var img := Image.create_empty(b.size.x * View.CELL, b.size.y * View.CELL, false, Image.FORMAT_RGBA8)  # 칠하지 않은 픽셀은 투명
	var rng := RandomNumberGenerator.new()
	View._pave(b, img, rng, View._plan().pave)
	var k: Vector2i = b.base.cell
	var wall_top: int = b.village.end.y * View.CELL
	if _paved(img, Vector2i(k.x * View.CELL + 8, wall_top - 34)) < 0.5:
		return "정문 안 공터(남벽 그림 바로 위)에 박석이 없다"
	for c in [Vector2i(30, 4), Vector2i(4, 30), Vector2i(55, 30)]:  # 북·서·동 닫힌 문루 안 공터(S202 2026-10-26 넷째 변경)
		if _paved(img, _mid(c)) < 0.5:
			return "닫힌 문루 안 공터 %s에 박석이 없다" % c
	for c in [k + Vector2i(0, 1), k + Vector2i(-6, 0), k + Vector2i(6, 0), k + Vector2i(-1, 7), k + Vector2i(1, 7)]:  # 거점 문 앞, 광장 양 끝, 남쪽 큰길 양 가장자리
		if _paved(img, _mid(c)) < 0.5:
			return "%s에 박석이 없다" % c
	if _paved(img, _mid(k + Vector2i(0, 7))) > 0.3:  # 남쪽 큰길 가운데는 흙. 양옆 칸 박석이 몇 px 넘어올 수 있다
		return "남쪽 큰길 가운데 %s까지 박석을 깔았다" % (k + Vector2i(0, 7))
	for p in [Vector2i(10 * View.CELL + 8, wall_top - 34), Vector2i(50 * View.CELL + 8, wall_top - 34), _mid(Vector2i(5, 2)), _mid(Vector2i(15, 30))]:  # 남벽 그림 바로 위(옛 박석 띠, 아래 그늘 줄은 피함), 북벽, 서쪽 큰길(흙)
		if _paved(img, p) > 0.0:
			return "%s까지 박석을 깔았다(흙이나 풀이어야 한다)" % p
	return ""

func test_well_at_plaza_corner():
	var b = load("res://src/sim/battle.gd").new(Main.stage())
	var wells: Array = View.ground_props(b).filter(func(p): return p[1] == 12)
	if wells.size() != 1 or wells[0][0] != b.base.cell + Vector2i(5, 3) or not View._plan().pave.has(wells[0][0]):
		return "우물이 %s다(거점 +5, +3의 광장 박석 칸 하나여야 한다)" % [wells]
	return ""
