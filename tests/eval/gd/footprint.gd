extends "res://tests/eval/gd/lib.gd"
# bld-1 큰 건물(S216·I178). lib.gd 머리의 계약에 더하는 API:
#   STRUCTURE_KINDS[종류].size — 가로 × 깊이 칸(Vector2i)
#   구조물의 칸(cell)은 차지 칸의 앞 왼쪽 칸이다. 차지 칸은 x..x+가로−1 × y−깊이+1..y
#   Battle.grid.block_at(칸) — 길 격자가 보는 막힌 칸의 구조물
#   BattleView(res://src/ui/battle_view.gd).ghost(battle, 종류, 칸) -> [Rect2i 차지 칸, bool 지을 수 있나]

const View := preload("res://src/ui/battle_view.gd")

# 마을은 위쪽 0~5행(30칸 폭)
func _battle(over := {}):
	var stage := {"village": Rect2i(0, 0, 30, 6), "base_hp": BIG, "waves": [[{"kind": "basic", "count": 1000}]]}
	stage.merge(over, true)
	return battle(stage)

func _cells(r: Rect2i) -> Array:
	var out := []
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			out.append(Vector2i(x, y))
	return out

# 칸마다 structure_at과 grid.block_at이 s인지. 아니면 그 칸
func _covers(b, s, cells: Array):
	for c in cells:
		if b.structure_at(c) != s or b.grid.block_at(c) != s:
			return c
	return null

# EV444 · S216: 크기 표
func ev444():
	var want := {"house": Vector2i(2, 2), "church": Vector2i(2, 3), "barracks": Vector2i(3, 2), "workshop": Vector2i(3, 2), "archery": Vector2i(3, 2),
		"wall": Vector2i.ONE, "tower": Vector2i.ONE, "magic": Vector2i.ONE, "cannon": Vector2i.ONE}
	var b = _battle()
	for k in want:
		if b.STRUCTURE_KINDS[k].get("size") != want[k]:
			return "%s 크기가 %s다(%s여야 한다)" % [k, b.STRUCTURE_KINDS[k].get("size"), want[k]]
	return ""

# EV445 · S216: 차지 칸 넷이 모두 그 집이고 막힌 칸이다. 겹치거나 마을 밖으로 나가면 거부
func ev445():
	var b = _battle()
	var h = b.build("house", Vector2i(10, 3))
	if h == null:
		return "집을 (10,3)에 짓지 못했다"
	var c = _covers(b, h, _cells(Rect2i(10, 2, 2, 2)))
	if c != null:
		return "차지 칸 %s가 집이 아니다(structure_at %s, block_at %s)" % [c, b.structure_at(c), b.grid.block_at(c)]
	for free in [Vector2i(12, 3), Vector2i(10, 1)]:
		if b.structure_at(free) != null or b.grid.block_at(free) != null:
			return "차지 칸 밖 %s가 막혔다" % free
	var gold0: int = b.gold
	if b.build("barracks", Vector2i(11, 4)) != null or b.gold != gold0:
		return "집과 겹치는 병영 (11,4)가 지어졌다(골드 %d → %d)" % [gold0, b.gold]
	return check(b.build("barracks", Vector2i(28, 3)) == null, "마을 밖 (30,3)까지 차지하는 병영 (28,3)이 지어졌다")

# EV446 · S216: 팔면 차지 칸이 모두 풀린다
func ev446():
	var b = _battle()
	var h = b.build("house", Vector2i(10, 3))
	if h == null or b.structure_at(Vector2i(11, 2)) != h:
		return "집을 지은 뒤 (11,2)가 집이 아니다(%s)" % [b.structure_at(Vector2i(11, 2))]
	b.sell([h])
	for c in _cells(Rect2i(10, 2, 2, 2)):
		if b.structure_at(c) != null or b.grid.block_at(c) != null:
			return "판 집의 차지 칸 %s가 남았다" % c
	return check(b.build("barracks", Vector2i(11, 3)) != null, "판 집 자리에 병영 (11,3)을 짓지 못했다")

# EV447 · S216: 부서지면 차지 칸이 모두 풀린다
func ev447():
	var b = _battle()
	var f = b.build("barracks", Vector2i(10, 3))
	b.start_battle()
	if f == null or b.structure_at(Vector2i(12, 2)) != f:
		return "병영을 지은 뒤 (12,2)가 병영이 아니다"
	b.damage(f, INF)
	for c in _cells(Rect2i(10, 2, 3, 2)):
		if b.structure_at(c) != null or b.grid.block_at(c) != null:
			return "부서진 병영의 차지 칸 %s가 남았다" % c
	return ""

# EV448 · I178: 산 용병은 차지 칸 둘레의 앞줄에서 집이 차지하지 않은 첫 칸에 나타난다
func ev448():
	var b = _battle()
	var f = b.build("barracks", Vector2i(10, 3))
	var h = b.build("house", Vector2i(10, 5))  # (10..11, 4..5)
	if f == null or h == null:
		return "병영·집을 짓지 못했다(%s, %s)" % [f, h]
	b.start_battle()
	var m = b.recruit(f)
	if m == null:
		return "병영에서 병사를 사지 못했다"
	return check(m.pos == Vector2(12, 4), "병사가 %s에 나타났다((12,4)여야 한다)" % m.pos)

# EV449 · I178: 공병은 차지 칸에 들어가지 않고 옆에서 짓는다
func ev449():
	var b = _battle()
	var e = b.place_merc("engineer", Vector2i(14, 2))
	if e == null:
		return "공병을 (14,2)에 두지 못했다"
	b.start_battle()
	var f = b.build("barracks", Vector2i(10, 3))
	if f == null:
		return "공병이 병영 (10,3) 짓기를 받지 않았다"
	var area := Rect2i(10, 2, 3, 2)
	var inside := []
	var done := run(b, 60.0, func():
		if area.has_point(cell_of(e)):
			inside.append(e.pos)
		return f.complete)
	if not inside.is_empty():
		return "공병이 차지 칸 %s에 들어갔다" % inside[0]
	return check(done, "60초 안에 병영을 다 짓지 못했다(진행률 %.2f)" % f.progress)

# EV450 · S216: 차지 칸 어디를 눌러도 그 시설을 고른다
func ev450():
	var b = _battle()
	var f = b.build("barracks", Vector2i(10, 3))
	b.start_battle()
	var c = controls(b)
	click(c, MOUSE_BUTTON_LEFT, px(Vector2i(12, 2)))
	if c.facility != f:
		return "(12,2)를 눌렀는데 고른 생산 시설이 %s다" % [c.facility]
	return check(c.picked == [f], "(12,2)를 눌렀는데 고른 구조물이 %s다" % [c.picked])

# EV451 · S216: 놓기 미리보기는 차지 칸과 지을 수 있는지
func ev451():
	var b = _battle()
	var g: Array = View.ghost(b, "house", Vector2i(10, 3))
	if g != [Rect2i(10, 2, 2, 2), true]:
		return "집 (10,3) 미리보기가 %s다" % [g]
	b.build("house", Vector2i(10, 3))
	g = View.ghost(b, "barracks", Vector2i(11, 3))
	if g != [Rect2i(11, 2, 3, 2), false]:
		return "집과 겹치는 병영 (11,3) 미리보기가 %s다" % [g]
	return check(View.ghost(b, "barracks", Vector2i(28, 3))[1] == false, "마을 밖으로 나가는 병영 (28,3)이 지을 수 있다고 나왔다")

# EV452 · I178: 마을 안 적은 가장 가까운 차지 칸까지 재서 노리고, 비행 적은 그 칸 옆에서 친다
func ev452():
	var b = _battle()
	var f = b.build("barracks", Vector2i(5, 1))
	b.start_battle()
	b.spawn_enemy("basic", Vector2i(9, 1), {"hp": BIG, "sight": 2.5})
	if not run(b, 10.0, func(): return f.hp < f.max_hp):
		return "인식 범위 2.5인 적이 2칸 떨어진 병영 차지 칸을 치지 않았다"
	var b2 = _battle()
	var f2 = b2.build("barracks", Vector2i(5, 1))
	b2.start_battle()
	var e = b2.spawn_enemy("flying", Vector2i(9, 1), {"hp": BIG, "sight": 2.5})
	if not run(b2, 10.0, func(): return f2.hp < f2.max_hp):
		return "비행 적이 병영을 치지 않았다"
	return check(e.pos.x >= 7.5, "비행 적이 x %.2f에서 쳤다(가장 가까운 차지 칸 (7,·) 옆이어야 한다)" % e.pos.x)
