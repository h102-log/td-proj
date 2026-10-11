extends "res://tests/eval/gd/lib.gd"

func _waves(n: int) -> Array:
	var ws := []
	for i in n:
		ws.append([{"kind": "basic", "count": 1}])
	return ws

# EV34 · S17: 웨이브 3개짜리 판은 준비→전투를 세 번 되풀이한다
func ev34():
	var b = battle({"base_hp": BIG, "waves": _waves(3)})
	var seq := [b.state]
	for i in 3:
		b.start_battle()
		seq.append(b.state)
		clear_wave(b)
		seq.append(b.state)
	var want := ["prep", "battle", "prep", "battle", "prep", "battle", "won"]
	return check(seq == want, "단계 순서가 %s다" % [seq])

# EV35 · S18: 준비 단계의 건설은 그 자리에서 완성된다
func ev35():
	var b = battle()
	var s = b.build("wall", Vector2i(10, 10))
	return check(s != null and s.complete and s.hp == s.max_hp, "준비 단계 건설이 바로 완성되지 않았다")

# EV36 · S29: 패배한 판을 재시작하면 처음 상태로 돌아간다
func ev36():
	var b = battle({"gold": 500, "waves": _waves(2)})
	b.build("wall", Vector2i(10, 3))
	b.start_battle()
	b.damage(b.base, BIG)
	if b.state != "lost":
		return "거점이 무너졌는데 패배가 아니다"
	b.restart()
	var ok: bool = b.base.hp == b.base.max_hp and b.gold == 500 and b.state == "prep" and b.wave_index == 0
	return check(ok, "재시작 뒤 상태: 거점 %d/%d, 골드 %d, %s, 웨이브 %d" % [b.base.hp, b.base.max_hp, b.gold, b.state, b.wave_index])

# EV37 · I14: 마지막 웨이브를 다 처치하면 승리
func ev37():
	var b = battle({"base_hp": BIG, "waves": _waves(2)})
	for i in 2:
		b.start_battle()
		clear_wave(b)
	return check(b.state == "won", "마지막 웨이브 뒤 판 상태가 %s다" % b.state)

# EV38 · I15: 적을 처치하면 처치 보상만큼 골드가 는다
func ev38():
	var b = battle({"gold": 0})
	var e = b.spawn_enemy("basic", Vector2i(10, 10))
	b.damage(e, BIG)
	return check(e.reward > 0 and b.gold == e.reward, "처치 보상 %d, 골드 %d" % [e.reward, b.gold])

# EV39 · I16: 골드가 모자라면 건설이 거부되고 아무것도 바뀌지 않는다
func ev39():
	var b = battle({"gold": 0})
	var s = b.build("wall", Vector2i(10, 10))
	return check(s == null and b.gold == 0 and b.structure_at(Vector2i(10, 10)) == null, "골드 0인데 건설됐다")
