extends CanvasLayer
# 테스트 패널(I232): 테스트 모드 게임 장면 오른쪽의 패널. 배속(I236)·라운드 이동(I235)·성능 표시(I237)·조정값 파일(I238)과
# 분류·종류마다의 수치 줄(I233·I234)을 둔다. 패널 밖의 «테스트 (F9)» 버튼과 F9 키로 닫고 연다. main.gd가 HUD 뒤에 붙여 HUD 위·ESC 메뉴 아래에 그린다.
# 패널에서 누르거나 고르거나 값을 넣으면 키보드 포커스를 놓아, 그다음 Space·Enter·단축키가 게임으로 간다(I232).
# 글은 개발자용이라 번역하지 않는다(I239). 한글 리터럴이 든 줄에는 «번역 안 함»을 단다(EV373가 그 줄을 건너뛴다)

const HudTheme := preload("res://src/ui/hud_theme.gd")
const Hud := preload("res://src/ui/hud.gd")
const Tuning := preload("res://src/sim/tuning.gd")
# 패널 자리(기준 해상도 px). 위 끝은 오른쪽 위 미션 토스트 아래, 오른쪽 끝은 카메라 가장자리 이동 폭(camera.gd EDGE) 밖,
# 아래 끝은 건설 격자(오른쪽 아래) 위다. «테스트 (F9)»는 패널 왼쪽 위 바깥에 붙는다
const BOX := Rect2(442, 48, 188, 236)
const FONT := 8
const PAD := 2  # 패널 버튼·값 칸의 안쪽 여백(px). 좁은 패널에 줄을 많이 보이려고 HUD 테마 여백보다 줄인다
const FPS_AT := Vector2(4, 44)  # 성능 표시 자리: 인구 칸(hud.gd POP_AT) 아래
const SPEEDS := [1, 2, 4, 8]  # 배속(S292 ②)
const STAGE_NAMES := {"gold": "골드", "stage.gold": "시작 골드 (gold)", "stage.base_hp": "거점 체력 (base_hp)", "stage.castle.wall_hp": "성벽 체력 (castle.wall_hp)", "stage.castle.gate_hp": "성문 체력 (castle.gate_hp)", "stage.spawn_gap": "출현 간격 (spawn_gap)", "stage.reward_scale": "처치 보상 배율 (reward_scale)"}  # 번역 안 함

var main  # 게임 장면(main.gd): 판·tuning·speed를 쥔다
var _box := PanelContainer.new()
var _list := VBoxContainer.new()  # 고른 종류의 수치 줄
var _fps := Label.new()  # 성능 표시(I237). 패널 밖이라 패널을 닫아도 남는다
var _show := CheckButton.new()
var _go: Button  # «이동»
var _round := OptionButton.new()
var _cat := OptionButton.new()
var _kind := OptionButton.new()
var _note := Label.new()  # 조정값 파일 경로와 마지막 결과(I238)
var _kinds := []  # _kind 항목 차례의 종류
var _live := []  # 판이 바꾸는 줄(지금 골드·영웅 레벨): [값 칸, 분류, 종류, path]. 고치는 중이 아니면 판 값을 보인다

func _init(m) -> void:
	main = m

func _ready() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 패널 밖 클릭은 HUD·맵으로 간다
	root.theme = _theme()
	root.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED  # 개발자용 글(I239)
	add_child(root)
	var toggle := _button("테스트 (F9)", _flip, root)  # 번역 안 함
	toggle.position = Vector2(BOX.position.x - toggle.get_combined_minimum_size().x - 2, BOX.position.y)
	var back := StyleBoxFlat.new()
	back.bg_color = HudTheme.PANEL
	back.set_content_margin_all(2)
	_fps.add_theme_stylebox_override("normal", back)
	_fps.position = FPS_AT
	root.add_child(_fps)
	_box.position = BOX.position
	_box.size = BOX.size
	root.add_child(_box)
	var col := VBoxContainer.new()
	_box.add_child(col)
	var top := HBoxContainer.new()  # 배속·성능 표시
	col.add_child(top)
	var group := ButtonGroup.new()
	for n in SPEEDS:
		var b := _button("×%d" % n, func(): main.speed = n, top)
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = n == main.speed
	_show.text = "성능 표시"  # 번역 안 함
	_show.button_pressed = true
	_show.toggled.connect(func(_on): _calm())
	top.add_child(_show)
	var tools := HBoxContainer.new()  # 라운드 이동·조정값 파일
	col.add_child(tools)
	for i in main.view.battle.rounds.size():
		_round.add_item("%d라운드" % (i + 1))  # 번역 안 함
	_round.selected = main.view.battle.round_index
	_round.item_selected.connect(func(_i): _calm())
	tools.add_child(_round)
	_go = _button("이동", _jump, tools)  # 번역 안 함
	_button("저장", _save, tools)  # 번역 안 함
	_button("불러오기", _load, tools)  # 번역 안 함
	_button("되돌리기", _reset, tools)  # 번역 안 함
	var pick := HBoxContainer.new()
	col.add_child(pick)
	for cat in Tuning.CATS:
		_cat.add_item(cat)
	_cat.fit_to_longest_item = false
	_cat.item_selected.connect(func(_i): _pick_cat())
	pick.add_child(_cat)
	_kind.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_kind.fit_to_longest_item = false  # 가장 긴 종류 이름에 맞추면 패널이 넓어진다
	_kind.clip_text = true
	_kind.item_selected.connect(func(_i):
		_fill()
		_calm())
	pick.add_child(_kind)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	_note.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY  # 패널 아래 글: 조정값 파일의 실제 경로와 마지막 결과(I238)
	_note.custom_minimum_size.x = BOX.size.x - 8
	_note.text = "조정값 파일: %s" % _where()  # 번역 안 함
	col.add_child(_note)
	_pick_cat()

func _process(_delta: float) -> void:
	var b = main.view.battle
	_fps.visible = _show.button_pressed
	if _fps.visible:
		_fps.text = "FPS %d · 적 %d · 아군 %d · 구조물 %d · 투사체 %d · 주민 %d" % [int(Engine.get_frames_per_second()), b.enemies.size(), b.units.filter(func(u): return u.alive).size(), b.structures.size(), b.missiles.size(), b.people.size()]  # 번역 안 함
	_go.disabled = not main.tuning.can_jump()
	for l in _live:
		var v = main.tuning.value(l[1], l[2], l[3])
		if v != null and not l[0].get_line_edit().has_focus():
			l[0].set_value_no_signal(v)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
		_flip()
		get_viewport().set_input_as_handled()

func _flip() -> void:
	_box.visible = not _box.visible

# 키보드 포커스를 놓는다(I232)
func _calm() -> void:
	get_viewport().gui_release_focus()

func _button(text: String, on_press: Callable, parent: Control) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(func():
		on_press.call()
		_calm())
	parent.add_child(b)
	return b

# HUD 테마(hud_theme.gd)에서 버튼·값 칸 여백과 줄 사이를 줄인 것
func _theme() -> Theme:
	var t := HudTheme.make(FONT)
	for st in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		var s: StyleBox = t.get_stylebox(st, "Button")
		s.content_margin_left = PAD
		s.content_margin_right = PAD
		s.content_margin_top = 1
		s.content_margin_bottom = 1
	for st in ["normal", "focus", "read_only"]:
		var s := StyleBoxFlat.new()
		s.bg_color = HudTheme.CELL
		s.border_color = HudTheme.ACCENT if st == "focus" else HudTheme.LINE
		s.set_border_width_all(1)
		s.set_content_margin_all(PAD)
		t.set_stylebox(st, "LineEdit", s)
	t.set_constant("separation", "VBoxContainer", 1)
	t.set_constant("separation", "HBoxContainer", 2)
	return t

func _where() -> String:
	return ProjectSettings.globalize_path(Tuning.path)

func _cat_name() -> String:
	return Tuning.CATS.keys()[_cat.selected]

func _pick_cat() -> void:
	var cat := _cat_name()
	_kinds = main.tuning.kinds(cat)
	_kind.clear()
	for k in _kinds:
		_kind.add_item(_kind_name(cat, k))
	_kind.selected = 0
	_fill()
	_calm()

func _kind_name(cat: String, k) -> String:
	match Tuning.CATS[cat]:
		"waves":
			return "%d라운드" % (k + 1)  # 번역 안 함
		"enemies":
			return "%s (%s)" % [Hud.ENEMIES.get(k, k), k]
		"mercs", "structures":
			return "%s (%s)" % [Hud.NAMES.get(k, k), k]
		"heroes", "gear":
			return "%s (%s)" % [Hud.HEROES.get(k, k), k]
	return str(k)

# 고른 종류의 줄을 다시 만든다. 웨이브는 웨이브마다 줄 뒤에 적 종류 더하기 줄을 둔다(I234)
func _fill() -> void:
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	_live.clear()
	if _kinds.is_empty():
		return
	var cat := _cat_name()
	var kind = _kinds[_kind.selected]
	var rows: Array = main.tuning.fields(cat, kind)
	if Tuning.CATS[cat] != "waves":
		for r in rows:
			_line(cat, kind, r)
		return
	for r in rows.filter(func(x): return x.path == ["hp_mult"]):
		_line(cat, kind, r)
	for w in main.view.battle.rounds[kind].size():
		for r in rows.filter(func(x): return (x.path[0] is int and x.path[0] == w) or (x.path.size() == 3 and x.path[1] == w)):
			_line(cat, kind, r)
		_adder(kind, w)

func _label(cat: String, r: Dictionary) -> String:
	if Tuning.CATS[cat] == "stage":
		return STAGE_NAMES.get(r.name, r.name)
	if r.path == ["hp_mult"]:
		return "체력 배율 (hp_mult)"  # 번역 안 함
	if Tuning.CATS[cat] == "waves" and r.path[0] is int:
		return "웨이브 %d · %s (%s)" % [r.path[0] + 1, Hud.ENEMIES.get(r.path[1], r.path[1]), r.path[1]]  # 번역 안 함
	if Tuning.CATS[cat] == "waves":
		return "웨이브 %d 밤 %s" % [r.path[1] + 1, r.path[2]]  # 번역 안 함
	if r.path == ["level"]:
		return "레벨 (보유 영웅)"  # 번역 안 함
	return r.name

# 수치 줄 하나: 이름 글자와 값 칸. 데이터 값과 다르면 이름을 강조색으로 그린다(I233)
func _line(cat: String, kind, r: Dictionary) -> void:
	var row := HBoxContainer.new()
	_list.add_child(row)
	var title := Label.new()
	title.text = _label(cat, r)
	title.tooltip_text = title.text
	title.mouse_filter = Control.MOUSE_FILTER_PASS  # 잘린 이름은 툴팁으로 본다
	title.clip_text = true
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	var spin := SpinBox.new()
	var whole: bool = r.value is int
	spin.step = 1 if whole else 0.01
	spin.custom_arrow_step = 1 if whole else 0.1
	spin.rounded = whole
	spin.min_value = -1e6  # 하한은 tuning이 칸에 맞춰 정한다(I233)
	spin.max_value = 1e6
	spin.value = r.value
	spin.custom_minimum_size.x = 56
	spin.select_all_on_focus = true
	row.add_child(spin)
	_mark(title, r.value, r.data)
	spin.value_changed.connect(func(v):
		main.tuning.put(cat, kind, r.path, v)
		var now = main.tuning.value(cat, kind, r.path)
		spin.set_value_no_signal(now)
		_mark(title, now, r.data)
		_calm())
	if r.path == ["gold"] or r.path == ["level"]:
		_live.append([spin, cat, kind, r.path])

func _mark(title: Label, v, data) -> void:
	title.add_theme_color_override("font_color", HudTheme.TEXT if is_equal_approx(float(v), float(data)) else HudTheme.ACCENT)

# 라운드 r 웨이브 w에 적 종류를 더하는 줄(I234)
func _adder(r: int, w: int) -> void:
	var row := HBoxContainer.new()
	_list.add_child(row)
	var foes: Array = main.view.battle.ENEMY_KINDS.keys()
	foes.sort()
	var pick := OptionButton.new()
	for k in foes:
		pick.add_item("%s (%s)" % [Hud.ENEMIES.get(k, k), k])
	pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pick.fit_to_longest_item = false
	pick.clip_text = true
	pick.item_selected.connect(func(_i): _calm())
	row.add_child(pick)
	var add := func():
		if main.tuning.add_enemy(r, w, foes[pick.selected]):
			_fill()
	_button("더하기", add, row)  # 번역 안 함

func _jump() -> void:
	if main.tuning.jump(_round.selected):
		_fill()

func _save() -> void:
	var n: int = main.tuning.save()
	_note.text = ("저장 %d칸 → %s" % [n, _where()]) if n >= 0 else ("저장하지 못함: %s" % _where())  # 번역 안 함

func _load() -> void:
	var n: int = main.tuning.load_file()
	_note.text = ("불러옴 %d칸 · 건너뜀 %d칸" % [n, main.tuning.skipped]) if n >= 0 else ("불러오지 못함(파일이 없거나 읽지 못함): %s" % _where())  # 번역 안 함
	_fill()

func _reset() -> void:
	main.tuning.reset()
	_note.text = "데이터 값으로 되돌림"  # 번역 안 함
	_fill()
