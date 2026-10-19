extends SceneTree
# 4.1a 스파이크 가림 장면(art_direction_research/05 §5 C1~C5): 장면을 꾸며 시뮬레이션을 돌리고 정한 순간의 맵 화면을 저장한다.
# C5는 자동 판정이다: 600프레임 동안 같은 정렬 y에 선 두 유닛의 앞뒤가 바뀐 횟수를 센다(0이어야 한다).
# 사용: godot --path . -s res://tools/bench/scenes.gd -- <draw|nodes> <C1|C2|C3|C4|C5> <출력 폴더>

const Main := preload("res://src/main.gd")
const Battle := preload("res://src/sim/battle.gd")
const Controls := preload("res://src/ui/controls.gd")
const Sheets := preload("res://tools/bench/sheets.gd")
const VIEWS := {"draw": preload("res://tools/bench/view_draw.gd"), "nodes": preload("res://tools/bench/view_nodes.gd")}
const DT := 1.0 / 60.0

var sv: SubViewport
var view
var b
var scene: String
var out: String
var frame := 0
var shots := []  # 찍을 순간: [이름, 조건 Callable]
var watch  # C3·C4에서 지켜볼 적
var flips := 0  # C5
var _order := {}  # C5: [앞 id, 뒤 id] 쌍 → 지난 프레임에 앞이었나

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	scene = args[1]
	out = args[2].trim_suffix("/") + "/%s_%s_" % [args[0], scene]
	var box := Main.map_viewport(root)
	root.add_child(box)
	sv = box.get_child(0)
	b = Battle.new(Main.stage())
	b.gold = 1 << 30
	view = VIEWS[args[0]].new()
	view.battle = b
	view.controls = Controls.new(b, view.CELL)
	view.sheets = Sheets.new(true)
	sv.add_child(view)
	var cam := Camera2D.new()
	cam.zoom = Vector2(3, 3)
	cam.position = Vector2(8, 9.5) * 16
	sv.add_child(cam)
	match scene:
		"C1":  # 성벽 바로 뒤(8행)와 그 뒤(7행)를 걸어 지나간다. 겹치지 않게 출발 x를 벌린다
			for p in [[2, 8], [7, 7]]:
				b.order_move([b.place_merc("soldier", Vector2i(p[0], p[1]))], Vector2i(p[0] + 8, p[1]))
			shots = [["a", func(): return frame == 40], ["b", func(): return frame == 90]]
		"C2":  # 성벽 위에 선 유닛과 성벽 위를 걷는 유닛, 그 앞(10행)과 뒤(8행)
			b.place_merc("soldier", Vector2i(6, 9))
			b.order_move([b.place_merc("archer", Vector2i(9, 9))], Vector2i(13, 9))
			b.place_merc("soldier", Vector2i(6, 10))
			b.place_merc("archer", Vector2i(4, 8))
			shots = [["a", func(): return frame == 30], ["b", func(): return frame == 80]]
		"C3":  # 빠른 적이 성벽을 기어오른다: 시작·중간·끝, 올라선 뒤
			watch = b.spawn_enemy("fast", Vector2i(8, 13))
			shots = [["start", func(): return watch.climbed > 0.0], ["mid", func(): return watch.climbed >= watch.climb * 0.5],
				["end", func(): return watch.climbed >= watch.climb * 0.9], ["top", func(): return watch.on_wall]]
		"C4":  # 비행 적이 성벽 위를 지나간다
			watch = b.spawn_enemy("flying", Vector2i(3, 16))
			cam.position = Vector2(10, 9.5) * 16
			shots = [["front", func(): return watch.pos.y <= 10.5], ["over", func(): return watch.pos.y <= 9.0], ["behind", func(): return watch.pos.y <= 7.5]]
		"C5":  # 한 줄(12행)에 용병 8명을 붙여 세우고 적을 보내 밀치락거리게 한다
			for x in 8:
				b.place_merc("soldier", Vector2i(10 + x, 12))
			for x in 6:
				b.spawn_enemy("basic", Vector2i(10 + x, 20))

func _process(_d: float) -> bool:
	if scene == "C5":
		_c5()
		if frame >= 600:
			print("C5 flips ", flips, " (pairs ", _order.size(), ")")
			return true
	elif shots.is_empty() or frame > 1200:
		if not shots.is_empty():
			printerr("못 찍은 순간: ", shots.map(func(s): return s[0]))
		return true
	elif shots[0][1].call():
		sv.get_texture().get_image().save_png(out + shots.pop_front()[0] + ".png")
	b.step(DT)
	view.t = frame * DT
	if view.has_method("sync"):
		view.sync()
	view.queue_redraw()
	frame += 1
	return false

# 정렬 키의 y가 같은 유닛 쌍이 프레임마다 같은 앞뒤인지 본다
func _c5() -> void:
	var items: Array = view._items()
	items.sort_custom(func(p, q): return p[0] < q[0])
	var rank := {}
	for i in items.size():
		rank[items[i][4]] = i
	for i in items.size():
		for j in range(i + 1, items.size()):
			if int(items[i][6]) == int(items[j][6]) and items[i][5] == items[j][5]:  # 정렬 키는 y를 정수로 묶는다
				var key := [items[i][4], items[j][4]]
				key.sort()
				var first: bool = rank[key[0]] < rank[key[1]]
				if _order.has(key) and _order[key] != first:
					flips += 1
				_order[key] = first
