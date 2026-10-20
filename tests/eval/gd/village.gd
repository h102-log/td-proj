extends "res://tests/eval/gd/lib.gd"
# WBS 2.22 생산 시설 3종·마을 레벨(S50·S98·S99·S100·I47). lib.gd·production.gd 머리의 계약에 더하는 API:
#   구조물 kind "barracks"(병영, 용병) · "workshop"(작업장, 공병) · "archery"(사격장, 궁수)
#   Battle.village_level — 마을 레벨(1에서 시작) · Battle.VILLAGE_UP — [레벨 1→2 비용, …]
#   Battle.raise_village() -> bool — 마을 레벨을 하나 올린다. 거부되면 false이고 레벨·골드가 그대로다
#   Controls.village — 거점이 골라져 있나(마을 레벨 팝업 대상)
#   단축키: 3 용병 놓기 · 9 사격장 놓기

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

func _soldiers(b) -> int:
	return b.units.filter(func(u): return u.kind == "soldier").size()

# EV110 · S98: 병영은 궁수를 팔지 않는다. 종류를 비우면 용병이다
func ev110():
	var b = _battle()
	var f = b.build("barracks", F)
	b.start_battle()
	var gold0: int = b.gold
	var a = b.recruit(f, "archer")
	if a != null or b.gold != gold0:
		return "병영에서 궁수를 샀다(%s, 골드 %d → %d)" % [a, gold0, b.gold]
	var s = b.recruit(f)
	return check(s != null and s.kind == "soldier", "종류 없이 산 용병이 %s다" % (s.kind if s else "없음"))

# EV111 · S99: 마을 레벨 1에는 사격장을 짓지 못하고, 병영·작업장은 짓는다
func ev111():
	var b = _battle()
	var gold0: int = b.gold
	if b.build("archery", F) != null or b.gold != gold0:
		return "레벨 %d에서 사격장이 지어졌다(골드 %d → %d)" % [b.village_level, gold0, b.gold]
	return check(b.build("barracks", G) != null and b.build("workshop", H) != null, "레벨 1에서 병영·작업장을 짓지 못했다")

# EV112 · S99: 준비 단계에 레벨을 올리면 비용이 들고 사격장이 열린다
func ev112():
	var b = _battle()
	var gold0: int = b.gold
	if not b.raise_village() or b.village_level != 2 or b.gold != gold0 - b.VILLAGE_UP[0]:
		return "레벨 올리기 뒤 레벨 %d, 골드 %d → %d(비용 %d)" % [b.village_level, gold0, b.gold, b.VILLAGE_UP[0]]
	var s = b.build("archery", F)
	return check(s != null and s.kind == "archery", "레벨 2에서 사격장을 짓지 못했다")

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

# EV116 · S50: 마을이 있으면 병영이 있어야 준비 단계에 용병을 산다
func ev116():
	var b = _battle()
	var c = controls(b)
	var gold0: int = b.gold
	_key(c, KEY_3)
	click(c, MOUSE_BUTTON_LEFT, px(OUT))
	if _soldiers(b) != 0 or b.gold != gold0:
		return "병영 없이 용병이 놓였다(골드 %d → %d)" % [gold0, b.gold]
	click(c, MOUSE_BUTTON_RIGHT, px(OUT))  # 놓기 모드를 끝낸다. 켜진 채 3 키를 다시 누르면 모드가 꺼진다(S186)
	b.build("barracks", F)
	_key(c, KEY_3)
	click(c, MOUSE_BUTTON_LEFT, px(OUT))
	return check(_soldiers(b) == 1, "병영을 지은 뒤에도 용병이 놓이지 않았다")

# EV117 · S50: 마을이 없으면 시설 없이 준비 단계에 용병을 산다
func ev117():
	var b = battle({"base_hp": BIG})
	var c = controls(b)
	_key(c, KEY_3)
	click(c, MOUSE_BUTTON_LEFT, px(OUT))
	return check(_soldiers(b) == 1, "마을이 없는데 용병이 놓이지 않았다")

# EV118 · S98: 레벨 2에서 9 키 뒤 마을 칸을 좌클릭하면 사격장이 지어진다
func ev118():
	var b = _battle()
	b.raise_village()
	var c = controls(b)
	_key(c, KEY_9)
	click(c, MOUSE_BUTTON_LEFT, px(F))
	var s = b.structure_at(F)
	return check(s != null and s.kind == "archery", "9 키 뒤 좌클릭한 칸 %s(놓기 모드 %s)" % [s, c.placing])
