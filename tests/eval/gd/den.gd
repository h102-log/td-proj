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
	_slay(b)
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

# EV905 · S322: 1층 층 정의의 세대 표와 뜀 수치. 디펜스 슬라임 킹 종류는 그대로다
func ev905():
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

# EV906 · S322: 왕은 걷지도 기본 공격도 하지 않고, 3초 선 뒤 가장 가까운 영웅 자리로 뛰어 원 안에만 피해를 준다. 뜀 거리 밖 영웅에게는 그쪽으로 5칸만 뛴다
func ev906():
	var b = _den()
	var e = _king(b)
	if e == null:
		return "원정 몸에 gen이 없거나 원정이 되지 않았다(판 %s · 적 %d)" % [b.state, b.enemies.size()]
	var a = b.party[0]
	a.pos = Vector2(84, 81.5)
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

# EV907 · I266 ①: 착지 원은 서로 겹치지 않고 선 몸 위에 내리지 않는다. 자리가 없으면 뛰지 않고 0.5초 뒤 다시 고른다
func ev907():
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

# EV908 · S322·I266 ②③: 죽으면 한 세대 작은 몸 둘로 갈라진다. 좌우 자리·가득 찬 체력·효과 없음·보상 없음·1.5초 쉼·엇갈린 박자, 방 밖에 놓이지 않고 넷째 세대는 갈라지지 않는다
func ev908():
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
	k1.pos = Vector2(74, 81)
	b.damage(k1, BIG)
	var g2: Array = b.enemies.filter(func(x): return x.gen == 2)
	var inside: bool = b.enemies.all(func(x): return b.in_room(Vector2i(x.pos.round())))
	if g2.size() != 2 or not g2.all(func(x): return _is_gen(x, 2)) or not inside:
		return "방 서쪽 끝 (74,81)에서 처치 뒤 2세대 %d(2) %s · 모두 방 안 %s" % [g2.size(), g2.map(func(x): return [x.hp, x.radius, x.pos]), inside]
	b.damage(g2[0], BIG)
	var g3: Array = b.enemies.filter(func(x): return x.gen == 3)
	if g3.size() != 2 or not g3.all(func(x): return _is_gen(x, 3)):
		return "2세대 처치 뒤 3세대 %d(2) %s" % [g3.size(), g3.map(func(x): return [x.hp, x.radius])]
	var n: int = b.enemies.size()
	b.damage(g3[0], BIG)
	return check(b.enemies.size() == n - 1, "3세대 처치 뒤 적 %d → %d(1 줄어야)" % [n, b.enemies.size()])

# EV909 · S322·I266 ④: 몸이 남으면 끝나지 않고, 모두 처치하면 처치로 끝난다. 불꽃이 다 타면 모든 몸이 사라지고, 전멸 뒤에는 어느 몸도 움직이지 않는다
func ev909():
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

# EV910 · S322: 보스 막대는 남은 총 체력 ÷ 1600이고, 몸 그림은 세대 몸 반지름에 비례해 작아진다
func ev910():
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
