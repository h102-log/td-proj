extends RefCounted
# 마우스·키 입력을 전투 명령으로 바꾼다. 마우스 좌표는 맵 px(칸 (x,y)가 [x, x+1) × cell_px)로 받는다.
# 좌클릭: 영웅을 고르거나(I9) 선택을 푼다 · 우클릭: 고른 유닛 이동(S14) · Q: 영웅 스킬(I10)

var battle
var cell_px: int
var selected := []

func _init(b, px: int) -> void:
	battle = b
	cell_px = px

func handle(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_Q:
		battle.use_skill()
	if not (event is InputEventMouseButton and event.pressed):
		return
	var cell := Vector2i((event.position / cell_px).floor())
	if event.button_index == MOUSE_BUTTON_LEFT:
		var h = battle.hero
		selected = [h] if h and h.alive and Vector2i(h.pos.round()) == cell else []
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		battle.order_move(selected, cell)
