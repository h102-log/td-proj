extends "res://tests/eval/gd/lib.gd"
# WBS 2.12 판매(S69·S70·I56·I57·I58). lib.gd 머리의 계약에 더하는 API:
#   Battle.sell(things: Array) — 준비 단계에만, 플레이어가 놓은 구조물·용병을 팔고 낸 골드 × 남은 체력 비율을 돌려준다
#   Controls.selling — 판매 후보 배열(클릭·드래그로 정해진다)

func _waves(n: int) -> Array:
	var ws := []
	for i in n:
		ws.append([{"kind": "basic", "count": 1}])
	return ws

# EV54 · S69: 준비 단계에 놓은 타워와 용병을 팔면 낸 골드가 모두 돌아오고 둘 다 사라진다
func ev54():
	var b = battle({"gold": 100})
	var t = b.build("tower", Vector2i(10, 5))
	var m = b.place_merc("soldier", Vector2i(12, 5))
	if t == null or m == null or b.gold >= 100:
		return "타워·용병을 놓지 못했다(골드 %d)" % b.gold
	b.sell([t, m])
	var ok: bool = b.gold == 100 and b.structure_at(Vector2i(10, 5)) == null and m not in b.units
	return check(ok, "판 뒤 골드 %d, 타워 칸 %s, 용병이 전장에 %s" % [b.gold, b.structure_at(Vector2i(10, 5)), m in b.units])

# EV55 · S69: 앞 웨이브에서 깎인 타워를 다음 준비 단계에 팔면 낸 골드 × 남은 체력 비율(내림)이 돌아온다
func ev55():
	var b = battle({"gold": 100, "base_hp": BIG, "waves": _waves(2)})
	var t = b.build("tower", Vector2i(5, 5))
	var paid: int = 100 - b.gold
	b.start_battle()
	b.damage(t, t.max_hp * 0.4)
	clear_wave(b)
	var want: int = floori(paid * float(t.hp) / t.max_hp)
	if b.state != "prep" or want >= paid:
		return "다음 준비 단계에 깎인 타워가 없다(%s, 체력 %d/%d)" % [b.state, t.hp, t.max_hp]
	var before: int = b.gold
	b.sell([t])
	return check(b.gold - before == want and b.structure_at(Vector2i(5, 5)) == null,
		"낸 골드 %d, 체력 %d/%d, 기대 %d, 돌려받은 골드 %d" % [paid, t.hp, t.max_hp, want, b.gold - before])

# EV56 · S69: 전투 단계에는 팔 수 없다
func ev56():
	var b = battle({"base_hp": BIG, "waves": _waves(1)})
	var t = b.build("tower", Vector2i(5, 5))
	b.start_battle()
	var before: int = b.gold
	b.sell([t])
	return check(b.gold == before and b.structure_at(Vector2i(5, 5)) == t, "전투 중에 팔렸다(골드 %d → %d)" % [before, b.gold])

# EV57 · I56: 영웅과 성곽 칸은 팔 수 없다
func ev57():
	var b = battle({"hero_start": Vector2i(5, 5),
		"castle": {"walls": [Vector2i(8, 3)], "gates": [Vector2i(8, 4)], "wall_hp": 300, "gate_hp": 150}})
	var before: int = b.gold
	b.sell([b.hero, b.castle[Vector2i(8, 3)], b.castle[Vector2i(8, 4)]])
	var ok: bool = b.gold == before and b.hero in b.units and b.castle.has(Vector2i(8, 3)) and b.castle.has(Vector2i(8, 4))
	return check(ok, "영웅·성곽이 팔렸다(골드 %d → %d)" % [before, b.gold])

# EV58 · S70: 준비 단계에 타워 칸을 좌클릭하면 판매 후보가 그 타워 하나다
func ev58():
	var b = battle()
	var t = b.build("tower", Vector2i(10, 5))
	var c = controls(b)
	click(c, MOUSE_BUTTON_LEFT, px(Vector2i(10, 5)))
	return check(c.selling == [t], "판매 후보가 %s다" % [c.selling])

# EV59 · S70·I57: 준비 단계에 타워·방벽·용병 하나씩과 영웅·성벽·성문을 함께 덮는 사각형을 드래그하면 판매 후보가 앞의 셋이다
func ev59():
	var b = battle({"hero_start": Vector2i(10, 7),
		"castle": {"walls": [Vector2i(12, 4)], "gates": [Vector2i(13, 4)], "wall_hp": 300, "gate_hp": 150}})
	var want := [b.build("tower", Vector2i(10, 5)), b.build("wall", Vector2i(11, 5)), b.place_merc("soldier", Vector2i(12, 6))]
	var c = controls(b)
	drag(c, px(Vector2i(9, 4)), px(Vector2i(13, 7)))
	var ok: bool = c.selling.size() == 3 and want.all(func(x): return x in c.selling)
	return check(ok, "판매 후보가 %d개다" % c.selling.size())

# EV60 · I57: 전투 단계의 클릭은 판매 후보를 만들지 않는다
func ev60():
	var b = battle({"base_hp": BIG, "waves": _waves(1)})
	b.build("tower", Vector2i(10, 5))
	b.start_battle()
	var c = controls(b)
	click(c, MOUSE_BUTTON_LEFT, px(Vector2i(10, 5)))
	return check(c.selling.is_empty(), "전투 중 판매 후보가 %s다" % [c.selling])

# EV63 · I58: 판매 후보가 있을 때 빈 칸을 좌클릭하면 판매 후보가 빈다
func ev63():
	var b = battle()
	var t = b.build("tower", Vector2i(10, 5))
	var c = controls(b)
	click(c, MOUSE_BUTTON_LEFT, px(Vector2i(10, 5)))
	if c.selling != [t]:
		return "타워를 클릭해도 판매 후보가 %s다" % [c.selling]
	click(c, MOUSE_BUTTON_LEFT, px(Vector2i(5, 15)))
	return check(c.selling.is_empty(), "빈 칸을 클릭한 뒤 판매 후보가 %s다" % [c.selling])

# EV237 · I135: 전투 단계에도 좌클릭한 용병은 고른 상태가 되고(판매 후보는 아니다) 우클릭 이동 지시를 받는다
func ev237():
	var b = battle({"base_hp": BIG, "waves": _waves(1)})
	var m = b.place_merc("soldier", Vector2i(10, 5))
	b.start_battle()
	var c = controls(b)
	click(c, MOUSE_BUTTON_LEFT, px(Vector2i(10, 5)))
	if c.selected != [m] or not c.selling.is_empty():
		return "전투 중 용병을 눌렀더니 고른 유닛 %s · 판매 후보 %s" % [c.selected, c.selling]
	var goal := Vector2i(10, 1)
	click(c, MOUSE_BUTTON_RIGHT, px(goal))
	return check(run(b, 10.0, func(): return near(m.pos, goal)), "우클릭한 칸에 닿지 못했다(%s)" % m.pos)
