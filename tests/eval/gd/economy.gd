extends "res://tests/eval/gd/lib.gd"
# 세금 시점·평시 보너스(I46 2026-11-17 변경), 생산 대기열(S20 2026-11-17 변경, I312), 사제 준비 단계 가드(S362 변경), 교회 용병 치료·둘레 회복(S137 변경),
# 전투 중 공병 일 시간 배율(S22 변경). lib.gd·house.gd 머리의 API에 더하는 것:
#   stage 키 calm_mult · train_scale · build_time_scale · Battle.tax_due() · Battle.peaceful() · Battle.recruit(시설, 종류) → 전투 단계에 대기열이면 사전 {kind, paid, left}
#   시설.queue(배열) · Battle.cancel_train(시설, 종류 = "") → bool · Battle.QUEUE_CAP · Battle.heal_mercs_cost() · Battle.heal_mercs() → bool · Battle.work_scale()

const W := [{"kind": "basic", "count": 1}]
const H1 := Vector2i(10, 3)
const H2 := Vector2i(14, 3)
const CHURCH := Vector2i(20, 2)

func _town(over := {}):
	var st := {"village": Rect2i(0, 0, 30, 6), "base_hp": BIG, "waves": [W, W, W]}
	st.merge(over, true)
	return battle(st)

func _houses(b) -> bool:
	return b.build("house", H1) != null and b.build("house", H2) != null

# 움직이지도 치지도 않는 적 하나를 구석에 둔다(전투 단계가 이어지게)
func _idle(b, cell := Vector2i(0, 19)):
	return b.spawn_enemy("basic", cell, {"speed": 0, "sight": 0, "damage": 0, "hp": BIG})

# EV1176 · I46 2026-11-17 변경: 세금은 다음 웨이브의 첫 파도가 돌격하는 순간과 라운드를 이기는 순간에 걷는다. ▶(라운드 첫 돌격)와 웨이브 끝에는 걷지 않는다
func ev1176():
	var b = _town({"waves": null, "rounds": [[W, W], [W]]})
	if not _houses(b):
		return "집을 짓지 못했다"
	var T: int = 2 * b.STRUCTURE_KINDS.house.tax
	var R: int = b.ENEMY_KINDS.basic.reward
	var g: int = b.gold
	b.start_battle()
	var at_start: int = b.gold - g
	clear_wave(b)
	var wave1: int = b.gold - g
	g = b.gold
	b.start_battle()  # 2웨이브 첫 파도 돌격(북): 다음 스텝에 돌격하며 걷는다
	b.step(DT)
	var at_charge: int = b.gold - g
	clear_wave(b)
	var at_end: int = b.gold - g
	return check(at_start == 0 and wave1 == R and at_charge == T and at_end == T + R + T and b.state == "cleared",
		"▶ 직후 +%d(0) · 1웨이브 끝까지 +%d(%d) · 2웨이브 돌격 순간 +%d(%d) · 라운드 끝(%s)까지 +%d(%d)" % [at_start, wave1, R, at_charge, T, b.state, at_end, T + R + T])

# EV1177 · I46 2026-11-17 변경: 걷는 순간 성벽 근처(성곽 없는 판은 마을 둘레 3칸) 안에 적이 없으면 calm_mult배(1.5, 내림), 적이 있으면 그대로다
func ev1177():
	var out := []
	for near in [false, true]:
		var b = _town({"calm_mult": 1.5})
		if not _houses(b):
			return "집을 짓지 못했다"
		b.start_battle()
		clear_wave(b)
		if near:
			_idle(b, Vector2i(15, 8))  # 마을 아래 변(5행)에서 3칸 안
		var g: int = b.gold
		var calm: bool = b.peaceful()
		b.start_battle()
		b.step(DT)
		out.append([calm, b.gold - g])
	var T: int = 2 * 5
	return check(out == [[true, floori(T * 1.5)], [false, T]], "[평시 여부, 걷은 세금] 적 없음 %s([true, %d]) · 적 근처 %s([false, %d])" % [out[0], floori(T * 1.5), out[1], T])

# EV1178 · S20 2026-11-17 변경: 전투 단계에 거점에서 산 병사는 대기열에 들어(골드·인구는 산 순간) train_time(6초)마다 하나씩 거점 옆 칸에 나와 집결 지점으로 간다. 대기열은 5까지다
func ev1178():
	var b = _town({"train_scale": 1.0, "waves": [[{"kind": "basic", "count": 1}]]})
	b.live_prep = true
	var cost: int = b.MERC_KINDS.soldier.cost
	b.start_battle()
	_idle(b)
	var g: int = b.gold
	var got := []
	for i in 6:
		got.append(b.recruit(b.base, "soldier"))
	var queued: bool = got.slice(0, 5).all(func(j): return j is Dictionary) and got[5] == null and b.base.queue.size() == 5
	var paid: bool = g - b.gold == 5 * cost and b.pop_used() == 5
	var soldiers := func(): return b.units.filter(func(u): return u.kind == "soldier").size()
	run(b, 5.9)
	var early: int = soldiers.call()
	run(b, 0.2)
	var first: int = soldiers.call()
	run(b, 6.0)
	var second: int = soldiers.call()
	var walked := run(b, 20.0, func(): return b.units.filter(func(u): return u.kind == "soldier").all(func(u): return u.pos.distance_to(Vector2(b.base.rally)) < 2.5))
	return check(queued and paid and early == 0 and first == 1 and second == 2 and b.base.queue.size() == 3 and walked,
		"대기열 5·여섯째 거부 %s · 골드 −%d(%d)·인구 %d(5) %s · 5.9초 %d(0) · 6.1초 %d(1) · 12.1초 %d(2) · 남은 대기 %d(3) · 집결 지점 둘레 도착 %s" % [queued, g - b.gold, 5 * cost, b.pop_used(), paid, early, first, second, b.base.queue.size(), walked])

# EV1179 · S20 2026-11-17 변경: 대기 차례를 취소하면 낸 골드가 모두 돌아오고, 라운드가 끝나면 남은 차례는 바로 나온다. 라운드 첫 준비의 구매는 바로 나온다
func ev1179():
	var b = _town({"train_scale": 1.0, "waves": [[{"kind": "basic", "count": 1}]]})
	b.live_prep = true
	var cost: int = b.MERC_KINDS.soldier.cost
	var m = b.recruit(b.base, "soldier")
	var instant: bool = m != null and not m is Dictionary and m in b.units
	b.start_battle()
	var idle = _idle(b)
	b.recruit(b.base, "soldier")
	b.recruit(b.base, "archer")
	b.recruit(b.base, "soldier")
	var g: int = b.gold
	var cancelled: bool = b.cancel_train(b.base, "soldier") and b.gold - g == cost and b.base.queue.size() == 2 and b.base.queue[1].kind == "archer"
	var none: bool = not b.cancel_train(b.base, "engineer")
	clear_round(b)
	var out: int = b.units.filter(func(u): return u.kind in ["soldier", "archer"]).size()
	return check(instant and cancelled and none and b.state == "won" and b.base.queue.is_empty() and out == 3,
		"준비 단계 바로 나옴 %s · 취소 환불 %s · 없는 종류 취소 거부 %s · 라운드 끝(%s) 뒤 대기 %d(0)·나온 용병 %d(3)" % [instant, cancelled, none, b.state, b.base.queue.size(), out])

# EV1180 · S362 2026-11-17 변경: 사제는 준비 단계에 고치지 않고 전투 단계에 고친다
func ev1180():
	var b = battle({"waves": [W]})
	b.place_merc("cleric", Vector2i(5, 10))
	var m = b.place_merc("soldier", Vector2i(6, 10))
	if m == null:
		return "병사를 놓지 못했다"
	m.hp = 30.0
	run(b, 5.0)
	var prep_hp: float = m.hp
	_idle(b)
	b.start_battle()
	run(b, 2.5)
	return check(prep_hp == 30.0 and m.hp > 30.0, "준비 단계 5초 뒤 체력 %.0f(30) · 전투 단계 2.5초 뒤 %.0f(30보다 큼)" % [prep_hp, m.hp])

# EV1181 · S137 2026-11-17 변경: 교회 «용병 치료»는 라운드 첫 준비에 다친 용병마다 잃은 체력 × (낸 골드 ÷ 최대 체력)을 올림해 더한 골드로 모두 가득 채우고, 전투 단계에는 거부된다.
#   전투 단계에 완성된 교회 가운데 4칸 안의 다친 용병은 초당 2씩 찬다(4칸 밖은 그대로)
func ev1181():
	var b = _town()
	if b.build("church", CHURCH) == null:
		return "교회를 짓지 못했다"
	var s = b.place_merc("soldier", Vector2i(10, 10))
	var a = b.place_merc("archer", Vector2i(12, 10))
	if s == null or a == null:
		return "용병을 놓지 못했다"
	s.hp = s.max_hp - 30.0
	a.hp = a.max_hp - 10.0
	var want: int = ceili(30.0 * s.paid / s.max_hp - 0.0001) + ceili(10.0 * a.paid / a.max_hp - 0.0001)
	var cost: int = b.heal_mercs_cost()
	var g: int = b.gold
	var healed: bool = b.heal_mercs() and s.hp == s.max_hp and a.hp == a.max_hp and g - b.gold == want
	var mid: Vector2 = b.middle(b.structures[CHURCH])
	s.pos = mid + Vector2(2, 0)
	a.pos = mid + Vector2(6, 0)
	s.hp = s.max_hp - 10.0
	a.hp = a.max_hp - 10.0
	b.start_battle()
	_idle(b)
	var refused: bool = not b.heal_mercs() and s.hp == s.max_hp - 10.0
	run(b, 2.0)
	var near_up: float = s.hp - (s.max_hp - 10.0)
	var far_up: float = a.hp - (a.max_hp - 10.0)
	return check(cost == want and healed and refused and absf(near_up - 4.0) < 0.3 and far_up == 0.0,
		"치료비 %d(%d) · 치료 %s · 전투 단계 거부 %s · 교회 2칸 옆 2초 회복 %.2f(4) · 6칸 밖 %.2f(0)" % [cost, want, healed, refused, near_up, far_up])

# EV1182 · S22 2026-11-17 변경: build_time_scale 2인 판의 전투 단계에 공병이 짓는 타워(짓는 시간 4초)는 5초에 미완성이고 9초 안에 완성된다. 배율이 없으면 4.5초 안에 완성된다
func ev1182():
	var out := []
	for scale in [2.0, 1.0]:
		var b = battle({"waves": [W], "build_time_scale": scale})
		b.place_merc("engineer", Vector2i(12, 11))
		b.start_battle()
		_idle(b)
		var t = b.build("tower", Vector2i(12, 10))
		if t == null:
			return "전투 단계에 타워를 지시하지 못했다(배율 %s)" % scale
		var fast := run(b, 4.5, func(): return t.complete)
		var slow := fast or run(b, 4.5, func(): return t.complete)
		out.append([fast, slow])
	return check(out == [[false, true], [true, true]], "[4.5초 안 완성, 9초 안 완성] 배율 2 %s([false, true]) · 배율 1 %s([true, true])" % [out[0], out[1]])
