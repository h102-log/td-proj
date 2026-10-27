extends "res://tests/eval/gd/save.gd"
# WBS 4.2 메뉴·설정(S163·S182~S184·I158~I160). save.gd 머리의 계약에 더하는 API:
#   res://src/menu.tscn — 진입 장면(메인 메뉴). 붙일 때 저장이 있는지 보고 «이어하기»를 켠다
#     «새 게임»(저장이 있으면 확인 창 «취소»·«지우고 새 게임»)·«이어하기»·«설정»·«종료»
#   설정 화면: 켜고 끄는 버튼 «퀵캐스트»·«부활»·«전체화면», 글자 «음량» 옆의 HSlider(0~100, 10씩), «뒤로»
#     글자 «카메라 속도» 옆의 HSlider(50~200, 25씩, S184). 음량 슬라이더보다 뒤에 있다(첫 슬라이더가 음량이다)
#   res://src/settings.gd — static var camera_speed(%, 기본 100)
#   res://src/settings.gd — static var shake(화면 흔들림 0 끔·1 약하게·2 보통, 기본 2, S200) · soft_flash(번쩍임 줄이기, 기본 false, S184)
#     설정 화면: 글자 «화면 흔들림» 옆의 OptionButton(항목 «끔»·«약하게»·«보통», «언어» OptionButton보다 뒤), 켜고 끄는 «번쩍임 줄이기»
#   게임 장면의 맵 카메라(Camera2D) — offset이 화면 흔들림(기준 화면 정수 px ÷ 줌), steady() -> Transform2D는 흔들림을 뺀 캔버스 변환(S200)
#   res://src/settings.gd — static var quickcast · revive · fullscreen(null이면 아직 고르지 않음) · volume(0~100)
#     load_file()(파일이 없으면 기본값) · save_file() · fullscreen_at_start(내보낸 빌드) -> bool
#   Controls.quickcast — 퀵캐스트(I158) · Battle.revive — 부활(I28)
#   언어(S193, I167): settings.gd static var language(«ko»·«en») · static default_language(OS 언어) -> String.
#     설정 화면의 보이는 OptionButton 하나가 «언어» 항목이다(항목 글 «한국어»·«English»). 고르면 item_selected로 저장·적용한다

func _settings():
	_save()
	var st = load("res://src/settings.gd")
	if FileAccess.file_exists(st.path):
		DirAccess.remove_absolute(st.path)
	st.load_file()
	return st

# 붙인 메인 메뉴 장면
func _menu():
	_save()
	var m = load("res://src/menu.tscn").instantiate()
	Engine.get_main_loop().root.add_child(m)
	return m

func _focus():
	return Engine.get_main_loop().root.gui_get_focus_owner()

# 보이는 글자(Label·버튼) 가운데 part가 든 것이 있다
func _says(node: Node, part: String) -> bool:
	for n in node.find_children("*", "Control", true, false):
		if n.is_visible_in_tree() and (n is Label or n is BaseButton) and part in n.text:
			return true
	return false

func _slider(node: Node):
	for n in node.find_children("*", "HSlider", true, false):
		if n.is_visible_in_tree():
			return n
	return null

# 보이는 조작 요소가 모두 글자가 있고 키보드 포커스를 받는다. 어긋난 것을 설명하는 문장, 없으면 ""
func _reachable(node: Node, page: String) -> String:
	for n in node.find_children("*", "Control", true, false):
		if not n.is_visible_in_tree() or not (n is BaseButton or n is Range):
			continue
		if n.focus_mode != Control.FOCUS_ALL:
			return "%s의 %s가 키보드 포커스를 받지 않는다" % [page, n.get("text") if n is BaseButton else n.get_class()]
		if n is BaseButton and n.text == "":
			return "%s에 글자 없는 버튼이 있다" % page
		if n is Range and not n.get_parent().get_children().any(func(s): return s is Label and s.text in ["음량", "카메라 속도"]):
			return "%s의 슬라이더 옆에 «음량»이나 «카메라 속도» 글자가 없다" % page
	return ""

# EV310 · S182: 메인 메뉴의 네 버튼, 이어하기 켜짐·포커스, 새 게임 확인 창
func ev310():
	var S = _save()
	S.erase()
	var m = _menu()
	for t in ["새 게임", "이어하기", "설정", "종료"]:
		if _button(m, t) == null:
			m.free()
			return "저장 없는 메인 메뉴에 «%s»가 없다" % t
	var why := ""
	if not _button(m, "이어하기").disabled:
		why = "저장이 없는데 «이어하기»가 눌린다"
	elif _focus() != _button(m, "새 게임"):
		why = "저장이 없을 때 포커스가 «새 게임»이 아니다"
	m.free()
	if why != "":
		return why
	S.write(battle())
	m = _menu()
	if _button(m, "이어하기").disabled or _focus() != _button(m, "이어하기"):
		why = "저장이 있는데 «이어하기»가 눌리지 않거나 포커스가 없다"
	elif not _press(m, "새 게임") or not _says(m, "지워") or _focus() != _button(m, "취소"):
		why = "저장이 있을 때 «새 게임»이 «지워» 확인 창(포커스 «취소»)을 열지 않는다"
	elif S.read().is_empty():
		why = "확인 전에 저장이 지워졌다"
	elif not _press(m, "취소") or _button(m, "새 게임") == null:
		why = "«취소» 뒤 메인 메뉴로 돌아가지 않았다"
	elif not _press(m, "새 게임") or not _press(m, "지우고 새 게임"):
		why = "확인 창에 «지우고 새 게임»이 없다"
	elif not S.read().is_empty():
		why = "«지우고 새 게임» 뒤에도 저장이 있다"
	m.free()
	return why

# EV311 · S183, I11: ESC 메뉴가 뜨고 트리가 멈춘다. 전투 단계에만 «저장되지 않습니다» 안내
func ev311():
	var main = _game()
	var b = main.view.battle
	b.next_round()
	_frame(main)
	_key(KEY_ESCAPE)
	var why := ""
	for t in ["계속", "설정", "메인 메뉴로", "게임 종료"]:
		if _button(main, t) == null:
			why = "ESC 메뉴에 «%s»가 없다" % t
	if why == "" and (not main.get_tree().paused or main.can_process()):
		why = "ESC 메뉴가 떠도 게임이 멈추지 않는다"
	elif why == "" and _focus() != _button(main, "계속"):
		why = "포커스가 «계속»이 아니다"
	elif why == "" and _says(main, "저장되지 않습니다"):
		why = "준비 단계 메뉴에 «저장되지 않습니다»가 보인다"
	if why == "":
		_key(KEY_ESCAPE)
		if _button(main, "계속") != null or main.get_tree().paused:
			why = "메뉴에서 ESC를 눌러도 닫히지 않는다"
	if why == "":
		b.start_battle()
		_key(KEY_ESCAPE)
		if not _says(main, "저장되지 않습니다"):
			why = "전투 단계 메뉴에 «저장되지 않습니다»가 없다"
	_done(main)
	return why

# EV312 · S183: 조준·놓기 모드의 ESC는 그것만 취소하고 메뉴를 열지 않는다
func ev312():
	var main = _game()
	var b = main.view.battle
	b.gold = BIG
	b.offers[0] = "ignis"
	b.hire(0)
	b.next_round()
	_frame(main)
	b.start_battle()
	var why := ""
	_key(KEY_Q)
	if main.controls.aiming != "q":
		why = "Q 키로 조준 상태가 되지 않았다"
	else:
		_key(KEY_ESCAPE)
		if main.controls.aiming != "" or main.get_tree().paused or _button(main, "계속") != null:
			why = "조준 중 ESC가 조준만 풀지 않았다"
	if why == "":
		_key(KEY_1)
		if main.controls.placing != "wall":
			why = "1 키로 놓기 모드가 되지 않았다"
		else:
			_key(KEY_ESCAPE)
			if main.controls.placing != "" or main.get_tree().paused or _button(main, "계속") != null:
				why = "놓기 모드의 ESC가 놓기 모드만 끝내지 않았다"
	_done(main)
	return why

# 이그니스가 있는 판의 전투 단계와 그 Controls. 마우스는 이그니스 4칸 오른쪽 칸 위에 있다
func _ignis(quick: bool) -> Array:
	var b = battle({"heroes": [{"kind": "ignis", "cell": Vector2i(10, 10)}], "waves": [[{"kind": "basic", "count": 1}]]})
	b.start_battle()
	var c = controls(b)
	c.quickcast = quick
	var e := InputEventMouseMotion.new()
	e.position = (Vector2(14, 10) + Vector2(0.5, 0.5)) * CELL_PX
	c.handle(e)
	return [b, c]

# EV314 · I158: 퀵캐스트는 키를 누르는 순간 커서 칸에 쓴다. 꺼져 있거나 HUD 버튼 경로면 조준 상태만 된다
func ev314():
	var bc := _ignis(true)
	var h = bc[0].hero
	_key_to(bc[1], KEY_Q)
	if bc[1].aiming != "" or h.mana >= h.max_mana or h.cd.q <= 0.0:
		return "퀵캐스트를 켜도 Q 키가 바로 쓰지 않았다(조준 «%s», 마나 %.0f, 대기 %.1f)" % [bc[1].aiming, h.mana, h.cd.q]
	bc = _ignis(false)
	h = bc[0].hero
	_key_to(bc[1], KEY_Q)
	if bc[1].aiming != "q" or h.mana < h.max_mana:
		return "퀵캐스트를 끄면 Q 키가 조준 상태만 만들어야 한다"
	bc = _ignis(true)
	h = bc[0].hero
	bc[1].skill_for(h, "q")
	if bc[1].aiming != "q" or h.mana < h.max_mana:
		return "퀵캐스트를 켜도 HUD 버튼 경로는 조준 상태만 만들어야 한다"
	return ""

func _key_to(c, code: int) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = true
	c.handle(e)

# EV315 · S184: 설정 기본값·저장·불러오기, 두 메뉴의 설정 화면
func ev315():
	var st = _settings()
	st.quickcast = true
	st.revive = false
	st.fullscreen = true
	st.volume = 5
	st.load_file()
	if [st.quickcast, st.revive, st.fullscreen, st.volume] != [false, true, null, 100]:
		return "설정 파일이 없을 때 기본값이 아니다: %s" % [[st.quickcast, st.revive, st.fullscreen, st.volume]]
	st.quickcast = true
	st.revive = false
	st.fullscreen = false
	st.volume = 30
	st.save_file()
	st.quickcast = false
	st.revive = true
	st.fullscreen = null
	st.volume = 100
	st.load_file()
	var got := [st.quickcast, st.revive, st.fullscreen, st.volume]
	_settings()
	if got != [true, false, false, 30]:
		return "저장한 설정을 다시 읽은 값이 다르다: %s" % [got]
	var m = _menu()
	var why := _settings_page(m, "메인 메뉴")
	m.free()
	if why != "":
		return why
	var main = _game()
	main.view.battle.next_round()
	_frame(main)
	_key(KEY_ESCAPE)
	why = _settings_page(main, "ESC 메뉴")
	_done(main)
	return why

func _settings_page(node: Node, where: String) -> String:
	if not _press(node, "설정"):
		return "%s에 «설정»이 없다" % where
	for t in ["퀵캐스트", "부활", "전체화면"]:
		if not _button(node, t) is CheckButton:
			return "%s의 설정에 켜고 끄는 «%s»가 없다" % [where, t]
	return "" if _slider(node) != null else "%s의 설정에 음량 슬라이더가 없다" % where

# EV316 · I160: 바꾼 설정이 진행 중인 판·Controls·마스터 버스에 바로 걸린다
func ev316():
	_settings()
	var main = _game()
	var b = main.view.battle
	b.next_round()
	_frame(main)
	_key(KEY_ESCAPE)
	_press(main, "설정")
	var why := ""
	var revive = _button(main, "부활")
	var quick = _button(main, "퀵캐스트")
	var vol = _slider(main)
	if revive == null or quick == null or vol == null:
		why = "ESC 메뉴 설정에 «부활»·«퀵캐스트»·음량이 없다"
	else:
		revive.button_pressed = false
		quick.button_pressed = true
		if b.revive:
			why = "«부활»을 꺼도 판의 revive가 켜져 있다"
		elif not main.controls.quickcast:
			why = "«퀵캐스트»를 켜도 Controls의 quickcast가 꺼져 있다"
		else:
			vol.value = 30
			if not is_equal_approx(AudioServer.get_bus_volume_db(0), linear_to_db(0.3)):
				why = "음량 30의 마스터 버스 음량이 %.2f dB다" % AudioServer.get_bus_volume_db(0)
			vol.value = 0
			if why == "" and not AudioServer.is_bus_mute(0):
				why = "음량 0인데 마스터 버스가 음소거가 아니다"
			vol.value = 100
	_done(main)
	_settings()
	return why

# EV317 · I159: 메뉴의 글자·포커스, 설정의 ESC, 음량 방향키, 메인 메뉴의 ESC
func ev317():
	_settings()
	var S = _save()
	S.write(battle())
	var m = _menu()
	var why := _reachable(m, "메인 메뉴")
	if why == "":
		var before = _focus()
		_key(KEY_ESCAPE)
		if _button(m, "새 게임") == null or _focus() != before:
			why = "메인 메뉴에서 ESC가 무언가를 바꿨다"
	if why == "":
		_press(m, "새 게임")
		why = _reachable(m, "확인 창")
		_press(m, "취소")
	if why == "":
		_press(m, "설정")
		why = _reachable(m, "메인 메뉴 설정")
	if why == "":
		var vol = _slider(m)
		vol.value = 50
		vol.grab_focus()
		_key(KEY_RIGHT)
		var up: float = vol.value
		_key(KEY_LEFT)
		if up != 60 or vol.value != 50:
			why = "음량 → 키 뒤 %d, ← 키 뒤 %d(기대 60, 50)" % [up, vol.value]
	if why == "":
		_key(KEY_ESCAPE)
		if _button(m, "새 게임") == null or _focus() != _button(m, "설정"):
			why = "설정에서 ESC가 메인 메뉴의 «설정»으로 돌아가지 않았다"
	m.free()
	S.erase()
	if why != "":
		_settings()
		return why
	var main = _game()
	main.view.battle.next_round()
	_frame(main)
	_key(KEY_ESCAPE)
	why = _reachable(main.menus, "ESC 메뉴")  # 메뉴 뒤의 HUD 버튼은 재지 않는다
	if why == "":
		_press(main, "설정")
		why = _reachable(main.menus, "ESC 메뉴 설정")
	if why == "":
		_key(KEY_ESCAPE)
		if _button(main, "계속") == null or _focus() != _button(main, "설정"):
			why = "설정에서 ESC가 ESC 메뉴의 «설정»으로 돌아가지 않았다"
	_done(main)
	_settings()
	return why

# EV318 · S163: 시작 창 모드는 저장된 값이 있으면 그 값, 없으면 내보낸 빌드 전체화면·편집기 창
func ev318():
	var st = _settings()
	var got := []
	for v in [null, false, true]:
		st.fullscreen = v
		got.append([st.fullscreen_at_start(true), st.fullscreen_at_start(false)])
	st.fullscreen = null
	return "" if got == [[true, false], [false, false], [true, true]] else "[내보낸, 편집기] 시작 전체화면이 (없음·창·전체화면)마다 %s다" % [got]

# EV370 · S193: 언어 기본값은 OS 언어가 한국어면 ko, 아니면 en이고, 저장한 언어는 OS 언어보다 앞선다
func ev370():
	var st = _settings()
	var got := []
	for os in ["ko_KR", "ko", "en_US", "ja_JP", ""]:
		got.append(st.default_language(os))
	var out := check(got == ["ko", "ko", "en", "en", "en"], "OS 언어 [ko_KR, ko, en_US, ja_JP, «»]의 기본값 %s(기대: [ko, ko, en, en, en])" % [got])
	for want in ["en", "ko"]:
		if out != "":
			break
		st.language = want
		st.save_file()
		st.language = "?"
		st.load_file()
		out = check(st.language == want, "language «%s»를 저장하고 다시 읽은 값 «%s»" % [want, st.language])
	_settings()
	return out

# EV371 · S193: 설정 «언어»로 English를 고르면 저장·적용되어 메인 메뉴 화면 글에 한글이 없고, 한국어로 돌아오면 «새 게임»이 보인다
func ev371():
	var st = _settings()
	st.language = "ko"
	TranslationServer.set_locale("ko")
	var m = _menu()
	var out := _ev371(m, st)
	m.free()
	TranslationServer.set_locale("ko")
	_settings()
	return out

func _ev371(m, st) -> String:
	if not _press(m, "설정"):
		return "메인 메뉴에 «설정»이 없다"
	var pick = _option(m)
	if pick == null:
		return "설정 화면에 «언어» OptionButton이 없다"
	if pick.get_item_text(pick.selected) != "한국어":
		return "언어 항목의 고른 값 «%s»(기대: «한국어»)" % pick.get_item_text(pick.selected)
	if not _choose(pick, "English"):
		return "언어 항목에 «English»가 없다"
	st.language = "?"
	st.load_file()
	if st.language != "en" or TranslationServer.get_locale() != "en":
		return "English를 고른 뒤 설정 파일 language «%s» · 번역 언어 «%s»(기대: en · en)" % [st.language, TranslationServer.get_locale()]
	_press(m, "뒤로")
	var ko := _hangul(m)
	if ko != "":
		return "English를 고르고 돌아온 메인 메뉴 화면 글에 한글이 있다: «%s»" % ko
	_press(m, "설정")
	if not _choose(_option(m), "한국어"):
		return "다시 연 설정에서 «한국어»를 고르지 못했다"
	_press(m, "뒤로")
	return check(_shows(m, "새 게임"), "한국어를 고르고 돌아온 메인 메뉴 화면 글에 «새 게임»이 없다")

func _option(node: Node):
	for n in node.find_children("*", "OptionButton", true, false):
		if n.is_visible_in_tree():
			return n
	return null

# 사람이 고른 것처럼 항목 text를 고른다(select는 item_selected를 내지 않는다)
func _choose(pick, text: String) -> bool:
	for i in (pick.item_count if pick else 0):
		if pick.get_item_text(i) == text:
			pick.select(i)
			pick.item_selected.emit(i)
			return true
	return false

# 보이는 Label·Button의 화면 글(자동 번역을 거친 글)
func _screen_texts(node: Node) -> Array:
	var out := []
	for n in node.find_children("*", "Control", true, false):
		if n.is_visible_in_tree() and (n is Label or n is Button):
			out.append(n.atr(n.text))
	return out

# 화면 글 가운데 한글이 든 첫 글. 없으면 ""
func _hangul(node: Node) -> String:
	var re := RegEx.create_from_string("[가-힣]")
	for t in _screen_texts(node):
		if re.search(t):
			return t
	return ""

func _shows(node: Node, part: String) -> bool:
	return _screen_texts(node).any(func(t): return part in t)

# 글자 text 옆의 보이는 슬라이더
func _slider_by(node: Node, text: String):
	for n in node.find_children("*", "HSlider", true, false):
		if n.is_visible_in_tree() and n.get_parent().get_children().any(func(s): return s is Label and s.text == text):
			return n
	return null

# node의 «설정»을 눌러 «카메라 속도» 슬라이더가 50~200·25씩이고 값이 want인지 본다. 어긋난 것을 설명하는 문장, 없으면 ""
func _camera_row(node: Node, where: String, want: int) -> String:
	if not _press(node, "설정"):
		return "%s에 «설정»이 없다" % where
	var s = _slider_by(node, "카메라 속도")
	if s == null:
		return "%s의 설정에 «카메라 속도» 슬라이더가 없다" % where
	if [s.min_value, s.max_value, s.step, s.value] != [50.0, 200.0, 25.0, float(want)]:
		return "%s의 카메라 속도 슬라이더가 %s다(기대 범위 50~200·25씩·값 %d)" % [where, [s.min_value, s.max_value, s.step, s.value], want]
	return ""

# EV390 · S184: 카메라 속도 설정의 기본값·저장·불러오기, 두 메뉴의 «카메라 속도» 슬라이더
func ev390():
	var st = _settings()
	if st.get("camera_speed") != 100:
		return "설정 파일이 없을 때 카메라 속도가 %s다(기대 100)" % st.get("camera_speed")
	st.camera_speed = 50
	st.save_file()
	st.camera_speed = 100
	st.load_file()
	if st.camera_speed != 50:
		_settings()
		return "저장한 카메라 속도 50을 다시 읽으니 %d다" % st.camera_speed
	var m = _menu()
	var why := _camera_row(m, "메인 메뉴", 50)
	m.free()
	if why == "":
		var main = _game()
		main.view.battle.next_round()
		_frame(main)
		_key(KEY_ESCAPE)
		why = _camera_row(main, "ESC 메뉴", 50)
		if why == "":
			_slider_by(main, "카메라 속도").value = 150
			st.camera_speed = 100
			st.load_file()
			if st.camera_speed != 150:
				why = "ESC 메뉴에서 150으로 바꾼 카메라 속도를 다시 읽으니 %d다" % st.camera_speed
		_done(main)
	_settings()
	return why

# 글자 text 옆의 보이는 OptionButton
func _option_by(node: Node, text: String):
	for n in node.find_children("*", "OptionButton", true, false):
		if n.is_visible_in_tree() and n.get_parent().get_children().any(func(s): return s is Label and s.text == text):
			return n
	return null

# node의 «설정»을 눌러 «화면 흔들림» 고르기가 끔·약하게·보통이고 want번이 골라져 있는지 본다. 어긋난 것을 설명하는 문장, 없으면 ""
func _shake_row(node: Node, where: String, want: int) -> String:
	if not _press(node, "설정"):
		return "%s에 «설정»이 없다" % where
	var o = _option_by(node, "화면 흔들림")
	if o == null:
		return "%s의 설정에 «화면 흔들림» 고르기가 없다" % where
	var items: Array = range(o.item_count).map(func(i): return o.get_item_text(i))
	if items != ["끔", "약하게", "보통"] or o.selected != want:
		return "%s의 화면 흔들림 항목이 %s이고 %d번이 골라져 있다(기대 끔·약하게·보통, %d번)" % [where, items, o.selected, want]
	return ""

# 화면 흔들림을 level로 두고 1라운드 전투 단계에서 정문 바로 왼쪽 성곽 칸을 무너뜨린 뒤 main을 1/60초씩 돌린다.
# [처음 3프레임의 카메라 offset × 줌 길이 가운데 가장 큰 값(정수가 아니면 -1), 0.35초 뒤 그 길이, 흔들리는 동안 steady()가 offset 0의 캔버스 변환과 같았나]
func _shake_run(level: int) -> Array:
	load("res://src/settings.gd").shake = level
	var main = _game()
	var b = main.view.battle
	b.gold = 1 << 20
	for i in 2:
		b.hire(i)
	b.next_round()
	_frame(main)
	b.start_battle()
	_frame(main)
	var gate = b.castle.values().filter(func(k): return k.kind == "gate" and absi(k.cell.x - b.base.cell.x) <= 1 and k.cell.y > b.base.cell.y)[0]
	b.damage(b.castle[gate.cell + Vector2i.LEFT], 1e9, "true")
	var cam = main.find_children("*", "Camera2D", true, false)[0]
	var top := 0
	var steady := true
	for i in 21:
		main._process(1.0 / 60.0)
		var o: Vector2 = cam.offset * cam.zoom.x
		if i < 3:
			top = top if top < 0 else (-1 if not o.is_equal_approx(o.round()) else maxi(top, roundi(o.length())))
		if cam.offset != Vector2.ZERO and cam.has_method("steady"):
			var keep: Vector2 = cam.offset
			var got: Transform2D = cam.steady()
			cam.offset = Vector2.ZERO
			cam.force_update_scroll()
			steady = steady and got.is_equal_approx(cam.get_viewport().get_canvas_transform())
			cam.offset = keep
			cam.force_update_scroll()
	var end: float = (cam.offset * cam.zoom.x).length()
	_done(main)
	return [top, end, steady]

# EV386 · S200: «화면 흔들림» 설정의 기본값·저장·불러오기, 두 메뉴의 고르기, 성곽 칸 붕괴 흔들림(보통 3px·약하게 2px·끔 0)과 흔들림을 뺀 변환
func ev386():
	var st = _settings()
	if st.get("shake") != 2:
		return "설정 파일이 없을 때 화면 흔들림이 %s다(기대 2, 보통)" % st.get("shake")
	st.shake = 1
	st.save_file()
	st.shake = 2
	st.load_file()
	if st.shake != 1:
		_settings()
		return "저장한 화면 흔들림 1(약하게)을 다시 읽으니 %d다" % st.shake
	var m = _menu()
	var why := _shake_row(m, "메인 메뉴", 1)
	m.free()
	if why == "":
		var main = _game()
		main.view.battle.next_round()
		_frame(main)
		_key(KEY_ESCAPE)
		why = _shake_row(main, "ESC 메뉴", 1)
		_done(main)
	if why == "":
		var got := {}
		for level in [2, 1, 0]:
			got[level] = _shake_run(level)
		if got[2] != [3, 0.0, true] or got[1].slice(0, 2) != [2, 0.0] or got[0].slice(0, 2) != [0, 0.0]:
			why = "성곽 칸 붕괴 뒤 [처음 3프레임의 가장 큰 흔들림, 0.35초 뒤 흔들림, steady가 흔들림을 뺐나]가 보통 %s · 약하게 %s · 끔 %s다(기대 [3, 0, true] · [2, 0] · [0, 0], 정수가 아니면 -1)" % [got[2], got[1], got[0]]
	_settings()
	return why

# node의 «설정»을 눌러 «번쩍임 줄이기» 켜고 끄는 항목을 찾는다. 없으면 null
func _flash_box(node: Node):
	if not _press(node, "설정"):
		return null
	var box = _button(node, "번쩍임 줄이기")
	return box if box is CheckButton else null

# EV542 · S184: «번쩍임 줄이기» 설정의 기본값·저장·불러오기와 두 메뉴의 켜고 끄는 항목
func ev542():
	var st = _settings()
	if st.get("soft_flash") != false:
		return "설정 파일이 없을 때 번쩍임 줄이기가 %s다(기대 꺼짐)" % st.get("soft_flash")
	st.soft_flash = true
	st.save_file()
	st.soft_flash = false
	st.load_file()
	if st.soft_flash != true:
		_settings()
		return "저장한 번쩍임 줄이기 켬을 다시 읽으니 %s다" % st.soft_flash
	var m = _menu()
	var box = _flash_box(m)
	var why := "" if box != null and box.button_pressed else "메인 메뉴 설정에 켜진 «번쩍임 줄이기» 항목이 없다(%s)" % box
	m.free()
	if why == "":
		st.soft_flash = false
		st.save_file()
		var main = _game()
		main.view.battle.next_round()
		_frame(main)
		_key(KEY_ESCAPE)
		box = _flash_box(main)
		if box == null or box.button_pressed:
			why = "ESC 메뉴 설정에 꺼진 «번쩍임 줄이기» 항목이 없다(%s)" % box
		else:
			box.button_pressed = true
			st.soft_flash = false
			st.load_file()
			if st.soft_flash != true:
				why = "ESC 메뉴에서 켠 번쩍임 줄이기를 다시 읽으니 %s다" % st.soft_flash
		_done(main)
	_settings()
	return why
