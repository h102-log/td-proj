extends Node2D
# 게임 장면. 시험 스테이지 맵에서 6라운드 도전을 띄운다(S63, I91). 메인 메뉴 장면(menu.tscn)의 새 게임·이어하기로 온다(S182).
# 진행 저장(S181)과 ESC 메뉴(S183)를 맡고, 창 준비·F11 전체화면 함수(S161~S164)도 여기 둔다

const Battle := preload("res://src/sim/battle.gd")
const BattleView := preload("res://src/ui/battle_view.gd")
const Camera := preload("res://src/ui/camera.gd")
const Controls := preload("res://src/ui/controls.gd")
const Hud := preload("res://src/ui/hud.gd")
const Menus := preload("res://src/ui/menus.gd")
const Save := preload("res://src/sim/save.gd")
const Settings := preload("res://src/settings.gd")
const QUIET := ["hiring", "prep", "cleared"]  # 전투 단계가 아닌 판 단계. 이때만 저장한다(S181)
# 도전의 라운드 순서(S63, I91): data/waves/의 웨이브 파일 이름. 1라운드는 시험 스테이지(S111)다
# ponytail: 2~6라운드는 5.1(WBS.md:129)까지 쓰는 임시값이다. 실제 라운드 수와 웨이브는 그때 정한다
const ROUNDS := ["test_stage", "round_2", "round_3", "round_4", "round_5", "round_6"]

static var resume := {}  # 이어하기(S182)로 올 때 메인 메뉴 장면이 넣는 저장. 비어 있으면 새 도전이다
static var live_prep := false  # 판에 옮기는 준비 단계 실시간(I175). 메인 메뉴가 게임을 막 켰을 때와 관찰 하네스가 켠다. 게임 장면을 바로 띄우는 평가는 끈 채 쓴다

var view
var controls
var hud
var menus  # ESC 메뉴(S183)
var _seen := ""  # 마지막으로 본 판 단계. 바뀌면 저장하거나 지운다(S181, I157)

func _ready() -> void:
	view = BattleView.new()
	view.battle = Battle.new(stage())
	view.battle.live_prep = live_prep  # 저장에 담지 않는다. 이어하기도 이 값이다
	if resume.is_empty():
		view.battle.begin_hiring()  # 도전은 영입 창에서 시작한다(S122)
	else:
		Save.apply(view.battle, resume)
		resume = {}
	view.battle.revive = Settings.revive  # I28, I160
	view.battle.wave_starting.connect(func(): Save.write(view.battle))  # 웨이브를 시작하기 직전에도 저장한다(S181)
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
	setup_window(get_window(), false)  # 창 크기·시작 모드는 진입 장면(menu.gd)이 정했다
	_check()

# 맵(전장)을 기준 해상도로 그려 정수배·Nearest로 키우는 SubViewport. 게임은 2026-10-25부터 맵을 루트에 바로 그리고(S30 변경),
# 이것은 4.1a 벤치(tools/bench)가 옛 그리기를 재는 데만 쓴다
static func map_viewport(w: Window) -> SubViewportContainer:
	var box := SubViewportContainer.new()
	box.size = Vector2(w.content_scale_size)
	box.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	box.mouse_filter = Control.MOUSE_FILTER_PASS  # STOP이면 클릭이 main._unhandled_input에 가지 않고, IGNORE면 휠·가운데 버튼이 카메라에 가지 않는다
	box.focus_mode = Control.FOCUS_NONE  # 기본값 FOCUS_CLICK이면 맵을 클릭할 때 키보드 포커스를 가져가 Enter·Space가 전투를 시작하지 못한다
	var sv := SubViewport.new()
	sv.size = w.content_scale_size  # stretch로 맞추면 트리 밖(평가)에서는 기본값 512×512 그대로였다
	sv.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	box.add_child(sv)
	return box

func _process(delta: float) -> void:
	view.battle.step(delta)
	view.tick(delta)  # 화면 시계와 사건 목록(I170, I171). step과 같은 delta라 ESC 메뉴면 같이 멈춘다
	view.queue_redraw()
	_check()

# 판 단계가 바뀌면 전투 단계가 아닌 단계는 저장하고(S181), 도전이 끝났으면 저장을 지운다(S65, I157)
func _check() -> void:
	var s: String = view.battle.state
	if s == _seen:
		return
	_seen = s
	if s in QUIET:
		Save.write(view.battle)
	elif s in ["won", "lost"]:
		Save.erase()

# 게임을 멈추고 ESC 메뉴를 연다(S183, I11). 전투 단계면 나가도 이번 웨이브가 저장되지 않는다고 알린다
func pause() -> void:
	menus.open("pause", view.battle.state == "battle")
	hud.cover()
	get_tree().paused = true

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

# 메인 메뉴로·게임 종료(I161): 전투 단계가 아니면 그때 상태를 저장하고 나간다
func leave(to_title: bool) -> void:
	if view.battle.state in QUIET:
		Save.write(view.battle)
	get_tree().paused = false
	if to_title:
		get_tree().change_scene_to_file("res://src/menu.tscn")
	else:
		get_tree().quit()

# 창 닫기(× 단추)도 «게임 종료»와 같이 저장한다(I161)
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and view and view.battle.state in QUIET:
		Save.write(view.battle)

# 전투 시작은 HUD 버튼 말고 Enter·Space(기본 ui_accept)로도 된다. 결과 창·영입 창이 떠 있으면 그 버튼을 누른다(I94)
# 창의 버튼에 키보드 포커스가 있으면 그 버튼이 누른다(I110). 버튼은 ui_accept를 소비하지 않아 여기서 거르지 않으면 둘 다 눌린다
# ESC는 조준·놓기·대포 옮기기 중이거나 맵 팝업이 떠 있으면 Controls가 그것을 취소하거나 닫고, 아니면 ESC 메뉴를 연다(S183)
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:  # S162, I154
		switch_fullscreen(get_window())
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE \
			and controls.placing == "" and controls.moving == null and controls.aiming == "" and not controls.attacking and not controls.popup_open():  # 그것만 취소하거나 닫는 ESC는 controls가 받는다(S183, S35)
		pause()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_accept") and get_viewport().gui_get_focus_owner() == null:
		if view.battle.state in ["hiring", "cleared", "won", "lost"]:
			hud.proceed()
		else:
			view.battle.start_battle()
	controls.handle(view.make_input_local(event))  # 화면 좌표 → 맵 px(카메라 줌·이동 반영)

# 창 준비: 최소 크기는 늘 기준 해상도의 2배(S164). 창 크기·시작 모드는 게임을 막 켰을 때(진입 장면 menu.gd)만 정한다(S161, S163, I153)
# 시작 모드는 설정에 고른 창 모드, 고른 적이 없으면 내보낸 빌드만 전체화면이다(S163, S184)
static func setup_window(w: Window, entry: bool) -> void:
	w.min_size = w.content_scale_size * 2
	if not entry:
		return
	if Settings.fullscreen_at_start(OS.has_feature("template")):
		w.mode = Window.MODE_FULLSCREEN
	else:
		fit_window(w)

# 지금 화면의 작업 영역에 테두리까지 들어가는 가장 큰 정수배 크기로 키워 가운데에 둔다(S161, I153)
static func fit_window(w: Window) -> void:
	var usable := DisplayServer.screen_get_usable_rect(w.current_screen)
	w.size = w.content_scale_size * window_scale(usable.size, w.get_size_with_decorations() - w.size, w.content_scale_size)
	w.position = usable.position + (usable.size - w.size) / 2

# 작업 영역 usable에 테두리 deco까지 들어가는 가장 큰 base 정수배. 들어가는 배수가 없으면 1(S161)
static func window_scale(usable: Vector2i, deco: Vector2i, base: Vector2i) -> int:
	var k := (usable - deco) / base
	return maxi(1, mini(k.x, k.y))

# 전체화면이면 창 모드로 돌아가며 그때의 화면에 맞춰 크기를 다시 정하고, 아니면 전체화면으로 간다(S162, I154)
static func toggle_fullscreen(w: Window) -> void:
	if w.mode == Window.MODE_FULLSCREEN:
		w.mode = Window.MODE_WINDOWED
		fit_window(w)
	else:
		w.mode = Window.MODE_FULLSCREEN

# F11(S162): 창 모드를 바꾸고 설정에 남긴다(I160)
static func switch_fullscreen(w: Window) -> void:
	toggle_fullscreen(w)
	Settings.fullscreen = w.mode == Window.MODE_FULLSCREEN
	Settings.save_file()

# 설정에서 고른 창 모드(S184)가 지금 창과 다르면 바꾼다
static func apply_window(w: Window) -> void:
	if Settings.fullscreen != null and Settings.fullscreen != (w.mode == Window.MODE_FULLSCREEN):
		toggle_fullscreen(w)

# W1 시험 스테이지(60×93, S203·S51 위아래 구도). 위쪽 60×60은 두께 3줄 사방 성곽(S217)이 두른 성이고, 적은 아래쪽 가장자리에서 온다.
# 도전 내내 이 맵이고, 라운드마다 웨이브만 바뀐다(S78, I91)
static func stage() -> Dictionary:
	var rounds := ROUNDS.map(func(r): return load("res://data/waves/%s.tres" % r).to_stage())  # S31, I66
	# 사방 성곽(S203·S217 2026-10-26 둘째 변경). 성곽의 칸은 차지 칸 가운데 가장 왼쪽·가장 아래 칸이고 문루는 3×3이다
	var sealed := [Vector2i(29, 2), Vector2i(0, 31), Vector2i(57, 31)]  # 북·서·동 닫힌 문루(S39)
	var gates := [Vector2i(29, 59)] + sealed  # 정문을 맨 앞에 둔다(S143 거리가 같으면 앞선 문)
	var walls := []  # 남·북 성벽은 열마다 하나(남 57~59행, 북 0~2행). 네 모서리 3×3도 여기다
	for x in 60:
		if x < 29 or x > 31:
			walls.append(Vector2i(x, 59))
			walls.append(Vector2i(x, 2))
	var side := []  # 동·서 성벽은 3~56행에서 행마다 하나(서 0~2열, 동 57~59열)
	for y in range(3, 57):
		if y < 29 or y > 31:
			side.append(Vector2i(0, y))
			side.append(Vector2i(57, y))
	return {
		"size": Vector2i(60, 93), "base": Vector2i(30, 30), "base_hp": 100, "gold": 220,  # 거점은 마을 한가운데(S37, S203). 시작 골드(S111)
		"spawns": [Vector2i(9, 92), Vector2i(30, 92), Vector2i(50, 92)],
		"spawn_spread": 10, "spawn_gap": 0.25, "reward_scale": 0.1,  # 맨 아래 줄 전체에서 흩어져 나온다(I177). 적 10배라 간격 0.25초(I91), 처치 보상 0.1배(I176)
		# 출전 칸(I107): 정문 문루(29~31열, 57~59행) 바로 앞 들판의 세 칸. 성문은 닫힌 채 시작해서(I67) 마을 안에 두면 나올 수 없다(I42, 사용자 2026-10-12)
		"hero_cells": [Vector2i(29, 61), Vector2i(31, 61), Vector2i(30, 61)],
		"engineer_cells": [Vector2i(30, 31), Vector2i(28, 61)],  # 시작 공병(S208): 거점 아래 마을 칸, 출전 칸 옆 들판 칸. 성문이 닫혀 있어도 마을·들판에 하나씩 짓는다(사용자 2026-10-25)
		# ponytail: 체력은 임시값이다. 성문이 성벽보다 약해야 한다는 것(I41)만 지킨다. 수치는 3.1 밸런스에서 정한다
		"castle": {"walls": walls, "gates": gates, "wall_hp": 300, "gate_hp": 150, "wall_size": Vector2i(1, 3), "gate_size": Vector2i(3, 3), "side_walls": side, "side_wall_size": Vector2i(3, 1), "sealed": sealed},
		"village": Rect2i(3, 3, 54, 54),  # 사방 성곽 안쪽(3~56행·열). 생산 시설은 여기에만 짓는다(S43)
		"roads": BattleView.roads(),  # 마을 길 칸(광장·큰길·문루 안 공터): 짓지 못한다(S43 2026-10-26 둘째 변경). 표는 바닥 그림과 같은 BattleView._plan
		"rounds": rounds,
		"hp_mult": ROUNDS.map(func(r): return load("res://data/waves/%s.tres" % r).hp_mult),  # 라운드 적 체력 배율(S144)
		"nights": ROUNDS.map(func(r): return load("res://data/waves/%s.tres" % r).nights),  # 웨이브마다 밤(S210)
		"quests": true,  # 미션·의뢰(S77, I118): data/quests의 모든 미션·의뢰가 뜬다
		"waves": rounds[0],  # 1라운드. 라운드 하나뿐인 스테이지의 키라 시험 스테이지 평가(EV144)가 읽는다
	}
