extends "res://tests/eval/gd/save.gd"
# 테스트 모드(S289~S292·I231~I242). save.gd 머리의 계약에 더하는 API:
#   res://src/sim/tuning.gd — 테스트 모드의 수치 조정. new(판)은 판의 데이터 표를 판만의 사본으로 바꾸고, 그때 값을 데이터 값으로 기억한다(I240)
#     static shown(tags: Array) -> bool — 메인 메뉴에 «테스트 모드»를 보이나(S290). tags에 "test"나 "editor"가 있으면 참
#     static var path — 조정값 파일(I238, 기본 user://tuning.json). 평가는 평가용 파일로 바꾼다
#     fields(분류, 종류) -> Array — 줄마다 {name, path(Array), value, data}(I233·I234)
#       분류: "판"·"웨이브"·"적"·"용병"·"구조물"·"영웅"·"장비"·"영입"·"레벨"·"미션"
#       종류: 판 "stage" · 웨이브 라운드 차례(0부터) · 영입 "hire" · 레벨 "levels" · 그 밖은 데이터 파일 이름(장비는 주인 영웅 종류)
#       데이터 줄의 path는 데이터 키·배열 번호를 차례로 담는다(["q", "damage"] · ["steps", 1, "q.damage"]). name은 이어 쓴 이름(«q.damage»·«steps[1].q.damage»)
#       판 줄 path: ["gold"](지금 골드) · ["stage", "gold"] · ["stage", "base_hp"] · ["stage", "castle", "wall_hp"] · ["stage", "castle", "gate_hp"] · ["stage", "spawn_gap"] · ["stage", "reward_scale"]
#       웨이브 줄 path: ["hp_mult"] · [웨이브 차례, 적 종류](수) · ["night", 웨이브 차례, 키](밤 수치) · 영웅 «레벨» 줄 path: ["level"]
#     put(분류, 종류, path, 값) — 칸에 넣고 살아 있는 것에 건다(S291, I241)
#     add_enemy(라운드 차례, 웨이브 차례, 적 종류) -> bool — 그 웨이브에 없는 적 종류를 수 1로 더한다(I234)
#     can_jump() -> bool · jump(라운드 차례) -> bool(I235)
#     changes() -> Array — 데이터와 다른 칸마다 {table, kind, path, value, data, file}(I238). 웨이브의 kind는 라운드 차례다
#     save() -> int(쓴 칸 수) · load_file() -> int(넣은 칸 수, 파일이 없거나 못 읽으면 -1) · skipped(지난 불러오기에서 건너뛴 칸 수) · reset()
#   res://src/main.gd — static var test(테스트 모드, I231). 게임 장면의 tuning(테스트 모드면 Tuning, 아니면 null) · speed(배속, I236) · panel(테스트 패널, 아니면 null)
#     panel._process(delta) — 성능 표시와 «이동» 버튼을 판에 맞춘다
#   res://src/ui/menus.gd — can_test(메인 메뉴의 «테스트 모드»를 보인다, S290). 누르면 chosen("test")
#   res://src/menu.gd — chosen("test")를 받으면 Main.test를 켜고 저장을 그대로 둔 채 새 도전으로 게임 장면을 연다
#   테스트 패널: 버튼 «×1»·«×2»·«×4»·«×8»·«이동»·«저장»·«불러오기»·«되돌리기», 켜고 끄기 «성능 표시». 패널 밖에 «테스트 (F9)» 버튼. F9로 닫고 연다
#   성능 표시: 보이는 Label 가운데 글이 «FPS »로 시작하는 것. «FPS n · 적 n · 아군 n · 구조물 n · 투사체 n · 주민 n»

const TUNING := "user://eval_tuning.json"

func _T():
	var T = load("res://src/sim/tuning.gd")
	if T != null:
		T.path = TUNING
	return T

func _M():
	return load("res://src/main.gd")

# 테스트 모드로 붙인 게임 장면. main.gd에 static var test가 없으면 null
func _test_game():
	if _M().get("test") == null:
		return null
	_M().set("test", true)
	return _game()

func _end(main) -> void:
	_done(main)
	_M().set("test", false)

# 붙인 메인 메뉴 장면
func _title():
	_save()
	var m = load("res://src/menu.tscn").instantiate()
	Engine.get_main_loop().root.add_child(m)
	return m

# 보이는 버튼 글자(트리 차례)
func _texts(node: Node) -> Array:
	return node.find_children("*", "BaseButton", true, false).filter(func(n): return n.is_visible_in_tree()).map(func(n): return n.text)

# 보이는 켜고 끄기 가운데 글자가 text인 것
func _toggle(node: Node, text: String):
	for n in node.find_children("*", "CheckButton", true, false):
		if n.is_visible_in_tree() and n.text == text:
			return n
	return null

# 성능 표시 글
func _fps(node: Node):
	for n in node.find_children("*", "Label", true, false):
		if n.is_visible_in_tree() and n.text.begins_with("FPS "):
			return n
	return null

func _names(rows: Array) -> Array:
	return rows.map(func(r): return r.name)

func _paths(rows: Array) -> Array:
	return rows.map(func(r): return r.path)

func _row(rows: Array, path: Array):
	for r in rows:
		if r.path == path:
			return r
	return null

# 패널의 보이는 조작 요소가 모두 이름이 있고 Tab으로 닿는다. 어긋난 것을 설명하는 문장, 없으면 ""
func _reach(panel: Node):
	var spins := 0
	for n in panel.find_children("*", "Control", true, false):
		if not n.is_visible_in_tree():
			continue
		if n is BaseButton:
			if n.text == "":
				return "패널에 글자 없는 버튼이 있다(%s)" % n.get_class()
			if n.focus_mode != Control.FOCUS_ALL:
				return "패널 버튼 «%s»가 Tab으로 포커스를 받지 않는다" % n.text
		elif n is SpinBox:
			spins += 1
			if n.get_line_edit().focus_mode != Control.FOCUS_ALL:
				return "패널 값 칸이 Tab으로 포커스를 받지 않는다"
			if not n.get_parent().get_children().any(func(s): return s is Label and s.text != "" and s.get_index() < n.get_index()):
				return "패널 값 칸 앞에 이름 글자가 없다"
	return "" if spins > 0 else "열린 패널에 값 칸이 없다"

# EV764 · S290: 테스트 빌드·에디터 실행에서만 «테스트 모드»가 보이고, 테스트 프리셋에만 기능 태그 test가 있다
func ev764():
	var T = _T()
	if T == null:
		return "res://src/sim/tuning.gd가 없다"
	for c in [[["test"], true], [["editor"], true], [["template", "test"], true], [[], false], [["template"], false], [["template", "release"], false]]:
		if T.shown(c[0]) != c[1]:
			return "shown(%s)이 %s다(%s여야 한다)" % [c[0], not c[1], c[1]]
	var cfg := ConfigFile.new()
	if cfg.load("res://export_presets.cfg") != OK:
		return "export_presets.cfg를 읽지 못했다"
	var tags := {}  # 프리셋 이름 → 기능 태그
	for s in cfg.get_sections():
		if s.begins_with("preset.") and s.count(".") == 1:
			tags[cfg.get_value(s, "name", "")] = Array(String(cfg.get_value(s, "custom_features", "")).split(",", false)).map(func(x): return x.strip_edges())
	if not "test" in tags.get("Windows Desktop (Test)", []):
		return "기능 태그 test가 든 프리셋 «Windows Desktop (Test)»가 없다: %s" % tags
	if not tags.has("Windows Desktop") or "test" in tags["Windows Desktop"]:
		return "출시판 프리셋 «Windows Desktop»이 없거나 기능 태그 test가 들었다: %s" % tags
	_save().erase()
	var m = _title()
	var order := _texts(m)
	m.free()
	var at := order.find("테스트 모드")
	if at < 0 or at != order.find("이어하기") + 1:
		return "에디터 실행의 메인 메뉴 버튼 차례가 %s다(«이어하기» 다음이 «테스트 모드»여야 한다)" % [order]
	m = _title()
	var menus = m.find_children("*", "CanvasLayer", true, false)[0]
	menus.can_test = false
	menus.open("title")
	var hidden: bool = _button(m, "테스트 모드") == null
	m.free()
	return check(hidden, "can_test가 거짓인데 메인 메뉴에 «테스트 모드»가 있다")

# EV765 · I231: 저장을 지우지 않고 들어가고, 테스트 모드 판은 저장을 쓰지도 지우지도 않으며, 메인 메뉴로 나가면 끝난다
func ev765():
	var M = _M()
	if M.get("test") == null:
		return "main.gd에 static var test가 없다"
	var S = _save()
	S.write(_new(_stage()))
	var bytes := FileAccess.get_file_as_bytes(PATH)
	var m = _title()
	var pressed := _press(m, "테스트 모드")
	var on: bool = M.test
	var fresh: bool = M.resume.is_empty()
	m.free()
	var kept := FileAccess.get_file_as_bytes(PATH) == bytes
	M.test = false
	if not pressed:
		return "메인 메뉴에 «테스트 모드»가 없다"
	if not on or not fresh:
		return "«테스트 모드»를 눌러도 Main.test가 켜지지 않거나 이어하기 저장을 넘긴다(test %s, resume 비었나 %s)" % [on, fresh]
	if not kept:
		return "«테스트 모드»를 누르자 저장 파일이 바뀌었다"
	var main = _test_game()
	var b = main.view.battle
	var why := ""
	if main.get("tuning") == null:
		why = "테스트 모드 게임 장면에 tuning이 없다"
	elif b.state != "hiring":
		why = "테스트 모드가 영입 창(hiring)이 아니라 %s로 시작했다" % b.state
	if why == "":
		_frame(main)
		b.next_round()
		_frame(main)
		b.start_battle()
		main._process(DT)
		b.damage(b.base, BIG)
		_frame(main)
		if b.state != "lost":
			why = "거점이 부서져도 패배가 아니다(%s)" % b.state
		elif FileAccess.get_file_as_bytes(PATH) != bytes:
			why = "테스트 모드 판(영입 창·준비·웨이브 시작·패배)이 저장 파일을 쓰거나 지웠다"
	if why == "":
		main._on_menu("title")
		if M.test:
			why = "«메인 메뉴로» 뒤에도 Main.test가 켜져 있다"
	_end(main)
	if why != "":
		return why
	main = _test_game()
	b = main.view.battle
	b.next_round()
	_frame(main)
	main._on_menu("title")  # 준비 단계에 메인 메뉴로
	var same := FileAccess.get_file_as_bytes(PATH) == bytes
	_end(main)
	return check(same, "테스트 모드의 준비 단계에서 메인 메뉴로 나가자 저장 파일이 바뀌었다")

# EV766 · I232: 테스트 패널은 처음 열려 있고 F9·«테스트 (F9)»로 닫고 연다. 판은 멈추지 않는다. 조작 요소는 이름이 있고 Tab으로 닿으며, 누르면 포커스를 놓는다
func ev766():
	var main = _test_game()
	if main == null:
		return "main.gd에 static var test가 없다"
	if main.get("panel") == null:
		_end(main)
		return "테스트 모드 게임 장면에 테스트 패널(panel)이 없다"
	var b = main.view.battle
	b.next_round()
	_frame(main)
	var p = main.panel
	var why := ""
	if not (p is CanvasLayer and p.layer == main.hud.layer and p.get_index() > main.hud.get_index() and p.layer < main.menus.layer):
		why = "패널이 HUD 위·ESC 메뉴 아래 층이 아니다"
	elif _toggle(main, "성능 표시") == null:
		why = "처음에 패널이 열려 있지 않다(«성능 표시»가 안 보인다)"
	if why == "":
		why = _reach(p)
	if why == "":
		var x2 = _button(main, "×2")
		if x2 == null:
			why = "패널에 «×2»가 없다"
		else:
			x2.grab_focus()
			x2.pressed.emit()
			if main.get_viewport().gui_get_focus_owner() != null:
				why = "패널 버튼을 누른 뒤에도 키보드 포커스가 남았다"
	if why == "":
		_key(KEY_F9)
		if _toggle(main, "성능 표시") != null:
			why = "F9를 눌러도 패널이 닫히지 않는다"
		else:
			_key(KEY_F9)
			if _toggle(main, "성능 표시") == null:
				why = "F9를 다시 눌러도 패널이 열리지 않는다"
	if why == "":
		if not _press(main, "테스트 (F9)") or _toggle(main, "성능 표시") != null:
			why = "«테스트 (F9)»를 눌러도 패널이 닫히지 않는다"
		elif not _press(main, "테스트 (F9)") or _toggle(main, "성능 표시") == null:
			why = "«테스트 (F9)»를 다시 눌러도 패널이 열리지 않는다"
	if why == "":
		b.start_battle()
		var t0: float = b.tally.battle_time
		main._process(DT)
		if b.tally.battle_time <= t0:
			why = "패널이 열려 있는 동안 판이 멈췄다"
	_end(main)
	if why != "":
		return why
	var plain = _game()
	var none: bool = plain.get("panel") == null and _button(plain, "테스트 (F9)") == null
	_done(plain)
	return check(none, "테스트 모드가 아닌 게임 장면에 테스트 패널이나 «테스트 (F9)»가 있다")

# EV767 · I233: 분류·종류의 수치 줄 — 수만 줄이 되고, 이어 쓴 이름, 정수·0.01 단위·하한, 레벨 줄
func ev767():
	var T = _T()
	if T == null:
		return "res://src/sim/tuning.gd가 없다"
	var b = _new(_stage())
	var t = T.new(b)
	var want := {
		["적", "slime"]: [["hp", "speed", "damage", "reward", "split.count"], ["split.kind", "flying", "boss"]],
		["영웅", "ignis"]: [["hp", "damage", "q.damage", "e.mr", "r.count"], ["q.id", "q.aim", "title"]],
		["용병", "archer"]: [["cost", "ranks[0].damage", "rank_cost[0]"], []],
		["구조물", "tower"]: [["cost", "hp", "damage", "range"], ["size", "pierce"]],
		["장비", "ignis"]: [["steps[1].q.damage", "steps[9].r.count"], ["steps[6].q.ignite", "title"]],
		["영입", "hire"]: [["slots", "cost[0]", "odds[2]", "gear_cost[9]"], []],
		["레벨", "levels"]: [["steps[0]", "growth", "unlock.q"], []],
		["미션", "base_safe"]: [["reward"], ["commission", "text"]],
	}
	for k in want:
		var names := _names(t.fields(k[0], k[1]))
		for n in want[k][0]:
			if not n in names:
				return "%s %s 줄에 %s가 없다: %s" % [k[0], k[1], n, names]
		for n in want[k][1]:
			if n in names:
				return "%s %s 줄에 수가 아닌 %s가 있다" % [k[0], k[1], n]
	var stage := [["gold"], ["stage", "gold"], ["stage", "base_hp"], ["stage", "castle", "wall_hp"], ["stage", "castle", "gate_hp"], ["stage", "spawn_gap"], ["stage", "reward_scale"]]
	if _paths(t.fields("판", "stage")) != stage:
		return "판 줄이 %s다(%s여야 한다)" % [_paths(t.fields("판", "stage")), stage]
	var hp: float = load("res://data/enemies/slime.tres").hp
	t.put("적", "slime", ["hp"], hp + 6.0)
	var r = _row(t.fields("적", "slime"), ["hp"])
	if r.value != hp + 6.0 or r.data != hp:
		return "slime hp 줄의 값·데이터 값이 %s·%s다(%s·%s여야 한다)" % [r.value, r.data, hp + 6.0, hp]
	t.put("적", "slime", ["reward"], 20.7)
	var reward = b.ENEMY_KINDS.slime.reward
	if typeof(reward) != TYPE_INT or reward != 21:
		return "정수 칸 reward에 20.7을 넣자 %s(%s)가 됐다(정수 21이어야 한다)" % [reward, type_string(typeof(reward))]
	t.put("적", "slime", ["speed"], 1.234)
	if not is_equal_approx(b.ENEMY_KINDS.slime.speed, 1.23):
		return "실수 칸 speed에 1.234를 넣자 %s가 됐다(0.01 단위 1.23이어야 한다)" % b.ENEMY_KINDS.slime.speed
	t.put("적", "slime", ["speed"], -3.0)
	t.put("적", "slime", ["hp"], 0.0)
	t.put("영웅", "ignis", ["e", "mr"], -0.5)
	if b.ENEMY_KINDS.slime.speed != 0.0 or b.ENEMY_KINDS.slime.hp != 1.0 or b.HERO_KINDS.ignis.e.mr != -0.5:
		return "하한이 맞지 않다: speed %s(0), hp %s(1), 음수 데이터 e.mr %s(-0.5)" % [b.ENEMY_KINDS.slime.speed, b.ENEMY_KINDS.slime.hp, b.HERO_KINDS.ignis.e.mr]
	if _row(t.fields("영웅", "ignis"), ["level"]) != null:
		return "보유하지 않은 영웅에 레벨 줄이 있다"
	b.offers[0] = "ignis"
	b.begin_hiring()
	if b.hire(0) == null:
		return "이그니스를 영입하지 못했다"
	var rows = t.fields("영웅", "ignis")
	return check(rows[0].path == ["level"] and rows[0].value == b.roster[0].level, "보유한 영웅의 첫 줄이 레벨 줄이 아니다: %s" % [rows[0]])

# EV768 · S291: 적 수치를 바꾸면 살아 있는 같은 종류 적에 바로 걸린다. 체력은 비율 그대로, 덮어쓴 값은 그대로
func ev768():
	var T = _T()
	if T == null:
		return "res://src/sim/tuning.gd가 없다"
	var b = battle({"hp_mult": [2.0]})
	var t = T.new(b)
	var hp: float = b.ENEMY_KINDS.slime.hp
	var a = b.spawn_enemy("slime", Vector2i(5, 5))
	var c = b.spawn_enemy("slime", Vector2i(5, 7), {"reward": 0})
	var o = b.spawn_enemy("basic", Vector2i(5, 9))
	a.hp = a.max_hp / 2
	var o_max: float = o.max_hp
	t.put("적", "slime", ["hp"], hp * 2)
	if not (is_equal_approx(a.max_hp, hp * 4) and is_equal_approx(a.hp, hp * 2) and is_equal_approx(c.max_hp, hp * 4) and is_equal_approx(c.hp, hp * 4)):
		return "slime hp를 두 배로 하자 반 체력 slime이 %s/%s, 가득 찬 slime이 %s/%s다(%s/%s, %s/%s여야 한다)" % [a.hp, a.max_hp, c.hp, c.max_hp, hp * 2, hp * 4, hp * 4, hp * 4]
	if o.max_hp != o_max:
		return "다른 종류(basic)의 최대 체력이 바뀌었다"
	t.put("적", "slime", ["damage"], 9.0)
	t.put("적", "slime", ["reward"], 30)
	t.put("적", "slime", ["radius"], 0.5)
	if a.damage != 9.0 or c.damage != 9.0:
		return "살아 있는 slime 피해가 %s·%s다(9여야 한다)" % [a.damage, c.damage]
	if a.reward != 30 or c.reward != 0:
		return "처치 보상이 %d·%d다(바꾼 30, 덮어쓴 0 그대로여야 한다)" % [a.reward, c.reward]
	if a.radius != 0.5 or a.girth != 0.5:
		return "몸 반지름이 %s, 나온 때 반지름이 %s다(0.5여야 한다)" % [a.radius, a.girth]
	var n = b.spawn_enemy("slime", Vector2i(5, 11))
	return check(is_equal_approx(n.max_hp, hp * 4) and n.damage == 9.0 and n.reward == 30, "새로 낸 slime이 바꾼 값이 아니다(%s, %s, %d)" % [n.max_hp, n.damage, n.reward])

# EV769 · I241: 용병은 강화 단계를 얹은 수치로 건다. 강화 단계가 덮는 칸은 바탕 값을 바꿔도 그대로다
func ev769():
	var T = _T()
	if T == null:
		return "res://src/sim/tuning.gd가 없다"
	var b = battle()
	var t = T.new(b)
	var hp: float = b.MERC_KINDS.soldier.hp
	var s = b.place_merc("soldier", Vector2i(20, 15))
	if s == null:
		return "병사를 놓지 못했다"
	s.hp = s.max_hp / 2
	t.put("용병", "soldier", ["hp"], hp * 2)
	t.put("용병", "soldier", ["damage"], 7.0)
	if not (is_equal_approx(s.max_hp, hp * 2) and is_equal_approx(s.hp, hp) and s.damage == 7.0):
		return "병사가 %s/%s, 공격력 %s다(%s/%s, 7이어야 한다)" % [s.hp, s.max_hp, s.damage, hp, hp * 2]
	b.merc_rank["archer"] = 1
	var a = b.place_merc("archer", Vector2i(20, 17))
	if a == null:
		return "궁수를 놓지 못했다"
	var ranked: float = b.MERC_KINDS.archer.ranks[0].damage
	t.put("용병", "archer", ["damage"], ranked + 10.0)
	if a.damage != ranked:
		return "강화 단계가 덮는 공격력이 바탕 값을 따라 %s가 됐다(%s 그대로여야 한다)" % [a.damage, ranked]
	t.put("용병", "archer", ["ranks", 0, "damage"], ranked + 1.0)
	return check(a.damage == ranked + 1.0, "1단계 공격력을 바꾸자 궁수 공격력이 %s다(%s여야 한다)" % [a.damage, ranked + 1.0])

# EV770 · I241: 구조물 — 다 지은 것과 짓는 중인 것 모두, 체력은 다 지었을 때의 체력과 함께 비율대로. 다른 종류는 그대로
func ev770():
	var T = _T()
	if T == null:
		return "res://src/sim/tuning.gd가 없다"
	var b = battle()
	var t = T.new(b)
	var hp: float = b.STRUCTURE_KINDS.tower.hp
	var w = b.build("tower", Vector2i(10, 5))
	var u = b.build("tower", Vector2i(10, 9))
	var x = b.build("wall", Vector2i(14, 5))
	if w == null or u == null or x == null:
		return "타워·방벽을 짓지 못했다"
	w.hp = w.max_hp / 2
	u.complete = false  # 반쯤 지은 타워(짓는 동안 입은 피해 없음)
	u.progress = 0.5
	u.hp = u.full * 0.5
	var x_max: float = x.max_hp
	t.put("구조물", "tower", ["hp"], hp * 2)
	if not (is_equal_approx(w.max_hp, hp * 2) and is_equal_approx(w.hp, hp) and is_equal_approx(w.full, hp * 2)):
		return "다 지은 타워가 %s/%s(다 지었을 때 %s)다(%s/%s, %s여야 한다)" % [w.hp, w.max_hp, w.full, hp, hp * 2, hp * 2]
	if not (is_equal_approx(u.full, hp * 2) and is_equal_approx(u.hp, hp)):
		return "짓는 중인 타워가 체력 %s, 다 지었을 때 %s다(%s, %s여야 한다)" % [u.hp, u.full, hp, hp * 2]
	t.put("구조물", "tower", ["damage"], 5.0)
	t.put("구조물", "tower", ["range"], 9.5)
	if w.damage != 5.0 or u.damage != 5.0 or w.range != 9.5 or u.range != 9.5:
		return "타워 공격력·사거리가 %s·%s, %s·%s다(5·9.5여야 한다)" % [w.damage, w.range, u.damage, u.range]
	return check(x.max_hp == x_max, "다른 종류(방벽)의 최대 체력이 바뀌었다")

# EV771 · I241: 영웅 — 체력·공격력은 레벨 성장을 얹어, 스킬 칸은 장비를 얹어 다시 맞춘다. 장비·레벨 칸과 레벨 줄
func ev771():
	var T = _T()
	if T == null:
		return "res://src/sim/tuning.gd가 없다"
	var b = battle({"heroes": [{"kind": "ignis", "cell": Vector2i(10, 10), "level": 3, "gear": 2}]})
	var t = T.new(b)
	var h = b.heroes[0]
	var g: float = 1.0 + b.LEVELS.growth * (h.level - 1)
	h.hp = h.max_hp / 2
	t.put("영웅", "ignis", ["hp"], 180.0)
	t.put("영웅", "ignis", ["damage"], 10.0)
	if not (is_equal_approx(h.max_hp, 180.0 * g) and is_equal_approx(h.hp, 90.0 * g) and is_equal_approx(h.damage, 10.0 * g)):
		return "Lv%d 이그니스가 %s/%s, 공격력 %s다(%s/%s, %s여야 한다)" % [h.level, h.hp, h.max_hp, h.damage, 90.0 * g, 180.0 * g, 10.0 * g]
	var geared: float = b.GEAR_KINDS.ignis.steps[1]["q.damage"]
	t.put("영웅", "ignis", ["q", "radius"], 1.8)
	t.put("영웅", "ignis", ["q", "damage"], geared + 13.0)
	if h.q.radius != 1.8:
		return "q.radius가 %s다(1.8이어야 한다)" % h.q.radius
	if h.q.damage != geared:
		return "장비(+2)가 덮는 q.damage가 바탕 값을 따라 %s가 됐다(%s 그대로여야 한다)" % [h.q.damage, geared]
	t.put("장비", "ignis", ["steps", 1, "q.damage"], geared + 2.0)
	if h.q.damage != geared + 2.0:
		return "장비 +1 단계 q.damage를 바꾸자 영웅 q.damage가 %s다(%s여야 한다)" % [h.q.damage, geared + 2.0]
	t.put("레벨", "levels", ["growth"], 0.5)
	var g2: float = 1.0 + 0.5 * (h.level - 1)
	if not (is_equal_approx(h.max_hp, 180.0 * g2) and is_equal_approx(h.hp, 90.0 * g2)):
		return "성장 비율을 0.5로 하자 이그니스가 %s/%s다(%s/%s여야 한다)" % [h.hp, h.max_hp, 90.0 * g2, 180.0 * g2]
	t.put("영웅", "ignis", ["level"], 5)
	var need: int = b.LEVELS.steps.slice(0, 4).reduce(func(s, x): return s + x, 0)
	return check(h.level == 5 and h.xp == need and is_equal_approx(h.hp / h.max_hp, 0.5), "레벨 줄을 5로 하자 Lv%d·경험치 %d·체력 비율 %s다(Lv5·%d·0.5여야 한다)" % [h.level, h.xp, h.hp / h.max_hp, need])

# EV772 · I234: 웨이브 칸 — 수·더하기는 그 웨이브가 시작될 때 쓰이고 미리보기에 보인다. 시작한 웨이브는 그대로. 체력 배율·밤 줄
func ev772():
	var T = _T()
	if T == null:
		return "res://src/sim/tuning.gd가 없다"
	var b = _new(_stage())
	var t = T.new(b)
	t.put("웨이브", 0, [0, "slime"], 3)
	if not t.add_enemy(0, 0, "basic"):
		return "1라운드 웨이브 1에 basic을 더하지 못했다"
	if t.add_enemy(0, 0, "basic"):
		return "웨이브에 이미 있는 종류를 또 더했다"
	t.put("웨이브", 0, [0, "basic"], 2)
	var row = _row(t.fields("웨이브", 0), [0, "basic"])
	if row == null or row.value != 2:
		return "더한 basic 줄이 없거나 수가 2가 아니다: %s" % [row]
	var pre := {}
	for d in b.spawn_counts(0, 0):
		for k in d:
			pre[k] = pre.get(k, 0) + d[k]
	if pre != {"slime": 3, "basic": 2}:
		return "웨이브 1 미리보기가 %s다(slime 3·basic 2여야 한다)" % pre
	var n := {}
	b.enemy_spawned.connect(func(e): n[e.kind] = n.get(e.kind, 0) + 1)
	b.start_battle()
	var left: int = b.enemies_left()
	t.put("웨이브", 0, [0, "slime"], 9)
	if b.enemies_left() != left:
		return "전투 중에 지금 웨이브의 수를 바꾸자 남은 적이 %d에서 %d가 됐다" % [left, b.enemies_left()]
	run(b, 5.0)
	if n != {"slime": 3, "basic": 2}:
		return "웨이브 1에 %s가 나왔다(slime 3·basic 2여야 한다)" % n
	var m0: float = _row(t.fields("웨이브", 0), ["hp_mult"]).value
	var e = b.enemies.filter(func(x): return x.kind == "basic")[0]
	var before: float = e.max_hp
	t.put("웨이브", 0, ["hp_mult"], m0 * 2)
	if not is_equal_approx(e.max_hp, before * 2):
		return "지금 라운드 체력 배율을 두 배로 하자 전장의 basic 최대 체력이 %s에서 %s가 됐다" % [before, e.max_hp]
	var fresh = b.spawn_enemy("basic", Vector2i(30, 120))
	if not is_equal_approx(fresh.max_hp, b.ENEMY_KINDS.basic.hp * m0 * 2):
		return "새로 낸 basic 최대 체력이 %s다(%s여야 한다)" % [fresh.max_hp, b.ENEMY_KINDS.basic.hp * m0 * 2]
	var rw := []
	for r in b.nights.size():
		for w in b.nights[r].size():
			if rw.is_empty() and not b.nights[r][w].is_empty():
				rw = [r, w]
	if rw.is_empty():
		return "밤 웨이브가 있는 라운드가 없다"
	var got := _paths(t.fields("웨이브", rw[0])).filter(func(p): return p[0] == "night" and p[1] == rw[1])
	var night_want: Array = b.nights[rw[0]][rw[1]].keys().map(func(k): return ["night", rw[1], k])
	return check(got == night_want, "%d라운드 웨이브 %d 밤 줄이 %s다(%s여야 한다)" % [rw[0] + 1, rw[1] + 1, got, night_want])

# EV773 · I235: 라운드 이동 — 영입 창·준비 단계에서 고른 라운드 웨이브 1의 준비 단계로, 이어지는 것은 그대로, 전투·패배에서는 안 된다
func ev773():
	var T = _T()
	if T == null:
		return "res://src/sim/tuning.gd가 없다"
	var b = _new(_stage())
	b.live_prep = true
	b.begin_hiring()
	var t = T.new(b)
	var g: int = b.gold
	if not t.can_jump() or not t.jump(3):
		return "영입 창에서 4라운드로 이동하지 못했다"
	if b.state != "prep" or b.round_index != 3 or b.wave_index != 0 or b.waves != b.rounds[3]:
		return "이동 뒤 %s·라운드 차례 %d·웨이브 차례 %d다(prep·3·0이어야 한다)" % [b.state, b.round_index, b.wave_index]
	if b.units.filter(func(u): return u.kind == "engineer").is_empty():
		return "영입 창에서 이동했는데 시작 공병이 없다"
	if b.gold != g:
		return "라운드 이동으로 골드가 %d에서 %d가 됐다" % [g, b.gold]
	var b2 = _new(_stage())
	var t2 = T.new(b2)
	var cell := _near(b2, "wall", Vector2i(32, 90))
	var s = b2.build("wall", cell)
	if s == null or not t2.jump(2):
		return "준비 단계에서 방벽을 짓고 3라운드로 이동하지 못했다"
	if b2.structure_at(cell) != s or b2.round_index != 2 or b2.tally.built != 0 or b2.mission == "":
		return "이동 뒤 방벽이 사라졌거나, 라운드 차례가 %d이거나, 집계(built %d)·미션(%s)이 새 라운드 것이 아니다" % [b2.round_index, b2.tally.built, b2.mission]
	b2.wave_index = 1
	if not t2.jump(2) or b2.wave_index != 0:
		return "지금 라운드를 고르자 웨이브 1로 돌아가지 않았다"
	b2.start_battle()
	if t2.can_jump() or t2.jump(4) or b2.round_index != 2:
		return "전투 단계에 라운드 이동이 된다"
	b2.damage(b2.base, BIG)
	if t2.can_jump() or t2.jump(4):
		return "패배 뒤에 라운드 이동이 된다"
	var main = _test_game()
	if main == null or main.get("panel") == null:
		if main != null:
			_end(main)
		return "테스트 모드 게임 장면에 테스트 패널이 없다"
	var mb = main.view.battle
	mb.next_round()
	_frame(main)
	main.panel._process(0.0)
	var go = _button(main, "이동")
	var ready: bool = go != null and not go.disabled
	mb.start_battle()
	main.panel._process(0.0)
	var blocked: bool = go != null and go.disabled
	_end(main)
	if not ready:
		return "준비 단계에 패널의 «이동»이 없거나 눌리지 않는다"
	return check(blocked, "전투 단계에 패널의 «이동»이 눌린다")

# EV774 · I236: 배속 ×N이면 한 프레임에 판과 화면 시계를 그 delta로 N번 돌린다. 테스트 모드가 아니면 ×1
func ev774():
	var main = _test_game()
	if main == null:
		return "main.gd에 static var test가 없다"
	if main.get("speed") == null or main.get("panel") == null:
		_end(main)
		return "테스트 모드 게임 장면에 speed나 panel이 없다"
	var b = main.view.battle
	b.next_round()
	_frame(main)
	b.start_battle()
	var why := ""
	if main.speed != 1:
		why = "처음 배속이 ×1이 아니라 ×%d다" % main.speed
	if why == "":
		_press(main, "×4")
		var t0: float = b.tally.battle_time
		var c0: float = main.view.clock
		main._process(DT)
		var d: float = b.tally.battle_time - t0
		var dc: float = main.view.clock - c0
		if main.speed != 4 or not is_equal_approx(d, 4 * DT) or not is_equal_approx(dc, 4 * DT):
			why = "×4에서 한 프레임(%s초)에 판이 %s초, 화면 시계가 %s초 돌았다(%s초여야 한다)" % [DT, d, dc, 4 * DT]
	if why == "":
		_press(main, "×1")
		var t1: float = b.tally.battle_time
		main._process(DT)
		if not is_equal_approx(b.tally.battle_time - t1, DT):
			why = "×1로 돌리자 한 프레임에 판이 %s초 돌았다" % (b.tally.battle_time - t1)
	_end(main)
	if why != "":
		return why
	var plain = _game()
	var pb = plain.view.battle
	pb.next_round()
	_frame(plain)
	pb.start_battle()
	var t2: float = pb.tally.battle_time
	plain._process(DT)
	var d2: float = pb.tally.battle_time - t2
	_done(plain)
	return check(is_equal_approx(d2, DT), "테스트 모드가 아닌 게임 장면이 한 프레임에 %s초 돌았다(%s초여야 한다)" % [d2, DT])

# EV775 · I237: 성능 표시는 판의 수를 보이고, «성능 표시»를 끄면 숨고, 패널을 닫아도 남는다
func ev775():
	var main = _test_game()
	if main == null:
		return "main.gd에 static var test가 없다"
	if main.get("panel") == null:
		_end(main)
		return "테스트 모드 게임 장면에 테스트 패널이 없다"
	var b = main.view.battle
	b.next_round()
	_frame(main)
	for x in [10, 14, 18]:
		b.spawn_enemy("basic", Vector2i(x, b.size.y - 2))
	main.panel._process(0.0)
	var l = _fps(main)
	var why := ""
	if l == null:
		why = "성능 표시(«FPS »로 시작하는 글)가 없다"
	else:
		var parts: Array = Array(l.text.split(" · "))
		var want := ["적 %d" % b.enemies.size(), "아군 %d" % b.units.filter(func(u): return u.alive).size(), "구조물 %d" % b.structures.size(),
			"투사체 %d" % b.missiles.size(), "주민 %d" % b.people.size()]
		if b.enemies.size() != 3 or parts.slice(1) != want:
			why = "성능 표시가 «%s»다(«FPS n · %s»여야 한다)" % [l.text, " · ".join(want)]
	if why == "":
		_toggle(main, "성능 표시").button_pressed = false
		main.panel._process(0.0)
		if _fps(main) != null:
			why = "«성능 표시»를 꺼도 성능 표시가 보인다"
	if why == "":
		_toggle(main, "성능 표시").button_pressed = true
		_key(KEY_F9)
		main.panel._process(0.0)
		if _fps(main) == null:
			why = "패널을 닫자 성능 표시가 사라졌다"
	_end(main)
	return why

# EV776 · I238: 저장은 데이터와 다른 칸만(지금 골드 빼고) 쓰고, 되돌리기는 데이터 값으로, 불러오기는 파일 값으로 돌린다. 모르는 칸은 건너뛴다
func ev776():
	var T = _T()
	if T == null:
		return "res://src/sim/tuning.gd가 없다"
	if FileAccess.file_exists(TUNING):
		DirAccess.remove_absolute(TUNING)
	var b = _new(_stage())
	var t = T.new(b)
	var hp: float = b.ENEMY_KINDS.slime.hp
	var dmg: float = b.STRUCTURE_KINDS.tower.damage
	var count: int = b.rounds[0][0].filter(func(x): return x.kind == "slime")[0].count
	var gold: int = _row(t.fields("판", "stage"), ["stage", "gold"]).data
	if t.load_file() != -1 or not t.changes().is_empty():
		return "파일이 없는데 불러오기가 -1이 아니거나 칸이 바뀌었다"
	t.put("적", "slime", ["hp"], hp + 6.0)
	t.put("구조물", "tower", ["damage"], dmg + 1.0)
	t.put("웨이브", 0, [0, "slime"], count + 5)
	t.add_enemy(0, 0, "basic")
	t.put("웨이브", 0, [0, "basic"], 2)
	t.put("판", "stage", ["stage", "gold"], 777)
	t.put("판", "stage", ["gold"], 12345)
	var want := [
		["enemies", "slime", ["hp"], hp + 6.0, hp, "data/enemies/slime.tres"],
		["structures", "tower", ["damage"], dmg + 1.0, dmg, "data/structures/tower.tres"],
		["waves", 0, [0, "slime"], count + 5, count, "data/waves/test_stage.tres"],
		["waves", 0, [0, "basic"], 2, 0, "data/waves/test_stage.tres"],
		["stage", "stage", ["stage", "gold"], 777, gold, "src/main.gd"],
	]
	var ch: Array = t.changes()
	if ch.size() != want.size():
		return "바뀐 칸이 %d개다(%d개여야 한다, 지금 골드는 빼고): %s" % [ch.size(), want.size(), ch]
	for w in want:
		if not ch.any(func(c): return [c.table, c.kind, c.path, c.value, c.data, c.file] == w):
			return "바뀐 칸에 %s가 없다: %s" % [w, ch]
	if t.save() != want.size():
		return "저장한 칸 수가 %d개가 아니다" % want.size()
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(TUNING))
	if not parsed is Dictionary or parsed.get("changes", []).size() != want.size():
		return "%s에 칸 %d개가 담기지 않았다" % [TUNING, want.size()]
	var e = b.spawn_enemy("slime", Vector2i(10, 100))
	t.reset()
	var wave: Array = b.rounds[0][0]
	if b.ENEMY_KINDS.slime.hp != hp or not is_equal_approx(e.max_hp, hp) or b.STRUCTURE_KINDS.tower.damage != dmg \
			or wave.filter(func(x): return x.kind == "slime")[0].count != count or wave.any(func(x): return x.kind == "basic") or not t.changes().is_empty():
		return "되돌리기 뒤에도 데이터 값이 아닌 칸이 있다: %s" % [t.changes()]
	if b.gold != 12345:
		return "되돌리기가 지금 골드를 %d로 바꿨다" % b.gold
	if t.load_file() != want.size() or t.skipped != 0:
		return "불러오기가 %d칸을 넣고 %d칸을 건너뛰었다(%d·0이어야 한다)" % [t.load_file(), t.skipped, want.size()]
	if b.ENEMY_KINDS.slime.hp != hp + 6.0 or not is_equal_approx(e.max_hp, hp + 6.0) or not wave.any(func(x): return x.kind == "basic" and x.count == 2):
		return "불러오기 뒤 slime hp·전장의 slime·웨이브의 basic이 파일 값이 아니다"
	var f := FileAccess.open(TUNING, FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 1, "changes": [{"table": "enemies", "kind": "slime", "path": ["hp"], "value": 30},
		{"table": "enemies", "kind": "nope", "path": ["hp"], "value": 1}]}))
	f.close()
	var got: int = t.load_file()
	return check(got == 1 and t.skipped == 1 and b.ENEMY_KINDS.slime.hp == 30.0 and b.STRUCTURE_KINDS.tower.damage == dmg,
		"모르는 종류가 든 파일을 불러오자 %d칸 넣고 %d칸 건너뛰었다(1·1이어야 한다), slime hp %s" % [got, t.skipped, b.ENEMY_KINDS.slime.hp])

# EV777 · I240: 테스트 모드에서 바꾼 수치는 데이터 Resource와 다른 판에 닿지 않고, 같은 판의 새 도전에는 남는다
func ev777():
	var T = _T()
	if T == null:
		return "res://src/sim/tuning.gd가 없다"
	var b = _new(_stage())
	var t = T.new(b)
	var split: int = b.ENEMY_KINDS.slime.split.count
	var cost: int = b.HIRE.cost[0]
	var growth: float = b.LEVELS.growth
	t.put("적", "slime", ["split", "count"], split + 3)
	t.put("영입", "hire", ["cost", 0], cost + 7)
	t.put("레벨", "levels", ["growth"], growth + 0.3)
	var other = _new(_stage())
	if other.ENEMY_KINDS.slime.split.count != split or other.HIRE.cost[0] != cost or not is_equal_approx(other.LEVELS.growth, growth):
		return "뒤에 만든 다른 판의 데이터 표가 바뀌었다(split %d, cost %d, growth %s)" % [other.ENEMY_KINDS.slime.split.count, other.HIRE.cost[0], other.LEVELS.growth]
	if load("res://data/enemies/slime.tres").split.count != split or load("res://data/hire.tres").cost[0] != cost or not is_equal_approx(load("res://data/levels.tres").growth, growth):
		return "데이터 Resource가 바뀌었다"
	b.restart()
	return check(b.ENEMY_KINDS.slime.split.count == split + 3 and b.HIRE.cost[0] == cost + 7, "새 도전(restart) 뒤 바꾼 수치가 남지 않았다")

# EV778 · S289: 판 분류의 지금 골드는 바로, 시작 골드는 새 도전부터
func ev778():
	var T = _T()
	if T == null:
		return "res://src/sim/tuning.gd가 없다"
	var b = _new(_stage())
	var t = T.new(b)
	t.put("판", "stage", ["gold"], 500)
	if b.gold != 500 or _row(t.fields("판", "stage"), ["gold"]).value != 500:
		return "지금 골드를 500으로 하자 판 골드가 %d다" % b.gold
	t.put("판", "stage", ["stage", "gold"], 321)
	if b.gold != 500:
		return "시작 골드를 바꾸자 지금 골드가 %d가 됐다" % b.gold
	b.restart()
	return check(b.gold == 321, "시작 골드를 321로 바꾼 뒤 새 도전의 골드가 %d다" % b.gold)

# EV779 · I241: 판 분류의 거점·성벽 체력은 거점과 그 종류의 성곽에 비율대로 걸리고, 업그레이드 배율은 남는다
func ev779():
	var T = _T()
	if T == null:
		return "res://src/sim/tuning.gd가 없다"
	var b = _new(_stage())
	var t = T.new(b)
	var rows = t.fields("판", "stage")
	var base_hp: float = b.base.max_hp
	var wall: float = _row(rows, ["stage", "castle", "wall_hp"]).data
	var mult: float = load("res://src/sim/battle.gd").UPGRADE_MULT
	var k = b.castle.values().filter(func(x): return x.kind == "castle_wall")[0]
	var gate = b.castle.values().filter(func(x): return x.kind == "gate")[0]
	k.level = 2  # 2단계로 올린 성벽(S86)
	k.max_hp = wall * mult
	k.hp = k.max_hp / 2
	var gate_max: float = gate.max_hp
	b.base.hp = base_hp / 2
	t.put("판", "stage", ["stage", "base_hp"], base_hp * 3)
	if not (is_equal_approx(b.base.max_hp, base_hp * 3) and is_equal_approx(b.base.hp, base_hp * 1.5)):
		return "거점 체력을 세 배로 하자 거점이 %s/%s다(%s/%s여야 한다)" % [b.base.hp, b.base.max_hp, base_hp * 1.5, base_hp * 3]
	t.put("판", "stage", ["stage", "castle", "wall_hp"], wall * 2)
	if not (is_equal_approx(k.max_hp, wall * 2 * mult) and is_equal_approx(k.hp, wall * mult)):
		return "성벽 체력을 두 배로 하자 2단계 성벽이 %s/%s다(%s/%s여야 한다)" % [k.hp, k.max_hp, wall * mult, wall * 2 * mult]
	return check(gate.max_hp == gate_max, "성벽 체력을 바꾸자 성문 최대 체력이 바뀌었다")
