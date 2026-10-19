extends "res://src/ui/battle_view.gd"
# 4.1a 스파이크 기준선: 그레이박스(battle_view 그대로)에 시간만 잰다. body_us는 성곽 칸 + 유닛·적 몸통이다(①·②와 같은 범위)

var t := 0.0
var draw_us := 0
var body_us := 0

func _draw() -> void:
	var t0 := Time.get_ticks_usec()
	super()
	draw_us = Time.get_ticks_usec() - t0

func _castle() -> void:
	var t0 := Time.get_ticks_usec()
	super()
	body_us = Time.get_ticks_usec() - t0

func _bodies() -> void:
	var t0 := Time.get_ticks_usec()
	super()
	body_us += Time.get_ticks_usec() - t0
