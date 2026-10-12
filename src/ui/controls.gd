extends RefCounted
# 마우스·키 입력을 전투 명령으로 바꾼다. 마우스 좌표는 맵 px(칸 (x,y)가 [x, x+1) × cell_px)로 받는다.
# 좌클릭: 영웅을 고르거나(I9) 선택을 푼다 · 좌드래그: 사각형 안의 용병을 고른다(S16, I9) · 우클릭: 고른 유닛 이동(S14)
# Q: 영웅 스킬(I10) · A: 고른 용병의 이동 방식 전환(S35) · H: 홀드 전환(S36) (A·H는 사용자 2026-10-12)

# ponytail: 맵 px 기준이라 줌에 따라 화면에서 느끼는 거리가 달라진다. 거슬리면 화면 px로 잰다
const CLICK_SLOP := 4.0  # 이보다 덜 끌고 떼면 클릭이다(맵 px)

var battle
var cell_px: int
var selected := []
var drag_rect := Rect2()  # 끌고 있는 선택 사각형(맵 px). 그리기용이고, 끌고 있지 않으면 크기 0
var _press = null  # 좌버튼을 누른 위치(맵 px)

func _init(b, px: int) -> void:
	battle = b
	cell_px = px

func handle(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_Q:
				battle.use_skill()
			KEY_A:  # 모두 «무조건 이동»이면 «이동 중 공격»으로, 아니면 모두 «무조건 이동»으로
				battle.set_move_mode(selected, "attack_move" if selected.all(func(u): return u.move_mode == "move") else "move")
			KEY_H:
				battle.set_hold(selected, not selected.all(func(u): return u.hold))
	if event is InputEventMouseMotion and _press != null:
		drag_rect = Rect2(_press, event.position - _press).abs()
	if not event is InputEventMouseButton:
		return
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press = event.position
		elif _press != null:
			_release(Rect2(_press, event.position - _press).abs())
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		battle.order_move(selected, Vector2i((event.position / cell_px).floor()))

func _release(rect: Rect2) -> void:
	_press = null
	drag_rect = Rect2()
	var h = battle.hero
	if rect.size.length() < CLICK_SLOP:
		var cell := Vector2i((rect.position / cell_px).floor())
		selected = [h] if h and h.alive and Vector2i(h.pos.round()) == cell else []
	else:
		selected = battle.units.filter(func(u): return u != h and rect.has_point((u.pos + Vector2(0.5, 0.5)) * cell_px))
