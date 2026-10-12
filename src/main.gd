extends Node2D
# 진입 씬. W1 시험 스테이지를 띄운다.

const Battle := preload("res://src/sim/battle.gd")
const BattleView := preload("res://src/ui/battle_view.gd")
const Camera := preload("res://src/ui/camera.gd")

var view

func _ready() -> void:
	view = BattleView.new()
	view.battle = Battle.new(stage())
	add_child(view)
	var cam := Camera.new()
	cam.map_px = Vector2(view.battle.size * BattleView.CELL)
	cam.position = Vector2(view.battle.base.cell * BattleView.CELL)
	add_child(cam)

func _process(delta: float) -> void:
	view.battle.step(delta)
	view.queue_redraw()

# ponytail: 웨이브 시작은 Enter·Space(기본 ui_accept)다. 전투 시작 버튼은 HUD를 만들 때(2.10) 붙인다
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		view.battle.start_battle()

# W1 시험 스테이지(40×32, S51 위아래 구도). 위쪽 마을을 가로 성곽이 막고, 적은 아래쪽 가장자리에서 온다.
static func stage() -> Dictionary:
	var gates := [Vector2i(0, 9), Vector2i(20, 9), Vector2i(39, 9)]  # 쪽문, 정문, 쪽문
	var walls := []
	for x in 40:
		if Vector2i(x, 9) not in gates:
			walls.append(Vector2i(x, 9))
	return {
		"size": Vector2i(40, 32), "base": Vector2i(20, 4), "base_hp": 100,
		"spawns": [Vector2i(6, 31), Vector2i(20, 31), Vector2i(33, 31)],
		# ponytail: 체력은 임시값이다. 성문이 성벽보다 약해야 한다는 것(I41)만 지킨다. 수치는 3.1 밸런스에서 정한다
		"castle": {"walls": walls, "gates": gates, "wall_hp": 300, "gate_hp": 150},
		"waves": [[{"kind": "basic", "count": 5}], [{"kind": "basic", "count": 8}], [{"kind": "basic", "count": 12}]],
	}
