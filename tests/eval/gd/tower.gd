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
