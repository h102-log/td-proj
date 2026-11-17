extends "res://tests/eval/gd/lib.gd"
# WBS 4.2 진행 저장(S181·I156·I157·I161). lib.gd·hire.gd 머리의 계약에 더하는 API:
#   res://src/sim/save.gd — static var path(저장 파일. 비어 있으면 쓰지 않는다) · snapshot(판) -> Dictionary(키 version 포함)
#     apply(판, 값) — 같은 스테이지로 새로 만든 판을 저장한 때로 되돌린다 · store(값) · write(판) — store(snapshot(판))
#     read() -> Dictionary — 없거나 못 읽거나 형식 판이 다르면 {} · erase()
#   res://src/settings.gd — static var path(설정 파일)
#   res://src/main.tscn — 게임 장면. Main(res://src/main.gd).resume: 비어 있지 않으면 _ready가 새 도전 대신 그 값을 불러온다
#     main.view.battle · main.controls · main.menus(ESC 메뉴) · main._process(delta)는 판을 delta만큼 돌리고 단계가 바뀌었으면 저장한다
#   ESC 메뉴: 게임 장면에서 ESC 키로 연다. 버튼은 글자로 찾는다(«계속»·«설정»·«메인 메뉴로»·«게임 종료»)
#   영입이 있던 때의 저장(I304): 저장 사전의 offers(목록)·rerolls(리롤 횟수)·lineup(출전 목록, heroes 사전의 차례 번호) 칸. 새 저장에는 없다
#     저장 사전의 heroes(영웅 사전 배열) · roster·deployed(그 차례 번호) · relics(유물 가방) · 영웅 사전의 relic(낀 유물 id)
# 저장 경로는 평가용 파일로 바꿔 둔다. 실제 저장(user://save.dat)을 건드리지 않게

const PATH := "user://eval_save.dat"
const HERO_SIX := ["aias", "sylvia", "seraphina", "vesper", "ignis", "chronos"]  # 고르기 창의 목록 = S97 표 차례(S373)

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
	var out := [b.state, b.round_index, b.wave_index, b.gold, b.base.hp, b.mission, b.offers]
	for e in b.enemies:
		out.append([e.kind, e.pos, e.hp])
	for u in b.units:
		out.append([u.kind, u.pos, u.hp, u.cd])
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

# 출전 영웅이 저마다 Q(방향 스킬)를 아래쪽으로 쓴다. 재사용 대기가 저장에 담겼는지 다음 웨이브 첫 시전이 가린다
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
	for p in [["tower", Vector2i(30, 67)], ["tower", Vector2i(34, 67)], ["wall", Vector2i(32, 70)], ["workshop", Vector2i(16, 24)]]:  # 들판은 남벽(59~63행, S203) 아래. 마을 시설은 작업장(병영은 없어졌다, S98 2026-11-12 변경)
		if a.build(p[0], _near(a, p[0], p[1])) == null:
			return "%s를 짓지 못했다" % p[0]
	for want in [Vector2i(32, 66), Vector2i(28, 65)]:  # 용병은 병영이 있어야 놓는다(S50)
		if a.place_merc("soldier", _near(a, "soldier", want)) == null:
			return "용병을 놓지 못했다"
	a.set_gate(a.castle[Vector2i(31, 63)], true)  # 정문 문루
	a.upgrade(a.castle[Vector2i(24, 63)])  # 24열 남벽
	a.start_battle()
	run(a, 15.0)
	_cast_q(a)
	if a.heroes.any(func(h): return h.cd.q <= 0.0):  # 웨이브가 끝날 때까지 기다리면 재사용 대기가 다 돌 수 있어 쓴 바로 뒤에 본다
		return "웨이브 1에서 Q를 쓰지 못했다"
	if not clear_wave(a) or a.state != "battle":  # 라운드 안에는 준비 단계가 없다(S17 2026-11-17 변경): 저장 시점은 라운드 사이다
		return "웨이브 1 뒤 전투 단계가 아니다(%s)" % a.state
	a.order_move(a.heroes, Vector2i(32, 78))
	run(a, 6.0)
	if not clear_round(a) or a.state != "cleared":
		return "1라운드를 이기지 못했다(%s)" % a.state
	var why := _twin(a, stage, func(x):
		x.next_round()
		x.start_battle()
		_cast_q(x))
	if why != "":
		return "라운드 사이: " + why
	if not clear_round(a) or a.state != "cleared":
		return "2라운드를 이기지 못했다(%s)" % a.state
	a.dismiss(a.roster[1])
	why = _twin(a, stage, func(x):
		x.next_round()
		x.start_battle()
		_cast_q(x))
	return "" if why == "" else "라운드 사이(영웅을 보낸 뒤): " + why

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
	clear_wave(b, 600.0)  # 마지막 웨이브는 적 82명이 2.5초 간격으로 나와 다 나오는 데만 205초다(I91 2026-10-21 변경)
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

# EV421 · I175: 게임 장면의 판은 Main.live_prep을 쥔다. 평가 기본(끔)은 옛 규칙이다
func ev421():
	var M = load("res://src/main.gd")
	var main = _game()
	var b = main.view.battle
	b.next_round()
	var wall = b.build("wall", _near(b, "wall", Vector2i(20, 30)))
	var why := ""
	if b.get("live_prep") != false or b._mercs() != 0 or wall == null or not wall.complete:
		why = "끈 게임 장면: live_prep %s · 용병 %d · 방벽 %s(완성 %s)" % [b.get("live_prep"), b._mercs(), wall, wall.complete if wall else null]
	_done(main)
	if why != "":
		return why
	M.live_prep = true
	main = _game()
	M.live_prep = false
	b = main.view.battle
	b.next_round()
	var engineers: int = b.units.filter(func(u): return u.kind == "engineer").size()
	var on: bool = b.get("live_prep") == true and engineers == 2
	_done(main)
	if not on:
		return "켠 게임 장면: live_prep %s · 공병 %d" % [b.get("live_prep"), engineers]
	return check(battle().get("live_prep") == false, "평가 헬퍼 판의 live_prep이 %s다" % battle().get("live_prep"))

# EV422 · S181: 준비 단계 실시간 판에서 공병이 일하는 중에 저장해 불러오면 일과 일꾼이 이어지고, 같은 입력에 같은 판이 된다
func ev422():
	var stage := _stage()
	var a = _new(stage)
	a.live_prep = true
	a.begin_hiring()
	a.offers[0] = "aias"
	if a.hire(0) == null:
		return "영입하지 못했다"
	a.next_round()
	a.state = "battle"  # 준비 단계 짓기는 바로 끝난다(S18 2026-11-06 변경). 공병이 일하는 판을 만들려고 잠시 전투 단계로 둔다
	var t = a.build("tower", _near(a, "tower", Vector2i(28, 61)))
	var f = a.build("workshop", _near(a, "workshop", Vector2i(26, 32)))
	a.state = "prep"
	if t == null or f == null or t.worker == null or f.worker == null:
		return "공병이 짓게 하지 못했다(타워 %s · 병영 %s)" % [t, f]
	run(a, 1.0)
	var S = _save()
	var c = _new(stage)
	S.apply(c, S.snapshot(a))
	for s in [t, f]:
		var k = c.structure_at(s.cell)
		var w = k.worker if k else null
		if w == null or w.job != k or w.pos != s.worker.pos:
			return "불러온 판의 %s: 일꾼 %s · 일꾼의 일이 그것 %s · 자리 %s / %s" % [s.kind, w, w.job == k if w else null, w.pos if w else null, s.worker.pos]
	var why := _twin(a, stage, func(x): x.live_prep = true)
	if why != "":
		return why
	return check(t.complete and f.complete, "20초 뒤 타워 완성 %s · 병영 완성 %s" % [t.complete, f.complete])

# EV476 · S221: 집의 가족과 가족을 정하는 난수가 저장된다
func ev476():
	var stage := {"size": Vector2i(30, 20), "base": Vector2i(25, 10), "base_hp": BIG, "spawns": [Vector2i(0, 10)], "gold": BIG, "waves": [],
		"hero_start": null, "village": Rect2i(0, 0, 30, 6), "seed": 7}
	var b = _new(stage)
	b.build("house", Vector2i(10, 3))
	b.build("house", Vector2i(14, 3))
	var c = _new(stage)
	_save().apply(c, _save().snapshot(b))
	var fam := func(x): return x.structures.values().map(func(s): return s.get("folk"))
	if fam.call(b).has(null) or fam.call(b).has([]) or fam.call(b) != fam.call(c):
		return "불러온 가족이 다르다: %s / %s" % [fam.call(b), fam.call(c)]
	b.build("house", Vector2i(18, 3))
	c.build("house", Vector2i(18, 3))
	return check(b.structures[Vector2i(18, 3)].folk == c.structures[Vector2i(18, 3)].folk,
		"불러온 뒤 지은 집의 가족이 다르다: %s / %s" % [b.structures[Vector2i(18, 3)].folk, c.structures[Vector2i(18, 3)].folk])

# EV482 · I179: 저장 판은 6이고, 판 5 저장은 읽지 않는다
func ev482():
	var S = _save()
	if S.VERSION != 7:
		return "저장 판이 %d다" % S.VERSION
	S.store({"version": 6, "probe": 1})
	var old: Dictionary = S.read()
	S.store({"version": 7, "probe": 1})
	var now: Dictionary = S.read()
	S.erase()
	return check(old.is_empty() and now.get("probe") == 1, "판 6 읽음 %s · 판 7 읽음 %s" % [old, now])

# EV503 · I183 ⑩: 주민 체력·가는 길·죽은 식구 수·신뢰·셈·주민 시계를 저장했다가 불러오면 같고, 이어 돌려도 주민 자리가 같다
func ev503():
	var stage := {"size": Vector2i(30, 20), "base": Vector2i(25, 10), "base_hp": BIG, "spawns": [Vector2i(0, 10)], "gold": BIG, "waves": [],
		"hero_start": null, "village": Rect2i(0, 0, 30, 6), "seed": 7}
	var b = _new(stage)
	var h1 = b.build("house", Vector2i(10, 3))
	var h2 = b.build("house", Vector2i(14, 3))
	b.build("church", Vector2i(20, 3))
	if b.get("people") == null or b.get("trust") == null or not ResourceLoader.exists("res://src/sim/folk.gd"):
		return "Battle.people·trust·src/sim/folk.gd가 없다"
	var F = load("res://src/sim/folk.gd")
	b.step(DT)
	b.damage(b.people.filter(func(v): return v.home == h1)[0], F.HP * 0.5)  # 교회로 가는 중
	b.damage(b.people.filter(func(v): return v.home == h2)[0], F.HP)  # 죽음
	b.trust = 3
	b.calm = 1
	run(b, 1.0)
	var c = _new(stage)
	_save().apply(c, _save().snapshot(b))
	var keep := func(x): return [x.trust, x.calm, x.get("evac_round"), snappedf(x.folk_clock, 0.0001), x.structures.values().map(func(s): return [s.get("folk"), s.get("lost")])]
	if keep.call(b) != keep.call(c):
		return "불러온 값이 다르다: %s / %s" % [keep.call(b), keep.call(c)]
	if not b.people.any(func(v): return v.m.get("away") != null):
		return "길 위의 주민이 없다(다친 주민이 교회로 가지 않았다)"
	run(b, 5.0)
	run(c, 5.0)
	var pb: Array = b.people.map(func(v): return v.pos)
	var pc: Array = c.people.map(func(v): return v.pos)
	var same: bool = pb.size() == pc.size() and range(pb.size()).all(func(k): return pb[k].distance_to(pc[k]) <= 0.01)
	return check(same, "이어 돌린 5초 뒤 주민 자리 %s / %s" % [pb, pc])

# EV511 · I184: 숙련·남은 라운드·다 큰 자녀·분가해 걷는 길을 저장했다가 불러오면 같고, 이어 돌려도 주민 자리가 같다
func ev511():
	var W := [{"kind": "basic", "count": 1}]
	var stage := {}
	var b = null
	var A = null
	for sd in range(1, 80):
		stage = {"size": Vector2i(30, 20), "base": Vector2i(25, 10), "base_hp": BIG, "spawns": [Vector2i(0, 10)], "gold": BIG, "waves": [],
			"hero_start": null, "village": Rect2i(0, 0, 30, 6), "rounds": [[W], [W], [W]], "seed": sd}
		b = _new(stage)
		A = b.build("house", Vector2i(10, 3))
		if A.folk.size() >= 2:
			break
		A = null
	if A == null:
		return "식구 둘 이상인 씨앗이 없다"
	var B = b.build("house", Vector2i(14, 3))
	if b.get("people") == null or not ResourceLoader.exists("res://src/sim/folk.gd"):
		return "Battle.people·src/sim/folk.gd가 없다"
	var F = load("res://src/sim/folk.gd")
	var g: Dictionary = A.folk.back()
	g.body = "man"
	g.grown = true
	for v in b.people.filter(func(x): return x.home == B):
		b.damage(v, F.HP)
	b.start_battle()
	if not clear_wave(b) or b.state != "cleared":
		return "1라운드가 끝나지 않았다(%s)" % b.state
	run(b, 1.0)
	if not b.people.any(func(v): return is_same(v.m, g) and v.m.get("away") != null):
		return "분가한 주민이 길 위에 없다"
	var c = _new(stage)
	_save().apply(c, _save().snapshot(b))
	var keep := func(x): return x.structures.values().map(func(s): return [s.get("folk"), s.get("lost")])
	if keep.call(b) != keep.call(c):
		return "불러온 값이 다르다: %s / %s" % [keep.call(b), keep.call(c)]
	run(b, 5.0)
	run(c, 5.0)
	var pb: Array = b.people.map(func(v): return v.pos)
	var pc: Array = c.people.map(func(v): return v.pos)
	var same: bool = pb.size() == pc.size() and range(pb.size()).all(func(k): return pb[k].distance_to(pc[k]) <= 0.01)
	return check(same, "이어 돌린 5초 뒤 주민 자리 %s / %s" % [pb, pc])

# EV529 · I187 ④: 분가하는 주민의 등짐(pack)은 길과 함께 저장되어, 불러온 판에서도 등짐 자세로 걷는다
func ev529():
	var W := [{"kind": "basic", "count": 1}]
	var stage := {}
	var b = null
	var A = null
	for sd in range(1, 80):
		stage = {"size": Vector2i(30, 20), "base": Vector2i(25, 10), "base_hp": BIG, "spawns": [Vector2i(0, 10)], "gold": BIG, "waves": [],
			"hero_start": null, "village": Rect2i(0, 0, 30, 6), "rounds": [[W], [W], [W]], "seed": sd}
		b = _new(stage)
		A = b.build("house", Vector2i(10, 3))
		if A.folk.size() >= 2:
			break
		A = null
	if A == null:
		return "식구 둘 이상인 씨앗이 없다"
	var B = b.build("house", Vector2i(14, 3))
	if b.get("people") == null or not ResourceLoader.exists("res://src/sim/folk.gd"):
		return "Battle.people·src/sim/folk.gd가 없다"
	var F = load("res://src/sim/folk.gd")
	var g: Dictionary = A.folk.back()
	g.body = "man"
	g.grown = true
	for v in b.people.filter(func(x): return x.home == B):
		b.damage(v, F.HP)
	b.start_battle()
	if not clear_wave(b) or b.state != "cleared":
		return "1라운드가 끝나지 않았다(%s)" % b.state
	run(b, 1.0)
	var c = _new(stage)
	_save().apply(c, _save().snapshot(b))
	run(c, 0.2)
	var who: Array = c.people.filter(func(v): return v.m.get("away") != null and not v.m.away["in"])
	return check(who.size() == 1 and who[0].m.away.get("pack", false) and who[0].pose == "carry_pack",
		"불러온 판의 길 위 주민 [자세, pack] %s" % [who.map(func(v): return [v.pose, v.m.away.get("pack")])])

# EV1104 · S98 2026-11-12 변경: 옛 저장의 병영·사격장은 불러올 때 판 것처럼(S69) 골드를 돌려주고 판에 두지 않는다.
# 활 장인을 맡았던 주민은 원래 직업으로 돌아가고, 그 시설을 짓던 공병은 일 없이 선다. 저장 판은 그대로 7이다
func ev1104():
	var S = _save()
	var a = _new(_stage())
	a.begin_hiring()
	a.next_round()
	var homes: Array = []
	for c in [Vector2i(24, 19), Vector2i(33, 17)]:
		homes.append(a.build("house", c))
	var w = a.build("workshop", Vector2i(42, 10))
	if homes.has(null) or w == null or homes.any(func(h): return h.folk.is_empty()):
		return "집 %s · 작업장 %s를 짓지 못했거나 집에 가족이 없다" % [homes, w]
	var e = a.place_merc("engineer", Vector2i(40, 20))
	var d: Dictionary = S.snapshot(a)
	var shop: Dictionary = d.structures.filter(func(f): return f.kind == "workshop")[0]
	var old_cells := [Vector2i(16, 24), Vector2i(16, 28)]
	for i in 2:  # 옛 판의 병영(다 지음)·사격장(짓는 중, 체력 절반)
		var f: Dictionary = shop.duplicate(true)
		f.kind = ["barracks", "archery"][i]
		f.cell = old_cells[i]
		f.paid = 40
		f.produces = [["soldier"], ["archer"]][i]
		f.folk = []
		f.hp = f.max_hp * (1.0 if i == 0 else 0.5)
		d.structures.append(f)
	var home: Dictionary = d.structures.filter(func(f): return f.kind == "house")[0]
	home.folk[0].craft = "bowyer"
	var unit: Dictionary = d.units.filter(func(u): return u is Dictionary and u.get("kind") == "engineer")[0]
	unit.job = [old_cells[1], "archery"]
	var b = _new(_stage())
	S.apply(b, d)
	var left: Array = b.structures.values().filter(func(s): return s.kind in ["barracks", "archery"])
	var want: int = a.gold + floori(40 * 1.0 * 0.8 + 0.0001) + floori(40 * 0.5 * 0.8 + 0.0001)
	var crafts: Array = []
	for s in b.structures.values():
		for m in s.folk:
			if m.has("craft"):
				crafts.append(m.craft)
	var be: Array = b.units.filter(func(u): return u.kind == "engineer")
	return check(left.is_empty() and b.gold == want and not "bowyer" in crafts and be.size() == 1 and be[0].job == null and S.VERSION == 7,
		"남은 옛 시설 %s · 골드 %d(기대 %d = 저장 %d + 32 + 16) · 시설 직업 %s · 공병 %d명 일 %s · 저장 판 %d(7)" % [left, b.gold, want, a.gold, crafts, be.size(), be.map(func(u): return u.job), S.VERSION])

func _kinds(hs: Array) -> Array:
	return hs.map(func(h): return h.kind)

# 시험 스테이지 판의 고르기 창에서 kinds를 차례로 고른 판(목록 앞 칸을 그 종류로 바꿔 넣는다 — EV306과 같은 방법). 출전 인원(셋)까지다
func _picked(kinds: Array):
	var b = _new(_stage())
	b.begin_hiring()
	for i in kinds.size():
		b.offers[i] = kinds[i]
		b.hire(i)
	return b

# 영웅 kinds의 저장 사전(옛 저장 꼴을 만드는 재료). 고르기 창에서 셋씩 고른 판의 저장에서 모은다. 전장에 선 적 없는 영웅이다
func _hero_dicts(kinds: Array) -> Array:
	var out := []
	for at in range(0, kinds.size(), 3):
		out.append_array(_save().snapshot(_picked(kinds.slice(at, at + 3))).heroes)
	return out

# 지금 라운드의 웨이브를 모두 이긴다. 라운드 사이가 되면 참
func _clear_round(b) -> bool:
	for i in 20:
		if b.state == "prep":
			b.start_battle()
		if b.state != "battle" or not clear_wave(b):
			break
	return b.state == "cleared"

# EV1132 · I304: 영입이 있던 때의 저장은 불러올 때 거른다. 목록·리롤 횟수는 버리고, 보유는 출전하던 영웅 먼저·대기 영웅으로 출전 인원까지다.
# 넘는 대기 영웅이 끼던 유물은 가방에 남는다. 채운 영웅은 다음 라운드에 서고, 모자란 판은 라운드 사이에 빈 자리를 고른다. 새 저장에는 그 칸들이 없다
func ev1132():
	var S = _save()
	var cells: Array = _stage().hero_cells
	var a = _picked(["aias", "sylvia"])
	a.next_round()
	var d: Dictionary = S.snapshot(a)
	var pool := _hero_dicts(["seraphina", "vesper", "ignis", "aias", "sylvia"])  # 대기 영웅 사전의 재료
	if a.state != "prep" or d.get("heroes", []).size() != 2 or pool.size() != 5:
		return "준비가 틀렸다: 단계 %s · 저장의 영웅 %d · 영웅 사전 %d" % [a.state, d.get("heroes", []).size(), pool.size()]
	var bare: Array = ["offers", "rerolls", "lineup"].filter(func(k): return d.has(k))  # 새 판의 저장에 남은 영입 칸
	for f in pool.slice(0, 3):
		d.heroes.append(f.duplicate(true))
	d.heroes[3].relic = "slime_crown"  # 버려질 대기 영웅(베스퍼)이 유물을 끼고 있다
	d.roster = [0, 1, 2, 3, 4]
	d.lineup = [0, 1]
	d.offers = ["vesper", "", ""]
	d.rerolls = 2
	d.relics = {"slime_crown": 0}
	var b = _new(_stage())
	S.apply(b, d)
	if _kinds(b.roster) != ["aias", "sylvia", "seraphina"] or _kinds(b.heroes) != ["aias", "sylvia"]:
		return "옛 저장(보유 다섯·출전 둘)을 불러온 보유 %s · 전장 %s(보유 [aias, sylvia, seraphina] · 전장 [aias, sylvia]여야 한다)" % [_kinds(b.roster), _kinds(b.heroes)]
	if b.offers != HERO_SIX or b.relics != {"slime_crown": 0} or b.roster.any(func(h): return h.relic != "") or b.gold != d.gold:
		return "불러온 판의 목록 %s(영웅 여섯) · 유물 가방 %s({slime_crown: 0}) · 보유 영웅이 낀 유물 %s(없어야) · 골드 %d(저장 %d)" % [b.offers, b.relics, b.roster.map(func(h): return h.relic), b.gold, d.gold]
	var again: Dictionary = S.snapshot(b)
	bare.append_array(["offers", "rerolls", "lineup"].filter(func(k): return again.has(k)))
	if not bare.is_empty():
		return "새 저장에 영입이 있던 때의 칸 %s가 있다(새 판의 저장에도, 옛 저장을 불러와 다시 뜬 저장에도 없어야 한다)" % [bare]
	if not _clear_round(b):
		return "불러온 판에서 1라운드를 이기지 못했다(%s)" % b.state
	b.next_round()
	var p = b.roster[2]
	var stood: bool = b.state == "prep" and b.heroes == b.roster and b.roster.all(func(h): return h in b.units and h.present) and near(p.pos, cells[2], 0.01) and p.hp == p.max_hp
	if not stood:
		return "다음 라운드: 단계 %s · 전장 %s · 세라피나 자리 %s(셋째 출전 칸 %s) 체력 %s/%s" % [b.state, _kinds(b.heroes), p.pos, cells[2], p.hp, p.max_hp]
	var e = _new(_stage())
	e.begin_hiring()
	var f: Dictionary = S.snapshot(e)
	f.heroes = [pool[3], pool[4], pool[0], pool[1]].map(func(x): return x.duplicate(true))  # 아이아스·실비아·세라피나·베스퍼
	f.roster = [0, 1, 2, 3]
	f.lineup = [3, 1]
	var g = _new(_stage())
	S.apply(g, f)
	if _kinds(g.roster) != ["sylvia", "vesper", "aias"]:
		return "보유 [0,1,2,3]·출전 [3,1]인 옛 저장을 불러온 보유 %s([sylvia, vesper, aias]여야 한다 — 출전하던 영웅을 보유 순서대로 먼저, 대기 영웅을 보유 순서대로)" % [_kinds(g.roster)]
	var one = _picked(["aias"])
	one.next_round()
	var o: Dictionary = S.snapshot(one)
	o.heroes.append(pool[4].duplicate(true))
	o.roster = [0, 1]
	o.lineup = [0]
	var h = _new(_stage())
	S.apply(h, o)
	var two: bool = _kinds(h.roster) == ["aias", "sylvia"] and _kinds(h.heroes) == ["aias"]
	if not two or not _clear_round(h):
		return "보유 둘·출전 하나인 옛 저장: 보유 %s · 전장 %s · 1라운드 뒤 단계 %s" % [_kinds(h.roster), _kinds(h.heroes), h.state]
	var third = h.hire(h.offers.find("ignis")) if "ignis" in h.offers else null
	return check(third != null and _kinds(h.roster) == ["aias", "sylvia", "ignis"], "영웅이 모자란 판의 라운드 사이에 이그니스를 고른 뒤 보유 %s(셋이어야 한다)" % [_kinds(h.roster)])

# EV1147 · I308 ③: 대열로 걷는 중에 저장해도 가는 자리(post)와 같이 걷기 상한(pace)이 담겨 불러온 판이 같은 결과를 낸다.
# 그 두 칸이 없는 옛 저장의 유닛은 자리·상한 없이 불러온다(저장 형식 판 그대로)
func ev1147():
	var stage := _stage()
	var a = _new(stage)
	var us := []
	for want in [Vector2i(40, 68), Vector2i(41, 68), Vector2i(42, 69), Vector2i(43, 69)]:
		var m = a.place_merc("soldier", _near(a, "soldier", want))
		if m == null:
			return "병사를 놓지 못했다"
		us.append(m)
	a.order_move(us, Vector2i(42, 76))
	run(a, 1.0)
	if us.any(func(u): return u.path.is_empty()):
		return "1초에 걷는 길이 빈 병사가 있다(걷는 중에 저장해야 한다)"
	var S = _save()
	var snap: Dictionary = S.snapshot(a)
	var dicts: Array = []
	for x in snap.units:
		if x is Dictionary and x.kind == "soldier":
			dicts.append(x)
	if dicts.size() != 4:
		return "snapshot의 병사 사전 %d개(4)" % dicts.size()
	for i in 4:
		if not dicts[i].get("pace", 0.0) > 0.0 or dicts[i].get("post") != us[i].path.back():
			return "snapshot의 병사 %d: pace %s(0보다 커야) · post %s(기대 길 끝 %s)" % [i, dicts[i].get("pace"), dicts[i].get("post"), us[i].path.back()]
	var old: Dictionary = snap.duplicate(true)
	var why := _twin(a, stage, func(_x): pass)
	if why != "":
		return why
	var cells := []
	for u in us:
		var c := cell_of(u)
		if u.pos.distance_to(Vector2(c)) > 0.05 or c in cells:
			return "20초 뒤 병사 자리 %s(기대 서로 다른 칸 중심)" % [us.map(func(v): return v.pos)]
		cells.append(c)
	for x in old.units:
		if x is Dictionary:
			x.erase("pace")
			x.erase("post")
	var c = _new(stage)
	S.apply(c, old)
	var back: Array = c.units.filter(func(u): return u.kind == "soldier")
	return check(c.units.size() == a.units.size() and back.size() == 4 and back.all(func(u): return u.pace == 0.0 and u.post == Vector2i(-1, -1)),
		"pace·post 없는 저장: 유닛 %d(%d) · 병사 %d(4) · pace %s · post %s(기대 0·(-1,-1))" % [c.units.size(), a.units.size(), back.size(), back.map(func(u): return u.get("pace")), back.map(func(u): return u.get("post"))])

# EV1154 · I309 ⑥: 줄에 선 채(길을 기다리는 유닛이 있는 채) 저장해도 기다리는 목적지 칸(due)이 담겨 불러온 판이 같은 결과를 낸다.
# 그 칸이 없는 옛 저장의 유닛은 기다리지 않는 것으로 읽는다(저장 형식 판 그대로)
func ev1154():
	var stage := _stage()
	stage.merge({"merc_cap": 40}, true)
	var a = _new(stage)
	var us := []
	for i in 20:
		var m = a.place_merc("soldier", _near(a, "soldier", Vector2i(38 + i % 5, 66 + i / 5)))
		if m == null:
			return "병사를 놓지 못했다"
		us.append(m)
	a.order_move(us, Vector2i(40, 80))
	if in_line(us).size() != 4:
		return "지시 직후 기다리는 병사 %d(4)" % in_line(us).size()
	var S = _save()
	var snap: Dictionary = S.snapshot(a)
	var dues: int = snap.units.filter(func(x): return x is Dictionary and x.get("due", Vector2i(-1, -1)) != Vector2i(-1, -1)).size()
	if dues != 4:
		return "snapshot에서 due가 있는 유닛 사전 %d(4)" % dues
	var old: Dictionary = snap.duplicate(true)
	var b = _new(stage)
	S.apply(b, snap)
	var back: Dictionary = S.snapshot(b)
	for k in snap:
		if back.get(k) != snap[k]:
			return "불러온 판의 snapshot «%s»가 다르다" % k
	if in_line(b.units).size() != 4:
		return "불러온 판에서 기다리는 병사 %d(4)" % in_line(b.units).size()
	for x in [a, b]:
		run(x, 20.0)
	var sa := _sum(a)
	var sb := _sum(b)
	if sa != sb:
		return "20초 뒤 두 판의 요약이 다르다"
	if not in_line(a.units).is_empty() or not in_line(b.units).is_empty():
		return "20초 뒤 기다리는 유닛 %d·%d(0)" % [in_line(a.units).size(), in_line(b.units).size()]
	for x in old.units:
		if x is Dictionary:
			x.erase("due")
	var c = _new(stage)
	S.apply(c, old)
	return check(c.units.size() == a.units.size() and in_line(c.units).is_empty(),
		"due 없는 저장: 유닛 %d(%d) · 기다리는 유닛 %d(0)" % [c.units.size(), a.units.size(), in_line(c.units).size()])
