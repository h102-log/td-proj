extends Node2D
# 전투 상태를 칸 단위로 그린다. 바닥은 타일(4.1b), 영웅은 도트 스프라이트(S165), 용병·적은 4방향 스프라이트(4.1d), 시설은 그림(4.1e), 나머지는 아직 도형이다(그레이박스, 아트는 WBS 4.1).

const CELL := 16
const COLORS := {
	"grid": Color(0, 0, 0, 0.15), "spawn": Color("c03030"), "merc": Color("50a0f0"),
	"engineer": Color("f0a030"), "archer": Color("60d0a0"),
}
const ENEMY_COLORS := {  # 적 종류마다 다른 색(I81)
	"basic": Color("d04040"), "fast": Color("f08030"), "armored": Color("807070"), "flying": Color("e050c0"), "boss": Color("801010"),
}
const HERO_COLORS := {  # 영웅 종류마다 다른 색(S56, S157, I101)
	"aias": Color("b060f0"), "sylvia": Color("a0ff40"), "seraphina": Color("f0f0f0"), "vesper": Color("40c060"), "ignis": Color("ff5020"), "chronos": Color("ffd020"),
}
# 걸린 효과의 테두리 색(I101). 적: 기절·속박·둔화·받는 피해 증가·도발·봉인·사슬·초당 피해. 아군: 받는 피해 감소·공격 속도·보호막·불사
const MARKS := {
	"stun": Color.YELLOW, "root": Color("c0a060"), "slow": Color.CYAN, "expose": Color.MAGENTA, "taunt": Color.RED, "seal": Color("6040a0"), "chain": Color("a0a0ff"), "dot": Color("ff8040"),
	"dr": Color("80c0ff"), "haste": Color.ORANGE, "shield": Color.WHITE, "invuln": Color.GOLD,
}
const ZONES := {  # 장판 색(I101). 엷게 채우고 테두리를 그린다
	"aias_r": Color("80c0ff"), "sylvia_e": Color("c0a060"), "sylvia_r": Color("a0ff40"), "seraphina_w": Color("fff0a0"), "vesper_q": Color("60c040"),
	"vesper_r": Color("402060"), "ignis_q": Color("ff6020"), "ignis_e": Color("8040c0"), "ignis_r": Color("ff3000"), "chronos_e": Color("ffd020"), "chronos_r": Color("40e0ff"),
}

const UNITS := preload("res://art/units/heroes.png")  # 영웅 6명과 용병·적 시트를 한 장에 모은 아틀라스(tools/art/atlas.py)
static var ART: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/units/heroes.json"))  # 종류 → 캔버스·발밑·시트 y
const LUNGE := 6.0  # 근접 돌진 거리(px). 림월드 0.35칸을 16px 칸으로 옮겼다(06 §4)
const CONTACT := 0.08  # 근접 공격이 대상에 닿는 때(친 뒤 초). 돌진(_lunge)이 가장 멀리 나간 때다
const FLASH := 0.1  # 피격 흰 번쩍임 길이(초, S177)
const FLINCH := 3.0  # 피격 밀림(px, S177). 림월드 0.17칸을 16px 칸으로 옮겼다(06 §4)
const FLINCH_BACK := 0.17  # 밀린 몸이 돌아오는 시간(초, 06 §4 약 10프레임)
const HITSTOP := 3.0 / 60.0  # 영웅이 치거나 맞은 타격에서 두 유닛의 그림만 멈추는 시간(초, S177). 시뮬레이션은 멈추지 않는다
const PIXEL_FONT := preload("res://art/fonts/Galmuri7.ttf")  # 맵 위 숫자(S167). 맵은 640×360을 정수배로 키우므로 벡터 글자는 뭉개진다
const GROUND_TILES := preload("res://art/tiles/ground.png")  # 0행 풀↔흙 꼭짓점 16꼴, 1행 풀·흙 변종과 깃발, 2·3행 전환 꼴 변종(tools/art/tiles.py)
const CASTLE := preload("res://art/castle/walls.png")  # 성곽 칸 조각 16×42: 행 단계 1~3마다 몸체·앞층, 통로 그늘, 잔해. 열 성벽·열린 문·닫힌 문(tools/art/atlas.py castle)
const KEEP := preload("res://art/castle/keep.png")  # 거점 망루 80×80, 마을 레벨 1·2. 칸 앞쪽 아래 왼쪽 모서리가 그림의 (32, 72)다(tools/art/keep.py)
const FACILITY := preload("res://art/castle/facility.png")  # 시설 48×48: 0행 그림, 1행 청사진 바탕. 칸 앞쪽 아래 왼쪽 모서리가 그림의 (16, 44)다(tools/art/facility.py)
static var FAC: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/castle/facility.json"))  # 종류 → [열, 그림 맨 윗줄, 맨 아랫줄 + 1]
const BLUEPRINT := Color(0.55, 0.78, 1.0, 0.6)  # 청사진 색(사용자 2026-10-20, 림월드 설계도). 회색 바탕에 곱한다
const GHOST := Color(1, 1, 1, 0.4)  # 거점에 가려진 유닛·시설을 덧그리는 색(C1, 사용자 2026-10-20). 성벽·거점에 가려진 영웅의 마나 막대도 이 색이다
const SHADE := Color(0, 0, 0, 0.55)  # 성벽에 가려진 부분의 실루엣 색(S175). 55%는 사용자가 고른 시안의 합성 색에 맞춘 Claude 값
const WALL_H := 24  # 성벽 앞면 높이(px, 4.0 확정값)
const TEAM := [Color("3c9f9c"), Color("ef3a0c")]  # 발밑 팀 색(S166): 아군 청록, 적 빨강(F24+ 팔레트)
static var FEET: ImageTexture = _feet()  # 발밑 채운 타원 14×6px. 아군·적을 한 장에 나란히 둬서 draw call이 끊기지 않는다

var battle
var controls  # 고른 유닛에 테두리를 그린다
var _seen := {}  # 영웅·용병·적 → [지난 위치, 방향]
var _hits := {}  # 방금 맞은 영웅·용병·적 id → [맞은 뒤 지난 시간(초), 공격자 → 대상 방향](S177). _bodies마다 다시 구한다
var ground: ImageTexture  # 바닥을 한 장으로 구운 것. 마을·출현 지점은 도전 내내 같아서(I91) 처음 한 번만 굽는다
var _clip := -INF  # 덧그릴 때 이 화면 y보다 위 줄은 그리지 않는다(_shade)

func _draw() -> void:
	if ground == null:
		ground = bake_ground(battle)
	draw_texture(ground, Vector2.ZERO)
	if controls.placing != "":  # 격자선은 놓기 모드에서만(4.1b, 사용자 2026-10-20)
		var map := Vector2(battle.size) * CELL
		for x in battle.size.x + 1:
			draw_line(Vector2(x * CELL, 0), Vector2(x * CELL, map.y), COLORS.grid)
		for y in battle.size.y + 1:
			draw_line(Vector2(0, y * CELL), Vector2(map.x, y * CELL), COLORS.grid)
	for s in battle.structures.values():  # 시설 그림은 _bodies가 유닛과 함께 정렬해 그린다(4.1e)
		if s.dest != null:  # 옮겨 갈 칸(S44): 청사진 색 테두리와 대포에서 이어지는 점선. 칸의 대포 청사진은 _bodies가 그린다(S176)
			draw_rect(_rect(s.dest), Color(BLUEPRINT, 1.0), false, 1.0)
			draw_dashed_line(_center(Vector2(s.cell)), _center(Vector2(s.dest)), Color(1, 1, 1, 0.7), 1.0, 3.0)
	for c in battle.barriers:  # 에너지 성벽(S151): 밝은 칸
		draw_rect(_rect(c), Color(MARKS.dr, 0.8))
	for z in battle.zones:  # 장판(I101). 떨어지는 중인 운석은 테두리만, 덫은 플레이어에게만 보인다
		var col: Color = ZONES.get(z.src, Color.WHITE)
		if z.has("cells"):
			continue
		if z.get("delay", 0.0) <= 0.0:
			draw_circle(_center(z.pos), CELL * z.radius, Color(col, 0.18))
			_pattern(z.src, _center(z.pos).round(), CELL * z.radius, Color(col, 0.9))
		draw_arc(_center(z.pos), CELL * z.radius, 0.0, TAU, 48, Color(col, 0.8), 1.0)
	for p in battle.forecast:  # 기본 적의 예상 경로(S142): 엷은 빨간 선, 유닛 아래에. 너비 1이면 1배 줌에서 칸 중심을 지나는 가로·세로 구간이 안 그려진다
		draw_polyline(PackedVector2Array(p.map(func(c): return _center(Vector2(c)))), Color(COLORS.spawn, 0.5), 1.5)
	# 타워 사격 선: 쏜 뒤 0.1초 동안. 대포는 맞은 곳에 범위 피해 원도 그린다(S90)
	for s in battle.structures.values():
		if s.target and s.cooldown > s.fire_gap - 0.1:
			draw_line(_spot(s), _spot(s.target), Color.YELLOW, 1.0)
			if s.splash > 0.0:
				draw_arc(_center(s.target.pos), CELL * s.splash, 0.0, TAU, 24, Color.YELLOW, 1.0)
	for h in battle.heroes:  # 오라 반경(S113): 오라가 있는 살아 있는 영웅마다 둘레에 늘 엷게, 유닛 아래에(I101)
		if h.alive and not h.aura.is_empty():
			_aura_ring(h)
	_bodies()
	_marks()
	for u in battle.units:
		var at := _spot(u)
		if u.is_hero:  # 영웅 레벨(I117): 오른쪽 위에 작게
			draw_string(PIXEL_FONT, (at + Vector2(CELL * 0.3, -CELL * 0.3)).round(), str(u.level), HORIZONTAL_ALIGNMENT_LEFT, -1, 8)
		if u in controls.selected:  # 테두리: 흰색 이동 중 공격, 노란색 무조건 이동. 홀드면 기준 반경도 그린다
			draw_arc(at, CELL * (u.radius + 0.2), 0.0, TAU, 24, Color.YELLOW if u.move_mode == "move" else Color.WHITE, 1.0)
			if u.hold:
				draw_arc(u.anchor * CELL + Vector2(CELL, CELL) / 2, CELL * u.hold_radius, 0.0, TAU, 48, Color(1, 1, 1, 0.4), 1.0)
		var ring := 0.35  # 걸린 효과(I101): 선택 테두리 바깥에 효과마다 한 겹
		for key in ["dr", "haste", "shield", "invuln"]:
			var on: bool = (not u.shields.is_empty()) if key == "shield" else (battle.effect(u, key) != null if key == "invuln" else battle.effect_sum(u, key) > 0.0)
			if on:
				draw_arc(at, CELL * (u.radius + ring), 0.0, TAU, 24, MARKS[key], 1.0)
				ring += 0.15
	for e in battle.enemies:
		var ring := 0.15
		for key in ["stun", "root", "slow", "expose", "taunt", "seal", "chain", "dot"]:  # 걸린 효과(I101)
			if battle.effect(e, key) != null:
				draw_arc(_spot(e), CELL * (e.radius + ring), 0.0, TAU, 24, MARKS[key], 1.0)
				ring += 0.15
	for u in battle.units:  # 마나 막대(S146): 영웅 발밑. 붙잡힌 적에 가리지 않게 적보다 나중에 그린다. 성벽·거점에 가린 영웅은 덧그림처럼 반투명(사용자 2026-10-20)
		if u.is_hero and u.alive:
			var bar := Rect2(_spot(u) + Vector2(-CELL, CELL) / 2.0, Vector2(CELL, 2))
			var tint := GHOST if _behind(u) else Color.WHITE
			draw_rect(bar, Color.BLACK * tint)
			draw_rect(Rect2(bar.position, Vector2(CELL * u.mana / u.max_mana, 2)), Color("4080ff") * tint)
	for h in battle.heroes:  # 쓰러진 영웅: 복귀할 때까지 쓰러진 자리에 그 영웅 색의 X(I130)
		if not h.alive:
			var c := _center(h.pos)
			var r := Vector2(CELL, CELL) * 0.3
			draw_line(c - r, c + r, HERO_COLORS[h.kind], 2.0)
			draw_line(c + Vector2(-r.x, r.y), c + Vector2(r.x, -r.y), HERO_COLORS[h.kind], 2.0)
	# 공격선: 친 뒤 0.1초 동안 아군은 흰색, 적은 빨간색(S71). 대상이 무엇이든 그린다(I59)
	for u in battle.units:
		if u.target and u.cooldown > u.attack_gap - 0.1:
			draw_line(_spot(u), _spot(u.target), Color.WHITE, 1.0)
	for e in battle.enemies:
		if e.target and e.cooldown > e.attack_gap - 0.1:
			draw_line(_spot(e), _spot(e.target), Color.RED, 1.0)
	# 즉시 스킬 범위 원(S72): 쓴 뒤 0.3초 동안 영웅 둘레에. ponytail: 0.3초는 임시값, 짧거나 길면 바꾼다
	for h in (battle.heroes if battle.state == "battle" else []):
		for slot in battle.SLOTS:
			var sk: Dictionary = h.get(slot)
			if h.alive and sk.get("aim") == "self" and sk.has("radius") and h.cd[slot] > sk.gap - 0.3:
				draw_arc(_center(h.pos), CELL * sk.radius, 0.0, TAU, 48, Color.WHITE, 1.0)
	_aim_preview()
	if controls.show_hp:
		for u in battle.units + battle.enemies:
			_hp_bar(u.pos - Vector2(0, _lift(u) / CELL), u)
	if controls.drag_rect.has_area():
		draw_rect(controls.drag_rect, Color.WHITE, false, 1.0)

# 칸에 붙는 표시: 놓기 모드 칸, 효과 테두리, 고른 것 테두리, 집결 지점, 체력 막대. 성벽 그림에 가리지 않게 몸통 뒤에 그린다(4.1c)
func _marks() -> void:
	if controls.placing != "":  # 놓기 모드: 지금 지을(놓을) 수 있는 칸을 엷게(S45, I138)
		for c in battle.placeable_cells(controls.placing):
			draw_rect(_rect(c), Color(1, 1, 1, 0.25))
	for s in battle.structures.values() + battle.castle.values():  # 받는 피해 감소·공격 속도가 걸린 칸(I101)
		var ring := 1
		for key in ["dr", "haste"]:
			if battle.effect_sum(s, key) > 0.0:
				draw_rect(_box(s).grow(-ring), MARKS[key], false, 1.0)
				ring += 2
	for s in controls.picked + ([controls.fort] if controls.fort else []) + ([battle.base] if controls.village else []):  # 전투 단계에 고른 구조물(S74, S83)·고른 성곽 칸(S85)·고른 거점(S100)
		draw_rect(_box(s), Color.WHITE, false, 1.0)
	var f = controls.facility  # 고른 생산 시설: 테두리와 집결 지점 깃발(S82)
	if f and f.alive:
		draw_rect(_rect(f.cell), Color.WHITE, false, 1.0)
		draw_line(_center(Vector2(f.cell)), _center(Vector2(f.rally)), Color(1, 1, 1, 0.4), 1.0)
		draw_rect(_rect(f.rally).grow(-5), Color.WHITE)
	_hp_bar(Vector2(battle.base.cell) - Vector2(0, 1.75), battle.base)  # 망루 흉벽 위(칸 위 1.75칸). 칸 위에 그리면 앞면 휘장을 가로질렀다
	# 구조물·성곽은 깎였을 때만 체력 막대를 그린다(성곽 칸이 많아서). V로 켜면 구조물은 늘 그린다(S73, I59)
	for b in battle.castle.values() + battle.structures.values():
		if b.hp < b.max_hp or (controls.show_hp and b.kind in battle.STRUCTURE_KINDS):
			var top: float = 28.0 - FAC[b.kind][1] if FAC.has(b.kind) else 0.0  # 시설은 그림 위에(4.1e). 칸 위에 그리면 그림을 가로질렀다
			_hp_bar(Vector2(b.cell) - Vector2(0, (_lift(b) + top) / CELL), b)

# 유닛·적·주민 몸통(S165, S172)과 성곽·거점(4.1c)·시설(4.1e). 발밑 팀 색(S166)과 비행 적 그림자(I81)를 먼저 깔고, (층, 바닥선 y, 목록 순서)로 정렬해 그린다.
# 성곽 칸은 몸체(바닥선)와 앞층(바닥선 + 2) 두 조각이고, 성벽 위 유닛·대포와 기어오르는 적은 그 사이(바닥선 + 1)에 올려 그려 앞층이 발을 가린다(05 §2).
# 성벽 위 유닛의 발밑 팀 색만은 앞층 다음(바닥선 + 3)에 올려 그려 흉벽에 가리지 않게 한다(사용자 2026-10-20).
# 성벽·거점 그림에 가려진 땅 유닛과 시설은 끝에 한 번 더 그린다(_shade). 레벨·선택·효과 테두리는 _draw가 모든 몸통 뒤에 그린다
func _bodies() -> void:
	var all: Array = battle.units + battle.enemies
	var walls: Array = battle.castle.values() + battle.rubble.values()
	var blds: Array = battle.structures.values()
	for s in battle.structures.values():  # 옮겨 갈 칸의 대포 청사진(S176): 진행률 0인 미완성 대포로 그린다
		if s.dest != null:
			blds.append({"kind": s.kind, "cell": s.dest, "dest": null, "razed": 0.0, "complete": false, "progress": 0.0})
	_hits = hit_table(all + blds)
	var now := Time.get_ticks_msec() / 1000.0
	var was := residents(battle, now - 0.05)
	var ps := residents(battle, now)
	var n := all.size()
	var m := n + 2 * walls.size()  # 이 번호부터 시설, 그다음 거점
	var feet := m + blds.size() + 1  # 이 번호부터 성벽 위 유닛의 발밑 표시
	var folk := feet + n  # 이 번호부터 주민
	var keys := PackedInt64Array()
	for i in n:
		var x = all[i]
		var fly: bool = x.get("flying") == true
		if not x.on_wall:
			_feet_mark(x, i)
		else:
			keys.append((1 << 44) | ((int(roundf(x.pos.y) + 1) * CELL + 3 + 64) << 20) | (feet + i))
		if fly:
			draw_circle(_center(x.pos) + Vector2(0, CELL * 0.4), CELL * x.radius * 0.8, Color(0, 0, 0, 0.35))
		var y := (roundf(x.pos.y) + 1) * CELL + 1 if x.on_wall or x.get("climbed") else _center(x.pos).y
		keys.append(((2 if fly else 1) << 44) | ((int(y) + 64) << 20) | i)
	for j in walls.size():
		var line: int = (walls[j].cell.y + 1) * CELL
		keys.append((1 << 44) | ((line + 64) << 20) | (n + 2 * j))
		keys.append((1 << 44) | ((line + 2 + 64) << 20) | (n + 2 * j + 1))
	for j in blds.size():  # 시설은 바닥선, 성벽 위 대포는 성곽 몸체와 앞층 사이(바닥선 + 1)
		keys.append((1 << 44) | (((blds[j].cell.y + 1) * CELL + int(battle.castle.has(blds[j].cell)) + 64) << 20) | (m + j))
	keys.append((1 << 44) | (((battle.base.cell.y + 1) * CELL + 64) << 20) | (m + blds.size()))
	for k in ps.size():
		keys.append((1 << 44) | ((int(_center(ps[k]).y) + 64) << 20) | (folk + k))
	keys.sort()
	var next := {}
	for k in keys:
		var i: int = k & 0xFFFFF
		if i >= folk:  # 주민(4.1d): 움직이는 쪽을 보고 걷기 2위상. 자리가 연출이라(I46) 방향도 0.05초 전 자리와의 차로 구한다
			var v: Vector2 = ps[i - folk] - was[i - folk]
			var moving := v.length_squared() > 1e-8
			_frame(ART.resident, "walk" if moving else "idle", _four(v), int(now * 8.0) % 2 if moving else 0, _center(ps[i - folk]))
		elif i >= feet:
			_feet_mark(all[i - feet], i - feet)
		elif i == m + blds.size():  # 거점 망루: 마을 레벨(S99)마다 한 장
			var at := Vector2(battle.base.cell * CELL) + Vector2(-32, CELL - 72)
			draw_texture_rect_region(KEEP, Rect2(at, Vector2(80, 80)), Rect2(80 * (clampi(battle.village_level, 1, 2) - 1), 0, 80, 80))
		elif i >= m:
			_facility(blds[i - m])
		elif i >= n:
			_wall_piece(walls[(i - n) / 2], (i - n) % 2)
		else:
			_body(all[i], i, next)
	for i in n:
		var t := _shade(all[i])
		if t.a > 0.0:
			_body(all[i], i, next, t)
	for s in blds:  # 시설도 같은 규칙으로 덧그린다(사용자 2026-10-20)
		var t := _shade(s)
		if t.a > 0.0:
			_facility(s, t)
	_clip = -INF
	_seen = next

# 가려진 몸통을 덧그릴 색. 성곽 칸 바로 뒤 한 줄은 성벽 그림 윗변(_clip)보다 아래만 어두운 실루엣이고(S175), 거점 뒤는 통째로 40%다(S171).
# 성곽 칸 두 줄 뒤는 성벽 통로가 발만 가려 덧그리지 않는다(S175). 덧그리지 않으면 투명
func _shade(x) -> Color:
	_clip = -INF
	if not _behind(x):
		return Color.TRANSPARENT
	var c := Vector2i(_pos_of(x).round())
	if battle.castle.has(c + Vector2i(0, 1)):
		_clip = (c.y + 2) * CELL - 41.0
		return SHADE
	return Color.TRANSPARENT if battle.castle.has(c + Vector2i(0, 2)) else GHOST

# 그림 한 장을 원본과 같은 크기로 그린다. _clip보다 위 줄은 뺀다
func _region(tex: Texture2D, dst: Rect2, src: Rect2, tint: Color) -> void:
	var cut := clampf(_clip - dst.position.y, 0.0, dst.size.y)
	if cut < dst.size.y:
		draw_texture_rect_region(tex, dst.grow_side(SIDE_TOP, -cut), src.grow_side(SIDE_TOP, -cut), tint)

# 시설 하나(4.1e, 사용자 2026-10-20). 미완성은 청사진 위에 진행률만큼 아래부터 그림을 채우고, 철거 중은 거꾸로 위부터 청사진으로 돌아간다.
# 다 접힌 대포는 접힌 그림이다(I74). 성벽 위 대포(I44)는 올려 그린다
func _facility(s, tint := Color.WHITE) -> void:
	var folded: bool = s.dest != null and s.razed >= 1.0
	var f: Array = FAC["cannon_folded" if folded else s.kind]
	var t: float = 1.0 if folded else (1.0 - s.razed if s.complete else s.progress)
	var cut := roundi(f[2] - t * (f[2] - f[1]))  # 이 줄부터 아래는 그림, 위는 청사진
	var at := Vector2(s.cell * CELL) + Vector2(-16, CELL - 44 - _lift(s))
	var x: float = 48.0 * f[0]
	if cut > 0:
		_region(FACILITY, Rect2(at, Vector2(48, cut)), Rect2(x, 48, 48, cut), BLUEPRINT * tint)
	if cut < 48:
		_region(FACILITY, Rect2(at + Vector2(0, cut), Vector2(48, 48 - cut)), Rect2(x, cut, 48, 48 - cut), tint)

# 유닛·적 몸통 하나. 영웅은 8방향 시트, 그림이 있는 용병·적은 4방향 시트, 나머지는 원으로
func _body(x, i: int, next: Dictionary, tint := Color.WHITE) -> void:
	if _hits.get(x.get_instance_id(), [INF])[0] < FLASH:  # 피격 번쩍임(S177): 255배 modulate가 그림을 흰 실루엣으로 만든다(유닛 그림에 0인 채널이 없다). 배치는 끊기지 않는다
		tint *= Color(255, 255, 255)
	if ART.has(x.kind) and not x.get("is_hero"):
		_four_sprite(x, next, tint)
	elif i >= battle.units.size():
		draw_circle(_spot(x), CELL * x.radius, ENEMY_COLORS.get(x.kind, ENEMY_COLORS.basic) * tint)
	elif x.is_hero and ART.has(x.kind):
		_sprite(x, next, tint)
	else:
		draw_circle(_spot(x), CELL * x.radius, (HERO_COLORS.get(x.kind, COLORS.merc) if x.is_hero else COLORS.get(x.kind, COLORS.merc)) * tint)

# 성벽·거점 그림이 덮는 자리에 선 땅 유닛이나 시설: 성곽 칸 뒤 두 줄, 거점 칸 뒤 두 줄과 그 양옆(C1, 사용자 2026-10-20)
func _behind(x) -> bool:
	if x.get("on_wall") == true or x.get("flying") == true or x.get("climbed"):
		return false
	var c := Vector2i(_pos_of(x).round())
	if battle.castle.has(c + Vector2i(0, 1)) or battle.castle.has(c + Vector2i(0, 2)):
		return true
	var d: Vector2i = c - battle.base.cell
	return absi(d.x) <= 1 and d.y >= -2 and d.y < 0

# 발밑 팀 색(S166). i는 battle.units + battle.enemies 안의 번호다. 비행 적은 그림자 자리에 그린다
func _feet_mark(x, i: int) -> void:
	var foot := (_spot(x) if x.on_wall else _center(x.pos)) + (Vector2(0, CELL * 0.4) if x.get("flying") == true else Vector2.ZERO) + _lunge(x) + _flinch(x)
	draw_texture_rect_region(FEET, Rect2((foot + Vector2(-7, -2)).round(), Vector2(14, 6)), Rect2(14 * int(i >= battle.units.size()), 0, 14, 6))

# 성곽 칸 조각 하나(front 0 몸체, 1 앞층). 조각 맨 아랫줄이 바닥선 바로 아래 줄이다. 단계(S86)마다 그림이 다르고(사용자 2026-10-20),
# 열린 성문은 몸체 위에 통로 그늘을 겹친다(I67). 잔해(I88)는 몸체 자리에 돌무더기 하나다
func _wall_piece(b, front: int) -> void:
	var at := Vector2(b.cell.x * CELL, (b.cell.y + 1) * CELL - 41)
	if battle.rubble.get(b.cell) == b:
		if front == 0:
			draw_texture_rect_region(CASTLE, Rect2(at, Vector2(16, 42)), Rect2(0, 7 * 42, 16, 42))
		return
	var col := 0 if b.kind == "castle_wall" else (1 if b.open else 2)
	draw_texture_rect_region(CASTLE, Rect2(at, Vector2(16, 42)), Rect2(col * 16, (2 * (b.level - 1) + front) * 42, 16, 42))
	if front == 0 and col == 1:
		draw_texture_rect_region(CASTLE, Rect2(at, Vector2(16, 42)), Rect2(16, 6 * 42, 16, 42))

# 위로 올려 그리는 정도(맵 px). 성벽 위 유닛·대포는 흉벽 바로 뒤(앞면에서 바닥 3px)에 서고, 기어오르는 적은 오른 만큼 오른다(4.1c, 05 §2)
func _lift(x) -> float:
	var p := _pos_of(x)
	var top: bool = x.on_wall if x.get("pos") != null else (x.kind in battle.STRUCTURE_KINDS and battle.castle.has(x.cell))
	if top:
		return (p.y + 0.5) * CELL - ((roundf(p.y) + 1) * CELL - 3 - WALL_H)
	if x.get("climbed"):
		return (3 + WALL_H) * x.climbed / x.climb
	return 0.0

# 유닛·적·칸을 그릴 자리(맵 px, 칸 가운데)와 칸 사각형. 성벽 위에 있으면 올린다
func _spot(x) -> Vector2:
	return _center(_pos_of(x)) - Vector2(0, _lift(x))

func _box(s) -> Rect2:
	return Rect2(_rect(s.cell).position - Vector2(0, _lift(s)), Vector2(CELL, CELL))

# 영웅 한 명(S165): 움직이면 그쪽으로 걷기 4프레임(초당 8), 친 뒤 0.3초는 대상 쪽으로 공격 3프레임, 아니면 정지.
# 서 있으면 대상 쪽, 대상도 없으면 마지막 방향을 본다. 위치는 화면 픽셀로 반올림한다(insights/2026-10-20_render_spike.md X1)
func _sprite(x, next: Dictionary, tint := Color.WHITE) -> void:
	var id: int = x.get_instance_id()
	var seen = _seen.get(id)
	var v: Vector2 = x.pos - seen[0] if seen else Vector2.ZERO
	var dir: int = seen[1] if seen else 0
	var moving := v.length_squared() > 1e-8
	if moving:
		dir = _dir_of(v)
	elif x.target:
		dir = _dir_of(_pos_of(x.target) - x.pos)
	next[id] = [x.pos, dir]
	var a: Dictionary = ART[x.kind]
	var c := int(a.c)
	var anim := "idle"
	var col := 0
	var t := _ago(x)
	if x.target and t < 0.3:
		anim = "attack"
		col = clampi(int(t / 0.1), 0, 2)
	elif moving:
		anim = "walk"
		col = int(Time.get_ticks_msec() / 125.0) % 4
	var size := c * (2 if anim == "attack" else 1)  # 공격은 2배 캔버스(tools/art/hero.py)
	var at := _spot(x) + _flinch(x) - Vector2(a.anchor[0], a.anchor[1]) - Vector2.ONE * (size - c) / 2.0
	_region(UNITS, Rect2(at.round(), Vector2(size, size)), Rect2(col * size, a[anim] + dir * size, size, size), tint)

# 용병·적 하나(C 절충안, 4.1d. 4.1a M1·M6에서 C만 통과했다): 4방향 정지, 움직이면 걷기 2위상(초당 8), 친 뒤 0.08~0.22초는 공격 키 포즈.
# 근접은 그동안 대상 쪽으로 돌진한다(_lunge). 방향 고르기는 _sprite와 같다(tools/bench/view_draw.gd C)
func _four_sprite(x, next: Dictionary, tint := Color.WHITE) -> void:
	var id: int = x.get_instance_id()
	var seen = _seen.get(id)
	var v: Vector2 = x.pos - seen[0] if seen else Vector2.ZERO
	var dir: int = seen[1] if seen else 0
	var moving := v.length_squared() > 1e-8
	if moving:
		dir = _four(v)
	elif x.target:
		dir = _four(_pos_of(x.target) - x.pos)
	next[id] = [x.pos, dir]
	var a := _ago(x)  # 친 뒤 지난 시간(초)
	var anim := "idle"
	var col := 0
	if x.target and a >= 0.08 and a < 0.22:
		anim = "attack"
	elif moving:
		anim = "walk"
		col = int(Time.get_ticks_msec() / 125.0) % 2
	_frame(ART[x.kind], anim, dir, col, _spot(x) + _lunge(x) + _flinch(x), tint)

# 4방향 시트(tools/art/atlas.py FOUR)의 한 칸을 발밑 p에 그린다. 행은 S·E·N·W, 공격·쓰러짐은 2배 캔버스
func _frame(a: Dictionary, anim: String, dir: int, col: int, p: Vector2, tint := Color.WHITE) -> void:
	var c := int(a.c)
	var size := c * (2 if anim == "attack" or anim == "fall" else 1)
	var at := p - Vector2(a.anchor[0], a.anchor[1]) - Vector2.ONE * (size - c) / 2.0
	_region(UNITS, Rect2(at.round(), Vector2(size, size)), Rect2(col * size, a[anim] + dir * size, size, size), tint)

# 화면 방향 v → 4방향 시트 행(S·E·N·W)
func _four(v: Vector2) -> int:
	return posmod(roundi((90.0 - rad_to_deg(v.angle())) / 90.0), 4)

# 근접 용병·적의 돌진(px): 친 뒤 0.08초에 대상 쪽으로 LUNGE만큼 나가고 0.32초에 걸쳐 돌아온다. 발밑 표시도 함께 옮긴다.
# 영웅(8방향 공격 프레임, S165)과 원거리(사거리 2칸 초과)는 돌진하지 않는다
func _lunge(x) -> Vector2:
	var a := _ago(x)
	if x.get("is_hero") or (x.get("range") != null and x.range > 2.0) or not x.target or a >= 0.4:
		return Vector2.ZERO
	return (_pos_of(x.target) - x.pos).normalized() * LUNGE * (a / CONTACT if a < CONTACT else 1.0 - (a - CONTACT) / 0.32)

# 공격자 xs 가운데 방금 친 것의 대상 → [맞은 뒤 지난 시간(초), 공격자 → 대상 방향](S177). 여럿에게 맞으면 가장 최근 타격이다.
# 시뮬레이션에 상태를 두지 않고 공격자의 친 뒤 시간에서 구한다(06 §4)
func hit_table(xs: Array) -> Dictionary:
	var hits := {}
	for x in xs:
		if x.get("target") != null:
			var t: float = _ago(x) - _contact(x)
			var id: int = x.target.get_instance_id()
			if t >= 0.0 and t < FLINCH_BACK and t < hits.get(id, [INF])[0]:
				hits[id] = [t, (_pos_of(x.target) - _pos_of(x)).normalized()]
	return hits

# 친 뒤 보일 시간(초). 영웅이 치거나 맞은 타격은 닿은 때(_contact)에서 HITSTOP만큼 멈췄다가 늦게 흐른다(S177)
func _ago(x) -> float:
	var a: float = (x.attack_gap if x.get("attack_gap") != null else x.fire_gap) - x.cooldown
	var c := _contact(x)
	if a >= c and x.target != null and (x.get("is_hero") == true or x.target.get("is_hero") == true):
		return maxf(a - HITSTOP, c)
	return a

# 공격이 대상에 닿는 때(친 뒤 초). 근접(사거리 2칸 이하) 영웅·용병·적은 돌진 끝, 원거리와 타워는 쏜 때다
func _contact(x) -> float:
	return 0.0 if x.get("pos") == null or (x.get("range") != null and x.range > 2.0) else CONTACT

# 맞은 몸의 밀림(px, S177): 공격자 반대쪽으로 FLINCH만큼 밀렸다가 FLINCH_BACK에 걸쳐 돌아온다. 발밑 표시도 함께 옮긴다
func _flinch(x) -> Vector2:
	var h = _hits.get(x.get_instance_id())
	return h[1] * FLINCH * (1.0 - h[0] / FLINCH_BACK) if h else Vector2.ZERO

static func _feet() -> ImageTexture:
	var im := Image.create_empty(28, 6, false, Image.FORMAT_RGBA8)
	for t in 2:
		for y in 6:
			for x in 14:
				if pow((x + 0.5 - 7.0) / 7.0, 2) + pow((y + 0.5 - 3.0) / 3.0, 2) <= 1.0:
					im.set_pixel(14 * t + x, y, TEAM[t])
	return ImageTexture.create_from_image(im)

# 바닥(4.1b, 사용자 2026-10-20): 마을 칸의 꼭짓점은 흙, 나머지는 풀이다. 마을 아래 변의 흙은 들판 쪽으로 꼭짓점 0~2개만큼 불규칙하게 번진다.
# 칸마다 네 꼭짓점으로 16꼴 가운데 하나를 고르고, 변종(풀·흙 한 가지인 칸은 넷, 전환 칸은 셋) 가운데 하나를 고른다. 출현 지점에는 깃발을 얹는다
static func bake_ground(b) -> ImageTexture:
	var src := GROUND_TILES.get_image()
	var img := Image.create_empty(b.size.x * CELL, b.size.y * CELL, false, src.get_format())
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var spill := range(b.size.x + 1).map(func(_x): return rng.randi_range(0, 2))
	var vil: Rect2i = b.village
	var dirt := func(x: int, y: int) -> int:
		return int(vil.has_area() and x >= vil.position.x and x <= vil.end.x and y >= vil.position.y and y <= vil.end.y + spill[x])
	for y in b.size.y:
		for x in b.size.x:
			var k: int = dirt.call(x, y) + 2 * dirt.call(x + 1, y) + 4 * dirt.call(x, y + 1) + 8 * dirt.call(x + 1, y + 1)
			var whole := k == 0 or k == 15
			var v := rng.randi_range(0, 3 if whole else 2)
			var at := Vector2i(k, 0)
			if v > 0:
				at = Vector2i(v - 1 + (3 if k == 15 else 0), 1) if whole else Vector2i(k, 1 + v)
			img.blit_rect(src, Rect2i(at * CELL, Vector2i(CELL, CELL)), Vector2i(x, y) * CELL)
	for c in b.spawns:  # ponytail: 깃발도 바닥에 구워서 막 나온 적이 깃발 위에 그려진다. 거슬리면 깃발만 바닥선 정렬로 옮긴다
		img.blend_rect(src, Rect2i(Vector2i(6, 1) * CELL, Vector2i(CELL, CELL)), c * CELL)
	return ImageTexture.create_from_image(img)

# 장판 안쪽 무늬(S168). 색이 비슷한 장판 쌍(불길·용암, 블랙홀·늪, 화살비·독안개, 황금률·성역)을 무늬로 가른다. 무늬는 원 안에만 그린다
func _pattern(src: String, c: Vector2, r: float, col: Color) -> void:
	match src:
		"ignis_q":  # 불길: 위로 솟는 ^(8px 격자)
			for p in _grid(c, r - 4.0, 8.0):
				draw_polyline(PackedVector2Array([p + Vector2(-3, 2), p + Vector2(0, -2), p + Vector2(3, 2)]), col)
		"ignis_r":  # 용암: 가운데서 뻗는 지그재그 균열 6줄
			for k in 6:
				var d := Vector2.from_angle(k * TAU / 6.0 + 0.3)
				var pts := PackedVector2Array([c])
				for i in range(1, 5):
					pts.append(c + d * r * 0.22 * i + d.orthogonal() * (2.0 if i % 2 else -2.0))
				draw_polyline(pts, col)
		"ignis_e":  # 블랙홀: 나선 3바퀴
			var pts := PackedVector2Array()
			for i in 61:
				pts.append(c + Vector2.from_angle(i / 60.0 * 3.0 * TAU) * r * 0.9 * i / 60.0)
			draw_polyline(pts, col)
		"vesper_r":  # 늪: 물결 가로줄 4줄
			for k in 4:
				var y := (k - 1.5) * r / 2.5
				var half := sqrt(maxf(r * r - y * y, 0.0)) - 3.0
				var pts := PackedVector2Array()
				var x := -half
				while x <= half:
					pts.append(c + Vector2(x, y + 2.0 * sin(x * TAU / 8.0)))
					x += 2.0
				draw_polyline(pts, col)
		"sylvia_r":  # 화살비: 비스듬한 빗금(6px 간격)
			var s := -r + 3.0
			while s < r - 3.0:
				var h := sqrt(r * r - s * s) - 2.0
				var q := c + Vector2(1, 1).normalized() * s
				draw_line(q - Vector2(1, -1).normalized() * h, q + Vector2(1, -1).normalized() * h, col)
				s += 6.0
		"vesper_q":  # 독안개: 흩어진 거품(6px 격자)
			for p in _grid(c, r - 3.0, 6.0):
				draw_arc(p, 1.5, 0.0, TAU, 8, col)
		"chronos_e":  # 황금률: 햇살 12줄
			for k in 12:
				var d := Vector2.from_angle(k * TAU / 12.0)
				draw_line(c + d * r * 0.25, c + d * r * 0.9, col)
		"seraphina_w":  # 성역: 큰 십자
			draw_line(c - Vector2(0, r * 0.8), c + Vector2(0, r * 0.8), col, 2.0)
			draw_line(c + Vector2(-r * 0.5, -r * 0.3), c + Vector2(r * 0.5, -r * 0.3), col, 2.0)
		"chronos_r":  # 왜곡장: 안쪽 점선 고리 둘
			for rr in [r * 0.6, r * 0.3]:
				for k in 12:
					draw_arc(c, rr, k * TAU / 12.0, (k + 0.5) * TAU / 12.0, 4, col)
		"sylvia_e":  # 덫: X(10px 격자)
			for p in _grid(c, r - 3.0, 10.0):
				draw_line(p - Vector2(2, 2), p + Vector2(2, 2), col)
				draw_line(p + Vector2(-2, 2), p + Vector2(2, -2), col)

# 가운데 c에서 step 간격 격자점 가운데 반경 r 안의 점
static func _grid(c: Vector2, r: float, step: float) -> Array:
	var out := []
	var n := int(r / step)
	for i in range(-n, n + 1):
		for j in range(-n, n + 1):
			if Vector2(i, j).length() * step <= r:
				out.append(c + Vector2(i, j) * step)
	return out

# 화면 방향 v(y가 아래)의 시트 행: S, SE, E, NE, N, NW, W, SW(tools/art/render.py DIRS)
static func _dir_of(v: Vector2) -> int:
	return posmod(roundi((90.0 - rad_to_deg(v.angle())) / 45.0), 8)

# 조준 중(S147): 영웅 둘레에 시전 사거리, 커서에 범위(지점·범위), 영웅에서 커서 쪽으로 길이(방향)나 부채꼴(아이아스 Q), 에너지 성벽이 설 칸
func _aim_preview() -> void:
	if controls.aiming == "" or not controls.aim_hero:
		return
	var h = controls.aim_hero
	var sk: Dictionary = h.get(controls.aiming)
	var at: Vector2 = controls.mouse / CELL - Vector2(0.5, 0.5)
	draw_arc(_center(h.pos), CELL * battle.CAST_RANGE, 0.0, TAU, 64, Color(1, 1, 1, 0.3), 1.0)
	match sk.aim:
		"dir":
			var d: Vector2 = battle._toward(h, at)
			if sk.has("arc"):  # 아이아스 Q: 반경 radius·각도 arc의 부채꼴(S151)
				var half := deg_to_rad(sk.arc) / 2.0
				draw_arc(_center(h.pos), CELL * sk.radius, d.angle() - half, d.angle() + half, 24, Color.WHITE, 1.0)
				for side in [-half, half]:
					draw_line(_center(h.pos), _center(h.pos + d.rotated(side) * sk.radius), Color.WHITE, 1.0)
			else:
				draw_line(_center(h.pos), _center(h.pos + d * sk.get("radius", 40.0)), Color.WHITE, 1.0)  # 실비아 Q는 맵 끝까지
		"point":
			if sk.id == "bulwark":
				var d: Vector2 = battle._toward(h, at)
				var side := Vector2i(0, 1) if absf(d.x) > absf(d.y) else Vector2i(1, 0)
				for i in range(-1, 2):
					draw_rect(_rect(Vector2i(at.round()) + side * i), Color.WHITE, false, 1.0)
			else:
				draw_arc(_center(at), CELL * sk.get("radius", 0.5), 0.0, TAU, 48, Color.WHITE, 1.0)
		_:
			draw_arc(_center(at), CELL * 0.7, 0.0, TAU, 24, Color.WHITE, 1.0)

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

# 오라 반경 원(S113). 크로노스는 원 안쪽에 시계 문자판 눈금 12개를 더 그린다(S160). 컨셉 아트의 광륜(등 뒤 천문시계 고리)은
# 24px 스프라이트에서 뺐고 여기서 이펙트로 살린다(I152). 눈금은 크로노스 색(금)이고 12·3·6·9시가 길다. 불투명도 0.5·짧은 눈금 3px는
# 들판 위에서 흐리고 대각 눈금이 점으로 보였다. 원은 다른 영웅과 같은 하늘색이다. 금색으로 하면 반경이 같은 E 결계(S158 황금의 율법)와 테두리가 겹친다
func _aura_ring(h) -> void:
	var c := _center(h.pos)
	var r: float = CELL * h.aura.radius
	draw_arc(c, r, 0.0, TAU, 48, Color(0.6, 0.8, 1.0, 0.35), 1.0)
	if h.kind != "chronos":
		return
	var ticks := PackedVector2Array()
	for k in 12:  # k = 0이 3시. 화면 y가 아래라 k가 늘면 시계 방향으로 돈다
		var d := Vector2.from_angle(k * TAU / 12)
		ticks.append(c + d * r)
		ticks.append(c + d * (r - (7.0 if k % 3 == 0 else 4.0)))
	draw_multiline(ticks, Color(HERO_COLORS.chronos, 0.8), 1.0)
