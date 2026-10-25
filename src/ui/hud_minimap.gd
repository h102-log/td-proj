extends Control
# 미니맵(S209): 화면 왼쪽 아래 [2,295,62,63]. 맵 한 칸이 1px이고 둘레에 1px 테두리. 바닥은 맵이 구운 바닥 그림을 줄인 것이고,
# 그 위에 성곽·구조물·거점·유닛 점(marks)과 카메라가 보이는 맵 사각형(view_rect)을 그린다.
# 좌클릭·좌버튼 끌기는 그 자리를 화면 가운데로 바로 옮기고, 우클릭은 그 자리를 맵에서 우클릭한 것으로 controls에 넘긴다.
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

var hud
var battle
var cell_px: int
var ground: ImageTexture  # 줄인 바닥. 맵이 바닥을 처음 그릴 때 굽는 것을 빌려 처음 그릴 때 만든다

func _init(h) -> void:
	hud = h
	battle = h.battle
	cell_px = h.controls.cell_px

func _ready() -> void:
	position = Vector2(2, 295)
	size = Vector2(battle.size) + Vector2(2, 2)
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
	for c in battle.rubble:
		out.append([_dot(Vector2(c), 1), RUBBLE])
	for c in battle.castle:
		out.append([_dot(Vector2(c), 1), GATE if battle.castle[c].kind == "gate" else WALL])
	for c in battle.structures:
		out.append([_dot(Vector2(c), 1), STRUCTURE])
	out.append([_dot(Vector2(battle.base.cell), 3), BASE])
	for u in battle.units:
		if not u.is_hero:
			out.append([_dot(u.pos, 1), ALLY])
	for e in battle.enemies:
		out.append([_dot(e.pos, 2 if e.kind == "boss" else 1), FOE])
	for h in battle.heroes:
		if h.present:
			out.append([_dot(h.pos, 2), HERO])
	return out

# 칸 좌표 p(칸 가운데가 정수)에 몸 가운데를 둔 n×n 점
func _dot(p: Vector2, n: int) -> Rect2:
	return Rect2(Vector2.ONE + (p + Vector2(0.5, 0.5) - Vector2.ONE * n / 2.0).round(), Vector2.ONE * n)

# 카메라가 보이는 맵(위 띠 아래 화면)을 미니맵 안 좌표로. 맵 밖은 잘라 낸다
func view_rect() -> Rect2:
	var seen: Rect2 = hud.map.get_canvas_transform().affine_inverse() * hud.VIEW
	return Rect2(Vector2.ONE + seen.position / cell_px, seen.size / cell_px).intersection(Rect2(Vector2.ONE, Vector2(battle.size)))

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), HudTheme.LINE)
	if ground == null and hud.view.ground != null:
		ground = shrink(hud.view.ground, battle.size)
	if ground:
		draw_texture(ground, Vector2.ONE)
	for m in marks():
		draw_rect(m[0], m[1])
	draw_rect(view_rect(), Color.WHITE, false, 1.0)

func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouse:
		return
	var at: Vector2 = (event.position - Vector2.ONE) * cell_px  # 미니맵 안 자리 → 맵 px
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
			or (event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		get_viewport().get_camera_2d().jump(at)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		var e: InputEventMouseButton = event.duplicate()
		e.position = at
		hud.controls.handle(e)
