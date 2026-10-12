extends RefCounted
# 카메라 줌 단계와 이동 범위를 본다(WBS 2.2a).
# 지키는 요구:
#   S52. 플레이어는 마우스 휠로 화면을 1×·2×·3× 정수배 단계로 확대·축소한다. 기본 배율은 2×다.
#   I50. 확대·축소는 커서 아래 지점을 기준으로 한다. 카메라는 맵 밖을 보여 주지 않고, ...

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

func test_camera_never_shows_outside_map():
	var cam = _cam()
	var c = cam.get_viewport_rect().size / 2
	for z in [-1, 0, 1]:
		cam.zoom_at(z, c)
		for dir in [Vector2(-1, -1), Vector2(1, 1)]:
			cam.pan(dir, 100.0)
			var half = cam.get_viewport_rect().size / 2 / cam.zoom.x
			var view := Rect2(cam.position - half, half * 2)
			if not Rect2(Vector2.ZERO, MAP).encloses(view):
				var why := "배율 %s에서 보이는 영역 %s가 맵 밖으로 나갔다" % [cam.zoom.x, view]
				cam.free()
				return why
	cam.free()
	return ""
