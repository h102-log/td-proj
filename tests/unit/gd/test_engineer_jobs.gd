extends "res://tests/eval/gd/lib.gd"
# 공병이 맡은 일(짓기·허물기)이 언제 끝나고 언제 거부되는지 본다(WBS 2.16). EV43~EV73이 보지 않는 갈래만 둔다.
# 지키는 요구:
#   I63. 공병은 공격하지 않는다. 짓거나 허무는 칸의 옆 칸(대각선 포함)에서 일한다. 일하러 가거나 일하는 공병에게
#        플레이어가 이동 지시를 하면 그 일을 그만두고, 구조물은 그 상태로 남는다.
#   I64. 철거(S74)도 I39처럼 놀고 있는 공병 가운데 가장 가까운 공병이 간다. … 생산 시설은 철거하지 않는다.
#   I18. 미완성 구조물은 경로를 막고(I3) 체력이 있어 적이 부술 수 있다. 다만 완성되기 전에는 사격·생산 같은 기능을 하지 않는다.
#   I19. 준비 단계가 되어도 미완성 구조물은 미완성인 채로 남는다.
#   I24. 구조물은 격자 한 칸을 차지하고(거점은 예외), 비어 있는 칸(구조물·유닛·적이 없는 칸)에만 지을 수 있다.

const T := Vector2i(12, 10)

func _battle():
	return battle({"village": Rect2i(0, 0, 30, 6), "base_hp": BIG, "waves": [[{"kind": "basic", "count": 1}], [{"kind": "basic", "count": 1}]]})

# 전투 단계를 연다. 웨이브 적은 처치하고, 움직이지도 치지도 않는 적 하나를 남겨 전투 단계가 이어지게 한다
func _start(b):
	b.start_battle()
	run(b, 5.0, func(): return not b.enemies.is_empty())
	var idle = b.spawn_enemy("basic", Vector2i(0, 19), {"speed": 0, "sight": 0, "damage": 0})
	for x in b.enemies.duplicate():
		if x != idle:
			b.damage(x, BIG)
	return idle

func test_move_order_stops_job_and_leaves_structure():
	var b = _battle()
	var e = b.place_merc("engineer", Vector2i(12, 13))
	_start(b)
	var s = b.build("tower", T)
	run(b, 30.0, func(): return s.progress >= 0.3)
	b.order_move([e], Vector2i(12, 18))
	var p: float = s.progress
	run(b, 2.0)
	return check(e.job == null and s.worker == null and b.structure_at(T) == s and not s.complete and s.progress == p,
		"이동 지시 뒤 일 %s, 진행률 %.2f → %.2f" % [e.job, p, s.progress])

func test_engineer_does_not_attack():
	var b = _battle()
	b.place_merc("engineer", Vector2i(12, 13))
	_start(b)
	var foe = b.spawn_enemy("basic", Vector2i(12, 14), {"speed": 0, "sight": 0, "damage": 0})
	run(b, 3.0)
	return check(foe.hp == foe.max_hp, "공병 옆 적의 체력이 %.1f다" % foe.hp)

func test_facility_is_not_demolished():
	var b = _battle()
	var f = b.build("barracks", Vector2i(10, 3))
	var e = b.place_merc("engineer", Vector2i(12, 13))
	_start(b)
	b.demolish([f])
	return check(e.job == null and not b.can_demolish(f), "생산 시설에 철거 공병이 갔다")

func test_unfinished_facility_does_not_recruit():
	var b = _battle()
	b.place_merc("engineer", Vector2i(10, 5))
	_start(b)
	var w = b.build("workshop", Vector2i(10, 3))
	return check(w != null and not w.complete and b.recruit(w) == null, "미완성 작업장(%s)에서 샀다" % w)

func test_battle_build_rejected_on_enemy_cell():
	var b = _battle()
	b.place_merc("engineer", Vector2i(12, 13))
	var idle = _start(b)
	return check(b.build("wall", cell_of(idle)) == null, "적이 선 칸에 지어졌다")

func test_prep_stops_jobs():
	var b = _battle()
	var e = b.place_merc("engineer", Vector2i(12, 13))
	var idle = _start(b)
	var s = b.build("tower", T)
	run(b, 30.0, func(): return s.progress >= 0.3)
	b.damage(idle, BIG)
	run(b, 1.0, func(): return b.state == "prep")
	var p: float = s.progress
	run(b, 2.0)
	return check(b.state == "prep" and e.job == null and not s.complete and s.progress == p,
		"준비 단계에 %s, 일 %s, 진행률 %.2f → %.2f" % [b.state, e.job, p, s.progress])
