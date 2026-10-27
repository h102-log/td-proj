extends RefCounted
# 피격 반응(S177)의 «방금 맞음» 표가 근접은 돌진이 닿은 때부터, 원거리는 시뮬레이션 투사체가 닿은 때(battle.landed)부터 세고, 영웅이 낀 타격은 닿은 때 3프레임 멈추는지 본다(WBS 4.1f).
# 지키는 요구:
#   S177. 맞은 영웅·용병·적은 0.1초 흰 번쩍임과 공격자 반대쪽 밀림을 보이고, 영웅이 치거나 맞은 타격은 두 유닛의 그림만 3프레임 멈춘다.
#   S178. 원거리 공격은 투사체로 그리고, 피해와 맞은 반응은 시뮬레이션 투사체가 닿는 때 난다(2026-10-25 변경).
#   S179. 즉시 스킬은 쓴 곳·맞은 대상을 흔적으로 남기고, 스킬에 맞은 적도 피격 반응을 보인다.
#   S180. 쓰러진 적·용병은 2초 동안 누운 몸으로 남고, 쓰러진 영웅은 복귀할 때까지 누운 몸으로 남는다.
#   S197. 근접 막타는 닿을 때까지 선 자세로 서 있고, 막타가 닿으면 0.1초 흰 실루엣으로 공격자 반대쪽 6px 밀려 그 자리에 눕는다.
#         원거리는 착탄 때, 즉시 스킬은 흔적 가운데 반대쪽으로 같고, 닿는 공격이 없는 죽음은 바로 눕는다. 영웅 X는 막타가 닿은 때부터 밀린 자리에.
#   S198. 보스 스킬 발동과 보스 타격: 맞은 아군은 6px·0.25초 밀리고, 넉백은 미끄러지며(성벽 오르내리기는 빼고), 끊기면 조각이 흩어지고, 보스에 가린 영웅을 덧그린다.
#   S199. 맞은 구조물·성곽 칸·거점은 닿은 뒤 0.05초 공격자 반대쪽으로 1px 흔들리고 부스러기 2점이 튀며, 체력 75·50·25% 밑이면 금 1·2·3줄,
#         맵 위 막대는 50% 밑 노랑·25% 밑 빨강이다(유닛 막대는 초록 그대로). 금은 구운 아틀라스 사본에서 단계가 오를수록 한 줄씩 늘어난다.
#   I171. 화면 사건 목록: 닿음은 공격 하나에 한 번, 처치는 쓰러진 대상을 노린 마지막 공격이 닿을 때(기다릴 공격이 없으면 바로) 난다.
#         원거리는 시뮬레이션 투사체가 닿은 프레임에 투사체 하나에 한 번이다.

const View := preload("res://src/ui/battle_view.gd")
const Battle := preload("res://src/sim/battle.gd")
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

# 시뮬레이션과 화면 시계를 함께 dt만큼 n번 돌리며 그 사이 난 사건 종류를 모은다(원거리 공격은 시뮬레이션 투사체가 닿는 때를 정한다)
func _play(b, v, n: int, dt: float) -> Array:
	var got := []
	for i in n:
		b.step(dt)
		v.tick(dt)
		got.append_array(v.events.map(func(e): return e.kind))
	return got

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
	v.free()
	s = _board()  # 원거리: 궁수가 시뮬레이션에서 화살 한 발을 쏜다(공격 간격 1초라 0.9초 동안 한 발)
	b = s[0]
	v = s[1]
	var far = b.spawn_enemy("basic", Vector2i(10, 5), {"speed": 0, "damage": 0, "hp": 1000})
	b.place_merc("archer", Vector2i(10, 9))
	v.tick(0.0)
	got = _play(b, v, 3, DT)
	if why == "" and got.has("hit"):
		why = "화살이 4칸을 날아 닿기 전(0.05초)에 닿음 사건이 났다(%s)" % [got]
	got += _play(b, v, 51, DT)
	if why == "" and (got.count("hit") != 1 or got.count("fire") != 1 or far.hp == far.max_hp):
		why = "화살 한 발에 쏨 %d번·닿음 %d번·과녁 체력 %s다(1번씩, 줄어야 한다)" % [got.count("fire"), got.count("hit"), far.hp]
	v.free()
	return why

func test_kill_event_waits_for_last_contact():
	var s := _board()
	var b = s[0]
	var v = s[1]
	var foe = b.spawn_enemy("basic", Vector2i(10, 5), {"speed": 0, "damage": 0})
	var other = b.spawn_enemy("basic", Vector2i(14, 5), {"speed": 0, "damage": 0})
	var soldier = b.place_merc("soldier", Vector2i(9, 5))
	_go(b, v)
	soldier.target = foe
	soldier.cooldown = soldier.attack_gap  # 친 때 쓰러진다(근접은 시뮬레이션이 친 때 피해를 준다)
	b.damage(foe, 1e9, "true")
	var why := ""
	var got := _ticks(v, 4, DT, [soldier])
	if got.has("kill"):
		why = "근접이 돌진 끝(%s초)에 닿기 전에 처치 사건이 났다(%s)" % [View.CONTACT, got]
	got = _ticks(v, 10, DT, [soldier])
	if why == "" and (got.count("kill") != 1 or got.has("hit")):
		why = "근접이 닿을 때 처치 사건 1번이어야 하는데 %s다" % [got]
	b.damage(other, 1e9, "true")  # 노린 공격이 없는 죽음(지속 피해 같은)은 바로 처치 사건이다
	got = _ticks(v, 1, DT)
	if why == "" and got.count("kill") != 1:
		why = "노린 공격 없이 쓰러진 적의 처치 사건이 다음 프레임에 %s다" % [got]
	v.free()
	s = _board()  # 원거리: 화살에 쓰러지면 쓰러진 그 프레임에 처치 사건이고 닿음 사건은 없다(S178)
	b = s[0]
	v = s[1]
	var weak = b.spawn_enemy("basic", Vector2i(10, 5), {"speed": 0, "damage": 0, "hp": 1.0})
	b.place_merc("archer", Vector2i(10, 9))
	v.tick(0.0)
	var frames := []
	for i in 30:
		b.step(DT)
		v.tick(DT)
		frames.append([weak.alive, v.events.map(func(e): return e.kind)])
	var died: int = frames.map(func(f): return f[0]).find(false)
	var kills := []
	for i in frames.size():
		if "kill" in frames[i][1]:
			kills.append(i)
		if why == "" and "hit" in frames[i][1]:
			why = "화살에 쓰러진 적에게 닿음 사건이 났다(%d프레임)" % i
	if why == "" and (died <= 0 or kills != [died]):
		why = "화살에 쓰러진 프레임 %d인데 처치 사건 프레임이 %s다(그 프레임 한 번이어야 한다)" % [died, kills]
	v.free()
	return why

# 막타 단계(S197) 하나를 견준다: [선 자세, 흰 번쩍임, 밀린 px]
func _blow(v, x, up: bool, white: bool, push: Vector2) -> bool:
	var s: Array = v._last_blow(x)
	return s[0] == up and s[1] == white and s[2].is_equal_approx(push)

func test_melee_kill_stands_until_contact_then_flashes_and_lies_pushed():
	var s := _board()
	var b = s[0]
	var v = s[1]
	var foe = b.spawn_enemy("basic", Vector2i(10, 5), {"speed": 0, "damage": 0})
	var other = b.spawn_enemy("basic", Vector2i(14, 5), {"speed": 0, "damage": 0})
	var soldier = b.place_merc("soldier", Vector2i(9, 5))
	_go(b, v)
	soldier.target = foe
	soldier.cooldown = soldier.attack_gap  # 친 때 쓰러진다(근접은 시뮬레이션이 친 때 피해를 준다)
	b.damage(foe, 1e9, "true")
	var why := ""
	_ticks(v, 1, DT, [soldier])
	if not _blow(v, foe, true, false, Vector2.ZERO):
		why = "근접 막타가 닿기 전에는 번쩍임 없이 그 자리에 서 있어야 하는데 %s다" % [v._last_blow(foe)]
	var got := []
	for i in 15:
		got = _ticks(v, 1, DT, [soldier])
		if got.has("kill"):
			break
	if why == "" and not got.has("kill"):
		why = "근접 막타가 닿지 않았다"
	_ticks(v, 3, DT, [soldier])
	if why == "" and not _blow(v, foe, true, true, Vector2(View.KILL_PUSH * 3.0 * DT / View.FLASH, 0)):
		why = "막타가 닿고 0.05초에는 선 자세 흰 실루엣으로 오른쪽으로 밀리는 중이어야 하는데 %s다" % [v._last_blow(foe)]
	_ticks(v, 4, DT, [soldier])
	if why == "" and not _blow(v, foe, false, false, Vector2(View.KILL_PUSH, 0)):
		why = "막타가 닿고 0.12초에는 공격자 반대쪽(오른쪽) %spx 밀린 자리에 누워야 하는데 %s다" % [View.KILL_PUSH, v._last_blow(foe)]
	b.damage(other, 1e9, "true")  # 닿는 공격이 없는 죽음(지속 피해 같은)은 바로 눕고 번쩍이지 않는다
	_ticks(v, 1, DT)
	if why == "" and not _blow(v, other, false, false, Vector2.ZERO):
		why = "노린 공격 없이 쓰러진 적은 바로 누워야 하는데 %s다" % [v._last_blow(other)]
	v.free()
	return why

func test_ranged_and_skill_kills_flash_and_push_at_once():
	var s := _board()  # 화살: 쓰러진 그 프레임(착탄)부터 번쩍이며 위로 밀린다(궁수는 아래에 있다)
	var b = s[0]
	var v = s[1]
	var weak = b.spawn_enemy("basic", Vector2i(10, 5), {"speed": 0, "damage": 0, "hp": 1.0})
	b.place_merc("archer", Vector2i(10, 9))
	v.tick(0.0)
	var why := ""
	for i in 60:
		b.step(DT)
		v.tick(DT)
		if not weak.alive:
			break
	if weak.alive:
		why = "화살이 1초 안에 적을 쓰러뜨리지 못했다"
	elif not _blow(v, weak, true, true, Vector2.ZERO):
		why = "화살에 쓰러진 프레임에는 선 자세 흰 실루엣이어야 하는데 %s다" % [v._last_blow(weak)]
	_play(b, v, 7, DT)
	if why == "" and not _blow(v, weak, false, false, Vector2(0, -View.KILL_PUSH)):
		why = "화살 막타 0.12초 뒤에는 위로 %spx 밀린 자리에 누워야 하는데 %s다" % [View.KILL_PUSH, v._last_blow(weak)]
	v.free()
	b = load("res://src/sim/battle.gd").new({"size": Vector2i(20, 20), "base": Vector2i(18, 18), "base_hp": 100, "spawns": [Vector2i(0, 10)], "hero_start": Vector2i(5, 5), "waves": [[{"kind": "basic", "count": 1}]]})
	b.start_battle()
	v = View.new()
	v.battle = b
	var front = b.spawn_enemy("basic", Vector2i(6, 5), {"speed": 0, "damage": 0, "hp": 1.0})
	v.tick(0.0)
	if why == "" and not b.cast(b.hero, "q", Vector2(7, 5)):
		why = "아이아스 Q(방패 강타)를 쓰지 못했다"
	v.tick(DT)
	if why == "" and (front.alive or not _blow(v, front, true, true, Vector2.ZERO)):
		why = "방패 강타에 쓰러진 적은 쓴 때 선 자세 흰 실루엣이어야 하는데 살아 있음 %s · %s다" % [front.alive, v._last_blow(front)]
	_ticks(v, 7, DT)
	if why == "" and not _blow(v, front, false, false, Vector2(View.KILL_PUSH, 0)):
		why = "방패 강타 0.12초 뒤에는 흔적 가운데(영웅) 반대쪽(오른쪽) %spx에 누워야 하는데 %s다" % [View.KILL_PUSH, v._last_blow(front)]
	v.free()
	return why

func test_hero_cross_waits_for_contact_and_sits_at_pushed_spot():
	var s := _board()
	var b = s[0]
	var v = s[1]
	var h = b.hero
	var foe = b.spawn_enemy("basic", Vector2i(h.pos.round()) + Vector2i(-1, 0), {"speed": 0})
	_go(b, v)
	foe.target = h
	foe.cooldown = foe.attack_gap
	b.damage(h, 1e9, "true")
	var why := ""
	_ticks(v, 1, DT, [foe])
	if v._cross_at(h) != null:
		why = "적의 근접 막타가 닿기 전에 영웅 X가 떴다"
	for i in 20:
		if v._cross_at(h) != null:
			break
		_ticks(v, 1, DT, [foe])
	_ticks(v, 7, DT, [foe])
	var c = v._cross_at(h)
	if why == "" and (c == null or not c.is_equal_approx(v._spot(h) + Vector2(View.KILL_PUSH, 0))):
		why = "막타가 닿은 뒤 영웅 X는 오른쪽으로 %spx 밀린 자리여야 하는데 %s다(발밑 %s)" % [View.KILL_PUSH, c, v._spot(h)]
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

# src가 쏜 투사체가 target에 닿고 age초 지난 것으로 battle.landed에 둔다
func _arrow(b, src, target, age: float):
	var m = Battle.Missile.new()
	m.src = src
	m.target = target
	m.look = "arrow"
	m.from = src.pos
	m.pos = target.pos
	m.at = target.pos
	m.age = age
	b.landed.append(m)
	return m

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
	if why == "" and _hit(v, archer, foe, View.CONTACT + 0.3) != null:
		why = "궁수(원거리)를 친 뒤 시간으로 맞은 것으로 셌다(시뮬레이션 투사체가 닿아야 한다)"
	var arrow = _arrow(b, archer, foe, 0.05)
	h = v.hit_table([]).get(foe.get_instance_id())
	if why == "" and (h == null or not is_equal_approx(h[0], 0.05) or not h[1].is_equal_approx(Vector2.UP)):
		why = "궁수의 화살이 닿고 0.05초인데 표가 %s다(0.05초, 위로 밀림이어야 한다)" % [h]
	arrow.src = b.hero  # 영웅이 쏜 투사체는 맞은 쪽만 3프레임 멈춘다(S177 → 2026-10-25 변경)
	arrow.age = 0.03
	h = v.hit_table([]).get(foe.get_instance_id())
	if why == "" and (h == null or h[0] != 0.0):
		why = "영웅이 쏜 화살이 닿고 0.03초(정지 중)인데 표가 %s다(0초여야 한다)" % [h]
	arrow.age = View.HITSTOP + 0.02
	h = v.hit_table([]).get(foe.get_instance_id())
	if why == "" and (h == null or not is_equal_approx(h[0], 0.02)):
		why = "영웅이 쏜 화살의 정지가 끝난 뒤 0.02초인데 표가 %s다" % [h]
	b.landed.clear()
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
	_arrow(b, archer, foe, 0.04)
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

func test_ranged_hero_one_fire_and_hit_while_target_closes_in():
	var b = load("res://src/sim/battle.gd").new({"size": Vector2i(20, 20), "base": Vector2i(18, 18), "base_hp": 100, "spawns": [Vector2i(0, 10)],
		"heroes": [{"kind": "sylvia", "cell": Vector2i(5, 5)}], "waves": [[{"kind": "basic", "count": 1}]]})
	var v = View.new()
	v.battle = b
	var foe = b.spawn_enemy("basic", Vector2i(9, 5), {"speed": 0, "damage": 0, "hp": 1000})
	v.tick(0.0)  # 준비 단계에도 영웅은 사거리 안의 적을 친다. 대상 없이 서 있다가 첫 화살을 쏜다
	var got := []
	for i in 50:  # 적이 1칸/초로 다가와도 화살 한 발은 쏨·닿음 한 번씩이다
		foe.pos.x -= DT
		b.step(DT)
		v.tick(DT)
		got.append_array(v.events.map(func(e): return e.kind))
	v.free()
	if got.count("fire") != 1 or got.count("hit") != 1:
		return "다가오는 적에게 쏜 첫 화살 한 발에 쏨 %d번·닿음 %d번이다(1번씩이어야 한다)" % [got.count("fire"), got.count("hit")]
	return ""

func test_second_knock_slides_from_drawn_spot_and_wall_walk_does_not_slide():
	var s := _board()
	var b = s[0]
	var v = s[1]
	var m = b.place_merc("soldier", Vector2i(5, 12))
	var w = b.place_merc("soldier", Vector2i(10, 12))
	_go(b, v)
	v.tick(DT)
	m.pos += Vector2(1, 0)
	v.tick(DT)
	for i in 3:
		v.tick(DT)
	var drawn: Vector2 = v._spot(m) + v._slip(m)
	m.pos += Vector2(1, 0)  # 미끄러지는 중에 또 한 칸
	v.tick(DT)
	var after: Vector2 = v._spot(m) + v._slip(m)
	var why := ""
	if drawn.distance_to(after) > 3.0:
		why = "미끄러지는 중에 또 옮겨지자 그린 자리가 %s → %s로 튀었다(이어서 미끄러져야 한다)" % [drawn, after]
	w.on_wall = true
	w.pos = Vector2(10, 5.45)
	v.tick(DT)
	w.pos.y = 5.55  # 성벽 위에서 칸 경계를 넘으면 그리는 높이가 16px 바뀌지만 걸은 것이다
	v.tick(DT)
	if why == "" and v._slides.has(w.get_instance_id()):
		why = "성벽 위를 걸어 칸 경계를 넘은 몸이 미끄러졌다"
	v.free()
	return why

# 준비 단계에 다 지은 방벽과 그 서쪽에 붙어 선 근접 적(움직이지도 깎지도 않음)
func _walled() -> Array:
	var s := _board()
	var b = s[0]
	b.build("wall", Vector2i(10, 5))
	s.append(b.structures[Vector2i(10, 5)])
	s.append(b.spawn_enemy("basic", Vector2i(9, 5), {"speed": 0, "damage": 0, "hp": 1000}))
	return s

func test_struct_hit_jolts_one_px_then_throws_debris():
	var s := _walled()
	var b = s[0]
	var v = s[1]
	var wall = s[2]
	var foe = s[3]
	var why := ""
	_hit(v, foe, wall, View.CONTACT + 0.02)
	v._hits = v.hit_table([foe])
	if v._jolt(wall) != Vector2(1, 0):
		why = "서쪽 적에게 맞고 0.02초 뒤 방벽 흔들림이 %s다((1, 0)이어야 한다)" % v._jolt(wall)
	_hit(v, foe, wall, View.CONTACT + 0.06)
	v._hits = v.hit_table([foe])
	if why == "" and v._jolt(wall) != Vector2.ZERO:
		why = "맞고 0.06초 뒤에도 방벽이 %s만큼 옮겨져 있다(0.05초 뒤엔 제자리여야 한다)" % v._jolt(wall)
	_go(b, v)
	foe.target = wall
	foe.cooldown = foe.attack_gap  # 막 쳤다
	var got := _ticks(v, 10, DT, [foe])
	var chips: Array = v._dots.filter(func(d): return d.col == View.DEBRIS)
	if why == "" and (got.count("struct") != 1 or chips.size() != 2 or signf(chips[0].p1.x - chips[0].p0.x) == signf(chips[1].p1.x - chips[1].p0.x)):
		why = "구조물 닿음 %d번에 부스러기 %d점(좌우로 하나씩 2점이어야 한다)" % [got.count("struct"), chips.size()]
	v.free()
	return why

func test_cracks_and_bar_color_follow_structure_hp():
	var s := _walled()
	var v = s[1]
	var wall = s[2]
	var foe = s[3]
	var why := ""
	for c in [[0.8, 0, View.BAR_TIERS[2]], [0.7, 1, View.BAR_TIERS[2]], [0.4, 2, View.BAR_TIERS[1]], [0.2, 3, View.BAR_TIERS[0]]]:
		wall.hp = wall.max_hp * c[0]
		var y: int = View.crack_y(wall, 840)
		if why == "" and (View.crack_stage(wall) != c[1] or View.bar_color(wall, true) != c[2] or (y == 0) != (c[1] == 0) or y % 840 != 0 or y > 6 * 840):
			why = "체력 %d%%인 방벽의 금 %d줄 · 막대 %s · 사본 y %d(금 %d줄 · %s · 금이 있으면 840의 1~6배)" % [c[0] * 100, View.crack_stage(wall), View.bar_color(wall, true).to_html(false), y, c[1], c[2].to_html(false)]
	wall.complete = false
	if why == "" and View.crack_stage(wall) != 0:
		why = "미완성 방벽에 금 %d줄이 있다(없어야 한다)" % View.crack_stage(wall)
	foe.hp = foe.max_hp * 0.2
	if why == "" and View.bar_color(foe, false) != Color.GREEN:
		why = "체력 20%%인 적 막대가 %s다(유닛 막대는 초록 그대로)" % View.bar_color(foe, false).to_html(false)
	v.free()
	return why

func test_crack_atlas_adds_one_crack_per_stage():
	var src: Image = View.KEEP.get_image()
	src.convert(Image.FORMAT_RGBA8)
	var img: Image = View.KEEP_K.get_image()
	var h := src.get_height()
	var changed := func(v: int) -> Dictionary:  # 사본 v(0~5)에서 원본과 달라진 칸
		var out := {}
		for y in h:
			for x in src.get_width():
				if img.get_pixel(x, y + h * (v + 1)) != src.get_pixel(x, y):
					out[Vector2i(x, y)] = true
		return out
	var why := ""
	if img.get_region(Rect2i(0, 0, src.get_width(), h)).get_data() != src.get_data():
		why = "구운 아틀라스의 첫 칸이 원본과 다르다"
	for p in 2:
		var one: Dictionary = changed.call(p)
		var two: Dictionary = changed.call(2 + p)
		var three: Dictionary = changed.call(4 + p)
		if why == "" and (one.is_empty() or one.size() >= two.size() or two.size() >= three.size() or not one.keys().all(func(k): return two.has(k)) or not two.keys().all(func(k): return three.has(k))):
			why = "무늬 %d의 금 칸 수가 단계 1·2·3에서 %d·%d·%d다(단계마다 앞 금을 두고 늘어야 한다)" % [p, one.size(), two.size(), three.size()]
	return why
