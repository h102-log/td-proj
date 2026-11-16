extends "res://tests/eval/gd/lib.gd"
# 무리 대열(S374·I306·I307). lib.gd 머리의 계약에 더하는 API:
#   Battle 상수 FORM — {gap: 자리 간격(칸), front: 근접으로 앞줄에 서는 사거리 상한(칸), pace: 같이 걷기 켬}(S374)
#   유닛: path·after(걷는 길, 둘 다 비면 서 있다) · on_wall(성벽 위) · speed · radius
#   stage 키 castle·village·merc_cap(castle.gd·production.gd 머리) · Battle.castle(칸 → 성곽 칸) · set_gate(문, 열기)
#   영웅: stage 키 heroes [{kind, cell}] · Battle.heroes · Battle.dash(영웅들, 칸 좌표)(전투 단계에만)
# 모든 측정은 판 상태(pos·path·after·on_wall·open)로 잰다. 화면을 그리지 않고 저장 파일을 쓰지 않는다.
# 도착한 칸은 걷는 길이 빈 스텝에 잰다(선 뒤에는 인식 범위 안 적을 쫓을 수 있다, I36). 적은 인식 범위(가장 긴 6칸) 밖에 둔다

const STILL := {"speed": 0.0, "damage": 0.0, "sight": 0.0, "hp": 1000000.0}  # 움직이지도 치지도 않는 적
const SIX := [Vector2i(4, 9), Vector2i(5, 9), Vector2i(6, 9), Vector2i(4, 10), Vector2i(5, 10), Vector2i(6, 10)]
const ROWS6 := [Vector2i(18, 9), Vector2i(18, 10), Vector2i(18, 11), Vector2i(17, 9), Vector2i(17, 10), Vector2i(17, 11)]
const GATE := Vector2i(19, 24)  # 성곽 판의 문루(x 19~21, y 20~24)

func _form(b):
	return b.get_script().get_script_constant_map().get("FORM")

func _idle(u) -> bool:
	return u.path.is_empty() and u.after.is_empty()

# 모두 걷는 길이 빌 때까지 돌린다
func _settle(b, us: Array, secs: float) -> bool:
	return run(b, secs, func(): return us.all(func(u): return _idle(u)))

# 서로 다른 칸의 중심(tol 안)에 서 있으면 그 칸들(us 차례), 아니면 빈 배열
func _cells(us: Array, tol := 0.05) -> Array:
	var out := []
	for u in us:
		var c := cell_of(u)
		if u.pos.distance_to(Vector2(c)) > tol or c in out:
			return []
		out.append(c)
	return out

func _where(us: Array) -> String:
	return str(us.map(func(u): return u.pos))

func _same_set(a: Array, b: Array) -> bool:
	return a.size() == b.size() and a.all(func(x): return x in b)

# EV794의 성곽 판: 40×40, 24행 성벽(두께 5, 20~24행), x 19~21 폭 3 문루(열림), 마을은 0~19행
func _castle():
	var walls := []
	for x in 40:
		if x < 19 or x > 21:
			walls.append(Vector2i(x, 24))
	var b = battle({"size": Vector2i(40, 40), "base": Vector2i(20, 3), "spawns": [Vector2i(20, 39)], "merc_cap": 40, "village": Rect2i(0, 0, 40, 20),
		"castle": {"walls": walls, "gates": [GATE], "wall_hp": 300, "gate_hp": 150, "wall_size": Vector2i(1, 5), "gate_size": Vector2i(3, 5)}})
	b.set_gate(b.castle[GATE], true)
	return b

func _in_gate(c: Vector2i) -> bool:
	return c.x >= 19 and c.x <= 21 and c.y >= 20 and c.y <= 24

# EV1138 · S374 ①: 둘 이상 고른 이동·공격 이동은 찍은 칸을 앞줄 가운데로 한 칸에 한 명씩 가로 줄을 짓는다. 손잡이는 상수 FORM
func ev1138():
	var form = _form(battle())
	if not form is Dictionary or form.get("gap") != 1 or form.get("front") != 2.0 or form.get("pace") != true:
		return "battle.gd의 FORM %s(기대 gap 1·front 2.0·pace 참)" % [form]
	for attack in [false, true]:
		var b = battle()
		var us := SIX.map(func(c): return b.place_merc("soldier", c))
		if us.has(null):
			return "병사 여섯을 두지 못했다"
		b.order_move(us, Vector2i(18, 10), attack)
		var mode := "공격 이동" if attack else "순수 이동"
		if not _settle(b, us, 15.0):
			return "%s: 15초 뒤에도 걷는 병사가 있다 %s" % [mode, _where(us)]
		var got := _cells(us)
		if not _same_set(got, ROWS6):
			return "%s: 선 자리 %s(기대 서로 다른 칸 중심 %s)" % [mode, _where(us), ROWS6]
	return ""

# 방패병 셋·불마법사 셋(또는 kinds)을 at에 두고 (18,10)으로 순수 이동시킨 뒤 선 칸. 적 칸 foe가 null이 아니면 움직이지도 치지도 않는 적을 둔다
func _send(kinds: Array, at: Array, foe) -> Array:
	var b = battle()
	if foe != null:
		b.spawn_enemy("basic", foe, STILL)
	var us := []
	for i in kinds.size():
		us.append(b.place_merc(kinds[i], at[i]))
	if us.has(null):
		return []
	b.order_move(us, Vector2i(18, 10))
	if not _settle(b, us, 15.0):
		return []
	return _cells(us)

# EV1139 · S374 ②: 근접이 앞줄, 원거리가 그 뒤 줄. 앞은 찍은 칸에서 가장 가까운 적 쪽, 적이 없으면 진행 방향. 창병(2.0)은 근접
func ev1139():
	var kinds := ["shieldman", "shieldman", "shieldman", "fire_mage", "fire_mage", "fire_mage"]
	var cases := [[Vector2i(27, 10), "x", 18, 17], [Vector2i(18, 18), "y", 10, 9], [null, "x", 18, 17]]
	for k in cases:
		var got := _send(kinds, SIX, k[0])
		if got.is_empty():
			return "적 %s: 15초 안에 여섯이 서로 다른 칸 중심에 서지 않았다" % [k[0]]
		var axis: int = 0 if k[1] == "x" else 1
		var front := got.slice(0, 3).map(func(c): return c[axis])
		var back := got.slice(3).map(func(c): return c[axis])
		if front.any(func(v): return v != k[2]) or back.any(func(v): return v != k[3]):
			return "적 %s: 방패병 칸 %s(%s가 %d) · 불마법사 칸 %s(%s가 %d)" % [k[0], got.slice(0, 3), k[1], k[2], got.slice(3), k[1], k[3]]
	var pair := _send(["spearman", "archer"], [Vector2i(4, 10), Vector2i(4, 11)], null)
	return check(pair == [Vector2i(18, 10), Vector2i(17, 10)], "창병·궁수가 선 칸 %s(기대 창병 (18,10)·궁수 (17,10))" % [pair])

# EV1140 · S374 ④: 같이 걷기. 무리는 가장 느린 유닛의 속도로 걷고, 새 명령을 받은 유닛은 풀린다
func ev1140():
	var b = battle()
	var cav = b.place_merc("cavalry", Vector2i(4, 10))
	var sh = b.place_merc("shieldman", Vector2i(4, 11))
	if cav == null or sh == null:
		return "기병·방패병을 두지 못했다"
	var c0: Vector2 = cav.pos
	b.order_move([cav, sh], Vector2i(22, 10))
	run(b, 3.0)
	var went: float = cav.pos.distance_to(c0)
	if went > sh.speed * 3.0 + 0.3:
		return "함께 보낸 기병이 3초에 %.2f칸 갔다(기대 방패병 속도 %.1f × 3 + 0.3 이하)" % [went, sh.speed]
	var c1: Vector2 = cav.pos
	var s1: Vector2 = sh.pos
	b.order_move([cav], Vector2i(22, 10))
	run(b, 1.0)
	var free: float = cav.pos.distance_to(c1)
	var kept: float = sh.pos.distance_to(s1)
	if free < cav.speed - 0.3 or absf(kept - sh.speed) > 0.3:
		return "기병에게만 새 이동 뒤 1초: 기병 %.2f칸(기대 %.1f − 0.3 이상) · 방패병 %.2f칸(기대 %.1f ± 0.3)" % [free, cav.speed, kept, sh.speed]
	var a = battle()
	var solo = a.place_merc("cavalry", Vector2i(4, 10))
	a.order_move([solo], Vector2i(22, 10))
	run(a, 3.0)
	var alone: float = solo.pos.distance_to(Vector2(4, 10))
	return check(alone >= solo.speed * 3.0 - 0.5, "혼자 보낸 기병이 3초에 %.2f칸 갔다(기대 %.1f × 3 − 0.5 이상)" % [alone, solo.speed])

# EV1141 · S374 ④: 대시한 영웅은 묶음에서 빠지고, 남은 유닛의 상한은 그대로다
func ev1141():
	var b = battle({"heroes": [{"kind": "aias", "cell": Vector2i(3, 9)}, {"kind": "sylvia", "cell": Vector2i(3, 10)}], "base_hp": BIG,
		"waves": [[{"kind": "basic", "count": 0}]]})
	var aias = b.heroes[0]
	var syl = b.heroes[1]
	var sh = b.place_merc("shieldman", Vector2i(3, 11))
	if sh == null or aias.kind != "aias" or syl.kind != "sylvia":
		return "영웅 둘·방패병을 두지 못했다"
	b.start_battle()
	b.spawn_enemy("basic", Vector2i(28, 2), STILL)  # 전투 단계가 이어지게 멀리 세워 둔다
	b.order_move([aias, syl, sh], Vector2i(21, 10))
	run(b, 1.0)
	b.dash([aias], aias.pos + Vector2(0, -3))
	if b.state != "battle" or not _idle(aias) or _idle(syl) or _idle(sh):
		return "대시 뒤 판 %s · 걷는 길이 빈 것: 아이아스 %s(참) · 실비아 %s(거짓) · 방패병 %s(거짓)" % [b.state, _idle(aias), _idle(syl), _idle(sh)]
	var s0: Vector2 = syl.pos
	run(b, 2.0)
	var went: float = syl.pos.distance_to(s0)
	if went > sh.speed * 2.0 + 0.3:
		return "대시 뒤 2초에 실비아가 %.2f칸 갔다(기대 방패병 속도 %.1f × 2 + 0.3 이하)" % [went, sh.speed]
	var a0: Vector2 = aias.pos
	b.order_move([aias], Vector2i(21, 6))
	run(b, 1.0)
	var own: float = aias.pos.distance_to(a0)
	return check(own >= aias.speed - 0.3, "혼자 이동한 아이아스가 1초에 %.2f칸 갔다(기대 %.1f − 0.3 이상)" % [own, aias.speed])

# EV1143 · S374 ③: 열린 문루 칸과 무리 밖 아군이 선 칸에는 서지 않는다. 열린 문루를 찍으면 문루(성벽 위)에 선다
func ev1143():
	var b = _castle()
	var guard = b.place_merc("soldier", Vector2i(19, 26))
	var us := []
	for i in 9:
		us.append(b.place_merc(["soldier", "archer", "engineer"][i % 3], Vector2i(14 + i % 3, 14 + i / 3)))
	if guard == null or us.has(null):
		return "용병을 두지 못했다"
	var g0: Vector2 = guard.pos
	var track := {"moved": 0.0}
	b.order_move(us, Vector2i(20, 26))
	var done := run(b, 30.0, func():
		track.moved = maxf(track.moved, guard.pos.distance_to(g0))
		return us.all(func(u): return _idle(u)))
	if not done:
		return "30초 뒤에도 걷는 용병이 있다 %s" % _where(us)
	var got := _cells(us)
	if got.is_empty() or Vector2i(19, 26) in got:
		return "아홉이 선 자리 %s(기대 서로 다른 칸 중심, (19,26) 아님)" % _where(us)
	var on_gate: Array = b.units.filter(func(u): return _in_gate(cell_of(u)))
	if not on_gate.is_empty() or track.moved > 0.05:
		return "문루에 선 유닛 %s(기대 없음) · 무리 밖 병사가 벗어난 거리 %.3f(0.05 이하)" % [_where(on_gate), track.moved]
	var gate = b.castle[GATE]
	b.set_gate(gate, false)
	if gate.open:
		return "성문 닫기가 받아들여지지 않았다"
	var c = _castle()
	var two := [c.place_merc("archer", Vector2i(15, 15)), c.place_merc("archer", Vector2i(16, 15))]
	if two.has(null):
		return "궁수 둘을 두지 못했다"
	c.order_move(two, Vector2i(20, 22))
	if not _settle(c, two, 30.0):
		return "문루 칸으로 보낸 둘이 30초 뒤에도 걷는다 %s" % _where(two)
	var top := _cells(two)
	return check(top.size() == 2 and two.all(func(u): return u.on_wall) and top.all(func(x): return _in_gate(x)),
		"문루 칸으로 보낸 둘 %s · 성벽 위 %s(기대 둘 다 성벽 위의 서로 다른 문루 칸 중심)" % [_where(two), two.map(func(u): return u.on_wall)])

# EV1144 · S374 ②: 성벽 위에서는 들판 쪽(맵 아래쪽) 줄이 앞이고, 성벽 위에서 칠 수 있는 유닛(사거리 2 이상)이 앞줄에 선다. 한 점에 포개지 않는다
func ev1144():
	var b = _castle()
	var us := []
	for i in 5:
		us.append(b.place_merc("archer" if i < 3 else "soldier", Vector2i(8 + i, 15)))
	if us.has(null):
		return "용병 다섯을 두지 못했다"
	b.order_move(us, Vector2i(10, 22))
	if not run(b, 40.0, func(): return us.all(func(u): return u.on_wall and _idle(u))):
		return "40초 뒤 성벽 위 %s · 자리 %s(기대 다섯 모두 성벽 위에 섬)" % [us.map(func(u): return u.on_wall), _where(us)]
	var got := _cells(us)
	if got.is_empty():
		return "다섯이 선 자리 %s(기대 서로 다른 칸 중심)" % _where(us)
	for i in us.size():
		for j in range(i + 1, us.size()):
			if us[i].pos.distance_to(us[j].pos) < 0.95:
				return "%d번째와 %d번째가 0.95칸 안에 있다 %s" % [i, j, _where(us)]
	var ys := got.map(func(c): return c.y)
	return check(ys == [24, 24, 24, 23, 23] and got.all(func(c): return b.walls.has(c)), "선 칸 %s(기대 궁수 셋 y 24, 병사 둘 y 23의 성곽 칸)" % [got])

# EV1145 · I306 ①: 자리와 짝은 고른 순서가 아니라 판의 유닛 차례로 정한다.
# 방패병 둘은 한 칸에 겹쳐 둔다: 짝짓기 키(축·옆)가 같아 마지막 동률 가르기(유닛 차례)까지 간다
func ev1145():
	var kinds := ["shieldman", "shieldman", "fire_mage", "fire_mage", "archer"]
	var spots := [Vector2i(4, 8), Vector2i(4, 8), Vector2i(4, 12), Vector2i(6, 9), Vector2i(3, 10)]
	var got := []
	for flip in [false, true]:
		var b = battle()
		var us := []
		for i in kinds.size():
			us.append(b.place_merc(kinds[i], spots[i]))
		if us.has(null):
			return "다섯을 두지 못했다"
		var send := us.duplicate()
		if flip:
			send.reverse()
		b.order_move(send, Vector2i(18, 10))
		if not _settle(b, us, 15.0):
			return "배열 %s: 15초 뒤에도 걷는다 %s" % ["뒤집음" if flip else "그대로", _where(us)]
		var cells := _cells(us)
		if cells.is_empty():
			return "배열 %s: 선 자리 %s(기대 서로 다른 칸 중심)" % ["뒤집음" if flip else "그대로", _where(us)]
		got.append(cells)
	if got[0] != got[1]:
		return "넘긴 배열의 차례에 따라 자리가 다르다: %s / %s" % [got[0], got[1]]
	var c = battle()
	var one = c.place_merc("archer", Vector2i(4, 10))
	c.order_move([one], Vector2i(18, 10))
	_settle(c, [one], 15.0)
	return check(near(one.pos, Vector2i(18, 10)), "혼자 보낸 궁수 %s(기대 (18,10) 0.5칸 안)" % [one.pos])

# 빈 판에 병사 A를 a에(hold면 홀드), B·C를 from에 두고 B·C(solo면 B만)를 (16,10)으로 보내 secs초 돌린다.
# [B, C, A가 처음 자리에서 벗어난 가장 먼 거리, B와 A가 가장 가까웠던 거리, 다 섰나]
func _cross(a: Vector2, hold: bool, solo: bool, from: Array, slow := 0.0) -> Array:
	var b = battle()
	var pa = b.place_merc("soldier", Vector2i(a.round()))
	var pb = b.place_merc("soldier", from[0], {"speed": slow} if slow > 0.0 else {})
	var pc = b.place_merc("soldier", from[1])
	pa.pos = a
	if hold:
		b.set_hold([pa], true)
	var track := {"moved": 0.0, "close": INF}
	var go: Array = [pb] if solo else [pb, pc]
	b.order_move(go, Vector2i(16, 10))
	var done := run(b, 10.0, func():
		track.moved = maxf(track.moved, pa.pos.distance_to(a))
		track.close = minf(track.close, pb.pos.distance_to(pa.pos))
		return go.all(func(u): return _idle(u)) and not hold)
	return [pb, pc, track.moved, track.close, done]

# EV1146 · I307: 자리로 걷는 유닛은 선 아군·마주 걷는 아군을 밀지 않고 지나가고, 홀드로 선 용병은 지나가지 못한다.
# 자리 없는 이동은 지금처럼 민다. 홀드로 선 용병에 닿으면 자리 칸에 닿은 것이다
func ev1146():
	var r := _cross(Vector2(10, 10), false, false, [Vector2i(4, 10), Vector2i(4, 11)])
	if not r[4] or _cells([r[0], r[1]]).is_empty() or r[2] > 0.05 or r[3] >= 0.3:
		return "① 다 섬 %s · B·C 자리 %s · A가 벗어난 거리 %.3f(0.05 이하) · B와 A의 가장 가까운 거리 %.3f(0.3 아래여야)" % [r[4], _where([r[0], r[1]]), r[2], r[3]]
	var b = battle()
	b.spawn_enemy("basic", Vector2i(27, 10), STILL)
	var sh = b.place_merc("shieldman", Vector2i(5, 10))
	var ar = b.place_merc("archer", Vector2i(15, 10))
	b.order_move([sh, ar], Vector2i(10, 10))
	if not _settle(b, [sh, ar], 8.0) or sh.pos.distance_to(Vector2(10, 10)) > 0.05 or ar.pos.distance_to(Vector2(9, 10)) > 0.05:
		return "② 8초 뒤 방패병 %s(기대 (10,10)) · 궁수 %s(기대 (9,10)) · 걷는 길 %s·%s" % [sh.pos, ar.pos, sh.path, ar.path]
	r = _cross(Vector2(10, 10), true, false, [Vector2i(4, 10), Vector2i(4, 11)])
	var room: float = r[0].radius * 2.0 - 0.13
	if r[2] > 0.05 or r[3] < room:
		return "③ 홀드: A가 벗어난 거리 %.3f(0.05 이하) · B와 A의 가장 가까운 거리 %.3f(%.2f 이상)" % [r[2], r[3], room]
	r = _cross(Vector2(10, 10), false, true, [Vector2i(4, 10), Vector2i(4, 11)])
	if r[2] <= 0.05:
		return "④ 혼자 보낸 B가 A를 밀지 않았다(벗어난 거리 %.3f, 0.05 넘어야)" % r[2]
	r = _cross(Vector2(16.55, 10), true, false, [Vector2i(12, 10), Vector2i(12, 11)], 0.6)
	var stood: bool = _idle(r[0]) and _idle(r[1])
	return check(stood and r[2] <= 0.05, "⑤ 홀드로 선 A 옆 자리: B·C 걷는 길이 빔 %s(참) · B %s · A가 벗어난 거리 %.3f(0.05 이하)" % [stood, r[0].pos, r[2]])
