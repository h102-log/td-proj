extends "res://src/ui/battle_view.gd"
# 4.1a 스파이크 ①(art_direction_research/05 §1): _draw() 하나에서 성벽·유닛·적을 (층, 바닥선 y, 순서)로 정렬해 시트에서 그린다.
# 그림이 없는 용병·적도 재려고 시트를 번호 순으로 돌려 쓴다(측정용 대역)

const Sheets := preload("res://tools/bench/sheets.gd")
const WALL_H := 24  # 성벽 앞면 높이(px, 4.0 확정값)
const FLY_H := 8  # 비행 높이(px). ponytail: 측정용 임시값, 4.1d에서 정한다
const LUNGE := 6.0  # B·C 근접 돌진(px, 06 §4. tools/art/viewer.gd와 같다)

var sheets
var sort_mode := "int"  # "int": 키를 정수 하나로 묶어 sort() / "custom": sort_custom에 비교 함수(05 §5 순서와 고르는 법)
var snap := true  # 그리는 위치를 직접 반올림한다(05 §3, X1)
var t := 0.0  # 애니메이션 시계(초). 벤치가 고정 간격으로 올린다
var bodies_only := false  # 바닥·오버레이 없이 몸통만(X1 캡처에서 선·막대가 색 경계를 흐리지 않게)
var method := "A"  # 유닛 방식(06 §1): "A" 8방향 프레임, "B" 림월드(4방향 정지 + 돌진), "C" 절충(B + 걷기 2위상 + 공격 키 포즈)
var plain := false  # 바닥·발밑 팀 색·몸통만. 공격선·마나·레벨·효과 테두리를 빼고 그림만으로 읽히는지 본다(M1·M6, tools/bench/m1.gd)
var stand_ins: Array = range(Sheets.WHO.size())  # 영웅이 아닌 유닛이 번호 순으로 돌려 쓸 시트
var foe_sheet := -1  # 0 이상이면 적 전원을 이 시트로 그린다(M6)
var _no := {}  # 유닛 → 처음 그린 순서. 대역 시트를 고른다(인스턴스 id는 실행마다 달라 같은 판도 그림이 바뀐다)
var draw_us := 0  # 지난 _draw 전체
var body_us := 0  # 지난 _bodies(정렬 + 그리기 호출)

func _ready() -> void:
	RenderingServer.canvas_item_set_custom_rect(get_canvas_item(), true, Rect2(Vector2.ZERO, Vector2(battle.size * CELL)))  # 05 §2 ①

func _draw() -> void:
	var t0 := Time.get_ticks_usec()
	if bodies_only:
		_bodies()
	elif plain:
		_plain()
	else:
		super()
	draw_us = Time.get_ticks_usec() - t0

func _plain() -> void:
	var map := Vector2(battle.size) * CELL
	draw_rect(Rect2(Vector2.ZERO, map), COLORS.field)
	draw_rect(Rect2(Vector2(battle.village.position) * CELL, Vector2(battle.village.size) * CELL), COLORS.village)
	for x in battle.size.x + 1:
		draw_line(Vector2(x * CELL, 0), Vector2(x * CELL, map.y), COLORS.grid)
	for y in battle.size.y + 1:
		draw_line(Vector2(0, y * CELL), Vector2(map.x, y * CELL), COLORS.grid)
	var all: Array = battle.units + battle.enemies
	for i in all.size():  # 발밑 팀 색(S166, battle_view._bodies와 같은 자리)
		var foot := _center(all[i].pos) + (Vector2(0, CELL * 0.4) if all[i].get("flying") == true else Vector2.ZERO)
		draw_texture_rect_region(FEET, Rect2((foot + _lunge(all[i]) + Vector2(-7, -2)).round(), Vector2(14, 6)), Rect2(14 * int(i >= battle.units.size()), 0, 14, 6))
	_bodies()

func _castle() -> void:
	pass  # 성벽은 _bodies의 정렬에 넣는다

func _bodies() -> void:
	var t0 := Time.get_ticks_usec()
	var items := _items()
	if sort_mode == "custom":
		items.sort_custom(func(a, b): return a[0] < b[0])
		for it in items:
			draw_texture_rect_region(it[1], Rect2(it[3], it[2].size), it[2])
	else:
		var keys := PackedInt64Array()
		for it in items:
			keys.append(it[0])
		keys.sort()
		for k in keys:
			var it: Array = items[k & 0xFFFFF]
			draw_texture_rect_region(it[1], Rect2(it[3], it[2].size), it[2])
	body_us = Time.get_ticks_usec() - t0

# 그릴 것: [정렬 키, 텍스처, 영역, 그릴 위치, 노드 이름, 층, 정렬 y]. 키 = 층 | 정렬 y | 목록 순서(같은 y의 앞뒤가 프레임마다 같다, C5)
# 층: 1 지상(유닛·성벽), 2 비행. 성벽 칸은 몸체 = 바닥선, 성벽 위 유닛 = 바닥선 + 1, 흉벽·앞면 = 바닥선 + 2(05 §2, 아트 시험 «남은 일»)
func _items() -> Array:
	var out := []
	var next := {}
	for u in battle.units:
		_unit(out, next, u)
	for e in battle.enemies:
		_unit(out, next, e, true)
	_seen = next
	for b in battle.castle.values():
		var strip: String = "castle_wall" if b.kind == "castle_wall" else ("open" if b.open else "gate")
		var line := float((b.cell.y + 1) * CELL)
		var at := Vector2(b.cell.x * CELL, line - 100)  # 성벽 그림의 원점 픽셀 (4, 100)
		_add(out, "w%d" % b.cell.x, 1, line, sheets.wall("wall", strip), at)
		_add(out, "f%d" % b.cell.x, 1, line + 2, sheets.wall("front", strip), at)
	return out

func _add(out: Array, name: String, layer: int, y: float, tr: Array, at: Vector2) -> void:
	out.append([(layer << 44) | ((int(y) + 64) << 20) | out.size(), tr[0], tr[1], at, name, layer, y])

# 움직이면 걷기(그 방향), 친 직후 0.3초는 공격 3프레임(대상 쪽), 아니면 정지. 그림 칸은 영웅이면 그 영웅, 아니면 번호 순 대역
# B·C(method)는 4방향이고, 친 직후 대상 쪽으로 돌진한다. C는 걷기 2위상과 돌진 끝의 공격 키 포즈를 더한다(tools/art/viewer.gd unit_panel)
func _unit(out: Array, next: Dictionary, x, foe := false) -> void:
	var id: int = x.get_instance_id()
	var seen = _seen.get(id)
	var v: Vector2 = x.pos - seen[0] if seen else Vector2.ZERO
	var dir: int = seen[1] if seen else 0
	var moving := v.length_squared() > 1e-8
	var four := method != "A"
	if moving:
		dir = _four(v) if four else Sheets.dir_of(v)
	elif x.target:
		dir = _four(_pos_of(x.target) - x.pos) if four else Sheets.dir_of(_pos_of(x.target) - x.pos)
	next[id] = [x.pos, dir]
	if not _no.has(id):
		_no[id] = _no.size()
	var anim := "idle"
	var col := 0
	var lunge := _lunge(x) if four else Vector2.ZERO  # A에서 함수 호출을 아낀다(벤치 몸통 시간이 10% 늘었다)
	var a: float = x.attack_gap - x.cooldown  # 친 뒤 지난 시간(초)
	if method == "A":
		if x.target and a < 0.3:
			anim = "attack"
			col = clampi(int(a / 0.1), 0, 2)
		elif moving:
			anim = "walk"
			col = int(t * 8.0) % 4
	elif lunge != Vector2.ZERO:
		if method == "C" and a >= 0.08 and a < 0.22:
			anim = "attack"
			col = 1
	elif moving and method == "C":
		anim = "walk"
		col = int(t * 8.0) % 2
	var s: int = Sheets.WHO.find(x.kind) if x.get("is_hero") else (foe_sheet if foe and foe_sheet >= 0 else stand_ins[_no[id] % stand_ins.size()])
	var foot := _center(x.pos)
	var layer := 1
	var key := foot.y
	var lift := 0.0
	var line := (roundf(x.pos.y) + 1) * CELL
	if x.get("flying"):
		layer = 2
		lift = FLY_H
	elif x.on_wall:
		key = line + 1
		lift = foot.y - (line - 3 - WALL_H)  # 흉벽 바로 뒤(앞면에서 바닥 3px)에 서고 앞면 높이만큼 올린다(tools/art/viewer.gd page_wall)
	elif x.get("climbed"):  # 기어오르는 중: 성벽 위 유닛과 같은 층에서 오른 만큼 올린다(05 §2)
		key = line + 1
		lift = (3 + WALL_H) * x.climbed / x.climb
	var c: float = sheets.sets[s].c
	var at: Vector2 = foot - sheets.sets[s].anchor - Vector2(0, lift) - (Vector2.ONE * c / 2.0 if anim == "attack" else Vector2.ZERO) + lunge
	_add(out, str(id), layer, key, sheets.frame(s, anim, dir, col), at.round() if snap else at)

# B·C의 시트 행: 화면 방향 v를 4방향(S·E·N·W)으로 묶는다
func _four(v: Vector2) -> int:
	return posmod(roundi((90.0 - rad_to_deg(v.angle())) / 90.0), 4) * 2

# B·C 돌진(px): 친 뒤 0.08초에 대상 쪽으로 6px 나가고 0.32초에 걸쳐 돌아온다. 발밑 표시도 몸과 함께 옮긴다(tools/art/viewer.gd의 그림자처럼)
func _lunge(x) -> Vector2:
	var a: float = x.attack_gap - x.cooldown
	if method == "A" or not x.target or a >= 0.4:
		return Vector2.ZERO
	return (_pos_of(x.target) - x.pos).normalized() * LUNGE * (a / 0.08 if a < 0.08 else 1.0 - (a - 0.08) / 0.32)
