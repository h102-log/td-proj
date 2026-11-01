extends Button
# «영입» 버튼(S272, I207): 화면 왼쪽 아래 대피령 버튼(S230) 바로 위 [3,238,60,26]. 투구 그림·«영입»·단축키 T.
# 누르거나 T 키(main)면 언제든 영입 창을 열고 닫는다(controls.shop). 창이 떠 있는 동안 금색 테두리로 눌린 모양이다. 준비·전투 단계에만 보인다

const HudTheme := preload("res://src/ui/hud_theme.gd")
const HudBuild := preload("res://src/ui/hud_build.gd")
const HELM := ["....rr....", "...rr.....", "..######..", ".#ssssss#.", "#ssssssss#", "#s######s#", "#ss#..#ss#", "#ssssssss#", ".#ss##ss#.", "..##..##.."]

var hud
var battle
var controls
var _on_box: StyleBoxFlat  # 창이 떠 있는 동안 바탕

func _init(h) -> void:
	hud = h
	battle = h.battle
	controls = h.controls

func _ready() -> void:
	theme_type_variation = "BarCell"
	position = Vector2(3, 238)
	size = Vector2(60, 26)
	focus_mode = Control.FOCUS_NONE  # 포커스가 가면 Enter가 전투 시작으로 가지 않는다
	pressed.connect(func(): controls.set_shop(not controls.shop))
	_on_box = HudTheme.box("normal", "Button", HudTheme.CELL, HudTheme.ACCENT)
	var helm := TextureRect.new()
	helm.texture = HudBuild.dots(HELM, {"r": HudTheme.DANGER, "s": Color("d0d6e0"), "#": Color("7a86a0")})
	helm.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	helm.stretch_mode = TextureRect.STRETCH_SCALE
	helm.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	helm.position = Vector2(3, 5)
	helm.size = Vector2(16, 16)
	helm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(helm)
	var key := _label("T", 7, HudTheme.ACCENT)
	key.position = Vector2(1, -2)
	var title := _label("영입", 9, HudTheme.TEXT)
	title.position = Vector2(22, 6)
	hud.tip.add(self, func(): return ["영입", "", "[T]", "영웅을 영입하고 목록을 리롤한다 · 판은 멈추지 않는다", ""])
	_process(0.0)

func _label(text: String, px: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", px)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l

func _process(_delta: float) -> void:
	visible = battle.state in ["prep", "battle"]
	if controls.shop:
		add_theme_stylebox_override("normal", _on_box)
	else:
		remove_theme_stylebox_override("normal")
