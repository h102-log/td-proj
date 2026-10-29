extends "res://tests/eval/gd/lib.gd"
# 슬라임 그림(S172 2026-10-27 넷째 변경, I189, S198 2026-10-27 둘째 변경). lib.gd 머리의 계약에 더하는 API:
#   art/units/heroes.json 칸 {c, anchor, x, one, idle, walk, attack, fall} · HudBuild.icon(종류) -> AtlasTexture
#   BattleView: battle · ART · _body(몸, 번호, next) · _region(텍스처, 대상, 원본, 색) · _shadow(자리, 반지름) · _spot(몸) · _seen
#     · _under_boss(영웅) · hp_bar_at(몸) -> 체력 막대 자리(칸)
#   적 cast(예고 {id, left, at}, 뜬 단계면 air) · radius · Battle.traces({hero, age, …}) · Battle.heroes

const View := preload("res://src/ui/battle_view.gd")
const SLIMES := ["slimelet", "slime", "big_slime", "slime_king"]
const FOUR := ["soldier", "archer", "engineer", "basic", "fast", "armored", "flying", "boss"]
const KING := Vector2i(10, 10)
const STILL := {"speed": 0, "sight": 0, "damage": 0}
const MERC := {"hp": BIG, "damage": 0, "range": 0, "sight": 0}
const THREE := [Vector2i(13, 10), Vector2i(13, 9), Vector2i(13, 11)]
const TOL := 0.5
const SINK := 15.0  # 킹 그림 3배를 배율 전 5px 내려 그린다(S236 2026-10-29 변경). 발밑 기준점이 몸 자리보다 이만큼 아래다

# 그림 한 장·그림자를 그리는 대신 모으는 화면
class Rec extends "res://src/ui/battle_view.gd":
	var cuts := []  # [대상 사각형, 원본 사각형]
	var shadows := 0

	func _region(_tex: Texture2D, dst: Rect2, src: Rect2, _tint: Color) -> void:
		cuts.append([dst, src])

	func _shadow(_at: Vector2, _r: float) -> void:
		shadows += 1

func _art() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://art/units/heroes.json"))

# 킹(움직이지도 치지도 않음)과 cells에 둔 땅 위 용병, 그 판을 그리는 기록 화면. 킹 그림이 없으면 이유 글
func _king(cells: Array):
	var b = battle({"base_hp": BIG, "hero_start": Vector2i(2, 2)})
	if not View.ART.has("slime_king"):
		return "heroes.json에 slime_king 칸이 없다"
	var e = b.spawn_enemy("slime_king", KING, STILL)
	for c in cells:
		b.place_merc("soldier", c, MERC)
	var v = Rec.new()
	v.battle = b
	return [b, e, v]

# 몸 x를 한 번 그리고 [대상, 원본, 그림자 수]. 화면이 지난 자리를 기억하게 한다. 그림이 한 장이 아니면 null
func _one(v, x):
	v.cuts = []
	v.shadows = 0
	var next := {}
	var i: int = v.battle.units.find(x)
	if i < 0:
		i = v.battle.units.size() + v.battle.enemies.find(x)
	v._body(x, i, next)
	v._seen = next
	if v.cuts.size() != 1:
		return null
	return [v.cuts[0][0], v.cuts[0][1], v.shadows]

# 정지 칸(c×c) 그림 사각형의 발밑(기준점을 대상 크기에 맞춰 옮긴 자리)
func _foot(dst: Rect2, a: Dictionary) -> Vector2:
	return dst.position + Vector2(a.anchor[0], a.anchor[1]) * dst.size / float(a.c)

func _size_ok(dst: Rect2, want: Vector2) -> bool:
	return absf(dst.size.x - want.x) <= TOL and absf(dst.size.y - want.y) <= TOL

func _idle_src(src: Rect2, a: Dictionary) -> bool:
	return src.is_equal_approx(Rect2(a.get("x", 0), a.idle, a.c, a.c))

func _aloft(e) -> bool:
	return e.cast != null and e.cast.get("air", false)

# 불투명 픽셀 [폭, 개수, 4f78ad 개수, efac28 개수]
func _pixels(img: Image, r: Rect2i) -> Array:
	var used := img.get_region(r).get_used_rect()
	var n := 0
	var blue := 0
	var gold := 0
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var p := img.get_pixel(x, y)
			if p.a > 0.0:
				n += 1
				var h := p.to_html(false)
				blue += int(h == "4f78ad")
				gold += int(h == "efac28")
	return [used.size.x, n, blue, gold]

# 칸의 동작별 그림 사각형: 슬라임(one)은 x에서 한 행, 용병·적 8종은 x 0에서 4방향
func _rects(a: Dictionary) -> Array:
	var c: int = int(a.c)
	var x: int = int(a.get("x", 0))
	var rows := 1 if a.get("one", false) else 4
	return [Rect2i(x, int(a.idle), c, c * rows), Rect2i(x, int(a.walk), 2 * c, c * rows),
		Rect2i(x, int(a.attack), 2 * c, 2 * c * rows), Rect2i(x, int(a.fall), 2 * c, 2 * c)]

# EV537 · S172: 슬라임 4종 칸(방향 없는 한 행)과 크기 차례, 파랑 본색, 킹만 금빛, HUD 아이콘
func ev537():
	var art := _art()
	var img: Image = load("res://art/units/heroes.png").get_image()
	var bad := []
	var widths := []
	for k in SLIMES:
		if not art.has(k):
			return "heroes.json에 %s 칸이 없다" % k
		var a: Dictionary = art[k]
		if a.get("one") != true:
			bad.append("%s one %s" % [k, a.get("one")])
		var c: int = int(a.c)
		var x: int = int(a.get("x", 0))
		var cells := {"idle": Rect2i(x, int(a.idle), c, c), "walk0": Rect2i(x, int(a.walk), c, c), "walk1": Rect2i(x + c, int(a.walk), c, c),
			"attack": Rect2i(x, int(a.attack), 2 * c, 2 * c), "fall": Rect2i(x, int(a.fall), 2 * c, 2 * c)}
		var px := {}
		for n in cells:
			px[n] = _pixels(img, cells[n])
			if px[n][1] == 0:
				bad.append("%s %s 빈 칸" % [k, n])
		if px.walk0[0] == px.walk1[0]:
			bad.append("%s 걷기 두 열 폭 같음 %d" % [k, px.walk0[0]])
		widths.append(px.idle[0])
		if px.idle[1] > 0 and px.idle[2] < 0.35 * px.idle[1]:
			bad.append("%s 4f78ad %d/%d" % [k, px.idle[2], px.idle[1]])
		if (px.idle[3] > 0) != (k == "slime_king"):
			bad.append("%s efac28 %d" % [k, px.idle[3]])
		var t: AtlasTexture = load("res://src/ui/hud_build.gd").icon(k)
		if not t.region.has_area() or not Rect2(cells.idle).encloses(t.region):
			bad.append("%s 아이콘 %s(칸 %s)" % [k, t.region, cells.idle])
	for i in range(1, widths.size()):
		if widths[i - 1] >= widths[i]:
			bad.append("정지 폭 차례 %s" % [widths])
			break
	return check(bad.is_empty(), "%s" % [bad])

# EV538 · I189: 아틀라스 높이 16384 이하, 슬라임 칸은 용병·적 8종 구역 안의 빈자리
func ev538():
	var art := _art()
	var img: Image = load("res://art/units/heroes.png").get_image()
	if img.get_height() > 16384:
		return "heroes.png 높이 %d" % img.get_height()
	var top := INF
	var bottom := -INF
	var taken := []
	for k in FOUR:
		var a: Dictionary = art[k]
		top = minf(top, a.idle)
		bottom = maxf(bottom, a.fall + 2 * a.c)
		taken.append_array(_rects(a))
	var bad := []
	for k in SLIMES:
		if not art.has(k) or art[k].get("one") != true:
			return "heroes.json에 %s 한 행 칸이 없다" % k
		for r in _rects(art[k]):
			if r.position.y < top or r.end.y > bottom:
				bad.append("%s %s가 구역 y %d~%d 밖" % [k, r, top, bottom])
			for o in taken:
				if r.intersects(o):
					bad.append("%s %s가 %s와 겹침" % [k, r, o])
			taken.append(r)
	return check(bad.is_empty(), "%s" % [bad])

# EV539 · S198: 슬라임 킹 웅크림(발밑 기준 납작해짐)·뜸(그림자 위로 10px)·착지 눌림(0.15초에 돌아옴), 늘 정지 그림 칸
func ev539():
	var s = _king(THREE)
	if s is String:
		return s
	var b = s[0]
	var e = s[1]
	var v = s[2]
	var a: Dictionary = View.ART.slime_king
	var base = _one(v, e)
	if base == null:
		return "킹 몸통이 그림 한 장이 아니다(%s)" % [v.cuts]
	var r0: Rect2 = base[0]
	var bad := []
	if base[2] != 0 or not _idle_src(base[1], a):
		bad.append("예고 전 그림자 %d · 원본 %s" % [base[2], base[1]])
	run(b, DT)
	if e.cast == null or not e.cast.has("at"):
		return "첫 스텝에 웅크리지 않았다(%s)" % [e.cast]
	var windup: float = e.cast.left
	for case in [[0.6, Vector2(1.075, 0.875)], [0.3, Vector2(1.1125, 0.8125)], [0.01, Vector2(1.15, 0.75)]]:
		e.cast.left = case[0]
		var d = _one(v, e)
		var want: Vector2 = r0.size * case[1]
		if d == null or not _size_ok(d[0], want) or _foot(d[0], a).distance_to(v._spot(e) + Vector2(0, SINK)) > TOL or d[2] != 0 or not _idle_src(d[1], a):
			bad.append("웅크림 %.2f초 남음: %s(크기 %s · 발밑 %s=%s)" % [case[0], d, want, _foot(d[0], a) if d else null, v._spot(e)])
	e.cast.left = windup
	run(b, 2.0, func(): return _aloft(e))
	if not _aloft(e):
		return "%s · 뜨지 않았다" % [bad]
	var air: float = e.cast.left
	e.cast.left = 0.3
	var d = _one(v, e)
	if d == null or not _size_ok(d[0], r0.size) or absf(v._spot(e).y - _foot(d[0], a).y - (30.0 - SINK)) > TOL or d[2] < 1 or not _idle_src(d[1], a):
		bad.append("뜬 한가운데: %s(발밑 %s · 화면 자리 %s)" % [d, _foot(d[0], a) if d else null, v._spot(e)])
	e.cast.left = air
	run(b, 2.0, func(): return e.cast == null)
	var tr = null
	for t in b.traces:
		if t.hero == e:
			tr = t
	if tr == null or tr.age >= 0.15:
		bad.append("착지 흔적 %s" % [tr])
	else:
		var k: float = tr.age / 0.15
		d = _one(v, e)
		var want := r0.size * Vector2(1.15 - 0.15 * k, 0.75 + 0.25 * k)
		if d == null or not _size_ok(d[0], want) or d[2] != 0 or not _idle_src(d[1], a):
			bad.append("착지 나이 %.2f: %s(크기 %s)" % [tr.age, d, want])
	run(b, 0.2)
	d = _one(v, e)
	if d == null or not _size_ok(d[0], r0.size) or not _idle_src(d[1], a):
		bad.append("착지 0.2초 뒤: %s(기준 %s)" % [d, r0.size])
	v.free()
	return check(bad.is_empty(), "%s" % [bad])

# 영웅을 킹 위 0~4.5칸에 0.1칸 간격으로 옮겨 가며 [가린 영웅 판정과 그린 사각형 겹침 25% 초과가 다른 자리들, 참 수, 거짓 수]
func _cover(v, e, h, king: Rect2) -> Array:
	var ha: Dictionary = View.ART[h.kind]
	var odd := []
	var yes := 0
	var no := 0
	for k in 46:  # 킹 그림이 4칸 남짓이라 그 위까지(S236 2026-10-29 변경)
		h.pos = e.pos - Vector2(0, 0.1 * k)
		var hr := Rect2(v._spot(h) - Vector2(ha.anchor[0], ha.anchor[1]), Vector2(ha.c, ha.c))
		var want: bool = hr.intersection(king).get_area() > 0.25 * hr.get_area()
		var got: bool = v._under_boss(h)
		yes += int(got)
		no += int(not got)
		if got != want:
			odd.append([0.1 * k, got, want])
	return [odd, yes, no]

# EV540 · S198: 줄어든 킹은 발밑 기준으로 반지름 비율만큼 작게, 체력 막대는 줄어든 머리와 뜬 높이를 따르고, 가린 영웅은 그린 그림으로 잰다
func ev540():
	var s = _king([])
	if s is String:
		return s
	var b = s[0]
	var e = s[1]
	var v = s[2]
	if not v.has_method("hp_bar_at"):
		return "BattleView.hp_bar_at이 없다"
	var a: Dictionary = View.ART.slime_king
	var h = b.heroes[0]
	var full = _one(v, e)
	if full == null:
		return "킹 몸통이 그림 한 장이 아니다(%s)" % [v.cuts]
	var bar_full: Vector2 = v.hp_bar_at(e) - e.pos
	var bad := []
	var cover := [_cover(v, e, h, full[0])]
	e.hp = e.max_hp * 0.5
	run(b, DT)
	if absf(e.radius - 2.0 * 0.8) > 0.01:
		return "체력 50%% 킹 반지름 %.3f" % e.radius
	var half = _one(v, e)
	if half == null or not _size_ok(half[0], full[0].size * 0.8) or half[0].get_center().distance_to(full[0].get_center()) > TOL:  # 큰 몸은 그림 가운데가 몸 가운데라 가운데가 그대로다(S236 2026-10-29 변경)
		bad.append("50%%: %s(가득 %s)" % [half, full])
	var drop: float = (v.hp_bar_at(e) - e.pos - bar_full).y * CELL_PX
	var want: float = (a.anchor[1] - 5.0) * 3.0 * 0.2  # 3배로 그리고 배율 전 5px 내린다(S236 2026-10-29 변경)
	if absf(drop - want) > TOL:
		bad.append("50%% 막대 %.2fpx 낮음(기대 %.2f)" % [drop, want])
	if half:
		cover.append(_cover(v, e, h, half[0]))
	var t = _king(THREE)
	var b2 = t[0]
	var e2 = t[1]
	var v2 = t[2]
	var ground: Vector2 = v2.hp_bar_at(e2) - e2.pos
	run(b2, 3.0, func(): return _aloft(e2))
	if not _aloft(e2):
		bad.append("뜨지 않았다")
	else:
		e2.cast.left = 0.3
		var rise: float = (ground - (v2.hp_bar_at(e2) - e2.pos)).y * CELL_PX
		if absf(rise - 30.0) > TOL:  # LEAP_UP 10 × 3배(S236 2026-10-29 변경)
			bad.append("뜬 한가운데 막대 %.2fpx 높음" % rise)
		var up = _one(v2, e2)
		if up:
			cover.append(_cover(v2, e2, b2.heroes[0], up[0]))
	var o = b.spawn_enemy("boss", Vector2i(20, 15), STILL)
	var ogre_full: Vector2 = v.hp_bar_at(o) - o.pos
	o.hp = o.max_hp * 0.5
	run(b, DT)
	if not (v.hp_bar_at(o) - o.pos).is_equal_approx(ogre_full):
		bad.append("오우거 막대 %s → %s" % [ogre_full, v.hp_bar_at(o) - o.pos])
	var odd := []
	var yes := 0
	var no := 0
	for c in cover:
		odd.append_array(c[0])
		yes += c[1]
		no += c[2]
	if not odd.is_empty() or yes == 0 or no == 0 or cover.size() < 3:
		bad.append("가린 영웅 [높이, 판정, 겹침 25%%] %s · 참 %d · 거짓 %d · 상태 %d" % [odd, yes, no, cover.size()])
	v.free()
	v2.free()
	return check(bad.is_empty(), "%s" % [bad])

# EV541 · S172: 슬라임 4종은 어느 쪽으로 걸어도 걷기 0행을 그리고, 고블린은 동쪽 행을 그린다
func ev541():
	var b = battle({"base_hp": BIG})
	var v = Rec.new()
	v.battle = b
	var bad := []
	for k in SLIMES + ["basic"]:
		if not View.ART.has(k):
			return "heroes.json에 %s 칸이 없다" % k
		var a: Dictionary = View.ART[k]
		var e = b.spawn_enemy(k, Vector2i(10 + 3 * SLIMES.find(k), 10), STILL)
		_one(v, e)
		var x: float = a.get("x", 0)
		for step in ([Vector2.RIGHT] if k == "basic" else [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]):
			e.pos += step
			var d = _one(v, e)
			var row: float = a.walk + (a.c if k == "basic" else 0)
			if d == null or not is_equal_approx(d[1].position.y, row) or not (is_equal_approx(d[1].position.x, x) or is_equal_approx(d[1].position.x, x + a.c)):
				bad.append("%s %s쪽: %s(기대 y %s · x %s 또는 %s)" % [k, step, d, row, x, x + a.c])
		b.enemies.erase(e)
	v.free()
	return check(bad.is_empty(), "%s" % [bad])

# EV596 · S236 2026-10-29 변경: 킹 정지 그림은 3배(32px 칸 → 96px)이고 그 가운데가 몸 자리(칸 가운데)다
func ev596():
	var s = _king([])
	if s is String:
		return s
	var e = s[1]
	var v = s[2]
	var got = _one(v, e)
	var at: Vector2 = v._spot(e)
	v.free()
	if got == null:
		return "킹 몸통이 그림 한 장이 아니다"
	return check(got[0].size.is_equal_approx(Vector2(96, 96)) and got[0].get_center().distance_to(at) <= TOL, "킹 그림 %s, 가운데 %s(몸 자리 %s)" % [got[0], got[0].get_center(), at])

# EV597 · S234 2026-10-29 변경: 갈라져 나온 꼬마 슬라임은 처음 훑을 때 배율 0.5이고 발밑(미끄러짐 더함)이 죽은 자리다.
# 0.15초 뒤 배율은 0.5와 1 사이, 0.35초 뒤 배율 1·미끄러짐 없음이다. 출현 지점에서 나온 슬라임은 처음부터 배율 1이다
func ev597():
	var b = battle({"base_hp": BIG})
	var p = b.spawn_enemy("slime", KING, STILL)
	var v = Rec.new()
	v.battle = b
	v._slide_scan()
	b.damage(p, BIG)
	b.step(DT)
	var kids: Array = b.enemies.filter(func(x): return x.kind == "slimelet")
	if kids.size() != 2:
		v.free()
		return "갈라져 나온 꼬마 슬라임 %d마리(2)" % kids.size()
	var o = b.spawn_enemy("slime", Vector2i(20, 10), STILL)
	v._slide_scan()
	var dead: Vector2 = v._center(Vector2(KING))
	var bad := []
	for k in kids:
		var foot: Vector2 = v._spot(k) + v._slip(k)
		if not is_equal_approx(v._look(k)[0].y, 0.5) or foot.distance_to(dead) > TOL:
			bad.append("처음 배율 %s, 발밑 %s(죽은 자리 %s)" % [v._look(k)[0], foot, dead])
	if not is_equal_approx(v._look(o)[0].y, 1.0):
		bad.append("출현 지점 슬라임 배율 %s" % [v._look(o)[0]])
	v.clock += 0.15
	for k in kids:
		var y: float = v._look(k)[0].y
		if y <= 0.5 or y >= 1.0:
			bad.append("0.15초 배율 %.3f" % y)
	v.clock += 0.2
	for k in kids:
		if not is_equal_approx(v._look(k)[0].y, 1.0) or v._slip(k).length() > TOL:
			bad.append("0.35초 배율 %s, 미끄러짐 %s" % [v._look(k)[0], v._slip(k)])
	v.free()
	return check(bad.is_empty(), "%s" % [bad])
