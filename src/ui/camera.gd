extends Camera2D
# 마우스 휠로 1·2·3배 정수배 줌(S52), 창 가장자리에 마우스를 대면 그쪽으로 이동(S53), 휠 버튼 드래그로 이동(S68).
# 맵 밖은 보이지 않는다(I50).

const ZOOMS := [1, 2, 3]
const EDGE := 16.0      # 가장자리로 치는 폭(창 px)
const SPEED := 320.0    # 초당 이동 거리(화면 px)

var map_px: Vector2     # 맵 크기(월드 px)
var level := 1          # ZOOMS의 인덱스, 기본 2배

func _ready() -> void:
	zoom = Vector2.ONE * ZOOMS[level]
	pan(Vector2.ZERO, 0.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_at(1, event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_at(-1, event.position)
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
		position -= event.relative / zoom.x  # 잡은 땅이 커서를 따라온다
		pan(Vector2.ZERO, 0.0)

func _process(delta: float) -> void:
	var w := get_window()
	if not w.has_focus():
		return
	# 2026-10-12
	# [동작] 마우스가 창 밖에 있어도 화면 좌표로 읽어 가장자리를 넘어간 쪽으로 계속 움직인다
	# [이유] 창 모드에서 가장자리를 넘어가면 멈춰서 스크롤이 잘 안 된다는 1차 시험 피드백(사용자 2026-10-12)
	var dir := edge_dir(Vector2(DisplayServer.mouse_get_position() - w.position), Vector2(w.size))
	if dir != Vector2.ZERO:
		pan(dir, delta)

# 창 기준 마우스 위치 m(창 px, 창 밖이면 범위를 벗어난다)이 가장자리에 걸린 방향
static func edge_dir(m: Vector2, size: Vector2) -> Vector2:
	return Vector2(int(m.x > size.x - EDGE) - int(m.x < EDGE), int(m.y > size.y - EDGE) - int(m.y < EDGE))

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
