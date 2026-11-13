extends Node
# 게임 장면의 효과음 연결(S269, S270). main이 프레임마다 화면 사건 목록(I171)을 hear로 넘기면 사건을 효과음 키로 바꿔 소리 노드(audio.gd)로 내고,
# 판 변화(놓기·공사 끝·영입·레벨)는 지난 프레임과 견줘 낸다. 웨이브 시작·보스 출현·놓기 거부는 신호로 받는다

const Audio := preload("res://src/audio.gd")
const Battle := preload("res://src/sim/battle.gd")
const NEAR := ["fire", "hit", "kill", "struct"]  # 보이는 맵 영역 안에서 났을 때만 소리를 내는 사건(S270)
const BURSTS := ["meteor", "burst", "loop", "resonate"]  # 칸(Q·W·E·R)이 아닌 영웅 스킬 흔적. 키가 slot 그대로다(S269)
const SHOTS := {"arrow": "arrow", "ball": "cannon"}  # 원거리 쏨의 투사체 모양(Battle.MISSILES) → 키. 나머지(구슬)는 bolt

var battle
var _primed := false  # 첫 hear는 판 상태를 기억만 한다(이어하기 직후 소리가 나지 않게)
var _built := 0  # 지난 프레임의 tally.built
var _bought := 0  # 지난 프레임의 tally.merc_bought
var _roster := 0
var _levels := {}  # 영웅 → 지난 프레임 레벨
var _building := {}  # 지난 프레임에 짓는 중이던 구조물

func _init(b, controls) -> void:
	name = "Sfx"
	battle = b
	b.wave_starting.connect(_play.bind("wave_start"))
	b.enemy_spawned.connect(_spawned)
	controls.refused.connect(func(_cell, _why): _play("refuse"))

# 화면 사건 하나 → 효과음 키(S269). 소리가 없으면 ""
static func key_for(e: Dictionary) -> String:
	var src = e.get("src")
	var dst = e.get("dst")
	match e.kind:
		"fire":
			if src == null or src is Battle.Enemy:
				return ""
			if src.get("pos") != null and src.range <= 2.0:  # 근접(battle_view._ranged와 같은 경계)
				return "swing"
			return SHOTS.get(Battle.MISSILES.get(src.kind, "bolt"), "bolt")
		"hit", "struct":
			if e.get("heavy", false):
				return "boom"
			if e.kind == "struct":
				return "struct_hit"
			return "hit" if dst is Battle.Enemy else "hurt"
		"kill":
			if dst is Battle.Enemy:
				return "enemy_die"
			return "hero_down" if dst != null and dst.get("is_hero") == true else "ally_down"
		"cast":
			var slot: String = e.get("slot", "")
			if slot in Battle.SLOTS:
				return "skill_" + src.get(slot).id
			return slot if slot in BURSTS else ""
		"boss":
			return "boss_skill"
		"interrupt":
			return "interrupt"
		"collapse":
			return "collapse"
		"counter":  # 원정 카운터 창 열림(S369 ⑥): 기존 키를 다시 쓴다(새 파일 없음)
			return "click"
		"wreck", "fall", "alone":  # 원정 보스의 형태 전환·홀로 남음(S369 ⑥)
			return "boss_appear"
	return ""

# 한 프레임: 사건을 소리로 내고(seen은 보이는 맵 영역, 맵 px) 판 변화를 견준다
func hear(events: Array, seen: Rect2) -> void:
	for e in events:
		if e.kind in NEAR and not seen.has_point(e.at):
			continue
		_play(key_for(e))
	var b = battle
	var levels := {}
	for h in b.roster:
		levels[h] = h.level
	var building := {}
	for s in b.structures.values():
		if not s.complete:
			building[s] = true
	if _primed:
		if b.tally.built > _built:
			_play("build")
		if b.roster.size() > _roster or b.tally.merc_bought > _bought:
			_play("hire")
		for h in levels:
			if levels[h] > _levels.get(h, levels[h]):
				_play("level_up")
		for s in _building:
			if s.complete and s.alive:
				_play("complete")
	_built = b.tally.built
	_bought = b.tally.merc_bought
	_roster = b.roster.size()
	_levels = levels
	_building = building
	_primed = true

func _spawned(e) -> void:
	if e.boss:
		_play("boss_appear")

func _play(key: String) -> void:
	Audio.of(get_tree()).play(key)
