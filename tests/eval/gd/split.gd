extends "res://tests/eval/gd/lib.gd"
# 적 갈라짐(S234·I186). lib.gd 머리의 계약에 더하는 API:
#   적 kind "slime"(슬라임) · "slimelet"(꼬마 슬라임) · "big_slime"(큰 슬라임) · 적 reward·xp·fx(출처 → {효과 키: 값, left: 남은 초})
#   Battle.enemies_left() · stage 키 hp_mult(라운드마다 체력 배율, S144)

const STILL := {"speed": 0, "sight": 0, "damage": 0}

func _alive(b, kind: String) -> Array:
	return b.enemies.filter(func(e): return e.alive and e.kind == kind)

func _at(es: Array, p: Vector2) -> bool:
	return es.any(func(e): return e.pos.distance_to(p) <= 0.01)

# EV518 · S234: 슬라임이 죽으면 둘레 0.25칸 동·서에 꼬마 둘. 꼬마는 보상·경험치 0, 체력 5이고 골드는 슬라임 몫만 는다
func ev518():
	var b = battle({"gold": 0})
	if not b.ENEMY_KINDS.has("slime"):
		return "적 종류 slime이 없다"
	var s = b.spawn_enemy("slime", Vector2i(10, 10), STILL)
	b.damage(s, BIG)
	var kids := _alive(b, "slimelet")
	var g: int = b.gold
	var out := check(kids.size() == 2 and _at(kids, Vector2(10.25, 10)) and _at(kids, Vector2(9.75, 10)) and g == 15
		and kids.all(func(k): return k.reward == 0 and k.xp == 0 and is_equal_approx(k.hp, 5.0)),
		"꼬마 [자리, 보상, 경험치, 체력] %s · 골드 %d(15여야 한다)" % [kids.map(func(k): return [k.pos, k.reward, k.xp, k.hp]), g])
	if out != "":
		return out
	for k in kids:
		b.damage(k, BIG)
	return check(b.gold == g, "꼬마 둘을 처치한 뒤 골드 %d(%d여야 한다)" % [b.gold, g])

# EV519 · S234: 큰 슬라임 → 슬라임 둘(보상·경험치 0) → 꼬마 넷. 꼬마까지 모두 죽어야 웨이브가 끝나고, 골드는 큰 슬라임 몫만 는다
func ev519():
	var b = battle({"base_hp": BIG, "gold": 0, "waves": [[{"kind": "big_slime", "count": 1}]]})
	if not b.ENEMY_KINDS.has("big_slime"):
		return "적 종류 big_slime이 없다"
	b.start_battle()
	if not run(b, 5.0, func(): return not b.enemies.is_empty()):
		return "큰 슬라임이 나오지 않았다"
	var seen := []
	var kills := 0
	for kind in ["big_slime", "slime", "slimelet"]:
		var es := _alive(b, kind)
		seen.append(es.size())
		if kind == "slime" and not es.all(func(e): return e.reward == 0 and e.xp == 0):
			return "큰 슬라임에서 갈라져 나온 슬라임의 [보상, 경험치] %s(모두 0이어야 한다)" % [es.map(func(e): return [e.reward, e.xp])]
		if kind == "slimelet" and (b.enemies_left() != 4 or b.state != "battle"):
			return "꼬마 %d마리일 때 남은 적 %d · 단계 %s(4 · battle이어야 한다)" % [es.size(), b.enemies_left(), b.state]
		for e in es:
			b.damage(e, BIG)
			kills += 1
	b.step(DT)
	return check(seen == [1, 2, 4] and kills == 7 and b.state != "battle" and b.gold == 35,
		"차례대로 나온 수 %s([1, 2, 4]여야 한다) · 처치 %d · 단계 %s · 골드 %d(35여야 한다)" % [seen, kills, b.state, b.gold])

# EV520 · S234: 갈라져 나온 적은 효과를 물려받지 않고 전염도 옮지 않으며, 체력에 라운드 체력 배율이 곱해진다
func ev520():
	var b = battle({"hp_mult": [2.0]})
	if not b.ENEMY_KINDS.has("slime"):
		return "적 종류 slime이 없다"
	var s = b.spawn_enemy("slime", Vector2i(10, 10), STILL)
	var o = b.spawn_enemy("basic", Vector2i(11, 10), STILL.merged({"hp": BIG}))
	s.fx["test"] = {"slow": 0.5, "stun": true, "seal": true, "left": 5.0}
	s.fx["vesper_q"] = {"dot": 1.0, "spread": 3.0, "left": 5.0}
	b.damage(s, BIG)
	var kids := _alive(b, "slimelet")
	return check(kids.size() == 2 and kids.all(func(k): return k.fx.is_empty() and is_equal_approx(k.hp, 10.0)) and o.fx.has("vesper_q"),
		"꼬마 [효과, 체력] %s · 옆 기본 적 중독 %s" % [kids.map(func(k): return [k.fx.keys(), k.hp]), o.fx.has("vesper_q")])

# EV521 · I186: 갈라져 나온 적은 출현 신호를 내지 않고, 둘레 자리가 막힌 칸이면 죽은 자리에 놓이며, 죽은 적이 노리던 성문을 이어 노린다
func ev521():
	var b = battle()
	if not b.ENEMY_KINDS.has("slime"):
		return "적 종류 slime이 없다"
	var n := [0]
	b.enemy_spawned.connect(func(_e): n[0] += 1)
	b.damage(b.spawn_enemy("slime", Vector2i(10, 5), STILL), BIG)
	var made := _alive(b, "slimelet")
	if n[0] != 1 or made.size() != 2:
		return "슬라임 하나를 두고 처치한 뒤 출현 신호 %d(1이어야 한다) · 꼬마 %d" % [n[0], made.size()]
	for k in made:  # 다음 측정과 섞이지 않게 치운다
		b.damage(k, BIG)
	if b.build("wall", Vector2i(11, 10)) == null:
		return "칸 (11,10)에 방벽을 짓지 못했다"
	var w = b.spawn_enemy("slime", Vector2i(10, 10), STILL)
	w.pos = Vector2(10.4, 10)
	w.via = Vector2i(12, 10)
	b.damage(w, BIG)
	var kids := _alive(b, "slimelet")
	return check(kids.size() == 2 and _at(kids, Vector2(10.4, 10)) and _at(kids, Vector2(10.15, 10)) and kids.all(func(k): return k.via == Vector2i(12, 10)),
		"방벽 옆에서 갈라진 꼬마 [자리, via] %s" % [kids.map(func(k): return [k.pos, k.via])])
