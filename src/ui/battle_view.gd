extends Node2D
# 전투 상태를 칸 단위 도형으로 그린다(그레이박스, 아트는 WBS 4.1).

const CELL := 16
const COLORS := {
	"field": Color("4a6b3a"), "grid": Color(0, 0, 0, 0.15), "spawn": Color("c03030"),
	"base": Color("e0c040"), "castle_wall": Color("8a8a8a"), "gate": Color("7a5230"), "gate_open": Color("c8a070"),
	"wall": Color("5a5a5a"), "tower": Color("3060b0"), "magic": Color("7030a0"), "merc": Color("50a0f0"),
	"village": Color("6b6b4a"), "barracks": Color("a06a30"),
	"workshop": Color("308080"), "engineer": Color("f0a030"), "archer": Color("60d0a0"), "cannon": Color("303060"), "archery": Color("40a070"),
	"house": Color("b08060"), "resident": Color("f0e0b0"), "church": Color("c8c8e8"),
}
const ENEMY_COLORS := {  # 적 종류마다 다른 색(I81)
	"basic": Color("d04040"), "fast": Color("f08030"), "armored": Color("807070"), "flying": Color("e050c0"), "boss": Color("801010"),
}
const HERO_COLORS := {  # 영웅 종류마다 다른 색(S56, I101)
	"knight": Color("b060f0"), "bowman": Color("a0ff40"), "mason": Color("c08040"), "priest": Color("f0f0f0"), "general": Color("ffd020"), "mage": Color("2040ff"),
}
const MARKS := {  # W가 걸린 대상의 테두리 색(I101). 용병 공격력은 주황(I65)
	"boost": Color.ORANGE, "guard": Color("80c0ff"), "ward": Color("80c0ff"), "expose": Color.MAGENTA, "slow": Color.CYAN, "stun": Color.YELLOW,
}

var battle
var controls  # 고른 유닛에 테두리를 그린다

func _draw() -> void:
	var map := Vector2(battle.size) * CELL
	draw_rect(Rect2(Vector2.ZERO, map), COLORS.field)
	draw_rect(Rect2(Vector2(battle.village.position) * CELL, Vector2(battle.village.size) * CELL), COLORS.village)
	for x in battle.size.x + 1:
		draw_line(Vector2(x * CELL, 0), Vector2(x * CELL, map.y), COLORS.grid)
	for y in battle.size.y + 1:
		draw_line(Vector2(0, y * CELL), Vector2(map.x, y * CELL), COLORS.grid)
	for b in battle.castle.values():  # 열린 성문은 밝게(I67). 단계는 칸 아래쪽 점 개수다(I68)
		draw_rect(_rect(b.cell), COLORS.gate_open if b.open else COLORS[b.kind])
		for i in b.level:
			draw_rect(Rect2(Vector2(b.cell) * CELL + Vector2(2 + i * 4, CELL - 4), Vector2(2, 2)), Color.WHITE)
	for k in battle.rubble.values():  # 잔해는 흐리게(I88)
		draw_rect(_rect(k.cell), Color(COLORS[k.kind], 0.3))
	for s in battle.structures.values():  # 미완성·접은 대포는 흐리게. 진행률은 체력 막대로 보인다(I62, I74)
		var col: Color = COLORS[s.kind]
		draw_rect(_rect(s.cell), col if s.complete and s.razed < 1.0 else Color(col, 0.4))
		if s.dest != null:  # 옮겨 갈 칸(S44)
			draw_rect(_rect(s.dest), col, false, 1.0)
	if controls.placing != "":  # 놓기 모드: 지금 지을(놓을) 수 있는 칸을 엷게(S45, I138)
		for c in battle.placeable_cells(controls.placing):
			draw_rect(_rect(c), Color(1, 1, 1, 0.25))
	for s in battle.structures.values() + battle.castle.values():  # 축성가 W를 받은 칸(I101)
		if s.ward_left > 0.0:
			draw_rect(_rect(s.cell).grow(-1), MARKS.ward, false, 1.0)
	for s in controls.picked + ([controls.fort] if controls.fort else []) + ([battle.base] if controls.village else []):  # 전투 단계에 고른 구조물(S74, S83)·고른 성곽 칸(S85)·고른 거점(S100)
		draw_rect(_rect(s.cell), Color.WHITE, false, 1.0)
	var f = controls.facility  # 고른 생산 시설: 테두리와 집결 지점 깃발(S82)
	if f and f.alive:
		draw_rect(_rect(f.cell), Color.WHITE, false, 1.0)
		draw_line(_center(Vector2(f.cell)), _center(Vector2(f.rally)), Color(1, 1, 1, 0.4), 1.0)
		draw_rect(_rect(f.rally).grow(-5), Color.WHITE)
	for c in battle.spawns:
		draw_rect(_rect(c).grow(-3), COLORS.spawn, false, 2.0)
	for p in battle.forecast:  # 기본 적의 예상 경로(S142): 엷은 빨간 선, 유닛 아래에. 너비 1이면 1배 줌에서 칸 중심을 지나는 가로·세로 구간이 안 그려진다
		draw_polyline(PackedVector2Array(p.map(func(c): return _center(Vector2(c)))), Color(COLORS.spawn, 0.5), 1.5)
	var base = battle.base
	draw_rect(_rect(base.cell), COLORS.base)
	for p in residents(battle, Time.get_ticks_msec() / 1000.0):
		draw_circle(_center(p), CELL * 0.15, COLORS.resident)
	_hp_bar(Vector2(base.cell), base)
	# 구조물·성곽은 깎였을 때만 체력 막대를 그린다(성곽 칸이 많아서). V로 켜면 구조물은 늘 그린다(S73, I59)
	for b in battle.castle.values() + battle.structures.values():
		if b.hp < b.max_hp or (controls.show_hp and b.kind in battle.STRUCTURE_KINDS):
			_hp_bar(Vector2(b.cell), b)
	# 타워 사격 선: 쏜 뒤 0.1초 동안. 대포는 맞은 곳에 범위 피해 원도 그린다(S90)
	for s in battle.structures.values():
		if s.target and s.cooldown > s.fire_gap - 0.1:
			draw_line(Vector2(s.cell) * CELL + Vector2(CELL, CELL) / 2, s.target.pos * CELL + Vector2(CELL, CELL) / 2, Color.YELLOW, 1.0)
			if s.splash > 0.0:
				draw_arc(_center(s.target.pos), CELL * s.splash, 0.0, TAU, 24, Color.YELLOW, 1.0)
	for h in battle.heroes:  # 오라 반경(S113): 오라가 열린(I114) 살아 있는 영웅마다 둘레에 늘 엷게, 유닛 아래에(I101)
		if h.alive and h.aura_radius > 0.0 and h.level >= battle.LEVELS.aura_level:
			draw_arc(_center(h.pos), CELL * h.aura_radius, 0.0, TAU, 48, Color(0.6, 0.8, 1.0, 0.35), 1.0)
	for u in battle.units:
		var at: Vector2 = u.pos * CELL + Vector2(CELL, CELL) / 2
		draw_circle(at, CELL * u.radius, HERO_COLORS.get(u.kind, COLORS.merc) if u.is_hero else COLORS.get(u.kind, COLORS.merc))
		if u.is_hero:  # 영웅 레벨(I117): 오른쪽 위에 작게
			draw_string(ThemeDB.fallback_font, at + Vector2(CELL * 0.3, -CELL * 0.3), str(u.level), HORIZONTAL_ALIGNMENT_LEFT, -1, 8)
		if u in controls.selected:  # 테두리: 흰색 이동 중 공격, 노란색 무조건 이동. 홀드면 기준 반경도 그린다
			draw_arc(at, CELL * (u.radius + 0.2), 0.0, TAU, 24, Color.YELLOW if u.move_mode == "move" else Color.WHITE, 1.0)
			if u.hold:
				draw_arc(u.anchor * CELL + Vector2(CELL, CELL) / 2, CELL * u.hold_radius, 0.0, TAU, 48, Color(1, 1, 1, 0.4), 1.0)
		if u.boost_left > 0.0:  # 버프를 받은 용병(I65): 선택 테두리 바깥에 주황 테두리
			draw_arc(at, CELL * (u.radius + 0.35), 0.0, TAU, 24, MARKS.boost, 1.0)
		if u.guard_left > 0.0:  # 사제 W를 받은 아군(I101)
			draw_arc(at, CELL * (u.radius + 0.5), 0.0, TAU, 24, MARKS.guard, 1.0)
	for e in battle.enemies:  # 비행 적은 아래에 그림자를 그린다(I81)
		if e.flying:
			draw_circle(_center(e.pos) + Vector2(0, CELL * 0.4), CELL * e.radius * 0.8, Color(0, 0, 0, 0.35))
		draw_circle(_center(e.pos), CELL * e.radius, ENEMY_COLORS.get(e.kind, ENEMY_COLORS.basic))
		var ring := 0.15
		for key in ["stun", "slow", "expose"]:  # 기절·느려짐·받는 피해 증가가 걸린 적(I101)
			if e.get(key + "_left") > 0.0:
				draw_arc(_center(e.pos), CELL * (e.radius + ring), 0.0, TAU, 24, MARKS[key], 1.0)
				ring += 0.15
	for h in battle.heroes:  # 쓰러진 영웅: 복귀할 때까지 쓰러진 자리에 그 영웅 색의 X(I130)
		if not h.alive:
			var c := _center(h.pos)
			var r := Vector2(CELL, CELL) * 0.3
			draw_line(c - r, c + r, HERO_COLORS[h.kind], 2.0)
			draw_line(c + Vector2(-r.x, r.y), c + Vector2(r.x, -r.y), HERO_COLORS[h.kind], 2.0)
	# 공격선: 친 뒤 0.1초 동안 아군은 흰색, 적은 빨간색(S71). 대상이 무엇이든 그린다(I59)
	for u in battle.units:
		if u.target and u.cooldown > u.attack_gap - 0.1:
			draw_line(_center(u.pos), _center(_pos_of(u.target)), Color.WHITE, 1.0)
	for e in battle.enemies:
		if e.target and e.cooldown > e.attack_gap - 0.1:
			draw_line(_center(e.pos), _center(_pos_of(e.target)), Color.RED, 1.0)
	# 스킬 범위 원(S72): 영웅마다(I101). 대기는 전투 단계에만 줄어(S136) 전투 단계에만 그린다. ponytail: 0.3초는 임시값, 짧거나 길면 바꾼다
	for h in (battle.heroes if battle.state == "battle" else []):
		if h.alive and h.skill_cooldown > h.skill_gap - 0.3:
			draw_arc(_center(h.pos), CELL * h.skill_radius, 0.0, TAU, 48, Color.WHITE, 1.0)
		if h.alive and h.buff_cooldown > h.buff_gap - 0.3:  # 스킬 2 범위 원(S72, I65)
			draw_arc(_center(h.pos), CELL * h.buff_radius, 0.0, TAU, 48, Color.ORANGE, 1.0)
	if controls.show_hp:
		for u in battle.units + battle.enemies:
			_hp_bar(u.pos, u)
	if controls.drag_rect.has_area():
		draw_rect(controls.drag_rect, Color.WHITE, false, 1.0)

# at: 칸 단위 위치(칸 (x,y)의 중심 = Vector2(x,y)). 그 칸 위쪽에 그린다
func _hp_bar(at: Vector2, b) -> void:
	var bar := Rect2(at * CELL + Vector2(0, -4), Vector2(CELL, 2))
	draw_rect(bar, Color.BLACK)
	draw_rect(Rect2(bar.position, Vector2(CELL * b.hp / b.max_hp, 2)), Color.GREEN)

# t초 때 주민 위치(칸 단위). 완성된 집마다 하나가 집 둘레 1.5칸 안을 떠돌고, 마을 밖으로는 나가지 않는다(S104)
# 연출이라 시뮬레이션에 상태를 두지 않고 시각으로 구한다(I46)
static func residents(b, t: float) -> Array:
	var lo := Vector2(b.village.position)
	var hi := Vector2(b.village.end - Vector2i.ONE)
	var out := []
	for s in b.structures.values():
		if s.tax > 0 and s.complete:
			var k := float(s.cell.x * 7 + s.cell.y * 13)  # 집마다 다른 위상
			out.append((Vector2(s.cell) + Vector2(sin(t * 0.7 + k), sin(t * 0.5 + k * 1.3)) * 1.5).clamp(lo, hi))
	return out

# 유닛·적은 pos, 구조물·성곽·거점은 cell로 자리를 갖는다
func _pos_of(x) -> Vector2:
	var p = x.get("pos")
	return p if p != null else Vector2(x.cell)

func _center(p: Vector2) -> Vector2:
	return p * CELL + Vector2(CELL, CELL) / 2

func _rect(c: Vector2i) -> Rect2:
	return Rect2(Vector2(c) * CELL, Vector2(CELL, CELL))
