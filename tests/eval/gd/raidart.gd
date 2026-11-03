extends "res://tests/eval/gd/lib.gd"
# 3라운드 고블린 그림: 묶음 ① 네 종(S172 2026-11-03 변경, I189 2026-11-03 변경)과 묶음 ②-a 세 종·사다리(S172·I189 2026-11-03 둘째 변경). lib.gd 머리의 계약에 더하는 API:
#   art/units/heroes.json 칸 {c, anchor, x, idle, walk, attack, fall, land_idle, land_walk} · HudBuild.icon(종류) -> AtlasTexture
#   BattleView: battle · ART · _body(몸, 번호, next) · _corpse([몸, 쓰러진 뒤 초]) · _region(텍스처, 대상, 원본, 색) · _shadow(자리, 반지름) · _seen
#     · _pline(가, 나, 색, 굵기) · _ladders() · tick(dt)
#   적 flying · cast(도화선 {id fuse, left, at}, 던지기 {id throw, left, at}, 사다리 내리기 {id ladder, left}) · throw.windup · col · ladder.windup
#   Battle.ladders(사다리 칸 → 공성탑) · castle(칸 → 성곽 조각) · area_of(구조물) -> Rect2i · cells_in(Rect2i) · build(종류, 칸) · base

const View := preload("res://src/ui/battle_view.gd")
const RAID := ["sapper", "ram", "catapult", "glider"]
const FALLS := ["sapper", "glider"]  # 누운 자세가 있는 종류. 망치·투석기는 정지 그림이 흐려진다
const FOUR := ["soldier", "archer", "engineer", "basic", "fast", "armored", "flying", "boss"]
const SLIMES := ["slimelet", "slime", "big_slime", "slime_king"]
const WOLVES := ["wolf", "leap_wolf", "night_wolf", "alpha_wolf"]
const SIEGE := ["siege_tower", "balloon", "airship"]  # 묶음 ②-a 세 종. 누운 자세가 없다
const LADDER := "res://art/castle/ladder.png"
const STILL := {"speed": 0, "sight": 0, "damage": 0}

# 그림 한 장·선·그림자를 그리는 대신 모으는 화면
class Rec extends "res://src/ui/battle_view.gd":
	var cuts := []  # [대상 사각형, 원본 사각형, 색, 텍스처 경로]
	var lines := []  # [가, 나]

	func _region(tex: Texture2D, dst: Rect2, src: Rect2, tint: Color) -> void:
		cuts.append([dst, src, tint, tex.resource_path if tex != null else ""])

	func _pline(a: Vector2i, b: Vector2i, _col: Color, _w := 1) -> void:
		lines.append([a, b])

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

# EV679 · I189: 아틀라스 468×15656(2026-11-03 둘째 변경), 네 종 칸은 늑대·슬라임 옆 열 오른쪽의 둘째 옆 열에서 용병·적 8종 구역 안의 빈자리
func ev679():
	var art := _art()
	var img: Image = load("res://art/units/heroes.png").get_image()
	if img.get_size() != Vector2i(468, 15656):
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

# 칸 a의 4행 정지·걷기·공격 칸 사각형(이름 → 사각형)
func _cells(a: Dictionary) -> Dictionary:
	var c: int = int(a.c)
	var x: int = int(a.get("x", 0))
	var cells := {}
	for r in 4:
		cells["idle%d" % r] = Rect2i(x, int(a.idle) + r * c, c, c)
		cells["walk0_%d" % r] = Rect2i(x, int(a.walk) + r * c, c, c)
		cells["walk1_%d" % r] = Rect2i(x + c, int(a.walk) + r * c, c, c)
		cells["attack%d" % r] = Rect2i(x, int(a.attack) + 2 * r * c, 2 * c, 2 * c)
	return cells

# 원본이 칸 a의 공격 칸(2c×2c, 공격 y부터 8c 안)인가
func _attack_cell(d, a: Dictionary) -> bool:
	return d != null and d[1].size.is_equal_approx(Vector2(2 * a.c, 2 * a.c)) and d[1].position.y >= a.attack and d[1].position.y < a.attack + 8 * a.c

# 원본이 c×c 칸(정지·걷기 한 칸)인가
func _small_cell(d, a: Dictionary) -> bool:
	return d != null and d[1].size.is_equal_approx(Vector2(a.c, a.c))

# 9행 성곽(성문 (12,9) 하나, 나머지 열은 성벽), 마을 0~8행, 거점 (12,2)(EV683 판의 성곽)
func _walled():
	var walls := []
	for x in 30:
		if x != 12:
			walls.append(Vector2i(x, 9))
	return battle({"size": Vector2i(30, 20), "base": Vector2i(12, 2), "base_hp": BIG, "spawns": [Vector2i(12, 19)],
		"village": Rect2i(0, 0, 30, 9), "castle": {"walls": walls, "gates": [Vector2i(12, 9)], "wall_hp": 300, "gate_hp": 150}})

# 성곽 없는 1라운드 판: 마을 0~8행, 거점 (12,2), 출현 지점 (12,19)(EV687 판)
func _town():
	return battle({"base": Vector2i(12, 2), "spawns": [Vector2i(12, 19)], "village": Rect2i(0, 0, 30, 9), "base_hp": BIG})

# secs초 동안 step(DT)마다 화면 시계도 돌리고 몸 x를 그린다. cond가 참이 되면 그 스텝에서 멈추고 true
func _drive(b, v, x, secs: float, cond := Callable()) -> bool:
	for i in int(round(secs / DT)):
		b.step(DT)
		v.tick(DT)
		_one(v, x)
		if cond.is_valid() and cond.call():
			return true
	return not cond.is_valid()

# EV702 · S172 2026-11-03 둘째 변경: 세 종 칸(4방향, x 있음, one·fall 없음), 크기, HUD 아이콘
func ev702():
	var art := _art()
	var img: Image = load("res://art/units/heroes.png").get_image()
	var whole := Rect2i(Vector2i.ZERO, img.get_size())
	var bad := []
	var used := {}
	for k in SIEGE + ["sapper"]:
		if not art.has(k):
			return "heroes.json에 %s 칸이 없다" % k
		var a: Dictionary = art[k]
		var cells := _cells(a)
		if k in SIEGE:
			if not a.has("x") or a.has("one") or a.has("fall"):
				bad.append("%s x %s · one %s · fall %s" % [k, a.get("x"), a.get("one"), a.get("fall")])
			for n in cells:
				if not whole.encloses(cells[n]):
					bad.append("%s %s %s가 그림 밖" % [k, n, cells[n]])
				elif _opaque(img, cells[n]) == 0:
					bad.append("%s %s 빈 칸" % [k, n])
			var t: AtlasTexture = load("res://src/ui/hud_build.gd").icon(k)
			if not t.region.has_area() or not Rect2(cells.idle0).encloses(t.region):
				bad.append("%s 아이콘 %s(칸 %s)" % [k, t.region, cells.idle0])
		if whole.encloses(cells.idle0):
			used[k] = img.get_region(cells.idle0).get_used_rect().size
	if used.size() != SIEGE.size() + 1:
		return "정지 남쪽 크기를 다 재지 못했다: %s · %s" % [used, bad]
	if used.siege_tower.y < 3 * used.sapper.y:
		bad.append("높이 siege_tower %d · sapper %d" % [used.siege_tower.y, used.sapper.y])
	if used.airship.y < 2 * used.balloon.y:
		bad.append("높이 airship %d · balloon %d" % [used.airship.y, used.balloon.y])
	return check(bad.is_empty(), "%s · 크기 %s" % [bad, used])

# EV703 · S172 2026-11-03 둘째 변경: 세 종은 동쪽으로 걸으면 걷기 동쪽 행, 멈추면 정지 동쪽 행
func ev703():
	var b = battle({"base_hp": BIG})
	var v = _rec(b)
	var bad := []
	for i in SIEGE.size():
		var k: String = SIEGE[i]
		if not View.ART.has(k):
			return "heroes.json에 %s 칸이 없다" % k
		var a: Dictionary = View.ART[k]
		var e = b.spawn_enemy(k, Vector2i(6 + 6 * i, 12), STILL)
		var msg := _east(v, e, a, "walk")
		if msg != "":
			bad.append(msg)
		var d = _one(v, e)
		var want := Rect2(a.x, a.idle + a.c, a.c, a.c)
		if d == null or not d[1].is_equal_approx(want):
			bad.append("%s 정지: %s(기대 %s)" % [k, d, want])
		b.enemies.erase(e)
	v.free()
	return check(bad.is_empty(), "%s" % [bad])

# EV704 · S172 2026-11-03 둘째 변경 ①: 공성탑은 사다리를 내리기 시작한 때부터 놓인 동안 성벽 열 쪽 공격 자세
func ev704():
	var b = _walled()
	var v = _rec(b)
	if not View.ART.has("siege_tower"):
		return "heroes.json에 siege_tower 칸이 없다"
	var a: Dictionary = View.ART.siege_tower
	var c: float = a.c
	var t = b.spawn_enemy("siege_tower", Vector2i(20, 11), STILL)
	_one(v, t)
	t.pos += Vector2.RIGHT
	_one(v, t)
	var col = b.castle.get(Vector2i(21, 9))
	if col == null:
		return "성벽 열 (21,9)가 없다"
	var bad := []
	var want := Rect2(a.x, a.attack + 2 * 2 * c, 2 * c, 2 * c)
	t.col = col
	for left in [1.9, 0.1]:
		t.cast = {"id": "ladder", "left": left}
		var d = _one(v, t)
		if d == null or not d[1].is_equal_approx(want):
			bad.append("내리기 left %.1f: %s(기대 %s)" % [left, d, want])
	t.cast = null
	for cell in b.cells_in(b.area_of(col)):
		b.ladders[cell] = t
	var laid = _one(v, t)
	if laid == null or not laid[1].is_equal_approx(want):
		bad.append("놓인 뒤: %s(기대 %s)" % [laid, want])
	b.ladders.clear()
	t.col = null
	var bare = _one(v, t)
	if not _small_cell(bare, a) or bare[1].position.y < a.idle or bare[1].position.y >= a.idle + 4 * c:
		bad.append("사다리 없음: %s(기대 정지 칸 y %s~)" % [bare, a.idle])
	v.free()
	return check(bad.is_empty(), "%s" % [bad])

# EV705 · S172 2026-11-03 둘째 변경 ②: 열기구는 폭탄이 터진 뒤, 비행선은 떨군 뒤 0.08~0.22초 공격 자세. 비행선 기본 공격에는 쓰지 않는다
func ev705():
	for k in ["balloon", "airship"]:
		if not View.ART.has(k):
			return "heroes.json에 %s 칸이 없다" % k
	var bad := []
	var b = _town()
	var house = b.build("house", Vector2i(11, 5))
	if house == null:
		return "집을 짓지 못했다"
	var v = _rec(b)
	var a: Dictionary = View.ART.balloon
	var e = b.spawn_enemy("balloon", Vector2i(12, 18), {"hp": BIG})
	if not _drive(b, v, e, 30.0, func(): return e.cast != null and e.cast.get("id") == "bomb"):
		return "30초 안에 폭탄 예고를 시작하지 않았다(자리 %s)" % e.pos
	_drive(b, v, e, 0.5)
	var during = _one(v, e)
	if not _small_cell(during, a):
		bad.append("열기구 예고 0.5초: %s" % [during])
	var h0: float = house.hp
	if not _drive(b, v, e, 3.0, func(): return e.cast == null):
		return "폭탄 예고가 끝나지 않았다(cast %s)" % [e.cast]
	if house.hp >= h0:
		bad.append("폭탄이 집을 치지 않았다(%s → %s)" % [h0, house.hp])
	_drive(b, v, e, 0.15)
	var hit = _one(v, e)
	if not _attack_cell(hit, a):
		bad.append("열기구 폭탄 0.15초 뒤: %s(기대 공격 칸 y %s~)" % [hit, a.attack])
	_drive(b, v, e, 0.35)
	var after = _one(v, e)
	if not _small_cell(after, a):
		bad.append("열기구 폭탄 0.5초 뒤: %s" % [after])
	v.free()
	var c = _town()
	var w = _rec(c)
	var p: Dictionary = View.ART.airship
	var s = c.spawn_enemy("airship", Vector2i(12, 18), {"hp": BIG})
	var basics := func(): return c.enemies.filter(func(x): return x.alive and x.kind == "basic")
	if not _drive(c, w, s, 40.0, func(): return not basics.call().is_empty()):
		return "40초 안에 비행선이 고블린을 떨구지 않았다(자리 %s · cast %s)" % [s.pos, s.cast]
	_drive(c, w, s, 0.15)
	var dropped = _one(w, s)
	if not _attack_cell(dropped, p):
		bad.append("비행선 투하 0.15초 뒤: %s(기대 공격 칸 y %s~)" % [dropped, p.attack])
	for x in basics.call():
		c.enemies.erase(x)
	var b0: float = c.base.hp
	if not _drive(c, w, s, 30.0, func(): return c.base.hp < b0):
		return "30초 안에 비행선이 거점을 치지 않았다(자리 %s)" % s.pos
	_drive(c, w, s, 0.15)
	var struck = _one(w, s)
	if not _small_cell(struck, p):
		bad.append("비행선 기본 공격 0.15초 뒤: %s" % [struck])
	w.free()
	return check(bad.is_empty(), "%s" % [bad])

# EV706 · S172 2026-11-03 둘째 변경 ③: 세 종은 누운 그림 없이 정지 남쪽 그림이 흐려진다. 열기구·비행선은 날던 자리
func ev706():
	var b = battle({"base_hp": BIG})
	var v = _rec(b)
	var bad := []
	for i in SIEGE.size():
		var k: String = SIEGE[i]
		if not View.ART.has(k):
			return "heroes.json에 %s 칸이 없다" % k
		var a: Dictionary = View.ART[k]
		var c: float = a.c
		var e = b.spawn_enemy(k, Vector2i(6 + 6 * i, 12), STILL)
		var alive = _one(v, e)
		var want := Rect2(a.x, a.idle, c, c)
		for case in [[1.0, 1.0], [1.75, 0.5]]:
			v.cuts = []
			v._corpse([e, case[0]])
			if v.cuts.size() != 1 or not v.cuts[0][1].is_equal_approx(want) or absf(v.cuts[0][2].a - case[1]) > 0.01:
				bad.append("%s %.2f초: %s(기대 %s · 알파 %s)" % [k, case[0], v.cuts, want, case[1]])
			elif e.flying and (alive == null or v.cuts[0][0].position.distance_to(alive[0].position) > 0.5):
				bad.append("%s %.2f초 자리 %s(살아 있을 때 %s)" % [k, case[0], v.cuts[0][0], alive])
		b.enemies.erase(e)
	v.free()
	return check(bad.is_empty(), "%s" % [bad])

# 모은 그림의 대상 사각형을 합친 사각형. 없으면 빈 사각형
func _union(cuts: Array) -> Rect2:
	if cuts.is_empty():
		return Rect2()
	var r: Rect2 = cuts[0][0]
	for k in cuts:
		r = r.merge(k[0])
	return r

# EV707 · S172 2026-11-03 둘째 변경 ④: 사다리는 선이 아니라 ladder.png 그림이고, 내리는 동안은 공성탑 쪽 끝에서 자란 길이만큼
func ev707():
	var b = _walled()
	var v = _rec(b)
	var t = b.spawn_enemy("siege_tower", Vector2i(20, 11), STILL)
	var col = b.castle.get(Vector2i(20, 9))
	if col == null:
		return "성벽 열 (20,9)가 없다"
	var area: Rect2i = b.area_of(col)
	var full: float = area.size.y * CELL_PX
	var mid: float = (area.position.x + area.size.x / 2.0) * CELL_PX
	var bad := []
	t.col = col
	for cell in b.cells_in(area):
		b.ladders[cell] = t
	v.cuts = []
	v.lines = []
	v._ladders()
	var r := _union(v.cuts)
	if not v.lines.is_empty():
		bad.append("놓인 사다리에 선 %d개" % v.lines.size())
	if v.cuts.is_empty() or v.cuts.any(func(k): return k[3] != LADDER):
		bad.append("놓인 사다리 그림: %s" % [v.cuts.map(func(k): return k[3])])
	elif absf(r.size.y - full) > 1.0 or absf(r.get_center().x - mid) > 2.0:
		bad.append("놓인 사다리 %s(기대 높이 %s · 가운데 x %s)" % [r, full, mid])
	b.ladders.clear()
	t.cast = {"id": "ladder", "left": t.ladder.windup * 0.5}
	v.cuts = []
	v.lines = []
	v._ladders()
	var h := _union(v.cuts)
	if not v.lines.is_empty() or v.cuts.is_empty() or v.cuts.any(func(k): return k[3] != LADDER):
		bad.append("내리는 사다리: 선 %d · 그림 %s" % [v.lines.size(), v.cuts.map(func(k): return k[3])])
	elif absf(h.size.y - full / 2.0) > 1.0 or absf(h.end.y - area.end.y * CELL_PX) > 1.0:
		bad.append("내리는 사다리 %s(기대 높이 %s · 아래 끝 %s)" % [h, full / 2.0, area.end.y * CELL_PX])
	v.free()
	return check(bad.is_empty(), "%s" % [bad])

# EV708 · I189 2026-11-03 둘째 변경: 세 종 칸은 둘째 옆 열 오른쪽의 셋째 옆 열에서 용병·적 8종 구역 안의 빈자리
func ev708():
	var art := _art()
	var top := INF
	var bottom := -INF
	var taken := []
	for k in FOUR:
		var a: Dictionary = art[k]
		top = minf(top, a.idle)
		bottom = maxf(bottom, a.fall + 2 * a.c)
		taken.append_array(_rects(a))
	for k in SLIMES + WOLVES:
		taken.append_array(_rects(art[k]))
	var right := 0
	for k in RAID:
		for r in _rects(art[k]):
			right = maxi(right, r.end.x)
			taken.append(r)
	var bad := []
	var xs := {}
	for k in SIEGE:
		if not art.has(k) or not art[k].has("x") or art[k].has("one"):
			return "heroes.json에 %s 옆 열 4방향 칸이 없다" % k
		xs[int(art[k].x)] = true
		if int(art[k].x) < right:
			bad.append("%s x %d < 둘째 옆 열 오른쪽 %d" % [k, art[k].x, right])
		for r in _rects(art[k]):
			if r.position.y < top or r.end.y > bottom:
				bad.append("%s %s가 구역 y %d~%d 밖" % [k, r, top, bottom])
			for o in taken:
				if r.intersects(o):
					bad.append("%s %s가 %s와 겹침" % [k, r, o])
			taken.append(r)
	if xs.size() != 1:
		bad.append("세 종 x가 여럿: %s" % [xs.keys()])
	return check(bad.is_empty(), "%s" % [bad])
