extends RefCounted
# 전투 시뮬레이션. 화면 없이 돈다(그리기는 src/ui/). API 계약은 tests/eval/gd/lib.gd 머리 주석에 있다.

# 칸 하나를 차지하고 체력이 있는 맵 요소: 거점 "base" · 성곽 성벽 "castle_wall" · 닫힌 성문 "gate"
class Block:
	var cell: Vector2i
	var kind: String
	var max_hp: float
	var hp: float
	var alive := true

	func _init(c: Vector2i, k: String, h: float) -> void:
		cell = c
		kind = k
		max_hp = h
		hp = h

var size: Vector2i
var spawns: Array
var base: Block
var castle := {}  # Vector2i → Block
var state := "prep"

func _init(stage: Dictionary) -> void:
	size = stage.size
	spawns = stage.spawns
	for c in spawns:
		assert(c.x == 0 or c.y == 0 or c.x == size.x - 1 or c.y == size.y - 1, "출현 지점 %s가 맵 가장자리가 아니다" % c)
	base = Block.new(stage.base, "base", stage.base_hp)
	var fort: Dictionary = stage.get("castle", {})
	for c in fort.get("walls", []):
		castle[c] = Block.new(c, "castle_wall", fort.wall_hp)
	for c in fort.get("gates", []):
		castle[c] = Block.new(c, "gate", fort.gate_hp)

func damage(target, amount: float) -> void:
	if not target.alive:
		return
	target.hp = maxf(target.hp - amount, 0.0)
	if target.hp == 0.0:
		target.alive = false
		if target == base:
			state = "lost"
