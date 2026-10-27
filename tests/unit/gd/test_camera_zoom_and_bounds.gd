extends RefCounted
# 카메라 줌 단계와 이동 범위를 본다(WBS 2.2a).
# 지키는 요구:
#   S52. 플레이어는 마우스 휠로 화면을 1×·2×·3× 정수배 단계로 확대·축소한다. 기본 배율은 2×다.
#   S53. 마우스를 창 가장자리에 대거나 그 너머 창 밖으로 내보내면 카메라가 그쪽으로 이동한다. ...
#   S68. 휠 버튼을 누른 채 끌면 잡은 땅이 커서를 따라오듯 카메라가 이동한다.
#   I50. 확대·축소는 커서 아래 지점을 기준으로 한다. 카메라는 아래로 72 ÷ 줌만큼만 맵 밖을 보인다(2026-10-21 변경).
#   S200. 성곽 붕괴 3px·보스 스킬 2px·보스 처치 3px(«약하게»는 절반 올림, «끔»은 0) 흔들림은 기준 화면 정수 px이고, 오른쪽·왼쪽·아래·위 차례로
#         2프레임마다 방향을 바꾸며 줄어든다. 화면 밖 사건은 흔들지 않고(보스 처치 빼고), 겹치면 센 것 하나다. steady()는 흔들림을 뺀 변환이다.

const MAP := Vector2(640, 512)
const DT := 1.0 / 60.0

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

# 사건 하나를 흘린 첫 프레임의 흔들림(offset × 줌)
func _jolt(cam, e: Dictionary) -> Vector2:
	cam._shake = [0, 0.0, 1.0]
	cam.rumble([e], DT)
	return cam.offset * cam.zoom.x

func test_shake_size_by_setting_event_and_screen():
	var st = load("res://src/settings.gd")
	var cam = _cam()
	var at: Vector2 = cam.position
	var far: Vector2 = cam.position + Vector2(2000, 0)
	var why := ""
	for z in [0, 1]:  # 2배·3배 줌
		cam.zoom_at(z, cam.get_viewport_rect().size / 2)
		for c in [[2, "collapse", at, null, 3], [1, "collapse", at, null, 2], [0, "collapse", at, null, 0], [2, "collapse", far, null, 0],
				[2, "boss", at, null, 2], [1, "boss", at, null, 1], [2, "kill", far, {"boss": true}, 3], [1, "kill", far, {"boss": true}, 2], [2, "kill", at, {}, 0]]:
			st.shake = c[0]
			var o := _jolt(cam, {"kind": c[1], "at": c[2], "dst": c[3]})
			if why == "" and (not o.is_equal_approx(o.round()) or roundi(o.length()) != c[4]):
				why = "줌 %s·설정 %d에서 %s(%s) 흔들림이 %s다(정수 %dpx여야 한다)" % [cam.zoom.x, c[0], c[1], "화면 밖" if c[2] == far else "화면 안", o, c[4]]
	st.shake = 2
	cam.free()
	return why

func test_shake_turns_every_two_frames_fades_and_stronger_wins():
	var st = load("res://src/settings.gd")
	st.shake = 2
	var cam = _cam()
	var seen := [_jolt(cam, {"kind": "collapse", "at": cam.position, "dst": null})]
	for i in 16:
		cam.rumble([], DT)
		seen.append(cam.offset * cam.zoom.x)
	var why := ""
	var dirs := [Vector2.RIGHT, Vector2.RIGHT, Vector2.LEFT, Vector2.LEFT, Vector2.DOWN, Vector2.DOWN, Vector2.UP, Vector2.UP]
	for i in 8:
		if why == "" and not seen[i].normalized().is_equal_approx(dirs[i]):
			why = "흔들림 %d프레임째 방향이 %s다(%s여야 한다): %s" % [i, seen[i], dirs[i], seen]
	for i in 16:
		if why == "" and seen[i + 1].length() > seen[i].length():
			why = "흔들림이 %d프레임째에 커졌다: %s" % [i + 1, seen]
	if why == "" and (seen[15] != Vector2.ZERO or seen[0].length() != 3.0 or seen[8].length() != 2.0):
		why = "붕괴 흔들림이 3px에서 시작해 0.15초에 2px로 줄고 0.25초 뒤 0이어야 한다: %s" % [seen]
	_jolt(cam, {"kind": "collapse", "at": cam.position, "dst": null})
	cam.rumble([{"kind": "boss", "at": cam.position, "dst": null}], DT)  # 더 약한 보스 스킬(2px)이 겹쳐도 붕괴(3px)를 이어 간다
	if why == "" and roundi((cam.offset * cam.zoom.x).length()) != 3:
		why = "붕괴 흔들림 중 보스 스킬이 나자 흔들림이 %s다(센 붕괴 3px를 이어야 한다)" % [cam.offset * cam.zoom.x]
	cam.free()
	return why

func test_steady_takes_shake_out_of_canvas_transform():
	var cam = _cam()
	cam.offset = Vector2(3, 0) / cam.zoom.x
	cam.force_update_scroll()
	var shaken: Transform2D = cam.get_viewport().get_canvas_transform()
	var got: Transform2D = cam.steady()
	cam.offset = Vector2.ZERO
	cam.force_update_scroll()
	var want: Transform2D = cam.get_viewport().get_canvas_transform()
	cam.free()
	if shaken.is_equal_approx(want):
		return "offset을 줘도 캔버스 변환이 그대로다(흔들림이 화면에 걸리지 않는다)"
	return "" if got.is_equal_approx(want) else "steady() %s가 흔들림 없는 변환 %s와 다르다" % [got, want]
