extends "res://tests/eval/gd/lib.gd"
# WBS 3.8 도전 구조(S61·S63·S64·S79·S117·I46·I67·I91~I93). lib.gd·repair.gd 머리의 계약에 더하는 API:
#   stage 키 rounds: [웨이브 배열, …] — 라운드마다 waves와 같은 모양이다. 없으면 [waves] 한 라운드짜리 도전이다
#   Battle.rounds · Battle.round_index(0부터) — Battle.waves는 지금 라운드의 웨이브다
#   state "cleared" — 마지막이 아닌 라운드를 이긴 «라운드 사이»(S117). 마지막 라운드를 이기면 "won"이다
#   Battle.next_round() -> bool — 라운드 사이에서 다음 라운드의 첫 준비 단계로 넘어간다. 라운드 사이가 아니면 거부한다(false)
#   Battle.restart() — 새 도전(S64, I92)
#   Battle.set_gate(성문, 열기) · Battle.upgrade(성곽 칸) · Battle.raise_village() -> bool · 영웅: present
# 성곽 맵은 repair.gd와 같다: 9행이 가로 성곽(성문 5·15·25열, 모두 닫힘), 위쪽(0~8행)이 마을, 아래쪽이 들판

const TOP := Vector2i(12, 9)  # 성곽 맵의 성벽 칸
const GATES := [Vector2i(5, 9), Vector2i(15, 9), Vector2i(25, 9)]
const T := Vector2i(12, 12)  # 성곽 맵의 들판 칸(타워)
const W := Vector2i(20, 12)  # 성곽 맵의 들판 칸(방벽)
const M := Vector2i(3, 15)  # 성곽 맵의 들판 칸(용병). 적의 길(15열)에서 멀다
const H := Vector2i(20, 14)  # 성곽 맵의 영웅 시작 칸
const BARRACKS := Vector2i(10, 3)  # 마을 칸
const HOUSE := Vector2i(6, 3)
const ONE := [{"kind": "basic", "count": 1}]
const ONE_ONE := [[ONE], [ONE]]  # 라운드 2개, 라운드마다 적 1마리짜리 웨이브 하나
const S111 := [{"basic": 6, "fast": 3}, {"basic": 6, "armored": 3, "flying": 3}, {"basic": 8, "fast": 4, "armored": 3, "flying": 3, "boss": 1}]
# I91 표(2026-10-21 개정): 2~6라운드 웨이브마다 종류별 적 수
const I91 := [
	[{"basic": 18, "fast": 8, "flying": 6}, {"basic": 18, "armored": 8, "flying": 10, "fast": 4}, {"basic": 18, "fast": 8, "armored": 8, "flying": 6}, {"basic": 22, "fast": 12, "armored": 8, "flying": 10, "boss": 1}],
	[{"basic": 22, "fast": 10, "flying": 8}, {"basic": 22, "armored": 10, "flying": 12, "fast": 6}, {"basic": 22, "fast": 10, "armored": 10, "flying": 8}, {"basic": 28, "fast": 14, "armored": 10, "flying": 12, "boss": 1}],
	[{"basic": 22, "fast": 12, "flying": 8}, {"basic": 24, "armored": 10, "flying": 12, "fast": 6}, {"basic": 24, "fast": 12, "armored": 10, "flying": 8}, {"basic": 30, "fast": 16, "armored": 10, "flying": 12, "boss": 1}],
	[{"basic": 24, "fast": 12, "flying": 10}, {"basic": 24, "armored": 12, "flying": 14, "fast": 6}, {"basic": 24, "fast": 12, "armored": 12, "flying": 10}, {"basic": 32, "fast": 16, "armored": 12, "flying": 14, "boss": 2}],
	[{"basic": 26, "fast": 14, "flying": 10}, {"basic": 26, "armored": 12, "flying": 14, "fast": 8}, {"basic": 26, "fast": 14, "armored": 12, "flying": 10}, {"basic": 36, "fast": 18, "armored": 12, "flying": 14, "boss": 2}],
]

func _castle(over := {}):
	var walls := []
	for x in 30:
		if Vector2i(x, 9) not in GATES:
			walls.append(Vector2i(x, 9))
	var stage := {"base": Vector2i(15, 4), "spawns": [Vector2i(15, 19)], "village": Rect2i(0, 0, 30, 9), "base_hp": BIG,
		"castle": {"walls": walls, "gates": GATES, "wall_hp": 300, "gate_hp": 150}, "rounds": ONE_ONE}
	stage.merge(over, true)
	return battle(stage)

# 지금 라운드의 웨이브를 모두 이긴다. 라운드 사이나 승리가 되면 참
func _win_round(b) -> bool:
	for i in 20:
		if b.state != "prep":
			break
		b.start_battle()
		if not clear_wave(b):
			return false
	return b.state in ["cleared", "won"]

func _key(c, key: int) -> void:
	var ev := InputEventKey.new()
	ev.keycode = key
	ev.pressed = true
	c.handle(ev)

# 표의 보스를 뺀 적 수를 10배 한 값(S111·I91 2026-10-25 변경)
func _ten(table: Array) -> Array:
	var out := []
	for w in table:
		var d := {}
		for k in w:
			d[k] = w[k] if k == "boss" else w[k] * 10
		out.append(d)
	return out

# 웨이브마다 {적 종류: 수}
func _counts(waves: Array) -> Array:
	var out := []
	for w in waves:
		var d := {}
		for entry in w:
			d[entry.kind] = d.get(entry.kind, 0) + entry.count
		out.append(d)
	return out

# EV159 · S63: 지은 구조물, 성곽 업그레이드, 마을 레벨이 다음 라운드로 그대로 이어진다
func ev159():
	var b = _castle()
	var built := [b.build("tower", T), b.build("wall", W), b.build("barracks", BARRACKS), b.build("house", HOUSE)]
	if built.has(null):
		return "준비 단계에 짓지 못한 것이 있다(%s)" % [built]
	var k = b.castle[TOP]
	b.upgrade(k)
	if k.level != 2 or not b.raise_village():
		return "성벽 칸 업그레이드(%d단계)나 마을 레벨 올리기가 되지 않았다" % k.level
	if not _win_round(b) or not b.next_round():
		return "1라운드를 이기고 다음 라운드로 넘어가지 못했다(%s)" % b.state
	var kept: bool = built.all(func(s): return s.alive and s.complete and b.structure_at(s.cell) == s)
	return check(kept and b.castle.get(TOP) == k and k.level == 2 and b.village_level == 2 and b.round_index == 1 and b.wave_index == 0 and b.state == "prep",
		"구조물 유지 %s · 성벽 칸 %d단계 · 마을 Lv%d · 라운드 %d · 웨이브 %d · %s" % [kept, k.level, b.village_level, b.round_index + 1, b.wave_index + 1, b.state])

# EV160 · S79: 깎인 체력은 회복되지 않고, 살아 있는 용병은 그 자리에 남는다
func ev160():
	var b = _castle({"base_hp": 100})
	var t = b.build("tower", T)
	var m = b.place_merc("soldier", M)
	var k = b.castle[TOP]
	b.damage(t, 10)
	b.damage(k, 50)
	b.damage(b.base, 20)
	b.damage(m, 5)
	var want := [t.hp, k.hp, b.base.hp, m.hp]
	if not _win_round(b):
		return "1라운드를 이기지 못했다(%s)" % b.state
	var at: Vector2 = m.pos
	if not b.next_round():
		return "다음 라운드로 넘어가지 못했다(%s)" % b.state
	run(b, 1.0)
	var got := [t.hp, k.hp, b.base.hp, m.hp]
	return check(got == want and m.alive and m in b.units and m.pos.distance_to(at) < 0.1,
		"체력(타워·성벽 칸·거점·용병) %s → %s · 용병 %s → %s" % [want, got, at, m.pos])

# EV161 · S61: 남은 골드가 다음 라운드로 이어진다
func ev161():
	var b = battle({"gold": 100, "base_hp": BIG, "rounds": ONE_ONE})
	if b.place_merc("soldier", Vector2i(20, 3)) == null:
		return "용병을 사지 못했다"
	if not _win_round(b) or not b.next_round():
		return "1라운드를 이기고 다음 라운드로 넘어가지 못했다(%s)" % b.state
	var want: int = 100 - b.MERC_KINDS.soldier.cost + b.ENEMY_KINDS.basic.reward
	return check(b.gold == want, "2라운드 골드가 %d다(%d여야 한다)" % [b.gold, want])

# EV162 · I46: 라운드 사이가 될 때 세금을 걷고, 다음 라운드로 넘어갈 때는 다시 걷지 않는다
func ev162():
	var b = battle({"village": Rect2i(0, 0, 30, 6), "base_hp": BIG, "rounds": ONE_ONE})
	if b.build("house", Vector2i(10, 3)) == null or b.build("house", Vector2i(14, 3)) == null:
		return "집을 짓지 못했다"
	var gold0: int = b.gold
	if not _win_round(b) or b.state != "cleared":
		return "1라운드를 이겨 라운드 사이가 되지 않았다(%s)" % b.state
	var want: int = b.ENEMY_KINDS.basic.reward + 2 * b.STRUCTURE_KINDS.house.tax
	var at_clear: int = b.gold - gold0
	b.next_round()
	return check(at_clear == want and b.gold - gold0 == want, "라운드 사이 +%d, 다음 라운드 +%d골드(둘 다 +%d여야 한다)" % [at_clear, b.gold - gold0, want])

# EV163 · S117: 라운드를 이기면 라운드 사이가 되고, 다음 라운드로 넘어가야 다음 라운드의 준비 단계가 된다
func ev163():
	var b = battle({"base_hp": BIG, "rounds": [[ONE, ONE], [ONE]]})
	var seq := [b.state]
	for i in 2:
		b.start_battle()
		seq.append(b.state)
		clear_wave(b)
		seq.append(b.state)
	b.start_battle()  # 라운드 사이에는 거부된다
	seq.append(b.state)
	b.next_round()
	seq.append(b.state)
	var refused: bool = not b.next_round() and b.round_index == 1 and b.state == "prep"  # 준비 단계에서는 거부된다
	b.start_battle()
	seq.append(b.state)
	clear_wave(b)
	seq.append(b.state)
	var want := ["prep", "battle", "prep", "battle", "cleared", "cleared", "prep", "battle", "won"]
	return check(seq == want and refused, "단계 순서 %s · 준비 단계에서 다음 라운드 거부 %s" % [seq, refused])

# EV164 · S117: 라운드 사이에는 맵 명령을 받지 않는다
func ev164():
	var b = _castle({"hero_start": H})
	var m = b.place_merc("soldier", M)
	var c = controls(b)
	click(c, MOUSE_BUTTON_LEFT, px(M))  # 준비 단계의 좌클릭은 용병을 고른다
	if c.selected != [m]:
		return "용병을 고르지 못했다(%s)" % [c.selected]
	if not _win_round(b) or b.state != "cleared":
		return "1라운드를 이겨 라운드 사이가 되지 않았다(%s)" % b.state
	var at: Vector2 = m.pos
	click(c, MOUSE_BUTTON_RIGHT, px(M + Vector2i(0, -3)))
	_key(c, KEY_Q)
	var g = b.castle[GATES[0]]
	b.set_gate(g, true)
	run(b, 3.0)
	return check(m.pos.distance_to(at) < 0.1 and b.hero.skill_uses == 0 and not g.open,
		"용병 %s → %s · 스킬 %d번 · 성문 열림 %s" % [at, m.pos, b.hero.skill_uses, g.open])

# EV165 · S64: 2라운드에서 지면 도전이 끝나고, 새 도전은 1라운드 처음 상태에서 시작한다
func ev165():
	var b = battle({"gold": 500, "rounds": ONE_ONE})
	if b.build("wall", Vector2i(10, 3)) == null or b.place_merc("soldier", Vector2i(20, 3)) == null:
		return "방벽을 짓거나 용병을 사지 못했다"
	if not _win_round(b) or not b.next_round():
		return "1라운드를 이기고 다음 라운드로 넘어가지 못했다(%s)" % b.state
	b.start_battle()
	b.damage(b.base, BIG)
	var lost: bool = b.state == "lost"
	var stuck: bool = not b.next_round() and b.state == "lost"
	b.restart()
	var fresh: bool = b.round_index == 0 and b.wave_index == 0 and b.state == "prep" and b.gold == 500 and b.base.hp == b.base.max_hp and b.structures.is_empty() and b.units.is_empty()
	return check(lost and stuck and fresh, "패배 %s · 넘어가기 거부 %s · 새 도전: %d라운드 웨이브 %d %s, 골드 %d, 거점 %d/%d, 구조물 %d, 유닛 %d" %
		[lost, stuck, b.round_index + 1, b.wave_index + 1, b.state, b.gold, b.base.hp, b.base.max_hp, b.structures.size(), b.units.size()])

# EV166 · I92: 새 도전은 마을 레벨, 성곽 단계·체력·잔해, 영웅까지 처음으로 돌린다
func ev166():
	var b = _castle({"hero_start": H, "base_hp": 100})
	var up = b.castle[TOP]
	var gone := TOP + Vector2i(4, 0)  # 성문(15열)이 아닌 성벽 칸
	b.upgrade(up)
	b.raise_village()
	b.damage(b.castle[gone], BIG)
	if up.level != 2 or b.village_level != 2 or not b.rubble.has(gone):
		return "준비가 되지 않았다(성벽 칸 %d단계, 마을 Lv%d, 잔해 %s)" % [up.level, b.village_level, b.rubble.keys()]
	if not _win_round(b) or not b.next_round():
		return "1라운드를 이기고 다음 라운드로 넘어가지 못했다(%s)" % b.state
	b.damage(b.hero, 30)
	b.start_battle()
	b.damage(b.base, BIG)
	if b.state != "lost":
		return "2라운드에서 지지 않았다(%s)" % b.state
	b.restart()
	var a = b.castle.get(TOP)
	var z = b.castle.get(gone)
	var walls: bool = a != null and z != null and a.level == 1 and z.level == 1 and a.hp == a.max_hp and z.hp == z.max_hp
	var hero: bool = b.hero != null and b.hero.hp == b.hero.max_hp and near(b.hero.pos, H, 0.01)
	return check(b.village_level == 1 and walls and b.rubble.is_empty() and hero,
		"새 도전: 마을 Lv%d · 성벽 칸 처음 상태 %s · 잔해 %s · 영웅 처음 상태 %s" % [b.village_level, walls, b.rubble.keys(), hero])

# EV167 · I93: 살아 있는 영웅은 자리·체력이 그대로이고, 쓰러진 영웅은 부활을 꺼도 다음 라운드 준비 단계에 시작 지점으로 돌아온다
func ev167():
	var start := Vector2i(20, 5)
	var b = battle({"hero_start": start, "base_hp": BIG, "rounds": ONE_ONE})
	var to := start + Vector2i(4, 0)
	b.order_move([b.hero], to)
	if not run(b, 10.0, func(): return near(b.hero.pos, to)):
		return "영웅이 옮겨 가지 않았다(%s)" % b.hero.pos
	b.damage(b.hero, 30)
	var hp: float = b.hero.hp
	if not _win_round(b):
		return "1라운드를 이기지 못했다(%s)" % b.state
	var at: Vector2 = b.hero.pos
	b.next_round()
	var kept: bool = b.state == "prep" and b.hero.present and b.hero.pos.distance_to(at) < 0.1 and b.hero.hp == hp
	var d = battle({"hero_start": start, "base_hp": BIG, "rounds": ONE_ONE})
	d.revive = false
	d.start_battle()
	run(d, 1.0)
	d.damage(d.hero, BIG)
	clear_wave(d)
	var away: bool = d.state == "cleared" and not d.hero.present
	d.next_round()
	var back: bool = d.state == "prep" and d.hero.present and d.hero.hp == 1.0 and near(d.hero.pos, start, 0.01)  # 체력 1로 돌아온다(S138)
	return check(kept and away and back, "살아 있는 영웅 그대로 %s · 쓰러진 영웅: 라운드 사이엔 없음 %s, 다음 라운드엔 시작 지점에 체력 1 %s(%s)" % [kept, away, back, d.hero.hp])

# EV168 · I67: 1라운드에 연 성문은 다음 라운드에도 열려 있다
func ev168():
	var b = _castle()
	var g = b.castle[GATES[0]]
	b.set_gate(g, true)
	if not g.open:
		return "성문을 열지 못했다"
	if not _win_round(b) or not b.next_round():
		return "1라운드를 이기고 다음 라운드로 넘어가지 못했다(%s)" % b.state
	var others := [b.castle[GATES[1]].open, b.castle[GATES[2]].open]
	return check(b.castle.get(GATES[0]) == g and g.open and others == [false, false], "연 성문 %s · 다른 성문 열림 %s" % [g.open, others])

# EV169 · I91: 시험 스테이지 도전은 6라운드이고, 1라운드는 S111, 2~6라운드는 I91 표의 적 수다(둘 다 보스를 뺀 10배)
func ev169():
	var b = load("res://src/sim/battle.gd").new(load("res://src/main.gd").stage())
	if b.rounds.size() != 6:
		return "라운드가 %d개다(6개여야 한다)" % b.rounds.size()
	var table := [_ten(S111)] + I91.map(func(r): return _ten(r))
	for k in 6:
		var got := _counts(b.rounds[k])
		if got != table[k]:
			return "%d라운드 웨이브가 %s다(%s여야 한다)" % [k + 1, got, table[k]]
	return ""

# EV170 · I91: 2라운드 웨이브 Resource의 첫 웨이브를 바꾸면 시험 스테이지 2라운드 첫 웨이브에 그만큼 나온다
func ev170():
	var w = load("res://data/waves/round_2.tres")
	if w == null:
		return "2라운드 웨이브 Resource를 불러오지 못했다"
	w.waves[0] = {"basic": 2}
	var b = load("res://src/sim/battle.gd").new(load("res://src/main.gd").stage())
	if not _win_round(b) or not b.next_round():
		return "1라운드를 이기고 다음 라운드로 넘어가지 못했다(%s)" % b.state
	var n := [0]
	b.enemy_spawned.connect(func(_e): n[0] += 1)
	b.start_battle()
	run(b, 10.0)
	return check(n[0] == 2, "2라운드 첫 웨이브에 적이 %d명 나왔다(2명이어야 한다)" % n[0])

# EV367 · I91: 시험 스테이지 판에서 적은 0.25초 간격으로 나온다. 첫 적은 전투를 시작하자마자 나온다
func ev367():
	var b = load("res://src/sim/battle.gd").new(load("res://src/main.gd").stage())
	var n := [0]
	b.enemy_spawned.connect(func(_e): n[0] += 1)
	b.start_battle()
	run(b, 0.2)
	var early: int = n[0]
	run(b, 0.2)
	return check(early == 1 and n[0] == 2, "0.2초 뒤 %d명, 0.4초 뒤 %d명이 나왔다(1명·2명이어야 한다)" % [early, n[0]])

# EV243 · S138: 쓰러진 영웅은 체력 1로 돌아온다(부활이 켜져 있으면 다음 준비 단계, 꺼져 있으면 다음 라운드).
#   쓰러진 채 출전에서 빠졌다가 다시 출전한 영웅은 S124대로 최대 체력이다
func ev243():
	var start := Vector2i(20, 5)
	var b = battle({"hero_start": start, "base_hp": BIG, "rounds": [[ONE, ONE], [ONE]]})
	b.start_battle()
	run(b, 1.0)
	b.damage(b.hero, BIG)
	clear_wave(b)
	var wave: bool = b.state == "prep" and b.hero.present and b.hero.hp == 1.0 and near(b.hero.pos, start, 0.01)
	var d = battle({"hero_start": start, "base_hp": BIG, "rounds": ONE_ONE})
	d.revive = false
	d.start_battle()
	run(d, 1.0)
	d.damage(d.hero, BIG)
	clear_wave(d)
	d.next_round()
	var later: bool = d.state == "prep" and d.hero.present and d.hero.hp == 1.0
	var r = battle({"hero_cells": [Vector2i(10, 5), Vector2i(12, 5)], "seed": 7, "base_hp": BIG, "rounds": [[ONE], [ONE], [ONE]]})
	r.begin_hiring()
	r.offers = ["aias", "seraphina", "ignis"]
	var k = r.hire(0)
	r.hire(1)
	r.next_round()
	r.start_battle()
	r.damage(k, BIG)
	clear_wave(r)
	r.set_lineup(k, false)
	r.next_round()
	var benched: bool = not k.present and k not in r.heroes
	r.start_battle()
	clear_wave(r)
	r.set_lineup(k, true)
	r.next_round()
	var back: bool = r.state == "prep" and k in r.heroes and k.present and k.hp == k.max_hp
	return check(wave and later and benched and back,
		"부활 켜짐: 웨이브 끝 체력 1 %s(%s) · 부활 꺼짐: 다음 라운드 체력 1 %s(%s) · 빠졌다 다시 출전: 빠짐 %s, 최대 체력 %s(%s/%s)" % [wave, b.hero.hp, later, d.hero.hp, benched, back, k.hp, k.max_hp])

# EV253 · S144: 라운드 체력 배율(stage 키 hp_mult: [라운드마다 배율], 없으면 1). 3라운드(1.5)의 기본 적은 체력·최대 체력이 1.5배이고
# 1라운드는 그대로다. 처치 보상은 배율과 상관없다
func ev253():
	var w := [[{"kind": "basic", "count": 1}]]
	var b = battle({"base_hp": BIG, "rounds": [w, w, w], "hp_mult": [1.0, 1.0, 1.5]})
	var hp: float = b.ENEMY_KINDS.basic.hp
	var got := []
	for r in 3:
		if r > 0 and not b.next_round():
			return "%d라운드로 넘어가지 못했다(%s)" % [r + 1, b.state]
		b.start_battle()
		if not run(b, 5.0, func(): return not b.enemies.is_empty()):
			return "%d라운드에 5초 안에 적이 나오지 않았다" % (r + 1)
		var e = b.enemies[0]
		got.append([e.hp, e.max_hp])
		var g0: int = b.gold
		b.damage(e, BIG)
		if r == 2 and b.gold != g0 + b.ENEMY_KINDS.basic.reward:
			return "3라운드 적 처치 보상이 %d다(basic %d여야 한다)" % [b.gold - g0, b.ENEMY_KINDS.basic.reward]
		if not clear_wave(b):
			return "%d라운드 웨이브가 끝나지 않았다" % (r + 1)
	var ok: bool = is_equal_approx(got[0][0], hp) and is_equal_approx(got[0][1], hp) and is_equal_approx(got[2][0], hp * 1.5) and is_equal_approx(got[2][1], hp * 1.5)
	return check(ok, "라운드별 [체력, 최대 체력] %s(1라운드 %s, 3라운드 %s여야 한다)" % [got, hp, hp * 1.5])

# EV426 · I176: 시험 스테이지는 처치 보상에 0.1을 곱하고, 1골드에 못 미치는 나머지는 쌓았다가 준다. 나머지는 저장에 담긴다
func ev426():
	var Save = load("res://src/sim/save.gd")
	var b = load("res://src/sim/battle.gd").new(load("res://src/main.gd").stage())
	b.gold = 0
	var got := []
	for i in 3:
		b.damage(b.spawn_enemy("basic", Vector2i(30, 50)), BIG)
		got.append(b.gold)
	var c = load("res://src/sim/battle.gd").new(load("res://src/main.gd").stage())
	Save.apply(c, Save.snapshot(b))
	c.damage(c.spawn_enemy("basic", Vector2i(30, 50)), BIG)
	var h = battle({"gold": 0})
	h.damage(h.spawn_enemy("basic", Vector2i(10, 10)), BIG)
	return check(got == [0, 1, 1] and c.gold == 2 and h.gold == 5,
		"시험 스테이지 기본 적 셋을 처치하며 골드 %s(0·1·1이어야 한다) · 저장해 불러온 판에서 하나 더 처치한 골드 %d(2여야 한다) · 헬퍼 판 골드 %d(5여야 한다)" % [got, c.gold, h.gold])

# EV427 · I177: 시험 스테이지의 적은 맡은 출현 지점에서 가로로 ±10칸 안의 맨 아래 줄 칸에서, 황금비 수열 차례로 흩어져 나온다
func ev427():
	var b = load("res://src/sim/battle.gd").new(load("res://src/main.gd").stage())
	var plan: Array = b.wave_plan(0, 0)
	var cells := []
	b.enemy_spawned.connect(func(e): cells.append(Vector2i(e.pos.round())))
	b.start_battle()
	clear_wave(b)
	if cells.size() != 90:
		return "1라운드 첫 웨이브에 적이 %d명 나왔다(90명이어야 한다)" % cells.size()
	var xs := {}
	for k in cells.size():
		var s: Vector2i = plan[k][1]
		var n: int = k / b.spawns.size()
		var x := clampi(s.x - 10 + int(fposmod(n * 0.6180339887, 1.0) * 21.0), 0, 59)
		if cells[k] != Vector2i(x, 92):
			return "%d번째 적이 %s에서 나왔다(출현 지점 %s, %s여야 한다)" % [k, cells[k], s, Vector2i(x, 92)]
		xs[x] = true
	var h = battle({"spawns": [Vector2i(0, 5)], "waves": [[{"kind": "basic", "count": 3}]]})
	var at := []
	h.enemy_spawned.connect(func(e): at.append(Vector2i(e.pos.round())))
	h.start_battle()
	clear_wave(h)
	return check(xs.size() >= 40 and at == [Vector2i(0, 5), Vector2i(0, 5), Vector2i(0, 5)],
		"나온 x %d가지(40가지 이상이어야 한다) · 헬퍼 판 나온 칸 %s(모두 (0, 5)여야 한다)" % [xs.size(), at])
