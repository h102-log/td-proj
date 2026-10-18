extends SceneTree
# 밸런스 자동 플레이(WBS 3.4·5.5용 도구). 평가가 아니다 — 동결된 tests/eval과 상관없다.
# 시험 스테이지(main.gd stage())의 6라운드 도전을 봇이 영입 창부터 끝까지 headless로 플레이하고,
# 웨이브마다 긴장감 지표를 «RESULT {json}» 한 줄로 낸다.
#
#   godot --headless --path . -s res://tools/balance/autoplay.gd -- '<설정 json>'
#
# 설정 키(모두 생략 가능):
#   seed        영입 목록 씨앗(정수)
#   dt          시뮬 한 걸음(초, 기본 0.05)
#   bot         봇 전략 손잡이(아래 BOT 기본값을 덮는다)
#   over        수치 오버라이드. data/ 파일을 바꾸지 않고 이 실행에서만 바꾼다
#     enemies/mercs/structures/heroes: {종류: {키: 값}}  · hire/levels: {키: 값}
#     stage: {gold, base_hp, wall_hp, gate_hp, rounds: [[{종류: 수}, ...웨이브], ...라운드]}
#     wave_mult: [라운드마다 적 수 배율] — rounds가 없을 때 시험 스테이지 웨이브에 곱해 내림한다
#     spawn_gap: 웨이브 안에서 적이 나오는 간격(초, battle.gd SPAWN_GAP). 숫자 하나거나 라운드마다 배열
#     cost_step: {종류: 단계} — 그 종류의 건설비가 지금 서 있는 같은 종류 하나마다 원래 값 × 단계씩 오른다(1차 관찰 A①)
#     fly_no_counter: 참이면 비행 적은 자기를 쏜 구조물에 반격하지 않는다(S5에서 비행 적을 뺀다, 1차 관찰 A③)
#     hp_mult: [라운드마다 적 체력 배율] — data의 라운드 배율(S144)에 더 곱한다. 처치 보상은 그대로다(1차 관찰 A⑤. 적 수를 늘리면 보상도 늘어 수입이 따라 오른다)
#     gate_split: 라운드 번호. 그 라운드부터 땅 적은 출현 지점에서 가장 가까운 성문을 먼저 노리고, 그 성문을 지나거나 부수면 거점으로 간다(1차 관찰 A④).
#                 battle.gd가 GATE_SPLIT_ROUND부터 같은 규칙(S143)을 걸어서, 그보다 이른 라운드를 재 볼 때만 뜻이 있다. 봇은 둘 가운데 이른 라운드부터 쪽문을 지킨다(sides)
# ponytail: 봇은 «무난한 플레이어» 하나를 흉내 낼 뿐이다. 사람의 손을 대신하지 않는다. 판정은 사람이 한다
# 사람과 다른 점: 준비 단계를 0초로 넘긴다(준비 단계 Q·오라 회복을 쓰지 않는다). 영웅을 마을로 부르지 않고 성문을 여닫지 않고
# (pingpong을 켜면 쪽문 핑퐁만 한다) 리롤하지 않는다. 의뢰는 보상만 보고 수락하고 조건에 맞춰 운영을 바꾸지 않는다. 잔해 위 유닛은 한 칸 물려 세운다(사람이 준비 단계에 걸어서 비키는 손을 대신한다, 복구 거부 I89를 피한다)

const BOT := {
	"name": "balanced",
	"plan": "balanced",     # 준비 단계 쇼핑 목록(PLANS)
	"micro": true,          # 영웅이 가까운 적을 쫓아가 친다. 끄면 출전 칸에 서 있다
	"skills": true,         # 영웅 Q·W·E·R을 상황 보고 쓴다
	"recruit": true,        # 전투 중 병영에서 병사를 사서 정문 앞으로 보낸다
	"battle_repair": true,  # 전투 중 공병이 정문을 고친다
	"prep_repair": true,    # 준비 단계에 성곽·구조물·잔해를 고친다. 거점은 base_repair_below 아래일 때만
	"base_repair_below": 0.5,
	"reserve": 0,           # 준비 단계에 남겨 둘 골드
	"hire_reserve": 20,     # 영입 뒤 남겨 둘 골드(최소)
	"hire_keep": 0.5,       # 영입 한 번마다 그때 골드의 이 비율은 방어에 남긴다
	"lead": 6.0,            # 영웅이 정문 앞 기준점에서 쫓아가는 최대 거리(칸)
	"hire_first_grade": 3,  # 도전을 시작할 때(1라운드 전) 영입하는 최고 등급
	"hire_first_count": 2,  # 도전을 시작할 때 영입하는 최대 인원
	"rally": [20, 10],      # 전투 중 산 병사를 보낼 칸
	"fill": false,          # 쇼핑 목록을 다 사면 들판·성벽에 타워·마법 타워·대포를 계속 짓는다(골드가 놀지 않게)
	"village_heroes": 0,    # 출전 영웅 가운데 뒤에서 이만큼을 준비 단계마다 마을 안 거점 옆(station)에 세운다
	"village_from": 3,      # 이 라운드부터
	"station": [[20, 6], [18, 5]],
	"vlead": 9.0,           # 마을 영웅이 쫓는 거리(거점에서, 칸)
	"pingpong": false,      # 쪽문 핑퐁(3장 자체 점검 §5의 사람 전략): 쪽문 하나만 열고, 땅 적이 그 문 pp_dist칸 안에 오면 반대 쪽문으로 바꾼다
	"pp_dist": 4.0,
	"pp_from": 1,           # 이 라운드부터 핑퐁한다. 그 전에는 성문을 닫아 둔다
	"pp_slow": 0.0,        # 0보다 크면 웨이브의 적이 다 나온 뒤 남은 땅 적이 모두 이 속도 이하(장갑·보스)일 때만 핑퐁하고, 그 전엔 성문을 닫아 둔다
	"gate_cd": 0.0,        # 봇이 스스로 지키는 성문 쿨타임(초, 전투 단계만). 쿨타임 규칙의 값을 고르려고 흉내 낸다
	"gate_cd_all": false,   # 참이면 성문 하나를 여닫을 때 셋이 함께 묶인다. 거짓이면 그 성문만
	"accept": true,         # 라운드 사이에 보상이 가장 큰 의뢰를 수락한다(실패해도 벌칙이 없다, I54)
	"sides": false,         # 쪽문 둘도 정문처럼 지킨다: 쇼핑 목록의 쏘는 구조물·정문 업그레이드를 쪽문에도 하나씩 더하고(_plan), fill을 세 성문에 번갈아 깐다
}

const GATE := Vector2i(20, 9)
const SIDES := [Vector2i(0, 9), Vector2i(39, 9)]  # 쪽문 둘
const FRONT := Vector2i(20, 12)

# 준비 단계 쇼핑 목록: 앞에서부터 사고, 골드가 모자란 항목에서 멈춘다(우선순위 저축)
# 항목: [종류, 인자...]
#   ["build", kind, x, y] · ["merc", kind, 유지할 수, 놓을 x, y] · ["wallmerc", kind, 유지할 수] · ["village"]
#   ["upgrade", x, y, 목표 단계] · ["house", 채 수]
const PLANS := {
	# 타워만: 정문 앞 타워·마법 타워·성벽 위 대포
	"turtle": [
		["build", "tower", 18, 12], ["build", "tower", 22, 12], ["build", "cannon", 19, 9],
		["build", "magic", 17, 11], ["build", "magic", 23, 11], ["build", "tower", 18, 14], ["build", "tower", 22, 14],
		["build", "cannon", 21, 9], ["upgrade", 20, 9, 2], ["build", "tower", 16, 12], ["build", "tower", 24, 12],
		["build", "cannon", 17, 9], ["build", "cannon", 23, 9], ["upgrade", 20, 9, 3], ["build", "magic", 16, 14],
		["build", "magic", 24, 14], ["build", "tower", 14, 12], ["build", "tower", 26, 12],
	],
	# 세 겹을 고루: 병영·병사 몸막기, 타워, 사격장·성벽 위 궁수, 집 몇 채, 공병 하나
	"balanced": [
		["build", "barracks", 17, 7], ["merc", "soldier", 2, 20, 10], ["build", "tower", 18, 12], ["build", "tower", 22, 12],
		["house", 2], ["build", "workshop", 24, 7], ["merc", "engineer", 1, 22, 8], ["village"], ["build", "archery", 15, 7],
		["wallmerc", "archer", 2], ["build", "magic", 17, 11], ["build", "magic", 23, 11], ["merc", "soldier", 3, 20, 10],
		["build", "cannon", 19, 9], ["house", 4], ["upgrade", 20, 9, 2], ["wallmerc", "archer", 4], ["build", "cannon", 21, 9],
		["build", "tower", 18, 14], ["build", "tower", 22, 14], ["merc", "soldier", 4, 20, 10], ["upgrade", 20, 9, 3],
		["house", 6], ["build", "cannon", 17, 9], ["build", "cannon", 23, 9], ["build", "magic", 16, 13], ["build", "magic", 24, 13],
	],
	# 숙련: 영웅 하나로 시작해 1라운드는 타워·대포로 버티고, 병영(정문 안쪽 2선)·사격장(성벽 궁수)·공병·집을 차례로 더한다
	"smart": [
		["build", "tower", 18, 12], ["build", "tower", 22, 12], ["build", "cannon", 19, 9], ["build", "magic", 17, 11],
		["build", "barracks", 17, 7], ["merc", "soldier", 2, 20, 8], ["village"], ["build", "archery", 15, 7],
		["wallmerc", "archer", 2], ["build", "workshop", 24, 7], ["merc", "engineer", 1, 22, 7], ["house", 2],
		["build", "magic", 23, 11], ["build", "cannon", 21, 9], ["upgrade", 20, 9, 2], ["wallmerc", "archer", 4],
		["build", "tower", 18, 14], ["build", "tower", 22, 14], ["house", 4], ["merc", "soldier", 3, 20, 8],
		["upgrade", 20, 9, 3], ["build", "cannon", 17, 9], ["build", "cannon", 23, 9], ["build", "magic", 16, 13],
		["build", "magic", 24, 13], ["house", 6], ["merc", "soldier", 4, 20, 8], ["build", "tower", 16, 12], ["build", "tower", 24, 12],
	],
	# 집 6채를 먼저 짓고 방어를 늦게 갖춘다
	"greedy": [
		["house", 6], ["build", "tower", 18, 12], ["build", "tower", 22, 12], ["build", "barracks", 17, 7],
		["merc", "soldier", 2, 20, 10], ["build", "magic", 17, 11], ["build", "magic", 23, 11], ["build", "cannon", 19, 9],
		["village"], ["build", "archery", 15, 7], ["wallmerc", "archer", 3], ["build", "cannon", 21, 9], ["upgrade", 20, 9, 2],
		["merc", "soldier", 4, 20, 10], ["build", "tower", 18, 14], ["build", "tower", 22, 14], ["upgrade", 20, 9, 3],
		["build", "cannon", 17, 9], ["build", "cannon", 23, 9], ["build", "magic", 16, 13], ["build", "magic", 24, 13],
	],
}
const HOUSE_CELLS := [Vector2i(3, 2), Vector2i(5, 2), Vector2i(7, 2), Vector2i(33, 2), Vector2i(35, 2), Vector2i(37, 2)]
const WALL_POSTS := [Vector2i(18, 9), Vector2i(22, 9), Vector2i(17, 9), Vector2i(23, 9), Vector2i(16, 9), Vector2i(24, 9)]
# fill: 성문마다 그 길(성문 x)과 출전 칸을 비우고 성문에서 가까운 칸부터. 성벽 칸은 대포다. 성문이 여럿이면 번갈아 깐다
static func _fill_cells(gates := [GATE]) -> Array:
	var per := []
	for g in gates:
		var out := []
		for dx in [5, 6]:
			for x in [g.x - dx, g.x + dx]:
				if x > 0 and x < 39:
					out.append(["build", "cannon", x, 9])
		var n := 0
		for y in [11, 13, 15, 12, 14, 16]:
			for dx in [3, 4, 5, 6, 7, 8]:
				for x in [g.x - dx, g.x + dx]:
					if x >= 0 and x <= 39:
						out.append(["build", "magic" if n % 3 == 2 else "tower", x, y])
						n += 1
		per.append(out)
	var mixed := []
	for i in per.map(func(o): return o.size()).max():
		for o in per:
			if i < o.size():
				mixed.append(o[i])
	return mixed

var b
var bot := {}
var dt := 0.05
var log := []        # 웨이브마다 지표
var hires := []
var cur := {}        # 지금 웨이브 지표
var _think := 0.0
var _spawned := 0    # 이번 웨이브에 나온 적 수(kills 지표). 람다는 지역 변수를 값으로 잡아 멤버로 센다
var _vill := []      # 마을에 세운 영웅
var _t := 0.0        # 이번 웨이브의 전투 시간
var _gate_at := {}   # 성문 칸 → 이번 웨이브에 마지막으로 여닫은 시각(봇의 쿨타임 흉내). "all"은 셋 중 아무거나
var _split := 0      # over.gate_split: 적이 성문 셋으로 갈라지는 첫 라운드(0이면 없음)

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var cfg: Dictionary = JSON.parse_string(args[0]) if args.size() > 0 and args[0] != "" else {}
	bot = BOT.duplicate()
	bot.merge(cfg.get("bot", {}), true)
	dt = cfg.get("dt", 0.05)
	var over: Dictionary = cfg.get("over", {})
	_split = int(over.get("gate_split", 0))
	var stage: Dictionary = load("res://src/main.gd").stage()
	stage.seed = int(cfg.get("seed", 1))
	_override_stage(stage, over)
	b = _battle_class(over).new(stage)
	_override_kinds(over)
	b.restart()  # 오버라이드한 영입 확률로 목록을 다시 뽑는다
	b.begin_hiring()
	b.enemy_spawned.connect(func(_e): _spawned += 1)
	var out := _play()
	print("RESULT ", JSON.stringify(out))
	quit(0)

func _override_stage(stage: Dictionary, over: Dictionary) -> void:
	var s: Dictionary = over.get("stage", {})
	for k in ["gold", "base_hp"]:
		if s.has(k):
			stage[k] = s[k]
	if s.has("wall_hp"):
		stage.castle.wall_hp = s.wall_hp
	if s.has("gate_hp"):
		stage.castle.gate_hp = s.gate_hp
	var rounds = null
	if s.has("rounds"):
		rounds = s.rounds
	elif over.has("wave_mult"):
		var first: Array = load("res://data/waves/test_stage.tres").waves
		rounds = []
		for m in over.wave_mult:
			rounds.append(first.map(func(w):
				var d := {}
				for k in w:
					d[k] = floori(w[k] * m)
				return d))
	if rounds != null:
		stage.rounds = rounds.map(func(r): return r.map(func(w): return w.keys().map(func(k): return {"kind": k, "count": int(w[k])})))
		stage.waves = stage.rounds[0]

func _override_kinds(over: Dictionary) -> void:
	for pair in [["enemies", b.ENEMY_KINDS], ["mercs", b.MERC_KINDS], ["structures", b.STRUCTURE_KINDS], ["heroes", b.HERO_KINDS]]:
		var o: Dictionary = over.get(pair[0], {})
		for kind in o:
			for key in o[kind]:
				pair[1][kind][key] = o[kind][key]
	for pair in [["hire", b.HIRE], ["levels", b.LEVELS]]:
		var o: Dictionary = over.get(pair[0], {})
		for key in o:
			pair[1].set(key, o[key])

# ---------------------------------------------------------------- 판 진행

func _play() -> Dictionary:
	var guard := 0
	while b.state not in ["won", "lost"] and guard < 200:
		guard += 1
		if b.hiring_open():
			_hire()
			b.next_round()
		elif b.state == "prep":
			var g0: int = b.gold
			var spent := _prep()
			_begin(g0, spent)
			b.start_battle()
			if not _fight():
				break
	var heroes = b.roster.map(func(h): return "%s:Lv%d" % [h.kind, h.level])
	return {
		"result": b.state, "round": b.round_index + 1, "wave": b.wave_index + 1, "gold": b.gold,
		"heroes": heroes, "hires": hires, "waves": log, "bot": bot.name,
	}

func _begin(g0: int, spent: int) -> void:
	cur = {
		"r": b.round_index + 1, "w": b.wave_index + 1, "gold_in": g0, "spent_prep": spent, "unspent": b.gold,
		"base_start": snappedf(b.base.hp / b.base.max_hp, 0.01),
		"spent_battle": 0, "base_min": 1.0, "gate_min": 1.0, "castle_lost": 0, "struct_lost": 0,
		"merc_lost": 0, "hero_down": 0, "leak": 0, "idle": 0.0, "secs": 0.0, "peak": 0, "kills": 0,
		"inside_peak": 0, "base_hp_end": 1.0, "gold_out": 0,
		"def": _defense(), "lv": b.heroes.map(func(h): return h.level), "zones": 0, "busy": 0.0, "toggles": 0,
	}

# 지금 방어 구성: 종류별 수(구조물·용병)
func _defense() -> Dictionary:
	var d := {}
	for s in b.structures.values():
		d[s.kind] = d.get(s.kind, 0) + 1
	for u in b.units:
		if not u.is_hero:
			d[u.kind] = d.get(u.kind, 0) + 1
	return d

# 전투 한 웨이브를 끝까지 돈다. 너무 오래 끌면(적이 끼었다) 멈추고 거짓
func _fight() -> bool:
	var castle0: int = b.castle.size()
	var structs0: int = b.structures.size()
	var mercs0 = b.units.filter(func(u): return not u.is_hero).size()
	var downs := 0
	var seen := {}
	var mercs_seen := {}
	var zones_hit := [false, false, false]
	_spawned = 0
	_gate_at.clear()
	var gold_track: int = b.gold
	var t := 0.0
	while b.state == "battle":
		_t = t
		var heroes_alive: int = b.heroes.filter(func(h): return h.alive).size()
		_think -= dt
		for u in b.units:
			if not u.is_hero:
				mercs_seen[u] = true
		if _think <= 0.0:
			_think = 0.25
			var g: int = b.gold
			_battle_actions()
			cur.spent_battle += maxi(g - b.gold, 0)
		b.step(dt)
		t += dt
		if bot.get("trace", false) and fmod(t, 2.0) < dt:
			_trace(t)
		downs += maxi(heroes_alive - b.heroes.filter(func(h): return h.alive).size(), 0)
		cur.base_min = minf(cur.base_min, b.base.hp / b.base.max_hp)
		var gate = b.castle.get(GATE)
		cur.gate_min = minf(cur.gate_min, (gate.hp / gate.max_hp) if gate else 0.0)
		cur.peak = maxi(cur.peak, b.enemies.size())
		var inside := 0
		var engaged := false
		for e in b.enemies:
			var c := Vector2i(e.pos.round())
			if c.y <= 8:
				inside += 1
				if not seen.has(e):
					seen[e] = true
			if c.y <= 16:
				engaged = true
		cur.inside_peak = maxi(cur.inside_peak, inside)
		var z := _zones()
		zones_hit[0] = zones_hit[0] or z[0]
		zones_hit[1] = zones_hit[1] or z[1]
		zones_hit[2] = zones_hit[2] or z[2]
		if int(z[0]) + int(z[1]) + int(z[2]) >= 2:
			cur.busy += dt
		if not engaged:
			cur.idle += dt
		if t > 900.0:
			cur.stall = true
			break
	cur.secs = snappedf(t, 0.1)
	cur.idle = snappedf(cur.idle, 0.1)
	cur.busy = snappedf(cur.busy, 0.1)
	cur.zones = int(zones_hit[0]) + int(zones_hit[1]) + int(zones_hit[2])
	cur.lv_end = b.heroes.map(func(h): return h.level)
	cur.leak = seen.size()
	cur.hero_down = downs
	cur.castle_lost = b.rubble.size()
	cur.struct_lost = maxi(structs0 - b.structures.size(), 0)
	cur.merc_alive = b.units.filter(func(u): return not u.is_hero).size()
	cur.merc_lost = mercs_seen.keys().filter(func(u): return not u.alive).size()
	cur.kills = _spawned - b.enemies.size()
	cur.base_hp_end = snappedf(b.base.hp / b.base.max_hp, 0.01)
	cur.base_min = snappedf(cur.base_min, 0.01)
	cur.gate_min = snappedf(cur.gate_min, 0.01)
	cur.gold_out = b.gold
	cur.state = b.state
	if b.state in ["cleared", "won"]:  # 라운드를 이겼다: 미션·의뢰 판정 [이름, 달성, 보상](I120)
		cur.quests = b.settled.map(func(s): return [s[0], s[1], b.QUEST_KINDS[s[0]].reward])
	log.append(cur)
	return not cur.has("stall")

# ---------------------------------------------------------------- 영입 창

func _hire() -> void:
	var hire = b.HIRE
	# 출전 인원이 빌 때까지, 남겨 둘 골드를 지키며 살 수 있는 가장 높은 등급을 산다
	var first: bool = b.state == "hiring"
	for _i in 3:
		if b.lineup.size() >= hire.lineup or b.roster.size() >= hire.cap:
			break
		if first and b.roster.size() >= bot.hire_first_count:
			break
		var best := -1
		var best_grade := 0
		for i in b.offers.size():
			var k: String = b.offers[i]
			if k == "":
				continue
			var g: int = b.HERO_KINDS[k].grade
			# 도전 시작 전에는 최소 예비만 남긴다. 시작 골드 150일 때 절반을 남기면 3성(100골드)을 아무도 못 샀다(2026-10-19). 시작 220 패널도 이 규칙으로 쟀다
			var keep: float = bot.hire_reserve if first else maxf(bot.hire_reserve, b.gold * bot.hire_keep)
			if first and g > bot.hire_first_grade:
				continue
			if b.gold - hire.cost[g - 1] >= keep and g > best_grade:
				best = i
				best_grade = g
		if best < 0:
			break
		var kind: String = b.offers[best]
		if b.hire(best):
			hires.append("R%d:%s" % [b.round_index + 1 + (1 if b.state == "cleared" else 0), kind])
	if bot.accept and b.state == "cleared" and not b.commission_offers.is_empty():
		var best := 0
		for i in b.commission_offers.size():
			if b.QUEST_KINDS[b.commission_offers[i]].reward > b.QUEST_KINDS[b.commission_offers[best]].reward:
				best = i
		b.accept(best)
	# 출전 중인 영웅보다 높은 등급이 목록에 있고 넉넉하면 산 뒤 경험치를 옮겨 바꿔 낸다(S62의 의도)
	if b.state == "cleared" and b.roster.size() < hire.cap:
		for i in b.offers.size():
			var k: String = b.offers[i]
			if k == "":
				continue
			var g: int = b.HERO_KINDS[k].grade
			var weak = null
			for h in b.lineup:
				if h.grade < g and (weak == null or h.grade < weak.grade):
					weak = h
			if weak and b.gold - hire.cost[g - 1] >= bot.hire_reserve + 60:
				var h = b.hire(i)
				if h:
					hires.append("R%d:%s(교체)" % [b.round_index + 2, k])
					b.transfer(weak, h)
					b.set_lineup(weak, false)
					b.set_lineup(h, true)
				break

# ---------------------------------------------------------------- 준비 단계

func _prep() -> int:
	var g0: int = b.gold
	if bot.prep_repair:
		for k in b.castle.values() + b.structures.values():
			if b.can_repair(k):
				b.repair(k)
		for k in b.rubble.values():
			for u in b.units:  # 잔해 칸에 선 유닛이 있으면 복구가 거부된다(I89). 마을 쪽으로 한 칸 물린다
				if Vector2i(u.pos.round()) == k.cell:
					u.pos = Vector2(k.cell + Vector2i.UP)
			b.restore(k)
		if b.base.hp < b.base.max_hp * bot.base_repair_below:
			b.repair(b.base)
	_station()
	if bot.pingpong:  # 준비 단계 여닫기는 쿨타임이 없다. 정문은 닫고 쪽문은 하나만 연다(pp_slow면 모두 닫는다)
		b.set_gate(b.castle[GATE], false)
		var gs := SIDES.map(func(c): return b.castle.get(c)).filter(func(g): return g != null)
		if bot.pp_slow > 0.0 or b.round_index + 1 < bot.pp_from:
			for g in gs:
				b.set_gate(g, false)
		elif gs.size() == 2 and gs[0].open == gs[1].open:
			b.set_gate(gs[0], true)
			b.set_gate(gs[1], false)
	var done := true
	for item in _plan():
		if not _buy(item):
			done = false
			break
	if done and bot.fill:
		for item in _fill_cells([GATE] + (SIDES if _sides() else [])):
			if not _buy(item):
				break
	return g0 - b.gold

# 적이 성문 셋으로 갈라지는 라운드(S143, gate_split이면 둘 가운데 이른 쪽)부터 무난한 플레이어는 쪽문도 지킨다
func _sides() -> bool:
	var from: int = mini(_split, b.GATE_SPLIT_ROUND) if _split > 0 else b.GATE_SPLIT_ROUND
	return bot.sides or b.round_index + 1 >= from

# 쇼핑 목록. sides면 쏘는 구조물마다 쪽문 둘에도 정문에서와 같은 x 거리(쪽문 안쪽)에 하나씩, 정문 업그레이드는 쪽문에도 더한다.
# 정문 양옆 한 쌍은 쪽문에서 같은 칸이 되어 하나만 선다(_buy가 건너뛴다)
func _plan() -> Array:
	if not _sides():
		return PLANS[bot.plan]
	var out := []
	for item in PLANS[bot.plan]:
		out.append(item)
		if item[0] == "build" and item[1] in ["tower", "magic", "cannon"]:
			var dx: int = absi(item[2] - GATE.x)
			for s in SIDES:
				out.append(["build", item[1], s.x + (dx if s.x < GATE.x else -dx), item[3]])
		elif item[0] == "upgrade" and Vector2i(item[1], item[2]) == GATE:
			for s in SIDES:
				out.append(["upgrade", s.x, s.y, item[3]])
	return out

# 항목 하나를 채운다. 이미 채웠으면 참, 골드가 모자라 못 채웠으면 거짓
func _buy(item: Array) -> bool:
	var spare: int = b.gold - bot.reserve
	match item[0]:
		"build":
			var cell := Vector2i(item[2], item[3])
			var s = b.structure_at(cell)
			if s and s.kind == item[1]:
				return true
			if s or b.rubble.has(cell):
				return true  # 다른 것이 섰거나 잔해다. 건너뛴다
			if spare < (b.price(item[1]) if b.has_method("price") else b.STRUCTURE_KINDS[item[1]].cost):  # cost_step이면 누진 값
				return false
			if b.STRUCTURE_KINDS[item[1]].village_level > b.village_level:
				return true
			b.build(item[1], cell)
			return true
		"house":
			var have: int = b.structures.values().filter(func(s): return s.tax > 0).size()
			for c in HOUSE_CELLS:
				if have >= item[1]:
					return true
				if b.structure_at(c):
					continue
				if spare < b.STRUCTURE_KINDS.house.cost:
					return false
				if b.build("house", c):
					have += 1
					spare = b.gold - bot.reserve
			return true
		"village":
			if b.village_level > b.VILLAGE_UP.size():
				return true
			if spare < b.VILLAGE_UP[b.village_level - 1]:
				return false
			b.raise_village()
			return true
		"upgrade":
			var k = b.castle.get(Vector2i(item[1], item[2]))
			if k == null or k.level >= item[3]:
				return true
			if spare < b.upgrade_cost(k):
				return false
			b.upgrade(k)
			return true
		"merc":
			if not b.can_buy(item[1]):
				return true
			var have := _count(item[1])
			while have < item[2]:
				if spare < b.MERC_KINDS[item[1]].cost or b._mercs() >= b.merc_cap:
					return spare >= b.MERC_KINDS[item[1]].cost
				var m = b.place_merc(item[1], _free_near(Vector2i(item[3], item[4])))
				if m == null:
					return true
				have += 1
				spare = b.gold - bot.reserve
			return true
		"wallmerc":
			if not b.can_buy(item[1]):
				return true
			var have := _count(item[1])
			while have < item[2]:
				if spare < b.MERC_KINDS[item[1]].cost or b._mercs() >= b.merc_cap:
					return spare >= b.MERC_KINDS[item[1]].cost
				var m = b.place_merc(item[1], _free_near(Vector2i(GATE.x, GATE.y - 1)))
				if m == null:
					return true
				var post = WALL_POSTS[have % WALL_POSTS.size()]
				b.order_move([m], post)
				have += 1
				spare = b.gold - bot.reserve
			return true
	return true

func _count(kind: String) -> int:
	return b.units.filter(func(u): return u.kind == kind).size()

func _free_near(c: Vector2i) -> Vector2i:
	for r in 4:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var p := c + Vector2i(dx, dy)
				if b.grid.is_in_boundsv(p) and not b.grid.block_at(p) and p != b.base.cell and not b.occupied(p) and p not in b._stage.hero_cells:
					return p
	return c

# ---------------------------------------------------------------- 전투 중 손

func _battle_actions() -> void:
	if bot.pingpong:
		_pingpong()
	for h in b.heroes:
		if not h.alive:
			continue
		if bot.skills:
			_skills(h)
		if h in _vill:
			_move_village_hero(h)
		elif bot.micro:
			_move_hero(h)
	if bot.recruit:
		var want := 0
		for item in PLANS[bot.plan]:
			if item[0] == "merc" and item[1] == "soldier":
				want = maxi(want, item[2])
		if _count("soldier") < want:
			for s in b.structures.values():
				if s.complete and "soldier" in s.produces and b.gold >= b.MERC_KINDS.soldier.cost + bot.reserve:
					s.rally = Vector2i(bot.rally[0], bot.rally[1])
					b.recruit(s)
					break
	if bot.battle_repair:
		var gate = b.castle.get(GATE)
		if gate and gate.hp < gate.max_hp * 0.6 and b.can_repair(gate) and b.gold >= b.repair_cost(gate):
			b.repair(gate)

func _near(pos: Vector2, r: float) -> Array:
	return b.enemies.filter(func(e): return e.pos.distance_to(pos) <= r)

# 영웅 칸마다 단순한 판단으로 쓴다(S145~S158). 지점·방향 칸은 시전 사거리 안에서 적이 가장 몰린 곳에, 회복 칸은 가장 깎인 아군에게
func _skills(h) -> void:
	var r: float = b.CAST_RANGE
	for slot in b.SLOTS:
		if not b.can_cast(h, slot) and not (slot == "w" and h.toggle):
			continue
		var sk: Dictionary = h.get(slot)
		match sk.id:
			"split_shot":  # 토글: 적이 셋 넘게 사거리 안이고 마나가 넉넉하면 켜고, 아니면 끈다
				var want: bool = _near(h.pos, h.range).size() >= 3 and h.mana > 60.0
				if want != h.toggle:
					b.cast(h, slot)
			"overcharge":  # 자동 시전에 맡긴다
				if not h.auto:
					b.toggle_auto(h, slot)
			"holy_beam", "guardian":
				var weak = _weakest(h, r)
				if weak and weak.hp < weak.max_hp * (0.6 if sk.id == "holy_beam" else 0.35):
					b.cast(h, slot, weak)
			"rewind":
				for o in b.heroes:
					if o != h and o.alive and o.mana < o.max_mana * 0.4 and o.pos.distance_to(h.pos) <= r:
						b.cast(h, slot, o)
						break
			"miracle":
				if b.units.filter(func(u): return u.hp < u.max_hp * 0.5).size() >= 3:
					b.cast(h, slot)
			"sanctum":
				var weak = _weakest(h, r)
				if weak and weak.hp < weak.max_hp * 0.6:
					b.cast(h, slot, weak.pos)
			"soul_chain":
				var big = null
				for e in _near(h.pos, r):
					if big == null or e.hp > big.hp:
						big = e
				if big and _near(big.pos, sk.radius).size() >= 3:
					b.cast(h, slot, big)
			_:
				if sk.aim == "self":
					if _near(h.pos, sk.get("radius", 3.0)).size() >= 2:
						b.cast(h, slot)
				else:
					var spot = _cluster(h.pos, r, sk.get("radius", 2.0))
					if spot:
						b.cast(h, slot, spot)

# 시전 사거리 안에서 반경 안에 적이 가장 많이 몰린 적의 자리. 둘 이상이거나 보스면 돌려주고, 아니면 null
func _cluster(from: Vector2, reach: float, radius: float):
	var best = null
	var best_n := 0
	for e in _near(from, reach):
		var n := _near(e.pos, radius).size()
		if n > best_n:
			best = e
			best_n = n
	return best.pos if best and (best_n >= 2 or best.kind == "boss") else null

# 시전 사거리 안에서 체력 비율이 가장 낮은 아군
func _weakest(h, reach: float):
	var low = null
	for u in b.units:
		if u.alive and u.pos.distance_to(h.pos) <= reach and (low == null or u.hp / u.max_hp < low.hp / low.max_hp):
			low = u
	return low

# 영웅은 정문 앞 기준점에서 lead칸 안의 가장 가까운 적에게 다가가고, 없으면 제자리로 돌아온다.
# 체력이 30% 아래면 기준점 뒤로 물러난다
func _move_hero(h) -> void:
	if h.hp < h.max_hp * 0.3:
		if h.pos.distance_to(Vector2(h.home) + Vector2(0, -1)) > 1.0:
			b.order_move([h], h.home + Vector2i(0, -1))
		return
	var best = null
	var best_d := INF
	for e in b.enemies:
		if e.on_wall or Vector2i(e.pos.round()).y <= 9:
			continue  # 성벽 위·마을 안 적은 들판에서 닿지 않는다
		var d: float = e.pos.distance_to(Vector2(FRONT))
		if d <= bot.lead and d < best_d:
			best = e
			best_d = d
	if best:
		if h.pos.distance_to(best.pos) > h.range * 0.8 and (h.path.is_empty() or h.path[-1].distance_to(Vector2i(best.pos.round())) > 1.5):
			b.order_move([h], Vector2i(best.pos.round()))
	elif h.path.is_empty() and h.pos.distance_to(Vector2(h.home)) > 1.5:
		b.order_move([h], h.home)

func _trace(t: float) -> void:
	var gate = b.castle.get(GATE)
	var kinds := {}
	for e in b.enemies:
		var c := Vector2i(e.pos.round())
		var zone := "마을" if c.y <= 8 else ("성벽" if e.on_wall else ("앞" if c.y <= 14 else "들"))
		var k: String = e.kind + "@" + zone
		kinds[k] = kinds.get(k, 0) + 1
	var us = b.units.map(func(u): return "%s%d(%d,%d)" % [u.kind.left(3), int(u.hp), roundi(u.pos.x), roundi(u.pos.y)])
	var ss = b.structures.values().filter(func(s): return s.range > 0.0).map(func(s): return "%s%d" % [s.kind.left(3), int(s.hp)])
	print("R%dW%d t=%5.1f 거점 %3d 성문 %s 골드 %d 적 %s 유닛 %s 탑 %s" % [b.round_index + 1, b.wave_index + 1, t, int(b.base.hp), str(int(gate.hp)) if gate else "잔해", b.gold, kinds, us, ss])

# 위협 지점 세 곳에 적이 와 있나: [정문 앞(들판, 정문 6칸 안), 측면 성벽(성벽 위이거나 정문에서 먼 성벽 앞), 마을 안]
func _zones() -> Array:
	var z := [false, false, false]
	for e in b.enemies:
		var c := Vector2i(e.pos.round())
		if c.y <= 8 and not e.on_wall:
			z[2] = true
		elif e.on_wall or (c.y <= 11 and absi(c.x - GATE.x) > 6):
			z[1] = true
		elif c.y <= 15 and absi(c.x - GATE.x) <= 6:
			z[0] = true
	return z

# 상수(SPAWN_GAP)와 규칙은 판 객체에서 바꿀 수 없다. 오버라이드가 있으면 그 함수만 바꾼 하위 클래스로 판을 만든다
func _battle_class(over: Dictionary):
	var code := ""
	if over.has("spawn_gap"):
		var gaps = over.spawn_gap if over.spawn_gap is Array else [over.spawn_gap]
		code += """
var gaps := %s
func _spawn_wave(dt: float) -> void:
	_spawn_timer -= dt
	if _queue.is_empty() or _spawn_timer > 0.0:
		return
	spawn_enemy(_queue.pop_front(), spawns[_spawned %% spawns.size()])
	_spawned += 1
	_spawn_timer = gaps[mini(round_index, gaps.size() - 1)]
	_forecast()
""" % [JSON.stringify(gaps)]
	if over.has("cost_step"):
		code += """
var cost_step := %s
func price(kind: String) -> int:
	var n := structures.values().filter(func(s): return s.kind == kind).size()
	return roundi(STRUCTURE_KINDS[kind].cost * (1.0 + cost_step.get(kind, 0.0) * n))
func build(kind: String, cell: Vector2i, overrides := {}):
	return super(kind, cell, overrides.merged({"cost": price(kind)}, true))
""" % [JSON.stringify(over.cost_step)]
	if over.get("fly_no_counter", false):  # 반격 대상은 _fire에서만 정해진다(S5, S140). 비행 적의 것은 쏜 뒤 바로 지운다
		code += """
func _fire(dt: float) -> void:
	super(dt)
	for e in enemies:
		if e.flying:
			e.attacker = null
"""
	if over.has("hp_mult"):
		code += """
var hp_mult := %s
func spawn_enemy(kind: String, cell: Vector2i, overrides := {}):
	var m: float = hp_mult[mini(round_index, hp_mult.size() - 1)]
	return super(kind, cell, overrides.merged({"hp": ENEMY_KINDS[kind].hp * m}, true))
""" % [JSON.stringify(over.hp_mult)]
	if int(over.get("gate_split", 0)) > 0:  # 처음 거점을 노리는 순간(출현 직후) 가장 가까운 성문을 정해 둔다. 그 성문이 잔해가 되거나 성곽 줄에 닿으면 거점이다
		code += """
var split_from := %d
func _target_of(e: Enemy):
	var t = super(e)
	if t != base or e.flying or round_index + 1 < split_from:
		return t
	if not e.has_meta("via"):
		var near: Vector2i = _stage.castle.gates[0]
		for c in _stage.castle.gates:
			if e.pos.distance_to(Vector2(c)) < e.pos.distance_to(Vector2(near)):
				near = c
		e.set_meta("via", near)
	var via: Vector2i = e.get_meta("via")
	if not castle.has(via) or roundi(e.pos.y) <= via.y:
		return base
	return castle[via]
""" % [int(over.gate_split)]
	if code == "":
		return load("res://src/sim/battle.gd")
	var src := GDScript.new()
	src.source_code = 'extends "res://src/sim/battle.gd"\n' + code
	src.reload()
	return src

# 마을 영웅(사람이 준비 단계에 성문을 열고 영웅을 마을로 걸어 들이는 손을 대신해 자리에 세운다).
# 3장 자체 점검 검증에서 «영웅 1명을 거점 옆에 두면 3~6라운드 거점 피해가 거의 사라진다»가 나와 패널에 넣었다
func _station() -> void:
	_vill.clear()
	if bot.village_heroes <= 0 or b.round_index + 1 < bot.village_from:
		return
	var alive_h = b.heroes.filter(func(h): return h.alive)
	for i in mini(bot.village_heroes, alive_h.size()):
		var h = alive_h[alive_h.size() - 1 - i]
		var st: Array = bot.station[i % bot.station.size()]
		h.pos = Vector2(st[0], st[1])
		h.on_wall = false
		h.path.clear()
		h.after.clear()
		_vill.append(h)

# 마을 영웅: 거점에서 vlead칸 안의 마을 안·성벽 위 적 가운데 가장 가까운 적을 쫓고, 없으면 자리로 돌아온다
func _move_village_hero(h) -> void:
	var st: Array = bot.station[_vill.find(h) % bot.station.size()]
	var home := Vector2i(st[0], st[1])
	if h.hp < h.max_hp * 0.3:
		if h.pos.distance_to(Vector2(home)) > 1.0:
			b.order_move([h], home)
		return
	var best = null
	var best_d := INF
	for e in b.enemies:
		if Vector2i(e.pos.round()).y > 8 and not e.on_wall:
			continue
		if e.pos.distance_to(Vector2(b.base.cell)) <= bot.vlead and e.pos.distance_to(h.pos) < best_d:
			best = e
			best_d = e.pos.distance_to(h.pos)
	if best:
		if h.pos.distance_to(best.pos) > h.range * 0.8 and (h.path.is_empty() or h.path[-1].distance_to(Vector2i(best.pos.round())) > 1.5):
			var c := Vector2i(best.pos.round())
			c.y = mini(c.y, 8)
			b.order_move([h], c)
	elif h.path.is_empty() and h.pos.distance_to(Vector2(home)) > 1.5:
		b.order_move([h], home)

# 쪽문 핑퐁: 땅 적이 열린 쪽문 pp_dist칸 안(들판)에 오면 반대 쪽문을 열고 이 문을 닫는다. 쿨타임에 묶여 있으면 기다린다.
# gate_cd_all이면 한 번에 하나만 여닫을 수 있어서, 열린 문을 먼저 닫고(그동안 적은 닫힌 문을 친다) 묶임이 풀리면 반대 문을 연다
func _pingpong() -> void:
	var gs := SIDES.map(func(c): return b.castle.get(c))
	if null in gs or b.round_index + 1 < bot.pp_from:
		return  # 쪽문이 부서져 잔해다
	if bot.pp_slow > 0.0 and not (b._queue.is_empty() and b.enemies.all(func(e): return e.flying or (e.climb <= 0.0 and e.speed <= bot.pp_slow))):
		return
	var opened := gs.filter(func(g): return g.open)
	if opened.is_empty():
		_toggle(gs[0] if _crowd(gs[0].cell) <= _crowd(gs[1].cell) else gs[1], true)  # 적이 덜 붙은 쪽을 연다
		return
	var a = opened[0] if opened.size() == 1 or _crowd(opened[0].cell) >= _crowd(opened[1].cell) else opened[1]
	if _crowd(a.cell) == 0:
		return
	var o = gs[1 - gs.find(a)]
	if bot.gate_cd_all:
		_toggle(a, false)
	elif o.open or (_gate_free(a) and _gate_free(o)):
		if o.open or _toggle(o, true):
			_toggle(a, false)

# 성문 칸에서 pp_dist칸 안의 들판에 있는 땅 적 수
func _crowd(cell: Vector2i) -> int:
	return b.enemies.filter(func(e): return not e.flying and not e.on_wall and e.pos.y >= 9.5 and e.pos.distance_to(Vector2(cell)) <= bot.pp_dist).size()

func _gate_free(g) -> bool:
	return _t - _gate_at.get("all" if bot.gate_cd_all else g.cell, -INF) >= bot.gate_cd

# 묶여 있으면 거짓. 성문 칸에 적·유닛이 있어 닫기가 거부돼도 거짓이고 묶지 않는다(I67)
func _toggle(g, open: bool) -> bool:
	if not _gate_free(g):
		return false
	b.set_gate(g, open)
	if g.open != open:
		return false
	_gate_at["all" if bot.gate_cd_all else g.cell] = _t
	cur.toggles += 1
	return true
