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
#   아군 길 나눠 구하기(I309): Battle.UNIT_ROUTES_PER_STEP · 유닛 due(길을 기다리는 목적지 칸, 기다리지 않으면 (-1, -1)) ·
#     Battle._slow(방금 구한 땅 길이 비용 격자에서 나왔다) · Battle._short(길) · Battle.grid.path(from, to)

const DT := 0.05
const BIG := 1000000
const CELL_PX := 16

func battle(over := {}):
	var stage := {
		"size": Vector2i(30, 20), "base": Vector2i(25, 10), "base_hp": 100,
		"spawns": [Vector2i(0, 10)], "gold": BIG, "waves": [], "hero_start": null,
		"muster_first": 1.0e9,  # 평가 판은 다음 웨이브가 저절로 오지 않고 start_battle()(북, S375)을 기다린다 — 옛 준비 단계 자리(I311 ⑤)
		"train_scale": 0.0,  # 평가 판은 전투 중에 산 용병이 바로 나온다(S20 2026-11-17 변경의 대기열은 economy 스위트가 train_scale 1로 잰다, I312)
		# 지형 이점·세 띠(S377)는 평가 판에서 끈다(terrain 스위트가 켜서 잰다): 사거리 보너스 0, 혼잡 ×1, 포위·전장 띠 없음, 노출 블록 무시 끔, 띠 골드 ×1, 밀림·깨우기·사냥꾼·지휘 0.
		# band_rows가 없어 집결 띠도 없다(S375의 잠든 적은 출현 칸에 선다)
		"wall_range_bonus": 0.0, "crowd_slow": 1.0, "surround_from": BIG, "harvest_rows": BIG, "exposed_block_mode": false, "exposed_light": 1.0,
		"bombard_gold": 1.0, "band_gold": 1.0, "band_push": 0.0, "band_wake": 0, "hunts_hero": 0, "command_per": 0.0,
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

# 이 웨이브가 끝날 때까지(끝난 웨이브 수가 오르거나 전투 단계가 끝날 때까지, S17 2026-11-17 변경) 이 웨이브(와 앞 웨이브) 소속으로 나오는 적을 처치한다.
# 라운드 안에서는 웨이브가 끝나도 전투 단계가 이어지고(S375) 다음 웨이브의 적은 그대로 둔다. 라운드의 마지막 웨이브면 라운드 사이·승리가 된다
func clear_wave(b, secs := 120.0) -> bool:
	var done: int = b.waves_done
	return run(b, secs, func():
		for e in b.enemies.duplicate():
			if e.alive and e.wave <= done:
				b.damage(e, BIG)
		return b.state != "battle" or b.waves_done > done)

# 라운드의 남은 웨이브를 모두 처치해 라운드 사이·승리까지 간다. 집결 중인 파도는 북으로 바로 부른다
func clear_round(b, secs := 300.0) -> bool:
	return run(b, secs, func():
		if b.mustering():
			b.drum()
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

# 준비 단계에 kind 용병 n명을 at부터 가로 w칸씩 줄지어 놓는다(아군 길 나눠 구하기 I309의 평가). 하나라도 못 놓으면 빈 배열
func squad(b, kind: String, n: int, at := Vector2i(2, 2), w := 10) -> Array:
	var us := []
	for i in n:
		var m = b.place_merc(kind, at + Vector2i(i % w, i / w))
		if m == null:
			return []
		us.append(m)
	return us

# us 가운데 길을 기다리는 유닛(I309: 유닛 칸 due가 (-1, -1)이 아니다). due 칸이 없는 판에서는 아무도 기다리지 않는다
func in_line(us: Array) -> Array:
	return us.filter(func(u):
		var d = u.get("due")
		return d is Vector2i and d != Vector2i(-1, -1))
