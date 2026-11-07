extends "res://tests/eval/gd/lib.gd"
# WBS 2.12 판매(S69·S70·I56·I57·I58). lib.gd 머리의 계약에 더하는 API:
#   Battle.sell(things: Array) — 준비 단계에만, 플레이어가 놓은 구조물·용병을 판다. 구조물은 낸 골드 × 남은 체력 비율 × 0.8,
#     용병은 낸 골드 × 남은 체력 비율을 돌려준다(1골드 미만 버림, S69 2026-11-07 변경)
#   Controls.selling — 판매 후보 배열(클릭·드래그로 정해진다)

func _waves(n: int) -> Array:
	var ws := []
	for i in n:
		ws.append([{"kind": "basic", "count": 1}])
	return ws

# EV54 · S69 2026-11-07 변경: 준비 단계에 놓은 타워와 병사를 팔면 타워는 낸 골드의 80%(20 → 16), 병사는 낸 골드 모두가 돌아오고 둘 다 사라진다
func ev54():
	var b = battle({"gold": 100})
	var t = b.build("tower", Vector2i(10, 5))
	var paid_t: int = 100 - b.gold
	var m = b.place_merc("soldier", Vector2i(12, 5))
	if t == null or m == null or paid_t <= 0 or b.gold >= 100 - paid_t:
		return "타워·용병을 놓지 못했다(골드 %d)" % b.gold
	b.sell([t, m])
	var want: int = 100 - paid_t + floori(paid_t * 0.8)
	var ok: bool = b.gold == want and b.structure_at(Vector2i(10, 5)) == null and m not in b.units
	return check(ok, "판 뒤 골드 %d(%d여야 한다: 타워 %d골드의 80%%와 병사 값 전액), 타워 칸 %s, 용병이 전장에 %s" % [b.gold, want, paid_t, b.structure_at(Vector2i(10, 5)), m in b.units])

# EV55 · S69 2026-11-07 변경: 앞 웨이브에서 깎인 타워를 다음 준비 단계에 팔면 낸 골드 × 남은 체력 비율 × 0.8(내림)이 돌아온다
func ev55():
	var b = battle({"gold": 100, "base_hp": BIG, "waves": _waves(2)})
	var t = b.build("tower", Vector2i(5, 5))
	var paid: int = 100 - b.gold
	b.start_battle()
	b.damage(t, t.max_hp * 0.4)
	clear_wave(b)
	var want: int = floori(paid * float(t.hp) / t.max_hp * 0.8)
	if b.state != "prep" or t.hp >= t.max_hp:
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

# EV59 · S70·I57: 준비 단계에 타워·방벽·용병 하나씩과 영웅·성벽·성문을 함께 덮는 사각형을 드래그하면 판매 후보가 용병 하나뿐이다(I173 2026-11-06 변경).
# 타워·방벽·성벽·성문만 덮는 사각형이면 타워·방벽 둘뿐이다
func ev59():
	var b = battle({"hero_start": Vector2i(10, 7),
		"castle": {"walls": [Vector2i(12, 4)], "gates": [Vector2i(13, 4)], "wall_hp": 300, "gate_hp": 150}})
	var built := [b.build("tower", Vector2i(10, 5)), b.build("wall", Vector2i(11, 5))]
	var m = b.place_merc("soldier", Vector2i(12, 6))
	var c = controls(b)
	drag(c, px(Vector2i(9, 4)), px(Vector2i(13, 7)))
	var mixed: bool = c.selling == [m]
	drag(c, px(Vector2i(9, 4)), Vector2(14, 6) * CELL_PX)
	var only: bool = c.selling.size() == 2 and built.all(func(x): return x in c.selling)
	return check(mixed and only, "함께 덮은 상자의 판매 후보가 용병 하나 %s · 구조물만 덮은 상자의 판매 후보가 타워·방벽 %s(%d개)" % [mixed, only, c.selling.size()])

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

# EV594 · S204 2026-10-29 변경: 좌클릭은 누른 자리가 그림 자리(발 기준 가로 ±0.5칸, 위 0.9칸~아래 0.35칸) 안인 유닛 가운데 그 가운데가 가장 가까운 것을 고른다
func ev594():
	var b = battle({"heroes": [{"kind": "sylvia", "cell": Vector2i(12, 10)}]})
	var m1 = b.place_merc("soldier", Vector2i(10, 10))
	var m2 = b.place_merc("soldier", Vector2i(10, 10))
	m2.pos = Vector2(10.4, 10)
	var h = b.heroes[0]
	var c = controls(b)
	var got := []
	for u in [m1, m2, h]:
		click(c, MOUSE_BUTTON_LEFT, (u.pos + Vector2(0.5, 0.0)) * CELL_PX)  # 몸통 자리 = 발 자리 + (0, −0.5)칸, 칸 왼쪽 위가 0
		got.append(c.selected == [u])
	click(c, MOUSE_BUTTON_LEFT, (m1.pos + Vector2(0.5, 0.5 - 0.8)) * CELL_PX)  # 첫째 병사 머리(발 자리에서 0.8칸 위, 위 칸에 든다)
	got.append(c.selected == [m1])
	return check(got == [true, true, true, true], "첫째·둘째 병사·영웅 몸통, 첫째 머리 칸을 눌러 고른 것이 맞나: %s" % [got])

# EV791 · I173 2026-11-06 변경: 드래그 상자에 용병이 들면 두 단계 모두 상자 안 구조물은 고르지 않는다. 구조물만 든 상자는 그 구조물을 고른다
func ev791():
	var b = battle({"base_hp": BIG, "waves": _waves(1)})
	var built := [b.build("tower", Vector2i(10, 5)), b.build("wall", Vector2i(11, 5))]
	var m = b.place_merc("soldier", Vector2i(12, 6))
	if built.has(null) or m == null:
		return "타워·방벽·용병을 놓지 못했다"
	var c = controls(b)
	drag(c, Vector2(9, 4) * CELL_PX, Vector2(14, 8) * CELL_PX)  # 칸 (9,4)~(13,7)
	var prep: bool = c.selected == [m] and c.selling == [m] and c.picked.is_empty()
	var prep_n := [c.selected.size(), c.selling.size(), c.picked.size()]
	b.start_battle()
	drag(c, Vector2(9, 4) * CELL_PX, Vector2(14, 8) * CELL_PX)
	var fight: bool = b.state == "battle" and c.selected == [m] and c.picked.is_empty() and c.selling.is_empty()
	var fight_n := [c.selected.size(), c.selling.size(), c.picked.size()]
	drag(c, Vector2(9, 4) * CELL_PX, Vector2(12, 6) * CELL_PX)  # 칸 (9,4)~(11,5): 타워·방벽만
	var only: bool = c.selected.is_empty() and c.picked.size() == 2 and built.all(func(x): return x in c.picked)
	return check(prep and fight and only, "[고른 것·판매·picked 수] 준비 단계 상자 %s %s · 전투 단계 상자 %s %s · 구조물만 든 상자 %s %s" % [prep, prep_n, fight, fight_n, only, [c.selected.size(), c.selling.size(), c.picked.size()]])

# EV805 · S69 2026-11-07 변경: 준비 단계에 집·병영·방벽(가득 참)을 팔면 낸 골드 × 0.8, 깎인 병사(52%)·궁수(50%)를 팔면 낸 골드 × 남은 체력 비율이
# 돌아오고(1골드 미만 버림) 판 것은 모두 사라진다
func ev805():
	var b = battle({"village": Rect2i(0, 0, 30, 6), "gold": 1000})
	var plan := [["house", Vector2i(10, 3), 1.0, 0.8], ["barracks", Vector2i(15, 3), 1.0, 0.8], ["wall", Vector2i(5, 12), 1.0, 0.8],
		["soldier", Vector2i(12, 12), 0.52, 1.0], ["archer", Vector2i(14, 12), 0.5, 1.0]]  # [종류, 칸, 남길 체력 비율, 판매 비율]
	var made := []
	for p in plan:
		var g: int = b.gold
		var x = b.build(p[0], p[1]) if p[0] in ["house", "barracks", "wall"] else b.place_merc(p[0], p[1])
		if x == null or g - b.gold <= 0:
			return "시험 조건이 틀렸다: %s를 %s에 놓지 못했다(골드 %d → %d)" % [p[0], p[1], g, b.gold]
		x.hp = x.max_hp * p[2]
		made.append([x, g - b.gold])
	var got := []
	var want := []
	for i in plan.size():
		var x = made[i][0]
		want.append(floori(made[i][1] * x.hp / x.max_hp * plan[i][3]))
		var g: int = b.gold
		b.sell([x])
		got.append(b.gold - g)
	var gone: bool = b.structure_at(Vector2i(10, 3)) == null and b.structure_at(Vector2i(15, 3)) == null \
		and b.structure_at(Vector2i(5, 12)) == null and made[3][0] not in b.units and made[4][0] not in b.units
	return check(got == want and gone, "집·병영·방벽·병사·궁수를 판 환불 %s(%s여야 한다, 낸 골드 %s) · 모두 사라짐 %s" % [got, want, made.map(func(m): return m[1]), gone])
