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
