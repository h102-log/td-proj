extends RefCounted
# 피격 반응(S177)의 «방금 맞음» 표가 근접은 돌진이 닿은 때부터, 원거리는 투사체가 닿은 때부터 세고, 영웅이 낀 타격은 닿은 때 3프레임 멈추는지 본다(WBS 4.1f).
# 지키는 요구:
#   S177. 맞은 영웅·용병·적은 0.1초 흰 번쩍임과 공격자 반대쪽 밀림을 보이고, 영웅이 치거나 맞은 타격은 두 유닛의 그림만 3프레임 멈춘다.
#   S178. 원거리 공격은 투사체로 그리고, 맞은 반응은 투사체가 닿는 때 난다.
#   S179. 즉시 스킬은 쓴 곳·맞은 대상을 흔적으로 남기고, 스킬에 맞은 적도 피격 반응을 보인다.
#   S180. 쓰러진 적·용병은 2초 동안 누운 몸으로 남고, 쓰러진 영웅은 복귀할 때까지 누운 몸으로 남는다.
#   S198. 보스 스킬 발동과 보스 타격: 맞은 아군은 6px·0.25초 밀리고, 넉백은 미끄러지며(성벽 오르내리기는 빼고), 끊기면 조각이 흩어지고, 보스에 가린 영웅을 덧그린다.
#   I171. 화면 사건 목록: 닿음은 공격 하나에 한 번, 처치는 쓰러진 대상을 노린 마지막 공격이 닿을 때(기다릴 공격이 없으면 바로) 난다.

const View := preload("res://src/ui/battle_view.gd")
const DT := 1.0 / 60.0

# 빈 판(준비 단계)과 그 판을 그리는 화면. 배치를 끝내면 _go로 전투를 시작한다
func _board() -> Array:
	var b = load("res://src/sim/battle.gd").new({"size": Vector2i(20, 20), "base": Vector2i(18, 18), "base_hp": 100, "spawns": [Vector2i(0, 10)], "hero_start": Vector2i(5, 5), "waves": [[{"kind": "basic", "count": 1}]]})
	b.gold = 1 << 20
	var v = View.new()
	v.battle = b
	return [b, v]

# 전투를 시작하고 화면 시계를 한 번 돌려 둔다(첫 tick은 있던 것을 기억만 한다)
func _go(b, v) -> void:
	b.start_battle()
	v.tick(0.0)

# 화면 시계를 dt만큼 n번 돌리며 그 사이 난 사건 종류를 모은다. 시뮬레이션은 돌리지 않는다(공격자의 친 뒤 시간은 시험이 흘린다)
func _ticks(v, n: int, dt: float, attackers := []) -> Array:
	var got := []
	for i in n:
		for x in attackers:
			x.cooldown -= dt
		v.tick(dt)
		got.append_array(v.events.map(func(e): return e.kind))
	return got

func test_contact_event_once_per_attack():
	var s := _board()
	var b = s[0]
	var v = s[1]
	var foe = b.spawn_enemy("basic", Vector2i(10, 5), {"speed": 0, "damage": 0, "hp": 1000})
	var soldier = b.place_merc("soldier", Vector2i(9, 5))
	var archer = b.place_merc("archer", Vector2i(10, 9))
	_go(b, v)
	soldier.target = foe
	soldier.cooldown = soldier.attack_gap  # 막 쳤다
	var why := ""
	var got := _ticks(v, 4, DT, [soldier])
	if got.has("hit"):
		why = "근접이 돌진 끝(%s초)에 닿기 전에 닿음 사건이 났다(%s)" % [View.CONTACT, got]
	got = _ticks(v, 20, DT, [soldier])
	if why == "" and got.count("hit") != 1:
		why = "근접 한 번에 닿음 사건이 %d번이다(1번이어야 한다)" % got.count("hit")
	soldier.cooldown = soldier.attack_gap  # 새 공격을 0.1초 한 프레임에 건너뛰어도 닿음은 한 번이다
	got = _ticks(v, 1, 0.1, [soldier]) + _ticks(v, 5, 0.1, [soldier])
	if why == "" and (got.count("hit") != 1 or got.count("fire") != 1):
		why = "새 공격을 0.1초씩 건너뛰었더니 닿음 %d번·쏨 %d번이다(1번씩이어야 한다)" % [got.count("hit"), got.count("fire")]
	soldier.target = null
	archer.target = foe
	archer.cooldown = archer.attack_gap
	var fly: float = v._contact(archer)
	got = _ticks(v, int(ceilf(fly / DT)) + 1, DT, [archer])
	foe.pos += Vector2(0, -3)  # 화살이 닿은 뒤 대상이 멀리 밀려 닿는 때가 늦어져도 다시 닿지 않는다
	got += _ticks(v, 40, DT, [archer])
	if why == "" and got.count("hit") != 1:
		why = "화살 한 발에 닿음 사건이 %d번이다(닿은 뒤 대상이 밀려도 1번이어야 한다)" % got.count("hit")
	v.free()
	return why

func test_kill_event_waits_for_last_contact():
	var s := _board()
	var b = s[0]
	var v = s[1]
	var foe = b.spawn_enemy("basic", Vector2i(10, 5), {"speed": 0, "damage": 0})
	var other = b.spawn_enemy("basic", Vector2i(14, 5), {"speed": 0, "damage": 0})
	var archer = b.place_merc("archer", Vector2i(10, 9))
	_go(b, v)
	archer.target = foe
	archer.cooldown = archer.attack_gap  # 쏜 때 쓰러진다(시뮬레이션은 쏜 때 피해를 준다, S178)
	b.damage(foe, 1e9, "true")
	var fly: float = v._contact(archer)
	var why := ""
	var got := _ticks(v, int(fly / DT) - 1, DT, [archer])
	if got.has("kill"):
		why = "화살이 닿기 전(%s초)에 처치 사건이 났다(%s)" % [fly, got]
	got = _ticks(v, 10, DT, [archer])
	if why == "" and (got.count("kill") != 1 or got.has("hit")):
		why = "화살이 닿을 때 처치 사건 1번이어야 하는데 %s다" % [got]
	b.damage(other, 1e9, "true")  # 노린 공격이 없는 죽음(지속 피해 같은)은 바로 처치 사건이다
	got = _ticks(v, 1, DT)
	if why == "" and got.count("kill") != 1:
		why = "노린 공격 없이 쓰러진 적의 처치 사건이 다음 프레임에 %s다" % [got]
	v.free()
	return why

# 오우거와 둘레 1칸의 용병 셋(체력 큼, 치지 않음)이 강타가 나올 때까지 시뮬레이션과 화면을 함께 돌린다
func _slam() -> Array:
	var s := _board()
	var b = s[0]
	var v = s[1]
	var e = b.spawn_enemy("boss", Vector2i(10, 10), {"speed": 0})
	var ms := []
	for c in [Vector2i(11, 10), Vector2i(10, 9), Vector2i(10, 11)]:
		ms.append(b.place_merc("soldier", c, {"hp": 1 << 20, "damage": 0, "range": 0, "sight": 0}))
	_go(b, v)
	for i in 180:
		b.step(DT)
		v.tick(DT)
		if v.events.any(func(x): return x.kind == "boss"):
			return [b, v, e, ms]
	return [b, v, e, ms, "3초 안에 강타가 나지 않았다"]

func test_boss_slam_pushes_heavy_and_slides():
	var s := _slam()
	var b = s[0]
	var v = s[1]
	var e = s[2]
	var ms: Array = s[3]
	var why: String = s[4] if s.size() > 4 else ""
	v._hits = v.hit_table(b.units + b.enemies)
	var h = v._hits.get(ms[0].get_instance_id())
	if why == "" and (h == null or not h[2] or not is_equal_approx(v._flinch(ms[0]).length(), View.HEAVY)):
		why = "강타에 맞은 용병의 표가 %s, 밀림 %s px다(무거운 타격, 6px이어야 한다)" % [h, v._flinch(ms[0]).length() if h else 0.0]
	if why == "" and (v._boss_trace(e) == null or v._slip(ms[0]).length() < 8.0):
		why = "강타 직후 보스 자세 흔적 %s, 넉백된 용병의 미끄러짐 %s px다(흔적이 있고 8px 넘게 뒤에 그려야 한다)" % [v._boss_trace(e), v._slip(ms[0]).length()]
	for i in 4:
		b.step(DT)
		v.tick(DT)
	var mid: float = v._slip(ms[0]).length()
	for i in 5:
		b.step(DT)
		v.tick(DT)
	if why == "" and (mid <= 0.5 or v._slip(ms[0]).length() > 0.0 or v._boss_trace(e) != null):
		why = "0.07초에 미끄러짐 %s px(중간), 0.15초에 %s px(0), 보스 자세 흔적 %s(없음)여야 한다" % [mid, v._slip(ms[0]).length(), v._boss_trace(e)]
	v._hits = v.hit_table(b.units + b.enemies)
	if why == "" and not v._hits.has(ms[0].get_instance_id()):
		why = "무거운 밀림은 0.25초 동안이라 0.15초에는 아직 표에 있어야 한다"
	v.free()
	return why

func test_wall_step_does_not_slide():
	var s := _board()
	var b = s[0]
	var v = s[1]
	var m = b.place_merc("soldier", Vector2i(9, 5))
	_go(b, v)
	v.tick(DT)
	m.pos += Vector2(1, 0)  # 같은 땅에서 한 칸 튐: 미끄러진다
	v.tick(DT)
	var why := ""
	if not v._slides.has(m.get_instance_id()):
		why = "땅에서 한 칸 튄 몸이 미끄러지지 않았다"
	v.tick(0.2)
	m.pos += Vector2(0, -1)  # 성문으로 성벽에 오름: 높이가 바로 바뀌므로 미끄러지지 않는다
	m.on_wall = true
	v.tick(DT)
	if why == "" and v._slides.has(m.get_instance_id()):
		why = "성벽에 오른 스텝이 미끄러졌다"
	v.free()
	return why

func test_interrupted_slam_scatters_shards():
	var s := _board()
	var b = s[0]
	var v = s[1]
	var e = b.spawn_enemy("boss", Vector2i(10, 10), {"speed": 0})
	for c in [Vector2i(11, 10), Vector2i(10, 9), Vector2i(10, 11)]:
		b.place_merc("soldier", c, {"hp": 1 << 20, "damage": 0, "range": 0, "sight": 0})
	_go(b, v)
	var why := ""
	for i in 30:
		b.step(DT)
		v.tick(DT)
		if e.cast:
			break
	if e.cast == null:
		why = "예고를 시작하지 않았다"
	e.fx["test_stun"] = {"stun": true, "left": 1.0}
	b.step(DT)
	v.tick(DT)
	var n: int = v._dots.filter(func(d): return not d.ground).size()
	if why == "" and (not v.events.any(func(x): return x.kind == "interrupt") or n != 12):
		why = "기절로 끊긴 프레임에 끊김 사건 %s, 조각 %d개다(12개여야 한다)" % [v.events.map(func(x): return x.kind), n]
	for i in 12:
		b.step(DT)
		v.tick(DT)
	if why == "" and v._dots.filter(func(d): return not d.ground).size() != 12:
		why = "0.2초에는 조각이 남아야 한다"
	for i in 12:
		b.step(DT)
		v.tick(DT)
	if why == "" and not v._dots.filter(func(d): return not d.ground).is_empty():
		why = "0.4초에는 조각이 없어야 한다"
	v.free()
	return why

func test_hero_under_boss_is_ghosted():
	var s := _board()
	var b = s[0]
	var v = s[1]
	var e = b.spawn_enemy("boss", Vector2i(5, 5), {"speed": 0})  # 영웅(5,5)과 같은 칸: 보스가 나중에 그려져 덮는다
	_go(b, v)
	var why := ""
	if not v._under_boss(b.hero):
		why = "보스와 같은 칸에 선 영웅을 가렸다고 보지 않았다"
	e.pos = Vector2(5, 3)  # 보스가 영웅 뒤(위)에 서면 영웅이 나중에 그려진다
	if why == "" and v._under_boss(b.hero):
		why = "영웅 뒤에 선 보스를 영웅을 가린다고 봤다"
	v.free()
	return why

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
