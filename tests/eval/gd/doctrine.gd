extends "res://tests/eval/gd/lib.gd"
# 용병 교리(S36 2026-11-17 변경): leash·복귀(I36 변경)·반응·후퇴·주둔 깃발·성벽 위 자리. lib.gd·merc.gd 머리의 API에 더하는 것:
#   용병 overrides leash(쫓는 거리, 0이면 sight) · Unit.retreat · Unit.fleeing · Unit.flag_at · Unit.anchor
#   Battle.set_retreat(용병들, on) · Battle.plant_flag(유닛들, 칸) → bool · Battle.flags(깃발 칸 배열) · Battle.FLAG_CAP
#   Battle.RETURN_DELAY · RETREAT_AT · RETREAT_BACK · RETREAT_TIMEOUT · Controls: T 키(후퇴 전환) · D 키(깃발 칸 고르기) · controls.flagging

const W := [{"kind": "basic", "count": 1}]
const ANCHOR := Vector2i(10, 10)

# 준비 단계 판(용병·구조물은 준비 단계에 놓는다)
func _board(over := {}):
	var st := {"waves": [W], "base_hp": BIG}
	st.merge(over, true)
	return battle(st)

# 전투 단계를 연다: 웨이브 적 하나는 바로 치우고 구석의 멈춘 적이 전투 단계를 잇는다
func _fight(b) -> void:
	b.start_battle()
	b.step(DT)
	kill_all(b)
	b.spawn_enemy("basic", Vector2i(29, 19), {"speed": 0, "sight": 0, "damage": 0, "hp": BIG})

func _dummy(b, cell: Vector2i, over := {}):
	return b.spawn_enemy("basic", cell, {"speed": 0, "sight": 0, "damage": 0, "hp": BIG}.merged(over, true))

# EV1183 · I36 2026-11-17 변경: 홀드가 꺼진 용병은 기준 지점에서 leash(이 판 3칸) 밖의 적은 쫓지 않고 그 자리에 선다. leash가 0이면 인식 범위가 leash다
func ev1183():
	var b = _board()
	var m = b.place_merc("soldier", ANCHOR, {"sight": 10, "leash": 3.0})
	_fight(b)
	_dummy(b, ANCHOR + Vector2i(7, 0))
	var far := [0.0]
	run(b, 6.0, func():
		far[0] = maxf(far[0], m.pos.distance_to(Vector2(ANCHOR)))
		return false)
	var c = _board()
	c.place_merc("soldier", ANCHOR, {"sight": 10})
	_fight(c)
	var e = _dummy(c, ANCHOR + Vector2i(7, 0))
	var reached := run(c, 6.0, func(): return e.hp < e.max_hp)
	return check(far[0] <= 0.3 and reached, "leash 3: 7칸 앞 적에게 가지 않아 기준 지점에서 가장 멀리 %.2f칸(0.3 이하) · leash 0(인식 범위 10): 7칸 앞 적을 쳤다 %s" % [far[0], reached])

# EV1184 · I36 2026-11-17 변경: 적을 쫓아가 쓰러뜨린 용병은 적이 없는 채 RETURN_DELAY(8초)가 지나면 기준 지점으로 돌아와 선다(7초에는 아직 그 자리, 10초 안에 0.5칸 안)
func ev1184():
	var b = _board()
	var m = b.place_merc("soldier", ANCHOR, {"sight": 10})
	_fight(b)
	var e = _dummy(b, ANCHOR + Vector2i(4, 0), {"hp": 1.0})
	if not run(b, 6.0, func(): return not e.alive):
		return "적을 쓰러뜨리지 않았다"
	var at: Vector2 = m.pos
	run(b, 7.0)
	var stayed: bool = m.pos.distance_to(at) < 0.3
	var back := run(b, 4.0, func(): return m.pos.distance_to(Vector2(ANCHOR)) <= 0.5)
	return check(at.distance_to(Vector2(ANCHOR)) > 2.0 and stayed and back, "쓰러뜨린 자리 %s(기준에서 2칸 넘게) · 7초 뒤 그대로 %s · 11초 안에 기준 지점 0.5칸 안 %s(%s)" % [at, stayed, back, m.pos])

# EV1185 · S36 2026-11-17 변경(반응): 홀드 반경 2 안에서 버티는 병사도, 2칸 안의 아군을 치는 적이면 반경 밖 1칸까지 나가 친다. 그보다 먼 적은 치지 않는다
func ev1185():
	var out := []
	for dx in [3, 5]:
		var b = _board()
		var a = b.place_merc("soldier", ANCHOR, {"sight": 10, "hold_radius": 2.0, "damage": 1.0})
		var ally = b.place_merc("soldier", ANCHOR + Vector2i(1, 0), {"sight": 0, "damage": 0.0})
		b.set_hold([a], true)
		_fight(b)
		var e = _dummy(b, ANCHOR + Vector2i(dx, 0), {"damage": 1.0, "sight": 3.0, "attack_gap": 100.0})
		e.target = ally  # 적이 옆 아군을 노린다
		run(b, 4.0, func():
			e.target = ally
			return e.hp < e.max_hp)
		out.append([e.hp < e.max_hp, snappedf(a.pos.distance_to(Vector2(ANCHOR)), 0.01)])
	return check(out[0][0] and out[0][1] <= 3.05 and not out[1][0] and out[1][1] <= 2.05,
		"[맞음, 기준에서 거리] 3칸 적 %s(맞음·3 이하) · 5칸 적 %s(안 맞음·2 이하)" % [out[0], out[1]])

# EV1186 · S36 2026-11-17 변경(후퇴): 후퇴를 켠 용병은 체력이 30% 밑이면 가장 가까운 피난처(교회 둘레)로 치지 않고 물러나고, 60% 위로 차면 후퇴 전 자리로 돌아온다.
#   차지 않아도 시한이 지나면 돌아오고, 후퇴를 끄면 그 자리에서 다시 싸운다
func ev1186():
	var b = _board({"village": Rect2i(0, 0, 30, 6)})
	var ch = b.build("church", Vector2i(20, 2))
	if ch == null:
		return "교회를 짓지 못했다"
	var m = b.place_merc("soldier", ANCHOR, {"sight": 10, "hp": 50.0})
	b.set_retreat([m], true)
	m.hp = 10.0  # 전투 단계 첫 판정(0.5초)에 물러나게 미리 깎아 둔다
	_fight(b)
	var e = _dummy(b, ANCHOR + Vector2i(0, 4))  # 교회(위쪽)와 반대쪽: 물러나는 길·돌아오는 길에 끼지 않는다
	var fled := run(b, 1.0, func(): return m.fleeing and not m.path.is_empty())
	var church := Vector2(b.middle(ch))
	var d0: float = m.pos.distance_to(church)
	run(b, 3.0)
	var nearer: bool = m.pos.distance_to(church) < d0 - 2.0 and e.hp == e.max_hp
	m.hp = 40.0
	var back := run(b, 12.0, func(): return not m.fleeing and m.pos.distance_to(Vector2(ANCHOR)) <= 0.6)
	var c = _board({"village": Rect2i(0, 0, 30, 6)})
	c.build("church", Vector2i(20, 2))
	var n = c.place_merc("soldier", ANCHOR, {"sight": 10, "hp": 50.0})
	c.set_retreat([n], true)
	n.hp = 10.0
	_fight(c)
	run(c, 1.0)
	n.flee_left = 1.0
	var timed := run(c, 2.0, func(): return not n.fleeing)
	c.set_retreat([n], false)
	var off: bool = not n.fleeing and not n.retreat
	return check(fled and nearer and back and timed and off,
		"30%%에 물러남 %s · 3초 뒤 교회 쪽으로 2칸 넘게·적은 그대로 %s · 60%%에 돌아옴 %s(%s) · 시한 뒤 돌아옴 %s · 끄면 후퇴 해제 %s" % [fled, nearer, back, m.pos, timed, off])

# EV1187 · S36 2026-11-17 변경(주둔 깃발): 고른 용병 넷을 칸에 배속하면 깃발이 생기고 넷이 그 둘레 대열(2칸 안)에 서며 flag_at이 그 칸이다.
#   깃발은 FLAG_CAP(6)개까지다. 직접 이동 명령을 받은 용병은 배속이 풀리고, 배속이 없어진 깃발은 사라진다
func ev1187():
	var b = _board()
	var team := []
	for i in 4:
		team.append(b.place_merc("soldier", Vector2i(3 + i, 15)))
	var extra := []
	for i in 7:
		extra.append(b.place_merc("soldier", Vector2i(3, 2 + i)))
	_fight(b)
	var cell := Vector2i(12, 12)
	var planted: bool = b.plant_flag(team, cell) and cell in b.flags and team.all(func(u): return u.flag_at == cell)
	var stood := run(b, 15.0, func(): return team.all(func(u): return u.path.is_empty() and u.pos.distance_to(Vector2(cell)) <= 2.2))
	var more := [cell]
	for i in 7:
		var at := Vector2i(20 + i, 3)
		if b.plant_flag([extra[i]], at):
			more.append(at)
	var capped: bool = b.flags.size() == b.FLAG_CAP and more.size() == b.FLAG_CAP
	b.order_move(team, Vector2i(5, 18))
	run(b, 0.6)
	var freed: bool = team.all(func(u): return u.flag_at == b.NO_POST) and cell not in b.flags
	return check(planted and stood and capped and freed, "배속 %s · 15초 안에 깃발 2.2칸 안 대열 %s · 6개 상한 %s(%d) · 직접 명령에 풀림·빈 깃발 사라짐 %s" % [planted, stood, capped, b.flags.size(), freed])

# EV1188 · S36 2026-11-17 변경(성벽 위 자리): 15열이 성곽(성문 (15,10)·(15,5))인 판에서 성곽 안쪽 칸 (17,10)에 궁수 둘·병사 둘을 배속하면 궁수 둘은 성벽 위 칸에 서고 병사 둘은 땅의 깃발 둘레에 선다
func ev1188():
	var walls := []
	for y in 20:
		if y != 10 and y != 5:
			walls.append(Vector2i(15, y))
	var b = _board({"castle": {"walls": walls, "gates": [Vector2i(15, 10), Vector2i(15, 5)], "wall_hp": 300, "gate_hp": 150}, "village": Rect2i(16, 0, 14, 20), "spawns": [Vector2i(0, 10)]})
	b.set_gate(b.castle[Vector2i(15, 10)], true)
	var archers := [b.place_merc("archer", Vector2i(20, 12)), b.place_merc("archer", Vector2i(21, 12))]
	var soldiers := [b.place_merc("soldier", Vector2i(20, 14)), b.place_merc("soldier", Vector2i(21, 14))]
	if archers.has(null) or soldiers.has(null):
		return "용병을 놓지 못했다"
	_fight(b)
	var cell := Vector2i(17, 10)
	if not b.plant_flag(archers + soldiers, cell):
		return "깃발을 세우지 못했다"
	var up := run(b, 30.0, func(): return archers.all(func(u): return u.on_wall and u.path.is_empty()) and soldiers.all(func(u): return u.path.is_empty()))
	var ground: bool = soldiers.all(func(u): return not u.on_wall and u.pos.distance_to(Vector2(cell)) <= 2.2)
	return check(up and ground, "30초 안에 궁수 둘 성벽 위 %s(%s) · 병사 둘 땅의 깃발 둘레 %s(%s)" % [up, archers.map(func(u): return [u.on_wall, u.pos]), ground, soldiers.map(func(u): return u.pos)])

# EV1189 · S36 2026-11-17 변경(조작): 용병을 고르고 T를 누르면 후퇴 교리가 켜지고 다시 누르면 꺼진다. D를 누르고 땅을 좌클릭하면 그 칸에 깃발이 선다. 영웅만 골랐으면 D는 아무 일도 하지 않는다
func ev1189():
	var b = battle({"hero_start": Vector2i(20, 5)})
	var c = controls(b)
	var m = b.place_merc("soldier", Vector2i(10, 10))
	c.selected = [m]
	var ev := InputEventKey.new()
	ev.keycode = KEY_T
	ev.pressed = true
	c.handle(ev)
	var on: bool = m.retreat
	c.handle(ev)
	var off: bool = not m.retreat
	var ev2 := InputEventKey.new()
	ev2.keycode = KEY_D
	ev2.pressed = true
	c.handle(ev2)
	var arming: bool = c.flagging
	click(c, MOUSE_BUTTON_LEFT, px(Vector2i(14, 10)))
	var planted: bool = not c.flagging and Vector2i(14, 10) in b.flags and m.flag_at == Vector2i(14, 10)
	c.selected = [b.hero]
	c.handle(ev2)
	return check(on and off and arming and planted and not c.flagging, "T 켬 %s · T 끔 %s · D 고르기 %s · 클릭 칸에 깃발 %s · 영웅만 고른 D %s(false)" % [on, off, arming, planted, c.flagging])
