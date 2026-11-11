extends "res://tests/eval/gd/lib.gd"
# WBS 3.8 도전 구조(S61·S63·S64·S79·S117·I46·I67·I91~I93). lib.gd·repair.gd 머리의 계약에 더하는 API:
#   stage 키 rounds: [웨이브 배열, …] — 라운드마다 waves와 같은 모양이다. 없으면 [waves] 한 라운드짜리 도전이다
#   Battle.rounds · Battle.round_index(0부터) — Battle.waves는 지금 라운드의 웨이브다
#   state "cleared" — 마지막이 아닌 라운드를 이긴 «라운드 사이»(S117). 마지막 라운드를 이기면 "won"이다
#   Battle.next_round() -> bool — 라운드 사이에서 다음 라운드의 첫 준비 단계로 넘어간다. 라운드 사이가 아니면 거부한다(false)
#   Battle.restart() — 새 도전(S64, I92)
#   Battle.set_gate(성문, 열기) · Battle.upgrade(성곽 칸) · Battle.raise_village() -> bool · 영웅: present
#   적 kind "shieldbearer"(방패 고블린, S301·I248) — 웨이브에서 나올 때 호위(기본 4)를 데려온다. 호위는 battle.spawn_counts(hud.gd 머리)에도 든다
#   웨이브 항목 키 front(S338·I281) — 그 종류를 묶은 출현 지점 차례(0부터, stage spawns 차례). 없으면 차례마다 돌아간다.
#     웨이브 Resource(WavesDef)의 fronts: 웨이브 차례마다 {적 종류: 출현 지점 차례}. to_stage()가 항목의 front로 싣는다
#   Battle.wave_plan(라운드, 웨이브) -> 나오는 차례대로 [종류, 출현 지점 칸, 나올 칸, 함께 나오는 마릿수]
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
const S111 := [{"slime": 36}, {"slime": 24, "big_slime": 10}, {"slime": 36, "big_slime": 14, "slime_king": 1}]  # S111 2026-10-30 변경: 1라운드 슬라임 테마, 보스 빼고 1.2배 반올림(10배를 하지 않는다)
# I91 2026-10-27 변경: 2라운드는 늑대 테마(마릿수, 10배를 하지 않는다)
# I91 2026-11-03 변경·둘째 변경·셋째 변경: 3라운드 1~4웨이브는 고블린 약탈단(마릿수, 10배를 하지 않는다)
# S301: 2~4웨이브에 방패 고블린·불화살 고블린을 더하고, 기본은 호위 고블린(방패 고블린 × 4) 수만큼 줄인 웨이브 데이터의 수다
const RAID := [{"basic": 260, "sapper": 30, "ram": 6},
	{"shieldbearer": 10, "fire_archer": 6, "basic": 310, "sapper": 30, "ram": 6, "catapult": 8, "glider": 80},
	{"shieldbearer": 12, "fire_archer": 8, "basic": 262, "sapper": 30, "ram": 4, "catapult": 6, "glider": 60, "siege_tower": 3, "balloon": 6},
	{"shieldbearer": 15, "fire_archer": 10, "basic": 240, "sapper": 40, "ram": 6, "catapult": 8, "glider": 80, "siege_tower": 3, "balloon": 6, "airship": 6, "war_machine": 1}]
const WOLF := [{"wolf": 320}, {"wolf": 300, "leap_wolf": 100}, {"wolf": 240, "leap_wolf": 80, "night_wolf": 80}, {"wolf": 320, "leap_wolf": 100, "night_wolf": 100, "alpha_wolf": 6}]  # I91 2026-11-05 변경: 알파 늑대 6
# S303: 4라운드 1·2웨이브는 하늘 둥지(마릿수, 10배를 하지 않는다). 키 차례가 나오는 차례다. 3·4웨이브는 I91 표 그대로
const SKY := [{"flying": 360, "feather_harpy": 60}, {"flying": 300, "song_harpy": 60, "feather_harpy": 60, "dive_harpy": 100},
	{"flying": 280, "storm_harpy": 40, "feather_harpy": 60, "snatch_harpy": 60, "dive_harpy": 60, "song_harpy": 40},
	{"flying": 320, "nest_harpy": 20, "feather_harpy": 80, "dive_harpy": 80, "song_harpy": 60, "storm_harpy": 50, "snatch_harpy": 70, "wyvern": 1}]  # S303(3웨이브는 2026-11-10 변경, 4웨이브는 2026-11-10 둘째 변경)
# S318: 5라운드 네 웨이브는 오크 전쟁패(마릿수, 10배를 하지 않는다). 키 차례가 나오는 차례다(3웨이브는 2026-11-10 변경, 4웨이브는 둘째 변경)
const ORC := [{"shield_orc": 48, "armored": 160}, {"shield_orc": 40, "armored": 180, "drummer": 20, "berserker": 80},
	{"shield_orc": 40, "armored": 140, "ogre_thrower": 20, "berserker": 40, "chain_orc": 30},
	{"shield_orc": 40, "armored": 180, "troll": 30, "twin_troll": 2, "berserker": 80}]
# S336: 6라운드 1~3웨이브는 대족장 군단(마릿수, 10배를 하지 않는다). 키 차례가 나오는 차례다(3웨이브는 2026-11-11 변경). 4웨이브는 I91 표 그대로
const HOST := [{"slime": 80, "armored": 40, "ogre_thrower": 10, "wolf": 112},
	{"shieldbearer": 10, "basic": 160, "fire_archer": 10, "shield_orc": 48, "drummer": 20, "wolf": 96, "wolf_rider": 60},
	{"wolf": 256, "armored": 140, "chain_orc": 25, "flying": 80, "song_harpy": 20, "dive_harpy": 20}]
# S336 2026-11-11 변경: 6라운드 3웨이브는 다지점(S338). 종류마다 묶인 출현 지점 차례(0 왼쪽 · 1 가운데 · 2 오른쪽)
const HOST_FRONTS := {"wolf": 0, "armored": 1, "chain_orc": 1, "flying": 2, "song_harpy": 2, "dive_harpy": 2}
const THREE := [Vector2i(5, 19), Vector2i(15, 19), Vector2i(25, 19)]  # 출현 지점 셋짜리 헬퍼 판(S338 평가)
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

# EV169 · I91: 시험 스테이지 도전은 6라운드이고, 1라운드는 S111, 2~6라운드는 I91 표의 보스를 뺀 10배 적 수다
func ev169():
	var b = load("res://src/sim/battle.gd").new(load("res://src/main.gd").stage())
	if b.rounds.size() != 6:
		return "라운드가 %d개다(6개여야 한다)" % b.rounds.size()
	var table := [S111, WOLF] + I91.slice(1).map(func(r): return _ten(r))
	table[2] = RAID  # I91 2026-11-03 변경·둘째 변경·셋째 변경: 3라운드 네 웨이브 모두 고블린 약탈단(마릿수)
	table[3] = SKY  # S303: 4라운드 네 웨이브 모두 하늘 둥지(마릿수)
	table[4] = ORC  # S318: 5라운드 네 웨이브 모두 오크 전쟁패(마릿수)
	table[5] = HOST + table[5].slice(3)  # S336: 6라운드 1~3웨이브는 대족장 군단(마릿수). 4웨이브는 I91 표의 10배 그대로
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
	if cells.size() != plan.size():
		return "1라운드 첫 웨이브에 적이 %d명 나왔다(계획 %d명)" % [cells.size(), plan.size()]
	var xs := {}
	for k in cells.size():
		var s: Vector2i = plan[k][1]
		var n: int = k / b.spawns.size()
		var x := clampi(s.x - 10 + int(fposmod(n * 0.6180339887, 1.0) * 21.0), 0, b.size.x - 1)  # 맵 오른쪽 끝 열에서 자른다
		if cells[k] != Vector2i(x, b.size.y - 1):  # 맨 아래 줄(S203)
			return "%d번째 적이 %s에서 나왔다(출현 지점 %s, %s여야 한다)" % [k, cells[k], s, Vector2i(x, b.size.y - 1)]
		xs[x] = true
	var h = battle({"spawns": [Vector2i(0, 5)], "waves": [[{"kind": "basic", "count": 3}]]})
	var at := []
	h.enemy_spawned.connect(func(e): at.append(Vector2i(e.pos.round())))
	h.start_battle()
	clear_wave(h)
	return check(xs.size() >= 20 and at == [Vector2i(0, 5), Vector2i(0, 5), Vector2i(0, 5)],
		"나온 x %d가지(20가지 이상이어야 한다) · 헬퍼 판 나온 칸 %s(모두 (0, 5)여야 한다)" % [xs.size(), at])

# EV820 · I248: 방패 고블린이 나오는 스텝에 같은 출현 지점에서 기본 고블린 4가 함께 나온다(호위, S301). 출현 지점 (8,19)·(22,19), 퍼짐 0인 판에서
# 호위는 출현 칸 줄(19행)의 서로 다른 칸에 방패 고블린을 가운데 두고(가로 평균이 방패 고블린 열과 0.5칸 안) 가로 2칸 안에 서고, 방패 고블린은 한 줄 북쪽(18행)·8열에서 1칸 안이다.
# 웨이브 미리보기 수(spawn_counts)에 호위 기본 4가 그 출현 지점 몫으로 들고, 시험 스테이지 3라운드 2웨이브 미리보기 수의 합은 방패 고블린 10·기본 350(데이터 310 + 호위 40)이다
func ev820():
	var b = battle({"spawns": [Vector2i(8, 19), Vector2i(22, 19)], "base_hp": BIG, "waves": [[{"kind": "shieldbearer", "count": 1}]]})
	if not b.ENEMY_KINDS.has("shieldbearer"):
		return "구현 없음: 적 종류 shieldbearer(방패 고블린, S106 표)가 없다"
	var counts: Array = b.spawn_counts(0, 0)
	var preview: bool = counts.size() == 2 and counts[0].size() == 2 and counts[0].get("shieldbearer") == 1 and counts[0].get("basic") == 4 and counts[1].is_empty()
	b.start_battle()
	run(b, 1.0, func(): return not b.enemies.is_empty())
	var out: Array = b.enemies.map(func(e): return [e.kind, cell_of(e)])  # 첫 적이 나온 스텝 끝의 모든 적
	var lead: Array = out.filter(func(o): return o[0] == "shieldbearer").map(func(o): return o[1])
	var guards: Array = out.filter(func(o): return o[0] == "basic").map(func(o): return o[1])
	var placed := false
	if out.size() == 5 and lead.size() == 1 and guards.size() == 4:
		var c: Vector2i = lead[0]
		var cells := {}
		for g in guards:
			cells[g] = true
		var mean: float = guards.reduce(func(s, g): return s + g.x, 0) / 4.0
		placed = c.y == 18 and absi(c.x - 8) <= 1 and cells.size() == 4 and absf(mean - c.x) <= 0.5 and guards.all(func(g): return g.y == 19 and absi(g.x - c.x) <= 2)
	var m = load("res://src/sim/battle.gd").new(load("res://src/main.gd").stage())
	var sum := {}
	for d in m.spawn_counts(2, 1):
		for k in d:
			sum[k] = sum.get(k, 0) + d[k]
	return check(preview and placed and sum.get("shieldbearer") == 10 and sum.get("basic") == 350,
		"미리보기 수 %s([{shieldbearer 1, basic 4}, {}]) · 첫 스텝에 나온 적 [종류, 칸] %s(방패 고블린 18행, 기본 4가 19행 양옆) · 시험 스테이지 3라운드 2웨이브 미리보기 합 %s(shieldbearer 10, basic 350)" % [counts, out, sum])

# EV829 · S301: data/waves/round_3.tres의 2·3·4웨이브는 S301의 수이고, 웨이브 사전의 키 차례가 S301의 나오는 차례(방패 고블린 → 불화살 고블린 → 기본 → …)다.
# RAID 2~4웨이브가 S301 문장의 차례대로 적혀 있다. Dictionary ==는 키 차례를 보지 않아 keys() 배열을 따로 견준다
func ev829():
	var w = load("res://data/waves/round_3.tres")
	if w == null or not w.get("waves") is Array or w.waves.size() != 4:
		return "3라운드 웨이브 Resource의 waves가 웨이브 4개 배열이 아니다(%s)" % [w.get("waves") if w != null else null]
	var bad := []
	for i in [1, 2, 3]:
		var d: Dictionary = w.waves[i]
		if d != RAID[i] or d.keys() != RAID[i].keys():
			bad.append("%d웨이브 %s(%s여야 한다)" % [i + 1, d, RAID[i]])
	return check(bad.is_empty(), "수나 차례가 다른 웨이브 %s" % [bad])

# EV838 · S303: data/waves/round_4.tres의 1~4웨이브는 S303의 수이고 키 차례가 나오는 차례(비행 → 깃털 사수 …)다.
# 비행은 무리 4(S238)라 비행 8마리짜리 웨이브의 첫 차례에 4마리가 함께 나온다
func ev838():
	var w = load("res://data/waves/round_4.tres")
	if w == null or not w.get("waves") is Array or w.waves.size() != 4:
		return "4라운드 웨이브 Resource의 waves가 웨이브 4개 배열이 아니다(%s)" % [w.get("waves") if w != null else null]
	var want: Array = SKY
	var bad := []
	for i in 4:
		var d: Dictionary = w.waves[i]
		if d != want[i] or d.keys() != want[i].keys():
			bad.append("%d웨이브 %s(%s여야 한다)" % [i + 1, d, want[i]])
	if not bad.is_empty():
		return "수나 차례가 다른 웨이브 %s" % [bad]
	var b = battle({"waves": [[{"kind": "flying", "count": 8}]]})
	b.start_battle()
	if not run(b, 1.0, func(): return not b.enemies.is_empty()):
		return "1초 안에 비행 적이 나오지 않았다"
	var born: Array = b.enemies.map(func(e): return e.kind)
	return check(born == ["flying", "flying", "flying", "flying"], "첫 적이 나온 스텝에 나온 적 %s(비행 4마리여야 한다)" % [born])

# EV896 · S318: data/waves/round_5.tres의 네 웨이브는 S318의 수이고 키 차례가 나오는 차례(방패벽 오크 → 장갑 …)다.
# 장갑은 무리 4, 방패벽 오크는 무리 2(S238)라 첫 차례에 그만큼 함께 나온다
func ev896():
	var w = load("res://data/waves/round_5.tres")
	if w == null or not w.get("waves") is Array or w.waves.size() != 4:
		return "5라운드 웨이브 Resource의 waves가 웨이브 4개 배열이 아니다(%s)" % [w.get("waves") if w != null else null]
	var want: Array = ORC
	var bad := []
	for i in 4:
		var d: Dictionary = w.waves[i]
		if d != want[i] or d.keys() != want[i].keys():
			bad.append("%d웨이브 %s(%s여야 한다)" % [i + 1, d, want[i]])
	if not bad.is_empty():
		return "수나 차례가 다른 웨이브 %s" % [bad]
	for pair in [["armored", 8, 4], ["shield_orc", 4, 2]]:
		var b = battle({"waves": [[{"kind": pair[0], "count": pair[1]}]]})
		if not b.ENEMY_KINDS.has(pair[0]):
			return "적 종류 %s가 없다" % pair[0]
		b.start_battle()
		if not run(b, 1.0, func(): return not b.enemies.is_empty()):
			return "1초 안에 %s가 나오지 않았다" % pair[0]
		var born: Array = b.enemies.map(func(e): return e.kind)
		if born.size() != pair[2] or born.any(func(k): return k != pair[0]):
			return "%s %d마리짜리 웨이브의 첫 적이 나온 스텝에 나온 적 %s(%d마리여야 한다)" % [pair[0], pair[1], born, pair[2]]
	return ""

# EV969 · S336: data/waves/round_6.tres의 1~3웨이브는 S336의 수이고 키 차례가 나오는 차례다. 4웨이브는 옛 구성 그대로다.
# 3웨이브는 다지점(S338)이라 fronts의 3웨이브 칸이 종류마다 출현 지점을 묶고, 시험 스테이지 미리보기 수가 출현 지점마다 그 테마뿐이다.
# 늑대 기수는 무리 2(S238)라 첫 차례에 둘이 함께 나온다
func ev969():
	var w = load("res://data/waves/round_6.tres")
	if w == null or not w.get("waves") is Array or w.waves.size() != 4:
		return "6라운드 웨이브 Resource의 waves가 웨이브 4개 배열이 아니다(%s)" % [w.get("waves") if w != null else null]
	var want: Array = HOST + [{"basic": 360, "fast": 180, "armored": 120, "flying": 140, "boss": 2}]
	var bad := []
	for i in 4:
		var d: Dictionary = w.waves[i]
		if d != want[i] or (i < 3 and d.keys() != want[i].keys()):
			bad.append("%d웨이브 %s(%s여야 한다)" % [i + 1, d, want[i]])
	if not bad.is_empty():
		return "수나 차례가 다른 웨이브 %s" % [bad]
	var fronts = w.get("fronts")
	if not fronts is Array or fronts.size() != 4 or fronts[2] != HOST_FRONTS or [0, 1, 3].any(func(i): return not fronts[i].is_empty()):
		return "6라운드 웨이브 Resource의 fronts가 %s다(3웨이브 칸만 %s이고 나머지는 비어야 한다)" % [fronts, HOST_FRONTS]
	var m = load("res://src/sim/battle.gd").new(load("res://src/main.gd").stage())
	var counts: Array = m.spawn_counts(5, 2)
	var themes := [{"wolf": 256}, {"armored": 140, "chain_orc": 25}, {"flying": 80, "song_harpy": 20, "dive_harpy": 20}]
	if counts != themes:
		return "시험 스테이지 6라운드 3웨이브 미리보기 수 %s(%s여야 한다)" % [counts, themes]
	var b = battle({"waves": [[{"kind": "wolf_rider", "count": 4}]]})
	if not b.ENEMY_KINDS.has("wolf_rider"):
		return "적 종류 wolf_rider가 없다"
	b.start_battle()
	if not run(b, 1.0, func(): return not b.enemies.is_empty()):
		return "1초 안에 늑대 기수가 나오지 않았다"
	var born: Array = b.enemies.map(func(e): return e.kind)
	return check(born == ["wolf_rider", "wolf_rider"], "늑대 기수 4마리짜리 웨이브의 첫 적이 나온 스텝에 나온 적 %s(2마리여야 한다)" % [born])

# 웨이브를 시작해 끝날 때까지(나오는 적은 그 스텝에 처치) 돌리고, 같은 스텝에 나온 적끼리 묶어 [종류, 수, 칸, 첫 차례부터 초]로 돌려준다.
# 한 차례에 종류나 칸이 섞였으면 종류는 "섞임", 칸은 (-1, -1)이다
func _turns(b) -> Array:
	var out := []
	var t := [0.0, -1.0]  # [지금 시각, 첫 차례 시각]
	b.enemy_spawned.connect(func(e):
		if t[1] < 0.0:
			t[1] = t[0]
		var c := Vector2i(e.pos.round())
		if out.is_empty() or not is_equal_approx(out[-1][3], t[0] - t[1]):
			out.append([e.kind, 0, c, t[0] - t[1]])
		out[-1][1] += 1
		if out[-1][0] != e.kind:
			out[-1][0] = "섞임"
		if out[-1][2] != c:
			out[-1][2] = Vector2i(-1, -1))
	b.start_battle()
	for i in 2400:
		if b.state != "battle":
			break
		b.step(DT)
		t[0] += DT
		kill_all(b)
	return out

# 차례들이 [종류, 수, 칸] 기대와 같고, 다음 차례까지의 간격이 gap × 그 차례의 마릿수(±0.06초)인가
func _same_turns(got: Array, want: Array, gap: float) -> bool:
	if got.size() != want.size():
		return false
	var at := 0.0
	for i in want.size():
		if got[i].slice(0, 3) != want[i] or absf(got[i][3] - at) > 0.06:
			return false
		at += gap * want[i][1]
	return true

# EV982 · S338: 묶인 종류는 묶인 출현 지점에서만 나온다. 출현 지점은 차례마다 돌아가며 제 줄의 다음 차례(무리나 한 마리)를 내고, 줄이 빈 출현 지점은 건너뛴다.
# 묶이지 않은 종류는 지금처럼 차례마다 돌아가며 맡고, 묶음이 없는 웨이브는 차례가 그대로다. 미리보기 수(spawn_counts)도 묶인 대로다
func ev982():
	var w := THREE[0]
	var c := THREE[1]
	var e := THREE[2]
	var over := {"spawns": THREE, "spawn_gap": 0.25, "base_hp": BIG}
	# A: 셋 다 묶음 — 늑대(무리 4)는 왼쪽, 장갑(무리 4)은 가운데, 기본은 오른쪽
	var a = battle(over.merged({"waves": [[{"kind": "wolf", "count": 8, "front": 0}, {"kind": "armored", "count": 8, "front": 1}, {"kind": "basic", "count": 3, "front": 2}]]}))
	var a_counts: Array = a.spawn_counts(0, 0)
	var a_got := _turns(a)
	var a_want := [["wolf", 4, w], ["armored", 4, c], ["basic", 1, e], ["wolf", 4, w], ["armored", 4, c], ["basic", 1, e], ["basic", 1, e]]
	if a_counts != [{"wolf": 8}, {"armored": 8}, {"basic": 3}] or not _same_turns(a_got, a_want, 0.25):
		return "묶인 웨이브: 미리보기 수 %s([{wolf 8}, {armored 8}, {basic 3}]) · 나온 차례 [종류, 수, 칸, 초] %s(%s, 간격 0.25초 × 마릿수여야 한다)" % [a_counts, a_got, a_want]
	# B: 늑대만 오른쪽에 묶고 기본은 묶지 않음 — 기본은 차례마다 왼쪽·가운데·오른쪽·왼쪽을 맡는다
	var b = battle(over.merged({"waves": [[{"kind": "wolf", "count": 4, "front": 2}, {"kind": "basic", "count": 4}]]}))
	var b_counts: Array = b.spawn_counts(0, 0)
	var b_got := _turns(b)
	var b_want := [["basic", 1, w], ["basic", 1, c], ["wolf", 4, e], ["basic", 1, w], ["basic", 1, e]]
	if b_counts != [{"basic": 2}, {"basic": 1}, {"wolf": 4, "basic": 1}] or not _same_turns(b_got, b_want, 0.25):
		return "섞인 웨이브: 미리보기 수 %s([{basic 2}, {basic 1}, {wolf 4, basic 1}]) · 나온 차례 %s(%s여야 한다)" % [b_counts, b_got, b_want]
	# C: A에서 묶음을 뺀 웨이브 — 지금처럼 항목 차례대로, 출현 지점은 차례마다 돌아간다
	var n = battle(over.merged({"waves": [[{"kind": "wolf", "count": 8}, {"kind": "armored", "count": 8}, {"kind": "basic", "count": 3}]]}))
	var n_got := _turns(n)
	var n_want := [["wolf", 4, w], ["wolf", 4, c], ["armored", 4, e], ["armored", 4, w], ["basic", 1, c], ["basic", 1, e], ["basic", 1, w]]
	return check(_same_turns(n_got, n_want, 0.25), "묶음 없는 웨이브: 나온 차례 %s(%s여야 한다)" % [n_got, n_want])

# EV983 · I281: ① WavesDef.fronts가 to_stage()에서 항목의 front로 실린다 ③ 나오는 칸의 n은 그 출현 지점의 줄에서 몇 번째 차례인가다
# ④ 묶인 함께 나오는 종류(S294)는 모두 그 출현 지점에서 한 차례에, 묶인 방패 고블린의 호위(S301)는 호위 종류의 묶음과 상관없이 방패 고블린을 따라 나온다
# ① 출현 지점 수를 넘거나 음수인 front는 묶이지 않은 것이다
func ev983():
	var def = load("res://src/data/waves_def.gd").new()
	if not "fronts" in def:
		return "구현 없음: WavesDef에 fronts 칸이 없다"
	var ws: Array[Dictionary] = [{"wolf": 4, "basic": 2}, {"basic": 1}]
	var fs: Array[Dictionary] = [{"wolf": 2}]
	def.waves = ws
	def.fronts = fs
	var staged: Array = def.to_stage()
	var want := [[{"kind": "wolf", "count": 4, "front": 2}, {"kind": "basic", "count": 2}], [{"kind": "basic", "count": 1}]]
	if staged != want:
		return "to_stage()가 %s다(%s여야 한다)" % [staged, want]
	var spread = battle({"spawns": THREE, "spawn_spread": 3, "spawn_gap": 0.25, "base_hp": BIG, "waves": [[{"kind": "basic", "count": 5, "front": 1}]]})
	var cells: Array = _turns(spread).map(func(t): return t[2])
	var xs := range(5).map(func(k): return Vector2i(15 - 3 + int(fposmod(k * 0.6180339887, 1.0) * 7.0), 19))  # 12·16·13·17·15
	if cells != xs:
		return "퍼짐 3인 판에서 가운데에 묶인 기본 5마리가 나온 칸 %s(%s여야 한다)" % [cells, xs]
	var pack = battle({"spawns": THREE, "spawn_gap": 0.25, "base_hp": BIG, "waves": [[{"kind": "alpha_wolf", "count": 3, "front": 1}]]})
	if not pack.ENEMY_KINDS.has("alpha_wolf") or not pack.ENEMY_KINDS.alpha_wolf.get("together", false):
		return "적 종류 alpha_wolf의 together가 꺼져 있다"
	var alpha_counts: Array = pack.spawn_counts(0, 0)
	var alpha := _turns(pack)
	if alpha_counts != [{}, {"alpha_wolf": 3}, {}] or alpha.size() != 1 or alpha[0].slice(0, 3) != ["alpha_wolf", 3, THREE[1]]:
		return "가운데에 묶인 알파 늑대 3: 미리보기 수 %s([{}, {alpha_wolf 3}, {}]) · 나온 차례 %s(한 차례에 셋이 (15,19)에서)" % [alpha_counts, alpha]
	var esc = battle({"spawns": THREE, "base_hp": BIG, "waves": [[{"kind": "shieldbearer", "count": 1, "front": 2}, {"kind": "basic", "count": 2, "front": 0}]]})
	var esc_counts: Array = esc.spawn_counts(0, 0)
	if esc_counts != [{"basic": 2}, {}, {"shieldbearer": 1, "basic": 4}]:
		return "오른쪽에 묶인 방패 고블린 1과 왼쪽에 묶인 기본 2의 미리보기 수 %s([{basic 2}, {}, {shieldbearer 1, basic 4}]여야 한다)" % [esc_counts]
	var one = battle({"base_hp": BIG, "waves": [[{"kind": "basic", "count": 2, "front": 2}]]})  # 출현 지점이 (0,10) 하나뿐인 판
	var neg = battle({"spawns": THREE, "base_hp": BIG, "waves": [[{"kind": "basic", "count": 3, "front": -1}]]})
	var one_counts: Array = one.spawn_counts(0, 0)
	var neg_counts: Array = neg.spawn_counts(0, 0)
	return check(one_counts == [{"basic": 2}] and neg_counts == [{"basic": 1}, {"basic": 1}, {"basic": 1}],
		"출현 지점 하나인 판의 front 2 미리보기 수 %s([{basic 2}]) · front −1 미리보기 수 %s([{basic 1}] 셋)" % [one_counts, neg_counts])
