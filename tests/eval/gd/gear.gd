extends "res://tests/eval/gd/hud.gd"
# 성장 시스템 PR1 영웅 전용장비(S246~S251·I200·I201). lib.gd·hire.gd·kits.gd·save.gd·hud.gd 머리의 계약에 더하는 API:
#   Battle.GEAR_KINDS — 영웅 종류 → 장비 데이터 {title, steps, notes}(data/gear/<영웅 종류>.tres). steps[n]은 단계 +n의 {"칸.키": 값}
#   Battle.bag — 영웅 종류 → 가진 장비의 강화 수치(+0부터). 키가 없으면 그 장비가 없다
#   Battle.forged — 이번 라운드 사이 창에서 장비마다 제작·강화한 횟수
#   Battle.forge(영웅 종류) -> bool — 제작(없으면 +0)이나 한 단계 강화. 못 하면 false이고 아무것도 바뀌지 않는다
#   Battle.wear(영웅, 켬) -> bool — 장착·해제. 못 하면 false · 영웅: worn — 장비를 꼈다
#   stage heroes 항목 gear: n — 그 수치의 장비를 가방에 넣고 낀 채 시작한다(평가용)
#   res://data/hire.tres — gear_cost(단계마다 비용, [0]이 제작) · forge_cap(창마다 장비 하나에 누르는 횟수)
#   BattleView.aim_r(판, 영웅, 칸) -> int — 지점 스킬 조준 원 반지름(아트 px, static)
#   게임 장면: 라운드 사이 창(main.hud.window)의 «영입»·«장비» 버튼. 장비 칸 줄 글은 Label, 제작·강화·장착 버튼은 BaseButton
#   PR2 전리품(S252·S253·I202): Battle.dropped — 이번 라운드 사이의 전리품 [영웅 종류, 전 수치(없던 장비면 -1), 뒤 수치]. 없으면 []
#     Battle.GEAR_KINDS는 평가가 바꿔 넣을 수 있다(전리품 후보를 정하려고)
#   PR3 용병 종류 강화(S254·S255·I203): Battle.rank_up(용병 종류) -> bool — 한 단계 강화. 못 하면 false이고 아무것도 바뀌지 않는다
#     Battle.merc_rank — 용병 종류 → 산 강화 단계 수. 키가 없으면 0 · MERC_KINDS[종류].ranks(단계마다 {키: 값}) · rank_cost(단계마다 골드)
#     저장 snapshot의 강화 칸 이름은 "ranks"다 · 게임 장면: 시설 팝업(main.hud.popup)의 «이름 강화 …» 버튼
# 단계 수치는 데이터(GEAR_KINDS)에서 읽는다. 임시값이라(S249) 수치를 바꿔도 동작을 재는 평가는 깨지지 않게

const CELLS := [Vector2i(10, 5), Vector2i(12, 5), Vector2i(14, 5)]  # 출전 칸(I107)
const ONE_ENEMY := [{"kind": "basic", "count": 1}]
const NO_ENEMY := [{"kind": "basic", "count": 0}]
const SIX := ["passive", "aura", "q", "w", "e", "r"]
const QWER := ["q", "w", "e", "r"]
const AT := Vector2(14, 10)

# 라운드 rounds개(라운드마다 적 1마리짜리 웨이브 하나)짜리 판. team은 처음 보유·출전하는 영웅 [{kind, cell, gear?}]
func _board(rounds: int, team := []):
	var plan := []
	for i in rounds:
		plan.append([ONE_ENEMY])
	return battle({"hero_cells": CELLS, "seed": 7, "base_hp": BIG, "rounds": plan, "heroes": team})

func _ignis(gear := -1) -> Array:
	var t := {"kind": "ignis", "cell": CELLS[0]}
	if gear >= 0:
		t.gear = gear
	return [t]

# 장비 API가 없으면 그 이유. 없을 때 forge·wear가 null을 내면 «거부»로 읽혀 빈 통과가 된다
func _api(b) -> String:
	return "" if b.has_method("forge") and b.has_method("wear") and b.get("bag") is Dictionary and b.get("forged") is Dictionary else "Battle에 forge·wear·bag·forged가 없다"

# 디스크에서 새로 읽은 영웅 데이터(캐시된 Resource가 오염돼도 따라 바뀌지 않게)
func _data(kind: String) -> Resource:
	return ResourceLoader.load("res://data/heroes/%s.tres" % kind, "", ResourceLoader.CACHE_MODE_IGNORE)

# I200: 데이터 사본에 장비 단계 0..n의 «칸.키 → 값»을 차례로 덮어쓴 여섯 사전
func _fitted(b, kind: String, n: int) -> Dictionary:
	var src := _data(kind)
	var out := {}
	for slot in SIX:
		out[slot] = src.get(slot).duplicate(true)
	for step in b.GEAR_KINDS[kind].steps.slice(0, n + 1):
		for path in step:
			out[path.get_slice(".", 0)][path.get_slice(".", 1)] = step[path]
	return out

# 영웅의 slots 사전이 want와 다르면 그 칸 이름들
func _differ(h, want: Dictionary, slots := SIX) -> Array:
	return slots.filter(func(s): return h.get(s) != want[s])

# 왕홀 +n(음수면 장비 없음) 이그니스 하나의 전투 단계. 구석 과녁으로 전투가 이어지고 기본 공격은 끈다. 시간은 흐르지 않는다
func _fight(n: int):
	var t := {"kind": "ignis", "cell": Vector2i(10, 10)}
	if n >= 0:
		t.gear = n
	var b = battle({"heroes": [t], "base_hp": BIG, "waves": [NO_ENEMY, NO_ENEMY], "seed": 11})
	_target(b, Vector2(0, 19))
	b.start_battle()
	b.hero.damage = 0.0
	return b

# 라운드를 이겨 라운드 사이로 가되, 그때 받은 전리품(S252)을 되돌린다. 제작·강화·장착(S246·S247)을 «전리품 없는 라운드 사이»에서 재려고
func _win_bare(b) -> bool:
	var bag: Dictionary = b.bag.duplicate()
	var won: bool = _win(b)
	if b.get("dropped") is Array and not b.dropped.is_empty():
		b.bag = bag
		b.dropped.clear()
		for h in b.roster:
			h.worn = h.worn and bag.has(h.kind)
			b._refit(h)
	return won

# 움직이지도 치지도 않는 과녁을 at(칸 좌표, 소수 가능)에 둔다
func _target(b, at: Vector2):
	var e = b.spawn_enemy("basic", Vector2i(at.round()), {"speed": 0, "sight": 0, "damage": 0, "hp": BIG})
	e.pos = at
	return e

# EV601 · S246: 제작은 라운드 사이에만, 골드가 있어야 되고, 보유하지 않은 영웅 장비도 된다
func ev601():
	var b = _board(2)
	var out := _api(b)
	b.begin_hiring()
	var g0: int = b.gold
	for phase in ["hiring", "prep", "battle"]:
		if out != "":
			break
		if phase == "prep":
			b.next_round()
		elif phase == "battle":
			b.start_battle()
		out = check(b.state == phase and not b.forge("ignis") and b.gold == g0 and b.bag.is_empty(), "%s 단계(%s)에서 제작됐다: 골드 %d · 가방 %s" % [phase, b.state, b.gold, b.bag])
	if out == "":
		out = check(_win_bare(b), "1라운드를 이겨 라운드 사이가 되지 않았다(%s)" % b.state)
	if out == "":
		var cost: int = b.HIRE.gear_cost[0]
		b.gold = cost - 1
		out = check(not b.forge("ignis") and b.gold == cost - 1 and b.bag.is_empty(), "골드 %d로 제작됐다(비용 %d)" % [cost - 1, cost])
		if out == "":
			b.gold = cost + 5
			out = check(b.forge("ignis") and b.bag.get("ignis") == 0 and b.gold == 5, "골드가 넉넉할 때 제작: 가방 %s · 골드 %d(기대 5)" % [b.bag, b.gold])
	return out

# EV602 · S246: 장비 하나는 창마다 forge_cap(2)번, 다음 창에서 다시 된다. 마지막 단계면 거부한다
func ev602():
	var b = _board(4)
	var out := _api(b)
	b.gold = BIG
	for want in [1, 3]:
		if out == "":
			out = check(_win_bare(b), "라운드를 이겨 라운드 사이가 되지 않았다(%s)" % b.state)
		if out == "":
			var got := [b.forge("ignis"), b.forge("ignis"), b.forge("ignis")]
			out = check(got == [true, true, false] and b.bag.get("ignis") == want, "창 하나에서 세 번 %s · 가방 %s(기대 [true, true, false], ignis %d)" % [got, b.bag, want])
			b.next_round()
	if out == "":
		out = check(_win_bare(b), "3라운드를 이겨 라운드 사이가 되지 않았다(%s)" % b.state)
	if out == "":
		b.bag.ignis = b.GEAR_KINDS.ignis.steps.size() - 1
		var g: int = b.gold
		out = check(not b.forge("ignis") and b.gold == g and b.bag.ignis == b.GEAR_KINDS.ignis.steps.size() - 1, "마지막 단계에서 강화됐다: 가방 %s" % [b.bag])
	return out

# EV603 · S247: 영입하면 저절로 끼고, 해제·재장착, 내보내도 가방에 남고 다시 영입하면 낀다. 보유한 채 처음 만들면 저절로 낀다
func ev603():
	var b = _board(2)
	var out := _api(b)
	b.gold = BIG
	if out == "":
		out = check(_win_bare(b) and b.forge("ignis"), "라운드 사이에서 장비를 만들지 못했다(%s, 가방 %s)" % [b.state, b.bag])
	if out != "":
		return out
	var want: float = _fitted(b, "ignis", 0).q.burn
	var base: float = b.HERO_KINDS.ignis.q.burn
	b.offers[0] = "ignis"
	var h = b.hire(0)
	out = check(h != null and want != base and h.get("worn") == true and h.q.burn == want, "영입한 이그니스: 장착 %s · 발화 %s(기대 %s, 데이터 %s)" % [h.get("worn") if h else null, h.q.burn if h else null, want, base])
	if out == "":
		var off: bool = b.wear(h, false)
		var burn_off: float = h.q.burn
		var on: bool = b.wear(h, true)
		out = check(off and on and burn_off == base and h.q.burn == want and h.worn, "해제 %s(발화 %s) · 재장착 %s(발화 %s)" % [off, burn_off, on, h.q.burn])
	if out == "":
		b.dismiss(h)
		out = check(b.bag.get("ignis") == 0 and not b.wear(h, true), "내보낸 뒤 가방 %s · 내보낸 영웅 장착이 거부되지 않았다" % [b.bag])
	if out == "":
		b.offers[1] = "ignis"
		var again = b.hire(1)
		out = check(again != null and again.worn and again.q.burn == want, "다시 영입한 이그니스가 장비를 끼지 않았다")
	if out == "":
		var b2 = _board(2, _ignis())
		b2.gold = BIG
		var made: bool = _win_bare(b2) and b2.forge("ignis")
		out = check(made and b2.hero.worn and b2.hero.q.burn == want, "보유한 채 처음 만든 장비: 만듦 %s · 장착 %s · 발화 %s" % [made, b2.hero.worn, b2.hero.q.burn])
	return out

# EV604 · I200: 장비는 레벨 몸 수치를 바꾸지 않고, 데이터 사본에 단계를 차례로 덮는다. 데이터는 그대로다
func ev604():
	var plain = _board(2, _ignis()).hero
	var b3 = _board(2, _ignis(3))
	var b6 = _board(2, _ignis(6))
	var out := _api(b6)
	if out == "":
		out = check(b6.hero.get("worn") == true and b6.bag.get("ignis") == 6, "평가 스테이지 gear 칸: 장착 %s · 가방 %s" % [b6.hero.get("worn"), b6.bag])
	for h in [b3.hero, b6.hero]:
		if out == "":
			out = check(h.max_hp == plain.max_hp and h.damage == plain.damage, "장비 낀 이그니스 체력 %s·공격력 %s(장비 없음 %s·%s)" % [h.max_hp, h.damage, plain.max_hp, plain.damage])
	for pair in [[b3, 3], [b6, 6]]:
		if out == "":
			var bad := _differ(pair[0].hero, _fitted(pair[0], "ignis", pair[1]))
			out = check(bad.is_empty(), "+%d 이그니스의 %s가 데이터 사본 + 단계 0..%d 덮어쓰기와 다르다" % [pair[1], bad, pair[1]])
	var fresh := _data("ignis")
	var cached: Resource = load("res://data/heroes/ignis.tres")
	for slot in QWER:
		if out == "":
			out = check(b6.HERO_KINDS.ignis[slot] == fresh.get(slot) and cached.get(slot) == fresh.get(slot), "장비 뒤 영웅 데이터 %s가 바뀌었다" % slot)
	if out == "":
		b6.gold = BIG
		var off: bool = _win(b6) and b6.wear(b6.hero, false)
		var bad := QWER.filter(func(s): return b6.hero.get(s) != fresh.get(s))
		out = check(off and bad.is_empty(), "+6 해제 %s · 데이터와 다른 칸 %s" % [off, bad])
	return out

# EV605 · S249: +3 화염구는 +2 화염구가 닿지 않는 거리를 맞힌다
func ev605():
	var probe = _board(1)
	var out := _api(probe)
	if out != "":
		return out
	var r2: float = _fitted(probe, "ignis", 2).q.radius
	var r3: float = _fitted(probe, "ignis", 3).q.radius
	if not r2 < r3:
		return "+2 반경 %s가 +3 반경 %s보다 작지 않다" % [r2, r3]
	var hit := []
	for n in [2, 3]:
		var b = _fight(n)
		var d = _target(b, AT + Vector2((r2 + r3) / 2.0, 0))
		var cast: bool = b.cast(b.hero, "q", AT)
		hit.append(cast and d.hp < d.max_hp)
	return check(hit == [false, true], "(+2, +3)에서 %s칸 과녁 맞음 %s(기대 [false, true])" % [(r2 + r3) / 2.0, hit])

# EV606 · S250: +6이면 블랙홀 안 화염구가 블랙홀을 불태워, 끌려온 적이 발화하고 이어 쓴 서리 고리에 언다
func ev606():
	var got := []
	for n in [5, 6]:
		var b = _fight(n)
		var out := _api(b)
		if out != "":
			return out
		var h = b.hero
		var d = _target(b, AT + Vector2((h.q.radius + h.e.radius) / 2.0, 0))
		var cast: bool = b.cast(h, "e", AT) and b.cast(h, "q", AT)
		var hit_by_q: bool = d.hp < d.max_hp
		run(b, 0.5)
		var burning: bool = b.effect(d, "dot") != null
		var frost: bool = b.cast(h, "w", AT)
		if not cast or not frost or hit_by_q:
			return "+%d: E·Q 시전 %s · W 시전 %s · 과녁이 Q에 맞음 %s" % [n, cast, frost, hit_by_q]
		got.append([burning, b.effect(d, "stun") != null])
	return check(got == [[false, false], [true, true]], "(+5, +6)마다 [발화, 빙결] %s(기대 [[false, false], [true, true]])" % [got])

# EV607 · I201: 가방·창당 횟수·장착 여부가 저장을 왕복하고, 그 칸이 없는 저장은 빈 가방·해제다
func ev607():
	var save = load("res://src/sim/save.gd")
	var b = _board(2, _ignis(3))
	var out := _api(b)
	b.gold = BIG
	if out == "":
		out = check(_win_bare(b) and b.forge("ignis") and b.bag.get("ignis") == 4 and b.forged.get("ignis") == 1, "라운드 사이 강화: 가방 %s · 횟수 %s" % [b.bag, b.forged])
	if out != "":
		return out
	var d: Dictionary = save.snapshot(b)
	if not d.has("version"):
		return "snapshot에 version이 없다"
	var b2 = _board(2, _ignis(3))
	save.apply(b2, d)
	var bad := _differ(b2.hero, {"q": b.hero.q, "w": b.hero.w, "e": b.hero.e, "r": b.hero.r}, QWER)
	out = check(b2.bag == b.bag and b2.forged == b.forged and b2.hero.worn and bad.is_empty() and save.snapshot(b2) == d,
		"불러온 판: 가방 %s · 횟수 %s · 장착 %s · 다른 칸 %s · snapshot 같음 %s" % [b2.bag, b2.forged, b2.hero.worn, bad, save.snapshot(b2) == d])
	if out == "":
		var old: Dictionary = d.duplicate(true)
		old.erase("bag")
		old.erase("forged")
		for f in old.heroes:
			f.erase("worn")
		var b3 = _board(2, _ignis(3))
		save.apply(b3, old)
		out = check(b3.bag.is_empty() and b3.forged.is_empty() and not b3.hero.worn, "칸이 없는 저장: 가방 %s · 횟수 %s · 장착 %s" % [b3.bag, b3.forged, b3.hero.worn])
	return out

# EV608 · S246: 새 도전이면 가방과 창당 횟수가 비고 이그니스는 데이터 수치다
func ev608():
	var b = _board(2, _ignis())
	var out := _api(b)
	b.gold = BIG
	if out == "":
		out = check(_win_bare(b) and b.forge("ignis") and b.forge("ignis") and b.bag.get("ignis") == 1, "라운드 사이에서 만들고 강화하지 못했다(가방 %s)" % [b.bag])
	if out == "":
		b.restart()
		var fresh := _data("ignis")
		var bad := QWER.filter(func(s): return b.hero.get(s) != fresh.get(s))
		out = check(b.bag.is_empty() and b.forged.is_empty() and bad.is_empty(), "새 도전 뒤 가방 %s · 횟수 %s · 데이터와 다른 칸 %s" % [b.bag, b.forged, bad])
	return out

# EV609 · S251: 과부하 차례의 Q·W·E 조준 원은 반경 × (1 + grow), R과 과부하 아닐 때는 반경 그대로
func ev609():
	var view = load("res://src/ui/battle_view.gd")
	var b = _fight(-1)
	var h = b.hero
	var grow: float = h.passive.grow
	var out := ""
	for charged in [false, true]:
		h.charged = charged
		for slot in QWER:
			var want := int(16 * h.get(slot).radius * (1.0 + grow if charged and slot != "r" else 1.0))
			var got = view.aim_r(b, h, slot)
			if out == "" and got != want:
				out = "과부하 %s %s 조준 원 %s(기대 %d)" % [charged, slot, got, want]
	if out == "":
		var b3 = _fight(3)
		b3.hero.charged = true
		var want := int(16 * _fitted(b3, "ignis", 3).q.radius * (1.0 + grow))
		out = check(view.aim_r(b3, b3.hero, "q") == want, "+3 과부하 Q 조준 원 %s(기대 %d)" % [view.aim_r(b3, b3.hero, "q"), want])
	return out

# EV610 · S248: 라운드 사이 창에만 «영입»·«장비» 전환이 있고, 장비 칸에서 제작한다
func ev610():
	var main = _game()
	var b = main.view.battle
	var out := _api(b)
	b.gold = BIG
	_frame(main)
	_layout(main)
	var win = main.hud.window
	if out == "":
		out = check(b.state == "hiring" and _button(win, "장비") == null, "도전 시작 영입 창(%s)에 «장비» 버튼이 있다" % b.state)
	if out == "":
		for i in 2:
			b.hire(i)
		b.next_round()
		_frame(main)
		_layout(main)
		out = check(b.state == "prep" and _button(win, "장비") == null, "준비 단계(%s)에 «장비» 버튼이 있다" % b.state)
	if out == "":
		out = check(_win_bare(b), "1라운드를 이겨 라운드 사이가 되지 않았다(%s)" % b.state)
	if out == "":
		_frame(main)
		_layout(main)
		out = check(_button(win, "영입") != null and _button(win, "장비") != null and _starts(win, "리롤") != null, "라운드 사이 창: «영입» %s · «장비» %s · 리롤 %s" % [_button(win, "영입") != null, _button(win, "장비") != null, _starts(win, "리롤") != null])
	var title: String = b.GEAR_KINDS.ignis.title if out == "" else ""
	var craft := "제작 %d골드" % b.HIRE.gear_cost[0] if out == "" else ""
	if out == "":
		_press(win, "장비")
		_frame(main)
		_layout(main)
		var rows: Array = _labels(win).filter(func(t): return t.begins_with(title + " — 없음"))
		out = check(_starts(win, "리롤") == null and rows.size() == 1 and _button(win, craft) != null, "«장비» 뒤: 리롤 %s · 줄 %s · «%s» %s" % [_starts(win, "리롤") != null, _labels(win), craft, _button(win, craft) != null])
	if out == "":
		_press(win, craft)
		_frame(main)
		_layout(main)
		var rows: Array = _labels(win).filter(func(t): return t.begins_with(title + " +0"))
		out = check(b.bag.get("ignis") == 0 and rows.size() == 1, "제작 뒤 가방 %s · 줄 %s" % [b.bag, _labels(win)])
	if out == "":
		_press(win, "영입")
		_frame(main)
		_layout(main)
		out = check(_starts(win, "리롤") != null, "«영입»을 눌러도 영입 칸이 다시 보이지 않는다")
	_done(main)
	return out

# ── PR2 전리품 ──

# 라운드마다 웨이브 수가 plan인 판(웨이브마다 적 1마리). 전리품 후보는 kinds의 장비(내용은 모두 왕홀 데이터)
func _rounds(plan: Array, team := [], kinds := ["ignis"], over := {}):
	var rounds := []
	for n in plan:
		var waves := []
		for i in n:
			waves.append(ONE_ENEMY)
		rounds.append(waves)
	var stage := {"hero_cells": CELLS, "seed": 7, "base_hp": BIG, "rounds": rounds, "heroes": team}
	stage.merge(over, true)
	var b = battle(stage)
	if b.get("GEAR_KINDS") is Dictionary and b.GEAR_KINDS.has("ignis"):
		var only := {}
		for k in kinds:
			only[k] = b.GEAR_KINDS.ignis
		b.GEAR_KINDS = only
	return b

func _loot_api(b) -> String:
	return _api(b) if _api(b) != "" else ("" if b.get("dropped") is Array else "Battle에 dropped가 없다")

# EV611 · S252: 웨이브 사이엔 없고, 라운드를 이기면 없던 장비 +0·있던 장비 +1, 창당 횟수에 세지 않고, 도전 성공엔 없다
func ev611():
	var b = _rounds([2, 1, 1])
	var out := _loot_api(b)
	if out != "":
		return out
	var seen := []
	b.start_battle()
	clear_wave(b)
	seen.append([b.state, b.bag.duplicate(), b.dropped.duplicate(), b.forged.size()])
	for r in 2:
		_win(b)
		seen.append([b.state, b.bag.duplicate(), b.dropped.duplicate(), b.forged.size()])
		b.next_round()
	b.start_battle()
	clear_wave(b)
	seen.append([b.state, b.bag.duplicate(), b.dropped.duplicate(), b.forged.size()])
	var want := [["prep", {}, [], 0], ["cleared", {"ignis": 0}, ["ignis", -1, 0], 0], ["cleared", {"ignis": 1}, ["ignis", 0, 1], 0], ["won", {"ignis": 1}, [], 0]]
	return check(seen == want, "[단계, 가방, 전리품, 창당 횟수 수] 차례 %s(기대 %s)" % [seen, want])

# EV612 · S252: 보유한 영웅의 장비를 처음 받으면 낀다. 전리품 뒤에도 그 창에서 2번 제작·강화된다. 마지막 단계 장비는 나오지 않는다
func ev612():
	var b = _rounds([1, 1, 1], _ignis())
	var out := _loot_api(b)
	if out != "":
		return out
	b.gold = BIG
	var won: bool = _win(b)
	var want: float = _fitted(b, "ignis", 0).q.burn
	out = check(won and b.bag.get("ignis") == 0 and b.hero.worn and b.hero.q.burn == want, "처음 받은 왕홀: 가방 %s · 장착 %s · 발화 %s(기대 %s)" % [b.bag, b.hero.worn, b.hero.q.burn, want])
	if out == "":
		var got := [b.forge("ignis"), b.forge("ignis"), b.forge("ignis")]
		out = check(got == [true, true, false] and b.bag.ignis == 2, "전리품 뒤 세 번 %s · 가방 %s(기대 [true, true, false], 2)" % [got, b.bag])
	if out == "":
		var last: int = b.GEAR_KINDS.ignis.steps.size() - 1
		b.bag.ignis = last
		b.next_round()
		out = check(_win(b) and b.bag.ignis == last and b.dropped.is_empty(), "마지막 단계에서 라운드 승리: 가방 %s · 전리품 %s" % [b.bag, b.dropped])
	return out

# EV613 · I202: 같은 씨앗이면 전리품이 있든 없든 영입 목록·의뢰 목록·다음 라운드 미션이 같다
func ev613():
	var a = _rounds([1, 1], [], ["ignis", "sylvia", "vesper"], {"quests": true})
	var z = _rounds([1, 1], [], ["ignis", "sylvia", "vesper"], {"quests": true})
	var out := _loot_api(a)
	if out != "":
		return out
	z.GEAR_KINDS = {}
	var won: bool = _win(a) and _win(z)
	out = check(won and not a.dropped.is_empty() and z.dropped.is_empty() and not a.commission_offers.is_empty(), "준비: 승리 %s · 전리품 %s / %s · 의뢰 %s" % [won, a.dropped, z.dropped, a.commission_offers])
	if out == "":
		var lists := [a.offers == z.offers, a.commission_offers == z.commission_offers]
		a.next_round()
		z.next_round()
		lists.append(a.mission == z.mission)
		out = check(lists == [true, true, true], "[영입 목록, 의뢰 목록, 미션] 같음 %s" % [lists])
	return out

# EV614 · I202: 전리품과 전리품 난수가 저장을 왕복하고, 그 칸이 없는 저장은 전리품 없음이다
func ev614():
	var save = load("res://src/sim/save.gd")
	var kinds := ["ignis", "sylvia", "vesper"]
	var a = _rounds([1, 1, 1, 1, 1], [], kinds)
	var out := _loot_api(a)
	if out != "":
		return out
	if not _win(a) or a.dropped.is_empty():
		return "1라운드 승리 뒤 전리품이 없다(%s, %s)" % [a.state, a.dropped]
	var d: Dictionary = save.snapshot(a)
	if not d.has("version"):
		return "snapshot에 version이 없다"
	var b = _rounds([1, 1, 1, 1, 1], [], kinds)
	save.apply(b, d)
	out = check(b.dropped == a.dropped and b.bag == a.bag and save.snapshot(b) == d, "불러온 판: 전리품 %s(기대 %s) · 가방 %s · snapshot 같음 %s" % [b.dropped, a.dropped, b.bag, save.snapshot(b) == d])
	if out == "":
		var runs := [[], []]
		for i in 4:
			for pair in [[a, 0], [b, 1]]:
				pair[0].next_round()
				_win(pair[0])
				runs[pair[1]].append(pair[0].dropped.duplicate())
		out = check(runs[0] == runs[1], "불러온 뒤 전리품 차례 %s(원래 판 %s)" % [runs[1], runs[0]])
	if out == "":
		var old: Dictionary = d.duplicate(true)
		old.erase("dropped")
		old.erase("loot")
		var c = _rounds([1, 1, 1, 1, 1], [], kinds)
		save.apply(c, old)
		out = check(c.dropped.is_empty(), "칸이 없는 저장의 전리품 %s" % [c.dropped])
	return out

# EV615 · S252: 라운드 승리 창 글에 «전리품 이름»(새 장비)과 «전리품 이름 +N → +N+1»(있던 장비)
func ev615():
	var main = _game()
	var b = main.view.battle
	var out := _loot_api(b)
	b.gold = BIG
	if out == "":
		for i in 2:
			b.hire(i)
		b.next_round()
		out = check(_win(b) and not b.dropped.is_empty(), "1라운드 승리 뒤 전리품이 없다(%s)" % b.state)
	if out == "":
		_frame(main)
		var title: String = b.GEAR_KINDS[b.dropped[0]].title
		var fresh := " ".join(_labels(main.hud.window))
		b.dropped = [b.dropped[0], 2, 3]
		_frame(main)
		var more := " ".join(_labels(main.hud.window))
		out = check(("전리품 %s" % title) in fresh and not ("전리품 %s +" % title) in fresh and ("전리품 %s +2 → +3" % title) in more,
			"새 장비 창 글 «%s» · 있던 장비 창 글 «%s»" % [fresh, more])
	_done(main)
	return out

# EV616 · S253: 가방에 그 영웅 장비가 있으면 영입 카드 툴팁에 «장비 있음 +N», 없는 영웅 카드엔 그 줄이 없다
func ev616():
	var main = _game()
	var b = main.view.battle
	var out := _loot_api(b)
	b.gold = BIG
	if out == "":
		b.offers[0] = "aias"
		b.offers[1] = "sylvia"
		for i in 2:
			b.hire(i)
		b.next_round()
		out = check(_win(b), "1라운드를 이겨 라운드 사이가 되지 않았다(%s)" % b.state)
	if out == "":
		b.bag = {"ignis": 4}
		b.offers[0] = "ignis"
		b.offers[1] = "vesper"
		_frame(main)
		var win = main.hud.window
		var cards := [_starts(win, "이그니스"), _starts(win, "베스퍼")]
		if cards.has(null):
			out = "영입 카드를 찾지 못했다: %s" % [cards]
		else:
			var tips := [_tip_of(main, cards[0]), _tip_of(main, cards[1])]
			out = check("장비 있음 +4" in tips[0] and not "장비 있음" in tips[1], "이그니스 카드 툴팁 «%s» · 베스퍼 카드 툴팁 «%s»" % tips)
	_done(main)
	return out

const VILLAGE := Rect2i(0, 0, 30, 6)  # 마을 칸(production.gd와 같다)
const BARRACKS := Vector2i(10, 3)

# 마을이 있고 라운드 둘(적 1마리 웨이브 하나씩)인 판의 준비 단계. barracks면 병영을 지어 둔다
func _camp(barracks := true, over := {}):
	var stage := {"village": VILLAGE, "base_hp": BIG, "rounds": [[ONE_ENEMY], [ONE_ENEMY]], "seed": 7}
	stage.merge(over, true)
	var b = battle(stage)
	if barracks:
		b.build("barracks", BARRACKS)
	return b

# 강화 API가 없으면 그 이유. 없을 때 rank_up이 null을 내면 «거부»로 읽혀 빈 통과가 된다
func _rank_api(b) -> String:
	if not (b.has_method("rank_up") and b.get("merc_rank") is Dictionary):
		return "Battle에 rank_up·merc_rank가 없다"
	for k in ["soldier", "archer", "engineer"]:
		if not (b.MERC_KINDS[k].get("ranks") is Array and b.MERC_KINDS[k].get("rank_cost") is Array and not b.MERC_KINDS[k].ranks.is_empty()):
			return "%s 데이터에 ranks·rank_cost가 없다" % k
	return ""

# 디스크에서 새로 읽은 용병 데이터(캐시된 Resource가 오염돼도 따라 바뀌지 않게)
func _mdata(kind: String) -> Resource:
	return ResourceLoader.load("res://data/mercs/%s.tres" % kind, "", ResourceLoader.CACHE_MODE_IGNORE)

# EV617 · S254: 강화는 준비 단계에, 파는 곳이 있고 골드가 있을 때만 된다. 마지막 단계면 거부한다
func ev617():
	var b = _camp(false)
	var out := _rank_api(b)
	if out != "":
		return out
	var cost: Array = b.MERC_KINDS.soldier.rank_cost
	var g0: int = b.gold
	out = check(b.state == "prep" and not b.rank_up("soldier") and b.gold == g0 and b.merc_rank.get("soldier", 0) == 0, "병영 없는 준비 단계(%s)에서 강화됐다: 골드 %d → %d · 단계 %s" % [b.state, g0, b.gold, b.merc_rank])
	if out == "":
		out = check(b.build("barracks", BARRACKS) != null, "마을 %s에 병영을 짓지 못했다" % BARRACKS)
	if out == "":
		g0 = b.gold
		out = check(b.rank_up("soldier") and b.gold == g0 - cost[0] and b.merc_rank.get("soldier") == 1, "병영 뒤 강화: 골드 %d → %d(비용 %d) · 단계 %s" % [g0, b.gold, cost[0], b.merc_rank])
	if out == "":
		b.gold = cost[1] - 1
		out = check(not b.rank_up("soldier") and b.gold == cost[1] - 1 and b.merc_rank.soldier == 1, "골드 %d로 2단계가 됐다(비용 %d): 단계 %s" % [cost[1] - 1, cost[1], b.merc_rank])
	b.gold = BIG
	if out == "":
		b.start_battle()
		var g: int = b.gold
		out = check(b.state == "battle" and not b.rank_up("soldier") and b.gold == g and b.merc_rank.soldier == 1, "전투 단계(%s)에서 강화됐다: 골드 %d → %d · 단계 %s" % [b.state, g, b.gold, b.merc_rank])
	if out == "":
		out = check(_win(b), "1라운드를 이겨 라운드 사이가 되지 않았다(%s)" % b.state)
	if out == "":
		var g: int = b.gold
		out = check(not b.rank_up("soldier") and b.gold == g and b.merc_rank.soldier == 1, "라운드 사이(%s)에서 강화됐다: 골드 %d → %d · 단계 %s" % [b.state, g, b.gold, b.merc_rank])
	if out == "":
		b.next_round()
		var g: int = b.gold
		var got := [b.rank_up("soldier"), b.rank_up("soldier")]
		var g2: int = b.gold
		var last: bool = b.rank_up("soldier")
		out = check(b.state == "prep" and got == [true, true] and g2 == g - cost[1] - cost[2] and not last and b.gold == g2 and b.merc_rank.soldier == 3,
			"다음 준비 단계(%s): 2·3단계 %s · 골드 %d → %d(비용 %d+%d) · 넷째 %s · 골드 %d · 단계 %s" % [b.state, got, g, g2, cost[1], cost[2], last, b.gold, b.merc_rank])
	return out

# EV618 · S254: 강화는 이미 있는 그 종류 용병(입은 피해는 그대로)과 뒤에 산 용병에 들고, 다른 종류와 데이터는 그대로다
func ev618():
	var b = _camp()
	var out := _rank_api(b)
	if out != "":
		return out
	var s1 = b.place_merc("soldier", Vector2i(12, 12))
	var s2 = b.place_merc("soldier", Vector2i(14, 12))
	var a = b.place_merc("archer", Vector2i(16, 12))
	if s1 == null or s2 == null or a == null:
		return "용병 둘·궁수 하나를 두지 못했다(%s, %s, %s)" % [s1, s2, a]
	s2.hp -= 10.0
	var arch := [a.max_hp, a.hp, a.damage]
	var base_hp: float = _mdata("soldier").hp
	var want: float = b.MERC_KINDS.soldier.ranks[0].get("hp", 0.0)
	if want <= base_hp:
		return "용병 1단계가 체력을 올리지 않는다(ranks[0] %s)" % [b.MERC_KINDS.soldier.ranks[0]]
	if not b.rank_up("soldier"):
		return "병영이 있는 준비 단계에서 용병 강화가 거부됐다"
	var s3 = b.place_merc("soldier", Vector2i(18, 12))
	return check(s1.max_hp == want and s1.hp == want and s2.max_hp == want and s2.hp == want - 10.0 and [a.max_hp, a.hp, a.damage] == arch
		and s3 != null and s3.hp == want and s3.max_hp == want and b.MERC_KINDS.soldier.hp == base_hp and base_hp == 50.0,
		"강화 뒤 용병 최대·체력 %s/%s, %s/%s(기대 %s, %s, 피해 10) · 궁수 %s(전 %s) · 새 용병 %s · 판 데이터 hp %s · 디스크 hp %s" % [s1.max_hp, s1.hp, s2.max_hp, s2.hp, want, want - 10.0, [a.max_hp, a.hp, a.damage], arch, [s3.max_hp, s3.hp] if s3 else null, b.MERC_KINDS.soldier.hp, base_hp])

# EV619 · S254: 3단계 용병(블록 수 2)은 EV301 배치에서 적 셋 가운데 둘을 붙잡고 하나는 지나간다
func ev619():
	var b = battle({"base": Vector2i(2, 10), "spawns": [Vector2i(29, 10)], "base_hp": BIG, "village": VILLAGE})
	var out := _rank_api(b)
	if out != "":
		return out
	if b.build("barracks", BARRACKS) == null:
		return "마을 %s에 병영을 짓지 못했다" % BARRACKS
	for i in 3:
		if not b.rank_up("soldier"):
			return "용병 %d단계 강화가 거부됐다" % (i + 1)
	var m = b.place_merc("soldier", Vector2i(12, 10), {"hp": BIG, "damage": 0, "sight": 0, "range": 0})
	var es := []
	for i in 3:
		es.append(b.spawn_enemy("basic", Vector2i(14, 9 + i), {"hp": BIG}))
	run(b, 4.0)
	var held := es.filter(func(e): return e.engaged == m)
	var gone := es.filter(func(e): return e.pos.x < 10.0)
	return check(m.block == 2 and held.size() == 2 and gone.size() == 1, "3단계 용병 블록 수 %d(2) · 붙잡음 %d(2) · 지나감 %d(1)" % [m.block, held.size(), gone.size()])

# EV620 · S254: 새 도전(restart)이면 강화 단계가 0이고 새로 둔 용병·공병은 데이터 수치다
func ev620():
	var b = _camp()
	var out := _rank_api(b)
	if out != "":
		return out
	if b.build("workshop", Vector2i(16, 3)) == null:
		return "마을 (16,3)에 작업장을 짓지 못했다"
	var got := []
	for i in 3:
		got.append(b.rank_up("soldier"))
	for i in 2:
		got.append(b.rank_up("engineer"))
	if got != [true, true, true, true, true]:
		return "용병 3단계·공병 2단계 강화 결과 %s" % [got]
	b.restart()
	var m = b.place_merc("soldier", Vector2i(12, 12))
	var e = b.place_merc("engineer", Vector2i(14, 12))
	var sd := _mdata("soldier")
	var ed := _mdata("engineer")
	return check(b.merc_rank.is_empty() and m != null and e != null and m.hp == sd.hp and m.max_hp == sd.hp and m.damage == sd.damage and m.block == sd.block and e.speed == ed.speed
		and [sd.hp, sd.damage, sd.block, ed.speed] == [50.0, 2.0, 1, 2.5],
		"restart 뒤 단계 %s · 새 용병 %s · 새 공병 속도 %s · 디스크 데이터 %s" % [b.merc_rank, [m.hp, m.max_hp, m.damage, m.block] if m else null, e.speed if e else null, [sd.hp, sd.damage, sd.block, ed.speed]])

# EV621 · S254: 강화 한 번은 라운드 집계의 산 용병 수에 하나로 센다. 거부된 강화는 세지 않는다
func ev621():
	var b = _camp()
	var out := _rank_api(b)
	if out != "":
		return out
	var n0: int = b.tally.merc_bought
	var ok: bool = b.rank_up("soldier")
	var n1: int = b.tally.merc_bought
	b.gold = 0
	var refused: bool = not b.rank_up("soldier")
	return check(ok and n1 == n0 + 1 and refused and b.tally.merc_bought == n1, "강화 %s: 산 용병 수 %d → %d · 골드 0 강화 거부 %s: %d" % [ok, n0, n1, refused, b.tally.merc_bought])

# EV622 · I203: 강화 단계와 강화된 용병은 저장 왕복에 남고, 칸이 없는 저장은 단계 0이다
func ev622():
	var save = load("res://src/sim/save.gd")
	var stage := {"village": VILLAGE, "base_hp": BIG, "rounds": [[ONE_ENEMY], [ONE_ENEMY]], "seed": 7}
	var a = battle(stage)
	var out := _rank_api(a)
	if out != "":
		return out
	a.build("barracks", BARRACKS)
	var m = a.place_merc("soldier", Vector2i(12, 12))
	if m == null or not a.rank_up("soldier"):
		return "용병을 두고 강화하지 못했다(%s, 단계 %s)" % [m, a.merc_rank]
	m.hp -= 10.0
	var want: float = a.MERC_KINDS.soldier.ranks[0].get("hp", 0.0)
	var d: Dictionary = save.snapshot(a)
	var b = battle(stage)
	save.apply(b, d)
	var ms: Array = b.units.filter(func(u): return u.kind == "soldier")
	var fresh = b.place_merc("soldier", Vector2i(14, 12))
	out = check(b.merc_rank == a.merc_rank and ms.size() == 1 and ms[0].max_hp == want and ms[0].hp == want - 10.0 and fresh != null and fresh.hp == want,
		"불러온 판: 단계 %s(기대 %s) · 용병 %s(기대 %s/%s) · 새 용병 %s" % [b.merc_rank, a.merc_rank, ms.map(func(u): return [u.max_hp, u.hp]), want, want - 10.0, fresh.hp if fresh else null])
	if out == "":
		var old: Dictionary = d.duplicate(true)
		old.erase("ranks")
		var c = battle(stage)
		c.merc_rank = {"soldier": 2}
		save.apply(c, old)
		out = check(c.merc_rank.is_empty() and c.units.size() == a.units.size(), "칸이 없는 저장의 단계 %s · 유닛 %d(기대 %d)" % [c.merc_rank, c.units.size(), a.units.size()])
	return out

# EV623 · S255: 준비 단계 병영 팝업의 «용병 강화 N» 버튼·툴팁·최대, 정보 칸 체력, 전투 단계엔 버튼 없음
func ev623():
	var main = _prep()
	var b = main.view.battle
	var out := _rank_api(b)
	var f = null
	if out == "":
		f = b.build("barracks", Vector2i(4, 4))
		out = check(f != null, "준비 단계에 마을 (4,4)에 병영을 짓지 못했다")
	var btn = null
	if out == "":
		main.controls.facility = f
		_frame(main)
		var cost: Array = b.MERC_KINDS.soldier.rank_cost
		btn = _starts(main.hud.popup, "용병 강화")
		out = check(btn != null and btn.text == "용병 강화 %d" % cost[0], "준비 단계 병영 팝업의 강화 버튼 %s(기대 «용병 강화 %d»)" % [btn.text if btn else null, cost[0]])
		if out == "":
			var tip := _tip_of(main, btn)
			var line := "체력 %d → %d" % [int(_mdata("soldier").hp), int(b.MERC_KINDS.soldier.ranks[0].hp)]
			out = check(line in tip, "강화 버튼 툴팁 «%s»에 «%s»가 없다" % [tip, line])
		if out == "":
			btn.pressed.emit()
			_frame(main)
			var lines: String = str(main.hud.grid._lines("soldier"))
			out = check(b.merc_rank.get("soldier") == 1 and btn.text == "용병 강화 %d" % cost[1] and "체력 %d" % int(b.MERC_KINDS.soldier.ranks[0].hp) in lines,
				"누른 뒤 단계 %s · 버튼 «%s»(기대 «용병 강화 %d») · 정보 칸 %s" % [b.merc_rank, btn.text, cost[1], lines])
		if out == "":
			b.rank_up("soldier")
			b.rank_up("soldier")
			_frame(main)
			out = check(b.merc_rank.get("soldier") == 3 and btn.is_visible_in_tree() and btn.text == "용병 강화 최대" and btn.disabled, "3단계 버튼 «%s» · 보임 %s · 못 누름 %s · 단계 %s" % [btn.text, btn.is_visible_in_tree(), btn.disabled, b.merc_rank])
		if out == "":
			b.start_battle()
			_frame(main)
			out = check(main.controls.facility == f and _starts(main.hud.popup, "용병 강화") == null and _starts(main.hud.popup, "용병") != null,
				"전투 단계 팝업: 고른 시설 %s · 강화 버튼 %s · 구매 버튼 %s" % [main.controls.facility, _starts(main.hud.popup, "용병 강화"), _starts(main.hud.popup, "용병")])
	_done(main)
	return out

# EV624 · S254: 강화는 전투 단계에 생산 시설에서 산 용병(recruit)에도 든다
func ev624():
	var b = _camp()
	var out := _rank_api(b)
	if out != "":
		return out
	var f = b.structure_at(BARRACKS)
	if f == null or not b.rank_up("soldier"):
		return "병영(%s)이 있는 준비 단계에서 용병 강화가 거부됐다" % f
	b.start_battle()
	var m = b.recruit(f)
	var want: float = b.MERC_KINDS.soldier.ranks[0].get("hp", 0.0)
	return check(m != null and want > _mdata("soldier").hp and m.hp == want and m.max_hp == want, "강화 뒤 전투 단계에 산 용병 %s(기대 체력 %s)" % [[m.max_hp, m.hp] if m else null, want])
