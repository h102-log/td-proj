extends "res://tests/eval/gd/lib.gd"
# WBS 2.23 주민 집과 세금(S43·S101~S104·I46·I49). lib.gd·village.gd 머리의 계약에 더하는 API:
#   구조물 kind "house"(집) · STRUCTURE_KINDS.house.tax — 집 하나가 준비 단계마다 내는 세금
#   Battle.HOUSE_CAP — 마을에 지을 수 있는 집 수
#   BattleView(res://src/ui/battle_view.gd).residents(battle, t: float) -> Array — t초 때 그리는 주민 위치들(칸 단위, Vector2)
#   단축키: 0 집 놓기

const H1 := Vector2i(10, 3)  # 마을 칸
const H2 := Vector2i(14, 3)
const OUT := Vector2i(15, 12)  # 들판 칸

# 마을은 위쪽 0~5행. 웨이브마다 적 1마리이고, 웨이브 1이 끝나면 준비 단계로 돌아온다
func _battle(over := {}):
	var stage := {"village": Rect2i(0, 0, 30, 6), "base_hp": BIG, "waves": [[{"kind": "basic", "count": 1}], [{"kind": "basic", "count": 1}]]}
	stage.merge(over, true)
	return battle(stage)

func _key(c, key: int) -> void:
	var ev := InputEventKey.new()
	ev.keycode = key
	ev.pressed = true
	c.handle(ev)

# 웨이브 하나를 끝내고 준비 단계에서 늘어난 골드. 끝나지 않으면 null
func _wave_income(b):
	var gold0: int = b.gold
	b.start_battle()
	if not clear_wave(b) or b.state != "prep":
		return null
	return b.gold - gold0

# EV119 · S43: 집은 들판에 짓지 못하고 마을에 짓는다
func ev119():
	var b = _battle()
	var gold0: int = b.gold
	if b.build("house", OUT) != null or b.gold != gold0:
		return "들판에 집이 지어졌다(골드 %d → %d)" % [gold0, b.gold]
	var h = b.build("house", H1)
	return check(h != null and h.complete, "마을 칸에 집이 지어지지 않았다(%s)" % [h])

# EV120 · S101: 상한만큼 지은 뒤 한 채 더는 거부된다
func ev120():
	var b = _battle()
	for i in b.HOUSE_CAP:
		if b.build("house", Vector2i(2 + i * 2, 1)) == null:
			return "%d채째 집을 짓지 못했다" % (i + 1)
	var gold0: int = b.gold
	return check(b.build("house", H1) == null and b.gold == gold0, "상한 %d채를 넘어 지어졌다(골드 %d → %d)" % [b.HOUSE_CAP, gold0, b.gold])

# EV121 · I46: 완성된 집 2채면 웨이브가 끝날 때 세금 2채분이 들어온다
func ev121():
	var b = _battle()
	b.build("house", H1)
	b.build("house", H2)
	var got = _wave_income(b)
	var want: int = b.ENEMY_KINDS.basic.reward + 2 * b.STRUCTURE_KINDS.house.tax
	return check(got == want, "늘어난 골드 %s, 기대 %d" % [got, want])

# EV122 · I46: 미완성 집은 세금을 내지 않는다
func ev122():
	var b = _battle()
	b.place_merc("engineer", Vector2i(28, 18))  # 멀리 둬서 웨이브가 끝나기 전에 다 짓지 못한다
	b.start_battle()
	var h = b.build("house", H1)
	if h == null or h.complete:
		return "전투 중에 미완성 집이 놓이지 않았다(%s)" % [h]
	var gold0: int = b.gold
	if not clear_wave(b) or b.state != "prep" or h.complete:
		return "웨이브가 끝나지 않았거나 집이 다 지어졌다(%s, 완성 %s)" % [b.state, h.complete]
	var want: int = gold0 + b.ENEMY_KINDS.basic.reward
	return check(b.gold == want, "골드 %d, 기대 %d" % [b.gold, want])

# EV123 · S102: 파괴된 집은 세금이 끊기고, 깎이기만 한 집은 다 낸다
func ev123():
	var b = _battle()
	var dead = b.build("house", H1)
	var hurt = b.build("house", H2)
	b.start_battle()
	b.damage(dead, BIG)
	b.damage(hurt, hurt.max_hp / 2.0)
	var gold0: int = b.gold
	if not clear_wave(b) or b.state != "prep":
		return "웨이브가 끝나지 않았다(%s)" % b.state
	var want: int = gold0 + b.ENEMY_KINDS.basic.reward + b.STRUCTURE_KINDS.house.tax
	return check(b.gold == want, "골드 %d, 기대 %d" % [b.gold, want])

# EV124 · S103: 전투 중에는 공병이 가서 시간을 들여 짓는다
func ev124():
	var b = _battle({"waves": [[{"kind": "basic", "count": 1000}]]})
	b.place_merc("engineer", Vector2i(10, 7))
	b.start_battle()
	var h = b.build("house", H1)
	if h == null or h.complete:
		return "전투 중에 지은 집이 미완성이 아니다(%s)" % [h]
	var done := run(b, 30.0, func():
		kill_all(b)
		return h.complete)
	return check(done, "공병이 집을 다 짓지 못했다(진행률 %.2f)" % h.progress)

# EV125 · S103: 0 키 뒤 마을 칸을 좌클릭하면 집이 지어진다
func ev125():
	var b = _battle()
	var c = controls(b)
	_key(c, KEY_0)
	click(c, MOUSE_BUTTON_LEFT, px(H1))
	var s = b.structure_at(H1)
	return check(s != null and s.kind == "house", "0 키 뒤 좌클릭한 칸 %s(놓기 모드 %s)" % [s, c.placing])

# 마을 안 (5,4)의 적이 인식 범위(3칸) 안 (5,1)의 kind를 치나. 거점은 오른쪽 아래 들판이라 길이 그 칸을 지나지 않는다
func _hits_in_village(kind: String) -> String:
	var b = _battle()
	var s = b.build(kind, Vector2i(5, 1))
	b.spawn_enemy("basic", Vector2i(5, 4), {"hp": BIG})
	if not run(b, 10.0, func(): return s.hp < s.max_hp):
		return "마을 안 적이 인식 범위 안의 %s을 치지 않았다" % kind
	return check(b.base.hp == b.base.max_hp, "거점 체력이 깎였다")

# EV126 · I49: 마을 안 적은 인식 범위 안의 집을 친다
func ev126():
	return _hits_in_village("house")

# EV127 · I49: 마을 안 적은 인식 범위 안의 생산 시설을 친다
func ev127():
	return _hits_in_village("barracks")

# EV128 · I49: 들판의 적은 인식 범위 안의 마을 집을 치지 않는다
func ev128():
	var b = _battle()
	var h = b.build("house", Vector2i(10, 5))  # 마을 맨 아래 줄
	var e = b.spawn_enemy("basic", Vector2i(10, 7), {"hp": BIG})  # 들판, 집에서 2칸
	if not run(b, 60.0, func(): return at_base(b, e)):
		return "적이 거점에 닿지 않았다"
	return check(h.hp == h.max_hp, "들판의 적이 집을 쳤다(체력 %.1f)" % h.hp)

# EV129 · S104: 완성된 집마다 주민 하나, 시간이 지나면 움직이고, 늘 마을 안이다
func ev129():
	var b = _battle()
	b.build("house", H1)
	b.build("house", H2)
	var view = load("res://src/ui/battle_view.gd")
	var a: Array = view.residents(b, 0.0)
	var z: Array = view.residents(b, 3.0)
	if a.size() != 2 or z.size() != 2:
		return "주민 수가 %d·%d다" % [a.size(), z.size()]
	if a == z:
		return "3초 뒤에도 주민이 그 자리다"
	for i in 120:
		for p in view.residents(b, i * 0.5):
			if not b.village.has_point(Vector2i(p.round())):
				return "%.1f초에 주민 %s가 마을 밖이다" % [i * 0.5, p]
	return ""

# EV462 · S43: 시험 스테이지의 길 칸(광장·큰길 가운데 줄·남쪽 큰길·정문 안 공터·북문·서문 안 공터)에는 집을 짓지 못하고, 고리 길·큰길 가장자리에는 짓는다
func ev462():
	var b = battle(load("res://src/main.gd").stage())
	b.gold = BIG
	for at in [Vector2i(26, 29), Vector2i(29, 15), Vector2i(10, 31), Vector2i(30, 45), Vector2i(27, 55), Vector2i(28, 4), Vector2i(4, 30)]:
		if b.build("house", at) != null or b.gold != BIG:
			return "길 칸에 걸친 %s에 집이 지어졌다(골드 %d → %d)" % [at, BIG, b.gold]
	for at in [Vector2i(22, 21), Vector2i(31, 15)]:
		if b.build("house", at) == null:
			return "길 칸이 아닌 %s에 집이 지어지지 않았다" % [at]
	return ""
