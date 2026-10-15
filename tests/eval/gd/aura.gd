extends "res://tests/eval/gd/lib.gd"
# WBS 3.2 영웅 오라(S96·S97·I82~I84). lib.gd 머리의 계약에 더하는 API:
#   영웅: aura_radius(오라 반경, 칸) · aura_guard(오라 안 용병이 받는 피해를 줄이는 비율, 0~1)
# 반경·감소율은 영웅 필드에서 읽는다. 수치가 임시값이라(S97) 밸런스를 바꿔도 이 평가가 깨지지 않게

const H := Vector2i(10, 10)  # 영웅
const IN := Vector2i(11, 10)  # 영웅 바로 옆 용병
const FAR := Vector2i(20, 15)  # 오라 반경 밖 용병
const HIT := 10.0  # 적 한 방의 피해

# 움직이지 않고, 인식 범위 안에서 가장 가까운 아군을 치는 적. 죽지 않는다
func _striker(b, cell: Vector2i):
	return b.spawn_enemy("basic", cell, {"speed": 0, "damage": HIT, "hp": BIG})

# 죽지 않는 용병
func _merc(b, kind: String, cell: Vector2i):
	return b.place_merc(kind, cell, {"hp": BIG})

# u가 다음에 맞는 한 방의 피해. secs 안에 안 맞으면 0
func _next_hit(b, u, secs := 5.0) -> float:
	var h0: float = u.hp
	run(b, secs, func(): return u.hp < h0)
	return h0 - u.hp

# 오라 안 용병이 받는 한 방
func _guarded(b) -> float:
	return HIT * (1.0 - b.hero.aura_guard)

# EV146 · S97: 새 판에서 영웅 옆 용병은 줄어든 피해를, 오라 반경 밖 용병은 그대로 받는다
func ev146():
	var b = battle({"hero_start": H})
	if b.hero.aura_guard <= 0.0 or b.hero.aura_guard >= 1.0:
		return "오라 감소율이 %s다(0과 1 사이여야 한다)" % b.hero.aura_guard
	if Vector2(FAR).distance_to(Vector2(H)) <= b.hero.aura_radius:
		return "반경 밖이어야 할 칸이 오라 반경 %s칸 안이다" % b.hero.aura_radius
	var m_in = _merc(b, "soldier", IN)
	var m_far = _merc(b, "soldier", FAR)
	_striker(b, IN + Vector2i(1, 0))
	_striker(b, FAR + Vector2i(1, 0))
	var hit_in := _next_hit(b, m_in)
	var hit_far := _next_hit(b, m_far)
	if not is_equal_approx(hit_in, _guarded(b)):
		return "영웅 옆 용병의 한 방이 %s다(%s여야 한다)" % [hit_in, _guarded(b)]
	return check(is_equal_approx(hit_far, HIT), "오라 반경 밖 용병의 한 방이 %s다(%s여야 한다)" % [hit_far, HIT])

# EV147 · S96: 영웅이 다운되면 오라가 풀려 옆 용병이 피해를 그대로 받는다
func ev147():
	var b = battle({"hero_start": H})
	var m = _merc(b, "soldier", IN)
	_striker(b, IN + Vector2i(1, 0))
	var before := _next_hit(b, m)
	if not is_equal_approx(before, _guarded(b)):
		return "다운 전 한 방이 %s다(%s여야 한다)" % [before, _guarded(b)]
	b.damage(b.hero, BIG)
	var after := _next_hit(b, m)
	return check(is_equal_approx(after, HIT), "영웅이 다운된 뒤 한 방이 %s다(%s여야 한다)" % [after, HIT])

# EV148 · I83: 웨이브 중 다운된 영웅이 다음 준비 단계에 복귀하면 오라가 다시 걸린다
func ev148():
	var b = battle({"hero_start": H, "waves": [[{"kind": "basic", "count": 1}], [{"kind": "basic", "count": 1}]]})
	b.start_battle()
	b.damage(b.hero, BIG)
	if not clear_wave(b):
		return "첫 웨이브가 끝나지 않았다(%s)" % b.state
	if b.state != "prep" or not b.hero.alive:
		return "준비 단계에 영웅이 돌아오지 않았다(상태 %s, 영웅 생존 %s)" % [b.state, b.hero.alive]
	var m = _merc(b, "soldier", IN)
	_striker(b, IN + Vector2i(1, 0))
	var hit := _next_hit(b, m)
	return check(is_equal_approx(hit, _guarded(b)), "복귀한 영웅 옆 용병의 한 방이 %s다(%s여야 한다)" % [hit, _guarded(b)])

# EV149 · I82: 오라는 상시라서, 반경 밖에서 맞던 용병 옆으로 영웅이 오면 그 뒤 한 방부터 줄어든다
func ev149():
	var b = battle({"hero_start": H})
	var m = _merc(b, "soldier", FAR)
	_striker(b, FAR + Vector2i(1, 0))
	var before := _next_hit(b, m)
	if not is_equal_approx(before, HIT):
		return "영웅이 오기 전 한 방이 %s다(%s여야 한다)" % [before, HIT]
	var to := FAR + Vector2i(-1, 0)
	b.order_move([b.hero], to)
	if not run(b, 20.0, func(): return near(b.hero.pos, to)):
		return "영웅이 용병 옆에 닿지 않았다(%s)" % b.hero.pos
	var after := _next_hit(b, m)
	return check(is_equal_approx(after, _guarded(b)), "영웅이 온 뒤 한 방이 %s다(%s여야 한다)" % [after, _guarded(b)])

# EV150 · I82: 궁수·공병도 오라를 받고, 영웅 자신은 받지 않는다
func ev150():
	for kind in ["archer", "engineer"]:
		var b = battle({"hero_start": H})
		var m = _merc(b, kind, IN)
		_striker(b, IN + Vector2i(1, 0))
		var hit := _next_hit(b, m)
		if not is_equal_approx(hit, _guarded(b)):
			return "영웅 옆 %s의 한 방이 %s다(%s여야 한다)" % [kind, hit, _guarded(b)]
	var hb = battle({"hero_start": H})
	_striker(hb, H + Vector2i(1, 0))
	var self_hit := _next_hit(hb, hb.hero)
	return check(is_equal_approx(self_hit, HIT), "영웅 자신의 한 방이 %s다(%s여야 한다)" % [self_hit, HIT])
