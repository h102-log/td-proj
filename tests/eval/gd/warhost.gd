extends "res://tests/eval/gd/orc.gd"
# 6라운드 대족장 군단 묶음 ①(S324 2026-11-11 변경·S335·I279). lib.gd·sky.gd·orc.gd 머리의 계약에 더하는 API:
#   적 kind "wolf_rider"(늑대 기수, S335). 적 칸 flank({ranged}) · phase2 · mount · via(먼저 노리는 성문 칸) · fx(걸린 효과)
#   Battle.fallen — 쓰러진 몸 [{who, age}] · Battle.wrecks — 수레 잔해 · Battle.gold · damage(대상, 양, "true")는 고정 피해
#   BattleView: ART(그림 칸 표) · _fallen() — 그릴 쓰러진 몸 [[몸, 쓰러진 뒤 초]]
#   묶음 ③(S339·S340·S341·I282): 적 kind "warguard"(대족장 근위대) · "warchief"(오크 대족장) · "warchief_foot"(내린 대족장).
#   적 칸 rooted(밀리지 않음) · calls(군단을 부른 횟수) · cd(스킬 → 남은 대기) · snag(던진 사슬의 끝) · Battle.horns(이 판에서 부대가 나온 횟수)
#   예고 cast: charge·chain {id, left, dir, to} · horn {id, left} · rift {id, left, spots} · Battle.armor_mult(Battle.armor_of(유닛)) — 물리 피해 배율
#   새 기믹(S344~S350·I285): 적 칸 duel({who, at, radius, left, need, dealt}) · doom({who, left}) · orders · banner({radius}) · bodyguard({big, reach}) · spent
#   Battle.edict({kind "rush"|"shield", left}) · Battle.edicts · 영웅 효과 출처 «shackle»({shackle 짝, reach, share}) · «verdict» · 효과 키 silence
#   예고 cast: duel {who, at} · shackle {pair, spots} · order · banner {at} · verdict {mark, at} · roar {dir} · 적 kind "warbanner"(전쟁 깃발)
#   BattleView: _feud_marks() — 결투장·사슬 족쇄·처형 표식·침묵·군령·깃발 그리기
# 판은 lib.gd battle()의 들판(30×20, 거점 (25,10))이다. 처치 보상 배율이 없어 처치 보상이 그대로 골드에 든다

const WR := "wolf_rider"
const TALL := {"hp": BIG}  # 체력만 크고 나머지는 종류 수치 그대로
const WG := "warguard"
const WC := "warchief"
const WF := "warchief_foot"
const WB := "warbanner"
const THREE := [Vector2i(5, 19), Vector2i(15, 19), Vector2i(25, 19)]  # 출현 지점 셋(왼쪽·가운데·오른쪽)

# 들판 판에 투척꾼(움직이지도 치지도 않음)을 (10,10)에, kind 적(over 수치)을 (11,10)에 두고 치지도 쫓지도 않는 궁수를 (15,10)에 세운다. [판, 투척꾼, 적, 궁수]
func _throw(kind: String, over: Dictionary) -> Array:
	var b = battle({"base_hp": BIG})
	if not (b.ENEMY_KINDS.has(OT) and b.ENEMY_KINDS.has(kind)):
		return [b, null, null, null]
	var t = _still(b, OT, Vector2(10, 10))
	var x = b.spawn_enemy(kind, Vector2i(11, 10), over)
	return [b, t, x, b.place_merc("archer", Vector2i(15, 10), MUTE)]

# 병사 Q를 q 칸에, 궁수 P를 p 칸에 세우고(둘 다 치지도 쫓지도 않음) kind 적(체력 큼)을 (10,10)에 내보낸 판을 3초 돌려, 먼저 체력을 잃은 쪽. «P»·«Q»·«PQ»(같은 스텝)·«»(아무도)
func _first_hit(kind: String, q: Vector2i, p: Vector2i) -> String:
	var b = battle({"base_hp": BIG})
	var sq = b.place_merc("soldier", q, QUIET)
	var ap = b.place_merc("archer", p, MUTE)
	b.spawn_enemy(kind, Vector2i(10, 10), TALL)
	for i in 60:
		b.step(DT)
		var hit := ("P" if ap.hp < ap.max_hp else "") + ("Q" if sq.hp < sq.max_hp else "")
		if hit != "":
			return hit
	return ""

# EV964 · S324: 던져진 슬라임은 떨어진 때 원 피해를 주고 꼬마 슬라임 둘로 갈라진다. 처치가 아니라 골드도 쓰러진 몸도 없다
func ev964():
	var g := _throw("slime", STILL)
	var b = g[0]
	var why := _need(b, [OT])
	if why != "":
		return why
	var t = g[1]
	var s = g[2]
	var p = g[3]
	var gold: int = b.gold
	if not _ever(b, t, "hurl", 0.1):
		return "0.1초 안에 던지기 예고를 시작하지 않았다(cast %s · 던질 종류 %s)" % [t.cast, b.ENEMY_KINDS[OT].hurl.kinds]
	_steps(b, 22)
	if s.pos.distance_to(Vector2(11, 10)) > 0.05 or _flying(s):
		return "예고 1.1초: 슬라임 자리 %s((11,10)) · 떴다 %s" % [s.pos, _flying(s)]
	var up := 22
	while up < 28 and not _flying(s):
		b.step(DT)
		up += 1
	if not _flying(s):
		return "예고 1.4초에 슬라임이 뜨지 않았다(cast %s)" % [s.cast]
	_steps(b, 40 - up)
	var kids: Array = b.enemies.filter(func(e): return e.kind == "slimelet")
	if s in b.enemies or s.alive or kids.size() != 2:
		return "예고 2.0초: 슬라임이 적 목록에 있다 %s · 살아 있다 %s · 꼬마 슬라임 %d마리(2)" % [s in b.enemies, s.alive, kids.size()]
	if kids.any(func(k): return k.pos.distance_to(Vector2(15, 10)) > 1.0 or k.reward != 0 or k.xp != 0 or not is_equal_approx(k.max_hp, 5.0)):
		return "꼬마 슬라임 [자리, 처치 보상, 경험치, 최대 체력] %s((15,10) 1칸 안, 0, 0, 5)" % [kids.map(func(k): return [k.pos, k.reward, k.xp, k.max_hp])]
	var lost := _lost(p)
	if lost < 12.0 - 0.001 or b.gold != gold or not b.fallen.is_empty():
		return "예고 2.0초: 궁수가 잃은 체력 %s(12 이상) · 골드 %d(처음 %d) · 쓰러진 몸 %d(0)" % [lost, b.gold, gold, b.fallen.size()]
	if not run(b, 3.0, func(): return _lost(p) > lost):
		return "갈라져 나온 꼬마 슬라임이 3초 안에 궁수를 치지 않았다(잃은 체력 %s)" % _lost(p)
	for k in kids:
		b.damage(k, BIG, "true")
	return check(b.gold == gold, "꼬마 슬라임 둘을 처치한 뒤 골드 %d(처음 %d 그대로여야 한다)" % [b.gold, gold])

# EV965 · S324: 던져진 늑대는 떨어진 자리에서 곧 문다. 기본 적·늑대 기수는 던질 종류가 아니다
func ev965():
	var g := _throw("wolf", {"speed": 0, "hp": BIG})
	var b = g[0]
	var why := _need(b, [OT, WR])
	if why != "":
		return why
	var t = g[1]
	var w = g[2]
	var p = g[3]
	if not _ever(b, t, "hurl", 0.1):
		return "0.1초 안에 던지기 예고를 시작하지 않았다(cast %s · 던질 종류 %s)" % [t.cast, b.ENEMY_KINDS[OT].hurl.kinds]
	_steps(b, 40)
	var lost := _lost(p)
	if _flying(w) or w.pos.distance_to(Vector2(15, 10)) > 1.0 or w.hp != w.max_hp or lost < 12.0 - 0.001:
		return "예고 2.0초: 늑대 떴다 %s · 자리 %s((15,10) 1칸 안) · 늑대가 잃은 체력 %s(0) · 궁수가 잃은 체력 %s(12 이상)" % [_flying(w), w.pos, _lost(w), lost]
	if not run(b, 1.0, func(): return _lost(p) > lost):
		return "떨어진 늑대가 1초 안에 궁수를 물지 않았다(잃은 체력 %s)" % _lost(p)
	for kind in ["basic", WR]:
		var h := _throw(kind, STILL)
		if _ever(h[0], h[1], "hurl", 3.0):
			return "%s를 집어 던지기 예고를 띄웠다(던질 종류가 아니다)" % kind
	return ""

# EV966 · S335 ①: 늑대 기수는 인식 범위 안의 원거리 아군을 더 가까운 근접 아군보다 먼저 노린다. 원거리가 범위 밖이면 일반 적과 같고, 몸이 닿은 유닛은 친다
func ev966():
	var why := _need(battle(), [WR])
	if why != "":
		return why
	var got := [_first_hit(WR, Vector2i(11, 12), Vector2i(14, 10)), _first_hit("wolf", Vector2i(11, 12), Vector2i(14, 10)),
		_first_hit(WR, Vector2i(11, 12), Vector2i(16, 10)), _first_hit(WR, Vector2i(12, 10), Vector2i(14, 10))]
	return check(got == ["P", "Q", "Q", "Q"],
		"3초 안에 먼저 체력을 잃은 쪽: 늑대 기수 «%s»(P) · 늑대 «%s»(Q) · 궁수가 인식 범위 밖일 때 늑대 기수 «%s»(Q) · 병사가 길을 막았을 때 늑대 기수 «%s»(Q)" % got)

# EV967 · S335 ②: 체력이 0이 되면 쓰러지지 않고 장갑이 된다. 체력은 가득, 효과는 비고, 먼저 노리던 성문은 그대로이며 그 자리에 늑대의 쓰러진 몸이 남는다
func ev967():
	var b = battle({"base_hp": BIG, "hp_mult": [1.5]})
	var why := _need(b, [WR])
	if why != "":
		return why
	var e = _still(b, WR, Vector2(10, 10), {"hp": 10})
	e.via = Vector2i(12, 10)
	e.fx["test"] = {"slow": 0.5, "left": 10.0}
	var gold: int = b.gold
	b.damage(e, 50.0, "true")
	if not e.alive or e.kind != "armored" or b.enemies.size() != 1:
		return "고정 피해 50 뒤: 살아 있다 %s · 종류 %s(armored) · 적 수 %d(1)" % [e.alive, e.kind, b.enemies.size()]
	var body: bool = is_equal_approx(e.hp, 27.0) and is_equal_approx(e.max_hp, 27.0) and is_equal_approx(e.armor, 15.0) and is_equal_approx(e.speed, 1.5) and is_equal_approx(e.radius, 0.35)
	if not body or not e.fx.is_empty() or e.via != Vector2i(12, 10) or b.gold != gold:
		return "내린 장갑: 체력 %s/%s(27) · 방어력 %s(15) · 속도 %s(1.5) · 몸 반지름 %s(0.35) · 효과 %s(없음) · via %s((12,10)) · 골드 %d(처음 %d)" % [e.hp, e.max_hp, e.armor, e.speed, e.radius, e.fx, e.via, b.gold, gold]
	var lying: Array = b.fallen
	if lying.size() != 1 or lying[0].who.kind != "wolf" or lying[0].who.pos.distance_to(Vector2(10, 10)) > 0.01 or not b.wrecks.is_empty():
		return "쓰러진 몸 %s(늑대 하나, (10,10)) · 수레 잔해 %d(0)" % [lying.map(func(f): return [f.who.kind, f.who.pos]), b.wrecks.size()]
	b.damage(e, BIG, "true")
	return check(not e.alive and b.gold == gold + 8, "내린 장갑에 큰 고정 피해: 살아 있다 %s · 골드 %d(처음 %d + 8)" % [e.alive, b.gold, gold])

# EV970 · I279: 늑대 기수는 제 그림 한 장이고 누운 그림이 없다. 내리면 늑대의 쓰러진 몸을 그리고 몸통은 장갑 그림이 된다. 던져진 슬라임은 포물선으로 들어 올려 그린다
func ev970():
	var b = battle({"base_hp": BIG})
	var why := _need(b, [OT, WR])
	if why != "":
		return why
	var v = _rec(b)
	var got := {}
	var n := 0
	for k in [WR, "wolf", "armored"]:
		var one = _cut(v, _still(b, k, Vector2(3 + n * 3, 5), {"hp": 100.0}))
		n += 1
		if one == null:
			var cuts: int = v.cuts.size()
			v.free()
			return "%s 몸통이 그림 한 장이 아니다(%d장)" % [k, cuts]
		got[k] = one
	var art: Dictionary = v.ART.get(WR, {})
	if got[WR][1] == got["wolf"][1] or got[WR][1] == got["armored"][1] or not (art.has("idle") and art.has("walk") and art.has("attack")) or art.has("fall"):
		v.free()
		return "늑대 기수 원본 사각형 %s(늑대 %s · 장갑 %s와 달라야 한다) · 그림 칸 %s(idle·walk·attack만)" % [got[WR][1], got["wolf"][1], got["armored"][1], art.keys()]
	var r = _still(b, WR, Vector2(20, 5), {"hp": 10})
	b.damage(r, 50.0, "true")
	var lying: Array = v._fallen().filter(func(d): return d[0].kind == "wolf")
	var after = _cut(v, r)
	v.free()
	if lying.size() != 1 or after == null or after[1] != got["armored"][1]:
		return "내린 뒤: 그릴 늑대의 쓰러진 몸 %d(1) · 몸통 %s(장갑 원본 사각형 %s)" % [lying.size(), after, got["armored"][1]]
	var g := _throw("slime", STILL)
	var t = g[1]
	var s = g[2]
	if not _ever(g[0], t, "hurl", 0.1):
		return "0.1초 안에 던지기 예고를 시작하지 않았다(cast %s)" % [t.cast]
	var w = _rec(g[0])
	var low = _cut(w, s)
	run(g[0], 1.5, func(): return _flying(s))
	_steps(g[0], 4)
	var high = _cut(w, s) if _flying(s) else null
	w.free()
	return check(low != null and high != null and high[0].position.y < low[0].position.y,
		"던져진 슬라임: 예고를 시작한 스텝의 그림 %s · 뜬 지 0.2초의 그림 %s(위끝이 더 위여야 한다)" % [low, high])

# ── 묶음 ③: 대족장 근위대(S339) · 오크 대족장(S340) · 내린 대족장(S341) ──

# 치지 않는 영웅 kind(레벨 5, 체력 큼) 하나를 cell에 세운 들판 판. 웨이브는 적이 나오지 않는 것 둘이라, 판에 적을 두고 전투를 열면 적이 남아 있는 동안 이어진다. [판, 영웅]
func _lone(kind: String, cell: Vector2i, stage := {}) -> Array:
	var none := [{"kind": "basic", "count": 0}]
	var b = battle({"base_hp": BIG, "waves": [none, none], "heroes": [{"kind": kind, "cell": cell, "level": 5}]}.merged(stage, true))
	var h = b.heroes[0]
	h.damage = 0.0
	h.max_hp = BIG
	h.hp = BIG
	return [b, h]

# 아이아스를 (10,10)에 세우고 kind 과녁을 (11,10)에 둔 판에서 요새화된 뒤 Q를 동쪽으로 쓴다. [과녁이 동쪽으로 옮겨진 칸, 과녁에 기절이 걸렸나]
func _bashed(kind: String) -> Array:
	var r := _lone("aias", Vector2i(10, 10))
	var b = r[0]
	var k = r[1]
	var e = _still(b, kind, Vector2(11, 10))
	b.start_battle()
	run(b, k.passive.still + 0.3)
	var x0: float = e.pos.x
	b.cast(k, "q", Vector2(13, 10))
	return [e.pos.x - x0, b.effect(e, "stun") != null, k.fort]

# EV985 · S339: 대족장 근위대는 끌어당김(이그니스 E 중력장)과 넉백(요새화한 아이아스 Q)에 자리가 그대로다. 마법 저항 감소·기절은 걸린다. 장갑은 끌려오고 밀린다
func ev985():
	var r := _lone("ignis", Vector2i(10, 10))
	var b = r[0]
	var g = r[1]
	var why := _need(b, [WG])
	if why != "":
		return why
	var mid := Vector2(14, 10)
	var orc = _still(b, "armored", Vector2(14, 12))
	var guard = _still(b, WG, Vector2(14, 8))
	b.start_battle()
	if not b.cast(g, "e", mid):
		return "이그니스가 E 중력장을 쓰지 못했다"
	run(b, 1.0)
	var pulled: float = 2.0 - orc.pos.distance_to(mid)
	var stayed: float = guard.pos.distance_to(Vector2(14, 8))
	if absf(pulled - g.e.pull) > 0.1 or stayed > 0.001 or b.effect(guard, "mr") == null or b.effect(orc, "mr") == null:
		return "중력장 1초: 장갑이 끌려온 칸 %.2f(%s) · 근위대가 옮겨진 칸 %.3f(0) · 마법 저항 감소 근위대 %s·장갑 %s(둘 다 걸려야 한다)" % [pulled, g.e.pull, stayed, b.effect(guard, "mr") != null, b.effect(orc, "mr") != null]
	var hit := [_bashed("armored"), _bashed(WG)]
	return check(hit[0][2] and hit[1][2] and hit[0][0] >= 0.9 and absf(hit[1][0]) <= 0.001 and hit[0][1] and hit[1][1],
		"요새화한 아이아스 Q [밀린 칸, 기절, 요새화]: 장갑 %s(0.9칸 이상, 기절) · 근위대 %s(0칸, 기절)" % hit)

# EV986 · S340: 오크 대족장은 나올 때 근위대 넷을 호위로 데려온다. 직선 돌진은 2칸 넘게 떨어진 가장 가까운 땅 위 아군 쪽 직선 예고 1초 뒤 7칸을 달려,
# 길 위 아군에 물리 30을 주고 길 옆으로 1칸 민다
func ev986():
	var b = battle({"spawns": THREE, "base_hp": BIG, "waves": [[{"kind": WC, "count": 1, "front": 1}]]})
	var why := _need(b, [WC, WG, WF])
	if why != "":
		return why
	var counts: Array = b.spawn_counts(0, 0)
	b.start_battle()
	run(b, 1.0, func(): return not b.enemies.is_empty())
	var born: Array = b.enemies.map(func(e): return [e.kind, cell_of(e)])
	var chief: Array = born.filter(func(o): return o[0] == WC)
	var guards: Array = born.filter(func(o): return o[0] == WG).map(func(o): return o[1])
	guards.sort()
	if counts != [{}, {WC: 1, WG: 4}, {}] or born.size() != 5 or chief.size() != 1 or chief[0][1] != Vector2i(15, 18) or guards != [Vector2i(13, 19), Vector2i(14, 19), Vector2i(16, 19), Vector2i(17, 19)]:
		return "미리보기 수 %s([{}, {warchief 1, warguard 4}, {}]) · 첫 스텝에 나온 적 %s(대족장 (15,18), 근위대 (13·14·16·17, 19))" % [counts, born]
	var c = battle({"base_hp": BIG})
	var e = _still(c, WC, Vector2(10, 10))
	var near = c.place_merc("soldier", Vector2i(11, 10), QUIET)  # 2칸 안: 돌진 대상이 아니다
	var m = c.place_merc("soldier", Vector2i(14, 10), QUIET)
	if not _ever(c, e, "charge", 0.1) or absf(e.cast.dir) > 0.01 or e.cast.to.distance_to(Vector2(17, 10)) > 0.3:
		return "0.1초 안에 (14,10) 병사 쪽 돌진 예고를 시작하지 않았다(cast %s — dir 0, to (17,10))" % [e.cast]
	_steps(c, 18)
	if e.pos.distance_to(Vector2(10, 10)) > 0.05 or m.hp != m.max_hp:
		return "예고 0.9초: 대족장 자리 %s((10,10)) · 병사가 잃은 체력 %s(0)" % [e.pos, _lost(m)]
	_steps(c, 4)
	var want: float = 30.0 * c.armor_mult(c.armor_of(m))
	return check(e.pos.distance_to(Vector2(17, 10)) <= 0.3 and absf(_lost(m) - want) <= 0.01 and absf(absf(m.pos.y - 10.0) - 1.0) <= 0.1 and absf(m.pos.x - 14.0) <= 0.1
		and absf(_lost(near) - want) <= 0.01 and absf(e.cd.get("charge", 0.0) - 9.9) <= 0.11,
		"예고 1.1초: 대족장 자리 %s((17,10)) · (14,10) 병사가 잃은 체력 %s(%s) · 병사 자리 %s(길 옆 1칸) · (11,10) 병사가 잃은 체력 %s(%s) · 돌진 대기 %s(10초에서 줄기 시작)" % [e.pos, _lost(m), want, m.pos, _lost(near), want, e.cd.get("charge")])

# 오크 대족장(움직이지도 치지도 않음, 돌진은 대기 중)을 (10,10)에, 실비아(치지 않음)를 hero 칸에 둔 판. [판, 대족장, 실비아]
func _snag(hero: Vector2i) -> Array:
	var r := _lone("sylvia", hero)
	var e = _still(r[0], WC, Vector2(10, 10)) if r[0].ENEMY_KINDS.has(WC) else null
	if e != null:
		e.cd["charge"] = BIG
	return [r[0], e, r[1]]

# EV987 · S340 ②: 사슬 갈고리는 1.5칸 넘고 6칸 안의 땅 위 영웅 쪽 직선 예고 1초 뒤 띠 안의 가장 가까운 영웅을 대족장 앞 1.2칸으로 끌어와 15를 주고 1.5초 기절시킨다.
# 띠 안의 병사는 맞지 않는다. 영웅이 띠에서 비키면 빗나가고, 영웅이 없으면 던지지 않으며, 예고 중 기절하면 취소되고 비틀거린다
func ev987():
	var g := _snag(Vector2i(14, 10))
	var b = g[0]
	var why := _need(b, [WC])
	if why != "":
		return why
	var e = g[1]
	var h = g[2]
	var m = b.place_merc("soldier", Vector2i(12, 10), QUIET)  # 띠 안, 영웅보다 가깝다
	if not _ever(b, e, "chain", 0.1) or absf(e.cast.dir) > 0.01 or e.cast.to.distance_to(Vector2(16, 10)) > 0.3:
		return "0.1초 안에 실비아 쪽 사슬 예고를 시작하지 않았다(cast %s — dir 0, to (16,10))" % [e.cast]
	_steps(b, 18)
	if h.pos.distance_to(Vector2(14, 10)) > 0.05 or h.hp != h.max_hp:
		return "예고 0.9초: 실비아 자리 %s((14,10)) · 잃은 체력 %s(0)" % [h.pos, _lost(h)]
	_steps(b, 4)
	var want: float = 15.0 * b.armor_mult(b.armor_of(h))
	if h.pos.distance_to(Vector2(11.2, 10)) > 0.15 or absf(_lost(h) - want) > 0.01 or b.effect(h, "stun") == null or m.hp != m.max_hp or m.pos.distance_to(Vector2(12, 10)) > 0.05 or e.snag != h:
		return "예고 1.1초: 실비아 자리 %s((11.2,10)) · 잃은 체력 %s(%s) · 기절 %s · 병사가 잃은 체력 %s(0)·자리 %s((12,10)) · 사슬 끝이 실비아다 %s" % [h.pos, _lost(h), want, b.effect(h, "stun") != null, _lost(m), m.pos, e.snag == h]
	_steps(b, 20)
	var held: bool = b.effect(h, "stun") != null
	_steps(b, 14)
	if not held or b.effect(h, "stun") != null:
		return "맞은 뒤 1.1초에 기절 %s(걸려 있어야 한다) · 1.8초에 기절 %s(풀려야 한다)" % [held, b.effect(h, "stun") != null]
	var dodge := _snag(Vector2i(14, 10))
	if not _ever(dodge[0], dodge[1], "chain", 0.1):
		return "비키는 판: 0.1초 안에 사슬 예고를 시작하지 않았다"
	_steps(dodge[0], 10)
	dodge[2].pos = Vector2(14, 12)
	dodge[2].anchor = Vector2(14, 12)
	_steps(dodge[0], 12)
	if dodge[2].hp != dodge[2].max_hp or dodge[2].pos.distance_to(Vector2(14, 12)) > 0.05 or not dodge[1].snag is Vector2:
		return "띠에서 비킨 실비아: 잃은 체력 %s(0) · 자리 %s((14,12)) · 사슬 끝 %s(띠 끝 자리여야 한다)" % [_lost(dodge[2]), dodge[2].pos, dodge[1].snag]
	var none = battle({"base_hp": BIG})
	var lone = _still(none, WC, Vector2(10, 10))
	lone.cd["charge"] = BIG
	none.place_merc("soldier", Vector2i(14, 10), QUIET)
	if _ever(none, lone, "chain", 3.0):
		return "영웅 없이 병사만 있는데 사슬 예고를 띄웠다(cast %s)" % [lone.cast]
	var cut := _snag(Vector2i(14, 10))
	if not _ever(cut[0], cut[1], "chain", 0.1):
		return "끊는 판: 0.1초 안에 사슬 예고를 시작하지 않았다"
	_steps(cut[0], 10)
	cut[1].fx["test_stun"] = {"stun": true, "left": 0.5}
	cut[0].step(DT)
	var off: bool = cut[1].cast == null and cut[1].fx.has("stagger")
	_steps(cut[0], 30)
	return check(off and cut[2].hp == cut[2].max_hp and cut[2].pos.distance_to(Vector2(14, 10)) <= 0.05,
		"예고 중 기절: 다음 스텝에 예고 없음·비틀거림 %s · 그 뒤 1.5초 실비아가 잃은 체력 %s(0)·자리 %s((14,10))" % [off, _lost(cut[2]), cut[2].pos])

# EV988 · S340 ③: 체력이 0이 되면 쓰러지지 않고 내린 대족장이 된다. 체력은 가득, 효과는 비고, 먼저 노리던 성문은 그대로이며 그 자리에 늑대의 쓰러진 몸이 남는다.
# 내리자마자 군단 호출 예고를 띄우고, 내린 대족장을 처치하면 골드 50을 받는다
func ev988():
	var b = battle({"base_hp": BIG, "hp_mult": [1.5]})
	var why := _need(b, [WC, WF])
	if why != "":
		return why
	var e = _still(b, WC, Vector2(10, 10), {"hp": 10})
	e.via = Vector2i(12, 10)
	e.fx["test"] = {"slow": 0.5, "left": 10.0}
	var gold: int = b.gold
	b.damage(e, 50.0, "true")
	if not e.alive or e.kind != WF or b.enemies.size() != 1 or not e.boss:
		return "고정 피해 50 뒤: 살아 있다 %s · 종류 %s(warchief_foot) · 적 수 %d(1) · 보스 %s" % [e.alive, e.kind, b.enemies.size(), e.boss]
	var body: bool = is_equal_approx(e.hp, 360.0) and is_equal_approx(e.max_hp, 360.0) and is_equal_approx(e.armor, 10.0) and is_equal_approx(e.speed, 1.2) and is_equal_approx(e.radius, 0.9)
	if not body or not e.fx.is_empty() or e.via != Vector2i(12, 10) or b.gold != gold or e.cast != null:
		return "내린 대족장: 체력 %s/%s(360) · 방어력 %s(10) · 속도 %s(1.2) · 몸 반지름 %s(0.9) · 효과 %s(없음) · via %s((12,10)) · 골드 %d(처음 %d) · 예고 %s(없음)" % [e.hp, e.max_hp, e.armor, e.speed, e.radius, e.fx, e.via, b.gold, gold, e.cast]
	var lying: Array = b.fallen
	if lying.size() != 1 or lying[0].who.kind != "wolf" or lying[0].who.pos.distance_to(Vector2(10, 10)) > 0.01 or not b.wrecks.is_empty():
		return "쓰러진 몸 %s(늑대 하나, (10,10)) · 수레 잔해 %d(0)" % [lying.map(func(f): return [f.who.kind, f.who.pos]), b.wrecks.size()]
	b.step(DT)
	if not _casting(e, "horn"):
		return "내린 다음 스텝에 군단 호출 예고를 띄우지 않았다(cast %s)" % [e.cast]
	b.damage(e, BIG, "true")
	return check(not e.alive and b.gold == gold + 50, "내린 대족장에 큰 고정 피해: 살아 있다 %s · 골드 %d(처음 %d + 50)" % [e.alive, b.gold, gold])

# 출현 지점 셋인 들판 판에 내린 대족장(움직이지도 치지도 않음)을 (15,5)에 둔다. [판, 대족장]
func _caller() -> Array:
	var b = battle({"spawns": THREE, "base_hp": BIG})
	return [b, _still(b, WF, Vector2(15, 5)) if b.ENEMY_KINDS.has(WF) else null]

# EV989 · S341 ①: 군단 호출은 예고 2.5초 뒤 출현 지점마다 부대(왼쪽 늑대 8·가운데 장갑 4·오른쪽 비행 8)를 한꺼번에 낸다. 부른 적은 처치 보상·경험치가 0이다.
# 세 번 부른 대족장은 더 부르지 않고, 봉인되면 시작하지 않으며, 예고 중 기절하면 부대가 나오지 않고 횟수도 세지 않는다
func ev989():
	var g := _caller()
	var b = g[0]
	var why := _need(b, [WF])
	if why != "":
		return why
	var e = g[1]
	var gold: int = b.gold
	if not _ever(b, e, "horn", 0.1) or absf(e.cast.left - 2.5) > 0.11:
		return "0.1초 안에 군단 호출 예고(2.5초)를 시작하지 않았다(cast %s)" % [e.cast]
	_steps(b, 46)
	if b.enemies.size() != 1 or b.horns != 0:
		return "예고 2.3초: 적 수 %d(1) · 부대가 나온 횟수 %d(0)" % [b.enemies.size(), b.horns]
	_steps(b, 6)
	var squads: Array = THREE.map(func(s): return b.enemies.filter(func(x): return x != e and absf(x.pos.x - s.x) <= 4.0 and x.pos.y >= 15.0).map(func(x): return x.kind))
	var called: Array = b.enemies.filter(func(x): return x != e)
	var want := [["wolf", 8], ["armored", 4], ["flying", 8]]
	var same: bool = range(3).all(func(i): return squads[i].size() == want[i][1] and squads[i].all(func(k): return k == want[i][0]))
	if not same or called.size() != 20 or called.any(func(x): return x.reward != 0 or x.xp != 0) or b.horns != 1 or e.calls != 1 or e.cast != null:
		return "예고 2.6초: 출현 지점마다 나온 종류 %s(늑대 8 · 장갑 4 · 비행 8) · 부른 적 %d(20) · 보상·경험치가 0이 아닌 적 %d · 판 횟수 %d(1) · 대족장 횟수 %d(1) · 예고 %s(없음)" % [squads, called.size(), called.filter(func(x): return x.reward != 0 or x.xp != 0).size(), b.horns, e.calls, e.cast]
	for x in called:
		b.damage(x, BIG, "true")
	if b.gold != gold:
		return "부른 적 20을 처치한 뒤 골드 %d(처음 %d 그대로여야 한다)" % [b.gold, gold]
	if _ever(b, e, "horn", 5.0):
		return "부른 뒤 5초 안에 다시 군단 호출 예고를 띄웠다(대기 30초)"
	var full := _caller()
	full[1].calls = 3
	var shut := _caller()
	shut[1].fx["test_seal"] = {"seal": true, "left": BIG}
	if _ever(full[0], full[1], "horn", 3.0) or _ever(shut[0], shut[1], "horn", 3.0):
		return "세 번 부른 대족장 예고 %s · 봉인된 대족장 예고 %s(둘 다 3초 동안 없어야 한다)" % [full[1].cast, shut[1].cast]
	var cut := _caller()
	if not _ever(cut[0], cut[1], "horn", 0.1):
		return "끊는 판: 0.1초 안에 군단 호출 예고를 시작하지 않았다"
	_steps(cut[0], 20)
	cut[1].fx["test_stun"] = {"stun": true, "left": 0.5}
	cut[0].step(DT)
	var off: bool = cut[1].cast == null and cut[1].fx.has("stagger")
	var again := false
	for i in 100:
		cut[0].step(DT)
		again = again or _casting(cut[1], "horn")
	return check(off and not again and cut[0].enemies.size() == 1 and cut[1].calls == 0 and cut[0].horns == 0,
		"예고 중 기절: 다음 스텝에 예고 없음·비틀거림 %s · 그 뒤 5초 안에 다시 예고 %s(없어야 한다) · 적 수 %d(1) · 대족장 횟수 %d(0) · 판 횟수 %d(0)" % [off, again, cut[0].enemies.size(), cut[1].calls, cut[0].horns])

# EV990 · S341 ②: 균열은 6칸 안 땅 위 아군의 자리를 유닛 차례로, 앞서 고른 자리와 1.5칸 넘게 떨어진 것만 네 곳까지 골라 원(반경 1.2)을 예고하고,
# 1.2초 뒤 원 안 땅 위 아군에 물리 30을 준다. 원 밖 아군과 원 안 구조물은 맞지 않는다
func ev990():
	var b = battle({"base_hp": BIG})
	var why := _need(b, [WF])
	if why != "":
		return why
	var e = _still(b, WF, Vector2(10, 10))
	e.cd["horn"] = BIG
	var tower = b.build("tower", Vector2i(14, 10), {"damage": 0})
	var cells := [Vector2i(13, 10), Vector2i(13, 11), Vector2i(10, 14), Vector2i(6, 10), Vector2i(12, 13), Vector2i(8, 12)]
	var ms: Array = cells.map(func(c): return b.place_merc("soldier", c, QUIET))
	b.start_battle()
	if not _ever(b, e, "rift", 0.1):
		return "0.1초 안에 균열 예고를 시작하지 않았다(cast %s)" % [e.cast]
	var spots: Array = e.cast.get("spots", [])
	var picked := [0, 2, 3, 4].map(func(i): return Vector2(cells[i]))
	if spots.size() != 4 or range(4).any(func(i): return spots[i].distance_to(picked[i]) > 0.05):
		return "균열 자리 %s(%s여야 한다)" % [spots, picked]
	_steps(b, 22)
	if ms.any(func(m): return m.hp != m.max_hp):
		return "예고 1.1초에 벌써 체력을 잃은 병사가 있다 %s" % [ms.map(func(m): return _lost(m))]
	_steps(b, 4)
	var want: float = 30.0 * b.armor_mult(b.armor_of(ms[0]))
	var lost: Array = ms.map(func(m): return _lost(m))
	var hit: bool = [0, 1, 2, 3, 4].all(func(i): return absf(lost[i] - want) <= 0.01)
	return check(hit and lost[5] == 0.0 and tower != null and tower.hp == tower.max_hp and e.cast == null,
		"예고 1.3초: 병사들이 잃은 체력 %s(앞 다섯은 %s, 마지막은 0) · 궁수탑 체력 %s/%s(그대로) · 예고 %s(없음)" % [lost, want, tower.hp if tower else null, tower.max_hp if tower else null, e.cast])

# EV991 · I282: 오크 대족장은 늑대 기수 그림, 근위대와 내린 대족장은 장갑 그림에 색을 곱해 그리고, 대족장 둘은 2배로 그린다. 사슬 예고는 띠 테두리 선 넷이고
# 던진 사슬은 대족장에서 끌려온 영웅까지 선이다. 균열 예고는 대족장이 어둠 속에 숨어도 그리고, 사슬 예고는 숨으면 그리지 않는다. 뿔나팔 원의 색은 금색이다
func ev991():
	var b = battle({"base_hp": BIG})
	var why := _need(b, [WR, WG, WC, WF])
	if why != "":
		return why
	var v = _rec(b)
	var hues: Dictionary = v.TELL_HUES
	v.free()
	if not hues.has(b.ENEMY_KINDS[WF].skills.horn.get("color", "")):
		return "내린 대족장 뿔나팔 색 %s(예고 색 표에 있어야 한다)" % [b.ENEMY_KINDS[WF].skills.horn.get("color")]
	var s := _snag(Vector2i(14, 10))
	var e = s[1]
	var h = s[2]
	if not _ever(s[0], e, "chain", 0.1):
		return "0.1초 안에 사슬 예고를 시작하지 않았다(cast %s)" % [e.cast]
	var u = _rec(s[0])
	u.clock = 0.0
	u._foes = u.foes()
	u._tells()
	var rim: int = u.lines.size()
	var red: bool = u.tell_color(e) == u.TELL
	run(s[0], 1.5, func(): return e.cast == null)
	u.lines = []
	u._chain_links()
	var from: Vector2 = u._center(e.pos)
	var to: Vector2 = u._center(h.pos)
	var link: bool = u.lines.any(func(l): return Vector2(l[0]).distance_to(from) <= 12.0 and Vector2(l[1]).distance_to(to) <= 24.0)
	u.free()
	if rim != 4 or not red or not link:
		return "사슬 예고 선 %d(4) · 보스 예고 색 %s · 던진 사슬 선(대족장 → 끌려온 영웅) %s" % [rim, red, link]
	var dark := _lone("sylvia", Vector2i(10, 10), {"nights": NIGHT, "waves": [ONE]})
	var nb = dark[0]
	nb.place_merc("soldier", Vector2i(10, 14), QUIET)
	_start(nb)
	run(nb, 1.0)
	var x = _still(nb, WF, Vector2(15, 14))  # 병사에게서 5칸: 병사 불빛(3.5칸) 밖이고 균열 거리(6칸) 안
	x.cd["horn"] = BIG
	var y = _still(nb, WC, Vector2(15, 10))  # 실비아에게서 5칸: 영웅 불빛(2.5칸) 밖이고 사슬 거리(6칸) 안
	y.cd["charge"] = BIG
	_steps(nb, 2)
	if nb.dark < 1.0 or nb.seen(x.pos) or nb.seen(y.pos) or not _casting(x, "rift") or not _casting(y, "chain"):
		return "시험 조건이 틀렸다: 어둠 %.2f · 내린 대족장이 보인다 %s · 대족장이 보인다 %s · 예고 %s / %s" % [nb.dark, nb.seen(x.pos), nb.seen(y.pos), x.cast, y.cast]
	var nv = _rec(nb)
	var tell: Array = nv.tellers()
	var hid := [x in tell, y not in tell]
	nv.free()
	return check(hid[0] and hid[1], "밤 판: 숨은 내린 대족장의 균열 예고를 그림 %s(그려야 한다) · 숨은 대족장의 사슬 예고를 안 그림 %s(그리지 않아야 한다)" % hid)

# ── 오크 대족장의 새 기믹(S344~S350, I285) ──

const NONE := [{"kind": "basic", "count": 0}]  # 적이 나오지 않는 웨이브

# 치지 않는 영웅들(레벨 5, 체력 큼)을 [종류, 칸]대로 세운 들판 판. 영웅은 제자리에서 움직이지 않는다
func _team(heroes: Array, stage := {}):
	var b = battle({"base_hp": BIG, "waves": [NONE, NONE], "heroes": heroes.map(func(h): return {"kind": h[0], "cell": h[1], "level": 5})}.merged(stage, true))
	for h in b.heroes:
		h.damage = 0.0
		h.max_hp = BIG
		h.hp = BIG
	return b

# kind 대족장(움직이지도 치지도 않음, 최대 체력 hp)을 (10,10)에 두고 only 스킬만 바로 쓸 수 있게 한다(나머지 스킬은 대기를 크게 둔다)
func _chief(b, kind: String, only: String, hp := 1000.0):
	var e = _still(b, kind, Vector2(10, 10), {"hp": hp})
	for id in e.skills:
		e.cd[id] = 0.0 if id == only else float(BIG)
	return e

# EV1014 · S344: 결투 신청은 5칸 안의 가장 가까운 땅 위 영웅을 지목해 예고 1.2초 뒤 결투장(반경 2.5)을 연다. 8초 동안 그 영웅은 원 밖으로 못 나가고,
# 원 밖에서 준 피해는 80% 줄며, 대족장은 새 스킬을 시작하지 않는다. 지목된 영웅이 최대 체력의 5%를 깎으면 대족장이 비틀거리고, 못 깎으면 영웅이 40을 받는다
func ev1014():
	var b = _team([["sylvia", Vector2i(12, 10)], ["ignis", Vector2i(14, 10)]])
	var why := _need(b, [WC])
	if why != "":
		return why
	var e = _chief(b, WC, "duel")
	var h = b.heroes[0]
	var m = b.place_merc("soldier", Vector2i(20, 10), QUIET)
	if not _ever(b, e, "duel", 0.1) or e.cast.get("who") != h or e.cast.at.distance_to(Vector2(10, 10)) > 0.05:
		return "0.1초 안에 실비아를 지목한 결투 예고를 시작하지 않았다(cast %s)" % [e.cast]
	_steps(b, 22)
	if not _casting(e, "duel") or not e.duel.is_empty():
		return "예고 1.1초에 벌써 결투가 열렸다(cast %s · duel %s)" % [e.cast, e.duel]
	_steps(b, 4)
	var d: Dictionary = e.duel
	if d.is_empty() or d.who != h or absf(d.radius - 2.5) > 0.001 or absf(d.left - 8.0) > 0.21 or absf(d.need - 50.0) > 0.01:
		return "예고 1.3초: 결투 %s(실비아, 반경 2.5, 남은 초 8, 깎아야 할 체력 50)" % [d]
	h.pos = Vector2(16, 10)
	b.step(DT)
	if absf(h.pos.distance_to(Vector2(10, 10)) - 2.5) > 0.01:
		return "결투장 밖 (16,10)으로 옮긴 실비아가 다음 스텝에 가운데에서 %.2f칸이다(2.5칸이어야 한다)" % h.pos.distance_to(Vector2(10, 10))
	e.cd["chain"] = 0.0
	var hp0: float = e.hp
	b.damage(e, 100.0, "true", m)
	var outside: float = hp0 - e.hp
	b.damage(e, 100.0, "true")
	var nobody: float = hp0 - e.hp - outside
	_steps(b, 20)
	if absf(outside - 20.0) > 0.01 or absf(nobody - 20.0) > 0.01 or _casting(e, "chain") or e.duel.is_empty():
		return "결투 중: 원 밖 병사가 준 고정 피해 100에 %s(20) · 출처 없는 100에 %s(20) · 사슬 예고 %s(없어야 한다) · 결투 %s(이어져야 한다)" % [outside, nobody, e.cast, e.duel]
	hp0 = e.hp
	b.damage(e, 100.0, "true", h)
	var inside: float = hp0 - e.hp
	b.step(DT)
	if absf(inside - 100.0) > 0.01 or not e.duel.is_empty() or not e.fx.has("stagger") or h.hp != h.max_hp:
		return "결투 상대가 준 고정 피해 100에 %s(100) · 다음 스텝 결투 %s(끝나야 한다) · 비틀거림 %s · 실비아가 잃은 체력 %s(0)" % [inside, e.duel, e.fx.has("stagger"), _lost(h)]
	var c = _team([["sylvia", Vector2i(12, 10)]])
	var x = _chief(c, WC, "duel")
	var k = c.heroes[0]
	if not _ever(c, x, "duel", 0.1):
		return "둘째 판: 0.1초 안에 결투 예고를 시작하지 않았다"
	_steps(c, 26)
	_steps(c, 150)
	if x.duel.is_empty() or k.hp != k.max_hp:
		return "둘째 판: 결투 7.5초에 결투 %s(이어져야 한다) · 실비아가 잃은 체력 %s(0)" % [x.duel, _lost(k)]
	_steps(c, 14)
	var want: float = 40.0 * c.armor_mult(c.armor_of(k))
	if not x.duel.is_empty() or absf(_lost(k) - want) > 0.01 or x.fx.has("stagger"):
		return "둘째 판: 결투 8.2초에 결투 %s(끝나야 한다) · 실비아가 잃은 체력 %s(%s) · 비틀거림 %s(없어야 한다)" % [x.duel, _lost(k), want, x.fx.has("stagger")]
	var f = _team([["sylvia", Vector2i(12, 10)]])
	var y = _chief(f, WC, "duel")
	if not _ever(f, y, "duel", 0.1):
		return "셋째 판: 0.1초 안에 결투 예고를 시작하지 않았다"
	f.heroes[0].pos = Vector2(14, 10)
	f.heroes[0].anchor = Vector2(14, 10)
	_steps(f, 26)
	return check(y.duel.is_empty() and y.cast == null, "셋째 판: 예고 중에 원 밖 (14,10)으로 비킨 뒤 결투 %s(열리지 않아야 한다) · 예고 %s" % [y.duel, y.cast])

# EV1015 · S345: 군령은 예고 2초 뒤 전장의 모든 적에게 8초 걸린다. 첫 군령은 돌격령(이동·공격 속도 +30%), 둘째는 방패령(투사체 피해 −50%)이다.
# 군령이 내려진 뒤 나온 적도 받는다. 예고 중 기절하면 내려지지 않는다
func ev1015():
	var b = battle({"base_hp": BIG, "base": Vector2i(28, 2)})
	var why := _need(b, [WC])
	if why != "":
		return why
	var e = _chief(b, WC, "order")
	var walker = b.spawn_enemy("basic", Vector2i(2, 18), {"sight": 0, "damage": 0, "hp": BIG})
	if not _ever(b, e, "order", 0.1) or absf(e.cast.left - 2.0) > 0.11:
		return "0.1초 안에 군령 예고(2초)를 시작하지 않았다(cast %s)" % [e.cast]
	var slow := _walked(b, walker)
	_steps(b, 22)
	if b.edict.get("kind") != "rush" or absf(b.edict.left - 8.0) > 0.21 or b.edicts != 1 or e.orders != 1:
		return "예고 2.1초: 군령 %s(rush, 남은 초 8) · 판 횟수 %d(1) · 대족장 횟수 %d(1)" % [b.edict, b.edicts, e.orders]
	var fast := _walked(b, walker)
	var late = b.spawn_enemy("basic", Vector2i(2, 16), {"sight": 0, "damage": 0, "hp": BIG})
	var newer := _walked(b, late)
	walker.cooldown = 10.0
	_steps(b, 20)
	var beat: float = 10.0 - walker.cooldown
	if not _ratio(fast, slow, 1.3) or not _ratio(newer, slow, 1.3) or absf(beat - 1.3) > 0.03:
		return "돌격령: 1초에 걸은 칸 %.2f(전 %.2f의 1.3배) · 뒤에 나온 적 %.2f(1.3배) · 1초에 준 공격 대기 %.3f(1.3)" % [fast, slow, newer, beat]
	_steps(b, 120)
	if not b.edict.is_empty():
		return "군령이 내려진 뒤 9초: 군령 %s(없어야 한다)" % [b.edict]
	var c = battle({"base_hp": BIG})
	var x = _chief(c, WC, "order")
	var prey = _still(c, "basic", Vector2(22, 16))
	var bow = c.place_merc("archer", Vector2i(20, 16), SHOT)
	var bare := _drop(c, [prey])
	x.orders = 1
	if not _ever(c, x, "order", 3.0):
		return "둘째 판: 군령 예고를 시작하지 않았다"
	_steps(c, 42)
	if c.edict.get("kind") != "shield":
		return "둘째 판: 대족장의 둘째 군령이 %s다(shield여야 한다)" % [c.edict]
	var covered := _drop(c, [prey])
	if absf(bare - 10.0) > 0.01 or absf(covered - 5.0) > 0.01:
		return "방패령: 궁수 화살 피해 %s(전 %s의 절반 5)" % [covered, bare]
	var f = battle({"base_hp": BIG})
	var y = _chief(f, WC, "order")
	if not _ever(f, y, "order", 0.1):
		return "셋째 판: 0.1초 안에 군령 예고를 시작하지 않았다"
	_steps(f, 20)
	y.fx["test_stun"] = {"stun": true, "left": 0.5}
	f.step(DT)
	var off: bool = y.cast == null and y.fx.has("stagger")
	_steps(f, 40)
	return check(off and f.edict.is_empty() and f.edicts == 0 and y.orders == 0, "예고 중 기절: 다음 스텝에 예고 없음·비틀거림 %s · 2초 뒤 군령 %s(없음) · 횟수 %d·%d(0)" % [off, f.edict, f.edicts, y.orders])

# EV1016 · S346: 사슬 족쇄는 6칸 안의 땅 위 영웅 둘의 자리에 원(반경 0.8) 예고 1초 뒤 둘을 10초 묶는다. 묶인 둘은 4칸 넘게 떨어지지 못하고,
# 한쪽이 받은 피해의 절반을 다른 쪽도 받는다. 하나가 풀리면 함께 풀리고, 하나라도 원에서 비키면 묶이지 않으며, 영웅이 하나뿐이면 쓰지 않는다
func ev1016():
	var b = _team([["sylvia", Vector2i(12, 10)], ["ignis", Vector2i(10, 13)]])
	var why := _need(b, [WC])
	if why != "":
		return why
	var e = _chief(b, WC, "shackle")
	var a = b.heroes[0]
	var c = b.heroes[1]
	if not _ever(b, e, "shackle", 0.1) or e.cast.get("spots", []).size() != 2 or e.cast.spots[0].distance_to(Vector2(12, 10)) > 0.05 or e.cast.spots[1].distance_to(Vector2(10, 13)) > 0.05:
		return "0.1초 안에 두 영웅 자리에 사슬 족쇄 예고를 시작하지 않았다(cast %s)" % [e.cast]
	_steps(b, 18)
	if a.fx.has("shackle") or c.fx.has("shackle"):
		return "예고 0.9초에 벌써 묶였다"
	_steps(b, 4)
	var ya = a.fx.get("shackle", {})
	var yc = c.fx.get("shackle", {})
	if ya.get("shackle") != c or yc.get("shackle") != a or absf(ya.get("left", 0.0) - 10.0) > 0.21:
		return "예고 1.1초: 실비아의 족쇄 %s · 이그니스의 족쇄 %s(서로를 가리키고 남은 초 10)" % [ya, yc]
	var before: Array = [a.hp, c.hp]
	b.damage(a, 20.0)
	var lost_a: float = before[0] - a.hp
	var lost_c: float = before[1] - c.hp
	var want: float = lost_a * 0.5 * b.armor_mult(b.armor_of(c))
	if lost_a <= 0.0 or absf(lost_c - want) > 0.01:
		return "실비아가 피해 20에 %s를 잃을 때 이그니스가 잃은 체력 %s(%s)" % [lost_a, lost_c, want]
	a.pos = Vector2(20, 10)
	a.anchor = Vector2(20, 10)
	b.step(DT)
	if absf(a.pos.distance_to(c.pos) - 4.0) > 0.1:
		return "실비아를 (20,10)으로 옮긴 다음 스텝에 둘 사이 %.2f칸(4칸이어야 한다)" % a.pos.distance_to(c.pos)
	if not b._harmful({"shackle": c}):
		return "족쇄가 해로운 효과(정화가 지우는 효과)가 아니다"
	a.fx.erase("shackle")
	b.step(DT)
	if c.fx.has("shackle"):
		return "실비아의 족쇄를 지운 다음 스텝에 이그니스의 족쇄가 남아 있다"
	var f = _team([["sylvia", Vector2i(12, 10)], ["ignis", Vector2i(10, 13)]])
	var y = _chief(f, WC, "shackle")
	if not _ever(f, y, "shackle", 0.1):
		return "둘째 판: 0.1초 안에 사슬 족쇄 예고를 시작하지 않았다"
	f.heroes[1].pos = Vector2(10, 15)
	f.heroes[1].anchor = Vector2(10, 15)
	_steps(f, 22)
	if f.heroes.any(func(h): return h.fx.has("shackle")):
		return "둘째 판: 이그니스가 원에서 비켰는데 묶였다"
	var g = _team([["sylvia", Vector2i(12, 10)]])
	var z = _chief(g, WC, "shackle")
	return check(not _ever(g, z, "shackle", 3.0), "영웅이 하나뿐인데 사슬 족쇄 예고를 띄웠다(cast %s)" % [z.cast])

# EV1017 · S347: 전쟁 깃발은 예고 1.5초 뒤 대족장 자리에 깃발(체력 60, 밀리지 않음)을 세운다. 깃발 4칸 안의 적(대족장 포함)은 체력이 1 아래로 내려가지 않고,
# 반경 밖의 적은 쓰러진다. 깃발은 부술 수 있고 처치 보상이 없으며, 부수면 불굴이 사라진다. 깃발이 서 있는 동안에는 새로 꽂지 않는다
func ev1017():
	var b = battle({"base_hp": BIG})
	var why := _need(b, [WF, "warbanner"])
	if why != "":
		return why
	var e = _chief(b, WF, "banner", 100.0)
	var near = _still(b, "armored", Vector2(13, 10), {"hp": 10.0})
	var far = _still(b, "armored", Vector2(16, 10), {"hp": 10.0})
	var gold: int = b.gold
	if not _ever(b, e, "banner", 0.1) or e.cast.at.distance_to(Vector2(10, 10)) > 0.05:
		return "0.1초 안에 깃발 예고를 시작하지 않았다(cast %s)" % [e.cast]
	_steps(b, 28)
	if b.enemies.any(func(o): return o.kind == "warbanner"):
		return "예고 1.4초에 벌써 깃발이 섰다"
	_steps(b, 4)
	var flags: Array = b.enemies.filter(func(o): return o.kind == "warbanner")
	if flags.size() != 1 or flags[0].pos.distance_to(Vector2(10, 10)) > 0.05 or not is_equal_approx(flags[0].max_hp, 60.0) or not flags[0].rooted:
		return "예고 1.6초: 깃발 %s(하나, (10,10), 체력 60, 밀리지 않음)" % [flags.map(func(o): return [o.pos, o.max_hp, o.rooted])]
	var flag = flags[0]
	b.damage(near, 1000.0, "true")
	b.damage(far, 1000.0, "true")
	b.damage(e, 1000.0, "true")
	if not near.alive or not is_equal_approx(near.hp, 1.0) or far.alive or not e.alive or not is_equal_approx(e.hp, 1.0):
		return "고정 피해 1000 뒤: 3칸의 장갑 살아 있다 %s·체력 %s(1) · 6칸의 장갑 살아 있다 %s(쓰러져야 한다) · 대족장 살아 있다 %s·체력 %s(1)" % [near.alive, near.hp, far.alive, e.alive, e.hp]
	e.cd["banner"] = 0.0
	if _ever(b, e, "banner", 2.0):
		return "깃발이 서 있는데 다시 깃발 예고를 띄웠다"
	gold = b.gold
	b.damage(flag, 1000.0, "true")
	b.damage(near, 1.0, "true")
	if flag.alive or near.alive or b.gold != gold + near.reward:
		return "깃발에 고정 피해 1000: 깃발 살아 있다 %s · 그 뒤 장갑에 피해 1: 살아 있다 %s · 골드 %d(깃발 보상 없이 장갑 보상 %d만)" % [flag.alive, near.alive, b.gold - gold, near.reward]
	return check(_ever(b, e, "banner", 1.0), "깃발이 부서진 뒤 1초 안에 다시 깃발 예고를 띄우지 않았다(cast %s)" % [e.cast])

# 실비아(체력 비율 ratio)를 (13,10)에, 이그니스(체력 가득)를 (12,12)에 세우고 내린 대족장을 (10,10)에 둔 판에서 처형 선고가 붙을 때까지 돌린다. [판, 대족장, 실비아, 이그니스]
func _doomed(ratio: float) -> Array:
	var b = _team([["sylvia", Vector2i(13, 10)], ["ignis", Vector2i(12, 12)]])
	if not b.ENEMY_KINDS.has(WF):
		return [b, null, null, null]
	var e = _chief(b, WF, "verdict")
	var h = b.heroes[0]
	h.hp = h.max_hp * ratio
	if not _ever(b, e, "verdict", 0.1) or e.cast.get("mark") != h:
		return [b, null, h, b.heroes[1]]
	_steps(b, 18)
	return [b, e, h, b.heroes[1]]

# EV1018 · S348: 처형 선고는 8칸 안에서 체력(보호막 포함) 비율이 가장 낮은 땅 위 영웅에게 예고 0.8초 뒤 표식을 붙인다. 5초 뒤 대족장이 곁으로 뛰어가 내려찍어,
# 비율이 60% 아래면 최대 체력의 80%, 아니면 10%를 물리 피해로 준다. 대족장이 기절해 있으면 사라진다
func ev1018():
	var low := _doomed(0.5)
	var b = low[0]
	var why := _need(b, [WF])
	if why != "":
		return why
	var e = low[1]
	var h = low[2]
	if e == null:
		return "0.1초 안에 체력 비율이 낮은 실비아에게 처형 선고 예고를 시작하지 않았다"
	if e.doom.get("who") != h or absf(e.doom.left - 5.0) > 0.21 or not h.fx.has("verdict") or low[3].fx.has("verdict"):
		return "예고 0.9초: 선고 %s(실비아, 남은 초 5) · 표식 실비아 %s·이그니스 %s" % [e.doom, h.fx.has("verdict"), low[3].fx.has("verdict")]
	_steps(b, 90)
	if not h.alive or h.hp != h.max_hp * 0.5 or e.pos.distance_to(Vector2(10, 10)) > 0.05:
		return "선고 4.5초: 실비아 살아 있다 %s · 잃은 체력 비율 %s(0.5 그대로) · 대족장 자리 %s((10,10))" % [h.alive, _lost(h) / h.max_hp, e.pos]
	var at: Vector2 = h.pos
	_steps(b, 12)
	if h.alive or not e.doom.is_empty() or absf(e.pos.distance_to(at) - (e.radius + h.radius)) > 0.1:
		return "선고 5.1초: 체력 50%% 실비아가 살아 있다 %s(쓰러져야 한다) · 선고 %s(없음) · 대족장과 실비아 자리 사이 %.2f칸(몸 반지름 합 %.2f)" % [h.alive, e.doom, e.pos.distance_to(at), e.radius + h.radius]
	var healed := _doomed(0.5)
	healed[2].hp = healed[2].max_hp * 0.7
	_steps(healed[0], 102)
	var graze: float = healed[2].max_hp * 0.1 * healed[0].armor_mult(healed[0].armor_of(healed[2]))
	if not healed[2].alive or absf(healed[2].max_hp * 0.7 - healed[2].hp - graze) > 1.0 or healed[2].fx.has("verdict"):
		return "치유한 판: 실비아 살아 있다 %s · 내려찍기에 잃은 체력 %s(최대 체력의 10%% × 방어력 배율 %s) · 표식 %s(없음)" % [healed[2].alive, healed[2].max_hp * 0.7 - healed[2].hp, graze, healed[2].fx.has("verdict")]
	var shielded := _doomed(0.5)
	shielded[0]._shield(shielded[2], "test", shielded[2].max_hp * 0.2, 30.0, INF)
	_steps(shielded[0], 102)
	if not shielded[2].alive or shielded[2].hp != shielded[2].max_hp * 0.5:
		return "보호막을 준 판(체력 50%% + 보호막 20%%): 실비아 살아 있다 %s · 체력 비율 %s(0.5 그대로 — 보호막이 받는다)" % [shielded[2].alive, shielded[2].hp / shielded[2].max_hp]
	var cut := _doomed(0.5)
	_steps(cut[0], 96)
	cut[1].fx["test_stun"] = {"stun": true, "left": 0.5}
	_steps(cut[0], 10)
	return check(cut[2].alive and cut[2].hp == cut[2].max_hp * 0.5 and cut[1].doom.is_empty() and not cut[2].fx.has("verdict"),
		"대족장이 기절한 판: 실비아 살아 있다 %s · 잃은 체력 비율 %s(0.5 그대로) · 선고 %s(없음) · 표식 %s(없음)" % [cut[2].alive, _lost(cut[2]) / cut[2].max_hp, cut[1].doom, cut[2].fx.has("verdict")])

# EV1019 · S349: 침묵의 포효는 3.5칸 안의 가장 가까운 땅 위 영웅 쪽 부채꼴(100°) 예고 0.8초 뒤 부채꼴 안 영웅에게 침묵을 6초 건다.
# 침묵한 영웅은 스킬을 쓰지 못한다. 부채꼴 밖 영웅과 용병은 걸리지 않고, 침묵은 해로운 효과다
func ev1019():
	var b = _team([["sylvia", Vector2i(12, 10)], ["ignis", Vector2i(10, 7)]])
	var why := _need(b, [WF])
	if why != "":
		return why
	var e = _chief(b, WF, "roar")
	var h = b.heroes[0]
	var back = b.heroes[1]
	var m = b.place_merc("soldier", Vector2i(12, 11), QUIET)
	b.start_battle()
	if not b.can_cast(h, "q"):
		return "시험 조건이 틀렸다: 침묵 전에 실비아가 Q를 쓸 수 없다"
	if not _ever(b, e, "roar", 0.1) or absf(e.cast.dir) > 0.01:
		return "0.1초 안에 실비아 쪽 포효 예고를 시작하지 않았다(cast %s)" % [e.cast]
	_steps(b, 14)
	if b.effect(h, "silence") != null:
		return "예고 0.7초에 벌써 침묵이 걸렸다"
	_steps(b, 4)
	if b.effect(h, "silence") == null or b.effect(back, "silence") != null or b.effect(m, "silence") != null or b.can_cast(h, "q") or not b.can_cast(back, "q"):
		return "예고 0.9초: 침묵 실비아 %s(걸림) · 뒤쪽 이그니스 %s(안 걸림) · 병사 %s(안 걸림) · 실비아 Q %s(못 씀) · 이그니스 Q %s(씀)" % [b.effect(h, "silence") != null, b.effect(back, "silence") != null, b.effect(m, "silence") != null, b.can_cast(h, "q"), b.can_cast(back, "q")]
	e.cd["roar"] = float(BIG)
	_steps(b, 110)
	var held: bool = b.effect(h, "silence") != null
	_steps(b, 14)
	return check(held and b.effect(h, "silence") == null and b.can_cast(h, "q") and b._harmful({"silence": true}),
		"걸린 뒤 5.5초에 침묵 %s(걸려 있어야 한다) · 6.2초에 침묵 %s(풀려야 한다)·Q %s(씀) · 해로운 효과 %s" % [held, b.effect(h, "silence") != null, b.can_cast(h, "q"), b._harmful({"silence": true})])

# EV1020 · S350: 대족장이 한 번에 30 이상을 받으면 4칸 안의 아직 대신 맞지 않은 가장 가까운 근위대가 곁으로 뛰어들어 그 피해를 대신 받는다. 근위대마다 한 번이다
func ev1020():
	var b = battle({"base_hp": BIG})
	var why := _need(b, [WC, WG])
	if why != "":
		return why
	var e = _still(b, WC, Vector2(10, 10), {"hp": 1000.0})
	for id in e.skills:
		e.cd[id] = float(BIG)
	var g1 = _still(b, WG, Vector2(12, 10), {"hp": 40.0})
	var g2 = _still(b, WG, Vector2(10, 13), {"hp": 40.0})
	var g3 = _still(b, WG, Vector2(20, 10), {"hp": 40.0})
	b.damage(e, 29.0, "true")
	if absf(_lost(e) - 29.0) > 0.01 or g1.hp != g1.max_hp or g1.spent:
		return "고정 피해 29: 대족장이 잃은 체력 %s(29) · 근위대 체력 %s/%s · 대신 맞았다 %s(아니어야 한다)" % [_lost(e), g1.hp, g1.max_hp, g1.spent]
	b.damage(e, 30.0, "true")
	if absf(_lost(e) - 29.0) > 0.01 or absf(_lost(g1) - 30.0) > 0.01 or not g1.spent or g2.spent or absf(g1.pos.distance_to(e.pos) - (e.radius + g1.radius)) > 0.01:
		return "고정 피해 30: 대족장이 잃은 체력 %s(29 그대로) · 2칸의 근위대가 잃은 체력 %s(30)·대신 맞았다 %s · 3칸의 근위대 대신 맞았다 %s(아니어야 한다) · 근위대와 대족장 사이 %.2f칸(몸 반지름 합 %.2f)" % [_lost(e), _lost(g1), g1.spent, g2.spent, g1.pos.distance_to(e.pos), e.radius + g1.radius]
	b.damage(e, 100.0, "true")
	if absf(_lost(e) - 29.0) > 0.01 or g2.alive or not g1.alive:
		return "고정 피해 100: 대족장이 잃은 체력 %s(29 그대로) · 3칸의 근위대 살아 있다 %s(쓰러져야 한다) · 먼저 맞은 근위대 살아 있다 %s" % [_lost(e), g2.alive, g1.alive]
	b.damage(e, 100.0, "true")
	return check(absf(_lost(e) - 129.0) <= 0.01 and g3.hp == g3.max_hp and not g3.spent, "대신 맞을 근위대가 없을 때 고정 피해 100: 대족장이 잃은 체력 %s(129) · 10칸의 근위대 체력 %s/%s" % [_lost(e), g3.hp, g3.max_hp])

# EV1021 · I285: 첫 대기(first)가 있는 스킬은 나온 때와 내린 때 대기가 그 초다. 결투장·깃발 반경은 고리로, 사슬 족쇄는 두 영웅을 잇는 선으로,
# 처형 표식·침묵·군령은 머리 위 선으로 그린다. 결투·사슬 족쇄·처형 선고 예고는 숨어도 그리는 예고다
func ev1021():
	var b = _team([["sylvia", Vector2i(12, 10)], ["ignis", Vector2i(10, 13)]])
	var why := _need(b, [WC, WF, "warbanner"])
	if why != "":
		return why
	var e = b.spawn_enemy(WC, Vector2i(10, 10), STILL.merged({"hp": 10.0}, true))
	var first: Array = [e.cd.get("duel"), e.cd.get("shackle"), e.cd.get("charge", 0.0), e.cd.get("order", 0.0)]
	b.damage(e, 100.0, "true")
	var second: Array = [e.cd.get("banner"), e.cd.get("verdict"), e.cd.get("horn", 0.0), e.cd.get("rift", 0.0)]
	if first != [6.0, 12.0, 0.0, 0.0] or e.kind != WF or second != [8.0, 14.0, 0.0, 0.0]:
		return "첫 대기: 나온 대족장 [결투, 족쇄, 돌진, 군령] %s([6, 12, 0, 0]) · 내린 대족장 [깃발, 선고, 호출, 균열] %s([8, 14, 0, 0])" % [first, second]
	var v = _rec(b)
	if not v.has_method("_feud_marks"):
		v.free()
		return "BattleView에 _feud_marks가 없다"
	var hidden: bool = ["duel", "shackle", "verdict"].all(func(id): return id in v.UNSEEN_TELLS)
	var a = b.heroes[0]
	var c = b.heroes[1]
	var marks := func() -> Array:
		v.rings = []
		v.lines = []
		v._foes = v.foes()
		v._feud_marks()
		return [v.rings.duplicate(), v.lines.duplicate()]
	var none: Array = marks.call()
	e.duel = {"who": a, "at": Vector2(10, 10), "radius": 2.5, "left": 8.0, "need": 50.0, "dealt": 0.0, "cut": 0.8, "lose": 40.0}
	var ring: Array = marks.call()
	e.duel = {}
	var flag = _still(b, "warbanner", Vector2(20, 5))
	var staff: Array = marks.call()
	b.damage(flag, BIG, "true")
	a.fx["shackle"] = {"shackle": c, "reach": 4.0, "share": 0.5, "left": 10.0}
	c.fx["shackle"] = {"shackle": a, "reach": 4.0, "share": 0.5, "left": 10.0}
	var chain: Array = marks.call()
	a.fx.erase("shackle")
	c.fx.erase("shackle")
	a.fx["silence"] = {"silence": true, "left": 6.0}
	var mute: Array = marks.call()
	a.fx.erase("silence")
	e.doom = {"who": a, "left": 5.0, "below": 0.6, "execute": 0.8, "graze": 0.1}
	a.fx["verdict"] = {"verdict": e, "left": 5.0}
	var skull: Array = marks.call()
	e.doom = {}
	a.fx.erase("verdict")
	b.edict = {"kind": "rush", "left": 8.0, "stride": 0.3, "haste": 0.3, "cut": 0.5}
	var rush: Array = marks.call()
	var mid := Vector2i(v._center(Vector2(10, 10)).floor())
	var pole := Vector2i(v._center(Vector2(20, 5)).floor())
	var from: Vector2 = v._spot(a)
	var to: Vector2 = v._spot(c)
	v.free()
	var plain: bool = none[0].is_empty() and none[1].is_empty()
	var drawn := [ring[0].any(func(r): return r[0] == mid and r[1] == 40), staff[0].any(func(r): return r[0] == pole and r[1] == 64) and staff[1].is_empty(),
		chain[1].any(func(l): return (Vector2(l[0]).distance_to(from) <= 12.0 and Vector2(l[1]).distance_to(to) <= 12.0) or (Vector2(l[0]).distance_to(to) <= 12.0 and Vector2(l[1]).distance_to(from) <= 12.0)),
		mute[1].size() == 2, skull[0].size() == 1 and skull[1].size() == 2, rush[1].size() == 2]
	return check(hidden and plain and drawn.all(func(x): return x),
		"숨어도 그리는 예고에 결투·족쇄·선고 %s · 아무것도 없을 때 그림 없음 %s · [결투장 고리, 깃발 고리(선 없음), 족쇄 선, 침묵 선 둘, 처형 고리와 선 둘, 군령 선 둘] %s" % [hidden, plain, drawn])

# ── 오크 대족장 군단 그림(I286) ──

const HOST_ART := {WC: ["idle", "walk", "attack", "charge", "order", "aim", "fall"], WF: ["idle", "walk", "attack", "horn", "banner", "roar", "verdict", "fall"],
	WG: ["idle", "walk", "attack", "fall"], WB: ["idle", "sway"]}  # 종류 → 그림 칸의 자세
const TWO := ["walk", "charge", "order", "aim", "horn", "banner", "roar", "verdict", "sway"]  # 2열 자세(나머지는 1열)

# EV1023 · I286: 네 종류의 그림 칸이 heroes.json에 있고 칸마다 그림이 있다. 사슬 갈고리·사슬 족쇄·결투 신청은 겨눔 칸을 함께 쓴다.
# 칸은 와이번 칸 오른쪽의 영웅 구역 안에 두 열(대족장 둘, 그 오른쪽에 근위대·깃발)로 위에서부터 쌓이고 서로 겹치지 않는다. 칸마다 몸의 높이(head)가 정지 그림에 맞다. 아틀라스 크기는 그대로다
func ev1023():
	var art: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/units/heroes.json"))
	var img: Image = load("res://art/units/heroes.png").get_image()
	var whole := Rect2i(Vector2i.ZERO, img.get_size())
	var bad := []
	var rects := []  # [이름, 시트 사각형]
	for k in HOST_ART:
		if not art.has(k):
			return "heroes.json에 %s 칸이 없다" % k
		var a: Dictionary = art[k]
		var missing: Array = HOST_ART[k].filter(func(s): return not a.has(s))
		if not a.has("x") or a.has("one") != (k == WB) or not missing.is_empty():
			bad.append("%s 칸 x %s · one %s(깃발만) · 없는 자세 %s" % [k, a.get("x"), a.get("one"), missing])
			continue
		var c := int(a.c)
		var x := int(a.x)
		var top := c  # 정지 그림의 가장 높은 불투명 줄(칸 안 y)
		for r in (1 if k == WB else 4):
			for y in top:
				if not img.get_region(Rect2i(x, int(a.idle) + r * c + y, c, 1)).is_invisible():
					top = y
					break
		if not a.has("head") or int(a.head) != int(a.anchor[1]) - maxi(0, top - 3):
			bad.append("%s head %s(기준점 y %d − max(0, 정지 그림 맨 윗줄 %d − 3))" % [k, a.get("head"), int(a.anchor[1]), top])
		for s in HOST_ART[k]:
			var n := c * (2 if s in ["attack", "fall"] else 1)
			var cols := 2 if s in TWO else 1
			var rows := 1 if s == "fall" or k == WB else 4
			rects.append(["%s %s" % [k, s], Rect2i(x, int(a[s]), cols * n, rows * n)])
			for r in rows:
				for q in cols:
					var cell := Rect2i(x + q * n, int(a[s]) + r * n, n, n)
					if not whole.encloses(cell):
						bad.append("%s %s %d행 %d열 %s가 그림 밖" % [k, s, r, q, cell])
					elif img.get_region(cell).is_invisible():
						bad.append("%s %s %d행 %d열 빈 칸" % [k, s, r, q])
	if not bad.is_empty():
		return "; ".join(bad.slice(0, 6))
	var wc: Dictionary = art[WC]
	if ["chain", "shackle", "duel"].any(func(s): return wc.get(s) != wc.aim):
		bad.append("겨눔 칸 aim %s을 함께 쓰지 않는다: chain %s · shackle %s · duel %s" % [wc.aim, wc.get("chain"), wc.get("shackle"), wc.get("duel")])
	var wy: Dictionary = art.wyvern
	var left: int = int(wy.x) + 2 * int(wy.c)  # 와이번 칸의 오른쪽 끝(가장 넓은 시트가 2열)
	var top: int = int(art.soldier.idle)  # 영웅 구역의 아래 끝
	var side: int = left + 2 * maxi(int(art[WC].c), int(art[WF].c))  # 대족장 열의 오른쪽 끝
	for col in [[left, WC, WF], [side, WG, WB]]:  # [x, 위 종류, 아래 종류]
		for k in [col[1], col[2]]:
			if int(art[k].x) != col[0]:
				bad.append("%s x %d(%d)" % [k, int(art[k].x), col[0]])
		if int(art[col[1]].idle) != 0 or int(art[col[2]].idle) <= int(art[col[1]].idle):
			bad.append("%s 정지 y %d(0) · %s 정지 y %d(그 아래)" % [col[1], int(art[col[1]].idle), col[2], int(art[col[2]].idle)])
	for i in rects.size():
		var r: Rect2i = rects[i][1]
		if r.end.y > top or not whole.encloses(r):
			bad.append("%s %s가 영웅 구역(y ~%d) 안이 아니다" % [rects[i][0], r, top])
		for j in i:
			if r.intersects(rects[j][1]):
				bad.append("%s와 %s가 겹친다" % [rects[i][0], rects[j][0]])
	if img.get_size() != Vector2i(828, 15656):
		bad.append("아틀라스 %s(828×15656)" % [img.get_size()])
	return check(bad.is_empty(), "; ".join(bad.slice(0, 6)))

# EV1024 · I286: 네 종류는 빌린 그림·큰 몸 표에 없이 제 칸의 그림 한 장을 키우지 않고 그린다. 스킬 자세는 시트의 0열·1열을, 예고·발동의 때와 방향에 맞게 그린다.
# 깃발은 흔들림 칸을 그리고, 오크 대족장이 내릴 때 남는 몸은 오크 대족장 칸의 누운 자세(쓰러진 전쟁 늑대)로 그린다
func ev1024():
	var r := _lone("sylvia", Vector2i(14, 10))
	var b = r[0]
	var h = r[1]
	var why := _need(b, [WR, WG, WC, WF, WB])
	if why != "":
		return why
	var consts: Dictionary = (load("res://src/ui/battle_view.gd") as Script).get_script_constant_map()
	var looks: Dictionary = consts.get("LOOKS", {})
	var grow: Dictionary = consts.get("GROW", {})
	if [WC, WF, WG, WB].any(func(k): return looks.has(k)) or grow.has(WC) or grow.has(WF):
		return "빌린 그림 표에 %s · 큰 몸 표에 %s(넷 다 없어야 한다)" % [[WC, WF, WG, WB].filter(func(k): return looks.has(k)), [WC, WF].filter(func(k): return grow.has(k))]
	var v = _rec(b)
	var art: Dictionary = v.ART
	var bad := []
	var n := 0
	for k in [WC, WF, WG, WB]:
		var one = _cut(v, _still(b, k, Vector2(3 + n * 6, 3), {"hp": 100.0}))
		n += 1
		if one == null:
			bad.append("%s 몸통이 그림 한 장이 아니다(%d장)" % [k, v.cuts.size()])
			continue
		var a: Dictionary = art[k]
		var c := float(a.c)
		var sheet: String = "sway" if k == WB else "idle"
		var src: Rect2 = one[1]
		var own: bool = src.size == Vector2(c, c) and src.position.x >= a.x and src.position.x < a.x + (2 if k == WB else 1) * c and src.position.y >= a[sheet] and src.position.y < a[sheet] + (1 if k == WB else 4) * c
		if not own or one[0].size != Vector2(c, c) or one[2] != Color.WHITE:
			bad.append("%s 원본 %s(제 %s 칸 x %d y %d, 칸 %d) · 대상 크기 %s(칸 그대로) · 색 %s(흰색)" % [k, src, sheet, int(a.x), int(a[sheet]), int(c), one[0].size, one[2]])
	if not bad.is_empty():
		v.free()
		return "; ".join(bad)
	var wc: Dictionary = art[WC]
	var wf: Dictionary = art[WF]
	var cw := float(wc.c)
	var cf := float(wf.c)
	var chief = _still(b, WC, Vector2(10, 10), {"hp": 100.0})  # 실비아(14,10)의 서쪽: 실비아 쪽은 동(1행)
	var foot = _still(b, WF, Vector2(10, 14), {"hp": 100.0})
	var bar: float = chief.pos.y - v.hp_bar_at(chief).y  # 보스 막대를 올린 높이(칸)
	if v._head(chief) != float(wc.head) or v._head(foot) != float(wf.head) or not is_equal_approx(bar, (float(wc.head) - float(art.basic.anchor[1])) / v.CELL):
		bad.append("몸의 높이: 대족장 %s(head %s) · 내린 대족장 %s(head %s) · 보스 막대 올림 %.3f칸(head − 기본 적 기준점 y %s, 칸으로)" % [v._head(chief), wc.head, v._head(foot), wf.head, bar, art.basic.anchor[1]])
	var poses := []  # [이름, 그린 원본 자리, 맞는 원본 자리]
	var shot := func(name: String, e, cast, want: Vector2):
		e.cast = cast
		var one = _cut(v, e)
		e.cast = null
		poses.append([name, one[1].position if one != null else null, want])
	shot.call("군령 예고 중(0열, 남)", chief, {"id": "order", "left": 1.5}, Vector2(wc.x, wc.order))
	shot.call("군령 예고 끝(1열, 남)", chief, {"id": "order", "left": 0.2}, Vector2(wc.x + cw, wc.order))
	shot.call("결투 예고 중(겨눔 0열, 지목한 영웅 쪽 동)", chief, {"id": "duel", "left": 1.0, "who": h, "at": chief.pos}, Vector2(wc.x, wc.aim + cw))
	shot.call("결투 예고 끝(겨눔 1열, 동)", chief, {"id": "duel", "left": 0.2, "who": h, "at": chief.pos}, Vector2(wc.x + cw, wc.aim + cw))
	shot.call("사슬 예고 중(정지, 동)", chief, {"id": "chain", "left": 1.0, "dir": 0.0, "to": chief.pos + Vector2(6, 0)}, Vector2(wc.x, wc.idle + cw))
	shot.call("사슬 예고 끝(겨눔 0열, 동)", chief, {"id": "chain", "left": 0.2, "dir": 0.0, "to": chief.pos + Vector2(6, 0)}, Vector2(wc.x, wc.aim + cw))
	shot.call("돌진 예고 끝(0열, 동)", chief, {"id": "charge", "left": 0.2, "dir": 0.0, "to": chief.pos + Vector2(6, 0)}, Vector2(wc.x, wc.charge + cw))
	shot.call("깃발 예고 중(0열, 화면 쪽 남)", foot, {"id": "banner", "left": 1.0, "at": foot.pos}, Vector2(wf.x, wf.banner))
	shot.call("깃발 예고 끝(1열, 남)", foot, {"id": "banner", "left": 0.2, "at": foot.pos}, Vector2(wf.x + cf, wf.banner))
	shot.call("포효 예고 끝(0열, 동)", foot, {"id": "roar", "left": 0.2, "dir": 0.0}, Vector2(wf.x, wf.roar + cf))
	shot.call("선고 예고 끝(0열, 표식 영웅 쪽 동)", foot, {"id": "verdict", "left": 0.2, "mark": h, "at": Vector2(14, 14)}, Vector2(wf.x, wf.verdict + cf))
	b.traces.append({"hero": foot, "slot": "verdict", "aim": null, "at": Vector2(14, 14), "radius": 0.8, "hits": [], "marked": false, "age": 0.0})
	shot.call("처형 내려찍기(1열, 내려찍은 쪽 동)", foot, null, Vector2(wf.x + cf, wf.verdict + cf))
	b.traces.clear()
	for p in poses:
		if p[1] == null or not Vector2(p[1]).is_equal_approx(p[2]):
			bad.append("%s: 원본 자리 %s(%s)" % p)
	var fell := []
	for k in [WC, WR]:
		var e = _still(b, k, Vector2(20 if k == WC else 26, 16), {"hp": 10.0})  # 위에 세운 깃발(21,3)의 불굴 반경 4칸 밖
		b.damage(e, 50.0, "true")
		var d: Array = v._fallen().filter(func(x): return x[0].pos.distance_to(e.pos) < 0.5)
		if d.size() != 1 or d[0][0].kind != "wolf":
			fell.append("%s가 내린 자리의 쓰러진 몸 %s(늑대 하나)" % [k, d.map(func(x): return x[0].kind)])
			continue
		v.cuts = []
		v._corpse(d[0])
		var want: Vector2 = Vector2(wc.x, wc.fall) if k == WC else Vector2(art.wolf.x, art.wolf.fall)
		var size: float = 2.0 * (cw if k == WC else float(art.wolf.c))
		if v.cuts.size() != 1 or not Vector2(v.cuts[0][1].position).is_equal_approx(want) or v.cuts[0][1].size != Vector2(size, size) or v.cuts[0][0].size != Vector2(size, size):
			fell.append("%s가 내린 뒤 쓰러진 몸 그림 %s(원본 자리 %s, 크기 %d, 키우지 않음)" % [k, v.cuts.map(func(x): return [x[1], x[0].size]), want, int(size)])
	v.free()
	return check(bad.is_empty() and fell.is_empty(), "; ".join(bad + fell))
