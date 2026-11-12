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

# EV679 · I189: 아틀라스 868×15656(2026-11-03 셋째 변경, 폭은 새 용병 그림 I296으로 2026-11-12에 늘었다), 네 종 칸은 늑대·슬라임 옆 열 오른쪽의 둘째 옆 열에서 용병·적 8종 구역 안의 빈자리
func ev679():
	var art := _art()
	var img: Image = load("res://art/units/heroes.png").get_image()
	if img.get_size() != Vector2i(868, 15656):
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

# 9~11행이 두께 3줄 성곽(성벽 열 1×3, 성문 문루 (12~14, 9~11)), 마을 0~8행, 거점 (12,2)(thick 스위트와 같은 성곽)
func _thick():
	var walls := []
	for x in 30:
		if x < 12 or x > 14:
			walls.append(Vector2i(x, 11))
	return battle({"size": Vector2i(30, 24), "base": Vector2i(12, 2), "base_hp": BIG, "spawns": [Vector2i(12, 23)], "village": Rect2i(0, 0, 30, 9),
		"castle": {"walls": walls, "gates": [Vector2i(12, 11)], "wall_hp": 300, "gate_hp": 150, "wall_size": Vector2i(1, 3), "gate_size": Vector2i(3, 3)}})

# EV707 · S172 2026-11-03 넷째 변경 ①: 사다리는 ladder.png 그림이고, 성벽 위 높이로 올려 열의 먼 끝에서 공성탑 꼭대기까지. 내리는 동안은 공성탑 쪽 끝에서 자란 길이만큼
func ev707():
	var b = _thick()
	var v = _rec(b)
	var t = b.spawn_enemy("siege_tower", Vector2i(20, 12), STILL)
	var col = b.castle.get(Vector2i(20, 11))
	if col == null:
		return "성벽 열 (20,11)가 없다"
	if not v.has_method("_ladder"):
		v.free()
		return "BattleView에 _ladder(탑, 자란 비율)가 없다"
	var area: Rect2i = b.area_of(col)
	var mid: float = (area.position.x + area.size.x / 2.0) * CELL_PX
	var top: float = area.position.y * CELL_PX - (3 + View.WALL_H - 8 + View.rise_at(b, col.cell))
	var bottom: float = v._spot(t).y - 59
	var bad := []
	t.col = col
	for cell in b.cells_in(area):
		b.ladders[cell] = t
	for case in [[1.0, bottom - top], [0.5, (bottom - top) / 2.0]]:
		v.cuts = []
		v.lines = []
		v._ladder(t, case[0])
		var r := _union(v.cuts)
		if not v.lines.is_empty() or v.cuts.is_empty() or v.cuts.any(func(k): return k[3] != LADDER):
			bad.append("자란 비율 %s: 선 %d · 그림 %s" % [case[0], v.lines.size(), v.cuts.map(func(k): return k[3])])
		elif absf(r.end.y - bottom) > 1.0 or absf(r.size.y - case[1]) > 1.0 or absf(r.get_center().x - mid) > 2.0:
			bad.append("자란 비율 %s: %s(기대 아랫변 %s · 높이 %s · 가운데 x %s)" % [case[0], r, bottom, case[1], mid])
		elif case[0] == 1.0 and absf(r.position.y - top) > 1.0:
			bad.append("놓인 사다리 윗변 %s(기대 %s)" % [r.position.y, top])
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

const WAR := {"idle": 1, "walk": 2, "cannon": 2, "mgun": 3, "grab": 3, "slam": 2}  # 전쟁 기계 칸의 자세 → 열 수(S172 2026-11-03 셋째 변경)

# 전쟁 기계 칸에 WAR 자세가 다 있으면 그 칸, 아니면 null
func _war_art():
	if not View.ART.has("war_machine"):
		return null
	var a: Dictionary = View.ART.war_machine
	for n in WAR:
		if not a.has(n):
			return null
	return a

# 몸 x의 원본이 want(±0.01)가 아니면 틀린 글을 bad에 더한다
func _expect(bad: Array, what: String, d, want: Rect2) -> void:
	if d == null or not d[1].is_equal_approx(want):
		bad.append("%s: %s(기대 %s)" % [what, d, want])

# 성곽 없는 판의 (10,10)에 움직이지도 치지도 않는 전쟁 기계를 두고 한 번 그린 [판, 기록 화면, 기계]
func _machine() -> Array:
	var b = battle({"base_hp": BIG})
	var v = _rec(b)
	var e = b.spawn_enemy("war_machine", Vector2i(10, 10), STILL)
	_one(v, e)
	return [b, v, e]

func _trace_of(e, slot: String, at: Vector2, age: float) -> Dictionary:
	return {"hero": e, "slot": slot, "aim": null, "at": at, "radius": 1.5, "hits": [], "marked": false, "age": age}

# EV710 · S172 2026-11-03 셋째 변경: 전쟁 기계 칸(4방향, x 있음, one·fall·attack 없음)과 여섯 자세의 열, HUD 아이콘
func ev710():
	var art := _art()
	if not art.has("war_machine"):
		return "heroes.json에 war_machine 칸이 없다"
	var a: Dictionary = art.war_machine
	var img: Image = load("res://art/units/heroes.png").get_image()
	var whole := Rect2i(Vector2i.ZERO, img.get_size())
	var bad := []
	if not a.has("x") or a.has("one") or a.has("fall") or a.has("attack"):
		bad.append("x %s · one %s · fall %s · attack %s" % [a.get("x"), a.get("one"), a.get("fall"), a.get("attack")])
	var c: int = int(a.c)
	var x: int = int(a.get("x", 0))
	for n in WAR:
		if not a.has(n):
			bad.append("%s 자세가 없다" % n)
			continue
		for r in 4:
			for k in WAR[n]:
				var cell := Rect2i(x + k * c, int(a[n]) + r * c, c, c)
				if not whole.encloses(cell):
					bad.append("%s %d열 %d행 %s가 그림 밖" % [n, k, r, cell])
				elif _opaque(img, cell) == 0:
					bad.append("%s %d열 %d행 빈 칸" % [n, k, r])
	var t: AtlasTexture = load("res://src/ui/hud_build.gd").icon("war_machine")
	var south := Rect2(x, a.get("idle", 0), c, c)
	if not t.region.has_area() or not south.encloses(t.region):
		bad.append("아이콘 %s(칸 %s)" % [t.region, south])
	return check(bad.is_empty(), "%s" % [bad])

# EV711 · S172 2026-11-03 셋째 변경 ④: 걷기·정지 동쪽 행, 성문을 친 기본 공격은 내려찍기 정점(북쪽 행)
func ev711():
	var a = _war_art()
	if a == null:
		return "heroes.json에 war_machine 칸(%s)이 없다" % [WAR.keys()]
	var c: float = a.c
	var bad := []
	var b = battle({"base_hp": BIG})
	var v = _rec(b)
	var e = b.spawn_enemy("war_machine", Vector2i(10, 12), STILL)
	var msg = _east(v, e, a, "walk")
	if msg != "":
		bad.append(msg)
	_expect(bad, "정지", _one(v, e), Rect2(a.x, a.idle + c, c, c))
	v.free()
	var w = _walled()
	var u = _rec(w)
	var m = w.spawn_enemy("war_machine", Vector2i(12, 12), {"hp": BIG, "skills": {}})
	var gate = w.castle.get(Vector2i(12, 9))
	if gate == null:
		return "성문 (12,9)가 없다"
	var g0: float = gate.hp
	var step := 1.0 / 60.0
	var hit := false
	for i in 20 * 60:
		w.step(step)
		u.tick(step)
		_one(u, m)
		if gate.hp < g0:
			hit = true
			break
	if not hit:
		return "20초 안에 성문을 치지 않았다(자리 %s)" % m.pos
	for i in 9:
		w.step(step)
		u.tick(step)
		_one(u, m)
	_expect(bad, "성문을 친 뒤 0.15초", _one(u, m), Rect2(a.x + c, a.slam + 2 * c, c, c))
	for i in 21:
		w.step(step)
		u.tick(step)
		_one(u, m)
	var after = _one(u, m)
	if not _small_cell(after, a) or after[1].position.y < a.idle or after[1].position.y >= a.idle + 4 * c:
		bad.append("성문을 친 뒤 0.5초: %s(기대 정지 칸 y %s~)" % [after, a.idle])
	u.free()
	return check(bad.is_empty(), "%s" % [bad])

# EV712 · S172 2026-11-03 셋째 변경 ①②③: 대포는 원 가운데 쪽을 보고, 예고 끝 0.4초에 조준(2px 듦), 발동 뒤 발사
func ev712():
	var a = _war_art()
	if a == null:
		return "heroes.json에 war_machine 칸(%s)이 없다" % [WAR.keys()]
	var c: float = a.c
	var s := _machine()
	var b = s[0]
	var v = s[1]
	var e = s[2]
	var bad := []
	var at := Vector2(10, 5)
	e.cast = {"id": "cannon", "left": 1.0, "at": at}
	var early = _one(v, e)
	_expect(bad, "대포 예고 left 1.0", early, Rect2(a.x, a.idle + 2 * c, c, c))
	e.cast = {"id": "cannon", "left": 0.3, "at": at}
	var late = _one(v, e)
	_expect(bad, "대포 예고 left 0.3", late, Rect2(a.x, a.cannon + 2 * c, c, c))
	if early != null and late != null and absf(late[0].position.y - (early[0].position.y - 2.0)) > 0.01:
		bad.append("대포 예고 들어 올림: y %s → %s" % [early[0].position.y, late[0].position.y])
	e.cast = null
	b.traces.append(_trace_of(e, "cannon", at, 0.05))
	_expect(bad, "대포 흔적 0.05초", _one(v, e), Rect2(a.x + c, a.cannon + 2 * c, c, c))
	v.free()
	return check(bad.is_empty(), "%s" % [bad])

# EV713 · S172 2026-11-03 셋째 변경 ①②: 집어 던지기 벌림 → 집음 → 놓음, 내려찍기 듦 → 찍음(남쪽 행)
func ev713():
	var a = _war_art()
	if a == null:
		return "heroes.json에 war_machine 칸(%s)이 없다" % [WAR.keys()]
	var c: float = a.c
	var s := _machine()
	var b = s[0]
	var v = s[1]
	var e = s[2]
	var bad := []
	e.cast = {"id": "grab", "left": 0.3}
	_expect(bad, "집어 던지기 예고", _one(v, e), Rect2(a.x, a.grab, c, c))
	e.cast = null
	for k in [[0.05, 1], [0.2, 2]]:
		b.traces.clear()
		b.traces.append(_trace_of(e, "grab", e.pos, k[0]))
		_expect(bad, "집어 던지기 흔적 %s초" % k[0], _one(v, e), Rect2(a.x + k[1] * c, a.grab, c, c))
	b.traces.clear()
	b.traces.append(_trace_of(e, "grab", e.pos, 0.35))
	var gone = _one(v, e)
	if gone == null or Rect2(a.x, a.grab, 3 * c, 4 * c).encloses(gone[1]):
		bad.append("집어 던지기 흔적 0.35초: %s(기대 grab 띠 밖)" % [gone])
	b.traces.clear()
	e.cast = {"id": "slam", "left": 0.3}
	_expect(bad, "내려찍기 예고", _one(v, e), Rect2(a.x, a.slam, c, c))
	e.cast = null
	b.traces.append(_trace_of(e, "slam", e.pos, 0.05))
	_expect(bad, "내려찍기 흔적 0.05초", _one(v, e), Rect2(a.x + c, a.slam, c, c))
	v.free()
	return check(bad.is_empty(), "%s" % [bad])

# EV714 · S172 2026-11-03 셋째 변경 ①③: 기관총 예고 끝은 가운데, 발사 동안은 총구 방향에 따라 왼·가운데·오른쪽(북쪽 행)
func ev714():
	var a = _war_art()
	if a == null:
		return "heroes.json에 war_machine 칸(%s)이 없다" % [WAR.keys()]
	var c: float = a.c
	var s := _machine()
	var v = s[1]
	var e = s[2]
	var bad := []
	var north := -PI / 2.0
	e.cast = {"id": "mgun", "left": 0.3, "dir": north}
	_expect(bad, "기관총 예고", _one(v, e), Rect2(a.x + c, a.mgun + 2 * c, c, c))
	var fire: float = e.skills.mgun.fire
	for k in 3:
		var t: float = [0.0, fire / 4.0, fire / 2.0][k]
		e.cast = {"id": "mgun", "fire": true, "dir": north, "shot": 0, "left": fire - t}
		_expect(bad, "기관총 발사 %s초" % t, _one(v, e), Rect2(a.x + k * c, a.mgun + 2 * c, c, c))
	v.free()
	return check(bad.is_empty(), "%s" % [bad])

# EV715 · S172 2026-11-03 셋째 변경 ⑤: 전쟁 기계는 누운 그림 없이 정지 남쪽 그림이 흐려진다
func ev715():
	if not View.ART.has("war_machine"):
		return "heroes.json에 war_machine 칸이 없다"
	var a: Dictionary = View.ART.war_machine
	var c: float = a.c
	var b = battle({"base_hp": BIG})
	var v = _rec(b)
	var e = b.spawn_enemy("war_machine", Vector2i(10, 12), STILL)
	var bad := []
	var want := Rect2(a.get("x", 0), a.idle, c, c)
	for case in [[1.0, 1.0], [1.75, 0.5]]:
		v.cuts = []
		v._corpse([e, case[0]])
		if v.cuts.size() != 1 or not v.cuts[0][1].is_equal_approx(want) or absf(v.cuts[0][2].a - case[1]) > 0.01:
			bad.append("%.2f초: %s(기대 %s · 알파 %s)" % [case[0], v.cuts, want, case[1]])
	v.free()
	return check(bad.is_empty(), "%s" % [bad])

# EV716 · I189 2026-11-03 셋째 변경: 전쟁 기계 칸은 셋째 옆 열 오른쪽의 넷째 옆 열에서 용병·적 8종 구역 안의 빈자리
func ev716():
	var art := _art()
	if not art.has("war_machine") or not art.war_machine.has("x"):
		return "heroes.json에 war_machine 옆 열 칸이 없다"
	var top := INF
	var bottom := -INF
	var taken := []
	for k in FOUR:
		var a: Dictionary = art[k]
		top = minf(top, a.idle)
		bottom = maxf(bottom, a.fall + 2 * a.c)
		taken.append_array(_rects(a))
	for k in SLIMES + WOLVES + RAID:
		taken.append_array(_rects(art[k]))
	var right := 0
	for k in SIEGE:
		for r in _rects(art[k]):
			right = maxi(right, r.end.x)
			taken.append(r)
	var m: Dictionary = art.war_machine
	var c: int = int(m.c)
	var bad := []
	if int(m.x) < right:
		bad.append("x %d < 셋째 옆 열 오른쪽 %d" % [m.x, right])
	for n in WAR:
		if not m.has(n):
			bad.append("%s 자세가 없다" % n)
			continue
		var r := Rect2i(int(m.x), int(m[n]), WAR[n] * c, 4 * c)
		if r.position.y < top or r.end.y > bottom:
			bad.append("%s %s가 구역 y %d~%d 밖" % [n, r, top, bottom])
		for o in taken:
			if r.intersects(o):
				bad.append("%s %s가 %s와 겹침" % [n, r, o])
		taken.append(r)
	return check(bad.is_empty(), "%s" % [bad])

# 쓰러진 몸·시설·몸통을 그리는 대신 차례를 모으는 화면. 발밑 표시·주민·소품·성곽 조각은 그리지 않는다
class Order extends Rec:
	var order := []  # [무엇, 대상]

	func _corpse(d: Array, _tint := Color.WHITE) -> void:
		order.append(["corpse", d[0]])

	func _facility(s, _tint := Color.WHITE) -> void:
		order.append(["facility", s])

	func _body(x, _i: int, _next: Dictionary, _tint := Color.WHITE, _flash := true) -> void:
		order.append(["body", x])

	func _feet_mark(_x, _i: int) -> void:
		pass

	func _folk_body(_x, _now: float) -> void:
		pass

	func _prop(_p: Array, _now: float) -> void:
		pass

	func _wall_piece(b, front: int) -> void:
		order.append(["wall%d" % front, b])  # wall0 몸체, wall1 앞층

	func _ladder(t, _grow: float) -> void:
		order.append(["ladder", t])

# order에서 [무엇, 대상]이 처음 나온 자리와 나온 수
func _seen_at(order: Array, what: String, x) -> Array:
	var at := -1
	var n := 0
	for i in order.size():
		if order[i][0] == what and is_same(order[i][1], x):
			n += 1
			if at < 0:
				at = i
	return [at, n]

# EV717 · S180 2026-11-03 변경: 날던 자리의 쓰러진 하늘 적은 나는 몸의 층(시설·땅 몸 위), 땅의 쓰러진 몸은 그대로 모든 몸 아래
func ev717():
	var b = _town()
	var house = b.build("house", Vector2i(11, 5))
	if house == null:
		return "집을 짓지 못했다"
	var balloon = b.spawn_enemy("balloon", Vector2i(11, 5), STILL)
	var goblin = b.spawn_enemy("basic", Vector2i(13, 5), STILL)
	b.damage(balloon, BIG * 10.0)
	b.damage(goblin, BIG * 10.0)
	run(b, 0.1)
	var soldier = b.place_merc("soldier", Vector2i(11, 7), STILL)
	if soldier == null:
		return "병사를 세우지 못했다"
	var v = Order.new()
	v.battle = b
	v._foes = []
	v._bodies()
	var o: Array = v.order
	v.free()
	var air := _seen_at(o, "corpse", balloon)
	var ground := _seen_at(o, "corpse", goblin)
	var fac := _seen_at(o, "facility", house)
	var man := _seen_at(o, "body", soldier)
	var bad := []
	if air[1] != 1 or ground[1] != 1 or fac[0] < 0 or man[0] < 0:
		return "그린 수: 열기구 %s · basic %s · 집 %s · 병사 %s" % [air, ground, fac, man]
	if air[0] < fac[0] or air[0] < man[0]:
		bad.append("열기구 시체 %d번째 · 집 %d · 병사 %d" % [air[0], fac[0], man[0]])
	if ground[0] > fac[0]:
		bad.append("basic 시체 %d번째 · 집 %d" % [ground[0], fac[0]])
	return check(bad.is_empty(), "%s" % [bad])

# EV718 · S172 2026-11-03 넷째 변경 ①: 사다리는 몸 층에서 그 성벽 열 몸체 다음, 성벽 위 몸·공성탑 전
func ev718():
	var b = _thick()
	var t = b.spawn_enemy("siege_tower", Vector2i(20, 12), STILL)
	var col = b.castle.get(Vector2i(20, 11))
	if col == null:
		return "성벽 열 (20,11)가 없다"
	t.col = col
	for cell in b.cells_in(b.area_of(col)):
		b.ladders[cell] = t
	var g = b.spawn_enemy("basic", Vector2i(20, 10), STILL)
	g.on_wall = true
	var v = Order.new()
	v.battle = b
	v._foes = [t, g]
	v._bodies()
	var o: Array = v.order
	v.free()
	var lad := _seen_at(o, "ladder", t)
	var wall := _seen_at(o, "wall0", col)
	var man := _seen_at(o, "body", g)
	var tower := _seen_at(o, "body", t)
	if lad[1] != 1 or wall[0] < 0 or man[0] < 0 or tower[0] < 0:
		return "그린 수: 사다리 %s · 성벽 몸체 %s · basic %s · 공성탑 %s" % [lad, wall, man, tower]
	return check(lad[0] > wall[0] and lad[0] < man[0] and lad[0] < tower[0], "차례: 사다리 %d · 성벽 몸체 %d · basic %d · 공성탑 %d" % [lad[0], wall[0], man[0], tower[0]])

# EV719 · S172 2026-11-03 넷째 변경 ②: 열기구 투하 자세의 떨어지는 폭탄은 2배 크기에 도화선 불꽃
func ev719():
	var art := _art()
	if not art.has("balloon"):
		return "heroes.json에 balloon 칸이 없다"
	var a: Dictionary = art.balloon
	var img: Image = load("res://art/units/heroes.png").get_image()
	var c: int = int(a.c)
	var x: int = int(a.x)
	var ay: int = int(a.anchor[1])
	var bad := []
	for row in [0, 2]:  # 남·북(4방향 시트 행 S·E·N·W)
		var idle := img.get_region(Rect2i(x, int(a.idle) + row * c, c, c))
		var below: int = idle.get_used_rect().end.y - ay  # 정지 그림 맨 아랫줄이 발밑 아래로 내려간 거리
		var att := img.get_region(Rect2i(x, int(a.attack) + row * 2 * c, 2 * c, 2 * c))
		var foot: int = ay + c / 2
		var n := 0
		var red := 0.0
		for yy in 2 * c:
			for xx in 2 * c:
				var p := att.get_pixel(xx, yy)
				if p.a > 0.0 and yy - foot > below + 2:
					n += 1
					red = maxf(red, p.r8)
		if n < 25 or red < 200:
			bad.append("행 %d: 아래 픽셀 %d · 가장 큰 R %d" % [row, n, red])
	return check(bad.is_empty(), "%s" % [bad])

# EV727 · S172 2026-11-03 셋째 변경 ②③: 스킬 시트 정점 열을 다 보인 뒤 흔적이 아직 남은 동안에도 전쟁 기계를 그린다. 흔적이 없을 때와 같은 한 장이다
func ev727():
	var a = _war_art()
	if a == null:
		return "heroes.json에 war_machine 칸(%s)이 없다" % [WAR.keys()]
	var s := _machine()
	var b = s[0]
	var v = s[1]
	var e = s[2]
	var want = _one(v, e)
	var bad := []
	for slot in ["cannon", "mgun", "slam"]:
		b.traces.clear()
		b.traces.append(_trace_of(e, slot, e.pos + Vector2(0, 3), View.SLAM_POSE * 1.5))  # 자세 시간(SLAM_POSE × 정점 열 1개)을 지났고 흔적 창(× 2) 안
		var got = _one(v, e)
		if want == null or got == null or not got[0].is_equal_approx(want[0]) or not got[1].is_equal_approx(want[1]):
			bad.append("%s 흔적 %s초: %s(기대 %s)" % [slot, View.SLAM_POSE * 1.5, got, want])
	v.free()
	return check(want != null and bad.is_empty(), "%s" % [bad])

const CHIEF := {"idle": 1, "walk": 2, "rage_idle": 1, "rage_walk": 2, "cleave": 2, "charge": 2, "fling": 2, "bombs": 2, "leap": 2}  # 고블린 대장 칸의 c×c 자세 → 열 수(S172 2026-11-05 변경). 공격·누운 자세는 2배 칸
const NO_CHIEF := "heroes.json에 chief 칸(%s·attack·fall)이 없다"

# 대장 칸에 CHIEF 자세와 공격·누운 자세가 다 있으면 그 칸, 아니면 null
func _chief_art():
	if not View.ART.has("chief"):
		return null
	var a: Dictionary = View.ART.chief
	for n in CHIEF.keys() + ["attack", "fall"]:
		if not a.has(n):
			return null
	return a

# 성곽 없는 판의 (10,10)에 움직이지도 치지도 않는 대장을 두고 한 번 그린 [판, 기록 화면, 대장]
func _chief() -> Array:
	var b = battle({"base_hp": BIG})
	var v = _rec(b)
	var e = b.spawn_enemy("chief", Vector2i(10, 10), STILL)
	_one(v, e)
	return [b, v, e]

func _chief_trace(e, slot: String, at: Vector2, age: float, more := {}) -> Dictionary:
	var t := {"hero": e, "slot": slot, "aim": null, "at": at, "radius": 0.0, "hits": [], "marked": false, "age": age}
	t.merge(more, true)
	return t

# EV756 · S172 2026-11-05 변경: 대장 칸(4방향, x·fall 있음, one·slam 없음)과 자세 열, 잔해 칸, HUD 아이콘
func ev756():
	var art := _art()
	if not art.has("chief") or not art.has("wreck"):
		return "heroes.json에 chief·wreck 칸이 없다"
	var a: Dictionary = art.chief
	var img: Image = load("res://art/units/heroes.png").get_image()
	var whole := Rect2i(Vector2i.ZERO, img.get_size())
	var bad := []
	if not a.has("x") or not a.has("fall") or a.has("one") or a.has("slam"):
		bad.append("x %s · fall %s · one %s · slam %s" % [a.get("x"), a.get("fall"), a.get("one"), a.get("slam")])
	var c: int = int(a.c)
	var x: int = int(a.get("x", 0))
	var cells := []  # [이름, 칸]
	for n in CHIEF:
		if not a.has(n):
			bad.append("%s 자세가 없다" % n)
			continue
		for r in 4:
			for k in CHIEF[n]:
				cells.append(["%s %d열 %d행" % [n, k, r], Rect2i(x + k * c, int(a[n]) + r * c, c, c)])
	if a.has("attack"):
		for r in 4:
			cells.append(["attack %d행" % r, Rect2i(x, int(a.attack) + 2 * r * c, 2 * c, 2 * c)])
	if a.has("fall"):
		cells.append(["fall", Rect2i(x, int(a.fall), 2 * c, 2 * c)])
	var w: Dictionary = art.wreck
	var wc: int = int(w.c)
	if not w.has("x") or not w.has("idle"):
		bad.append("wreck x %s · idle %s" % [w.get("x"), w.get("idle")])
	for r in 4:
		cells.append(["wreck %d행" % r, Rect2i(int(w.get("x", 0)), int(w.get("idle", 0)) + r * wc, wc, wc)])
	for d in cells:
		if not whole.encloses(d[1]):
			bad.append("%s %s가 그림 밖" % d)
		elif _opaque(img, d[1]) == 0:
			bad.append("%s 빈 칸" % d[0])
	var t: AtlasTexture = load("res://src/ui/hud_build.gd").icon("chief")
	var south := Rect2(x, a.get("idle", 0), c, c)
	if t == null or not t.region.has_area() or not south.encloses(t.region):
		bad.append("아이콘 %s(칸 %s)" % [t.region if t else null, south])
	return check(bad.is_empty(), "%s" % [bad])

# EV757 · S172 2026-11-05 변경 ①④: 걷기·정지 동쪽 행, 분노면 망토 없는 걷기·정지, 병사를 친 기본 공격은 공격 칸
func ev757():
	var a = _chief_art()
	if a == null:
		return NO_CHIEF % [CHIEF.keys()]
	var c: float = a.c
	var bad := []
	var b = battle({"base_hp": BIG})
	var v = _rec(b)
	var e = b.spawn_enemy("chief", Vector2i(10, 12), STILL)
	var msg = _east(v, e, a, "walk")
	if msg != "":
		bad.append(msg)
	_expect(bad, "정지", _one(v, e), Rect2(a.x, a.idle + c, c, c))
	e.hp = e.max_hp * 0.2
	if not b.raging(e):
		bad.append("체력 20%에 분노가 아니다")
	msg = _east(v, e, a, "rage_walk")
	if msg != "":
		bad.append(msg)
	_expect(bad, "분노 정지", _one(v, e), Rect2(a.x, a.rage_idle + c, c, c))
	v.free()
	var w = battle({"base_hp": BIG})
	var u = _rec(w)
	var m = w.spawn_enemy("chief", Vector2i(10, 12), {"hp": BIG, "skills": {}, "speed": 0})
	var s = w.place_merc("soldier", Vector2i(10, 11), {"hp": BIG, "speed": 0})
	if s == null:
		u.free()
		return "병사를 세우지 못했다"
	var h0: float = s.hp
	var step := 1.0 / 60.0
	var hit := false
	for i in 20 * 60:
		w.step(step)
		u.tick(step)
		_one(u, m)
		if s.hp < h0:
			hit = true
			break
	if not hit:
		u.free()
		return "20초 안에 병사를 치지 않았다(자리 %s)" % m.pos
	for i in 9:
		w.step(step)
		u.tick(step)
		_one(u, m)
	var d = _one(u, m)
	if not _attack_cell(d, a):
		bad.append("병사를 친 뒤 0.15초: %s(기대 공격 칸 y %s~)" % [d, a.attack])
	u.free()
	return check(bad.is_empty(), "%s" % [bad])

# EV758 · S172 2026-11-05 변경 ①②: 철퇴 젖힘(2px 듦) → 쓸어 멈춤(북쪽 행), 돌진 웅크림 → 내닫음(동쪽 행)
func ev758():
	var a = _chief_art()
	if a == null:
		return NO_CHIEF % [CHIEF.keys()]
	var c: float = a.c
	var s := _chief()
	var b = s[0]
	var v = s[1]
	var e = s[2]
	var bad := []
	var north := -PI / 2.0
	e.cast = {"id": "cleave", "left": 1.0, "dir": north}
	var early = _one(v, e)
	_expect(bad, "철퇴 예고 left 1.0", early, Rect2(a.x, a.idle + 2 * c, c, c))
	e.cast = {"id": "cleave", "left": 0.3, "dir": north}
	var late = _one(v, e)
	_expect(bad, "철퇴 예고 left 0.3", late, Rect2(a.x, a.cleave + 2 * c, c, c))
	if early != null and late != null and absf(late[0].position.y - (early[0].position.y - 2.0)) > 0.01:
		bad.append("철퇴 예고 들어 올림: y %s → %s" % [early[0].position.y, late[0].position.y])
	e.cast = null
	b.traces.append(_chief_trace(e, "cleave", Vector2(10, 10), 0.05, {"dir": north, "range": 2.5, "arc": 120.0}))
	_expect(bad, "철퇴 흔적 0.05초", _one(v, e), Rect2(a.x + c, a.cleave + 2 * c, c, c))
	b.traces.clear()
	e.cast = {"id": "charge", "left": 0.3, "dir": 0.0, "to": Vector2(16, 10)}
	_expect(bad, "돌진 예고 left 0.3", _one(v, e), Rect2(a.x, a.charge + c, c, c))
	e.cast = null
	b.traces.append(_chief_trace(e, "charge", Vector2(10, 10), 0.05, {"from": Vector2(4, 10), "width": 1.0}))
	_expect(bad, "돌진 흔적 0.05초", _one(v, e), Rect2(a.x + c, a.charge + c, c, c))
	v.free()
	return check(bad.is_empty(), "%s" % [bad])

# EV759 · S172 2026-11-05 변경 ①②: 폭탄 듦 → 내던짐(남쪽 행), 집게 던지기 예고는 정지 그림(2px 듦), 발동 뒤 집음 → 치켜듦
func ev759():
	var a = _chief_art()
	if a == null:
		return NO_CHIEF % [CHIEF.keys()]
	var c: float = a.c
	var s := _chief()
	var b = s[0]
	var v = s[1]
	var e = s[2]
	var bad := []
	e.cast = {"id": "bombs", "left": 0.3, "spots": [Vector2(10, 6)]}
	_expect(bad, "폭탄 예고 left 0.3", _one(v, e), Rect2(a.x, a.bombs, c, c))
	e.cast = null
	b.traces.append(_chief_trace(e, "bombs", Vector2(10, 6), 0.05, {"radius": 0.8}))
	_expect(bad, "폭탄 흔적 0.05초", _one(v, e), Rect2(a.x + c, a.bombs, c, c))
	b.traces.clear()
	e.cast = {"id": "fling", "left": 1.0}
	var early = _one(v, e)
	_expect(bad, "집게 던지기 예고 left 1.0", early, Rect2(a.x, a.idle, c, c))
	e.cast = {"id": "fling", "left": 0.3}
	var late = _one(v, e)
	_expect(bad, "집게 던지기 예고 left 0.3", late, Rect2(a.x, a.idle, c, c))
	if early != null and late != null and absf(late[0].position.y - (early[0].position.y - 2.0)) > 0.01:
		bad.append("집게 던지기 예고 들어 올림: y %s → %s" % [early[0].position.y, late[0].position.y])
	e.cast = null
	for k in [[0.05, 0], [0.2, 1]]:
		b.traces.clear()
		b.traces.append(_chief_trace(e, "fling", e.pos, k[0]))
		_expect(bad, "집게 던지기 흔적 %s초" % k[0], _one(v, e), Rect2(a.x + k[1] * c, a.fling, c, c))
	b.traces.clear()
	b.traces.append(_chief_trace(e, "fling", e.pos, 0.35))
	var gone = _one(v, e)
	if gone == null or Rect2(a.x, a.fling, 2 * c, 4 * c).encloses(gone[1]):
		bad.append("집게 던지기 흔적 0.35초: %s(기대 fling 띠 밖)" % [gone])
	v.free()
	return check(bad.is_empty(), "%s" % [bad])

# 뜬 몸의 그림자 수도 세는 기록 화면
class Shade extends Rec:
	var shades := 0

	func _shadow(_at: Vector2, _r: float) -> void:
		shades += 1

# EV760 · S172 2026-11-05 변경 ③: 부서진 뒤 뜬 동안 착지 0열(한가운데 10px 듦, 그림자), 착지 뒤 0.15초 착지 1열, 그 뒤 정지
func ev760():
	var a = _chief_art()
	if a == null:
		return NO_CHIEF % [CHIEF.keys()]
	var c: float = a.c
	var b = battle({"base_hp": BIG})
	var v = Shade.new()
	v.battle = b
	var e = b.spawn_enemy("war_machine", Vector2i(10, 10), STILL.merged({"hp": 10}))
	_one(v, e)
	b.damage(e, 50.0, "true")
	if e.kind != "chief" or e.cast == null or not e.cast.get("air", false):
		v.free()
		return "부서진 뒤 종류 %s · cast %s" % [e.kind, e.cast]
	var bad := []
	_expect(bad, "부서진 직후", _one(v, e), Rect2(a.x, a.leap, c, c))
	e.cast.left = e.skills.leap.air / 2.0
	v.shades = 0
	var mid = _one(v, e)
	_expect(bad, "뜬 한가운데", mid, Rect2(a.x, a.leap, c, c))
	if v.shades != 1:
		bad.append("그림자 %d개" % v.shades)
	e.cast = null
	var ground = _one(v, e)
	if mid == null or ground == null or absf(mid[0].position.y - (ground[0].position.y - 10.0)) > 0.01:
		bad.append("뜬 높이: %s → 땅 %s" % [mid, ground])
	b.traces.append(_chief_trace(e, "slam", e.pos, 0.05, {"radius": 2.5}))
	_expect(bad, "착지 흔적 0.05초", _one(v, e), Rect2(a.x + c, a.leap, c, c))
	b.traces.clear()
	b.traces.append(_chief_trace(e, "slam", e.pos, 0.3, {"radius": 2.5}))
	var after = _one(v, e)
	if not _small_cell(after, a) or after[1].position.y < a.idle or after[1].position.y >= a.idle + 4 * c:
		bad.append("착지 흔적 0.3초: %s(기대 정지 칸 y %s~)" % [after, a.idle])
	v.free()
	return check(bad.is_empty(), "%s" % [bad])

# 차례 기록 화면에 잔해 그리기도 모으는 화면
class WreckOrder extends Order:
	func _wreck(w: Dictionary) -> void:
		order.append(["wreck", w])

# (10,11)에서 (10,10)으로 옮겨 북쪽을 보게 그린 뒤 참 피해 50으로 부순 전쟁 기계(체력 10)
func _broken(b, v):
	var e = b.spawn_enemy("war_machine", Vector2i(10, 11), STILL.merged({"hp": 10}))
	_one(v, e)
	e.pos = Vector2(10, 10)
	_one(v, e)
	b.damage(e, 50.0, "true")
	return e

# EV761 · S172 2026-11-05 변경 ⑥: 부서진 자리에 기계가 보던 쪽의 잔해, 끝 0.5초 흐림, 5초 뒤 지움, 대장 몸통보다 먼저
func ev761():
	if not View.ART.has("wreck"):
		return "heroes.json에 wreck 칸이 없다"
	var w: Dictionary = View.ART.wreck
	var c: float = w.c
	var b = battle({"base_hp": BIG})
	var v = _rec(b)
	if not v.has_method("_wreck"):
		v.free()
		return "화면에 _wreck이 없다"
	var e = _broken(b, v)
	var list = b.get("wrecks")
	if list == null or list.size() != 1 or not list[0].at.is_equal_approx(Vector2(10, 10)):
		v.free()
		return "잔해 기록 %s(종류 %s)" % [list, e.kind]
	var bad := []
	var want := Rect2(w.get("x", 0), w.idle + 2 * c, c, c)
	for case in [[0.0, 1.0], [4.75, 0.5]]:
		list[0].age = case[0]
		v.cuts = []
		v._wreck(list[0])
		if v.cuts.size() != 1 or not v.cuts[0][1].is_equal_approx(want) or absf(v.cuts[0][2].a - case[1]) > 0.01:
			bad.append("%.2f초: %s(기대 %s · 알파 %s)" % [case[0], v.cuts, want, case[1]])
	list[0].age = 4.75
	b.step(0.3)
	if not b.wrecks.is_empty():
		bad.append("5초 뒤 잔해 기록 %s" % [b.wrecks])
	v.free()
	var b2 = battle({"base_hp": BIG})
	var o = WreckOrder.new()
	o.battle = b2
	var m = _broken(b2, o)
	o._foes = [m]
	o.order = []
	o._bodies()
	var order: Array = o.order
	o.free()
	var at_w := -1
	for i in order.size():
		if order[i][0] == "wreck":
			at_w = i
			break
	var at_m := _seen_at(order, "body", m)
	if at_w < 0 or at_m[0] < 0 or at_w > at_m[0]:
		bad.append("잔해 %d번째 · 대장 몸통 %s" % [at_w, at_m])
	return check(bad.is_empty(), "%s" % [bad])

# EV762 · S172 2026-11-05 변경 ⑤: 대장은 누운 자세로 눕고 끝 0.5초 동안 흐려진다
func ev762():
	var a = _chief_art()
	if a == null:
		return NO_CHIEF % [CHIEF.keys()]
	var c: float = a.c
	var b = battle({"base_hp": BIG})
	var v = _rec(b)
	var e = b.spawn_enemy("chief", Vector2i(10, 12), STILL)
	var bad := []
	var want := Rect2(a.x, a.fall, 2 * c, 2 * c)
	for case in [[1.0, 1.0], [1.75, 0.5]]:
		v.cuts = []
		v._corpse([e, case[0]])
		if v.cuts.size() != 1 or not v.cuts[0][1].is_equal_approx(want) or absf(v.cuts[0][2].a - case[1]) > 0.01:
			bad.append("%.2f초: %s(기대 %s · 알파 %s)" % [case[0], v.cuts, want, case[1]])
	v.free()
	return check(bad.is_empty(), "%s" % [bad])

# EV763 · I189 2026-11-05 변경: 대장·잔해 칸은 주민 띠 구역 오른쪽, 아틀라스 크기 그대로
func ev763():
	var art := _art()
	if not art.has("chief") or not art.has("wreck"):
		return "heroes.json에 chief·wreck 칸이 없다"
	var size: Vector2i = load("res://art/units/heroes.png").get_image().get_size()
	var bad := []
	if size != Vector2i(868, 15656):
		bad.append("heroes.png %s" % size)
	var right := 0
	var top := size.y
	for k in art:
		if k.begins_with("folk_"):
			right = maxi(right, int(art[k].x) + 2 * int(art[k].c))
			top = mini(top, int(art[k].idle))
	var a: Dictionary = art.chief
	var w: Dictionary = art.wreck
	if int(a.get("x", -1)) != int(w.get("x", -2)) or int(a.get("x", 0)) < right:
		bad.append("x 대장 %s · 잔해 %s · 주민 띠 오른쪽 %d" % [a.get("x"), w.get("x"), right])
	var c: int = int(a.c)
	var x: int = int(a.get("x", 0))
	var rects := []  # [이름, 그림 사각형]
	for n in CHIEF:
		rects.append([n, Rect2i(x, int(a.get(n, 0)), CHIEF[n] * c, 4 * c)])
	rects.append(["attack", Rect2i(x, int(a.get("attack", 0)), 2 * c, 8 * c)])
	rects.append(["fall", Rect2i(x, int(a.get("fall", 0)), 2 * c, 2 * c)])
	rects.append(["wreck", Rect2i(int(w.get("x", 0)), int(w.get("idle", 0)), int(w.c), 4 * int(w.c))])
	for i in rects.size():
		var r: Rect2i = rects[i][1]
		if r.position.y < top or r.end.y > size.y:
			bad.append("%s %s가 구역 y %d~%d 밖" % [rects[i][0], r, top, size.y])
		for j in i:
			if r.intersects(rects[j][1]):
				bad.append("%s %s가 %s와 겹침" % [rects[i][0], r, rects[j][0]])
	return check(bad.is_empty(), "%s" % [bad])
