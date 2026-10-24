extends "res://tests/eval/gd/lib.gd"
# 2026-10-25 proj-1(S178 변경·I174). lib.gd 머리의 계약에 더하는 API:
#   Battle.shots — 날아가는 원거리 기본 공격 목록(배열). 웨이브가 끝나면 빈다
#   Battle.fallen — 쓰러진 영웅·용병·적 {who, age} · Battle.sell(구조물들) · Battle.cast(영웅, 칸)
#   영웅·용병·구조물: target(마지막으로 쏜 적, 쏠 때 정해진다) · cooldown · 적: attacker(반격 대상)
#   BattleView(res://src/ui/battle_view.gd): battle · tick(dt) · events — 이번 프레임의 사건 {kind, ...}(I171)

const FRAME := 1.0 / 60.0

# 움직이지도 치지도 않는 과녁
func _dummy(b, cell: Vector2i, over := {}):
	return b.spawn_enemy("basic", cell, {"speed": 0, "sight": 0, "damage": 0, "hp": BIG}.merged(over, true))

# x가 처음 쏜 step까지 돌린다. [쏜 step 끝에 e 체력이 그대로인가, 쏜 때에서 e 체력이 처음 줄 때까지 초(3초 안에 안 줄면 INF)]
func _first_hit(b, x, e) -> Array:
	var shot := run(b, 5.0, func(): return x.target != null)
	var kept: bool = shot and e.hp == e.max_hp
	var t := 0.0
	while e.hp == e.max_hp and t < 3.0:
		b.step(DT)
		t += DT
	return [kept, t if e.hp < e.max_hp else INF]

# EV401 · S178: 피해는 투사체가 닿을 때다. 닿는 때는 거리 ÷ 속도(유닛은 손에서 놓는 0.08초를 더함)
func ev401():
	var want := {"tower": 0.2, "magic": 0.3, "cannon": 0.4, "archer": 0.28}
	var got := {}
	var ok := true
	for kind in want:
		var b = battle()
		var x = b.place_merc(kind, Vector2i(10, 7)) if kind == "archer" else b.build(kind, Vector2i(10, 7))
		var e = _dummy(b, Vector2i(10, 10))
		var r := _first_hit(b, x, e)
		got[kind] = r
		ok = ok and x != null and r[0] and absf(r[1] - want[kind]) <= DT + 1e-4
	return check(ok, "[쏜 step에 체력 그대로, 처음 깎인 때(초)] %s · 기대 %s ± %s" % [got, want, DT])

# EV402 · S178: 처치(쓰러짐·골드)와 반격 대상 지정도 화살이 닿을 때다
func ev402():
	var b = battle()
	var t = b.build("tower", Vector2i(10, 7))
	var e = _dummy(b, Vector2i(10, 10), {"hp": 1})
	var g0: int = b.gold
	run(b, 5.0, func(): return t.target != null)
	var alive_at_fire: bool = e.alive and b.gold == g0
	run(b, 3.0, func(): return not e.alive)
	var fell: bool = not e.alive and b.fallen.any(func(f): return f.who == e) and b.gold == g0 + e.reward
	var b2 = battle()
	var t2 = b2.build("tower", Vector2i(10, 7))
	var e2 = _dummy(b2, Vector2i(10, 10))
	run(b2, 5.0, func(): return t2.target != null)
	var none_at_fire: bool = t2.target == e2 and e2.attacker == null
	run(b2, 3.0, func(): return e2.hp < e2.max_hp)
	var counter: bool = e2.hp < e2.max_hp and e2.attacker == t2
	return check(alive_at_fire and fell and none_at_fire and counter,
		"쏜 step에 살아 있고 골드 그대로 %s · 닿는 step에 쓰러짐·쓰러진 몸·골드 %s · 쏜 step에 반격 대상 없음 %s · 닿는 step에 그 타워 %s" % [alive_at_fire, fell, none_at_fire, counter])

# 구조물 kind가 A(10,10)를 처음 쏜 직후까지 돌린 판. [판, 구조물, A]
func _fired(kind: String) -> Array:
	var b = battle()
	var s = b.build(kind, Vector2i(10, 7))
	var a = _dummy(b, Vector2i(10, 10))
	return [b, s, a]

# EV403 · S178: 날아가는 중 대상이 쓰러지면 화살은 사라지고 대포알은 마지막 자리에 떨어진다. 대포알은 대상을 따라가 닿은 자리가 범위의 가운데다
func ev403():
	var r := _fired("tower")
	var b = r[0]
	var near_a = _dummy(b, Vector2i(11, 10))
	run(b, 5.0, func(): return r[1].target != null)
	b.damage(r[2], BIG, "true")
	r[1].range = 0.0
	run(b, 1.0)
	var gone: bool = near_a.hp == near_a.max_hp and b.shots.is_empty()
	r = _fired("cannon")
	b = r[0]
	near_a = _dummy(b, Vector2i(11, 10))
	run(b, 5.0, func(): return r[1].target != null)
	b.damage(r[2], BIG, "true")
	r[1].range = 0.0
	run(b, 1.0)
	var dropped: bool = near_a.hp < near_a.max_hp
	r = _fired("cannon")
	b = r[0]
	var by_new = _dummy(b, Vector2i(14, 10))
	var by_old = _dummy(b, Vector2i(9, 10))
	run(b, 5.0, func(): return r[1].target != null)
	var aimed: bool = r[1].target == r[2]
	r[2].pos = Vector2(13, 10)
	r[1].range = 0.0
	run(b, 1.0)
	var follow: bool = aimed and r[2].hp < r[2].max_hp and by_new.hp < by_new.max_hp and by_old.hp == by_old.max_hp
	return check(gone and dropped and follow,
		"화살: 대상이 쓰러지면 옆 적 그대로·투사체 없음 %s · 대포알: 마지막 자리에 떨어져 옆 적 깎임 %s · 옮긴 대상을 따라가 옮긴 자리 옆만 깎임 %s" % [gone, dropped, follow])

# EV404 · S178: 웨이브가 끝나면 날아가던 투사체는 사라진다. 근접은 그대로 친 step에 피해를 준다
func ev404():
	var b = battle({"base_hp": BIG, "waves": [[{"kind": "basic", "count": 1}], [{"kind": "basic", "count": 1}]]})
	var c = b.build("cannon", Vector2i(5, 7))
	b.start_battle()
	var shot := run(b, 30.0, func(): return c.target != null)
	var e = c.target
	if e:
		b.damage(e, BIG, "true")
	b.step(DT)
	var cleared: bool = shot and b.state == "prep" and b.shots.is_empty()
	var b2 = battle()
	var s = b2.place_merc("soldier", Vector2i(10, 9))
	var foe = _dummy(b2, Vector2i(10, 10))
	run(b2, 5.0, func(): return s.target != null)
	var melee: bool = s.target == foe and foe.hp < foe.max_hp
	return check(cleared and melee, "대포알이 나는 중에 웨이브가 끝나면 준비 단계·투사체 없음 %s(%s) · 근접은 친 step에 깎임 %s" % [cleared, b.state, melee])

# EV405 · I174: 팔린 타워의 화살도 닿지만 반격 대상은 생기지 않는다. 실비아 W는 대상마다 화살이 따로 나고, 마나·중첩은 쏠 때 정한다
func ev405():
	var r := _fired("tower")
	var b = r[0]
	run(b, 5.0, func(): return r[1].target != null)
	b.sell([r[1]])
	var sold: bool = b.structure_at(Vector2i(10, 7)) == null
	run(b, 1.0)
	var lands: bool = sold and r[2].hp < r[2].max_hp and r[2].attacker == null
	var k = battle({"heroes": [{"kind": "sylvia", "cell": Vector2i(10, 10)}], "base_hp": BIG, "waves": [[{"kind": "basic", "count": 0}], [{"kind": "basic", "count": 0}]], "seed": 11})
	var s = k.hero
	var foes := [_dummy(k, Vector2i(12, 10)), _dummy(k, Vector2i(13, 10)), _dummy(k, Vector2i(13, 11)), _dummy(k, Vector2i(13, 9)), _dummy(k, Vector2i(13, 12))]
	_dummy(k, Vector2i(0, 19))  # 전투 단계가 이어지게
	k.start_battle()
	k.cast(s, "w")
	var m0: float = s.mana
	run(k, 3.0, func(): return s.target != null)
	var volley: bool = s.mana <= m0 - s.w.mana + 0.5 and k.shots.size() == 1 + s.w.extra and foes.all(func(e): return e.hp == e.max_hp)
	var prev: float = s.cooldown
	var again := false
	for i in 80:  # 둘째 공격을 친 step(쿨다운이 다시 차오름)
		k.step(DT)
		if s.cooldown > prev:
			again = true
			break
		prev = s.cooldown
	var stacked: bool = again and s.target == foes[0] and s.stacks == 1
	return check(lands and volley and stacked,
		"판 타워의 화살 닿음·반격 대상 없음 %s · W 첫 공격을 친 step에 마나 냄·화살 %d발(4)·체력 그대로 %s · 둘째 공격을 친 step에 중첩 %d(1) %s" % [lands, k.shots.size(), volley, s.stacks, stacked])

# 궁수가 (10,10)의 과녁 e를 쏘는 판을 화면과 함께 FRAME씩 돌린다. [닿음 사건이 처음 난 프레임, e 체력이 처음 준 프레임, 처치 사건 프레임, e가 쓰러진 프레임](없으면 -1)
func _frames(hp: float) -> Array:
	var b = battle()
	b.place_merc("archer", Vector2i(10, 7))
	var e = _dummy(b, Vector2i(10, 10), {"hp": hp})
	var v = load("res://src/ui/battle_view.gd").new()
	v.battle = b
	v.tick(0.0)
	var got := [-1, -1, -1, -1]
	for f in 180:
		b.step(FRAME)
		v.tick(FRAME)
		var kinds: Array = v.events.filter(func(x): return x.dst == e).map(func(x): return x.kind)
		for i in 4:
			var now: bool = [kinds.has("hit"), e.hp < e.max_hp, kinds.has("kill"), not e.alive][i]
			if now and got[i] < 0:
				got[i] = f
	v.free()
	return got

# EV406 · S177: 원거리 공격의 맞은 때는 투사체가 닿는 때다. 화면의 닿음·처치 사건(I171)이 시뮬레이션이 피해를 주는 프레임과 같다
func ev406():
	var a := _frames(BIG)
	var k := _frames(1)
	var ok: bool = a[1] > 0 and a[0] == a[1] and k[3] > 0 and k[2] == k[3]
	return check(ok, "닿음 사건 프레임 %d · 체력이 준 프레임 %d · 처치 사건 프레임 %d · 쓰러진 프레임 %d" % [a[0], a[1], k[2], k[3]])
