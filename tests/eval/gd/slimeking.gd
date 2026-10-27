extends "res://tests/eval/gd/lib.gd"
# 슬라임 킹(S235). lib.gd 머리의 계약에 더하는 API:
#   적 kind "slime_king" · 적 cast(예고 중인 스킬 {id, left, at}. 뜬 단계면 air가 참. 없으면 null) · 적 radius · skills
#   Battle.effect(대상, 키) · Battle.missiles(투사체 목록, 각 target) · 적 fx(출처 → {효과 키: 값, left: 남은 초})
# 기절·봉인·초당 피해는 적 fx에 직접 넣어 건다(효과를 거는 스킬과 상관없이 S235만 재려고)

const KING := Vector2i(10, 10)
const STILL := {"speed": 0, "sight": 0, "damage": 0}
const MERC := {"hp": BIG, "damage": 0, "range": 0, "sight": 0}
const THREE := [Vector2i(13, 10), Vector2i(13, 9), Vector2i(13, 11)]

# 킹과 cells에 차례로 둔 땅 위 용병(체력 큼, 치지 않음). 킹에 점프가 없으면 null
func _king(cells: Array, over := STILL):
	var b = battle({"base_hp": BIG})
	if not b.ENEMY_KINDS.has("slime_king") or not b.ENEMY_KINDS.slime_king.skills.has("leap"):
		return null
	var e = b.spawn_enemy("slime_king", KING, over)
	var ms := []
	for c in cells:
		ms.append(b.place_merc("soldier", c, MERC))
	return [b, e, ms]

func _lost(m) -> float:
	return m.max_hp - m.hp

func _aloft(e) -> bool:
	return e.cast != null and e.cast.get("air", false)

func _at(e):
	return e.cast.get("at") if e.cast != null else null

# EV522 · S235: 셋이 몰린 자리로 1.2초 웅크린 뒤 0.6초 동안 곧장 뛰어, 착지 자리 둘레에 물리 30·넉백·둔화 30%
func ev522():
	var s = _king(THREE)
	if s == null:
		return "slime_king에 leap 스킬이 없다"
	var b = s[0]
	var e = s[1]
	var ms: Array = s[2]
	run(b, DT)
	var at = _at(e)
	if at == null or at.distance_to(Vector2(13, 10)) > 0.01:
		return "첫 스텝 예고 %s(착지 자리 (13,10)이어야 한다)" % [e.cast]
	run(b, 1.05)
	var held: bool = e.pos.distance_to(Vector2(KING)) <= 0.01 and ms.all(func(m): return m.hp == m.max_hp)
	run(b, 0.45)
	var mid: Vector2 = e.pos
	var flying: bool = _aloft(e) and mid.x > 10.2 and mid.x < 12.8
	run(b, 0.45)
	var landed: bool = e.cast == null and e.pos.distance_to(Vector2(13, 10)) <= 0.05
	var hit: bool = ms.all(func(m): return is_equal_approx(_lost(m), 30.0))
	var pushed: bool = ms.all(func(m): return m.pos.distance_to(Vector2(13, 10)) > 0.9)
	var slowed: bool = ms.all(func(m): return b.effect(m, "slow") != null and is_equal_approx(b.effect(m, "slow"), 0.3))
	return check(held and flying and landed and hit and pushed and slowed,
		"웅크림 중 자리·무피해 %s · 1.55초 뜬 채 %s(%s) · 2초 착지 %s(%s) · 피해 30 %s · 넉백 %s · 둔화 0.3 %s" % [held, flying, mid, landed, e.pos, hit, pushed, slowed])

# EV523 · S235: 가장 많이 몰린 자리로 뛰고, 같으면 유닛 차례가 앞선 쪽
func ev523():
	var cells := [Vector2i(14, 10), Vector2i(14, 9), Vector2i(14, 11), Vector2i(10, 14), Vector2i(9, 14), Vector2i(11, 14), Vector2i(10, 15)]
	var got := []
	for cs in [cells, cells.slice(0, 6)]:
		var s = _king(cs)
		if s == null:
			return "slime_king에 leap 스킬이 없다"
		run(s[0], DT)
		got.append(_at(s[1]))
	var ok: bool = got[0] != null and got[1] != null and got[0].distance_to(Vector2(10, 14)) <= 0.01 and got[1].distance_to(Vector2(14, 10)) <= 0.01
	return check(ok, "착지 자리(셋·넷, 셋·셋) %s((10, 14)·(14, 10)이어야 한다)" % [got])

# EV524 · S235: 곧은 선이 방벽을 지나는 자리는 고르지 않는다
func ev524():
	var s = _king([Vector2i(14, 9), Vector2i(14, 10), Vector2i(14, 11), Vector2i(15, 10), Vector2i(10, 14), Vector2i(9, 14), Vector2i(11, 14)])
	if s == null:
		return "slime_king에 leap 스킬이 없다"
	var b = s[0]
	for y in range(8, 13):
		if b.build("wall", Vector2i(12, y)) == null:
			return "칸 (12,%d)에 방벽을 짓지 못했다" % y
	run(b, DT)
	var at = _at(s[1])
	return check(at != null and at.distance_to(Vector2(10, 14)) <= 0.01, "방벽 너머 넷·트인 쪽 셋에서 착지 자리 %s((10, 14)여야 한다)" % [at])

# EV525 · S235: 웅크림은 기절(비틀거림)·봉인(그냥)에 끊기고, 뜬 동안은 끊기지 않는다
func ev525():
	var s = _king(THREE)
	if s == null:
		return "slime_king에 leap 스킬이 없다"
	var b = s[0]
	var e = s[1]
	var ms: Array = s[2]
	run(b, 0.5)
	if e.cast == null:
		return "0.5초에 웅크리고 있지 않다"
	e.fx["test_stun"] = {"stun": true, "left": 1.0}
	b.step(DT)
	var stun_cut: bool = e.cast == null and b.effect(e, "expose") != null and is_equal_approx(b.effect(e, "expose"), 0.5)
	run(b, 2.0)
	var unhurt: bool = ms.all(func(m): return m.hp == m.max_hp)
	s = _king(THREE)
	b = s[0]
	e = s[1]
	run(b, 0.5)
	e.fx["test_seal"] = {"seal": true, "left": 3.0}
	b.step(DT)
	var seal_cut: bool = e.cast == null and b.effect(e, "expose") == null
	s = _king(THREE)
	b = s[0]
	e = s[1]
	ms = s[2]
	run(b, 1.5)
	var up := _aloft(e)
	e.fx["test_stun"] = {"stun": true, "left": 1.0}
	run(b, 0.5)
	var through: bool = up and ms.all(func(m): return is_equal_approx(_lost(m), 30.0))
	return check(stun_cut and unhurt and seal_cut and through,
		"웅크림 중 기절로 끊김·비틀거림 %s · 그 뒤 무피해 %s · 봉인으로 끊김(비틀거림 없음) %s · 뜬 동안 기절에도 착지 피해 %s(1.5초에 뜸 %s)" % [stun_cut, unhurt, seal_cut, through, up])

# EV526 · S235: 뜬 동안은 타워가 노리지 않고 피해를 받지 않는다. 이미 걸린 초당 피해는 든다
func ev526():
	var s = _king(THREE)
	if s == null:
		return "slime_king에 leap 스킬이 없다"
	var b = s[0]
	var e = s[1]
	if b.build("tower", Vector2i(11, 12), {"damage": 0}) == null:
		return "칸 (11,12)에 타워를 짓지 못했다"
	var shot := false
	var t := 0.0
	while not _aloft(e) and t < 3.0:
		if t >= 1.1 and not e.fx.has("test_dot"):
			e.fx["test_dot"] = {"dot": 10.0, "left": 5.0}
		b.step(DT)
		t += DT
		shot = shot or b.missiles.any(func(m): return m.target == e)
	if not _aloft(e) or not e.fx.has("test_dot"):
		return "3초 안에 뜨지 않았거나 초당 피해를 걸기 전에 떴다"
	var before: Array = b.missiles.duplicate()
	var hp0: float = e.hp
	var air := 0.0
	var poked := false
	var aimed := false
	while _aloft(e) and air < 1.0:
		if air >= 0.25 and not poked:
			b.damage(e, 50.0)
			poked = true
		b.step(DT)
		air += DT
		aimed = aimed or b.missiles.any(func(m): return m.target == e and not m in before)
	var lost: float = hp0 - e.hp
	return check(shot and poked and not aimed and absf(lost - 10.0 * air) <= 1.0,
		"웅크리는 동안 타워가 킹을 쏨 %s · 뜬 동안 새 투사체가 킹을 노림 %s · 뜬 동안 준 체력 %.2f(초당 피해 몫 %.2f ±1, 뜬 시간 %.2f)" % [shot, aimed, lost, 10.0 * air, air])

# EV527 · S235: 체력 50%면 몸 0.8배·걷기 1.3배·공격 1.25배. 봉인되면 빨라짐만 꺼진다
func ev527():
	var walked := []
	var sizes := []
	for sealed in [false, true]:
		var b = battle({"base_hp": BIG})
		var e = b.spawn_enemy("slime_king", Vector2i(5, 10))
		if not e.skills.has("shrink"):
			return "slime_king에 shrink 스킬이 없다"
		e.hp = e.max_hp * 0.5
		if sealed:
			e.fx["test_seal"] = {"seal": true, "left": 10.0}
		run(b, DT)
		var x0: float = e.pos.x
		run(b, 1.0)
		walked.append(e.pos.x - x0)
		sizes.append(e.radius)
	var hits := []
	for frac in [1.0, 0.5]:
		var s = _king([Vector2i(11, 10)], {})
		s[1].hp = s[1].max_hp * frac
		run(s[0], 5.9)
		hits.append(roundi(_lost(s[2][0]) / s[1].damage))
	var fast: bool = absf(walked[0] - 1.0 * 1.3) <= 0.05
	var calm: bool = absf(walked[1] - 1.0) <= 0.05
	var small: bool = sizes.all(func(r): return absf(r - 0.55 * 0.8) <= 0.01)
	return check(fast and calm and small and hits == [3, 4],
		"50%% 걸음 %.3f · 봉인 걸음 %.3f · 몸 반지름 %s · 5.9초 친 횟수(가득·50%%) %s" % [walked[0], walked[1], sizes, hits])
