extends "res://tests/eval/gd/lib.gd"
# WBS 2.18 데이터 구동(S31·I66). lib.gd 머리의 계약에 더하는 API:
#   Battle.ENEMY_KINDS · MERC_KINDS · STRUCTURE_KINDS — 종류 이름 → 수치. Battle.new 때 data/ 아래 Resource에서 읽는다
#   res://data/enemies/<kind>.tres(hp …) · data/mercs/<kind>.tres(cost …) · data/structures/<kind>.tres(damage …)
#   res://data/waves/test_stage.tres — waves: Array, 웨이브마다 {적 kind: 수}. 시험 스테이지(main.gd stage())가 쓴다

func _files(dir: String) -> Array:
	var out := []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".tres"):
			out.append(f.get_basename())
	out.sort()
	return out

func _keys(d: Dictionary) -> Array:
	var out := d.keys()
	out.sort()
	return out

# EV78 · I66: 폴더의 Resource 파일 이름 집합 = 판의 종류 집합
func ev78():
	var b = battle()
	for pair in [["res://data/enemies", b.ENEMY_KINDS], ["res://data/mercs", b.MERC_KINDS], ["res://data/structures", b.STRUCTURE_KINDS]]:
		var files := _files(pair[0])
		if files.is_empty():
			return "%s에 Resource 파일이 없다" % pair[0]
		if files != _keys(pair[1]):
			return "%s 파일 %s ≠ 종류 %s" % [pair[0], files, _keys(pair[1])]
	return ""

# EV79 · S31: Resource의 수치를 바꾸면 새 판에 그 값이 쓰인다
func ev79():
	var en = load("res://data/enemies/basic.tres")
	var me = load("res://data/mercs/soldier.tres")
	var to = load("res://data/structures/tower.tres")
	if en == null or me == null or to == null:
		return "Resource 파일을 불러오지 못했다"
	en.hp = 77.0
	me.cost = 13
	to.damage = 7.0
	var b = battle({"gold": 100})
	var e = b.spawn_enemy("basic", Vector2i(5, 5), {"speed": 0, "sight": 0, "damage": 0})
	if e.max_hp != 77.0:
		return "적 최대 체력이 %s다(77이어야 한다)" % e.max_hp
	if b.place_merc("soldier", Vector2i(20, 15)) == null or b.gold != 87:
		return "용병을 놓은 뒤 골드가 %d다(87이어야 한다)" % b.gold
	if b.build("tower", Vector2i(5, 7)) == null:
		return "타워를 짓지 못했다"
	if not run(b, 5.0, func(): return e.hp < e.max_hp):
		return "타워가 적을 쏘지 않았다"
	return check(is_equal_approx(e.max_hp - e.hp, 7.0), "타워의 한 방이 %s다(7이어야 한다)" % (e.max_hp - e.hp))

# EV80 · S31: 웨이브 Resource의 첫 웨이브 적 수를 바꾸면 시험 스테이지 첫 웨이브에 그만큼 나온다
func ev80():
	var w = load("res://data/waves/test_stage.tres")
	if w == null:
		return "웨이브 Resource를 불러오지 못했다"
	w.waves[0] = {"basic": 2}
	var b = load("res://src/sim/battle.gd").new(load("res://src/main.gd").stage())
	var n := [0]
	b.enemy_spawned.connect(func(_e): n[0] += 1)
	b.start_battle()
	run(b, 10.0)
	return check(n[0] == 2, "첫 웨이브에 적이 %d명 나왔다(2명이어야 한다)" % n[0])

# EV254 · S144: 시험 스테이지의 라운드 체력 배율은 [1, 1.6, 1.37, 3.82, 5.41, 7.69]이다(라운드 웨이브 파일의 hp_mult)
func ev254():
	var m: Array = load("res://src/main.gd").stage().get("hp_mult", [])
	var want := [1.0, 1.6, 1.37, 3.82, 5.41, 7.69]
	var same: bool = m.size() == want.size() and range(want.size()).all(func(i): return is_equal_approx(m[i], want[i]))
	return check(same, "시험 스테이지 체력 배율이 %s다(%s여야 한다)" % [m, want])
