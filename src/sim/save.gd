extends RefCounted
# 진행 중인 도전 하나의 저장(S65, S181, I156, I157). 판(Battle)을 사전으로 떠서 user://의 파일 하나에 쓴다.
# 전투 단계가 아닐 때만 뜬다(S181). 그때는 적·장판·효과가 비어 있어(battle.gd의 _clear_effects) 유닛·구조물이 가리키는 것은
# 공병 일과 집결 중인 시설뿐이다. 그래서 유닛·구조물은 스크립트 변수를 모두 담고, 객체를 가리키는 칸(SKIP)은 빼되 그 둘은 칸으로 담아 다시 잇는다

const Battle := preload("res://src/sim/battle.gd")
const VERSION := 7  # 저장 형식 판. 다르면 읽지 않는다(I157). 3: 사방 성곽·맵 60×93(S203, I179). 4: 집의 가족(S221). 5: 주민의 원래 직업(S222). 6: 주민 체력·대피·신뢰(S225~S229). 7: 숙련·성장·다 큰 자녀(S231~S233, 주민 사전 xp·grow·grown)
# 판에서 담는 칸. 맵·라운드·마을 칸은 같은 스테이지로 새 판을 만들면 같다
const KEYS := ["state", "round_index", "wave_index", "gold", "village_level", "offers", "quests", "mission", "commission", "commission_offers", "settled", "tally", "_chains",
	"trust", "calm", "evac_round", "folk_clock"]  # 주민의 체력·가는 길·일과 위상과 집의 죽은 식구 수는 구조물 folk·lost에 담긴다(I183 ⑩)

# 유닛·구조물에서 담지 않는 칸: 읽기만 하는 present와, 다른 객체를 가리키는 칸(지난 공격 대상·공병 일·스킬 지시·실비아 표식·나온 생산 시설).
# 전투 단계가 아니면 공격 대상·공병 일·나온 생산 시설 말고는 비어 있다(_clear_effects). 공격 대상은 화면이 그리는 지난 타격이다.
# 공병 일(준비 단계 실시간, S181 2026-10-25 변경)과 나온 생산 시설은 _fields가 칸으로 담는다
const SKIP := ["present", "target", "worker", "job", "order", "mark", "rally_from"]

static var path := ""  # 저장 파일. 비어 있으면 쓰지 않는다. 진입 장면(menu.gd)이 정하고, 평가는 평가용 파일로 바꾼다

static func snapshot(b) -> Dictionary:
	var d := {"version": VERSION, "rng": b._rng.state, "luck": b._luck.state, "kin": b._kin.state, "spare": b._spare, "bag": b.bag.duplicate(), "forged": b.forged.duplicate()}
	for k in KEYS:
		d[k] = _copy(b.get(k))
	d.base = _fields(b.base)
	for k in ["castle", "rubble", "structures"]:
		d[k] = b.get(k).values().map(func(o): return _fields(o))
	var people: Array = b.roster.duplicate()  # 영웅: 보유 영웅과, 내보냈지만 다음 라운드까지 전장에 남은 영웅(I105)
	for h in b.heroes:
		if h not in people:
			people.append(h)
	d.heroes = people.map(func(h): return _fields(h))
	d.roster = b.roster.map(func(h): return people.find(h))
	d.lineup = b.lineup.map(func(h): return people.find(h))
	d.deployed = b.heroes.map(func(h): return people.find(h))
	d.units = b.units.map(func(u): return people.find(u) if u.is_hero else _fields(u))  # 순서가 행동 순서라 그대로 둔다
	return d

# 같은 스테이지로 새로 만든 판 b를 저장한 때로 되돌린다. 컬렉션은 비우고 다시 채운다(grid와 화면이 같은 객체를 쥐고 있다)
static func apply(b, d: Dictionary) -> void:
	for k in KEYS:
		b.set(k, _copy(d[k]))
	b.waves = b.rounds[b.round_index]
	b._rng.state = d.rng
	b._luck.state = d.luck
	b._kin.state = d.kin
	b._spare = d.get("spare", 0.0)  # 쌓인 처치 보상 나머지(I176). 이 칸이 생기기 전 저장은 0
	b.bag = d.get("bag", {}).duplicate()  # 전용장비 가방과 창당 횟수(I201). 이 칸이 생기기 전 저장은 비어 있다. 장착 여부는 영웅 칸 worn이다
	b.forged = d.get("forged", {}).duplicate()
	b.base = _block(d.base)
	for k in ["castle", "rubble", "structures"]:
		b.get(k).clear()
		for f in d[k]:
			b.get(k)[f.cell] = _block(f)
	for pair in [[b.structures, b.footprint], [b.castle, b.walls], [b.rubble, b.debris]]:  # 차지 칸(S216·S217)은 Block에서 다시 편다
		pair[1].clear()
		for k in pair[0].values():
			b._put(pair[0], pair[1], k)
	var people: Array = d.heroes.map(func(f): return _unit(f, b.HERO_KINDS))
	b.roster.assign(d.roster.map(func(i): return people[i]))
	b.lineup.assign(d.lineup.map(func(i): return people[i]))
	b.heroes.assign(d.deployed.map(func(i): return people[i]))
	b.hero = b.heroes[0] if b.heroes else null
	b.units.assign(d.units.map(func(x): return people[x] if x is int else _unit(x, b.MERC_KINDS)))
	for u in b.units:
		if u.has_meta("rally_from"):
			u.rally_from = b.structures.get(u.get_meta("rally_from"))
			u.remove_meta("rally_from")
		if u.has_meta("job"):
			u.job = _job(b, u.get_meta("job")[0], u.get_meta("job")[1])
			u.job.worker = u
			u.remove_meta("job")
	b._census()  # 주민 몸은 구조물 folk에서 다시 만든다
	b._forecast()

static func write(b) -> void:
	store(snapshot(b))

# [동작] 임시 파일에 다 쓴 뒤 저장 파일과 바꾼다
# [의도] 쓰는 도중에 꺼져도 앞 저장이 남게 한다(I157). 바꾸는 사이에 꺼지면 임시 파일만 남으므로 read가 그것도 본다
static func store(d: Dictionary) -> void:
	if path == "":
		return
	var f := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if f == null:
		push_error("저장 파일을 쓰지 못했다: %s" % path)
		return
	f.store_var(d)
	f.close()
	DirAccess.rename_absolute(path + ".tmp", path)

# 저장. 없거나 못 읽거나 형식 판이 다르면 {}
static func read() -> Dictionary:
	for p in [path, path + ".tmp"]:
		if path != "" and FileAccess.file_exists(p):
			var d = FileAccess.open(p, FileAccess.READ).get_var()
			if d is Dictionary and d.get("version") == VERSION:
				return d
	return {}

static func erase() -> void:
	for p in [path, path + ".tmp"]:
		if path != "" and FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)

static func _copy(v):
	return v.duplicate(true) if v is Array or v is Dictionary else v

# 유닛·구조물의 스크립트 변수(SKIP 말고). 집결 지점으로 걷는 용병(I22)은 나온 생산 시설을 칸으로, 일하는 공병(I63)은 그 일을 [칸, 종류]로 담는다
static func _fields(o) -> Dictionary:
	var out := {}
	for p in o.get_property_list():
		if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and p.name not in SKIP:
			out[p.name] = _copy(o.get(p.name))
	if o.get("rally_from"):
		out.rally_from = o.rally_from.cell
	if o.get("job"):
		out.job = [o.job.cell, o.job.kind]
	return out

# 공병 일의 칸·종류로 그 구조물을 찾는다. 성벽 위 대포 칸은 성곽과 구조물이 겹쳐서 종류로 가린다
static func _job(b, cell: Vector2i, kind: String):
	if kind == "base":
		return b.base
	var s = b.structures.get(cell)
	if s and s.kind == kind:
		return s
	return b.castle.get(cell, b.rubble.get(cell))

static func _put(o, f: Dictionary) -> void:
	for k in f:
		if k in ["rally_from", "job"]:
			o.set_meta(k, f[k])  # 구조물을 다 세운 뒤 apply가 잇는다
		else:
			o.set(k, _copy(f[k]))

static func _block(f: Dictionary):
	var k = Battle.Block.new(f.cell, f.kind, f.max_hp)
	_put(k, f)
	return k

static func _unit(f: Dictionary, kinds: Dictionary):
	var u = Battle.Unit.new(f.kind, Vector2i.ZERO, kinds[f.kind])
	_put(u, f)
	return u
