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
#   S200. 성곽 칸이 무너지면 먼지 12점·돌 조각 4개(0.25초 안에 엇갈려 떨어짐)가 나고, 그 칸 성벽 위 유닛은 0.15초에 걸쳐 땅으로 내려온다.
#   S177·S197 2026-10-27 변경. «번쩍임 줄이기»면 흰 실루엣 대신 원래 그림 위에 흰 40%를 덧그린다.
#   S177 2026-10-28 변경. 장갑(지금 방어력 10 이상)이 기본 공격·타워 사격의 물리 피해에 맞으면 1px 밀리고 강철 점이 0.2초 남는다. 무거운 타격은 밀림 그대로.
#   S178 2026-10-28 변경. 대포는 쏠 때 1px 반동·포연·섬광, 떨어지면 먼지 6점. 주 대상은 6px·0.25초, 범위 곁 대상(시뮬레이션 기록)은 흰 0.1초·4px.
#   S197 2026-10-28 변경. 대포 범위 곁 대상이 그 대포알에 쓰러지면 착탄 때 번쩍이며 떨어진 곳 반대쪽 6px 밀려 눕는다.
#   S165 2026-10-29 변경. 스킬을 쓰면 0.3초 공격 3프레임(지점·방향·대상 쪽, 자기 스킬은 보던 쪽), 걷기 명령은 0.08초 뒤 끊는다.
#   S179 2026-10-29 변경. 적을 노린 즉시 스킬이 아무도 못 맞히면 흔적을 50%로. 사슬 나눔으로만 맞은 적은 흔적 대상이 아니다.
#   S180 2026-10-29 변경. 쓰러진 영웅은 쓰러짐 5프레임 동안 40%로 덧그리고, 영웅 색 고리가 1.5칸까지 퍼지며 옅어진다.
#   S73 2026-10-29 변경. 영웅은 체력 50% 밑이면 V와 상관없이 체력바가 보인다.
#   I171. 화면 사건 목록: 닿음은 공격 하나에 한 번, 처치는 쓰러진 대상을 노린 마지막 공격이 닿을 때(기다릴 공격이 없으면 바로) 난다.
#         원거리는 시뮬레이션 투사체가 닿은 프레임에 투사체 하나에 한 번이다.

const View := preload("res://src/ui/battle_view.gd")
const Battle := preload("res://src/sim/battle.gd")
const DT := 1.0 / 60.0

# 그림 한 장(_region)을 그리는 대신 그 색만 모으는 화면
class Rec extends "res://src/ui/battle_view.gd":
	var tints := []

	func _region(_tex: Texture2D, _dst: Rect2, _src: Rect2, tint: Color) -> void:
		tints.append(tint)

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

func test_wall_step_slides_briefly():
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
	m.pos += Vector2(0, -1)  # 성문으로 성벽에 오름: STEP초에 걸쳐 미끄러진다(S198 2026-10-28)
	m.on_wall = true
	v.tick(DT)
	if why == "" and v._slides.get(m.get_instance_id(), [0, 0, 0])[2] != View.STEP:
		why = "성벽에 오른 스텝의 미끄러짐이 %s다(STEP초여야 한다)" % [v._slides.get(m.get_instance_id())]
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
	v.tick(View.STEP + 0.05)  # 성벽에 오른 미끄러짐(S198 2026-10-28)이 끝난 뒤
	w.pos.y = 5.55  # 성벽 위에서 칸 경계를 넘어도 걸은 것이다
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

func test_soft_flash_draws_white_40_over_the_body():
	var st = load("res://src/settings.gd")
	var b = load("res://src/sim/battle.gd").new({"size": Vector2i(20, 20), "base": Vector2i(18, 18), "base_hp": 100, "spawns": [Vector2i(0, 10)], "hero_start": Vector2i(5, 5), "waves": [[{"kind": "basic", "count": 1}]]})
	var v = Rec.new()
	v.battle = b
	var foe = b.spawn_enemy("basic", Vector2i(10, 5), {"speed": 0, "damage": 0, "hp": 1000})
	var dead = b.spawn_enemy("basic", Vector2i(12, 5), {"speed": 0, "damage": 0, "hp": 1000})
	var why := ""
	for soft in [false, true]:
		st.soft_flash = soft
		var want: Array = [Color.WHITE, View.SOFT_FLASH] if soft else [Color(255, 255, 255)]
		v._hits = {foe.get_instance_id(): [0.05, Vector2.RIGHT, View.FLINCH, View.FLINCH_BACK, false]}  # 0.05초 전에 맞았다
		v.tints = []
		v._body(foe, b.units.size(), {})
		if why == "" and v.tints != want:
			why = "번쩍임 줄이기 %s일 때 맞은 몸을 %s로 그렸다(%s여야 한다)" % [soft, v.tints, want]
		v._killed = {dead.get_instance_id(): [v.clock, Vector2.RIGHT, dead, 0]}  # 막타가 방금 닿았다(S197)
		v.tints = []
		v._corpse([dead, 0.0])
		if why == "" and v.tints != want:
			why = "번쩍임 줄이기 %s일 때 막타 맞은 몸을 %s로 그렸다(%s여야 한다)" % [soft, v.tints, want]
	st.soft_flash = false
	v.free()
	return why

func test_collapse_throws_dust_and_stones_and_lowers_wall_units():
	var s := _board()
	var b = s[0]
	var v = s[1]
	var k = Battle.Block.new(Vector2i(8, 8), "castle_wall", 300.0)
	k.size = Vector2i(1, 3)
	var w = b.place_merc("soldier", Vector2i(8, 7))
	w.on_wall = true
	v.tick(DT)
	var e := {"kind": "collapse", "at": v._center(Vector2(8, 7)), "dst": k, "n": 5}
	v._react(e)
	var why := ""
	var dust: Array = v._dots.filter(func(d): return d.col == View.DUST)
	var stones: Array = v._dots.filter(func(d): return d.col == View.STONE)
	var floor_y: float = 9 * View.CELL - 1
	if dust.size() != 12 or stones.size() != 4:
		why = "무너진 칸에서 먼지 %d점·돌 조각 %d개가 났다(12·4여야 한다)" % [dust.size(), stones.size()]
	elif not stones.all(func(d): return d.p1.y == floor_y and d.p0.y < floor_y - 20.0 and d.t0 + d.life - v.clock <= 0.25 + 1e-6):
		why = "돌 조각이 성벽 꼭대기에서 바닥선(%s)까지 0.25초 안에 떨어지지 않는다: %s" % [floor_y, stones.map(func(d): return [d.p0, d.p1, d.t0 - v.clock, d.life])]
	elif stones.map(func(d): return d.t0).reduce(func(a, c): return maxf(a, c)) <= v.clock:
		why = "돌 조각 4개가 한꺼번에 떨어지기 시작한다(때를 엇갈려야 한다)"
	w.on_wall = false  # 시뮬레이션은 무너진 칸 위 유닛을 그 칸 땅에 바로 내린다
	v.events = [e]
	var high: Vector2 = v._spot(w) + v._slip(w)
	v._slide_scan()
	var start: Vector2 = v._spot(w) + v._slip(w)
	v.clock += View.DROP
	var end: Vector2 = v._spot(w) + v._slip(w)
	if why == "" and (not v._slides.has(w.get_instance_id()) or start.y >= v._spot(w).y - 10.0 or end != v._spot(w)):
		why = "무너진 칸 위 유닛이 %s에서 땅 %s으로 0.15초에 걸쳐 내려오지 않는다(시작 %s · 0.15초 뒤 %s)" % [high, v._spot(w), start, end]
	v.free()
	return why

# 대포(12,12)와 오른쪽 4칸의 주 대상, 그 아래 1칸의 곁 대상(대포 범위 1칸 안, 주 대상보다 멀다). 대포알이 떨어질 때까지 시뮬레이션과 화면을 함께 돌린다.
# [판, 화면, 대포, 주 대상, 곁 대상, 쏜 프레임의 반동, 쏜 프레임의 효과 점, 오류]
func _cannon(side_hp: float) -> Array:
	var s := _board()
	var b = s[0]
	var v = s[1]
	var cn = b.build("cannon", Vector2i(12, 12))
	var main = b.spawn_enemy("basic", Vector2i(16, 12), {"speed": 0, "damage": 0, "hp": 1000})
	var side = b.spawn_enemy("basic", Vector2i(16, 13), {"speed": 0, "damage": 0, "hp": side_hp})
	_go(b, v)
	var recoil := Vector2.ZERO
	var dots := []
	for i in 120:
		b.step(DT)
		v.tick(DT)
		if v.events.any(func(e): return e.kind == "fire" and e.src == cn):
			recoil = v._recoil(cn)
			dots = v._dots.duplicate()
		if not b.landed.is_empty():
			var why := "" if b.landed[0].target == main else "대포가 가까운 주 대상이 아니라 %s를 쐈다" % [b.landed[0].target]
			return [b, v, cn, main, side, recoil, dots, why]
	return [b, v, cn, main, side, recoil, dots, "2초 안에 대포알이 떨어지지 않았다"]

func test_cannon_fires_with_recoil_smoke_flash_and_lands_with_dust():
	var s := _cannon(1000)
	var v = s[1]
	var cn = s[2]
	var dots: Array = s[6]
	var why: String = s[7]
	if why == "" and s[5] != Vector2.LEFT:
		why = "쏜 프레임에 대포 그림이 대상 반대쪽(왼쪽)으로 1px 물러나야 하는데 %s다" % [s[5]]
	var smoke := dots.filter(func(d): return d.col == View.PX.smoke).size()
	var flash := dots.filter(func(d): return d.col == View.PX.gold or d.col == View.PX.cream).size()
	if why == "" and (smoke != View.PUFFS or flash != 9):
		why = "쏜 프레임에 포연 %d점·섬광 %d점이다(%d·9여야 한다)" % [smoke, flash, View.PUFFS]
	if why == "" and v._recoil(cn) != Vector2.ZERO:
		why = "대포알이 떨어질 때(쏜 뒤 0.5초)는 반동이 끝나야 하는데 %s다" % [v._recoil(cn)]
	var dust: int = v._dots.filter(func(d): return d.col == View.DUST).size()
	if why == "" and dust != 6:
		why = "대포알이 떨어진 프레임에 먼지 %d점이다(6점이어야 한다)" % dust
	v.free()
	return why

func test_cannon_pushes_main_heavy_and_flashes_side_targets():
	var s := _cannon(1000)
	var b = s[0]
	var v = s[1]
	var main = s[3]
	var side = s[4]
	var why: String = s[7]
	var m = b.landed[0] if not b.landed.is_empty() else null
	if why == "" and m.side != [side]:
		why = "떨어진 대포알의 곁 대상 기록이 %s다(곁 대상 하나만, 주 대상은 빼야 한다)" % [m.side]
	v._hits = v.hit_table(b.units + b.enemies)
	var h = v._hits.get(main.get_instance_id())
	if why == "" and (h == null or h[2] != View.HEAVY or h[3] != View.HEAVY_BACK):
		why = "대포알에 맞은 주 대상의 표가 %s다(6px·0.25초여야 한다)" % [h]
	h = v._hits.get(side.get_instance_id())
	var away: Vector2 = (side.pos - m.at).normalized() if m else Vector2.ZERO
	if why == "" and (h == null or h[0] >= View.FLASH or h[2] != View.SIDE or not h[1].is_equal_approx(away)):
		why = "대포 범위 곁 대상의 표가 %s다(번쩍임 중, %spx, 떨어진 곳 반대쪽 %s여야 한다)" % [h, View.SIDE, away]
	v.free()
	return why

func test_cannon_side_kill_flashes_and_lies_pushed_away_from_blast():
	var s := _cannon(1.0)
	var b = s[0]
	var v = s[1]
	var side = s[4]
	var why: String = s[7]
	if why == "" and side.alive:
		why = "곁 대상(체력 1)이 대포 범위 피해에 쓰러지지 않았다"
	elif why == "" and not _blow(v, side, true, true, Vector2.ZERO):
		why = "범위 피해에 쓰러진 곁 대상은 착탄 프레임에 선 자세 흰 실루엣이어야 하는데 %s다" % [v._last_blow(side)]
	_play(b, v, 7, DT)
	if why == "" and not _blow(v, side, false, false, Vector2(0, View.KILL_PUSH)):
		why = "곁 대상은 0.12초 뒤 떨어진 곳 반대쪽(아래)으로 %spx 밀린 자리에 누워야 하는데 %s다" % [View.KILL_PUSH, v._last_blow(side)]
	v.free()
	return why

func test_armor_pushes_one_px_with_steel_dot_for_physical_hits():
	var s := _board()
	var b = s[0]
	var v = s[1]
	var tank = b.spawn_enemy("armored", Vector2i(10, 5), {"speed": 0, "damage": 0, "hp": 1000})
	var foe = b.spawn_enemy("basic", Vector2i(10, 7), {"speed": 0, "damage": 0, "hp": 1000})
	var soldier = b.place_merc("soldier", Vector2i(9, 5))
	var archer = b.place_merc("archer", Vector2i(10, 9))
	var why := ""
	var h = _hit(v, soldier, tank, View.CONTACT + 0.05)
	if h == null or h[2] != View.ARMOR or not h[4]:
		why = "장갑 적을 친 병사(물리)의 표가 %s다(1px, 강철 점이어야 한다)" % [h]
	h = _hit(v, soldier, foe, View.CONTACT + 0.05)
	if why == "" and (h == null or h[2] != View.FLINCH or h[4]):
		why = "장갑 없는 적을 친 병사의 표가 %s다(3px, 강철 점 없음이어야 한다)" % [h]
	var m = _arrow(b, archer, tank, 0.05)
	h = v.hit_table([]).get(tank.get_instance_id())
	if why == "" and (h == null or h[2] != View.ARMOR or not h[4]):
		why = "장갑 적에 닿은 화살의 표가 %s다(1px, 강철 점이어야 한다)" % [h]
	m.src = Battle.Block.new(Vector2i(13, 5), "magic", 100.0)
	m.kind = "magic"
	h = v.hit_table([]).get(tank.get_instance_id())
	if why == "" and (h == null or h[2] != View.FLINCH or h[4]):
		why = "장갑 적에 닿은 마법탑 구슬(마법)의 표가 %s다(3px, 강철 점 없음이어야 한다)" % [h]
	m.src = Battle.Block.new(Vector2i(13, 7), "cannon", 100.0)
	m.kind = "phys"
	h = v.hit_table([]).get(tank.get_instance_id())
	if why == "" and (h == null or h[2] != View.HEAVY or not h[4]):
		why = "장갑 적에 닿은 대포알의 표가 %s다(무거운 6px 그대로, 강철 점이어야 한다)" % [h]
	m.src = archer
	m.age = View.FLINCH_BACK + 0.01
	v._hits = v.hit_table([])
	h = v._hits.get(tank.get_instance_id())
	if why == "" and (h == null or not h[4] or v._flinch(tank) != Vector2.ZERO):
		why = "장갑 적이 화살에 맞고 %s초면 밀림은 끝나고 강철 점은 남아야(%s초까지) 하는데 표 %s, 밀림 %s다" % [m.age, View.STEEL, h, v._flinch(tank)]
	m.age = View.STEEL
	if why == "" and v.hit_table([]).has(tank.get_instance_id()):
		why = "강철 점은 맞은 뒤 %s초에 끝나야 한다" % View.STEEL
	v.free()
	return why

# 영웅 그림 한 장(_region)의 원본 칸만 모으는 화면
class Src extends "res://src/ui/battle_view.gd":
	var src := []

	func _region(_tex: Texture2D, _dst: Rect2, s: Rect2, _tint: Color) -> void:
		src.append(s)

# 흔적 조각을 그리지 않고, 그릴 때의 불투명도(_fade)만 모으는 화면
class Fade extends "res://src/ui/battle_view.gd":
	var fades := []

	func _pring(_c: Vector2i, _r: int, _th: int, _col: Color, _dash := 0, _spin := 0.0) -> void:
		fades.append(_fade)
	func _parc(_c: Vector2i, _r: int, _th: int, _a0: float, _a1: float, _col: Color) -> void:
		fades.append(_fade)
	func _pline(_a: Vector2i, _b: Vector2i, _col: Color, _w := 1) -> void:
		fades.append(_fade)
	func _spr(_name: String, _frame: int, _at: Vector2i, _bottom := false) -> void:
		fades.append(_fade)
	func _px(_p: Vector2i, _col: Color, _size := Vector2i.ONE) -> void:
		fades.append(_fade)

# 전투 중인 빈 판(영웅 아이아스 (5,5))을 화면 v에 붙인다
func _fight(v):
	var b = Battle.new({"size": Vector2i(20, 20), "base": Vector2i(18, 18), "base_hp": 100, "spawns": [Vector2i(0, 10)], "hero_start": Vector2i(5, 5), "waves": [[{"kind": "basic", "count": 1}]]})
	b.start_battle()
	v.battle = b
	return b

# 마나·재사용 대기를 채우고 쓴다
func _ready_cast(b, h, slot: String, aim = null) -> bool:
	h.mana = h.max_mana
	for k in h.cd.keys():
		h.cd[k] = 0.0
	return b.cast(h, slot, aim)

# 영웅 그림 한 장을 그리고 그 원본 칸을 돌려준다. 본 방향은 다음 프레임으로 넘긴다(_bodies와 같다)
func _pose(v, h) -> Rect2:
	v.src.clear()
	var next := {}
	v._sprite(h, next)
	v._seen = next
	return v.src[0]

func test_skill_cast_poses_hero_toward_aim_for_0_3s():
	var v = Src.new()
	var b = _fight(v)
	var h = b.hero
	var a: Dictionary = View.ART[h.kind]
	var c := int(a.c)
	var east: int = View._dir_of(Vector2.RIGHT)
	var why := ""
	v._seen[h.get_instance_id()] = [h.pos, 4]  # 북쪽을 보고 서 있다(_dir_of 4)
	if not _ready_cast(b, h, "q", h.pos + Vector2(3, 0)):
		why = "방패 강타를 쓰지 못했다"
	var r := _pose(v, h)
	if why == "" and r.position != Vector2(0, a.attack + east * 2 * c):
		why = "방패 강타를 쓴 직후 그림이 %s다(동쪽 공격 첫 프레임 (0, %d)이어야 한다)" % [r, a.attack + east * 2 * c]
	for i in 13:
		b.step(DT)
	r = _pose(v, h)
	if why == "" and r.position != Vector2(2 * 2 * c, a.attack + east * 2 * c):
		why = "쓰고 0.22초 뒤 그림이 %s다(동쪽 공격 셋째 프레임이어야 한다)" % r
	for i in 6:
		b.step(DT)
	r = _pose(v, h)
	if why == "" and r.position != Vector2(0, a.idle + east * c):
		why = "쓰고 0.32초 뒤 그림이 %s다(동쪽 정지여야 한다)" % r
	v._seen[h.get_instance_id()] = [h.pos, 4]
	_ready_cast(b, h, "w")  # 전장의 포효(자기 스킬)는 보던 쪽 그대로
	r = _pose(v, h)
	if why == "" and r.position != Vector2(0, a.attack + 4 * 2 * c):
		why = "전장의 포효를 쓴 직후 그림이 %s다(보던 북쪽 공격 첫 프레임이어야 한다)" % r
	b.order_move([h], Vector2i(5, 9))  # 걷기 명령은 기본 공격처럼 닿는 때(0.08초) 뒤 자세를 끊는다(S196)
	for i in 6:
		b.step(DT)
	r = _pose(v, h)
	if why == "" and r.position.y >= a.attack and r.position.y < a.fall:
		why = "걸어가는 영웅이 쓰고 0.1초 뒤에도 공격 자세다(%s)" % r
	v.free()
	return why

func test_missed_skill_trace_draws_at_half():
	var v = Fade.new()
	var b = _fight(v)
	var h = b.hero
	var why := ""
	_ready_cast(b, h, "q", h.pos + Vector2(3, 0))
	if not v.missed(b.traces[-1]):
		why = "아무도 없는 쪽 방패 강타를 빗나감으로 보지 않았다"
	v._traces(true)
	if why == "" and (v.fades.is_empty() or v.fades.any(func(f): return f != View.MISS_FADE)):
		why = "빗나간 방패 강타를 불투명도 %s로 그렸다(모두 %s여야 한다)" % [v.fades, View.MISS_FADE]
	if why == "" and v._fade != 1.0:
		why = "흔적을 다 그린 뒤 불투명도가 %s다(1로 돌아와야 한다)" % v._fade
	b.traces.clear()
	var foe = b.spawn_enemy("basic", Vector2i(6, 5), {"speed": 0, "damage": 0, "hp": 1000})
	_ready_cast(b, h, "q", h.pos + Vector2(3, 0))
	v.fades.clear()
	v._traces(true)
	if why == "" and (v.missed(b.traces[-1]) or v.fades.is_empty() or v.fades.any(func(f): return f != 1.0)):
		why = "적을 맞힌 방패 강타를 빗나감 %s, 불투명도 %s로 그렸다" % [v.missed(b.traces[-1]), v.fades]
	_ready_cast(b, h, "w")  # 전장의 포효는 피해가 없어도 도발을 걸면 맞힌 것이다
	if why == "" and v.missed(b.traces[-1]):
		why = "곁의 적을 도발한 전장의 포효를 빗나감으로 봤다"
	foe.pos = Vector2(15, 15)
	_ready_cast(b, h, "w")
	if why == "" and not v.missed(b.traces[-1]):
		why = "아무도 도발하지 못한 전장의 포효를 빗나감으로 보지 않았다"
	_ready_cast(b, h, "e")  # 반격의 태세는 적을 노리지 않는다
	if why == "" and v.missed(b.traces[-1]):
		why = "반격의 태세를 빗나감으로 봤다"
	v.free()
	return why

func test_chain_share_is_not_a_skill_hit():
	var v = View.new()
	var b = _fight(v)
	var h = b.hero
	var near = b.spawn_enemy("basic", Vector2i(6, 5), {"speed": 0, "damage": 0, "hp": 1000})
	var far = b.spawn_enemy("basic", Vector2i(5, 12), {"speed": 0, "damage": 0, "hp": 1000})
	for e in [near, far]:  # 베스퍼 E 영혼 사슬로 묶인 둘
		b._fx(e, "vesper_e", {"chain": 1, "share": 0.5, "spread": 0.0}, 5.0)
	_ready_cast(b, h, "q", h.pos + Vector2(3, 0))
	var c = b.traces[-1]
	var why := ""
	if far.hp >= 1000:
		why = "사슬로 나눈 피해가 들지 않았다(시험 판이 틀렸다)"
	elif c.hits != [near]:
		why = "방패 강타 흔적의 맞은 대상이 %s다(맞은 적 하나여야 한다)" % [c.hits]
	elif v.hit_table([]).has(far.get_instance_id()):
		why = "사슬로 나눈 피해만 받은 적이 피격 반응을 보인다"
	v.free()
	return why

func test_fallen_hero_ring_spreads_during_fall_and_body_is_ghosted():
	var s := _board()
	var b = s[0]
	var v = s[1]
	var h = b.hero
	_go(b, v)
	b.damage(h, 1e9, "true")
	_play(b, v, 1, DT)
	var why := ""
	var r0: Array = v.fall_ring(h)
	if r0.is_empty():
		why = "쓰러진 직후 고리가 없다"
	_play(b, v, 12, DT)
	var r1: Array = v.fall_ring(h)
	if why == "" and (r1.is_empty() or r1[1] <= r0[1] or r1[3] >= r0[3]):
		why = "0.2초 뒤 고리가 %s다(첫 %s보다 크고 옅어야 한다)" % [r1, r0]
	if why == "" and not r1.is_empty() and r1[0] != v._cross_at(h):
		why = "고리 가운데 %s가 X 자리 %s와 다르다" % [r1[0], v._cross_at(h)]
	_play(b, v, 15, DT)
	if why == "" and not v.fall_ring(h).is_empty():
		why = "쓰러짐 5프레임(%s초) 뒤에도 고리가 남았다" % View.FALL_RING
	var rec = Rec.new()
	rec.battle = b
	rec._corpse([h, 0.1], View.GHOST)
	if why == "" and (rec.tints.is_empty() or not is_equal_approx(rec.tints[-1].a, View.GHOST.a)):
		why = "덧그린 쓰러짐의 색이 %s다(알파 %s여야 한다)" % [rec.tints, View.GHOST.a]
	rec.free()
	v.free()
	return why

func test_hero_below_half_hp_shows_bar_without_v():
	var s := _board()
	var b = s[0]
	var v = s[1]
	var h = b.hero
	var m = b.place_merc("soldier", Vector2i(8, 8))
	var why := ""
	h.hp = 0.6 * h.max_hp
	if View.hp_bar_size(h, false) != Vector2.ZERO:
		why = "체력 60% 영웅은 V를 끄면 막대가 없어야 한다"
	h.hp = 0.4 * h.max_hp
	m.hp = 0.4 * m.max_hp
	if why == "" and View.hp_bar_size(h, false) != Vector2(View.CELL, 2):
		why = "체력 40%% 영웅의 막대가 V를 꺼도 %s여야 하는데 %s다" % [Vector2(View.CELL, 2), View.hp_bar_size(h, false)]
	if why == "" and View.hp_bar_size(m, false) != Vector2.ZERO:
		why = "체력 40% 용병은 V를 끄면 막대가 없어야 한다"
	v.free()
	return why
