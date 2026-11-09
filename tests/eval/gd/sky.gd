extends "res://tests/eval/gd/lib.gd"
# 4라운드 하늘 둥지 묶음 ①(S109 2026-11-09 변경·S303~S306·I250~I252). lib.gd·heroes.gd 머리의 계약에 더하는 API:
#   적 kind "feather_harpy"(깃털 사수 하피, S304) · "dive_harpy"(박치기 하피, S305) · "song_harpy"(노래하는 하피, S306)
#   Battle.feathers — 날아가는 깃털 [{pos, target, ...}](S304) · armor_of(대상) · armor_mult(방어력) · effect(대상, 키) · effect_sum(대상, 키) · seen(자리) · dark
#   적 cast {id "dive", left, who(대상)} — 활강하는 동안은 air가 참이다(S305) · 유닛 prey(대상 공격의 대상) · 영웅 cd[칸] · Battle.toggle_auto · cast(영웅, 칸, aim)
#   BattleView: _body(몸, 번호, next) · _region · _pline · _pring · _shadow · _seen · _feathers() · _tells() · _foes · _center · status_marks(x, ally) · NOTE · tellers() · foes() · tell_color(적)
# 판은 lib.gd battle()의 들판(30×20, 거점 (25,10), 출현 지점 (0,10))이다. 영웅은 stage heroes [{kind, cell, level}]로 둔다(heroes.gd와 같다)

const FH := "feather_harpy"
const DH := "dive_harpy"
const SH := "song_harpy"
const HEROES := ["aias", "sylvia", "seraphina", "vesper", "ignis", "chronos"]
const ONE := [{"kind": "basic", "count": 1}]  # 적 하나짜리 웨이브
const STILL := {"speed": 0, "sight": 0, "damage": 0, "hp": BIG}  # 움직이지도 치지도 않는 과녁
const TOP := Vector2i(12, 9)  # 성곽 판의 성벽 칸
const IN := Vector2i(10, 4)  # 성곽 판의 마을 칸
const GATES := [Vector2i(5, 9), Vector2i(15, 9), Vector2i(25, 9)]

# 그림 한 장·선·고리·그림자를 그리는 대신 모으는 화면
class Rec extends "res://src/ui/battle_view.gd":
	var cuts := []  # [대상 사각형, 원본 사각형, 색]
	var lines := []  # [가, 나]
	var rings := []  # [가운데, 반지름]

	func _region(_tex: Texture2D, dst: Rect2, src: Rect2, tint: Color) -> void:
		cuts.append([dst, src, tint])

	func _pline(a: Vector2i, b: Vector2i, _col: Color, _w := 1) -> void:
		lines.append([a, b])

	func _pring(c: Vector2i, r: int, _th: int, _col: Color, _dash := 0, _spin := 0.0) -> void:
		rings.append([c, r])

	func _shadow(_at: Vector2, _r: float) -> void:
		pass

func _need(b, kinds: Array) -> String:
	for k in kinds:
		if not b.ENEMY_KINDS.has(k):
			return "적 종류 %s가 없다" % k
	return ""

# kind 적을 at(칸 좌표, 실수 자리)에 둔다. 기본은 움직이지도 치지도 않는 과녁이다
func _still(b, kind: String, at: Vector2, over := {}):
	var e = b.spawn_enemy(kind, Vector2i(at.round()), STILL.merged(over, true))
	e.pos = at
	return e

# 들판 판에 유닛 kind 하나를 cell에 세운다. 영웅은 레벨 5로 stage heroes에, 용병은 준비 단계에 over 수치로 놓는다. [판, 유닛]
func _one(kind: String, cell: Vector2i, over := {}, stage := {}) -> Array:
	var base := {"base_hp": BIG, "waves": [ONE]}
	if kind in HEROES:
		var hb = battle(base.merged({"heroes": [{"kind": kind, "cell": cell, "level": 5}]}).merged(stage, true))
		return [hb, hb.heroes[0]]
	var b = battle(base.merged(stage, true))
	return [b, b.place_merc(kind, cell, over)]

# 전투 단계를 연다. 웨이브 적은 처치하고, 움직이지도 치지도 않는 적 하나를 구석 (0,19)에 남겨 전투 단계가 이어지게 한다(heroes.gd _start)
func _start(b) -> void:
	b.start_battle()
	run(b, 5.0, func(): return not b.enemies.is_empty())
	var idle = b.spawn_enemy("basic", Vector2i(0, 19), {"speed": 0, "sight": 0, "damage": 0})
	for x in b.enemies.duplicate():
		if x != idle:
			b.damage(x, BIG)

func _steps(b, n: int) -> void:
	for i in n:
		b.step(DT)

# 박치기 예고 중이다(활강 전)
func _diving(e) -> bool:
	return e.cast != null and e.cast.id == "dive" and not e.cast.get("air", false)

# 성곽 판: 9행이 가로 성곽(성문 5·15·25열, 모두 닫힘), 위쪽(0~8행)이 마을, 아래쪽이 들판(units.gd와 같다)
func _castle():
	var walls := []
	for x in 30:
		if Vector2i(x, 9) not in GATES:
			walls.append(Vector2i(x, 9))
	return battle({"base": Vector2i(15, 4), "spawns": [Vector2i(15, 19)], "village": Rect2i(0, 0, 30, 9), "base_hp": BIG,
		"castle": {"walls": walls, "gates": GATES, "wall_hp": 300, "gate_hp": 150}})

# 마을에 놓은 용병을 성벽 위 그 칸에 올린다. 못 오르면 null
func _up(b, kind: String, cell: Vector2i, over := {}):
	var m = b.place_merc(kind, IN, over)
	b.order_move([m], cell)
	return m if run(b, 30.0, func(): return m.on_wall and near(m.pos, cell)) else null

func _rec(b):
	var v = Rec.new()
	v.battle = b
	return v

# 몸 x를 한 번 그려 [대상, 원본, 색]. 그림이 한 장이 아니면 null
func _cut(v, x):
	v.cuts = []
	var next := {}
	v._body(x, v.battle.units.size() + v.battle.enemies.find(x), next)
	v._seen = next
	if v.cuts.size() != 1:
		return null
	return v.cuts[0]

# EV833 · S109: 들판의 병사·아이아스는 옆 1칸의 날고 있는 과녁을 5초 동안 깎지 못하고, 궁수·실비아는 깎는다. 땅 과녁은 넷 모두 깎는다(S109 2026-11-09 변경)
func ev833():
	for kind in ["soldier", "aias", "archer", "sylvia"]:
		for foe in ["flying", "basic"]:
			var r := _one(kind, Vector2i(10, 10))
			var b = r[0]
			if r[1] == null:
				return "%s를 세우지 못했다" % kind
			var e = _still(b, foe, Vector2(11, 10))
			run(b, 5.0)
			var hit: bool = e.hp < e.max_hp
			var want: bool = foe == "basic" or kind in ["archer", "sylvia"]
			if hit != want:
				return "%s가 옆 1칸의 %s 과녁을 5초 동안 %s" % [kind, foe, "깎았다(깎지 못해야 한다)" if hit else "깎지 못했다(깎아야 한다)"]
	return ""

# EV834 · S109: 봉인된 비행 적과 내려앉은 글라이더는 날고 있지 않아 병사가 친다
func ev834():
	var r := _one("soldier", Vector2i(10, 10))
	var b = r[0]
	var e = _still(b, "flying", Vector2(11, 10))
	e.fx["test_seal"] = {"seal": true, "left": 30.0}
	if not run(b, 5.0, func(): return e.hp < e.max_hp):
		return "병사가 봉인된 비행 적을 5초 동안 깎지 못했다"
	r = _one("soldier", Vector2i(10, 10))
	b = r[0]
	var g = _still(b, "glider", Vector2(11, 10), {"flying": false})
	return check(run(b, 5.0, func(): return g.hp < g.max_hp), "병사가 내려앉은 글라이더를 5초 동안 깎지 못했다")

# EV835 · S109: 병사는 몸이 닿은 날고 있는 적도 치지 않고, 인식 범위 안의 날고 있는 적에게 다가가지 않으며, 대상 공격으로 골라도 그 명령을 놓는다
func ev835():
	for foe in ["flying", "basic"]:
		var r := _one("soldier", Vector2i(10, 10))
		var b = r[0]
		var e = _still(b, foe, Vector2(12, 10), {"radius": 2.0})
		run(b, 5.0)
		if (e.hp < e.max_hp) != (foe == "basic"):
			return "병사가 몸이 닿은 몸 반지름 2인 %s 과녁을 5초 동안 %s" % [foe, "깎았다" if e.hp < e.max_hp else "깎지 못했다"]
	for foe in ["flying", "basic"]:
		var r := _one("soldier", Vector2i(10, 10))
		var b = r[0]
		var m = r[1]
		var at: Vector2 = m.pos
		var e = _still(b, foe, Vector2(13, 10))
		run(b, 5.0)
		var moved: float = m.pos.distance_to(at)
		var hit: bool = e.hp < e.max_hp
		if foe == "flying" and (moved > 0.1 or hit):
			return "병사가 인식 범위 안의 날고 있는 과녁에 %.2f칸 다가갔다(깎음 %s)" % [moved, hit]
		if foe == "basic" and not hit:
			return "병사가 인식 범위 안의 땅 과녁에 다가가 깎지 않았다(%.2f칸 감)" % moved
	var r := _one("soldier", Vector2i(10, 10))
	var b = r[0]
	var m = r[1]
	var at: Vector2 = m.pos
	var e = _still(b, "flying", Vector2(13, 10))
	b.order_attack([m], e)
	run(b, 1.0)
	return check(m.prey == null and m.pos.distance_to(at) <= 0.1, "날고 있는 과녁을 대상 공격으로 고른 병사: 대상이 남음 %s · %.2f칸 감" % [m.prey != null, m.pos.distance_to(at)])

# EV836 · S109: 아이아스 Q 방패 강타·E 반격의 태세는 날고 있는 적에 들지 않고, W 전장의 포효는 걸린다
func ev836():
	var r := _one("aias", Vector2i(10, 10))
	var b = r[0]
	var h = r[1]
	_start(b)
	var fly = _still(b, "flying", Vector2(11, 9.7))
	var foot = _still(b, "basic", Vector2(11, 10.3))
	var f0: float = fly.hp
	var g0: float = foot.hp
	if not b.cast(h, "q", Vector2(12, 10)):
		return "아이아스가 Q를 쓰지 못했다"
	var q := [foot.hp < g0, b.effect(foot, "stun") != null, fly.hp == f0, b.effect(fly, "stun") == null]
	if q != [true, true, true, true]:
		return "Q 방패 강타: 땅 과녁 깎임·기절 %s · 날고 있는 과녁 그대로·기절 없음 %s" % [q.slice(0, 2), q.slice(2)]
	if not b.cast(h, "w"):
		return "아이아스가 W를 쓰지 못했다"
	if b.effect(fly, "taunt") != h or b.effect_sum(fly, "armor") >= 0.0:
		return "W 전장의 포효: 날고 있는 과녁 도발 %s · 방어력 증감 %s" % [b.effect(fly, "taunt") == h, b.effect_sum(fly, "armor")]
	if not b.cast(h, "e"):
		return "아이아스가 E를 쓰지 못했다"
	b.damage(h, 20.0)
	var fly2 = _still(b, "flying", h.pos + Vector2(1, -0.3))  # 요새화 중인 Q가 밀어낸 과녁 대신 반경 2 안에 새로 둔다
	var foot2 = _still(b, "basic", h.pos + Vector2(1, 0.3))
	f0 = fly2.hp
	g0 = foot2.hp
	b.cast(h, "e")  # 태세 중에 다시 누르면 바로 터뜨린다(S151)
	return check(foot2.hp < g0 and fly2.hp == f0, "E 반격의 태세 터뜨림: 땅 과녁 %.1f → %.1f · 날고 있는 과녁 %.1f → %.1f" % [g0, foot2.hp, f0, fly2.hp])

# EV837 · S109·I244: 아이아스 Q·E 오토는 날고 있는 적만 둘레에 있으면 쓰지 않고, 땅 적이면 쓴다
func ev837():
	for foe in ["flying", "basic"]:
		var r := _one("aias", Vector2i(10, 10))
		var b = r[0]
		var h = r[1]
		_start(b)
		b.toggle_auto(h, "q")
		b.toggle_auto(h, "e")
		for p in [Vector2(11, 10), Vector2(10, 11), Vector2(9, 10)]:
			_still(b, foe, p)
		var used := run(b, 3.0, func(): return h.cd.q > 0.0 or h.cd.e > 0.0)
		if used != (foe == "basic"):
			return "%s 과녁 셋 곁의 아이아스 Q·E 오토: 3초 안에 %s(대기 Q %.1f · E %.1f)" % [foe, "썼다(쓰지 않아야 한다)" if used else "쓰지 않았다(써야 한다)", h.cd.q, h.cd.e]
	return ""

# EV840 · S304: 깃털 사수 하피는 궁수에서 5칸 안에 들면 멈춰 깃털을 쏜다. 피해는 깃털이 닿을 때이고 1.5초마다 쏜다
func ev840():
	var r := _one("archer", Vector2i(10, 12), {"hp": BIG, "damage": 0})
	var b = r[0]
	var why := _need(b, [FH])
	if why != "":
		return why
	var a = r[1]
	var f = b.spawn_enemy(FH, Vector2i(3, 10), {"hp": BIG})
	var want: float = 3.0 * b.armor_mult(b.armor_of(a))
	var t := 0.0
	var stop_t := -1.0
	var at := Vector2.ZERO
	var moved := 0.0
	var early := false  # 깃털이 처음 나간 스텝에 체력이 줄었다
	var had := 0
	var drops := []  # [때, 양]
	while t < 13.0:
		var h0: float = a.hp
		var p0: Vector2 = f.pos
		b.step(DT)
		t += DT
		if stop_t < 0.0 and f.pos == p0 and f.pos.distance_to(a.pos) <= 5.0 + 0.001:
			stop_t = t
			at = f.pos
		if stop_t >= 0.0 and t - stop_t <= 3.0:
			moved = maxf(moved, f.pos.distance_to(at))
		if had == 0 and b.feathers.size() > 0 and drops.is_empty() and a.hp < h0:
			early = true
		had = b.feathers.size()
		if a.hp < h0:
			drops.append([t, h0 - a.hp])
	if stop_t < 0.0 or stop_t > 10.0:
		return "10초 안에 궁수 5칸 안에서 멈추지 않았다(자리 %s)" % f.pos
	var d: float = at.distance_to(a.pos)
	if d < 4.8 or d > 5.0 + 0.001 or moved > 0.05:
		return "멈춘 거리 %.2f(4.8~5) · 멈춘 뒤 3초 동안 %.2f칸 움직임" % [d, moved]
	if early or drops.size() < 2:
		return "깃털이 처음 나간 스텝에 체력이 줄었다 %s · 체력이 준 때 %s" % [early, drops]
	if drops.any(func(x): return absf(x[1] - want) > 0.01):
		return "한 번에 준 체력 %s(%.2f여야 한다)" % [drops.map(func(x): return x[1]), want]
	var gap: float = drops[1][0] - drops[0][0]
	return check(absf(gap - 1.5) <= 0.1 + 0.001, "체력이 주는 때의 간격 %.2f초(1.5)" % gap)

# EV841 · S304: 아군이 없으면 거점으로 가고, 도발되면 도발한 영웅을 쏘며, 봉인되면 쏘지 않는다. 대상이 쓰러지면 날던 깃털은 사라진다
func ev841():
	var b = battle()  # 아군이 없는 판
	var why := _need(b, [FH])
	if why != "":
		return why
	b.spawn_enemy(FH, Vector2i(3, 10), {"hp": BIG})
	if not run(b, 20.0, func(): return b.base.hp < b.base.max_hp):
		return "아군이 없는 판에서 20초 안에 거점을 치지 못했다"
	var t = _one("aias", Vector2i(10, 16))
	var c = t[0]
	var h = t[1]
	var a = c.place_merc("archer", Vector2i(8, 12), {"hp": BIG, "damage": 0})
	var f = c.spawn_enemy(FH, Vector2i(3, 10), {"hp": BIG})
	f.fx["test_taunt"] = {"taunt": h, "left": 30.0}
	var shot := run(c, 15.0, func(): return h.hp < h.max_hp)
	if a.hp != a.max_hp or not shot:
		return "도발된 하피: 궁수 체력 %.0f(그대로여야 한다) · 아이아스를 깎음 %s" % [a.hp, shot]
	var s := _one("archer", Vector2i(8, 12), {"hp": BIG, "damage": 0})
	var d = s[0]
	var g = d.spawn_enemy(FH, Vector2i(3, 10), {"hp": BIG})
	g.fx["test_seal"] = {"seal": true, "left": 30.0}
	run(d, 10.0)
	if s[1].hp != s[1].max_hp:
		return "봉인된 하피가 궁수를 쐈다(체력 %.0f)" % s[1].hp
	var k := _one("archer", Vector2i(10, 12), {"hp": BIG, "damage": 0})
	var x = k[0]
	var by = x.place_merc("soldier", Vector2i(11, 12), {"hp": BIG, "damage": 0})
	x.spawn_enemy(FH, Vector2i(3, 10), {"hp": BIG})
	if not run(x, 10.0, func(): return not x.feathers.is_empty()):
		return "10초 안에 깃털을 쏘지 않았다"
	x.damage(k[1], BIG)
	x.step(DT)
	var gone: bool = x.feathers.is_empty()
	var b0: float = by.hp
	run(x, 0.5)
	return check(gone and by.hp == b0, "대상이 쓰러진 뒤 깃털이 사라짐 %s · 곁의 병사 체력 %.0f → %.0f" % [gone, b0, by.hp])

# EV842 · S305: 박치기 하피는 인식 범위 안 가장 가까운 아군(방패병이 아님)에게 1초 예고 뒤 활강해 박아 반경 1 안 아군에 피해를 주고 밀친 뒤,
# 예고를 시작한 자리로 돌아가고 닿은 때부터 6초 뒤 다시 예고한다
func ev842():
	var r := _one("archer", Vector2i(10, 10), {"hp": 100.0, "damage": 0})
	var b = r[0]
	var why := _need(b, [DH])
	if why != "":
		return why
	var a1 = r[1]
	var a2 = b.place_merc("archer", Vector2i(10, 11), {"hp": 100.0, "damage": 0})
	a2.pos = Vector2(10, 10.8)
	var a3 = b.place_merc("archer", Vector2i(10, 12), {"hp": 100.0, "damage": 0})
	var d = b.spawn_enemy(DH, Vector2i(3, 10), {"hp": BIG})
	if not run(b, 10.0, func(): return _diving(d)):
		return "10초 안에 박치기 예고를 시작하지 않았다(자리 %s)" % d.pos
	if d.cast.get("who") != a1:
		return "박치기 대상이 (10,10) 궁수가 아니다"
	var from: Vector2 = d.pos
	var spot: Vector2 = a1.pos.move_toward(from, 0.4)
	var at1: Vector2 = a1.pos
	var at2: Vector2 = a2.pos
	var want: float = 100.0 - 8.0 * b.armor_mult(b.armor_of(a1))
	var t := 0.0
	var hit_t := -1.0
	var hover := 0.0
	while t < 2.0 and hit_t < 0.0:
		b.step(DT)
		t += DT
		if t < 0.95:
			hover = maxf(hover, d.pos.distance_to(from))
		if a1.hp < a1.max_hp:
			hit_t = t
	if hover > 0.05:
		return "예고 동안 %.2f칸 움직였다" % hover
	if hit_t < 1.3 - 0.001 or hit_t > 1.5 + 0.001:
		return "예고를 시작한 뒤 %.2f초에 닿았다(1.3~1.5)" % hit_t
	if not (is_equal_approx(a1.hp, want) and is_equal_approx(a2.hp, want) and a3.hp == a3.max_hp):
		return "닿은 뒤 체력 %s(앞의 둘 %.2f, 셋째 100이어야 한다)" % [[a1.hp, a2.hp, a3.hp], want]
	var push1: float = a1.pos.x - at1.x
	var push2: float = a2.pos.distance_to(spot) - at2.distance_to(spot)
	if push1 < 0.9 or push2 < 0.8:
		return "밀림: (10,10) 궁수 동쪽으로 %.2f칸(0.9 넘게) · (10,10.8) 궁수 닿은 자리에서 %.2f칸 멀어짐(0.8 넘게)" % [push1, push2]
	var since := 0.0
	var back_t := -1.0
	var next_t := -1.0
	while since < 8.0 and next_t < 0.0:
		b.step(DT)
		since += DT
		if back_t < 0.0 and d.pos.distance_to(from) <= 0.3:
			back_t = since
		if _diving(d):
			next_t = since
	if back_t < 0.0 or back_t > 3.0:
		return "닿은 뒤 3초 안에 예고를 시작한 자리로 돌아오지 않았다(%.2f초, 자리 %s, 시작 %s)" % [back_t, d.pos, from]
	return check(next_t >= 5.8 - 0.001 and next_t <= 6.3 + 0.001, "다음 예고가 닿은 때부터 %.2f초 뒤다(5.8~6.3)" % next_t)

# EV843 · S305: 방패병(병사·아이아스)에 박으면 대상은 다치지 않고 하피가 기절해 땅에 떨어진다. 떨어진 하피는 병사가 치고, 풀리면 예고를 시작한 자리로 돌아간다
func ev843():
	for kind in ["soldier", "aias"]:
		var r := _one(kind, Vector2i(10, 10), {"hp": 100.0, "damage": 2.0})
		var b = r[0]
		var why := _need(b, [DH])
		if why != "":
			return why
		var u = r[1]
		var d = b.spawn_enemy(DH, Vector2i(3, 10), {"hp": BIG})
		if not run(b, 10.0, func(): return _diving(d)):
			return "%s: 10초 안에 박치기 예고를 시작하지 않았다(자리 %s)" % [kind, d.pos]
		var from: Vector2 = d.pos
		var hp0: float = u.hp
		var t := 0.0
		while t < 2.0 and b.effect(d, "stun") == null:
			b.step(DT)
			t += DT
		if b.effect(d, "stun") == null or t < 1.3 - 0.001 or t > 1.5 + 0.001:
			return "%s: 예고를 시작한 뒤 하피가 기절하지 않았거나 때가 %.2f초다(1.3~1.5)" % [kind, t]
		if u.hp != hp0:
			return "%s: 박혔는데 체력이 %.1f → %.1f" % [kind, hp0, u.hp]
		if kind == "aias":
			continue
		var h0: float = d.hp
		var down := 0.0
		while b.effect(d, "stun") != null and down < 3.0:
			b.step(DT)
			down += DT
		if d.hp >= h0:
			return "병사가 기절한 하피를 깎지 못했다"
		if not run(b, 3.0, func(): return d.pos.distance_to(from) <= 0.3):
			return "기절이 풀린 뒤 3초 안에 예고를 시작한 자리로 돌아오지 않았다(%s, 시작 %s)" % [d.pos, from]
	return ""

# EV844 · I251: 성벽 위 궁수는 박치기에 이웃 성벽 칸으로 밀리고 성벽 위에 그대로다
func ev844():
	var b = _castle()
	var why := _need(b, [DH])
	if why != "":
		return why
	var a = _up(b, "archer", TOP, {"hp": 100.0, "damage": 0})
	if a == null:
		return "궁수가 성벽에 오르지 못했다"
	var d = b.spawn_enemy(DH, Vector2i(12, 16), {"hp": BIG})
	if not run(b, 15.0, func(): return a.hp < a.max_hp):
		return "15초 안에 박치기에 맞지 않았다(하피 %s)" % d.pos
	var c := Vector2i(a.pos.round())
	var want: float = 100.0 - 8.0 * b.armor_mult(b.armor_of(a))
	return check(a.on_wall and absi(c.x - TOP.x) == 1 and c.y == TOP.y and a.pos.distance_to(Vector2(c)) < 0.01 and is_equal_approx(a.hp, want),
		"닿은 뒤 궁수 %s(성벽 위 %s) · 체력 %.2f(%.2f)" % [a.pos, a.on_wall, a.hp, want])

# EV845 · S305·S279: 예고 중 기절이면 꺼지고 비틀거리지 않으며 대기가 처음부터 돈다. 봉인 중에는 시작하지 않는다. 숨어도 예고를 그린다
func ev845():
	var r := _one("archer", Vector2i(10, 10), {"hp": 100.0, "damage": 0})
	var b = r[0]
	var why := _need(b, [DH])
	if why != "":
		return why
	var a = r[1]
	var d = b.spawn_enemy(DH, Vector2i(3, 10), {"hp": BIG})
	if not run(b, 10.0, func(): return _diving(d)):
		return "10초 안에 박치기 예고를 시작하지 않았다(자리 %s)" % d.pos
	run(b, 0.5)
	d.fx["test_stun"] = {"stun": true, "left": 0.5}
	b.step(DT)
	var off: bool = d.cast == null
	var reel: bool = b.effect(d, "expose") != null
	var t := 0.0
	var kept := true
	var next_t := -1.0
	while t < 8.0 and next_t < 0.0:
		b.step(DT)
		t += DT
		if t <= 1.5 + 0.001:
			kept = kept and a.hp == a.max_hp
		if _diving(d):
			next_t = t
	if not off or reel or not kept or next_t < 5.8 - 0.001 or next_t > 6.3 + 0.001:
		return "기절: 예고 꺼짐 %s · 비틀거림 %s · 1.5초 동안 궁수 체력 그대로 %s · 다음 예고 %.2f초 뒤(5.8~6.3)" % [off, reel, kept, next_t]
	var s := _one("archer", Vector2i(10, 10), {"hp": 100.0, "damage": 0})
	var c = s[0]
	var q = c.spawn_enemy(DH, Vector2i(3, 10), {"hp": BIG})
	q.fx["test_seal"] = {"seal": true, "left": 30.0}
	if run(c, 10.0, func(): return q.cast != null):
		return "봉인된 하피가 10초 안에 예고를 시작했다"
	var n := _one("archer", Vector2i(10, 10), {"hp": 100.0, "damage": 0}, {"nights": [[{"at": 0.0, "dark": 1.0, "fade": 0.05}]]})
	var k = n[0]
	_start(k)
	var h = k.spawn_enemy(DH, Vector2i(3, 10), {"hp": BIG})
	if not run(k, 10.0, func(): return _diving(h)):
		return "밤 판: 10초 안에 박치기 예고를 시작하지 않았다(자리 %s)" % h.pos
	if k.dark <= 0.0 or k.seen(h.pos):
		return "시험 조건이 틀렸다: 어둠 %.2f · 하피 자리 %s가 보인다 %s(숨어야 한다)" % [k.dark, h.pos, k.seen(h.pos)]
	var v = load("res://src/ui/battle_view.gd").new()
	v.battle = k
	var told: bool = h in v.tellers()
	var drawn: bool = h in v.foes()
	var col: Color = v.tell_color(h)
	v.free()
	return check(told and not drawn and col == Color("ef692f"), "숨은 하피: 예고를 그림 %s · 몸을 그림 %s · 예고 색 %s(ef692f)" % [told, drawn, col.to_html(false)])

# EV846 · S306: 노래하는 하피 반경 3 안의 적(자기 포함)은 초당 최대 체력 3%를 회복하고, 겹쳐도 하나만 들며, 기절·봉인된 하피는 노래하지 않는다
func ev846():
	var b = battle()
	var why := _need(b, [SH])
	if why != "":
		return why
	var s = _still(b, SH, Vector2(10, 10), {"hp": 100.0})
	var near = _still(b, "basic", Vector2(12, 10), {"hp": 100.0})
	var far = _still(b, "basic", Vector2(14, 10), {"hp": 100.0})
	var full = _still(b, "basic", Vector2(11, 11), {"hp": 100.0})
	for e in [s, near, far]:
		e.hp = 50.0
	_steps(b, 20)
	var got := [s.hp - 50.0, near.hp - 50.0, far.hp - 50.0, full.hp]
	if absf(got[0] - 3.0) > 0.1 or absf(got[1] - 3.0) > 0.1 or got[2] != 0.0 or got[3] != 100.0:
		return "1초 뒤 늘어난 체력: 하피 %.2f · (12,10) %.2f(3) · (14,10) %.2f(0) · 가득 찬 적 %.1f(100)" % got
	var c = battle()
	_still(c, SH, Vector2(10, 10), {"hp": 100.0})
	_still(c, SH, Vector2(10, 11), {"hp": 100.0})
	var two = _still(c, "basic", Vector2(12, 10), {"hp": 100.0})
	two.hp = 50.0
	_steps(c, 20)
	if absf(two.hp - 53.0) > 0.1:
		return "노래하는 하피 둘 곁의 적이 1초에 %.2f 늘었다(3)" % (two.hp - 50.0)
	for key in ["stun", "seal"]:
		var k = battle()
		var q = _still(k, SH, Vector2(10, 10), {"hp": 100.0})
		q.fx["test_" + key] = {key: true, "left": 5.0}
		var m = _still(k, "basic", Vector2(12, 10), {"hp": 100.0})
		m.hp = 50.0
		_steps(k, 20)
		if m.hp != 50.0:
			return "%s 걸린 하피 곁의 적이 1초에 %.2f 늘었다(0)" % [key, m.hp - 50.0]
	return ""

# EV847 · S306: 노래 반경 안 병사의 공격 간격은 1 ÷ 0.7배가 되고 겹쳐도 같다. 걸린 공격 속도 감소는 0.3이고, 하피가 기절하면 곧 풀린다
func ev847():
	var gaps := []
	for n in [0, 1, 2]:
		var r := _one("soldier", Vector2i(10, 10))
		var b = r[0]
		if n > 0:
			var why := _need(b, [SH])
			if why != "":
				return why
		for i in n:
			_still(b, SH, Vector2(10 - i, 12))
		var e = _still(b, "basic", Vector2(11, 10))
		var times := []
		var t := 0.0
		var h0: float = e.hp
		while t < 10.0:
			b.step(DT)
			t += DT
			if e.hp < h0:
				times.append(t)
				h0 = e.hp
		if times.size() < 3:
			return "노래하는 하피 %d마리 판: 병사가 10초에 %d번만 쳤다" % [n, times.size()]
		gaps.append((times[-1] - times[0]) / (times.size() - 1))
	var want: float = gaps[0] / 0.7
	if absf(gaps[1] / want - 1.0) > 0.05 or absf(gaps[2] / want - 1.0) > 0.05:
		return "치는 간격: 하피 없음 %.3f · 하나 %.3f · 둘 %.3f(둘 다 %.3f ±5%%)" % [gaps[0], gaps[1], gaps[2], want]
	var r := _one("soldier", Vector2i(10, 10))
	var b = r[0]
	var m = r[1]
	var s = _still(b, SH, Vector2(10, 12))
	b.step(DT)
	var lag: float = b.effect_sum(m, "lag")
	s.fx["test_stun"] = {"stun": true, "left": 5.0}
	var off := run(b, 0.65, func(): return b.effect_sum(m, "lag") <= 0.0)
	return check(is_equal_approx(lag, 0.3) and off, "병사의 공격 속도 감소 %.2f(0.3) · 하피 기절 뒤 0.65초 안에 풀림 %s" % [lag, off])

# EV848 · I250: 하피 셋은 비행(하피) 그림에 색을 곱해 그리고, 날아가는 깃털은 그 자리에 선으로 그린다
func ev848():
	var b = battle()
	var why := _need(b, [FH, DH, SH])
	if why != "":
		return why
	var v = _rec(b)
	var got := []
	for k in ["flying", FH, DH, SH]:
		var e = _still(b, k, Vector2(5 + got.size() * 3, 5))
		var one = _cut(v, e)
		if one == null:
			v.free()
			return "%s 몸통이 그림 한 장이 아니다(%d장)" % [k, v.cuts.size()]
		got.append(one)
	v.free()
	var srcs: Array = got.map(func(x): return x[1])
	if srcs.any(func(x): return x != srcs[0]):
		return "원본 사각형이 비행과 다르다: %s" % [srcs]
	var tints: Array = got.map(func(x): return x[2])
	for i in tints.size():
		for j in range(i + 1, tints.size()):
			if tints[i] == tints[j]:
				return "색이 같다: %s" % [tints]
	var r := _one("archer", Vector2i(10, 12), {"hp": BIG, "damage": 0})
	var c = r[0]
	c.spawn_enemy(FH, Vector2i(3, 10), {"hp": BIG})
	if not run(c, 10.0, func(): return not c.feathers.is_empty()):
		return "10초 안에 깃털을 쏘지 않았다"
	c.step(DT)
	if c.feathers.is_empty():
		return "깃털이 한 스텝 만에 닿았다"
	var w = _rec(c)
	if not w.has_method("_feathers"):
		w.free()
		return "BattleView에 깃털 그리기(_feathers)가 없다"
	w._feathers()
	var p: Vector2 = w._center(c.feathers[0].pos)
	var lines: Array = w.lines.duplicate()
	w.free()
	return check(lines.any(func(l): return Vector2(l[0]).distance_to(p) <= 8.0 or Vector2(l[1]).distance_to(p) <= 8.0), "깃털 자리 %s 둘레 8px 안에 끝이 있는 선이 없다(선 %s)" % [p, lines])

# EV849 · I252: 노래하는 하피 둘레에 반경 3칸 고리를 그리고, 반경 안 아군에는 음표 색 점을 그린다
func ev849():
	var b = battle()
	var why := _need(b, [SH])
	if why != "":
		return why
	var note = load("res://src/ui/battle_view.gd").get_script_constant_map().get("NOTE")
	if not note is Color:
		return "BattleView.NOTE(음표 색)가 없다"
	var s = _still(b, SH, Vector2(10, 10))
	var m1 = b.place_merc("soldier", Vector2i(11, 10))
	var m2 = b.place_merc("soldier", Vector2i(20, 10))
	b.step(DT)
	var v = _rec(b)
	v._foes = v.foes()
	v._tells()
	var c := Vector2i(v._center(s.pos).floor())
	var ring: bool = v.rings.any(func(x): return x[0] == c and x[1] == 48)
	var near: bool = v.status_marks(m1, true).any(func(x): return x.get("c") == note)
	var far: bool = v.status_marks(m2, true).any(func(x): return x.get("c") == note)
	var rings: Array = v.rings.duplicate()
	v.free()
	return check(ring and near and not far, "고리(가운데 %s, 반지름 48) %s(그린 고리 %s) · 반경 안 병사 음표 %s · 반경 밖 병사 음표 %s" % [c, ring, rings, near, far])
