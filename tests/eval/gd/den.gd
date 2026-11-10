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

const ROOM := Rect2i(74, 76, 20, 12)
const ENTRY := [Vector2i(83, 87), Vector2i(85, 87), Vector2i(84, 87)]
const BOSS := Vector2i(84, 80)
const TEAM := [{"kind": "aias", "cell": Vector2i(31, 65)}, {"kind": "ignis", "cell": Vector2i(33, 65)}, {"kind": "seraphina", "cell": Vector2i(32, 65)}]

# 모서리마다 꼭짓점 칸에서 가로·세로 거리 합이 2 미만인 세 칸(I262 ①)
func _corners() -> Array:
	var out := []
	for k in [[74, 76, 1, 1], [93, 76, -1, 1], [74, 87, 1, -1], [93, 87, -1, -1]]:
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

# EV887 · S317·I262 ①: 맵 크기는 그대로이고 길 격자만 띠까지 넓다. 방 안 228칸만 설 수 있고, 띠에는 짓거나 용병을 놓지 못한다. 웨이브 길은 띠 밖이다
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
	var rock := corners + [Vector2i(64, 0), Vector2i(73, 80), Vector2i(94, 80), Vector2i(84, 75), Vector2i(84, 88), Vector2i(103, 129)]
	var walk: Array = rock.filter(func(c): return b._bare(c))
	if stand != 228 or not walk.is_empty():
		return "방에서 설 수 있는 칸 %d(기대 228) · 설 수 있는 바위 칸 %s(기대 없음)" % [stand, walk]
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
	b.floors_cleared = 0
	b.start_battle()
	var battle_why: String = b.raid_block()
	var started: bool = b.start_raid()
	if whys != ["party", "torch", "done"] or battle_why != "state" or started or b.state != "battle" or b.torches != 2:
		return "전멸·횃불 0·1층 깸 %s(기대 party·torch·done) · 전투 단계 %s(기대 state) · 시작 %s · 판 %s · 횃불 %d(기대 battle, 2)" % [whys, battle_why, started, b.state, b.torches]
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
	if e.kind != "slime_king" or Vector2i(e.pos.round()) != BOSS or e.hp != 1300.0 or e.max_hp != 1300.0 or e.reward != 0 or e.xp != 0 or b.dark != 0.0:
		return "보스 %s %s 체력 %s/%s 골드 %d 경험치 %d · 어둠 %s(기대 slime_king %s 1300/1300 0 0 · 0)" % [e.kind, e.pos, e.hp, e.max_hp, e.reward, e.xp, b.dark, BOSS]
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
	g.pos = Vector2(92, 82)
	b.dash([g], Vector2(100, 82))
	return check(g.dash_cd > 0.0 and g.pos.x > 92.0 and g.pos.x < 93.5, "바위 쪽 대시 뒤 x %.2f(92보다 크고 93.5 미만) · 대기 %.2f" % [g.pos.x, g.dash_cd])

# EV891 · S316·I262 ⑥⑦: 처치로 끝나면 3초 뒤 원정 직전 몸으로 돌아오고, 깬 층이 1 는다. 골드·웨이브·집계는 그대로다
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
	b.damage(b.enemies[0], BIG)
	_go(b, 2.9)
	var mid: String = b.state
	_go(b, 0.2)
	if mid != "raid" or b.state != "prep":
		return "처치 뒤 2.9초 %s(기대 raid) · 3.1초 %s(기대 prep)" % [mid, b.state]
	var count: Array = b.heroes.map(func(h): return b.units.count(h))
	if b.floors_cleared != 1 or b.torches != torches - 1 or b.gold != gold or b.wave_index != wave or b.tally != tally:
		return "깬 층 %d(1) · 횃불 %d(%d) · 골드 %d(%d) · 웨이브 %d(%d) · 집계 %s(기대 %s)" % [b.floors_cleared, b.torches, torches - 1, b.gold, gold, b.wave_index, wave, b.tally, tally]
	if not a.alive or a.hp != 40.0 or a.pos != Vector2(30, 70) or c.cd.q != 3.0 or count != [1, 1, 1]:
		return "아이아스 살았나 %s 체력 %s 자리 %s(기대 40, (30,70)) · 이그니스 Q 대기 %s(3) · units 안 횟수 %s(기대 1·1·1)" % [a.alive, a.hp, a.pos, c.cd.q, count]
	return check(b.enemies.is_empty() and b.zones.is_empty() and b.missiles.is_empty() and b.loops.is_empty() and b.raid_block() == "done",
		"돌아온 뒤 적 %d · 장판 %d · 투사체 %d · 루프 %d · 이유 %s(기대 모두 0, done)" % [b.enemies.size(), b.zones.size(), b.missiles.size(), b.loops.size(), b.raid_block()])

# EV892 · S316·I262 ⑥: 전멸·불꽃·철수로 끝난다. 전멸·불꽃은 2.5초 뒤, 철수는 바로 돌아오고, 쓴 횃불은 돌아오지 않는다
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
	if mid != "raid" or b.state != "prep" or not b.heroes.all(func(h): return h.alive) or b.heroes.map(func(h): return h.hp) != hp or b.floors_cleared != 0:
		return "전멸 뒤 2.4초 %s(raid) · 2.6초 %s(prep) · 체력 %s(기대 %s, 모두 살아) · 깬 층 %d(0)" % [mid, b.state, b.heroes.map(func(h): return h.hp), hp, b.floors_cleared]
	b.start_raid()
	b.flame = 119.9
	_go(b, 0.2)
	var gone: bool = b.enemies.is_empty()
	_go(b, 2.4)
	var left: String = b.state
	_go(b, 0.2)
	if not gone or left != "raid" or b.state != "prep":
		return "불꽃 120초 뒤 보스 사라짐 %s · 2.6초 %s(raid) · 2.8초 %s(prep)" % [gone, left, b.state]
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
	var room := Vector2(ROOM.position + ROOM.size / 2) * 16.0  # 보스방 가운데(맵 px) = (1344, 1312)
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
