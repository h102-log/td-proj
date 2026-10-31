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
		out = check(_win(b), "1라운드를 이겨 라운드 사이가 되지 않았다(%s)" % b.state)
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
			out = check(_win(b), "라운드를 이겨 라운드 사이가 되지 않았다(%s)" % b.state)
		if out == "":
			var got := [b.forge("ignis"), b.forge("ignis"), b.forge("ignis")]
			out = check(got == [true, true, false] and b.bag.get("ignis") == want, "창 하나에서 세 번 %s · 가방 %s(기대 [true, true, false], ignis %d)" % [got, b.bag, want])
			b.next_round()
	if out == "":
		out = check(_win(b), "3라운드를 이겨 라운드 사이가 되지 않았다(%s)" % b.state)
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
		out = check(_win(b) and b.forge("ignis"), "라운드 사이에서 장비를 만들지 못했다(%s, 가방 %s)" % [b.state, b.bag])
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
		var made: bool = _win(b2) and b2.forge("ignis")
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
		out = check(_win(b) and b.forge("ignis") and b.bag.get("ignis") == 4 and b.forged.get("ignis") == 1, "라운드 사이 강화: 가방 %s · 횟수 %s" % [b.bag, b.forged])
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
		out = check(_win(b) and b.forge("ignis") and b.forge("ignis") and b.bag.get("ignis") == 1, "라운드 사이에서 만들고 강화하지 못했다(가방 %s)" % [b.bag])
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
		out = check(_win(b), "1라운드를 이겨 라운드 사이가 되지 않았다(%s)" % b.state)
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
