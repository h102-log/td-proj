extends "res://tests/eval/gd/lib.gd"
# 플레이 후기 3 구현 검토(2026-11-01)에서 찾은 두 결함이 다시 생기지 않는지 본다. EV660·EV662는 이 갈래를 재지 않는다.
# 지키는 요구:
#   S277. 켜진 공병은 6칸 안·80% 밑이고 막힌 칸 없이 닿는(I125) 것 가운데 체력 비율이 가장 낮은 하나를 맡는다.
#   S276. 성벽 위에 선 유닛의 체력바는 머리 위다. 발 아래면 그 성곽 칸 막대(I59·S173)를 덮는다.

const GATES := [Vector2i(5, 9), Vector2i(15, 9), Vector2i(25, 9)]
const WALL := Vector2i(12, 9)

# 9행 성벽(성문 셋은 닫힘)이 마을과 들판을 가르는 판
func _castle():
	var walls := []
	for x in 30:
		if Vector2i(x, 9) not in GATES:
			walls.append(Vector2i(x, 9))
	return battle({"base": Vector2i(15, 4), "spawns": [Vector2i(15, 19)], "village": Rect2i(0, 0, 30, 9), "base_hp": BIG,
		"castle": {"walls": walls, "gates": GATES, "wall_hp": 300, "gate_hp": 150}})

func test_auto_fix_skips_walled_off_lowest():
	var b = _castle()
	var eng = b.place_merc("engineer", Vector2i(12, 7))
	var wall = b.castle[WALL]
	wall.hp = wall.max_hp * 0.7
	var tower = b.build("tower", Vector2i(12, 12))  # 성벽 너머, 6칸 안, 비율이 더 낮다
	tower.hp = tower.max_hp * 0.5
	b.live_prep = true
	b.set_auto_fix([eng], true)
	run(b, 1.0)
	return check(not b._reaches(eng, b._spot(eng, tower)) and eng.job == wall,
		"닿지 않는 타워(닿음 %s) 옆에서 성벽을 맡지 않았다: 일 %s" % [b._reaches(eng, b._spot(eng, tower)), eng.job])

func test_wall_top_bar_stays_over_head():
	var b = _castle()
	var m = b.place_merc("archer", WALL)
	var v = load("res://src/ui/battle_view.gd").new()
	v.battle = b
	v.controls = controls(b)
	var size := Vector2(16, 2)
	var got: Rect2 = v.hp_bar_rect(m, size)
	var head: Rect2 = v._bar_over(v.hp_bar_at(m), size)
	var cell_bar: Rect2 = v._bar_over(Vector2(WALL), size)  # 그 성곽 칸 막대 자리(_marks의 _hp_bar)
	v.free()
	return check(m.on_wall and got == head and not got.intersects(cell_bar),
		"성벽 위(%s) 궁수 막대 %s, 머리 위 %s, 성곽 칸 막대 %s" % [m.on_wall, got, head, cell_bar])
