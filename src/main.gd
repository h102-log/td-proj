extends Node2D
# 게임 장면. 시험 스테이지 맵에서 6라운드 도전을 띄운다(S63, I91). 메인 메뉴 장면(menu.tscn)의 새 게임·이어하기·테스트 모드로 온다(S182, S290).
# 진행 저장(S181)과 ESC 메뉴(S183)를 맡고, 창 준비·F11 전체화면 함수(S161~S164)도 여기 둔다. 테스트 모드면 수치 조정·테스트 패널·배속을 붙인다(S289~S292)

const Battle := preload("res://src/sim/battle.gd")
const BattleView := preload("res://src/ui/battle_view.gd")
const Camera := preload("res://src/ui/camera.gd")
const Controls := preload("res://src/ui/controls.gd")
const Hud := preload("res://src/ui/hud.gd")
const HudCursor := preload("res://src/ui/hud_cursor.gd")
const Menus := preload("res://src/ui/menus.gd")
const Save := preload("res://src/sim/save.gd")
const Settings := preload("res://src/settings.gd")
const Audio := preload("res://src/audio.gd")
const Sfx := preload("res://src/sfx.gd")
const Tuning := preload("res://src/sim/tuning.gd")
const TestPanel := preload("res://src/ui/test_panel.gd")
const QUIET := ["hiring", "prep", "cleared"]  # 전투 단계·원정(S316)이 아닌 판 단계. 이때만 저장한다(S181)
const PAUSE_NOTES := {  # ESC 메뉴의 «저장되지 않습니다» 안내(S183): 판 단계 → 글
	"battle": "지금 나가면 이번 웨이브 진행은 저장되지 않습니다",
	"raid": "지금 나가면 원정 전 준비 단계로 돌아갑니다(쓴 횃불은 돌아오지 않습니다)",  # I262 ⑤
}
# 도전의 라운드 순서(S63, I91): data/waves/의 웨이브 파일 이름. 1라운드는 시험 스테이지(S111, 슬라임 테마)다
# ponytail: 2~6라운드는 5.1(WBS.md:129)까지 쓰는 임시값이다. 실제 라운드 수와 웨이브는 그때 정한다
const ROUNDS := ["test_stage", "round_2", "round_3", "round_4", "round_5", "round_6"]
const FIELD_ROWS := 66  # 시험 스테이지 들판 줄 수(S203): 성 바로 아래 줄부터. 맵 높이와 출현 줄은 여기서 셈한다(사용자 2026-10-28)
const WALL_T := 5  # 시험 스테이지 성곽 두께(줄, S217 2026-11-03 변경). 성곽·마을·거점·출현·출전 칸은 여기서 셈한다. 성곽 그림(tools/art/wall.py)을 이 두께로 굽으므로 바꾸면 다시 굽는다

static var resume := {}  # 이어하기(S182)로 올 때 메인 메뉴 장면이 넣는 저장. 비어 있으면 새 도전이다
static var live_prep := false  # 판에 옮기는 준비 단계 실시간(I175). 메인 메뉴가 게임을 막 켰을 때와 관찰 하네스가 켠다. 게임 장면을 바로 띄우는 평가는 끈 채 쓴다
static var test := false  # 테스트 모드(S289, I231). 메인 메뉴의 «테스트 모드»가 켜고 «메인 메뉴로»가 끈다. 이 판은 진행 저장을 쓰지도 지우지도 않는다

var view
var controls
var hud
var menus  # ESC 메뉴(S183)
var sfx  # 효과음 연결(S269)
var _seen := ""  # 마지막으로 본 판 단계. 바뀌면 저장하거나 지운다(S181, I157)
var _map_press := false  # 마지막 좌버튼 누름이 맵(controls)에 갔다. 더블클릭의 둘째 누름을 맵에 줄지 본다(S275)
var _cursor := Vector2()  # 마지막 마우스 입력의 화면 자리. HUD 위 입력도 든다. 대시(S315)가 지금 카메라로 맵 자리를 다시 구한다
var tuning  # 테스트 모드의 수치 조정(Tuning, I240). 테스트 모드가 아니면 null
var panel  # 테스트 패널(I232). 테스트 모드가 아니면 null
var speed := 1  # 배속(I236): 한 프레임에 판을 돌리는 횟수. 테스트 패널만 바꾼다

func _ready() -> void:
	view = BattleView.new()
	view.battle = Battle.new(stage())
	if test:
		tuning = Tuning.new(view.battle)  # 데이터 표를 이 판만의 사본으로 바꾼다(I240). HUD가 표를 읽기 전에
	view.battle.live_prep = live_prep  # 저장에 담지 않는다. 이어하기도 이 값이다
	if resume.is_empty():
		view.battle.begin_hiring()  # 도전은 영입 창에서 시작한다(S122)
	else:
		Save.apply(view.battle, resume)
		resume = {}
	view.battle.revive = Settings.revive  # I28, I160
	view.battle.wave_starting.connect(_store)  # 웨이브를 시작하기 직전에도 저장한다(S181)
	view.battle.raid_starting.connect(_store)  # 횃불을 쓴 직후 원정에 들어가기 전에도 저장한다(S316)
	controls = Controls.new(view.battle, BattleView.CELL)
	controls.quickcast = Settings.quickcast  # I158
	view.controls = controls
	add_child(view)  # 맵은 루트 뷰포트에 바로 그려 창 해상도다(S30 2026-10-25 변경). 카메라·HUD 좌표는 그대로 기준 해상도 단위다
	var cam := Camera.new()
	cam.map_px = Vector2(view.battle.size * BattleView.CELL)
	cam.position = Vector2(Vector2i(view.battle.base.cell.x, view.battle.village.end.y) * BattleView.CELL)  # 정문(거점 열의 성곽 칸, S203)
	add_child(cam)
	hud = Hud.new(view.battle, controls, get_viewport())
	hud.view = view
	hud.menu_pressed.connect(pause)  # 위 띠 메뉴 칸(S185)
	add_child(hud)
	menus = Menus.new()
	menus.chosen.connect(_on_menu)
	add_child(menus)
	sfx = Sfx.new(view.battle, controls)
	add_child(sfx)
	if test:
		panel = TestPanel.new(self)  # HUD와 같은 층에서 HUD 뒤에 붙어 HUD 위·ESC 메뉴 아래에 그린다(I232)
		add_child(panel)
	Audio.of(get_tree()).follow(view.battle.state, false, true)  # 이어하기로 라운드 사이에 와도 징글은 없다(S271)
	setup_window(get_window(), false)  # 창 크기·시작 모드는 진입 장면(menu.gd)이 정했다
	get_window().size_changed.connect(_resized)
	_check()

# 맵(전장)을 기준 해상도로 그려 정수배·Nearest로 키우는 SubViewport. 게임은 2026-10-25부터 맵을 루트에 바로 그리고(S30 변경),
# 이것은 4.1a 벤치(tools/bench)가 옛 그리기를 재는 데만 쓴다
static func map_viewport(w: Window) -> SubViewportContainer:
	var box := SubViewportContainer.new()
	box.size = Vector2(w.content_scale_size)
	box.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	box.mouse_filter = Control.MOUSE_FILTER_PASS  # STOP이면 클릭이 main._unhandled_input에 가지 않고, IGNORE면 휠·가운데 버튼이 카메라에 가지 않는다
	box.focus_mode = Control.FOCUS_NONE  # 기본값 FOCUS_CLICK이면 맵을 클릭할 때 키보드 포커스를 가져가, 포커스가 없을 때만 받는 Enter·Space(I94)가 막힌다
	var sv := SubViewport.new()
	sv.size = w.content_scale_size  # stretch로 맞추면 트리 밖(평가)에서는 기본값 512×512 그대로였다
	sv.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	box.add_child(sv)
	return box

func _process(delta: float) -> void:
	var heard := []
	for i in speed:  # 배속(I236): 같은 delta로 speed번 돌리고, 그 사이에 생긴 사건을 모두 연출·효과음에 넘긴다
		view.battle.step(delta)
		view.tick(delta)  # 화면 시계와 사건 목록(I170, I171). step과 같은 delta라 ESC 메뉴면 같이 멈춘다
		heard += view.events
	view.events = heard
	var cam := get_viewport().get_camera_2d()
	cam.rumble(view.events, delta)  # 화면 흔들림(S200): 방금 낸 사건 목록을 읽는다
	sfx.hear(view.events, cam.steady().affine_inverse() * Hud.VIEW)  # 효과음(S269, S270): 위 띠 아래 보이는 맵 영역
	var b = view.battle
	Audio.of(get_tree()).follow(b.state, b.enemies.any(func(e): return e.alive and e.boss))  # 음악(S271)
	view.queue_redraw()
	_check()
	var at: Vector2 = get_viewport().get_camera_2d().steady().affine_inverse() * get_viewport().get_mouse_position()  # 지금 마우스 자리 → 맵 px(handle에 넘기는 것과 같은 변환)
	HudCursor.apply(HudCursor.kind(controls, at, get_viewport().gui_get_hovered_control() != null), cursor_scale(get_window()))  # 커서 모양(S278, I211). 가장자리 스크롤 중에도 맞게 매 프레임 정한다

# 판 단계가 바뀌면 전투 단계가 아닌 단계는 저장하고(S181), 도전이 끝났으면 저장을 지운다(S65, I157). 테스트 모드는 둘 다 하지 않는다(I231).
# 원정에 들어가면 카메라를 보스방에 묶고, 돌아오면 푼다(S317)
func _check() -> void:
	var s: String = view.battle.state
	if s == _seen:
		return
	var was := _seen
	_seen = s
	var cam: Camera2D = get_viewport().get_camera_2d()
	if s == "raid":  # 원정(S317): 카메라를 보스방에 묶고, 고른 것은 원정대만 남기고 놓기 모드를 끝낸다(I262 ④)
		var room: Rect2i = view.battle.den.room
		cam.hold((Vector2(room.position) + Vector2(room.size) / 2.0) * BattleView.CELL)
		controls.selected = controls.selected.filter(func(u): return u in view.battle.party)
		controls.facility = null
		controls.village = false
		controls.placing = ""
		controls.moving = null
	elif was == "raid":
		cam.release()
	if s in QUIET:
		_store()
	elif s in ["won", "lost"] and not test:
		Save.erase()

# 진행 저장(S181). 테스트 모드 판은 저장 파일을 쓰지 않는다(I231)
func _store() -> void:
	if not test:
		Save.write(view.battle)

# 게임을 멈추고 ESC 메뉴를 연다(S183, I11). 전투 단계·원정(S316)이면 나가도 저장되지 않는다고 알린다
func pause() -> void:
	menus.open("pause", PAUSE_NOTES.get(view.battle.state, ""))
	hud.cover()
	get_tree().paused = true
	_map_press = false  # 메뉴 버튼 누름은 멈춘 동안이라 _input이 보지 못한다
	HudCursor.apply("arrow", cursor_scale(get_window()))  # ESC 메뉴 위는 기본 화살표(S278). 멈춘 동안 _process가 커서를 정하지 않는다

# 멈춘 동안 창 배율이 바뀌면(ESC 메뉴 설정의 전체화면·창 크기 끌기) 커서를 그 배율로 다시 건다(I211). 멈추지 않았으면 _process가 건다
func _resized() -> void:
	if get_tree().paused:
		HudCursor.apply("arrow", cursor_scale(get_window()))

func _on_menu(what: String) -> void:
	match what:
		"continue":
			menus.close()
			get_tree().paused = false
		"settings":  # 바꾼 설정은 진행 중인 판에 바로 건다(I160)
			view.battle.revive = Settings.revive
			controls.quickcast = Settings.quickcast
			apply_window(get_window())
		"title", "quit":
			leave(what == "title")

# 메인 메뉴로·게임 종료(I161): 전투 단계가 아니면 그때 상태를 저장하고 나간다. 나가면 테스트 모드가 끝난다(I231)
func leave(to_title: bool) -> void:
	if view.battle.state in QUIET:
		_store()
	test = false
	get_tree().paused = false
	if to_title:
		get_tree().change_scene_to_file("res://src/menu.tscn")
	else:
		get_tree().quit()

# 창 닫기(× 단추)도 «게임 종료»와 같이 저장한다(I161)
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and view and view.battle.state in QUIET:
		_store()

# 더블클릭의 둘째 좌누름은 첫 누름이 맵에 갔으면 HUD보다 먼저 맵에 준다. 첫 클릭으로 새로 뜬 선택 패널·태그가 그 자리를 덮어도
# 용병 더블클릭(S275)이 되게 한다. 뗌은 누름을 받은 HUD가 없으니 그대로 _unhandled_input으로 온다
func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		_cursor = event.position
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var to_map: bool = event.double_click and _map_press
		_map_press = false
		if to_map:
			get_viewport().set_input_as_handled()
			_unhandled_input(event)

# 결과 창·영입 창이 떠 있으면 Enter·Space(기본 ui_accept)로 그 버튼을 누른다(I94). 전투 시작은 HUD 버튼을 마우스로 누를 때만이다(I13 2026-11-10 변경)
# 창의 버튼에 키보드 포커스가 있으면 그 버튼이 누른다(I110). 버튼은 ui_accept를 소비하지 않아 여기서 거르지 않으면 둘 다 눌린다
# Space는 그다음 controls로 가 전투 단계의 대시(S315)가 된다. 마우스 없이 카메라만 움직였을 수 있어 커서의 맵 자리를 지금 카메라로 다시 구한다(I261 ③)
# ESC는 조준·놓기·대포 옮기기 중이거나 맵 팝업이 떠 있으면 Controls가 그것을 취소하거나 닫고, 아니면 ESC 메뉴를 연다(S183)
# 준비·전투 단계의 T는 언제든 영입 창을 열고 닫고, 창이 떠 있으면 ESC는 ESC 메뉴 대신 창을 닫는다(S272)
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:  # S162, I154
		switch_fullscreen(get_window())
		get_viewport().set_input_as_handled()
		return
	var shop_key: bool = event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_T or (event.keycode == KEY_ESCAPE and controls.shop))
	if shop_key and view.battle.state in ["prep", "battle"]:
		controls.set_shop(not controls.shop)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE \
			and controls.placing == "" and controls.moving == null and controls.aiming == "" and not controls.attacking and not controls.popup_open():  # 그것만 취소하거나 닫는 ESC는 controls가 받는다(S183, S35)
		pause()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_accept") and get_viewport().gui_get_focus_owner() == null:
		if view.battle.state in ["hiring", "cleared", "won", "lost"] or controls.shop:
			hud.proceed()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_map_press = true
	var to_map: Transform2D = get_viewport().get_camera_2d().steady().affine_inverse()  # 화면 좌표 → 맵 px(카메라 줌·이동 반영, 흔들림은 뺌 S200)
	if event is InputEventKey and event.keycode == KEY_SPACE:
		controls.mouse = to_map * _cursor
	controls.view = hud.minimap.seen()  # 용병 더블클릭이 고르는 화면 안(S275)
	controls.handle(event.xformed_by(to_map))

# 창 준비: 최소 크기는 늘 기준 해상도의 2배(S164). 창 크기·시작 모드는 게임을 막 켰을 때(진입 장면 menu.gd)만 정한다(S161, S163, I153)
# 시작 모드는 설정에 고른 창 모드, 고른 적이 없으면 내보낸 빌드만 전체화면이다(S163, S184)
static func setup_window(w: Window, entry: bool) -> void:
	w.min_size = w.content_scale_size * 2
	if entry:
		if Settings.fullscreen_at_start(OS.has_feature("template")):
			w.mode = Window.MODE_FULLSCREEN
		else:
			fit_window(w)
	apply_cursor(w)

# 지금 화면의 작업 영역에 테두리까지 들어가는 가장 큰 정수배 크기로 키워 가운데에 둔다(S161, I153)
static func fit_window(w: Window) -> void:
	var usable := DisplayServer.screen_get_usable_rect(w.current_screen)
	w.size = w.content_scale_size * window_scale(usable.size, w.get_size_with_decorations() - w.size, w.content_scale_size)
	w.position = usable.position + (usable.size - w.size) / 2

# 작업 영역 usable에 테두리 deco까지 들어가는 가장 큰 base 정수배. 들어가는 배수가 없으면 1(S161)
static func window_scale(usable: Vector2i, deco: Vector2i, base: Vector2i) -> int:
	var k := (usable - deco) / base
	return maxi(1, mini(k.x, k.y))

# 커서 그림 배율(I211): 창 크기를 기준 해상도로 나눈 정수 몫, 최소 1. 루트 stretch의 정수배와 같다
static func cursor_scale(w: Window) -> int:
	return window_scale(w.size, Vector2i.ZERO, w.content_scale_size)

# 전체화면이면 창 모드로 돌아가며 그때의 화면에 맞춰 크기를 다시 정하고, 아니면 전체화면으로 간다(S162, I154)
static func toggle_fullscreen(w: Window) -> void:
	if w.mode == Window.MODE_FULLSCREEN:
		w.mode = Window.MODE_WINDOWED
		fit_window(w)
	else:
		w.mode = Window.MODE_FULLSCREEN
	apply_cursor(w)

# F11(S162): 창 모드를 바꾸고 설정에 남긴다(I160)
static func switch_fullscreen(w: Window) -> void:
	toggle_fullscreen(w)
	Settings.fullscreen = w.mode == Window.MODE_FULLSCREEN
	Settings.save_file()

# 설정에서 고른 창 모드(S184)가 지금 창과 다르면 바꾼다
static func apply_window(w: Window) -> void:
	if Settings.fullscreen != null and Settings.fullscreen != (w.mode == Window.MODE_FULLSCREEN):
		toggle_fullscreen(w)
	apply_cursor(w)  # 커서 가두기 설정을 바꿨을 수도 있다

# 커서 가두기(I194): 전체화면이거나 설정 «커서 가두기»가 켜져 있으면 창 안에 가둔다
static func cursor_mode(full: bool) -> int:
	return Input.MOUSE_MODE_CONFINED if full or Settings.confine else Input.MOUSE_MODE_VISIBLE

static func apply_cursor(w: Window) -> void:
	Input.mouse_mode = cursor_mode(w.mode == Window.MODE_FULLSCREEN)

# W1 시험 스테이지(60 × (60 + FIELD_ROWS), S203·S51 위아래 구도). 위쪽 60×60은 두께 3줄 사방 성곽(S217)이 두른 성이고, 적은 아래쪽 가장자리에서 온다.
# 도전 내내 이 맵이고, 라운드마다 웨이브만 바뀐다(S78, I91)
static func stage() -> Dictionary:
	var rounds := ROUNDS.map(func(r): return load("res://data/waves/%s.tres" % r).to_stage())  # S31, I66
	# 사방 성곽(S203·S217 2026-11-03 변경). 성곽의 칸은 차지 칸 가운데 가장 왼쪽·가장 아래 칸이고, 문루는 남·북 3×t·동·서 t×3이다
	var t := WALL_T
	var n := 54 + 2 * t  # 성 한 변(칸): 마을 54칸(S203, 사용자 2026-11-03 «마을크기는 그대로») + 양쪽 성곽
	var mid := n / 2  # 거점 열·행. 문루는 이 줄을 가운데로 폭 3칸이다
	var sealed := [Vector2i(mid - 1, t - 1), Vector2i(0, mid + 1), Vector2i(n - t, mid + 1)]  # 북·서·동 닫힌 문루(S39)
	var gates := [Vector2i(mid - 1, n - 1)] + sealed  # 정문을 맨 앞에 둔다(S143 거리가 같으면 앞선 문)
	var walls := []  # 남·북 성벽은 열마다 하나(남 n−t~n−1행, 북 0~t−1행). 네 모서리 t×t도 여기다
	for x in n:
		if x < mid - 1 or x > mid + 1:
			walls.append(Vector2i(x, n - 1))
			walls.append(Vector2i(x, t - 1))
	var side := []  # 동·서 성벽은 마을 행(t~n−t−1)에서 행마다 하나(서 0~t−1열, 동 n−t~n−1열)
	for y in range(t, n - t):
		if y < mid - 1 or y > mid + 1:
			side.append(Vector2i(0, y))
			side.append(Vector2i(n - t, y))
	return {
		"size": Vector2i(n, n + FIELD_ROWS), "base": Vector2i(mid, mid), "base_hp": 100, "gold": 1000,  # 거점은 마을 한가운데(S37, S203). 시작 골드(S111)
		"spawns": [Vector2i(mid - 21, n - 1 + FIELD_ROWS), Vector2i(mid, n - 1 + FIELD_ROWS), Vector2i(mid + 20, n - 1 + FIELD_ROWS)],  # 맨 아래 줄. x는 거점 열에서 잰 자리(S203)
		"spawn_spread": 10, "spawn_gap": 0.25, "reward_scale": 0.1,  # 맨 아래 줄 전체에서 흩어져 나온다(I177). 적 10배라 간격 0.25초(I91), 처치 보상 0.1배(I176)
		# 출전 칸(I107): 정문 문루 바로 앞 들판(한 줄 띄움)의 세 칸. 성문은 닫힌 채 시작해서(I67) 마을 안에 두면 나올 수 없다(I42, 사용자 2026-10-12)
		"hero_cells": [Vector2i(mid - 1, n + 1), Vector2i(mid + 1, n + 1), Vector2i(mid, n + 1)],
		"engineer_cells": [Vector2i(mid, mid + 1), Vector2i(mid - 2, n + 1)],  # 시작 공병(S208): 거점 아래 마을 칸, 출전 칸 옆 들판 칸. 성문이 닫혀 있어도 마을·들판에 하나씩 짓는다(사용자 2026-10-25)
		# ponytail: 체력은 임시값이다. 성문이 성벽보다 약해야 한다는 것(I41)만 지킨다. 수치는 3.1 밸런스에서 정한다
		"castle": {"walls": walls, "gates": gates, "wall_hp": 300, "gate_hp": 150, "wall_size": Vector2i(1, t), "gate_size": Vector2i(3, t), "side_walls": side, "side_wall_size": Vector2i(t, 1),
			"side_gates": sealed.slice(1), "side_gate_size": Vector2i(t, 3), "sealed": sealed},
		"village": Rect2i(t, t, 54, 54),  # 사방 성곽 안쪽. 생산 시설은 여기에만 짓는다(S43)
		"roads": BattleView.roads(),  # 마을 길 칸(광장·큰길·문루 안 공터): 짓지 못한다(S43 2026-10-26 둘째 변경). 표는 바닥 그림과 같은 BattleView._plan
		"water": BattleView.water(),  # 수로·연못 물 칸(S220): 짓지 못하고 아무도 들어가지 않는다. 표는 바닥 그림과 같은 BattleView._plan
		"garden": BattleView.garden(),  # 텃밭 칸(I182 ⑥): 농부·이삭 줍기·약초꾼·짐꾼의 일터. 표는 바닥 그림과 같은 BattleView._plan
		"yards": BattleView.yards(),  # 자갈 마당 칸(I182 ⑥): 석공·목수의 일터
		"rounds": rounds,
		"hp_mult": ROUNDS.map(func(r): return load("res://data/waves/%s.tres" % r).hp_mult),  # 라운드 적 체력 배율(S144)
		"nights": ROUNDS.map(func(r): return load("res://data/waves/%s.tres" % r).nights),  # 웨이브마다 밤(S210)
		"quests": true,  # 미션(S77, I118): data/quests의 모든 미션이 뜬다
		"waves": rounds[0],  # 1라운드. 라운드 하나뿐인 스테이지의 키라 시험 스테이지 평가(EV144)가 읽는다
		# 보스방 원정(S316·S317, I262): 맵 오른쪽에 붙는 숨은 띠 폭(strip), 보스방 사각형(room)과 모서리 막는 거리(cut), 입구 칸(출전 차례)·보스 칸,
		# 계단 칸·벽 횃불 칸(꺼지는 차례), 라운드마다 더하는 횃불(torches)·쌓임 상한(torch_cap), 층 차례(data/dungeon 파일 이름),
		# 끝나고 돌아오기까지 초(처치 win_wait, 전멸·불꽃 wipe_wait). 수치는 임시값(05 §2.2·§2.3)
		"den": {"strip": 40, "room": Rect2i(70, 72, 28, 16), "cut": 2, "entry": [Vector2i(83, 87), Vector2i(85, 87), Vector2i(84, 87)], "boss": Vector2i(84, 80),
			"stairs": Rect2i(83, 88, 3, 2), "lamps": [Vector2i(69, 80), Vector2i(77, 71), Vector2i(90, 71), Vector2i(98, 80)],
			"torches": 2, "torch_cap": 4, "floors": ["floor_1", "floor_2"], "win_wait": 3.0, "wipe_wait": 2.5},
	}
