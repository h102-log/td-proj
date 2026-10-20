extends RefCounted
# 피격 반응(S177)의 «방금 맞음» 표가 근접은 돌진이 닿은 때부터, 원거리는 쏜 때부터 세고, 영웅이 낀 타격은 닿은 때 3프레임 멈추는지 본다(WBS 4.1f).
# 지키는 요구:
#   S177. 맞은 영웅·용병·적은 0.1초 흰 번쩍임과 공격자 반대쪽 밀림을 보이고, 영웅이 치거나 맞은 타격은 두 유닛의 그림만 3프레임 멈춘다.

const View := preload("res://src/ui/battle_view.gd")

func _hit(v, attacker, target, ago: float):  # attacker가 ago초 전에 target을 친 것으로 두고 target의 표 칸을 돌려준다
	attacker.target = target
	attacker.cooldown = attacker.attack_gap - ago
	return v.hit_table([attacker]).get(target.get_instance_id())

func test_hit_table_counts_from_contact_and_holds_hero_hits():
	var b = load("res://src/sim/battle.gd").new({"size": Vector2i(20, 20), "base": Vector2i(18, 18), "base_hp": 100, "spawns": [Vector2i(0, 10)], "hero_start": Vector2i(5, 5), "waves": [[{"kind": "basic", "count": 1}]]})
	b.gold = 1 << 20
	var v = View.new()
	v.battle = b
	var foe = b.spawn_enemy("basic", Vector2i(10, 5))
	var soldier = b.place_merc("soldier", Vector2i(9, 5))
	var archer = b.place_merc("archer", Vector2i(10, 9))
	var why := ""
	if _hit(v, soldier, foe, View.CONTACT - 0.02) != null:
		why = "근접이 돌진 끝에 닿기 전에 맞은 것으로 셌다"
	var h = _hit(v, soldier, foe, View.CONTACT + 0.05)
	if why == "" and (h == null or not is_equal_approx(h[0], 0.05) or not h[1].is_equal_approx(Vector2.RIGHT)):
		why = "병사가 닿은 뒤 0.05초인데 표가 %s다(0.05초, 오른쪽으로 밀림이어야 한다)" % [h]
	h = _hit(v, archer, foe, 0.05)
	if why == "" and (h == null or not is_equal_approx(h[0], 0.05)):
		why = "궁수(원거리)는 쏜 때부터 세야 하는데 표가 %s다" % [h]
	h = _hit(v, b.hero, foe, View.CONTACT + 0.03)
	if why == "" and (h == null or h[0] != 0.0 or v._ago(b.hero) != View.CONTACT):
		why = "영웅 타격 정지(3프레임) 중인데 대상 %s, 영웅 자세 시간 %s다(0초, 닿은 때여야 한다)" % [h, v._ago(b.hero)]
	h = _hit(v, b.hero, foe, View.CONTACT + View.HITSTOP + 0.02)
	if why == "" and (h == null or not is_equal_approx(h[0], 0.02)):
		why = "영웅 타격 정지가 끝난 뒤 0.02초인데 표가 %s다" % [h]
	h = _hit(v, foe, b.hero, View.CONTACT + 0.03)
	if why == "" and (h == null or h[0] != 0.0):
		why = "적이 영웅을 친 타격도 멈춰야 하는데 표가 %s다" % [h]
	soldier.target = foe
	soldier.cooldown = soldier.attack_gap - (View.CONTACT + 0.1)
	archer.target = foe
	archer.cooldown = archer.attack_gap - 0.04
	h = v.hit_table([soldier, archer]).get(foe.get_instance_id())
	if why == "" and (h == null or not is_equal_approx(h[0], 0.04)):
		why = "둘에게 맞으면 가장 최근 타격(0.04초)이어야 하는데 %s다" % [h]
	v.free()
	return why
