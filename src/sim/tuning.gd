extends RefCounted
# 테스트 모드의 수치 조정(S289~S292, I231~I242). 판 하나에 붙는다. 만들 때 판의 데이터 표를 판만의 사본으로 바꾸고(I240),
# 그때 값을 데이터 값으로 기억한다. 테스트 패널(src/ui/test_panel.gd)이 분류·종류의 줄(fields)을 그리고 put으로 넣는다.
# 줄의 path는 데이터 키·배열 번호를 차례로 담는다(["q", "damage"] · ["steps", 1, "q.damage"]). 판·웨이브 줄의 path는 fields 머리 주석

const CATS := {"판": "stage", "웨이브": "waves", "적": "enemies", "용병": "mercs", "구조물": "structures", "영웅": "heroes", "장비": "gear", "영입": "hire", "레벨": "levels", "미션": "quests"}  # 분류 이름 → 표 이름. 번역 안 함(개발자용, I239)
const TABLES := {"enemies": "ENEMY_KINDS", "mercs": "MERC_KINDS", "structures": "STRUCTURE_KINDS", "heroes": "HERO_KINDS", "gear": "GEAR_KINDS", "quests": "QUEST_KINDS"}  # 표 이름 → 판의 종류 표
# 판 분류의 줄(I233): 지금 골드와 시험 스테이지(main.gd stage())의 칸. ["stage", …]는 판의 stage 사전 경로다
const STAGE := [["gold"], ["stage", "gold"], ["stage", "base_hp"], ["stage", "castle", "wall_hp"], ["stage", "castle", "gate_hp"], ["stage", "spawn_gap"], ["stage", "reward_scale"]]
const HP_KEYS := ["hp", "base_hp", "wall_hp", "gate_hp"]  # 1보다 작게 두지 못하는 체력 칸(I233)
const SLOTS := ["passive", "aura", "q", "w", "e", "r"]  # 장비를 얹어 다시 맞추는 영웅 칸(I200)

static var path := "user://tuning.json"  # 조정값 파일(I238)

var b  # 판(Battle)
var skipped := 0  # 지난 불러오기에서 건너뛴 칸 수(I238)
var _data := {}  # 표 이름 → 만들 때의 값 사본(데이터 값)

# 메인 메뉴에 «테스트 모드»를 보이나(S290): 테스트 빌드(기능 태그 test)나 에디터 실행(editor)
static func shown(tags: Array) -> bool:
	return "test" in tags or "editor" in tags

# 판의 종류 표는 안쪽 사전만 사본으로 바꿔 표를 쥔 HUD가 그대로 본다. 영입·레벨 Resource와 밤 표도 사본으로 바꾼다.
# 데이터 Resource(load 캐시)와 거기서 나온 사전을 고치지 않게 한다(I240)
func _init(battle) -> void:
	b = battle
	for t in TABLES:
		var table: Dictionary = b.get(TABLES[t])
		for k in table:
			table[k] = table[k].duplicate(true)
		_data[t] = table.duplicate(true)
	for t in ["hire", "levels"]:
		b.set(t.to_upper(), _copy(b.get(t.to_upper())))
		_data[t] = _props(b.get(t.to_upper()))
	b.nights = b.nights.duplicate(true)
	b._stage["nights"] = b.nights
	_data.stage = {"castle": {}}
	for p in STAGE.slice(1):
		var v = _get_in(b._stage, p.slice(1))
		if v != null:
			(_data.stage.castle if p.size() == 3 else _data.stage)[p[-1]] = v
	_data.waves = {"rounds": b.rounds.duplicate(true), "hp_mult": Array(b._stage.get("hp_mult", [])).duplicate(), "nights": b.nights.duplicate(true)}

# 그 분류의 종류: 판 "stage" · 웨이브 라운드 차례 · 영입 "hire" · 레벨 "levels" · 그 밖은 데이터 파일 이름(장비는 주인 영웅 종류)
func kinds(cat: String) -> Array:
	var t: String = CATS.get(cat, "")
	match t:
		"stage", "hire", "levels":
			return [t]
		"waves":
			return range(b.rounds.size())
	if not TABLES.has(t):
		return []
	var out: Array = b.get(TABLES[t]).keys()
	out.sort()
	return out

# 줄마다 {name, path, value, data}(I233·I234). 수(정수·실수) 칸만 줄이 된다.
# 판 줄 path는 STAGE. 웨이브 줄 path: ["hp_mult"] · [웨이브 차례, 적 종류](수) · ["night", 웨이브 차례, 키](밤 수치). 보유 영웅의 «레벨» 줄 path: ["level"]
func fields(cat: String, kind) -> Array:
	var t: String = CATS.get(cat, "")
	var out := []
	match t:
		"stage":
			for p in STAGE:
				var v = _now(t, kind, p)
				if _num(v):
					out.append(_line(p, v, _was(t, kind, p)))
		"waves":
			if not kind in kinds(cat):
				return out
			var rows := [["hp_mult"]]
			for w in b.rounds[kind].size():
				rows.append_array(b.rounds[kind][w].map(func(e): return [w, e.kind]))
				var night = _get_in(b.nights, [kind, w])
				if night is Dictionary:
					rows.append_array(night.keys().map(func(k): return ["night", w, k]))
			for p in rows:
				var v = _now(t, kind, p)
				if _num(v):
					out.append(_line(p, v, _was(t, kind, p)))
		"hire", "levels":
			var r: Resource = b.get(t.to_upper())
			for p in _vars(r):
				_leaves(r.get(p), _data[t].get(p), [p], out)
		_:
			if not TABLES.has(t) or not b.get(TABLES[t]).has(kind):
				return out
			if t == "heroes" and not _heroes(kind).is_empty():
				var lv: int = _heroes(kind)[0].level
				out.append(_line(["level"], lv, lv))
			_leaves(b.get(TABLES[t])[kind], _data[t][kind], [], out)
	return out

# 지금 값. 없는 칸이면 null
func value(cat: String, kind, at: Array):
	return _now(CATS.get(cat, ""), kind, at)

# 칸에 넣고 살아 있는 것에 건다(S291, I241). 값은 칸에 맞춘다(_fit). 없는 칸이면 아무것도 하지 않는다
func put(cat: String, kind, at: Array, v) -> void:
	var t: String = CATS.get(cat, "")
	var old = _now(t, kind, at)
	if not _num(old):
		return
	v = _fit(t, at, v, old, _was(t, kind, at))
	if v == old:
		return
	match t:
		"stage":
			_put_stage(at, old, v)
		"waves":
			_put_wave(kind, at, old, v)
		"hire":
			_set_in(b.HIRE, at, v)
		"levels":  # 레벨 칸은 모든 영웅의 레벨·체력·공격력을 다시 맞춘다(I241 ④)
			_set_in(b.LEVELS, at, v)
			for h in _heroes(""):
				_regrow(h)
		"enemies":
			_put_enemy(kind, at, old, v)
		"mercs":
			_put_merc(kind, at, v)
		"structures":
			_put_structure(kind, at, old, v)
		"heroes":
			_put_hero(kind, at, old, v)
		"gear":  # 장비 칸은 그 장비 주인 영웅을 다시 맞춘다(I241 ④)
			_set_in(b.GEAR_KINDS[kind], at, v)
			for h in _heroes(kind):
				b._refit(h)
		"quests":  # 미션 판정 때 읽는다(I241 ⑦)
			_set_in(b.QUEST_KINDS[kind], at, v)

# 라운드 r 웨이브 w에 없는 적 종류를 수 1로 더한다(I234)
func add_enemy(r: int, w: int, kind: String) -> bool:
	if not b.ENEMY_KINDS.has(kind) or r < 0 or r >= b.rounds.size() or w < 0 or w >= b.rounds[r].size() or b.rounds[r][w].any(func(e): return e.kind == kind):
		return false
	b.rounds[r][w].append({"kind": kind, "count": 1})
	return true

# 라운드 이동은 영입 창(도전 시작 전·라운드 사이)과 준비 단계에서만 한다(I235)
func can_jump() -> bool:
	return b.state in ["hiring", "prep", "cleared"]

# 라운드 차례 r의 웨이브 1 준비 단계로 간다(I235). 도전 시작 전이면 먼저 1라운드로 들어간다(출전·시작 공병).
# 라운드를 이긴 것이 아니라서 판정·세금·전리품·목록 뽑기 없이, 라운드 사이에서 다음 라운드로 갈 때(next_round)와 같이 넘어간다
func jump(r: int) -> bool:
	if not can_jump() or r < 0 or r >= b.rounds.size():
		return false
	if b.state == "hiring":
		b.next_round()
	b.round_index = r - 1
	b.state = "cleared"
	return b.next_round()

# 데이터 값과 다른 칸마다 {table, kind, path, value, data, file}(I238). 지금 골드와 영웅 레벨은 판 상태라 빼고, 웨이브의 kind는 라운드 차례다
func changes() -> Array:
	var out := []
	for cat in CATS:
		for kind in kinds(cat):
			for r in fields(cat, kind):
				if r.path != ["gold"] and r.path != ["level"] and r.value != r.data:
					out.append({"table": CATS[cat], "kind": kind, "path": r.path, "value": r.value, "data": r.data, "file": _file(CATS[cat], kind)})
	return out

# 바뀐 칸을 조정값 파일에 덮어쓴다(I238). 쓴 칸 수, 쓰지 못하면 -1
func save() -> int:
	var ch := changes()
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return -1
	f.store_string(JSON.stringify({"version": 1, "changes": ch}, "\t"))
	f.close()
	return ch.size()

# 저장에 담는 칸을 모두 데이터 값으로 돌린 뒤 파일의 칸을 넣는다(I238). 넣은 칸 수, 파일이 없거나 못 읽으면 아무것도 바꾸지 않고 -1
func load_file() -> int:
	skipped = 0
	if not FileAccess.file_exists(path):
		return -1
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not d is Dictionary or not d.get("changes") is Array:
		return -1
	reset()
	var n := 0
	for c in d.changes:
		if _apply(c):
			n += 1
		else:
			skipped += 1
	return n

# 저장에 담는 칸을 모두 데이터 값으로 돌린다. 웨이브에 더한 적 종류는 뺀다(I238)
func reset() -> void:
	for c in changes():
		put(CATS.find_key(c.table), c.kind, c.path, c.data)
	for r in b.rounds.size():
		for w in b.rounds[r].size():
			var wave: Array = b.rounds[r][w]
			for i in range(wave.size() - 1, -1, -1):
				if _wave_at(_data.waves.rounds, [], [], r, [w, wave[i].kind]) == null:
					wave.remove_at(i)

# 파일의 칸 하나를 넣는다. 지금 데이터에 없는 종류·칸이면 거짓(I238). JSON의 수는 실수라 종류·경로의 번호는 정수로 돌린다
func _apply(c) -> bool:
	if not c is Dictionary:
		return false
	var cat = CATS.find_key(c.get("table"))
	var kind = c.get("kind")
	if kind is float:
		kind = int(kind)
	var at: Array = Array(c.get("path", [])).map(func(k): return int(k) if k is float else k)
	if cat == null or at.is_empty() or not _num(c.get("value")) or not kind in kinds(cat):
		return false
	if CATS[cat] == "waves" and at.size() == 2 and at[0] is int and at[1] is String and _now("waves", kind, at) == null:
		add_enemy(kind, at[0], at[1])
	if not _num(_now(CATS[cat], kind, at)):
		return false
	put(cat, kind, at, c.value)
	return true

# 표 t·종류 kind의 칸 at의 지금 값. 없으면 null
func _now(t: String, kind, at: Array):
	match t:
		"stage":
			if not at in STAGE:
				return null
			return b.gold if at == ["gold"] else _get_in(b._stage, at.slice(1))
		"waves":
			return _wave_at(b.rounds, b._stage.get("hp_mult", []), b.nights, kind, at)
		"hire", "levels":
			return _get_in(b.get(t.to_upper()), at)
		"heroes":
			if at == ["level"]:
				var hs := _heroes(kind)
				return hs[0].level if hs else null
	if not TABLES.has(t) or not b.get(TABLES[t]).has(kind):
		return null
	return _get_in(b.get(TABLES[t])[kind], at)

# 그 칸의 데이터 값. 웨이브에 더한 적 종류는 0이다. 지금 골드·영웅 레벨은 지금 값이다
func _was(t: String, kind, at: Array):
	match t:
		"stage":
			return b.gold if at == ["gold"] else _get_in(_data.stage, at.slice(1))
		"waves":
			return _wave_at(_data.waves.rounds, _data.waves.hp_mult, _data.waves.nights, kind, at, 0)
		"hire", "levels":
			return _get_in(_data[t], at)
		"heroes":
			if at == ["level"]:
				return _now(t, kind, at)
	if not _data.has(t) or not _data[t].has(kind):
		return null
	return _get_in(_data[t][kind], at)

# 넣을 값을 칸에 맞춘다(I233): 정수 칸은 정수, 실수 칸은 0.01 단위. 데이터 값이 0 이상이면 0보다, 체력 칸은 1보다 작게 두지 않는다.
# 레벨 줄은 1~최대 레벨이다
func _fit(t: String, at: Array, v, old, data):
	var x: float = roundf(float(v)) if old is int else snappedf(float(v), 0.01)
	if not _num(data) or data >= 0:
		x = maxf(x, 0.0)
	if at[-1] is String and at[-1] in HP_KEYS:
		x = maxf(x, 1.0)
	if t == "heroes" and at == ["level"]:
		x = clampf(x, 1.0, b.LEVELS.steps.size() + 1)
	return int(x) if old is int else x

# 판 분류(I241 ⑤): 지금 골드는 판에, 나머지는 stage 사전에 넣는다. 거점·성벽·성문 체력은 거점과 그 종류의 성곽·잔해에 비율로 건다
func _put_stage(at: Array, old, v) -> void:
	if at == ["gold"]:
		b.gold = v
		return
	_set_in(b._stage, at.slice(1), v)
	var of := {"base_hp": "base", "wall_hp": "castle_wall", "gate_hp": "gate"}
	if not of.has(at[-1]):
		return
	for k in [b.base] + b.castle.values() + b.rubble.values():
		if k.kind == of[at[-1]]:
			_scale(k, float(v) / old)
	b._repath = true  # 성곽 칸의 길 비용은 남은 체력이다(S7)

# 웨이브 분류(I234): 수는 그 웨이브가 시작될 때 읽힌다. 지금 라운드의 체력 배율은 전장의 적에 비율로 건다(I241 ⑥). 밤 칸은 판이 바로 읽는다
func _put_wave(r: int, at: Array, old, v) -> void:
	if at == ["hp_mult"]:
		b._stage.hp_mult[r] = v
		if r == b.round_index and old > 0:
			for e in b.enemies:
				if e.alive:
					_scale(e, float(v) / old)
	elif at[0] is String:
		b.nights[r][at[1]][at[2]] = v
	else:
		for e in b.rounds[r][at[0]]:
			if e.kind == at[1]:
				e.count = v

func _put_enemy(kind: String, at: Array, old, v) -> void:
	_set_in(b.ENEMY_KINDS[kind], at, v)
	for e in b.enemies:
		if e.kind != kind or not e.alive:
			continue
		if at == ["hp"]:
			_scale(e, float(v) / old)
		else:
			_match(e, at, old, v)
			if at == ["radius"] and e.girth == old:  # 나온 때의 반지름(줄어듦 S236의 기준)
				e.girth = v
	b._repath = true  # wall_k·속도처럼 길에 닿는 칸일 수 있다

# 용병(I241 ③): 강화 단계를 얹은 바꾸기 전·뒤 수치로 건다. 강화 단계가 덮는 칸은 바탕 값을 바꿔도 그대로다
func _put_merc(kind: String, at: Array, v) -> void:
	var before: Dictionary = b.merc_stats(kind)
	_set_in(b.MERC_KINDS[kind], at, v)
	var after: Dictionary = b.merc_stats(kind)
	for u in b.units:
		if u.is_hero or u.kind != kind or not u.alive:
			continue
		for key in after:
			if not _num(after[key]) or after[key] == before[key]:
				continue
			if key == "hp":
				_scale(u, float(after.hp) / before.hp)
			else:
				_match(u, [key], before[key], after[key])

func _put_structure(kind: String, at: Array, old, v) -> void:
	_set_in(b.STRUCTURE_KINDS[kind], at, v)
	for s in b.structures.values() + b.rubble.values():
		if s.kind != kind:
			continue
		if at == ["hp"]:
			_scale(s, float(v) / old)
		else:
			_match(s, at, old, v)
	b._repath = true  # 방벽 체력은 길 비용이다(S7)

# 영웅(I241 ④): 체력·공격력은 레벨 성장을 얹어 다시 정하고, 패시브·오라·스킬은 장비를 얹어 다시 맞춘다. 레벨 줄은 그 레벨의 처음 경험치다
func _put_hero(kind: String, at: Array, old, v) -> void:
	if at == ["level"]:
		for h in _heroes(kind):
			var ratio := _ratio(h)
			b._set_xp(h, b.LEVELS.steps.slice(0, v - 1).reduce(func(s, x): return s + x, 0))
			h.hp = ratio * h.max_hp
		return
	_set_in(b.HERO_KINDS[kind], at, v)
	for h in _heroes(kind):
		if at == ["hp"] or at == ["damage"]:
			_regrow(h)
		elif at[0] in SLOTS:
			b._refit(h)
		else:
			_match(h, at, old, v)

# 보유 영웅과 전장의 영웅(쓰러진 영웅 포함) 가운데 그 종류. kind가 ""이면 모두
func _heroes(kind: String) -> Array:
	var out := []
	for h in b.roster + b.heroes:
		if (kind == "" or h.kind == kind) and not h in out:
			out.append(h)
	return out

# 레벨 성장(I112)을 얹어 최대 체력·공격력을 다시 정한다. 체력 비율은 그대로다
func _regrow(h) -> void:
	var ratio := _ratio(h)
	b._set_xp(h, h.xp)
	h.hp = ratio * h.max_hp

static func _ratio(o) -> float:
	return o.hp / o.max_hp if o.max_hp > 0.0 else 1.0

# 최대 체력과 체력(구조물·거점·성곽은 다 지었을 때의 체력도)에 f를 곱한다(I241 ①)
static func _scale(o, f: float) -> void:
	o.max_hp *= f
	o.hp *= f
	if o.get("full") != null:
		o.full *= f

# 살아 있는 것의 그 칸이 바꾸기 전 값과 같으면 새 값으로 바꾼다(I241 ②). 덮어쓴 값은 그대로다
static func _match(o, at: Array, old, v) -> void:
	var holder = _get_in(o, at.slice(0, -1))
	var cur = _get_in(holder, [at[-1]]) if holder != null else null
	if _num(cur) and cur == old:
		_set_in(holder, [at[-1]], v)

# 라운드 r의 웨이브 칸 at의 값. 웨이브에 없는 적 종류면 absent
static func _wave_at(rounds: Array, mult: Array, nights: Array, r, at: Array, absent = null):
	if not (r is int and r >= 0 and r < rounds.size()):
		return null
	if at == ["hp_mult"]:
		return mult[r] if r < mult.size() else null
	if at.size() == 3 and at[0] is String and at[0] == "night":
		return _get_in(nights, [r, at[1], at[2]])
	if at.size() == 2 and at[0] is int and at[1] is String and at[0] >= 0 and at[0] < rounds[r].size():
		for e in rounds[r][at[0]]:
			if e.kind == at[1]:
				return e.count
		return absent
	return null

static func _file(t: String, kind) -> String:
	match t:
		"stage":
			return "src/main.gd"
		"hire", "levels":
			return "data/%s.tres" % t
		"waves":
			var names: Array = load("res://src/main.gd").ROUNDS
			return "data/waves/%s.tres" % names[kind] if kind < names.size() else ""
	return "data/%s/%s.tres" % [t, kind]

static func _num(v) -> bool:
	return v is int or v is float

static func _line(at: Array, v, data) -> Dictionary:
	return {"name": _name(at), "path": at, "value": v, "data": data}

# 이어 쓴 이름: 사전 키는 점으로, 배열 번호는 [n]으로(«q.damage»·«rank_cost[0]»·«steps[3].q.damage»)
static func _name(at: Array) -> String:
	var s := ""
	for k in at:
		s += ("[%d]" % k) if k is int else (("." if s != "" else "") + str(k))
	return s

# 수 칸마다 줄을 out에 더한다. 사전·배열은 안으로 들어가고 글자·참거짓·칸 좌표 등은 건너뛴다(I233)
static func _leaves(v, data, at: Array, out: Array) -> void:
	if v is Dictionary:
		for k in v:
			_leaves(v[k], data.get(k) if data is Dictionary else null, at + [k], out)
	elif v is Array:
		for i in v.size():
			_leaves(v[i], data[i] if data is Array and i < data.size() else null, at + [i], out)
	elif _num(v):
		out.append(_line(at, v, data if _num(data) else v))

# root(사전·배열·Object)에서 at을 따라간 값. 없으면 null
static func _get_in(root, at: Array):
	var v = root
	for k in at:
		if v is Dictionary:
			if not v.has(k):
				return null
			v = v[k]
		elif v is Array:
			if not (k is int and k >= 0 and k < v.size()):
				return null
			v = v[k]
		elif v is Object and k is String:
			v = v.get(k)
		else:
			return null
	return v

static func _set_in(root, at: Array, v) -> void:
	var holder = _get_in(root, at.slice(0, -1))
	if holder is Object:
		holder.set(at[-1], v)
	elif holder != null:
		holder[at[-1]] = v

static func _vars(o: Object) -> Array:
	return o.get_property_list().filter(func(p): return p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE != 0).map(func(p): return p.name)

# 스크립트 변수(배열·사전은 깊은 사본)를 옮긴 새 Resource
static func _copy(r: Resource) -> Resource:
	var c: Resource = r.get_script().new()
	for p in _vars(r):
		var v = r.get(p)
		c.set(p, v.duplicate(true) if v is Array or v is Dictionary else v)
	return c

static func _props(o: Object) -> Dictionary:
	var out := {}
	for p in _vars(o):
		var v = o.get(p)
		out[p] = v.duplicate(true) if v is Array or v is Dictionary else v
	return out
