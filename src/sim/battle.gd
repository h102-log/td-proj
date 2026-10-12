extends RefCounted
# 전투 시뮬레이션. 화면 없이 돈다(그리기는 src/ui/). API 계약은 tests/eval/gd/lib.gd 머리 주석에 있다.

signal enemy_spawned(enemy)

# ponytail: 수치는 임시값이다. 적·구조물 종류별 역할과 수치는 3.1(I34), Resource 파일화는 2.18(S31)에서 한다
# ponytail: wall_k 1.0은 가득 찬 방벽(100) 하나 = 100칸 걷기. EV6·9(돌아가기)와 EV7(뚫기)을 함께 넘는 임시값
const ENEMY_KINDS := {"basic": {"hp": 10.0, "speed": 2.0, "wall_k": 1.0, "damage": 5.0, "attack_gap": 1.0, "radius": 0.3, "sight": 3.0}}
# ponytail: 용병은 몸과 체력만 있다. 이동·자동 공격(damage·range·sight·hold_radius)은 2.8에서 붙인다
const MERC_KINDS := {"soldier": {"hp": 50.0, "radius": 0.3}}
# 스킬은 «주변 skill_radius칸 안의 적 전부에게 피해»다(I33, 사용자 2026-10-12: 1.5칸·대기 10초·단축키 Q). 피해량 등 나머지는 임시값
# ponytail: 영웅은 하나뿐이다. 영웅 종류·스킬 2개·오라(I33)는 내용이 정해지면 HERO_KINDS로 넓힌다
const HERO := {"hp": 100.0, "radius": 0.3, "speed": 3.0, "damage": 3.0, "range": 1.5, "attack_gap": 1.0,
	"skill_damage": 30.0, "skill_radius": 1.5, "skill_gap": 10.0}
const STRUCTURE_KINDS := {"wall": {"hp": 100.0}, "tower": {"hp": 100.0, "range": 4.0, "damage": 2.0, "fire_gap": 1.0}}
const SPAWN_GAP := 1.0  # 웨이브 안에서 적이 나오는 간격(초)
const REACH := 1.0      # 적이 막힌 칸·거점·유닛을 칠 수 있는 거리(중심 사이). 옆 칸 중심까지가 1이다
const UNIT_WALL_K := 1e6  # 유닛 경로의 막힌 칸 비용 배율. 돌아갈 길이 있으면 막힌 칸(닫힌 성문 포함, I42)을 지나지 않는다

# 칸 하나를 차지하고 체력이 있는 것: 거점 "base" · 성곽 "castle_wall"·"gate" · 구조물 "wall" 등
class Block:
	var cell: Vector2i
	var kind: String
	var max_hp: float
	var hp: float
	var alive := true
	var complete := true
	var range := 0.0  # 사거리(칸). 0보다 커야 적을 쏜다(타워)
	var damage := 0.0
	var fire_gap := 1.0  # 쏘는 간격(초)
	var cooldown := 0.0

	func _init(c: Vector2i, k: String, h: float) -> void:
		cell = c
		kind = k
		max_hp = h
		hp = h

class Enemy:
	var kind: String
	var pos: Vector2  # 칸 단위, 칸 (x,y)의 중심 = Vector2(x,y)
	var hp: float
	var max_hp: float
	var speed: float
	var radius: float  # 몸 반지름(칸 단위)
	var wall_k: float
	var damage: float
	var attack_gap: float  # 공격 간격(초)
	var sight: float  # 인식 범위(칸)
	var cooldown := 0.0  # 0 이하면 바로 칠 수 있다
	var alive := true
	var attacker  # 마지막으로 이 적을 쏜 구조물. 살아 있는 동안 반격 대상이다(S4 ②)
	var goal: Vector2i  # 경로의 끝 칸(지금 노리는 대상의 칸)
	var path: Array[Vector2i] = []

	func _init(k: String, cell: Vector2i, stats: Dictionary) -> void:
		kind = k
		pos = Vector2(cell)
		for key in stats:
			set(key, stats[key])
		max_hp = hp

# 영웅과 용병(I1). 지금은 영웅만 걷고 치고 스킬을 쓴다. 용병은 speed·range가 0이다(2.8에서 붙인다)
class Unit:
	var kind: String
	var pos: Vector2  # 칸 단위, Enemy.pos와 같다
	var hp: float
	var max_hp: float
	var radius: float  # 몸 반지름(칸 단위)
	var alive := true
	var present: bool:  # 전장에 있다. 쓰러진 영웅은 다음 준비 단계에 돌아올 때까지 거짓이다(S26)
		get:
			return alive
	var speed := 0.0
	var damage := 0.0
	var range := 0.0  # 사거리(칸). 0보다 커야 적을 친다
	var attack_gap := 1.0  # 공격 간격(초)
	var cooldown := 0.0
	var path: Array[Vector2i] = []  # 명령받은 이동 경로(지금 칸 제외)
	var skill_damage := 0.0
	var skill_radius := 0.0
	var skill_gap := 0.0  # 재사용 대기(초). 0이면 스킬이 없다
	var skill_cooldown := 0.0
	var skill_uses := 0

	func skill_ready() -> bool:
		return skill_gap > 0.0 and skill_cooldown <= 0.0

	func _init(k: String, cell: Vector2i, stats: Dictionary) -> void:
		kind = k
		pos = Vector2(cell)
		for key in stats:
			set(key, stats[key])
		max_hp = hp

# 막힌 칸(구조물·성곽)을 «남은 체력 × 적의 wall_k» 비용 칸으로 보는 격자(S7, S34, I3, I40)
class CostGrid extends AStarGrid2D:
	var castle: Dictionary
	var structures: Dictionary
	var wall_k := 1.0  # 경로를 구하기 직전에 그 적의 값을 넣는다

	func block_at(c: Vector2i):
		return structures.get(c, castle.get(c))

	func _compute_cost(from: Vector2i, to: Vector2i) -> float:
		# 옆 칸이 막혔으면 대각선으로 끼어들지 않는다(solid였을 때의 DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES와 같게)
		if from.x != to.x and from.y != to.y and (block_at(Vector2i(to.x, from.y)) or block_at(Vector2i(from.x, to.y))):
			return 1e9
		var b = block_at(to)
		return Vector2(to - from).length() + (b.hp * wall_k if b else 0.0)

var size: Vector2i
var spawns: Array
var waves: Array
var base: Block
var castle := {}      # Vector2i → Block
var structures := {}  # Vector2i → Block
var enemies := []
var units := []  # 살아 있는 영웅·용병
var hero  # 영웅(Unit). 스테이지에 hero_start가 없으면 null
var revive := true  # 쓰러진 영웅이 다음 준비 단계에 돌아온다(S27). 기본값 켜짐(I28)
var state := "prep"
var wave_index := 0

var grid := CostGrid.new()
var _repath := false  # 막힌 칸이 바뀌어 적 경로를 다시 구해야 한다
var _queue := []      # 이번 웨이브에서 아직 안 나온 적 종류
var _spawn_timer := 0.0
var _spawned := 0     # 이번 웨이브에서 나온 적 수(출현 지점 돌아가며 쓰기)
var _hero_start: Vector2i  # 쓰러진 영웅이 돌아오는 칸

func _init(stage: Dictionary) -> void:
	size = stage.size
	spawns = stage.spawns
	for c in spawns:
		assert(c.x == 0 or c.y == 0 or c.x == size.x - 1 or c.y == size.y - 1, "출현 지점 %s가 맵 가장자리가 아니다" % c)
	waves = stage.get("waves", [])
	base = Block.new(stage.base, "base", stage.base_hp)
	grid.region = Rect2i(Vector2i.ZERO, size)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	grid.castle = castle
	grid.structures = structures
	var fort: Dictionary = stage.get("castle", {})
	for c in fort.get("walls", []):
		castle[c] = Block.new(c, "castle_wall", fort.wall_hp)
	for c in fort.get("gates", []):
		castle[c] = Block.new(c, "gate", fort.gate_hp)
	if stage.get("hero_start") != null:
		_hero_start = stage.hero_start
		hero = Unit.new("hero", _hero_start, HERO)
		units.append(hero)

func step(dt: float) -> void:
	if state == "battle":
		_spawn_wave(dt)
	if _repath:
		_repath = false
		for e in enemies:
			_find_path(e)
	for e in enemies:
		_move(e, dt)
	_push_apart()
	for u in units:
		_act(u, dt)
	_fire(dt)
	if state == "battle" and _queue.is_empty() and enemies.is_empty():
		wave_index += 1
		state = "won" if wave_index >= waves.size() else "prep"
		if state == "prep" and revive and hero and not hero.alive:
			_return_hero()

# 쓰러진 영웅은 시작 지점에 체력이 가득 찬 채 돌아온다(S26, I27)
# ponytail: 공격·스킬 대기는 쓰러질 때 값 그대로 둔다. 정할 문장이 생기면 여기서 초기화
func _return_hero() -> void:
	hero.alive = true
	hero.hp = hero.max_hp
	hero.pos = Vector2(_hero_start)
	hero.path.clear()
	units.append(hero)

func start_battle() -> void:
	if state != "prep" or wave_index >= waves.size():
		return
	state = "battle"
	for entry in waves[wave_index]:
		for i in entry.count:
			_queue.append(entry.kind)
	_spawn_timer = 0.0
	_spawned = 0

func spawn_enemy(kind: String, cell: Vector2i, overrides := {}):
	var e := Enemy.new(kind, cell, ENEMY_KINDS[kind].merged(overrides, true))
	e.goal = base.cell
	_find_path(e)
	enemies.append(e)
	enemy_spawned.emit(e)
	return e

# 준비 단계에만, 막힌 칸·거점이 아닌 맵 안 칸에 바로 놓는다(S18)
func place_merc(kind: String, cell: Vector2i, overrides := {}):
	if state != "prep" or not grid.is_in_boundsv(cell) or grid.block_at(cell) or cell == base.cell:
		return null
	var m := Unit.new(kind, cell, MERC_KINDS[kind].merged(overrides, true))
	units.append(m)
	return m

# 유닛들을 그 칸으로 보낸다(S14). 맵 밖 칸이면 무시한다
func order_move(group: Array, cell: Vector2i) -> void:
	if not grid.is_in_boundsv(cell):
		return
	grid.wall_k = UNIT_WALL_K
	for u in group:
		if u.alive:
			u.path = grid.get_id_path(Vector2i(u.pos.round()), cell, true).slice(1)

# 영웅 스킬(S15): 주변 skill_radius칸 안의 적 전부에게 피해. 명령으로만 쓴다
func use_skill() -> void:
	if not hero or not hero.alive or not hero.skill_ready():
		return
	hero.skill_cooldown = hero.skill_gap
	hero.skill_uses += 1
	for e in enemies.duplicate():
		if e.pos.distance_to(hero.pos) <= hero.skill_radius:
			damage(e, hero.skill_damage)

# 준비 단계에만, 빈 칸(구조물·성곽·거점이 없는 맵 안 칸)에 바로 완성해 짓는다(S18, I24)
func build(kind: String, cell: Vector2i, overrides := {}):
	if state != "prep" or not grid.is_in_boundsv(cell) or structures.has(cell) or castle.has(cell) or cell == base.cell:
		return null
	var stats: Dictionary = STRUCTURE_KINDS[kind].merged(overrides, true)
	var s := Block.new(cell, kind, stats.hp)
	for key in stats:
		s.set(key, stats[key])
	structures[cell] = s
	_repath = true
	return s

func structure_at(cell: Vector2i):
	return structures.get(cell)

func damage(target, amount: float) -> void:
	if not target.alive:
		return
	target.hp = maxf(target.hp - amount, 0.0)
	if target.hp > 0.0:
		return
	target.alive = false
	if target == base:
		state = "lost"
	elif target is Enemy:
		enemies.erase(target)
	elif target is Unit:  # 전장에서 빠진다. 영웅은 다음 준비 단계에 돌아온다(step, S26)
		units.erase(target)
	else:  # 구조물·성곽: 칸이 비고 경로를 다시 구한다(I5)
		structures.erase(target.cell)
		castle.erase(target.cell)
		_repath = true

func _spawn_wave(dt: float) -> void:
	_spawn_timer -= dt
	if _queue.is_empty() or _spawn_timer > 0.0:
		return
	spawn_enemy(_queue.pop_front(), spawns[_spawned % spawns.size()])
	_spawned += 1
	_spawn_timer = SPAWN_GAP

# 대상 칸(e.goal)까지 «걷는 거리 + 막힌 칸 비용»이 가장 싼 경로. 막힌 칸과 거점은 닿는 거리에서 친다(_move).
# 그래서 반격 대상이 성벽에 둘러싸여 있으면 비용이 가장 싼 성벽을 뚫고 간다(S6)
func _find_path(e: Enemy) -> void:
	grid.wall_k = e.wall_k
	e.path = grid.get_id_path(Vector2i(e.pos.round()), e.goal, true)

# 적이 지금 노리는 것(S4): ① 인식 범위 안이나 몸이 닿은 가장 가까운 유닛(영웅·용병) → ② 살아 있는 반격 대상 → ③④ 거점.
# 들판의 구조물은 ①이 아니다(I7). 쏘지 않는 구조물은 attacker가 되지 않는다(_fire). 반격 대상이 부서지면 ②가 끝난다(I8)
func _target_of(e: Enemy):
	var best = null
	var best_d := INF
	for m in units:
		var d := e.pos.distance_to(m.pos)
		# 밀어낸 직후 거리는 반지름 합과 같아서 0.01 여유를 둔다(S13: 몸으로 막은 유닛은 인식 범위 밖이어도 친다)
		if d < best_d and (d <= e.sight or d <= e.radius + m.radius + 0.01):
			best = m
			best_d = d
	if best:
		return best
	if e.attacker and e.attacker.alive:
		return e.attacker
	return base

func _move(e: Enemy, dt: float) -> void:
	e.cooldown -= dt
	var aim = _target_of(e)
	var goal: Vector2i = Vector2i(aim.pos.round()) if aim is Unit else aim.cell
	if goal != e.goal:  # 대상이 바뀌었다
		e.goal = goal
		_find_path(e)
	if aim is Unit and e.pos.distance_to(aim.pos) <= REACH:
		_attack(e, aim)
		return
	var left := e.speed * dt
	while left > 0.0 and not e.path.is_empty():
		var next: Vector2i = e.path[0]
		var target := Vector2(next)
		var d := e.pos.distance_to(target)
		var block = base if next == base.cell else grid.block_at(next)
		if block:
			if d <= REACH:  # 막힌 칸은 부수고(I6, S9), 거점은 친다(S4 ④)
				_attack(e, block)
				return
		elif Vector2i(e.pos.round()) == next:
			# 칸에 들어서면 도착으로 친다. 밀려나 칸 중심에 못 닿는 적들이 같은 중심을 노리며 멈추지 않게(I51)
			e.path.remove_at(0)
			continue
		if d <= left:
			e.pos = target
			e.path.remove_at(0)
			left -= d
		else:
			_shove(e, (target - e.pos) / d * left, units)
			left = 0.0

# 겹친 적끼리 겹친 만큼 반씩 밀어낸다. 경로는 그대로라 밀려난 적은 _move가 다시 데려간다(I51)
# ponytail: O(n²) 전수 비교, 적이 수백이면 칸 버킷으로
func _push_apart() -> void:
	for i in enemies.size():
		for j in range(i + 1, enemies.size()):
			var a: Enemy = enemies[i]
			var o: Enemy = enemies[j]
			var gap := o.pos - a.pos
			var overlap := a.radius + o.radius - gap.length()
			if overlap > 0.0:
				var push := (gap.normalized() if gap != Vector2.ZERO else Vector2.RIGHT) * overlap / 2.0
				_shove(a, -push, units)
				_shove(o, push, units)

# 쏘는 구조물은 사거리 안에서 가장 가까운 적을 쏘고(S28, I29), 맞은 적은 그 구조물에 반격한다(S5)
func _fire(dt: float) -> void:
	for s in structures.values():
		if s.range <= 0.0:
			continue
		s.cooldown -= dt
		if s.cooldown > 0.0:
			continue
		var best = _nearest_enemy(Vector2(s.cell), s.range)
		if best:
			s.cooldown = s.fire_gap
			best.attacker = s
			damage(best, s.damage)

# 유닛은 명령받은 경로를 걷고(S14), 사거리 안의 가장 가까운 적을 친다(S15). 걷는 동안에도 친다
func _act(u: Unit, dt: float) -> void:
	u.cooldown -= dt
	u.skill_cooldown -= dt
	var left := u.speed * dt
	while left > 0.0 and not u.path.is_empty():
		var to := Vector2(u.path[0]) - u.pos
		_shove(u, to.limit_length(left), enemies)
		left -= to.length()  # 적에게 막혀 못 갔어도 줄인다
		if u.pos.distance_to(Vector2(u.path[0])) < 0.01:
			u.path.remove_at(0)
	if u.range > 0.0 and u.cooldown <= 0.0:
		var e = _nearest_enemy(u.pos, u.range)
		if e:
			u.cooldown = u.attack_gap
			damage(e, u.damage)

func _nearest_enemy(from: Vector2, reach: float):
	var best = null
	var best_d := reach
	for e in enemies:
		var d: float = e.pos.distance_to(from)
		if d <= best_d:
			best = e
			best_d = d
	return best

# 맵 밖이나 막힌 칸·거점 칸으로는 들어가지 않는다. 막히면 한 축으로만 움직여 벽을 따라 미끄러진다
# 2026-10-12
# [동작] bodies(적이 움직이면 유닛, 유닛이 움직이면 적)와 겹치는 자리는 그 몸 바로 바깥 자리로 바꾼 뒤 칸을 검사한다
# [의도] 유닛이 몸으로 적의 길을 막고, 몸이 닿은 적은 그 유닛을 치게 한다(S13, _target_of). 경로에는 유닛을 넣지 않는다(I2)
# [이유] 겹친 뒤 따로 밀어내면, 성벽에 막힌 적이 한 축으로 미끄러지며 한 칸 틈의 용병 옆을 빠져나갔다
#        (test_crowd_cannot_pass_merc_in_one_cell_gap)
# ponytail: 몸 하나씩 차례로 밀어낸다. 몸끼리 붙어 있으면 앞 몸 쪽으로 다시 겹칠 수 있다. 아군끼리 밀어내기(2.8)에서 다시 본다
func _shove(e, by: Vector2, bodies: Array) -> void:
	for v in [by, Vector2(by.x, 0), Vector2(0, by.y)]:
		var p: Vector2 = e.pos + v
		for m in bodies:
			var gap: Vector2 = p - m.pos
			if gap.length() < e.radius + m.radius:
				p = m.pos + (gap.normalized() if gap != Vector2.ZERO else Vector2.LEFT) * (e.radius + m.radius)
		var c := Vector2i(p.round())
		if grid.is_in_boundsv(c) and not grid.block_at(c) and c != base.cell:
			e.pos = p
			return

func _attack(e: Enemy, target) -> void:
	if e.cooldown <= 0.0:
		e.cooldown = e.attack_gap
		damage(target, e.damage)
