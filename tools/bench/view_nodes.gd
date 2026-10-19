extends "res://tools/bench/view_draw.gd"
# 4.1a 스파이크 ②(art_direction_research/05 §1): y 정렬 부모 아래 Sprite2D를 유닛·적·성벽 칸마다 두고 매 프레임 상태를 옮긴다.
# 층은 z_index, 바닥선은 노드 원점 y, 높이는 offset이다(05 §2). 그릴 것은 ①과 같은 _items()에서 받는다.
# 오버레이(체력 막대·테두리)는 부모 _draw라 이 노드들 밑에 깔린다. 측정용이라 그대로 둔다

var sync_us := 0
var _layer := Node2D.new()
var _nodes := {}  # 노드 이름 → Sprite2D

func _ready() -> void:
	super()
	_layer.y_sort_enabled = true
	add_child(_layer)

func _bodies() -> void:
	pass  # 노드가 그린다

func sync() -> void:
	var t0 := Time.get_ticks_usec()
	var next := {}
	for it in _items():
		var s: Sprite2D = _nodes.get(it[4])
		if s == null:
			s = Sprite2D.new()
			s.centered = false  # 05 §3 주의점
			s.region_enabled = true
			_layer.add_child(s)
		s.texture = it[1]
		s.region_rect = it[2]
		s.z_index = it[5] - 1
		s.position = Vector2(it[3].x, it[6])
		s.offset = Vector2(0, it[3].y - it[6])
		next[it[4]] = s
	for k in _nodes:
		if not next.has(k):
			_nodes[k].queue_free()
	_nodes = next
	sync_us = Time.get_ticks_usec() - t0
