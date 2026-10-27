extends Button
# 대피령 버튼(S230): 화면 왼쪽 아래 미니맵(S209) 위 [3,266,60,26]. 종 그림·«대피령»(대피령 중이면 빨간 바탕에 «대피 중»)·단축키 B·신뢰 칸 다섯.
# 누르거나 B 키(controls)면 대피령을 낸다(S225). 낼 수 없으면(전투 단계가 아님·주민이 없음) 흐리다.
# 판의 주민 소식(battle.folk_news)을 토스트로 띄운다. 보이기는 스스로 정한다(준비·전투 단계). 시간은 _process로 흘린다

const HudTheme := preload("res://src/ui/hud_theme.gd")
const HudBuild := preload("res://src/ui/hud_build.gd")
const Folk := preload("res://src/sim/folk.gd")
const BELL := ["....##....", "...####...", "..######..", "..######..", "..######..", ".########.", "##########", "....oo....", "....oo....", ".........."]
const NEWS := {"hurt": "주민이 다쳤다 — 이번 라운드 세금 −1", "dead": "주민이 죽었다 — 그 집 세금 −1",
	"false": "거짓 대피령: 적이 성벽에 안 왔다 · 신뢰 −1", "ok": "대피령이 옳았다 · 신뢰 +1", "left": "신뢰가 바닥나 한 가구가 떠났다"}

var hud
var battle
var dots := []  # 신뢰 칸 다섯(ColorRect). 앞에서부터 신뢰만큼 금색이다
var _title: Label
var _bells := []  # [평소 종, 대피 중 종](TextureRect)
var _on_box: StyleBoxFlat  # 대피 중 바탕

func _init(h) -> void:
	hud = h
	battle = h.battle

func _ready() -> void:
	theme_type_variation = "BarCell"
	position = Vector2(3, 266)
	size = Vector2(60, 26)
	focus_mode = Control.FOCUS_NONE  # 포커스가 가면 Enter가 전투 시작으로 가지 않는다
	pressed.connect(func(): battle.evacuate())
	_on_box = HudTheme.box("normal", "Button", Color("3a1a12"), HudTheme.DANGER)
	for c in [HudTheme.ACCENT, HudTheme.DANGER]:
		var bell := TextureRect.new()
		bell.texture = HudBuild.dots(BELL, {"#": c, "o": Color("6b5537")})
		bell.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bell.stretch_mode = TextureRect.STRETCH_SCALE
		bell.position = Vector2(3, 5)
		bell.size = Vector2(16, 16)
		bell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bell)
		_bells.append(bell)
	var key := _label("B", 7, HudTheme.ACCENT)
	key.position = Vector2(1, -2)
	_title = _label("", 9, HudTheme.TEXT)
	_title.position = Vector2(22, 0)
	for i in Folk.TRUST:
		var pip := ColorRect.new()
		pip.position = Vector2(22 + 7 * i, 17)
		pip.size = Vector2(5, 4)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(pip)
		dots.append(pip)
	hud.tip.add(self, func(): return ["대피령", "", "[B]", "주민을 대피소와 집으로 피신시킨다 · 신뢰 %d/%d" % [battle.trust, Folk.TRUST], _why()])
	_process(0.0)

func _label(text: String, px: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", px)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l

# 대피령을 낼 수 없는 까닭(툴팁 빨간 줄). 낼 수 있거나 대피령 중이면 ""
func _why() -> String:
	if battle.can_evacuate() or battle.evac:
		return ""
	return "주민이 없다" if battle.people.is_empty() else "전투 단계에만"

func _process(_delta: float) -> void:
	visible = battle.state in ["prep", "battle"]
	modulate.a = 1.0 if battle.can_evacuate() or battle.evac else 0.35  # 흐린 칸은 건설 격자(hud_build)와 같은 값
	_title.text = "대피 중" if battle.evac else "대피령"
	_title.add_theme_color_override("font_color", HudTheme.DANGER if battle.evac else HudTheme.TEXT)
	_bells[0].visible = not battle.evac
	_bells[1].visible = battle.evac
	if battle.evac:
		add_theme_stylebox_override("normal", _on_box)
	else:
		remove_theme_stylebox_override("normal")
	for i in dots.size():
		dots[i].color = HudTheme.ACCENT if i < battle.trust else HudTheme.LINE
	for n in battle.folk_news:
		hud.toasts.push(NEWS[n])
	battle.folk_news.clear()
