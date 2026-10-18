extends "res://tests/eval/gd/lib.gd"
# 2026-10-18 영웅 개편(S145~S158·I141~I149). lib.gd·heroes.gd 머리의 계약에 더하는 API:
#   Battle.cast(영웅, 칸, aim = null) -> bool — aim은 지점·방향이면 칸 좌표(Vector2), 대상이면 유닛·구조물·적
#   Battle.can_cast(영웅, 칸) · Battle.toggle_auto(영웅, 칸) · Battle.damage(대상, 양, 종류 = "phys", 낸 쪽 = null)
#   Battle.effect(대상, 키) — 걸린 효과의 값(없으면 null) · Battle.effect_sum(대상, 키) — 더하는 효과의 합 · Battle.armor_of(대상)
#   Battle.armor_mult(방어력) — 물리 피해 배율(S149) · Battle.zones · Battle.barriers(칸 → 막힌 칸) · Battle.CAST_RANGE
#   영웅: mana · max_mana · cd[칸] · skill_uses · fort · radius · shields(출처 → {hp, left}) · stacks · mark · toggle · auto · order
#   Controls.skill_key(칸, shift) · Controls.aiming · 구조물: cooldown(다음 사격까지 남은 초)
# 수치는 영웅 필드(q·w·e·r·passive·aura 사전)에서 읽는다. 임시값이라(S151~S158) 밸런스를 바꿔도 효과를 재는 평가는 깨지지 않게
# 영웅의 기본 공격이 재는 값을 흐리지 않게, 기본 공격을 재지 않는 평가는 영웅의 공격력을 0으로 둔다

const H := Vector2i(10, 10)
const ONE := [{"kind": "basic", "count": 1}]
const NONE := [{"kind": "basic", "count": 0}]  # 적이 나오지 않는 웨이브. 판에 적이 남아 있는 동안 전투 단계가 이어진다

# 영웅 목록으로 만든 판. 영웅은 최대 레벨이다(I115)
func _kit(team: Array, over := {}):
	var stage := {"heroes": team.map(func(t): return {"kind": t[0], "cell": t[1]}), "base_hp": BIG, "waves": [NONE, NONE], "seed": 11}
	stage.merge(over, true)
	return battle(stage)

# 전투 단계를 연다. 구석에 움직이지도 치지도 않는 적 하나를 두어 전투 단계가 이어지게 한다. 시간은 흐르지 않는다
func _start(b) -> void:
	b.spawn_enemy("basic", Vector2i(0, 19), {"speed": 0, "sight": 0, "damage": 0, "hp": BIG})
	b.start_battle()

# 움직이지도 치지도 않는 과녁
func _dummy(b, cell: Vector2i, over := {}):
	return b.spawn_enemy("basic", cell, {"speed": 0, "sight": 0, "damage": 0, "hp": BIG}.merged(over, true))

func _quiet(b) -> void:  # 영웅의 기본 공격을 끈다
	for h in b.heroes:
		h.damage = 0.0

func _lost(x, hp0: float) -> float:
	return hp0 - x.hp

func _key(c, key: int) -> void:
	var ev := InputEventKey.new()
	ev.keycode = key
	ev.pressed = true
	c.handle(ev)

func _near_f(a: float, b: float, tol := 0.01) -> bool:
	return absf(a - b) <= tol

# ── 공통 규칙 ──

# EV255 · S145: 오라는 Lv1부터다. Lv1 실비아 옆 타워는 사거리 4를 넘는 4.12칸 적을 쏘고, 오라 밖 타워는 쏘지 않는다
func ev255():
	var b = battle({"heroes": [{"kind": "sylvia", "cell": H, "level": 1}], "base_hp": BIG})
	var near_t = b.build("tower", H + Vector2i(1, 0))
	var far_t = b.build("tower", Vector2i(20, 3))
	var e1 = _dummy(b, H + Vector2i(1, 0) + Vector2i(4, 1))
	var e2 = _dummy(b, Vector2i(20, 3) + Vector2i(4, 1))
	run(b, 3.0)
	return check(b.hero.level == 1 and e1.hp < e1.max_hp and e2.hp == e2.max_hp,
		"Lv%d · 오라 안 타워가 4.12칸 적을 쏨 %s · 오라 밖 타워가 쏨 %s" % [b.hero.level, e1.hp < e1.max_hp, e2.hp < e2.max_hp])

# EV256 · S146: 마나는 전투 단계에만 초당 2씩 차고, 모자라면 스킬을 쓰지 않으며 대기도 시작하지 않는다
func ev256():
	var b = _kit([["bastion", H]])
	var k = b.hero
	_start(b)
	b.cast(k, "w")
	var m0: float = k.mana
	run(b, 10.0)
	var gained: float = k.mana - m0
	run(b, 100.0)
	var capped: bool = _near_f(k.mana, k.max_mana)
	for e in b.enemies.duplicate():
		b.damage(e, BIG)
	run(b, 0.1)
	k.mana = 30.0
	run(b, 10.0)
	var prep: bool = b.state == "prep" and k.mana == 30.0
	_start(b)
	k.cd.q = 0.0
	var refused: bool = not b.cast(k, "q", Vector2(H + Vector2i(2, 0))) and k.cd.q == 0.0 and _near_f(k.mana, 30.0, 0.001)
	return check(m0 == k.max_mana - k.w.mana and _near_f(gained, 20.0, 0.2) and capped and prep and refused,
		"W 뒤 마나 %s · 전투 10초에 +%s · 상한 %s · 준비 단계 그대로 %s · 마나 30에 Q(40) 거부 %s" % [m0, gained, capped, prep, refused])

# EV257 · S146: 새로 출전한 영웅은 마나가 가득 찬 채 서고, 쓰러졌다 돌아온 영웅은 마나 0으로 선다
func ev257():
	var b = battle({"hero_cells": [Vector2i(10, 5), Vector2i(12, 5), Vector2i(14, 5)], "base_hp": BIG, "rounds": [[ONE, ONE]], "seed": 3})
	b.begin_hiring()
	b.offers = ["bastion", "bastion", "bastion"]
	var k = b.hire(0)
	b.next_round()
	var fresh: bool = k.mana == k.max_mana
	b.start_battle()
	run(b, 0.5)
	b.damage(k, BIG)
	clear_wave(b)
	return check(fresh and b.state == "prep" and k.present and k.mana == 0.0, "새로 출전 마나 가득 %s · 돌아온 영웅(%s) 마나 %s" % [fresh, b.state, k.mana])

# EV258 · S147: 시전 사거리(6칸) 안이면 바로 쓰고, 밖이면 그쪽으로 걸어가 사거리에 들면 쓴다. 가는 동안 이동 지시를 받으면 쓰지 않는다
func ev258():
	var b = _kit([["ignis", Vector2i(3, 10)]])
	var h = b.hero
	_quiet(b)
	var near_e = _dummy(b, Vector2i(7, 12))  # 걸어갈 줄(10행) 밖. 적의 몸은 영웅의 길을 막는다(S13)
	var far_e = _dummy(b, Vector2i(20, 10))
	_start(b)
	var now: bool = b.cast(h, "q", Vector2(7, 12)) and h.skill_uses == 1 and near_e.hp < near_e.max_hp
	h.cd.q = 0.0
	var queued: bool = b.cast(h, "q", Vector2(20, 10)) and h.skill_uses == 1 and not h.path.is_empty()
	run(b, 10.0, func(): return h.skill_uses == 2)
	var cast_at: Vector2 = h.pos
	var walked: bool = h.skill_uses == 2 and cast_at.distance_to(Vector2(20, 10)) <= b.CAST_RANGE + 0.2 and far_e.hp < far_e.max_hp
	h.cd.q = 0.0
	h.mana = h.max_mana
	b.order_move([h], Vector2i(3, 10))
	run(b, 5.0)
	b.cast(h, "q", Vector2(20, 10))
	b.order_move([h], Vector2i(3, 12))
	run(b, 5.0)
	return check(now and queued and walked and h.skill_uses == 2,
		"사거리 안 바로 %s · 밖이면 걸어감 %s · 닿아 씀 %s(%s에서) · 이동 지시로 그만둠 %s(%d번)" % [now, queued, walked, cast_at, h.skill_uses == 2, h.skill_uses])

# EV259 · S147: 고르는 칸은 키를 누르면 조준 상태가 되고, 좌클릭한 곳에 쓴다. 우클릭·ESC는 취소한다. 즉시 칸은 키만으로 쓴다
func ev259():
	var b = _kit([["bastion", Vector2i(5, 12)], ["ignis", H]])
	var c = controls(b)
	var ig = b.heroes[1]
	_start(b)
	_key(c, KEY_F2)
	_key(c, KEY_Q)
	var aiming: bool = c.aiming == "q" and ig.skill_uses == 0
	click(c, MOUSE_BUTTON_RIGHT, px(H + Vector2i(3, 0)))
	var cancel: bool = c.aiming == "" and ig.skill_uses == 0 and ig.cd.q <= 0.0
	_key(c, KEY_E)
	_key(c, KEY_ESCAPE)
	var esc: bool = c.aiming == "" and ig.skill_uses == 0
	_key(c, KEY_Q)
	click(c, MOUSE_BUTTON_LEFT, px(H + Vector2i(3, 0)))
	var used: bool = c.aiming == "" and ig.skill_uses == 1
	_key(c, KEY_F1)
	_key(c, KEY_W)
	var instant: bool = c.aiming == "" and b.heroes[0].skill_uses == 1
	return check(aiming and cancel and esc and used and instant,
		"Q 조준 %s · 우클릭 취소 %s · ESC 취소 %s · 좌클릭에 씀 %s · 즉시 칸 키만으로 %s" % [aiming, cancel, esc, used, instant])

# EV260 · S148: 증가율은 더한다(크로노스 오라 +15%와 Q +35%면 쏘는 대기가 1.5배 빠르게 준다). 같은 종류의 오라끼리는 가장 큰 값 하나다
func ev260():
	var b = _kit([["chronos", H], ["chronos", H + Vector2i(0, 2)]])
	var t = b.build("tower", H + Vector2i(1, 1))
	var lone = b.build("tower", Vector2i(20, 3))
	var rate := func(s):  # 한 스텝에 준 대기 ÷ 스텝 길이
		s.cooldown = 1.0
		b.step(DT)
		return (1.0 - s.cooldown) / DT
	var two_auras: float = rate.call(t)
	_start(b)
	b.cast(b.heroes[0], "q", t)
	var with_q: float = rate.call(t)
	var plain: float = rate.call(lone)
	return check(_near_f(two_auras, 1.15, 0.001) and _near_f(with_q, 1.5, 0.001) and _near_f(plain, 1.0, 0.001),
		"크로노스 둘의 오라 %s(1.15) · 오라 + Q %s(1.5) · 오라 밖 %s(1)" % [two_auras, with_q, plain])

# EV261 · S148: 감소율은 곱한다. 요새화(25%)한 바스티온이 반격의 태세(50%)를 쓰면 피해 100에 37.5를 받는다
func ev261():
	var b = _kit([["bastion", H]])
	var k = b.hero
	_quiet(b)
	_start(b)
	run(b, k.passive.still + 0.3)
	var hp0: float = k.hp
	b.damage(k, 100.0)
	var fort_only: float = _lost(k, hp0)
	k.hp = k.max_hp
	b.cast(k, "e")
	hp0 = k.hp
	b.damage(k, 100.0)
	var both: float = _lost(k, hp0)
	return check(k.fort and _near_f(fort_only, 75.0) and _near_f(both, 37.5), "요새화 %s · 요새화만 %s(75) · 요새화 + 태세 %s(37.5)" % [k.fort, fort_only, both])

# EV262 · S149: 물리 피해는 워크3식 방어 공식을 받고, 마법 피해는 방어력을 무시하며, 고정 피해는 그대로 들어간다
func ev262():
	var b = battle()
	var a = _dummy(b, Vector2i(5, 5), {"armor": 15.0})
	var n = _dummy(b, Vector2i(5, 8), {"armor": -15.0})
	var cases := [[a, 10.0, "phys", 10.0 * (1.0 - 0.9 / 1.9)], [n, 10.0, "phys", 10.0 * (2.0 - pow(0.94, 15.0))], [a, 10.0, "magic", 10.0], [a, 10.0, "true", 10.0]]
	for c in cases:
		var hp0: float = c[0].hp
		b.damage(c[0], c[1], c[2])
		if not _near_f(_lost(c[0], hp0), c[3], 0.001):
			return "방어력 %s 적이 %s 피해 %s에 %s 깎였다(%s여야 한다)" % [c[0].armor, c[2], c[1], _lost(c[0], hp0), c[3]]
	return ""

# ── 바스티온(S151) ──

# EV263 · S151: Q는 지점 쪽 반경 2·90° 부채꼴 안 적에게 물리 피해와 기절 1.5초. 뒤쪽·옆쪽 적은 맞지 않는다
func ev263():
	var b = _kit([["bastion", H]])
	var k = b.hero
	_quiet(b)
	var front = _dummy(b, H + Vector2i(1, 0))
	var back = _dummy(b, H + Vector2i(-1, 0))
	var side = _dummy(b, H + Vector2i(0, 2))
	_start(b)
	b.cast(k, "q", Vector2(H + Vector2i(3, 0)))
	var hit: bool = _near_f(_lost(front, BIG), k.q.damage) and b.effect(front, "stun") != null
	var spared: bool = back.hp == back.max_hp and side.hp == side.max_hp and b.effect(back, "stun") == null
	run(b, k.q.stun - 0.1)
	var still_stunned: bool = b.effect(front, "stun") != null
	run(b, 0.2)
	return check(hit and spared and still_stunned and b.effect(front, "stun") == null,
		"앞 적 피해·기절 %s · 뒤·옆 그대로 %s · 1.4초 기절 %s · 1.6초 풀림 %s" % [hit, spared, still_stunned, b.effect(front, "stun") == null])

# EV264 · S151·I147: 2초 서 있으면 요새화(받는 피해 −25%, 몸 반지름 0.6). 이동 지시를 받으면 풀린다. 요새화 중 Q는 앞 적을 1칸 밀쳐 내고 둔화시킨다
func ev264():
	var b = _kit([["bastion", H]])
	var k = b.hero
	_quiet(b)
	var front = _dummy(b, H + Vector2i(1, 0))
	_start(b)
	run(b, k.passive.still + 0.3)
	var hp0: float = k.hp
	b.damage(k, 10.0)
	var fort: bool = k.fort and _near_f(k.radius, k.passive.radius) and _near_f(_lost(k, hp0), 7.5)
	var x0: float = front.pos.x
	b.cast(k, "q", Vector2(H + Vector2i(3, 0)))
	var pushed: bool = front.pos.x - x0 >= 0.9 and _near_f(b.effect_sum(front, "slow"), k.q.slow)
	b.order_move([k], H + Vector2i(0, 3))
	run(b, 0.2)
	hp0 = k.hp
	b.damage(k, 10.0)
	return check(fort and pushed and not k.fort and _near_f(_lost(k, hp0), 10.0),
		"요새화 %s · 밀쳐 냄·둔화 %s(%s칸) · 이동 지시로 풀림 %s(피해 %s)" % [fort, pushed, front.pos.x - x0, not k.fort, _lost(k, hp0)])

# EV265 · S151: W는 반경 3 적을 도발하고(옆 용병이 더 가까워도 바스티온을 노린다) 방어력을 5 깎으며, 도발한 적 하나마다 최대 체력 4% 보호막을 준다
func ev265():
	var b = _kit([["bastion", H]])
	var k = b.hero
	_quiet(b)
	var m = b.place_merc("soldier", H + Vector2i(3, 0), {"hp": BIG, "damage": 0})
	var striker = b.spawn_enemy("basic", H + Vector2i(2, 0), {"speed": 1.0, "damage": 5.0, "hp": BIG})
	var others := [_dummy(b, H + Vector2i(0, 2)), _dummy(b, H + Vector2i(-2, 0)), _dummy(b, H + Vector2i(0, -2))]
	var out = _dummy(b, H + Vector2i(5, 0))
	_start(b)
	b.cast(k, "w")
	var taunted: bool = ([striker] + others).all(func(e): return b.effect(e, "taunt") == k and _near_f(b.armor_of(e), k.w.armor)) and b.effect(out, "taunt") == null
	var shield: float = k.shields.bastion_w.hp
	run(b, k.w.time - 0.5)
	return check(taunted and _near_f(shield, 4 * k.w.shield * k.max_hp) and m.hp == m.max_hp,
		"도발·방어력 −5 %s · 보호막 %s(%s) · 옆 용병 맞지 않음 %s" % [taunted, shield, 4 * k.w.shield * k.max_hp, m.hp == m.max_hp])

# EV266 · S151: E는 3초 동안 받는 피해 −50%. 다시 누르거나 끝나면 그동안 들어온 피해(줄이기 전) × 1.5를 반경 2 적에게 준다
func ev266():
	var b = _kit([["bastion", H]])
	var k = b.hero
	_quiet(b)
	var near_e = _dummy(b, H + Vector2i(1, 0))
	var far_e = _dummy(b, H + Vector2i(3, 0))
	_start(b)
	b.cast(k, "e")
	var hp0: float = k.hp
	b.damage(k, 20.0)
	b.damage(k, 20.0)
	var halved: bool = _near_f(_lost(k, hp0), 20.0)
	b.cast(k, "e")
	var burst: bool = _near_f(_lost(near_e, BIG), 40.0 * k.e.ratio) and far_e.hp == far_e.max_hp and k.brace == 0.0
	k.cd.e = 0.0
	k.mana = k.max_mana
	var before: float = near_e.hp
	b.cast(k, "e")
	b.damage(k, 20.0)
	run(b, k.e.time + 0.1)
	return check(halved and burst and _near_f(before - near_e.hp, 20.0 * k.e.ratio),
		"태세 중 40에 %s 받음 · 다시 눌러 터뜨림 %s · 끝나서 터짐 %s" % [_lost(k, hp0), burst, before - near_e.hp])

# EV267 · S151·I142: R은 지점 칸을 가운데로 영웅 → 지점 방향에 수직인 3칸 에너지 성벽을 세운다. 땅 적은 지나가지 못해 돌아가고,
# 6초 뒤 사라진다. 성벽 2칸 안 타워는 받는 피해 −40%
func ev267():
	var b = _kit([["bastion", Vector2i(10, 10)]], {"base": Vector2i(2, 10), "spawns": [Vector2i(29, 10)]})
	var k = b.hero
	_quiet(b)
	var tw = b.build("tower", Vector2i(15, 12))
	_start(b)
	b.cast(k, "r", Vector2(14, 10))
	var cells: Array = b.barriers.keys()
	cells.sort()
	var want := [Vector2i(14, 9), Vector2i(14, 10), Vector2i(14, 11)]
	var walker = b.spawn_enemy("basic", Vector2i(20, 10), {"sight": 0, "hp": BIG})
	var seen := {"crossed": false}  # 람다는 지역 변수를 복사해 가져가서 사전에 적는다
	run(b, k.r.time - 0.5, func():
		seen.crossed = seen.crossed or Vector2i(walker.pos.round()) in want
		return false)
	var crossed: bool = seen.crossed
	var hp0: float = tw.hp
	b.damage(tw, 10.0)
	var warded: bool = _near_f(_lost(tw, hp0), 10.0 * (1.0 - k.r.dr))
	run(b, 0.7)
	return check(cells == want and not crossed and warded and b.barriers.is_empty(),
		"성벽 칸 %s(%s) · 적이 성벽 칸을 지남 %s · 타워 피해 −40%% %s · 6초 뒤 사라짐 %s" % [cells, want, crossed, warded, b.barriers.is_empty()])

# ── 세라피나(S152) ──

# EV268 · S152: Q는 아군 → 적 → 아군 … 차례로 3칸 안 가장 가까운 대상에 도약해 모두 5번(회복 20 · 마법 15). 여섯째 대상은 맞지 않는다
func ev268():
	var b = _kit([["seraphina", Vector2i(10, 5)]])
	var s = b.hero
	_quiet(b)
	var m1 = b.place_merc("soldier", Vector2i(12, 10), {"damage": 0})
	var e1 = _dummy(b, Vector2i(14, 10))
	var m2 = b.place_merc("soldier", Vector2i(16, 10), {"damage": 0})
	var e2 = _dummy(b, Vector2i(18, 10))
	var m3 = b.place_merc("soldier", Vector2i(20, 10), {"damage": 0})
	var e3 = _dummy(b, Vector2i(22, 10))
	for m in [m1, m2, m3]:
		m.hp = 10.0
	_start(b)
	b.cast(s, "q", m1)
	var healed: bool = [m1, m2, m3].all(func(m): return _near_f(m.hp, 10.0 + s.q.heal))
	var hurt: bool = _near_f(_lost(e1, BIG), s.q.damage) and _near_f(_lost(e2, BIG), s.q.damage)
	return check(healed and hurt and e3.hp == e3.max_hp, "용병 셋 회복 %s(%s) · 적 둘 피해 %s · 여섯째 그대로 %s" % [healed, [m1.hp, m2.hp, m3.hp], hurt, e3.hp == e3.max_hp])

# EV269 · S152: 최대 체력을 넘친 회복은 빛의 보호막이 되어 피해를 먼저 받는다. 오라 안 아군은 방어력 +6이라 피해 10에 10 × 배율(6)만 받는다
func ev269():
	var b = _kit([["seraphina", H]])
	var s = b.hero
	_quiet(b)
	var m = b.place_merc("soldier", H + Vector2i(2, 0), {"damage": 0})
	var far_m = b.place_merc("soldier", H + Vector2i(8, 0), {"damage": 0})
	_start(b)
	b.cast(s, "q", m)
	var shield: float = m.shields.seraphina.hp if m.shields.has("seraphina") else 0.0
	b.damage(m, 10.0)
	var absorbed: bool = m.hp == m.max_hp and _near_f(m.shields.seraphina.hp, shield - 10.0 * b.armor_mult(s.aura.armor))
	var hp0: float = far_m.hp
	b.damage(far_m, 10.0)
	return check(_near_f(shield, s.q.heal) and absorbed and _near_f(_lost(far_m, hp0), 10.0),
		"넘친 회복 보호막 %s(%s) · 오라 안 피해 10이 보호막에서 %s · 오라 밖 피해 %s(10)" % [shield, s.q.heal, absorbed, _lost(far_m, hp0)])

# EV270 · S152: E가 걸린 아군은 받는 회복이 30% 늘고, 체력이 0이 될 피해를 받으면 체력 1로 남아 2.5초 동안 피해를 받지 않는다
func ev270():
	var b = _kit([["seraphina", H]])
	var s = b.hero
	_quiet(b)
	var m = b.place_merc("soldier", H + Vector2i(2, 0), {"damage": 0})
	_start(b)
	b.cast(s, "e", m)
	m.hp = 10.0
	b.cast(s, "q", m)
	var boosted: bool = _near_f(m.hp, 10.0 + s.q.heal * (1.0 + s.e.heal_up))
	b.damage(m, BIG)
	var saved: bool = m.alive and m.hp == 1.0
	run(b, s.e.undying - 0.2)
	b.damage(m, BIG)
	var held: bool = m.alive and m.hp == 1.0
	run(b, 0.4)
	b.damage(m, BIG)
	return check(boosted and saved and held and not m.alive, "회복 +30%% %s(%s) · 체력 1로 남음 %s · 불사 중 그대로 %s · 끝나면 쓰러짐 %s" % [boosted, m.hp, saved, held, not m.alive])

# EV271 · S152: R은 모든 아군과 쏘는 구조물을 최대 체력 50%만큼 회복하고, 5초 동안 사격이 맞은 적 둘레 1칸 적에게 마법 3을 더한다
func ev271():
	var b = _kit([["seraphina", Vector2i(3, 3)]])
	var s = b.hero
	_quiet(b)
	var m = b.place_merc("soldier", Vector2i(5, 3), {"damage": 0})
	var t = b.build("tower", Vector2i(15, 10))
	m.hp = 10.0
	t.hp = 10.0
	var target = _dummy(b, Vector2i(17, 10))
	var beside = _dummy(b, Vector2i(17, 11))
	_start(b)
	b.cast(s, "r")
	var healed: bool = _near_f(m.hp, 10.0 + 0.5 * m.max_hp) and _near_f(t.hp, 10.0 + 0.5 * t.max_hp)
	run(b, 1.0, func(): return target.hp < target.max_hp)
	return check(healed and _near_f(_lost(target, BIG), t.damage + s.r.bless) and _near_f(_lost(beside, BIG), s.r.bless),
		"50%% 회복 %s · 과녁 %s(%s) · 옆 적 %s(%s)" % [healed, _lost(target, BIG), t.damage + s.r.bless, _lost(beside, BIG), s.r.bless])

# EV272 · S152: W 성역 안의 아군은 초당 5씩 회복하고, 안의 적은 25% 느리게 걷는다
func ev272():
	var b = _kit([["seraphina", Vector2i(10, 4)]], {"base": Vector2i(2, 10), "spawns": [Vector2i(29, 10)]})
	var s = b.hero
	_quiet(b)
	var m = b.place_merc("soldier", Vector2i(10, 7), {"damage": 0})
	m.hp = 10.0
	var walker = b.spawn_enemy("basic", Vector2i(12, 10), {"sight": 0, "hp": BIG})
	_start(b)
	b.cast(s, "w", Vector2(10, 9))
	var x0: float = walker.pos.x
	run(b, 1.0)
	return check(_near_f(m.hp, 10.0 + s.w.hps, 0.3) and _near_f(x0 - walker.pos.x, walker.speed * (1.0 - s.w.slow), 0.15),
		"1초 회복 %s(+%s) · 적 1초에 %s칸(%s)" % [m.hp - 10.0, s.w.hps, x0 - walker.pos.x, walker.speed * (1.0 - s.w.slow)])

# ── 실비아(S153) ──

# EV273 · S153: 같은 적을 이어 치면 중첩이 쌓이고, 5중첩(여섯째 한 방)부터 방어력의 35%를 무시한다. 다른 적을 치면 0부터다
func ev273():
	var b = _kit([["sylvia", H]])
	var s = b.hero
	var a = _dummy(b, H + Vector2i(2, 0), {"armor": 15.0})
	_start(b)
	var hits := []
	for i in 6:
		var hp0: float = a.hp
		run(b, 5.0, func(): return a.hp < hp0)
		hits.append(hp0 - a.hp)
	var plain: float = s.damage * b.armor_mult(15.0)
	var pierced: float = s.damage * b.armor_mult(15.0 * (1.0 - s.passive.ignore))
	var ok := hits.slice(0, 5).all(func(x): return _near_f(x, plain, 0.001)) and _near_f(hits[5], pierced, 0.001)
	return check(ok and s.stacks == s.passive.stacks, "한 방들 %s(다섯은 %s, 여섯째 %s) · 중첩 %d" % [hits, plain, pierced, s.stacks])

# EV274 · S153: Q는 지점 쪽 직선 위 적을 가까운 차례로 꿰뚫고, 하나 맞힐 때마다 피해가 10%씩 준다. 첫 적에 중첩 3
func ev274():
	var b = _kit([["sylvia", H]])
	var s = b.hero
	_quiet(b)
	var line := [_dummy(b, H + Vector2i(2, 0)), _dummy(b, H + Vector2i(4, 0)), _dummy(b, H + Vector2i(5, 0))]
	var off = _dummy(b, H + Vector2i(3, 2))
	_start(b)
	b.cast(s, "q", Vector2(H + Vector2i(6, 0)))
	var got := line.map(func(e): return _lost(e, BIG))
	var want := [s.q.damage, s.q.damage * 0.9, s.q.damage * 0.81]
	var ok := true
	for i in 3:
		ok = ok and _near_f(got[i], want[i], 0.001)
	return check(ok and off.hp == off.max_hp and s.mark == line[0] and s.stacks == s.q.stacks, "직선 위 %s(%s) · 직선 밖 그대로 %s · 첫 적 중첩 %d" % [got, want, off.hp == off.max_hp, s.stacks])

# EV275 · S153: W를 켜면 기본 공격마다 마나 8을 내고 대상과 가까운 적 3명에게도 같은 피해를 준다. 마나가 모자라면 꺼진다
func ev275():
	var b = _kit([["sylvia", H]])
	var s = b.hero
	var foes := [_dummy(b, H + Vector2i(2, 0)), _dummy(b, H + Vector2i(3, 0)), _dummy(b, H + Vector2i(3, 1)), _dummy(b, H + Vector2i(3, -1)), _dummy(b, H + Vector2i(3, 2))]
	_start(b)
	b.cast(s, "w")
	var m0: float = s.mana
	run(b, 3.0, func(): return foes.any(func(e): return e.hp < e.max_hp))
	var hit_n: int = foes.filter(func(e): return e.hp < e.max_hp).size()
	var paid: bool = s.mana <= m0 - s.w.mana + 0.5
	s.mana = 5.0
	var before := foes.map(func(e): return e.hp)
	run(b, 3.0, func(): return foes.any(func(e): return e.hp < before[foes.find(e)]))
	var after_n: int = 0
	for i in foes.size():
		if foes[i].hp < before[i]:
			after_n += 1
	return check(hit_n == 1 + s.w.extra and paid and after_n == 1 and not s.toggle, "켜고 한 방에 %d명(4) · 마나 냄 %s · 마나 5면 %d명이고 꺼짐 %s" % [hit_n, paid, after_n, not s.toggle])

# EV276 · S153·S149: E 덫은 땅 적이 밟으면 터져 반경 1.5 적을 3초 속박한다(제자리, 닿는 용병은 친다). 속박된 적에게 쏘는 구조물의 치명타(피해 ×2) 확률은 25%다
func ev276():
	var b = _kit([["sylvia", Vector2i(5, 4)]], {"base": Vector2i(2, 10), "spawns": [Vector2i(29, 10)]})
	var s = b.hero
	_quiet(b)
	var t = b.build("tower", Vector2i(25, 3))  # 전투 단계에는 공병이 지어야 해서 준비 단계에 짓는다
	_start(b)
	b.cast(s, "e", Vector2(10, 10))
	var walker = b.spawn_enemy("basic", Vector2i(13, 10), {"sight": 0, "hp": BIG})
	run(b, 5.0, func(): return b.effect(walker, "root") != null)
	var at: Vector2 = walker.pos
	run(b, s.e.root - 0.2)
	var held: bool = walker.pos.distance_to(at) < 0.01
	run(b, 0.5)
	var freed: bool = walker.pos.distance_to(at) > 0.1
	s.cd.e = 0.0
	s.mana = s.max_mana
	var d = _dummy(b, Vector2i(8, 7))
	b.cast(s, "e", Vector2(8, 7))
	b.step(DT)
	var crits := 0
	for i in 400:
		var hp0: float = d.hp
		b.damage(d, 10.0, "phys", t)
		if _near_f(hp0 - d.hp, 20.0, 0.001):
			crits += 1
	return check(held and freed and crits >= 70 and crits <= 130, "3초 제자리 %s · 풀림 %s · 치명타 %d/400(100 안팎)" % [held, freed, crits])

# EV277 · S153: R 화살비 안의 적은 초당 물리 8(보스 ×1.5)을 받고, 체력이 15% 이하인 보스 아닌 적은 처형된다
func ev277():
	var b = _kit([["sylvia", Vector2i(5, 10)]])
	var s = b.hero
	_quiet(b)
	var plain = _dummy(b, Vector2i(10, 10), {"hp": 1000})
	var boss = b.spawn_enemy("boss", Vector2i(10, 12), {"speed": 0, "sight": 0, "damage": 0, "hp": 1000})
	var low = _dummy(b, Vector2i(11, 11), {"hp": 100})
	low.hp = 15.5
	_start(b)
	b.cast(s, "r", Vector2(10, 11))
	run(b, 1.0)
	return check(_near_f(1000.0 - plain.hp, s.r.dps, 0.5) and _near_f(1000.0 - boss.hp, s.r.dps * s.r.boss, 0.6) and not low.alive,
		"1초 피해 %s(%s) · 보스 %s(%s) · 15%% 이하 처형 %s" % [1000.0 - plain.hp, s.r.dps, 1000.0 - boss.hp, s.r.dps * s.r.boss, not low.alive])

# ── 베스퍼(S154·S155) ──

# EV278 · S154: 오라(방어력 −5)와 Q 독안개(방어력 −10)가 겹친 장갑 적(15)은 방어력 0이라 물리 피해를 그대로 받고, 마법 피해는 25% 더 받는다
func ev278():
	var b = _kit([["vesper", H]])
	var v = b.hero
	_quiet(b)
	var a = b.spawn_enemy("armored", H + Vector2i(2, 0), {"speed": 0, "sight": 0, "damage": 0, "hp": BIG})
	var aura_only: float = b.armor_of(a)
	_start(b)
	b.cast(v, "q", Vector2(H + Vector2i(2, 0)))
	b.step(DT)
	var both: float = b.armor_of(a)
	var hp0: float = a.hp
	b.damage(a, 10.0)
	var phys: float = _lost(a, hp0)
	hp0 = a.hp
	b.damage(a, 10.0, "magic")
	return check(_near_f(aura_only, 15.0 - v.aura.foe_armor) and _near_f(both, 0.0) and _near_f(phys, 10.0) and _near_f(_lost(a, hp0), 10.0 * (1.0 - v.q.mr)),
		"오라만 방어력 %s · 둘 다 %s · 물리 10에 %s · 마법 10에 %s" % [aura_only, both, phys, _lost(a, hp0)])

# EV279 · S154: 중독된 적이 죽으면 반경 2 적에게 중독이 남은 시간만큼 옮는다. 멀리 있는 적에게는 옮지 않는다
func ev279():
	var b = _kit([["vesper", Vector2i(10, 4)]])
	var v = b.hero
	_quiet(b)
	var src = _dummy(b, Vector2i(12, 10))
	var near_e = _dummy(b, Vector2i(14, 10))
	var far_e = _dummy(b, Vector2i(17, 10))
	_start(b)
	b.cast(v, "q", Vector2(10, 10))
	run(b, 0.5)
	var clean: bool = b.effect_sum(near_e, "armor") == 0.0
	b.damage(src, BIG)
	return check(clean and _near_f(b.effect_sum(near_e, "armor"), v.q.armor) and b.effect_sum(far_e, "armor") == 0.0,
		"독안개 밖이라 처음엔 안 걸림 %s · 옮음 %s · 먼 적 그대로 %s" % [clean, b.effect_sum(near_e, "armor"), b.effect_sum(far_e, "armor") == 0.0])

# EV280 · S154: W 저주에 걸린 적은 공격력 −35%·둔화 40%·받는 피해 +20%다
func ev280():
	var b = _kit([["vesper", Vector2i(10, 4)]], {"base": Vector2i(2, 15), "spawns": [Vector2i(29, 15)]})
	var v = b.hero
	_quiet(b)
	var m = b.place_merc("soldier", Vector2i(12, 10), {"hp": BIG, "damage": 0})
	var striker = b.spawn_enemy("basic", Vector2i(13, 10), {"speed": 0, "damage": 10.0, "hp": BIG})
	var walker = b.spawn_enemy("basic", Vector2i(12, 8), {"sight": 0, "hp": BIG})
	_start(b)
	b.cast(v, "w", Vector2(12, 9))
	var hp0: float = m.hp
	run(b, 3.0, func(): return m.hp < hp0)
	var bite: float = _lost(m, hp0)
	var p0: Vector2 = walker.pos
	run(b, 1.0)
	var step: float = walker.pos.distance_to(p0)
	hp0 = striker.hp
	b.damage(striker, 10.0)
	return check(_near_f(bite, 10.0 * (1.0 - v.w.weaken)) and _near_f(step, walker.speed * (1.0 - v.w.slow), 0.15) and _near_f(_lost(striker, hp0), 10.0 * (1.0 + v.w.expose)),
		"용병이 받은 한 방 %s(6.5) · 1초에 %s칸(1.2) · 받은 피해 %s(12)" % [bite, step, _lost(striker, hp0)])

# EV281 · S154: E는 대상과 3칸 안 적 4명(체력 높은 차례)을 묶는다. 하나가 피해 100을 받으면 나머지가 35씩 고정 피해로 받고, 다시 나뉘지 않는다
func ev281():
	var b = _kit([["vesper", Vector2i(10, 6)]])
	var v = b.hero
	_quiet(b)
	var t = _dummy(b, Vector2i(12, 10))
	var others := []
	for i in 5:
		var e = _dummy(b, Vector2i(11 + i, 12))
		e.hp = 5000.0 - i * 1000.0
		others.append(e)
	_start(b)
	b.cast(v, "e", t)
	var before := others.map(func(e): return e.hp)
	b.damage(t, 100.0)
	var got := []
	for i in 5:
		got.append(before[i] - others[i].hp)
	var want := [35.0, 35.0, 35.0, 35.0, 0.0]
	var ok := _near_f(_lost(t, BIG), 100.0)
	for i in 5:
		ok = ok and _near_f(got[i], want[i] * v.e.share / 0.35, 0.001)
	return check(ok, "대상 %s(100) · 나머지 %s(%s)" % [_lost(t, BIG), got, want])

# EV282 · S155·S154: 늪 안에서 봉인된 비행 적은 용병 몸에 막혀 지나가지 못하고(늪이 없으면 지나간다), 늪 안 적은 초당 최대 체력 4%를 받는다
func ev282():
	var ends := []
	for swamp in [true, false]:
		var b = _kit([["vesper", Vector2i(14, 5)]], {"base": Vector2i(2, 10), "spawns": [Vector2i(29, 10)]})
		_quiet(b)
		var m = b.place_merc("soldier", Vector2i(15, 10), {"hp": BIG, "damage": 0, "range": 0, "sight": 0})
		var flyer = b.spawn_enemy("flying", Vector2i(17, 10), {"sight": 0, "hp": BIG})
		var d = _dummy(b, Vector2i(14, 8), {"hp": 1000})
		_start(b)
		if swamp:
			b.cast(b.hero, "r", Vector2(15, 9))
		run(b, 4.0)
		ends.append([flyer.pos.x, m.hp < m.max_hp, 1000.0 - d.hp])
	var v_burn: float = battle().HERO_KINDS.vesper.r.burn
	return check(ends[0][0] > 15.5 and ends[0][1] and ends[1][0] < 14.0 and _near_f(ends[0][2], 4.0 * v_burn * 1000.0, 2.0),
		"늪: 비행 적 x %s(막힘) 용병 맞음 %s · 늪 없음: x %s(지나감) · 늪 4초 피해 %s(%s)" % [ends[0][0], ends[0][1], ends[1][0], ends[0][2], 4.0 * v_burn * 1000.0])

# EV283 · S155: 늪 안에서 봉인된 기어오르는 적은 성벽을 오르지 못한다(늪이 없으면 오른다)
func ev283():
	var tops := []
	for swamp in [true, false]:
		var walls := []
		for x in 30:
			if x != 15:
				walls.append(Vector2i(x, 9))
		var b = _kit([["vesper", Vector2i(9, 13)]], {"base": Vector2i(15, 4), "spawns": [Vector2i(14, 19)], "village": Rect2i(0, 0, 30, 9),
			"castle": {"walls": walls, "gates": [Vector2i(15, 9)], "wall_hp": 300, "gate_hp": 150}})
		_quiet(b)
		var f = b.spawn_enemy("fast", Vector2i(14, 12), {"hp": BIG, "sight": 0})
		_start(b)
		if swamp:
			b.cast(b.hero, "r", Vector2(14, 10))
		var seen := {"up": false}  # 람다는 지역 변수를 복사해 가져가서 사전에 적는다
		run(b, 4.8, func():
			seen.up = seen.up or f.on_wall
			return false)
		tops.append(seen.up)
	return check(not tops[0] and tops[1], "늪 안에서 오름 %s · 늪 없이 오름 %s" % [tops[0], tops[1]])

# ── 이그니스(S156) ──

# EV284 · S156: Q는 반경 1.5 적에게 마법 25와 발화. W는 반경 2 적에게 마법 15와 둔화, 발화 중인 적은 열충격(15 더, 빙결)
func ev284():
	var b = _kit([["ignis", H]])
	var g = b.hero
	_quiet(b)
	var d1 = _dummy(b, H + Vector2i(3, 0))
	var d2 = _dummy(b, H + Vector2i(3, 2))
	_start(b)
	b.cast(g, "q", Vector2(H + Vector2i(3, 0)))
	var q_ok: bool = _near_f(_lost(d1, BIG), g.q.damage) and b.effect_sum(d1, "dot") > 0.0 and d2.hp == d2.max_hp
	b.cast(g, "w", Vector2(H + Vector2i(3, 1)))
	var shock: bool = _near_f(_lost(d1, BIG), g.q.damage + g.w.damage + g.w.shock) and b.effect(d1, "stun") != null
	var cold: bool = _near_f(_lost(d2, BIG), g.w.damage) and b.effect(d2, "stun") == null and _near_f(b.effect_sum(d2, "slow"), g.w.slow)
	return check(q_ok and shock and cold, "Q 피해·발화 %s · 발화 적 열충격 %s(%s) · 발화 아닌 적 15·둔화 %s(%s)" % [q_ok, shock, _lost(d1, BIG), cold, _lost(d2, BIG)])

# EV285 · S156: E 중력장은 안의 적을 초당 1.5칸씩 중심으로 끌어당기고(보스도) 마법 저항을 20% 깎는다
func ev285():
	var b = _kit([["ignis", H]])
	var g = b.hero
	_quiet(b)
	var d = _dummy(b, H + Vector2i(4, 2))
	var boss = b.spawn_enemy("boss", H + Vector2i(4, -2), {"speed": 0, "sight": 0, "damage": 0, "hp": BIG})
	var mid := Vector2(H + Vector2i(4, 0))
	_start(b)
	b.cast(g, "e", mid)
	run(b, 1.0)
	var pulled: bool = _near_f(d.pos.distance_to(mid), 2.0 - g.e.pull, 0.1) and _near_f(boss.pos.distance_to(mid), 2.0 - g.e.pull, 0.1)
	var hp0: float = d.hp
	b.damage(d, 10.0, "magic")
	return check(pulled and _near_f(_lost(d, hp0), 10.0 * (1.0 - g.e.mr)), "끌림 %s(%s, %s) · 마법 10에 %s" % [pulled, d.pos.distance_to(mid), boss.pos.distance_to(mid), _lost(d, hp0)])

# EV286 · S156: R 운석은 0.5초 간격으로 셋이 떨어진다(지점, 수직 양옆 1칸). 각 마법 40과 기절 1초, 떨어진 자리는 용암
func ev286():
	var b = _kit([["ignis", H]])
	var g = b.hero
	_quiet(b)
	var mid = _dummy(b, Vector2i(14, 10), {"hp": 1000})
	var top = _dummy(b, Vector2i(14, 7), {"hp": 1000})  # 수직 한쪽 운석(14,9)에서 2칸이라 운석은 맞지 않고, 그 칸 위 용암에도 들지 않는다
	_start(b)
	b.cast(g, "r", Vector2(14, 10))
	run(b, 0.4)
	var none: bool = mid.hp == mid.max_hp
	run(b, 0.15)
	var first: bool = mid.max_hp - mid.hp >= g.r.damage and mid.max_hp - mid.hp < g.r.damage + 5.0 and b.effect(mid, "stun") != null
	run(b, 1.1)
	var three: bool = mid.max_hp - mid.hp >= 3.0 * g.r.damage
	var lava: int = b.zones.filter(func(z): return z.src == "ignis_r").size()
	return check(none and first and three and lava == 3 and top.hp == top.max_hp, "0.4초 그대로 %s · 0.55초 첫 운석 %s · 1.65초 셋 %s(%s) · 용암 %d곳 · 2칸 밖 그대로 %s" % [none, first, three, mid.max_hp - mid.hp, lava, top.hp == top.max_hp])

# EV287 · S156: 스킬을 3번 쓰면 다음 Q의 반경이 ×1.3이 되고 대기가 2초 준다. 오라 안 영웅은 초당 마나가 2.5 더 찬다
func ev287():
	var b = _kit([["ignis", H], ["bastion", H + Vector2i(0, 2)], ["bastion", Vector2i(25, 3)]])
	var g = b.hero
	_quiet(b)
	var edge = _dummy(b, Vector2i(17, 10))
	_start(b)
	for slot in ["q", "w", "e"]:
		b.cast(g, slot, Vector2(12, 14))  # 과녁에서 멀리
	g.mana = g.max_mana
	g.cd.q = 0.0
	var spot := Vector2(15.1, 10)  # 과녁에서 1.9칸: 반경 1.5 밖, 1.5 × 1.3 = 1.95 안
	var untouched: bool = edge.hp == edge.max_hp and spot.distance_to(Vector2(17, 10)) > g.q.radius
	b.cast(g, "q", spot)
	var grown: bool = untouched and edge.hp < edge.max_hp and _near_f(g.cd.q, g.q.gap - g.passive.cut)
	var near_b = b.heroes[1]
	var far_b = b.heroes[2]
	near_b.mana = 0.0
	far_b.mana = 0.0
	run(b, 2.0)
	return check(grown and _near_f(near_b.mana, 2.0 * (near_b.mana_regen + g.aura.mana), 0.2) and _near_f(far_b.mana, 2.0 * far_b.mana_regen, 0.2),
		"넷째 Q 반경·대기 %s(대기 %s) · 오라 안 2초 마나 %s · 밖 %s" % [grown, g.cd.q, near_b.mana, far_b.mana])

# ── 크로노스(S158) ──

# EV288 · S158: 오라 안 영웅은 15% 빨리 걷는다
func ev288():
	var b = _kit([["chronos", H], ["bastion", H + Vector2i(0, 1)], ["bastion", Vector2i(3, 18)]])
	var near_b = b.heroes[1]
	var far_b = b.heroes[2]
	b.order_move([near_b], H + Vector2i(0, 1) + Vector2i(2, 0))
	b.order_move([far_b], Vector2i(3, 18) + Vector2i(2, 0))
	var p1: Vector2 = near_b.pos
	var p2: Vector2 = far_b.pos
	for i in 10:
		b.step(DT)
	var ratio: float = near_b.pos.distance_to(p1) / far_b.pos.distance_to(p2)
	return check(_near_f(ratio, 1.0 + b.hero.aura.stride, 0.01), "오라 안 걸음 ÷ 밖 걸음 %s(%s)" % [ratio, 1.0 + b.hero.aura.stride])

# EV289 · S158·I146: Shift+Q로 자동 시전을 켜면 사거리 안에서 그 효과가 없는 가장 공격력 높은 대상에 쓴다. Q를 받은 타워는 한 방이 ×1.2다
func ev289():
	var b = _kit([["chronos", H], ["ignis", H + Vector2i(0, 2)]])
	var c = controls(b)
	var ch = b.hero
	var ig = b.heroes[1]
	ig.damage = 0.0
	ch.damage = 0.0
	var tw = b.build("tower", H + Vector2i(2, 0))
	var mg = b.build("magic", H + Vector2i(-2, 0))
	_start(b)
	c.skill_key("q", true)
	ig.damage = 7.0
	b.step(DT)
	var first: bool = ch.auto and b.effect_sum(ig, "might") > 0.0 and b.effect_sum(mg, "might") == 0.0
	run(b, ch.q.gap + 0.1)
	var second: bool = b.effect_sum(mg, "might") > 0.0 and b.effect_sum(tw, "might") == 0.0
	ig.damage = 0.0
	var d = _dummy(b, H + Vector2i(4, 1))
	ch.cd.q = 0.0
	ch.auto = false
	b.cast(ch, "q", tw)
	tw.cooldown = 0.0
	run(b, 1.0, func(): return d.hp < d.max_hp)
	return check(first and second and _near_f(_lost(d, BIG), tw.damage * (1.0 + ch.q.might)), "첫 자동: 이그니스 %s · 둘째: 마법 타워 %s · Q 받은 타워 한 방 %s(%s)" % [first, second, _lost(d, BIG), tw.damage * (1.0 + ch.q.might)])

# EV290 · S158·I145: W는 다른 영웅의 마나를 최대 마나 25%만큼 채우고 Q·W·E 대기를 5초씩 줄인다. 자기 자신에게는 쓰지 못한다
func ev290():
	var b = _kit([["chronos", H], ["bastion", H + Vector2i(2, 0)]])
	var ch = b.hero
	var k = b.heroes[1]
	_start(b)
	k.mana = 50.0
	k.cd.q = 6.0
	k.cd.w = 10.0
	var self_ok: bool = b.cast(ch, "w", ch)
	b.cast(ch, "w", k)
	return check(not self_ok and _near_f(k.mana, 50.0 + ch.w.mana_back * k.max_mana) and _near_f(k.cd.q, 1.0) and _near_f(k.cd.w, 5.0),
		"자기에게 씀 %s · 마나 %s · Q 대기 %s · W 대기 %s" % [self_ok, k.mana, k.cd.q, k.cd.w])

# EV291 · S158·I149: E 결계 안에서 처치된 적의 골드는 보상 × 1.3을 반올림한 값이다(기본 5 → 7, 장갑 8 → 10). 결계 밖은 그대로다
func ev291():
	var b = _kit([["chronos", H]])
	var ch = b.hero
	_quiet(b)
	var inside = _dummy(b, H + Vector2i(1, 0))
	var armored = b.spawn_enemy("armored", H + Vector2i(0, 1), {"speed": 0, "sight": 0, "damage": 0})
	var outside = _dummy(b, H + Vector2i(6, 0))
	_start(b)
	b.cast(ch, "e")
	var g0: int = b.gold
	b.damage(inside, BIG)
	var g1: int = b.gold
	b.damage(armored, BIG)
	var g2: int = b.gold
	b.damage(outside, BIG)
	return check(g1 - g0 == 7 and g2 - g1 == 10 and b.gold - g2 == 5, "결계 안 기본 +%d(7) · 장갑 +%d(10) · 밖 기본 +%d(5)" % [g1 - g0, g2 - g1, b.gold - g2])

# EV292 · S158: R 왜곡장 안의 적은 이동·공격 속도가 반이 되고, 안의 영웅은 스킬 대기가 1.5배 빠르게 준다
func ev292():
	var b = _kit([["chronos", H]], {"base": Vector2i(2, 15), "spawns": [Vector2i(29, 15)]})
	var ch = b.hero
	_quiet(b)
	var walker = b.spawn_enemy("basic", Vector2i(13, 10), {"sight": 0, "hp": BIG})
	_start(b)
	b.cast(ch, "r", Vector2(12, 10))
	b.step(DT)
	ch.cd.q = 5.0
	walker.cooldown = 1.0
	var p0: Vector2 = walker.pos
	b.step(DT)
	var moved: float = walker.pos.distance_to(p0)
	return check(_near_f(moved, walker.speed * DT * (1.0 - ch.r.slow), 0.002) and _near_f(1.0 - walker.cooldown, DT * (1.0 - ch.r.lag), 0.0001) and _near_f(5.0 - ch.cd.q, DT * (1.0 + ch.r.cdr), 0.0001),
		"적 한 스텝 걸음 %s · 적 공격 대기 줄음 %s · 영웅 Q 대기 줄음 %s" % [moved, 1.0 - walker.cooldown, 5.0 - ch.cd.q])

# ── 추론 문장 ──

# EV293 · I143: 웨이브가 끝나면 장판·에너지 성벽·보호막·태세가 사라지고, 재사용 대기와 마나는 그대로다
func ev293():
	var b = _kit([["bastion", H]])
	var k = b.hero
	_quiet(b)
	var foe = _dummy(b, H + Vector2i(2, 0))
	_start(b)
	b.cast(k, "w")
	b.cast(k, "e")
	k.mana = k.max_mana
	b.cast(k, "r", Vector2(H + Vector2i(4, 0)))
	var had: bool = not b.zones.is_empty() and not b.barriers.is_empty() and not k.shields.is_empty() and k.brace > 0.0
	var keep := [k.cd.w, k.cd.e, k.cd.r, k.mana]
	b.damage(foe, BIG)
	for e in b.enemies.duplicate():
		b.damage(e, BIG)
	b.step(DT)
	var now := [k.cd.w, k.cd.e, k.cd.r, k.mana]
	var kept := true  # 마지막 전투 스텝 한 번만큼(대기 −DT, 마나 +2·DT)만 다르다
	for i in 4:
		kept = kept and _near_f(now[i], keep[i], 0.11)
	return check(had and b.state == "prep" and b.zones.is_empty() and b.barriers.is_empty() and k.shields.is_empty() and k.brace == 0.0 and kept,
		"있었음 %s · %s · 장판 %d · 성벽 %d · 보호막 %d · 태세 %s · 대기·마나 그대로 %s(%s → %s)" % [had, b.state, b.zones.size(), b.barriers.size(), k.shields.size(), k.brace, kept, keep, now])

# EV294 · I145: 대상이 맞지 않으면 쓰지 않는다(세라피나 Q를 적에게, 베스퍼 E를 용병에게). 조준 중 맞는 대상이 없는 곳을 누르면 조준이 이어진다
func ev294():
	var b = _kit([["seraphina", H], ["vesper", H + Vector2i(0, 2)]])
	var c = controls(b)
	var foe = _dummy(b, H + Vector2i(2, 0))
	var m = b.place_merc("soldier", H + Vector2i(-2, 0))
	_start(b)
	var bad: bool = not b.cast(b.heroes[0], "q", foe) and not b.cast(b.heroes[1], "e", m) and b.heroes[0].skill_uses == 0 and b.heroes[1].skill_uses == 0
	_key(c, KEY_F1)
	_key(c, KEY_Q)
	click(c, MOUSE_BUTTON_LEFT, px(H + Vector2i(5, 5)))
	var waiting: bool = c.aiming == "q" and b.heroes[0].skill_uses == 0
	click(c, MOUSE_BUTTON_LEFT, px(H + Vector2i(-2, 0)))
	return check(bad and waiting and c.aiming == "" and b.heroes[0].skill_uses == 1, "맞지 않는 대상 거부 %s · 빈 곳 클릭에 조준 이어짐 %s · 용병 클릭에 씀 %s" % [bad, waiting, b.heroes[0].skill_uses == 1])

# EV295 · I142: 에너지 성벽 칸에는 짓지 못하고, 피해를 받아도 깎이지 않는다
func ev295():
	var b = _kit([["bastion", H]])
	var k = b.hero
	_start(b)
	b.cast(k, "r", Vector2(H + Vector2i(4, 0)))
	var c := Vector2i(H + Vector2i(4, 0))
	var wall = b.barriers.get(c)
	if wall == null:
		return "에너지 성벽이 서지 않았다(%s)" % [b.barriers.keys()]
	var hp0: float = wall.hp
	b.damage(wall, 1000.0)
	return check(b.build("wall", c) == null and wall.hp == hp0 and wall.alive, "짓기 거부 %s · 깎이지 않음 %s" % [b.build("wall", c) == null, wall.hp == hp0])

# EV296 · S157: data/heroes의 영웅은 bastion·sylvia(동), seraphina·vesper(은), ignis·chronos(금)다
func ev296():
	var kinds: Dictionary = battle().HERO_KINDS
	var want := {"bastion": 1, "sylvia": 1, "seraphina": 2, "vesper": 2, "ignis": 3, "chronos": 3}
	var got := {}
	for k in kinds:
		got[k] = kinds[k].grade
	return check(got == want, "영웅·등급 %s(%s여야 한다)" % [got, want])
