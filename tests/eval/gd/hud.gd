extends "res://tests/eval/gd/save.gd"
# WBS 4.1g HUD 개편(S187·I162). save.gd 머리의 계약에 더하는 API:
#   main.hud.bar — HUD 위 띠(Control). 그 안의 보이는 BaseButton이 «위 띠의 조작»이다
#   main.hud.tip — 툴팁 패널(Control, I162). visible · get_global_rect() · _process(delta)로 시간을 흘린다
#     tip.reason — 빨간 이유 줄(Label). 못 쓰는 조건이 없으면 숨는다
#   main.hud.grid — 건설 격자(Control, S186). _process(delta)로 시간을 흘린다. 자리는 컨테이너 없이 바로 정해진다
#     grid.cells — 놓기 kind → 칸(BaseButton). 칸 안의 TextureRect가 아이콘이다(S30)
#     grid.info — 정보 칸(Control). grid.reason — 그 안의 빨간 이유 줄(Label) · grid.band — «공병 없음» 띠(Control, I128)
#   카메라(Camera2D, 게임 장면 안에 하나) — scroll(창 기준 마우스, 창 크기, delta) · pan(dir, delta) · zoom_at(step, 커서) · level
#     static edge_dir(창 기준 마우스, 창 크기)(S53)
# 커서는 화면(640×360) 좌표의 InputEventMouseMotion으로 옮긴다. 빈 맵 자리는 (320,300)이다

const EMPTY := Vector2(320, 300)
const ROWS := [["wall", "tower", "magic", "cannon"], ["barracks", "workshop", "archery", "house", "church"], ["soldier", "engineer", "archer"]]  # 건설 격자 줄(S186)
const DANGER := Color("ef3a0c")
const QNAME := {"aias": "방패 강타", "sylvia": "관통의 바람살", "seraphina": "성스러운 빛줄기", "vesper": "부식의 독안개", "ignis": "화염구 작렬", "chronos": "무기 과충전"}  # S97 표의 Q

# 영웅 둘을 영입해 출전시키고 1라운드 준비 단계로 간 게임 장면
func _prep():
	var main = _game()
	var b = main.view.battle
	b.gold = BIG
	for i in 2:
		b.hire(i)
	b.next_round()
	_frame(main)
	_layout(main)
	return main

# 컨테이너 배치는 다음 프레임으로 미뤄지는데 평가는 한 프레임 안에서 돈다. 위에서부터 직접 정렬한다(안 하면 버튼이 모두 (0,0)이다).
# 두 번 돈다. 줄바꿈 줄(HFlow)의 높이는 자기 정렬 뒤에 정해져서, 한 번이면 그 아래 영웅 줄이 둘째 줄 버튼 위에 겹친다
func _layout(main) -> void:
	for i in 2:
		for c in main.hud.find_children("*", "Container", true, false):
			c.notification(Container.NOTIFICATION_SORT_CHILDREN)

func _move(at: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = at
	e.global_position = at
	Engine.get_main_loop().root.push_input(e, true)

func _bar_buttons(main) -> Array:
	return main.hud.bar.find_children("*", "BaseButton", true, false).filter(func(n): return n.is_visible_in_tree())

# 툴팁 안의 보이는 글을 한 줄로
func _tip_text(tip) -> String:
	var parts := []
	for n in tip.find_children("*", "Label", true, false):
		if n.is_visible_in_tree():
			parts.append(n.text)
	return " ".join(parts)

# 빈 맵에서 툴팁을 닫고 0.25초를 넘긴 뒤 btn 가운데로 커서를 옮긴다
func _fresh(tip, btn) -> void:
	_move(EMPTY)
	tip._process(0.3)
	_move(btn.get_global_rect().get_center())

# EV319 · S187: 위 띠의 보이는 버튼마다 0.1초에는 툴팁이 없고 0.25초에는 버튼 바로 아래·화면 안·폭 160 이하로 뜬다
func ev319():
	var main = _prep()
	var tip = main.hud.tip
	var buttons := _bar_buttons(main)
	var out := "" if buttons.size() >= 9 else "위 띠의 보이는 버튼이 %d개다" % buttons.size()
	var spots := {}
	for btn in buttons:
		spots[btn.get_global_rect().position] = true
	if out == "" and spots.size() < buttons.size():
		out = "버튼 %d개가 자리 %d곳에 겹쳐 있다(배치 전)" % [buttons.size(), spots.size()]
	for btn in buttons:
		if out != "":
			break
		_fresh(tip, btn)
		tip._process(0.1)
		if tip.visible:
			out = "«%s»: 0.1초에 툴팁이 떴다" % btn.text
			break
		tip._process(0.15)
		var r: Rect2 = btn.get_global_rect()
		var t: Rect2 = tip.get_global_rect()
		if not tip.visible:
			out = "«%s»: 0.25초에도 툴팁이 없다" % btn.text
		elif t.position.y < r.end.y - 0.5:
			out = "«%s»: 툴팁 윗변 %.1f가 버튼 아랫변 %.1f보다 위다" % [btn.text, t.position.y, r.end.y]
		elif not Rect2(-0.5, -0.5, 641, 361).encloses(t):
			out = "«%s»: 툴팁 %s가 화면 밖으로 나갔다" % [btn.text, t]
		elif t.size.x > 160.5:
			out = "«%s»: 툴팁 폭이 %.1f다" % [btn.text, t.size.x]
	_done(main)
	return out

# EV320 · S187: 떠 있는 툴팁에서 옆 버튼으로 옮기면 바로 뜨고, 툴팁 위로 옮기면 남고, 0.3초 비운 뒤에는 다시 기다린다
func ev320():
	var main = _prep()
	var tip = main.hud.tip
	var buttons := _bar_buttons(main)
	var a = buttons[0]
	var c = buttons[1]
	_fresh(tip, a)
	tip._process(0.25)
	var out := "" if tip.visible else "첫 버튼에 0.25초를 두어도 툴팁이 없다"
	if out == "":
		_move(c.get_global_rect().get_center())
		tip._process(0.0)
		var r: Rect2 = c.get_global_rect()
		var t: Rect2 = tip.get_global_rect()
		if not tip.visible or t.position.y < r.end.y - 0.5 or t.end.x < r.position.x or t.position.x > r.end.x:
			out = "옆 버튼으로 옮긴 순간 그 버튼 아래에 툴팁이 없다(%s, 버튼 %s)" % [t, r]
	if out == "":
		var t: Rect2 = tip.get_global_rect()
		_move(Vector2(t.position.x + 2, t.end.y - 2))
		tip._process(0.5)
		out = check(tip.visible, "커서를 툴팁 위로 옮기자 0.5초 안에 툴팁이 사라졌다")
	if out == "":
		_move(EMPTY)
		tip._process(0.3)
		_move(buttons[2].get_global_rect().get_center())
		tip._process(0.1)
		out = check(not tip.visible, "빈 맵에서 0.3초 뒤 다른 버튼에 0.1초 만에 툴팁이 떴다")
	_done(main)
	return out

# node 아래 보이는 버튼 가운데 글이 head로 시작하는 것
func _starts(node: Node, head: String):
	for n in node.find_children("*", "BaseButton", true, false):
		if n.is_visible_in_tree() and n.text.begins_with(head):
			return n
	return null

# EV321 · S187: 준비 단계 첫 영웅 Q 툴팁은 S97 표의 이름과 «마나»에 빨간 줄 «전투 단계». 놓기 칸 글은 EV323(정보 칸)이 본다
func ev321():
	var main = _prep()
	var tip = main.hud.tip
	var b = main.view.battle
	var out := ""
	var q = null
	for n in _bar_buttons(main):
		if n.text == "Q":
			q = n
			break
	if out == "" and q:
		_fresh(tip, q)
		tip._process(0.25)
		var s := _tip_text(tip)
		var name: String = QNAME[b.heroes[0].kind]
		if not (name in s and "마나" in s) or not "전투 단계" in tip.reason.text:
			out = "준비 단계 첫 영웅 Q 툴팁이 «%s», 빨간 줄이 «%s»다(기대 «%s»·«마나»·«전투 단계»)" % [s, tip.reason.text, name]
	elif out == "":
		out = "«Q» 버튼이 없다"
	_done(main)
	return out

func _cam(main):
	return main.find_children("*", "Camera2D", true, false)[0]

func _rects(g) -> Dictionary:
	var out := {}
	for k in g.cells:
		out[k] = g.cells[k].get_global_rect()
	return out

# 칸 안의 글: 버튼 글과 자식 Label
func _cell_text(c) -> String:
	var parts := [c.text]
	for n in c.find_children("*", "Label", true, false):
		parts.append(n.text)
	return " ".join(parts)

func _red(c) -> bool:
	return c.get_theme_stylebox("normal").border_color.is_equal_approx(DANGER)

# 건설 격자 칸의 자리(S186): 12칸이 격자 안에 겹치지 않고 세 줄로, 용병은 파는 시설 아래. 칸 글에 이유(I132)가 없다. 문제가 없으면 ""
func _grid_shape(g, r: Dictionary) -> String:
	var area := Rect2(510, 288, 130, 72).grow(0.5)
	for row in ROWS:
		for k in row:
			if not r.has(k):
				return "«%s» 칸이 없다(%s)" % [k, r.keys()]
			if not area.encloses(r[k]) or r[k].size.x < 19.5 or r[k].size.y < 19.5:
				return "«%s» 칸 %s가 격자 [510,288,130,72] 밖이거나 20×20보다 작다" % [k, r[k]]
			for k2 in r:
				if k2 != k and r[k].intersects(r[k2]):
					return "«%s» 칸 %s와 «%s» 칸 %s가 겹친다" % [k, r[k], k2, r[k2]]
			if absf(r[k].position.y - r[row[0]].position.y) > 0.5:
				return "«%s» 칸 y %.1f가 같은 줄 «%s»의 %.1f와 다르다" % [k, r[k].position.y, row[0], r[row[0]].position.y]
	for i in [1, 2]:
		if r[ROWS[i][0]].position.y <= r[ROWS[i - 1][0]].position.y:
			return "%d줄이 %d줄보다 아래가 아니다" % [i + 1, i]
	for pair in [["soldier", "barracks"], ["engineer", "workshop"], ["archer", "archery"]]:
		if absf(r[pair[0]].position.x - r[pair[1]].position.x) > 0.5:
			return "«%s» 칸 x %.1f가 «%s» 칸 x %.1f와 다르다" % [pair[0], r[pair[0]].position.x, pair[1], r[pair[1]].position.x]
	if r.size() != 12:
		return "칸이 %d개다(%s)" % [r.size(), r.keys()]
	return ""

# EV322 · S186: 준비·전투 단계에 건설 격자 12칸의 자리가 같고, 칸 글에 «없음»·«Lv»가 없다. 칸·2 키를 두 번 누르면 놓기 모드가 켜졌다 꺼진다
func ev322():
	var main = _prep()
	var g = main.hud.get("grid")
	if g == null:
		_done(main)
		return "main.hud.grid가 없다"
	var b = main.view.battle
	g._process(0.0)
	var prep := _rects(g)
	var out := _grid_shape(g, prep)
	if out == "" and not g.is_visible_in_tree():
		out = "준비 단계에 건설 격자가 보이지 않는다"
	if out == "":
		var seen := []
		g.cells.tower.pressed.emit()
		seen.append(main.controls.placing)
		g.cells.tower.pressed.emit()
		seen.append(main.controls.placing)
		_key(KEY_2)
		seen.append(main.controls.placing)
		_key(KEY_2)
		seen.append(main.controls.placing)
		out = check(seen == ["tower", "", "tower", ""], "타워 칸·칸·2 키·2 키 뒤 놓기 모드가 %s다(기대 tower, «», tower, «»)" % [seen])
	if out == "":
		b.start_battle()
		_frame(main)
		g._process(0.0)
		var now := _rects(g)
		for k in prep:
			if not now[k].is_equal_approx(prep[k]):
				out = "«%s» 칸이 준비 %s에서 전투 %s로 옮겼다" % [k, prep[k], now[k]]
				break
		if out == "" and not g.is_visible_in_tree():
			out = "전투 단계에 건설 격자가 보이지 않는다"
	for k in g.cells:  # 전투 단계(공병 없음·용병 구매 불가)에서 잰다
		var t := _cell_text(g.cells[k])
		if out == "" and ("없음" in t or "Lv" in t):
			out = "«%s» 칸 글 «%s»에 이유가 붙었다" % [k, t]
	_done(main)
	return out

# EV323 · I132: 마을 Lv1 준비 단계에 타워 칸 정보 칸은 «타워»·«30골드»·«[2]»에 빨간 줄이 없고, 사격장 칸은 빨간 줄에 «마을 Lv2».
# 사격장 칸을 누르면 놓기 모드 없이 거점이 골라져 마을 레벨 버튼이 뜨고, 칸 테두리가 0.2초에 빨갛고 0.4초에 아니다.
# 전투 단계에 누르면 마을 레벨 버튼이 없고 정보 칸에 «준비 단계에»
func ev323():
	var main = _prep()
	var g = main.hud.get("grid")
	if g == null:
		_done(main)
		return "main.hud.grid가 없다"
	var b = main.view.battle
	var c = main.controls
	var out := ""
	_move(g.cells.tower.get_global_rect().get_center())
	g._process(0.0)
	var s := _tip_text(g.info)
	if not g.info.is_visible_in_tree() or not ("타워" in s and "30골드" in s and "[2]" in s) or g.reason.is_visible_in_tree():
		out = "타워 칸 정보 칸이 «%s»다(보임 %s, 빨간 줄 %s)" % [s, g.info.is_visible_in_tree(), g.reason.is_visible_in_tree()]
	var archery = g.cells.archery
	if out == "":
		_move(archery.get_global_rect().get_center())
		g._process(0.0)
		if not g.reason.is_visible_in_tree() or not "마을 Lv2" in g.reason.text:
			out = "마을 Lv1 사격장 칸 정보 칸의 빨간 줄이 «%s»다(보임 %s)" % [g.reason.text, g.reason.is_visible_in_tree()]
	if out == "":
		archery.pressed.emit()
		main.hud._process(0.0)
		var up = _starts(main.hud, "마을 레벨 2로")
		g._process(0.2)
		var red_early := _red(archery)
		g._process(0.2)
		if not c.village or up == null or c.placing != "":
			out = "준비 단계에 사격장 칸을 누른 뒤 거점 고름 %s · 마을 레벨 버튼 %s · 놓기 모드 «%s»" % [c.village, up, c.placing]
		elif not red_early or _red(archery):
			out = "사격장 칸 테두리가 0.2초에 빨강 %s, 0.4초에 빨강 %s다" % [red_early, _red(archery)]
	if out == "":
		c.village = false
		b.start_battle()
		_frame(main)
		archery.pressed.emit()
		main.hud._process(0.0)
		g._process(0.0)
		s = _tip_text(g.info)
		if _starts(main.hud, "마을 레벨") != null or not "준비 단계에" in s:
			out = "전투 단계에 사격장 칸을 누른 뒤 마을 레벨 버튼 %s · 정보 칸 «%s»" % [_starts(main.hud, "마을 레벨"), s]
	_done(main)
	return out

# EV324 · I128: 전투 단계에 놀고 있는 공병이 없으면 «공병 없음» 띠가 보이고 1·2줄 칸이 0.35다. 공병을 사면 띠가 숨고 칸이 밝다
func ev324():
	var main = _prep()
	var g = main.hud.get("grid")
	if g == null:
		_done(main)
		return "main.hud.grid가 없다"
	var b = main.view.battle
	var ws = b.build("workshop", _near(b, "workshop", b.base.cell))
	b.start_battle()
	_frame(main)
	g._process(0.0)
	var out := "" if ws else "작업장을 짓지 못했다"
	var dim: Array = (ROWS[0] + ROWS[1]).filter(func(k): return absf(g.cells[k].modulate.a - 0.35) > 0.01)
	if out == "" and (not g.band.is_visible_in_tree() or not "공병 없음" in _tip_text(g.band) or not dim.is_empty()):
		out = "공병 0인 전투 단계: 띠 보임 %s · 띠 글 «%s» · 0.35가 아닌 칸 %s" % [g.band.is_visible_in_tree(), _tip_text(g.band), dim]
	if out == "":
		var e = b.recruit(ws, "engineer")
		g._process(0.0)
		if e == null:
			out = "작업장에서 공병을 사지 못했다"
		elif g.band.is_visible_in_tree() or absf(g.cells.tower.modulate.a - 1.0) > 0.01:
			out = "공병을 산 뒤 띠 보임 %s · 타워 칸 불투명도 %.2f" % [g.band.is_visible_in_tree(), g.cells.tower.modulate.a]
	_done(main)
	return out

# EV325 · I50, S186: 1·2·3배 줌 맨 아래에서 맵 아래끝이 화면 y 288이고 정보 칸은 [376,306,130,54] 안에 아래로 붙는다.
# 맨 위에서는 맵 y 0이 화면 y 0 아래로 내려가지 않고 정보 칸은 격자 위(x 510, 아래끝 288)다
func ev325():
	var main = _prep()
	var g = main.hud.get("grid")
	if g == null:
		_done(main)
		return "main.hud.grid가 없다"
	var b = main.view.battle
	var cam = _cam(main)
	var map: SubViewport = main.hud.map
	var bottom: float = b.size.y * main.view.CELL
	var out := ""
	_move(g.cells.archery.get_global_rect().get_center())
	for lv in 3:
		cam.zoom_at(lv - cam.level, Vector2(320, 180))
		cam.pan(Vector2(0, 1), 100.0)
		cam.force_update_scroll()
		var y: float = (map.get_canvas_transform() * Vector2(0, bottom)).y
		g._process(0.0)
		var r: Rect2 = g.info.get_global_rect()
		if absf(y - 288.0) > 0.5:
			out = "%d배 줌 맨 아래에서 맵 아래끝이 화면 y %.1f다" % [cam.zoom.x, y]
		elif not g.info.is_visible_in_tree() or absf(r.position.x - 376) > 0.5 or absf(r.end.y - 360) > 0.5 or absf(r.size.x - 130) > 0.5 or r.size.y > 54.5:
			out = "%d배 줌 맨 아래에서 정보 칸이 %s다(보임 %s)" % [cam.zoom.x, r, g.info.is_visible_in_tree()]
		if out != "":
			break
		cam.pan(Vector2(0, -1), 100.0)
		cam.force_update_scroll()
		var top: float = (map.get_canvas_transform() * Vector2.ZERO).y
		g._process(0.0)
		r = g.info.get_global_rect()
		if top > 0.5:
			out = "%d배 줌 맨 위에서 맵 y 0이 화면 y %.1f다" % [cam.zoom.x, top]
		elif absf(r.position.x - 510) > 0.5 or absf(r.end.y - 288) > 0.5 or absf(r.size.x - 130) > 0.5:
			out = "%d배 줌 맨 위에서 정보 칸이 %s다" % [cam.zoom.x, r]
		if out != "":
			break
	_done(main)
	return out

# EV326 · S53: 2배 줌·창 1280×720에서 오른쪽 가장자리 띠 안의 건설 칸 위면 카메라가 서고, 같은 x의 맵 위면 간다. 위 가장자리는 창 y 0~3만
func ev326():
	var main = _prep()
	var g = main.hud.get("grid")
	if g == null:
		_done(main)
		return "main.hud.grid가 없다"
	var cam = _cam(main)
	var C = load("res://src/ui/camera.gd")
	var size := Vector2(1280, 720)
	var church: Rect2 = g.cells.church.get_global_rect()
	var at := Vector2(church.end.x - 2, church.get_center().y)
	var out := check(C.edge_dir(at * 2, size).x == 1, "교회 칸 오른쪽 끝 %s가 가장자리 띠 밖이다" % at)
	if out == "":
		_move(at)
		var before: Vector2 = cam.position
		cam.scroll(at * 2, size, 1.0)
		if not cam.position.is_equal_approx(before):
			out = "건설 칸 위에서 카메라가 %s에서 %s로 움직였다" % [before, cam.position]
		var open := Vector2(at.x, 150)
		_move(open)
		cam.scroll(open * 2, size, 1.0)
		if out == "" and cam.position.is_equal_approx(before):
			out = "같은 x의 맵 위 가장자리에서 카메라가 움직이지 않았다"
	for y in [0, 3, 4, 5, 15]:
		var want := Vector2(0, -1) if y < 4 else Vector2.ZERO
		if out == "" and C.edge_dir(Vector2(640, y), size) != want:
			out = "창 y %d에서 방향이 %s다(기대 %s)" % [y, C.edge_dir(Vector2(640, y), size), want]
	_done(main)
	return out

# EV327 · S30: 건설 격자 12칸마다 아이콘(TextureRect) 텍스처가 0보다 크고, 시설 9종은 facility.png, 용병 3종은 heroes.png를 자른 것이다
func ev327():
	var main = _prep()
	var g = main.hud.get("grid")
	if g == null:
		_done(main)
		return "main.hud.grid가 없다"
	var fac = load("res://art/castle/facility.png")
	var units = load("res://art/units/heroes.png")
	var out := ""
	for row in ROWS:
		for k in row:
			var pics: Array = g.cells[k].find_children("*", "TextureRect", true, false) if g.cells.has(k) else []
			var t = pics[0].texture if not pics.is_empty() else null
			var want = units if k in ROWS[2] else fac
			if out == "" and (t == null or t.get_size().x <= 0 or t.get_size().y <= 0 or t.get("atlas") != want):
				out = "«%s» 칸 아이콘이 %s다(크기 %s, 아틀라스 %s)" % [k, t, t.get_size() if t else null, t.get("atlas") if t else null]
	_done(main)
	return out
