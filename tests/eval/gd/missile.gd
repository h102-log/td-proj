extends "res://tests/eval/gd/lib.gd"
# proj-1(2026-10-25): 원거리 기본 공격(사거리 2칸을 넘는 영웅·용병, 쏘는 구조물)의 피해는 투사체가 닿을 때다(S178 → 변경, I174).
# lib.gd·kits.gd 머리의 계약에 더하는 API:
#   Battle.missiles — 날고 있거나 출발을 기다리는 투사체 목록. 웨이브가 끝나면 빈다(I143)
#   쏘는 쪽(유닛·구조물): cooldown(다음 공격까지 남은 초). 친 step에 공격 간격으로 돌아간다 · 적: attacker(반격 대상)
#   BattleView(src/ui/battle_view.gd): new() 뒤 battle을 넣고 tick(dt)을 부르면 events에 이번 프레임의 사건({kind, dst, …})이 든다(I171)
# 시간은 «쏜 step이 시작한 때»부터 «피해가 난 step이 끝난 때»까지 잰다. 그래서 허용 범위는 [닿는 때, 닿는 때 + DT]다

# 움직이지도 치지도 않는 과녁
func _dummy(b, cell: Vector2i, over := {}):
	return b.spawn_enemy("basic", cell, {"speed": 0, "sight": 0, "damage": 0, "hp": BIG}.merged(over, true))

# x(유닛·구조물)가 칠 때까지 돌리고 친 step을 마친 뒤 멈춘다. 친 step이 시작한 시각(초)을 돌려준다. secs 안에 치지 않으면 -1
func _until_shot(b, x, secs := 5.0) -> float:
	var t := 0.0
	while t < secs:
		var cd: float = x.cooldown
		b.step(DT)
		if x.cooldown > cd:
			return t
		t += DT
	return -1.0

# x가 과녁 e를 친 step이 시작한 때부터 e의 체력이 준 step이 끝난 때까지(초). 치지 않으면 -1, 3초 안에 줄지 않으면 INF
func _delay(b, x, e) -> float:
	var t0 := _until_shot(b, x)
	if t0 < 0.0:
		return -1.0
	var t := t0 + DT
	while e.hp == e.max_hp and t < t0 + 3.0:
		b.step(DT)
		t += DT
	return t - t0 if e.hp < e.max_hp else INF

func _sylvia(cell: Vector2i):
	return battle({"heroes": [{"kind": "sylvia", "cell": cell}], "base_hp": BIG, "waves": [[{"kind": "basic", "count": 0}]]})

# 전투 단계를 연다. 구석에 움직이지도 치지도 않는 적 하나를 두어 전투 단계가 이어지게 한다(kits.gd _start와 같다)
func _start(b) -> void:
	_dummy(b, Vector2i(0, 19))
	b.start_battle()

# EV401 · S178: 3칸 앞 과녁의 체력은 투사체가 닿을 때 준다. 궁수는 친 뒤 0.08초 + 화살 3/15초, 궁수탑 3/15초, 마법탑 구슬 3/10초, 대포알 3/7.5초다
func ev401():
	var got := []
	var ok := true
	for c in [["archer", 0.08 + 3.0 / 15.0], ["tower", 3.0 / 15.0], ["magic", 3.0 / 10.0], ["cannon", 3.0 / 7.5]]:
		var b = battle()
		var x = b.place_merc("archer", Vector2i(5, 5)) if c[0] == "archer" else b.build(c[0], Vector2i(5, 5))
		var e = _dummy(b, Vector2i(8, 5))
		var d := _delay(b, x, e)
		got.append("%s %.2f초(%.2f~%.2f)" % [c[0], d, c[1], c[1] + DT])
		ok = ok and d >= c[1] - 0.001 and d <= c[1] + DT + 0.001
	return check(ok, "친 step부터 피해까지 " + ", ".join(got))

# EV402 · S178: 날아가는 동안 대상이 쓰러지면 화살은 아무도 맞히지 않고 사라지고(축복이 실렸어도 옆 적이 그대로), 대포알은 대상의 마지막 자리에 떨어져 둘레 1칸 적에게 범위 피해를 준다
func ev402():
	var b = battle({"heroes": [{"kind": "seraphina", "cell": Vector2i(3, 3)}], "base_hp": BIG, "waves": [[{"kind": "basic", "count": 0}]]})
	b.hero.damage = 0.0
	var a = b.build("tower", Vector2i(15, 10))
	var t1 = _dummy(b, Vector2i(19, 10))
	var t2 = _dummy(b, Vector2i(19, 11))  # 쓰러진 대상 바로 옆(축복 반경 안), 탑 사거리 밖
	_start(b)
	b.cast(b.hero, "r")  # 축복(S152): 닿은 자리 둘레 1칸 적에게 마법 피해
	var shot := _until_shot(b, a) >= 0.0
	var flying: bool = t1.hp == t1.max_hp
	b.damage(t1, BIG * 2.0, "true")
	run(b, 1.0)
	var vanished: bool = t2.hp == t2.max_hp
	var c = battle()
	var cn = c.build("cannon", Vector2i(5, 5))
	var m1 = _dummy(c, Vector2i(9, 5))
	var m2 = _dummy(c, Vector2i(9, 6))  # 마지막 자리에서 1칸(대포 범위 안)
	var fired := _until_shot(c, cn) >= 0.0
	var ball: bool = m1.hp == m1.max_hp and m2.hp == m2.max_hp
	c.damage(m1, BIG * 2.0, "true")
	run(c, 1.0)
	var lost: float = BIG - m2.hp
	return check(shot and flying and vanished and fired and ball and absf(lost - cn.damage) < 0.01,
		"축복 걸린 탑이 쏨 %s · 쏜 step에 대상 그대로 %s · 대상이 쓰러진 뒤 옆 적 그대로 %s · 대포가 쏨 %s · 쏜 step에 그대로 %s · 옆 적이 잃은 체력 %s(%s)" % [shot, flying, vanished, fired, ball, lost, cn.damage])

# EV403 · S178: 투사체는 대상을 따라간다. 3칸 앞에서 초당 6칸으로 걷는 적을 쏘면, 쏜 뒤 적이 0.4칸 넘게 비켜나도 화살은 그 적에게 닿고,
# 쏜 때부터 닿은 때까지 화살(초당 15칸)이 날 수 있는 거리는 탑에서 닿은 때의 적 자리까지 거리 이상이다(쏜 때의 자리로 날아갔다면 모자란다)
func ev403():
	var b = battle()
	var t = b.build("tower", Vector2i(5, 5))
	var e = b.spawn_enemy("basic", Vector2i(8, 5), {"sight": 0, "damage": 0, "hp": BIG, "speed": 6.0})
	var p0: Vector2 = e.pos
	var d := _delay(b, t, e)
	var moved: float = e.pos.distance_to(p0)
	var far: float = Vector2(5, 5).distance_to(e.pos)
	return check(d > DT and d < INF and moved > 0.4 and d * 15.0 >= far - 0.01,
		"쏜 step부터 맞기까지 %.2f초(쏜 step 뒤, 3초 안) · 대상이 간 거리 %.2f칸(0.4 넘게) · 화살이 날 수 있는 거리 %.2f칸 ≥ 닿은 때 대상까지 %.2f칸" % [d, moved, d * 15.0, far])

# EV404 · S178: 반격 대상과 축복(세라피나 R)은 투사체가 닿을 때 정해지고 들어간다. 쏜 step에는 반격 대상이 없고 옆 적도 그대로다
func ev404():
	var b = battle()
	var t = b.build("tower", Vector2i(5, 5))
	var e = _dummy(b, Vector2i(8, 5))
	_until_shot(b, t)
	var no_counter: bool = e.attacker == null
	run(b, 1.0, func(): return e.hp < e.max_hp)
	var counter: bool = e.attacker == t
	var c = battle({"heroes": [{"kind": "seraphina", "cell": Vector2i(3, 3)}], "base_hp": BIG, "waves": [[{"kind": "basic", "count": 0}]]})
	var s = c.hero
	s.damage = 0.0
	var tw = c.build("tower", Vector2i(15, 10))
	var target = _dummy(c, Vector2i(17, 10))
	var beside = _dummy(c, Vector2i(17, 11))
	_start(c)
	c.cast(s, "r")
	_until_shot(c, tw)
	var calm: bool = target.hp == target.max_hp and beside.hp == beside.max_hp
	run(c, 1.0, func(): return target.hp < target.max_hp)
	var blessed: float = BIG - beside.hp
	return check(no_counter and counter and calm and absf(blessed - s.r.bless) < 0.01,
		"쏜 step에 반격 대상 없음 %s · 닿은 뒤 반격 대상이 그 탑 %s · 쏜 step에 과녁·옆 적 그대로 %s · 옆 적 축복 피해 %s(%s)" % [no_counter, counter, calm, blessed, s.r.bless])

# EV405 · S178: 실비아 W가 켜져 있으면 갈래 대상마다 화살을 따로 쏜다. 쏜 step에는 마나 8을 내고 네 적이 모두 그대로이며, 화살이 닿으면 넷이 저마다 공격력만큼 잃는다
func ev405():
	var b = _sylvia(Vector2i(10, 10))
	var s = b.hero
	var foes := [_dummy(b, Vector2i(12, 10)), _dummy(b, Vector2i(13, 10)), _dummy(b, Vector2i(13, 11)), _dummy(b, Vector2i(13, 9)), _dummy(b, Vector2i(13, 12))]
	_start(b)
	b.cast(s, "w")
	var m0: float = s.mana
	var shot := _until_shot(b, s) >= 0.0
	var paid: bool = s.mana <= m0 - s.w.mana + 0.5
	var calm: bool = foes.all(func(e): return e.hp == e.max_hp)
	run(b, 0.6)
	var lost := foes.map(func(e): return BIG - e.hp)
	var ok: bool = lost.slice(0, 4).all(func(x): return absf(x - s.damage) < 0.01) and lost[4] == 0.0
	return check(shot and paid and calm and ok, "쏨 %s · 마나 냄 %s · 쏜 step에 모두 그대로 %s · 0.6초 뒤 잃은 체력 %s(앞 넷 %s, 다섯째 0)" % [shot, paid, calm, lost, s.damage])

# EV406 · I174: 궁수가 친 뒤 화살이 나가기 전(0.08초 안)에 쓰러지면 화살은 나가지 않는다. 궁수탑이 쏜 뒤 부서져도 화살은 닿고, 부서진 탑은 반격 대상이 되지 않는다
func ev406():
	var b = battle()
	var a = b.place_merc("archer", Vector2i(5, 5), {"attack_gap": 100.0})
	var e = _dummy(b, Vector2i(8, 5))
	var shot := _until_shot(b, a) >= 0.0
	var calm: bool = e.hp == e.max_hp
	b.damage(a, BIG * 2.0, "true")
	run(b, 1.0)
	var none: bool = e.hp == e.max_hp
	var c = battle()
	var t = c.build("tower", Vector2i(5, 5))
	var f = _dummy(c, Vector2i(8, 5))
	var fired := _until_shot(c, t) >= 0.0
	c.damage(t, BIG * 2.0)
	var gone: bool = c.structure_at(Vector2i(5, 5)) == null
	var hit := run(c, 1.0, func(): return f.hp < f.max_hp)
	return check(shot and calm and none and fired and gone and hit and f.attacker == null,
		"궁수가 침 %s · 친 step에 그대로 %s · 궁수가 쓰러진 뒤 1초 동안 그대로 %s · 탑이 쏨 %s · 탑 부서짐 %s · 화살이 닿음 %s · 반격 대상 %s(없어야)" % [shot, calm, none, fired, gone, hit, f.attacker])

# EV407 · I143: 웨이브가 끝나면 날던 투사체가 사라진다. 대포알이 나는 동안 대상이 쓰러져 웨이브가 끝나면, 준비 단계의 투사체 목록은 비어 있다
func ev407():
	var b = battle({"waves": [[{"kind": "basic", "count": 1}], [{"kind": "basic", "count": 1}]]})
	var cn = b.build("cannon", Vector2i(4, 10))
	b.start_battle()
	var fired := _until_shot(b, cn) >= 0.0
	var ms = b.get("missiles")
	var flying: int = ms.size() if ms != null else -1
	for e in b.enemies.duplicate():
		b.damage(e, BIG * 2.0, "true")
	b.step(DT)
	ms = b.get("missiles")
	return check(fired and flying == 1 and b.state == "prep" and ms != null and ms.is_empty(),
		"대포가 쏨 %s · 쏜 뒤 나는 투사체 %d개(1) · 판 단계 %s(prep) · 웨이브가 끝난 뒤 투사체 %s(빈 목록)" % [fired, flying, b.state, ms])

# EV408 · I148: 실비아의 중첩은 쏜 때 센다. 넷째 중첩에서 같은 적을 쏘면 쏜 step에 중첩이 다섯이 되지만 체력은 그대로이고,
# 닿으면 대상과 W 갈래 대상이 모두 방어력 15의 35%를 무시한 피해를 잃는다
func ev408():
	var b = _sylvia(Vector2i(10, 10))
	var s = b.hero
	var t = _dummy(b, Vector2i(12, 10), {"armor": 15.0})
	var n = _dummy(b, Vector2i(13, 10), {"armor": 15.0})
	_start(b)
	b.cast(s, "w")
	s.mark = t
	s.stacks = s.passive.stacks - 1
	var shot := _until_shot(b, s) >= 0.0
	var counted: bool = s.stacks == s.passive.stacks
	var calm: bool = t.hp == t.max_hp and n.hp == n.max_hp
	run(b, 0.6)
	var want: float = s.damage * b.armor_mult(15.0 * (1.0 - s.passive.ignore))
	var got := [BIG - t.hp, BIG - n.hp]
	return check(shot and counted and calm and absf(got[0] - want) < 0.001 and absf(got[1] - want) < 0.001,
		"쏨 %s · 쏜 step에 중첩 %d(%d) · 쏜 step에 둘 다 그대로 %s · 닿은 뒤 잃은 체력 %s(둘 다 %s)" % [shot, s.stacks, s.passive.stacks, calm, got, want])

# 화면을 붙인 판에서 secs 동안 step과 tick을 함께 돌리고, 프레임마다 [과녁 체력, 과녁이 살아 있나, 그 프레임 사건 종류]를 모은다
func _frames(b, e, secs: float) -> Array:
	var v = load("res://src/ui/battle_view.gd").new()
	v.battle = b
	v.tick(0.0)  # 첫 tick은 있던 것을 기억만 한다
	var out := []
	var t := 0.0
	while t < secs:
		b.step(DT)
		v.tick(DT)
		out.append([e.hp, e.alive, v.events.filter(func(x): return x.dst == e).map(func(x): return x.kind)])
		t += DT
	v.free()
	return out

# EV409 · I171: 원거리 공격의 닿음 사건은 투사체가 닿아 체력이 준 프레임에 한 번 난다. 그 화살에 쓰러진 적의 처치 사건도 쓰러진 그 프레임에 한 번이다
func ev409():
	var b = battle()
	b.build("tower", Vector2i(5, 5))
	var e = _dummy(b, Vector2i(8, 5))
	var fs := _frames(b, e, 0.9)  # 궁수탑은 1초마다 쏜다. 첫 화살만 본다
	var drop := -1
	var hits := []
	for i in fs.size():
		if drop < 0 and fs[i][0] < e.max_hp:
			drop = i
		if "hit" in fs[i][2]:
			hits.append(i)
	var c = battle()
	c.build("tower", Vector2i(5, 5))
	var k = _dummy(c, Vector2i(8, 5), {"hp": 1.0})
	var ks := _frames(c, k, 0.9)
	var died := -1
	var kills := []
	var khits := 0
	for i in ks.size():
		if died < 0 and not ks[i][1]:
			died = i
		if "kill" in ks[i][2]:
			kills.append(i)
		khits += ks[i][2].count("hit")
	return check(drop > 0 and hits == [drop] and died > 0 and kills == [died] and khits == 0,
		"체력이 준 프레임 %d · 닿음 사건 프레임 %s · 쓰러진 프레임 %d · 처치 사건 프레임 %s · 그 적의 닿음 사건 %d번(0)" % [drop, hits, died, kills, khits])
