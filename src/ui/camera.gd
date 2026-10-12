extends Camera2D
# 마우스 휠로 1·2·3배 정수배 줌(S52), 창 가장자리에 마우스를 대면 그쪽으로 이동(S53). 맵 밖은 보이지 않는다(I50).

const ZOOMS := [1, 2, 3]
const EDGE := 8.0       # 가장자리로 치는 폭(화면 px)
const SPEED := 320.0    # 초당 이동 거리(화면 px)

var map_px: Vector2     # 맵 크기(월드 px)
var level := 1          # ZOOMS의 인덱스, 기본 2배
var mouse_in := false

func _ready() -> void:
	zoom = Vector2.ONE * ZOOMS[level]
	get_window().mouse_entered.connect(func(): mouse_in = true)
	get_window().mouse_exited.connect(func(): mouse_in = false)
	pan(Vector2.ZERO, 0.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_at(1, event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_at(-1, event.position)

func _process(delta: float) -> void:
	if not mouse_in or not get_window().has_focus():
		return
	var m := get_viewport().get_mouse_position()
	var v := get_viewport_rect().size
	var dir := Vector2(int(m.x > v.x - EDGE) - int(m.x < EDGE), int(m.y > v.y - EDGE) - int(m.y < EDGE))
	if dir != Vector2.ZERO:
		pan(dir, delta)

# dir 방향으로 delta초만큼 옮기고 맵 안에 가둔다
func pan(dir: Vector2, delta: float) -> void:
	var half := get_viewport_rect().size / 2 / zoom.x
	position = (position + dir * SPEED * delta / zoom.x).clamp(half, map_px - half)

# 커서 아래 월드 지점이 그대로 있게 확대 단계를 바꾼다
func zoom_at(step: int, cursor: Vector2) -> void:
	var next := clampi(level + step, 0, ZOOMS.size() - 1)
	if next == level:
		return
	var off := cursor - get_viewport_rect().size / 2
	position += off / zoom.x - off / ZOOMS[next]
	level = next
	zoom = Vector2.ONE * ZOOMS[level]
	pan(Vector2.ZERO, 0.0)
