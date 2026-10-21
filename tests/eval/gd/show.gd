extends "res://tests/eval/gd/lib.gd"
# WBS 2.12 화면 표시(S71·S73). 그리기는 재지 못하니 그리는 데 쓰는 상태를 잰다. lib.gd 머리의 계약에 더하는 API:
#   유닛·적: target — 마지막으로 친 대상 · Controls.show_hp — 체력바를 모두 그리는가
#   BattleView.hp_bar_size(유닛·적, show_hp) — 그 체력바의 크기(px). 그리지 않으면 Vector2.ZERO(static)

# EV61 · S71: 용병이 적을 치면 용병의 공격 대상이 그 적이고, 적이 거점을 치면 적의 공격 대상이 거점이다
func ev61():
	var b = battle({"base_hp": BIG})
	var m = b.place_merc("soldier", Vector2i(10, 10))
	var e = b.spawn_enemy("basic", Vector2i(11, 10), {"hp": BIG, "speed": 0.0})
	if not run(b, 5.0, func(): return e.hp < e.max_hp):
		return "용병이 적을 치지 않았다"
	if m.target != e:
		return "용병의 공격 대상이 %s다" % [m.target]
	var b2 = battle({"base_hp": BIG})
	var e2 = b2.spawn_enemy("basic", Vector2i(24, 10), {"sight": 0.0})
	if not run(b2, 5.0, func(): return b2.base.hp < b2.base.max_hp):
		return "적이 거점을 치지 않았다"
	return check(e2.target == b2.base, "적의 공격 대상이 %s다" % [e2.target])

# EV62 · S73: 체력바 표시는 처음에 꺼져 있고, V 키를 누를 때마다 켜짐·꺼짐이 바뀐다
func ev62():
	var c = controls(battle())
	var seen := [c.show_hp]
	for i in 2:
		var ev := InputEventKey.new()
		ev.keycode = KEY_V
		ev.pressed = true
		c.handle(ev)
		seen.append(c.show_hp)
	return check(seen == [false, true, false], "V를 두 번 누르는 동안 %s였다" % [seen])

# EV362 · S73: 보스 체력바는 V 표시와 상관없이 24×3이고, 기본 적은 켰을 때만 16×2다
func ev362():
	var b = battle()
	var boss = b.spawn_enemy("boss", Vector2i(10, 10), {"speed": 0.0})
	var e = b.spawn_enemy("basic", Vector2i(12, 10), {"speed": 0.0})
	var view = load("res://src/ui/battle_view.gd")
	if boss == null or e == null or not view.get_script_method_list().any(func(m): return m.name == "hp_bar_size"):
		return "보스(%s)·기본 적(%s)을 두지 못했거나 BattleView.hp_bar_size가 없다" % [boss, e]
	var got := [view.hp_bar_size(boss, false), view.hp_bar_size(boss, true), view.hp_bar_size(e, false), view.hp_bar_size(e, true)]
	return check(got == [Vector2(24, 3), Vector2(24, 3), Vector2.ZERO, Vector2(16, 2)], "보스(꺼짐·켜짐)·기본 적(꺼짐·켜짐) 체력바 크기 %s" % [got])
