extends RefCounted
# 출전 인원(lineup)을 출전 칸 수보다 크게 둔 판이 깨지지 않는다(2026-11-16 플레이 후기 4 검토에서 나온 회귀).
# 테스트 모드에서 «영입» 분류의 lineup 줄을 4로 두면 고르기 창이 넷을 고를 때까지 막았고, 넷째를 세울 출전 칸이 없어 다음 라운드로 넘어가다 멈췄다.
# 출전 칸보다 큰 lineup은 지원하지 않는다. 고르는 수가 출전 칸 수에서 멈추는 것만 본다.
# 지키는 요구:
#   S373. … 출전 인원(`data/hire.tres`의 lineup, 3명)을 다 고르면 나머지 카드는 눌리지 않는다. 다 고르기 전에는 «1라운드 시작» 버튼이 눌리지 않고 Enter·Space로도 넘어가지 않는다.
#   I107. … 새로 출전한 영웅은 다른 출전 영웅이 시작 칸으로 쓰지 않는 첫 출전 칸에 서고 … → 2026-10-18 변경: 출전 칸은 셋이다(S123).

const Main := preload("res://src/main.gd")

func _kinds(hs: Array) -> Array:
	return hs.map(func(h): return h.kind)

# 판: 출전 칸이 셋인 스테이지에서 lineup이 4여도 넷째는 거부되고, 셋으로 다음 라운드에 넘어간다
func test_board_picks_stop_at_hero_cells():
	var b = load("res://src/sim/battle.gd").new(Main.stage())
	b.HIRE = b.HIRE.duplicate()  # 데이터 Resource(load 캐시)를 고치지 않는다
	b.HIRE.lineup = 4
	b.begin_hiring()
	var got: Array = range(4).map(func(i): return b.hire(i) != null)
	var count: int = b.lineup_size()
	b.next_round()
	var why := []
	if got != [true, true, true, false] or count != 3:
		why.append("고르기 %s(넷째만 거부여야 한다) · 고르는 수 %d(3이어야 한다)" % [got, count])
	if b.state != "prep" or _kinds(b.heroes) != ["aias", "sylvia", "seraphina"] or b.hero != b.heroes[0]:
		why.append("다음 라운드 뒤 단계 %s · 출전 영웅 %s" % [b.state, _kinds(b.heroes)])
	b.HIRE.lineup = 2
	if b.lineup_size() != 2:
		why.append("lineup 2인 판의 고르는 수 %d" % b.lineup_size())
	return "" if why.is_empty() else "출전 칸보다 큰 lineup: %s" % ", ".join(why)

# 화면: 테스트 모드에서 lineup 줄을 4로 올려도 셋을 고르면 «1라운드 시작»이 눌리고, 넷째 카드는 고르지 못한다
func test_pick_window_starts_with_three_when_lineup_is_four():
	Main.test = true  # 테스트 모드 판은 저장을 쓰지 않는다(I231)
	var main = load("res://src/main.tscn").instantiate()
	Engine.get_main_loop().root.add_child(main)
	var b = main.view.battle
	var hud = main.hud
	main.tuning.put("영입", "hire", ["lineup"], 4)
	hud._process(0.0)
	for i in 3:
		hud._offers[i].pressed.emit()
	hud._process(0.0)
	var open: bool = not hud._next.disabled
	var info: String = hud._hire_info.text
	hud._offers[3].pressed.emit()
	var held: int = b.roster.size()
	hud.proceed()
	var state: String = b.state
	var out: Array = _kinds(b.heroes)
	main.free()
	Main.test = false
	var why := []
	if not open or not info.begins_with("영웅 3/3"):
		why.append("셋을 고른 뒤 «1라운드 시작» 눌림 %s · 안내 줄 «%s»(영웅 3/3이어야 한다)" % [open, info])
	if held != 3:
		why.append("넷째 카드를 누른 뒤 보유 %d명(3이어야 한다)" % held)
	if state != "prep" or out != ["aias", "sylvia", "seraphina"]:
		why.append("진행 뒤 단계 %s · 출전 영웅 %s" % [state, out])
	return "" if why.is_empty() else "lineup 4인 고르기 창: %s" % ", ".join(why)
