extends "res://tests/eval/gd/lib.gd"
# WBS 2.17 영웅 스킬 2 «아군 버프»(S84·I65). lib.gd 머리의 계약에 더하는 API:
#   Controls.handle(KEY_W 눌림) — 영웅의 아군 버프를 쓴다
#   영웅: buff_ready() · buff_mult(공격력 배율) · buff_time(지속 초) · buff_gap(재사용 대기 초)
# 배율·시간·대기는 영웅 필드에서 읽는다. 수치가 임시값이라(S84) 밸런스를 바꿔도 이 평가가 깨지지 않게
# W와 그 대기는 전투 단계에만 돈다(S136). 그래서 평가는 _start로 전투 단계를 연 뒤 잰다

const H := Vector2i(10, 10)  # 영웅
const IN := Vector2i(11, 10)  # 영웅 바로 옆 용병
const FAR := Vector2i(20, 15)  # 범위 밖 용병
const ONE := [{"kind": "basic", "count": 1}]  # 적 하나짜리 웨이브

func _press_w(c) -> void:
	var ev := InputEventKey.new()
	ev.keycode = KEY_W
	ev.pressed = true
	c.handle(ev)

# 움직이지도 반격하지도 않는 과녁
func _dummy(b, cell: Vector2i):
	return b.spawn_enemy("basic", cell, {"speed": 0, "sight": 0, "damage": 0, "hp": BIG})

# 과녁이 다음에 맞는 한 방의 피해. secs 안에 안 맞으면 0
func _next_hit(b, e, secs := 5.0) -> float:
	var h0: float = e.hp
	run(b, secs, func(): return e.hp < h0)
	return h0 - e.hp

# 전투 단계를 연다. 웨이브 적은 처치하고, 움직이지도 치지도 않는 적 하나를 구석에 남겨 전투 단계가 이어지게 한다(heroes.gd와 같다)
func _start(b) -> void:
	b.start_battle()
	run(b, 5.0, func(): return not b.enemies.is_empty())
	var idle = b.spawn_enemy("basic", Vector2i(0, 19), {"speed": 0, "sight": 0, "damage": 0})
	for x in b.enemies.duplicate():
		if x != idle:
			b.damage(x, BIG)

# EV74 · S84: W를 쓰면 영웅 옆 용병만 공격력이 배율만큼 오른다(새 판에서 바로 쓸 수 있다)
func ev74():
	var b = battle({"hero_start": H, "waves": [ONE]})
	var c = controls(b)
	var m_in = b.place_merc("soldier", IN)
	var m_far = b.place_merc("soldier", FAR)
	_start(b)
	var e_in = _dummy(b, IN + Vector2i(1, 0))
	var e_far = _dummy(b, FAR + Vector2i(1, 0))
	if b.hero.buff_mult <= 1.0:
		return "버프 배율이 %s다(1보다 커야 한다)" % b.hero.buff_mult
	_press_w(c)
	var hit_in := _next_hit(b, e_in)
	var hit_far := _next_hit(b, e_far)
	if not is_equal_approx(hit_in, m_in.damage * b.hero.buff_mult):
		return "옆 용병의 한 방이 %s다(%s × %s여야 한다)" % [hit_in, m_in.damage, b.hero.buff_mult]
	return check(is_equal_approx(hit_far, m_far.damage), "범위 밖 용병의 한 방이 %s다(%s여야 한다)" % [hit_far, m_far.damage])

# EV75 · S84: 지속 시간이 지나면 한 방이 기본 공격력으로 돌아온다
func ev75():
	var b = battle({"hero_start": H, "waves": [ONE]})
	var c = controls(b)
	var m = b.place_merc("soldier", IN)
	_start(b)
	var e = _dummy(b, IN + Vector2i(1, 0))
	_press_w(c)
	run(b, b.hero.buff_time + 0.5)
	var hit := _next_hit(b, e)
	return check(is_equal_approx(hit, m.damage), "지속 시간 뒤 한 방이 %s다(%s여야 한다)" % [hit, m.damage])

# EV76 · S84: 쓴 직후엔 다시 못 쓰고 대기가 지나면 쓸 수 있다. Q 스킬과 대기가 따로다
func ev76():
	var b = battle({"hero_start": H, "waves": [ONE]})
	var c = controls(b)
	_start(b)
	if not b.hero.buff_ready():
		return "새 판에서 버프를 쓸 수 없다"
	_press_w(c)
	if b.hero.buff_ready():
		return "W를 쓴 직후에 다시 쓸 수 있다"
	if not b.hero.skill_ready():
		return "W를 썼더니 Q 스킬을 쓸 수 없다"
	run(b, b.hero.buff_gap - 0.5)
	if b.hero.buff_ready():
		return "재사용 대기가 끝나기 전에 다시 쓸 수 있다"
	run(b, 1.0)
	return check(b.hero.buff_ready(), "재사용 대기가 지나도 다시 쓸 수 없다")

# EV77 · I65: W를 쓴 순간 범위 밖에 있던 용병은 지속 시간 안에 영웅 옆으로 와도 버프가 없다
func ev77():
	var b = battle({"hero_start": H, "waves": [ONE]})
	var c = controls(b)
	var m = b.place_merc("soldier", Vector2i(16, 10))
	_start(b)
	_press_w(c)
	b.order_move([m], IN)
	var walked := 0.0
	while walked < b.hero.buff_time and not near(m.pos, IN):
		run(b, DT)
		walked += DT
	if not near(m.pos, IN):
		return "버프 지속 시간 안에 영웅 옆에 오지 못했다"
	var e = _dummy(b, IN + Vector2i(1, 0))
	var hit := _next_hit(b, e, b.hero.buff_time - walked)
	if hit == 0.0:
		return "버프 지속 시간 안에 과녁을 치지 못했다"
	return check(is_equal_approx(hit, m.damage), "늦게 온 용병의 한 방이 %s다(%s여야 한다)" % [hit, m.damage])
