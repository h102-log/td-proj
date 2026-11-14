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
#     keep.undo — 준비 단계 머리 줄 «↶»(BaseButton, S367) · keep.undos — 무를 목록(Array, 구매마다 하나)
#     keep.recents — 탭 줄 오른쪽 끝 최근 칸 셋(BaseButton, S368). 누르면(pressed) 한 명, gui_input Shift 누름은 다섯 명까지
#     keep.recent — 최근 칸 셋의 종류(빈 칸 "") · keep.recent_pics — 최근 칸 그림(TextureRect, 흐리면 modulate.a 0.35) · keep.tab_hint — 탭 줄 «Tab» Label
#   main.controls.keep_tab — 마지막 탭(0 근접·1 원거리·2 지원) · main.controls.rallying — 집결 지점 고르기 중
#   G·Tab 키는 main을 거쳐 controls로 간다(_key·_shift_key)

const FIELD := Vector2i(10, 70)  # 시험 스테이지의 빈 들판 칸(유닛·구조물이 없다)
const GOLD := Color("e0c040")
const RED := Color("ef3a0c")
const PIP := Color("ffd37f")
const MELEE := ["soldier", "shieldman", "spearman", "cavalry", ""]  # 병사·궁수도 거점이 판다(S98 2026-11-12 변경)
const RANGED := ["archer", "netter", "fire_mage", "thunder_mage", "frost_mage"]
const SHIELD := 1  # 근접 탭에서 방패병 카드 칸(병사 다음)
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
	var ok := first == 0 and heads and melee == MELEE and names == ["병사", "방패병", "창병", "기병"] and ranged == RANGED and support == SUPPORT and back == RANGED and again == [2, SUPPORT]
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
	k.cards[SHIELD].pressed.emit()
	_frame(main)
	var n1 := _n_of(b, "shieldman")
	var one: bool = n1 == n0 + 1 and b.gold == g0 - cost
	var shown := [k.owned[SHIELD].text, k.costs[SHIELD].text, k.owned[SHIELD].is_visible_in_tree()]
	var want: int = mini(5, b.pop_cap() - b.pop_used())
	var g1: int = b.gold
	_shift_click(k.cards[SHIELD])
	_frame(main)
	var many: bool = _n_of(b, "shieldman") == n0 + 1 + want and b.gold == g1 - want * cost
	_done(main)
	return check(one and shown == ["×1", str(cost), true] and want >= 1 and many,
		"한 번 누름: 방패병 %d → %d · 골드 %d → %d · 카드 보유·값·보유 보임 %s(기대 ×1·%d·참) · Shift: 기대 %d명 더, 방패병 %d · 골드 %d → %d" % [n0, n1, g0, g1, shown, cost, want, _n_of(b, "shieldman"), g1, b.gold])

# EV1093 · S365: 강화 점·강화 띠. 준비 단계에 띠를 누르면 한 단계, 최대면 «강화 최대», 전투 단계에는 눌리지 않는다
func ev1093():
	var main = _live_prep()
	var b = main.view.battle
	b.village_level = b.VILLAGE_UP.size() + 1  # 마을 레벨이 강화 단계를 연다(S254 2026-11-14 변경). 띠·점·최대를 재므로 최대로 둔다
	var k = _panel(main)
	if not k is Control:
		_done(main)
		return "main.hud.keep이 없다"
	_open(main)
	var before := [k.pips[SHIELD].size(), _filled(k, SHIELD), k.strips[SHIELD].text]
	var g0: int = b.gold
	k.strips[SHIELD].pressed.emit()
	_frame(main)
	var after := [b.merc_rank.get("shieldman", 0), g0 - b.gold, _filled(k, SHIELD), k.strips[SHIELD].text]
	b.merc_rank["shieldman"] = 3
	_frame(main)
	var top := [k.strips[SHIELD].text, k.strips[SHIELD].disabled]
	b.merc_rank["shieldman"] = 1
	b.start_battle()
	_frame(main)
	var g1: int = b.gold
	var off: bool = k.strips[SHIELD].disabled
	k.strips[SHIELD].pressed.emit()
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
	var prep1 := [vis.call(k.village) and k.village.text.begins_with("마을 Lv2 %d" % b.VILLAGE_UP[0]), vis.call(k.raid), k.raid.text, k.raid.disabled, vis.call(k.rally)]
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
		"1라운드 머리 줄(마을 Lv2 비용 보임·원정 보임·글·꺼짐·집결 보임) %s · 원정 툴팁 «%s» · 인구 글 맞음 %s · 2라운드 첫 누름 %s(원정?·prep) · 2.1초 뒤 «%s» · 두 번 누른 뒤 %s · 전투 단계 집결·마을·원정 보임 %s" % [prep1, said, pop, armed, cooled, went, fight])

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
	var warn := [k.costs[SHIELD].get_theme_color("font_color"), k.slashes[SHIELD].is_visible_in_tree()]
	b.gold = 10
	_frame(main)
	var poor: Color = k.costs[SHIELD].get_theme_color("font_color")
	b.gold = BIG
	while b.pop_used() < b.pop_cap() and b.recruit(b.base, "spearman") != null:
		pass
	_frame(main)
	var faded := [snappedf(k.pics[SHIELD].modulate.a, 0.01), k.pop.get_theme_color("font_color")]
	_move(k.cards[SHIELD].get_global_rect().get_center())
	_frame(main)
	_layout(main)
	_frame(main)
	var said := " ".join(_labels(k.info)) if k.info.is_visible_in_tree() else ""
	_done(main)
	return check(warn[0].is_equal_approx(GOLD) and warn[1] and poor.is_equal_approx(RED) and is_equal_approx(faded[0], 0.35) and faded[1].is_equal_approx(RED) and "인구 가득" in said,
		"골드 25: 값 색·빗금 %s(기대 #e0c040·참) · 골드 10: %s(#ef3a0c) · 인구 상한: 그림 불투명도·인구 글 색 %s(0.35·#ef3a0c) · 설명 상자 «%s»(«인구 가득»)" % [warn, poor, faded, said])

# EV1096 · I298 ④: 설명 상자는 패널 바로 위에 지연 없이, 이름·역할 한 줄·수치·다음 강화 효과
func ev1096():
	var main = _live_prep()
	var b = main.view.battle
	var k = _panel(main)
	if not k is Control:
		_done(main)
		return "main.hud.keep이 없다"
	b.village_level = b.VILLAGE_UP.size() + 1  # 마을 레벨이 강화 단계를 연다(S254 2026-11-14 변경)
	b.rank_up("shieldman")
	_open(main)
	_move(k.cards[SHIELD].get_global_rect().get_center())
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

# EV1097 · I298 ⑤: 산 직후 카드 «+n»(0.8초)과 전투 단계 토스트 «이름 +n → 집결 지점»(토스트 줄의 3.5초 간격 뒤)
func ev1097():
	var main = _live_prep()
	var b = main.view.battle
	var k = _panel(main)
	if not k is Control:
		_done(main)
		return "main.hud.keep이 없다"
	b.start_battle()
	_open(main)
	k.cards[SHIELD].pressed.emit()
	_frame(main)
	var plus := [k.plus[SHIELD].is_visible_in_tree(), k.plus[SHIELD].text]
	main.hud.toasts._process(4.0)  # 앞 토스트(라운드 미션)가 뜬 지 3.5초가 지나야 다음 토스트가 뜬다(I163)
	var toasts: Array = _toasts(main)
	var toast: bool = toasts.any(func(t): return "방패병 +1 → 집결 지점" in t)
	main.hud._process(1.0)
	var gone: bool = not k.plus[SHIELD].is_visible_in_tree()
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

# 그 종류가 든 탭을 열고 그 카드를 누른다(패널로 산다)
func _buy(main, k, kind: String) -> void:
	main.controls.keep_tab = k.tab_of(kind)
	_frame(main)
	var i: int = k.kinds.find(kind)
	if i >= 0:
		k.cards[i].pressed.emit()
	_frame(main)

func _part(n) -> String:
	var t = n.get("text")
	return str(t) if t != null and str(t) != "" else str(n.name)

# 보이는 조작 수와, 패널 밖으로 나가거나 서로 겹친 것(없으면 [])
func _clash(k, parts: Array) -> Array:
	var box: Rect2 = k.get_global_rect()
	var shown: Array = parts.filter(func(n): return n.is_visible_in_tree())
	var bad := []
	for i in shown.size():
		var r: Rect2 = shown[i].get_global_rect()
		if not box.encloses(r):
			bad.append("%s 밖 %s" % [_part(shown[i]), r])
		for j in range(i + 1, shown.size()):
			if r.intersects(shown[j].get_global_rect()):
				bad.append("%s·%s 겹침" % [_part(shown[i]), _part(shown[j])])
	return [shown.size(), bad]

# EV1099 · S366: 병사의 화면 이름은 «병사»다(이름표·건설 격자 정보 칸·영어 «Soldier»)
func ev1099():
	var main = _live_prep()
	var hud = main.hud
	var name: String = str(hud.NAMES.get("soldier"))
	var cell = hud.grid.cells.get("soldier")
	var said := ""
	if cell != null:
		_move(cell.get_global_rect().get_center())
		hud.grid._process(0.0)
		said = _tip_text(hud.grid.info)
	var en: String = load("res://src/locale.gd").new().english("병사")
	_done(main)
	return check(name == "병사" and said.begins_with("병사") and en == "Soldier",
		"이름표 soldier «%s»(«병사») · 병사 칸 정보 칸 «%s»(«병사»로 시작) · 영어 «%s»(«Soldier»)" % [name, said, en])

# EV1100 · S367: 준비 단계 «↶»는 거점 패널에서 산 것을 나중 것부터 무른다(판매 규칙 그대로). 전투를 시작하면 목록을 비우고 숨는다
func ev1100():
	var main = _live_prep()
	var b = main.view.battle
	var c = main.controls
	var k = _panel(main)
	if not k is Control or not k.get("undo") is BaseButton:
		_done(main)
		return "main.hud.keep 또는 keep.undo가 없다"
	_open(main)
	var out := ""
	var empty := [k.undo.is_visible_in_tree(), k.undo.disabled, _tip_of(main, k.undo)]
	if not (empty[0] and empty[1] and "무를 구매가 없다" in empty[2]):
		out = "처음 «↶» 보임·꺼짐·툴팁 %s(참·참·«무를 구매가 없다»)" % [empty]
	var cs: int = b.MERC_KINDS.shieldman.cost
	var cc: int = b.MERC_KINDS.cleric.cost
	if out == "":
		_buy(main, k, "shieldman")
		_buy(main, k, "cleric")
		var tip := _tip_of(main, k.undo)
		if k.undo.disabled or not "사제 ×1" in tip:
			out = "방패병·사제를 산 뒤 «↶» 꺼짐 %s · 툴팁 «%s»(«사제 ×1»)" % [k.undo.disabled, tip]
	if out == "":
		var g: int = b.gold
		var n := [_n_of(b, "shieldman"), _n_of(b, "cleric")]
		k.undo.pressed.emit()
		var first := [_n_of(b, "cleric") == n[1] - 1, _n_of(b, "shieldman") == n[0], b.gold == g + cc]
		k.undo.pressed.emit()
		_frame(main)
		var second := [_n_of(b, "shieldman") == n[0] - 1, b.gold == g + cc + cs, k.undo.disabled]
		if first.has(false) or second.has(false):
			out = "첫 «↶»: 사제 하나 줄고·방패병 그대로·골드 +%d %s · 둘째: 방패병 하나 줄고·골드 +%d·꺼짐 %s" % [cc, first, cc + cs, second]
	if out == "":
		c.keep_tab = 0
		_frame(main)
		var want: int = mini(5, b.pop_cap() - b.pop_used())
		var n0 := _n_of(b, "shieldman")
		var g0: int = b.gold
		_shift_click(k.cards[SHIELD])
		_frame(main)
		var got := _n_of(b, "shieldman") - n0
		k.undo.pressed.emit()
		_frame(main)
		if want < 2 or got != want or _n_of(b, "shieldman") != n0 or b.gold != g0:
			out = "Shift로 방패병 %d명(기대 %d, 2 이상)을 산 뒤 «↶» 한 번: 방패병 %d → %d · 골드 %d → %d(그대로여야 한다)" % [got, want, n0, _n_of(b, "shieldman"), g0, b.gold]
	if out == "":
		_buy(main, k, "shieldman")
		b.start_battle()
		_frame(main)
		out = check(not k.undo.is_visible_in_tree() and k.undos.is_empty(), "전투 단계 «↶» 보임 %s · 무를 목록 %d개(비어야 한다)" % [k.undo.is_visible_in_tree(), k.undos.size()])
	_done(main)
	return out

# EV1101 · S368: 탭 줄 오른쪽 끝 «최근 산 3종» 칸. 있는 종류는 그대로, 없는 종류는 빈 칸·가장 오래전에 산 칸에. 누르면 그 종류를 산다(탭 그대로)
func ev1101():
	var main = _live_prep()
	var b = main.view.battle
	var c = main.controls
	var k = _panel(main)
	if not k is Control or not k.get("recents") is Array:
		_done(main)
		return "main.hud.keep 또는 keep.recents가 없다"
	_open(main)
	var out := ""
	var start := [k.recents.size(), k.recents.all(func(r): return r.is_visible_in_tree() and r.disabled), k.recent.duplicate()]
	if start != [3, true, ["", "", ""]]:
		out = "처음 최근 칸 수·모두 보이고 꺼짐·종류 %s(3·참·[\"\", \"\", \"\"])" % [start]
	if out == "":
		var seen := []
		for kind in ["shieldman", "cleric", "spearman", "shieldman", "cavalry"]:
			_buy(main, k, kind)
			b.sell(b.units.filter(func(u): return u.kind == kind and u.alive))  # 인구를 비운다
			seen.append(k.recent.duplicate())
		var want := [["shieldman", "", ""], ["shieldman", "cleric", ""], ["shieldman", "cleric", "spearman"], ["shieldman", "cleric", "spearman"], ["shieldman", "cavalry", "spearman"]]
		if seen != want:
			out = "방패병·사제·창병·방패병·기병을 산 뒤마다 칸 종류 %s(기대 %s)" % [seen, want]
	if out == "":
		c.keep_tab = 2
		_frame(main)
		var n0 := _n_of(b, "cavalry")
		var g0: int = b.gold
		k.recents[1].pressed.emit()
		_frame(main)
		if _n_of(b, "cavalry") != n0 + 1 or b.gold != g0 - b.MERC_KINDS.cavalry.cost or c.keep_tab != 2:
			out = "둘째 최근 칸: 기병 %d → %d · 골드 %d → %d(값 %d) · 탭 %d(2 그대로)" % [n0, _n_of(b, "cavalry"), g0, b.gold, b.MERC_KINDS.cavalry.cost, c.keep_tab]
	if out == "":
		b.sell(b.units.filter(func(u): return u.kind == "cavalry" and u.alive))
		var want: int = mini(5, b.pop_cap() - b.pop_used())
		var n0 := _n_of(b, "shieldman")
		_shift_click(k.recents[0])
		_frame(main)
		var faded: float = k.recent_pics[0].modulate.a
		if want < 2 or _n_of(b, "shieldman") != n0 + want or not is_equal_approx(faded, 0.35):
			out = "첫째 최근 칸 Shift: 방패병 %d → %d(기대 %d명 더, 2 이상) · 인구 상한에서 그림 불투명도 %s(0.35)" % [n0, _n_of(b, "shieldman"), want, faded]
	if out == "":
		var before: Array = k.recent.duplicate()
		b.start_battle()
		_frame(main)
		out = check(k.recent == before and k.recents.all(func(r): return r.is_visible_in_tree()), "전투 단계 칸 종류 %s(%s 그대로) · 보임 %s" % [k.recent, before, k.recents.map(func(r): return r.is_visible_in_tree())])
	_done(main)
	return out

# EV1102 · I299: 머리 줄·탭 줄의 조작이 패널 안에서 겹치지 않고, 최근 칸은 12×12로 카드 줄 오른쪽 끝에 맞춘다. 영어 머리 줄 버튼 글도 칸 안
func ev1102():
	var main = _live_prep()
	var b = main.view.battle
	var k = _panel(main)
	if not k is Control or not k.get("undo") is BaseButton or not k.get("recents") is Array or not k.get("tab_hint") is Control:
		_done(main)
		return "main.hud.keep·keep.undo·keep.recents·keep.tab_hint가 없다"
	_open(main)
	var prep := _clash(k, [k.pop, k.undo, k.village, k.raid, k.rally] + k.tabs + [k.tab_hint] + k.recents)
	var sizes: Array = k.recents.map(func(r): return r.size)
	var edge: float = k.recents[2].get_global_rect().end.x - k.cards[4].get_global_rect().end.x
	b.start_battle()
	_frame(main)
	var fight := _clash(k, [k.pop, k.undo, k.village, k.raid, k.rally] + k.tabs + [k.tab_hint] + k.recents)
	_done(main)
	TranslationServer.set_locale("en")
	var main2 = _live_prep()
	var k2 = _panel(main2)
	_open(main2)
	var wide := []
	for btn in [k2.village, k2.raid]:
		var size_px: int = btn.get_theme_font_size("font_size")
		var w: float = btn.get_theme_font("font").get_string_size(tr(btn.text), HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
		if not btn.is_visible_in_tree() or w > btn.size.x - 12 + 0.01:
			wide.append([btn.text, size_px, w, btn.size.x, btn.is_visible_in_tree()])
	_done(main2)
	TranslationServer.set_locale("ko")
	return check(prep[0] == 11 and prep[1].is_empty() and fight[0] == 9 and fight[1].is_empty() and sizes.all(func(s): return s == Vector2(12, 12)) and is_zero_approx(edge) and wide.is_empty(),
		"준비: 보이는 조작 %d(11) · %s · 전투: %d(9) · %s · 최근 칸 크기 %s(12×12) · 셋째 칸과 다섯째 카드 오른쪽 끝 차 %s(0) · 영어로 넘친 머리 줄 버튼 %s" % [prep[0], prep[1], fight[0], fight[1], sizes, edge, wide])

# EV1118 · S254 2026-11-14 변경: 마을 레벨에 막힌 강화 띠는 «LvN 필요»이고 눌리지 않는다. 설명 상자 이유·마을 레벨 버튼 툴팁, 레벨을 올리면 열린다
func ev1118():
	var main = _live_prep()
	var b = main.view.battle
	var k = _panel(main)
	if not k is Control:
		_done(main)
		return "main.hud.keep이 없다"
	b.gold = BIG
	_open(main)
	var s: Button = k.strips[SHIELD]
	var locked := [b.village_level, s.text, s.disabled]
	var g0: int = b.gold
	s.pressed.emit()
	_frame(main)
	var kept: bool = b.merc_rank.get("shieldman", 0) == 0 and b.gold == g0
	_move(s.get_global_rect().get_center())
	_frame(main)
	_layout(main)
	_frame(main)
	var said := " ".join(_labels(k.info)) if k.info.is_visible_in_tree() else ""
	_move(EMPTY)
	_frame(main)
	var tip := _tip_of(main, k.village)
	k.village.pressed.emit()
	_frame(main)
	var cost: Array = b.MERC_KINDS.shieldman.rank_cost
	var opened := [b.village_level, s.text, s.disabled]
	s.pressed.emit()
	_frame(main)
	var next := [b.merc_rank.get("shieldman", 0), s.text]
	_done(main)
	return check(locked == [1, "Lv2 필요", true] and kept and "✕ 마을 Lv2 필요" in said and "Lv2에 강화 1단계" in tip and opened == [2, "강화 %d" % cost[0], false] and next == [1, "Lv3 필요"],
		"마을 Lv1 띠 %s(1·Lv2 필요·눌리지 않음) · 눌러도 그대로 %s · 설명 상자 «%s»(«✕ 마을 Lv2 필요») · 마을 레벨 버튼 툴팁 «%s»(«Lv2에 강화 1단계») · 올린 뒤 %s(2·강화 %d·눌림) · 띠 누른 뒤 %s(1·Lv3 필요)" % [locked, kept, said, tip, opened, cost[0], next])
