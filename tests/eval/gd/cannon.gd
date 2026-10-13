extends "res://tests/eval/gd/lib.gd"
# WBS 2.21 대포(S43·S44·S90~S93·I72~I74). lib.gd·engineer.gd·wall.gd 머리의 계약에 더하는 API:
#   구조물 kind "cannon"(대포) · 구조물: razed(철거 진행률 0~1. 옮기는 대포는 1이면 접혀 새 칸으로 가는 중이다)
#   Battle.move_cannon(대포, 칸) — 전투 단계에, 놀고 있는 가장 가까운 공병을 보내 대포를 그 칸으로 옮긴다
#   Controls.moving — 옮길 대포. 팝업의 «옮기기» 버튼이 넣는다. 그동안 좌클릭한 칸으로 옮기기를 지시하고 비운다
#   Controls.handle(KEY_8 눌림) — 대포 놓기 모드
# 맵: wall.gd와 같다. 9행이 가로 성곽(성문 5·15·25열), 위쪽(0~8행)이 마을, 아래쪽이 들판

const MAIN := Vector2i(15, 9)  # 정문
const TOP := Vector2i(12, 9)  # 성벽 칸
const IN := Vector2i(10, 4)  # 마을 칸
const A := Vector2i(20, 14)  # 들판 칸
const B := Vector2i(26, 14)  # 들판 칸(A에서 6칸)
const NEAR := Vector2i(20, 16)  # 공병 자리

func _battle():
	var gates := [Vector2i(5, 9), MAIN, Vector2i(25, 9)]
	var walls := []
	for x in 30:
		if Vector2i(x, 9) not in gates:
			walls.append(Vector2i(x, 9))
	return battle({"base": Vector2i(15, 4), "spawns": [Vector2i(15, 19)], "village": Rect2i(0, 0, 30, 9), "base_hp": BIG,
		"castle": {"walls": walls, "gates": gates, "wall_hp": 300, "gate_hp": 150},
		"waves": [[{"kind": "basic", "count": 1}], [{"kind": "basic", "count": 1}]]})

# 전투 단계를 연다. 웨이브 적은 바로 처치하고, 움직이지도 치지도 않는 적 하나를 구석에 남겨 전투 단계가 이어지게 한다
func _start(b):
	b.start_battle()
	run(b, 5.0, func(): return not b.enemies.is_empty())
	var idle = b.spawn_enemy("basic", Vector2i(0, 19), {"speed": 0, "sight": 0, "damage": 0})
	for x in b.enemies.duplicate():
		if x != idle:
			b.damage(x, BIG)
	return idle

# 움직이지도 치지도 않는 과녁
func _dummy(b, cell: Vector2i):
	return b.spawn_enemy("basic", cell, {"speed": 0, "sight": 0, "damage": 0, "hp": BIG})

func _key(c, key: int) -> void:
	var ev := InputEventKey.new()
	ev.keycode = key
	ev.pressed = true
	c.handle(ev)

# 준비 단계에 A에 대포를 짓고 NEAR에 공병을 둔 뒤 전투 단계를 연다
func _moving_setup(b):
	var s = b.build("cannon", A)
	var e = b.place_merc("engineer", NEAR)
	_start(b)
	return [s, e]

# EV98 · S90: 한 발에 맞은 적과 그 1칸 안의 적이 같은 피해를 입고, 그보다 먼 적은 그대로다
func ev98():
	var b = _battle()
	var c := Vector2i(12, 12)
	if b.build("cannon", c) == null:
		return "들판에 대포를 짓지 못했다"
	var hit = _dummy(b, c + Vector2i(0, 3))  # 가장 가깝다
	var side = _dummy(b, c + Vector2i(1, 3))  # hit에서 1칸
	var far = _dummy(b, c + Vector2i(-2, 3))  # hit에서 2칸
	if not run(b, 5.0, func(): return hit.hp < hit.max_hp):
		return "대포가 쏘지 않았다"
	var dmg: float = b.STRUCTURE_KINDS.cannon.damage
	return check(hit.hp == BIG - dmg and side.hp == BIG - dmg and far.hp == BIG,
		"피해 %s · 맞은 적 %s · 1칸 옆 %s · 2칸 옆 %s" % [dmg, BIG - hit.hp, BIG - side.hp, BIG - far.hp])

# EV99 · I73: 범위 피해만 입은 적도 대포에 반격한다
func ev99():
	var b = _battle()
	var c := Vector2i(12, 12)
	var s = b.build("cannon", c)
	if s == null:
		return "들판에 대포를 짓지 못했다"
	_dummy(b, c + Vector2i(0, 3))
	var m = b.spawn_enemy("basic", c + Vector2i(1, 3), {"speed": 0, "sight": 0, "hp": BIG})
	if not run(b, 5.0, func(): return m.hp < m.max_hp):
		return "범위 피해가 1칸 뒤 적에 닿지 않았다"
	m.speed = 2.0
	return check(run(b, 30.0, func(): return s.hp < s.max_hp), "범위로 맞은 적이 대포를 치지 않았다(적 %s)" % m.pos)

# EV100 · S43: 성벽 칸에는 대포만 짓는다. 성문·마을에는 대포를 짓지 못한다
func ev100():
	var b = _battle()
	if b.build("cannon", TOP) == null:
		return "성벽 칸에 대포를 짓지 못했다"
	if b.build("cannon", MAIN) != null:
		return "성문 칸에 대포가 지어졌다"
	if b.build("tower", TOP + Vector2i(1, 0)) != null or b.build("wall", TOP + Vector2i(2, 0)) != null:
		return "성벽 칸에 타워나 방벽이 지어졌다"
	if b.build("cannon", IN) != null:
		return "마을 칸에 대포가 지어졌다"
	return check(b.build("cannon", A) != null, "들판에 대포를 짓지 못했다")

# EV101 · I72: 성벽 위 대포가 들판 적을 쏘고, 반격하러 온 근접 적은 대포 대신 성벽을 친다
func ev101():
	var b = _battle()
	var s = b.build("cannon", TOP)
	if s == null:
		return "성벽 칸에 대포를 짓지 못했다"
	var k = b.castle[TOP]
	var m = b.spawn_enemy("basic", TOP + Vector2i(0, 4), {"sight": 0, "hp": BIG})
	if not run(b, 30.0, func(): return k.hp < k.max_hp):
		return "성벽 체력이 그대로다(적 %s, 적 체력 %s/%s)" % [m.pos, m.hp, m.max_hp]
	return check(m.hp < m.max_hp and s.hp == s.max_hp, "적 체력 %s/%s · 대포 체력 %s/%s" % [m.hp, m.max_hp, s.hp, s.max_hp])

# EV102 · S93: 성벽 위 대포가 부서져도 성벽 칸은 체력 그대로 남는다
func ev102():
	var b = _battle()
	var s = b.build("cannon", TOP)
	if s == null:
		return "성벽 칸에 대포를 짓지 못했다"
	var k = b.castle[TOP]
	b.damage(s, BIG)
	run(b, 0.5)
	return check(b.structure_at(TOP) == null and b.castle.get(TOP) == k and k.hp == k.max_hp,
		"대포 %s · 성벽 칸 %s(체력 %s/%s)" % [b.structure_at(TOP), b.castle.get(TOP), k.hp, k.max_hp])

# EV103 · I72: 대포가 선 성벽 칸이 부서지면 대포도 사라진다
func ev103():
	var b = _battle()
	var s = b.build("cannon", TOP)
	if s == null:
		return "성벽 칸에 대포를 짓지 못했다"
	b.damage(b.castle[TOP], BIG)
	run(b, 0.5)
	return check(b.structure_at(TOP) == null and not s.alive, "성벽 칸이 부서졌는데 대포가 남았다")

# EV104 · S44: 옮기기는 골드가 들지 않고, 공병이 철거한 뒤 새 칸에 다시 짓는다. 입은 피해는 그대로다
func ev104():
	var b = _battle()
	var s = b.build("cannon", A)
	b.damage(s, 30.0)
	var before: float = s.hp
	b.place_merc("engineer", NEAR)
	_start(b)
	var gold: int = b.gold
	b.move_cannon(s, B)
	if b.gold != gold or b.structure_at(A) != s:
		return "지시 직후 골드 %d(전 %d), 원래 칸 %s" % [b.gold, gold, b.structure_at(A)]
	if not run(b, 60.0, func(): return b.structure_at(B) == s and s.complete):
		return "새 칸에 완성되지 않았다(새 칸 %s, 진행률 %.2f)" % [b.structure_at(B), s.progress]
	return check(b.structure_at(A) == null and absf(s.hp - before) < 0.01 and b.gold == gold,
		"원래 칸 %s · 체력 %s(옮기기 전 %s) · 골드 %d" % [b.structure_at(A), s.hp, before, b.gold])

# EV105 · S91: 대포를 클릭하고 «옮기기»를 누른 뒤 성벽 칸을 클릭하면 그 성벽 칸으로 옮긴다
func ev105():
	var b = _battle()
	var c = controls(b)
	var s = b.build("cannon", A)
	b.place_merc("engineer", NEAR)
	_start(b)
	click(c, MOUSE_BUTTON_LEFT, px(A))
	if c.picked != [s]:
		return "대포를 클릭해도 고르지 못했다(%s)" % [c.picked]
	c.moving = c.picked[0]  # «옮기기» 버튼
	click(c, MOUSE_BUTTON_LEFT, px(TOP))
	if c.moving != null:
		return "칸을 클릭한 뒤에도 옮기기 모드다"
	return check(run(b, 90.0, func(): return b.structure_at(TOP) == s and s.complete),
		"성벽 칸에 완성되지 않았다(성벽 칸 %s, 원래 칸 %s)" % [b.structure_at(TOP), b.structure_at(A)])

# EV106 · I74: 철거를 끝내고 새 칸으로 가던 공병이 죽으면 대포는 원래 칸에 완성된 채 남는다
func ev106():
	var b = _battle()
	var se = _moving_setup(b)
	var s = se[0]
	b.move_cannon(s, B)
	if not run(b, 30.0, func(): return s.razed >= 1.0):
		return "철거가 끝나지 않았다(%.2f)" % s.razed
	b.damage(se[1], BIG)
	run(b, 1.0)
	return check(b.structure_at(A) == s and s.complete and b.structure_at(B) == null,
		"원래 칸 %s · 완성 %s · 새 칸 %s" % [b.structure_at(A), s.complete, b.structure_at(B)])

# EV107 · I74: 새 칸에서 다시 짓던 공병이 죽으면 대포는 새 칸에 미완성으로 남는다
func ev107():
	var b = _battle()
	var se = _moving_setup(b)
	var s = se[0]
	b.move_cannon(s, B)
	if not run(b, 60.0, func(): return b.structure_at(B) == s and s.progress > 0.0):
		return "새 칸에서 다시 짓기 시작하지 않았다"
	b.damage(se[1], BIG)
	run(b, 1.0)
	return check(b.structure_at(B) == s and not s.complete and b.structure_at(A) == null,
		"새 칸 %s · 완성 %s · 원래 칸 %s" % [b.structure_at(B), s.complete, b.structure_at(A)])

# EV108 · S44: 타워는 옮기지 않고, 준비 단계에는 대포도 옮기지 않는다
func ev108():
	var b = _battle()
	var s = b.build("cannon", A)
	var t = b.build("tower", A + Vector2i(0, -2))
	var e = b.place_merc("engineer", NEAR)
	b.move_cannon(s, B)
	run(b, 1.0)
	if b.structure_at(A) != s or b.structure_at(B) != null or e.job != null:
		return "준비 단계에 대포 옮기기가 지시됐다"
	_start(b)
	b.move_cannon(t, B)
	run(b, 1.0)
	return check(b.structure_at(t.cell) == t and b.structure_at(B) == null and e.job == null, "타워 옮기기가 지시됐다(공병 일 %s)" % e.job)

# EV109 · S92: 8 키로 대포를 놓는다
func ev109():
	var b = _battle()
	var c = controls(b)
	_key(c, KEY_8)
	click(c, MOUSE_BUTTON_LEFT, px(A))
	var s = b.structure_at(A)
	return check(s != null and s.kind == "cannon", "8 키 뒤 좌클릭한 칸 %s(놓기 모드 %s)" % [s, c.placing])
