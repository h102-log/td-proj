extends Panel  # 컨테이너가 아니라 자식을 정렬하지 않는다. 칸 자리는 좌표로 바로 정한다
# 건설 격자(S186): 화면 오른쪽 아래 [510,288,130,72]에 놓기 칸 12개를 세 줄로 둔다. 칸이나 단축키를 누르면 놓기 모드를 켜고, 다시 누르면 끈다.
# 못 놓는 칸은 흐리게(0.35) 하고 이유는 정보 칸의 빨간 줄에 쓴다. 흐린 칸을 누르면 테두리가 번쩍이고,
# 준비 단계에 마을 레벨로 잠긴 칸이면 거점을 골라 마을 레벨 팝업을 띄운다(I132).
# 격자 위 정보 칸은 칸 호버 > 놓기 중 > 고른 구조물·성곽·거점을 보인다. 카메라가 맨 아래면 격자 왼쪽(선택 패널이 보이면 그 왼쪽)으로 옮긴다(S186).
# 전투 단계에 놀고 있는 공병이 없으면 1·2줄에 «공병 없음» 띠를 덮는다(I128). 칸 그림은 시설·용병 그림을 잘라 쓴다(S30)

const BattleView := preload("res://src/ui/battle_view.gd")
const HudTheme := preload("res://src/ui/hud_theme.gd")
const ROWS := [["wall", "tower", "magic", "cannon"], ["barracks", "workshop", "archery", "house", "church"], ["soldier", "engineer", "archer", "shelter"]]  # 용병은 파는 시설 바로 아래, 대피소는 집 아래(S186 2026-10-27 변경)
const HEADS := ["공", "마", "용"]  # ponytail: 줄 머리는 한 글자 임시값. 전용 아이콘이 생기면 그림으로 바꾼다
const PAD := 4  # 격자 안쪽 여백
const HEAD := 12  # 줄 머리 폭
const STEP := 22  # 칸 20 + 간격 2
const FLASH := 0.3  # 거부 표시 길이(초, I132 임시값)
const WARN := Color("e0c040")  # 골드가 모자란 비용(절반 이상 있음). 절반도 없으면 DANGER
const THINGS := {"castle_wall": "성벽", "gate": "성문", "base": "거점"}  # 고른 것 가운데 NAMES에 없는 이름
const CROSS := ["#...#", ".#.#.", "..#..", ".#.#.", "#...#"]  # ✕ 도트

var hud
var battle
var controls
var cells := {}  # kind → 칸 버튼
var info := PanelContainer.new()  # 정보 칸
var reason := Label.new()  # 정보 칸의 빨간 이유 줄
var band := PanelContainer.new()  # «공병 없음» 띠(I128)
var _keys := {}  # kind → 단축키 글자
var _costs := {}  # kind → 비용 Label
var _styles := {}  # kind → [normal, hover, pressed] 테두리
var _flash := {}  # kind → 남은 거부 표시 초
var _none := false  # 전투 단계에 놀고 있는 공병이 하나도 없다
var _name := Label.new()
var _cost := Label.new()
var _key := Label.new()
var _body := Label.new()
var _state := Label.new()

func _init(h) -> void:
	hud = h
	battle = h.battle
	controls = h.controls

func _ready() -> void:
	position = Vector2(510, 288)
	size = Vector2(130, 72)
	add_theme_stylebox_override("panel", HudTheme.box("panel", "PanelContainer", HudTheme.PANEL, HudTheme.LINE))
	var costs: Dictionary = battle.STRUCTURE_KINDS.merged(battle.MERC_KINDS)
	for key in controls.PLACE_KEYS:
		_keys[controls.PLACE_KEYS[key]] = OS.get_keycode_string(key).replace("Minus", "-").replace("Equal", "=").replace("BackSlash", "\\")
	for r in ROWS.size():
		var head := _label(self, HEADS[r], 8, HudTheme.DIM)
		head.position = Vector2(PAD, PAD + r * STEP)
		head.size = Vector2(HEAD, 20)
		head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		head.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		for col in ROWS[r].size():
			var kind: String = ROWS[r][col]
			cells[kind] = _cell(kind, costs[kind].cost, Vector2(PAD + HEAD + 2 + col * STEP, PAD + r * STEP))
	var x := HBoxContainer.new()
	x.alignment = BoxContainer.ALIGNMENT_CENTER
	x.add_child(_cross())
	_label(x, "공병 없음", 8, HudTheme.DANGER)
	band.add_child(x)
	band.add_theme_stylebox_override("panel", HudTheme.box("panel", "PanelContainer", Color(HudTheme.PANEL, 1.0), HudTheme.DANGER))
	band.custom_minimum_size.x = size.x - 4
	add_child(band)
	band.reset_size()
	band.position = Vector2(2, PAD + STEP - 1 - band.size.y / 2)  # 1·2줄 사이 간격 가운데
	info.add_theme_stylebox_override("panel", HudTheme.box("panel", "PanelContainer", Color(HudTheme.PANEL, 1.0), HudTheme.LINE))
	info.custom_minimum_size.x = size.x
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	info.add_child(col)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 3)
	col.add_child(top)
	for l in [_name, _cost, _key]:
		top.add_child(l)
	_key.add_theme_color_override("font_color", HudTheme.ACCENT)
	var why := HBoxContainer.new()
	why.add_theme_constant_override("separation", 2)
	why.add_child(_cross())
	why.add_child(reason)
	for l in [_cost, _body, _state, reason]:
		l.add_theme_font_size_override("font_size", 8)
	_state.add_theme_color_override("font_color", HudTheme.DIM)
	reason.add_theme_color_override("font_color", HudTheme.DANGER)
	for l in [_body, _state, reason]:
		l.clip_text = true  # 폭 130을 넘기지 않는다
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(_body)
	col.add_child(_state)
	col.add_child(why)
	add_child(info)
	for n in [info, band] + info.find_children("*", "Control", true, false) + band.find_children("*", "Control", true, false):
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	visible = battle.state in ["prep", "battle"]
	if not visible:
		return
	_none = battle.live() and battle.engineer_gap([]) == "none"
	band.visible = _none
	for kind in cells:
		var c: Button = cells[kind]
		var cost: int = battle.STRUCTURE_KINDS.get(kind, battle.MERC_KINDS.get(kind)).cost
		c.modulate.a = 0.35 if _lock(kind) != "" else 1.0
		_costs[kind].self_modulate = HudTheme.TEXT if battle.gold >= cost else WARN if battle.gold * 2 >= cost else HudTheme.DANGER
		c.button_pressed = controls.placing == kind
		_flash[kind] = maxf(_flash.get(kind, 0.0) - delta, 0.0)
		var red: bool = _flash[kind] > 0.0
		for i in 3:
			_styles[kind][i].border_color = HudTheme.DANGER if red else [HudTheme.LINE, HudTheme.HOVER, HudTheme.ACCENT][i]
	_show_info()

# 칸 하나: 그림, 오른쪽 위 노란 단축키, 아래 비용. 1단계 테마의 칸 안쪽 여백 대신 자기 크기(20×20)를 따로 준다
func _cell(kind: String, cost: int, at: Vector2) -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 8)
	var st := []
	for line in [HudTheme.LINE, HudTheme.HOVER, HudTheme.ACCENT]:
		var s := StyleBoxFlat.new()
		s.bg_color = HudTheme.CELL
		s.border_color = line
		s.set_border_width_all(1)
		s.set_content_margin_all(0)
		st.append(s)
	_styles[kind] = st
	for i in 4:
		b.add_theme_stylebox_override(["normal", "hover", "pressed", "hover_pressed"][i], st[mini(i, 2)])
	b.position = at
	b.size = Vector2(20, 20)
	b.pressed.connect(func(): _press(kind))
	add_child(b)
	var pic := TextureRect.new()
	pic.texture = icon(kind)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.position = Vector2(2, 2)
	pic.size = Vector2(16, 16)
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(pic)
	var key := _label(b, _keys[kind], 8, HudTheme.ACCENT)
	key.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	key.position = Vector2(8, -2)
	key.size = Vector2(11, 10)
	_costs[kind] = _label(b, str(cost), 8, Color.WHITE)
	_costs[kind].horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_costs[kind].position = Vector2(0, 9)
	_costs[kind].size = Vector2(20, 10)
	return b

func _label(parent: Control, text: String, font: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 3)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

# 시설·용병 그림을 잘라 칸 그림 대역으로 쓴다(S30, ui_research/00_brief.md §7). 빈 여백을 잘라 칸을 채우고, 칸에 맞춰 줄이는 것은 TextureRect가 한다
static func icon(kind: String) -> AtlasTexture:
	var t := AtlasTexture.new()
	if BattleView.FAC.has(kind):  # [열, 그림 맨 윗줄, 맨 아랫줄 + 1]
		var f: Array = BattleView.FAC[kind]
		t.atlas = BattleView.FACILITY
		t.region = Rect2(f[0] * BattleView.FAC_N, f[1], BattleView.FAC_N, f[2] - f[1])
	elif kind == "base":  # 마을 Lv1 거점 망루(S190)
		t.atlas = BattleView.KEEP
		t.region = Rect2(0, 0, 80, 80)
	elif BattleView.ART.has(kind):  # 남쪽을 보는 정지 그림
		var a: Dictionary = BattleView.ART[kind]
		t.atlas = BattleView.UNITS
		t.region = Rect2(0, a.idle, a.c, a.c)
	else:  # 그림이 아직 없는 종류는 빈 그림(맵에는 색 원으로 그린다)
		return t
	var used := t.atlas.get_image().get_region(Rect2i(t.region)).get_used_rect()
	t.region = Rect2(t.region.position + Vector2(used.position), used.size)
	return t

# 도트 그림(S30: 기호는 글꼴이 아니라 그림). rows의 글자마다 colors의 색이고 없는 글자는 투명이다. Nearest로 그린다
static func dots(rows: Array, colors := {"#": Color.WHITE}) -> ImageTexture:
	var img := Image.create(rows[0].length(), rows.size(), false, Image.FORMAT_RGBA8)
	for y in rows.size():
		for x in rows[y].length():
			img.set_pixel(x, y, colors.get(rows[y][x], Color.TRANSPARENT))
	return ImageTexture.create_from_image(img)

# 빨간 ✕. 5×5 도트를 Nearest로 그린다
static func _cross() -> TextureRect:
	var r := TextureRect.new()
	r.texture = dots(CROSS)
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.modulate = HudTheme.DANGER
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return r

# 칸을 놓을 수 없는 이유(I132, I128): 마을 레벨(S99), 전투 단계의 공병, 그 용병의 시설이 없음(준비 단계 S50, 전투 단계 S81). 놓을 수 있으면 ""
func _lock(kind: String) -> String:
	if kind in battle.STRUCTURE_KINDS:
		var need: int = battle.STRUCTURE_KINDS[kind].village_level
		if need > battle.village_level:
			return "마을 Lv%d 필요" % need
		return "놀고 있는 공병 없음" if _none else ""
	if battle.can_buy(kind):
		return ""
	for s in battle.STRUCTURE_KINDS:  # 그 용병을 파는 시설
		if kind in battle.STRUCTURE_KINDS[s].produces:
			return "%s 없음" % hud.NAMES[s]
	return ""

# 칸을 누름: 놓을 수 있으면 놓기 모드를 켜고 끈다. 전투 단계 용병 칸은 용병 키와 같다(S81).
# 못 놓으면 테두리를 번쩍이고, 준비 단계의 마을 레벨 잠금이면 거점을 고른다(해결 길, I132)
func _press(kind: String) -> void:
	var why := _lock(kind)
	if battle.live() and kind in battle.MERC_KINDS:
		controls.merc_key(kind, Input.is_key_pressed(KEY_SHIFT))
	elif why == "":
		controls.placing = "" if controls.placing == kind else kind
		return
	if why == "":
		return
	_flash[kind] = FLASH
	if why.begins_with("마을 Lv") and battle.state == "prep":
		controls.placing = ""
		controls.pick_base()

# 정보 칸 줄: [이름, 비용, [키], 한 줄 설명, 상태·해결 길, 이유]
func _lines(kind: String) -> Array:
	var d = battle.STRUCTURE_KINDS.get(kind, battle.MERC_KINDS.get(kind))
	var why := _lock(kind)
	var path := ""
	if why.begins_with("마을 Lv"):
		var up: int = battle.VILLAGE_UP[battle.village_level - 1]
		path = "거점에서 Lv%d로 올린다(%d)" % [battle.village_level + 1, up] if battle.state == "prep" else "준비 단계에 거점에서 올린다(%d)" % up
	elif why == "놀고 있는 공병 없음":
		path = "거점에서 공병을 산다" if battle.base in battle.sellers("engineer") else "작업장에서 공병을 산다"
	if why == "" and battle.gold < d.cost:
		why = "골드 %d 모자람" % (d.cost - battle.gold)
	var about := "체력 %d · 적의 길을 막는다" % d.hp
	if kind in battle.MERC_KINDS:
		for s in battle.STRUCTURE_KINDS:
			if kind in battle.STRUCTURE_KINDS[s].produces:
				about = ("거점·%s에서 산다 · 체력 %d" if battle.base in battle.sellers(kind) else "%s에서 산다 · 체력 %d") % [hud.NAMES[s], d.hp]
	elif not d.produces.is_empty():
		about = "마을 · %s를 판다" % ", ".join(d.produces.map(func(k): return hud.NAMES[k]))
	elif d.tax > 0:
		about = "마을 · 준비 단계마다 세금 +%d" % d.tax
	elif d.heal > 0.0:
		about = "마을 · 지은 교회를 눌러 영웅 치료"
	elif d.seats > 0:
		about = "마을 · 대피령 때 주민 %d명" % d.seats
	elif d.range > 0.0:
		about = "사거리 %s칸 · 공격력 %s" % [hud._num(d.range), hud._num(d.damage)] + (" · 범위 피해" if d.splash > 0.0 else "")
	return [hud.NAMES[kind], "%d골드" % d.cost, "[%s]" % _keys[kind], about, path, why]

# 고른 것(구조물·성곽·거점)의 이름과 체력. 없으면 []. 고른 용병(판매 후보 포함)은 선택 패널이 보인다(S206)
func _picked() -> Array:
	var all: Array = controls.selling + controls.picked + ([controls.fort] if controls.fort else []) + ([battle.base] if controls.village else [])
	all = all.filter(func(t): return t.get("is_hero") == null)
	for t in all:
		if t.alive or t == controls.fort:  # 잔해(I89)는 성곽 칸으로 남는다
			return [THINGS.get(t.kind, hud.NAMES.get(t.kind, t.kind)), "", "", hud.info_lines[0], "체력 %d/%d" % [ceili(t.hp), ceili(t.max_hp)], hud.info_lines[1]]  # 팝업 버튼의 설명·이유(I124, I128, I132, I140)
	return []

# 정보 칸: 칸 호버 > 놓기 중 > 시설 없는 용병 키(S81) > 고른 것. 빈 줄은 숨기고 위로만 자란다. 카메라가 맨 아래면 격자 왼쪽 맵 밖 띠에 아래로 붙인다(S186)
func _show_info() -> void:
	var kind = cells.find_key(get_viewport().gui_get_hovered_control())
	var v: Array = _lines(kind) if kind else _lines(controls.placing) if controls.placing != "" else _lines(controls.missing) if controls.missing != "" else _picked()
	info.visible = not v.is_empty()
	if v.is_empty():
		return
	for i in 4:
		var l: Label = [_name, _cost, _key, _body][i]
		l.text = v[i]
	_state.text = v[4]
	reason.text = v[5]
	for l in [_cost, _key, _body, _state]:
		l.visible = l.text != ""
	reason.get_parent().visible = reason.text != ""
	reason.visible = reason.text != ""
	info.reset_size()
	var box := info_box()
	info.global_position = Vector2(box.position.x, box.end.y - info.size.y)

# 정보 칸이 4줄까지 자랐을 때의 사각형. 카메라가 맨 아래면 격자 왼쪽 맵 밖 띠, 선택 패널이 보이면 그 왼쪽(S186). 맵 위 팝업이 피한다(I137)
func info_box() -> Rect2:
	var cam: Camera2D = hud.map.get_camera_2d()
	var low: bool = cam != null and cam.at_bottom()
	return Rect2(Vector2(178 if hud.select.visible else 376, 306) if low else Vector2(510, 234), Vector2(130, 54))
