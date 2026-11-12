extends Panel  # 컨테이너가 아니라 자식을 좌표로 바로 놓는다(hud_build·hud_select와 같다)
# 거점 패널(S365, I298): 거점을 고르면(controls.village) 준비·전투 단계에 화면 아래 [92,262,216,98]에 뜬다. G로 열고 닫는다(controls).
# 위에서부터 머리 줄(거점·인구·«↶»·마을 레벨·원정 / 전투 중 집결), 탭 줄(근접·원거리·지원·최근 산 3종), 카드 다섯, 카드 아래 강화 띠, 안내 줄이다.
# 탭마다 TABS 목록 차례로 거점이 파는 종류만 앞 칸부터 놓고 남은 칸은 빈 채로 자리를 지킨다. 카드를 누르면 한 명, Shift+누르면 BATCH명까지 산다.
# 준비 단계의 «↶»는 이번 준비 단계에 패널에서 산 것을 나중 것부터 무른다(S367). 최근 칸 셋은 패널에서 산 최근 세 종류를 다시 산다(S368).
# 카드·강화 띠·최근 칸에 마우스를 올리면 패널 바로 위에 설명 상자가 뜬다. 보이기와 글은 hud._process가 부르는 refresh가 정한다

const HudTheme := preload("res://src/ui/hud_theme.gd")
const HudBuild := preload("res://src/ui/hud_build.gd")
const AT := Rect2(92, 262, 216, 98)  # 패널 자리(S365 임시값)
const SLOTS := 5  # 탭마다 카드 칸 수
const CARD := Vector2(40, 44)
const STEP := 42  # 카드 칸 40 + 간격 2
const BATCH := 5  # Shift+클릭으로 사는 최대 수(S365 임시값)
const PLUS_SECS := 0.8  # 산 직후 카드 위 «+n»이 보이는 초(I298 ⑤ 임시값)
const FADE := 0.35  # 인구 상한일 때 카드 그림 불투명도(건설 격자 흐림과 같다)
const WARN := Color("e0c040")  # 골드가 모자란 값(절반 이상 있음). 건설 격자와 같다(hud_build.gd WARN)
const EMPTY_BG := Color("1b1d24")
const EMPTY_LINE := Color("2a2e38")
const PIP_OFF := Color("4a505c")
const TAB_ON := Color("2f3440")
const TORCH_EDGE := Color("c06a2a")  # 원정 버튼 테두리(사기 버튼과 가른다)
# 탭 이름·그림·목록(S365). 목록 차례로 거점이 파는 종류만 놓는다(병사·궁수도 거점이 판다, S98 2026-11-12 변경)
const TABS := [["근접", "sword", ["soldier", "shieldman", "spearman", "cavalry"]],
	["원거리", "bow", ["archer", "netter", "fire_mage", "thunder_mage", "frost_mage"]],
	["지원", "plus", ["engineer", "cleric"]]]
const ROLE := {  # 설명 상자 둘째 줄(I298 ④)
	"soldier": "값싼 근접 · 길을 막는다", "shieldman": "정면 돌진을 막아 기절시키는 탱커", "spearman": "둘째 줄 근접 · 나는 적도 친다",
	"cavalry": "빠른 근접 · 6칸 돌진", "archer": "원거리 물리 · 강화마다 명중률", "netter": "나는 적을 그물로 끌어내린다",
	"fire_mage": "느린 큰 한 방 · 범위 마법과 발화", "thunder_mage": "마법 · 확률로 4번 전이", "frost_mage": "마법 · 냉기 4겹이면 빙결",
	"cleric": "공격하지 않고 다친 아군을 회복", "engineer": "짓고 고친다 · 공격하지 않음"}
const ICONS := {
	"sword": ["......#", ".....#.", "....#..", "#..#...", ".##....", ".##....", "#..#..."],
	"bow": ["..##...", ".#..#..", "#....#.", "#######", "#....#.", ".#..#..", "..##..."],
	"plus": ["..###..", "..###..", "#######", "#######", "#######", "..###..", "..###.."]}
const TORCH := [".o.o.", "oyyyo", ".oyo.", "..#..", "..#..", "..#..", "..#.."]
const SLASH := [".......#", "......#.", ".....#..", "....#...", "...#....", "..#.....", ".#......", "#......."]  # 모자란 값 동전의 빗금(I298 ②)
const UNDO := ["..#....", ".##....", "######.", ".##...#", "..#...#", "......#", "..####."]  # «↶» 휘어 돌아가는 화살(I299 ①). 글꼴에 ↶ 글자가 없어 그림으로 그린다
const TAB_W := 48  # 탭 버튼 폭(I299 ③). 간격 2
const RECENT := 3  # 최근 산 종류 칸 수(S368 임시값)
const CELL := 12  # 머리 줄 «↶»·최근 칸 한 변(누르는 칸 최소 12)

var hud
var battle
var controls
var tabs := []  # 탭 버튼 셋
var kinds := []  # 지금 탭의 칸 다섯 종류(빈 칸 "")
var cards := []
var names := []
var owned := []
var costs := []
var pics := []
var slashes := []
var pips := []  # 카드마다 강화 점(ColorRect 셋)
var plus := []
var strips := []
var village: Button
var raid: Button
var rally: Button
var undo: Button  # 준비 단계 머리 줄 «↶»(S367)
var undos := []  # 무를 목록: 패널 구매마다 [종류, 산 용병들](I299 ②). 판이 준비 단계가 아니면 비운다
var recents := []  # 탭 줄 오른쪽 끝 최근 칸 셋(S368)
var recent := []  # 최근 칸 셋의 종류(빈 칸 "")
var recent_pics := []
var tab_hint: Label  # 탭 줄 «Tab»
var pop: Label
var info := PanelContainer.new()  # 설명 상자(I298 ④)
var _tab_names := []  # 탭 이름 Label
var _tab_counts := []  # 탭 종류 수 Label
var _tab_lines := []  # 고른 탭 밑줄
var _tab_icons := []
var _card_styles := []  # 카드마다 [보통, 마우스, 빈 칸]
var _owned_bg := []
var _coins := []
var _info := []  # 설명 상자 줄 Label: 머리·역할·수치·다음 강화·이유
var _plus := {}  # 종류 → [보일 때까지(hud._now), 산 수](I298 ⑤)
var _arm := -INF  # 원정 버튼을 한 번 누른 hud._now(I298 ⑦)
var _last := {}  # 종류 → 패널에서 마지막으로 산 차례(_seq). 최근 칸이 가장 오래전에 산 칸을 고른다(S368)
var _seq := 0

func _init(h) -> void:
	hud = h
	battle = h.battle
	controls = h.controls

func _ready() -> void:
	position = AT.position
	size = AT.size
	add_theme_stylebox_override("panel", HudTheme.framed(HudTheme.box("panel", "PanelContainer", HudTheme.PANEL, HudTheme.LINE)))
	_head()
	for t in TABS.size():
		_tab(t)
	tab_hint = _label(self, "Tab", 7, HudTheme.ACCENT)
	tab_hint.position = Vector2(4 + TABS.size() * (TAB_W + 2) + 1, 17)
	tab_hint.size = Vector2(14, 13)
	tab_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	for j in RECENT:
		_recent_cell(j)
	for i in SLOTS:
		_card(i)
	var foot := _label(self, "클릭 1명 · Shift+클릭 5명 · 마우스 올리면 설명", 7, HudTheme.DIM)
	foot.position = Vector2(4, 88)
	foot.size = Vector2(208, 10)
	info.add_theme_stylebox_override("panel", HudTheme.box("panel", "PanelContainer", Color(HudTheme.PANEL, 1.0), HudTheme.LINE))
	info.custom_minimum_size.x = AT.size.x
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.visible = false
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(col)
	for row in [[9, HudTheme.TEXT], [8, HudTheme.DIM], [8, HudTheme.TEXT], [8, HudTheme.ACCENT], [8, HudTheme.DANGER]]:
		_info.append(_label(col, "", row[0], row[1]))
	add_child(info)
	refresh(0.0)

# 머리 줄: 거점 그림·«거점»·G, 인구, 준비 단계 마을 레벨·원정, 전투 단계 집결
func _head() -> void:
	var keep := TextureRect.new()
	keep.texture = HudBuild.icon("base")
	keep.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	keep.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	keep.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	keep.position = Vector2(3, 2)
	keep.size = Vector2(11, 11)
	keep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(keep)
	var title := _label(self, "거점", 9, HudTheme.TEXT)
	title.position = Vector2(16, 1)
	title.size = Vector2(22, 13)
	var key := _label(self, "G", 7, HudTheme.ACCENT)
	key.position = Vector2(38, 1)
	key.size = Vector2(8, 13)
	pop = _label(self, "", 8, HudTheme.TEXT)
	pop.position = Vector2(48, 1)
	pop.size = Vector2(40, 13)
	hud.tip.add(pop_cell(), func(): return ["인구", "", "", hud._pop_line(), ""])
	undo = _head_button(Vector2(90, 2), Vector2(CELL, CELL), HudBuild.dots(UNDO, {"#": HudTheme.TEXT}), HudTheme.LINE)
	undo.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for st in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		undo.get_theme_stylebox(st).content_margin_left = 0
	undo.pressed.connect(undo_last)
	hud.tip.add(undo, _undo_tip)
	village = _head_button(Vector2(104, 2), Vector2(54, 12), HudBuild.dots(hud.UP, {"#": HudTheme.ACCENT}), HudTheme.LINE)
	village.pressed.connect(func(): battle.raise_village())
	hud.tip.add(village, func(): return ["마을 레벨 올리기", "", "", hud._opens, "✕ " + _gold_short(_village_cost()) if battle.gold < _village_cost() else ""])
	raid = _head_button(Vector2(160, 2), Vector2(52, 12), HudBuild.dots(TORCH, {"#": Color("8a6a4a"), "o": HudTheme.DANGER, "y": HudTheme.ACCENT}), TORCH_EDGE)
	raid.pressed.connect(_raid_press)
	hud.tip.add(raid, _raid_tip)
	rally = _head_button(Vector2(132, 2), Vector2(80, 12), HudBuild.dots(hud.FLAG, {"|": HudTheme.TEXT, "#": Color("3c9f9c")}), HudTheme.LINE)
	rally.toggle_mode = true
	rally.pressed.connect(func(): controls.rallying = not controls.rallying)
	hud.tip.add(rally, func(): return ["집결", "", "", "누르고 맵을 누르면 거점의 집결 지점이 된다 · 산 용병이 그리로 간다", ""])

# 인구 글은 Label이라 툴팁을 받지 않는다. 같은 자리에 빈 버튼을 깔아 툴팁만 받는다
func pop_cell() -> Control:
	var c := Control.new()
	c.position = pop.position
	c.size = pop.size
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(c)
	return c

func _head_button(at: Vector2, sz: Vector2, pic: Texture2D, line: Color) -> Button:
	var b := Button.new()
	b.theme_type_variation = "BarCell"  # 안쪽 여백이 없어 좌표로 준 크기를 넘지 않는다
	b.focus_mode = Control.FOCUS_NONE
	b.icon = pic
	b.add_theme_constant_override("icon_max_width", 7)
	b.add_theme_constant_override("h_separation", 2)
	b.add_theme_font_size_override("font_size", 7)
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for st in [["normal", HudTheme.CELL, line], ["hover", HudTheme.CELL, HudTheme.HOVER], ["pressed", HudTheme.CELL, HudTheme.ACCENT],
			["hover_pressed", HudTheme.CELL, HudTheme.ACCENT], ["disabled", HudTheme.CELL.darkened(0.3), line]]:
		var s := HudTheme.box(st[0], "Button", st[1], st[2])
		s.set_content_margin_all(0)
		s.content_margin_left = 3
		b.add_theme_stylebox_override(st[0], s)
	add_child(b)  # 트리에 붙인 뒤 크기를 준다. 붙이기 전에는 기본 글꼴로 잰 최소 크기로 늘어난다
	b.position = at
	b.size = sz
	return b

func _tab(t: int) -> void:
	var b := Button.new()
	b.toggle_mode = true
	b.focus_mode = Control.FOCUS_NONE
	b.position = Vector2(4 + t * (TAB_W + 2), 17)
	b.size = Vector2(TAB_W, 13)
	var off := StyleBoxFlat.new()
	off.bg_color = HudTheme.CELL
	off.border_color = HudTheme.LINE
	off.set_border_width_all(1)
	off.set_content_margin_all(0)
	var on := off.duplicate()
	on.bg_color = TAB_ON
	on.border_color = HudTheme.ACCENT
	var hover := off.duplicate()
	hover.border_color = HudTheme.HOVER
	for st in [["normal", off], ["hover", hover], ["pressed", on], ["hover_pressed", on]]:
		b.add_theme_stylebox_override(st[0], st[1])
	b.pressed.connect(func(): controls.keep_tab = t)
	add_child(b)
	var pic := TextureRect.new()
	pic.texture = HudBuild.dots(ICONS[TABS[t][1]])
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.position = Vector2(3, 3)
	pic.size = Vector2(7, 7)
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(pic)
	var name := _label(b, TABS[t][0], 8, HudTheme.TEXT)
	name.position = Vector2(12, 0)
	name.size = Vector2(TAB_W - 20, 13)
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var count := _label(b, "", 7, HudTheme.DIM)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count.position = Vector2(TAB_W - 9, 0)
	count.size = Vector2(7, 13)
	var line := ColorRect.new()
	line.color = HudTheme.ACCENT
	line.position = Vector2(1, 11)
	line.size = Vector2(TAB_W - 2, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(line)
	tabs.append(b)
	_tab_names.append(name)
	_tab_counts.append(count)
	_tab_lines.append(line)
	_tab_icons.append(pic)

# 카드 하나와 그 아래 강화 띠(S365): 이름, 그림, 보유 «×n», 동전·값(빗금), 강화 점, «+n»
func _card(i: int) -> void:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.position = Vector2(4 + i * STEP, 32)
	b.size = CARD
	var st := []
	for look in [[HudTheme.CELL, HudTheme.LINE], [Color("2b2f3a"), HudTheme.HOVER], [EMPTY_BG, EMPTY_LINE]]:
		var s := StyleBoxFlat.new()
		s.bg_color = look[0]
		s.border_color = look[1]
		s.set_border_width_all(1)
		s.set_content_margin_all(0)
		st.append(s)
	_card_styles.append(st)
	for k in ["normal", "pressed", "focus"]:
		b.add_theme_stylebox_override(k, st[0])
	b.add_theme_stylebox_override("hover", st[1])
	b.add_theme_stylebox_override("hover_pressed", st[1])
	b.add_theme_stylebox_override("disabled", st[2])
	b.pressed.connect(func(): buy(i, 1))
	b.gui_input.connect(func(e): _card_input(e, i))
	add_child(b)
	var name := _label(b, "", 7, HudTheme.TEXT)
	name.position = Vector2(2, 0)
	name.size = Vector2(37, 10)
	name.clip_text = true
	var pic := TextureRect.new()
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED  # 그림은 1배(맵에서 보는 크기)
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.position = Vector2(0, 10)
	pic.size = Vector2(40, 22)
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(pic)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.6)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(bg)
	var mine := _label(b, "", 7, HudTheme.TEXT)
	mine.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	mine.position = Vector2(20, 16)
	mine.size = Vector2(18, 9)
	var coin := TextureRect.new()
	coin.texture = HudBuild.dots(hud.COIN, {"#": HudTheme.ACCENT, "o": Color("b08a3a")})
	coin.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	coin.position = Vector2(3, 35)
	coin.size = Vector2(6, 6)
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(coin)
	var slash := TextureRect.new()
	slash.texture = HudBuild.dots(SLASH, {"#": HudTheme.DANGER})
	slash.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	slash.position = Vector2(2, 34)
	slash.size = Vector2(8, 8)
	slash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(slash)
	var cost := _label(b, "", 8, HudTheme.TEXT)
	cost.position = Vector2(11, 32)
	cost.size = Vector2(18, 12)
	cost.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var dots := []
	for j in 3:
		var p := ColorRect.new()
		p.size = Vector2(3, 3)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(p)
		dots.append(p)
	var got := _label(b, "", 9, HudTheme.GOOD)
	got.position = Vector2(2, 9)
	got.size = Vector2(20, 12)
	var strip := Button.new()
	strip.theme_type_variation = "BarCell"
	strip.focus_mode = Control.FOCUS_NONE
	strip.icon = HudBuild.dots(hud.UP, {"#": HudTheme.ACCENT})
	strip.add_theme_constant_override("icon_max_width", 5)
	strip.add_theme_constant_override("h_separation", 2)
	strip.add_theme_font_size_override("font_size", 7)
	strip.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	strip.pressed.connect(func(): rank(i))
	add_child(strip)  # 머리 줄 버튼처럼 붙인 뒤 크기를 준다
	strip.position = Vector2(4 + i * STEP, 32 + CARD.y + 1)
	strip.size = Vector2(CARD.x, 12)
	cards.append(b)
	names.append(name)
	pics.append(pic)
	_owned_bg.append(bg)
	owned.append(mine)
	_coins.append(coin)
	slashes.append(slash)
	costs.append(cost)
	pips.append(dots)
	plus.append(got)
	strips.append(strip)
	kinds.append("")

# 탭 줄 오른쪽 끝 최근 칸 하나(S368, I299 ③): 셋째 칸 오른쪽 끝이 카드 줄 오른쪽 끝(212)이다. 누르면 한 명, Shift+누르면 BATCH명까지
func _recent_cell(j: int) -> void:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.position = Vector2(4 + SLOTS * STEP - 2 - (RECENT - j) * (CELL + 2) + 2, 17)
	b.size = Vector2(CELL, CELL)
	var on := StyleBoxFlat.new()
	on.bg_color = HudTheme.CELL
	on.border_color = HudTheme.LINE
	on.set_border_width_all(1)
	on.set_content_margin_all(0)
	var hover := on.duplicate()
	hover.bg_color = Color("2b2f3a")
	hover.border_color = HudTheme.HOVER
	var empty := on.duplicate()
	empty.bg_color = EMPTY_BG
	empty.border_color = EMPTY_LINE
	for k in ["normal", "pressed", "focus"]:
		b.add_theme_stylebox_override(k, on)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("hover_pressed", hover)
	b.add_theme_stylebox_override("disabled", empty)
	b.pressed.connect(func(): buy_kind(recent[j], 1))
	b.gui_input.connect(func(e): _recent_input(e, j))
	add_child(b)
	var pic := TextureRect.new()
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.position = Vector2(1, 1)
	pic.size = Vector2(CELL - 2, CELL - 2)
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(pic)
	recents.append(b)
	recent_pics.append(pic)
	recent.append("")

func _label(parent: Control, text: String, font: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

# 탭 t에 놓는 종류: TABS 목록 차례로 거점이 파는 것(base.produces, 파는 곳 sellers에 거점이 든 것)만. 판 동안 바뀌지 않는다
func tab_kinds(t: int) -> Array:
	var out: Array = TABS[t][2].filter(func(k): return battle.base in battle.sellers(k))
	while out.size() < SLOTS:
		out.append("")
	return out.slice(0, SLOTS)

# 그 종류가 든 탭(없으면 -1). 공병 칸·5 키로 거점을 고르면 이 탭이 열린다(I298 ①)
static func tab_of(kind: String) -> int:
	for t in TABS.size():
		if kind in TABS[t][2]:
			return t
	return -1

# Shift를 누른 왼쪽 버튼 누름은 BATCH명까지 산다(I298 ③). 버튼의 보통 누름(한 명)은 받지 않게 처리를 끝낸다
func _card_input(e: InputEvent, i: int) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed and e.shift_pressed:
		buy(i, BATCH)
		accept_event()

# 최근 칸도 카드처럼 Shift를 누른 왼쪽 버튼 누름은 BATCH명까지 산다(S368)
func _recent_input(e: InputEvent, j: int) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed and e.shift_pressed:
		buy_kind(recent[j], BATCH)
		accept_event()

# 칸 i의 종류를 산다(buy_kind)
func buy(i: int, count: int) -> int:
	return buy_kind(kinds[i] if i < kinds.size() else "", count)

# 그 종류를 거점에서 count명까지 산다. 한 번이라도 못 사면 멈춘다(I298 ③). 산 수를 «+n»과 전투 단계 토스트로 보이고(I298 ⑤),
# 최근 칸(S368)에 적고, 준비 단계면 무를 목록(S367)에 더한다
func buy_kind(k: String, count: int) -> int:
	if k == "":
		return 0
	var got := []
	for j in count:
		var m = battle.recruit(battle.base, k)
		if m == null:
			break
		got.append(m)
	if not got.is_empty():
		_plus[k] = [hud._now + PLUS_SECS, got.size()]
		if battle.state == "battle":
			hud.toasts.push("%s +%d → 집결 지점" % [hud.NAMES[k], got.size()])
		elif battle.state == "prep":
			undos.append([k, got])
		_note(k)
	return got.size()

# 최근 칸에 산 종류를 적는다(S368): 칸에 있으면 그대로, 없으면 빈 칸(왼쪽부터)이나 가장 오래전에 산 종류의 칸에
func _note(k: String) -> void:
	_seq += 1
	_last[k] = _seq
	if k in recent:
		return
	var j: int = recent.find("")
	if j < 0:
		j = 0
		for i in recent.size():
			if _last.get(recent[i], 0) < _last.get(recent[j], 0):
				j = i
	recent[j] = k

# 무를 목록의 마지막 구매 가운데 아직 남은 용병이 있는 것: [종류, 남은 용병들]. 없으면 []
func _undo_left() -> Array:
	for i in range(undos.size() - 1, -1, -1):
		var left: Array = undos[i][1].filter(func(u): return u.alive and u in battle.units)
		if not left.is_empty():
			return [undos[i][0], left]
	return []

# «↶»(S367): 남은 용병이 있는 마지막 구매를 판매 규칙 그대로 판다(battle.sell, S69). 남은 것이 없는 구매는 건너뛰고 뺀다
func undo_last() -> void:
	while not undos.is_empty():
		var e: Array = undos.pop_back()
		var left: Array = e[1].filter(func(u): return u.alive and u in battle.units)
		if not left.is_empty():
			battle.sell(left)
			return

func _undo_tip() -> Array:
	var e := _undo_left()
	if e.is_empty():
		return ["구매 되돌리기", "", "", "준비 단계에 거점 패널에서 산 것을 나중 것부터 무른다", "✕ 무를 구매가 없다"]
	var back: int = e[1].reduce(func(n, u): return n + battle.refund(u), 0)
	return ["구매 되돌리기", "", "", "직전 구매를 무른다\n%s ×%d · %d골드 돌려받음" % [hud.NAMES[e[0]], e[1].size(), back], ""]

# 칸 i 종류를 한 단계 강화한다(S254). 준비 단계가 아니거나 최대·골드 모자람이면 battle이 거부한다
func rank(i: int) -> void:
	var k: String = kinds[i] if i < kinds.size() else ""
	if k != "":
		battle.rank_up(k)

# 원정 버튼(I298 ⑦): 첫 클릭은 «원정?», CONFIRM초 안에 다시 누르면 들어간다(S74 철거와 같은 꼴)
func _raid_press() -> void:
	if hud._now - _arm < hud.CONFIRM:
		_arm = -INF
		battle.start_raid()
	else:
		_arm = hud._now

func _armed() -> bool:
	return hud._now - _arm < hud.CONFIRM

func _raid_tip() -> Array:
	var f: String = battle.next_floor()
	var why: String = battle.raid_block()
	var reason: String = tr("%d라운드부터") % battle.FLOOR_KINDS[f].opens if why == "round" else hud.RAID_WHY.get(why, "")
	var body: String = (tr(battle.FLOOR_KINDS[f].title) + " · " if f != "" else "") + tr("남은 횃불 %d") % battle.torches
	return ["원정", "", "", body + "\n" + "두 번 눌러 들어간다 · 횃불 하나를 쓴다", "✕ " + reason if reason != "" else ""]

func _village_cost() -> int:
	return battle.VILLAGE_UP[battle.village_level - 1] if battle.village_level <= battle.VILLAGE_UP.size() else 0

func _gold_short(cost: int) -> String:
	return "골드 %d 모자람" % (cost - battle.gold)

# 값 글자색(I298 ②): 건설 격자 값과 같다
static func cost_color(gold: int, cost: int) -> Color:
	return HudTheme.TEXT if gold >= cost else WARN if gold * 2 >= cost else HudTheme.DANGER

# 카드 칸에서 사지 못하는 이유(I298 ④). 살 수 있으면 ""
func buy_reason(k: String) -> String:
	var d: Dictionary = battle.merc_stats(k)
	if battle.pop_used() >= battle.pop_cap():
		return ("인구 가득 — 집을 지으면 %d명 늘어난다" % battle.STRUCTURE_KINDS.house.pop) if battle.village.has_area() else "인구 가득"
	if battle.gold < d.cost:
		return _gold_short(d.cost)
	if battle._exit_of(battle.base) == null:
		return "거점 둘레가 막혀 나올 칸이 없다"
	return ""

# 강화 띠에서 올리지 못하는 이유(I298 ④). 올릴 수 있으면 ""
func rank_reason(k: String) -> String:
	var d: Dictionary = battle.MERC_KINDS[k]
	var r: int = battle.merc_rank.get(k, 0)
	if r >= d.ranks.size():
		return "강화 최대"
	if battle.state != "prep":
		return "준비 단계에만"
	if battle.gold < d.rank_cost[r]:
		return _gold_short(d.rank_cost[r])
	return ""

# 수치 줄(I298 ④): 체력·공격력(마법이면 «마법»)·사거리·방어력, 사제는 회복
func stat_line(k: String) -> String:
	var d: Dictionary = battle.merc_stats(k)
	var parts := ["체력 %s" % hud._num(d.hp)]
	if d.damage > 0.0:
		parts.append(("마법 %s" if d.damage_kind == "magic" else "공격력 %s") % hud._num(d.damage))
	if d.range > 0.0:
		parts.append("사거리 %s칸" % hud._num(d.range))
	if d.armor > 0.0:
		parts.append("방어력 %s" % hud._num(d.armor))
	if not d.mend.is_empty():
		parts.append("회복 %s" % hud._num(d.mend.heal))
	return " · ".join(parts)

func refresh(delta: float) -> void:
	if battle.state != "prep":  # 무를 목록은 이번 준비 단계 것만(S367)
		undos.clear()
	visible = controls.village and battle.state in ["prep", "battle"] and not controls.shop
	if not visible:
		_arm = -INF
		controls.rallying = false
		info.visible = false
		return
	var prep: bool = battle.state == "prep"
	var full: bool = battle.pop_used() >= battle.pop_cap()
	pop.text = "인구 %d/%d" % [battle.pop_used(), battle.pop_cap()]
	pop.add_theme_color_override("font_color", HudTheme.DANGER if full else HudTheme.TEXT)
	undo.visible = prep
	undo.disabled = _undo_left().is_empty()
	village.visible = prep and battle.village_level <= battle.VILLAGE_UP.size()
	if village.visible:
		village.text = tr("마을 Lv%d %d") % [battle.village_level + 1, _village_cost()]
		village.add_theme_color_override("font_color", cost_color(battle.gold, _village_cost()))
		village.add_theme_font_size_override("font_size", _fit_button(village))
	raid.visible = prep and not battle.den.is_empty()
	if raid.visible:
		var f: String = battle.next_floor()
		raid.disabled = battle.raid_block() != ""
		raid.text = "원정?" if _armed() and not raid.disabled else tr("원정 %d층") % (battle.floors_cleared + 1) if f != "" else "원정"
		for c in ["font_color", "font_hover_color"]:
			raid.add_theme_color_override(c, HudTheme.DANGER if raid.text == "원정?" else HudTheme.TEXT)
		raid.add_theme_font_size_override("font_size", _fit_button(raid))
	rally.visible = battle.state == "battle"
	rally.text = "집결"
	rally.button_pressed = controls.rallying
	var t: int = controls.keep_tab
	for i in tabs.size():
		tabs[i].button_pressed = i == t
		_tab_lines[i].visible = i == t
		_tab_names[i].add_theme_color_override("font_color", HudTheme.TEXT if i == t else HudTheme.DIM)
		_tab_names[i].add_theme_font_size_override("font_size", _fit(_tab_names[i], TABS[i][0], 8, TAB_W - 20.0))  # 영어 «Support»처럼 넘치면 한 단계 작게(S193)
		_tab_icons[i].modulate = [Color("d8705a"), Color("6aa8e0"), HudTheme.GOOD][i] if i == t else HudTheme.DIM
		_tab_counts[i].text = str(tab_kinds(i).filter(func(k): return k != "").size())
	var now := tab_kinds(t)
	for i in SLOTS:
		kinds[i] = now[i]
		_show_card(i, prep, full)
	for j in RECENT:
		_show_recent(j)
	_show_info()

# 최근 칸 하나(S368): 빈 칸은 꺼진 빈 칸, 지금 사지 못하면(I298 ④ 이유) 그림을 흐리게
func _show_recent(j: int) -> void:
	var k: String = recent[j]
	recents[j].disabled = k == ""
	recent_pics[j].visible = k != ""
	if k != "":
		recent_pics[j].texture = HudBuild.icon(k)
		recent_pics[j].modulate.a = FADE if buy_reason(k) != "" else 1.0

func _show_card(i: int, prep: bool, full: bool) -> void:
	var k: String = kinds[i]
	var c: Button = cards[i]
	var empty := k == ""
	c.disabled = empty
	for n in [names[i], pics[i], _coins[i], costs[i]]:
		n.visible = not empty
	strips[i].visible = not empty
	if empty:
		owned[i].visible = false
		_owned_bg[i].visible = false
		slashes[i].visible = false
		plus[i].visible = false
		for p in pips[i]:
			p.visible = false
		return
	var d: Dictionary = battle.merc_stats(k)
	names[i].text = hud.NAMES[k]
	names[i].add_theme_font_size_override("font_size", _fit(names[i], hud.NAMES[k], 7, 37.0))
	names[i].add_theme_color_override("font_color", HudTheme.DIM if full else HudTheme.TEXT)
	pics[i].texture = HudBuild.icon(k)
	pics[i].modulate.a = FADE if full else 1.0
	var n: int = battle.units.filter(func(u): return u.kind == k and u.alive).size()
	owned[i].text = "×%d" % n
	owned[i].visible = n > 0
	_owned_bg[i].visible = n > 0
	if n > 0:
		var w: float = owned[i].get_theme_font("font").get_string_size(owned[i].text, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
		_owned_bg[i].position = Vector2(CARD.x - w - 4, 17)
		_owned_bg[i].size = Vector2(w + 3, 9)
	costs[i].text = str(d.cost)
	costs[i].add_theme_color_override("font_color", cost_color(battle.gold, d.cost))
	slashes[i].visible = battle.gold < d.cost
	var ranks: Array = battle.MERC_KINDS[k].ranks
	var r: int = battle.merc_rank.get(k, 0)
	for j in pips[i].size():
		var p: ColorRect = pips[i][j]
		p.visible = j < ranks.size()
		p.color = HudTheme.ACCENT if j < r else PIP_OFF
		p.position = Vector2(CARD.x - 4 * ranks.size() - 1 + j * 4, 36)
	var top: bool = r >= ranks.size()
	var s: Button = strips[i]
	s.text = "강화 최대" if top else tr("강화 %d") % battle.MERC_KINDS[k].rank_cost[r]
	s.disabled = top or not prep
	s.add_theme_color_override("font_color", HudTheme.TEXT if top else cost_color(battle.gold, battle.MERC_KINDS[k].rank_cost[r]))
	var got: Array = _plus.get(k, [-INF, 0])
	plus[i].visible = hud._now < got[0]
	plus[i].text = "+%d" % got[1]

# 글자 크기: 지금 언어로 옮긴 text가 폭 w에 들면 px, 아니면 한 단계 작게(S193 — 영어 글도 칸 안에)
func _fit(l: Label, text: String, px: int, w: float) -> int:
	return px if l.get_theme_font("font").get_string_size(tr(text), HORIZONTAL_ALIGNMENT_LEFT, -1, px).x <= w else px - 1

# 머리 줄 버튼 글자 크기(I299 ①): 그림 자리(왼쪽 여백 3 + 그림 7 + 사이 2)를 뺀 폭에 들면 7, 아니면 6
func _fit_button(b: Button) -> int:
	return 7 if b.get_theme_font("font").get_string_size(tr(b.text), HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x <= b.size.x - 12 else 6

# 마우스를 올린 카드·강화 띠·최근 칸(S368)의 설명 상자(I298 ④): 패널 바로 위, 지연 없이
func _show_info() -> void:
	var hov := get_viewport().gui_get_hovered_control()
	var k := ""
	var on_strip := strips.has(hov)
	if cards.has(hov) or on_strip:
		k = kinds[maxi(cards.find(hov), strips.find(hov))]
	elif recents.has(hov):
		k = recent[recents.find(hov)]
	if k == "":
		info.visible = false
		return
	var d: Dictionary = battle.MERC_KINDS[k]
	var r: int = battle.merc_rank.get(k, 0)
	var n: int = battle.units.filter(func(u): return u.kind == k and u.alive).size()
	_info[0].text = "%s · %d골드 · 보유 %d · 강화 %d/%d" % [hud.NAMES[k], battle.merc_stats(k).cost, n, r, d.ranks.size()]
	_info[1].text = ROLE.get(k, "")
	_info[2].text = stat_line(k)
	_info[3].text = "강화 최대" if r >= d.ranks.size() else "다음 강화 %d골드: %s" % [d.rank_cost[r], hud._rank_line(k, d.ranks[r])]
	var why: String = rank_reason(k) if on_strip else buy_reason(k)
	_info[4].text = "✕ " + why if why != "" and why != "강화 최대" else ""
	_info[4].visible = _info[4].text != ""
	info.visible = true
	info.reset_size()
	info.position = Vector2(0, -info.size.y - 2)
