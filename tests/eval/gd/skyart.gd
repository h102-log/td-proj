extends "res://tests/eval/gd/raidart.gd"
# 4라운드 와이번 그림(S172·I189 2026-11-10 변경). raidart.gd 머리의 계약에 더하는 API:
#   heroes.json 칸 wyvern {c, anchor, x, idle, walk, attack, plunge, carpet} · wyvern_fallen {c, anchor, x, idle, walk, attack, breath, rush, tail, fall}
#   BattleView: LOOKS · GROW · 적 cast — 급강하 {id plunge, left, at} · 내리꽂기 {id plunge, left, air 참, from, at} · 융단 폭격 {id carpet, left, dir, to}
#     · 지나가기 {id carpet, left, pass 참, dir, from, to} · 숨결 {id breath, left, dir} · 맹진 {id rush, left, dir, to} · 꼬리 {id tail, left, dir(뒤쪽)}
#   effect(와이번, "rest") — 내려앉음(효과 출처 «plunge» {rest, down}) · Battle._fx(대상, 출처, 효과, 초)

const WY := {"idle": 1, "walk": 2, "plunge": 2, "carpet": 2}  # 와이번 칸의 c×c 자세 → 열 수(S172 2026-11-10 변경). 공격은 2배 칸
const WF := {"idle": 1, "walk": 2, "breath": 2, "rush": 2, "tail": 2}  # 떨어진 와이번. 공격·누운 자세는 2배 칸
const SIX := ["aias", "sylvia", "seraphina", "vesper", "ignis", "chronos"]
const NO_WY := "heroes.json에 %s 칸(%s·attack)이 없다"

# kind 칸에 poses 자세와 공격(떨어진 와이번은 누운 자세도)이 다 있으면 그 칸, 아니면 null
func _wy_art(kind: String, poses: Dictionary):
	if not View.ART.has(kind):
		return null
	var a: Dictionary = View.ART[kind]
	for n in poses.keys() + ["attack"] + (["fall"] if kind == "wyvern_fallen" else []):
		if not a.has(n):
			return null
	return a

# 성곽 없는 판의 (10,10)에 움직이지도 치지도 않는 kind(체력 큼)를 두고 한 번 그린 [판, 기록 화면, 적]
func _still_boss(kind: String) -> Array:
	var b = battle({"base_hp": BIG})
	var v = _rec(b)
	var e = b.spawn_enemy(kind, Vector2i(10, 10), STILL.merged({"hp": BIG}))
	_one(v, e)
	return [b, v, e]

# 칸 a의 그림 사각형 [이름, Rect2i]: poses는 c×4c·2c×4c, 공격 2c×8c, 누운 자세 2c×2c
func _wy_rects(kind: String, a: Dictionary, poses: Dictionary) -> Array:
	var c: int = int(a.c)
	var x: int = int(a.get("x", 0))
	var out := []
	for n in poses:
		out.append(["%s %s" % [kind, n], Rect2i(x, int(a.get(n, 0)), poses[n] * c, 4 * c)])
	out.append(["%s attack" % kind, Rect2i(x, int(a.get("attack", 0)), 2 * c, 8 * c)])
	if a.has("fall"):
		out.append(["%s fall" % kind, Rect2i(x, int(a.fall), 2 * c, 2 * c)])
	return out

# EV873 · S172 2026-11-10 변경: 와이번·떨어진 와이번 칸(x 있음, one 없음)과 자세 열의 4행 모든 칸, 누운 자세. 빌린 그림·큰 몸 표에서 빠짐
func ev873():
	var art := _art()
	var img: Image = load("res://art/units/heroes.png").get_image()
	var whole := Rect2i(Vector2i.ZERO, img.get_size())
	var bad := []
	for kind in ["wyvern", "wyvern_fallen"]:
		if not art.has(kind):
			bad.append("heroes.json에 %s 칸이 없다" % kind)
			continue
		var a: Dictionary = art[kind]
		var poses: Dictionary = WY if kind == "wyvern" else WF
		if not a.has("x") or a.has("one") or not a.has("attack") or (kind == "wyvern_fallen" and not a.has("fall")):
			bad.append("%s x %s · one %s · attack %s · fall %s" % [kind, a.get("x"), a.get("one"), a.get("attack"), a.get("fall")])
			continue
		var c: int = int(a.c)
		var x: int = int(a.x)
		var cells := []
		for n in poses:
			if not a.has(n):
				bad.append("%s %s 자세가 없다" % [kind, n])
				continue
			for r in 4:
				for k in poses[n]:
					cells.append(["%s %s %d열 %d행" % [kind, n, k, r], Rect2i(x + k * c, int(a[n]) + r * c, c, c)])
		for r in 4:
			cells.append(["%s attack %d행" % [kind, r], Rect2i(x, int(a.attack) + 2 * r * c, 2 * c, 2 * c)])
		if a.has("fall"):
			cells.append(["%s fall" % kind, Rect2i(x, int(a.fall), 2 * c, 2 * c)])
		for d in cells:
			if not whole.encloses(d[1]):
				bad.append("%s %s가 그림 밖" % d)
			elif _opaque(img, d[1]) == 0:
				bad.append("%s 빈 칸" % d[0])
	for k in ["wyvern", "wyvern_fallen"]:
		if View.LOOKS.has(k) or View.GROW.has(k):
			bad.append("%s가 LOOKS %s · GROW %s에 남았다" % [k, View.LOOKS.has(k), View.GROW.has(k)])
	return check(bad.is_empty(), "%s" % [bad])

# EV874 · S172 2026-11-10 변경 ①: 와이번 정지, 급강하 예고(끝 0.4초 들어 올림)·내리꽂기·내려앉음, 융단 폭격 예고·지나가기
func ev874():
	var a = _wy_art("wyvern", WY)
	if a == null:
		return NO_WY % ["wyvern", WY.keys()]
	var c: float = a.c
	var s := _still_boss("wyvern")
	var b = s[0]
	var v = s[1]
	var e = s[2]
	var bad := []
	_expect(bad, "정지", _one(v, e), Rect2(a.x, a.idle, c, c))
	e.cast = {"id": "plunge", "left": 1.0, "at": Vector2(13, 10)}
	var early = _one(v, e)
	_expect(bad, "급강하 예고 left 1.0", early, Rect2(a.x, a.idle + c, c, c))
	e.cast = {"id": "plunge", "left": 0.3, "at": Vector2(13, 10)}
	var late = _one(v, e)
	_expect(bad, "급강하 예고 left 0.3", late, Rect2(a.x, a.plunge + c, c, c))
	if early != null and late != null and absf(late[0].position.y - (early[0].position.y - 2.0)) > 0.01:
		bad.append("급강하 예고 들어 올림: y %s → %s" % [early[0].position.y, late[0].position.y])
	e.cast = {"id": "plunge", "left": 0.3, "air": true, "from": Vector2(7, 10), "at": Vector2(13, 10)}
	var dive = _one(v, e)
	_expect(bad, "내리꽂는 동안", dive, Rect2(a.x + c, a.plunge + c, c, c))
	e.cast = null
	b._fx(e, "plunge", {"rest": true, "down": true}, 2.0)
	var rest = _one(v, e)
	_expect(bad, "내려앉은 동안", rest, Rect2(a.x + c, a.plunge + c, c, c))
	for d in [["내리꽂는 동안", dive], ["내려앉은 동안", rest]]:
		if early != null and d[1] != null and absf(d[1][0].position.y - early[0].position.y) > 0.01:
			bad.append("%s 높이: y %s(left 1.0 때 %s)" % [d[0], d[1][0].position.y, early[0].position.y])
	e.fx.clear()
	var north := -PI / 2.0
	e.cast = {"id": "carpet", "left": 0.3, "dir": north, "to": Vector2(10, 2)}
	_expect(bad, "융단 폭격 예고 left 0.3", _one(v, e), Rect2(a.x, a.carpet + 2 * c, c, c))
	e.cast = {"id": "carpet", "left": 0.7, "pass": true, "dir": north, "from": Vector2(10, 10), "to": Vector2(10, 2)}
	var sweep = _one(v, e)
	_expect(bad, "지나가는 동안", sweep, Rect2(a.x + c, a.carpet + 2 * c, c, c))
	if early != null and sweep != null and absf(sweep[0].position.y - early[0].position.y) > 0.01:
		bad.append("지나가는 동안 높이: y %s(left 1.0 때 %s)" % [sweep[0].position.y, early[0].position.y])
	v.free()
	return check(bad.is_empty(), "%s" % [bad])

# EV875 · S172 2026-11-10 변경 ②: 떨어진 와이번 숨결·맹진·꼬리 휘두르기의 준비·정점 자세와 보는 쪽(꼬리는 부채꼴 반대쪽), 누운 자세
func ev875():
	var a = _wy_art("wyvern_fallen", WF)
	if a == null:
		return NO_WY % ["wyvern_fallen", WF.keys() + ["fall"]]
	var c: float = a.c
	var s := _still_boss("wyvern_fallen")
	var b = s[0]
	var v = s[1]
	var e = s[2]
	var bad := []
	e.cast = {"id": "breath", "left": 0.3, "dir": 0.0}
	_expect(bad, "숨결 예고", _one(v, e), Rect2(a.x, a.breath + c, c, c))
	e.cast = null
	b.traces.append(_chief_trace(e, "breath", Vector2(10, 10), 0.05, {"dir": 0.0, "range": 3.0, "arc": 60.0}))
	_expect(bad, "숨결 흔적 0.05초", _one(v, e), Rect2(a.x + c, a.breath + c, c, c))
	b.traces.clear()
	e.cast = {"id": "rush", "left": 0.3, "dir": -PI / 2.0, "to": Vector2(10, 4)}
	_expect(bad, "맹진 예고", _one(v, e), Rect2(a.x, a.rush + 2 * c, c, c))
	e.cast = null
	b.traces.append(_chief_trace(e, "rush", Vector2(10, 10), 0.05, {"from": Vector2(10, 13), "width": 1.0}))
	_expect(bad, "맹진 흔적 0.05초", _one(v, e), Rect2(a.x + c, a.rush + 2 * c, c, c))
	b.traces.clear()
	e.cast = {"id": "tail", "left": 0.3, "dir": PI}
	_expect(bad, "꼬리 예고(뒤쪽 서)", _one(v, e), Rect2(a.x, a.tail + c, c, c))
	e.cast = null
	b.traces.append(_chief_trace(e, "tail", Vector2(10, 10), 0.05, {"dir": PI, "range": 2.0, "arc": 120.0}))
	_expect(bad, "꼬리 흔적 0.05초(뒤쪽 서)", _one(v, e), Rect2(a.x + c, a.tail + c, c, c))
	b.traces.clear()
	v.cuts = []
	v._corpse([e, 1.0])
	var want := Rect2(a.x, a.fall, 2 * c, 2 * c)
	if v.cuts.size() != 1 or not v.cuts[0][1].is_equal_approx(want):
		bad.append("쓰러진 몸 1.0초: %s(기대 %s)" % [v.cuts, want])
	v.free()
	return check(bad.is_empty(), "%s" % [bad])

# EV876 · I189 2026-11-10 변경: 와이번 두 벌 칸은 영웅 구역 오른쪽(가장 넓은 영웅 시트 폭), 영웅 구역 안, 서로 겹치지 않음, 아틀라스 크기 그대로
func ev876():
	var art := _art()
	if not art.has("wyvern") or not art.has("wyvern_fallen"):
		return "heroes.json에 wyvern·wyvern_fallen 칸이 없다"
	var size: Vector2i = load("res://art/units/heroes.png").get_image().get_size()
	var bad := []
	if size != Vector2i(828, 15656):
		bad.append("heroes.png %s" % size)
	var right := 0
	for h in SIX:  # 영웅 시트 가운데 가장 넓은 것: 쓰러짐 5칸 × 2배 캔버스(atlas.py ANIMS, hero.py FALL)
		right = maxi(right, 10 * int(art[h].c))
	var top: int = int(art.soldier.idle)  # 용병·적 칸 구역이 시작하는 y(첫 용병·적 칸)
	var a: Dictionary = art.wyvern
	var f: Dictionary = art.wyvern_fallen
	if int(a.get("x", -1)) != right or int(f.get("x", -2)) != right:
		bad.append("x 와이번 %s · 떨어진 와이번 %s(가장 넓은 영웅 시트 %d)" % [a.get("x"), f.get("x"), right])
	var rects := _wy_rects("wyvern", a, WY) + _wy_rects("wyvern_fallen", f, WF)
	for i in rects.size():
		var r: Rect2i = rects[i][1]
		if r.position.y < 0 or r.end.y > top or r.end.x > size.x:
			bad.append("%s %s가 영웅 구역(y 0~%d, 폭 %d) 밖" % [rects[i][0], r, top, size.x])
		for j in i:
			if r.intersects(rects[j][1]):
				bad.append("%s %s가 %s와 겹침" % [rects[i][0], r, rects[j][0]])
	return check(bad.is_empty(), "%s" % [bad])
