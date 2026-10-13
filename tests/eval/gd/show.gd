extends "res://tests/eval/gd/lib.gd"
# WBS 2.12 화면 표시(S71·S73). 그리기는 재지 못하니 그리는 데 쓰는 상태를 잰다. lib.gd 머리의 계약에 더하는 API:
#   유닛·적: target — 마지막으로 친 대상 · Controls.show_hp — 체력바를 모두 그리는가

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
