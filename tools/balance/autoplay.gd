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
# ponytail: 봇은 «무난한 플레이어» 하나를 흉내 낼 뿐이다. 사람의 손을 대신하지 않는다. 판정은 사람이 한다

const BOT := {
	"name": "balanced",
	"plan": "balanced",     # 준비 단계 쇼핑 목록(PLANS)
	"micro": true,          # 영웅이 가까운 적을 쫓아가 친다. 끄면 출전 칸에 서 있다
	"skills": true,         # 영웅 Q·W를 상황 보고 쓴다
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
}

const GATE := Vector2i(20, 9)
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
# fill: 정문(x=20) 길과 출전 칸을 비우고 정문에서 가까운 칸부터. 성벽 칸은 대포다
static func _fill_cells() -> Array:
	var out := []
	for c in [Vector2i(15, 9), Vector2i(25, 9), Vector2i(14, 9), Vector2i(26, 9)]:
		out.append(["build", "cannon", c.x, c.y])
	var n := 0
	for y in [11, 13, 15, 12, 14, 16]:
		for dx in [3, 4, 5, 6, 7, 8]:
			for x in [20 - dx, 20 + dx]:
				out.append(["build", "magic" if n % 3 == 2 else "tower", x, y])
				n += 1
	return out

var b
var bot := {}
var dt := 0.05
var log := []        # 웨이브마다 지표
var hires := []
var cur := {}        # 지금 웨이브 지표
var _think := 0.0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var cfg: Dictionary = JSON.parse_string(args[0]) if args.size() > 0 and args[0] != "" else {}
	bot = BOT.duplicate()
	bot.merge(cfg.get("bot", {}), true)
	dt = cfg.get("dt", 0.05)
	var over: Dictionary = cfg.get("over", {})
	var stage: Dictionary = load("res://src/main.gd").stage()
	stage.seed = int(cfg.get("seed", 1))
	_override_stage(stage, over)
	b = _battle_class(over).new(stage)
	_override_kinds(over)
	b.restart()  # 오버라이드한 영입 확률로 목록을 다시 뽑는다
	b.begin_hiring()
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
		"spent_battle": 0, "base_min": 1.0, "gate_min": 1.0, "castle_lost": 0, "struct_lost": 0,
		"merc_lost": 0, "hero_down": 0, "leak": 0, "idle": 0.0, "secs": 0.0, "peak": 0, "kills": 0,
		"inside_peak": 0, "base_hp_end": 1.0, "gold_out": 0,
		"def": _defense(), "lv": b.heroes.map(func(h): return h.level), "zones": 0, "busy": 0.0,
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
	var spawned := 0
	b.enemy_spawned.connect(func(_e): spawned += 1)
	var gold_track: int = b.gold
	var t := 0.0
	while b.state == "battle":
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
	cur.kills = spawned - b.enemies.size()
	cur.base_hp_end = snappedf(b.base.hp / b.base.max_hp, 0.01)
	cur.base_min = snappedf(cur.base_min, 0.01)
	cur.gate_min = snappedf(cur.gate_min, 0.01)
	cur.gold_out = b.gold
	cur.state = b.state
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
			var keep: float = maxf(bot.hire_reserve, b.gold * bot.hire_keep)
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
			if bot.get("trace", false):
				print("복구 시도 %s 결과 %s 골드 %d 비용 %d 칸점유 %s worker %s" % [k.cell, not b.rubble.has(k.cell), b.gold, b.repair_cost(k), b._occupied(k.cell), k.worker])
		if b.base.hp < b.base.max_hp * bot.base_repair_below:
			b.repair(b.base)
	var done := true
	for item in PLANS[bot.plan]:
		if not _buy(item):
			done = false
			break
	if done and bot.fill:
		for item in _fill_cells():
			if not _buy(item):
				break
	return g0 - b.gold

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
			if spare < b.STRUCTURE_KINDS[item[1]].cost:
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
				if b.grid.is_in_boundsv(p) and not b.grid.block_at(p) and p != b.base.cell and not b._occupied(p) and p not in b._stage.hero_cells:
					return p
	return c

# ---------------------------------------------------------------- 전투 중 손

func _battle_actions() -> void:
	for h in b.heroes:
		if not h.alive:
			continue
		if bot.skills:
			_skills(h)
		if bot.micro:
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

func _skills(h) -> void:
	if h.skill_ready():
		var foes := _near(h.pos, h.skill_radius)
		var fire := false
		if h.skill_damage > 0.0 or h.skill_stun > 0.0:
			fire = foes.size() >= 2 or foes.any(func(e): return e.kind == "boss")
		if h.skill_heal > 0.0:
			fire = b.units.any(func(u): return u.pos.distance_to(h.pos) <= h.skill_radius and u.hp < u.max_hp * 0.6)
		if h.skill_mend > 0.0:
			fire = b._fortified(h.pos, h.skill_radius).any(func(s): return s.hp < s.max_hp * 0.7)
		if fire:
			b.use_skill(h)
	if h.buff_ready() and h.level >= b.LEVELS.buff_level:
		var foes := _near(h.pos, h.buff_radius + 1.0)
		var mercs: int = b.units.filter(func(u): return not u.is_hero and u.pos.distance_to(h.pos) <= h.buff_radius).size()
		var fire := false
		if h.buff_mult > 1.0 or h.buff_guard > 0.0:
			fire = mercs >= 2 and foes.size() >= 2
		if h.buff_expose > 0.0 or h.buff_slow > 0.0:
			fire = _near(h.pos, h.buff_radius).size() >= 3
		if h.buff_ward > 0.0:
			fire = foes.size() >= 2 and not b._fortified(h.pos, h.buff_radius).is_empty()
		if fire:
			b.use_buff(h)

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

# SPAWN_GAP은 상수라 판 객체에서 바꿀 수 없다. 오버라이드가 있으면 _spawn_wave만 바꾼 하위 클래스로 판을 만든다
func _battle_class(over: Dictionary):
	if not over.has("spawn_gap"):
		return load("res://src/sim/battle.gd")
	var gaps = over.spawn_gap if over.spawn_gap is Array else [over.spawn_gap]
	var src := GDScript.new()
	src.source_code = """extends "res://src/sim/battle.gd"
var gaps := %s
func _spawn_wave(dt: float) -> void:
	_spawn_timer -= dt
	if _queue.is_empty() or _spawn_timer > 0.0:
		return
	spawn_enemy(_queue.pop_front(), spawns[_spawned %% spawns.size()])
	_spawned += 1
	_spawn_timer = gaps[mini(round_index, gaps.size() - 1)]
""" % [JSON.stringify(gaps)]
	src.reload()
	return src
