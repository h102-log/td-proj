extends "res://tests/eval/gd/lib.gd"
# 3라운드 고블린 약탈단 묶음 ②-b: 고블린 전쟁 기계 1페이즈(S287·I223). 묶음 ②-c: 2페이즈 고블린 대장(S288·I230).
# lib.gd·boss.gd 머리의 계약에 더하는 API:
#   적 kind "war_machine"(고블린 전쟁 기계) · 적 skills(스킬 이름 → 수치: slam·grab·cannon·mgun) · 적 cast {id, left, at?}
#   적 kind "chief"(고블린 대장, 기계가 부서지면 같은 적이 이 종류가 된다) · skills leap·cleave·fling·bombs·charge·rage
#   · 철퇴 cast의 dir(라디안) · 폭탄 cast의 spots(자리 배열) · 적 via·boss·armor · Battle.fallen · Battle.raging(적) · Battle.finish(구조물)
#   Battle.effect(대상, 키) · Battle.castle(칸 → 성곽) · Battle.area_of(구조물) -> Rect2i
# 기절은 적 fx에 직접 넣어 건다(boss.gd와 같다)

const GATE := Vector2i(12, 9)
const WM := Vector2i(10, 10)  # 성곽 없는 판의 기계 자리
const QUIET := {"damage": 0, "range": 0, "sight": 0, "hp": BIG}  # 치지도 쫓지도 않는 병사(체력 큼)

# 9행 성곽(성문은 GATE 하나, 나머지 열은 성벽), 마을 0~8행, 거점 (12,2). 3라운드 준비 단계로 간다(siege2.gd _raid와 같다)
func _raid():
	var walls := []
	for x in 30:
		if x != GATE.x:
			walls.append(Vector2i(x, 9))
	var w := [[{"kind": "basic", "count": 1}]]
	var b = battle({"size": Vector2i(30, 20), "base": Vector2i(12, 2), "base_hp": BIG, "spawns": [Vector2i(12, 19)],
		"village": Rect2i(0, 0, 30, 9), "castle": {"walls": walls, "gates": [GATE], "wall_hp": 300, "gate_hp": 150}, "rounds": [w, w, w]})
	for i in 2:
		b.start_battle()
		if not clear_wave(b) or not b.next_round():
			return null
	return b if b.round_index == 2 and b.state == "prep" else null

func _need(b) -> String:
	if b == null:
		return "3라운드 준비 단계로 가지 못했다"
	return "" if b.ENEMY_KINDS.has("war_machine") else "적 종류 war_machine이 없다"

# 전쟁 기계(체력 큼). only가 배열이면 그 스킬만 남긴다(빈 배열이면 스킬 없음)
func _wm(b, cell: Vector2i, only = null):
	var sk: Dictionary = b.ENEMY_KINDS.war_machine.get("skills", {})
	var keep := {}
	for id in sk:
		if only == null or id in only:
			keep[id] = sk[id]
	return b.spawn_enemy("war_machine", cell, {"hp": BIG, "skills": keep})

func _soldier(b, cell: Vector2i):
	return b.place_merc("soldier", cell, QUIET)

func _casting(e, id: String) -> bool:
	return e.cast != null and e.cast.get("id") == id

func _lost(m) -> float:
	return m.max_hp - m.hp

# 8의 배수(8 이상)만큼 잃었다
func _riddled(m) -> bool:
	var n := _lost(m) / 8.0
	return n >= 1.0 and is_equal_approx(n, roundf(n))

func _stun(e) -> void:
	e.fx["test_stun"] = {"stun": true, "left": 1.0}

# EV694 · S287: 인식 범위 0이라 곁의 병사를 노리지 않고 성문으로 가서 친다. 길을 막은 병사는 친다
func ev694():
	var b = _raid()
	var why := _need(b)
	if why != "":
		return why
	var gate = b.castle.get(GATE)
	var side = _soldier(b, Vector2i(14, 14))
	if gate == null or side == null:
		return "성문이나 병사를 두지 못했다"
	_wm(b, Vector2i(12, 16), [])
	var hit := run(b, 30.0, func(): return gate.hp < gate.max_hp)
	var spared: bool = side.hp == side.max_hp
	var c = _raid()
	var m = _soldier(c, Vector2i(12, 13))
	if m == null:
		return "길에 병사를 두지 못했다"
	_wm(c, Vector2i(12, 16), [])
	var blocked := run(c, 10.0, func(): return m.hp < m.max_hp)
	return check(hit and spared and blocked, "30초 안 성문 피해 %s · 곁 병사 그대로 %s · 길을 막은 병사 피해 %s" % [hit, spared, blocked])

# EV695 · S287: 대포는 가장 몰린 아군 자리에 원 예고 1.2초 뒤 아군 −30·넉백. 아군이 없으면 가장 가까운 성벽 열에 −40
func ev695():
	var b = battle({"base_hp": BIG})
	if not b.ENEMY_KINDS.has("war_machine"):
		return "적 종류 war_machine이 없다"
	var three := [Vector2i(9, 4), Vector2i(10, 4), Vector2i(11, 4)]
	var ms: Array = three.map(func(c): return _soldier(b, c))
	var lone = _soldier(b, Vector2i(16, 10))
	var e = _wm(b, WM, ["cannon"])
	if not run(b, 0.1, func(): return _casting(e, "cannon")):
		return "0.1초 안에 대포 예고를 시작하지 않았다(cast %s)" % [e.cast]
	var aim: bool = e.cast.has("at") and Vector2(e.cast.at).distance_to(Vector2(10, 4)) <= 0.01
	var at: Vector2 = e.pos
	var d0: Array = ms.map(func(m): return m.pos.distance_to(Vector2(10, 4)))
	run(b, 1.1)
	var held: bool = e.pos.distance_to(at) <= 0.01 and ms.all(func(m): return m.hp == m.max_hp) and lone.hp == lone.max_hp
	run(b, 0.2)
	var hit: bool = ms.all(func(m): return is_equal_approx(_lost(m), 30.0)) and lone.hp == lone.max_hp
	var pushed := true
	for i in ms.size():
		pushed = pushed and ms[i].pos.distance_to(Vector2(10, 4)) > d0[i] + 0.5
	var c = _raid()
	var why := _need(c)
	if why != "":
		return why
	var col = c.castle.get(Vector2i(20, 9))
	var w = _wm(c, Vector2i(20, 13), ["cannon"])
	var wall := run(c, 0.1, func(): return _casting(w, "cannon"))
	var on_col: bool = wall and w.cast.has("at") and Vector2(w.cast.at).distance_to(Vector2(20, 9)) <= 0.01 and c.area_of(col).has_point(Vector2i(20, 9))
	run(c, 1.3)
	var broke: bool = col != null and is_equal_approx(col.max_hp - col.hp, 40.0)
	return check(aim and held and hit and pushed and on_col and broke,
		"자리 (10,4) %s · 1.1초 그대로 %s · 1.3초 셋 −30·외톨이 그대로 %s · 넉백 %s · 아군 없을 때 성벽 열 원 %s · 그 열 −40 %s" % [aim, held, hit, pushed, on_col, broke])

# EV696 · S287: 기관총은 가장 가까운 아군 쪽 부채꼴(각 120°)을 1초 예고한 뒤 2초 쏜다. 부채꼴 밖·성벽에 가린 땅 아군은 맞지 않는다
func ev696():
	var b = battle({"base_hp": BIG})
	if not b.ENEMY_KINDS.has("war_machine"):
		return "적 종류 war_machine이 없다"
	var a = _soldier(b, Vector2i(10, 7))
	var bb = _soldier(b, Vector2i(12, 7))
	var cc = _soldier(b, Vector2i(6, 10))
	var d = _soldier(b, Vector2i(10, 14))
	var all := [a, bb, cc, d]
	var e = _wm(b, WM, ["mgun"])
	if not run(b, 0.1, func(): return _casting(e, "mgun")):
		return "0.1초 안에 기관총 예고를 시작하지 않았다(cast %s)" % [e.cast]
	run(b, 0.95)
	var quiet: bool = all.all(func(m): return m.hp == m.max_hp)
	run(b, 2.25)
	var hit: bool = _riddled(a) and _riddled(bb) and cc.hp == cc.max_hp and d.hp == d.max_hp
	var lost := [_lost(a), _lost(bb), _lost(cc), _lost(d)]
	var rest := not run(b, 2.8, func(): return e.cast != null)
	var c = _raid()
	var why := _need(c)
	if why != "":
		return why
	var top = _soldier(c, Vector2i(18, 5))  # 마을에 두고 성벽 위 (20,9)로 올린다(wolf.gd _merc_on과 같다)
	var inside = _soldier(c, Vector2i(21, 7))
	if top == null or inside == null:
		return "성벽 위·마을에 병사를 두지 못했다"
	top.pos = Vector2(20, 9)
	top.anchor = top.pos
	top.on_wall = true
	_wm(c, Vector2i(20, 11), ["mgun"])
	run(c, 3.2)
	var shot: bool = top.hp < top.max_hp
	var hid: bool = inside.hp == inside.max_hp
	return check(quiet and hit and rest and shot and hid,
		"0.95초 그대로 %s · 3.2초 A·B 8의 배수·C·D 그대로 %s(잃은 체력 %s) · 6초까지 다시 예고 안 함 %s · 성벽 위 맞음 %s · 성벽 너머 마을 그대로 %s" % [quiet, hit, lost, rest, shot, hid])

# EV697 · I223: 집어 던지기는 붙은 병사를 0.8초 뒤 보스 너머 4칸에 던지고 −25. 예고 중 원 밖으로 나가면 헛친다
func ev697():
	var b = battle({"base_hp": BIG})
	if not b.ENEMY_KINDS.has("war_machine"):
		return "적 종류 war_machine이 없다"
	var m = _soldier(b, Vector2i(10, 9))
	var e = _wm(b, WM, ["grab"])
	if not run(b, 0.1, func(): return _casting(e, "grab")):
		return "0.1초 안에 집어 던지기 예고를 시작하지 않았다(cast %s)" % [e.cast]
	run(b, 0.75)
	var held: bool = m.pos.distance_to(Vector2(10, 9)) <= 0.05 and m.hp == m.max_hp
	run(b, 0.15)
	var thrown: bool = m.pos.distance_to(Vector2(10, 14)) <= 1.0 and is_equal_approx(_lost(m), 25.0)
	var where: Vector2 = m.pos
	var c = battle({"base_hp": BIG})
	var n = _soldier(c, Vector2i(10, 9))
	var f = _wm(c, WM, ["grab"])
	run(c, 0.1, func(): return _casting(f, "grab"))
	run(c, 0.4)
	n.pos = Vector2(10, 6)
	n.anchor = Vector2(10, 6)
	run(c, 0.5)
	var miss: bool = n.hp == n.max_hp and n.pos.distance_to(Vector2(10, 6)) <= 1.0
	return check(held and thrown and miss, "0.75초 그대로 %s · 0.9초 (10,14) 1칸 안·−25 %s(자리 %s, 잃은 체력 %s) · 원 밖이면 헛침 %s" % [held, thrown, where, _lost(m), miss])

# EV698 · S287: 땅 아군 둘이 붙으면 스킬 넷 가운데 내려찍기가 먼저다. 1.2초 예고 뒤 −30·넉백·둔화 0.3
func ev698():
	var b = battle({"base_hp": BIG})
	if not b.ENEMY_KINDS.has("war_machine"):
		return "적 종류 war_machine이 없다"
	var ms := [_soldier(b, Vector2i(11, 10)), _soldier(b, Vector2i(10, 11))]
	var e = _wm(b, WM)
	var all4: bool = ["slam", "grab", "cannon", "mgun"].all(func(id): return e.skills.has(id))
	if not run(b, 0.1, func(): return e.cast != null):
		return "0.1초 안에 예고를 시작하지 않았다"
	var first: String = e.cast.get("id", "")
	var d0: Array = ms.map(func(m): return m.pos.distance_to(e.pos))
	run(b, 1.25)
	var hit: bool = ms.all(func(m): return is_equal_approx(_lost(m), 30.0))
	var pushed: bool = ms[0].pos.distance_to(e.pos) > d0[0] + 0.5 and ms[1].pos.distance_to(e.pos) > d0[1] + 0.5
	var slowed: bool = ms.all(func(m): return b.effect(m, "slow") != null and is_equal_approx(b.effect(m, "slow"), 0.3))
	return check(all4 and first == "slam" and hit and pushed and slowed,
		"스킬 넷 %s · 첫 예고 %s(slam이어야 한다) · −30 %s · 넉백 %s · 둔화 0.3 %s" % [all4, first, hit, pushed, slowed])

# EV699 · S287·S194: 대포 예고 중 기절이면 취소되고 비틀거린다. 기관총 발사 중 기절이면 멈추고 비틀거린다
func ev699():
	var b = battle({"base_hp": BIG})
	if not b.ENEMY_KINDS.has("war_machine"):
		return "적 종류 war_machine이 없다"
	var ms: Array = [Vector2i(9, 4), Vector2i(10, 4), Vector2i(11, 4)].map(func(c): return _soldier(b, c))
	_soldier(b, Vector2i(16, 10))
	var e = _wm(b, WM, ["cannon"])
	if not run(b, 0.1, func(): return _casting(e, "cannon")):
		return "0.1초 안에 대포 예고를 시작하지 않았다"
	run(b, 0.5)
	_stun(e)
	b.step(DT)
	var off: bool = e.cast == null
	run(b, 0.85)
	var spared: bool = ms.all(func(m): return m.hp == m.max_hp)
	var reel = b.effect(e, "expose")
	var stagger: bool = reel != null and is_equal_approx(reel, 0.5)
	var c = battle({"base_hp": BIG})
	var guns := [_soldier(c, Vector2i(10, 7)), _soldier(c, Vector2i(12, 7)), _soldier(c, Vector2i(6, 10)), _soldier(c, Vector2i(10, 14))]
	var w = _wm(c, WM, ["mgun"])
	if not run(c, 0.1, func(): return _casting(w, "mgun")):
		return "0.1초 안에 기관총 예고를 시작하지 않았다"
	run(c, 1.6)
	var firing: bool = w.cast != null
	_stun(w)
	c.step(DT)
	var stop: bool = w.cast == null
	var reel2 = c.effect(w, "expose")
	var hp0: Array = guns.map(func(m): return m.hp)
	run(c, 0.9)
	var still := true
	for i in guns.size():
		still = still and guns[i].hp == hp0[i]
	return check(off and spared and stagger and firing and stop and reel2 != null and still,
		"대포: 취소 %s · 1.4초 무피해 %s · 비틀거림 %s / 기관총: 1.6초 발사 중 %s · 멈춤 %s · 비틀거림 %s · 기절 동안 피해 없음 %s" % [off, spared, stagger, firing, stop, reel2 != null, still])

# 다각형 칠하기만 모으고 선·성긴 칠·테·원 칠은 그리지 않는 화면(트리 밖)
class Fan extends "res://src/ui/battle_view.gd":
	var polys := []  # [점들, 색]

	func _poly(pts: PackedVector2Array, col: Color) -> void:
		polys.append([pts, col])

	func _pline(_a: Vector2i, _b: Vector2i, _col: Color, _w := 1) -> void:
		pass

	func _pnoise(_c: Vector2i, _r: int, _col: Color, _lim: int, _salt := 0) -> void:
		pass

	func _edge(_c: Vector2i, _r: int, _light: Color, _dark: Color, _others := []) -> void:
		pass

	func _pdisc(_c: Vector2i, _r: int, _col: Color) -> void:
		pass

# 이번 그림의 발동 채움 다각형: 색이 예고색이고 알파 0.6(±0.01)
func _hot(v) -> Array:
	var tell: Color = load("res://src/ui/battle_view.gd").TELL
	return v.polys.filter(func(p): return Color(p[1], 1.0).is_equal_approx(Color(tell, 1.0)) and absf(p[1].a - 0.6) <= 0.01)

# 부채꼴 채움 다각형 pts가 가운데 c, 반경 r(px), 방향 dir ± half(라디안) 안이면 ""
func _fan_ok(pts: PackedVector2Array, c: Vector2, r: float, dir: float, half: float) -> String:
	var rim := 0
	for p in pts:
		var d := p.distance_to(c)
		if d > r + 1.0:
			return "점 %s가 반경 %s 밖(%s)" % [p, r, d]
		if absf(d - r) <= 1.0:
			rim += 1
		if d > 1.0 and absf(angle_difference(dir, (p - c).angle())) > half + deg_to_rad(1.0):
			return "점 %s가 방향 %s ± %s 밖" % [p, dir, half]
	return "" if rim >= 2 else "반경 위 점이 %d개" % rim

# EV709 · S198: 기관총 발사를 시작한 프레임부터 2프레임은 부채꼴 안을 예고색 60%로 채운다
func ev709():
	var b = battle({"base_hp": BIG})
	if not b.ENEMY_KINDS.has("war_machine"):
		return "적 종류 war_machine이 없다"
	_soldier(b, Vector2i(10, 7))
	var e = _wm(b, WM, ["mgun"])
	var sk: Dictionary = e.skills.mgun
	var v = Fan.new()
	v.battle = b
	var hot := []  # 스텝마다 발동 채움 다각형들
	var start := -1
	var dir := 0.0
	for i in int(round(4.0 / DT)):
		b.step(DT)
		v.tick(DT)
		v._foes = v.foes()
		v.polys = []
		v._tells()
		hot.append(_hot(v))
		if start < 0 and e.cast != null and e.cast.get("id") == "mgun" and e.cast.get("fire", false):
			start = i
			dir = e.cast.dir
		if start >= 0 and i >= start + 2:
			break
	if start < 0:
		v.free()
		return "4초 안에 기관총 발사를 시작하지 않았다(cast %s)" % [e.cast]
	var bad := []
	var c: Vector2 = v._center(e.pos)
	for k in 2:
		if hot[start + k].size() != 1:
			bad.append("발사 %d번째 스텝 채움 %d개" % [k + 1, hot[start + k].size()])
		else:
			var msg := _fan_ok(hot[start + k][0][0], c, sk.range * CELL_PX, dir, deg_to_rad(sk.arc) / 2.0)
			if msg != "":
				bad.append("발사 %d번째 스텝: %s" % [k + 1, msg])
	if hot.size() <= start + 2 or not hot[start + 2].is_empty():
		bad.append("셋째 스텝 채움 %s" % [hot.slice(start + 2)])
	v.free()
	return check(bad.is_empty(), "%s" % [bad])

# ── 고블린 대장(S288·I230) ──

const STILL := {"hp": BIG, "speed": 0.0, "damage": 0.0}  # 움직이지도 치지도 않는 대장(체력 큼)

func _no_chief(b) -> String:
	return "" if b.ENEMY_KINDS.has("chief") else "적 종류 chief가 없다"

# secs초를 스텝 수로 센다. run()은 DT를 더해 가며 재서 0.5초가 11스텝이 되기도 한다
func _steps(b, secs: float) -> void:
	for i in roundi(secs / DT):
		b.step(DT)

# 고블린 대장(움직이지도 치지도 않음). only가 배열이면 그 스킬만 남긴다
func _chief(b, cell: Vector2i, only = null, over := {}):
	var sk: Dictionary = b.ENEMY_KINDS.chief.get("skills", {})
	var keep := {}
	for id in sk:
		if only == null or id in only:
			keep[id] = sk[id]
	var stats := STILL.duplicate()
	stats.merge(over, true)
	stats.skills = keep
	return b.spawn_enemy("chief", cell, stats)

# EV744 · S288: 기계 체력이 0이 되면 쓰러지지 않고 대장이 된다. 새 체력 막대는 대장 체력 × 배율이고, 처치 골드·쓰러진 몸이 없다
func ev744():
	var b = battle({"base_hp": BIG, "hp_mult": [1.5]})
	var why := _no_chief(b)
	if why != "":
		return why
	var e = b.spawn_enemy("war_machine", WM, {"hp": 10})
	var g0: int = b.gold
	b.damage(e, 50.0, "true")
	var into: bool = e.alive and e.kind == "chief" and e.get("boss") == true and b.enemies.size() == 1 and b.enemies[0] == e
	var full: bool = is_equal_approx(e.hp, 300.0) and is_equal_approx(e.max_hp, 300.0)
	var body: bool = is_equal_approx(e.radius, 0.9) and is_equal_approx(e.armor, 10.0) and is_equal_approx(e.speed, 1.2)
	var quiet: bool = b.gold == g0 and b.fallen.is_empty()
	var hp := [e.hp, e.max_hp]
	run(b, 1.2)
	b.damage(e, BIG, "true")
	var paid: bool = not e.alive and b.enemies.is_empty() and b.gold == g0 + 50
	return check(into and full and body and quiet and paid,
		"대장으로 %s(종류 %s) · 체력 300 가득 %s(%s) · 몸 0.9·방어 10·속도 1.2 %s · 골드·쓰러진 몸 그대로 %s · 대장 처치 골드 +50 %s(%d)" % [into, e.kind, full, hp, body, quiet, paid, b.gold - g0])

# EV745 · S288: 바뀐 뒤 1초 뛰는 동안 맞지 않고, 착지하면 2.5칸 안 땅 아군 −30·넉백. 하던 대포 예고는 취소된다
func ev745():
	var b = battle({"base_hp": BIG})
	var why := _no_chief(b)
	if why != "":
		return why
	var a = _soldier(b, Vector2i(10, 8))
	var far = _soldier(b, Vector2i(13, 10))
	var e = b.spawn_enemy("war_machine", WM, {"hp": 10, "skills": {"cannon": b.ENEMY_KINDS.war_machine.skills.cannon}})
	if not run(b, 0.1, func(): return _casting(e, "cannon")):
		return "0.1초 안에 대포 예고를 시작하지 않았다(cast %s)" % [e.cast]
	b.damage(e, 50.0, "true")
	_steps(b, 0.5)
	var hp0: float = e.hp
	b.damage(e, 50.0, "true")
	var aloft: bool = e.kind == "chief" and e.hp == hp0
	_steps(b, 0.4)
	var calm: bool = a.hp == a.max_hp and far.hp == far.max_hp
	_steps(b, 0.2)
	var hit: bool = is_equal_approx(_lost(a), 30.0) and a.pos.distance_to(Vector2(10, 10)) > 3.0 and far.hp == far.max_hp
	return check(aloft and calm and hit,
		"0.5초 맞지 않음 %s · 0.9초 그대로 %s · 1.1초 A −30·3칸 밖·B 그대로 %s(A 잃은 체력 %s, 자리 %s)" % [aloft, calm, hit, _lost(a), a.pos])

# EV746 · S288: 대장은 먼저 노리는 성문이 없고, 인식 범위 안 병사를 치러 간다
func ev746():
	var b = _raid()
	var why := _need(b)
	if why == "":
		why = _no_chief(b)
	if why != "":
		return why
	var gate = b.castle.get(GATE)
	var e = b.spawn_enemy("war_machine", Vector2i(12, 16), {"hp": 10, "skills": {}})
	var had: bool = e.via != null
	b.ENEMY_KINDS.chief["skills"] = {"leap": b.ENEMY_KINDS.chief.skills.get("leap", {})}
	var m = _soldier(b, Vector2i(16, 16))
	if gate == null or m == null:
		return "성문이나 병사를 두지 못했다"
	b.damage(e, 50.0, "true")
	var free: bool = e.via == null
	var hit := run(b, 8.0, func(): return m.hp < m.max_hp)
	var kept: bool = gate.hp == gate.max_hp
	return check(had and free and hit and kept, "기계는 성문을 노림 %s · 대장은 안 노림 %s · 8초 안 병사 피해 %s · 성문 그대로 %s" % [had, free, hit, kept])

# EV747 · S288·I230: 철퇴는 가장 가까운 아군 쪽 부채꼴(120°) 0.8초 예고 뒤 그 안 아군 −40·넉백. 붙은 아군이면 철퇴가 먼저다
func ev747():
	var b = battle({"base_hp": BIG})
	var why := _no_chief(b)
	if why != "":
		return why
	var a = _soldier(b, Vector2i(10, 8))
	var back = _soldier(b, Vector2i(10, 12))
	var c = _soldier(b, Vector2i(11, 8))
	var side = _soldier(b, Vector2i(12, 10))
	var all := [a, back, c, side]
	var e = _chief(b, WM, ["cleave"])
	if not run(b, 0.1, func(): return _casting(e, "cleave")):
		return "0.1초 안에 철퇴 예고를 시작하지 않았다(cast %s)" % [e.cast]
	var north: bool = e.cast.has("dir") and absf(angle_difference(e.cast.dir, -PI / 2.0)) <= deg_to_rad(1.0)
	var d0 := [a.pos.distance_to(e.pos), c.pos.distance_to(e.pos)]
	run(b, 0.75)
	var calm: bool = all.all(func(m): return m.hp == m.max_hp)
	run(b, 0.1)
	var hit: bool = is_equal_approx(_lost(a), 40.0) and is_equal_approx(_lost(c), 40.0) and back.hp == back.max_hp and side.hp == side.max_hp
	var pushed: bool = a.pos.distance_to(e.pos) > d0[0] + 1.0 and c.pos.distance_to(e.pos) > d0[1] + 1.0
	var lost: Array = all.map(func(m): return _lost(m))
	var f = battle({"base_hp": BIG})
	_soldier(f, Vector2i(10, 9))
	var g = _chief(f, WM)
	run(f, 0.1, func(): return g.cast != null)
	var first: String = "" if g.cast == null else g.cast.get("id", "")
	return check(north and calm and hit and pushed and first == "cleave",
		"북쪽 부채꼴 %s · 0.75초 그대로 %s · 0.85초 A·C −40·B·D 그대로 %s(잃은 체력 %s) · 넉백 %s · 스킬 다 둔 대장의 첫 예고 %s(cleave여야 한다)" % [north, calm, hit, lost, pushed, first])

# EV748 · S288·I230: 돌진은 2칸 넘게 떨어진 가장 가까운 아군 쪽으로 1초 예고 뒤 6칸 옮겨 간다. 길 위 아군 −30·옆으로 1칸, 막히면 그 앞에서 멈추고 −80
func ev748():
	var b = battle({"base_hp": BIG})
	var why := _no_chief(b)
	if why != "":
		return why
	var a = _soldier(b, Vector2i(10, 6))
	var e = _chief(b, WM, ["charge"])
	if not run(b, 0.1, func(): return _casting(e, "charge")):
		return "0.1초 안에 돌진 예고를 시작하지 않았다(cast %s)" % [e.cast]
	var at: Vector2 = e.pos
	run(b, 0.95)
	var held: bool = e.pos.distance_to(at) <= 0.01 and a.hp == a.max_hp
	run(b, 0.15)
	var went: bool = e.pos.distance_to(Vector2(10, 4)) <= 0.1 and is_equal_approx(_lost(a), 30.0) and absf(a.pos.x - 9.0) <= 0.15
	var where := [e.pos, a.pos, _lost(a)]
	var c = battle({"base_hp": BIG})
	var n = _soldier(c, Vector2i(10, 6))
	var w = c.build("wall", Vector2i(10, 5))
	if n == null or w == null:
		return "병사나 방벽을 두지 못했다"
	c.finish(w)
	var f = _chief(c, WM, ["charge"])
	run(c, 0.1, func(): return _casting(f, "charge"))
	run(c, 1.1)
	var stop: bool = f.pos.distance_to(Vector2(10, 5.5)) <= 0.1 and is_equal_approx(w.max_hp - w.hp, 80.0) and is_equal_approx(_lost(n), 30.0)
	return check(held and went and stop,
		"0.95초 그대로 %s · 1.1초 (10,4)·A −30·x 9 %s(대장·A 자리, A 잃은 체력 %s) · 방벽 앞 (10,5.5) 멈춤·방벽 −80·병사 −30 %s(대장 %s, 방벽 잃은 체력 %s)" % [
			held, went, where, stop, f.pos, w.max_hp - w.hp])

# EV749 · S288: 집게 던지기는 1페이즈 집어 던지기와 같다. 붙은 병사를 0.8초 뒤 대장 너머 4칸에 던지고 −25
func ev749():
	var b = battle({"base_hp": BIG})
	var why := _no_chief(b)
	if why != "":
		return why
	var a = _soldier(b, Vector2i(10, 9))
	var e = _chief(b, WM, ["fling"])
	if not run(b, 0.1, func(): return _casting(e, "fling")):
		return "0.1초 안에 집게 던지기 예고를 시작하지 않았다(cast %s)" % [e.cast]
	run(b, 0.75)
	var held: bool = a.pos.distance_to(Vector2(10, 9)) <= 0.5 and a.hp == a.max_hp
	run(b, 0.15)
	var thrown: bool = a.pos.distance_to(Vector2(10, 14)) <= 1.0 and is_equal_approx(_lost(a), 25.0)
	return check(held and thrown, "0.75초 그대로 %s · 0.9초 (10,14) 1칸 안·−25 %s(자리 %s, 잃은 체력 %s)" % [held, thrown, a.pos, _lost(a)])

# EV750 · S288: 폭탄은 4칸 안 땅 아군 가운데 서로 1.5칸 넘게 떨어진 세 자리에 원(반경 0.8)을 0.8초 예고한 뒤 원마다 −25
func ev750():
	var b = battle({"base_hp": BIG})
	var why := _no_chief(b)
	if why != "":
		return why
	var cells := [Vector2i(10, 7), Vector2i(11, 7), Vector2i(13, 10), Vector2i(10, 13), Vector2i(10, 15)]
	var ms: Array = cells.map(func(c): return _soldier(b, c))
	var e = _chief(b, WM, ["bombs"])
	if not run(b, 0.1, func(): return _casting(e, "bombs")):
		return "0.1초 안에 폭탄 예고를 시작하지 않았다(cast %s)" % [e.cast]
	var spots: Array = e.cast.get("spots", [])
	var want := [Vector2(10, 7), Vector2(13, 10), Vector2(10, 13)]
	var placed: bool = spots.size() == 3 and range(3).all(func(i): return Vector2(spots[i]).distance_to(want[i]) <= 0.1)
	run(b, 0.75)
	var calm: bool = ms.all(func(m): return m.hp == m.max_hp)
	run(b, 0.1)
	var hit: bool = [0, 2, 3].all(func(i): return is_equal_approx(_lost(ms[i]), 25.0)) and [1, 4].all(func(i): return ms[i].hp == ms[i].max_hp)
	return check(placed and calm and hit, "자리 셋(A·C·D) %s(%s) · 0.75초 그대로 %s · 0.85초 A·C·D −25·B·E 그대로 %s(잃은 체력 %s)" % [
		placed, spots, calm, hit, ms.map(func(m): return _lost(m))])

# EV751 · S288: 체력 25% 이하면 분노(이동 +30%), 봉인되면 꺼진다
func ev751():
	var b = battle({"base_hp": BIG})
	var why := _no_chief(b)
	if why != "":
		return why
	var rage: Dictionary = b.ENEMY_KINDS.chief.get("skills", {}).get("rage", {})
	var e = _chief(b, WM, ["rage"], {"hp": 100.0})
	e.hp = 30.0
	var calm: bool = not b.raging(e)
	e.hp = 20.0
	var mad: bool = b.raging(e)
	e.fx["test_seal"] = {"seal": true, "left": 1.0}
	var sealed: bool = not b.raging(e)
	var walked := []
	for hp in [100.0, 20.0]:
		var c = battle({"base_hp": BIG})
		var f = c.spawn_enemy("chief", Vector2i(5, 10), {"hp": 100.0, "skills": {"rage": rage}})
		f.hp = hp
		var p0: Vector2 = f.pos
		run(c, 1.0)
		walked.append(f.pos.distance_to(p0))
	var ratio: float = walked[1] / walked[0] if walked[0] > 0.0 else 0.0
	return check(calm and mad and sealed and absf(ratio - 1.3) <= 0.05,
		"체력 30 분노 아님 %s · 20 분노 %s · 봉인이면 꺼짐 %s · 걸은 거리 %s(비 %.3f, 1.3이어야 한다)" % [calm, mad, sealed, walked, ratio])

# EV752 · S288·S194: 돌진 예고 중 기절이면 취소되고(대장은 그 자리) 비틀거린다
func ev752():
	var b = battle({"base_hp": BIG})
	var why := _no_chief(b)
	if why != "":
		return why
	var a = _soldier(b, Vector2i(10, 6))
	var e = _chief(b, WM, ["charge"])
	if not run(b, 0.1, func(): return _casting(e, "charge")):
		return "0.1초 안에 돌진 예고를 시작하지 않았다(cast %s)" % [e.cast]
	run(b, 0.5)
	_stun(e)
	b.step(DT)
	var off: bool = e.cast == null
	run(b, 0.65)
	var stay: bool = e.pos.distance_to(Vector2(10, 10)) <= 0.1 and a.hp == a.max_hp
	var reel = b.effect(e, "expose")
	var stagger: bool = reel != null and is_equal_approx(reel, 0.5)
	return check(off and stay and stagger, "취소 %s · 1.2초 그 자리·A 그대로 %s(대장 %s) · 비틀거림 %s" % [off, stay, e.pos, stagger])
