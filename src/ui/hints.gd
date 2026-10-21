extends Panel
# 처음 하는 사람 힌트(S191): 준비 단계에 [4,300,200,40]에 끝나지 않은 첫 힌트를 두 줄 + «건너뛰기»로 보인다. 힌트 설정(S184)을 끄면 숨는다.
# 끝날 조건은 숨어 있을 때도 지난 프레임과 비교해 찾고, 끝낸 힌트는 설정 파일에 남긴다(I166). HUD가 매 프레임 step을 부른다

const HudTheme := preload("res://src/ui/hud_theme.gd")
const Settings := preload("res://src/settings.gd")
const HINTS := [  # [이름, 글](S191 임시값). 이 차례에서 끝나지 않은 첫 힌트를 보인다
	["build", "오른쪽 아래 칸(숫자 키)을 고르고\n맵을 눌러 짓는다"],
	["start", "준비가 끝나면 위 오른쪽\n▶ 전투 시작 (Enter)"],
	["move", "영웅을 누르고(F1)\n우클릭한 칸으로 보낸다"],
	["buy", "전투 중에도 3·5·7로 용병을 산다\n짓기는 공병(5)이 가서 한다"],
	["keep", "거점을 누르면 마을 레벨을 올린다\n(새 시설이 열린다)"],
]

var battle
var controls
var text := Label.new()
var _built := -1  # 지난 프레임의 라운드 집계(I119) built. -1이면 아직 보지 않았다
var _bought := -1  # 지난 프레임의 라운드 집계 merc_bought

func _init(b, c) -> void:
	battle = b
	controls = c
	controls.hero_sent.connect(_finish.bind("move"))

# 크기는 HUD 테마를 받은 뒤에 정한다. 그 전에는 기본 글꼴 크기로 최소 크기가 잡혀 버튼이 칸 밖으로 커진다
func _ready() -> void:
	position = Vector2(4, 300)
	size = Vector2(200, 40)
	add_theme_stylebox_override("panel", HudTheme.box("panel", "PanelContainer", Color(HudTheme.PANEL, 1.0), HudTheme.LINE))
	text.position = Vector2(4, 0)
	text.size = Vector2(146, 40)
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 9)
	add_child(text)
	var skip := Button.new()
	skip.text = "건너뛰기"
	skip.theme_type_variation = "BarCell"
	skip.focus_mode = Control.FOCUS_NONE
	skip.add_theme_font_size_override("font_size", 8)
	add_child(skip)
	skip.position = Vector2(150, 24)
	skip.size = Vector2(46, 13)
	skip.pressed.connect(func(): _finish(_current()))

func step() -> void:
	var t: Dictionary = battle.tally
	if _built >= 0 and t.built > _built:
		_finish("build")
	if battle.state == "battle":
		_finish("start")
		if _bought >= 0 and t.merc_bought > _bought:
			_finish("buy")
	if controls.village:
		_finish("keep")
	_built = t.built
	_bought = t.merc_bought
	var now := _current()
	visible = Settings.hints and battle.state == "prep" and now != ""
	for h in HINTS:
		if h[0] == now:
			text.text = h[1]

# 차례에서 끝나지 않은 첫 힌트 이름. 모두 끝냈으면 ""
func _current() -> String:
	for h in HINTS:
		if not h[0] in Settings.hints_done:
			return h[0]
	return ""

func _finish(name: String) -> void:
	if name == "" or name in Settings.hints_done:
		return
	Settings.hints_done.append(name)
	Settings.save_file()
