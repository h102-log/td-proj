extends Control
# 토스트(I163): 위 오른쪽 [436,30,200,16]·[436,48,200,16]에 최대 둘. 하나는 4초(push에서 정하면 그 초) 보인다.
# 새 토스트는 앞 토스트가 뜬 지 3.5초가 지나야 뜨고 그때까지 줄을 선다. 같은 글이 보이거나 줄 서 있으면 «(2)»처럼 횟수만 올린다.
# 툴팁(I162)이 떠 있으면 시간을 세지 않는다. 시간은 _process의 delta로만 센다(평가가 delta를 넣어 돌린다)

const HudTheme := preload("res://src/ui/hud_theme.gd")
const LIFE := 4.0
const GAP := 3.5

var tip: Control  # 툴팁 패널(I162)
var _wait := []  # 줄 선 토스트 {text, n, left}
var _shown := []  # 보이는 토스트. 앞이 윗줄이다
var _since := INF  # 마지막 토스트가 뜬 뒤 흐른 초
var _rows := []  # 토스트 칸 둘(Panel)

func _ready() -> void:
	position = Vector2(436, 30)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in 2:
		var p := Panel.new()
		p.add_theme_stylebox_override("panel", HudTheme.box("panel", "PanelContainer", Color(HudTheme.PANEL, 1.0), HudTheme.LINE))
		p.position = Vector2(0, 18 * i)
		p.size = Vector2(200, 16)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.visible = false
		var l := Label.new()
		l.add_theme_font_size_override("font_size", 8)
		l.position = Vector2(4, 0)
		l.size = Vector2(192, 16)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.clip_text = true
		p.add_child(l)
		add_child(p)
		_rows.append(p)

func push(text: String, secs := LIFE) -> void:
	var same: Array = (_shown + _wait).filter(func(t): return t.text == text)
	if same.is_empty():
		_wait.append({"text": text, "n": 1, "left": secs})
	else:
		same[0].n += 1
	_pull()

func _process(delta: float) -> void:
	if tip and tip.visible:
		return
	_since += delta
	for t in _shown:
		t.left -= delta
	_shown = _shown.filter(func(t): return t.left > 0.0)
	_pull()

# 띄울 수 있으면 줄 선 토스트를 띄우고 칸 글을 다시 쓴다
func _pull() -> void:
	if not _wait.is_empty() and _shown.size() < 2 and _since >= GAP:
		_shown.append(_wait.pop_front())
		_since = 0.0
	for i in 2:
		_rows[i].visible = i < _shown.size()
		if _rows[i].visible:
			var t: Dictionary = _shown[i]
			_rows[i].get_child(0).text = t.text + (" (%d)" % t.n if t.n > 1 else "")
