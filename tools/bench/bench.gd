extends SceneTree
# 4.1a 스파이크 측정(art_direction_research/05 §5 P1~P5): 그레이박스·①·② 화면에 유닛 N(적:아군 = 100:40)을 띄워
# 워밍업 뒤 600프레임의 프레임·그리기 시간과 draw call을 잰다. 시뮬레이션은 고정 간격이라 변형끼리 같은 판이다.
# 사용: godot --path . -s res://tools/bench/bench.gd -- <grey|draw|nodes> <N> [vsync=off] [atlas=packed|split] [sort=int|custom] [zoom=1] [out=파일]
#      X1 캡처: [snap=direct|engine|none] [cam=x,y] [frames=600] [shot=파일.png] — shot이면 몸통만 그린 맵 화면을 저장한다

const Main := preload("res://src/main.gd")
const Battle := preload("res://src/sim/battle.gd")
const Controls := preload("res://src/ui/controls.gd")
const Sheets := preload("res://tools/bench/sheets.gd")
const VIEWS := {"grey": preload("res://tools/bench/view_grey.gd"), "draw": preload("res://tools/bench/view_draw.gd"), "nodes": preload("res://tools/bench/view_nodes.gd")}
const WARMUP := 60
const REPATH_EVERY := 60  # 적 전원의 경로 재계산을 강제로 일으키는 간격(프레임, 05 §5 측정 조건)
const DT := 1.0 / 60.0
const FOES := ["basic", "basic", "basic", "basic", "fast", "armored", "flying"]

var opt := {"vsync": "off", "atlas": "packed", "sort": "int", "zoom": "1", "out": "", "snap": "direct", "cam": "320,320", "frames": "600", "shot": ""}
var view
var battle
var sv: SubViewport
var rid: RID
var n_foe := 0
var n_ally := 0
var allies := []
var frame := 0
var last := 0
var rows_step := 0  # 지난 battle.step 시간
var rows := []  # 프레임마다 [프레임, 시뮬레이션, _draw 전체, 몸통(정렬·그리기 또는 노드 동기화), 렌더 CPU, 렌더 GPU, draw call, 걷기 프레임 전환]
var rng := RandomNumberGenerator.new()

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var variant: String = args[0]
	var n := int(args[1])
	for a in args.slice(2):
		opt[a.get_slice("=", 0)] = a.get_slice("=", 1)
	n_foe = roundi(n * 100.0 / 140.0)
	n_ally = n - n_foe
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if opt.vsync == "on" else DisplayServer.VSYNC_DISABLED)
	var box := Main.map_viewport(root)
	root.add_child(box)
	sv = box.get_child(0)
	sv.snap_2d_transforms_to_pixel = opt.snap == "engine"
	battle = Battle.new(Main.stage())
	battle.gold = 1 << 30
	battle.merc_cap = 1 << 20
	allies = battle.MERC_KINDS.keys().filter(func(k): return k != "engineer")
	view = VIEWS[variant].new()
	view.battle = battle
	view.controls = Controls.new(battle, view.CELL)
	if variant != "grey":
		view.sheets = Sheets.new(opt.atlas == "packed")
		view.sort_mode = opt.sort
		view.snap = opt.snap == "direct"
		view.bodies_only = opt.shot != ""
	sv.add_child(view)
	var cam := Camera2D.new()  # 마우스로 움직이는 게임 카메라 대신 고정 카메라
	cam.zoom = Vector2.ONE * float(opt.zoom)
	cam.position = Vector2(float(opt.cam.get_slice(",", 0)), float(opt.cam.get_slice(",", 1)))  # 기본 (320, 320): 성벽(9행)부터 맵 아래 끝까지
	sv.add_child(cam)
	rid = sv.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	rng.seed = 7

func _process(_delta: float) -> bool:
	var now := Time.get_ticks_usec()
	if frame > WARMUP:
		rows.append([now - last, rows_step, view.draw_us, view.get("sync_us") if view.get("sync_us") != null else view.body_us,
			RenderingServer.viewport_get_measured_render_time_cpu(rid), RenderingServer.viewport_get_measured_render_time_gpu(rid),
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), int(view.t * 8.0) != int((view.t - DT) * 8.0)])
	last = now
	if frame >= WARMUP + int(opt.frames):
		_finish()
		return true
	_top_up()
	if frame % REPATH_EVERY == 0:
		battle._repath = true
	var t0 := Time.get_ticks_usec()
	battle.step(DT)
	rows_step = Time.get_ticks_usec() - t0
	view.t = frame * DT
	if view.has_method("sync"):
		view.sync()
	view.queue_redraw()
	frame += 1
	return false


# 죽은 만큼 다시 채워 N을 지킨다. 적은 아래쪽(22~31행), 아군은 성벽 앞(11~18행)
func _top_up() -> void:
	while battle.enemies.size() < n_foe:
		battle.spawn_enemy(FOES[rng.randi() % FOES.size()], Vector2i(rng.randi_range(0, 39), rng.randi_range(22, 31)))
	var tries := 0
	while battle.units.size() < n_ally and tries < 1000:
		battle.place_merc(allies[rng.randi() % allies.size()], Vector2i(rng.randi_range(0, 39), rng.randi_range(11, 18)))
		tries += 1

func _finish() -> void:
	var names := ["frame_us", "step_us", "draw_us", "body_us", "render_cpu_ms", "render_gpu_ms", "draw_calls"]
	var out := {"variant": OS.get_cmdline_user_args()[0], "n": n_foe + n_ally, "opt": opt,
		"renderer": RenderingServer.get_current_rendering_method(), "adapter": RenderingServer.get_video_adapter_name(),
		"debug_build": OS.is_debug_build(), "frames": rows.size()}
	for i in names.size():
		out[names[i]] = _stats(rows.map(func(r): return float(r[i])))
	# 05 §5 P5. 프레임 전체 시간은 시뮬레이션 변동(경로 재계산)에 묻혀서 그리기 몫(몸통 + 렌더 CPU)으로 잰다
	var cost := func(r): return float(r[3]) + r[4] * 1000.0
	var sw := rows.filter(func(r): return r[7]).map(cost)
	var calm := rows.filter(func(r): return not r[7]).map(cost)
	out["p5_switch_minus_median_us"] = _stats(sw).median - _stats(calm).median
	if opt.shot != "":
		sv.get_texture().get_image().save_png(opt.shot)
	var text := JSON.stringify(out, "  ")
	print(text)
	if opt.out != "":
		var f := FileAccess.open(opt.out, FileAccess.WRITE)
		f.store_string(text)

static func _stats(a: Array) -> Dictionary:
	var s := a.duplicate()
	s.sort()
	if s.is_empty():
		return {}
	var q := func(p: float): return s[mini(s.size() - 1, int(p * s.size()))]
	return {"median": q.call(0.5), "p95": q.call(0.95), "p99": q.call(0.99), "max": s[-1]}
