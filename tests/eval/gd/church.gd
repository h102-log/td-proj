extends "res://tests/eval/gd/lib.gd"
# WBS 3.4 1차 관찰 교회(S137·I140). lib.gd 머리의 계약에 더하는 API:
#   stage 키 village: Rect2i — 마을 칸(S43) · 구조물 kind "church"(교회, data/structures/church.tres)
#   Battle.STRUCTURE_KINDS.church.heal — 체력 1당 치료비(골드)
#   Battle.heal(영웅) — 준비 단계에 교회가 있으면 치료비를 내고 그 영웅의 체력을 가득 채운다. 아니면 아무 일도 없다
# 단가는 데이터에서 읽는다. 임시값이라(S137) 밸런스를 바꿔도 동작을 재는 평가는 깨지지 않게. EV242만 표를 대조한다

const CHURCH := Vector2i(5, 3)  # 마을 칸
const ONE := [{"kind": "basic", "count": 1}]  # 적 하나짜리 웨이브

# 마을(0~8행)이 있고 기사 하나를 낸 판
func _town():
	return battle({"village": Rect2i(0, 0, 30, 9), "hero_start": Vector2i(10, 12), "base_hp": BIG, "waves": [ONE]})

# 잃은 체력 lost의 치료비. 1골드 미만은 올린다(I140)
func _cost(b, lost: float) -> int:
	return ceili(lost * b.STRUCTURE_KINDS.church.heal - 0.0001)

# EV240 · S137: 교회가 있는 준비 단계에서만 치료한다. 치료하면 체력이 가득 차고 잃은 체력 × 단가만큼 골드가 준다
func ev240():
	var none = _town()
	none.damage(none.hero, 33)
	var hp0: float = none.hero.hp
	none.heal(none.hero)
	var refused: bool = none.hero.hp == hp0 and none.gold == BIG
	var b = _town()
	if b.build("church", CHURCH) == null:
		return "교회를 짓지 못했다"
	var k = b.hero
	b.damage(k, 33)
	var g: int = b.gold
	b.heal(k)
	var paid: int = g - b.gold
	var healed: bool = k.hp == k.max_hp and paid == _cost(b, 33)
	b.damage(k, 33)
	b.start_battle()
	g = b.gold
	b.heal(k)
	var fight: bool = b.state == "battle" and k.hp == k.max_hp - 33 and b.gold == g
	return check(refused and healed and fight,
		"교회 없음 거부 %s · 준비 단계 치료 %s(체력 %s/%s, 낸 골드 %d, %d여야 한다) · 전투 단계 거부 %s" % [refused, healed, k.hp, k.max_hp, paid, _cost(b, 33), fight])

# EV241 · I140: 1골드 미만은 올리고, 골드가 모자라거나 쓰러진 영웅이면 거부한다
func ev241():
	var b = _town()
	if b.build("church", CHURCH) == null:
		return "교회를 짓지 못했다"
	var k = b.hero
	b.damage(k, 1)
	var g: int = b.gold
	b.heal(k)
	var paid: int = g - b.gold
	var one: bool = k.hp == k.max_hp and paid == _cost(b, 1) and paid >= 1
	b.damage(k, 33)
	var hp: float = k.hp
	b.gold = _cost(b, 33) - 1
	b.heal(k)
	var poor: bool = k.hp == hp and b.gold == _cost(b, 33) - 1
	b.gold = BIG
	b.damage(k, BIG)
	b.heal(k)
	var down: bool = not k.alive and b.gold == BIG
	return check(one and poor and down,
		"1 깎인 치료비 %d골드(%d여야 한다) · 골드 모자라면 거부 %s · 쓰러진 영웅 거부 %s(생존 %s, 골드 %d)" % [paid, _cost(b, 1), poor, down, k.alive, b.gold])

# EV242 · S137: 교회 수치가 S137과 같고, 마을 칸에만 지어진다
func ev242():
	var c: Dictionary = battle().STRUCTURE_KINDS.get("church", {})
	var keys := ["cost", "hp", "build_time", "heal", "village_level"]
	var want := [40, 150.0, 6.0, 0.5, 1]
	var same := not c.is_empty()
	for i in keys.size():
		same = same and c.get(keys[i]) != null and is_equal_approx(float(c.get(keys[i])), float(want[i]))
	var b = _town()
	var field = b.build("church", Vector2i(10, 15))
	var town = b.build("church", CHURCH)
	return check(same and field == null and town != null,
		"교회 수치 %s(%s여야 한다) · 들판 칸 거부 %s · 마을 칸 지음 %s" % [keys.map(func(x): return c.get(x)), want, field == null, town != null])
