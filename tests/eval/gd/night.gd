extends "res://tests/eval/gd/hud.gd"
# 낮밤(S210~S214). lib·save·hud 머리의 계약에 더하는 API:
#   battle.nights — 라운드마다 웨이브 차례의 밤 {at, dark, fade}(S210). stage의 nights 키로 받는다. 없거나 비었으면 낮
#   battle.night(라운드, 웨이브) — 그 웨이브의 밤 사전. 낮이면 {}
#   battle.dark — 지금 어둠(0~1) · battle.wave_time — 이번 전투 단계가 시작된 뒤 흐른 초
#   battle.lights — 불빛 [자리(칸), 어둠 1일 때 반경(칸)] 목록. step 끝에 다시 모은다 · battle.seen(칸 좌표) — 보이나(S211)
#   main.view.foes() — 맵에 그리는 적(숨은 적 뺌, S213) · main.view.night — 어둠 덮개(ColorRect, S212). 맵(main.view)의 자식이다
#   main.view.night_params() — 덮개 셰이더 값 {dark, count, lights(PackedVector4Array: 맵 px 가운데 x·y, 지금 반경 px)}
#   main.view.tick(delta) — 덮개 값을 셰이더(night.material)에 넘기고, 어둠이 0이면 덮개를 숨긴다
#   main.hud.moon — 진행 칸의 달(CanvasItem, S214) · main.hud._wave_tip() — 웨이브 버튼 툴팁 [제목, 단축키, 비용, 본문, 이유]
#   main.hud.minimap.marks() — 미니맵 점 [사각형, 색](S209). 적 점 색은 ff3b3b

const W := [{"kind": "basic", "count": 1}]
const FOE := Color("ff3b3b")
const FAR := {"hp": 1000000.0, "speed": 0.0, "sight": 0.0, "damage": 0.0}  # 움직이지도 치지도 않는 시험용 적

# 밤 웨이브의 전투 단계로 들어가 어둠이 dark가 된 판(어둠은 0.05초 만에 오른다)
func _night_battle(over: Dictionary, dark := 1.0):
	var w: Array = over.get("waves", [W])
	over.merge({"waves": w, "nights": [w.map(func(_x): return {"at": 0.0, "dark": dark, "fade": 0.05})]}, true)
	var b = battle(over)
	return b

func _close(a: float, b: float, tol := 0.03) -> bool:
	return absf(a - b) <= tol

# EV438 · S210: 밤 웨이브는 at초 뒤 fade초 동안 dark까지 오르고(fade가 없으면 10초), 전투가 끝나면 1을 3초에 내리는 빠르기로 0까지 내린다
func ev438():
	var b = battle({"waves": [W, W, W, W], "nights": [[{}, {"at": 2.0, "dark": 0.8, "fade": 4.0}, {}, {"at": 0.0, "dark": 1.0}]]})
	b.start_battle()
	run(b, 5.0)
	var day: float = b.dark
	if not clear_wave(b) or b.state != "prep":
		return "1웨이브가 끝나지 않았다(%s)" % b.state
	b.start_battle()
	run(b, 1.9)
	var before: float = b.dark
	run(b, 2.1)
	var mid: float = b.dark
	run(b, 3.0)
	var full: float = b.dark
	if not (day == 0.0 and before == 0.0 and _close(mid, 0.4) and _close(full, 0.8)):
		return "낮 웨이브 5초 %.3f · 밤 웨이브 1.9초 %.3f(0) · 4초 %.3f(0.4) · 7초 %.3f(0.8)" % [day, before, mid, full]
	clear_wave(b)
	var cleared: float = b.dark
	run(b, 1.5)
	var dawn: float = b.dark
	run(b, 1.5)
	var morning: float = b.dark
	if not (b.state == "prep" and _close(dawn, cleared - 0.5, 0.05) and morning == 0.0):
		return "웨이브가 끝난 뒤(%s) 어둠 %.3f → 1.5초 %.3f(%.3f) → 3초 %.3f(0)" % [b.state, cleared, dawn, cleared - 0.5, morning]
	b.start_battle()
	clear_wave(b)
	b.start_battle()
	run(b, 5.0)
	return check(_close(b.dark, 0.5), "fade가 없는 밤 웨이브 5초 어둠 %.3f(0.5)" % b.dark)

# EV439 · S210: 게임 장면의 도전은 1라운드에 밤이 없고, 2~6라운드 밤 웨이브의 해 지는 때·어둠이 표와 같다
func ev439():
	var b = battle(load("res://src/main.gd").stage())
	var want := {  # [라운드, 웨이브](0부터) → [at, dark]
		Vector2i(1, 3): [30.0, 0.5], Vector2i(2, 2): [30.0, 0.6], Vector2i(2, 3): [20.0, 0.8],
		Vector2i(3, 1): [30.0, 0.7], Vector2i(3, 3): [10.0, 1.0],
		Vector2i(4, 1): [20.0, 0.8], Vector2i(4, 2): [10.0, 1.0], Vector2i(4, 3): [0.0, 1.0],
		Vector2i(5, 0): [20.0, 0.8], Vector2i(5, 1): [0.0, 1.0], Vector2i(5, 2): [0.0, 1.0], Vector2i(5, 3): [0.0, 1.0],
	}
	var bad := []
	for r in b.rounds.size():
		for w in b.rounds[r].size():
			var n: Dictionary = b.night(r, w)
			var got := [] if n.is_empty() else [n.get("at"), n.get("dark")]
			if got != want.get(Vector2i(r, w), []):
				bad.append("%d라운드 %d웨이브 %s(%s)" % [r + 1, w + 1, got, want.get(Vector2i(r, w), [])])
	return check(b.rounds.size() == 6 and bad.is_empty(), "라운드 %d개 · 다른 웨이브: %s" % [b.rounds.size(), "; ".join(bad)])

# EV440 · S211: 어둠 1에서 불빛 반경은 병사 3.5·궁수 2·영웅 2.5·거점 4·성문 2·타워 2이고, 방벽은 빛이 없다.
# 쓰러진 용병은 빛이 없고, 어둠 0.5면 반경이 두 배, 어둠 0이면 모두 보인다
func ev440():
	var over := {
		"heroes": [{"kind": "aias", "cell": Vector2i(12, 4)}],
		"castle": {"walls": [], "gates": [Vector2i(20, 4)], "wall_hp": 100, "gate_hp": 50},
	}
	var b = _night_battle(over)
	var soldier = b.place_merc("soldier", Vector2i(5, 16))
	b.place_merc("archer", Vector2i(5, 4))
	b.build("tower", Vector2i(12, 16))
	b.build("wall", Vector2i(18, 16))
	run(b, 0.05)
	var day: bool = b.seen(Vector2(2.9, 4)) and b.seen(Vector2(0, 0))
	b.start_battle()
	run(b, 0.2)
	if b.dark != 1.0:
		return "밤 웨이브 0.2초 뒤 어둠 %.3f(1)" % b.dark
	var probes := [  # [칸 좌표, 보여야 하나, 이름]
		[Vector2(8.4, 16), true, "병사 3.4칸"], [Vector2(8.6, 16), false, "병사 3.6칸"],
		[Vector2(3.1, 4), true, "궁수 1.9칸"], [Vector2(2.9, 4), false, "궁수 2.1칸"],
		[Vector2(14.4, 4), true, "영웅 2.4칸"], [Vector2(14.6, 4), false, "영웅 2.6칸"],
		[Vector2(25, 13.9), true, "거점 3.9칸"], [Vector2(25, 14.1), false, "거점 4.1칸"],
		[Vector2(20, 5.9), true, "성문 1.9칸"], [Vector2(20, 6.1), false, "성문 2.1칸"],
		[Vector2(12, 17.9), true, "타워 1.9칸"], [Vector2(12, 18.1), false, "타워 2.1칸"],
		[Vector2(18, 16.5), false, "방벽 0.5칸"],
	]
	var bad := probes.filter(func(p): return b.seen(p[0]) != p[1]).map(func(p): return "%s %s" % [p[2], not p[1]])
	b.damage(soldier, BIG)
	run(b, 0.05)
	var gone: bool = not b.seen(Vector2(8.4, 16))
	var half = _night_battle({}, 0.5)
	half.place_merc("soldier", Vector2i(5, 16))
	half.start_battle()
	run(half, 0.2)
	var wide: bool = half.dark == 0.5 and half.seen(Vector2(11.9, 16)) and not half.seen(Vector2(12.1, 16))
	return check(day and bad.is_empty() and gone and wide, "낮에 다 보임 %s · 어긋난 곳 %s · 쓰러진 병사 빛 없음 %s · 어둠 0.5 병사 7칸 %s(어둠 %.2f)" % [day, bad, gone, wide, half.dark])

# 밤(어둠 dark) 전투 단계로 들어간 게임 장면 1라운드: 영웅 둘이 정문 앞에 있다. 1웨이브는 비우고 칸마다 시험용 적(FAR)만 둔다. [게임 장면, 적들]
func _night_game(cells := [Vector2i(40, 55)], dark := 1.0) -> Array:
	var main = _prep()
	var b = main.view.battle
	b.nights = [b.waves.map(func(_x): return {"at": 0.0, "dark": dark, "fade": 0.05})]
	b.waves[0] = []
	var foes: Array = cells.map(func(c): return b.spawn_enemy("basic", c, FAR))
	b.start_battle()
	for i in 4:
		b.step(DT)
	return [main, foes]

# EV441 · S213: 밤에 불빛 밖의 적은 맵·미니맵에 그리지 않고, 클릭·명령의 대상이 되지 않으며, 패널에서 빠지고, 진행 칸이 비추지 않는다
func ev441():
	var got := _night_game([Vector2i(20, 13), Vector2i(31, 33)])  # 거점(30,13)에서 10칸 불빛 밖 · 영웅(31,31) 옆, 거점에서 20칸
	var main = got[0]
	var hid = got[1][0]
	var lit = got[1][1]
	var b = main.view.battle
	var c = main.controls
	var drawn: Array = main.view.foes()
	var dots: int = main.hud.minimap.marks().filter(func(m): return m[1] == FOE).size()
	var out := ""
	if b.dark != 1.0 or not (lit in drawn) or hid in drawn or dots != 1:
		out = "어둠 %.2f · 그리는 적에 보이는 적 %s·숨은 적 %s · 미니맵 적 점 %d(1)" % [b.dark, lit in drawn, hid in drawn, dots]
	if out == "":
		click(c, MOUSE_BUTTON_LEFT, px(Vector2i(20, 13)))
		var hid_shown = c.shown
		click(c, MOUSE_BUTTON_LEFT, px(Vector2i(31, 33)))
		var lit_shown = c.shown
		c.pick_hero(0)
		click(c, MOUSE_BUTTON_RIGHT, px(Vector2i(20, 13)))
		var hid_foe = c.order.get("foe")
		c.pick_hero(0)
		click(c, MOUSE_BUTTON_RIGHT, px(Vector2i(31, 33)))
		var lit_foe = c.order.get("foe")
		if hid_shown != null or lit_shown != lit or hid_foe != null or lit_foe != lit:
			out = "숨은 적 클릭 패널 %s · 보이는 적 클릭 패널 %s · 숨은 적 우클릭 대상 %s · 보이는 적 우클릭 대상 %s" % [hid_shown, lit_shown == lit, hid_foe, lit_foe == lit]
	if out == "":
		_away(main)
		main.hud.gauge.pressed.emit()
		out = _focused(main, lit.pos * 16 + Vector2(8, 8))
	if out == "":
		c.shown = lit
		lit.pos = Vector2(40, 45)  # 불빛 밖으로
		b.step(DT)
		main.hud._process(0.0)
		out = check(c.shown == null, "패널에 보이던 적이 숨었는데 패널이 %s를 보인다" % c.shown)
	_done(main)
	return out

# EV442 · S212: 어둠 덮개는 맵 (0,-92)에서 맵 위 띠 92px과 바닥 그림 크기(맵 + 아래 띠)를 덮고 클릭을 받지 않으며, 낮에는 숨고,
# 밤(어둠 0.5)에는 보이며 불빛마다 맵 px 가운데와 지금 반경(반경 ÷ 어둠 × 16)을 셰이더에 넘긴다
func ev442():
	var main = _prep()
	var v = main.view
	if not v.get("night") is ColorRect:
		_done(main)
		return "main.view.night가 ColorRect가 아니다(%s)" % v.get("night")
	_frame(main)
	var size: Vector2 = v.night.size
	var rows: int = v.battle.size.y
	var placed: bool = v.night.position == Vector2(0, -92) and v.night.material.get_shader_parameter("origin") == Vector2(0, -92) and v.night.get_parent() == v and v.night.mouse_filter == Control.MOUSE_FILTER_IGNORE
	var day_shown: bool = v.night.visible
	var day_count: int = v.night_params().count
	_done(main)
	main = _night_game([Vector2i(40, 55)], 0.5)[0]
	v = main.view
	var b = v.battle
	_frame(main)
	var p: Dictionary = v.night_params()
	var bad := []
	for i in b.lights.size():
		var l: Array = b.lights[i]
		var want := Vector4(l[0].x * 16 + 8, l[0].y * 16 + 8, l[1] / b.dark * 16, 0)
		if not p.lights[i].is_equal_approx(want):
			bad.append("%s → %s(%s)" % [l, p.lights[i], want])
	var shader: Dictionary = {"dark": v.night.material.get_shader_parameter("dark"), "count": v.night.material.get_shader_parameter("count")}
	var out := check(size == Vector2(960, 92 + rows * 16 + 72) and placed and not day_shown and day_count == 0
			and v.night.visible and p.dark == 0.5 and p.count == b.lights.size() and b.lights.size() >= 4 and bad.is_empty() and shader.dark == 0.5 and shader.count == p.count,
			"크기 %s · 자리·부모·클릭 무시 %s · 낮 보임 %s·불빛 %d · 밤 보임 %s·어둠 %.2f·불빛 %d(%d) · 셰이더 %s · 어긋난 불빛 %s" % [size, placed, day_shown, day_count, v.night.visible, p.dark, p.count, b.lights.size(), shader, bad.slice(0, 3)])
	_done(main)
	return out

# EV443 · S214: 다음 웨이브가 밤이면 진행 칸에 달이 보이고, 툴팁에 해 지는 때가 붙고, «다음 웨이브는 밤» 토스트가 뜬다.
# 밤 웨이브 전투 단계에는 달이 보이고, 해가 지기 시작할 때 «해가 진다» 토스트가 한 번 뜬다
func ev443():
	var main = _prep()
	var b = main.view.battle
	var hud = main.hud
	if hud.get("moon") == null:
		_done(main)
		return "main.hud.moon이 없다"
	b.nights = [[{}, {"at": 3.0, "dark": 0.6}, {}]]
	hud._process(0.0)
	var day_moon: bool = hud.moon.is_visible_in_tree()
	var day_tip: String = hud._wave_tip()[3]
	b.state = "battle"
	hud._process(0.0)
	b.wave_index = 1
	b.state = "prep"
	hud._process(0.0)
	hud.toasts._process(3.6)  # 미션 토스트가 막 떠서 3.5초 줄을 선다(I163)
	var said := _toasts(main).filter(func(t): return "다음 웨이브는 밤" in t)
	var tip: String = hud._wave_tip()[3]
	var out := check(not day_moon and not "해가 진다" in day_tip and hud.moon.is_visible_in_tree() and said.size() == 1 and "밤 — 전투 3초에 해가 진다" in tip,
			"낮 웨이브 달 %s·툴팁 %s · 밤 웨이브 달 %s · 토스트 %s · 툴팁 «%s»" % [day_moon, day_tip.replace("\n", "⏎"), hud.moon.is_visible_in_tree(), _toasts(main), tip.replace("\n", "⏎")])
	if out == "":
		hud.toasts._process(10.0)
		b.start_battle()
		var told := []
		for i in 80:  # 4초
			b.step(DT)
			hud._process(DT)
			hud.toasts._process(DT)
			if i == 50:  # 2.55초
				told.append(_toasts(main).filter(func(t): return "해가 진다" in t).size())
		told.append(_toasts(main).filter(func(t): return "해가 진다" in t).size())
		out = check(hud.moon.is_visible_in_tree() and told == [0, 1] and b.dark > 0.0, "전투 단계 달 %s · «해가 진다» 토스트 2.55초 %d·4초 %d · 어둠 %.2f" % [hud.moon.is_visible_in_tree(), told[0], told[1], b.dark])
	_done(main)
	return out

# EV564 · S240·S213: 숨은 밤 늑대는 맵에 그리지 않고 눈빛만 그린다. 숨은 다른 적과 불빛 안 밤 늑대는 눈빛이 없다
func ev564():
	var got := _night_game([Vector2i(20, 13)])
	var main = got[0]
	var b = main.view.battle
	if not b.ENEMY_KINDS.has("night_wolf"):
		_done(main)
		return "적 종류 night_wolf가 없다"
	var hid_basic = got[1][0]
	var hid_wolf = b.spawn_enemy("night_wolf", Vector2i(21, 13), FAR)
	var lit_wolf = b.spawn_enemy("night_wolf", Vector2i(31, 33), FAR)
	b.step(DT)
	var drawn: Array = main.view.foes()
	var eyes: Array = main.view.eyes() if main.view.has_method("eyes") else []
	var dark: float = b.dark
	_done(main)
	return check(dark > 0.0 and not (hid_wolf in drawn) and not (hid_basic in drawn) and (lit_wolf in drawn)
		and (hid_wolf in eyes) and not (hid_basic in eyes) and not (lit_wolf in eyes),
		"어둠 %.2f · 그리는 적: 숨은 밤 늑대 %s · 숨은 기본 적 %s · 불빛 안 밤 늑대 %s · 눈빛: 숨은 밤 늑대 %s · 숨은 기본 적 %s · 불빛 안 밤 늑대 %s" % [
			dark, hid_wolf in drawn, hid_basic in drawn, lit_wolf in drawn, hid_wolf in eyes, hid_basic in eyes, lit_wolf in eyes])

# EV585 · S213·S242: 숨은 알파 늑대의 덮치기 예고는 그린다. 숨은 다른 보스의 예고는 그리지 않는다
func ev585():
	var got := _night_game()  # 웨이브가 끝나지 않게 먼 곳의 적 하나
	var main = got[0]
	var b = main.view.battle
	if not b.ENEMY_KINDS.has("alpha_wolf") or not main.view.has_method("tellers"):
		_done(main)
		return "적 종류 alpha_wolf 또는 view.tellers()가 없다"
	var w = b.spawn_enemy("alpha_wolf", Vector2i(20, 13), FAR)
	var k = b.spawn_enemy("slime_king", Vector2i(20, 15), FAR)
	w.cast = {"id": "pounce", "left": 0.5, "at": Vector2(22, 13)}
	k.cast = {"id": "leap", "left": 0.5, "at": Vector2(22, 15)}
	var dark_t: Array = main.view.tellers()
	var drawn: Array = main.view.foes()
	var dark: float = b.dark
	b.dark = 0.0
	var day_t: Array = main.view.tellers()
	_done(main)
	return check(dark > 0.0 and (w in dark_t) and not (k in dark_t) and not (w in drawn) and not (k in drawn) and (w in day_t) and (k in day_t),
		"어둠 %.2f · 예고를 그리는 적: 알파 %s · 킹 %s · 그리는 적: 알파 %s · 킹 %s · 어둠 0 예고: 알파 %s · 킹 %s" % [
			dark, w in dark_t, k in dark_t, w in drawn, k in drawn, w in day_t, k in day_t])
