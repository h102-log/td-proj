extends "res://tests/eval/gd/lib.gd"
# WBS 2.22 생산 시설 3종·마을 레벨(S50·S98·S99·S100·I47). lib.gd·production.gd 머리의 계약에 더하는 API:
#   구조물 kind "workshop"(작업장, 공병). 병영·사격장은 없고 거점(Battle.base)이 용병 열한 종을 판다(S98 2026-11-12 변경)
#   Battle.village_level — 마을 레벨(1에서 시작) · Battle.VILLAGE_UP — [레벨 1→2 비용, …]
#   Battle.raise_village() -> bool — 마을 레벨을 하나 올린다. 거부되면 false이고 레벨·골드가 그대로다
#   Controls.village — 거점이 골라져 있나(마을 레벨 팝업 대상)
#   단축키: 7 궁수 놓기 · 4·9는 비었다(S98 2026-11-12 변경)

const F := Vector2i(10, 3)  # 마을 칸
const G := Vector2i(14, 3)
const H := Vector2i(18, 3)
const OUT := Vector2i(15, 12)  # 들판 칸

# 마을은 위쪽 0~5행
func _battle(over := {}):
	var stage := {"village": Rect2i(0, 0, 30, 6), "base_hp": BIG, "waves": [[{"kind": "basic", "count": 1000}]]}
	stage.merge(over, true)
	return battle(stage)

func _key(c, key: int) -> void:
	var ev := InputEventKey.new()
	ev.keycode = key
	ev.pressed = true
	c.handle(ev)

func _archers(b) -> int:
	return b.units.filter(func(u): return u.kind == "archer").size()

# EV110 · S98: 작업장은 공병만 판다(종류를 비우면 공병). 마을이 있는 판의 거점은 live_prep이 꺼져도 병사·궁수를 판다(2026-11-12 변경)
func ev110():
	var b = _battle()
	var f = b.build("workshop", F)
	b.start_battle()
	var gold0: int = b.gold
	var a = b.recruit(f, "archer")
	if a != null or b.gold != gold0:
		return "작업장에서 궁수를 샀다(%s, 골드 %d → %d)" % [a, gold0, b.gold]
	var e = b.recruit(f)
	if e == null or e.kind != "engineer":
		return "작업장에서 종류 없이 산 용병이 %s다" % (e.kind if e else "없음")
	var got := []
	for kind in ["soldier", "archer"]:
		var g: int = b.gold
		var m = b.recruit(b.base, kind)
		got.append([kind, m.kind if m else "없음", g - b.gold])
	return check(got.all(func(x): return x[1] == x[0] and x[2] == b.MERC_KINDS[x[0]].cost), "거점에서 산 것 [종류, 나온 것, 준 골드] %s" % [got])

# EV111 · S99: 마을 레벨 2가 여는 구조물이 없다(S98 2026-11-12 변경). 레벨 1에 작업장·집·교회를 짓는다
func ev111():
	var b = _battle()
	var locked: Array = b.STRUCTURE_KINDS.keys().filter(func(k): return b.STRUCTURE_KINDS[k].village_level != 1)
	if not locked.is_empty():
		return "마을 레벨 1이 아닌 구조물 %s" % [locked]
	return check(b.build("workshop", F) != null and b.build("house", G) != null and b.build("church", H) != null, "레벨 1에서 작업장·집·교회를 짓지 못했다")

# EV112 · S99: 준비 단계에 레벨을 올리면 비용이 든다
func ev112():
	var b = _battle()
	var gold0: int = b.gold
	return check(b.raise_village() and b.village_level == 2 and b.gold == gold0 - b.VILLAGE_UP[0],
		"레벨 올리기 뒤 레벨 %d, 골드 %d → %d(비용 %d)" % [b.village_level, gold0, b.gold, b.VILLAGE_UP[0]])

# EV113 · S99: 골드가 모자라거나 이미 최대 레벨(2)이면 올리지 못한다
func ev113():
	var poor = _battle()
	poor.gold = poor.VILLAGE_UP[0] - 1
	if poor.raise_village() or poor.village_level != 1 or poor.gold != poor.VILLAGE_UP[0] - 1:
		return "골드가 모자란데 레벨 %d, 골드 %d" % [poor.village_level, poor.gold]
	var b = _battle()
	b.raise_village()
	var gold0: int = b.gold
	return check(not b.raise_village() and b.village_level == 2 and b.gold == gold0, "최대 레벨에서 또 올랐다(레벨 %d, 골드 %d → %d)" % [b.village_level, gold0, b.gold])

# EV114 · I47: 전투 단계에는 올리지 못한다
func ev114():
	var b = _battle()
	b.start_battle()
	var gold0: int = b.gold
	return check(not b.raise_village() and b.village_level == 1 and b.gold == gold0, "전투 중에 올랐다(레벨 %d, 골드 %d → %d)" % [b.village_level, gold0, b.gold])

# EV115 · S100: 거점을 클릭하면 골라지고, 빈 칸을 클릭하면 풀린다
func ev115():
	var b = _battle()
	var c = controls(b)
	click(c, MOUSE_BUTTON_LEFT, px(b.base.cell))
	if not c.village:
		return "거점을 클릭해도 골라지지 않았다"
	click(c, MOUSE_BUTTON_LEFT, px(OUT))
	return check(not c.village, "빈 칸을 클릭해도 거점이 골라져 있다")

# EV116 · S50: 마을이 있으면 그 용병의 시설이 있어야 준비 단계에 용병을 산다. 궁수(7)와 사격장으로 잰다(용병 키 3은 없다, I108 2026-11-06 변경)
func ev116():
	var b = _battle()
	var c = controls(b)
	var gold0: int = b.gold
	_key(c, KEY_7)
	click(c, MOUSE_BUTTON_LEFT, px(OUT))
	return check(_archers(b) == 1 and b.gold == gold0 - b.MERC_KINDS.archer.cost,
		"마을 Lv1·시설 없음에서 7 키 뒤 들판 칸에 놓인 궁수 %d명(1, 거점이 판다) · 골드 %d → %d" % [_archers(b), gold0, b.gold])

# EV117 · S50: 마을이 없으면 시설 없이 준비 단계에 용병을 산다. 궁수(7)로 잰다(용병 키 3은 없다, I108 2026-11-06 변경)
func ev117():
	var b = battle({"base_hp": BIG})
	var c = controls(b)
	_key(c, KEY_7)
	click(c, MOUSE_BUTTON_LEFT, px(OUT))
	return check(_archers(b) == 1, "마을이 없는데 궁수가 놓이지 않았다")

# EV118 · S98: 4·9 키(옛 병영·사격장 놓기)는 아무 일도 하지 않는다(2026-11-12 변경)
func ev118():
	var b = _battle()
	b.raise_village()
	var c = controls(b)
	var gold0: int = b.gold
	for key in [KEY_4, KEY_9]:
		_key(c, key)
		if c.placing != "":
			return "%s 키 뒤 놓기 모드가 «%s»다" % [OS.get_keycode_string(key), c.placing]
		click(c, MOUSE_BUTTON_LEFT, px(F))
	return check(b.structure_at(F) == null and b.gold == gold0, "4·9 키 뒤 좌클릭한 칸 %s · 골드 %d → %d" % [b.structure_at(F), gold0, b.gold])

# EV1103 · S98: 병영·사격장 종류가 없고 생산 시설은 작업장 하나다. 거점은 용병 열한 종을 모두 판다(2026-11-12 변경)
func ev1103():
	var b = _battle()
	var gone: Array = ["barracks", "archery"].filter(func(k): return k in b.STRUCTURE_KINDS)
	var makers: Array = b.STRUCTURE_KINDS.keys().filter(func(k): return not b.STRUCTURE_KINDS[k].produces.is_empty())
	var missing: Array = b.MERC_KINDS.keys().filter(func(k): return k not in b.base.produces)
	return check(gone.is_empty() and makers == ["workshop"] and missing.is_empty(),
		"남은 옛 종류 %s · 생산 시설 %s([workshop]) · 거점이 팔지 않는 용병 %s" % [gone, makers, missing])
