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
#   main.hud.cells — 위 띠 칸(S185) 이름 → Control: status · mission · engineer · hero0 · hero1 · hero2 · progress · menu.
#     status·mission·engineer·menu는 BaseButton이다. status 안 Label 하나가 거점 체력 숫자, engineer 안 Label이 놀고 있는 공병 수다
#   main.hud.hp_bar — 거점 체력 막대의 채운 부분(ColorRect, S190) · main.hud._process(delta)로 시간을 흘린다
#   main.hud.marks — 임무 칸의 점 둘(CanvasItem, 왼쪽 미션·오른쪽 의뢰, I122). 실패면 modulate가 #ef3a0c
#   main.hud.toasts — 토스트 층(Control, I163). 보이는 자식 하나가 토스트 하나이고 그 안 Label에 글이 있다. push(글) · _process(delta)
#   main.hud.start — 진행 칸의 전투 시작 버튼(BaseButton, I13) · main.hud.gauge — 진행 칸의 웨이브 버튼(BaseButton, 준비 단계 다음 웨이브·전투 단계 계기판)
#   main.hud.skull — 진행 칸의 보스 해골(CanvasItem, S188)
#   main.hud.edges — 아래 가장자리 표식 층(Control, S188). 보이는 자식 하나가 표식 하나이고 그 안 Label에 수가 있다
#   battle.spawn_counts(라운드, 웨이브) — 출현 지점(battle.spawns 차례)마다 {적 종류: 수}(S188). 라운드·웨이브는 0부터
#   main.hud.portraits — 출전 칸 차례마다 영웅 초상(BaseButton, I129·I165). 누르면 그 영웅을 고른다
#   main.hud.slots — 출전 칸 차례마다 {"q"·"w"·"e"·"r": 스킬 칸(BaseButton, I151)}. 버튼 글은 쓸 수 있으면 칸 글자(«Q»), 재사용 대기면 보이는 칸 글에 올림한 초.
#     self_modulate: 마나 부족 (0.5,0.5,1) · 잠김 (0.4,0.4,0.4) · 그 밖 흰색. 스킬 칸.lock — 자물쇠(CanvasItem). 잠겼을 때만 보인다
#   main.hud.tags — 상황 태그 [A, H](BaseButton, I139). 버튼 글은 없고, 안의 첫 TextureRect가 상태 그림이다(텍스처·modulate)
#   main.hud.popup — 맵 위 팝업(Control, I58). 그 안의 보이는 BaseButton이 팝업 버튼이고, 못 누르는 버튼은 disabled다
#   main.hud.hint — 놓기·조준 안내 글(Label, S147·I128). main.hud.chip — 그 글을 담은 안내 칩(Control, S147)
#   main.hud.map — 맵 SubViewport. get_canvas_transform()이 맵 px → 화면 좌표다
#   main.hud.alerts — 경보(Control, S189). recent: 최근 경보 칸(Vector2i, 새 것이 앞, 최대 5). 보이는 BaseButton 자식이 화면 밖 가장자리 표식이다
#     토스트 칸(main.hud.toasts의 보이는 자식)은 자리가 있으면 gui_input에 왼쪽 버튼 누름을 넣어 누른다(I163)
#   main.hud.window — 결과·영입 창(Control, S117·I136). 그 안의 보이는 BaseButton이 창 버튼(«리롤…»·«다음 라운드…»)이다 · main.hud.dim — 띠 아래 맵 덮개(ColorRect)
#   main.hud.hints — 처음 하는 사람 힌트 칸(Control, S191). 그 안의 보이는 Label이 힌트 글이고, «건너뛰기» 버튼이 있다
#     hints.axis — 튜토리얼 축 이름(Label, S192). 글이 «시설»·«용병»·«영웅»이다 · hints.text — 힌트 글(Label) · hints.HINTS — [이름, 웨이브, 판 단계, 글] 표
#   언어(S193, I167): settings.gd static var language(«ko»·«en») · apply_language()(번역기를 넣고 언어를 건다)
#   res://src/settings.gd — static var hints(힌트 켬, S184) · hints_done(끝낸 힌트 이름 Array: build·start·move·buy·keep, I166). ESC 메뉴 설정 화면에 켜고 끄는 버튼 «힌트»
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
		var up = _starts(main.hud, "마을 Lv2")
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
		if _starts(main.hud, "마을 Lv") != null or not "준비 단계에" in s:
			out = "전투 단계에 사격장 칸을 누른 뒤 마을 레벨 버튼 %s · 정보 칸 «%s»" % [_starts(main.hud, "마을 Lv"), s]
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

const BAR := {"status": Rect2(4, 2, 96, 24), "mission": Rect2(104, 2, 24, 24), "engineer": Rect2(130, 2, 20, 24), "hero0": Rect2(156, 2, 104, 24),
	"hero1": Rect2(264, 2, 104, 24), "hero2": Rect2(372, 2, 104, 24), "progress": Rect2(480, 2, 136, 24), "menu": Rect2(620, 2, 16, 24)}  # S185
const FOCUS := Vector2(320, 194)  # I164

# 위 띠 칸 사각형이 BAR와 같고, 늘 보이는 칸과 준비·전투 단계에만 보이는 칸이 맞게 보인다. 문제가 없으면 ""
func _bar_shape(main, phase: String) -> String:
	var bar = main.hud.bar
	if not bar.get_global_rect().is_equal_approx(Rect2(0, 0, 640, 28)) or not bar.is_visible_in_tree():
		return "%s: 위 띠가 %s다(보임 %s)" % [phase, bar.get_global_rect(), bar.is_visible_in_tree()]
	var cells = main.hud.get("cells")
	if not cells is Dictionary:
		return "%s: main.hud.cells가 없다" % phase
	var field: bool = main.view.battle.state in ["prep", "battle"]
	for k in BAR:
		if not cells.has(k):
			return "%s: «%s» 칸이 없다(%s)" % [phase, k, cells.keys()]
		var r: Rect2 = cells[k].get_global_rect()
		if r.position.distance_to(BAR[k].position) > 0.5 or r.size.distance_to(BAR[k].size) > 0.5:
			return "%s: «%s» 칸이 %s다(기대 %s)" % [phase, k, r, BAR[k]]
		var want = true if k in ["status", "progress", "menu"] else field if k in ["mission", "engineer"] else null
		if want != null and cells[k].is_visible_in_tree() != want:
			return "%s: «%s» 칸 보임이 %s다" % [phase, k, cells[k].is_visible_in_tree()]
	return ""

# 판의 1라운드 웨이브를 모두 이겨 라운드 사이로 간다
func _win(b) -> bool:
	for i in 10:
		if b.state == "prep":
			b.start_battle()
		if b.state == "battle" and not clear_wave(b):
			return false
		if b.state == "cleared":
			return true
	return false

# EV328 · S185: 영입 창·준비·전투·라운드 사이에서 위 띠와 칸 사각형이 같고, 임무·공병 칸은 준비·전투 단계에만 보인다
func ev328():
	var main = _game()
	var b = main.view.battle
	b.gold = BIG
	_frame(main)
	_layout(main)
	var out := _bar_shape(main, "영입 창")
	if out == "":
		for i in 2:
			b.hire(i)
		b.next_round()
		_frame(main)
		_layout(main)
		out = _bar_shape(main, "준비 단계")
	if out == "":
		b.start_battle()
		_frame(main)
		_layout(main)
		out = _bar_shape(main, "전투 단계")
	if out == "":
		out = check(_win(b), "1라운드를 이겨 라운드 사이가 되지 않았다(%s)" % b.state)
	if out == "":
		_frame(main)
		_layout(main)
		out = _bar_shape(main, "라운드 사이")
	_done(main)
	return out

# node 아래 보이는 Label의 글
func _labels(node: Node) -> Array:
	return node.find_children("*", "Label", true, false).filter(func(l): return l.is_visible_in_tree()).map(func(l): return l.text)

# EV329 · S190: 상태 묶음의 숫자가 거점 체력이고, 피해에 0.2초 하얗게 번쩍인 뒤 50% 밑 노랑, 25% 밑 빨강이다
func ev329():
	var main = _prep()
	var cells = main.hud.get("cells")
	var bar = main.hud.get("hp_bar")
	if not cells is Dictionary or bar == null:
		_done(main)
		return "main.hud.cells나 main.hud.hp_bar가 없다"
	var b = main.view.battle
	var hp := ceili(b.base.hp)
	var out := check(str(hp) in _labels(cells.status), "상태 묶음 글 %s에 거점 체력 %d가 없다" % [_labels(cells.status), hp])
	if out == "":
		b.damage(b.base, 7)
		main.hud._process(0.1)
		var white: bool = bar.color.is_equal_approx(Color.WHITE)
		main.hud._process(0.2)
		if not str(hp - 7) in _labels(cells.status):
			out = "피해 7 뒤 상태 묶음 글이 %s다(기대 %d)" % [_labels(cells.status), hp - 7]
		elif not white or bar.color.is_equal_approx(Color.WHITE):
			out = "피해 뒤 0.1초에 흰색 %s, 0.3초에 흰색 %s다" % [white, bar.color.is_equal_approx(Color.WHITE)]
	for pair in [[0.4, Color("e0c040")], [0.2, DANGER]]:
		if out == "":
			b.base.hp = b.base.max_hp * pair[0]
			main.hud._process(0.3)
			out = check(bar.color.is_equal_approx(pair[1]), "거점 체력 %d%%에서 막대 색이 %s다(기대 %s)" % [pair[0] * 100, bar.color, pair[1]])
	_done(main)
	return out

# 맵 px p가 화면 (320,194)에서 축마다 0.5 안이거나, 그 축으로 맞추는 쪽으로 카메라가 더 움직이지 못한다(I164). 문제가 없으면 ""
func _focused(main, p: Vector2) -> String:
	var cam = _cam(main)
	cam.force_update_scroll()
	var s: Vector2 = main.hud.map.get_canvas_transform() * p
	for ax in 2:
		var off: float = s[ax] - FOCUS[ax]
		if absf(off) <= 0.5:
			continue
		var dir := Vector2.ZERO
		dir[ax] = signf(off)
		var before: Vector2 = cam.position
		cam.pan(dir, 0.05)
		var moved: bool = not cam.position.is_equal_approx(before)
		cam.position = before
		if moved:
			return "%d배 줌: 화면 %s가 (320,194)에서 어긋났는데 카메라가 그쪽으로 더 갈 수 있다" % [cam.zoom.x, s]
	return ""

# 카메라를 맨 오른쪽 아래로 보낸다
func _away(main) -> void:
	_cam(main).pan(Vector2(1, 1), 100.0)

# EV330 · I164: 2·3배 줌에서 상태 묶음을 누르면 거점이 경계 안에서 (320,194)에 가장 가깝게 온다. 3배 줌에서는 정확히 온다
func ev330():
	var main = _prep()
	var cells = main.hud.get("cells")
	if not cells is Dictionary:
		_done(main)
		return "main.hud.cells가 없다"
	var b = main.view.battle
	var cam = _cam(main)
	var keep := Vector2(b.base.cell) * 16 + Vector2(8, 8)
	var out := ""
	for lv in [1, 2]:
		cam.zoom_at(lv - cam.level, Vector2(320, 180))
		_away(main)
		cells.status.pressed.emit()
		out = _focused(main, keep)
		if out != "":
			break
	if out == "":
		var s: Vector2 = main.hud.map.get_canvas_transform() * keep
		out = check(s.distance_to(FOCUS) <= 0.7, "3배 줌에서 거점이 화면 %s다(기대 (320,194))" % s)
	_done(main)
	return out

# 토스트 층에서 보이는 토스트의 글
func _toasts(main) -> Array:
	var out := []
	for t in main.hud.toasts.get_children():
		if t.is_visible_in_tree():
			out.append(" ".join(_labels(t)))
	return out

# EV331 · I122: 라운드 첫 준비 단계에 미션 토스트가 뜨고, 미션이 깨지면 임무 칸 왼쪽 점이 빨갛고 «미션 실패» 토스트가 하나 뜬다. 툴팁에 조건 문장
func ev331():
	var main = _prep()
	var marks = main.hud.get("marks")
	var cells = main.hud.get("cells")
	if marks == null or main.hud.get("toasts") == null or not cells is Dictionary:
		_done(main)
		return "main.hud.marks·toasts·cells가 없다"
	var b = main.view.battle
	var q: Dictionary = b.QUEST_KINDS[b.mission] if b.mission != "" else {}
	var out := check(not q.is_empty(), "1라운드 미션이 없다")
	var starts := _toasts(main).filter(func(t): return t.begins_with("이번 라운드 미션"))
	if out == "" and (starts.size() != 1 or not marks[0].is_visible_in_tree() or marks[0].modulate.is_equal_approx(DANGER)):
		out = "준비 단계 첫 프레임 토스트 %s · 왼쪽 점 보임 %s · 빨강 %s" % [_toasts(main), marks[0].is_visible_in_tree(), marks[0].modulate.is_equal_approx(DANGER)]
	if out == "":
		_fresh(main.hud.tip, cells.mission)
		main.hud.tip._process(0.25)
		out = check(q.text in _tip_text(main.hud.tip), "임무 칸 툴팁 «%s»에 미션 조건 «%s»가 없다" % [_tip_text(main.hud.tip), q.text])
		_move(EMPTY)
		main.hud.tip._process(0.3)
	if out == "":
		b.tally[q.zero[0]] = 1
		for i in 8:
			main.hud._process(0.5)
			main.hud.toasts._process(0.5)
		var fails := _toasts(main).filter(func(t): return t.begins_with("미션 실패"))
		if not marks[0].modulate.is_equal_approx(DANGER) or fails.size() != 1:
			out = "미션이 깨진 4초 뒤 왼쪽 점 빨강 %s · 토스트 %s" % [marks[0].modulate.is_equal_approx(DANGER), _toasts(main)]
	_done(main)
	return out

# EV332 · I163: 앞 토스트가 뜬 지 3.5초가 지나야 다음이 뜨고, 같은 글은 «(2)»로 합친다. 툴팁이 떠 있으면 시간이 흐르지 않는다
func ev332():
	var main = _prep()
	var toasts = main.hud.get("toasts")
	var cells = main.hud.get("cells")
	if toasts == null or not cells is Dictionary:
		_done(main)
		return "main.hud.toasts·cells가 없다"
	var mine := func(): return _toasts(main).filter(func(t): return "시험 경보" in t)
	toasts.push("시험 경보")
	toasts.push("시험 경보")
	toasts._process(3.0)
	var out := check(mine.call().is_empty(), "미션 토스트가 뜬 지 3초에 «시험 경보»가 떴다(%s)" % [_toasts(main)])
	if out == "":
		toasts._process(0.6)
		var m: Array = mine.call()
		if m.size() != 1 or not m[0].ends_with("(2)") or _toasts(main).size() != 2:
			out = "3.6초에 토스트가 %s다(기대: 미션 토스트와 «시험 경보 (2)»)" % [_toasts(main)]
	if out == "":
		_fresh(main.hud.tip, cells.menu)
		main.hud.tip._process(0.25)
		toasts._process(10.0)
		out = check(main.hud.tip.visible and _toasts(main).size() == 2, "툴팁 %s가 떠 있는 동안 10초 뒤 토스트가 %s다" % [main.hud.tip.visible, _toasts(main)])
	if out == "":
		_move(EMPTY)
		main.hud.tip._process(0.3)
		toasts._process(4.1)
		out = check(mine.call().is_empty(), "툴팁을 닫고 4.1초 뒤에도 «시험 경보»가 있다(%s)" % [_toasts(main)])
	_done(main)
	return out

# EV333 · S185: 메뉴 칸을 누르면 ESC 메뉴가 열리고 트리가 멈춘다
func ev333():
	var main = _prep()
	var cells = main.hud.get("cells")
	if not cells is Dictionary or not cells.get("menu") is BaseButton:
		_done(main)
		return "main.hud.cells.menu 버튼이 없다"
	cells.menu.pressed.emit()
	var out := check(_button(main, "계속") != null and main.get_tree().paused, "메뉴 칸을 누른 뒤 «계속» %s · 트리 멈춤 %s" % [_button(main, "계속"), main.get_tree().paused])
	_done(main)
	return out

# EV334 · S185: 전투 단계 공병 칸은 놀고 있는 공병 수이고 0이면 빨갛다. 툴팁은 «놀고 있는 공병 N · 전체 M», 누르면 그 공병에게 카메라가 간다(I164)
func ev334():
	var main = _prep()
	var cells = main.hud.get("cells")
	if not cells is Dictionary:
		_done(main)
		return "main.hud.cells가 없다"
	var b = main.view.battle
	var ws = b.build("workshop", _near(b, "workshop", b.base.cell))
	b.start_battle()
	_frame(main)
	var n: Label = null
	for l in cells.engineer.find_children("*", "Label", true, false):
		n = l
	var out := check(ws != null and n != null, "작업장 %s · 공병 칸 Label %s" % [ws, n])
	if out == "" and (n.text != "0" or not n.get_theme_color("font_color").is_equal_approx(DANGER)):
		out = "공병 0인 전투 단계 공병 칸 글 «%s» · 색 %s" % [n.text, n.get_theme_color("font_color")]
	var e = b.recruit(ws, "engineer") if out == "" else null
	if out == "":
		main.hud._process(0.0)
		if e == null:
			out = "작업장에서 공병을 사지 못했다"
		elif n.text != "1" or n.get_theme_color("font_color").is_equal_approx(DANGER):
			out = "공병을 산 뒤 공병 칸 글 «%s» · 색 %s" % [n.text, n.get_theme_color("font_color")]
	if out == "":
		_fresh(main.hud.tip, cells.engineer)
		main.hud.tip._process(0.25)
		out = check("놀고 있는 공병 1 · 전체 1" in _tip_text(main.hud.tip), "공병 칸 툴팁이 «%s»다" % _tip_text(main.hud.tip))
	if out == "":
		var cam = _cam(main)
		cam.zoom_at(2 - cam.level, Vector2(320, 180))
		_away(main)
		cells.engineer.pressed.emit()
		out = _focused(main, e.pos * 16 + Vector2(8, 8))
	_done(main)
	return out

const ENEMY := {"basic": "기본", "fast": "빠름", "armored": "장갑", "flying": "비행", "boss": "보스"}  # S106
const SIDES := ["왼쪽", "가운데", "오른쪽"]  # S188: 시험 스테이지 출현 지점 차례

# 웨이브 데이터(라운드 r·웨이브 w)의 적 수
func _wave_total(b, r: int, w: int) -> int:
	return b.rounds[r][w].reduce(func(n, e): return n + e.count, 0)

func _count(d: Dictionary) -> int:
	return d.values().reduce(func(n, x): return n + x, 0)

# EV335 · S188: 1~6라운드 웨이브마다 출현 지점별 미리보기 수가 실제로 그 지점에서 나온 적의 종류별 수와 같다
func ev335():
	var b = _new(load("res://src/main.gd").stage())
	if not b.has_method("spawn_counts"):
		return "battle.spawn_counts가 없다"
	var got := []
	b.enemy_spawned.connect(func(e): got.append([e.kind, cell_of(e)]))
	for r in b.rounds.size():
		for w in b.rounds[r].size():
			b.round_index = r
			b.waves = b.rounds[r]
			b.wave_index = w
			b.state = "prep"
			var want: Array = b.spawn_counts(r, w)
			var total := _wave_total(b, r, w)
			if want.size() != b.spawns.size() or want.reduce(func(n, d): return n + _count(d), 0) != total:
				return "%d라운드 %d웨이브 미리보기 %s의 합이 데이터 적 수 %d와 다르다" % [r + 1, w + 1, want, total]
			got.clear()
			b.start_battle()
			for i in total + 3:
				b.step(b.SPAWN_GAP)
				kill_all(b)
			var real: Array = b.spawns.map(func(_c): return {})
			for g in got:
				var d: Dictionary = real[b.spawns.find(g[1])]
				d[g[0]] = d.get(g[0], 0) + 1
			for i in want.size():
				if want[i].size() != real[i].size() or want[i].keys().any(func(k): return real[i].get(k, -1) != want[i][k]):
					return "%d라운드 %d웨이브 %s 출현 지점: 미리보기 %s · 실제 %s" % [r + 1, w + 1, b.spawns[i], want, real]
	return ""

# EV336 · I13: 진행 칸은 영입 «영입»·«다음 적 N» → 준비 «전투 시작»(누르면 전투) → 전투 «남은 적 N» → 패배 «패배»다
func ev336():
	var main = _game()
	_frame(main)
	var b = main.view.battle
	var cells = main.hud.get("cells")
	var start = main.hud.get("start")
	if not cells is Dictionary or not start is BaseButton:
		_done(main)
		return "main.hud.cells나 main.hud.start 버튼이 없다"
	var n := _wave_total(b, 0, 0)
	var text := func(): return " ".join(_labels(cells.progress))
	var out := check(b.state == "hiring" and "영입" in text.call() and "다음 적 %d" % n in text.call(), "영입 창(%s) 진행 칸 글이 «%s»다(기대 «영입»·«다음 적 %d»)" % [b.state, text.call(), n])
	if out == "":
		b.gold = BIG
		for i in 2:
			b.hire(i)
		b.next_round()
		_frame(main)
		if not start.is_visible_in_tree() or not "전투 시작" in " ".join(_labels(start)):
			out = "준비 단계 전투 시작 버튼 보임 %s · 글 %s" % [start.is_visible_in_tree(), _labels(start)]
	if out == "":
		start.pressed.emit()
		out = check(b.state == "battle", "전투 시작 버튼을 누른 뒤 판이 %s다" % b.state)
	if out == "":
		main.hud._process(0.0)
		if start.is_visible_in_tree() or not "남은 적 %d" % n in text.call() or "전투 시작" in text.call():
			out = "전투 단계 전투 시작 버튼 보임 %s · 진행 칸 글 «%s»(기대 «남은 적 %d», «전투 시작» 없음)" % [start.is_visible_in_tree(), text.call(), n]
	if out == "":
		b.damage(b.base, BIG)
		main.hud._process(0.0)
		out = check(b.state == "lost" and "패배" in text.call(), "패배(%s) 진행 칸 글이 «%s»다" % [b.state, text.call()])
	_done(main)
	return out

# EV337 · S188: 준비 단계 진행 칸에 «적 N», 웨이브 버튼 툴팁에 출현 지점별 종류·수, 화면 밖 출현 지점은 아래 가장자리 표식, 보스 웨이브면 해골과 토스트
func ev337():
	var main = _prep()
	var b = main.view.battle
	var cells = main.hud.get("cells")
	var gauge = main.hud.get("gauge")
	var edges = main.hud.get("edges")
	if not cells is Dictionary or not gauge is BaseButton or edges == null or main.hud.get("skull") == null or not b.has_method("spawn_counts"):
		_done(main)
		return "main.hud.cells·gauge 버튼·edges·skull이나 battle.spawn_counts가 없다"
	var want: Array = b.spawn_counts(0, 0)
	var n := _wave_total(b, 0, 0)
	var out := check("적 %d" % n in " ".join(_labels(cells.progress)), "준비 단계 진행 칸 글 %s에 «적 %d»가 없다" % [_labels(cells.progress), n])
	if out == "":
		_fresh(main.hud.tip, gauge)
		main.hud.tip._process(0.25)
		var lines := []  # 툴팁 Label마다 줄로 나눈다. 한 줄로 이으면 이름 줄이 첫 출현 지점 줄 앞에 붙는다
		for l in main.hud.tip.find_children("*", "Label", true, false):
			if l.is_visible_in_tree():
				lines.append_array(l.text.split("\n"))
		for i in want.size():
			var line := ""
			for l in lines:
				if l.strip_edges().begins_with(SIDES[i]):
					line = l
			var miss: Array = want[i].keys().filter(func(k): return not "%s %d" % [ENEMY[k], want[i][k]] in line)
			if line == "" or not miss.is_empty():
				out = "웨이브 버튼 툴팁 «%s»의 %s 줄에 %s가 없다(미리보기 %s)" % [_tip_text(main.hud.tip), SIDES[i], miss, want[i]]
				break
		_move(EMPTY)
		main.hud.tip._process(0.3)
	if out == "" and (main.hud.skull.is_visible_in_tree() or _toasts(main).any(func(t): return "보스" in t)):
		out = "보스 없는 첫 웨이브인데 해골 %s · 토스트 %s" % [main.hud.skull.is_visible_in_tree(), _toasts(main)]
	var cam = _cam(main)
	if out == "":
		cam.zoom_at(0 - cam.level, Vector2(320, 180))
		cam.pan(Vector2(0, -1), 100.0)
		cam.force_update_scroll()
		main.hud._process(0.0)
		var shown: Array = edges.get_children().filter(func(m): return m.is_visible_in_tree())
		var nums := shown.map(func(m): return int(" ".join(_labels(m))))
		nums.sort()
		var sums := want.map(func(d): return _count(d))
		sums.sort()
		var area := Rect2(30, 344, 470, 12)
		if shown.size() != b.spawns.size() or nums != sums or shown.any(func(m): return not area.encloses(m.get_global_rect().grow(-0.01))):
			out = "1배 줌 맨 위: 표식 %d개(기대 %d) · 수 %s(기대 %s) · 자리 %s" % [shown.size(), b.spawns.size(), nums, sums, shown.map(func(m): return m.get_global_rect())]
	if out == "":
		cam.pan(Vector2(0, 1), 100.0)
		cam.force_update_scroll()
		main.hud._process(0.0)
		var shown: Array = edges.get_children().filter(func(m): return m.is_visible_in_tree())
		out = check(shown.is_empty(), "1배 줌 맨 아래인데 표식이 %d개 보인다" % shown.size())
	var bosses: Array = range(1, b.waves.size()).filter(func(w): return b.waves[w].any(func(e): return e.kind == "boss"))
	if out == "" and bosses.is_empty():
		out = "1라운드에 첫 웨이브가 아닌 보스 웨이브가 없다"
	if out == "":
		b.state = "battle"
		main.hud._process(0.0)
		b.wave_index = bosses[0]
		b.state = "prep"
		main.hud._process(0.0)
		main.hud.toasts._process(3.6)  # 미션 토스트가 막 떠서 3.5초 줄을 선다(I163)
		var said := _toasts(main).filter(func(t): return "다음 웨이브에 보스" in t)
		out = check(main.hud.skull.is_visible_in_tree() and said.size() == 1, "보스 웨이브 준비 단계: 해골 %s · 토스트 %s" % [main.hud.skull.is_visible_in_tree(), _toasts(main)])
	_done(main)
	return out

# EV338 · I13: 전투 중 진행 칸을 누르면 거점에 가장 가까운 적에게 카메라가 간다(I164)
func ev338():
	var main = _prep()
	var b = main.view.battle
	var gauge = main.hud.get("gauge")
	if not gauge is BaseButton:
		_done(main)
		return "main.hud.gauge 버튼이 없다"
	b.start_battle()
	b.spawn_enemy("basic", Vector2i(6, 25))
	var near = b.spawn_enemy("basic", Vector2i(20, 14))
	main.hud._process(0.0)
	var cam = _cam(main)
	cam.zoom_at(2 - cam.level, Vector2(320, 180))
	_away(main)
	gauge.pressed.emit()
	var out := _focused(main, near.pos * 16 + Vector2(8, 8))
	_done(main)
	return out

# 칸의 보이는 글: 버튼 글과 보이는 자식 Label
func _shown(c) -> String:
	return " ".join([c.text] + _labels(c))

# EV339 · I151: 준비 단계 Q는 칸 글자·흰색, 잠긴 R은 어둡고 자물쇠(«Lv» 글 없음), Q를 누르면 «전투 단계에만» 토스트,
# 재사용 대기면 올림한 초, 마나가 모자라면 파란 틴트
func ev339():
	var main = _prep()
	var slots = main.hud.get("slots")
	if not slots is Array or slots.is_empty() or not slots[0] is Dictionary or not slots[0].get("q") is BaseButton \
			or not slots[0].get("r") is BaseButton or not slots[0]["r"].get("lock") is CanvasItem:
		_done(main)
		return "main.hud.slots[0]의 q·r 스킬 칸이나 칸의 lock이 없다"
	var h = main.view.battle.heroes[0]
	var q: BaseButton = slots[0]["q"]
	var r: BaseButton = slots[0]["r"]
	main.hud._process(0.0)
	var out := ""
	if q.text != "Q" or not q.self_modulate.is_equal_approx(Color.WHITE):
		out = "준비 단계 Q 칸 글이 «%s», self_modulate가 %s다(기대 «Q»·흰색)" % [q.text, q.self_modulate]
	elif not r.self_modulate.is_equal_approx(Color(0.4, 0.4, 0.4)) or not r.lock.is_visible_in_tree() or "Lv" in _shown(r):
		out = "Lv%d 영웅의 R 칸: self_modulate %s · 자물쇠 %s · 글 «%s»(기대 (0.4,0.4,0.4)·보임·«Lv» 없음)" % [h.level, r.self_modulate, r.lock.is_visible_in_tree(), _shown(r)]
	if out == "":
		main.hud.toasts._process(3.6)  # 미션 토스트가 막 떠서 3.5초 줄을 선다(I163)
		q.pressed.emit()
		out = check(_toasts(main).any(func(t): return "전투 단계에만" in t), "준비 단계에 Q 칸을 누른 뒤 토스트가 %s다" % [_toasts(main)])
	if out == "":
		h.cd["q"] = 3.2
		main.hud._process(0.0)
		var s := _shown(q)
		out = check("4" in s and not "3" in s, "재사용 대기 3.2초인 Q 칸 글이 «%s»다(기대 «4», «3» 없음)" % s)
	if out == "":
		h.cd["q"] = 0.0
		h.mana = 0.0
		main.hud._process(0.0)
		out = check(q.self_modulate.is_equal_approx(Color(0.5, 0.5, 1.0)), "마나 0인 Q 칸 self_modulate가 %s다(기대 (0.5,0.5,1))" % q.self_modulate)
	_done(main)
	return out

# EV340 · I165: F1을 0.6초 간격으로 두 번 넣으면 카메라가 그대로이고, 0.4초 안에 두 번이면 첫 영웅에게 간다. 초상을 누르면 그 영웅을 고르고, 두 번이면 카메라가 간다
func ev340():
	var main = _prep()
	var b = main.view.battle
	var faces = main.hud.get("portraits")
	if not faces is Array or faces.size() < 2 or not faces[1] is BaseButton:
		_done(main)
		return "main.hud.portraits가 없다"
	var cam = _cam(main)
	cam.zoom_at(2 - cam.level, Vector2(320, 180))
	_away(main)
	var at: Vector2 = cam.position
	_key(KEY_F1)
	main.hud._process(0.6)
	_key(KEY_F1)
	var out := ""
	if not cam.position.is_equal_approx(at) or main.controls.selected != [b.heroes[0]]:
		out = "F1을 0.6초 간격으로 두 번: 카메라 %s → %s, 고른 것 %s(기대 그대로·첫 영웅)" % [at, cam.position, main.controls.selected]
	if out == "":
		main.hud._process(0.3)
		_key(KEY_F1)
		out = _focused(main, b.heroes[0].pos * 16 + Vector2(8, 8))
	if out == "":
		_away(main)
		faces[1].pressed.emit()
		out = check(main.controls.selected == [b.heroes[1]], "둘째 초상을 누르자 고른 것이 %s다" % [main.controls.selected])
	if out == "":
		main.hud._process(0.2)
		faces[1].pressed.emit()
		out = _focused(main, b.heroes[1].pos * 16 + Vector2(8, 8))
	_done(main)
	return out

# EV341 · I129: 출전 1·2·3명 모두 영웅 칸 셋이 같은 자리에 보이고 초상은 출전 수만큼이다. 쓰러진 영웅 칸에 «쓰러짐», 스킬 칸은 숨는다
func ev341():
	var out := ""
	for n in [1, 2, 3]:
		var main = _game()
		var b = main.view.battle
		b.gold = BIG
		for i in 3:
			b.hire(i)
		for h in b.roster.slice(n):
			b.set_lineup(h, false)
		b.next_round()
		_frame(main)
		var cells = main.hud.get("cells")
		var faces = main.hud.get("portraits")
		var slots = main.hud.get("slots")
		if not cells is Dictionary or not faces is Array or faces.size() != 3 or not slots is Array or slots.size() != 3:
			out = "main.hud.cells·portraits·slots가 없거나 칸이 셋이 아니다"
		elif b.heroes.size() != n:
			out = "출전 %d명으로 두었는데 전장 영웅이 %d명이다" % [n, b.heroes.size()]
		for i in 3:
			if out != "":
				break
			var k := "hero%d" % i
			var r: Rect2 = cells[k].get_global_rect()
			if not cells[k].is_visible_in_tree() or r.position.distance_to(BAR[k].position) > 0.5 or r.size.distance_to(BAR[k].size) > 0.5:
				out = "출전 %d명: %s 칸 %s · 보임 %s(기대 %s)" % [n, k, r, cells[k].is_visible_in_tree(), BAR[k]]
			elif faces[i].is_visible_in_tree() != (i < n):
				out = "출전 %d명: %d번 초상 보임이 %s다" % [n, i, faces[i].is_visible_in_tree()]
		if out == "" and n == 2:
			b.start_battle()
			b.damage(b.heroes[0], BIG, "true")
			main.hud._process(0.0)
			var seen := " ".join(_labels(cells.hero0))
			var shown: Array = slots[0].values().filter(func(s): return s.is_visible_in_tree())
			if b.heroes[0].alive or not "쓰러짐" in seen or not shown.is_empty():
				out = "쓰러진 첫 영웅 칸: 살아 있음 %s · 글 «%s» · 보이는 스킬 칸 %d" % [b.heroes[0].alive, seen, shown.size()]
		_done(main)
		if out != "":
			break
	return out

# 태그(I139)의 상태 그림: 안의 첫 TextureRect의 [텍스처, modulate]
func _look(tag) -> Array:
	var pics: Array = tag.find_children("*", "TextureRect", true, false)
	return [pics[0].texture, pics[0].modulate] if not pics.is_empty() else [null, null]

# 태그에 커서를 0.25초 두었을 때 툴팁 글. 뜨지 않으면 ""
func _tag_tip(tip, tag) -> String:
	_fresh(tip, tag)
	tip._process(0.25)
	return _tip_text(tip) if tip.visible else ""

# EV342 · I139: 용병을 고르면 오른쪽 가장자리 [616,182]·[616,208]에 글 없는 그림 태그 A·H가 뜨고, 상태 글은 툴팁이며, 누르면 A·H 키와 같고, 용병을 놓으면 숨는다
func ev342():
	var main = _prep()
	var b = main.view.battle
	var c = main.hud.controls
	var tip = main.hud.tip
	var tags = main.hud.get("tags")
	if not tags is Array or tags.size() != 2 or not tags[0] is BaseButton or not tags[1] is BaseButton:
		_done(main)
		return "main.hud.tags가 BaseButton 둘이 아니다"
	var m1 = b.place_merc("soldier", Vector2i(20, 14))
	var m2 = b.place_merc("soldier", Vector2i(21, 14))
	if m1 == null or m2 == null:
		_done(main)
		return "준비 단계에 용병을 놓지 못했다"
	b.set_move_mode([m1, m2], "attack_move")
	b.set_hold([m1, m2], false)
	c.selected = [m1]
	main.hud._process(0.0)
	var out := ""
	for i in 2:
		var r: Rect2 = tags[i].get_global_rect()
		var want := Rect2(616, 182 + 26 * i, 24, 24)
		var key: String = "AH"[i]
		if not tags[i].is_visible_in_tree() or r.position.distance_to(want.position) > 0.5 or r.size.distance_to(want.size) > 0.5:
			out = "%s 태그 %s · 보임 %s(기대 %s)" % [key, r, tags[i].is_visible_in_tree(), want]
		elif tags[i].text != "" or " ".join(_labels(tags[i])) != key or _look(tags[i])[0] == null:
			out = "%s 태그: 버튼 글 «%s» · 보이는 글 %s · 그림 %s(기대: 버튼 글 없음, 보이는 글은 키 글자 하나, 그림 있음)" % [key, tags[i].text, _labels(tags[i]), _look(tags[i])[0]]
		if out != "":
			break
	var attack := _look(tags[0])
	var off := _look(tags[1])
	if out == "":
		var said := _tag_tip(tip, tags[0])
		if not "이동 중 공격" in said or "무조건 이동" in said:
			out = "이동 중 공격인 용병의 A 태그 툴팁이 «%s»다" % said
	if out == "":
		tags[0].pressed.emit()
		main.hud._process(0.0)
		var said := _tag_tip(tip, tags[0])
		if m1.move_mode != "move" or _look(tags[0]) == attack or not "무조건 이동" in said or "이동 중 공격" in said:
			out = "A 태그를 누른 뒤: 이동 방식 %s · 그림이 그대로 %s · 툴팁 «%s»" % [m1.move_mode, _look(tags[0]) == attack, said]
	if out == "":
		_key(KEY_A)
		main.hud._process(0.0)
		out = check(m1.move_mode == "attack_move" and _look(tags[0]) == attack, "A 키를 넣자 이동 방식이 %s · 그림이 처음과 같음 %s다(태그를 누른 것과 A 키가 같은 전환이 아니다)" % [m1.move_mode, _look(tags[0]) == attack])
	if out == "":
		tags[1].pressed.emit()
		main.hud._process(0.0)
		var said := _tag_tip(tip, tags[1])
		if not m1.hold or _look(tags[1]) == off or not "홀드 켬" in said or "홀드 끔" in said:
			out = "H 태그를 누른 뒤: 홀드 %s · 그림이 그대로 %s · 툴팁 «%s»" % [m1.hold, _look(tags[1]) == off, said]
	if out == "":
		b.set_move_mode([m2], "move")
		c.selected = [m1, m2]
		main.hud._process(0.0)
		var said_a := _tag_tip(tip, tags[0])
		var said_h := _tag_tip(tip, tags[1])
		if not "섞임" in said_a or not "섞임" in said_h or _look(tags[0]) == attack:
			out = "상태가 섞인 두 용병: A 툴팁 «%s» · H 툴팁 «%s» · A 그림이 이동 중 공격과 같음 %s" % [said_a, said_h, _look(tags[0]) == attack]
	if out == "":
		c.selected = []
		main.hud._process(0.0)
		out = check(not tags[0].is_visible_in_tree() and not tags[1].is_visible_in_tree(), "용병을 놓았는데 태그가 보인다")
	_done(main)
	return out

# 팝업 안의 보이는 버튼
func _pops(main) -> Array:
	return main.hud.popup.find_children("*", "BaseButton", true, false).filter(func(n): return n.is_visible_in_tree())

# 맵 칸의 화면 사각형
func _screen_cell(main, cell: Vector2i) -> Rect2:
	return main.hud.map.get_canvas_transform() * Rect2(Vector2(cell) * CELL_PX, Vector2(CELL_PX, CELL_PX))

# 팝업 버튼 b에 커서를 0.25초 두었을 때 툴팁 빨간 줄 글. 숨어 있으면 ""
func _pop_why(main, btn) -> String:
	_layout(main)
	_fresh(main.hud.tip, btn)
	main.hud.tip._process(0.25)
	var r = main.hud.tip.reason
	return r.text if main.hud.tip.visible and r.is_visible_in_tree() else ""

# EV343 · I137: 화면 네 구석(오른쪽 아래는 건설 격자 왼쪽)과 정보 칸 바로 위의 용병을 누르면 판매 팝업이 화면 안에 뜨고
# 위 띠·건설 격자·정보 칸·태그·고른 칸 사각형과 겹치지 않는다
func ev343():
	var main = _prep()
	if not main.hud.get("popup") is Control:
		_done(main)
		return "main.hud.popup이 없다"
	var b = main.view.battle
	var c = main.controls
	var hud = main.hud
	var cam = _cam(main)  # 1배 줌, 화면이 맵 [0,0,640,360]을 보이게
	cam.zoom_at(-1, Vector2(320, 180))
	cam.position = Vector2(320, 180)
	cam.force_update_scroll()
	var out := ""
	# 네 구석(오른쪽 아래는 건설 격자 왼쪽), 정보 칸 위·안, 태그 왼쪽, 화면 가운데 왼쪽 위(팝업이 바깥쪽 = 왼쪽 위에 붙는지도 본다)
	for s in [Vector2(24, 40), Vector2(616, 40), Vector2(24, 344), Vector2(500, 344), Vector2(600, 220), Vector2(600, 248), Vector2(568, 190), Vector2(200, 120)]:
		var cell := Vector2i((hud.map.get_canvas_transform().affine_inverse() * s / CELL_PX).floor())
		var m = b.place_merc("soldier", cell)
		if m == null:
			out = "화면 %s 칸 %s에 용병을 놓지 못했다" % [s, cell]
			break
		click(c, MOUSE_BUTTON_LEFT, px(cell))
		_frame(main)
		hud.grid._process(0.0)
		var r: Rect2 = hud.popup.get_global_rect()
		var avoid := {"위 띠": Rect2(0, 0, 640, 30), "건설 격자": Rect2(510, 288, 130, 72), "고른 칸": _screen_cell(main, cell)}
		if hud.grid.info.is_visible_in_tree():
			avoid["정보 칸"] = hud.grid.info.get_global_rect()
		for i in hud.tags.size():
			if hud.tags[i].is_visible_in_tree():
				avoid["태그 %d" % i] = hud.tags[i].get_global_rect()
		if _pops(main).is_empty():
			out = "화면 %s의 용병을 눌렀는데 팝업 버튼이 없다(판매 후보 %s)" % [s, c.selling]
		elif not Rect2(0, 0, 640, 360).encloses(r):
			out = "화면 %s의 용병 팝업 %s가 화면 밖으로 나간다" % [s, r]
		for k in avoid:
			if out == "" and avoid[k].intersects(r):
				out = "화면 %s의 용병 팝업 %s가 %s %s와 겹친다" % [s, r, k, avoid[k]]
		if out == "" and s == Vector2(200, 120) and (r.end.x > avoid["고른 칸"].position.x or r.end.y > avoid["고른 칸"].position.y):
			out = "화면 가운데 왼쪽 위 용병의 팝업 %s가 고른 칸 %s의 왼쪽 위(바깥쪽)에 있지 않다" % [r, avoid["고른 칸"]]
		if out != "":
			break
		b.sell([m])
		_frame(main)
	_done(main)
	return out

# EV344 · I128: 성문이 닫혀 마을 안 공병이 들판에 닿지 못하는 전투 단계에서 들판 타워의 철거 버튼은 어둡고 괄호 글이 없으며,
# 이유 «닿는 공병 없음»은 툴팁과 정보 칸의 빨간 줄에 있다. 그때 놓기 모드로 들판 빈 칸을 누르면 안내 줄이 1.5초 «닿는 공병 없음»이다
func ev344():
	var main = _prep()
	var hud = main.hud
	if not hud.get("popup") is Control or not hud.get("hint") is Label:
		_done(main)
		return "main.hud.popup·hint가 없다"
	var b = main.view.battle
	var c = main.controls
	var e = b.place_merc("engineer", Vector2i(10, 4))  # 마을. 성문은 닫힌 채 시작한다(I67)
	var t = b.build("tower", Vector2i(10, 14))
	if e == null or t == null:
		_done(main)
		return "준비 단계에 공병(%s)이나 타워(%s)를 놓지 못했다" % [e, t]
	b.start_battle()
	_frame(main)
	click(c, MOUSE_BUTTON_LEFT, px(t.cell))
	_frame(main)
	var gone = _button(hud.popup, "철거")
	var out := ""
	if b.engineer_gap([t.cell]) != "far":
		out = "준비가 틀렸다: 타워 칸의 공병 사정이 «%s»다(«far»여야 한다)" % b.engineer_gap([t.cell])
	elif gone == null or not gone.disabled:
		out = "닿는 공병이 없는데 «철거» 버튼이 %s다(눌림 %s)" % [gone, gone != null and not gone.disabled]
	elif _pops(main).any(func(n): return "(" in n.text):
		out = "팝업 버튼 글에 괄호가 있다: %s" % [_pops(main).map(func(n): return n.text)]
	if out == "":
		var said := _pop_why(main, gone)
		hud.grid._process(0.0)
		var info: String = hud.grid.reason.text if hud.grid.reason.is_visible_in_tree() else ""
		if not "닿는 공병 없음" in said or not "닿는 공병 없음" in info:
			out = "철거 버튼 툴팁 빨간 줄 «%s» · 정보 칸 빨간 줄 «%s»(둘 다 «닿는 공병 없음»이어야 한다)" % [said, info]
	if out == "":
		c.picked = []
		_key(KEY_2)
		click(c, MOUSE_BUTTON_LEFT, px(Vector2i(12, 14)))
		hud._process(0.0)
		var now: String = hud.hint.text if hud.hint.is_visible_in_tree() else ""
		hud._process(1.6)
		if c.placing != "tower" or b.structures.has(Vector2i(12, 14)) or not "닿는 공병 없음" in now or "닿는 공병 없음" in hud.hint.text:
			out = "놓기 모드 «%s» · 지어짐 %s · 누른 직후 안내 줄 «%s» · 1.6초 뒤 «%s»" % [c.placing, b.structures.has(Vector2i(12, 14)), now, hud.hint.text]
	_done(main)
	return out

# EV359 · I128: 준비 단계 타워 놓기가 구역·골드로 거부되면 안내 줄이 첫 이유다. ESC로 놓기 모드를 꺼도 안내 칩은 1.5초 이유를 남긴다
func ev359():
	var main = _prep()
	var hud = main.hud
	if not hud.get("hint") is Label or not hud.get("chip") is Control:
		_done(main)
		return "main.hud.hint·chip이 없다"
	var b = main.view.battle
	var c = main.controls
	var walls: Array = b.castle.keys().filter(func(k): return b.castle[k].kind == "castle_wall")
	if walls.is_empty():
		_done(main)
		return "성벽 칸(castle_wall)이 없다"
	var built: int = b.structures.size()
	_key(KEY_2)
	var said := []  # 칸을 누른 직후 안내 줄 글
	for cell in [Vector2i(10, 4), walls[0]]:
		click(c, MOUSE_BUTTON_LEFT, px(cell))
		hud._process(0.0)
		said.append(hud.hint.text)
	b.gold = 10
	click(c, MOUSE_BUTTON_LEFT, px(Vector2i(12, 14)))
	hud._process(0.0)
	said.append(hud.hint.text)
	var poor := "골드 %d 모자람" % (b.STRUCTURE_KINDS.tower.cost - 10)
	var out := ""
	if b.structures.size() != built:
		out = "거부되어야 할 놓기가 지어졌다(구조물 %d → %d)" % [built, b.structures.size()]
	elif not "성 안에는 마을 시설만" in said[0] or not "성곽에는 대포만" in said[1] or not poor in said[2]:
		out = "누른 직후 안내 줄 %s(기대: «성 안에는 마을 시설만»·«성곽에는 대포만»·«%s»)" % [said, poor]
	if out == "":
		_key(KEY_ESCAPE)
		hud._process(0.0)
		var kept: bool = hud.chip.is_visible_in_tree() and poor in hud.hint.text
		var mode: String = c.placing
		hud._process(1.6)
		out = check(mode == "" and kept and not hud.chip.is_visible_in_tree(),
			"ESC 뒤 놓기 모드 «%s» · 칩에 이유 남음 %s(글 «%s») · 1.6초 뒤 칩 보임 %s" % [mode, kept, hud.hint.text, hud.chip.is_visible_in_tree()])
	_done(main)
	return out

# EV345 · I124: 막힌 성문의 «닫기», 쿨타임 중인 성문 버튼(I123), 전투 단계의 교회 치료 버튼(I140)은 어둡고 글에 괄호가 없으며 이유는 툴팁 빨간 줄에 있다
func ev345():
	var main = _prep()
	var hud = main.hud
	if not hud.get("popup") is Control:
		_done(main)
		return "main.hud.popup이 없다"
	var b = main.view.battle
	var c = main.controls
	var g = b.castle[Vector2i(20, 9)]  # 정문
	b.set_gate(g, true)
	var m = b.place_merc("soldier", g.cell)
	var church = b.build("church", Vector2i(5, 4))
	var h = b.heroes[0]
	b.damage(h, 10, "true")
	if not g.open or m == null or church == null or h.hp >= h.max_hp:
		_done(main)
		return "준비가 틀렸다: 정문 열림 %s · 정문 위 용병 %s · 교회 %s · 영웅 체력 %s/%s" % [g.open, m, church, h.hp, h.max_hp]
	var out := ""
	click(c, MOUSE_BUTTON_LEFT, px(g.cell))
	_frame(main)
	var shut = _button(hud.popup, "닫기")
	if shut == null or not shut.disabled or _pops(main).any(func(n): return "(" in n.text):
		out = "용병이 선 열린 정문 팝업: «닫기» %s · 눌림 %s · 글 %s" % [shut, shut != null and not shut.disabled, _pops(main).map(func(n): return n.text)]
	elif not "칸 막힘" in _pop_why(main, shut):
		out = "막힌 «닫기» 툴팁 빨간 줄이 «%s»다" % _pop_why(main, shut)
	if out == "":
		b.sell([m])
		b.start_battle()
		b.set_gate(g, false)
		c.fort = null
		click(c, MOUSE_BUTTON_LEFT, px(g.cell))
		_frame(main)
		var want := "열기 %d초" % ceili(g.lock)
		var lock = _button(hud.popup, want)
		if g.open or g.lock <= 0.0 or lock == null or not lock.disabled or _pops(main).any(func(n): return "(" in n.text):
			out = "쿨타임 중인 정문 팝업: «%s» %s · 글 %s(닫힘 %s, 쿨타임 %s)" % [want, lock, _pops(main).map(func(n): return n.text), not g.open, g.lock]
		elif _pop_why(main, lock) == "":
			out = "쿨타임 중인 성문 버튼 툴팁에 빨간 줄이 없다"
	if out == "":
		click(c, MOUSE_BUTTON_LEFT, px(church.cell))
		_frame(main)
		var heal = _starts(hud.popup, "치료 " + hud.HEROES[h.kind].get_slice("(", 0))
		if heal == null or not heal.disabled or _pops(main).any(func(n): return "(" in n.text):
			out = "전투 단계 교회 팝업: 치료 버튼 %s · 버튼 %s(치료는 어둡고, 글에 괄호가 없어야 한다)" % [heal, _pops(main).map(func(n): return [n.text, n.disabled])]
		elif not "준비 단계에만" in _pop_why(main, heal):
			out = "전투 단계 치료 버튼 툴팁 빨간 줄이 «%s»다" % _pop_why(main, heal)
	_done(main)
	return out

# EV346 · S74: 철거는 첫 클릭에 «철거?»가 되고 2초 안에 다시 누르면 철거 지시가 나간다. 다른 것을 고르거나 2초가 지나면 «철거»로 돌아가 다시 첫 클릭이다
func ev346():
	var main = _prep()
	var hud = main.hud
	if not hud.get("popup") is Control:
		_done(main)
		return "main.hud.popup이 없다"
	var b = main.view.battle
	var c = main.controls
	var es := [b.place_merc("engineer", Vector2i(12, 14)), b.place_merc("engineer", Vector2i(12, 15))]
	var t1 = b.build("tower", Vector2i(10, 14))
	var t2 = b.build("tower", Vector2i(14, 14))
	var t3 = b.build("tower", Vector2i(16, 14))
	if null in es or t1 == null or t2 == null or t3 == null:
		_done(main)
		return "준비 단계에 공병 %s나 타워(%s, %s, %s)를 놓지 못했다" % [es, t1, t2, t3]
	b.start_battle()
	_frame(main)
	click(c, MOUSE_BUTTON_LEFT, px(t1.cell))
	_frame(main)
	var out := ""
	var d = _button(hud.popup, "철거")
	if d == null or d.disabled:
		out = "전투 단계에 타워를 눌렀는데 누를 수 있는 «철거» 버튼이 없다(%s)" % [d]
	if out == "":
		d.pressed.emit()
		hud._process(0.0)
		if t1.worker != null or _button(hud.popup, "철거?") == null:
			out = "«철거»를 한 번 누른 뒤 철거 공병 %s · «철거?» 버튼 %s" % [t1.worker, _button(hud.popup, "철거?")]
	if out == "":
		hud._process(1.0)
		_button(hud.popup, "철거?").pressed.emit()
		hud._process(0.0)
		out = check(t1.worker in es, "1초 뒤 «철거?»를 눌렀는데 철거 지시가 없다")
	if out == "":  # 둘째 타워에서 한 번 누르고 0.5초 뒤 셋째 타워를 고르면 첫 클릭부터다
		click(c, MOUSE_BUTTON_LEFT, px(t2.cell))
		_frame(main)
		_button(hud.popup, "철거").pressed.emit()
		hud._process(0.5)
		click(c, MOUSE_BUTTON_LEFT, px(t3.cell))
		_frame(main)
		var other = _button(hud.popup, "철거")
		if other == null:
			out = "둘째 타워에서 «철거»를 누르고 셋째 타워를 고르자 버튼 글이 %s다(«철거»여야 한다)" % [_pops(main).map(func(n): return n.text)]
		else:
			other.pressed.emit()
			hud._process(0.0)
			if t2.worker != null or t3.worker != null or _button(hud.popup, "철거?") == null:
				out = "셋째 타워에서 한 번 누르자 철거 공병 %s·%s · «철거?» 버튼 %s(첫 클릭이어야 한다)" % [t2.worker, t3.worker, _button(hud.popup, "철거?")]
	if out == "":
		hud._process(2.1)
		var back = _button(hud.popup, "철거")
		if back == null:
			out = "«철거»를 누르고 2.1초 뒤 버튼 글이 %s다(«철거»여야 한다)" % [_pops(main).map(func(n): return n.text)]
		else:
			back.pressed.emit()
			hud._process(0.0)
			out = check(t3.worker == null and _button(hud.popup, "철거?") != null, "2초 지나 다시 누르자 철거 공병 %s · «철거?» 버튼 %s(첫 클릭이어야 한다)" % [t3.worker, _button(hud.popup, "철거?")])
	_done(main)
	return out

func _shift_key(code: int) -> void:
	for down in [true, false]:
		var e := InputEventKey.new()
		e.keycode = code
		e.physical_keycode = code
		e.shift_pressed = true
		e.pressed = down
		Engine.get_main_loop().root.push_input(e, true)

func _soldiers(b) -> int:
	return b.units.filter(func(u): return u.kind == "soldier").size()

# EV347 · S81: 병영 하나인 판의 전투 단계에서 3 키는 그 병영을 고르고(구매 팝업) 카메라를 병영 쪽으로 옮기며, 다시 3이면 용병 한 명을 산다
func ev347():
	var main = _prep()
	var b = main.view.battle
	var c = main.controls
	var f = b.build("barracks", Vector2i(4, 4))
	if f == null:
		_done(main)
		return "준비 단계에 마을 (4,4)에 병영을 짓지 못했다"
	b.start_battle()
	_frame(main)
	var cam = _cam(main)
	cam.focus(Vector2(600, 450))  # 병영에서 먼 들판 오른쪽 아래
	cam.force_update_scroll()
	var gap := func(): return (main.hud.map.get_canvas_transform() * ((Vector2(f.cell) + Vector2(0.5, 0.5)) * CELL_PX)).distance_to(Vector2(320, 194))
	var far: float = gap.call()
	_key(KEY_3)
	cam.force_update_scroll()
	_frame(main)
	var near: float = gap.call()
	var out := ""
	if c.facility != f or _starts(main.hud.popup, "용병") == null or near >= far - 1.0:
		out = "3 키 뒤 고른 시설 %s(병영 %s) · «용병» 구매 버튼 %s · 병영과 화면 (320,194) 거리 %.0f → %.0f" % [c.facility, f, _starts(main.hud.popup, "용병"), far, near]
	if out == "":
		var n := _soldiers(b)
		var gold: int = b.gold
		_key(KEY_3)
		out = check(_soldiers(b) == n + 1 and b.gold == gold - b.MERC_KINDS.soldier.cost and c.facility == f, "3 키를 다시 넣자 용병 %d → %d · 골드 %d → %d(용병 값 %d) · 고른 시설 %s" % [n, _soldiers(b), gold, b.gold, b.MERC_KINDS.soldier.cost, c.facility])
	if out == "":  # 건설 격자 용병 칸은 3 키와 같다
		var n := _soldiers(b)
		main.hud.grid.cells.soldier.pressed.emit()
		out = check(_soldiers(b) == n + 1 and c.facility == f, "건설 격자 용병 칸을 누르자 용병 %d → %d · 고른 시설 %s" % [n, _soldiers(b), c.facility])
	_done(main)
	return out

# EV348 · S81: 병영이 둘이면 Shift+3이 다음 병영을 고른다(지은 차례로 돈다). 사격장이 없을 때 7 키는 고른 시설·카메라를 그대로 두고
# 정보 칸 빨간 줄에 «사격장 없음»을 보인다. 그때 건설 격자 용병 칸은 밝고 궁수 칸은 흐리다
func ev348():
	var main = _prep()
	var b = main.view.battle
	var c = main.controls
	var g = main.hud.grid
	var f1 = b.build("barracks", Vector2i(4, 4))
	var f2 = b.build("barracks", Vector2i(8, 4))
	if f1 == null or f2 == null:
		_done(main)
		return "준비 단계에 마을에 병영 둘(%s, %s)을 짓지 못했다" % [f1, f2]
	b.start_battle()
	_frame(main)
	_key(KEY_3)
	var picks := [c.facility]
	_shift_key(KEY_3)
	picks.append(c.facility)
	_shift_key(KEY_3)
	picks.append(c.facility)
	var out := ""
	if picks != [f1, f2, f1] or _soldiers(b) != 0:
		out = "3 → Shift+3 → Shift+3에 고른 시설 %s · 용병 %d명(기대 첫 병영 %s → 둘째 %s → 첫, 0명)" % [picks, _soldiers(b), f1, f2]
	if out == "":
		var cam = _cam(main)
		var pos: Vector2 = cam.position
		_key(KEY_7)
		_frame(main)
		g._process(0.0)
		var why: String = g.reason.text if g.reason.is_visible_in_tree() else ""
		if c.facility != f1 or cam.position != pos or not g.info.is_visible_in_tree() or not "사격장 없음" in why:
			out = "사격장 없이 7 키: 고른 시설 %s · 카메라 %s → %s · 정보 칸 보임 %s · 빨간 줄 «%s»" % [c.facility, pos, cam.position, g.info.is_visible_in_tree(), why]
		elif absf(g.cells.soldier.modulate.a - 1.0) > 0.01 or absf(g.cells.archer.modulate.a - 0.35) > 0.01:
			out = "전투 단계 용병 칸 불투명도 %.2f(1이어야 한다) · 궁수 칸 %.2f(0.35여야 한다)" % [g.cells.soldier.modulate.a, g.cells.archer.modulate.a]
	_done(main)
	return out

# EV349 · S147: 조준 중에는 위 띠 바로 아래 [134,30] 안내 칩이 보이고, 영웅 초상에 커서를 두어 툴팁이 뜨면 숨으며, 툴팁이 사라지면 다시 보인다
func ev349():
	var main = _game()
	var b = main.view.battle
	var hud = main.hud
	if not hud.get("chip") is Control or not hud.get("hint") is Label:
		_done(main)
		return "main.hud.chip·hint가 없다"
	b.gold = BIG
	b.offers[0] = "ignis"
	b.hire(0)
	b.next_round()
	b.start_battle()
	_frame(main)
	var h = b.heroes[0]
	h.mana = h.max_mana
	_key(KEY_F1)
	_key(KEY_Q)
	hud._process(0.0)
	var chip = hud.chip
	var r: Rect2 = chip.get_global_rect()
	var out := ""
	if main.controls.aiming != "q" or not chip.is_visible_in_tree() or r.position.distance_to(Vector2(134, 30)) > 0.5 or r.size.x < 179.5 or r.size.y > 14.5 \
			or not ("Q" in hud.hint.text and "좌클릭" in hud.hint.text):
		out = "이그니스 Q 조준 %s · 칩 보임 %s · 칩 %s(기대 [134,30] 폭 180 이상 높이 14 이하) · 글 «%s»" % [main.controls.aiming, chip.is_visible_in_tree(), r, hud.hint.text]
	if out == "":
		_fresh(hud.tip, hud.portraits[0])
		hud.tip._process(0.25)
		hud._process(0.0)
		var tipped: bool = hud.tip.visible
		var hidden: bool = not chip.is_visible_in_tree()
		_move(EMPTY)
		hud.tip._process(0.3)
		hud._process(0.0)
		if not tipped or not hidden or hud.tip.visible or not chip.is_visible_in_tree() or main.controls.aiming != "q":
			out = "초상 툴팁 뜸 %s · 그때 칩 숨음 %s · 커서를 치운 뒤 툴팁 %s · 칩 보임 %s · 조준 %s" % [tipped, hidden, hud.tip.visible, chip.is_visible_in_tree(), main.controls.aiming]
	_done(main)
	return out

# 맵 칸 가운데의 화면 위치와 카메라가 대상을 놓는 자리 (320,194)의 거리
func _off(main, cell: Vector2i) -> float:
	_cam(main).force_update_scroll()
	return (main.hud.map.get_canvas_transform() * ((Vector2(cell) + Vector2(0.5, 0.5)) * CELL_PX)).distance_to(Vector2(320, 194))

func _press_toast(main, head: String) -> bool:
	for t in main.hud.toasts.get_children():
		if t.is_visible_in_tree() and " ".join(_labels(t)).begins_with(head):
			var e := InputEventMouseButton.new()
			e.button_index = MOUSE_BUTTON_LEFT
			e.pressed = true
			t.gui_input.emit(e)
			return true
	return false

# HUD와 토스트 층의 시간을 함께 흘린다(평가는 토스트 층 _process를 따로 부른다)
func _pass(main, secs: float) -> void:
	main.hud._process(secs)
	main.hud.toasts._process(secs)

# EV350 · S189: 화면 밖 거점이 맞으면 토스트 하나와 가장자리 표식이 뜨고, 1초 뒤 또 맞아도 토스트는 그대로다. C 키는 카메라를 거점 쪽으로 옮긴다
func ev350():
	var main = _prep()
	var b = main.view.battle
	var hud = main.hud
	if not hud.get("alerts") is Control:
		_done(main)
		return "main.hud.alerts가 없다"
	b.start_battle()
	_frame(main)
	_pass(main, 10.0)  # 준비 단계 미션 토스트를 흘려 보낸다
	b.mission = ""  # 미션이 깨진 토스트가 끼지 않게(미션은 판마다 다르다)
	b.commission = ""
	_cam(main).focus(Vector2(600, 450))  # 거점이 화면 밖(위)
	_cam(main).force_update_scroll()
	b.damage(b.base, 5, "true")
	hud._process(0.0)
	var shown := _toasts(main)
	var marks: Array = hud.alerts.find_children("*", "BaseButton", true, false).filter(func(n): return n.is_visible_in_tree())
	var out := ""
	if shown.size() != 1 or not "거점 공격받음" in shown[0]:
		out = "거점 피해 뒤 토스트 %s(«거점 공격받음» 하나여야 한다)" % [shown]
	elif marks.size() != 1 or marks[0].get_global_rect().intersects(Rect2(0, 0, 640, 30)) or marks[0].get_global_rect().intersects(Rect2(510, 288, 130, 72)):
		out = "화면 밖 거점 피해 뒤 가장자리 표식 %s(하나이고 위 띠·건설 격자와 겹치지 않아야 한다)" % [marks.map(func(n): return n.get_global_rect())]
	if out == "":
		_pass(main, 1.0)
		b.damage(b.base, 5, "true")
		hud._process(0.0)
		if _toasts(main) != shown:
			out = "1초 뒤 거점이 또 맞자 토스트가 %s다(그대로 %s여야 한다)" % [_toasts(main), shown]
	if out == "":
		var far := _off(main, b.base.cell)
		_key(KEY_C)
		var near := _off(main, b.base.cell)
		out = check(near < far - 1.0 and hud.alerts.recent.size() == 1, "C 키 뒤 거점과 (320,194) 거리 %.0f → %.0f · 최근 경보 %s" % [far, near, hud.alerts.recent])
	_done(main)
	return out

# EV351 · S189·I163: 정문이 맞으면 «정문 공격받음», 3.6초 뒤 왼쪽 쪽문이 맞으면 따로 «왼쪽 쪽문 공격받음»이 뜬다. 정문 토스트를 누르면 카메라가 정문 쪽으로 간다.
# 첫 피해 5초 뒤 정문이 또 맞아도 토스트는 없다(20초에 한 번). C는 왼쪽 쪽문, 한 번 더 C는 정문 쪽으로 카메라를 옮긴다
func ev351():
	var main = _prep()
	var b = main.view.battle
	var hud = main.hud
	if not hud.get("alerts") is Control:
		_done(main)
		return "main.hud.alerts가 없다"
	b.start_battle()
	_frame(main)
	_pass(main, 10.0)  # 준비 단계 미션 토스트를 흘려 보낸다
	b.mission = ""  # 미션이 깨진 토스트가 끼지 않게(미션은 판마다 다르다)
	b.commission = ""
	var g1 = b.castle[Vector2i(20, 9)]
	var g0 = b.castle[Vector2i(0, 9)]
	b.damage(g1, 5, "true")
	hud._process(0.0)
	var t1 := _toasts(main)
	_pass(main, 3.6)
	b.damage(g0, 5, "true")
	hud._process(0.0)
	var t2 := _toasts(main)
	var out := ""
	if t1.size() != 1 or not t1[0].begins_with("정문 공격받음") or t2.size() != 2 or not t2[1].begins_with("왼쪽 쪽문 공격받음"):
		out = "정문 피해 뒤 토스트 %s · 3.6초 뒤 왼쪽 쪽문 피해 뒤 %s" % [t1, t2]
	if out == "":
		_cam(main).focus(Vector2(600, 450))
		var far := _off(main, g1.cell)
		var pressed := _press_toast(main, "정문")
		var near := _off(main, g1.cell)
		if not pressed or near >= far - 1.0:
			out = "정문 토스트 누름 %s · 정문과 (320,194) 거리 %.0f → %.0f" % [pressed, far, near]
	if out == "":
		_pass(main, 1.4)
		b.damage(g1, 5, "true")
		hud._process(0.0)
		_pass(main, 4.0)
		var later := _toasts(main)
		if later.any(func(t): return "정문" in t) or hud.alerts.recent != [g0.cell, g1.cell]:
			out = "첫 피해 5초 뒤 정문이 또 맞은 뒤 토스트 %s · 최근 경보 %s(정문 토스트가 없고 [왼쪽 쪽문, 정문]이어야 한다)" % [later, hud.alerts.recent]
	if out == "":
		_cam(main).focus(Vector2(600, 450))
		var a0 := _off(main, g0.cell)
		_key(KEY_C)
		var a1 := _off(main, g0.cell)
		var b0 := _off(main, g1.cell)
		_key(KEY_C)
		var b1 := _off(main, g1.cell)
		out = check(a1 < a0 - 1.0 and b1 < b0 - 1.0, "C 키에 왼쪽 쪽문 거리 %.0f → %.0f, 다시 C에 정문 거리 %.0f → %.0f(둘 다 가까워져야 한다)" % [a0, a1, b0, b1])
	_done(main)
	return out

# 보유를 상한(5명)까지 채운다(목록이 비면 리롤)
func _five(b) -> void:
	for t in 6:
		for i in b.HIRE.slots:
			if b.roster.size() < b.HIRE.cap:
				b.hire(i)
		if b.roster.size() >= b.HIRE.cap:
			return
		b.reroll()

# EV352 · S117: 영입 창·라운드 사이 창이 떠 있으면 띠 아래 맵 덮개(검정 50%)가 보이고 건설 격자는 숨는다. 준비 단계에는 반대다
func ev352():
	var main = _game()
	var b = main.view.battle
	var hud = main.hud
	if not hud.get("window") is Control or not hud.get("dim") is ColorRect:
		_done(main)
		return "main.hud.window·dim이 없다"
	b.gold = BIG
	_frame(main)
	hud.grid._process(0.0)
	var out := ""
	var r: Rect2 = hud.dim.get_global_rect()
	if b.state != "hiring" or not hud.window.is_visible_in_tree() or not hud.dim.is_visible_in_tree() or absf(hud.dim.color.a - 0.5) > 0.01 or not r.is_equal_approx(Rect2(0, 28, 640, 332)) or hud.grid.visible:
		out = "영입 창: 단계 %s · 창 %s · 덮개 %s(알파 %.2f, %s) · 격자 %s" % [b.state, hud.window.is_visible_in_tree(), hud.dim.is_visible_in_tree(), hud.dim.color.a, r, hud.grid.visible]
	if out == "":
		b.hire(0)
		b.next_round()
		_frame(main)
		hud.grid._process(0.0)
		if hud.dim.is_visible_in_tree() or not hud.grid.visible:
			out = "준비 단계에 덮개 %s · 격자 %s(덮개는 숨고 격자는 보여야 한다)" % [hud.dim.is_visible_in_tree(), hud.grid.visible]
	if out == "":
		if not _win(b):
			out = "1라운드를 이기지 못했다(%s)" % b.state
		else:
			_frame(main)
			hud.grid._process(0.0)
			out = check(hud.window.is_visible_in_tree() and hud.dim.is_visible_in_tree() and not hud.grid.visible, "라운드 사이: 창 %s · 덮개 %s · 격자 %s" % [hud.window.is_visible_in_tree(), hud.dim.is_visible_in_tree(), hud.grid.visible])
	_done(main)
	return out

# EV353 · S183: 준비 단계에 용병을 고른 채 ESC 메뉴를 열면 건설 격자와 태그가 숨는다
func ev353():
	var main = _prep()
	var b = main.view.battle
	var hud = main.hud
	var m = b.place_merc("soldier", Vector2i(20, 14))
	main.controls.selected = [m]
	_frame(main)
	hud.grid._process(0.0)
	var before: bool = hud.grid.visible and hud.tags[0].is_visible_in_tree()
	_key(KEY_ESCAPE)
	var paused: bool = main.get_tree().paused
	var out := check(before and paused and not hud.grid.visible and not hud.tags[0].visible and not hud.tags[1].visible,
		"ESC 전 격자·태그 보임 %s · ESC 뒤 멈춤 %s · 격자 %s · 태그 %s·%s" % [before, paused, hud.grid.visible, hud.tags[0].visible, hud.tags[1].visible])
	_done(main)
	return out

# EV354 · I136: 보유 5명·의뢰 2개인 라운드 사이 창은 [16,34]에서 폭 608로 뜨고 아래끝이 356 이하다. 한 명을 내보낸 뒤 영입해도 리롤·진행 버튼 자리가 같다
func ev354():
	var main = _game()
	var b = main.view.battle
	var hud = main.hud
	if not hud.get("window") is Control:
		_done(main)
		return "main.hud.window가 없다"
	b.gold = BIG
	_five(b)
	b.next_round()
	var won: bool = _win(b)
	_frame(main)
	_layout(main)
	var w: Rect2 = hud.window.get_global_rect()
	var out := ""
	if not won or b.roster.size() != 5 or b.commission_offers.size() != 2:
		out = "준비가 틀렸다: 1라운드 승리 %s · 보유 %d · 의뢰 %d" % [won, b.roster.size(), b.commission_offers.size()]
	elif not w.position.is_equal_approx(Vector2(16, 34)) or absf(w.size.x - 608.0) > 0.5 or w.end.y > 356.5:
		out = "보유 5명·의뢰 2개 라운드 사이 창 %s(기대: [16,34] 폭 608, 아래끝 356 이하)" % w
	if out == "":
		b.dismiss(b.roster[4])
		_frame(main)
		_layout(main)
		var re = _starts(hud.window, "리롤")
		var go = _starts(hud.window, "다음 라운드")
		if re == null or go == null:
			out = "라운드 사이 창에 «리롤»(%s)·«다음 라운드»(%s) 버튼이 없다" % [re, go]
		else:
			var at := [re.get_global_rect(), go.get_global_rect()]
			for i in b.HIRE.slots:
				if b.offers[i] != "":
					b.hire(i)
					break
			_frame(main)
			_layout(main)
			var now := [re.get_global_rect(), go.get_global_rect()]
			out = check(b.roster.size() == 5 and now == at, "내보내고 영입한 뒤 보유 %d · 리롤·진행 버튼 %s → %s" % [b.roster.size(), at, now])
	_done(main)
	return out

# EV355 · I127: 보유가 상한이면 리롤 버튼이 0.35로 흐리지만 누를 수 있고, 누르면 창에 «내보내야 영입할 수 있다»가 보이며 골드·목록이 그대로다
func ev355():
	var main = _game()
	var b = main.view.battle
	var hud = main.hud
	if not hud.get("window") is Control:
		_done(main)
		return "main.hud.window가 없다"
	b.gold = BIG
	_five(b)
	_frame(main)
	var re = _starts(hud.window, "리롤")
	var out := ""
	if re == null or b.roster.size() != 5 or absf(re.modulate.a - 0.35) > 0.01 or re.disabled:
		out = "보유 %d명 영입 창의 리롤 버튼 %s(불투명도 0.35이고 누를 수 있어야 한다)" % [b.roster.size(), [re.modulate.a, re.disabled] if re else null]
	else:
		var gold: int = b.gold
		var offers: Array = b.offers.duplicate()
		re.pressed.emit()
		main.hud._process(0.0)
		var said := " ".join(_labels(hud.window))
		out = check(b.gold == gold and b.offers == offers and "내보내야 영입할 수 있다" in said, "상한에서 리롤을 누른 뒤 골드 %d → %d · 목록 %s → %s · 창 글 «%s»" % [gold, b.gold, offers, b.offers, said])
	_done(main)
	return out

# 맵 칸 가운데가 위 띠 아래 화면(hud.VIEW) 안에 보이는가
func _on_screen(main, cell: Vector2i) -> bool:
	return main.hud.VIEW.has_point(main.hud.map.get_canvas_transform() * ((Vector2(cell) + Vector2(0.5, 0.5)) * 16.0))

# EV361 · S189: 화면 밖 들판 타워가 처음 절반 아래가 되면 «타워 위험» 토스트가 하나 뜨고, 더 깎여도 다시 뜨지 않는다. 화면 안 타워는 알리지 않는다
func ev361():
	var main = _prep()
	var b = main.view.battle
	var hud = main.hud
	if not hud.get("alerts") is Control:
		_done(main)
		return "main.hud.alerts가 없다"
	var far = b.build("tower", Vector2i(10, 14))
	var seen = b.build("tower", Vector2i(26, 14))
	if far == null or seen == null:
		_done(main)
		return "준비 단계에 타워 (10,14)·(26,14)를 짓지 못했다(%s, %s)" % [far, seen]
	b.start_battle()
	_frame(main)
	_pass(main, 10.0)  # 준비 단계 미션 토스트를 흘려 보낸다
	b.mission = ""  # 미션이 깨진 토스트가 끼지 않게
	b.commission = ""
	_cam(main).focus(Vector2(600, 450))
	_cam(main).force_update_scroll()
	var out := ""
	if _on_screen(main, far.cell):
		out = "준비가 틀렸다: 카메라를 (600,450)에 맞춰도 (10,14)가 화면 안이다"
	if out == "":
		b.damage(far, far.max_hp * 0.6, "true")
		hud._process(0.0)
		var t1 := _toasts(main)
		b.damage(far, far.max_hp * 0.1, "true")
		hud._process(0.0)
		var t2 := _toasts(main)
		if t1.size() != 1 or not "타워 위험" in t1[0] or t2 != t1:
			out = "화면 밖 타워 60%% 피해 뒤 토스트 %s(«타워 위험» 하나여야 한다) · 10%% 더 준 뒤 %s(그대로여야 한다)" % [t1, t2]
	if out == "":
		far.hp = far.max_hp  # 수리로 다시 찬 뒤(묶기 15초가 지나도록 흘린다)
		hud._process(0.0)
		_pass(main, 16.0)
		b.damage(far, far.max_hp * 0.6, "true")
		hud._process(0.0)
		if _toasts(main).any(func(t): return "위험" in t):
			out = "체력을 채우고 16초 뒤 다시 60%% 피해를 주자 토스트 %s(«위험»이 없어야 한다, 구조물마다 한 번)" % [_toasts(main)]
	if out == "":
		_cam(main).focus((Vector2(seen.cell) + Vector2(0.5, 0.5)) * 16.0)
		_cam(main).force_update_scroll()
		var before := _toasts(main)
		var shown := _on_screen(main, seen.cell)
		b.damage(seen, seen.max_hp * 0.6, "true")
		hud._process(0.0)
		var after := _toasts(main)
		_cam(main).focus(Vector2(600, 450))  # 이미 절반 아래인 타워에서 카메라만 돌린다
		_cam(main).force_update_scroll()
		hud._process(0.0)
		out = check(shown and after == before and not _on_screen(main, seen.cell) and _toasts(main) == before,
			"화면 안(%s) 타워 60%% 피해 뒤 토스트 %s → %s · 카메라를 돌려 화면 밖(%s)이 된 뒤 %s(모두 그대로여야 한다)" % [shown, before, after, not _on_screen(main, seen.cell), _toasts(main)])
	_done(main)
	return out

# EV363 · I151: Q 키로 못 쓰는 칸도 토스트가 뜬다(준비 단계 «전투 단계에만», 재사용 대기 «재사용 대기 N초»). Q 칸을 눌러도 같다
func ev363():
	var main = _prep()
	var b = main.view.battle
	var hud = main.hud
	var said := []  # 단계마다 보이는 토스트 글
	hud.toasts._process(3.6)  # 미션 토스트가 막 떠서 3.5초 줄을 선다(I163)
	_key(KEY_Q)
	said.append(_toasts(main))
	b.start_battle()
	_frame(main)
	b.heroes[0].cd["q"] = 3.2
	hud.toasts._process(3.6)
	_key(KEY_Q)
	said.append(_toasts(main))
	hud.toasts._process(3.6)
	hud.slots[0]["q"].pressed.emit()
	said.append(_toasts(main))
	var out := check(said[0].any(func(t): return "전투 단계에만" in t) and said[1].any(func(t): return "재사용 대기 4초" in t) and said[2].any(func(t): return "재사용 대기 4초" in t),
		"준비 단계 Q 키 · 재사용 대기 중 Q 키 · 재사용 대기 중 Q 칸 뒤 토스트 %s" % [said])
	_done(main)
	return out

# EV364 · I140: 교회 팝업에 출전 영웅마다 «치료 이름…» 버튼이 늘 있고, 체력이 가득하면 어둡고 이유가 «체력 가득»이다.
# 깎이면 «치료 이름 N»이 눌린다. 건설 격자 교회 칸 설명에 «교회를 눌러»가 있다
func ev364():
	var main = _prep()
	var b = main.view.battle
	var hud = main.hud
	var c = main.controls
	var church = b.build("church", Vector2i(5, 4))
	if church == null or b.heroes.size() != 2 or b.heroes.any(func(h): return h.hp < h.max_hp):
		_done(main)
		return "준비가 틀렸다: 교회 %s · 영웅 %d · 체력 %s" % [church, b.heroes.size(), b.heroes.map(func(h): return [h.hp, h.max_hp])]
	click(c, MOUSE_BUTTON_LEFT, px(church.cell))
	_frame(main)
	var heals: Array = _pops(main).filter(func(n): return n.text.begins_with("치료 "))
	var out := ""
	if heals.size() != 2 or heals.any(func(n): return not n.disabled):
		out = "체력이 가득 찬 두 영웅의 교회 팝업 버튼 %s(«치료 »로 시작하는 disabled 버튼 둘이어야 한다)" % [_pops(main).map(func(n): return [n.text, n.disabled])]
	elif not "체력 가득" in _pop_why(main, heals[0]):
		out = "체력이 가득 찬 영웅의 치료 버튼 툴팁 빨간 줄이 «%s»다" % _pop_why(main, heals[0])
	if out == "":
		var h = b.heroes[0]
		b.damage(h, 33, "true")
		_frame(main)
		var want := "치료 %s %d" % [hud.HEROES[h.kind].get_slice("(", 0), b.heal_cost(h)]
		var btn = _starts(hud.popup, want)
		if btn == null or btn.disabled:
			out = "33 깎인 뒤 «%s» 버튼 %s(눌려야 한다) · 버튼 %s" % [want, btn, _pops(main).map(func(n): return [n.text, n.disabled])]
	if out == "":
		_move(hud.grid.cells.church.get_global_rect().get_center())
		hud.grid._process(0.0)
		var s := _tip_text(hud.grid.info)
		out = check("교회를 눌러" in s, "교회 칸 정보 칸 글이 «%s»다" % s)
	_done(main)
	return out

# EV365 · S100: 망루 그림 안(거점 칸 두 칸 위)을 눌러도 거점을 고르고, 그 안 용병 칸을 누르면 용병이 먼저다
func ev365():
	var main = _prep()
	var b = main.view.battle
	var c = main.controls
	click(c, MOUSE_BUTTON_LEFT, px(b.base.cell + Vector2i(0, -2)))
	var above: bool = c.village
	click(c, MOUSE_BUTTON_LEFT, px(Vector2i(10, 14)))
	var off: bool = not c.village
	var m = b.place_merc("soldier", b.base.cell + Vector2i(0, -1))
	if m == null:
		_done(main)
		return "준비가 틀렸다: 거점 칸 바로 위에 용병을 놓지 못했다"
	click(c, MOUSE_BUTTON_LEFT, px(b.base.cell + Vector2i(0, -1)))
	var out := check(above and off and not c.village and m in c.selected,
		"두 칸 위 누름에 거점 %s · 들판 누름에 풀림 %s · 용병 칸 누름에 거점 %s · 용병 골라짐 %s" % [above, off, c.village, m in c.selected])
	_done(main)
	return out

# EV366 · I110: 도전 시작 전 영입 창에만 «준비 단계에 지을 골드도 남긴다»가 있다
func ev366():
	var main = _game()
	var b = main.view.battle
	var hud = main.hud
	if not hud.get("window") is Control:
		_done(main)
		return "main.hud.window가 없다"
	b.gold = BIG
	_frame(main)
	var before := " ".join(_labels(hud.window))
	for i in 2:
		b.hire(i)
	b.next_round()
	var won: bool = _win(b)
	_frame(main)
	var after := " ".join(_labels(hud.window))
	var out := check(b.state == "cleared" and won and "지을 골드도 남긴다" in before and not "지을 골드도 남긴다" in after and after != "",
		"도전 시작 전 영입 창 글 «%s» · 1라운드 승리(%s) 뒤 창 글 «%s»" % [before, won, after])
	_done(main)
	return out

# btn에 커서를 0.25초 둔 뒤 툴팁 안의 보이는 글. 툴팁이 없으면 ""
func _tip_of(main, btn) -> String:
	_layout(main)
	_fresh(main.hud.tip, btn)
	main.hud.tip._process(0.25)
	return _tip_text(main.hud.tip) if main.hud.tip.visible else ""

# EV360 · I110: 라운드 사이 창의 내보내기·이관·의뢰 버튼과 이관 중 «여기로»에 툴팁이 있다
func ev360():
	var main = _game()
	var b = main.view.battle
	var hud = main.hud
	if not hud.get("window") is Control or not hud.get("tip") is Control:
		_done(main)
		return "main.hud.window·tip이 없다"
	b.gold = BIG
	for i in 2:
		b.hire(i)
	b.next_round()
	var won: bool = _win(b)
	_frame(main)
	_layout(main)
	var shown: Array = hud.window.find_children("*", "BaseButton", true, false).filter(func(n): return n.is_visible_in_tree())
	var drop: Array = shown.filter(func(n): return n.text == "내보내기")
	var give: Array = shown.filter(func(n): return n.text == "이관" and not n.disabled)
	var take: Array = shown.filter(func(n): return n.text.ends_with("수락"))
	if not won or drop.is_empty() or give.is_empty() or take.is_empty():
		_done(main)
		return "준비가 틀렸다: 1라운드 승리 %s · 내보내기 %d · 눌리는 이관 %d · 의뢰 수락 %d" % [won, drop.size(), give.size(), take.size()]
	var said := [_tip_of(main, drop[0]), _tip_of(main, give[0]), _tip_of(main, take[0])]
	give[0].pressed.emit()
	_frame(main)
	var to = _starts(hud.window, "여기로")
	said.append(_tip_of(main, to) if to else "«여기로» 버튼 없음")
	var out := check("골드는 돌려받지 못한다" in said[0] and "Lv1로" in said[1] and "다음 라운드에 걸린다" in said[2] and "경험치를 받는다" in said[3],
		"툴팁 글 내보내기·이관·의뢰·여기로 %s" % [said])
	_done(main)
	return out

# 평가용 설정 파일을 지우고 읽는다. 힌트 켬·끝낸 힌트 없음(S184, I166)
func _hints_reset():
	_save()
	var st = load("res://src/settings.gd")
	if FileAccess.file_exists(st.path):
		DirAccess.remove_absolute(st.path)
	st.load_file()
	return st

# 힌트 칸이 보이면 그 안의 보이는 글, 안 보이면 ""
func _hint_says(main) -> String:
	var h = main.hud.hints
	return " ".join(_labels(h)) if h.is_visible_in_tree() else ""

# EV356 · S191: 준비 단계 [4,300,200,40]에 «짓는다» 힌트가 뜨고, 보이기 전에 해낸 영웅 이동은 끝난 것으로 치며, 지으면 «거점», 거점을 누르면 «전투 시작»으로 바뀌고, 전투가 시작되면 숨는다
func ev356():
	var st = _hints_reset()
	var main = _prep()
	var b = main.view.battle
	var hud = main.hud
	if not hud.get("hints") is Control:
		_done(main)
		return "main.hud.hints가 없다"
	var out := ""
	var r: Rect2 = hud.hints.get_global_rect()
	var said := _hint_says(main)
	if r != Rect2(4, 300, 200, 40) or not "짓는다" in said:
		out = "새 설정의 1라운드 준비 단계 힌트 칸 %s · 글 «%s»(기대: [4,300,200,40], «짓는다»)" % [r, said]
	if out == "":
		var h = b.heroes[0]
		main.controls.selected = [h]
		main.controls.facility = null
		click(main.controls, MOUSE_BUTTON_RIGHT, px(Vector2i(h.pos.round()) + Vector2i(2, 0)))
		_frame(main)
		said = _hint_says(main)
		if not "move" in st.hints_done or not "짓는다" in said:
			out = "영웅 이동 뒤 끝낸 힌트 %s · 글 «%s»(기대: move가 있고 글은 «짓는다»)" % [st.hints_done, said]
	if out == "":
		if b.build("tower", Vector2i(10, 14)) == null:
			out = "타워를 짓지 못했다"
		else:
			_frame(main)
			said = _hint_says(main)
			if not "거점" in said:
				out = "타워를 지은 뒤 힌트 글 «%s»(기대: «거점»)" % said
	if out == "":
		click(main.controls, MOUSE_BUTTON_LEFT, px(b.base.cell))
		_frame(main)
		said = _hint_says(main)
		if not "keep" in st.hints_done or not "전투 시작" in said:
			out = "거점을 누른 뒤 끝낸 힌트 %s · 글 «%s»(기대: keep이 있고 «전투 시작»)" % [st.hints_done, said]
	var f = b.build("barracks", Vector2i(4, 4)) if out == "" else null
	if out == "" and f == null:
		out = "준비 단계에 마을 (4,4)에 병영을 짓지 못했다"
	if out == "":
		b.start_battle()
		_frame(main)
		if b.state != "battle" or hud.hints.is_visible_in_tree() or not "start" in st.hints_done:
			out = "전투를 시작한 뒤(단계 %s) 힌트 칸 보임 %s · 끝낸 힌트 %s(기대: 숨고 start가 있다)" % [b.state, hud.hints.is_visible_in_tree(), st.hints_done]
	if out == "":
		b.recruit(f, "soldier")
		_frame(main)
		out = check("buy" in st.hints_done, "전투 단계에 용병을 산 뒤 끝낸 힌트 %s(기대: buy가 있다)" % [st.hints_done])
	_done(main)
	_hints_reset()
	return out

# EV357 · S191·I166: «건너뛰기»는 지금 힌트를 끝내고, 끝낸 힌트는 설정 파일에 남아 다시 읽은 뒤 새 게임에서도 뜨지 않는다
func ev357():
	var st = _hints_reset()
	var main = _prep()
	var hud = main.hud
	if not hud.get("hints") is Control:
		_done(main)
		return "main.hud.hints가 없다"
	var out := ""
	if not _press(hud.hints, "건너뛰기"):
		out = "힌트 칸에 «건너뛰기»가 없다"
	else:
		_frame(main)
		var said := _hint_says(main)
		if not "거점" in said:
			out = "«건너뛰기» 뒤 힌트 글 «%s»(기대: «거점»)" % said
	_done(main)
	if out == "":
		st.hints_done = []
		st.load_file()
		main = _prep()
		var said := _hint_says(main)
		out = check("build" in st.hints_done and not "짓는다" in said and "거점" in said, "다시 읽은 뒤 새 게임의 끝낸 힌트 %s · 글 «%s»(기대: build가 있고 «짓는다» 없이 «거점»)" % [st.hints_done, said])
		_done(main)
	_hints_reset()
	return out

# EV358 · S184: 설정의 «힌트»(기본 켬)를 끄면 저장되고 힌트 칸이 숨는다. 다시 켜면 끝낸 힌트는 그대로 둔 채 다음 힌트가 뜬다
func ev358():
	var st = _hints_reset()
	var main = _prep()
	var hud = main.hud
	if not hud.get("hints") is Control:
		_done(main)
		return "main.hud.hints가 없다"
	_press(hud.hints, "건너뛰기")
	_key(KEY_ESCAPE)
	_press(main, "설정")
	var box = _button(main, "힌트")
	var out := ""
	if not box is CheckButton or not box.button_pressed:
		out = "ESC 메뉴 설정에 켜진 «힌트» 항목이 없다(%s)" % box
	else:
		box.button_pressed = false
		st.hints = true
		st.load_file()
		if st.hints:
			out = "«힌트»를 끈 뒤 설정 파일을 다시 읽으니 힌트가 켜져 있다"
	if out == "":
		_press(main, "뒤로")
		_press(main, "계속")
		_frame(main)
		if hud.hints.is_visible_in_tree():
			out = "«힌트»를 끈 뒤 준비 단계에 힌트 칸이 보인다"
	if out == "":
		_key(KEY_ESCAPE)
		_press(main, "설정")
		box = _button(main, "힌트")
		if box:
			box.button_pressed = true
		_press(main, "뒤로")
		_press(main, "계속")
		_frame(main)
		var said := _hint_says(main)
		out = check(box != null and "거점" in said, "«힌트»를 다시 켠 뒤 힌트 글 «%s»(기대: «거점»)" % said)
	_done(main)
	_hints_reset()
	return out

# EV368 · S192: 1라운드 웨이브마다 그 웨이브의 축 단계만 보이고(앞 웨이브에서 남은 단계는 넘어오지 않는다), 2·3웨이브 전투 단계에는 전투 단계용 단계가 보인다
func ev368():
	var st = _hints_reset()
	var main = _prep()
	var b = main.view.battle
	var hud = main.hud
	if not hud.get("hints") is Control or not hud.hints.get("axis") is Label:
		_done(main)
		_hints_reset()
		return "main.hud.hints.axis가 없다"
	var out := check(hud.hints.axis.text == "시설", "1웨이브 준비 단계 축 이름 «%s»(기대: «시설»)" % hud.hints.axis.text)
	if out == "":
		b.start_battle()
		if not clear_wave(b):
			out = "1웨이브를 끝내지 못했다"
		else:
			_frame(main)
			var said := _hint_says(main)
			if b.state != "prep" or b.wave_index != 1 or not "병영" in said or hud.hints.axis.text != "용병":
				out = "1웨이브 뒤(단계 %s, 웨이브 %d) 힌트 글 «%s» · 축 «%s»(기대: 2웨이브 준비 단계, «병영», «용병»)" % [b.state, b.wave_index + 1, said, hud.hints.axis.text]
	var f = b.build("barracks", Vector2i(4, 4)) if out == "" else null
	if out == "" and f == null:
		out = "2웨이브 준비 단계에 마을 (4,4)에 병영을 짓지 못했다"
	if out == "":
		if b.place_merc("soldier", Vector2i(10, 14)) == null:
			out = "2웨이브 준비 단계에 (10,14)에 용병을 놓지 못했다"
		else:
			_frame(main)
			if hud.hints.is_visible_in_tree() or not "merc" in st.hints_done:
				out = "용병을 놓은 뒤 힌트 칸 보임 %s · 끝낸 힌트 %s(기대: 숨고 merc가 있다)" % [hud.hints.is_visible_in_tree(), st.hints_done]
	if out == "":
		b.start_battle()
		_frame(main)
		var r: Rect2 = hud.hints.get_global_rect()
		var said := _hint_says(main)
		if b.state != "battle" or r != Rect2(4, 300, 200, 40) or not "3·5·7" in said:
			out = "2웨이브 전투 단계(단계 %s) 힌트 칸 %s · 글 «%s»(기대: [4,300,200,40], «3·5·7»)" % [b.state, r, said]
	if out == "":
		b.recruit(f, "soldier")
		_frame(main)
		if hud.hints.is_visible_in_tree():
			out = "전투 중 용병을 산 뒤 힌트 칸이 보인다 · 글 «%s»" % _hint_says(main)
	if out == "":
		if not clear_wave(b):
			out = "2웨이브를 끝내지 못했다"
		else:
			_frame(main)
			var said := _hint_says(main)
			if b.state != "prep" or b.wave_index != 2 or not "우클릭" in said or hud.hints.axis.text != "영웅":
				out = "2웨이브 뒤(단계 %s, 웨이브 %d) 힌트 글 «%s» · 축 «%s»(기대: 3웨이브 준비 단계, «우클릭», «영웅»)" % [b.state, b.wave_index + 1, said, hud.hints.axis.text]
	if out == "":
		b.start_battle()
		_frame(main)
		var said := _hint_says(main)
		if not "스킬" in said:
			out = "3웨이브 전투 단계 힌트 글 «%s»(기대: «스킬»)" % said
	if out == "":
		var h = b.heroes[0]
		var aim = h if h.q.aim == "ally" else h.pos + Vector2(1, 0)
		if not b.cast(h, "q", aim):
			out = "첫 출전 영웅이 Q(%s)를 쓰지 못했다" % h.q.aim
		else:
			_frame(main)
			out = check(not hud.hints.is_visible_in_tree() and "skill" in st.hints_done, "Q를 쓴 뒤 힌트 칸 보임 %s · 끝낸 힌트 %s(기대: 숨고 skill이 있다)" % [hud.hints.is_visible_in_tree(), st.hints_done])
	_done(main)
	_hints_reset()
	return out

# EV369 · S192: 2라운드부터는 끝내지 않은 단계가 있어도 힌트 칸이 보이지 않는다
func ev369():
	_hints_reset()
	var main = _prep()
	var b = main.view.battle
	var hud = main.hud
	if not hud.get("hints") is Control:
		_done(main)
		_hints_reset()
		return "main.hud.hints가 없다"
	var out := ""
	if not _win(b) or not b.next_round():
		out = "1라운드를 이기고 2라운드로 가지 못했다(단계 %s)" % b.state
	if out == "":
		_frame(main)
		if hud.hints.is_visible_in_tree():
			out = "2라운드 준비 단계에 힌트 칸이 보인다 · 글 «%s»" % _hint_says(main)
	if out == "":
		b.start_battle()
		_frame(main)
		out = check(b.state == "battle" and not hud.hints.is_visible_in_tree(), "2라운드 전투 단계(단계 %s)에 힌트 칸 보임 %s · 글 «%s»" % [b.state, hud.hints.is_visible_in_tree(), _hint_says(main)])
	_done(main)
	_hints_reset()
	return out

# 언어를 en으로 건다(S193). 평가 끝에는 _english_off로 ko로 돌린다
func _english():
	var st = _hints_reset()
	st.language = "en"
	st.apply_language()
	return st

func _english_off(st) -> void:
	st.language = "ko"
	st.apply_language()
	_hints_reset()

# 보이는 Label·Button의 화면 글(자동 번역을 거친 글)을 [where, 글]로 seen에 더한다
func _gather(node: Node, where: String, seen: Array) -> void:
	for n in node.find_children("*", "Control", true, false):
		if n.is_visible_in_tree() and (n is Label or n is Button) and n.text != "":
			seen.append([where, n.atr(n.text)])

# buttons를 하나씩 가리켜 뜬 툴팁의 화면 글을 seen에 더한다
func _gather_tips(main, buttons: Array, where: String, seen: Array) -> void:
	var tip = main.hud.tip
	for btn in buttons:
		_fresh(tip, btn)
		tip._process(0.3)
		if tip.visible:
			_gather(tip, "%s «%s»" % [where, btn.atr(btn.text)], seen)

# EV372 · S193: 영어로 두면 영입 창부터 패배 창·ESC 메뉴까지 보이는 글과 툴팁에 한글이 없다
func ev372():
	var st = _english()
	var main = _game()
	var b = main.view.battle
	var hud = main.hud
	b.gold = BIG
	_frame(main)
	_layout(main)
	var seen := []
	_gather(main, "영입 창", seen)
	_gather_tips(main, hud.window.find_children("*", "BaseButton", true, false).filter(func(n): return n.is_visible_in_tree()), "영입 창 툴팁", seen)
	for i in 2:
		b.hire(i)
	b.next_round()
	_frame(main)
	_layout(main)
	_pass(main, 0.1)
	_gather(main, "준비 단계", seen)
	_gather_tips(main, _bar_buttons(main), "위 띠 툴팁", seen)
	for kind in hud.grid.cells:
		_move(hud.grid.cells[kind].get_global_rect().get_center())
		hud.grid._process(0.0)
		_gather(hud.grid, "정보 칸 «%s»" % kind, seen)
	_move(EMPTY)
	_key(KEY_2)
	hud._process(0.0)
	_gather(main, "타워 놓기 중", seen)
	click(main.controls, MOUSE_BUTTON_LEFT, px(Vector2i(5, 5)))  # 성 안(마을) 칸: 타워는 성 밖에만
	hud._process(0.0)
	_gather(main, "놓기 거부", seen)
	_key(KEY_ESCAPE)
	var f = b.build("barracks", Vector2i(4, 4))
	b.start_battle()
	_frame(main)
	if f:
		click(main.controls, MOUSE_BUTTON_LEFT, px(f.cell))
		hud._process(0.0)
		_gather(main, "전투 단계 병영 팝업", seen)
	_pass(main, 10.0)
	b.damage(b.base, 5, "true")
	hud._process(0.0)
	_gather(hud.toasts, "경보 토스트", seen)
	var won: bool = _win(b)
	_frame(main)
	_layout(main)
	_gather(main, "라운드 승리 창", seen)
	_gather_tips(main, hud.window.find_children("*", "BaseButton", true, false).filter(func(n): return n.is_visible_in_tree()), "승리 창 툴팁", seen)
	b.next_round()
	b.start_battle()
	b.damage(b.base, BIG, "true")
	_frame(main)
	_layout(main)
	var lost: bool = b.state == "lost"
	_gather(main, "패배 창", seen)
	_key(KEY_ESCAPE)
	_gather(main, "ESC 메뉴", seen)
	_press(main, "설정")
	_gather(main, "설정", seen)
	_done(main)
	_english_off(st)
	var hangul := RegEx.create_from_string("[가-힣]")
	var bad := seen.filter(func(p): return hangul.search(p[1]) != null)
	if f == null or not won or not lost:
		return "화면을 다 띄우지 못했다(병영 %s · 승리 %s · 패배 %s)" % [f != null, won, lost]
	if seen.size() < 100:
		return "모은 화면 글이 %d개뿐이다" % seen.size()
	return check(bad.is_empty(), "영어 화면 글 %d개 가운데 한글이 든 것 %d개: %s" % [seen.size(), bad.size(), "; ".join(bad.slice(0, 8).map(func(p): return "%s: «%s»" % [p[0], p[1].replace("\n", "⏎")]))])

# 글꼴로 잰 화면 글 l의 가장 긴 줄 폭
func _text_w(l: Label) -> float:
	var font: Font = l.get_theme_font("font")
	var fs: int = l.get_theme_font_size("font_size")
	var w := 0.0
	for line in l.atr(l.text).split("\n"):
		w = maxf(w, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
	return w

# EV374 · S193: 영어 힌트 줄·정보 칸의 잘리는 줄·안내 칩 글이 칸 폭 안이다
func ev374():
	var st = _english()
	var main = _prep()
	var b = main.view.battle
	var hud = main.hud
	var over := []
	var label: Label = hud.hints.text
	var font: Font = label.get_theme_font("font")
	var fs: int = label.get_theme_font_size("font_size")
	for h in hud.hints.HINTS:
		for line in TranslationServer.translate(h[3]).split("\n"):
			var w := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			if w > label.size.x + 0.5:
				over.append("힌트 «%s» %.0f > %.0f" % [line, w, label.size.x])
	for kind in hud.grid.cells:
		_move(hud.grid.cells[kind].get_global_rect().get_center())
		hud.grid._process(0.0)
		var box: Rect2 = hud.grid.info.get_global_rect()
		if box.size.x > 130.5:
			over.append("정보 칸 «%s» 폭 %.0f" % [kind, box.size.x])
		for l in hud.grid.info.find_children("*", "Label", true, false):
			if l.is_visible_in_tree() and l.clip_text and _text_w(l) > l.size.x + 0.5:
				over.append("정보 칸 «%s» «%s» %.0f > %.0f" % [kind, l.atr(l.text), _text_w(l), l.size.x])
	_move(EMPTY)
	for kind in hud.grid.cells:
		main.controls.placing = kind
		hud._process(0.0)
		if hud.chip.size.x > 180.5:
			over.append("안내 칩 «%s» 폭 %.0f" % [hud.hint.atr(hud.hint.text), hud.chip.size.x])
	main.controls.placing = ""
	var c = b.build("cannon", _near(b, "cannon", Vector2i(10, 14)))
	if c:
		main.controls.moving = c
		hud._process(0.0)
		if hud.chip.size.x > 180.5:
			over.append("안내 칩 «%s» 폭 %.0f" % [hud.hint.atr(hud.hint.text), hud.chip.size.x])
		main.controls.moving = null
	b.start_battle()
	main.controls.aiming = "q"
	main.controls.aim_hero = b.heroes[0]
	hud._process(0.0)
	var aim_w := _text_w(hud.hint)
	if hud.chip.size.x > 180.5:
		over.append("안내 칩 «%s» 폭 %.0f" % [hud.hint.atr(hud.hint.text), hud.chip.size.x])
	main.controls.aiming = ""
	_done(main)
	_english_off(st)
	if c == null or aim_w <= 0.0:
		return "대포 옮기기·스킬 조준 칩을 띄우지 못했다(대포 %s · 조준 글 폭 %.0f)" % [c != null, aim_w]
	return check(over.is_empty(), "영어 글이 칸을 넘는 곳 %d개: %s" % [over.size(), "; ".join(over.slice(0, 8))])
