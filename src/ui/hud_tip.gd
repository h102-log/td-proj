extends PanelContainer
# 툴팁(S187, I162): add(조작, 글 함수)로 걸어 둔 조작에 커서가 0.2초 머물면 그 조작 바로 아래에 뜬다.
# 떠 있거나 사라진 지 0.25초 안에 다른 조작으로 옮기면 바로 뜨고, 커서가 조작이나 툴팁 위에 있는 동안 남는다.
# 글 함수는 [이름, 키, 비용, 설명, 이유]를 돌려준다. 빈 글인 줄은 숨는다. 떠 있는 동안 매 프레임 다시 부른다
# 시간은 _process의 delta로만 센다(평가가 delta를 넣어 돌린다)

const HudTheme := preload("res://src/ui/hud_theme.gd")
const DELAY := 0.2
const QUICK := 0.25
const WIDTH := 160

var reason := Label.new()  # 빨간 이유 줄
var _lines := {}  # 조작 → 글 함수
var _under := {}  # 조작 → 툴팁을 그 아래에 붙일 Control(맵 위 팝업 버튼은 팝업 전체). 없으면 조작 자신
var _name := Label.new()
var _key := Label.new()
var _cost := Label.new()
var _body := Label.new()
var _target: Control = null  # 툴팁이 붙은 조작
var _wait: Control = null  # 커서가 머무는 조작
var _waited := 0.0
var _clock := 0.0
var _hid_at := -INF
var _mouse := Vector2(-1, -1)
var _inner := 0.0  # 줄바꿈 글의 폭: WIDTH − 패널 안쪽 여백

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	var panel := HudTheme.box("panel", "PanelContainer", Color(HudTheme.PANEL, 1.0), HudTheme.LINE)  # 불투명. 밑의 버튼 글자가 비치지 않게
	add_theme_stylebox_override("panel", panel)
	_inner = WIDTH - panel.get_margin(SIDE_LEFT) - panel.get_margin(SIDE_RIGHT)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 3)
	col.add_child(head)
	for l in [_name, _key, _cost]:
		head.add_child(l)
	_key.add_theme_color_override("font_color", HudTheme.ACCENT)
	for l in [_body, reason]:
		l.add_theme_font_size_override("font_size", 8)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = _inner
		col.add_child(l)
	reason.add_theme_color_override("font_color", HudTheme.DANGER)
	for n in find_children("*", "Control", true, false):
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE

# 툴팁이 root 안의 조작에 붙어 떠 있다. 위 띠 조작의 툴팁이 떠 있으면 안내 칩이 숨는다(S147)
func shows_in(root: Control) -> bool:
	return visible and _target != null and root.is_ancestor_of(_target)

func add(c: Control, lines: Callable, under: Control = null) -> void:
	_lines[c] = lines
	if under:
		_under[c] = under

# 커서 자리는 들어온 입력으로 잰다. 평가가 넣는 입력도 같은 길로 온다
func _input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		_mouse = e.position

func _process(delta: float) -> void:
	_clock += delta
	var hov := get_viewport().gui_get_hovered_control()
	var c: Control = hov if _lines.has(hov) else null
	if _target and _target.is_visible_in_tree() and (c == _target or get_global_rect().has_point(_mouse)):  # 툴팁 밑의 다른 조작보다 툴팁 위가 먼저다
		_show(_target)
		return
	if c == null:
		if _target:
			_hid_at = _clock - delta  # 커서는 이 프레임 앞에서 떠났다
		_target = null
		_wait = null
		visible = false
		return
	if c != _wait:
		_wait = c
		_waited = 0.0
	_waited += delta
	if _target or _clock - _hid_at <= QUICK or _waited >= DELAY:
		_show(c)

# 글을 채우고 조작 바로 아래에 둔다. 아래로 넘치면 조작 위로, 옆으로 넘치면 화면 안으로
func _show(c: Control) -> void:
	_target = c
	var v: Array = _lines[c].call()
	_name.text = v[0]
	_key.text = "(%s)" % v[1] if v[1] != "" else ""
	_cost.text = v[2]
	_body.text = v[3]
	reason.text = v[4]
	for l in [_key, _cost, _body, reason]:
		l.visible = l.text != ""
	for l in [_body, reason]:  # 줄바꿈 글은 폭이 정해져야 높이를 잰다. 안 그러면 폭 0으로 재서 한 글자마다 줄이 바뀐다
		l.size.x = _inner
	visible = true
	reset_size()
	var r: Rect2 = _under.get(c, c).get_global_rect()
	var screen := get_viewport().get_visible_rect().size
	var y := r.end.y if r.end.y + size.y <= screen.y else r.position.y - size.y
	global_position = Vector2(clampf(r.position.x, 0.0, screen.x - size.x), y)
