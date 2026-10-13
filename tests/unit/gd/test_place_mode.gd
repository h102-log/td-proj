extends "res://tests/eval/gd/lib.gd"
# 1·2·3 놓기 모드: 좌클릭은 그 칸에 짓거나 놓고, 우클릭은 모드를 끝낸다(WBS 2.10, 사용자 2026-10-12).
# 지키는 요구:
#   S18. 준비 단계에서는 유닛 배치와 구조물 건설이 그 자리에서 바로 완성된다.
#   S22. 전투 중 건설은 공병이 그 칸까지 걸어가서 시간을 들여 짓는다.

func _key(c, code: int) -> void:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.pressed = true
	c.handle(ev)

func test_key_then_click_builds_and_stays_in_mode():
	var b = battle({"gold": 100})
	var c = controls(b)
	_key(c, KEY_1)
	click(c, MOUSE_BUTTON_LEFT, px(Vector2i(5, 5)))
	click(c, MOUSE_BUTTON_LEFT, px(Vector2i(6, 5)))
	var built: bool = b.structure_at(Vector2i(5, 5)) != null and b.structure_at(Vector2i(6, 5)) != null
	return check(built and b.gold == 100 - 2 * b.STRUCTURE_KINDS.wall.cost, "방벽 두 칸이 안 지어졌다(골드 %d)" % b.gold)

func test_merc_key_places_soldier():
	var b = battle()
	var c = controls(b)
	_key(c, KEY_3)
	click(c, MOUSE_BUTTON_LEFT, px(Vector2i(5, 5)))
	return check(b.units.size() == 1 and cell_of(b.units[0]) == Vector2i(5, 5), "용병이 안 놓였다")

func test_right_click_ends_mode():
	var b = battle()
	var c = controls(b)
	_key(c, KEY_2)
	click(c, MOUSE_BUTTON_RIGHT, px(Vector2i(5, 5)))
	click(c, MOUSE_BUTTON_LEFT, px(Vector2i(5, 5)))
	return check(c.placing == "" and b.structure_at(Vector2i(5, 5)) == null, "우클릭 뒤에도 놓기 모드다")

func test_mode_ends_in_battle():
	var b = battle({"waves": [[{"kind": "basic", "count": 1}]]})
	var c = controls(b)
	_key(c, KEY_1)
	b.start_battle()
	click(c, MOUSE_BUTTON_LEFT, px(Vector2i(5, 5)))
	return check(c.placing == "", "전투 중에도 놓기 모드다")

# 전투가 시작된 뒤 첫 입력이 놓기 키여도 모드가 켜져, 좌클릭으로 공병에게 건설을 지시한다
func test_structure_key_first_after_battle_start():
	var b = battle({"waves": [[{"kind": "basic", "count": 1}]]})
	var c = controls(b)
	b.place_merc("engineer", Vector2i(5, 8))
	b.start_battle()
	_key(c, KEY_2)
	click(c, MOUSE_BUTTON_LEFT, px(Vector2i(5, 5)))
	var s = b.structure_at(Vector2i(5, 5))
	return check(s != null and not s.complete, "전투 시작 뒤 2 → 좌클릭으로 지어지지 않았다(모드 %s)" % c.placing)
