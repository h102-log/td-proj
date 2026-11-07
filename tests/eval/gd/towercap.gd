extends "res://tests/eval/gd/lib.gd"
# 타워 상한(S299·I246): 마을이 있는 판의 쏘는 구조물(타워·마법 타워·대포, 성벽 위 대포 포함)은 거점 4 + 다 지은 집 한 채마다 4개까지다.
# lib.gd·engineer.gd·cannon.gd·save.gd·hud.gd 머리의 계약에 더하는 API:
#   main.hud.towers — 인구 칸 오른쪽 [60,30,52,12]의 타워 칸(Label, I246 ④). 글 «타워 n/m», n ≥ m이면 글자색(테마 font_color)이 HudTheme.DANGER.
#     툴팁(main.hud.tip)에 «타워·마법 타워·대포 n개 · 상한 m(거점 4 + 집 k채 × 4)». 마을이 없는 판에서는 숨는다
#   data/structures/house.tres의 towers — 집 한 채 몫(S299 손잡이). EV806이 4인지 본다
# 그 밖은 있는 API의 행동으로 잰다: 상한에 닿으면 build(kind, cell)이 null이고 골드가 그대로다(준비 단계 즉시 건설·전투 단계 청사진 모두).
#   이어 짓기는 resume(s)가 돌려주는 공병, 건설 격자 칸 불투명도·정보 칸(grid.reason·grid.info, hud.gd 머리), 맵 클릭 거부는 안내 칩 글(main.hud.hint, I128 «✕ 이유»)이다.
#   기대 숫자(거점 4·집 한 채 4)는 SPEC 문장의 값을 박는다. 구현 상수(battle.gd 거점 몫·house.tres towers)를 기대값으로 쓰지 않는다
# sim 맵: cannon.gd와 같다. 9행이 가로 성곽(성문 5·15·25열), 위쪽 0~8행이 마을, 아래쪽 10~19행이 들판
# HUD: 시험 스테이지 게임 장면(main.tscn) 1라운드 준비 단계. 정문 앞 들판 (20,70) 둘레에 짓는다

const KINDS := ["tower", "magic", "cannon"]  # 쏘는 구조물(데이터 range > 0, I246 ①)
const TOP := Vector2i(12, 9)  # 성벽 칸
const IN := Vector2i(10, 5)  # 마을 칸(공병 자리)
const HOUSE := Vector2i(2, 1)  # 마을 칸(집 2×2의 칸)
const MOVE := Vector2i(26, 16)  # 대포를 옮길 들판 칸
const SPOTS := [Vector2i(2, 12), Vector2i(4, 12), Vector2i(6, 12), Vector2i(8, 12), Vector2i(10, 12), Vector2i(12, 12),
	Vector2i(14, 12), Vector2i(16, 12), Vector2i(18, 12), Vector2i(20, 12), Vector2i(22, 12), Vector2i(24, 12)]  # 들판 칸(한 칸씩 띄움)
const FIELD := Vector2i(20, 70)  # 시험 스테이지 정문 앞 들판
const DANGER := Color("ef3a0c")
const EMPTY := Vector2(320, 300)

func _battle():
	var gates := [Vector2i(5, 9), Vector2i(15, 9), Vector2i(25, 9)]
	var walls := []
	for x in 30:
		if Vector2i(x, 9) not in gates:
			walls.append(Vector2i(x, 9))
	return battle({"base": Vector2i(15, 4), "spawns": [Vector2i(15, 19)], "village": Rect2i(0, 0, 30, 9), "base_hp": BIG,
		"castle": {"walls": walls, "gates": gates, "wall_hp": 300, "gate_hp": 150},
		"waves": [[{"kind": "basic", "count": 1}], [{"kind": "basic", "count": 1}]]})

# 전투 단계를 연다. 웨이브 적은 바로 처치하고, 움직이지도 치지도 않는 적 하나를 구석에 남겨 전투 단계가 이어지게 한다.
# 들판 타워 사거리 안이라 체력을 크게 둔다
func _start(b):
	b.start_battle()
	run(b, 5.0, func(): return not b.enemies.is_empty())
	var idle = b.spawn_enemy("basic", Vector2i(0, 19), {"speed": 0, "sight": 0, "damage": 0, "hp": BIG})
	for x in b.enemies.duplicate():
		if x != idle:
			b.damage(x, BIG)
	return idle

# SPOTS[from..to)에 KINDS를 차례로 섞어 짓는다. 지어진 수
func _shooters(b, from: int, to: int) -> int:
	var n := 0
	for i in range(from, to):
		if b.build(KINDS[i % 3], SPOTS[i]) != null:
			n += 1
	return n

# EV806 · S299: 집 몫 손잡이(house.tres의 towers)가 4다. 마을 판(집 0채) 준비 단계에 타워·마법 타워·대포(성벽 위 대포 포함)를 섞어 4개까지 짓고
# 5번째는 거부(골드 그대로), 방벽은 상관없다. 집 한 채를 지으면 상한 8이라 4개 더 지어지고 9번째는 거부
func ev806():
	var d: Resource = ResourceLoader.load("res://data/structures/house.tres", "", ResourceLoader.CACHE_MODE_IGNORE)  # 디스크에서 새로 읽는다
	var per = d.get("towers") if d else null
	var knob: bool = per != null and (per is int or per is float) and per == 4
	var b = _battle()
	var first := _shooters(b, 0, 3)
	var top = b.build("cannon", TOP)
	var g: int = b.gold
	var fifth = b.build("tower", SPOTS[3])
	var gf: int = b.gold
	var refused: bool = fifth == null and gf == g
	var wall = b.build("wall", Vector2i(8, 15))
	var h = b.build("house", HOUSE)
	var more := _shooters(b, 4, 8)
	var g2: int = b.gold
	var ninth = b.build("magic", SPOTS[8])
	var refused2: bool = ninth == null and b.gold == g2
	return check(knob and first == 3 and top != null and refused and wall != null and h != null and h.complete and more == 4 and refused2,
		"house.tres towers %s(4) · 들판 셋 %d(3) · 성벽 위 대포 %s · 5번째 거부 %s(골드 %d → %d) · 방벽 %s · 집 %s(완성 %s) · 집 뒤 더 지은 수 %d(4) · 9번째 거부 %s" % [
			per, first, top, refused, g, gf, wall, h, h.complete if h else null, more, refused2])

# EV807 · I246: 전투 단계 청사진도 센다. 상한이면 새 청사진은 거부(골드 그대로)되고, 청사진을 취소하면 자리가 빈다.
# 짓는 중인 집은 몫을 주지 않아 상한이 그대로다. 상한인 채로 공병이 손을 뗀 미완성 마법 타워는 이어 짓기(resume)로 공병이 다시 붙는다(I246 ③).
# 둘째 판: 다 지은 집이 있는 전투 단계에 여섯째 청사진은 지어지고, 그 집이 부서지면 상한이 4로 줄어 일곱째는 거부된다(I246 ②)
func ev807():
	var b = _battle()
	var pre := _shooters(b, 0, 3)
	var crew := [b.place_merc("engineer", IN), b.place_merc("engineer", Vector2i(20, 16)), b.place_merc("engineer", Vector2i(22, 16))]
	if pre != 3 or crew.has(null):
		return "준비가 틀렸다: 준비 단계 쏘는 구조물 %d(3) · 공병 %s" % [pre, crew]
	_start(b)
	var bp = b.build("tower", SPOTS[3])
	if bp == null or bp.complete:
		return "준비가 틀렸다: 전투 단계 넷째 타워가 청사진이 아니다(%s)" % bp
	var g: int = b.gold
	var over = b.build("magic", SPOTS[4])
	var refused: bool = over == null and b.gold == g
	b.cancel(bp)
	var gone: bool = b.structure_at(SPOTS[3]) == null
	var again = b.build("magic", SPOTS[5])
	var h = b.build("house", HOUSE)
	run(b, 1.0)
	var g2: int = b.gold
	var more = b.build("cannon", SPOTS[6])
	var refused2: bool = more == null and b.gold == g2
	var idle: int = crew.filter(func(u): return u.alive and u.job == null).size()  # 놀고 있는 공병이 있어도 거부해야 상한 때문이다
	var hand = again.worker if again != null else null
	if hand != null:
		b.stop([hand])  # 짓던 공병이 손을 뗀다. 마법 타워는 미완성으로 남는다(I63)
	var back = b.resume(again) if again != null and again.worker == null and not again.complete else null
	var resumed: bool = back != null and again.worker == back
	# 둘째 판(따로 띄운 같은 맵): 집 한 채로 상한 8, 준비 단계에 쏘는 구조물 다섯
	var b2 = _battle()
	var h2 = b2.build("house", HOUSE)
	var five := _shooters(b2, 0, 5)
	var crew2 := [b2.place_merc("engineer", Vector2i(20, 16)), b2.place_merc("engineer", Vector2i(22, 16))]
	if h2 == null or not h2.complete or five != 5 or crew2.has(null):
		return "준비가 틀렸다: 둘째 판 집 %s(완성 %s) · 준비 단계 쏘는 구조물 %d(5) · 공병 %s" % [h2, h2.complete if h2 else null, five, crew2]
	_start(b2)
	var sixth = b2.build("tower", SPOTS[5])
	b2.damage(h2, BIG)
	var razed: bool = not h2.alive and b2.structure_at(HOUSE) == null
	var g3: int = b2.gold
	var seventh = b2.build("magic", SPOTS[6])
	var refused3: bool = seventh == null and b2.gold == g3
	var idle2: int = crew2.filter(func(u): return u.alive and u.job == null).size()
	return check(refused and gone and again != null and h != null and not h.complete and refused2 and idle > 0 and resumed
		and sixth != null and razed and refused3 and idle2 > 0,
		"청사진 넷 뒤 다섯째 거부 %s · 취소 뒤 빈 칸 %s · 취소 뒤 다시 지음 %s · 짓는 중인 집 %s(완성 %s) · 그때 새 청사진 거부 %s · 놀고 있는 공병 %d(1 이상) · 손 뗀 공병 %s 뒤 이어 짓기 공병 %s(붙어야) · 둘째 판 집 있을 때 여섯째 청사진 %s · 집 부서짐 %s · 그 뒤 일곱째 거부 %s · 놀고 있는 공병 %d(1 이상)" % [
			refused, gone, again, h, h.complete if h else null, refused2, idle, hand, back, sixth, razed, refused3, idle2])

# EV808 · S299: 집을 팔아 상한이 줄어도 있는 쏘는 구조물은 그대로이고 새로 짓기는 거부된다. 대포 옮기기는 상한을 넘은 채여도 된다.
# 마을이 없는 판에는 상한이 없다(쏘는 구조물 10개)
func ev808():
	var b = _battle()
	var h = b.build("house", HOUSE)
	var built := _shooters(b, 0, 8)
	var e = b.place_merc("engineer", Vector2i(20, 16))
	if h == null or not h.complete or built != 8 or e == null:
		return "준비가 틀렸다: 집 %s · 집 한 채로 지은 쏘는 구조물 %d(8) · 공병 %s" % [h, built, e]
	var eight: Array = SPOTS.slice(0, 8).map(func(c): return b.structure_at(c))
	b.sell([h])
	var kept: bool = SPOTS.slice(0, 8).map(func(c): return b.structure_at(c)) == eight
	var g: int = b.gold
	var extra = b.build("tower", SPOTS[8])
	var refused: bool = extra == null and b.gold == g
	var gun = b.structure_at(SPOTS[2])  # KINDS[2] 대포
	_start(b)
	b.move_cannon(gun, MOVE)
	var moved := run(b, 60.0, func(): return b.structure_at(MOVE) == gun and gun.complete)
	var bare = battle({"base_hp": BIG})  # 마을이 없는 판
	var free := 0
	for i in 10:
		if bare.build(KINDS[i % 3], Vector2i(2 + 2 * i, 4)) != null:
			free += 1
	return check(kept and refused and moved and free == 10,
		"집을 판 뒤 쏘는 구조물 8개 그대로 %s · 새로 짓기 거부 %s · 상한 넘은 채 대포 옮김 %s(새 칸 %s) · 마을 없는 판에 지은 수 %d(10)" % [
			kept, refused, moved, b.structure_at(MOVE), free])

# ── HUD(I246 ④⑤) — hud.gd·save.gd의 장면 띄우기·뒷정리 도우미를 옮겨 쓴다 ──

func _save():
	var s = load("res://src/sim/save.gd")
	s.path = "user://eval_save.dat"
	var st = load("res://src/settings.gd")
	st.path = "user://eval_settings.cfg"
	return s

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

# 컨테이너 배치는 다음 프레임으로 미뤄지는데 평가는 한 프레임 안에서 돈다. 위에서부터 직접 정렬한다
func _layout(main) -> void:
	for i in 2:
		for c in main.hud.find_children("*", "Container", true, false):
			c.notification(Container.NOTIFICATION_SORT_CHILDREN)

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

func _move(at: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = at
	e.global_position = at
	Engine.get_main_loop().root.push_input(e, true)

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

func _tip_of(main, btn) -> String:
	_layout(main)
	_fresh(main.hud.tip, btn)
	main.hud.tip._process(0.25)
	return _tip_text(main.hud.tip) if main.hud.tip.visible else ""

# 그 종류를 놓을 수 있는 칸 가운데 want에 가장 가까운 칸
func _near(b, kind: String, want: Vector2i) -> Vector2i:
	var best: Vector2i = b.placeable_cells(kind)[0]
	for c in b.placeable_cells(kind):
		if Vector2(c - want).length() < Vector2(best - want).length():
			best = c
	return best

func _red(l) -> bool:
	return l.get_theme_color("font_color").is_equal_approx(DANGER)

# EV809 · I246: 타워 칸은 인구 칸 오른쪽 [60,30,52,12]에 «타워 n/m»이다. 상한에 닿으면 빨강이고 툴팁에 상한 내역이 있다.
# 집 한 채를 지으면 «타워 4/8»로 빨강이 풀린다. 넷을 더 짓고 집을 팔면 «타워 8/4»로 상한을 넘어도 빨강이고, 전투 단계에서도 그대로 보인다.
# 마을이 없는 판에서는 숨는다
func ev809():
	var main = _prep()
	var b = main.view.battle
	var tw = main.hud.get("towers")
	if not tw is Label:
		_done(main)
		return "구현 없음: 타워 칸(main.hud.towers, Label)이 없다"
	var out := ""
	if b.structures.values().any(func(s): return s.range > 0.0):
		out = "준비가 틀렸다: 1라운드 준비 단계에 쏘는 구조물이 이미 있다"
	if out == "":
		var r: Rect2 = tw.get_global_rect()
		out = check(tw.is_visible_in_tree() and r.position.distance_to(Vector2(60, 30)) <= 0.5 and r.size.distance_to(Vector2(52, 12)) <= 0.5 and tw.text == "타워 0/4",
			"타워 칸 %s(보임 %s) · 글 «%s»(기대 [60,30,52,12] «타워 0/4»)" % [r, tw.is_visible_in_tree(), tw.text])
	if out == "":
		var n := 0
		for k in ["tower", "magic", "cannon", "tower"]:
			if b.build(k, _near(b, k, FIELD)) != null:
				n += 1
		_frame(main)
		var tip := _tip_of(main, tw)
		var line := "타워·마법 타워·대포 4개 · 상한 4(거점 4 + 집 0채 × 4)"
		out = check(n == 4 and tw.text == "타워 4/4" and _red(tw) and line in tip,
			"지은 쏘는 구조물 %d(4) · 글 «%s»(기대 «타워 4/4») · 빨강 %s · 툴팁 «%s»에 «%s»" % [n, tw.text, _red(tw), tip, line])
	var h = null
	if out == "":
		h = b.build("house", _near(b, "house", b.base.cell + Vector2i(6, 6)))
		_frame(main)
		var tip := _tip_of(main, tw)
		var line := "타워·마법 타워·대포 4개 · 상한 8(거점 4 + 집 1채 × 4)"
		out = check(h != null and h.complete and tw.text == "타워 4/8" and not _red(tw) and line in tip,
			"집 %s(완성 %s) 뒤 글 «%s»(기대 «타워 4/8») · 빨강 %s(아니어야) · 툴팁 «%s»에 «%s»" % [h, h.complete if h else null, tw.text, _red(tw), tip, line])
	if out == "":
		var n := 0
		for k in ["magic", "cannon", "tower", "magic"]:
			if b.build(k, _near(b, k, FIELD)) != null:
				n += 1
		b.sell([h])
		_frame(main)
		out = check(n == 4 and not h.alive and tw.text == "타워 8/4" and _red(tw),
			"집 뒤 더 지은 쏘는 구조물 %d(4) · 집 팔림 %s · 글 «%s»(기대 «타워 8/4») · 빨강 %s" % [n, not h.alive, tw.text, _red(tw)])
	if out == "":
		b.start_battle()
		_frame(main)
		out = check(b.state == "battle" and tw.is_visible_in_tree() and tw.text == "타워 8/4" and _red(tw),
			"start_battle 뒤 한 프레임: 판 상태 %s(battle) · 타워 칸 보임 %s · 글 «%s»(기대 «타워 8/4») · 빨강 %s" % [b.state, tw.is_visible_in_tree(), tw.text, _red(tw)])
	if out == "":
		b.village = Rect2i()  # 마을이 없는 판
		main.hud._process(0.0)
		out = check(not tw.is_visible_in_tree(), "마을을 없앤 판에서 타워 칸이 보인다(글 «%s»)" % tw.text)
	_done(main)
	return out

# EV810 · I246: 상한에 닿으면 건설 격자의 타워·마법 타워·대포 칸이 0.35로 흐리고 정보 칸에 «✕ 타워 가득»·«집을 지으면 4개 늘어난다», 방벽 칸은 그대로다.
# 타워 놓기 모드로 맵을 눌러 넷째를 지은 뒤 다음 칸을 누르면 거부되고 안내 칩에 «✕ 타워 가득 — 집을 지으면 4개 늘어난다»
func ev810():
	var main = _prep()
	var b = main.view.battle
	var hud = main.hud
	var g = hud.grid
	var c = main.controls
	var n := 0
	for k in ["tower", "magic", "cannon"]:
		if b.build(k, _near(b, k, FIELD)) != null:
			n += 1
	var out := "" if n == 3 else "준비가 틀렸다: 준비 단계에 쏘는 구조물을 셋 짓지 못했다(%d)" % n
	if out == "":
		c.handle(InputEventMouseMotion.new())  # 컨트롤이 판 단계(준비)를 먼저 보게 한다(EV795와 같다)
		g.cells.tower.pressed.emit()
		var fourth := _near(b, "tower", FIELD)
		click(c, MOUSE_BUTTON_LEFT, px(fourth))
		if c.placing != "tower" or b.structure_at(fourth) == null:
			out = "준비가 틀렸다: 타워 놓기 모드 «%s»로 %s를 눌러 넷째 타워가 서지 않았다(%s)" % [c.placing, fourth, b.structure_at(fourth)]
	if out == "":
		var fifth := _near(b, "tower", FIELD)
		var g0: int = b.gold
		click(c, MOUSE_BUTTON_LEFT, px(fifth))
		hud._process(0.0)
		var said: String = hud.hint.text if hud.hint.is_visible_in_tree() else ""
		var want := "✕ 타워 가득 — 집을 지으면 4개 늘어난다"
		out = check(b.structure_at(fifth) == null and b.gold == g0 and want in said,
			"상한에서 %s를 누른 뒤 지어짐 %s · 골드 %d → %d · 안내 칩 «%s»(기대 «%s»)" % [fifth, b.structure_at(fifth), g0, b.gold, said, want])
		click(c, MOUSE_BUTTON_RIGHT, px(fifth))  # 놓기 모드를 끝낸다
	if out == "":
		g._process(0.0)
		var dim: Array = KINDS.filter(func(k): return absf(g.cells[k].modulate.a - 0.35) > 0.01)
		out = check(dim.is_empty() and absf(g.cells.wall.modulate.a - 1.0) <= 0.01,
			"쏘는 구조물 넷 뒤 0.35가 아닌 칸 %s · 방벽 칸 불투명도 %.2f(1이어야 한다)" % [dim, g.cells.wall.modulate.a])
	if out == "":
		var bad := []
		for k in KINDS:
			_move(g.cells[k].get_global_rect().get_center())
			g._process(0.0)
			var s := _tip_text(g.info)
			if not g.reason.is_visible_in_tree() or not "타워 가득" in g.reason.text or not "집을 지으면 4개 늘어난다" in s:
				bad.append("%s 칸: 빨간 줄 «%s»(보임 %s) · 정보 칸 «%s»" % [k, g.reason.text, g.reason.is_visible_in_tree(), s])
		_move(g.cells.wall.get_global_rect().get_center())
		g._process(0.0)
		if g.reason.is_visible_in_tree():
			bad.append("방벽 칸: 빨간 줄 «%s»" % g.reason.text)
		out = check(bad.is_empty(), " · ".join(bad))
	_done(main)
	return out
