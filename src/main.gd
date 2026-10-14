extends Node2D
# 진입 씬. W1 시험 스테이지를 띄운다.

const Battle := preload("res://src/sim/battle.gd")
const BattleView := preload("res://src/ui/battle_view.gd")
const Camera := preload("res://src/ui/camera.gd")
const Controls := preload("res://src/ui/controls.gd")
const Hud := preload("res://src/ui/hud.gd")

var view
var controls

func _ready() -> void:
	view = BattleView.new()
	view.battle = Battle.new(stage())
	controls = Controls.new(view.battle, BattleView.CELL)
	view.controls = controls
	add_child(view)
	var cam := Camera.new()
	cam.map_px = Vector2(view.battle.size * BattleView.CELL)
	cam.position = Vector2(view.battle.base.cell * BattleView.CELL)
	add_child(cam)
	add_child(Hud.new(view.battle, controls))

func _process(delta: float) -> void:
	view.battle.step(delta)
	view.queue_redraw()

# 전투 시작은 HUD 버튼 말고 Enter·Space(기본 ui_accept)로도 된다
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		view.battle.start_battle()
	controls.handle(view.make_input_local(event))  # 화면 좌표 → 맵 px(카메라 줌·이동 반영)

# W1 시험 스테이지(40×32, S51 위아래 구도). 위쪽 마을을 가로 성곽이 막고, 적은 아래쪽 가장자리에서 온다.
static func stage() -> Dictionary:
	var gates := [Vector2i(0, 9), Vector2i(20, 9), Vector2i(39, 9)]  # 쪽문, 정문, 쪽문
	var walls := []
	for x in 40:
		if Vector2i(x, 9) not in gates:
			walls.append(Vector2i(x, 9))
	return {
		"size": Vector2i(40, 32), "base": Vector2i(20, 4), "base_hp": 100, "gold": 150,  # 시작 골드(S111)
		"spawns": [Vector2i(6, 31), Vector2i(20, 31), Vector2i(33, 31)],
		# 영웅은 정문 바로 앞 들판에서 시작한다. 성문 열기가 없어서 마을 안에 두면 나올 수 없다(I42, 사용자 2026-10-12)
		"hero_start": Vector2i(20, 11),
		# ponytail: 체력은 임시값이다. 성문이 성벽보다 약해야 한다는 것(I41)만 지킨다. 수치는 3.1 밸런스에서 정한다
		"castle": {"walls": walls, "gates": gates, "wall_hp": 300, "gate_hp": 150},
		"village": Rect2i(0, 0, 40, 9),  # 성곽(9행) 위쪽. 생산 시설은 여기에만 짓는다(S43)
		"waves": load("res://data/waves/test_stage.tres").to_stage(),  # S31, I66
	}
