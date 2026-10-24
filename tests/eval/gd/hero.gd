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

# EV21 · S15: 스킬은 명령 없이는 쓰지 않는다(자동 시전을 켜지 않았으면)
func ev21():
	var b = battle({"hero_start": START, "waves": [[{"kind": "basic", "count": 0}]]})
	b.spawn_enemy("basic", START + Vector2i(1, 0), {"speed": 0, "damage": 0, "hp": BIG})
	b.start_battle()
	if not b.can_cast(b.hero, "q"):
		return "전투 단계에서 Q를 쓸 수 있는 상태가 아니다"
	run(b, 10)
	return check(b.hero.skill_uses == 0 and b.state == "battle", "명령 없이 스킬을 %d번 썼다(%s)" % [b.hero.skill_uses, b.state])

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

# EV246 · S141: 영웅은 서 있을 때 인식 범위 안의 적에게 다가가 치고, 인식 범위 밖의 적에게는 가지 않는다
func ev246():
	var b = battle({"hero_start": START})
	var near = b.spawn_enemy("basic", START + Vector2i(2, 0), {"speed": 0, "sight": 0, "damage": 0, "hp": BIG})
	var reached := run(b, 5.0, func(): return near.hp < near.max_hp)
	var d = battle({"hero_start": START})
	var far = d.spawn_enemy("basic", START + Vector2i(4, 0), {"speed": 0, "sight": 0, "damage": 0, "hp": BIG})
	run(d, 3.0)
	var stayed: bool = d.hero.pos.distance_to(Vector2(START)) < 0.01 and far.hp == far.max_hp
	return check(reached and stayed, "2칸 앞 과녁에 다가가 침 %s(기사 %s, 인식 범위 %s) · 4칸 앞 과녁만 있으면 그대로 %s(기사 %s)" % [reached, b.hero.pos, b.hero.sight, stayed, d.hero.pos])

# EV383 · S196: 이동 명령으로 걷는 영웅은 사거리 안을 지나는 적을 치지 않는다
func ev383():
	var b = battle({"hero_start": START})
	var e = b.spawn_enemy("basic", START + Vector2i(6, 1), {"speed": 0, "sight": 0, "damage": 0, "hp": BIG})
	b.order_move([b.hero], START + Vector2i(12, 0))
	var arrived := run(b, 10, func(): return near(b.hero.pos, START + Vector2i(12, 0), 0.01))
	return check(arrived and e.hp == e.max_hp, "도착 %s(%s) · 지나친 적 체력 %s/%s" % [arrived, b.hero.pos, e.hp, e.max_hp])

# EV384 · S196: 친 영웅은 0.25초 동안 제자리에 서 있다가 0.35초에는 다음 적에게 다가가고 있다. 친 직후 이동 명령을 받으면 0.05초에는 그 자리이고 0.15초에는 걷고 있다
func ev384():
	var b = battle({"hero_start": START})
	b.spawn_enemy("basic", START + Vector2i(1, 0), {"speed": 0, "sight": 0, "damage": 0, "hp": 1})
	b.spawn_enemy("basic", START + Vector2i(0, 2), {"speed": 0, "sight": 0, "damage": 0, "hp": BIG})
	if not run(b, 5, func(): return b.enemies.size() == 1):
		return "영웅이 옆의 적을 쓰러뜨리지 않았다"
	var p0: Vector2 = b.hero.pos
	for i in 5:
		b.step(DT)
	var still: float = b.hero.pos.distance_to(p0)
	for i in 2:
		b.step(DT)
	var chased: float = b.hero.pos.distance_to(p0)
	var d = battle({"hero_start": START})
	d.spawn_enemy("basic", START + Vector2i(1, 0), {"speed": 0, "sight": 0, "damage": 0, "hp": 1})
	if not run(d, 5, func(): return d.enemies.is_empty()):
		return "영웅이 옆의 적을 쓰러뜨리지 않았다(이동 명령 판)"
	var q0: Vector2 = d.hero.pos
	d.order_move([d.hero], START + Vector2i(0, 6))
	d.step(DT)
	var held: float = d.hero.pos.distance_to(q0)
	for i in 2:
		d.step(DT)
	var walked: float = d.hero.pos.distance_to(q0)
	return check(still < 0.001 and chased > 0.05 and held < 0.001 and walked > 0.05,
		"친 뒤 0.25초 움직임 %.3f칸 · 0.35초 %.3f칸 · 이동 명령 0.05초 %.3f칸 · 0.15초 %.3f칸" % [still, chased, held, walked])

# EV385 · S196: 적이 선 칸으로 이동 명령을 받은 기사는 그 적 몸에 닿으면 도착이라(걸을 길이 빈다, S14) 3초 안에 그 적을 친다
func ev385():
	var b = battle({"hero_start": START})
	var e = b.spawn_enemy("basic", START + Vector2i(4, 0), {"speed": 0, "sight": 0, "damage": 0, "hp": BIG})
	b.order_move([b.hero], START + Vector2i(4, 0))
	run(b, 3.0)
	return check(b.hero.path.is_empty() and e.hp < e.max_hp, "기사 %s · 걸을 길 %s · 적 체력 %s/%s" % [b.hero.pos, b.hero.path, e.hp, e.max_hp])

# EV391 · S14: 적이 붙어 싸우던 영웅도 우클릭하면 걸어 나간다(막혀도 걷기를 그만두지 않는다). 들어갈 수 없는 칸으로 보내면 그 앞 칸에 선다
func ev391():
	var b = battle({"heroes": [{"kind": "sylvia", "cell": Vector2i(10, 10)}]})
	var h = b.heroes[0]
	b.spawn_enemy("basic", Vector2i(9, 10), {"speed": 0, "damage": 0, "hp": BIG})
	run(b, 1.0)
	var c = controls(b)
	click(c, MOUSE_BUTTON_LEFT, px(cell_of(h)))
	if not h in c.selected:
		return "실비아를 고르지 못했다"
	var p0: Vector2 = h.pos
	click(c, MOUSE_BUTTON_RIGHT, px(Vector2i(4, 10)))
	run(b, 1.5)
	var gone: float = h.pos.distance_to(p0)
	var d = battle({"hero_start": START})
	if d.build("wall", Vector2i(10, 5)) == null:
		return "방벽을 짓지 못했다"
	var k = d.hero
	var dc = controls(d)
	click(dc, MOUSE_BUTTON_LEFT, px(START))
	click(dc, MOUSE_BUTTON_RIGHT, px(Vector2i(10, 5)))
	var stood := run(d, 4.0, func(): return k.path.is_empty() and k.after.is_empty())
	var off: float = k.pos.distance_to(Vector2(10, 5))
	return check(gone > 2.0 and stood and off > 0.5 and off <= 1.1, "실비아가 1.5초에 %.2f칸 · 기사 걸을 길 비움 %s · 방벽 중심에서 %.2f칸" % [gone, stood, off])

# EV393 · I35: 공격 이동하는 영웅은 가는 길에 사거리에 든 적을 처치하고 목적지에 간다
func ev393():
	var b = battle({"hero_start": Vector2i(2, 10)})
	var e = b.spawn_enemy("basic", Vector2i(10, 11), {"speed": 0, "damage": 0, "sight": 0, "hp": 30})
	b.order_move([b.hero], Vector2i(20, 10), true)
	var ok := run(b, 60, func(): return not e.alive and near(b.hero.pos, Vector2i(20, 10)))
	return check(ok, "적 살아 있음 %s · 기사 %s" % [e.alive, b.hero.pos])

# EV394 · S35: 대상 공격하는 영웅은 사거리 안에 다른 적이 있어도 그 적만 치고, 그 적이 사라지면 그 자리에 선다. 걷는 적도 따라가 친다
func ev394():
	var b = battle({"hero_start": START})
	var a = b.spawn_enemy("basic", Vector2i(11, 5), {"speed": 0, "damage": 0, "sight": 0, "hp": BIG})
	var other = b.spawn_enemy("basic", Vector2i(9, 6), {"speed": 0, "damage": 0, "sight": 0, "hp": BIG})
	b.order_attack([b.hero], a)
	run(b, 4.0)
	var only: bool = a.hp < a.max_hp and other.hp == other.max_hp
	b.damage(a, BIG)
	b.step(DT)
	var stood: bool = b.hero.prey == null and b.hero.path.is_empty() and b.hero.after.is_empty()
	var d = battle({"hero_start": START})
	var w = d.spawn_enemy("basic", Vector2i(11, 5), {"speed": 1, "damage": 0, "sight": 0, "hp": BIG})
	d.order_attack([d.hero], w)
	var caught := run(d, 6.0, func(): return w.hp < w.max_hp)
	return check(only and stood and caught, "대상 체력 줆 %s · 다른 적 체력 %s/%s · 대상이 사라진 뒤 대상 %s 걸을 길 %s · 걷는 대상 따라가 침 %s" % [a.hp < a.max_hp, other.hp, other.max_hp, b.hero.prey, b.hero.path, caught])
