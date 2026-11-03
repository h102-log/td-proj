extends "res://tests/eval/gd/gear.gd"
# 언제든 영입 창·장비 아이콘(S272·S274·I206·I207·I209). lib.gd·hire.gd·save.gd·hud.gd·gear.gd 머리의 계약에 더하는 API:
#   게임 장면 준비·전투 단계: T 키(입력 경로)나 main.hud.shop(BaseButton, 왼쪽 아래 «영입» 버튼)으로 언제든 영입 창(main.hud.window)을 열고 닫는다
#     창 안의 «닫기 (T)» 버튼 · 영입 카드는 글에 이명 «…»이 든 BaseButton이다(카드 안 TextureRect는 장비 작은 아이콘뿐)
#   res://art/gear/gear.png — 장비 아이콘 96×24. y 0에 16×16, y 16에 8×8, 열 차례 GEAR_COLS(I209)
#   아이콘은 AtlasTexture(atlas가 gear.png)를 쓴 TextureRect다. 장비 칸 줄(HBoxContainer)의 첫 TextureRect가 큰 아이콘이다
#   main.hud.portraits[i] 안의 TextureRect 가운데 atlas가 gear.png인 것이 초상 귀퉁이 작은 아이콘이다

const GEAR_PNG := "res://art/gear/gear.png"
const GEAR_COLS := ["aias", "chronos", "ignis", "seraphina", "sylvia", "vesper"]

# 준비 단계 게임 장면(아이아스 출전)
func _shop_prep():
	var main = _game()
	var b = main.view.battle
	b.gold = BIG
	b.offers = ["aias", "", ""]
	b.hire(0)
	b.next_round()
	_frame(main)
	return main

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

# EV653 · S272: T로 열고 닫고, ESC는 ESC 메뉴 대신 창을 닫는다. 창이 떠 있어도 판이 흐르고, 준비·전투 단계를 벗어나면 닫힌다
func ev653():
	var main = _shop_prep()
	var b = main.view.battle
	var w = main.hud.window
	var seen := []
	_key(KEY_T)
	_frame(main)
	seen.append(w.visible and not Engine.get_main_loop().paused)
	_key(KEY_T)
	_frame(main)
	seen.append(not w.visible)
	_key(KEY_T)
	_frame(main)
	_key(KEY_ESCAPE)
	_frame(main)
	seen.append(not w.visible and not Engine.get_main_loop().paused)
	b.start_battle()
	_key(KEY_T)
	_frame(main)
	var t0: float = b.wave_time
	main._process(0.5)
	main.hud._process(0.5)
	seen.append(w.visible and b.state == "battle" and b.wave_time > t0)
	var won := _win(b)
	_frame(main)
	b.next_round()
	_frame(main)
	seen.append(won and b.state == "prep" and not w.visible)
	_done(main)
	return check(seen == [true, true, true, true, true], "[T로 열림·안 멈춤, T로 닫힘, ESC로 닫힘·안 멈춤, 전투 중 판이 흐름, 라운드 뒤 다음 준비 단계에 닫혀 있음] %s" % [seen])

# EV654 · I206: 언제든 영입 창의 모양과, 창이 떠 있는 동안 맵 명령을 받지 않는 것
func ev654():
	var main = _shop_prep()
	var b = main.view.battle
	var hud = main.hud
	var c = main.controls
	var t = b.build("tower", Vector2i(22, 66))
	if t == null:
		_done(main)
		return "준비 단계에 타워를 놓지 못했다"
	click(c, MOUSE_BUTTON_LEFT, px(t.cell))  # 창이 닫혀 있으면 골라진다(재는 것이 헛돌지 않게)
	var picks_closed: bool = not (c.picked + c.selling).is_empty()
	c.picked = []
	c.selling = []
	_key(KEY_1)
	_frame(main)
	var placing_before: bool = c.placing != ""
	_key(KEY_T)
	_frame(main)
	hud.grid._process(0.0)  # 격자는 자기 _process에서 보이기를 정한다(_frame은 돌리지 않는다)
	var out := ""
	var words := " ".join(_labels(hud.window))
	var toggles: Array = hud.window.find_children("*", "BaseButton", true, false).filter(func(n): return n.is_visible_in_tree() and (n.text.ends_with("출전") or n.text.ends_with("대기")))
	if not (picks_closed and placing_before):
		out = "준비가 틀렸다: 창이 닫혀 있을 때 클릭으로 골라짐 %s · 1 키로 놓기 모드 %s" % [picks_closed, placing_before]
	elif not hud.window.visible or hud.dim.visible:
		out = "창 보임 %s · 맵 덮개 보임 %s(창은 보이고 덮개는 없어야 한다)" % [hud.window.visible, hud.dim.visible]
	elif not ("영입" in words and "출전·내보내기는 라운드 사이에" in words) or _focus_text(main) != "닫기 (T)":
		out = "창 글 «%s» · 포커스 «%s»(«영입»·«출전·내보내기는 라운드 사이에»와 «닫기 (T)» 포커스여야 한다)" % [words, _focus_text(main)]
	elif _button(hud.window, "장비") != null or _button(hud.window, "내보내기") != null or hud.window.find_children("*", "BaseButton", true, false).any(func(n): return n.is_visible_in_tree() and "수락" in n.text):
		out = "언제든 영입 창에 «장비»·«내보내기»·의뢰 버튼이 있다"
	elif toggles.is_empty() or toggles.any(func(n): return not n.disabled):
		out = "보유 영웅 출전 전환 버튼 %s(있고 모두 disabled여야 한다)" % [toggles.map(func(n): return [n.text, n.disabled])]
	elif hud.grid.visible or c.placing != "":
		out = "창을 연 뒤 건설 격자 보임 %s · 놓기 모드 «%s»(숨고 꺼져야 한다)" % [hud.grid.visible, c.placing]
	if out == "":
		_key(KEY_1)
		_frame(main)
		click(c, MOUSE_BUTTON_LEFT, px(t.cell))
		_frame(main)
		if c.placing != "" or not (c.picked + c.selling).is_empty():
			out = "창이 열린 동안 1 키에 놓기 모드 «%s» · 타워 클릭에 골라짐 %s(둘 다 없어야 한다)" % [c.placing, c.picked + c.selling]
	if out == "":
		b.offers = ["seraphina", "", ""]
		_frame(main)  # 카드 글은 HUD 프레임에서 목록을 읽어 정한다
		var n: int = b.roster.size()
		var card = hud.window.find_children("*", "BaseButton", true, false).filter(func(x): return x.is_visible_in_tree() and "«" in x.text and not x.disabled)
		if card.is_empty():
			out = "영입 카드가 없다"
		else:
			card[0].pressed.emit()
			out = check(b.roster.size() == n + 1, "카드를 눌렀는데 보유가 %d → %d다" % [n, b.roster.size()])
	_done(main)
	return out

# EV655 · I207: «영입» 버튼 자리·글·보이는 단계, 눌러서 열고 닫기
func ev655():
	var main = _game()
	var b = main.view.battle
	var hud = main.hud
	b.gold = BIG
	var shop = hud.get("shop")
	if not shop is BaseButton:
		_done(main)
		return "main.hud.shop(BaseButton)이 없다"
	var tick := func():  # 버튼은 자기 _process에서 보이기를 정한다(_frame은 돌리지 않는다. 대피령 버튼 평가와 같다)
		_frame(main)
		shop._process(0.0)
	tick.call()
	var seen := [shop.visible]
	b.offers = ["aias", "", ""]
	b.hire(0)
	b.next_round()
	tick.call()
	var words := " ".join(_labels(shop))
	var at := Rect2(shop.position, shop.size)
	seen.append(shop.visible and at == Rect2(3, 238, 60, 26) and "영입" in words and "T" in words)
	shop.pressed.emit()
	tick.call()
	seen.append(hud.window.visible)
	shop.pressed.emit()
	tick.call()
	seen.append(not hud.window.visible)
	b.start_battle()
	tick.call()
	seen.append(shop.visible)
	var won := _win(b)
	tick.call()
	seen.append(won and not shop.visible)
	_done(main)
	return check(seen == [false, true, true, true, true, true], "[영입 창에 보임, 준비 단계 자리·글, 눌러 열림, 다시 눌러 닫힘, 전투 단계 보임, 라운드 사이에 숨음] %s(기대 [false, true, true, true, true, true]) · 자리 %s · 글 «%s»" % [seen, at, words])

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

# EV658 · S274: 장비를 낀 출전 영웅 초상 귀퉁이와, 가방에 장비가 있는 영웅의 영입 카드에 작은 아이콘
func ev658():
	var main = _game()
	var b = main.view.battle
	var hud = main.hud
	b.gold = BIG
	b.offers = ["ignis", "", ""]
	var h = b.hire(0)
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
	_key(KEY_T)
	b.offers = ["seraphina", "chronos", ""]
	b.bag["seraphina"] = 0
	_frame(main)
	var cards := {}
	for n in hud.window.find_children("*", "BaseButton", true, false):
		if n.is_visible_in_tree() and "«" in n.text:
			for k in {"seraphina": "세라피나", "chronos": "크로노스"}:
				if n.text.begins_with({"seraphina": "세라피나", "chronos": "크로노스"}[k]):
					cards[k] = _pics(n).filter(func(r): return r.texture is AtlasTexture and r.texture.atlas != null and r.texture.atlas.resource_path == GEAR_PNG)
	var has: bool = cards.has("seraphina") and cards.seraphina.size() == 1 and _is_icon(cards.seraphina[0], "seraphina", true)
	var none: bool = cards.has("chronos") and cards.chronos.is_empty()
	_done(main)
	return check(worn and bare and has and none, "초상 귀퉁이: 낌 %s · 해제 뒤 없음 %s / 영입 카드: 가방에 있는 세라피나 %s · 없는 크로노스 숨음 %s" % [worn, bare, has, none])
