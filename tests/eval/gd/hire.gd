extends "res://tests/eval/gd/lib.gd"
# WBS 3.5 영입소(S122~S124·I103~I109). lib.gd·rounds.gd·heroes.gd 머리의 계약에 더하는 API:
#   stage 키 hero_cells: [칸, …] — 출전 칸(I107) · seed: int — 영입소 난수 씨앗. 같은 씨앗이면 같은 목록이 나온다
#   res://data/hire.tres — slots · odds([동, 은, 금]) · cost([동, 은, 금]) · reroll · cap · lineup (S123). Battle.HIRE가 이 Resource다
#   state "hiring" — 도전 시작 전 영입 창(S122). Battle.begin_hiring() — 1라운드 웨이브 1의 준비 단계(restart 직후)에서 연다
#   Battle.next_round() -> bool — 영입 창이나 라운드 사이에서 출전 목록을 전장에 반영하고 1라운드나 다음 라운드의 첫 준비 단계로 간다
#   Battle.offers — 목록(칸마다 영웅 종류, 영입한 칸은 ""). 평가가 바꿔 넣을 수 있다 · Battle.roster — 보유 영웅(영입 순서)
#   Battle.lineup — 다음 라운드에 출전할 영웅 · Battle.heroes — 전장에 나온 출전 영웅(보유 순서) · Battle.hero — 첫 출전 영웅
#   Battle.hire(칸 번호) -> 영웅|null · Battle.reroll() -> bool · Battle.dismiss(영웅) · Battle.set_lineup(영웅, 출전) -> bool(못 바꾸면 false)
#   Controls: F1·F2 키 — 출전 영웅 1·2를 고른다(I108)
# 수치는 Battle.HIRE와 영웅 데이터에서 읽는다. 임시값이라(S123) 밸런스를 바꿔도 동작을 재는 평가는 깨지지 않게. EV194만 표를 대조한다

const CELLS := [Vector2i(10, 5), Vector2i(12, 5)]  # 출전 칸
const ONE := [{"kind": "basic", "count": 1}]
const ONE_ONE := [[ONE], [ONE]]  # 라운드 2개, 라운드마다 적 1마리짜리 웨이브 하나

# 영입 창이 열린 판(출전 칸·씨앗·라운드 2개)
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

func _cost(b, h) -> int:
	return b.HIRE.cost[h.grade - 1]

# 리롤을 n번 해 나온 목록의 종류별 수
func _sample(b, n: int) -> Dictionary:
	var seen := {}
	for i in n:
		b.reroll()
		for k in b.offers:
			seen[k] = seen.get(k, 0) + 1
	return seen

# EV192 · S122: 도전 시작 전 영입 창이 먼저 뜨고, 영입한 영웅이 1라운드 첫 준비 단계에 출전 칸에 선다
func ev192():
	var b = _main()
	var cells: Array = load("res://src/main.gd").stage().get("hero_cells", [])
	b.begin_hiring()
	if b.state != "hiring" or not b.heroes.is_empty() or b.hero != null or b.gold != 150:
		return "영입 창이 아니거나 영웅이 있다(%s, 영웅 %d명, hero %s, 골드 %d)" % [b.state, b.heroes.size(), b.hero, b.gold]
	if b.offers.size() != b.HIRE.slots or b.offers.has(""):
		return "목록이 다 차 있지 않다(%s)" % [b.offers]
	var h = b.hire(0)
	if h == null or cells.is_empty():
		return "목록의 첫 영웅을 영입하지 못했거나 출전 칸이 없다(%s)" % [cells]
	var started: bool = b.next_round()
	return check(started and b.state == "prep" and b.round_index == 0 and b.wave_index == 0 and b.heroes == [h] and b.hero == h
		and h.present and h.hp == h.max_hp and near(h.pos, cells[0], 0.01) and b.gold == 150 - _cost(b, h),
		"넘어감 %s · %s %d라운드 웨이브 %d · 출전 %d명 · 영웅 자리 %s 체력 %d/%d · 골드 %d" % [started, b.state, b.round_index + 1, b.wave_index + 1, b.heroes.size(), h.pos, h.hp, h.max_hp, b.gold])

# EV193 · I109: 도전 시작 전 영입 창에서는 맵 명령을 받지 않는다
func ev193():
	var b = _hiring({"gold": 500})
	var c = controls(b)
	var cell := Vector2i(15, 10)
	_key(c, KEY_1)
	click(c, MOUSE_BUTTON_LEFT, px(cell))
	b.start_battle()
	var wall = b.build("wall", cell + Vector2i(0, 2))
	var merc = b.place_merc("soldier", cell + Vector2i(0, 4))
	run(b, 1.0)
	return check(b.state == "hiring" and c.placing == "" and wall == null and merc == null and b.structures.is_empty() and b.units.is_empty() and b.gold == 500,
		"단계 %s · 놓기 모드 «%s» · 방벽 %s · 용병 %s · 구조물 %d · 유닛 %d · 골드 %d" % [b.state, c.placing, wall, merc, b.structures.size(), b.units.size(), b.gold])

# EV194 · S123: data/hire.tres의 값이 표와 같다
func ev194():
	var r = load("res://data/hire.tres")
	if r == null:
		return "data/hire.tres를 불러오지 못했다"
	var odds := [0.6, 0.3, 0.1]
	var cost := [30, 60, 100]
	var ok: bool = r.slots == 3 and r.reroll == 10 and r.cap == 4 and r.lineup == 2 and r.odds.size() == 3 and r.cost.size() == 3
	for i in 3:
		ok = ok and is_equal_approx(r.odds[i], odds[i]) and r.cost[i] == cost[i]
	return check(ok, "칸 %s · 등장 확률 %s · 영입 비용 %s · 리롤 %s · 보유 상한 %s · 출전 %s" % [r.slots, r.odds, r.cost, r.reroll, r.cap, r.lineup])

# EV195 · S123: 리롤마다 골드가 리롤 비용만큼 줄고, 등급 비율이 등장 확률과 맞는다
func ev195():
	var b = _hiring()
	var g0: int = b.gold
	var seen := _sample(b, 6000)
	var total := 0
	var by := [0, 0, 0]
	for k in seen:
		by[b.HERO_KINDS[k].grade - 1] += seen[k]
		total += seen[k]
	if b.gold != g0 - 6000 * b.HIRE.reroll or total != 6000 * b.HIRE.slots:
		return "골드 %d → %d, 뽑힌 칸 %d" % [g0, b.gold, total]
	for i in 3:
		if absf(float(by[i]) / total - b.HIRE.odds[i]) > 0.015:
			return "등급 비율 %s (등장 확률 %s)" % [by.map(func(x): return float(x) / total), b.HIRE.odds]
	return ""

# EV196 · I103: 등급마다 두 영웅이 같은 확률로 나오고, 같은 영웅을 여럿 보유할 수 있다
func ev196():
	var b = _hiring()
	var seen := _sample(b, 6000)
	for g in [1, 2, 3]:
		var kinds: Array = b.HERO_KINDS.keys().filter(func(k): return b.HERO_KINDS[k].grade == g)
		var n: int = kinds.reduce(func(s, k): return s + seen.get(k, 0), 0)
		for k in kinds:
			if n == 0 or absf(float(seen.get(k, 0)) / n - 0.5) > 0.05:
				return "%d등급 %s: %d / %d (0.5여야 한다)" % [g, k, seen.get(k, 0), n]
	var d = _hiring()
	d.offers = ["knight", "knight", "knight"]
	var a = d.hire(0)
	var z = d.hire(1)
	return check(a != null and z != null and d.roster.size() == 2 and d.roster.all(func(h): return h.kind == "knight"),
		"같은 영웅 둘을 영입하지 못했다(보유 %s)" % [d.roster.map(func(h): return h.kind)])

# EV197 · S123: 영입하면 등급의 영입 비용만큼 골드가 줄고, 출전은 2명·보유는 4명까지다
func ev197():
	var b = _hiring({"gold": 200})
	b.offers = ["knight", "priest", "general"]
	var k = b.hire(0)
	var p = b.hire(1)
	var g = b.hire(2)
	if k == null or p == null or g == null or b.gold != 200 - _cost(b, k) - _cost(b, p) - _cost(b, g):
		return "셋을 영입하지 못했거나 골드가 %d다" % b.gold
	b.set_lineup(k, true)
	b.set_lineup(p, true)
	var third: bool = b.set_lineup(g, true)
	if third or b.lineup.size() != b.HIRE.lineup:
		return "출전 목록 %d명 · 셋째 넣기 %s" % [b.lineup.size(), third]
	b.gold = BIG
	b.offers = ["mage", "bowman", "mason"]
	var fourth = b.hire(0)
	var gold: int = b.gold
	var fifth = b.hire(1)
	return check(fourth != null and fifth == null and b.roster.size() == b.HIRE.cap and b.gold == gold,
		"넷째 %s · 다섯째 %s · 보유 %d명 · 골드 %d → %d" % [fourth, fifth, b.roster.size(), gold, b.gold])

# EV198 · S124: 계속 출전하는 영웅은 자리·체력이 그대로, 빠진 영웅은 사라지고, 새로 출전한 영웅은 출전 칸에 최대 체력으로 선다
func ev198():
	var b = _hiring()
	b.offers = ["knight", "priest", "mage"]
	var k = b.hire(0)
	var p = b.hire(1)
	b.set_lineup(k, true)
	b.set_lineup(p, true)
	b.next_round()
	var to: Vector2i = CELLS[0] + Vector2i(0, 3)
	b.order_move([k], to)
	if not run(b, 10.0, func(): return near(k.pos, to)):
		return "기사가 옮겨 가지 않았다(%s)" % k.pos
	b.damage(k, 30)
	var hp: float = k.hp
	if not _win_round(b) or b.state != "cleared":
		return "1라운드를 이겨 라운드 사이가 되지 않았다(%s)" % b.state
	var at: Vector2 = k.pos
	var m = b.hire(2)
	if m == null or not b.set_lineup(p, false) or not b.set_lineup(m, true):
		return "라운드 사이에 출전을 바꾸지 못했다"
	b.next_round()
	var kept: bool = k in b.units and k.pos.distance_to(at) < 0.1 and k.hp == hp
	var gone: bool = p not in b.units and p not in b.heroes
	var fresh: bool = m in b.units and m.present and near(m.pos, CELLS[1], 0.01) and m.hp == m.max_hp
	return check(b.state == "prep" and kept and gone and fresh, "기사 그대로 %s · 사제 사라짐 %s · 마도사가 출전 칸에 최대 체력 %s (%s)" % [kept, gone, fresh, m.pos])

# EV199 · I104: 목록은 도전 시작·라운드 승리 때 무료로 새로 뽑고, 영입·리롤은 영입 창에서만 한다
func ev199():
	var b = _hiring()
	b.hire(0)
	var emptied: bool = b.offers[0] == ""
	var g: int = b.gold
	var rolled: bool = b.reroll() and not b.offers.has("") and b.gold == g - b.HIRE.reroll
	b.hire(1)
	b.next_round()
	var before: Array = b.offers.duplicate()
	g = b.gold
	var refused: bool = not b.reroll() and b.hire(0) == null and b.offers == before and b.gold == g
	if not _win_round(b):
		return "1라운드를 이기지 못했다(%s)" % b.state
	var refilled: bool = not b.offers.has("") and b.gold == g + b.ENEMY_KINDS.basic.reward
	b.gold = b.HIRE.reroll - 1
	before = b.offers.duplicate()
	var poor: bool = not b.reroll() and b.offers == before and b.gold == b.HIRE.reroll - 1
	return check(emptied and rolled and refused and refilled and poor,
		"영입한 칸 빔 %s · 리롤 %s · 준비 단계 거부 %s · 라운드 승리 뒤 다시 참 %s · 골드 모자라면 거부 %s" % [emptied, rolled, refused, refilled, poor])

# EV200 · I105: 내보낸 영웅은 보유·출전 목록에서 빠지고 환불은 없다. 전장에 있었으면 다음 라운드에 사라진다
func ev200():
	var b = _hiring()
	b.offers = ["knight", "priest", "mage"]
	var k = b.hire(0)
	var p = b.hire(1)
	b.set_lineup(k, true)
	b.set_lineup(p, true)
	var g: int = b.gold
	b.dismiss(p)
	var out: bool = b.roster == [k] and b.lineup == [k] and b.gold == g
	b.next_round()
	b.dismiss(k)
	var kept: bool = b.roster == [k] and b.heroes == [k]
	if not _win_round(b):
		return "1라운드를 이기지 못했다(%s)" % b.state
	b.dismiss(k)
	b.next_round()
	var gone: bool = b.roster.is_empty() and b.heroes.is_empty() and b.hero == null and k not in b.units
	return check(out and kept and gone, "영입 창에서 내보냄 %s · 준비 단계에서는 그대로 %s · 라운드 사이에 내보내면 다음 라운드엔 없음 %s" % [out, kept, gone])

# EV201 · I106: 영웅 없이도 시작하고, 영입한 영웅은 빈 출전 자리에 바로 들며, 출전 목록은 다음 라운드에도 그대로다
func ev201():
	var b = _hiring()
	var c = controls(b)
	var started: bool = b.next_round() and b.state == "prep" and b.hero == null and b.heroes.is_empty()
	_key(c, KEY_Q)
	_key(c, KEY_W)
	var d = _hiring()
	d.offers = ["knight", "priest", "mage"]
	var k = d.hire(0)
	var p = d.hire(1)
	var m = d.hire(2)
	var auto: bool = d.lineup == [k, p]
	d.next_round()
	if not _win_round(d):
		return "1라운드를 이기지 못했다(%s)" % d.state
	d.next_round()
	var same: bool = d.heroes == [k, p] and m not in d.units
	return check(started and auto and same, "영웅 없이 시작 %s · 처음 둘만 출전 %s · 다음 라운드도 같은 둘 %s" % [started, auto, same])

# EV202 · I107: 시험 스테이지의 출전 칸은 정문 앞 (19,11)·(21,11)이고, 영웅은 보유 순서대로 서며, 출전 칸에는 짓지 못한다
func ev202():
	var cells: Array = load("res://src/main.gd").stage().get("hero_cells", [])
	if cells.size() != 2 or cells[0] != Vector2i(19, 11) or cells[1] != Vector2i(21, 11):
		return "출전 칸이 %s다" % [cells]
	var b = _main()
	b.begin_hiring()
	b.offers = ["knight", "bowman", "knight"]
	var k = b.hire(0)
	var w = b.hire(1)
	b.set_lineup(k, true)
	b.set_lineup(w, true)
	b.next_round()
	var placed: bool = near(k.pos, cells[0], 0.01) and near(w.pos, cells[1], 0.01)
	b.order_move([k], cells[0] + Vector2i(0, 4))
	b.order_move([w], cells[1] + Vector2i(0, 4))
	run(b, 5.0)
	var blocked: bool = b.build("wall", cells[0]) == null and b.build("wall", cells[1]) == null
	var beside = b.build("wall", cells[0] + Vector2i(1, 0))
	return check(placed and blocked and beside != null, "보유 순서대로 섬 %s · 출전 칸에 못 지음 %s · 옆 칸에 지음 %s" % [placed, blocked, beside != null])

# EV203 · I108: 출전 순서는 보유 순서이고 첫 출전 영웅이 hero다. F2로 고르고, 빠진 영웅을 골라 둔 채면 첫 출전 영웅이 Q를 쓴다
func ev203():
	var b = _hiring()
	b.offers = ["knight", "priest", "mage"]
	var k = b.hire(0)
	var p = b.hire(1)
	var m = b.hire(2)
	for h in b.roster:
		b.set_lineup(h, false)
	b.set_lineup(m, true)
	b.set_lineup(k, true)
	b.next_round()
	if b.heroes != [k, m] or b.hero != k:
		return "출전 영웅 %s · hero %s (기사, 마도사 순이어야 한다)" % [b.heroes.map(func(h): return h.kind), b.hero.kind if b.hero else "없음"]
	var c = controls(b)
	_key(c, KEY_F2)
	var picked: bool = c.selected == [m]
	b.start_battle()  # Q는 전투 단계에만 쓴다(S136)
	_key(c, KEY_Q)
	var mage_q: bool = m.skill_uses == 1 and k.skill_uses == 0
	if not clear_wave(b) or not _win_round(b):
		return "1라운드를 이기지 못했다(%s)" % b.state
	b.set_lineup(m, false)
	b.set_lineup(p, true)
	b.next_round()
	b.start_battle()
	_key(c, KEY_Q)
	var first_q: bool = k.skill_uses == 1 and m.skill_uses == 1 and p.skill_uses == 0
	return check(picked and mage_q and first_q, "F2로 마도사 고름 %s · 마도사가 Q %s · 다음 라운드엔 기사가 Q %s" % [picked, mage_q, first_q])

# EV232 · I127: 보유 영웅이 상한이면 리롤은 거부되고 골드와 목록이 그대로다
func ev232():
	var b = _hiring()
	for i in 3:
		b.hire(i)
	var rolled: bool = b.reroll()
	b.hire(0)
	if b.roster.size() != b.HIRE.cap:
		return "보유 영웅이 상한(%d)까지 차지 않았다(%d)" % [b.HIRE.cap, b.roster.size()]
	var before: Array = b.offers.duplicate()
	var g: int = b.gold
	var refused: bool = not b.reroll() and b.offers == before and b.gold == g
	return check(rolled and refused, "상한 전 리롤 %s · 상한에서 리롤 거부 %s(골드 %d → %d)" % [rolled, refused, g, b.gold])
