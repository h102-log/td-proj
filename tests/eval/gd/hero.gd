extends "res://tests/eval/gd/lib.gd"

const START := Vector2i(5, 5)

func _two_waves():
	var one := [{"kind": "basic", "count": 1}]
	return battle({"hero_start": Vector2i(20, 5), "base_hp": BIG, "waves": [one, one]})

# EV19 · S14: 영웅을 클릭해 고르고 우클릭한 지점으로 간다
func ev19():
	var b = battle({"hero_start": START})
	var c = controls(b)
	click(c, MOUSE_BUTTON_LEFT, px(START))
	click(c, MOUSE_BUTTON_RIGHT, px(Vector2i(15, 12)))
	var ok := run(b, 60, func(): return near(b.hero.pos, Vector2i(15, 12)))
	return check(ok, "우클릭한 지점에 도착하지 않았다")

# EV20 · S15: 명령 없이 사거리 안의 적을 공격한다
func ev20():
	var b = battle({"hero_start": START})
	var e = b.spawn_enemy("basic", START + Vector2i(1, 0), {"speed": 0, "damage": 0, "hp": BIG})
	var ok := run(b, 10, func(): return e.hp < e.max_hp)
	return check(ok, "영웅이 자동으로 공격하지 않았다")

# EV21 · S15: 스킬은 명령 없이는 쓰지 않는다
func ev21():
	var b = battle({"hero_start": START})
	b.spawn_enemy("basic", START + Vector2i(1, 0), {"speed": 0, "damage": 0, "hp": BIG})
	if not run(b, 60, func(): return b.hero.skill_ready()):
		return "60초 안에 스킬이 준비되지 않았다"
	run(b, 10)
	return check(b.hero.skill_uses == 0, "명령 없이 스킬을 %d번 썼다" % b.hero.skill_uses)

# EV22 · S26: 쓰러진 영웅은 웨이브 동안 없고, 다음 준비 단계에 시작 지점에 있다
func ev22():
	var b = _two_waves()
	b.start_battle()
	run(b, 1)
	b.damage(b.hero, BIG)
	run(b, 3)
	if b.hero.present:
		return "쓰러진 영웅이 웨이브 도중 전장에 있다"
	if not clear_wave(b) or b.state != "prep":
		return "웨이브가 끝나지 않았다"
	return check(b.hero.present and near(b.hero.pos, Vector2i(20, 5)), "다음 준비 단계에 시작 지점으로 복귀하지 않았다")

# EV23 · S27: 부활을 끄면 다음 준비 단계에도 돌아오지 않는다
func ev23():
	var b = _two_waves()
	b.revive = false
	b.start_battle()
	run(b, 1)
	b.damage(b.hero, BIG)
	if not clear_wave(b) or b.state != "prep":
		return "웨이브가 끝나지 않았다"
	return check(not b.hero.present, "부활을 껐는데 영웅이 돌아왔다")

# EV24 · I26: 영웅이 쓰러져도 판은 계속된다
func ev24():
	var b = _two_waves()
	b.start_battle()
	run(b, 1)
	b.damage(b.hero, BIG)
	run(b, 0.5)
	return check(b.state == "battle", "영웅 다운 뒤 판 상태가 %s다" % b.state)
