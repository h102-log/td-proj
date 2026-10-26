extends "res://tests/eval/gd/lib.gd"
# castle-3 두꺼운 성곽·문루(S217·I179). lib.gd·castle.gd·wall.gd 머리의 계약에 더하는 API:
#   stage castle 키 wall_size·gate_size: Vector2i — 성벽 열·성문의 크기(가로 × 깊이). 없으면 1×1. 성곽의 칸은 앞(들판 쪽) 왼쪽 칸이다
#   Battle.walls / Battle.debris: 차지 칸 → 성곽·잔해 Block · Battle.field_y: 성곽 아래 첫 줄
#   Battle.grid._compute_cost(from, to) — 길 격자가 한 칸 옮길 때 매기는 비용(grid.path를 한 번 부른 뒤 잰다)
#   Battle.repair(구조물·성곽) · Battle._target_of(적) — 적이 지금 노리는 것(S4)
# 맵: 9~11행이 두께 3줄 성곽(성문 문루 4~6·14~16·24~26열), 위쪽 0~8행이 마을, 아래 12~23행이 들판

const Main := preload("res://src/main.gd")
const IN := Vector2i(8, 4)  # 마을 칸
const COL := Vector2i(8, 11)  # 성벽 열 하나의 칸(앞줄). 차지 칸 (8, 9..11)
const MAIN := Vector2i(14, 11)  # 정문 문루의 칸. 차지 칸 (14..16, 9..11)

func _battle(over := {}):
	var gates := [Vector2i(4, 11), MAIN, Vector2i(24, 11)]
	var walls := []
	for x in 30:
		if not gates.any(func(g): return x >= g.x and x < g.x + 3):
			walls.append(Vector2i(x, 11))
	var stage := {"size": Vector2i(30, 24), "base": Vector2i(15, 4), "spawns": [Vector2i(15, 23)], "village": Rect2i(0, 0, 30, 9), "base_hp": BIG,
		"castle": {"walls": walls, "gates": gates, "wall_hp": 300, "gate_hp": 150, "wall_size": Vector2i(1, 3), "gate_size": Vector2i(3, 3)},
		"waves": [[{"kind": "basic", "count": 1}], [{"kind": "basic", "count": 1}]]}
	stage.merge(over, true)
	return battle(stage)

# 전투 단계를 연다. 웨이브 적은 바로 처치하고, 움직이지도 치지도 않는 적 하나를 구석에 남겨 전투 단계가 이어지게 한다
func _start(b):
	b.start_battle()
	run(b, 5.0, func(): return not b.enemies.is_empty())
	var idle = b.spawn_enemy("basic", Vector2i(0, 23), {"speed": 0, "sight": 0, "damage": 0})
	for x in b.enemies.duplicate():
		if x != idle:
			b.damage(x, BIG)
	return idle

# EV453 · S217: 시험 스테이지 성곽은 성벽 열 57개(1×3)와 정문 문루 하나(3×3)이고, 차지 칸 180개가 27~29행을 덮는다
func ev453():
	var b = load("res://src/sim/battle.gd").new(Main.stage())
	var cols: Array = b.castle.values().filter(func(k): return k.kind == "castle_wall")
	var gates: Array = b.castle.values().filter(func(k): return k.kind == "gate")
	if cols.size() != 57 or gates.size() != 1 or b.walls.size() != 180:
		return "성벽 열 %d·문루 %d·차지 칸 %d다(57·1·180이어야 한다)" % [cols.size(), gates.size(), b.walls.size()]
	if not cols.all(func(k): return k.size == Vector2i(1, 3) and k.cell.y == 29) or not gates.all(func(k): return k.size == Vector2i(3, 3) and k.cell.y == 29):
		return "성벽 열·문루 크기나 칸이 틀렸다"
	var k = b.walls.get(Vector2i(10, 29))
	for c in [Vector2i(10, 27), Vector2i(10, 28)]:
		if b.walls.get(c) != k or b.grid.block_at(c) != k:
			return "%s가 (10,29)와 같은 성벽 열이 아니다" % c
	for c in [Vector2i(29, 27), Vector2i(31, 28), Vector2i(30, 29)]:
		if b.walls.get(c) != b.castle.get(Vector2i(29, 29)):
			return "%s가 정문 문루가 아니다" % c
	return check(b.size == Vector2i(60, 63) and b.field_y == 30, "맵 %s·들판 첫 줄 %d다(60×63·30이어야 한다)" % [b.size, b.field_y])

# EV454 · S217: 열린 문루는 아홉 칸이 모두 지나갈 수 있고, 뒤 줄에 적이 서 있으면 닫히지 않는다
func ev454():
	var b = _battle()
	var g = b.castle[MAIN]
	b.set_gate(g, true)
	for y in range(9, 12):
		for x in range(14, 17):
			if b.grid.block_at(Vector2i(x, y)) != null:
				return "열린 문루 (%d,%d)가 막혔다" % [x, y]
	b.spawn_enemy("basic", Vector2i(15, 9), {"speed": 0, "sight": 0, "damage": 0, "hp": BIG})  # 문루 뒤 줄(마을 쪽)
	b.set_gate(g, false)
	return check(g.open, "문루 뒤 줄 (15,9)에 적이 서 있는데 성문이 닫혔다")

# EV455 · S217: 성벽 위 유닛은 성벽 뒤 줄에 올라 앞줄로 걸어간다
func ev455():
	var b = _battle()
	var m = b.place_merc("soldier", IN)
	if m == null:
		return "용병을 마을 (8,4)에 두지 못했다"
	_start(b)
	b.order_move([m], Vector2i(8, 9))
	if not run(b, 30.0, func(): return m.on_wall and near(m.pos, Vector2i(8, 9))):
		return "용병이 성벽 뒤 줄 (8,9)에 오르지 못했다(%s, 성벽 위 %s)" % [m.pos, m.on_wall]
	b.order_move([m], COL)
	return check(run(b, 30.0, func(): return m.on_wall and near(m.pos, COL)), "용병이 성벽 위로 앞줄 (8,11)에 가지 못했다(%s, 성벽 위 %s)" % [m.pos, m.on_wall])

# EV456 · S217: 성벽 열 세 칸 모두에 대포를 짓고, 그 열이 부서지면 대포 셋이 모두 부서지고 세 칸이 잔해(지나갈 수 있음)가 된다
func ev456():
	var b = _battle()
	for y in range(9, 12):
		if b.build("cannon", Vector2i(8, y)) == null:
			return "성벽 (8,%d)에 대포를 짓지 못했다" % y
	b.start_battle()
	b.damage(b.castle[COL], INF)
	for y in range(9, 12):
		var c := Vector2i(8, y)
		if b.structure_at(c) != null or b.grid.block_at(c) != null or b.debris.get(c) == null:
			return "부서진 성벽 열의 %s: 대포 %s · 막힘 %s · 잔해 %s" % [c, b.structure_at(c), b.grid.block_at(c), b.debris.get(c)]
	return ""

# EV457 · S217: 기어오르는 적은 앞줄을 오른 뒤 통로를 걸어 건너 마을로 내려가고, 성벽은 부수지 않는다
func ev457():
	var b = _battle()
	b.start_battle()
	var e = b.spawn_enemy("fast", Vector2i(8, 16), {"hp": BIG, "sight": 0})
	var rows := {}
	var done := run(b, 40.0, func():
		if e.on_wall:
			rows[Vector2i(e.pos.round()).y] = true
		return not e.on_wall and Vector2i(e.pos.round()).y <= 8)
	if not done:
		return "기어오르는 적이 40초 안에 마을에 들어오지 않았다(%s, 성벽 위 %s)" % [e.pos, e.on_wall]
	if not (rows.has(9) and rows.has(10) and rows.has(11)):
		return "성벽 위 세 줄을 모두 걷지 않았다(걸은 줄 %s)" % [rows.keys()]
	return check(b.castle.values().all(func(k): return k.hp == k.max_hp), "기어오르는 적이 성곽을 쳤다")

# EV458 · I179: 길 비용은 성벽 열에 들어갈 때 한 번이고 열 안에서는 거리만 센다
func ev458():
	var b = _battle()
	b.grid.wall_k = 1.0
	b.grid.path(Vector2i(8, 16), b.base.cell)
	if b.grid.block_at(Vector2i(8, 10)) != b.castle.get(COL):  # 열 안 비용을 재기 전에 (8,10)이 같은 열인지 본다(아니면 빈칸 비용 1로 빈 통과다)
		return "(8,10)이 성벽 열 (8,11)이 아니다(%s)" % [b.grid.block_at(Vector2i(8, 10))]
	var enter: float = b.grid._compute_cost(Vector2i(8, 12), COL)
	var inside: float = b.grid._compute_cost(COL, Vector2i(8, 10))
	if not is_equal_approx(enter, 1.0 + 300.0):
		return "성벽 열에 들어가는 비용이 %.1f다(1 + 체력 300이어야 한다)" % enter
	return check(is_equal_approx(inside, 1.0), "성벽 열 안에서 한 칸 옮기는 비용이 %.1f다(1이어야 한다)" % inside)

# EV459 · I179: 3라운드 땅 적은 문루에서 가장 가까운 칸까지 재서 성문을 고르고, 문루 칸에 들어서면 거점을 노린다
func ev459():
	var b = _battle({"waves": [[{"kind": "basic", "count": 1}]], "rounds": [[[{"kind": "basic", "count": 1}]], [[{"kind": "basic", "count": 1}]], [[{"kind": "basic", "count": 1}]]]})
	b.round_index = 2
	b.set_gate(b.castle[MAIN], true)
	var inside = b.spawn_enemy("basic", Vector2i(15, 10), {"speed": 0, "hp": BIG})  # 열린 정문 문루 가운데
	if b._target_of(inside) != b.base:
		return "문루 (15,10)에 선 적이 %s를 노린다(거점이어야 한다)" % [b._target_of(inside)]
	var far = b.spawn_enemy("basic", Vector2i(3, 20), {"speed": 0, "sight": 0, "hp": BIG})
	return check(b._target_of(far) == b.castle[Vector2i(4, 11)], "들판 (3,20)의 적이 %s를 노린다(왼쪽 문루여야 한다)" % [b._target_of(far)])

# EV460 · I179: 마을 공병이 성벽 열을 수리한다. 공병은 성곽 칸에 들어가지 않고 마을 쪽 옆 칸에서 고친다
func ev460():
	var b = _battle()
	var e = b.place_merc("engineer", IN)
	_start(b)
	var k = b.castle[COL]
	b.damage(k, 150.0)
	b.repair(k)
	if k.worker != e:
		return "마을 공병이 성벽 열 수리를 맡지 않았다(일꾼 %s)" % [k.worker]
	var stood := []
	var done := run(b, 60.0, func():
		if b.walls.has(Vector2i(e.pos.round())) or e.on_wall:
			stood.append(e.pos)
		return k.hp >= k.max_hp)
	if not stood.is_empty():
		return "공병이 성곽 칸 %s에 들어갔다" % stood[0]
	return check(done, "60초 안에 성벽 열을 다 고치지 못했다(체력 %.1f)" % k.hp)
