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

# EV401 · S178: 3칸 앞 과녁의 체력은 투사체가 닿을 때 준다. 궁수는 친 뒤 0.08초 + 화살 3/15초, 궁수탑 3/15초, 마법탑 구슬 3/10초, 대포알 3/7.5초다.
# 궁수는 명중률(S178 2026-11-04 변경)을 1로 둔다
func ev401():
	var got := []
	var ok := true
	for c in [["archer", 0.08 + 3.0 / 15.0], ["tower", 3.0 / 15.0], ["magic", 3.0 / 10.0], ["cannon", 3.0 / 7.5]]:
		var b = battle()
		var x = b.place_merc("archer", Vector2i(5, 5), {"accuracy": 1.0}) if c[0] == "archer" else b.build(c[0], Vector2i(5, 5))
		var e = _dummy(b, Vector2i(8, 5))
		var d := _delay(b, x, e)
		got.append("%s %.2f초(%.2f~%.2f)" % [c[0], d, c[1], c[1] + DT])
		ok = ok and d >= c[1] - 0.001 and d <= c[1] + DT + 0.001
	return check(ok, "친 step부터 피해까지 " + ", ".join(got))

# EV402 · S178: 날아가는 동안 대상이 쓰러지면 마법탑 구슬(대상을 따라간다)은 아무도 맞히지 않고 사라지고(축복이 실렸어도 옆 적이 그대로),
# 대포알은 조준점(멈춘 과녁의 자리)에 떨어져 둘레 1칸 적에게 범위 피해를 준다(S178 2026-11-04 변경)
func ev402():
	var b = battle({"heroes": [{"kind": "seraphina", "cell": Vector2i(3, 3)}], "base_hp": BIG, "waves": [[{"kind": "basic", "count": 0}]]})
	b.hero.damage = 0.0
	var a = b.build("magic", Vector2i(15, 10))
	var t1 = _dummy(b, Vector2i(19, 10))
	var t2 = _dummy(b, Vector2i(19, 11))  # 쓰러진 대상 바로 옆(축복 반경 안). 마법탑은 2.5초마다 쏘아 1초 안에 다시 쏘지 않는다
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
		"축복 걸린 마법탑이 쏨 %s · 쏜 step에 대상 그대로 %s · 대상이 쓰러진 뒤 옆 적 그대로 %s · 대포가 쏨 %s · 쏜 step에 그대로 %s · 옆 적이 잃은 체력 %s(%s)" % [shot, flying, vanished, fired, ball, lost, cn.damage])

# EV403 · S178: 마법탑 구슬은 대상을 따라간다(S178 2026-11-04 변경). 3칸 앞에서 초당 6칸으로 걷는 적을 쏘면, 쏜 뒤 적이 0.4칸 넘게 비켜나도 구슬은 그 적에게 닿고,
# 쏜 때부터 닿은 때까지 구슬(초당 10칸)이 날 수 있는 거리는 탑에서 닿은 때의 적 자리까지 거리 이상이다(쏜 때의 자리로 날아갔다면 모자란다)
func ev403():
	var b = battle()
	var t = b.build("magic", Vector2i(5, 5))
	var e = b.spawn_enemy("basic", Vector2i(8, 5), {"sight": 0, "damage": 0, "hp": BIG, "speed": 6.0})
	var p0: Vector2 = e.pos
	var d := _delay(b, t, e)
	var moved: float = e.pos.distance_to(p0)
	var far: float = Vector2(5, 5).distance_to(e.pos)
	return check(d > DT and d < INF and moved > 0.4 and d * 10.0 >= far - 0.01,
		"쏜 step부터 맞기까지 %.2f초(쏜 step 뒤, 3초 안) · 대상이 간 거리 %.2f칸(0.4 넘게) · 구슬이 날 수 있는 거리 %.2f칸 ≥ 닿은 때 대상까지 %.2f칸" % [d, moved, d * 10.0, far])

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

# 실비아와 궁수들이 선 판. quiet면 실비아 공격력을 0으로 둔다. 궁수는 한 번만 쏘고(공격 간격 100초) 명중률은 1이다(S178 2026-11-04 변경). [판, 궁수들]
func _archers(hero_cell: Vector2i, cells: Array, quiet := true) -> Array:
	var b = battle({"heroes": [{"kind": "sylvia", "cell": hero_cell}], "base_hp": BIG, "waves": [[{"kind": "basic", "count": 0}]], "merc_cap": cells.size()})
	if b.hero and quiet:
		b.hero.damage = 0.0
	return [b, cells.map(func(c): return b.place_merc("archer", c, {"attack_gap": 100.0, "accuracy": 1.0}))]

# EV405 · I212: 순풍 장판(실비아 W)을 지나는 궁수 화살은 speed배 빨라져, 장판을 지나지 않는 같은 거리(5칸)의 화살보다 먼저 닿고 피해는 같다(궁수 공격력).
# 그 화살을 쏜 궁수에는 공격 속도 +haste가 걸려 haste_time초 뒤 풀리고, 장판을 지나지 않은 궁수에는 걸리지 않는다
func ev405():
	var pair := _archers(Vector2i(8, 9), [Vector2i(3, 5), Vector2i(3, 14)])
	var b = pair[0]
	var a = pair[1][0]
	var c = pair[1][1]
	var s = b.hero
	var ta = _dummy(b, Vector2i(8, 5))
	var tc = _dummy(b, Vector2i(8, 14))
	_start(b)
	var used: bool = b.cast(s, "w", Vector2(5, 5))
	var t := 0.0
	var at := [-1.0, -1.0]
	while t < 2.0 and (at[0] < 0.0 or at[1] < 0.0):
		b.step(DT)
		t += DT
		if at[0] < 0.0 and ta.hp < BIG:
			at[0] = t
		if at[1] < 0.0 and tc.hp < BIG:
			at[1] = t
	var haste := [b.effect(a, "haste"), b.effect(c, "haste")]
	var lost := [BIG - ta.hp, BIG - tc.hp]
	run(b, s.w.haste_time + 0.2)
	var faded: bool = b.effect(a, "haste") == null
	var ok: bool = used and at[0] > 0.0 and at[1] > 0.0 and at[0] < at[1] and absf(lost[0] - a.damage) < 0.001 and absf(lost[1] - a.damage) < 0.001
	return check(ok and haste[0] != null and absf(haste[0] - s.w.haste) < 0.001 and haste[1] == null and faded,
		"씀 %s · 닿은 때 [지남, 안 지남] %s · 피해 %s(둘 다 %s) · 궁수 공격 속도 증가 %s(%s, 없음) · %s초 뒤 풀림 %s" % [used, at, lost, a.damage, haste, s.w.haste, s.w.haste_time, faded])

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

# EV408 · I213: 정조준 비율은 쏠 때 거리로 정해 화살에 담는다. 실비아가 far칸 앞 과녁을 쏜 step에는 과녁 체력이 그대로이고,
# 쏜 뒤 과녁을 near칸 앞으로 옮겨도 닿은 피해는 far칸 값(공격력 × (1 + might))이다
func ev408():
	var b = _sylvia(Vector2i(3, 10))
	var s = b.hero
	var p: Dictionary = s.passive
	var t = _dummy(b, Vector2i(3 + roundi(p.far), 10))
	t.pos = Vector2(3.0 + p.far, 10.0)
	_start(b)
	var shot := _until_shot(b, s) >= 0.0
	var calm: bool = t.hp == t.max_hp
	t.pos = Vector2(3.0 + p.near, 10.0)
	run(b, 0.6)
	var want: float = s.damage * (1.0 + p.might)
	return check(shot and calm and absf((BIG - t.hp) - want) < 0.001,
		"쏨 %s · 쏜 step에 그대로 %s · 가까이 옮긴 뒤 닿은 피해 %s(먼 값 %s)" % [shot, calm, BIG - t.hp, want])

# EV667 · I212: 렌즈와 바람의 길은 화살만 받는다. 렌즈를 지난 마법 타워 구슬의 피해는 타워 공격력 그대로다.
# 실비아 R 바람의 길을 지난 궁수 화살은 방어력 15 과녁에 궁수 공격력 × (1 + might) × armor_mult(15 × (1 − ignore_max))를 준다
func ev667():
	var pair := _archers(Vector2i(6, 5), [])
	var b = pair[0]
	var s = b.hero
	var mt = b.build("magic", Vector2i(5, 10))
	var e = _dummy(b, Vector2i(9, 10))
	_start(b)
	var lensed: bool = b.cast(s, "e", Vector2(7, 10))
	run(b, 1.5, func(): return e.hp < BIG)
	var bolt: float = BIG - e.hp
	pair = _archers(Vector2i(3, 10), [Vector2i(12, 7)], false)  # R 저격에 공격력이 든다. 적은 모두 실비아 사거리 밖이라 기본 공격은 닿지 않는다
	var c = pair[0]
	var h = c.hero
	var a = pair[1][0]
	var tgt = _dummy(c, Vector2i(12, 12), {"armor": 15.0})
	_dummy(c, Vector2i(28, 10))  # 가장 먼 적: 바람의 길이 (3,10)에서 (28,10)까지
	_start(c)
	var pathed: bool = c.cast(h, "r")
	run(c, 1.5, func(): return tgt.hp < BIG)
	var arrow: float = BIG - tgt.hp
	var want: float = a.damage * (1.0 + h.passive.might) * c.armor_mult(15.0 * (1.0 - h.passive.ignore_max))
	return check(lensed and mt != null and absf(bolt - mt.damage) < 0.001 and pathed and absf(arrow - want) < 0.001,
		"렌즈 %s · 렌즈 지난 구슬 피해 %s(타워 공격력 %s) · 길 %s · 길 지난 궁수 화살 %s(%s)" % [lensed, bolt, mt.damage if mt else null, pathed, arrow, want])

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

# ── 논타겟팅 투사체(S178 2026-11-04 변경, I224) ──
# 투사체(Battle.missiles의 하나)에 더하는 API: free — 논타겟팅인가(궁수는 화살이 나갈 때 정한다) · mark — 조준점(나가는 때 노린 적이 선 자리)
# 용병 수치 accuracy — 궁수 명중률(0~1). place_merc의 덮어쓰기로 정할 수 있다

# 화살이 다 날아 투사체 목록이 빌 때까지(초). «쏜 step이 시작한 때»부터 «빈 step이 끝난 때»까지다. secs 안에 비지 않으면 INF
func _until_gone(b, x, secs := 2.0) -> float:
	var t0 := _until_shot(b, x)
	if t0 < 0.0:
		return -1.0
	var t := t0 + DT
	while not b.missiles.is_empty() and t < t0 + secs:
		b.step(DT)
		t += DT
	return t - t0 if b.missiles.is_empty() else INF

# EV730 · S178: 궁수탑 화살은 쏜 때 노린 적의 자리로 곧게 난다. 쏜 뒤 노린 적이 2칸 비켜나면 그 적은 맞지 않고, 조준점 너머 같은 줄의 적이 맞는다.
# 아무도 맞히지 못한 화살은 탑에서 사거리(8칸)만큼 간 곳에서 사라진다(쏜 step부터 8/15초 이상, 그보다 한 step 넘게 늦지 않다)
func ev730():
	var b = battle()
	var t = b.build("tower", Vector2i(5, 5))
	var a = _dummy(b, Vector2i(8, 5))
	var behind = _dummy(b, Vector2i(11, 5))
	var shot := _until_shot(b, t) >= 0.0
	a.pos = Vector2(8, 7)
	run(b, 0.8)  # 궁수탑은 1초마다 쏜다. 첫 화살만 본다
	var c = battle()
	var u = c.build("tower", Vector2i(5, 5))
	var a2 = _dummy(c, Vector2i(8, 5))
	var far = _dummy(c, Vector2i(14, 5))  # 같은 줄, 사거리 8 밖
	var t0 := _until_shot(c, u)
	a2.pos = Vector2(8, 7)
	var t1 := t0 + DT
	while not c.missiles.is_empty() and t1 < t0 + 0.9:
		c.step(DT)
		t1 += DT
	var life: float = t1 - t0 if t0 >= 0.0 and c.missiles.is_empty() else INF
	var want := 8.0 / 15.0
	return check(shot and a.hp == a.max_hp and behind.hp < behind.max_hp and a2.hp == a2.max_hp and far.hp == far.max_hp and life >= want - 0.001 and life <= want + DT + 0.001,
		"탑이 쏨 %s · 비켜난 과녁 그대로 %s · 조준점 너머 과녁이 맞음 %s · 둘째 판 비켜난 과녁 그대로 %s · 사거리 밖 과녁 그대로 %s · 화살이 사라지기까지 %.2f초(%.2f~%.2f)" % [shot, a.hp == a.max_hp, behind.hp < behind.max_hp, a2.hp == a2.max_hp, far.hp == far.max_hp, life, want, want + DT])

# EV731 · S178: 궁수탑 화살은 날아가는 길에 몸이 닿은 첫 적 하나에게 닿는다. 쏜 뒤 길 위 (7,5)에 과녁이 들어오면 그 과녁이 맞고 노린 (8,5) 과녁은 그대로다
func ev731():
	var b = battle()
	var t = b.build("tower", Vector2i(5, 5))
	var a = _dummy(b, Vector2i(8, 5))
	var shot := _until_shot(b, t) >= 0.0
	var d = _dummy(b, Vector2i(7, 5))
	run(b, 0.8)
	return check(shot and d.hp < d.max_hp and a.hp == a.max_hp,
		"탑이 쏨 %s · 길 위에 들어온 과녁이 맞음 %s(체력 %s) · 노린 과녁 그대로 %s(체력 %s)" % [shot, d.hp < d.max_hp, d.hp, a.hp == a.max_hp, a.hp])

# EV732 · S178: 대포알은 쏜 때 노린 적의 자리(조준점)에 떨어져 둘레 1칸 안의 적에게만 대포 피해를 준다. 날아가는 길의 적은 맞지 않는다.
# 대포가 (9,5) 과녁을 쏜 뒤 그 과녁을 (9,7)로 옮기고 (9,6)·(7,5)에 과녁을 두면 (9,6)만 대포 피해만큼 잃는다
func ev732():
	var b = battle()
	var cn = b.build("cannon", Vector2i(5, 5))
	var a = _dummy(b, Vector2i(9, 5))
	var fired := _until_shot(b, cn) >= 0.0
	a.pos = Vector2(9, 7)
	var near = _dummy(b, Vector2i(9, 6))
	var under = _dummy(b, Vector2i(7, 5))
	run(b, 1.0)  # 대포는 2.5초마다 쏜다
	var lost: float = near.max_hp - near.hp
	return check(fired and absf(lost - cn.damage) < 0.01 and a.hp == a.max_hp and under.hp == under.max_hp,
		"대포가 쏨 %s · 조준점 1칸 옆 과녁이 잃은 체력 %s(%s) · 비켜난 노린 과녁 그대로 %s · 날아가는 길의 과녁 그대로 %s" % [fired, lost, cn.damage, a.hp == a.max_hp, under.hp == under.max_hp])

# EV733 · S178: 원거리 영웅의 화살은 그대로 대상을 따라간다. 실비아가 3칸 앞 과녁을 친 뒤 과녁을 2칸 옮겨도 1초 안에 과녁 체력이 준다
func ev733():
	var b = _sylvia(Vector2i(3, 10))
	var s = b.hero
	var t = _dummy(b, Vector2i(6, 10))
	_start(b)
	var shot := _until_shot(b, s) >= 0.0
	t.pos = Vector2(6, 12)
	var hit := run(b, 1.0, func(): return t.hp < t.max_hp)
	return check(shot and hit, "실비아가 침 %s · 옮긴 과녁이 1초 안에 맞음 %s" % [shot, hit])

# EV734 · I224: 화살은 지난 길에서 몸 가운데까지가 몸 반지름 이하인 적에게 닿는다. 궁수탑이 (8,5) 과녁을 쏜 뒤 과녁을 길에서
# 반지름 − 0.05칸 옮기면 맞고, 반지름 + 0.1칸 옮기면 맞지 않으며 그 과녁에 반격 대상(attacker)도 생기지 않는다
func ev734():
	var got := []
	for k in [-0.05, 0.1]:
		var b = battle()
		var t = b.build("tower", Vector2i(5, 5))
		var e = _dummy(b, Vector2i(8, 5))
		var shot := _until_shot(b, t) >= 0.0
		e.pos = Vector2(8.0, 5.0 + e.radius + k)
		run(b, 0.8)
		got.append([shot, e.hp < e.max_hp, e.attacker])
	return check(got[0][0] and got[0][1] and got[1][0] and not got[1][1] and got[1][2] == null,
		"[반지름 안, 반지름 밖]으로 옮긴 과녁 [쏨, 맞음, 반격 대상] %s(안은 맞고, 밖은 맞지 않고 반격 대상 없음)" % [got])

# EV735 · I224: 대포알이 노린 적을 맞히지 못하면 화면의 피격 표(BattleView.hit_table)에 그 적이 없고, 범위 안의 적은 곁 대상(SIDE px)으로 밀린다.
# 대포가 (9,5) 과녁을 쏜 뒤 과녁을 (9,8)로 옮기고 (9,6)에 과녁을 두고 대포알이 떨어질 때까지 돌린다
func ev735():
	var b = battle()
	var cn = b.build("cannon", Vector2i(5, 5))
	var a = _dummy(b, Vector2i(9, 5))
	var fired := _until_shot(b, cn) >= 0.0
	a.pos = Vector2(9, 8)
	var near = _dummy(b, Vector2i(9, 6))
	var fell := run(b, 1.0, func(): return not b.landed.is_empty())
	var View = load("res://src/ui/battle_view.gd")
	var v = View.new()
	v.battle = b
	var hits: Dictionary = v.hit_table(b.units + b.enemies)
	v.free()
	var ha = hits.get(a.get_instance_id())
	var hn = hits.get(near.get_instance_id())
	return check(fired and fell and ha == null and hn != null and hn[2] == View.SIDE,
		"대포가 쏨 %s · 떨어짐 %s · 비켜난 노린 과녁의 표 %s(없어야) · 범위 안 과녁의 표 %s(밀림 %spx)" % [fired, fell, ha, hn, View.SIDE])

# EV736 · S178: 궁수는 명중률의 확률로 대상을 따라가는 화살, 아니면 논타겟팅 화살을 쏜다. 명중률 1인 궁수의 화살은 나간 뒤 과녁을 2칸 옮겨도 맞는다.
# 명중률 0인 궁수의 화살은 논타겟팅(free)이고 조준점(mark)이 과녁 자리다. 나간 뒤 과녁을 2칸 옮기면 맞지 않고, 옮기지 않으면 맞는다
func ev736():
	var got := []
	for c in [[1.0, true], [0.0, true], [0.0, false]]:
		var b = battle()
		var a = b.place_merc("archer", Vector2i(5, 5), {"attack_gap": 100.0, "accuracy": c[0]})
		var e = _dummy(b, Vector2i(8, 5))
		var shot := _until_shot(b, a) >= 0.0
		run(b, 0.1)  # 화살이 나가는 때(친 뒤 0.08초)를 지난다
		var m = b.missiles[0] if not b.missiles.is_empty() else null
		var free = m.get("free") if m != null else null
		var off: float = m.get("mark").distance_to(e.pos) if free == true else -1.0
		if c[1]:
			e.pos = Vector2(8, 7)
		run(b, 1.0)
		got.append([shot, free, snappedf(off, 0.01), e.hp < e.max_hp])
	var ok: bool = got.all(func(g): return g[0]) and got[0][1] == false and got[0][3] and got[1][1] == true and got[1][2] < 0.01 and not got[1][3] and got[2][1] == true and got[2][2] < 0.01 and got[2][3]
	return check(ok, "[명중률 1 + 옮김, 명중률 0 + 옮김, 명중률 0]의 [침, 논타겟팅, 조준점에서 과녁까지, 맞음] %s(기대 [참, 거짓, -, 참] · [참, 참, 0, 거짓] · [참, 참, 0, 참])" % [got])
