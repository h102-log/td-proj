extends "res://tests/eval/gd/gear.gd"
# 영웅 고르기 창·장비 아이콘(S373·I303·S274·I209). lib.gd·hire.gd·save.gd·hud.gd·gear.gd 머리의 계약에 더하는 API:
#   게임 장면 고르기 창(main.hud.window, 판 단계 "hiring"): 영웅 카드는 글에 이명 «…»이 든 BaseButton이다(카드 안 TextureRect는 장비 작은 아이콘뿐)
#     카드를 누르면(pressed) 고르고, 고른 카드를 다시 누르면 뺀다. 고른 카드는 button_pressed이고 카드 안 보이는 Label 글이 고른 번호다
#     다 고르기 전에는 «1라운드 시작» 버튼이 disabled이고 main.hud.proceed()와 Enter(입력 경로)가 넘어가지 않는다. 그때 키보드 포커스는 보이는 첫 카드다(I303 ②)
#   준비·전투 단계: «영입» 버튼(main.hud.shop)과 언제든 영입 창은 없다. T 키는 아무 일도 하지 않는다(I303 ⑤)
#   res://art/gear/gear.png — 장비 아이콘 96×24. y 0에 16×16, y 16에 8×8, 열 차례 GEAR_COLS(I209)
#   아이콘은 AtlasTexture(atlas가 gear.png)를 쓴 TextureRect다. 장비 칸 줄(HBoxContainer)의 첫 TextureRect가 큰 아이콘이다
#   main.hud.portraits[i] 안의 TextureRect 가운데 atlas가 gear.png인 것이 초상 귀퉁이 작은 아이콘이다

const GEAR_PNG := "res://art/gear/gear.png"
const GEAR_COLS := ["aias", "chronos", "ignis", "seraphina", "sylvia", "vesper"]

# 장비 k의 아이콘 자리: 큰 것은 y 0의 16×16, 작은 것은 y 16의 8×8
func _icon_rect(k: String, small: bool) -> Rect2:
	var i := GEAR_COLS.find(k)
	return Rect2(i * 8, 16, 8, 8) if small else Rect2(i * 16, 0, 16, 16)

# TextureRect가 장비 k의 아이콘을 보인다
func _is_icon(r, k: String, small: bool) -> bool:
	var t = r.texture
	return t is AtlasTexture and t.atlas != null and t.atlas.resource_path == GEAR_PNG and t.region == _icon_rect(k, small)

# node 아래 보이는 TextureRect
func _pics(node: Node) -> Array:
	return node.find_children("*", "TextureRect", true, false).filter(func(r): return r.is_visible_in_tree())

func _focus_text(main) -> String:
	var f = main.get_viewport().gui_get_focus_owner()
	return f.text if f is BaseButton else ""

# 카드 안 보이는 Label 글을 이은 것(고른 번호, I303 ③). 고르지 않은 카드는 ""
func _num_of(card) -> String:
	return "".join(_labels(card))

# 영웅 종류 k의 보이는 카드. 없으면 null
func _card_of(main, k: String):
	for c in _cards(main.hud.window):
		if c.text.begins_with(main.hud.HEROES[k]):
			return c
	return null

# 한 프레임(_frame)에 더해, 자기 _process에서 보이기를 정하는 HUD 버튼(대피령·전체 오토 같은 것)도 돌린다
func _tick(main) -> void:
	_frame(main)
	for n in main.hud.find_children("*", "BaseButton", true, false):
		if n.get_script() != null and n.has_method("_process"):
			n._process(0.0)

# EV1129 · S373: 고르기 창의 카드 여섯(S97 표 차례), 눌러 고르고 다시 눌러 빼기, 고른 차례 번호, 다 고르면 나머지 카드와 진행 버튼
func ev1129():
	var main = _game()
	var b = main.view.battle
	var hud = main.hud
	_frame(main)
	_layout(main)
	var words := " ".join(_labels(hud.window))
	var cards := _cards(hud.window)
	var go = _starts(hud.window, "1라운드 시작")
	var out := ""
	if b.state != "hiring" or not ("영웅 고르기" in words and "영웅 0/3" in words):
		out = "고르기 창(%s)의 글 «%s»에 «영웅 고르기»·«영웅 0/3»이 없다" % [b.state, words]
	elif cards.size() != HERO_SIX.size():
		out = "보이는 카드가 %d장이다(여섯이어야 한다): %s" % [cards.size(), cards.map(func(c): return c.text)]
	for i in cards.size():
		if out == "" and not cards[i].text.begins_with(hud.HEROES[HERO_SIX[i]]):
			out = "%d번 카드 글이 «%s»다(«%s»로 시작해야 한다 — S97 표 차례)" % [i + 1, cards[i].text, hud.HEROES[HERO_SIX[i]]]
		if out == "" and i > 0 and cards[i].get_global_rect().position.y <= cards[i - 1].get_global_rect().position.y:
			out = "%d번 카드가 앞 카드보다 아래에 있지 않다(%s / %s)" % [i + 1, cards[i - 1].get_global_rect(), cards[i].get_global_rect()]
	if out == "":
		var bad: Array = hud.window.find_children("*", "BaseButton", true, false).filter(func(n): return n.is_visible_in_tree() and ("리롤" in n.text or "내보내기" in n.text or "영입" in n.text)).map(func(n): return n.text)
		if go == null or not go.disabled or not bad.is_empty():
			out = "«1라운드 시작» 버튼 %s(있고 disabled여야 한다) · 글에 «리롤»·«내보내기»·«영입»이 든 버튼 %s(없어야 한다)" % [[go.text, go.disabled] if go else null, bad]
	if out == "":
		var gold: int = b.gold
		cards[4].pressed.emit()
		var picked: bool = _kinds(b.roster) == ["ignis"] and b.gold == gold
		_frame(main)
		out = check(picked and cards[4].button_pressed and _num_of(cards[4]) == "1", "이그니스 카드를 누른 뒤 보유 %s · 골드 %d → %d · 카드 눌린 모양 %s · 카드 안 번호 «%s»(기대 [ignis], 골드 그대로, 눌린 모양, «1»)" % [_kinds(b.roster), gold, b.gold, cards[4].button_pressed, _num_of(cards[4])])
	if out == "":
		cards[0].pressed.emit()
		cards[2].pressed.emit()
		_frame(main)
		var nums: Array = cards.map(func(c): return _num_of(c))
		var off: Array = cards.map(func(c): return c.disabled)
		out = check(_kinds(b.roster) == ["ignis", "aias", "seraphina"] and nums == ["2", "", "3", "", "1", ""] and off == [false, true, false, true, false, true] and not go.disabled,
			"셋을 고른 뒤 보유 %s · 카드 번호 %s(기대 [2, , 3, , 1, ]) · 카드 disabled %s(고르지 않은 셋만) · «1라운드 시작» disabled %s(아니어야)" % [_kinds(b.roster), nums, off, go.disabled])
	if out == "":
		cards[4].pressed.emit()
		_frame(main)
		var nums: Array = cards.map(func(c): return _num_of(c))
		out = check(_kinds(b.roster) == ["aias", "seraphina"] and nums == ["1", "", "2", "", "", ""] and go.disabled and not cards[4].button_pressed,
			"이그니스 카드를 다시 누른 뒤 보유 %s · 카드 번호 %s(기대 [1, , 2, , , ]) · «1라운드 시작» disabled %s(다시 disabled여야)" % [_kinds(b.roster), nums, go.disabled])
	_done(main)
	return out

# EV1130 · S373: 다 고르기 전에는 Enter(포커스가 없을 때 main이 부르는 길)와 진행 버튼 함수가 넘어가지 않는다. 다 고르면 넘어가고, 진 뒤의 새 도전도 고르기 창에서 시작한다
func ev1130():
	var main = _game()
	var b = main.view.battle
	var hud = main.hud
	_frame(main)
	var team := [b.hire(2), b.hire(0)]
	_frame(main)
	main.get_viewport().gui_release_focus()
	_key(KEY_ENTER)
	_frame(main)
	var out := check(b.state == "hiring" and b.roster == team and not team.has(null), "둘만 고른 채 Enter를 넣은 뒤 단계 %s · 보유 %s(hiring이고 고른 둘 그대로여야 한다)" % [b.state, _kinds(b.roster)])
	if out == "":
		hud.proceed()
		out = check(b.state == "hiring", "둘만 고른 채 hud.proceed()를 부른 뒤 단계 %s(hiring이어야 한다)" % b.state)
	if out == "":
		team.append(b.hire(1))
		_frame(main)
		main.get_viewport().gui_release_focus()
		_key(KEY_ENTER)
		_frame(main)
		out = check(b.state == "prep" and b.round_index == 0 and b.heroes == team and not team.has(null), "셋째를 고르고 Enter를 넣은 뒤 단계 %s · 출전 %s(1라운드 준비 단계이고 고른 차례 [seraphina, aias, sylvia]여야 한다)" % [b.state, _kinds(b.heroes)])
	if out == "":
		b.damage(b.base, BIG)
		_frame(main)
		hud._process(1.1)
		hud.proceed()
		var again: bool = b.state == "hiring" and b.roster.is_empty() and b.heroes.is_empty()
		_frame(main)
		var go = _starts(hud.window, "1라운드 시작")
		out = check(again and _cards(hud.window).size() == 6 and go != null and go.disabled, "진 뒤 새 도전: 단계 %s · 보유 %d명 · 보이는 카드 %d장 · «1라운드 시작» %s(고르기 창·보유 없음·카드 여섯·disabled여야 한다)" % [b.state, b.roster.size(), _cards(hud.window).size(), [go.text, go.disabled] if go else null])
	_done(main)
	return out

# EV1131 · I303: 고르기 창의 포커스는 다 고르기 전에 첫 카드, 다 고르면 «1라운드 시작»이다. 준비·전투 단계에는 «영입» 버튼이 없고 T 키가 아무 일도 하지 않는다
func ev1131():
	var main = _game()
	var b = main.view.battle
	var hud = main.hud
	var c = main.controls
	_frame(main)
	var out := check(b.state == "hiring" and _focus_text(main).begins_with(hud.HEROES.aias), "고르기 창이 처음 보인 프레임의 포커스가 «%s»다(첫 카드 «%s…»여야 한다)" % [_focus_text(main), hud.HEROES.aias])
	if out == "":
		for k in ["sylvia", "vesper", "chronos"]:
			var card = _card_of(main, k)
			if card:
				card.pressed.emit()
		_frame(main)
		out = check(b.roster.size() == 3 and _focus_text(main).begins_with("1라운드 시작"), "카드 셋을 누른 뒤 보유 %d · 포커스 «%s»(«1라운드 시작…»이어야 한다)" % [b.roster.size(), _focus_text(main)])
	if out == "":
		b.next_round()
		for phase in ["prep", "battle"]:
			if out != "":
				break
			if phase == "battle":
				b.start_battle()
			_tick(main)
			var at: Array = hud.find_children("*", "BaseButton", true, false).filter(func(n): return n.is_visible_in_tree() and n.get_global_rect().is_equal_approx(Rect2(3, 238, 60, 26))).map(func(n): return " ".join(_labels(n)))
			if b.state != phase or hud.get("shop") != null or not at.is_empty():
				out = "%s 단계(%s): main.hud.shop %s(없어야 한다) · [3,238,60,26]의 보이는 버튼 %s(없어야 한다)" % [phase, b.state, hud.get("shop"), at]
				break
			_key(KEY_2)
			_key(KEY_MINUS)
			_tick(main)
			var before := [c.placing, c.selected.duplicate()]
			_key(KEY_T)
			_tick(main)
			if before[0] == "" or before[1] != [b.heroes[1]]:
				out = "준비가 틀렸다(%s 단계): - 키 뒤 놓기 모드 «%s» · 2 키 뒤 고른 유닛 %s" % [phase, before[0], before[1]]
			elif hud.window.visible or c.placing != before[0] or c.selected != before[1]:
				out = "%s 단계에 T 키를 넣은 뒤 창 보임 %s · 놓기 모드 «%s» → «%s» · 고른 유닛 %s → %s(창이 뜨지 않고 그대로여야 한다)" % [phase, hud.window.visible, before[0], c.placing, before[1], c.selected]
	_done(main)
	return out

# EV656 · I209: 아이콘 그림이 96×24, 팔레트 색만, 반투명 없음, 칸마다 1/4 이상 칠함, 같은 크기끼리 서로 다름
func ev656():
	var img := Image.load_from_file(ProjectSettings.globalize_path(GEAR_PNG))
	if img == null or img.is_empty():
		return "%s를 읽지 못했다" % GEAR_PNG
	if img.get_size() != Vector2i(96, 24):
		return "크기 %s(96×24여야 한다)" % img.get_size()
	var pal: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/art/palettes.json"))
	var ok := {}
	for hexes in [pal.f24p, pal.fx]:
		for h in hexes:
			ok[String(h).to_lower()] = true
	img.convert(Image.FORMAT_RGBA8)
	var bad := []
	for y in 24:
		for x in 96:
			var c := img.get_pixel(x, y)
			var a := roundi(c.a * 255)
			if a != 0 and a != 255:
				bad.append("(%d,%d) 알파 %d" % [x, y, a])
			elif a == 255 and not ok.has(c.to_html(false).to_lower()):
				bad.append("(%d,%d) %s" % [x, y, c.to_html(false)])
	if not bad.is_empty():
		return "팔레트 밖·반투명 픽셀 %d개: %s" % [bad.size(), bad.slice(0, 5)]
	var thin := []
	for small in [false, true]:
		var cells := []
		for k in GEAR_COLS:
			var part := img.get_region(Rect2i(_icon_rect(k, small)))
			var used := 0
			for y in part.get_height():
				for x in part.get_width():
					used += int(part.get_pixel(x, y).a > 0.5)
			if used * 4 < part.get_width() * part.get_height():
				thin.append("%s %s %d칸" % [k, "작은" if small else "큰", used])
			cells.append(part.get_data())
		for i in cells.size():
			for j in range(i + 1, cells.size()):
				if cells[i] == cells[j]:
					thin.append("%s와 %s의 %s 아이콘이 같다" % [GEAR_COLS[i], GEAR_COLS[j], "작은" if small else "큰"])
	return check(thin.is_empty(), "덜 칠했거나 같은 아이콘: %s" % [thin])

# EV657 · S274: 장비 칸 줄 머리 큰 아이콘(없는 장비는 0.35)과 라운드 승리 창 전리품 줄의 큰 아이콘
func ev657():
	var main = _game()
	var b = main.view.battle
	var hud = main.hud
	b.gold = BIG
	b.offers = ["aias", "", ""]
	b.hire(0)
	b.next_round()
	var out := check(_win(b) and not b.dropped.is_empty(), "1라운드 승리 뒤 전리품이 없다(%s)" % b.state)
	if out == "":
		_frame(main)
		var k: String = b.dropped[0]
		out = check(_pics(hud.window).any(func(r): return _is_icon(r, k, false)), "라운드 승리 창에 전리품 %s의 큰 아이콘이 없다" % k)
	if out == "":
		_press(hud.window, "장비")
		_frame(main)
		var seen := {}
		for row in hud.window.find_children("*", "HBoxContainer", true, false):
			if not row.is_visible_in_tree():
				continue
			var line := " ".join(_labels(row))
			for g in b.GEAR_KINDS:
				if line.begins_with(b.GEAR_KINDS[g].title):
					var pics: Array = row.find_children("*", "TextureRect", true, false)
					var first = pics[0] if not pics.is_empty() else null
					seen[g] = first != null and first.is_visible_in_tree() and _is_icon(first, g, false) and is_equal_approx(first.modulate.a, 1.0 if b.bag.has(g) else 0.35)
		var want := {}
		for g in b.GEAR_KINDS:
			want[g] = true
		out = check(seen == want and b.bag.size() < b.GEAR_KINDS.size(), "장비 줄마다 머리 아이콘이 맞음 %s · 가방 %s(모두 참이고, 없는 장비도 있어야 한다)" % [seen, b.bag])
	_done(main)
	return out

# EV658 · S274: 장비를 낀 출전 영웅 초상 귀퉁이와, 가방에 장비가 있는 영웅의 고르기 창 카드에 작은 아이콘
func ev658():
	var main = _game()
	var b = main.view.battle
	var hud = main.hud
	b.gold = BIG
	b.offers = ["seraphina", "chronos", "ignis"]
	b.bag["seraphina"] = 0
	_frame(main)
	var cards := {}
	for n in _cards(hud.window):
		for k in ["seraphina", "chronos"]:
			if n.text.begins_with(hud.HEROES[k]):
				cards[k] = _pics(n).filter(func(r): return r.texture is AtlasTexture and r.texture.atlas != null and r.texture.atlas.resource_path == GEAR_PNG)
	var has: bool = cards.has("seraphina") and cards.seraphina.size() == 1 and _is_icon(cards.seraphina[0], "seraphina", true)
	var none: bool = cards.has("chronos") and cards.chronos.is_empty()
	var h = b.hire(2)
	b.next_round()
	b.bag["ignis"] = 2
	h.worn = true
	_frame(main)
	var corner := func(): return _pics(hud.portraits[0]).filter(func(r): return r.texture is AtlasTexture and r.texture.atlas != null and r.texture.atlas.resource_path == GEAR_PNG)
	var on: Array = corner.call()
	var worn: bool = on.size() == 1 and _is_icon(on[0], "ignis", true)
	h.worn = false
	_frame(main)
	var bare: bool = corner.call().is_empty()
	_done(main)
	return check(worn and bare and has and none, "초상 귀퉁이: 낌 %s · 해제 뒤 없음 %s / 고르기 창 카드: 가방에 있는 세라피나 %s · 없는 크로노스 숨음 %s" % [worn, bare, has, none])

# EV880 · S313·I259: «전체 오토» 버튼의 자리·글·툴팁·보이는 단계, 눌러서 모두 켜고 끄기, 모두 켜진 동안 금색 테두리
func ev880():
	var main = _game()
	var b = main.view.battle
	var hud = main.hud
	b.gold = BIG
	var btn = hud.get("auto_all")
	if not btn is BaseButton:
		_done(main)
		return "main.hud.auto_all(BaseButton)이 없다"
	var tick := func():  # 버튼은 자기 _process에서 보이기·테두리를 정한다(_frame은 돌리지 않는다. 대피령 버튼 평가와 같다)
		_frame(main)
		btn._process(0.0)
	tick.call()
	var seen := [btn.visible]
	b.offers = ["aias", "", ""]
	b.hire(0)
	b.next_round()
	var k = b.heroes[0]
	for s in k.auto:
		k.auto[s] = false
	tick.call()
	var words := " ".join(_labels(btn))
	var at := Rect2(btn.position, btn.size)
	var tipped := _tip_of(main, btn)
	seen.append(btn.visible and at == Rect2(3, 210, 60, 26) and "오토" in words and tipped.begins_with("전체 오토"))
	btn.pressed.emit()
	tick.call()
	var box = btn.get_theme_stylebox("normal") if btn.has_theme_stylebox_override("normal") else null
	var gold: Color = load("res://src/ui/hud_theme.gd").ACCENT
	seen.append(k.auto.values().all(func(v): return v) and box is StyleBoxFlat and box.border_color == gold)
	btn.pressed.emit()
	tick.call()
	seen.append(k.auto.values().all(func(v): return not v) and not btn.has_theme_stylebox_override("normal"))
	b.start_battle()
	tick.call()
	seen.append(btn.visible)
	_done(main)
	return check(seen == [false, true, true, true, true], "[영입 창에 숨음, 준비 단계 자리·글·툴팁, 눌러 모두 켬·금색 테두리, 다시 눌러 모두 끔, 전투 단계 보임] %s(기대 [false, true, true, true, true]) · 자리 %s · 글 «%s» · 툴팁 «%s» · 오토 %s" % [seen, at, words, tipped, k.auto])
