extends "res://tests/eval/gd/lib.gd"
# 3라운드 고블린 약탈단 묶음 ①: 일반 적 예고(S279), 폭파병(S280), 공성 망치(S281·I217·I218), 투석기(S282·I216·I219), 글라이더(S283·I220).
# lib.gd·boss.gd 머리의 계약에 더하는 API:
#   적 kind "sapper"(폭파병) · "ram"(공성 망치) · "catapult"(투석기) · "glider"(글라이더 고블린) · 적 flying(지금 비행 적인가)
#   적 cast(예고 중인 행동, 없으면 null): 폭파병 도화선 {id "fuse", left} · 투석기 던지기 {id "throw", left, at(원 가운데)}
#   기절·봉인은 적 fx에 직접 넣어 건다(boss.gd와 같다) · Battle.effect(대상, 키) · Battle.damage(대상, 양, kind)
#   Battle round_index · castle(칸 → 성곽) · next_round() · stage 키 rounds·castle·village · 용병 pos·anchor·on_wall

const GATE := Vector2i(12, 9)
const QUIET := {"damage": 0, "range": 0, "sight": 0}  # 치지도 쫓지도 않는 병사

# 9행 성곽(성문은 GATE 하나, 나머지 열은 성벽), 마을 0~8행, 거점 (12,2). 라운드 셋을 두고 1·2라운드를 넘겨
# 3라운드 준비 단계로 간다. 땅 적이 성문을 먼저 노리는 것(S143)은 3라운드부터다. 못 가면 null
func _siege(rows := 20):
	var walls := []
	for x in 30:
		if x != GATE.x:
			walls.append(Vector2i(x, 9))
	var w := [[{"kind": "basic", "count": 1}]]
	var b = battle({"size": Vector2i(30, rows), "base": Vector2i(12, 2), "base_hp": BIG, "spawns": [Vector2i(12, rows - 1)],
		"village": Rect2i(0, 0, 30, 9), "castle": {"walls": walls, "gates": [GATE], "wall_hp": 300, "gate_hp": 150}, "rounds": [w, w, w]})
	for i in 2:
		b.start_battle()
		if not clear_wave(b) or not b.next_round():
			return null
	return b if b.round_index == 2 and b.state == "prep" else null

# 9행 성곽(성문 (0,9)), 마을 0~8행, 거점 (12,2)인 1라운드 판
func _fort():
	var walls := []
	for x in range(1, 30):
		walls.append(Vector2i(x, 9))
	return battle({"base": Vector2i(12, 2), "spawns": [Vector2i(12, 19)], "village": Rect2i(0, 0, 30, 9), "base_hp": BIG,
		"castle": {"walls": walls, "gates": [Vector2i(0, 9)], "wall_hp": 300, "gate_hp": 150}})

func _need(b, kind: String) -> String:
	if b == null:
		return "3라운드 준비 단계로 가지 못했다"
	return "" if b.ENEMY_KINDS.has(kind) else "적 종류 %s가 없다" % kind

func _casting(e, id: String) -> bool:
	return e.cast != null and e.cast.get("id") == id

# EV669 · S279: 투석기 던지기 예고 중 기절이면 꺼지고 비틀거리지 않으며, 대기 시간이 처음부터 다시 돈다. 봉인 중엔 시작하지 않는다
func ev669():
	var b = battle({"base_hp": BIG})
	var why := _need(b, "catapult")
	if why != "":
		return why
	var c = b.spawn_enemy("catapult", Vector2i(0, 10), {"hp": BIG})
	if not run(b, 30.0, func(): return _casting(c, "throw")):
		return "30초 안에 던지기 예고를 시작하지 않았다(자리 %s)" % c.pos
	var gap: float = c.pos.distance_to(Vector2(b.base.cell))
	run(b, 0.5)
	c.fx["test_stun"] = {"stun": true, "left": 0.5}
	b.step(DT)
	var off: bool = c.cast == null
	var reel: bool = b.effect(c, "expose") != null
	var hp0: float = b.base.hp
	var waited := 0.0
	var kept := true
	while waited < 7.0 and c.cast == null:
		b.step(DT)
		waited += DT
		if waited <= 1.5 + 0.001:
			kept = kept and b.base.hp == hp0
	var d = battle({"base_hp": BIG})
	var s = d.spawn_enemy("catapult", Vector2i(0, 10), {"hp": BIG})
	s.fx["test_seal"] = {"seal": true, "left": 30.0}
	var quiet := not run(d, 20.0, func(): return s.cast != null)
	return check(gap <= 11.01 and off and not reel and kept and waited >= 5.8 and waited <= 6.3 and quiet,
		"멈춘 거리 %.2f · 기절에 꺼짐 %s · 비틀거림 %s · 1.5초 거점 그대로 %s · 다음 예고까지 %.2f초(5.8~6.3) · 봉인 20초 예고 없음 %s" % [gap, off, reel, kept, waited, quiet])

# EV671 · S280: 폭파병은 인식 범위의 병사를 치지 않고 성문 앞에서 3초 도화선을 켜고, 터지면 성문 −80·곁 병사 −30, 자기는 보상 없이 죽는다
func ev671():
	var b = _siege()
	var why := _need(b, "sapper")
	if why != "":
		return why
	var side = b.place_merc("soldier", Vector2i(10, 13), QUIET.merged({"hp": 100}))
	var by = b.place_merc("soldier", Vector2i(13, 10), QUIET.merged({"hp": 100}))
	var s = b.spawn_enemy("sapper", Vector2i(12, 16), {"sight": 3})
	var gold0: int = b.gold
	if not run(b, 10.0, func(): return _casting(s, "fuse")):
		return "10초 안에 도화선을 켜지 않았다(자리 %s · 병사 체력 %s)" % [s.pos, side.hp]
	var at: Vector2 = s.pos
	var g = b.castle[GATE]
	var hp0: float = g.hp
	run(b, 2.9)
	var held: bool = g.hp == hp0 and s.alive and s.pos.distance_to(at) < 0.01
	run(b, 0.2)
	return check(at.distance_to(Vector2(12, 10)) <= 0.5 and held and is_equal_approx(hp0 - g.hp, 80.0) and not s.alive and b.gold == gold0
		and is_equal_approx(by.hp, 70.0) and side.hp == 100.0,
		"켠 자리 %s · 2.9초 그대로 %s · 성문 %.1f→%.1f · 폭파병 살아 있음 %s · 골드 %d→%d · 곁 병사 %.1f · 길 옆 병사 %.1f" % [
			at, held, hp0, g.hp, s.alive, gold0, b.gold, by.hp, side.hp])

# EV672 · S280: 도화선 중 죽으면 터지지 않는다. 기절로 꺼지면 비틀거리지 않고, 풀린 뒤 처음부터 다시 켠다
func ev672():
	var b = _siege()
	var why := _need(b, "sapper")
	if why != "":
		return why
	var s = b.spawn_enemy("sapper", Vector2i(12, 16))
	if not run(b, 10.0, func(): return _casting(s, "fuse")):
		return "10초 안에 도화선을 켜지 않았다(자리 %s)" % s.pos
	var g = b.castle[GATE]
	var hp0: float = g.hp
	b.damage(s, BIG)
	run(b, 3.5)
	var dud: bool = g.hp == hp0
	var c = _siege()
	if c == null:
		return "둘째 판: 3라운드 준비 단계로 가지 못했다"
	var t = c.spawn_enemy("sapper", Vector2i(12, 16))
	if not run(c, 10.0, func(): return _casting(t, "fuse")):
		return "둘째 판: 10초 안에 도화선을 켜지 않았다(자리 %s)" % t.pos
	var h = c.castle[GATE]
	var hp1: float = h.hp
	run(c, 1.0)
	t.fx["test_stun"] = {"stun": true, "left": 1.0}
	c.step(DT)
	var off: bool = t.cast == null
	var reel: bool = c.effect(t, "expose") != null
	run(c, 4.8 - 1.0 - DT)
	var still: bool = h.hp == hp1
	var relit: bool = _casting(t, "fuse")
	run(c, 0.4)
	return check(dud and off and not reel and still and relit and is_equal_approx(hp1 - h.hp, 80.0),
		"죽인 뒤 성문 그대로 %s · 기절에 꺼짐 %s · 비틀거림 %s · 4.8초 성문 그대로 %s · 다시 켬 %s · 5.2초 성문 %.1f→%.1f" % [dud, off, reel, still, relit, hp1, h.hp])

# EV673 · S281·I218: 공성 망치는 길 위 병사에 막히지 않고 밀어내며 지나가 성문을 친다. 병사는 다치지 않는다
func ev673():
	var b = _siege()
	var why := _need(b, "ram")
	if why != "":
		return why
	var m = b.place_merc("soldier", Vector2i(12, 13), QUIET.merged({"hp": 100}))
	var r = b.spawn_enemy("ram", Vector2i(12, 17), {"sight": 3, "hp": BIG})
	var g = b.castle[GATE]
	var pushed := [0.0]
	var hit := run(b, 15.0, func():
		pushed[0] = maxf(pushed[0], m.pos.distance_to(Vector2(12, 13)))
		return g.hp < g.max_hp)
	return check(hit and pushed[0] > 0.4 and m.hp == 100.0,
		"15초 안에 성문을 침 %s(망치 %s) · 병사가 밀린 거리 최대 %.2f · 병사 체력 %.1f" % [hit, r.pos, pushed[0], m.hp])

# EV674 · I217·S281: 공성 망치는 타워 화살을 30%만 받고, 투사체가 아닌 물리·마법은 그대로 받는다. 봉인되면 화살도 그대로 받는다
func ev674():
	var b = battle({"base_hp": BIG})
	var why := _need(b, "ram")
	if why != "":
		return why
	b.build("tower", Vector2i(10, 7), {"range": 8, "damage": 10})
	var r = b.spawn_enemy("ram", Vector2i(2, 10), {"hp": BIG})
	var h0: float = r.hp
	if not run(b, 20.0, func(): return r.hp < h0):
		return "20초 안에 타워가 망치를 맞히지 않았다(망치 %s)" % r.pos
	var arrow: float = h0 - r.hp
	var h1: float = r.hp
	b.damage(r, 10.0)
	var phys: float = h1 - r.hp
	var h2: float = r.hp
	b.damage(r, 10.0, "magic")
	var magic: float = h2 - r.hp
	r.fx["test_seal"] = {"seal": true, "left": 30.0}
	var h3: float = r.hp
	if not run(b, 5.0, func(): return r.hp < h3):
		return "봉인 뒤 5초 안에 타워가 망치를 맞히지 않았다(망치 %s)" % r.pos
	var sealed: float = h3 - r.hp
	return check(is_equal_approx(arrow, 3.0) and is_equal_approx(phys, 10.0) and is_equal_approx(magic, 10.0) and is_equal_approx(sealed, 10.0),
		"화살 %.2f(3) · 물리 %.2f(10) · 마법 %.2f(10) · 봉인 중 화살 %.2f(10)" % [arrow, phys, magic, sealed])

# EV675 · S282·I216·I219: 투석기는 성문에서 11칸 안에 들면 멈춰 성문 칸에 1.5초 원 예고를 띄우고, 끝에 성문 −40·성문 위 병사 −15
func ev675():
	var b = _siege(32)
	var why := _need(b, "catapult")
	if why != "":
		return why
	var top = b.place_merc("soldier", Vector2i(12, 5), QUIET.merged({"hp": 100}))
	top.pos = Vector2(GATE)
	top.anchor = Vector2(GATE)
	top.on_wall = true
	var c = b.spawn_enemy("catapult", Vector2i(12, 28), {"hp": BIG})
	if not run(b, 15.0, func(): return _casting(c, "throw")):
		return "15초 안에 던지기 예고를 시작하지 않았다(자리 %s)" % c.pos
	var gap: float = c.pos.distance_to(Vector2(GATE))
	var aim = c.cast.get("at")
	var g = b.castle[GATE]
	var hp0: float = g.hp
	run(b, 1.4)
	var early: bool = g.hp == hp0 and top.hp == 100.0
	run(b, 0.2)
	return check(gap >= 10.5 and gap <= 11.01 and aim != null and Vector2(aim).distance_to(Vector2(GATE)) < 0.01 and early
		and is_equal_approx(hp0 - g.hp, 40.0) and is_equal_approx(top.hp, 85.0),
		"멈춘 거리 %.2f(10.5~11) · 원 가운데 %s · 1.4초 그대로 %s · 성문 %.1f→%.1f · 성문 위 병사 %.1f" % [gap, aim, early, hp0, g.hp, top.hp])

# EV676 · S283·I220: 글라이더는 날아서 성벽을 넘고 마을에 들어선 뒤 3칸 더 가서 내려 땅 적이 된다. 날다가 봉인되면 그 자리에 내리고 다시 날지 않는다
func ev676():
	var b = _fort()
	var why := _need(b, "glider")
	if why != "":
		return why
	var gl = b.spawn_enemy("glider", Vector2i(12, 16), {"hp": BIG, "sight": 0})
	if not gl.flying:
		return "나올 때 날고 있지 않다"
	if not run(b, 15.0, func(): return not gl.flying):
		return "15초 안에 내려앉지 않았다(자리 %s)" % gl.pos
	var at: Vector2 = gl.pos
	var m = b.place_merc("soldier", Vector2i(12, 4), QUIET.merged({"hp": BIG}))
	var struck := run(b, 5.0, func(): return m.hp < m.max_hp)
	var d = _fort()
	var f = d.spawn_enemy("glider", Vector2i(12, 18), {"hp": BIG, "sight": 0})
	run(d, 1.0)
	f.fx["test_seal"] = {"seal": true, "left": 1.0}
	d.step(DT)
	var down: bool = not f.flying
	var spot: Vector2 = f.pos
	run(d, 2.0)
	return check(at.y >= 5.0 and at.y <= 6.0 and absf(at.x - 12.0) < 0.5 and struck and down and spot.y > 9.0 and not f.flying,
		"내린 자리 %s(y 5~6) · 앞 병사를 침 %s · 봉인에 내림 %s(자리 %s) · 풀린 뒤 날지 않음 %s" % [at, struck, down, spot, not f.flying])
