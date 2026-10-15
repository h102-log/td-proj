extends "res://tests/eval/gd/lib.gd"
# 성벽 위 대포에 반격하는 기어오르는 적(S112). lib.gd·units.gd 머리의 계약을 쓴다
# 맵은 units.gd와 같다: 9행이 가로 성곽(성문 5·15·25열, 모두 닫힘), 위쪽(0~8행)이 마을, 아래쪽이 들판

const TOP := Vector2i(12, 9)  # 대포를 짓는 성벽 칸
const GATES := [Vector2i(5, 9), Vector2i(15, 9), Vector2i(25, 9)]

func _battle():
	var walls := []
	for x in 30:
		if Vector2i(x, 9) not in GATES:
			walls.append(Vector2i(x, 9))
	return battle({"base": Vector2i(15, 4), "spawns": [Vector2i(15, 19)], "village": Rect2i(0, 0, 30, 9), "base_hp": BIG,
		"castle": {"walls": walls, "gates": GATES, "wall_hp": 300, "gate_hp": 150}})

# EV171 · S112: 성벽 위 대포에 맞은 빠름 적은 성벽 위로 올라가 대포를 치고, 아래 성벽은 치지 않는다
func ev171():
	var b = _battle()
	var s = b.build("cannon", TOP)
	if s == null:
		return "성벽 칸에 대포를 짓지 못했다"
	var k = b.castle[TOP]
	var e = b.spawn_enemy("fast", TOP + Vector2i(0, 4), {"sight": 0, "hp": BIG})
	# 다가가서 오르기까지 4초쯤 걸린다(3칸 ÷ 속도 3.5 + 오르는 시간 3초, S106·S107)
	if not run(b, 10.0, func(): return s.hp < s.max_hp):
		return "10초 안에 대포를 치지 않았다(적 %s, 성벽 위 %s)" % [e.pos, e.on_wall]
	return check(e.on_wall and k.hp == k.max_hp, "대포를 칠 때 성벽 위 %s · 성벽 체력 %s/%s" % [e.on_wall, k.hp, k.max_hp])
