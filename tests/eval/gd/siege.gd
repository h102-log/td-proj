extends "res://tests/eval/gd/lib.gd"
# 3라운드 고블린 약탈단 묶음 ①: 일반 적 예고(S279), 폭파병(S280), 공성 망치(S281·I217·I218), 투석기(S282·I216·I219), 글라이더(S283·I220).
# 불화살 고블린(S302·I216·I249).
# lib.gd·boss.gd 머리의 계약에 더하는 API:
#   적 kind "sapper"(폭파병) · "ram"(공성 망치) · "catapult"(투석기) · "glider"(글라이더 고블린) · "fire_archer"(불화살 고블린) · 적 flying(지금 비행 적인가)
#   적 cast(예고 중인 행동, 없으면 null): 폭파병 도화선 {id "fuse", left} · 투석기 던지기 {id "throw", left, at(원 가운데)} · 불화살 {id "flame", left, at(대상 구조물 칸 가운데, Vector2)}
#   불(S302)은 새 API 없이 구조물 체력으로 잰다. 끄기는 Battle.repair·set_auto_fix·공병 job, 숨은 예고는 BattleView tellers()·foes()·tell_color()(night.gd 머리)
#   적 행동·구조물 불은 준비 단계에도 돈다(투석기 EV669와 같은 시험 판 전제)
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

# ── 불화살 고블린(S302·I216·I249) ──

const FA := "fire_archer"
const FLAME := "flame"  # 불화살 예고의 cast id. 타워 사격(_fire)·기관총 cast.fire와 겹치지 않게 flame이다
const T0 := Vector2i(12, 6)  # (0,10)에서 거점 (25,10)으로 가는 불화살 고블린에게 처음 9칸 안에 드는 쏘는 구조물 칸. x≈3.94에서 든다
const WW := [[{"kind": "basic", "count": 1}], [{"kind": "basic", "count": 1}]]

# 전투 단계를 연다. 웨이브 적은 처치하고, 움직이지도 치지도 않는 적 하나를 구석 (0,19)에 남겨 전투 단계가 이어지게 한다
func _fight(b):
	b.start_battle()
	run(b, 5.0, func(): return not b.enemies.is_empty())
	var idle = b.spawn_enemy("basic", Vector2i(0, 19), {"speed": 0, "sight": 0, "damage": 0})
	for x in b.enemies.duplicate():
		if x != idle:
			b.damage(x, BIG)
	return idle

# 불화살 고블린(체력 큼)을 (0,10)에 내보내 타워 t가 처음 깎일 때까지 돌린다. 15초 안에 못 맞히면 null
func _lit(b, t):
	var f = b.spawn_enemy(FA, Vector2i(0, 10), {"hp": BIG})
	var hit := run(b, 15.0, func(): return t.hp < t.max_hp)
	return f if hit else null

func _about(x: float, want: float, tol := 0.5) -> bool:
	return absf(x - want) <= tol

# 불화살 예고의 at이 그 칸 가운데(Vector2)인가. at이 없거나 다른 꼴이면 false
func _aims(f, cell: Vector2i) -> bool:
	var at = f.cast.get("at") if f.cast != null else null
	return typeof(at) == TYPE_VECTOR2 and at.distance_to(Vector2(cell)) < 0.01

# EV822 · S302·I216: 불화살 고블린은 9칸 안에 다 지은 쏘는 구조물이 들면 멈춰 1초 예고 뒤 물리 5를 주고, 6초 뒤 같은 자리에서 다시 쏜다.
# 먼저 9칸 안에 드는 미완성 타워와 방벽은 노리지 않는다. 예고 at은 노린 칸 가운데다. 사거리 안에 다 지은 타워가 둘이면 가까운 쪽에만 쏘고,
# 마법 타워·대포 하나만 있어도 멈춰 5를 준다
func ev822():
	var b = battle({"waves": WW})
	var why := _need(b, FA)
	if why != "":
		return why
	var t = b.build("tower", T0)
	var w = b.build("wall", Vector2i(4, 7))
	var eng = b.place_merc("engineer", Vector2i(6, 12))
	if t == null or w == null or eng == null:
		return "시험 판을 차리지 못했다(타워 %s · 방벽 %s · 공병 %s)" % [t, w, eng]
	_fight(b)
	var u = b.build("tower", Vector2i(6, 7))
	b.damage(eng, BIG)  # 짓는 공병이 없어 미완성으로 남는다
	if u == null or u.complete:
		return "시험 조건이 틀렸다: 미완성 타워를 두지 못했다(%s)" % u
	var f = b.spawn_enemy(FA, Vector2i(0, 10), {"hp": BIG})
	if not run(b, 15.0, func(): return _casting(f, FLAME)):
		return "15초 안에 불화살 예고(cast id flame)를 시작하지 않았다(자리 %s · 타워 체력 %.1f)" % [f.pos, t.hp]
	var gap: float = f.pos.distance_to(Vector2(T0))
	var aimed := _aims(f, T0)
	var at: Vector2 = f.pos
	var hp0: float = t.hp
	var hit_t := 0.0
	while hit_t < 2.0 and t.hp == hp0:
		b.step(DT)
		hit_t += DT
	var loss: float = hp0 - t.hp
	var spared: bool = b.structure_at(u.cell) == u and w.hp == w.max_hp
	var again := 0.0
	while again < 8.0 and not _casting(f, FLAME):
		b.step(DT)
		again += DT
	var still: bool = f.pos.distance_to(at) < 0.01
	if not (gap >= 8.8 and gap <= 9.01 and aimed and hit_t >= 0.95 and hit_t <= 1.1 and loss >= 4.99 and loss <= 5.21 and spared
			and again >= 5.8 and again <= 6.3 and still):
		return "멈춘 거리 %.2f(8.8~9) · 예고 at이 타워 칸 %s %s · 맞기까지 %.2f초(1) · 맞은 피해 %.2f(5) · 미완성 타워·방벽 그대로 %s · 다음 예고까지 %.2f초(5.8~6.3) · 같은 자리 %s" % [
			gap, T0, aimed, hit_t, loss, spared, again, still]
	# 둘째 판: 나온 자리에서 다 지은 타워 둘이 사거리 안이다. 먼 쪽을 먼저 짓는다
	var c = battle()
	var far = c.build("tower", Vector2i(6, 16))  # (0,10)에서 8.49칸
	var near = c.build("tower", Vector2i(5, 5))  # (0,10)에서 7.07칸
	if far == null or near == null:
		return "둘째 판을 차리지 못했다(먼 타워 %s · 가까운 타워 %s)" % [far, near]
	var g = c.spawn_enemy(FA, Vector2i(0, 10), {"hp": BIG})
	if not run(c, 5.0, func(): return _casting(g, FLAME)):
		return "둘째 판: 5초 안에 불화살 예고를 시작하지 않았다(자리 %s)" % g.pos
	var chose := _aims(g, near.cell)
	var landed := run(c, 2.0, func(): return near.hp < near.max_hp or far.hp < far.max_hp)
	if not (chose and landed and near.hp < near.max_hp and far.hp == far.max_hp):
		return "둘째 판(7.07칸·8.49칸 타워): 예고 at이 가까운 타워 칸 %s %s · 2초 안에 맞음 %s · 가까운 타워 %.1f/%.1f · 먼 타워 %.1f/%.1f(그대로)" % [
			near.cell, chose, landed, near.hp, near.max_hp, far.hp, far.max_hp]
	# 셋째·넷째 판: 마법 타워나 대포 하나만 있어도 멈춰 쏜다
	for kind in ["magic", "cannon"]:
		var d = battle()
		var s = d.build(kind, T0)
		if s == null:
			return "%s 판을 차리지 못했다" % kind
		var h = d.spawn_enemy(FA, Vector2i(0, 10), {"hp": BIG})
		if not run(d, 15.0, func(): return _casting(h, FLAME)):
			return "%s 판: 15초 안에 불화살 예고를 시작하지 않았다(자리 %s · 체력 %.1f)" % [kind, h.pos, s.hp]
		var gap2: float = h.pos.distance_to(Vector2(T0))
		var aim2 := _aims(h, T0)
		var s0: float = s.hp
		var wait := 0.0
		while wait < 2.0 and s.hp == s0:
			d.step(DT)
			wait += DT
		var loss2: float = s0 - s.hp
		if not (gap2 >= 8.8 and gap2 <= 9.01 and aim2 and wait >= 0.95 and wait <= 1.1 and loss2 >= 4.99 and loss2 <= 5.21):
			return "%s 판: 멈춘 거리 %.2f(8.8~9) · 예고 at이 그 칸 %s · 맞기까지 %.2f초(1) · 맞은 피해 %.2f(5)" % [kind, gap2, aim2, wait, loss2]
	return ""

# EV823 · S302(2026-11-08 변경): 쏘는 구조물이 없으면 사거리 안의 가장 가까운 유닛에 불화살을 쏜다. 예고는 그 유닛을 따라가고,
# 1초 뒤 물리 5를 준다. 쏠 것이 없으면 성문까지 가서 근접으로 3을 친다
func ev823():
	var b = _siege()
	var why := _need(b, FA)
	if why != "":
		return why
	var side = b.place_merc("soldier", Vector2i(10, 13), QUIET.merged({"hp": 100, "armor": 0}))
	if side == null:
		return "시험 판을 차리지 못했다(병사 %s)" % side
	var f = b.spawn_enemy(FA, Vector2i(12, 16), {"hp": BIG})
	if not run(b, 1.0, func(): return _casting(f, FLAME)):
		return "1초 안에 불화살 예고를 시작하지 않았다(자리 %s · 병사 %.1f)" % [f.pos, side.hp]
	var on = f.cast.get("on")
	side.pos = Vector2(8, 13)
	b.step(DT)
	var at = f.cast.get("at") if f.cast != null else null
	var follows: bool = typeof(at) == TYPE_VECTOR2 and at.distance_to(side.pos) < 0.01
	var hp0: float = side.hp
	var hit_t := DT
	while hit_t < 2.0 and side.hp == hp0:
		b.step(DT)
		hit_t += DT
	var loss: float = hp0 - side.hp
	if not (on == side and follows and hit_t >= 0.95 and hit_t <= 1.1 and loss >= 4.99 and loss <= 5.21):
		return "노린 것이 병사 %s · 옮긴 뒤 예고 at %s가 병사 자리 %s를 따라감 %s · 맞기까지 %.2f초(1) · 맞은 피해 %.2f(5)" % [
			on == side, at, side.pos, follows, hit_t, loss]
	b.damage(side, BIG)
	var g = b.castle[GATE]
	var g0: float = g.hp
	var hit := run(b, 15.0, func(): return g.hp < g0)
	if not hit:
		return "병사가 쓰러진 뒤 15초 안에 성문을 치지 않았다(자리 %s · 병사 살아 있음 %s)" % [f.pos, side.alive]
	return check(is_equal_approx(g0 - g.hp, 3.0) and f.pos.distance_to(Vector2(12, 10)) <= 1.1,
		"성문 %.1f→%.1f(−3) · 친 자리 %s((12,10)에서 1.1칸 안)" % [g0, g.hp, f.pos])

# EV824 · S302·I249: 불은 초당 4로 9초 타고, 붙은 지 3초에 8방향 이웃 쏘는 구조물로 남은 시간 그대로 옮겨붙는다. 옮은 불도 3초 뒤 번지고
# 남은 시간이 0이면 번지지 않는다. 2칸 떨어진 타워와 곁 방벽은 붙지 않는다. 불붙은 타워가 또 맞으면 남은 시간이 9초로 새로 되고 번짐도 새로 센다
# 9 = 3+3+3이라 한 스텝 안의 연산 순서에 따라 셋째 이웃이 한 스텝(0.2) 타거나 이웃 피해가 ±0.6 흔들려, 셋째 이웃은 0.25 이하·이웃은 ±1로 잰다
func ev824():
	var b = battle()
	var why := _need(b, FA)
	if why != "":
		return why
	var a = b.build("tower", T0)
	var m = b.build("magic", T0 + Vector2i(1, -1))  # a의 대각선 이웃
	var c = b.build("cannon", T0 + Vector2i(2, -2))  # m의 이웃, a에서 2칸
	var d = b.build("tower", T0 + Vector2i(3, -3))  # c의 이웃
	var e = b.build("tower", T0 + Vector2i(2, 1))  # a에서 2칸, 누구와도 이웃이 아니다
	var w = b.build("wall", T0 + Vector2i(-1, 0))  # a의 이웃 방벽
	var six := [a, m, c, d, e, w]
	if six.has(null):
		return "시험 판을 차리지 못했다(%s)" % [six]
	var f = _lit(b, a)
	if f == null:
		return "15초 안에 타워 %s를 맞히지 않았다" % T0
	b.damage(f, BIG)  # 한 번만 맞힌다
	run(b, 2.8)
	var early: bool = m.hp == m.max_hp
	run(b, 0.5)
	var caught: bool = m.hp < m.max_hp
	run(b, 9.0)
	var lost: Array = six.map(func(s): return s.max_hp - s.hp)
	run(b, 2.0)
	var settled: bool = six.map(func(s): return s.max_hp - s.hp) == lost
	if not (early and caught and _about(lost[0], 41.0) and _about(lost[1], 24.0, 1.0) and _about(lost[2], 12.0, 1.0) and lost[3] <= 0.25 and lost[4] == 0.0
			and lost[5] == 0.0 and settled):
		return "번짐: 이웃 2.8초 그대로 %s · 3.3초 붙음 %s · 잃은 체력 맞은 타워 %.2f(41±0.5) · 이웃 %.2f(24±1) · 그 이웃 %.2f(12±1) · 셋째 이웃 %.2f(0.25 이하) · 2칸 %.2f(0) · 방벽 %.2f(0) · 끝난 뒤 그대로 %s" % [
			early, caught, lost[0], lost[1], lost[2], lost[3], lost[4], lost[5], settled]
	var r = battle()
	var t = r.build("tower", T0)
	var g = _lit(r, t)
	if g == null:
		return "둘째 판: 15초 안에 타워를 맞히지 않았다"
	if not run(r, 8.0, func(): return _casting(g, FLAME)):
		return "둘째 판: 첫 불화살 뒤 8초 안에 다시 예고하지 않았다(자리 %s)" % g.pos
	var n = r.build("tower", T0 + Vector2i(1, -1))  # t의 대각선 이웃. 첫 불이 번진(3초) 뒤에 지어 첫 불로는 붙지 않는다
	if n == null:
		return "둘째 판: 이웃 타워를 짓지 못했다"
	if not run(r, 1.5, func(): return g.cast == null):
		return "둘째 판: 다시 띄운 예고가 1.5초 안에 끝나지 않았다(자리 %s)" % g.pos
	r.damage(g, BIG)
	run(r, 0.5)
	var h0: float = t.hp
	run(r, 2.3)
	var cold: bool = n.hp == n.max_hp
	run(r, 0.7)
	var spread: bool = n.hp < n.max_hp
	run(r, 5.0)
	var renewed: float = h0 - t.hp
	run(r, 1.5)
	var h1: float = t.hp
	run(r, 1.0)
	return check(_about(renewed, 32.0) and t.hp == h1 and cold and spread,
		"다시 맞은 뒤 0.5~8.5초 불 피해 %.2f(32) · 10~11초 그대로 %s · 이웃 2.8초 그대로 %s · 3.5초 붙음 %s(이웃 %.1f/%.1f)" % [
			renewed, t.hp == h1, cold, spread, n.hp, n.max_hp])

# EV825 · I249: 전투 중 수리를 지시해 공병이 일을 시작하면 불이 꺼진다. 자동 수리 공병은 80% 넘는 불붙은 타워를 더 깎인 불 없는 타워보다 먼저 맡는다.
# 웨이브가 끝나면 불이 꺼진다: 준비 단계에도, 다음 웨이브가 시작된 뒤에도 그 타워가 타지 않는다
func ev825():
	var b = battle({"waves": WW})
	var why := _need(b, FA)
	if why != "":
		return why
	var t = b.build("tower", T0)
	# 타워 북쪽 곁. 남쪽 (12,8)이면 걸어오는 고블린 사거리에 타워보다 먼저 들어 공병을 쏜다(S302 2026-11-08 변경)
	var eng = b.place_merc("engineer", T0 + Vector2i(0, -2))
	if t == null or eng == null:
		return "시험 판을 차리지 못했다(타워 %s · 공병 %s)" % [t, eng]
	_fight(b)
	var f = _lit(b, t)
	if f == null:
		return "15초 안에 타워를 맞히지 않았다"
	b.damage(f, BIG)
	var h0: float = t.hp
	run(b, 1.0)
	var burned: float = h0 - t.hp
	b.repair(t)
	if eng.job != t:
		return "전투 중 수리 지시를 공병이 맡지 않았다(일 %s)" % eng.job
	var seen := {"prev": t.hp, "drop": 0.0}
	var began := run(b, 5.0, func():
		var up: bool = t.hp > seen.prev + 0.0001
		seen.prev = t.hp
		return up)
	run(b, 9.0, func():
		seen.drop = maxf(seen.drop, seen.prev - t.hp)
		seen.prev = t.hp
		return false)
	if burned < 3.5 or not began or seen.drop > 0.0001:
		return "수리: 맞은 뒤 1초 불 피해 %.2f(4) · 5초 안에 고치기 시작 %s · 시작 뒤 9초 동안 한 스텝에 가장 크게 깎인 양 %.2f(0)" % [burned, began, seen.drop]
	var c = battle({"waves": WW})
	var t2 = c.build("tower", T0)
	var worse = c.build("tower", T0 + Vector2i(4, 2))
	var e2 = c.place_merc("engineer", T0 + Vector2i(1, 2))
	if t2 == null or worse == null or e2 == null:
		return "둘째 판을 차리지 못했다(타워 %s · 깎을 타워 %s · 공병 %s)" % [t2, worse, e2]
	_fight(c)
	var f2 = _lit(c, t2)
	if f2 == null:
		return "둘째 판: 15초 안에 타워를 맞히지 않았다"
	c.damage(f2, BIG)
	worse.hp = worse.max_hp * 0.5
	var ratio: float = t2.hp / t2.max_hp
	c.live_prep = true
	c.set_auto_fix([e2], true)
	var took := run(c, 1.5, func(): return e2.job != null)
	if not took or e2.job != t2 or ratio <= 0.8:
		return "자동 수리: 불붙은 타워 체력 %.0f%%(80%% 넘음) · 1.5초 안에 맡음 %s · 맡은 것이 불붙은 타워 %s · 50%%인 타워 %s" % [
			ratio * 100.0, took, e2.job == t2, e2.job == worse]
	var d = battle({"waves": WW})
	var t3 = d.build("tower", T0)
	if t3 == null:
		return "셋째 판을 차리지 못했다"
	_fight(d)
	if _lit(d, t3) == null:
		return "셋째 판: 15초 안에 타워를 맞히지 않았다"
	var h3: float = t3.hp
	run(d, 1.0)
	var lit: bool = h3 - t3.hp >= 3.5
	if not clear_wave(d) or d.state != "prep":
		return "셋째 판: 웨이브가 끝나 준비 단계로 가지 않았다(%s)" % d.state
	var h4: float = t3.hp
	run(d, 3.0)
	var h5: float = t3.hp
	d.start_battle()  # 준비 단계에 불을 멈춰 두기만 했다면 다음 웨이브에 다시 탄다
	var next: bool = d.state == "battle"
	run(d, 2.0)
	return check(lit and h5 == h4 and next and t3.hp == h5,
		"웨이브 끝: 끝나기 전 1초 불 피해 %s · 준비 단계 3초 동안 타워 체력 %.2f → %.2f(그대로) · 다음 웨이브 시작 %s · 시작 뒤 2초 동안 %.2f → %.2f(그대로)" % [
			lit, h4, h5, next, h5, t3.hp])

# EV826 · I249·S279: 불화살 예고 중 기절이면 꺼지고 비틀거리지 않으며 대기가 처음부터 돈다. 봉인 중엔 시작하지 않는다.
# 예고 중 노린 타워가 없어지면 쏘지 않고, 대기가 돈 뒤에야 다음 타워에 쏜다
func ev826():
	var b = battle()
	var why := _need(b, FA)
	if why != "":
		return why
	var t = b.build("tower", T0)
	var f = b.spawn_enemy(FA, Vector2i(0, 10), {"hp": BIG})
	if not run(b, 15.0, func(): return _casting(f, FLAME)):
		return "15초 안에 불화살 예고를 시작하지 않았다(자리 %s)" % f.pos
	run(b, 0.5)
	f.fx["test_stun"] = {"stun": true, "left": 0.5}
	b.step(DT)
	var off: bool = f.cast == null
	var reel: bool = b.effect(f, "expose") != null
	var waited := 0.0
	var kept := true
	while waited < 7.0 and f.cast == null:
		b.step(DT)
		waited += DT
		if waited <= 1.5 + 0.001:
			kept = kept and t.hp == t.max_hp
	var c = battle()
	c.build("tower", T0)
	var s = c.spawn_enemy(FA, Vector2i(0, 10), {"hp": BIG})
	s.fx["test_seal"] = {"seal": true, "left": 30.0}
	var quiet := not run(c, 20.0, func(): return s.cast != null)
	var d = battle()
	var t1 = d.build("tower", T0)
	var t2 = d.build("tower", Vector2i(16, 6))  # 처음 멈춘 자리에서 12.7칸. 걸어가야 9칸 안에 든다
	var g = d.spawn_enemy(FA, Vector2i(0, 10), {"hp": BIG})
	if not run(d, 15.0, func(): return _casting(g, FLAME)):
		return "셋째 판: 15초 안에 불화살 예고를 시작하지 않았다(자리 %s)" % g.pos
	run(d, 0.5)
	d.damage(t1, BIG)
	var gone: bool = d.structure_at(T0) == null
	var w2 := 0.0
	var safe := true
	while w2 < 1.5 and g.cast != null:  # 없어진 타워의 예고가 끝나기를 기다린다(바로 꺼져도 된다)
		d.step(DT)
		w2 += DT
		safe = safe and t2.hp == t2.max_hp
	while w2 < 9.0 and not _casting(g, FLAME):
		d.step(DT)
		w2 += DT
		safe = safe and t2.hp == t2.max_hp
	var reach: float = g.pos.distance_to(Vector2(16, 6))
	return check(off and not reel and kept and waited >= 5.8 and waited <= 6.3 and quiet and gone and safe and w2 >= 5.8 and w2 <= 6.8 and reach <= 9.01,
		"기절에 꺼짐 %s · 비틀거림 %s · 1.5초 타워 그대로 %s · 다음 예고까지 %.2f초(5.8~6.3) · 봉인 20초 예고 없음 %s · 노린 타워 없어짐 %s · 다음 타워 그대로 %s · 다음 예고까지 %.2f초(5.8~6.8) · 그 타워까지 %.2f칸(9 이하)" % [
			off, reel, kept, waited, quiet, gone, safe, w2, reach])

# EV827 · I249·S279: 밤에 불빛 밖에 숨은 불화살 고블린이 띄운 불화살 예고는 그리고(tellers), 몸은 그리지 않는다(foes). 예고 색은 일반 적 주황이다
func ev827():
	var b = battle({"waves": WW, "nights": [[{"at": 0.0, "dark": 1.0, "fade": 0.05}, {}]]})
	var why := _need(b, FA)
	if why != "":
		return why
	if b.build("tower", T0) == null:
		return "시험 판을 차리지 못했다"
	_fight(b)
	var f = b.spawn_enemy(FA, Vector2i(0, 10), {"hp": BIG})
	if not run(b, 15.0, func(): return _casting(f, FLAME)):
		return "15초 안에 불화살 예고를 시작하지 않았다(자리 %s)" % f.pos
	if b.dark <= 0.0 or b.seen(f.pos):
		return "시험 조건이 틀렸다: 어둠 %.2f · 고블린 자리 %s가 보인다 %s(숨어야 한다)" % [b.dark, f.pos, b.seen(f.pos)]
	var v = load("res://src/ui/battle_view.gd").new()
	v.battle = b
	var told: bool = f in v.tellers()
	var drawn: bool = f in v.foes()
	var col: Color = v.tell_color(f)
	v.free()
	return check(told and not drawn and col == Color("ef692f"),
		"숨은 고블린: 예고를 그림 %s · 몸을 그림 %s · 예고 색 %s(ef692f)" % [told, drawn, col.to_html(false)])

# 불화살 예고가 유닛 u를 노리는가
func _aims_at(f, u) -> bool:
	return f.cast != null and f.cast.get("id") == FLAME and f.cast.get("on") == u

# EV830 · S302(2026-11-08 변경): 사거리 안에 쏘는 구조물이 있으면 더 가까운 병사가 있어도 구조물에 쏜다.
# 도발한 병사가 사거리 안이면 구조물보다 먼저 그 병사에 쏘고, 사거리 밖이면 쏘지 않고 다가가 사거리에 들면 쏜다
func ev830():
	var b = battle({"waves": WW})
	var why := _need(b, FA)
	if why != "":
		return why
	var t = b.build("tower", Vector2i(5, 5))
	var near = b.place_merc("soldier", Vector2i(2, 10), QUIET.merged({"hp": 100}))
	if t == null or near == null:
		return "시험 판을 차리지 못했다(타워 %s · 병사 %s)" % [t, near]
	_fight(b)
	var f = b.spawn_enemy(FA, Vector2i(0, 10), {"hp": BIG})
	if not run(b, 5.0, func(): return _casting(f, FLAME)):
		return "5초 안에 불화살 예고를 시작하지 않았다(자리 %s)" % f.pos
	var chose := _aims(f, t.cell)
	var landed := run(b, 2.0, func(): return t.hp < t.max_hp)
	if not (chose and landed and near.hp == 100.0):
		return "타워 (5,5)·병사 (2,10): 예고 at이 타워 칸 %s · 2초 안에 타워를 깎음 %s · 병사 %.1f(100)" % [chose, landed, near.hp]
	var c = battle({"waves": WW})
	var t2 = c.build("tower", Vector2i(5, 5))
	var lure = c.place_merc("soldier", Vector2i(2, 10), QUIET.merged({"hp": 100}))
	if t2 == null or lure == null:
		return "둘째 판을 차리지 못했다(타워 %s · 병사 %s)" % [t2, lure]
	_fight(c)
	var g = c.spawn_enemy(FA, Vector2i(0, 10), {"hp": BIG})
	g.fx["test_taunt"] = {"taunt": lure, "left": 30.0}
	if not run(c, 5.0, func(): return _aims_at(g, lure)):
		return "둘째 판: 도발한 병사 (2,10)을 노린 예고를 5초 안에 띄우지 않았다(cast %s)" % [g.cast]
	var d = battle({"waves": WW})
	var t3 = d.build("tower", Vector2i(5, 5))
	var far = d.place_merc("soldier", Vector2i(20, 10), QUIET.merged({"hp": 100}))
	if t3 == null or far == null:
		return "셋째 판을 차리지 못했다(타워 %s · 병사 %s)" % [t3, far]
	_fight(d)
	var h = d.spawn_enemy(FA, Vector2i(0, 10), {"hp": BIG})
	h.fx["test_taunt"] = {"taunt": far, "left": 30.0}
	var seen := {"cast": false}
	run(d, 5.0, func():
		seen.cast = seen.cast or h.cast != null
		return false)
	var x5: float = h.pos.x
	var later := run(d, 15.0, func(): return _aims_at(h, far))
	return check(not seen.cast and x5 > 2.0 and later,
		"셋째 판(도발한 병사 (20,10), 사거리 밖): 5초 동안 예고 %s(없음) · 5초 뒤 x %.2f(2보다 큼) · 20초 안에 그 병사를 노림 %s" % [seen.cast, x5, later])

# EV831 · S302(2026-11-08 변경): 유닛의 불은 9초 동안 초당 4 물리 피해이고 곁 유닛·쏘는 구조물로 번지지 않는다. 발치에 불꽃 조각을 그린다.
# 성역(정화)이 지우고, 웨이브가 끝나면 꺼진다
func ev831():
	var b = battle({"waves": WW})
	var why := _need(b, FA)
	if why != "":
		return why
	var a = b.place_merc("soldier", Vector2i(4, 10), QUIET.merged({"hp": 1000, "armor": 0}))
	var other = b.place_merc("soldier", Vector2i(5, 10), QUIET.merged({"hp": 1000, "armor": 0}))
	var eng = b.place_merc("engineer", Vector2i(6, 12))
	if a == null or other == null or eng == null:
		return "시험 판을 차리지 못했다(병사 a %s · 곁 병사 %s · 공병 %s)" % [a, other, eng]
	_fight(b)
	var f = b.spawn_enemy(FA, Vector2i(0, 10), {"hp": BIG})
	if not run(b, 5.0, func(): return a.hp < a.max_hp):
		return "5초 안에 병사 a를 맞히지 않았다(cast %s · 곁 병사 %.1f)" % [f.cast, other.hp]
	b.damage(f, BIG)
	var u = b.build("tower", Vector2i(4, 9))
	b.damage(eng, BIG)  # 짓는 공병이 없어 미완성으로 남는다(EV822와 같다). 구조물의 불은 미완성 쏘는 구조물에도 번진다(I249 ④)
	if u == null or u.complete:
		return "시험 조건이 틀렸다: a 곁에 미완성 타워를 두지 못했다(%s)" % u
	var u0: float = u.hp
	var v = load("res://src/ui/battle_view.gd").new()
	v.battle = b
	var lit: bool = v.status_marks(a, true).any(func(m): return m.k == "flame_s")
	var plain: bool = not v.status_marks(other, true).any(func(m): return m.k == "flame_s")
	v.free()
	run(b, 0.5)
	var h05: float = a.hp
	run(b, 8.0)
	var h85: float = a.hp
	run(b, 1.5)
	var h10: float = a.hp
	run(b, 1.0)
	var h11: float = a.hp
	if not (_about(h05 - h85, 32.0) and h11 == h10 and other.hp == other.max_hp and u.hp == u0 and lit and plain):
		return "맞은 뒤 0.5~8.5초 불 피해 %.2f(32±0.5) · 10~11초 %.2f → %.2f(그대로) · 곁 병사 %.1f/%.1f · 곁 미완성 타워 %.1f → %.1f · 불꽃 조각 a %s · 곁 병사 없음 %s" % [
			h05 - h85, h10, h11, other.hp, other.max_hp, u0, u.hp, lit, plain]
	var c = battle({"waves": WW, "heroes": [{"kind": "seraphina", "cell": Vector2i(6, 12)}]})
	var a2 = c.place_merc("soldier", Vector2i(4, 10), QUIET.merged({"hp": 1000, "armor": 0}))
	if a2 == null or c.heroes.is_empty():
		return "둘째 판을 차리지 못했다(병사 %s · 영웅 %s)" % [a2, c.heroes]
	var sera = c.heroes[0]
	_fight(c)
	var g = c.spawn_enemy(FA, Vector2i(0, 10), {"hp": BIG})
	if not run(c, 5.0, func(): return a2.hp < a2.max_hp):
		return "둘째 판: 5초 안에 병사를 맞히지 않았다(cast %s)" % [g.cast]
	c.damage(g, BIG)
	var burning: bool = c.effect_sum(a2, "burn") > 0.0
	var cast_ok = c.cast(sera, "w", a2.pos)
	var wiped := run(c, 0.5, func(): return c.effect_sum(a2, "burn") == 0.0)
	if not (burning and cast_ok and wiped):
		return "둘째 판: 맞은 병사 불 %s · 성역 씀 %s · 0.5초 안에 불이 0 %s(남은 불 %.2f)" % [burning, cast_ok, wiped, c.effect_sum(a2, "burn")]
	var d = battle({"waves": WW})
	var a3 = d.place_merc("soldier", Vector2i(4, 10), QUIET.merged({"hp": 1000, "armor": 0}))
	if a3 == null:
		return "셋째 판을 차리지 못했다"
	_fight(d)
	d.spawn_enemy(FA, Vector2i(0, 10), {"hp": BIG})
	if not run(d, 5.0, func(): return a3.hp < a3.max_hp):
		return "셋째 판: 5초 안에 병사를 맞히지 않았다"
	var hot: bool = d.effect_sum(a3, "burn") > 0.0
	if not clear_wave(d) or d.state != "prep":
		return "셋째 판: 웨이브가 끝나 준비 단계로 가지 않았다(%s)" % d.state
	return check(hot and d.effect_sum(a3, "burn") == 0.0,
		"셋째 판: 웨이브 끝나기 전 불 %s · 준비 단계의 불 %.2f(0)" % [hot, d.effect_sum(a3, "burn")])
