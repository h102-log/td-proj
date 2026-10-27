extends Camera2D
# 마우스 휠로 1·2·3배 정수배 줌(S52), 창 가장자리에 마우스를 대거나 방향키를 누르면 그쪽으로 이동(S53), 휠 버튼 드래그로 이동(S68).
# HUD 버튼·미니맵(S209) 위에서는 가장자리 이동을 멈추고, 위쪽 가장자리는 창 맨 위 4 창 px만 친다(S53).
# 맵 밖은 아래로 건설 격자 높이만큼만 보인다(I50).
# 가장자리·방향키 이동은 가감속하고(S53), 휠 줌은 정수 화면 배율만 지나며 옮겨 가고(S52), HUD가 옮기는 카메라는 미끄러진다(I164).
# 그 움직임은 glide(delta)가 흘린다. pan·zoom_at·focus는 바로 옮기는 한 걸음이다.

const Settings := preload("res://src/settings.gd")
const Minimap := preload("res://src/ui/hud_minimap.gd")
const ZOOMS := [1, 2, 3]
const EDGE := 16.0      # 가장자리로 치는 폭(창 px)
const TOP_EDGE := 4.0   # 위쪽 가장자리로 치는 폭(창 px, S53 임시값). 위 띠 버튼을 누르러 가다 화면이 움직이지 않게
const BOTTOM := 72.0    # 아래로 맵 밖을 보이는 높이(화면 px, I50). 건설 격자(S186) 높이라 맨 아래 출현 지점이 격자에 가리지 않는다
const TOP := 64.0       # 위로 맵 밖을 보이는 높이(맵 px, I50 2026-10-26 변경). 사방 성곽의 북벽 그림이 맵 위로 56px까지 솟는다(S219)
const TOP_BAR := 28.0   # 위 띠 높이(화면 px, hud VIEW). 위로는 그만큼 더 나가 북벽이 위 띠에 가리지 않는다
const SPEED := 640.0  # 초당 이동 거리(화면 px). 설정 «카메라 속도»(%)를 곱한다(S53)
const FOCUS := Vector2(320, 194)  # HUD가 카메라를 대상으로 옮길 때 대상이 오는 화면 자리(I164). 위 띠 아래 빈 영역 가운데
# 가속·감속·ease-out 시간(초). Claude 시안 값이다(insights/2026-10-25_motion_camera_feel.md «시안»)
const ACCEL := 0.12  # 가장자리·방향키 이동이 최고 속도까지 오르는 시간(S53)
const DECEL := 0.15  # 입력이 없으면 서는 시간(S53)
const GLIDE := 0.2   # 부드러운 줌(S52)·미끄러짐(I164)
const SHAKE := {"collapse": [3, 0.25], "boss": [2, 0.2], "boss_kill": [3, 0.35]}  # 화면 흔들림(S200): 사건 → [«보통» 크기(기준 화면 px), 길이(초)]. «약하게»는 크기 절반 올림
const SHAKE_DIRS := [Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP]  # 흔들림 방향 차례. 2프레임마다 다음으로(S200)
const SHAKE_OFF := 32.0  # 보이는 사각형을 이만큼(맵 px, 2칸) 키운 범위 밖의 사건은 흔들지 않는다(S200)

var map_px: Vector2     # 맵 크기(월드 px)
var level := 1          # ZOOMS의 인덱스, 기본 2배. 부드러운 줌 중에는 가는 단계다
var manual := true      # 실제 마우스 가장자리·방향키를 읽는다. 관찰 하네스(tools/play)는 끄고 glide만 흘린다
var _vel := Vector2.ZERO  # 가장자리·방향키 이동 속도(화면 px/초)
var _driven := false    # 이번 프레임에 가장자리·방향키 입력이 있었다. 없으면 glide가 감속한다
var _zoom_from := 0.0   # 부드러운 줌이 출발한 화면 배율(줌 × 창 배율)
var _zoom_t := 1.0      # 부드러운 줌 진행(0~1). 1이면 멈춰 있다
var _anchor := Vector2.ZERO  # 부드러운 줌 동안 그대로 둘 커서 자리(I50)
var _slide := [Vector2.ZERO, Vector2.ZERO]  # 미끄러짐의 출발·도착 자리
var _slide_t := 1.0     # 미끄러짐 진행(0~1). 1이면 멈춰 있다
var _shake := [0, 0.0, 1.0]  # 지금 흔들림 [크기(기준 화면 px), 지난 초, 길이(초)]
var _beat := 0          # rumble을 부른 프레임 수. 흔들림 방향을 고른다

func _ready() -> void:
	zoom = Vector2.ONE * ZOOMS[level]
	pan(Vector2.ZERO, 0.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_smooth(1, event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_smooth(-1, event.position)
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
		_slide_t = 1.0
		position -= event.relative / zoom.x  # 잡은 땅이 커서를 따라온다
		pan(Vector2.ZERO, 0.0)

func _process(delta: float) -> void:
	var w := get_window()
	if manual and w.has_focus():
		# 2026-10-12
		# [동작] 마우스가 창 밖에 있어도 화면 좌표로 읽어 가장자리를 넘어간 쪽으로 계속 움직인다
		# [이유] 창 모드에서 가장자리를 넘어가면 멈춰서 스크롤이 잘 안 된다는 1차 시험 피드백(사용자 2026-10-12)
		scroll(Vector2(DisplayServer.mouse_get_position() - w.position), Vector2(w.size), delta)
		keys(delta)
	glide(delta)

# 방향키 이동(S53). 버튼에 키보드 포커스가 있으면(영입 창·결과 창, I110) 방향키는 그 버튼이 쓴다
func keys(delta: float) -> void:
	if get_tree().root.gui_get_focus_owner() != null:
		return
	var dir := Vector2(int(Input.is_key_pressed(KEY_RIGHT)) - int(Input.is_key_pressed(KEY_LEFT)), int(Input.is_key_pressed(KEY_DOWN)) - int(Input.is_key_pressed(KEY_UP)))
	if dir != Vector2.ZERO:
		_drive(dir, delta)

# 가장자리 이동(S53). 커서가 HUD 버튼·미니맵(S209) 위면 멈춘다. HUD는 루트 뷰포트에 있어 그 호버를 본다
func scroll(m: Vector2, size: Vector2, delta: float) -> void:
	var over := get_tree().root.gui_get_hovered_control()
	if over is BaseButton or over is Minimap:
		return
	var dir := edge_dir(m, size)
	if dir != Vector2.ZERO:
		_drive(dir, delta)

# 창 기준 마우스 위치 m(창 px, 창 밖이면 범위를 벗어난다)이 가장자리에 걸린 방향
static func edge_dir(m: Vector2, size: Vector2) -> Vector2:
	return Vector2(int(m.x > size.x - EDGE) - int(m.x < EDGE), int(m.y > size.y - EDGE) - int(m.y < TOP_EDGE))

# 가장자리·방향키 이동 한 프레임(S53): 속도를 dir 쪽 최고 속도로 ACCEL초에 걸쳐 올려(dir이 0이면 DECEL초에 걸쳐 내려) 그만큼 옮긴다.
# 한 번에 ACCEL초보다 긴 delta면 바로 최고 속도다. 맵 경계에 막힌 축은 속도를 버린다
func _drive(dir: Vector2, delta: float) -> void:
	var top := SPEED * Settings.camera_speed / 100.0
	_vel = _vel.move_toward(dir * top, top / (ACCEL if dir != Vector2.ZERO else DECEL) * delta)
	if dir != Vector2.ZERO:
		_driven = true
		_slide_t = 1.0
	var want := position + _vel * delta / zoom.x
	position = want
	pan(Vector2.ZERO, 0.0)
	if not is_equal_approx(position.x, want.x):
		_vel.x = 0.0
	if not is_equal_approx(position.y, want.y):
		_vel.y = 0.0

# 가감속·부드러운 줌·미끄러짐을 delta초 흘린다. 게임은 매 프레임 입력을 읽은 뒤 부르고, 하네스·평가는 직접 부른다
func glide(delta: float) -> void:
	if not _driven and _vel != Vector2.ZERO:
		_drive(Vector2.ZERO, delta)
	_driven = false
	if _zoom_t < 1.0:
		_zoom_t = minf(_zoom_t + delta / GLIDE, 1.0)
		var k := _scale()
		var s := lerpf(_zoom_from, ZOOMS[level] * k, 1.0 - pow(1.0 - _zoom_t, 2.0))
		_set_zoom(roundf(s) / k, _anchor)  # 화면 배율은 정수만 지난다. 아트 1px이 늘 정수 화면 px라 도트가 번지지 않는다
	if _slide_t < 1.0:
		_slide_t = minf(_slide_t + delta / GLIDE, 1.0)
		position = _slide[0].lerp(_slide[1], 1.0 - pow(1.0 - _slide_t, 2.0))

# 화면 흔들림(S200): 이번 프레임의 사건 목록(view.events)에서 흔들림을 고르고 dt초 흘려 offset에 둔다.
# main·하네스가 view.tick 다음에 부른다(ESC 메뉴면 main이 멈춰 흔들림도 멈춘다). offset × 줌은 늘 정수 기준 화면 px다
func rumble(events: Array, dt: float) -> void:
	var half := get_viewport_rect().size / 2 / zoom.x
	var seen := Rect2(position - half, half * 2).grow(SHAKE_OFF)
	for e in events:
		var kind: String = e.kind if e.kind != "kill" else ("boss_kill" if e.dst != null and e.dst.get("boss") else "")
		if SHAKE.has(kind) and Settings.shake > 0 and (kind == "boss_kill" or seen.has_point(e.at)):
			var px: int = SHAKE[kind][0] if Settings.shake == 2 else ceili(SHAKE[kind][0] / 2.0)
			if px >= shake_px():  # 겹치면 그 순간 더 센 것 하나
				_shake = [px, 0.0, SHAKE[kind][1]]
				_beat = 0
	_shake[1] += dt
	var n := shake_px() if Settings.shake > 0 else 0
	offset = SHAKE_DIRS[_beat / 2 % SHAKE_DIRS.size()] * n / zoom.x
	_beat += 1

# 지금 흔들림 크기(기준 화면 px): 선형으로 줄어든 크기를 올림한 정수
func shake_px() -> int:
	return maxi(ceili(_shake[0] * (1.0 - _shake[1] / _shake[2])), 0)

# 흔들림을 뺀 캔버스 변환(S200). HUD 팝업·표식·미니맵 사각형과 맵 클릭은 맵 자리를 이것으로 잡아 흔들리지 않는다
func steady() -> Transform2D:
	return get_viewport().get_canvas_transform().translated(offset * zoom)

# 가감속·부드러운 줌·미끄러짐이 아직 움직이는 중이다
func busy() -> bool:
	return _vel != Vector2.ZERO or _zoom_t < 1.0 or _slide_t < 1.0

# 창 배율(루트 stretch의 정수배, 1280×720 창 2·4K 전체화면 6). 화면 배율은 줌 × 이것이다
func _scale() -> float:
	return maxf(get_viewport().get_stretch_transform().x.x, 1.0)

# dir 방향으로 delta초만큼 옮기고 맵 안에 가둔다. 아래는 BOTTOM ÷ 줌, 위는 TOP + TOP_BAR ÷ 줌만큼 맵 밖으로 나간다(I50)
func pan(dir: Vector2, delta: float) -> void:
	var half := get_viewport_rect().size / 2 / zoom.x
	position = (position + dir * SPEED * Settings.camera_speed / 100.0 * delta / zoom.x).clamp(half - Vector2(0, TOP + TOP_BAR / zoom.x), map_px - half + Vector2(0, BOTTOM / zoom.x))

# 맵 px의 대상을 화면 FOCUS에 바로 놓고 경계 안으로 당긴다(I164)
func focus(at: Vector2) -> void:
	position = at - (FOCUS - get_viewport_rect().size / 2) / zoom.x
	pan(Vector2.ZERO, 0.0)

# 미니맵이 카메라를 대상으로 바로 옮긴다(S209). 미끄러짐과 가장자리·방향키 속도는 버린다
func jump(at: Vector2) -> void:
	_slide_t = 1.0
	_vel = Vector2.ZERO
	focus(at)

# HUD가 카메라를 대상으로 옮긴다(I164): focus 자리까지 GLIDE초 동안 ease-out으로 미끄러진다. 사람이 카메라를 움직이면 버린다
func slide(at: Vector2) -> void:
	var from := position
	focus(at)
	_slide = [from, position]
	position = from
	_slide_t = 0.0

# 아래 경계에 닿아 있다. 정보 칸이 격자 왼쪽으로 옮긴다(S186)
func at_bottom() -> bool:
	return position.y >= map_px.y - get_viewport_rect().size.y / 2 / zoom.x + BOTTOM / zoom.x - 0.01

# 휠 줌(S52): 단계를 바꾸고 화면 배율을 GLIDE초 동안 ease-out으로 옮긴다. 옮기는 중이면 지금 배율에서 이어 간다
func zoom_smooth(step: int, cursor: Vector2) -> void:
	var next := clampi(level + step, 0, ZOOMS.size() - 1)
	if next == level:
		return
	_zoom_from = zoom.x * _scale()
	level = next
	_zoom_t = 0.0
	_anchor = cursor
	_slide_t = 1.0

# 커서 아래 월드 지점이 그대로 있게 확대 단계를 바로 바꾼다(평가·유닛 시험이 판을 차릴 때)
func zoom_at(step: int, cursor: Vector2) -> void:
	var next := clampi(level + step, 0, ZOOMS.size() - 1)
	if next == level:
		return
	level = next
	_zoom_t = 1.0
	_set_zoom(ZOOMS[level], cursor)

# 커서 아래 월드 지점이 그대로 있게 줌을 z로 둔다(I50)
func _set_zoom(z: float, cursor: Vector2) -> void:
	var off := cursor - get_viewport_rect().size / 2
	position += off / zoom.x - off / z
	zoom = Vector2.ONE * z
	pan(Vector2.ZERO, 0.0)
