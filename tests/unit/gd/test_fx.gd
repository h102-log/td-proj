extends RefCounted
# 영웅 이펙트 C 묶음 fx-1~fx-4(WBS 4.1s)의 그리기 규칙을 본다.
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
#   S179·S168·S198·I101 2026-10-28 변경(fx-4). 크로노스(금·얼음): 과충전은 대상의 쏘는 곳까지 금 줄과 번개 조각(영웅·구조물 대상 모두),
#         보스 예고는 F24+ 빨강 두 겹 테와 차오르는 성긴 칠, 발동 채움은 원판이고,
#         조준 미리보기(사거리·범위·부채꼴·방향·설 칸)는 아트 px 도우미로 그린다(덮개 위 층 _cv).
#   I101 2026-10-28 셋째 변경. 명령 표식·홀드 기준 반경·대포알 고리도 아트 px 고리라 맵에 화면 px 원·호(draw_arc)가 없다.
#   I215·S153 2026-11-01 변경. 실비아 바람: 순풍 장판은 실비아 → 장판 쪽으로 흐르는 줄, 렌즈는 실비아 → 지점에 수직인 관문(양옆 경계·양 끝 기둥),
#         바람의 길은 두 가닥 나선, 저격은 표적 괄호(SNIPE_MARK초)와 화면 밖 꺾쇠, 렌즈를 지난 화살은 굵은 촉과 막 지날 때 번쩍 고리,
#         순풍에서 온 공격 속도는 발 둘레 바람 줄 조각(다른 공격 속도가 함께면 사각형도).
#   I199 2026-11-04 변경(fx-7). «크로노스 새 칸의 그림은 색으로 시간의 방향을 나눈다. 노화는 앞으로 감기(시계 방향, 모래빛), 시간의 문과 되돌림은
#         되감기(반시계, 얼음 램프), 태엽 감기는 놋쇠 태엽(금·구리)이다.» 노화는 시계 방향 점선 테 + 모래알 16 + 걸린 적 머리 위 모래시계,
#         시간의 문은 얼음 칠 2/16 · 눈금 넷 · 반시계 바늘 둘 · 어두운 축, 문에 든 적은 머리 위 남은 시간 고리(마지막 0.5초 깜박)와 되돌아갈 자리 점 + 흐린 점선,
#         되돌림은 조여드는 반시계 얼음 점선 → 얼음 번쩍 + 옛 자리 쪽부터 사라지는 잔상 넷(노화 되감기면 터지는 금 고리),
#         태엽 감기 둘레는 금 테두리 + 시계 방향 톱니 28(쓴 순간 빨리) · 칠 1/16 이하, 둘레 안 아군 영웅·탑은 어두운 테두리 태엽 열쇠(0.12초마다 뒤집힘)다.
#   I227 2026-11-04(fx-8). 세라피나: 빛줄기는 빛 구슬이 BEAM_HOP초(마디가 많으면 BEAM_SPAN을 나눔)에 한 마디씩 건너고 먼저 지난 마디가 먼저 식는다,
#         성역 정화는 몸 양옆에서 솟는 빛 점 두 줄기(정화 흔적은 0.5초에 하나), 성역 안 아군은 오르는 금 십자, 수호 천사 4초는 등 뒤 접힌 날개,
#         불사 순간은 크림 원판 + 깃털(공용 금 테·별은 그대로), 축복은 쏘는 곳 옆 마름모 빛 맺힘, 축복 터짐은 크림 십자 + 대각선 조각 넷,
#         세라피나 보호막은 금 점선 테다. 정화·축복 터짐·불사 흔적에는 맞은 대상이 없다.
#   I226 2026-11-04(fx-9, 위 fx-3의 베스퍼 쇠약·사슬·늪보다 우선). 베스퍼: 쇠약의 저주는 조여들며 반시계로 도는 그림자 고리(HEX_SEGS마디로 들쭉날쭉 끊긴 연기 테두리,
#         바깥 검정 1px도 같은 각에서 끊김) + 검은 연기 가닥 HEX_WISPS, 영혼 사슬은 E 대상(hub)에서 시작하는 나무 모양 쇠사슬(굵기 2, 크림·재),
#         피해 나누기는 흔적 share(초당 피해 빼고)와 맞은 적 가슴에서 퍼지는 크림 고리 + 맞은 적에서 사슬을 따라 흐르는 크림 빛(가운데 청록, 바깥 검정),
#         전염은 옮은 적이 있을 때만 흔적 spread와 전염 반경까지 퍼지는 점선 고리(약 PLAGUE_DASH px 주기) + 옮은 적 머리 위 해골(떠오르고 끝에 깜박),
#         늪은 진흙·깊은 청록 물 칠 + 가운데서 퍼지는 1px 물결 BOG_WAVES(BOG_DASH px마다 끊긴 점선), 늪에 든 적은 발이 진흙 띠에 잠긴다. 색은 팔레트 안이다.
#   I228(fx-10). 아이아스: 요새화는 발 앞 돌담 다섯(아래 층), 자기 받는 피해 감소에는 공용 방패가 없다. 방패 강타는 밀려 나가는 방패 조각 + 2px 호,
#         밀린 적은 발 양옆 흙먼지. 포효는 충격파 둘 + 외침 선 다섯, 포효 보호막만이면 머리 위 지붕 호. 태세는 방패 테두리 + 쌓인 피해 테(막으면 번쩍),
#         터뜨림은 납작한 팔각 충격파 + 아래 층 균열, 공명은 벽 테두리 번쩍 + 떠오르는 작은 고리, 둘레 칠 1/16, 성벽 북쪽 끝 흉벽 이빨 셋이다.

const View := preload("res://src/ui/battle_view.gd")
const Battle := preload("res://src/sim/battle.gd")

# 조각·도형을 그리지 않고 조각 이름만 모으는 화면. 선·호·칸은 따로 모은다
class Rec extends "res://src/ui/battle_view.gd":
	var spr := []
	var lines := []  # [a, b, 색, 굵기]
	var arcs := []  # [반지름, 굵기, a0, a1, 색]
	var rings := []  # [가운데, 반지름, 굵기, 색, 점선, 점선 돌림]
	var segs := []  # 끊긴 고리 [가운데, 반지름, 굵기, 색, 마디 수, 돌림, 해시]. 칸은 그대로 그려 pxs에 남는다
	var pxs := []  # [자리, 색, 크기]
	var fills := []  # 성긴 칠 색
	var noise := []  # 성긴 칠 [반지름, 밀도]
	var discs := []  # 원판 [가운데, 반지름, 색]
	var edges := []  # 판정 경계 [밝은 색, 어두운 색]
	var shown := Rect2()  # 화면에 보이는 맵 영역으로 칠 사각형(트리 밖이라 직접 준다)
	func shown_rect() -> Rect2:
		return shown
	func _spr(name: String, frame: int, at: Vector2i, bottom := false) -> void:
		spr.append([name, frame, at])
	func _pring(c: Vector2i, r: int, th: int, col: Color, dash := 0, spin := 0.0) -> void:
		spr.append(["ring", th])
		rings.append([c, r, th, col, dash, spin])
	func _seg_ring(c: Vector2i, r: int, th: int, col: Color, n: int, spin: float, seed := -1) -> void:
		segs.append([c, r, th, col, n, spin, seed])
		super(c, r, th, col, n, spin, seed)
	func _pline(a: Vector2i, b: Vector2i, col: Color, w := 1) -> void:
		lines.append([a, b, col, w])
	func _parc(c: Vector2i, r: int, th: int, a0: float, a1: float, col: Color) -> void:
		arcs.append([r, th, a0, a1, col])
	func _pdisc(c: Vector2i, r: int, col: Color) -> void:
		discs.append([c, r, col])
	func _pnoise(c: Vector2i, r: int, col: Color, lim: int, salt := 0) -> void:
		fills.append(col)
		noise.append([r, lim])
	func _px(p: Vector2i, col: Color, size := Vector2i.ONE) -> void:
		pxs.append([p, col, size])
	func _edge(c: Vector2i, r: int, light: Color, dark: Color, others := []) -> void:
		edges.append([light, dark])
	func wipe() -> void:
		for a in [spr, lines, arcs, rings, segs, pxs, fills, noise, discs, edges]:
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
	var down := marks.filter(func(m): return m.k == "down")
	if why == "" and (down.map(func(m): return m.f) != [0] or kinds.has("frost")):
		why = "둔화가 능력치 감소 줄 화살표 하나(프레임 0)가 아니다: %s" % [kinds]  # I101 2026-11-04 변경
	if why == "" and (not kinds.has("flame_s") or marks.filter(func(m): return m.k == "px").size() < 4):
		why = "발화가 작은 불꽃 + 불티 넷이 아니다: %s" % [kinds]
	var icons := marks.filter(func(m): return m.k in ["taunt", "seal"])
	if why == "" and (icons.size() != 2 or icons.any(func(m): return m.p.y >= stars.map(func(s): return s.p.y).min())):
		why = "도발·봉인 기호가 %s다(별보다 위에 둘이어야 한다)" % [icons.map(func(m): return [m.k, m.p])]
	v.free()
	return why

# fx-5 판정: 속박·둔화·독 방울이 발밑 팀 타원(발밑 y −2~+3, _feet_mark)에 묻혔다. 조각 아랫줄이 타원 윗줄보다 위여야 한다.
# 둔화는 능력치 감소 줄(I101 2026-11-04 변경)로 옮겨 타원 아랫줄보다 아래여야 한다(체력바를 끈 때)
func test_root_poison_above_team_ellipse_and_debuff_row_below():
	var b = _battle()
	var v = View.new()
	v.battle = b
	var e = b.spawn_enemy("basic", Vector2i(10, 10), {"speed": 0})
	b._fx(e, "sylvia_e", {"root": true}, 2.0)
	b._fx(e, "chronos_r", {"slow": 0.4}, 2.0)
	b._fx(e, "vesper_q", {"dot": 3.0}, 2.0)
	var feet: Vector2i = Vector2i((v._spot(e) + v._slip(e)).floor())
	var why := ""
	for t in [0.0, 0.13, 0.26, 0.39, 0.49]:
		v.clock = t
		var marks: Array = v.status_marks(e, false)
		var kinds := marks.map(func(m): return m.k)
		if kinds.count("bind") != 1 or kinds.count("down") != 1 or kinds.count("venom") != 2:
			why = "밧줄 1·줄 화살표 1·방울 2가 아니다: %s" % [kinds]
			break
		for m in marks:
			var h: int = View.FX_ART[m.k][3]
			if m.k == "down":
				if m.p.y - h / 2 <= feet.y + 3:
					why = "줄 화살표 윗줄이 %d다(발밑 %d, 타원 아랫줄 %d보다 아래여야 한다)" % [m.p.y - h / 2, feet.y, feet.y + 3]
					break
			elif m.p.y - h / 2 + h - 1 >= feet.y - 2:
				why = "%s 아랫줄이 %d다(발밑 %d, 타원 윗줄 %d보다 위여야 한다, 시각 %.2f)" % [m.k, m.p.y - h / 2 + h - 1, feet.y, feet.y - 2, t]
				break
		if why != "":
			break
	v.free()
	return why

func test_ally_effects_use_halo_only_for_shield_and_invuln():
	var b = _battle()
	var v = View.new()
	v.battle = b
	var h = b.heroes[0] if not b.heroes.is_empty() else b.units[0]
	h.shields["test"] = {"hp": 10.0, "left": 2.0}
	b._fx(h, "aias_r", {"dr": 0.3}, 2.0)  # 절대 방어선 둘레에서 온 받는 피해 감소는 공용 방패 둘이다(아이아스 자기 것은 I228 ②)
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

# I228 ③: 방패 조각이 0.12초에 부채꼴 쪽으로 밀려 나가고, 베기 띠는 앞 가장자리 크림·겹 수 4 → 2, 그 뒤 0.4초까지 2px 호 하나
func test_shield_bash_slams_shield_out_then_thick_band_and_two_px_arc():
	var v = Rec.new()
	var c := Vector2i(100, 100)
	var d := 0.5
	var half := PI / 4.0
	v._bash(c, 32.0, d, half, 0.02, [])
	var why := ""
	var radii: Array = v.arcs.map(func(a): return a[0])
	var near: Array = v.spr.filter(func(s): return s[0] == "aegis")
	if v.arcs.size() < 2 or radii.max() - radii.min() != v.arcs.size() - 1 or v.arcs.any(func(a): return absf(a[2] - (d - half)) > 1e-4 or absf(a[3] - (d + half)) > 1e-4):
		why = "쓴 직후 베기가 %s다(부채꼴 안 이어진 띠 둘 이상이어야 한다)" % [v.arcs]
	elif v.arcs.filter(func(a): return a[0] >= radii.max() - 1).any(func(a): return a[4] != View.PX.cream):
		why = "베기 앞 가장자리 두 겹이 크림이 아니다"
	elif near.size() != 1 or near[0][1] != 0:
		why = "쓴 직후 방패 조각이 %s다(흰 번쩍 프레임 하나여야 한다)" % [near]
	v.wipe()
	v._bash(c, 32.0, d, half, 0.1, [])
	var far: Array = v.spr.filter(func(s): return s[0] == "aegis")
	var dir := Vector2.from_angle(d)
	if why == "" and (far.size() != 1 or far[0][1] != 1 or Vector2(far[0][2] - near[0][2]).dot(dir) < 6.0):
		why = "0.1초 방패 조각이 %s다(보라 방패가 부채꼴 쪽으로 6px 넘게 나가야 한다)" % [far]
	v.wipe()
	v._bash(c, 32.0, d, half, View.SWEEP + 0.05, [])
	if why == "" and (v.arcs.size() != 1 or v.arcs[0][0] != 32 or v.arcs[0][1] != 2 or v.spr.any(func(s): return s[0] == "aegis")):
		why = "베기 뒤 %s · %s다(반경 32의 2px 호 하나, 방패 조각 없음이어야 한다)" % [v.arcs, v.spr]
	v.wipe()
	v._bash(c, 32.0, d, half, View.FX + 0.05, [])
	if why == "" and v.arcs.size() != 1:
		why = "0.35초에 호가 %d개다(0.4초까지 남아야 한다)" % v.arcs.size()
	v.wipe()
	v._bash(c, 32.0, d, half, View.FX + 0.1, [])
	if why == "" and not v.arcs.is_empty():
		why = "0.4초 뒤에도 호를 그린다"
	v.free()
	return why

# I228 ③: 요새화 중 방패 강타에 밀린 적(둔화가 걸린 적)만 발 양옆으로 흙먼지(2×2)가 퍼진다(0.45초, 몸통 아래 층)
func test_shield_bash_shoves_kick_dust_beside_feet_below_bodies():
	var b = _pair()
	var v = Rec.new()
	v.battle = b
	var pushed = b.spawn_enemy("basic", Vector2i(10, 12), {"speed": 0, "sight": 0, "damage": 0, "hp": 1e9})
	var still = b.spawn_enemy("basic", Vector2i(12, 12), {"speed": 0, "sight": 0, "damage": 0, "hp": 1e9})
	b._fx(pushed, "aias_q_slow", {"slow": 0.3}, 3.0)
	v._foes = [pushed, still]
	var c := Vector2i(v._center(Vector2(10, 10)).floor())
	v._shove(c, [pushed, still], 0.1)
	var feet: Vector2i = Vector2i((v._spot(pushed) + v._slip(pushed)).floor())
	var dust: Array = v.pxs.filter(func(p): return p[2] == Vector2i(2, 2))
	var why := ""
	if dust.size() != 6 or dust.any(func(p): return absi(p[0].x - feet.x) < 4 or absi(p[0].y - feet.y) > 4) or dust.any(func(p): return not p[1] in [View.PX.cream, View.PX.ash, View.PX.smoke]):
		why = "밀린 적 흙먼지가 %s다(발 양옆 2×2 여섯, 크림·재·연기여야 한다)" % [dust]
	elif dust.filter(func(p): return p[0].x < feet.x).size() != 3:
		why = "흙먼지가 한쪽으로 쏠렸다: %s" % [dust]
	v.wipe()
	v._shove(c, [pushed], 0.45)
	if why == "" and not v.pxs.is_empty():
		why = "0.45초 뒤에도 흙먼지를 그린다"
	v.free()
	return why

# I228 ④: 충격파 고리 둘은 그대로, 외침 선은 머리 위 부채꼴 다섯(굵기 2 → 1, 크림 → 금)
func test_war_cry_two_shock_rings_five_shouts_above_and_dust_below():
	var b = _pair()
	var v = Rec.new()
	v.battle = b
	var h = b.heroes[0]
	v._cry(Vector2i(100, 100), 48.0, View.CRY_ECHO + 0.02, 7, h, true)
	var why := ""
	var top := int(v._spot(h).y - v._head(h)) + 6
	if v.rings.size() != 2 or v.rings[0][1] <= v.rings[1][1] or v.rings.any(func(r): return r[2] < 1):
		why = "충격파가 %s다(바깥 고리와 늦게 나온 안쪽 고리 둘이어야 한다)" % [v.rings.map(func(r): return [r[1], r[2]])]
	elif v.lines.size() != 5 or v.lines.any(func(l): return l[0].y >= top or l[1].y >= l[0].y or l[3] != 2 or l[2] != View.PX.cream):
		why = "외침 선이 %s다(머리 위로 뻗는 크림 2px 다섯이어야 한다)" % [v.lines]
	elif v.lines.map(func(l): return l[1].x - l[0].x).min() >= 0 or v.lines.map(func(l): return l[1].x - l[0].x).max() <= 0:
		why = "외침 선이 부채꼴로 퍼지지 않는다: %s" % [v.lines]
	v.wipe()
	v._cry(Vector2i(100, 100), 48.0, 0.25, 7, h, true)
	if why == "" and (v.lines.size() != 5 or v.lines.any(func(l): return l[3] != 1 or l[2] != View.PX.gold)):
		why = "0.25초 외침 선이 %s다(금 1px로 식어야 한다)" % [v.lines]
	v.wipe()
	v._cry(Vector2i(100, 100), 48.0, 0.3, 7, h, true)
	if why == "" and not v.lines.is_empty():
		why = "0.3초 뒤에도 외침 선을 그린다"
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
	if lit < inside * 0.03 or lit > inside * 0.07:  # inside는 실제 캡슐보다 커서 2/16이면 약 0.09다
		return "성긴 칠이 %d칸이다(안쪽의 약 1/16이어야 한다, I228 ⑦)" % lit
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
	var want := [["q", a, Vector2(10, 12), "spark"], ["e", a, null, "aegis"], ["e", a, null, "line"], ["r", s, null, "spark"]]  # 터뜨림은 팔각 충격파 선(I228 ⑥)
	for w in want:
		if w[3] == "line":
			a.braced = 30.0
			b.cast(a, "e")
		elif not _ready_cast(b, w[1], w[0], w[2]):
			v.free()
			return "%s %s를 못 썼다" % [w[1].kind, w[0]]
		b.step(1.0 / 60.0)
		v.wipe()
		v._traces(true)
		var got: Array = v.spr.map(func(x): return x[0]) + (["arc"] if not v.arcs.is_empty() else []) + (["line"] if not v.lines.is_empty() else [])
		if w[3] == "line" and got.has("burst"):
			v.free()
			return "터뜨림에 터짐 조각이 남았다: %s" % [got]
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

# ── fx-10: 아이아스(I228) ──

# ① 요새화가 켜진 동안 발 앞 반원에 돌담 다섯(그을음 그림자 + 연기 몸 + 재 윗줄). 켜진 순간은 그림자만이고 0.25초에 솟는다
func test_fortify_stone_wall_rises_in_front_half_of_feet():
	var b = _pair()
	var v = Rec.new()
	v.battle = b
	var a = b.heroes[0]
	var feet: Vector2i = Vector2i((v._spot(a) + v._slip(a)).floor())
	v._fort_wall(a)
	var why := ""
	if not v.pxs.is_empty():
		why = "요새화 전에 돌담을 그린다: %s" % [v.pxs]
	a.still = a.passive.still
	a.fort = true
	v.wipe()
	v._fort_wall(a)
	var shadows: Array = v.pxs.filter(func(p): return p[1] == View.PX.soot and p[2] == Vector2i(4, 1))
	if why == "" and (shadows.size() != 5 or v.pxs.any(func(p): return p[1] == View.PX.smoke and p[2].y > 1)):
		why = "켜진 순간이 %s다(그림자 다섯, 아직 솟지 않음이어야 한다)" % [v.pxs]
	a.still = a.passive.still + 0.3
	v.wipe()
	v._fort_wall(a)
	var bodies: Array = v.pxs.filter(func(p): return p[1] == View.PX.smoke and p[2] == Vector2i(4, 3))
	var tops: Array = v.pxs.filter(func(p): return p[1] == View.PX.ash and p[2] == Vector2i(4, 1))
	if why == "" and (bodies.size() != 5 or tops.size() != 5):
		why = "0.3초 돌담이 몸 %d · 윗줄 %d다(다섯씩이어야 한다)" % [bodies.size(), tops.size()]
	elif why == "" and bodies.any(func(p): return p[0].y + 3 < feet.y - 2):
		why = "돌담이 발 위쪽(몸 뒤)에 있다: %s" % [bodies.map(func(p): return p[0])]
	elif why == "" and (bodies.map(func(p): return p[0].x).min() > feet.x - 8 or bodies.map(func(p): return p[0].x + 4).max() < feet.x + 8):
		why = "돌담이 발 양옆까지 닿지 않는다: %s" % [bodies.map(func(p): return p[0])]
	a.still = a.passive.still + 2.0
	v.wipe()
	v._fort_wall(a)
	if why == "" and v.pxs.size() != 15:
		why = "먼지가 0.4초 뒤에도 남았다(칸 %d개, 돌담 15칸이어야 한다)" % v.pxs.size()
	v.free()
	return why

# ② 아이아스 자기 받는 피해 감소(요새화·태세)에는 공용 방패 둘이 없고, 다른 데서 온 받는 피해 감소가 함께면 공용 방패 둘이 다시 보인다
func test_aias_own_damage_cut_hides_shared_guard():
	var b = _pair()
	var v = Rec.new()
	v.battle = b
	var a = b.heroes[0]
	b._fx(a, "aias_p", {"dr": 0.25}, 1.0)
	var why := ""
	if v.status_marks(a, true).any(func(m): return m.k == "guard"):
		why = "요새화만 걸렸는데 공용 방패가 있다"
	b._fx(a, "aias_r", {"dr": 0.4}, 1.0)
	if why == "" and v.status_marks(a, true).filter(func(m): return m.k == "guard").size() != 2:
		why = "절대 방어선 둘레가 함께인데 공용 방패 둘이 없다"
	var s = b.heroes[1]
	b._fx(s, "aias_e", {"dr": 0.5}, 1.0)
	if why == "" and v.status_marks(s, true).filter(func(m): return m.k == "guard").size() != 2:
		why = "아이아스가 아닌 영웅의 받는 피해 감소가 공용 방패 둘이 아니다"
	v.free()
	return why

# ④ 전장의 포효 보호막만 있으면 공용 얼음 테 대신 머리 위 지붕 호 셋(바깥 밝은 보라 · 보라 · 안쪽 어두운 보라). 다른 보호막이 함께면 공용 테
func test_war_cry_shield_alone_is_roof_arc_above_head():
	var b = _pair()
	var v = Rec.new()
	v.battle = b
	var a = b.heroes[0]
	a.shields["aias_w"] = {"hp": 10.0, "left": 5.0}
	var marks: Array = v.status_marks(a, true)
	var arcs: Array = marks.filter(func(m): return m.k == "arc")
	var why := ""
	if marks.any(func(m): return m.k == "ring"):
		why = "포효 보호막만인데 공용 테가 있다"
	elif arcs.size() != 3 or arcs.any(func(m): return m.a0 >= m.a1 or m.a1 > 0.0 or m.a0 < -PI) or arcs.map(func(m): return m.c) != [View.PX.vio0, View.PX.vio1, View.PX.vio3]:
		why = "지붕 호가 %s다(머리 위 반원 셋, 바깥부터 밝은 보라 · 보라 · 어두운 보라여야 한다)" % [arcs]
	elif arcs.map(func(m): return m.r) != [arcs[1].r + 1, arcs[1].r, arcs[1].r - 1]:
		why = "지붕 호 반지름이 %s다(1px씩 붙어야 한다)" % [arcs.map(func(m): return m.r)]
	a.shields["test"] = {"hp": 10.0, "left": 2.0}
	marks = v.status_marks(a, true)
	if why == "" and (marks.filter(func(m): return m.k == "ring").size() != 1 or marks.any(func(m): return m.k == "arc")):
		why = "다른 보호막이 함께인데 공용 테 하나가 아니다: %s" % [marks.map(func(m): return m.k)]
	v.free()
	return why

# ⑤ 태세가 걸린 동안(0.3초 뒤부터) 몸 앞 방패 테두리 프레임 + 쌓인 피해 테(최대 체력 20%면 반지름 11 크림). 막은 직후 흰 번쩍, 마지막 0.5초 깜박
func test_brace_shows_outline_shield_and_charge_ring_until_burst():
	var b = _pair()
	var v = Rec.new()
	v.battle = b
	var a = b.heroes[0]
	b.spawn_enemy("basic", Vector2i(25, 25), {"speed": 0, "sight": 0, "damage": 0, "hp": 1e9})  # 적이 없으면 첫 스텝 뒤 판이 끝나 태세가 지워진다
	if not _ready_cast(b, a, "e"):
		v.free()
		return "태세를 못 썼다"
	var why := ""
	if v.status_marks(a, true).any(func(m): return m.k == "aegis"):
		why = "쓴 직후(흔적의 방패 조각 0.3초 안)에도 걸린 동안 표시를 그린다"
	a.brace = a.e.time - View.FX - 0.1
	var marks: Array = v.status_marks(a, true)
	var shield: Array = marks.filter(func(m): return m.k == "aegis")
	var ring: Array = marks.filter(func(m): return m.k == "ring")
	if why == "" and (shield.size() != 1 or shield[0].f != 2 or ring.size() != 1 or ring[0].r != 8 or ring[0].c != View.PX.vio2 or ring[0].p != shield[0].p):
		why = "받은 피해 없는 태세가 %s다(방패 테두리 프레임 + 반지름 8 어두운 보라 테여야 한다)" % [marks]
	elif why == "" and marks.any(func(m): return m.k == "guard"):
		why = "태세에 공용 방패 둘이 있다"
	b.damage(a, a.max_hp * View.BRACE_FULL, "true", null)
	b.step(1.0 / 60.0)
	marks = v.status_marks(a, true)
	shield = marks.filter(func(m): return m.k == "aegis")
	ring = marks.filter(func(m): return m.k == "ring")
	if why == "" and (shield.size() != 1 or shield[0].f != 0 or ring.size() != 1 or ring[0].r != 11 or ring[0].c != View.PX.cream):
		why = "최대 체력 20%%를 막은 직후가 %s다(흰 번쩍 프레임 + 반지름 11 크림 테여야 한다)" % [marks]
	for i in 10:
		b.step(1.0 / 60.0)
	if why == "" and v.status_marks(a, true).filter(func(m): return m.k == "aegis").any(func(m): return m.f != 2):
		why = "막고 0.18초 뒤에도 흰 번쩍이다"
	a.brace = 0.3
	var seen := []
	for t in [0.0, 0.05, 0.1, 0.13, 0.15, 0.18]:
		v.clock = t
		seen.append(v.status_marks(a, true).any(func(m): return m.k == "aegis"))
	if why == "" and (not seen.has(true) or not seen.has(false)):
		why = "남은 0.5초 밑에서 깜박이지 않는다: %s" % [seen]
	v.free()
	return why

# ⑧ 태세 중 받은 피해는 맞은 대상이 없는 block 흔적을 남긴다. 태세가 아니면 남기지 않는다
func test_braced_hit_leaves_block_trace_without_hits():
	var b = _pair()
	var a = b.heroes[0]
	b.damage(a, 5.0, "phys", null)
	if b.traces.any(func(t): return t.slot == "block"):
		return "태세가 아닌데 block 흔적이 남았다"
	if not _ready_cast(b, a, "e"):
		return "태세를 못 썼다"
	b.traces.clear()
	b.damage(a, 5.0, "phys", null)
	var blk: Array = b.traces.filter(func(t): return t.slot == "block")
	if blk.size() != 1 or blk[0].hero != a or not blk[0].hits.is_empty():
		return "태세 중 피해의 흔적이 %s다(아이아스의 block 하나, 맞은 대상 없음이어야 한다)" % [blk]
	return ""

# ⑥ 터뜨림은 터짐 조각·고리 없이 납작한 팔각 충격파(앞 절반은 두 겹), 몸통 아래 층 균열 여덟(0.6초), 맞은 적 섬광
func test_burst_is_flat_octagon_shock_cracks_below_and_sparks():
	var b = _pair()
	var v = Rec.new()
	v.battle = b
	var e = b.spawn_enemy("basic", Vector2i(10, 12), {"speed": 0, "sight": 0, "damage": 0, "hp": 1e9})
	var c := Vector2i(100, 100)
	v._burst(c, 32.0, 0.02, 7, [e], true)
	var why := ""
	var w: int = v.lines.map(func(l): return absi(l[0].x - c.x)).max() if not v.lines.is_empty() else 0
	var h: int = v.lines.map(func(l): return absi(l[0].y - c.y)).max() if not v.lines.is_empty() else 0
	if v.spr.any(func(s): return s[0] == "burst") or not v.rings.is_empty():
		why = "터뜨림에 터짐 조각이나 고리가 있다: %s" % [v.spr]
	elif v.lines.size() != 16 or v.lines.any(func(l): return l[2] != View.PX.cream and l[2] != View.PX.vio0):
		why = "터뜨림 직후 선이 %d개다(크림 · 밝은 보라 팔각 둘, 16개여야 한다)" % v.lines.size()
	elif h >= w:
		why = "팔각이 납작하지 않다(가로 %d, 세로 %d)" % [w, h]
	elif not v.spr.any(func(s): return s[0] == "spark"):
		why = "맞은 적에 섬광이 없다"
	v.wipe()
	v._burst(c, 32.0, 0.2, 7, [e], true)
	if why == "" and v.lines.size() != 8:
		why = "0.2초 팔각이 선 %d개다(한 겹 8개여야 한다)" % v.lines.size()
	v.wipe()
	v._burst(c, 32.0, 0.3, 7, [e], false)
	if why == "" and (v.lines.size() != 16 or v.lines.any(func(l): return l[2] != View.PX.soot)):
		why = "0.3초 아래 층 균열이 %s다(그을음 꺾인 줄 여덟, 선 16개여야 한다)" % [v.lines.size()]
	v.wipe()
	v._burst(c, 32.0, 0.6, 7, [e], false)
	v._burst(c, 32.0, 0.3, 7, [e], true)
	if why == "" and not v.lines.is_empty():
		why = "0.6초 균열이나 0.3초 충격파가 남았다: %d" % v.lines.size()
	v.free()
	return why

# ⑥ 성벽 공명은 성벽 칸마다 벽 조각 위·아래 테두리 번쩍(0.12초)과, 벽 위로 떠오르며 퍼지는 보라 고리(0.3초)
func test_resonance_flashes_wall_edges_and_lifts_small_ring():
	var v = Rec.new()
	var q := Vector2i(6, 8)
	var c := Vector2i(v._center(Vector2(q)).floor())
	var tall := int(View.FX_ART.ward[3])
	var top := q * View.CELL - Vector2i(0, tall - View.CELL)
	v._resonate(c, 0.02)
	var why := ""
	var edges: Array = v.pxs.filter(func(p): return p[2] == Vector2i(View.CELL, 1))
	if edges.size() != 2 or edges.map(func(p): return p[0]) != [top, top + Vector2i(0, tall - 1)] or edges.any(func(p): return p[1] != View.PX.cream):
		why = "공명 직후 벽 테두리가 %s다(그림 위끝 %s와 아래끝의 크림 줄 둘이어야 한다)" % [edges, top]
	elif v.rings.size() != 1 or v.rings[0][1] > 4 or v.rings[0][0].y >= c.y:
		why = "공명 직후 고리가 %s다(가운데 위에 작은 고리 하나여야 한다)" % [v.rings]
	v.wipe()
	v._resonate(c, 0.2)
	if why == "" and (not v.pxs.is_empty() or v.rings.size() != 1 or v.rings[0][1] < 8):
		why = "0.2초 공명이 테두리 %d · 고리 %s다(번쩍 없이 커진 고리 하나여야 한다)" % [v.pxs.size(), v.rings]
	v.wipe()
	v._resonate(c, 0.3)
	if why == "" and not (v.pxs.is_empty() and v.rings.is_empty()):
		why = "0.3초 뒤에도 공명을 그린다"
	v.free()
	return why

# ⑦ 에너지 성벽 줄의 북쪽 끝 칸 윗면 뒤끝에 흉벽 이빨 셋(2×3 얼음 + 위 1px 밝은 얼음, 옆 남색 1px)
func test_energy_wall_north_end_cells_carry_three_merlons():
	var v = Rec.new()
	var q := Vector2i(6, 8)
	var tall := int(View.FX_ART.ward[3])
	var top := q * View.CELL - Vector2i(0, tall - View.CELL)
	v._merlons(top)
	var teeth: Array = v.pxs.filter(func(p): return p[1] == View.PX.ice1 and p[2] == Vector2i(2, 3))
	var why := ""
	if teeth.size() != 3 or teeth.any(func(p): return p[0].y != top.y - 3) or teeth.map(func(p): return p[0].x - top.x) != [1, 7, 13]:
		why = "흉벽 이빨이 %s다(윗면 뒤끝 위 x 1·7·13에 셋이어야 한다)" % [teeth]
	elif v.pxs.filter(func(p): return p[1] == View.PX.navy and p[2] == Vector2i(4, 3)).size() != 3 or v.pxs.filter(func(p): return p[1] == View.PX.ice0 and p[2] == Vector2i(2, 1)).size() != 3:
		why = "흉벽 이빨의 남색 옆선·밝은 윗줄이 셋씩이 아니다"
	v.free()
	return why

func test_toggle_on_shows_wind_at_feet_only_while_on():
	var b = _pair()
	var v = Rec.new()
	v.battle = b
	var s = b.heroes[1]
	var feet: Vector2i = Vector2i((v._spot(s) + v._slip(s)).floor())
	var why := ""
	if v.status_marks(s, true).any(func(m): return m.k == "gust"):
		why = "토글을 켜지 않았는데 바람 줄이 있다"
	s.toggle = true  # 지금 영웅 데이터에는 토글 칸이 없어 켠 상태를 직접 둔다
	var g: Array = v.status_marks(s, true).filter(func(m): return m.k == "gust")
	if why == "" and (g.size() != 1 or absi(g[0].p.y - feet.y) > 2):
		why = "켠 토글이 %s다(발밑 바람 줄 하나여야 한다)" % [g]
	v.free()
	return why

func _len(l: Array) -> float:
	return Vector2(l[1] - l[0]).length()

# I215 2026-11-01 변경: 바람의 길은 길 끝까지 닿는 양옆 경계(밝은 연두 1px + 바깥 어두운 1px), 짧은 마디로 이은 두 가닥 나선(앞 밝은 연두·뒤 어두운 연두),
# 연두 점 칠이다. 저격 흔적은 실비아에서 표적까지 닿는 줄이고, 표적 둘레 괄호(짧은 줄 여덟)가 SNIPE_MARK초까지만 남는다
func test_wind_path_helix_edges_and_snipe_brackets():
	var b = _pair()
	var s = b.heroes[1]
	var e = b.spawn_enemy("basic", Vector2i(24, 10), {"speed": 0, "sight": 0, "damage": 0, "hp": 1e9})
	var v = Rec.new()
	v.battle = b
	if not _ready_cast(b, s, "r"):
		v.free()
		return "실비아 R을 못 썼다"
	var c0 := Vector2i(v._center(s.pos).floor())
	var tip := Vector2i(v._center(e.pos).floor())
	var length := Vector2(tip - c0).length()
	v.clock = 0.0
	v._zones()  # 처음 본 때를 기억한다(아직 펼쳐지지 않아 그리지 않는다)
	v.clock = 1.0
	v.wipe()
	v._zones()
	var why := ""
	var long: Array = v.lines.filter(func(l): return _len(l) > length - 2.0).map(func(l): return l[2])
	var helix: Array = v.lines.filter(func(l): return _len(l) < 8.0).map(func(l): return l[2])
	if long.count(View.PX.lime1) != 2 or long.count(View.PX.soot) != 2:
		why = "바람의 길 긴 줄이 %s다(밝은 연두·어두운 경계 둘씩이어야 한다)" % [long]
	elif helix.size() < 2 * int(length / 3.0) - 2 or not helix.has(View.PX.lime1) or not helix.has(View.PX.lime3):
		why = "나선 마디가 %d개 · 색 %s다(두 가닥 %d개 넘게, 밝은·어두운 연두 둘 다)" % [helix.size(), helix.slice(0, 6), 2 * int(length / 3.0) - 2]
	elif v.pxs.is_empty() or v.pxs.any(func(p): return p[1] != View.PX.lime3):
		why = "바람의 길 칠이 %d점이다(연두 점이어야 한다)" % v.pxs.size()
	if why == "":
		why = _off_palette(_colors(v))
	if why == "":
		v.wipe()
		v._traces(true)
		if not v.lines.any(func(l): return l[1] == tip):
			why = "저격 줄 끝이 %s다(표적 %s에 닿아야 한다)" % [v.lines.map(func(l): return l[1]), tip]
	if why == "":
		v.wipe()
		v._snipe(c0, tip, 0.45, [])
		var marks: Array = v.lines.filter(func(l): return _len(l) <= 3.5 and Vector2(l[0] - tip).length() < 16.0)
		if marks.size() != 8 or v.lines.any(func(l): return _len(l) > 20.0):
			why = "0.45초 저격 흔적이 괄호 줄 %d개 · 긴 줄 %d개다(괄호 여덟, 긴 줄 없음)" % [marks.size(), v.lines.filter(func(l): return _len(l) > 20.0).size()]
	if why == "":
		v.wipe()
		v._snipe(c0, tip, View.SNIPE_MARK + 0.05, [])
		if not v.lines.is_empty():
			why = "SNIPE_MARK초 뒤에도 저격 흔적 줄 %d개가 남았다" % v.lines.size()
	v.free()
	return why

# I215 2026-11-01 변경: 순풍 장판은 밀도 1 연두 칠 위로 실비아 → 장판 쪽으로 흐르는 바람 줄(머리 밝음)과 판정 경계(밝은 연두 + 어두운)다
func test_tailwind_streaks_run_from_sylvia_toward_zone():
	var b = _pair()
	var s = b.heroes[1]
	b.zones = [{"src": "sylvia_w", "owner": s, "pos": Vector2(14, 16), "radius": 2.0, "left": 3.0}]
	var v = Rec.new()
	v.battle = b
	v._zones()
	v.clock = 1.0
	v.wipe()
	v._zones()
	var why := ""
	var runs: Array = v.lines.filter(func(l): return _len(l) >= 2.0)
	if runs.size() < 6 or runs.any(func(l): return absf(Vector2(l[1] - l[0]).normalized().cross(Vector2.DOWN)) > 0.2):
		why = "바람 줄 %d개가 실비아 → 장판(아래) 쪽이 아니다: %s" % [runs.size(), runs.slice(0, 4).map(func(l): return l[1] - l[0])]
	elif not runs.any(func(l): return l[2] == View.PX.lime0):
		why = "바람 줄 머리(밝은 연두)가 없다"
	elif v.edges != [[View.PX.lime1, View.PX.soot]] or v.noise.size() != 1 or v.noise[0][1] != 1:
		why = "경계 %s · 칠 %s다(밝은 연두·어두운 경계 하나, 밀도 1 칠 하나)" % [v.edges, v.noise]
	if why == "":
		why = _off_palette(_colors(v))
	v.free()
	return why

# S153·I215 2026-11-01 변경: 렌즈는 지점을 가운데로 실비아 → 지점에 수직인 길이 length 관문이다. 원 판정 경계는 없고,
# 관문 길이만큼 긴 양옆 경계 둘씩(밝은 연두 + 어두운)과 양 끝 바람 기둥 둘(어두운 테 5×9)을 그린다
func test_lens_is_gate_with_side_edges_and_posts():
	var b = _pair()
	var s = b.heroes[1]
	if not _ready_cast(b, s, "e", Vector2(14, 14)):
		return "실비아 E를 못 썼다"
	var z = b.zones.filter(func(x): return x.src == "sylvia_e")[0]
	var why := ""
	if not z.has("to") or absf(z.pos.distance_to(z.to) - s.e.length) > 0.01 or absf(z.to.y - z.pos.y) > 0.01 or absf((z.pos.x + z.to.x) / 2.0 - 14.0) > 0.01:
		why = "렌즈가 %s → %s다((14,14)를 가운데로 동서 길이 %s 관문이어야 한다)" % [z.pos, z.get("to"), s.e.length]
	var v = Rec.new()
	v.battle = b
	v._zones()
	v.clock = 1.0
	v.wipe()
	v._zones()
	var long: Array = v.lines.filter(func(l): return _len(l) > View.CELL * s.e.length - 2.0)
	var posts: Array = v.pxs.filter(func(p): return p[1] == View.PX.soot and p[2] == Vector2i(5, 9))
	if why == "" and (long.map(func(l): return l[2]).count(View.PX.lime0) != 2 or long.map(func(l): return l[2]).count(View.PX.soot) != 2 or long.any(func(l): return l[1].y != l[0].y)):
		why = "관문 긴 줄이 %s다(동서로 밝은 연두·어두운 둘씩)" % [long.map(func(l): return [l[0], l[1], l[2].to_html(false)])]
	elif why == "" and (posts.size() != 2 or not v.edges.is_empty() or not v.rings.is_empty()):
		why = "기둥 %d개 · 원 경계 %d · 고리 %d다(기둥 둘, 원 없음)" % [posts.size(), v.edges.size(), v.rings.size()]
	if why == "":
		why = _off_palette(_colors(v))
	v.free()
	return why

# 쏜 쪽·지난 바람만 가진 가짜 화살(_arrow_wind가 읽는 것만)
class Shot:
	var src
	var passed := []
	var aim := 0.0
	var lensed := false

# I215 2026-11-01 변경: 렌즈를 지난 화살은 촉이 2px 굵기 연두이고, 관문 경계에서 10px 안이면 촉 둘레 번쩍 고리(반지름 4)가 난다.
# 바람의 길을 지난 화살은 연두 꼬리를 달되, 쏜 자리 가까이에서는 꼬리를 내지 않는다
func test_lensed_arrow_bright_head_and_flash_near_gate():
	var b = _pair()
	var a = b.heroes[0]
	var v = Rec.new()
	v.battle = b
	var gate := {"src": "sylvia_e", "pos": Vector2(12, 14), "to": Vector2(16, 14), "radius": 0.25, "amp": 0.6}
	var m := Shot.new()
	m.src = a
	m.passed = [gate]
	m.lensed = true
	var why := ""
	v._arrow_wind(m, v._center(Vector2(14, 14)) + Vector2(0, 8), Vector2.DOWN)
	if v.lines.filter(func(l): return l[3] == 2).size() != 2 or not v.rings.any(func(r): return r[1] == 4):
		why = "관문을 막 지난 렌즈 화살이 굵은 줄 %d · 고리 %s다(굵은 줄 둘, 반지름 4 고리)" % [v.lines.filter(func(l): return l[3] == 2).size(), v.rings]
	v.wipe()
	v._arrow_wind(m, v._center(Vector2(14, 19)), Vector2.DOWN)
	if why == "" and (v.lines.filter(func(l): return l[3] == 2).size() != 2 or not v.rings.is_empty()):
		why = "관문에서 먼 렌즈 화살에 고리 %s가 있다" % [v.rings]
	m.lensed = false
	m.passed = [{"src": "sylvia_r"}]
	v.wipe()
	v._arrow_wind(m, v._muzzle(a) + Vector2(40, 0), Vector2.RIGHT)
	if why == "" and (v.lines.size() != 2 or v.lines.any(func(l): return l[3] != 1 or l[0].x < int(v._muzzle(a).x))):
		why = "바람의 길을 지난 화살 꼬리가 %s다(가는 줄 둘)" % [v.lines]
	v.wipe()
	v._arrow_wind(m, v._muzzle(a) + Vector2(5, 0), Vector2.RIGHT)
	if why == "" and not v.lines.is_empty():
		why = "쏜 자리 5px 앞 화살에 꼬리 %s가 있다" % [v.lines]
	v.free()
	return why

# I215 2026-11-01 변경: 순풍(sylvia_w)에서 온 공격 속도는 발 둘레 바람 줄 조각(gust) 하나이고 금·주황 사각형이 없다. 다른 공격 속도가 함께면 사각형도 그린다
func test_tailwind_haste_is_wind_at_feet_and_other_haste_keeps_squares():
	var b = _pair()
	var a = b.heroes[0]
	var v = Rec.new()
	v.battle = b
	var feet: Vector2i = Vector2i((v._spot(a) + v._slip(a)).floor())
	b._fx(a, "sylvia_w", {"haste": 0.3}, 3.0)
	var sq := func(ms: Array): return ms.filter(func(x): return x.k == "px" and (x.c == View.PX.gold or x.c == View.PX.orange)).size()
	var marks: Array = v.status_marks(a, true)
	var gust: Array = marks.filter(func(x): return x.k == "gust")
	var why := ""
	if gust.size() != 1 or absi(gust[0].p.y - feet.y) > 2 or sq.call(marks) != 0:
		why = "순풍 공격 속도가 바람 줄 %s · 사각형 %d다(발밑 바람 줄 하나, 사각형 없음)" % [gust.map(func(x): return x.p), sq.call(marks)]
	b._fx(a, "chronos_q", {"haste": 0.2}, 3.0)
	marks = v.status_marks(a, true)
	if why == "" and (marks.filter(func(x): return x.k == "gust").size() != 1 or sq.call(marks) != 3):
		why = "순풍 + 다른 공격 속도가 바람 줄 %d · 사각형 %d다(하나 · 셋)" % [marks.filter(func(x): return x.k == "gust").size(), sq.call(marks)]
	v.free()
	return why

# I215 2026-11-01 변경: 저격 표적이 화면 밖이면 SNIPE_MARK초 동안 화면 가장자리(SNIPE_EDGE 안쪽)에 표적 쪽 꺾쇠 둘(어두운 3px 테 + 연두)을 그린다.
# 표적이 화면 안이거나 시간이 지나면 그리지 않는다
func test_snipe_pointer_only_while_target_off_screen():
	var b = _pair()
	var s = b.heroes[1]
	var e = b.spawn_enemy("basic", Vector2i(24, 10), {"speed": 0, "sight": 0, "damage": 0, "hp": 1e9})
	var v = Rec.new()
	v.battle = b
	if not _ready_cast(b, s, "r"):
		v.free()
		return "실비아 R을 못 썼다"
	var c0: Vector2 = v._center(s.pos)
	v.shown = Rect2(c0 - Vector2(80, 80), Vector2(160, 160))  # 표적(오른쪽 160px)은 밖
	v._snipe_pointers()
	var why := ""
	var thick: Array = v.lines.filter(func(l): return l[3] == 3 and l[2] == View.PX.soot)
	var right: float = v.shown.end.x - View.SNIPE_EDGE
	if thick.size() != 4 or v.lines.size() != 8 or v.lines.any(func(l): return l[1].x > right + 0.5 or l[1].x < right - 7.0):
		why = "화면 밖 표적 꺾쇠가 줄 %d(테 %d)개 · 끝 %s다(줄 여덟·테 넷, 오른쪽 가장자리 %s 안쪽)" % [v.lines.size(), thick.size(), v.lines.map(func(l): return l[1]), right]
	v.wipe()
	v.shown = Rect2(c0 - Vector2(80, 80), Vector2(400, 160))
	v._snipe_pointers()
	if why == "" and not v.lines.is_empty():
		why = "표적이 화면 안인데 꺾쇠 %d줄을 그렸다" % v.lines.size()
	v.wipe()
	v.shown = Rect2(c0 - Vector2(80, 80), Vector2(160, 160))
	b.traces[0].age = View.SNIPE_MARK + 0.01
	v._snipe_pointers()
	if why == "" and not v.lines.is_empty():
		why = "SNIPE_MARK초 뒤에도 꺾쇠 %d줄이 남았다" % v.lines.size()
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

# 기록 화면이 모은 색 전부(줄·호·고리·칸·성긴 칠·원판·경계)
func _colors(v) -> Array:
	var out: Array = v.lines.map(func(l): return l[2]) + v.arcs.map(func(a): return a[4]) + v.rings.map(func(r): return r[3]) + v.pxs.map(func(p): return p[1]) + v.fills + v.discs.map(func(d): return d[2])
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

# I227 ①: 빛 구슬이 한 마디씩 건너가며 줄을 남기고, 먼저 지난 마디가 먼저 식는다
func test_holy_beam_orb_hops_in_order_and_older_hops_cool_first():
	var b = _duo()
	var s = b.heroes[0]
	var ally = b.heroes[1]
	var e = _target(b, Vector2i(12, 12))
	var hits := [ally, e, s]
	var v = Rec.new()
	v.battle = b
	var hop: float = View.beam_hop(hits.size())
	var to := [Vector2i(v._chest(ally).floor()), Vector2i(v._chest(e).floor()), Vector2i(v._chest(s).floor())]
	var why := ""
	if not is_equal_approx(hop, View.BEAM_HOP):
		why = "세 마디의 한 마디 시간이 %.3f초다(BEAM_HOP여야 한다)" % hop
	v._beam(s, hits, hop * 0.5)
	var ends: Array = v.lines.map(func(l): return l[1])
	var orb: Array = v.discs.filter(func(d): return d[2] == View.PX.cream and d[1] == 2)
	var pieces: Array = v.spr.filter(func(q): return q[0] != "ring")  # Rec는 고리도 spr에 적는다
	if why == "" and (v.lines.is_empty() or ends.has(to[0]) or not pieces.is_empty()):
		why = "첫 마디를 반쯤 건넜을 때 줄 끝이 %s · 조각 %s다(첫 대상에 아직 닿지 않아야 한다)" % [ends, pieces]
	elif why == "" and (orb.size() != 1 or not ends.has(orb[0][0]) or not v.rings.any(func(r): return r[0] == orb[0][0] and r[1] == 3 and r[3] == View.PX.gold)):
		why = "건너는 중 줄 끝에 빛 구슬(크림 원판 2 + 금 고리 3)이 없다: 원판 %s · 고리 %s" % [v.discs, v.rings]
	v.wipe()
	v._beam(s, hits, hop * 2.5)
	ends = v.lines.map(func(l): return l[1])
	var names: Array = v.spr.map(func(x): return x[0])
	if why == "" and (not ends.has(to[0]) or not ends.has(to[1]) or ends.has(to[2])):
		why = "2.5마디 뒤 줄 끝이 %s다(아군 → 적까지 닿고 셋째 대상에는 아직이어야 한다)" % [ends]
	elif why == "" and not v.lines.any(func(l): return l[0] == to[0] and l[1] == to[1]):
		why = "둘째 마디가 첫 대상에서 시작하지 않는다: %s" % [v.lines]
	elif why == "" and not names.has("mend"):
		why = "닿은 아군에 회복 반짝이 없다: %s" % [names]
	elif why == "" and v.lines.filter(func(l): return l[2] == View.PX.cream and l[3] == 1 and l[0].distance_to(to[1]) <= 6 and l[0].distance_to(to[1]) >= 1).size() < 8:
		why = "닿은 적 둘레에 크림 빛살 여덟이 없다"
	v.wipe()
	v._beam(s, hits, hop * 3.0 + 0.05)  # 셋 다 그어진 뒤: 첫 마디는 0.21초, 셋째 마디는 0.05초 식었다
	var first: Array = v.lines.filter(func(l): return l[1] == to[0] and l[2] != View.PX.cream)
	var last: Array = v.lines.filter(func(l): return l[1] == to[2] and l[2] != View.PX.cream)
	if why == "" and (first.size() != 1 or last.size() != 1):
		why = "다 그은 뒤 마디 줄이 첫 %s · 셋째 %s다" % [first, last]
	elif why == "" and not (first[0][3] < last[0][3] and first[0][2] != View.PX.gold and last[0][2] == View.PX.gold):
		why = "먼저 지난 마디가 먼저 식지 않았다: 첫 %s · 셋째 %s(첫 마디가 더 가늘고 금이 아니어야 한다)" % [first[0], last[0]]
	elif why == "" and v.discs.filter(func(d): return d[0] == to[2]).is_empty():
		why = "마지막 대상에 닿은 구슬이 ORB_FADE초 동안 남지 않는다"
	v.free()
	return why

# I227 ①: 마디 수 × 한 마디가 BEAM_SPAN을 넘으면 나눠, 14마디(성역 공명)도 흔적 수명(1초) 안에 다 식는다
func test_long_holy_beam_fits_in_span_and_cools_before_trace_ends():
	var b = _duo()
	var s = b.heroes[0]
	var ally = b.heroes[1]
	var e = _target(b, Vector2i(12, 12))
	var long := []
	for i in 7:
		long.append_array([ally, e])
	var v = Rec.new()
	v.battle = b
	var why := ""
	var hop: float = View.beam_hop(long.size())
	if not is_equal_approx(hop * long.size(), View.BEAM_SPAN):
		why = "14마디가 %.3f초에 다 건넌다(BEAM_SPAN %.2f초여야 한다)" % [hop * long.size(), View.BEAM_SPAN]
	elif View.BEAM_SPAN + View.BEAM_COOL >= 1.0:
		why = "BEAM_SPAN + BEAM_COOL이 흔적 수명 1초를 넘는다"
	v._beam(s, long, long.size() * hop)
	var last := Vector2i(v._chest(e).floor())
	if why == "" and not v.rings.any(func(r): return r[0] == last and r[1] == 3):
		why = "14마디가 다 건넌 순간 빛 구슬이 마지막 대상 %s에 없다: %s" % [last, v.rings.map(func(r): return r[0])]
	v.wipe()
	v._beam(s, long, long.size() * hop + View.BEAM_COOL)
	if why == "" and not v.lines.is_empty():
		why = "14마디가 다 건너고 BEAM_COOL이 지나도 줄을 그린다"
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

# 끊긴 고리 sg(Rec.segs 한 줄)가 그린 칸(I226 ①·④): 고리 칸의 10~90%만 그렸고(끊김), 바깥 검정 1px 칸마다 같은 각(±1.5px)에 고리 칸이 있다. 맞으면 ""
func _broken(v, sg: Array) -> String:
	var c: Vector2i = sg[0]
	var r: int = sg[1]
	var main: Array = v.pxs.filter(func(p): return p[1] == sg[3] and p[2] == Vector2i.ONE and absf(Vector2(p[0] - c).length() - r) <= sg[2] + 1).map(func(p): return Vector2(p[0] - c))
	var rim: Array = v.pxs.filter(func(p): return p[1] == View.PX.night and p[2] == Vector2i.ONE and absf(Vector2(p[0] - c).length() - r - 0.5) < 1.5).map(func(p): return Vector2(p[0] - c))
	var all: int = v.px_cells(r, sg[2]).size()
	if main.size() < all * 0.1 or main.size() > all * 0.9:
		return "고리 칸 %d/%d를 그렸다(끊겨야 한다)" % [main.size(), all]
	if rim.is_empty():
		return "바깥 검정이 없다"
	for q in rim:
		if not main.any(func(m): return absf(angle_difference(m.angle(), q.angle())) * r <= 1.5):
			return "바깥 검정 %s 둘레에 고리 칸이 없다(같은 각에서 끊겨야 한다)" % [q]
	return ""

func test_enfeeble_dark_ring_closes_inward_with_wisps_and_marks_cursed_heads():
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
	var shade: Array = ["soot", "dark", "smoke"].map(func(n): return View.PX[n])
	var why := ""
	var main0 := []
	var spins := []
	for t in [0.01, View.HEX_CLOSE * 0.9]:
		v.wipe()
		v._hex(c, rad, t, 7)
		var sg: Array = v.segs
		var wisps: Array = v.pxs.filter(func(p): return p[1] == View.PX.night and p[2] == Vector2i(2, 2))
		if sg.size() != 1 or not sg[0][3] in shade or sg[0][4] != View.HEX_SEGS or sg[0][6] < 0 or not v.rings.is_empty():
			why = "%.2f초 고리가 끊긴 고리 %s · 이은 고리 %s다(그림자 색, %d마디 들쭉날쭉한 연기 테두리 하나여야 한다)" % [t, sg, v.rings, View.HEX_SEGS]
		elif wisps.size() != View.HEX_WISPS:
			why = "%.2f초 검은 연기 가닥이 %d개다(%d개여야 한다)" % [t, wisps.size(), View.HEX_WISPS]
		elif _colors(v).any(func(col): return col in [View.PX.teal, View.PX.midteal, View.PX.deepteal]):
			why = "%.2f초 저주 흔적에 청록이 있다(독안개와 같은 색이라 묻힌다)" % t
		else:
			why = _broken(v, sg[0])
		if why != "":
			break
		main0.append(sg[0][1])
		spins.append(sg[0][5])
	if why == "" and (main0[0] < int(rad * 0.9) or main0[1] >= main0[0] or main0[1] < int(rad * 0.6)):
		why = "고리 반지름이 %s다(반경에서 0.6배까지 조여들어야 한다)" % [main0]
	elif why == "" and spins[1] >= spins[0]:
		why = "조여드는 동안 고리가 반시계로 돌지 않는다: 돌림 %s" % [spins]
	var hx: Array = v.spr.filter(func(q): return q[0] == "hex")
	if why == "" and (hx.size() != 1 or hx[0][2].y >= int(v._spot(e).y - v._head(e))):
		why = "저주 문양이 %s다(걸린 적 머리 위에 하나여야 한다)" % [hx]
	v.free()
	return why

# 영혼 사슬 셋: 처음 적 a(13, 13)·b(17, 13)를 먼저 세우고 E 대상 hub(15, 14)에 E를 쓴다. 돌려주는 것: [판, hub, a, b]
func _chained() -> Array:
	var b = _duo()
	var a = _target(b, Vector2i(13, 13))
	var c = _target(b, Vector2i(17, 13))
	var hub = _target(b, Vector2i(15, 14))
	_ready_cast(b, b.heroes[1], "e", hub)
	b.step(1.0 / 60.0)
	return [b, hub, a, c]

# 줄 p → q 가운데 둘레(±1px)에 그려진 칸이 있다
func _near_mid(v, p: Vector2, q: Vector2) -> bool:
	var m := Vector2i(((p + q) / 2.0).floor())
	return v.pxs.any(func(x): return absi(x[0].x - m.x) <= 1 and absi(x[0].y - m.y) <= 1)

func test_soul_chain_is_iron_links_tree_from_target():
	var bt := _chained()
	var b = bt[0]
	var hub = bt[1]
	var a = bt[2]
	var c = bt[3]
	if not [hub, a, c].all(func(x): return x.fx.has("vesper_e")) or hub.fx.vesper_e.get("hub") != hub or a.fx.vesper_e.get("hub") != hub:
		return "셋이 E 대상을 적어 둔 사슬에 묶이지 않았다"
	var v = Rec.new()
	v.battle = b
	v._foes = b.enemies
	v._traces(true)
	var why := ""
	var to := Vector2i(v._chest(hub).floor())
	if not v.lines.any(func(l): return l[1] == to and l[2] in [View.PX.teal, View.PX.midteal, View.PX.deepteal]):
		why = "베스퍼에서 대상까지 청록 줄이 없다: %s" % [v.lines]
	elif v.rings.size() != 1:
		why = "대상 둘레 고리가 %d개다(하나여야 한다)" % v.rings.size()
	elif v.spr.any(func(q): return q[0] == "link"):
		why = "옛 청록 고리 조각으로 잇는다"
	if why == "":
		v.wipe()
		b.traces.clear()
		v._traces(true)
		var body: Array = v.pxs.filter(func(p): return p[1] in [View.PX.cream, View.PX.ash])
		if body.is_empty() or not body.all(func(p): return p[2] == Vector2i(2, 1)):
			why = "사슬 몸이 %s다(굵기 2의 크림·재 칸이어야 한다)" % [body.map(func(p): return [p[1].to_html(false), p[2]])]
		elif body.filter(func(p): return p[1] == View.PX.cream).size() * 3 > body.size():
			why = "크림 반짝이 너무 많다(4px마다 하나)"
		elif not (_near_mid(v, v._chest(hub), v._chest(a)) and _near_mid(v, v._chest(hub), v._chest(c))):
			why = "E 대상에서 두 적으로 가는 사슬이 없다"
		elif _near_mid(v, v._chest(a), v._chest(c)):
			why = "처음 적 a에서 b로 잇는다(E 대상에서 시작하는 나무여야 한다)"
	if why == "":
		v._foes = b.enemies.filter(func(x): return x != hub)  # E 대상이 숨으면 남은 적 가운데 처음 적에서 시작한다
		v.wipe()
		v._traces(true)
		if not _near_mid(v, v._chest(a), v._chest(c)):
			why = "E 대상이 없을 때 남은 둘을 잇지 않는다"
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
	var mid := Vector2i(v._center(Vector2(12, 12)).floor())
	if why == "" and (v.rings.size() != View.BOG_WAVES or v.rings.any(func(r): return r[0] != mid or r[2] != 1 or r[4] != View.BOG_DASH) or not v.lines.is_empty() or _colors(v).any(func(c): return c in vio)):
		why = "늪이 물결 %s · 줄 %d · 색 %s다(가운데서 퍼지는 1px 물결 %d, %dpx마다 끊긴 점선, 물결 가로줄 없음, 보라 없음이어야 한다)" % [v.rings.map(func(r): return [r[0], r[1], r[2], r[4]]), v.lines.size(), _colors(v), View.BOG_WAVES, View.BOG_DASH]
	elif why == "" and not (View.PX.deepteal in v.fills and View.PX.dark in v.fills and View.PX.soot in v.fills):
		why = "늪 칠이 %s다(진흙 어둠·그을음과 깊은 청록 물이어야 한다)" % [v.fills.map(func(c): return c.to_html(false))]
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

# ── fx-4: 크로노스·보스 예고·조준 미리보기 ──

# 크로노스(Q 자동 시전 끔)와 아이아스, 그 위쪽에 다 지은 궁수탑 하나, 판이 끝나지 않게 멀리 선 과녁 하나. 돌려주는 것: [판, 궁수탑]
func _chrono() -> Array:
	var b = Battle.new({"size": Vector2i(30, 30), "base": Vector2i(28, 28), "base_hp": 100, "spawns": [Vector2i(0, 20)],
		"heroes": [{"kind": "chronos", "cell": Vector2i(10, 10)}, {"kind": "aias", "cell": Vector2i(14, 10)}], "waves": [[{"kind": "basic", "count": 1}]]})
	b.gold = 9999
	var tower = b.build("tower", Vector2i(12, 7))
	b.start_battle()
	b._queue = []
	b.heroes[0].auto = false
	_target(b, Vector2i(24, 24))
	return [b, tower]

func test_fx4_pieces_in_atlas():
	for name in ["charge", "back", "hub"]:
		if not View.FX_ART.has(name):
			return "이펙트 아틀라스에 %s 조각이 없다" % name
	return ""

func test_overcharge_gold_line_and_bolt_on_hero_and_tower():
	var bt := _chrono()
	var b = bt[0]
	if bt[1] == null or not bt[1].complete:
		return "궁수탑을 못 지었다"
	var ch = b.heroes[0]
	var gold := [View.PX.gold, View.PX.tan, View.PX.bronze]
	var v = Rec.new()
	v.battle = b
	var why := ""
	for x in [b.heroes[1], bt[1]]:
		if not _ready_cast(b, ch, "q", x):
			why = "크로노스 Q를 %s에 못 썼다" % x.kind
			break
		b.step(1.0 / 60.0)
		v.wipe()
		v._traces(true)  # 구조물 대상이면 몸 높이(_head)를 쓰지 않아야 오류 없이 그린다
		var to := Vector2i(v._muzzle(x).floor())
		var bolt: Array = v.spr.filter(func(q): return q[0] == "charge")
		if not v.lines.any(func(l): return l[1] == to and l[2] in gold):
			why = "크로노스에서 %s 쏘는 곳 %s까지 금 줄이 없다: %s" % [x.kind, to, v.lines]
		elif bolt.size() != 1 or bolt[0][2] != to:
			why = "%s 쏘는 곳 %s의 번개 조각이 %s다(하나여야 한다)" % [x.kind, to, bolt]
		elif v.rings.size() != 1:
			why = "%s 둘레 고리가 %d개다(하나여야 한다)" % [x.kind, v.rings.size()]
		if why != "":
			break
		b.traces.clear()
	v.free()
	return why

# ── fx-7: 크로노스 새 칸(I199 2026-11-04 변경) ──

# 발 자리(아트 px). 머리 위 표시는 여기서 _head만큼 위다
func _feet_px(v, x) -> Vector2i:
	return Vector2i((v._spot(x) + v._slip(x)).floor())

func test_aging_is_clockwise_dashed_sand_rim_with_hourglass_over_aged_foes():
	var b = _chrono()[0]
	var ch = b.heroes[0]
	var aged = _target(b, Vector2i(12, 15))
	var plain = _target(b, Vector2i(13, 13))
	b._fx(aged, "chronos_w", {"weaken": 0.1, "dot": 0.0}, 2.0)
	b.traces = [{"hero": ch, "slot": "w", "aim": Vector2(12, 14), "at": Vector2(12, 14), "radius": 2.0, "hits": [], "marked": true, "age": 0.0}]
	var v = Rec.new()
	v.battle = b
	var sand := [View.PX.cream, View.PX.tan, View.PX.ash]
	var why := ""
	var spins := []
	for t in [0.05, 0.25]:
		b.traces[0].age = t
		v._foes = []
		v.wipe()
		v._traces(true)
		var rim: Array = v.rings.filter(func(r): return r[4] > 0)
		var grains: Array = v.pxs.filter(func(p): return p[2] == Vector2i.ONE and p[1].a == 1.0 and p[1] in sand)
		if v.rings.size() != 1 or rim.size() != 1 or rim[0][1] != int(View.CELL * 2.0) or not (rim[0][3] in sand):
			why = "노화 %.2f초 고리가 %s다(반경 자리 모래빛 점선 테 하나여야 한다)" % [t, v.rings.map(func(r): return [r[1], r[3].to_html(false), r[4]])]
		elif grains.size() != 16:
			why = "노화 %.2f초 모래알이 %d개다(16개여야 한다)" % [t, grains.size()]
		if why != "":
			break
		spins.append(rim[0][5])
		v._foes = [aged, plain]
		v.wipe()
		v._traces(true)
		for x in [aged, plain]:
			var feet := _feet_px(v, x)
			var glass: bool = v.pxs.any(func(p): return p[2] == Vector2i(5, 1) and p[0].x + 2 == feet.x and p[0].y < feet.y - int(v._head(x)))
			if glass != (x == aged):
				why = "노화 %.2f초 %s 머리 위 모래시계가 %s다(노화 걸린 적에만 있어야 한다)" % [t, "걸린 적" if x == aged else "안 걸린 적", glass]
		if why != "":
			break
	if why == "" and spins[1] <= spins[0]:
		why = "점선 테 돌림이 %.2f → %.2f다(시계 방향으로 돌아야 한다)" % spins
	if why == "" and _off_palette(_colors(v)) != "":
		why = "노화 흔적에 팔레트 밖 색 %s가 있다" % _off_palette(_colors(v))
	v.free()
	return why

func test_loop_shock_closes_counterclockwise_then_flashes_with_afterimages_from_old_spot():
	var b = _chrono()[0]
	var ch = b.heroes[0]
	var e = _target(b, Vector2i(12, 14))
	b.traces = [{"hero": ch, "slot": "loop", "aim": Vector2(12, 8), "at": Vector2(12, 14), "radius": 1.5, "hits": [e], "marked": false, "age": 0.0, "foe": e, "aged": false}]
	var v = Rec.new()
	v.battle = b
	v._foes = [e]
	var ice := [View.PX.ice0, View.PX.ice1, View.PX.ice2]
	var r0 := int(View.CELL * 1.5)
	var why := ""
	var seen := []
	for t in [0.02, 0.15]:
		b.traces[0].age = t
		v.wipe()
		v._traces(true)
		if v.rings.size() != 1 or v.rings[0][4] == 0 or not (v.rings[0][3] in ice):
			why = "되돌림 %.2f초 고리가 %s다(얼음 점선 고리 하나여야 한다)" % [t, v.rings.map(func(r): return [r[1], r[3].to_html(false), r[4]])]
			break
		seen.append(v.rings[0])
	if why == "" and not (seen[1][1] < seen[0][1] and seen[0][1] <= r0 and seen[1][5] < seen[0][5]):
		why = "되돌림 고리가 반지름 %d → %d · 돌림 %.2f → %.2f다(반경 %d에서 안으로 조여들며 반시계로 돌아야 한다)" % [seen[0][1], seen[1][1], seen[0][5], seen[1][5], r0]
	if why == "":
		b.traces[0].age = 0.24
		v.wipe()
		v._traces(true)
		if not v.rings.is_empty() or not v.discs.any(func(d): return d[1] == 3 and d[2] == View.PX.ice0):
			why = "되돌림 0.24초가 고리 %d · 원판 %s다(조여든 뒤 가운데 얼음 번쩍만 있어야 한다)" % [v.rings.size(), v.discs]
	if why == "":
		var counts := []
		var tops := []
		for t in [0.1, 0.25]:  # 잔상(몸통 아래 층): 옛 자리 (12, 8) 쪽부터 사라진다
			b.traces[0].age = t
			v.wipe()
			v._traces(false)
			var ghosts: Array = v.pxs.filter(func(p): return p[2].x == 3 and p[1] in [View.PX.ice1, View.PX.ice2, View.PX.ice3])
			counts.append(ghosts.size())
			tops.append(ghosts.map(func(p): return p[0].y).min() if not ghosts.is_empty() else 0)
		if counts != [4, 2] or tops[1] <= tops[0]:
			why = "잔상이 %s개 · 맨 위 y %s다(넷이었다가 옛 자리 쪽부터 둘이 사라져야 한다)" % [counts, tops]
	if why == "":
		var gold := [View.PX.cream, View.PX.gold, View.PX.tan]
		for aged in [false, true]:  # 노화 되감기(S266)로 피해가 커졌으면 조여든 뒤 금 고리가 반경 너머로 터진다
			b.traces[0].aged = aged
			var rs := []
			for t in [0.25, 0.39]:
				b.traces[0].age = t
				v.wipe()
				v._traces(true)
				var burst: Array = v.rings.filter(func(r): return r[3] in gold and r[4] == 0)
				rs.append(burst[0][1] if burst.size() == 1 else -1)
			if not aged and rs != [-1, -1]:
				why = "노화 되감기가 아닌데 금 고리 %s가 있다" % [rs]
			elif aged and not (rs[0] > int(r0 * 0.25) and rs[1] > rs[0] and rs[1] > r0):
				why = "노화 되감기 금 고리 반지름이 %s다(반경의 0.25배에서 반경 너머로 터져야 한다)" % [rs]
			if why != "":
				break
	if why == "" and _off_palette(_colors(v)) != "":
		why = "되돌림 흔적에 팔레트 밖 색 %s가 있다" % _off_palette(_colors(v))
	v.free()
	return why

func test_time_gate_is_counterclockwise_ice_hands_with_four_ticks():
	var v = _zone_draw("chronos_e")
	var c := Vector2i(v._center(Vector2(12, 12)).floor())
	var why := ""
	var ice := [View.PX.ice0, View.PX.ice1, View.PX.ice2, View.PX.ice3, View.PX.ice4]
	var long0 = null
	for l in v.lines:
		if l[0] == c and l[3] == 1 and l[2] == View.PX.cream:
			long0 = l[1]
	var hands: Array = v.lines.filter(func(l): return l[0] == c)
	var ticks: Array = v.lines.filter(func(l): return l[0] != c)
	if hands.size() != 2 or ticks.size() != 4 or long0 == null or not ticks.all(func(l): return l[2] in ice):
		why = "시간의 문 줄이 %s다(가운데 바늘 둘 · 얼음 눈금 넷이어야 한다)" % [v.lines.map(func(l): return [l[0], l[1], l[2].to_html(false), l[3]])]
	elif v.fills.size() != 1 or not (v.fills[0] in ice) or v.noise[0][1] != 2:
		why = "칠이 %s · %s다(얼음 성긴 칠 2/16이어야 한다)" % [v.fills, v.noise]
	elif v.edges != [[View.PX.ice0, View.PX.night]]:
		why = "경계가 %s다(얼음 밝은 1px + 어두운 1px이어야 한다)" % [v.edges]
	elif not v.pxs.any(func(p): return p[0] == c - Vector2i(1, 1) and p[2] == Vector2i(3, 3) and p[1] == View.PX.night):
		why = "가운데 축(어두운 3×3px)이 없다"
	if why == "":
		v.clock = 1.2
		v.wipe()
		v._zones()
		var long1 = null
		for l in v.lines:
			if l[0] == c and l[3] == 1 and l[2] == View.PX.cream:
				long1 = l[1]
		# 화면 y가 아래라 각이 줄면 반시계 방향
		if long1 == null or angle_difference(Vector2(long0 - c).angle(), Vector2(long1 - c).angle()) >= 0.0:
			why = "긴 바늘 끝이 %s → %s다(반시계 방향으로 돌아야 한다)" % [long0, long1]
	v.free()
	return why

# 태엽 감기 둘레를 clock초에 그려 첫 톱니(금 2×2px)의 각을 잰다. 톱니가 없으면 NAN
func _tooth_angle(v, c: Vector2i, at: float) -> float:
	v.clock = at
	v.wipe()
	v._zones()
	var teeth: Array = v.pxs.filter(func(p): return p[2] == Vector2i(2, 2) and p[1] == View.PX.gold)
	return Vector2(teeth[0][0] - c).angle() if not teeth.is_empty() else NAN

func test_wind_up_is_gold_rim_with_clockwise_teeth_and_thin_fill():
	var v = _zone_draw("chronos_r")
	var c := Vector2i(v._center(Vector2(12, 12)).floor())
	var why := ""
	var teeth: Array = v.pxs.filter(func(p): return p[2] == Vector2i(2, 2) and p[1] == View.PX.gold)
	var shades: Array = v.pxs.filter(func(p): return p[2] == Vector2i(3, 3) and p[1] == View.PX.soot)
	if teeth.size() != 28 or shades.size() != 28:
		why = "톱니가 금 %d · 그림자 %d다(28개씩이어야 한다)" % [teeth.size(), shades.size()]
	elif v.rings.any(func(r): return r[4] > 0) or not v.lines.is_empty():
		why = "점선 고리 %d · 줄 %d가 있다(안쪽 점선 고리와 눈금이 없어야 한다)" % [v.rings.filter(func(r): return r[4] > 0).size(), v.lines.size()]
	elif v.edges != [[View.PX.gold, View.PX.soot]]:
		why = "경계가 %s다(금 밝은 1px + 어두운 1px이어야 한다)" % [v.edges]
	elif v.noise.any(func(n): return n[1] > 1):
		why = "칠 밀도가 %s다(1/16 이하여야 한다)" % [v.noise]
	if why == "":
		# 화면 y가 아래라 각이 늘면 시계 방향. 쓴 순간부터 0.6초는 빨리 돈다(_zone_draw는 0초에 처음 봤다)
		var burst := angle_difference(_tooth_angle(v, c, 0.1), _tooth_angle(v, c, 0.3))
		var steady := angle_difference(_tooth_angle(v, c, 1.0), _tooth_angle(v, c, 1.5))
		if steady <= 0.0 or burst <= steady:
			why = "톱니가 처음 0.2초에 %.3f · 1초 뒤 0.5초에 %.3f rad 돌았다(시계 방향으로, 처음에 더 빨리 돌아야 한다)" % [burst, steady]
	v.free()
	return why

func test_time_gate_foes_show_return_timer_over_head_and_dim_dashes_to_return_spot():
	var b = _chrono()[0]
	var ch = b.heroes[0]
	var e = _target(b, Vector2i(12, 14))
	var delay: float = ch.e.delay
	var back := Vector2(12, 10)
	b.loops = [{"e": e, "at": back, "wall": false, "left": delay, "owner": ch, "blast": 1.5, "damage": 0.0, "aged": 1.0}]
	var v = Rec.new()
	v.battle = b
	v._foes = [e]
	var feet := _feet_px(v, e)
	var why := ""
	for k in [0.75, 0.25]:
		b.loops[0].left = delay * k
		v.wipe()
		v._chrono_marks()
		var disc: Array = v.discs.filter(func(d): return d[1] == 3 and d[2] == View.PX.night)
		if disc.size() != 1 or disc[0][0].x != feet.x or disc[0][0].y + 3 >= feet.y - int(v._head(e)):
			why = "남은 시간 %.2f 원판이 %s다(발 %s 머리 바로 위에 하나여야 한다)" % [k, disc, feet]
		elif v.arcs.size() != 1 or v.arcs[0][4] != View.PX.ice0 or absf(v.arcs[0][3] - v.arcs[0][2] - TAU * k) > 0.01 or absf(v.arcs[0][3] + PI / 2.0) > 0.01:
			why = "남은 시간 %.2f 호가 %s다(12시에서 반시계로 비율만큼인 얼음 호여야 한다)" % [k, v.arcs]
		if why != "":
			break
	if why == "":
		for left in [0.45, 0.35]:  # 마지막 0.5초는 0.2초마다 0.1초씩 꺼진다
			b.loops[0].left = left
			v.wipe()
			v._chrono_marks()
			if v.discs.is_empty() != (left == 0.45):
				why = "남은 %.2f초에 고리가 %s다(마지막 0.5초는 깜박여야 한다)" % [left, "없다" if v.discs.is_empty() else "있다"]
				break
	if why == "":
		b.loops[0].left = 1.0
		v.wipe()
		v._traces(false)
		var anchor := Vector2i(v._center(back).floor())
		var dashes: Array = v.pxs.filter(func(p): return p[1] == View.PX.ice3 and p[2] == Vector2i.ONE)
		if not v.rings.any(func(r): return r[0] == anchor and r[1] == 3 and r[3] == View.PX.ice1) or not v.pxs.any(func(p): return p[0] == anchor and p[1] == View.PX.ice0):
			why = "되돌아갈 자리 %s 점이 없다: %s" % [anchor, v.rings]
		var box := Rect2i(anchor, Vector2i.ZERO).expand(feet).grow(1)
		if why == "" and (dashes.size() < 4 or not dashes.all(func(p): return box.has_point(p[0]))):
			why = "적 %s → 되돌아갈 자리 %s 흐린 점선이 %s다" % [feet, anchor, dashes.map(func(p): return p[0])]
	if why == "":
		v._foes = []  # 숨은 적(S213)에는 그리지 않는다
		v.wipe()
		v._chrono_marks()
		v._traces(false)
		if not v.discs.is_empty() or not v.rings.is_empty():
			why = "숨은 적에도 남은 시간 고리 %d · 자리 점 %d가 있다" % [v.discs.size(), v.rings.size()]
	v.free()
	return why

func test_wind_up_allies_show_flipping_wind_key_with_dark_outline():
	var bt := _chrono()
	var b = bt[0]
	var a = b.heroes[1]
	var tower = bt[1]
	if tower == null or not tower.complete:
		return "궁수탑을 못 지었다"
	b._fx(a, "chronos_r", {"cdr": 0.5}, 2.0)
	b._fx(tower, "chronos_r", {"haste": 0.5}, 2.0)
	b._fx(b.enemies[0], "chronos_r", {"slow": 0.3}, 2.0)  # 적도 같은 이름 효과(둔화)라 열쇠가 없어야 한다
	var v = Rec.new()
	v.battle = b
	v._foes = b.enemies.duplicate()
	var hero_feet := _feet_px(v, a)
	var spots := [hero_feet + Vector2i(6, -int(v._head(a) * 0.6)), Vector2i(v._muzzle(tower).floor()) + Vector2i(7, 3)]
	var why := ""
	for pose in [[0.0, Vector2i(9, 5)], [0.12, Vector2i(5, 5)]]:  # 정면은 손잡이 7×3 + 테두리, 옆은 3×3 + 테두리
		v.clock = pose[0]
		v.wipe()
		v._chrono_marks()
		var rims: Array = v.pxs.filter(func(p): return p[1] == View.PX.night and p[2] == pose[1])
		for s in spots:
			if not rims.any(func(p): return p[0] == s + Vector2i(-pose[1].x / 2, -6)):
				why = "%.2f초 열쇠 자리 %s에 어두운 테두리 %s가 없다: %s" % [pose[0], s, pose[1], rims.map(func(p): return p[0])]
			elif not v.pxs.any(func(p): return p[1] == View.PX.gold and p[0].y < s.y - 2 and absi(p[0].x - s.x) <= 3):
				why = "%.2f초 열쇠 자리 %s에 금 손잡이가 없다" % [pose[0], s]
		if why == "" and rims.size() != 2:
			why = "%.2f초 열쇠가 %d개다(둘레 안 아군 영웅 하나 · 탑 하나여야 한다)" % [pose[0], rims.size()]
		if why != "":
			break
	if why == "" and _off_palette(_colors(v)) != "":
		why = "태엽 열쇠에 팔레트 밖 색 %s가 있다" % _off_palette(_colors(v))
	v.free()
	return why

func test_boss_tell_two_tone_edge_and_fill_grows_then_flash_disc():
	var b = _duo()
	var boss = b.spawn_enemy("boss", Vector2i(12, 13), {"speed": 0, "sight": 0, "damage": 0})
	var sk: Dictionary = boss.skills.slam
	var v = Rec.new()
	v.battle = b
	v._foes = [boss]
	var radii := []
	var why := ""
	for left in [sk.windup * 0.8, sk.windup * 0.2]:
		boss.cast = {"id": "slam", "left": left}
		v.wipe()
		v._tells()
		if v.edges != [[View.TELL, View.PX.maroon]] or v.fills != [View.TELL]:
			why = "예고가 경계 %s · 칠 %s다(F24+ 빨강 밝은 테와 어두운 테, 빨강 칠 하나여야 한다)" % [v.edges, v.fills]
			break
		radii.append(v.noise[0][0])
	if why == "" and (radii[0] >= radii[1] or radii[1] > int(View.CELL * sk.radius)):
		why = "남은 시간이 줄 때 칠 반지름이 %s다(예고 반경 %d 안에서 커져야 한다)" % [radii, int(View.CELL * sk.radius)]
	v._foes = []  # 숨은 보스(S213)
	v.wipe()
	v._tells()
	if why == "" and not v.edges.is_empty():
		why = "숨은 보스의 예고를 그린다"
	boss.cast = null
	v._fills = [[{"at": Vector2(12, 13), "radius": sk.radius}, View.FILL]]
	v.wipe()
	v._tells()
	if why == "" and (v.discs.size() != 1 or v.discs[0][1] != int(View.CELL * sk.radius) or v.discs[0][2] != Color(View.TELL, 0.6)):
		why = "발동 채움이 %s다(예고 반경 원판 하나, 예고색 60%%여야 한다)" % [v.discs]
	v.free()
	return why

func test_aim_preview_draws_with_art_px_helpers():
	var b = _pair()
	var a = b.heroes[0]
	var s = b.heroes[1]
	var v = Rec.new()
	v.battle = b
	var at := func(c: Vector2i) -> Vector2: return Vector2(c) * View.CELL + Vector2(8, 8)
	v.controls = {"aiming": "q", "aim_hero": a, "mouse": at.call(Vector2i(13, 10))}
	v._aim_preview()
	var o := Vector2i(v._center(a.pos).floor())
	var why := ""
	if not v.rings.any(func(r): return r[0] == o and r[1] == int(View.CELL * b.CAST_RANGE)):
		why = "시전 사거리 고리가 없다: %s" % [v.rings]
	elif v.arcs.size() != 1 or v.lines.size() != 2:
		why = "아이아스 Q 부채꼴이 호 %d · 줄 %d다(호 하나 · 양옆 줄 둘이어야 한다)" % [v.arcs.size(), v.lines.size()]
	var cases := [[a, "r", "설 칸 세 칸의 네 변", func(): return v.pxs.size() == 12],
		[s, "q", "방향 줄 하나", func(): return v.lines.size() == 1 and v.lines[0][0] == Vector2i(v._center(s.pos).floor())],
		[s, "e", "사거리 고리와 영웅 → 지점에 수직인 관문 줄", func(): return v.rings.size() == 1 and v.lines.size() == 1 and absf(Vector2(v.lines[0][1] - v.lines[0][0]).normalized().dot(Vector2(-1, 1).normalized())) < 0.1]]
	for k in cases:
		if why != "":
			break
		v.controls = {"aiming": k[1], "aim_hero": k[0], "mouse": at.call(Vector2i(12, 12))}
		v.wipe()
		v._aim_preview()
		if not k[3].call():
			why = "%s %s 조준이 줄 %d · 고리 %d · 칸 %d다(%s여야 한다)" % [k[0].kind, k[1], v.lines.size(), v.rings.size(), v.pxs.size(), k[2]]
	v.free()
	return why

func test_map_draws_no_screen_px_circles():
	var src := FileAccess.get_file_as_string("res://src/ui/battle_view.gd")
	if src.count("draw_arc(") > 0:
		return "battle_view.gd에 draw_arc가 %d곳 남았다(원·호는 아트 px 고리여야 한다)" % src.count("draw_arc(")
	if src.count("draw_circle(") != 4:
		return "battle_view.gd의 draw_circle이 %d곳이다(그림자·대역 몸 넷만 남아야 한다)" % src.count("draw_circle(")
	return ""

func test_fx4_draws_only_palette_colors():
	var bt := _chrono()
	var b = bt[0]
	var ch = b.heroes[0]
	var a = b.heroes[1]
	var boss = b.spawn_enemy("boss", Vector2i(12, 14), {"speed": 0, "sight": 0, "damage": 0})
	boss.cast = {"id": "slam", "left": 0.5}
	b.traces.append({"hero": boss, "slot": "slam", "aim": null, "at": Vector2(12, 14), "radius": 2.0, "hits": [], "age": 0.0})
	var v = Rec.new()
	v.battle = b
	v._foes = [boss]
	v._fills = [[{"at": Vector2(12, 14), "radius": 2.0}, View.FILL]]
	for t in [0.0, 0.05, 0.1, 0.15, 0.2, 0.25]:
		v._charge(ch, a, t)
		v._charge(ch, bt[1], t)
		b.traces[-1].age = t
		v._traces(true)
	v._tells()
	var off := _off_palette(_colors(v))
	v.free()
	if off != "":
		return "fx-4 흔적·보스 예고에 팔레트 밖 색 %s가 있다" % off
	for src in ["chronos_e", "chronos_r"]:
		var w = _zone_draw(src)
		off = _off_palette(_colors(w))
		w.free()
		if off != "":
			return "%s 장판에 팔레트 밖 색 %s가 있다" % [src, off]
	return ""

# ── fx-8: 세라피나(I227) ──

# 성역 장판 하나를 아군 x 자리에 둔 판
func _sanctum_on(b, x) -> void:
	b.zones = [{"src": "seraphina_w", "owner": b.heroes[0], "pos": x.pos, "radius": 2.0, "left": 3.0, "hps": 5.0, "slow": 0.25}]

# I227 ②·⑥: 성역이 해로운 효과를 지우면 그 아군을 aim으로 맞은 대상 없는 정화 흔적 하나(0.5초에 하나), 그림은 몸 양옆에서 솟는 빛 점 두 줄기
func test_sanctum_cleanse_leaves_one_trace_and_light_streams_beside_ally():
	var b = _duo()
	var x = b.heroes[1]
	_target(b, Vector2i(25, 25))  # 판이 끝나 장판이 지워지지 않게 멀리 선 과녁
	_sanctum_on(b, x)
	b._fx(x, "test", {"slow": 0.4}, 5.0)
	b.step(1.0 / 60.0)
	var why := ""
	var cl: Array = b.traces.filter(func(c): return c.slot == "cleanse")
	if x.fx.has("test"):
		why = "성역 안 아군의 둔화가 안 지워졌다"
	elif cl.size() != 1 or not is_same(cl[0].aim, x) or not cl[0].hits.is_empty():
		why = "정화 흔적이 %s다(그 아군을 aim으로, 맞은 대상 없이 하나여야 한다)" % [cl.map(func(c): return [c.aim, c.hits])]
	if why == "":
		b._fx(x, "test", {"slow": 0.4}, 5.0)
		b.step(1.0 / 60.0)
		if x.fx.has("test") or b.zones.is_empty():
			why = "두 번째 스텝에 정화가 일어나지 않았다(장판 %d개)" % b.zones.size()
		elif b.traces.filter(func(c): return c.slot == "cleanse").size() != 1:
			why = "0.5초 안에 다시 정화했는데 흔적이 늘었다"
	if why != "":
		return why
	var v = Rec.new()
	v.battle = b
	var feet := _feet_px(v, x)
	cl[0].age = 0.2
	v._traces(true)
	var motes: Array = v.pxs.filter(func(p): return p[2] == Vector2i(1, 2) and p[0].y < feet.y)
	if not motes.any(func(p): return p[0].x < feet.x - 2) or not motes.any(func(p): return p[0].x > feet.x + 2):
		why = "정화 0.2초에 몸 양옆 빛 점 줄기가 없다: %s" % [motes.map(func(p): return p[0])]
	elif motes.any(func(p): return absi(p[0].x - feet.x) <= 2):
		why = "빛 점이 몸 가운데를 가린다: %s" % [motes.map(func(p): return p[0])]
	elif not motes.any(func(p): return p[0].y < feet.y - int(v._head(x) * 0.5)):
		why = "빛 점이 몸 위쪽까지 솟지 않았다"
	v.wipe()
	cl[0].age = View.CLEANSE_RISE
	v._traces(true)
	if why == "" and not v.pxs.is_empty():
		why = "CLEANSE_RISE초 뒤에도 빛 점을 그린다"
	v.free()
	return why

# I227 ②: 성역 안 아군에서만 그을음 테두리 금 십자가 오른다
func test_sanctum_allies_show_rising_gold_cross_and_outside_none():
	var b = _duo()
	var s = b.heroes[0]
	var x = b.heroes[1]
	_sanctum_on(b, x)
	var v = Rec.new()
	v.battle = b
	var why := ""
	var near_in := 0
	for t in [0.0, 0.15, 0.3, 0.45]:
		v.clock = t
		v.wipe()
		v._sera_marks()
		var arms: Array = v.pxs.filter(func(p): return p[1] == View.PX.gold and p[2] == Vector2i(1, 3))
		var rims: Array = v.pxs.filter(func(p): return p[1] == View.PX.soot and p[2] == Vector2i(3, 5))
		if arms.any(func(p): return Vector2(p[0]).distance_to(v._chest(s)) < 12.0):
			why = "성역 밖 세라피나에도 금 십자가 있다"
			break
		if arms.any(func(p): return Vector2(p[0]).distance_to(v._chest(x)) < 16.0) and not rims.is_empty():
			near_in += 1
	if why == "" and near_in < 2:
		why = "성역 안 아군의 테두리 금 십자가 주기 안에서 %d번만 보였다" % near_in
	v.free()
	return why

# I227 ③: 수호 천사 4초는 등 뒤 접힌 날개(몸통 아래 층), 불사 순간 흔적은 크림 원판 번쩍 + 깃털, 불사 동안 공용 금 테·별은 그대로
func test_guardian_folded_wings_then_saved_flash_feathers_and_invuln_kept():
	var b = _duo()
	var x = b.heroes[1]
	b._fx(x, "seraphina_e", {"heal_up": 0.3, "angel": 2.5}, 4.0)
	var v = Rec.new()
	v.battle = b
	var feet := _feet_px(v, x)
	var shoulder := feet.y - int(v._head(x) * 0.45)
	v._folded_wings()
	var why := ""
	var up: Array = v.pxs.filter(func(p): return p[1] == View.PX.cream and p[0].y < shoulder - 4)
	if not up.any(func(p): return p[0].x < feet.x - 3) or not up.any(func(p): return p[0].x > feet.x + 3):
		why = "수호 천사가 걸린 아군 어깨 위 양옆에 크림 날개가 없다: %s" % [up.map(func(p): return p[0])]
	elif not v.pxs.any(func(p): return p[1] == View.PX.soot):
		why = "접힌 날개에 그을음 테두리가 없다"
	x.hp = 3.0
	b.damage(x, 500.0, "phys")
	var sv: Array = b.traces.filter(func(c): return c.slot == "saved")
	if why == "" and (not x.alive or not x.fx.has("seraphina_e_saved")):
		why = "죽을 피해에 불사가 안 됐다"
	elif why == "" and (sv.size() != 1 or not is_same(sv[0].aim, x) or not sv[0].hits.is_empty()):
		why = "불사 흔적이 %s다(그 아군을 aim으로, 맞은 대상 없이 하나여야 한다)" % [sv.map(func(c): return [c.aim, c.hits])]
	if why != "":
		v.free()
		return why
	var kinds: Array = v.status_marks(x, true).map(func(m): return m.k)
	if kinds.count("ring") < 1 or not kinds.has("star"):
		why = "불사 동안 공용 금 테·별이 없다: %s" % [kinds]
	v.wipe()
	sv[0].age = 0.05
	v._traces(true)
	var flash: Array = v.discs.filter(func(d): return d[1] == 6 and d[2] == View.PX.cream)
	var feathers: Array = v.pxs.filter(func(p): return p[1] == View.PX.cream and p[2] == Vector2i(1, 2))
	if why == "" and (flash.size() != 1 or feathers.size() < View.FEATHERS):
		why = "불사 0.05초에 크림 원판 %d · 깃털 %d다(원판 하나 · 깃털 %d이어야 한다)" % [flash.size(), feathers.size(), View.FEATHERS]
	v.wipe()
	sv[0].age = View.SAVE_FLASH + 0.02
	v._traces(true)
	if why == "" and v.discs.any(func(d): return d[1] == 6):
		why = "SAVE_FLASH초 뒤에도 원판이 번쩍인다"
	v.wipe()
	v._folded_wings()
	if why == "" and (not v.spr.any(func(q): return q[0] == "wing") or v.pxs.any(func(p): return p[1] == View.PX.cream)):
		why = "불사 동안 등 뒤가 %s · 접힌 날개 칸 %d다(날개 조각만 있어야 한다)" % [v.spr, v.pxs.size()]
	v.free()
	return why

# I227 ④: 축복이 걸린 영웅 머리 위·탑 쏘는 곳 옆에 마름모 빛 맺힘(BLESS_BLINK초마다 밝기), 축복 터짐 흔적은 크림 십자 + 대각선으로 퍼지는 2×2 조각 넷
func test_bless_diamond_beside_hands_and_tower_and_burst_shards():
	var bt := _chrono()
	var b = bt[0]
	var tower = bt[1]
	if tower == null or not tower.complete:
		return "궁수탑을 못 지었다"
	var plain = b.heroes[0]
	var a = b.heroes[1]
	b._fx(a, "seraphina_r", {"bless": 3.0, "splash": 1.0}, 5.0)
	b._fx(tower, "seraphina_r", {"bless": 3.0, "splash": 1.0}, 5.0)
	var v = Rec.new()
	v.battle = b
	var why := ""
	var near := func(x, col: Color) -> int:
		return v.pxs.filter(func(p): return p[1] == col and Vector2(p[0]).distance_to(Vector2(v.bless_spot(x))) < 5.0).size()
	var top: Vector2i = v.bless_spot(a)
	var feet := _feet_px(v, a)
	if top.y + 3 >= feet.y - int(v._head(a) * 0.6) or absi(top.x - feet.x) > 1:
		why = "영웅 축복 자리 %s가 머리 위가 아니다(발 %s, 받는 피해 감소 방패 조각은 몸 양옆 높이)" % [top, feet]
	elif Vector2(v.bless_spot(tower)).distance_to(v._muzzle(tower)) > 9.0:
		why = "탑 축복 자리가 쏘는 곳 옆이 아니다"
	v._sera_marks()
	if why == "" and (near.call(a, View.PX.cream) == 0 or near.call(tower, View.PX.cream) == 0):
		why = "축복이 걸린 영웅 머리 위·탑 쏘는 곳 옆에 크림 빛 맺힘이 없다"
	elif near.call(a, View.PX.soot) == 0 or near.call(tower, View.PX.soot) == 0:
		why = "축복 빛 맺힘에 그을음 테두리가 없다"
	elif near.call(plain, View.PX.cream) != 0:
		why = "축복이 없는 영웅에도 빛 맺힘이 있다"
	v.clock = View.BLESS_BLINK
	v.wipe()
	v._sera_marks()
	if why == "" and (near.call(a, View.PX.cream) != 0 or near.call(a, View.PX.gold) == 0):
		why = "BLESS_BLINK초 뒤 빛 맺힘이 어두워지지 않았다"
	var e = b.enemies[0]
	var hp0: float = e.hp
	b._blessing(a, e.pos, 3.0, 1.0)
	var bl: Array = b.traces.filter(func(c): return c.slot == "bless")
	if why == "" and (e.hp >= hp0 or bl.size() != 1 or bl[0].at != e.pos or not bl[0].hits.is_empty() or bl[0].radius != 1.0):
		why = "축복 터짐이 피해 %.1f · 흔적 %s다(피해는 그대로, 맞은 대상 없는 흔적 하나여야 한다)" % [hp0 - e.hp, bl.map(func(c): return [c.at, c.hits, c.radius])]
	if why != "":
		v.free()
		return why
	var c := Vector2i(v._center(e.pos).floor()) - Vector2i(0, 6)
	var reach := []
	for t in [0.02, 0.15]:
		bl[0].age = t
		v.wipe()
		v._traces(true)
		var shards: Array = v.pxs.filter(func(p): return p[2] == Vector2i(2, 2))
		var diag := shards.filter(func(p): return absf(absf(p[0].x + 1.0 - c.x) - absf(p[0].y + 1.0 - c.y)) <= 2.0 and Vector2(p[0] + Vector2i.ONE - c).length() > 2.0)
		if diag.size() != 4:
			why = "축복 터짐 %.2f초 대각선 조각이 %s다(넷이어야 한다)" % [t, shards.map(func(p): return p[0] - c)]
			break
		reach.append(Vector2(diag[0][0] + Vector2i.ONE - c).length())
		if t == 0.02 and not v.pxs.any(func(p): return p[1] == View.PX.cream and p[2].x >= 3 and p[0].y == c.y):
			why = "축복 터짐 0.02초 가운데 크림 십자가 없다"
			break
	if why == "" and reach[1] <= reach[0]:
		why = "조각이 퍼지지 않는다: %s" % [reach]
	bl[0].age = View.BLESS_BURST
	v.wipe()
	v._traces(true)
	if why == "" and not v.pxs.is_empty():
		why = "BLESS_BURST초 뒤에도 조각을 그린다"
	v.free()
	return why

# I227 ⑤: 세라피나 보호막은 금 점선 테, 다른 보호막이 함께 있으면 공용 얼음 테도
func test_seraphina_shield_is_gold_dashed_ring_and_others_keep_ice():
	var b = _battle()
	var v = View.new()
	v.battle = b
	var h = b.heroes[0] if not b.heroes.is_empty() else b.units[0]
	h.shields["seraphina"] = {"hp": 10.0, "left": 2.0}
	var rings: Array = v.status_marks(h, true).filter(func(m): return m.k == "ring")
	var why := ""
	if rings.size() != 1 or rings[0].c != View.PX.gold or rings[0].get("dash", 0) != 2:
		why = "세라피나 보호막만 있는데 테가 %s다(금 점선 테 하나여야 한다)" % [rings]
	h.shields["aias_w"] = {"hp": 10.0, "left": 2.0}
	rings = v.status_marks(h, true).filter(func(m): return m.k == "ring")
	if why == "" and (rings.size() != 2 or not rings.any(func(m): return m.c == View.PX.ice0 and m.get("dash", 0) == 0)):
		why = "보호막 둘인데 테가 %s다(금 점선 테 + 얼음 테여야 한다)" % [rings]
	v.free()
	return why

func test_fx8_draws_only_palette_colors():
	var bt := _chrono()
	var b = bt[0]
	var a = b.heroes[1]
	var e = b.enemies[0]
	b._fx(a, "seraphina_e", {"heal_up": 0.3, "angel": 2.5}, 4.0)
	b._fx(a, "seraphina_r", {"bless": 3.0, "splash": 1.0}, 5.0)
	b._fx(bt[1], "seraphina_r", {"bless": 3.0, "splash": 1.0}, 5.0)
	a.shields["seraphina"] = {"hp": 10.0, "left": 2.0}
	_sanctum_on(b, a)
	b._trace(a, "cleanse", a, a.pos, 0.0)
	b._trace(a, "saved", a, a.pos, 0.0)
	b._trace(a, "bless", null, e.pos, 1.0)
	b._tracing = null
	var v = Rec.new()
	v.battle = b
	for t in [0.0, 0.05, 0.1, 0.15, 0.2, 0.3, 0.5]:
		v.clock = t
		for c in b.traces:
			c.age = t
		v._traces(true)
		v._folded_wings()
		v._sera_marks()
		v._beam(b.heroes[0], [a, e, b.heroes[0]], t)
		for m in v.status_marks(a, true):
			if m.k == "ring":
				v.rings.append([m.p, m.r, 1, m.c, m.get("dash", 0), 0.0])
	var off := _off_palette(_colors(v))
	v.free()
	if off != "":
		return "fx-8 그림에 팔레트 밖 색 %s가 있다" % off
	return ""

# ── fx-9: 베스퍼(I226) ──

func test_shared_damage_leaves_share_trace_and_light_flows_along_chain():
	var bt := _chained()
	var b = bt[0]
	var hub = bt[1]
	var a = bt[2]
	var c = bt[3]
	b.traces.clear()
	b.damage(a, 10.0, "phys", b.heroes[1])
	var sh: Array = b.traces.filter(func(t): return t.slot == "share")
	var why := ""
	if sh.size() != 1 or sh[0].aim != a or sh[0].chain != a.fx.vesper_e.chain or not sh[0].hits.is_empty() or sh[0].hero != b.heroes[1]:
		why = "a가 맞았는데 나누기 흔적이 %s다(a·사슬 번호·맞은 대상 없음·주인 베스퍼여야 한다)" % [sh]
	if why == "":
		b.traces.clear()
		b._fx(a, "vesper_q", {"dot": 3.0}, 3.0)  # 초당 피해에서 나뉜 것은 남기지 않는다
		for i in 10:
			b._tick(1.0 / 60.0)
		if b.traces.any(func(t): return t.slot == "share"):
			why = "중독 초당 피해가 나뉠 때도 나누기 흔적을 남긴다"
		b.traces = sh
	var v = Rec.new()
	v.battle = b
	v._foes = b.enemies
	var ch := [v._chest(a), v._chest(hub), v._chest(c)]
	var bead := func(): return v.pxs.filter(func(p): return p[1] == View.PX.cream and p[2] == Vector2i(5, 3))
	for step in [[0.5, 0, 1], [1.5, 1, 2]]:  # 맞은 a → hub(첫 마디) → c(둘째 마디)
		if why != "":
			break
		sh[0].age = View.CHAIN_HOP * step[0]
		v.wipe()
		v._traces(true)
		var bs: Array = bead.call()
		var want := Vector2i(ch[step[1]].lerp(ch[step[2]], 0.5).floor())
		var burst: Array = v.rings.filter(func(r): return r[0] == Vector2i(ch[0].floor()) and r[3] == View.PX.cream)
		if bs.size() != 1 or (bs[0][0] + Vector2i(2, 1) - want).length() > 1.5:
			why = "%.2f초 크림 빛이 %s다(%s 둘레 하나여야 한다)" % [sh[0].age, bs.map(func(p): return p[0] + Vector2i(2, 1)), want]
		elif not v.pxs.any(func(p): return p[0] == bs[0][0] - Vector2i(1, 1) and p[1] == View.PX.night and p[2] == Vector2i(7, 5)):
			why = "%.2f초 빛에 바깥 검정 1px이 없다" % sh[0].age
		elif not v.pxs.any(func(p): return p[0] == bs[0][0] + Vector2i(1, 1) and p[1] == View.PX.teal and p[2] == Vector2i(3, 1)):
			why = "%.2f초 빛 가운데에 청록 3×1이 없다" % sh[0].age
		elif step[0] < 1.0 and (burst.size() != 1 or burst[0][1] < 3 or burst[0][1] > 7 or not v.rings.any(func(r): return r[0] == burst[0][0] and r[1] == burst[0][1] + 1 and r[3] == View.PX.night)):
			why = "%.2f초 맞은 적 가슴에 퍼지는 크림 고리(반지름 3~7, 바깥 검정 1px)가 %s다" % [sh[0].age, v.rings]
		elif step[0] > 1.0 and not v.rings.any(func(r): return r[0] == Vector2i(ch[1].floor()) and r[3] == View.PX.teal):
			why = "빛이 지난 E 대상 가슴에 청록 고리가 없다: %s" % [v.rings]
	if why == "":  # 맞은 적 고리는 퍼진다
		var rs := []
		for t in [0.01, View.CHAIN_RING * 0.9]:
			sh[0].age = t
			v.wipe()
			v._traces(true)
			rs.append(v.rings.filter(func(r): return r[0] == Vector2i(ch[0].floor()) and r[3] == View.PX.cream).map(func(r): return r[1]))
		if rs[0].size() != 1 or rs[1].size() != 1 or rs[1][0] <= rs[0][0]:
			why = "맞은 적 크림 고리 반지름이 %s다(퍼져야 한다)" % [rs]
	if why == "":
		sh[0].age = View.CHAIN_HOP * 2.0 + View.CHAIN_RING + 0.01
		v.wipe()
		v._traces(true)
		if not bead.call().is_empty() or not v.rings.is_empty():
			why = "다 흐른 뒤에도 빛 %d · 고리 %d가 남는다" % [bead.call().size(), v.rings.size()]
	v.free()
	return why

func test_contagion_leaves_spread_trace_then_ring_and_rising_skulls():
	var b = _duo()
	var ves = b.heroes[1]
	var carrier = _target(b, Vector2i(14, 13))
	var near = _target(b, Vector2i(15, 14))
	var lone = _target(b, Vector2i(24, 24))
	b._fx(carrier, "vesper_w", {"slow": 0.4, "spread": 2.0}, 4.0)
	b._fx(lone, "vesper_w", {"slow": 0.4, "spread": 2.0}, 4.0)
	b.traces.clear()
	b.damage(lone, 2e9, "true", ves)  # 둘레에 옮을 적이 없으면 흔적이 없다
	var why := ""
	if b.traces.any(func(t): return t.slot == "spread"):
		why = "옮은 적이 없는데 전염 흔적을 남긴다"
	b.damage(carrier, 2e9, "true", ves)
	var sp: Array = b.traces.filter(func(t): return t.slot == "spread")
	if why == "" and (sp.size() != 1 or sp[0].foes != [near] or not sp[0].hits.is_empty() or sp[0].radius != 2.0 or sp[0].at != carrier.pos or sp[0].hero != ves):
		why = "전염 흔적이 %s다(죽은 자리·반경 2·옮은 적 near·맞은 대상 없음·주인 베스퍼여야 한다)" % [sp]
	if why != "":
		return why
	var v = Rec.new()
	v.battle = b
	v._foes = b.enemies
	var at := Vector2i(v._center(carrier.pos).floor()) - Vector2i(0, 2)
	var crown: Vector2i = v._crown(near)
	var skull := func(): return v.pxs.filter(func(p): return p[1] == View.PX.cream)
	var rs := []
	for t in [0.05, 0.25]:
		sp[0].age = t
		v.wipe()
		v._traces(true)
		var main: Array = v.segs.filter(func(r): return r[0] == at)
		if main.size() != 1 or main[0][6] >= 0 or main[0][1] < 4 or main[0][1] > View.CELL * 2 or absf(main[0][4] - TAU * main[0][1] / View.PLAGUE_DASH) > 1.0 or v.rings.any(func(r): return r[0] == at):
			why = "%.2f초 전염 고리가 끊긴 고리 %s · 이은 고리 %s다(죽은 자리에서 전염 반경까지, 약 %dpx 주기 점선 하나)" % [t, v.segs, v.rings, View.PLAGUE_DASH]
		else:
			why = _broken(v, main[0])
		if why != "":
			break
		rs.append(main[0][1])
	if why == "" and rs[1] <= rs[0]:
		why = "전염 고리가 퍼지지 않는다"
	if why == "":
		sp[0].age = 0.1
		v.wipe()
		v._traces(true)
		if not skull.call().is_empty():
			why = "SKULL_IN 전에 해골이 보인다"
	var ys := []
	for t in [0.2, 0.6]:
		if why != "":
			break
		sp[0].age = t
		v.wipe()
		v._traces(true)
		var body: Array = skull.call()
		if body.size() != 16 or not body.all(func(p): return absi(p[0].x - crown.x) <= 2 and p[0].y <= crown.y + 2):
			why = "%.2f초 해골이 %s다(옮은 적 머리 위 크림 16칸이어야 한다)" % [t, body.map(func(p): return p[0])]
		else:
			ys.append(body.map(func(p): return p[0].y).min())
	if why == "" and ys[1] >= ys[0]:
		why = "해골이 떠오르지 않는다: %s" % [ys]
	for t in [0.72, View.SKULL_OUT + 0.01]:  # 끝 SKULL_BLINK초는 깜박이고, SKULL_OUT 뒤로는 없다
		if why != "":
			break
		sp[0].age = t
		v.wipe()
		v._traces(true)
		if not skull.call().is_empty():
			why = "%.2f초에 해골이 보인다" % t
	v.free()
	return why

func test_swamp_foes_sink_feet_in_mud_band():
	var b = _duo()
	var e = _target(b, Vector2i(14, 13))
	var dry = _target(b, Vector2i(20, 13))
	b._fx(e, "vesper_r", {"slow": 0.6, "seal": true}, 0.1)
	var v = Rec.new()
	v.battle = b
	v._foes = [e, dry]
	v._mire_marks()
	var f := _feet_px(v, e)
	var why := ""
	if not v.pxs.any(func(p): return p[0] == f + Vector2i(-5, -2) and p[1] == View.PX.soot and p[2] == Vector2i(11, 1)):
		why = "늪에 든 적 발 위에 그을음 띠가 없다: %s" % [v.pxs]
	elif not v.pxs.any(func(p): return p[0] == f + Vector2i(-6, -1) and p[1] == View.PX.dark and p[2] == Vector2i(13, 2)):
		why = "늪에 든 적 발을 덮는 진흙 띠가 없다"
	elif v.pxs.any(func(p): return absi(p[0].x - _feet_px(v, dry).x) < 8):
		why = "늪 밖 적에도 진흙 띠를 그린다"
	v.free()
	return why

func test_fx9_draws_only_palette_colors():
	var bt := _chained()
	var b = bt[0]
	b.damage(bt[2], 10.0, "phys", b.heroes[1])
	b.traces.append({"hero": b.heroes[1], "slot": "spread", "aim": null, "at": Vector2(15, 16), "radius": 2.0, "hits": [], "marked": false, "age": 0.0, "foes": [bt[1]]})
	b._fx(bt[2], "vesper_r", {"slow": 0.6}, 1.0)
	var v = Rec.new()
	v.battle = b
	v._foes = b.enemies
	for t in [0.0, 0.05, 0.1, 0.15, 0.2, 0.3, 0.5, 0.7]:
		for c in b.traces:
			c.age = t
		v._traces(true)
		v._hex(Vector2i(100, 100), 32.0, t, 7)
		v.clock = t
		v._mire_marks()
	var off := _off_palette(_colors(v))
	v.free()
	if off != "":
		return "fx-9 흔적에 팔레트 밖 색 %s가 있다" % off
	return ""
