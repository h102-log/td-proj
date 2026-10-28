extends CanvasLayer
# 메인 메뉴·ESC 메뉴·설정·확인 창(S182~S184, I159). 메인 메뉴 장면(menu.gd)과 게임 장면(main.gd)이 붙이고 open으로 연다.
# 고른 것은 chosen으로 알린다: "new" 새 게임 · "resume" 이어하기 · "quit" 종료 · "continue" 계속 · "title" 메인 메뉴로 · "settings" 설정을 바꿨다
# 트리가 멈춰도 돈다. ESC 메뉴는 일시정지(I11) 중에 뜨기 때문이다. HUD(층 1) 위에 그린다

const Settings := preload("res://src/settings.gd")
const HudTheme := preload("res://src/ui/hud_theme.gd")
const LANGUAGES := {"ko": "한국어", "en": "English"}  # 설정 «언어»의 항목(S193). 언어 이름은 그 언어로 쓴다. 번역 안 함
const SHAKES := ["끔", "약하게", "보통"]  # 설정 «화면 흔들림»의 항목(S200). 번호가 Settings.shake다

signal chosen(what: String)

var can_resume := false  # 메인 메뉴의 «이어하기»를 누를 수 있다(저장이 있다, S182)
var page := ""  # 보이는 화면: "title" · "confirm" · "pause" · "settings". 닫혀 있으면 ""
var _note := false  # ESC 메뉴에 «저장되지 않습니다» 안내를 보인다(전투 단계, S183)
var _back := ""  # 설정을 연 화면. 설정의 ESC·«뒤로»가 돌아간다(I159)
var _root := Control.new()  # 보이고 숨기는 틀. 글자 크기도 여기서 준다
var _dim := ColorRect.new()
var _box := VBoxContainer.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 2
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.theme = HudTheme.make(12)
	add_child(_root)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	panel.add_child(_box)
	if page == "":
		_root.hide()

# 화면 p를 연다. note는 ESC 메뉴의 «저장되지 않습니다» 안내
func open(p: String, note := false) -> void:
	page = p
	_note = note
	for c in _box.get_children():
		_box.remove_child(c)  # 바로 빼야 같은 프레임에 새 화면 버튼만 남는다
		c.queue_free()
	_dim.color = Color(0.08, 0.08, 0.1) if p in ["title", "confirm"] or _back == "title" else Color(0, 0, 0, 0.6)
	var first: Control
	match p:
		"title":
			_back = "title"
			var fresh := _button("새 게임", _new_game)
			var go := _button("이어하기", func(): chosen.emit("resume"))
			go.disabled = not can_resume
			_button("설정", _settings)
			_button("종료", func(): chosen.emit("quit"))
			first = go if can_resume else fresh
		"confirm":
			_label("진행 중인 도전이 지워집니다.\n새 게임을 시작할까요?")
			first = _button("취소", open.bind("title"))
			_button("지우고 새 게임", func(): chosen.emit("new"))
		"pause":
			_back = "pause"
			if note:
				_label("지금 나가면 이번 웨이브 진행은 저장되지 않습니다")
			first = _button("계속", func(): chosen.emit("continue"))
			_button("설정", _settings)
			_button("메인 메뉴로", func(): chosen.emit("title"))
			_button("게임 종료", func(): chosen.emit("quit"))
		"settings":
			first = _check("퀵캐스트", Settings.quickcast, func(on): Settings.quickcast = on)
			_check("부활", Settings.revive, func(on): Settings.revive = on)
			var full: bool = Settings.fullscreen if Settings.fullscreen != null else get_window().mode == Window.MODE_FULLSCREEN
			_check("전체화면 (F11)", full, func(on): Settings.fullscreen = on)
			_check("커서 가두기", Settings.confine, func(on): Settings.confine = on)  # I194
			_check("힌트", Settings.hints, func(on): Settings.hints = on)  # S191
			var row := HBoxContainer.new()
			_box.add_child(row)
			_label("음량", row)
			var vol := HSlider.new()
			vol.step = 10
			vol.value = Settings.volume
			vol.custom_minimum_size.x = 100
			vol.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(vol)
			var pct := _label("%d%%" % Settings.volume, row)
			vol.value_changed.connect(func(v):
				pct.text = "%d%%" % v
				Settings.volume = int(v)
				Settings.apply_volume()
				_changed())
			var cam_row := HBoxContainer.new()  # 카메라 속도(S184, S53). 음량 다음에 둔다
			_box.add_child(cam_row)
			_label("카메라 속도", cam_row)
			var cam := HSlider.new()
			cam.min_value = 50
			cam.max_value = 200
			cam.step = 25
			cam.value = Settings.camera_speed
			cam.custom_minimum_size.x = 100
			cam.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			cam_row.add_child(cam)
			var cam_pct := _label("%d%%" % Settings.camera_speed, cam_row)
			cam.value_changed.connect(func(v):
				cam_pct.text = "%d%%" % v
				Settings.camera_speed = int(v)
				_changed())
			var lang := HBoxContainer.new()
			_box.add_child(lang)
			_label("언어", lang)
			var pick := OptionButton.new()
			pick.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
			for code in LANGUAGES:
				pick.add_item(LANGUAGES[code])
			pick.selected = LANGUAGES.keys().find(Settings.language)
			lang.add_child(pick)
			pick.item_selected.connect(func(i):
				Settings.language = LANGUAGES.keys()[i]
				Settings.apply_language()
				_changed())
			var shake_row := HBoxContainer.new()  # 화면 흔들림(S184, S200). 언어 고르기보다 뒤에 둔다(언어가 설정 화면의 첫 고르기다)
			_box.add_child(shake_row)
			_label("화면 흔들림", shake_row)
			var shake := OptionButton.new()
			for t in SHAKES:
				shake.add_item(t)
			shake.selected = Settings.shake
			shake_row.add_child(shake)
			shake.item_selected.connect(func(i):
				Settings.shake = i
				_changed())
			_check("번쩍임 줄이기", Settings.soft_flash, func(on): Settings.soft_flash = on)  # S177, S197
			_button("뒤로", _leave_settings)
	_root.show()
	first.grab_focus()

func close() -> void:
	page = ""
	_root.hide()

func _settings() -> void:
	open("settings", _note)

# 저장이 있으면 지워진다는 확인 창을 먼저 연다(S182)
func _new_game() -> void:
	if can_resume:
		open("confirm")
	else:
		chosen.emit("new")

# 설정을 닫고 연 화면으로 돌아가 «설정»에 포커스를 둔다(I159)
func _leave_settings() -> void:
	open(_back, _note)
	for b in _box.get_children():
		if b is Button and b.text == "설정":
			b.grab_focus()

func _changed() -> void:
	Settings.save_file()
	chosen.emit("settings")

# ESC는 한 단계 뒤로(I159): 설정·확인 창은 앞 화면으로, ESC 메뉴는 «계속», 메인 메뉴는 아무것도 하지 않는다
func _unhandled_input(event: InputEvent) -> void:
	if page == "" or not (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		return
	get_viewport().set_input_as_handled()
	match page:
		"settings":
			_leave_settings()
		"confirm":
			open("title")
		"pause":
			chosen.emit("continue")

func _button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(on_press)
	_box.add_child(b)
	return b

func _check(text: String, on: bool, set_to: Callable) -> CheckButton:
	var b := CheckButton.new()
	b.text = text
	b.button_pressed = on
	b.toggled.connect(func(v):
		set_to.call(v)
		_changed())
	_box.add_child(b)
	return b

func _label(text: String, parent: Control = null) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	(parent if parent else _box).add_child(l)
	return l
