extends "res://tests/eval/gd/lib.gd"
# lib.gd 머리의 계약에 더하는 API: 적 cast(예고 중인 스킬, 없으면 null, S194) · fx(출처 → {효과 키: 값, left: 남은 초})
#   Battle.effect(대상, 키) · Battle.raging(적) · 오우거는 kind "boss"(S195)
# 기절·봉인은 적 fx에 직접 넣어 건다(효과를 거는 스킬과 상관없이 S194만 재려고)

const OGRE := Vector2i(10, 10)

# 오우거와 그 둘레 1칸에 가만히 선 땅 위 용병 n명(체력 큼, 치지 않음)
func _ogre(n: int, over := {}):
	var b = battle({"base_hp": BIG})
	var e = b.spawn_enemy("boss", OGRE, over)
	var ms := []
	for c in [Vector2i(11, 10), Vector2i(10, 9), Vector2i(10, 11)].slice(0, n):
		ms.append(b.place_merc("soldier", c, {"hp": BIG, "damage": 0, "range": 0, "sight": 0}))
	return [b, e, ms]

func _lost(m) -> float:
	return m.max_hp - m.hp

# EV375 · S195: 셋이면 1.2초 예고(자리를 지키고 치지 않음) 뒤 물리 30·넉백·둔화 30%
func ev375():
	var s = _ogre(3)
	var b = s[0]
	var e = s[1]
	var ms: Array = s[2]
	run(b, DT)
	if e.cast == null:
		return "용병 셋이 붙었는데 예고를 시작하지 않았다"
	var at: Vector2 = e.pos
	var d0: Array = ms.map(func(m): return m.pos.distance_to(e.pos))
	run(b, 1.05)
	var held: bool = e.pos.distance_to(at) <= 0.01 and ms.all(func(m): return m.hp == m.max_hp)
	run(b, 0.2)
	var hit: bool = ms.all(func(m): return is_equal_approx(_lost(m), 30.0))
	var pushed := true
	for i in ms.size():
		pushed = pushed and ms[i].pos.distance_to(e.pos) > d0[i] + 0.5
	var slowed: bool = ms.all(func(m): return b.effect(m, "slow") != null and is_equal_approx(b.effect(m, "slow"), 0.3))
	return check(held and hit and pushed and slowed, "예고 중 자리·무피해 %s · 피해 30 %s · 넉백 %s · 둔화 0.3 %s" % [held, hit, pushed, slowed])

# EV376 · S195: 둘이면 예고하지 않는다. 강타 뒤 11초는 다시 예고하지 않고, 13초 안에는 다시 예고한다
func ev376():
	var s = _ogre(2)
	var b = s[0]
	var e = s[1]
	var two_quiet := not run(b, 3.0, func(): return e.cast != null)
	s = _ogre(3)
	b = s[0]
	e = s[1]
	var ms: Array = s[2]
	if not run(b, 2.0, func(): return b.effect(ms[0], "slow") != null):
		return "용병 셋인데 강타하지 않았다"
	var spots := [Vector2(11, 10), Vector2(10, 9), Vector2(10, 11)]
	var calm := true
	var t := 0.0
	while t < 11.0:
		for i in ms.size():  # 오우거 둘레 1칸으로 되돌려 둔다(밀려나도)
			ms[i].pos = e.pos + (spots[i] - Vector2(OGRE))
		calm = calm and e.cast == null
		b.step(DT)
		t += DT
	var again := run(b, 2.0, func():
		for i in ms.size():
			ms[i].pos = e.pos + (spots[i] - Vector2(OGRE))
		return e.cast != null)
	return check(two_quiet and calm and again, "둘이면 예고 없음 %s · 11초 대기 %s · 13초 안에 다시 %s" % [two_quiet, calm, again])

# EV377 · S194: 예고 중 기절이면 취소되고 2초 비틀거린다(받는 피해 +50%)
func ev377():
	var s = _ogre(3)
	var b = s[0]
	var e = s[1]
	var ms: Array = s[2]
	run(b, 0.5)
	if e.cast == null:
		return "0.5초에 예고 중이 아니다"
	e.fx["test_stun"] = {"stun": true, "left": 1.0}
	run(b, 0.9)
	var spared: bool = ms.all(func(m): return m.hp == m.max_hp)
	var reeling = b.effect(e, "expose")
	var stagger: bool = reeling != null and is_equal_approx(reeling, 0.5)
	var cancelled: bool = e.cast == null
	run(b, 1.2)
	var over: bool = b.effect(e, "expose") == null
	return check(spared and stagger and cancelled and over, "강타 안 듦 %s · 1.4초 비틀거림 0.5 %s · 예고 취소 %s · 2.6초 풀림 %s" % [spared, stagger, cancelled, over])

# EV378 · S194: 봉인 중엔 예고하지 않고, 예고 중 봉인되면 비틀거림 없이 취소된다
func ev378():
	var s = _ogre(3)
	var b = s[0]
	var e = s[1]
	e.fx["test_seal"] = {"seal": true, "left": 10.0}
	var quiet := not run(b, 3.0, func(): return e.cast != null)
	s = _ogre(3)
	b = s[0]
	e = s[1]
	run(b, 0.5)
	if e.cast == null:
		return "0.5초에 예고 중이 아니다"
	e.fx["test_seal"] = {"seal": true, "left": 10.0}
	run(b, DT)
	return check(quiet and e.cast == null and b.effect(e, "expose") == null,
		"봉인 중 예고 없음 %s · 봉인하면 취소 %s · 비틀거림 없음 %s" % [quiet, e.cast == null, b.effect(e, "expose") == null])

# EV379 · S195: 체력 50% 이하면 이동 ×1.3·공격 속도 +50%, 봉인하면 꺼진다
func ev379():
	var walked := []
	for v in [[0.5, false], [0.5, true]]:
		var b = battle({"base_hp": BIG})
		var e = b.spawn_enemy("boss", Vector2i(5, 10))
		e.hp = e.max_hp * v[0]
		if v[1]:
			e.fx["test_seal"] = {"seal": true, "left": 10.0}
		run(b, DT)
		var x0: float = e.pos.x
		run(b, 1.0)
		walked.append(e.pos.x - x0)
	var hits := []
	for frac in [1.0, 0.5]:
		var s = _ogre(1)
		s[1].hp = s[1].max_hp * frac
		run(s[0], 5.9)
		hits.append(roundi(_lost(s[2][0]) / s[1].damage))
	var fast: bool = absf(walked[0] - 1.2 * 1.3) <= 0.05
	var sealed: bool = absf(walked[1] - 1.2) <= 0.05
	return check(fast and sealed and hits == [3, 5], "50%% 걸음 %.3f · 봉인 걸음 %.3f · 5.9초 친 횟수(가득·50%%) %s" % [walked[0], walked[1], hits])

# EV380 · I168: 둔화 30%가 걸린 용병은 0.7배 걷는다
func ev380():
	var b = battle({"base_hp": BIG})
	var a = b.place_merc("soldier", Vector2i(5, 5))
	var c = b.place_merc("soldier", Vector2i(5, 15))
	c.fx["test_slow"] = {"slow": 0.3, "left": 10.0}
	b.order_move([a], Vector2i(15, 5))
	b.order_move([c], Vector2i(15, 15))
	run(b, 1.0)
	var ratio: float = (c.pos.x - 5.0) / (a.pos.x - 5.0) if a.pos.x > 5.0 else 0.0
	return check(absf(ratio - 0.7) <= 0.05, "걸은 거리 비율 %.3f (둔화 %.2f · 보통 %.2f)" % [ratio, c.pos.x - 5.0, a.pos.x - 5.0])
