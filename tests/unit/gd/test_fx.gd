extends RefCounted
# 영웅 이펙트 C 묶음 fx-1(WBS 4.1s)의 그리기 규칙을 본다.
# 지키는 요구:
#   S179 2026-10-27 변경. 이펙트는 아트 px 격자에 그리고 F24+와 확장 램프 색만 쓴다. 장판은 펼쳐지고 줄어들며, 판정 경계는 밝은 1px + 어두운 1px이고
#         같은 종류 장판끼리 겹친 곳은 바깥 테두리만 남는다. 화염구 작렬·운석 착탄은 밝은 섬광부터 시작하고 연기는 몸통 아래 층이다.
#   I101 2026-10-27 변경. 걸린 효과는 테두리를 쌓지 않고 효과마다 조각 하나다: 기절은 머리 위 별, 둔화는 발밑 서리, 도발·봉인은 머리 위 기호 등.

const View := preload("res://src/ui/battle_view.gd")
const Battle := preload("res://src/sim/battle.gd")

# 조각·도형을 그리지 않고 조각 이름만 모으는 화면
class Rec extends "res://src/ui/battle_view.gd":
	var spr := []
	func _spr(name: String, frame: int, at: Vector2i, bottom := false) -> void:
		spr.append([name, frame])
	func _pring(c: Vector2i, r: int, th: int, col: Color, dash := 0) -> void:
		spr.append(["ring", th])
	func _pline(a: Vector2i, b: Vector2i, col: Color, w := 1) -> void:
		pass
	func _pdisc(c: Vector2i, r: int, col: Color) -> void:
		pass
	func _pnoise(c: Vector2i, r: int, col: Color, lim: int, salt := 0) -> void:
		pass

func _battle():
	var b = Battle.new({"size": Vector2i(20, 20), "base": Vector2i(18, 18), "base_hp": 100, "spawns": [Vector2i(0, 10)], "hero_start": Vector2i(5, 5), "waves": [[{"kind": "basic", "count": 1}]]})
	b.start_battle()
	return b

func test_fx_atlas_uses_palette_and_fx_ramp_with_hard_alpha():
	var pal: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/art/palettes.json"))
	var ok := {}
	for h in pal.f24p + pal.fx:
		ok[h] = true
	var img: Image = load("res://art/fx/fx.png").get_image()
	img.decompress()
	var seen := 0
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a8 == 0:
				continue
			seen += 1
			if c.a8 != 255:
				return "(%d,%d) 알파가 %d다(0이나 255여야 한다)" % [x, y, c.a8]
			if not ok.has(c.to_html(false)):
				return "(%d,%d) 색 %s가 팔레트 밖이다" % [x, y, c.to_html(false)]
	return "" if seen > 1000 else "칠한 칸이 %d개뿐이다(아틀라스를 못 읽었다)" % seen

func test_px_ring_cells_sit_on_radius_and_are_symmetric():
	for r in [3, 10, 24]:
		for th in [1, 3]:
			var cells: Array = View.px_cells(r, th)
			if cells.is_empty():
				return "반지름 %d 굵기 %d 고리가 비었다" % [r, th]
			var set := {}
			for o in cells:
				var d := Vector2(o.x + 0.5, o.y + 0.5).length()
				if d > r + 0.5 or d <= r + 0.5 - th:
					return "반지름 %d 굵기 %d 고리 칸 %s가 거리 %.2f다" % [r, th, o, d]
				set[o] = true
			for o in cells:  # 가운데가 칸 모서리라 x → -1 - x, y → -1 - y로 대칭이다
				if not set.has(Vector2i(-1 - o.x, o.y)) or not set.has(Vector2i(o.x, -1 - o.y)) or not set.has(Vector2i(o.y, o.x)):
					return "반지름 %d 굵기 %d 고리가 대칭이 아니다(%s)" % [r, th, o]
	return ""

func test_edge_keeps_only_outer_border_of_overlapping_same_zones():
	var c := Vector2i(100, 100)
	var alone: Array = View.edge_cells(c, 24, [])
	var other := [Vector2(c) + Vector2(16, 0), 24.0]
	var both: Array = View.edge_cells(c, 24, [other])
	if alone[0].is_empty() or alone[1].is_empty():
		return "테두리가 비었다"
	if both[1].size() >= alone[1].size():
		return "겹친 장판이 있어도 테두리 칸이 %d개 그대로다" % both[1].size()
	for p in both[0] + both[1]:
		if (Vector2(p) + Vector2(0.5, 0.5)).distance_to(other[0]) < other[1] - 0.5:
			return "다른 장판 안쪽 칸 %s를 테두리로 그린다" % p
	return ""

func test_zone_opens_then_shrinks_at_the_end():
	var z := {"radius": 1.5, "left": 4.0}
	var full := int(View.CELL * 1.5)
	if View.zone_r(z, 0.0) != 0 or View.zone_r(z, 0.05) >= full or View.zone_r(z, 0.25) != full:
		return "펼침이 %d → %d → %d다(0 → 반지름 미만 → %d여야 한다)" % [View.zone_r(z, 0.0), View.zone_r(z, 0.05), View.zone_r(z, 0.25), full]
	z.left = 0.15
	if View.zone_r(z, 1.0) >= full or View.zone_r(z, 1.0) <= 0:
		return "남은 0.15초에 반지름이 %d다(줄어들어야 한다)" % View.zone_r(z, 1.0)
	return ""

func test_foe_effects_are_one_mark_each_not_stacked_rings():
	var b = _battle()
	var v = View.new()
	v.battle = b
	var e = b.spawn_enemy("basic", Vector2i(10, 10), {"speed": 0})
	b._fx(e, "ignis_w_freeze", {"stun": true}, 2.0)
	b._fx(e, "ignis_w", {"slow": 0.4}, 2.0)
	b._fx(e, "ignis_q", {"dot": 3.0}, 2.0)
	b._fx(e, "aias_w", {"taunt": b.heroes[0] if not b.heroes.is_empty() else true}, 2.0)
	b._fx(e, "vesper_x", {"seal": true}, 2.0)
	var feet: Vector2i = Vector2i((v._spot(e) + v._slip(e)).floor())
	var marks: Array = v.status_marks(e, false)
	var why := ""
	var kinds := marks.map(func(m): return m.k)
	if kinds.has("ring"):
		why = "적 효과를 고리로 그린다: %s" % [kinds]
	var stars := marks.filter(func(m): return m.k == "star")
	if why == "" and (stars.size() != 2 or stars.any(func(m): return m.p.y > feet.y - 10)):
		why = "기절 별이 %s다(머리 위에 둘이어야 한다, 발밑 y %d)" % [stars.map(func(m): return m.p), feet.y]
	var frost := marks.filter(func(m): return m.k == "frost")
	if why == "" and (frost.size() != 1 or absi(frost[0].p.y - feet.y) > 3):
		why = "둔화 서리가 %s다(발밑에 하나여야 한다)" % [frost.map(func(m): return m.p)]
	if why == "" and (not kinds.has("flame_s") or marks.filter(func(m): return m.k == "px").size() < 4):
		why = "발화가 작은 불꽃 + 불티 넷이 아니다: %s" % [kinds]
	var icons := marks.filter(func(m): return m.k in ["taunt", "seal"])
	if why == "" and (icons.size() != 2 or icons.any(func(m): return m.p.y >= stars.map(func(s): return s.p.y).min())):
		why = "도발·봉인 기호가 %s다(별보다 위에 둘이어야 한다)" % [icons.map(func(m): return [m.k, m.p])]
	v.free()
	return why

func test_ally_effects_use_halo_only_for_shield_and_invuln():
	var b = _battle()
	var v = View.new()
	v.battle = b
	var h = b.heroes[0] if not b.heroes.is_empty() else b.units[0]
	h.shields["test"] = {"hp": 10.0, "left": 2.0}
	b._fx(h, "aias_e", {"dr": 0.3}, 2.0)
	b._fx(h, "chronos_q", {"haste": 0.3}, 2.0)
	var marks: Array = v.status_marks(h, true)
	var why := ""
	var kinds := marks.map(func(m): return m.k)
	if kinds.count("ring") != 1 or kinds.count("guard") != 2 or kinds.count("px") != 3:
		why = "보호막 테 1·방패 2·오르는 점 3이 아니다: %s" % [kinds]
	b._fx(h, "seraphina_e_saved", {"invuln": true}, 2.0)
	kinds = v.status_marks(h, true).map(func(m): return m.k)
	if why == "" and (kinds.count("ring") != 2 or not kinds.has("star")):
		why = "불사에 금 테와 별이 없다: %s" % [kinds]
	v.free()
	return why

func test_boom_bright_first_frame_above_and_smoke_below_bodies():
	var img: Image = load("res://art/fx/fx.png").get_image()
	img.decompress()
	var m: Array = View.FX_ART.boom
	var mid := img.get_pixel(m[0] + m[2] / 2, m[1] + m[3] / 2)
	if mid.to_html(false) != "efd8a1":
		return "폭발 첫 프레임 가운데가 %s다(밝은 크림 efd8a1이어야 한다, Gemini 고칠 점 1)" % mid.to_html(false)
	var v = Rec.new()
	v._boom(Vector2i(50, 50), 24.0, 0.0, 7, false, true)
	var top: Array = v.spr.map(func(s): return s[0])
	if not top.has("boom") or v.spr.filter(func(s): return s[0] == "boom")[0][1] != 0 or top.count("ring") != 1 or top.has("puff"):
		var why := "쓴 순간 위 층이 %s다(폭발 0프레임과 고리 하나, 연기 없음이어야 한다)" % [v.spr]
		v.free()
		return why
	v.spr.clear()
	v._boom(Vector2i(50, 50), 24.0, 0.4, 7, false, false)
	var low: Array = v.spr.map(func(s): return s[0])
	v.free()
	if low.is_empty() or low.any(func(s): return s != "puff"):
		return "0.4초 아래 층이 %s다(연기 조각만이어야 한다)" % [low]
	return ""

func test_ally_bleed_is_falling_drops_not_a_ring():
	var b = _battle()
	var v = View.new()
	v.battle = b
	var h = b.heroes[0] if not b.heroes.is_empty() else b.units[0]
	b._fx(h, "bleed", {"bleed": 2.0}, 3.0)
	var marks: Array = v.status_marks(h, true)
	var feet: Vector2i = Vector2i((v._spot(h) + v._slip(h)).floor())
	var why := ""
	if marks.size() != 3 or marks.any(func(m): return m.k != "px" or m.p.y >= feet.y):
		why = "출혈(I193 ③)이 %s다(몸에서 떨어지는 점 셋이어야 한다)" % [marks.map(func(m): return [m.k, m.p])]
	v.free()
	return why
