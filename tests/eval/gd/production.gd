extends "res://tests/eval/gd/lib.gd"
# WBS 2.15 생산 시설·집결 지점·전투 중 구매·배치 상한(S19~S21·S25·S43·S48·S81·S82·I22·I23). lib.gd 머리의 계약에 더하는 API:
#   stage 키 village: Rect2i — 마을 칸. 생산 시설은 이 안에만, 타워·방벽은 이 밖에만 짓는다. 없으면 모든 칸이 들판이다
#   stage 키 merc_cap: int — 배치 상한(살아 있는 용병 수, 공병 포함)
#   구조물 kind "barracks" — 용병("soldier") 생산 시설. rally: Vector2i — 집결 지점
#   Battle.recruit(시설) -> 용병|null — 전투 단계에만, 그 시설에서 용병 하나를 산다
#   Battle.set_rally(시설, cell) — 집결 지점을 바꾼다
#   Controls.facility — 고른 생산 시설(구매 팝업 대상). 없으면 null

const F := Vector2i(10, 3)    # 마을 안 생산 시설 칸
const R1 := Vector2i(15, 9)   # 들판의 집결 지점
const R2 := Vector2i(5, 9)

# 마을은 위쪽 0~5행. 웨이브는 길게 두고 나오는 적은 바로 처치해, 전투 단계가 이어지는 동안 용병이 적에게 끌려가지 않게 한다
func _battle(over := {}):
	var stage := {"village": Rect2i(0, 0, 30, 6), "base_hp": BIG, "waves": [[{"kind": "basic", "count": 1000}]]}
	stage.merge(over, true)
	return battle(stage)

func _calm(b, secs: float, cond: Callable) -> bool:
	return run(b, secs, func():
		kill_all(b)
		return cond.call())

# EV40 · S19: 전투 단계에 생산 시설에서 용병을 사면 골드가 가격만큼 준다
func ev40():
	var b = _battle()
	var f = b.build("barracks", F)
	if f == null:
		return "마을 칸에 생산 시설을 짓지 못했다"
	b.start_battle()
	var before: int = b.gold
	var m = b.recruit(f)
	return check(m != null and b.gold == before - b.MERC_KINDS.soldier.cost, "구매 결과 %s, 골드 %d → %d" % [m, before, b.gold])

# EV41 · S20: 전투 중에 산 용병은 시설 옆 칸에서 나타나 집결 지점에 도착한다
func ev41():
	var b = _battle()
	var f = b.build("barracks", F)
	b.set_rally(f, R1)
	b.start_battle()
	var m = b.recruit(f)
	if m == null or cell_of(m) not in ring(F):
		return "시설 옆 칸에서 나타나지 않았다(%s)" % [m.pos if m else null]
	return check(_calm(b, 30.0, func(): return near(m.pos, R1)), "집결 지점 %s에 닿지 않았다(위치 %s)" % [R1, m.pos])

# EV42 · S21: 전투 중에 집결 지점을 바꾼 뒤 산 용병은 새 집결 지점에 도착한다
func ev42():
	var b = _battle()
	var f = b.build("barracks", F)
	b.start_battle()
	b.set_rally(f, R2)
	var m = b.recruit(f)
	if m == null:
		return "사지 못했다"
	return check(_calm(b, 30.0, func(): return near(m.pos, R2)), "새 집결 지점 %s에 닿지 않았다(위치 %s)" % [R2, m.pos])

# EV47 · S25: 상한 3에 용병 3명이 살아 있으면 준비 단계 놓기도, 전투 중 구매도 거부된다
func ev47():
	var b = _battle({"merc_cap": 3})
	for x in [10, 12, 14]:
		if b.place_merc("soldier", Vector2i(x, 12)) == null:
			return "상한 안의 용병을 놓지 못했다"
	var f = b.build("barracks", F)
	var before: int = b.gold
	var placed = b.place_merc("soldier", Vector2i(16, 12))
	if placed != null or b.gold != before:
		return "준비 단계에 상한을 넘겨 놓였다(골드 %d → %d)" % [before, b.gold]
	b.start_battle()
	before = b.gold
	var bought = b.recruit(f)
	return check(bought == null and b.gold == before, "전투 중에 상한을 넘겨 샀다(골드 %d → %d)" % [before, b.gold])

# EV50 · I23: 시설에서 걸어 나오는 중인 용병도 상한에 센다
func ev50():
	var b = _battle({"merc_cap": 2})
	b.place_merc("soldier", Vector2i(10, 12))
	var f = b.build("barracks", F)
	b.set_rally(f, R1)
	b.start_battle()
	var m = b.recruit(f)
	if m == null or near(m.pos, R1):
		return "걸어 나오는 용병이 없다"
	var before: int = b.gold
	var again = b.recruit(f)
	return check(again == null and b.gold == before, "걷는 용병을 세지 않고 또 샀다(골드 %d → %d)" % [before, b.gold])

# EV64 · I22: 집결 지점을 바꾸면 걸어가던 용병은 새 지점으로 가고, 이미 닿은 용병은 남는다
func ev64():
	var b = _battle()
	var f = b.build("barracks", F)
	b.start_battle()
	b.set_rally(f, R1)
	var first = b.recruit(f)
	if first == null or not _calm(b, 30.0, func(): return near(first.pos, R1)):
		return "첫 용병이 집결 지점 %s에 닿지 않았다" % R1
	var second = b.recruit(f)
	b.set_rally(f, R2)
	if second == null or not _calm(b, 30.0, func(): return near(second.pos, R2)):
		return "걸어가던 용병이 새 집결 지점 %s에 닿지 않았다(위치 %s)" % [R2, second.pos if second else null]
	return check(near(first.pos, R1, 1.0), "이미 닿은 용병이 움직였다(위치 %s)" % first.pos)

# EV65 · S43: 생산 시설은 마을에만, 타워는 마을 밖에만 짓는다
func ev65():
	var b = _battle()
	var before: int = b.gold
	var field_facility = b.build("barracks", Vector2i(10, 12))
	var village_tower = b.build("tower", Vector2i(12, 3))
	if field_facility != null or village_tower != null or b.gold != before:
		return "들판 생산 시설 %s, 마을 타워 %s, 골드 %d → %d" % [field_facility, village_tower, before, b.gold]
	return check(b.build("barracks", F) != null, "마을 칸에 생산 시설을 짓지 못했다")

# EV66 · S48: 파괴된 생산 시설에서는 살 수 없다
func ev66():
	var b = _battle()
	var f = b.build("barracks", F)
	b.start_battle()
	b.damage(f, BIG)
	var before: int = b.gold
	var m = b.recruit(f)
	return check(m == null and b.gold == before, "파괴된 시설에서 샀다(골드 %d → %d)" % [before, b.gold])

# EV67 · S81: 전투 단계에 시설 칸을 좌클릭하면 그 시설이 골라지고, 빈 칸을 좌클릭하면 비워진다
func ev67():
	var b = _battle()
	var c = controls(b)
	var f = b.build("barracks", F)
	b.start_battle()
	click(c, MOUSE_BUTTON_LEFT, px(F))
	if c.facility != f:
		return "시설을 클릭해도 골라지지 않았다(%s)" % c.facility
	click(c, MOUSE_BUTTON_LEFT, px(Vector2i(20, 15)))
	return check(c.facility == null, "빈 칸을 클릭해도 시설이 골라져 있다")

# EV68 · S82: 시설을 고른 채 우클릭한 칸이 집결 지점이 된다
func ev68():
	var b = _battle()
	var c = controls(b)
	var f = b.build("barracks", F)
	b.start_battle()
	click(c, MOUSE_BUTTON_LEFT, px(F))
	click(c, MOUSE_BUTTON_RIGHT, px(R2))
	return check(f.rally == R2, "집결 지점이 %s다(기대 %s)" % [f.rally, R2])
