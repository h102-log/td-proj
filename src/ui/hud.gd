extends CanvasLayer
# 골드·웨이브·단계를 보이고, 놓기 모드·«전투 시작»(I13) 버튼과 판이 끝난 뒤의 결과·«재시작»(S29)을 둔다.
# 판매 후보가 있으면 그 옆에 판매 버튼을 띄운다(S70, I58). 전투 단계에 생산 시설을 고르면 그 옆에 구매 버튼을 띄운다(S81, I61).

const NAMES := {"wall": "방벽", "tower": "타워", "soldier": "용병", "barracks": "병영"}
const STATES := {"prep": "준비", "battle": "전투", "won": "승리", "lost": "패배"}

var battle
var controls
var _info := Label.new()
var _hint := Label.new()
var _start: Button
var _sell: Button
var _buy: Button
var _place := {}  # kind → 버튼
var _result := PanelContainer.new()
var _result_label := Label.new()

func _init(b, c) -> void:
	battle = b
	controls = c

func _ready() -> void:
	var root := Control.new()  # 글자 크기를 한 번에 주는 틀. 클릭은 아래 맵으로 흘린다
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = Theme.new()
	root.theme.default_font_size = 10
	add_child(root)
	var bar := PanelContainer.new()
	root.add_child(bar)
	var col := VBoxContainer.new()
	bar.add_child(col)
	var row := HBoxContainer.new()
	col.add_child(row)
	row.add_child(_info)
	var costs: Dictionary = battle.STRUCTURE_KINDS.merged(battle.MERC_KINDS)
	for key in controls.PLACE_KEYS:
		var kind: String = controls.PLACE_KEYS[key]
		_place[kind] = _button(row, "%s %d (%s)" % [NAMES[kind], costs[kind].cost, OS.get_keycode_string(key)], func(): controls.placing = kind)
		_place[kind].toggle_mode = true
	_start = _button(row, "전투 시작 (Enter)", _start_battle)
	col.add_child(_hint)
	_result.set_anchors_preset(Control.PRESET_CENTER)
	_result.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_result.grow_vertical = Control.GROW_DIRECTION_BOTH
	root.add_child(_result)
	var box := VBoxContainer.new()
	_result.add_child(box)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_result_label)
	_button(box, "재시작", _restart)
	_sell = _button(root, "", _sell_now)
	_buy = _button(root, "", func(): battle.recruit(controls.facility))

func _process(_delta: float) -> void:
	var prep: bool = battle.state == "prep"
	var n: int = battle.waves.size()
	_info.text = "골드 %d · 웨이브 %d/%d · %s" % [battle.gold, mini(battle.wave_index + 1, n), n, STATES[battle.state]]
	for kind in _place:
		_place[kind].disabled = not prep
		_place[kind].button_pressed = controls.placing == kind
	_start.disabled = not prep
	_hint.visible = prep and controls.placing != ""
	_hint.text = "%s 놓기: 좌클릭 · 끝내기: 우클릭·ESC" % NAMES.get(controls.placing, "")
	_result.visible = battle.state in ["won", "lost"]
	_result_label.text = "승리!" if battle.state == "won" else "패배"
	if not prep or controls.placing != "":  # 전투가 시작되거나 놓기 모드에 들어가면 판매 팝업을 닫는다(I58)
		controls.selling = []
	_sell.visible = not controls.selling.is_empty()
	_sell.text = "판매 +%d골드" % controls.selling.reduce(func(n, t): return n + battle.refund(t), 0)
	_sell.reset_size()
	# 맵 px → 화면 좌표. 전투 화면(BattleView)이 원점에 있어 카메라 변환만 곱한다
	_sell.position = get_viewport().get_canvas_transform() * controls.sell_at + Vector2(6, 6)
	if controls.facility and not controls.facility.alive:  # 파괴되거나 팔린 시설
		controls.facility = null
	_buy.visible = battle.state == "battle" and controls.facility != null
	if _buy.visible:
		_buy.text = "%s 구매 %d골드" % [NAMES[controls.facility.produces], battle.MERC_KINDS[controls.facility.produces].cost]
	_buy.reset_size()
	_buy.position = _sell.position

# 키보드 포커스를 받지 않는다. 받으면 Enter·Space가 맵 대신 마지막에 누른 버튼을 누른다
func _button(parent: Control, text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(on_press)
	parent.add_child(b)
	return b

func _start_battle() -> void:
	controls.placing = ""
	battle.start_battle()

# 고른 유닛·놓기 모드도 비운다. 재시작 뒤의 영웅은 새 객체다
func _restart() -> void:
	battle.restart()
	controls.selected = []
	controls.selling = []
	controls.placing = ""
	controls.facility = null

# 팔린 용병은 고른 상태에서도 뺀다
func _sell_now() -> void:
	battle.sell(controls.selling)
	controls.selling = []
	controls.selected = controls.selected.filter(func(u): return u.alive)
