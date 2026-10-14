extends CanvasLayer
# 골드·다음 세금(I75)·웨이브·단계를 보이고, 놓기 모드·«전투 시작»(I13) 버튼과 판이 끝난 뒤의 결과·«재시작»(S29)을 둔다.
# 판매 후보가 있으면 그 옆에 판매 버튼을 띄운다(S70, I58). 전투 단계에 생산 시설을 고르면 그 옆에 파는 용병마다 구매 버튼을 띄운다(S81, I61, I71).
# 고른 구조물에 따라 같은 자리에 철거(S74)·이어 짓기·취소(전투 단계)와 완성(준비 단계) 버튼도 띄운다(S83). 대포면 옮기기(S91)도 띄운다.
# 성곽 칸을 고르면 같은 자리에 성문 열기·닫기(S85)와 업그레이드(S86) 버튼을 띄운다. 거점을 고르면 마을 레벨 올리기(S100) 버튼을 띄운다.

const NAMES := {"wall": "방벽", "tower": "타워", "soldier": "용병", "barracks": "병영", "engineer": "공병", "workshop": "작업장", "archer": "궁수", "cannon": "대포", "archery": "사격장", "house": "집"}
const STATES := {"prep": "준비", "battle": "전투", "won": "승리", "lost": "패배"}

var battle
var controls
var _info := Label.new()
var _hint := Label.new()
var _start: Button
var _popup := HBoxContainer.new()  # 판매·완성·구매·철거·이어 짓기·취소 버튼. 클릭하거나 드래그를 놓은 지점 옆에 뜬다
var _sell: Button
var _finish: Button
var _buy := {}  # 용병 kind → 구매 버튼
var _demolish: Button
var _move: Button
var _resume: Button
var _cancel: Button
var _gate: Button
var _upgrade: Button
var _village: Button
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
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)  # 화면 너비에 맞춰 버튼 줄이 줄바꿈된다(S105)
	root.add_child(bar)
	var col := VBoxContainer.new()
	bar.add_child(col)
	var row := HFlowContainer.new()
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
	root.add_child(_popup)
	_sell = _button(_popup, "", _sell_now)
	_finish = _button(_popup, "완성", func(): _apply(battle.finish, battle.unfinished(controls.selling)))
	for kind in battle.MERC_KINDS:
		_buy[kind] = _button(_popup, "", func(): battle.recruit(controls.facility, kind))
	_demolish = _button(_popup, "철거", func(): _apply(func(s): battle.demolish([s]), controls.picked))
	_move = _button(_popup, "옮기기", _start_move)
	_resume = _button(_popup, "이어 짓기", func(): _apply(battle.resume, battle.unfinished(controls.picked)))
	_cancel = _button(_popup, "취소", func(): _apply(battle.cancel, battle.unfinished(controls.picked)))
	_gate = _button(_popup, "", func(): battle.set_gate(controls.fort, not controls.fort.open))
	_upgrade = _button(_popup, "", func(): battle.upgrade(controls.fort))
	_village = _button(_popup, "", func(): battle.raise_village())

func _process(_delta: float) -> void:
	var prep: bool = battle.state == "prep"
	var n: int = battle.waves.size()
	_info.text = "골드 %d (세금 +%d) · 웨이브 %d/%d · %s · 마을 Lv%d" % [battle.gold, battle.tax(), mini(battle.wave_index + 1, n), n, STATES[battle.state], battle.village_level]
	for kind in _place:
		_place[kind].disabled = not (prep or (battle.state == "battle" and kind in battle.STRUCTURE_KINDS))
		# 마을 레벨이 모자란 시설(S99)과, 준비 단계에 시설이 없어 못 사는 용병(S50)
		if kind in battle.STRUCTURE_KINDS:
			_place[kind].disabled = _place[kind].disabled or battle.STRUCTURE_KINDS[kind].village_level > battle.village_level
		elif prep:
			_place[kind].disabled = _place[kind].disabled or not battle.can_buy(kind)
		_place[kind].button_pressed = controls.placing == kind
	_start.disabled = not prep
	_hint.visible = controls.placing != "" or controls.moving != null
	_hint.text = "%s 놓기: 좌클릭 · 끝내기: 우클릭·ESC" % NAMES.get(controls.placing, "")
	if controls.moving:
		_hint.text = "대포 옮길 칸: 좌클릭 · 끝내기: 우클릭·ESC"
	_result.visible = battle.state in ["won", "lost"]
	_result_label.text = "승리!" if battle.state == "won" else "패배"
	if not prep or controls.placing != "":  # 전투가 시작되거나 놓기 모드에 들어가면 판매 팝업을 닫는다(I58)
		controls.selling = []
	_sell.visible = not controls.selling.is_empty()
	_sell.text = "판매 +%d골드" % controls.selling.reduce(func(n, t): return n + battle.refund(t), 0)
	_finish.visible = not battle.unfinished(controls.selling).is_empty()
	if controls.facility and not controls.facility.alive:  # 파괴되거나 팔린 시설
		controls.facility = null
	for kind in _buy:
		_buy[kind].visible = battle.state == "battle" and controls.facility != null and kind in controls.facility.produces
		_buy[kind].text = "%s 구매 %d골드" % [NAMES[kind], battle.MERC_KINDS[kind].cost]
	if battle.state != "battle" or controls.placing != "":
		controls.picked = []
	controls.picked = controls.picked.filter(func(s): return s.alive)  # 부서지거나 허물거나 취소된 것은 뺀다
	var todo: Array = battle.unfinished(controls.picked)
	_demolish.visible = controls.picked.any(battle.can_demolish)
	_move.visible = _cannon() != null
	_resume.visible = todo.any(func(s): return s.worker == null)
	_cancel.visible = not todo.is_empty()
	if controls.placing != "" or (controls.fort and not controls.fort.alive):  # 놓기 모드거나 부서진 성곽 칸
		controls.fort = null
	var k = controls.fort
	_gate.visible = k != null and k.kind == "gate"
	if _gate.visible:
		_gate.text = "닫기" if k.open else "열기"
	# 공병이 올리는 중이면 숨긴다. 그만둔 업그레이드는 «계속»으로 골드 없이 이어 올린다(I68)
	_upgrade.visible = k != null and battle.state in ["prep", "battle"] and k.level < battle.UPGRADE_MAX and k.worker == null
	if _upgrade.visible:
		_upgrade.text = "업그레이드 계속" if k.lift >= 0.0 else "업그레이드 %d골드" % battle.upgrade_cost(k)
	if controls.placing != "":
		controls.village = false
	_village.visible = controls.village and prep and battle.village_level <= battle.VILLAGE_UP.size()
	if _village.visible:
		_village.text = "마을 레벨 %d로 올리기 %d골드" % [battle.village_level + 1, battle.VILLAGE_UP[battle.village_level - 1]]
	_popup.reset_size()
	# 맵 px → 화면 좌표. 전투 화면(BattleView)이 원점에 있어 카메라 변환만 곱한다
	_popup.position = get_viewport().get_canvas_transform() * controls.sell_at + Vector2(6, 6)

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
	controls.picked = []
	controls.fort = null
	controls.village = false

# 고른 구조물마다 f를 부르고 팝업을 닫는다
func _apply(f: Callable, things: Array) -> void:
	for t in things:
		f.call(t)
	controls.selling = []
	controls.picked = []

# 고른 구조물 가운데 옮길 수 있는 첫 대포(S44)
func _cannon():
	for s in controls.picked:
		if s.kind == "cannon" and battle.can_demolish(s):
			return s
	return null

func _start_move() -> void:
	controls.moving = _cannon()
	controls.picked = []

# 팔린 용병은 고른 상태에서도 뺀다
func _sell_now() -> void:
	battle.sell(controls.selling)
	controls.selling = []
	controls.selected = controls.selected.filter(func(u): return u.alive)
