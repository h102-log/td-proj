extends RefCounted
# 전투 시뮬레이션. 화면 없이 돈다(그리기는 src/ui/). API 계약은 tests/eval/gd/lib.gd 머리 주석에 있다.

signal enemy_spawned(enemy)

# ponytail: 수치는 임시값이다. 적·구조물 종류별 역할과 수치는 3.1(I34), Resource 파일화는 2.18(S31)에서 한다
const ENEMY_KINDS := {"basic": {"hp": 10.0, "speed": 2.0}}
const STRUCTURE_KINDS := {"wall": {"hp": 100.0}}
const SPAWN_GAP := 1.0  # 웨이브 안에서 적이 나오는 간격(초)

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
	var alive := true
	var path: Array[Vector2i] = []

	func _init(k: String, cell: Vector2i, stats: Dictionary) -> void:
		kind = k
		pos = Vector2(cell)
		for key in stats:
			set(key, stats[key])
		max_hp = hp

var size: Vector2i
var spawns: Array
var waves: Array
var base: Block
var castle := {}      # Vector2i → Block
var structures := {}  # Vector2i → Block
var enemies := []
var state := "prep"
var wave_index := 0

var grid := AStarGrid2D.new()
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
	var fort: Dictionary = stage.get("castle", {})
	for c in fort.get("walls", []):
		castle[c] = Block.new(c, "castle_wall", fort.wall_hp)
		grid.set_point_solid(c)
	for c in fort.get("gates", []):
		castle[c] = Block.new(c, "gate", fort.gate_hp)
		grid.set_point_solid(c)

func step(dt: float) -> void:
	if state == "battle":
		_spawn_wave(dt)
	if _repath:
		_repath = false
		for e in enemies:
			_find_path(e)
	for e in enemies:
		_move(e, dt)
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
	grid.set_point_solid(cell)
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

func _spawn_wave(dt: float) -> void:
	_spawn_timer -= dt
	if _queue.is_empty() or _spawn_timer > 0.0:
		return
	spawn_enemy(_queue.pop_front(), spawns[_spawned % spawns.size()])
	_spawned += 1
	_spawn_timer = SPAWN_GAP

# 거점 옆 칸까지의 경로. 거점에 닿을 길이 없으면 가장 가까운 칸까지 간다.
# ponytail: 막힌 칸은 지금 아예 못 지나간다. 성벽을 부수는 비용 경로는 2.4(S7)에서 바꾼다
func _find_path(e: Enemy) -> void:
	e.path = grid.get_id_path(Vector2i(e.pos.round()), base.cell, true)
	if not e.path.is_empty() and e.path.back() == base.cell:
		e.path.pop_back()

func _move(e: Enemy, dt: float) -> void:
	var left := e.speed * dt
	while left > 0.0 and not e.path.is_empty():
		var target := Vector2(e.path[0])
		var d := e.pos.distance_to(target)
		if d <= left:
			e.pos = target
			e.path.remove_at(0)
			left -= d
		else:
			e.pos += (target - e.pos) / d * left
			left = 0.0
