extends "res://tests/eval/gd/lib.gd"
# 2라운드 늑대 PR ①: 무리 출현(S238·I190), 도약 늑대(S239·I191), 아군 기절(I192). lib.gd·kits.gd 머리의 계약에 더하는 API:
#   적 kind "wolf"(늑대) · "leap_wolf"(도약 늑대) · 적 on_wall·fx·goal · stage 키 spawn_gap(출현 간격)·spawn_spread(출현 퍼짐, I177)·castle
#   Battle.spawn_counts(라운드, 웨이브) · Battle.effect(대상, 키) · Battle.cast(영웅, 칸, aim) · 용병 on_wall·anchor · 영웅 mana·max_mana·cd

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
