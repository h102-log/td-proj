extends RefCounted
# 마우스·키 입력을 전투 명령으로 바꾼다. 마우스 좌표는 맵 px(칸 (x,y)가 [x, x+1) × cell_px)로 받는다.
# 좌클릭: 영웅이나 생산 시설·성곽 칸·거점을 고르거나(I9, S81, S85, S86, S100) 선택을 푼다 · 좌드래그: 사각형 안의 용병을 고른다(S16, I9)
# 우클릭: 생산 시설을 골랐으면 그 칸을 집결 지점으로(S82), 아니면 고른 유닛 이동(S14)
# 준비 단계의 좌클릭·좌드래그는 판매 후보도 정한다(S70, I57). 좌클릭한 용병은 두 단계 모두 고른 상태가 된다(I135)
# 전투 단계의 좌클릭·좌드래그는 철거·취소·이어 짓기 후보(picked)를 정한다(S74, S83)
# Q·W·E·R: 영웅 스킬(S145, I10). 고른 영웅이, 없으면 첫 영웅이 쓴다(S119). 즉시·켜고 끄는 칸은 바로 쓰고, 지점·방향·대상을 고르는 칸은
# 조준 상태가 된다(퀵캐스트를 켜면 키를 누르는 순간 커서 자리에 쓴다, I158). 조준 중 좌클릭은 그 지점·대상에 쓰고, 우클릭·ESC는 취소한다(S147). Shift+키와 HUD 스킬 버튼 우클릭은 자동 시전을 켜고 끈다(S158, I151)
# A: 고른 용병의 이동 방식 전환(S35) · H: 홀드 전환(S36) (A·H는 사용자 2026-10-12) · V: 체력바 표시 전환(S73)
# F1·F2·F3: 출전 영웅 1·2·3을 고른다(I108)
# 1 방벽 · 2 타워 · - 마법 타워(S110) · 3 용병 · 4 병영 · 5 공병 · 6 작업장 · 7 궁수(I71) · 8 대포(S92) · 9 사격장(S98) · 0 집(S103) · = 교회(I140): 놓기 모드. 그동안 좌클릭은 그 칸에 짓거나 놓고, 우클릭·ESC·같은 키는 모드를 끝낸다(사용자 2026-10-12, S186)
# 전투 단계엔 구조물만 짓는다(공병이 가서 짓는다, S22). 단계가 바뀌면 모드가 끝난다
# 옮길 대포(moving)가 있으면 다음 좌클릭한 칸으로 옮기고(S91), 우클릭·ESC·단계 변경은 옮기기를 그만둔다
# 결과 창(라운드 사이·도전 끝)과 도전 시작 전 영입 창이 떠 있는 동안에는 아무 입력도 받지 않는다(S117, I109)

# ponytail: 맵 px 기준이라 줌에 따라 화면에서 느끼는 거리가 달라진다. 거슬리면 화면 px로 잰다
const CLICK_SLOP := 4.0  # 이보다 덜 끌고 떼면 클릭이다(맵 px)
const SKILL_KEYS := {KEY_Q: "q", KEY_W: "w", KEY_E: "e", KEY_R: "r"}  # 영웅 스킬 칸(S145)
const PLACE_KEYS := {KEY_1: "wall", KEY_2: "tower", KEY_MINUS: "magic", KEY_3: "soldier", KEY_4: "barracks", KEY_5: "engineer", KEY_6: "workshop", KEY_7: "archer", KEY_8: "cannon", KEY_9: "archery", KEY_0: "house", KEY_EQUAL: "church"}

var battle
var cell_px: int
var selected := []
var drag_rect := Rect2()  # 끌고 있는 선택 사각형(맵 px). 그리기용이고, 끌고 있지 않으면 크기 0
var _press = null  # 좌버튼을 누른 위치(맵 px)
var placing := ""  # 놓기 모드의 종류(구조물 kind 또는 용병 kind). 빈 문자열이면 모드가 아니다
var selling := []  # 판매 후보(구조물·용병). 비어 있지 않으면 화면에 판매 팝업이 뜬다(I58)
var sell_at := Vector2()  # 판매 팝업을 띄울 곳: 클릭하거나 드래그를 놓은 지점(맵 px)
var show_hp := false  # 체력바를 모두 그린다(S73)
var facility = null  # 고른 생산 시설. 전투 단계엔 그 옆에 구매 팝업이 뜬다(S81, I61)
var picked := []  # 전투 단계에 고른 플레이어 구조물. 철거·취소·이어 짓기 팝업의 대상이다(S74, S83)
var fort = null  # 고른 성곽 칸이나 잔해(I88). 그 옆에 여닫기·업그레이드·수리·복구 팝업이 뜬다(S85, S86, S116, I89)
var moving = null  # 옮길 대포. 팝업의 «옮기기» 버튼이 넣는다(S91)
var village := false  # 거점을 골랐다. 그 옆에 마을 레벨 팝업이 뜬다(S100)
var aiming := ""  # 조준 중인 스킬 칸(S147). 빈 문자열이면 조준 중이 아니다
var aim_hero = null  # 조준 중인 칸을 쓸 영웅
var mouse := Vector2()  # 마지막 마우스 위치(맵 px). 화면이 조준 범위를 그린다
var quickcast := false  # 퀵캐스트(I158): 조준하는 칸의 키를 누르는 순간 커서 자리에 쓴다. main이 설정(S184)에서 넣는다
var _state: String  # 마지막으로 본 판 단계. 바뀌면 놓기 모드를 끝낸다

func _init(b, px: int) -> void:
	battle = b
	cell_px = px
	_state = b.state

func handle(event: InputEvent) -> void:
	if battle.state != _state:  # 키보다 먼저 본다. 단계가 바뀐 뒤 첫 입력이 놓기 키여도 모드가 켜지게
		placing = ""
		moving = null
		aiming = ""
		_state = battle.state
	if aiming != "" and not (aim_hero and aim_hero.alive):  # 조준하던 영웅이 쓰러졌다
		aiming = ""
	if event is InputEventMouse:
		mouse = event.position
	if battle.state not in ["prep", "battle"]:
		_press = null
		drag_rect = Rect2()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_Q, KEY_W, KEY_E, KEY_R:
				skill_key(SKILL_KEYS[event.keycode], event.shift_pressed)
			KEY_A:
				toggle_move_mode()
			KEY_H:
				toggle_hold()
			KEY_V:
				show_hp = not show_hp
			KEY_F1, KEY_F2, KEY_F3:  # 쓰러진 영웅은 고르지 않는다. 우클릭이 집결 지점 대신 영웅을 옮기게 시설 선택을 푼다
				var i: int = event.keycode - KEY_F1
				selected = battle.heroes.slice(i, i + 1).filter(func(h): return h.alive)
				facility = null
			KEY_ESCAPE:
				placing = ""
				moving = null
				aiming = ""
		if event.keycode in PLACE_KEYS:
			placing = "" if placing == PLACE_KEYS[event.keycode] else PLACE_KEYS[event.keycode]
		if placing != "":
			aiming = ""
	# 전투 단계엔 구조물만 놓기 모드가 된다. 전투 중 용병 구매는 시설 팝업으로 한다(S81)
	if not (battle.state == "prep" or (battle.state == "battle" and placing in battle.STRUCTURE_KINDS)):
		placing = ""
	if event is InputEventMouseMotion and _press != null:
		drag_rect = Rect2(_press, event.position - _press).abs()
	if not event is InputEventMouseButton:
		return
	if aiming != "" and event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_aim_at(event.position)
		else:
			aiming = ""
		return
	if moving and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			battle.move_cannon(moving, Vector2i((event.position / cell_px).floor()))
		moving = null
		return
	if placing != "" and event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_place(Vector2i((event.position / cell_px).floor()))
		else:
			placing = ""
		return
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press = event.position
		elif _press != null:
			_release(Rect2(_press, event.position - _press).abs(), event.position)
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var cell := Vector2i((event.position / cell_px).floor())
		if facility:
			battle.set_rally(facility, cell)
		else:
			battle.order_move(selected, cell)

func _release(rect: Rect2, at: Vector2) -> void:
	_press = null
	drag_rect = Rect2()
	sell_at = at
	var mercs: Array = battle.units.filter(func(u): return not u.is_hero)
	var prep: bool = battle.state == "prep"
	if rect.size.length() < CLICK_SLOP:
		var cell := Vector2i((rect.position / cell_px).floor())
		selected = battle.heroes.filter(func(h): return h.alive and Vector2i(h.pos.round()) == cell).slice(0, 1)  # 클릭한 칸의 영웅(I9, I101)
		var hit = battle.structure_at(cell)
		facility = hit if hit and not hit.produces.is_empty() and hit.complete else null
		fort = battle.castle.get(cell, battle.rubble.get(cell))
		village = cell == battle.base.cell
		picked = [hit] if hit and not prep else []
		for m in mercs:
			if Vector2i(m.pos.round()) == cell:
				hit = m
		selling = [hit] if prep and hit else []
		if hit in mercs:
			selected = [hit]
	else:
		var inside := func(p: Vector2): return rect.has_point((p + Vector2(0.5, 0.5)) * cell_px)
		facility = null
		fort = null
		village = false
		selected = mercs.filter(func(u): return inside.call(u.pos))
		var built: Array = battle.structures.values().filter(func(s): return inside.call(Vector2(s.cell)))
		selling = (selected + built) if prep else []
		picked = [] if prep else built

# 거점을 고른다. 거점 칸을 좌클릭한 것과 같다(S100). 건설 격자의 마을 레벨로 잠긴 칸이 해결 길로 부른다(I132)
func pick_base() -> void:
	var at := (Vector2(battle.base.cell) + Vector2(0.5, 0.5)) * cell_px
	_release(Rect2(at, Vector2.ZERO), at)

# 고른 용병의 이동 방식 전환(S35): 모두 «무조건 이동»이면 «이동 중 공격»으로, 아니면 모두 «무조건 이동»으로. A 키와 HUD 버튼(I139)이 부른다
func toggle_move_mode() -> void:
	battle.set_move_mode(selected, "attack_move" if selected.all(func(u): return u.move_mode == "move") else "move")

# 고른 용병의 홀드 전환(S36). H 키와 HUD 버튼(I139)이 부른다
func toggle_hold() -> void:
	battle.set_hold(selected, not selected.all(func(u): return u.hold))

# 스킬 키(S145, S147, S158). Q·W·E·R 키와 테스트가 부른다. shift면 자동 시전을 켜고 끈다.
# 즉시·켜고 끄는 칸(그리고 태세 중인 반격의 태세)은 바로 쓰고, 고르는 칸은 지금 쓸 수 있을 때만 조준 상태가 된다
func skill_key(slot: String, shift := false) -> void:
	var h = _hero()
	skill_for(h if h and h.alive else battle._first_alive(), slot, shift)
	if quickcast and aiming == slot:  # I158. HUD 스킬 버튼은 skill_for로 바로 와서 조준 상태로 남는다
		_aim_at(mouse)

# 영웅 h의 칸 slot을 쓴다(키·HUD 스킬 버튼, I151). shift면 자동 시전을 켜고 끈다
func skill_for(h, slot: String, shift := false) -> void:
	if not h or not h.alive:
		return
	if shift:
		battle.toggle_auto(h, slot)
		return
	var sk: Dictionary = h.get(slot)
	if sk.get("aim") in ["self", "toggle"] or (sk.get("id") == "brace" and h.brace > 0.0):
		battle.cast(h, slot)
	elif battle.can_cast(h, slot):
		aiming = slot
		aim_hero = h
		placing = ""
		moving = null

# 조준 중 좌클릭(S147, I145): 지점·방향은 클릭한 곳(칸 좌표), 대상은 클릭한 곳에서 가장 가까운 적이나 아군(0.7칸 안, 아군 구조물은 그 칸).
# 쓰거나 걸어가기 시작하면 조준이 끝나고, 맞는 대상이 없으면 조준을 이어 간다
func _aim_at(px: Vector2) -> void:
	var at := px / cell_px - Vector2(0.5, 0.5)
	var sk: Dictionary = aim_hero.get(aiming)
	var aim = at
	if sk.aim == "enemy":
		aim = _closest(battle.enemies, at)
	elif sk.aim == "ally":
		aim = _closest(battle.units, at)
		var s = battle.structure_at(Vector2i(at.round()))
		if aim == null and s:
			aim = s
	if aim != null and battle.cast(aim_hero, aiming, aim):
		aiming = ""

func _closest(pool: Array, at: Vector2):
	var best = null
	for x in pool:
		if x.pos.distance_to(at) <= 0.7 and (best == null or x.pos.distance_to(at) < best.pos.distance_to(at)):
			best = x
	return best

# 스킬을 쓸 영웅: 고른 출전 영웅. 없으면 null이라 첫 출전 영웅이 쓴다(S119). 출전에서 빠진 영웅은 고르지 않은 것으로 본다(I108)
func _hero():
	for u in selected:
		if u.is_hero and u in battle.heroes:
			return u
	return null

# 모드는 놓은 뒤에도 이어진다. 방벽을 줄지어 짓기 쉽게
func _place(cell: Vector2i) -> void:
	if placing in battle.STRUCTURE_KINDS:
		battle.build(placing, cell)
	elif battle.can_buy(placing):  # 마을이 있으면 그 용병의 시설이 있어야 산다(S50)
		battle.place_merc(placing, cell)
