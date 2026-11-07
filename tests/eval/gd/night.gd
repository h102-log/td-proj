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
# 밤 전투(S300·I247, EV811~EV816): 더하는 API 없음. 체력·자리·재사용 대기로 잰다. 이미 있는 것을 더 쓴다:
#   stage 키 heroes [{kind, cell}](최대 레벨) · 용병 overrides accuracy · 적 overrides radius(몸 반지름)
#   Battle.cast(영웅, 칸, aim) · Battle.toggle_auto(영웅, 칸) · Battle.effect(대상, 키) · 영웅 cd[칸](kits.gd 머리)
#   몸이 닿음(I247 ③, S13): 두 몸 중심 거리 ≤ 두 몸 반지름 합 + 0.01(_touching과 같은 여유). 용병·영웅 몸 반지름은 기본 0.3이다(EV813)

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
	var out := check(size == Vector2(1024, 92 + rows * 16 + 72) and placed and not day_shown and day_count == 0
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

# EV670 · S279·S213: 숨은 투석기의 던지기 예고는 그리고, 숨은 폭파병의 도화선은 그리지 않는다. 일반 적 예고는 주황, 보스 예고는 빨강이다
func ev670():
	var got := _night_game()  # 웨이브가 끝나지 않게 먼 곳의 적 하나
	var main = got[0]
	var b = main.view.battle
	if not b.ENEMY_KINDS.has("catapult") or not b.ENEMY_KINDS.has("sapper") or not main.view.has_method("tell_color"):
		_done(main)
		return "적 종류 catapult·sapper 또는 view.tell_color()가 없다"
	var c = b.spawn_enemy("catapult", Vector2i(20, 13), FAR)
	var s = b.spawn_enemy("sapper", Vector2i(20, 15), FAR)
	var k = b.spawn_enemy("slime_king", Vector2i(31, 33), FAR)
	c.cast = {"id": "throw", "left": 0.5, "at": Vector2(22, 13)}
	s.cast = {"id": "fuse", "left": 1.0, "at": s.pos}
	k.cast = {"id": "leap", "left": 0.5, "at": Vector2(31, 35)}
	var dark_t: Array = main.view.tellers()
	var drawn: Array = main.view.foes()
	var dark: float = b.dark
	b.dark = 0.0
	var day_t: Array = main.view.tellers()
	var cols := [main.view.tell_color(c), main.view.tell_color(s), main.view.tell_color(k)]
	_done(main)
	return check(dark > 0.0 and (c in dark_t) and not (s in dark_t) and not (c in drawn) and not (s in drawn) and (c in day_t) and (s in day_t)
		and cols[0] == Color("ef692f") and cols[1] == Color("ef692f") and cols[2] == Color("ef3a0c"),
		"어둠 %.2f · 예고를 그리는 적: 투석기 %s · 폭파병 %s · 그리는 적: 투석기 %s · 폭파병 %s · 어둠 0 예고: 투석기 %s · 폭파병 %s · 색 %s" % [
			dark, c in dark_t, s in dark_t, c in drawn, s in drawn, c in day_t, s in day_t, cols.map(func(x): return x.to_html(false))])

# EV689 · S286·S285·S279: 숨은 열기구의 폭탄 예고와 비행선의 투하 표식은 그리고 몸은 숨긴다. 둘 다 일반 적 예고(주황)다
func ev689():
	var got := _night_game()
	var main = got[0]
	var b = main.view.battle
	if not b.ENEMY_KINDS.has("balloon") or not b.ENEMY_KINDS.has("airship"):
		_done(main)
		return "적 종류 balloon·airship이 없다"
	var e = b.spawn_enemy("balloon", Vector2i(20, 13), FAR)
	var a = b.spawn_enemy("airship", Vector2i(20, 15), FAR)
	e.cast = {"id": "bomb", "left": 1.0, "at": Vector2(22, 13)}
	a.cast = {"id": "drop", "left": 1.0, "at": Vector2(22, 15)}
	var told: Array = main.view.tellers()
	var drawn: Array = main.view.foes()
	var dark: float = b.dark
	var cols := [main.view.tell_color(e), main.view.tell_color(a)]
	_done(main)
	return check(dark > 0.0 and (e in told) and (a in told) and not (e in drawn) and not (a in drawn) and cols.all(func(c): return c == Color("ef692f")),
		"어둠 %.2f · 예고를 그리는 적: 열기구 %s · 비행선 %s · 그리는 적: 열기구 %s · 비행선 %s · 색 %s" % [
			dark, e in told, a in told, e in drawn, a in drawn, cols.map(func(x): return x.to_html(false))])

# EV700 · S213·S287: 숨은 전쟁 기계의 대포 예고는 그리고(보스 빨강) 몸은 숨긴다. 기관총 예고는 몸 둘레라 함께 숨긴다
func ev700():
	var got := _night_game()
	var main = got[0]
	var b = main.view.battle
	if not b.ENEMY_KINDS.has("war_machine"):
		_done(main)
		return "적 종류 war_machine이 없다"
	var w = b.spawn_enemy("war_machine", Vector2i(20, 13), FAR)
	w.cast = {"id": "cannon", "left": 1.0, "at": Vector2(23, 13)}
	var told: Array = main.view.tellers()
	var drawn: Array = main.view.foes()
	var col: Color = main.view.tell_color(w)
	w.cast = {"id": "mgun", "left": 1.0}
	var gun: Array = main.view.tellers()
	var dark: float = b.dark
	_done(main)
	return check(dark > 0.0 and (w in told) and not (w in drawn) and col == Color("ef3a0c") and not (w in gun),
		"어둠 %.2f · 대포 예고를 그리는 적에 %s · 몸을 그리는 적에 %s · 색 %s · 기관총 예고를 그리는 적에 %s" % [
			dark, w in told, w in drawn, col.to_html(false), w in gun])

# EV753 · S288: 숨은 고블린 대장의 폭탄 원은 그리고(보스 빨강) 몸은 숨긴다. 철퇴 부채꼴은 몸 둘레라 함께 숨긴다
func ev753():
	var got := _night_game()
	var main = got[0]
	var b = main.view.battle
	if not b.ENEMY_KINDS.has("chief"):
		_done(main)
		return "적 종류 chief가 없다"
	var e = b.spawn_enemy("chief", Vector2i(20, 13), FAR)
	e.cast = {"id": "bombs", "left": 0.5, "spots": [Vector2(22, 13)]}
	var told: Array = main.view.tellers()
	var drawn: Array = main.view.foes()
	var col: Color = main.view.tell_color(e)
	e.cast = {"id": "cleave", "left": 0.5, "dir": 0.0}
	var fan: Array = main.view.tellers()
	var dark: float = b.dark
	_done(main)
	return check(dark > 0.0 and (e in told) and not (e in drawn) and col == Color("ef3a0c") and not (e in fan),
		"어둠 %.2f · 폭탄 예고를 그리는 적에 %s · 몸을 그리는 적에 %s · 색 %s · 철퇴 예고를 그리는 적에 %s" % [
			dark, e in told, e in drawn, col.to_html(false), e in fan])

# ── 밤 전투(S300·I247) ──
# 판은 lib 판(거점 (25,10), 불빛 4칸)이고 시험은 모두 거점 불빛 밖 위쪽에서 한다. 과녁은 준비 단계에 놓고, 첫 스텝은 아직 낮의 불빛으로 고르니(I247 ①)
# 그 사이에 쏜 것이 닿을 1초 뒤부터 잰다

const NONE := [{"kind": "basic", "count": 0}]  # 적이 나오지 않는 웨이브. 판에 적이 남아 있는 동안 전투 단계가 이어진다
const LAMP := {"damage": 0.0, "sight": 0.0}  # 불빛만 내는 병사: 치지도 쫓지도 않는다

# 어둠 dark인 밤 웨이브 판(적이 나오지 않는다). heroes는 [[종류, 칸], ...]이고 기본 공격을 끈다
func _dusk(dark := 1.0, heroes := []):
	var b = _night_battle({"waves": [NONE], "heroes": heroes.map(func(h): return {"kind": h[0], "cell": h[1]})}, dark)
	for h in b.heroes:
		h.damage = 0.0
	return b

# 칸 좌표 at에 선 움직이지도 치지도 않는 과녁
func _post(b, at: Vector2, over := {}):
	var e = b.spawn_enemy("basic", Vector2i(at.round()), FAR.merged(over, true))
	e.pos = at
	return e

# t0초 돌린 뒤 secs초 동안 과녁마다 잃은 체력
func _losses(b, foes: Array, t0: float, secs: float) -> Array:
	run(b, t0)
	var hp0: Array = foes.map(func(e): return e.hp)
	run(b, secs)
	return range(foes.size()).map(func(i): return hp0[i] - foes[i].hp)

# EV811 · S300·I247 ①②: 어둠 1에서 타워(불빛 2칸)는 5칸 앞, 궁수(불빛 2칸)는 4칸 앞, 이그니스(불빛 2.5칸, 사거리 4칸)의 기본 공격은 3칸 앞의 숨은 과녁을 3초 동안 쏘지 않는다.
# 과녁 옆 칸에 불빛만 내는 병사가 서 있으면(시야 공유) 쏘고, 어둠 0이면 쏜다
func ev811():
	var bad := []
	for kind in ["tower", "archer", "hero"]:
		var at: Vector2i = {"tower": Vector2i(10, 4), "archer": Vector2i(9, 4), "hero": Vector2i(8, 4)}[kind]
		for mode in ["숨음", "공유", "어둠 0"]:
			var dark := 0.0 if mode == "어둠 0" else 1.0
			# 영웅 판은 _dusk가 끄는 공격력을 살려 둔다
			var b = _night_battle({"waves": [NONE], "heroes": [{"kind": "ignis", "cell": Vector2i(5, 4)}]}, dark) if kind == "hero" else _dusk(dark)
			if mode == "공유":
				b.place_merc("soldier", at + Vector2i(1, 0), LAMP)
			var shooter = b.build("tower", Vector2i(5, 4)) if kind == "tower" else (b.place_merc("archer", Vector2i(5, 4)) if kind == "archer" else (b.heroes[0] if not b.heroes.is_empty() else null))
			var e = _post(b, Vector2(at))
			b.start_battle()
			var lost: float = _losses(b, [e], 1.0, 3.0)[0]
			var lit: bool = b.seen(e.pos)
			var want: bool = mode != "숨음"
			if shooter == null or lit != want or (lost > 0.0) != want:
				bad.append("%s %s: 보임 %s · 3초 동안 잃은 체력 %s(%s)" % [kind, mode, lit, lost, "> 0" if want else "0"])
	return check(bad.is_empty(), "; ".join(bad))

# EV812 · S300·I247 ②: 어둠 1에서 병사는 인식 범위(4칸) 안이지만 자기 불빛(3.5칸) 밖인 3.9칸의 숨은 과녁을 쫓지 않고 서 있다.
# 과녁 옆 칸에 공격력 0 타워(불빛 2칸)가 있으면 쫓아가 친다
func ev812():
	var got := []
	for shared in [false, true]:
		var b = _dusk()
		var s = b.place_merc("soldier", Vector2i(5, 4))
		if shared:
			b.build("tower", Vector2i(10, 4), {"damage": 0.0})
		var e = _post(b, Vector2(8.9, 4))
		b.start_battle()
		run(b, 0.5)
		var p0: Vector2 = s.pos
		var lit: bool = b.seen(e.pos)
		run(b, 2.5)
		got.append({"lit": lit, "moved": s.pos.distance_to(p0), "gap": s.pos.distance_to(e.pos), "hit": e.hp < e.max_hp})
	var hid: Dictionary = got[0]
	var seen: Dictionary = got[1]
	return check(not hid.lit and hid.moved < 0.05 and not hid.hit and seen.lit and seen.gap <= 1.3 and seen.hit,
		"숨은 과녁: 보임 %s · 0.5~3초에 병사가 움직인 거리 %.2f(0) · 맞음 %s · 타워가 비춘 과녁: 보임 %s · 3초 뒤 병사와의 거리 %.2f(1.3 이하) · 맞음 %s" % [
			hid.lit, hid.moved, hid.hit, seen.lit, seen.gap, seen.hit])

# EV813 · S300·I247 ③: 어둠 1에서 궁수(불빛 2칸, 명중률 1)는 중심이 2.305칸 떨어진 숨은 과녁을, 몸이 닿는 큰 과녁(반지름 2)이면 쏘고
# 몸이 닿지 않는 보통 과녁(반지름 0.3)이면 사거리(5칸) 안이어도 쏘지 않는다
func ev813():
	var got := []
	for r in [2.0, 0.3]:
		var b = _dusk()
		b.place_merc("archer", Vector2i(5, 4), {"accuracy": 1.0})
		var e = _post(b, Vector2(7.305, 4), {"radius": r})
		b.start_battle()
		got.append([_losses(b, [e], 1.0, 3.0)[0], b.seen(e.pos)])
	return check(got[0][0] > 0.0 and got[1][0] == 0.0 and not got[0][1] and not got[1][1],
		"3초 동안 잃은 체력: 몸이 닿은 큰 과녁 %s(> 0, 보임 %s) · 닿지 않은 보통 과녁 %s(0, 보임 %s)" % [got[0][0], got[0][1], got[1][0], got[1][1]])

# EV814 · S300·I247 ④: 어둠 1에서 12칸 앞 과녁을 대상 공격하러 걸어가던 병사는 과녁을 비추던 병사가 쓰러져 과녁이 숨으면 대상 공격을 놓아 더 걸어가지 않는다.
# 12칸 앞 과녁에게 걸어가서 E를 쓰려던 베스퍼도 과녁이 숨으면 E를 쓰지 않는다(재사용 대기가 시작되지 않고 사슬이 걸리지 않는다)
func ev814():
	var b = _dusk()
	var s = b.place_merc("soldier", Vector2i(3, 4))
	var lamp = b.place_merc("soldier", Vector2i(16, 4), LAMP)
	var e = _post(b, Vector2(15, 4))
	b.start_battle()
	run(b, 0.3)
	var lit: bool = b.seen(e.pos)
	b.order_attack([s], e)
	var p0: Vector2 = s.pos
	run(b, 1.0)
	var went: float = s.pos.distance_to(p0)
	b.damage(lamp, BIG)
	run(b, 0.2)
	var hid: bool = not b.seen(e.pos)
	var p1: Vector2 = s.pos
	run(b, 2.0)
	var on: float = s.pos.distance_to(p1)
	var v = _dusk(1.0, [["vesper", Vector2i(2, 4)]])
	var h = v.heroes[0]
	var lamp2 = v.place_merc("soldier", Vector2i(15, 4), LAMP)
	var f = _post(v, Vector2(14, 4))
	v.start_battle()
	run(v, 0.3)
	var ordered: bool = v.seen(f.pos) and v.cast(h, "e", f)
	var q0: Vector2 = h.pos
	run(v, 0.5)
	var walked: float = h.pos.distance_to(q0)
	v.damage(lamp2, BIG)
	run(v, 4.0)
	var unused: bool = h.cd.e <= 0.0 and v.effect(f, "chain") == null
	return check(lit and went > 1.0 and hid and on < 0.05 and ordered and walked > 0.5 and unused,
		"병사: 보이는 과녁에 걸어감 %.2f칸(%s) · 숨은 뒤(%s) 2초에 더 걸은 거리 %.2f(0) · 베스퍼: E 걸어가기 %s · %.2f칸 · 숨은 뒤 E를 쓰지 않음 %s(대기 %.2f)" % [
			went, lit, hid, on, ordered, walked, unused, h.cd.e])

# EV815 · S300·I247 ⑤: 어둠 1에서 타워는 가장 가까운 숨은 적(3칸) 대신 병사 불빛 안의 보이는 적(7칸)을 노리고, 그 화살 길 위 4칸의 숨은 적이 화살에 맞는다.
# 대포도 가장 가까운 숨은 적 대신 보이는 적을 노리고, 그 적 0.8칸 옆 범위 피해(1칸) 안의 숨은 적도 맞는다.
# 공격력 0 베스퍼(불빛 2.5칸)가 4칸 앞 숨은 과녁 자리에 쓴 Q 독안개(장판)는 그 과녁을 3초 동안 깎는다
func ev815():
	var bad := []
	for kind in ["tower", "cannon"]:
		var b = _dusk()
		var s = b.build(kind, Vector2i(5, 4))
		b.place_merc("soldier", Vector2i(15, 4), LAMP)
		var first = _post(b, Vector2(5, 7))
		var lit = _post(b, Vector2(12, 4))
		var side = _post(b, Vector2(9, 4) if kind == "tower" else Vector2(11.2, 4))  # 화살 길 위 · 범위 피해 안
		b.start_battle()
		var lost: Array = _losses(b, [first, lit, side], 1.0, 5.0)
		var seen: Array = [first, lit, side].map(func(x): return b.seen(x.pos))
		var ok: bool = s != null and seen == [false, true, false] and lost[0] == 0.0 and lost[2] > 0.0 and (kind == "tower" or lost[1] > 0.0)
		if not ok:
			bad.append("%s: 보임(가까운 숨은 적·보이는 적·%s) %s · 5초 동안 잃은 체력 %s — 가까운 숨은 적 0, 화살 길·범위 안 숨은 적 > 0, 대포의 보이는 적 > 0이어야 한다" % [kind, "화살 길 위 숨은 적" if kind == "tower" else "범위 안 숨은 적", seen, lost])
	var v = _dusk(1.0, [["vesper", Vector2i(4, 4)]])
	var z = _post(v, Vector2(8, 4))
	v.start_battle()
	run(v, 0.3)
	var hp0: float = z.hp
	var used: bool = not v.heroes.is_empty() and v.cast(v.heroes[0], "q", z.pos)
	run(v, 3.0)
	var zoned: float = hp0 - z.hp
	if not used or zoned <= 0.0 or v.seen(z.pos):
		bad.append("베스퍼 Q 독안개: 씀 %s · 3초 동안 숨은 과녁이 잃은 체력 %s(> 0) · 보임 %s(false)" % [used, zoned, v.seen(z.pos)])
	return check(bad.is_empty(), "; ".join(bad))

# EV816 · S300·I247 ②: 어둠 1에서 E 오토를 켠 베스퍼는 사거리 안 숨은 적 셋 무리에는 1초 동안 E를 쓰지 않고, 그 무리를 병사 불빛이 비추면 쓴다.
# 세라피나가 궁수(불빛 2칸)에게 쓴 Q는 궁수 2.5칸 옆의 숨은 적에게 튀지 않고(피해 0), 어둠 0이면 튄다.
# 베스퍼가 병사 불빛 안의 보이는 과녁에 손으로 쓴 E(영혼 사슬, 반경 3칸)는 그 과녁 2.5칸 옆의 숨은 과녁을 묶지 않고, 어둠 0이면 묶는다
func ev816():
	var auto := []
	for shared in [false, true]:
		var b = _dusk(1.0, [["vesper", Vector2i(4, 4)]])
		var h = b.heroes[0]
		if shared:
			b.place_merc("soldier", Vector2i(10, 4), LAMP)
		var pack: Array = [Vector2(8.5, 4), Vector2(9, 3), Vector2(9, 5)].map(func(p): return _post(b, p))
		b.start_battle()
		run(b, 0.3)
		b.toggle_auto(h, "e")
		run(b, 1.0)
		auto.append([h.cd.e > 0.0, pack.filter(func(x): return b.seen(x.pos)).size()])
	var hop := []
	for dark in [1.0, 0.0]:
		var b = _dusk(dark, [["seraphina", Vector2i(4, 14)]])
		var h = b.heroes[0]
		var a = b.place_merc("archer", Vector2i(7, 14), {"damage": 0.0})
		var e = _post(b, Vector2(9.5, 14))
		b.start_battle()
		run(b, 0.3)
		var hp0: float = e.hp
		var used: bool = b.cast(h, "q", a)
		hop.append([used, hp0 - e.hp, b.seen(e.pos)])
	var tie := []
	for dark in [1.0, 0.0]:
		var b = _dusk(dark, [["vesper", Vector2i(4, 4)]])
		b.place_merc("soldier", Vector2i(8, 6), LAMP)  # 사슬 대상만 비춘다
		var hub = _post(b, Vector2(8, 4))
		var side = _post(b, Vector2(8, 1.5))  # 대상에서 2.5칸 · 병사에서 4.5칸 · 베스퍼에서 4.7칸
		b.start_battle()
		run(b, 0.3)
		var seen := [b.seen(hub.pos), b.seen(side.pos)]
		var used: bool = not b.heroes.is_empty() and b.cast(b.heroes[0], "e", hub)
		tie.append([used, seen, b.effect(hub, "chain") != null, b.effect(side, "chain") != null])
	return check(auto[0] == [false, 0] and auto[1] == [true, 3] and hop[0][0] and hop[0][1] == 0.0 and not hop[0][2] and hop[1][0] and hop[1][1] > 0.0
			and tie[0] == [true, [true, false], true, false] and tie[1] == [true, [true, true], true, true],
		"베스퍼 E 오토 [썼나, 보이는 적 수]: 숨은 무리 %s([false, 0]) · 비춘 무리 %s([true, 3]) · 세라피나 Q [썼나, 옆 적이 잃은 체력, 보임]: 어둠 1 %s([true, 0, false]) · 어둠 0 %s(체력 > 0) · 베스퍼 E [썼나, [대상 보임, 옆 과녁 보임], 대상 사슬, 옆 과녁 사슬]: 어둠 1 %s([true, [true, false], true, false]) · 어둠 0 %s([true, [true, true], true, true])" % [
			auto[0], auto[1], hop[0], hop[1], tie[0], tie[1]])
