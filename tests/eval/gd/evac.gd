extends "res://tests/eval/gd/house.gd"
# 주민 ④ 대피령·대피소·신뢰(S225~S229·I183). lib.gd·house.gd 머리의 계약에 더하는 API:
#   Battle.evacuate() -> bool — 대피령(S225). 낼 수 없으면 false · Battle.evac — 대피령 중인가
#   Battle.trust — 신뢰(0~5, S229) · Battle.calm — 대피령 없이 지난 라운드 수 · Battle.folk_clock — 주민 시계(초, 스텝마다 흐른다)
#   Battle.people — 주민 몸(BattleView.folk_of 차례): pos(칸 단위) · inside(집·대피소·교회 안) · hp · max_hp · alive · home(사는 구조물)
#     · m — 그 주민의 가족 사전(사는 구조물 folk[i]). 일과대로가 아니면 m.away = {to: "shelter"|"home"|"church"|"out", in: 안에 들었나, s: 길에서 간 칸}
#     m.hp — 체력(없으면 가득). 평가가 직접 둔다
#   Battle.damage(주민, 양) — 주민 체력을 깎는다(0이면 죽는다)
#   구조물 lost — 그 집의 죽은 식구 수 · kind "shelter"(대피소) · STRUCTURE_KINDS.shelter.seats — 자리 수
#   res://src/sim/folk.gd — 손잡이 상수 HP · SLOW · SPEED · HEAL · HOME_HEAL · TRUST · REFUSE · TRUST_AFTER_LEAVE
#   단축키: B 대피령

const FOLK := "res://src/sim/folk.gd"
const SHELTER := Vector2i(26, 3)  # 마을 칸(집 줄 ROW6의 오른쪽)
const WAVE1 := [{"kind": "basic", "count": 1}]

func _F():
	return load(FOLK) if ResourceLoader.exists(FOLK) else null

# ④ 계약이 없으면 그 까닭(글), 있으면 ""
func _lacks(b) -> String:
	if _F() == null:
		return "src/sim/folk.gd가 없다"
	if b.get("people") == null or not b.has_method("evacuate"):
		return "Battle.people·evacuate가 없다"
	return ""

func _to(v) -> String:
	var a = v.m.get("away")
	return a.get("to", "") if a != null else ""

# 집 여섯 채(ROW6)와 대피소를 지은 마을 판 가운데 주민이 자리 수보다 많은 첫 씨앗. 못 찾으면 그 까닭(글)
func _crowd():
	for sd in range(1, 40):
		var b = _six({"seed": sd})
		if b == null:
			return "집 여섯 채를 짓지 못했다"
		var bad := _lacks(b)
		if bad != "":
			return bad
		var d = b.STRUCTURE_KINDS.get("shelter")
		if d == null:
			return "data/structures/shelter.tres가 없다"
		if b.people.size() > d.seats:
			if b.build("shelter", SHELTER) == null:
				return "대피소 %s를 짓지 못했다" % [SHELTER]
			return b
	return "주민이 대피소 자리보다 많은 씨앗이 없다"

# 전투를 시작하고 대피령을 낸 뒤 모두 안에 들 때까지 돌린다. 안 되면 그 까닭(글)
func _evacuated(b) -> String:
	b.start_battle()
	b.step(DT)
	if not b.evacuate():
		return "전투 단계에 대피령이 나지 않았다"
	if not run(b, 30.0, func(): return b.people.all(func(v): return v.inside)):
		return "대피령 30초 뒤 안에 든 주민 %d/%d" % [b.people.filter(func(v): return v.inside).size(), b.people.size()]
	return ""

# EV487 · S225: 준비 단계에는 대피령이 나지 않고, 전투 단계에 B 키로 나며, 다시 내지 못하고, 웨이브가 끝나면 풀린다
func ev487():
	var b = _battle()
	b.build("house", H1)
	var bad := _lacks(b)
	if bad != "":
		return bad
	if b.evacuate() or b.evac:
		return "준비 단계에 대피령이 났다"
	b.start_battle()
	b.step(DT)
	_key(controls(b), KEY_B)
	if b.evac != true:
		return "전투 단계에 B 키를 눌러도 대피령이 나지 않았다"
	if b.evacuate():
		return "대피령 중에 대피령을 다시 냈다"
	if not clear_wave(b) or b.state != "prep":
		return "웨이브가 끝나지 않았다(%s)" % b.state
	return check(b.evac == false, "웨이브가 끝났는데 대피령 중이다")

# EV488 · S226: 신뢰 5에서 대피령을 내면 모두 안에 들고, 대피소에 자리 수만큼, 나머지는 자기 집에 든다. 대피소에 든 주민이 집으로 간 주민보다 멀지 않았다
func ev488():
	var b = _crowd()
	if b is String:
		return b
	var mid: Vector2 = b.middle(b.structure_at(SHELTER))
	b.start_battle()
	b.step(DT)
	var far := {}
	for v in b.people:
		far[v] = v.pos.distance_to(mid)
	if not b.evacuate():
		return "대피령이 나지 않았다"
	if not run(b, 30.0, func(): return b.people.all(func(v): return v.inside)):
		return "대피령 30초 뒤 안에 든 주민 %d/%d" % [b.people.filter(func(v): return v.inside).size(), b.people.size()]
	var kept: Array = b.people.filter(func(v): return v.pos.distance_to(mid) <= 2.0)
	var homed: Array = b.people.filter(func(v): return v.pos.distance_to(b.middle(v.home)) <= 2.5)
	var seats: int = b.STRUCTURE_KINDS.shelter.seats
	if kept.size() != seats or kept.size() + homed.size() != b.people.size():
		return "주민 %d명 가운데 대피소 %d명(자리 %d) · 자기 집 %d명" % [b.people.size(), kept.size(), seats, homed.size()]
	var worst: float = kept.map(func(v): return far[v]).max()
	var best: float = homed.map(func(v): return far[v]).min()
	return check(worst <= best + 0.001, "대피소에 든 주민의 가장 먼 거리 %.2f가 집으로 간 주민의 가장 가까운 거리 %.2f보다 멀다" % [worst, best])

# EV489 · S225·S223: 웨이브가 끝나면 대피한 주민이 60초 안에 일과로 돌아오고, 일과 중인 자리는 판 시계로 구한 일과(residents)와 같으며, 30초 안에 모두 밖에 보인다
func ev489():
	var b = _crowd()
	if b is String:
		return b
	var bad := _evacuated(b)
	if bad != "":
		return bad
	if not clear_wave(b) or b.state != "prep" or b.evac:
		return "웨이브가 끝나지 않았거나 대피령이 남았다(%s, 대피령 %s)" % [b.state, b.evac]
	if not run(b, 60.0, func(): return b.people.all(func(v): return v.m.get("away") == null)):
		return "웨이브 끝 60초 뒤에도 일과로 돌아오지 않은 주민 %d명" % b.people.filter(func(v): return v.m.get("away") != null).size()
	var view = load(BV)
	var st := {"seen": {}, "bad": ""}
	run(b, 30.0, func():
		var ps: Array = view.residents(b, b.folk_clock)
		for k in b.people.size():
			var v = b.people[k]
			if not v.inside:
				st["seen"][k] = true
			if ps.size() != b.people.size() or v.pos.distance_to(ps[k]) > 0.01:
				st["bad"] = "%.2f초 주민 %d의 자리 %s가 일과 %s와 다르다" % [b.folk_clock, k, v.pos, ps[k] if k < ps.size() else null]
		return st["bad"] != "")
	if st.bad != "":
		return st.bad
	return check(st.seen.size() == b.people.size(), "30초 동안 밖에 보인 주민 %d/%d" % [st.seen.size(), b.people.size()])

# EV490 · S229: 따르지 않는 주민 수는 round(n × (5 − 신뢰) × 0.2)다
func ev490():
	var F = _F()
	if F == null:
		return "src/sim/folk.gd가 없다"
	for t in [5, 3, 0]:
		var b = _six({"seed": 2})
		var bad := _lacks(b) if b != null else "집 여섯 채를 짓지 못했다"
		if bad != "":
			return bad
		var n: int = b.people.size()
		b.trust = t
		b.start_battle()
		b.step(DT)
		if not b.evacuate():
			return "신뢰 %d에서 대피령이 나지 않았다" % t
		var stay: int = b.people.filter(func(v): return v.m.get("away") == null).size()
		var want := roundi(n * (F.TRUST - t) * F.REFUSE)
		if stay != want:
			return "신뢰 %d · 주민 %d명에서 따르지 않은 주민 %d명, 기대 %d명" % [t, n, stay, want]
	return ""

func _hurt_any(b) -> bool:
	return b.people.any(func(v): return v.hp < v.max_hp)

# EV491 · S227·I49: 마을 안 적은 밖의 주민을 친다. 들판의 적은 치지 않는다. 모두 안에 들면 마을 안 적도 치지 않는다
func ev491():
	var b = _battle({"seed": 1})
	b.build("house", H1)
	var bad := _lacks(b)
	if bad != "":
		return bad
	b.start_battle()
	b.step(DT)
	var out: Array = b.people.filter(func(v): return not v.inside and not b.footprint.has(Vector2i(v.pos.round())))
	if out.is_empty():
		return "밖에 나와 있는 주민이 없다"
	var n: int = b.people.size()
	b.spawn_enemy("basic", Vector2i(out[0].pos.round()), {"hp": BIG, "sight": 3.0})
	if not run(b, 10.0, func(): return _hurt_any(b) or b.people.size() < n):
		return "마을 안 적이 10초 동안 밖의 주민을 치지 않았다"
	var f = _battle({"seed": 1})
	f.build("house", H1)
	f.start_battle()
	f.spawn_enemy("basic", Vector2i(10, 7), {"hp": BIG, "sight": 10.0})  # 마을 바로 아래 들판 칸
	var m: int = f.people.size()
	run(f, 10.0)
	if _hurt_any(f) or f.people.size() != m:
		return "들판의 적이 주민을 쳤다"
	var s = _battle({"seed": 1})
	s.build("house", H1)
	bad = _evacuated(s)
	if bad != "":
		return bad
	var k: int = s.people.size()
	s.spawn_enemy("basic", Vector2i(12, 4), {"hp": BIG, "sight": 3.0, "damage": 0.5})
	run(s, 30.0)
	return check(not _hurt_any(s) and s.people.size() == k, "모두 안에 든 주민을 마을 안 적이 쳤다(주민 %d → %d)" % [k, s.people.size()])

# 집 (2,3)과 교회 (24,3)(church면)을 지은 마을 판에서 집 주민 하나에 amount 피해를 준다. [판, 주민] 또는 까닭(글)
func _hurt_one(amount: float, church := true):
	var b = _battle({"seed": 1})
	b.build("house", Vector2i(2, 3))
	if church:
		b.build("church", Vector2i(24, 3))
	var bad := _lacks(b)
	if bad != "":
		return bad
	b.step(DT)
	var who: Array = b.people.filter(func(x): return x.home.kind == "house")
	if who.is_empty():
		return "집에 주민이 없다"
	var v = who[0]
	b.damage(v, amount)
	return [b, v]

# EV492 · S227: 다친 주민은 교회로 가고, 걸음은 평소 × (남은 체력 ÷ 15)이며 30% 밑으로 느려지지 않는다
func ev492():
	var F = _F()
	if F == null:
		return "src/sim/folk.gd가 없다"
	for amount in [F.HP * 0.5, F.HP - 1.0]:
		var got = _hurt_one(amount)
		if got is String:
			return got
		var b = got[0]
		var v = got[1]
		if _to(v) != "church" or v.m.away.get("in", false):
			return "피해 %.1f를 받은 주민이 교회로 가는 길 위가 아니다(away %s)" % [amount, v.m.get("away")]
		var s0: float = v.m.away.s
		for i in 10:  # 0.5초. run은 0.05 누적 오차로 한 스텝을 더 돈다
			b.step(DT)
		var ds: float = v.m.away.s - s0
		var want: float = F.SPEED * maxf((F.HP - amount) / F.HP, F.SLOW) * 0.5
		if absf(ds - want) > 0.02:
			return "피해 %.1f를 받은 주민이 0.5초에 %.3f칸 걸었다, 기대 %.3f칸" % [amount, ds, want]
	return ""

# EV493 · S227: 교회 안에서 초당 1씩 회복하고, 다 나으면 집으로 가 일과로 돌아온다. 교회가 없으면 집 안에서 초당 0.5씩 회복한다
func ev493():
	var F = _F()
	if F == null:
		return "src/sim/folk.gd가 없다"
	var got = _hurt_one(F.HP * 0.5)
	if got is String:
		return got
	var b = got[0]
	var v = got[1]
	if not run(b, 60.0, func(): return _to(v) == "church" and v.m.away.get("in", false)):
		return "다친 주민이 60초 안에 교회에 들지 않았다(away %s)" % [v.m.get("away")]
	var h0: float = v.hp
	run(b, 2.0)
	if absf(v.hp - h0 - F.HEAL * 2.0) > 0.1:
		return "교회 안 2초에 체력 %.2f → %.2f, 기대 +%.2f" % [h0, v.hp, F.HEAL * 2.0]
	if not run(b, 30.0, func(): return v.hp >= v.max_hp):
		return "교회 안에서 30초 동안 다 낫지 않았다(%.2f)" % v.hp
	if not run(b, 60.0, func(): return v.m.get("away") == null):
		return "다 나은 주민이 60초 안에 일과로 돌아오지 않았다(away %s)" % [v.m.get("away")]
	got = _hurt_one(F.HP * 0.5, false)
	if got is String:
		return got
	b = got[0]
	v = got[1]
	if not run(b, 30.0, func(): return _to(v) == "home" and v.m.away.get("in", false)):
		return "교회가 없는 판에서 다친 주민이 30초 안에 집에 들지 않았다(away %s)" % [v.m.get("away")]
	h0 = v.hp
	run(b, 2.0)
	var want: float = F.HEAL * F.HOME_HEAL * 2.0
	return check(absf(v.hp - h0 - want) <= 0.1, "집 안 2초에 체력 %.2f → %.2f, 기대 +%.2f" % [h0, v.hp, want])

# EV494 · S227·S221·S222: 체력이 0이면 죽어 가족에서 빠지고 lost가 1이다. 사제도 죽는다
func ev494():
	var F = _F()
	if F == null:
		return "src/sim/folk.gd가 없다"
	var b = _battle({"seed": 1})
	var h = b.build("house", H1)
	b.build("church", Vector2i(20, 3))
	var bad := _lacks(b)
	if bad != "":
		return bad
	var n: int = h.folk.size()
	var p: int = b.people.size()
	var v = b.people.filter(func(x): return x.home == h)[0]
	b.damage(v, F.HP)
	if v.alive or h.folk.size() != n - 1 or h.get("lost") != 1 or b.people.size() != p - 1:
		return "죽은 뒤 살아 있음 %s · 가족 %d → %d · lost %s · 주민 %d → %d" % [v.alive, n, h.folk.size(), h.get("lost"), p, b.people.size()]
	var priest: Array = b.people.filter(func(x): return x.home.kind == "church")
	if priest.size() != 1:
		return "교회 주민(사제)이 %d명이다" % priest.size()
	b.damage(priest[0], F.HP)
	var jobs: Array = load(BV).folk_of(b).map(func(f): return f.job)
	return check(not "priest" in jobs and b.people.size() == p - 2, "사제가 죽은 뒤 직업 %s · 주민 %d" % [jobs, b.people.size()])

# EV495 · S228: 웨이브 끝 세금은 다친 식구·죽은 식구마다 1 줄고, 죽은 몫은 다음 웨이브에도 빠지며, 식구가 다 죽으면 0이다
func ev495():
	var F = _F()
	if F == null:
		return "src/sim/folk.gd가 없다"
	var b = null
	var h = null
	for sd in range(1, 40):
		b = _battle({"seed": sd, "waves": [WAVE1, WAVE1, WAVE1, WAVE1, WAVE1, WAVE1]})
		h = b.build("house", H1)
		if h.folk.size() >= 2:
			break
	var bad := _lacks(b)
	if bad != "":
		return bad
	if h.folk.size() < 2:
		return "식구가 둘 이상인 씨앗이 없다"
	var R: int = b.ENEMY_KINDS.basic.reward
	var T: int = b.STRUCTURE_KINDS.house.tax
	var fam := func(): return b.people.filter(func(x): return x.home == h)
	var got := [_wave_income(b)]
	var a = fam.call()[0]
	b.damage(a, F.HP * 0.5)
	got.append(_wave_income(b))
	a.m["hp"] = F.HP
	b.damage(fam.call()[1], F.HP)
	got.append(_wave_income(b))
	got.append(_wave_income(b))
	for x in fam.call():
		b.damage(x, F.HP)
	got.append(_wave_income(b))
	var want := [R + T, R + T - 1, R + T - 1, R + T - 1, R]
	return check(got == want, "웨이브 끝마다 늘어난 골드 %s, 기대 %s(처치 %d + 세금)" % [got, want, R])

# 대피령을 내고 at에 적을 한 스텝 둔 뒤 웨이브를 끝낸다. 안 되면 그 까닭(글)
func _alarm(b, at: Vector2i) -> String:
	b.start_battle()
	b.step(DT)
	if not b.evacuate():
		return "웨이브 %d에 대피령이 나지 않았다" % b.wave_index
	b.spawn_enemy("basic", at, {"hp": BIG})
	b.step(DT)
	if not clear_wave(b) or b.state == "battle":
		return "웨이브가 끝나지 않았다"
	return ""

# 9행이 가로 성곽(성문 5·15·25열)이고 위쪽(0~8행)이 마을인 판에 집 하나
func _walled():
	var walls := []
	for x in 30:
		if not x in [5, 15, 25]:
			walls.append(Vector2i(x, 9))
	var b = battle({"base": Vector2i(15, 4), "spawns": [Vector2i(15, 19)], "village": Rect2i(0, 0, 30, 9), "base_hp": BIG, "seed": 1,
		"castle": {"walls": walls, "gates": [Vector2i(5, 9), Vector2i(15, 9), Vector2i(25, 9)], "wall_hp": 300, "gate_hp": 150},
		"waves": [WAVE1, WAVE1, WAVE1, WAVE1]})
	b.build("house", Vector2i(6, 3))
	return b

# EV496 · S229·I183 ⑤: 적이 성벽 바깥 3칸 안에 오지 않은 웨이브의 대피령은 신뢰 −1, 온 웨이브는 +1(5에서 그대로). 성곽이 없는 판은 마을 칸을 3칸 넓혀 잰다
func ev496():
	var boards := [[_walled(), Vector2i(20, 13), Vector2i(20, 12)], [_six({"seed": 1, "waves": [WAVE1, WAVE1, WAVE1, WAVE1]}), Vector2i(20, 9), Vector2i(20, 8)]]
	for k in boards.size():
		var b = boards[k][0]
		var bad := _lacks(b) if b != null else "판을 만들지 못했다"
		if bad != "":
			return bad
		var name: String = ["성곽 판", "성곽 없는 판"][k]
		b.trust = 3
		var seq := []
		for at in [boards[k][1], boards[k][2]]:
			bad = _alarm(b, at)
			if bad != "":
				return "%s: %s" % [name, bad]
			seq.append(b.trust)
		b.trust = 5
		bad = _alarm(b, boards[k][2])
		if bad != "":
			return "%s: %s" % [name, bad]
		seq.append(b.trust)
		if seq != [2, 3, 5]:
			return "%s: 거짓·정당·정당(신뢰 5) 뒤 신뢰 %s, 기대 [2, 3, 5]" % [name, seq]
	return ""

# EV497 · S229: 신뢰는 처음 5이고, 대피령 없이 라운드 둘이 지나면 1 는다
func ev497():
	var F = _F()
	var b = _battle({"seed": 1, "rounds": [[WAVE1], [WAVE1], [WAVE1]]})
	b.build("house", H1)
	var bad := _lacks(b)
	if bad != "":
		return bad
	if b.trust != F.TRUST:
		return "처음 신뢰가 %s다" % b.trust
	b.trust = 2
	var seq := []
	for r in 2:
		b.start_battle()
		if not clear_wave(b) or b.state != "cleared":
			return "%d라운드가 끝나지 않았다(%s)" % [r + 1, b.state]
		seq.append(b.trust)
		b.next_round()
	return check(seq == [2, 3], "대피령 없이 1·2라운드 뒤 신뢰 %s, 기대 [2, 3]" % [seq])

# EV498 · S229·S228·I183 ⑥: 신뢰 0으로 라운드가 끝나면 한 가구가 정문으로 걸어 나가 빈 집이 되고, 그 라운드 세금부터 빠지며, 신뢰는 1이 된다
func ev498():
	var F = _F()
	var b = _battle({"seed": 1, "rounds": [[WAVE1], [WAVE1]]})
	var homes := []
	for c in ROW6.slice(0, 3):
		homes.append(b.build("house", c))
	var bad := _lacks(b)
	if bad != "":
		return bad
	var size0: Array = homes.map(func(h): return h.folk.size())
	b.trust = 1
	var gold0: int = b.gold
	bad = _alarm(b, Vector2i(20, 15))  # 들판 깊은 칸: 거짓 대피령
	if bad != "":
		return bad
	if b.state != "cleared" or b.trust != F.TRUST_AFTER_LEAVE:
		return "라운드 끝 단계 %s · 신뢰 %s, 기대 cleared · %d" % [b.state, b.trust, F.TRUST_AFTER_LEAVE]
	var going: Array = homes.filter(func(h): return not h.folk.is_empty() and h.folk.all(func(m): return m.get("away", {}).get("to") == "out"))
	if going.size() != 1:
		return "떠나는 집이 %d채다" % going.size()
	var R: int = b.ENEMY_KINDS.basic.reward
	var T: int = b.STRUCTURE_KINDS.house.tax
	if b.gold - gold0 != 2 * R + 2 * T:
		return "라운드 끝 골드 +%d, 기대 +%d(처치 둘 + 남은 두 집 세금)" % [b.gold - gold0, 2 * R + 2 * T]
	var gone = going[0]
	if not run(b, 60.0, func(): return gone.folk.is_empty()):
		return "60초 안에 떠나는 가족이 사라지지 않았다(%d명 남음)" % gone.folk.size()
	var rest := []
	for i in homes.size():
		if homes[i] != gone:
			rest.append(homes[i].folk.size() == size0[i])
	return check(b.tax() == 2 * T and rest == [true, true], "떠난 뒤 세금 %d(기대 %d) · 남은 집 가족 그대로 %s" % [b.tax(), 2 * T, rest])

# EV499 · S226: 대피소는 30골드·2×2칸·자리 8이고 마을에만 짓는다
func ev499():
	var b = _battle()
	var d = b.STRUCTURE_KINDS.get("shelter")
	if d == null:
		return "data/structures/shelter.tres가 없다"
	if d.cost != 30 or d.size != Vector2i(2, 2) or d.get("seats") != 8:
		return "대피소 값 %s · 크기 %s · 자리 %s, 기대 30 · (2, 2) · 8" % [d.cost, d.size, d.get("seats")]
	var field = b.build("shelter", OUT)
	return check(b.build("shelter", SHELTER) != null and field == null, "마을 칸 대피소 %s · 들판 칸 대피소 %s" % [b.structure_at(SHELTER), field])

# EV500 · I183 ⑦: 대피소가 부서지면 안의 주민이 자기 집으로 간다
func ev500():
	var b = _crowd()
	if b is String:
		return b
	var bad := _evacuated(b)
	if bad != "":
		return bad
	var kept: Array = b.people.filter(func(v): return _to(v) == "shelter")
	if kept.size() != b.STRUCTURE_KINDS.shelter.seats:
		return "대피소에 든 주민 %d명" % kept.size()
	b.damage(b.structure_at(SHELTER), BIG)
	if b.structure_at(SHELTER) != null:
		return "대피소가 부서지지 않았다"
	return check(run(b, 30.0, func(): return kept.all(func(v): return _to(v) == "home")), "대피소가 부서진 30초 뒤 행선지 %s" % [kept.map(func(v): return _to(v))])
