extends "res://tests/eval/gd/lib.gd"
# 3라운드 고블린 네 종 그림(S172 2026-11-03 변경, I189 2026-11-03 변경). lib.gd 머리의 계약에 더하는 API:
#   art/units/heroes.json 칸 {c, anchor, x, idle, walk, attack, fall, land_idle, land_walk} · HudBuild.icon(종류) -> AtlasTexture
#   BattleView: battle · ART · _body(몸, 번호, next) · _corpse([몸, 쓰러진 뒤 초]) · _region(텍스처, 대상, 원본, 색) · _shadow(자리, 반지름) · _seen
#   적 flying · cast(도화선 {id fuse, left, at}, 던지기 {id throw, left, at}) · throw.windup

const View := preload("res://src/ui/battle_view.gd")
const RAID := ["sapper", "ram", "catapult", "glider"]
const FALLS := ["sapper", "glider"]  # 누운 자세가 있는 종류. 망치·투석기는 정지 그림이 흐려진다
const FOUR := ["soldier", "archer", "engineer", "basic", "fast", "armored", "flying", "boss"]
const SLIMES := ["slimelet", "slime", "big_slime", "slime_king"]
const WOLVES := ["wolf", "leap_wolf", "night_wolf", "alpha_wolf"]
const STILL := {"speed": 0, "sight": 0, "damage": 0}

# 그림 한 장·그림자를 그리는 대신 모으는 화면
class Rec extends "res://src/ui/battle_view.gd":
	var cuts := []  # [대상 사각형, 원본 사각형, 색]

	func _region(_tex: Texture2D, dst: Rect2, src: Rect2, tint: Color) -> void:
		cuts.append([dst, src, tint])

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

func _opaque(img: Image, r: Rect2i) -> int:
	var n := 0
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			n += int(img.get_pixel(x, y).a > 0.0)
	return n

# 칸의 동작별 그림 사각형. 슬라임(one)은 한 행, 나머지는 4방향. 웅크림·뜀·내린 정지는 정지와, 내린 걷기는 걷기와 같은 크기
func _rects(a: Dictionary) -> Array:
	var c: int = int(a.c)
	var x: int = int(a.get("x", 0))
	var rows := 1 if a.get("one", false) else 4
	var out := [Rect2i(x, int(a.idle), c, c * rows), Rect2i(x, int(a.walk), 2 * c, c * rows), Rect2i(x, int(a.attack), 2 * c, 2 * c * rows)]
	if a.has("fall"):
		out.append(Rect2i(x, int(a.fall), 2 * c, 2 * c))
	for e in ["crouch", "air", "land_idle"]:
		if a.has(e):
			out.append(Rect2i(x, int(a[e]), c, c * rows))
	if a.has("land_walk"):
		out.append(Rect2i(x, int(a.land_walk), 2 * c, c * rows))
	return out

# EV678 · S172: 네 종 칸(4방향, x 있음, one 없음)·누운 자세(폭파병·글라이더만)·내린 글라이더, 크기, HUD 아이콘
func ev678():
	var art := _art()
	var img: Image = load("res://art/units/heroes.png").get_image()
	var whole := Rect2i(Vector2i.ZERO, img.get_size())
	var bad := []
	var used := {}
	for k in RAID:
		if not art.has(k):
			return "heroes.json에 %s 칸이 없다" % k
		var a: Dictionary = art[k]
		if not a.has("x") or a.has("one"):
			bad.append("%s x %s · one %s" % [k, a.get("x"), a.get("one")])
		if a.has("fall") != (k in FALLS):
			bad.append("%s fall %s" % [k, a.get("fall")])
		var c: int = int(a.c)
		var x: int = int(a.get("x", 0))
		var cells := {}
		if a.has("fall"):
			cells["fall"] = Rect2i(x, int(a.fall), 2 * c, 2 * c)
		if k == "glider" and not (a.has("land_idle") and a.has("land_walk")):
			bad.append("glider land_idle %s · land_walk %s" % [a.get("land_idle"), a.get("land_walk")])
		for r in 4:
			cells["idle%d" % r] = Rect2i(x, int(a.idle) + r * c, c, c)
			cells["walk0_%d" % r] = Rect2i(x, int(a.walk) + r * c, c, c)
			cells["walk1_%d" % r] = Rect2i(x + c, int(a.walk) + r * c, c, c)
			cells["attack%d" % r] = Rect2i(x, int(a.attack) + 2 * r * c, 2 * c, 2 * c)
			if a.has("land_idle") and a.has("land_walk"):
				cells["land_idle%d" % r] = Rect2i(x, int(a.land_idle) + r * c, c, c)
				cells["land_walk0_%d" % r] = Rect2i(x, int(a.land_walk) + r * c, c, c)
				cells["land_walk1_%d" % r] = Rect2i(x + c, int(a.land_walk) + r * c, c, c)
		for n in cells:
			if not whole.encloses(cells[n]):
				bad.append("%s %s %s가 그림 밖" % [k, n, cells[n]])
			elif _opaque(img, cells[n]) == 0:
				bad.append("%s %s 빈 칸" % [k, n])
		if not whole.encloses(cells.idle0):
			continue
		used[k] = img.get_region(cells.idle0).get_used_rect().size
		if cells.has("land_idle0") and whole.encloses(cells.land_idle0):
			used["land"] = img.get_region(cells.land_idle0).get_used_rect().size
		var t: AtlasTexture = load("res://src/ui/hud_build.gd").icon(k)
		if not t.region.has_area() or not Rect2(cells.idle0).encloses(t.region):
			bad.append("%s 아이콘 %s(칸 %s)" % [k, t.region, cells.idle0])
	if used.size() != RAID.size() + 1:
		return "정지 남쪽 크기를 다 재지 못했다: %s · %s" % [used, bad]
	if used.ram.y < 2 * used.sapper.y:
		bad.append("높이 ram %d · sapper %d" % [used.ram.y, used.sapper.y])
	if used.glider.x < 1.5 * used.land.x:
		bad.append("폭 glider %d · land_idle %d" % [used.glider.x, used.land.x])
	return check(bad.is_empty(), "%s · 크기 %s" % [bad, used])

# EV679 · I189: 아틀라스 크기 그대로, 네 종 칸은 늑대·슬라임 옆 열 오른쪽의 둘째 옆 열에서 용병·적 8종 구역 안의 빈자리
func ev679():
	var art := _art()
	var img: Image = load("res://art/units/heroes.png").get_image()
	if img.get_size() != Vector2i(414, 15656):
		return "heroes.png 크기 %s" % img.get_size()
	var top := INF
	var bottom := -INF
	var taken := []
	for k in FOUR:
		var a: Dictionary = art[k]
		top = minf(top, a.idle)
		bottom = maxf(bottom, a.fall + 2 * a.c)
		taken.append_array(_rects(a))
	var right := 0
	for k in SLIMES + WOLVES:
		for r in _rects(art[k]):
			right = maxi(right, r.end.x)
			taken.append(r)
	var bad := []
	var xs := {}
	for k in RAID:
		if not art.has(k) or not art[k].has("x") or art[k].has("one"):
			return "heroes.json에 %s 옆 열 4방향 칸이 없다" % k
		xs[int(art[k].x)] = true
		if int(art[k].x) < right:
			bad.append("%s x %d < 옆 열 오른쪽 %d" % [k, art[k].x, right])
		for r in _rects(art[k]):
			if r.position.y < top or r.end.y > bottom:
				bad.append("%s %s가 구역 y %d~%d 밖" % [k, r, top, bottom])
			for o in taken:
				if r.intersects(o):
					bad.append("%s %s가 %s와 겹침" % [k, r, o])
			taken.append(r)
	if xs.size() != 1:
		bad.append("네 종 x가 여럿: %s" % [xs.keys()])
	return check(bad.is_empty(), "%s" % [bad])

# 몸 x를 그린 뒤 동쪽으로 한 칸 옮겨 그린다. 원본이 칸 a의 walk 동쪽 행(칸 x 또는 x + c)이 아니면 틀린 글
func _east(v, x, a: Dictionary, walk: String) -> String:
	_one(v, x)
	x.pos += Vector2.RIGHT
	var d = _one(v, x)
	var at: float = a.get("x", 0)
	if d == null or not is_equal_approx(d[1].position.y, a[walk] + a.c) or not (is_equal_approx(d[1].position.x, at) or is_equal_approx(d[1].position.x, at + a.c)):
		return "%s %s 동쪽: %s(기대 y %s · x %s 또는 %s)" % [x.kind, walk, d, a[walk] + a.c, at, at + a.c]
	return ""

# EV680 · S172: 네 종은 동쪽으로 걸으면 걷기 동쪽 행, 내려앉은 글라이더는 날개 접은 걷기·정지
func ev680():
	var b = battle({"base_hp": BIG})
	var v = _rec(b)
	var bad := []
	for i in RAID.size():
		var k: String = RAID[i]
		if not View.ART.has(k):
			return "heroes.json에 %s 칸이 없다" % k
		var a: Dictionary = View.ART[k]
		var e = b.spawn_enemy(k, Vector2i(6 + 4 * i, 10), STILL)
		var msg := _east(v, e, a, "walk")
		if msg != "":
			bad.append(msg)
		if k == "glider":
			if not (a.has("land_idle") and a.has("land_walk")):
				return "glider 칸에 land_idle·land_walk가 없다"
			e.flying = false
			msg = _east(v, e, a, "land_walk")
			if msg != "":
				bad.append(msg)
			var d = _one(v, e)
			var want := Rect2(a.x, a.land_idle + a.c, a.c, a.c)
			if d == null or not d[1].is_equal_approx(want):
				bad.append("내린 glider 정지: %s(기대 %s)" % [d, want])
		b.enemies.erase(e)
	v.free()
	return check(bad.is_empty(), "%s" % [bad])

# EV681 · S172 ①②: 폭파병은 도화선 내내 보던 쪽 공격 자세, 투석기는 던지기 예고 0.08~0.22초에 원 가운데 쪽 공격 자세
func ev681():
	var b = battle({"base_hp": BIG})
	var v = _rec(b)
	for k in ["sapper", "catapult"]:
		if not View.ART.has(k):
			return "heroes.json에 %s 칸이 없다" % k
	var bad := []
	var a: Dictionary = View.ART.sapper
	var c: float = a.c
	var s = b.spawn_enemy("sapper", Vector2i(10, 10), STILL)
	_one(v, s)
	s.pos += Vector2.UP
	_one(v, s)
	var want := Rect2(a.x, a.attack + 2 * 2 * c, 2 * c, 2 * c)
	for left in [2.9, 0.1]:
		s.cast = {"id": "fuse", "left": left, "at": s.pos}
		var d = _one(v, s)
		if d == null or not d[1].is_equal_approx(want):
			bad.append("도화선 left %.1f: %s(기대 %s)" % [left, d, want])
	s.cast = null
	b.enemies.erase(s)
	var p: Dictionary = View.ART.catapult
	var pc: float = p.c
	var t = b.spawn_enemy("catapult", Vector2i(10, 20), STILL)
	_one(v, t)
	t.pos += Vector2.RIGHT
	_one(v, t)
	var w: float = t.throw.windup
	t.cast = {"id": "throw", "left": w - 0.15, "at": t.pos + Vector2(0, -5)}
	var d1 = _one(v, t)
	var hit := Rect2(p.x, p.attack + 2 * 2 * pc, 2 * pc, 2 * pc)
	if d1 == null or not d1[1].is_equal_approx(hit):
		bad.append("던지기 0.15초: %s(기대 %s)" % [d1, hit])
	t.cast = {"id": "throw", "left": w - 0.5, "at": t.pos + Vector2(0, -5)}
	var d2 = _one(v, t)
	if d2 == null or not d2[1].size.is_equal_approx(Vector2(pc, pc)) or d2[1].position.y < p.idle or d2[1].position.y >= p.idle + 4 * pc:
		bad.append("던지기 0.5초: %s(기대 정지 칸 y %s~)" % [d2, p.idle])
	t.cast = null
	v.free()
	return check(bad.is_empty(), "%s" % [bad])

# EV682 · S172 ④: 쓰러진 폭파병·글라이더는 누운 자세, 망치·투석기는 정지 남쪽 그림. 넷 다 S180 시간대로 흐려진다
func ev682():
	var b = battle({"base_hp": BIG})
	var v = _rec(b)
	var bad := []
	for i in RAID.size():
		var k: String = RAID[i]
		if not View.ART.has(k):
			return "heroes.json에 %s 칸이 없다" % k
		var a: Dictionary = View.ART[k]
		if (k in FALLS) and not a.has("fall"):
			return "%s 칸에 fall이 없다" % k
		var c: float = a.c
		var e = b.spawn_enemy(k, Vector2i(6 + 4 * i, 10), STILL)
		var want := Rect2(a.x, a.fall, 2 * c, 2 * c) if k in FALLS else Rect2(a.x, a.idle, c, c)
		for case in [[1.0, 1.0], [1.75, 0.5]]:
			v.cuts = []
			v._corpse([e, case[0]])
			if v.cuts.size() != 1 or not v.cuts[0][1].is_equal_approx(want) or absf(v.cuts[0][2].a - case[1]) > 0.01:
				bad.append("%s %.2f초: %s(기대 %s · 알파 %s)" % [k, case[0], v.cuts, want, case[1]])
		b.enemies.erase(e)
	v.free()
	return check(bad.is_empty(), "%s" % [bad])
