extends "res://tests/eval/gd/hud.gd"
# 위 띠 영웅 칸과 숫자 키(플레이 후기 4의 2·3번, I108 2026-11-16 변경·I310·I261 ⑦). hud.gd 머리의 계약에 더하는 API:
#   Controls.caster() — 스킬 쓸 영웅(고른 것 가운데 앞에서부터 첫 살아 있는 출전 영웅, 없으면 null) · aiming · aim_hero · quickcast · mouse
#   main.hud._rows[i] — 출전 칸 i의 {secs: 남은 대시 초 Label, no: 대시 거부 테두리(Control), point: 스킬 쓸 영웅 세모(TextureRect), ...}
#   main.hud.portraits[i] — 초상 버튼. 고른 영웅이면 normal·hover 덮어쓰기가 pressed 스타일박스(S372 «고른 칸»)다
#   res://src/audio.gd of(트리).played — 낸 효과음 키(sound.gd 머리)
# 판: `_prep3`(영웅 셋 아이아스·실비아·세라피나) · `_prep`(영웅 둘). 병사는 준비 단계에 SOLDIER 칸에 놓는다(전투 단계에는 놓지 못한다)

const SOLDIER := Vector2i(20, 14)
const SPOT := Vector2i(32, 40)  # 둘레 2.5칸이 막히지 않은 칸(EV886)

# 영웅 셋 판에 병사 하나를 놓고 전투를 시작한 게임 장면 [main, 병사]. 퀵캐스트는 끈다(Q 키가 조준 상태가 된다)
func _fight3() -> Array:
	var main = _prep3()
	var b = main.view.battle
	var m = b.place_merc("soldier", SOLDIER)
	b.start_battle()
	main.controls.quickcast = false
	_frame(main)
	return [main, m]

# 영웅 둘 판에 병사 하나를 놓고 전투를 시작한 게임 장면 [main, 병사]
func _fight2() -> Array:
	var main = _prep()
	var b = main.view.battle
	var m = b.place_merc("soldier", SOLDIER)
	b.start_battle()
	main.controls.quickcast = false
	_frame(main)
	return [main, m]

func _picks(c) -> Array:
	return c.selected.map(func(u): return u.kind)

func _same(a: Array, b: Array) -> bool:
	return a.size() == b.size() and a.all(func(x): return x in b)

# 고른 칸 모양: normal·hover 덮어쓰기가 그 버튼의 pressed 스타일박스다(S372)
func _picked_look(face) -> bool:
	var press: StyleBox = face.get_theme_stylebox("pressed")
	return face.has_theme_stylebox_override("normal") and face.get_theme_stylebox("normal") == press and face.get_theme_stylebox("hover") == press

func _plain(face) -> bool:
	return not face.has_theme_stylebox_override("normal") and not face.has_theme_stylebox_override("hover")

func _audio():
	var tree: SceneTree = Engine.get_main_loop()
	var old = tree.root.get_node_or_null("Audio")
	if old:
		old.free()
	return load("res://src/audio.gd").of(tree)

# 커서를 영웅 h의 동쪽 cells칸 맵 자리 위에 둔다(카메라를 영웅에 맞춘다)
func _aim_east(main, h, cells: float) -> void:
	var cam = _cam(main)
	cam.position = (h.pos + Vector2(0.5, 0.5)) * CELL_PX
	cam.force_update_scroll()
	_move(cam.steady() * ((h.pos + Vector2(0.5 + cells, 0.5)) * CELL_PX))

# EV1155 · I108 2026-11-16 변경: 용병이 섞인 무리에서 숫자 키·초상은 무리를 그대로 두고 그 영웅을 맨 앞(스킬 쓸 영웅)으로 옮긴다. 두 번 눌러도 풀리지 않는다
func ev1155():
	var f := _fight3()
	var main = f[0]
	var m = f[1]
	var b = main.view.battle
	var c = main.controls
	if m == null or b.heroes.size() != 3:
		_done(main)
		return "시험 판: 병사 %s · 출전 영웅 %d명(셋이어야 한다)" % [m, b.heroes.size()]
	var h: Array = b.heroes
	var group := [h[0], h[1], m]
	var out := ""
	c.selected = group.duplicate()
	_key(KEY_2)
	if not _same(c.selected, group) or c.selected[0] != h[1]:
		out = "[영웅 1, 영웅 2, 병사]에서 2 키: 고른 것 %s(기대 같은 셋, 첫째 영웅 2)" % [_picks(c)]
	if out == "":
		_key(KEY_Q)
		if c.aiming != "q" or c.aim_hero != h[1]:
			out = "이어 Q 키: 조준 «%s» · 조준 영웅 %s(기대 «q»·영웅 2)" % [c.aiming, c.aim_hero.kind if c.aim_hero else null]
	if out == "":
		c.aiming = ""
		main.hud._process(0.1)
		_key(KEY_2)
		if not _same(c.selected, group) or c.selected[0] != h[1]:
			out = "0.1초 뒤 2 키를 또: 고른 것 %s(기대 같은 셋, 첫째 영웅 2)" % [_picks(c)]
	if out == "":
		main.hud._process(0.6)
		var mixed := [m, h[0], h[2]]
		c.selected = mixed.duplicate()
		main.hud.portraits[2].pressed.emit()
		if not _same(c.selected, mixed) or c.selected[0] != h[2]:
			out = "[병사, 영웅 1, 영웅 3]에서 셋째 초상: 고른 것 %s(기대 같은 셋, 첫째 영웅 3)" % [_picks(c)]
	_done(main)
	return out

# EV1156 · I108 2026-11-16 변경: 영웅만 고른 무리·무리에 없는 영웅·살아 있는 용병이 없는 무리·빈 선택에서는 그 영웅 하나만 고른다
func ev1156():
	var main = _prep3()
	var b = main.view.battle
	var m = b.place_merc("soldier", SOLDIER)
	var gone = b.place_merc("soldier", SOLDIER + Vector2i(1, 0))
	b.start_battle()
	_frame(main)
	var c = main.controls
	if m == null or gone == null or b.heroes.size() != 3:
		_done(main)
		return "시험 판: 병사 %s·%s · 출전 영웅 %d명(셋이어야 한다)" % [m, gone, b.heroes.size()]
	var h: Array = b.heroes
	b.damage(gone, BIG, "true")
	var out := ""
	_key(KEY_QUOTELEFT)
	var all_three: bool = _same(c.selected, h)
	_key(KEY_2)
	if not all_three or c.selected != [h[1]]:
		out = "` 키(영웅 셋 %s) 뒤 2 키: 고른 것 %s(기대 영웅 2 하나)" % [all_three, _picks(c)]
	for k in [[[h[0], m], KEY_3, h[2], "[영웅 1, 병사]에서 3 키"], [[h[0], h[1], gone], KEY_2, h[1], "[영웅 1, 영웅 2, 쓰러진 병사]에서 2 키"], [[], KEY_1, h[0], "빈 선택에서 1 키"]]:
		if out != "":
			break
		c.selected = k[0].duplicate()
		main.hud._process(0.6)
		_key(k[1])
		if c.selected != [k[2]]:
			out = "%s: 고른 것 %s(기대 %s 하나)" % [k[3], _picks(c), k[2].kind]
	_done(main)
	return check(out == "" and not gone.alive, out if out != "" else "병사를 쓰러뜨리지 못했다")

# EV1157 · I108 2026-11-16 변경: 쓰러졌거나 없는 영웅의 키·초상은 고른 것도 카메라도 바꾸지 않는다
func ev1157():
	var f := _fight2()
	var main = f[0]
	var m = f[1]
	var b = main.view.battle
	var c = main.controls
	if m == null or b.heroes.size() != 2:
		_done(main)
		return "시험 판: 병사 %s · 출전 영웅 %d명(둘이어야 한다)" % [m, b.heroes.size()]
	var h: Array = b.heroes
	b.damage(h[1], BIG, "true")
	var out := "" if not h[1].alive else "영웅 2를 쓰러뜨리지 못했다"
	if out == "":
		c.selected = [h[0], m]
		_key(KEY_2)
		if c.selected != [h[0], m]:
			out = "[영웅 1, 병사]에서 쓰러진 영웅 2의 키: 고른 것 %s(기대 그대로)" % [_picks(c)]
	for k in [KEY_2, KEY_3]:
		if out != "":
			break
		c.selected = [h[0]]
		main.hud._process(0.6)
		_key(k)
		if c.selected != [h[0]]:
			out = "[영웅 1]에서 %s 키: 고른 것 %s(기대 그대로)" % ["2" if k == KEY_2 else "3", _picks(c)]
	if out == "":
		var cam = _cam(main)
		cam.zoom_at(2 - cam.level, Vector2(320, 180))
		_away(main)
		_settle(main)
		var at: Vector2 = cam.position
		c.selected = [h[0]]
		main.hud._process(0.6)
		_key(KEY_2)
		main.hud._process(0.1)
		_key(KEY_2)
		main.hud._process(0.6)
		main.hud.portraits[1].pressed.emit()
		main.hud._process(0.1)
		main.hud.portraits[1].pressed.emit()
		_settle(main)
		if absf(cam.position.x - at.x) > 0.5 or absf(cam.position.y - at.y) > 0.5 or c.selected != [h[0]]:
			out = "쓰러진 영웅 2의 키·초상을 두 번씩: 카메라 %s → %s · 고른 것 %s(기대 그대로·[영웅 1])" % [at, cam.position, _picks(c)]
	_done(main)
	return out

# EV1158 · I108 2026-11-16 변경: Q·W·E·R은 고른 것 가운데 앞에서부터 첫 살아 있는 출전 영웅이 쓰고, 없으면 살아 있는 첫 출전 영웅이 쓴다
func ev1158():
	var f := _fight3()
	var main = f[0]
	var m = f[1]
	var b = main.view.battle
	var c = main.controls
	if m == null or b.heroes.size() != 3:
		_done(main)
		return "시험 판: 병사 %s · 출전 영웅 %d명(셋이어야 한다)" % [m, b.heroes.size()]
	var h: Array = b.heroes
	b.damage(h[1], BIG, "true")
	c.selected = [h[1], h[2], m]
	_key(KEY_Q)
	var out := ""
	if h[1].alive or c.aim_hero != h[2] or c.aiming != "q":
		out = "[쓰러진 영웅 2, 영웅 3, 병사]에서 Q 키: 조준 «%s» · 조준 영웅 %s(기대 «q»·영웅 3)" % [c.aiming, c.aim_hero.kind if c.aim_hero else null]
	if out == "":
		c.aiming = ""
		b.damage(h[2], BIG, "true")
		_key(KEY_Q)
		if h[2].alive or c.aim_hero != h[0] or c.aiming != "q":
			out = "영웅 2·3이 쓰러진 무리에서 Q 키: 조준 «%s» · 조준 영웅 %s(기대 «q»·영웅 1)" % [c.aiming, c.aim_hero.kind if c.aim_hero else null]
	_done(main)
	return out

# EV1159 · I108 2026-11-16 변경: 스킬 쓸 영웅이 바뀌면 다른 영웅의 조준은 끈다. 새 스킬 쓸 영웅의 조준은 남는다
func ev1159():
	var f := _fight3()
	var main = f[0]
	var m = f[1]
	var b = main.view.battle
	var c = main.controls
	if m == null or b.heroes.size() != 3:
		_done(main)
		return "시험 판: 병사 %s · 출전 영웅 %d명(셋이어야 한다)" % [m, b.heroes.size()]
	var h: Array = b.heroes
	var out := ""
	c.selected = [h[0], h[1], m]
	_key(KEY_Q)
	var first: bool = c.aiming == "q" and c.aim_hero == h[0]
	_key(KEY_2)
	if not first or c.aiming != "":
		out = "영웅 1의 Q 조준(켜짐 %s) 뒤 2 키: 조준 «%s»(기대 «»)" % [first, c.aiming]
	if out == "":
		main.hud._process(0.6)
		_key(KEY_Q)
		var second: bool = c.aiming == "q" and c.aim_hero == h[1]
		_key(KEY_2)
		if not second or c.aiming != "q" or c.aim_hero != h[1]:
			out = "영웅 2의 Q 조준(켜짐 %s) 뒤 2 키: 조준 «%s»·%s(기대 «q»·영웅 2)" % [second, c.aiming, c.aim_hero.kind if c.aim_hero else null]
	if out == "":
		c.aiming = ""
		c.selected = [h[0]]
		main.hud._process(0.6)
		_key(KEY_Q)
		var solo: bool = c.aiming == "q" and c.aim_hero == h[0]
		_key(KEY_3)
		if not solo or c.selected != [h[2]] or c.aiming != "":
			out = "[영웅 1] Q 조준(켜짐 %s) 뒤 3 키: 고른 것 %s · 조준 «%s»(기대 영웅 3 하나·«»)" % [solo, _picks(c), c.aiming]
	if out == "":
		main.hud._process(0.6)
		main.hud.slots[2]["q"].pressed.emit()
		var third: bool = c.aiming == "q" and c.aim_hero == h[2]
		c.selected = [h[0], h[2], m]
		_key(KEY_3)
		if not third or c.aiming != "q" or c.aim_hero != h[2]:
			out = "영웅 3의 Q 칸 조준(켜짐 %s) 뒤 [영웅 1, 영웅 3, 병사]에서 3 키: 조준 «%s»·%s(기대 «q»·영웅 3)" % [third, c.aiming, c.aim_hero.kind if c.aim_hero else null]
	_done(main)
	return out

# 초상마다 [고른 칸, 평소, 세모 보임]
func _marks(main) -> Array:
	main.hud._process(0.0)
	var out := []
	for i in main.hud.portraits.size():
		var p = main.hud._rows[i].get("point")
		out.append([_picked_look(main.hud.portraits[i]), _plain(main.hud.portraits[i]), p != null and p.is_visible_in_tree()])
	return out

# 기대: picked는 고른 칸이어야 할 초상 번호, point는 세모가 있어야 할 초상 번호(-1이면 없음). 나머지는 평소 모양·세모 없음
func _marks_are(got: Array, picked: Array, point: int) -> bool:
	for i in got.size():
		if got[i][0] != (i in picked) or got[i][1] == (i in picked) or got[i][2] != (i == point):
			return false
	return true

# EV1160 · I310 ①②: 고른 살아 있는 출전 영웅의 초상은 «고른 칸», 스킬 쓸 영웅에만 세모. 원정에서도 같다
func ev1160():
	var f := _fight3()
	var main = f[0]
	var m = f[1]
	var b = main.view.battle
	var c = main.controls
	if m == null or b.heroes.size() != 3:
		_done(main)
		return "시험 판: 병사 %s · 출전 영웅 %d명(셋이어야 한다)" % [m, b.heroes.size()]
	var h: Array = b.heroes
	var cases := [[[h[0], h[1], m], -1, [0, 1], 0], [null, KEY_2, [0, 1], 1], [[m], -1, [], -1], [[], -1, [], -1]]
	var out := ""
	for k in cases:
		if k[0] != null:
			c.selected = k[0].duplicate()
		if k[1] != -1:
			_key(k[1])
		var got := _marks(main)
		if not _marks_are(got, k[2], k[3]):
			out = "고른 것 %s: 초상 [고른 칸, 평소, 세모] %s(기대 고른 칸 %s · 세모 %d)" % [_picks(c), got, k[2], k[3]]
			break
	if out == "":
		b.damage(h[0], BIG, "true")
		c.selected = [h[0], h[2]]
		var got := _marks(main)
		if h[0].alive or not _marks_are(got, [2], 2):
			out = "쓰러진 영웅 1·영웅 3을 고름: %s(기대 고른 칸 [2] · 세모 2)" % [got]
	_done(main)
	if out != "":
		return out
	main = _prep()
	b = main.view.battle
	b.state = "cleared"
	b.next_round()
	_frame(main)
	var went: bool = b.start_raid()
	main.controls.selected = b.party.duplicate()
	var got := _marks(main)
	var want: Array = range(b.party.size()).map(func(p): return b.heroes.find(b.party[p]))
	var first: int = b.heroes.find(b.party[0]) if not b.party.is_empty() else -2
	_done(main)
	return check(went and b.state == "raid" and _marks_are(got, want, first), "원정(%s, 판 %s)에서 원정대 %s를 모두 고름: %s(기대 고른 칸 %s · 세모 %d)" % [went, b.state, b.party.map(func(x): return x.kind), got, want, first])

# EV1161 · I310 ②, I261 ⑦: 세모 그림의 자리·모양·색, 거부 테두리보다 위, 남은 대시 초 글 모양
func ev1161():
	var main = _prep()
	var row: Dictionary = main.hud._rows[0]
	var face = main.hud.portraits[0]
	var p = row.get("point")
	var no = row.get("no")
	var secs = row.get("secs")
	if not p is TextureRect or no == null or not secs is Label:
		_done(main)
		return "초상 칸에 point(TextureRect)·no·secs(Label)가 없다: %s · %s · %s" % [p, no, secs]
	var out := ""
	if p.get_parent() != face or not p.position.is_equal_approx(Vector2(20, 7)) or not p.size.is_equal_approx(Vector2(6, 9)):
		out = "세모 부모 %s · 자리 %s · 크기 %s(기대 초상 · (20,7) · 6×9)" % [p.get_parent() == face, p.position, p.size]
	var img: Image = p.texture.get_image() if out == "" and p.texture else null
	if out == "" and (img == null or img.get_size() != Vector2i(6, 9)):
		out = "세모 그림 크기 %s(6×9)" % [img.get_size() if img else null]
	if out == "":
		var inside := 0
		var rows := []
		var right := -1
		var bad := []
		for y in 9:
			var n := 0
			for x in 6:
				var col := img.get_pixel(x, y)
				if col.a < 0.5:
					continue
				if col.is_equal_approx(Color("ffd37f")):
					n += 1
					right = maxi(right, x)
				elif not col.is_equal_approx(Color("0b0c10")):
					bad.append([x, y, col.to_html(false)])
			inside += n
			rows.append(n)
		if inside != 16 or rows.slice(1, 8) != [1, 2, 3, 4, 3, 2, 1] or not bad.is_empty() or 20 + right != 24:
			out = "세모 안쪽 칸 %d(16) · 줄마다 %s(1·2·3·4·3·2·1) · 다른 색 %s · 가장 오른쪽 x %d(24)" % [inside, rows, bad, 20 + right]
	if out == "" and not (no.get_parent() == face and p.get_index() > no.get_index()):
		out = "거부 테두리 부모 %s · 차례 세모 %d / 테두리 %d(세모가 뒤여야 한다)" % [no.get_parent() == face, p.get_index(), no.get_index()]
	if out == "":
		var fs: int = secs.get_theme_font_size("font_size")
		var r := Rect2(secs.position, secs.size)
		if fs != 10 or secs.get_theme_color("font_color") != Color("e8e8e8") or secs.get_theme_color("font_outline_color") != Color.BLACK or secs.get_theme_constant("outline_size") != 3 or not Rect2(Vector2.ZERO, face.size).encloses(r):
			out = "남은 초 글: 크기 %d(10) · 색 %s · 테 %s·%d(검정 3) · 사각형 %s(초상 %s 안)" % [fs, secs.get_theme_color("font_color").to_html(false), secs.get_theme_color("font_outline_color"), secs.get_theme_constant("outline_size"), r, face.size]
	_done(main)
	return out

# EV1162 · I261 ⑦: 초상 대기 막 위 올림한 남은 초, 쓰러지면 없음, 초상 툴팁의 대시 줄
func ev1162():
	var main = _prep()
	var b = main.view.battle
	var hud = main.hud
	b.start_battle()
	_frame(main)
	var h = b.heroes[0]
	var secs = hud._rows[0].get("secs")
	if not secs is Label:
		_done(main)
		return "초상 칸에 남은 초 글(secs)이 없다"
	var got := []
	for cd in [3.2, 0.5, 0.0]:
		h.dash_cd = cd
		hud._process(0.0)
		got.append([cd, secs.is_visible_in_tree(), secs.text])
	var out := ""
	if got[0][1] != true or got[0][2] != "4" or got[1][1] != true or got[1][2] != "1" or got[2][1] != false:
		out = "dash_cd별 [대기, 보임, 글] %s(기대 3.2 «4» · 0.5 «1» · 0 숨음)" % [got]
	if out == "":
		_fresh(hud.tip, hud.portraits[0])
		hud.tip._process(0.25)
		var s := _tip_text(hud.tip)
		if not hud.tip.visible or not "Space" in s or not "대시" in s:
			out = "첫 초상 툴팁 «%s»(보임 %s, 기대 «Space»·«대시» 있음)" % [s, hud.tip.visible]
	if out == "":
		b.damage(h, BIG, "true")
		h.dash_cd = 3.2
		hud._process(0.0)
		if h.alive or secs.is_visible_in_tree():
			out = "쓰러진 영웅(살아 있음 %s)의 남은 초 글이 보인다" % h.alive
	_done(main)
	return out

# 거부 표시: [초상마다 거부 테두리 보임, «대시 대기» 토스트 글, refuse 났나]
func _refusal(main, audio) -> Array:
	main.hud._process(0.0)
	var nos := []
	for i in main.view.battle.heroes.size():
		var no = main.hud._rows[i].get("no")
		nos.append(no != null and no.is_visible_in_tree())
	return [nos, _toasts(main).filter(func(t): return "대시 대기" in t), "refuse" in audio.played]

# EV1163 · I261 ⑦: 대기 중 Space에 아무도 대시하지 못하면 대기 중인 영웅 초상이 빨갛고 토스트·refuse. 준비 단계·한 명이라도 대시함·다른 까닭이면 없다
func ev1163():
	var main = _prep()
	var b = main.view.battle
	var hud = main.hud
	var c = main.controls
	var audio = _audio()
	var h: Array = b.heroes
	if h.size() != 2:
		_done(main)
		return "출전 영웅이 %d명이다(둘이어야 한다)" % h.size()
	var out := ""
	hud.toasts._process(3.6)  # 미션 토스트
	h[0].dash_cd = 3.0
	c.selected = [h[0]]
	_aim_east(main, h[0], 3)
	audio._process(1.0)
	audio.played.clear()
	_key(KEY_SPACE)
	var prep := _refusal(main, audio)
	if prep[0].has(true) or not prep[1].is_empty() or prep[2]:
		out = "준비 단계 Space: 거부 표시 %s(없어야 한다)" % [prep]
	if out == "":
		b.start_battle()
		_frame(main)
		hud.toasts._process(3.6)
		h[0].pos = Vector2(SPOT)
		h[1].pos = Vector2(SPOT + Vector2i(0, 1))
		c.selected = [h[0], h[1]]
		h[0].dash_cd = 3.2
		h[1].dash_cd = 1.4
		_aim_east(main, h[0], 3)
		audio._process(1.0)
		audio.played.clear()
		_key(KEY_SPACE)
		var still: bool = h[0].pos == Vector2(SPOT) and h[1].pos == Vector2(SPOT + Vector2i(0, 1))
		var got := _refusal(main, audio)
		if not still or got[0] != [true, true] or not got[1].any(func(t): return "대시 대기 2초" in t) or not got[2]:
			out = "둘 다 대기 중 Space: 그대로 %s · [테두리, 토스트, refuse] %s(기대 [참, 참] · «대시 대기 2초» · 참)" % [still, got]
		if out == "":
			hud._process(0.35)
			var later := _refusal(main, audio)
			if later[0].has(true):
				out = "0.35초 뒤에도 거부 테두리가 보인다 %s" % [later[0]]
	if out == "":
		hud.toasts._process(4.1)  # 앞 거부 토스트(4초)가 진다
		h[1].dash_cd = 0.0
		_aim_east(main, h[0], 3)
		audio._process(1.0)
		audio.played.clear()
		var at: Vector2 = h[1].pos
		_key(KEY_SPACE)
		var got := _refusal(main, audio)
		if h[1].pos == at or got[0].has(true) or not got[1].is_empty() or got[2]:
			out = "영웅 2만 대시할 수 있을 때 Space: 영웅 2 움직임 %s · 거부 표시 %s(없어야 한다)" % [h[1].pos != at, got]
	if out == "":
		hud._process(0.5)
		hud.toasts._process(4.1)
		h[0].dash_cd = 0.0
		h[0].on_wall = true
		c.selected = [h[0]]
		_aim_east(main, h[0], 3)
		audio._process(1.0)
		audio.played.clear()
		_key(KEY_SPACE)
		var got := _refusal(main, audio)
		if got[0].has(true) or not got[1].is_empty() or got[2]:
			out = "성벽 위(대기 없음) 영웅만 고른 Space: 거부 표시 %s(없어야 한다)" % [got]
	_done(main)
	return out
