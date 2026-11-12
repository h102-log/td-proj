extends Panel
# 처음 하는 사람 힌트(S191)이자 튜토리얼(S192): 1라운드 k웨이브에 k웨이브 단계 가운데 지금 판 단계의 끝나지 않은 첫 단계를
# [68,300,200,40](미니맵 S209 오른쪽)에 두 줄 + «건너뛰기»로 보이고, 오른쪽 위에 그 웨이브의 축 이름을 둔다. 힌트 설정(S184)을 끄면 숨는다.
# 끝날 조건은 숨어 있을 때도 지난 프레임과 비교해 찾고, 끝낸 힌트는 설정 파일에 남긴다(I166). HUD가 매 프레임 step을 부른다.
# 원정 동안에는 라운드와 상관없이 첫 원정 힌트를 보이고(S332), 그것이 끝났으면 그 층의 힌트를 보인다(S342 ⑬)

const HudTheme := preload("res://src/ui/hud_theme.gd")
const Settings := preload("res://src/settings.gd")
const AXES := ["시설", "용병", "영웅"]  # 1라운드 1·2·3웨이브가 소개하는 축(S192)
const AT := Vector2(68, 300)  # 힌트 칸의 자리(S191)
const RAID_AT := Vector2(4, 29)  # 원정 동안의 자리(S332 2026-11-11 변경): 위 띠 바로 아래 왼쪽. 보스방 바닥을 가리지 않는다
const HINTS := [  # [이름, 1라운드 웨이브, 판 단계, 글](S192 임시값)
	["build", 1, "prep", "오른쪽 아래 칸(숫자 키)을 고르고\n맵을 누르면 공병이 가서 짓는다"],
	["keep", 1, "prep", "거점을 누르면 마을 레벨을 올린다\n(새 시설이 열린다)"],
	["start", 1, "prep", "준비가 끝나면 위 오른쪽\n▶ 전투 시작을 누른다"],
	["merc", 2, "prep", "병영(4)을 짓고 용병 칸으로 산다\n용병은 적을 몸으로 붙잡는다"],
	["buy", 2, "battle", "전투 중에도 용병 칸·5·7로 산다\n짓기는 공병(5)이 가서 한다"],
	["move", 3, "prep", "영웅을 누르고(1)\n우클릭한 칸으로 보낸다"],
	["skill", 3, "battle", "Q로 영웅 스킬을 쓴다\n조준하는 칸은 맵을 눌러 쓴다"],
	["raid", 0, "raid", "보스는 그로기 때만 크게 맞는다\n빨강은 피하고 금색에 모인다"],  # 첫 원정 힌트(S332): 웨이브 0은 라운드·웨이브와 상관없이 원정 동안이다(I277 ④)
	["raid2", 0, "raid", "벽 앞에서 돌진을 피하면 박힌다\n붙잡힌 동료는 때려서 구한다"],  # 2층 힌트(S337 ⑧)
	["raid3", 0, "raid", "포탄 원을 기계 옆에서 굳힌다\n대장 돌진은 잔해나 벽에 박는다"],  # 3층 힌트(S342 ⑬): 이름 끝의 수가 층 번호다(I284 ③)
	["raid4", 0, "raid", "급강하를 피하면 땅에 처박힌다\n떨어진 뒤엔 옆구리에 선다"],  # 4층 힌트(S352 ⑬)
	["raid5", 0, "raid", "바위·착지를 형제에게 맞힌다\n하나가 쓰러지면 남은 쪽이 성난다"],  # 5층 힌트(S354 ⑬): 두 몸 가운데 어느 몸이든 그로기가 되면 끝난다(I293 ①)
]

var battle
var controls
var text := Label.new()
var axis := Label.new()  # 축 이름(S192)
var _built := -1  # 지난 프레임의 라운드 집계(I119) built. -1이면 아직 보지 않았다
var _bought := -1  # 지난 프레임의 라운드 집계 merc_bought
var _used := -1  # 지난 프레임의 출전 영웅 스킬 수(_skills)
var _groggy := false  # 지난 프레임에 원정 보스 몸이 그로기였나(I284 ③)

func _init(b, c) -> void:
	battle = b
	controls = c
	controls.hero_sent.connect(_finish.bind("move"))

# 크기는 HUD 테마를 받은 뒤에 정한다. 그 전에는 기본 글꼴 크기로 최소 크기가 잡혀 버튼이 칸 밖으로 커진다
func _ready() -> void:
	position = AT
	size = Vector2(200, 40)
	add_theme_stylebox_override("panel", HudTheme.framed(HudTheme.box("panel", "PanelContainer", Color(HudTheme.PANEL, 1.0), HudTheme.LINE)))
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
	var groggy: bool = battle.state == "raid" and battle.enemies.any(func(e): return battle.effect(e, "groggy") != null)
	if groggy and not _groggy:  # 원정 힌트(S332·S342 ⑬)는 보스 몸이 그로기가 된 프레임에 그때 보일 것 하나가 끝난다(I284 ③)
		_finish(_current())
	_groggy = groggy
	var used := _skills()
	if _used >= 0 and used > _used:
		_finish("skill")
	_built = t.built
	_bought = t.merc_bought
	_used = used
	var now := _current()
	position = RAID_AT if battle.state == "raid" else AT  # 원정 동안은 왼쪽 위다(I286 ③)
	visible = Settings.hints and now != ""
	for h in HINTS:
		if h[0] == now:
			text.text = h[3]
			axis.text = AXES[h[1] - 1] if h[1] > 0 else "원정"

# 1라운드 지금 웨이브의 단계 가운데 지금 판 단계의 끝나지 않은 첫 단계 이름(S192). 앞 웨이브에 남은 단계는 넘어오지 않는다. 없으면 ""
func _current() -> String:
	if battle.state == "raid":  # 첫 원정 힌트(S332), 그다음 그 층의 힌트(S342 ⑬, I284 ③)
		for name in ["raid", "raid%d" % (battle.floors_cleared + 1)]:
			if HINTS.any(func(h): return h[0] == name) and not name in Settings.hints_done:
				return name
		return ""
	if battle.round_index > 0:
		return ""
	for h in HINTS:
		if h[1] == battle.wave_index + 1 and h[2] == battle.state and not h[0] in Settings.hints_done:
			return h[0]
	return ""

# 출전 영웅이 쓴 스킬 수(S192)
func _skills() -> int:
	return battle.heroes.reduce(func(s, h): return s + h.skill_uses, 0)

func _finish(name: String) -> void:
	if name == "" or name in Settings.hints_done:
		return
	Settings.hints_done.append(name)
	Settings.save_file()
