extends "res://tests/eval/gd/lib.gd"
# castle-3 두꺼운 성곽·문루(S217·I179). lib.gd·castle.gd·wall.gd 머리의 계약에 더하는 API:
#   stage castle 키 wall_size·gate_size: Vector2i — 성벽 열·성문의 크기(가로 × 깊이). 없으면 1×1. 성곽의 칸은 앞(들판 쪽) 왼쪽 칸이다
#   Battle.walls / Battle.debris: 차지 칸 → 성곽·잔해 Block · Battle.field_y: 성곽 아래 첫 줄
#   Battle.grid._compute_cost(from, to) — 길 격자가 한 칸 옮길 때 매기는 비용(grid.path를 한 번 부른 뒤 잰다)
#   Battle.repair(구조물·성곽) · Battle._target_of(적) — 적이 지금 노리는 것(S4)
#   BattleView: battle · controls · _draw() · _wall_piece(성곽·잔해 Block, 조각) · _feet_mark(몸, 번호) · _body(몸, 번호, next, 색, 번쩍임) · _zones()
#     · _spot(몸) · rise_at(판, 칸) · _marks() · _facility(구조물, 색) · _lift(구조물) · GHOST_OK·GHOST_NO · ghost(판, 종류, 칸) · Controls: mouse(맵 px) · placing
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

# EV453 · S217: 시험 스테이지(사방 성곽)의 성곽은 남·북 성벽 열 114개(1×3, 칸 59·2행), 동·서 성벽 행 102개(3×1, 칸 0·57열, 3~56행에서 29~31행 뺌),
# 문루 넷(3×3)이고 차지 칸 684개가 서로 겹치지 않는다. 맵 60×93, 들판 첫 줄 60, 마을 (3,3)부터 54×54, 거점 (30,30)
func ev453():
	var b = load("res://src/sim/battle.gd").new(Main.stage())
	var cols: Array = b.castle.values().filter(func(k): return k.kind == "castle_wall" and k.size == Vector2i(1, 3))
	var rows: Array = b.castle.values().filter(func(k): return k.kind == "castle_wall" and k.size == Vector2i(3, 1))
	var gates: Array = b.castle.values().filter(func(k): return k.kind == "gate")
	if cols.size() != 114 or rows.size() != 102 or gates.size() != 4 or b.castle.size() != 220 or b.walls.size() != 684:
		return "성벽 열 %d·행 %d·문루 %d·Block %d·차지 칸 %d다(114·102·4·220·684여야 한다)" % [cols.size(), rows.size(), gates.size(), b.castle.size(), b.walls.size()]
	if not cols.all(func(k): return k.cell.y in [2, 59]) or not rows.all(func(k): return k.cell.x in [0, 57] and k.cell.y >= 3 and k.cell.y <= 56 and (k.cell.y < 29 or k.cell.y > 31)):
		return "성벽 열·행의 칸이 틀렸다"
	if gates.map(func(k): return k.cell) != [Vector2i(29, 59), Vector2i(29, 2), Vector2i(0, 31), Vector2i(57, 31)] or not gates.all(func(k): return k.size == Vector2i(3, 3)):
		return "문루가 %s다" % [gates.map(func(k): return [k.cell, k.size])]
	var area := 0
	for k in b.castle.values():
		area += k.size.x * k.size.y
	if area != b.walls.size():
		return "차지 칸이 겹친다(크기 합 %d · 차지 칸 %d)" % [area, b.walls.size()]
	for pair in [[Vector2i(1, 10), Vector2i(0, 10)], [Vector2i(2, 10), Vector2i(0, 10)], [Vector2i(0, 0), Vector2i(0, 2)], [Vector2i(58, 57), Vector2i(58, 59)],
			[Vector2i(30, 1), Vector2i(29, 2)], [Vector2i(59, 30), Vector2i(57, 31)], [Vector2i(10, 57), Vector2i(10, 59)]]:
		if b.walls.get(pair[0]) != b.castle.get(pair[1]) or b.grid.block_at(pair[0]) != b.castle.get(pair[1]):
			return "%s가 %s의 Block이 아니다" % pair
	return check(b.size == Vector2i(60, 93) and b.field_y == 60 and b.village == Rect2i(3, 3, 54, 54) and b.base.cell == Vector2i(30, 30),
		"맵 %s·들판 첫 줄 %d·마을 %s·거점 %s다" % [b.size, b.field_y, b.village, b.base.cell])

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

# 시험 스테이지(사방 성곽)를 웨이브 하나로 줄인 판. 전투 단계를 열고 웨이브 적은 처치하고, 움직이지도 치지도 않는 적 하나를 맨 아래 줄 구석에 남긴다
func _square_battle():
	var st: Dictionary = Main.stage()
	for k in ["rounds", "hp_mult", "nights", "quests"]:
		st.erase(k)
	st.waves = [[{"kind": "basic", "count": 1}], [{"kind": "basic", "count": 1}]]
	st.hero_start = null
	var b = battle(st)
	return b

# EV464 · S39: 시험 스테이지 준비 단계에 북·서·동 닫힌 문루를 열라 하면 닫힌 채이고, 정문 문루는 열린다
func ev464():
	var b = load("res://src/sim/battle.gd").new(Main.stage())
	b.begin_hiring()
	b.next_round()
	if b.state != "prep":
		return "준비 단계가 아니다(%s)" % b.state
	for c in [Vector2i(29, 2), Vector2i(0, 31), Vector2i(57, 31)]:
		var g = b.castle.get(c)
		if g == null or g.kind != "gate":
			return "%s가 문루가 아니다" % c
		b.set_gate(g, true)
		if g.open:
			return "닫힌 문루 %s가 열렸다" % c
	var main_gate = b.castle[Vector2i(29, 59)]
	b.set_gate(main_gate, true)
	return check(main_gate.open, "정문 문루가 열리지 않았다")

# EV465 · S217: 시험 스테이지 전투 단계에 마을 (20,40)의 병사를 북쪽 성벽 위 (10,1)로 보내면 90초 안에 성벽 위로 닿고,
# 이어 서쪽 성벽 위 (1,20)으로 보내면 90초 안에 성벽 위로 닿는다(사방 성벽 위 고리)
func ev465():
	var b = _square_battle()
	var m = b.place_merc("soldier", Vector2i(20, 40))
	if m == null:
		return "병사를 마을 (20,40)에 두지 못했다"
	b.start_battle()
	run(b, 5.0, func(): return not b.enemies.is_empty())
	var idle = b.spawn_enemy("basic", Vector2i(0, 92), {"speed": 0, "sight": 0, "damage": 0})
	for x in b.enemies.duplicate():
		if x != idle:
			b.damage(x, BIG)
	b.order_move([m], Vector2i(10, 1))
	if not run(b, 90.0, func(): return m.on_wall and near(m.pos, Vector2i(10, 1))):
		return "병사가 북쪽 성벽 위 (10,1)에 닿지 못했다(%s, 성벽 위 %s)" % [m.pos, m.on_wall]
	b.order_move([m], Vector2i(1, 20))
	return check(run(b, 90.0, func(): return m.on_wall and near(m.pos, Vector2i(1, 20))), "병사가 서쪽 성벽 위 (1,20)에 닿지 못했다(%s, 성벽 위 %s)" % [m.pos, m.on_wall])

# 성곽 조각·발밑·몸통·장판을 그리는 대신 부른 차례를 모으는 화면
class Rec extends "res://src/ui/battle_view.gd":
	var calls := []  # [이름, 대상]

	func _wall_piece(b, _front: int) -> void:
		calls.append(["wall", b])

	func _feet_mark(x, _i: int) -> void:
		calls.append(["feet", x])

	func _body(x, _i: int, _next: Dictionary, _tint := Color.WHITE, _flash := true) -> void:
		calls.append(["body", x])

	func _zones() -> void:
		calls.append(["zones", null])

# EV566 · S170: 잔해는 바닥 층이다. 정문 잔해 조각은 장판보다 먼저, 잔해 가운데 줄 병사의 발밑·몸통은 장판보다 나중에 그린다
func ev566():
	var b = _battle()
	var gate = b.castle[MAIN]
	b.damage(gate, BIG)
	var m = b.place_merc("soldier", MAIN + Vector2i(1, -1))
	if b.rubble.get(MAIN) != gate or m == null:
		return "정문이 잔해가 되지 않았거나(%s) 잔해 가운데 줄에 병사를 놓지 못했다(%s)" % [b.rubble.keys(), m]
	var v = Rec.new()
	v.battle = b
	v.controls = controls(b)
	v._draw()
	var order: Array = v.calls.filter(func(c): return c[1] == gate or c[1] == m or c[0] == "zones").map(func(c): return c[0])
	v.free()
	var z := order.find("zones")
	return check(order.has("wall") and order.has("feet") and order.has("body") and z >= 0 and order.rfind("wall") < z and order.find("feet") > z and order.find("body") > z,
		"부른 차례 %s" % [order])

# EV567 · S170: 성벽 위 병사는 선 자리대로 그린다. 남북으로는 고르게, 성벽 열(12)과 탑 열(13) 사이는 비탈처럼
func ev567():
	var b = _battle()
	var m = b.place_merc("soldier", IN)
	if m == null:
		return "병사를 마을 %s에 두지 못했다" % [IN]
	m.on_wall = true
	var v = load("res://src/ui/battle_view.gd").new()
	v.battle = b
	var y := func(p: Vector2) -> float:
		m.pos = p
		return v._spot(m).y
	var y0: float = y.call(Vector2(8, 9.0))
	var steps := [y.call(Vector2(8, 9.4)) - y0, y.call(Vector2(8, 9.6)) - y0]
	var r12: int = v.rise_at(b, Vector2i(12, 10))
	var r13: int = v.rise_at(b, Vector2i(13, 10))
	var flat: float = y.call(Vector2(12, 10))
	var half: float = flat - y.call(Vector2(12.5, 10))
	var top: float = flat - y.call(Vector2(13, 10))
	v.free()
	return check(absf(steps[0] - 6.4) <= 0.5 and absf(steps[1] - 9.6) <= 0.5 and r13 > r12 and absf(half - (r13 - r12) / 2.0) <= 0.5 and absf(top - (r13 - r12)) <= 0.5,
		"남북 %s px(6.4·9.6이어야 한다) · 바닥 높이 12열 %d 13열 %d · 12.5열 %.1f px · 13열 %.1f px 위" % [steps, r12, r13, half, top])

# 시설 그림을 그리는 대신 [구조물, 색, 올림]을 모으는 화면
class FacRec extends "res://src/ui/battle_view.gd":
	var facs := []

	func _facility(s, tint := Color.WHITE) -> void:
		facs.append([s, tint, _lift(s)])

# EV568 · S216: 놓기 미리보기는 지어질 그림 자리에 청사진을 겹친다. 성벽 칸 대포는 지은 대포처럼 올린다
func ev568():
	var b = _battle()
	var c = controls(b)
	var v = FacRec.new()
	v.battle = b
	v.controls = c
	var cell := COL + Vector2i(0, -1)  # 성벽 열 가운데 줄 (8,10)
	c.mouse = (Vector2(cell) + Vector2(0.5, 0.5)) * CELL_PX
	c.placing = "cannon"
	v._marks()
	var cannon: Array = v.facs.duplicate()
	v.facs.clear()
	c.placing = "tower"
	v._marks()
	var tower: Array = v.facs.duplicate()
	c.placing = ""
	var s = b.build("cannon", cell)
	var real: float = v._lift(s) if s != null else -1.0
	var ok: Color = v.GHOST_OK
	var no: Color = v.GHOST_NO
	v.free()
	var good_c: bool = cannon.size() == 1 and cannon[0][0].kind == "cannon" and cannon[0][0].cell == cell and not cannon[0][0].complete and cannon[0][0].progress == 0.0 \
		and cannon[0][1] == ok and cannon[0][2] > 0.0 and absf(cannon[0][2] - real) < 0.01
	var good_t: bool = tower.size() == 1 and tower[0][0].kind == "tower" and tower[0][0].cell == cell and tower[0][1] == no
	return check(good_c and good_t, "대포 %s · 지은 대포 올림 %.2f · 타워 %s" % [cannon.map(func(f): return [f[0].kind, f[0].cell, f[1], f[2]]), real, tower.map(func(f): return [f[0].kind, f[0].cell, f[1]])])

# EV569 · I138: 실시간 단계의 놓기 미리보기는 닿는 공병이 없는 칸을 지을 수 없다고 본다
func ev569():
	var b = _battle()
	var BV = load("res://src/ui/battle_view.gd")
	if b.place_merc("engineer", IN) == null:
		return "공병을 마을 %s에 두지 못했다" % [IN]
	var mid := COL + Vector2i(0, -1)
	var back := COL + Vector2i(0, -2)
	var prep: bool = BV.ghost(b, "cannon", mid)[1]
	_start(b)
	var live := [BV.ghost(b, "cannon", back)[1], BV.ghost(b, "cannon", mid)[1]]
	return check(b.state == "battle" and prep and live == [true, false], "%s · 준비 단계 (8,10) %s · 전투 단계 (8,9) %s (8,10) %s" % [b.state, prep, live[0], live[1]])
