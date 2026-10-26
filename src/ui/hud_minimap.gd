extends Control
# 미니맵(S209): 화면 왼쪽 아래 [2,295,62,65]. 맵 한 칸이 1px이고 둘레에 1px 테두리. 바닥은 맵이 구운 바닥 그림을 줄인 것이고,
# 그 위에 성곽·구조물·거점·유닛 점(marks)과 카메라가 보이는 맵 사각형(view_rect)을 그린다.
# 맵이 ROWS줄보다 길면 ROWS줄 창만 보이고 창이 세로로 스크롤된다(S209 2026-10-26 둘째 변경). 카메라가 움직여 그 사각형이 창 밖으로 나가면 창이 따라가고,
# 좌버튼 끌기는 카메라를 두고 창을 스크롤한다. 누른 자리에서 SLOP px 안에서 떼면 그 자리를 화면 가운데로 바로 옮긴다.
# 우클릭은 그 자리를 맵에서 우클릭한 것으로 controls에 넘긴다.
# 보이기와 다시 그리기는 hud._process가 정한다

const HudTheme := preload("res://src/ui/hud_theme.gd")
const RUBBLE := Color("4a4a50")
const WALL := Color("9aa0aa")
const GATE := Color("c08a4a")
const STRUCTURE := Color("8fd8ff")
const BASE := Color("ffd37f")
const ALLY := Color("3ce0d8")
const FOE := Color("ff3b3b")
const HERO := Color.WHITE
const NIGHT := Color("0b1030")  # 밤에 바닥을 덮는 색(S212). 맵 어둠 덮개(battle_view NIGHT_COLOR)와 같다
const NIGHT_ALPHA := 0.6  # 바닥 덮개 불투명도 = 이 값 × 어둠(S212). 점이 묻히지 않게 맵보다 엷다
const ROWS := 63  # 창 세로 칸 수(S209 2026-10-26 둘째 변경): 60×63 맵 때의 미니맵 [2,295,62,65]를 그대로 둔다
const SLOP := 3.0  # 누른 자리에서 이만큼(px) 안에서 떼면 클릭, 넘으면 끌기(S209)

var hud
var battle
var cell_px: int
var ground: ImageTexture  # 줄인 바닥. 맵이 바닥을 처음 그릴 때 굽는 것을 빌려 처음 그릴 때 만든다
var top := 0  # 창 맨 윗줄(맵 칸). 처음에는 맨 아래(적이 오는 들판 쪽)다
var _seen := Rect2()  # 지난번 따라간 카메라 사각형(맵 칸). 카메라가 움직였을 때만 따라간다
var _press = null  # 좌버튼을 누른 미니맵 안 자리. 끌기와 클릭을 가른다
var _press_top := 0

func _init(h) -> void:
	hud = h
	battle = h.battle
	cell_px = h.controls.cell_px

func _ready() -> void:
	position = Vector2(2, 295)
	size = Vector2(battle.size.x, rows()) + Vector2(2, 2)
	top = battle.size.y - rows()
	mouse_filter = Control.MOUSE_FILTER_STOP  # 미니맵을 누른 클릭이 아래 맵으로 가지 않게
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

# 맵 바닥 그림(맵 밖 아래 띠까지 구운 것)의 맵 부분을 칸당 1px로 줄인다
static func shrink(full: Texture2D, cells: Vector2i) -> ImageTexture:
	var img := full.get_image()
	var px := full.get_width() / cells.x
	img = img.get_region(Rect2i(Vector2i.ZERO, cells * px))
	img.resize(cells.x, cells.y, Image.INTERPOLATE_LANCZOS)  # 칸 평균에 가장 가깝다(2026-10-25 81칸 잼: 최대 오차 0.055, BILINEAR·TRILINEAR 0.105)
	return ImageTexture.create_from_image(img)

# 그리는 차례의 [미니맵 안 사각형, 색]: 잔해 → 성곽 칸 → 구조물 → 거점 → 용병 → 적 → 영웅
func marks() -> Array:
	var out := []
	for c in battle.debris:  # 성곽·잔해는 차지 칸마다(S217)
		out.append([_dot(Vector2(c), 1), RUBBLE])
	for c in battle.walls:
		out.append([_dot(Vector2(c), 1), GATE if battle.walls[c].kind == "gate" else WALL])
	for c in battle.footprint:  # 차지 칸마다(S216)
		out.append([_dot(Vector2(c), 1), STRUCTURE])
	out.append([_dot(Vector2(battle.base.cell), 3), BASE])
	for u in battle.units:
		if not u.is_hero:
			out.append([_dot(u.pos, 1), ALLY])
	for e in battle.enemies:
		if battle.seen(e.pos):  # 어둠 속에 숨은 적(S213)은 점을 찍지 않는다
			out.append([_dot(e.pos, 2 if e.kind == "boss" else 1), FOE])
	for h in battle.heroes:
		if h.present:
			out.append([_dot(h.pos, 2), HERO])
	return out

# 칸 좌표 p(칸 가운데가 정수)에 몸 가운데를 둔 n×n 점. 창 위로 top줄 올린다
func _dot(p: Vector2, n: int) -> Rect2:
	return Rect2(Vector2(1, 1 - top) + (p + Vector2(0.5, 0.5) - Vector2.ONE * n / 2.0).round(), Vector2.ONE * n)

func rows() -> int:
	return mini(battle.size.y, ROWS)

# 카메라가 보이는 맵(위 띠 아래 화면)의 맵 칸 사각형
func seen() -> Rect2:
	var r: Rect2 = hud.map.get_canvas_transform().affine_inverse() * hud.VIEW
	return Rect2(r.position / cell_px, r.size / cell_px)

# 카메라 사각형을 미니맵 안 좌표로. 창 밖은 잘라 낸다(창 밖이면 빈 사각형)
func view_rect() -> Rect2:
	var r := seen()
	return Rect2(Vector2(1, 1 - top) + r.position, r.size).intersection(_window())

# 창(미니맵 안 좌표). 바닥·밤 덮개·점은 이 안에만 그린다
func _window() -> Rect2:
	return Rect2(Vector2.ONE, Vector2(battle.size.x, rows()))

# 카메라 사각형이 지난번과 다르고 창 밖으로 나가 있으면, 그 사각형이 들어오게 창을 가장 적게 옮긴다(S209)
func follow() -> void:
	var r := seen()
	if r == _seen:
		return
	_seen = r
	var lo := floori(r.position.y)
	var hi := ceili(r.end.y)
	if lo < top:
		top = lo
	elif hi > top + rows():
		top = hi - rows()
	top = clampi(top, 0, battle.size.y - rows())

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), HudTheme.LINE)
	if ground == null and hud.view.ground != null:
		ground = shrink(hud.view.ground, battle.size)
	follow()
	var win := _window()
	if ground:
		draw_texture_rect_region(ground, win, Rect2(0, top, battle.size.x, rows()))
	if battle.dark > 0.0:  # 밤(S212): 바닥만 덮고 점은 그 위에 찍는다
		draw_rect(win, Color(NIGHT, NIGHT_ALPHA * battle.dark))
	for m in marks():
		var r: Rect2 = m[0].intersection(win)
		if r.has_area():
			draw_rect(r, m[1])
	draw_rect(view_rect(), Color.WHITE, false, 1.0)

func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouse:
		return
	var at: Vector2 = (event.position - Vector2(1, 1 - top)) * cell_px  # 미니맵 안 자리 → 맵 px
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press = event.position
			_press_top = top
		elif _press != null:
			if event.position.distance_to(_press) <= SLOP:
				get_viewport().get_camera_2d().jump((_press - Vector2(1, 1 - top)) * cell_px)
			_press = null
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT and _press != null:
		if event.position.distance_to(_press) > SLOP:  # 끌기: 카메라는 두고 창을 끈 만큼 스크롤한다
			top = clampi(_press_top - roundi(event.position.y - _press.y), 0, battle.size.y - rows())
			queue_redraw()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		var e: InputEventMouseButton = event.duplicate()
		e.position = at
		hud.controls.handle(e)
