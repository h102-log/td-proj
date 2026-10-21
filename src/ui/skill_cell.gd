extends Button
# 영웅 칸의 스킬 칸 18×18(I151). HUD가 매 프레임 show_state로 상태를 넣고, 칸은 글 대신 그림으로 보인다:
# 쓸 수 있음 = 칸 글자, 재사용 대기 = 위에서 덮는 검정 막(남은 비율)과 가운데 올림한 초(칸 글자는 왼쪽 위로), 마나 부족 = 파란 틴트,
# 잠김 = 어둡게 + 자물쇠, 자동 시전 = 네 귀퉁이 금색 꺾쇠, 조준 중 = 금색 테두리 맥박, 토글 켬 = 청록 안쪽 테두리, 준비 단계 = 오른쪽 아래 모래시계

const HudTheme := preload("res://src/ui/hud_theme.gd")
const HudBuild := preload("res://src/ui/hud_build.gd")
const MANA := Color(0.5, 0.5, 1.0)  # 마나 부족 틴트(ui_research 4.7)
const LOCKED := Color(0.4, 0.4, 0.4)
const CURTAIN := Color(0, 0, 0, 0.6)  # 재사용 대기 막(ui_research 4.9)
const TEAL := Color("3c9f9c")  # 토글 켬(ui_research 4.9 아군 색)
const FLASH := 0.3  # 거부 표시 초(I151 임시값)
const LOCK := [".###.", "#...#", "#...#", "#####", "##.##", "##.##", "#####"]
const GLASS := ["#####", ".#.#.", "..#..", ".#.#.", "#####"]  # 모래시계

var lock := TextureRect.new()  # 잠겼을 때만 보인다
var _glass := TextureRect.new()
var _key := Label.new()  # 재사용 대기 중 왼쪽 위로 옮긴 칸 글자
var _secs := Label.new()  # 재사용 대기 올림한 초
var _over := Control.new()  # 막·꺾쇠·테두리. 틴트(self_modulate)에 물들지 않게 자식에 그린다
var _st := {}
var _reject := -INF  # 거부 표시를 시작한 때(HUD 시계)

func _init() -> void:
	theme_type_variation = "BarCell"
	focus_mode = Control.FOCUS_NONE
	add_theme_font_size_override("font_size", 8)
	size = Vector2(18, 18)

func _ready() -> void:
	_over.size = size
	_over.draw.connect(_paint)
	add_child(_over)
	for l in [_key, _secs]:
		l.add_theme_color_override("font_color", HudTheme.TEXT)
		add_child(l)
	_key.add_theme_font_size_override("font_size", 7)
	_key.position = Vector2(1, -1)
	_key.size = Vector2(8, 8)
	_secs.add_theme_font_size_override("font_size", 8)
	_secs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_secs.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_secs.position = Vector2(0, 3)
	_secs.size = Vector2(18, 14)
	for pair in [[lock, LOCK, HudTheme.TEXT, Rect2(6, 5, 5, 7)], [_glass, GLASS, HudTheme.DIM, Rect2(12, 12, 5, 5)]]:
		var r: TextureRect = pair[0]
		r.texture = HudBuild.dots(pair[1], {"#": pair[2]})
		r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.position = pair[3].position
		r.size = pair[3].size
		add_child(r)
	for n in get_children():
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE

# s: letter(칸 글자) · cd(남은 재사용 대기 초) · gap(재사용 대기 초) · mana(모자람) · lock · auto · aim · on(토글 켬) · prep(준비 단계) · now(HUD 시계)
func show_state(s: Dictionary) -> void:
	_st = s
	var wait: bool = s.cd > 0.0 and not s.lock
	text = "" if wait else s.letter
	_key.text = s.letter
	_key.visible = wait
	_secs.text = str(ceili(s.cd))
	_secs.visible = wait
	lock.visible = s.lock
	_glass.visible = s.prep and not s.lock
	self_modulate = LOCKED if s.lock else MANA if s.mana else Color.WHITE
	_over.queue_redraw()

# 거부 표시(I151): 테두리가 FLASH초 빨갛다
func reject() -> void:
	_reject = _st.get("now", 0.0)

func _paint() -> void:
	if _st.is_empty():
		return
	var r := Rect2(Vector2.ZERO, size)
	if _st.cd > 0.0 and not _st.lock:
		_over.draw_rect(Rect2(0, 0, size.x, size.y * clampf(_st.cd / maxf(_st.gap, 0.01), 0.0, 1.0)), CURTAIN)
	if _st.auto:
		for x in [0.0, size.x - 1.0]:
			for y in [0.0, size.y - 1.0]:
				_over.draw_rect(Rect2(minf(x, size.x - 4.0), y, 4, 1), HudTheme.ACCENT)
				_over.draw_rect(Rect2(x, minf(y, size.y - 4.0), 1, 4), HudTheme.ACCENT)
	if _st.on:
		_over.draw_rect(r.grow(-2.0), TEAL, false, 2.0)
	if _st.aim:
		_over.draw_rect(r.grow(-0.5), Color(HudTheme.ACCENT, 0.55 + 0.45 * sin(_st.now * TAU * 2.0)), false, 1.0)
	if _st.now - _reject < FLASH:
		_over.draw_rect(r.grow(-0.5), HudTheme.DANGER, false, 1.0)
