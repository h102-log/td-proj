extends "res://tests/eval/gd/lib.gd"

# EV32 · S28: 명령 없이 사거리 안의 적을 쏜다
func ev32():
	var b = battle()
	b.build("tower", Vector2i(10, 10), {"range": 4})
	var e = b.spawn_enemy("basic", Vector2i(12, 10), {"speed": 0, "damage": 0, "sight": 0, "hp": BIG})
	var ok := run(b, 10, func(): return e.hp < e.max_hp)
	return check(ok, "타워가 사거리 안의 적을 쏘지 않았다")

# EV33 · S28: 체력이 0이 되면 사라지고 칸이 빈다
func ev33():
	var b = battle()
	var t = b.build("tower", Vector2i(10, 10))
	b.damage(t, t.max_hp)
	return check(b.structure_at(Vector2i(10, 10)) == null, "파괴된 타워가 칸에 남아 있다")

# EV591 · S245: 시설 가격과 쏘는 구조물 사거리(2026-10-29 플레이 후기 2). 타워는 7칸 떨어진 적을 쏜다
func ev591():
	var b = battle()
	var k: Dictionary = b.STRUCTURE_KINDS
	var got := [k.wall.cost, k.tower.cost, k.tower.range, k.magic.cost, k.magic.range, k.cannon.cost, k.cannon.range]
	if got != [5, 20, 8.0, 30, 8.0, 40, 10.0]:
		return "방벽·타워·사거리·마법·사거리·대포·사거리 = %s, 기대 [5, 20, 8, 30, 8, 40, 10]" % [got]
	b.build("tower", Vector2i(5, 10))
	var e = b.spawn_enemy("basic", Vector2i(12, 10), {"speed": 0, "damage": 0, "sight": 0, "hp": BIG})
	return check(run(b, 5, func(): return e.hp < e.max_hp), "타워가 7칸 떨어진 적을 쏘지 않았다")

# EV592 · S110: 마법 타워에 맞은 적은 2초 동안 30% 느리다. 다시 맞아도, 둘에 맞아도 둔화는 30% 하나다
func ev592():
	var b = battle()
	b.build("magic", Vector2i(10, 12))
	var e = b.spawn_enemy("basic", Vector2i(9, 10), {"speed": 1.0, "damage": 0, "sight": 0, "hp": BIG})
	if not run(b, 3, func(): return e.hp < e.max_hp):
		return "마법 타워가 쏘지 않았다"
	var p0: Vector2 = e.pos
	run(b, 1.0)
	var went: float = e.pos.distance_to(p0)
	if absf(went - 0.7) > 0.06 or not is_equal_approx(b.effect(e, "slow"), 0.3):
		return "맞은 뒤 1초에 %.2f칸(0.7), 둔화 %s(0.3)" % [went, b.effect(e, "slow")]
	run(b, 1.1)
	if b.effect(e, "slow") != null:
		return "맞은 뒤 2.1초에도 둔화가 남았다(다음 발 전)"
	var b2 = battle()
	b2.build("magic", Vector2i(10, 12))
	b2.build("magic", Vector2i(11, 12))
	var e2 = b2.spawn_enemy("basic", Vector2i(10, 10), {"speed": 0, "damage": 0, "sight": 0, "hp": BIG})
	run(b2, 1.0)
	var slows: Array = e2.fx.values().filter(func(v): return v.has("slow"))
	return check(e2.max_hp - e2.hp >= 11.9 and slows.size() == 1 and is_equal_approx(slows[0].slow, 0.3), "둘에 맞은 뒤 깎인 체력 %s, 둔화 %s" % [e2.max_hp - e2.hp, slows])
