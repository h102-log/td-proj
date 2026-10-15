extends "res://tests/eval/gd/lib.gd"
# WBS 3.9 미션·의뢰(S66·S77·I54·I118~I121). lib.gd·rounds.gd·hire.gd 머리의 계약에 더하는 API:
#   stage 키 quests: true(data/quests의 모든 미션·의뢰) | [이름, …](그것들만, 평가용). 없으면 미션·의뢰가 없다
#   res://data/quests/<이름>.tres — commission · text · reward · zero(0이어야 하는 집계 키) · time_limit (I118). Battle.QUEST_KINDS[이름]이 그 수치다
#   Battle.quests — 이 도전의 미션·의뢰 이름 · Battle.mission — 이번 라운드의 미션 이름("" 없음) · Battle.commission — 수락한 의뢰 이름
#   Battle.commission_offers — 라운드 사이의 의뢰 목록 · Battle.accept(칸 번호) -> bool — 라운드 사이에만. 다시 수락하면 무른다
#   Battle.settled — 지난 라운드의 판정 [[이름, 달성], …] · Battle.tally — 라운드 집계(I119) · Battle.quest_met(이름) -> bool
# 수치는 Battle.QUEST_KINDS에서 읽는다. 임시값이라(I118) EV212만 표를 대조한다

const H := Vector2i(20, 14)  # 성곽 맵의 영웅 시작 칸
const TOP := Vector2i(12, 9)  # 성곽 맵의 성벽 칸
const GATES := [Vector2i(5, 9), Vector2i(15, 9), Vector2i(25, 9)]
const T := Vector2i(12, 12)  # 성곽 맵의 들판 칸(타워)
const M := Vector2i(3, 15)  # 성곽 맵의 들판 칸(용병)
const ONE := [{"kind": "basic", "count": 1}]
const ONE_ONE := [[ONE], [ONE]]  # 라운드 2개, 라운드마다 적 1마리짜리 웨이브 하나
const TABLE := {  # I118 표: 이름 → [의뢰?, 보상, 0이어야 하는 집계, 시간 상한]
	"base_safe": [false, 20, ["base_hit"], 0.0],
	"castle_safe": [false, 20, ["castle_lost"], 0.0],
	"mercs_safe": [false, 20, ["merc_lost"], 0.0],
	"heroes_safe": [false, 20, ["hero_down"], 0.0],
	"flawless": [true, 60, ["base_hit", "castle_lost", "structure_lost"], 0.0],
	"no_buying": [true, 50, ["merc_bought"], 0.0],
	"no_building": [true, 50, ["built"], 0.0],
	"swift": [true, 50, [], 120.0],
}

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

# EV212 · I118: data/quests의 파일 = 판의 미션·의뢰 종류이고, 값이 표와 같다
func ev212():
	var b = battle()
	var files := _files("res://data/quests")
	if files != _sorted(b.QUEST_KINDS.keys()) or files != _sorted(TABLE.keys()):
		return "파일 %s ≠ 종류 %s ≠ 표 %s" % [files, _sorted(b.QUEST_KINDS.keys()), _sorted(TABLE.keys())]
	for name in TABLE:
		var q: Dictionary = b.QUEST_KINDS[name]
		var want: Array = TABLE[name]
		if q.commission != want[0] or q.reward != want[1] or Array(q.zero) != want[2] or q.time_limit != want[3] or q.text == "":
			return "%s: 의뢰 %s 보상 %d 집계 %s 상한 %s 문장 «%s»(표는 %s)" % [name, q.commission, q.reward, q.zero, q.time_limit, q.text, want]
	return ""

# EV213 · I120: 미션은 라운드를 이기는 순간 판정되어 달성이면 보상 골드를 받고, 실패면 아무 일도 없다. 마지막 라운드도 판정한다
func ev213():
	var b = battle({"gold": 100, "base_hp": BIG, "rounds": ONE_ONE, "quests": ["base_safe"]})
	if b.mission != "base_safe" or b.commission != "" or not b.settled.is_empty():
		return "1라운드 미션이 %s다(base_safe여야 한다) · 의뢰 %s · 판정 %s" % [b.mission, b.commission, b.settled]
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

# EV214 · I121: 의뢰는 라운드 사이에만 고른다. 목록은 2개이고, 하나만 수락하며, 다시 누르면 무른다. 도전 시작 전·준비 단계에서는 거부된다
func ev214():
	var b = battle({"base_hp": BIG, "rounds": ONE_ONE, "seed": 3, "quests": ["no_buying", "no_building", "swift"]})
	b.begin_hiring()
	var before: bool = b.mission == "" and b.commission_offers.is_empty() and not b.accept(0) and b.commission == ""
	b.next_round()
	if not _win_round(b) or b.state != "cleared":
		return "1라운드를 이기지 못했다(%s)" % b.state
	var offers: Array = b.commission_offers.duplicate()
	var listed: bool = offers.size() == 2 and offers[0] != offers[1] and offers.all(func(n): return b.QUEST_KINDS[n].commission) and b.commission == ""
	var a: bool = b.accept(0) and b.commission == offers[0]
	var undo: bool = b.accept(0) and b.commission == ""
	var other: bool = b.accept(1) and b.commission == offers[1] and b.accept(0) and b.commission == offers[0]
	var bad: bool = not b.accept(5) and b.commission == offers[0]
	b.next_round()
	var kept: bool = b.state == "prep" and b.commission == offers[0] and b.commission_offers.is_empty() and not b.accept(0) and b.commission == offers[0]
	return check(before and listed and a and undo and other and bad and kept,
		"도전 시작 전 없음 %s · 목록 %s(%s) · 수락 %s · 무름 %s · 바꿈 %s · 범위 밖 거부 %s · 준비 단계 %s(의뢰 %s)" % [before, offers, listed, a, undo, other, bad, kept, b.commission])

# EV215 · S77: 수락한 의뢰는 다음 라운드 하나에 걸린다. 실패하면 벌칙 없이 보상만 없고(I54), 달성하면 보상 골드를 받는다(S66)
func ev215():
	var b = battle({"gold": 100, "base_hp": BIG, "rounds": [[ONE], [ONE], [ONE]], "quests": ["no_buying"]})
	var reward: int = b.ENEMY_KINDS.basic.reward
	var bonus: int = b.QUEST_KINDS.no_buying.reward
	if not _win_round(b) or b.commission_offers != ["no_buying"] or not b.accept(0):
		return "1라운드를 이기고 의뢰를 수락하지 못했다(%s, 목록 %s)" % [b.state, b.commission_offers]
	b.next_round()
	var cost: int = b.MERC_KINDS.soldier.cost
	if b.place_merc("soldier", Vector2i(20, 3)) == null:
		return "2라운드 준비 단계에 용병을 사지 못했다"
	if not _win_round(b) or b.state != "cleared":
		return "2라운드를 이기지 못했다(%s)" % b.state
	var failed: bool = b.gold == 100 + 2 * reward - cost and b.settled == [["no_buying", false]] and b.commission == ""
	var gold2: int = b.gold
	if b.commission_offers != ["no_buying"] or not b.accept(0):
		return "2라운드 뒤 의뢰를 수락하지 못했다(목록 %s)" % [b.commission_offers]
	b.next_round()
	if not _win_round(b) or b.state != "won":
		return "3라운드를 이기지 못했다(%s)" % b.state
	var done: bool = b.gold == gold2 + reward + bonus and b.settled == [["no_buying", true]]
	return check(failed and done, "2라운드(용병을 삼): 골드 %d(%d여야 한다) 판정 %s · 3라운드: 골드 %d(%d여야 한다) 판정 %s" %
		[gold2, 100 + 2 * reward - cost, b.settled if not failed else "실패", b.gold, gold2 + reward + bonus, b.settled])

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

# EV217 · I120: 미션은 도전의 미션 가운데 뽑히고, 둘 이상이면 지난 라운드와 같은 미션이 잇달아 나오지 않는다. 미션·의뢰가 없는 스테이지는 아무것도 바뀌지 않는다
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
	var plain: bool = d.gold == 100 + d.ENEMY_KINDS.basic.reward and d.settled.is_empty() and d.commission_offers.is_empty()
	return check(alternates and none and plain, "미션 순서 %s · 미션 없는 판: 처음 %s, 이긴 뒤 골드 %d 판정 %s 의뢰 목록 %s" % [seq, none, d.gold, d.settled, d.commission_offers])

# EV218 · I118: 시험 스테이지(`main.gd` stage())는 data/quests의 미션·의뢰를 모두 쓴다. 1라운드에 미션이 하나 있고, 이기면 서로 다른 의뢰 2개가 뜬다
func ev218():
	var b = load("res://src/sim/battle.gd").new(load("res://src/main.gd").stage())
	var all: bool = _sorted(b.quests) == _sorted(b.QUEST_KINDS.keys())
	var has: bool = b.mission != "" and b.mission in b.QUEST_KINDS and not b.QUEST_KINDS[b.mission].commission and b.commission == ""
	if not _win_round(b) or b.state != "cleared":
		return "1라운드를 이기지 못했다(%s)" % b.state
	var o: Array = b.commission_offers
	var offered: bool = o.size() == 2 and o[0] != o[1] and o.all(func(n): return n in b.QUEST_KINDS and b.QUEST_KINDS[n].commission)
	return check(all and has and offered, "모두 씀 %s(%s) · 1라운드 미션 %s · 의뢰 목록 %s" % [all, b.quests, b.mission, o])

# EV219 · I118: 조건마다 집계를 본다 — 용병을 잃으면 mercs_safe가, 영웅이 쓰러지면 heroes_safe가, 성곽 칸이 부서지면 castle_safe가,
#   구조물이 부서지면 flawless가, 지으면 no_building이 실패한다. 판매·수리·업그레이드는 조건을 깨지 않는다
func ev219():
	var b = _castle({"hero_start": H, "gold": 1000})
	var m = b.place_merc("soldier", M)
	var m2 = b.place_merc("soldier", M + Vector2i(2, 0))
	var all_met: bool = ["base_safe", "castle_safe", "mercs_safe", "heroes_safe", "flawless", "no_building"].all(b.quest_met)
	var bought: bool = not b.quest_met("no_buying")
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
	var fixed_ok: bool = b.quest_met("castle_safe") and b.quest_met("flawless") and b.quest_met("no_building") and k.hp == k.max_hp
	b.damage(k, BIG)
	var castle_lost: bool = not b.quest_met("castle_safe") and not b.quest_met("flawless") and b.quest_met("base_safe")
	var d = _castle({"gold": 1000})
	var t = d.build("tower", T)
	var built: bool = t != null and not d.quest_met("no_building") and d.quest_met("flawless")
	d.damage(t, BIG)
	var structure_lost: bool = not d.quest_met("flawless") and d.quest_met("castle_safe") and d.quest_met("base_safe")
	return check(all_met and bought and sold_ok and merc_lost and hero_down and fixed_ok and castle_lost and built and structure_lost,
		"처음 모두 달성 %s · 사면 no_buying 실패 %s · 판매는 괜찮음 %s · 용병 잃음 %s · 영웅 다운 %s · 수리·업그레이드는 괜찮음 %s · 성곽 칸 부서짐 %s · 지음 %s · 구조물 부서짐 %s" %
		[all_met, bought, sold_ok, merc_lost, hero_down, fixed_ok, castle_lost, built, structure_lost])

# EV220 · I118: swift는 라운드의 전투 시간 합이 상한 이하일 때만 달성이다
func ev220():
	var limit: float = battle().QUEST_KINDS.swift.time_limit
	var results := []
	for slow in [false, true]:
		var b = battle({"gold": 100, "base_hp": BIG, "rounds": ONE_ONE, "quests": ["swift"]})
		if not _win_round(b) or b.commission_offers != ["swift"] or not b.accept(0):
			return "1라운드를 이기고 swift를 수락하지 못했다(%s, 목록 %s)" % [b.state, b.commission_offers]
		b.next_round()
		var gold1: int = b.gold
		b.start_battle()
		if slow:
			run(b, limit + 5.0)
		if not clear_wave(b) or b.state != "won":
			return "2라운드를 이기지 못했다(%s)" % b.state
		results.append([b.tally.battle_time, b.settled, b.gold - gold1])
	var reward: int = battle().ENEMY_KINDS.basic.reward
	var bonus: int = battle().QUEST_KINDS.swift.reward
	var quick: bool = results[0][0] <= limit and results[0][1] == [["swift", true]] and results[0][2] == reward + bonus
	var late: bool = results[1][0] > limit and results[1][1] == [["swift", false]] and results[1][2] == reward
	return check(quick and late, "빨리 끝냄: 전투 %.1f초 판정 %s +%d골드 · 늦게 끝냄: 전투 %.1f초 판정 %s +%d골드(상한 %.0f초, 보상 %d)" %
		[results[0][0], results[0][1], results[0][2], results[1][0], results[1][1], results[1][2], limit, bonus])

# EV221 · I92: 새 도전은 수락한 의뢰·의뢰 목록·판정·집계를 비우고 1라운드 미션을 새로 뽑는다
func ev221():
	var b = battle({"base_hp": BIG, "rounds": ONE_ONE, "quests": ["base_safe", "no_buying"]})
	b.place_merc("soldier", Vector2i(20, 3))
	b.damage(b.base, 1)
	if not _win_round(b) or not b.accept(0):
		return "1라운드를 이기고 의뢰를 수락하지 못했다(%s, 목록 %s)" % [b.state, b.commission_offers]
	if b.commission != "no_buying" or b.settled.is_empty() or b.tally.merc_bought != 1:
		return "준비가 되지 않았다(의뢰 %s, 판정 %s, 집계 %s)" % [b.commission, b.settled, b.tally]
	b.restart()
	var clean: bool = b.mission == "base_safe" and b.commission == "" and b.commission_offers.is_empty() and b.settled.is_empty() and b.TALLY_KEYS.all(func(k): return b.tally[k] == 0)
	return check(clean, "새 도전: 미션 %s · 의뢰 %s · 목록 %s · 판정 %s · 집계 %s" % [b.mission, b.commission, b.commission_offers, b.settled, b.tally])
