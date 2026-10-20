extends SceneTree
# M1·M6(art_direction_research/06 §2): 적 100·아군 40 난전에서 주인공 하나가 누구를 치는지 그림만으로 읽히는지 볼 3초 장면을 찍는다.
# 주인공은 M1이 아이아스(유일한 근접 영웅), M6이 무기 없는 몸통 적(tools/art/brute.py) 하나다. 줌 2, 공격선 등 오버레이 없음(사용자 2026-10-20).
# 시뮬레이션은 그리기와 상관없어서 A·B·C가 같은 판이다. 먼저 그림 없이 돌려 구간을 고르고(_pick), 같은 판을 다시 돌려 그 구간을 30fps로 찍는다.
# 사용: godot --path . -s res://tools/bench/m1.gd -- <A|B|C> <m1|m6> <출력 폴더>  → <폴더>/<m1|m6>_<안>/000.png…와 answer.json. GIF는 tools/bench/m1_gif.py

const Main := preload("res://src/main.gd")
const Battle := preload("res://src/sim/battle.gd")
const Controls := preload("res://src/ui/controls.gd")
const Sheets := preload("res://tools/bench/sheets.gd")
const ViewDraw := preload("res://tools/bench/view_draw.gd")
const DT := 1.0 / 60.0
const N_FOE := 100
const N_ALLY := 40
const WARMUP := 300  # 이보다 앞은 구간으로 쓰지 않는다(난전이 생기기 전)
const SEARCH := 3600  # 구간을 찾는 범위(프레임)
const LEN := 180  # 3초
const ZOOM := 2
const FOES := ["basic", "basic", "basic", "basic", "fast", "armored"]  # bench.gd에서 비행을 뺐다. 그림이 없어 사람 대역이 발밑 표시와 떨어져 떠 보인다
const HALF := Vector2(320, 180) / ZOOM  # 화면 절반(월드 px)

var b
var rng := RandomNumberGenerator.new()
var allies := []
var ids := {}  # 객체 → 처음 나온 순서. 같은 판이면 두 번 돌려도 같다
var objs := {}  # 순서 → 객체
var mode: String
var dir: String
var start := -1  # 구간 첫 프레임(그 프레임의 step 뒤 상태)
var subject := -1
var target := -1
var cam_at := Vector2.ZERO
var sv: SubViewport
var view
var cam: Camera2D
var frame := 0
var shots := []  # 찍은 프레임마다 [주인공 화면 좌표, 대상 화면 좌표]
var hits := []  # 주인공이 친 순간(찍은 프레임 번호)
var first := {}  # 첫 프레임의 모든 유닛: 순서 → [화면 x, 화면 y, 적이면 1](판정 때 짚은 점에서 가장 가까운 유닛을 찾는다)

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	mode = args[1]
	dir = args[2].trim_suffix("/") + "/%s_%s/" % [mode, args[0]]
	DirAccess.make_dir_recursive_absolute(dir)
	_pick()
	if start < 0:
		printerr("구간을 못 찾음")
		quit(1)
		return
	_reset()
	var box := Main.map_viewport(root)
	root.add_child(box)
	sv = box.get_child(0)
	view = ViewDraw.new()
	view.battle = b
	view.controls = Controls.new(b, view.CELL)
	view.sheets = Sheets.new(true)
	view.method = args[0]
	view.plain = true
	view.stand_ins = range(1, Sheets.WHO.size() - 1)  # 아이아스(0)는 주인공만 쓰고, 기사(hero)는 M6 몸통 적과 거의 같아서 뺀다
	if mode == "m6":
		view.foe_sheet = Sheets.WHO.size() + Sheets.EXTRA.find("brute")
	sv.add_child(view)
	cam = Camera2D.new()
	cam.zoom = Vector2.ONE * ZOOM
	cam.position = cam_at
	sv.add_child(cam)

func _process(_d: float) -> bool:
	var i := frame - 1 - start  # 지금 화면은 지난 프레임의 step 뒤 상태다(scenes.gd와 같다)
	if i >= LEN:
		_finish()
		return true
	if i >= 0:
		var x = objs[subject]
		if is_equal_approx(x.cooldown, x.attack_gap):
			hits.append(i / 2)
		if x.target != objs[target]:
			printerr("대상이 _pick과 다름: 프레임 ", frame)
		if i == 0:
			for o in b.units + b.enemies:
				first[ids[o]] = _screen(o.pos) + [int(o in b.enemies)]
		if i % 2 == 0:
			sv.get_texture().get_image().save_png(dir + "%03d.png" % (i / 2))
			shots.append([_screen(x.pos), _screen(objs[target].pos)])
	_step()
	frame += 1
	view.t = frame * DT
	view.queue_redraw()
	return false

func _reset() -> void:
	var stage := Main.stage()
	stage["hero_start"] = Vector2i(20, 15)  # 아군 줄(11~18행) 가운데
	stage["seed"] = 7  # battle.gd의 _rng(영입소·미션)·_luck(치명타·기절) 씨앗. 없으면 실행마다 판이 달라져 A·B·C가 다른 판이 됐다
	b = Battle.new(stage)
	b.gold = 1 << 30
	b.merc_cap = 1 << 20
	allies = b.MERC_KINDS.keys().filter(func(k): return k != "engineer")
	rng.seed = 7
	ids = {}
	objs = {}

# bench.gd _top_up과 같은 채우기(비행 적 없음). 적은 아래쪽(22~31행), 아군은 성벽 앞(11~18행)
func _step() -> void:
	while b.enemies.size() < N_FOE:
		b.spawn_enemy(FOES[rng.randi() % FOES.size()], Vector2i(rng.randi_range(0, 39), rng.randi_range(22, 31)))
	var tries := 0
	while b.units.size() < N_ALLY and tries < 1000:
		b.place_merc(allies[rng.randi() % allies.size()], Vector2i(rng.randi_range(0, 39), rng.randi_range(11, 18)))
		tries += 1
	b.step(DT)
	for x in b.units + b.enemies:
		if not ids.has(x):
			objs[ids.size()] = x
			ids[x] = ids.size()

# 그림 없이 돌려 가장 이른 구간을 고른다: 3초 동안 대상이 그대로이고(M6은 아군 유닛만) 2번 이상 치며, 구간 첫 프레임에 대상 둘레 2칸 안에 다른 유닛이 3명 이상
func _pick() -> void:
	_reset()
	var runs := {}  # 후보 → [대상, 대상을 잡은 프레임, 친 프레임들]
	var snaps := []  # 프레임마다 {순서: 위치}
	for f in SEARCH:
		_step()
		var snap := {}
		for x in b.units + b.enemies:
			snap[ids[x]] = x.pos
		snaps.append(snap)
		for x in (b.heroes if mode == "m1" else b.enemies):
			var k: int = ids.get(x, -1)
			if not x.alive or not ids.has(x.target) or (mode == "m6" and x.target not in b.units):
				runs.erase(k)
				continue
			var t: int = ids[x.target]
			if not runs.has(k) or runs[k][0] != t:
				runs[k] = [t, f, []]
			var r: Array = runs[k]
			if is_equal_approx(x.cooldown, x.attack_gap):
				r[2].append(f)
			var s := f + 1 - LEN
			if s < WARMUP or s < r[1] or r[2].filter(func(h): return h >= s).size() < 2:
				continue
			var crowd := 0
			for o in snaps[s]:
				if o != k and o != t and snaps[s][o].distance_to(snaps[s][t]) <= 2.0:
					crowd += 1
			if crowd >= 3:
				start = s
				subject = k
				target = t
				cam_at = (snaps[s][k] * 16 + Vector2(8, 8)).clamp(HALF, Vector2(b.size) * 16 - HALF)
				print("구간 ", s, "~", f, " 주인공 ", k, " (", x.kind, ") 대상 ", t, " 둘레 ", crowd, "명, 친 프레임 ", r[2])
				return

func _screen(p: Vector2) -> Array:
	var v := ((p * 16 + Vector2(8, 8)) - cam_at) * ZOOM + HALF * ZOOM
	return [roundi(v.x), roundi(v.y)]

func _finish() -> void:
	var f := FileAccess.open(dir + "answer.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"mode": mode, "start": start, "subject": subject, "subject_kind": objs[subject].kind, "target": target,
		"fps": 30, "size": [640, 360], "hits": hits, "first": first, "frames": shots.map(func(s): return {"subject": s[0], "target": s[1]})}, "  "))
	print("찍음 ", shots.size(), "장 → ", dir)
