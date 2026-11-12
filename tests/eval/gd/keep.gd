extends "res://tests/eval/gd/hud.gd"
# 거점 패널(S365·I298). hud.gd 머리의 계약에 더하는 API:
#   main.hud.keep — 거점 패널(Control, S365). HUD _process가 함께 새로 그린다
#     keep.tabs — 탭 버튼 셋(BaseButton, 근접·원거리·지원 차례). 안의 Label이 탭 이름·종류 수다
#     keep.kinds — 지금 탭의 칸 다섯 종류(빈 칸은 "")
#     keep.cards — 카드 다섯(BaseButton). 누르면(pressed) 한 명, gui_input에 Shift를 누른 왼쪽 버튼 누름을 넣으면 다섯 명까지 산다
#     keep.names·keep.owned·keep.costs — 카드마다 이름·보유(«×n», 0이면 숨김)·값 Label. 값 글자색은 font_color 덮어쓰기다
#     keep.pics — 카드마다 그림(TextureRect, 흐리면 modulate.a 0.35) · keep.slashes — 카드마다 값 동전의 빗금(CanvasItem)
#     keep.pips — 카드마다 강화 점(ColorRect 배열, 산 단계만큼 color가 #ffd37f) · keep.plus — 카드마다 «+n» Label
#     keep.strips — 카드 아래 강화 띠 다섯(BaseButton, 글은 text)
#     keep.village·keep.raid·keep.rally — 머리 줄 버튼(BaseButton, 글은 text). main.hud.raid는 keep.raid다
#     keep.pop — 머리 줄 인구 Label(«인구 n/m», 상한이면 font_color #ef3a0c)
#     keep.info — 설명 상자(Control). 그 안의 보이는 Label이 글이다
#   main.controls.keep_tab — 마지막 탭(0 근접·1 원거리·2 지원) · main.controls.rallying — 집결 지점 고르기 중
#   G·Tab 키는 main을 거쳐 controls로 간다(_key·_shift_key)

const FIELD := Vector2i(10, 70)  # 시험 스테이지의 빈 들판 칸(유닛·구조물이 없다)
const GOLD := Color("e0c040")
const RED := Color("ef3a0c")
const PIP := Color("ffd37f")
const MELEE := ["shieldman", "spearman", "cavalry", "", ""]
const RANGED := ["netter", "fire_mage", "thunder_mage", "frost_mage", ""]
const SUPPORT := ["engineer", "cleric", "", "", ""]

func _panel(main):
	return main.hud.get("keep")

# 거점 칸을 좌클릭하고 HUD를 한 번 돌린다
func _open(main) -> void:
	click(main.controls, MOUSE_BUTTON_LEFT, px(main.view.battle.base.cell))
	_frame(main)
	_layout(main)
	_frame(main)

func _n_of(b, kind: String) -> int:
	return b.units.filter(func(u): return u.kind == kind and u.alive).size()

func _filled(k, i: int) -> int:
	return k.pips[i].filter(func(p): return p.color.is_equal_approx(PIP)).size()

func _shift_click(btn) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.shift_pressed = true
	btn.gui_input.emit(e)

func _tab_text(t) -> String:
	return str(t.get("text")) + " " + " ".join(_labels(t))

# EV1089 · S365: 거점을 누르거나 G로 열고, 빈 땅·G·ESC로 닫는다. G로 열면 고른 영웅과 카메라는 그대로다. 거점 맵 팝업에는 보이는 버튼이 없다
func ev1089():
	var main = _live_prep()
	var b = main.view.battle
	var c = main.controls
	var k = _panel(main)
	if not k is Control:
		_done(main)
		return "main.hud.keep이 없다"
	_open(main)
	var opened: bool = k.is_visible_in_tree()
	var pops: Array = _pops(main).map(func(n): return n.text)
	click(c, MOUSE_BUTTON_LEFT, px(FIELD))
	_frame(main)
	var closed: bool = not k.is_visible_in_tree()
	var h = b.heroes[0]
	c.selected = [h]
	var cam: Camera2D = main.get_viewport().get_camera_2d()
	var pos0: Vector2 = cam.position
	_key(KEY_G)
	_frame(main)
	var g_open: bool = k.is_visible_in_tree()
	var kept: bool = c.selected == [h] and cam.position == pos0
	_key(KEY_G)
	_frame(main)
	var g_closed: bool = not k.is_visible_in_tree()
	_key(KEY_G)
	_frame(main)
	_key(KEY_ESCAPE)
	_frame(main)
	var esc: bool = not k.is_visible_in_tree() and not main.get_tree().paused
	_done(main)
	return check(opened and pops.is_empty() and closed and g_open and kept and g_closed and esc,
		"거점 누름 뒤 패널 %s · 팝업 버튼 %s · 빈 땅 뒤 숨음 %s · G 뒤 보임 %s · 영웅·카메라 그대로 %s · G 다시 뒤 숨음 %s · ESC 뒤 숨고 안 멈춤 %s" % [opened, pops, closed, g_open, kept, g_closed, esc])

# EV1090 · S365: 패널 사각형 [92,262,216,98], 조작이 모두 그 안, 건설 격자·미니맵과 겹치지 않음. 패널이 떠 있는 동안 힌트 칸은 (4,44)(I298 ⑧)
func ev1090():
	_hints_reset()
	var main = _live_prep()
	var k = _panel(main)
	if not k is Control:
		_done(main)
		return "main.hud.keep이 없다"
	_open(main)
	var r: Rect2 = k.get_global_rect()
	var parts: Array = (k.tabs + k.cards + k.strips + [k.village, k.raid, k.rally]).filter(func(n): return n.is_visible_in_tree())
	var outside: Array = parts.filter(func(n): return not r.encloses(n.get_global_rect())).map(func(n): return n.get_global_rect())
	var hud = main.hud
	var clash: bool = r.intersects(hud.grid.get_global_rect()) or r.intersects(hud.minimap.get_global_rect())
	var hint_open: Vector2 = hud.hints.get_global_rect().position
	var hint_shown: bool = hud.hints.is_visible_in_tree()
	click(main.controls, MOUSE_BUTTON_LEFT, px(FIELD))
	_frame(main)
	var hint_closed: Vector2 = hud.hints.get_global_rect().position
	_done(main)
	return check(r == Rect2(92, 262, 216, 98) and parts.size() >= 13 and outside.is_empty() and not clash and hint_shown and hint_open == Vector2(4, 44) and hint_closed == Vector2(68, 300),
		"패널 %s(기대 [92,262,216,98]) · 보이는 조작 %d개(13개 이상) · 밖으로 나간 것 %s · 건설 격자·미니맵과 겹침 %s · 힌트 보임 %s · 열린 동안 힌트 자리 %s(4,44) · 닫은 뒤 %s(68,300)" % [r, parts.size(), outside, clash, hint_shown, hint_open, hint_closed])

# EV1091 · S365: 탭 셋(근접·원거리·지원), 탭마다 거점이 파는 종류만 목록 차례로 앞 칸부터, Tab·Shift+Tab·탭 버튼으로 바꾸고 다시 열면 마지막 탭
func ev1091():
	var main = _live_prep()
	var c = main.controls
	var k = _panel(main)
	if not k is Control:
		_done(main)
		return "main.hud.keep이 없다"
	_open(main)
	var first: int = c.keep_tab
	var titles: Array = k.tabs.map(_tab_text)
	var heads: bool = titles.size() == 3 and "근접" in titles[0] and "원거리" in titles[1] and "지원" in titles[2]
	var melee: Array = k.kinds.duplicate()
	var names: Array = []
	for i in k.cards.size():
		if k.cards[i].is_visible_in_tree() and k.kinds[i] != "":
			names.append(k.names[i].text)
	_key(KEY_TAB)
	_frame(main)
	var ranged: Array = k.kinds.duplicate()
	_key(KEY_TAB)
	_frame(main)
	var support: Array = k.kinds.duplicate()
	_shift_key(KEY_TAB)
	_frame(main)
	var back: Array = k.kinds.duplicate()
	k.tabs[2].pressed.emit()
	_frame(main)
	click(c, MOUSE_BUTTON_LEFT, px(FIELD))
	_frame(main)
	_key(KEY_G)
	_frame(main)
	var again: Array = [c.keep_tab, k.kinds.duplicate()]
	_done(main)
	var ok := first == 0 and heads and melee == MELEE and names == ["방패병", "창병", "기병"] and ranged == RANGED and support == SUPPORT and back == RANGED and again == [2, SUPPORT]
	return check(ok, "처음 탭 %d · 탭 글 %s · 근접 %s 이름 %s · Tab 뒤 %s · 또 Tab 뒤 %s · Shift+Tab 뒤 %s · 지원 탭 누르고 닫았다 G 뒤 %s" % [first, titles, melee, names, ranged, support, back, again])

# EV1092 · S365: 카드를 누르면 한 명, Shift+누르면 다섯 명까지(인구가 되는 만큼) 거점에서 산다. 카드에 보유 «×n»과 값
func ev1092():
	var main = _live_prep()
	var b = main.view.battle
	var k = _panel(main)
	if not k is Control:
		_done(main)
		return "main.hud.keep이 없다"
	_open(main)
	var cost: int = b.MERC_KINDS.shieldman.cost
	var g0: int = b.gold
	var n0 := _n_of(b, "shieldman")
	k.cards[0].pressed.emit()
	_frame(main)
	var n1 := _n_of(b, "shieldman")
	var one: bool = n1 == n0 + 1 and b.gold == g0 - cost
	var shown := [k.owned[0].text, k.costs[0].text, k.owned[0].is_visible_in_tree()]
	var want: int = mini(5, b.pop_cap() - b.pop_used())
	var g1: int = b.gold
	_shift_click(k.cards[0])
	_frame(main)
	var many: bool = _n_of(b, "shieldman") == n0 + 1 + want and b.gold == g1 - want * cost
	_done(main)
	return check(one and shown == ["×1", str(cost), true] and want >= 1 and many,
		"한 번 누름: 방패병 %d → %d · 골드 %d → %d · 카드 보유·값·보유 보임 %s(기대 ×1·%d·참) · Shift: 기대 %d명 더, 방패병 %d · 골드 %d → %d" % [n0, n1, g0, g1, shown, cost, want, _n_of(b, "shieldman"), g1, b.gold])

# EV1093 · S365: 강화 점·강화 띠. 준비 단계에 띠를 누르면 한 단계, 최대면 «강화 최대», 전투 단계에는 눌리지 않는다
func ev1093():
	var main = _live_prep()
	var b = main.view.battle
	var k = _panel(main)
	if not k is Control:
		_done(main)
		return "main.hud.keep이 없다"
	_open(main)
	var before := [k.pips[0].size(), _filled(k, 0), k.strips[0].text]
	var g0: int = b.gold
	k.strips[0].pressed.emit()
	_frame(main)
	var after := [b.merc_rank.get("shieldman", 0), g0 - b.gold, _filled(k, 0), k.strips[0].text]
	b.merc_rank["shieldman"] = 3
	_frame(main)
	var top := [k.strips[0].text, k.strips[0].disabled]
	b.merc_rank["shieldman"] = 1
	b.start_battle()
	_frame(main)
	var g1: int = b.gold
	var off: bool = k.strips[0].disabled
	k.strips[0].pressed.emit()
	_frame(main)
	var still: bool = b.merc_rank.get("shieldman", 0) == 1 and b.gold == g1
	_done(main)
	return check(before == [3, 0, "강화 45"] and after == [1, 45, 1, "강화 65"] and top == ["강화 최대", true] and off and still,
		"처음 점·채운 점·띠 %s(기대 3·0·강화 45) · 띠 누른 뒤 단계·쓴 골드·채운 점·띠 %s(1·45·1·강화 65) · 3단계 %s(강화 최대·눌리지 않음) · 전투 단계 띠 꺼짐 %s · 눌러도 그대로 %s" % [before, after, top, off, still])

# EV1094 · S365: 머리 줄 — 준비 단계 마을 레벨·원정(첫 클릭 «원정?», 2초 안에 다시), 전투 단계 집결. 인구 글
func ev1094():
	var main = _live_prep()
	var b = main.view.battle
	var k = _panel(main)
	if not k is Control:
		_done(main)
		return "main.hud.keep이 없다"
	_open(main)
	var vis := func(n): return n.is_visible_in_tree()
	var prep1 := [vis.call(k.village) and k.village.text.begins_with("마을 Lv2 60"), vis.call(k.raid), k.raid.text, k.raid.disabled, vis.call(k.rally)]
	var said := _tip_of(main, k.raid)
	var pop: bool = k.pop.text == "인구 %d/%d" % [b.pop_used(), b.pop_cap()]
	b.state = "cleared"
	b.next_round()
	main.controls.village = true
	_frame(main)
	k.raid.pressed.emit()
	_frame(main)
	var armed := [k.raid.text, b.state]
	main.hud._process(2.1)
	var cooled: String = k.raid.text
	k.raid.pressed.emit()
	k.raid.pressed.emit()
	_frame(main)
	var went: String = b.state
	_done(main)
	var main2 = _live_prep()
	var b2 = main2.view.battle
	var k2 = _panel(main2)
	b2.start_battle()
	_open(main2)
	var fight := [k2.rally.is_visible_in_tree(), k2.village.is_visible_in_tree(), k2.raid.is_visible_in_tree()]
	_done(main2)
	return check(prep1 == [true, true, "원정 1층", true, false] and "2라운드부터" in said and pop and armed == ["원정?", "prep"] and cooled == "원정 1층" and went == "raid" and fight == [true, false, false],
		"1라운드 머리 줄(마을 Lv2 60 보임·원정 보임·글·꺼짐·집결 보임) %s · 원정 툴팁 «%s» · 인구 글 맞음 %s · 2라운드 첫 누름 %s(원정?·prep) · 2.1초 뒤 «%s» · 두 번 누른 뒤 %s · 전투 단계 집결·마을·원정 보임 %s" % [prep1, said, pop, armed, cooled, went, fight])

# EV1095 · I298 ②④: 값 글자색(절반 이상 노랑·절반도 없으면 빨강)과 빗금, 인구 상한이면 그림 흐림·인구 글 빨강·설명 상자 «인구 가득»
func ev1095():
	var main = _live_prep()
	var b = main.view.battle
	var k = _panel(main)
	if not k is Control:
		_done(main)
		return "main.hud.keep이 없다"
	_open(main)
	b.gold = 25
	_frame(main)
	var warn := [k.costs[0].get_theme_color("font_color"), k.slashes[0].is_visible_in_tree()]
	b.gold = 10
	_frame(main)
	var poor: Color = k.costs[0].get_theme_color("font_color")
	b.gold = BIG
	while b.pop_used() < b.pop_cap() and b.recruit(b.base, "spearman") != null:
		pass
	_frame(main)
	var faded := [snappedf(k.pics[0].modulate.a, 0.01), k.pop.get_theme_color("font_color")]
	_move(k.cards[0].get_global_rect().get_center())
	_frame(main)
	_layout(main)
	_frame(main)
	var said := " ".join(_labels(k.info)) if k.info.is_visible_in_tree() else ""
	_done(main)
	return check(warn[0].is_equal_approx(GOLD) and warn[1] and poor.is_equal_approx(RED) and faded[0] == 0.35 and faded[1].is_equal_approx(RED) and "인구 가득" in said,
		"골드 25: 값 색·빗금 %s(기대 #e0c040·참) · 골드 10: %s(#ef3a0c) · 인구 상한: 그림 불투명도·인구 글 색 %s(0.35·#ef3a0c) · 설명 상자 «%s»(«인구 가득»)" % [warn, poor, faded, said])

# EV1096 · I298 ④: 설명 상자는 패널 바로 위에 지연 없이, 이름·역할 한 줄·수치·다음 강화 효과
func ev1096():
	var main = _live_prep()
	var b = main.view.battle
	var k = _panel(main)
	if not k is Control:
		_done(main)
		return "main.hud.keep이 없다"
	b.rank_up("shieldman")
	_open(main)
	_move(k.cards[0].get_global_rect().get_center())
	_frame(main)
	_layout(main)
	_frame(main)
	var shown: bool = k.info.is_visible_in_tree()
	var r: Rect2 = k.info.get_global_rect()
	var said := " ".join(_labels(k.info))
	_move(EMPTY)
	_frame(main)
	var gone: bool = not k.info.is_visible_in_tree()
	_done(main)
	var want := ["방패병", "정면 돌진을 막아 기절시키는 탱커", "체력 110", "방어력 10 → 15"]
	var miss: Array = want.filter(func(w): return not w in said)
	return check(shown and r.end.y <= 262.0 and r.size.y > 0.0 and miss.is_empty() and gone,
		"설명 상자 보임 %s · 사각형 %s(아래 가장자리 262 이하) · 없는 글 %s · 글 «%s» · 빈 자리로 옮긴 뒤 숨음 %s" % [shown, r, miss, said, gone])

# EV1097 · I298 ⑤: 산 직후 카드 «+n»(0.8초)과 전투 단계 토스트 «이름 +n → 집결 지점»
func ev1097():
	var main = _live_prep()
	var b = main.view.battle
	var k = _panel(main)
	if not k is Control:
		_done(main)
		return "main.hud.keep이 없다"
	b.start_battle()
	_open(main)
	k.cards[0].pressed.emit()
	_frame(main)
	var plus := [k.plus[0].is_visible_in_tree(), k.plus[0].text]
	var toasts: Array = _toasts(main)
	var toast: bool = toasts.any(func(t): return "방패병 +1 → 집결 지점" in t)
	main.hud._process(1.0)
	var gone: bool = not k.plus[0].is_visible_in_tree()
	_done(main)
	return check(plus == [true, "+1"] and toast and gone, "산 뒤 «+n» 보임·글 %s(참·+1) · 토스트 %s(«방패병 +1 → 집결 지점») · 1초 뒤 숨음 %s" % [plus, toasts, gone])

# EV1098 · I298 ⑥: 전투 단계 «집결»을 누르면 집결 지점 고르기, 다음 맵 좌클릭 칸이 거점 집결 지점. 우클릭은 그만둔다. 고른 영웅은 그대로
func ev1098():
	var main = _live_prep()
	var b = main.view.battle
	var c = main.controls
	var k = _panel(main)
	if not k is Control:
		_done(main)
		return "main.hud.keep이 없다"
	b.start_battle()
	var h = b.heroes[0]
	c.selected = [h]
	_key(KEY_G)
	_frame(main)
	k.rally.pressed.emit()
	var on: bool = c.get("rallying") == true
	_frame(main)
	var chip: String = main.hud.hint.text if main.hud.chip.is_visible_in_tree() else ""
	var to: Vector2i = b.base.cell + Vector2i(4, 4)
	click(c, MOUSE_BUTTON_LEFT, px(to))
	var set_ok: bool = b.base.rally == to and c.get("rallying") == false and c.selected == [h]
	k.rally.pressed.emit()
	click(c, MOUSE_BUTTON_RIGHT, px(to + Vector2i(2, 0)))
	var quit: bool = c.get("rallying") == false and b.base.rally == to
	_done(main)
	return check(on and "집결 지점" in chip and set_ok and quit,
		"«집결» 뒤 고르기 %s · 안내 칩 «%s» · 좌클릭 뒤 집결 %s·고르기 %s·영웅 그대로 %s · 다시 켜고 우클릭 뒤 꺼짐·집결 그대로 %s" % [on, chip, b.base.rally, c.get("rallying"), c.selected == [h], quit])
