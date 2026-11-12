extends "res://tests/eval/gd/lib.gd"
# 새 용병 여덟(S354~S362·I292~I294). lib.gd 머리의 계약에 더하는 API:
#   용병 kind "shieldman" · "fire_mage" · "thunder_mage" · "spearman" · "frost_mage" · "cleric" · "cavalry" · "netter"
#   용병 칸 armor · damage_kind("phys" | "magic") · parry · blast · chain · thrust · frost · mend · lance · net (스킬 사전, data/mercs/<종류>.tres)
#   유닛 face(보는 쪽, 단위 벡터) · cast(불마법사 예고 {at, left}, 없으면 null) · rush(기병 돌진 {to, dir, hit}, 없으면 null) · rush_cd · net_cd
#   Battle.HQ_MERCS(거점이 공병 다음에 파는 종류) · Battle.effect(대상, 키) · Battle.regrows(적) · Battle.traces(흔적: slot·hero·aim·hits)
#   Battle.missiles(날아가는 투사체: src·look) · Battle._flies(적) · Battle._pluck(하피, 든 것) · Battle._carried(유닛)
# 적 kind는 기존 그대로: basic · flying · troll · chief(siege3.gd) · dive_harpy(sky.gd) · leap_wolf(wolf.gd) · snatch_harpy · wyvern

const NEW := ["shieldman", "fire_mage", "thunder_mage", "spearman", "frost_mage", "cleric", "cavalry", "netter"]
const DUMMY := {"hp": BIG, "speed": 0.0, "damage": 0.0, "sight": 0.0}  # 움직이지도 치지도 않는 적(체력 큼)
const STILL := {"hp": BIG, "speed": 0.0, "damage": 0.0}  # 움직이지도 치지도 않는 대장(siege3.gd와 같다)

func _need(b, kinds: Array) -> String:
	for k in kinds:
		if not b.MERC_KINDS.has(k):
			return "용병 종류 %s가 없다" % k
	return ""

func _lost(x) -> float:
	return x.max_hp - x.hp

# 물리 피해 x가 방어력 a를 지나 남는 값(S149)
func _phys(b, x: float, a: float) -> float:
	return x * b.armor_mult(a)

func _dummy(b, cell: Vector2i, over := {}):
	return b.spawn_enemy("basic", cell, DUMMY.merged(over, true))

# 스킬이 charge 하나인 고블린 대장(siege3.gd _chief와 같다)
func _chief(b, cell: Vector2i):
	var sk: Dictionary = b.ENEMY_KINDS.chief.get("skills", {})
	var stats := STILL.duplicate()
	stats.skills = {"charge": sk.charge}
	return b.spawn_enemy("chief", cell, stats)

func _casting(e, id: String) -> bool:
	return e.cast != null and e.cast.get("id") == id

func _stun(x) -> void:
	x.fx["test_stun"] = {"stun": true, "left": 30.0}

func _zaps(b) -> Array:
	return b.traces.filter(func(t): return t.slot == "zap")

# EV1054 · S354: 여덟 종류의 수치와 강화 단계가 표와 같다
func ev1054():
	var b = battle()
	var why := _need(b, NEW)
	if why != "":
		return why
	var want := {
		"shieldman": {"cost": 30, "hp": 90.0, "damage": 1.5, "attack_gap": 1.2, "range": 1.2, "speed": 2.2, "armor": 10.0, "block": 2, "damage_kind": "phys", "parry": {"stun": 1.5},
			"ranks": [{"hp": 110.0}, {"armor": 15.0}, {"block": 3}], "rank_cost": [45, 65, 95]},
		"fire_mage": {"cost": 40, "hp": 25.0, "damage": 12.0, "attack_gap": 4.0, "range": 5.0, "speed": 2.3, "damage_kind": "magic", "blast": {"windup": 1.5, "radius": 1.5, "dps": 2.0, "time": 3.0},
			"ranks": [{"damage": 15.0}, {"attack_gap": 3.5}, {"range": 6.0}], "rank_cost": [55, 80, 115]},
		"thunder_mage": {"cost": 35, "hp": 25.0, "damage": 3.0, "attack_gap": 1.2, "range": 4.5, "speed": 2.4, "damage_kind": "magic", "chain": {"odds": 0.25, "jumps": 4, "reach": 2.5},
			"ranks": [{"damage": 4.0}, {"attack_gap": 1.0}, {"chain": {"odds": 0.35}}], "rank_cost": [50, 75, 110]},
		"spearman": {"cost": 25, "hp": 40.0, "damage": 3.0, "attack_gap": 1.1, "range": 2.0, "speed": 2.5, "damage_kind": "phys", "thrust": {"reach": 1.0, "width": 0.5},
			"ranks": [{"hp": 50.0}, {"damage": 4.0}, {"thrust": {"reach": 1.5}}], "rank_cost": [40, 60, 90]},
		"frost_mage": {"cost": 35, "hp": 25.0, "damage": 2.0, "attack_gap": 1.5, "range": 4.5, "speed": 2.4, "damage_kind": "magic", "frost": {"slow": 0.15, "stacks": 4, "time": 3.0, "freeze": 1.5},
			"ranks": [{"damage": 3.0}, {"frost": {"freeze": 2.0}}, {"range": 5.0}], "rank_cost": [50, 75, 110]},
		"cleric": {"cost": 35, "hp": 25.0, "damage": 0.0, "attack_gap": 2.0, "range": 0.0, "sight": 0.0, "speed": 2.5, "mend": {"range": 3.0, "heal": 8.0},
			"ranks": [{"mend": {"heal": 10.0}}, {"attack_gap": 1.6}, {"mend": {"range": 4.0}}], "rank_cost": [45, 65, 95]},
		"cavalry": {"cost": 40, "hp": 55.0, "damage": 3.0, "attack_gap": 1.0, "range": 1.2, "speed": 4.0, "radius": 0.35, "damage_kind": "phys",
			"lance": {"min": 2.5, "length": 6.0, "speed": 12.0, "damage": 8.0, "width": 0.8, "push": 1.0, "cd": 8.0},
			"ranks": [{"hp": 70.0}, {"lance": {"damage": 11.0}}, {"lance": {"cd": 6.0}}], "rank_cost": [55, 80, 115]},
		"netter": {"cost": 30, "hp": 30.0, "damage": 1.5, "attack_gap": 1.2, "range": 5.0, "speed": 2.5, "damage_kind": "phys", "net": {"cd": 6.0, "time": 3.0, "boss": false},
			"ranks": [{"net": {"time": 4.0}}, {"net": {"cd": 5.0}}, {"range": 6.0}], "rank_cost": [45, 65, 95]},
	}
	var bad := []
	for k in want:
		var d: Dictionary = b.MERC_KINDS[k]
		for key in want[k]:
			if d.get(key) != want[k][key]:
				bad.append("%s.%s %s(%s여야 한다)" % [k, key, d.get(key), want[k][key]])
	return check(bad.is_empty(), "; ".join(bad))

# EV1055 · S354: live_prep 판에서는 거점이 공병 다음에 여덟을 팔고, 강화 단계의 사전 값은 그 칸의 적힌 키만 덮는다
func ev1055():
	var stage: Dictionary = load("res://src/main.gd").stage()
	stage.gold = BIG
	var b = load("res://src/sim/battle.gd").new(stage.duplicate(true))
	b.live_prep = true
	b.begin_hiring()
	b.next_round()
	var why := _need(b, NEW)
	if why != "":
		return why
	if b.base.produces != ["engineer"] + NEW:
		return "거점이 파는 것 %s(공병 다음 %s여야 한다)" % [b.base.produces, NEW]
	var bad := []
	for k in NEW:
		if b.sellers(k) != [b.base]:
			bad.append("%s 파는 곳 %s" % [k, b.sellers(k)])
	var t = b.recruit(b.base, "thunder_mage")
	if t == null or t.kind != "thunder_mage" or b.base.rally != cell_of(t):
		return "거점에서 번개마법사를 사지 못했다(%s, 집결 지점 %s)" % [t, b.base.rally]
	for i in 3:
		if not b.rank_up("thunder_mage"):
			bad.append("번개마법사 %d단계 강화 실패" % (i + 1))
	var chain = {"odds": 0.35, "jumps": 4, "reach": 2.5}
	var kept: bool = b.MERC_KINDS.thunder_mage.chain == {"odds": 0.25, "jumps": 4, "reach": 2.5}
	var stats: Dictionary = b.merc_stats("thunder_mage")
	var fresh: bool = stats.chain == chain and is_equal_approx(stats.damage, 4.0) and is_equal_approx(stats.attack_gap, 1.0)
	var live: bool = t.chain == chain and is_equal_approx(t.damage, 4.0) and is_equal_approx(t.attack_gap, 1.0)
	var off: Dictionary = load("res://src/main.gd").stage()
	var o = load("res://src/sim/battle.gd").new(off.duplicate(true))
	o.begin_hiring()
	o.next_round()
	var closed: bool = NEW.all(func(k): return o.sellers(k).is_empty() and not o.can_buy(k))
	return check(bad.is_empty() and kept and fresh and live and closed,
		"%s · 데이터 그대로 %s · 강화 뒤 수치 %s(chain %s) · 있는 용병 %s(chain %s) · live_prep 아닌 마을 판은 여덟을 팔지 않음 %s" % [
			"; ".join(bad), kept, fresh, stats.chain, live, t.chain, closed])

# EV1056 · S355: 정면에서 온 대장 돌진은 방패병 앞에서 멈추고, 방패병은 다치지도 밀리지도 않으며 대장이 1.5초 기절한다.
# 방패병 앞 길의 병사는 맞고 뒤의 병사는 맞지 않는다. 동쪽 적을 친 방패병(보는 쪽 동쪽)은 남쪽에서 온 돌진에 다른 아군처럼 맞는다
func ev1056():
	var b = battle({"base_hp": BIG})
	var why := _need(b, ["shieldman"])
	if why != "":
		return why
	var s = b.place_merc("shieldman", Vector2i(10, 6), {"hp": BIG, "damage": 0, "sight": 0})
	var front = b.place_merc("soldier", Vector2i(10, 8), {"hp": BIG, "damage": 0, "range": 0, "sight": 0})
	var back = b.place_merc("soldier", Vector2i(10, 4), {"hp": BIG, "damage": 0, "range": 0, "sight": 0})
	if s.get("face") != Vector2(0, 1):
		return "처음 보는 쪽 %s((0, 1)이어야 한다)" % [s.get("face")]
	var e = _chief(b, Vector2i(10, 10))
	if not run(b, 0.1, func(): return _casting(e, "charge")):
		return "0.1초 안에 돌진 예고를 시작하지 않았다(cast %s)" % [e.cast]
	run(b, 1.1)
	var stop: bool = absf(e.pos.y - 7.25) <= 0.05 and absf(e.pos.x - 10.0) <= 0.01
	var safe: bool = s.hp == s.max_hp and s.pos.distance_to(Vector2(10, 6)) <= 0.01
	var hit: bool = is_equal_approx(_lost(front), 30.0) and back.hp == back.max_hp
	var stun = b.effect(e, "stun")
	run(b, 1.5)
	var woke: bool = b.effect(e, "stun") == null
	var c = battle({"base_hp": BIG})
	var t = c.place_merc("shieldman", Vector2i(10, 6), {"hp": BIG, "damage": 1.0, "sight": 0})
	var east = _dummy(c, Vector2i(11, 6))
	run(c, 1.5, func(): return east.hp < east.max_hp)
	var faced: bool = t.face.distance_to(Vector2(1, 0)) <= 0.01
	c.damage(east, BIG)
	var f = _chief(c, Vector2i(10, 10))
	run(c, 0.1, func(): return _casting(f, "charge"))
	run(c, 1.1)
	var took: bool = is_equal_approx(_lost(t), _phys(c, 30.0, 10.0)) and f.pos.distance_to(Vector2(10, 4)) <= 0.1 and c.effect(f, "stun") == null
	return check(stop and safe and hit and stun == true and woke and faced and took,
		"막음: 대장 (10,7.25) 멈춤 %s(%s) · 방패병 그대로 %s(체력 %s, 자리 %s) · 앞 병사 −30·뒤 병사 그대로 %s(%s, %s) · 대장 기절 %s · 1.5초 뒤 풀림 %s · 동쪽 적을 치면 보는 쪽 (1,0) %s(%s) · 등을 보인 방패병 −%.2f·대장 (10,4) %s(잃은 체력 %s, 대장 %s)" % [
			stop, e.pos, safe, s.hp, s.pos, hit, _lost(front), _lost(back), stun, woke, faced, t.face, _phys(c, 30.0, 10.0), took, _lost(t), f.pos])

# EV1057 · S355: 정면에서 박은 박치기 하피는 방패병과 곁 아군을 치지 못하고 기절해 땅에 떨어진다. 등 쪽에서 박으면 방패병이 맞고 밀린다
func ev1057():
	var b = battle()
	var why := _need(b, ["shieldman"])
	if why != "":
		return why
	var s = b.place_merc("shieldman", Vector2i(10, 10), {"hp": BIG, "damage": 0, "sight": 0})
	var a = b.place_merc("archer", Vector2i(11, 10), {"hp": BIG, "damage": 0, "sight": 0})
	var d = b.spawn_enemy("dive_harpy", Vector2i(10, 13), {"hp": BIG, "damage": 0})
	if not run(b, 3.0, func(): return b.effect(d, "stun") != null):
		return "3초 안에 박치기 하피가 기절하지 않았다(cast %s, 방패병 잃은 체력 %s)" % [d.cast, _lost(s)]
	var held: bool = s.hp == s.max_hp and a.hp == a.max_hp and s.pos.distance_to(Vector2(10, 10)) <= 0.01
	var down: bool = b.effect(d, "down") == true and not b._flies(d)
	var c = battle()
	var t = c.place_merc("shieldman", Vector2i(10, 10), {"hp": BIG, "damage": 0, "sight": 0})
	var g = c.spawn_enemy("dive_harpy", Vector2i(10, 7), {"hp": BIG, "damage": 0})
	var hit := run(c, 3.0, func(): return t.hp < t.max_hp)
	var took: bool = hit and is_equal_approx(_lost(t), _phys(c, 8.0, 10.0)) and t.pos.distance_to(Vector2(10, 10)) > 0.5 and c.effect(g, "stun") == null
	return check(held and down and took,
		"정면: 방패병·곁 궁수 그대로 %s(%s, %s) · 하피 내려앉음 %s · 등 쪽: 방패병 −%.2f·밀림·하피 기절 아님 %s(잃은 체력 %s, 자리 %s)" % [
			held, _lost(s), _lost(a), down, _phys(c, 8.0, 10.0), took, _lost(t), t.pos])

# 들판 (12,18)에서 북쪽으로 돌진하는 도약 늑대(웨이브에서 나온 것과 같다, I243 ①)
func _dasher(b):
	var w = b.spawn_enemy("leap_wolf", Vector2i(12, 18), {"hp": BIG, "damage": 0})
	w.dashing = true
	w.lane = 12
	b._find_path(w)
	return w

# EV1058 · S355: 돌진하는 도약 늑대가 정면의 방패병에게 맞거나 몸에 막혀 돌진이 끝나면 1.5초 기절한다. 기절한 방패병은 막지 못한다
func ev1058():
	var b = battle({"size": Vector2i(30, 20), "base": Vector2i(25, 2), "spawns": [Vector2i(0, 10)]})
	var why := _need(b, ["shieldman"])
	if why != "":
		return why
	var s = b.place_merc("shieldman", Vector2i(12, 12), {"hp": BIG, "damage": 0, "sight": 0})
	var w = _dasher(b)
	if not w.dashing:
		return "도약 늑대가 돌진하지 않는다"
	var got := run(b, 2.0, func(): return not w.dashing)
	var stun = b.effect(w, "stun")
	var near: bool = w.pos.distance_to(s.pos) <= 1.5
	run(b, 1.3)
	var still = b.effect(w, "stun")
	run(b, 0.35)
	var woke: bool = b.effect(w, "stun") == null
	var c = battle({"size": Vector2i(30, 20), "base": Vector2i(25, 2), "spawns": [Vector2i(0, 10)]})
	var t = c.place_merc("shieldman", Vector2i(12, 12), {"hp": BIG, "damage": 0, "sight": 0})
	_stun(t)
	var v = _dasher(c)
	var ended := run(c, 2.0, func(): return not v.dashing)
	return check(got and stun == true and near and still == true and woke and ended and c.effect(v, "stun") == null,
		"막음 %s · 기절 %s · 방패병 1.5칸 안 %s(늑대 %s) · 1.3초 뒤 기절 %s · 1.65초 뒤 풀림 %s · 기절한 방패병: 돌진 끝 %s·늑대 기절 %s" % [
			got, stun, near, w.pos, still, woke, ended, c.effect(v, "stun")])

# EV1059 · S356: 불마법사는 대상 자리에 1.5초 원을 예고한 뒤 반경 1.5칸 안의 적 모두(나는 적 포함)에 마법 12와 발화(초당 2, 3초)를 준다.
# 원 밖의 적과 예고 동안 원을 나간 적은 맞지 않고, 다음 예고는 4초 뒤다
func ev1059():
	var b = battle()
	var why := _need(b, ["fire_mage"])
	if why != "":
		return why
	var m = b.place_merc("fire_mage", Vector2i(5, 10), {"hp": BIG, "sight": 0})
	var a = _dummy(b, Vector2i(9, 10), {"armor": 15.0})
	var near = _dummy(b, Vector2i(10, 10))
	var bird = b.spawn_enemy("flying", Vector2i(9, 11), DUMMY)
	var away = _dummy(b, Vector2i(9, 13))
	var out = _dummy(b, Vector2i(12, 10))
	b.step(DT)
	var c0 = m.get("cast")
	if c0 == null or c0.at.distance_to(Vector2(9, 10)) > 0.01 or absf(c0.left - 1.5) > DT + 0.001:
		return "첫 스텝 예고 %s((9,10)·남은 1.5초여야 한다)" % [c0]
	away.pos = Vector2(9, 10.5)  # 예고 동안 원 안에 들어왔다가
	run(b, 1.0)
	away.pos = Vector2(9, 13)  # 끝나기 전에 나간다
	var calm: bool = [a, near, bird, away, out].all(func(e): return e.hp == e.max_hp)
	run(b, 0.5, func(): return a.hp < a.max_hp)
	var blast: bool = [a, near, bird].all(func(e): return absf(_lost(e) - 12.0) <= 0.2) and away.hp == away.max_hp and out.hp == out.max_hp
	var burn = b.effect(a, "dot")
	var n0: float = _lost(a)
	run(b, 3.2)
	var burnt: bool = absf(_lost(a) - n0 - 6.0) <= 0.3 and b.effect(a, "dot") == null
	var c = battle()
	var k = c.place_merc("fire_mage", Vector2i(5, 10), {"hp": BIG, "sight": 0})
	_dummy(c, Vector2i(9, 10))
	var starts := []
	var t := 0.0
	var was = null
	while t < 9.0:
		c.step(DT)
		t += DT
		if k.cast != null and was == null:
			starts.append(t)
		was = k.cast
	var gap: bool = starts.size() >= 2 and absf(starts[1] - starts[0] - 4.0) <= DT + 0.001
	return check(calm and blast and burn == 2.0 and burnt and gap,
		"예고 동안 그대로 %s · 터짐: 원 안 셋 −12·나간 적·원 밖 그대로 %s(%s, %s, %s / %s, %s) · 발화 %s(초당 2) · 3초 −6 %s(%.2f) · 예고 시작 차례 %s(4초 간격)" % [
			calm, blast, _lost(a), _lost(near), _lost(bird), _lost(away), _lost(out), burn, burnt, _lost(a) - n0, starts])

# EV1060 · S356: 예고 동안 불마법사가 기절하거나 이동 지시를 받으면 예고가 사라지고 터지지 않는다. 불마법사의 발화는 트롤 재생을 멈춘다
func ev1060():
	var b = battle()
	var why := _need(b, ["fire_mage"])
	if why != "":
		return why
	var m = b.place_merc("fire_mage", Vector2i(5, 10), {"hp": BIG, "sight": 0})
	var a = _dummy(b, Vector2i(9, 10))
	b.step(DT)
	var began: bool = m.cast != null
	_stun(m)
	run(b, 2.0)
	var stunned: bool = m.cast == null and a.hp == a.max_hp
	var c = battle()
	var k = c.place_merc("fire_mage", Vector2i(5, 10), {"hp": BIG, "sight": 0})
	var e = _dummy(c, Vector2i(9, 10))
	c.step(DT)
	c.order_move([k], Vector2i(5, 14))
	c.step(DT)
	var moved: bool = k.cast == null
	run(c, 2.0)
	var spared: bool = e.hp == e.max_hp
	var d = battle()
	var f = d.place_merc("fire_mage", Vector2i(5, 10), {"hp": BIG, "sight": 0})
	var troll = d.spawn_enemy("troll", Vector2i(9, 10), {"hp": 1000.0, "speed": 0.0, "damage": 0.0, "sight": 0.0, "skills": {}})
	troll.hp = 500.0
	var grows: bool = d.regrows(troll)
	run(d, 2.0, func(): return d.effect(troll, "dot") != null)
	var stopped: bool = d.effect(troll, "dot") != null and not d.regrows(troll)
	return check(began and stunned and moved and spared and grows and stopped,
		"예고 시작 %s · 기절하면 예고 사라짐·안 터짐 %s · 이동 지시에 사라짐 %s · 안 터짐 %s · 트롤 재생 %s → 발화 중 멈춤 %s" % [began, stunned, moved, spared, grows, stopped])

# EV1061 · S357: 번개마법사는 투사체 없이 바로 마법 3을 꽂는다. 전이가 터지면 4번 전이하고, 옮길 새 적이 없으면 처음 대상을 친다
func ev1061():
	var b = battle()
	var why := _need(b, ["thunder_mage"])
	if why != "":
		return why
	var m = b.place_merc("thunder_mage", Vector2i(5, 10), {"hp": BIG, "sight": 0, "chain": {"odds": 0.0, "jumps": 4, "reach": 2.5}})
	var a = _dummy(b, Vector2i(8, 10), {"armor": 15.0})
	b.step(DT)
	var once: bool = is_equal_approx(_lost(a), 3.0) and b.missiles.is_empty()
	var c = battle()
	c.place_merc("thunder_mage", Vector2i(5, 10), {"hp": BIG, "sight": 0, "chain": {"odds": 1.0, "jumps": 4, "reach": 2.5}})
	var lone = _dummy(c, Vector2i(8, 10))
	c.step(DT)
	var five: bool = is_equal_approx(_lost(lone), 15.0)
	var d = battle()
	d.place_merc("thunder_mage", Vector2i(5, 10), {"hp": BIG, "sight": 0, "chain": {"odds": 1.0, "jumps": 4, "reach": 2.5}})
	var x = _dummy(d, Vector2i(8, 10))
	var y = _dummy(d, Vector2i(10, 10))
	var z = _dummy(d, Vector2i(12, 10))
	var far = _dummy(d, Vector2i(8, 14))
	d.step(DT)
	var zaps := _zaps(d)
	var order: bool = zaps.size() == 1 and zaps[0].hits == [x, y, z, x, x]
	var dealt: bool = is_equal_approx(_lost(x), 9.0) and is_equal_approx(_lost(y), 3.0) and is_equal_approx(_lost(z), 3.0) and far.hp == far.max_hp
	return check(once and five and order and dealt,
		"전이 없음: 바로 −3·투사체 없음 %s(%s, 투사체 %d) · 혼자인 적 −15 %s(%s) · 셋: 맞은 차례 [x,y,z,x,x] %s · x −9·y −3·z −3·먼 적 그대로 %s(%s, %s, %s, %s)" % [
			once, _lost(a), b.missiles.size(), five, _lost(lone), order, dealt, _lost(x), _lost(y), _lost(z), _lost(far)])

# EV1062 · S358: 창병은 2칸 떨어진 나는 적을 치고, 대상 뒤 1칸 선 위의 적도 같은 물리 피해로 꿰뚫는다. 선 밖의 적은 맞지 않는다
func ev1062():
	var b = battle()
	var why := _need(b, ["spearman"])
	if why != "":
		return why
	b.place_merc("spearman", Vector2i(5, 10), {"hp": BIG, "sight": 0})
	var bird = b.spawn_enemy("flying", Vector2i(7, 10), DUMMY)
	var hit := run(b, 1.5, func(): return bird.hp < bird.max_hp)
	var c = battle()
	c.place_merc("spearman", Vector2i(5, 10), {"hp": BIG, "sight": 0})
	var a = _dummy(c, Vector2i(7, 10))
	var behind = _dummy(c, Vector2i(8, 10))
	var aside = _dummy(c, Vector2i(8, 11))
	run(c, 1.5, func(): return a.hp < a.max_hp)
	var pierced: bool = is_equal_approx(_lost(a), 3.0) and is_equal_approx(_lost(behind), 3.0) and aside.hp == aside.max_hp
	return check(hit and pierced, "나는 적을 침 %s · 대상 −3·뒤 −3·옆 그대로 %s(%s, %s, %s)" % [hit, pierced, _lost(a), _lost(behind), _lost(aside)])

# EV1063 · S359: 얼음 마법사의 구슬이 닿을 때마다 냉기가 한 겹 쌓여 겹마다 둔화 15%이고, 넷째 겹에 겹이 사라지며 1.5초 빙결한다. 두 마법사가 함께 쌓는다
func ev1063():
	var b = battle()
	var why := _need(b, ["frost_mage"])
	if why != "":
		return why
	var m = b.place_merc("frost_mage", Vector2i(5, 10), {"hp": BIG, "sight": 0, "damage": 0.0})
	var a = _dummy(b, Vector2i(9, 10))
	var steps := []
	for n in [1, 2, 3]:
		if not run(b, 3.0, func(): return b.effect(a, "chill") == n):
			return "%d겹이 쌓이지 않았다(냉기 %s)" % [n, b.effect(a, "chill")]
		steps.append(is_equal_approx(b.effect_sum(a, "slow"), 0.15 * n))
	var look: bool = b.missiles.all(func(x): return x.look == "bolt")
	if not run(b, 3.0, func(): return b.effect(a, "stun") != null):
		return "넷째 겹에 빙결하지 않았다(냉기 %s)" % [b.effect(a, "chill")]
	var froze: bool = b.effect(a, "chill") == null
	run(b, 1.4)
	var still = b.effect(a, "stun")
	run(b, 0.2)
	var thaw: bool = b.effect(a, "stun") == null
	var c = battle()
	c.place_merc("frost_mage", Vector2i(5, 9), {"hp": BIG, "sight": 0, "damage": 0.0})
	c.place_merc("frost_mage", Vector2i(5, 11), {"hp": BIG, "sight": 0, "damage": 0.0})
	var e = _dummy(c, Vector2i(9, 10))
	var both := run(c, 3.0, func(): return c.effect(e, "stun") != null)
	return check(steps == [true, true, true] and look and froze and still == true and thaw and both,
		"겹마다 둔화 15%%·30%%·45%% %s · 구슬(bolt) %s · 넷째 겹 빙결·겹 사라짐 %s · 1.4초 뒤 빙결 %s · 1.6초 뒤 풀림 %s · 두 마법사 3초 안 빙결(둘째 사격) %s" % [steps, look, froze, still, thaw, both])

# EV1064 · S360: 사제는 적을 치지 않고, 3칸 안 다친 아군 가운데 체력 비율이 가장 낮은 것을 2초마다 8씩 고친다. 고칠 것이 없으면 기다렸다가 바로 고친다
func ev1064():
	var b = battle()
	var why := _need(b, ["cleric"])
	if why != "":
		return why
	var p = b.place_merc("cleric", Vector2i(5, 10), {"hp": BIG})
	var foe = _dummy(b, Vector2i(5, 11))
	var s1 = b.place_merc("soldier", Vector2i(6, 10), {"damage": 0, "sight": 0})
	var s2 = b.place_merc("soldier", Vector2i(7, 10), {"damage": 0, "sight": 0})
	var far = b.place_merc("archer", Vector2i(12, 10), {"damage": 0, "sight": 0})
	s1.hp = 30.0
	s2.hp = 40.0
	far.hp = 10.0
	b.step(DT)
	var first: bool = is_equal_approx(s1.hp, 38.0) and is_equal_approx(s2.hp, 40.0) and is_equal_approx(far.hp, 10.0)
	run(b, 1.9)
	var waited: bool = is_equal_approx(s1.hp, 38.0)
	run(b, 0.15)
	var second: bool = is_equal_approx(s1.hp, 46.0) and is_equal_approx(s2.hp, 40.0)
	run(b, 2.0)
	var third: bool = is_equal_approx(s2.hp, 48.0)
	run(b, 10.0)
	var full: bool = s1.hp == s1.max_hp and s2.hp == s2.max_hp and is_equal_approx(far.hp, 10.0) and foe.hp == foe.max_hp
	s2.hp = 45.0
	b.step(DT)
	var quick: bool = is_equal_approx(s2.hp, 50.0)
	return check(first and waited and second and third and full and quick,
		"첫 회복 s1 38 %s(%s, %s, %s) · 1.95초까지 그대로 %s · 2초 s1 46 %s · 4초 s2 48 %s · 다 참·먼 궁수·적 그대로 %s(%s, %s, %s, 적 %s) · 기다리다 바로 %s(%s)" % [
			first, s1.hp, s2.hp, far.hp, waited, second, third, full, s1.hp, s2.hp, far.hp, foe.hp, quick, s2.hp])

# EV1065 · S361: 기병은 2.5칸 넘게 떨어진 적 쪽으로 6칸을 초당 12칸으로 달려, 지나간 적에게 물리 8을 주고 옆으로 1칸 민다. 끝나면 8초 대기. 홀드면 달리지 않는다
func ev1065():
	var b = battle()
	var why := _need(b, ["cavalry"])
	if why != "":
		return why
	var k = b.place_merc("cavalry", Vector2i(5, 10), {"hp": BIG, "damage": 0.0})
	var a = _dummy(b, Vector2i(9, 10))
	b.step(DT)
	var r = k.get("rush")
	if r == null or r.to.distance_to(Vector2(11, 10)) > 0.01:
		return "첫 스텝에 (11,10)까지 돌진하지 않았다(rush %s)" % [r]
	run(b, 0.25)
	var mid: bool = absf(k.pos.x - 8.6) <= 0.35
	run(b, 0.5, func(): return k.rush == null)
	var done: bool = k.rush == null and k.pos.distance_to(Vector2(11, 10)) <= 0.05 and absf(k.rush_cd - 8.0) <= 0.1
	var hurt: bool = is_equal_approx(_lost(a), 8.0) and absf(a.pos.y - 9.0) <= 0.05 and absf(a.pos.x - 9.0) <= 0.05
	var c = battle()
	var h = c.place_merc("cavalry", Vector2i(5, 10), {"hp": BIG, "damage": 0.0})
	c.set_hold([h], true)
	_dummy(c, Vector2i(9, 10))
	run(c, 1.0)
	var held: bool = h.rush == null and h.pos.distance_to(Vector2(5, 10)) <= 0.01
	return check(mid and done and hurt and held,
		"0.3초 x 8.6 %s(%s) · 끝·(11,10)·대기 8 %s(%s, %s) · 적 −8·(9,9)로 밀림 %s(%s, %s) · 홀드면 그대로 %s(%s)" % [
			mid, k.pos, done, k.pos, k.rush_cd, hurt, _lost(a), a.pos, held, h.pos])

# EV1066 · S362: 그물 사수는 사거리 안 나는 적에게 그물을 던져 3초 봉인하고(내려앉음), 아군을 든 낚아채기 하피를 먼저 노려 든 것을 내려놓게 한다.
# 보스는 노리지 않는다. 그물 대기 6초 동안은 화살을 쏜다
func ev1066():
	var b = battle()
	var why := _need(b, ["netter"])
	if why != "":
		return why
	var n = b.place_merc("netter", Vector2i(5, 10), {"hp": BIG, "sight": 0})
	var bird = b.spawn_enemy("flying", Vector2i(8, 10), DUMMY)
	b.step(DT)
	var netted: bool = b.effect(bird, "seal") == true and not b._flies(bird) and absf(n.net_cd - 6.0) <= DT + 0.001
	if not run(b, 2.0, func(): return b.missiles.any(func(x): return x.src == n and x.look == "arrow")):
		return "그물 대기 동안 화살을 쏘지 않았다(그물 %s)" % netted
	var gone := run(b, 2.5, func(): return b.effect(bird, "seal") == null)
	var freed: bool = gone and b._flies(bird) and absf(n.net_cd - 3.0) <= 0.1
	var c = battle()
	var t = c.place_merc("netter", Vector2i(5, 10), {"hp": BIG, "sight": 0})
	var held = c.place_merc("soldier", Vector2i(9, 12), {"hp": BIG, "damage": 0, "sight": 0})
	c.spawn_enemy("flying", Vector2i(7, 10), DUMMY)
	var snatch = c.spawn_enemy("snatch_harpy", Vector2i(9, 12), DUMMY)
	c._pluck(snatch, held)
	if not c._carried(held):
		return "낚아채기 하피가 병사를 들지 못했다"
	c.step(DT)
	c.step(DT)
	var first: bool = c.effect(snatch, "seal") == true and not c._carried(held)
	var d = battle()
	d.place_merc("netter", Vector2i(5, 10), {"hp": BIG, "sight": 0})
	var boss = d.spawn_enemy("wyvern", Vector2i(7, 10), {"hp": BIG, "speed": 0.0, "damage": 0.0, "sight": 0.0, "skills": {}})
	var other = d.spawn_enemy("flying", Vector2i(9, 10), DUMMY)
	d.step(DT)
	var skip: bool = d.effect(boss, "seal") == null and d.effect(other, "seal") == true
	return check(netted and freed and first and skip,
		"그물: 봉인·내려앉음·대기 6 %s · 3초 뒤 풀려 다시 낢(그물 대기 3초 남음) %s · 든 하피 먼저·병사 내려놓음 %s · 보스 건너뛰고 다른 하피 %s" % [netted, freed, first, skip])
