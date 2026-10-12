extends Node2D
# 진입 씬. W1 시험 스테이지를 띄운다.

const Battle := preload("res://src/sim/battle.gd")
const BattleView := preload("res://src/ui/battle_view.gd")

func _ready() -> void:
	var view := BattleView.new()
	view.battle = Battle.new(stage())
	add_child(view)

# W1 시험 스테이지(30×20). 마을은 오른쪽 가장자리에 붙고 ㄷ자 성곽이 감싼다.
static func stage() -> Dictionary:
	var gates := [Vector2i(19, 10), Vector2i(29, 4), Vector2i(29, 16)]  # 정문, 양 끝 쪽문
	var walls := []
	for y in range(4, 17):
		walls.append(Vector2i(19, y))
	for x in range(20, 30):
		walls.append(Vector2i(x, 4))
		walls.append(Vector2i(x, 16))
	return {
		"size": Vector2i(30, 20), "base": Vector2i(25, 10), "base_hp": 100,
		"spawns": [Vector2i(0, 10), Vector2i(10, 0), Vector2i(10, 19)],
		# ponytail: 체력은 임시값이다. 성문이 성벽보다 약해야 한다는 것(I41)만 지킨다. 수치는 3.1 밸런스에서 정한다
		"castle": {"walls": walls.filter(func(c): return c not in gates), "gates": gates, "wall_hp": 300, "gate_hp": 150},
	}
