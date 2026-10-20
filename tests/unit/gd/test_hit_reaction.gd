extends RefCounted
# 피격 반응(S177)의 «방금 맞음» 표가 근접은 돌진이 닿은 때부터, 원거리는 투사체가 닿은 때부터 세고, 영웅이 낀 타격은 닿은 때 3프레임 멈추는지 본다(WBS 4.1f).
# 지키는 요구:
#   S177. 맞은 영웅·용병·적은 0.1초 흰 번쩍임과 공격자 반대쪽 밀림을 보이고, 영웅이 치거나 맞은 타격은 두 유닛의 그림만 3프레임 멈춘다.
#   S178. 원거리 공격은 투사체로 그리고, 맞은 반응은 투사체가 닿는 때 난다.
#   S179. 즉시 스킬은 쓴 곳·맞은 대상을 흔적으로 남기고, 스킬에 맞은 적도 피격 반응을 보인다.
#   S180. 쓰러진 적·용병은 2초 동안 누운 몸으로 남고, 쓰러진 영웅은 복귀할 때까지 누운 몸으로 남는다.

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
	archer.target = foe
	var fly: float = v._flight(archer)  # 궁수 손에서 적 몸통까지 화살이 나는 시간(S178)
	if why == "" and _hit(v, archer, foe, View.CONTACT + fly - 0.02) != null:
		why = "궁수(원거리)의 화살이 닿기 전에 맞은 것으로 셌다(나는 시간 %s초)" % fly
	h = _hit(v, archer, foe, View.CONTACT + fly + 0.05)
	if why == "" and (fly <= 0.0 or h == null or not is_equal_approx(h[0], 0.05)):
		why = "궁수의 화살이 닿고 0.05초인데 표가 %s다(나는 시간 %s초)" % [h, fly]
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
	archer.cooldown = archer.attack_gap - (View.CONTACT + fly + 0.04)
	h = v.hit_table([soldier, archer]).get(foe.get_instance_id())
	if why == "" and (h == null or not is_equal_approx(h[0], 0.04)):
		why = "둘에게 맞으면 가장 최근 타격(0.04초)이어야 하는데 %s다" % [h]
	v.free()
	return why

func test_skill_trace_marks_hit_enemy_then_fades():
	var b = load("res://src/sim/battle.gd").new({"size": Vector2i(20, 20), "base": Vector2i(18, 18), "base_hp": 100, "spawns": [Vector2i(0, 10)], "hero_start": Vector2i(5, 5), "waves": [[{"kind": "basic", "count": 1}]]})
	b.start_battle()
	var v = View.new()
	v.battle = b
	var front = b.spawn_enemy("basic", Vector2i(6, 5), {"speed": 0, "damage": 0, "hp": 1000})
	var why := ""
	if not b.cast(b.hero, "q", Vector2(7, 5)):
		why = "아이아스 Q(방패 강타)를 쓰지 못했다"
	var c = b.traces[-1] if not b.traces.is_empty() else null
	if why == "" and (c == null or c.slot != "q" or c.hits != [front] or c.at != b.hero.pos):
		why = "방패 강타 흔적이 %s다(Q, 맞은 적은 앞의 적 하나, 가운데는 영웅 자리여야 한다)" % [c]
	var h = v.hit_table([]).get(front.get_instance_id())
	if why == "" and (h == null or h[0] != 0.0 or not h[1].is_equal_approx(Vector2.RIGHT)):
		why = "스킬에 맞은 적의 표가 %s다(0초, 오른쪽으로 밀림이어야 한다)" % [h]
	for i in 12:
		b.step(1.0 / 60.0)
	if why == "" and (v.hit_table([]).has(front.get_instance_id()) or b.traces.is_empty()):
		why = "0.2초 뒤에는 피격 반응이 끝나고 흔적은 남아야 하는데 표 %s, 흔적 %s개다" % [v.hit_table([]), b.traces.size()]
	for i in 60:
		b.step(1.0 / 60.0)
	if why == "" and not b.traces.is_empty():
		why = "1초가 지난 흔적이 남았다"
	v.free()
	return why

func test_fallen_body_stays_then_clears_but_hero_stays():
	var b = load("res://src/sim/battle.gd").new({"size": Vector2i(20, 20), "base": Vector2i(18, 18), "base_hp": 100, "spawns": [Vector2i(0, 10)], "hero_start": Vector2i(5, 5), "waves": [[{"kind": "basic", "count": 1}]]})
	b.start_battle()
	var v = View.new()
	v.battle = b
	var foe = b.spawn_enemy("basic", Vector2i(10, 5), {"speed": 0})
	var why := ""
	b.damage(foe, 1e9, "true")
	b.damage(b.hero, 1e9, "true")
	var d: Array = v._fallen().map(func(x): return x[0])
	if d != [foe, b.hero]:
		why = "쓰러진 직후 그릴 몸이 %s다(적, 영웅 순이어야 한다)" % [d]
	for i in 90:
		b.step(1.0 / 60.0)
	if why == "" and v._fallen().size() != 2:
		why = "1.5초 뒤에도 적의 몸은 남아야 하는데 %s개다" % v._fallen().size()
	for i in 31:
		b.step(1.0 / 60.0)
	d = v._fallen()
	if why == "" and (not b.fallen.is_empty() or d.size() != 1 or d[0][0] != b.hero or d[0][1] != b.FALLEN):
		why = "2초 뒤에는 적의 몸은 지워지고 영웅만 마지막 자세(%s초)로 남아야 하는데 시뮬레이션 %s개, 그릴 몸 %s다" % [b.FALLEN, b.fallen.size(), d]
	v.free()
	return why
