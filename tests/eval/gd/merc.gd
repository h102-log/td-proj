extends "res://tests/eval/gd/lib.gd"

const DEST := Vector2i(20, 10)

# EV25 · S16: 드래그 사각형 안의 용병만 선택된다
func ev25():
	var b = battle()
	var inside := [Vector2i(5, 5), Vector2i(6, 5), Vector2i(5, 6)].map(func(c): return b.place_merc("soldier", c))
	var outside = b.place_merc("soldier", Vector2i(12, 12))
	var c = controls(b)
	drag(c, px(Vector2i(4, 4)), px(Vector2i(7, 7)))
	var sel: Array = c.selected
	var ok: bool = sel.size() == 3 and inside.all(func(m): return m in sel) and not (outside in sel)
	return check(ok, "선택 결과가 사각형과 다르다 (%d명)" % sel.size())

# EV26 · S16: 명령 없이 사거리 안의 적을 공격한다
func ev26():
	var b = battle()
	b.place_merc("soldier", Vector2i(5, 5))
	var e = b.spawn_enemy("basic", Vector2i(6, 5), {"speed": 0, "damage": 0, "hp": BIG})
	var ok := run(b, 10, func(): return e.hp < e.max_hp)
	return check(ok, "용병이 자동으로 공격하지 않았다")

# 용병이 (2,10)에서 DEST로 가는 길 바로 옆 (10,11)에 멈춰 선 적을 둔다
func _pass_by(mode: String, enemy_hp: int) -> Array:
	var b = battle()
	var m = b.place_merc("soldier", Vector2i(2, 10), {"range": 1.5})
	var e = b.spawn_enemy("basic", Vector2i(10, 11), {"speed": 0, "damage": 0, "sight": 0, "hp": enemy_hp})
	b.set_move_mode([m], mode)
	b.order_move([m], DEST)
	return [b, m, e]

# EV27 · S35: «무조건 이동»은 가는 길의 적을 치지 않고 목적지에 간다
func ev27():
	var s := _pass_by("move", BIG)
	var b = s[0]
	var m = s[1]
	var e = s[2]
	var ok := run(b, 60, func(): return near(m.pos, DEST))
	return check(ok and e.hp == e.max_hp, "무조건 이동 중에 적을 공격했거나 도착하지 못했다")

# EV28 · S35: «이동 중 공격»은 가는 길의 적을 처치하고 목적지에 간다
func ev28():
	var s := _pass_by("attack_move", 30)
	var b = s[0]
	var m = s[1]
	var e = s[2]
	var ok := run(b, 120, func(): return not e.alive and near(m.pos, DEST))
	return check(ok, "적을 처치하고 목적지에 도착하지 못했다")

# EV29 · S36: 홀드가 켜진 용병은 반경 밖으로 나가지 않는다
func ev29():
	var b = battle()
	var m = b.place_merc("soldier", Vector2i(10, 10), {"sight": 10, "hold_radius": 2})
	b.set_hold([m], true)
	b.spawn_enemy("basic", Vector2i(15, 10), {"speed": 0, "damage": 0, "sight": 0, "hp": BIG})
	var far := [0.0]
	run(b, 10, func():
		far[0] = maxf(far[0], m.pos.distance_to(Vector2(10, 10)))
		return false)
	return check(far[0] <= 2.01, "홀드 반경 2를 벗어났다 (최대 %.2f)" % far[0])

# EV30 · S36: 홀드가 켜진 용병도 반경 안의 적은 공격한다
func ev30():
	var b = battle()
	var m = b.place_merc("soldier", Vector2i(10, 10), {"sight": 10, "hold_radius": 3})
	b.set_hold([m], true)
	var e = b.spawn_enemy("basic", Vector2i(12, 10), {"speed": 0, "damage": 0, "sight": 0, "hp": BIG})
	var ok := run(b, 10, func(): return e.hp < e.max_hp)
	return check(ok, "반경 안의 적을 공격하지 않았다")

# EV31 · I36: 홀드가 꺼진 용병은 인식 범위 안의 적에게 다가간다
func ev31():
	var b = battle()
	var m = b.place_merc("soldier", Vector2i(5, 5), {"sight": 10})
	var e = b.spawn_enemy("basic", Vector2i(11, 5), {"speed": 0, "damage": 0, "sight": 0, "hp": BIG})
	var d0: float = m.pos.distance_to(e.pos)
	run(b, 3)
	return check(m.pos.distance_to(e.pos) < d0, "인식 범위 안의 적에게 다가가지 않았다")

# EV381 · S196: 이동 중 공격으로 걷던 용병은 앞의 적을 쓰러뜨린 뒤 0.2초 동안 제자리에 서 있고, 0.3초에는 다시 걷고 있다
func ev381():
	var b = battle()
	var m = b.place_merc("soldier", Vector2i(5, 10))
	b.spawn_enemy("basic", Vector2i(8, 10), {"speed": 0, "damage": 0, "sight": 0, "hp": 1})
	b.order_move([m], DEST)
	if not run(b, 10, func(): return b.enemies.is_empty()):
		return "용병이 앞의 적을 쓰러뜨리지 않았다"
	var p0: Vector2 = m.pos
	for i in 4:
		b.step(DT)
	var still: float = m.pos.distance_to(p0)
	for i in 2:
		b.step(DT)
	return check(still < 0.001 and m.pos.distance_to(p0) > 0.05, "쓰러뜨린 뒤 0.2초 움직임 %.3f칸 · 0.3초 %.3f칸" % [still, m.pos.distance_to(p0)])

# EV388 · I9: 드래그 사각형이 영웅과 용병을 함께 고른다. 판매 후보에 영웅은 없고, 영웅이 여럿이면 Q는 출전 순서에서 앞선 영웅이 쓴다
func ev388():
	var b = battle({"heroes": [{"kind": "aias", "cell": Vector2i(12, 12)}, {"kind": "sylvia", "cell": Vector2i(5, 5)}]})
	if b.state != "prep" or b.heroes.size() != 2:
		return "준비 단계에 영웅 둘이 출전한 판이 아니다 (%s, %d명)" % [b.state, b.heroes.size()]
	var first = b.heroes[0]
	var second = b.heroes[1]
	var inside := [Vector2i(6, 5), Vector2i(5, 6)].map(func(c): return b.place_merc("soldier", c))
	var outside = b.place_merc("soldier", Vector2i(12, 13))
	var c = controls(b)
	var keyed := []
	c.skill_keyed.connect(func(h, _slot): keyed.append(h))
	drag(c, px(Vector2i(4, 4)), px(Vector2i(7, 7)))
	var sel: Array = c.selected.duplicate()
	var picked: bool = sel.size() == 3 and second in sel and inside.all(func(m): return m in sel) and not (first in sel) and not (outside in sel)
	var sale: bool = c.selling.size() == 2 and inside.all(func(m): return m in c.selling)
	c.skill_key("q")
	click(c, MOUSE_BUTTON_RIGHT, px(Vector2i(20, 5)))
	var sent: bool = sel.size() == 3 and sel.all(func(u): return not u.path.is_empty())
	b.spawn_enemy("basic", Vector2i(29, 19), {"speed": 0, "sight": 0, "damage": 0, "hp": BIG})
	b.start_battle()
	drag(c, px(Vector2i(4, 4)), px(Vector2i(14, 14)))
	var all: bool = c.selected.size() == 5 and first in c.selected and second in c.selected and outside in c.selected
	c.skill_key("q")
	var order: bool = keyed.size() == 2 and keyed[0] == second and keyed[1] == first
	return check(picked and sale and sent and all and order, "준비 단계 드래그 %s(%d개) · 판매 후보 %s · 우클릭 이동 %s · 전투 단계 드래그 %s(%d개) · Q 쓴 영웅 순서 %s" % [picked, sel.size(), sale, sent, all, c.selected.size(), order])
