extends "res://tests/eval/gd/lib.gd"
# WBS 3.6 영웅 레벨(S76·S125~S127·I112~I115). lib.gd·hire.gd·heroes.gd 머리의 계약에 더하는 API:
#   res://data/levels.tres — steps(다음 레벨까지 경험치 [Lv2, Lv3, Lv4, Lv5]) · growth(레벨마다 오르는 비율) · unlock(칸마다 열리는 레벨, S145) (S126).
#     Battle.LEVELS가 이 Resource다
#   적 데이터 xp(Battle.ENEMY_KINDS[종류].xp) — 처치되면 출전 영웅이 받는 경험치
#   영웅: level · xp · stage 키 heroes 항목의 level(없으면 최대 레벨, I115)
#   Battle.add_xp(영웅, 양) — 경험치를 더하고(상한 I113) 레벨·최대 체력·공격력을 맞춘다
#   Battle.transfer(주는 영웅, 받는 영웅) -> bool — 라운드 사이에서만 한다(S127)
# 수치는 Battle.LEVELS와 데이터에서 읽는다. EV205만 표를 대조하고, EV206·EV209·EV210은 S126의 누적 경험치를 쓴다

const CELLS := [Vector2i(10, 5), Vector2i(12, 5), Vector2i(14, 5)]  # 출전 칸(출전 3명, S123)
const ONE := [{"kind": "basic", "count": 1}]
const ONE_ONE := [[ONE], [ONE]]  # 라운드 2개, 라운드마다 적 1마리짜리 웨이브 하나

# 영입 창이 열린 판(출전 칸·씨앗·라운드 2개)
func _hiring(over := {}):
	var stage := {"hero_cells": CELLS, "seed": 7, "base_hp": BIG, "rounds": ONE_ONE}
	stage.merge(over, true)
	var b = battle(stage)
	b.begin_hiring()
	return b

# 아이아스 하나를 영입해 1라운드 준비 단계로 간 판과 그 아이아스
func _aias():
	var b = _hiring()
	b.offers = ["aias", "aias", "aias"]
	var k = b.hire(0)
	b.next_round()
	return [b, k]

func _key(c, key: int) -> void:
	var ev := InputEventKey.new()
	ev.keycode = key
	ev.pressed = true
	c.handle(ev)

# 적을 n번 내보내 곧바로 처치한다
func _kill(b, n: int) -> void:
	for i in n:
		b.damage(b.spawn_enemy("basic", Vector2i(0, 10)), BIG)

# 지금 라운드의 웨이브를 모두 이긴다. 라운드 사이나 승리가 되면 참
func _win_round(b) -> bool:
	for i in 20:
		if b.state != "prep":
			break
		b.start_battle()
		if not clear_wave(b):
			return false
	return b.state in ["cleared", "won"]

# EV204 · S125: 적이 처치되면 그때 전장에 살아 있는 출전 영웅이 모두 경험치를 받는다
func ev204():
	var b = _hiring()
	b.offers = ["aias", "seraphina", "ignis"]
	var k = b.hire(0)
	var p = b.hire(1)
	var m = b.hire(2)
	b.set_lineup(m, false)
	b.next_round()
	var x: int = b.ENEMY_KINDS.basic.xp
	_kill(b, 1)
	var first := [k.xp, p.xp, m.xp]
	b.damage(p, BIG)
	_kill(b, 1)
	var got := [k.xp, p.xp, m.xp]
	return check(first == [x, x, 0] and got == [2 * x, x, 0],
		"처치 한 번 뒤 %s([%d, %d, 0]이어야 한다) · 세라피나가 쓰러진 뒤 한 번 더 %s([%d, %d, 0]이어야 한다)" % [first, x, x, got, 2 * x, x])

# EV205 · S126: data/levels.tres와 적 경험치가 표와 같다
func ev205():
	var r = load("res://data/levels.tres")
	if r == null:
		return "data/levels.tres를 불러오지 못했다"
	var steps := [20, 30, 50, 70]
	var ok: bool = r.steps.size() == 4 and is_equal_approx(r.growth, 0.1) and r.unlock == {"q": 1, "w": 2, "e": 3, "r": 5}
	for i in 4:
		ok = ok and r.steps[i] == steps[i]
	var b = battle()
	var xps := {}
	for k in b.ENEMY_KINDS:
		xps[k] = b.ENEMY_KINDS[k].get("xp")
	ok = ok and xps.size() == 5 and xps.values().all(func(x): return x == 1)
	return check(ok, "다음 레벨까지 %s · 비율 %s · 열리는 레벨 %s · 적 경험치 %s" % [r.steps, r.growth, r.unlock, xps])

# EV206 · S126: 누적 경험치 20·50·100·170에 닿는 순간 Lv2·3·4·5가 되고, 그 뒤로는 Lv5다
func ev206():
	var kb = _aias()
	var b = kb[0]
	var k = kb[1]
	var seen := []  # 레벨이 바뀐 순간의 [경험치, 레벨]
	var lv: int = k.level
	for i in 200:
		_kill(b, 1)
		if k.level != lv:
			seen.append([k.xp, k.level])
			lv = k.level
	var want := [[20, 2], [50, 3], [100, 4], [170, 5]]
	return check(seen == want and k.level == 5 and k.xp == 170, "레벨이 바뀐 순간 %s(%s여야 한다) · 끝 Lv%d 경험치 %d" % [seen, want, k.level, k.xp])

# EV207 · I112: 레벨마다 최대 체력·공격력이 Lv1 값의 비율만큼 오르고, 체력도 오른 만큼 오른다. 스킬·오라 수치는 그대로다
func ev207():
	var kb = _aias()
	var b = kb[0]
	var k = kb[1]
	var base: Dictionary = b.HERO_KINDS.aias
	var g: float = b.LEVELS.growth
	b.damage(k, 30)
	var hp0: float = k.hp
	b.add_xp(k, 20)
	var lv2: bool = k.level == 2 and is_equal_approx(k.max_hp, base.hp * (1.0 + g)) and is_equal_approx(k.damage, base.damage * (1.0 + g)) and is_equal_approx(k.hp, hp0 + base.hp * g)
	b.add_xp(k, 150)
	var lv5: bool = k.level == 5 and is_equal_approx(k.max_hp, base.hp * (1.0 + 4.0 * g)) and is_equal_approx(k.damage, base.damage * (1.0 + 4.0 * g))
	var same: bool = b.SLOTS.all(func(slot): return k.get(slot) == base[slot]) and k.passive == base.passive and k.aura == base.aura
	return check(lv2 and lv5 and same, "Lv2 %s(최대 체력 %s, 공격력 %s, 체력 %s) · Lv5 %s(최대 체력 %s, 공격력 %s) · 스킬 수치 그대로 %s" % [lv2, k.max_hp, k.damage, k.hp, lv5, k.max_hp, k.damage, same])

# EV208 · S76: Q는 Lv1, W는 Lv2, E는 Lv3, R은 Lv5에 열린다. 그 전에는 그 칸의 키가 아무 일도 하지 않는다
func ev208():
	var kb = _aias()
	var b = kb[0]
	var k = kb[1]
	var c = controls(b)
	b.start_battle()  # 스킬은 전투 단계에만 쓴다(S136)
	var q: bool = b.can_cast(k, "q")
	_key(c, KEY_W)
	var locked: bool = k.cd.w == 0.0 and k.skill_uses == 0 and k.mana == k.max_mana
	b.add_xp(k, 20)
	_key(c, KEY_W)
	var w: bool = k.level == 2 and k.skill_uses == 1 and k.cd.w > 0.0
	b.add_xp(k, 30)
	_key(c, KEY_E)
	var e: bool = k.level == 3 and k.skill_uses == 2 and k.cd.e > 0.0
	b.add_xp(k, 50)
	k.mana = k.max_mana
	var r_shut: bool = k.level == 4 and not b.can_cast(k, "r")
	b.add_xp(k, 70)
	var r_open: bool = k.level == 5 and b.can_cast(k, "r")
	return check(q and locked and w and e and r_shut and r_open, "Lv1 Q %s · Lv1 W 잠김 %s · Lv2 W %s · Lv3 E %s · Lv4 R 잠김 %s · Lv5 R %s" % [q, locked, w, e, r_shut, r_open])

# EV209 · I115: 영입한 영웅은 Lv1, 스테이지가 준 영웅은 따로 정하지 않으면 최대 레벨이다
func ev209():
	var b = _hiring()
	b.offers = ["aias", "aias", "aias"]
	var k = b.hire(0)
	var hired: bool = k.level == 1 and k.xp == 0
	var s = battle({"hero_start": Vector2i(5, 5)})
	var start: bool = s.hero.level == 5 and s.hero.xp == 170
	var d = battle({"heroes": [{"kind": "aias", "cell": Vector2i(5, 5), "level": 2}]})
	var two: bool = d.hero.level == 2 and d.hero.xp == 20 and is_equal_approx(d.hero.max_hp, d.HERO_KINDS.aias.hp * (1.0 + d.LEVELS.growth))
	return check(hired and start and two, "영입 Lv1·0 %s · hero_start Lv5·170 %s · level 2 영웅 %s" % [hired, start, two])

# EV210 · S127: 이관은 라운드 사이에만 하고, 경험치를 전부 옮기며 주는 영웅은 Lv1로 보유에 남는다
func ev210():
	var b = _hiring()
	b.offers = ["aias", "seraphina", "ignis"]
	var k = b.hire(0)
	var p = b.hire(1)
	b.add_xp(p, 10)
	var early: bool = not b.transfer(k, p)
	b.set_lineup(p, false)
	b.next_round()
	b.add_xp(k, 50)
	var prep: bool = not b.transfer(k, p) and k.xp == 50 and p.xp == 10
	if not _win_round(b) or b.state != "cleared":
		return "1라운드를 이겨 라운드 사이가 되지 않았다(%s)" % b.state
	b.add_xp(k, 60 - k.xp)
	var g: int = b.gold
	var moved: bool = b.transfer(k, p)
	var after: bool = moved and p.xp == 70 and p.level == 3 and k.xp == 0 and k.level == 1 and k in b.roster \
		and is_equal_approx(k.max_hp, b.HERO_KINDS.aias.hp) and k.hp <= k.max_hp and b.gold == g
	b.add_xp(k, 150)
	b.transfer(k, p)
	return check(early and prep and after and p.xp <= 170, "도전 시작 전 거부 %s · 준비 단계 거부 %s · 라운드 사이 이관 %s(세라피나 %d, 아이아스 Lv%d %d, 체력 %s/%s) · 상한 170 %d" % [early, prep, after, p.xp, k.level, k.xp, k.hp, k.max_hp, p.xp])

# EV211 · I113: 전투 중에 경험치를 채우면 그 자리에서 레벨이 오르고 그 레벨의 칸이 열린다
func ev211():
	var kb = _aias()
	var b = kb[0]
	var k = kb[1]
	b.start_battle()
	if b.state != "battle":
		return "전투 단계가 아니다(%s)" % b.state
	_kill(b, 50)
	var lv3: bool = k.level == 3 and b.state == "battle"
	_key(controls(b), KEY_E)
	return check(lv3 and k.skill_uses == 1 and k.cd.e > 0.0, "전투 중 Lv3 %s(Lv%d, %s) · E 씀 %s" % [lv3, k.level, b.state, k.cd.e > 0.0])

# 아이아스·세라피나를 영입해 1라운드를 이긴 라운드 사이의 판과 두 영웅. 못 이기면 [판, 오류 문장]
func _cleared():
	var b = _hiring()
	b.offers = ["aias", "seraphina", "ignis"]
	var k = b.hire(0)
	var p = b.hire(1)
	b.next_round()
	if not _win_round(b) or b.state != "cleared":
		return [b, "1라운드를 이겨 라운드 사이가 되지 않았다(%s)" % b.state]
	return [b, k, p]

# EV227 · I116: 받는 영웅이 경험치를 다 받으면 상한(I113)을 넘을 때는 이관이 거부되고 둘 다 그대로다. 상한에 딱 닿는 이관은 받아들여진다
func ev227():
	var r: Array = _cleared()
	if r.size() == 2:
		return r[1]
	var b = r[0]
	var k = r[1]
	var p = r[2]
	var cap: int = b.LEVELS.steps.reduce(func(s, x): return s + x, 0)
	b.add_xp(p, cap - 50 - p.xp)
	b.add_xp(k, 50 - k.xp)
	var fit: bool = b.transfer(k, p) and p.xp == cap and k.xp == 0
	b.add_xp(k, 50)
	var refused: bool = not b.transfer(k, p) and p.xp == cap and k.xp == 50
	return check(fit and refused, "상한에 딱 닿는 이관 %s · 넘치는 이관 거부 %s(세라피나 %d, 아이아스 %d)" % [fit, refused, p.xp, k.xp])

# EV228 · I116: 이관으로 레벨이 바뀐 영웅은 체력 비율이 그대로라, 이관을 네 번 오가도 체력이 차지 않는다
func ev228():
	var r: Array = _cleared()
	if r.size() == 2:
		return r[1]
	var b = r[0]
	var k = r[1]
	var p = r[2]
	b.add_xp(k, b.LEVELS.steps.reduce(func(s, x): return s + x, 0) - k.xp)
	b.add_xp(p, -p.xp)
	k.hp = 10.0
	var ratio: float = k.hp / k.max_hp
	for i in 2:
		if not (b.transfer(k, p) and b.transfer(p, k)):
			return "이관 왕복 %d번째가 거부됐다(아이아스 %d, 세라피나 %d)" % [i + 1, k.xp, p.xp]
	return check(k.level == 5 and absf(k.hp / k.max_hp - ratio) < 0.001, "네 번 이관 뒤 아이아스 Lv%d 체력 %s/%s(비율 %s → %s)" % [k.level, k.hp, k.max_hp, ratio, k.hp / k.max_hp])
