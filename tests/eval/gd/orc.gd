extends "res://tests/eval/gd/sky.gd"
# 5라운드 오크 전쟁패 묶음 ①(S318~S321·I263~I265). lib.gd·sky.gd 머리의 계약에 더하는 API:
#   적 kind "shield_orc"(방패벽 오크, S319) · "berserker"(광전사 오크, S320) · "drummer"(전쟁 북 고수, S321)
#   Battle.nearest(구조물·거점, 자리) — 가장 가까운 차지 칸 가운데(I178) · 용병 overrides accuracy(명중률)
# 판은 lib.gd battle()의 들판(30×20, 거점 (25,10))이다. 움직이지 않는 적도 거점을 노려서 정면은 동쪽이다(I263 ③)

const SO := "shield_orc"
const BK := "berserker"
const DR := "drummer"
const SHOT := {"damage": 10, "accuracy": 1.0}  # 늘 맞는 궁수

# 방패벽 오크 둘을 (10,10)과 (10,y)에 둔 판. [판, (10,10) 오크, 둘째 오크]
func _pair(y: float) -> Array:
	var b = battle()
	return [b, _still(b, SO, Vector2(10, 10)), _still(b, SO, Vector2(10, y))]

# es 가운데 하나라도 체력이 줄 때까지 돌려, 그 스텝에 가장 많이 준 체력. secs 안에 안 줄면 -1
func _drop(b, es: Array, secs := 20.0) -> float:
	var was: Array = es.map(func(e): return e.hp)
	var t := 0.0
	while t < secs:
		b.step(DT)
		t += DT
		var most := 0.0
		for i in es.size():
			most = maxf(most, was[i] - es[i].hp)
		if most > 0.0:
			return most
	return -1.0

# got ÷ base가 want에서 2% 안이다
func _ratio(got: float, base: float, want: float) -> bool:
	return got > 0.0 and base > 0.0 and absf(got / base / want - 1.0) <= 0.02

# x가 1초(20스텝)에 나아간 거리
func _walked(b, x) -> float:
	var from: Vector2 = x.pos
	_steps(b, 20)
	return x.pos.distance_to(from)

# 병사 (10,10) 옆 (11,10)에 kind 적(속도 0, 피해 1)을 세운 판. [판, 병사, 적]
func _duel(kind: String, over := {}) -> Array:
	var r := _one("soldier", Vector2i(10, 10), {"hp": BIG, "damage": 0})
	return [r[0], r[1], _still(r[0], kind, Vector2(11, 10), {"damage": 1, "sight": 3}.merged(over, true))]

# u의 체력이 주는 때의 평균 간격(10초). 세 번 못 맞으면 -1
func _gap(b, u) -> float:
	var times := []
	var t := 0.0
	var h0: float = u.hp
	while t < 10.0:
		b.step(DT)
		t += DT
		if u.hp < h0:
			times.append(t)
			h0 = u.hp
	return (times[-1] - times[0]) / (times.size() - 1) if times.size() >= 3 else -1.0

# EV898 · S319: 정면의 궁수 화살은 붙은 방패벽 오크에 절반만 들고, 붙지 않았거나 뒤에서 쏘면 그대로 든다
func ev898():
	var got := []
	for c in [[12.0, 13], [11.0, 13], [11.0, 7]]:  # [둘째 오크 y, 궁수 x]
		var p := _pair(c[0])
		var why := _need(p[0], [SO])
		if why != "":
			return why
		p[0].place_merc("archer", Vector2i(c[1], 10), SHOT)
		got.append(_drop(p[0], [p[1]]))
	return check(_ratio(got[1], got[0], 0.5) and _ratio(got[2], got[0], 1.0),
		"(10,10) 오크가 화살에 처음 준 체력: 붙지 않음 %.3f · 붙음 %.3f(0.5배) · 붙었고 뒤에서 %.3f(같음)" % got)

# EV899 · S319: 방패벽 둘레 2칸 안 적도 절반만 받는다. 마법 타워 구슬은 절반, 대포알·병사 근접은 그대로다
func ev899():
	var arrow := []
	for c in [[13, 16], [11, 14]]:  # [기본 적 x, 궁수 x]
		var p := _pair(11.0)
		var why := _need(p[0], [SO])
		if why != "":
			return why
		var e = _still(p[0], "basic", Vector2(c[0], 10))
		p[0].place_merc("archer", Vector2i(c[1], 10), SHOT)
		arrow.append(_drop(p[0], [e]))
	if not _ratio(arrow[1], arrow[0], 0.5):
		return "기본 적이 화살에 처음 준 체력: 오크에서 2칸 밖 %.3f · 1칸 %.3f(0.5배)" % arrow
	var got := {}
	for how in ["magic", "cannon", "soldier"]:
		got[how] = []
		for y in [12.0, 11.0]:
			var p := _pair(y)
			if how == "soldier":
				p[0].place_merc("soldier", Vector2i(11, 10))
			elif p[0].build(how, Vector2i(15, 10)) == null:
				return "%s를 (15,10)에 짓지 못했다" % how
			got[how].append(_drop(p[0], [p[1], p[2]]))
	return check(_ratio(got.magic[1], got.magic[0], 0.5) and _ratio(got.cannon[1], got.cannon[0], 1.0) and _ratio(got.soldier[1], got.soldier[0], 1.0),
		"오크가 처음 준 체력 [붙지 않음, 붙음]: 마법 타워 %s(0.5배) · 대포 %s(같음) · 병사 %s(같음)" % [got.magic, got.cannon, got.soldier])

# EV900 · S319: 짝이 기절·봉인되면 방패벽이 꺼져 그대로 맞는다
func ev900():
	var p := _pair(12.0)
	var why := _need(p[0], [SO])
	if why != "":
		return why
	p[0].place_merc("archer", Vector2i(13, 10), SHOT)
	var lone := _drop(p[0], [p[1]])
	var got := []
	for key in ["stun", "seal"]:
		var q := _pair(11.0)
		q[2].fx["test_" + key] = {key: true, "left": BIG}
		q[0].place_merc("archer", Vector2i(13, 10), SHOT)
		got.append(_drop(q[0], [q[1]]))
	return check(_ratio(got[0], lone, 1.0) and _ratio(got[1], lone, 1.0), "(10,10) 오크가 처음 준 체력: 붙지 않음 %.3f · 짝 기절 %.3f · 짝 봉인 %.3f(셋이 같아야 한다)" % [lone, got[0], got[1]])

# EV901 · S320: 광전사 오크는 잃은 체력 비율만큼 빨리 걷고 빨리 친다. 봉인되면 꺼진다
func ev901():
	var moved := []
	for c in [[100.0, false], [50.0, false], [50.0, true]]:  # [체력, 봉인]
		var b = battle()
		var why := _need(b, [BK])
		if why != "":
			return why
		var e = b.spawn_enemy(BK, Vector2i(3, 10), {"hp": 100.0, "sight": 0, "damage": 0})
		e.hp = c[0]
		if c[1]:
			e.fx["test_seal"] = {"seal": true, "left": BIG}
		moved.append(_walked(b, e))
	if absf(moved[0] - 1.8) > 0.1 or absf(moved[1] - 2.25) > 0.1 or absf(moved[2] - 1.8) > 0.1:
		return "1초에 나아간 칸: 가득 %.3f(1.8) · 체력 50 %.3f(2.25) · 체력 50에 봉인 %.3f(1.8)" % moved
	var gaps := []
	for c in [[100.0, false], [75.0, false], [75.0, true]]:
		var d := _duel(BK, {"hp": 100.0})
		d[2].hp = c[0]
		if c[1]:
			d[2].fx["test_seal"] = {"seal": true, "left": BIG}
		gaps.append(_gap(d[0], d[1]))
	return check(absf(gaps[0] - 1.0) <= 0.08 and absf(gaps[1] / 0.8 - 1.0) <= 0.08 and absf(gaps[2] - 1.0) <= 0.08,
		"병사를 치는 간격: 가득 %.3f(1) · 체력 75 %.3f(0.8) · 체력 75에 봉인 %.3f(1)" % gaps)

# EV902 · S321: 전쟁 북 반경 3 안의 다른 적은 이동 1.25배·공격 속도 1.3배다. 겹쳐도 같고, 북 고수는 받지 않으며, 기절·봉인이면 멈춘다
func ev902():
	var moved := {}
	for c in [["없음", [], "", "basic"], ["안", [Vector2(5, 12)], "", "basic"], ["밖", [Vector2(5, 14)], "", "basic"], ["기절", [Vector2(5, 12)], "stun", "basic"],
			["봉인", [Vector2(5, 12)], "seal", "basic"], ["둘", [Vector2(5, 12), Vector2(4, 12)], "", "basic"], ["북 고수", [Vector2(5, 12)], "", DR]]:
		var b = battle()
		var why := _need(b, [DR])
		if why != "":
			return why
		for p in c[1]:
			var d = _still(b, DR, p)
			if c[2] != "":
				d.fx["test_" + c[2]] = {c[2]: true, "left": BIG}
		moved[c[0]] = _walked(b, b.spawn_enemy(c[3], Vector2i(3, 10), {"sight": 0, "damage": 0, "hp": BIG}))
	var want := {"없음": 2.0, "안": 2.5, "밖": 2.0, "기절": 2.0, "봉인": 2.0, "둘": 2.5, "북 고수": 1.5}
	for k in want:
		if absf(moved[k] - want[k]) > 0.1:
			return "1초에 나아간 칸 %s(%s여야 한다)" % [moved, want]
	var plain := _duel("basic")
	var base := _gap(plain[0], plain[1])
	var fast := _duel("basic")
	_still(fast[0], DR, Vector2(11, 12))
	var quick := _gap(fast[0], fast[1])
	return check(absf(base - 1.0) <= 0.08 and absf(quick * 1.3 - 1.0) <= 0.08, "병사를 치는 간격: 북 없음 %.3f(1) · 북 %.3f(1 ÷ 1.3)" % [base, quick])

# EV903 · S321: 들을 적이 있으면 북 고수는 거점에서 2칸에 서서 치지 않고, 들을 적이 쓰러지면 거점을 친다
func ev903():
	var b = battle({"base_hp": BIG})
	var why := _need(b, [DR])
	if why != "":
		return why
	var ear = _still(b, "basic", Vector2(21, 12), {"hp": 100.0})
	var d = b.spawn_enemy(DR, Vector2i(15, 10), {"hp": BIG})
	var far := func(): return d.pos.distance_to(b.nearest(b.base, d.pos))
	if not run(b, 10.0, func(): return far.call() <= 2.0):
		return "북 고수가 10초 안에 거점 2칸 안에 들지 않았다(거리 %.2f)" % far.call()
	var at: Vector2 = d.pos
	var hp: float = b.base.hp
	var stopped: float = far.call()
	_steps(b, 100)
	if stopped < 1.9 or d.pos.distance_to(at) > 0.05 or b.base.hp != hp:
		return "들을 적이 있는 동안: 멈춘 거리 %.3f(1.9~2) · 5초 동안 움직인 칸 %.3f · 거점 체력 %s → %s" % [stopped, d.pos.distance_to(at), hp, b.base.hp]
	b.damage(ear, BIG)
	return check(run(b, 5.0, func(): return b.base.hp < hp), "들을 적이 쓰러진 뒤 5초 안에 거점을 치지 않았다(거리 %.2f)" % far.call())

# EV904 · I263~I265: 오크 셋은 장갑(오크) 그림에 색을 곱해 그리고, 다친 광전사는 색이 다르다. 방패벽을 선 둘은 선으로 잇고, 북 반경 고리를 그린다
# 방패벽 선은 몸통 위 층에 가슴 높이로 그린다(I263 ⑤, 락 뒤 개정)
func ev904():
	var b = battle()
	var why := _need(b, [SO, BK, DR])
	if why != "":
		return why
	var v = _rec(b)
	var got := []
	for k in ["armored", SO, BK, DR]:
		var one = _cut(v, _still(b, k, Vector2(5 + got.size() * 4, 5), {"hp": 100.0}))
		if one == null:
			v.free()
			return "%s 몸통이 그림 한 장이 아니다(%d장)" % [k, v.cuts.size()]
		got.append(one)
	var hurt = _still(b, BK, Vector2(5, 15), {"hp": 100.0})
	hurt.hp = 25.0
	var red = _cut(v, hurt)
	v.free()
	var srcs: Array = got.map(func(x): return x[1])
	if srcs.any(func(x): return x != srcs[0]):
		return "원본 사각형이 장갑과 다르다: %s" % [srcs]
	var tints: Array = got.map(func(x): return x[2])
	for i in tints.size():
		for j in range(i + 1, tints.size()):
			if tints[i] == tints[j]:
				return "색이 같다: %s" % [tints]
	if red == null or red[2] == tints[2]:
		return "체력 25%%인 광전사 오크의 색이 가득일 때와 같다(%s)" % [tints[2]]
	var linked := []
	for x in [11.0, 13.0]:
		var c = battle()
		var o1 = _still(c, SO, Vector2(10, 10))
		var o2 = _still(c, SO, Vector2(x, 10))
		c.step(DT)
		var w = _rec(c)
		if not w.has_method("_wall_links"):
			w.free()
			return "BattleView에 방패벽 선 그리기(_wall_links)가 없다"
		w._wall_links()
		var ends := [w._center(o1.pos), w._center(o2.pos)]
		linked.append(w.lines.any(func(l): return (Vector2(l[0]).distance_to(ends[0]) <= 12.0 and Vector2(l[1]).distance_to(ends[1]) <= 12.0) or (Vector2(l[0]).distance_to(ends[1]) <= 12.0 and Vector2(l[1]).distance_to(ends[0]) <= 12.0)))
		w.free()
	var kb = battle()
	var dr = _still(kb, DR, Vector2(10, 10))
	kb.step(DT)
	var u = _rec(kb)
	u._foes = u.foes()
	u._tells()
	var mid := Vector2i(u._center(dr.pos).floor())
	var ring: bool = u.rings.any(func(x): return x[0] == mid and x[1] == 48)
	var rings: Array = u.rings.duplicate()
	u.free()
	return check(linked[0] and not linked[1] and ring, "방패벽 선: 1칸 %s(있어야 한다) · 3칸 %s(없어야 한다) · 북 고리(가운데 %s, 반지름 48) %s(그린 고리 %s)" % [linked[0], linked[1], mid, ring, rings])

# ── 5라운드 오크 전쟁패 묶음 ②(S322·S323·I266·I267) ── 더하는 API:
#   적 kind "ogre_thrower"(오우거 투척꾼, S322) · "chain_orc"(사슬 오크, S323)
#   적 cast {id "hurl", left, at(떨어질 자리), who(집힌 오크)} · 뜬 오크 cast {id "hurled", air 참, at} · {id "hook", left, dir(라디안), to(띠 끝)}
#   BattleView: _foe_tells() · _chain_links() · clock

const OT := "ogre_thrower"
const CH := "chain_orc"
const MUTE := {"damage": 0, "sight": 0, "hp": BIG}  # 치지도 쫓지도 않는 궁수(사거리는 그대로라 원거리 아군이다)
const QUIET := {"damage": 0, "range": 0, "sight": 0, "hp": BIG}  # 치지도 쫓지도 않는 병사
const NIGHT := [[{"at": 0.0, "dark": 1.0, "fade": 0.05}]]  # 0초에 어둠 1인 밤 웨이브(sky.gd ev844와 같다)

func _casting(e, id: String) -> bool:
	return e.cast != null and e.cast.id == id

func _flying(e) -> bool:
	return e.cast != null and e.cast.get("air", false)

func _lost(m) -> float:
	return m.max_hp - m.hp

# 들판 판에 투척꾼(움직이지도 치지도 않음)을 (10,10)에 두고 kind 적(과녁)을 orcs 자리마다, 유닛을 mercs([종류, 칸, 수치])대로 세운다. [판, 투척꾼, 적들, 유닛들]
func _toss(orcs: Array, mercs: Array, kind := "armored") -> Array:
	var b = battle({"base_hp": BIG})
	if not b.ENEMY_KINDS.has(OT):
		return [b, null, [], []]
	var t = _still(b, OT, Vector2(10, 10))
	var os: Array = orcs.map(func(p): return _still(b, kind, p))
	var ms: Array = mercs.map(func(m): return b.place_merc(m[0], m[1], m[2]))
	return [b, t, os, ms]

# 들판 판에 사슬 오크(움직이지도 치지도 않음)를 (10,10)에 두고 치지도 쫓지도 않는 병사를 cells마다 세운다. [판, 사슬 오크, 병사들]
func _snare(cells: Array) -> Array:
	var b = battle({"base_hp": BIG})
	if not b.ENEMY_KINDS.has(CH):
		return [b, null, []]
	var e = _still(b, CH, Vector2(10, 10))
	return [b, e, cells.map(func(c): return b.place_merc("soldier", c, QUIET))]

# secs 안에 e가 id 예고를 띄웠다
func _ever(b, e, id: String, secs: float) -> bool:
	return run(b, secs, func(): return _casting(e, id))

# EV906 · S322: 옆의 장갑을 집어 2~6칸 원거리 아군 자리에 원 예고 1.2초 → 장갑이 0.6초 떠서 떨어져 원 안 아군에 12. 대기 8초 뒤 다음 오크를 집는다
func ev906():
	var g := _toss([Vector2(11, 10), Vector2(10, 11)], [["archer", Vector2i(15, 10), MUTE], ["archer", Vector2i(15, 12), MUTE]])
	var b = g[0]
	var why := _need(b, [OT])
	if why != "":
		return why
	var t = g[1]
	var a = g[2][0]
	var p = g[3][0]
	var q = g[3][1]
	if not _ever(b, t, "hurl", 0.1) or t.cast.get("at") == null or t.cast.at.distance_to(Vector2(15, 10)) > 0.1:
		return "0.1초 안에 (15,10)에 던지기 예고를 시작하지 않았다(cast %s)" % [t.cast]
	_steps(b, 22)
	if a.pos.distance_to(Vector2(11, 10)) > 0.05 or _flying(a) or p.hp != p.max_hp:
		return "예고 1.1초: 장갑 자리 %s((11,10)) · 떴다 %s · 궁수가 잃은 체력 %s(0)" % [a.pos, _flying(a), _lost(p)]
	var up := 22
	while up < 28 and not _flying(a):
		b.step(DT)
		up += 1
	if not _flying(a):
		return "예고 1.4초에 장갑이 뜨지 않았다(cast %s)" % [a.cast]
	_steps(b, 40 - up)
	if _flying(a) or a.pos.distance_to(Vector2(15, 10)) > 1.0 or a.hp != a.max_hp or not is_equal_approx(_lost(p), 12.0) or q.hp != q.max_hp:
		return "예고 2.0초: 장갑 떴다 %s · 자리 %s((15,10) 1칸 안) · 장갑이 잃은 체력 %s(0) · P %s(12) · Q %s(0)" % [_flying(a), a.pos, _lost(a), _lost(p), _lost(q)]
	var early := false
	for i in 154 - (40 - up):
		b.step(DT)
		early = early or _casting(t, "hurl")
	_steps(b, 12)
	return check(not early and _casting(t, "hurl"), "장갑이 뜬 뒤 7.7초 안에 다시 예고 %s(없어야 한다) · 8.3초에 예고 %s(있어야 한다, cast %s)" % [early, _casting(t, "hurl"), t.cast])

# EV907 · S322: 오크가 1.5칸 밖·원거리 아군 없음·대상이 2칸 안·북 고수·봉인이면 던지지 않는다. 던질 것이 없으면 붙은 병사를 친다
func ev907():
	var cases := [
		["오크가 1.5칸 밖", [Vector2(12, 10)], [["archer", Vector2i(15, 10), MUTE]], "armored", false],
		["원거리 아군 없음", [Vector2(10, 11)], [["soldier", Vector2i(15, 10), QUIET]], "armored", false],
		["대상이 2칸 안", [Vector2(10, 11)], [["archer", Vector2i(12, 10), MUTE]], "armored", false],
		["북 고수", [Vector2(10, 11)], [["archer", Vector2i(15, 10), MUTE]], DR, false],
		["봉인", [Vector2(10, 11)], [["archer", Vector2i(15, 10), MUTE]], "armored", true],
	]
	for c in cases:
		var g := _toss(c[1], c[2], c[3])
		var why := _need(g[0], [OT])
		if why != "":
			return why
		if c[4]:
			g[1].fx["test_seal"] = {"seal": true, "left": BIG}
		if _ever(g[0], g[1], "hurl", 3.0):
			return "%s: 3초 안에 던지기 예고를 시작했다(cast %s)" % [c[0], g[1].cast]
	var b = battle({"base_hp": BIG})
	var t = b.spawn_enemy(OT, Vector2i(10, 10), {"speed": 0, "hp": BIG})
	_still(b, "armored", Vector2(10, 11))
	var m = b.place_merc("soldier", Vector2i(11, 10), QUIET)
	var hit: bool = run(b, 3.0, func(): return m.hp < m.max_hp)
	return check(hit and not _casting(t, "hurl"), "던질 대상이 없는 투척꾼이 3초 안에 붙은 병사를 쳤다 %s · 예고 %s" % [hit, t.cast])

# EV908 · S322: 예고 중 투척꾼이 기절하면 취소되고 집힌 장갑이 다시 걷는다. 집힌 장갑이 쓰러져도 취소되고, 대기는 취소된 때부터 8초다
func ev908():
	var g := _toss([], [["archer", Vector2i(15, 10), MUTE]])
	var b = g[0]
	var why := _need(b, [OT])
	if why != "":
		return why
	var t = g[1]
	var p = g[3][0]
	var a = b.spawn_enemy("armored", Vector2i(11, 10), {"sight": 0, "damage": 0, "hp": BIG})
	if not _ever(b, t, "hurl", 0.1):
		return "0.1초 안에 던지기 예고를 시작하지 않았다(cast %s)" % [t.cast]
	var from: Vector2 = a.pos
	_steps(b, 10)
	var held: bool = a.pos.distance_to(from) <= 0.05
	t.fx["test_stun"] = {"stun": true, "left": 1.0}
	b.step(DT)
	var off: bool = t.cast == null and not _flying(a)
	_steps(b, 20)
	var walked: float = a.pos.distance_to(from)
	_steps(b, 30)
	if not (held and off and walked > 1.0 and p.hp == p.max_hp):
		return "기절: 0.5초 동안 장갑이 서 있었다 %s · 다음 스텝에 예고 없음·안 뜸 %s · 그 뒤 1초에 걸은 칸 %.2f(1 넘게) · 궁수가 잃은 체력 %s(0)" % [held, off, walked, _lost(p)]
	var h := _toss([Vector2(11, 10), Vector2(10, 11)], [["archer", Vector2i(15, 10), MUTE]])
	var c = h[0]
	var u = h[1]
	var dead = h[2][0]
	dead.hp = 100.0
	if not _ever(c, u, "hurl", 0.1):
		return "둘째 판: 0.1초 안에 던지기 예고를 시작하지 않았다(cast %s)" % [u.cast]
	_steps(c, 10)
	c.damage(dead, BIG)
	c.step(DT)
	var cut: bool = u.cast == null
	var early := false
	for i in 154:
		c.step(DT)
		early = early or _casting(u, "hurl")
	_steps(c, 12)
	return check(cut and not early and _casting(u, "hurl"), "집힌 장갑이 쓰러진 다음 스텝에 예고 없음 %s · 그 뒤 7.7초 안에 다시 예고 %s(없어야 한다) · 8.3초에 예고 %s(있어야 한다)" % [cut, early, _casting(u, "hurl")])

# EV909 · S322: 성벽 위 궁수도 던질 대상이다. 장갑은 그 성벽 위에 떨어져 궁수를 친다
func ev909():
	var b = _castle()
	var why := _need(b, [OT])
	if why != "":
		return why
	var m = _up(b, "archer", Vector2i(14, 9), MUTE)
	if m == null:
		return "궁수를 성벽 위 (14,9)에 올리지 못했다"
	var t = _still(b, OT, Vector2(14, 13))
	var a = b.spawn_enemy("armored", Vector2i(15, 13), {"speed": 0, "hp": BIG})
	if not _ever(b, t, "hurl", 0.1) or t.cast.get("at") == null or t.cast.at.distance_to(m.pos) > 0.1:
		return "0.1초 안에 궁수 자리 %s에 던지기 예고를 시작하지 않았다(cast %s)" % [m.pos, t.cast]
	_steps(b, 40)
	var lost := _lost(m)
	if not a.on_wall or a.pos.distance_to(Vector2(14, 9)) > 0.5 or lost < 12.0 - 0.001:
		return "예고 2.0초: 장갑 성벽 위 %s · 자리 %s((14,9) 0.5칸 안) · 궁수가 잃은 체력 %s(12 이상)" % [a.on_wall, a.pos, lost]
	return check(run(b, 3.0, func(): return _lost(m) > lost), "떨어진 장갑이 3초 안에 궁수를 더 치지 않았다(잃은 체력 %s)" % _lost(m))

# EV910 · S323: 1.5~5칸의 땅 위 아군 쪽으로 직선 예고 1초 → 띠 안 가장 가까운 아군이 8을 잃고 오크 앞 1칸으로 끌려온다. 띠에서 비키면 빗나간다
func ev910():
	var g := _snare([Vector2i(13, 10)])
	var b = g[0]
	var why := _need(b, [CH])
	if why != "":
		return why
	var e = g[1]
	var m = g[2][0]
	if not _ever(b, e, "hook", 0.1) or e.cast.get("dir") == null or e.cast.get("to") == null:
		return "0.1초 안에 사슬 예고를 시작하지 않았다(cast %s)" % [e.cast]
	if absf(rad_to_deg(angle_difference(0.0, e.cast.dir))) > 1.0 or e.cast.to.distance_to(Vector2(15, 10)) > 0.3:
		return "예고 방향 %.1f°(0°) · 띠 끝 %s((15,10))" % [rad_to_deg(e.cast.dir), e.cast.to]
	_steps(b, 18)
	var kept: bool = m.pos.distance_to(Vector2(13, 10)) <= 0.05 and m.hp == m.max_hp
	_steps(b, 5)
	if not (kept and m.pos.distance_to(Vector2(11, 10)) <= 0.1 and is_equal_approx(_lost(m), 8.0)):
		return "0.9초 그대로 %s · 1.15초 자리 %s((11,10)) · 잃은 체력 %s(8)" % [kept, m.pos, _lost(m)]
	var h := _snare([Vector2i(13, 10)])
	var n = h[2][0]
	if not _ever(h[0], h[1], "hook", 0.1):
		return "둘째 판: 0.1초 안에 사슬 예고를 시작하지 않았다"
	_steps(h[0], 10)
	n.pos = Vector2(13, 12)
	n.anchor = Vector2(13, 12)
	_steps(h[0], 13)
	if n.hp != n.max_hp or n.pos.distance_to(Vector2(13, 12)) > 0.1:
		return "띠에서 비킨 병사: 잃은 체력 %s(0) · 자리 %s((13,12))" % [_lost(n), n.pos]
	var k := _snare([Vector2i(12, 10), Vector2i(14, 10)])
	if not _ever(k[0], k[1], "hook", 0.1):
		return "셋째 판: 0.1초 안에 사슬 예고를 시작하지 않았다"
	_steps(k[0], 23)
	var near_m = k[2][0]
	var far_m = k[2][1]
	return check(near_m.pos.distance_to(Vector2(11, 10)) <= 0.1 and is_equal_approx(_lost(near_m), 8.0) and far_m.pos.distance_to(Vector2(14, 10)) <= 0.05 and far_m.hp == far_m.max_hp,
		"둘이 줄에 선 판: 가까운 병사 자리 %s((11,10))·잃은 체력 %s(8) · 먼 병사 자리 %s((14,10))·잃은 체력 %s(0)" % [near_m.pos, _lost(near_m), far_m.pos, _lost(far_m)])

# EV911 · S323: 1.5칸 안·5칸 밖·선이 막힘·봉인·성벽 위 아군이면 사슬을 던지지 않는다. 예고 중 기절하면 취소되고 대기는 취소된 때부터 7초다
func ev911():
	for c in [["1.5칸 안", Vector2i(11, 10), false, false], ["5칸 밖", Vector2i(16, 10), false, false], ["선이 막힘", Vector2i(13, 10), true, false], ["봉인", Vector2i(13, 10), false, true]]:
		var g := _snare([c[1]])
		var why := _need(g[0], [CH])
		if why != "":
			return why
		if c[2]:
			var w = g[0].build("wall", Vector2i(12, 10))
			if w == null:
				return "(12,10)에 방벽을 짓지 못했다"
			g[0].finish(w)
		if c[3]:
			g[1].fx["test_seal"] = {"seal": true, "left": BIG}
		if _ever(g[0], g[1], "hook", 3.0):
			return "%s: 3초 안에 사슬 예고를 시작했다(cast %s)" % [c[0], g[1].cast]
	var cb = _castle()
	var top = _up(cb, "soldier", Vector2i(14, 9), QUIET)
	if top == null:
		return "병사를 성벽 위 (14,9)에 올리지 못했다"
	var ce = _still(cb, CH, Vector2(14, 12))
	if _ever(cb, ce, "hook", 3.0):
		return "성벽 위 병사: 3초 안에 사슬 예고를 시작했다(cast %s)" % [ce.cast]
	var s := _snare([Vector2i(13, 10)])
	var b = s[0]
	var e = s[1]
	var m = s[2][0]
	if not _ever(b, e, "hook", 0.1):
		return "0.1초 안에 사슬 예고를 시작하지 않았다(cast %s)" % [e.cast]
	_steps(b, 10)
	e.fx["test_stun"] = {"stun": true, "left": 1.0}
	b.step(DT)
	var cut: bool = e.cast == null
	var early := false
	for i in 134:
		b.step(DT)
		early = early or _casting(e, "hook")
		if i == 11 and (m.pos.distance_to(Vector2(13, 10)) > 0.05 or m.hp != m.max_hp):
			return "끊긴 사슬: 1.15초에 병사 자리 %s((13,10)) · 잃은 체력 %s(0)" % [m.pos, _lost(m)]
	_steps(b, 12)
	return check(cut and not early and _casting(e, "hook"), "기절한 다음 스텝에 예고 없음 %s · 그 뒤 6.7초 안에 다시 예고 %s(없어야 한다) · 7.3초에 예고 %s(있어야 한다)" % [cut, early, _casting(e, "hook")])

# EV912 · I266·I267: 투척꾼은 오우거 그림, 사슬 오크는 장갑 그림에 색을 곱해 그린다. 던지기 원 예고는 고리로(오크가 뜬 동안에도, 투척꾼이 숨어도),
# 사슬 직선 예고는 띠 테두리 선 넷으로(숨으면 그리지 않는다), 빗나간 사슬은 오크에서 띠 끝까지 선으로 그린다
func ev912():
	var b = battle()
	var why := _need(b, [OT, CH])
	if why != "":
		return why
	var v = _rec(b)
	var got := {}
	var n := 0
	for k in ["boss", OT, "armored", CH, SO, BK, DR]:
		var one = _cut(v, _still(b, k, Vector2(3 + n * 3, 5 + 6 * (n % 2)), {"hp": 100.0}))
		n += 1
		if one == null:
			v.free()
			return "%s 몸통이 그림 한 장이 아니다(%d장)" % [k, v.cuts.size()]
		got[k] = one
	v.free()
	if got[OT][1] != got["boss"][1] or got[CH][1] != got["armored"][1]:
		return "원본 사각형: 투척꾼 %s(오우거 %s) · 사슬 오크 %s(장갑 %s)" % [got[OT][1], got["boss"][1], got[CH][1], got["armored"][1]]
	if got[OT][2] == got["boss"][2] or ["armored", SO, BK, DR].any(func(k): return got[k][2] == got[CH][2]):
		return "색이 같다: 투척꾼 %s·오우거 %s · 사슬 오크 %s·장갑 %s·방패벽 %s·광전사 %s·북 고수 %s" % [got[OT][2], got["boss"][2], got[CH][2], got["armored"][2], got[SO][2], got[BK][2], got[DR][2]]
	var g := _toss([Vector2(11, 10)], [["archer", Vector2i(15, 10), MUTE]])
	var t = g[1]
	var a = g[2][0]
	if not _ever(g[0], t, "hurl", 0.1):
		return "0.1초 안에 던지기 예고를 시작하지 않았다(cast %s)" % [t.cast]
	var w = _rec(g[0])
	if not (w.has_method("_foe_tells") and w.has_method("_chain_links")):
		w.free()
		return "BattleView에 _foe_tells·_chain_links가 없다"
	var mid := Vector2i(w._center(t.cast.at).floor())
	var told: bool = t in w.tellers()
	var col: Color = w.tell_color(t)
	w.clock = 0.0
	w._foes = w.foes()
	w._foe_tells()
	var ring: bool = w.rings.any(func(x): return x[0] == mid and x[1] == 16)
	run(g[0], 1.5, func(): return _flying(a))
	w.rings = []
	w._foes = w.foes()
	w._foe_tells()
	var air_ring: bool = _flying(a) and w.rings.any(func(x): return x[0] == mid and x[1] == 16)
	w.free()
	if not (told and col == Color("ef692f") and ring and air_ring):
		return "던지기 예고: 그리는 적에 %s · 색 %s(ef692f) · 고리(가운데 %s, 반지름 16) %s · 장갑이 뜬 동안 고리 %s" % [told, col.to_html(false), mid, ring, air_ring]
	var nb = _one("archer", Vector2i(10, 10), MUTE, {"nights": NIGHT})[0]
	_start(nb)
	run(nb, 1.0)
	var nt = _still(nb, OT, Vector2(5, 10))
	_still(nb, "armored", Vector2(5, 11))
	var nc = _still(nb, CH, Vector2(6, 8))
	_steps(nb, 2)
	if nb.dark < 1.0 or nb.seen(nt.pos) or nb.seen(nc.pos) or not _casting(nt, "hurl") or not _casting(nc, "hook"):
		return "시험 조건이 틀렸다: 어둠 %.2f · 투척꾼이 보인다 %s · 사슬 오크가 보인다 %s · 예고 %s / %s" % [nb.dark, nb.seen(nt.pos), nb.seen(nc.pos), nt.cast, nc.cast]
	var nv = load("res://src/ui/battle_view.gd").new()
	nv.battle = nb
	var tell: Array = nv.tellers()
	var hid := [nt in tell, nc in tell]
	nv.free()
	if not hid[0] or hid[1]:
		return "밤 판: 숨은 투척꾼의 예고를 그림 %s(그려야 한다) · 숨은 사슬 오크의 예고를 그림 %s(그리지 않아야 한다)" % hid
	var s := _snare([Vector2i(13, 10)])
	var e = s[1]
	var m = s[2][0]
	if not _ever(s[0], e, "hook", 0.1):
		return "0.1초 안에 사슬 예고를 시작하지 않았다(cast %s)" % [e.cast]
	var u = _rec(s[0])
	var from: Vector2 = u._center(e.pos)
	var to: Vector2 = u._center(e.cast.to)
	var shown: bool = e in u.tellers()
	u.clock = 0.0
	u._foes = u.foes()
	u._tells()
	var rim: int = u.lines.size()
	_steps(s[0], 10)
	m.pos = Vector2(13, 12)
	m.anchor = Vector2(13, 12)
	if not run(s[0], 1.0, func(): return e.cast == null):
		u.free()
		return "사슬 예고가 1.5초 안에 끝나지 않았다"
	var links := func() -> bool:
		u.lines = []
		u._chain_links()
		return u.lines.any(func(l): return Vector2(l[0]).distance_to(from) <= 12.0 and Vector2(l[1]).distance_to(to) <= 12.0)
	var drawn: bool = links.call()
	_steps(s[0], 10)
	var gone: bool = not links.call()
	u.free()
	return check(shown and rim == 4 and drawn and gone and m.hp == m.max_hp, "사슬 예고: 그리는 적에 %s · 띠 테두리 선 %d(4) · 빗나간 다음 스텝에 사슬 선 %s · 0.5초 뒤 사슬 선 없음 %s · 병사가 잃은 체력 %s(0)" % [shown, rim, drawn, gone, _lost(m)])
