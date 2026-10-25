extends "res://tests/eval/gd/lib.gd"

# EV1 · S1: 구조물 없는 맵의 네 가장자리에서 나온 적이 모두 거점에 닿는다
func ev1():
	var edges := [Vector2i(0, 10), Vector2i(29, 10), Vector2i(15, 0), Vector2i(15, 19)]
	var b = battle({"base": Vector2i(15, 10), "base_hp": BIG, "spawns": edges})
	var es := edges.map(func(c): return b.spawn_enemy("basic", c))
	var ok := run(b, 120, func(): return es.all(func(e): return at_base(b, e)))
	return check(ok, "가장자리 네 곳의 적이 모두 거점에 닿지 못했다")

# EV2 · S2: 거점 체력이 0이 되면 패배
func ev2():
	var b = battle()
	b.damage(b.base, b.base.max_hp)
	return check(b.state == "lost", "거점 체력 0인데 판 상태가 %s다" % b.state)

# EV3 · S3: 웨이브의 적은 모두 맵 가장자리 칸에서 처음 나타난다
func ev3():
	var b = battle({"base_hp": BIG, "spawns": [Vector2i(0, 5), Vector2i(29, 15)], "waves": [[{"kind": "basic", "count": 6}]]})
	var firsts := []
	b.enemy_spawned.connect(func(e): firsts.append(cell_of(e)))
	b.start_battle()
	run(b, 120, func(): return firsts.size() >= 6)
	if firsts.size() < 6:
		return "적 6마리가 다 나오지 않았다 (%d마리)" % firsts.size()
	var inner := firsts.filter(func(c): return c.x > 0 and c.y > 0 and c.x < 29 and c.y < 19)
	return check(inner.is_empty(), "가장자리가 아닌 칸에서 나온 적: %s" % [inner])

# EV4 · S30: 화면 확대 방식이 canvas_items·정수배이고, 맵은 기준 해상도 SubViewport에 Nearest로 그린다
func ev4():
	var mode = ProjectSettings.get_setting("display/window/stretch/mode", "disabled")
	var scale = ProjectSettings.get_setting("display/window/stretch/scale_mode", "fractional")
	if mode != "canvas_items" or scale != "integer":
		return "확대 방식이 %s·%s다" % [mode, scale]
	var snap = ProjectSettings.get_setting("rendering/2d/snap/snap_2d_vertices_to_pixel", false)
	if not snap:
		return "꼭짓점 스냅이 꺼져 있다"
	load("res://src/sim/save.gd").path = "user://eval_save.dat"  # 실제 저장·설정을 건드리지 않게(save.gd 평가와 같은 파일)
	load("res://src/settings.gd").path = "user://eval_settings.cfg"
	load("res://src/main.gd").resume = {}
	var root: Window = Engine.get_main_loop().root
	var main = load("res://src/main.tscn").instantiate()
	root.add_child(main)
	var subs: Array = main.find_children("*", "SubViewport", true, false)
	var cams: Array = main.find_children("*", "Camera2D", true, false)
	var view = main.get("view")
	var ok: bool = subs.is_empty() and view != null and view.get_viewport() == root and cams.size() == 1 and cams[0].get_viewport() == root
	var why := "게임 장면의 SubViewport %d개 · 판 그림이 루트 뷰포트에 %s · 카메라 %d개(루트 뷰포트에 %s)" % [subs.size(), view != null and view.get_viewport() == root, cams.size(), cams.all(func(c): return c.get_viewport() == root)]
	main.free()
	return check(ok, why)

# EV303 · S161: 창 모드 배수는 작업 영역에 창 테두리까지 들어가는 가장 큰 정수배다. 들어가는 배수가 없으면 1배
func ev303():
	var main = load("res://src/main.gd")
	var cases := [  # [작업 영역, 테두리, 기대 배수]
		[Vector2i(3840, 2088), Vector2i(0, 45), 5], [Vector2i(1920, 1032), Vector2i(0, 31), 2],
		[Vector2i(2560, 1392), Vector2i(0, 31), 3], [Vector2i(1280, 765), Vector2i(0, 45), 2],
		[Vector2i(1279, 765), Vector2i(0, 45), 1], [Vector2i(600, 300), Vector2i(0, 45), 1],
	]
	for c in cases:
		var k: int = main.window_scale(c[0], c[1], Vector2i(640, 360))
		if k != c[2]:
			return "작업 영역 %s·테두리 %s에서 %d배를 골랐다(기대 %d배)" % [c[0], c[1], k, c[2]]
	return ""

# EV304 · S164: main이 창을 준비하면 창 최소 크기가 기준 해상도의 2배(1280×720)다
func ev304():
	var w: Window = Engine.get_main_loop().root
	load("res://src/main.gd").setup_window(w, false)
	return check(w.min_size == Vector2i(1280, 720), "창 최소 크기가 %s다" % w.min_size)
