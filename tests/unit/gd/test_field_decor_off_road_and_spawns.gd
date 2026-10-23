extends RefCounted
# 들판 장식(S201)이 길·출현 지점 둘레·성곽 바로 앞 줄·맨 아래 줄을 비우고, 길이 출현 지점마다 정문까지 이어지며,
# 바닥 그림이 맵 밖 띠(I50)까지 한 장인지 본다(WBS 4.1h).
# 지키는 요구:
#   S201. 정문에서 맵 아래끝까지 흙길이 나고, 다른 출현 지점에서는 오솔길이 이 큰길로 합류한다. 빈 들판 칸에는 그을음·포탄 구덩이·자갈·풀 포기를
#         바닥에 그리고 바위·그루터기를 놓는다. … 맵 아래 맵 밖 띠(I50)에는 그을린 흙 바닥에 마른 나무를 세운다.

const Main := preload("res://src/main.gd")
const View := preload("res://src/ui/battle_view.gd")
const Camera := preload("res://src/ui/camera.gd")

func _battle():
	return load("res://src/sim/battle.gd").new(Main.stage())

func test_props_stay_on_open_field():
	var b = _battle()
	var road: Dictionary = View._road(b)
	var props: Array = View.ground_props(b).filter(func(p): return p[1] < 5)
	var want := roundi(15 * View._field_scale(b))  # 바위 9·그루터기 6은 40×22 들판 기준이고 넓이에 비례한다(S203)
	if props.size() != want:
		return "소품이 %d개다(%d개여야 한다)" % [props.size(), want]
	for p in props:
		var c: Vector2i = p[0]
		if c.y <= b.village.end.y + 1 or c.y >= b.size.y - 1:
			return "%s는 성곽 바로 앞 줄이나 맨 아래 줄이다" % c
		if [c, c + Vector2i.RIGHT, c + Vector2i.DOWN, c + Vector2i.ONE].any(func(v): return road.has(v)):
			return "%s가 길에 닿는다" % c
		if b.spawns.any(func(s): return absi(s.x - c.x) <= 1 and absi(s.y - c.y) <= 1):
			return "%s가 출현 지점 둘레 1칸 안이다" % c
	return ""

func test_road_joins_every_spawn_to_main_gate():
	var b = _battle()
	var road: Dictionary = View._road(b)
	var start := Vector2i(b.base.cell.x, b.village.end.y + 1)
	var seen := {start: true}
	var todo := [start]
	while todo:
		var p: Vector2i = todo.pop_back()
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if road.has(p + d) and not seen.has(p + d):
				seen[p + d] = true
				todo.append(p + d)
	for s in b.spawns:
		if not (seen.has(Vector2i(s.x, b.size.y)) or seen.has(Vector2i(s.x + 1, b.size.y))):
			return "출현 지점 %s의 맵 아래끝 꼭짓점이 정문 앞 길과 이어지지 않는다" % s
	return ""

func test_ground_covers_outside_strip():
	var b = _battle()
	var size: Vector2 = View.bake_ground(b).get_size()
	if size != Vector2(b.size.x * View.CELL, b.size.y * View.CELL + Camera.BOTTOM):
		return "바닥 그림이 %s다(맵 아래 맵 밖 띠 %d px까지여야 한다)" % [size, Camera.BOTTOM]
	return ""
