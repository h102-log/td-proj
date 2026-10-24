extends RefCounted
# EVAL 공용 헬퍼. 시뮬레이션을 화면 없이 돌린다.
#
# 이 테스트가 전제하는 API (W1 구현이 맞춰야 할 계약):
#   Battle  res://src/sim/battle.gd   Battle.new(stage: Dictionary)
#     stage 키: size, base, base_hp, spawns, gold, waves, hero_start(null이면 영웅 없음)
#     waves: [[{kind, count}, ...], ...]  웨이브 하나 = 항목 배열
#     state "prep" | "battle" | "won" | "lost" · wave_index · gold · revive · base · hero · enemies
#     step(dt) · start_battle() · restart() · damage(대상, 양)
#     build(kind, cell, overrides={}) -> 구조물|null · structure_at(cell) -> 구조물|null
#     spawn_enemy(kind, cell, overrides={}) -> 적 · place_merc(kind, cell, overrides={}) -> 용병|null
#     order_move(units, cell, attack=false) · order_attack(units, 적) · stop(units) · set_hold(units, on)
#     signal enemy_spawned(enemy)
#   유닛: pos(Vector2, 칸 단위, 칸 (x,y)의 중심 = Vector2(x,y)) · hp · max_hp · alive
#   적: reward · 영웅: present · skill_uses · 구조물: cell · hp · max_hp · complete · Battle.can_cast(영웅, 칸)(heroes.gd 머리)
#   Controls res://src/ui/controls.gd  Controls.new(battle, cell_px) · handle(event) · selected
#   kind: 적 "basic" · 용병 "soldier" · 구조물 "wall" "tower"
#   overrides 키: 적 sight·wall_k·hp·speed·damage / 용병 hp·damage·range·sight·hold_radius / 타워 range·damage

const DT := 0.05
const BIG := 1000000
const CELL_PX := 16

func battle(over := {}):
	var stage := {
		"size": Vector2i(30, 20), "base": Vector2i(25, 10), "base_hp": 100,
		"spawns": [Vector2i(0, 10)], "gold": BIG, "waves": [], "hero_start": null,
	}
	stage.merge(over, true)
	return load("res://src/sim/battle.gd").new(stage)

func controls(b):
	return load("res://src/ui/controls.gd").new(b, CELL_PX)

# cond가 참이 될 때까지 시뮬레이션을 돌린다. cond가 없으면 secs만큼 돌리고 true.
func run(b, secs: float, cond := Callable()) -> bool:
	var t := 0.0
	while t < secs:
		if cond.is_valid() and cond.call():
			return true
		b.step(DT)
		t += DT
	return not cond.is_valid() or cond.call()

# 전투 단계가 끝날 때까지 나오는 적을 모두 처치한다
func clear_wave(b, secs := 120.0) -> bool:
	return run(b, secs, func():
		kill_all(b)
		return b.state != "battle")

func kill_all(b) -> void:
	for e in b.enemies.duplicate():
		if e.alive:
			b.damage(e, BIG)

func cell_of(u) -> Vector2i:
	return Vector2i(u.pos.round())

func near(pos: Vector2, cell: Vector2i, tol := 0.5) -> bool:
	return pos.distance_to(Vector2(cell)) <= tol

func at_base(b, e) -> bool:
	return e.pos.distance_to(Vector2(b.base.cell)) <= 1.5

# 칸들의 구조물이 모두 남아 있고 체력이 가득한가
func intact(b, cells: Array) -> bool:
	return cells.all(func(c):
		var s = b.structure_at(c)
		return s != null and s.hp == s.max_hp)

func ring(center: Vector2i) -> Array:
	var cells := []
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx != 0 or dy != 0:
				cells.append(center + Vector2i(dx, dy))
	return cells

func px(cell: Vector2i) -> Vector2:
	return Vector2(cell) * CELL_PX + Vector2(CELL_PX, CELL_PX) / 2.0

func click(c, button: int, p: Vector2) -> void:
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = button
		ev.pressed = pressed
		ev.position = p
		c.handle(ev)

func drag(c, from: Vector2, to: Vector2) -> void:
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = from
	c.handle(down)
	var move := InputEventMouseMotion.new()
	move.position = to
	move.button_mask = MOUSE_BUTTON_MASK_LEFT
	c.handle(move)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = to
	c.handle(up)

func check(ok: bool, why: String) -> String:
	return "" if ok else why
