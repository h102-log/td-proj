extends RefCounted
# HUD·메뉴 공용 테마(ui_research 4.9): 어두운 패널, 칸 바탕·테두리, 마우스 올림 테두리, 강조색 하나. 풀·흙 색은 쓰지 않는다
# 칸 안쪽 여백은 Godot 기본 테마 값을 그대로 둔다. 바꾸면 버튼 크기가 바뀌어 지금 줄(영웅 셋이 640px 안)이 넘친다

const PANEL := Color("14161c", 0.92)
const CELL := Color("23262f")
const LINE := Color("3a3f4b")
const HOVER := Color("6b7280")
const ACCENT := Color("ffd37f")
const DANGER := Color("ef3a0c")
const TEXT := Color("e8e8e8")
const DIM := Color("9aa0aa")

static func make(font_size: int) -> Theme:
	var t := Theme.new()
	t.default_font_size = font_size
	t.set_stylebox("panel", "PanelContainer", box("panel", "PanelContainer", PANEL, LINE))
	for st in [["normal", LINE], ["hover", HOVER], ["pressed", ACCENT], ["hover_pressed", ACCENT], ["focus", ACCENT]]:
		t.set_stylebox(st[0], "Button", box(st[0], "Button", Color.TRANSPARENT if st[0] == "focus" else CELL, st[1]))
	t.set_stylebox("disabled", "Button", box("disabled", "Button", CELL.darkened(0.3), LINE))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		t.set_color(c, "Button", TEXT)
	t.set_color("font_disabled_color", "Button", DIM)
	t.set_color("font_color", "Label", TEXT)
	return t

# 기본 테마의 같은 칸을 복사해 색만 바꾼다(안쪽 여백은 그대로)
static func box(name: String, type: String, bg: Color, line: Color) -> StyleBoxFlat:
	var base: StyleBox = ThemeDB.get_default_theme().get_stylebox(name, type)
	var s := StyleBoxFlat.new()
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		s.set_content_margin(side, base.get_margin(side))
	s.bg_color = bg
	s.border_color = line
	s.set_border_width_all(1)
	return s
