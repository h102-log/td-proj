extends RefCounted
# 전투 시뮬레이션. 화면 없이 돈다(그리기는 src/ui/). API 계약은 tests/eval/gd/lib.gd 머리 주석에 있다.

signal enemy_spawned(enemy)
signal wave_starting  # 웨이브를 시작하기 직전(준비 단계가 끝나는 때). main이 저장한다(S181)

# 종류 이름 → 수치. 판을 만들 때 data/ 아래 Resource 파일에서 읽는다(S31). 파일 이름이 종류 이름이다(I66)
# 상수였을 때의 이름을 그대로 둔다(UI·테스트가 battle.MERC_KINDS.soldier.cost처럼 읽는다)
var ENEMY_KINDS := _kinds("res://data/enemies/")
var MERC_KINDS := _kinds("res://data/mercs/")
var STRUCTURE_KINDS := _kinds("res://data/structures/")
var HERO_KINDS := _kinds("res://data/heroes/")  # 칸의 뜻은 src/data/hero_def.gd 머리 주석(S97, I95)
var HIRE = load("res://data/hire.tres")  # 영입소 수치(S123, I103)
var LEVELS = load("res://data/levels.tres")  # 영웅 레벨 수치(S126, I111)
var QUEST_KINDS := _kinds("res://data/quests/")  # 미션·의뢰 정의(S77, I118). 칸의 뜻은 src/data/quest_def.gd 머리 주석
const VILLAGE_UP := [60]  # 마을 레벨 n→n+1 비용(S99). 길이+1이 최대 레벨이다. 임시값(Claude 예시, 사용자 2026-10-13 수락)
const MERC_CAP := 10  # 배치 상한 기본값(S25). 임시값(사용자 2026-10-13), 스테이지의 merc_cap이 덮어쓴다
const HOUSE_CAP := 6  # 마을에 지을 수 있는 집 수(S101). 임시값(사용자 2026-10-13)
const QUEST_OFFERS := 2  # 라운드 사이에 보이는 의뢰 수(I121). 임시값(Claude 예시)
const TALLY_KEYS := ["base_hit", "castle_lost", "structure_lost", "merc_lost", "hero_down", "merc_bought", "built", "battle_time"]  # 라운드 집계의 키(I119)
const SPAWN_GAP := 2.5  # 웨이브 안에서 적이 나오는 간격(초). 임시값: 1.0 → 0.9(2026-10-15 3장 자체 점검, 사용자 승인 2026-10-16 — insights/2026-10-15_ch3_self_check_balance.md §8) → 2.5(2026-10-21 5.1 판 길이, I91 — insights/2026-10-21_round_design.md)
const REACH := 1.0      # 적이 막힌 칸·거점·유닛을 칠 수 있는 거리(중심 사이). 옆 칸 중심까지가 1이다
const POSE := 0.22  # 친 뒤 제자리에 서는 시간(초, S196). 용병·적의 공격 키 포즈가 끝나는 때다(S172)
const HERO_POSE := 0.3  # 영웅이 친 뒤 제자리에 서는 시간(초, S196). 공격 3프레임이 끝나는 때다(S165)
const CONTACT := 0.08  # 걷기 명령을 받은 영웅이 다시 걷는 때(친 뒤 초, S196). 화면의 근접 공격이 닿는 때(battle_view CONTACT)와 같다. 원거리 유닛의 투사체가 나가는 때다(I174)
const RANGED := 2.0  # 사거리가 이보다 큰 영웅·용병은 원거리다. 쏘는 구조물은 모두 원거리다(S178, I174)
const MISSILES := {"archer": "arrow", "sylvia": "arrow", "tower": "arrow", "cannon": "ball"}  # 원거리 기본 공격의 투사체(S178). 나머지(마법 타워·마법 영웅)는 구슬(bolt)
const SPEED := {"arrow": 15.0, "bolt": 10.0, "ball": 7.5}  # 투사체 속도(칸/초, S178)
const REPATH_PER_STEP := 8  # 한 스텝에 경로를 다시 구하는 적 수(I155). 적 40명을 한 번에 구하면 61ms(디버그)라 나눈다(사용자 2026-10-20)
const UNIT_WALL_K := 1e6  # 유닛 경로의 막힌 칸 비용 배율. 돌아갈 길이 있으면 막힌 칸(닫힌 성문 포함, I42)을 지나지 않는다
const WORK_REACH := 2.0  # 공병이 일하는 거리(중심 사이). 옆 칸 대각선(1.41)에, 무리에 밀려 0.5칸 못 미친 도착(I51)을 더했다
# 성곽 업그레이드(S86): 한 단계마다 최대 체력 ×UPGRADE_MULT. 비용은 종류별 1→2단계 값이고 다음 단계는 2배. 수치는 임시값
const UPGRADE_COST := {"castle_wall": 10, "gate": 20}
const UPGRADE_MULT := 1.5
const UPGRADE_MAX := 3
const UPGRADE_TIME := 5.0  # 전투 중 공병이 한 단계 올리는 시간(초)
const GATE_LOCK := 20.0  # 전투 단계에 여닫은 성문을 다시 여닫지 못하는 시간(초, S135). 핑퐁 봇 측정을 보고 사용자가 고름(insights/2026-10-16_gate_cooldown.md)
const COUNTER_HOLD := 3.0  # 반격 대상이 이만큼 쏘지 않아야 다른 구조물로 바뀐다(초, S140). 가장 느린 쏘는 간격(2.5초)보다 길다. 임시값
const GATE_SPLIT_ROUND := 3  # 이 라운드부터 땅 적은 출현 지점에서 가장 가까운 성문을 먼저 노린다(S143). 임시값
# 수리(S114): 성곽·거점의 체력 1당 수리비(골드). 구조물은 낸 골드 ÷ 최대 체력이다. 수치는 임시값
const REPAIR_RATE := {"castle_wall": 0.1, "gate": 0.1, "base": 1.0}
const REPAIR_TIME := 5.0  # 전투 중 공병이 성곽·거점을 0에서 가득 채우는 시간(초, I87). 구조물은 건설 시간이다
const WALL_RANGE := 2.0  # 성벽 위에서 치려면 필요한 사거리(칸, S88). 열린 성문 위는 예외다(S89). 임시값
const SLOTS := ["q", "w", "e", "r"]  # 영웅 스킬 칸(S145)
const CAST_RANGE := 6.0  # 지점·대상을 고르는 스킬의 시전 사거리(칸, S147). 임시값
const CRIT := 2.0  # 치명타 피해 배율(S149). 임시값
const STAY := 0.6  # 장판 안에 있는 동안 거는 효과의 남은 시간(초, I141). 장판을 나오면 곧 풀린다
const FALLEN := 2.0  # 쓰러진 몸(fallen)을 지우는 때(쓰러진 뒤 초, S180). 화면은 끝 0.5초 동안 흐린다
const STAGGER := 2.0  # 예고 중 기절로 스킬이 끊긴 보스가 비틀거리는 시간(초, S194). 임시값
const STAGGER_EXPOSE := 0.5  # 비틀거리는 동안 받는 피해 증가(S194). 임시값
const DUSK := 10.0  # 밤 웨이브에 fade가 없을 때 어둠이 dark까지 오르는 시간(초, S210). 임시값
const DAWN := 3.0  # 전투 단계가 끝난 뒤 어둠이 1에서 0까지 내리는 시간(초, S210). 임시값
const BASE_LIGHT := 4.0  # 거점의 밤 불빛 반경(칸, S211). 임시값
const GATE_LIGHT := 2.0  # 성문 칸의 밤 불빛 반경(칸, S211). 임시값
const LIGHT_CHUNK := 8  # 보이는지(seen) 물을 때 불빛을 나눠 담는 구역 크기(칸). 적 수백 명이 물어도 그 구역의 불빛만 본다

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
	var pierce := false  # 마법 피해를 준다(마법 타워, S110, S149)
	var armor := 0.0  # 방어력(S149). 기본 0이고 세라피나 오라로만 오른다(방벽)
	var fx := {}  # 걸린 효과: 출처 → {효과 키: 값, left: 남은 초}(S150, I141)
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
	var sealed := false  # 닫힌 문루(S39 2026-10-26 둘째 변경): 열거나 닫지 못한다
	var lock := 0.0  # 성문 쿨타임(S135)의 남은 초. 0보다 크면 여닫기 지시를 거부한다
	var level := 1  # 성곽 업그레이드 단계(S86)
	var lift := -1.0  # 업그레이드 진행률(0~1). 음수면 올리는 중이 아니다. 그만두면 그대로 남는다(I68)
	var mend := 0.0  # 수리비를 냈지만 아직 채우지 못한 체력(I87). 0보다 크면 공병이 마저 고친다
	var size := Vector2i.ONE  # 차지 칸 가로 × 깊이(S216). cell은 차지 칸의 앞 왼쪽 칸이다(area_of)

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
	var armor := 0.0  # 방어력. 받는 물리 피해를 워크3식 비율로 줄인다(S108, S149)
	var flying := false  # 경로 층을 무시하고 곧장 난다(S109, I79)
	var climb := 0.0  # 성곽 성벽을 오르는 시간(초). 0이면 오르지 않는다(S107, I76)
	var climbed := 0.0  # 지금 성벽을 오른 시간(초)
	var on_wall := false  # 성곽 성벽 칸 위에 올라서 있다(I76)
	var cooldown := 0.0  # 0 이하면 바로 칠 수 있다
	var fx := {}  # 걸린 효과: 출처 → {효과 키: 값, left: 남은 초}(S150, I141)
	var engaged = null  # 이 적을 붙잡은 유닛(S159). 블록 자리를 하나 차지한다. 없으면 null
	var alive := true
	var attacker  # 반격 대상인 구조물. 살아 있는 동안 반격한다(S4 ②). 바뀌는 때는 _fire(S140)
	var held := 0.0  # 반격 대상을 바꾸지 않는 남은 초(S140). 반격 대상이 쏠 때마다 COUNTER_HOLD로 돌아간다
	var target  # 마지막으로 친 대상. 화면이 친 직후 공격선을 그린다(S71)
	var goal: Vector2i  # 경로의 끝 칸(지금 노리는 대상의 칸)
	var via = null  # 먼저 노리는 성문 칸(S143). 그 칸에 들어서거나 성문이 잔해가 되면 null
	var path: Array[Vector2i] = []
	var skills := {}  # 보스 스킬 이름 → 수치(S194, I169). 종류의 사전을 같이 쓰니 적마다 바뀌는 값은 cast·cd에 둔다
	var cast = null  # 예고 중인 스킬 {id, left}(S194). 없으면 null
	var cd := {}  # 스킬 → 남은 대기(초). 없는 스킬은 0이다(나온 때, S194)

	func _init(k: String, cell: Vector2i, stats: Dictionary) -> void:
		kind = k
		pos = Vector2(cell)
		for key in stats:
			set(key, stats[key])
		max_hp = hp

# 영웅과 용병(I1). 스킬은 영웅만, 홀드는 용병만 쓴다(S16)
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
	var sight := 0.0  # 인식 범위(칸). 서 있을 때 이 안의 적을 쫓는다(I36, 영웅은 S141)
	var path: Array[Vector2i] = []  # 명령받은 이동 경로(지금 칸 제외)
	var move_mode := "attack_move"  # 지금 걷는 길의 명령: "move" 순수 이동(S14) | "attack_move" 공격 이동(S35)
	var prey  # 대상 공격(S35)하는 적. 없으면 null
	var chase_to: Vector2i  # 대상에게 가는 길을 구한 칸. 대상이 여기서 1칸 넘게 옮기면 다시 구한다
	var hold := false  # 켜지면 anchor에서 hold_radius 안에서만 싸운다(S36)
	var hold_radius := 0.0
	var anchor: Vector2  # 홀드 기준 지점(I37)
	var armor := 0.0  # 방어력(S149). 기본 0이고 세라피나 오라로만 오른다
	var block := 1  # 블록 수(S159): 동시에 붙잡는 적 수. 요새화한 아이아스는 더 많다
	var fx := {}  # 걸린 효과: 출처 → {효과 키: 값, left: 남은 초}(S150, I141)
	var shields := {}  # 보호막: 출처 → {hp, left}(S150). 피해를 체력보다 먼저 받는다
	# 영웅만 쓰는 칸. 종류별 수치와 칸의 뜻은 src/data/hero_def.gd(S97, I95)
	var is_hero := false
	var home: Vector2i  # 쓰러진 영웅이 돌아오는 시작 칸(S26, I102)
	var grade := 0
	var level := 1  # 영웅 레벨(S60, S126). 경험치로 정해진다(Battle._set_xp)
	var xp := 0
	var mana := 0.0  # 지금 마나(S146). 만들 때 HeroDef의 최대 마나가 들어온다
	var max_mana := 0.0
	var mana_regen := 0.0
	var passive := {}
	var aura := {}
	var q := {}
	var w := {}
	var e := {}
	var r := {}
	var cd := {"q": 0.0, "w": 0.0, "e": 0.0, "r": 0.0}  # 칸마다 남은 재사용 대기(초)
	var skill_uses := 0  # 쓴 스킬 수(모든 칸)
	var order = null  # 시전 사거리 밖이라 걸어가서 쓸 스킬 {slot, aim}(S147). 없으면 null
	var toggle := false  # 켜고 끄는 칸(실비아 W)이 켜져 있다(S153)
	var auto := false  # 자동 시전(크로노스 Q)이 켜져 있다(S158)
	var casts := 0  # 이그니스 패시브: 쓴 스킬 수(S156)
	var charged := false  # 이그니스 패시브: 다음 Q·W·E가 커진다
	var mark = null  # 실비아 패시브: 직전에 친 적(S153)
	var stacks := 0  # 실비아 패시브 중첩
	var still := 0.0  # 아이아스 패시브: 이동 지시 없이 지난 시간(초, S151, I147)
	var fort := false  # 요새화
	var brace := 0.0  # 아이아스 E: 남은 시간(초). 0보다 크면 태세 중이다
	var braced := 0.0  # 태세 동안 들어온 피해(줄이기 전 값)
	var on_wall := false  # 성벽 위에 있다(S42, I44)
	var after: Array[Vector2i] = []  # path 끝에서 오르내린 뒤 걸을 길. 첫 칸이 오르내려 서는 칸이다(I69)

	func _init(k: String, cell: Vector2i, stats: Dictionary) -> void:
		kind = k
		pos = Vector2(cell)
		for key in stats:
			set(key, stats[key])
		max_hp = hp
		max_mana = mana

# 원거리 기본 공격의 투사체(S178, I174). 대상을 따라가 닿을 때 피해를 준다. 쏜 쪽의 상태(피해량·종류·방어 무시·축복)는 쏜 때 담는다
class Missile:
	var src  # 쏜 유닛·구조물
	var target  # 노린 적
	var look: String  # 모양: "arrow" | "bolt" | "ball"(MISSILES)
	var speed: float  # 칸/초
	var wait := 0.0  # 출발까지 남은 초. 유닛은 CONTACT, 구조물은 0
	var from: Vector2  # 출발한 자리. 화면이 날아간 비율을 센다
	var pos: Vector2  # 지금 자리
	var at: Vector2  # 날아가는 곳: 대상의 지금 자리, 대상이 쓰러졌으면 마지막 자리
	var hurt := 0.0  # 피해량(공격력 × 공격력 배율)
	var kind := "phys"  # 피해 종류(S149)
	var ignore := 0.0  # 방어 무시 비율(I148)
	var splash := 0.0  # 범위 피해 반경(대포, S90)
	var bless := 0.0  # 축복 마법 피해(S152). 없으면 0
	var bless_r := 0.0  # 축복 반경
	var age := 0.0  # 닿은 뒤 지난 초(landed)

# 막힌 칸(구조물·성곽)을 «남은 체력 × 적의 wall_k» 비용 칸으로 보는 격자(S7, S34, I3, I40). 성곽 업그레이드 배율은 빼고 센다(S139)
class CostGrid extends AStarGrid2D:
	var castle: Dictionary
	var structures: Dictionary
	var barriers: Dictionary  # 에너지 성벽 칸(S151, I142). 부서지지 않는 막힌 칸이다
	var wall_k := 1.0  # 경로를 구하기 직전에 그 적의 값을 넣는다
	var climb := 0.0  # 성곽 성벽 칸의 비용(오르는 시간 × 속도, I76). 기어오르는 적의 경로를 구하는 동안만 0보다 크다

	# 성곽을 먼저 본다. 성벽 위 대포의 칸은 성벽이다(I72)
	func block_at(c: Vector2i):
		var b = castle.get(c, structures.get(c, barriers.get(c)))
		return null if b and b.open else b

	# 2026-10-20
	# [동작] 칸마다 막힌 칸 종류와 체력 비용을 배열에 펴 두고, 경로를 구할 때마다(path) 다시 편다
	# [이유] _compute_cost는 이웃 칸 하나마다 불린다. 사전 3개를 뒤지던 때는 적 100명 재계산이 320ms였다(디버그 빌드,
	#        insights/2026-10-20_render_spike.md). 비용 식과 계산 순서는 그대로다
	var _w := 0
	var _kind := PackedByteArray()  # 0 빈칸·열린 성문, 1 막힌 칸, 2 성곽 성벽, 3 에너지 성벽
	var _hp := PackedFloat64Array()  # 남은 체력 / 업그레이드 배율(S139)
	var _id := PackedInt64Array()  # 칸의 막힌 Block. 같은 Block 안에서 옮겨 가는 칸은 비용을 다시 매기지 않는다(I179)

	func path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
		_w = region.size.x
		_kind.resize(region.size.x * region.size.y)
		_kind.fill(0)
		_hp.resize(_kind.size())
		_id.resize(_kind.size())
		_id.fill(0)
		for d in [barriers, structures, castle]:  # 성곽을 먼저 본다(block_at)
			for c in d:
				var b = d[c]
				var i: int = c.y * _w + c.x
				_kind[i] = 0 if b.open else (2 if b.kind == "castle_wall" else (3 if b.kind == "barrier" else 1))
				_hp[i] = b.hp / pow(UPGRADE_MULT, b.level - 1)
				_id[i] = b.get_instance_id()
		return get_id_path(from, to, true)

	# 경로가 보는 막힌 칸. 유닛 경로(order_move가 wall_k를 UNIT_WALL_K로 둔다)는 에너지 성벽을 지나간다(I142)
	func _solid(i: int) -> bool:
		return _kind[i] != 0 and not (_kind[i] == 3 and wall_k >= UNIT_WALL_K)

	func _compute_cost(from: Vector2i, to: Vector2i) -> float:
		# 옆 칸이 막혔으면 대각선으로 끼어들지 않는다(solid였을 때의 DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES와 같게)
		if from.x != to.x and from.y != to.y and (_solid(from.y * _w + to.x) or _solid(to.y * _w + from.x)):
			return 1e9
		var t := to.y * _w + to.x
		if not _solid(t) or _id[t] == _id[from.y * _w + from.x]:  # 같은 Block 안(두꺼운 성벽·문루·큰 건물, I179)은 들어갈 때 한 번만 센다
			return Vector2(to - from).length()
		if climb > 0.0 and _kind[t] == 2:  # 부수지 않고 넘는다(I43)
			return Vector2(to - from).length() + climb
		return Vector2(to - from).length() + _hp[t] * wall_k

var size: Vector2i
var spawns: Array
var spawn_spread := 0  # 출현 지점마다 가로로 흩어져 나오는 칸 수(±, I177). 0이면 출현 지점 칸에서 나온다
var forecast := []  # 출현 지점마다 기본 적이 지금 나오면 걸을 길(칸 배열, S142). 화면이 선으로 그린다
var waves: Array  # 지금 라운드의 웨이브
var rounds: Array  # 도전의 라운드마다 웨이브 배열(S63, I91). stage에 rounds가 없으면 waves 하나가 1라운드짜리 도전이다
var nights: Array  # 라운드마다 웨이브 차례의 밤 {at, dark, fade}(S210). 없거나 짧으면 낮이다
var base: Block
var castle := {}      # 성곽의 칸(앞 왼쪽 칸) → 성곽 Block. 성벽은 열마다, 성문은 문마다 하나다(S217)
var walls := {}  # 성곽 차지 칸 → 성곽 Block(S217). 길 격자와 칸으로 찾는 곳은 이것을 본다
var field_y := 0  # 들판 첫 줄: 성곽(없으면 마을) 아래 첫 줄. 들판 꾸밈이 쓴다
var structures := {}  # 구조물의 칸 → Block. 한 구조물에 한 키다
var footprint := {}  # 차지 칸 → 구조물(S216). 길 격자와 칸으로 찾는 곳은 이것을 본다
var rubble := {}  # 성곽의 칸 → 부서진 성곽 Block(I88). 지나갈 수 있고, 복구하면 castle로 돌아간다(I89)
var debris := {}  # 잔해 차지 칸 → 잔해 Block
var barriers := {}  # Vector2i → 에너지 성벽 칸 Block(S151, I142). 그 장판(zones)이 끝나면 사라진다
var zones := []  # 장판(S150, I141): {src, pos, radius, left, owner, 수치…}. 웨이브가 끝나면 모두 사라진다(I143)
var traces := []  # 즉시 스킬 흔적(S179): {hero, slot, aim, at, radius, hits, age}. 그리기만 읽고 1초 지나면 지운다
var fallen := []  # 쓰러진 영웅·용병·적(S180): {who, age}. 그리기만 읽고 FALLEN초 지나면 지운다
var missiles := []  # 날고 있거나 출발을 기다리는 투사체(Missile, S178). 웨이브가 끝나면 사라진다(I143)
var landed := []  # 닿은 투사체(Missile). 그리기만 읽고(맞은 반응·사건, S177·I171) 1초 지나면 지운다
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
# 준비 단계를 적 없는 전투로 돈다(S18 2026-10-25 변경, I175): 짓기·업그레이드·수리·복구는 공병, 용병은 시설에서 산다. 시작 공병(S208)도 이것이 켜졌을 때다
# ponytail: 평가 300여 곳이 준비 단계 즉시 짓기·놓기로 판을 차려서, 끄면 옛 규칙인 길을 남긴다. 게임 장면(Main.live_prep)·하네스·봇이 켠다
var live_prep := false
var state := "prep"  # "prep" | "battle" | "hiring"(도전 시작 전 영입 창, S122) | "cleared"(라운드 사이, S117) | "won"(도전 성공) | "lost"
var round_index := 0
var wave_index := 0
var gold := 0
var village := Rect2i()  # 마을 칸. 생산 시설은 안에만, 나머지 구조물은 밖에만 짓는다(S43). 비어 있으면 모두 들판
var roads := {}  # 길 칸 → true. 마을 안이라도 짓지 못한다(S43 2026-10-26 변경). 스테이지가 정하고, 없으면 비어 있다
var merc_cap := MERC_CAP
var village_level := 1  # 오를수록 지을 수 있는 생산 시설이 는다(S46, S99)
var dark := 0.0  # 어둠(S210): 0 낮 ~ 1 한밤. 밤 웨이브의 전투 단계에 오르고, 전투가 끝나면 내린다. 저장에 담지 않는다(준비 단계는 낮)
var wave_time := 0.0  # 이번 전투 단계가 시작된 뒤 흐른 시간(초). 밤 웨이브의 해 지는 때(at)를 잰다
var lights := []  # 불빛(S211): [자리(칸), 어둠 1일 때 반경(칸)]. step 끝에 다시 모은다. 화면이 어둠을 그릴 때 읽는다

var grid := CostGrid.new()
var _wall := AStarGrid2D.new()  # 성벽 위 길. 성곽 칸만 걸을 수 있다(I69)
var _repath := false  # 막힌 칸이 바뀌어 적 경로를 다시 구해야 한다
var _stale := {}  # 경로를 다시 구할 적, 먼저 밀린 순서(I155)
var _queue := []      # 이번 웨이브에서 아직 안 나온 적 [종류, 출현 지점, 나올 칸](wave_plan)
var _spawn_timer := 0.0
var _spare := 0.0  # 아직 1골드가 되지 않은 처치 보상(I176)
var _stage: Dictionary  # 재시작할 때 다시 읽는다
var _rng := RandomNumberGenerator.new()  # 영입소 목록을 뽑는다. 스테이지에 seed가 있으면 그 씨앗이다(평가용)
var _luck := RandomNumberGenerator.new()  # 치명타·요새화 기절(S149, S151). 영입소 목록이 전투에 따라 바뀌지 않게 따로 둔다
var _chains := 0  # 영혼 사슬(S154)마다 붙이는 번호
var _holds := {}  # 유닛 → 그 유닛이 붙잡은 적 수(S159). 스텝마다 적의 engaged로 다시 센다
var _tracing = null  # 지금 내는 스킬 흔적(_trace). 그동안 피해·회복을 받은 대상이 hits에 쌓인다
var _lit := {}  # 구역(LIGHT_CHUNK칸) → 그 구역에 닿는 [불빛 자리, 지금 반경²](seen)
var _all_lit := true  # 어둠이 0이거나 불빛 하나가 맵을 다 덮어 모두 보인다

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
	spawn_spread = stage.get("spawn_spread", 0)
	for c in spawns:
		assert(c.x == 0 or c.y == 0 or c.x == size.x - 1 or c.y == size.y - 1, "출현 지점 %s가 맵 가장자리가 아니다" % c)
	rounds = stage.get("rounds", [stage.get("waves", [])])
	nights = stage.get("nights", [])
	grid.region = Rect2i(Vector2i.ZERO, size)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	_wall.region = grid.region
	_wall.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_wall.update()
	grid.castle = walls
	grid.structures = footprint
	grid.barriers = barriers
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
	_spare = 0.0
	village = stage.get("village", Rect2i())
	roads = stage.get("roads", {})
	merc_cap = stage.get("merc_cap", MERC_CAP)
	village_level = 1
	dark = 0.0
	wave_time = 0.0
	for s in structures.values() + castle.values() + rubble.values() + ([base] if base else []):  # 공병 ↔ 구조물 상호 참조를 끊는다. 남기면 RefCounted 순환이라 해제되지 않는다
		_release(s)
	base = Block.new(stage.base, "base", stage.base_hp)
	castle.clear()
	walls.clear()
	rubble.clear()
	debris.clear()
	structures.clear()
	footprint.clear()
	barriers.clear()
	zones.clear()
	missiles.clear()
	landed.clear()
	enemies.clear()
	units.clear()
	_queue.clear()
	_repath = false
	_stale.clear()
	var fort: Dictionary = stage.get("castle", {})
	for kind in ["castle_wall", "gate"]:  # 크기(S217)가 없으면 칸 하나다. 성벽은 열마다, 성문은 문마다 Block 하나
		for c in fort.get("walls" if kind == "castle_wall" else "gates", []):
			var k := Block.new(c, kind, fort.wall_hp if kind == "castle_wall" else fort.gate_hp)
			k.size = fort.get("wall_size" if kind == "castle_wall" else "gate_size", Vector2i.ONE)
			_put(castle, walls, k)
	for c in fort.get("side_walls", []):  # 사방 성곽의 동·서 성벽은 행마다 Block 하나(S217 2026-10-26 둘째 변경)
		var k := Block.new(c, "castle_wall", fort.wall_hp)
		k.size = fort.side_wall_size
		_put(castle, walls, k)
	for c in fort.get("sealed", []):  # 닫힌 문루(S39)
		castle[c].sealed = true
	field_y = village.end.y + 1
	for k in castle.values():
		field_y = maxi(field_y, k.cell.y + 1)
	base.produces = ["engineer"]  # live_prep 판에서는 거점도 공병을 판다(S98 2026-10-25 변경, sellers)
	var exit = _exit_of(base)
	base.rally = exit if exit != null else base.cell
	heroes.clear()
	# 영웅 목록(I102). 목록이 없고 hero_start만 있으면 아이아스 하나다. 이 영웅들은 보유·출전한 채 시작한다(평가용 스테이지)
	# 레벨(level)을 정하지 않으면 최대 레벨이다(I115)
	var team: Array = stage.get("heroes", [] if stage.get("hero_start") == null else [{"kind": "aias", "cell": stage.hero_start}])
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
		_luck.seed = stage.seed + 1
	else:
		_rng.randomize()
		_luck.randomize()
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
	_forecast()
	_light_up()

func step(dt: float) -> void:
	for t in traces + fallen + landed:
		t.age += dt
	traces = traces.filter(func(t): return t.age < 1.0)
	landed = landed.filter(func(m): return m.age < 1.0)
	fallen = fallen.filter(func(f): return f.age < FALLEN)
	if state == "battle":
		_spawn_wave(dt)
		tally.battle_time += dt  # 라운드 집계(I119)
		wave_time += dt
	if _repath:
		_repath = false
		for e in enemies:
			_stale[e] = true  # 이미 밀린 적은 자리를 지킨다
		_forecast()
	var n := 0
	for e in _stale.keys():
		if n == REPATH_PER_STEP:
			break
		_stale.erase(e)
		if e.alive:
			_find_path(e)
			n += 1
	_tick(dt)
	_zones(dt)
	_count_holds()
	for e in enemies:
		_move(e, dt)
	_push_apart(enemies, units)
	var ground := units.filter(func(u): return not u.on_wall)  # 성벽 위 유닛은 밀리지 않는다(I70)
	for u in units:
		_act(u, dt)
	_push_apart(ground, enemies)
	_fire(dt)
	_fly(dt)
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
		_clear_effects()
		if state == "prep" and revive:
			for h in heroes:
				if not h.alive:
					_return_hero(h)
	for k in castle.values() + rubble.values():  # 성문 쿨타임은 전투 단계에만 줄고, 웨이브가 끝나면 사라진다(S135)
		k.lock = maxf(k.lock - dt, 0.0) if state == "battle" else 0.0
	_night(dt)
	_light_up()

# 라운드 r·웨이브 w의 밤(S210): {at, dark, fade}. 낮이면 {}
func night(r: int, w: int) -> Dictionary:
	if r >= nights.size() or w >= nights[r].size():
		return {}
	return nights[r][w]

# 어둠(S210): 밤 웨이브의 전투 단계에서 at초가 지나면 dark까지 fade초에 오르고, 그 밖에는 1을 DAWN초에 내리는 빠르기로 0까지 내린다
func _night(dt: float) -> void:
	var n := night(round_index, wave_index) if state == "battle" else {}
	if n.is_empty() or wave_time < n.get("at", 0.0):
		dark = maxf(dark - dt / DAWN, 0.0)
		return
	var goal := clampf(n.get("dark", 1.0), 0.0, 1.0)
	dark = minf(dark + goal / maxf(n.get("fade", DUSK), 0.01) * dt, goal) if dark < goal else maxf(dark - dt / DAWN, goal)

# 어둠 1일 때 x의 불빛 반경(칸, S211). 데이터 값이라 저장된 판에도 같다. 빛이 없으면 0
func light_of(x) -> float:
	if x is Unit:
		return (HERO_KINDS if x.is_hero else MERC_KINDS)[x.kind].get("light", 0.0)
	if x == base:
		return BASE_LIGHT
	if x.kind == "gate":
		return GATE_LIGHT
	if not x.complete or x.razed >= 1.0:  # 미완성(I18)·접어 옮기는 대포(I74)는 빛이 없다
		return 0.0
	return STRUCTURE_KINDS.get(x.kind, {}).get("light", 0.0)

# 불빛(S211)을 모으고, 지금 어둠의 반경으로 구역마다 나눠 담는다. 어둠이 0이거나 불빛 하나가 맵을 다 덮으면 모두 보인다
func _light_up() -> void:
	lights.clear()
	_lit.clear()
	for x in units + structures.values() + castle.values() + [base]:  # 쓰러진 유닛·부서진 칸은 이 목록에 없다
		var r := light_of(x)
		if r > 0.0:
			lights.append([x.pos if x is Unit else middle(x), r])
	_all_lit = dark <= 0.0
	if _all_lit:
		return
	var far := Vector2(size).length()
	var last := (size - Vector2i.ONE) / LIGHT_CHUNK
	for l in lights:
		var r: float = l[1] / dark
		if r >= far:
			_all_lit = true
			return
		var lo := Vector2i(((l[0] - Vector2(r, r)) / LIGHT_CHUNK).floor()).clamp(Vector2i.ZERO, last)
		var hi := Vector2i(((l[0] + Vector2(r, r)) / LIGHT_CHUNK).floor()).clamp(Vector2i.ZERO, last)
		for cx in range(lo.x, hi.x + 1):
			for cy in range(lo.y, hi.y + 1):
				var k := Vector2i(cx, cy)
				if not _lit.has(k):
					_lit[k] = []
				_lit[k].append([l[0], r * r])

# 칸 좌표 p가 보이나(S211, S213): 어둠이 0이면 늘 보이고, 아니면 어느 불빛의 지금 반경(밤 반경 ÷ 어둠) 안이어야 한다
func seen(p: Vector2) -> bool:
	if _all_lit:
		return true
	for l in _lit.get(Vector2i((p / LIGHT_CHUNK).floor()).clamp(Vector2i.ZERO, (size - Vector2i.ONE) / LIGHT_CHUNK), []):
		if p.distance_squared_to(l[0]) <= l[1]:
			return true
	return false

# 영웅을 자기 시작 칸에 세운다. 체력은 쓰러졌다 돌아올 때(S26, I102) 1이고(S138, I27), 새로 출전할 때(S124) 가득 찬다.
# 마나도 돌아올 때 0, 새로 출전할 때 가득이다(S146). 공격·스킬 대기는 쓰러질 때 값을 이어 간다(S67)
func _return_hero(h: Unit, fresh := false) -> void:
	h.alive = true
	h.hp = h.max_hp if fresh else 1.0
	h.mana = h.max_mana if fresh else 0.0
	h.order = null
	h.pos = Vector2(h.home)
	h.still = 0.0  # 요새화 시간도 새로 센다(I147)
	h.on_wall = false
	h.path.clear()
	h.after.clear()
	units.append(h)

func start_battle() -> void:
	if state != "prep" or wave_index >= waves.size():
		return
	wave_starting.emit()
	state = "battle"
	_queue = wave_plan(round_index, wave_index)
	_spawn_timer = 0.0
	wave_time = 0.0

# 라운드 r·웨이브 w의 적을 나오는 차례대로 [종류, 출현 지점, 나올 칸]. 항목 차례로 나오고 출현 지점을 돌아가며 쓴다.
# 나올 칸은 출현 지점에서 n번째 적마다 황금비 수열로 가로 ±spawn_spread 안에 흩는다(I177). 씨앗을 쓰지 않는다.
# 전투(start_battle)와 미리보기(spawn_counts, S188)가 함께 써서 미리보기가 실제와 어긋나지 않는다
func wave_plan(r: int, w: int) -> Array:
	var out := []
	for entry in rounds[r][w]:
		for i in entry.count:
			var s: Vector2i = spawns[out.size() % spawns.size()]
			var n := out.size() / spawns.size()
			var x := s.x - spawn_spread + int(fposmod(n * 0.6180339887, 1.0) * (2 * spawn_spread + 1))
			out.append([entry.kind, s, Vector2i(clampi(x, 0, size.x - 1), s.y)])
	return out

# 출현 지점(spawns 차례)마다 {적 종류: 수}(S188)
func spawn_counts(r: int, w: int) -> Array:
	var out := spawns.map(func(_c): return {})
	for p in wave_plan(r, w):
		var d: Dictionary = out[spawns.find(p[1])]
		d[p[0]] = d.get(p[0], 0) + 1
	return out

# 이번 웨이브에서 아직 안 나왔거나 살아 있는 적 수(I13 «남은 적»)
func enemies_left() -> int:
	return _queue.size() + enemies.size()

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
	elif live_prep:  # 도전의 첫 준비 단계: 시작 공병(S208)
		for c in _stage.get("engineer_cells", []):
			units.append(Unit.new("engineer", c, MERC_KINDS.engineer))
	state = "prep"
	_deploy()
	for h in heroes:
		if not h.alive:
			_return_hero(h)
	_forecast()  # 라운드에 따라 길이 성문을 지난다(S142, S143)
	return true

# 공병이 가서 일하고 용병을 생산 시설에서 사는 단계: 전투 단계와, live_prep이면 준비 단계(S18, I175)
func live() -> bool:
	return state == "battle" or (live_prep and state == "prep")

# [동작] 도전 시작 전 영입 창(S122)을 연다. main·HUD가 새 도전(restart) 직후에 부른다
# [이유] restart()가 곧바로 열지 않는 것은 동결된 평가(EV36·EV80·EV165·EV170)가
#        «restart 직후 = 1라운드 웨이브 1의 준비 단계»에 기대서다
func begin_hiring() -> void:
	state = "hiring"

# 영입 창(도전 시작 전·라운드 사이)이 떠 있다. 영입·리롤·내보내기·출전 선택은 이때만 한다(I104)
func hiring_open() -> bool:
	return state in ["hiring", "cleared"]

# 목록을 모두 새로 뽑는다(I103): 칸마다 보유하지 않았고 이 목록에 아직 없는 영웅이 후보다. 후보가 있는 등급만 등장 확률 비율대로 고르고,
# 그 등급의 후보 가운데 하나를 같은 확률로 고른다. 후보가 없으면 빈 칸이다
func _draw_offers() -> void:
	offers.clear()
	for i in HIRE.slots:
		var free := HERO_KINDS.keys().filter(func(k): return not k in offers and not roster.any(func(h): return h.kind == k))
		if free.is_empty():
			offers.append("")
			continue
		var odds := PackedFloat32Array(range(HIRE.odds.size()).map(func(g): return HIRE.odds[g] if free.any(func(k): return HERO_KINDS[k].grade == g + 1) else 0.0))
		var grade: int = _rng.rand_weighted(odds) + 1
		var kinds := free.filter(func(k): return HERO_KINDS[k].grade == grade)
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
			_return_hero(h, true)
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
	var stats: Dictionary = ENEMY_KINDS[kind].merged(overrides, true)
	stats.hp *= _hp_mult()  # 라운드 체력 배율(S144). 처치 보상은 그대로다
	var e := Enemy.new(kind, cell, stats)
	if not e.flying:
		e.via = _gate_of(cell)
	e.goal = base.cell
	_find_path(e)
	enemies.append(e)
	enemy_spawned.emit(e)
	return e

# 지금 라운드의 적 체력 배율(S144). stage에 hp_mult가 없거나 짧으면 1이다
func _hp_mult() -> float:
	var m: Array = _stage.get("hp_mult", [])
	return m[round_index] if round_index < m.size() else 1.0

# GATE_SPLIT_ROUND부터 그 칸에서 가장 가까운(직선 거리) 성문 칸. 거리가 같으면 성문 목록에서 앞선 것이다. 그 전이거나 성문이 없으면 null(S143)
func _gate_of(cell: Vector2i):
	if round_index + 1 < GATE_SPLIT_ROUND:
		return null
	var fort: Dictionary = _stage.get("castle", {})
	var best = null
	var best_d := INF
	for g in fort.get("gates", []):  # 거리는 문루에서 가장 가까운 칸까지(S217). 칸 하나인 문은 그 칸이다
		var r := area_at(g, fort.get("gate_size", Vector2i.ONE))
		var d := Vector2(cell).distance_to(Vector2(cell).clamp(Vector2(r.position), Vector2(r.end - Vector2i.ONE)))
		if d < best_d:
			best = g
			best_d = d
	return best

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

# 준비 단계 구매(S50): 마을이 있는 스테이지면 그 용병을 파는 곳(sellers)이 있어야 한다
func can_buy(kind: String) -> bool:
	return not village.has_area() or not sellers(kind).is_empty()

# 그 용병을 파는 곳: 완성된 생산 시설(지은 차례)과, live_prep 판의 공병이면 맨 뒤에 거점(S98 2026-10-25 변경)
func sellers(kind: String) -> Array:
	return structures.values().filter(func(s): return s.complete and kind in s.produces) + ([base] if live_prep and kind in base.produces else [])

# 준비 단계에만, 놓을 수 있는 칸(_merc_cell)에 바로 놓는다(S18). live_prep 판의 플레이어는 시설에서 산다(recruit, I20). 이것은 판을 차리는 길이다(I175). 성곽 칸이면 그 칸의 성벽 위에 선다(I134). 골드가 모자라면 거부한다(I16)
# 시설 조건(S50)은 보지 않는다. 플레이어의 구매는 Controls가 can_buy로 먼저 묻는다
func place_merc(kind: String, cell: Vector2i, overrides := {}):
	if state != "prep" or not _merc_cell(cell):
		return null
	var stats: Dictionary = MERC_KINDS[kind].merged(overrides, true)
	if gold < stats.cost or _mercs() >= merc_cap:
		return null
	gold -= stats.cost
	var m := Unit.new(kind, cell, stats)
	m.on_wall = walls.has(cell)
	m.paid = stats.cost
	units.append(m)
	tally.merc_bought += 1  # 라운드 집계(I119)
	return m

# 용병을 놓을 수 있는 칸: 거점이 아닌 맵 안 칸 가운데 막히지 않은 칸이나, 대포가 없는 성곽 칸(I134)
func _merc_cell(cell: Vector2i) -> bool:
	return grid.is_in_boundsv(cell) and cell != base.cell and (not grid.block_at(cell) or (walls.has(cell) and not footprint.has(cell)))

# 유닛들을 그 칸으로 보낸다(S14). attack이면 공격 이동, 아니면 순수 이동이다(S35). 맵 밖 칸이면 무시한다. 성곽 칸이면 성벽 위의 그 칸으로 간다(I69)
func order_move(group: Array, cell: Vector2i, attack := false) -> void:
	if not grid.is_in_boundsv(cell):
		return
	_unit_paths()
	for u in group:
		_drop_orders(u)
		u.move_mode = "attack_move" if attack else "move"
		if u.alive:
			_route(u, cell)

# 유닛들이 적 e를 대상 공격한다(S35). 걸어가는 동안은 순수 이동처럼 다른 적을 치지 않는다
func order_attack(group: Array, e: Enemy) -> void:
	_unit_paths()
	for u in group:
		_drop_orders(u)
		u.move_mode = "move"
		if u.alive:
			u.prey = e
			u.chase_to = Vector2i(e.pos.round())
			_route(u, u.chase_to)

# 정지(S35): 명령을 지우고 그 자리에 선다
func stop(group: Array) -> void:
	for u in group:
		_drop_orders(u)
		_halt(u)

# 앞선 명령을 지운다: 집결(I22)·걸어가서 쓰려던 스킬(S147)·대상 공격(S35)·공병의 일(I63)
func _drop_orders(u: Unit) -> void:
	u.rally_from = null
	u.order = null
	u.prey = null
	if u.job:
		_release(u.job)

func _halt(u: Unit) -> void:
	u.path.clear()
	u.after.clear()
	u.anchor = u.pos
	u.rally_from = null

# 유닛 경로를 구하기 전에 부른다. 부서진 성곽 칸이 빠지게 성벽 위 격자를 매번 새로 깐다
func _unit_paths() -> void:
	grid.wall_k = UNIT_WALL_K
	_wall.fill_solid_region(_wall.region)
	for c in walls:  # 성벽 위는 차지 칸 어디로나 걷는다(S217 «성벽 위에서 이동»)
		_wall.set_point_solid(c, false)

# 땅과 성벽 위를 오가면 path 끝(성문 안쪽 칸이나 성문 칸)에서 오르내린 뒤 after를 걷는다(I44).
# 오르내릴 성문은 «땅 위 경로 비용 + 성벽 위 걸음 수»가 가장 작은 곳이고, 같으면 성곽 칸 차례가 앞선 곳이다(I69)
# 2026-10-26
# [동작] 땅 길은 «직선 거리 + 성벽 위 걸음 수» 하한이 작은 계단부터 구하고, 하한이 지금 최선보다 크면 멈춘다
# [이유] 사방 성곽(S203)에서 계단 칸이 3에서 12로 늘어 유닛 하나 명령에 땅 길 A*(칸마다 GDScript 비용 함수)를 12번 돌려
#        성벽 위로 보내는 명령이 한 명에 0.5ms에서 9ms가 됐고, 이렇게 해서 1.5ms다(2026-10-26 측정). 땅 길 비용은 직선 거리보다
#        작지 않아 고르는 계단은 그대로다. 내려가는 길은 _short가 막힌 목적지 앞에서 자르므로 가장 큰 차지 칸 대각선(4.5)만큼 하한을 낮춘다
func _route(u: Unit, cell: Vector2i) -> void:
	var from := Vector2i(u.pos.round())
	var up := walls.has(cell)
	u.path.clear()
	u.after.clear()
	if u.on_wall == up:
		u.path = (_wall.get_id_path(from, cell) if up else _short(grid.path(from, cell))).slice(1)
		return
	var cands := []  # [하한, 차례, 계단 칸, 성벽 위 길]
	for g in walls:
		var s = _stair(g)
		if s == null:
			continue
		var top: Array[Vector2i] = _wall.get_id_path(from, g) if u.on_wall else _wall.get_id_path(g, cell)
		if not top.is_empty():
			var near: float = Vector2(s).distance_to(Vector2(cell)) - 4.5 if u.on_wall else Vector2(s).distance_to(Vector2(from))
			cands.append([near + top.size(), cands.size(), s, top])
	cands.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
	var best := INF
	var best_i := -1
	for c in cands:
		if c[0] > best:
			break
		var ground: Array[Vector2i] = _short(grid.path(c[2], cell)) if u.on_wall else grid.path(from, c[2])
		var cost: float = _cost(ground) + c[3].size()
		if cost < best or (cost == best and c[1] < best_i):
			best = cost
			best_i = c[1]
			u.path = (c[3] if u.on_wall else ground).slice(1)
			u.after = ground if u.on_wall else c[3]

# 목적지 칸이 들어갈 수 없는 칸(구조물·거점)이면 길은 그 앞 칸에서 끝난다(S14). 에너지 성벽은 아군이 지나간다(I142)
func _short(p: Array[Vector2i]) -> Array[Vector2i]:
	while p.size() > 1:
		var b = grid.block_at(p.back())
		if p.back() != base.cell and (b == null or b.kind == "barrier"):
			break
		p.pop_back()
	return p

# 성문 바로 안쪽(마을 쪽) 칸. 성문이 아니거나 마을에 닿지 않으면 null(I44)
func _stair(g: Vector2i):
	if walls[g].kind != "gate":
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

# 용병의 홀드(S36)를 바꾼다. 영웅에게는 걸지 않는다(S16)
func set_hold(group: Array, on: bool) -> void:
	for u in group:
		if not u.is_hero:
			u.hold = on
			u.anchor = u.pos  # 기준 지점은 켠 순간의 위치(I37)

# 살아 있는 출전 영웅 가운데 첫 영웅(I126). 없으면 null
# ── 영웅 스킬(S145~S158) ──────────────────────────────────────────────

# 영웅 h가 칸 slot을 지금 쓸 수 있다(S145~S147): 전투 단계(S136), 살아 있음, 열린 칸(S76), 재사용 대기, 마나
func can_cast(h, slot: String) -> bool:
	var sk: Dictionary = h.get(slot)
	return state == "battle" and h.alive and not sk.is_empty() and h.level >= LEVELS.unlock[slot] and h.cd[slot] <= 0.0 and h.mana >= sk.mana

# 영웅 h(없거나 쓰러졌으면 살아 있는 첫 영웅, S119, I126)가 칸 slot을 쓴다(S145). 명령으로만 쓴다(S15).
# aim은 지점·방향이면 칸 좌표(Vector2), 아군·적 대상이면 그 유닛·구조물이다. 즉시·켜고 끄는 칸은 aim이 없다.
# 시전 사거리 밖이면 그쪽으로 걸어가 사거리에 들면 쓴다(S147). 쓰거나 걸어가기 시작하면 참
func cast(h, slot: String, aim = null) -> bool:
	h = h if h and h.alive else _first_alive()
	if not h or state != "battle":
		return false
	var sk: Dictionary = h.get(slot)
	if sk.get("id") == "brace" and h.brace > 0.0:  # 반격의 태세를 다시 누르면 바로 터뜨린다(S151)
		_burst(h)
		return true
	if sk.get("aim") == "toggle" and h.toggle:  # 켜진 토글은 언제든 끈다(S153)
		h.toggle = false
		return true
	if not can_cast(h, slot):
		return false
	match sk.aim:
		"self":
			_use(h, slot, null)
		"toggle":
			h.toggle = true
			h.cd[slot] = sk.gap
		_:
			if not _aim_ok(h, sk, aim):
				return false
			var at := _where(aim)
			if h.pos.distance_to(at) > CAST_RANGE:
				order_move([h], Vector2i(at.round()))
				h.order = {"slot": slot, "aim": aim}
				return true
			_use(h, slot, aim)
	return true

# 자동 시전(S158)을 켜고 끈다. 자동 시전이 있는 칸(크로노스 Q)만이다. 단계와 상관없다
func toggle_auto(h, slot: String) -> void:
	if h and h.get(slot).get("auto", false):
		h.auto = not h.auto

# 대상이 그 칸의 조준 종류에 맞는다(S147, I145). 지점·방향은 맵 안 칸, 아군은 targets대로, 적은 살아 있는 적
func _aim_ok(h, sk: Dictionary, aim) -> bool:
	match sk.aim:
		"point", "dir":
			return aim is Vector2 and grid.is_in_boundsv(Vector2i(aim.round()))
		"enemy":
			return aim is Enemy and aim.alive and aim in enemies
		"ally":
			match sk.targets:
				"unit":  # 영웅·용병
					return aim is Unit and aim.alive and aim in units
				"hero_tower":  # 출전 영웅이나 완성된 쏘는 구조물
					return (aim is Unit and aim.alive and aim in heroes) or (aim is Block and aim.alive and aim.complete and aim.range > 0.0 and structures.get(aim.cell) == aim)
				"hero":  # 출전 영웅(자기 포함)
					return aim is Unit and aim.alive and aim in heroes
	return false

# 칸을 쓴다: 마나를 내고 재사용 대기를 시작하고 그 칸의 효과를 낸다. 이그니스 패시브(S156)가 커진 칸을 고른다
func _use(h, slot: String, aim) -> void:
	var sk: Dictionary = h.get(slot)
	var grow := 1.0
	h.mana -= sk.mana
	h.cd[slot] = sk.gap
	h.skill_uses += 1
	if h.passive.get("id") == "overload":
		if h.charged and slot != "r":
			grow += h.passive.grow
			h.cd[slot] = maxf(sk.gap - h.passive.cut, 0.0)
			h.charged = false
		h.casts += 1
		if h.casts % int(h.passive.every) == 0:
			h.charged = true
	_trace(h, slot, aim, aim if sk.aim == "point" else h.pos, sk.get("radius", 0.0) * grow)
	call("_cast_" + sk.id, h, sk, aim, grow)
	_tracing = null

# 즉시 스킬 흔적을 남긴다(S179). at은 흔적의 가운데(지점 스킬은 지점, 나머지는 쓴 때 영웅 자리)다. _tracing을 비울 때까지 맞은 대상이 hits에 쌓인다.
# 보스 강타(S195)도 남긴다. 그때 h는 그 적이고 slot은 스킬 이름이다
func _trace(h, slot: String, aim, at: Vector2, radius: float) -> void:
	_tracing = {"hero": h, "slot": slot, "aim": aim, "at": at, "radius": radius, "hits": [], "age": 0.0}
	traces.append(_tracing)

# 걸어가서 쓰기(S147, I145): 대상이 사라졌거나 길이 끝났는데 닿지 못했으면 그만둔다. 사거리에 들면 멈춰서 쓴다
func _follow_order(h: Unit) -> void:
	var aim = h.order.aim
	if not (aim is Vector2) and not (aim.alive and (aim in units or aim in enemies or structures.get(aim.get("cell")) == aim)):
		h.order = null
		return
	if h.pos.distance_to(_where(aim)) <= CAST_RANGE:
		var slot: String = h.order.slot
		h.order = null
		h.path.clear()
		h.after.clear()
		if can_cast(h, slot) and _aim_ok(h, h.get(slot), aim):
			_use(h, slot, aim)
	elif h.path.is_empty() and h.after.is_empty():
		h.order = null

# 유닛·적은 pos, 구조물·성곽은 cell, 지점은 그대로
func _where(x) -> Vector2:
	if x is Vector2:
		return x
	var p = x.get("pos")
	return p if p != null else Vector2(x.cell)

# 영웅 → 지점 방향. 영웅 칸을 골랐으면 아래쪽(적이 오는 쪽, S51)
func _toward(h: Unit, at: Vector2) -> Vector2:
	return (at - h.pos).normalized() if at.distance_to(h.pos) > 0.01 else Vector2.DOWN

func _first_alive():
	for h in heroes:
		if h.alive:
			return h
	return null

# ── 효과(S150, I141) ──

# 대상 t에 출처 src의 효과 eff를 secs초 건다. 같은 출처가 이미 걸려 있으면 값과 남은 시간을 새로 바꾼다(I97)
func _fx(t, src: String, eff: Dictionary, secs: float) -> void:
	var entry := eff.duplicate()
	entry.left = secs
	t.fx[src] = entry

# 더해서 쌓는 효과(증가율, 방어력·마법 저항 증감, 초당 피해·회복)의 합(S150)
func _fx_sum(t, key: String) -> float:
	var sum := 0.0
	for v in t.fx.values():
		sum += v.get(key, 0.0)
	return sum

# 곱해서 쌓는 감소율(받는 피해 감소, 둔화, 공격력·공격 속도 감소): 1 − Π(1 − 값)(S150)
func _fx_cut(t, key: String) -> float:
	var keep := 1.0
	for v in t.fx.values():
		keep *= 1.0 - v.get(key, 0.0)
	return 1.0 - keep

# 화면·평가가 읽는 효과(S150): 대상 t에 걸린 효과 key의 값(없으면 null)과, 더해서 쌓는 효과의 합
func effect(t, key: String):
	return _fx_on(t, key)

func effect_sum(t, key: String) -> float:
	return _fx_sum(t, key)

# 기절·속박·봉인·도발처럼 걸렸는지만 보는 효과. 걸려 있으면 그 값(도발이면 도발한 영웅), 아니면 null
func _fx_on(t, key: String):
	for v in t.fx.values():
		if v.has(key):
			return v[key]
	return null

# 오라(S96, I100, I144): pos에 걸리는 오라 key의 값. 살아 있는 출전 영웅 가운데 pos가 오라 반경 안인 것의 가장 큰 값.
# 오라는 Lv1부터다(S145). 다운된 영웅의 오라는 풀린다
func _aura(key: String, pos: Vector2) -> float:
	var best := 0.0
	for h in heroes:
		if h.alive and h.aura.has(key) and pos.distance_to(h.pos) <= h.aura.radius:
			best = maxf(best, h.aura[key])
	return best

# 공격 속도 증가율(S150): 영웅·쏘는 구조물은 크로노스 오라, 그리고 걸린 효과의 합. 실비아는 패시브 중첩(S153)도 더한다
func _haste(x) -> float:
	var up := _fx_sum(x, "haste")
	if x is Block or x.is_hero:
		up += _aura("haste", _where(x))
	if x is Unit and x.passive.get("id") == "weak_point":
		up += x.stacks * x.passive.haste
	return up

# 공격력 배율: 걸린 «공격력 +» 효과의 합(크로노스 Q, S158)
func _might(x) -> float:
	return 1.0 + _fx_sum(x, "might")

# 사거리(S153 실비아 오라, I144): 영웅·쏘는 구조물은 오라만큼 늘어난다. 용병은 그대로다
func _reach(x) -> float:
	var base_range: float = x.range
	return base_range * (1.0 + _aura("reach", _where(x))) if x is Block or x.is_hero else base_range

# 방어력(S149): 적은 기본값 + 걸린 증감 − 베스퍼 오라, 아군 유닛은 기본값 + 세라피나 오라 + 걸린 증감, 구조물은 방벽만 세라피나 오라를 받는다
func armor_of(t) -> float:
	if t is Enemy:
		return t.armor + _fx_sum(t, "armor") - _aura("foe_armor", t.pos)
	if t is Unit:
		return t.armor + _aura("armor", t.pos) + _fx_sum(t, "armor")
	return t.armor + (_aura("armor", Vector2(t.cell)) if t.kind == "wall" else 0.0)

# 워크3식 방어 공식(S149): 방어력 a의 물리 피해 배율. a ≥ 0이면 1 − 0.06a ÷ (1 + 0.06a), 음수면 2 − 0.94^(−a)
static func armor_mult(a: float) -> float:
	return 1.0 - 0.06 * a / (1.0 + 0.06 * a) if a >= 0.0 else 2.0 - pow(0.94, -a)

# 비행 적이 지금 날고 있다. 봉인(S155)에 걸리면 내려앉아 몸에 막힌다
func _flies(x) -> bool:
	return x is Enemy and x.flying and _fx_on(x, "seal") == null

# 보호막(S150)을 더한다. 출처마다 하나이고, 더하면 상한 cap까지 쌓이고 남은 시간은 새로 센다
func _shield(u: Unit, src: String, amount: float, secs: float, cap: float) -> void:
	var s: Dictionary = u.shields.get(src, {"hp": 0.0})
	u.shields[src] = {"hp": minf(s.hp + amount, cap), "left": secs}

# 피해를 보호막으로 먼저 받는다. 먼저 사라질 보호막부터 깎는다. 남은 피해를 돌려준다
func _absorb(u: Unit, amount: float) -> float:
	var order := u.shields.keys()
	order.sort_custom(func(a, b): return u.shields[a].left < u.shields[b].left)
	for src in order:
		var take := minf(amount, u.shields[src].hp)
		u.shields[src].hp -= take
		amount -= take
		if u.shields[src].hp <= 0.0:
			u.shields.erase(src)
	return amount

# 회복(S150): 받는 회복 증가를 곱하고 최대 체력을 넘지 않는다. 세라피나가 영웅·용병을 넘치게 회복하면 넘친 양이 빛의 보호막이 된다(S152)
# 구조물을 한 번에 회복하면 적의 경로를 다시 구한다. 초당 회복은 구하지 않는다(적이 성벽을 깎을 때와 같다)
func _heal(t, amount: float, src = null, repath := true) -> void:
	if not t.alive:
		return
	if _tracing != null:
		_tracing.hits.append(t)
	if t is Unit:
		amount *= 1.0 + _fx_sum(t, "heal_up")
	var over: float = t.hp + amount - t.max_hp
	t.hp = minf(t.hp + amount, t.max_hp)
	if over > 0.0 and t is Unit and src is Unit and src.passive.get("id") == "overflow":
		_shield(t, "seraphina", over, src.passive.time, INF)  # 넘친 양의 100%, 상한 없음(기획서)
	if t is Block and repath:
		_repath = true  # 남은 체력이 적의 경로 비용이다(S7)

# 치명타(S149): 실비아·쏘는 구조물이 «치명타 확률 +»가 걸린 적을 치면 그 확률로 피해 ×CRIT
func _crits(target: Enemy, src) -> bool:
	if not (src is Block or (src is Unit and src.passive.get("id") == "weak_point")):
		return false
	var odds := _fx_sum(target, "crit")
	return odds > 0.0 and _luck.randf() < odds

# 넉백·끌어당김: 땅 적은 막힌 칸·몸에 막히면 멈추고(_shove), 나는 적은 그대로 옮긴다
func _knock(e: Enemy, by: Vector2) -> void:
	if _flies(e):
		e.pos = (e.pos + by).clamp(Vector2.ZERO, Vector2(size - Vector2i.ONE))
	else:
		_shove(e, by, units)

# 효과·보호막의 남은 시간을 줄이고, 초당 피해(발화·중독)와 초당 회복을 낸다. 영웅 칸의 시간도 여기서 돈다
func _tick(dt: float) -> void:
	for e in enemies.duplicate():
		_age(e, dt)
		var dot := _fx_sum(e, "dot")
		if dot > 0.0:
			damage(e, dot * dt, "magic")
	for u in units.duplicate():
		_age(u, dt)
		for src in u.shields.keys():
			u.shields[src].left -= dt
			if u.shields[src].left <= 0.0:
				u.shields.erase(src)
		var regen := _fx_sum(u, "regen")
		if regen > 0.0:
			_heal(u, regen * dt)
	for s in structures.values() + castle.values():
		_age(s, dt)
		var regen := _fx_sum(s, "regen")
		if regen > 0.0 and s.complete:
			_heal(s, regen * dt, null, false)

func _age(t, dt: float) -> void:
	for src in t.fx.keys():
		t.fx[src].left -= dt
		if t.fx[src].left <= 0.0:
			t.fx.erase(src)

# 웨이브가 끝나면 장판·에너지 성벽·효과·보호막·날던 투사체가 모두 사라진다(I143). 준비 단계에 공짜 회복·효과가 남지 않게
func _clear_effects() -> void:
	for z in zones:
		_end_zone(z)
	zones.clear()
	missiles.clear()
	for t in enemies + units + structures.values() + castle.values():
		t.fx.clear()
	for u in units:
		u.shields.clear()
		u.brace = 0.0
		u.order = null
		u.mark = null

# ── 장판(S150, I141) ──

func _zone(src: String, h: Unit, at: Vector2, radius: float, secs: float, extra := {}) -> Dictionary:
	var z := {"src": src, "owner": h, "pos": at, "radius": radius, "left": secs}
	z.merge(extra)
	zones.append(z)
	return z

func _inside(z: Dictionary, p: Vector2) -> bool:
	if z.has("cells"):  # 에너지 성벽 둘레(S151): 성벽 칸 가운데 하나에서 radius 안
		return z.cells.any(func(c): return p.distance_to(Vector2(c)) <= z.radius)
	return p.distance_to(z.pos) <= z.radius

func _zones(dt: float) -> void:
	for z in zones.duplicate():
		if z.has("follow"):  # 영웅을 따라다니는 결계(크로노스 E)
			z.pos = z.owner.pos
		if z.get("delay", 0.0) > 0.0:  # 떨어지는 중인 운석(S156)
			z.delay -= dt
			if z.delay > 0.0:
				continue
			_meteor(z)
		var foes: Array = enemies.filter(func(e): return _inside(z, e.pos))
		match z.src:
			"aias_r":  # 둘레의 아군 영웅과 방어 타워(쏘는 구조물): 받는 피해 감소와 초당 최대 체력 비율 회복
				for t in heroes.filter(func(x): return x.alive) + structures.values().filter(func(x): return x.range > 0.0):
					if _inside(z, _where(t)) and (not t is Block or t.complete):
						_fx(t, "aias_r", {"dr": z.dr, "regen": z.regen * t.max_hp}, STAY)
			"sylvia_e":  # 덫: 땅 적이 밟으면 터진다
				if enemies.any(func(e): return not _flies(e) and e.pos.distance_to(z.pos) <= 0.5):
					for e in foes:
						_fx(e, "sylvia_e", {"root": true, "crit": z.crit}, z.root)
					z.left = 0.0
					_trace(z.owner, "trap", null, z.pos, z.radius)
					_tracing = null
			"sylvia_r":  # 화살비: 초당 물리 피해(보스 ×), 체력 비율 이하 보스 아닌 적은 처형
				for e in foes:
					damage(e, z.dps * dt * (z.boss if e.kind == "boss" else 1.0), "phys", z.owner)
					if e.alive and e.kind != "boss" and e.hp <= z.execute * e.max_hp:
						damage(e, e.hp, "true", z.owner)
			"seraphina_w":  # 성역: 안의 아군은 초당 회복과 정화, 안의 적은 둔화
				for u in units.filter(func(x): return _inside(z, x.pos)):
					for src in u.fx.keys():
						if _harmful(u.fx[src]):
							u.fx.erase(src)
					_heal(u, z.hps * dt, z.owner)
				for e in foes:
					_fx(e, "seraphina_w", {"slow": z.slow}, STAY)
			"vesper_q":  # 독안개: 안의 적을 중독시킨다(나와도 poison초 남는다)
				for e in foes:
					_fx(e, "vesper_q", {"dot": z.dps, "armor": z.armor, "mr": z.mr, "spread": z.spread}, z.poison)
			"vesper_r":  # 늪: 둔화·봉인, 초당 최대 체력 비율 마법 피해
				for e in foes:
					_fx(e, "vesper_r", {"slow": z.slow, "seal": true, "spread": z.owner.passive.radius}, STAY)
					damage(e, z.burn * e.max_hp * dt, "magic", z.owner)
			"ignis_q":  # 바닥 불길: 안의 적에게 초당 마법 피해(발화와 따로 든다)
				for e in foes:
					damage(e, z.dps * dt, "magic", z.owner)
			"ignis_e":  # 중력장: 중심으로 끌어당기고 마법 저항을 깎는다
				for e in foes:
					var to: Vector2 = z.pos - e.pos
					_knock(e, to.limit_length(z.pull * dt))
					_fx(e, "ignis_e", {"mr": z.mr}, STAY)  # 중력장 안에 있는 동안만
			"ignis_r":  # 용암: 초당 최대 체력 비율 마법 피해
				for e in foes:
					damage(e, z.burn * e.max_hp * dt, "magic", z.owner)
			"chronos_r":  # 시간 왜곡장: 안의 아군 영웅·쏘는 구조물은 빨라지고, 안의 적은 느려진다
				for t in heroes.filter(func(x): return x.alive) + structures.values().filter(func(x): return x.range > 0.0 and x.complete):
					if _inside(z, _where(t)):
						_fx(t, "chronos_r", {"haste": z.haste, "cdr": z.cdr}, STAY)
				for e in foes:
					_fx(e, "chronos_r", {"slow": z.slow, "lag": z.lag}, STAY)
		z.left -= dt
		if z.left <= 0.0:
			_end_zone(z)
			zones.erase(z)

# 해로운 효과(S152 정화가 지운다): 기절·속박·둔화·도발·봉인·공격력·공격 속도 감소, 받는 피해 증가, 초당 피해, 방어력·마법 저항 감소
func _harmful(v: Dictionary) -> bool:
	return ["stun", "root", "slow", "taunt", "seal", "weaken", "lag", "expose", "dot", "chain"].any(func(k): return v.has(k)) or v.get("armor", 0.0) < 0.0 or v.get("mr", 0.0) < 0.0

# 장판이 끝날 때: 에너지 성벽 칸을 치운다(S151)
func _end_zone(z: Dictionary) -> void:
	if z.has("cells"):
		for c in z.cells:
			barriers.erase(c)
		_repath = true

# ── 아이아스(S151) ──

# Q 방패 강타: 지점 쪽 부채꼴 안 적에게 물리 피해와 기절. 요새화 중이면 밀쳐 내고 둔화
func _cast_shield_bash(h: Unit, sk: Dictionary, aim, grow: float) -> void:
	var dir := _toward(h, aim)
	for e in enemies.duplicate():
		var to: Vector2 = e.pos - h.pos
		if to.length() > sk.radius * grow or (to.length() > 0.01 and rad_to_deg(absf(dir.angle_to(to))) > sk.arc / 2.0):
			continue
		damage(e, sk.damage, "phys", h)
		if not e.alive:
			continue
		_fx(e, "aias_q", {"stun": true}, sk.stun)
		if h.fort:
			_knock(e, (to.normalized() if to.length() > 0.01 else dir) * sk.push)
			_fx(e, "aias_q_slow", {"slow": sk.slow}, sk.slow_time)

# W 전장의 포효: 주변 적을 도발하고 방어력을 깎는다. 도발한 적 하나마다 최대 체력 비율 보호막
func _cast_war_cry(h: Unit, sk: Dictionary, _aim, grow: float) -> void:
	var n := 0
	for e in enemies:
		if e.pos.distance_to(h.pos) <= sk.radius * grow:
			_fx(e, "aias_w", {"taunt": h, "armor": sk.armor}, sk.time)
			n += 1
	if n > 0:  # 상한은 없다(기획서). 보호막 시간 5초는 기획서에 없어 세라피나와 같게 둔다
		_shield(h, "aias_w", n * sk.shield * h.max_hp, 5.0, INF)

# E 반격의 태세: time초 동안 받는 피해 감소. 끝나거나 다시 누르면 _burst
func _cast_brace(h: Unit, sk: Dictionary, _aim, _grow: float) -> void:
	h.brace = sk.time
	h.braced = 0.0
	_fx(h, "aias_e", {"dr": sk.dr}, sk.time)

# 태세 동안 들어온 피해(줄이기 전 값) × ratio를 주변 적에게 물리 피해로 낸다
func _burst(h: Unit) -> void:
	var sk: Dictionary = h.e
	var hurt: float = h.braced * sk.ratio
	h.brace = 0.0
	h.braced = 0.0
	h.fx.erase("aias_e")
	if hurt > 0.0:
		_trace(h, "burst", null, h.pos, sk.radius)
		for e in enemies.duplicate():
			if e.pos.distance_to(h.pos) <= sk.radius:
				damage(e, hurt, "phys", h)
		_tracing = null

# R 절대 방어선: 지점 칸을 가운데로, 영웅 → 지점 방향에 수직인 length칸 줄에 에너지 성벽을 세운다(I142)
func _cast_bulwark(h: Unit, sk: Dictionary, aim, _grow: float) -> void:
	var d := _toward(h, aim)
	var side := Vector2i(0, 1) if absf(d.x) > absf(d.y) else Vector2i(1, 0)
	var at := Vector2i(aim.round())
	var taken := _taken()
	var cells := []
	for i in range(-(int(sk.length) / 2), int(sk.length) - int(sk.length) / 2):
		var c := at + side * i
		if grid.is_in_boundsv(c) and not grid.block_at(c) and not debris.has(c) and c != base.cell and not taken.has(c):
			barriers[c] = Block.new(c, "barrier", 1e6)
			cells.append(c)
	if not cells.is_empty():
		_repath = true
		_zone("aias_r", h, aim, sk.radius, sk.time, {"cells": cells, "dr": sk.dr, "regen": sk.regen})

# ── 실비아(S153) ──

# Q 관통의 바람살: 지점 쪽 일직선(맵 끝까지)의 모든 적을 가까운 차례로 꿰뚫는다. 피해는 공격력 × ratio, 꿰뚫을 때마다 준다. 첫 적에게 약점 포착 중첩
func _cast_piercing_gale(h: Unit, sk: Dictionary, aim, _grow: float) -> void:
	var dir := _toward(h, aim)
	var hit := enemies.filter(func(e):
		return (e.pos - h.pos).dot(dir) >= 0.0 and absf((e.pos - h.pos).cross(dir)) <= sk.width / 2.0 + e.radius)
	hit.sort_custom(func(a, b): return (a.pos - h.pos).dot(dir) < (b.pos - h.pos).dot(dir))
	var hurt: float = h.damage * _might(h) * sk.ratio
	for e in hit:
		if e == hit[0]:
			h.stacks = maxi(h.stacks if h.mark == e else 0, sk.stacks)
			h.mark = e
		damage(e, hurt, "phys", h)
		hurt *= 1.0 - sk.falloff

func _cast_split_shot(_h: Unit, _sk: Dictionary, _aim, _grow: float) -> void:
	pass  # 켜고 끄는 칸이라 cast가 직접 다룬다. 효과는 _strike

# E 폭풍의 덫: 지점에 덫을 깐다. 개수와 시간 제한이 없고 밟히면 터진다(웨이브가 끝나면 사라진다, I143)
func _cast_storm_trap(h: Unit, sk: Dictionary, aim, grow: float) -> void:
	_zone("sylvia_e", h, aim, sk.radius * grow, INF, {"root": sk.root, "crit": sk.crit})

# R 천공의 화살비
func _cast_arrow_rain(h: Unit, sk: Dictionary, aim, _grow: float) -> void:
	_zone("sylvia_r", h, aim, sk.radius, sk.time, {"dps": sk.dps, "execute": sk.execute, "boss": sk.boss})

# ── 세라피나(S152) ──

# Q 성스러운 빛줄기: 아군 회복 → 가까운 적 마법 피해 → 가까운 다른 아군(또는 깎인 구조물) 회복 … 모두 hits번. 같은 대상은 다시 맞지 않는다
func _cast_holy_beam(h: Unit, sk: Dictionary, aim, _grow: float) -> void:
	var hit := [aim]
	_heal(aim, sk.heal, h)
	var next_foe := true
	while hit.size() < sk.hits:
		var from := _where(hit[-1])
		var pool: Array = enemies if next_foe else units + structures.values().filter(func(s): return s.complete and s.hp < s.max_hp)
		var best = null
		for t in pool:
			var d := from.distance_to(_where(t))
			if t not in hit and t.alive and d <= sk.hop and (best == null or d < from.distance_to(_where(best))):
				best = t
		if best == null:
			break
		hit.append(best)
		if next_foe:
			damage(best, sk.damage, "magic", h)
		else:
			_heal(best, sk.heal, h)
		next_foe = not next_foe

# W 정화의 성역
func _cast_sanctum(h: Unit, sk: Dictionary, aim, grow: float) -> void:
	_zone("seraphina_w", h, aim, sk.radius * grow, sk.time, {"hps": sk.hps, "slow": sk.slow})

# E 수호 천사의 날개: 받는 회복 증가. 그동안 체력이 0이 될 피해를 받으면 불사(damage)
func _cast_guardian(_h: Unit, sk: Dictionary, aim, _grow: float) -> void:
	_fx(aim, "seraphina_e", {"heal_up": sk.heal_up, "angel": sk.undying}, sk.time)

# R 기적의 강림: 모든 아군과 쏘는 구조물을 최대 체력 비율만큼 회복, 영웅·쏘는 구조물의 기본 공격에 축복
func _cast_miracle(h: Unit, sk: Dictionary, _aim, _grow: float) -> void:
	var shooters: Array = structures.values().filter(func(s): return s.complete and s.range > 0.0)
	for t in units.duplicate() + shooters:
		_heal(t, sk.heal * t.max_hp, h)
	for t in heroes.filter(func(x): return x.alive) + shooters:
		_fx(t, "seraphina_r", {"bless": sk.bless, "splash": sk.splash}, sk.time)

# 축복(S152): 기본 공격이 맞은 적 둘레 splash칸 안의 적에게 마법 피해를 더 준다. 원거리는 쏜 때의 양을 투사체에 담아 닿을 때 준다(_land)
func _bless(src, at: Vector2) -> void:
	var b = _fx_on(src, "bless")
	if b != null:
		_blessing(src, at, b, src.fx.seraphina_r.splash)

func _blessing(src, at: Vector2, amount: float, radius: float) -> void:
	for e in enemies.duplicate():
		if e.pos.distance_to(at) <= radius:
			damage(e, amount, "magic", src)

# ── 베스퍼(S154) ──

# Q 부식의 독안개
func _cast_corrosion(h: Unit, sk: Dictionary, aim, grow: float) -> void:
	_zone("vesper_q", h, aim, sk.radius * grow, sk.time, {"poison": sk.poison, "dps": sk.dps, "armor": sk.armor, "mr": sk.mr, "spread": h.passive.radius})

# W 쇠약의 저주
func _cast_enfeeble(h: Unit, sk: Dictionary, aim, grow: float) -> void:
	for e in enemies:
		if e.pos.distance_to(aim) <= sk.radius * grow:
			_fx(e, "vesper_w", {"slow": sk.slow, "weaken": sk.weaken, "expose": sk.expose, "spread": h.passive.radius}, sk.time)

# E 영혼 사슬: 대상과 radius칸 안 다른 적 links명(체력 높은 차례)을 묶는다. 피해 나누기는 damage
func _cast_soul_chain(h: Unit, sk: Dictionary, aim, grow: float) -> void:
	var others := enemies.filter(func(e): return e != aim and e.pos.distance_to(aim.pos) <= sk.radius * grow)
	others.sort_custom(func(a, b): return a.hp > b.hp)
	_chains += 1
	for e in [aim] + others.slice(0, sk.links):
		_fx(e, "vesper_e", {"chain": _chains, "share": sk.share, "spread": h.passive.radius}, sk.time)

# R 심연의 늪
func _cast_abyss(h: Unit, sk: Dictionary, aim, _grow: float) -> void:
	_zone("vesper_r", h, aim, sk.radius, sk.time, {"slow": sk.slow, "burn": sk.burn})

# 전염(S154 패시브): 베스퍼의 디버프(Q 중독·W 저주·E 사슬·R 늪)가 걸린 적이 죽으면 둘레 적에게 남은 시간만큼 옮긴다.
# 더 오래 남은 같은 효과는 그대로 둔다. 사슬이 옮으면 그 적도 같은 사슬에 묶인다
func _spread(dead: Enemy) -> void:
	for src in ["vesper_q", "vesper_w", "vesper_e", "vesper_r"]:
		if not dead.fx.has(src) or not dead.fx[src].has("spread"):
			continue
		var v: Dictionary = dead.fx[src]
		for o in enemies:
			if o.pos.distance_to(dead.pos) <= v.spread and (not o.fx.has(src) or o.fx[src].left < v.left):
				o.fx[src] = v.duplicate()

# ── 이그니스(S156) ──

# Q 화염구 작렬: 범위 마법 피해와 발화, 그 자리에 불길
func _cast_fireball(h: Unit, sk: Dictionary, aim, grow: float) -> void:
	for e in enemies.duplicate():
		if e.pos.distance_to(aim) <= sk.radius * grow:
			damage(e, sk.damage, "magic", h)
			if e.alive:
				_fx(e, "ignis_q", {"dot": sk.dps}, sk.burn)
	_zone("ignis_q", h, aim, sk.radius * grow, sk.fire, {"dps": sk.fire_dps})

# W 서리 고리: 범위 마법 피해와 둔화. 발화 중인 적은 열충격(피해 더하고 빙결)
func _cast_frost_ring(h: Unit, sk: Dictionary, aim, grow: float) -> void:
	for e in enemies.duplicate():
		if e.pos.distance_to(aim) > sk.radius * grow:
			continue
		var burning: bool = e.fx.has("ignis_q")
		damage(e, sk.damage + (sk.shock if burning else 0.0), "magic", h)
		if not e.alive:
			continue
		_fx(e, "ignis_w", {"slow": sk.slow}, sk.slow_time)
		if burning:
			_fx(e, "ignis_w_freeze", {"stun": true}, sk.freeze)

# E 비전 블랙홀
func _cast_black_hole(h: Unit, sk: Dictionary, aim, grow: float) -> void:
	_zone("ignis_e", h, aim, sk.radius * grow, sk.time, {"pull": sk.pull, "mr": sk.mr})

# R 메테오 스웜: 지점, 그 좌우 spread칸(영웅 → 지점 방향에 수직)에 delay초 간격으로 운석. 떨어진 자리는 용암
func _cast_meteor_swarm(h: Unit, sk: Dictionary, aim, _grow: float) -> void:
	var side: Vector2 = _toward(h, aim).orthogonal() * sk.spread
	var spots := [aim, aim + side, aim - side]
	for i in int(sk.count):
		_zone("ignis_r", h, spots[i % spots.size()], sk.radius, sk.lava, {"delay": sk.delay * (i + 1), "damage": sk.damage, "stun": sk.stun, "burn": sk.burn})

func _meteor(z: Dictionary) -> void:
	_trace(z.owner, "meteor", null, z.pos, z.radius)
	for e in enemies.duplicate():
		if e.pos.distance_to(z.pos) <= z.radius:
			damage(e, z.damage, "magic", z.owner)
			if e.alive:
				_fx(e, "ignis_r", {"stun": true}, z.stun)
	_tracing = null

# ── 크로노스(S158) ──

# Q 무기 과충전: 아군 영웅이나 쏘는 구조물의 공격 속도·공격력
func _cast_overcharge(_h: Unit, sk: Dictionary, aim, _grow: float) -> void:
	_fx(aim, "chronos_q", {"haste": sk.haste, "might": sk.might}, sk.time)

# 자동 시전(S158, I146): 켜져 있고 쓸 수 있으면 시전 사거리 안에서 아직 안 걸린 가장 공격력 높은 영웅·쏘는 구조물에 쓴다
func _autocast(h: Unit) -> void:
	if not h.auto or h.order or not can_cast(h, "q"):
		return
	var best = null
	for t in heroes + structures.values():
		if _aim_ok(h, h.q, t) and not t.fx.has("chronos_q") and _where(t).distance_to(h.pos) <= CAST_RANGE and (best == null or t.damage > best.damage):
			best = t
	if best:
		_use(h, "q", best)

# W 시간 되감기: 영웅(자기 포함)의 마나를 최대 마나 비율만큼 채우고 Q·W·E 대기를 줄인다
func _cast_rewind(_h: Unit, sk: Dictionary, aim, _grow: float) -> void:
	aim.mana = minf(aim.mana + sk.mana_back * aim.max_mana, aim.max_mana)
	for slot in ["q", "w", "e"]:
		aim.cd[slot] = maxf(aim.cd[slot] - sk.cut, 0.0)

# E 황금의 율법: 크로노스를 따라다니는 결계. 안에서 처치된 적의 골드가 늘어난다(damage)
func _cast_golden_law(h: Unit, sk: Dictionary, _aim, grow: float) -> void:
	_zone("chronos_e", h, h.pos, sk.radius * grow, sk.time, {"bonus": sk.bonus, "follow": true})

# R 시간 왜곡장
func _cast_time_warp(h: Unit, sk: Dictionary, aim, _grow: float) -> void:
	_zone("chronos_r", h, aim, sk.radius, sk.time, {"haste": sk.haste, "cdr": sk.cdr, "slow": sk.slow, "lag": sk.lag})

# 지을 수 있는 칸에 짓는다(_buildable). 마을 레벨이 모자란 종류는 거부한다(S99). live가 아닌 준비 단계엔 바로 완성된다(S18, I175).
# live()엔 진행률 0의 미완성 구조물을 놓고 놀고 있는 가장 가까운 공병을 보낸다. 그런 공병이 없으면 거부한다(S22, I39, I62)
# 생산 시설의 집결 지점 기본값은 출구 칸이다(I61). 건설비는 지시하는 순간 내고, 모자라면 거부한다(I16, I17)
func build(kind: String, cell: Vector2i, overrides := {}):
	if state not in ["prep", "battle"] or not _buildable(kind, cell) or STRUCTURE_KINDS[kind].village_level > village_level:
		return null
	var stats: Dictionary = STRUCTURE_KINDS[kind].merged(overrides, true)
	if gold < stats.cost or (stats.tax > 0 and structures.values().filter(func(s): return s.tax > 0).size() >= HOUSE_CAP):  # 집 상한(S101)
		return null
	var engineer = _idle_engineer(cell) if live() else null
	if live() and not engineer:
		return null
	gold -= stats.cost
	var s := Block.new(cell, kind, stats.hp)
	for key in stats:
		s.set(key, stats[key])
	s.paid = stats.cost
	_occupy(s)
	tally.built += 1  # 라운드 집계(I119)
	if engineer:
		s.progress = 0.0
		s.complete = false
		s.hp = 0.0
		_send(engineer, s)
	if not s.produces.is_empty():
		var exit = _exit_of(s)
		s.rally = exit if exit != null else cell
	_repath = true
	return s

# 차지 칸(S216)이 모두 빈 칸(구조물·거점·유닛·적이 없는 맵 안 칸, I24)이다. 생산 시설·집·교회는 마을 안, 나머지는 마을 밖이고,
# 성곽 칸에는 대포만 성벽 칸(성문 제외)에 짓는다(S43, I72). taken은 유닛·적이 선 칸(_taken)이고, 칸을 여럿 물을 때 한 번 모아 넘긴다
func _buildable(kind: String, cell: Vector2i, taken = null) -> bool:
	var def: Dictionary = STRUCTURE_KINDS[kind]
	var inside: bool = not def.produces.is_empty() or def.tax > 0 or def.heal > 0
	if taken == null:
		taken = _taken()
	for c in cells_in(area_at(cell, def.size)):
		if not grid.is_in_boundsv(c) or footprint.has(c) or c == base.cell or debris.has(c) or barriers.has(c) or roads.has(c):  # 잔해(I88)·에너지 성벽(I142)·길(S43) 칸에는 짓지 못한다
			return false
		if c in _stage.get("hero_cells", []):  # 출전 칸에는 짓지 못한다(I107). 영웅이 서거나 돌아올 칸이다
			return false
		if walls.has(c) and (kind != "cannon" or walls[c].kind != "castle_wall"):
			return false
		if taken.has(c) or village.has_point(c) != inside:
			return false
	return true

# 놓기 모드에서 그 칸에 그 구조물을 지을 수 있다(S216 미리보기). 골드·공병은 보지 않는다(I138)
func can_build(kind: String, cell: Vector2i) -> bool:
	return STRUCTURE_KINDS[kind].village_level <= village_level and _buildable(kind, cell)

# 구조물의 칸 cell에서 크기 size가 차지하는 칸(S216): 오른쪽으로 가로, 위로 깊이만큼
static func area_at(cell: Vector2i, size: Vector2i) -> Rect2i:
	return Rect2i(cell.x, cell.y - size.y + 1, size.x, size.y)

static func area_of(s) -> Rect2i:
	return area_at(s.cell, s.size)

static func cells_in(r: Rect2i) -> Array:
	var out := []
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			out.append(Vector2i(x, y))
	return out

# 구조물에서 p(칸 좌표)에 가장 가까운 차지 칸 가운데(I178). 칸 하나인 구조물·성곽·거점은 그 칸이다
static func nearest(s, p: Vector2) -> Vector2:
	var r := area_of(s)
	return p.clamp(Vector2(r.position), Vector2(r.end - Vector2i.ONE))

# 차지 칸 가운데(칸 좌표). 밤 불빛(S211)·주민(I178)의 기준이다
static func middle(s) -> Vector2:
	var r := area_of(s)
	return Vector2(r.position) + Vector2(r.size - Vector2i.ONE) / 2.0

func _occupy(s: Block) -> void:
	_put(structures, footprint, s)

func _vacate(s: Block) -> void:
	_cut(structures, footprint, s)

# 칸 → Block 사전(d)과 차지 칸 → Block 사전(fp)에 함께 넣고 뺀다(S216, S217)
func _put(d: Dictionary, fp: Dictionary, s: Block) -> void:
	d[s.cell] = s
	for c in cells_in(area_of(s)):
		fp[c] = s

func _cut(d: Dictionary, fp: Dictionary, s: Block) -> void:
	d.erase(s.cell)
	for c in cells_in(area_of(s)):
		fp.erase(c)

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
	return footprint.get(cell)

# 전투 단계(live)에만, 생산 시설에서 용병 하나를 산다(S20, I21, I20). 시설 옆 칸에 나타나 집결 지점으로 걸어간다(I61)
# live_prep 판의 거점은 공병을 파는 시설처럼 쓴다(S98 2026-10-25 변경)
# kind를 비우면 시설의 첫째 용병이다(S87). 시설이 팔지 않는 종류거나, 골드가 모자라거나, 배치 상한에 닿았거나(S25, I23),
# 시설이 파괴됐으면(S48) 거부한다
func recruit(f, kind := ""):
	if not live() or (structures.get(f.cell) != f and not (live_prep and f == base)) or f.produces.is_empty() or not f.complete:  # 미완성 시설은 생산하지 않는다(I18)
		return null
	if kind == "":
		kind = f.produces[0]
	if kind not in f.produces:
		return null
	var stats: Dictionary = MERC_KINDS[kind]
	var exit = _exit_of(f)
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
	order_move([u], f.rally, true)  # 집결 지점까지 공격 이동(I38)
	u.rally_from = f

# 시설 차지 칸 둘레의 빈 칸. 앞(아래, 들판 쪽 S51) 줄 → 왼쪽 옆 → 오른쪽 옆 → 뒤 줄 순서로, 앞·뒤 줄은 왼쪽부터, 옆 줄은 앞부터 본다(I61, I178)
# ponytail: 모서리(대각선) 칸은 보지 않는다. 둘레가 다 막히면 모서리까지 볼 일
func _exit_of(s: Block):
	var r := area_of(s)
	var ring := []
	for x in range(r.position.x, r.end.x):
		ring.append(Vector2i(x, r.end.y))
	for side in [r.position.x - 1, r.end.x]:
		for y in range(r.end.y - 1, r.position.y - 1, -1):
			ring.append(Vector2i(side, y))
	for x in range(r.position.x, r.end.x):
		ring.append(Vector2i(x, r.position.y - 1))
	for c in ring:
		if grid.is_in_boundsv(c) and not grid.block_at(c) and c != base.cell:
			return c
	return null

# 준비·전투 단계에 성문을 열거나 닫는다(S85, S117). 닫힌 문루(S39)는 거부한다. 성문 칸에 유닛이나 적이 있으면 닫지 않는다. 여닫으면 적(I67)과 걷던 유닛(I133)의 경로를 다시 구한다. 전투 단계에 여닫으면 그 성문만 GATE_LOCK초 동안 묶고, 묶인 성문과 거부된 지시는 묶지 않는다(S135)
func set_gate(g: Block, open: bool) -> void:
	if state not in ["prep", "battle"] or g.kind != "gate" or g.sealed or castle.get(g.cell) != g or g.lock > 0.0:
		return
	if not open and occupied_area(g):
		return
	g.open = open
	_repath = true
	_unit_paths()
	for u in units:  # 걷던 유닛도 지금 목적지까지 길을 다시 구한다(I133). 명령(집결·대상·이동 방식)은 그대로다. 일하러 가는 공병은 그대로 둔다
		if u.job == null and not (u.path.is_empty() and u.after.is_empty()):
			_route(u, (u.after if not u.after.is_empty() else u.path).back())
	if state == "battle":
		g.lock = GATE_LOCK

func upgrade_cost(k: Block) -> int:
	return UPGRADE_COST[k.kind] * (1 << (k.level - 1))

# 성곽 칸 하나를 한 단계 올린다(S86). 골드는 지시할 때 낸다(I16). live가 아닌 준비 단계엔 바로 오르고, live()엔 놀고 있는
# 가장 가까운 공병을 보낸다. 그런 공병이 없으면 거부한다. 그만둔 업그레이드는 골드를 더 내지 않고 이어 올린다(I68)
func upgrade(k: Block) -> void:
	if state not in ["prep", "battle"] or castle.get(k.cell) != k or k.level >= UPGRADE_MAX or k.worker:
		return
	var engineer = _idle_engineer(k) if live() else null
	if live() and not engineer:
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
	_repath = true  # 깎인 칸은 오른 체력만큼 적의 경로 비용도 바뀐다(S7, S139)

# 수리비(S114, I85): 아직 내지 않은 잃은 체력 × 체력 1당 값, 1골드 미만은 올린다.
# 구조물은 낸 골드 ÷ 최대 체력이라 판매 환불(S69)의 나머지와 같다. 잔해는 체력 0이라 복구비가 된다(I89)
func repair_cost(t: Block) -> int:
	var owed := maxf(t.max_hp - t.hp - t.mend, 0.0)
	return ceili(owed * REPAIR_RATE.get(t.kind, t.paid / t.max_hp) - 0.0001)  # ponytail: 부동소수 오차로 1골드 더 받지 않게

# 판에 있는 완성된 구조물·성곽 칸·거점이고, 깎였고, 일하는 공병이 없다(I85, I86)
func can_repair(t) -> bool:
	return t is Block and state in ["prep", "battle"] and t.complete and t.worker == null and t.hp < t.max_hp and (structures.get(t.cell) == t or castle.get(t.cell) == t or t == base)

# 깎인 것을 고친다(S80). live가 아닌 준비 단계엔 수리비를 내고 바로 가득 차고(I86), live()엔 지시할 때 내고
# 놀고 있는 가장 가까운 공병이 가서 낸 만큼 채운다(S115, I87). 공병이 없거나 골드가 모자라면 거부한다
func repair(t) -> void:
	if not can_repair(t):
		return
	var engineer = _idle_engineer(t) if live() else null
	if (live() and not engineer) or gold < repair_cost(t):
		return
	gold -= repair_cost(t)
	t.mend = t.max_hp - t.hp
	if engineer:
		_send(engineer, t)
	else:
		_mend(t, t.mend)

# 교회 치료비(S137): 잃은 체력 × 체력 1당 값(교회 데이터의 heal), 1골드 미만은 올린다(I140)
func heal_cost(h: Unit) -> int:
	return ceili((h.max_hp - h.hp) * STRUCTURE_KINDS.church.heal - 0.0001)  # ponytail: 부동소수 오차로 1골드 더 받지 않게(repair_cost와 같다)

# 준비 단계에 완성된 교회가 있으면 치료비를 내고 살아 있는 출전 영웅의 체력을 가득 채운다(S137). 골드가 모자라면 거부한다(I140)
func heal(h: Unit) -> void:
	if state != "prep" or h not in heroes or not h.alive or h.hp >= h.max_hp or gold < heal_cost(h):
		return
	if not structures.values().any(func(s): return s.kind == "church" and s.complete):
		return
	gold -= heal_cost(h)
	h.hp = h.max_hp

# 잔해를 되살린다(I89). 복구비는 지시할 때 낸다. live가 아닌 준비 단계엔 바로 가득 찬 채 서고, live()엔 놀고 있는
# 가장 가까운 공병이 가서 닿으면 다시 세운 뒤 채운다(_work). 지시할 때 칸에 누가 있으면 거부한다
func restore(k: Block) -> void:
	if state not in ["prep", "battle"] or rubble.get(k.cell) != k or k.worker or occupied_area(k):
		return
	var engineer = _idle_engineer(k) if live() else null
	if (live() and not engineer) or gold < repair_cost(k):
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
	_cut(rubble, debris, k)
	_put(castle, walls, k)
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

# 그 Block의 차지 칸(S217) 어디에든 유닛이나 적이 서 있다
func occupied_area(k: Block) -> bool:
	var r := area_of(k)
	return (units + enemies).any(func(u): return r.has_point(Vector2i(u.pos.round())))

# 전투 단계(live)에만, 미완성 구조물을 없애고 낸 골드를 모두 돌려준다(S23, S83)
func cancel(s) -> void:
	if live() and not s.complete and structures.get(s.cell) == s:
		_remove(s)
		gold += s.paid

# 전투 단계(live)에만, 짓는 공병이 없는 미완성 구조물에 놀고 있는 가장 가까운 공병을 보낸다(S24, S83)
func resume(s):
	if not live() or s.complete or s.worker or structures.get(s.cell) != s:
		return null
	var engineer = _idle_engineer(s)
	if engineer:
		_send(engineer, s)
	return engineer

# live_prep이 꺼진 판의 준비 단계에만, 미완성 구조물을 추가 비용 없이 바로 완성한다(I19, I175)
func finish(s) -> void:
	if state == "prep" and not live_prep and not s.complete and structures.get(s.cell) == s:
		_grow(s, 1.0)

# 전투 단계에만, 철거할 수 있는 구조물마다 놀고 있는 가장 가까운 공병을 보낸다. 그런 공병이 없으면 그 구조물은 거부한다(S74, I64)
func demolish(things: Array) -> void:
	if state != "battle":
		return
	for t in things:
		var engineer = _idle_engineer(t) if can_demolish(t) else null
		if engineer:
			t.mend = 0.0  # 남은 수리 몫(I87)이 있으면 공병이 허물지 않고 고친다
			_send(engineer, t)

# 전투 단계에만, 놀고 있는 가장 가까운 공병을 보내 대포를 그 칸으로 옮긴다. 골드는 들지 않는다(S44, I48).
# 공병은 대포를 허물어 접고, 새 칸 옆에 닿으면 거기서 다시 짓는다(_work, I74)
func move_cannon(s: Block, cell: Vector2i) -> void:
	if state != "battle" or s.kind != "cannon" or not can_demolish(s) or not _buildable(s.kind, cell):
		return
	var engineer = _idle_engineer(s)
	if engineer:
		s.dest = cell
		s.mend = 0.0  # 남은 수리 몫(I87)이 있으면 공병이 접지 않고 고친다
		_send(engineer, s)

# 접은 대포를 새 칸으로 옮겨 진행률 0부터 다시 짓는다. 새 칸에 지을 수 없게 됐으면 그만둔다(I74)
func _settle(s: Block) -> void:
	if not _buildable(s.kind, s.dest):
		_release(s)
		return
	_vacate(s)
	s.cell = s.dest
	_occupy(s)
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

# 놀고 있는 공병(짓거나 허무는 일을 맡지 않은 공병) 가운데 그 칸(at이 Block이면 그 일 자리, _spot)에 가장 가까운 공병(I39). 성벽 위 공병은 뺀다(I69).
# 막힌 칸을 지나야만 닿는 공병도 뺀다(I125). 전투 중 공병에게 맡기는 지시는 모두 여기를 거친다. 거리는 가장 가까운 차지 칸까지다(I178)
func _idle_engineer(cell):
	var best = null
	var best_d := INF
	for u in units:
		if u.kind == "engineer" and u.job == null and not u.on_wall:
			var c := _spot(u, cell)
			var d: float = u.pos.distance_to(Vector2(c))
			if d < best_d and _reaches(u, c):
				best = u
				best_d = d
	return best

# 공병이 그 일을 하러 가는 칸(I178): 칸이면 그 칸, Block이면 차지 칸 가운데 공병에게 가장 가까운 칸이고 접은 대포는 새 칸(I74)이다.
# 성벽 위 대포 칸은 성곽과 구조물이 겹쳐서 칸이 아니라 Block으로 묻는다
func _spot(u: Unit, at) -> Vector2i:
	if at is Vector2i:
		return at
	return _site(at) if at.dest != null and at.razed >= 1.0 else Vector2i(nearest(at, u.pos).round())

# 전투 중 공병 지시(I125)를 맡을 공병이 없는 이유(I128): 칸(또는 Block, _spot)들 가운데 하나라도 맡을 공병이 있으면 "",
# 놀고 있는 공병이 하나도 없으면 "none", 있는데 어느 칸에도 닿지 못하면 "far". 칸이 비면(놓기 버튼) 놀고 있는 공병이 있는지만 본다
func engineer_gap(cells: Array) -> String:
	if not units.any(func(u): return u.kind == "engineer" and u.job == null):
		return "none"
	return "" if cells.is_empty() or cells.any(func(c): return _idle_engineer(c) != null) else "far"

# 지금 막힌 칸(닫힌 성문·성벽·구조물)을 지나지 않고 그 칸까지 걸어갈 수 있다(I125). 끝 칸은 일하는 자리라 막혀 있어도 된다
func _reaches(u: Unit, cell: Vector2i) -> bool:
	grid.wall_k = UNIT_WALL_K  # _send와 같은 유닛 경로
	return not grid.path(Vector2i(u.pos.round()), cell).slice(1, -1).any(func(c): return grid.block_at(c) != null)

# 공병에게 그 구조물 일을 맡기고 옆 칸(대각선 포함)까지 걸어가게 한다(I63)
func _send(u: Unit, s: Block) -> void:
	u.job = s
	u.rally_from = null
	u.prey = null
	u.after.clear()
	s.worker = u
	grid.wall_k = UNIT_WALL_K
	u.path = grid.path(Vector2i(u.pos.round()), _spot(u, s)).slice(1, -1)

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
	_vacate(s)
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
	var s: Block = u.job
	if u.pos.distance_to(Vector2(_spot(u, s))) > WORK_REACH:
		_send(u, s)
	elif s.mend > 0.0:
		if rubble.get(s.cell) != s:
			_mend(s, s.max_hp / (s.build_time if structures.get(s.cell) == s else REPAIR_TIME) * dt)
		elif not occupied_area(s):  # 잔해는 칸이 비어야 다시 세운다(I89)
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
			_vacate(t)
			_repath = true
		elif t is Unit and not t.is_hero and t in units:
			if t.job:  # 일하던 공병의 일은 그 상태로 남는다(I63)
				_release(t.job)
			units.erase(t)
		else:
			continue
		t.alive = false
		gold += refund(t)

# 판매로 돌려받는 골드: 낸 골드 × 남은 체력 비율, 1골드 미만은 버린다(S69, I56)
func refund(t) -> int:
	return floori(t.paid * t.hp / t.max_hp)

# 피해(S149): kind는 phys 물리 · magic 마법 · true 고정. src는 피해를 낸 영웅·용병·구조물(없으면 null), ignore는 양수 방어력을 무시하는 비율(S153).
# 적: 치명타 → 물리는 방어력, 마법은 마법 저항 → 받는 피해 증가. 고정 피해는 아무것도 받지 않는다.
# 아군 유닛: 불사면 받지 않고, 방어력과 받는 피해 감소를 받은 뒤 보호막이 먼저 받는다. 구조물·성곽: 방어력과 받는 피해 감소. 에너지 성벽은 부서지지 않는다(I142)
func damage(target, amount: float, kind := "phys", src = null, ignore := 0.0) -> void:
	if not target.alive or (target is Block and target.kind == "barrier"):
		return
	if _tracing != null:
		_tracing.hits.append(target)
	if target is Enemy:
		if kind != "true":
			if _crits(target, src):
				amount *= CRIT
			if kind == "phys":
				var a := armor_of(target)
				amount *= armor_mult(a * (1.0 - ignore) if a > 0.0 else a)
			else:
				amount *= 1.0 - _fx_sum(target, "mr")  # 마법 저항은 기본 0이고, 깎이면 음수라 더 받는다
			amount *= 1.0 + _fx_sum(target, "expose")
	elif target is Unit:
		if target.brace > 0.0:  # 반격의 태세는 줄이기 전 값을 센다(S151). 불사 중에 들어온 피해도 센다(I147)
			target.braced += amount
		if _fx_on(target, "invuln") != null:
			return
		amount = _absorb(target, amount * armor_mult(armor_of(target)) * (1.0 - _fx_cut(target, "dr")))
		if amount >= target.hp and _fx_on(target, "angel") != null:  # 수호 천사(S152): 쓰러지지 않고 불사
			var secs: float = target.fx.seraphina_e.angel
			target.fx.erase("seraphina_e")
			_fx(target, "seraphina_e_saved", {"invuln": true}, secs)
			target.hp = 1.0
			return
	else:
		amount *= armor_mult(armor_of(target)) * (1.0 - _fx_cut(target, "dr"))
	if target == base and amount > 0.0:
		tally.base_hit += 1  # 라운드 집계(I119)
	target.hp = maxf(target.hp - amount, 0.0)
	if target is Enemy and kind != "true":
		_share(target, amount, src)
	if target.hp > 0.0:
		return
	target.alive = false
	if target is Enemy or target is Unit:
		fallen.append({"who": target, "age": 0.0})
	if target == base:
		state = "lost"
		settled = [mission, commission].filter(func(n): return n != "").map(func(n): return [n, false])  # 진 라운드의 미션·의뢰는 모두 실패다(I131)
	elif target is Enemy:
		enemies.erase(target)
		var bonus := 0.0  # 크로노스 E 결계 안에서 처치되면 골드가 는다(S158). 겹쳐도 한 번, 반올림(I149)
		for z in zones:
			if z.src == "chronos_e" and target.pos.distance_to(z.pos) <= z.radius:
				bonus = maxf(bonus, z.bonus)
		_spare += roundi(target.reward * (1.0 + bonus)) * _stage.get("reward_scale", 1.0)  # 처치 보상 배율(I176). 1골드에 못 미치는 나머지는 쌓아 둔다
		gold += floori(_spare)
		_spare -= floori(_spare)
		_spread(target)
		target.fx.clear()  # 도발은 영웅을 가리킨다. 죽은 적이 영웅을 붙잡아 두지 않게
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
			_vacate(target)
			tally.structure_lost += 1  # 라운드 집계(I119)
			return
		_cut(castle, walls, target)
		tally.castle_lost += 1  # 라운드 집계(I119)
		_put(rubble, debris, target)  # 잔해로 남아 지나갈 수 있고, 복구하면 되살아난다(I88, I89). 성벽은 열 하나가 통째로다(S217)
		var area := area_of(target)
		for c in cells_in(area):  # 성벽이 부서지면 그 위 대포도 부서진다(I72)
			if footprint.has(c):
				damage(footprint[c], INF)
		# 그 칸들에 걸쳐 선(0.5칸 안) 유닛은 그 칸 땅으로 내려오고, 성벽 위로 그 칸을 지나려던 유닛은 멈춘다(I70)
		var cells := cells_in(area)
		for u in units:
			var here = null
			if u.on_wall:
				for c in cells:
					if u.pos.distance_to(Vector2(c)) <= 0.5:
						here = c
						break
			if here != null:
				u.on_wall = false
				u.pos = Vector2(here)
			if here != null or (u.path if u.on_wall else u.after).any(func(p): return area.has_point(p)):
				u.path.clear()
				u.after.clear()

# 영혼 사슬(S154): 묶인 적 하나가 받은 피해(줄인 뒤)의 비율을 같은 사슬의 다른 적이 고정 피해로 받는다. 나눠 받은 고정 피해는 다시 나뉘지 않는다
func _share(e: Enemy, amount: float, src) -> void:
	var link = _fx_on(e, "chain")
	if link == null:
		return
	var part: float = amount * e.fx.vesper_e.share
	for o in enemies.duplicate():
		if o != e and _fx_on(o, "chain") == link:
			damage(o, part, "true", src)

func _spawn_wave(dt: float) -> void:
	_spawn_timer -= dt
	if _queue.is_empty() or _spawn_timer > 0.0:
		return
	var next: Array = _queue.pop_front()
	spawn_enemy(next[0], next[2])
	var gap: float = _stage.get("spawn_gap", SPAWN_GAP)  # 시험 스테이지는 적 10배라 0.25초(I91)
	_spawn_timer = gap
	if _queue.size() % maxi(1, roundi(SPAWN_GAP / gap)) == 0:  # 성곽이 깎인 만큼 길이 바뀌었을 수 있다. 다시 구하는 것은 2.5초에 한 번꼴(S142)
		_forecast()

# 대상 칸(e.goal)까지 «걷는 거리 + 막힌 칸 비용»이 가장 싼 경로. 막힌 칸과 거점은 닿는 거리에서 친다(_move).
# 그래서 반격 대상이 성벽에 둘러싸여 있으면 비용이 가장 싼 성벽을 뚫고 간다(S6)
func _find_path(e: Enemy) -> void:
	if e.flying:  # 길을 찾지 않고 곧장 난다(I79)
		return
	grid.wall_k = e.wall_k
	grid.climb = e.climb * e.speed
	e.path = grid.path(Vector2i(e.pos.round()), e.goal)
	grid.climb = 0.0

# 출현 지점마다 기본 적이 지금 나오면 거점까지 걸을 길(S142). 장갑 적도 wall_k가 같아 같은 길이다.
# 3라운드부터는 그 출현 지점의 성문(S143)을 지나고, 그 성문이 잔해면 곧장 거점까지다
func _forecast() -> void:
	grid.wall_k = ENEMY_KINDS.basic.wall_k
	forecast = spawns.map(func(c):
		var g = _gate_of(c)
		if g == null or not castle.has(g):
			return grid.path(c, base.cell)
		return grid.path(c, g) + grid.path(g, base.cell).slice(1))

# 적이 지금 노리는 것(S4): ① 인식 범위 안이나 몸이 닿은 가장 가까운 유닛(영웅·용병) → ② 살아 있는 반격 대상 → ③④ 거점.
# 3라운드부터 땅 적은 ③ 앞에 출현 지점에서 가장 가까운 성문을 먼저 노린다. 그 칸에 들어서거나 잔해가 되면 거점이다(S143).
# 마을 안의 적에게는 인식 범위 안의 마을 구조물(집·생산 시설, S43)도 ①이다(I49). 들판의 구조물은 ①이 아니다(I7). 쏘지 않는 구조물은 attacker가 되지 않는다(_fire). 반격 대상이 부서지면 ②가 끝난다(I8)
func _target_of(e: Enemy):
	var taunt = _fx_on(e, "taunt")  # 도발(S151): 도발한 영웅만 노린다. 블록 수와 상관없다. 그 영웅이 쓰러지면 풀린다
	if taunt and taunt.alive:
		_engage(e, taunt)
		return taunt
	var best = null
	var best_d := INF
	for m in units:
		if not _free(m, e):  # 블록 자리가 찬 유닛은 노리지 않고 지나간다(S159)
			continue
		var d := e.pos.distance_to(m.pos)
		# 밀어낸 직후 거리는 반지름 합과 같아서 0.01 여유를 둔다(S13: 몸으로 막은 유닛은 인식 범위 밖이어도 친다)
		# 성벽 위 유닛은 몸으로 길을 막을 때만 친다(U13, S89, I70). 비행 적·기어오르는 적은 그 성벽 위 유닛도 노리고(I77), 비행 적은 몸에 막히지 않는다(S109)
		# 인식 범위 0은 아무것도 보지 않는다. 몸이 겹치는 비행 적이 거리 0에서 보게 되지 않게
		if d < best_d and ((d <= e.sight and e.sight > 0.0 and (not m.on_wall or e.flying or e.climb > 0.0)) or (not _flies(e) and d <= e.radius + m.radius + 0.01)):
			best = m
			best_d = d
	if village.has_point(Vector2i(e.pos.round())):
		for s in structures.values():
			var d := e.pos.distance_to(nearest(s, e.pos))  # 가장 가까운 차지 칸까지(I178)
			if d < best_d and d <= e.sight:
				best = s
				best_d = d
	_engage(e, best if best is Unit else null)
	if best:
		return best
	if e.attacker and e.attacker.alive:
		return e.attacker
	if e.via != null:
		if castle.has(e.via) and not area_of(castle[e.via]).has_point(Vector2i(e.pos.round())):  # 문루 칸에 들어서면 거점이다(S217)
			return castle[e.via]
		e.via = null
	return base

func _move(e: Enemy, dt: float) -> void:
	var sealed := _fx_on(e, "seal") != null  # 봉인(S155): 비행 적은 내려앉고 기어오르는 적은 오르지 못한다. 보스는 스킬을 쓰지 못한다(S194)
	var rage := raging(e)
	e.cooldown -= dt * (1.0 - _fx_cut(e, "lag")) * (1.0 + (e.skills.rage.haste if rage else 0.0))  # 공격 속도 감소(S158), 분노(S195)
	e.held -= dt
	var stunned := _fx_on(e, "stun") != null
	if e.cast and (stunned or sealed):  # 예고가 끊긴다. 기절이면 비틀거리고, 봉인이면 그냥 취소된다(S194)
		e.cd[e.cast.id] = e.skills[e.cast.id].cd
		e.cast = null
		if stunned:
			_fx(e, "stagger", {"expose": STAGGER_EXPOSE}, STAGGER)
	if stunned:  # 기절·빙결(S150): 움직이지도 치지도 않는다
		return
	if _skills(e, dt, sealed):  # 예고 동안은 움직이지도 치지도 않는다(S194)
		return
	if e.attack_gap - e.cooldown < POSE:  # 친 뒤 공격 자세 동안 제자리에 선다(S196)
		return
	var rooted := _fx_on(e, "root") != null  # 속박(S150): 움직이지 않지만 닿는 대상은 친다
	var speed: float = 0.0 if rooted else e.speed * (1.0 - _fx_cut(e, "slow")) * (1.0 + (e.skills.rage.stride if rage else 0.0))
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
	if e.flying:  # 막힌 칸을 넘어 대상으로 곧장 날아가 닿는 거리에서 친다(I79). 봉인되면 막힌 칸·몸에 막힌다(S155)
		var to: Vector2 = aim.pos if aim is Unit else nearest(aim, e.pos)  # 구조물은 가장 가까운 차지 칸(I178)
		if e.pos.distance_to(to) <= REACH:
			_attack(e, aim)
		elif sealed:
			_shove(e, (to - e.pos).limit_length(speed * dt), units)
		else:
			e.pos = e.pos.move_toward(to, speed * dt)
		return
	if rooted:  # 길 위 막힌 칸이 닿아 있으면 그것만 친다
		var near = null if e.path.is_empty() else (base if e.path[0] == base.cell else grid.block_at(e.path[0]))
		if near and not (e.climb > 0.0 and near.kind == "castle_wall") and e.pos.distance_to(Vector2(e.path[0])) <= REACH:
			_attack(e, near)
		return
	var left := speed * dt
	while left > 0.0 and not e.path.is_empty():
		var next: Vector2i = e.path[0]
		var target := Vector2(next)
		var d := e.pos.distance_to(target)
		var block = base if next == base.cell else grid.block_at(next)
		if block and e.climb > 0.0 and block.kind == "castle_wall":  # 성곽 성벽은 부수지 않고 기어올라 그 칸 위로 올라선다(S107, I76)
			if sealed:  # 봉인(S155): 오르지 못하고 그 자리에 선다
				return
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

# ── 보스 스킬(S194) ──

# 분노(S195): 체력이 정한 비율 이하인 보스. 봉인되면 꺼진다(S194). 화면이 붉게 그린다
func raging(e: Enemy) -> bool:
	return e.skills.has("rage") and e.hp <= e.skills.rage.below * e.max_hp and _fx_on(e, "seal") == null

# 대기를 줄이고, 예고 중이면 시간을 세어 다 되면 발동한다. 예고가 없으면 쓸 수 있는 스킬의 예고를 시작한다. 이번 스텝을 스킬에 썼으면 true
func _skills(e: Enemy, dt: float, sealed: bool) -> bool:
	for id in e.cd:
		e.cd[id] -= dt
	if e.cast:
		e.cast.left -= dt
		if e.cast.left <= 0.0:
			var id: String = e.cast.id
			e.cast = null
			e.cd[id] = e.skills[id].cd
			if id == "slam":
				_slam(e, e.skills.slam)
		return true
	var sk: Dictionary = e.skills.get("slam", {})
	if sealed or sk.is_empty() or e.cd.get("slam", 0.0) > 0.0 or _ground_near(e.pos, sk.radius).size() < sk.count:
		return false
	e.cast = {"id": "slam", "left": sk.windup}
	return true

# 성벽 위가 아닌 영웅·용병 가운데 at에서 r 안에 있는 것
func _ground_near(at: Vector2, r: float) -> Array:
	return units.filter(func(u): return not u.on_wall and u.pos.distance_to(at) <= r)

# 대지 강타(S195): 반경 안 땅 위 영웅·용병에게 물리 피해, 보스에게서 멀어지는 쪽으로 넉백(막힌 칸·몸에서 멈춘다), 둔화
func _slam(e: Enemy, sk: Dictionary) -> void:
	_trace(e, "slam", null, e.pos, sk.radius)
	for u in _ground_near(e.pos, sk.radius):
		damage(u, sk.damage, "phys", e)
		if u.alive:
			_shove(u, (u.pos - e.pos).normalized() * sk.knock, enemies)
			_fx(u, "slam", {"slow": sk.slow}, sk.slow_time)
	_tracing = null

# 블록 수(S159, I150): 유닛 m이 적 e를 붙잡고 있거나 블록 자리가 남았다. 붙잡을 수 있는 유닛만 e를 노리고 몸으로 막는다
func _free(m: Unit, e: Enemy) -> bool:
	return e.engaged == m or _holds.get(m, 0) < m.block

# 적 e를 유닛 m(없으면 null)이 붙잡게 한다. 블록 자리 수를 맞춘다
func _engage(e: Enemy, m) -> void:
	if e.engaged == m:
		return
	if e.engaged:
		_holds[e.engaged] = _holds.get(e.engaged, 1) - 1
	e.engaged = m
	if m:
		_holds[m] = _holds.get(m, 0) + 1

# 붙잡힌 적 수를 다시 센다(I150). 붙잡은 유닛이 쓰러졌거나 전장에 없으면 풀린다
func _count_holds() -> void:
	_holds.clear()
	for e in enemies:
		if e.engaged and not (e.engaged.alive and e.engaged in units):
			e.engaged = null
		if e.engaged:
			_holds[e.engaged] = _holds.get(e.engaged, 0) + 1

# 몸끼리 닿는가(S13, S159): 유닛과 적 사이는 그 유닛이 그 적을 붙잡을 수 있을 때만 막는다. 비행 적은 막지 않는다(S109). 아군은 에너지 성벽을 지나간다(I142)
func _touch(mover, body) -> bool:
	if body is Enemy and _flies(body):
		return false
	if mover is Enemy and body is Unit:
		return _free(body, mover)
	if mover is Unit and body is Enemy:
		return _free(mover, body)
	return true

# 같은 편(bodies)끼리 겹친 만큼 반씩 밀어낸다. 상대 편(others)과는 겹치지 않게 민다. 비행 적은 밀지도 밀리지도 않는다(I79).
# 경로는 그대로라 밀려난 쪽은 _move·_act가 다시 데려간다(I51)
# 1칸 버킷의 이웃 아홉 칸만 비교한다. 몸 반지름 합은 가장 큰 보스 둘이 0.9라 겹친 쌍은 늘 이웃 버킷이다. 차례는 전수 비교(i < j)와 같다
# ponytail: 버킷은 스텝 처음 자리로 나눈다. 한 스텝 안에서 0.1칸 넘게 밀려 새로 겹친 쌍은 다음 스텝에 민다
func _push_apart(bodies: Array, others: Array) -> void:
	var near := {}  # 버킷 칸 → 비행 적이 아닌 bodies 번호들
	var home := []
	for i in bodies.size():
		var k := Vector2i(bodies[i].pos.floor())
		home.append(k)
		if not bodies[i].get("flying"):
			if near.has(k):
				near[k].append(i)
			else:
				near[k] = [i]
	for i in bodies.size():
		var a = bodies[i]
		if a.get("flying"):
			continue
		var js := []
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				for j in near.get(home[i] + Vector2i(dx, dy), []):
					if j > i:
						js.append(j)
		js.sort()
		for j in js:
			var o = bodies[j]
			var gap: Vector2 = o.pos - a.pos
			var overlap: float = a.radius + o.radius - gap.length()
			if overlap > 0.0:
				var push := (gap.normalized() if gap != Vector2.ZERO else Vector2.RIGHT) * overlap / 2.0
				_shove(a, -push, others)
				_shove(o, push, others)

# 쏘는 구조물은 사거리 안에서 가장 가까운 적을 쏜다(S28, I29). 피해·반격·범위 피해·축복은 투사체가 닿을 때다(_land, S178).
# 마법 타워는 마법 피해다(S110, S149). 공격 속도·공격력·사거리는 영웅 효과를 받는다(_haste·_might·_reach, S150)
func _fire(dt: float) -> void:
	for s in structures.values():
		if s.range <= 0.0 or not s.complete or s.razed >= 1.0:  # 미완성 타워(I18)·접은 대포(I74)는 쏘지 않는다
			continue
		s.cooldown -= dt * (1.0 + _haste(s))
		if s.cooldown > 0.0:
			continue
		var best = _nearest_enemy(Vector2(s.cell), _reach(s))
		if best:
			s.cooldown = s.fire_gap
			s.target = best
			_shoot(s, best, s.damage * _might(s), "magic" if s.pierce else "phys")

# 원거리 기본 공격의 투사체를 낸다(S178, I174). 유닛은 친 뒤 CONTACT초에 그때 선 자리에서, 구조물은 바로 그 칸에서 출발한다.
# 피해량·종류·방어 무시·축복은 지금 정해 담는다. 축복은 한 공격에 한 번이라 갈래 화살(S153)에는 싣지 않는다
func _shoot(src, e: Enemy, hurt: float, kind: String, ignore := 0.0, blessed := true) -> void:
	var m := Missile.new()
	m.src = src
	m.target = e
	m.look = MISSILES.get(src.kind, "bolt")
	m.speed = SPEED[m.look]
	m.wait = CONTACT if src is Unit else 0.0
	m.from = _where(src)
	m.pos = m.from
	m.at = e.pos
	m.hurt = hurt
	m.kind = kind
	m.ignore = ignore
	m.splash = src.splash if src is Block else 0.0
	var b = _fx_on(src, "bless") if blessed else null
	if b != null:
		m.bless = b
		m.bless_r = src.fx.seraphina_r.splash
	missiles.append(m)

# 투사체를 날린다(S178, I174). 출발 전에 쏜 유닛이 쓰러지면 나가지 않는다. 대상을 따라가고, 대상이 쓰러지면 화살·구슬은 사라지고
# 대포알은 마지막 자리로 간다. 닿으면 _land. 쏜 쪽이 날아가는 동안 쓰러지거나 팔려도 닿는다
func _fly(dt: float) -> void:
	var flying := []
	for m in missiles:
		var left := dt
		if m.wait > 0.0:
			m.wait -= dt
			if m.wait > 0.0:
				flying.append(m)
				continue
			if not m.src.alive:
				continue
			m.from = _where(m.src)
			m.pos = m.from
			left = -m.wait
		if m.target.alive:
			m.at = m.target.pos
		elif m.look != "ball":
			continue
		var to: Vector2 = m.at - m.pos
		if to.length() > m.speed * left:
			m.pos += to.normalized() * m.speed * left
			flying.append(m)
		else:
			m.pos = m.at
			_land(m)
	missiles = flying

# 투사체가 닿았다(S178, I174). 화살·구슬은 대상에게, 대포알은 떨어진 자리 둘레 splash칸 안의 적 모두에게 같은 피해를 준다(S90).
# 쏜 구조물이 서 있으면 맞은 적은 그 구조물에 반격한다(S5, I73): 반격 대상이 있으면 그 대상이 COUNTER_HOLD초 동안 쏘지 않았을 때만 바꾼다.
# 같은 step이면 먼저 쏜 투사체가 먼저 닿는다(S140). 축복이 실렸으면 닿은 자리 둘레에 마법 피해를 더한다(S152)
func _land(m: Missile) -> void:
	var s = m.src
	var stands: bool = s is Block and s.alive and structures.get(s.cell) == s
	for e in enemies.duplicate():
		if e == m.target or (m.splash > 0.0 and e.pos.distance_to(m.at) <= m.splash):
			if stands and (e.attacker == s or e.held <= 0.0 or not (e.attacker and e.attacker.alive)):
				e.attacker = s
				e.held = COUNTER_HOLD
			damage(e, m.hurt, m.kind, s, m.ignore)
	if m.bless > 0.0:
		_blessing(s, m.at, m.bless, m.bless_r)
	landed.append(m)

# 유닛은 명령받은 경로를 걷고(S14), 사거리 안의 가장 가까운 적을 친다(S15). 걷는 동안은 명령을 따른다: 순수 이동은 치지 않고,
# 공격 이동은 사거리에 든 적 앞에 서서 친다(S35, I35, S196). 대상 공격은 그 적만 친다. 서 있으면 영웅·용병 모두 인식 범위 안의 적을 쫓는다(I36, S141).
# 홀드가 켜진 용병은 서 있는 동안 기준 지점 반경 안의 적만 노리고, 그 반경 밖으로 쫓아가지 않는다(S36)
func _act(u: Unit, dt: float) -> void:
	u.cooldown -= dt * (1.0 + _haste(u))
	if u.is_hero:
		_hero_tick(u, dt)
	if u.path.is_empty() and not u.after.is_empty():  # 오르내리는 칸에 닿았다(I44, I69)
		u.on_wall = not u.on_wall
		u.pos = Vector2(u.after[0])
		u.path = u.after.slice(1)
		u.after.clear()
	# 걷는 동안엔 반경을 보지 않는다. 홀드 중 이동 지시를 받으면 도착한 곳이 새 기준이다(I37)
	var zone := u.hold_radius if u.hold and u.path.is_empty() else INF
	var top = walls.get(Vector2i(u.pos.round()))
	var wall_only: bool = u.on_wall and u.range < WALL_RANGE and not (top and top.open)  # 성벽 위 근접 유닛은 열린 성문 위에서만 들판의 적을 치고(S88, S89), 성벽 위의 적은 친다(I78)
	var foe = _hunt(u, wall_only) if u.prey else _nearest_enemy(u.pos, _reach(u), u.anchor, zone, wall_only)
	var walking := not u.path.is_empty()
	if walking and u.move_mode == "move":  # 순수 이동·대상에게 걸어가는 동안은 치지 않는다(S14, S196)
		foe = null
	elif walking and foe:  # 공격 이동: 멈춰서 친다(S35, I35)
		walking = false
	var left: float = u.speed * dt * ((1.0 + _aura("stride", u.pos)) if u.is_hero else 1.0) * (1.0 - _fx_cut(u, "slow"))  # 크로노스 오라: 영웅이 더 빨리 걷는다(S158). 둔화(I168)
	if u.attack_gap - u.cooldown < (CONTACT if u.is_hero and walking else (HERO_POSE if u.is_hero else POSE)):  # 친 뒤 공격 자세 동안 제자리에 선다(S196)
		left = 0.0
	if walking:
		while left > 0.0 and not u.path.is_empty():
			var to := Vector2(u.path[0]) - u.pos
			if u.on_wall:  # 성벽 위는 성곽 칸끼리 이어져 있어 막힘 없이 걷는다(I69)
				u.pos += to.limit_length(left)
			else:
				_shove(u, to.limit_length(left), enemies)
			left -= to.length()  # 적에게 막혀 못 갔어도 줄인다
			var d := u.pos.distance_to(Vector2(u.path[0]))
			# 마지막 칸은 다른 유닛과 몸이 닿은 채 0.5칸 안에 들어도 도착이다. 같은 칸으로 보낸 무리가 서로 밀며 끝없이 걷지 않게(I51).
			# 길의 칸(목적지 포함)에 적이 서 있으면 그 적 몸에 닿을 때 그 칸에 닿은 것으로 친다(S14). 그래야 막은 몸을 돌아 다음 칸으로 간다
			var crowded := u.path.size() == 1 and d <= 0.5 and units.any(func(o): return o != u and o.pos.distance_to(u.pos) < u.radius + o.radius + 0.01)
			var taken := d <= 1.1 and enemies.any(func(e): return not _flies(e) and e.pos.distance_to(Vector2(u.path[0])) <= 0.5 and e.pos.distance_to(u.pos) < u.radius + e.radius + 0.01)
			if d < 0.01 or crowded or taken:
				u.path.remove_at(0)
				if u.path.is_empty():
					u.anchor = u.pos
					u.rally_from = null
	elif not foe and not u.on_wall:  # 성벽 위 유닛은 쫓아 내려가지 않는다(I70)
		# ponytail: 적에게 곧장 다가간다. 벽 너머 적에게는 벽을 따라 미끄러질 뿐이다. 막히는 일이 보이면 경로로
		var prey = u.prey if u.prey else _nearest_enemy(u.pos, u.sight, u.anchor, zone)  # 길 끝에서도 대상(S35)이 사거리 밖이면 곧장 다가간다
		if prey:
			var p: Vector2 = u.pos + (prey.pos - u.pos).limit_length(left)
			if u.hold:
				p = u.anchor + (p - u.anchor).limit_length(u.hold_radius)
			_shove(u, p - u.pos, enemies)
	if foe and u.cooldown <= 0.0:
		u.cooldown = u.attack_gap
		u.target = foe
		_strike(u, foe)
	if u.is_hero and u.passive.get("id") == "fortress":
		_fortify(u, dt)
	if u.job and u.path.is_empty():
		_work(u, dt)

# 영웅 칸의 시간(S136, S146): 전투 단계에만 재사용 대기가 줄고(크로노스 R은 빠르게) 마나가 찬다(이그니스 오라는 더).
# 반격의 태세가 끝나면 터뜨리고(S151), 걸어가서 쓸 스킬(S147)과 자동 시전(S158)을 본다
func _hero_tick(h: Unit, dt: float) -> void:
	if state != "battle":
		return
	for slot in SLOTS:
		h.cd[slot] -= dt * (1.0 + _fx_sum(h, "cdr"))
	h.mana = minf(h.mana + (h.mana_regen + _aura("mana", h.pos)) * dt, h.max_mana)
	if h.brace > 0.0:
		h.brace -= dt
		if h.brace <= 0.0:
			_burst(h)
	if h.order:
		_follow_order(h)
	_autocast(h)

# 기본 공격 한 방(S15). 실비아(I148): 같은 적을 이어 치면 중첩이 쌓이고 다 차면 방어력 일부를 무시한다, W가 켜져 있으면 둘레 적에게도 들어간다(S153).
# 아이아스: 요새화 중이면 확률로 기절시킨다(S151). 축복이 걸렸으면 맞은 곳에 마법 피해를 더한다(S152).
# 원거리(사거리 RANGED칸 초과)는 맞을 적마다 투사체를 쏘고, 피해·축복은 닿을 때다(S178, I174). 중첩은 쏜 때 센다(I148)
func _strike(u: Unit, foe: Enemy) -> void:
	var hurt := u.damage * _might(u)
	var ignore := 0.0
	var hit := [foe]
	if u.passive.get("id") == "weak_point":
		u.stacks = mini(u.stacks + 1, u.passive.stacks) if foe == u.mark else 0
		u.mark = foe
		if u.stacks >= u.passive.stacks:
			ignore = u.passive.ignore
	if u.toggle:
		if u.mana >= u.w.mana:
			u.mana -= u.w.mana
			var reach := _reach(u)
			var more := enemies.filter(func(e): return e != foe and e.pos.distance_to(u.pos) <= reach)
			more.sort_custom(func(a, b): return a.pos.distance_to(foe.pos) < b.pos.distance_to(foe.pos))
			hit += more.slice(0, u.w.extra)
		else:
			u.toggle = false
	if u.range > RANGED:
		for e in hit:
			_shoot(u, e, hurt, "phys", ignore, e == foe)
		return
	var at: Vector2 = foe.pos
	for e in hit:
		damage(e, hurt, "phys", u, ignore)
	if u.fort and foe.alive and _luck.randf() < u.passive.stun_odds:
		_fx(foe, "aias_p_stun", {"stun": true}, u.passive.stun)
	_bless(u, at)

# 아이아스 패시브 요새화(S151, I147): 이동 지시 없이 still초가 지나면 요새화. 받는 피해 감소, 블록 수 +3. 이동 지시를 받으면 풀린다.
# 적을 쫓거나(S141) 밀려서 움직인 것은 이동 지시가 아니다(기획서 원문). 걸어갈 길(path·after)은 이동 지시로만 생긴다
func _fortify(h: Unit, dt: float) -> void:
	if not (h.path.is_empty() and h.after.is_empty()):
		h.still = 0.0
	else:
		h.still += dt
	h.fort = h.still >= h.passive.still
	h.block = HERO_KINDS[h.kind].block + (h.passive.block if h.fort else 0)  # 블록 수 +3(S159)
	if h.fort:
		_fx(h, "aias_p", {"dr": h.passive.dr}, STAY)
	else:  # 풀리면 바로 끝난다(장판의 «안에 있는 동안» 효과와 달리 남지 않는다)
		h.fx.erase("aias_p")

# 대상 공격(S35): 대상이 죽거나 사라졌으면 그 자리에 서고 null. 칠 수 있는 거리면 서서 그 적을 돌려준다.
# 아니면 null이고, 대상이 길을 구한 칸에서 1칸 넘게 옮겼으면 그 칸으로 길을 다시 구한다
func _hunt(u: Unit, wall_only: bool):
	var e = u.prey
	if not (e.alive and e in enemies):
		u.prey = null
		_halt(u)
		return null
	if e.pos.distance_to(u.pos) <= _reach(u) and (e.on_wall or not wall_only):
		u.path.clear()
		u.after.clear()
		return e
	var c := Vector2i(e.pos.round())
	if maxi(absi(c.x - u.chase_to.x), absi(c.y - u.chase_to.y)) > 1:
		_unit_paths()
		u.chase_to = c
		_route(u, c)
	return null

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
			if gap.length() < e.radius + m.radius and _touch(e, m):  # 비행 적은 길을 막지 않는다(S109). 봉인된 비행 적은 막는다(S155). 블록 자리가 없으면 지나간다(S159)
				var n := gap.normalized() if gap != Vector2.ZERO else Vector2.LEFT
				p = m.pos + n * (e.radius + m.radius)
				if e is Unit and p.distance_to(e.pos) < v.length() * 0.25:  # 아군은 정면으로 막은 몸의 둘레를 따라 돌아간다(S14). 적은 막힌 채로 둔다(위 [의도])
					p = m.pos + n.rotated(v.length() / (e.radius + m.radius) * (1.0 if n.cross(v) >= 0.0 else -1.0)) * (e.radius + m.radius)
		var c := Vector2i(p.round())
		var blk = grid.block_at(c)
		if blk and blk.kind == "barrier" and e is Unit:  # 아군은 에너지 성벽을 지나간다(I142)
			blk = null
		if grid.is_in_boundsv(c) and (not blk or (e.on_wall and _climbable(c))) and c != base.cell:  # 성벽 위의 적은 성벽 칸을 걷는다(I76)
			e.pos = p
			return

# 기어오를 수 있는 칸: 성곽의 성벽 칸. 성문은 오르지 않는다(I76)
func _climbable(c: Vector2i) -> bool:
	return walls.has(c) and walls[c].kind == "castle_wall"

func _attack(e: Enemy, target) -> void:
	if e.cooldown <= 0.0:
		e.cooldown = e.attack_gap
		e.target = target
		damage(target, e.damage * (1.0 - _fx_cut(e, "weaken")))  # 공격력 감소(S154)
