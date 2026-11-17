extends "res://tests/eval/gd/lib.gd"
# 파도·집결(S375)·라운드 안 자동 진행(S17 2026-11-17 변경)·전투 중 영웅 복귀(S26·S138 2026-11-17 변경). lib.gd 머리의 API에 더하는 것:
#   stage 키 surges([라운드][웨이브] 파도 수) · muster_first · muster(집결 초) · wake_batch · pressure_cap · wave_climax · band_rows
#            hero_back · hero_back_hp · hero_back_cell
#   Battle.dormant(집결 띠에 잠든 적) · Battle.mustering() · Battle.muster_wave() · Battle.muster_surge() → [차례, 파도 수] · Battle.muster_left
#   Battle.drum() → bool · Battle.waves_done · Battle.enemies_left() · Battle.back_cell()

const SPAWN := Vector2i(0, 10)

func _one(n: int) -> Array:
	return [{"kind": "basic", "count": n}]

# 첫 웨이브(적 1)는 ▶로 바로 오고(S375 — ▶가 첫 북), 둘째 웨이브(적 12, 파도 3)가 집결을 잰다
func _stage(over := {}) -> Dictionary:
	var st := {"base_hp": BIG, "waves": [_one(1), _one(12)], "surges": [[1, 3]], "muster_first": 2.0, "muster": 1.0, "wake_batch": 4, "spawn_gap": 0.05}
	st.merge(over, true)
	return st

# ▶를 누르고 첫 웨이브의 적 하나를 처치해 둘째 웨이브 첫 파도의 집결만 남긴 때. 흐른 시간은 DT 한 스텝이다
func _past_first(b) -> void:
	b.start_battle()
	b.step(DT)
	kill_all(b)

func _kinds(es: Array) -> Dictionary:
	var d := {}
	for e in es:
		d[e.kind] = d.get(e.kind, 0) + 1
	return d

# EV1168 · S17 2026-11-17 변경: 집결 0초인 웨이브 3개짜리 라운드는 ▶ 한 번에 끝까지 저절로 간다. 웨이브가 끝나도 전투 단계가 이어지고 준비 단계로 돌아가지 않으며,
#   마지막 웨이브가 끝나면 승리다. 전투 단계의 start_battle()은 북이라 집결 중이 아니면 아무 일도 하지 않는다
func ev1168():
	var b = battle({"base_hp": BIG, "waves": [_one(1), _one(1), _one(1)], "muster_first": 0.0})
	var seq := [b.state]
	b.start_battle()
	seq.append(b.state)
	var done := [b.waves_done]
	for i in 3:
		if not run(b, 30.0, func():
				kill_all(b)
				return b.waves_done > i or b.state != "battle"):
			return "%d웨이브가 끝나지 않았다(%s)" % [i + 1, b.state]
		seq.append(b.state)
		done.append(b.waves_done)
		b.start_battle()
	return check(seq == ["prep", "battle", "battle", "battle", "won"] and done == [0, 1, 2, 3],
		"단계 차례 %s(prep·battle·battle·battle·won) · 끝난 웨이브 %s(0·1·2·3)" % [seq, done])

# EV1169 · S375: 첫 웨이브(적 1)는 ▶로 바로 오고, 적 12의 둘째 웨이브를 파도 3개로 가르면 ▶ 직후 그 첫 파도 4마리가 잠들어 있다(들판에는 없다).
#   집결 2초가 지나면 한 스텝에 모두 깨어나며 다음 파도 4마리가 잠든다. 그다음 파도는 1초 뒤다. 남은 적은 아직 안 나온 적까지 센다
func ev1169():
	var b = battle(_stage())
	_past_first(b)
	var at0 := [b.dormant.size(), b.enemies.size(), b.enemies_left(), b.mustering(), b.muster_wave(), b.muster_surge()]
	run(b, 1.8)
	var at19 := [b.dormant.size(), b.enemies.size()]
	run(b, 0.2)
	var at21 := [b.dormant.size(), b.enemies.size(), b.muster_surge()]
	run(b, 1.1)
	var at32 := [b.dormant.size(), b.enemies.size(), b.muster_surge()]
	run(b, 1.1)
	var at43 := [b.dormant.size(), b.enemies.size(), b.mustering(), b.enemies_left()]
	var want0 := [4, 0, 12, true, 1, [1, 3]]
	return check(at0 == want0 and at19 == [4, 0] and at21 == [4, 4, [2, 3]] and at32 == [4, 8, [3, 3]] and at43 == [0, 12, false, 12],
		"▶ 직후 %s(%s) · 1.9초 %s([4, 0]) · 2.1초 %s([4, 4, [2, 3]]) · 3.2초 %s([4, 8, [3, 3]]) · 4.3초 %s([0, 12, false, 12])" % [at0, want0, at19, at21, at32, at43])

# EV1170 · S375: 잠든 적은 대상이 되지 않고 피해를 받지 않는다 — 출현 칸을 사거리 안에 둔 타워가 집결 10초 동안 쏘지 않고 잠든 적의 체력이 가득하다. 깨어나면 쏜다
func ev1170():
	var b = battle(_stage({"waves": [_one(1), _one(5)], "surges": [[1, 1]], "muster_first": 10.0}))
	var t = b.build("tower", Vector2i(3, 10))
	if t == null:
		return "타워를 짓지 못했다"
	_past_first(b)
	t.target = null
	run(b, 5.0)
	var asleep: bool = b.dormant.size() == 5 and b.enemies.is_empty() and t.target == null and b.dormant.all(func(e): return e.hp == e.max_hp)
	b.drum()
	var hit := run(b, 3.0, func(): return b.enemies.any(func(e): return e.hp < e.max_hp))
	return check(asleep and hit, "집결 5초: 잠든 %d·들판 %d·타워 대상 %s·가득 %s · 깨어난 뒤 3초 안에 맞음 %s" % [b.dormant.size(), b.enemies.size(), t.target, asleep, hit])

# EV1171 · S375: 북 — 준비 단계의 drum()은 거부되고, 집결 30초 중 drum()을 부르면 다음 스텝에 그 파도가 돌격한다. 집결 중이 아니면 거부된다
func ev1171():
	var b = battle(_stage({"waves": [_one(1), _one(6)], "surges": [[1, 1]], "muster_first": 30.0, "wake_batch": 6}))
	var in_prep: bool = b.drum()
	_past_first(b)
	run(b, 1.0)
	var drummed: bool = b.drum()
	var before: int = b.enemies.size()
	b.step(DT)
	var after: int = b.enemies.size()
	var again: bool = b.drum()
	return check(not in_prep and drummed and before == 0 and after == 6 and b.dormant.is_empty() and not again,
		"준비 단계 북 %s(false) · 집결 중 북 %s(true) · 들판 %d → %d(0 → 6) · 잠든 %d(0) · 다 깬 뒤 북 %s(false)" % [in_prep, drummed, before, after, b.dormant.size(), again])

# EV1172 · S375: pressure_cap 2인 판에서 파도 2개(각 2마리)의 둘째 파도는 살아 있는 적이 2 이상이면 집결 초가 다 지나도 돌격하지 않고, 하나가 죽어 2 아래가 되면 돌격한다
func ev1172():
	var b = battle(_stage({"waves": [_one(4)], "surges": [[2]], "muster_first": 0.0, "muster": 0.0, "pressure_cap": 2, "wake_batch": 2}))
	b.start_battle()
	run(b, 2.0)
	var held := [b.enemies.size(), b.dormant.size(), b.muster_left <= 0.0]
	b.damage(b.enemies[0], BIG)
	run(b, 0.3)
	var freed := [b.enemies.size(), b.dormant.size()]
	return check(held == [2, 2, true] and freed == [3, 0], "상한에 걸린 2초 뒤 [들판, 잠든, 집결 초 끝] %s([2, 2, true]) · 하나 죽인 뒤 %s([3, 0])" % [held, freed])

# EV1173 · S375: 기본 20·공성 램 2의 웨이브를 파도 2개로 가르면 램은 마지막 파도에 들고, 기본 적은 wave_climax 1이면 10·10, 3이면 5·15로 나뉜다
func ev1173():
	var out := []
	for climax in [1.0, 3.0]:
		var b = battle(_stage({"waves": [_one(1), [{"kind": "basic", "count": 20}, {"kind": "ram", "count": 2}]], "surges": [[1, 2]], "muster_first": 30.0, "muster": 30.0, "wave_climax": climax}))
		_past_first(b)
		var first := _kinds(b.dormant)
		b.drum()
		b.step(DT)
		out.append([first, _kinds(b.dormant)])
	var want := [[{"basic": 10}, {"basic": 10, "ram": 2}], [{"basic": 5}, {"basic": 15, "ram": 2}]]
	return check(out == want, "파도 [첫째, 둘째] 구성 climax 1: %s · climax 3: %s(기대 %s)" % [out[0], out[1], want])

# EV1174 · S26·S138 2026-11-17 변경: 전투 중 쓰러진 영웅은 hero_back 3초 뒤 거점 아래 칸에 최대 체력의 절반으로 돌아온다. 그동안은 전장에 없다
func ev1174():
	var b = battle({"base_hp": BIG, "waves": [_one(1)], "hero_start": Vector2i(20, 5), "hero_back": 3.0, "hero_back_hp": 0.5})
	b.start_battle()
	run(b, 0.2)
	b.damage(b.hero, BIG)
	run(b, 2.5)
	var away: bool = not b.hero.present and b.state == "battle"
	run(b, 0.6)
	var want_hp := floorf(b.hero.max_hp * 0.5)
	return check(away and b.hero.present and near(b.hero.pos, b.back_cell(), 0.01) and b.back_cell() == Vector2i(25, 11) and b.hero.hp == want_hp,
		"2.7초 뒤 없음 %s · 3.3초 뒤 있음 %s · 자리 %s(%s) · 체력 %.0f(%.0f)" % [away, b.hero.present, b.hero.pos, b.back_cell(), b.hero.hp, want_hp])

# EV1175 · S27·S26 2026-11-17 변경: 부활을 끄면 hero_back이 지나도 돌아오지 않고, 라운드가 끝나도 전장에 없다
func ev1175():
	var b = battle({"base_hp": BIG, "waves": [_one(1), _one(1)], "hero_start": Vector2i(20, 5), "hero_back": 1.0})
	b.revive = false
	b.start_battle()
	run(b, 0.2)
	b.damage(b.hero, BIG)
	run(b, 3.0)
	var mid: bool = not b.hero.present
	clear_round(b)
	return check(mid and not b.hero.present and b.state == "won", "3초 뒤 없음 %s · 라운드 끝(%s) 뒤 없음 %s" % [mid, b.state, not b.hero.present])
