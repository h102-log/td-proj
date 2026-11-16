extends "res://tests/eval/gd/lib.gd"
# WBS 3.5 영입소(S122~S124·I103~I109) → 2026-11-16: 영웅 고르기(S54 2026-11-16 변경·S373·I303). lib.gd·rounds.gd·heroes.gd 머리의 계약에 더하는 API:
#   stage 키 hero_cells: [칸, …] — 출전 칸(I107) · seed: int — 난수 씨앗(미션을 뽑는다)
#   res://data/hire.tres — lineup(고르는 수 = 출전 인원, S123) · gear_cost · forge_cap · relic_cost · relic_cap. Battle.HIRE가 이 Resource다
#   state "hiring" — 도전 시작 전 영웅 고르기 창(S122·S373). Battle.begin_hiring() — 1라운드 웨이브 1의 준비 단계(restart 직후)에서 연다
#   Battle.next_round() -> bool — 고르기 창이나 라운드 사이에서 보유 영웅을 전장에 반영하고 1라운드나 다음 라운드의 첫 준비 단계로 간다. 영웅이 모자라도(0명도) 넘어간다(I106)
#   Battle.offers — 고르기 창의 목록: 영웅 종류 여섯(S97 표 차례). 고른 뒤에도 칸이 비지 않는다. 평가가 바꿔 넣을 수 있다
#   Battle.roster — 보유 영웅 = 출전 영웅(고른 순서) · Battle.heroes — 전장에 나온 출전 영웅(보유 순서) · Battle.hero — 첫 출전 영웅
#   Battle.hire(칸 번호) -> 영웅|null — 고른다(골드 없음). 고르기 창과 영웅이 출전 인원보다 적은 라운드 사이에만 받고, 같은 영웅·출전 인원을 넘는 것은 거부한다
#   Battle.dismiss(영웅) — 뺀다. 고르기 창과 라운드 사이에만 받는다(이름은 영입이 있던 때의 것이다, I303 ①)
#   Controls: 1·2·3 키 — 출전 영웅 1·2·3을 고른다(I108)
#   Battle.restart() — 새 도전(1라운드 웨이브 1의 준비 단계). 보유를 비운다
# 수치는 Battle.HIRE와 영웅 데이터에서 읽는다. EV194만 데이터 파일을 대조한다

const HERO_SIX := ["aias", "sylvia", "seraphina", "vesper", "ignis", "chronos"]  # 고르기 창의 목록 = S97 표 차례(S373)

const CELLS := [Vector2i(10, 5), Vector2i(12, 5), Vector2i(14, 5)]  # 출전 칸(출전 3명, S123)
const ONE := [{"kind": "basic", "count": 1}]
const ONE_ONE := [[ONE], [ONE]]  # 라운드 2개, 라운드마다 적 1마리짜리 웨이브 하나

# 고르기 창이 열린 판(출전 칸·씨앗·라운드 2개)
func _hiring(over := {}):
	var stage := {"hero_cells": CELLS, "seed": 7, "base_hp": BIG, "rounds": ONE_ONE}
	stage.merge(over, true)
	var b = battle(stage)
	b.begin_hiring()
	return b

# 시험 스테이지(main.gd stage())로 만든 판
func _main():
	return load("res://src/sim/battle.gd").new(load("res://src/main.gd").stage())

func _key(c, key: int) -> void:
	var ev := InputEventKey.new()
	ev.keycode = key
	ev.pressed = true
	c.handle(ev)

# 지금 라운드의 웨이브를 모두 이긴다. 라운드 사이나 승리가 되면 참
func _win_round(b) -> bool:
	for i in 20:
		if b.state != "prep":
			break
		b.start_battle()
		if not clear_wave(b):
			return false
	return b.state in ["cleared", "won"]

func _kinds(hs: Array) -> Array:
	return hs.map(func(h): return h.kind)

# EV192 · S122: 도전 시작 전 고르기 창이 먼저 뜨고, 골드 없이 고른 영웅이 1라운드 첫 준비 단계에 출전 칸에 선다
func ev192():
	var b = _main()
	var stage: Dictionary = load("res://src/main.gd").stage()
	var cells: Array = stage.get("hero_cells", [])
	b.begin_hiring()
	if b.state != "hiring" or not b.heroes.is_empty() or b.hero != null or b.gold != stage.gold:
		return "고르기 창이 아니거나 영웅이 있다(%s, 영웅 %d명, hero %s, 골드 %d)" % [b.state, b.heroes.size(), b.hero, b.gold]
	if b.offers != HERO_SIX:
		return "목록이 %s다(영웅 여섯이 S97 표 차례 %s여야 한다)" % [b.offers, HERO_SIX]
	var h = b.hire(0)
	if h == null or cells.is_empty():
		return "목록의 첫 영웅을 고르지 못했거나 출전 칸이 없다(%s)" % [cells]
	var started: bool = b.next_round()
	return check(started and b.state == "prep" and b.round_index == 0 and b.wave_index == 0 and b.heroes == [h] and b.hero == h
		and h.present and h.hp == h.max_hp and near(h.pos, cells[0], 0.01) and b.gold == stage.gold,
		"넘어감 %s · %s %d라운드 웨이브 %d · 출전 %d명 · 영웅 자리 %s 체력 %d/%d · 골드 %d(시작 골드 %d 그대로여야 한다)" % [started, b.state, b.round_index + 1, b.wave_index + 1, b.heroes.size(), h.pos, h.hp, h.max_hp, b.gold, stage.gold])

# EV193 · I109: 도전 시작 전 영입 창에서는 맵 명령을 받지 않는다
func ev193():
	var b = _hiring({"gold": 500})
	var c = controls(b)
	var cell := Vector2i(15, 10)
	_key(c, KEY_MINUS)
	click(c, MOUSE_BUTTON_LEFT, px(cell))
	b.start_battle()
	var wall = b.build("wall", cell + Vector2i(0, 2))
	var merc = b.place_merc("soldier", cell + Vector2i(0, 4))
	run(b, 1.0)
	return check(b.state == "hiring" and c.placing == "" and wall == null and merc == null and b.structures.is_empty() and b.units.is_empty() and b.gold == 500,
		"단계 %s · 놓기 모드 «%s» · 방벽 %s · 용병 %s · 구조물 %d · 유닛 %d · 골드 %d" % [b.state, c.placing, wall, merc, b.structures.size(), b.units.size(), b.gold])

# EV194 · S123: data/hire.tres에 남은 영웅 수치는 출전 인원(고르는 수) 3뿐이다. 영입이 있던 때의 칸은 없다
func ev194():
	var r = load("res://data/hire.tres")
	if r == null:
		return "data/hire.tres를 불러오지 못했다"
	var left: Array = ["slots", "odds", "cost", "reroll", "reroll_step", "cap"].filter(func(k): return r.get(k) != null)
	return check(r.get("lineup") == 3 and left.is_empty(), "출전 인원 %s(3이어야 한다) · 남아 있는 영입 칸 %s(없어야 한다)" % [r.get("lineup"), left])

# EV197 · S123: 고르는 데 골드가 들지 않고, 출전 인원(lineup)만큼만 고른다. 같은 영웅은 두 번 고르지 못한다. lineup이 고르는 수 손잡이다
func ev197():
	var b = _hiring({"gold": 300})
	if b.offers != HERO_SIX:
		return "고르기 창의 목록이 %s다(%s여야 한다)" % [b.offers, HERO_SIX]
	var k = b.hire(0)
	var p = b.hire(2)
	var c = b.hire(5)
	if k == null or p == null or c == null or b.roster != [k, p, c] or b.gold != 300:
		return "아이아스·세라피나·크로노스를 고른 뒤 보유 %s · 골드 %d(셋 모두 보유에 들고 300 그대로여야 한다)" % [_kinds(b.roster), b.gold]
	var fourth = b.hire(4)
	var capped: bool = fourth == null and b.roster == [k, p, c]
	b.dismiss(c)
	var twice = b.hire(2)
	var m = b.hire(4)
	var swapped: bool = twice == null and m != null and b.roster == [k, p, m] and b.gold == 300
	var d = _hiring()
	d.HIRE = d.HIRE.duplicate()
	d.HIRE.lineup = 2
	var two := [d.hire(0), d.hire(1)]
	var third = d.hire(2)
	var knob: bool = not two.has(null) and third == null and d.roster.size() == 2
	return check(capped and swapped and knob,
		"넷째 거부 %s · 크로노스를 뺀 뒤 세라피나 다시 고르기 거부·이그니스 받음 %s(보유 %s, 골드 %d) · lineup 2인 판에서 셋째 거부 %s(보유 %d명)" % [capped, swapped, _kinds(b.roster), b.gold, knob, d.roster.size()])

# EV198 · S124: 계속 출전하는 영웅은 자리·체력이 그대로, 빠진 영웅은 사라지고, 새로 출전한 영웅은 출전 칸에 최대 체력으로 선다
func ev198():
	var b = _hiring()
	b.offers = ["aias", "seraphina", "ignis"]
	var k = b.hire(0)
	var p = b.hire(1)
	b.next_round()
	var to: Vector2i = CELLS[0] + Vector2i(0, 3)
	b.order_move([k], to)
	if not run(b, 10.0, func(): return near(k.pos, to)):
		return "아이아스가 옮겨 가지 않았다(%s)" % k.pos
	b.damage(k, 30)
	var hp: float = k.hp
	if not _win_round(b) or b.state != "cleared":
		return "1라운드를 이겨 라운드 사이가 되지 않았다(%s)" % b.state
	var at: Vector2 = k.pos
	b.dismiss(p)  # 출전 전환이 없어졌다(S54 2026-11-16 변경). 빼고 고르는 것으로 같은 세 구절을 잰다
	b.offers[2] = "ignis"
	var m = b.hire(2)
	if m == null or p in b.roster:
		return "라운드 사이에 세라피나를 빼고 이그니스를 고르지 못했다(보유 %s)" % [_kinds(b.roster)]
	b.next_round()
	var kept: bool = k in b.units and k.pos.distance_to(at) < 0.1 and k.hp == hp
	var gone: bool = p not in b.units and p not in b.heroes
	var fresh: bool = m in b.units and m.present and near(m.pos, CELLS[1], 0.01) and m.hp == m.max_hp
	return check(b.state == "prep" and kept and gone and fresh, "아이아스 그대로 %s · 세라피나 사라짐 %s · 이그니스가 출전 칸에 최대 체력 %s (%s)" % [kept, gone, fresh, m.pos])

# EV201 · I106: 판 함수는 영웅 없이도 시작하고, 고른 영웅은 모두 출전하며 다음 라운드에도 그대로다
func ev201():
	var b = _hiring()
	var c = controls(b)
	var started: bool = b.next_round() and b.state == "prep" and b.hero == null and b.heroes.is_empty()
	_key(c, KEY_Q)
	_key(c, KEY_W)
	var d = _hiring({"gold": BIG})
	d.offers = ["aias", "seraphina", "ignis"]
	var team := [d.hire(0), d.hire(1), d.hire(2)]
	d.next_round()
	var lined: bool = not team.has(null) and d.heroes == team
	if not _win_round(d):
		return "1라운드를 이기지 못했다(%s)" % d.state
	d.next_round()
	var same: bool = d.state == "prep" and d.heroes == team
	return check(started and lined and same, "영웅 없이 시작 %s · 고른 셋이 고른 차례로 출전 %s · 다음 라운드도 같은 셋·같은 차례 %s" % [started, lined, same])

# EV202 · I107: 시험 스테이지의 출전 칸은 정문 문루 앞 (29,61)·(31,61)·(30,61)이고, 영웅은 보유 순서대로 서며, 출전 칸에는 짓지 못한다
func ev202():
	var cells: Array = load("res://src/main.gd").stage().get("hero_cells", [])
	if cells != [Vector2i(31, 65), Vector2i(33, 65), Vector2i(32, 65)]:
		return "출전 칸이 %s다" % [cells]
	var b = _main()
	b.begin_hiring()
	b.gold = BIG
	b.offers = ["aias", "sylvia", "seraphina"]  # 같은 영웅은 두 번 고르지 못한다(I303 ①)
	var team := [b.hire(0), b.hire(1), b.hire(2)]
	b.next_round()
	var placed := true
	for i in 3:
		placed = placed and near(team[i].pos, cells[i], 0.01)
		b.order_move([team[i]], cells[i] + Vector2i(0, 4))
	run(b, 5.0)
	var blocked: bool = cells.all(func(c): return b.build("wall", c) == null)
	var beside = b.build("wall", cells[0] + Vector2i(-1, 0))
	return check(placed and blocked and beside != null, "보유 순서대로 섬 %s · 출전 칸에 못 지음 %s · 옆 칸에 지음 %s" % [placed, blocked, beside != null])

# EV203 · I108: 출전 순서는 고른 순서이고 첫 출전 영웅이 hero다. 2 키로 고른 영웅이 스킬을 쓰고, 다음 라운드에도 차례가 그대로다
func ev203():
	var b = _hiring()
	b.offers = ["aias", "seraphina", "chronos"]
	var m = b.hire(2)  # 고른 순서: 크로노스 → 아이아스 → 세라피나(목록 차례와 다르게)
	var k = b.hire(0)
	var p = b.hire(1)
	for h in b.roster:
		b.add_xp(h, 50)  # E는 Lv3에 열린다(S145)
	b.next_round()
	if b.heroes != [m, k, p] or b.hero != m:
		return "출전 영웅 %s · hero %s (크로노스, 아이아스, 세라피나 순이고 hero는 크로노스여야 한다)" % [_kinds(b.heroes), b.hero.kind if b.hero else "없음"]
	var c = controls(b)
	_key(c, KEY_2)
	var picked: bool = c.selected == [k]
	b.start_battle()  # 스킬은 전투 단계에만 쓴다(S136)
	_key(c, KEY_E)  # 아이아스 E는 즉시 칸이다
	var second_e: bool = k.skill_uses == 1 and m.skill_uses == 0 and p.skill_uses == 0
	if not clear_wave(b) or not _win_round(b):
		return "1라운드를 이기지 못했다(%s)" % b.state
	b.next_round()
	var same: bool = b.state == "prep" and b.heroes == [m, k, p]
	_key(c, KEY_3)
	var third: bool = c.selected == [p]
	return check(picked and second_e and same and third, "2 키로 아이아스 고름 %s · 아이아스만 E %s · 다음 라운드도 같은 차례 %s · 3 키로 세라피나 고름 %s" % [picked, second_e, same, third])

# ── 영웅 고르기(S54 2026-11-16 변경) ──

# EV1127 · S54: 영웅 여섯 가운데 셋을 골드 없이 고르고, 그 셋이 도전 내내 출전한다. 준비·전투 단계에는 고르지도 빼지도 못한다
func ev1127():
	var b = _hiring({"gold": 500})
	if b.offers != HERO_SIX:
		return "고르기 창의 목록이 %s다(%s여야 한다)" % [b.offers, HERO_SIX]
	var m = b.hire(4)
	var k = b.hire(0)
	var p = b.hire(2)
	if m == null or k == null or p == null or b.roster != [m, k, p]:
		return "이그니스·아이아스·세라피나를 차례로 고른 뒤 보유가 %s다" % [_kinds(b.roster)]
	var free: bool = b.gold == 500 and b.offers == HERO_SIX and b.roster.all(func(h): return h.level == 1)
	b.dismiss(k)
	var out: bool = b.roster == [m, p]
	var c = b.hire(5)
	var team := [m, p, c]
	var again: bool = c != null and b.roster == team
	b.next_round()
	var stood: bool = b.state == "prep" and b.heroes == team and b.hero == m
	for i in 3:
		stood = stood and team[i] != null and team[i].present and near(team[i].pos, CELLS[i], 0.01) and team[i].hp == team[i].max_hp
	if not _win_round(b) or b.state != "cleared":
		return "1라운드를 이겨 라운드 사이가 되지 않았다(%s)" % b.state
	var full: bool = b.hire(1) == null and b.offers == HERO_SIX and b.roster == team
	b.next_round()
	var same: bool = b.state == "prep" and b.heroes == team
	var d = _hiring({"gold": 500})
	var a = d.hire(0)
	var s = d.hire(1)
	d.next_round()
	var seen := []
	for phase in ["prep", "battle"]:
		if phase == "battle":
			d.start_battle()
		var got = d.hire(2)
		d.dismiss(s)
		seen.append([d.state, got == null, d.roster == [a, s] and d.heroes == [a, s]])
	return check(free and out and again and stood and full and same and seen == [["prep", true, true], ["battle", true, true]],
		"골드·목록 그대로·Lv1 %s · 아이아스 빼기 %s · 크로노스 고르기 %s · 셋이 고른 차례로 출전 칸에 최대 체력 %s · 라운드 사이 넷째 거부·목록 그대로 %s · 다음 라운드도 같은 셋 %s · 둘만 고른 판 [단계, 고르기 거부, 보유·출전 둘 그대로] %s" % [free, out, again, stood, full, same, seen])

# EV1128 · S54: 새 도전에서는 다시 고른다. 리롤·출전 선택·언제든 영입의 판 함수와 칸은 없다
func ev1128():
	var b = _hiring()
	for i in 3:
		b.hire(i)
	b.next_round()
	for h in b.roster:
		b.add_xp(h, 30)
	b.damage(b.base, BIG)
	if b.state != "lost" or b.roster.size() != 3:
		return "준비가 틀렸다: 단계 %s · 보유 %d명(셋을 고른 판이 져야 한다)" % [b.state, b.roster.size()]
	b.restart()
	b.begin_hiring()
	if b.state != "hiring" or not b.roster.is_empty() or not b.heroes.is_empty() or b.hero != null or b.offers != HERO_SIX:
		return "새 도전: 단계 %s · 보유 %s · 출전 %s · 목록 %s(고르기 창이고 보유·출전이 비고 목록은 %s여야 한다)" % [b.state, _kinds(b.roster), _kinds(b.heroes), b.offers, HERO_SIX]
	var team := [b.hire(3), b.hire(4), b.hire(5)]
	var fresh: bool = not team.has(null) and b.roster == team and team.all(func(h): return h.level == 1 and h.xp == 0)
	var funcs: Array = ["reroll", "reroll_cost", "set_lineup", "can_hire"].filter(func(n): return b.has_method(n))
	var vars: Array = ["lineup", "rerolls"].filter(func(n): return b.get(n) != null)
	return check(fresh and funcs.is_empty() and vars.is_empty(),
		"앞 도전과 다른 셋을 Lv1·경험치 0으로 고름 %s(보유 %s) · 남아 있는 메서드 %s · 속성 %s(없어야 한다)" % [fresh, _kinds(b.roster), funcs, vars])
