extends Panel  # 컨테이너가 아니라 자식을 좌표로 바로 놓는다(hud_build와 같다)
# 선택 패널(S206): 건설 격자 바로 왼쪽 [312,288,196,72]. 고른 영웅·용병이 하나거나 패널에 보인 적(controls.shown)이면
# 그림·이름·체력 막대(영웅은 Lv·마나 막대도)와 스탯 여섯, 여럿이면 그림 칸(24×20)을 7개씩 3줄까지 두고 칸을 누르면 그 유닛만 고른다.
# 패널의 적은 빨강 테두리·빨강 이름이고, 그 적이 쓰러지면 고른 유닛으로 돌아간다. 보일 것이 없으면 숨는다. hud._process가 refresh를 부른다

const HudTheme := preload("res://src/ui/hud_theme.gd")
const HudBuild := preload("res://src/ui/hud_build.gd")
const COLS := 7
const MAX := 21  # 그림 칸 수(7 × 3줄)
const MANA := Color("4080ff")  # 영웅 발밑 마나 막대(battle_view)와 같은 색

var hud
var battle
var controls
var one := Control.new()  # 하나일 때
var many := Control.new()  # 여럿일 때
var pic := TextureRect.new()
var title := Label.new()
var lv := Label.new()
var hp := ColorRect.new()  # 체력 막대의 찬 부분
var mana := ColorRect.new()
var mana_back := ColorRect.new()
var stats := []  # 스탯 Label 여섯: 체력·공격력·사거리·공격 간격·이동·방어력
var cells := []  # 그림 칸 버튼
var _units := []  # 그림 칸 차례의 유닛
var _icons := {}
var _plain: StyleBox
var _red: StyleBox

func _init(h) -> void:
	hud = h
	battle = h.battle
	controls = h.controls

func _ready() -> void:
	position = Vector2(312, 288)
	size = Vector2(196, 72)
	_plain = HudTheme.framed(HudTheme.box("panel", "PanelContainer", HudTheme.PANEL, HudTheme.LINE))
	_red = HudTheme.framed(HudTheme.box("panel", "PanelContainer", HudTheme.PANEL, HudTheme.DANGER))
	add_theme_stylebox_override("panel", _plain)
	for c in [one, many]:
		c.size = size
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(c)
	var box := Panel.new()
	box.add_theme_stylebox_override("panel", HudTheme.box("panel", "PanelContainer", HudTheme.CELL, HudTheme.LINE))
	box.position = Vector2(4, 4)
	box.size = Vector2(48, 48)
	one.add_child(box)
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	box.add_child(pic)
	_label(one, lv, 9, HudTheme.DIM, Vector2(4, 53), Vector2(48, 14)).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(one, title, 10, HudTheme.TEXT, Vector2(57, 1), Vector2(134, 14)).clip_text = true
	_bar(Vector2(57, 16), Vector2(134, 4), hp)
	_bar(Vector2(57, 21), Vector2(134, 2), mana, mana_back)
	mana.color = MANA
	for i in 6:
		stats.append(_label(one, Label.new(), 8, HudTheme.TEXT, Vector2(57 + (i % 2) * 68, 25 + (i / 2) * 13), Vector2(68, 12)))
	for i in MAX:
		cells.append(_cell(i))
	for n in find_children("*", "Control", true, false):
		if not n is BaseButton:
			n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mouse_filter = Control.MOUSE_FILTER_STOP  # 패널을 누른 클릭이 아래 맵으로 가지 않게

func _label(parent: Control, l: Label, font: int, color: Color, at: Vector2, sz: Vector2) -> Label:
	l.add_theme_font_size_override("font_size", font)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 3)
	l.position = at
	l.size = sz
	parent.add_child(l)
	return l

func _bar(at: Vector2, sz: Vector2, fill: ColorRect, back := ColorRect.new()) -> void:
	back.color = Color.BLACK
	back.position = at
	back.size = sz
	one.add_child(back)
	fill.position = at
	fill.size = sz
	one.add_child(fill)

# 그림 칸 하나: 건설 격자 칸(hud_build._cell)과 같은 테두리, 그 아래 2px 체력 막대
func _cell(i: int) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	for st in [["normal", HudTheme.LINE], ["hover", HudTheme.HOVER], ["pressed", HudTheme.ACCENT]]:
		var s := StyleBoxFlat.new()
		s.bg_color = HudTheme.CELL
		s.border_color = st[1]
		s.set_border_width_all(1)
		s.set_content_margin_all(0)
		b.add_theme_stylebox_override(st[0], s)
	b.position = Vector2(4 + (i % COLS) * 27, 3 + (i / COLS) * 23)
	b.size = Vector2(24, 20)
	b.pressed.connect(func(): controls.pick_unit(_units[i]))
	var t := TextureRect.new()
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.position = Vector2(2, 2)
	t.size = Vector2(20, 16)
	b.add_child(t)
	var back := ColorRect.new()
	back.color = Color.BLACK
	back.position = Vector2(1, 20)
	back.size = Vector2(22, 2)
	b.add_child(back)
	var fill := ColorRect.new()
	fill.color = HudTheme.GOOD
	fill.position = back.position
	fill.size = back.size
	b.add_child(fill)
	many.add_child(b)
	return b

func _icon(kind: String) -> AtlasTexture:
	if not _icons.has(kind):
		_icons[kind] = HudBuild.icon(kind)
	return _icons[kind]

func refresh() -> void:
	if controls.shown and (not controls.shown.alive or not battle.seen(controls.shown.pos)):  # 그 적이 쓰러지거나 어둠 속에 숨으면(S213) 고른 유닛으로 돌아간다
		controls.shown = null
	var units: Array = controls.selected.filter(func(u): return u.alive)
	var x = controls.shown if controls.shown else (units[0] if units.size() == 1 else null)
	visible = battle.state in ["prep", "battle"] and (x != null or units.size() > 1)
	if not visible:
		return
	one.visible = x != null
	many.visible = x == null
	add_theme_stylebox_override("panel", _red if x != null and x == controls.shown else _plain)
	if x != null:
		_one(x, x == controls.shown)
	else:
		_many(units)

func _one(x, foe: bool) -> void:
	var t := _icon(x.kind)
	var k: float = maxf(floorf(minf(44.0 / t.get_width(), 44.0 / t.get_height())), 1.0)  # 도트가 고르게 정수배로 키운다
	pic.texture = t
	pic.size = Vector2(t.get_width(), t.get_height()) * k
	pic.position = ((Vector2(48, 48) - pic.size) / 2).round()
	var hero: bool = x.get("is_hero") == true
	title.text = ("%s 적" % hud.ENEMIES.get(x.kind, x.kind)) if foe else hud.HEROES[x.kind] if hero else hud.NAMES.get(x.kind, x.kind)
	title.add_theme_color_override("font_color", HudTheme.DANGER if foe else HudTheme.TEXT)
	lv.visible = hero
	lv.text = "Lv%d" % x.level if hero else ""
	hp.size.x = 134.0 * clampf(x.hp / x.max_hp, 0.0, 1.0)
	hp.color = HudTheme.DANGER if foe else HudTheme.GOOD
	mana.visible = hero and x.max_mana > 0.0
	mana_back.visible = mana.visible
	if mana.visible:
		mana.size.x = 134.0 * clampf(x.mana / x.max_mana, 0.0, 1.0)
	# ponytail: 효과·오라를 뺀 기본값(S206). 걸린 효과를 보이려면 battle의 _might·_reach·armor_of로 바꾼다
	var reach: float = x.get("range") if x.get("range") != null else 0.0
	var lines := ["체력 %d/%d" % [ceili(x.hp), ceili(x.max_hp)], "공격력 %s" % hud._num(x.damage),
		"사거리 %s칸" % hud._num(reach) if reach > battle.RANGED else "사거리 근접",
		"공격 간격 %s초" % hud._num(x.attack_gap), "이동 %s칸/초" % hud._num(x.speed), "방어력 %s" % hud._num(x.armor)]
	for i in 6:
		stats[i].text = lines[i]

func _many(units: Array) -> void:
	_units = units.slice(0, MAX)
	for i in MAX:
		var b: Button = cells[i]
		b.visible = i < _units.size()
		if b.visible:
			var u = _units[i]
			b.get_child(0).texture = _icon(u.kind)
			b.get_child(2).size.x = 22.0 * clampf(u.hp / u.max_hp, 0.0, 1.0)
