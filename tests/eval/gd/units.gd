extends "res://tests/eval/gd/lib.gd"
# WBS 3.1 적 5종·마법 타워(S11·S106~S111·I43·I76~I78·I81). lib.gd·wall.gd 머리의 계약에 더하는 API:
#   적 kind "fast"(빠름, 성벽 등반) · "armored"(장갑) · "flying"(비행) · "boss"(보스)
#   ENEMY_KINDS[kind] 키: armor(방어력, S149) · flying(비행) · climb(성벽 오르는 시간, 초. 0이면 오르지 않는다)
#   구조물 kind "magic"(마법 타워, 장갑 무시) · 단축키: - 마법 타워 놓기
#   BattleView(res://src/ui/battle_view.gd).ENEMY_COLORS — 적 kind → 색
# 성곽 맵은 wall.gd와 같다: 9행이 가로 성곽(성문 5·15·25열, 모두 닫힘), 위쪽(0~8행)이 마을, 아래쪽이 들판

const TOP := Vector2i(12, 9)  # 성벽 칸
const IN := Vector2i(10, 4)  # 마을 칸
const GATES := [Vector2i(5, 9), Vector2i(15, 9), Vector2i(25, 9)]

# S106 표: kind → [체력, 속도, 피해, 공격 간격, 몸 반지름, 인식 범위, 처치 보상, wall_k(비행은 null)]
const TABLE := {
	"basic": [10, 2, 5, 1, 0.3, 3, 5, 1],
	"fast": [6, 3.5, 3, 0.8, 0.25, 3, 4, 1],
	"armored": [18, 1.5, 6, 1.2, 0.35, 3, 8, 1],
	"flying": [8, 2.5, 4, 1, 0.3, 3, 6, null],
	"boss": [160, 1.2, 20, 2, 0.45, 4, 50, 0.3],
	"slime": [14, 1.5, 4, 1, 0.3, 3, 15, 1],  # 1라운드 슬라임 테마(S106 2026-10-27 변경)
	"slimelet": [5, 2, 2, 0.8, 0.18, 3, 0, 1],
	"big_slime": [30, 1.1, 8, 1.4, 0.45, 3, 35, 1],
	"slime_king": [160, 1, 20, 2, 2.0, 4, 50, 0.3],  # 몸 반지름 2(S236 2026-10-29 변경)
	"wolf": [9, 3, 3, 0.8, 0.25, 3, 5, 1],  # 2라운드 늑대 테마(S106 2026-10-27 변경)
	"leap_wolf": [12, 3, 3, 0.8, 0.25, 3, 7, 1],
	"night_wolf": [12, 2.8, 4, 1, 0.28, 3, 7, 1],
	"alpha_wolf": [160, 2, 20, 1.5, 0.45, 4, 50, 0.3],
}
const PACK := {"wolf": 4, "leap_wolf": 2, "night_wolf": 2}  # 무리(S238). 나머지 종류는 1
const KEYS := ["hp", "speed", "damage", "attack_gap", "radius", "sight", "reward", "wall_k"]

func _castle(gates := GATES, walls = null):
	if walls == null:
		walls = []
		for x in 30:
			if Vector2i(x, 9) not in gates:
				walls.append(Vector2i(x, 9))
	return battle({"base": Vector2i(15, 4), "spawns": [Vector2i(15, 19)], "village": Rect2i(0, 0, 30, 9), "base_hp": BIG,
		"castle": {"walls": walls, "gates": gates, "wall_hp": 300, "gate_hp": 150}})

func _full(b) -> bool:
	return b.castle.values().all(func(k): return k.hp == k.max_hp)

func _on_wall(b, e) -> bool:
	var k = b.castle.get(cell_of(e))
	return k != null and k.kind == "castle_wall"

# 마을에 놓은 용병을 성벽 위 그 칸에 올린다. 못 오르면 null
func _up(b, kind: String, cell: Vector2i):
	var m = b.place_merc(kind, IN)
	b.order_move([m], cell)
	return m if run(b, 30.0, func(): return m.on_wall and near(m.pos, cell)) else null

# 움직이지 않는 과녁
func _still(b, kind: String, cell: Vector2i, over := {}):
	return b.spawn_enemy(kind, cell, ({"speed": 0, "sight": 0, "damage": 0, "hp": BIG} as Dictionary).merged(over, true))

# 첫 번째로 깎인 체력. 깎이지 않으면 -1
func _first_hit(b, e, secs := 5.0) -> float:
	return BIG - e.hp if run(b, secs, func(): return e.hp < e.max_hp) else -1.0

# EV53 · S11: 적 정의마다 무시하는 판정 층은 0개나 1개다(비행·성벽 등반은 경로 층, I80)
func ev53():
	var b = battle()
	for k in b.ENEMY_KINDS:
		var d: Dictionary = b.ENEMY_KINDS[k]
		var n := int(d.get("flying", false)) + int(d.get("climb", 0.0) > 0.0)
		if n > 1:
			return "%s가 판정 층 %d개를 무시한다" % [k, n]
	return ""

# EV130 · S106: 적 5종의 수치가 표와 같다
func ev130():
	var b = battle()
	for k in TABLE:
		if not b.ENEMY_KINDS.has(k):
			return "적 종류 %s가 없다" % k
		for i in KEYS.size():
			var want = TABLE[k][i]
			var got = b.ENEMY_KINDS[k][KEYS[i]]
			if want != null and not is_equal_approx(got, want):
				return "%s.%s = %s, 표는 %s" % [k, KEYS[i], got, want]
	var d: Dictionary = b.ENEMY_KINDS
	var plain: Array = TABLE.keys().filter(func(k): return k != "slime" and k != "big_slime")
	return check(d.fast.climb == 3.0 and d.armored.armor == 15.0 and d.flying.flying and not d.basic.flying and d.basic.climb == 0.0
		and d.slime.get("split") == {"kind": "slimelet", "count": 2} and d.big_slime.get("split") == {"kind": "slime", "count": 2}
		and plain.all(func(k): return d[k].get("split", {}).is_empty()) and d.slime_king.get("boss") == true and d.alpha_wolf.get("boss") == true
		and TABLE.keys().all(func(k): return d[k].get("pack", 1) == PACK.get(k, 1)) and is_equal_approx(d.leap_wolf.climb, 0.8),
		"특수: fast.climb %s · armored.armor %s · flying.flying %s · 갈라짐 %s · boss %s · 무리 %s · leap_wolf.climb %s" % [d.fast.climb, d.armored.armor, d.flying.flying,
			TABLE.keys().map(func(k): return [k, d[k].get("split")]), [d.slime_king.get("boss"), d.alpha_wolf.get("boss")],
			TABLE.keys().map(func(k): return [k, d[k].get("pack")]), d.leap_wolf.climb])

# 방어력 a의 물리 피해 배율(S149, 워크3식): a ≥ 0이면 1 − 0.06a ÷ (1 + 0.06a)
func _armor(a: float) -> float:
	return 1.0 - 0.06 * a / (1.0 + 0.06 * a)

# EV131 · S108: 방어력 15인 장갑 적은 물리 피해를 워크3식 비율만큼 덜 받는다(최소 1 규칙은 없다). 방어력 0인 적은 그대로 받는다
func ev131():
	var b = battle()
	var a = _still(b, "armored", Vector2i(5, 5))
	for amount in [2.0, 6.0, 0.5]:
		var hp0: float = a.hp
		b.damage(a, amount)
		if not is_equal_approx(hp0 - a.hp, amount * _armor(15.0)):
			return "장갑 적이 피해 %s에 %s 깎였다(%s이어야 한다)" % [amount, hp0 - a.hp, amount * _armor(15.0)]
	var n = _still(b, "basic", Vector2i(5, 8))
	b.damage(n, 2.0)
	return check(is_equal_approx(BIG - n.hp, 2.0), "방어력 0인 적이 피해 2에 %s 깎였다" % (BIG - n.hp))

# EV132 · S110: 마법 타워는 마법 피해라 방어력을 무시하고, 타워는 방어력만큼 덜 깎는다
func ev132():
	var got := {}
	for kind in ["magic", "tower"]:
		var b = battle()
		var c := Vector2i(10, 10)
		if b.build(kind, c) == null:
			return "%s를 짓지 못했다" % kind
		got[kind] = _first_hit(b, _still(b, "armored", c + Vector2i(2, 0)))
	return check(is_equal_approx(got.magic, 6.0) and is_equal_approx(got.tower, 2.0 * _armor(15.0)), "한 발에 깎인 체력: 마법 타워 %s(6), 타워 %s(%s)" % [got.magic, got.tower, 2.0 * _armor(15.0)])

# EV133 · S110: - 키 뒤 좌클릭한 들판 칸에 마법 타워가 지어진다
func ev133():
	var b = battle()
	var c = controls(b)
	var ev := InputEventKey.new()
	ev.keycode = KEY_MINUS
	ev.pressed = true
	c.handle(ev)
	var gold0: int = b.gold
	var cell := Vector2i(10, 10)
	click(c, MOUSE_BUTTON_LEFT, px(cell))
	var s = b.structure_at(cell)
	return check(s != null and s.kind == "magic" and gold0 - b.gold == b.STRUCTURE_KINDS.magic.cost, "- 키 뒤 좌클릭: %s, 골드 %d 줄었다(마법 타워 값 %d, 놓기 모드 %s)" % [s, gold0 - b.gold, b.STRUCTURE_KINDS.magic.cost, c.placing])

# EV134 · S109: 비행 적은 닫힌 성곽을 부수지 않고 넘어 거점을 친다
func ev134():
	var b = _castle()
	b.spawn_enemy("flying", Vector2i(12, 19), {"hp": BIG})
	if not run(b, 30.0, func(): return b.base.hp < b.base.max_hp):
		return "비행 적이 거점을 치지 못했다"
	return check(_full(b), "비행 적이 성곽을 깎았다")

# EV135 · S109: 비행 적은 경로 위 용병에 막히지 않는다
func ev135():
	var b = battle()
	var m = b.place_merc("soldier", Vector2i(12, 10), {"damage": 0})
	b.spawn_enemy("flying", Vector2i(5, 10), {"sight": 0, "hp": BIG})
	if not run(b, 30.0, func(): return b.base.hp < b.base.max_hp):
		return "비행 적이 거점에 닿지 못했다(용병 %s)" % m.pos
	return check(m.hp == m.max_hp, "비행 적이 길 위 용병을 쳤다(체력 %s)" % m.hp)

# EV136 · S109: 비행 적도 근접 용병·타워·대포 범위 피해에 맞는다
func ev136():
	var b = battle()
	b.place_merc("soldier", Vector2i(10, 10))
	if _first_hit(b, _still(b, "flying", Vector2i(11, 10))) <= 0.0:
		return "근접 용병이 비행 적을 치지 못했다"
	b = battle()
	b.build("tower", Vector2i(10, 8))
	if _first_hit(b, _still(b, "flying", Vector2i(10, 10))) <= 0.0:
		return "타워가 비행 적을 쏘지 못했다"
	b = battle()
	b.build("cannon", Vector2i(10, 8))
	_still(b, "basic", Vector2i(10, 11))  # 대포가 노리는 더 가까운 적
	return check(_first_hit(b, _still(b, "flying", Vector2i(11, 11))) > 0.0, "대포 범위 피해가 비행 적에 닿지 않았다")

# EV137 · I77: 비행 적은 인식 범위 안 성벽 위 궁수를 친다
func ev137():
	var b = _castle()
	var m = _up(b, "archer", TOP)
	if m == null:
		return "궁수가 성벽에 오르지 못했다"
	b.spawn_enemy("flying", TOP + Vector2i(0, 3), {"hp": BIG})
	return check(run(b, 15.0, func(): return m.hp < m.max_hp), "비행 적이 성벽 위 궁수를 치지 않았다")

# EV138 · S107: 빠름 적은 닫힌 성곽을 부수지 않고 넘어 거점을 친다
func ev138():
	var b = _castle()
	var e = b.spawn_enemy("fast", Vector2i(12, 19), {"hp": BIG})
	if not run(b, 40.0, func(): return b.base.hp < b.base.max_hp):
		return "빠름 적이 거점을 치지 못했다(%s)" % e.pos
	return check(_full(b), "빠름 적이 성곽을 깎았다")

# EV139 · S107: 성벽 앞의 빠름 적은 3초를 들여 성벽 칸 위에 올라선다
func ev139():
	var b = _castle()
	var e = b.spawn_enemy("fast", TOP + Vector2i(0, 1), {"hp": BIG, "sight": 0})
	if run(b, 2.5, func(): return _on_wall(b, e)):
		return "2.5초 안에 성벽 칸 위에 올라섰다"
	return check(run(b, 2.0, func(): return _on_wall(b, e)), "4.5초가 지나도 성벽 칸 위에 올라서지 않았다(%s)" % e.pos)

# EV140 · I76: 닫힌 성문은 기어오르지 않고 부순다
func ev140():
	var gates := []
	for x in 30:
		gates.append(Vector2i(x, 9))
	var b = _castle(gates, [])
	b.spawn_enemy("fast", Vector2i(15, 15), {"hp": BIG, "sight": 0})
	if not run(b, 20.0, func(): return not _full(b)):
		return "빠름 적이 닫힌 성문을 부수지 않았다"
	return check(b.base.hp == b.base.max_hp, "성문을 부수기 전에 거점에 닿았다")

# EV141 · I43: 들판의 방벽은 기어오르지 않고 부순다
func ev141():
	var b = battle()
	var cells := ring(b.base.cell)
	for c in cells:
		b.build("wall", c)
	b.spawn_enemy("fast", Vector2i(0, 10), {"hp": BIG, "sight": 0})
	return check(run(b, 30.0, func(): return not intact(b, cells)), "빠름 적이 방벽을 부수지 않았다")

# EV142 · I77: 빠름 적은 성벽에 올라 인식 범위 안 성벽 위 궁수를 친다
func ev142():
	var b = _castle()
	var m = _up(b, "archer", TOP)
	if m == null:
		return "궁수가 성벽에 오르지 못했다"
	var e = b.spawn_enemy("fast", TOP + Vector2i(0, 3), {"hp": BIG})
	if not run(b, 15.0, func(): return m.hp < m.max_hp):
		return "빠름 적이 성벽 위 궁수를 치지 않았다(%s)" % e.pos
	return check(_on_wall(b, e), "빠름 적이 성벽에 오르지 않고 궁수를 쳤다(%s)" % e.pos)

# EV143 · I78: 성벽 위의 적은 성벽 위 근접 용병이 친다
func ev143():
	var b = _castle()
	var m = _up(b, "soldier", TOP)
	if m == null:
		return "용병이 성벽에 오르지 못했다"
	var e = b.spawn_enemy("fast", TOP + Vector2i(0, 3), {"hp": BIG, "damage": 0})
	var ground_hp := [e.hp]  # 성벽 위로 올라서기 직전 프레임의 체력. 올라선 프레임 안에서 바로 맞을 수 있다
	if not run(b, 15.0, func():
		if not _on_wall(b, e):
			ground_hp[0] = e.hp
		return _on_wall(b, e)):
		return "빠름 적이 성벽에 오르지 않았다(%s)" % e.pos
	if ground_hp[0] < e.max_hp:
		return "성벽 위 근접 용병이 땅의 적을 쳤다(S88)"
	return check(run(b, 3.0, func(): return e.hp < e.max_hp), "성벽 위 근접 용병이 성벽 위 적을 치지 않았다")

# EV144 · S111: 시험 스테이지의 시작 골드와 웨이브
func ev144():
	var stage: Dictionary = load("res://src/main.gd").stage()
	var want := [{"slime": 30}, {"slime": 20, "big_slime": 8}, {"slime": 30, "big_slime": 12, "slime_king": 1}]  # S111 2026-10-27 변경: 1라운드 슬라임 테마
	var got := []
	for w in stage.waves:
		var d := {}
		for entry in w:
			d[entry.kind] = d.get(entry.kind, 0) + entry.count
		got.append(d)
	return check(stage.gold == 1000 and got == want, "시작 골드 %s, 웨이브 %s" % [stage.gold, got])

# EV145 · I81: 적 종류(TABLE, S106)의 색이 모두 있고 서로 다르다
func ev145():
	var colors: Dictionary = load("res://src/ui/battle_view.gd").ENEMY_COLORS
	var seen := []
	for k in TABLE:
		if not colors.has(k):
			return "적 %s의 색이 없다" % k
		if colors[k] in seen:
			return "적 %s의 색이 다른 적과 같다" % k
		seen.append(colors[k])
	return ""
