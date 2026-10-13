extends "res://tests/eval/gd/lib.gd"
# WBS 2.16 공병(S22~S25·S49·S74·I5·I18·I19·I39). lib.gd·production.gd 머리의 계약에 더하는 API:
#   용병 kind "engineer"(공병) · 구조물 kind "workshop"(공병 생산 시설, produces "engineer")
#   전투 단계의 build(kind, cell) -> 진행률 0의 미완성 구조물|null — 놀고 있는 가장 가까운 공병을 보낸다
#   구조물: progress(0~1) · complete · worker(일하는 공병|null) · 유닛: job(일하는 구조물|null)
#   Battle.cancel(구조물) — 전투 단계에, 미완성 구조물을 없애고 낸 골드를 모두 돌려준다
#   Battle.resume(구조물) -> 공병|null — 전투 단계에, 일하는 공병이 없는 미완성 구조물에 놀고 있는 가장 가까운 공병을 보낸다
#   Battle.finish(구조물) — 준비 단계에, 미완성 구조물을 바로 완성한다
#   Battle.demolish(things: Array) — 전투 단계에, 완성된 방벽·타워마다 놀고 있는 가장 가까운 공병을 보내 허문다
#   Controls.picked — 전투 단계에 고른 플레이어 구조물(철거·취소·이어 짓기 대상)

const T := Vector2i(12, 10)  # 짓는 칸(들판)
const NEAR := Vector2i(12, 13)
const FAR := Vector2i(20, 16)

func _battle(over := {}):
	var stage := {"village": Rect2i(0, 0, 30, 6), "base_hp": BIG,
		"waves": [[{"kind": "basic", "count": 1}], [{"kind": "basic", "count": 1}]]}
	stage.merge(over, true)
	return battle(stage)

# 전투 단계를 연다. 웨이브 적은 바로 처치하고, 움직이지도 치지도 않는 적 하나를 구석에 남겨 전투 단계가 이어지게 한다
func _start(b):
	b.start_battle()
	run(b, 5.0, func(): return not b.enemies.is_empty())
	var idle = b.spawn_enemy("basic", Vector2i(0, 19), {"speed": 0, "sight": 0, "damage": 0})
	for x in b.enemies.duplicate():
		if x != idle:
			b.damage(x, BIG)
	return idle

# EV43 · S22: 전투 중 건설은 지시 직후 미완성이고, 공병이 가서 시간을 들여 완성한다
func ev43():
	var b = _battle()
	b.place_merc("engineer", NEAR)
	_start(b)
	var s = b.build("tower", T)
	if s == null or s.complete:
		return "지시 직후 미완성 구조물이 없다(%s)" % s
	return check(run(b, 30.0, func(): return s.complete), "완성되지 않았다(진행률 %.2f)" % s.progress)

# EV44 · S23: 짓는 중에 취소하면 구조물이 사라지고 낸 골드가 모두 돌아온다
func ev44():
	var b = _battle()
	b.place_merc("engineer", NEAR)
	_start(b)
	var before: int = b.gold
	var s = b.build("tower", T)
	if s == null or not run(b, 30.0, func(): return s.progress > 0.0):
		return "짓기 시작하지 않았다"
	b.cancel(s)
	return check(b.gold == before and b.structure_at(T) == null, "취소 뒤 골드 %d(지시 전 %d), 칸 %s" % [b.gold, before, b.structure_at(T)])

# EV45 · S24: 짓다 죽으면 체력이 «최대 체력 × 진행률»인 미완성 구조물이 남고, 더 지어지지 않는다
func ev45():
	var b = _battle()
	var e = b.place_merc("engineer", NEAR)
	_start(b)
	var s = b.build("tower", T)
	if s == null or not run(b, 30.0, func(): return s.progress >= 0.4):
		return "진행률 0.4에 닿지 않았다"
	b.damage(e, BIG)
	var p: float = s.progress
	run(b, 1.0)
	return check(not s.complete and s.progress == p and absf(s.hp - s.max_hp * p) < 0.01,
		"진행률 %.3f → %.3f, 체력 %.2f(기대 %.2f)" % [p, s.progress, s.hp, s.max_hp * p])

# EV46 · S24: 남은 미완성 구조물을 이어 짓게 하면 다른 공병이 가서 완성한다
func ev46():
	var b = _battle()
	var first = b.place_merc("engineer", NEAR)
	var second = b.place_merc("engineer", FAR)
	_start(b)
	var s = b.build("tower", T)
	if s == null or not run(b, 30.0, func(): return s.progress >= 0.2):
		return "짓기 시작하지 않았다"
	b.damage(first, BIG)
	if b.resume(s) != second:
		return "남은 공병이 이어 짓도록 배정되지 않았다"
	return check(run(b, 60.0, func(): return s.complete), "완성되지 않았다(진행률 %.2f)" % s.progress)

# EV48 · I5: 적의 경로 위에 방벽이 완성되면 적이 길을 다시 찾아 돌아간다
func ev48():
	var b = _battle()
	var e = b.place_merc("engineer", Vector2i(12, 16))
	_start(b)
	var foe = b.spawn_enemy("basic", Vector2i(0, 10), {"sight": 0, "damage": 0})
	var s = b.build("wall", T)
	if s == null or not run(b, 30.0, func(): return s.complete):
		return "방벽이 완성되지 않았다"
	b.order_move([e], Vector2i(12, 18))  # 공병이 돌아가는 길을 몸으로 막지 않게 비킨다
	return check(run(b, 60.0, func(): return at_base(b, foe)) and s.alive and s.hp == s.max_hp,
		"적이 거점에 닿지 못했다(위치 %s, 방벽 체력 %.1f)" % [foe.pos, s.hp])

# EV49 · I18: 미완성 타워는 쏘지 않는다
func ev49():
	var b = _battle()
	var e = b.place_merc("engineer", NEAR)
	_start(b)
	var s = b.build("tower", T)
	b.damage(e, BIG)  # 짓는 공병이 없어 미완성으로 남는다
	var foe = b.spawn_enemy("basic", T + Vector2i(2, 0), {"speed": 0, "sight": 0, "damage": 0})
	run(b, 3.0)
	return check(s != null and not s.complete and foe.hp == foe.max_hp, "미완성 타워(%s)가 적을 쳤다(체력 %.1f)" % [s, foe.hp])

# EV51 · I39: 놀고 있는 공병 가운데 건설 칸에 더 가까운 공병이 간다
func ev51():
	var b = _battle()
	var near_e = b.place_merc("engineer", NEAR)
	b.place_merc("engineer", FAR)
	_start(b)
	var s = b.build("tower", T)
	return check(s != null and near_e.job == s and s.worker == near_e, "가까운 공병이 배정되지 않았다(%s)" % [s.worker if s else null])

# EV52 · I39: 놀고 있는 공병이 없으면 전투 중 건설은 거부된다. 짓는 중인 공병은 놀고 있지 않다
func ev52():
	var b = _battle()
	b.place_merc("engineer", NEAR)
	_start(b)
	if b.build("tower", T) == null:
		return "첫 건설 지시가 거부됐다"
	var other := T + Vector2i(3, 0)
	var before: int = b.gold
	var s = b.build("tower", other)
	return check(s == null and b.gold == before and b.structure_at(other) == null, "일하는 공병뿐인데 지어졌다(골드 %d → %d)" % [before, b.gold])

# EV69 · S25: 공병도 배치 상한에 센다
func ev69():
	var b = _battle({"merc_cap": 3})
	for kind in ["soldier", "soldier", "engineer"]:
		if b.place_merc(kind, Vector2i(10 + b.units.size() * 2, 12)) == null:
			return "상한 안의 %s를 놓지 못했다" % kind
	var f = b.build("barracks", Vector2i(10, 3))
	_start(b)
	var before: int = b.gold
	var m = b.recruit(f)
	return check(m == null and b.gold == before, "공병을 세지 않고 샀다(골드 %d → %d)" % [before, b.gold])

# EV70 · S74: 철거는 공병이 가서 시간을 들여 허물고, 골드는 돌려받지 않는다
func ev70():
	var b = _battle()
	var t = b.build("tower", T)
	b.place_merc("engineer", NEAR)
	_start(b)
	var before: int = b.gold
	b.demolish([t])
	if b.structure_at(T) != t:
		return "철거 지시 즉시 사라졌다"
	return check(run(b, 30.0, func(): return b.structure_at(T) == null) and b.gold == before,
		"타워 %s, 골드 %d → %d" % [b.structure_at(T), before, b.gold])

# EV71 · S74: 전투 단계에 타워 칸을 좌클릭하면 철거 후보가 그 타워 하나다
func ev71():
	var b = _battle()
	var c = controls(b)
	var t = b.build("tower", T)
	_start(b)
	click(c, MOUSE_BUTTON_LEFT, px(T))
	return check(c.picked == [t], "철거 후보가 %s다" % [c.picked])

# EV72 · I19: 준비 단계에 남은 미완성 구조물은 추가 비용 없이 바로 완성시킬 수 있다
func ev72():
	var b = _battle()
	var e = b.place_merc("engineer", NEAR)
	var idle = _start(b)
	var s = b.build("tower", T)
	b.damage(e, BIG)
	b.damage(idle, BIG)
	if s == null or not run(b, 5.0, func(): return b.state == "prep") or s.complete:
		return "준비 단계에 미완성 구조물이 없다(%s, %s)" % [b.state, s]
	var before: int = b.gold
	b.finish(s)
	return check(s.complete and b.gold == before, "완성 %s, 골드 %d → %d" % [s.complete, before, b.gold])

# EV73 · S49: 작업장에서 산 용병은 공병이다
func ev73():
	var b = _battle()
	var w = b.build("workshop", Vector2i(10, 3))
	_start(b)
	var m = b.recruit(w) if w else null
	return check(m != null and m.kind == "engineer", "작업장에서 산 것: %s" % [m.kind if m else null])
