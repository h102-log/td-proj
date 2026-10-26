extends RefCounted
# 마을 풀 바탕(S169 2026-10-26 변경)·바랜 풀·시설 터와 마당 소품(S215)을 본다(WBS 4.1k).
# 지키는 요구:
#   S169 → 2026-10-26 변경: 마을 칸도 풀이다. 흙은 거점 줄 아래 광장 둘레와 성곽 위 세 줄, 그리고 시설 터(S215)뿐이다.
#         성 안 풀은 잡음으로 덩어리진 자리만 바래게 해 성 밖 들판과 가른다.
#   S215. 마을 시설은 짓기 시작하면 둘레에 흙 터를 깐다 … 사격장 터는 과녁 쪽(아래)으로 밟힌 줄이 난다.
#         → 2026-10-26 변경: 터는 차지 칸(S216) 가운데를 중심으로 하고 반지름은 차지 칸에 맞춘다(yard_radius).
#         돌길·광장 돌 위에는 깔지 않는다. 다 지으면 마당 소품을 붙인다 … 타워·성벽에는 터가 없다.

const Main := preload("res://src/main.gd")
const View := preload("res://src/ui/battle_view.gd")
const Battle := preload("res://src/sim/battle.gd")

static func _share(img: Image, c: Vector2i, col: Color) -> float:
	var n := 0
	for y in View.CELL:
		for x in View.CELL:
			n += int(img.get_pixelv(c * View.CELL + Vector2i(x, y)).is_equal_approx(col))
	return n / float(View.CELL * View.CELL)

func test_village_is_grass_but_wall_strip_and_plaza_edge():
	var b = Battle.new(Main.stage())
	var img: Image = View.bake_ground(b).get_image()
	for c in [Vector2i(5, 5), Vector2i(50, 10), Vector2i(10, 20), Vector2i(45, 3)]:  # 광장에서 먼 성 안 칸
		if _share(img, c, Color("2d472d")) < 0.5:
			return "성 안 %s가 풀이 아니다(풀색 %.2f)" % [c, _share(img, c, Color("2d472d"))]
	for c in [Vector2i(5, 25), Vector2i(50, 24), Vector2i(27, 20), Vector2i(33, 20)]:  # 성곽 위 세 줄, 광장 양 끝 칸
		if _share(img, c, Color("2d472d")) > 0.05:
			return "%s가 흙이 아니다(풀색 %.2f)" % [c, _share(img, c, Color("2d472d"))]
	return ""

func test_worn_grass_only_inside_above_wall_strip():
	var b = Battle.new(Main.stage())
	var img := Image.create_empty(b.size.x * View.CELL, b.size.y * View.CELL, false, Image.FORMAT_RGBA8)
	img.fill(Color("2d472d"))
	View._worn(b, img)
	var n := {"392a1c": 0, "684c3c": 0}  # 짙은 갈색·흙색으로 바뀐 픽셀 수
	var total := 0
	var top: int = (b.village.end.y - 3) * View.CELL
	for y in img.get_height():
		for x in img.get_width():
			var worn := not img.get_pixel(x, y).is_equal_approx(Color("2d472d"))
			if y >= top and worn:
				return "성곽 위 세 줄·성 밖 (%d, %d)까지 바랬다" % [x, y]
			if y < top:
				total += 1
				if worn:
					n[img.get_pixel(x, y).to_html(false)] += 1
	for k in n:
		if n[k] <= 0.01 * total:
			return "성 안 풀에 %s이 %d픽셀뿐이다" % [k, n[k]]
	if n["392a1c"] + n["684c3c"] > 0.22 * total:
		return "성 안 풀이 22%%보다 많이 바랬다(%s / %d)" % [n, total]
	return ""

# 데이터 크기(S216)를 단 구조물. Block.new는 크기를 모른다
static func _block(b, kind: String, cell: Vector2i):
	var s = Battle.Block.new(cell, kind, 10.0)
	s.size = b.STRUCTURE_KINDS[kind].size
	return s

func test_yard_ring_trample_and_no_stones():
	var b = Battle.new(Main.stage())
	var under: Image = View.bake_ground(b).get_image()
	var house = _block(b, "house", Vector2i(20, 10))  # 차지 칸 (20..21, 9..10)
	var y: Array = View.bake_yard(b, house, under)
	var img: Image = y[0].get_image()
	var center := Vector2(21, 10) * View.CELL + Vector2(0, 3)  # 차지 칸 가운데보다 3px 아래(S215 2026-10-26 변경)
	for k in 8:  # 반지름의 절반 고리는 잡음이 흔들어도 늘 터 안이다
		var p: Vector2 = center + Vector2.from_angle(k * TAU / 8) * View.yard_radius(house) * 0.5 - y[1]
		if img.get_pixelv(Vector2i(p)).a == 0.0:
			return "집 터 안쪽 %s가 비었다" % p
	for p in [Vector2i.ZERO, img.get_size() - Vector2i.ONE]:
		if img.get_pixelv(p).a > 0.0:
			return "집 터 그림의 모서리 %s까지 칠했다" % p
	var archery = _block(b, "archery", Vector2i(20, 10))  # 차지 칸 (20..22, 9..10)
	var a: Array = View.bake_yard(b, archery, under)
	var foot := Vector2i(Vector2(21.5, 10) * View.CELL + Vector2(0, 3 + View.yard_radius(archery).y + 10) - a[1])
	if not Rect2i(Vector2i.ZERO, a[0].get_size()).has_point(foot) or a[0].get_image().get_pixelv(foot).a == 0.0:  # 그림 밖을 읽으면 불투명 검정이 와서 먼저 범위를 본다
		return "사격장 터에 아래로 밟힌 줄이 없다"
	var plaza = _block(b, "house", b.base.cell + Vector2i(0, 5))  # 광장 한가운데
	var q: Array = View.bake_yard(b, plaza, under)
	var qi: Image = q[0].get_image()
	var stones := 0
	for py in qi.get_height():
		for px in qi.get_width():
			if under.get_pixel(px + int(q[1].x), py + int(q[1].y)).is_equal_approx(View.PAVE):
				stones += 1
				if qi.get_pixel(px, py).a > 0.0:
					return "광장 박석 (%d, %d) 위에 터를 깔았다" % [px, py]
	if stones == 0:
		return "광장 시험 칸 둘레에 박석이 없다(시험 칸이 틀렸다)"
	return ""

func test_props_only_when_built_and_not_for_towers():
	var house = _block(Battle.new(Main.stage()), "house", Vector2i(20, 10))
	if View.yard_props(house).size() != 3:
		return "다 지은 집의 마당 소품이 %s다(텃밭·울타리·장작 셋)" % [View.yard_props(house)]
	house.complete = false
	if not View.yard_props(house).is_empty():
		return "짓는 중인 집에 마당 소품이 있다"
	for kind in ["tower", "wall", "cannon", "magic"]:
		if View.YARDS.has(kind) or not View.yard_props(Battle.Block.new(Vector2i(20, 10), kind, 10.0)).is_empty():
			return "%s에 터나 마당 소품이 있다" % kind
	return ""
