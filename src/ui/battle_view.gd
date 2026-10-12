extends Node2D
# 전투 상태를 칸 단위 도형으로 그린다(그레이박스, 아트는 WBS 4.1).

const CELL := 16
const COLORS := {
	"field": Color("4a6b3a"), "grid": Color(0, 0, 0, 0.15), "spawn": Color("c03030"),
	"base": Color("e0c040"), "castle_wall": Color("8a8a8a"), "gate": Color("7a5230"),
	"wall": Color("5a5a5a"), "tower": Color("3060b0"), "enemy": Color("d04040"), "merc": Color("50a0f0"),
	"hero": Color("b060f0"),
}

var battle
var controls  # 고른 유닛에 테두리를 그린다

func _draw() -> void:
	var map := Vector2(battle.size) * CELL
	draw_rect(Rect2(Vector2.ZERO, map), COLORS.field)
	for x in battle.size.x + 1:
		draw_line(Vector2(x * CELL, 0), Vector2(x * CELL, map.y), COLORS.grid)
	for y in battle.size.y + 1:
		draw_line(Vector2(0, y * CELL), Vector2(map.x, y * CELL), COLORS.grid)
	for b in battle.castle.values():
		draw_rect(_rect(b.cell), COLORS[b.kind])
	for s in battle.structures.values():
		draw_rect(_rect(s.cell), COLORS[s.kind])
	for c in battle.spawns:
		draw_rect(_rect(c).grow(-3), COLORS.spawn, false, 2.0)
	var base = battle.base
	draw_rect(_rect(base.cell), COLORS.base)
	_hp_bar(base)
	# 구조물·성곽은 깎였을 때만 체력 막대를 그린다(성곽 칸이 많아서)
	for b in battle.castle.values() + battle.structures.values():
		if b.hp < b.max_hp:
			_hp_bar(b)
	# 타워 사격 선: 쏜 뒤 0.1초 동안
	for s in battle.structures.values():
		if s.target and s.cooldown > s.fire_gap - 0.1:
			draw_line(Vector2(s.cell) * CELL + Vector2(CELL, CELL) / 2, s.target.pos * CELL + Vector2(CELL, CELL) / 2, Color.YELLOW, 1.0)
	for u in battle.units:
		var at: Vector2 = u.pos * CELL + Vector2(CELL, CELL) / 2
		draw_circle(at, CELL * u.radius, COLORS.hero if u == battle.hero else COLORS.merc)
		if u in controls.selected:  # 테두리: 흰색 이동 중 공격, 노란색 무조건 이동. 홀드면 기준 반경도 그린다
			draw_arc(at, CELL * (u.radius + 0.2), 0.0, TAU, 24, Color.YELLOW if u.move_mode == "move" else Color.WHITE, 1.0)
			if u.hold:
				draw_arc(u.anchor * CELL + Vector2(CELL, CELL) / 2, CELL * u.hold_radius, 0.0, TAU, 48, Color(1, 1, 1, 0.4), 1.0)
	for e in battle.enemies:
		draw_circle(e.pos * CELL + Vector2(CELL, CELL) / 2, CELL * e.radius, COLORS.enemy)
	if controls.drag_rect.has_area():
		draw_rect(controls.drag_rect, Color.WHITE, false, 1.0)

func _hp_bar(b) -> void:
	var bar := Rect2(Vector2(b.cell) * CELL + Vector2(0, -4), Vector2(CELL, 2))
	draw_rect(bar, Color.BLACK)
	draw_rect(Rect2(bar.position, Vector2(CELL * b.hp / b.max_hp, 2)), Color.GREEN)

func _rect(c: Vector2i) -> Rect2:
	return Rect2(Vector2(c) * CELL, Vector2(CELL, CELL))
