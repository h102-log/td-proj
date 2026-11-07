extends "res://tests/eval/gd/lib.gd"
# WBS 3.9 미션(S66·S77·I54·I118~I120). lib.gd·rounds.gd·hire.gd 머리의 계약에 더하는 API:
#   stage 키 quests: true(data/quests의 모든 미션) | [이름, …](그것들만, 평가용). 없으면 미션이 없다
#   res://data/quests/<이름>.tres — text · reward · zero(0이어야 하는 집계 키) · time_limit (I118). Battle.QUEST_KINDS[이름]이 그 수치다
#   Battle.quests — 이 도전의 미션 이름 · Battle.mission — 이번 라운드의 미션 이름("" 없음)
#   Battle.settled — 지난 라운드의 판정 [[이름, 달성], …] · Battle.tally — 라운드 집계(I119) · Battle.quest_met(이름) -> bool
#   의뢰는 없다(S77 2026-11-07 변경): Battle에 commission·commission_offers·accept가 없고, 퀘스트 데이터에 미션·의뢰를 가르는 칸(commission)이 없다
#   Save.apply(res://src/sim/save.gd, save.gd 머리) — 옛 저장의 quests·settled에 든 지운 의뢰 이름은 버리고, 옛 저장의 commission·commission_offers 칸은 읽지 않는다
# 수치는 Battle.QUEST_KINDS에서 읽는다. 임시값이라(I118) EV212만 표를 대조한다

const H := Vector2i(20, 14)  # 성곽 맵의 영웅 시작 칸
const TOP := Vector2i(12, 9)  # 성곽 맵의 성벽 칸
const GATES := [Vector2i(5, 9), Vector2i(15, 9), Vector2i(25, 9)]
const T := Vector2i(12, 12)  # 성곽 맵의 들판 칸(타워)
const M := Vector2i(3, 15)  # 성곽 맵의 들판 칸(용병)
const ONE := [{"kind": "basic", "count": 1}]
const ONE_ONE := [[ONE], [ONE]]  # 라운드 2개, 라운드마다 적 1마리짜리 웨이브 하나
const TABLE := {  # I118 표(2026-11-07 변경, 미션 넷): 이름 → [보상, 0이어야 하는 집계, 시간 상한]
	"base_safe": [20, ["base_hit"], 0.0],
	"castle_safe": [20, ["castle_lost"], 0.0],
	"mercs_safe": [20, ["merc_lost"], 0.0],
	"heroes_safe": [20, ["hero_down"], 0.0],
}
const GONE := ["flawless", "no_buying", "no_building", "swift"]  # S77 2026-11-07 변경으로 지운 의뢰 넷

# 성곽 맵(rounds.gd와 같다): 9행이 가로 성곽(성문 5·15·25열, 모두 닫힘), 위쪽이 마을, 아래쪽이 들판
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

func _files(dir: String) -> Array:
	var out := []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".tres"):
			out.append(f.get_basename())
	out.sort()
	return out

func _sorted(a: Array) -> Array:
	var out := a.duplicate()
	out.sort()
	return out

# EV212 · I118: data/quests의 파일 = 판의 미션 종류(미션 넷)이고, 값이 표와 같으며, 미션·의뢰를 가르는 칸이 없다
func ev212():
	var b = battle()
	var files := _files("res://data/quests")
	if files != _sorted(b.QUEST_KINDS.keys()) or files != _sorted(TABLE.keys()):
		return "파일 %s ≠ 종류 %s ≠ 표 %s" % [files, _sorted(b.QUEST_KINDS.keys()), _sorted(TABLE.keys())]
	for name in TABLE:
		var q: Dictionary = b.QUEST_KINDS[name]
		var want: Array = TABLE[name]
		if q.has("commission"):
			return "%s에 미션·의뢰를 가르는 칸(commission)이 남았다" % name
		if q.reward != want[0] or Array(q.zero) != want[1] or q.time_limit != want[2] or q.text == "":
			return "%s: 보상 %d 집계 %s 상한 %s 문장 «%s»(표는 %s)" % [name, q.reward, q.zero, q.time_limit, q.text, want]
	return ""

# EV213 · I120: 미션은 라운드를 이기는 순간 판정되어 달성이면 보상 골드를 받고, 실패면 아무 일도 없다. 마지막 라운드도 판정한다
func ev213():
	var b = battle({"gold": 100, "base_hp": BIG, "rounds": ONE_ONE, "quests": ["base_safe"]})
	if b.mission != "base_safe" or not b.settled.is_empty():
		return "1라운드 미션이 %s다(base_safe여야 한다) · 판정 %s" % [b.mission, b.settled]
	if not _win_round(b) or b.state != "cleared":
		return "1라운드를 이기지 못했다(%s)" % b.state
	var reward: int = b.ENEMY_KINDS.basic.reward
	var bonus: int = b.QUEST_KINDS.base_safe.reward
	var first: bool = b.gold == 100 + reward + bonus and b.settled == [["base_safe", true]]
	var gold1: int = b.gold
	b.next_round()
	var fresh: bool = b.mission == "base_safe" and b.settled.is_empty()
	b.damage(b.base, 1)
	if not _win_round(b) or b.state != "won":
		return "2라운드를 이기지 못했다(%s)" % b.state
	var second: bool = b.gold == gold1 + reward and b.settled == [["base_safe", false]]
	return check(first and fresh and second, "1라운드: 골드 %d(%d여야 한다) 판정 %s · 2라운드 준비: 미션 %s 판정 %s · 2라운드: 골드 %d(%d여야 한다) 판정 %s" %
		[gold1, 100 + reward + bonus, b.settled if not first else "달성", b.mission, fresh, b.gold, gold1 + reward, b.settled])

# EV215 · S77: 의뢰가 없다. 라운드 사이에 의뢰 목록·수락이 없고, 판정은 라운드마다 자동으로 뜬 미션 하나뿐이며 달성하면 보상 골드를 받는다.
#   data/quests에는 미션 넷만 있다. 지운 의뢰가 든 옛 저장을 불러오면 그 의뢰의 기록은 버리고 나머지는 저장 그대로다. 저장 판(Save.VERSION)은 7 그대로다
func ev215():
	var S = load("res://src/sim/save.gd")
	var version = S.get_script_constant_map().get("VERSION")
	if version != 7:  # S77 «저장 판은 그대로». 다른 기능이 저장 판을 올리면 이 줄을 함께 고친다
		return "저장 판 Save.VERSION이 %s다(의뢰를 지워도 저장 판은 그대로 7이어야 한다, S77)" % [version]
	var stage := {"gold": 100, "base_hp": BIG, "rounds": ONE_ONE, "quests": true}
	var b = battle(stage)
	var left: Array = ["commission", "commission_offers"].filter(func(k): return b.get(k) != null)
	if b.has_method("accept"):
		left.append("accept")
	if not left.is_empty():
		return "의뢰가 남았다: Battle의 %s" % [left]
	var files := _files("res://data/quests")
	if files != _sorted(TABLE.keys()):
		return "data/quests가 %s다(미션 넷 %s만 있어야 한다)" % [files, _sorted(TABLE.keys())]
	var m1: String = b.mission
	if not m1 in TABLE or not _win_round(b) or b.state != "cleared":
		return "1라운드 미션 «%s»로 1라운드를 이기지 못했다(%s)" % [m1, b.state]
	var bonus: int = b.QUEST_KINDS[m1].reward
	var gold1: int = 100 + b.ENEMY_KINDS.basic.reward + bonus
	if b.settled != [[m1, true]] or bonus <= 0 or b.gold != gold1:
		return "1라운드 뒤 판정 %s · 골드 %d(판정은 [[%s, true]] 하나, 골드는 %d여야 한다)" % [b.settled, b.gold, m1, gold1]
	var old: Dictionary = S.snapshot(b)
	old["quests"] = old["quests"] + GONE
	old["settled"] = old["settled"] + [["no_buying", false]]
	old["commission"] = "no_buying"
	old["commission_offers"] = ["flawless", "swift"]
	var c = battle(stage)
	S.apply(c, old)
	if _sorted(c.quests) != _sorted(TABLE.keys()) or c.settled != [[m1, true]] or c.gold != gold1 or c.state != "cleared" or c.mission != m1:
		return "옛 저장을 불러온 판: 미션 목록 %s · 판정 %s · 골드 %d · 단계 %s · 미션 %s(지운 의뢰는 버리고 나머지는 저장 그대로여야 한다)" % [c.quests, c.settled, c.gold, c.state, c.mission]
	c.next_round()
	var m2: String = c.mission
	if not m2 in TABLE or not _win_round(c) or c.state != "won":
		return "불러온 판의 2라운드 미션 «%s»로 2라운드를 이기지 못했다(%s)" % [m2, c.state]
	return check(c.settled == [[m2, true]], "불러온 판의 2라운드 판정 %s([[%s, true]] 하나여야 한다)" % [c.settled, m2])

# EV216 · I119: 라운드 집계는 사는 것·짓는 것·거점이 맞는 것·부서지는 것·잃는 것·전투 시간을 세고, 판매는 세지 않으며, 다음 라운드에 0이 된다
func ev216():
	var b = _castle({"hero_start": H})
	var zero: bool = b.TALLY_KEYS.all(func(k): return b.tally[k] == 0)
	var m = b.place_merc("soldier", M)
	var m2 = b.place_merc("soldier", M + Vector2i(2, 0))
	var t = b.build("tower", T)
	if m == null or m2 == null or t == null or not zero:
		return "준비가 되지 않았다(용병 %s %s, 타워 %s, 처음 집계 %s)" % [m, m2, t, b.tally]
	b.damage(b.base, 1)
	b.damage(b.castle[TOP], BIG)
	b.damage(t, BIG)
	b.damage(m, BIG)
	b.sell([m2])
	b.damage(b.hero, BIG)
	var want := {"base_hit": 1, "castle_lost": 1, "structure_lost": 1, "merc_lost": 1, "hero_down": 1, "merc_bought": 2, "built": 1}
	var counted: bool = want.keys().all(func(k): return b.tally[k] == want[k]) and b.tally.battle_time == 0.0
	var got: Dictionary = b.tally.duplicate()
	b.start_battle()
	run(b, 2.0)
	var timed: bool = absf(b.tally.battle_time - 2.0) < 0.1
	var time: float = b.tally.battle_time
	if not clear_wave(b) or not b.next_round():
		return "1라운드를 이기고 다음 라운드로 넘어가지 못했다(%s)" % b.state
	var reset: bool = b.TALLY_KEYS.all(func(k): return b.tally[k] == 0)
	return check(counted and timed and reset, "집계 %s(%s여야 한다) · 전투 2초 뒤 시간 %.2f · 다음 라운드에 0 %s(%s)" % [got, want, time, reset, b.tally])

# EV217 · I120: 미션은 도전의 미션 가운데 뽑히고, 둘 이상이면 지난 라운드와 같은 미션이 잇달아 나오지 않는다. 미션이 없는 스테이지는 아무것도 바뀌지 않는다
func ev217():
	var b = battle({"base_hp": BIG, "seed": 11, "rounds": [[ONE], [ONE], [ONE], [ONE]], "quests": ["base_safe", "castle_safe"]})
	var seq := [b.mission]
	for i in 3:
		if not _win_round(b) or not b.next_round():
			return "%d라운드를 이기고 넘어가지 못했다(%s)" % [i + 1, b.state]
		seq.append(b.mission)
	var alternates: bool = seq.all(func(n): return n in ["base_safe", "castle_safe"]) and range(1, 4).all(func(i): return seq[i] != seq[i - 1])
	var d = battle({"gold": 100, "base_hp": BIG, "rounds": ONE_ONE})
	var none: bool = d.quests.is_empty() and d.mission == ""
	if not _win_round(d) or d.state != "cleared":
		return "미션 없는 판의 1라운드를 이기지 못했다(%s)" % d.state
	var plain: bool = d.gold == 100 + d.ENEMY_KINDS.basic.reward and d.settled.is_empty()
	return check(alternates and none and plain, "미션 순서 %s · 미션 없는 판: 처음 %s, 이긴 뒤 골드 %d 판정 %s" % [seq, none, d.gold, d.settled])

# EV218 · I118: 시험 스테이지(`main.gd` stage())는 data/quests의 미션을 모두 쓰고, 1라운드에 미션이 하나 있다
func ev218():
	var b = load("res://src/sim/battle.gd").new(load("res://src/main.gd").stage())
	var all: bool = _sorted(b.quests) == _sorted(b.QUEST_KINDS.keys())
	var has: bool = b.mission != "" and b.mission in b.QUEST_KINDS
	return check(all and has, "모두 씀 %s(%s) · 1라운드 미션 %s" % [all, b.quests, b.mission])

# EV219 · I118: 조건마다 집계를 본다 — 용병을 잃으면 mercs_safe가, 영웅이 쓰러지면 heroes_safe가, 성곽 칸이 부서지면 castle_safe가 실패한다.
#   용병을 사는 것·판매·수리·업그레이드와, 짓거나 성곽이 아닌 구조물이 부서지는 것은 미션을 깨지 않는다
func ev219():
	var b = _castle({"hero_start": H, "gold": 1000})
	var m = b.place_merc("soldier", M)
	var m2 = b.place_merc("soldier", M + Vector2i(2, 0))
	var all_met: bool = TABLE.keys().all(b.quest_met)
	b.sell([m2])
	var sold_ok: bool = b.quest_met("mercs_safe")
	b.damage(m, BIG)
	var merc_lost: bool = not b.quest_met("mercs_safe") and b.quest_met("heroes_safe")
	b.damage(b.hero, BIG)
	var hero_down: bool = not b.quest_met("heroes_safe")
	var k = b.castle[TOP]
	b.damage(k, 100)
	b.repair(k)
	b.upgrade(b.castle[TOP + Vector2i(1, 0)])
	var fixed_ok: bool = b.quest_met("castle_safe") and k.hp == k.max_hp
	b.damage(k, BIG)
	var castle_lost: bool = not b.quest_met("castle_safe") and b.quest_met("base_safe")
	var d = _castle({"gold": 1000})
	var t = d.build("tower", T)
	d.damage(t, BIG)
	var structure_lost: bool = t != null and TABLE.keys().all(d.quest_met)
	return check(all_met and sold_ok and merc_lost and hero_down and fixed_ok and castle_lost and structure_lost,
		"용병 둘을 사도 모두 달성 %s · 판매는 괜찮음 %s · 용병 잃음 %s · 영웅 다운 %s · 수리·업그레이드는 괜찮음 %s · 성곽 칸 부서짐 %s · 타워를 짓고 부서져도 모두 달성 %s" %
		[all_met, sold_ok, merc_lost, hero_down, fixed_ok, castle_lost, structure_lost])

# EV221 · I92: 새 도전은 판정·집계를 비우고 1라운드 미션을 새로 뽑는다
func ev221():
	var b = battle({"base_hp": BIG, "rounds": ONE_ONE, "quests": ["base_safe"]})
	b.place_merc("soldier", Vector2i(20, 3))
	b.damage(b.base, 1)
	if not _win_round(b) or b.state != "cleared":
		return "1라운드를 이기지 못했다(%s)" % b.state
	if b.settled.is_empty() or b.tally.merc_bought != 1:
		return "준비가 되지 않았다(판정 %s, 집계 %s)" % [b.settled, b.tally]
	b.restart()
	var clean: bool = b.mission == "base_safe" and b.settled.is_empty() and b.TALLY_KEYS.all(func(k): return b.tally[k] == 0)
	return check(clean, "새 도전: 미션 %s · 판정 %s · 집계 %s" % [b.mission, b.settled, b.tally])

# EV234 · I131: 라운드에 지면 그 라운드의 미션은 실패로 판정되고 보상이 없다
func ev234():
	var b = battle({"base_hp": BIG, "rounds": ONE_ONE, "quests": ["mercs_safe"]})
	if not _win_round(b) or b.state != "cleared":
		return "1라운드를 이기지 못했다(%s)" % b.state
	b.next_round()
	b.start_battle()
	var gold: int = b.gold
	b.damage(b.base, BIG)
	return check(b.state == "lost" and b.settled == [["mercs_safe", false]] and b.gold == gold,
		"단계 %s · 판정 %s · 골드 %d → %d" % [b.state, b.settled, gold, b.gold])
