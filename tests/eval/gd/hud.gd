extends "res://tests/eval/gd/save.gd"
# WBS 4.1g HUD 개편(S187·I162). save.gd 머리의 계약에 더하는 API:
#   main.hud.bar — HUD 위 띠(Control). 그 안의 보이는 BaseButton이 «위 띠의 조작»이다
#   main.hud.tip — 툴팁 패널(Control, I162). visible · get_global_rect() · _process(delta)로 시간을 흘린다
#     tip.reason — 빨간 이유 줄(Label). 못 쓰는 조건이 없으면 숨는다
#   main.hud.grid — 건설 격자(Control, S186). _process(delta)로 시간을 흘린다. 자리는 컨테이너 없이 바로 정해진다
#     grid.cells — 놓기 kind → 칸(BaseButton). 칸 안의 TextureRect가 아이콘이다(S30)
#     grid.info — 정보 칸(Control). grid.reason — 그 안의 빨간 이유 줄(Label) · grid.band — «공병 없음» 띠(Control, I128)
#   카메라(Camera2D, 게임 장면 안에 하나) — scroll(창 기준 마우스, 창 크기, delta) · pan(dir, delta) · zoom_at(step, 커서) · level
#     static edge_dir(창 기준 마우스, 창 크기)(S53) · keys(delta) — 눌린 방향키 쪽으로 옮긴다(S53) · map_px(맵 크기, 맵 px)
#   res://src/settings.gd — static var camera_speed(카메라 속도 %, S184·S53)
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
#   main.hud.map — 맵을 그리는 뷰포트(S30 2026-10-25 변경 뒤로 루트). get_canvas_transform()이 맵 px → 화면 좌표다
#   카메라 busy() — 가감속·부드러운 줌·미끄러짐이 아직 움직이는 중 · glide(delta) — 그것을 delta만큼 흘린다(S52·S53·I164)
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

# 미끄러지는 카메라(I164)·부드러운 줌(S52)이 멈출 때까지 1/60초씩 흘린다. 2초에서 끊는다
func _settle(main) -> void:
	var cam = _cam(main)
	for i in 120:
		if not cam.busy():
			break
		cam.glide(1.0 / 60.0)
	cam.force_update_scroll()

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

# 건설 격자 칸의 자리(S186): 13칸이 격자 안에 겹치지 않고 세 줄로, 용병은 파는 시설 아래, 대피소는 집 아래. 칸 글에 이유(I132)가 없다. 문제가 없으면 ""
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
	for pair in [["soldier", "barracks"], ["engineer", "workshop"], ["archer", "archery"], ["shelter", "house"]]:
		if not r.has(pair[0]):
			return "«%s» 칸이 없다(%s)" % [pair[0], r.keys()]
		if absf(r[pair[0]].position.x - r[pair[1]].position.x) > 0.5:
			return "«%s» 칸 x %.1f가 «%s» 칸 x %.1f와 다르다" % [pair[0], r[pair[0]].position.x, pair[1], r[pair[1]].position.x]
	if not area.encloses(r.shelter) or absf(r.shelter.position.y - r.soldier.position.y) > 0.5:  # 대피소는 3줄 4열(S186 2026-10-27 변경)
		return "«shelter» 칸 %s가 격자 밖이거나 3줄(y %.1f)이 아니다" % [r.shelter, r.soldier.position.y]
	if r.size() != 13:
		return "칸이 %d개다(%s)" % [r.size(), r.keys()]
	return ""

# EV322 · S186: 준비·전투 단계에 건설 격자 13칸의 자리가 같고, 칸 글에 «없음»·«Lv»가 없다. 칸·2 키를 두 번 누르면 놓기 모드가 켜졌다 꺼진다
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

# EV323 · I132: 마을 Lv1 준비 단계에 타워 칸 정보 칸은 «타워»·«(타워 값)골드»·«[2]»에 빨간 줄이 없고, 사격장 칸은 빨간 줄에 «마을 Lv2».
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
	if not g.info.is_visible_in_tree() or not ("타워" in s and "%d골드" % b.STRUCTURE_KINDS.tower.cost in s and "[2]" in s) or g.reason.is_visible_in_tree():
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
# 맨 위에서는 맵 y 0이 화면 y 28 + 64 × 줌(위 띠 아래로 맵 밖 64px, I50 2026-10-26 변경)이고 정보 칸은 격자 위(x 510, 아래끝 288)다
func ev325():
	var main = _prep()
	var g = main.hud.get("grid")
	if g == null:
		_done(main)
		return "main.hud.grid가 없다"
	var b = main.view.battle
	var cam = _cam(main)
	var map: Viewport = main.hud.map
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
		if absf(top - (28.0 + 64.0 * cam.zoom.x)) > 0.5:
			out = "%d배 줌 맨 위에서 맵 y 0이 화면 y %.1f다(%.1f여야 한다)" % [cam.zoom.x, top, 28.0 + 64.0 * cam.zoom.x]
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
	_settle(main)
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

const ENEMY := {"basic": "기본", "fast": "빠름", "armored": "장갑", "flying": "비행", "boss": "보스", "slime": "슬라임", "slimelet": "꼬마 슬라임", "big_slime": "큰 슬라임", "slime_king": "슬라임 킹"}  # S106
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
			var plan: Array = b.wave_plan(r, w)
			if got.size() != plan.size():
				return "%d라운드 %d웨이브에 적이 %d명 나왔다(%d명이어야 한다)" % [r + 1, w + 1, got.size(), plan.size()]
			var real: Array = b.spawns.map(func(_c): return {})
			for k in got.size():  # 출현 지점은 wave_plan이 맡긴 것이고, 나온 칸은 그 출현 지점에서 가로로 spawn_spread 안이어야 한다(I177)
				var s: Vector2i = plan[k][1]
				if got[k][0] != plan[k][0] or got[k][1].y != s.y or absi(got[k][1].x - s.x) > b.spawn_spread:
					return "%d라운드 %d웨이브 %d번째 적 %s가 출현 지점 %s(가로 ±%d)에서 나오지 않았다" % [r + 1, w + 1, k, got[k], s, b.spawn_spread]
				var d: Dictionary = real[b.spawns.find(s)]
				d[got[k][0]] = d.get(got[k][0], 0) + 1
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
		if out == "" and not lines.any(func(l): return "슬라임: 죽으면 둘로 갈라진다" in l):  # S188 2026-10-27 변경
			out = "첫 웨이브 툴팁 «%s»에 «슬라임: 죽으면 둘로 갈라진다» 줄이 없다" % _tip_text(main.hud.tip)
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
		var area := Rect2(68, 344, 432, 12)
		if shown.size() != b.spawns.size() or nums != sums or shown.any(func(m): return not area.encloses(m.get_global_rect().grow(-0.01))):
			out = "1배 줌 맨 위: 표식 %d개(기대 %d) · 수 %s(기대 %s) · 자리 %s" % [shown.size(), b.spawns.size(), nums, sums, shown.map(func(m): return m.get_global_rect())]
	if out == "":
		cam.pan(Vector2(0, 1), 100.0)
		cam.force_update_scroll()
		main.hud._process(0.0)
		var shown: Array = edges.get_children().filter(func(m): return m.is_visible_in_tree())
		var away: Array = b.spawns.filter(func(s): return not _on_screen(main, s))  # 맵이 1배 화면보다 넓어(S203) 양옆 출현 지점은 맨 아래에서도 화면 밖이다
		out = check(shown.size() == away.size(), "1배 줌 맨 아래인데 표식이 %d개 보인다(화면 밖 출현 지점 %s)" % [shown.size(), away])
	var bosses: Array = range(1, b.waves.size()).filter(func(w): return b.waves[w].any(func(e): return b.ENEMY_KINDS[e.kind].get("boss") == true))  # 보스 표시(I185)
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

# EV342 · I139: 영웅이나 용병을 고르면 오른쪽 가장자리 [616,182]·[616,208]에 공격 이동(A)·정지(S) 태그가, 용병을 고르면 [616,234]에 홀드(H) 태그가 뜬다.
# 글 없는 그림 태그이고 툴팁이 있으며, 누르면 A·S·H 키와 같다. 홀드 태그 그림이 상태를 보인다
func ev342():
	var main = _prep()
	var b = main.view.battle
	var c = main.hud.controls
	var tip = main.hud.tip
	var tags = main.hud.get("tags")
	if not tags is Array or tags.size() != 3 or not tags.all(func(t): return t is BaseButton):
		_done(main)
		return "main.hud.tags가 BaseButton 셋이 아니다"
	var m1 = b.place_merc("soldier", Vector2i(20, 14))
	var m2 = b.place_merc("soldier", Vector2i(21, 14))
	if m1 == null or m2 == null:
		_done(main)
		return "준비 단계에 용병을 놓지 못했다"
	b.set_hold([m1, m2], false)
	c.selected = [m1]
	main.hud._process(0.0)
	var out := ""
	for i in 3:
		var r: Rect2 = tags[i].get_global_rect()
		var want := Rect2(608, 182 + 26 * i, 24, 24)
		var key: String = "ASH"[i]
		if not tags[i].is_visible_in_tree() or r.position.distance_to(want.position) > 0.5 or r.size.distance_to(want.size) > 0.5:
			out = "%s 태그 %s · 보임 %s(기대 %s)" % [key, r, tags[i].is_visible_in_tree(), want]
		elif tags[i].text != "" or " ".join(_labels(tags[i])) != key or _look(tags[i])[0] == null:
			out = "%s 태그: 버튼 글 «%s» · 보이는 글 %s · 그림 %s(기대: 버튼 글 없음, 보이는 글은 키 글자 하나, 그림 있음)" % [key, tags[i].text, _labels(tags[i]), _look(tags[i])[0]]
		if out != "":
			break
	var off := _look(tags[2])
	if out == "":
		var said := [_tag_tip(tip, tags[0]), _tag_tip(tip, tags[1]), _tag_tip(tip, tags[2])]
		if not "공격 이동" in said[0] or not "정지" in said[1] or not "홀드 끔" in said[2]:
			out = "툴팁 A «%s» · S «%s» · H «%s»" % said
	if out == "":
		tags[0].pressed.emit()
		var aimed: bool = c.attacking
		_key(KEY_ESCAPE)
		if not aimed or c.attacking or _paused():
			out = "A 태그를 누른 뒤 공격 명령 조준 %s · ESC 뒤 조준 %s · 멈춤 %s" % [aimed, c.attacking, _paused()]
	if out == "":
		b.order_move([m1], Vector2i(24, 14))
		var walking: bool = not m1.path.is_empty()
		tags[1].pressed.emit()
		if not walking or not m1.path.is_empty():
			out = "S 태그: 누르기 전 걷는 중 %s · 누른 뒤 걸을 길 %s" % [walking, m1.path]
	if out == "":
		tags[2].pressed.emit()
		main.hud._process(0.0)
		var said := _tag_tip(tip, tags[2])
		if not m1.hold or _look(tags[2]) == off or not "홀드 켬" in said or "홀드 끔" in said:
			out = "H 태그를 누른 뒤: 홀드 %s · 그림이 그대로 %s · 툴팁 «%s»" % [m1.hold, _look(tags[2]) == off, said]
	if out == "":
		_key(KEY_H)
		main.hud._process(0.0)
		out = check(not m1.hold and _look(tags[2]) == off, "H 키를 넣자 홀드 %s · 그림이 처음과 같음 %s다(태그를 누른 것과 H 키가 같은 전환이 아니다)" % [m1.hold, _look(tags[2]) == off])
	if out == "":
		b.set_hold([m2], true)
		c.selected = [m1, m2]
		main.hud._process(0.0)
		var said := _tag_tip(tip, tags[2])
		if not "섞임" in said:
			out = "홀드가 섞인 두 용병: H 툴팁 «%s»" % said
	if out == "":
		c.selected = [b.heroes[0]]
		main.hud._process(0.0)
		if not tags[0].is_visible_in_tree() or not tags[1].is_visible_in_tree() or tags[2].is_visible_in_tree():
			out = "영웅만 고름: A %s · S %s · H %s(기대 A·S만 보임)" % [tags[0].is_visible_in_tree(), tags[1].is_visible_in_tree(), tags[2].is_visible_in_tree()]
	if out == "":
		c.selected = []
		main.hud._process(0.0)
		out = check(not tags.any(func(t): return t.is_visible_in_tree()), "고른 것을 비웠는데 태그가 보인다")
	_done(main)
	return out

func _paused() -> bool:
	return Engine.get_main_loop().paused

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
	var t = b.build("tower", Vector2i(20, 62))
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
		click(c, MOUSE_BUTTON_LEFT, px(Vector2i(22, 62)))
		hud._process(0.0)
		var now: String = hud.hint.text if hud.hint.is_visible_in_tree() else ""
		hud._process(1.6)
		if c.placing != "tower" or b.structures.has(Vector2i(22, 62)) or not "닿는 공병 없음" in now or "닿는 공병 없음" in hud.hint.text:
			out = "놓기 모드 «%s» · 지어짐 %s · 누른 직후 안내 줄 «%s» · 1.6초 뒤 «%s»" % [c.placing, b.structures.has(Vector2i(22, 62)), now, hud.hint.text]
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
	click(c, MOUSE_BUTTON_LEFT, px(Vector2i(22, 62)))
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
	var g = b.castle[Vector2i(29, 59)]  # 정문 문루(S217)
	var top := Vector2i(30, 57)  # 문루 윗줄 가운데. 앞줄(59행)을 누르면 팝업이 화면 아래끝에 붙는다
	b.set_gate(g, true)
	var m = b.place_merc("soldier", g.cell)
	var church = b.build("church", Vector2i(5, 6))  # 북벽(0~2행, S203) 아래
	var h = b.heroes[0]
	b.damage(h, 10, "true")
	if not g.open or m == null or church == null or h.hp >= h.max_hp:
		_done(main)
		return "준비가 틀렸다: 정문 열림 %s · 정문 위 용병 %s · 교회 %s · 영웅 체력 %s/%s" % [g.open, m, church, h.hp, h.max_hp]
	var out := ""
	click(c, MOUSE_BUTTON_LEFT, px(top))
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
		click(c, MOUSE_BUTTON_LEFT, px(top))
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
	var es := [b.place_merc("engineer", Vector2i(22, 62)), b.place_merc("engineer", Vector2i(22, 63))]
	var t1 = b.build("tower", Vector2i(20, 62))
	var t2 = b.build("tower", Vector2i(24, 62))
	var t3 = b.build("tower", Vector2i(26, 62))
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
	_settle(main)
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
	_settle(main)
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
	_cam(main).focus(Vector2(600, 930))  # 거점이 화면 밖(위)
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

# EV351 · S189·I163: 정문이 맞으면 «정문 공격받음», 3.6초 뒤 거점이 맞으면 따로 «거점 공격받음»이 뜬다. 정문 토스트를 누르면 카메라가 정문 쪽으로 간다.
# 첫 피해 5초 뒤 정문이 또 맞아도 토스트는 없다(20초에 한 번). C는 거점, 한 번 더 C는 정문 쪽으로 카메라를 옮긴다.
# 시험 스테이지에 쪽문이 없어져(S39 2026-10-26 변경) 둘째 경보를 왼쪽 쪽문에서 거점으로 바꿨다
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
	var g1 = b.castle[Vector2i(29, 59)]  # 정문 문루(S217)
	var g0 = b.base
	b.damage(g1, 5, "true")
	hud._process(0.0)
	var t1 := _toasts(main)
	_pass(main, 3.6)
	b.damage(g0, 5, "true")
	hud._process(0.0)
	var t2 := _toasts(main)
	var out := ""
	if t1.size() != 1 or not t1[0].begins_with("정문 공격받음") or t2.size() != 2 or not t2[1].begins_with("거점 공격받음"):
		out = "정문 피해 뒤 토스트 %s · 3.6초 뒤 거점 피해 뒤 %s" % [t1, t2]
	if out == "":
		_cam(main).focus(Vector2(760, 1218))
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
			out = "첫 피해 5초 뒤 정문이 또 맞은 뒤 토스트 %s · 최근 경보 %s(정문 토스트가 없고 [거점, 정문]이어야 한다)" % [later, hud.alerts.recent]
	if out == "":
		_cam(main).focus(Vector2(760, 1218))
		var a0 := _off(main, g0.cell)
		_key(KEY_C)
		var a1 := _off(main, g0.cell)
		var b0 := _off(main, g1.cell)
		_key(KEY_C)
		var b1 := _off(main, g1.cell)
		out = check(a1 < a0 - 1.0 and b1 < b0 - 1.0, "C 키에 거점 거리 %.0f → %.0f, 다시 C에 정문 거리 %.0f → %.0f(둘 다 가까워져야 한다)" % [a0, a1, b0, b1])
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
	var far = b.build("tower", Vector2i(20, 62))
	var seen = b.build("tower", Vector2i(36, 62))
	if far == null or seen == null:
		_done(main)
		return "준비 단계에 타워 (20,32)·(36,32)를 짓지 못했다(%s, %s)" % [far, seen]
	b.start_battle()
	_frame(main)
	_pass(main, 10.0)  # 준비 단계 미션 토스트를 흘려 보낸다
	b.mission = ""  # 미션이 깨진 토스트가 끼지 않게
	b.commission = ""
	_cam(main).focus(Vector2(760, 1218))
	_cam(main).force_update_scroll()
	var out := ""
	if _on_screen(main, far.cell):
		out = "준비가 틀렸다: 카메라를 (760,738)에 맞춰도 (20,32)가 화면 안이다"
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
		_cam(main).focus(Vector2(760, 1218))  # 이미 절반 아래인 타워에서 카메라만 돌린다
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
	var church = b.build("church", Vector2i(5, 6))  # 북벽(0~2행, S203) 아래
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

# EV356 · S191: 준비 단계 [68,300,200,40]에 «짓는다» 힌트가 뜨고, 보이기 전에 해낸 영웅 이동은 끝난 것으로 치며, 지으면 «거점», 거점을 누르면 «전투 시작»으로 바뀌고, 전투가 시작되면 숨는다
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
	if r != Rect2(68, 300, 200, 40) or not "짓는다" in said:
		out = "새 설정의 1라운드 준비 단계 힌트 칸 %s · 글 «%s»(기대: [68,300,200,40], «짓는다»)" % [r, said]
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
		if b.build("tower", Vector2i(20, 62)) == null:
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
		if b.state != "battle" or r != Rect2(68, 300, 200, 40) or not "3·5·7" in said:
			out = "2웨이브 전투 단계(단계 %s) 힌트 칸 %s · 글 «%s»(기대: [68,300,200,40], «3·5·7»)" % [b.state, r, said]
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
	_pass(main, 1.1)  # 전투에서 넘어온 결과 창은 1초 뒤에 뜬다(S117)
	_layout(main)
	_gather(main, "라운드 승리 창", seen)
	_gather_tips(main, hud.window.find_children("*", "BaseButton", true, false).filter(func(n): return n.is_visible_in_tree()), "승리 창 툴팁", seen)
	b.next_round()
	b.start_battle()
	b.damage(b.base, BIG, "true")
	_frame(main)
	_pass(main, 1.1)
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
	var titled: bool = seen.any(func(p): return p[0] == "라운드 승리 창" and "Next Round" in p[1])
	var tips: int = seen.filter(func(p): return p[0].begins_with("승리 창 툴팁")).size()
	var ended: bool = seen.any(func(p): return p[0] == "패배 창" and "New Run" in p[1])
	if not titled or tips == 0 or not ended:
		return "결과 창 글을 모으지 못했다(승리 창 «Next Round» %s · 승리 창 툴팁 %d개 · 패배 창 «New Run» %s)" % [titled, tips, ended]
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

# 방향키 하나를 누르거나 뗀다. Input 상태(Input.is_key_pressed)까지 바뀌게 parse_input_event로 넣고 바로 흘린다
func _hold(code: int, down: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = down
	Input.parse_input_event(e)
	Input.flush_buffered_events()

# 맵 가운데에 둔 카메라를 code 방향키를 누른 채 0.5초 돌린 뒤의 이동(맵 px)
func _keyed(cam, code: int) -> Vector2:
	var center: Vector2 = cam.map_px / 2
	cam.position = center
	_hold(code, true)
	cam.keys(0.5)
	_hold(code, false)
	return cam.position - center

# 1라운드 전투를 시작해 HUD가 전투 단계를 본 게임 장면
func _fighting():
	var main = _prep()
	main.view.battle.start_battle()
	_frame(main)
	return main

func _window_state(hud) -> String:
	return "창 %s · 덮개 %s" % [hud.window.is_visible_in_tree(), hud.dim.is_visible_in_tree()]

# EV387 · S117: 전투에서 라운드 사이·패배로 넘어가면 결과 창과 덮개는 1초 뒤에 뜨고, 그동안 Enter는 창만 연다. 이어하기로 불러온 라운드 사이는 바로 뜬다
func ev387():
	var main = _fighting()
	var b = main.view.battle
	var hud = main.hud
	if not _win(b):
		_done(main)
		return "1라운드를 이기지 못했다(%s)" % b.state
	_frame(main)
	_pass(main, 0.5)
	var out := ""
	if hud.window.is_visible_in_tree() or hud.dim.is_visible_in_tree():
		out = "라운드 사이 0.5초에 %s(둘 다 숨어 있어야 한다)" % _window_state(hud)
	if out == "":
		_pass(main, 0.6)
		var f = Engine.get_main_loop().root.gui_get_focus_owner()
		var on: String = f.text if f is BaseButton else str(f)
		if not hud.window.is_visible_in_tree() or not hud.dim.is_visible_in_tree() or not "다음 라운드" in on:
			out = "라운드 사이 1.1초에 %s · 포커스 «%s»(둘 다 보이고 포커스는 «다음 라운드»여야 한다)" % [_window_state(hud), on]
	var snap: Dictionary = _save().snapshot(b)
	_done(main)
	if out == "":
		main = _fighting()
		b = main.view.battle
		hud = main.hud
		_win(b)
		_frame(main)
		_pass(main, 0.5)
		_key(KEY_ENTER)
		hud._process(0.0)
		if b.state != "cleared" or not hud.window.is_visible_in_tree():
			out = "라운드 사이 0.5초에 Enter: 단계 %s · %s(라운드 사이 그대로 창이 보여야 한다)" % [b.state, _window_state(hud)]
		_done(main)
	if out == "":
		main = _fighting()
		b = main.view.battle
		hud = main.hud
		b.damage(b.base, BIG, "true")
		_frame(main)
		_pass(main, 0.5)
		var hid: bool = not hud.window.is_visible_in_tree()
		_key(KEY_ENTER)
		hud._process(0.0)
		if b.state != "lost" or not hid or not hud.window.is_visible_in_tree():
			out = "패배: 0.5초에 창 숨음 %s · Enter 뒤 단계 %s · %s(숨었다가 패배 그대로 창이 보여야 한다)" % [hid, b.state, _window_state(hud)]
		_done(main)
	if out == "":
		load("res://src/main.gd").resume = snap
		main = load("res://src/main.tscn").instantiate()
		Engine.get_main_loop().root.add_child(main)
		_frame(main)
		out = check(main.view.battle.state == "cleared" and main.hud.window.is_visible_in_tree(), "이어하기로 불러온 라운드 사이: 단계 %s · %s(창이 바로 보여야 한다)" % [main.view.battle.state, _window_state(main.hud)])
		_done(main)
	return out

# EV389 · S53: 가장자리·방향키 이동은 초당 640 화면 px × 카메라 속도. 키보드 포커스를 쥔 버튼이 있으면 방향키로 움직이지 않는다
func ev389():
	var st = load("res://src/settings.gd")
	var main = _prep()
	var cam = _cam(main)
	if not cam.has_method("keys"):
		_done(main)
		return "카메라에 keys(delta)가 없다"
	st.camera_speed = 100
	var center: Vector2 = cam.map_px / 2
	cam.position = center
	cam.scroll(Vector2(1279, 400), Vector2(1280, 720), 0.5)
	var edge: float = cam.position.x - center.x
	var right := _keyed(cam, KEY_RIGHT)
	var down := _keyed(cam, KEY_DOWN)
	st.camera_speed = 50
	var slow := _keyed(cam, KEY_RIGHT)
	st.camera_speed = 100
	var b := Button.new()
	main.hud.add_child(b)
	b.grab_focus()
	var held := _keyed(cam, KEY_RIGHT)
	b.free()
	_done(main)
	var ok := absf(edge - 160) <= 0.5 and absf(right.x - 160) <= 0.5 and absf(down.y - 160) <= 0.5 and absf(slow.x - 80) <= 0.5 and held.length() < 0.01
	return check(ok, "가장자리 %.1f · → %s · ↓ %s · 속도 50%% → %s · 포커스 중 → %s (기대 x 160 · x 160 · y 160 · x 80 · 0)" % [edge, right, down, slow, held])

# EV399 · S183: 맵 팝업이 떠 있으면 ESC는 그 팝업만 닫고 메뉴를 열지 않는다. 다음 ESC가 메뉴를 연다. 고른 영웅은 ESC로 풀리지 않는다
func ev399():
	var main = _prep()
	var c = main.controls
	var h = main.view.battle.heroes[0]
	c.selected = [h]
	c.village = true
	_frame(main)
	var shown: bool = not _pops(main).is_empty()
	_key(KEY_ESCAPE)
	var first: bool = not main.get_tree().paused and not c.village
	_frame(main)
	var hidden: bool = _pops(main).is_empty()
	_key(KEY_ESCAPE)
	var menu: bool = main.get_tree().paused
	var kept: bool = c.selected == [h]
	_done(main)
	return check(shown and first and hidden and menu and kept, "거점 팝업 뜸 %s · 첫 ESC에 팝업만 닫힘(멈추지 않음) %s · 팝업 숨음 %s · 둘째 ESC에 메뉴 %s · 고른 영웅 그대로 %s" % [shown, first, hidden, menu, kept])

# 2026-10-25 ui-sel(S206·S207, S186 변경). 위 계약에 더하는 API:
#   main.hud.select — 선택 패널(Control, S206). 보이는 Label이 글이고, 여럿이면 보이는 BaseButton 하나가 그림 칸 하나다
#   main.controls.shown — 패널에 보인 적(S206). main.view.foot_mark(유닛·적) — 발밑 표시 «pick»(고름)·«foe»(패널의 적)·«»(S207)

func _sel_text(main) -> Array:
	var s = main.hud.get("select")
	return [] if s == null or not s.is_visible_in_tree() else _labels(s)

func _missing(lines: Array, want: Array) -> Array:
	return want.filter(func(w): return not w in lines)

# EV410 · S206: 하나를 고르면 패널에 그림·이름·Lv·체력과 스탯이 보이고, 고른 용병은 정보 칸이 아니라 패널에 보인다
func ev410():
	var main = _prep()
	var b = main.view.battle
	var s = main.hud.get("select")
	if s == null:
		_done(main)
		return "main.hud.select가 없다"
	_key(KEY_F1)
	_frame(main)
	var h = b.heroes[0]
	var want := [main.hud.HEROES[h.kind], "Lv%d" % h.level, "체력 %d/%d" % [ceili(h.hp), ceili(h.max_hp)], "공격력 %s" % main.hud._num(h.damage),
		"사거리 %s칸" % main.hud._num(h.range) if h.range > b.RANGED else "사거리 근접", "공격 간격 %s초" % main.hud._num(h.attack_gap), "이동 %s칸/초" % main.hud._num(h.speed), "방어력 %s" % main.hud._num(h.armor)]
	var r: Rect2 = s.get_global_rect()
	var miss := _missing(_sel_text(main), want)
	var vis: bool = s.is_visible_in_tree()
	var one: bool = main.controls.selected == [h] and vis and r.is_equal_approx(Rect2(312, 288, 196, 72)) and miss.is_empty()
	var m = b.place_merc("soldier", Vector2i(30, 31))
	click(main.controls, MOUSE_BUTTON_LEFT, px(Vector2i(30, 31)))
	_frame(main)
	var g = main.hud.grid
	g._process(0.0)
	var merc_miss := _missing(_sel_text(main), ["용병", "사거리 근접"])
	var merc: bool = m != null and main.controls.selected == [m] and merc_miss.is_empty() and not g.info.is_visible_in_tree()
	var info: bool = g.info.is_visible_in_tree()
	main.controls.selected = []
	main.controls.selling = []
	_frame(main)
	var hidden: bool = not s.is_visible_in_tree()
	_done(main)
	return check(one and merc and hidden, "영웅 하나: 패널 보임 %s·%s, 빠진 글 %s · 용병: 고름 %s, 빠진 글 %s, 정보 칸 보임 %s · 비우면 숨음 %s" % [vis, r, miss, m != null, merc_miss, info, hidden])

# EV411 · S206: 여럿이면 그림 칸 버튼이 하나씩이고, 칸을 누르면 그 유닛만 고른다
func ev411():
	var main = _prep()
	var b = main.view.battle
	var c = main.controls
	var s = main.hud.get("select")
	if s == null:
		_done(main)
		return "main.hud.select가 없다"
	for p in [Vector2i(28, 62), Vector2i(30, 62), Vector2i(32, 62)]:  # 성곽 앞줄(59행)·출전 칸(61행) 아래(S203 2026-10-26 둘째 변경)
		b.place_merc("soldier", p)
	drag(c, px(Vector2i(27, 60)), px(Vector2i(33, 63)))
	_frame(main)
	var btns: Array = s.find_children("*", "BaseButton", true, false).filter(func(x): return x.is_visible_in_tree())
	var r: Rect2 = s.get_global_rect()
	var apart := true
	for i in btns.size():
		apart = apart and r.encloses(btns[i].get_global_rect())
		for j in range(i + 1, btns.size()):
			apart = apart and not btns[i].get_global_rect().intersects(btns[j].get_global_rect())
	var five: bool = c.selected.size() == 5 and btns.size() == 5 and apart
	var pick = c.selected[2] if c.selected.size() > 2 else null
	if btns.size() > 2:
		btns[2].pressed.emit()
	_frame(main)
	var one: bool = pick != null and c.selected == [pick] and "용병" in _sel_text(main)
	_done(main)
	return check(five and one, "고른 것 %d · 보이는 칸 %d · 패널 안·안 겹침 %s · 셋째 칸 누름 뒤 그 유닛만 %s(고른 것 %d)" % [c.selected.size(), btns.size(), apart, one, c.selected.size()])

# EV412 · S206, S183: 적을 누르면 고른 유닛은 그대로 두고 패널만 그 적이다. ESC·다시 고름·그 적의 죽음에 패널이 돌아오고, ESC는 그때 메뉴를 열지 않는다
func ev412():
	var main = _prep()
	var b = main.view.battle
	var c = main.controls
	if main.hud.get("select") == null:
		_done(main)
		return "main.hud.select가 없다"
	var h = b.heroes[0]
	var name: String = main.hud.HEROES[h.kind]
	_key(KEY_F1)
	var e = b.spawn_enemy("basic", Vector2i(30, 33), {"speed": 0, "sight": 0, "damage": 0, "hp": BIG})
	click(c, MOUSE_BUTTON_LEFT, px(Vector2i(30, 33)))
	_frame(main)
	var foe: bool = c.selected == [h] and _missing(_sel_text(main), ["기본 적", "사거리 근접"]).is_empty() and not name in _sel_text(main)
	_key(KEY_ESCAPE)
	_frame(main)
	var esc: bool = not main.get_tree().paused and name in _sel_text(main)
	_key(KEY_ESCAPE)
	var menu: bool = main.get_tree().paused
	main._on_menu("continue")  # 메뉴의 «계속»
	click(c, MOUSE_BUTTON_LEFT, px(Vector2i(30, 33)))
	_key(KEY_F1)
	_frame(main)
	var again: bool = name in _sel_text(main)
	click(c, MOUSE_BUTTON_LEFT, px(Vector2i(30, 33)))
	click(c, MOUSE_BUTTON_LEFT, px(Vector2i(h.pos.round())))  # 영웅을 클릭으로 다시 고름
	_frame(main)
	var clicked: bool = c.selected == [h] and name in _sel_text(main)
	click(c, MOUSE_BUTTON_LEFT, px(Vector2i(30, 33)))
	click(c, MOUSE_BUTTON_LEFT, px(b.base.cell))  # 거점을 누름: 유닛 선택이 빈다(S204)
	_frame(main)
	var base: bool = c.selected.is_empty() and not main.hud.select.is_visible_in_tree()
	_key(KEY_F1)
	click(c, MOUSE_BUTTON_LEFT, px(Vector2i(30, 33)))
	_frame(main)
	var shown: bool = "기본 적" in _sel_text(main)
	b.damage(e, BIG, "true")
	_frame(main)
	var dead: bool = shown and name in _sel_text(main)
	_done(main)
	return check(foe and esc and menu and again and clicked and base and dead, "적 누름: 영웅 그대로·패널 적 %s · ESC에 메뉴 없이 패널 영웅 %s · 둘째 ESC에 메뉴 %s · F1에 패널 영웅 %s · 영웅 클릭에 패널 영웅 %s · 거점 누름에 패널 숨음 %s · 적이 쓰러지면 패널 영웅 %s" % [foe, esc, menu, again, clicked, base, dead])

# EV413 · S186: 선택 패널이 보이고 카메라가 맨 아래면 정보 칸은 패널 왼쪽 [178,306,130,54]다. 패널이 없으면 격자 왼쪽 376이다
func ev413():
	var main = _prep()
	var g = main.hud.get("grid")
	if main.hud.get("select") == null:
		_done(main)
		return "main.hud.select가 없다"
	var cam = _cam(main)
	_key(KEY_F1)
	_frame(main)
	_move(g.cells.archery.get_global_rect().get_center())
	var out := ""
	for lv in 3:
		cam.zoom_at(lv - cam.level, Vector2(320, 180))
		cam.pan(Vector2(0, 1), 100.0)
		cam.force_update_scroll()
		g._process(0.0)
		var r: Rect2 = g.info.get_global_rect()
		if not g.info.is_visible_in_tree() or absf(r.position.x - 178) > 0.5 or absf(r.end.y - 360) > 0.5 or absf(r.size.x - 130) > 0.5:
			out = "%d배 줌 맨 아래, 패널이 보일 때 정보 칸이 %s다(보임 %s)" % [cam.zoom.x, r, g.info.is_visible_in_tree()]
			break
	if out == "":
		main.controls.selected = []
		_frame(main)
		g._process(0.0)
		var r: Rect2 = g.info.get_global_rect()
		if absf(r.position.x - 376) > 0.5:
			out = "고른 것을 비운 뒤 정보 칸이 %s다(x 376이어야 한다)" % r
	_done(main)
	return out if out != "" else check(true, "")

# EV414 · S207: 고른 영웅·용병은 «pick», 패널의 적은 «foe» 발밑 표시다
func ev414():
	var main = _prep()
	var b = main.view.battle
	var c = main.controls
	if not main.view.has_method("foot_mark"):
		_done(main)
		return "main.view.foot_mark가 없다"
	var h0 = b.heroes[0]
	var h1 = b.heroes[1]
	_key(KEY_F1)
	var e = b.spawn_enemy("basic", Vector2i(30, 33), {"speed": 0, "sight": 0, "damage": 0, "hp": BIG})
	click(c, MOUSE_BUTTON_LEFT, px(Vector2i(30, 33)))
	var v = main.view
	var first := [v.foot_mark(h0), v.foot_mark(e), v.foot_mark(h1)]
	_key(KEY_F2)
	var second := [v.foot_mark(h0), v.foot_mark(h1), v.foot_mark(e)]
	_done(main)
	return check(first == ["pick", "foe", ""] and second == ["", "pick", ""], "첫 영웅 고르고 적 누름 %s(pick, foe, «») · F2 뒤 %s(«», pick, «»)" % [first, second])

# EV415 · S188: 선택 패널이 보이면 패널과 겹치는 가장자리 표식은 패널 바로 위(아래끝 y 286)로 올라간다
func ev415():
	var main = _prep()
	if main.hud.get("select") == null:
		_done(main)
		return "main.hud.select가 없다"
	_key(KEY_F1)
	_frame(main)
	var marks: Array = main.hud.edges.get_children().filter(func(m): return m.is_visible_in_tree())
	var lifted := 0
	var bad := []
	for m in marks:
		var r: Rect2 = m.get_global_rect()
		var over: bool = r.end.x > 312.0
		lifted += int(over)
		if (over and absf(r.end.y - 286.0) > 0.5) or (not over and absf(r.position.y - 344.0) > 0.5):
			bad.append(r)
	main.controls.selected = []
	_frame(main)
	for m in marks:
		if m.is_visible_in_tree() and absf(m.get_global_rect().position.y - 344.0) > 0.5:
			bad.append(["비운 뒤", m.get_global_rect()])
	var n := marks.size()
	_done(main)
	return check(lifted > 0 and bad.is_empty(), "보이는 표식 %d · 패널과 겹쳐 올라간 것 %d · 자리가 틀린 것 %s" % [n, lifted, bad])

# 준비 단계 실시간 게임 장면(I175): Main.live_prep을 켜고 띄운 뒤 끈다. 판은 켠 값을 쥔다
func _live_prep():
	var M = load("res://src/main.gd")
	M.live_prep = true
	var main = _prep()
	M.live_prep = false
	return main

# EV418 · S83: 준비 단계 실시간 게임 장면의 준비 단계에 미완성 병영을 누르면 «이어 짓기»·«취소»가 뜨고 «완성»·«판매»는 없다
func ev418():
	var main = _live_prep()
	var b = main.view.battle
	var c = main.controls
	var f = b.build("barracks", _near(b, "barracks", Vector2i(26, 32)))
	var texts := func(): return _pops(main).map(func(n): return n.text)
	var out := ""
	if f == null or f.complete or f.worker == null:
		out = "준비 단계 병영: %s · 완성 %s · 일꾼 %s" % [f, f.complete if f else null, f.worker if f else null]
	if out == "":
		click(c, MOUSE_BUTTON_LEFT, px(f.cell))
		_frame(main)
		if texts.call() != ["취소"]:
			out = "공병이 일하는 병영을 누른 팝업 버튼: %s(«취소» 하나여야 한다)" % [texts.call()]
	if out == "":
		b.order_move([f.worker], Vector2i(40, 5))
		_frame(main)
		var t: Array = texts.call()
		if not ("이어 짓기" in t and "취소" in t) or t.any(func(s): return s == "완성" or s.begins_with("판매")):
			out = "일을 그만둔 병영의 팝업 버튼: %s" % [t]
	if out == "":
		_press(main.hud.popup, "이어 짓기")
		if f.worker == null:
			out = "«이어 짓기»를 눌러도 일꾼이 없다"
	if out == "":
		b.order_move([f.worker], Vector2i(40, 5))
		click(c, MOUSE_BUTTON_LEFT, px(f.cell))  # 버튼을 누르면 팝업이 닫힌다(_apply)
		_frame(main)
		var g: int = b.gold
		_press(main.hud.popup, "취소")
		out = check(b.structure_at(f.cell) == null and b.gold == g + f.paid, "«취소» 뒤 병영 %s · 골드 %d → %d(건설비 %d)" % [b.structure_at(f.cell), g, b.gold, f.paid])
	_done(main)
	return out

# EV423 · I20: 준비 단계 실시간 게임 장면의 준비 단계에도 완성된 병영 팝업의 구매 버튼과 건설 격자 용병 칸으로 산다
func ev423():
	var main = _live_prep()
	var b = main.view.battle
	var c = main.controls
	var f = b.build("barracks", _near(b, "barracks", Vector2i(26, 32)))
	var out := ""
	if f == null or not run(b, 30.0, func(): return f.complete):
		out = "준비 단계 병영이 30초 안에 완성되지 않았다(%s)" % f
	if out == "":
		click(c, MOUSE_BUTTON_LEFT, px(f.cell))
		_frame(main)
		var buy = _starts(main.hud.popup, "용병")
		var n := _soldiers(b)
		if buy:
			buy.pressed.emit()
		var m = b.units.filter(func(u): return u.kind == "soldier").back() if _soldiers(b) > 0 else null
		if buy == null or _soldiers(b) != n + 1 or m.pos.distance_to(Vector2(f.cell)) > 1.5:
			out = "병영 팝업 «용병» 버튼 %s · 용병 %d → %d · 나온 자리 %s(병영 %s)" % [buy, n, _soldiers(b), m.pos if m else null, f.cell]
	if out == "":
		var n := _soldiers(b)
		main.hud.grid.cells.soldier.pressed.emit()
		main.hud.grid.cells.soldier.pressed.emit()
		out = check(c.placing == "" and _soldiers(b) > n, "건설 격자 용병 칸을 두 번 누른 뒤 놓기 모드 «%s» · 용병 %d → %d" % [c.placing, n, _soldiers(b)])
	_done(main)
	return out

# EV425 · S98: live_prep 게임 장면은 작업장이 없어도 공병 칸이 거점을 고르고 거점 팝업에서 공병을 산다. 거점을 고르고 우클릭하면 거점의 집결 지점이다
func ev425():
	var main = _live_prep()
	var b = main.view.battle
	var c = main.controls
	var count := func(): return b.units.filter(func(u): return u.kind == "engineer").size()
	b.sell(b.units.filter(func(u): return u.kind == "engineer"))
	_frame(main)
	main.hud.grid._process(0.0)
	var cell: Button = main.hud.grid.cells.engineer
	var out := ""
	if count.call() != 0 or absf(cell.modulate.a - 1.0) > 0.01:
		out = "작업장 없는 판: 남은 공병 %d · 공병 칸 불투명도 %s" % [count.call(), cell.modulate.a]
	if out == "":
		cell.pressed.emit()
		_frame(main)
		var buy = _starts(main.hud.popup, "공병")
		if c.placing != "" or c.facility != b.base or buy == null:
			out = "공병 칸을 누른 뒤 놓기 모드 «%s» · 고른 시설 %s(거점 %s) · 팝업 «공병» %s" % [c.placing, c.facility, b.base, buy]
		else:
			cell.pressed.emit()
			var n: int = count.call()
			buy.pressed.emit()
			if n != 1 or count.call() != 2:
				out = "공병 칸을 다시 누른 뒤 공병 %d(1이어야 한다) · 팝업 버튼 뒤 %d(2여야 한다)" % [n, count.call()]
	if out == "":
		var to: Vector2i = _near(b, "barracks", Vector2i(26, 15))
		click(c, MOUSE_BUTTON_LEFT, px(b.base.cell))
		click(c, MOUSE_BUTTON_RIGHT, px(to))
		out = check(c.facility == b.base and b.base.rally == to, "거점을 누르고 %s 우클릭: 고른 시설 %s · 거점 집결 지점 %s" % [to, c.facility, b.base.rally])
	_done(main)
	return out

# EV428 · S53: 가장자리·방향키 이동은 0.12초에 최고 속도에 오르고, 입력이 없으면 0.15초에 선다. 경계에 닿은 축은 바로 선다
func ev428():
	load("res://src/settings.gd").camera_speed = 100
	var main = _prep()
	var cam = _cam(main)
	var dt := 1.0 / 60.0
	var top: float = 640.0 / cam.zoom.x * dt  # 최고 속도 한 프레임(맵 px)
	cam.position = cam.map_px / 2
	var steps := []
	for i in 8:
		var x0: float = cam.position.x
		cam.scroll(Vector2(1279, 400), Vector2(1280, 720), dt)
		steps.append(cam.position.x - x0)
	var x1: float = cam.position.x
	var frames := 0
	while cam.busy() and frames < 30:
		cam.glide(dt)
		frames += 1
	var coast: float = cam.position.x - x1
	_away(main)
	cam.scroll(Vector2(1279, 400), Vector2(1280, 720), dt)
	var walled: bool = cam.busy()
	_done(main)
	var ok: bool = steps[0] > 0.0 and steps[0] < top - 0.01 and absf(steps[7] - top) <= 0.01 and coast > 0.0 and frames <= 12 and not walled
	return check(ok, "프레임마다 x %s(최고 %.3f) · 입력을 끊고 %.2f를 더 가서 %d프레임에 섬 · 경계에서 움직이는 중 %s" % [steps.map(func(s): return snappedf(s, 0.001)), top, coast, frames, walled])

# EV429 · S52: 휠로 바꾼 줌은 0.2초 ease-out으로 옮겨 가고, 옮기는 동안 화면 배율은 정수만 지나며 커서 아래 지점이 그대로다
func ev429():
	var root: Window = Engine.get_main_loop().root
	var size0 := root.size
	root.size = Vector2i(1280, 720)  # 창 배율 2. 헤드리스 창(64×64)은 배율 1이라 중간 배율이 없다
	var main = _prep()
	var cam = _cam(main)
	var at := Vector2(400, 200)
	var under := func() -> Vector2:
		cam.force_update_scroll()
		return main.hud.map.get_canvas_transform().affine_inverse() * at
	var p0: Vector2 = under.call()
	for down in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_WHEEL_UP
		e.position = at
		e.global_position = at
		e.pressed = down
		root.push_input(e, true)
	var lv: int = cam.level
	var z: float = cam.zoom.x
	var scales := []
	var drift := 0.0
	while cam.busy() and scales.size() < 30:
		cam.glide(1.0 / 60.0)
		scales.append(cam.zoom.x * 2.0)
		drift = maxf(drift, under.call().distance_to(p0))
	var last: float = cam.zoom.x
	_done(main)
	root.size = size0
	var whole: bool = not scales.is_empty() and scales.all(func(s): return absf(s - roundf(s)) < 0.001)
	var five: bool = scales.any(func(s): return absf(s - 5.0) < 0.001)
	return check(lv == 2 and is_equal_approx(z, 2.0) and whole and five and drift <= 0.5 and scales.size() <= 13 and is_equal_approx(last, 3.0), "휠 그 프레임: 단계 %d · 줌 %s / 프레임마다 화면 배율 %s · 커서 아래 지점이 %.2f 움직임 · 끝 줌 %s" % [lv, z, scales, drift, last])

# EV430 · I164: HUD가 옮기는 카메라는 0.2초 동안 미끄러져 간다. 미끄러지는 중에 방향키가 들어오면 남은 미끄러짐을 버린다
func ev430():
	var main = _prep()
	var cells = main.hud.get("cells")
	var cam = _cam(main)
	var keep := Vector2(main.view.battle.base.cell) * 16 + Vector2(8, 8)
	var gap := func() -> float:
		cam.force_update_scroll()
		return (main.hud.map.get_canvas_transform() * keep).distance_to(FOCUS)
	_away(main)
	cells.status.pressed.emit()
	var out := ""
	if gap.call() <= 1.0 or not cam.busy():
		out = "상태 묶음을 누른 프레임: 거점과 (320,194) 거리 %.1f · 움직이는 중 %s(멀고 움직이는 중이어야 한다)" % [gap.call(), cam.busy()]
	if out == "":
		for i in 15:
			cam.glide(1.0 / 60.0)
		out = "15프레임 뒤에도 움직이는 중이다" if cam.busy() else _focused(main, keep)
	if out == "":
		_away(main)
		cells.status.pressed.emit()
		cam.glide(1.0 / 60.0)
		_hold(KEY_LEFT, true)
		cam.keys(1.0 / 60.0)
		_hold(KEY_LEFT, false)
		for i in 30:
			cam.glide(1.0 / 60.0)
		out = check(gap.call() > 1.0, "미끄러지는 중에 ←를 누른 뒤에도 거점이 (320,194)에서 %.1f — 남은 미끄러짐을 버려야 한다" % gap.call())
	_done(main)
	return out

const MINI := Rect2(2, 295, 62, 65)  # 미니맵(S209). 테두리 1px 안에 칸당 1px. 60×63칸 창이 세로로 스크롤된다(2026-10-26 둘째 변경)
const EVAC := Rect2(3, 266, 60, 26)  # 대피령 버튼(S230)

# 미니맵 위 맵 칸 c 가운데의 화면 자리
func _mini(c: Vector2) -> Vector2:
	return MINI.position + Vector2.ONE + c + Vector2(0.5, 0.5)

# 맵 칸 c 가운데의 화면 자리
func _on(main, c: Vector2) -> Vector2:
	_cam(main).force_update_scroll()
	return main.hud.map.get_canvas_transform() * ((c + Vector2(0.5, 0.5)) * 16)

# 화면 at에 마우스 버튼 누름·뗌 입력을 넣는다
func _button_at(at: Vector2, button: int, down: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = button
	e.position = at
	e.global_position = at
	e.pressed = down
	e.button_mask = (1 << (button - 1)) if down else 0
	Engine.get_main_loop().root.push_input(e, true)

# 좌버튼을 누른 채 화면 at으로 커서를 옮긴다
func _drag_to(at: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = at
	e.global_position = at
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	Engine.get_main_loop().root.push_input(e, true)

# EV431 · S209: 미니맵은 준비·전투 단계에 [2,295,62,63]에 보이고, 영입 창에는 숨는다
func ev431():
	var main = _game()
	_frame(main)
	if main.hud.get("minimap") == null:
		_done(main)
		return "main.hud.minimap이 없다"
	var hiring: bool = main.hud.minimap.is_visible_in_tree()
	_done(main)
	main = _prep()
	var m = main.hud.minimap
	var prep: bool = m.is_visible_in_tree()
	var r: Rect2 = m.get_global_rect()
	main.view.battle.start_battle()
	_frame(main)
	var fight: bool = m.is_visible_in_tree()
	_done(main)
	return check(not hiring and prep and r.is_equal_approx(MINI) and fight, "영입 창 보임 %s · 준비 단계 보임 %s·%s · 전투 단계 보임 %s" % [hiring, prep, r, fight])

# EV432 · S209: 미니맵을 누르고 3px 안에서 떼면 그 자리(창 맨 윗줄을 더한 칸)를 화면 가운데(320,194)로 바로 옮기고, 미끄러짐을 버리며, 놓기 모드와 맵은 건드리지 않는다.
# 누른 채 끌면 카메라는 그대로이고 창이 끈 만큼 스크롤되며, 뗀 뒤 버튼 없이 옮겨도 카메라는 그대로다(2026-10-26 둘째 변경)
func ev432():
	var main = _prep()
	var m = main.hud.get("minimap")
	if m == null or not m.has_method("follow"):
		_done(main)
		return "main.hud.minimap.follow가 없다"
	var b = main.view.battle
	var cam = _cam(main)
	_away(main)
	main.hud.cells.status.pressed.emit()
	var sliding: bool = cam.busy()
	_key(KEY_2)
	var n: int = b.structures.size()
	cam.force_update_scroll()
	m.follow()
	var top: int = m.top
	_button_at(_mini(Vector2(40, 20)), MOUSE_BUTTON_LEFT, true)
	_button_at(_mini(Vector2(40, 20)) + Vector2(1, 1), MOUSE_BUTTON_LEFT, false)
	var d1: Vector2 = (_on(main, Vector2(40, 20 + top)) - FOCUS).abs()
	var still: bool = not cam.busy()
	var kept: bool = b.structures.size() == n and main.controls.placing == "tower"
	cam.force_update_scroll()
	m.follow()
	var top1: int = m.top
	var p: Vector2 = cam.position
	_button_at(_mini(Vector2(10, 20)), MOUSE_BUTTON_LEFT, true)
	_drag_to(_mini(Vector2(10, 30)))
	var scrolled: int = m.top
	var want := clampi(top1 - 10, 0, b.size.y - 63)
	_button_at(_mini(Vector2(10, 30)), MOUSE_BUTTON_LEFT, false)
	_move(_mini(Vector2(40, 50)))
	var stays: bool = cam.position.is_equal_approx(p)
	_done(main)
	return check(sliding and maxf(d1.x, d1.y) <= 0.5 and still and kept and scrolled == want and top1 > 0 and stays,
		"누르기 전 미끄러지는 중 %s · 클릭: 창 (40,20)+윗줄 %d가 (320,194)에서 %s, 멈춤 %s, 구조물·놓기 그대로 %s · 끌기: 창 윗줄 %d → %d(%d여야 한다), 카메라 그대로 %s" % [sliding, top, d1, still, kept, top1, scrolled, want, stays])

# EV433 · S209: 미니맵의 카메라 사각형은 위 띠 아래 보이는 맵을 칸 단위로 옮겨 창 윗줄만큼 올린 것이고, 창은 그 사각형이 들어오게 따라간다
func ev433():
	var main = _prep()
	var m = main.hud.get("minimap")
	if m == null or not m.has_method("view_rect"):
		_done(main)
		return "main.hud.minimap.view_rect가 없다"
	var cam = _cam(main)
	var bad := []
	for lv in 3:
		cam.zoom_at(lv - cam.level, Vector2(320, 180))
		for at in [cam.map_px / 2, Vector2.ZERO, cam.map_px]:
			cam.position = at
			cam.pan(Vector2.ZERO, 0.0)
			cam.force_update_scroll()
			var z: float = cam.zoom.x
			var seen := Rect2(cam.position + (Vector2(0, 28) - Vector2(320, 180)) / z, Vector2(640, 332) / z)
			m.follow()
			var want := Rect2(seen.position / 16 + Vector2(1, 1 - m.top), seen.size / 16).intersection(Rect2(1, 1, 60, 63))
			var vis := Rect2(seen.position / 16, seen.size / 16).intersection(Rect2(Vector2.ZERO, Vector2(main.view.battle.size)))  # 카메라가 보는 맵 칸
			if vis.size.y <= 63 and (vis.position.y < m.top - 0.01 or vis.end.y > m.top + 63 + 0.01):
				bad.append(["창 밖", z, cam.position, m.top])
			var got: Rect2 = m.view_rect()
			var d: Vector2 = (got.position - want.position).abs()
			var e: Vector2 = (got.size - want.size).abs()
			if maxf(maxf(d.x, d.y), maxf(e.x, e.y)) > 0.01:
				bad.append([z, cam.position, got, want])
	_done(main)
	return check(bad.is_empty(), "[줌, 카메라, 그린 사각형, 기대] %s" % [bad])

# EV434 · S209: 미니맵 점은 칸마다 정해진 색·크기로 정해진 차례에 그리고, 바닥은 맵 바닥 그림을 칸 크기로 줄인 것이다
func ev434():
	var main = _prep()
	var m = main.hud.get("minimap")
	if m == null or not m.has_method("marks"):
		_done(main)
		return "main.hud.minimap.marks가 없다"
	var b = main.view.battle
	b.build("tower", Vector2i(20, 62))
	b.place_merc("soldier", Vector2i(30, 63))  # 출전 칸(61행, I107) 아래
	var still := {"speed": 0, "sight": 0, "damage": 0, "hp": BIG}
	var e = b.spawn_enemy("basic", Vector2i(20, 70), still)
	e.pos = Vector2(20.6, 70.4)  # 몸 가운데가 든 칸은 (21,70)
	b.spawn_enemy("boss", Vector2i(40, 70), still)
	b.damage(b.walls[Vector2i(10, 57)], BIG, "true")  # 10열 남벽(57~59행)
	_cam(main).force_update_scroll()
	m.follow()  # 창은 정문 앞 카메라를 따라간다(S209). 점 자리는 칸 + 1 − 창 맨 윗줄 t
	var t: int = m.top
	var marks: Array = m.marks()
	var want := [[Rect2(22, 71 - t, 1, 1), "ff3b3b"], [Rect2(41, 71 - t, 2, 2), "ff3b3b"], [Rect2(31, 64 - t, 1, 1), "3ce0d8"], [Rect2(21, 63 - t, 1, 1), "8fd8ff"],
		[Rect2(30, 30 - t, 3, 3), "ffd37f"], [Rect2(11, 58 - t, 1, 1), "4a4a50"], [Rect2(29, 58 - t, 1, 1), "9aa0aa"], [Rect2(31, 58 - t, 1, 1), "c08a4a"]]
	var miss := want.filter(func(w): return not marks.any(func(k): return k[0].is_equal_approx(w[0]) and k[1].is_equal_approx(Color(w[1]))))
	for h in b.heroes:
		var p: Vector2 = h.pos + Vector2(1.5, 1.5 - t)
		if not marks.any(func(k): return k[0].size == Vector2(2, 2) and k[0].has_point(p) and k[1].is_equal_approx(Color.WHITE)):
			miss.append([h.kind, p])
	var rank := {"4a4a50": 0, "9aa0aa": 1, "c08a4a": 1, "8fd8ff": 2, "ffd37f": 3, "3ce0d8": 4, "ff3b3b": 5, "ffffff": 6}
	var ranks: Array = marks.map(func(k): return rank.get(k[1].to_html(false), -1))
	var sorted := ranks.duplicate()
	sorted.sort()
	var ground: ImageTexture = load("res://src/ui/battle_view.gd").bake_ground(b)
	var small: Image = load("res://src/ui/hud_minimap.gd").shrink(ground, b.size).get_image()
	var big: Image = ground.get_image()
	var off := []
	for c in range(81).map(func(i): return Vector2i(i % 9, i / 9) * 7):
		var sum := Color(0, 0, 0, 0)
		for y in 16:
			for x in 16:
				sum += big.get_pixel(c.x * 16 + x, c.y * 16 + y)
		var avg: Color = sum / 256.0
		var got := small.get_pixel(c.x, c.y)
		if maxf(maxf(absf(got.r - avg.r), absf(got.g - avg.g)), absf(got.b - avg.b)) > 0.08:
			off.append([c, got, avg])
	_done(main)
	return check(miss.is_empty() and not -1 in ranks and ranks == sorted and small.get_size() == b.size and off.is_empty(),
		"없는 점 %s · 색 차례 %s · 바닥 크기 %s · 평균과 다른 칸 %s" % [miss, ranks, small.get_size(), off])

# EV435 · S209: 미니맵 우클릭은 그 자리를 맵에서 우클릭한 것과 같다(고른 유닛 명령, 놓기 취소)
func ev435():
	var main = _prep()
	if main.hud.get("minimap") == null:
		_done(main)
		return "main.hud.minimap이 없다"
	var b = main.view.battle
	var c = main.controls
	var h = b.heroes[0]
	_key(KEY_F1)
	var cell := Vector2i(38, 45 + main.hud.minimap.top)  # 창 안 (38,45)에 창 맨 윗줄을 더한 칸
	for down in [true, false]:
		_button_at(_mini(Vector2(38, 45)), MOUSE_BUTTON_RIGHT, down)
	var at: Vector2 = c.order.get("at", Vector2.INF)
	var px := (Vector2(cell) + Vector2(0.5, 0.5)) * 16
	var sent: bool = at.distance_to(px) <= 0.01 and not h.path.is_empty() and h.path.back() == cell
	_key(KEY_2)
	var placing: String = c.placing
	var n: int = b.structures.size()
	for down in [true, false]:
		_button_at(_mini(Vector2(38, 45)), MOUSE_BUTTON_RIGHT, down)
	var off: bool = placing == "tower" and c.placing == "" and b.structures.size() == n
	_done(main)
	return check(sent and off, "명령 자리 %s(기대 %s, 칸 %s) · 영웅 길 끝 %s · 놓기 %s → %s, 구조물 %d → %d" % [at, px, cell, h.path.back() if not h.path.is_empty() else null, placing, c.placing, n, b.structures.size()])

# EV436 · S209: 커서가 미니맵 위면 가장자리 이동이 멈추고, 같은 x의 맵 위면 간다
func ev436():
	var main = _prep()
	if main.hud.get("minimap") == null:
		_done(main)
		return "main.hud.minimap이 없다"
	var cam = _cam(main)
	var size := Vector2(1280, 720)
	cam.position = cam.map_px / 2
	var at := Vector2(4, 356)
	_move(at)
	var p0: Vector2 = cam.position
	cam.scroll(at * 2, size, 1.0)
	var held: bool = cam.position.is_equal_approx(p0)
	var open := Vector2(4, 200)
	_move(open)
	cam.scroll(open * 2, size, 1.0)
	var moved: bool = cam.position.x < p0.x
	_done(main)
	return check(held and moved, "미니맵 위에서 그대로 %s · 맵 위에서 x가 줆 %s" % [held, moved])

# EV437 · S189: 왼쪽·아래 경보 표식은 미니맵과 겹치지 않는다
func ev437():
	var main = _prep()
	var b = main.view.battle
	b.heroes[0].pos = Vector2(1, 89)
	b.heroes[1].pos = Vector2(0, 64)
	for h in b.heroes.slice(0, 2):
		b.damage(h, BIG, "true")
	main.hud._process(0.0)
	var rs: Array = main.hud.alerts.find_children("*", "BaseButton", true, false).filter(func(x): return x.is_visible_in_tree()).map(func(x): return x.get_global_rect())
	var low := rs.filter(func(r): return absf(r.position.y - 344) < 0.01 and r.position.x >= 67.99)
	var side := rs.filter(func(r): return absf(r.position.x - 2) < 0.01 and r.end.y <= 264.01)
	_done(main)
	return check(rs.size() == 2 and low.size() == 1 and side.size() == 1 and not rs.any(func(r): return r.intersects(MINI) or r.intersects(EVAC)),
		"보이는 표식 %s · 아래 띠 %d · 왼쪽 띠 %d" % [rs, low.size(), side.size()])

# EV461 · S218: 문루·문 양옆 탑 그림 안(성곽 뒤 땅 칸)을 누르면 그 성곽을 고르고, 보통 성벽 열 뒤 칸은 아니며, 그 칸의 용병이 먼저다
func ev461():
	var main = _prep()
	var b = main.view.battle
	var c = main.controls
	var gate = b.castle.get(Vector2i(29, 59))
	var tower = b.castle.get(Vector2i(28, 59))
	if gate == null or gate.kind != "gate" or tower == null:
		_done(main)
		return "준비가 틀렸다: 정문 문루 %s · 왼쪽 탑 열 %s" % [gate, tower]
	click(c, MOUSE_BUTTON_LEFT, px(Vector2i(30, 55)))
	var on_gate: bool = c.fort == gate
	click(c, MOUSE_BUTTON_LEFT, px(Vector2i(28, 54)))
	var on_tower: bool = c.fort == tower
	click(c, MOUSE_BUTTON_LEFT, px(Vector2i(20, 55)))
	var plain: bool = c.fort == null
	var m = b.place_merc("soldier", Vector2i(30, 56))
	if m == null:
		_done(main)
		return "준비가 틀렸다: 문루 뒤 칸 (30,56)에 용병을 놓지 못했다"
	click(c, MOUSE_BUTTON_LEFT, px(Vector2i(30, 56)))
	var out := check(on_gate and on_tower and plain and c.fort == null and m in c.selected,
		"문루 뒤 누름에 문루 %s · 탑 뒤 누름에 탑 %s · 보통 성벽 뒤 누름에 빔 %s · 용병 칸 누름에 성곽 %s · 용병 골라짐 %s" % [on_gate, on_tower, plain, c.fort, m in c.selected])
	_done(main)
	return out

# EV463 · I128: 길 칸을 누른 놓기 거부의 이유는 «길에는 지을 수 없다»다
func ev463():
	var main = _prep()
	var hud = main.hud
	var b = main.view.battle
	var c = main.controls
	var built: int = b.structures.size()
	_key(KEY_0)
	click(c, MOUSE_BUTTON_LEFT, px(Vector2i(26, 29)))
	hud._process(0.0)
	var said: String = hud.hint.text
	var refused: bool = b.structures.size() == built
	click(c, MOUSE_BUTTON_LEFT, px(Vector2i(22, 21)))
	var out := check(refused and "길에는 지을 수 없다" in said and b.structures.size() == built + 1,
		"광장 칸 거부 %s · 누른 직후 안내 줄 «%s» · 고리 길 칸 뒤 구조물 %d → %d" % [refused, said, built, b.structures.size()])
	_done(main)
	return out

# EV466 · S219: 사방 성곽 그림의 높이와 누르기. 서·동 닫힌 문루 칸은 통로보다 8px, 네 모서리 탑 칸은 12px, 북문 문루는 17px·그 양옆 탑은 27px 올려 그리고
# 보통 북벽·동서 성벽 칸은 0이다. 게임 장면 준비 단계에 서쪽 닫힌 문루 그림(맵 px (24,448))을 누르면 그 문루를 고르고 «열기» 버튼이 없다.
# 서쪽 성벽 20행 그림(맵 px (24,304))을 누르면 20행 성벽을, 남서 모서리 탑 그림(맵 px (8,892))을 누르면 0열 남벽을 고른다. 정문 문루를 고르면 «열기» 버튼이 있다
func ev466():
	var main = _prep()
	var b = main.view.battle
	var c = main.controls
	var hud = main.hud
	var BV = load("res://src/ui/battle_view.gd")
	var rise := {Vector2i(1, 30): 8, Vector2i(58, 30): 8, Vector2i(1, 1): 12, Vector2i(58, 58): 12, Vector2i(30, 1): 17, Vector2i(28, 1): 27, Vector2i(32, 1): 27,
		Vector2i(30, 58): 17, Vector2i(10, 1): 0, Vector2i(1, 10): 0, Vector2i(58, 40): 0}
	var bad := []
	for k in rise:
		if BV.rise_at(b, k) != rise[k]:
			bad.append([k, BV.rise_at(b, k), rise[k]])
	var out := ""
	if not bad.is_empty():
		out = "[칸, 올림, 기대] %s" % [bad]
	if out == "":
		click(c, MOUSE_BUTTON_LEFT, Vector2(24, 448))
		_frame(main)
		var west = c.fort
		var opened = _button(hud.popup, "열기")
		click(c, MOUSE_BUTTON_LEFT, Vector2(24, 304))
		var row20 = c.fort
		click(c, MOUSE_BUTTON_LEFT, Vector2(8, 892))
		var corner = c.fort
		click(c, MOUSE_BUTTON_LEFT, px(Vector2i(30, 58)))
		_frame(main)
		var main_open = _button(hud.popup, "열기")
		out = check(west == b.castle.get(Vector2i(0, 31)) and opened == null and row20 == b.castle.get(Vector2i(0, 20)) and corner == b.castle.get(Vector2i(0, 59)) and main_open != null,
			"서쪽 문루 그림 누름 %s(«열기» %s) · 20행 그림 %s · 남서 모서리 탑 그림 %s · 정문 «열기» %s" % [west.cell if west else null, opened, row20.cell if row20 else null, corner.cell if corner else null, main_open])
	_done(main)
	return out

# EV467 · I180: 사방 성곽 맵의 성곽 경보 성문 이름은 거점에서 본 방향으로 남쪽 정문 «정문», 북·서·동 닫힌 문루 «북문»·«서문»·«동문»이다
func ev467():
	var main = _prep()
	var b = main.view.battle
	var a = main.hud.get("alerts")
	if a == null or not a.has_method("_name"):
		_done(main)
		return "main.hud.alerts._name이 없다"
	var gates: Array = b.castle.values().filter(func(k): return k.kind == "gate")
	var names := [Vector2i(29, 59), Vector2i(29, 2), Vector2i(0, 31), Vector2i(57, 31)].map(func(g): return a._name(b.castle[g], gates))
	_done(main)
	return check(names == ["정문", "북문", "서문", "동문"], "정문·북·서·동 문루 이름이 %s다" % [names])

# EV470 · S220: 바닥 그림의 연못·수로 가운데는 물 색이고(물 칸이 없는 판은 아니다), 미니맵 줄임의 연못 칸은 청록이다
func ev470():
	var BV = load("res://src/ui/battle_view.gd")
	var st: Dictionary = load("res://src/main.gd").stage()
	if not st.has("water"):
		return "시험 스테이지에 물 칸(water)이 없다"
	var waters := ["276468", "3c9f9c", "a4aec2"]  # 깊은 물색 183f39는 풀 점 색과 같아 세지 않는다
	var spots := [Vector2i(748, 268), Vector2i(728, 120)]
	var ground: ImageTexture = BV.bake_ground(battle(st))
	var wet: Array = spots.map(func(p): return ground.get_image().get_pixelv(p).to_html(false))
	var dry_st := st.duplicate()
	dry_st.erase("water")
	var dry_img: Image = BV.bake_ground(battle(dry_st)).get_image()
	var dry: Array = spots.map(func(p): return dry_img.get_pixelv(p).to_html(false))
	var c: Color = load("res://src/ui/hud_minimap.gd").shrink(ground, st.size).get_image().get_pixel(46, 16)
	return check(wet.all(func(h): return h in waters) and not dry.any(func(h): return h in waters) and c.g - c.r > 0.1 and c.b - c.r > 0.1,
		"물 판 두 픽셀 %s · 물 없는 판 %s · 미니맵 연못 칸 %s" % [wet, dry, c.to_html(false)])

# EV477 · S172: 아틀라스에 주민 몸 여섯 × look 여덟의 정지·걷기 4방향 칸이 있고 비어 있지 않다. look이 다르면 그림이 다르다
func ev477():
	var art: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/units/heroes.json"))
	var img: Image = load("res://art/units/heroes.png").get_image()
	var bad := []
	for body in ["man", "woman", "boy", "girl", "old_man", "old_woman"]:
		for look in 8:
			var a = art.get("folk_%s_%d" % [body, look])
			if a == null:
				bad.append("folk_%s_%d 없음" % [body, look])
				continue
			var c := int(a.c)
			for f in [["idle", 0], ["walk", 0], ["walk", 1]]:
				for dir in 4:
					var r := Rect2i(int(a.get("x", 0)) + f[1] * c, int(a[f[0]]) + dir * c, c, c)
					if not Rect2i(Vector2i.ZERO, img.get_size()).encloses(r) or img.get_region(r).is_invisible():
						bad.append("folk_%s_%d %s %d열 %d행" % [body, look, f[0], f[1], dir])
		var a0 = art.get("folk_%s_0" % body)
		var a1 = art.get("folk_%s_1" % body)
		if a0 and a1:
			var c0 := int(a0.c)
			var c1 := int(a1.c)
			if img.get_region(Rect2i(int(a0.get("x", 0)), int(a0.idle), c0, c0)).get_data() == img.get_region(Rect2i(int(a1.get("x", 0)), int(a1.idle), c1, c1)).get_data():
				bad.append("%s look 0·1 그림이 같다" % body)
	return check(bad.is_empty(), "%s" % [bad.slice(0, 8)])

# EV486 · S172: 주민 칸마다 그 몸의 역할(I182)이 맡는 직업의 일 자세가 있다. 제자리는 동·서 2행, 들고 걷기는 4방향 4행, 2프레임
func ev486():
	var art: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/units/heroes.json"))
	var img: Image = load("res://art/units/heroes.png").get_image()
	var adult := ["hoe", "fish", "axe", "saw", "hammer", "sit", "stir", "carry_sack", "carry_lantern", "carry_water", "squat", "carry_basket"]  # 가장·배우자 직업의 자세
	var need := {"man": adult, "woman": adult, "boy": ["carry_stick", "squat", "carry_water"], "girl": ["carry_stick", "squat", "carry_water"],
		"old_man": ["sit", "squat", "carry_basket"], "old_woman": ["sit", "squat", "carry_basket"]}
	var bad := []
	for body in need:
		for look in 8:
			var a = art.get("folk_%s_%d" % [body, look])
			if a == null:
				bad.append("folk_%s_%d 없음" % [body, look])
				continue
			var c := int(a.c)
			for p in need[body]:
				if not a.has(p):
					bad.append("folk_%s_%d %s 없음" % [body, look, p])
					continue
				for f in 2:
					for d in (4 if p.begins_with("carry") else 2):
						var r := Rect2i(int(a.get("x", 0)) + f * c, int(a[p]) + d * c, c, c)
						if not Rect2i(Vector2i.ZERO, img.get_size()).encloses(r) or img.get_region(r).is_invisible():
							bad.append("folk_%s_%d %s %d열 %d행" % [body, look, p, f, d])
	var pr = art.get("folk_man_8")
	if pr == null or not (pr.has("idle") and pr.has("walk") and pr.has("stir")):
		bad.append("folk_man_8(사제) %s" % [pr])
	return check(bad.is_empty(), "%s" % [bad.slice(0, 8)])

# EV501 · S230: 미니맵 위 [3,266,60,26]의 대피령 버튼은 «대피령»·«B»와 신뢰 칸 다섯(채운 칸 = 신뢰)을 보이고, 준비 단계에는 흐리며,
# 주민이 있는 전투 단계에는 흐리지 않고, 누르면 대피령이 나서 «대피 중»이다
func ev501():
	var main = _prep()
	var b = main.view.battle
	var e = main.hud.get("evac")
	if not e is BaseButton or not b.has_method("evacuate"):
		_done(main)
		return "main.hud.evac(BaseButton)·Battle.evacuate가 없다"
	b.build("house", Vector2i(22, 17))
	b.trust = 3
	e._process(0.0)
	var r: Rect2 = e.get_global_rect()
	var t := _cell_text(e)
	var dots = e.get("dots")
	var out := ""
	if not r.is_equal_approx(EVAC) or not e.is_visible_in_tree():
		out = "버튼 %s(보임 %s), 기대 %s" % [r, e.is_visible_in_tree(), EVAC]
	elif not ("대피령" in t and "B" in t):
		out = "버튼 글 «%s»에 «대피령»·«B»가 없다" % t
	elif not dots is Array or dots.size() != 5:
		out = "신뢰 칸이 다섯이 아니다(%s)" % [dots]
	elif not (dots[0].color == dots[2].color and dots[3].color == dots[4].color and dots[2].color != dots[3].color):
		out = "신뢰 3에서 칸 색 %s" % [dots.map(func(d): return d.color)]
	elif e.modulate.a >= 0.99:
		out = "준비 단계인데 버튼이 흐리지 않다"
	if out == "":
		b.start_battle()
		_frame(main)
		e._process(0.0)
		if e.modulate.a < 0.99:
			out = "주민이 있는 전투 단계인데 버튼이 흐리다(%.2f)" % e.modulate.a
		else:
			e.pressed.emit()
			e._process(0.0)
			if not b.evac or not "대피 중" in _cell_text(e):
				out = "누른 뒤 대피령 %s · 글 «%s»" % [b.evac, _cell_text(e)]
	_done(main)
	return out

# EV502 · S230: 주민이 다치면 «주민이 다쳤다» 토스트가, 거짓 대피령으로 웨이브가 끝나면 «거짓 대피령» 토스트가 뜬다
func ev502():
	var main = _prep()
	var b = main.view.battle
	var e = main.hud.get("evac")
	if not e is BaseButton or b.get("people") == null or not ResourceLoader.exists("res://src/sim/folk.gd"):
		_done(main)
		return "main.hud.evac·Battle.people·src/sim/folk.gd가 없다"
	b.build("house", Vector2i(22, 17))
	b.start_battle()
	_frame(main)
	_pass(main, 10.0)  # 준비 단계 미션 토스트를 흘려 보낸다
	b.mission = ""
	b.commission = ""
	e._process(0.0)
	b.damage(b.people[0], load("res://src/sim/folk.gd").HP * 0.5)
	e._process(0.0)
	var hurt := _toasts(main)
	var out := ""
	if not hurt.any(func(x): return "주민이 다쳤다" in x):
		out = "주민이 다친 뒤 토스트 %s" % [hurt]
	if out == "":
		_pass(main, 10.0)
		b.evacuate()
		e._process(0.0)
		if not clear_wave(b) or b.state == "battle":
			out = "웨이브가 끝나지 않았다"
		else:
			e._process(0.0)
			var shown := _toasts(main)
			if not shown.any(func(x): return "거짓 대피령" in x):
				out = "거짓 대피령으로 끝난 웨이브 뒤 토스트 %s" % [shown]
	_done(main)
	return out

# EV512 · S172: 청소년 몸 lad·lass 칸에 정지·걷기와 어른과 같은 일 자세가 있고, 키가 아이와 어른 사이다
func ev512():
	var art: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/units/heroes.json"))
	var img: Image = load("res://art/units/heroes.png").get_image()
	var whole := Rect2i(Vector2i.ZERO, img.get_size())
	var adult := ["hoe", "fish", "axe", "saw", "hammer", "sit", "stir", "carry_sack", "carry_lantern", "carry_water", "squat", "carry_basket"]
	var bad := []
	for body in ["lad", "lass"]:
		for look in 8:
			var a = art.get("folk_%s_%d" % [body, look])
			if a == null:
				bad.append("folk_%s_%d 없음" % [body, look])
				continue
			var c := int(a.c)
			var cells := []
			for f in [["idle", 0], ["walk", 0], ["walk", 1]]:
				for dir in 4:
					cells.append([f[0], f[1], dir, int(a[f[0]]) + dir * c])
			for p in adult:
				if not a.has(p):
					bad.append("folk_%s_%d %s 없음" % [body, look, p])
					continue
				for f in 2:
					for d in (4 if p.begins_with("carry") else 2):
						cells.append([p, f, d, int(a[p]) + d * c])
			for x in cells:
				var r := Rect2i(int(a.get("x", 0)) + x[1] * c, x[3], c, c)
				if not whole.encloses(r) or img.get_region(r).is_invisible():
					bad.append("folk_%s_%d %s %d열 %d행" % [body, look, x[0], x[1], x[2]])
	if not bad.is_empty():
		return "%s" % [bad.slice(0, 8)]
	var tall := func(body, look):  # 정지 남쪽 그림의 불투명 픽셀 높이
		var a: Dictionary = art["folk_%s_%d" % [body, look]]
		var c := int(a.c)
		return img.get_region(Rect2i(int(a.get("x", 0)), int(a.idle), c, c)).get_used_rect().size.y
	for look in 8:
		var m: Array = ["boy", "lad", "man"].map(func(k): return tall.call(k, look))
		var w: Array = ["girl", "lass", "woman"].map(func(k): return tall.call(k, look))
		if not (m[0] < m[1] and m[1] < m[2] and w[0] < w[1] and w[1] < w[2]):
			bad.append("look %d 키 boy·lad·man %s · girl·lass·woman %s" % [look, m, w])
	return check(bad.is_empty(), "%s" % [bad])

# EV513 · S233: 분가·이사·출생 소식이 토스트로 차례로 뜬다
func ev513():
	var main = _prep()
	var b = main.view.battle
	var e = main.hud.get("evac")
	if not e is BaseButton or b.get("folk_news") == null:
		_done(main)
		return "main.hud.evac·Battle.folk_news가 없다"
	_pass(main, 10.0)  # 준비 단계 미션 토스트를 흘려 보낸다
	b.mission = ""
	b.commission = ""
	e._process(0.0)
	b.folk_news = ["split", "moved", "born"]
	e._process(0.0)
	var shown := _toasts(main)
	for i in 24:  # 토스트는 3.5초 간격으로 줄을 서서 뜬다(I163)
		_pass(main, 0.5)
		shown += _toasts(main)
	_done(main)
	var miss := ["다 큰 자녀가 새 집으로 나갔다", "새 가족이 이사 왔다", "아기가 태어났다"].filter(func(w): return not shown.any(func(x): return w in x))
	return check(miss.is_empty(), "토스트 %s에 %s가 없다" % [shown, miss])

# EV515 · I185: 미니맵 점 크기는 boss 칸으로 가른다. boss 칸을 켠 기본 적은 2×2, 끈 오우거는 1×1
func ev515():
	var main = _prep()
	var m = main.hud.get("minimap")
	if m == null or not m.has_method("marks"):
		_done(main)
		return "main.hud.minimap.marks가 없다"
	var b = main.view.battle
	var still := {"speed": 0, "sight": 0, "damage": 0, "hp": BIG}
	b.spawn_enemy("basic", Vector2i(20, 70), still.merged({"boss": true}))
	b.spawn_enemy("boss", Vector2i(40, 70), still.merged({"boss": false}))
	_cam(main).force_update_scroll()
	m.follow()
	var t: int = m.top  # 점 자리는 칸 + 1 − 창 맨 윗줄
	var foes: Array = m.marks().filter(func(k): return k[1].is_equal_approx(Color("ff3b3b"))).map(func(k): return k[0])
	_done(main)
	var want := [Rect2(21, 71 - t, 2, 2), Rect2(41, 71 - t, 1, 1)]
	return check(want.all(func(w): return foes.any(func(r): return r.is_equal_approx(w))), "적 점 %s에 boss 칸 켠 기본 적 %s·끈 오우거 %s가 없다" % [foes, want[0], want[1]])

# EV517 · I185: 진행 칸 해골과 «다음 웨이브에 보스» 토스트는 웨이브에 든 종류의 boss 칸으로 가른다
func ev517():
	var main = _prep()
	var b = main.view.battle
	if main.hud.get("skull") == null or b.waves.size() < 3:
		_done(main)
		return "main.hud.skull이 없거나 1라운드 웨이브가 셋보다 적다(%d)" % b.waves.size()
	var kinds: Dictionary = b.ENEMY_KINDS
	for k in kinds:
		kinds[k]["boss"] = false
	kinds[b.waves[1][0].kind]["boss"] = true  # 2웨이브 첫 종류만 보스
	b.state = "battle"
	main.hud._process(0.0)
	b.wave_index = 1
	b.state = "prep"
	main.hud._process(0.0)
	main.hud.toasts._process(3.6)  # 미션 토스트가 막 떠서 3.5초 줄을 선다(I163, EV337)
	var said := _toasts(main).filter(func(t): return "다음 웨이브에 보스" in t)
	var out := check(main.hud.skull.is_visible_in_tree() and said.size() == 1, "2웨이브 첫 종류 %s만 boss 칸을 켠 준비 단계: 해골 %s · 토스트 %s" % [b.waves[1][0].kind, main.hud.skull.is_visible_in_tree(), _toasts(main)])
	if out == "":
		for i in 10:  # 떠 있는 토스트를 모두 흘려 보낸다
			main.hud.toasts._process(10.0)
		kinds[b.waves[1][0].kind]["boss"] = false
		b.state = "battle"
		main.hud._process(0.0)
		b.wave_index = 2
		b.state = "prep"
		main.hud._process(0.0)
		main.hud.toasts._process(0.0)
		said = _toasts(main).filter(func(t): return "다음 웨이브에 보스" in t)
		out = check(not main.hud.skull.is_visible_in_tree() and said.is_empty(), "boss 칸을 모두 끈 3웨이브(%s) 준비 단계: 해골 %s · 토스트 %s" % [b.waves[2].map(func(e): return e.kind), main.hud.skull.is_visible_in_tree(), _toasts(main)])
	_done(main)
	return out

# 주민 칸의 한 그림(몸·look·자세 키·방향 행·프레임 열)
func _folk_cell(art: Dictionary, img: Image, body: String, look: int, key: String, dir: int, f: int) -> Image:
	var a: Dictionary = art["folk_%s_%d" % [body, look]]
	var c := int(a.c)
	return img.get_region(Rect2i(int(a.get("x", 0)) + f * c, int(a[key]) + dir * c, c, c))

# EV522 · S172 2026-10-27 셋째 변경: 정지 남쪽 키는 성별마다 아이 < 청소년 < 어른이 2px 이상씩 차이 난다
func ev522():
	var art: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/units/heroes.json"))
	var img: Image = load("res://art/units/heroes.png").get_image()
	var bad := []
	for look in 8:
		for row in [["boy", "lad", "man"], ["girl", "lass", "woman"]]:
			var h: Array = row.map(func(k): return _folk_cell(art, img, k, look, "idle", 0, 0).get_used_rect().size.y)
			if not (h[0] + 2 <= h[1] and h[1] + 2 <= h[2]):
				bad.append("look %d %s 키 %s" % [look, row, h])
	return check(bad.is_empty(), "%s" % [bad])

# EV523 · S172 셋째 변경: 젊은 주민의 정지 4방향 그림 위 3줄(머리)에 노인 회색(a4aec2·d0d6e0)이 없고, 노인 정지 남쪽 위 3줄에는 a4aec2가 있다
func ev523():
	var art: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/units/heroes.json"))
	var img: Image = load("res://art/units/heroes.png").get_image()
	var top := func(cell: Image) -> Array:  # 불투명 영역 위 3줄의 색(hex)
		var r := cell.get_used_rect()
		var out := []
		for y in range(r.position.y, r.position.y + 3):
			for x in range(r.position.x, r.end.x):
				var p := cell.get_pixel(x, y)
				if p.a > 0.5:
					out.append(p.to_html(false))
		return out
	var bad := []
	for look in 8:
		for body in ["boy", "lad", "man", "girl", "lass", "woman"]:
			for dir in 4:
				var hit: Array = top.call(_folk_cell(art, img, body, look, "idle", dir, 0)).filter(func(h): return h in ["a4aec2", "d0d6e0"])
				if not hit.is_empty():
					bad.append("folk_%s_%d 정지 %d행 위 3줄 %s" % [body, look, dir, hit])
		for body in ["old_man", "old_woman"]:
			if not "a4aec2" in top.call(_folk_cell(art, img, body, look, "idle", 0, 0)):
				bad.append("folk_%s_%d 정지 남쪽 위 3줄에 a4aec2가 없다" % [body, look])
	return check(bad.is_empty(), "%d건 %s" % [bad.size(), bad.slice(0, 8)])

# EV524 · S172 셋째 변경: look 1(웃옷 a56243)의 물동이 이고 걷기 그림마다 물동이의 파랑 계열 픽셀이 5개 이상이다
func ev524():
	var art: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/units/heroes.json"))
	var img: Image = load("res://art/units/heroes.png").get_image()
	var bad := []
	for body in ["man", "woman", "lad", "lass", "boy", "girl"]:
		for d in 4:
			for f in 2:
				var cell := _folk_cell(art, img, body, 1, "carry_water", d, f)
				var n := 0
				for y in cell.get_height():
					for x in cell.get_width():
						var p := cell.get_pixel(x, y)
						if p.a > 0.5 and p.to_html(false) in ["4f78ad", "7a86a0", "56607a"]:
							n += 1
				if n < 5:
					bad.append("folk_%s_1 carry_water %d행 %d열 파랑 %d" % [body, d, f, n])
	return check(bad.is_empty(), "%s" % [bad.slice(0, 8)])

# EV525 · I187 ③: 몸 여덟 × look 0~7의 주민 칸마다 등짐(carry_pack) 4방향 × 2프레임이 있고 북쪽은 걷기와 다르다. 사제 옷에는 없다
func ev525():
	var art: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/units/heroes.json"))
	var img: Image = load("res://art/units/heroes.png").get_image()
	var whole := Rect2i(Vector2i.ZERO, img.get_size())
	var bad := []
	for body in ["man", "woman", "boy", "girl", "lad", "lass", "old_man", "old_woman"]:
		for look in 8:
			var a = art.get("folk_%s_%d" % [body, look])
			if a == null or not a.has("carry_pack"):
				bad.append("folk_%s_%d carry_pack 없음" % [body, look])
				continue
			var c := int(a.c)
			for d in 4:
				for f in 2:
					var r := Rect2i(int(a.get("x", 0)) + f * c, int(a.carry_pack) + d * c, c, c)
					if not whole.encloses(r) or img.get_region(r).is_invisible():
						bad.append("folk_%s_%d carry_pack %d행 %d열" % [body, look, d, f])
			if bad.is_empty() and _folk_cell(art, img, body, look, "carry_pack", 2, 0).get_data() == _folk_cell(art, img, body, look, "walk", 2, 0).get_data():
				bad.append("folk_%s_%d carry_pack 북쪽이 걷기와 같다" % [body, look])
	if art.get("folk_man_8", {}).has("carry_pack"):
		bad.append("folk_man_8(사제)에 carry_pack이 있다")
	return check(bad.is_empty(), "%s" % [bad.slice(0, 8)])

# EV536 · S188: 1라운드 3웨이브 줄에 슬라임 킹 특성
func ev536():
	var main = _prep()
	var lines: String = main.hud._wave_lines([0, 2])
	_done(main)
	return check("슬라임 킹: 웅크린 뒤 뛰어내려 찍는다. 맞을수록 작아지고 빨라진다" in lines, "1라운드 3웨이브 줄 «%s»에 슬라임 킹 특성이 없다" % lines)

# EV556 · S188: 2라운드 1·2웨이브 줄에 늑대·도약 늑대 특성이 있다
func ev556():
	var main = _prep()
	var one: String = main.hud._wave_lines([1, 0])
	var two: String = main.hud._wave_lines([1, 1])
	_done(main)
	return check("늑대: 무리로 온다" in one and "도약 늑대: 성벽 위로 뛰어 아군을 밀치고 기절시킨다" in two, "2라운드 1웨이브 줄 «%s» · 2웨이브 줄 «%s»" % [one, two])

# EV565 · S188: 2라운드 3웨이브 줄에 밤 늑대 특성이 있다
func ev565():
	var main = _prep()
	var three: String = main.hud._wave_lines([1, 2])
	_done(main)
	return check("밤 늑대: 어두울수록 세다, 물면 피를 흘린다" in three, "2라운드 3웨이브 줄 «%s»에 밤 늑대 특성이 없다" % three)

# EV584 · S188: 2라운드 4웨이브 줄에 알파 늑대 특성이 있다
func ev584():
	var main = _prep()
	var four: String = main.hud._wave_lines([1, 3])
	_done(main)
	return check("알파 늑대: 성벽 위 원거리를 덮쳐 붙잡는다, 둘레 늑대를 빠르게 한다" in four, "2라운드 4웨이브 줄 «%s»에 알파 늑대 특성이 없다" % four)

# EV570 · S187: 스킬 툴팁 수치 줄은 그 스킬 사전의 값으로 채운다. 지점·대상을 고르는 스킬은 시전 거리 줄을 더한다
func ev570():
	var H = load("res://src/ui/hud.gd")
	var main = _prep()
	var b = main.view.battle
	var bad := []
	for kind in b.HERO_KINDS:
		for slot in b.SLOTS:
			var sk: Dictionary = b.HERO_KINDS[kind][slot]
			var lines: Array = H.skill_lines(kind, slot, sk)
			if lines.is_empty() or lines.any(func(l): return l == "" or "{" in l):
				bad.append([kind, slot, lines])
				continue
			var far: bool = sk.aim in ["point", "enemy", "ally"]
			if far != (lines.back() == "시전 거리 6칸") or (not far and lines.has("시전 거리 6칸")):
				bad.append([kind, slot, "시전 거리", lines])
			for key in ["damage", "radius", "time", "stun", "heal", "dps"]:
				if sk.has(key):
					var bent := sk.duplicate()
					bent[key] = 77.0
					if not "77" in "\n".join(H.skill_lines(kind, slot, bent)):
						bad.append([kind, slot, key])
	var h = b.heroes[0]
	var about: String = main.hud._skill_tip(0, "q")[3]
	var want: Array = H.skill_lines(h.kind, "q", h.q)
	_done(main)
	return check(bad.is_empty() and want.all(func(l): return l in about), "어긋난 스킬 %s · 첫 영웅 %s Q 설명 «%s»에 %s" % [bad, h.kind, about, want])

# EV571 · S241: 화면 아래 HUD 패널은 미니맵과 같은 두 겹 테두리(안쪽 6b7280, 바깥 0b0c10 1px). 위 띠는 그대로
func ev571():
	var main = _prep()
	var h = main.hud
	var bad := []
	for n in [h.grid, h.grid.info, h.select, h.hints]:
		var s: StyleBox = n.get_theme_stylebox("panel")
		if not s is StyleBoxFlat or s.border_color != Color("6b7280") or s.shadow_color != Color("0b0c10") or s.shadow_size != 1:
			bad.append([n.name, s.border_color if s is StyleBoxFlat else s, s.shadow_color if s is StyleBoxFlat else null, s.shadow_size if s is StyleBoxFlat else null])
	var top: StyleBox = h.bar.get_theme_stylebox("panel")
	var top_ok: bool = top is StyleBoxFlat and top.shadow_size == 0
	_done(main)
	return check(bad.is_empty() and top_ok, "어긋난 패널 %s · 위 띠 그림자 없음 %s" % [bad, top_ok])
