extends RefCounted
# 맵(전장)을 SubViewport로 옮긴 뒤에도(S30) 마우스·키 입력이 예전과 같은 곳에 닿는지 본다.
# 진입 씬(main.tscn)을 붙이고 하네스(tools/play/play.gd)처럼 기준 해상도(640×360) 좌표로 입력을 넣는다.
# 지키는 요구:
#   S30. → 2026-10-19 변경: 맵(전장)은 기준 해상도로 그린 다음 창 크기에 맞춰 정수배로 확대한다. HUD는 같은 정수배로 키운 크기·위치에 놓되 화면 해상도로 그린다.
#   S52. 플레이어는 마우스 휠로 화면을 1×·2×·3× 정수배 단계로 확대·축소한다. 기본 배율은 2×다.
#   S68. 휠 버튼을 누른 채 끌면 잡은 땅이 커서를 따라오듯 카메라가 이동한다.
#   I13. 준비 단계는 플레이어가 «전투 시작»을 누르면 끝난다(카운트다운은 없다).
#   I94. 결과 창(S117)의 버튼은 전투 시작과 같은 키(Enter·Space)로도 누른다(I12).
#   I9. 영웅은 드래그 선택에 들어가지 않는다. — 그래서 드래그 선택은 용병으로 잰다
#   I58. 판매 팝업은 클릭하거나 드래그를 놓은 지점 옆에 뜨고, …
#   I137. 클릭한 곳 옆에 뜨는 팝업(I58)이 화면 밖으로 나가면 화면 안으로 당겨 띄운다.

const BOTTOM := Vector2(320, 300)  # HUD 윗줄(준비 단계 높이 196) 아래의 맵 자리

# 준비 단계의 진입 씬. 게임에서는 다음 프레임에 일어나는 두 가지를 바로 한다:
# 영입 창을 닫아 그 버튼이 쥔 키보드 포커스를 풀고(HUD _process), 카메라 위치를 맵 SubViewport의 화면 변환에 반영한다
func _main():
	var main = load("res://src/main.tscn").instantiate()
	Engine.get_main_loop().root.add_child(main)
	main.view.battle.next_round()
	main.hud._process(0.0)
	_cam(main).force_update_scroll()
	return main

func _push(e: InputEvent) -> void:
	Engine.get_main_loop().root.push_input(e, true)  # true: 이미 기준 해상도 좌표다

func _motion(at: Vector2, rel := Vector2.ZERO, mask := 0) -> void:
	var e := InputEventMouseMotion.new()
	e.position = at
	e.relative = rel
	e.button_mask = mask
	_push(e)

func _button(index: int, at: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = index
	e.position = at
	e.pressed = pressed
	_push(e)

func _cam(main) -> Camera2D:
	return main.view.get_viewport().get_camera_2d()

# 커서(기준 해상도 좌표) 아래의 맵 px. 카메라는 맵 SubViewport(640×360)의 가운데를 본다
func _under(cam: Camera2D, cursor: Vector2) -> Vector2:
	return cam.position + (cursor - Vector2(320, 180)) / cam.zoom.x

func test_mouse_reaches_controls_in_map_px():
	var main = _main()
	_motion(BOTTOM)
	var got: Vector2 = main.controls.mouse
	var want := _under(_cam(main), BOTTOM)
	main.free()
	return "" if got.is_equal_approx(want) else "커서 %s가 맵 px %s로 갔다(기대 %s)" % [BOTTOM, got, want]

func test_wheel_and_middle_drag_reach_camera():
	var main = _main()
	var cam := _cam(main)
	var world := _under(cam, BOTTOM)
	_button(MOUSE_BUTTON_WHEEL_UP, BOTTOM, true)
	_button(MOUSE_BUTTON_WHEEL_UP, BOTTOM, false)
	var zoom := cam.zoom.x
	var kept := _under(cam, BOTTOM)
	var x0 := cam.position.x
	_button(MOUSE_BUTTON_MIDDLE, BOTTOM, true)
	_motion(BOTTOM - Vector2(30, 0), Vector2(-30, 0), MOUSE_BUTTON_MASK_MIDDLE)
	_button(MOUSE_BUTTON_MIDDLE, BOTTOM - Vector2(30, 0), false)
	var moved := cam.position.x - x0
	main.free()
	if zoom != 3.0 or not kept.is_equal_approx(world):
		return "휠 위로 배율 %s, 커서 아래 지점 %s → %s(기대 3배, 그대로)" % [zoom, world, kept]
	return "" if is_equal_approx(moved, 10.0) else "휠 버튼으로 왼쪽 30px 끌어 카메라가 %s 움직였다(기대 +10)" % moved

func test_enter_starts_battle_after_map_click():
	var main = _main()
	_button(MOUSE_BUTTON_LEFT, BOTTOM, true)
	_button(MOUSE_BUTTON_LEFT, BOTTOM, false)
	var key := InputEventKey.new()
	key.keycode = KEY_ENTER
	key.physical_keycode = KEY_ENTER
	key.pressed = true
	_push(key)
	var state: String = main.view.battle.state
	var focus := str(main.get_viewport().gui_get_focus_owner())
	main.free()
	return "" if state == "battle" else "맵을 클릭한 뒤 Enter를 눌러도 %s 단계다(키보드 포커스: %s)" % [state, focus]

func test_sell_popup_opens_next_to_drag_release_point():
	var main = _main()
	var b = main.view.battle
	var merc = b.place_merc("soldier", Vector2i(14, 10))
	var cam := _cam(main)
	cam.position = Vector2(320, 150)  # 용병 칸(14,10)이 HUD 윗줄 아래에 보이게
	cam.force_update_scroll()
	var c: Vector2 = merc.pos * 16 + Vector2(8, 8)
	var p: Vector2 = (c - Vector2(10, 10) - cam.position) * cam.zoom.x + Vector2(320, 180)
	var q: Vector2 = (c + Vector2(10, 10) - cam.position) * cam.zoom.x + Vector2(320, 180)
	_motion(p)
	_button(MOUSE_BUTTON_LEFT, p, true)
	_motion(q, q - p, MOUSE_BUTTON_MASK_LEFT)
	_button(MOUSE_BUTTON_LEFT, q, false)
	main.hud._process(0.0)
	var selected: Array = main.controls.selected
	var at: Vector2 = main.hud._popup.position
	main.free()
	if selected != [merc]:
		return "용병을 둘러 끌었는데 고른 것이 %s다" % [selected]
	return "" if at.is_equal_approx(q + Vector2(6, 6)) else "판매 팝업이 %s에 떴다(기대: 놓은 지점 %s 옆 %s)" % [at, q, q + Vector2(6, 6)]
