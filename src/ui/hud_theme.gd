extends RefCounted
# HUD·메뉴 공용 테마(ui_research 4.9): 어두운 패널, 칸 바탕·테두리, 마우스 올림 테두리, 강조색 하나. 풀·흙 색은 쓰지 않는다
# 칸 안쪽 여백은 Godot 기본 테마 값을 그대로 둔다(팝업·창 버튼). 위 띠 칸(S185)은 크기를 좌표로 정해 여백 없는 변형 BarCell을 쓴다

const PANEL := Color("14161c", 0.92)
const CELL := Color("23262f")
const LINE := Color("3a3f4b")  # 막대 바탕·꺼진 신뢰 점·빈 영웅 칸 점선(테두리 아님, S371). 이 색째 밝히면 막대 바탕/DANGER(2.65)·신뢰 점(7.47) 대비가 떨어진다
const BORDER := Color("697288")  # 칸·버튼·창·패널 테두리(S371): 칸 바탕·패널 바탕(반투명이면 순백 위까지)과 3:1 이상
const HOVER := Color("97a1b5")  # 마우스 올림 테두리(S371): 평상시↔hover 1.85, hover↔누름(ACCENT) 1.84로 비슷하게 갈린다
const ACCENT := Color("ffd37f")
const DANGER := Color("ef3a0c")
const TEXT := Color("e8e8e8")
const DIM := Color("9aa0aa")
const GOOD := Color("7cc85a")  # 거점 체력 막대·세금(S190)
const MAP_EDGE := Color("0b0c10")  # 미니맵·하단 패널 바깥 테두리(S209 2026-10-28, S241)
const MAP_RIM := Color("6b7280")  # 미니맵·하단 패널 안쪽 테두리(S209 2026-10-28, S241). 맵 가장자리 성벽 점(DIM)과 갈린다

static func make(font_size: int) -> Theme:
	var t := Theme.new()
	t.default_font_size = font_size
	t.set_stylebox("panel", "PanelContainer", box("panel", "PanelContainer", PANEL, BORDER))
	for st in [["normal", BORDER], ["hover", HOVER], ["pressed", ACCENT], ["hover_pressed", ACCENT], ["focus", ACCENT]]:
		t.set_stylebox(st[0], "Button", box(st[0], "Button", Color.TRANSPARENT if st[0] == "focus" else CELL, st[1]))
	t.set_stylebox("disabled", "Button", box("disabled", "Button", CELL.darkened(0.3), BORDER))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		t.set_color(c, "Button", TEXT)
	t.set_color("font_disabled_color", "Button", DIM)
	t.set_color("font_color", "Label", TEXT)
	t.set_type_variation("BarCell", "Button")
	for st in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		var s: StyleBox = t.get_stylebox(st, "Button").duplicate()
		s.set_content_margin_all(0)
		t.set_stylebox(st, "BarCell", s)
	# 설정 화면의 언어 목록·슬라이더(S371). 목록은 밑의 버튼 글자가 비치지 않게 불투명
	t.set_stylebox("panel", "PopupMenu", box("panel", "PopupMenu", Color(PANEL, 1.0), BORDER))
	t.set_stylebox("hover", "PopupMenu", box("hover", "PopupMenu", CELL, HOVER))
	var sep: StyleBoxLine = ThemeDB.get_default_theme().get_stylebox("separator", "PopupMenu").duplicate()
	sep.color = BORDER
	t.set_stylebox("separator", "PopupMenu", sep)
	for c in ["font_color", "font_hover_color", "font_separator_color"]:
		t.set_color(c, "PopupMenu", TEXT)
	for c in ["font_disabled_color", "font_accelerator_color"]:
		t.set_color(c, "PopupMenu", DIM)
	t.set_stylebox("slider", "HSlider", box("slider", "HSlider", CELL, BORDER))
	# 채운 쪽은 테두리 색 면, 마우스를 올리면 HOVER 면(S371)
	t.set_stylebox("grabber_area", "HSlider", box("grabber_area", "HSlider", BORDER, BORDER))
	t.set_stylebox("grabber_area_highlight", "HSlider", box("grabber_area_highlight", "HSlider", HOVER, HOVER))
	# 홈 오른쪽 끝을 손잡이 반 폭만큼 안으로: 100%에서 네모난 홈 끝이 둥근 기본 손잡이 밖으로 삐죽 나오지 않게(채움 끝은 늘 손잡이 가운데)
	var track: StyleBoxFlat = t.get_stylebox("slider", "HSlider")
	track.expand_margin_right = -ThemeDB.get_default_theme().get_icon("grabber", "HSlider").get_width() / 2.0
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

# 화면 아래 HUD 패널의 두 겹 테두리(S241): 안쪽 선은 MAP_RIM(따로 정한 색이면 그대로), 바로 바깥 1px은 MAP_EDGE
static func framed(s: StyleBoxFlat) -> StyleBoxFlat:
	if s.border_color == BORDER:
		s.border_color = MAP_RIM
	s.shadow_color = MAP_EDGE
	s.shadow_size = 1
	return s
