extends "res://tests/eval/gd/lib.gd"
# 지형 이점·세 띠(S377): 성벽 위 사거리, 혼잡 칸, 포위, 노출, 세 띠 처치 골드, 집결 띠(건설 금지·밀림·깨우기), 영웅 사냥꾼, 지휘 보너스.
# lib.gd 머리의 API에 더하는 것: 스테이지 손잡이(battle.gd TERRAIN의 키 — 평가 기본 판은 모두 끈 값이라 이 판이 켠다) ·
#   Battle.knob(키) · zone_of(칸) → "front"|"bombard"|"band" · exposed(칸) 0~1 · gold_mult(칸) · in_band(칸) · in_crowd(칸) ·
#   taken_mult(유닛) · surround_bonus(유닛) · command_bonus(영웅) · Enemy.hunter · Battle._holds(유닛 → 붙잡은 적 수)

const W := [{"kind": "basic", "count": 1}]
# 켠 손잡이(S377 임시값과 같다). 마을 0~4행이라 성곽 아래 가장자리는 5행: 전장 띠 5~6행(harvest_rows 2), 포격 띠 7~15행, 집결 띠 16~19행(band_rows 4)
const ON := {"wall_range_bonus": 1.0, "crowd_slow": 0.5, "surround_from": 3, "surround_step": 0.15, "surround_cap": 0.6,
	"harvest_rows": 2, "band_rows": 4, "exposed_cap": 1.25, "exposed_light": 0.7, "exposed_block_mode": true, "flag_cover": 2.0,
	"bombard_gold": 0.5, "band_gold": 0.0, "band_push": 1.0, "band_wake": 6, "band_wake_every": 2.0,
	"hunts_hero": 0, "hunts_from": 1, "hunt_sight": 12.0, "command_per": 0.02, "command_cap": 0.3, "command_radius": 4.0}

# 준비 단계 판: 마을은 위 다섯 줄, 출현 칸은 맨 아래 줄 가운데(집결 띠가 아래쪽 줄이 되게, S51)
func _board(over := {}):
	var st := {"waves": [W], "base_hp": BIG, "village": Rect2i(0, 0, 30, 5), "spawns": [Vector2i(15, 19)], "merc_cap": 40}
	st.merge(ON, true)
	st.merge(over, true)
	return battle(st)

# 전투 단계를 연다: 웨이브 적 하나는 바로 치우고 구석의 멈춘 적이 전투 단계를 잇는다
func _fight(b) -> void:
	b.start_battle()
	b.step(DT)
	kill_all(b)
	b.spawn_enemy("basic", Vector2i(29, 0), {"speed": 0, "sight": 0, "damage": 0, "hp": BIG})

func _dummy(b, cell: Vector2i, over := {}):
	return b.spawn_enemy("basic", cell, {"speed": 0, "sight": 0, "damage": 0, "hp": BIG}.merged(over, true))

# 성곽 판(wall 스위트와 같은 꼴): 9행 성곽, 성문 (5,9)·(15,9)·(25,9), 마을 0~8행, 거점 (15,4), 출현 (15,19)
func _wall_board(over := {}):
	var gates := [Vector2i(5, 9), Vector2i(15, 9), Vector2i(25, 9)]
	var walls := []
	for x in 30:
		if Vector2i(x, 9) not in gates:
			walls.append(Vector2i(x, 9))
	var st := {"base": Vector2i(15, 4), "spawns": [Vector2i(15, 19)], "village": Rect2i(0, 0, 30, 9), "base_hp": BIG,
		"castle": {"walls": walls, "gates": gates, "wall_hp": 300, "gate_hp": 150}, "waves": [W], "merc_cap": 40}
	st.merge(ON, true)
	st.merge(over, true)
	return battle(st)

# 마을에 놓은 용병을 성벽 위 그 칸에 올린다. 못 오르면 null
func _up(b, kind: String, cell: Vector2i, over := {}):
	var m = b.place_merc(kind, Vector2i(10, 6), over)
	b.order_move([m], cell)
	return m if run(b, 30.0, func(): return m.on_wall and near(m.pos, cell)) else null

# EV1190 · S377 ①(S88 2026-11-17 변경): 성벽 위 원거리 용병의 사거리는 wall_range_bonus칸 는다. 사거리 5 궁수가 성벽 위에서 6칸 앞의 적을 치고, 보너스 0이면 치지 못한다
func ev1190():
	var top := Vector2i(10, 9)
	var out := []
	for bonus in [1.0, 0.0]:
		var b = _wall_board({"wall_range_bonus": bonus})
		var m = _up(b, "archer", top, {"accuracy": 1.0})
		if m == null:
			return "궁수가 성벽에 오르지 못했다"
		var e = _dummy(b, top + Vector2i(0, int(m.range) + 1))
		out.append(run(b, 10.0, func(): return e.hp < e.max_hp))
	return check(out == [true, false], "성벽 위 궁수(사거리 5)가 6칸 앞의 적을 침: 보너스 1 %s(쳐야 한다) · 보너스 0 %s(치지 못해야 한다)" % out)

# EV1191 · S377 ②: 열린 성문 둘레 crowd_pad(2)칸은 혼잡 칸이라 땅 적의 속도가 crowd_slow(0.5)배다. 닫힌 성문 둘레는 아니다
func ev1191():
	var b = _wall_board()
	var g = b.castle[Vector2i(15, 9)]
	var closed: bool = not b.in_crowd(Vector2i(15, 11))
	b.set_gate(g, true)
	b.step(DT)
	var cells: Array = [b.in_crowd(Vector2i(15, 11)), b.in_crowd(Vector2i(17, 7)), b.in_crowd(Vector2i(15, 12)), b.in_crowd(Vector2i(18, 9))]
	var e = b.spawn_enemy("basic", Vector2i(15, 12), {"sight": 0, "damage": 0, "speed": 2.0})
	run(b, 1.0, func(): return e.pos.y <= 11.0)  # 혼잡 칸 안에 든 다음부터 잰다
	var from: Vector2 = e.pos
	run(b, 1.0)
	var moved := from.distance_to(e.pos)
	return check(closed and cells == [true, true, false, false] and absf(moved - 1.0) <= 0.2,
		"닫힌 성문 둘레는 혼잡 아님 %s · 열린 뒤 (15,11)·(17,7) 혼잡, (15,12)·(18,9) 아님 %s · 혼잡 칸의 속도 2 적이 1초에 %.2f칸(1.0 ± 0.2)" % [closed, cells, moved])

# EV1192 · S377 ③: 붙잡은 적이 셋째부터 하나마다 받는 피해 +15%(상한 +60%). 블록 4 병사를 적 넷이 동시에 치면 피해 10짜리 넷에 52를 잃는다.
# 성벽 위는 면제다
func ev1192():
	var b = _board()
	var m = b.place_merc("soldier", Vector2i(10, 6), {"block": 4, "armor": 0.0, "hp": 1000.0, "damage": 0.0, "sight": 0})
	_fight(b)
	for d in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		b.spawn_enemy("basic", Vector2i(10, 6) + d, {"speed": 0, "sight": 3, "damage": 10.0, "attack_gap": 100.0, "cooldown": 1.0})
	run(b, 0.5)
	var holds: int = b._holds.get(m, 0)
	var mult: float = b.taken_mult(m)
	run(b, 1.5)
	var lost: float = 1000.0 - m.hp
	m.on_wall = true
	var wall: float = b.surround_bonus(m)
	return check(holds == 4 and absf(mult - 1.3) < 0.001 and absf(lost - 52.0) < 0.01 and wall == 0.0,
		"붙잡은 적 %d(4) · 배율 %.3f(1.3) · 잃은 체력 %.2f(52) · 성벽 위 포위 보너스 %s(0)" % [holds, mult, lost, wall])

# EV1193 · S377 ⑤: 노출은 포격 띠 첫 줄 1.0에서 마지막 줄 exposed_cap(1.25)까지 줄마다 고르게 오르고 집결 띠는 cap이다. 전장 띠·깃발 둘레 flag_cover칸은 1이다.
# 포격 띠 끝(15행)의 병사는 피해 100에 125를 잃는다
func ev1193():
	var b = _board()
	var m = b.place_merc("soldier", Vector2i(10, 15), {"armor": 0.0, "hp": 1000.0, "damage": 0.0, "sight": 0})
	var zones := [b.zone_of(Vector2i(10, 6)), b.zone_of(Vector2i(10, 7)), b.zone_of(Vector2i(10, 15)), b.zone_of(Vector2i(10, 16))]
	var ex := [b.exposed(Vector2i(10, 6)), b.exposed(Vector2i(10, 7)), b.exposed(Vector2i(10, 11)), b.exposed(Vector2i(10, 15)), b.exposed(Vector2i(10, 18))]
	_fight(b)
	var mult: float = b.taken_mult(m)
	b.spawn_enemy("basic", Vector2i(11, 15), {"speed": 0, "sight": 3, "damage": 100.0, "attack_gap": 100.0, "cooldown": 1.0})
	run(b, 2.0)
	var lost: float = 1000.0 - m.hp
	var flagged: bool = b.plant_flag([m], Vector2i(10, 15))
	var covered: float = b.taken_mult(m)
	return check(zones == ["front", "bombard", "bombard", "band"] and ex == [0.0, 0.0, 0.5, 1.0, 1.0] and absf(mult - 1.25) < 0.001 and absf(lost - 125.0) < 0.01 and flagged and absf(covered - 1.0) < 0.001,
		"지대 %s · 노출 %s(0·0·0.5·1·1) · 15행 배율 %.3f(1.25) · 잃은 체력 %.2f(125) · 깃발 뒤 배율 %.3f(1.0)" % [zones, ex, mult, lost, covered])

# EV1194 · S377 ⑤(S159 2026-11-17 변경): 노출 띠의 유닛은 블록 자리가 차도 적이 붙는다(셋이 모두 붙잡는다). 전장 띠에서는 하나만 붙잡고, exposed_block_mode를 끄면 노출 띠에서도 하나다
func ev1194():
	var out := []
	for at in [[Vector2i(10, 12), true], [Vector2i(10, 6), true], [Vector2i(10, 12), false]]:
		var b = _board({"exposed_block_mode": at[1]})
		var m = b.place_merc("soldier", at[0], {"damage": 0.0, "sight": 0})
		_fight(b)
		for d in [Vector2i(-2, 0), Vector2i(2, 0), Vector2i(0, 2)]:
			b.spawn_enemy("basic", at[0] + d, {"speed": 0, "sight": 5, "damage": 0})
		run(b, 0.5)
		out.append(b._holds.get(m, 0))
	return check(out == [3, 1, 1], "붙잡은 적 수 %s(노출 띠 3 · 전장 띠 1 · 노출 블록 무시 끔 1)" % [out])

# EV1195 · S377 ⑥(I176 2026-11-17 변경): 처치 골드는 쓰러진 자리의 띠 배율을 곱한다. 처치 보상 10 적을 전장 띠·포격 띠·집결 띠에서 처치하면 골드 10·15·15다
func ev1195():
	var b = _board({"gold": 0})
	_fight(b)
	var got := []
	for c in [Vector2i(10, 6), Vector2i(10, 10), Vector2i(10, 18)]:
		b.damage(b.spawn_enemy("basic", c, {"reward": 10}), BIG)
		got.append(b.gold)
	var mults := [b.gold_mult(Vector2i(10, 6)), b.gold_mult(Vector2i(10, 10)), b.gold_mult(Vector2i(10, 18))]
	return check(got == [10, 15, 15] and mults == [1.0, 0.5, 0.0], "골드 %s(10·15·15) · 배율 %s(1·0.5·0)" % [got, mults])

# EV1196 · S377 ⑦(S43 2026-11-17 변경): 집결 띠(맨 아래 band_rows줄)에는 아무것도 짓지 못한다. 그 위 들판에는 짓는다
func ev1196():
	var b = _board()
	var band: bool = b.can_build("tower", Vector2i(10, 16)) or b.can_build("tower", Vector2i(10, 19)) or b.can_build("barrier", Vector2i(20, 17))
	var field: bool = b.can_build("tower", Vector2i(10, 14)) and b.can_build("tower", Vector2i(10, 8))
	var cells: Array = b.placeable_cells("tower")
	var in_band: bool = cells.any(func(c): return b.in_band(c))
	return check(not band and field and not in_band and not cells.is_empty(),
		"집결 띠에 지음 %s(안 돼야 한다) · 들판에 지음 %s · 놓을 수 있는 칸 %d개 가운데 집결 띠 칸 있음 %s" % [band, field, cells.size(), in_band])

# EV1197 · S377 ⑦: 집결 띠에 든 아군은 성곽 쪽으로 band_push(1)칸/초 밀리고, 든 동안 band_wake_every(2)초마다 가장 가까운 잠든 적 band_wake(6)마리가 깨어난다
func ev1197():
	var b = _board({"waves": [W, [{"kind": "basic", "count": 10}]]})
	var m = b.place_merc("soldier", Vector2i(15, 12), {"damage": 0.0, "sight": 0, "hp": BIG})
	b.start_battle()
	run(b, 3.0, func(): return b.dormant.size() == 10 and not b.enemies.is_empty())  # 첫 웨이브의 적이 나온 뒤 치운다
	kill_all(b)
	var dormant: int = b.dormant.size()
	var foes: int = b.enemies.size()
	m.pos = Vector2(15, 19)
	run(b, 1.0)
	var pushed: float = 19.0 - m.pos.y
	run(b, 1.1)
	var woke: int = b.enemies.size() - foes
	return check(dormant == 10 and absf(pushed - 1.0) <= 0.15 and woke == 6 and b.dormant.size() == 4,
		"잠든 적 %d(10) · 1초에 밀린 거리 %.2f(1.0) · 2.1초에 깨어난 적 %d(6) · 남은 잠든 적 %d(4)" % [dormant, pushed, woke, b.dormant.size()])

# EV1198 · S377 ⑧(S4 2026-11-17 변경): hunts_from 라운드부터 파도마다 hunts_hero마리가 사냥꾼이다. 사냥꾼은 hunt_sight칸 안의 마을·성벽 위·혼잡 칸 밖 영웅을
# 더 가까운 용병보다 먼저 노리고, 영웅이 마을에 들어가면 일반 적과 같다
func ev1198():
	var b = _board({"hero_start": Vector2i(10, 12), "hunts_hero": 2, "waves": [[{"kind": "basic", "count": 5}]]})
	b.start_battle()
	run(b, 3.0, func(): return b.enemies.size() >= 5)
	var hunters: int = b.enemies.filter(func(e): return e.hunter).size()
	var c = _board({"hero_start": Vector2i(10, 12)})
	var h = c.heroes[0]
	var m = c.place_merc("soldier", Vector2i(6, 10), {"damage": 0.0, "sight": 0})
	_fight(c)
	var e = c.spawn_enemy("basic", Vector2i(4, 10), {"speed": 0, "sight": 3, "damage": 0})
	var plain = c._target_of(e)
	e.hunter = true
	var hunted = c._target_of(e)
	h.pos = Vector2(10, 2)
	var home = c._target_of(e)
	return check(hunters == 2 and plain == m and hunted == h and home == m,
		"사냥꾼 %d(2) · 일반 적의 대상 용병 %s · 사냥꾼의 대상 영웅 %s · 영웅이 마을에 들면 용병 %s" % [hunters, plain == m, hunted == h, home == m])

# EV1199 · S377 ⑨: 영웅 둘레 command_radius(4)칸 안의 다른 아군 1명마다 피해 +command_per(2%), 상한 command_cap(30%). 아군 셋이면 공격력 배율 1.06, 스물이면 1.3, 5칸 밖은 세지 않는다
func ev1199():
	var b = _board({"hero_start": Vector2i(10, 12)})
	var h = b.heroes[0]
	var none: float = b._might(h)
	b.place_merc("soldier", Vector2i(15, 12))
	var far: float = b.command_bonus(h)
	for c in [Vector2i(9, 12), Vector2i(11, 12), Vector2i(10, 13)]:
		b.place_merc("soldier", c)
	var three: float = b._might(h)
	for y in range(10, 15):
		for x in range(8, 13):
			if b.units.all(func(u): return u.pos != Vector2(x, y)):
				b.place_merc("soldier", Vector2i(x, y))
	var crowd: int = b.units.filter(func(u): return u != h and u.pos.distance_to(h.pos) <= 4.0).size()
	var many: float = b._might(h)
	return check(none == 1.0 and far == 0.0 and absf(three - 1.06) < 0.001 and crowd >= 15 and absf(many - 1.3) < 0.001,
		"혼자 %.2f(1.0) · 5칸 밖 하나 %.2f(0) · 셋 %.3f(1.06) · 4칸 안 %d명 %.3f(1.3)" % [none, far, three, crowd, many])
