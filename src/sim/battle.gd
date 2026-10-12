extends RefCounted
# 전투 시뮬레이션. 화면 없이 돈다(그리기는 src/ui/). API 계약은 tests/eval/gd/lib.gd 머리 주석에 있다.

signal enemy_spawned(enemy)

# ponytail: 수치는 임시값이다. 적·구조물 종류별 역할과 수치는 3.1(I34), Resource 파일화는 2.18(S31)에서 한다
# ponytail: wall_k 1.0은 가득 찬 방벽(100) 하나 = 100칸 걷기. EV6·9(돌아가기)와 EV7(뚫기)을 함께 넘는 임시값
const ENEMY_KINDS := {"basic": {"hp": 10.0, "speed": 2.0, "wall_k": 1.0, "damage": 5.0, "attack_gap": 1.0, "radius": 0.3}}
const STRUCTURE_KINDS := {"wall": {"hp": 100.0}}
const SPAWN_GAP := 1.0  # 웨이브 안에서 적이 나오는 간격(초)
const REACH := 1.0      # 적이 막힌 칸·거점을 칠 수 있는 거리(칸 중심 사이). 옆 칸 중심까지가 1이다

# 칸 하나를 차지하고 체력이 있는 것: 거점 "base" · 성곽 "castle_wall"·"gate" · 구조물 "wall" 등
class Block:
	var cell: Vector2i
	var kind: String
	var max_hp: float
	var hp: float
	var alive := true
	var complete := true

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
	var cooldown := 0.0  # 0 이하면 바로 칠 수 있다
	var alive := true
	var path: Array[Vector2i] = []

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
var state := "prep"
var wave_index := 0

var grid := CostGrid.new()
var _repath := false  # 막힌 칸이 바뀌어 적 경로를 다시 구해야 한다
var _queue := []      # 이번 웨이브에서 아직 안 나온 적 종류
var _spawn_timer := 0.0
var _spawned := 0     # 이번 웨이브에서 나온 적 수(출현 지점 돌아가며 쓰기)

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
	if state == "battle" and _queue.is_empty() and enemies.is_empty():
		wave_index += 1
		state = "won" if wave_index >= waves.size() else "prep"

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
	_find_path(e)
	enemies.append(e)
	enemy_spawned.emit(e)
	return e

# 준비 단계에만, 빈 칸(구조물·성곽·거점이 없는 맵 안 칸)에 바로 완성해 짓는다(S18, I24)
func build(kind: String, cell: Vector2i, overrides := {}):
	if state != "prep" or not grid.is_in_boundsv(cell) or structures.has(cell) or castle.has(cell) or cell == base.cell:
		return null
	var stats: Dictionary = STRUCTURE_KINDS[kind].merged(overrides, true)
	var s := Block.new(cell, kind, stats.hp)
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

# 거점까지 «걷는 거리 + 막힌 칸 비용»이 가장 싼 경로. 막힌 칸과 거점은 닿는 거리에서 친다(_move).
func _find_path(e: Enemy) -> void:
	grid.wall_k = e.wall_k
	e.path = grid.get_id_path(Vector2i(e.pos.round()), base.cell, true)

func _move(e: Enemy, dt: float) -> void:
	e.cooldown -= dt
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
			_shove(e, (target - e.pos) / d * left)
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
				_shove(a, -push)
				_shove(o, push)

# 맵 밖이나 막힌 칸·거점 칸으로는 들어가지 않는다. 막히면 한 축으로만 움직여 벽을 따라 미끄러진다
func _shove(e: Enemy, by: Vector2) -> void:
	for v in [by, Vector2(by.x, 0), Vector2(0, by.y)]:
		var c := Vector2i((e.pos + v).round())
		if grid.is_in_boundsv(c) and not grid.block_at(c) and c != base.cell:
			e.pos += v
			return

func _attack(e: Enemy, target) -> void:
	if e.cooldown <= 0.0:
		e.cooldown = e.attack_gap
		damage(target, e.damage)
