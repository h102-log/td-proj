extends SceneTree
# AI 관찰 플레이 하네스(WBS 3.4·5.5용 도구). 평가가 아니다 — 판정은 관찰자가 한다.
# 진입 씬(main.tscn)을 창으로 띄우고 실시간 진행을 끈 채, <폴더>/cmd.txt의 명령을 사람 입력과 같은 길(GUI → main → controls)로 넣는다.
# 명령을 다 하면 <폴더>/NNN.png(화면)와 state.json(상태 요약)을 쓰고 done에 NNN을 적는다. 보내기와 기다리기는 send.py가 한다.
#
#   godot --path . -s res://tools/play/play.gd -- <폴더> [seed]
#
# 명령(한 줄에 하나, 좌표는 기준 해상도 640×360. 캡처는 창 크기 1280×720이라 캡처에서 잰 좌표를 반으로 줄여 쓴다):
#   click x y · rclick x y · move x y(커서만 옮기고 툴팁이 뜰 만큼 프레임을 쉰다) · drag x1 y1 x2 y2(좌버튼) · pan x1 y1 x2 y2(휠 버튼 드래그) · wheel up|down x y
#   key 이름(Enter·Space·Escape·Q·F1·1·Minus …) · wait 초(게임 시간 진행, 단계가 바뀌면 거기서 멈춘다) · quit
# 게임 시간은 wait에서만 흐른다. seed를 주면 영입 목록·미션이 매번 같아서, log.txt를 새 폴더의 하네스에 통째로 보내면 같은 판이 재생된다.
# 실행마다 새 폴더를 쓴다(캡처 번호가 001부터 다시 시작하고 log.txt는 이어 붙는다).

const DT := 0.05  # autoplay.gd의 기본 한 걸음과 같다
const GAP := 3  # 명령 사이·캡처 전에 쉬는 프레임. HUD가 _process에서 팝업을 갱신하고 그려질 틈이다
const HOVER := 30  # move 뒤에 쉬는 프레임. 툴팁 지연(hud_tip.gd DELAY 0.2초)을 실시간으로 넘긴다

var dir: String
var seed = null
var started := false
var main
var queue := []
var gap := GAP
var shot := 0
var pending := false  # cmd.txt를 받았고 아직 캡처하지 않았다
var errors := []

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	dir = args[0].trim_suffix("/") + "/"
	if args.size() > 1:
		seed = int(args[1])
	main = load("res://src/main.tscn").instantiate()
	root.add_child(main)  # main._ready는 여기서 바로 돌지 않는다. 손대기는 _start()에서 한다

# main._ready 뒤에 한 번 부른다. 그 전에 set_process(false)를 하면 READY 알림이 _process를 다시 켠다
func _start() -> void:
	main.set_process(false)  # 실시간 step(main.gd _process)을 끈다. 생각하는 동안 게임 시간이 흐르지 않게
	main.view.get_viewport().get_camera_2d().set_process(false)  # 실제 마우스 위치로 하는 가장자리 스크롤(camera.gd _process)을 끈다
	if seed != null:
		var b = main.view.battle
		b._stage["seed"] = seed  # restart()가 이 씨앗으로 영입 목록·미션을 뽑는다. 새 도전도 같은 씨앗이다
		b.restart()
		b.begin_hiring()

func _process(_delta: float) -> bool:
	if not started:
		if not main.is_node_ready():
			return false
		started = true
		_start()
	main.view.queue_redraw()  # main._process에서 step만 빼고 그리기는 매 프레임 한다. 선택·놓기·드래그 사각형도 맵이 그린다
	if gap > 0:
		gap -= 1
		return false
	if not queue.is_empty():
		gap = GAP
		return _run(queue.pop_front())
	if pending:
		pending = false
		_save()
	elif FileAccess.file_exists(dir + "cmd.txt"):
		var text := FileAccess.get_file_as_string(dir + "cmd.txt")
		DirAccess.remove_absolute(dir + "cmd.txt")
		for line in text.split("\n", false):
			if line.strip_edges() != "":
				queue.append(line.strip_edges())
		var log := FileAccess.open(dir + "log.txt", FileAccess.READ_WRITE if FileAccess.file_exists(dir + "log.txt") else FileAccess.WRITE)
		log.seek_end()
		for line in queue:
			log.store_line(line)
		log.close()
		pending = true  # 명령이 없어도 지금 화면을 찍는다
	return false

# 명령 하나를 실행한다. true면 하네스를 끝낸다
func _run(line: String) -> bool:
	var a := line.split(" ", false)
	var n := []
	for s in a.slice(1):
		n.append(float(s))
	match [a[0], n.size()]:
		["click", 2], ["rclick", 2]:
			var p := Vector2(n[0], n[1])
			var button := MOUSE_BUTTON_LEFT if a[0] == "click" else MOUSE_BUTTON_RIGHT
			_motion(p, Vector2.ZERO, 0)
			_button(button, p, true)
			_button(button, p, false)
		["move", 2]:
			_motion(Vector2(n[0], n[1]), Vector2.ZERO, 0)
			gap = HOVER
		["drag", 4], ["pan", 4]:
			var p := Vector2(n[0], n[1])
			var q := Vector2(n[2], n[3])
			var button := MOUSE_BUTTON_LEFT if a[0] == "drag" else MOUSE_BUTTON_MIDDLE
			_motion(p, Vector2.ZERO, 0)
			_button(button, p, true)
			_motion(q, q - p, MOUSE_BUTTON_MASK_LEFT if button == MOUSE_BUTTON_LEFT else MOUSE_BUTTON_MASK_MIDDLE)
			_button(button, q, false)
		["wheel", 3]:  # n[0]은 up·down 자리라 0이다
			var button := MOUSE_BUTTON_WHEEL_UP if a[1] == "up" else MOUSE_BUTTON_WHEEL_DOWN
			_button(button, Vector2(n[1], n[2]), true)
			_button(button, Vector2(n[1], n[2]), false)
		["key", 1]:
			var code := OS.find_keycode_from_string(a[1])
			if code == KEY_NONE:
				errors.append("모르는 키: " + line)
			for pressed in [true, false]:
				var e := InputEventKey.new()
				e.keycode = code
				e.physical_keycode = code  # ui_accept(Enter·Space)가 어느 쪽으로 묶여 있어도 맞게
				e.pressed = pressed
				root.push_input(e, true)
		["wait", 1]:
			var b = main.view.battle
			var from: String = b.state
			for i in roundi(n[0] / DT):
				b.step(DT)
				main.view.tick(DT)  # main._process를 껐으므로 화면 시계·사건 목록도 여기서 흘린다(I170, I171)
				if b.state != from:  # 웨이브가 끝나거나 판이 끝나면 사람처럼 거기서 본다
					break
		["quit", 0]:
			_save()
			return true
		_:
			errors.append("모르는 명령: " + line)
	return false

func _motion(at: Vector2, rel: Vector2, mask: int) -> void:
	var e := InputEventMouseMotion.new()
	e.position = at
	e.global_position = at
	e.relative = rel
	e.button_mask = mask
	root.push_input(e, true)  # true: 좌표가 이미 기준 해상도(640×360) 좌표다. 창 배율(1280×720)을 거치지 않는다

func _button(index: int, at: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = index
	e.pressed = pressed
	e.position = at
	e.global_position = at
	root.push_input(e, true)

# 화면·상태를 쓰고 마지막에 done을 바꿔 넣는다. send.py는 done이 생기면 읽으므로 반쯤 쓴 파일을 보지 않게 이름을 바꿔 넣는다
func _save() -> void:
	shot += 1
	var name := "%03d" % shot
	root.get_texture().get_image().save_png(dir + name + ".png")
	var b = main.view.battle
	var state := {
		"shot": name, "state": b.state, "gold": b.gold,
		"round": b.round_index + 1, "wave": mini(b.wave_index + 1, b.waves.size()), "waves": b.waves.size(),
		"battle_time": b.tally.get("battle_time", 0.0), "base_hp": b.base.hp,
		"heroes": b.heroes.map(func(h): return {"kind": h.kind, "level": h.level, "hp": h.hp, "max_hp": h.max_hp, "alive": h.alive, "cell": [h.pos.x, h.pos.y]}),
		"mercs": b.units.filter(func(u): return not u.is_hero).size(),
		"enemies": b.enemies.size(),
	}
	_write(dir + "state.json", JSON.stringify(state))
	_write(dir + "done.tmp", "\n".join([name] + errors))
	DirAccess.remove_absolute(dir + "done")  # quit 직전 캡처처럼 send.py가 지우기 전에 다시 쓸 때
	DirAccess.rename_absolute(dir + "done.tmp", dir + "done")
	errors.clear()

func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()
