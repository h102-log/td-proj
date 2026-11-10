extends "res://tests/eval/gd/sky2.gd"
# 4라운드 하늘 둥지 묶음 ③(S106·S303 2026-11-10 둘째 변경·S309~S312·I255~I257). lib.gd·sky.gd·sky2.gd 머리의 계약에 더하는 API:
#   적 kind "nest_harpy"(둥지 하피) · "nest"(둥지) · "harpy_chick"(새끼 하피)(S309) · "wyvern"(와이번, S310) · "wyvern_fallen"(떨어진 와이번, S311)
#   적 cast {id "nest", at(칸)} — 둥지 짓기(S309)
#   적 cast {id "plunge", at} — 급강하 예고, {id "plunge", air 참} — 내리꽂기 · effect(와이번, "rest") — 내려앉음(S310)
#   적 cast {id "carpet", dir, to} — 융단 폭격 예고, {id "carpet", pass 참} — 지나가기 · effect(아군, "burn") — 불(S310)
#   적 cast {id "breath", dir} · {id "rush", to} · {id "tail", dir}(S311) · 적 via · Battle.fallen · Battle.wrecks · Battle.light_of(x)
#   BattleView: ART · ENEMY_COLORS · clock · status_marks(x, ally) · tellers() · _foe_tells()

const NH := "nest_harpy"
const CH := "harpy_chick"
const WY := "wyvern"
const WF := "wyvern_fallen"
const NIGHT := [[{"at": 0.0, "dark": 1.0, "fade": 0.05}]]  # 0초에 어둠 1인 밤 웨이브(sky.gd ev844와 같다)
const SPOT := Vector2i(12, 9)  # (12,15)에서 내보낸 둥지 하피가 고르는 가장 가까운 성곽 성벽 칸
const A0 := {"hp": 100.0, "damage": 0}  # 체력 100, 공격력 0인 용병

func _nesting(e) -> bool:
	return e.cast != null and e.cast.id == "nest"

func _casting(e, id: String) -> bool:
	return e.cast != null and e.cast.id == id

func _burns(b, x) -> bool:
	return b.effect(x, "burn") != null

func _chicks(b) -> Array:
	return b.enemies.filter(func(x): return x.kind == CH)

# 판 b에 용병 kind를 at(실수 자리)에 놓는다
func _merc_at(b, kind: String, at: Vector2, over := {}):
	var m = b.place_merc(kind, Vector2i(at.round()), over)
	if m != null:
		m.pos = at
	return m

# 성곽 판 b에 둥지 하피(체력 큼)를 (12,15)에 내보내 짓기 시작할 때까지 돌린다. 하피, 못 하면 까닭(글)
func _builder(b):
	var why := _need(b, [NH, "nest"])
	if why != "":
		return why
	var e = b.spawn_enemy(NH, Vector2i(12, 15), {"hp": BIG})
	if not run(b, 10.0, func(): return _nesting(e)):
		return "10초 안에 둥지를 짓기 시작하지 않았다(자리 %s · cast %s)" % [e.pos, e.cast]
	return e

# 성곽 판 b에서 둥지가 될 때까지 돌린다. 둥지(적), 못 하면 까닭(글)
func _nested(b):
	var e = _builder(b)
	if e is String:
		return e
	if not run(b, 4.0, func(): return e.kind == "nest"):
		return "짓기 시작한 뒤 4초 안에 둥지가 되지 않았다(종류 %s)" % e.kind
	return e

# 새 새끼 하피가 나올 때까지 돌린다. 나온 때(초), secs 안에 안 나오면 -1
func _next_chick(b, secs: float) -> float:
	var known := _chicks(b)
	var t := 0.0
	while t < secs:
		b.step(DT)
		t += DT
		if _chicks(b).any(func(c): return not c in known):
			return t
	return -1.0

# kind 떨어진 와이번(체력 큼)을 at에 두고 off 스킬의 대기를 99초로 둔다
func _fallen(b, at: Vector2, off: Array, over := {}):
	var e = b.spawn_enemy(WF, Vector2i(at.round()), {"hp": BIG}.merged(over, true))
	e.pos = at
	for k in off:
		e.cd[k] = 99.0
	return e

# 떨어진 와이번 f가 맹진 예고를 시작해 돌진을 마칠 때까지 돌린다. 못 하면 까닭(글), 하면 ""
func _rushed(b, f) -> String:
	if not run(b, 1.0, func(): return _casting(f, "rush")):
		return "1초 안에 맹진 예고를 시작하지 않았다(cast %s)" % [f.cast]
	if not run(b, 1.5, func(): return not _casting(f, "rush")):
		return "1.5초 안에 맹진이 끝나지 않았다"
	return ""

# 밤 판의 전투 단계를 열고 어둠이 1이 될 때까지 돌린다
func _dark(b) -> String:
	_start(b)
	run(b, 1.0)
	return "" if b.dark >= 1.0 else "전투 단계 1초에 어둠이 %s다(1이어야 한다)" % b.dark

# EV860 · S309: 가장 가까운 빈 성곽 성벽 칸에 내려앉아 3초 동안 짓고 둥지가 된다(처치가 아니다)
func ev860():
	var b = _fort()
	var why := _need(b, [NH, "nest"])
	if why != "":
		return why
	var gold0: int = b.gold
	var e = b.spawn_enemy(NH, Vector2i(12, 15), {"hp": BIG})
	if not run(b, 10.0, func(): return _nesting(e)):
		return "10초 안에 둥지를 짓기 시작하지 않았다(자리 %s · cast %s)" % [e.pos, e.cast]
	if e.pos.distance_to(Vector2(SPOT)) > 0.05 or not e.on_wall or e.cast.get("at") != SPOT:
		return "짓기 시작한 스텝: 자리 %s((12,9)에서 0.05칸 안) · 성벽 위 %s · 예고 자리 %s((12,9))" % [e.pos, e.on_wall, e.cast.get("at")]
	var t := 0.0
	while t < 3.5 and e.kind != "nest":
		b.step(DT)
		t += DT
	if t < 2.9 - 0.001 or t > 3.1 + 0.001:
		return "짓기 시작한 뒤 %.2f초에 둥지가 됐다(2.9~3.1, 종류 %s)" % [t, e.kind]
	var want: float = b.ENEMY_KINDS["nest"].hp
	if e.flying or not e.on_wall or not is_equal_approx(e.hp, want) or not is_equal_approx(e.max_hp, want) or not e.fx.is_empty():
		return "바뀐 스텝: 비행 %s · 성벽 위 %s · 체력 %s/%s(%s) · 효과 %s" % [e.flying, e.on_wall, e.hp, e.max_hp, want, e.fx]
	var at: Vector2 = e.pos
	var moved := 0.0
	for i in int(3.0 / DT):
		b.step(DT)
		moved = maxf(moved, e.pos.distance_to(at))
	return check(moved <= 0.05 and b.gold == gold0, "둥지가 된 뒤 3초 움직임 %.2f칸 · 골드 %d → %d(그대로여야 한다)" % [moved, gold0, b.gold])

# EV861 · S309: 둥지는 4초마다 새끼 하피를 낳고, 살아 있는 새끼는 셋까지다. 기절 중에는 세지 않는다. 둥지가 쓰러져도 새끼는 남는다
func ev861():
	var b = _fort()
	var why := _need(b, [NH, "nest", CH])
	if why != "":
		return why
	var n = _nested(b)
	if n is String:
		return n
	var born := []
	var first = null
	var t := 0.0
	var known := []
	while t < 12.5:
		b.step(DT)
		t += DT
		for c in _chicks(b):
			if not c in known:
				known.append(c)
				born.append(snappedf(t, 0.01))
				if first == null:
					first = c.pos
	if born.size() != 3 or absf(born[0] - 4.0) > 0.1 or absf(born[1] - 8.0) > 0.1 or absf(born[2] - 12.0) > 0.1:
		return "새끼가 나온 때 %s초(둥지가 된 때부터 4·8·12초 ±0.1이어야 한다)" % [born]
	if first.distance_to(n.pos) > 0.05:
		return "첫 새끼가 나온 자리 %s(둥지 자리 %s에서 0.05칸 안이어야 한다)" % [first, n.pos]
	if known.any(func(c): return not c.flying or c.reward != 0 or c.xp != 0):
		return "새끼 [비행, 보상, 경험치] %s(비행·0·0이어야 한다)" % [known.map(func(c): return [c.flying, c.reward, c.xp])]
	for i in int(8.0 / DT):
		b.step(DT)
	if _chicks(b).size() != 3:
		return "셋이 살아 있는 동안 8초 뒤 새끼가 %d마리다(3이어야 한다)" % _chicks(b).size()
	var g0: int = b.gold
	b.damage(_chicks(b)[0], BIG)
	if b.gold != g0:
		return "새끼를 쓰러뜨려 골드가 %d → %d가 됐다" % [g0, b.gold]
	var gap := _next_chick(b, 6.0)
	if gap < 3.9 - 0.001 or gap > 4.1 + 0.001:
		return "새끼 하나를 쓰러뜨린 뒤 %.2f초에 새로 나왔다(3.9~4.1)" % gap
	b.damage(_chicks(b)[0], BIG)
	b._fx(n, "t_stun", {"stun": true}, 1.0)
	var gap2 := _next_chick(b, 7.0)
	if gap2 < 4.9 - 0.001 or gap2 > 5.1 + 0.001:
		return "새끼를 쓰러뜨리고 둥지를 1초 기절시킨 뒤 %.2f초에 새로 나왔다(4.9~5.1)" % gap2
	var left := _chicks(b)
	var g1: int = b.gold
	b.damage(n, BIG)
	var kept: bool = left.size() == 3 and left.all(func(c): return c.alive and c in b.enemies)
	return check(not n.alive and b.gold == g1 + 10 and kept, "둥지를 쓰러뜨린 뒤: 둥지 살아 있음 %s · 골드 %d → %d(+10) · 새끼 셋 남음 %s" % [n.alive, g1, b.gold, kept])

# EV862 · S309: 대포·아군이 있는 칸은 고르지 않고, 짓는 동안은 성벽 위 근접에 맞으며, 기절·성벽이 부서지면 짓기가 취소되고 그 자리에서 기다린 뒤 다시 짓는다
func ev862():
	var a = _fort()
	if a.build("cannon", SPOT) == null:
		return "성벽 칸 (12,9)에 대포를 짓지 못했다"
	var e1 = _builder(a)
	if e1 is String:
		return "대포 판: " + e1
	if e1.cast.at == SPOT:
		return "대포가 있는 (12,9)에 짓기 시작했다"
	var c = _fort()
	if _up(c, "soldier", SPOT, {"hp": BIG, "damage": 0}) == null:
		return "병사를 성벽 위 (12,9)에 올리지 못했다"
	var e2 = _builder(c)
	if e2 is String:
		return "병사 판: " + e2
	if e2.cast.at == SPOT:
		return "병사가 선 (12,9)에 짓기 시작했다"
	var d = _fort()
	if _up(d, "soldier", Vector2i(13, 9), {"hp": BIG, "damage": 1}) == null:
		return "병사를 성벽 위 (13,9)에 올리지 못했다"
	var e3 = d.spawn_enemy(NH, Vector2i(12, 15), {"hp": BIG})
	var hp0: float = e3.hp
	if not run(d, 10.0, func(): return _nesting(e3)):
		return "병사 (13,9) 판: 10초 안에 짓기 시작하지 않았다(자리 %s)" % e3.pos
	if e3.cast.at != SPOT or e3.hp != hp0:
		return "병사 (13,9) 판: 짓는 칸 %s((12,9)) · 짓기 전 체력 %s → %s(그대로여야 한다)" % [e3.cast.at, hp0, e3.hp]
	if not run(d, 1.0, func(): return e3.hp < hp0):
		return "짓기 시작한 뒤 1초 안에 성벽 위 (13,9) 병사가 체력을 깎지 않았다"
	var f = _fort()
	var e4 = _builder(f)
	if e4 is String:
		return e4
	run(f, 1.0)
	f._fx(e4, "t_stun", {"stun": true}, 0.5)
	f.step(DT)
	if _nesting(e4) or e4.on_wall:
		return "기절시킨 다음 스텝: 예고 %s · 성벽 위 %s(둘 다 없어야 한다)" % [e4.cast, e4.on_wall]
	var t := DT
	while t < 6.0 and not _nesting(e4):
		f.step(DT)
		t += DT
		if e4.kind != NH:
			return "기절로 취소된 뒤 %.2f초에 종류가 %s가 됐다" % [t, e4.kind]
	if t < 3.9 - 0.001 or t > 4.2 + 0.001 or not _nesting(e4) or e4.cast.at != SPOT:
		return "기절시킨 뒤 %.2f초에 다시 짓기 시작했다(3.9~4.2, 예고 %s)" % [t, e4.cast]
	f.damage(f.walls[SPOT], BIG)
	f.step(DT)
	return check(not _nesting(e4), "짓던 성벽을 부순 다음 스텝에도 짓기 예고가 남았다(%s)" % [e4.cast])

# EV863 · S309: 성곽이 없으면 짓지 않고 거점을 친다. 둥지가 앉은 성벽이 부서지면 둥지도 쓰러진다(처치)
func ev863():
	var b = battle()
	var why := _need(b, [NH, "nest"])
	if why != "":
		return why
	var e = b.spawn_enemy(NH, Vector2i(0, 10), {"hp": BIG})
	var built := false
	for i in int(15.0 / DT):
		b.step(DT)
		built = built or _nesting(e) or e.kind == "nest"
	if built or b.base.hp >= b.base.max_hp:
		return "들판 판 15초: 짓기 %s · 거점 체력 %s/%s(깎아야 한다)" % [built, b.base.hp, b.base.max_hp]
	var c = _fort()
	var n = _nested(c)
	if n is String:
		return n
	var g: int = c.gold
	c.damage(c.walls[SPOT], BIG)
	return check(not n.alive and c.gold == g + 10, "앉은 성벽을 부순 바로 뒤: 둥지 살아 있음 %s · 골드 %d → %d(+10)" % [n.alive, g, c.gold])

# EV864 · S310: 급강하는 가장 몰린 아군 자리에 원 예고 뒤 내리꽂아 피해·밀기를 주고 2초 내려앉는다(그동안 근접에 맞는다)
func ev864():
	var b = battle()
	var why := _need(b, [WY])
	if why != "":
		return why
	var arch := []
	for y in [9, 10, 11]:
		arch.append(b.place_merc("archer", Vector2i(10, y), A0))
	b.place_merc("soldier", Vector2i(9, 12), {"hp": BIG, "damage": 1})
	var e = b.spawn_enemy(WY, Vector2i(2, 10), {"hp": BIG})
	if not run(b, 10.0, func(): return _casting(e, "plunge")):
		return "10초 안에 급강하 예고를 시작하지 않았다(자리 %s · cast %s)" % [e.pos, e.cast]
	var at: Vector2 = e.cast.get("at", Vector2.INF)
	if at.distance_to(Vector2(10, 10)) > 0.01:
		return "급강하 예고 자리 %s((10,10)과 0.01칸 안이어야 한다)" % [at]
	var t := 0.0
	while t < 2.0 and b.effect(e, "rest") == null:
		b.step(DT)
		t += DT
	if t < 1.4 - 0.001 or t > 1.6 + 0.001 or e.pos.distance_to(Vector2(10, 10)) > 0.05:
		return "예고를 시작한 뒤 %.2f초에 내려앉았다(1.4~1.6) · 자리 %s((10,10))" % [t, e.pos]
	var want := [Vector2(10, 8), Vector2(11, 10), Vector2(10, 12)]
	for i in 3:
		var hp: float = 100.0 - 30.0 * b.armor_mult(b.armor_of(arch[i]))
		if not is_equal_approx(arch[i].hp, hp) or arch[i].pos.distance_to(want[i]) > 0.1:
			return "닿은 스텝: 궁수 %d 체력 %.2f(%.2f) · 자리 %s(%s에서 0.1칸 안)" % [i, arch[i].hp, hp, arch[i].pos, want[i]]
	var hp1: float = e.hp
	var p: Vector2 = e.pos
	var moved := 0.0
	var told := false
	var n := 0
	while n < 60:
		b.step(DT)
		if b.effect(e, "rest") == null:
			break
		n += 1
		moved = maxf(moved, e.pos.distance_to(p))
		told = told or e.cast != null
	if (n + 1) * DT < 1.9 or moved > 0.05 or told or e.hp >= hp1:
		return "내려앉은 %.2f초: 움직임 %.2f칸 · 새 예고 %s · 체력 %s → %s(병사가 깎아야 한다)" % [(n + 1) * DT, moved, told, hp1, e.hp]
	var hp2: float = e.hp
	run(b, 1.0)
	return check(is_equal_approx(e.hp, hp2), "내려앉음이 끝난 뒤 1초에 체력 %s → %s(그대로여야 한다)" % [hp2, e.hp])

# EV865 · S310: 융단 폭격은 아군이 가장 많이 걸리는 직선을 예고하고 0.8초에 지나가며, 줄 위 아군에 불(burn), 줄 위 쏘는 구조물에 불(flame)을 붙인다
func ev865():
	var b = battle()
	var why := _need(b, [WY])
	if why != "":
		return why
	var t1 = b.build("tower", Vector2i(11, 12))
	var t2 = b.build("tower", Vector2i(11, 14))
	if t1 == null or t2 == null:
		return "타워를 (11,12)·(11,14)에 짓지 못했다"
	var on := []
	for x in [10, 12, 14]:
		on.append(b.place_merc("archer", Vector2i(x, 12), A0))
	var off = b.place_merc("archer", Vector2i(8, 15), A0)
	var e = _still(b, WY, Vector2(6, 12))
	e.cd["plunge"] = 99.0
	if not run(b, 1.0, func(): return _casting(e, "carpet")):
		return "1초 안에 융단 폭격 예고를 시작하지 않았다(cast %s)" % [e.cast]
	var to: Vector2 = e.cast.get("to", Vector2.INF)
	if to.distance_to(Vector2(14, 12)) > 0.01:
		return "직선 끝 %s((14,12)와 0.01칸 안이어야 한다)" % [to]
	var t := 0.0
	while t < 2.0 and not (_casting(e, "carpet") and e.cast.get("pass", false)):
		b.step(DT)
		t += DT
	if t < 1.1 - 0.001 or t > 1.3 + 0.001:
		return "예고를 시작한 뒤 %.2f초에 지나가기 시작했다(1.1~1.3)" % t
	var u := 0.0
	while u < 1.5 and _casting(e, "carpet"):
		b.step(DT)
		u += DT
	if u < 0.7 - 0.001 or u > 0.9 + 0.001 or e.pos.distance_to(Vector2(14, 12)) > 0.05:
		return "지나가기 시작한 뒤 %.2f초에 끝났다(0.7~0.9) · 자리 %s((14,12))" % [u, e.pos]
	if not on.all(func(a): return _burns(b, a)) or _burns(b, off):
		return "끝난 스텝 불: 줄 위 궁수 %s(모두 참) · (8,15) 궁수 %s(거짓)" % [on.map(func(a): return _burns(b, a)), _burns(b, off)]
	if not t1.fx.has("flame") or t2.fx.has("flame"):
		return "끝난 스텝 구조물 불: (11,12) 타워 %s(참) · (11,14) 타워 %s(거짓)" % [t1.fx.has("flame"), t2.fx.has("flame")]
	run(b, 4.1)
	return check(on.all(func(a): return absf(a.hp - 80.0) <= 0.5 and not _burns(b, a)), "4.1초 뒤 줄 위 궁수 [체력, 불] %s(80±0.5, 거짓)" % [on.map(func(a): return [a.hp, _burns(b, a)])])

# EV866 · S311: 체력이 0이 된 와이번은 쓰러지지 않고 가장 가까운 빈 칸의 떨어진 와이번이 된다(처치가 아니다). 땅 적이라 근접이 친다
func ev866():
	var b = _fort()
	var why := _need(b, [WY, WF])
	if why != "":
		return why
	b.place_merc("archer", Vector2i(12, 6), {"hp": BIG, "damage": 0})
	var e = b.spawn_enemy(WY, SPOT, {"hp": 10.0, "speed": 0, "sight": 0})
	if not run(b, 1.0, func(): return _casting(e, "plunge") and not e.cast.get("air", false)):
		return "1초 안에 급강하 예고를 시작하지 않았다(cast %s)" % [e.cast]
	b._fx(e, "t_slow", {"slow": 0.3}, 99.0)
	var g: int = b.gold
	var nf: int = b.fallen.size()
	var nw: int = b.wrecks.size()
	b.damage(e, 1000.0)
	var want: float = b.ENEMY_KINDS[WF].hp
	if not (e.alive and e in b.enemies and e.kind == WF and not e.flying and e.boss):
		return "피해 뒤: 살아 있음 %s · 목록 %s · 종류 %s · 비행 %s · boss %s" % [e.alive, e in b.enemies, e.kind, e.flying, e.boss]
	if not (is_equal_approx(e.hp, want) and is_equal_approx(e.max_hp, want) and e.cast == null and e.fx.is_empty() and e.via == null):
		return "피해 뒤: 체력 %s/%s(%s) · 예고 %s · 효과 %s · via %s" % [e.hp, e.max_hp, want, e.cast, e.fx, e.via]
	if e.pos.distance_to(Vector2(12, 8)) > 0.05 and e.pos.distance_to(Vector2(12, 10)) > 0.05:
		return "떨어진 자리 %s((12,8)이나 (12,10)과 0.05칸 안이어야 한다)" % [e.pos]
	if b.gold != g or b.fallen.size() != nf or b.wrecks.size() != nw:
		return "골드 %d → %d · 쓰러진 몸 %d → %d · 잔해 %d → %d(모두 그대로여야 한다)" % [g, b.gold, nf, b.fallen.size(), nw, b.wrecks.size()]
	var s = _merc_at(b, "soldier", e.pos + Vector2(-0.9, 0), {"hp": BIG, "damage": 1})
	if s == null:
		return "떨어진 와이번 옆에 병사를 놓지 못했다(자리 %s)" % [e.pos]
	var hp0: float = e.hp
	return check(run(b, 3.0, func(): return e.hp < hp0), "떨어진 와이번 옆 병사가 3초 안에 체력을 깎지 않았다(와이번 %s · 병사 %s)" % [e.pos, s.pos])

# EV867 · S311: 화염 숨결은 가장 가까운 땅 아군 쪽 부채꼴(반경 3, 60°) 안에 불을 붙이고, 불은 정화(세라피나 W)로 풀린다
func ev867():
	var b = battle()
	var why := _need(b, [WF])
	if why != "":
		return why
	var hit := [_merc_at(b, "archer", Vector2(12, 10), A0), _merc_at(b, "archer", Vector2(12.5, 11), A0)]
	var miss := [_merc_at(b, "archer", Vector2(10, 12.5), A0), _merc_at(b, "archer", Vector2(14, 10), A0)]
	var e = _fallen(b, Vector2(10, 10), ["rush", "tail"], {"speed": 0})
	if not run(b, 1.0, func(): return _casting(e, "breath")):
		return "1초 안에 화염 숨결 예고를 시작하지 않았다(cast %s)" % [e.cast]
	var dir: float = e.cast.get("dir", INF)
	if absf(angle_difference(dir, 0.0)) > deg_to_rad(1.0):
		return "숨결 방향 %.1f°(동쪽 0°여야 한다)" % rad_to_deg(dir)
	var t := 0.0
	while t < 1.2 and not hit.any(func(a): return _burns(b, a)):
		b.step(DT)
		t += DT
	if t < 0.7 - 0.001 or t > 0.9 + 0.001:
		return "예고를 시작한 뒤 %.2f초에 불이 붙었다(0.7~0.9)" % t
	if not hit.all(func(a): return _burns(b, a)) or miss.any(func(a): return _burns(b, a)):
		return "불: 부채꼴 안 %s(모두 참) · 밖 %s(모두 거짓)" % [hit.map(func(a): return _burns(b, a)), miss.map(func(a): return _burns(b, a))]
	run(b, 4.1)
	if hit.any(func(a): return absf(a.hp - 80.0) > 0.5 or _burns(b, a)):
		return "4.1초 뒤 [체력, 불] %s(80±0.5, 거짓)" % [hit.map(func(a): return [a.hp, _burns(b, a)])]
	var c = battle({"heroes": [{"kind": "seraphina", "cell": Vector2i(12, 8), "level": 5}], "waves": [ONE], "base_hp": BIG})
	var h = c.heroes[0]
	h.damage = 0.0
	var a = _merc_at(c, "archer", Vector2(12, 10), A0)
	_start(c)  # 세라피나 W는 전투 단계에만 쓴다. 웨이브 적은 처치하고 구석 과녁으로 단계를 잇는다
	_fallen(c, Vector2(10, 10), ["rush", "tail"], {"speed": 0})
	if not run(c, 2.0, func(): return _burns(c, a)):
		return "세라피나 판: 2초 안에 (12,10) 궁수에 불이 붙지 않았다"
	if _burns(c, h):
		return "세라피나 판: 부채꼴 밖 세라피나에 불이 붙었다"
	if not c.cast(h, "w", a.pos):
		return "세라피나가 W를 쓰지 못했다"
	c.step(DT)
	return check(not _burns(c, a), "W를 쓴 다음 스텝에도 궁수의 불이 남아 있다")

# EV868 · S311: 맹진은 2칸 넘게 떨어진 가장 가까운 땅 아군 쪽으로 6칸 돌진해 지나는 아군을 옆으로 밀고 불을 붙인다. 방패병·막힌 칸 앞에서 멈추면 비틀거린다
func ev868():
	var b = battle()
	var why := _need(b, [WF])
	if why != "":
		return why
	var far = _merc_at(b, "archer", Vector2(9, 10), A0)
	var side = _merc_at(b, "archer", Vector2(6.5, 10.3), A0)
	var e = _fallen(b, Vector2(5, 10), ["breath", "tail"])
	if not run(b, 1.0, func(): return _casting(e, "rush")):
		return "1초 안에 맹진 예고를 시작하지 않았다(cast %s)" % [e.cast]
	var to: Vector2 = e.cast.get("to", Vector2.INF)
	if to.distance_to(Vector2(11, 10)) > 0.01:
		return "멈출 자리 %s((11,10)과 0.01칸 안이어야 한다)" % [to]
	var p0: Vector2 = e.pos
	var t := 0.0
	while t < 1.5 and e.pos.distance_to(p0) < 0.5:
		b.step(DT)
		t += DT
	if t < 0.9 - 0.001 or t > 1.1 + 0.001 or e.pos.distance_to(Vector2(11, 10)) > 0.05 or b.effect_sum(e, "expose") != 0.0:
		return "예고를 시작한 뒤 %.2f초(0.9~1.1)에 자리 %s((11,10)) · expose %s(0)" % [t, e.pos, b.effect_sum(e, "expose")]
	if far.pos.distance_to(Vector2(9, 9)) > 0.1 or side.pos.distance_to(Vector2(6.5, 11.3)) > 0.1 or not (_burns(b, far) and _burns(b, side)):
		return "지난 궁수: (9,10) → %s((9,9)) · (6.5,10.3) → %s((6.5,11.3)) · 불 %s" % [far.pos, side.pos, [_burns(b, far), _burns(b, side)]]
	var c = battle()
	_merc_at(c, "archer", Vector2(9, 10), A0)
	var s = _merc_at(c, "soldier", Vector2(8, 10), {"hp": 100.0, "damage": 0, "sight": 0})
	var f = _fallen(c, Vector2(5, 10), ["breath", "tail"])
	var r := _rushed(c, f)
	if r != "":
		return "병사 판: " + r
	if f.pos.distance_to(Vector2(7, 10)) > 0.05 or not is_equal_approx(c.effect_sum(f, "expose"), 0.5):
		return "병사 판: 멈춘 자리 %s((7,10)) · expose %s(0.5)" % [f.pos, c.effect_sum(f, "expose")]
	if s.pos.distance_to(Vector2(8, 10)) > 0.05 or s.hp != 100.0 or _burns(c, s):
		return "병사 판: 병사 자리 %s · 체력 %s · 불 %s(그대로·100·거짓)" % [s.pos, s.hp, _burns(c, s)]
	var d = battle()
	var wall = d.build("wall", Vector2i(8, 10))
	if wall == null:
		return "방벽을 (8,10)에 짓지 못했다"
	_merc_at(d, "archer", Vector2(9, 10), A0)
	var g = _fallen(d, Vector2(5, 10), ["breath", "tail"])
	var hp0: float = wall.hp
	r = _rushed(d, g)
	if r != "":
		return "방벽 판: " + r
	return check(g.pos.distance_to(Vector2(7.25, 10)) <= 0.05 and is_equal_approx(d.effect_sum(g, "expose"), 0.5) and wall.hp == hp0,
		"방벽 판: 멈춘 자리 %s((7.25,10)) · expose %s(0.5) · 방벽 체력 %s → %s" % [g.pos, d.effect_sum(g, "expose"), hp0, wall.hp])

# EV869 · S311: 꼬리 휘두르기는 노리는 대상 반대쪽 부채꼴 안 땅 아군을 1.5칸 민다. 뒤에 아군이 없으면 쓰지 않는다
func ev869():
	var b = battle()
	var why := _need(b, [WF])
	if why != "":
		return why
	var front = _merc_at(b, "archer", Vector2(11.2, 10), A0)
	var back = _merc_at(b, "archer", Vector2(8.5, 10), A0)
	var e = _fallen(b, Vector2(10, 10), ["breath", "rush"], {"speed": 0})
	if not run(b, 1.0, func(): return _casting(e, "tail")):
		return "1초 안에 꼬리 휘두르기 예고를 시작하지 않았다(cast %s)" % [e.cast]
	var dir: float = e.cast.get("dir", INF)
	if absf(angle_difference(dir, PI)) > deg_to_rad(1.0):
		return "꼬리 방향 %.1f°(서쪽 180°여야 한다)" % rad_to_deg(dir)
	var p: Vector2 = front.pos
	var t := 0.0
	while t < 1.0 and back.pos.distance_to(Vector2(8.5, 10)) < 0.5:
		b.step(DT)
		t += DT
	if t < 0.5 - 0.001 or t > 0.7 + 0.001 or back.pos.distance_to(Vector2(7, 10)) > 0.1 or front.pos.distance_to(p) > 0.05:
		return "예고를 시작한 뒤 %.2f초(0.5~0.7): 뒤 궁수 %s((7,10)) · 앞 궁수 %s(그대로)" % [t, back.pos, front.pos]
	var c = battle()
	_merc_at(c, "archer", Vector2(11.2, 10), A0)
	var f = _fallen(c, Vector2(10, 10), ["breath", "rush"], {"speed": 0})
	var told := false
	for i in int(3.0 / DT):
		c.step(DT)
		told = told or _casting(f, "tail")
	return check(not told, "앞에만 궁수를 둔 판에서 꼬리 휘두르기 예고를 시작했다")

# EV870 · S312: 불붙은 구조물은 불빛 반경이 2.5칸이 되고, 불이 꺼지면 돌아간다
func ev870():
	var b = battle({"nights": NIGHT, "waves": [ONE], "base_hp": BIG})
	var tw = b.build("tower", Vector2i(12, 16))
	var cn = b.build("cannon", Vector2i(5, 16))
	if tw == null or cn == null:
		return "타워 (12,16)이나 대포 (5,16)를 짓지 못했다"
	var why := _dark(b)
	if why != "":
		return why
	var p := Vector2(14.3, 16)
	if not is_equal_approx(b.light_of(tw), 2.0) or b.seen(p):
		return "불 없음: 타워 반경 %s(2) · (14.3,16) 보임 %s(거짓)" % [b.light_of(tw), b.seen(p)]
	b._fx(tw, "flame", {"burn": 0.0, "burnt": 0.0}, 1.0)
	b._fx(cn, "flame", {"burn": 0.0, "burnt": 0.0}, 1.0)
	b.step(DT)
	if not (is_equal_approx(b.light_of(tw), 2.5) and b.seen(p) and is_equal_approx(b.light_of(cn), 2.5)):
		return "불붙음: 타워 반경 %s(2.5) · (14.3,16) 보임 %s(참) · 대포 반경 %s(2.5)" % [b.light_of(tw), b.seen(p), b.light_of(cn)]
	run(b, 2.0, func(): return not tw.fx.has("flame"))
	b.step(DT)
	return check(is_equal_approx(b.light_of(tw), 2.0) and not b.seen(p), "불이 꺼진 뒤: 타워 반경 %s(2) · (14.3,16) 보임 %s(거짓)" % [b.light_of(tw), b.seen(p)])

# EV871 · I255: 둥지 하피·새끼 하피는 비행 그림에 색을 곱하고, 둥지는 색 원이다. 짓는 원 예고는 하피가 어둠에 숨어도 그린다
func ev871():
	var b = battle()
	var why := _need(b, [NH, CH, "nest"])
	if why != "":
		return why
	var v = _rec(b)
	var got := []
	for k in ["flying", NH, CH]:
		var e = _still(b, k, Vector2(3 + got.size() * 3, 5))
		var one = _cut(v, e)
		if one == null:
			v.free()
			return "%s 몸통이 그림 한 장이 아니다(%d장)" % [k, v.cuts.size()]
		got.append(one)
	v.free()
	var view := load("res://src/ui/battle_view.gd")
	var drawn: bool = view.ART.has("nest")
	var colored: bool = view.ENEMY_COLORS.has("nest")
	if got.any(func(x): return x[1] != got[0][1]):
		return "원본 사각형이 비행과 다르다: %s" % [got.map(func(x): return x[1])]
	if got[0][2] == got[1][2] or got[0][2] == got[2][2] or got[1][2] == got[2][2]:
		return "색이 같다: %s" % [got.map(func(x): return x[2])]
	if drawn or not colored:
		return "둥지: 그림 칸 표에 있음 %s(거짓) · 적 색 표에 있음 %s(참)" % [drawn, colored]
	var c = _fort({"nights": NIGHT, "waves": [ONE]})
	why = _dark(c)
	if why != "":
		return why
	var h = _builder(c)
	if h is String:
		return h
	var w = _rec(c)
	w._foes = w.foes()
	var hidden: bool = not h in w._foes
	var tells: bool = h in w.tellers()
	w.clock = 0.0
	w.rings = []
	w._foe_tells()
	var o: Vector2 = w._center(Vector2(SPOT))
	var rings: Array = w.rings.duplicate()
	w.free()
	return check(hidden and tells and rings.any(func(r): return Vector2(r[0]).distance_to(o) <= 1.5 and r[1] == 8),
		"숨음 %s · 예고를 그리는 적 %s · 고리 %s((12,9) 가운데 %s에 반지름 8)" % [hidden, tells, rings, o])

# EV872 · I256: 와이번·떨어진 와이번은 비행 그림을 2배로 키우고 색을 곱한다. 불붙은 아군에 작은 불꽃을 그리고, 급강하·융단 폭격 예고는 와이번이 숨어도 그린다
func ev872():
	var b = battle()
	var why := _need(b, [WY, WF, NH, CH])
	if why != "":
		return why
	var v = _rec(b)
	var got := []
	for k in ["flying", NH, CH, WY, WF]:
		var e = _still(b, k, Vector2(3 + got.size() * 4, 5))
		var one = _cut(v, e)
		if one == null:
			v.free()
			return "%s 몸통이 그림 한 장이 아니다(%d장)" % [k, v.cuts.size()]
		got.append(one)
	v.free()
	if got.any(func(x): return x[1] != got[0][1]):
		return "원본 사각형이 비행과 다르다: %s" % [got.map(func(x): return x[1])]
	var size0: Vector2 = got[0][0].size
	for i in [3, 4]:
		if got[i][0].size.distance_to(size0 * 2.0) > 0.5:
			return "%s 그림 크기 %s(비행 %s의 2배여야 한다)" % [[WY, WF][i - 3], got[i][0].size, size0]
	var tints: Array = got.map(func(x): return x[2])
	for i in tints.size():
		for j in range(i + 1, tints.size()):
			if tints[i] == tints[j]:
				return "색이 같다: %s" % [tints]
	var c = battle()
	var a1 = c.place_merc("archer", Vector2i(10, 10), A0)
	var a2 = c.place_merc("archer", Vector2i(14, 10), A0)
	c._fx(a1, "burn", {"burn": 5.0}, 4.0)
	var w = _rec(c)
	var m1: Array = w.status_marks(a1, true)
	var m2: Array = w.status_marks(a2, true)
	w.free()
	if not m1.any(func(m): return m.k == "flame_s") or m2.any(func(m): return m.k == "flame_s"):
		return "불 표식: 불붙은 궁수 %s(있어야 한다) · 불 없는 궁수 %s(없어야 한다)" % [m1.map(func(m): return m.k), m2.map(func(m): return m.k)]
	for id in ["plunge", "carpet"]:
		var d = battle({"nights": NIGHT, "waves": [ONE], "base_hp": BIG})
		d.place_merc("archer", Vector2i(10, 10), A0)
		d.place_merc("archer", Vector2i(8, 10), A0)
		why = _dark(d)
		if why != "":
			return why
		var y = _still(d, WY, Vector2(14.5, 10))
		y.cd["carpet" if id == "plunge" else "plunge"] = 99.0
		if not run(d, 1.0, func(): return _casting(y, id)):
			return "1초 안에 %s 예고를 시작하지 않았다(cast %s)" % [id, y.cast]
		var x = _rec(d)
		x._foes = x.foes()
		var hidden: bool = not y in x._foes
		var tells: bool = y in x.tellers()
		x.lines = []
		x._foe_tells()
		var n: int = x.lines.size()
		x.free()
		if not hidden or not tells or (id == "carpet" and n < 4):
			return "%s 예고: 숨음 %s · 예고를 그리는 적 %s · 숨어도 그린 선 %d(융단 폭격은 넷 이상)" % [id, hidden, tells, n]
	return ""
