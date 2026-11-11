extends "res://tests/eval/gd/hud.gd"
# 보스방 원정 — 드나들기(S316·S317·I262). hud.gd 머리의 계약에 더하는 API:
#   Battle: signal raid_starting(횃불을 쓴 직후, 원정에 들어가기 전) · state "raid"(원정)
#     torches(횃불 자루) · floors_cleared(깬 층 수) · party(원정대 영웅, 출전 차례) · flame(불꽃이 탄 초) · grid.region(길 격자 범위)
#     raid_block() -> String: ""(누를 수 있음) | "state"(준비 단계 아님) | "round"(층이 열리는 라운드 전) | "done"(모든 층을 깸) | "torch"(횃불 없음) | "party"(나갈 영웅 없음)
#     start_raid() -> bool(못 하면 거짓, 판 그대로) · retreat()(«철수») · _bare(칸) — 땅 적이 설 수 있는 칸
#   main.view.den_torches() -> int — 켜진 벽 횃불 수
#   main.hud.raid — 거점 팝업의 «원정» 버튼 · main.hud.retreat — 진행 칸의 «철수» 버튼 · main.hud.boss_bar — 보스 이름·체력 막대(Control)
#   main.hud.fade — 검은 덮개(ColorRect, 화면 전체). 불투명도는 color.a × modulate.a이고 숨으면 0으로 본다 · main.hud.minimap · main.hud.grid
# 시험 스테이지(`main.gd` stage())를 쓴다. 영웅은 스테이지 heroes로 보유·출전한 채(최대 레벨) 2라운드 첫 준비 단계로 넘긴다

const ROOM := Rect2i(70, 72, 28, 16)
const ENTRY := [Vector2i(83, 87), Vector2i(85, 87), Vector2i(84, 87)]
const BOSS := Vector2i(84, 80)
const TEAM := [{"kind": "aias", "cell": Vector2i(31, 65)}, {"kind": "ignis", "cell": Vector2i(33, 65)}, {"kind": "seraphina", "cell": Vector2i(32, 65)}]

# 모서리마다 꼭짓점 칸에서 가로·세로 거리 합이 2 미만인 세 칸(I262 ①)
func _corners() -> Array:
	var out := []
	for k in [[70, 72, 1, 1], [97, 72, -1, 1], [70, 87, 1, -1], [97, 87, -1, -1]]:
		for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)]:
			out.append(Vector2i(k[0] + d.x * k[2], k[1] + d.y * k[3]))
	return out

# 2라운드 첫 준비 단계(횃불 2)의 시험 스테이지 판
func _den(team := TEAM):
	var st := _stage()
	st.heroes = team
	var b = _new(st)
	b.state = "cleared"
	b.next_round()
	return b

func _alive_heroes(b) -> Array:
	return b.heroes.filter(func(h): return h.alive)

# 원정 동안 secs초 돌린다(판 단계가 바뀌면 멈추지 않는다)
func _go(b, secs: float) -> void:
	var t := 0.0
	while t < secs - 0.0001:
		b.step(DT)
		t += DT

# EV887 · S317·I262 ①: 맵 크기는 그대로이고 길 격자만 띠까지 넓다. 방 안 436칸만 설 수 있고, 띠에는 짓거나 용병을 놓지 못한다. 웨이브 길은 띠 밖이다
func ev887():
	var M = load("res://src/main.gd")
	var b = _new(_stage())
	var size := Vector2i(64, 64 + M.FIELD_ROWS)
	if b.size != size or b.grid.region != Rect2i(0, 0, 104, size.y):
		return "맵 크기 %s(기대 %s) · 길 격자 %s(기대 %s)" % [b.size, size, b.grid.region, Rect2i(0, 0, 104, size.y)]
	var corners := _corners()
	var stand := 0
	for x in range(ROOM.position.x, ROOM.end.x):
		for y in range(ROOM.position.y, ROOM.end.y):
			var c := Vector2i(x, y)
			if b._bare(c):
				stand += 1
			elif c not in corners:
				return "방 칸 %s에 설 수 없다" % c
	var rock := corners + [Vector2i(64, 0), Vector2i(69, 80), Vector2i(98, 80), Vector2i(84, 71), Vector2i(84, 88), Vector2i(103, 129)]
	var walk: Array = rock.filter(func(c): return b._bare(c))
	if stand != 436 or not walk.is_empty():
		return "방에서 설 수 있는 칸 %d(기대 436) · 설 수 있는 바위 칸 %s(기대 없음)" % [stand, walk]
	var gold: int = b.gold
	var made := []
	for c in [Vector2i(84, 82), Vector2i(70, 40)]:
		for k in ["wall", "tower"]:
			if b.build(k, c) != null:
				made.append([k, c])
		if b.place_merc("soldier", c) != null:
			made.append(["soldier", c])
	if not made.is_empty() or b.gold != gold:
		return "띠에 지어지거나 놓였다 %s · 골드 %d → %d" % [made, gold, b.gold]
	if b.build("wall", Vector2i(40, 90)) == null or b.place_merc("soldier", Vector2i(40, 92)) == null:
		return "들판 (40,90)에 성벽·(40,92)에 병사가 놓이지 않는다(대조)"
	var off := []
	for way in b.forecast:
		for c in way:
			if c.x >= 64:
				off.append(c)
	if b.forecast.is_empty() or not off.is_empty():
		return "예상 길 %d개 · x 64 이상 칸 %s" % [b.forecast.size(), off.slice(0, 5)]
	var main = _game()
	var cam: Camera2D = main.get_viewport().get_camera_2d()
	var px: Vector2 = cam.map_px
	_done(main)
	return check(px == Vector2(size * 16), "게임 장면 카메라 map_px %s(기대 %s)" % [px, Vector2(size * 16)])

# EV888 · S316·I262 ②③: 횃불은 0에서 다음 라운드마다 2씩 4까지. 원정 버튼의 못 누르는 이유 차례
func ev888():
	var st := _stage()
	st.heroes = TEAM
	var b = _new(st)
	var first := [b.torches, b.raid_block()]
	b.torches = 1
	var given: String = b.raid_block()
	b.torches = 0
	var got := []
	for i in 5:
		b.state = "cleared"
		b.next_round()
		got.append(b.torches)
		if i == 0:
			got.append(b.raid_block())
	if first != [0, "round"] or given != "round" or got != [2, "", 4, 4, 4, 4]:
		return "1라운드 %s(기대 [0, round]) · 횃불 1 %s(기대 round) · 라운드마다 %s(기대 [2, \"\", 4, 4, 4, 4])" % [first, given, got]
	b = _den()
	var whys := []
	for h in b.heroes:
		b.damage(h, BIG)
	whys.append(b.raid_block())
	for h in b.heroes:
		b._return_hero(h, true)
	b.torches = 0
	whys.append(b.raid_block())
	b.torches = 2
	b.floors_cleared = 1
	whys.append(b.raid_block())
	b.floors_cleared = 2
	whys.append(b.raid_block())
	b.floors_cleared = 3
	whys.append(b.raid_block())
	b.floors_cleared = 0
	b.start_battle()
	var battle_why: String = b.raid_block()
	var started: bool = b.start_raid()
	if whys != ["party", "torch", "round", "round", "done"] or battle_why != "state" or started or b.state != "battle" or b.torches != 2:
		return "전멸·횃불 0·1층 깸·2층 깸·3층 깸 %s(기대 party·torch·round·round·done) · 전투 단계 %s(기대 state) · 시작 %s · 판 %s · 횃불 %d(기대 battle, 2)" % [whys, battle_why, started, b.state, b.torches]
	return ""

# EV889 · S316·I262 ④⑤: 들어가기. 저장 신호 때는 준비 단계·횃불 1이고, 산 영웅만 입구에 선다. 보스는 층 수치이고 라운드 배율을 받지 않는다. 원정 중 집은 멈추고 집 명령은 판을 바꾸지 않는다
func ev889():
	var b = _den()
	b.round_index = 3  # 라운드 체력 배율이 1이 아닌 4라운드
	var mult: float = b._hp_mult()
	b.damage(b.heroes[2], BIG)
	b.order_move([b.heroes[0]], Vector2i(32, 75))
	var guard = b.place_merc("soldier", Vector2i(32, 90))
	var seen := []
	b.raid_starting.connect(func(): seen.append([b.state, b.torches]))
	if not b.start_raid():
		return "원정을 시작하지 못했다(이유 %s)" % b.raid_block()
	if mult == 1.0 or guard == null:
		return "4라운드 배율 %s(1이 아니어야) · 병사 %s" % [mult, guard]
	if seen != [["prep", 1]] or b.state != "raid":
		return "저장 신호 %s(기대 [[prep, 1]]) · 판 %s(기대 raid)" % [seen, b.state]
	var party: Array = b.party
	var at := party.map(func(h): return Vector2i(h.pos.round()))
	var idle := party.all(func(h): return h.path.is_empty() and h.order == null and h.prey == null)
	if party != [b.heroes[0], b.heroes[1]] or at != [ENTRY[0], ENTRY[1]] or not idle:
		return "원정대 %s · 자리 %s(기대 %s) · 명령 비었나 %s" % [party.map(func(h): return h.kind), at, ENTRY.slice(0, 2), idle]
	if b.enemies.size() != 1:
		return "적 %d(기대 보스 하나)" % b.enemies.size()
	var e = b.enemies[0]
	if e.kind != "slime_king" or Vector2i(e.pos.round()) != BOSS or e.hp != 400.0 or e.max_hp != 400.0 or e.reward != 0 or e.xp != 0 or b.dark != 0.0:
		return "보스 %s %s 체력 %s/%s 골드 %d 경험치 %d · 어둠 %s(기대 slime_king %s 400/400 0 0 · 0)" % [e.kind, e.pos, e.hp, e.max_hp, e.reward, e.xp, b.dark, BOSS]
	var gold: int = b.gold
	var n: int = b.units.size()
	var s: int = b.structures.size()
	b.start_battle()
	var built = b.build("wall", Vector2i(40, 90))
	var put = b.place_merc("soldier", Vector2i(40, 92))
	var hired = b.hire(0)
	if b.state != "raid" or built != null or put != null or hired != null or b.gold != gold or b.units.size() != n or b.structures.size() != s:
		return "원정 중 전투 시작·짓기·용병·영입 뒤 판 %s · 짓기 %s · 용병 %s · 영입 %s · 골드 %d→%d · 유닛 %d→%d · 구조물 %d→%d" % [b.state, built, put, hired, gold, b.gold, n, b.units.size(), s, b.structures.size()]
	var from: Vector2 = guard.pos
	b.order_move([guard], Vector2i(32, 100))
	_go(b, 3.0)
	return check(guard.pos == from, "들판 병사가 원정 중에 %s → %s로 움직였다" % [from, guard.pos])

# EV890 · S316·I262 ④⑤: 보스는 3초 서 있다가 원정대에 다가가고, 들판 병사가 있어도 원정대를 노린다. 원정 중 스킬·대시가 돌고, 대시는 바위 앞에서 멈춘다
func ev890():
	var b = _den()
	var guard = b.place_merc("soldier", Vector2i(63, 82))
	b.start_raid()
	var e = b.enemies[0] if not b.enemies.is_empty() else null
	if b.state != "raid" or e == null:
		return "원정이 되지 않았다(판 %s)" % b.state
	for h in b.party:  # 보스가 먼저 다가오게 원정대를 멈춰 둔다
		h.speed = 0.0
		h.sight = 0.0
	var from: Vector2 = e.pos
	_go(b, 2.9)
	var still: bool = e.pos == from
	var near := func(): return b.party.map(func(h): return e.pos.distance_to(h.pos)).min()
	var d0: float = near.call()
	_go(b, 3.0)
	var d1: float = near.call()
	var aim = b._target_of(e)
	if not still or d1 >= d0 or aim not in b.party or guard == null:
		return "2.9초에 보스 %s → %s(그대로여야) · 원정대까지 %.2f → %.2f(줄어야) · 대상 %s(원정대여야) · 병사 %s" % [from, e.pos, d0, d1, aim, guard]
	var h = b.party[0]
	var ok: bool = b.can_cast(h, "q")
	b.cast(h, "q", e.pos)
	var cd0: float = h.cd.q
	_go(b, 1.0)
	if not ok or cd0 <= 0.0 or h.cd.q > cd0 - 0.9:
		return "원정 중 Q 쓸 수 있나 %s · 대기 %.2f → 1초 뒤 %.2f(0.9 넘게 줄어야)" % [ok, cd0, h.cd.q]
	var g = b.party[1]
	g.pos = Vector2(96, 82)
	b.dash([g], Vector2(100, 82))
	return check(g.dash_cd > 0.0 and g.pos.x > 96.0 and g.pos.x < 97.5, "바위 쪽 대시 뒤 x %.2f(96보다 크고 97.5 미만) · 대기 %.2f" % [g.pos.x, g.dash_cd])

# EV891 · S316·I262 ⑥⑦: 처치로 끝나면 3초 뒤 원정 직전 몸으로 돌아오고, 깬 층이 1 는다. 골드는 층 골드(S333) 120만 늘고 웨이브·집계는 그대로다
func ev891():
	var b = _den()
	var a = b.heroes[0]
	var c = b.heroes[1]
	a.hp = 40.0
	a.pos = Vector2(30, 70)
	c.cd.q = 3.0
	var gold: int = b.gold
	var wave: int = b.wave_index
	var torches: int = b.torches
	var tally: Dictionary = b.tally.duplicate()
	b.start_raid()
	if b.state != "raid":
		return "원정이 되지 않았다(판 %s)" % b.state
	b.damage(a, BIG)
	_slay(b)
	_go(b, 2.9)
	var mid: String = b.state
	_go(b, 0.2)
	if mid != "raid" or b.state != "prep":
		return "처치 뒤 2.9초 %s(기대 raid) · 3.1초 %s(기대 prep)" % [mid, b.state]
	var count: Array = b.heroes.map(func(h): return b.units.count(h))
	if b.floors_cleared != 1 or b.torches != torches - 1 or b.gold != gold + 120 or b.wave_index != wave or b.tally != tally:
		return "깬 층 %d(1) · 횃불 %d(%d) · 골드 %d(%d) · 웨이브 %d(%d) · 집계 %s(기대 %s)" % [b.floors_cleared, b.torches, torches - 1, b.gold, gold + 120, b.wave_index, wave, b.tally, tally]
	if not a.alive or a.hp != 40.0 or a.pos != Vector2(30, 70) or c.cd.q != 3.0 or count != [1, 1, 1]:
		return "아이아스 살았나 %s 체력 %s 자리 %s(기대 40, (30,70)) · 이그니스 Q 대기 %s(3) · units 안 횟수 %s(기대 1·1·1)" % [a.alive, a.hp, a.pos, c.cd.q, count]
	return check(b.enemies.is_empty() and b.zones.is_empty() and b.missiles.is_empty() and b.loops.is_empty() and b.raid_block() == "round",
		"돌아온 뒤 적 %d · 장판 %d · 투사체 %d · 루프 %d · 이유 %s(기대 모두 0, round)" % [b.enemies.size(), b.zones.size(), b.missiles.size(), b.loops.size(), b.raid_block()])

# EV892 · S316·I262 ⑥: 전멸·불꽃·철수로 끝난다. 전멸·불꽃 뒤에는 «다시»를 기다리다(S331) 철수로, 철수는 바로 돌아오고, 쓴 횃불은 돌아오지 않는다
func ev892():
	var b = _den()
	b.torches = 4
	var hp: Array = b.heroes.map(func(h): return h.hp)
	b.start_raid()
	for h in b.party:
		b.damage(h, BIG)
	_go(b, 2.4)
	var mid: String = b.state
	_go(b, 0.2)
	var late: String = b.state
	b.retreat()
	if mid != "raid" or late != "raid" or b.state != "prep" or not b.heroes.all(func(h): return h.alive) or b.heroes.map(func(h): return h.hp) != hp or b.floors_cleared != 0:
		return "전멸 뒤 2.4초 %s(raid) · 2.6초 %s(raid) · 철수 뒤 %s(prep) · 체력 %s(기대 %s, 모두 살아) · 깬 층 %d(0)" % [mid, late, b.state, b.heroes.map(func(h): return h.hp), hp, b.floors_cleared]
	b.start_raid()
	b.flame = 119.9
	_go(b, 0.2)
	var gone: bool = b.enemies.is_empty()
	_go(b, 2.6)
	var left: String = b.state
	b.retreat()
	if not gone or left != "raid" or b.state != "prep":
		return "불꽃 120초 뒤 보스 사라짐 %s · 2.8초 %s(raid) · 철수 뒤 %s(prep)" % [gone, left, b.state]
	b.start_raid()
	b.retreat()
	return check(b.state == "prep" and b.torches == 1 and b.floors_cleared == 0, "철수 뒤 %s(prep) · 횃불 %d(1) · 깬 층 %d(0)" % [b.state, b.torches, b.floors_cleared])

# 2라운드 첫 준비 단계(횃불 2)의 게임 장면. 영웅 둘을 영입했다
func _den_game():
	var main = _prep()
	var b = main.view.battle
	b.state = "cleared"
	b.next_round()
	_frame(main)
	_layout(main)
	return main

# EV893 · S316·I262 ③④: 원정 시작 때 준비 단계·횃불 1로 저장하고, 원정 중에는 저장하지 않으며, 돌아오면 다시 저장한다. 횃불·깬 층은 불러오면 그대로이고 옛 저장은 0이다
func ev893():
	var main = _den_game()
	var b = main.view.battle
	var s = _save()
	b.start_raid()
	_frame(main)
	var at_start: Dictionary = s.read()
	var text := FileAccess.get_file_as_string(PATH)
	for i in 20:
		main._process(0.05)
	var during := FileAccess.get_file_as_string(PATH)
	b.floors_cleared = 1
	b.retreat()
	_frame(main)
	var back: Dictionary = s.read()
	_done(main)
	if at_start.get("state") != "prep" or at_start.get("torches") != 1 or during != text or back.get("state") != "prep":
		return "원정 시작 저장 판 %s 횃불 %s(prep, 1) · 원정 중 파일 바뀜 %s · 철수 뒤 저장 판 %s(prep)" % [at_start.get("state"), at_start.get("torches"), during != text, back.get("state")]
	var loaded = _loaded()
	var old: Dictionary = back.duplicate()
	old.erase("torches")
	old.erase("floors_cleared")
	var fresh = _new(load("res://src/main.gd").stage())
	s.apply(fresh, old)
	return check(loaded.torches == 1 and loaded.floors_cleared == 1 and fresh.torches == 0 and fresh.floors_cleared == 0,
		"불러온 횃불 %d·깬 층 %d(1·1) · 옛 저장 %d·%d(0·0)" % [loaded.torches, loaded.floors_cleared, fresh.torches, fresh.floors_cleared])

# 카메라 아래 맵 px의 화면 자리
func _screen(main, p: Vector2) -> Vector2:
	return main.get_viewport().get_camera_2d().steady() * p

# EV894 · S317·I262 ②⑧: 거점 팝업의 원정 버튼, 원정 중 고정 카메라·숨는 패널·철수 버튼·보스 막대, 돌아오면 카메라·미니맵이 돌아온다
func ev894():
	var main = _prep()
	var b = main.view.battle
	var hud = main.hud
	if not hud.get("raid") is BaseButton or not hud.get("retreat") is BaseButton or not hud.get("boss_bar") is Control:
		_done(main)
		return "main.hud.raid·retreat·boss_bar가 없다"
	main.controls.village = true
	_frame(main)
	var first := [hud.raid.is_visible_in_tree(), hud.raid.disabled, _tip_of(main, hud.raid)]
	b.state = "cleared"
	b.next_round()
	_frame(main)
	var cam: Camera2D = main.get_viewport().get_camera_2d()
	cam.position = Vector2(500, 900)  # 기본 2배 줌
	cam.pan(Vector2.ZERO, 0.0)
	var pos0: Vector2 = cam.position
	main.controls.village = true
	_frame(main)
	_layout(main)
	var second := [hud.raid.is_visible_in_tree(), hud.raid.disabled, hud.raid.text]
	if first[0] != true or first[1] != true or not "2라운드부터" in first[2] or second != [true, false, "원정 1층"]:
		_done(main)
		return "1라운드 버튼 보임·꺼짐·툴팁 %s(기대 참·참·«2라운드부터») · 2라운드 %s(기대 [참, 거짓, 원정 1층])" % [first, second]
	hud.raid.pressed.emit()
	_frame(main)
	var room := Vector2(ROOM.position + ROOM.size / 2) * 16.0  # 보스방 가운데(맵 px) = (1344, 1280)
	var z: float = cam.zoom.x
	var spot := _screen(main, room)
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_WHEEL_UP
	e.position = Vector2(320, 180)
	e.pressed = true
	cam._unhandled_input(e)
	cam.glide(0.5)
	cam.pan(Vector2.RIGHT, 0.5)
	cam._drive(Vector2.DOWN, 0.5)
	var m := InputEventMouseMotion.new()
	m.relative = Vector2(-40, 30)
	m.button_mask = MOUSE_BUTTON_MASK_MIDDLE
	cam._unhandled_input(m)
	cam.glide(0.5)
	var spot2 := _screen(main, room)
	var shown := [hud.minimap.visible, hud.grid.visible, hud.retreat.is_visible_in_tree(), hud.boss_bar.is_visible_in_tree()]
	if b.state != "raid" or z != 1.0 or cam.zoom.x != 1.0 or not spot.is_equal_approx(Vector2(320, 194)) or not spot2.is_equal_approx(Vector2(320, 194)) or shown != [false, false, true, true]:
		_done(main)
		return "원정 판 %s · 줌 %s → 조작 뒤 %s(1) · 방 가운데 화면 %s → %s(기대 (320,194)) · 미니맵·격자·철수·보스 막대 %s(기대 [거짓, 거짓, 참, 참])" % [b.state, z, cam.zoom.x, spot, spot2, shown]
	hud.retreat.pressed.emit()
	_frame(main)
	var after := [b.state, cam.zoom.x, cam.position, hud.minimap.visible]
	_done(main)
	return check(after == ["prep", 2.0, pos0, true], "철수 뒤 판·줌·카메라 자리·미니맵 %s(기대 [prep, 2, %s, 참])" % [after, pos0])

# 덮개 불투명도: 숨으면 0
func _shade(hud) -> float:
	return hud.fade.color.a * hud.fade.modulate.a if hud.fade.visible else 0.0

# EV895 · S317·I262 ⑧⑨: 켜진 벽 횃불은 불꽃의 1/4마다 하나씩 준다. 검은 덮개는 들어갈 때·돌아올 때 불투명에서 0.4초 동안 걷힌다
func ev895():
	var main = _den_game()
	var b = main.view.battle
	var hud = main.hud
	if not main.view.has_method("den_torches") or not hud.get("fade") is ColorRect:
		_done(main)
		return "main.view.den_torches나 main.hud.fade가 없다"
	var lit := [main.view.den_torches()]
	b.start_raid()
	main._process(0.0)
	hud._process(0.0)
	var shades := [_shade(hud)]
	hud._process(0.2)
	shades.append(_shade(hud))
	hud._process(0.21)
	shades.append(_shade(hud))
	lit.append(main.view.den_torches())
	for t in [29.9, 30.1, 60.1, 90.1, 119.9]:
		b.flame = t
		lit.append(main.view.den_torches())
	b.retreat()
	main._process(0.0)
	hud._process(0.0)
	var back := [_shade(hud)]
	hud._process(0.41)
	back.append(_shade(hud))
	_done(main)
	if lit != [4, 4, 4, 3, 2, 1, 1]:
		return "켜진 횃불 %s(기대 원정 밖 4 · 시작 4 · 29.9초 4 · 30.1초 3 · 60.1초 2 · 90.1초 1 · 119.9초 1)" % [lit]
	return check(shades[0] >= 0.9 and shades[1] > 0.3 and shades[1] < 0.7 and shades[2] == 0.0 and back[0] >= 0.9 and back[1] == 0.0,
		"들어갈 때 덮개 %s(기대 0.9 이상 → 0.2초 0.3~0.7 → 0.41초 0) · 돌아올 때 %s(기대 0.9 이상 → 0)" % [shades, back])

# ── 1층 뜀·분열(S322·I266) ── 더하는 API:
#   FloorDef.gens: 세대마다 {hp, radius, land(착지 원 반경), gap(뜀 간격)} · Enemy.gen(세대, 원정 몸이 아니면 -1)
#   원정 몸의 skills.leap은 몸마다 따로인 사전이다: radius(착지 원 반경)·cd(뜀 간격)·damage·range·step·reach·retry·born
#   main.hud._boss_fill — 보스 막대 채움(폭 136이 가득) · main.view._shrunk(몸) — 몸 그림 배율

const GEN_HP := [400.0, 200.0, 100.0, 50.0]
const GEN_BODY := [1.6, 1.2, 0.9, 0.7]
const GEN_LAND := [2.5, 2.0, 1.6, 1.3]

# 원정대를 멈춘다: 걷지도, 적을 찾지도, 치지도, 오토로 스킬을 쓰지도 않는다
func _freeze(b) -> void:
	for h in b.party:
		h.speed = 0.0
		h.sight = 0.0
		h.cooldown = 1.0e9
		for k in h.auto:
			h.auto[k] = false

# 원정을 시작해 원정대를 멈춘다. 왕(세대 칸이 있는 하나뿐인 적)을 돌려주고, 아니면 null
func _king(b):
	b.start_raid()
	if b.state != "raid" or b.enemies.size() != 1 or b.enemies[0].get("gen") == null:
		return null
	_freeze(b)
	return b.enemies[0]

# 방 안의 몸을 나오는 대로 모두 처치하고 처치한 수를 돌려준다
func _slay(b) -> int:
	var n := 0
	while not b.enemies.is_empty() and n < 40:
		b.damage(b.enemies[0], BIG)
		n += 1
	return n

# 세대 g 몸의 수치가 표와 같나
func _is_gen(e, g: int) -> bool:
	return e.kind == "slime_king" and e.gen == g and e.hp == GEN_HP[g] and e.max_hp == GEN_HP[g] and e.radius == GEN_BODY[g] \
		and e.skills.leap.radius == GEN_LAND[g] and e.skills.leap.damage == 35.0 and e.reward == 0 and e.xp == 0

# 남은 총 체력: 산 몸마다 체력 + 아직 나오지 않은 자손의 체력
func _left(b) -> float:
	var sum := 0.0
	for e in b.enemies:
		sum += e.hp
		for k in range(e.gen + 1, GEN_HP.size()):
			sum += GEN_HP[k] * pow(2.0, k - e.gen)
	return sum

# EV921 · S322: 1층 층 정의의 세대 표와 뜀 수치. 디펜스 슬라임 킹 종류는 그대로다
func ev921():
	var f = load("res://data/dungeon/floor_1.tres")
	var gens = f.get("gens")
	if not gens is Array or gens.size() != 4:
		return "floor_1의 gens %s(기대 4행)" % [gens]
	for g in 4:
		var row: Dictionary = gens[g]
		if row.get("hp") != GEN_HP[g] or row.get("radius") != GEN_BODY[g] or row.get("land") != GEN_LAND[g] or row.get("gap") != [6.0, 12.0, 12.0, 12.0][g]:
			return "세대 %d %s(기대 체력 %s · 몸 %s · 착지 원 %s · 간격 %s)" % [g, row, GEN_HP[g], GEN_BODY[g], GEN_LAND[g], [6.0, 12.0, 12.0, 12.0][g]]
	var leap: Dictionary = f.skills.get("leap", {})
	var want := {"damage": 35.0, "knock": 1.0, "slow": 0.3, "slow_time": 3.0, "windup": 1.5, "air": 0.6, "range": 5.0, "retry": 0.5, "born": 1.5}
	for k in want:
		if leap.get(k) != want[k]:
			return "leap.%s %s(기대 %s)" % [k, leap.get(k), want[k]]
	if f.skills.has("shrink"):
		return "floor_1 skills에 shrink가 있다"
	var king = load("res://data/enemies/slime_king.tres")
	return check(king.speed == 1.0 and king.skills.has("shrink") and king.skills.leap.count == 3 and king.skills.leap.radius == 2.0,
		"디펜스 slime_king 속도 %s(1) · shrink %s · 점프 몰린 수 %s(3) · 반경 %s(2)" % [king.speed, king.skills.has("shrink"), king.skills.leap.get("count"), king.skills.leap.get("radius")])

# EV922 · S322: 왕은 걷지도 기본 공격도 하지 않고, 3초 선 뒤 가장 가까운 영웅 자리로 뛰어 원 안에만 피해를 준다. 뜀 거리 밖 영웅에게는 그쪽으로 5칸만 뛴다
func ev922():
	var b = _den()
	var e = _king(b)
	if e == null:
		return "원정 몸에 gen이 없거나 원정이 되지 않았다(판 %s · 적 %d)" % [b.state, b.enemies.size()]
	var a = b.party[0]
	a.pos = Vector2(84, 81.5)
	e.rest = 999.0  # 대본(S326)의 강타가 끼지 않게 쉼을 아주 길게 둔다
	if e.hp != 400.0 or e.radius != 1.6:
		return "왕 체력 %s(400) · 몸 반지름 %s(1.6)" % [e.hp, e.radius]
	var from: Vector2 = e.pos
	var hp0: float = a.hp
	var others: Array = [b.party[1].hp, b.party[2].hp]
	_go(b, 2.9)
	if e.pos != from or e.cast != null or a.hp != hp0:
		return "2.9초에 왕 %s → %s(그대로여야) · 예고 %s(없어야) · 닿은 영웅 체력 %s → %s(그대로여야)" % [from, e.pos, e.cast, hp0, a.hp]
	_go(b, 0.3)
	var spot: Vector2 = a.pos
	if e.cast == null or e.cast.id != "leap" or not e.cast.at.is_equal_approx(spot):
		return "3.2초에 예고 %s(기대 leap, 착지 %s)" % [e.cast, spot]
	_go(b, 2.2)
	if not e.pos.is_equal_approx(spot) or e.cast != null or a.hp >= hp0 or [b.party[1].hp, b.party[2].hp] != others:
		return "착지 뒤 왕 %s(기대 %s) · 예고 %s(없어야) · 첫째 체력 %s → %s(줄어야) · 입구 둘 %s → %s(그대로여야)" % [e.pos, spot, e.cast, hp0, a.hp, others, [b.party[1].hp, b.party[2].hp]]
	var at: Vector2 = e.pos
	var hp1: float = a.hp
	_go(b, 5.0)
	if e.pos != at or e.cast != null or a.hp < hp1:
		return "착지 뒤 5초에 왕 %s → %s(그대로여야) · 예고 %s(없어야) · 첫째 체력 %s → %s(줄지 않아야)" % [at, e.pos, e.cast, hp1, a.hp]
	_go(b, 0.5)
	if e.cast == null:
		return "뜬 뒤 뜀 간격 6초가 지났는데 다시 예고하지 않았다"
	var b2 = _den()
	var e2 = _king(b2)
	if e2 == null:
		return "둘째 판 원정이 되지 않았다"
	b2.damage(b2.party[1], BIG)
	b2.damage(b2.party[2], BIG)
	_go(b2, 3.2)
	var far: Vector2 = Vector2(BOSS) + (b2.party[0].pos - Vector2(BOSS)).normalized() * 5.0
	return check(e2.cast != null and e2.cast.at.distance_to(far) < 0.01, "뜀 거리 밖 영웅 %s에게 예고 %s(기대 착지 %s)" % [b2.party[0].pos, e2.cast, far])

# 왕을 처치해 얻은 1세대 둘. 쉼을 없앤다
func _pair(b) -> Array:
	var e = _king(b)
	if e == null:
		return []
	b.damage(e, BIG)
	for k in b.enemies:
		k.pull = 0.0
	return b.enemies.duplicate()

# EV923 · I266 ①: 착지 원은 서로 겹치지 않고 선 몸 위에 내리지 않는다. 자리가 없으면 뛰지 않고 0.5초 뒤 다시 고른다
func ev923():
	var b = _den()
	var kids := _pair(b)
	if kids.size() != 2:
		return "왕을 처치했는데 몸이 %d(기대 2)" % kids.size()
	var hero := Vector2(84, 82)
	b.party[0].pos = hero
	kids[0].pos = Vector2(80, 82)
	kids[1].pos = Vector2(88, 82)
	kids[0].cd["leap"] = 0.0
	kids[1].cd["leap"] = 0.0
	b.step(DT)
	if kids[0].cast == null or kids[1].cast == null:
		return "① 한 스텝 뒤 예고 %s · %s(둘 다 있어야)" % [kids[0].cast, kids[1].cast]
	var p: Vector2 = kids[0].cast.at
	var q: Vector2 = kids[1].cast.at
	if not p.is_equal_approx(hero) or p.distance_to(q) < 4.0 - 0.001 or not b.in_room(Vector2i(q.round())) or kids[1].pos.distance_to(q) > 5.0 + 0.001:
		return "① 앞 몸 착지 %s(기대 %s) · 뒤 몸 착지 %s(앞 착지에서 %.2f칸, 4 이상 · 방 안 %s · 몸에서 %.2f칸, 5 이하)" % [p, hero, q, p.distance_to(q), b.in_room(Vector2i(q.round())), kids[1].pos.distance_to(q)]
	var out := []
	for reach in [4.0, 0.0]:
		var c = _den()
		var two := _pair(c)
		if two.size() != 2:
			return "②③ 왕을 처치했는데 몸이 %d(기대 2)" % two.size()
		c.party[0].pos = hero
		two[0].pos = Vector2(83, 82)
		two[0].cd["leap"] = 99.0
		two[1].pos = Vector2(88, 82)
		two[1].cd["leap"] = 0.0
		two[1].skills.leap.reach = reach
		c.step(DT)
		if reach > 0.0:
			if two[0].cast != null or two[1].cast == null or two[1].cast.at.distance_to(two[0].pos) < 2.4 - 0.001:
				return "② 선 몸 예고 %s(없어야) · 뛰는 몸 예고 %s(선 몸 %s에서 2.4칸 이상이어야)" % [two[0].cast, two[1].cast, two[0].pos]
		else:
			out.append(two[1].cast == null)
			_go(c, 0.4)
			out.append(two[1].cast == null)
			two[1].skills.leap.reach = 4.0
			_go(c, 0.2)
			out.append(two[1].cast != null)
	return check(out == [true, true, true], "③ 고리 범위 0: 한 스텝 뒤 예고 없음·0.4초 뒤 없음·되돌리고 0.2초 뒤 있음 %s(기대 모두 참)" % [out])

# EV924 · S322·I266 ②③: 죽으면 한 세대 작은 몸 둘로 갈라진다. 좌우 자리·가득 찬 체력·효과 없음·보상 없음·1.5초 쉼·엇갈린 박자, 방 밖에 놓이지 않고 넷째 세대는 갈라지지 않는다
func ev924():
	var b = _den()
	var e = _king(b)
	if e == null:
		return "원정 몸에 gen이 없거나 원정이 되지 않았다(판 %s · 적 %d)" % [b.state, b.enemies.size()]
	e.fx["test"] = {"slow": 0.5, "left": 9.0}
	var seen := []
	b.enemy_spawned.connect(func(_x): seen.append(1))
	var gold: int = b.gold
	var xp: Array = b.heroes.map(func(h): return h.xp)
	b.damage(e, BIG)
	if b.enemies.size() != 2:
		return "왕 처치 뒤 적 %d(기대 2)" % b.enemies.size()
	var k0 = b.enemies[0]
	var k1 = b.enemies[1]
	if not _is_gen(k0, 1) or not _is_gen(k1, 1) or not k0.fx.is_empty() or not k1.fx.is_empty():
		return "1세대 둘 %s/%s 몸 %s 착지 원 %s · %s/%s 몸 %s 착지 원 %s(기대 200/200 · 1.2 · 2.0) · 효과 %s %s(없어야)" % [k0.hp, k0.max_hp, k0.radius, k0.skills.leap.radius, k1.hp, k1.max_hp, k1.radius, k1.skills.leap.radius, k0.fx, k1.fx]
	if not k0.pos.is_equal_approx(Vector2(82.8, 80)) or not k1.pos.is_equal_approx(Vector2(85.2, 80)):
		return "1세대 자리 %s · %s(기대 (82.8,80) · (85.2,80))" % [k0.pos, k1.pos]
	if not seen.is_empty() or b.gold != gold or b.heroes.map(func(h): return h.xp) != xp or b.state != "raid":
		return "출현 신호 %d(0) · 골드 %d → %d · 경험치 %s → %s · 판 %s(raid)" % [seen.size(), gold, b.gold, xp, b.heroes.map(func(h): return h.xp), b.state]
	var at := [k0.pos, k1.pos]
	_go(b, 1.4)
	if [k0.pos, k1.pos] != at or k0.cast != null or k1.cast != null:
		return "1.4초에 자리 %s → %s(그대로여야) · 예고 %s %s(없어야)" % [at, [k0.pos, k1.pos], k0.cast, k1.cast]
	_go(b, 0.3)
	if k0.cast == null or k1.cast != null:
		return "1.7초에 첫째 예고 %s(있어야) · 둘째 예고 %s(없어야)" % [k0.cast, k1.cast]
	_go(b, 5.7)
	var late: bool = k1.cast == null and not b._aloft(k1) and k1.pos == at[1]
	_go(b, 0.4)
	if not late or k1.cast == null:
		return "둘째: 7.4초까지 안 뜀 %s(참) · 7.8초 예고 %s(있어야)" % [late, k1.cast]
	k1.pos = Vector2(70, 81)
	b.damage(k1, BIG)
	var g2: Array = b.enemies.filter(func(x): return x.gen == 2)
	var inside: bool = b.enemies.all(func(x): return b.in_room(Vector2i(x.pos.round())))
	if g2.size() != 2 or not g2.all(func(x): return _is_gen(x, 2)) or not inside:
		return "방 서쪽 끝 (70,81)에서 처치 뒤 2세대 %d(2) %s · 모두 방 안 %s" % [g2.size(), g2.map(func(x): return [x.hp, x.radius, x.pos]), inside]
	b.damage(g2[0], BIG)
	var g3: Array = b.enemies.filter(func(x): return x.gen == 3)
	if g3.size() != 2 or not g3.all(func(x): return _is_gen(x, 3)):
		return "2세대 처치 뒤 3세대 %d(2) %s" % [g3.size(), g3.map(func(x): return [x.hp, x.radius])]
	var n: int = b.enemies.size()
	b.damage(g3[0], BIG)
	return check(b.enemies.size() == n - 1, "3세대 처치 뒤 적 %d → %d(1 줄어야)" % [n, b.enemies.size()])

# EV925 · S322·I266 ④: 몸이 남으면 끝나지 않고, 모두 처치하면 처치로 끝난다. 불꽃이 다 타면 모든 몸이 사라지고, 전멸 뒤에는 어느 몸도 움직이지 않는다
func ev925():
	var b = _den()
	var e = _king(b)
	if e == null:
		return "원정 몸에 gen이 없거나 원정이 되지 않았다(판 %s · 적 %d)" % [b.state, b.enemies.size()]
	b.damage(e, BIG)
	_go(b, 4.0)
	if b.state != "raid" or b.floors_cleared != 0:
		return "① 왕 처치 4.0초 뒤 판 %s(raid) · 깬 층 %d(0)" % [b.state, b.floors_cleared]
	var slain: int = 1 + _slay(b)
	_go(b, 2.9)
	var mid: String = b.state
	_go(b, 0.2)
	if slain != 15 or mid != "raid" or b.state != "prep" or b.floors_cleared != 1:
		return "① 처치한 몸 %d(15) · 2.9초 %s(raid) · 3.1초 %s(prep) · 깬 층 %d(1)" % [slain, mid, b.state, b.floors_cleared]
	var c = _den()
	if _pair(c).size() != 2:
		return "② 왕을 처치했는데 몸이 둘이 아니다"
	c.flame = 119.9
	_go(c, 0.2)
	if not c.enemies.is_empty():
		return "② 불꽃 120초 뒤 적 %d(0)" % c.enemies.size()
	var d = _den()
	var kids := _pair(d)
	if kids.size() != 2:
		return "③ 왕을 처치했는데 몸이 둘이 아니다"
	for k in kids:
		k.cd["leap"] = 0.0
	for h in d.party:
		d.damage(h, BIG)
	var at: Array = kids.map(func(k): return k.pos)
	_go(d, 2.0)
	return check(kids.map(func(k): return k.pos) == at and kids.all(func(k): return k.cast == null) and d.state == "raid",
		"③ 전멸 뒤 2초에 자리 %s → %s(그대로여야) · 예고 %s(없어야) · 판 %s(raid)" % [at, kids.map(func(k): return k.pos), kids.map(func(k): return k.cast), d.state])

# EV926 · S322: 보스 막대는 남은 총 체력 ÷ 1600이고, 몸 그림은 세대 몸 반지름에 비례해 작아진다
func ev926():
	var main = _den_game()
	var b = main.view.battle
	var hud = main.hud
	b.start_raid()
	_frame(main)
	if b.enemies.size() != 1 or b.enemies[0].get("gen") == null:
		_done(main)
		return "원정 몸에 gen이 없거나 적이 하나가 아니다(%d)" % b.enemies.size()
	var king = b.enemies[0]
	var big: float = main.view._shrunk(king)
	var rows := []
	rows.append([_left(b), hud._boss_fill.size.x])
	b.damage(king, BIG)
	_frame(main)
	var small: float = main.view._shrunk(b.enemies[0]) if not b.enemies.is_empty() else 0.0
	rows.append([_left(b), hud._boss_fill.size.x])
	if not b.enemies.is_empty():
		b.damage(b.enemies[0], BIG)
	_frame(main)
	rows.append([_left(b), hud._boss_fill.size.x])
	_done(main)
	var fits := rows.all(func(r): return absf(r[1] - 136.0 * r[0] / 1600.0) < 0.01)
	if not fits or rows[0][0] <= 1500.0 or rows[1][0] > 1200.0 or rows[2][0] > 1000.0:
		return "[남은 총 체력, 막대 폭] %s(폭 = 136 × 합 ÷ 1600 · 합은 1500 초과 → 1200 이하 → 1000 이하)" % [rows]
	return check(is_equal_approx(big, 3.0) and is_equal_approx(small, big * 0.75), "그림 배율 왕 %s(3) · 1세대 %s(왕의 0.75배)" % [big, small])

# ── 레이드 규칙(S323·I267) ── 더하는 API:
#   FloorDef.ward(평소 받는 피해 감소 비율) · groggy {time, mult} · enrage {soft, step, ramp}
#   그로기는 효과 출처 «groggy»({groggy: true})다 · 뜀 예고의 cast.aimed(겨눈 뜀이면 참) · Battle.raid_ramp() -> float(착지 피해 배율)

func _groggy(b, e) -> bool:
	return b._fx_on(e, "groggy") != null

# EV927 · S323: 1층 층 정의의 경감·그로기·광폭 수치
func ev927():
	var f = load("res://data/dungeon/floor_1.tres")
	return check(f.get("ward") == 0.88 and f.get("groggy") == {"time": 5.0, "mult": 1.5} and f.get("enrage") == {"soft": 80.0, "step": 10.0, "ramp": 0.15},
		"ward %s(0.88) · groggy %s(time 5 · mult 1.5) · enrage %s(soft 80 · step 10 · ramp 0.15)" % [f.get("ward"), f.get("groggy"), f.get("enrage")])

# EV928 · S323 ①②: 평소 12%만 받고 고정 피해는 그대로, 그로기 중에는 1.5배. 디펜스 슬라임 킹은 그대로다
func ev928():
	var b = _den()
	var e = _king(b)
	if e == null:
		return "원정이 되지 않았다(판 %s · 적 %d)" % [b.state, b.enemies.size()]
	var hp := [e.hp]
	b.damage(e, 100.0, "magic")
	hp.append(e.hp)
	b.damage(e, 100.0, "true")
	hp.append(e.hp)
	b._fx(e, "groggy", {"groggy": true}, 5.0)
	b.damage(e, 100.0, "magic")
	hp.append(e.hp)
	var lost := [hp[0] - hp[1], hp[1] - hp[2], hp[2] - hp[3]]
	if absf(lost[0] - 12.0) > 0.001 or absf(lost[1] - 100.0) > 0.001 or absf(lost[2] - 150.0) > 0.001:
		return "왕이 잃은 체력 %s(기대 마법 100 → 12 · 고정 100 → 100 · 그로기 중 마법 100 → 150)" % [lost]
	var c = _den()
	var k = c.spawn_enemy("slime_king", Vector2i(32, 100))
	var before: float = k.hp
	c.damage(k, 100.0, "magic")
	return check(absf(before - k.hp - 100.0) < 0.001, "디펜스 슬라임 킹이 마법 100에 잃은 체력 %s(100)" % [before - k.hp])

# EV929 · S323 ②: 겨눈 뜀이 아무도 못 맞히면 그 몸만 5초 그로기다. 맞히면 없고, 이동 뜀은 비어도 없다
func ev929():
	var b = _den()
	var e = _king(b)
	if e == null:
		return "원정이 되지 않았다(판 %s · 적 %d)" % [b.state, b.enemies.size()]
	var a = b.party[0]
	a.pos = Vector2(84, 82)
	_go(b, 3.2)
	if e.cast == null or not e.cast.at.is_equal_approx(a.pos) or e.cast.get("aimed") != true:
		return "① 3.2초 예고 %s(기대 착지 %s · aimed 참)" % [e.cast, a.pos]
	a.pos = Vector2(80, 86)
	_go(b, 2.2)
	if not _groggy(b, e) or e.cast != null:
		return "① 빈 착지 뒤 그로기 %s(참) · 예고 %s(없어야)" % [_groggy(b, e), e.cast]
	var at: Vector2 = e.pos
	var cd: float = e.cd.leap
	_go(b, 4.5)
	if e.pos != at or e.cd.leap != cd or e.cast != null or not _groggy(b, e):
		return "① 그로기 4.5초 동안 자리 %s → %s · 뜀 대기 %s → %s(그대로여야) · 예고 %s(없어야) · 그로기 %s(참)" % [at, e.pos, cd, e.cd.leap, e.cast, _groggy(b, e)]
	_go(b, 1.0)
	if _groggy(b, e) or e.cd.leap >= cd:
		return "① 5초 뒤 그로기 %s(거짓) · 뜀 대기 %s → %s(줄어야)" % [_groggy(b, e), cd, e.cd.leap]
	var c = _den()
	var k = _king(c)
	if k == null:
		return "② 원정이 되지 않았다"
	var hit = c.party[0]
	hit.pos = Vector2(84, 82)
	var hp: float = hit.hp
	_go(c, 5.4)
	if hit.hp >= hp or _groggy(c, k):
		return "② 맞은 영웅 체력 %s → %s(줄어야) · 왕 그로기 %s(거짓)" % [hp, hit.hp, _groggy(c, k)]
	var d = _den()
	var m = _king(d)
	if m == null:
		return "③ 원정이 되지 않았다"
	d.damage(d.party[1], BIG)
	d.damage(d.party[2], BIG)
	var far = d.party[0]
	far.pos = Vector2(75, 86)
	var hp2: float = far.hp
	_go(d, 3.2)
	var aimed = m.cast.get("aimed") if m.cast != null else null
	_go(d, 2.2)
	return check(aimed == false and m.cast == null and not _groggy(d, m) and far.hp == hp2 and m.pos != Vector2(BOSS),
		"③ 먼 영웅 쪽 뜀 aimed %s(거짓) · 착지 뒤 예고 %s(없어야) · 그로기 %s(거짓) · 영웅 체력 %s → %s · 왕 자리 %s(옮겨야)" % [aimed, m.cast, _groggy(d, m), hp2, far.hp, m.pos])

# EV930 · S323 ③④: 기절·봉인은 걸리지 않고 둔화는 걸린다. 예고가 끊기지 않고, 밀기·되감기가 자리를 옮기지 않는다. 그로기 중에도 같다
func ev930():
	var b = _den()
	var e = _king(b)
	if e == null:
		return "원정이 되지 않았다(판 %s · 적 %d)" % [b.state, b.enemies.size()]
	_go(b, 3.2)
	if e.cast == null:
		return "3.2초에 왕이 예고 중이 아니다"
	b._fx(e, "t1", {"stun": true}, 3.0)
	b._fx(e, "t2", {"slow": 0.3, "seal": true}, 3.0)
	var got := [b._fx_on(e, "stun"), b._fx_on(e, "seal"), b._fx_on(e, "slow"), e.fx.has("t1")]
	b.step(DT)
	if got != [null, null, 0.3, false] or e.cast == null or e.fx.has("stagger"):
		return "기절·봉인·둔화·기절만 든 효과 %s(기대 [null, null, 0.3, 거짓]) · 한 스텝 뒤 예고 %s(있어야) · 비틀거림 %s(없어야)" % [got, e.cast, e.fx.has("stagger")]
	var at: Vector2 = e.pos
	b._knock(e, Vector2(2, 0))
	var pushed: Vector2 = e.pos
	b.loops.append({"e": e, "at": Vector2(78, 80), "wall": false, "left": 0.0, "owner": b.party[0], "blast": 1.0, "damage": 5.0, "aged": 1.0})
	b.step(DT)
	if pushed != at or e.pos != at:
		return "밀기 뒤 %s · 되감기 뒤 %s(둘 다 %s여야)" % [pushed, e.pos, at]
	b._fx(e, "groggy", {"groggy": true}, 5.0)
	b._fx(e, "t3", {"stun": true}, 3.0)
	b._knock(e, Vector2(2, 0))
	return check(b._fx_on(e, "stun") == null and e.pos == at, "그로기 중 기절 %s(null) · 밀기 뒤 %s(기대 %s)" % [b._fx_on(e, "stun"), e.pos, at])

# 둘째 영웅만 살려 (84,82)에 두고 불꽃을 flame으로 둔 원정에서 5.4초 뒤 그 영웅이 잃은 체력. 원정이 안 되면 -1
func _landed(flame: float) -> float:
	var b = _den()
	if _king(b) == null:
		return -1.0
	b.damage(b.party[0], BIG)
	b.damage(b.party[2], BIG)
	var u = b.party[1]
	u.pos = Vector2(84, 82)
	var hp: float = u.hp
	b.flame = flame
	_go(b, 5.4)
	return hp - u.hp

# EV931 · S323 ⑤: 불꽃 80초부터 10초마다 착지 피해가 15%씩 는다
func ev931():
	var b = _den()
	if not b.has_method("raid_ramp"):
		return "raid_ramp가 없다"
	var idle: float = b.raid_ramp()
	if _king(b) == null:
		return "원정이 되지 않았다"
	var got := []
	for t in [79.9, 80.0, 95.0, 119.0]:
		b.flame = t
		got.append(b.raid_ramp())
	var want := [1.0, 1.15, 1.3, 1.6]
	if idle != 1.0 or range(4).any(func(i): return absf(got[i] - want[i]) > 0.0001):
		return "원정 밖 배율 %s(1) · 불꽃 79.9·80·95·119 배율 %s(기대 %s)" % [idle, got, want]
	var low := _landed(10.0)
	var high := _landed(81.0)
	return check(low > 0.0 and absf(high - low * 1.15) < 0.01, "착지에 잃은 체력: 불꽃 10 %s · 불꽃 81 %s(기대 앞의 1.15배 %s)" % [low, high, low * 1.15])

# ── 왕의 대본(S326·I270) ── 더하는 API:
#   FloorDef.plan [{id, wait}] · skills의 slam·soak·brand · Enemy.beat(대본 차례)·rest(그 패턴까지 남은 쉼)
#   soak 예고의 cast.at(금색 원 자리) · brand 예고의 cast.mark(표식 영웅)·cast.at(원 자리)

# 왕을 바로 움직이게 하고(서 있기 0) 뜀을 막은 원정. 대본 칸이 없으면 null
func _scripted(b, beat: int):
	var e = _king(b)
	if e == null or e.get("rest") == null or e.get("beat") == null:
		return null
	e.pull = 0.0
	e.cd["leap"] = 999.0
	e.beat = beat
	e.rest = 0.0
	return e

# 영웅 h가 피해 amount에 잃을 체력(방어력·받는 피해 감소)
func _take(b, h, amount: float) -> float:
	return amount * b.armor_mult(b.armor_of(h)) * (1.0 - b._fx_cut(h, "dr"))

# secs초 동안 적 list의 예고가 뜬 때 [초, id]와 끝난 때를 적는다
func _casts(b, list: Array, secs: float) -> Array:
	var starts := []
	var ends := []
	var on := {}
	var t := 0.0
	while t < secs:
		b.step(DT)
		t += DT
		for e in list:
			var id = e.cast.id if e.cast != null else null
			if id != on.get(e):
				if id != null:
					starts.append([t, id])
				if on.get(e) != null:
					ends.append(t)
				on[e] = id
	return [starts, ends]

# EV932 · S326: 1층 층 정의의 강타·점액 비·표식 수치와 대본
func ev932():
	var f = load("res://data/dungeon/floor_1.tres")
	var want := {
		"slam": {"windup": 2.0, "radius": 3.0, "damage": 30.0, "knock": 1.5, "slow": 0.3, "slow_time": 3.0, "counter": 1.0, "color": "blue"},
		"soak": {"windup": 4.0, "radius": 1.5, "far": 5.0, "turn": 90.0, "damage": 60.0, "need": 2, "miss": 20.0, "heal": 0.05, "counter": 1.0, "color": "gold"},
		"brand": {"windup": 3.0, "radius": 2.0, "damage": 30.0, "color": "violet"},
	}
	for id in want:
		var sk: Dictionary = f.skills.get(id, {})
		for k in want[id]:
			if sk.get(k) != want[id][k]:
				return "%s.%s %s(기대 %s)" % [id, k, sk.get(k), want[id][k]]
	return check(f.get("plan") == [{"id": "slam", "wait": 5.0}, {"id": "soak", "wait": 6.0}, {"id": "brand", "wait": 6.0}], "plan %s(기대 slam 5 → soak 6 → brand 6)" % [f.get("plan")])

# EV933 · S326: 왕은 강타 → 점액 비 → 표식을 쉼을 두고 되풀이하고 그 사이에도 뛴다. 갈라진 몸은 뜀만 쓴다
func ev933():
	var b = _den()
	var e = _king(b)
	if e == null or e.get("rest") == null:
		return "원정이 되지 않았거나 왕에 대본 칸(rest)이 없다"
	e.cd["leap"] = 999.0
	var log := _casts(b, [e], 45.0)
	var starts: Array = log[0]
	var ends: Array = log[1]
	if starts.size() < 4 or ends.size() < 3 or starts.slice(0, 4).map(func(s): return s[1]) != ["slam", "soak", "brand", "slam"]:
		return "① 뜬 예고 %s(기대 slam·soak·brand·slam)" % [starts]
	var gaps := [starts[0][0], starts[1][0] - ends[0], starts[2][0] - ends[1], starts[3][0] - ends[2]]
	var lo := [7.8, 5.8, 5.8, 4.8]
	if range(4).any(func(i): return gaps[i] < lo[i] - 0.001 or gaps[i] > lo[i] + 0.501):
		return "① 첫 예고 때와 앞 예고가 끝난 뒤 쉼 %s(기대 7.8~8.3 · 5.8~6.3 · 5.8~6.3 · 4.8~5.3)" % [gaps]
	var c = _den()
	var k = _king(c)
	if k == null:
		return "② 원정이 되지 않았다"
	var ids: Array = _casts(c, [k], 20.0)[0].map(func(s): return s[1])
	if ids.count("leap") < 2 or not "slam" in ids:
		return "② 20초 동안 뜬 예고 %s(뜀 2번 이상과 slam이 있어야)" % [ids]
	var d = _den()
	var kids := _pair(d)
	if kids.size() != 2:
		return "③ 왕을 처치했는데 몸이 둘이 아니다"
	var bare: bool = kids.all(func(x): return not x.skills.has("slam") and not x.skills.has("soak") and not x.skills.has("brand"))
	var seen: Array = _casts(d, kids, 30.0)[0].map(func(s): return s[1])
	return check(bare and not seen.is_empty() and seen.all(func(id): return id == "leap"), "③ 1세대 skills에 대본 패턴 없음 %s · 30초 동안 뜬 예고 %s(leap뿐이어야)" % [bare, seen])

# EV934 · S326 ①④: 강타는 둘레 반경 안만 치고 빗나가도 창이 없다. 카운터 창 안 기절은 예고를 끊고 그로기를 연다
func ev934():
	var b = _den()
	var e = _scripted(b, 0)
	if e == null:
		return "원정이 되지 않았거나 왕에 대본 칸(beat·rest)이 없다"
	var u = b.party[1]
	u.pos = Vector2(84, 82)
	b.step(DT)
	if e.cast == null or e.cast.id != "slam" or absf(e.cast.left - 2.0) > 0.051:
		return "한 스텝 뒤 예고 %s(기대 slam, 남은 2초)" % [e.cast]
	var want: float = _take(b, u, 30.0)
	var hp: float = u.hp
	var far: float = e.pos.distance_to(u.pos)
	var others := [b.party[0].hp, b.party[2].hp]
	_go(b, 2.2)
	if absf(hp - u.hp - want) > 0.01 or e.pos.distance_to(u.pos) <= far + 1.0 or b._fx_on(u, "slow") != 0.3 or [b.party[0].hp, b.party[2].hp] != others or _groggy(b, e):
		return "① 잃은 체력 %s(기대 %s) · 거리 %.2f → %.2f(1칸 넘게 늘어야) · 둔화 %s(0.3) · 입구 둘 %s → %s · 왕 그로기 %s(거짓)" % [hp - u.hp, want, far, e.pos.distance_to(u.pos), b._fx_on(u, "slow"), others, [b.party[0].hp, b.party[2].hp], _groggy(b, e)]
	var c = _den()
	var k = _scripted(c, 0)
	if k == null:
		return "② 원정이 되지 않았다"
	var v = c.party[1]
	v.pos = Vector2(84, 82)
	c.step(DT)
	_go(c, 0.5)
	c._fx(k, "t1", {"stun": true}, 2.0)
	var early := [k.cast != null and k.cast.id == "slam", _groggy(c, k), c._fx_on(k, "stun")]
	_go(c, 0.7)
	c._fx(k, "t2", {"stun": true}, 2.0)
	var late := [k.cast, _groggy(c, k), c._fx_on(k, "stun")]
	var hp2: float = v.hp
	_go(c, 2.0)
	return check(early == [true, false, null] and late == [null, true, null] and v.hp == hp2 and k.beat == 1,
		"② 창 앞 기절 뒤 [예고 있음, 그로기, 기절] %s(기대 [참, 거짓, null]) · 창 안 기절 뒤 [예고, 그로기, 기절] %s(기대 [null, 참, null]) · 영웅 체력 %s → %s · 대본 차례 %s(1)" % [early, late, hp2, v.hp, k.beat])

# 점액 비 예고를 띄운 원정. [판, 왕]이고 안 되면 []
func _soaking() -> Array:
	var b = _den()
	var e = _scripted(b, 1)
	if e == null:
		return []
	b.step(DT)
	if e.cast == null or e.cast.id != "soak":
		return []
	return [b, e]

# EV935 · S326 ②④·I270 ②: 점액 비는 2명 이상 모이면 나눠 받고 창이 열리며, 못 모이면 모두 맞고 왕이 회복한다. 카운터 창 안 기절은 끊는다
func ev935():
	var s := _soaking()
	if s.is_empty():
		return "점액 비 예고가 뜨지 않았다(원정·대본 칸·한 스텝 뒤 soak)"
	var b = s[0]
	var e = s[1]
	var at: Vector2 = e.cast.at
	if not at.is_equal_approx(Vector2(79, 80)) or not b.in_room(Vector2i(at.round())):
		return "금색 원 자리 %s(기대 (79,80), 보스방 칸)" % [at]
	var p = b.party
	p[1].pos = at + Vector2(0.4, 0)
	p[2].pos = at - Vector2(0.4, 0)
	var want := [_take(b, p[1], 30.0), _take(b, p[2], 30.0)]
	var hp: Array = p.map(func(h): return h.hp)
	_go(b, 4.2)
	var lost: Array = range(3).map(func(i): return hp[i] - p[i].hp)
	if lost[0] != 0.0 or absf(lost[1] - want[0]) > 0.01 or absf(lost[2] - want[1]) > 0.01 or not _groggy(b, e):
		return "① 잃은 체력 %s(기대 0 · %s · %s) · 왕 그로기 %s(참)" % [lost, want[0], want[1], _groggy(b, e)]
	s = _soaking()
	if s.is_empty():
		return "② 점액 비 예고가 뜨지 않았다"
	b = s[0]
	e = s[1]
	p = b.party
	b.damage(e, 100.0, "true")
	p[1].pos = at
	want = [_take(b, p[1], 20.0), _take(b, p[2], 20.0)]
	hp = p.map(func(h): return h.hp)
	_go(b, 4.2)
	lost = range(3).map(func(i): return hp[i] - p[i].hp)
	if lost[0] <= 0.0 or absf(lost[1] - want[0]) > 0.01 or absf(lost[2] - want[1]) > 0.01 or absf(e.hp - 320.0) > 0.001 or _groggy(b, e):
		return "② 잃은 체력 %s(기대 0 초과 · %s · %s) · 왕 체력 %s(320) · 그로기 %s(거짓)" % [lost, want[0], want[1], e.hp, _groggy(b, e)]
	s = _soaking()
	if s.is_empty():
		return "③ 점액 비 예고가 뜨지 않았다"
	b = s[0]
	e = s[1]
	_go(b, 3.2)
	b._fx(e, "t", {"stun": true}, 2.0)
	var cut := [e.cast, _groggy(b, e)]
	hp = b.party.map(func(h): return h.hp)
	_go(b, 1.5)
	if cut != [null, true] or b.party.map(func(h): return h.hp) != hp:
		return "③ 창 안 기절 뒤 [예고, 그로기] %s(기대 [null, 참]) · 영웅 체력 %s → %s(그대로여야)" % [cut, hp, b.party.map(func(h): return h.hp)]
	s = _soaking()
	if s.is_empty():
		return "④ 점액 비 예고가 뜨지 않았다"
	b = s[0]
	e = s[1]
	b.damage(b.party[0], BIG)
	b.damage(b.party[2], BIG)
	var lone = b.party[1]
	lone.pos = at
	var hp1: float = lone.hp
	_go(b, 4.2)
	return check(lone.hp < hp1 and not _groggy(b, e) and e.hp == 400.0, "④ 혼자 들어간 영웅 체력 %s → %s(줄어야) · 왕 그로기 %s(거짓) · 왕 체력 %s(400)" % [hp1, lone.hp, _groggy(b, e), e.hp])

# EV936 · S326 ③·I270 ③: 표식은 출전 차례로 산 영웅에 붙어 따라다니고, 끝날 때 원 안 모두가 맞는다
func ev936():
	var b = _den()
	var e = _scripted(b, 2)
	if e == null:
		return "원정이 되지 않았거나 왕에 대본 칸(beat·rest)이 없다"
	var p = b.party
	b.damage(p[0], BIG)
	b.step(DT)
	if e.cast == null or e.cast.id != "brand" or e.cast.get("mark") != p[1] or not e.cast.at.is_equal_approx(p[1].pos):
		return "한 스텝 뒤 예고 %s(기대 brand, 표식 둘째 영웅, 자리 %s)" % [e.cast, p[1].pos]
	p[1].pos = Vector2(80, 80)
	p[2].pos = Vector2(80.5, 80)
	b.step(DT)
	if e.cast == null or not e.cast.at.is_equal_approx(Vector2(80, 80)):
		return "영웅을 옮긴 뒤 원 자리 %s(기대 (80,80))" % [e.cast]
	var want := [_take(b, p[1], 30.0), _take(b, p[2], 30.0)]
	var hp := [p[1].hp, p[2].hp]
	_go(b, 3.2)
	if absf(hp[0] - p[1].hp - want[0]) > 0.01 or absf(hp[1] - p[2].hp - want[1]) > 0.01 or _groggy(b, e) or e.cast != null:
		return "잃은 체력 %s · %s(기대 %s · %s) · 왕 그로기 %s(거짓) · 예고 %s(없어야)" % [hp[0] - p[1].hp, hp[1] - p[2].hp, want[0], want[1], _groggy(b, e), e.cast]
	var marks := []
	for i in 2:
		e.beat = 2
		e.rest = 0.0
		b.step(DT)
		marks.append(e.cast.get("mark") if e.cast != null else null)
		_go(b, 3.2)
	return check(marks == [p[2], p[1]], "다음 표식 차례 %s(기대 셋째 → 둘째 영웅)" % [marks.map(func(m): return m.kind if m != null else null)])

# ── «다시» 창·첫 원정 힌트·튕김(S331·S332·I277) ── 더하는 API:
#   Battle.raid_pending() -> bool(전멸·불꽃 뒤 «다시»·«철수»를 기다리는 중) · retry() -> bool(횃불 하나로 같은 층을 다시. 못 하면 거짓이고 판은 그대로)
#   raid_left()는 원정이 끝난 뒤에는 끝난 순간의 값이다 · 튕김은 효과 출처 «deflect»({deflect: true})다
#   main.hud.again — «다시» 창(Control) · main.hud.again_retry — «다시» 버튼 · main.hud.again_retreat — «철수» 버튼
#   끝낸 힌트 이름 «raid»(Settings.hints_done)

# EV950 · S331·I277 ①②: 전멸 뒤 2.5초가 지나면 «다시»를 기다리고 그동안 왕과 불꽃이 멈춘다. retry는 횃불 하나로 원정 직전 몸·새 왕·불꽃 0에서 다시 한다
func ev950():
	var b = _den()
	if not b.has_method("retry") or not b.has_method("raid_pending"):
		return "Battle에 retry·raid_pending이 없다"
	var a = b.heroes[0]
	a.hp = 40.0
	a.pos = Vector2(30, 70)
	b.heroes[1].cd.q = 3.0
	var seen := []
	b.raid_starting.connect(func(): seen.append([b.state, b.torches, a.pos]))
	b.start_raid()
	if b.state != "raid" or b.enemies.size() != 1:
		return "원정이 되지 않았다(판 %s · 적 %d)" % [b.state, b.enemies.size()]
	var king = b.enemies[0]
	for h in b.party:
		b.damage(h, BIG)
	_go(b, 2.4)
	var early: bool = b.raid_pending()
	_go(b, 0.2)
	if early or not b.raid_pending() or b.state != "raid":
		return "전멸 뒤 2.4초 기다림 %s(거짓) · 2.6초 %s(참) · 판 %s(raid)" % [early, b.raid_pending(), b.state]
	var at: Vector2 = king.pos
	var flame: float = b.flame
	_go(b, 1.0)
	if king.pos != at or king.cast != null or b.flame != flame or not b.raid_pending():
		return "기다리는 1초 동안 왕 자리 %s → %s · 예고 %s(없어야) · 불꽃 %s → %s(그대로여야) · 기다림 %s(참)" % [at, king.pos, king.cast, flame, b.flame, b.raid_pending()]
	b.loops.append({"e": king, "at": Vector2(78, 80), "wall": false, "left": 5.0, "owner": a, "blast": 1.0, "damage": 5.0, "aged": 1.0})
	var ok: bool = b.retry()
	if not ok or b.torches != 0 or seen != [["prep", 1, Vector2(30, 70)], ["prep", 0, Vector2(30, 70)]]:
		return "retry %s(참) · 횃불 %d(0) · 저장 신호 [판, 횃불, 첫째 영웅 자리] %s(기대 [prep, 1, (30,70)] · [prep, 0, (30,70)])" % [ok, b.torches, seen]
	var spots: Array = b.party.map(func(h): return Vector2i(h.pos.round()))
	var count: Array = b.heroes.map(func(h): return b.units.count(h))
	if b.state != "raid" or b.party != b.heroes or not b.party.all(func(h): return h.alive) or spots != ENTRY or a.hp != 40.0 or b.heroes[1].cd.q != 3.0 or count != [1, 1, 1]:
		return "다시 뒤 판 %s(raid) · 원정대 %d명 · 자리 %s(기대 %s) · 첫째 체력 %s(40) · 둘째 Q 대기 %s(3) · units 안 횟수 %s(1·1·1)" % [b.state, b.party.size(), spots, ENTRY, a.hp, b.heroes[1].cd.q, count]
	var e = b.enemies[0] if b.enemies.size() == 1 else null
	if e == null or e == king or Vector2i(e.pos.round()) != BOSS or e.hp != 400.0 or b.flame != 0.0 or b.raid_pending() or not b.zones.is_empty() or not b.missiles.is_empty() or not b.loops.is_empty():
		return "다시 뒤 적 %d(새 왕 하나, (84,80), 체력 400) · 불꽃 %s(0) · 기다림 %s(거짓) · 장판 %d · 투사체 %d · 루프 %d(모두 0)" % [b.enemies.size(), b.flame, b.raid_pending(), b.zones.size(), b.missiles.size(), b.loops.size()]
	_freeze(b)
	var from: Vector2 = e.pos
	_go(b, 2.9)
	return check(e.pos == from and e.cast == null, "새 왕이 2.9초 안에 %s → %s · 예고 %s(서 있어야)" % [from, e.pos, e.cast])

# EV951 · S331·I277 ①②: 불꽃이 다 타도 기다리고 끝난 순간의 남은 체력이 남는다. 횃불이 없거나 끝나기 전이면 retry가 거짓이다. 철수는 돌아오고, 처치는 기다림 없이 3초 뒤 돌아온다
func ev951():
	var b = _den()
	if not b.has_method("retry") or not b.has_method("raid_pending"):
		return "Battle에 retry·raid_pending이 없다"
	var hp: Array = b.heroes.map(func(h): return h.hp)
	var e = _king(b)
	if e == null:
		return "① 원정이 되지 않았다(판 %s · 적 %d)" % [b.state, b.enemies.size()]
	b.damage(e, 100.0, "true")
	b.flame = 119.9
	_go(b, 0.2)
	var gone: bool = b.enemies.is_empty()
	_go(b, 2.4)
	var early: bool = b.raid_pending()
	_go(b, 0.2)
	if not gone or early or not b.raid_pending() or absf(b.raid_left() - 1500.0 / 1600.0) > 0.0001:
		return "① 불꽃 120초 뒤 적 없음 %s · 2.6초 기다림 %s(거짓) · 2.8초 %s(참) · 남은 체력 비율 %s(기대 %s)" % [gone, early, b.raid_pending(), b.raid_left(), 1500.0 / 1600.0]
	b.torches = 0
	var ok: bool = b.retry()
	if ok or b.state != "raid" or b.torches != 0 or not b.raid_pending():
		return "① 횃불 0에서 retry %s(거짓) · 판 %s(raid) · 횃불 %d(0) · 기다림 %s(참)" % [ok, b.state, b.torches, b.raid_pending()]
	b.retreat()
	if b.state != "prep" or b.heroes.map(func(h): return h.hp) != hp or b.floors_cleared != 0:
		return "① 철수 뒤 판 %s(prep) · 체력 %s(기대 %s) · 깬 층 %d(0)" % [b.state, b.heroes.map(func(h): return h.hp), hp, b.floors_cleared]
	var c = _den()
	var k = _king(c)
	if k == null:
		return "② 원정이 되지 않았다"
	var no: bool = c.retry()
	if no or c.torches != 1 or c.enemies != [k]:
		return "② 끝나기 전 retry %s(거짓) · 횃불 %d(1) · 적 %d(그대로 하나)" % [no, c.torches, c.enemies.size()]
	_slay(c)
	_go(c, 2.9)
	var mid := [c.state, c.raid_pending()]
	_go(c, 0.2)
	return check(mid == ["raid", false] and c.state == "prep" and c.floors_cleared == 1, "② 처치 뒤 2.9초 [판, 기다림] %s(기대 [raid, 거짓]) · 3.1초 %s(prep) · 깬 층 %d(1)" % [mid, c.state, c.floors_cleared])

# 게임 장면을 0.05초씩 secs초 돌린다(판과 HUD)
func _spin(main, secs: float) -> void:
	for i in roundi(secs / 0.05):
		main._process(0.05)
		main.hud._process(0.05)

# EV952 · S331·I277 ③: 전멸 2.6초 뒤 «다시» 창이 뜨고 보스 남은 체력과 두 버튼이 있다. «다시»는 원정을 잇고, 횃불이 없으면 꺼진 채 이유를 보이며, «철수»는 돌아온다
func ev952():
	var main = _den_game()
	var b = main.view.battle
	var hud = main.hud
	if not hud.get("again") is Control or not hud.get("again_retry") is BaseButton or not hud.get("again_retreat") is BaseButton or not b.has_method("raid_pending"):
		_done(main)
		return "main.hud.again·again_retry·again_retreat나 Battle.raid_pending이 없다"
	b.start_raid()
	_frame(main)
	var first: bool = hud.again.is_visible_in_tree()
	for h in b.party:
		b.damage(h, BIG)
	_spin(main, 2.6)
	_layout(main)
	var said := " ".join(_labels(hud.again))
	var shown := [hud.again.is_visible_in_tree(), "보스 남은 체력 100%" in said, "다시" in hud.again_retry.text and "횃불 1" in hud.again_retry.text, "철수" in hud.again_retreat.text, hud.again_retry.disabled]
	if b.state != "raid" or first or shown != [true, true, true, true, false]:
		_done(main)
		return "판 %s(raid) · 원정 시작 때 창 보임 %s(거짓) · 전멸 2.6초 뒤 [창 보임, «보스 남은 체력 100%%», «다시»·«횃불 1», «철수», «다시» 꺼짐] %s(기대 [참, 참, 참, 참, 거짓]) · 창 글 «%s» · 버튼 «%s»·«%s»" % [b.state, first, shown, said, hud.again_retry.text, hud.again_retreat.text]
	hud.again_retry.pressed.emit()
	_frame(main)
	var again := [hud.again.is_visible_in_tree(), b.state, b.torches, not b.party.is_empty() and b.party.all(func(h): return h.alive)]
	if again != [false, "raid", 0, true]:
		_done(main)
		return "«다시» 뒤 [창 보임, 판, 횃불, 원정대 모두 삶] %s(기대 [거짓, raid, 0, 참])" % [again]
	for h in b.party:
		b.damage(h, BIG)
	_spin(main, 2.6)
	_layout(main)
	var open: bool = hud.again.is_visible_in_tree()
	var tip := _tip_of(main, hud.again_retry) if open else ""
	if not open or not hud.again_retry.disabled or not "횃불 없음" in tip:
		_done(main)
		return "횃불 0에서 전멸 2.6초 뒤 창 보임 %s(참) · «다시» 꺼짐 %s(참) · 툴팁 «%s»(«횃불 없음»이 있어야)" % [open, hud.again_retry.disabled, tip]
	hud.again_retreat.pressed.emit()
	_frame(main)
	var back := [b.state, hud.again.is_visible_in_tree()]
	_done(main)
	return check(back == ["prep", false], "«철수» 뒤 [판, 창 보임] %s(기대 [prep, 거짓])" % [back])

# EV953 · S331: 횃불을 쓸 때마다 원정 직전 몸·줄어든 횃불로 저장한다. «다시» 뒤 저장은 준비 단계·횃불 0이고 원정 중에는 바뀌지 않는다
func ev953():
	var main = _den_game()
	var b = main.view.battle
	if not b.has_method("retry"):
		_done(main)
		return "Battle에 retry가 없다"
	var s = _save()
	b.start_raid()
	_frame(main)
	var first: Dictionary = s.read()
	for h in b.party:
		b.damage(h, BIG)
	_spin(main, 2.6)
	var ok: bool = b.retry()
	_frame(main)
	var second: Dictionary = s.read()
	var text := FileAccess.get_file_as_string(PATH)
	var loaded = _loaded()
	_spin(main, 1.0)
	var during := FileAccess.get_file_as_string(PATH)
	_done(main)
	if first.get("state") != "prep" or first.get("torches") != 1 or not ok or second.get("state") != "prep" or second.get("torches") != 0:
		return "원정 시작 저장 판 %s 횃불 %s(prep, 1) · retry %s(참) · «다시» 뒤 저장 판 %s 횃불 %s(prep, 0)" % [first.get("state"), first.get("torches"), ok, second.get("state"), second.get("torches")]
	return check(loaded.state == "prep" and loaded.torches == 0 and not loaded.heroes.is_empty() and loaded.heroes.all(func(h): return h.alive) and during == text,
		"불러온 판 %s 횃불 %d(prep, 0) · 출전 영웅 %d명 모두 삶 %s(참) · 원정 1초 동안 저장 파일 바뀜 %s(거짓)" % [loaded.state, loaded.torches, loaded.heroes.size(), loaded.heroes.all(func(h): return h.alive), during != text])

# 서 있지도 뛰지도 대본을 돌지도 않는 왕. 원정이 안 됐거나 대본 칸이 없으면 null
func _idle_king(b):
	var e = _king(b)
	if e == null or e.get("rest") == null:
		return null
	e.pull = 0.0
	e.cd["leap"] = 999.0
	e.rest = 999.0
	return e

# EV954 · I277 ⑤: 카운터 창 밖에서 지워진 기절·봉인은 0.5초 튕김 효과를 남긴다. 둔화만 든 효과와 카운터 창 안 끊기에는 없다
func ev954():
	var b = _den()
	var e = _idle_king(b)
	if e == null:
		return "① 원정이 되지 않았거나 왕에 대본 칸(rest)이 없다"
	b._fx(e, "t0", {"slow": 0.3}, 3.0)
	var none = b.effect(e, "deflect")
	b._fx(e, "t1", {"stun": true}, 3.0)
	var got := [b.effect(e, "deflect") != null, b.effect(e, "stun")]
	_go(b, 0.4)
	var mid: bool = b.effect(e, "deflect") != null
	_go(b, 0.2)
	var after = b.effect(e, "deflect")
	if none != null or got != [true, null] or not mid or after != null:
		return "① 둔화만 건 뒤 튕김 %s(null) · 기절을 건 뒤 [튕김 있음, 기절] %s(기대 [참, null]) · 0.4초 뒤 있음 %s(참) · 0.6초 뒤 %s(null)" % [none, got, mid, after]
	b._fx(e, "groggy", {"groggy": true}, 5.0)
	b._fx(e, "t2", {"slow": 0.3, "seal": true}, 3.0)
	if b.effect(e, "deflect") == null or b.effect(e, "seal") != null:
		return "② 그로기 중 봉인을 건 뒤 튕김 %s(있어야) · 봉인 %s(null)" % [b.effect(e, "deflect"), b.effect(e, "seal")]
	var c = _den()
	var k = _scripted(c, 0)
	if k == null:
		return "③ 원정이 되지 않았다"
	c.step(DT)
	_go(c, 1.2)
	var casting: bool = k.cast != null and k.cast.id == "slam"
	c._fx(k, "t", {"stun": true}, 2.0)
	return check(casting and k.cast == null and _groggy(c, k) and c.effect(k, "deflect") == null,
		"③ 강타 예고 1.2초 뒤 예고 중 %s(참) · 기절을 건 뒤 예고 %s(없어야) · 그로기 %s(참) · 튕김 %s(null)" % [casting, k.cast, _groggy(c, k), c.effect(k, "deflect")])

# EV955 · S332·I277 ④: 원정에 들어가면 첫 원정 힌트가 뜨고 그로기가 열리면 끝나 다음 원정에는 안 뜬다. 힌트 설정을 끄면 안 뜬다
func ev955():
	var st = _hints_reset()
	var main = _den_game()
	var b = main.view.battle
	var hud = main.hud
	var out := ""
	var before: bool = hud.hints.is_visible_in_tree()
	b.start_raid()
	_frame(main)
	var said := _hint_says(main)
	if before or b.state != "raid" or b.enemies.is_empty() or not "그로기" in said or not "금색" in said:
		out = "2라운드 준비 단계 힌트 칸 보임 %s(거짓) · 원정 판 %s · 힌트 글 «%s»(«그로기»·«금색»이 있어야)" % [before, b.state, said]
	if out == "":
		b._fx(b.enemies[0], "groggy", {"groggy": true}, 5.0)
		_frame(main)
		if hud.hints.is_visible_in_tree() or not "raid" in st.hints_done:
			out = "그로기 뒤 힌트 칸 보임 %s(거짓) · 끝낸 힌트 %s(raid가 있어야)" % [hud.hints.is_visible_in_tree(), st.hints_done]
	if out == "":
		b.retreat()
		_frame(main)
		b.start_raid()
		_frame(main)
		if b.state != "raid" or hud.hints.is_visible_in_tree():
			out = "다음 원정(판 %s)에 힌트 칸 보임 %s(거짓)" % [b.state, hud.hints.is_visible_in_tree()]
	if out == "":
		st.hints_done = []
		st.hints = false
		_frame(main)
		var off: bool = hud.hints.is_visible_in_tree()
		st.hints = true
		_frame(main)
		out = check(not off and hud.hints.is_visible_in_tree(), "끝낸 힌트를 비우고 힌트 설정을 끈 채 보임 %s(거짓) · 켠 뒤 %s(참)" % [off, hud.hints.is_visible_in_tree()])
	_done(main)
	_hints_reset()
	return out

# ── 층 보상·유물(S333·S334·I278) ── 더하는 API:
#   FloorDef.relic(유물 id)·gold(층 골드) · data/relics/<유물 id>.tres(title·steps·notes) · HireDef.relic_cost·relic_cap
#   Battle.RELIC_KINDS · relics(유물 id → 강화 수치) · relic_forged(이번 창 강화 횟수) · Unit.relic(낀 유물 id, 없으면 "")·relic_fx(낀 유물 효과 사전)
#     wear_relic(영웅, 유물 id) -> bool(""면 뺀다) · forge_relic(유물 id) -> bool. 못 하면 거짓이고 판은 그대로
#   main.hud.relic_rows — 유물마다 [유물 id, 줄(Control), 글(Label), 강화 버튼, 영웅 바꾸기 버튼]

const CROWN := "slime_crown"

# EV956 · S333·S334: 1층 층 정의의 유물·층 골드, 점액 왕관의 단계, 강화 비용과 창당 횟수
func ev956():
	var f = load("res://data/dungeon/floor_1.tres")
	if f.get("relic") != CROWN or f.get("gold") != 120:
		return "floor_1 relic %s(slime_crown) · gold %s(120)" % [f.get("relic"), f.get("gold")]
	if not ResourceLoader.exists("res://data/relics/slime_crown.tres"):
		return "data/relics/slime_crown.tres가 없다"
	var r = load("res://data/relics/slime_crown.tres")
	var steps = r.get("steps")
	var want := [0.05, 0.07, 0.09, 0.11, 0.13]
	if r.get("title") != "점액 왕관" or not steps is Array or steps.size() != 5 or range(5).any(func(i): return absf(steps[i].get("cdr", -1.0) - want[i]) > 0.000001):
		return "점액 왕관 이름 %s · 단계 %s(기대 cdr %s)" % [r.get("title"), steps, want]
	var hire = load("res://data/hire.tres")
	return check(hire.get("relic_cost") == [60, 90, 130, 180] and hire.get("relic_cap") == 1, "relic_cost %s([60, 90, 130, 180]) · relic_cap %s(1)" % [hire.get("relic_cost"), hire.get("relic_cap")])

# EV957 · S333·I278 ①: 처치로 돌아오면 층 골드와 유물 +0을 받고 출전 첫째 영웅이 저절로 낀다. 전멸·철수로는 받지 않는다
func ev957():
	var b = _den()
	if b.get("relics") == null:
		return "Battle에 relics가 없다"
	var gold: int = b.gold
	b.start_raid()
	_slay(b)
	_go(b, 3.1)
	var worn: Array = b.heroes.map(func(h): return h.relic)
	if b.state != "prep" or b.gold != gold + 120 or b.relics != {CROWN: 0} or worn != [CROWN, "", ""] or absf(b.heroes[0].relic_fx.get("cdr", 0.0) - 0.05) > 0.000001:
		return "① 처치 뒤 판 %s(prep) · 골드 %d → %d(120 늘어야) · 가방 %s({slime_crown: 0}) · 낀 유물 %s(첫째만) · 첫째 relic_fx %s(cdr 0.05)" % [b.state, gold, b.gold, b.relics, worn, b.heroes[0].relic_fx]
	var c = _den()
	c.torches = 4
	var g: int = c.gold
	c.start_raid()
	for h in c.party:
		c.damage(h, BIG)
	_go(c, 2.6)
	c.retreat()
	c.start_raid()
	c.retreat()
	return check(c.state == "prep" and c.gold == g and c.relics.is_empty() and c.heroes.all(func(h): return h.relic == ""),
		"② 전멸 뒤 철수·바로 철수 뒤 판 %s(prep) · 골드 %d → %d(그대로) · 가방 %s(비어야) · 낀 유물 %s(없어야)" % [c.state, g, c.gold, c.relics, c.heroes.map(func(h): return h.relic)])

# 라운드 사이에 가방에 점액 왕관 +n을 두고 who번째 영웅에게 끼운 뒤 2라운드 첫 준비 단계로 넘긴 판. 유물 API가 없으면 null.
# 출전 셋은 스킬 대기 오라가 없는 영웅이다(이그니스 오라는 셋 모두의 대기를 25% 빠르게 한다)
func _crowned(n: int, who: int):
	var st := _stage()
	st.heroes = [TEAM[0], {"kind": "sylvia", "cell": Vector2i(33, 65)}, TEAM[2]]
	var b = _new(st)
	if not b.has_method("wear_relic") or b.get("relics") == null:
		return null
	b.state = "cleared"
	b.relics[CROWN] = n
	if not b.wear_relic(b.heroes[who], CROWN):
		return null
	b.next_round()
	return b

# 출전 영웅의 오토를 끄고 Q 대기 50초·대시 대기 5초로 둔 뒤 1초 돌려, 영웅마다 [준 Q 대기, 준 대시 대기]
func _drain(b) -> Array:
	for h in b.heroes:
		for k in h.auto:
			h.auto[k] = false
		h.cd.q = 50.0
		h.dash_cd = 5.0
	_go(b, 1.0)
	return b.heroes.map(func(h): return [50.0 - h.cd.q, 5.0 - h.dash_cd])

# rows(영웅마다 [준 Q 대기, 준 대시 대기])가 둘째 영웅만 Q 대기 fast초, 나머지는 1초이고 대시 대기는 모두 1초인가
func _paced(rows: Array, fast: float) -> bool:
	return rows.size() == 3 and range(3).all(func(i): return absf(rows[i][0] - (fast if i == 1 else 1.0)) < 0.001 and absf(rows[i][1] - 1.0) < 0.001)

# EV958 · S334·I278 ③: 왕관을 낀 영웅만 스킬 대기가 5% 빨리 준다. 전투 단계와 원정 모두에서, 대시 대기는 그대로. +2면 9%다
func ev958():
	var b = _crowned(0, 1)
	if b == null:
		return "유물 API(relics·wear_relic)가 없거나 라운드 사이에 끼우지 못했다"
	b.start_battle()
	var war := _drain(b)
	if b.state != "battle" or not _paced(war, 1.05):
		return "① 전투 단계(판 %s) 1초에 [준 Q 대기, 준 대시 대기] %s(기대 둘째만 1.05, 나머지 1 · 대시 모두 1)" % [b.state, war]
	var c = _crowned(0, 1)
	c.start_raid()
	_freeze(c)
	var raid := _drain(c)
	if c.state != "raid" or not _paced(raid, 1.05):
		return "② 원정(판 %s) 1초에 [준 Q 대기, 준 대시 대기] %s(기대 둘째만 1.05, 나머지 1 · 대시 모두 1)" % [c.state, raid]
	var d = _crowned(2, 1)
	d.start_battle()
	var up := _drain(d)
	return check(_paced(up, 1.09), "③ 왕관 +2에서 전투 1초에 [준 Q 대기, 준 대시 대기] %s(기대 둘째만 1.09)" % [up])

# EV959 · S334·I278 ④: 끼기·빼기는 라운드 사이에만 되고, 유물 하나는 한 영웅만 낀다. 내보낸 영웅의 유물은 가방에 남는다
func ev959():
	var b = _den()
	if not b.has_method("wear_relic") or b.get("relics") == null:
		return "Battle에 wear_relic·relics가 없다"
	b.relics[CROWN] = 0
	var a = b.heroes[0]
	var c = b.heroes[1]
	var d = b.heroes[2]
	var early: bool = b.wear_relic(a, CROWN)
	if early or a.relic != "":
		return "준비 단계 끼기 %s(거짓) · 낀 유물 «%s»(없어야)" % [early, a.relic]
	b.state = "cleared"
	var first: bool = b.wear_relic(a, CROWN)
	if not first or a.relic != CROWN or absf(a.relic_fx.get("cdr", 0.0) - 0.05) > 0.000001:
		return "라운드 사이 끼기 %s(참) · 첫째 relic «%s» · relic_fx %s(cdr 0.05)" % [first, a.relic, a.relic_fx]
	var moved: bool = b.wear_relic(c, CROWN)
	if not moved or a.relic != "" or not a.relic_fx.is_empty() or c.relic != CROWN:
		return "둘째에게 끼우기 %s(참) · 첫째 relic «%s»·relic_fx %s(비어야) · 둘째 relic «%s»" % [moved, a.relic, a.relic_fx, c.relic]
	var none: bool = b.wear_relic(c, "no_such_relic")
	var off: bool = b.wear_relic(c, "")
	if none or not off or b.heroes.any(func(h): return h.relic != ""):
		return "없는 유물 끼기 %s(거짓) · 빼기 %s(참) · 낀 유물 %s(없어야)" % [none, off, b.heroes.map(func(h): return h.relic)]
	var last: bool = b.wear_relic(d, CROWN)
	b.dismiss(d)
	var gone: bool = b.wear_relic(d, CROWN)
	return check(last and d not in b.roster and d.relic == "" and b.relics == {CROWN: 0} and not gone,
		"셋째에게 끼우기 %s(참) · 내보낸 뒤 보유 %s(거짓) · relic «%s»(없어야) · 가방 %s · 내보낸 영웅에게 끼우기 %s(거짓)" % [last, d in b.roster, d.relic, b.relics, gone])

# EV960 · S334·I278 ④: 강화는 라운드 사이에만, 창마다 한 번, 60·90·130·180골드로 +4까지다
func ev960():
	var b = _den()
	if not b.has_method("forge_relic") or not b.has_method("wear_relic") or b.get("relics") == null:
		return "Battle에 forge_relic·wear_relic·relics가 없다"
	b.relics[CROWN] = 0
	b.gold = 1000
	var a = b.heroes[0]
	var early: bool = b.forge_relic(CROWN)
	b.state = "cleared"
	b.wear_relic(a, CROWN)
	var first: bool = b.forge_relic(CROWN)
	if early or not first or b.gold != 940 or b.relics[CROWN] != 1 or absf(a.relic_fx.get("cdr", 0.0) - 0.07) > 0.000001:
		return "준비 단계 강화 %s(거짓) · 라운드 사이 강화 %s(참) · 골드 %d(940) · 유물 +%d(1) · relic_fx %s(cdr 0.07)" % [early, first, b.gold, b.relics[CROWN], a.relic_fx]
	var twice: bool = b.forge_relic(CROWN)
	if twice or b.gold != 940 or b.relics[CROWN] != 1:
		return "같은 창 둘째 강화 %s(거짓) · 골드 %d(940) · 유물 +%d(1)" % [twice, b.gold, b.relics[CROWN]]
	b.next_round()
	b.state = "cleared"
	var next: bool = b.forge_relic(CROWN)
	if not next or b.gold != 850 or b.relics[CROWN] != 2:
		return "다음 라운드 사이 강화 %s(참) · 골드 %d(850) · 유물 +%d(2)" % [next, b.gold, b.relics[CROWN]]
	b.relic_forged.clear()
	b.gold = 100
	var poor: bool = b.forge_relic(CROWN)
	b.gold = 1000
	var more := []
	for i in 3:
		b.relic_forged.clear()
		more.append(b.forge_relic(CROWN))
	if poor or more != [true, true, false] or b.relics[CROWN] != 4 or b.gold != 690:
		return "골드 100에서 강화 %s(거짓) · 창당 횟수를 비우며 세 번 %s(기대 [참, 참, 거짓]) · 유물 +%d(4) · 골드 %d(690)" % [poor, more, b.relics[CROWN], b.gold]
	b.relic_forged.clear()
	b.relics.erase(CROWN)
	var lost: bool = b.forge_relic(CROWN)
	var none: bool = b.forge_relic("no_such_relic")
	return check(not lost and not none and b.gold == 690, "가방에 없는 유물 강화 %s · 없는 유물 id 강화 %s(둘 다 거짓) · 골드 %d(690)" % [lost, none, b.gold])

# EV961 · S334·I278 ②: 유물 가방·창당 횟수·낀 유물은 저장에 담긴다. 옛 저장과 새 도전은 유물이 없고, 라운드 전리품에 유물이 나오지 않는다
func ev961():
	var st := _stage()
	st.heroes = TEAM
	var b = _new(st)
	if not b.has_method("forge_relic") or not b.has_method("wear_relic") or b.get("relics") == null:
		return "Battle에 forge_relic·wear_relic·relics가 없다"
	b.state = "cleared"
	b.relics[CROWN] = 0
	b.wear_relic(b.heroes[1], CROWN)
	b.forge_relic(CROWN)
	var s = _save()
	var d: Dictionary = s.snapshot(b)
	var fresh = _new(st)
	s.apply(fresh, d.duplicate(true))
	var h = fresh.heroes[1] if fresh.heroes.size() == 3 else null
	if h == null or fresh.relics != {CROWN: 1} or fresh.relic_forged != {CROWN: 1} or h.relic != CROWN or absf(h.relic_fx.get("cdr", 0.0) - 0.07) > 0.000001:
		return "① 되돌린 판 가방 %s({slime_crown: 1}) · 창당 횟수 %s({slime_crown: 1}) · 둘째 영웅 relic «%s»·relic_fx %s(cdr 0.07)" % [fresh.relics, fresh.relic_forged, h.relic if h else null, h.relic_fx if h else null]
	var old: Dictionary = d.duplicate(true)
	old.erase("relics")
	old.erase("relic_forged")
	for f in old.heroes:
		f.erase("relic")
		f.erase("relic_fx")
	var aged = _new(st)
	s.apply(aged, old)
	if not aged.relics.is_empty() or not aged.relic_forged.is_empty() or aged.heroes.any(func(x): return x.relic != "" or not x.relic_fx.is_empty()):
		return "② 옛 저장을 되돌린 판 가방 %s · 창당 횟수 %s(비어야) · 낀 유물 %s(없어야)" % [aged.relics, aged.relic_forged, aged.heroes.map(func(x): return x.relic)]
	fresh.restart()
	if not fresh.relics.is_empty() or not fresh.relic_forged.is_empty():
		return "③ 새 도전 뒤 가방 %s · 창당 횟수 %s(비어야)" % [fresh.relics, fresh.relic_forged]
	var odd := []
	for i in 40:
		b._drop_gear()
		if not b.dropped.is_empty() and not b.GEAR_KINDS.has(b.dropped[0]):
			odd.append(b.dropped[0])
	return check(odd.is_empty() and not b.bag.has(CROWN), "④ 전리품 40번에 전용장비가 아닌 것 %s(없어야) · 전용장비 가방에 slime_crown %s(거짓)" % [odd, b.bag.has(CROWN)])

# EV962 · S334·I278 ⑤: 장비 칸의 유물 줄. 없으면 숨고, 있으면 이름·수치·낀 영웅과 강화·영웅 바꾸기 버튼이 있다
func ev962():
	var main = _prep()
	var b = main.view.battle
	var hud = main.hud
	if not hud.get("relic_rows") is Array or not b.has_method("wear_relic"):
		_done(main)
		return "main.hud.relic_rows나 Battle.wear_relic이 없다"
	if not _win(b):
		_done(main)
		return "1라운드를 이기지 못했다(%s)" % b.state
	_frame(main)
	hud._gear_tab = true
	_frame(main)
	_layout(main)
	var rows: Array = hud.relic_rows.filter(func(r): return r[0] == CROWN)
	if rows.size() != 1 or not hud.window.is_visible_in_tree() or rows[0][1].is_visible_in_tree():
		_done(main)
		return "장비 칸의 slime_crown 줄 %d개(1) · 창 보임 %s(참) · 유물이 없을 때 줄 보임 %s(거짓)" % [rows.size(), hud.window.is_visible_in_tree(), rows[0][1].is_visible_in_tree() if rows.size() == 1 else null]
	var row: Array = rows[0]
	var names: Array = b.roster.map(func(h): return hud.HEROES[h.kind].get_slice("(", 0))
	b.relics[CROWN] = 0
	b.wear_relic(b.roster[0], CROWN)
	b.gold = 1000
	_frame(main)
	_layout(main)
	if not row[1].is_visible_in_tree() or not "점액 왕관 +0" in row[2].text or not names[0] in row[2].text or row[3].text != "강화 +1 · 60골드" or row[3].disabled:
		_done(main)
		return "유물 줄 보임 %s(참) · 글 «%s»(«점액 왕관 +0»·«%s») · 강화 버튼 «%s»(강화 +1 · 60골드) 꺼짐 %s(거짓)" % [row[1].is_visible_in_tree(), row[2].text, names[0], row[3].text, row[3].disabled]
	row[3].pressed.emit()
	_frame(main)
	_layout(main)
	var tip := _tip_of(main, row[3])
	if not "점액 왕관 +1" in row[2].text or not row[3].disabled or not "다 씀" in tip or b.gold != 940:
		_done(main)
		return "강화 뒤 글 «%s»(«점액 왕관 +1») · 강화 버튼 꺼짐 %s(참) · 툴팁 «%s»(«다 씀») · 골드 %d(940)" % [row[2].text, row[3].disabled, tip, b.gold]
	row[4].pressed.emit()
	_frame(main)
	var second := [b.roster[0].relic, b.roster[1].relic, names[1] in row[2].text]
	row[4].pressed.emit()
	_frame(main)
	var third := [b.roster.all(func(h): return h.relic == ""), "아무도 안 낌" in row[2].text]
	_done(main)
	return check(second == ["", CROWN, true] and third == [true, true],
		"영웅 바꾸기 한 번 뒤 [첫째 relic, 둘째 relic, 글에 둘째 이름] %s(기대 [\"\", slime_crown, 참]) · 두 번 뒤 [아무도 안 낌, 글에 «아무도 안 낌»] %s(기대 [참, 참])" % [second, third])

# 토스트를 0.5초씩 20번 돌리는 동안 보인 토스트 글들
func _toast_texts(main) -> Array:
	var seen := []
	for i in 20:
		main.hud._process(0.0)
		main.hud.toasts._process(0.5)
		for t in _labels(main.hud.toasts):
			if t not in seen:
				seen.append(t)
	return seen

# EV963 · S333·I278 ⑥: 처치로 돌아오면 유물 이름과 층 골드가 든 토스트가 뜬다. 철수로는 뜨지 않는다
func ev963():
	var main = _den_game()
	var b = main.view.battle
	b.start_raid()
	_frame(main)
	_slay(b)
	_spin(main, 3.1)
	var state: String = b.state
	var texts := _toast_texts(main)
	_done(main)
	if state != "prep" or not texts.any(func(t): return "점액 왕관" in t and "120" in t):
		return "처치 뒤 판 %s(prep) · 보인 토스트 %s(«점액 왕관»과 «120»이 함께 든 것이 있어야)" % [state, texts]
	main = _den_game()
	b = main.view.battle
	b.start_raid()
	_frame(main)
	b.retreat()
	_frame(main)
	texts = _toast_texts(main)
	_done(main)
	return check(not texts.any(func(t): return "점액 왕관" in t), "철수 뒤 보인 토스트 %s(«점액 왕관»이 없어야)" % [texts])

# ── 2층 알파 늑대(S337·I280) ── 더하는 API:
#   FloorDef.walks(거짓이면 걷지도 기본 공격도 하지 않는다) · 층 정의 floor_2 · Battle.raid_frenzy() -> int(원정 보스 몸의 광분 수)
#   돌진 예고의 cast {dir, to, aimed(벽 돌진이면 참)} · 덮치기 예고의 cast.who(사냥감) · Enemy.grief(광분 수) · Enemy.grip(붙잡은 영웅 {who, …}, 없으면 null)
#   main.hud._boss_name — 보스 막대의 이름 글

# 3라운드 첫 준비 단계(횃불 4)에서 1층을 깬 것으로 둔 시험 스테이지 판
func _den2(team := TEAM):
	var b = _den(team)
	b.state = "cleared"
	b.next_round()
	b.floors_cleared = 1
	return b

# 2층 원정을 시작해 원정대를 멈추고 알파의 서 있기를 0으로, 대본 쉼을 아주 길게 둔다. 알파(하나뿐인 적)를 돌려주고, 아니면 null
func _alpha(b):
	b.start_raid()
	if b.state != "raid" or b.enemies.size() != 1 or b.enemies[0].kind != "alpha_wolf" or b.enemies[0].get("rest") == null:
		return null
	_freeze(b)
	var e = b.enemies[0]
	e.pull = 0.0
	e.rest = 999.0
	return e

# 원정대 셋을 자리 at(출전 차례)에 둔다
func _stand(b, at: Array) -> void:
	for i in at.size():
		b.party[i].pos = at[i]

# 대본 차례 beat의 예고를 한 스텝 뒤에 띄운다. 띄운 예고를 돌려준다
func _tell(b, e, beat: int):
	e.cast = null
	e.beat = beat
	e.rest = 0.0
	b.step(DT)
	return e.cast

# 사냥감 자리(출전 차례): 둘째 영웅(이그니스)이 알파 (84,80)에서 가장 먼 남쪽 (84,85)다.
# 첫째 영웅(아이아스)은 맞을 때마다 50% 확률로 피해를 반만 받아(S151) 피해를 재는 사냥감으로 쓰지 않는다
const HUNT := [Vector2(82, 81), Vector2(84, 85), Vector2(86, 81)]

# 알파 (84,80), 둘째 영웅을 가장 먼 (84,85)에 두고 덮치기로 붙잡게 한다. [판, 알파, 붙잡힌 영웅]이고 안 되면 []
func _pinned() -> Array:
	var b = _den2()
	var e = _alpha(b)
	if e == null:
		return []
	_stand(b, HUNT)
	_tell(b, e, 1)
	_go(b, 2.6)
	if e.get("grip") == null or not is_same(e.grip.who, b.party[1]) or not is_same(b._fx_on(b.party[1], "pin"), e):
		return []
	return [b, e, b.party[1]]

# EV971 · S337: 2층 층 정의의 수치와 층 차례. 1층은 걷는 층 기본값 그대로이고 디펜스 알파 늑대 종류도 그대로다
func ev971():
	var f = load("res://data/dungeon/floor_2.tres")
	var sk: Dictionary = f.skills
	if f.title != "알파 늑대" or f.opens != 3 or f.kind != "alpha_wolf" or f.stats.get("hp") != 1600.0 or f.stats.get("radius") != 0.9 or f.get("walks") != false or not f.gens.is_empty():
		return "이름 %s · 열림 %s · 종류 %s · 체력 %s · 몸 반지름 %s · walks %s · 세대 %s(기대 알파 늑대·3·alpha_wolf·1600·0.9·거짓·없음)" % [f.title, f.opens, f.kind, f.stats.get("hp"), f.stats.get("radius"), f.get("walks"), f.gens]
	if f.plan != [{"id": "charge", "wait": 4.0}, {"id": "pounce", "wait": 5.0}, {"id": "charge", "wait": 4.0}, {"id": "brand", "wait": 5.0}]:
		return "대본 %s(기대 돌진 4 → 덮치기 5 → 돌진 4 → 표식 5)" % [f.plan]
	var charge := {"length": 8.0, "width": 1.0, "side": 1.0, "windup": 1.6, "unit": 30.0}
	var pounce := {"windup": 2.0, "counter": 0.8, "air": 0.4, "damage": 25.0, "pin_time": 4.0, "bite": 8.0, "break_dmg": 5.0, "color": "blue"}
	var brand := {"radius": 2.0, "windup": 3.0, "damage": 30.0, "color": "violet"}
	if sk.get("charge") != charge or sk.get("pounce") != pounce or sk.get("brand") != brand or sk.get("frenzy") != {"damage": 0.25, "cap": 3}:
		return "돌진 %s · 덮치기 %s · 표식 %s · 광분 %s" % [sk.get("charge"), sk.get("pounce"), sk.get("brand"), sk.get("frenzy")]
	if f.ward != 0.88 or f.groggy != {"time": 5.0, "mult": 1.5} or f.enrage != {"soft": 80.0, "step": 10.0, "ramp": 0.15} or f.hard != 120.0 or f.gold != 150 or f.relic != "":
		return "경감 %s · 그로기 %s · 광폭 %s · 불꽃 %s · 층 골드 %s · 유물 «%s»(기대 0.88·5초 1.5배·80초 10초 0.15·120·150·없음)" % [f.ward, f.groggy, f.enrage, f.hard, f.gold, f.relic]
	var wolf = load("res://data/enemies/alpha_wolf.tres")
	return check(_stage().den.floors == ["floor_1", "floor_2", "floor_3"] and load("res://data/dungeon/floor_1.tres").get("walks") == true
		and wolf.hp == 160.0 and wolf.radius == 0.45 and wolf.skills.pounce.break_dmg == 40.0 and wolf.skills.frenzy == {"damage": 0.25},
		"층 차례 %s(기대 floor_1·floor_2·floor_3) · 1층 walks %s(참) · 디펜스 알파 체력 %s·몸 %s·break_dmg %s·광분 %s(기대 160·0.45·40·{damage 0.25})" % [_stage().den.floors, load("res://data/dungeon/floor_1.tres").get("walks"), wolf.hp, wolf.radius, wolf.skills.pounce.break_dmg, wolf.skills.frenzy])

# EV972 · S337·I280 ①: 2층은 3라운드부터 열리고 알파 하나가 층 수치로 나온다. 알파는 걷지도 기본 공격도 하지 않는다
func ev972():
	var a = _den()
	a.floors_cleared = 1
	var early: String = a.raid_block()
	var b = _den2()
	var why: String = b.raid_block()
	var torches: int = b.torches
	var e = _alpha(b)
	if early != "round" or why != "" or e == null:
		return "2라운드 이유 %s(round) · 3라운드 이유 «%s»(없음) · 원정 %s · 적 %d(알파 하나)" % [early, why, b.state, b.enemies.size()]
	if e.pos != Vector2(BOSS) or e.hp != 1600.0 or e.max_hp != 1600.0 or e.radius != 0.9 or e.reward != 0 or e.xp != 0 or e.raid.get("title") != "알파 늑대" or b.raid_left() != 1.0 or b.torches != torches - 1:
		return "자리 %s · 체력 %s/%s · 몸 %s · 보상 %s·%s · 층 %s · 남은 비율 %s · 횃불 %d(기대 (84,80)·1600·0.9·0·0·알파 늑대·1·%d)" % [e.pos, e.hp, e.max_hp, e.radius, e.reward, e.xp, e.raid.get("title"), b.raid_left(), b.torches, torches - 1]
	var u = b.party[0]
	u.pos = Vector2(84, 82)
	var hp: float = u.hp
	_go(b, 6.0)
	return check(e.pos == Vector2(BOSS) and u.hp == hp and e.cast == null, "6초 뒤 알파 자리 %s((84,80)) · 2칸 옆 영웅 체력 %s → %s · 예고 %s(없음)" % [e.pos, hp, u.hp, e.cast])

# EV973 · S337·I280 ②: 사냥감은 가장 먼 산 원정대 영웅이고, 거리가 같으면 출전 차례가 앞선 쪽, 도발했으면 도발한 영웅이다. 덮치기도 같은 사냥감을 노린다
func ev973():
	var b = _den2()
	var e = _alpha(b)
	if e == null:
		return "2층 원정이 되지 않았다"
	var got := []
	_stand(b, [Vector2(86, 80), Vector2(84, 84), Vector2(78, 80)])
	got.append(_tell(b, e, 0))
	var pounce = _tell(b, e, 1)
	b.damage(b.party[2], BIG)
	got.append(_tell(b, e, 0))
	b._return_hero(b.party[2], true)
	_stand(b, [Vector2(88, 80), Vector2(80, 80), Vector2(84, 82)])
	got.append(_tell(b, e, 0))
	b._fx(e, "t", {"taunt": b.party[2]}, 5.0)
	got.append(_tell(b, e, 0))
	if got.any(func(c): return c == null or c.id != "charge" or not c.has("dir")) or pounce == null or pounce.id != "pounce":
		return "예고 %s · 덮치기 %s" % [got, pounce]
	var dirs: Array = got.map(func(c): return Vector2.from_angle(c.dir).round())
	return check(dirs == [Vector2(-1, 0), Vector2(0, 1), Vector2(1, 0), Vector2(0, 1)] and is_same(pounce.who, b.party[2]),
		"돌진 방향 [가장 먼 셋째, 셋째가 쓰러짐, 같은 거리, 도발] %s(기대 서·남·동·남) · 덮치기 대상이 셋째 %s" % [dirs, is_same(pounce.who, b.party[2])])

# EV974 · S337 ①: 벽 돌진을 모두 피하면 알파가 벽 앞에서 멈춰 그로기가 된다
func ev974():
	var b = _den2()
	var e = _alpha(b)
	if e == null:
		return "2층 원정이 되지 않았다"
	_stand(b, HUNT)
	var c = _tell(b, e, 0)
	if c == null or c.id != "charge" or c.get("aimed") != true or absf(c.left - 1.6) > 0.051 or c.to.distance_to(Vector2(84, 87.25)) > 0.01:
		return "예고 %s(기대 charge·벽 돌진·남은 1.6초·끝 (84,87.25))" % [c]
	b.party[1].pos = Vector2(86, 85)
	var hp: Array = b.party.map(func(h): return h.hp)
	_go(b, 1.5)
	var before := [e.pos, e.cast != null]
	_go(b, 0.2)
	if before != [Vector2(BOSS), true] or e.pos.distance_to(Vector2(84, 87.25)) > 0.01 or not _groggy(b, e) or e.cast != null or b.party.map(func(h): return h.hp) != hp or e.beat != 1:
		return "1.5초 [자리, 예고 중] %s(기대 (84,80)·참) · 1.7초 자리 %s((84,87.25)) · 그로기 %s(참) · 예고 %s(없음) · 영웅 체력 %s → %s · 대본 차례 %s(1)" % [before, e.pos, _groggy(b, e), e.cast, hp, b.party.map(func(h): return h.hp), e.beat]
	_go(b, 4.7)
	var late: bool = _groggy(b, e)
	_go(b, 0.4)
	return check(late and not _groggy(b, e), "그로기가 4.7초 뒤 %s(참) · 5.1초 뒤 %s(거짓)" % [late, _groggy(b, e)])

# EV975 · S337 ①: 벽 돌진에 맞으면 피해 30과 옆으로 1칸 밀림이고 그로기가 없다. 이동 돌진은 아무도 못 맞혀도 그로기가 없다
func ev975():
	var b = _den2()
	var e = _alpha(b)
	if e == null:
		return "2층 원정이 되지 않았다"
	_stand(b, HUNT)
	var u = b.party[1]
	_tell(b, e, 0)
	var want: float = _take(b, u, 30.0)
	var hp: float = u.hp
	var others := [b.party[0].hp, b.party[2].hp]
	_go(b, 1.7)
	if absf(hp - u.hp - want) > 0.01 or absf(absf(u.pos.x - 84.0) - 1.0) > 0.01 or absf(u.pos.y - 85.0) > 0.01 or e.pos.distance_to(Vector2(84, 87.25)) > 0.01 or _groggy(b, e) or [b.party[0].hp, b.party[2].hp] != others:
		return "① 잃은 체력 %s(기대 %s) · 맞은 영웅 자리 %s(옆으로 1칸: (83,85)나 (85,85)) · 알파 %s((84,87.25)) · 그로기 %s(거짓) · 길 밖 둘 %s → %s" % [hp - u.hp, want, u.pos, e.pos, _groggy(b, e), others, [b.party[0].hp, b.party[2].hp]]
	var k = _den2()
	var w = _alpha(k)
	if w == null:
		return "② 2층 원정이 되지 않았다"
	_stand(k, [Vector2(88, 80), Vector2(83, 81), Vector2(85, 81)])
	var c = _tell(k, w, 0)
	if c == null or c.get("aimed") != false or c.to.distance_to(Vector2(92, 80)) > 0.01:
		return "② 예고 %s(기대 이동 돌진·끝 (92,80))" % [c]
	k.party[0].pos = Vector2(88, 83)
	var all: Array = k.party.map(func(h): return h.hp)
	_go(k, 1.7)
	return check(w.pos.distance_to(Vector2(92, 80)) < 0.01 and not _groggy(k, w) and k.party.map(func(h): return h.hp) == all and w.cast == null,
		"② 이동 돌진 뒤 알파 %s((92,80)) · 그로기 %s(거짓) · 영웅 체력 %s → %s" % [w.pos, _groggy(k, w), all, k.party.map(func(h): return h.hp)])

# EV976 · S337 ②③·I280 ④⑤: 덮치기는 뛴 뒤 대시로 벗어나도 붙잡고 초당 8로 문다. 붙잡은 동안 경감 뒤 피해 합이 5를 넘으면 놓고 그로기가 된다
func ev976():
	var b = _den2()
	var e = _alpha(b)
	if e == null:
		return "2층 원정이 되지 않았다"
	_stand(b, HUNT)
	var u = b.party[1]
	var c = _tell(b, e, 1)
	if c == null or c.id != "pounce" or not is_same(c.who, u) or absf(c.left - 2.0) > 0.051:
		return "예고 %s(기대 pounce·둘째 영웅·남은 2초)" % [c]
	var hp: float = u.hp
	_go(b, 2.1)
	if e.cast == null or not e.cast.get("air", false) or u.hp != hp:
		return "2.1초 뒤 예고 %s(뜬 덮치기) · 영웅 체력 %s → %s(그대로)" % [e.cast, hp, u.hp]
	b.dash([u], Vector2(95, 85))
	var dashed: Vector2 = u.pos
	_go(b, 0.5)
	var gap: float = e.pos.distance_to(u.pos)
	if dashed.distance_to(Vector2(86, 85)) > 0.01 or not is_same(b._fx_on(u, "pin"), e) or e.get("grip") == null or absf(gap - (0.9 + u.radius)) > 0.3 or hp - u.hp < _take(b, u, 25.0) - 0.01:
		return "대시한 자리 %s((86,85)) · 붙잡힘 %s(참) · 알파와의 거리 %.2f(몸 반지름 합 %.2f에서 0.3 안) · 잃은 체력 %s(착지 %s 이상)" % [dashed, is_same(b._fx_on(u, "pin"), e), gap, 0.9 + u.radius, hp - u.hp, _take(b, u, 25.0)]
	var at: Vector2 = u.pos
	hp = u.hp
	_go(b, 1.0)
	if absf(hp - u.hp - _take(b, u, 8.0)) > 0.05 or u.pos != at or _groggy(b, e):
		return "붙잡힌 1초에 잃은 체력 %s(기대 %s) · 자리 %s → %s · 그로기 %s(거짓)" % [hp - u.hp, _take(b, u, 8.0), at, u.pos, _groggy(b, e)]
	b.damage(e, 40.0)
	b.step(DT)
	var held := [is_same(b._fx_on(u, "pin"), e), _groggy(b, e)]
	b.damage(e, 2.0)
	b.step(DT)
	return check(held == [true, false] and b._fx_on(u, "pin") == null and e.grip == null and _groggy(b, e) and e.grief == 0,
		"피해 40(경감 뒤 4.8) 뒤 [붙잡힘, 그로기] %s(기대 [참, 거짓]) · 2 더(합 5.04) 뒤 붙잡힘 %s(없음) · 그로기 %s(참) · 광분 %s(0)" % [held, b._fx_on(u, "pin"), _groggy(b, e), e.grief])

# EV977 · S337 ③·I280 ⑤: 붙잡힘을 정화로 풀거나 알파에게 기절을 걸려 하면 알파가 놓고 그로기가 된다. 기절은 걸리지 않는다
func ev977():
	var p := _pinned()
	if p.is_empty():
		return "① 덮치기로 붙잡지 못했다"
	var b = p[0]
	var e = p[1]
	var u = p[2]
	var sera = b.party[2]
	sera.pos = u.pos + Vector2(2, 0)
	sera.cd.w = 0.0
	var cast: bool = b.cast(sera, "w", u.pos)
	_go(b, 0.2)
	if not cast or b._fx_on(u, "pin") != null or e.grip != null or not _groggy(b, e) or e.grief != 0:
		return "① 성역을 썼나 %s · 붙잡힘 %s(없음) · 알파가 붙잡은 영웅 %s(없음) · 그로기 %s(참) · 광분 %s(0)" % [cast, b._fx_on(u, "pin"), e.grip, _groggy(b, e), e.grief]
	p = _pinned()
	if p.is_empty():
		return "② 덮치기로 붙잡지 못했다"
	b = p[0]
	e = p[1]
	u = p[2]
	b._fx(e, "t", {"stun": true}, 2.0)
	return check(b._fx_on(u, "pin") == null and e.grip == null and _groggy(b, e) and b._fx_on(e, "stun") == null and b.effect(e, "deflect") == null and e.grief == 0,
		"② 기절을 걸려 한 뒤 붙잡힘 %s(없음) · 알파가 붙잡은 영웅 %s(없음) · 그로기 %s(참) · 기절 %s(없음) · 튕김 %s(없음) · 광분 %s(0)" % [b._fx_on(u, "pin"), e.grip, _groggy(b, e), b._fx_on(e, "stun"), b.effect(e, "deflect"), e.grief])

# EV978 · S337 ③④: 4초가 다 되거나 붙잡힌 영웅이 쓰러지면 그로기 없이 광분이 하나 쌓인다. 광분 하나마다 피해가 25% 늘고 3을 넘지 않는다
func ev978():
	var p := _pinned()
	if p.is_empty():
		return "① 덮치기로 붙잡지 못했다"
	var b = p[0]
	var e = p[1]
	var u = p[2]
	_go(b, 3.2)
	var mid := [is_same(b._fx_on(u, "pin"), e), e.grief]
	_go(b, 0.8)
	if mid != [true, 0] or b._fx_on(u, "pin") != null or e.grip != null or _groggy(b, e) or e.grief != 1 or b.raid_frenzy() != 1 or not u.alive:
		return "① 붙잡고 3.5초 안 [붙잡힘, 광분] %s(기대 [참, 0]) · 4.2초 넘어 붙잡힘 %s(없음) · 그로기 %s(거짓) · 광분 %s·%s(1·1) · 영웅 살았나 %s" % [mid, b._fx_on(u, "pin"), _groggy(b, e), e.grief, b.raid_frenzy(), u.alive]
	e.pos = Vector2(BOSS)
	_stand(b, HUNT)
	_tell(b, e, 0)
	var want: float = _take(b, u, 30.0 * 1.25)
	var hp: float = u.hp
	_go(b, 1.7)
	if absf(hp - u.hp - want) > 0.01:
		return "① 광분 1의 돌진에 잃은 체력 %s(기대 %s = 30 × 1.25)" % [hp - u.hp, want]
	e.grief = 3
	e.pos = Vector2(BOSS)
	u.hp = u.max_hp
	_stand(b, HUNT)
	_tell(b, e, 1)
	_go(b, 2.6)
	var again: bool = is_same(b._fx_on(u, "pin"), e)
	_go(b, 4.2)
	if not again or b._fx_on(u, "pin") != null or e.grief != 3:
		return "① 광분 3에서 다시 붙잡았나 %s · 4초 뒤 붙잡힘 %s(없음) · 광분 %s(3 그대로)" % [again, b._fx_on(u, "pin"), e.grief]
	p = _pinned()
	if p.is_empty():
		return "② 덮치기로 붙잡지 못했다"
	b = p[0]
	e = p[1]
	b.damage(p[2], BIG)
	b.step(DT)
	return check(e.grip == null and not _groggy(b, e) and e.grief == 1, "② 붙잡힌 영웅이 쓰러진 뒤 알파가 붙잡은 영웅 %s(없음) · 그로기 %s(거짓) · 광분 %s(1)" % [e.grip, _groggy(b, e), e.grief])

# EV979 · S337 ②·I280 ④: 덮치기 예고의 마지막 0.8초에 기절을 걸려 하면 예고가 끊기고 그로기가 된다. 그 앞에서는 튕기고, 뜬 동안은 카운터 창이 아니다
func ev979():
	var b = _den2()
	var e = _alpha(b)
	if e == null:
		return "2층 원정이 되지 않았다"
	_stand(b, HUNT)
	var u = b.party[1]
	_tell(b, e, 1)
	_go(b, 1.0)
	var open: bool = b.countering(e)
	b._fx(e, "t1", {"stun": true}, 2.0)
	var early := [e.cast != null and e.cast.id == "pounce", _groggy(b, e), b.effect(e, "deflect") != null]
	_go(b, 0.4)
	var window: bool = b.countering(e)
	b._fx(e, "t2", {"stun": true}, 2.0)
	var late := [e.cast, _groggy(b, e), b._fx_on(e, "stun"), e.beat]
	var hp: float = u.hp
	_go(b, 1.5)
	if open or early != [true, false, true] or not window or late != [null, true, null, 2] or u.hp != hp or b._fx_on(u, "pin") != null:
		return "① 1.0초 카운터 창 %s(거짓) · 그때 기절 뒤 [예고 있음, 그로기, 튕김] %s(기대 [참, 거짓, 참]) · 1.4초 카운터 창 %s(참) · 그때 기절 뒤 [예고, 그로기, 기절, 대본 차례] %s(기대 [null, 참, null, 2]) · 영웅 체력 %s → %s · 붙잡힘 %s(없음)" % [open, early, window, late, hp, u.hp, b._fx_on(u, "pin")]
	var k = _den2()
	var w = _alpha(k)
	if w == null:
		return "② 2층 원정이 되지 않았다"
	_stand(k, HUNT)
	_tell(k, w, 1)
	_go(k, 2.15)
	var aloft: bool = w.cast != null and w.cast.get("air", false)
	var counted: bool = k.countering(w)
	k._fx(w, "t", {"stun": true}, 2.0)
	_go(k, 0.5)
	return check(aloft and not counted and is_same(k._fx_on(k.party[1], "pin"), w) and not _groggy(k, w),
		"② 2.15초에 뜬 중 %s(참) · 카운터 창 %s(거짓) · 기절을 걸려 한 뒤 붙잡힘 %s(참) · 그로기 %s(거짓)" % [aloft, counted, is_same(k._fx_on(k.party[1], "pin"), w), _groggy(k, w)])

# EV980 · S337 ⑤·I280 ⑦: 대본은 돌진 → 덮치기 → 돌진 → 표식을 쉼 4·5·4·5초로 돌고, 쉼은 붙잡은 동안 줄지 않는다. 표식은 출전 차례의 영웅을 따라다니다 원 안 모두에게 30을 준다
func ev980():
	var b = _den2()
	b.start_raid()
	if b.state != "raid" or b.enemies.size() != 1:
		return "2층 원정이 되지 않았다"
	_freeze(b)
	var e = b.enemies[0]
	var got: Array = _casts(b, [e], 39.0)
	var starts: Array = got[0]
	var ends: Array = got[1]
	var ids: Array = starts.map(func(s): return s[1])
	if ids != ["charge", "pounce", "charge", "brand", "charge"] or ends.size() < 4:
		return "예고 차례 %s(기대 돌진·덮치기·돌진·표식·돌진) · 끝난 예고 %d(4 이상)" % [ids, ends.size()]
	var gaps := [starts[0][0]]
	for i in range(1, 5):
		gaps.append(starts[i][0] - ends[i - 1])
	var want := [7.0, 5.0, 8.0, 5.0, 4.0]
	if range(5).any(func(i): return absf(gaps[i] - want[i]) > 0.2):
		return "첫 예고까지와 앞 예고가 끝난 때부터 다음 예고까지 %s(기대 %s, 0.2초 안: 서 있기 3 + 쉼 4 · 쉼 5 · 붙잡은 4 + 쉼 4 · 쉼 5 · 쉼 4)" % [gaps, want]
	var k = _den2()
	var w = _alpha(k)
	if w == null:
		return "② 2층 원정이 되지 않았다"
	_stand(k, [Vector2(88, 84), Vector2(80, 84), Vector2(81, 84)])
	w.turn = 1
	var c = _tell(k, w, 3)
	if c == null or c.id != "brand" or not is_same(c.get("mark"), k.party[1]) or absf(c.left - 3.0) > 0.051:
		return "② 예고 %s(기대 brand·둘째 영웅·남은 3초)" % [c]
	_go(k, 1.0)
	k.party[1].pos = Vector2(80, 80)
	k.party[2].pos = Vector2(81, 80)
	var hp: Array = k.party.map(func(h): return h.hp)
	k.step(DT)
	var follows: bool = w.cast != null and w.cast.at == Vector2(80, 80)
	_go(k, 2.2)
	var lost: Array = [hp[0] - k.party[0].hp, hp[1] - k.party[1].hp, hp[2] - k.party[2].hp]
	return check(follows and lost[0] == 0.0 and absf(lost[1] - _take(k, k.party[1], 30.0)) < 0.01 and absf(lost[2] - _take(k, k.party[2], 30.0)) < 0.01 and not _groggy(k, w) and w.cast == null,
		"② 원이 표식 영웅을 따라갔나 %s · 잃은 체력 %s(기대 0·%s·%s) · 그로기 %s(거짓)" % [follows, lost, _take(k, k.party[1], 30.0), _take(k, k.party[2], 30.0), _groggy(k, w)])

# EV981 · S337·I280 ①⑨: 보스 막대의 이름과 «광분 n», 그림 2배. 처치하면 깬 층 2·층 골드 150이고 유물 없는 층의 토스트가 뜬다
func ev981():
	var main = _den_game()
	var b = main.view.battle
	b.state = "cleared"
	b.next_round()
	b.floors_cleared = 1
	_frame(main)
	_toast_texts(main)
	b.start_raid()
	_frame(main)
	if b.state != "raid" or b.enemies.size() != 1 or b.enemies[0].kind != "alpha_wolf":
		_done(main)
		return "2층 원정이 되지 않았다(판 %s · 적 %d)" % [b.state, b.enemies.size()]
	var e = b.enemies[0]
	var calm: String = main.hud._boss_name.text
	var scale: float = main.view._shrunk(e)
	e.grief = 2
	_frame(main)
	var mad: String = main.hud._boss_name.text
	var gold: int = b.gold
	b.damage(e, BIG)
	_spin(main, 3.1)
	var after := [b.state, b.floors_cleared, b.gold - gold, b.relics, b.raid_block()]
	var texts := _toast_texts(main)
	_done(main)
	if calm != "알파 늑대" or not is_equal_approx(scale, 2.0) or not ("알파 늑대" in mad and "광분 2" in mad):
		return "보스 막대 이름 «%s»(알파 늑대) · 그림 배율 %s(2) · 광분 2일 때 «%s»(«알파 늑대»와 «광분 2»가 있어야)" % [calm, scale, mad]
	return check(after == ["prep", 2, 150, {}, "round"] and texts.any(func(t): return "2층" in t and "150" in t),
		"처치 3.1초 뒤 [판, 깬 층, 는 골드, 가방, 원정 버튼 이유] %s(기대 [prep, 2, 150, {}, round]) · 보인 토스트 %s(«2층»과 «150»이 함께 든 것이 있어야)" % [after, texts])

# ── 원정 3층 «전쟁 기계 → 고블린 대장»(S342·I283) ── 더하는 API:
#   층 정의 floor_3 · FloorDef.phase2({title, kind, scale, stats, skills, plan}: 체력이 0이 되면 바뀔 둘째 형태)·scale(몸 그림 배율, 0이면 I280 ①)·wreck(수레 잔해 원의 반지름)
#   대포 예고의 cast {mark(사냥감), at(원 자리), aimed(굳을 때 원이 기계 몸에 닿았나. 굳기 전에는 없다)} · 기관총 예고의 cast {dir, fire(발사 단계면 참)}
#   도약 예고의 cast {at(착지 자리), aimed(겨눈 뜀이면 참), air(뜬 동안 참)} · 철퇴 예고의 cast.dir · 폭탄 예고의 cast.spots
#   Battle.wrecks — 수레 잔해 [{at, …}] · Battle.raid_title() -> String(지금 형태의 이름)

# 4라운드 첫 준비 단계(횃불 4)에서 2층까지 깬 것으로 둔 시험 스테이지 판
func _den3(team := TEAM):
	var b = _den2(team)
	b.state = "cleared"
	b.next_round()
	b.floors_cleared = 2
	return b

# 3층 원정을 시작해 원정대를 멈추고 기계의 서 있기를 0으로, 대본 쉼을 아주 길게 둔다. 기계(하나뿐인 적)를 돌려주고, 아니면 null
func _machine(b):
	b.start_raid()
	if b.state != "raid" or b.enemies.size() != 1 or b.enemies[0].kind != "war_machine" or b.enemies[0].get("rest") == null:
		return null
	_freeze(b)
	var e = b.enemies[0]
	e.pull = 0.0
	e.rest = 999.0
	return e

# 3층 원정에서 기계를 부숴 대장으로 바꾸고 대본 쉼을 아주 길게 둔다. 대장(같은 적)을 돌려주고, 아니면 null
func _chief(b):
	var e = _machine(b)
	if e == null:
		return null
	b.damage(e, BIG)
	if e.kind != "chief" or not e.alive:
		return null
	e.cast = null
	e.rest = 999.0
	return e

# 예고가 끝날 때까지 돌린다(많아야 10초)
func _resolve(b, e) -> void:
	var n := 0
	while e.cast != null and n < 200:
		b.step(DT)
		n += 1

const FAR3 := [Vector2(80, 76), Vector2(84, 86), Vector2(88, 76)]  # 둘째 영웅(이그니스)이 기계 (84,80)에서 가장 먼 남쪽 (84,86)이다

# EV994 · S342: 3층 층 정의의 수치와 층 차례. 디펜스 전쟁 기계·대장 종류는 그대로다
func ev994():
	var f = load("res://data/dungeon/floor_3.tres")
	if f.title != "전쟁 기계" or f.opens != 4 or f.kind != "war_machine" or f.stats != {"hp": 1000.0, "armor": 8.0, "radius": 1.4, "reward": 0, "xp": 0} or f.get("walks") != false or not f.gens.is_empty() or f.get("wreck") != 1.4 or f.get("scale") != 1.0:
		return "이름 %s · 열림 %s · 종류 %s · 수치 %s · walks %s · 세대 %s · 잔해 %s · 그림 배율 %s(기대 전쟁 기계·4·war_machine·체력 1000 방어력 8 몸 1.4 보상 0·거짓·없음·1.4·1)" % [f.title, f.opens, f.kind, f.stats, f.get("walks"), f.gens, f.get("wreck"), f.get("scale")]
	var sk: Dictionary = f.skills
	var cannon := {"windup": 4.0, "lock": 1.0, "radius": 1.5, "unit": 30.0, "knock": 1.0, "color": "violet"}
	var mgun := {"windup": 1.4, "fire": 2.0, "tick": 0.25, "range": 5.0, "arc": 120.0, "spread": 15.0, "unit": 8.0}
	var slam := {"windup": 2.5, "radius": 3.0, "damage": 30.0, "knock": 1.5, "color": "blue", "counter": 1.0}
	if sk.get("cannon") != cannon or sk.get("mgun") != mgun or sk.get("slam") != slam or sk.size() != 3:
		return "1형 스킬: 대포 %s · 기관총 %s · 증기 배출 %s · 수 %d(셋)" % [sk.get("cannon"), sk.get("mgun"), sk.get("slam"), sk.size()]
	if f.plan != [{"id": "cannon", "wait": 5.0}, {"id": "mgun", "wait": 4.0}, {"id": "cannon", "wait": 5.0}, {"id": "slam", "wait": 5.0}]:
		return "1형 대본 %s(기대 대포 5 → 기관총 4 → 대포 5 → 증기 배출 5)" % [f.plan]
	var p: Dictionary = f.get("phase2")
	if p.get("title") != "고블린 대장" or p.get("kind") != "chief" or p.get("scale") != 1.0 or p.get("stats") != {"hp": 1000.0, "armor": 10.0, "radius": 1.5, "reward": 0, "xp": 0}:
		return "2형 이름 %s · 종류 %s · 그림 배율 %s · 수치 %s(기대 고블린 대장·chief·1·체력 1000 방어력 10 몸 1.5 보상 0)" % [p.get("title"), p.get("kind"), p.get("scale"), p.get("stats")]
	var want := {
		"leap": {"windup": 1.5, "air": 0.6, "range": 8.0, "radius": 2.5, "damage": 30.0, "knock": 1.5},
		"cleave": {"windup": 1.4, "range": 3.5, "arc": 120.0, "unit": 40.0, "knock": 1.5},
		"charge": {"windup": 1.4, "length": 8.0, "width": 1.0, "side": 1.0, "unit": 30.0, "run": 2.0},
		"bombs": {"windup": 1.6, "count": 3, "gap": 1.5, "radius": 1.2, "unit": 25.0},
		"soak": {"windup": 4.5, "radius": 1.5, "far": 5.0, "turn": 90.0, "damage": 90.0, "need": 3, "miss": 30.0, "heal": 0.05, "color": "gold", "counter": 1.0},
	}
	var got: Dictionary = p.get("skills", {})
	for id in want:
		if got.get(id) != want[id]:
			return "2형 %s %s(기대 %s)" % [id, got.get(id), want[id]]
	if got.size() != 5 or p.get("plan") != [{"id": "leap", "wait": 4.0}, {"id": "cleave", "wait": 2.0}, {"id": "charge", "wait": 4.0}, {"id": "bombs", "wait": 4.0}, {"id": "soak", "wait": 5.0}]:
		return "2형 스킬 수 %d(다섯) · 대본 %s(기대 도약 4 → 철퇴 2 → 돌진 4 → 폭탄 4 → 금색 원 5)" % [got.size(), p.get("plan")]
	if f.ward != 0.89 or f.groggy != {"time": 5.0, "mult": 1.5} or f.enrage != {"soft": 100.0, "step": 10.0, "ramp": 0.15} or f.hard != 150.0 or f.gold != 180 or f.relic != "":
		return "경감 %s · 그로기 %s · 광폭 %s · 불꽃 %s · 층 골드 %s · 유물 «%s»(기대 0.89·5초 1.5배·100초 10초 0.15·150·180·없음)" % [f.ward, f.groggy, f.enrage, f.hard, f.gold, f.relic]
	var machine = load("res://data/enemies/war_machine.tres")
	var chief = load("res://data/enemies/chief.tres")
	return check(_stage().den.floors == ["floor_1", "floor_2", "floor_3"] and machine.hp == 200.0 and machine.radius == 0.7 and machine.armor == 15.0 and machine.phase2 == "chief"
		and machine.skills.cannon.windup == 1.2 and chief.hp == 200.0 and chief.radius == 0.9 and chief.armor == 10.0 and chief.skills.charge.length == 6.0 and not chief.skills.leap.has("windup"),
		"층 차례 %s(기대 floor_1·floor_2·floor_3) · 디펜스 기계 체력 %s·몸 %s·방어력 %s·둘째 형태 %s·대포 예고 %s(200·0.7·15·chief·1.2) · 디펜스 대장 체력 %s·몸 %s·방어력 %s·돌진 길이 %s(200·0.9·10·6)" % [_stage().den.floors, machine.hp, machine.radius, machine.armor, machine.phase2, machine.skills.cannon.windup, chief.hp, chief.radius, chief.armor, chief.skills.charge.length])

# EV995 · S342: 3층은 4라운드부터 열리고 기계 하나가 층 수치로 나온다. 기계는 걷지도 기본 공격도 하지 않는다
func ev995():
	var a = _den2()
	a.floors_cleared = 2
	var early: String = a.raid_block()
	var b = _den3()
	var why: String = b.raid_block()
	var torches: int = b.torches
	var e = _machine(b)
	if early != "round" or why != "" or e == null:
		return "3라운드 이유 %s(round) · 4라운드 이유 «%s»(없음) · 원정 %s · 적 %d(기계 하나)" % [early, why, b.state, b.enemies.size()]
	if e.pos != Vector2(BOSS) or e.hp != 1000.0 or e.max_hp != 1000.0 or e.radius != 1.4 or e.armor != 8.0 or e.reward != 0 or e.xp != 0 or e.raid.get("title") != "전쟁 기계" or b.raid_left() != 1.0 or b.torches != torches - 1:
		return "자리 %s · 체력 %s/%s · 몸 %s · 방어력 %s · 보상 %s·%s · 층 %s · 남은 비율 %s · 횃불 %d(기대 (84,80)·1000·1.4·8·0·0·전쟁 기계·1·%d)" % [e.pos, e.hp, e.max_hp, e.radius, e.armor, e.reward, e.xp, e.raid.get("title"), b.raid_left(), b.torches, torches - 1]
	var u = b.party[1]
	u.pos = Vector2(84, 82)
	var hp: float = u.hp
	_go(b, 6.0)
	return check(e.pos == Vector2(BOSS) and u.hp == hp and e.cast == null, "6초 뒤 기계 자리 %s((84,80)) · 2칸 옆 영웅 체력 %s → %s · 예고 %s(없음)" % [e.pos, hp, u.hp, e.cast])

# EV996 · S342: 대포는 가장 먼 산 원정대 영웅을, 기관총은 가장 가까운 영웅을 노린다. 거리가 같으면 출전 차례가 앞선 쪽이고, 도발했으면 도발한 영웅이다
func ev996():
	var b = _den3()
	var e = _machine(b)
	if e == null:
		return "3층 원정이 되지 않았다"
	var p = b.party
	_stand(b, [Vector2(86, 80), Vector2(84, 84), Vector2(78, 80)])
	var shell = _tell(b, e, 0)
	var gun = _tell(b, e, 1)
	_stand(b, [Vector2(82, 80), Vector2(86, 80), Vector2(84, 86)])
	var tie_gun = _tell(b, e, 1)
	_stand(b, [Vector2(88, 80), Vector2(80, 80), Vector2(84, 82)])
	var tie_shell = _tell(b, e, 0)
	b._fx(e, "t", {"taunt": p[1]}, 5.0)
	var taunt_shell = _tell(b, e, 0)
	var taunt_gun = _tell(b, e, 1)
	if [shell, tie_shell, taunt_shell].any(func(c): return c == null or c.id != "cannon" or not c.has("mark")) or [gun, tie_gun, taunt_gun].any(func(c): return c == null or c.id != "mgun" or not c.has("dir")):
		return "대포 예고 %s · 기관총 예고 %s" % [[shell, tie_shell, taunt_shell], [gun, tie_gun, taunt_gun]]
	var marks: Array = [shell, tie_shell, taunt_shell].map(func(c): return p.find(c.mark))
	var ats: Array = [shell, tie_shell, taunt_shell].map(func(c): return c.at)
	var dirs: Array = [gun, tie_gun, taunt_gun].map(func(c): return Vector2.from_angle(c.dir).round())
	return check(marks == [2, 0, 1] and ats == [Vector2(78, 80), Vector2(88, 80), Vector2(80, 80)] and dirs == [Vector2(1, 0), Vector2(-1, 0), Vector2(-1, 0)],
		"대포 사냥감 [가장 먼 셋째, 같은 거리, 도발] %s(기대 [2, 0, 1]) · 원 자리 %s · 기관총 방향 [가장 가까운 첫째, 같은 거리, 도발] %s(기대 동·서·서)" % [marks, ats, dirs])

# EV997 · S342 ①·I283 ③: 포탄 원은 사냥감을 따라다니다 마지막 1초에 굳는다. 기계에 닿은 채 굳은 원이 아무도 못 맞히면 기계가 그로기가 된다
func ev997():
	var b = _den3()
	var e = _machine(b)
	if e == null:
		return "3층 원정이 되지 않았다"
	_stand(b, FAR3)
	var u = b.party[1]
	var c = _tell(b, e, 0)
	if c == null or c.id != "cannon" or not is_same(c.get("mark"), u) or c.get("at") != Vector2(84, 86) or absf(c.left - 4.0) > 0.051 or c.has("aimed"):
		return "예고 %s(기대 cannon·둘째 영웅·원 (84,86)·남은 4초·aimed 없음)" % [c]
	u.pos = Vector2(84, 84)
	b.step(DT)
	var follows: bool = e.cast != null and e.cast.at == Vector2(84, 84)
	_go(b, 2.0)
	u.pos = Vector2(84, 82.5)
	_go(b, 1.2)
	var locked := [e.cast != null and e.cast.at == Vector2(84, 82.5), e.cast != null and e.cast.get("aimed")]
	u.pos = Vector2(84, 86)
	b.step(DT)
	var stays: bool = e.cast != null and e.cast.at == Vector2(84, 82.5)
	var hp: Array = b.party.map(func(h): return h.hp)
	_go(b, 0.5)
	var before := [e.cast != null, _groggy(b, e)]
	_go(b, 0.3)
	if not follows or locked != [true, true] or not stays or before != [true, false] or e.cast != null or not _groggy(b, e) or b.party.map(func(h): return h.hp) != hp or e.beat != 1 or e.pos != Vector2(BOSS):
		return "따라갔나 %s · 남은 0.75초 [원 (84,82.5), 기계에 닿음] %s(기대 [참, 참]) · 굳은 뒤 그대로 %s · 남은 0.2초 [예고 중, 그로기] %s(기대 [참, 거짓]) · 터진 뒤 예고 %s(없음) · 그로기 %s(참) · 영웅 체력 %s → %s · 대본 차례 %s(1) · 기계 자리 %s" % [follows, locked, stays, before, e.cast, _groggy(b, e), hp, b.party.map(func(h): return h.hp), e.beat, e.pos]
	_go(b, 4.6)
	var late: bool = _groggy(b, e)
	_go(b, 0.5)
	return check(late and not _groggy(b, e), "그로기가 4.6초 뒤 %s(참) · 5.1초 뒤 %s(거짓)" % [late, _groggy(b, e)])

# EV998 · S342 ①: 포탄에 맞으면 피해 30과 1칸 밀림이고 그로기가 없다. 기계에 닿지 않은 원은 아무도 못 맞혀도 그로기가 없다
func ev998():
	var b = _den3()
	var e = _machine(b)
	if e == null:
		return "3층 원정이 되지 않았다"
	_stand(b, FAR3)
	var u = b.party[1]
	_tell(b, e, 0)
	u.pos = Vector2(84, 82.5)
	var want: float = _take(b, u, 30.0)
	var hp: float = u.hp
	var others := [b.party[0].hp, b.party[2].hp]
	_go(b, 4.1)
	if absf(hp - u.hp - want) > 0.01 or u.pos.distance_to(Vector2(84, 83.5)) > 0.01 or _groggy(b, e) or [b.party[0].hp, b.party[2].hp] != others or e.cast != null or e.beat != 1:
		return "① 잃은 체력 %s(기대 %s) · 맞은 영웅 자리 %s((84,83.5)) · 그로기 %s(거짓) · 원 밖 둘 %s → %s · 예고 %s(없음) · 대본 차례 %s(1)" % [hp - u.hp, want, u.pos, _groggy(b, e), others, [b.party[0].hp, b.party[2].hp], e.cast, e.beat]
	var k = _den3()
	var w = _machine(k)
	if w == null:
		return "② 3층 원정이 되지 않았다"
	_stand(k, FAR3)
	_tell(k, w, 0)
	_go(k, 3.3)
	var c = w.cast
	if c == null or c.get("at") != Vector2(84, 86) or c.get("aimed") != false:
		return "② 남은 0.7초 예고 %s(기대 원 (84,86)·기계에 안 닿음)" % [c]
	k.party[1].pos = Vector2(88, 86)
	var all: Array = k.party.map(func(h): return h.hp)
	_go(k, 0.9)
	return check(not _groggy(k, w) and k.party.map(func(h): return h.hp) == all and w.cast == null, "② 안 닿은 원이 빈 뒤 그로기 %s(거짓) · 영웅 체력 %s → %s · 예고 %s(없음)" % [_groggy(k, w), all, k.party.map(func(h): return h.hp), w.cast])

# EV999 · S342 ②·I283 ④: 기관총은 가까운 영웅 쪽 부채꼴 안을 틱마다 8로 쏘고, 아무도 못 맞혀도 그로기가 없다. 대본 차례는 발사가 끝난 때 넘어간다
func ev999():
	var b = _den3()
	var e = _machine(b)
	if e == null:
		return "3층 원정이 되지 않았다"
	var p = b.party
	_stand(b, [Vector2(84, 76), Vector2(84, 83), Vector2(BOSS) + Vector2.from_angle(deg_to_rad(150.0)) * 4.0])
	var c = _tell(b, e, 1)
	if c == null or c.id != "mgun" or Vector2.from_angle(c.get("dir", 0.0)).round() != Vector2(0, 1) or absf(c.left - 1.4) > 0.051 or c.get("fire", false):
		return "예고 %s(기대 mgun·남쪽·남은 1.4초·발사 전)" % [c]
	var want := [_take(b, p[1], 8.0), _take(b, p[2], 8.0)]
	var hp: Array = p.map(func(h): return h.hp)
	_go(b, 2.4)
	var mid := [e.cast != null and e.cast.get("fire", false), e.beat]
	_go(b, 1.2)
	var lost: Array = range(3).map(func(i): return hp[i] - p[i].hp)
	if mid != [true, 1] or lost[0] != 0.0 or absf(lost[1] - 2.0 * want[0]) > 0.01 or absf(lost[2] - want[1]) > 0.01 or _groggy(b, e) or e.cast != null or e.beat != 2:
		return "① 2.4초 [발사 중, 대본 차례] %s(기대 [참, 1]) · 잃은 체력 %s(기대 부채꼴 밖 0 · 가운데 %s · 끝 %s) · 그로기 %s(거짓) · 예고 %s(없음) · 대본 차례 %s(2)" % [mid, lost, 2.0 * want[0], want[1], _groggy(b, e), e.cast, e.beat]
	var k = _den3()
	var w = _machine(k)
	if w == null:
		return "② 3층 원정이 되지 않았다"
	_stand(k, [Vector2(84, 76), Vector2(84, 83), Vector2(88, 76)])
	_tell(k, w, 1)
	k.party[1].pos = Vector2(84, 74)
	var all: Array = k.party.map(func(h): return h.hp)
	_go(k, 3.6)
	return check(not _groggy(k, w) and k.party.map(func(h): return h.hp) == all and w.cast == null, "② 모두 피한 뒤 그로기 %s(거짓) · 영웅 체력 %s → %s · 예고 %s(없음)" % [_groggy(k, w), all, k.party.map(func(h): return h.hp), w.cast])

# EV1000 · S342 ③: 증기 배출은 둘레 반경 3칸에 피해 30·넉백 1.5칸이고 둔화가 없다. 카운터 창 안의 기절은 예고를 끊고 그로기를 연다
func ev1000():
	var b = _den3()
	var e = _machine(b)
	if e == null:
		return "3층 원정이 되지 않았다"
	_stand(b, [Vector2(80, 76), Vector2(84, 82), Vector2(88, 76)])
	var u = b.party[1]
	var c = _tell(b, e, 3)
	if c == null or c.id != "slam" or absf(c.left - 2.5) > 0.051:
		return "예고 %s(기대 slam·남은 2.5초)" % [c]
	var want: float = _take(b, u, 30.0)
	var hp: float = u.hp
	var others := [b.party[0].hp, b.party[2].hp]
	_go(b, 2.6)
	if absf(hp - u.hp - want) > 0.01 or u.pos.distance_to(Vector2(84, 83.5)) > 0.01 or b._fx_on(u, "slow") != null or _groggy(b, e) or [b.party[0].hp, b.party[2].hp] != others or e.beat != 0:
		return "① 잃은 체력 %s(기대 %s) · 맞은 영웅 자리 %s((84,83.5)) · 둔화 %s(없음) · 그로기 %s(거짓) · 반경 밖 둘 %s → %s · 대본 차례 %s(0)" % [hp - u.hp, want, u.pos, b._fx_on(u, "slow"), _groggy(b, e), others, [b.party[0].hp, b.party[2].hp], e.beat]
	var k = _den3()
	var w = _machine(k)
	if w == null:
		return "② 3층 원정이 되지 않았다"
	_stand(k, [Vector2(80, 76), Vector2(84, 82), Vector2(88, 76)])
	_tell(k, w, 3)
	_go(k, 1.0)
	var open: bool = k.countering(w)
	k._fx(w, "t1", {"stun": true}, 2.0)
	var early := [w.cast != null and w.cast.id == "slam", _groggy(k, w), k.effect(w, "deflect") != null]
	_go(k, 0.6)
	var window: bool = k.countering(w)
	k._fx(w, "t2", {"stun": true}, 2.0)
	var late := [w.cast, _groggy(k, w), k._fx_on(w, "stun"), w.beat]
	var hp2: float = k.party[1].hp
	_go(k, 1.5)
	return check(not open and early == [true, false, true] and window and late == [null, true, null, 0] and k.party[1].hp == hp2,
		"② 1.0초 카운터 창 %s(거짓) · 그때 기절 뒤 [예고 있음, 그로기, 튕김] %s(기대 [참, 거짓, 참]) · 1.6초 카운터 창 %s(참) · 그때 기절 뒤 [예고, 그로기, 기절, 대본 차례] %s(기대 [null, 참, null, 0]) · 영웅 체력 %s → %s" % [open, early, window, late, hp2, k.party[1].hp])

# EV1001 · S342 ④·I283 ①⑧: 기계 체력이 0이 되면 처치가 아니라 같은 자리에서 대장으로 바뀌고 잔해가 남는다. 대장은 바로 도약을 예고하고, 대장을 처치하면 깬 층 3·층 골드 180이다
func ev1001():
	var b = _den3()
	var e = _machine(b)
	if e == null:
		return "3층 원정이 되지 않았다"
	if not b.get("wrecks") is Array:
		return "판에 wrecks가 없다"
	_stand(b, FAR3)
	b.damage(e, 500.0, "true")
	var half: float = b.raid_left()
	_tell(b, e, 0)
	b._fx(e, "t", {"slow": 0.3}, 9.0)
	var gold: int = b.gold
	b.damage(e, BIG)
	var now := [b.state, b.enemies.size(), not b.enemies.is_empty() and is_same(b.enemies[0], e), e.kind, e.alive, e.hp, e.max_hp, e.radius, e.armor, e.reward, e.xp, e.pos, e.cast, e.fx.is_empty(), b.gold - gold, b.floors_cleared]
	if absf(half - 0.75) > 0.0001 or now != ["raid", 1, true, "chief", true, 1000.0, 1000.0, 1.5, 10.0, 0, 0, Vector2(BOSS), null, true, 0, 2]:
		return "기계 체력 500일 때 남은 비율 %s(0.75) · 부서진 뒤 [판, 적 수, 같은 적, 종류, 살았나, 체력, 최대 체력, 몸, 방어력, 처치 골드, 경험치, 자리, 예고, 효과 없음, 는 골드, 깬 층] %s(기대 [raid, 1, 참, chief, 참, 1000, 1000, 1.5, 10, 0, 0, (84,80), null, 참, 0, 2])" % [half, now]
	if absf(b.raid_left() - 0.5) > 0.0001 or b.wrecks.size() != 1 or b.wrecks[0].at != Vector2(BOSS) or (b.has_method("raid_title") and b.raid_title() != "고블린 대장") or not b.has_method("raid_title"):
		return "부서진 뒤 남은 비율 %s(0.5) · 잔해 %s(하나, (84,80)) · 이름 %s(고블린 대장)" % [b.raid_left(), b.wrecks.map(func(w): return w.at), b.raid_title() if b.has_method("raid_title") else "raid_title 없음"]
	b.step(DT)
	var first = e.cast
	if first == null or first.id != "leap":
		return "부서진 다음 스텝의 예고 %s(기대 leap)" % [first]
	e.cast = null
	e.rest = 999.0
	_go(b, 6.0)
	var kept := [b.state, b.wrecks.size()]
	b.damage(e, BIG)
	_go(b, 3.1)
	return check(kept == ["raid", 1] and b.state == "prep" and b.floors_cleared == 3 and b.gold - gold == 180 and b.wrecks.is_empty() and b.relics == {},
		"부서지고 6초 뒤 [판, 잔해 수] %s(기대 [raid, 1]) · 대장 처치 3.1초 뒤 판 %s(prep) · 깬 층 %s(3) · 는 골드 %s(180) · 잔해 %s(없음) · 가방 %s(빔)" % [kept, b.state, b.floors_cleared, b.gold - gold, b.wrecks.size(), b.relics])

# EV1002 · S342 ⑥·I283 ⑦: 도약은 사냥감 자리에 뛰고 겨눈 뜀을 모두 피하면 그로기다. 맞으면 피해 30·넉백 1.5칸이고, 8칸보다 먼 사냥감에게는 8칸만 뛴다
func ev1002():
	var b = _den3()
	var e = _chief(b)
	if e == null:
		return "3층 원정에서 기계가 대장으로 바뀌지 않았다"
	_stand(b, [Vector2(84, 78), Vector2(84, 84), Vector2(86, 79)])
	var u = b.party[1]
	var c = _tell(b, e, 0)
	if c == null or c.id != "leap" or c.get("at") != Vector2(84, 84) or c.get("aimed") != true or absf(c.left - 1.5) > 0.051 or c.get("air", false):
		return "① 예고 %s(기대 leap·착지 (84,84)·겨눈 뜀·남은 1.5초·뜨기 전)" % [c]
	u.pos = Vector2(88, 84)
	var hp: Array = b.party.map(func(h): return h.hp)
	_go(b, 1.6)
	var air: bool = e.cast != null and e.cast.get("air", false)
	var soon := [e.beat, e.rest]
	_go(b, 0.6)
	if not air or soon != [1, 2.0] or e.pos.distance_to(Vector2(84, 84)) > 0.01 or not _groggy(b, e) or b.party.map(func(h): return h.hp) != hp or e.cast != null:
		return "① 1.6초 뜬 중 %s(참) · 그때 [대본 차례, 쉼] %s(기대 [1, 2]) · 2.2초 대장 자리 %s((84,84)) · 그로기 %s(참) · 영웅 체력 %s → %s · 예고 %s(없음)" % [air, soon, e.pos, _groggy(b, e), hp, b.party.map(func(h): return h.hp), e.cast]
	var k = _den3()
	var w = _chief(k)
	if w == null:
		return "② 기계가 대장으로 바뀌지 않았다"
	_stand(k, [Vector2(84, 78), Vector2(84, 84), Vector2(86, 79)])
	var v = k.party[1]
	_tell(k, w, 0)
	var want: float = _take(k, v, 30.0)
	var hp2: float = v.hp
	_go(k, 2.3)
	if absf(hp2 - v.hp - want) > 0.01 or absf(v.pos.x - 84.0) > 0.01 or v.pos.y < 85.49 or v.pos.y > 86.0 or _groggy(k, w):
		return "② 잃은 체력 %s(기대 %s) · 맞은 영웅 자리 %s(남쪽으로 1.5칸 넘게: x 84·y 85.5~86) · 그로기 %s(거짓)" % [hp2 - v.hp, want, v.pos, _groggy(k, w)]
	var m = _den3()
	var x = _chief(m)
	if x == null:
		return "③ 기계가 대장으로 바뀌지 않았다"
	_stand(m, [Vector2(84, 78), Vector2(96, 80), Vector2(86, 79)])
	var far = _tell(m, x, 0)
	if far == null or far.id != "leap" or far.get("at") != Vector2(92, 80) or far.get("aimed") != false:
		return "③ 예고 %s(기대 leap·착지 (92,80)·이동 뜀)" % [far]
	var all: Array = m.party.map(func(h): return h.hp)
	_go(m, 2.3)
	return check(x.pos.distance_to(Vector2(92, 80)) < 0.01 and not _groggy(m, x) and m.party.map(func(h): return h.hp) == all, "③ 이동 뜀 뒤 대장 %s((92,80)) · 그로기 %s(거짓) · 영웅 체력 %s → %s" % [x.pos, _groggy(m, x), all, m.party.map(func(h): return h.hp)])

# EV1003 · S342 ⑦⑨: 철퇴는 가까운 영웅 쪽 부채꼴 안에 피해 40·넉백 1.5칸이다. 폭탄은 예고를 띄울 때의 영웅 자리마다 떨어져 원 안에 25를 준다. 둘 다 그로기가 없다
func ev1003():
	var b = _den3()
	var e = _chief(b)
	if e == null:
		return "3층 원정에서 기계가 대장으로 바뀌지 않았다"
	var p = b.party
	_stand(b, [Vector2(BOSS) + Vector2.from_angle(deg_to_rad(160.0)) * 3.0, Vector2(84, 82.5), Vector2(BOSS) + Vector2.from_angle(deg_to_rad(140.0)) * 3.0])
	var c = _tell(b, e, 1)
	if c == null or c.id != "cleave" or Vector2.from_angle(c.get("dir", 0.0)).round() != Vector2(0, 1) or absf(c.left - 1.4) > 0.051:
		return "① 예고 %s(기대 cleave·남쪽·남은 1.4초)" % [c]
	var want := [_take(b, p[1], 40.0), _take(b, p[2], 40.0)]
	var hp: Array = p.map(func(h): return h.hp)
	_go(b, 1.5)
	var lost: Array = range(3).map(func(i): return hp[i] - p[i].hp)
	var gaps := [e.pos.distance_to(p[1].pos), e.pos.distance_to(p[2].pos)]
	if lost[0] != 0.0 or absf(lost[1] - want[0]) > 0.01 or absf(lost[2] - want[1]) > 0.01 or absf(gaps[0] - 4.0) > 0.02 or absf(gaps[1] - 4.5) > 0.02 or _groggy(b, e) or e.beat != 2:
		return "① 잃은 체력 %s(기대 부채꼴 밖 0 · %s · %s) · 맞은 둘의 대장과의 거리 %s(기대 4.0·4.5) · 그로기 %s(거짓) · 대본 차례 %s(2)" % [lost, want[0], want[1], gaps, _groggy(b, e), e.beat]
	var k = _den3()
	var w = _chief(k)
	if w == null:
		return "② 기계가 대장으로 바뀌지 않았다"
	var q = k.party
	_stand(k, [Vector2(80, 84), Vector2(80, 85), Vector2(88, 84)])
	var d = _tell(k, w, 3)
	if d == null or d.id != "bombs" or d.get("spots") != [Vector2(80, 84), Vector2(88, 84)] or absf(d.left - 1.6) > 0.051:
		return "② 예고 %s(기대 bombs·자리 (80,84)·(88,84)·남은 1.6초)" % [d]
	q[0].pos = Vector2(80, 80)
	var need := [_take(k, q[1], 25.0), _take(k, q[2], 25.0)]
	var hp2: Array = q.map(func(h): return h.hp)
	_go(k, 1.7)
	var lost2: Array = range(3).map(func(i): return hp2[i] - q[i].hp)
	return check(lost2[0] == 0.0 and absf(lost2[1] - need[0]) < 0.01 and absf(lost2[2] - need[1]) < 0.01 and q[1].pos == Vector2(80, 85) and not _groggy(k, w) and w.cast == null and w.beat == 4,
		"② 잃은 체력 %s(기대 원 밖 0 · %s · %s) · 둘째 영웅 자리 %s((80,85) 그대로) · 그로기 %s(거짓) · 예고 %s(없음) · 대본 차례 %s(4)" % [lost2, need[0], need[1], q[1].pos, _groggy(k, w), w.cast, w.beat])

# EV1004 · S342 ⑧·I283 ⑤⑥: 대장의 돌진은 잔해 앞에서 멈추고, 2칸 넘게 달려 박혔는데 아무도 못 맞혔으면 그로기다. 2칸을 못 달리면 이동 돌진이다. 잔해 안에서 출발하면 막히지 않고, 영웅 대시는 잔해를 지나간다
func ev1004():
	var b = _den3()
	var e = _chief(b)
	if e == null:
		return "3층 원정에서 기계가 대장으로 바뀌지 않았다"
	_stand(b, [Vector2(80, 84), Vector2(84, 74), Vector2(88, 84)])
	e.pos = Vector2(84, 85)
	var c = _tell(b, e, 2)
	if c == null or c.id != "charge" or c.get("aimed") != true or c.to.distance_to(Vector2(84, 81.5)) > 0.01 or absf(c.left - 1.4) > 0.051:
		return "① 예고 %s(기대 charge·벽 돌진·끝 (84,81.5)·남은 1.4초)" % [c]
	var hp: Array = b.party.map(func(h): return h.hp)
	_go(b, 1.5)
	if e.pos.distance_to(Vector2(84, 81.5)) > 0.01 or not _groggy(b, e) or b.party.map(func(h): return h.hp) != hp or e.beat != 3:
		return "① 잔해 너머로 돌진한 뒤 대장 %s((84,81.5)) · 그로기 %s(참) · 영웅 체력 %s → %s · 대본 차례 %s(3)" % [e.pos, _groggy(b, e), hp, b.party.map(func(h): return h.hp), e.beat]
	var k = _den3()
	var w = _chief(k)
	if w == null:
		return "② 기계가 대장으로 바뀌지 않았다"
	_stand(k, [Vector2(80, 84), Vector2(84, 74), Vector2(88, 84)])
	w.pos = Vector2(84, 82.5)
	var near = _tell(k, w, 2)
	if near == null or near.get("aimed") != false or near.to.distance_to(Vector2(84, 81.5)) > 0.01:
		return "② 예고 %s(기대 이동 돌진·끝 (84,81.5))" % [near]
	_go(k, 1.5)
	if w.pos.distance_to(Vector2(84, 81.5)) > 0.01 or _groggy(k, w):
		return "② 1칸 달려 잔해 앞에 멈춘 뒤 대장 %s((84,81.5)) · 그로기 %s(거짓)" % [w.pos, _groggy(k, w)]
	w.pos = Vector2(BOSS)
	var out = _tell(k, w, 2)
	if out == null or out.get("aimed") != false or out.to.distance_to(Vector2(84, 72)) > 0.01:
		return "③ 잔해 가운데에서 띄운 예고 %s(기대 이동 돌진·끝 (84,72))" % [out]
	w.cast = null
	w.rest = 999.0
	w.pos = Vector2(90, 84)
	var u = k.party[0]
	u.pos = Vector2(84, 82)
	k.dash([u], Vector2(84, 70))
	return check(u.pos.distance_to(Vector2(84, 80)) < 0.01, "④ 잔해를 가로질러 대시한 영웅 자리 %s((84,80))" % [u.pos])

# 금색 원 예고를 띄운 3층 2형. [판, 대장]이고 안 되면 []
func _feast(team := TEAM) -> Array:
	var b = _den3(team)
	var e = _chief(b)
	if e == null:
		return []
	_stand(b, [Vector2(83, 84), Vector2(84, 84), Vector2(85, 84)].slice(0, b.party.size()))
	var c = _tell(b, e, 4)
	if c == null or c.id != "soak" or not c.has("at"):
		return []
	return [b, e]

# EV1005 · S342 ⑩: 금색 원은 셋이 모이면 30씩 나눠 받고 그로기가 열린다. 둘이면 모두 30을 받고 대장이 5% 회복한다. 원정대가 둘뿐이어도 3명 기준은 같다
func ev1005():
	var s := _feast()
	if s.is_empty():
		return "금색 원 예고가 뜨지 않았다(3층 원정·대장·한 스텝 뒤 soak)"
	var b = s[0]
	var e = s[1]
	var at: Vector2 = e.cast.at
	var p = b.party
	if not at.is_equal_approx(Vector2(79, 80)) or absf(e.cast.left - 4.5) > 0.051:
		return "금색 원 자리 %s((79,80)) · 남은 %s초(4.5)" % [at, e.cast.left]
	_stand(b, [at + Vector2(0, -0.7), at, at + Vector2(0, 0.7)])
	var want := [_take(b, p[1], 30.0), _take(b, p[2], 30.0)]
	var hp: Array = p.map(func(h): return h.hp)
	_go(b, 4.6)
	var lost: Array = range(3).map(func(i): return hp[i] - p[i].hp)
	if lost[0] <= 0.0 or absf(lost[1] - want[0]) > 0.01 or absf(lost[2] - want[1]) > 0.01 or not _groggy(b, e) or e.hp != 1000.0:
		return "① 셋이 모인 뒤 잃은 체력 %s(기대 0 초과 · %s · %s) · 그로기 %s(참) · 대장 체력 %s(1000)" % [lost, want[0], want[1], _groggy(b, e), e.hp]
	s = _feast()
	if s.is_empty():
		return "② 금색 원 예고가 뜨지 않았다"
	b = s[0]
	e = s[1]
	p = b.party
	b.damage(e, 100.0, "true")
	_stand(b, [Vector2(84, 86), at, at + Vector2(0, 0.7)])
	want = [_take(b, p[1], 30.0), _take(b, p[2], 30.0)]
	hp = p.map(func(h): return h.hp)
	_go(b, 4.6)
	lost = range(3).map(func(i): return hp[i] - p[i].hp)
	if lost[0] <= 0.0 or absf(lost[1] - want[0]) > 0.01 or absf(lost[2] - want[1]) > 0.01 or _groggy(b, e) or absf(e.hp - 950.0) > 0.001:
		return "② 둘만 모인 뒤 잃은 체력 %s(기대 0 초과 · %s · %s) · 그로기 %s(거짓) · 대장 체력 %s(900 + 50 = 950)" % [lost, want[0], want[1], _groggy(b, e), e.hp]
	s = _feast(TEAM.slice(0, 2))
	if s.is_empty():
		return "③ 원정대 둘의 금색 원 예고가 뜨지 않았다"
	b = s[0]
	e = s[1]
	p = b.party
	var spot: Vector2 = e.cast.at
	_stand(b, [spot + Vector2(0, -0.4), spot + Vector2(0, 0.4)])
	var need: float = _take(b, p[1], 30.0)
	var hp1: float = p[1].hp
	_go(b, 4.6)
	return check(p.size() == 2 and absf(hp1 - p[1].hp - need) < 0.01 and not _groggy(b, e), "③ 원정대 %d명(2)이 다 모인 뒤 둘째 영웅이 잃은 체력 %s(기대 %s) · 그로기 %s(거짓)" % [p.size(), hp1 - p[1].hp, need, _groggy(b, e)])

# EV1006 · S342 ⑤·I283 ①④: 기계의 대본은 대포 → 기관총 → 대포 → 증기 배출을 쉼 5·4·5·5초로 돈다. 대장은 차례 0·쉼 0에서 시작해 도약 → 철퇴 → 돌진 → 폭탄 → 금색 원을 쉼 4·2·4·4·5초로 돈다
func ev1006():
	var b = _den3()
	b.start_raid()
	if b.state != "raid" or b.enemies.size() != 1 or b.enemies[0].kind != "war_machine":
		return "3층 원정이 되지 않았다"
	_freeze(b)
	var got: Array = _casts(b, [b.enemies[0]], 41.5)
	var starts: Array = got[0]
	var ends: Array = got[1]
	var ids: Array = starts.map(func(s): return s[1])
	if ids != ["cannon", "mgun", "cannon", "slam", "cannon"] or ends.size() < 4:
		return "① 예고 차례 %s(기대 대포·기관총·대포·증기 배출·대포) · 끝난 예고 %d(4 이상)" % [ids, ends.size()]
	var gaps := [starts[0][0]]
	for i in range(1, 5):
		gaps.append(starts[i][0] - ends[i - 1])
	var want := [8.0, 4.0, 5.0, 5.0, 5.0]
	if range(5).any(func(i): return absf(gaps[i] - want[i]) > 0.2):
		return "① 첫 예고까지와 앞 예고가 끝난 때부터 다음 예고까지 %s(기대 %s, 0.2초 안: 서 있기 3 + 쉼 5 · 쉼 4 · 쉼 5 · 쉼 5 · 쉼 5)" % [gaps, want]
	var k = _den3()
	var w = _machine(k)
	if w == null:
		return "② 3층 원정이 되지 않았다"
	_stand(k, [Vector2(72, 80), Vector2(73, 80), Vector2(74, 80)])
	k.damage(w, BIG)
	var born := [w.kind, w.beat, w.rest]
	var seen := []
	for i in 5:
		for h in k.party:
			h.hp = h.max_hp
		_tell(k, w, i)
		var id = w.cast.id if w.cast != null else null
		_resolve(k, w)
		seen.append([id, w.beat, snappedf(w.rest, 0.5)])
	return check(born == ["chief", 0, 0.0] and seen == [["leap", 1, 2.0], ["cleave", 2, 4.0], ["charge", 3, 4.0], ["bombs", 4, 5.0], ["soak", 0, 4.0]],
		"② 부서진 직후 [종류, 대본 차례, 쉼] %s(기대 [chief, 0, 0]) · 차례마다 [예고, 끝난 뒤 대본 차례, 다음 쉼] %s(기대 leap 1 2 · cleave 2 4 · charge 3 4 · bombs 4 5 · soak 0 4)" % [born, seen])

# EV1007 · I283 ⑨: 보스 막대의 이름은 지금 형태를 따르고 기계·대장·잔해의 그림 배율은 1이다. 대장을 처치하면 유물 없는 층의 토스트가 뜬다
func ev1007():
	var main = _den_game()
	var b = main.view.battle
	for i in 2:
		b.state = "cleared"
		b.next_round()
	b.floors_cleared = 2
	_frame(main)
	_toast_texts(main)
	b.start_raid()
	_frame(main)
	if b.state != "raid" or b.enemies.size() != 1 or b.enemies[0].kind != "war_machine":
		_done(main)
		return "3층 원정이 되지 않았다(판 %s · 적 %d)" % [b.state, b.enemies.size()]
	var e = b.enemies[0]
	var first := [main.hud._boss_name.text, main.view._shrunk(e)]
	b.damage(e, BIG)
	e.cast = null
	e.rest = 999.0
	_frame(main)
	var second := [main.hud._boss_name.text, main.view._shrunk(e), b.wrecks[0].get("size") if b.wrecks.size() == 1 else null]
	var gold: int = b.gold
	b.damage(e, BIG)
	_spin(main, 3.1)
	var after := [b.state, b.floors_cleared, b.gold - gold, b.relics, b.raid_block()]
	var texts := _toast_texts(main)
	_done(main)
	if first != ["전쟁 기계", 1.0] or second != ["고블린 대장", 1.0, 1.0]:
		return "기계일 때 [이름, 그림 배율] %s(기대 [전쟁 기계, 1]) · 대장일 때 [이름, 그림 배율, 잔해 그림 배율] %s(기대 [고블린 대장, 1, 1])" % [first, second]
	return check(after == ["prep", 3, 180, {}, "done"] and texts.any(func(t): return "3층" in t and "180" in t),
		"처치 3.1초 뒤 [판, 깬 층, 는 골드, 가방, 원정 버튼 이유] %s(기대 [prep, 3, 180, {}, done]) · 보인 토스트 %s(«3층»과 «180»이 함께 든 것이 있어야)" % [after, texts])

# EV1008 · I283 ⑤⑧: 대장인 채 전멸해 «다시»를 하면 잔해가 사라지고 기계가 가득 찬 체력으로 새로 나온다. 철수해도 잔해가 사라진다
func ev1008():
	var b = _den3()
	var e = _chief(b)
	if e == null or not b.get("wrecks") is Array or b.wrecks.size() != 1:
		return "3층 원정에서 기계가 대장으로 바뀌고 잔해가 하나 남지 않았다"
	for h in b.party.duplicate():
		b.damage(h, BIG)
	_go(b, 2.6)
	var waiting := [b.raid_pending(), b.wrecks.size(), snappedf(b.raid_left(), 0.001)]
	var ok: bool = b.retry()
	var again := [ok, b.state, b.wrecks.size(), b.enemies.size(), b.enemies[0].kind if not b.enemies.is_empty() else "", b.enemies[0].hp if not b.enemies.is_empty() else 0.0, b.raid_left()]
	if waiting != [true, 1, 0.5] or again != [true, "raid", 0, 1, "war_machine", 1000.0, 1.0]:
		return "① 전멸 2.6초 뒤 [기다림, 잔해 수, 남은 비율] %s(기대 [참, 1, 0.5]) · «다시» 뒤 [됐나, 판, 잔해 수, 적 수, 종류, 체력, 남은 비율] %s(기대 [참, raid, 0, 1, war_machine, 1000, 1])" % [waiting, again]
	var k = _den3()
	var w = _chief(k)
	if w == null:
		return "② 기계가 대장으로 바뀌지 않았다"
	k.retreat()
	return check(k.state == "prep" and k.wrecks.is_empty() and k.enemies.is_empty(), "② 철수 뒤 판 %s(prep) · 잔해 %d(0) · 적 %d(0)" % [k.state, k.wrecks.size(), k.enemies.size()])

# 불꽃이 flame초일 때 3층 패턴 id 하나가 도발한 둘째 영웅에게서 깎은 체력. 대포·기관총은 기계가, 철퇴·폭탄은 대장이 쓴다. 안 되면 -1
func _burn(id: String, flame: float) -> float:
	var b = _den3()
	var first: bool = id in ["cannon", "mgun"]
	var e = _machine(b) if first else _chief(b)
	if e == null:
		return -1.0
	var u = b.party[1]
	_stand(b, [Vector2(72, 80), Vector2(84, 83), Vector2(96, 80)])
	b._fx(e, "t", {"taunt": u}, 30.0)
	b.flame = flame
	var plan: Array = e.raid.plan if first else e.raid.phase2.plan
	var c = _tell(b, e, plan.map(func(s): return s.id).find(id))
	if c == null or c.id != id:
		return -1.0
	var hp: float = u.hp
	_go(b, 4.2)
	return hp - u.hp

# EV1009 · I283 ④: 불꽃 100초부터의 광폭 배율은 포탄·기관총 틱·철퇴·폭탄의 피해에도 든다
func ev1009():
	var rows := []
	for id in ["cannon", "mgun", "cleave", "bombs"]:
		rows.append([id, _burn(id, 10.0), _burn(id, 101.0)])
	return check(rows.all(func(r): return r[1] > 0.0 and absf(r[2] - r[1] * 1.15) < 0.01), "[패턴, 불꽃 10초에 잃은 체력, 불꽃 101초에 잃은 체력] %s(뒤가 앞의 1.15배여야)" % [rows])
