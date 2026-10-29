extends "res://tests/eval/gd/lib.gd"
# WBS 3.3 시설 파괴·수리(S80·S114·S115·I85~I89). lib.gd·engineer.gd·wall.gd 머리의 계약에 더하는 API:
#   Battle.repair(구조물·성곽 칸·거점) — 깎인 것을 고친다. 준비 단계엔 바로, 전투 단계엔 공병이 간다
#   Battle.restore(성곽 칸) — 부서진 성곽 칸(잔해)을 되살린다. 부서지기 전에 쥐고 있던 성곽 칸 객체를 넘긴다
#   Battle.REPAIR_RATE — {"castle_wall", "gate", "base"} → 체력 1당 수리비(골드)
#   Battle.refund(대상) — 판매 환불(S69). 구조물 수리비는 «낸 골드 − 환불»이다(S114)
#   Battle.upgrade(성곽 칸) — 성곽 업그레이드(S86)
# 성곽 맵은 wall.gd와 같다: 9행이 가로 성곽(성문 5·15·25열, 모두 닫힘), 위쪽(0~8행)이 마을, 아래쪽이 들판

const T := Vector2i(12, 10)  # 기본 맵의 타워 칸
const TOP := Vector2i(12, 9)  # 성곽 맵의 성벽 칸
const GATES := [Vector2i(5, 9), Vector2i(15, 9), Vector2i(25, 9)]
const WAVES := [[{"kind": "basic", "count": 1}], [{"kind": "basic", "count": 1}]]

func _castle(over := {}):
	var walls := []
	for x in 30:
		if Vector2i(x, 9) not in GATES:
			walls.append(Vector2i(x, 9))
	var stage := {"base": Vector2i(15, 4), "spawns": [Vector2i(15, 19)], "village": Rect2i(0, 0, 30, 9), "base_hp": BIG,
		"castle": {"walls": walls, "gates": GATES, "wall_hp": 300, "gate_hp": 150}}
	stage.merge(over, true)
	return battle(stage)

# 전투 단계를 연다. 웨이브 적은 처치하고, 움직이지도 치지도 않는 적 하나를 구석에 남겨 전투 단계가 이어지게 한다
func _start(b):
	b.start_battle()
	run(b, 5.0, func(): return not b.enemies.is_empty())
	var idle = b.spawn_enemy("basic", Vector2i(0, 19), {"speed": 0, "sight": 0, "damage": 0})
	for x in b.enemies.duplicate():
		if x != idle:
			b.damage(x, BIG)
	return idle

func _intact(b) -> bool:
	return b.castle.values().all(func(k): return k.hp == k.max_hp)

# EV151 · S80: 준비 단계에 깎인 타워를 수리하면 체력이 가득 차고, 골드가 판매 환불의 나머지만큼 준다
func ev151():
	var b = battle()
	var t = b.build("tower", T)
	b.damage(t, t.max_hp / 2.0)
	var before: int = b.gold
	var owed: int = t.paid - b.refund(t)
	b.repair(t)
	return check(t.hp == t.max_hp and b.gold == before - owed, "체력 %s/%s · 골드 %d → %d(%d 줄어야 한다)" % [t.hp, t.max_hp, before, b.gold, owed])

# EV152 · S114: 성벽 칸·거점을 깎고 준비 단계에 수리하면 골드가 잃은 체력 × 각 단가만큼 준다
func ev152():
	var b = _castle()
	var k = b.castle[TOP]
	b.damage(k, 100.0)
	var g0: int = b.gold
	b.repair(k)
	var want_k := ceili(100.0 * b.REPAIR_RATE.castle_wall)
	if k.hp != k.max_hp or g0 - b.gold != want_k:
		return "성벽 칸: 체력 %s/%s · 낸 골드 %d(%d여야 한다)" % [k.hp, k.max_hp, g0 - b.gold, want_k]
	b.damage(b.base, 30.0)
	var g1: int = b.gold
	b.repair(b.base)
	var want_b := ceili(30.0 * b.REPAIR_RATE.base)
	return check(b.base.hp == b.base.max_hp and g1 - b.gold == want_b,
		"거점: 체력 %s/%s · 낸 골드 %d(%d여야 한다)" % [b.base.hp, b.base.max_hp, g1 - b.gold, want_b])

# EV153 · I86: 골드가 수리비보다 적으면 수리가 거부되고 체력·골드가 그대로다
func ev153():
	var b = battle()
	b.gold = b.STRUCTURE_KINDS.tower.cost + 5  # 짓고 나면 수리비보다 적게 남는다
	var t = b.build("tower", T)
	b.damage(t, t.max_hp * 0.9)
	var hp0: float = t.hp
	var g0: int = b.gold
	if g0 >= t.paid - b.refund(t):
		return "시험 조건이 틀렸다: 골드 %d가 수리비 %d보다 적어야 한다" % [g0, t.paid - b.refund(t)]
	b.repair(t)
	return check(t.hp == hp0 and b.gold == g0, "골드가 모자란데 체력 %s → %s · 골드 %d → %d" % [hp0, t.hp, g0, b.gold])

# EV154 · I88: 닫힌 성곽의 성벽 칸 하나를 부수면 적이 그 잔해 칸을 지나 거점에 닿고, 그 칸에는 타워를 짓지 못한다
func ev154():
	var b = _castle()
	b.damage(b.castle[TOP], BIG)
	if b.build("tower", TOP) != null:
		return "잔해 칸에 타워를 지었다"
	var e = b.spawn_enemy("basic", TOP + Vector2i(0, 4), {"hp": BIG, "sight": 0})
	var crossed := [false]
	if not run(b, 30.0, func():
		crossed[0] = crossed[0] or cell_of(e) == TOP
		return at_base(b, e)):
		return "적이 거점에 닿지 않았다(%s)" % e.pos
	return check(crossed[0] and _intact(b), "잔해 칸을 지났나 %s · 남은 성곽이 온전한가 %s" % [crossed[0], _intact(b)])

# EV155 · I89: 2단계 성벽 칸을 부순 뒤 준비 단계에 복구하면 골드가 복구비만큼 줄고 2단계 최대 체력으로 돌아온다
func ev155():
	var b = _castle()
	var k = b.castle[TOP]
	b.upgrade(k)
	if k.level != 2:
		return "업그레이드가 되지 않았다(단계 %d)" % k.level
	var top_hp: float = k.max_hp
	b.damage(k, BIG)
	var g0: int = b.gold
	b.restore(k)
	var want := ceili(top_hp * b.REPAIR_RATE.castle_wall)
	return check(b.castle.get(TOP) == k and k.level == 2 and k.hp == top_hp and g0 - b.gold == want,
		"복구 뒤 성곽 %s · 단계 %d · 체력 %s/%s · 낸 골드 %d(%d여야 한다)" % [b.castle.get(TOP), k.level, k.hp, top_hp, g0 - b.gold, want])

# EV156 · S115: 전투 중 수리는 지시하는 순간 수리비를 내고, 공병이 가서 시간이 지나며 가득 채운다. 공병이 없으면 거부된다
func ev156():
	var b = battle({"base_hp": BIG, "waves": WAVES})
	var t = b.build("tower", T)
	_start(b)
	b.damage(t, 60.0)
	var g0: int = b.gold
	b.repair(t)
	if b.gold != g0 or t.hp != t.max_hp - 60.0:
		return "공병이 없는데 수리를 받았다(골드 %d → %d, 체력 %s)" % [g0, b.gold, t.hp]
	b = battle({"base_hp": BIG, "waves": WAVES})
	t = b.build("tower", T)
	b.place_merc("engineer", T + Vector2i(0, 4))
	_start(b)
	b.damage(t, 60.0)
	g0 = b.gold
	var owed: int = t.paid - b.refund(t)
	b.repair(t)
	if g0 - b.gold != owed:
		return "지시할 때 낸 골드가 %d다(%d여야 한다)" % [g0 - b.gold, owed]
	if t.hp >= t.max_hp:
		return "공병이 가기도 전에 체력이 찼다"
	return check(run(b, 20.0, func(): return t.hp >= t.max_hp), "20초가 지나도 체력이 %s/%s다" % [t.hp, t.max_hp])

# EV157 · I87: 수리하던 공병에게 이동 지시를 하면 체력이 그 자리에서 멈추고, 다시 수리하면 골드 없이 마저 고친다
func ev157():
	var b = battle({"base_hp": BIG, "waves": WAVES})
	var t = b.build("tower", T)
	var eng = b.place_merc("engineer", T + Vector2i(0, 2))
	_start(b)
	b.damage(t, 80.0)
	var hurt: float = t.hp
	b.repair(t)
	if not run(b, 5.0, func(): return t.hp > hurt):
		return "공병이 고치기 시작하지 않았다"
	b.order_move([eng], Vector2i(2, 2))
	run(b, 0.5)
	var stopped: float = t.hp
	run(b, 2.0)
	if t.hp != stopped or t.hp >= t.max_hp:
		return "이동 지시 뒤에도 체력이 %s → %s로 바뀌었다" % [stopped, t.hp]
	var g0: int = b.gold
	b.repair(t)
	if b.gold != g0:
		return "이어 고치는데 골드가 %d → %d로 줄었다" % [g0, b.gold]
	return check(run(b, 20.0, func(): return t.hp >= t.max_hp), "이어 고쳐도 체력이 %s/%s다" % [t.hp, t.max_hp])

# EV158 · I89: 전투 중 복구는 지시하는 순간 복구비를 낸다. 공병이 닿기 전엔 잔해 그대로고, 닿은 뒤 성곽으로 다시 서서 가득 찬다.
# 공병이 없으면 거부된다
func ev158():
	var b = _castle({"waves": WAVES})
	var k = b.castle[TOP]
	_start(b)
	b.damage(k, BIG)
	var g0: int = b.gold
	b.restore(k)
	if b.gold != g0 or b.castle.has(TOP):
		return "공병이 없는데 복구를 받았다(골드 %d → %d)" % [g0, b.gold]
	b = _castle({"waves": WAVES})
	k = b.castle[TOP]
	b.place_merc("engineer", Vector2i(2, 2))
	_start(b)
	b.damage(k, BIG)
	g0 = b.gold
	b.restore(k)
	var want := ceili(k.max_hp * b.REPAIR_RATE.castle_wall)
	if g0 - b.gold != want:
		return "지시할 때 낸 골드가 %d다(%d여야 한다)" % [g0 - b.gold, want]
	run(b, 0.5)
	if b.castle.has(TOP):
		return "공병이 닿기도 전에 성곽이 섰다"
	if not run(b, 30.0, func(): return b.castle.get(TOP) == k):
		return "공병이 가도 성곽이 다시 서지 않았다"
	return check(run(b, 20.0, func(): return k.hp >= k.max_hp), "다시 선 성곽 체력이 %s/%s다" % [k.hp, k.max_hp])
