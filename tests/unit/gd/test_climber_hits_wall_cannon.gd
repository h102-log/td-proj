extends "res://tests/eval/gd/lib.gd"
# 성벽 위 대포에 맞은 기어오르는 적이 대포 칸에 올라선 채 서 있지 않고, 성벽 위에서 대포를 치는지 본다.
# 지키는 요구:
#   S112. 성벽 위 대포에 맞아 반격하러 온 기어오르는 적(S107)은 그 성벽 칸 위로 올라가 대포를 친다. 아래 성벽은 치지 않는다.
#   S93. 성벽 위 대포가 부서져도 그 아래 성벽 칸은 남는다.
# 맵은 평가 units.gd와 같다: 9행이 가로 성곽(성문 5·15·25열, 모두 닫힘), 위쪽(0~8행)이 마을, 아래쪽이 들판

const TOP := Vector2i(12, 9)  # 대포를 짓는 성벽 칸
const GATES := [Vector2i(5, 9), Vector2i(15, 9), Vector2i(25, 9)]

func _battle():
	var walls := []
	for x in 30:
		if Vector2i(x, 9) not in GATES:
			walls.append(Vector2i(x, 9))
	return battle({"base": Vector2i(15, 4), "spawns": [Vector2i(15, 19)], "village": Rect2i(0, 0, 30, 9), "base_hp": BIG,
		"castle": {"walls": walls, "gates": GATES, "wall_hp": 300, "gate_hp": 150}})

func test_climber_hits_wall_cannon_from_wall():
	var b = _battle()
	var s = b.build("cannon", TOP)
	var k = b.castle[TOP]
	var e = b.spawn_enemy("fast", TOP + Vector2i(0, 4), {"sight": 0, "hp": BIG})
	# 다가가서 오르기까지 4초쯤 걸린다(3칸 ÷ 속도 3.5 + 오르는 시간 3초, S106·S107)
	if not run(b, 10.0, func(): return s.hp < s.max_hp):
		return "10초 안에 대포를 치지 않았다(적 %s, 성벽 위 %s)" % [e.pos, e.on_wall]
	return check(e.on_wall and k.hp == k.max_hp, "대포를 칠 때 성벽 위 %s · 성벽 체력 %s/%s" % [e.on_wall, k.hp, k.max_hp])
