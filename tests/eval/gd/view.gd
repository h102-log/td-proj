extends "res://tests/eval/gd/hud.gd"
# 지대·집결·표식 그림과 진행 칸·툴팁·대기열 배지(S378, S188·I13·S142 2026-11-17 변경). hud.gd 머리의 API에 더하는 것:
#   BattleView(battle·controls를 넣어 바로 만든다): zone_bands() -> [[지대 이름, 맵 px Rect2]] · blobs() -> [[자리, 반지름]] · hunter_marks() -> [[적, px]] ·
#     forecast_line(경로) -> 집결 띠 밖 칸들 · far_texts() -> [[글, px, 불투명도]]
#   Controls.zoning(Alt를 누르고 있는 동안) · Battle.far_hits · Battle.FAR_TEXT · Battle.surge_counts(라운드, 웨이브) · Battle.muster_total()
#   hud._wave_lines([라운드, 웨이브]) · hud._track·_fill·_g2(진행 칸 막대·둘째 줄) · hud.keep.owned[i](카드의 «×보유+대기» 글) · hud.minimap.marks()

const BView := preload("res://src/ui/battle_view.gd")
const HTheme := preload("res://src/ui/hud_theme.gd")
const W1 := [{"kind": "basic", "count": 1}]
const ON := {"harvest_rows": 2, "band_rows": 4, "bombard_gold": 0.5, "band_gold": 0.0, "crowd_slow": 0.5, "exposed_block_mode": false, "hunts_hero": 0}

# 준비 단계 판: 마을 0~4행, 출현 (15,19), 전장 띠 5~6행·포격 띠 7~15행·집결 띠 16~19행(terrain 스위트와 같다)
func _board(over := {}):
	var st := {"waves": [W1], "base_hp": BIG, "village": Rect2i(0, 0, 30, 5), "spawns": [Vector2i(15, 19)], "merc_cap": 40}
	st.merge(ON, true)
	st.merge(over, true)
	return battle(st)

func _view(b):
	var v = BView.new()
	v.battle = b
	v.controls = controls(b)
	return v

func _alt(c, down: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = KEY_ALT
	ev.physical_keycode = KEY_ALT
	ev.pressed = down
	c.handle(ev)

func _fight(b) -> void:
	b.start_battle()
	b.step(DT)
	kill_all(b)
	b.spawn_enemy("basic", Vector2i(29, 0), {"speed": 0, "sight": 0, "damage": 0, "hp": BIG})

# EV1200 · S378 ①: 지대 색 띠는 Alt를 누르고 있거나 깃발 칸을 고르는 동안만이다. 전장 5~6행·포격 7~15행·집결 16~19행 사각형과, 열린 성문 둘레 혼잡 칸
func ev1200():
	var b = _board()
	var v = _view(b)
	var c = v.controls
	var off: Array = v.zone_bands()
	_alt(c, true)
	var on: Array = v.zone_bands()
	_alt(c, false)
	var released: Array = v.zone_bands()
	c.flagging = true
	var flag: int = v.zone_bands().size()
	var rows := on.map(func(z): return [z[0], int(z[1].position.y / 16), int(z[1].end.y / 16)])
	var gates := [Vector2i(5, 9), Vector2i(15, 9), Vector2i(25, 9)]
	var walls := []
	for x in 30:
		if Vector2i(x, 9) not in gates:
			walls.append(Vector2i(x, 9))
	var w = battle({"base": Vector2i(15, 4), "spawns": [Vector2i(15, 19)], "village": Rect2i(0, 0, 30, 9), "base_hp": BIG, "waves": [W1],
		"castle": {"walls": walls, "gates": gates, "wall_hp": 300, "gate_hp": 150}, "crowd_pad": 2})
	w.set_gate(w.castle[Vector2i(15, 9)], true)
	w.step(DT)
	var vw = _view(w)
	_alt(vw.controls, true)
	var crowd: Array = vw.zone_bands().filter(func(z): return z[0] == "crowd").map(func(z): return Rect2i(z[1].position / 16, z[1].size / 16))
	v.free()
	vw.free()
	return check(off.is_empty() and rows == [["front", 5, 7], ["bombard", 7, 16], ["band", 16, 20]] and released.is_empty() and flag == 3 and crowd == [Rect2i(13, 7, 5, 5)],
		"Alt 전 %d · Alt 중 %s(전장 5~7·포격 7~16·집결 16~20) · Alt 뗀 뒤 %d · 깃발 고르기 중 %d(3) · 열린 성문 둘레 혼잡 칸 %s((13,7) 5×5)" % [off.size(), rows, released.size(), flag, crowd])

# EV1201 · S378 ②: 집결 띠에 잠든 적마다 덩어리 하나가 있고, 미니맵에도 어두운 점으로 찍힌다. 집결 중이 아니면 덩어리가 없다
func ev1201():
	var b = _board({"waves": [W1, [{"kind": "basic", "count": 10}]]})
	var v = _view(b)
	var before: int = v.blobs().size()
	b.start_battle()
	run(b, 3.0, func(): return b.dormant.size() == 10 and not b.enemies.is_empty())
	var blobs: Array = v.blobs()
	var in_band: bool = blobs.all(func(x): return b.in_band(x[0]))
	v.free()
	var main = _prep()
	var mb = main.view.battle
	main.hud.start.pressed.emit()
	run(mb, 2.0, func(): return mb.dormant.size() > 0)
	var dots: int = main.hud.minimap.marks().filter(func(m): return m[1] == main.hud.minimap.DORMANT).size()
	var dormant: int = mb.dormant.size()
	_done(main)
	return check(before == 0 and blobs.size() == 10 and in_band and dormant > 0 and dots == dormant,
		"집결 전 덩어리 %d(0) · 집결 중 %d(10) 모두 집결 띠 안 %s · 시험 스테이지 미니맵 잠든 점 %d = 잠든 적 %d" % [before, blobs.size(), in_band, dots, dormant])

# EV1202 · S378 ③: 보이는 영웅 사냥꾼마다 깃발 표식이 하나다. 사냥꾼이 아닌 적에는 없다
func ev1202():
	var b = _board()
	_fight(b)
	var v = _view(b)
	var e = b.spawn_enemy("basic", Vector2i(10, 12), {"speed": 0, "sight": 0, "damage": 0})
	var none: int = v.hunter_marks().size()
	e.hunter = true
	var marks: Array = v.hunter_marks()
	v.free()
	return check(none == 0 and marks.size() == 1 and is_same(marks[0][0], e), "사냥꾼 아님 %d(0) · 사냥꾼 표식 %d(1, 그 적 %s)" % [none, marks.size(), marks.size() == 1 and is_same(marks[0][0], e)])

# EV1203 · S142 2026-11-17 변경: 예상 경로 그림은 집결 띠(16~19행) 안의 칸을 빼고 띠 경계에서 시작한다. 판의 forecast 자체는 그대로 출현 칸에서 시작한다
func ev1203():
	var b = _board()
	b.step(DT)
	var path: Array = b.forecast[0]
	var v = _view(b)
	var line: Array = v.forecast_line(path)
	v.free()
	var band_in_path: int = path.filter(func(c): return c.y >= 16).size()
	return check(path[0] == Vector2i(15, 19) and band_in_path >= 4 and line.size() == path.size() - band_in_path and line.all(func(c): return c.y < 16) and line[0].y == 15,
		"경로 시작 %s((15,19)) · 집결 띠 칸 %d개 · 그리는 칸 %d개(= %d − %d) 첫 칸 %s(15행)" % [path[0], band_in_path, line.size(), path.size(), band_in_path, line[0] if not line.is_empty() else null])

# EV1204 · S188 2026-11-17 변경: 파도가 둘 이상인 웨이브의 툴팁에는 파도마다 «파도 j — 종류 수» 줄이 붙는다(3라운드 1웨이브: 파도 3, 공성 ram은 마지막 파도).
# 파도 하나인 웨이브(1라운드)에는 없다
func ev1204():
	var main = _prep()
	var b = main.view.battle
	var hud = main.hud
	var parts: Array = b.surge_counts(2, 0)
	var total: int = parts.reduce(func(n, d): return n + d.values().reduce(func(a, x): return a + x, 0), 0)
	var ram_last: bool = parts.size() == 3 and not parts[0].has("ram") and not parts[1].has("ram") and parts[2].get("ram", 0) == 6
	var lines: String = hud._wave_lines([2, 0])
	var one: String = hud._wave_lines([0, 0])
	_done(main)
	return check(total == 296 and ram_last and "파도 1 — " in lines and "파도 3 — " in lines and not "파도 4" in lines and not "파도 " in one,
		"3라운드 1웨이브 파도 %d개 합 %d(296) · ram 마지막 %s · 툴팁 «%s» · 1라운드 툴팁 «%s»" % [parts.size(), total, ram_last, lines.replace("\n", " / "), one.replace("\n", " / ")])

# EV1205 · I13 2026-11-17 변경: 집결 중 진행 칸의 막대는 금색이고 남은 집결 비율만큼 차 있으며, 둘째 줄은 «파도 j/k · 집결 m:ss»다. 5초 뒤 막대가 줄고 «0:25»다
func ev1205():
	var main = _prep()
	var b = main.view.battle
	var hud = main.hud
	hud.start.pressed.emit()
	b.step(DT)
	_frame(main)
	var first := [hud._track.visible, hud._fill.color == HTheme.ACCENT, hud._g2.text, hud._fill.size.x / maxf(hud._track.size.x, 1.0)]
	run(b, 5.0)
	_frame(main)
	var later := [hud._g2.text, hud._fill.size.x / maxf(hud._track.size.x, 1.0)]
	_done(main)
	return check(first[0] and first[1] and first[2].begins_with("파도 1/1 · 집결 0:30") and absf(first[3] - 1.0) < 0.02 and later[0].begins_with("파도 1/1 · 집결 0:25") and absf(later[1] - 25.0 / 30.0) < 0.03,
		"막대 보임 %s 금색 %s 글 «%s» 채움 %.2f(1.0) · 5초 뒤 «%s» 채움 %.2f(0.83)" % [first[0], first[1], first[2], first[3], later[0], later[1]])

# EV1206 · S378 ④: 거점 패널 카드의 «×보유+대기» 글: 전투 중 병사 둘을 대기열에 넣으면 «+2», 하나가 나오면 «×1+1»
func ev1206():
	var main = _prep()
	var b = main.view.battle
	var hud = main.hud
	hud.start.pressed.emit()
	b.step(DT)
	for i in 2:
		b.recruit(b.base, "soldier")
	main.view.controls.village = true
	_frame(main)
	var keep = hud.keep
	var i: int = keep.kinds.find("soldier")
	var first := [keep.visible, i >= 0 and keep.owned[i].visible, keep.owned[i].text if i >= 0 else ""]
	run(b, 7.0)
	_frame(main)
	var later: String = keep.owned[i].text if i >= 0 else ""
	var queued: int = b.base.queue.size()
	_done(main)
	return check(first == [true, true, "+2"] and later == "×1+1" and queued == 1, "패널 보임 %s 배지 보임 %s «%s»(+2) · 7초 뒤 «%s»(×1+1) 대기열 %d(1)" % [first[0], first[1], first[2], later, queued])

# EV1207 · S378 ⑤: 포격·집결 띠에서 적이 쓰러지면 그 자리에 «먼 곳 ×0.5»·«적의 땅 ×0» 글이 뜨고 전장 띠에서는 뜨지 않으며, FAR_TEXT초 뒤 사라진다
func ev1207():
	var b = _board()
	_fight(b)
	b.far_hits.clear()  # 첫 웨이브의 적은 집결 띠(출현 칸)에서 치웠다
	var v = _view(b)
	b.damage(b.spawn_enemy("basic", Vector2i(10, 6)), BIG)
	var front: int = b.far_hits.size()
	b.damage(b.spawn_enemy("basic", Vector2i(10, 10)), BIG)
	b.damage(b.spawn_enemy("basic", Vector2i(10, 18)), BIG)
	var texts: Array = v.far_texts().map(func(t): return t[0])
	run(b, b.FAR_TEXT + 0.1)
	var left: int = v.far_texts().size()
	v.free()
	return check(front == 0 and texts == ["먼 곳 ×0.5", "적의 땅 ×0"] and left == 0, "전장 띠 처치 글 %d(0) · 글 %s · %.1f초 뒤 %d(0)" % [front, texts, b.FAR_TEXT + 0.1, left])
