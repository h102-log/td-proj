extends RefCounted
# 카메라 줌 단계와 이동 범위를 본다(WBS 2.2a).
# 지키는 요구:
#   S52. 플레이어는 마우스 휠로 화면을 1×·2×·3× 정수배 단계로 확대·축소한다. 기본 배율은 2×다.
#   S53. 마우스를 창 가장자리에 대거나 그 너머 창 밖으로 내보내면 카메라가 그쪽으로 이동한다. ...
#   S68. 휠 버튼을 누른 채 끌면 잡은 땅이 커서를 따라오듯 카메라가 이동한다.
#   I50. 확대·축소는 커서 아래 지점을 기준으로 한다. 카메라는 아래로 72 ÷ 줌만큼만 맵 밖을 보인다(2026-10-21 변경).

const MAP := Vector2(640, 512)

func _cam():
	var cam = load("res://src/ui/camera.gd").new()
	cam.map_px = MAP
	cam.position = MAP / 2
	Engine.get_main_loop().root.add_child(cam)
	return cam

# 커서 아래에 있는 월드 지점
func _under(cam, cursor: Vector2) -> Vector2:
	return cam.position + (cursor - cam.get_viewport_rect().size / 2) / cam.zoom.x

func test_wheel_zoom_steps_between_1x_and_3x():
	var cam = _cam()
	var c = cam.get_viewport_rect().size / 2
	var seen := [cam.zoom.x]
	for step in [1, 1, -1, -1, -1, -1]:
		cam.zoom_at(step, c)
		seen.append(cam.zoom.x)
	cam.free()
	return "" if seen == [2.0, 3.0, 3.0, 2.0, 1.0, 1.0, 1.0] else "배율이 %s 순서로 바뀌었다" % [seen]

func test_zoom_keeps_point_under_cursor():
	var cam = _cam()
	var cursor := Vector2(500, 100)
	var before := _under(cam, cursor)
	cam.zoom_at(1, cursor)
	var after := _under(cam, cursor)
	cam.free()
	return "" if before.is_equal_approx(after) else "커서 아래 지점이 %s에서 %s로 바뀌었다" % [before, after]

func test_camera_shows_outside_map_only_above_and_below():
	var cam = _cam()
	var c = cam.get_viewport_rect().size / 2
	for z in [-1, 0, 1]:
		cam.zoom_at(z, c)
		var below: float = cam.BOTTOM / cam.zoom.x
		var above: float = cam.TOP + cam.TOP_BAR / cam.zoom.x  # 위 여백(I50 2026-10-26 변경)
		for dir in [Vector2(-1, -1), Vector2(1, 1)]:
			cam.pan(dir, 100.0)
			var half = cam.get_viewport_rect().size / 2 / cam.zoom.x
			var view := Rect2(cam.position - half, half * 2)
			if not Rect2(Vector2(0, -above), MAP + Vector2(0, above + below)).grow(0.01).encloses(view) or (dir.y > 0 and absf(view.end.y - MAP.y - below) > 0.01) or (dir.y < 0 and absf(view.position.y + above) > 0.01):
				var why := "배율 %s에서 보이는 영역 %s가 맵과 위 여백 %.1f·아래 여백 %.1f를 벗어나거나 끝에 닿지 않았다" % [cam.zoom.x, view, above, below]
				cam.free()
				return why
	cam.free()
	return ""

func test_edge_dir_keeps_going_outside_window():
	var cam = load("res://src/ui/camera.gd")
	var size := Vector2(1280, 720)
	var cases := {Vector2(640, 360): Vector2.ZERO, Vector2(2, 360): Vector2(-1, 0), Vector2(-300, 360): Vector2(-1, 0),
		Vector2(1500, -40): Vector2(1, -1), Vector2(640, 900): Vector2(0, 1), Vector2(640, 3): Vector2(0, -1), Vector2(640, 4): Vector2.ZERO, Vector2(640, 10): Vector2.ZERO}
	for m in cases:
		if cam.edge_dir(m, size) != cases[m]:
			return "마우스 %s에서 방향이 %s다(기대 %s)" % [m, cam.edge_dir(m, size), cases[m]]
	return ""

func test_middle_drag_moves_ground_with_cursor():
	var cam = _cam()
	var before: Vector2 = cam.position
	var ev := InputEventMouseMotion.new()
	ev.button_mask = MOUSE_BUTTON_MASK_MIDDLE
	ev.relative = Vector2(10, -6)
	cam._unhandled_input(ev)
	var moved: Vector2 = cam.position - before
	cam.free()
	return "" if moved.is_equal_approx(Vector2(-10, 6) / 2) else "2배 줌에서 (10,-6) 끌었는데 카메라가 %s 움직였다" % [moved]
