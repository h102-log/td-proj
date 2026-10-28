extends RefCounted
# 영웅 이펙트 C 묶음 fx-1·fx-2·fx-3(WBS 4.1s)의 그리기 규칙을 본다.
# 지키는 요구:
#   S179 2026-10-27 변경. 이펙트는 아트 px 격자에 그리고 F24+와 확장 램프 색만 쓴다. 장판은 펼쳐지고 줄어들며, 판정 경계는 밝은 1px + 어두운 1px이고
#         같은 종류 장판끼리 겹친 곳은 바깥 테두리만 남는다. 화염구 작렬·운석 착탄은 밝은 섬광부터 시작하고 연기는 몸통 아래 층이다.
#   I101 2026-10-27 변경. 걸린 효과는 테두리를 쌓지 않고 효과마다 조각 하나다: 기절은 머리 위 별, 둔화는 발밑 서리, 도발·봉인은 머리 위 기호 등.
#   S179·S168·I101 2026-10-28 변경(fx-2). 아이아스·실비아: 방패 강타는 굵은 베기 띠 + 맞은 섬광, 포효는 충격파 둘(먼지는 아래 층), 태세는 방패 조각,
#         터뜨림은 밝은 섬광부터, 바람살은 맵 끝까지 뻗는 굵은 줄, 덫 터짐은 고리 하나 + 바람 호 셋, 화살비는 떨어지는 화살(위 층)·꽂힌 화살(아래 층),
#         절대 방어선 둘레는 칸 원을 합친 모양의 두 겹 테두리, 에너지 성벽 칸은 이어진 벽, 켜진 갈래살은 실비아 발밑 바람 줄이다.
#   S179·S168 2026-10-28 변경(fx-3). 세라피나(크림·금)·베스퍼(청록): 빛줄기는 맞은 차례대로 한 마디씩 뻗고, 수호 천사는 등 뒤 날개(아래 층),
#         기적은 아군마다 내려오는 빛기둥, 쇠약은 조여드는 고리와 머리 위 저주 문양, 영혼 사슬은 거는 줄과 청록 고리 도트다.
#         성역·독안개·늪은 무늬 대신 재질(성휘·빛 점 / 안개·거품 / 진흙·물결)이고, 늪은 보라를 쓰지 않는다. 색은 팔레트 안이다.
#   S179·S168 2026-10-28 변경(fx-4). 크로노스(금·크림, 왜곡장은 얼음): 과충전은 금 줄·고리 하나·불티 넷, 되감기는 크림 줄·조여드는 고리·머리 위 시계,
#         황금률은 청동 칠·도는 톱니 고리·동전 점, 왜곡장은 얼음 칠·반대로 도는 점선 고리 둘·시곗바늘 둘이다(햇살·무늬 없음).
#         보스 예고·채움, 대포알 고리, 조준 미리보기, 명령 표식, 홀드 반경도 아트 px라 맵에 화면 px 원(draw_arc)이 남지 않는다.

const View := preload("res://src/ui/battle_view.gd")
const Battle := preload("res://src/sim/battle.gd")

# 조각·도형을 그리지 않고 조각 이름만 모으는 화면. 선·호·칸은 따로 모은다
class Rec extends "res://src/ui/battle_view.gd":
	var spr := []
	var lines := []  # [a, b, 색, 굵기]
	var arcs := []  # [반지름, 굵기, a0, a1, 색]
	var rings := []  # [가운데, 반지름, 굵기, 색, 끊김, 돈 각]
	var pxs := []  # [자리, 색, 크기]
	var fills := []  # 성긴 칠 색
	var edges := []  # 판정 경계 [밝은 색, 어두운 색]
	func _spr(name: String, frame: int, at: Vector2i, bottom := false) -> void:
		spr.append([name, frame, at])
	func _pring(c: Vector2i, r: int, th: int, col: Color, dash := 0, turn := 0.0) -> void:
		spr.append(["ring", th])
		rings.append([c, r, th, col, dash, turn])
	func _pline(a: Vector2i, b: Vector2i, col: Color, w := 1) -> void:
		lines.append([a, b, col, w])
	func _parc(c: Vector2i, r: int, th: int, a0: float, a1: float, col: Color) -> void:
		arcs.append([r, th, a0, a1, col])
	func _pdisc(c: Vector2i, r: int, col: Color) -> void:
		pass
	func _pnoise(c: Vector2i, r: int, col: Color, lim: int, salt := 0) -> void:
		fills.append(col)
	func _px(p: Vector2i, col: Color, size := Vector2i.ONE) -> void:
		pxs.append([p, col, size])
	func _edge(c: Vector2i, r: int, light: Color, dark: Color, others := []) -> void:
		edges.append([light, dark])
	func wipe() -> void:
		for a in [spr, lines, arcs, rings, pxs, fills, edges]:
			a.clear()

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

# ── fx-2: 아이아스·실비아 ──

func _pair():
	var b = Battle.new({"size": Vector2i(30, 30), "base": Vector2i(28, 28), "base_hp": 100, "spawns": [Vector2i(0, 20)],
		"heroes": [{"kind": "aias", "cell": Vector2i(10, 10)}, {"kind": "sylvia", "cell": Vector2i(14, 10)}], "waves": [[{"kind": "basic", "count": 1}]]})
	b.start_battle()
	b._queue = []
	return b

func _ready_cast(b, h, slot: String, aim = null) -> bool:
	h.mana = h.max_mana
	for k in h.cd.keys():
		h.cd[k] = 0.0
	return b.cast(h, slot, aim)

func test_fx2_pieces_and_bright_first_burst_frame():
	for name in ["spark", "aegis", "burst", "ward", "trap", "gust", "stuck"]:
		if not View.FX_ART.has(name):
			return "이펙트 아틀라스에 %s 조각이 없다" % name
	var img: Image = load("res://art/fx/fx.png").get_image()
	img.decompress()
	var m: Array = View.FX_ART.burst
	var mid := img.get_pixel(m[0] + m[2] / 2, m[1] + m[3] / 2)
	if mid.to_html(false) != "efd8a1":
		return "터뜨림 첫 프레임 가운데가 %s다(밝은 크림 efd8a1이어야 한다)" % mid.to_html(false)
	return ""

func test_shield_bash_is_thick_band_inside_fan_then_one_thin_arc():
	var v = Rec.new()
	var d := 0.5
	var half := PI / 4.0
	v._bash(Vector2i(100, 100), 32.0, d, half, 0.02, [])
	var why := ""
	var radii: Array = v.arcs.map(func(a): return a[0])
	if v.arcs.size() < 3 or radii.max() - radii.min() != v.arcs.size() - 1 or v.arcs.any(func(a): return absf(a[2] - (d - half)) > 1e-4 or absf(a[3] - (d + half)) > 1e-4):
		why = "쓴 직후 베기가 %s다(부채꼴 안 이어진 띠 셋 이상이어야 한다)" % [v.arcs]
	elif v.arcs.filter(func(a): return a[0] == radii.max())[0][4] != View.PX.cream:
		why = "베기 앞 가장자리가 크림이 아니다"
	v.wipe()
	v._bash(Vector2i(100, 100), 32.0, d, half, View.SWEEP + 0.05, [])
	if why == "" and (v.arcs.size() != 1 or v.arcs[0][0] != 32):
		why = "베기 뒤 %s다(반경 32의 호 하나여야 한다)" % [v.arcs]
	v.wipe()
	v._bash(Vector2i(100, 100), 32.0, d, half, View.FX, [])
	if why == "" and not v.arcs.is_empty():
		why = "FX초 뒤에도 호를 그린다"
	v.free()
	return why

func test_war_cry_two_shock_rings_above_and_dust_below():
	var b = _pair()
	var v = Rec.new()
	v.battle = b
	var h = b.heroes[0]
	v._cry(Vector2i(100, 100), 48.0, View.CRY_ECHO + 0.02, 7, h, true)
	var why := ""
	if v.rings.size() != 2 or v.rings[0][1] <= v.rings[1][1] or v.rings.any(func(r): return r[2] < 1):
		why = "충격파가 %s다(바깥 고리와 늦게 나온 안쪽 고리 둘이어야 한다)" % [v.rings.map(func(r): return [r[1], r[2]])]
	elif v.lines.size() != 3 or v.lines.any(func(l): return l[0].y >= int((v._spot(h)).y - v._head(h))):
		why = "외침 선이 %s다(머리 위 셋이어야 한다)" % [v.lines]
	v.wipe()
	v._cry(Vector2i(100, 100), 48.0, 0.1, 7, h, false)
	if why == "" and (not v.rings.is_empty() or v.pxs.size() != 10):
		why = "아래 층이 고리 %d · 먼지 %d다(고리 없이 먼지 10이어야 한다)" % [v.rings.size(), v.pxs.size()]
	v.free()
	return why

func test_gale_reaches_map_end_fast_with_core_and_sparks_on_hits():
	var b = _pair()
	var v = Rec.new()
	v.battle = b
	var e = b.spawn_enemy("basic", Vector2i(20, 10), {"speed": 0})
	var c := Vector2i(100, 100)
	v._gale(c, Vector2.RIGHT, View.GALE_REACH * 0.3, 7, [e])
	var early: float = v.lines.map(func(l): return Vector2(l[1] - l[0]).length()).max()
	v.wipe()
	v._gale(c, Vector2.RIGHT, View.GALE_REACH + 0.01, 7, [e])
	var body: Array = v.lines.filter(func(l): return l[0] == c)
	var why := ""
	if early >= View.CELL * 60.0:
		why = "쓴 직후 줄이 이미 %.0fpx다(뻗어 나가야 한다)" % early
	elif body.size() != 2 or body.any(func(l): return l[1].x - c.x < View.CELL * 63) or body.map(func(l): return l[3]).max() != 3 or body.map(func(l): return l[3]).min() != 1:
		why = "뻗은 뒤 몸통이 %s다(맵 끝까지 굵기 3 몸통과 1 심이어야 한다)" % [body.map(func(l): return [l[1], l[3]])]
	elif not v.spr.any(func(s): return s[0] == "spark" and s[1] == 1):
		why = "맞은 적에 섬광이 없다: %s" % [v.spr]
	v.free()
	return why

func test_trap_burst_one_ring_and_three_swirls_above_debris_below():
	var v = Rec.new()
	v._whirl(Vector2i(100, 100), 24.0, 0.05, 7, true)
	var why := ""
	if v.rings.size() != 1 or v.arcs.size() != 3:
		why = "덫 터짐 위 층이 고리 %d · 호 %d다(1 · 3이어야 한다)" % [v.rings.size(), v.arcs.size()]
	v.wipe()
	v._whirl(Vector2i(100, 100), 24.0, 0.05, 7, false)
	if why == "" and (not v.rings.is_empty() or not v.arcs.is_empty() or v.pxs.size() != 6):
		why = "덫 터짐 아래 층이 %s다(부스러기 여섯뿐이어야 한다)" % [[v.rings.size(), v.arcs.size(), v.pxs.size()]]
	v.free()
	return why

func test_arrow_rain_falls_above_bodies_and_sticks_below():
	var v = Rec.new()
	var z := {"src": "sylvia_r", "pos": Vector2(10, 10), "radius": 2.5, "left": 4.0}
	v._zone_age(z)
	var fell := 0
	var stuck := 0
	for i in 12:
		v.clock = 0.5 + i * 0.1
		v.wipe()
		v._rain(z, true)
		if v.spr.any(func(s): return s[0] == "stuck"):
			v.free()
			return "%.1f초 위 층에 꽂힌 화살이 있다" % (0.5 + i * 0.1)
		fell += v.lines.size()
		v.wipe()
		v._rain(z, false)
		if not v.lines.is_empty():
			v.free()
			return "%.1f초 아래 층에 떨어지는 화살이 있다" % (0.5 + i * 0.1)
		stuck += v.spr.filter(func(s): return s[0] == "stuck").size()
	v.free()
	if fell == 0 or stuck == 0:
		return "떨어진 화살 %d · 꽂힌 화살 %d다(둘 다 있어야 한다)" % [fell, stuck]
	return ""

func test_bulwark_capsule_is_union_of_cell_circles_with_two_tone_edge():
	var offs := [Vector2i(0, 0), Vector2i(16, 0), Vector2i(32, 0)]
	var m: Array = View.capsule_cells(offs, 32)
	var dist := func(p: Vector2i) -> float:
		var q := Vector2(p) + Vector2(0.5, 0.5)
		return offs.map(func(o): return q.distance_to(Vector2(o))).min()
	if m[2].is_empty() or m[3].is_empty():
		return "테두리가 비었다"
	for p in m[2]:
		var d: float = dist.call(p)
		if d <= 31.5 or d > 32.5:
			return "밝은 테두리 칸 %s가 가장 가까운 칸 가운데에서 %.2f다(반경 32 둘레여야 한다)" % [p, d]
	for p in m[3]:
		var d: float = dist.call(p)
		if d <= 32.5 or d > 33.5:
			return "어두운 테두리 칸 %s가 %.2f다(밝은 테두리 바로 바깥이어야 한다)" % [p, d]
	if not m[2].has(Vector2i(16, -32)) or m[2].has(Vector2i(16, 0)):
		return "가운데 칸 위 둘레가 밝은 테두리에 없거나 안쪽에 테두리가 있다"
	var img: Image = m[0].get_image()
	var lit := 0
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.5:
				lit += 1
	var inside := 3.14159 * 32 * 32 + 64 * 64
	if lit < inside * 0.08 or lit > inside * 0.18:
		return "성긴 칠이 %d칸이다(안쪽의 약 2/16이어야 한다)" % lit
	return ""

func test_energy_wall_cells_join_into_one_wall():
	var row := {Vector2i(4, 5): true, Vector2i(5, 5): true, Vector2i(6, 5): true}
	for q in row:
		if View.ward_edges(row, q) != [true, true, true]:
			return "가로 벽 칸 %s가 %s다(앞면과 두 선을 모두 그려야 한다)" % [q, View.ward_edges(row, q)]
	var col := {Vector2i(5, 4): true, Vector2i(5, 5): true, Vector2i(5, 6): true}
	var got := [View.ward_edges(col, Vector2i(5, 4)), View.ward_edges(col, Vector2i(5, 5)), View.ward_edges(col, Vector2i(5, 6))]
	if got != [[false, true, false], [false, false, false], [true, false, true]]:
		return "세로 벽이 %s다(북쪽 끝만 뒤끝 선, 남쪽 끝만 앞면·앞끝 선이어야 한다)" % [got]
	return ""

func test_aias_sylvia_casts_draw_their_own_pieces():
	var b = _pair()
	var a = b.heroes[0]
	var s = b.heroes[1]
	var e = b.spawn_enemy("basic", Vector2i(10, 12), {"speed": 0, "sight": 0, "damage": 0, "hp": 1e9})
	var v = Rec.new()
	v.battle = b
	var want := [["q", a, Vector2(10, 12), "spark"], ["e", a, null, "aegis"], ["e", a, null, "burst"], ["e", s, Vector2(10, 12), "arc"]]
	for w in want:
		if w[3] == "burst":
			a.braced = 30.0
			b.cast(a, "e")
		elif not _ready_cast(b, w[1], w[0], w[2]):
			v.free()
			return "%s %s를 못 썼다" % [w[1].kind, w[0]]
		b.step(1.0 / 60.0)
		v.wipe()
		v._traces(true)
		var got: Array = v.spr.map(func(x): return x[0]) + (["arc"] if not v.arcs.is_empty() else [])
		if not got.has(w[3]):
			v.free()
			return "%s %s 뒤 그린 것이 %s다(%s가 있어야 한다)" % [w[1].kind, w[0], got, w[3]]
		if w[3] == "aegis":
			var at: Vector2i = v.spr.filter(func(x): return x[0] == "aegis")[0][2]
			if at.y >= int(v._spot(a).y) or at.y <= int(v._spot(a).y - v._head(a)):
				v.free()
				return "태세 방패가 y %d다(발밑 %d과 머리 사이 몸 앞이어야 한다)" % [at.y, int(v._spot(a).y)]
		b.traces.clear()
	v.free()
	return ""

func test_split_shot_on_shows_wind_at_feet_only_while_on():
	var b = _pair()
	var v = Rec.new()
	v.battle = b
	var s = b.heroes[1]
	var feet: Vector2i = Vector2i((v._spot(s) + v._slip(s)).floor())
	var why := ""
	if v.status_marks(s, true).any(func(m): return m.k == "gust"):
		why = "갈래살을 켜지 않았는데 바람 줄이 있다"
	_ready_cast(b, s, "w")
	var g: Array = v.status_marks(s, true).filter(func(m): return m.k == "gust")
	if why == "" and (g.size() != 1 or absi(g[0].p.y - feet.y) > 2):
		why = "켠 갈래살이 %s다(발밑 바람 줄 하나여야 한다)" % [g]
	v.free()
	return why

# ── fx-3: 세라피나(크림·금)·베스퍼(청록) ──

func _duo():
	var b = Battle.new({"size": Vector2i(30, 30), "base": Vector2i(28, 28), "base_hp": 100, "spawns": [Vector2i(0, 20)],
		"heroes": [{"kind": "seraphina", "cell": Vector2i(10, 10)}, {"kind": "vesper", "cell": Vector2i(14, 10)}], "waves": [[{"kind": "basic", "count": 1}]]})
	b.start_battle()
	b._queue = []
	return b

func _target(b, cell: Vector2i):
	return b.spawn_enemy("basic", cell, {"speed": 0, "sight": 0, "damage": 0, "hp": 1e9})

# 기록 화면이 모은 색 전부(줄·호·고리·칸·성긴 칠·경계)
func _colors(v) -> Array:
	var out: Array = v.lines.map(func(l): return l[2]) + v.arcs.map(func(a): return a[4]) + v.rings.map(func(r): return r[3]) + v.pxs.map(func(p): return p[1]) + v.fills
	for e in v.edges:
		out += e
	return out

# 팔레트(f24p + fx) 밖 색이 있으면 그 색, 없으면 ""
func _off_palette(colors: Array) -> String:
	var pal: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/art/palettes.json"))
	for c in colors:
		if not (c.to_html(false) in pal.f24p + pal.fx):
			return c.to_html(false)
	return ""

# 장판 하나를 펼쳐진 뒤(1초)에 그린 기록 화면
func _zone_draw(src: String):
	var b = _duo()
	b.zones = [{"src": src, "owner": b.heroes[0], "pos": Vector2(12, 12), "radius": 2.0, "left": 3.0}]
	var v = Rec.new()
	v.battle = b
	v._zones()  # 처음 본 때를 0초로
	v.clock = 1.0
	v.wipe()
	v._zones()
	return v

func test_fx3_pieces_and_teal_chain_links():
	for name in ["mend", "wing", "glyph", "fog", "fizz", "hex"]:
		if not View.FX_ART.has(name):
			return "이펙트 아틀라스에 %s 조각이 없다" % name
	var img: Image = load("res://art/fx/fx.png").get_image()
	img.decompress()
	var m: Array = View.FX_ART.link
	var c := img.get_pixel(m[0] + 1, m[1])
	if c.to_html(false) != "3c9f9c":
		return "사슬 고리가 %s다(베스퍼 청록 3c9f9c여야 한다)" % c.to_html(false)
	return ""

func test_holy_beam_hops_target_to_target_in_order():
	var b = _duo()
	var s = b.heroes[0]
	var ally = b.heroes[1]
	var e = _target(b, Vector2i(12, 12))
	var hits := [ally, e, s]
	var v = Rec.new()
	v.battle = b
	var to := [Vector2i(v._chest(ally).floor()), Vector2i(v._chest(e).floor()), Vector2i(v._chest(s).floor())]
	v._beam(s, hits, View.BEAM_HOP * 0.5)
	var ends: Array = v.lines.map(func(l): return l[1])
	var why := ""
	if v.lines.is_empty() or ends.has(to[0]) or not v.spr.is_empty():
		why = "첫 마디가 반쯤 뻗었을 때 줄 끝이 %s · 조각 %s다(첫 대상에 아직 닿지 않아야 한다)" % [ends, v.spr]
	elif v.lines.map(func(l): return l[3]).max() != 3:
		why = "쓴 직후 줄이 굵기 3이 아니다"
	v.wipe()
	v._beam(s, hits, View.BEAM_HOP * 2.5)
	ends = v.lines.map(func(l): return l[1])
	var names: Array = v.spr.map(func(x): return x[0])
	if why == "" and (not ends.has(to[0]) or not ends.has(to[1]) or ends.has(to[2])):
		why = "2.5마디 뒤 줄 끝이 %s다(아군 → 적까지 닿고 셋째 대상에는 아직이어야 한다)" % [ends]
	elif why == "" and not v.lines.any(func(l): return l[0] == to[0] and l[1] == to[1]):
		why = "둘째 마디가 첫 대상에서 시작하지 않는다: %s" % [v.lines]
	elif why == "" and (not names.has("mend") or not names.has("spark")):
		why = "닿은 아군 회복 반짝·적 섬광이 없다: %s" % [names]
	v.free()
	return why

func test_guardian_wings_behind_body_and_line_ring_above():
	var b = _duo()
	var s = b.heroes[0]
	var x = b.heroes[1]
	var v = Rec.new()
	v.battle = b
	var feet := Vector2i(v._spot(x).floor())
	v._angel(s, x, 0.1, false)
	var why := ""
	var w: Array = v.spr.filter(func(q): return q[0] == "wing")
	if w.size() != 1 or w[0][1] != 1 or not v.lines.is_empty() or not v.rings.is_empty():
		why = "아래 층이 %s다(날개 조각 1프레임 하나뿐이어야 한다)" % [v.spr]
	elif w[0][2].y >= feet.y or w[0][2].y <= feet.y - int(v._head(x)):
		why = "날개가 y %d다(발밑 %d과 머리 사이 등 뒤여야 한다)" % [w[0][2].y, feet.y]
	v.wipe()
	v._angel(s, x, 0.1, true)
	if why == "" and (v.spr.any(func(q): return q[0] == "wing") or v.lines.size() != 1 or v.rings.size() != 1):
		why = "위 층이 조각 %s · 줄 %d · 고리 %d다(날개 없이 줄 하나·고리 하나여야 한다)" % [v.spr, v.lines.size(), v.rings.size()]
	v.wipe()
	v._angel(s, x, View.FX, true)
	if why == "" and not (v.lines.is_empty() and v.rings.is_empty()):
		why = "FX초 뒤에도 그린다"
	v.free()
	return why

func test_miracle_pillar_falls_on_each_healed_ally_then_ring():
	var b = _duo()
	var hits := [b.heroes[0], b.heroes[1]]
	var v = Rec.new()
	v.battle = b
	v._miracle(hits, View.PILLAR * 0.5)
	var why := ""
	var cols: Array = v.pxs.filter(func(p): return p[2].x > 1)  # 기둥 몸통(크림 심은 폭 1)
	if cols.size() != 2 or cols.any(func(p): return p[2].y <= 0 or p[2].y >= View.PILLAR_H) or not v.rings.is_empty():
		why = "내려오는 중 기둥이 %s · 고리 %d다(아군마다 덜 내려온 기둥 하나, 고리 없음이어야 한다)" % [cols.map(func(p): return [p[0], p[2]]), v.rings.size()]
	v.wipe()
	v._miracle(hits, View.PILLAR + 0.02)
	cols = v.pxs.filter(func(p): return p[2].x > 1)
	if why == "" and (cols.size() != 2 or cols.any(func(p): return p[2].y != View.PILLAR_H) or v.rings.size() != 2 or v.spr.filter(func(q): return q[0] == "mend").size() != 2):
		why = "내려온 뒤 기둥 %s · 고리 %d · 조각 %s다(아군마다 다 내려온 기둥·고리·반짝 하나씩이어야 한다)" % [cols.map(func(p): return p[2]), v.rings.size(), v.spr]
	for x in hits:  # 기둥 아래 끝이 그 아군 발밑이다
		var feet := Vector2i(v._spot(x).floor())
		if why == "" and not cols.any(func(p): return p[0].y + p[2].y == feet.y and absi(p[0].x + p[2].x / 2 - feet.x) <= 1):
			why = "%s 발밑 %s에 닿은 기둥이 없다" % [x.kind, feet]
	v.free()
	return why

func test_enfeeble_ring_closes_inward_and_marks_cursed_heads():
	var b = _duo()
	var e = _target(b, Vector2i(14, 13))
	if not _ready_cast(b, b.heroes[1], "w", Vector2(14, 13)):
		return "베스퍼 W를 못 썼다"
	b.step(1.0 / 60.0)
	var v = Rec.new()
	v.battle = b
	v._foes = b.enemies
	var c := Vector2i(v._center(Vector2(14, 13)).floor())
	var rad := View.CELL * 2.0
	v._hex(c, rad, 0.01, 7)
	var r0: Array = v.rings.map(func(r): return r[1])
	v.wipe()
	v._hex(c, rad, View.HEX_CLOSE * 0.9, 7)
	var r1: Array = v.rings.map(func(r): return r[1])
	var why := ""
	if r0.size() != 1 or r1.size() != 1 or r0[0] < int(rad * 0.9) or r1[0] >= r0[0] or r1[0] < int(rad * 0.6):
		why = "고리 반지름이 %s → %s다(반경에서 0.6배까지 조여들어야 한다)" % [r0, r1]
	var hx: Array = v.spr.filter(func(q): return q[0] == "hex")
	if why == "" and (hx.size() != 1 or hx[0][2].y >= int(v._spot(e).y - v._head(e))):
		why = "저주 문양이 %s다(걸린 적 머리 위에 하나여야 한다)" % [hx]
	v.free()
	return why

func test_soul_chain_cast_draws_line_ring_and_teal_links():
	var b = _duo()
	var e = _target(b, Vector2i(14, 13))
	_target(b, Vector2i(16, 13))
	if not _ready_cast(b, b.heroes[1], "e", e):
		return "베스퍼 E를 못 썼다"
	b.step(1.0 / 60.0)
	var v = Rec.new()
	v.battle = b
	v._foes = b.enemies
	v._traces(true)
	var why := ""
	var to := Vector2i(v._chest(e).floor())
	if not v.lines.any(func(l): return l[1] == to and l[2] in [View.PX.teal, View.PX.midteal, View.PX.deepteal]):
		why = "베스퍼에서 대상까지 청록 줄이 없다: %s" % [v.lines]
	elif v.rings.size() != 1:
		why = "대상 둘레 고리가 %d개다(하나여야 한다)" % v.rings.size()
	elif not v.spr.any(func(q): return q[0] == "link"):
		why = "묶인 적끼리 잇는 사슬 고리가 없다"
	v.free()
	return why

func test_sanctum_fog_swamp_are_materials_without_old_patterns():
	var v = _zone_draw("seraphina_w")
	var why := ""
	if not v.spr.any(func(q): return q[0] == "glyph") or v.lines.any(func(l): return l[3] > 1) or v.pxs.size() != View.MOTES:
		why = "성역이 조각 %s · 줄 굵기 %s · 빛 점 %d다(성휘와 빛 점 %d, 굵은 십자 없음이어야 한다)" % [v.spr, v.lines.map(func(l): return l[3]), v.pxs.size(), View.MOTES]
	v.free()
	v = _zone_draw("vesper_q")
	var names: Array = v.spr.map(func(q): return q[0])
	if why == "" and (names.count("fog") != View.FOGS or names.count("fizz") != View.FIZZ or not v.rings.is_empty()):
		why = "독안개가 조각 %s · 고리 %d다(안개 %d · 거품 %d, 거품 고리 무늬 없음이어야 한다)" % [names, v.rings.size(), View.FOGS, View.FIZZ]
	v.free()
	v = _zone_draw("vesper_r")
	var vio: Array = ["vio0", "vio1", "vio2", "vio3", "vio4"].map(func(n): return View.PX[n])
	if why == "" and (v.rings.size() != View.RIPPLES or not v.lines.is_empty() or _colors(v).any(func(c): return c in vio)):
		why = "늪이 물결 %d · 줄 %d · 색 %s다(물결 %d, 물결 가로줄 없음, 보라 없음이어야 한다)" % [v.rings.size(), v.lines.size(), _colors(v), View.RIPPLES]
	v.free()
	return why

func test_fx3_draws_only_palette_colors():
	var b = _duo()
	var s = b.heroes[0]
	var x = b.heroes[1]
	var e = _target(b, Vector2i(12, 12))
	var v = Rec.new()
	v.battle = b
	for t in [0.0, 0.05, 0.1, 0.15, 0.2, 0.25]:
		v._beam(s, [x, e, s], t)
		v._angel(s, x, t, true)
		v._angel(s, x, t, false)
		v._miracle([s, x], t)
		v._hex(Vector2i(100, 100), 32.0, t, 7)
		v._shackle(x, e, t)
	var off := _off_palette(_colors(v))
	v.free()
	if off != "":
		return "fx-3 흔적에 팔레트 밖 색 %s가 있다" % off
	for src in ["seraphina_w", "vesper_q", "vesper_r"]:
		var w = _zone_draw(src)
		off = _off_palette(_colors(w))
		w.free()
		if off != "":
			return "%s 장판에 팔레트 밖 색 %s가 있다" % [src, off]
	return ""

func _chronos():
	var b = Battle.new({"size": Vector2i(30, 30), "base": Vector2i(28, 28), "base_hp": 100, "spawns": [Vector2i(0, 20)],
		"heroes": [{"kind": "chronos", "cell": Vector2i(10, 10)}, {"kind": "seraphina", "cell": Vector2i(14, 10)}], "waves": [[{"kind": "basic", "count": 1}]]})
	b.start_battle()
	b._queue = []
	return b

# 크로노스가 slot을 동료에게 쓰고 한 스텝 뒤 흔적을 그린 기록 화면. 못 쓰면 null
func _chronos_cast(slot: String):
	var b = _chronos()
	if not _ready_cast(b, b.heroes[0], slot, b.heroes[1]):
		return null
	b.step(1.0 / 60.0)
	var v = Rec.new()
	v.battle = b
	v._traces(true)
	return v

func test_overcharge_and_rewind_draw_line_ring_and_their_own_marks():
	if not View.FX_ART.has("clock"):
		return "이펙트 아틀라스에 clock 조각이 없다"
	var v = _chronos_cast("q")
	if v == null:
		return "크로노스 Q를 못 썼다"
	var to := Vector2i(v._chest(v.battle.heroes[1]).floor())
	var why := ""
	if not v.lines.any(func(l): return l[1] == to and l[2] in [View.PX.gold, View.PX.bronze] and l[3] == 2):
		why = "과충전: 크로노스에서 대상까지 굵기 2 금 줄이 없다: %s" % [v.lines]
	elif v.rings.size() != 1 or v.pxs.size() != 4:
		why = "과충전: 고리 %d · 불티 %d다(고리 하나 · 불티 넷이어야 한다)" % [v.rings.size(), v.pxs.size()]
	v.free()
	if why != "":
		return why
	v = _chronos_cast("w")
	if v == null:
		return "크로노스 W를 못 썼다"
	var x = v.battle.heroes[1]
	to = Vector2i(v._chest(x).floor())
	if not v.lines.any(func(l): return l[1] == to and l[2] in [View.PX.cream, View.PX.gold]):
		why = "되감기: 크로노스에서 대상까지 크림 줄이 없다: %s" % [v.lines]
	elif not v.spr.any(func(q): return q[0] == "clock"):
		why = "되감기: 대상 머리 위 시계 조각이 없다: %s" % [v.spr]
	if why == "":
		var r := []
		for t in [0.05, 0.25]:
			v.wipe()
			v._rewind(v.battle.heroes[0], x, t)
			r.append(v.rings[0][1] if v.rings.size() == 1 else -1)
		if r[0] <= r[1] or r[1] < 0:
			why = "되감기 고리 반지름이 0.05초 %d → 0.25초 %d다(고리 하나가 안으로 조여들어야 한다)" % r
	v.free()
	return why

func test_golden_law_and_time_warp_are_materials_without_old_patterns():
	var v = _zone_draw("chronos_e")
	var gear: Array = v.rings.filter(func(r): return r[2] == 2 and r[4] > 0)
	var why := ""
	if not v.lines.is_empty() or gear.size() != 1 or v.pxs.size() < View.COINS or v.fills != [View.PX.bronze] or v.edges != [[View.PX.gold, View.PX.soot]]:
		why = "황금률이 줄 %d · 톱니 고리 %d · 칸 %d · 칠 %s · 경계 %s다(햇살 없음, 톱니 하나, 동전 %d 이상, 청동 칠, 금 경계여야 한다)" % [
			v.lines.size(), gear.size(), v.pxs.size(), v.fills, v.edges, View.COINS]
	else:
		var turn: float = gear[0][5]
		v.clock = 2.0
		v.wipe()
		v._zones()
		if is_equal_approx(v.rings.filter(func(r): return r[2] == 2)[0][5], turn):
			why = "황금률 톱니 고리가 1초 뒤에도 같은 각(%s)이다(돌아야 한다)" % turn
	v.free()
	if why != "":
		return why
	v = _zone_draw("chronos_r")
	var ice: Array = ["ice0", "ice1", "ice2", "ice3", "ice4", "navy", "night", "soot"].map(func(n): return View.PX[n])
	var turns: Array = v.rings.map(func(r): return signf(r[5]))
	if v.rings.size() != 2 or not v.rings.all(func(r): return r[4] > 0) or turns[0] == turns[1] or v.lines.size() != 2 or not _colors(v).all(func(c): return c in ice):
		why = "왜곡장이 고리 %s · 줄 %d · 색 %s다(반대로 도는 점선 고리 둘, 바늘 둘, 얼음색만이어야 한다)" % [v.rings.map(func(r): return [r[1], r[4], r[5]]), v.lines.size(), _colors(v)]
	v.free()
	return why

func test_fx4_draws_only_palette_colors():
	var b = _chronos()
	var v = Rec.new()
	v.battle = b
	for t in [0.0, 0.05, 0.1, 0.15, 0.2, 0.25]:
		v._charge(b.heroes[0], b.heroes[1], t, 7)
		v._rewind(b.heroes[0], b.heroes[1], t)
	var off := _off_palette(_colors(v) + [View.TELL])
	v.free()
	if off != "":
		return "크로노스 흔적·보스 예고에 팔레트 밖 색 %s가 있다" % off
	for src in ["chronos_e", "chronos_r"]:
		var w = _zone_draw(src)
		off = _off_palette(_colors(w))
		w.free()
		if off != "":
			return "%s 장판에 팔레트 밖 색 %s가 있다" % [src, off]
	return ""

func test_map_draws_no_screen_px_circles():
	var src := FileAccess.get_file_as_string("res://src/ui/battle_view.gd")
	if src.count("draw_arc(") > 0:
		return "battle_view.gd에 draw_arc가 %d곳 남았다(원·호는 아트 px 고리여야 한다)" % src.count("draw_arc(")
	if src.count("draw_circle(") != 4:
		return "battle_view.gd의 draw_circle이 %d곳이다(그림자·대역 몸 넷만 남아야 한다)" % src.count("draw_circle(")
	return ""
