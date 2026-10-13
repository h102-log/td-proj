extends "res://tests/eval/gd/lib.gd"
# WBS 2.20 성곽 ① 성문 여닫기·업그레이드(S39·S40·S85·S86·I67·I68). lib.gd·engineer.gd 머리의 계약에 더하는 API:
#   stage 키 castle: {walls: [칸], gates: [칸], wall_hp, gate_hp} · Battle.castle(칸 → 성곽 칸)
#   성곽 칸: kind("castle_wall"|"gate") · open(성문이 열렸나) · level(1부터) · hp · max_hp
#   Battle.set_gate(성문, open) — 성문을 열거나 닫는다. 성문 칸에 유닛·적이 있으면 닫기를 거부한다
#   Battle.upgrade(성곽 칸) — 준비 단계엔 바로 올리고, 전투 단계엔 놀고 있는 가장 가까운 공병을 보낸다. 거부되면 골드가 그대로다
#   Battle.upgrade_cost(성곽 칸) -> int
#   Controls.fort — 좌클릭으로 고른 성곽 칸
# 비용·배율·최고 단계는 판에서 읽거나 결과로 잰다. 수치가 임시값이라(S86) 밸런스를 바꿔도 이 평가가 깨지지 않게

const X := 15  # 성곽 열. 출현 지점(0,10)과 거점(25,10) 사이를 세로로 막는다
const GATE := Vector2i(X, 10)
const WALL := Vector2i(X, 5)
const WEST := Vector2i(10, 10)
const EAST := Vector2i(20, 10)

func _battle():
	var walls := []
	for y in 20:
		if y != GATE.y:
			walls.append(Vector2i(X, y))
	return battle({"castle": {"walls": walls, "gates": [GATE], "wall_hp": 300, "gate_hp": 150}, "base_hp": BIG,
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

# EV81 · S85: 성문은 닫힌 채 시작하고, 두 단계 모두 클릭으로 고르며, 지시대로 여닫힌다
func ev81():
	var b = _battle()
	var c = controls(b)
	var g = b.castle[GATE]
	if g.open:
		return "새 판의 성문이 열려 있다"
	click(c, MOUSE_BUTTON_LEFT, px(GATE))
	if c.fort != g or not c.selling.is_empty():
		return "준비 단계에 성문을 눌렀더니 고른 성곽 칸 %s, 판매 후보 %s" % [c.fort, c.selling]
	b.set_gate(g, true)
	if not g.open:
		return "열기 지시 뒤에도 닫혀 있다"
	_start(b)
	c.fort = null
	click(c, MOUSE_BUTTON_LEFT, px(GATE))
	if c.fort != g or not c.picked.is_empty():
		return "전투 단계에 성문을 눌렀더니 고른 성곽 칸 %s, 철거 후보 %s" % [c.fort, c.picked]
	b.set_gate(g, false)
	return check(not g.open, "닫기 지시 뒤에도 열려 있다")

# EV82 · S40: 열린 성문은 적이 부수지 않고 지나간다
func ev82():
	var b = _battle()
	var g = b.castle[GATE]
	b.set_gate(g, true)
	var e = b.spawn_enemy("basic", Vector2i(0, 10), {"sight": 0})
	if not run(b, 60.0, func(): return b.base.hp < b.base.max_hp):
		return "적이 거점을 치지 못했다(적 위치 %s)" % e.pos
	return check(g.hp == g.max_hp, "적이 열린 성문 체력을 깎았다(%s/%s)" % [g.hp, g.max_hp])

# EV83 · S39: 아군은 열린 성문으로만 성곽을 넘는다
func ev83():
	var b = _battle()
	var g = b.castle[GATE]
	var m = b.place_merc("soldier", WEST)
	b.order_move([m], EAST)
	run(b, 20.0)
	if m.pos.x >= X:
		return "닫힌 성문을 넘어갔다(%s)" % m.pos
	b.set_gate(g, true)
	b.order_move([m], EAST)
	return check(run(b, 20.0, func(): return near(m.pos, EAST)), "열린 성문으로 넘어가지 못했다(%s)" % m.pos)

# EV84 · I67: 성문 칸에 적이 있으면 닫히지 않는다
func ev84():
	var b = _battle()
	var g = b.castle[GATE]
	b.set_gate(g, true)
	b.spawn_enemy("basic", GATE, {"speed": 0, "sight": 0, "damage": 0})
	b.set_gate(g, false)
	return check(g.open, "적이 선 성문이 닫혔다")

# EV85 · S86: 준비 단계 업그레이드는 바로 오르고, 매번 같은 배율로 최대 체력이 늘며, 최고 단계에서 멈춘다
func ev85():
	var b = _battle()
	for cell in [WALL, GATE]:
		var k = b.castle[cell]
		var ratio := 0.0
		for i in 10:
			var gold0: int = b.gold
			var cost: int = b.upgrade_cost(k)
			var max0: float = k.max_hp
			var lv: int = k.level
			b.upgrade(k)
			if k.level == lv:  # 더 오르지 않는다: 최고 단계
				if lv < 2 or b.gold != gold0:
					return "%s: %d단계에서 멈췄고 골드가 %d → %d다" % [k.kind, lv, gold0, b.gold]
				break
			if k.level != lv + 1 or cost <= 0 or b.gold != gold0 - cost:
				return "%s %d단계 업그레이드: 단계 %d, 비용 %d, 골드 %d → %d" % [k.kind, lv, k.level, cost, gold0, b.gold]
			var r: float = k.max_hp / max0
			if r <= 1.0 or (ratio > 0.0 and not is_equal_approx(r, ratio)):
				return "%s %d단계 업그레이드: 최대 체력 배율 %s(앞 단계 %s)" % [k.kind, lv, r, ratio]
			ratio = r
		if ratio == 0.0 or k.level < 2:
			return "%s가 한 번도 오르지 않았다" % k.kind
	return ""

# EV86 · S86: 전투 중 업그레이드는 공병이 가서 올린다. 놀고 있는 공병이 없으면 거부된다
func ev86():
	var b = _battle()
	var k = b.castle[WALL]
	var e = b.place_merc("engineer", WALL + Vector2i(-3, 0))
	_start(b)
	var lv: int = k.level
	b.upgrade(k)
	if k.level != lv or e.job != k:
		return "지시 직후 단계 %d(전 %d), 공병이 맡은 일 %s" % [k.level, lv, e.job]
	var other = b.castle[WALL + Vector2i(0, 3)]
	var gold0: int = b.gold
	b.upgrade(other)
	if b.gold != gold0 or other.level != lv:
		return "놀고 있는 공병이 없는데 받아들였다(골드 %d → %d, 단계 %d)" % [gold0, b.gold, other.level]
	return check(run(b, 30.0, func(): return k.level == lv + 1), "공병이 올리지 못했다(단계 %d)" % k.level)

# EV87 · I68: 업그레이드해도 입은 피해는 그대로다
func ev87():
	var b = _battle()
	var k = b.castle[WALL]
	b.damage(k, 100)
	var lost: float = k.max_hp - k.hp
	var lv: int = k.level
	b.upgrade(k)
	if k.level != lv + 1:
		return "오르지 않았다"
	return check(is_equal_approx(k.max_hp - k.hp, lost), "입은 피해가 %s → %s다" % [lost, k.max_hp - k.hp])

# EV88 · I68: 그만둔 업그레이드는 골드를 더 내지 않고 이어 올린다
func ev88():
	var b = _battle()
	var k = b.castle[WALL]
	var e = b.place_merc("engineer", WALL + Vector2i(-3, 0))
	_start(b)
	var lv: int = k.level
	b.upgrade(k)
	if not run(b, 30.0, func(): return e.job == k and e.path.is_empty()):
		return "공병이 일하러 닿지 않았다"
	run(b, 1.0)
	b.order_move([e], WALL + Vector2i(-6, 0))
	run(b, 2.0)
	if k.level != lv or e.job != null:
		return "이동 지시 뒤 단계 %d(전 %d), 공병이 맡은 일 %s" % [k.level, lv, e.job]
	var gold0: int = b.gold
	b.upgrade(k)
	if b.gold != gold0:
		return "다시 업그레이드하니 골드가 %d → %d다" % [gold0, b.gold]
	return check(run(b, 30.0, func(): return k.level == lv + 1), "이어 올리지 못했다(단계 %d)" % k.level)
