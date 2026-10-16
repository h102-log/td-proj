extends RefCounted
# 영웅 스킬을 Q로 쓰면 주변 적만 다치고, 재사용 대기 동안은 다시 쓰이지 않는지 본다(WBS 2.6).
# 지키는 요구:
#   S15. 영웅은 적을 자동으로 공격하고, 스킬은 플레이어가 직접 쓴다.
#   I10. 영웅 스킬은 키보드 단축키로도 쓸 수 있다.
#   I33. W1에서는 스킬 1개(주변 1.5칸 광역 피해, 사용자 2026-10-12)만 만든다.
#   S136. Q·W는 전투 단계에만 쓴다. 그래서 전투 단계를 연 뒤 누른다.

func _press_q(c) -> void:
	var ev := InputEventKey.new()
	ev.keycode = KEY_Q
	ev.pressed = true
	c.handle(ev)

func test_q_skill_hits_only_nearby_enemies_once_per_cooldown():
	var b = load("res://src/sim/battle.gd").new({"size": Vector2i(20, 20), "base": Vector2i(18, 18), "base_hp": 100, "spawns": [Vector2i(0, 10)], "hero_start": Vector2i(5, 5), "waves": [[{"kind": "basic", "count": 1}]]})
	var c = load("res://src/ui/controls.gd").new(b, 16)
	b.start_battle()
	var near = b.spawn_enemy("basic", Vector2i(6, 5), {"speed": 0, "damage": 0, "hp": 1000})
	var far = b.spawn_enemy("basic", Vector2i(9, 5), {"speed": 0, "damage": 0, "hp": 1000})
	_press_q(c)
	_press_q(c)
	if b.hero.skill_uses != 1:
		return "Q 두 번에 스킬을 %d번 썼다(대기 중에는 쓰이지 않아야 한다)" % b.hero.skill_uses
	if near.max_hp - near.hp != b.hero.skill_damage:
		return "1칸 옆 적이 스킬 피해를 받지 않았다: %s" % near.hp
	return "" if far.hp == far.max_hp else "4칸 떨어진 적이 스킬 피해를 받았다"
