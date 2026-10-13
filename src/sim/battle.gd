extends RefCounted
# 전투 시뮬레이션. 화면 없이 돈다(그리기는 src/ui/). API 계약은 tests/eval/gd/lib.gd 머리 주석에 있다.

signal enemy_spawned(enemy)

# 종류 이름 → 수치. 판을 만들 때 data/ 아래 Resource 파일에서 읽는다(S31). 파일 이름이 종류 이름이다(I66)
# 상수였을 때의 이름을 그대로 둔다(UI·테스트가 battle.MERC_KINDS.soldier.cost처럼 읽는다)
var ENEMY_KINDS := _kinds("res://data/enemies/")
var MERC_KINDS := _kinds("res://data/mercs/")
var STRUCTURE_KINDS := _kinds("res://data/structures/")
# 스킬은 «주변 skill_radius칸 안의 적 전부에게 피해»다(I33, 사용자 2026-10-12: 1.5칸·대기 10초·단축키 Q). 피해량 등 나머지는 임시값
# 스킬 2(buff_*)는 «주변 buff_radius칸 안 용병의 공격력 ×buff_mult, buff_time초»다(S84, 단축키 W). 수치는 임시값
# ponytail: 영웅은 하나뿐이라 아직 상수다. 영웅 종류·오라(I33)와 Resource 파일화(I66)는 3.7에서 HERO_KINDS로 넓힌다
const HERO := {"hp": 100.0, "radius": 0.3, "speed": 3.0, "damage": 3.0, "range": 1.5, "attack_gap": 1.0,
	"skill_damage": 30.0, "skill_radius": 1.5, "skill_gap": 10.0,
	"buff_radius": 3.0, "buff_mult": 1.5, "buff_time": 5.0, "buff_gap": 20.0}
const MERC_CAP := 10  # 배치 상한 기본값(S25). 임시값(사용자 2026-10-13), 스테이지의 merc_cap이 덮어쓴다
const SPAWN_GAP := 1.0  # 웨이브 안에서 적이 나오는 간격(초)
const REACH := 1.0      # 적이 막힌 칸·거점·유닛을 칠 수 있는 거리(중심 사이). 옆 칸 중심까지가 1이다
const UNIT_WALL_K := 1e6  # 유닛 경로의 막힌 칸 비용 배율. 돌아갈 길이 있으면 막힌 칸(닫힌 성문 포함, I42)을 지나지 않는다
const WORK_REACH := 2.0  # 공병이 일하는 거리(중심 사이). 옆 칸 대각선(1.41)에, 무리에 밀려 0.5칸 못 미친 도착(I51)을 더했다

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
	var target  # 마지막으로 쏜 적. 화면이 쏜 직후 사격 선을 그린다
	var paid := 0  # 지을 때 낸 골드. 판매 환불의 기준(S69)
	var produces := ""  # 생산 시설이면 나오는 용병 kind(S20)
	var rally: Vector2i  # 생산 시설의 집결 지점(S21)
	var progress := 1.0  # 건설 진행률(0~1). 1 미만이면 미완성이다(I62)
	var build_time := 1.0  # 전투 중 짓는 데 드는 시간(초)
	var worker  # 이 구조물을 짓거나 허무는(그러러 가는) 공병
	var razed := 0.0  # 철거 진행률(0~1, I64)

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
	var reward := 0  # 처치하면 얻는 골드(I15)
	var cooldown := 0.0  # 0 이하면 바로 칠 수 있다
	var alive := true
	var attacker  # 마지막으로 이 적을 쏜 구조물. 살아 있는 동안 반격 대상이다(S4 ②)
	var target  # 마지막으로 친 대상. 화면이 친 직후 공격선을 그린다(S71)
	var goal: Vector2i  # 경로의 끝 칸(지금 노리는 대상의 칸)
	var path: Array[Vector2i] = []

	func _init(k: String, cell: Vector2i, stats: Dictionary) -> void:
		kind = k
		pos = Vector2(cell)
		for key in stats:
			set(key, stats[key])
		max_hp = hp

# 영웅과 용병(I1). 스킬은 영웅만, 이동 방식·홀드는 용병만 쓴다(S16)
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
	var target  # 마지막으로 친 적. 화면이 친 직후 공격선을 그린다(S71)
	var paid := 0  # 놓을 때 낸 골드. 판매 환불의 기준(S69)
	var rally_from  # 집결 지점으로 걸어가는 중이면 나온 생산 시설(I22). 닿거나 다른 이동 지시를 받으면 null
	var job  # 공병이 맡은 구조물(짓거나 허문다, I63). 놀고 있으면 null
	var sight := 0.0  # 인식 범위(칸). 서 있을 때 이 안의 적을 쫓는다(I36)
	var path: Array[Vector2i] = []  # 명령받은 이동 경로(지금 칸 제외)
	var move_mode := "attack_move"  # "move" | "attack_move"(S35). 새 용병은 이동 중 공격(I38)
	var hold := false  # 켜지면 anchor에서 hold_radius 안에서만 싸운다(S36)
	var hold_radius := 0.0
	var anchor: Vector2  # 홀드 기준 지점(I37)
	var skill_damage := 0.0
	var skill_radius := 0.0
	var skill_gap := 0.0  # 재사용 대기(초). 0이면 스킬이 없다
	var skill_cooldown := 0.0
	var skill_uses := 0
	var buff_radius := 0.0
	var buff_mult := 1.0
	var buff_time := 0.0
	var buff_gap := 0.0  # 재사용 대기(초). 0이면 스킬 2가 없다
	var buff_cooldown := 0.0
	var boost := 1.0  # 용병이 받은 버프 배율. boost_left초 동안만 공격력에 곱한다(S84)
	var boost_left := 0.0

	func skill_ready() -> bool:
		return skill_gap > 0.0 and skill_cooldown <= 0.0

	func buff_ready() -> bool:
		return buff_gap > 0.0 and buff_cooldown <= 0.0

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
var gold := 0
var village := Rect2i()  # 마을 칸. 생산 시설은 안에만, 나머지 구조물은 밖에만 짓는다(S43). 비어 있으면 모두 들판
var merc_cap := MERC_CAP

var grid := CostGrid.new()
var _repath := false  # 막힌 칸이 바뀌어 적 경로를 다시 구해야 한다
var _queue := []      # 이번 웨이브에서 아직 안 나온 적 종류
var _spawn_timer := 0.0
var _spawned := 0     # 이번 웨이브에서 나온 적 수(출현 지점 돌아가며 쓰기)
var _hero_start: Vector2i  # 쓰러진 영웅이 돌아오는 칸
var _stage: Dictionary  # 재시작할 때 다시 읽는다

# dir의 Resource 파일마다 «파일 이름 → 스크립트 변수 사전». list_directory는 내보낸 빌드의 .remap도 원래 이름으로 준다
static func _kinds(dir: String) -> Dictionary:
	var out := {}
	for f in ResourceLoader.list_directory(dir):
		if f.ends_with(".tres"):
			var r := load(dir + f)
			var stats := {}
			for p in r.get_property_list():
				if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
					stats[p.name] = r.get(p.name)
			out[f.get_basename()] = stats
	return out

func _init(stage: Dictionary) -> void:
	size = stage.size
	spawns = stage.spawns
	for c in spawns:
		assert(c.x == 0 or c.y == 0 or c.x == size.x - 1 or c.y == size.y - 1, "출현 지점 %s가 맵 가장자리가 아니다" % c)
	waves = stage.get("waves", [])
	grid.region = Rect2i(Vector2i.ZERO, size)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	grid.castle = castle
	grid.structures = structures
	_stage = stage
	restart()

# 판을 stage 그대로 처음 상태로 놓는다(S29). W1은 라운드 하나뿐인 도전이라 재시작이 곧 하드리셋이다(S64)
# 컬렉션은 새로 만들지 않고 비운다. grid와 화면이 같은 객체를 쥐고 있다
func restart() -> void:
	var stage := _stage
	state = "prep"
	wave_index = 0
	gold = stage.get("gold", 0)
	village = stage.get("village", Rect2i())
	merc_cap = stage.get("merc_cap", MERC_CAP)
	base = Block.new(stage.base, "base", stage.base_hp)
	for s in structures.values():  # 공병 ↔ 구조물 상호 참조를 끊는다. 남기면 RefCounted 순환이라 해제되지 않는다
		_release(s)
	castle.clear()
	structures.clear()
	enemies.clear()
	units.clear()
	_queue.clear()
	_repath = false
	var fort: Dictionary = stage.get("castle", {})
	for c in fort.get("walls", []):
		castle[c] = Block.new(c, "castle_wall", fort.wall_hp)
	for c in fort.get("gates", []):
		castle[c] = Block.new(c, "gate", fort.gate_hp)
	hero = null
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
	_push_apart(enemies, units)
	for u in units:
		_act(u, dt)
	_push_apart(units, enemies)
	_fire(dt)
	if state == "battle" and _queue.is_empty() and enemies.is_empty():
		wave_index += 1
		state = "won" if wave_index >= waves.size() else "prep"
		for s in structures.values():  # 하던 건설·철거는 그 상태로 멈춘다(I19)
			_release(s)
		if state == "prep" and revive and hero and not hero.alive:
			_return_hero()

# 쓰러진 영웅은 시작 지점에 체력이 가득 찬 채 돌아온다(S26, I27)
# 공격·스킬 대기는 쓰러질 때 값을 이어 간다(S67)
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

# 준비 단계에만, 막힌 칸·거점이 아닌 맵 안 칸에 바로 놓는다(S18). 골드가 모자라면 거부한다(I16)
func place_merc(kind: String, cell: Vector2i, overrides := {}):
	if state != "prep" or not grid.is_in_boundsv(cell) or grid.block_at(cell) or cell == base.cell:
		return null
	var stats: Dictionary = MERC_KINDS[kind].merged(overrides, true)
	if gold < stats.cost or _mercs() >= merc_cap:
		return null
	gold -= stats.cost
	var m := Unit.new(kind, cell, stats)
	m.paid = stats.cost
	units.append(m)
	return m

# 유닛들을 그 칸으로 보낸다(S14). 맵 밖 칸이면 무시한다
func order_move(group: Array, cell: Vector2i) -> void:
	if not grid.is_in_boundsv(cell):
		return
	grid.wall_k = UNIT_WALL_K
	for u in group:
		u.rally_from = null
		if u.job:  # 공병은 하던 일을 그만둔다(I63)
			_release(u.job)
		if u.alive:
			u.path = grid.get_id_path(Vector2i(u.pos.round()), cell, true).slice(1)

# 용병의 이동 방식(S35)·홀드(S36)를 바꾼다. 영웅에게는 걸지 않는다(S16)
func set_move_mode(group: Array, mode: String) -> void:
	assert(mode in ["move", "attack_move"], "이동 방식 %s" % mode)
	for u in group:
		if u != hero:
			u.move_mode = mode

func set_hold(group: Array, on: bool) -> void:
	for u in group:
		if u != hero:
			u.hold = on
			u.anchor = u.pos  # 기준 지점은 켠 순간의 위치(I37)

# 영웅 스킬(S15): 주변 skill_radius칸 안의 적 전부에게 피해. 명령으로만 쓴다
func use_skill() -> void:
	if not hero or not hero.alive or not hero.skill_ready():
		return
	hero.skill_cooldown = hero.skill_gap
	hero.skill_uses += 1
	for e in enemies.duplicate():
		if e.pos.distance_to(hero.pos) <= hero.skill_radius:
			damage(e, hero.skill_damage)

# 영웅 스킬 2(S84): 지금 주변 buff_radius칸 안에 있는 용병에게만 버프를 건다(I65). 명령으로만 쓴다
func use_buff() -> void:
	if not hero or not hero.alive or not hero.buff_ready():
		return
	hero.buff_cooldown = hero.buff_gap
	for u in units:
		if u != hero and u.pos.distance_to(hero.pos) <= hero.buff_radius:
			u.boost = hero.buff_mult
			u.boost_left = hero.buff_time

# 빈 칸(구조물·성곽·거점·유닛·적이 없는 맵 안 칸)에 짓는다(I24). 준비 단계엔 바로 완성된다(S18).
# 전투 단계엔 진행률 0의 미완성 구조물을 놓고 놀고 있는 가장 가까운 공병을 보낸다. 그런 공병이 없으면 거부한다(S22, I39, I62)
# 생산 시설은 마을 안에만, 나머지 구조물은 마을 밖에만 짓는다(S43). 생산 시설의 집결 지점 기본값은 출구 칸이다(I61)
# 건설비는 지시하는 순간 내고, 모자라면 거부한다(I16, I17)
func build(kind: String, cell: Vector2i, overrides := {}):
	if state not in ["prep", "battle"] or not grid.is_in_boundsv(cell) or structures.has(cell) or castle.has(cell) or cell == base.cell:
		return null
	if (units + enemies).any(func(u): return Vector2i(u.pos.round()) == cell):
		return null
	var stats: Dictionary = STRUCTURE_KINDS[kind].merged(overrides, true)
	if gold < stats.cost or village.has_point(cell) != (stats.produces != ""):
		return null
	var engineer = _idle_engineer(cell) if state == "battle" else null
	if state == "battle" and not engineer:
		return null
	gold -= stats.cost
	var s := Block.new(cell, kind, stats.hp)
	for key in stats:
		s.set(key, stats[key])
	s.paid = stats.cost
	structures[cell] = s
	if engineer:
		s.progress = 0.0
		s.complete = false
		s.hp = 0.0
		_send(engineer, s)
	if s.produces != "":
		var exit = _exit_of(cell)
		s.rally = exit if exit != null else cell
	_repath = true
	return s

func structure_at(cell: Vector2i):
	return structures.get(cell)

# 전투 단계에만, 생산 시설에서 용병 하나를 산다(S20, I21). 시설 옆 칸에 나타나 집결 지점으로 걸어간다(I61)
# 골드가 모자라거나, 배치 상한에 닿았거나(S25, I23), 시설이 파괴됐으면(S48) 거부한다
func recruit(f):
	if state != "battle" or structures.get(f.cell) != f or f.produces == "" or not f.complete:  # 미완성 시설은 생산하지 않는다(I18)
		return null
	var stats: Dictionary = MERC_KINDS[f.produces]
	var exit = _exit_of(f.cell)
	if exit == null or gold < stats.cost or _mercs() >= merc_cap:
		return null
	gold -= stats.cost
	var m := Unit.new(f.produces, exit, stats)
	m.paid = stats.cost
	units.append(m)
	_to_rally(m, f)
	return m

# 아직 집결 지점에 닿지 않은 그 시설의 용병도 새 집결 지점으로 간다(I22). 0.5칸 안에 들어왔으면 닿은 것이다
func set_rally(f, cell: Vector2i) -> void:
	if not grid.is_in_boundsv(cell):
		return
	var old := Vector2(f.rally)
	f.rally = cell
	for u in units:
		if u.rally_from == f and u.pos.distance_to(old) > 0.5:
			_to_rally(u, f)

func _to_rally(u: Unit, f: Block) -> void:
	order_move([u], f.rally)
	u.rally_from = f

# 시설 옆의 빈 칸. 맵 아래쪽(들판 쪽, S51)부터 본다(I61)
# ponytail: 상하좌우 넷만 본다. 넷이 다 막히면 대각선까지 볼 일
func _exit_of(cell: Vector2i):
	for d in [Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP]:
		var c: Vector2i = cell + d
		if grid.is_in_boundsv(c) and not grid.block_at(c) and c != base.cell:
			return c
	return null

# 전투 단계에만, 미완성 구조물을 없애고 낸 골드를 모두 돌려준다(S23)
func cancel(s) -> void:
	if state == "battle" and not s.complete and structures.get(s.cell) == s:
		_remove(s)
		gold += s.paid

# 전투 단계에만, 짓는 공병이 없는 미완성 구조물에 놀고 있는 가장 가까운 공병을 보낸다(S24, S83)
func resume(s):
	if state != "battle" or s.complete or s.worker or structures.get(s.cell) != s:
		return null
	var engineer = _idle_engineer(s.cell)
	if engineer:
		_send(engineer, s)
	return engineer

# 준비 단계에만, 미완성 구조물을 추가 비용 없이 바로 완성한다(I19)
func finish(s) -> void:
	if state == "prep" and not s.complete and structures.get(s.cell) == s:
		_grow(s, 1.0)

# 전투 단계에만, 철거할 수 있는 구조물마다 놀고 있는 가장 가까운 공병을 보낸다. 그런 공병이 없으면 그 구조물은 거부한다(S74, I64)
func demolish(things: Array) -> void:
	if state != "battle":
		return
	for t in things:
		var engineer = _idle_engineer(t.cell) if can_demolish(t) else null
		if engineer:
			_send(engineer, t)

# 완성된 방벽·타워이고 허무는 공병이 아직 없다. 골드는 돌려주지 않는다(S74). 생산 시설은 철거하지 않는다(I64)
func can_demolish(t) -> bool:
	return t is Block and structures.get(t.cell) == t and t.complete and t.produces == "" and t.worker == null

# things 가운데 판에 남아 있는 미완성 구조물. 화면이 완성·취소·이어 짓기 버튼에 쓴다(S83)
func unfinished(things: Array) -> Array:
	return things.filter(func(t): return t is Block and structures.get(t.cell) == t and not t.complete)

# 놀고 있는 공병(짓거나 허무는 일을 맡지 않은 공병) 가운데 그 칸에 가장 가까운 공병(I39)
func _idle_engineer(cell: Vector2i):
	var best = null
	for u in units:
		if u.kind == "engineer" and u.job == null and (best == null or u.pos.distance_to(Vector2(cell)) < best.pos.distance_to(Vector2(cell))):
			best = u
	return best

# 공병에게 그 구조물 일을 맡기고 옆 칸(대각선 포함)까지 걸어가게 한다(I63)
func _send(u: Unit, s: Block) -> void:
	u.job = s
	u.rally_from = null
	s.worker = u
	grid.wall_k = UNIT_WALL_K
	u.path = grid.get_id_path(Vector2i(u.pos.round()), s.cell, true).slice(1, -1)

# 일하던 공병을 놓아준다. 공병은 그 자리에 서고, 구조물은 그 상태로 남는다(I63)
func _release(s: Block) -> void:
	if s.worker:
		s.worker.job = null
		s.worker.path.clear()
		s.worker = null

func _remove(s: Block) -> void:
	_release(s)
	structures.erase(s.cell)
	s.alive = false
	_repath = true

# 진행률을 dp만큼 올리고 체력을 «최대 체력 × 진행률 − 짓는 동안 입은 피해»로 둔다. 다 차면 완성되고 적 경로를 다시 구한다(I62)
# 체력에 더해 가지 않고 곱해서 구한다. 더하면 오차가 쌓여 다 지어도 최대 체력에 못 미친다(EV48)
func _grow(s: Block, dp: float) -> void:
	var lost := s.max_hp * s.progress - s.hp
	s.progress = minf(s.progress + dp, 1.0)
	s.hp = s.max_hp * s.progress - lost
	if s.progress >= 1.0:
		s.complete = true
		_release(s)
		_repath = true

# 옆 칸에 닿은 공병은 미완성이면 짓고(I62), 완성이면 허문다(I64: 건설 시간의 절반이 든다). 밀려나 멀어졌으면 다시 걸어간다
# ponytail: 닿을 수 없는 칸이면 매 프레임 경로를 다시 구한다. 공병이 많아 느려지면 포기 처리를 둔다
func _work(u: Unit, dt: float) -> void:
	var s: Block = u.job
	if u.pos.distance_to(Vector2(s.cell)) > WORK_REACH:
		_send(u, s)
	elif not s.complete:
		_grow(s, dt / s.build_time)
	else:
		s.razed += dt / (s.build_time / 2.0)
		if s.razed >= 1.0:
			_remove(s)

# 배치 상한에 세는 살아 있는 용병 수(공병 포함, 영웅 제외, I23)
func _mercs() -> int:
	return units.filter(func(u): return u != hero).size()

# 준비 단계에만, 플레이어가 놓은 구조물·용병을 판다(S69). 성곽·영웅 등 나머지는 건너뛴다(I56)
func sell(things: Array) -> void:
	if state != "prep":
		return
	for t in things:
		if t is Block and structures.get(t.cell) == t:
			structures.erase(t.cell)
			_repath = true
		elif t is Unit and t != hero and t in units:
			units.erase(t)
		else:
			continue
		t.alive = false
		gold += refund(t)

# 판매로 돌려받는 골드: 낸 골드 × 남은 체력 비율, 1골드 미만은 버린다(S69, I56)
func refund(t) -> int:
	return floori(t.paid * t.hp / t.max_hp)

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
		gold += target.reward
	elif target is Unit:  # 전장에서 빠진다. 영웅은 다음 준비 단계에 돌아온다(step, S26). 공병이 하던 일은 그 상태로 남는다(S24)
		if target.job:
			_release(target.job)
		units.erase(target)
	else:  # 구조물·성곽: 칸이 비고 경로를 다시 구한다(I5)
		_release(target)
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

# 같은 편(bodies)끼리 겹친 만큼 반씩 밀어낸다. 상대 편(others)과는 겹치지 않게 민다.
# 경로는 그대로라 밀려난 쪽은 _move·_act가 다시 데려간다(I51)
# ponytail: O(n²) 전수 비교, 적이 수백이면 칸 버킷으로
func _push_apart(bodies: Array, others: Array) -> void:
	for i in bodies.size():
		for j in range(i + 1, bodies.size()):
			var a = bodies[i]
			var o = bodies[j]
			var gap: Vector2 = o.pos - a.pos
			var overlap: float = a.radius + o.radius - gap.length()
			if overlap > 0.0:
				var push := (gap.normalized() if gap != Vector2.ZERO else Vector2.RIGHT) * overlap / 2.0
				_shove(a, -push, others)
				_shove(o, push, others)

# 쏘는 구조물은 사거리 안에서 가장 가까운 적을 쏘고(S28, I29), 맞은 적은 그 구조물에 반격한다(S5)
func _fire(dt: float) -> void:
	for s in structures.values():
		if s.range <= 0.0 or not s.complete:  # 미완성 타워는 쏘지 않는다(I18)
			continue
		s.cooldown -= dt
		if s.cooldown > 0.0:
			continue
		var best = _nearest_enemy(Vector2(s.cell), s.range)
		if best:
			s.cooldown = s.fire_gap
			s.target = best
			best.attacker = s
			damage(best, s.damage)

# 유닛은 명령받은 경로를 걷고(S14), 사거리 안의 가장 가까운 적을 친다(S15). 영웅은 걷는 동안에도 친다.
# 용병은 걷는 동안 이동 방식을 따르고(S35, I35), 서 있으면 인식 범위 안의 적을 쫓는다(I36).
# 홀드가 켜진 용병은 서 있는 동안 기준 지점 반경 안의 적만 노리고, 그 반경 밖으로 쫓아가지 않는다(S36)
func _act(u: Unit, dt: float) -> void:
	u.cooldown -= dt
	u.skill_cooldown -= dt
	u.buff_cooldown -= dt
	u.boost_left -= dt
	# 걷는 동안엔 반경을 보지 않는다. 홀드 중 이동 지시를 받으면 도착한 곳이 새 기준이다(I37)
	var zone := u.hold_radius if u.hold and u.path.is_empty() else INF
	var foe = _nearest_enemy(u.pos, u.range, u.anchor, zone)
	var walking := not u.path.is_empty()
	if walking and u != hero:
		if u.move_mode == "move":
			foe = null
		elif foe:  # 이동 중 공격: 멈춰서 친다
			walking = false
	var left := u.speed * dt
	if walking:
		while left > 0.0 and not u.path.is_empty():
			var to := Vector2(u.path[0]) - u.pos
			_shove(u, to.limit_length(left), enemies)
			left -= to.length()  # 적에게 막혀 못 갔어도 줄인다
			var d := u.pos.distance_to(Vector2(u.path[0]))
			# 마지막 칸은 다른 유닛과 몸이 닿은 채 0.5칸 안에 들어도 도착이다. 같은 칸으로 보낸 무리가 서로 밀며 끝없이 걷지 않게(I51)
			var crowded := u.path.size() == 1 and d <= 0.5 and units.any(func(o): return o != u and o.pos.distance_to(u.pos) < u.radius + o.radius + 0.01)
			if d < 0.01 or crowded:
				u.path.remove_at(0)
				if u.path.is_empty():
					u.anchor = u.pos
					u.rally_from = null
	elif not foe:
		# ponytail: 적에게 곧장 다가간다. 벽 너머 적에게는 벽을 따라 미끄러질 뿐이다. 막히는 일이 보이면 경로로
		var prey = _nearest_enemy(u.pos, u.sight, u.anchor, zone)
		if prey:
			var p: Vector2 = u.pos + (prey.pos - u.pos).limit_length(left)
			if u.hold:
				p = u.anchor + (p - u.anchor).limit_length(u.hold_radius)
			_shove(u, p - u.pos, enemies)
	if foe and u.cooldown <= 0.0:
		u.cooldown = u.attack_gap
		u.target = foe
		damage(foe, u.damage * (u.boost if u.boost_left > 0.0 else 1.0))
	if u.job and u.path.is_empty():
		_work(u, dt)

# from에서 reach 안의 가장 가까운 적. center에서 zone보다 먼 적은 뺀다(홀드 반경)
func _nearest_enemy(from: Vector2, reach: float, center := Vector2.ZERO, zone := INF):
	var best = null
	var best_d := reach
	for e in enemies:
		var d: float = e.pos.distance_to(from)
		if d <= best_d and e.pos.distance_to(center) <= zone:
			best = e
			best_d = d
	return best

# 맵 밖이나 막힌 칸·거점 칸으로는 들어가지 않는다. 막히면 한 축으로만 움직여 벽을 따라 미끄러진다
# 2026-10-12
# [동작] bodies(적이 움직이면 유닛, 유닛이 움직이면 적)와 겹치는 자리는 그 몸 바로 바깥 자리로 바꾼 뒤 칸을 검사한다
# [의도] 유닛이 몸으로 적의 길을 막고, 몸이 닿은 적은 그 유닛을 치게 한다(S13, _target_of). 경로에는 유닛을 넣지 않는다(I2)
# [이유] 겹친 뒤 따로 밀어내면, 성벽에 막힌 적이 한 축으로 미끄러지며 한 칸 틈의 용병 옆을 빠져나갔다
#        (test_crowd_cannot_pass_merc_in_one_cell_gap)
# ponytail: 몸 하나씩 차례로 밀어낸다. 몸끼리 붙어 있으면 앞 몸 쪽으로 다시 겹칠 수 있다. 겹친 채 남는 일이 보이면 몇 번 되풀이한다
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
		e.target = target
		damage(target, e.damage)
