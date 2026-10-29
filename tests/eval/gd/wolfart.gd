extends "res://tests/eval/gd/lib.gd"
# 늑대 그림(S172 2026-10-29 변경, I189 2026-10-29 변경, S244). lib.gd 머리의 계약에 더하는 API:
#   art/units/heroes.json 칸 {c, anchor, x, idle, walk, attack, fall, crouch, air} · HudBuild.icon(종류) -> AtlasTexture
#   BattleView: battle · ART · _body(몸, 번호, next) · _region(텍스처, 대상, 원본, 색) · _shadow(자리, 반지름) · _seen
#   적 climb · climbed(초) · cast(덮치기 예고 {id, left, at}, 뜬 단계면 air·from)

const View := preload("res://src/ui/battle_view.gd")
const WOLVES := ["wolf", "leap_wolf", "night_wolf", "alpha_wolf"]
const EXTRA := {"leap_wolf": ["crouch"], "alpha_wolf": ["crouch", "air"]}
const FOUR := ["soldier", "archer", "engineer", "basic", "fast", "armored", "flying", "boss"]
const SLIMES := ["slimelet", "slime", "big_slime", "slime_king"]
const STILL := {"speed": 0, "sight": 0, "damage": 0}
const TOL := 0.5

# 그림 한 장·그림자를 그리는 대신 모으는 화면
class Rec extends "res://src/ui/battle_view.gd":
	var cuts := []  # [대상 사각형, 원본 사각형]

	func _region(_tex: Texture2D, dst: Rect2, src: Rect2, _tint: Color) -> void:
		cuts.append([dst, src])

	func _shadow(_at: Vector2, _r: float) -> void:
		pass

func _art() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://art/units/heroes.json"))

func _rec(b):
	var v = Rec.new()
	v.battle = b
	return v

# 몸 x를 한 번 그리고 [대상, 원본]. 화면이 지난 자리를 기억하게 한다. 그림이 한 장이 아니면 null
func _one(v, x):
	v.cuts = []
	var next := {}
	v._body(x, v.battle.units.size() + v.battle.enemies.find(x), next)
	v._seen = next
	if v.cuts.size() != 1:
		return null
	return [v.cuts[0][0], v.cuts[0][1]]

# 그림 사각형의 발밑 줄(기준점을 대상 크기에 맞춰 옮긴 y)
func _foot(dst: Rect2, a: Dictionary) -> float:
	return dst.position.y + a.anchor[1] * dst.size.y / float(a.c)

func _opaque(img: Image, r: Rect2i) -> int:
	var n := 0
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			n += int(img.get_pixel(x, y).a > 0.0)
	return n

func _has(img: Image, r: Rect2i, hexes: Array) -> bool:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var p := img.get_pixel(x, y)
			if p.a > 0.0 and p.to_html(false) in hexes:
				return true
	return false

# 어떤 행에 hexes 색 픽셀이 1px 이상 떨어진 두 무리로 있나
func _two_groups(img: Image, r: Rect2i, hexes: Array) -> bool:
	for y in range(r.position.y, r.end.y):
		var xs := []
		for x in range(r.position.x, r.end.x):
			var p := img.get_pixel(x, y)
			if p.a > 0.0 and p.to_html(false) in hexes:
				xs.append(x)
		for i in range(1, xs.size()):
			if xs[i] - xs[i - 1] >= 2:
				return true
	return false

# 칸의 동작별 그림 사각형. 슬라임(one)은 한 행, 나머지는 4방향. 웅크림·뜀은 정지와 같은 크기
func _rects(a: Dictionary) -> Array:
	var c: int = int(a.c)
	var x: int = int(a.get("x", 0))
	var rows := 1 if a.get("one", false) else 4
	var out := [Rect2i(x, int(a.idle), c, c * rows), Rect2i(x, int(a.walk), 2 * c, c * rows),
		Rect2i(x, int(a.attack), 2 * c, 2 * c * rows), Rect2i(x, int(a.fall), 2 * c, 2 * c)]
	for e in ["crouch", "air"]:
		if a.has(e):
			out.append(Rect2i(x, int(a[e]), c, c * rows))
	return out

# EV586 · S172: 늑대 4종 칸(4방향, x 있음, one 없음)·웅크림·뜀, 크기, 알파 붉은 눈, 밤 늑대 두 눈, HUD 아이콘
func ev586():
	var art := _art()
	var img: Image = load("res://art/units/heroes.png").get_image()
	var whole := Rect2i(Vector2i.ZERO, img.get_size())
	var bad := []
	var high := {}
	for k in WOLVES:
		if not art.has(k):
			return "heroes.json에 %s 칸이 없다" % k
		var a: Dictionary = art[k]
		if not a.has("x") or a.has("one"):
			bad.append("%s x %s · one %s" % [k, a.get("x"), a.get("one")])
		var c: int = int(a.c)
		var x: int = int(a.get("x", 0))
		var cells := {"fall": Rect2i(x, int(a.fall), 2 * c, 2 * c)}
		for r in 4:
			cells["idle%d" % r] = Rect2i(x, int(a.idle) + r * c, c, c)
			cells["walk0_%d" % r] = Rect2i(x, int(a.walk) + r * c, c, c)
			cells["walk1_%d" % r] = Rect2i(x + c, int(a.walk) + r * c, c, c)
			cells["attack%d" % r] = Rect2i(x, int(a.attack) + 2 * r * c, 2 * c, 2 * c)
			for e in EXTRA.get(k, []):
				if a.has(e):
					cells["%s%d" % [e, r]] = Rect2i(x, int(a[e]) + r * c, c, c)
		for e in EXTRA.get(k, []):
			if not a.has(e):
				bad.append("%s %s 없음" % [k, e])
		for n in cells:
			if not whole.encloses(cells[n]):
				bad.append("%s %s %s가 그림 밖" % [k, n, cells[n]])
			elif _opaque(img, cells[n]) == 0:
				bad.append("%s %s 빈 칸" % [k, n])
		if not whole.encloses(cells.idle0):
			continue
		high[k] = img.get_region(cells.idle0).get_used_rect().size.y
		if k == "alpha_wolf" and not _has(img, cells.idle0, ["ef3a0c"]):
			bad.append("alpha_wolf 정지 남쪽에 ef3a0c 없음")
		if k == "night_wolf" and not _two_groups(img, cells.idle0, ["efd8a1", "efac28"]):
			bad.append("night_wolf 정지 남쪽 눈이 두 무리가 아니다")
		var t: AtlasTexture = load("res://src/ui/hud_build.gd").icon(k)
		if not t.region.has_area() or not Rect2(cells.idle0).encloses(t.region):
			bad.append("%s 아이콘 %s(칸 %s)" % [k, t.region, cells.idle0])
	if high.has("wolf") and high.has("alpha_wolf") and high.alpha_wolf < 1.5 * high.wolf:
		bad.append("정지 남쪽 높이 %s" % [high])
	return check(bad.is_empty() and high.size() == WOLVES.size(), "%s · 높이 %s" % [bad, high])

# EV587 · I189: 아틀라스 높이 16384 이하, 늑대 칸은 용병·적 8종 구역 안의 빈자리
func ev587():
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
	for k in SLIMES:
		taken.append_array(_rects(art[k]))
	var bad := []
	for k in WOLVES:
		if not art.has(k) or not art[k].has("x") or art[k].has("one"):
			return "heroes.json에 %s 옆 열 4방향 칸이 없다" % k
		for r in _rects(art[k]):
			if r.position.y < top or r.end.y > bottom:
				bad.append("%s %s가 구역 y %d~%d 밖" % [k, r, top, bottom])
			for o in taken:
				if r.intersects(o):
					bad.append("%s %s가 %s와 겹침" % [k, r, o])
			taken.append(r)
	return check(bad.is_empty(), "%s" % [bad])

# EV588 · S172: 늑대 4종은 동쪽으로 걸으면 그 칸 x의 걷기 동쪽 행을 그린다
func ev588():
	var b = battle({"base_hp": BIG})
	var v = _rec(b)
	var bad := []
	for i in WOLVES.size():
		var k: String = WOLVES[i]
		if not View.ART.has(k):
			return "heroes.json에 %s 칸이 없다" % k
		var a: Dictionary = View.ART[k]
		var e = b.spawn_enemy(k, Vector2i(10 + 3 * i, 10), STILL)
		_one(v, e)
		e.pos += Vector2.RIGHT
		var d = _one(v, e)
		var x: float = a.get("x", 0)
		if d == null or not is_equal_approx(d[1].position.y, a.walk + a.c) or not (is_equal_approx(d[1].position.x, x) or is_equal_approx(d[1].position.x, x + a.c)):
			bad.append("%s 동쪽: %s(기대 y %s · x %s 또는 %s)" % [k, d, a.walk + a.c, x, x + a.c])
		b.enemies.erase(e)
	v.free()
	return check(bad.is_empty(), "%s" % [bad])

# 기어오르는 몸 x를 climbed초만큼 오른 채 그린다
func _climbing(v, x, climbed: float):
	x.climbed = climbed
	return _one(v, x)

# EV589 · S244 ①: 도약 늑대는 마지막 0.15초 전까지 성벽 밑에서 웅크리고, 그 뒤 정지 그림으로 다른 오르는 적과 같은 비율만큼 오른다
func ev589():
	var b = battle({"base_hp": BIG})
	var v = _rec(b)
	for k in ["leap_wolf", "fast"]:
		if not View.ART.has(k):
			return "heroes.json에 %s 칸이 없다" % k
	var a: Dictionary = View.ART.leap_wolf
	var ka: Dictionary = View.ART.fast
	if not a.has("crouch"):
		return "leap_wolf 칸에 crouch가 없다"
	var w = b.spawn_enemy("leap_wolf", Vector2i(10, 10), STILL)
	var f = b.spawn_enemy("fast", Vector2i(10, 10), STILL)
	w.climb = 0.8
	f.climb = 0.8
	var c: float = a.c
	var bad := []
	var w0 = _climbing(v, w, 0.0)
	var f0 = _climbing(v, f, 0.0)
	var f4 = _climbing(v, f, 0.4)
	if w0 == null or f0 == null or f4 == null:
		return "그림이 한 장이 아니다(늑대 %s · 코볼트 %s · %s)" % [w0, f0, f4]
	var kfoot: float = _foot(f4[0], ka)
	if not is_equal_approx(f4[1].position.y, ka.walk + 2 * ka.c) or _foot(f0[0], ka) - kfoot <= 1.0:
		bad.append("코볼트 0.4초: 원본 %s · 발밑 %.2f → %.2f" % [f4[1], _foot(f0[0], ka), kfoot])
	for t in [0.4, 0.64]:
		var d = _climbing(v, w, t)
		if d == null or not d[1].is_equal_approx(Rect2(a.x, a.crouch + 2 * c, c, c)) or absf(_foot(d[0], a) - _foot(w0[0], a)) > TOL:
			bad.append("늑대 %.3f초: %s(발밑 %s · 오르기 전 %.2f)" % [t, d, _foot(d[0], a) if d else null, _foot(w0[0], a)])
	var up = _climbing(v, w, 0.725)
	if up == null or not up[1].is_equal_approx(Rect2(a.x, a.idle + 2 * c, c, c)) or absf(_foot(up[0], a) - kfoot) > TOL:
		bad.append("늑대 0.725초: %s(발밑 %s · 코볼트 0.4초 %.2f)" % [up, _foot(up[0], a) if up else null, kfoot])
	v.free()
	return check(bad.is_empty(), "%s" % [bad])

# EV590 · S244 ②: 알파 덮치기 예고는 대상 쪽 웅크림, 뜬 단계는 대상 쪽 뜀이고 들어 올리지 않는다
func ev590():
	var b = battle({"base_hp": BIG})
	var v = _rec(b)
	if not View.ART.has("alpha_wolf") or not View.ART.alpha_wolf.has("crouch") or not View.ART.alpha_wolf.has("air"):
		return "heroes.json에 alpha_wolf 웅크림·뜀 칸이 없다"
	var a: Dictionary = View.ART.alpha_wolf
	var c: float = a.c
	var e = b.spawn_enemy("alpha_wolf", Vector2i(10, 10), STILL)
	var d0 = _one(v, e)
	if d0 == null:
		return "알파 몸통이 그림 한 장이 아니다(%s)" % [v.cuts]
	var at: Vector2 = e.pos + Vector2(3, 0)
	var bad := []
	for case in [[{"id": "pounce", "left": 0.6, "at": at}, "crouch"], [{"id": "pounce", "left": 0.2, "at": at}, "crouch"],
			[{"id": "pounce", "left": 0.2, "air": true, "from": e.pos, "at": at}, "air"]]:
		e.cast = case[0]
		var d = _one(v, e)
		var want := Rect2(a.x, a[case[1]] + c, c, c)
		if d == null or not d[1].is_equal_approx(want) or absf(_foot(d[0], a) - _foot(d0[0], a)) > TOL:
			bad.append("%s: %s(기대 원본 %s · 발밑 %.2f)" % [case[0], d, want, _foot(d0[0], a)])
	e.cast = null
	v.free()
	return check(bad.is_empty(), "%s" % [bad])
