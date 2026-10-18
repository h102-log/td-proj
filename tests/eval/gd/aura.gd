extends "res://tests/eval/gd/lib.gd"
# 영웅 오라(S96·I83). lib.gd·heroes.gd 머리의 계약에 더하는 API:
#   영웅: aura(사전: radius 반경 칸 · armor 방어력 + …) · Battle.armor_mult(방어력) — 물리 피해 배율(S149)
# 2026-10-18 영웅 개편으로 기사 오라(«용병이 받는 피해 −15%»)가 없어져, 오라가 다운으로 풀리고 복귀하면 다시 걸리는 것은 세라피나 오라(방어력 +6, S152)로 잰다.
# 기사 오라 고유의 평가(EV146·EV149·EV150)는 기각했다(EVAL.md ## 기각). 반경·수치는 영웅 필드에서 읽는다

const H := Vector2i(10, 10)  # 영웅
const IN := Vector2i(11, 10)  # 영웅 바로 옆 용병
const HIT := 10.0  # 적 한 방의 피해

# 움직이지 않고, 인식 범위 안에서 가장 가까운 아군을 치는 적. 죽지 않는다
func _striker(b, cell: Vector2i):
	return b.spawn_enemy("basic", cell, {"speed": 0, "damage": HIT, "hp": BIG})

# 죽지 않는 용병
func _merc(b, kind: String, cell: Vector2i):
	return b.place_merc(kind, cell, {"hp": BIG})

# u가 다음에 맞는 한 방의 피해. secs 안에 안 맞으면 0
func _next_hit(b, u, secs := 5.0) -> float:
	var h0: float = u.hp
	run(b, secs, func(): return u.hp < h0)
	return h0 - u.hp

# 오라 안 용병이 받는 한 방
func _guarded(b) -> float:
	return HIT * b.armor_mult(b.hero.aura.armor)

func _seraphina(over := {}):
	var stage := {"heroes": [{"kind": "seraphina", "cell": H}]}
	stage.merge(over, true)
	return battle(stage)

# EV147 · S96: 영웅이 다운되면 오라가 풀려 옆 용병이 피해를 그대로 받는다
func ev147():
	var b = _seraphina()
	var m = _merc(b, "soldier", IN)
	_striker(b, IN + Vector2i(1, 0))
	var before := _next_hit(b, m)
	if not is_equal_approx(before, _guarded(b)):
		return "다운 전 한 방이 %s다(%s여야 한다)" % [before, _guarded(b)]
	b.damage(b.hero, BIG)
	var after := _next_hit(b, m)
	return check(is_equal_approx(after, HIT), "영웅이 다운된 뒤 한 방이 %s다(%s여야 한다)" % [after, HIT])

# EV148 · I83: 웨이브 중 다운된 영웅이 다음 준비 단계에 복귀하면 오라가 다시 걸린다
func ev148():
	var b = _seraphina({"waves": [[{"kind": "basic", "count": 1}], [{"kind": "basic", "count": 1}]]})
	b.start_battle()
	b.damage(b.hero, BIG)
	if not clear_wave(b):
		return "첫 웨이브가 끝나지 않았다(%s)" % b.state
	if b.state != "prep" or not b.hero.alive:
		return "준비 단계에 영웅이 돌아오지 않았다(상태 %s, 영웅 생존 %s)" % [b.state, b.hero.alive]
	var m = _merc(b, "soldier", IN)
	_striker(b, IN + Vector2i(1, 0))
	var hit := _next_hit(b, m)
	return check(is_equal_approx(hit, _guarded(b)), "복귀한 영웅 옆 용병의 한 방이 %s다(%s여야 한다)" % [hit, _guarded(b)])
