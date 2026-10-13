extends "res://tests/eval/gd/lib.gd"
# WBS 2.20 성곽 ② 성벽 위 이동·원거리 공격·궁수(S42·S87·S88·S89·I44·I69·I70). lib.gd·castle.gd 머리의 계약에 더하는 API:
#   stage 키 village: Rect2i(마을 칸)
#   order_move(units, 성곽 칸) — 성벽 위의 그 칸으로 보낸다 · 유닛: on_wall(성벽 위에 있나) · range · kind
#   용병 kind "archer"(궁수) · 구조물 kind "barracks"(병영)
#   Battle.recruit(시설, kind="") -> 용병|null — kind를 비우면 시설의 기본 용병을 산다
# 맵: 9행이 가로 성곽(성문 5·15·25열), 위쪽(0~8행)이 마을, 아래쪽이 들판. 적은 아래 가장자리에서 온다

const MAIN := Vector2i(15, 9)  # 정문
const TOP := Vector2i(12, 9)  # 성벽 칸
const IN := Vector2i(10, 4)  # 마을 칸
const OUT := Vector2i(10, 14)  # 들판 칸

func _battle():
	var gates := [Vector2i(5, 9), MAIN, Vector2i(25, 9)]
	var walls := []
	for x in 30:
		if Vector2i(x, 9) not in gates:
			walls.append(Vector2i(x, 9))
	return battle({"base": Vector2i(15, 4), "spawns": [Vector2i(15, 19)], "village": Rect2i(0, 0, 30, 9), "base_hp": BIG,
		"castle": {"walls": walls, "gates": gates, "wall_hp": 300, "gate_hp": 150},
		"waves": [[{"kind": "basic", "count": 1}], [{"kind": "basic", "count": 1}]]})

# 전투 단계를 연다. 웨이브 적은 바로 처치하고, 움직이지도 치지도 않는 적 하나를 구석에 남겨 전투 단계가 이어지게 한다
func _start(b):
	b.start_battle()
	run(b, 5.0, func(): return not b.enemies.is_empty())
	var idle = b.spawn_enemy("basic", Vector2i(0, 19), {"speed": 0, "sight": 0, "damage": 0})
	for x in b.enemies.duplicate():
		if x != idle:
			b.damage(x, BIG)
	return idle

# 마을에 놓은 용병을 성벽 위 그 칸에 올린다. 못 오르면 null
func _up(b, kind: String, cell: Vector2i):
	var m = b.place_merc(kind, IN)
	b.order_move([m], cell)
	return m if run(b, 30.0, func(): return m.on_wall and near(m.pos, cell)) else null

# 움직이지도 치지도 않는 과녁
func _dummy(b, cell: Vector2i):
	return b.spawn_enemy("basic", cell, {"speed": 0, "sight": 0, "damage": 0, "hp": BIG})

# EV89 · I44: 마을에서는 성문이 닫혀 있어도 성벽에 오른다
func ev89():
	var b = _battle()
	var m = b.place_merc("soldier", IN)
	b.order_move([m], TOP)
	var ok := run(b, 30.0, func(): return m.on_wall and near(m.pos, TOP))
	if b.castle.values().any(func(k): return k.open):
		return "열린 성문이 있다"
	return check(ok, "성벽에 오르지 못했다(%s, 성벽 위 %s)" % [m.pos, m.on_wall])

# EV90 · I44: 들판에서는 열린 성문으로 마을에 들어와야 오른다
func ev90():
	var b = _battle()
	var m = b.place_merc("soldier", OUT)
	b.order_move([m], TOP)
	run(b, 20.0)
	if m.on_wall or m.pos.y < MAIN.y + 0.5:
		return "성문이 닫혔는데 성곽을 넘었다(%s, 성벽 위 %s)" % [m.pos, m.on_wall]
	b.set_gate(b.castle[MAIN], true)
	b.order_move([m], TOP)
	return check(run(b, 30.0, func(): return m.on_wall and near(m.pos, TOP)), "정문을 열어도 오르지 못했다(%s, 성벽 위 %s)" % [m.pos, m.on_wall])

# EV91 · I69: 성벽 위에서 들판 칸으로 보내면 내려와 열린 성문으로 나간다
func ev91():
	var b = _battle()
	var m = _up(b, "soldier", TOP)
	if m == null:
		return "성벽에 오르지 못했다"
	b.set_gate(b.castle[MAIN], true)
	b.order_move([m], OUT)
	return check(run(b, 30.0, func(): return not m.on_wall and near(m.pos, OUT)), "들판으로 나가지 못했다(%s, 성벽 위 %s)" % [m.pos, m.on_wall])

# EV92 · S42: 성벽 위 궁수는 사거리 안 들판 적을 친다
func ev92():
	var b = _battle()
	var a = _up(b, "archer", TOP)
	if a == null:
		return "궁수가 성벽에 오르지 못했다"
	var e = _dummy(b, TOP + Vector2i(0, 3))
	if a.range < 3.0:
		return "궁수 사거리 %s로는 3칸 앞 과녁에 닿지 않는다" % a.range
	return check(run(b, 5.0, func(): return e.hp < e.max_hp), "성벽 위 궁수가 들판 적을 치지 않았다")

# EV93 · S88: 성벽 위 근접 용병은 바로 아래 적을 치지 않고 내려가지도 않는다
func ev93():
	var b = _battle()
	var m = _up(b, "soldier", TOP)
	if m == null:
		return "성벽에 오르지 못했다"
	if m.range >= 2.0:
		return "용병 사거리가 %s다(2 미만이어야 한다)" % m.range
	var e = _dummy(b, TOP + Vector2i(0, 1))
	run(b, 5.0)
	return check(e.hp == e.max_hp and m.on_wall and near(m.pos, TOP), "적 체력 %s/%s, 용병 %s(성벽 위 %s)" % [e.hp, e.max_hp, m.pos, m.on_wall])

# EV94 · I70: 적은 인식 범위 안의 성벽 위 용병을 노리지 않는다
func ev94():
	var b = _battle()
	var m = _up(b, "soldier", MAIN + Vector2i(-2, 0))
	if m == null:
		return "성벽에 오르지 못했다"
	b.set_gate(b.castle[MAIN], true)
	var e = b.spawn_enemy("basic", Vector2i(15, 19), {"sight": 5})
	if not run(b, 60.0, func(): return b.base.hp < b.base.max_hp):
		return "적이 거점을 치지 못했다(적 %s)" % e.pos
	return check(m.hp == m.max_hp, "성벽 위 용병이 맞았다(%s/%s)" % [m.hp, m.max_hp])

# EV95 · S89: 열린 정문 위 용병은 길을 막고 적과 싸운다. 적은 쓰러뜨린 뒤 지나간다
func ev95():
	var b = _battle()
	var m = _up(b, "soldier", MAIN)
	if m == null:
		return "정문 위에 오르지 못했다"
	b.set_gate(b.castle[MAIN], true)
	var e = b.spawn_enemy("basic", Vector2i(15, 19), {"hp": BIG})
	var t := 0.0
	while m.alive and t < 120.0:
		run(b, DT)
		t += DT
		if e.pos.y < MAIN.y - 0.5:
			return "정문 위 용병이 살아 있는데 적이 지나갔다(%s)" % e.pos
	if m.alive:
		return "적이 정문 위 용병을 쓰러뜨리지 못했다(용병 체력 %s)" % m.hp
	if e.hp == e.max_hp:
		return "정문 위 용병이 적을 치지 않았다"
	return check(run(b, 60.0, func(): return b.base.hp < b.base.max_hp), "용병을 쓰러뜨린 적이 거점을 치지 못했다(%s)" % e.pos)

# EV96 · I70: 선 칸이 부서지면 그 칸 땅으로 내려온다
func ev96():
	var b = _battle()
	var m = _up(b, "soldier", TOP)
	if m == null:
		return "성벽에 오르지 못했다"
	b.damage(b.castle[TOP], BIG)
	run(b, 0.5)
	return check(m.alive and not m.on_wall and near(m.pos, TOP), "칸이 부서진 뒤 용병 %s, 성벽 위 %s, 살아 있음 %s" % [m.pos, m.on_wall, m.alive])

# EV97 · S87: 병영에서 궁수를 산다. 종류를 비우면 용병이다
func ev97():
	var b = _battle()
	var f = b.build("barracks", Vector2i(20, 4))
	_start(b)
	var gold0: int = b.gold
	var a = b.recruit(f, "archer")
	if a == null or a.kind != "archer" or a.range < 2.0:
		return "궁수를 사지 못했다(%s)" % a
	if b.gold != gold0 - b.MERC_KINDS.archer.cost:
		return "골드 %d → %d(궁수 값 %d)" % [gold0, b.gold, b.MERC_KINDS.archer.cost]
	var s = b.recruit(f)
	return check(s != null and s.kind == "soldier", "종류 없이 산 용병이 %s다" % (s.kind if s else "없음"))
