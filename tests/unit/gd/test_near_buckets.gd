extends RefCounted
# 2칸 버킷(_units_near·_foes_near)이 전수 루프와 같은 결과를 내는지 본다.
# 지키는 요구:
#   I305. 적이 노릴 유닛·아군이 고를 적·몸 막기는 그 편의 몸을 2칸 버킷에 담아 후보만 보고, 결과는 그 편의 몸을 차례로 다 본 것과 같다.
#         버킷은 그 편의 누군가 생기거나 자리·몸 반지름이 바뀌었거나 목록의 수가 달라졌으면 다음에 물을 때 다시 담는다.
# 낡음을 재는 시험은 판 하나에서, 바꾼 뒤 다른 몸·판을 만들거나 움직이지 않고 곧바로 묻는다
# (세대 수가 클래스에 하나라 다른 판이 움직이면 이 판의 버킷도 다시 담겨 낡음이 가려진다).

const B := preload("res://src/sim/battle.gd")

func _battle():
	return B.new({"size": Vector2i(40, 40), "base": Vector2i(39, 39), "base_hp": 1000000, "gold": 1000000, "spawns": [Vector2i(0, 0)]})

func _unit(b, p: Vector2, r := 0.3):
	var u := B.Unit.new("soldier", Vector2i.ZERO, b.MERC_KINDS.soldier)
	u.pos = p
	u.radius = r
	b.units.append(u)
	return u

func _foe(b, p: Vector2, r := 0.3):
	var e := B.Enemy.new("basic", Vector2i.ZERO, b.ENEMY_KINDS.basic)
	e.pos = p
	e.radius = r
	b.enemies.append(e)
	return e

# arr에서 p에서 «r + 그 몸의 반지름» 안에 있는 번호(전수)
func _brute(arr: Array, p: Vector2, r: float) -> Array:
	var out := []
	for j in arr.size():
		if p.distance_to(arr[j].pos) <= r + arr[j].radius:
			out.append(j)
	return out

# 후보 ids가 오름차순이고 need를 모두 담았으면 "", 아니면 이유
func _covers(ids: Array, need: Array, n: int) -> String:
	for k in ids.size():
		if ids[k] < 0 or ids[k] >= n or (k > 0 and ids[k] <= ids[k - 1]):
			return "후보가 오름차순 번호가 아니다 %s" % [ids]
	var missed: Array = need.filter(func(j): return j not in ids)
	return "" if missed.is_empty() else "놓친 번호 %s(후보 %s)" % [missed, ids]

# 무작위 판 200개(몸 80개: 반지름 0.18~0.9, 큰 몸 2.0 둘, 음수 자리와 x 64 넘는 자리 포함)에서 무작위 점·거리로 물으면 닿을 번호가 모두 들고 오름차순이다
func test_candidates_cover_brute_force():
	var b = _battle()
	if not (b.has_method("_units_near") and b.has_method("_foes_near")):
		return "Battle에 _units_near·_foes_near가 없다"
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var asked := 0
	for board in 200:
		b.units.clear()
		b.enemies.clear()
		var wide: bool = board % 3 == 0  # 셋에 하나는 넓게 흩고, 나머지는 뭉친다
		var span := 70.0 if wide else 12.0
		for i in 80:
			var p := Vector2(rng.randf_range(-4.0, span), rng.randf_range(-4.0, span * 0.5))
			var r: float = 2.0 if i in [7, 50] else rng.randf_range(0.18, 0.9)
			if i % 2 == 0:
				_unit(b, p, r)
			else:
				_foe(b, p, r)
		for q in 20:
			var p := Vector2(rng.randf_range(-6.0, span + 2.0), rng.randf_range(-6.0, span * 0.5 + 2.0))
			var r: float = [rng.randf_range(0.0, 1.5), rng.randf_range(0.0, 8.0), rng.randf_range(8.0, 40.0), INF][q % 4]
			if q == 19:  # 버킷 칸 경계(짝수 좌표)에 놓인 점
				p = Vector2(2.0 * rng.randi_range(-2, 6), 2.0 * rng.randi_range(-2, 3))
			for side in [[b.units, b._units_near(p, r)], [b.enemies, b._foes_near(p, r)]]:
				var why := _covers(side[1], _brute(side[0], p, r), side[0].size())
				asked += 1
				if why != "":
					return "판 %d · 점 %s 거리 %s: %s" % [board, p, r, why]
	return "" if asked == 8000 else "물은 횟수 %d(8000)" % asked

# 같은 몸·같은 by로 _shove한 자리가, 그 몸을 제자리로 돌리고 같은 판에서 scan_all을 켜고 _shove한 자리와 같다
func _shove_twice(b, mover, by: Vector2, bodies: Array) -> String:
	var from: Vector2 = mover.pos
	b._shove(mover, by, bodies)
	var got: Vector2 = mover.pos
	mover.pos = from
	b.scan_all = true
	b._shove(mover, by, bodies)
	var want: Vector2 = mover.pos
	b.scan_all = false
	mover.pos = from
	return "" if got == want else "버킷 %s · 전수 %s(자리 %s, by %s)" % [got, want, from, by]

func test_shove_matches_full_scan():
	var b = _battle()
	if not "scan_all" in b:
		return "Battle에 scan_all이 없다"
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	var moved := 0
	for board in 300:
		b.units.clear()
		b.enemies.clear()
		for i in 30:
			var p := Vector2(rng.randf_range(10.0, 16.0), rng.randf_range(10.0, 16.0))
			var r: float = 2.0 if (i == 4 and board % 5 == 0) else [0.18, 0.3, 0.3, 0.45, 0.9][rng.randi_range(0, 4)]
			if board % 2 == 0:
				_foe(b, p, r)
			else:
				_unit(b, p, r)
		var at := Vector2(rng.randf_range(9.0, 17.0), rng.randf_range(9.0, 17.0))
		var mover = _unit(b, at) if board % 2 == 0 else _foe(b, at)  # 짝수 판은 유닛이 적에, 홀수 판은 적이 유닛에 막힌다
		var bodies: Array = b.enemies if board % 2 == 0 else b.units
		for k in 4:
			var by := Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(0.05, 1.5)
			var why := _shove_twice(b, mover, by, bodies)
			if why != "":
				return "무작위 판 %d: %s" % [board, why]
			var was: Vector2 = mover.pos
			b._shove(mover, by, bodies)
			if mover.pos != was:
				moved += 1
			mover.pos = at
	if moved < 300:
		return "무작위 판에서 실제로 움직인 밀기 %d번(300번 이상이어야 헛돌지 않는다)" % moved
	# 한 줄로 붙어 선 유닛 12명을 따라 미끄러지는 적: 밀릴 때마다 다음 몸에 겹쳐 처음 후보를 뽑은 자리에서 6칸 넘게 간다(다시 뽑기)
	b.units.clear()
	b.enemies.clear()
	for i in 12:
		_unit(b, Vector2(5.0 + 0.55 * i, 10.0))
	for i in 10:  # 먼 곳의 유닛: 그 편의 몸이 적으면(BUCKET_MIN 이하) 버킷을 거치지 않는다
		_unit(b, Vector2(30.0 + i, 30.0))
	var slider = _foe(b, Vector2(3.0, 10.0))
	var why := _shove_twice(b, slider, Vector2(2.05, 0.0), b.units)
	b._shove(slider, Vector2(2.05, 0.0), b.units)
	if why != "" or slider.pos.x < 11.0:
		return "한 줄 12명: %s · 미끄러진 자리 %s(x 11 이상이어야 다시 뽑기를 지난다)" % [why, slider.pos]
	# 큰 몸(반지름 2.0, 버킷에 넣지 않는 몸)에 닿는 유닛
	b.units.clear()
	b.enemies.clear()
	for i in 20:
		_foe(b, Vector2(20.0 + i, 30.0))
	var king = _foe(b, Vector2(12.0, 12.0), 2.0)
	var poker = _unit(b, Vector2(9.0, 12.0))
	why = _shove_twice(b, poker, Vector2(1.5, 0.0), b.enemies)
	b._shove(poker, Vector2(1.5, 0.0), b.enemies)
	if why != "" or absf(poker.pos.distance_to(king.pos) - 2.3) > 0.001:
		return "큰 몸: %s · 멈춘 자리 %s(큰 몸에서 2.3칸이어야)" % [why, poker.pos]
	return ""

# 같은 거리의 둘 가운데 _target_of는 배열 앞쪽, _nearest_enemy는 배열 뒤쪽을 고른다. 배열 앞쪽 몸을 남동쪽 버킷 칸에 두어 칸을 훑는 차례와 배열 차례가 거꾸로다
func test_target_ties_keep_array_order():
	var b = _battle()
	if not "scan_all" in b:
		return "Battle에 scan_all이 없다"
	var u0 = _unit(b, Vector2(10.5, 10.5))
	var u1 = _unit(b, Vector2(9.5, 9.5))
	for k in 20:  # 그 편의 몸을 BUCKET_MIN보다 많게, 든 칸 수를 훑을 칸 수(넷) 이상으로: 칸을 하나씩 찾는 갈래를 지난다
		_unit(b, Vector2(-10.0 + 2.0 * k, 30.0))
	var e = _foe(b, Vector2(10.0, 10.0))
	e.sight = 1.0
	var got = b._target_of(e)
	b.scan_all = true
	var want = b._target_of(e)
	b.scan_all = false
	if not is_same(got, u0) or not is_same(want, u0):
		return "_target_of: 버킷이 배열 앞쪽 유닛을 고름 %s · 전수가 고름 %s(둘 다 참이어야)" % [is_same(got, u0), is_same(want, u0)]
	b.units.clear()
	b.enemies.clear()
	var m = _unit(b, Vector2(10.0, 10.0))
	var e0 = _foe(b, Vector2(10.5, 10.5))
	var e1 = _foe(b, Vector2(9.5, 9.5))
	for k in 20:
		_foe(b, Vector2(-10.0 + 2.0 * k, 30.0))
	for foe in b.enemies:
		foe.lit = true
	got = b._nearest_enemy(m.pos, 1.0)
	b.scan_all = true
	want = b._nearest_enemy(m.pos, 1.0)
	b.scan_all = false
	if not is_same(got, e1) or not is_same(want, e1):
		return "_nearest_enemy: 버킷이 배열 뒤쪽 적을 고름 %s · 전수가 고름 %s(둘 다 참이어야) · 앞쪽 적을 고름 %s" % [is_same(got, e1), is_same(want, e1), is_same(got, e0)]
	return ""

# 먼저 물어 버킷을 담아 둔 뒤, 멀리 있던 몸을 물음 범위 안으로 들이는 다섯 가지 쓰기 바로 뒤에 후보가 전수 번호를 모두 담는다
func test_stale_after_outside_write():
	var b = _battle()
	if not (b.has_method("_units_near") and b.has_method("_foes_near")):
		return "Battle에 _units_near·_foes_near가 없다"
	var at := Vector2(10.0, 10.0)
	var us := []
	var es := []
	for k in 5:
		us.append(_unit(b, Vector2(30.0 + 2.0 * k, 30.0)))
		es.append(_foe(b, Vector2(30.0 + 2.0 * k, 34.0)))
	for k in 20:  # 먼 곳의 몸 스무 개씩: 그 편의 몸이 적으면(BUCKET_MIN 이하) 버킷을 거치지 않아 낡음을 잴 수 없다
		_unit(b, Vector2(20.0 + k, 38.0))
		_foe(b, Vector2(20.0 + k, 36.0))
	var bad := []
	var ask := func(what: String, want_u: Array, want_e: Array) -> void:
		var gu: Array = b._units_near(at, 1.0)
		var ge: Array = b._foes_near(at, 1.0)
		if _brute(b.units, at, 1.0) != want_u or _brute(b.enemies, at, 1.0) != want_e:
			bad.append("%s: 시험이 잘못 짜였다(전수 %s·%s, 기대 %s·%s)" % [what, _brute(b.units, at, 1.0), _brute(b.enemies, at, 1.0), want_u, want_e])
		var why := _covers(gu, want_u, b.units.size()) + _covers(ge, want_e, b.enemies.size())
		if why != "":
			bad.append("%s: %s" % [what, why])
	ask.call("처음", [], [])
	us[0].pos = Vector2(10.5, 10.0)  # ㉠ pos 대입
	es[0].pos = Vector2(9.5, 10.0)
	ask.call("㉠ pos 대입", [0], [0])
	us[1].pos.x = 10.0  # ㉡ 성분 쓰기: (10, 30)은 아직 멀다. y도 써서 들인다
	us[1].pos.y = 10.5
	es[1].pos.x = 10.0
	es[1].pos.y = 9.5
	ask.call("㉡ pos.x·pos.y 쓰기", [0, 1], [0, 1])
	us[2].set("pos", Vector2(10.0, 9.2))  # ㉢ set()
	es[2].set("pos", Vector2(10.0, 10.8))
	ask.call("㉢ set(\"pos\")", [0, 1, 2], [0, 1, 2])
	us[3].pos = Vector2(13.5, 10.0)  # ㉣ 닿지 않는 자리(2.5칸 밖 버킷 칸)에 두고 물은 뒤 반지름만 키운다
	es[3].pos = Vector2(6.5, 10.0)
	ask.call("㉣ 앞", [0, 1, 2], [0, 1, 2])
	us[3].radius = 3.0
	es[3].radius = 3.0
	ask.call("㉣ radius 대입", [0, 1, 2, 3], [0, 1, 2, 3])
	b.units.erase(us[4])  # ㉤ 하나를 빼고 새 몸을 넣는다(수가 같다)
	_unit(b, Vector2(10.0, 10.9))
	b.enemies.erase(es[4])
	_foe(b, Vector2(10.9, 10.0))
	ask.call("㉤ 빼고 새로 넣기", [0, 1, 2, 3, 24], [0, 1, 2, 3, 24])
	return " / ".join(bad)
