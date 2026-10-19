extends RefCounted
# 영웅 스킬 Q를 키와 클릭으로 쓰면 클릭한 쪽의 가까운 적만 다치고, 재사용 대기 동안은 다시 쓰이지 않는지 본다(WBS 2.6, 2026-10-18 영웅 개편).
# 지키는 요구:
#   S15. 영웅은 적을 자동으로 공격하고, 스킬은 플레이어가 직접 쓴다.
#   I10. 영웅 스킬은 키보드 단축키로도 쓸 수 있다.
#   S147. 방향을 고르는 칸은 키를 누르면 조준 상태가 되고, 좌클릭한 쪽에 쓴다.
#   S151. 아이아스 Q는 지점 쪽 반경 2·90° 부채꼴 안 적에게 물리 피해를 준다.
#   S136. 스킬은 전투 단계에만 쓴다. 그래서 전투 단계를 연 뒤 누른다.

func _press_q(c) -> void:
	var ev := InputEventKey.new()
	ev.keycode = KEY_Q
	ev.pressed = true
	c.handle(ev)

func _click(c, cell: Vector2i) -> void:
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		ev.position = Vector2(cell) * 16 + Vector2(8, 8)
		c.handle(ev)

func test_q_skill_hits_only_enemies_toward_click_once_per_cooldown():
	var b = load("res://src/sim/battle.gd").new({"size": Vector2i(20, 20), "base": Vector2i(18, 18), "base_hp": 100, "spawns": [Vector2i(0, 10)], "hero_start": Vector2i(5, 5), "waves": [[{"kind": "basic", "count": 1}]]})
	var c = load("res://src/ui/controls.gd").new(b, 16)
	b.start_battle()
	var front = b.spawn_enemy("basic", Vector2i(6, 5), {"speed": 0, "damage": 0, "hp": 1000})
	var back = b.spawn_enemy("basic", Vector2i(4, 5), {"speed": 0, "damage": 0, "hp": 1000})
	var far = b.spawn_enemy("basic", Vector2i(9, 5), {"speed": 0, "damage": 0, "hp": 1000})
	_press_q(c)
	if c.aiming != "q" or b.hero.skill_uses != 0:
		return "Q 키에 조준 상태가 되지 않았거나 바로 썼다(조준 «%s», %d번)" % [c.aiming, b.hero.skill_uses]
	_click(c, Vector2i(8, 5))
	_press_q(c)
	_click(c, Vector2i(8, 5))
	if b.hero.skill_uses != 1:
		return "Q 두 번에 스킬을 %d번 썼다(대기 중에는 쓰이지 않아야 한다)" % b.hero.skill_uses
	if front.max_hp - front.hp != b.hero.q.damage:
		return "클릭한 쪽 1칸 앞 적이 스킬 피해를 받지 않았다: %s" % front.hp
	return "" if back.hp == back.max_hp and far.hp == far.max_hp else "뒤쪽 적이나 4칸 떨어진 적이 스킬 피해를 받았다"
