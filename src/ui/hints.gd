extends Panel
# 처음 하는 사람 힌트(S191)이자 튜토리얼(S192): 1라운드 k웨이브에 k웨이브 단계 가운데 지금 판 단계의 끝나지 않은 첫 단계를
# [4,300,200,40]에 두 줄 + «건너뛰기»로 보이고, 오른쪽 위에 그 웨이브의 축 이름을 둔다. 힌트 설정(S184)을 끄면 숨는다.
# 끝날 조건은 숨어 있을 때도 지난 프레임과 비교해 찾고, 끝낸 힌트는 설정 파일에 남긴다(I166). HUD가 매 프레임 step을 부른다

const HudTheme := preload("res://src/ui/hud_theme.gd")
const Settings := preload("res://src/settings.gd")
const AXES := ["시설", "용병", "영웅"]  # 1라운드 1·2·3웨이브가 소개하는 축(S192)
const HINTS := [  # [이름, 1라운드 웨이브, 판 단계, 글](S192 임시값)
	["build", 1, "prep", "오른쪽 아래 칸(숫자 키)을 고르고\n맵을 누르면 공병이 가서 짓는다"],
	["keep", 1, "prep", "거점을 누르면 마을 레벨을 올린다\n(새 시설이 열린다)"],
	["start", 1, "prep", "준비가 끝나면 위 오른쪽\n▶ 전투 시작 (Enter)"],
	["merc", 2, "prep", "병영(4)을 짓고 3으로 용병을 산다\n용병은 적을 몸으로 붙잡는다"],
	["buy", 2, "battle", "전투 중에도 3·5·7로 용병을 산다\n짓기는 공병(5)이 가서 한다"],
	["move", 3, "prep", "영웅을 누르고(F1)\n우클릭한 칸으로 보낸다"],
	["skill", 3, "battle", "Q로 영웅 스킬을 쓴다\n조준하는 칸은 맵을 눌러 쓴다"],
]

var battle
var controls
var text := Label.new()
var axis := Label.new()  # 축 이름(S192)
var _built := -1  # 지난 프레임의 라운드 집계(I119) built. -1이면 아직 보지 않았다
var _bought := -1  # 지난 프레임의 라운드 집계 merc_bought
var _used := -1  # 지난 프레임의 출전 영웅 스킬 수(_skills)

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
	axis.position = Vector2(150, 2)
	axis.size = Vector2(46, 20)
	axis.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	axis.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	axis.add_theme_font_size_override("font_size", 8)
	axis.add_theme_color_override("font_color", HudTheme.DIM)
	add_child(axis)
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
		_finish("buy" if battle.state == "battle" else "merc")
	if controls.village:
		_finish("keep")
	var used := _skills()
	if _used >= 0 and used > _used:
		_finish("skill")
	_built = t.built
	_bought = t.merc_bought
	_used = used
	var now := _current()
	visible = Settings.hints and now != ""
	for h in HINTS:
		if h[0] == now:
			text.text = h[3]
			axis.text = AXES[h[1] - 1]

# 1라운드 지금 웨이브의 단계 가운데 지금 판 단계의 끝나지 않은 첫 단계 이름(S192). 앞 웨이브에 남은 단계는 넘어오지 않는다. 없으면 ""
func _current() -> String:
	if battle.round_index > 0:
		return ""
	for h in HINTS:
		if h[1] == battle.wave_index + 1 and h[2] == battle.state and not h[0] in Settings.hints_done:
			return h[0]
	return ""

# 출전 영웅이 쓴 스킬 수. 켜 둔 토글 칸도 하나로 센다(S192)
func _skills() -> int:
	return battle.heroes.reduce(func(s, h): return s + h.skill_uses + int(h.toggle), 0)

func _finish(name: String) -> void:
	if name == "" or name in Settings.hints_done:
		return
	Settings.hints_done.append(name)
	Settings.save_file()
