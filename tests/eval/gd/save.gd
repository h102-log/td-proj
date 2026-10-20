extends "res://tests/eval/gd/lib.gd"
# WBS 4.2 진행 저장(S181·I156·I157·I161). lib.gd·hire.gd 머리의 계약에 더하는 API:
#   res://src/sim/save.gd — static var path(저장 파일. 비어 있으면 쓰지 않는다) · snapshot(판) -> Dictionary(키 version 포함)
#     apply(판, 값) — 같은 스테이지로 새로 만든 판을 저장한 때로 되돌린다 · store(값) · write(판) — store(snapshot(판))
#     read() -> Dictionary — 없거나 못 읽거나 형식 판이 다르면 {} · erase()
#   res://src/settings.gd — static var path(설정 파일)
#   res://src/main.tscn — 게임 장면. Main(res://src/main.gd).resume: 비어 있지 않으면 _ready가 새 도전 대신 그 값을 불러온다
#     main.view.battle · main.controls · main.menus(ESC 메뉴) · main._process(delta)는 판을 delta만큼 돌리고 단계가 바뀌었으면 저장한다
#   ESC 메뉴: 게임 장면에서 ESC 키로 연다. 버튼은 글자로 찾는다(«계속»·«설정»·«메인 메뉴로»·«게임 종료»)
# 저장 경로는 평가용 파일로 바꿔 둔다. 실제 저장(user://save.dat)을 건드리지 않게

const PATH := "user://eval_save.dat"

func _save():
	var s = load("res://src/sim/save.gd")
	s.path = PATH
	var st = load("res://src/settings.gd")
	st.path = "user://eval_settings.cfg"
	return s

# 시험 스테이지에 씨앗·골드를 더한 것
func _stage() -> Dictionary:
	var stage: Dictionary = load("res://src/main.gd").stage()
	stage.merge({"seed": 7, "gold": BIG}, true)
	return stage

func _new(stage: Dictionary):
	return load("res://src/sim/battle.gd").new(stage)

# 저장 파일을 새 판(시험 스테이지)에 불러온 것
func _loaded():
	var b = _new(load("res://src/main.gd").stage())
	_save().apply(b, _save().read())
	return b

# 새 게임으로 붙인 게임 장면
func _game():
	_save()
	load("res://src/main.gd").resume = {}
	var main = load("res://src/main.tscn").instantiate()
	Engine.get_main_loop().root.add_child(main)
	return main

func _done(main) -> void:
	Engine.get_main_loop().paused = false
	main.free()

# 한 프레임: 판 단계를 보고(main), 닫힌 창의 포커스를 푼다(HUD)
func _frame(main) -> void:
	main._process(0.0)
	main.hud._process(0.0)

func _key(code: int) -> void:
	for down in [true, false]:
		var e := InputEventKey.new()
		e.keycode = code
		e.physical_keycode = code
		e.pressed = down
		Engine.get_main_loop().root.push_input(e, true)

# 보이는 버튼 가운데 글자가 text인 것
func _button(node: Node, text: String):
	for n in node.find_children("*", "BaseButton", true, false):
		if n.is_visible_in_tree() and n.text == text:
			return n
	return null

func _press(node: Node, text: String) -> bool:
	var b = _button(node, text)
	if b:
		b.pressed.emit()
	return b != null

# 그 종류를 놓을 수 있는 칸 가운데 want에 가장 가까운 칸
func _near(b, kind: String, want: Vector2i) -> Vector2i:
	var best: Vector2i = b.placeable_cells(kind)[0]
	for c in b.placeable_cells(kind):
		if Vector2(c - want).length() < Vector2(best - want).length():
			best = c
	return best

# 두 판을 비교할 요약
func _sum(b) -> Array:
	var out := [b.state, b.round_index, b.wave_index, b.gold, b.base.hp, b.mission, b.commission, b.offers]
	for e in b.enemies:
		out.append([e.kind, e.pos, e.hp])
	for u in b.units:
		out.append([u.kind, u.pos, u.hp, u.mana])
	for c in b.structures:
		out.append([c, b.structures[c].kind, b.structures[c].hp])
	for c in b.castle:
		out.append([c, b.castle[c].hp])
	return out

# 판 a를 저장해 새 판에 불러오고, 두 판에 같은 입력(go)을 넣어 20초 돌린 뒤 비교한다
func _twin(a, stage: Dictionary, go: Callable) -> String:
	var S = _save()
	var snap = S.snapshot(a) if S else null
	if not snap is Dictionary or not snap.has("version"):  # 런타임 오류는 실행을 멈추지 않아 빈 값끼리 같다고 나올 수 있다
		return "snapshot이 비었다"
	var b = _new(stage)
	S.apply(b, snap)
	var back: Dictionary = S.snapshot(b)
	for k in snap:
		if back.get(k) != snap[k]:
			return "불러온 판의 snapshot «%s»가 다르다" % k
	for x in [a, b]:
		go.call(x)
		run(x, 20.0)
	var sa := _sum(a)
	var sb := _sum(b)
	for i in mini(sa.size(), sb.size()):
		if sa[i] != sb[i]:
			return "20초 뒤 요약 %d번째가 다르다: %s / %s" % [i, sa[i], sb[i]]
	return "" if sa.size() == sb.size() else "20초 뒤 요약 길이가 다르다: %d / %d" % [sa.size(), sb.size()]

# 출전 영웅이 저마다 Q(방향 스킬)를 아래쪽으로 쓴다. 재사용 대기·마나가 저장에 담겼는지 다음 웨이브 첫 시전이 가린다
func _cast_q(x) -> void:
	for h in x.heroes:
		x.cast(h, "q", h.pos + Vector2(0, 3))

# EV306 · I156: 저장해 불러온 판은 저장한 판과 같은 입력에 같은 결과를 낸다(준비 단계·라운드 사이)
# 아이아스(요새화 기절, 난수)와 실비아를 영입해 Q를 쓰고, 영웅을 적이 오는 길에 세워 둔다
func ev306():
	var stage := _stage()
	var a = _new(stage)
	a.begin_hiring()
	a.offers[0] = "aias"
	a.offers[1] = "sylvia"
	if a.hire(0) == null or a.hire(1) == null:
		return "영입하지 못했다"
	a.next_round()
	for p in [["tower", Vector2i(18, 13)], ["tower", Vector2i(22, 13)], ["wall", Vector2i(20, 16)], ["barracks", Vector2i(14, 5)]]:
		if a.build(p[0], _near(a, p[0], p[1])) == null:
			return "%s를 짓지 못했다" % p[0]
	for want in [Vector2i(20, 12), Vector2i(16, 11)]:  # 용병은 병영이 있어야 놓는다(S50)
		if a.place_merc("soldier", _near(a, "soldier", want)) == null:
			return "용병을 놓지 못했다"
	a.set_gate(a.castle[Vector2i(20, 9)], true)
	a.upgrade(a.castle[Vector2i(12, 9)])
	a.start_battle()
	run(a, 15.0)
	_cast_q(a)
	if not clear_wave(a) or a.state != "prep":
		return "웨이브 1 뒤 준비 단계가 아니다(%s)" % a.state
	if a.heroes.any(func(h): return h.cd.q <= 0.0):
		return "웨이브 1에서 Q를 쓰지 못했다"
	a.order_move(a.heroes, Vector2i(20, 24))
	run(a, 6.0)
	var why := _twin(a, stage, func(x):
		x.start_battle()
		_cast_q(x))
	if why != "":
		return "준비 단계: " + why
	for i in 20:
		if a.state == "cleared":
			break
		if a.state == "prep":
			a.start_battle()
		clear_wave(a)
	if a.state != "cleared":
		return "1라운드를 이기지 못했다(%s)" % a.state
	a.accept(0)
	a.dismiss(a.roster[1])
	why = _twin(a, stage, func(x):
		x.next_round()
		x.start_battle()
		_cast_q(x))
	return "" if why == "" else "라운드 사이: " + why

# EV307 · I157: 파일 왕복, 임시 파일, 깨진 파일·다른 형식 판·지운 뒤는 저장 없음
func ev307():
	var S = _save()
	var a = _new(_stage())
	a.begin_hiring()
	a.hire(0)
	a.next_round()
	S.store(S.snapshot(a))
	if S.read() != S.snapshot(a):
		return "읽은 값이 snapshot과 다르다"
	if FileAccess.file_exists(PATH + ".tmp"):
		return "임시 파일이 남았다"
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_buffer(PackedByteArray([7, 0, 0, 0, 250, 251, 252, 253, 1, 2]))
	f.close()
	if not S.read().is_empty():
		return "깨진 파일을 저장으로 읽었다"
	var d: Dictionary = S.snapshot(a)
	d.version = d.version + 1
	S.store(d)
	if not S.read().is_empty():
		return "형식 판이 다른 저장을 읽었다"
	S.store(S.snapshot(a))
	S.erase()
	return "" if S.read().is_empty() else "지운 뒤에도 저장이 있다"

# EV308 · S181: 영입 창·준비 단계·웨이브 시작 직전에 저장하고, 전투 단계에는 저장하지 않는다
func ev308():
	var S = _save()
	S.erase()
	var main = _game()
	var b = main.view.battle
	if _loaded().state != "hiring":
		_done(main)
		return "새 게임 직후 저장이 영입 창이 아니다"
	b.next_round()
	_frame(main)
	if _loaded().state != "prep":
		_done(main)
		return "1라운드로 넘어간 뒤 저장이 준비 단계가 아니다"
	var cell := _near(b, "wall", Vector2i(20, 16))
	b.build("wall", cell)
	b.start_battle()
	var c = _loaded()
	if c.state != "prep" or c.structure_at(cell) == null:
		_done(main)
		return "웨이브를 시작할 때의 저장이 «준비 단계 + 방벽»이 아니다(%s)" % c.state
	var bytes := FileAccess.get_file_as_bytes(PATH)
	for i in 200:
		main._process(DT)
	var in_battle: bool = b.state == "battle"
	var same := FileAccess.get_file_as_bytes(PATH) == bytes
	_done(main)
	if not in_battle:
		return "전투가 10초 안에 끝났다"
	return "" if same else "전투 단계에 저장 파일이 바뀌었다"

# EV309 · I157: 지거나 도전에 성공하면 저장을 지운다
func ev309():
	var S = _save()
	S.erase()
	var main = _game()
	var b = main.view.battle
	b.next_round()
	_frame(main)
	if S.read().is_empty():
		_done(main)
		return "준비 단계에 저장이 없다"
	b.damage(b.base, BIG)
	_frame(main)
	var lost: bool = b.state == "lost"
	var gone := not FileAccess.file_exists(PATH)
	_done(main)
	if not lost or not gone:
		return "진 판(%s)의 저장이 남았다" % b.state if lost else "거점을 부숴도 지지 않았다"
	main = _game()
	b = main.view.battle
	b.next_round()
	_frame(main)
	b.round_index = b.rounds.size() - 1
	b.waves = b.rounds[b.round_index]
	b.wave_index = b.waves.size() - 1
	b.start_battle()
	if S.read().is_empty():
		_done(main)
		return "마지막 웨이브를 시작할 때 저장이 없다"
	clear_wave(b)
	_frame(main)
	var won: bool = b.state == "won"
	gone = not FileAccess.file_exists(PATH)
	_done(main)
	if not won:
		return "마지막 웨이브를 이겨도 도전에 성공하지 않았다(%s)" % b.state
	return "" if gone else "도전에 성공한 판의 저장이 남았다"

# EV313 · I161: ESC 메뉴의 «메인 메뉴로»는 준비 단계면 저장하고, 전투 단계면 저장하지 않는다
func ev313():
	var S = _save()
	S.erase()
	var main = _game()
	var b = main.view.battle
	b.next_round()
	_frame(main)
	var cell := _near(b, "wall", Vector2i(20, 16))
	b.build("wall", cell)
	_key(KEY_ESCAPE)
	if not _press(main, "메인 메뉴로"):
		_done(main)
		return "ESC 메뉴에 «메인 메뉴로»가 없다"
	_done(main)
	if _loaded().structure_at(cell) == null:
		return "준비 단계에 나간 저장에 방벽이 없다"
	main = _game()
	b = main.view.battle
	b.next_round()
	_frame(main)
	b.start_battle()
	for i in 20:
		main._process(DT)
	var bytes := FileAccess.get_file_as_bytes(PATH)
	_key(KEY_ESCAPE)
	var pressed := _press(main, "메인 메뉴로")
	var same := FileAccess.get_file_as_bytes(PATH) == bytes
	_done(main)
	if not pressed:
		return "전투 단계의 ESC 메뉴에 «메인 메뉴로»가 없다"
	return "" if same else "전투 단계에 나갈 때 저장 파일이 바뀌었다"
