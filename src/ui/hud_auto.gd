extends Button
# «전체 오토» 버튼(S313, I259): 화면 왼쪽 아래 «영입» 버튼(S272) 바로 위 [3,210,60,26]. 금색 꺾쇠 넷·«오토». 단축키는 없다.
# 누르면 출전 영웅 모두의 칸 오토를 한 번에 켜고 끈다(Battle.toggle_auto_all). 모두 켜져 있는 동안 금색 테두리다. 준비·전투 단계에만 보인다

const HudTheme := preload("res://src/ui/hud_theme.gd")
const HudBuild := preload("res://src/ui/hud_build.gd")
const CORNERS := ["###....###", "#........#", "#........#", "..........", "..........", "..........", "..........", "#........#", "#........#", "###....###"]  # 켜진 스킬 칸의 금색 꺾쇠(S296)

var hud
var battle
var _on_box: StyleBoxFlat  # 모두 켜져 있는 동안 바탕

func _init(h) -> void:
	hud = h
	battle = h.battle

func _ready() -> void:
	theme_type_variation = "BarCell"
	position = Vector2(3, 210)
	size = Vector2(60, 26)
	focus_mode = Control.FOCUS_NONE  # 포커스가 가면 Enter가 전투 시작으로 가지 않는다
	pressed.connect(func(): battle.toggle_auto_all())
	_on_box = HudTheme.box("normal", "Button", HudTheme.CELL, HudTheme.ACCENT)
	var mark := TextureRect.new()
	mark.texture = HudBuild.dots(CORNERS, {"#": HudTheme.ACCENT})
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_SCALE
	mark.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mark.position = Vector2(3, 3)
	mark.size = Vector2(20, 20)
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mark)
	var title := Label.new()
	title.text = "오토"
	title.add_theme_font_size_override("font_size", 9)
	title.add_theme_color_override("font_color", HudTheme.TEXT)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.position = Vector2(26, 6)
	add_child(title)
	hud.tip.add(self, func(): return ["전체 오토", "", "", "출전 영웅의 스킬 오토를 한 번에 켜고 끈다 · 하나라도 꺼져 있으면 모두 켠다", ""])
	_process(0.0)

func _process(_delta: float) -> void:
	visible = battle.state in ["prep", "battle"]
	if battle.all_auto():
		add_theme_stylebox_override("normal", _on_box)
	else:
		remove_theme_stylebox_override("normal")
