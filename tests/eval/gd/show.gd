extends "res://tests/eval/gd/save.gd"
# WBS 2.12 화면 표시(S71·S73). 그리기는 재지 못하니 그리는 데 쓰는 상태를 잰다. lib.gd·save.gd 머리의 계약에 더하는 API:
#   유닛·적: target — 마지막으로 친 대상 · Controls.show_hp — 체력바를 모두 그리는가
#   BattleView.hp_bar_size(유닛·적, show_hp) — 그 체력바의 크기(px). 그리지 않으면 Vector2.ZERO(static)
#   BattleView 인스턴스 hp_bar_rect(유닛·적, 크기) -> Rect2 — 그 체력바를 실제로 그리는 사각형(맵 px, S276). 막대를 그리는 코드도 이 함수를 쓴다
#   main.hud.hp_button — 체력바 버튼(BaseButton, S276). pressed면 controls.show_hp가 바뀐다. 보이는 글은 Label «V» 하나, 밝기는 버튼(또는 그 그림)의 modulate

# EV61 · S71: 용병이 적을 치면 용병의 공격 대상이 그 적이고, 적이 거점을 치면 적의 공격 대상이 거점이다
func ev61():
	var b = battle({"base_hp": BIG})
	var m = b.place_merc("soldier", Vector2i(10, 10))
	var e = b.spawn_enemy("basic", Vector2i(11, 10), {"hp": BIG, "speed": 0.0})
	if not run(b, 5.0, func(): return e.hp < e.max_hp):
		return "용병이 적을 치지 않았다"
	if m.target != e:
		return "용병의 공격 대상이 %s다" % [m.target]
	var b2 = battle({"base_hp": BIG})
	var e2 = b2.spawn_enemy("basic", Vector2i(24, 10), {"sight": 0.0})
	if not run(b2, 5.0, func(): return b2.base.hp < b2.base.max_hp):
		return "적이 거점을 치지 않았다"
	return check(e2.target == b2.base, "적의 공격 대상이 %s다" % [e2.target])

# EV62 · S73: 체력바 표시는 처음에 꺼져 있고, V 키를 누를 때마다 켜짐·꺼짐이 바뀐다
func ev62():
	var c = controls(battle())
	var seen := [c.show_hp]
	for i in 2:
		var ev := InputEventKey.new()
		ev.keycode = KEY_V
		ev.pressed = true
		c.handle(ev)
		seen.append(c.show_hp)
	return check(seen == [false, true, false], "V를 두 번 누르는 동안 %s였다" % [seen])

# EV362 · S73: 보스 체력바는 V 표시와 상관없이 24×3이고, 기본 적은 켰을 때만 16×2다
func ev362():
	var b = battle()
	var boss = b.spawn_enemy("boss", Vector2i(10, 10), {"speed": 0.0})
	var e = b.spawn_enemy("basic", Vector2i(12, 10), {"speed": 0.0})
	var view = load("res://src/ui/battle_view.gd")
	if boss == null or e == null or not view.get_script_method_list().any(func(m): return m.name == "hp_bar_size"):
		return "보스(%s)·기본 적(%s)을 두지 못했거나 BattleView.hp_bar_size가 없다" % [boss, e]
	var got := [view.hp_bar_size(boss, false), view.hp_bar_size(boss, true), view.hp_bar_size(e, false), view.hp_bar_size(e, true)]
	return check(got == [Vector2(24, 3), Vector2(24, 3), Vector2.ZERO, Vector2(16, 2)], "보스(꺼짐·켜짐)·기본 적(꺼짐·켜짐) 체력바 크기 %s" % [got])

# EV514 · I185: 체력바는 종류 이름이 아니라 boss 칸으로 가른다. boss 칸을 켠 기본 적은 늘 24×3, 끈 오우거는 켰을 때만 16×2
func ev514():
	var b = battle()
	var boss = b.spawn_enemy("basic", Vector2i(10, 10), {"speed": 0.0, "boss": true})
	var ogre = b.spawn_enemy("boss", Vector2i(12, 10), {"speed": 0.0, "boss": false})
	var view = load("res://src/ui/battle_view.gd")
	if boss == null or ogre == null or not view.get_script_method_list().any(func(m): return m.name == "hp_bar_size"):
		return "기본 적(%s)·오우거(%s)를 두지 못했거나 BattleView.hp_bar_size가 없다" % [boss, ogre]
	var got := [view.hp_bar_size(boss, false), view.hp_bar_size(boss, true), view.hp_bar_size(ogre, false), view.hp_bar_size(ogre, true)]
	return check(got == [Vector2(24, 3), Vector2(24, 3), Vector2.ZERO, Vector2(16, 2)], "boss 칸 켠 기본 적(꺼짐·켜짐)·끈 오우거(꺼짐·켜짐) 체력바 크기 %s" % [got])

# 발 자리(맵 px, S166): 칸 가운데. 비행 적은 그림자 자리로 0.4칸 아래다(battle_view.gd의 발밑 타원·그림자 자리와 같다)
func _foot(u) -> Vector2:
	var p: Vector2 = u.pos * CELL_PX + Vector2(CELL_PX, CELL_PX) / 2.0
	return p + (Vector2(0, CELL_PX * 0.4) if u.get("flying") == true else Vector2.ZERO)

# 체력바를 그리는 대신 hp_bar_rect를 부른 [대상, 크기]를 모으는 화면(thick.gd의 Rec처럼).
# 내부 클래스로 두면 hp_bar_rect의 꼴(static·인자 수)이 약속과 다를 때 스위트 전체가 안 불러와져서 실행 중에 만든다
const BARS_SRC := "extends \"res://src/ui/battle_view.gd\"\nvar asked := []\n\nfunc hp_bar_rect(u = null, size = null):\n\tasked.append([u, size])\n\treturn Rect2()\n"

# 체력바 표시를 show로 두고 트리 밖 화면의 _draw를 한 번 돌렸을 때 hp_bar_rect를 부른 [대상, 크기]. 화면을 만들지 못하면 null
func _drawn_bars(b, show: bool):
	var s := GDScript.new()
	s.source_code = BARS_SRC
	if s.reload() != OK:
		return null
	var v = s.new()
	v.battle = b
	v.controls = controls(b)
	v.controls.show_hp = show
	v._draw()
	var out: Array = v.asked
	v.free()
	return out

# EV660 · S276: 체력바를 켜면 병사·기본 적의 막대가 발 자리에서 x −8~+8·y +8~+10이고, 비행 적은 그림자 자리에서 같다.
# 보스 막대는 발 자리보다 위다. 끄면 병사·기본 적은 그리지 않는다. 그리는 코드가 이 사각형(hp_bar_rect)을 쓰는지는 _draw를 돌려 잰다
func ev660():
	var b = battle({"base_hp": BIG, "waves": [[{"kind": "basic", "count": 1}]]})  # 웨이브가 없으면 준비 단계 _draw의 출현 배지(S188)가 막대보다 먼저 오류로 멈춘다
	var m = b.place_merc("soldier", Vector2i(10, 10))
	var e = b.spawn_enemy("basic", Vector2i(14, 10), {"speed": 0.0})
	var f = b.spawn_enemy("flying", Vector2i(18, 10), {"speed": 0.0})
	var boss = b.spawn_enemy("boss", Vector2i(22, 10), {"speed": 0.0})
	if m == null or e == null or f == null or boss == null or f.get("flying") != true:
		return "병사(%s)·기본 적(%s)·비행 적(%s)·보스(%s)를 두지 못했다" % [m, e, f, boss]
	var view_gd = load("res://src/ui/battle_view.gd")
	var v = view_gd.new()
	v.battle = b
	v.controls = controls(b)
	if not v.has_method("hp_bar_rect"):
		v.free()
		return "BattleView.hp_bar_rect가 없다"
	v.controls.show_hp = true
	var bad := []
	for u in [m, e, f]:
		var want := Rect2(_foot(u) + Vector2(-8, 8), Vector2(16, 2))
		var got: Rect2 = v.call("hp_bar_rect", u, view_gd.hp_bar_size(u, v.controls.show_hp))
		if got.position.distance_to(want.position) > 0.5 or got.end.distance_to(want.end) > 0.5:
			bad.append("%s 막대 %s(기대 %s)" % [u.kind, got, want])
	var top: Rect2 = v.call("hp_bar_rect", boss, view_gd.hp_bar_size(boss, v.controls.show_hp))
	if top.end.y > _foot(boss).y:
		bad.append("보스 막대 %s가 발 자리 %s보다 위가 아니다" % [top, _foot(boss)])
	v.controls.show_hp = false
	for u in [m, e]:
		if view_gd.hp_bar_size(u, v.controls.show_hp) != Vector2.ZERO:
			bad.append("체력바를 껐는데 %s 막대 크기가 %s다" % [u.kind, view_gd.hp_bar_size(u, false)])
	v.free()
	var on = _drawn_bars(b, true)
	var off = _drawn_bars(b, false)
	if on == null or off == null:
		bad.append("hp_bar_rect를 덮어쓴 화면을 만들지 못했다(인스턴스 메서드 hp_bar_rect(u, size)가 아니다)")
	else:
		var called := func(seen: Array, u, size: Vector2) -> bool:
			return seen.any(func(a): return is_same(a[0], u) and a[1] is Vector2 and a[1].is_equal_approx(size))
		for u in [m, e, f]:
			if not called.call(on, u, Vector2(16, 2)):
				bad.append("체력바를 켜고 그릴 때 %s 막대에 hp_bar_rect(16×2)를 부르지 않았다(부른 수 %d)" % [u.kind, on.size()])
		for u in [m, e]:
			if off.any(func(a): return is_same(a[0], u) and a[1] is Vector2 and a[1] != Vector2.ZERO):
				bad.append("체력바를 끄고 그릴 때 %s 막대를 그렸다" % u.kind)
	return check(bad.is_empty(), "%s" % [bad])

const HP_BUTTON := Rect2(65, 266, 24, 24)  # 체력바 버튼(S276)

# 컨테이너 배치를 직접 돌린다(hud.gd의 _layout과 같다. 평가는 한 프레임 안에서 돈다)
func _layout(main) -> void:
	for i in 2:
		for c in main.hud.find_children("*", "Container", true, false):
			c.notification(Container.NOTIFICATION_SORT_CHILDREN)

# HUD를 한 번 돌린다. 버튼이 스스로 도는 노드(대피령 버튼처럼)면 그것도
func _turn(main, btn) -> void:
	main.hud._process(0.0)
	var s = btn.get_script()
	if s != null and s.get_script_method_list().any(func(x): return x.name == "_process"):
		btn.call("_process", 0.0)

func _move(at: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = at
	ev.global_position = at
	Engine.get_main_loop().root.push_input(ev, true)

# 빈 맵에서 툴팁을 닫고 btn 가운데에 커서를 0.25초 두었을 때 툴팁 안의 보이는 글(hud.gd의 _tip_of와 같다). 뜨지 않으면 ""
func _tip_of(main, btn) -> String:
	var tip = main.hud.tip
	_move(Vector2(320, 300))
	tip._process(0.3)
	_move(btn.get_global_rect().get_center())
	tip._process(0.25)
	if not tip.visible:
		return ""
	return " ".join(tip.find_children("*", "Label", true, false).filter(func(l): return l.is_visible_in_tree()).map(func(l): return l.text))

# 버튼 안의 보이는 글: 버튼 글과 보이는 Label
func _words(btn) -> Array:
	var t = btn.get("text")
	var out := [t] if t is String and t != "" else []
	for l in btn.find_children("*", "Label", true, false):
		if l.is_visible_in_tree() and l.text != "":
			out.append(l.text)
	return out

# 버튼 안의 보이는 그림(TextureRect)
func _pics(btn) -> Array:
	return btn.find_children("*", "TextureRect", true, false).filter(func(p): return p.is_visible_in_tree() and p.texture != null)

# 버튼 밝기: 버튼과 그 첫 그림의 modulate·self_modulate를 곱한 색의 (r+g+b)/3 × a
func _shine(btn) -> float:
	var m: Color = btn.modulate * btn.self_modulate
	var pics := _pics(btn)
	if not pics.is_empty():
		m *= pics[0].modulate * pics[0].self_modulate
	return (m.r + m.g + m.b) / 3.0 * m.a

# EV661 · S276: 1라운드 준비 단계에 체력바 버튼이 [65,266,24,24]에 보이고 글은 «V» 하나·그림이 있으며, 툴팁에 «체력바»·«[V]»가 있다.
# 누르면 show_hp가 켜지고 꺼져 있을 때보다 밝으며, 다시 누르면 꺼진다. 결과 창(won)에서는 숨는다
func ev661():
	var main = _game()
	var b = main.view.battle
	b.gold = BIG
	for i in 2:
		b.hire(i)
	b.next_round()
	_frame(main)
	_layout(main)
	var btn = main.hud.get("hp_button")
	if not btn is BaseButton:
		_done(main)
		return "main.hud.hp_button(BaseButton)이 없다"
	var c = main.hud.controls
	_turn(main, btn)
	var r: Rect2 = btn.get_global_rect()
	var out := ""
	if b.state != "prep" or c.show_hp:
		out = "준비가 틀렸다: 단계 %s · 처음 체력바 표시 %s" % [b.state, c.show_hp]
	elif not btn.is_visible_in_tree() or r.position.distance_to(HP_BUTTON.position) > 0.5 or r.size.distance_to(HP_BUTTON.size) > 0.5:
		out = "버튼 %s(보임 %s), 기대 %s" % [r, btn.is_visible_in_tree(), HP_BUTTON]
	elif _words(btn) != ["V"] or (_pics(btn).is_empty() and btn.get("icon") == null and btn.get("texture_normal") == null):
		out = "보이는 글 %s · 그림 %d(기대: 글은 «V» 하나, 그림 있음)" % [_words(btn), _pics(btn).size()]
	if out == "":
		var said := _tip_of(main, btn)
		if not ("체력바" in said and "[V]" in said):
			out = "툴팁 «%s»에 «체력바»·«[V]»가 없다" % said
	if out == "":
		var off := _shine(btn)
		btn.pressed.emit()
		_turn(main, btn)
		var on := _shine(btn)
		if not c.show_hp or on <= off + 0.01:
			out = "누른 뒤 체력바 표시 %s · 밝기 %.2f(꺼졌을 때 %.2f)" % [c.show_hp, on, off]
		else:
			btn.pressed.emit()
			_turn(main, btn)
			var again := _shine(btn)
			out = check(not c.show_hp and again <= off + 0.01, "다시 누른 뒤 체력바 표시 %s · 밝기 %.2f(처음 꺼졌을 때 %.2f)" % [c.show_hp, again, off])
	if out == "":
		b.state = "won"
		_frame(main)
		_turn(main, btn)
		out = check(not btn.is_visible_in_tree(), "결과 창(won)인데 체력바 버튼이 보인다")
	_done(main)
	return out
