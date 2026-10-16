extends RefCounted
# 전투 시뮬레이션. 화면 없이 돈다(그리기는 src/ui/). API 계약은 tests/eval/gd/lib.gd 머리 주석에 있다.

signal enemy_spawned(enemy)

# 종류 이름 → 수치. 판을 만들 때 data/ 아래 Resource 파일에서 읽는다(S31). 파일 이름이 종류 이름이다(I66)
# 상수였을 때의 이름을 그대로 둔다(UI·테스트가 battle.MERC_KINDS.soldier.cost처럼 읽는다)
var ENEMY_KINDS := _kinds("res://data/enemies/")
var MERC_KINDS := _kinds("res://data/mercs/")
var STRUCTURE_KINDS := _kinds("res://data/structures/")
var HERO_KINDS := _kinds("res://data/heroes/")  # 효과의 뜻은 src/data/hero_def.gd 머리 주석(S97, I95)
var HIRE = load("res://data/hire.tres")  # 영입소 수치(S123, I103)
var LEVELS = load("res://data/levels.tres")  # 영웅 레벨 수치(S126, I111)
var QUEST_KINDS := _kinds("res://data/quests/")  # 미션·의뢰 정의(S77, I118). 칸의 뜻은 src/data/quest_def.gd 머리 주석
const VILLAGE_UP := [60]  # 마을 레벨 n→n+1 비용(S99). 길이+1이 최대 레벨이다. 임시값(Claude 예시, 사용자 2026-10-13 수락)
const MERC_CAP := 10  # 배치 상한 기본값(S25). 임시값(사용자 2026-10-13), 스테이지의 merc_cap이 덮어쓴다
const HOUSE_CAP := 6  # 마을에 지을 수 있는 집 수(S101). 임시값(사용자 2026-10-13)
const QUEST_OFFERS := 2  # 라운드 사이에 보이는 의뢰 수(I121). 임시값(Claude 예시)
const TALLY_KEYS := ["base_hit", "castle_lost", "structure_lost", "merc_lost", "hero_down", "merc_bought", "built", "battle_time"]  # 라운드 집계의 키(I119)
const SPAWN_GAP := 0.9  # 웨이브 안에서 적이 나오는 간격(초). 임시값: 1.0 → 0.9(2026-10-15 3장 자체 점검, 사용자 승인 2026-10-16 — insights/2026-10-15_ch3_self_check_balance.md §8)
const REACH := 1.0      # 적이 막힌 칸·거점·유닛을 칠 수 있는 거리(중심 사이). 옆 칸 중심까지가 1이다
const UNIT_WALL_K := 1e6  # 유닛 경로의 막힌 칸 비용 배율. 돌아갈 길이 있으면 막힌 칸(닫힌 성문 포함, I42)을 지나지 않는다
const WORK_REACH := 2.0  # 공병이 일하는 거리(중심 사이). 옆 칸 대각선(1.41)에, 무리에 밀려 0.5칸 못 미친 도착(I51)을 더했다
# 성곽 업그레이드(S86): 한 단계마다 최대 체력 ×UPGRADE_MULT. 비용은 종류별 1→2단계 값이고 다음 단계는 2배. 수치는 임시값
const UPGRADE_COST := {"castle_wall": 10, "gate": 20}
const UPGRADE_MULT := 1.5
const UPGRADE_MAX := 3
const UPGRADE_TIME := 5.0  # 전투 중 공병이 한 단계 올리는 시간(초)
const GATE_LOCK := 20.0  # 전투 단계에 여닫은 성문을 다시 여닫지 못하는 시간(초, S135). 핑퐁 봇 측정을 보고 사용자가 고름(insights/2026-10-16_gate_cooldown.md)
# 수리(S114): 성곽·거점의 체력 1당 수리비(골드). 구조물은 낸 골드 ÷ 최대 체력이다. 수치는 임시값
const REPAIR_RATE := {"castle_wall": 0.1, "gate": 0.1, "base": 1.0}
const REPAIR_TIME := 5.0  # 전투 중 공병이 성곽·거점을 0에서 가득 채우는 시간(초, I87). 구조물은 건설 시간이다
const WALL_RANGE := 2.0  # 성벽 위에서 치려면 필요한 사거리(칸, S88). 열린 성문 위는 예외다(S89). 임시값

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
	var splash := 0.0  # 범위 피해 반경(칸, S90)
	var pierce := false  # 적의 장갑을 무시한다(마법 타워, S110)
	var ward := 0.0  # 축성가 W로 받은 «받는 피해 감소» 비율. ward_left초 동안만(S120)
	var ward_left := 0.0
	var cooldown := 0.0
	var target  # 마지막으로 쏜 적. 화면이 쏜 직후 사격 선을 그린다
	var paid := 0  # 지을 때 낸 골드. 판매 환불의 기준(S69)
	var produces := []  # 생산 시설이면 파는 용병 kind들. 첫째가 기본이다(S20, S87)
	var rally: Vector2i  # 생산 시설의 집결 지점(S21)
	var tax := 0  # 집이면 준비 단계마다 내는 세금(S101)
	var progress := 1.0  # 건설 진행률(0~1). 1 미만이면 미완성이다(I62)
	var full: float  # 다 지었을 때의 체력. 옮겨 다시 짓는 대포는 옮기기 전 체력이다(I74)
	var build_time := 1.0  # 전투 중 짓는 데 드는 시간(초)
	var worker  # 이 구조물을 짓거나 허무는(그러러 가는) 공병
	var razed := 0.0  # 철거 진행률(0~1, I64). 옮기는 대포는 1이면 접혀 새 칸으로 가는 중이다(I74)
	var dest  # 대포를 옮겨 갈 칸(S44). 옮기는 중이 아니면 null
	var open := false  # 열린 성문(S85). 막힌 칸이 아니다(I67)
	var lock := 0.0  # 성문 쿨타임(S135)의 남은 초. 0보다 크면 여닫기 지시를 거부한다
	var level := 1  # 성곽 업그레이드 단계(S86)
	var lift := -1.0  # 업그레이드 진행률(0~1). 음수면 올리는 중이 아니다. 그만두면 그대로 남는다(I68)
	var mend := 0.0  # 수리비를 냈지만 아직 채우지 못한 체력(I87). 0보다 크면 공병이 마저 고친다

	func _init(c: Vector2i, k: String, h: float) -> void:
		cell = c
		kind = k
		max_hp = h
		hp = h
		full = h

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
	var xp := 0  # 처치되면 그때 살아 있는 출전 영웅이 저마다 받는 경험치(S125)
	var armor := 0.0  # 받는 피해를 이만큼 줄인다(S108)
	var flying := false  # 경로 층을 무시하고 곧장 난다(S109, I79)
	var climb := 0.0  # 성곽 성벽을 오르는 시간(초). 0이면 오르지 않는다(S107, I76)
	var climbed := 0.0  # 지금 성벽을 오른 시간(초)
	var on_wall := false  # 성곽 성벽 칸 위에 올라서 있다(I76)
	var cooldown := 0.0  # 0 이하면 바로 칠 수 있다
	var expose := 0.0  # 궁수 W로 받은 «받는 피해 증가» 비율. expose_left초 동안만(I99)
	var expose_left := 0.0
	var slow := 0.0  # 마도사 W로 받은 «이동 속도 감소» 비율. slow_left초 동안만(I99)
	var slow_left := 0.0
	var stun_left := 0.0  # 장군 Q의 기절. 남은 동안 움직이지도 치지도 않는다(I98)
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
	# 영웅만 쓰는 칸. 종류별 수치와 효과의 뜻은 src/data/hero_def.gd(S97, I95)
	var is_hero := false
	var home: Vector2i  # 쓰러진 영웅이 돌아오는 시작 칸(S26, I102)
	var grade := 0
	var level := 1  # 영웅 레벨(S60, S126). 경험치로 정해진다(Battle._set_xp)
	var xp := 0
	var skill_damage := 0.0
	var skill_stun := 0.0
	var skill_heal := 0.0
	var skill_mend := 0.0
	var skill_radius := 0.0
	var skill_gap := 0.0  # 재사용 대기(초). 0이면 스킬이 없다
	var skill_cooldown := 0.0
	var skill_uses := 0
	var buff_radius := 0.0
	var buff_mult := 1.0
	var buff_expose := 0.0
	var buff_guard := 0.0
	var buff_ward := 0.0
	var buff_slow := 0.0
	var buff_time := 0.0
	var buff_gap := 0.0  # 재사용 대기(초). 0이면 스킬 2가 없다
	var buff_cooldown := 0.0
	var aura_radius := 0.0
	var aura_guard := 0.0  # 오라 안 용병이 받는 피해를 줄이는 비율(0~1). 0이면 그 오라가 없다
	var aura_haste := 0.0
	var aura_work := 0.0
	var aura_regen := 0.0
	var aura_might := 0.0
	var aura_stride := 0.0
	var aura_gunnery := 0.0
	# W로 받은 효과. _left초 동안만 걸린다(I97)
	var boost := 1.0  # 용병 공격력 배율(S84)
	var boost_left := 0.0
	var guard := 0.0  # 받는 피해 감소 비율(사제 W, I99)
	var guard_left := 0.0
	var on_wall := false  # 성벽 위에 있다(S42, I44)
	var after: Array[Vector2i] = []  # path 끝에서 오르내린 뒤 걸을 길. 첫 칸이 오르내려 서는 칸이다(I69)

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
	var climb := 0.0  # 성곽 성벽 칸의 비용(오르는 시간 × 속도, I76). 기어오르는 적의 경로를 구하는 동안만 0보다 크다

	# 성곽을 먼저 본다. 성벽 위 대포의 칸은 성벽이다(I72)
	func block_at(c: Vector2i):
		var b = castle.get(c, structures.get(c))
		return null if b and b.open else b

	func _compute_cost(from: Vector2i, to: Vector2i) -> float:
		# 옆 칸이 막혔으면 대각선으로 끼어들지 않는다(solid였을 때의 DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES와 같게)
		if from.x != to.x and from.y != to.y and (block_at(Vector2i(to.x, from.y)) or block_at(Vector2i(from.x, to.y))):
			return 1e9
		var b = block_at(to)
		if b and climb > 0.0 and b.kind == "castle_wall":  # 부수지 않고 넘는다(I43)
			return Vector2(to - from).length() + climb
		return Vector2(to - from).length() + (b.hp * wall_k if b else 0.0)

var size: Vector2i
var spawns: Array
var waves: Array  # 지금 라운드의 웨이브
var rounds: Array  # 도전의 라운드마다 웨이브 배열(S63, I91). stage에 rounds가 없으면 waves 하나가 1라운드짜리 도전이다
var base: Block
var castle := {}      # Vector2i → Block
var structures := {}  # Vector2i → Block
var rubble := {}  # Vector2i → 부서진 성곽 칸 Block(I88). 지나갈 수 있고, 복구하면 castle로 돌아간다(I89)
var enemies := []
var units := []  # 살아 있는 영웅·용병
var heroes := []  # 전장에 나온 출전 영웅(Unit)들, 보유 순서(I108). 쓰러진 영웅도 들어 있다(I102)
var hero  # 첫 출전 영웅(S119, I108). 영웅이 없으면 null
var roster := []  # 보유 영웅, 영입 순서(S58, S59). 새 도전이면 비운다(S64)
var lineup := []  # 다음 라운드에 출전할 영웅(S59, I106). 영입 창에서 바꾸고 다음 라운드로 넘어갈 때 전장에 반영한다(S124)
var offers := []  # 영입소 목록: 칸마다 영웅 종류, 영입한 칸은 ""(I103, I104)
var quests := []  # 이 도전에서 뜰 수 있는 미션·의뢰 이름(I118). 스테이지의 quests가 정한다. 비어 있으면 미션·의뢰가 없다
var mission := ""  # 지금 라운드의 미션(S77, I120). 없으면 ""
var commission := ""  # 수락한 의뢰(S77, I121). 다음 라운드 하나에 걸린다. 없으면 ""
var commission_offers := []  # 라운드 사이에 고를 수 있는 의뢰 이름(I121)
var settled := []  # 지난 라운드의 미션·의뢰 판정 [이름, 달성 여부](I120). 결과 창이 보인다(I122)
var tally := {}  # 라운드 집계(I119): TALLY_KEYS → 수. 라운드가 시작될 때 0이 된다
var revive := true  # 쓰러진 영웅이 다음 준비 단계에 돌아온다(S27). 기본값 켜짐(I28)
var state := "prep"  # "prep" | "battle" | "hiring"(도전 시작 전 영입 창, S122) | "cleared"(라운드 사이, S117) | "won"(도전 성공) | "lost"
var round_index := 0
var wave_index := 0
var gold := 0
var village := Rect2i()  # 마을 칸. 생산 시설은 안에만, 나머지 구조물은 밖에만 짓는다(S43). 비어 있으면 모두 들판
var merc_cap := MERC_CAP
var village_level := 1  # 오를수록 지을 수 있는 생산 시설이 는다(S46, S99)

var grid := CostGrid.new()
var _wall := AStarGrid2D.new()  # 성벽 위 길. 성곽 칸만 걸을 수 있다(I69)
var _repath := false  # 막힌 칸이 바뀌어 적 경로를 다시 구해야 한다
var _queue := []      # 이번 웨이브에서 아직 안 나온 적 종류
var _spawn_timer := 0.0
var _spawned := 0     # 이번 웨이브에서 나온 적 수(출현 지점 돌아가며 쓰기)
var _stage: Dictionary  # 재시작할 때 다시 읽는다
var _rng := RandomNumberGenerator.new()  # 영입소 목록을 뽑는다. 스테이지에 seed가 있으면 그 씨앗이다(평가용)

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
	rounds = stage.get("rounds", [stage.get("waves", [])])
	grid.region = Rect2i(Vector2i.ZERO, size)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	_wall.region = grid.region
	_wall.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_wall.update()
	grid.castle = castle
	grid.structures = structures
	_stage = stage
	restart()

# 새 도전(S29, S64): 1라운드를 stage 그대로 처음 상태로 놓는다. 앞 도전에서 남는 것은 없다(I92)
# 컬렉션은 새로 만들지 않고 비운다. grid와 화면이 같은 객체를 쥐고 있다
func restart() -> void:
	var stage := _stage
	state = "prep"
	round_index = 0
	waves = rounds[0]
	wave_index = 0
	gold = stage.get("gold", 0)
	village = stage.get("village", Rect2i())
	merc_cap = stage.get("merc_cap", MERC_CAP)
	village_level = 1
	for s in structures.values() + castle.values() + rubble.values() + ([base] if base else []):  # 공병 ↔ 구조물 상호 참조를 끊는다. 남기면 RefCounted 순환이라 해제되지 않는다
		_release(s)
	base = Block.new(stage.base, "base", stage.base_hp)
	castle.clear()
	rubble.clear()
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
	heroes.clear()
	# 영웅 목록(I102). 목록이 없고 hero_start만 있으면 기사 하나다. 이 영웅들은 보유·출전한 채 시작한다(평가용 스테이지)
	# 레벨(level)을 정하지 않으면 최대 레벨이다(I115)
	var team: Array = stage.get("heroes", [] if stage.get("hero_start") == null else [{"kind": "knight", "cell": stage.hero_start}])
	for t in team:
		var h := Unit.new(t.kind, t.cell, HERO_KINDS[t.kind])
		h.is_hero = true
		h.home = t.cell
		_set_xp(h, LEVELS.steps.slice(0, t.get("level", LEVELS.steps.size() + 1) - 1).reduce(func(s, x): return s + x, 0))
		heroes.append(h)
		units.append(h)
	hero = heroes[0] if heroes else null
	roster = heroes.duplicate()
	lineup = heroes.duplicate()
	if stage.has("seed"):
		_rng.seed = stage.seed
	else:
		_rng.randomize()
	_draw_offers()  # 도전을 시작할 때 무료로 뽑는다(I104)
	var q = stage.get("quests", [])  # 미션·의뢰(I118): true면 data/quests의 모든 것, 배열이면 그 이름들만(평가용). 없으면 뜨지 않는다
	quests = QUEST_KINDS.keys() if q is bool and q else (q.duplicate() if q is Array else [])
	quests.sort()
	mission = ""
	commission = ""
	commission_offers.clear()
	settled.clear()
	_reset_tally()
	_draw_mission()  # 1라운드의 미션(I120)

func step(dt: float) -> void:
	if state == "battle":
		_spawn_wave(dt)
		tally.battle_time += dt  # 라운드 집계(I119)
	if _repath:
		_repath = false
		for e in enemies:
			_find_path(e)
	for e in enemies:
		_move(e, dt)
	_push_apart(enemies, units)
	var ground := units.filter(func(u): return not u.on_wall)  # 성벽 위 유닛은 밀리지 않는다(I70)
	for u in units:
		_act(u, dt)
	_push_apart(ground, enemies)
	_fire(dt)
	if state == "battle" and _queue.is_empty() and enemies.is_empty():
		wave_index += 1
		if wave_index < waves.size():
			state = "prep"
		elif round_index + 1 < rounds.size():
			state = "cleared"  # 라운드 사이(S117). 다음 라운드는 next_round로 간다
			_draw_offers()  # 목록은 라운드를 이길 때 무료로 새로 뽑는다(I104)
		else:
			state = "won"  # 마지막 라운드를 이겨 도전에 성공했다(I92)
		if state != "prep":  # 라운드를 이겼다: 미션과 수락한 의뢰를 판정해 보상을 준다(S77, I120). 라운드 사이에는 새 의뢰 목록을 보인다(I121)
			_settle_quests()
			if state == "cleared":
				_draw_commissions()
		if state != "won":  # 준비 단계나 라운드 사이로 넘어갈 때 걷는다(I46)
			gold += tax()
		for s in structures.values() + castle.values() + rubble.values() + [base]:  # 하던 건설·철거·업그레이드·수리·복구는 그 상태로 멈춘다(I19, I68, I87)
			_release(s)
		if state == "prep" and revive:
			for h in heroes:
				if not h.alive:
					_return_hero(h)
	for s in structures.values() + castle.values():  # 축성가 W의 남은 시간(S120)
		s.ward_left -= dt
	for k in castle.values() + rubble.values():  # 성문 쿨타임은 전투 단계에만 줄고, 웨이브가 끝나면 사라진다(S135)
		k.lock = maxf(k.lock - dt, 0.0) if state == "battle" else 0.0

# 영웅을 자기 시작 칸에 체력이 가득 찬 채 세운다: 쓰러졌다 돌아올 때(S26, I27, I102)와 새로 출전할 때(S124)
# 공격·스킬 대기는 쓰러질 때 값을 이어 간다(S67)
func _return_hero(h: Unit) -> void:
	h.alive = true
	h.hp = h.max_hp
	h.pos = Vector2(h.home)
	h.on_wall = false
	h.path.clear()
	h.after.clear()
	units.append(h)

func start_battle() -> void:
	if state != "prep" or wave_index >= waves.size():
		return
	state = "battle"
	for entry in waves[wave_index]:
		for i in entry.count:
			_queue.append(entry.kind)
	_spawn_timer = 0.0
	_spawned = 0

# 영입 창(S122)이나 라운드 사이(S117)에서 1라운드나 다음 라운드의 첫 준비 단계로 간다. 그 밖에서는 거부한다
# 출전 목록을 전장에 반영하고(S124), 구조물·성곽·마을·용병·골드와 계속 출전하는 영웅은 그대로 이어진다(S63, S79, S61, I93)
# 쓰러진 영웅은 부활 설정과 상관없이 시작 지점으로 돌아온다(I93)
func next_round() -> bool:
	if not hiring_open():
		return false
	if state == "cleared":
		round_index += 1
		waves = rounds[round_index]
		wave_index = 0
		commission_offers.clear()
		settled.clear()
		_reset_tally()  # 새 라운드의 집계와 미션(I119, I120). 수락한 의뢰는 이 라운드에 걸린다(I121)
		_draw_mission()
	state = "prep"
	_deploy()
	for h in heroes:
		if not h.alive:
			_return_hero(h)
	return true

# [동작] 도전 시작 전 영입 창(S122)을 연다. main·HUD가 새 도전(restart) 직후에 부른다
# [이유] restart()가 곧바로 열지 않는 것은 동결된 평가(EV36·EV80·EV165·EV170)가
#        «restart 직후 = 1라운드 웨이브 1의 준비 단계»에 기대서다
func begin_hiring() -> void:
	state = "hiring"

# 영입 창(도전 시작 전·라운드 사이)이 떠 있다. 영입·리롤·내보내기·출전 선택은 이때만 한다(I104)
func hiring_open() -> bool:
	return state in ["hiring", "cleared"]

# 목록을 모두 새로 뽑는다(I103): 칸마다 등급을 등장 확률로 고르고, 그 등급의 영웅 가운데 하나를 같은 확률로 고른다
func _draw_offers() -> void:
	offers.clear()
	for i in HIRE.slots:
		var grade: int = _rng.rand_weighted(PackedFloat32Array(HIRE.odds)) + 1
		var kinds := HERO_KINDS.keys().filter(func(k): return HERO_KINDS[k].grade == grade)
		offers.append(kinds[_rng.randi_range(0, kinds.size() - 1)])

# 목록의 i번째 영웅을 영입한다(S54). 빈 칸이거나, 골드가 모자라거나(I104), 보유 상한(S123)이면 거부한다
# 출전 목록이 차지 않았으면 바로 출전 목록에 넣는다(I106)
func hire(i: int):
	if not hiring_open() or offers[i] == "" or roster.size() >= HIRE.cap:
		return null
	var stats: Dictionary = HERO_KINDS[offers[i]]
	var cost: int = HIRE.cost[stats.grade - 1]
	if gold < cost:
		return null
	gold -= cost
	var h := Unit.new(offers[i], Vector2i.ZERO, stats)
	h.is_hero = true
	offers[i] = ""
	roster.append(h)
	if lineup.size() < HIRE.lineup:
		lineup.append(h)
	return h

# 리롤 비용(S123)을 내고 목록을 모두 새로 뽑는다(S57, I104). 골드가 모자라거나 보유 영웅이 상한이면 거부한다(I127)
func reroll() -> bool:
	if not hiring_open() or gold < HIRE.reroll or roster.size() >= HIRE.cap:
		return false
	gold -= HIRE.reroll
	_draw_offers()
	return true

# 보유 영웅을 내보낸다(I105). 환불은 없다. 전장에 있으면 다음 라운드로 넘어갈 때 사라진다(S124)
func dismiss(h) -> void:
	if hiring_open():
		roster.erase(h)
		lineup.erase(h)

# 보유 영웅을 출전 목록에 넣거나 뺀다(S59). 출전 인원(S123)이 차 있으면 넣기를 거부한다
func set_lineup(h, on: bool) -> bool:
	if not hiring_open() or h not in roster or (on and h not in lineup and lineup.size() >= HIRE.lineup):
		return false
	if not on:
		lineup.erase(h)
	elif h not in lineup:
		lineup.append(h)
	return true

# 출전 목록을 전장에 반영한다(S124). 빠진 영웅은 전장에서 사라지고, 계속 출전하는 영웅은 자리·체력이 그대로다.
# 새로 출전한 영웅은 다른 출전 영웅이 시작 칸으로 쓰지 않는 첫 출전 칸에 최대 체력으로 선다(I107)
func _deploy() -> void:
	for h in heroes:
		if h not in lineup:
			units.erase(h)
	var team := roster.filter(func(h): return h in lineup)  # 출전 순서는 보유 순서다(I108)
	var homes := team.filter(func(h): return h in heroes).map(func(h): return h.home)
	for h in team:
		if h not in heroes:
			h.home = _stage.hero_cells.filter(func(c): return c not in homes)[0]
			homes.append(h.home)
			_return_hero(h)
	heroes.assign(team)
	hero = heroes[0] if heroes else null

# 영웅 경험치를 n만큼 더한다(S125). 레벨·최대 체력·공격력은 _set_xp가 맞춘다
func add_xp(h: Unit, n: int) -> void:
	_set_xp(h, h.xp + n)

# 경험치를 정하고(최대 레벨의 누적 경험치가 상한, I113) 레벨을 S126의 누적 경험치로 맞춘다.
# 최대 체력·공격력은 Lv1 값 × (1 + growth × (레벨 − 1))이다(I112). 체력은 최대 체력이 오른 만큼 오르고, 줄면 새 최대 체력을 넘지 않는다.
# 이관은 transfer가 체력 비율을 따로 맞춘다(I116)
func _set_xp(h: Unit, xp: int) -> void:
	h.xp = mini(xp, LEVELS.steps.reduce(func(s, x): return s + x, 0))
	h.level = 1
	var need := 0
	for step in LEVELS.steps:
		need += step
		if h.xp >= need:
			h.level += 1
	var base: Dictionary = HERO_KINDS[h.kind]
	var mult: float = 1.0 + LEVELS.growth * (h.level - 1)
	var max_hp: float = base.hp * mult
	if h.alive:
		h.hp = minf(h.hp + maxf(max_hp - h.max_hp, 0.0), max_hp)
	h.max_hp = max_hp
	h.damage = base.damage * mult

# 라운드 사이에 보유 영웅 둘 사이이고, 받는 영웅이 경험치를 다 받아도 상한(I113)을 넘지 않는다(S127, I116)
func can_transfer(from, to) -> bool:
	return state == "cleared" and from != to and from in roster and to in roster and to.xp + from.xp <= LEVELS.steps.reduce(func(s, x): return s + x, 0)

# 라운드 사이에만, 주는 영웅의 경험치를 전부 받는 영웅에게 옮긴다(S127, U14). 주는 영웅은 Lv1로 돌아가 보유 목록에 남는다. 비용은 없다.
# 레벨이 바뀐 두 영웅의 체력 비율은 그대로다(I116)
func transfer(from: Unit, to: Unit) -> bool:
	if not can_transfer(from, to):
		return false
	for pair in [[to, to.xp + from.xp], [from, 0]]:
		var ratio: float = pair[0].hp / pair[0].max_hp
		_set_xp(pair[0], pair[1])
		pair[0].hp = ratio * pair[0].max_hp
	return true

# 라운드 집계(I119)를 0으로 돌린다. 도전을 시작할 때와 다음 라운드로 넘어갈 때
func _reset_tally() -> void:
	for k in TALLY_KEYS:
		tally[k] = 0.0 if k == "battle_time" else 0

# 이 도전의 미션 가운데 하나를 같은 확률로 뽑아 이번 라운드의 미션으로 둔다(I120). 둘 이상이면 지난 라운드의 미션은 피한다. 없으면 ""
func _draw_mission() -> void:
	var pool := quests.filter(func(n): return not QUEST_KINDS[n].commission)
	if pool.size() > 1:
		pool.erase(mission)
	mission = pool[_rng.randi_range(0, pool.size() - 1)] if not pool.is_empty() else ""

# 이 도전의 의뢰 가운데 QUEST_OFFERS개를 서로 다르게 같은 확률로 뽑아 목록에 둔다(I121). 의뢰가 그보다 적으면 있는 만큼이다
func _draw_commissions() -> void:
	var pool := quests.filter(func(n): return QUEST_KINDS[n].commission)
	commission_offers.clear()
	for i in mini(QUEST_OFFERS, pool.size()):
		commission_offers.append(pool.pop_at(_rng.randi_range(0, pool.size() - 1)))

# 라운드 사이에만, 의뢰 목록의 i번째를 수락한다(S77, I121). 수락한 의뢰를 다시 수락하면 무른다. 의뢰는 하나만 수락한다
func accept(i: int) -> bool:
	if state != "cleared" or i < 0 or i >= commission_offers.size():
		return false
	commission = "" if commission == commission_offers[i] else commission_offers[i]
	return true

# 라운드를 이긴 순간 미션과 수락한 의뢰를 판정한다(S77, I120): 조건을 채웠으면 보상 골드를 받는다(S66). 실패해도 벌칙은 없다(I54)
# 판정은 settled에 남기고(I122), 수락한 의뢰는 다 쓴 것이라 비운다. 미션은 다음 라운드를 뽑을 때까지 둔다(_draw_mission이 피한다)
func _settle_quests() -> void:
	settled.clear()
	for name in [mission, commission]:
		if name != "":
			var done := quest_met(name)
			if done:
				gold += QUEST_KINDS[name].reward
			settled.append([name, done])
	commission = ""

# 미션·의뢰의 조건(I118)을 지금 집계가 채우나: zero의 집계가 모두 0이고, 시간 상한이 있으면 전투 시간 합이 그 이하다
func quest_met(name: String) -> bool:
	var q: Dictionary = QUEST_KINDS[name]
	return q.zero.all(func(k): return tally[k] == 0) and (q.time_limit <= 0.0 or tally.battle_time <= q.time_limit)

func spawn_enemy(kind: String, cell: Vector2i, overrides := {}):
	var e := Enemy.new(kind, cell, ENEMY_KINDS[kind].merged(overrides, true))
	e.goal = base.cell
	_find_path(e)
	enemies.append(e)
	enemy_spawned.emit(e)
	return e

# 준비 단계가 시작될 때 걷는 세금: 완성된 집의 세금 합이다. 미완성·부서진·팔린 집은 내지 않는다(I46, S102)
func tax() -> int:
	return structures.values().reduce(func(n, s): return n + (s.tax if s.complete else 0), 0)

# 준비 단계에만 골드를 내고 마을 레벨을 하나 올린다(S99, I47). 최대 레벨이거나 골드가 모자라면 거부한다
func raise_village() -> bool:
	if state != "prep" or village_level > VILLAGE_UP.size() or gold < VILLAGE_UP[village_level - 1]:
		return false
	gold -= VILLAGE_UP[village_level - 1]
	village_level += 1
	return true

# 준비 단계 구매(S50): 마을이 있는 스테이지면 그 용병을 파는 완성된 생산 시설이 있어야 한다
func can_buy(kind: String) -> bool:
	return not village.has_area() or structures.values().any(func(s): return s.complete and kind in s.produces)

# 준비 단계에만, 놓을 수 있는 칸(_merc_cell)에 바로 놓는다(S18). 성곽 칸이면 그 칸의 성벽 위에 선다(I134). 골드가 모자라면 거부한다(I16)
# 시설 조건(S50)은 보지 않는다. 플레이어의 구매는 Controls가 can_buy로 먼저 묻는다
func place_merc(kind: String, cell: Vector2i, overrides := {}):
	if state != "prep" or not _merc_cell(cell):
		return null
	var stats: Dictionary = MERC_KINDS[kind].merged(overrides, true)
	if gold < stats.cost or _mercs() >= merc_cap:
		return null
	gold -= stats.cost
	var m := Unit.new(kind, cell, stats)
	m.on_wall = castle.has(cell)
	m.paid = stats.cost
	units.append(m)
	tally.merc_bought += 1  # 라운드 집계(I119)
	return m

# 용병을 놓을 수 있는 칸: 거점이 아닌 맵 안 칸 가운데 막히지 않은 칸이나, 대포가 없는 성곽 칸(I134)
func _merc_cell(cell: Vector2i) -> bool:
	return grid.is_in_boundsv(cell) and cell != base.cell and (not grid.block_at(cell) or (castle.has(cell) and not structures.has(cell)))

# 유닛들을 그 칸으로 보낸다(S14). 맵 밖 칸이면 무시한다. 성곽 칸이면 성벽 위의 그 칸으로 간다(I69)
func order_move(group: Array, cell: Vector2i) -> void:
	if not grid.is_in_boundsv(cell):
		return
	grid.wall_k = UNIT_WALL_K
	_wall.fill_solid_region(_wall.region)  # 부서진 성곽 칸이 빠지게 매번 새로 깐다
	for c in castle:
		_wall.set_point_solid(c, false)
	for u in group:
		u.rally_from = null
		if u.job:  # 공병은 하던 일을 그만둔다(I63)
			_release(u.job)
		if u.alive:
			_route(u, cell)

# 땅과 성벽 위를 오가면 path 끝(성문 안쪽 칸이나 성문 칸)에서 오르내린 뒤 after를 걷는다(I44).
# 오르내릴 성문은 «땅 위 경로 비용 + 성벽 위 걸음 수»가 가장 작은 곳이다(I69)
func _route(u: Unit, cell: Vector2i) -> void:
	var from := Vector2i(u.pos.round())
	var up := castle.has(cell)
	u.path.clear()
	u.after.clear()
	if u.on_wall == up:
		u.path = (_wall.get_id_path(from, cell) if up else grid.get_id_path(from, cell, true)).slice(1)
		return
	var best := INF
	for g in castle:
		var s = _stair(g)
		if s == null:
			continue
		var top: Array[Vector2i] = _wall.get_id_path(from, g) if u.on_wall else _wall.get_id_path(g, cell)
		var ground: Array[Vector2i] = grid.get_id_path(s, cell, true) if u.on_wall else grid.get_id_path(from, s, true)
		var cost := _cost(ground) + top.size()
		if not top.is_empty() and cost < best:
			best = cost
			u.path = (top if u.on_wall else ground).slice(1)
			u.after = ground if u.on_wall else top

# 성문 바로 안쪽(마을 쪽) 칸. 성문이 아니거나 마을에 닿지 않으면 null(I44)
func _stair(g: Vector2i):
	if castle[g].kind != "gate":
		return null
	for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if village.has_point(g + d):
			return g + d
	return null

func _cost(path: Array[Vector2i]) -> float:
	var sum := 0.0
	for i in range(1, path.size()):
		sum += grid._compute_cost(path[i - 1], path[i])
	return sum

# 용병의 이동 방식(S35)·홀드(S36)를 바꾼다. 영웅에게는 걸지 않는다(S16)
func set_move_mode(group: Array, mode: String) -> void:
	assert(mode in ["move", "attack_move"], "이동 방식 %s" % mode)
	for u in group:
		if not u.is_hero:
			u.move_mode = mode

func set_hold(group: Array, on: bool) -> void:
	for u in group:
		if not u.is_hero:
			u.hold = on
			u.anchor = u.pos  # 기준 지점은 켠 순간의 위치(I37)

# 살아 있는 출전 영웅 가운데 첫 영웅(I126). 없으면 null
func _first_alive():
	for h in heroes:
		if h.alive:
			return h
	return null

# 영웅 스킬(S15, S95): 영웅 h(없거나 쓰러졌으면 살아 있는 첫 영웅, S119, I126)가 주변 skill_radius칸에 쓴다. 명령으로만 쓴다
# 적 피해·기절, 영웅·용병 회복, 구조물·성곽 칸 회복 가운데 그 영웅이 가진 것만 걸린다(S97, I98, S120)
func use_skill(h = null) -> void:
	h = h if h and h.alive else _first_alive()
	if not h or not h.alive or not h.skill_ready():
		return
	h.skill_cooldown = h.skill_gap
	h.skill_uses += 1
	for e in enemies.duplicate():
		if e.pos.distance_to(h.pos) <= h.skill_radius:
			e.stun_left = maxf(e.stun_left, h.skill_stun)
			if h.skill_damage > 0.0:
				damage(e, h.skill_damage)
	if h.skill_heal > 0.0:
		for u in units:
			if u.pos.distance_to(h.pos) <= h.skill_radius:
				u.hp = minf(u.hp + h.skill_heal, u.max_hp)
	if h.skill_mend > 0.0:
		for s in _fortified(h.pos, h.skill_radius):
			s.hp = minf(s.hp + h.skill_mend, s.max_hp)
		_repath = true  # 남은 체력이 적의 경로 비용이다(S7)

# 영웅 스킬 2(S84, S97): 영웅 h(없거나 쓰러졌으면 살아 있는 첫 영웅, S119, I126)가 지금 주변 buff_radius칸 안에 있는 대상에게만 건다(I65, I97). 명령으로만 쓴다
# 용병 공격력은 영웅에게 걸리지 않는다(I99)
func use_buff(h = null) -> void:
	h = h if h and h.alive else _first_alive()
	if not h or not h.alive or not h.buff_ready() or h.level < LEVELS.buff_level:  # W는 정해진 레벨에 열린다(S76, I114)
		return
	h.buff_cooldown = h.buff_gap
	for u in units:
		if u.pos.distance_to(h.pos) <= h.buff_radius:
			if not u.is_hero:
				_apply(u, "boost", h.buff_mult, h.buff_time)
			_apply(u, "guard", h.buff_guard, h.buff_time)
	for e in enemies:
		if e.pos.distance_to(h.pos) <= h.buff_radius:
			_apply(e, "expose", h.buff_expose, h.buff_time)
			_apply(e, "slow", h.buff_slow, h.buff_time)
	for s in _fortified(h.pos, h.buff_radius):
		_apply(s, "ward", h.buff_ward, h.buff_time)

# W 효과 하나를 대상 t에 건다. 그 영웅에게 없는 효과(배율 1·비율 0)는 건너뛴다.
# 같은 종류가 걸려 있으면 새 값이 크거나 같을 때만 값과 남은 시간을 바꾼다(I97)
func _apply(t, key: String, value: float, secs: float) -> void:
	if value <= (1.0 if key == "boost" else 0.0) or (t.get(key + "_left") > 0.0 and value < t.get(key)):
		return
	t.set(key, value)
	t.set(key + "_left", secs)

# 축성가 Q·W의 대상(S120): pos에서 r칸 안의 완성된 플레이어 구조물과 성곽 칸. 거점·잔해는 빠진다
func _fortified(pos: Vector2, r: float) -> Array:
	return (structures.values() + castle.values()).filter(func(s): return s.complete and pos.distance_to(Vector2(s.cell)) <= r)

# pos에 걸리는 오라 key의 값: 살아 있는 영웅 가운데 pos가 오라 반경 안인 것의 가장 큰 값(S96, I96, I100)
func _aura(key: String, pos: Vector2) -> float:
	var best := 0.0
	for h in heroes:
		if h.alive and h.level >= LEVELS.aura_level and pos.distance_to(h.pos) <= h.aura_radius:  # 오라는 정해진 레벨에 열린다(S76, I114)
			best = maxf(best, h.get(key))
	return best

# 용병 공격력 배율(I96): W(기사·장군, S84)와 장군 오라 가운데 큰 값 하나. 영웅에게는 걸리지 않는다(I99)
func _might(u: Unit) -> float:
	if u.is_hero:
		return 1.0
	return maxf(u.boost if u.boost_left > 0.0 else 1.0, 1.0 + _aura("aura_might", u.pos))

# 지을 수 있는 칸에 짓는다(_buildable). 마을 레벨이 모자란 종류는 거부한다(S99). 준비 단계엔 바로 완성된다(S18).
# 전투 단계엔 진행률 0의 미완성 구조물을 놓고 놀고 있는 가장 가까운 공병을 보낸다. 그런 공병이 없으면 거부한다(S22, I39, I62)
# 생산 시설의 집결 지점 기본값은 출구 칸이다(I61). 건설비는 지시하는 순간 내고, 모자라면 거부한다(I16, I17)
func build(kind: String, cell: Vector2i, overrides := {}):
	if state not in ["prep", "battle"] or not _buildable(kind, cell) or STRUCTURE_KINDS[kind].village_level > village_level:
		return null
	var stats: Dictionary = STRUCTURE_KINDS[kind].merged(overrides, true)
	if gold < stats.cost or (stats.tax > 0 and structures.values().filter(func(s): return s.tax > 0).size() >= HOUSE_CAP):  # 집 상한(S101)
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
	tally.built += 1  # 라운드 집계(I119)
	if engineer:
		s.progress = 0.0
		s.complete = false
		s.hp = 0.0
		_send(engineer, s)
	if not s.produces.is_empty():
		var exit = _exit_of(cell)
		s.rally = exit if exit != null else cell
	_repath = true
	return s

# 빈 칸(구조물·거점·유닛·적이 없는 맵 안 칸, I24)이다. 생산 시설·집은 마을 안, 나머지는 마을 밖이고,
# 성곽 칸에는 대포만 성벽 칸(성문 제외)에 짓는다(S43, I72). taken은 유닛·적이 선 칸(_taken)이고, 칸을 여럿 물을 때 한 번 모아 넘긴다
func _buildable(kind: String, cell: Vector2i, taken = null) -> bool:
	if not grid.is_in_boundsv(cell) or structures.has(cell) or cell == base.cell or rubble.has(cell):  # 잔해 칸에는 짓지 못한다(I88)
		return false
	if cell in _stage.get("hero_cells", []):  # 출전 칸에는 짓지 못한다(I107). 영웅이 서거나 돌아올 칸이다
		return false
	if castle.has(cell) and (kind != "cannon" or castle[cell].kind != "castle_wall"):
		return false
	if (taken if taken != null else _taken()).has(cell):
		return false
	var def: Dictionary = STRUCTURE_KINDS[kind]
	return village.has_point(cell) == (not def.produces.is_empty() or def.tax > 0)

# 유닛·적이 선 칸(I24)
func _taken() -> Dictionary:
	var out := {}
	for u in units + enemies:
		out[Vector2i(u.pos.round())] = true
	return out

# 놓기 모드에서 지금 그 지시가 받아들여지는 칸(S45, I138). 골드·공병은 보지 않는다
func placeable_cells(kind: String) -> Array:
	var building := kind in STRUCTURE_KINDS
	if (STRUCTURE_KINDS[kind].village_level > village_level) if building else (state != "prep" or not can_buy(kind)):
		return []
	var taken := _taken()  # 칸마다 유닛·적을 훑으면 40×32 맵에서 18ms라 한 번 모은다
	var out := []
	for x in size.x:
		for y in size.y:
			var c := Vector2i(x, y)
			if _buildable(kind, c, taken) if building else _merc_cell(c):
				out.append(c)
	return out

func structure_at(cell: Vector2i):
	return structures.get(cell)

# 전투 단계에만, 생산 시설에서 용병 하나를 산다(S20, I21). 시설 옆 칸에 나타나 집결 지점으로 걸어간다(I61)
# kind를 비우면 시설의 첫째 용병이다(S87). 시설이 팔지 않는 종류거나, 골드가 모자라거나, 배치 상한에 닿았거나(S25, I23),
# 시설이 파괴됐으면(S48) 거부한다
func recruit(f, kind := ""):
	if state != "battle" or structures.get(f.cell) != f or f.produces.is_empty() or not f.complete:  # 미완성 시설은 생산하지 않는다(I18)
		return null
	if kind == "":
		kind = f.produces[0]
	if kind not in f.produces:
		return null
	var stats: Dictionary = MERC_KINDS[kind]
	var exit = _exit_of(f.cell)
	if exit == null or gold < stats.cost or _mercs() >= merc_cap:
		return null
	gold -= stats.cost
	var m := Unit.new(kind, exit, stats)
	m.paid = stats.cost
	units.append(m)
	tally.merc_bought += 1  # 라운드 집계(I119)
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

# 준비·전투 단계에 성문을 열거나 닫는다(S85, S117). 성문 칸에 유닛이나 적이 있으면 닫지 않는다. 여닫으면 적(I67)과 걷던 유닛(I133)의 경로를 다시 구한다. 전투 단계에 여닫으면 그 성문만 GATE_LOCK초 동안 묶고, 묶인 성문과 거부된 지시는 묶지 않는다(S135)
func set_gate(g: Block, open: bool) -> void:
	if state not in ["prep", "battle"] or g.kind != "gate" or castle.get(g.cell) != g or g.lock > 0.0:
		return
	if not open and occupied(g.cell):
		return
	g.open = open
	_repath = true
	for u in units:  # 걷던 유닛도 지금 목적지까지 길을 다시 구한다(I133). 일하러 가는 공병은 그대로 둔다
		if u.job == null and not (u.path.is_empty() and u.after.is_empty()):
			var r = u.rally_from
			order_move([u], (u.after if not u.after.is_empty() else u.path).back())
			u.rally_from = r
	if state == "battle":
		g.lock = GATE_LOCK

func upgrade_cost(k: Block) -> int:
	return UPGRADE_COST[k.kind] * (1 << (k.level - 1))

# 성곽 칸 하나를 한 단계 올린다(S86). 골드는 지시할 때 낸다(I16). 준비 단계엔 바로 오르고, 전투 단계엔 놀고 있는
# 가장 가까운 공병을 보낸다. 그런 공병이 없으면 거부한다. 그만둔 업그레이드는 골드를 더 내지 않고 이어 올린다(I68)
func upgrade(k: Block) -> void:
	if state not in ["prep", "battle"] or castle.get(k.cell) != k or k.level >= UPGRADE_MAX or k.worker:
		return
	var engineer = _idle_engineer(k.cell) if state == "battle" else null
	if state == "battle" and not engineer:
		return
	if k.lift < 0.0:
		if gold < upgrade_cost(k):
			return
		gold -= upgrade_cost(k)
		k.lift = 0.0
	if engineer:
		_send(engineer, k)
	else:
		_lift(k, 1.0)

# 진행률을 dp만큼 올리고, 다 차면 한 단계 오른다. 최대 체력이 오른 만큼 체력도 올라 입은 피해는 그대로다(I68)
func _lift(k: Block, dp: float) -> void:
	k.lift += dp
	if k.lift < 1.0:
		return
	k.lift = -1.0
	k.level += 1
	var gain := k.max_hp * (UPGRADE_MULT - 1.0)
	k.max_hp += gain
	k.hp += gain
	_release(k)
	_repath = true  # 남은 체력이 적의 경로 비용이다(S7, I41)

# 수리비(S114, I85): 아직 내지 않은 잃은 체력 × 체력 1당 값, 1골드 미만은 올린다.
# 구조물은 낸 골드 ÷ 최대 체력이라 판매 환불(S69)의 나머지와 같다. 잔해는 체력 0이라 복구비가 된다(I89)
func repair_cost(t: Block) -> int:
	var owed := maxf(t.max_hp - t.hp - t.mend, 0.0)
	return ceili(owed * REPAIR_RATE.get(t.kind, t.paid / t.max_hp) - 0.0001)  # ponytail: 부동소수 오차로 1골드 더 받지 않게

# 판에 있는 완성된 구조물·성곽 칸·거점이고, 깎였고, 일하는 공병이 없다(I85, I86)
func can_repair(t) -> bool:
	return t is Block and state in ["prep", "battle"] and t.complete and t.worker == null and t.hp < t.max_hp and (structures.get(t.cell) == t or castle.get(t.cell) == t or t == base)

# 깎인 것을 고친다(S80). 준비 단계엔 수리비를 내고 바로 가득 차고(I86), 전투 단계엔 지시할 때 내고
# 놀고 있는 가장 가까운 공병이 가서 낸 만큼 채운다(S115, I87). 공병이 없거나 골드가 모자라면 거부한다
func repair(t) -> void:
	if not can_repair(t):
		return
	var engineer = _idle_engineer(t.cell) if state == "battle" else null
	if (state == "battle" and not engineer) or gold < repair_cost(t):
		return
	gold -= repair_cost(t)
	t.mend = t.max_hp - t.hp
	if engineer:
		_send(engineer, t)
	else:
		_mend(t, t.mend)

# 잔해를 되살린다(I89). 복구비는 지시할 때 낸다. 준비 단계엔 바로 가득 찬 채 서고, 전투 단계엔 놀고 있는
# 가장 가까운 공병이 가서 닿으면 다시 세운 뒤 채운다(_work). 지시할 때 칸에 누가 있으면 거부한다
func restore(k: Block) -> void:
	if state not in ["prep", "battle"] or rubble.get(k.cell) != k or k.worker or occupied(k.cell):
		return
	var engineer = _idle_engineer(k.cell) if state == "battle" else null
	if (state == "battle" and not engineer) or gold < repair_cost(k):
		return
	gold -= repair_cost(k)
	k.mend = k.max_hp
	if engineer:
		_send(engineer, k)
	else:
		_raise(k)
		_mend(k, k.mend)

# 잔해를 체력 0인 성곽 칸으로 다시 세운다. 부서지기 전 단계와 최대 체력은 그대로다(I89)
func _raise(k: Block) -> void:
	rubble.erase(k.cell)
	castle[k.cell] = k
	k.alive = true
	k.hp = 0.0
	_repath = true

# 낸 몫(mend)에서 dhp만큼 체력을 채운다. 낸 만큼 다 채우거나 가득 차면 끝내고 공병을 놓아준다(I87)
# ponytail: 더해 가는 오차로 가득 차기 직전에 멈추지 않게, 0.001 안쪽이면 다 찬 것으로 친다
func _mend(t: Block, dhp: float) -> void:
	var d := minf(dhp, t.mend)
	t.hp = minf(t.hp + d, t.max_hp)
	t.mend -= d
	if t.mend > 0.001 and t.hp < t.max_hp:
		return
	if t.max_hp - t.hp < 0.001:
		t.hp = t.max_hp
	t.mend = 0.0
	_release(t)
	_repath = true  # 남은 체력이 적의 경로 비용이다(S7)

# 칸에 유닛이나 적이 서 있다. 성문 닫기(I67)·잔해 복구(I89)를 막고, 화면은 그 버튼에 «(칸 막힘)»을 붙인다(I124)
func occupied(cell: Vector2i) -> bool:
	return (units + enemies).any(func(u): return Vector2i(u.pos.round()) == cell)

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
			t.mend = 0.0  # 남은 수리 몫(I87)이 있으면 공병이 허물지 않고 고친다
			_send(engineer, t)

# 전투 단계에만, 놀고 있는 가장 가까운 공병을 보내 대포를 그 칸으로 옮긴다. 골드는 들지 않는다(S44, I48).
# 공병은 대포를 허물어 접고, 새 칸 옆에 닿으면 거기서 다시 짓는다(_work, I74)
func move_cannon(s: Block, cell: Vector2i) -> void:
	if state != "battle" or s.kind != "cannon" or not can_demolish(s) or not _buildable(s.kind, cell):
		return
	var engineer = _idle_engineer(s.cell)
	if engineer:
		s.dest = cell
		s.mend = 0.0  # 남은 수리 몫(I87)이 있으면 공병이 접지 않고 고친다
		_send(engineer, s)

# 접은 대포를 새 칸으로 옮겨 진행률 0부터 다시 짓는다. 새 칸에 지을 수 없게 됐으면 그만둔다(I74)
func _settle(s: Block) -> void:
	if not _buildable(s.kind, s.dest):
		_release(s)
		return
	structures.erase(s.cell)
	s.cell = s.dest
	structures[s.cell] = s
	s.dest = null
	s.razed = 0.0
	s.full = s.hp
	s.hp = 0.0
	s.progress = 0.0
	s.complete = false
	_repath = true

# 공병이 일하러 가는 칸. 접은 대포는 새 칸이다(I74)
func _site(s: Block) -> Vector2i:
	return s.dest if s.dest != null and s.razed >= 1.0 else s.cell

# 완성된 방벽·타워·대포이고 일하는 공병이 아직 없다. 골드는 돌려주지 않는다(S74). 생산 시설은 철거하지 않는다(I64)
func can_demolish(t) -> bool:
	return t is Block and structures.get(t.cell) == t and t.complete and t.produces.is_empty() and t.worker == null

# things 가운데 판에 남아 있는 미완성 구조물. 화면이 완성·취소·이어 짓기 버튼에 쓴다(S83)
func unfinished(things: Array) -> Array:
	return things.filter(func(t): return t is Block and structures.get(t.cell) == t and not t.complete)

# 놀고 있는 공병(짓거나 허무는 일을 맡지 않은 공병) 가운데 그 칸에 가장 가까운 공병(I39). 성벽 위 공병은 뺀다(I69).
# 막힌 칸을 지나야만 닿는 공병도 뺀다(I125). 전투 중 공병에게 맡기는 지시는 모두 여기를 거친다
func _idle_engineer(cell: Vector2i):
	var best = null
	for u in units:
		if u.kind == "engineer" and u.job == null and not u.on_wall and (best == null or u.pos.distance_to(Vector2(cell)) < best.pos.distance_to(Vector2(cell))) and _reaches(u, cell):
			best = u
	return best

# 전투 중 공병 지시(I125)를 맡을 공병이 없는 이유(I128): 칸들 가운데 하나라도 맡을 공병이 있으면 "",
# 놀고 있는 공병이 하나도 없으면 "none", 있는데 어느 칸에도 닿지 못하면 "far". 칸이 비면(놓기 버튼) 놀고 있는 공병이 있는지만 본다
func engineer_gap(cells: Array) -> String:
	if not units.any(func(u): return u.kind == "engineer" and u.job == null):
		return "none"
	return "" if cells.is_empty() or cells.any(func(c): return _idle_engineer(c) != null) else "far"

# 지금 막힌 칸(닫힌 성문·성벽·구조물)을 지나지 않고 그 칸까지 걸어갈 수 있다(I125). 끝 칸은 일하는 자리라 막혀 있어도 된다
func _reaches(u: Unit, cell: Vector2i) -> bool:
	grid.wall_k = UNIT_WALL_K  # _send와 같은 유닛 경로
	return not grid.get_id_path(Vector2i(u.pos.round()), cell, true).slice(1, -1).any(func(c): return grid.block_at(c) != null)

# 공병에게 그 구조물 일을 맡기고 옆 칸(대각선 포함)까지 걸어가게 한다(I63)
func _send(u: Unit, s: Block) -> void:
	u.job = s
	u.rally_from = null
	u.after.clear()
	s.worker = u
	grid.wall_k = UNIT_WALL_K
	u.path = grid.get_id_path(Vector2i(u.pos.round()), _site(s), true).slice(1, -1)

# 일하던 공병을 놓아준다. 공병은 그 자리에 서고, 구조물은 그 상태로 남는다(I63)
# 옮기던 대포는 원래 칸에 완성된 채 남는다(U12, I74)
func _release(s: Block) -> void:
	if s.worker:
		s.worker.job = null
		s.worker.path.clear()
		s.worker = null
	if s.dest != null:
		s.dest = null
		s.razed = 0.0

func _remove(s: Block) -> void:
	_release(s)
	structures.erase(s.cell)
	s.alive = false
	_repath = true

# 진행률을 dp만큼 올리고 체력을 «다 지었을 때의 체력 × 진행률 − 짓는 동안 입은 피해»로 둔다. 다 차면 완성되고 적 경로를 다시 구한다(I62, I74)
# 체력에 더해 가지 않고 곱해서 구한다. 더하면 오차가 쌓여 다 지어도 최대 체력에 못 미친다(EV48)
func _grow(s: Block, dp: float) -> void:
	var lost := s.full * s.progress - s.hp
	s.progress = minf(s.progress + dp, 1.0)
	s.hp = s.full * s.progress - lost
	if s.progress >= 1.0:
		s.complete = true
		_release(s)
		_repath = true

# 옆 칸에 닿은 공병은 수리할 몫이 있으면 고치고(I87, 잔해면 다시 세운 뒤 고친다, I89), 성곽이면 올리고(S86),
# 미완성이면 짓고(I62), 완성이면 허문다(I64: 건설 시간의 절반이 든다). 밀려나 멀어졌으면 다시 걸어간다
# 옮기는 대포는 허물면 접어 두고, 새 칸 옆에 닿으면 내려놓는다(I74)
# ponytail: 닿을 수 없는 칸이면 매 프레임 경로를 다시 구한다. 공병이 많아 느려지면 포기 처리를 둔다
# ponytail: 일의 종류를 칸 상태로 고른다. 수리 몫과 그만둔 업그레이드가 함께 남은 칸은 수리부터 하고 멈춘다
func _work(u: Unit, dt: float) -> void:
	dt *= 1.0 + _aura("aura_work", u.pos)  # 축성가 오라: 공병이 하는 모든 일이 빨라진다(I100)
	var s: Block = u.job
	if u.pos.distance_to(Vector2(_site(s))) > WORK_REACH:
		_send(u, s)
	elif s.mend > 0.0:
		if rubble.get(s.cell) != s:
			_mend(s, s.max_hp / (s.build_time if structures.get(s.cell) == s else REPAIR_TIME) * dt)
		elif not occupied(s.cell):  # 잔해는 칸이 비어야 다시 세운다(I89)
			_raise(s)
	elif s.lift >= 0.0:
		_lift(s, dt / UPGRADE_TIME)
	elif not s.complete:
		_grow(s, dt / s.build_time)
	elif s.razed >= 1.0:
		_settle(s)
	else:
		s.razed += dt / (s.build_time / 2.0)
		if s.razed >= 1.0 and s.dest == null:
			_remove(s)

# 배치 상한에 세는 살아 있는 용병 수(공병 포함, 영웅 제외, I23)
func _mercs() -> int:
	return units.filter(func(u): return not u.is_hero).size()

# 준비 단계에만, 플레이어가 놓은 구조물·용병을 판다(S69). 성곽·영웅 등 나머지는 건너뛴다(I56)
func sell(things: Array) -> void:
	if state != "prep":
		return
	for t in things:
		if t is Block and structures.get(t.cell) == t:
			structures.erase(t.cell)
			_repath = true
		elif t is Unit and not t.is_hero and t in units:
			units.erase(t)
		else:
			continue
		t.alive = false
		gold += refund(t)

# 판매로 돌려받는 골드: 낸 골드 × 남은 체력 비율, 1골드 미만은 버린다(S69, I56)
func refund(t) -> int:
	return floori(t.paid * t.hp / t.max_hp)

func damage(target, amount: float, pierce := false) -> void:
	if not target.alive:
		return
	if target is Enemy:
		if not pierce:  # 장갑(S108): 줄인 피해는 1 아래로 내려가지 않고, 원래 1 미만이면 그대로다
			amount = maxf(amount - target.armor, minf(amount, 1.0))
		if target.expose_left > 0.0:  # 궁수 W(I99): 장갑을 뺀 뒤에 곱한다
			amount *= 1.0 + target.expose
	elif target is Unit:
		# 받는 피해 감소(I96): 사제 W(I99)와, 용병이면 맞는 순간 가까이 있는 살아 있는 영웅의 오라(I82) 가운데 큰 값 하나.
		# 다운된 영웅의 오라는 풀린다(S96)
		var guard: float = target.guard if target.guard_left > 0.0 else 0.0
		if not target.is_hero:
			guard = maxf(guard, _aura("aura_guard", target.pos))
		amount *= 1.0 - guard
	elif target.ward_left > 0.0:  # 축성가 W(S120): 구조물·성곽 칸만 받는다
		amount *= 1.0 - target.ward
	if target == base and amount > 0.0:
		tally.base_hit += 1  # 라운드 집계(I119)
	target.hp = maxf(target.hp - amount, 0.0)
	if target.hp > 0.0:
		return
	target.alive = false
	if target == base:
		state = "lost"
		settled = [mission, commission].filter(func(n): return n != "").map(func(n): return [n, false])  # 진 라운드의 미션·의뢰는 모두 실패다(I131)
	elif target is Enemy:
		enemies.erase(target)
		gold += target.reward
		for h in heroes:  # 누가 처치했든 그때 살아 있는 출전 영웅이 모두 받는다(S125)
			if h.alive:
				add_xp(h, target.xp)
	elif target is Unit:  # 전장에서 빠진다. 영웅은 다음 준비 단계에 돌아온다(step, S26). 공병이 하던 일은 그 상태로 남는다(S24)
		if target.job:
			_release(target.job)
		units.erase(target)
		if target.is_hero:  # 라운드 집계(I119)
			tally.hero_down += 1
		else:
			tally.merc_lost += 1
	else:  # 구조물·성곽: 칸이 비고 경로를 다시 구한다(I5)
		_release(target)
		_repath = true
		if structures.get(target.cell) == target:  # 성벽 위 대포가 부서져도 성벽 칸은 남는다(S93)
			structures.erase(target.cell)
			tally.structure_lost += 1  # 라운드 집계(I119)
			return
		castle.erase(target.cell)
		tally.castle_lost += 1  # 라운드 집계(I119)
		rubble[target.cell] = target  # 잔해로 남아 지나갈 수 있고, 복구하면 되살아난다(I88, I89)
		if structures.has(target.cell):  # 성벽 칸이 부서지면 그 위 대포도 부서진다(I72)
			damage(structures[target.cell], INF)
		# 그 칸에 걸쳐 선(0.5칸 안) 유닛은 그 칸 땅으로 내려오고, 성벽 위로 그 칸을 지나려던 유닛은 멈춘다(I70)
		for u in units:
			var here: bool = u.on_wall and u.pos.distance_to(Vector2(target.cell)) <= 0.5
			if here:
				u.on_wall = false
				u.pos = Vector2(target.cell)
			if here or target.cell in (u.path if u.on_wall else u.after):
				u.path.clear()
				u.after.clear()

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
	if e.flying:  # 길을 찾지 않고 곧장 난다(I79)
		return
	grid.wall_k = e.wall_k
	grid.climb = e.climb * e.speed
	e.path = grid.get_id_path(Vector2i(e.pos.round()), e.goal, true)
	grid.climb = 0.0

# 적이 지금 노리는 것(S4): ① 인식 범위 안이나 몸이 닿은 가장 가까운 유닛(영웅·용병) → ② 살아 있는 반격 대상 → ③④ 거점.
# 마을 안의 적에게는 인식 범위 안의 마을 구조물(집·생산 시설, S43)도 ①이다(I49). 들판의 구조물은 ①이 아니다(I7). 쏘지 않는 구조물은 attacker가 되지 않는다(_fire). 반격 대상이 부서지면 ②가 끝난다(I8)
func _target_of(e: Enemy):
	var best = null
	var best_d := INF
	for m in units:
		var d := e.pos.distance_to(m.pos)
		# 밀어낸 직후 거리는 반지름 합과 같아서 0.01 여유를 둔다(S13: 몸으로 막은 유닛은 인식 범위 밖이어도 친다)
		# 성벽 위 유닛은 몸으로 길을 막을 때만 친다(U13, S89, I70). 비행 적·기어오르는 적은 그 성벽 위 유닛도 노리고(I77), 비행 적은 몸에 막히지 않는다(S109)
		# 인식 범위 0은 아무것도 보지 않는다. 몸이 겹치는 비행 적이 거리 0에서 보게 되지 않게
		if d < best_d and ((d <= e.sight and e.sight > 0.0 and (not m.on_wall or e.flying or e.climb > 0.0)) or (not e.flying and d <= e.radius + m.radius + 0.01)):
			best = m
			best_d = d
	if village.has_point(Vector2i(e.pos.round())):
		for s in structures.values():
			var d := e.pos.distance_to(Vector2(s.cell))
			if d < best_d and d <= e.sight:
				best = s
				best_d = d
	if best:
		return best
	if e.attacker and e.attacker.alive:
		return e.attacker
	return base

func _move(e: Enemy, dt: float) -> void:
	e.cooldown -= dt
	e.expose_left -= dt
	e.slow_left -= dt
	if e.stun_left > 0.0:  # 기절(I98): 움직이지도 치지도 않는다
		e.stun_left -= dt
		return
	var speed := e.speed * ((1.0 - e.slow) if e.slow_left > 0.0 else 1.0)  # 마도사 W(I99)
	if e.on_wall and not _climbable(Vector2i(e.pos.round())):  # 성벽에서 내려왔거나 그 성벽이 부서졌다(I76)
		e.on_wall = false
	var aim = _target_of(e)
	var goal: Vector2i = Vector2i(aim.pos.round()) if aim is Unit else aim.cell
	if goal != e.goal:  # 대상이 바뀌었다
		e.goal = goal
		_find_path(e)
	# 기어오르는 적은 땅에서 성벽 위 유닛을 치지 않고, 그 칸으로 올라가서 친다(I77)
	var below: bool = aim is Unit and e.climb > 0.0 and not e.on_wall and aim.on_wall and _climbable(goal)
	if aim is Unit and e.pos.distance_to(aim.pos) <= REACH and not below:
		_attack(e, aim)
		return
	# 성벽 위 대포는 성벽 위에서 친다(S112). 땅에서는 아래 성벽을 치지 않고 기어오른다(S107)
	if e.on_wall and not aim is Unit and _climbable(goal) and e.pos.distance_to(Vector2(goal)) <= REACH:
		_attack(e, aim)
		return
	if e.flying:  # 막힌 칸을 넘어 대상으로 곧장 날아가 닿는 거리에서 친다(I79)
		var to: Vector2 = aim.pos if aim is Unit else Vector2(goal)
		if e.pos.distance_to(to) <= REACH:
			_attack(e, aim)
		else:
			e.pos = e.pos.move_toward(to, speed * dt)
		return
	var left := speed * dt
	while left > 0.0 and not e.path.is_empty():
		var next: Vector2i = e.path[0]
		var target := Vector2(next)
		var d := e.pos.distance_to(target)
		var block = base if next == base.cell else grid.block_at(next)
		if block and e.climb > 0.0 and block.kind == "castle_wall":  # 성곽 성벽은 부수지 않고 기어올라 그 칸 위로 올라선다(S107, I76)
			# ponytail: 오르다 대상이 바뀌어 그만둬도 오른 시간이 남아 다음 오르기가 짧아진다. 거슬리면 오르던 칸을 기억한다
			if not e.on_wall and d <= REACH:
				e.climbed += dt
				if e.climbed >= e.climb:
					e.climbed = 0.0
					e.on_wall = true
					_shove(e, target - e.pos, units)
				return
			block = null  # 성벽 위에서는 이어진 성벽 칸을 걷고, 땅에서는 오를 자리까지 걷는다
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

# 같은 편(bodies)끼리 겹친 만큼 반씩 밀어낸다. 상대 편(others)과는 겹치지 않게 민다. 비행 적은 밀지도 밀리지도 않는다(I79).
# 경로는 그대로라 밀려난 쪽은 _move·_act가 다시 데려간다(I51)
# ponytail: O(n²) 전수 비교, 적이 수백이면 칸 버킷으로
func _push_apart(bodies: Array, others: Array) -> void:
	for i in bodies.size():
		for j in range(i + 1, bodies.size()):
			var a = bodies[i]
			var o = bodies[j]
			if a.get("flying") or o.get("flying"):
				continue
			var gap: Vector2 = o.pos - a.pos
			var overlap: float = a.radius + o.radius - gap.length()
			if overlap > 0.0:
				var push := (gap.normalized() if gap != Vector2.ZERO else Vector2.RIGHT) * overlap / 2.0
				_shove(a, -push, others)
				_shove(o, push, others)

# 쏘는 구조물은 사거리 안에서 가장 가까운 적을 쏘고(S28, I29), 맞은 적은 그 구조물에 반격한다(S5).
# 대포는 맞은 적 splash칸 안의 적에게도 같은 피해를 주고, 그 적들도 반격한다(S90, I73). 마법 타워는 장갑을 무시한다(S110)
func _fire(dt: float) -> void:
	for s in structures.values():
		if s.range <= 0.0 or not s.complete or s.razed >= 1.0:  # 미완성 타워(I18)·접은 대포(I74)는 쏘지 않는다
			continue
		s.cooldown -= dt
		if s.cooldown > 0.0:
			continue
		var best = _nearest_enemy(Vector2(s.cell), s.range)
		if best:
			s.cooldown = s.fire_gap
			s.target = best
			var hurt: float = s.damage * (1.0 + _aura("aura_gunnery", Vector2(s.cell)))  # 마도사 오라(I100)
			for e in enemies.duplicate():
				if e == best or (s.splash > 0.0 and e.pos.distance_to(best.pos) <= s.splash):
					e.attacker = s
					damage(e, hurt, s.pierce)

# 유닛은 명령받은 경로를 걷고(S14), 사거리 안의 가장 가까운 적을 친다(S15). 영웅은 걷는 동안에도 친다.
# 용병은 걷는 동안 이동 방식을 따르고(S35, I35), 서 있으면 인식 범위 안의 적을 쫓는다(I36).
# 홀드가 켜진 용병은 서 있는 동안 기준 지점 반경 안의 적만 노리고, 그 반경 밖으로 쫓아가지 않는다(S36)
func _act(u: Unit, dt: float) -> void:
	u.cooldown -= dt * (1.0 + (_aura("aura_haste", u.pos) if u.range >= WALL_RANGE else 0.0))  # 궁수 오라: 원거리 아군은 더 자주 친다(I100)
	u.skill_cooldown -= dt
	u.buff_cooldown -= dt
	u.boost_left -= dt
	u.guard_left -= dt
	if not u.is_hero:  # 사제 오라: 용병 체력이 차오른다(I100)
		u.hp = minf(u.hp + _aura("aura_regen", u.pos) * dt, u.max_hp)
	if u.path.is_empty() and not u.after.is_empty():  # 오르내리는 칸에 닿았다(I44, I69)
		u.on_wall = not u.on_wall
		u.pos = Vector2(u.after[0])
		u.path = u.after.slice(1)
		u.after.clear()
	# 걷는 동안엔 반경을 보지 않는다. 홀드 중 이동 지시를 받으면 도착한 곳이 새 기준이다(I37)
	var zone := u.hold_radius if u.hold and u.path.is_empty() else INF
	var foe = _nearest_enemy(u.pos, u.range, u.anchor, zone)
	var top = castle.get(Vector2i(u.pos.round()))
	if u.on_wall and u.range < WALL_RANGE and not (top and top.open):  # 성벽 위 근접 유닛은 열린 성문 위에서만 들판의 적을 치고(S88, S89), 성벽 위의 적은 친다(I78)
		foe = _nearest_enemy(u.pos, u.range, u.anchor, zone, true)
	var walking := not u.path.is_empty()
	if walking and not u.is_hero:
		if u.move_mode == "move":
			foe = null
		elif foe:  # 이동 중 공격: 멈춰서 친다
			walking = false
	var left := u.speed * dt * (1.0 if u.is_hero else 1.0 + _aura("aura_stride", u.pos))  # 장군 오라: 용병이 더 빨리 걷는다(I100)
	if walking:
		while left > 0.0 and not u.path.is_empty():
			var to := Vector2(u.path[0]) - u.pos
			if u.on_wall:  # 성벽 위는 성곽 칸끼리 이어져 있어 막힘 없이 걷는다(I69)
				u.pos += to.limit_length(left)
			else:
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
	elif not foe and not u.on_wall:  # 성벽 위 유닛은 쫓아 내려가지 않는다(I70)
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
		damage(foe, u.damage * _might(u))
	if u.job and u.path.is_empty():
		_work(u, dt)

# from에서 reach 안의 가장 가까운 적. center에서 zone보다 먼 적은 뺀다(홀드 반경). on_wall이면 성벽 위의 적만 본다(I78)
func _nearest_enemy(from: Vector2, reach: float, center := Vector2.ZERO, zone := INF, on_wall := false):
	var best = null
	var best_d := reach
	for e in enemies:
		var d: float = e.pos.distance_to(from)
		if d <= best_d and e.pos.distance_to(center) <= zone and (e.on_wall or not on_wall):
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
			if gap.length() < e.radius + m.radius and not m.get("flying"):  # 비행 적은 길을 막지 않는다(S109)
				p = m.pos + (gap.normalized() if gap != Vector2.ZERO else Vector2.LEFT) * (e.radius + m.radius)
		var c := Vector2i(p.round())
		if grid.is_in_boundsv(c) and (not grid.block_at(c) or (e.on_wall and _climbable(c))) and c != base.cell:  # 성벽 위의 적은 성벽 칸을 걷는다(I76)
			e.pos = p
			return

# 기어오를 수 있는 칸: 성곽의 성벽 칸. 성문은 오르지 않는다(I76)
func _climbable(c: Vector2i) -> bool:
	return castle.has(c) and castle[c].kind == "castle_wall"

func _attack(e: Enemy, target) -> void:
	if e.cooldown <= 0.0:
		e.cooldown = e.attack_gap
		e.target = target
		damage(target, e.damage)
