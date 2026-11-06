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
#   main.hud.fix_tag — 자동 수리 태그(BaseButton, I210). hud.tags(A·S·H)와 따로다. 안의 첫 TextureRect가 그림이고 그 modulate가 밝기다
#     툴팁(main.hud.tip)에 «자동 수리»·«[F]». 누르면 F 키(Controls.toggle_auto_fix)와 같다. 유닛.auto_fix — 자동 수리 켬(S277)

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

# 6행을 가로로 막는 성곽(성문 5·15·25열, 모두 닫힘)을 더한 판. 위쪽(0~5행)이 마을이다
func _walled():
	var gates := [Vector2i(5, 6), Vector2i(15, 6), Vector2i(25, 6)]
	var walls := []
	for x in 30:
		if Vector2i(x, 6) not in gates:
			walls.append(Vector2i(x, 6))
	return _battle({"base": Vector2i(15, 2), "castle": {"walls": walls, "gates": gates, "wall_hp": 300, "gate_hp": 150}})

# EV229 · I125: 성문이 모두 닫혀 마을 안 공병이 들판 칸에 갈 수 없으면 건설 지시는 거부되고 골드가 그대로다. 성문을 열면 받아들여진다
func ev229():
	var b = _walled()
	b.place_merc("engineer", Vector2i(12, 4))
	_start(b)
	var g: int = b.gold
	var refused: bool = b.build("tower", T) == null and b.gold == g and b.structure_at(T) == null
	b.set_gate(b.castle[Vector2i(15, 6)], true)
	var s = b.build("tower", T)
	return check(refused and s != null and b.gold == g - b.STRUCTURE_KINDS.tower.cost,
		"닫힌 성곽 너머 건설 거부 %s · 성문을 열고 받아들여짐 %s(골드 %d → %d)" % [refused, s != null, g, b.gold])

# EV230 · I125: 닫힌 성곽 안쪽의 더 가까운 공병과 들판의 더 먼 공병이 있으면, 들판 칸 건설은 들판의 공병이 맡는다
func ev230():
	var b = _walled()
	var inner = b.place_merc("engineer", Vector2i(12, 4))
	var outer = b.place_merc("engineer", FAR)
	_start(b)
	var s = b.build("tower", T)
	return check(s != null and s.worker == outer, "일을 맡은 공병: %s(안쪽 %s · 들판 %s)" % [s.worker.pos if s and s.worker else null, inner.pos, outer.pos])

# 준비 단계 실시간 판(I175). 끈 채 판을 차린 뒤 켠다
func _live(b):
	b.live_prep = true
	return b

# 그 종류를 놓을 수 있는 칸 가운데 want에 가장 가까운 칸
func _nearest(b, kind: String, want: Vector2i) -> Vector2i:
	var best: Vector2i = b.placeable_cells(kind)[0]
	for c in b.placeable_cells(kind):
		if Vector2(c - want).length() < Vector2(best - want).length():
			best = c
	return best

# EV416 · S18: 준비 단계 실시간 판의 준비 단계 짓기·업그레이드·수리·복구는 공병이 가서 시간을 들인다. 마을 레벨 올리기는 바로 된다
func ev416():
	var b = _walled()
	var e = b.place_merc("engineer", NEAR)
	_live(b)
	var g: int = b.gold
	var s = b.build("tower", T)
	if s == null or s.complete or s.progress != 0.0 or b.gold != g - b.STRUCTURE_KINDS.tower.cost or e.job != s:
		return "지시 직후: 구조물 %s · 완성 %s · 진행률 %s · 골드 %d → %d · 공병의 일 %s" % [s, s.complete if s else null, s.progress if s else null, g, b.gold, e.job]
	g = b.gold
	if b.build("tower", Vector2i(14, 10)) != null or b.gold != g:
		return "공병이 일하는 동안 둘째 타워가 받아들여졌다(골드 %d → %d)" % [g, b.gold]
	b.finish(s)
	if s.complete:
		return "finish로 바로 완성됐다"
	run(b, 1.0)
	if s.complete:
		return "1초 만에 완성됐다"
	if not run(b, 30.0, func(): return s.complete):
		return "30초 안에 완성되지 않았다(진행률 %.2f)" % s.progress
	var k = b.castle[Vector2i(12, 6)]
	var lv: int = k.level
	b.upgrade(k)
	if k.level != lv or e.job != k:
		return "업그레이드 지시 직후 단계 %d → %d · 공병의 일 %s" % [lv, k.level, e.job]
	if not run(b, 30.0, func(): return k.level == lv + 1):
		return "30초 안에 업그레이드되지 않았다"
	var w = b.castle[Vector2i(10, 6)]
	b.damage(w, w.max_hp / 2.0)
	b.repair(w)
	if w.hp >= w.max_hp or e.job != w:
		return "수리 지시 직후 체력 %.0f/%.0f · 공병의 일 %s" % [w.hp, w.max_hp, e.job]
	if not run(b, 30.0, func(): return w.hp >= w.max_hp):
		return "30초 안에 수리되지 않았다(%.0f/%.0f)" % [w.hp, w.max_hp]
	var c := Vector2i(8, 6)
	b.damage(b.castle[c], BIG)
	var r = b.rubble.get(c)
	if r == null:
		return "성벽 칸이 잔해가 되지 않았다"
	b.restore(r)
	if not b.rubble.has(c) or e.job != r:
		return "복구 지시 직후 잔해 %s · 공병의 일 %s" % [b.rubble.has(c), e.job]
	if not run(b, 30.0, func(): return b.castle.has(c)):
		return "30초 안에 복구되지 않았다"
	var vl: int = b.village_level
	return check(b.raise_village() and b.village_level == vl + 1, "마을 레벨 올리기 %d → %d" % [vl, b.village_level])

# EV417 · I20: 준비 단계 실시간 판의 준비 단계 구매는 시설 옆에 나와 집결 지점으로 걷는다. 건설 격자 용병 칸(merc_key)은 시설을 고르고 다시 누르면 산다. 칸을 눌러 놓지 않는다
func ev417():
	var b = _battle()
	var f = b.build("barracks", Vector2i(10, 3))
	_live(b)
	var rally := Vector2i(10, 12)
	b.set_rally(f, rally)
	var g: int = b.gold
	var m = b.recruit(f)
	if m == null or b.gold != g - b.MERC_KINDS.soldier.cost or m.pos.distance_to(Vector2(f.cell)) > 1.5:
		return "준비 단계 구매: 용병 %s · 골드 %d → %d · 나온 자리 %s(병영 %s)" % [m, g, b.gold, m.pos if m else null, f.cell]
	if not run(b, 10.0, func(): return near(m.pos, rally)):
		return "10초 안에 집결 지점에 닿지 않았다(%s)" % m.pos
	var c = controls(b)
	var n: int = b.units.size()
	c.merc_key("soldier")  # 건설 격자 용병 칸과 같다. 용병 키 3은 없다(I108 2026-11-06 변경)
	if c.placing != "" or c.facility != f:
		return "용병 칸 뒤 놓기 모드 «%s» · 고른 시설 %s" % [c.placing, c.facility]
	c.merc_key("soldier")  # 건설 격자 용병 칸과 같다. 용병 키 3은 없다(I108 2026-11-06 변경)
	if b.units.size() != n + 1:
		return "용병 칸을 다시 눌러도 용병 %d → %d" % [n, b.units.size()]
	var cell := Vector2i(20, 14)
	click(c, MOUSE_BUTTON_LEFT, px(cell))
	return check(b.units.size() == n + 1 and not b.occupied(cell), "빈 칸 클릭 뒤 유닛 %d(%d여야 한다) · 그 칸에 유닛 %s" % [b.units.size(), n + 1, b.occupied(cell)])

# EV419 · I19: 준비 단계 실시간 판의 준비 단계에 시작한 일은 전투를 시작해도 이어지고, 웨이브가 끝나면 멈춘다
func ev419():
	var b = _battle()
	var e = b.place_merc("engineer", NEAR)
	_live(b)
	var s = b.build("tower", T, {"build_time": 60.0})
	run(b, 2.0)
	if s == null or s.progress <= 0.0:
		return "준비 단계 2초 뒤 진행률이 0이다(%s)" % [s.progress if s else null]
	var idle = _start(b)
	var p: float = s.progress
	run(b, 2.0)
	if e.job != s or s.progress <= p:
		return "전투 시작 뒤 공병의 일 %s · 진행률 %.3f → %.3f" % [e.job, p, s.progress]
	b.damage(idle, BIG)
	if not run(b, 5.0, func(): return b.state == "prep"):
		return "웨이브가 끝나지 않았다(%s)" % b.state
	p = s.progress
	run(b, 1.0)
	return check(e.job == null and s.worker == null and p < 1.0 and s.progress == p, "웨이브 뒤 공병의 일 %s · 일꾼 %s · 진행률 %.3f → %.3f" % [e.job, s.worker, p, s.progress])

# EV420 · S208: 준비 단계 실시간 판은 1라운드로 갈 때 공병 둘을 마을 안·밖에 무료로 세운다
func ev420():
	var stage: Dictionary = load("res://src/main.gd").stage()
	stage.gold = BIG
	var off = load("res://src/sim/battle.gd").new(stage.duplicate(true))
	off.begin_hiring()
	off.next_round()
	if off._mercs() != 0:
		return "끈 판에도 1라운드에 용병이 %d명이다" % off._mercs()
	var b = load("res://src/sim/battle.gd").new(stage)
	b.live_prep = true
	b.begin_hiring()
	b.next_round()
	var cells: Array = stage.get("engineer_cells", [])
	var es: Array = b.units.filter(func(u): return u.kind == "engineer")
	if cells.size() != 2 or es.size() != 2 or b._mercs() != 2 or es.map(func(u): return Vector2i(u.pos.round())) != cells:
		return "공병 칸 %s · 공병 %s · 상한에 세는 수 %d" % [cells, es.map(func(u): return u.pos), b._mercs()]
	var inner: Array = es.filter(func(u): return b.village.has_point(Vector2i(u.pos.round())))
	var outer: Array = es.filter(func(u): return not b.village.has_point(Vector2i(u.pos.round())))
	if inner.size() != 1 or outer.size() != 1:
		return "마을 안 공병 %d · 밖 공병 %d" % [inner.size(), outer.size()]
	var t = b.build("tower", _nearest(b, "tower", Vector2i(28, 31)))
	var f = b.build("barracks", _nearest(b, "barracks", Vector2i(26, 15)))
	if t == null or f == null or t.worker != outer[0] or f.worker != inner[0]:
		return "타워 %s(일꾼 %s) · 병영 %s(일꾼 %s)" % [t, t.worker if t else null, f, f.worker if f else null]
	var g: int = b.gold
	b.sell([inner[0]])
	if b.gold != g or f.worker != null:
		return "병영 짓는 공병을 팔자 골드 %d → %d · 병영 일꾼 %s" % [g, b.gold, f.worker]
	b.state = "cleared"
	b.next_round()
	var left: int = b.units.filter(func(u): return u.kind == "engineer").size()
	return check(left == 1, "다음 라운드에 공병이 %d명이다(1명이어야 한다)" % left)

# EV424 · S98: live_prep 판에서는 거점도 공병을 판다. 작업장이 생기면 작업장 다음이고, 끈 판은 작업장만 판다
func ev424():
	var stage: Dictionary = load("res://src/main.gd").stage()
	stage.gold = BIG
	var b = load("res://src/sim/battle.gd").new(stage.duplicate(true))
	b.live_prep = true
	b.begin_hiring()
	b.next_round()
	b.sell(b.units.filter(func(u): return u.kind == "engineer"))
	if b.units.any(func(u): return u.kind == "engineer") or b.sellers("engineer") != [b.base] or not b.can_buy("engineer"):
		return "작업장 없는 판: 남은 공병 %d · 파는 곳 %s · 살 수 있음 %s" % [b.units.filter(func(u): return u.kind == "engineer").size(), b.sellers("engineer"), b.can_buy("engineer")]
	var g: int = b.gold
	var e = b.recruit(b.base, "engineer")
	var d: Vector2i = cell_of(e) - b.base.cell if e else Vector2i.ZERO
	if e == null or e.kind != "engineer" or b.gold != g - b.MERC_KINDS.engineer.cost or absi(d.x) + absi(d.y) != 1 or b.base.rally != cell_of(e):
		return "거점에서 산 공병 %s · 골드 %d → %d · 자리 %s(거점 %s · 집결 지점 %s)" % [e, g, b.gold, e.pos if e else null, b.base.cell, b.base.rally]
	var w = b.build("workshop", _nearest(b, "workshop", Vector2i(26, 32)))
	if w == null or w.worker != e:
		return "작업장 %s · 일꾼 %s(거점에서 산 공병 %s)" % [w, w.worker if w else null, e]
	if not run(b, 30.0, func(): return w.complete):
		return "작업장이 30초 안에 완성되지 않았다(진행 %s)" % w.progress
	if b.sellers("engineer") != [w, b.base]:
		return "작업장을 지은 뒤 파는 곳 %s(작업장 %s · 거점 %s)" % [b.sellers("engineer"), w, b.base]
	var off = load("res://src/sim/battle.gd").new(stage)
	off.begin_hiring()
	off.next_round()
	off.start_battle()
	var og: int = off.gold
	var oe = off.recruit(off.base, "engineer")
	return check(off.state == "battle" and off.sellers("engineer") == [] and oe == null and off.gold == og, "끈 판 %s 단계: 파는 곳 %s · 거점 구매 %s · 골드 %d → %d" % [off.state, off.sellers("engineer"), oe, og, off.gold])

# 영웅 둘을 영입해 출전시키고 1라운드 준비 단계로 간 게임 장면(hud.gd _prep과 같다). 저장·설정은 평가용 파일로 바꿔 실제 파일을 건드리지 않는다
func _scene():
	load("res://src/sim/save.gd").path = "user://eval_save.dat"
	load("res://src/settings.gd").path = "user://eval_settings.cfg"
	load("res://src/main.gd").resume = {}
	var main = load("res://src/main.tscn").instantiate()
	Engine.get_main_loop().root.add_child(main)
	var b = main.view.battle
	b.gold = BIG
	for i in 2:
		b.hire(i)
	b.next_round()
	main._process(0.0)
	main.hud._process(0.0)
	for i in 2:  # 컨테이너 배치는 다음 프레임으로 미뤄진다. 평가는 한 프레임 안에서 돌아 직접 정렬한다(hud.gd _layout)
		for c in main.hud.find_children("*", "Container", true, false):
			c.notification(Container.NOTIFICATION_SORT_CHILDREN)
	return main

func _scene_done(main) -> void:
	Engine.get_main_loop().paused = false
	main.free()

func _mouse_to(at: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = at
	e.global_position = at
	Engine.get_main_loop().root.push_input(e, true)

# 빈 맵 (320,300)에서 툴팁을 닫고, 버튼에 커서를 0.25초 두었을 때 툴팁 안의 보이는 글. 뜨지 않으면 ""
func _tip_on(tip, btn) -> String:
	_mouse_to(Vector2(320, 300))
	tip._process(0.3)
	_mouse_to(btn.get_global_rect().get_center())
	tip._process(0.25)
	if not tip.visible:
		return ""
	return " ".join(tip.find_children("*", "Label", true, false).filter(func(l): return l.is_visible_in_tree()).map(func(l): return l.text))

# 태그의 그림: 안의 첫 TextureRect의 [텍스처, modulate]
func _pic_of(tag) -> Array:
	var pics: Array = tag.find_children("*", "TextureRect", true, false)
	return [pics[0].texture, pics[0].modulate] if not pics.is_empty() else [null, null]

# EV664 · I210: 공병을 고르면 A 태그 왼쪽 [582,182,24,24]에 자동 수리 태그가 뜬다. 보이는 글은 키 글자 «F» 하나이고 그림이 있으며
# hud.tags(A·S·H)와 따로다. 툴팁은 «자동 수리»·«[F]». 누르면 그 공병의 자동 수리가 켜지고 그림이 밝아진다. 병사만 고르면 숨는다
func ev664():
	var main = _scene()
	var b = main.view.battle
	var c = main.hud.controls
	var tag = main.hud.get("fix_tag")
	if not tag is BaseButton:
		_scene_done(main)
		return "main.hud.fix_tag가 BaseButton이 아니다(%s · 구현 없음)" % [tag]
	var eng = b.place_merc("engineer", Vector2i(20, 14))
	var sol = b.place_merc("soldier", Vector2i(21, 14))
	if eng == null or sol == null:
		_scene_done(main)
		return "준비 단계에 공병·병사를 놓지 못했다(%s · %s)" % [eng, sol]
	c.selected = [eng]
	main.hud._process(0.0)
	var out := ""
	var r: Rect2 = tag.get_global_rect()
	var want := Rect2(582, 182, 24, 24)
	var said: Array = tag.find_children("*", "Label", true, false).filter(func(l): return l.is_visible_in_tree()).map(func(l): return l.text)
	var text = tag.get("text")
	var tags = main.hud.get("tags")
	if not tag.is_visible_in_tree() or r.position.distance_to(want.position) > 0.5 or r.size.distance_to(want.size) > 0.5:
		out = "자동 수리 태그 %s · 보임 %s(기대 %s)" % [r, tag.is_visible_in_tree(), want]
	elif (text != null and text != "") or " ".join(said) != "F" or _pic_of(tag)[0] == null:
		out = "자동 수리 태그: 버튼 글 «%s» · 보이는 글 %s · 그림 %s(기대: 버튼 글 없음, 보이는 글은 «F» 하나, 그림 있음)" % [text, said, _pic_of(tag)[0]]
	elif not tags is Array or tags.size() != 3 or tag in tags:
		out = "hud.tags가 %s다(A·S·H 셋 그대로이고 자동 수리 태그는 따로여야 한다)" % [tags]
	if out == "":
		var tip := _tip_on(main.hud.tip, tag)
		if not "자동 수리" in tip or not "[F]" in tip:
			out = "자동 수리 태그 툴팁 «%s»(«자동 수리»·«[F]»가 있어야 한다)" % tip
	if out == "":
		var off: Color = _pic_of(tag)[1]
		tag.pressed.emit()
		main.hud._process(0.0)
		var lit: Color = _pic_of(tag)[1]
		if eng.get("auto_fix") != true or lit.get_luminance() <= off.get_luminance():
			out = "태그를 누른 뒤 공병 자동 수리 %s · 그림 밝기 %.2f → %.2f(밝아져야 한다)" % [eng.get("auto_fix"), off.get_luminance(), lit.get_luminance()]
	if out == "":
		c.selected = [sol]
		main.hud._process(0.0)
		out = check(not tag.is_visible_in_tree(), "병사만 골랐는데 자동 수리 태그가 보인다")
	_scene_done(main)
	return out

# EV792 · I24 2026-11-06 변경: 전투 단계에 놀고 있는 공병이 선 칸에도 짓고, 공병은 차지 칸 둘레 첫 빈 칸(앞 줄)으로 비켜서서 짓는다.
# 일을 맡은 공병이 선 칸에는 짓지 못한다
func ev792():
	var b = _battle()
	var e = b.place_merc("engineer", T)
	_start(b)
	var ok_cell: bool = b.can_build("tower", T) and T in b.placeable_cells("tower")
	var s = b.build("tower", T)
	if s == null:
		return "공병이 선 칸에 짓지 못했다(can_build·미리보기 %s)" % ok_cell
	var aside: bool = e.pos.distance_to(Vector2(T + Vector2i(0, 1))) <= 0.01 and e.job == s
	var busy: bool = not b.can_build("tower", T + Vector2i(0, 1))
	var done := run(b, 30.0, func(): return s.complete)
	return check(ok_cell and aside and busy and done, "can_build·미리보기 %s · 공병이 앞 칸에서 일 맡음 %s(자리 %s) · 일하는 공병 칸 거부 %s · 30초 안 완성 %s(진행률 %.2f)" % [ok_cell, aside, e.pos, busy, done, s.progress])

# EV793 · I24 2026-11-06 변경: 준비 단계에 병사가 선 칸은 그대로 거부하고, 걷던 공병이 선 칸에 지으면 바로 완성되고 공병은 비켜서며 걷기를 그만둔다
func ev793():
	var b = _battle()
	var e = b.place_merc("engineer", T)
	b.place_merc("soldier", T + Vector2i(4, 0))
	var refused: bool = not b.can_build("tower", T + Vector2i(4, 0)) and b.build("tower", T + Vector2i(4, 0)) == null
	b.order_move([e], FAR)
	var s = b.build("tower", T)
	if s == null:
		return "걷던 공병이 선 칸에 짓지 못했다(병사 칸 거부 %s)" % refused
	var aside: bool = s.complete and e.pos.distance_to(Vector2(T + Vector2i(0, 1))) <= 0.01 and e.path.is_empty()
	return check(refused and aside, "병사 칸 거부 %s · 완성·공병 앞 칸·걷기 그만둠 %s(완성 %s, 자리 %s, 길 %d칸)" % [refused, aside, s.complete, e.pos, e.path.size()])
