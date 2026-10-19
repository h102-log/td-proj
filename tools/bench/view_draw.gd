extends "res://src/ui/battle_view.gd"
# 4.1a 스파이크 ①(art_direction_research/05 §1): _draw() 하나에서 성벽·유닛·적을 (층, 바닥선 y, 순서)로 정렬해 시트에서 그린다.
# 그림이 없는 용병·적도 재려고 시트를 번호 순으로 돌려 쓴다(측정용 대역)

const Sheets := preload("res://tools/bench/sheets.gd")
const WALL_H := 24  # 성벽 앞면 높이(px, 4.0 확정값)
const FLY_H := 8  # 비행 높이(px). ponytail: 측정용 임시값, 4.1d에서 정한다

var sheets
var sort_mode := "int"  # "int": 키를 정수 하나로 묶어 sort() / "custom": sort_custom에 비교 함수(05 §5 순서와 고르는 법)
var snap := true  # 그리는 위치를 직접 반올림한다(05 §3, X1)
var t := 0.0  # 애니메이션 시계(초). 벤치가 고정 간격으로 올린다
var bodies_only := false  # 바닥·오버레이 없이 몸통만(X1 캡처에서 선·막대가 색 경계를 흐리지 않게)
var draw_us := 0  # 지난 _draw 전체
var body_us := 0  # 지난 _bodies(정렬 + 그리기 호출)
var _seen := {}  # 유닛·적 → [지난 위치, 방향]

func _ready() -> void:
	RenderingServer.canvas_item_set_custom_rect(get_canvas_item(), true, Rect2(Vector2.ZERO, Vector2(battle.size * CELL)))  # 05 §2 ①

func _draw() -> void:
	var t0 := Time.get_ticks_usec()
	if bodies_only:
		_bodies()
	else:
		super()
	draw_us = Time.get_ticks_usec() - t0

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
		_unit(out, next, e)
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
func _unit(out: Array, next: Dictionary, x) -> void:
	var id: int = x.get_instance_id()
	var seen = _seen.get(id)
	var v: Vector2 = x.pos - seen[0] if seen else Vector2.ZERO
	var dir: int = seen[1] if seen else 0
	var moving := v.length_squared() > 1e-8
	if moving:
		dir = Sheets.dir_of(v)
	elif x.target:
		dir = Sheets.dir_of(_pos_of(x.target) - x.pos)
	next[id] = [x.pos, dir]
	var anim := "idle"
	var col := 0
	if x.target and x.cooldown > x.attack_gap - 0.3:
		anim = "attack"
		col = clampi(int((x.attack_gap - x.cooldown) / 0.1), 0, 2)
	elif moving:
		anim = "walk"
		col = int(t * 8.0) % 4
	var s: int = Sheets.WHO.find(x.kind) if x.get("is_hero") else id % Sheets.WHO.size()
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
	var at: Vector2 = foot - sheets.sets[s].anchor - Vector2(0, lift) - (Vector2.ONE * c / 2.0 if anim == "attack" else Vector2.ZERO)
	_add(out, str(id), layer, key, sheets.frame(s, anim, dir, col), at.round() if snap else at)
