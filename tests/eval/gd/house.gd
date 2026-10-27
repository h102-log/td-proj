extends "res://tests/eval/gd/lib.gd"
# WBS 2.23 주민 집과 세금(S43·S101~S104·I46·I49). lib.gd·village.gd 머리의 계약에 더하는 API:
#   구조물 kind "house"(집) · STRUCTURE_KINDS.house.tax — 집 하나가 준비 단계마다 내는 세금
#   Battle.HOUSE_CAP — 마을에 지을 수 있는 집 수
#   BattleView(res://src/ui/battle_view.gd).residents(battle, t: float) -> Array — t초 때 그리는 주민 위치들(칸 단위, Vector2)
#   단축키: 0 집 놓기
#   주민 직업(S222·S223·S224, I182): 집 가족의 주민 사전에 원래 직업 job(문자열, 아래 *_JOBS의 이름)
#   Battle.trade(집, i) -> String — 그 집 i번째 주민의 지금 직업(작업장·사격장에 따라 대장장이·활 장인으로 바뀐 것까지)
#   BattleView.folk_of(battle) -> Array — residents 차례의 주민 {body, look, job(지금 직업), home(사는 구조물의 칸)}. 교회의 사제가 끝에 붙는다
#   BattleView.chores(battle, t) -> Array — residents 차례로 {pose, inside}. pose는 "idle"·"walk"·일 자세(POSE 값), inside는 집 안(보이지 않음)
#   BattleView.props(battle) -> Dictionary — 고정 소품 칸: mill·oven·stalls(칸 배열), inn(여관 간판을 단 집의 칸 배열)
#   Battle.dark — 어둠(S210). 평가가 직접 둔다

const H1 := Vector2i(10, 3)  # 마을 칸
const H2 := Vector2i(14, 3)
const OUT := Vector2i(15, 12)  # 들판 칸

# 마을은 위쪽 0~5행. 웨이브마다 적 1마리이고, 웨이브 1이 끝나면 준비 단계로 돌아온다
func _battle(over := {}):
	var stage := {"village": Rect2i(0, 0, 30, 6), "base_hp": BIG, "waves": [[{"kind": "basic", "count": 1}], [{"kind": "basic", "count": 1}]]}
	stage.merge(over, true)
	return battle(stage)

func _key(c, key: int) -> void:
	var ev := InputEventKey.new()
	ev.keycode = key
	ev.pressed = true
	c.handle(ev)

# 웨이브 하나를 끝내고 준비 단계에서 늘어난 골드. 끝나지 않으면 null
func _wave_income(b):
	var gold0: int = b.gold
	b.start_battle()
	if not clear_wave(b) or b.state != "prep":
		return null
	return b.gold - gold0

# EV119 · S43: 집은 들판에 짓지 못하고 마을에 짓는다
func ev119():
	var b = _battle()
	var gold0: int = b.gold
	if b.build("house", OUT) != null or b.gold != gold0:
		return "들판에 집이 지어졌다(골드 %d → %d)" % [gold0, b.gold]
	var h = b.build("house", H1)
	return check(h != null and h.complete, "마을 칸에 집이 지어지지 않았다(%s)" % [h])

# EV120 · S101: 상한만큼 지은 뒤 한 채 더는 거부된다
func ev120():
	var b = _battle()
	for i in b.HOUSE_CAP:
		if b.build("house", Vector2i(2 + i * 2, 1)) == null:
			return "%d채째 집을 짓지 못했다" % (i + 1)
	var gold0: int = b.gold
	return check(b.build("house", H1) == null and b.gold == gold0, "상한 %d채를 넘어 지어졌다(골드 %d → %d)" % [b.HOUSE_CAP, gold0, b.gold])

# EV121 · I46: 완성된 집 2채면 웨이브가 끝날 때 세금 2채분이 들어온다
func ev121():
	var b = _battle()
	b.build("house", H1)
	b.build("house", H2)
	var got = _wave_income(b)
	var want: int = b.ENEMY_KINDS.basic.reward + 2 * b.STRUCTURE_KINDS.house.tax
	return check(got == want, "늘어난 골드 %s, 기대 %d" % [got, want])

# EV122 · I46: 미완성 집은 세금을 내지 않는다
func ev122():
	var b = _battle()
	b.place_merc("engineer", Vector2i(28, 18))  # 멀리 둬서 웨이브가 끝나기 전에 다 짓지 못한다
	b.start_battle()
	var h = b.build("house", H1)
	if h == null or h.complete:
		return "전투 중에 미완성 집이 놓이지 않았다(%s)" % [h]
	var gold0: int = b.gold
	if not clear_wave(b) or b.state != "prep" or h.complete:
		return "웨이브가 끝나지 않았거나 집이 다 지어졌다(%s, 완성 %s)" % [b.state, h.complete]
	var want: int = gold0 + b.ENEMY_KINDS.basic.reward
	return check(b.gold == want, "골드 %d, 기대 %d" % [b.gold, want])

# EV123 · S102: 파괴된 집은 세금이 끊기고, 깎이기만 한 집은 다 낸다
func ev123():
	var b = _battle()
	var dead = b.build("house", H1)
	var hurt = b.build("house", H2)
	b.start_battle()
	b.damage(dead, BIG)
	b.damage(hurt, hurt.max_hp / 2.0)
	var gold0: int = b.gold
	if not clear_wave(b) or b.state != "prep":
		return "웨이브가 끝나지 않았다(%s)" % b.state
	var want: int = gold0 + b.ENEMY_KINDS.basic.reward + b.STRUCTURE_KINDS.house.tax
	return check(b.gold == want, "골드 %d, 기대 %d" % [b.gold, want])

# EV124 · S103: 전투 중에는 공병이 가서 시간을 들여 짓는다
func ev124():
	var b = _battle({"waves": [[{"kind": "basic", "count": 1000}]]})
	b.place_merc("engineer", Vector2i(10, 7))
	b.start_battle()
	var h = b.build("house", H1)
	if h == null or h.complete:
		return "전투 중에 지은 집이 미완성이 아니다(%s)" % [h]
	var done := run(b, 30.0, func():
		kill_all(b)
		return h.complete)
	return check(done, "공병이 집을 다 짓지 못했다(진행률 %.2f)" % h.progress)

# EV125 · S103: 0 키 뒤 마을 칸을 좌클릭하면 집이 지어진다
func ev125():
	var b = _battle()
	var c = controls(b)
	_key(c, KEY_0)
	click(c, MOUSE_BUTTON_LEFT, px(H1))
	var s = b.structure_at(H1)
	return check(s != null and s.kind == "house", "0 키 뒤 좌클릭한 칸 %s(놓기 모드 %s)" % [s, c.placing])

# 마을 안 (5,4)의 적이 인식 범위(3칸) 안 (5,1)의 kind를 치나. 거점은 오른쪽 아래 들판이라 길이 그 칸을 지나지 않는다
func _hits_in_village(kind: String) -> String:
	var b = _battle()
	var s = b.build(kind, Vector2i(5, 1))
	b.spawn_enemy("basic", Vector2i(5, 4), {"hp": BIG})
	if not run(b, 10.0, func(): return s.hp < s.max_hp):
		return "마을 안 적이 인식 범위 안의 %s을 치지 않았다" % kind
	return check(b.base.hp == b.base.max_hp, "거점 체력이 깎였다")

# EV126 · I49: 마을 안 적은 인식 범위 안의 집을 친다
func ev126():
	return _hits_in_village("house")

# EV127 · I49: 마을 안 적은 인식 범위 안의 생산 시설을 친다
func ev127():
	return _hits_in_village("barracks")

# EV128 · I49: 들판의 적은 인식 범위 안의 마을 집을 치지 않는다
func ev128():
	var b = _battle()
	var h = b.build("house", Vector2i(10, 5))  # 마을 맨 아래 줄
	var e = b.spawn_enemy("basic", Vector2i(10, 7), {"hp": BIG})  # 들판, 집에서 2칸
	if not run(b, 60.0, func(): return at_base(b, e)):
		return "적이 거점에 닿지 않았다"
	return check(h.hp == h.max_hp, "들판의 적이 집을 쳤다(체력 %.1f)" % h.hp)

# EV129 · S104: 완성된 집마다 그 집 가족 모두, 시간이 지나면 움직이고, 늘 마을 안이다
func ev129():
	var b = _battle()
	b.build("house", H1)
	b.build("house", H2)
	var n = _people(b)
	if n is String:
		return n
	var view = load("res://src/ui/battle_view.gd")
	var a: Array = view.residents(b, 0.0)
	if a.size() != n:
		return "주민 수가 %d다(두 집 가족 %d명이어야 한다)" % [a.size(), n]
	if range(1, 121).all(func(i): return view.residents(b, i * 0.5) == a):
		return "60초 동안 주민이 그 자리다"
	for i in 120:
		for p in view.residents(b, i * 0.5):
			if not b.village.has_point(Vector2i(p.round())):
				return "%.1f초에 주민 %s가 마을 밖이다" % [i * 0.5, p]
	return ""

# EV462 · S43: 시험 스테이지의 길 칸(광장·큰길 가운데 줄·남쪽 큰길·정문 안 공터·북문·서문 안 공터)에는 집을 짓지 못하고, 고리 길·큰길 가장자리에는 짓는다
func ev462():
	var b = battle(load("res://src/main.gd").stage())
	b.gold = BIG
	for at in [Vector2i(26, 29), Vector2i(29, 15), Vector2i(10, 31), Vector2i(30, 45), Vector2i(27, 55), Vector2i(28, 4), Vector2i(4, 30)]:
		if b.build("house", at) != null or b.gold != BIG:
			return "길 칸에 걸친 %s에 집이 지어졌다(골드 %d → %d)" % [at, BIG, b.gold]
	for at in [Vector2i(22, 21), Vector2i(31, 15)]:
		if b.build("house", at) == null:
			return "길 칸이 아닌 %s에 집이 지어지지 않았다" % [at]
	return ""

# EV468 · S220: 시험 스테이지의 물 칸 49칸과 다리 칸 셋(길 칸). 차지 칸이 물·다리에 걸치는 집은 거부되고, 물가 옆에는 짓는다
func ev468():
	var b = battle(load("res://src/main.gd").stage())
	var w = b.get("water")
	if not w is Dictionary or w.size() != 49:
		return "물 칸이 49칸이 아니다(%s)" % [w.size() if w is Dictionary else w]
	for c in [Vector2i(45, 4), Vector2i(45, 9), Vector2i(45, 12), Vector2i(44, 13), Vector2i(49, 19)]:
		if not w.has(c):
			return "%s가 물 칸이 아니다" % [c]
	for c in [Vector2i(45, 3), Vector2i(45, 10), Vector2i(45, 11)]:
		if w.has(c) or not b.roads.has(c):
			return "다리 칸 %s가 물 칸이거나 길 칸이 아니다" % [c]
	b.gold = BIG
	for at in [Vector2i(44, 14), Vector2i(43, 17), Vector2i(45, 6), Vector2i(44, 11)]:
		if b.build("house", at) != null or b.gold != BIG:
			return "물·다리 칸에 걸친 %s에 집이 지어졌다(골드 %d → %d)" % [at, BIG, b.gold]
	for at in [Vector2i(42, 15), Vector2i(43, 8), Vector2i(46, 9)]:
		if b.build("house", at) == null:
			return "물가 옆 %s에 집이 지어지지 않았다" % [at]
	return ""

# EV471 · S220: 수로·연못 옆 집의 주민은 물 칸 위에 그리지 않는다
func ev471():
	var b = battle(load("res://src/main.gd").stage())
	var w = b.get("water")
	if not w is Dictionary or w.is_empty():
		return "물 칸이 없다"
	b.gold = BIG
	for at in [Vector2i(43, 8), Vector2i(42, 18)]:
		if b.build("house", at) == null:
			return "%s에 집이 지어지지 않았다" % [at]
	var n = _people(b)
	if n is String:
		return n
	var view = load("res://src/ui/battle_view.gd")
	for i in 1201:
		var ps: Array = view.residents(b, i * 0.05)
		if ps.size() != n:
			return "주민이 %d명이다(%d명이어야 한다)" % [ps.size(), n]
		for p in ps:
			if w.has(Vector2i(p.round())):
				return "%.2f초에 주민 %s가 물 칸 위다" % [i * 0.05, p]
	return ""

# 완성된 집들의 가족 수 합. 가족(folk)이 없는 집이 있으면 그 까닭(글)
func _people(b):
	var n := 0
	for s in b.structures.values():
		var f = s.get("folk")
		if s.tax > 0 and s.complete and (not f is Array or f.is_empty()):
			return "집 %s에 가족(folk)이 없다" % [s.cell]
		n += f.size() if f is Array else 0
	return n

const ADULT := ["man", "woman"]
const KID := ["boy", "girl"]
const ELDER := ["old_man", "old_woman"]

# 가족(folk) → 유형(S221): alone·couple·kids·single·three. 다섯 유형이 아니면 ""
func _kind_of(folk: Array) -> String:
	var bodies: Array = folk.map(func(m): return m.body)
	var a: Array = bodies.filter(func(x): return x in ADULT)
	var k: int = bodies.filter(func(x): return x in KID).size()
	var e: int = bodies.filter(func(x): return x in ELDER).size()
	var couple: bool = a.size() == 2 and "man" in a and "woman" in a
	if bodies.size() != a.size() + k + e or bodies.is_empty():
		return ""
	if bodies.size() == 1:
		return "alone"
	if couple and k == 0 and e == 0:
		return "couple"
	if couple and k >= 1 and k <= 3 and e == 0:
		return "kids"
	if a.size() == 1 and k >= 1 and k <= 2 and e == 0:
		return "single"
	if couple and k >= 1 and k <= 2 and e == 1:
		return "three"
	return ""

# 판의 집들의 가족을 [몸, look] 배열로(비교용)
func _families(b) -> Array:
	return b.structures.values().map(func(s): return (s.get("folk") if s.get("folk") is Array else []).map(func(m): return [m.body, m.look]))

# EV473 · S221: 집마다 다섯 유형 가운데 하나의 가족, 몸·look 범위, 가족은 피부가 같고, 같은 씨앗·차례면 같은 가족
func ev473():
	var b = _battle({"seed": 7})
	b.build("house", H1)
	b.build("house", H2)
	for s in b.structures.values():
		var f = s.get("folk")
		if not f is Array or f.is_empty() or f.size() > 5 or _kind_of(f) == "":
			return "집 %s의 가족이 다섯 유형이 아니다: %s" % [s.cell, f]
		for m in f:
			if not m.body in ADULT + KID + ELDER or m.look < 0 or m.look > 7 or m.look % 3 != f[0].look % 3:
				return "집 %s의 주민 %s가 몸·look 범위 밖이거나 피부가 가족과 다르다" % [s.cell, m]
	var c = _battle({"seed": 7})
	c.build("house", H1)
	c.build("house", H2)
	return check(_families(b) == _families(c), "같은 씨앗·차례인데 가족이 다르다: %s / %s" % [_families(b), _families(c)])

# EV474 · S221: 씨앗 200개에서 다섯 유형이 모두 나오고 부부와 아이가 가장 많다
func ev474():
	var n := {}
	for sd in range(1, 201):
		var b = _battle({"seed": sd})
		var s = b.build("house", H1)
		var f = s.get("folk") if s else null
		var k: String = _kind_of(f) if f is Array else ""
		if k == "":
			return "씨앗 %d의 가족이 다섯 유형이 아니다: %s" % [sd, f]
		n[k] = n.get(k, 0) + 1
	var top: String = n.keys().reduce(func(x, y): return x if n[x] >= n[y] else y)
	return check(n.size() == 5 and top == "kids", "유형별 수 %s" % [n])

# EV475 · S221: 짓는 동안은 가족이 없고, 다 지으면 생기고, 팔면 함께 없어진다
func ev475():
	var b = _battle()
	b.place_merc("engineer", Vector2i(12, 5))
	b.start_battle()
	var h = b.build("house", H1)
	var view = load("res://src/ui/battle_view.gd")
	if h == null or h.complete:
		return "전투 중에 미완성 집이 놓이지 않았다(%s)" % [h]
	if not h.get("folk") is Array or not h.folk.is_empty() or not view.residents(b, 0.0).is_empty():
		return "짓는 중인 집에 가족이 있다(%s)" % [h.get("folk")]
	if not run(b, 60, func(): return h.complete):
		return "60초 안에 다 짓지 못했다"
	if h.folk.is_empty() or h.folk.size() > 5 or view.residents(b, 0.0).size() != h.folk.size():
		return "다 지은 집의 가족 %s · 주민 %d명" % [h.folk, view.residents(b, 0.0).size()]
	if not clear_wave(b) or b.state != "prep":
		return "웨이브가 끝나지 않았다(%s)" % b.state
	b.sell([h])
	return check(view.residents(b, 0.0).is_empty(), "판 집의 주민이 남았다(%d명)" % view.residents(b, 0.0).size())

# 주민 직업(S222·I182)의 직업 이름. 역할별 목록은 I182 ②다
const HEAD_JOBS := ["farmer", "fisher", "woodcutter", "carpenter", "mason", "weaver", "merchant", "porter", "miller", "baker", "innkeeper", "watchman"]
const SPOUSE_JOBS := ["water_carrier", "washer", "spinner", "weaver", "brewer", "gleaner", "herbalist", "midwife"]
const CHILD_JOBS := ["play", "goose_herd", "gleaner", "water_carrier"]
const ELDER_JOBS := ["spinner", "herbalist", "midwife"]
const UNIQUE := ["priest", "blacksmith", "miller", "baker", "innkeeper", "watchman", "midwife", "bowyer"]
# 직업 → 일 자세(S172 2026-10-27 변경). 들고 걷기는 carry_로 시작한다
const POSE := {"farmer": "hoe", "gleaner": "squat", "herbalist": "squat", "washer": "squat", "fisher": "fish", "woodcutter": "axe",
	"blacksmith": "hammer", "mason": "hammer", "carpenter": "saw", "spinner": "sit", "weaver": "sit", "bowyer": "sit",
	"merchant": "stir", "brewer": "stir", "baker": "stir", "innkeeper": "stir", "priest": "stir",
	"water_carrier": "carry_water", "porter": "carry_sack", "miller": "carry_sack", "midwife": "carry_basket",
	"watchman": "carry_lantern", "goose_herd": "carry_stick", "play": "walk"}
const ROW6 := [Vector2i(2, 3), Vector2i(6, 3), Vector2i(10, 3), Vector2i(14, 3), Vector2i(18, 3), Vector2i(22, 3)]
const TOWN6 := [Vector2i(22, 17), Vector2i(31, 15), Vector2i(40, 8), Vector2i(40, 16), Vector2i(14, 24), Vector2i(36, 40)]  # 시험 스테이지 집 자리(안 고리 변 밖)
const BV := "res://src/ui/battle_view.gd"

# 가족의 주민마다 역할: 첫 어른 head, 둘째 어른 spouse, 아이 child, 노인 elder(I182 ①)
func _roles(folk: Array) -> Array:
	var out := []
	for m in folk:
		if m.body in ADULT:
			out.append("spouse" if "head" in out else "head")
		else:
			out.append("child" if m.body in KID else "elder")
	return out

func _role_jobs(role: String) -> Array:
	return {"head": HEAD_JOBS, "spouse": SPOUSE_JOBS, "child": CHILD_JOBS, "elder": ELDER_JOBS}[role]

# 마을 0~5행 판에 집 여섯 채. 하나라도 못 지으면 null
func _six(over := {}):
	var b = _battle(over)
	for c in ROW6:
		if b.build("house", c) == null:
			return null
	return b

# 시험 스테이지 판(씨앗 sd, 마을 레벨 2)에 집 여섯 채와 more([종류, 칸]). 못 지으면 그 까닭(글)
func _town(sd: int, more := []):
	var st: Dictionary = load("res://src/main.gd").stage()
	st.seed = sd
	var b = battle(st)
	b.village_level = 2
	b.gold = BIG
	for c in TOWN6:
		if b.build("house", c) == null:
			return "집 %s를 짓지 못했다" % [c]
	for k in more:
		if b.build(k[0], k[1]) == null:
			return "%s %s를 짓지 못했다" % k
	return b

# 원래 직업이 고유 직업이 아닌 가장들 [집, 차례]
func _heads(b) -> Array:
	var out := []
	for s in b.structures.values():
		if s.tax > 0 and s.complete:
			var r := _roles(s.folk)
			for i in s.folk.size():
				if r[i] == "head" and not s.folk[i].get("job") in UNIQUE:
					out.append([s, i])
	return out

# 지금 직업(trade)이 job인 주민들 [집, 차례]
func _holders(b, job: String) -> Array:
	var out := []
	for s in b.structures.values():
		if s.tax > 0 and s.complete:
			for i in s.folk.size():
				if b.trade(s, i) == job:
					out.append([s, i])
	return out

# EV478 · S222: 원래 직업은 역할의 목록 안이고, 300판에서 목록의 직업이 모두 나온다
func ev478():
	var seen := {}
	for sd in range(1, 301):
		var s = _battle({"seed": sd}).build("house", H1)
		if s == null or not s.get("folk") is Array or s.folk.is_empty():
			return "씨앗 %d: 집이나 가족이 없다" % sd
		var r := _roles(s.folk)
		for i in s.folk.size():
			var j = s.folk[i].get("job")
			if not j in _role_jobs(r[i]):
				return "씨앗 %d: %s(%s)의 원래 직업 %s가 목록 밖이다" % [sd, s.folk[i].body, r[i], j]
			seen[j] = true
	var miss := (HEAD_JOBS + SPOUSE_JOBS + CHILD_JOBS + ELDER_JOBS).filter(func(j): return not seen.has(j))
	return check(miss.is_empty(), "나오지 않은 직업: %s" % [miss])

# EV479 · S222: 고유 직업은 판에 한 명 이하, 낚시꾼 넷·상인 둘 이하, 시설 직업·사제는 원래 직업이 아니다
func ev479():
	for sd in range(1, 101):
		var b = _six({"seed": sd})
		if b == null:
			return "씨앗 %d: 집 여섯 채를 짓지 못했다" % sd
		var n := {}
		for s in b.structures.values():
			for m in s.folk:
				if not m.get("job") is String:
					return "씨앗 %d: 원래 직업이 없는 주민이 있다(%s)" % [sd, m]
				n[m.get("job")] = n.get(m.get("job"), 0) + 1
		for j in UNIQUE:
			if n.get(j, 0) > 1:
				return "씨앗 %d: %s가 %d명이다" % [sd, j, n[j]]
		if n.get("fisher", 0) > 4 or n.get("merchant", 0) > 2:
			return "씨앗 %d: 낚시꾼 %d·상인 %d명" % [sd, n.get("fisher", 0), n.get("merchant", 0)]
		for j in ["blacksmith", "bowyer", "priest"]:
			if n.has(j):
				return "씨앗 %d: 원래 직업이 %s인 주민이 있다" % [sd, j]
	return ""

# EV480 · S222: 작업장·사격장을 지으면 이미 사는 가장이 대장장이·활 장인이 되고, 팔면 원래 직업으로 돌아간다
func ev480():
	var b = null
	for sd in range(1, 51):
		var c = _six({"seed": sd})
		if c and _heads(c).size() >= 2:
			b = c
			break
	if b == null:
		return "씨앗 1~50에 원래 직업이 고유 직업이 아닌 가장이 둘 이상인 판이 없다"
	b.village_level = 2
	var heads := _heads(b)
	var is_head := func(x): return heads.any(func(h): return h[0] == x[0] and h[1] == x[1])
	if b.build("workshop", Vector2i(25, 3)) == null:
		return "작업장을 짓지 못했다"
	var smith := _holders(b, "blacksmith")
	if smith.size() != 1 or not is_head.call(smith[0]):
		return "대장장이가 원래 직업이 고유 직업이 아닌 가장 한 명이 아니다: %d명" % smith.size()
	var h: Array = smith[0]
	for s in b.structures.values():
		if s.tax > 0:
			for i in s.folk.size():
				if not (s == h[0] and i == h[1]) and b.trade(s, i) != s.folk[i].job:
					return "대장장이가 아닌 주민 %s의 직업이 %s다(원래 %s)" % [s.folk[i].body, b.trade(s, i), s.folk[i].job]
	if b.build("archery", Vector2i(25, 1)) == null:
		return "사격장을 짓지 못했다"
	var bow := _holders(b, "bowyer")
	if bow.size() != 1 or not is_head.call(bow[0]) or (bow[0][0] == h[0] and bow[0][1] == h[1]):
		return "활 장인이 대장장이가 아닌 가장 한 명이 아니다: %d명" % bow.size()
	b.sell([b.structures[Vector2i(25, 3)]])
	return check(b.trade(h[0], h[1]) == h[0].folk[h[1]].job and _holders(b, "blacksmith").is_empty(),
		"작업장을 판 뒤 대장장이였던 주민의 직업 %s(원래 %s) · 대장장이 %d명" % [b.trade(h[0], h[1]), h[0].folk[h[1]].job, _holders(b, "blacksmith").size()])

# EV481 · S222: 다 지은 교회에 사제 한 명이 살고, 교회를 팔면 없어진다
func ev481():
	var b = _battle()
	var view = load(BV)
	var house = b.build("house", H1)
	var church = b.build("church", Vector2i(20, 3))
	if house == null or church == null:
		return "집 %s · 교회 %s" % [house, church]
	var n: int = house.folk.size()
	if view.residents(b, 0.0).size() != n + 1:
		return "교회를 지은 뒤 주민 %d명(가족 %d명 + 사제여야 한다)" % [view.residents(b, 0.0).size(), n]
	var last: Dictionary = view.folk_of(b).back()
	if last.get("body") != "man" or last.get("look") != 8 or last.get("job") != "priest":
		return "마지막 주민이 사제가 아니다: %s" % [last]
	for i in 121:
		var p: Vector2 = view.residents(b, i * 0.5).back()
		if p.distance_to(b.middle(church)) > 4.0:
			return "%.1f초에 사제 %s가 교회에서 4칸 밖이다" % [i * 0.5, p]
	b.sell([church])
	return check(view.residents(b, 0.0).size() == n, "교회를 판 뒤 주민 %d명" % view.residents(b, 0.0).size())

# 일하는 자리가 일터 안인가(EV483). 걷는 직업·놀기·야경꾼은 보지 않는다. 일터 밖이면 그 까닭(글)
func _off_work(b, f: Dictionary, p: Vector2) -> String:
	var plan: Dictionary = load(BV)._plan()
	var near_any := func(cells: Array, r: float): return cells.any(func(c): return p.distance_to(Vector2(c)) <= r)
	var mid_of := func(kind: String): return b.middle(b.structures.values().filter(func(s): return s.kind == kind)[0])
	var ok := true
	match f.job:
		"farmer", "gleaner", "herbalist":
			ok = near_any.call(plan.garden, 1.5)
		"fisher":
			ok = near_any.call([Vector2i(43, 14), Vector2i(50, 17), Vector2i(44, 8), Vector2i(46, 8)], 1.5)
		"washer":
			ok = near_any.call([Vector2i(43, 16), Vector2i(43, 17)], 1.5)
		"baker":
			ok = near_any.call([Vector2i(25, 28)], 1.5)
		"merchant":
			ok = near_any.call([Vector2i(25, 33), Vector2i(35, 28)], 1.5)
		"mason", "carpenter":
			ok = near_any.call(plan.slabs + plan.gravel, 1.5)
		"spinner", "weaver", "brewer", "innkeeper", "woodcutter":
			ok = p.distance_to(b.middle(b.structures[f.home])) <= 3.5
		"blacksmith":
			ok = p.distance_to(mid_of.call("workshop")) <= 3.5
		"bowyer":
			ok = p.distance_to(mid_of.call("archery")) <= 3.5
		"priest":
			ok = p.distance_to(mid_of.call("church")) <= 3.5
	return "" if ok else "%s가 일터 밖 %s에서 일한다" % [f.job, p]

# EV483 · S223·S224: 낮에는 모두 일터에서 그 직업의 일 자세로 일하고 집 둘레에도 있으며, 걷는 길은 물·남의 구조물 위가 아니다
func ev483():
	var b = _town(3, [["workshop", Vector2i(20, 44)], ["archery", Vector2i(12, 44)], ["church", Vector2i(38, 24)]])
	if b is String:
		return b
	var view = load(BV)
	var who: Array = view.folk_of(b)
	var worked := {}
	var homed := {}
	for k in 721:
		var t := k * 0.25
		var ps: Array = view.residents(b, t)
		var ch: Array = view.chores(b, t)
		if ps.size() != who.size() or ch.size() != who.size():
			return "%.2f초에 주민 %d · 일 %d · 사람 %d" % [t, ps.size(), ch.size(), who.size()]
		for i in who.size():
			var j: String = who[i].job
			var p: Vector2 = ps[i]
			var pose: String = ch[i].pose
			var home = b.structures.get(who[i].home)
			if j == "watchman" and pose == "carry_lantern":
				return "%.2f초 낮에 야경꾼이 등불 자세다" % t
			if pose == POSE[j] and j != "play":
				worked[i] = true
				var bad := _off_work(b, who[i], p)
				if bad != "":
					return "%.2f초 %s" % [t, bad]
			elif pose in ["idle", "walk"] and p.distance_to(b.middle(home)) <= 2.5:
				homed[i] = true
			if pose == "walk" or pose.begins_with("carry"):
				var c := Vector2i(p.round())
				var s = b.footprint.get(c)
				if b.water.has(c) or (s and s != home):
					return "%.2f초 %s가 걷다가 %s(물 칸이거나 남의 구조물) 위다" % [t, j, c]
	for i in who.size():
		if not who[i].job in ["play", "watchman"] and not (worked.has(i) and homed.has(i)):
			return "%s(%s)가 일 %s · 집 둘레 %s" % [who[i].job, who[i].body, worked.has(i), homed.has(i)]
	return ""

# 안 고리 직사각형(18~42열, 21~38행)의 변에서 0.6칸 안인가
func _on_ring(p: Vector2) -> bool:
	var in_x := p.x >= 17.4 and p.x <= 42.6
	var in_y := p.y >= 20.4 and p.y <= 38.6
	return (in_y and minf(absf(p.x - 18), absf(p.x - 42)) <= 0.6) or (in_x and minf(absf(p.y - 21), absf(p.y - 38)) <= 0.6)

# EV484 · S223: 어둠 0.3이면 야경꾼 말고 모두 집 안이고, 야경꾼은 등불을 들고 안 고리를 돈다. 어둠 0이면 집 안인 주민이 없다
func ev484():
	var view = load(BV)
	var b = null
	for sd in range(1, 51):
		var c = _town(sd, [["church", Vector2i(38, 24)]])
		if c is String:
			return c
		if view.folk_of(c).any(func(f): return f.job == "watchman"):
			b = c
			break
	if b == null:
		return "씨앗 1~50에 야경꾼이 있는 판이 없다"
	var who: Array = view.folk_of(b)
	b.dark = 0.3
	for k in 61:
		var ch: Array = view.chores(b, k * 0.5)
		var ps: Array = view.residents(b, k * 0.5)
		for i in who.size():
			if who[i].job == "watchman":
				if ch[i].inside or ch[i].pose != "carry_lantern" or not _on_ring(ps[i]):
					return "%.1f초 야경꾼 %s · %s · 집 안 %s" % [k * 0.5, ps[i], ch[i].pose, ch[i].inside]
			elif not ch[i].inside:
				return "%.1f초 어둠 0.3인데 %s가 밖이다" % [k * 0.5, who[i].job]
	b.dark = 0.0
	for k in 61:
		if view.chores(b, k * 0.5).any(func(c): return c.inside):
			return "%.1f초 어둠 0인데 집 안인 주민이 있다" % (k * 0.5)
	return ""

# EV485 · S224: 시험 스테이지의 고정 소품 자리와 칸, 작은 판에는 소품이 없고, 여관 간판은 여관 주인의 집에만
func ev485():
	var view = load(BV)
	var b = battle(load("res://src/main.gd").stage())
	var pr: Dictionary = view.props(b)
	if pr.get("mill") != [Vector2i(45, 5), Vector2i(45, 6)] or pr.get("oven") != [Vector2i(25, 28)] or pr.get("stalls") != [Vector2i(25, 33), Vector2i(35, 28)]:
		return "소품 자리 %s" % [pr]
	if not pr.mill.all(func(c): return b.water.has(c)) or not (pr.oven + pr.stalls).all(func(c): return b.roads.has(c)):
		return "물레방아가 물 칸이 아니거나 화덕·좌판이 길 칸이 아니다"
	var small: Dictionary = view.props(_battle())
	if not (small.get("mill", []) + small.get("oven", []) + small.get("stalls", [])).is_empty():
		return "작은 판에 소품이 있다: %s" % [small]
	var seen := []
	for sd in range(1, 21):
		var c = _town(sd)
		if c is String:
			return c
		var inn := _holders(c, "innkeeper").map(func(h): return h[0].cell)
		var got: Array = view.props(c).get("inn", [])
		if got != inn or inn.size() > 1:
			return "씨앗 %d: 여관 간판 %s · 여관 주인의 집 %s" % [sd, got, inn]
		seen.append(inn.size())
	return check(0 in seen and 1 in seen, "씨앗 1~20에 여관 주인이 있는 판·없는 판이 다 나오지 않았다: %s" % [seen])
