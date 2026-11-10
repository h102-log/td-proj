extends "res://tests/eval/gd/orc.gd"
# 5라운드 오크 전쟁패 묶음 ③(S327~S329·I271~I274). lib.gd·sky.gd·orc.gd 머리의 계약에 더하는 API:
#   적 kind "troll"(트롤 싸움꾼, S328) · "twin_troll"(쌍둥이 트롤, S329). 적 칸 regen(초당 최대 체력 비율) · swat · mate(짝 번호) · twin(맡은 몸, 없으면 null)
#   적 cast: 쓸기 {id swat, left, dir} · 집어 먹기 {id devour, left, who} · 형제 던지기 {id twin, left, at} · 집어 던지기 {id lob, left, at, who(오크, 바위면 null)}
#   Battle.lobs — 날아가는 바위·몸 [{from, at, left, air, radius, hit, by, look("rock"|"twin"), who}] · Battle._zone(출처, 영웅, 자리, 반경, 초, 더할 칸) · zones
#   Battle.armor_of(유닛) · Battle.armor_mult(방어력) · effect(대상, 효과 키)
#   BattleView: LOOKS · GROW · TWINS · _regen_marks() · _feed_marks() · _lob_marks() · _twin_bodies() · _tells() · _foe_tells() · _edge(가운데, 반지름, 밝은 색, 어두운 색) · _pdisc(가운데, 반지름, 색)
#     · _poly(점들, 색) · _shadow(자리, 반지름) · _px(자리, 색, 크기) · _chest(몸) · CELL · tick(dt) · events([{kind, src, …}])
# 판은 lib.gd battle()의 들판(30×20, 거점 (25,10))이다

const TR := "troll"
const TT := "twin_troll"
const PREY := {"sight": 0, "damage": 0, "hp": BIG}  # 걷는 졸개(치지도 쫓지도 않음)

# 그림 한 장·선·고리·점 원·테를 그리는 대신 모으는 화면
class TRec extends "res://src/ui/battle_view.gd":
	var cuts := []  # [대상 사각형, 원본 사각형, 색]
	var lines := []  # [가, 나]
	var rings := []  # [가운데, 반지름]
	var discs := []  # [가운데, 반지름]
	var edges := []  # [가운데, 반지름]
	var polys := []  # [점들, 색]
	var shadows := []  # [자리, 반지름]

	func _region(_tex: Texture2D, dst: Rect2, src: Rect2, tint: Color) -> void:
		cuts.append([dst, src, tint])

	func _pline(a: Vector2i, b: Vector2i, _col: Color, _w := 1) -> void:
		lines.append([a, b])

	func _pring(c: Vector2i, r: int, _th: int, _col: Color, _dash := 0, _spin := 0.0) -> void:
		rings.append([c, r])

	func _pdisc(c: Vector2i, r: int, _col: Color) -> void:
		discs.append([c, r])

	func _edge(c: Vector2i, r: int, _light: Color, _dark: Color, _others := []) -> void:
		edges.append([c, r])

	func _pnoise(_c: Vector2i, _r: int, _col: Color, _lim: int, _salt := 0) -> void:
		pass

	func _shadow(at: Vector2, r: float) -> void:
		shadows.append([at, r])

	func _poly(pts: PackedVector2Array, col: Color) -> void:
		polys.append([pts, col])

	func _px(_p: Vector2i, _col: Color, _size := Vector2i.ONE) -> void:
		pass

func _trec(b):
	var v = TRec.new()
	v.battle = b
	return v

# kind 적(움직이지도 치지도 않음, 최대 체력 100)을 at에 두고 체력을 hp로 낮춘다
func _worn(b, kind: String, at: Vector2, hp: float):
	var e = _still(b, kind, at, {"hp": 100.0})
	e.hp = hp
	return e

# e가 secs 동안 얻은 체력
func _gain(b, e, secs := 1.0) -> float:
	var was: float = e.hp
	_steps(b, roundi(secs / DT))
	return e.hp - was

# 들판 판의 (10,10)에 서 있는 트롤 싸움꾼(속도 0, 피해 0, 체력 큼)과 cells마다 치지도 쫓지도 않는 궁수. [판, 트롤, 궁수들]
func _brawl(cells: Array) -> Array:
	var b = battle({"base_hp": BIG})
	if not b.ENEMY_KINDS.has(TR):
		return [b, null, []]
	var ms: Array = cells.map(func(c): return b.place_merc("archer", c, MUTE))
	return [b, b.spawn_enemy(TR, Vector2i(10, 10), {"speed": 0, "damage": 0, "hp": BIG}), ms]

# 들판 판에 영웅 이그니스(레벨 5, 공격력·인식 범위 0)를 hero 칸에, 움직이지도 치지도 않는 쌍둥이 트롤(over 수치)을 (10,10)에 둔다. [판, 영웅, 트롤]
func _lair(hero: Vector2i, over := {}, stage := {}) -> Array:
	var r := _one("ignis", hero, {}, stage)
	var h = r[1]
	h.sight = 0.0
	h.damage = 0.0
	if not r[0].ENEMY_KINDS.has(TT):
		return [r[0], h, null]
	return [r[0], h, _still(r[0], TT, Vector2(10, 10), over)]

# 들판 판의 (10,10)에 움직이지도 치지도 않는 쌍둥이 트롤(최대 체력 1000, 재생 0)을 두고 체력을 hp로 낮춘다. [판, 트롤]
func _hungry(hp: float) -> Array:
	var b = battle({"base_hp": BIG})
	if not b.ENEMY_KINDS.has(TT):
		return [b, null]
	var w = _still(b, TT, Vector2(10, 10), {"hp": 1000.0, "regen": 0.0})
	w.hp = hp
	return [b, w]

# 영웅 (18,10), 움직이지도 치지도 않는 쌍둥이 트롤 Y(체력 100) (10,10), 걷는 쌍둥이 트롤 X(피해 0, 체력 큼, 재생 0) (10,4). [판, 영웅, X, Y]
func _pairup() -> Array:
	var g := _lair(Vector2i(18, 10), {"hp": 100.0})
	if g[2] == null:
		return [g[0], g[1], null, null]
	return [g[0], g[1], g[0].spawn_enemy(TT, Vector2i(10, 4), {"damage": 0, "hp": BIG, "regen": 0.0}), g[2]]

# EV938 · S327: 재생은 초당 최대 체력 × regen. 기절·봉인·발화·불 장판 동안 멈추고, 풀리면 다시 찬다. 가득이면 넘지 않는다
func ev938():
	var b = battle({"base_hp": BIG})
	var why := _need(b, [TR, TT])
	if why != "":
		return why
	var t = _worn(b, TR, Vector2(10, 10), 50.0)
	var got := _gain(b, t)
	if absf(got - 3.0) > 0.05:
		return "체력 50인 트롤 싸움꾼이 1초에 찬 체력 %.3f(3)" % got
	t.hp = 99.5
	_steps(b, 20)
	if t.hp != 100.0:
		return "체력 99.5에서 1초 뒤 체력 %s(100)" % t.hp
	for fx in [["기절", "test_stun", {"stun": true, "left": BIG}], ["봉인", "test_seal", {"seal": true, "left": BIG}], ["발화", "ignis_q", {"dot": 0.0, "left": BIG}]]:
		t.hp = 50.0
		t.fx[fx[1]] = fx[2]
		var held := _gain(b, t)
		t.fx.erase(fx[1])
		var back := _gain(b, t)
		if held != 0.0 or absf(back - 3.0) > 0.05:
			return "%s: 걸린 1초에 찬 체력 %.3f(0) · 지운 뒤 1초에 %.3f(3)" % [fx[0], held, back]
	t.hp = 50.0
	var far = _worn(b, TR, Vector2(14, 10), 50.0)
	b._zone("ignis_q", null, Vector2(10, 10), 1.5, BIG, {"dps": 0.0})
	var in_fire := _gain(b, t)
	var out_fire: float = far.hp - 50.0
	b.zones.clear()
	var after := _gain(b, t)
	if in_fire != 0.0 or absf(out_fire - 3.0) > 0.05 or absf(after - 3.0) > 0.05:
		return "바닥 불길: 안의 트롤이 1초에 찬 체력 %.3f(0) · 4칸 밖 트롤 %.3f(3) · 장판을 지운 뒤 1초에 %.3f(3)" % [in_fire, out_fire, after]
	var twin = _worn(b, TT, Vector2(10, 16), 50.0)
	var orc = _worn(b, "armored", Vector2(20, 4), 50.0)
	var tw := _gain(b, twin)
	return check(absf(tw - 1.0) <= 0.05 and orc.hp == 50.0, "쌍둥이 트롤이 1초에 찬 체력 %.3f(1) · 장갑 체력 %s(50)" % [tw, orc.hp])

# EV939 · S328: 1.5칸 안 가장 가까운 땅 위 아군 쪽 부채꼴(120°) 예고 0.8초 → 부채꼴 안 아군에 8과 넉백 1.5칸. 대기 6초 뒤 남은 아군 쪽으로 다시 쓴다
func ev939():
	var g := _brawl([Vector2i(11, 10), Vector2i(11, 11), Vector2i(9, 10)])
	var b = g[0]
	var why := _need(b, [TR])
	if why != "":
		return why
	var t = g[1]
	var a = g[2][0]
	var m = g[2][1]
	var c = g[2][2]
	if not _ever(b, t, "swat", 0.1) or absf(angle_difference(t.cast.get("dir", 9.0), 0.0)) > 0.01:
		return "0.1초 안에 동쪽으로 쓸기 예고를 시작하지 않았다(cast %s)" % [t.cast]
	_steps(b, 14)
	if a.hp != a.max_hp or m.hp != m.max_hp or a.pos.distance_to(Vector2(11, 10)) > 0.05:
		return "예고 0.7초: A가 잃은 체력 %s(0) · B %s(0) · A 자리 %s((11,10))" % [_lost(a), _lost(m), a.pos]
	var n := 14
	while n < 18 and _casting(t, "swat"):
		b.step(DT)
		n += 1
	if _casting(t, "swat"):
		return "예고 0.9초에도 쓸지 않았다(cast %s)" % [t.cast]
	var da: float = t.pos.distance_to(a.pos)
	var dm: float = t.pos.distance_to(m.pos)
	if not (is_equal_approx(_lost(a), 8.0) and is_equal_approx(_lost(m), 8.0) and da >= 2.3 and dm >= 2.7 and c.hp == c.max_hp and c.pos.distance_to(Vector2(9, 10)) <= 0.01):
		return "쓴 뒤: A가 잃은 체력 %s(8) · B %s(8) · 트롤에서 A까지 %.2f(2.3 이상) · B까지 %.2f(2.7 이상) · C가 잃은 체력 %s(0) · C 자리 %s((9,10))" % [_lost(a), _lost(m), da, dm, _lost(c), c.pos]
	var early := false
	for i in 114:
		b.step(DT)
		early = early or _casting(t, "swat")
	_steps(b, 12)
	return check(not early and _casting(t, "swat") and absf(angle_difference(t.cast.dir, PI)) <= 0.01,
		"쓴 뒤 5.7초 안에 다시 예고 %s(없어야 한다) · 6.3초에 서쪽 예고(cast %s)" % [early, t.cast])

# EV940 · S328: 예고 중 기절하면 취소되고 비틀거리지 않으며 대기가 돈다. 봉인·성벽 위 아군에는 쓸지 않는다. 대기 중에는 다가가 친다
func ev940():
	var g := _brawl([Vector2i(11, 10)])
	var b = g[0]
	var why := _need(b, [TR])
	if why != "":
		return why
	var t = g[1]
	var a = g[2][0]
	if not _ever(b, t, "swat", 0.1):
		return "0.1초 안에 쓸기 예고를 시작하지 않았다(cast %s)" % [t.cast]
	_steps(b, 8)
	t.fx["test_stun"] = {"stun": true, "left": 0.5}
	b.step(DT)
	var off: bool = t.cast == null and not t.fx.has("stagger")
	var calm := true
	var early := false
	for i in 114:
		b.step(DT)
		early = early or _casting(t, "swat")
		if i < 20:
			calm = calm and a.hp == a.max_hp and a.pos.distance_to(Vector2(11, 10)) <= 0.01
	_steps(b, 12)
	if not (off and calm and not early and _casting(t, "swat")):
		return "기절: 다음 스텝에 예고·비틀거림 없음 %s · 그 뒤 1초 궁수 그대로 %s · 5.7초 안에 다시 예고 %s(없어야 한다) · 6.3초에 예고 %s(있어야 한다)" % [off, calm, early, _casting(t, "swat")]
	var s := _brawl([Vector2i(11, 10)])
	s[1].fx["test_seal"] = {"seal": true, "left": BIG}
	if _ever(s[0], s[1], "swat", 3.0):
		return "봉인한 트롤 싸움꾼이 3초 안에 쓸기 예고를 띄웠다"
	var cb = _castle()
	var up = _up(cb, "archer", Vector2i(14, 9), MUTE)
	if up == null:
		return "궁수가 성벽 (14,9)에 오르지 못했다"
	run(cb, 5.0, func(): return up.path.is_empty() and up.after.is_empty())
	var ct = _still(cb, TR, Vector2(14, 10))
	if _ever(cb, ct, "swat", 3.0):
		return "성벽 위 궁수에게 쓸기 예고를 띄웠다(cast %s)" % [ct.cast]
	var wb = battle({"base_hp": BIG})
	var wm = wb.place_merc("archer", Vector2i(13, 10), MUTE)
	var wt = wb.spawn_enemy(TR, Vector2i(10, 10), {"hp": BIG})
	if not _ever(wb, wt, "swat", 10.0):
		return "걷는 트롤 싸움꾼이 10초 안에 쓸기 예고를 띄우지 않았다"
	if not run(wb, 2.0, func(): return not _casting(wt, "swat")):
		return "쓸기 예고가 2초 안에 끝나지 않았다"
	var again := false
	for i in 100:
		wb.step(DT)
		again = again or _casting(wt, "swat")
	return check(not again and _lost(wm) >= 18.0, "쓴 뒤 5초 안에 다시 예고 %s(없어야 한다) · 궁수가 잃은 체력 %s(18 이상)" % [again, _lost(wm)])

# EV941 · S329 ③: 2~7칸 영웅 자리에 원 예고 1.2초, 2칸 안 장갑을 집어 0.6초 날려 원 안 아군에 15. 집힌 장갑이 쓰러지면 취소된다
func ev941():
	var g := _lair(Vector2i(15, 10))
	var b = g[0]
	var why := _need(b, [TT])
	if why != "":
		return why
	var h = g[1]
	var w = g[2]
	var a = _still(b, "armored", Vector2(11.5, 10))
	var cut: float = b.armor_mult(b.armor_of(h))
	if not _ever(b, w, "lob", 0.1) or w.cast.get("at") == null or w.cast.at.distance_to(Vector2(15, 10)) > 0.1 or not is_same(w.cast.get("who"), a):
		return "0.1초 안에 (15,10)에 장갑을 집은 집어 던지기 예고를 시작하지 않았다(cast %s)" % [w.cast]
	_steps(b, 22)
	if a.pos.distance_to(Vector2(11.5, 10)) > 0.05 or _flying(a) or h.hp != h.max_hp:
		return "예고 1.1초: 장갑 자리 %s((11.5,10)) · 떴다 %s · 영웅이 잃은 체력 %s(0)" % [a.pos, _flying(a), _lost(h)]
	var rocks: bool = not b.lobs.is_empty()
	var up := 22
	while up < 28 and not _flying(a):
		b.step(DT)
		up += 1
		rocks = rocks or not b.lobs.is_empty()
	if not _flying(a):
		return "예고 1.4초에 장갑이 뜨지 않았다(cast %s)" % [a.cast]
	for i in 40 - up:
		b.step(DT)
		rocks = rocks or not b.lobs.is_empty()
	if _flying(a) or a.pos.distance_to(Vector2(15, 10)) > 1.5 or absf(_lost(h) - 15.0 * cut) > 0.01 or rocks:
		return "예고 2.0초: 장갑 떴다 %s · 자리 %s((15,10) 1.5칸 안) · 영웅이 잃은 체력 %s(%s) · 바위를 던졌다 %s" % [_flying(a), a.pos, _lost(h), 15.0 * cut, rocks]
	var k := _lair(Vector2i(15, 10))
	var dead = _still(k[0], "armored", Vector2(11, 10), {"hp": 100.0})
	if not _ever(k[0], k[2], "lob", 0.1):
		return "둘째 판: 0.1초 안에 집어 던지기 예고를 시작하지 않았다(cast %s)" % [k[2].cast]
	_steps(k[0], 10)
	k[0].damage(dead, BIG, "true")
	k[0].step(DT)
	var gone: bool = k[2].cast == null
	_steps(k[0], 40)
	return check(gone and k[1].hp == k[1].max_hp, "집힌 장갑이 쓰러진 다음 스텝에 예고 없음 %s · 그 뒤 2초 영웅이 잃은 체력 %s(0)" % [gone, _lost(k[1])])

# EV942 · S329 ③: 집을 오크가 없으면 바위를 던진다. 예고 1.2초 뒤 0.6초 날아 원 안 아군에 25. 영웅이 2칸 안·7칸 밖이거나 없으면 던지지 않는다
func ev942():
	var g := _lair(Vector2i(15, 10))
	var b = g[0]
	var why := _need(b, [TT])
	if why != "":
		return why
	var h = g[1]
	var w = g[2]
	var orc = _still(b, "armored", Vector2(13, 13))
	var p = b.place_merc("archer", Vector2i(16, 10), MUTE)
	var q = b.place_merc("archer", Vector2i(15, 13), MUTE)
	var cut: float = b.armor_mult(b.armor_of(h))
	if not _ever(b, w, "lob", 0.1) or w.cast.get("at") == null or w.cast.at.distance_to(Vector2(15, 10)) > 0.1 or w.cast.get("who") != null:
		return "0.1초 안에 (15,10)에 맨손 집어 던지기 예고를 시작하지 않았다(cast %s)" % [w.cast]
	var at: Vector2 = w.cast.at
	_steps(b, 22)
	if not b.lobs.is_empty() or h.hp != h.max_hp or p.hp != p.max_hp:
		return "예고 1.1초: 던진 것 %s(없어야 한다) · 영웅이 잃은 체력 %s(0) · P %s(0)" % [b.lobs, _lost(h), _lost(p)]
	var up := 22
	while up < 28 and b.lobs.is_empty():
		b.step(DT)
		up += 1
	if b.lobs.size() != 1 or b.lobs[0].get("look") != "rock" or b.lobs[0].get("at") != at or h.hp != h.max_hp or p.hp != p.max_hp:
		return "예고 1.4초: 던진 것 %s(look rock, at %s 하나) · 영웅이 잃은 체력 %s(0) · P %s(0)" % [b.lobs, at, _lost(h), _lost(p)]
	_steps(b, 40 - up)
	if not (b.lobs.is_empty() and absf(_lost(h) - 25.0 * cut) <= 0.01 and is_equal_approx(_lost(p), 25.0) and q.hp == q.max_hp and orc.hp == orc.max_hp and orc.pos.distance_to(Vector2(13, 13)) <= 0.01):
		return "예고 2.0초: 던진 것 %s(없어야 한다) · 영웅이 잃은 체력 %s(%s) · P %s(25) · Q %s(0) · 장갑이 잃은 체력 %s(0)·자리 %s" % [b.lobs, _lost(h), 25.0 * cut, _lost(p), _lost(q), _lost(orc), orc.pos]
	for cell in [Vector2i(11, 10), Vector2i(18, 10)]:
		var n := _lair(cell)
		if _ever(n[0], n[2], "lob", 3.0):
			return "영웅이 %s에 있는데 3초 안에 집어 던지기 예고를 시작했다(cast %s)" % [cell, n[2].cast]
	var mb = battle({"base_hp": BIG})
	mb.place_merc("archer", Vector2i(15, 10), MUTE)
	var mw = _still(mb, TT, Vector2(10, 10))
	return check(not _ever(mb, mw, "lob", 3.0), "영웅 없이 궁수만 있는데 집어 던지기 예고를 시작했다(cast %s)" % [mw.cast])

# EV943 · S329 ①: 체력 50% 이하이고 2칸 안에 졸개가 있으면 예고 1.5초 뒤 졸개를 먹고 25% 회복한다(보상 없음). 끊기거나 졸개가 먼저 쓰러지면 못 먹는다
func ev943():
	var g := _hungry(400.0)
	var b = g[0]
	var why := _need(b, [TT])
	if why != "":
		return why
	var w = g[1]
	var a = b.spawn_enemy("armored", Vector2i(11, 10), PREY)
	var gold: int = b.gold
	if not _ever(b, w, "devour", 0.1) or not is_same(w.cast.get("who"), a):
		return "0.1초 안에 장갑을 집은 집어 먹기 예고를 시작하지 않았다(cast %s)" % [w.cast]
	var from: Vector2 = a.pos
	_steps(b, 28)
	if not a.alive or a.pos.distance_to(from) > 0.05 or w.hp != 400.0:
		return "예고 1.4초: 장갑 살아 있다 %s · 움직인 칸 %.2f(0.05 안) · 트롤 체력 %s(400)" % [a.alive, a.pos.distance_to(from), w.hp]
	_steps(b, 4)
	if a.alive or a in b.enemies or b.fallen.any(func(f): return is_same(f.who, a)) or w.hp != 650.0 or b.gold != gold:
		return "예고 1.6초: 장갑 살아 있다 %s · 적 목록에 %s · 쓰러진 몸 목록에 %s · 트롤 체력 %s(650) · 골드 변화 %d(0)" % [a.alive, a in b.enemies, b.fallen.any(func(f): return is_same(f.who, a)), w.hp, b.gold - gold]
	var s := _hungry(400.0)
	var sa = s[0].spawn_enemy("armored", Vector2i(11, 10), PREY)
	if not _ever(s[0], s[1], "devour", 0.1):
		return "기절 판: 0.1초 안에 집어 먹기 예고를 시작하지 않았다(cast %s)" % [s[1].cast]
	_steps(s[0], 10)
	s[1].fx["test_stun"] = {"stun": true, "left": 1.0}
	s[0].step(DT)
	var off: bool = s[1].cast == null and s[1].fx.has("stagger")
	var was: Vector2 = sa.pos
	_steps(s[0], 20)
	if not (off and sa.alive and sa.pos.distance_to(was) > 1.0 and s[1].hp == 400.0):
		return "기절: 다음 스텝에 예고 없음·비틀거림 %s · 장갑 살아 있다 %s · 그 뒤 1초에 걸은 칸 %.2f(1 넘게) · 트롤 체력 %s(400)" % [off, sa.alive, sa.pos.distance_to(was), s[1].hp]
	var d := _hungry(400.0)
	var da = _still(d[0], "armored", Vector2(11, 10), {"hp": 100.0})
	if not _ever(d[0], d[1], "devour", 0.1):
		return "졸개 쓰러짐 판: 0.1초 안에 집어 먹기 예고를 시작하지 않았다(cast %s)" % [d[1].cast]
	_steps(d[0], 10)
	d[0].damage(da, BIG, "true")
	d[0].step(DT)
	if d[1].cast != null or d[1].hp != 400.0 or d[1].fx.has("stagger"):
		return "졸개가 먼저 쓰러진 다음 스텝: 예고 %s(없어야 한다) · 체력 %s(400) · 비틀거림 %s(없어야 한다)" % [d[1].cast, d[1].hp, d[1].fx.has("stagger")]
	for c in [["체력 60%", 600.0, "armored", Vector2(11, 10)], ["졸개가 3칸 밖", 400.0, "armored", Vector2(13, 10)], ["사슬 오크", 400.0, CH, Vector2(11, 10)]]:
		var n := _hungry(c[1])
		_still(n[0], c[2], c[3])
		if _ever(n[0], n[1], "devour", 3.0):
			return "%s: 3초 안에 집어 먹기 예고를 시작했다(cast %s)" % [c[0], n[1].cast]
	return ""

# EV944 · S329 ②: 쓰러진 형제의 몸으로 걸어가 가장 가까운 영웅 자리에 원 예고 1.5초 → 몸이 0.6초 날아 원 안 아군에 40. 몸은 다시 일어나지 않고 한 번만 던진다
func ev944():
	var g := _pairup()
	var b = g[0]
	var why := _need(b, [TT])
	if why != "":
		return why
	var h = g[1]
	var x = g[2]
	var y = g[3]
	var cut: float = b.armor_mult(b.armor_of(h))
	var gold: int = b.gold
	var d0: float = x.pos.distance_to(y.pos)
	b.damage(y, BIG, "true")
	if y.alive or not is_same(x.get("twin"), y) or b.gold != gold + 50:
		return "Y를 쓰러뜨린 뒤: Y 살아 있다 %s · X가 맡은 몸이 Y다 %s · 골드 변화 %d(50)" % [y.alive, is_same(x.get("twin"), y), b.gold - gold]
	_steps(b, 60)
	if d0 - x.pos.distance_to(y.pos) <= 3.0:
		return "3초 뒤 X와 몸 사이 거리 %.2f(처음 %.2f에서 3칸 넘게 줄어야 한다)" % [x.pos.distance_to(y.pos), d0]
	if not _ever(b, x, "twin", 5.0) or x.pos.distance_to(y.pos) > 1.5 or x.cast.get("at") == null or x.cast.at.distance_to(Vector2(18, 10)) > 0.1:
		return "8초 안에 몸 곁(1.5칸 안)에서 (18,10)에 형제 던지기 예고를 띄우지 않았다(cast %s · 몸까지 %.2f)" % [x.cast, x.pos.distance_to(y.pos)]
	_steps(b, 28)
	if h.hp != h.max_hp or not b.lobs.is_empty():
		return "예고 1.4초: 영웅이 잃은 체력 %s(0) · 던진 것 %s(없어야 한다)" % [_lost(h), b.lobs]
	_steps(b, 6)
	if b.lobs.size() != 1 or b.lobs[0].get("look") != "twin" or x.twin != null:
		return "예고 1.7초: 던진 것 %s(look twin 하나) · X가 맡은 몸 %s(없어야 한다)" % [b.lobs, x.twin]
	_steps(b, 12)
	if not b.lobs.is_empty() or absf(_lost(h) - 40.0 * cut) > 0.01 or b.enemies.size() != 1:
		return "예고 2.3초: 던진 것 %s(없어야 한다) · 영웅이 잃은 체력 %s(%s) · 판의 적 %d(1)" % [b.lobs, _lost(h), 40.0 * cut, b.enemies.size()]
	var again := false
	for i in 200:
		b.step(DT)
		again = again or _casting(x, "twin")
	if again or b.enemies.size() != 1:
		return "그 뒤 10초: 형제 던지기 예고를 다시 띄웠다 %s · 판의 적 %d(1)" % [again, b.enemies.size()]
	var s := _pairup()
	var sx = s[2]
	var sy = s[3]
	s[0].damage(sy, BIG, "true")
	if not _ever(s[0], sx, "twin", 8.0):
		return "둘째 판: 8초 안에 형제 던지기 예고를 띄우지 않았다(cast %s)" % [sx.cast]
	_steps(s[0], 10)
	sx.fx["test_stun"] = {"stun": true, "left": 0.5}
	s[0].step(DT)
	var kept: bool = sx.cast == null and is_same(sx.twin, sy)
	var early := false
	for i in 110:
		s[0].step(DT)
		early = early or _casting(sx, "twin")
	return check(kept and not early and _ever(s[0], sx, "twin", 1.5), "기절: 다음 스텝에 예고 없음·몸 그대로 %s · 5.5초 안에 다시 예고 %s(없어야 한다) · 7초 안에 다시 예고 %s(있어야 한다)" % [kept, early, _casting(sx, "twin")])

# EV945 · S329: 무리 2로 함께 나오고 짝 번호가 0·1이다. 스킬 차례는 집어 먹기가 먼저다. 봉인되면 스킬도 재생도 멈춘다
func ev945():
	var wb = battle({"waves": [[{"kind": TT, "count": 2}]]})
	var why := _need(wb, [TT])
	if why != "":
		return why
	wb.start_battle()
	if not run(wb, 1.0, func(): return not wb.enemies.is_empty()):
		return "1초 안에 쌍둥이 트롤이 나오지 않았다"
	var mates: Array = wb.enemies.map(func(e): return e.get("mate"))
	mates.sort()
	if wb.enemies.size() != 2 or wb.enemies.any(func(e): return e.kind != TT) or mates != [0, 1]:
		return "첫 적이 나온 스텝에 나온 적 %s(쌍둥이 트롤 2) · 짝 번호 %s([0, 1])" % [wb.enemies.map(func(e): return e.kind), mates]
	var g := _lair(Vector2i(15, 10), {"hp": 1000.0})
	g[2].hp = 400.0
	_still(g[0], "armored", Vector2(11, 10))
	run(g[0], 0.2, func(): return g[2].cast != null)
	if not _casting(g[2], "devour"):
		return "체력 40%%·졸개·영웅이 다 있을 때 처음 뜬 예고 %s(devour)" % [g[2].cast]
	var s := _lair(Vector2i(15, 10), {"hp": 1000.0})
	s[2].hp = 400.0
	_still(s[0], "armored", Vector2(11, 10))
	s[2].fx["test_seal"] = {"seal": true, "left": BIG}
	var cast := false
	for i in 60:
		s[0].step(DT)
		cast = cast or s[2].cast != null
	return check(not cast and s[2].hp == 400.0, "봉인 3초: 예고를 띄웠다 %s(없어야 한다) · 체력 %s(400)" % [cast, s[2].hp])

func _cells() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://art/units/heroes.json"))

# EV946 · I271 ③·I272 ③·I273 ⑥·I274: 트롤 그림과 쌍둥이의 2배·색, 테 두른 재생 십자, 쓸기 부채꼴 테두리와 안쪽 칠, 던지기 원 테(숨어도), 날아가는 바위·몸과 그림자,
# 던진 뒤 자세, 집어 먹기 예고(졸개 둘레 테와 선)와 사건, 맡은 몸
func ev946():
	var b = battle()
	var why := _need(b, [TR, TT])
	if why != "":
		return why
	var art := _cells()
	if not art.has("troll") or not art.troll.has("fall"):
		return "heroes.json에 troll 칸(fall 포함)이 없다"
	var a: Dictionary = art.troll
	var c: int = int(a.c)
	var idle := Rect2(int(a.x), int(a.idle), c, c)
	var lying := Rect2(int(a.x), int(a.fall), 2 * c, 2 * c)
	var v = _trec(b)
	for need in ["_regen_marks", "_feed_marks", "_lob_marks", "_twin_bodies"]:
		if not v.has_method(need):
			v.free()
			return "BattleView에 %s가 없다" % need
	var bodies := [_cut(v, _still(b, TR, Vector2(5, 5), {"hp": 100.0})), _cut(v, _still(b, TT, Vector2(10, 5), {"hp": 100.0})), _cut(v, _still(b, TT, Vector2(15, 5), {"hp": 100.0}))]
	v.free()
	if bodies.any(func(x): return x == null):
		return "트롤 싸움꾼·쌍둥이 트롤 몸통이 그림 한 장이 아니다(%s)" % [bodies]
	if bodies.any(func(x): return x[1] != idle) or bodies[1][0].size != bodies[0][0].size * 2.0 or bodies[2][0].size != bodies[0][0].size * 2.0 or bodies[1][2] == bodies[2][2]:
		return "몸통: 원본 %s(셋 다 %s) · 대상 크기 %s(쌍둥이는 싸움꾼의 2배) · 쌍둥이 색 %s·%s(달라야 한다)" % [bodies.map(func(x): return x[1]), idle, bodies.map(func(x): return x[0].size), bodies[1][2], bodies[2][2]]
	var rb = battle()
	var rt = _still(rb, TR, Vector2(10, 10), {"hp": 100.0})
	var rv = _trec(rb)
	var cross := func() -> int:
		rv.lines = []
		rv._foes = rv.foes()
		rv._regen_marks()
		return rv.lines.size()
	var full: int = cross.call()
	rt.hp = 50.0
	var half: int = cross.call()
	rt.fx["test_stun"] = {"stun": true, "left": BIG}
	var stunned: int = cross.call()
	rv.free()
	if full != 0 or half != 4 or stunned != 0:
		return "재생 표시 선 수: 체력 가득 %d(0) · 절반 %d(4: 어두운 테 둘과 십자 둘) · 기절 %d(0)" % [full, half, stunned]
	var g := _brawl([Vector2i(11, 10), Vector2i(11, 11), Vector2i(9, 10)])
	if not _ever(g[0], g[1], "swat", 0.1):
		return "0.1초 안에 쓸기 예고를 시작하지 않았다(cast %s)" % [g[1].cast]
	var sv = _trec(g[0])
	var told: bool = g[1] in sv.tellers()
	var col: Color = sv.tell_color(g[1])
	sv.clock = 0.0
	sv._foes = sv.foes()
	sv._tells()
	var rim: int = sv.lines.size()
	var fill: Array = sv.polys
	sv.clock = 0.25
	sv.lines = []
	sv.polys = []
	sv._tells()
	var dim: Array = [sv.lines.size(), sv.polys.size()]
	sv.free()
	if not told or col != Color("ef692f") or rim != 8 or fill.size() != 1 or fill[0][0].size() != 8 or not fill[0][1].is_equal_approx(Color(Color("ef692f"), 0.2)) or dim != [0, 1]:
		return "쓸기 예고: 그리는 적에 %s · 색 %s(ef692f) · 켜진 때 테두리 선 %d(8)·안쪽 칠 %s(점 8개에 ef692f 알파 0.2 하나) · 꺼진 때 [선, 칠] %s([0, 1])" % [told, col.to_html(false), rim, fill.map(func(x): return [x[0].size(), x[1]]), dim]
	var l := _lair(Vector2i(15, 10))
	var w = l[2]
	if not _ever(l[0], w, "lob", 0.1):
		return "0.1초 안에 집어 던지기 예고를 시작하지 않았다(cast %s)" % [w.cast]
	var lv = _trec(l[0])
	var mid := Vector2i(lv._center(w.cast.at).floor())
	var red: Color = lv.tell_color(w)
	lv._foes = lv.foes()
	lv._foe_tells()
	var ring: bool = lv.edges.any(func(x): return x[0] == mid and x[1] == 24)
	if not run(l[0], 2.0, func(): return not l[0].lobs.is_empty()):
		lv.free()
		return "2초 안에 바위를 던지지 않았다"
	_steps(l[0], 2)
	var toss = _cut(lv, w)  # 던진 뒤 0.1초: 던진 쪽(동)을 보는 공격 키 포즈
	_steps(l[0], 3)
	lv.edges = []
	lv._foes = lv.foes()
	lv._foe_tells()
	var air_ring: bool = lv.edges.any(func(x): return x[0] == mid and x[1] == 24)
	lv._lob_marks()
	var line: float = lv._center(w.pos).y
	var discs: Array = lv.discs
	var shade: Array = lv.shadows
	var rock: bool = discs.size() == 2 and discs[0][1] == 4 and discs[1][1] == 3 and discs[0][0] == discs[1][0] and discs[0][0].y < int(line)
	var shaded: bool = shade.size() == 1 and absf(shade[0][0].y - line) < 0.01 and shade[0][0].x > lv._center(w.pos).x and shade[0][0].x < float(mid.x)
	run(l[0], 2.0, func(): return l[0].lobs.is_empty())
	_steps(l[0], 1)
	var landed = _cut(lv, w)  # 바위가 떨어진 뒤: 자세를 바꾸지 않는다
	lv.free()
	var swing := Rect2(int(a.x), int(a.attack) + 2 * c, 2 * c, 2 * c)
	if red != Color("ef3a0c") or not ring or not air_ring or not rock or not shaded:
		return "집어 던지기: 예고 색 %s(ef3a0c) · 예고 테(가운데 %s, 반지름 24) %s · 바위가 나는 동안 테 %s · 바위 점 원 %s(같은 자리에 반지름 4·3, 선분보다 위) · 그림자 %s(선분 위 하나)" % [red.to_html(false), mid, ring, air_ring, discs, shade]
	if toss == null or toss[1] != swing or landed == null or landed[1].size != Vector2(c, c):
		return "집어 던지기 자세: 던진 뒤 0.1초 원본 %s(공격 동쪽 칸 %s) · 떨어진 뒤 원본 %s(정지 칸 크기 %d)" % [toss[1] if toss else null, swing, landed[1] if landed else null, c]
	var hg := _hungry(400.0)
	var hw = hg[1]
	var prey = hg[0].spawn_enemy("armored", Vector2i(11, 10), PREY)
	if not _ever(hg[0], hw, "devour", 0.1) or not is_same(hw.cast.get("who"), prey):
		return "0.1초 안에 장갑을 집은 집어 먹기 예고를 시작하지 않았다(cast %s)" % [hw.cast]
	var dv = _trec(hg[0])
	dv._foes = dv.foes()
	dv._tells()
	var rings: int = dv.edges.size()
	dv.lines = []
	dv._feed_marks()
	var chest := Vector2i(dv._chest(prey).floor())
	var girth: int = int(dv.CELL * prey.radius) + 4
	var grip: bool = dv.edges == [[chest, girth]] and dv.lines == [[Vector2i(dv._chest(hw).floor()), chest]]
	var marks: Array = [dv.edges, dv.lines]
	dv.free()
	if rings != 0 or not grip:
		return "집어 먹기 예고: 예고·오라 그리기의 테 %d(0) · 졸개 둘레 [테, 선] %s(테 [%s, %d] 하나와 쌍둥이 가슴에서 졸개 가슴까지 선 하나)" % [rings, marks, chest, girth]
	var fv = load("res://src/ui/battle_view.gd").new()
	fv.battle = hg[0]
	fv.tick(0.0)
	var kinds := []
	for i in 40:
		hg[0].step(DT)
		fv.tick(DT)
		kinds.append_array(fv.events.filter(func(x): return x.src == hw).map(func(x): return x.kind))
	fv.free()
	if kinds != ["feed"]:
		return "집어 먹기 예고부터 2초 동안 쌍둥이 트롤이 낸 사건 %s([feed] 하나, boss 없음)" % [kinds]
	var n := _one("ignis", Vector2i(10, 10), {}, {"nights": NIGHT})
	var nb = n[0]
	n[1].sight = 0.0
	n[1].damage = 0.0
	_start(nb)
	run(nb, 1.0)
	var nt = _still(nb, TT, Vector2(4, 10))
	_steps(nb, 2)
	if nb.dark < 1.0 or nb.seen(nt.pos) or not _casting(nt, "lob"):
		return "시험 조건이 틀렸다: 어둠 %.2f · 쌍둥이 트롤이 보인다 %s · 예고 %s" % [nb.dark, nb.seen(nt.pos), nt.cast]
	var nv = load("res://src/ui/battle_view.gd").new()
	nv.battle = nb
	var hid: bool = nt in nv.tellers()
	nv.free()
	if not hid:
		return "밤 판: 숨은 쌍둥이 트롤의 집어 던지기 예고를 그리지 않는다"
	var p := _pairup()
	var pb = p[0]
	pb.damage(p[3], BIG, "true")
	_steps(pb, 60)
	var pv = _trec(pb)
	pv._twin_bodies()
	var body: Array = pv.cuts
	if not run(pb, 8.0, func(): return not pb.lobs.is_empty()):
		pv.free()
		return "8초 안에 몸을 던지지 않았다"
	_steps(pb, 3)
	pv.cuts = []
	pv._twin_bodies()
	var left: int = pv.cuts.size()
	pv.cuts = []
	pv.shadows = []
	pv._lob_marks()
	var flown: Array = pv.cuts
	var under: int = pv.shadows.size()
	var hurl = _cut(pv, p[2])  # 던진 뒤 0.15초: 몸이 나는 쪽(동)을 보는 공격 키 포즈
	pv.free()
	return check(body.size() == 1 and body[0][1] == lying and left == 0 and flown.size() == 1 and flown[0][1] == lying and under == 1 and hurl != null and hurl[1] == swing,
		"맡은 몸: 3초 뒤 그림 %s(원본 %s 한 장) · 몸이 나는 동안 맡은 몸 그림 %d(0) · 나는 몸 그림 %s(원본 %s 한 장) · 그림자 %d(1) · 던진 쌍둥이 원본 %s(공격 동쪽 칸 %s)" % [body.map(func(x): return x[1]), lying, left, flown.map(func(x): return x[1]), lying, under, hurl[1] if hurl else null, swing])

# EV947 · I274: 트롤 칸(x 있음, one 없음)의 4행 모든 칸과 누운 자세, 빌린 그림·큰 몸·쌍둥이 색 표, 아틀라스 자리(주민 띠 오른쪽 잔해 아래)
func ev947():
	var art := _cells()
	if not art.has("troll"):
		return "heroes.json에 troll 칸이 없다"
	var a: Dictionary = art.troll
	if not a.has("x") or a.has("one") or ["idle", "walk", "attack", "fall"].any(func(k): return not a.has(k)):
		return "troll 칸 x %s · one %s · idle %s · walk %s · attack %s · fall %s" % [a.get("x"), a.get("one"), a.get("idle"), a.get("walk"), a.get("attack"), a.get("fall")]
	var img: Image = load("res://art/units/heroes.png").get_image()
	var whole := Rect2i(Vector2i.ZERO, img.get_size())
	var c: int = int(a.c)
	var x: int = int(a.x)
	var cells := []
	for r in 4:
		cells.append(["정지 %d행" % r, Rect2i(x, int(a.idle) + r * c, c, c)])
		for k in 2:
			cells.append(["걷기 %d열 %d행" % [k, r], Rect2i(x + k * c, int(a.walk) + r * c, c, c)])
		cells.append(["공격 %d행" % r, Rect2i(x, int(a.attack) + 2 * r * c, 2 * c, 2 * c)])
	cells.append(["누운 자세", Rect2i(x, int(a.fall), 2 * c, 2 * c)])
	var bad := []
	for d in cells:
		if not whole.encloses(d[1]):
			bad.append("%s %s가 그림 밖" % d)
		elif img.get_region(d[1]).is_invisible():
			bad.append("%s 빈 칸" % d[0])
	var consts: Dictionary = (load("res://src/ui/battle_view.gd") as Script).get_script_constant_map()
	var looks: Dictionary = consts.get("LOOKS", {})
	var twins = consts.get("TWINS")
	if looks.has(TR) or not looks.has(TT) or looks[TT][0] != TR or consts.get("GROW", {}).get(TT, [0.0])[0] != 2.0:
		bad.append("LOOKS troll %s(없어야 한다) · twin_troll %s(troll 그림) · GROW twin_troll %s(2)" % [looks.has(TR), looks.get(TT), consts.get("GROW", {}).get(TT)])
	if not twins is Array or twins.size() != 2 or twins[0] == twins[1]:
		bad.append("TWINS %s(서로 다른 색 둘)" % [twins])
	var wreck: Dictionary = art.wreck
	var top: int = int(wreck.idle) + 4 * int(wreck.c)
	var rects := [["정지", Rect2i(x, int(a.idle), c, 4 * c)], ["걷기", Rect2i(x, int(a.walk), 2 * c, 4 * c)], ["공격", Rect2i(x, int(a.attack), 2 * c, 8 * c)], ["누운 자세", Rect2i(x, int(a.fall), 2 * c, 2 * c)]]
	if x != int(wreck.x):
		bad.append("x %d(잔해 x %d)" % [x, int(wreck.x)])
	for i in rects.size():
		var r: Rect2i = rects[i][1]
		if r.position.y < top or not whole.encloses(r):
			bad.append("%s %s가 잔해 아래(y %d~) 그림 안이 아니다" % [rects[i][0], r, top])
		for j in i:
			if r.intersects(rects[j][1]):
				bad.append("%s가 %s와 겹침" % [rects[i][0], rects[j][0]])
	if img.get_size() != Vector2i(828, 15656):
		bad.append("heroes.png %s(828×15656)" % img.get_size())
	return check(bad.is_empty(), "%s" % [bad])
