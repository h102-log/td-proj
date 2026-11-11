extends "res://tests/eval/gd/orc.gd"
# 6라운드 대족장 군단 묶음 ①(S324 2026-11-11 변경·S335·I279). lib.gd·sky.gd·orc.gd 머리의 계약에 더하는 API:
#   적 kind "wolf_rider"(늑대 기수, S335). 적 칸 flank({ranged}) · phase2 · mount · via(먼저 노리는 성문 칸) · fx(걸린 효과)
#   Battle.fallen — 쓰러진 몸 [{who, age}] · Battle.wrecks — 수레 잔해 · Battle.gold · damage(대상, 양, "true")는 고정 피해
#   BattleView: ART(그림 칸 표) · _fallen() — 그릴 쓰러진 몸 [[몸, 쓰러진 뒤 초]]
# 판은 lib.gd battle()의 들판(30×20, 거점 (25,10))이다. 처치 보상 배율이 없어 처치 보상이 그대로 골드에 든다

const WR := "wolf_rider"
const TALL := {"hp": BIG}  # 체력만 크고 나머지는 종류 수치 그대로

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
