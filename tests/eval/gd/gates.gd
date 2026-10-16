extends "res://tests/eval/gd/lib.gd"
# 성문 쿨타임(S135). castle.gd 머리의 API에 더하는 것:
#   Battle.GATE_LOCK — 전투 단계에 여닫은 성문을 다시 여닫지 못하는 시간(초)
#   Battle.set_gate(성문, open) — 쿨타임 중인 성문에 낸 지시는 거부한다(성문이 그대로다)

const X := 15  # 성곽 열. 출현 지점(0,10)과 거점(25,10) 사이를 세로로 막는다
const A := Vector2i(X, 10)
const B := Vector2i(X, 5)

func _battle():
	var walls := []
	for y in 20:
		if y != A.y and y != B.y:
			walls.append(Vector2i(X, y))
	return battle({"castle": {"walls": walls, "gates": [A, B], "wall_hp": 300, "gate_hp": 150}, "base_hp": BIG,
		"waves": [[{"kind": "basic", "count": 1}], [{"kind": "basic", "count": 1}]]})

# 전투 단계를 연다. 웨이브 적은 바로 처치하고, 움직이지도 치지도 않는 적 하나를 구석에 남겨 전투 단계가 이어지게 한다(castle.gd와 같다)
func _start(b):
	b.start_battle()
	run(b, 5.0, func(): return not b.enemies.is_empty())
	var idle = b.spawn_enemy("basic", Vector2i(0, 19), {"speed": 0, "sight": 0, "damage": 0})
	for x in b.enemies.duplicate():
		if x != idle:
			b.damage(x, BIG)
	return idle

# EV222 · S135: 전투 단계에 연 성문은 GATE_LOCK(20초)이 지나야 닫히고, 닫자마자는 다시 열리지 않는다
func ev222():
	var b = _battle()
	if b.GATE_LOCK != 20.0:
		return "GATE_LOCK이 %s초다(S135는 20초)" % b.GATE_LOCK
	var g = b.castle[A]
	_start(b)
	b.set_gate(g, true)
	if not g.open:
		return "전투 단계 첫 열기가 거부됐다"
	run(b, b.GATE_LOCK - 0.5)
	b.set_gate(g, false)
	if not g.open:
		return "연 지 %s초 만에 닫혔다" % (b.GATE_LOCK - 0.5)
	run(b, 1.0)
	b.set_gate(g, false)
	if g.open:
		return "연 지 %s초가 지나도 닫히지 않는다" % (b.GATE_LOCK + 0.5)
	b.set_gate(g, true)
	return check(not g.open, "닫자마자 다시 열렸다")

# EV223 · S135: 준비 단계에는 쿨타임이 없다
func ev223():
	var b = _battle()
	var g = b.castle[A]
	for want in [true, false, true]:
		b.set_gate(g, want)
		if g.open != want:
			return "준비 단계 연속 여닫기에서 %s 지시가 거부됐다" % ("열기" if want else "닫기")
	_start(b)
	b.set_gate(g, false)
	return check(not g.open, "준비 단계에 연 성문을 전투 시작 직후 닫지 못했다")

# EV224 · S135: 쿨타임은 성문마다 따로 걸린다
func ev224():
	var b = _battle()
	var a = b.castle[A]
	var g = b.castle[B]
	_start(b)
	b.set_gate(a, true)
	b.set_gate(g, true)
	if not (a.open and g.open):
		return "전투 중 두 성문을 잇달아 열지 못했다(A %s, B %s)" % [a.open, g.open]
	b.set_gate(g, false)
	b.set_gate(a, false)
	return check(a.open and g.open, "쿨타임 중인 성문이 닫혔다(A 열림 %s, B 열림 %s)" % [a.open, g.open])

# EV225 · S135: 웨이브가 끝나면 남은 쿨타임은 사라진다
func ev225():
	var b = _battle()
	var g = b.castle[A]
	_start(b)
	b.set_gate(g, true)
	if not g.open:
		return "전투 중 열지 못했다"
	if not clear_wave(b) or b.state != "prep":
		return "1웨이브를 끝내지 못했다(%s)" % b.state
	_start(b)
	b.set_gate(g, false)
	return check(not g.open, "앞 웨이브의 쿨타임이 남아 다음 웨이브 첫 닫기가 거부됐다")

# EV226 · S135: 거부된 지시에는 쿨타임이 걸리지 않는다(적이 선 성문 닫기, I67)
func ev226():
	var b = _battle()
	var g = b.castle[A]
	b.set_gate(g, true)
	_start(b)
	var e = b.spawn_enemy("basic", A, {"speed": 0, "sight": 0, "damage": 0})
	b.set_gate(g, false)
	if not g.open:
		return "적이 선 성문이 닫혔다"
	b.damage(e, BIG)
	b.set_gate(g, false)
	return check(not g.open, "거부된 닫기 뒤에 쿨타임이 걸려 다시 닫지 못했다")

# EV235 · I133: 닫힌 성문 앞에서 기다리던 용병은 다른 성문이 열리면 그쪽으로 돌아가 목적지에 닿는다
func ev235():
	var b = _battle()
	var m = b.place_merc("soldier", Vector2i(10, 3))
	var goal := Vector2i(20, 3)
	b.order_move([m], goal)
	if run(b, 10.0, func(): return near(m.pos, goal)):
		return "성문이 모두 닫혔는데 10초 안에 목적지에 닿았다(%s)" % m.pos
	var other = b.castle[A] if m.pos.distance_to(Vector2(B)) < m.pos.distance_to(Vector2(A)) else b.castle[B]
	b.set_gate(other, true)
	return check(run(b, 30.0, func(): return near(m.pos, goal)), "%s 성문을 연 뒤 30초가 지나도 목적지에 닿지 못했다(%s)" % [other.cell, m.pos])
