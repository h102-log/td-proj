extends "res://tests/eval/gd/save.gd"
# WBS 4.1g HUD 개편(S187·I162). save.gd 머리의 계약에 더하는 API:
#   main.hud.bar — HUD 위 띠(Control). 그 안의 보이는 BaseButton이 «위 띠의 조작»이다
#   main.hud.tip — 툴팁 패널(Control, I162). visible · get_global_rect() · _process(delta)로 시간을 흘린다
#     tip.reason — 빨간 이유 줄(Label). 못 쓰는 조건이 없으면 숨는다
# 커서는 화면(640×360) 좌표의 InputEventMouseMotion으로 옮긴다. 빈 맵 자리는 (320,300)이다

const EMPTY := Vector2(320, 300)
const QNAME := {"aias": "방패 강타", "sylvia": "관통의 바람살", "seraphina": "성스러운 빛줄기", "vesper": "부식의 독안개", "ignis": "화염구 작렬", "chronos": "무기 과충전"}  # S97 표의 Q

# 영웅 둘을 영입해 출전시키고 1라운드 준비 단계로 간 게임 장면
func _prep():
	var main = _game()
	var b = main.view.battle
	b.gold = BIG
	for i in 2:
		b.hire(i)
	b.next_round()
	_frame(main)
	_layout(main)
	return main

# 컨테이너 배치는 다음 프레임으로 미뤄지는데 평가는 한 프레임 안에서 돈다. 위에서부터 직접 정렬한다(안 하면 버튼이 모두 (0,0)이다).
# 두 번 돈다. 줄바꿈 줄(HFlow)의 높이는 자기 정렬 뒤에 정해져서, 한 번이면 그 아래 영웅 줄이 둘째 줄 버튼 위에 겹친다
func _layout(main) -> void:
	for i in 2:
		for c in main.hud.find_children("*", "Container", true, false):
			c.notification(Container.NOTIFICATION_SORT_CHILDREN)

func _move(at: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = at
	e.global_position = at
	Engine.get_main_loop().root.push_input(e, true)

func _bar_buttons(main) -> Array:
	return main.hud.bar.find_children("*", "BaseButton", true, false).filter(func(n): return n.is_visible_in_tree())

# 툴팁 안의 보이는 글을 한 줄로
func _tip_text(tip) -> String:
	var parts := []
	for n in tip.find_children("*", "Label", true, false):
		if n.is_visible_in_tree():
			parts.append(n.text)
	return " ".join(parts)

# 빈 맵에서 툴팁을 닫고 0.25초를 넘긴 뒤 btn 가운데로 커서를 옮긴다
func _fresh(tip, btn) -> void:
	_move(EMPTY)
	tip._process(0.3)
	_move(btn.get_global_rect().get_center())

# EV319 · S187: 위 띠의 보이는 버튼마다 0.1초에는 툴팁이 없고 0.25초에는 버튼 바로 아래·화면 안·폭 160 이하로 뜬다
func ev319():
	var main = _prep()
	var tip = main.hud.tip
	var buttons := _bar_buttons(main)
	var out := "" if buttons.size() >= 10 else "위 띠의 보이는 버튼이 %d개다" % buttons.size()
	var spots := {}
	for btn in buttons:
		spots[btn.get_global_rect().position] = true
	if out == "" and spots.size() < buttons.size():
		out = "버튼 %d개가 자리 %d곳에 겹쳐 있다(배치 전)" % [buttons.size(), spots.size()]
	for btn in buttons:
		if out != "":
			break
		_fresh(tip, btn)
		tip._process(0.1)
		if tip.visible:
			out = "«%s»: 0.1초에 툴팁이 떴다" % btn.text
			break
		tip._process(0.15)
		var r: Rect2 = btn.get_global_rect()
		var t: Rect2 = tip.get_global_rect()
		if not tip.visible:
			out = "«%s»: 0.25초에도 툴팁이 없다" % btn.text
		elif t.position.y < r.end.y - 0.5:
			out = "«%s»: 툴팁 윗변 %.1f가 버튼 아랫변 %.1f보다 위다" % [btn.text, t.position.y, r.end.y]
		elif not Rect2(-0.5, -0.5, 641, 361).encloses(t):
			out = "«%s»: 툴팁 %s가 화면 밖으로 나갔다" % [btn.text, t]
		elif t.size.x > 160.5:
			out = "«%s»: 툴팁 폭이 %.1f다" % [btn.text, t.size.x]
	_done(main)
	return out

# EV320 · S187: 떠 있는 툴팁에서 옆 버튼으로 옮기면 바로 뜨고, 툴팁 위로 옮기면 남고, 0.3초 비운 뒤에는 다시 기다린다
func ev320():
	var main = _prep()
	var tip = main.hud.tip
	var buttons := _bar_buttons(main)
	var a = buttons[0]
	var c = buttons[1]
	_fresh(tip, a)
	tip._process(0.25)
	var out := "" if tip.visible else "첫 버튼에 0.25초를 두어도 툴팁이 없다"
	if out == "":
		_move(c.get_global_rect().get_center())
		tip._process(0.0)
		var r: Rect2 = c.get_global_rect()
		var t: Rect2 = tip.get_global_rect()
		if not tip.visible or t.position.y < r.end.y - 0.5 or t.end.x < r.position.x or t.position.x > r.end.x:
			out = "옆 버튼으로 옮긴 순간 그 버튼 아래에 툴팁이 없다(%s, 버튼 %s)" % [t, r]
	if out == "":
		var t: Rect2 = tip.get_global_rect()
		_move(Vector2(t.position.x + 2, t.end.y - 2))
		tip._process(0.5)
		out = check(tip.visible, "커서를 툴팁 위로 옮기자 0.5초 안에 툴팁이 사라졌다")
	if out == "":
		_move(EMPTY)
		tip._process(0.3)
		_move(buttons[2].get_global_rect().get_center())
		tip._process(0.1)
		out = check(not tip.visible, "빈 맵에서 0.3초 뒤 다른 버튼에 0.1초 만에 툴팁이 떴다")
	_done(main)
	return out

func _starts(main, head: String):
	for n in _bar_buttons(main):
		if n.text.begins_with(head):
			return n
	return null

# EV321 · S187: 타워 툴팁은 «타워»·«(2)»·«30골드»에 빨간 줄이 없고, 마을 Lv1 사격장은 빨간 줄에 «마을 Lv2»,
# 준비 단계 첫 영웅 Q는 S97 표의 이름과 «마나»에 빨간 줄 «전투 단계»
func ev321():
	var main = _prep()
	var tip = main.hud.tip
	var b = main.view.battle
	var out := ""
	var tower = _starts(main, "타워 ")
	if tower == null:
		out = "«타워 »로 시작하는 버튼이 없다"
	else:
		_fresh(tip, tower)
		tip._process(0.25)
		var s := _tip_text(tip)
		if not ("타워" in s and "(2)" in s and "30골드" in s) or tip.reason.is_visible_in_tree():
			out = "타워 툴팁이 «%s»다(빨간 줄 %s)" % [s, tip.reason.is_visible_in_tree()]
	var archery = _starts(main, "사격장")
	if out == "" and archery:
		_fresh(tip, archery)
		tip._process(0.25)
		if not tip.reason.is_visible_in_tree() or not "마을 Lv2" in tip.reason.text:
			out = "마을 Lv1 사격장 툴팁의 빨간 줄이 «%s»다(보임 %s)" % [tip.reason.text, tip.reason.is_visible_in_tree()]
	elif out == "":
		out = "«사격장»으로 시작하는 버튼이 없다"
	var q = null
	for n in _bar_buttons(main):
		if n.text == "Q":
			q = n
			break
	if out == "" and q:
		_fresh(tip, q)
		tip._process(0.25)
		var s := _tip_text(tip)
		var name: String = QNAME[b.heroes[0].kind]
		if not (name in s and "마나" in s) or not "전투 단계" in tip.reason.text:
			out = "준비 단계 첫 영웅 Q 툴팁이 «%s», 빨간 줄이 «%s»다(기대 «%s»·«마나»·«전투 단계»)" % [s, tip.reason.text, name]
	elif out == "":
		out = "«Q» 버튼이 없다"
	_done(main)
	return out
