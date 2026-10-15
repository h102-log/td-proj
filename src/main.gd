extends Node2D
# 진입 씬. 시험 스테이지 맵에서 6라운드 도전을 띄운다(S63, I91).

const Battle := preload("res://src/sim/battle.gd")
const BattleView := preload("res://src/ui/battle_view.gd")
const Camera := preload("res://src/ui/camera.gd")
const Controls := preload("res://src/ui/controls.gd")
const Hud := preload("res://src/ui/hud.gd")
# 도전의 라운드 순서(S63, I91): data/waves/의 웨이브 파일 이름. 1라운드는 시험 스테이지(S111)다
# ponytail: 2~6라운드는 5.1(WBS.md:129)까지 쓰는 임시값이다. 실제 라운드 수와 웨이브는 그때 정한다
const ROUNDS := ["test_stage", "round_2", "round_3", "round_4", "round_5", "round_6"]

var view
var controls
var hud

func _ready() -> void:
	view = BattleView.new()
	view.battle = Battle.new(stage())
	view.battle.begin_hiring()  # 도전은 영입 창에서 시작한다(S122)
	controls = Controls.new(view.battle, BattleView.CELL)
	view.controls = controls
	add_child(view)
	var cam := Camera.new()
	cam.map_px = Vector2(view.battle.size * BattleView.CELL)
	cam.position = Vector2(view.battle.base.cell * BattleView.CELL)
	add_child(cam)
	hud = Hud.new(view.battle, controls)
	add_child(hud)

func _process(delta: float) -> void:
	view.battle.step(delta)
	view.queue_redraw()

# 전투 시작은 HUD 버튼 말고 Enter·Space(기본 ui_accept)로도 된다. 결과 창·영입 창이 떠 있으면 그 버튼을 누른다(I94)
# 창의 버튼에 키보드 포커스가 있으면 그 버튼이 누른다(I110). 버튼은 ui_accept를 소비하지 않아 여기서 거르지 않으면 둘 다 눌린다
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and get_viewport().gui_get_focus_owner() == null:
		if view.battle.state in ["hiring", "cleared", "won", "lost"]:
			hud.proceed()
		else:
			view.battle.start_battle()
	controls.handle(view.make_input_local(event))  # 화면 좌표 → 맵 px(카메라 줌·이동 반영)

# W1 시험 스테이지(40×32, S51 위아래 구도). 위쪽 마을을 가로 성곽이 막고, 적은 아래쪽 가장자리에서 온다.
# 도전 내내 이 맵이고, 라운드마다 웨이브만 바뀐다(S78, I91)
static func stage() -> Dictionary:
	var rounds := ROUNDS.map(func(r): return load("res://data/waves/%s.tres" % r).to_stage())  # S31, I66
	var gates := [Vector2i(0, 9), Vector2i(20, 9), Vector2i(39, 9)]  # 쪽문, 정문, 쪽문
	var walls := []
	for x in 40:
		if Vector2i(x, 9) not in gates:
			walls.append(Vector2i(x, 9))
	return {
		"size": Vector2i(40, 32), "base": Vector2i(20, 4), "base_hp": 100, "gold": 150,  # 시작 골드(S111)
		"spawns": [Vector2i(6, 31), Vector2i(20, 31), Vector2i(33, 31)],
		# 출전 칸(I107): 정문(20,9) 바로 앞 들판의 두 칸. 성문은 닫힌 채 시작해서(I67) 마을 안에 두면 나올 수 없다(I42, 사용자 2026-10-12)
		"hero_cells": [Vector2i(19, 11), Vector2i(21, 11)],
		# ponytail: 체력은 임시값이다. 성문이 성벽보다 약해야 한다는 것(I41)만 지킨다. 수치는 3.1 밸런스에서 정한다
		"castle": {"walls": walls, "gates": gates, "wall_hp": 300, "gate_hp": 150},
		"village": Rect2i(0, 0, 40, 9),  # 성곽(9행) 위쪽. 생산 시설은 여기에만 짓는다(S43)
		"rounds": rounds,
		"quests": true,  # 미션·의뢰(S77, I118): data/quests의 모든 미션·의뢰가 뜬다
		"waves": rounds[0],  # 1라운드. 라운드 하나뿐인 스테이지의 키라 시험 스테이지 평가(EV144)가 읽는다
	}
