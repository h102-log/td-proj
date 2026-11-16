extends "res://tests/eval/gd/lib.gd"
# 규모 ①: 2칸 버킷(I305). 적이 노릴 유닛·아군이 고를 적·몸 막기가 그 편의 몸을 다 훑지 않고 후보만 보되, 결과는 다 훑은 것과 같다.
# lib.gd 머리의 계약에 더하는 API:
#   Battle.scan_all: bool — 참이면 버킷 없이 그 편의 몸을 모두 본다(옛 길). 동치 평가가 켠다
#   Battle.audit — [0, 0, 0, 0]을 넣으면 후보를 물을 때마다 전수와 견줘 [물은 횟수, 놓친 몸 수, 후보 수 합, 전체 수 합]을 센다. null이면 세지 않는다
#   Battle._target_of(적) · _nearest_enemy(자리, 거리, 홀드 기준, 홀드 반경, 성벽 위만, 몸 반지름) · _shove(몸, 옮길 거리, 상대 편 목록)
#   그 밖은 있는 API다: 시험 스테이지(main.gd stage()), start_raid·retreat(den.gd 머리), dash·cast·order_move·place_merc·spawn_enemy
# 저장 파일을 쓰지 않는다(평가용 파일을 함께 쓰는 묶음에 들지 않는다).
# 낡음을 재는 평가(EV1134)는 판 하나에서, 바꾼 뒤 다른 몸·판을 만들거나 움직이지 않고 곧바로 묻는다.
#   버킷이 낡았는지 아는 세대 수가 클래스에 하나라, 다른 판이 움직이면 이 판의 버킷도 다시 담겨 낡음이 가려진다

const TEAM := [{"kind": "aias", "cell": Vector2i(31, 65)}, {"kind": "ignis", "cell": Vector2i(33, 65)}, {"kind": "chronos", "cell": Vector2i(32, 65)}]
const MERCS := ["soldier", "shieldman", "spearman", "archer", "fire_mage", "cleric", "cavalry", "netter"]
const LONE := Vector2i(16, 72)  # 무리에서 떨어져 선 사제 칸. 낚아채기 하피를 이 칸에 내보낸다
const WEAK := Vector2i(44, 72)  # 체력 1인 병사 칸. 옆 칸에 기본 적을 내보낸다

func _api(b) -> String:
	return "" if b.get("scan_all") is bool and "audit" in b else "Battle에 scan_all·audit가 없다"

# 시험 스테이지(씨앗 7, 거점 체력 넉넉히, 배치 상한 40)에 영웅 셋(오토 켬)과 용병 32명을 놓고 2라운드 준비 단계로 넘긴 판
func _twin():
	var st: Dictionary = load("res://src/main.gd").stage()
	st.merge({"seed": 7, "gold": BIG, "base_hp": BIG, "merc_cap": 40, "heroes": TEAM}, true)
	var b = load("res://src/sim/battle.gd").new(st)
	for i in 30:  # 정문 앞 세 줄(67~69행, 27~36열)
		b.place_merc(MERCS[i % MERCS.size()], Vector2i(27 + i % 10, 67 + i / 10))
	b.place_merc("cleric", LONE, {"hp": float(BIG)})
	b.place_merc("soldier", WEAK, {"hp": 1.0})
	for h in b.heroes:
		for slot in h.auto:
			h.auto[slot] = true
	b.state = "cleared"
	b.next_round()
	return b

# 두 판에 같은 스텝에 넣는 명령. 넉백으로 자리가 바뀐 적이 있었으면 참
func _command(b, t: int) -> bool:
	var aias = b.heroes[0]
	var ignis = b.heroes[1]
	var chronos = b.heroes[2]
	var mercs: Array = b.units.filter(func(u): return not u.is_hero)
	match t:
		0:
			b.start_raid()
		40:
			b.retreat()
		41:
			b.start_battle()
		60:
			b.spawn_enemy("slime_king", Vector2i(32, 76))
			b.spawn_enemy("big_slime", Vector2i(29, 71), {"hp": 1.0})
			b.spawn_enemy("big_slime", Vector2i(35, 71), {"hp": 1.0})
			b.spawn_enemy("leap_wolf", Vector2i(24, 72))
			b.spawn_enemy("leap_wolf", Vector2i(40, 72))
			b.spawn_enemy("ram", Vector2i(32, 73))
			b.spawn_enemy("snatch_harpy", LONE, {"hp": float(BIG)})
			b.spawn_enemy("chain_orc", Vector2i(26, 73))
			b.spawn_enemy("ogre_thrower", Vector2i(38, 74))
			b.spawn_enemy("basic", WEAK + Vector2i(0, 1), {"hp": float(BIG), "damage": 50.0})
		100:
			b.order_move(mercs.slice(0, 12), Vector2i(34, 72), true)
		120:
			b.dash([ignis], ignis.pos + Vector2(0, 3))
		140:  # 요새화한 아이아스 바로 앞에 서 있는 적을 내보내고 Q를 쓴다(밀쳐 냄)
			var e = b.spawn_enemy("basic", Vector2i(aias.pos.round()) + Vector2i(0, 1), {"hp": float(BIG), "speed": 0.0, "damage": 0.0})
			var at: Vector2 = e.pos
			aias.cd.q = 0.0
			b.cast(aias, "q", aias.pos + Vector2(0, 2))
			return e.pos != at
		160:
			chronos.cd.e = 0.0
			b.cast(chronos, "e", chronos.pos + Vector2(0, 3))
		220:
			b.order_move(mercs, Vector2i(30, 70), false)
	return false

# 판의 모습: 판 단계·골드·거점 체력과 유닛 목록·적 목록(차례대로 종류·자리·체력·성벽 위, 적은 붙잡은 유닛의 번호도)
func _sig(b) -> Array:
	var out := [b.state, b.gold, b.base.hp]
	for u in b.units:
		out.append([u.kind, u.pos, u.hp, u.on_wall])
	for e in b.enemies:
		out.append([e.kind, e.pos, e.hp, e.on_wall, b.units.find(e.engaged)])
	return out

# EV1133 · I305: 버킷으로 고른 판은 모든 몸을 본 판(scan_all)과 스텝마다 같다. 후보는 닿을 수 있는 몸을 하나도 놓치지 않는다
func ev1133():
	var a = _twin()
	var b = _twin()
	var out := _api(b)
	if out != "":
		return out
	a.scan_all = true
	b.audit = [0, 0, 0, 0]
	var seen := {"dash": 0, "split": 0, "foe_down": 0, "merc_down": 0, "lift": 0, "knock": 0}
	for t in 400:
		_command(a, t)
		if _command(b, t):
			seen.knock += 1
		a.step(DT)
		b.step(DT)
		var sa := _sig(a)
		var sb := _sig(b)
		if sa != sb:
			var i := 0
			while i < mini(sa.size(), sb.size()) and sa[i] == sb[i]:
				i += 1
			return "스텝 %d에서 두 판이 갈렸다: 칸 %d · 모두 본 판 %s · 버킷 판 %s(칸 수 %d·%d)" % [t, i, sa[i] if i < sa.size() else null, sb[i] if i < sb.size() else null, sa.size(), sb.size()]
		if b.heroes.any(func(h): return h.dash_cd > 0.0):
			seen.dash += 1
		if b.enemies.any(func(e): return e.kind == "slime" and e.split_from != null):
			seen.split += 1
		if b.fallen.any(func(f): return f.who.get("is_hero") == null):
			seen.foe_down += 1
		if b.fallen.any(func(f): return f.who.get("is_hero") == false):
			seen.merc_down += 1
		if b.units.any(func(u): return b._fx_on(u, "lift") != null):
			seen.lift += 1
	var idle: Array = seen.keys().filter(func(k): return seen[k] == 0)
	return check(b.audit[0] > 0 and b.audit[1] == 0 and idle.is_empty(),
		"후보를 물은 횟수 %d(0보다 커야) · 놓친 몸 수 %d(0) · 한 번도 없었던 일 %s · 있었던 스텝 수 %s" % [b.audit[0], b.audit[1], idle, seen])

# 적이 나오지 않는 전투 단계의 판(영웅 없음). 용병은 준비 단계에 놓고 넘긴다.
# 물음이 닿지 않는 먼 줄(1행·18행)에 움직이지 않는 병사 스무 명과 적 스무 마리를 함께 둔다: 그 편의 몸이 16 이하면 버킷을 거치지 않아 낡음을 잴 수 없다
func _still(cells: Array):
	var b = battle({"base_hp": BIG, "waves": [[]], "merc_cap": 40})
	var ms: Array = cells.map(func(c): return b.place_merc("soldier", c, {"speed": 0.0, "damage": 0.0}))
	for i in 20:
		b.place_merc("soldier", Vector2i(5 + i, 1), {"speed": 0.0, "damage": 0.0})
	b.start_battle()
	for i in 20:
		_foe(b, Vector2i(5 + i, 18))
	return [b] + ms

func _foe(b, cell: Vector2i, over := {}):
	return b.spawn_enemy("basic", cell, {"speed": 0.0, "damage": 0.0, "hp": float(BIG)}.merged(over, true))

# EV1134 · I305: 스텝 밖에서 자리·몸 반지름·목록을 바꾸면 다음 물음이 바로 새 자리를 본다(먼저 물어 버킷을 담아 둔 뒤 바꾸고 곧바로 묻는다)
func ev1134():
	var bad := []
	# ① 멀리 있던 병사를 pos를 넣어 적 옆으로
	var s1: Array = _still([Vector2i(20, 10)])
	var b = s1[0]
	if _api(b) != "":
		return _api(b)
	var m = s1[1]
	var e = _foe(b, Vector2i(10, 10), {"sight": 3.0})
	var was = b._target_of(e)
	m.pos = Vector2(11, 10)
	var now = b._target_of(e)
	b.scan_all = true
	var full = b._target_of(e)
	if is_same(was, m) or not is_same(now, m) or not is_same(full, m):
		bad.append("① 옮기기 전 대상이 병사 %s(거짓) · 옮긴 뒤 %s(참) · 모두 본 답 %s(참)" % [is_same(was, m), is_same(now, m), is_same(full, m)])
	# ② 가까운 적을 목록에서 빼기
	var s2: Array = _still([Vector2i(10, 10)])
	b = s2[0]
	m = s2[1]
	var near_e = _foe(b, Vector2i(11, 10))
	var far_e = _foe(b, Vector2i(13, 10))
	was = b._nearest_enemy(m.pos, 5.0)
	b.enemies.erase(near_e)
	now = b._nearest_enemy(m.pos, 5.0)
	b.scan_all = true
	full = b._nearest_enemy(m.pos, 5.0)
	if not is_same(was, near_e) or not is_same(now, far_e) or not is_same(full, far_e):
		bad.append("② 빼기 전 가까운 적 %s(참) · 뺀 뒤 먼 적 %s(참) · 모두 본 답 %s(참)" % [is_same(was, near_e), is_same(now, far_e), is_same(full, far_e)])
	# ③ 닿지 않던 적의 몸 반지름을 키우기. 적의 버킷 칸(x 12~14)은 병사 둘레를 훑는 칸(x 8~12) 밖이다
	var s3: Array = _still([Vector2i(10, 10)])
	b = s3[0]
	m = s3[1]
	e = _foe(b, Vector2i(12, 10))
	e.pos = Vector2(12.5, 10)
	was = b._nearest_enemy(m.pos, 1.2, Vector2.ZERO, INF, false, m.radius)
	e.radius = 3.0
	now = b._nearest_enemy(m.pos, 1.2, Vector2.ZERO, INF, false, m.radius)
	b.scan_all = true
	full = b._nearest_enemy(m.pos, 1.2, Vector2.ZERO, INF, false, m.radius)
	if was != null or not is_same(now, e) or not is_same(full, e):
		bad.append("③ 키우기 전 %s(null) · 키운 뒤 그 적 %s(참) · 모두 본 답 %s(참)" % [was, is_same(now, e), is_same(full, e)])
	# ④ 멀리 있던 적을 pos를 넣어 병사가 갈 자리로
	var s4: Array = _still([Vector2i(10, 10)])
	b = s4[0]
	m = s4[1]
	e = _foe(b, Vector2i(10, 15))
	b._shove(m, Vector2(1, 0), b.enemies)
	var free: Vector2 = m.pos
	m.pos = Vector2(10, 10)
	e.pos = Vector2(11, 10)
	b._shove(m, Vector2(1, 0), b.enemies)
	var stopped: Vector2 = m.pos
	m.pos = Vector2(10, 10)
	b.scan_all = true
	b._shove(m, Vector2(1, 0), b.enemies)
	var apart: float = stopped.distance_to(e.pos)
	if not free.is_equal_approx(Vector2(11, 10)) or absf(apart - (m.radius + e.radius)) > 0.001 or m.pos != stopped:
		bad.append("④ 적이 멀 때 밀린 자리 %s((11, 10)) · 적을 옮긴 뒤 멈춘 자리 %s(적과 %.3f칸, 기대 %.3f) · 모두 본 자리 %s(같아야)" % [free, stopped, apart, m.radius + e.radius, m.pos])
	return check(bad.is_empty(), " / ".join(bad))

# EV1135 · I305: 서 있는 병사 60·적 120의 판에서 후보가 닿을 몸을 놓치지 않고, 본 몸 수가 전수의 0.15 이하다
func ev1135():
	var b = battle({"size": Vector2i(64, 24), "merc_cap": 60, "base_hp": BIG, "waves": [[]]})
	var out := _api(b)
	if out != "":
		return out
	var placed := 0
	for i in 60:
		if b.place_merc("soldier", Vector2i(2 + i, 8), {"speed": 0.0, "damage": 0.0}) != null:
			placed += 1
	b.start_battle()
	for i in 120:
		_foe(b, Vector2i(2 + i % 60, 12 + 2 * (i / 60)))
	b.audit = [0, 0, 0, 0]
	for i in 10:
		b.step(DT)
	var ratio: float = float(b.audit[2]) / maxf(float(b.audit[3]), 1.0)
	return check(placed == 60 and b.enemies.size() == 120 and b.state == "battle" and b.audit[0] > 0 and b.audit[1] == 0 and ratio <= 0.15,
		"놓인 병사 %d(60) · 적 %d(120) · 판 단계 %s · 물은 횟수 %d(0보다 커야) · 놓친 몸 수 %d(0) · 후보 수 합 ÷ 전체 수 합 %.3f(0.15 이하)" % [placed, b.enemies.size(), b.state, b.audit[0], b.audit[1], ratio])
