extends "res://tests/eval/gd/lib.gd"
# 2라운드 늑대 PR ①: 무리 출현(S238·I190), 도약 늑대(S239·I191), 아군 기절(I192). lib.gd·kits.gd 머리의 계약에 더하는 API:
#   적 kind "wolf"(늑대) · "leap_wolf"(도약 늑대) · 적 on_wall·fx·goal · stage 키 spawn_gap(출현 간격)·spawn_spread(출현 퍼짐, I177)·castle
#   Battle.spawn_counts(라운드, 웨이브) · Battle.effect(대상, 키) · Battle.cast(영웅, 칸, aim) · 용병 on_wall·anchor · 영웅 mana·max_mana·cd
# wolf-3(S242·S243·I195): 적 kind "alpha_wolf" · 적 cast {id "pounce", who 대상} · 붙잡힘 효과 키 "pin" · Battle.damage(대상, 양, "magic")

const SPAWNS := [Vector2i(0, 5), Vector2i(0, 10), Vector2i(0, 15)]
const WALL := Vector2i(12, 9)  # 도약 늑대가 뛰어오르는 성벽 칸
const BELOW := Vector2i(12, 10)  # 그 바로 앞 들판 칸
const NONE := [{"kind": "basic", "count": 0}]  # 적이 나오지 않는 웨이브

# 출현 신호마다 [나온 스텝의 시작 시각, 종류, 나온 칸]을 모은다. t[0]은 _steps가 센다
func _watch(b, log: Array, t: Array) -> void:
	b.enemy_spawned.connect(func(e): log.append([t[0], e.kind, Vector2i(e.pos.round())]))

func _steps(b, t: Array, secs: float, kill := false) -> void:
	var end: float = t[0] + secs
	while t[0] < end - 0.001:
		b.step(DT)
		t[0] += DT
		if kill:
			kill_all(b)

# 같은 스텝에 나온 적끼리 묶는다: [시각, 수, 칸 목록]
func _groups(log: Array) -> Array:
	var out := []
	for x in log:
		if out.is_empty() or out[-1][0] != x[0]:
			out.append([x[0], 0, []])
		out[-1][1] += 1
		out[-1][2].append(x[2])
	return out

# 성곽 판: 9행 x 1~29는 성곽 성벽(skip 칸은 땅), (0,9)는 닫힌 성문, 거점은 (12,2)
func _castle(skip := [], over := {}):
	var walls := []
	for x in range(1, 30):
		if Vector2i(x, 9) not in skip:
			walls.append(Vector2i(x, 9))
	var stage := {"base": Vector2i(12, 2), "spawns": [Vector2i(12, 19)], "village": Rect2i(0, 0, 30, 9), "base_hp": BIG,
		"castle": {"walls": walls, "gates": [Vector2i(0, 9)], "wall_hp": 300, "gate_hp": 150}}
	stage.merge(over, true)
	return battle(stage)

# 성벽 위 p에 선 용병(병사, 체력 큼, 공격력 0)
func _merc_on(b, p: Vector2):
	var m = b.place_merc("soldier", Vector2i(12, 5), {"hp": BIG, "damage": 0})
	m.pos = p
	m.anchor = p
	m.on_wall = true
	return m

func _leap(b, cell := BELOW, over := {}):
	return b.spawn_enemy("leap_wolf", cell, {"hp": BIG}.merged(over, true))

func _stunned(b, x) -> bool:
	return b.effect(x, "stun") != null

func _intact(b) -> bool:
	return b.castle.values().all(func(k): return k.hp == k.max_hp)

# EV543 · S238: 무리(pack 4)는 넷이 같은 순간 한 출현 지점에서 나오고, 다음 무리는 간격 × 4 뒤 다음 출현 지점에서 나온다
func ev543():
	var b = battle({"spawns": SPAWNS, "spawn_gap": 1.0, "waves": [[{"kind": "wolf", "count": 8}]]})
	if not b.ENEMY_KINDS.has("wolf"):
		return "적 종류 wolf가 없다"
	var log := []
	var t := [0.0]
	_watch(b, log, t)
	b.start_battle()
	_steps(b, t, DT)
	var first := log.size()
	var home := log.all(func(x): return x[2] == SPAWNS[0])
	_steps(b, t, 3.9 - t[0])
	var mid := log.size()
	_steps(b, t, 4.1 - t[0])
	var next := log.slice(4)
	return check(first == 4 and home and mid == 4 and log.size() == 8 and next.all(func(x): return x[2] == SPAWNS[1]),
		"나온 수: 시작 %d · 3.9초 %d · 4.1초 %d(4·4·8이어야 한다) · 칸 %s" % [first, mid, log.size(), log.map(func(x): return x[2])])

# EV544 · S238: 무리 크기·간격·출현 지점 차례. 나머지는 작은 무리로 마지막에, 무리 없는 종류는 한 마리씩. 미리보기 수는 실제와 같다
func ev544():
	var b = battle({"spawns": SPAWNS, "spawn_gap": 1.0, "waves": [[{"kind": "wolf", "count": 10}, {"kind": "basic", "count": 2}]]})
	if not b.ENEMY_KINDS.has("wolf"):
		return "적 종류 wolf가 없다"
	var plan: Array = b.spawn_counts(0, 0)
	var log := []
	var t := [0.0]
	_watch(b, log, t)
	b.start_battle()
	_steps(b, t, 13.0, true)
	var g := _groups(log)
	var real := SPAWNS.map(func(_s): return {})
	for x in log:
		var i := SPAWNS.find(x[2])
		if i < 0:
			return "출현 지점이 아닌 칸 %s에서 나왔다" % x[2]
		real[i][x[1]] = real[i].get(x[1], 0) + 1
	var want_t := [0.0, 4.0, 8.0, 10.0, 11.0]
	var times := g.map(func(x): return x[0])
	var on_time: bool = times.size() == 5 and range(5).all(func(i): return absf(times[i] - want_t[i]) <= 0.06)
	return check(g.map(func(x): return x[1]) == [4, 4, 2, 1, 1] and on_time
		and g.map(func(x): return x[2][0]) == [SPAWNS[0], SPAWNS[1], SPAWNS[2], SPAWNS[0], SPAWNS[1]] and plan == real,
		"[시각, 수, 칸] %s · 미리보기 %s · 실제 %s" % [g.map(func(x): return [snappedf(x[0], 0.01), x[1], x[2][0]]), plan, real])

# EV545 · I190: 무리는 이어진 칸에서 나온다. 첫 칸은 무리 차례로 센 황금비 칸을 퍼짐 구역·맵 안으로 당긴 칸이다. 퍼짐이 없으면 모두 출현 지점 칸
func ev545():
	var sp := [Vector2i(1, 19), Vector2i(15, 19), Vector2i(28, 19)]
	var b = battle({"spawns": sp, "spawn_gap": 0.25, "spawn_spread": 3, "waves": [[{"kind": "wolf", "count": 24}]]})
	if not b.ENEMY_KINDS.has("wolf"):
		return "적 종류 wolf가 없다"
	var log := []
	var t := [0.0]
	_watch(b, log, t)
	b.start_battle()
	_steps(b, t, 8.0, true)
	var g := _groups(log)
	if g.size() != 6:
		return "무리 %d개가 나왔다(6개여야 한다): %s" % [g.size(), g.map(func(x): return x[2])]
	for i in 6:
		var s: Vector2i = sp[i % 3]
		var k := i / 3
		var x0 := maxi(0, mini(mini(s.x - 3 + int(fposmod(k * 0.6180339887, 1.0) * 7), s.x), 26))
		var want := range(4).map(func(j): return Vector2i(x0 + j, 19))
		if g[i][2] != want:
			return "%d번째 무리(출현 지점 %s, k %d)의 칸 %s(%s여야 한다)" % [i, s, k, g[i][2], want]
	var b2 = battle({"spawns": sp, "spawn_gap": 0.25, "waves": [[{"kind": "wolf", "count": 4}]]})
	var log2 := []
	var t2 := [0.0]
	_watch(b2, log2, t2)
	b2.start_battle()
	_steps(b2, t2, DT)
	return check(log2.size() == 4 and log2.all(func(x): return x[2] == sp[0]), "퍼짐 없는 판의 무리 칸 %s" % [log2.map(func(x): return x[2])])

# EV546 · S239: 도약 늑대는 성벽 앞에서 0.8초 웅크린 뒤 그 성벽 칸 위로 뛰어오른다
func ev546():
	var b = _castle()
	if not b.ENEMY_KINDS.has("leap_wolf"):
		return "적 종류 leap_wolf가 없다"
	var w = _leap(b, BELOW, {"sight": 0})
	if run(b, 0.7, func(): return w.on_wall):
		return "0.7초 안에 성벽 위에 섰다"
	return check(run(b, 0.5, func(): return w.on_wall) and cell_of(w) == WALL, "1.2초가 지나도 성벽 칸 (12,9) 위에 서지 않았다(%s, on_wall %s)" % [w.pos, w.on_wall])

# EV547 · S239·I191: 뛰어오른 칸 한가운데의 성벽 위 아군은 동쪽 이웃 칸으로 밀리고 0.5초 기절한다
func ev547():
	var b = _castle()
	if not b.ENEMY_KINDS.has("leap_wolf"):
		return "적 종류 leap_wolf가 없다"
	var m = _merc_on(b, Vector2(WALL))
	var w = _leap(b)
	if not run(b, 2.0, func(): return w.on_wall):
		return "도약 늑대가 2초 안에 성벽 위에 서지 않았다"
	var at: Vector2 = m.pos
	if at.distance_to(Vector2(13, 9)) > 0.05 or not _stunned(b, m):
		return "늑대가 선 스텝에 용병 자리 %s((13,9)여야 한다) · 기절 %s" % [at, _stunned(b, m)]
	run(b, 0.45)
	if not _stunned(b, m) or m.pos.distance_to(at) > 0.01:
		return "0.45초 뒤 기절 %s(걸려 있어야 한다) · 자리 %s(%s여야 한다)" % [_stunned(b, m), m.pos, at]
	run(b, 0.15)
	return check(not _stunned(b, m), "0.6초 뒤에도 기절이 남아 있다")

# 성곽 판(skip 칸은 땅)에서 성벽 위 p에 선 용병이 도약 늑대에 밀려난 자리와 기절
func _shoved(skip: Array, p: Vector2) -> Array:
	var b = _castle(skip)
	var m = _merc_on(b, p)
	var w = _leap(b)
	if not run(b, 2.0, func(): return w.on_wall):
		return [null, false]
	return [m.pos, _stunned(b, m)]

# EV548 · I191: 밀려나는 쪽은 아군이 치우친 쪽(가운데면 동쪽)이고, 그쪽이 성벽 위를 걸을 수 없는 칸이면 반대쪽, 둘 다 그러면 제자리
func ev548():
	if not battle().ENEMY_KINDS.has("leap_wolf"):
		return "적 종류 leap_wolf가 없다"
	var cases := [
		[[Vector2i(13, 9)], Vector2(WALL), Vector2(11, 9)],
		[[Vector2i(11, 9), Vector2i(13, 9)], Vector2(WALL), Vector2(WALL)],
		[[], Vector2(12.3, 9), Vector2(13, 9)],
		[[], Vector2(11.7, 9), Vector2(11, 9)],
	]
	for c in cases:
		var got := _shoved(c[0], c[1])
		if got[0] == null or got[0].distance_to(c[2]) > 0.05 or not got[1]:
			return "땅 칸 %s · 용병 %s에서 밀린 자리 %s(%s여야 한다) · 기절 %s" % [c[0], c[1], got[0], c[2], got[1]]
	return ""

# EV549 · S239: 기절을 막는 시간이 없다. 둘째 도약 늑대가 오르면 같은 아군이 다시 기절하고 또 밀린다
func ev549():
	var b = _castle()
	if not b.ENEMY_KINDS.has("leap_wolf"):
		return "적 종류 leap_wolf가 없다"
	var m = _merc_on(b, Vector2(WALL))
	var w1 = _leap(b)
	if not run(b, 2.0, func(): return w1.on_wall):
		return "첫 도약 늑대가 2초 안에 성벽 위에 서지 않았다"
	run(b, 0.6)
	b.damage(w1, BIG)
	if _stunned(b, m):
		return "첫 기절이 0.6초 뒤에도 남아 있다"
	m.pos = Vector2(13, 9)
	m.anchor = m.pos
	b.stop([m])
	var w2 = _leap(b, Vector2i(13, 10))
	if not run(b, 2.0, func(): return w2.on_wall):
		return "둘째 도약 늑대가 2초 안에 성벽 위에 서지 않았다"
	return check(_stunned(b, m) and m.pos.distance_to(Vector2(14, 9)) <= 0.05, "둘째 늑대가 선 스텝에 기절 %s · 자리 %s((14,9)여야 한다)" % [_stunned(b, m), m.pos])

# EV550 · S239: 뛴 뒤 3초 동안 이동 속도가 0.5배(둔화 0.5)다
func ev550():
	var b = _castle()
	if not b.ENEMY_KINDS.has("leap_wolf"):
		return "적 종류 leap_wolf가 없다"
	var w = _leap(b, BELOW, {"sight": 0})
	if not run(b, 2.0, func(): return w.on_wall):
		return "도약 늑대가 2초 안에 성벽 위에 서지 않았다"
	var p0: Vector2 = w.pos
	var slowed := true
	for i in 20:
		b.step(DT)
		var v = b.effect(w, "slow")
		slowed = slowed and v != null and is_equal_approx(v, 0.5)
	var d: float = w.pos.distance_to(p0)
	if not slowed or absf(d - 1.5) > 0.1:
		return "선 뒤 1초에 %s칸(1.5여야 한다) · 둔화 0.5가 늘 걸려 있었나 %s" % [d, slowed]
	run(b, 2.1)
	return check(b.effect(w, "slow") == null, "선 때부터 3.1초 뒤에도 둔화 %s가 남아 있다" % b.effect(w, "slow"))

# EV551 · S239·S155: 봉인된 도약 늑대는 뛰지 못한다
func ev551():
	var b = _castle()
	if not b.ENEMY_KINDS.has("leap_wolf"):
		return "적 종류 leap_wolf가 없다"
	var w = _leap(b, BELOW, {"sight": 0})
	w.fx["test"] = {"seal": true, "left": 5.0}
	return check(not run(b, 2.0, func(): return w.on_wall), "봉인된 도약 늑대가 2초 안에 성벽 위에 섰다")

# EV552 · I191: 한 번 뛰어오른 도약 늑대는 성벽에서 내려온 뒤 다시 오르지 않고 성곽을 부순다
func ev552():
	var b = _castle()
	if not b.ENEMY_KINDS.has("leap_wolf"):
		return "적 종류 leap_wolf가 없다"
	var w = _leap(b, BELOW, {"sight": 0})
	if not run(b, 2.0, func(): return w.on_wall):
		return "도약 늑대가 2초 안에 성벽 위에 서지 않았다"
	w.pos = Vector2(12, 12)
	w.goal = Vector2i(-1, -1)  # 대상이 바뀐 것으로 쳐서 길을 새로 찾게 한다
	b.step(DT)  # 성벽 위인지는 다음 걸음에 본다(I76)
	if run(b, 3.0, func(): return w.on_wall):
		return "들판으로 옮긴 뒤 3초 안에 다시 성벽 위에 섰다(%s)" % w.pos
	return check(run(b, 10.0, func(): return not _intact(b)), "10초가 지나도 성곽이 깎이지 않았다(늑대 %s)" % w.pos)

# EV553 · I192: 기절한 아군은 치지도 움직이지도 않고, 기절 동안 받은 이동 명령은 풀린 뒤 따른다
func ev553():
	var b = battle()
	var m = b.place_merc("soldier", Vector2i(10, 10), {"damage": 5})
	var foe = b.spawn_enemy("basic", Vector2i(11, 10), {"speed": 0, "sight": 0, "damage": 0, "hp": BIG})
	m.fx["test"] = {"stun": true, "left": 1.0}
	var p0: Vector2 = m.pos
	var hp0: float = foe.hp
	for i in 10:  # 0.5초. run은 시각을 더해 세다 보면 스텝이 하나 더 돌 수 있어 스텝 수로 센다
		b.step(DT)
	if foe.hp != hp0:
		return "기절한 용병이 0.5초 안에 적을 쳤다(체력 %s → %s)" % [hp0, foe.hp]
	b.order_move([m], Vector2i(5, 10))
	for i in 9:  # 0.95초까지
		b.step(DT)
	if m.pos.distance_to(p0) > 0.01:
		return "기절한 용병이 0.95초 안에 %s에서 %s로 움직였다" % [p0, m.pos]
	return check(run(b, 3.0, func(): return m.pos.x < 9.0), "기절이 풀린 뒤 3초가 지나도 이동 명령을 따르지 않았다(%s)" % m.pos)

# 세라피나 한 명이 든 판. 영웅은 최대 레벨이다(I115). 시간은 흐르지 않는다
func _with_seraphina(cell: Vector2i, over := {}):
	var stage := {"heroes": [{"kind": "seraphina", "cell": cell}], "base_hp": BIG, "waves": [NONE, NONE], "seed": 11}
	stage.merge(over, true)
	return battle(stage)

# EV554 · I192: 기절한 영웅은 스킬을 쓰지 못하고 마나·대기 시간이 들지 않는다. 풀리면 쓴다
func ev554():
	var b = _with_seraphina(Vector2i(10, 4))
	var h = b.hero
	h.damage = 0.0
	b.spawn_enemy("basic", Vector2i(0, 19), {"speed": 0, "sight": 0, "damage": 0, "hp": BIG})
	b.start_battle()
	h.mana = h.max_mana
	h.fx["test"] = {"stun": true, "left": 1.0}
	var mana0: float = h.mana
	var cd0: float = h.cd.w
	if b.cast(h, "w", Vector2(10, 6)) or h.mana != mana0 or h.cd.w != cd0:
		return "기절한 영웅의 W: 마나 %s → %s · 대기 %s → %s(쓰이지 않아야 한다)" % [mana0, h.mana, cd0, h.cd.w]
	run(b, 1.1)
	h.mana = h.max_mana
	return check(b.cast(h, "w", Vector2(10, 6)), "기절이 풀린 뒤에도 W를 쓰지 못했다")

# EV555 · I192·S152: 도약 늑대가 건 기절도 해로운 효과라 정화(세라피나 W)로 지워진다
func ev555():
	var walls := []
	for x in range(1, 30):
		walls.append(Vector2i(x, 9))
	var b = _with_seraphina(Vector2i(13, 7), {"base": Vector2i(12, 2), "spawns": [Vector2i(12, 19)], "village": Rect2i(0, 0, 30, 9),
		"castle": {"walls": walls, "gates": [Vector2i(0, 9)], "wall_hp": 300, "gate_hp": 150}})
	if not b.ENEMY_KINDS.has("leap_wolf"):
		return "적 종류 leap_wolf가 없다"
	var h = b.hero
	h.damage = 0.0
	var m = _merc_on(b, Vector2(WALL))
	var w = _leap(b)
	b.start_battle()
	if not run(b, 2.0, func(): return w.on_wall):
		return "도약 늑대가 2초 안에 성벽 위에 서지 않았다"
	if not _stunned(b, m):
		return "도약 늑대가 선 스텝에 용병이 기절하지 않았다"
	h.mana = h.max_mana
	if not b.cast(h, "w", m.pos):
		return "세라피나가 W를 쓰지 못했다"
	b.step(DT)
	return check(not _stunned(b, m), "W를 쓴 다음 스텝에도 용병이 기절해 있다")

# ── 밤 늑대(S240·I193) ──

func _has_night(b) -> bool:
	return b.ENEMY_KINDS.has("night_wolf")

# 어둠을 d로 고정하고(스텝 끝에만 바뀐다) 거점 쪽으로 곧게 걷는 밤 늑대가 1초에 간 거리
func _night_walk(d: float, sealed := false) -> float:
	var b = battle()
	var w = b.spawn_enemy("night_wolf", Vector2i(5, 10), {"hp": BIG, "sight": 0})
	if sealed:
		w.fx["test"] = {"seal": true, "left": 5.0}
	var p0: Vector2 = w.pos
	for i in 20:
		b.dark = d
		b.step(DT)
	return w.pos.distance_to(p0)

func _bleed_of(x):  # 걸린 출혈 효과(없으면 null)
	for v in x.fx.values():
		if v.has("bleed"):
			return v
	return null

func _clear_bleed(x) -> void:
	for k in x.fx.keys():
		if x.fx[k].has("bleed"):
			x.fx.erase(k)

# 용병(10,10) 옆 (11,10)에 서 있는 밤 늑대
func _bite_board(over := {}):
	var b = battle()
	var m = b.place_merc("soldier", Vector2i(10, 10), {"hp": BIG, "damage": 0})
	m.armor = 0.0
	var w = b.spawn_enemy("night_wolf", Vector2i(11, 10), {"hp": BIG, "speed": 0}.merged(over, true))
	return [b, m, w]

# EV557 · S240: 이동 속도 × (1 + 0.6 × 어둠)
func ev557():
	if not _has_night(battle()):
		return "적 종류 night_wolf가 없다"
	var got := [0.0, 0.5, 1.0].map(func(d): return _night_walk(d))
	var want := [2.8, 3.64, 4.48]
	return check(range(3).all(func(i): return absf(got[i] - want[i]) <= 0.05), "어둠 0·0.5·1에서 1초에 %s칸(%s여야 한다)" % [got, want])

# EV558 · S240: 공격 속도 × (1 + 0.6 × 어둠). 문 횟수는 체력이 준 스텝 수(출혈은 스텝마다 지운다)
func _bites(d: float) -> int:
	var got = _bite_board()
	var b = got[0]
	var m = got[1]
	var n := 0
	for i in 118:  # 5.9초
		var hp0: float = m.hp
		b.dark = d
		b.step(DT)
		_clear_bleed(m)
		if m.hp < hp0:
			n += 1
	return n

func ev558():
	if not _has_night(battle()):
		return "적 종류 night_wolf가 없다"
	var day := _bites(0.0)
	var night := _bites(1.0)
	return check(day == 6 and night == 10, "5.9초 동안 문 횟수: 어둠 0 %d(6) · 어둠 1 %d(10)" % [day, night])

# EV559 · S240·I193: 출혈은 4초 동안 초당 2의 물리 피해(방어력 0이면 그대로)
func ev559():
	if not _has_night(battle()):
		return "적 종류 night_wolf가 없다"
	var got = _bite_board()
	var b = got[0]
	var m = got[1]
	if not run(b, 1.0, func(): return m.hp < BIG):
		return "밤 늑대가 1초 안에 물지 않았다"
	b.damage(got[2], BIG)
	if _bleed_of(m) == null:
		return "물린 용병에게 출혈이 없다"
	var hp1: float = m.hp
	for i in 40:
		b.step(DT)
	var lost: float = hp1 - m.hp
	if absf(lost - 4.0) > 0.15:
		return "출혈 2초에 체력이 %s 줄었다(4여야 한다)" % lost
	for i in 42:
		b.step(DT)
	return check(_bleed_of(m) == null, "문 때부터 4.1초 뒤에도 출혈이 남아 있다")

# EV560 · S240: 다시 물면 남은 시간이 새로 되고, 둘이 물어도 출혈은 하나
func ev560():
	if not _has_night(battle()):
		return "적 종류 night_wolf가 없다"
	var got = _bite_board({"attack_gap": 2.0})
	var b = got[0]
	var m = got[1]
	var w = got[2]
	if not run(b, 1.0, func(): return m.hp < BIG):
		return "밤 늑대가 1초 안에 물지 않았다"
	var cd: float = w.cooldown
	var again := false
	for i in 60:
		b.step(DT)
		if w.cooldown > cd:
			again = true
			break
		cd = w.cooldown
	var v = _bleed_of(m)
	if not again or v == null or absf(v.left - 4.0) > 0.06:
		return "두 번째로 문 스텝에 출혈 남은 시간 %s(4여야 한다) · 다시 물었나 %s" % [v.left if v else null, again]
	var two = _bite_board()  # 블록 자리(S159)가 하나라 첫 늑대가 문 뒤 처치하고 둘째가 문다
	var b2 = two[0]
	var m2 = two[1]
	if not run(b2, 1.0, func(): return _bleed_of(m2) != null):
		return "첫 밤 늑대가 1초 안에 물지 않았다"
	b2.damage(two[2], BIG)
	var w2 = b2.spawn_enemy("night_wolf", Vector2i(9, 10), {"hp": BIG, "speed": 0})
	run(b2, 0.2)
	var n: int = m2.fx.values().filter(func(v): return v.has("bleed")).size()
	return check(w2.target == m2 and n == 1 and is_equal_approx(b2.effect_sum(m2, "bleed"), 2.0),
		"둘째 밤 늑대가 물었나 %s · 출혈 %d개(1) · 합 %s(2)" % [w2.target == m2, n, b2.effect_sum(m2, "bleed")])

# EV561 · S240·S152: 출혈은 해로운 효과라 정화(세라피나 W)로 풀린다
func ev561():
	var b = _with_seraphina(Vector2i(10, 4))
	if not _has_night(b):
		return "적 종류 night_wolf가 없다"
	var h = b.hero
	h.damage = 0.0
	var m = b.place_merc("soldier", Vector2i(10, 7), {"hp": BIG, "damage": 0})
	var w = b.spawn_enemy("night_wolf", Vector2i(11, 7), {"hp": BIG, "speed": 0})
	b.spawn_enemy("basic", Vector2i(0, 19), {"speed": 0, "sight": 0, "damage": 0, "hp": BIG})  # 늑대를 처치해도 웨이브가 끝나지 않게(끝나면 효과가 모두 지워진다, I143)
	b.start_battle()
	if not run(b, 1.0, func(): return _bleed_of(m) != null):
		return "밤 늑대가 1초 안에 물어 출혈을 걸지 않았다"
	b.damage(w, BIG)
	h.mana = h.max_mana
	if not b.cast(h, "w", m.pos):
		return "세라피나가 W를 쓰지 못했다"
	b.step(DT)
	return check(_bleed_of(m) == null, "W를 쓴 다음 스텝에도 출혈이 남아 있다")

# EV562 · S240: 구조물에는 출혈을 걸지 않는다(유닛에는 건다)
func ev562():
	var b = battle()
	if not _has_night(b):
		return "적 종류 night_wolf가 없다"
	var walls := []
	for y in 20:
		walls.append(b.build("wall", Vector2i(12, y)))
	b.spawn_enemy("night_wolf", Vector2i(10, 10), {"hp": BIG, "sight": 0})
	if not run(b, 10.0, func(): return walls.any(func(s): return s and s.hp < s.max_hp)):
		return "밤 늑대가 10초 안에 방벽을 치지 않았다"
	if not walls.all(func(s): return s == null or _bleed_of(s) == null):
		return "방벽에 출혈이 걸렸다"
	var got = _bite_board()  # 대조: 같은 밤 늑대가 용병을 물면 출혈이 걸린다
	return check(run(got[0], 1.0, func(): return _bleed_of(got[1]) != null), "용병 옆에 선 밤 늑대가 1초 안에 물어 출혈을 걸지 않았다")

# EV563 · S240·S155: 봉인되면 어둠에 세지지 않지만 물면 출혈은 건다
func ev563():
	if not _has_night(battle()):
		return "적 종류 night_wolf가 없다"
	var d := _night_walk(1.0, true)
	if absf(d - 2.8) > 0.05:
		return "봉인된 밤 늑대가 어둠 1에서 1초에 %s칸(2.8이어야 한다)" % d
	var got = _bite_board()
	got[2].fx["test"] = {"seal": true, "left": 5.0}
	var b = got[0]
	var m = got[1]
	return check(run(b, 1.0, func(): return _bleed_of(m) != null), "봉인된 밤 늑대가 물어도 출혈이 걸리지 않았다")

# ── 알파 늑대(S242·S243·I195) ──

func _has_alpha(b) -> bool:
	return b.ENEMY_KINDS.has("alpha_wolf")

func _alpha(b, cell: Vector2i, over := {}):
	return b.spawn_enemy("alpha_wolf", cell, {"hp": BIG, "speed": 0, "damage": 0, "sight": 0}.merged(over, true))

func _pinned(b, x) -> bool:
	return b.effect(x, "pin") != null

# 성곽 판: 성벽 (12,9)(또는 archer_at)에 궁수(체력 큼, 공격력 0, 방어력 0), (10,9)에 병사, (12,13)에 알파. [판, 궁수, 병사, 알파]
func _pounce_board(archer_at := Vector2(WALL), over := {}) -> Array:
	var b = _castle([], over)
	var a = b.place_merc("archer", Vector2i(13, 5), {"hp": BIG, "damage": 0})
	a.armor = 0.0
	a.pos = archer_at
	a.anchor = archer_at
	a.on_wall = true
	var s = _merc_on(b, Vector2(10, 9))
	return [b, a, s, _alpha(b, Vector2i(12, 13))]

# 알파가 성벽 위에 설 때까지(2초 안) 돌린다
func _land(g: Array) -> bool:
	return run(g[0], 2.0, func(): return g[3].on_wall)

# EV576 · S242: 7칸 안 성벽 위 원거리 아군을 1초 웅크린 뒤 0.4초 뛰어 덮치고, 착지에 물리 25와 붙잡힘
func ev576():
	if not _has_alpha(battle()):
		return "적 종류 alpha_wolf가 없다"
	var g := _pounce_board()
	var b = g[0]
	var a = g[1]
	var w = g[3]
	b.step(DT)
	var c = w.cast
	if not (c is Dictionary) or c.get("id") != "pounce" or c.get("who") != a:
		return "첫 스텝 예고 %s(pounce, 대상 궁수여야 한다)" % [c]
	var p0: Vector2 = w.pos
	var hp0: float = a.hp
	run(b, 0.85)  # 0.9초
	if w.pos.distance_to(p0) > 0.01 or a.hp != hp0:
		return "0.9초 알파 자리 %s → %s · 궁수 체력 %s → %s(그대로여야 한다)" % [p0, w.pos, hp0, a.hp]
	if not run(b, 1.1, func(): return w.on_wall):
		return "알파가 2초 안에 성벽 위에 서지 않았다"
	var gap: float = w.pos.distance_to(a.pos)
	var lost: float = hp0 - a.hp
	if gap > 1.0 or absf(lost - 25.0) > 0.5 or not _pinned(b, a):
		return "선 스텝 알파-궁수 거리 %.2f(1 안) · 궁수 체력 손실 %.2f(25) · 붙잡힘 %s" % [gap, lost, _pinned(b, a)]
	var far := _pounce_board(Vector2(3, 9))
	return check(not run(far[0], 3.0, func(): return far[3].cast != null), "궁수가 7칸 밖 (3,9)인데 3초 안에 웅크렸다")

# 알파(인식 범위 8)가 노리던 병사를 0.5초 뒤 (15,10)에 붙들어 둔다. [옮긴 뒤 예고가 처음 생긴 시각(없으면 -1), 예고 대상, 병사]
func _chase(walls: bool) -> Array:
	var b = battle()
	if walls:
		for y in range(8, 13):
			b.build("wall", Vector2i(13, y))
	var s = b.place_merc("soldier", Vector2i(12, 10), {"hp": BIG, "damage": 0})
	var w = _alpha(b, Vector2i(10, 10), {"sight": 8})
	run(b, 0.5)
	var t := 0.0
	while t < 3.0 - 0.001:
		s.pos = Vector2(15, 10)
		s.anchor = s.pos
		b.step(DT)
		t += DT
		if w.cast is Dictionary:
			return [t, w.cast.get("who"), s]
	return [-1.0, null, s]

# EV577 · S242: 노리던 아군이 3칸 넘게 떨어진 채 2초면 덮친다. 곧은 선이 막혔으면 고르지 않는다
func ev577():
	if not _has_alpha(battle()):
		return "적 종류 alpha_wolf가 없다"
	var open := _chase(false)
	if open[0] < 1.9 or open[0] > 2.1 or open[1] != open[2]:
		return "옮긴 뒤 예고 시각 %.2f초(1.9~2.1) · 대상이 병사 %s" % [open[0], open[1] == open[2]]
	var shut := _chase(true)
	return check(shut[0] < 0.0, "방벽 너머 병사인데 옮긴 뒤 %.2f초에 예고가 생겼다" % shut[0])

# EV578 · S242: 붙잡힌 아군은 4초 동안 서서 치지 않고, 알파는 그 아군만 초당 물리 8로 문다
func ev578():
	if not _has_alpha(battle()):
		return "적 종류 alpha_wolf가 없다"
	var g := _pounce_board()
	var b = g[0]
	var a = g[1]
	var s = g[2]
	var w = g[3]
	if not _land(g):
		return "알파가 2초 안에 성벽 위에 서지 않았다"
	a.damage = 5.0
	var whp: float = w.hp
	var ap: Vector2 = a.pos
	var hp0: float = a.hp
	var shp: float = s.hp
	run(b, 2.0)
	var lost: float = hp0 - a.hp
	if w.hp != whp or a.pos.distance_to(ap) > 0.01 or absf(lost - 16.0) > 0.5 or s.hp != shp:
		return "붙잡힌 2초: 알파 체력 %s → %s(그대로) · 궁수 자리 %s → %s · 궁수 체력 손실 %.2f(16) · 병사 체력 %s → %s" % [whp, w.hp, ap, a.pos, lost, shp, s.hp]
	run(b, 2.1)
	if _pinned(b, a):
		return "선 때부터 4.1초 뒤에도 붙잡힘이 있다"
	return check(run(b, 1.0, func(): return w.hp < whp), "붙잡힘이 풀린 뒤 1초 안에 궁수가 알파를 치지 않았다")

# EV579 · S242: 알파가 받은 피해 합이 40을 넘거나, 기절(비틀거리지 않음)·봉인에 걸리면 붙잡음이 풀린다
func ev579():
	if not _has_alpha(battle()):
		return "적 종류 alpha_wolf가 없다"
	var g := _pounce_board()
	var b = g[0]
	var a = g[1]
	var w = g[3]
	if not _land(g) or not _pinned(b, a):
		return "알파가 2초 안에 궁수를 붙잡지 않았다"
	b.damage(w, 30.0, "magic")
	b.step(DT)
	var held := _pinned(b, a)
	b.damage(w, 15.0, "magic")
	b.step(DT)
	if not held or _pinned(b, a):
		return "피해 30 뒤 붙잡힘 %s(있어야 한다) · 15 더 뒤 %s(없어야 한다)" % [held, _pinned(b, a)]
	g = _pounce_board()
	b = g[0]
	a = g[1]
	w = g[3]
	if not _land(g) or not _pinned(b, a):
		return "둘째 판에서 알파가 궁수를 붙잡지 않았다"
	b._fx(w, "test", {"stun": true}, 1.0)
	b.step(DT)
	if _pinned(b, a) or b.effect(w, "expose") != null:
		return "알파 기절 뒤 붙잡힘 %s · 받는 피해 증가 %s(둘 다 없어야 한다)" % [_pinned(b, a), b.effect(w, "expose") != null]
	g = _pounce_board()
	b = g[0]
	a = g[1]
	w = g[3]
	if not _land(g) or not _pinned(b, a):
		return "셋째 판에서 알파가 궁수를 붙잡지 않았다"
	b._fx(w, "test", {"seal": true}, 1.0)
	b.step(DT)
	return check(not _pinned(b, a), "알파를 봉인한 뒤에도 붙잡힘이 있다")

# EV580 · S242·S152: 붙잡힘은 해로운 효과라 정화(세라피나 W)로 풀린다
func ev580():
	if not _has_alpha(battle()):
		return "적 종류 alpha_wolf가 없다"
	var g := _pounce_board(Vector2(WALL), {"heroes": [{"kind": "seraphina", "cell": Vector2i(13, 7)}], "waves": [NONE, NONE], "seed": 11})
	var b = g[0]
	var a = g[1]
	var h = b.hero
	h.damage = 0.0
	b.start_battle()
	if not _land(g) or not _pinned(b, a):
		return "알파가 2초 안에 궁수를 붙잡지 않았다"
	h.mana = h.max_mana
	if not b.cast(h, "w", a.pos):
		return "세라피나가 W를 쓰지 못했다"
	b.step(DT)
	return check(not _pinned(b, a), "W를 쓴 다음 스텝에도 궁수가 붙잡혀 있다")

# EV581 · S243: 적이 아군에 거는 조작 효과는 하나만, 뒤에 건 것이 이긴다. 영웅이 적에 거는 CC는 지금대로
func ev581():
	if not _has_alpha(battle()):
		return "적 종류 alpha_wolf가 없다"
	var g := _pounce_board()
	var b = g[0]
	var a = g[1]
	if not _land(g) or not _pinned(b, a):
		return "알파가 2초 안에 궁수를 붙잡지 않았다"
	var v = _leap(b)
	if not run(b, 2.0, func(): return v.on_wall):
		return "도약 늑대가 2초 안에 성벽 위에 서지 않았다"
	if _pinned(b, a) or not _stunned(b, a):
		return "도약 늑대가 선 스텝에 붙잡힘 %s(없어야 한다) · 기절 %s(있어야 한다)" % [_pinned(b, a), _stunned(b, a)]
	g = _pounce_board()
	b = g[0]
	a = g[1]
	run(b, 1.0)
	a.fx["test"] = {"stun": true, "left": 3.0}
	if not _land(g):
		return "기절 판에서 알파가 2초 안에 성벽 위에 서지 않았다"
	if _stunned(b, a) or not _pinned(b, a):
		return "알파가 선 스텝에 기절 %s(없어야 한다) · 붙잡힘 %s(있어야 한다)" % [_stunned(b, a), _pinned(b, a)]
	var f = battle()
	var e = f.spawn_enemy("basic", Vector2i(10, 10), {"hp": BIG, "speed": 0, "damage": 0})
	f._fx(e, "a", {"stun": true}, 2.0)
	f._fx(e, "b", {"stun": true}, 0.5)
	run(f, 1.0)
	return check(_stunned(f, e), "적에 기절 2초 뒤 0.5초를 걸었더니 1초 뒤 기절이 없다")

# 거점 쪽으로 곧게 걷는 늑대가 1초에 간 거리. alphas: [칸, 봉인] 목록
func _wolf_walk(alphas := []) -> float:
	var b = battle()
	var v = b.spawn_enemy("wolf", Vector2i(5, 10), {"hp": BIG, "sight": 0})
	for x in alphas:
		var w = _alpha(b, x[0])
		if x[1]:
			w.fx["test"] = {"seal": true, "left": 5.0}
	var p0: Vector2 = v.pos
	run(b, 1.0)
	return v.pos.distance_to(p0)

# 용병 (10,10) 옆 (11,10)에 서 있는 늑대가 5.9초 동안 문 횟수(용병 체력이 준 스텝 수)
func _wolf_bites(alpha: bool) -> int:
	var b = battle()
	var m = b.place_merc("soldier", Vector2i(10, 10), {"hp": BIG, "damage": 0})
	m.armor = 0.0
	b.spawn_enemy("wolf", Vector2i(11, 10), {"hp": BIG, "speed": 0})
	if alpha:
		_alpha(b, Vector2i(11, 12))
	var n := 0
	for i in 118:
		var hp0: float = m.hp
		b.step(DT)
		if m.hp < hp0:
			n += 1
	return n

# EV582 · S242: 울부짖음 — 4칸 안 늑대는 이동·공격 속도 × 1.3, 봉인되면 꺼진다
func ev582():
	if not _has_alpha(battle()):
		return "적 종류 alpha_wolf가 없다"
	var d0 := _wolf_walk()
	var got := [_wolf_walk([[Vector2i(7, 12), false]]), _wolf_walk([[Vector2i(7, 16), false]]), _wolf_walk([[Vector2i(7, 12), true]])]
	var want := [1.3 * d0, d0, d0]
	if not range(3).all(func(i): return absf(got[i] - want[i]) <= 0.05):
		return "1초 거리 알파 (7,12)·(7,16)·봉인 %s(%s여야 한다, d0 %.2f)" % [got, want, d0]
	var bites := [_wolf_bites(false), _wolf_bites(true)]
	return check(bites == [8, 10], "5.9초 동안 문 횟수 알파 없음·있음 %s([8, 10]이어야 한다)" % [bites])

# EV583 · I195: 같은 적 오라는 둘이 닿아도 하나만 든다
func ev583():
	if not _has_alpha(battle()):
		return "적 종류 alpha_wolf가 없다"
	var d0 := _wolf_walk()
	var two := _wolf_walk([[Vector2i(7, 12), false], [Vector2i(7, 8), false]])
	return check(absf(two - 1.3 * d0) <= 0.05, "알파 둘 곁에서 1초 거리 %.2f(1.3 × %.2f = %.2f여야 한다)" % [two, d0, 1.3 * d0])
