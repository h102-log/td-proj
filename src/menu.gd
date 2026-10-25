extends Node
# 진입 장면: 메인 메뉴(S182). 새 게임·이어하기를 고르면 게임 장면(main.tscn)으로 가고,
# ESC 메뉴의 «메인 메뉴로»(I161)는 이 장면으로 돌아온다. 게임을 막 켰을 때는 저장·설정 파일을 정하고 창을 준비한다(S161, S163)

const Main := preload("res://src/main.gd")
const Save := preload("res://src/sim/save.gd")
const Settings := preload("res://src/settings.gd")
const Menus := preload("res://src/ui/menus.gd")

func _ready() -> void:
	if Save.path == "":  # 게임을 막 켰다. 평가는 경로를 먼저 정해 이 준비를 건너뛴다
		Save.path = "user://save.dat"
		Settings.path = "user://settings.cfg"
		Settings.load_file()
		Settings.apply_volume()
		Settings.apply_language()  # S193
		Main.setup_window(get_window(), true)
		Main.live_prep = true  # 준비 단계 실시간(I175). 평가는 이 준비를 건너뛰어 옛 규칙 판을 쓴다
	var menus := Menus.new()
	menus.can_resume = not Save.read().is_empty()
	menus.chosen.connect(_on_menu)
	add_child(menus)
	menus.open("title")

func _on_menu(what: String) -> void:
	match what:
		"new":
			Save.erase()
			Main.resume = {}
			get_tree().change_scene_to_file("res://src/main.tscn")
		"resume":
			Main.resume = Save.read()
			get_tree().change_scene_to_file("res://src/main.tscn")
		"quit":
			get_tree().quit()
		"settings":
			Main.apply_window(get_window())

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:  # S162
		Main.switch_fullscreen(get_window())
