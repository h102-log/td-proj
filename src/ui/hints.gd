extends Panel
# 처음 하는 사람 힌트(S191)이자 튜토리얼(S192): 1라운드 k웨이브에 k웨이브 단계 가운데 지금 판 단계의 끝나지 않은 첫 단계를
# [68,300,200,40](미니맵 S209 오른쪽)에 두 줄 + «건너뛰기»로 보이고, 오른쪽 위에 그 웨이브의 축 이름을 둔다. 힌트 설정(S184)을 끄면 숨는다.
# 끝날 조건은 숨어 있을 때도 지난 프레임과 비교해 찾고, 끝낸 힌트는 설정 파일에 남긴다(I166). HUD가 매 프레임 step을 부른다.
# 원정 동안에는 라운드와 상관없이 첫 원정 힌트를 보이고(S332), 그것이 끝났으면 그 층의 힌트를 보인다(S342 ⑬). 원정 힌트는 줄마다 따로 뜨고 끝난다(S369 ⑦)

const HudTheme := preload("res://src/ui/hud_theme.gd")
const Settings := preload("res://src/settings.gd")
const AXES := ["시설", "용병", "영웅"]  # 1라운드 1·2·3웨이브가 소개하는 축(S192)
const AT := Vector2(68, 300)  # 힌트 칸의 자리(S191)
const RAID_AT := Vector2(4, 29)  # 원정 동안의 자리(S332 2026-11-11 변경): 위 띠 바로 아래 왼쪽. 보스방 바닥을 가리지 않는다
const KEEP_AT := Vector2(4, 44)  # 거점 패널(S365)이 떠 있는 동안의 자리(I298 ⑧): 인구·타워 칸 바로 아래 왼쪽. 패널이 원래 자리를 덮는다
const HINTS := [  # [이름, 1라운드 웨이브, 판 단계, 글](S192 임시값, keep·merc·buy 글은 S98 2026-11-12 변경)
	["build", 1, "prep", "오른쪽 아래 칸(숫자 키)을 고르고\n맵을 누르면 공병이 가서 짓는다"],
	["keep", 1, "prep", "거점을 누르면(G) 거점 패널이 뜬다\n(여기서 용병을 산다)"],
	["start", 1, "prep", "준비가 끝나면 위 오른쪽\n▶ 전투 시작을 누른다"],
	["merc", 2, "prep", "거점 패널 카드를 눌러 병사를 산다\n용병은 적을 몸으로 붙잡는다"],
	["buy", 2, "battle", "전투 중에도 G로 패널을 열어 산다\n짓기는 공병(5)이 가서 한다"],
	["move", 3, "prep", "영웅을 누르고(1)\n우클릭한 칸으로 보낸다"],
	["skill", 3, "battle", "Q로 영웅 스킬을 쓴다\n조준하는 칸은 맵을 눌러 쓴다"],
	# 원정 힌트는 줄마다 하나다(S369 ⑦, I300 ⑧). 다섯째 칸이 있는 둘째 줄(이름 끝 b)은 그 원정에서 그 사건이 일어난 뒤에만 뜬다
	["raid", 0, "raid", "보스는 그로기 때만 크게 맞는다"],  # 첫 원정 힌트(S332): 웨이브 0은 라운드·웨이브와 상관없이 원정 동안이다(I277 ④)
	["raidb", 0, "raid", "빨강은 피하고 금색에 모인다", "gold"],
	["raid2", 0, "raid", "벽 앞에서 돌진을 피하면 박힌다"],  # 2층 힌트(S337 ⑧)
	["raid2b", 0, "raid", "붙잡힌 동료는 때려서 구한다", "pin"],
	["raid3", 0, "raid", "포탄 원을 기계 옆에서 굳힌다"],  # 3층 힌트(S342 ⑬): 이름 끝의 수가 층 번호다(I284 ③)
	["raid3b", 0, "raid", "대장 돌진은 잔해나 벽에 박는다", "phase2"],
	["raid4", 0, "raid", "급강하를 피하면 땅에 처박힌다"],  # 4층 힌트(S352 ⑬)
	["raid4b", 0, "raid", "떨어진 뒤엔 옆구리에 선다", "phase2"],
	["raid5", 0, "raid", "바위·착지를 형제에게 맞힌다"],  # 5층 힌트(S354 ⑬): 두 몸 가운데 어느 몸이든 그로기가 되면 끝난다(I293 ①)
	["raid5b", 0, "raid", "하나가 쓰러지면 남은 쪽이 성난다", "lone"],
]

var battle
var controls
var text := Label.new()
var axis := Label.new()  # 축 이름(S192)
var _built := -1  # 지난 프레임의 라운드 집계(I119) built. -1이면 아직 보지 않았다
var _bought := -1  # 지난 프레임의 라운드 집계 merc_bought
var _used := -1  # 지난 프레임의 출전 영웅 스킬 수(_skills)
var _groggy := false  # 지난 프레임에 원정 보스 몸이 그로기였나(I284 ③)
var _met := {}  # 이번 원정에서 일어난 둘째 줄 사건(gold·pin·phase2·lone → true, I300 ⑧). 원정이 아니면 비운다

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
	if battle.state == "raid":
		for k in _events_now():
			_met[k] = true
	else:
		_met = {}
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
	position = RAID_AT if battle.state == "raid" else KEEP_AT if controls.village and battle.state in ["prep", "battle"] else AT  # 원정 동안은 왼쪽 위다(I286 ③). 거점 패널이 떠 있으면 그 위로(I298 ⑧)
	visible = Settings.hints and now != ""
	for h in HINTS:
		if h[0] == now:
			text.text = h[3]
			axis.text = AXES[h[1] - 1] if h[1] > 0 else "원정"

# 1라운드 지금 웨이브의 단계 가운데 지금 판 단계의 끝나지 않은 첫 단계 이름(S192). 앞 웨이브에 남은 단계는 넘어오지 않는다. 없으면 ""
func _current() -> String:
	if battle.state == "raid":  # 첫 원정 힌트(S332), 그다음 그 층의 힌트(S342 ⑬, I284 ③). 줄마다 첫 줄 → 둘째 줄(S369 ⑦)
		for base in ["raid", "raid%d" % (battle.floors_cleared + 1)]:
			for name in [base, base + "b"]:
				var h = _hint(name)
				if h != null and not name in Settings.hints_done and (h.size() < 5 or _met.has(h[4])):
					return name
		return ""
	if battle.round_index > 0:
		return ""
	for h in HINTS:
		if h[1] == battle.wave_index + 1 and h[2] == battle.state and not h[0] in Settings.hints_done:
			return h[0]
	return ""

func _hint(name: String):
	for h in HINTS:
		if h[0] == name:
			return h
	return null

# 지금 원정 보스 몸에 일어나 있는 둘째 줄 사건(I300 ⑧): 금색 원 예고·영웅 붙잡음·둘째 형태·홀로 남음
func _events_now() -> Array:
	var out := []
	for e in battle.enemies:
		if e.raid.is_empty():
			continue
		var sk = battle.deed(e, e.cast.id) if e.cast != null else null
		if sk is Dictionary and sk.get("color", "") == "gold":
			out.append("gold")
		if e.grip != null:
			out.append("pin")
		if battle._second(e):
			out.append("phase2")
		if e.lone:
			out.append("lone")
	return out

# 출전 영웅이 쓴 스킬 수(S192)
func _skills() -> int:
	return battle.heroes.reduce(func(s, h): return s + h.skill_uses, 0)

func _finish(name: String) -> void:
	if name == "" or name in Settings.hints_done:
		return
	Settings.hints_done.append(name)
	Settings.save_file()
