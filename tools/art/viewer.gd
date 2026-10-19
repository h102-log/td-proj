extends SceneTree
# 4.0 아트 시험 보기 화면(insights/2026-10-18_art_trial.md). 실행: godot --path . -s res://tools/art/viewer.gd
# 쪽: ←/→ 또는 1~9·0(10쪽). 보기: A 각도 45/60, O 외곽선 B/D, P 팔레트, S 유닛 크기 16/24/32, H 성벽 높이, T 타일 보기, R 처음부터
# 화면: 휠 줌 1~3배, 우클릭·휠 버튼으로 끌어 이동, Space 시점 처음으로. 인자 shots: 쪽마다 캡처를 art/trial/preview/view_N.png로 남기고 끝낸다

const DIRS := ["S", "SE", "E", "NE", "N", "NW", "W", "SW"]
const STEP := 0.285  # 한 걸음 보폭(모델 단위), tools/art/hero.py WALK
const SPEED := 48.0  # 기사 3칸/초 × 16px
const LUNGE := 6.0  # 근접 돌진 6px(06 §4)
const KB := 3.0  # 피격 밀림 3px, 0.34초에 복귀
const FLASH := 2.0 / 60.0  # 흰 번쩍임 2프레임
const SHADOW := Vector2(5, 2)  # 발밑 그림자 타원(10×4)의 중심
const PAGES := [
	["정지 8방향: 변형 8개", "H8 방향 일관성, 팔레트·외곽선·각도 고르기. 행 = 각도 × 외곽선 × 팔레트, 열 = 남·남동·동·북동·북·북서·서·남서"],
	["실루엣", "H1: 5초 안에 «무기 든 사람»으로 읽히나. 행 = 16·24·32px"],
	["걷기 제자리 8fps", "H6: 절뚝거림이 보이나. 행 = 16·24·32px"],
	["걷기 이동", "H6: 제자리 미끄러짐이 보이나. 3칸/초, 걸은 거리만큼 프레임을 넘긴다. 사각형 안 가로줄만 8fps 고정"],
	["공격·쓰러짐(8방향 프레임안)", "공격 3프레임을 1초마다, 쓰러짐 5프레임. 공격·쓰러짐은 2배 캔버스"],
	["유닛 방식 세 안", "M3 움직임 느낌. A 8방향 프레임 / B 림월드 / C 절충. 걷기 → 허수아비 3번 → 맞고 쓰러짐, 12초 반복"],
	["대각 이동 8방향 대 4방향", "M5 방향 구분. 같은 걷기 프레임을 8방향(왼쪽)과 4방향(오른쪽)으로 고른다"],
	["바닥 타일", "T2 이음매·반복 무늬, T3 terrain 칠하기. T로 보기 바꿈: 들판 / 풀·흙 8×8 반복 / 아틀라스"],
	["성벽 높이", "H로 앞면 16·24·32px. 왼쪽 문 열림·오른쪽 문 닫힘. 성벽 뒤 마을 1·2줄, 성벽 위(서 있기·걷기)"],
	["크로노스", "정지·걷기 제자리 8fps·공격·쓰러짐·걷기 이동. 열 = 남·남동·동·북동·북·북서·서·남서. 45° D f24p 24px만 굽어서 A·O·P·S는 듣지 않는다"],
]
const DEFAULT_ZOOM := [1, 1, 1, 2, 1, 2, 2, 2, 2, 1]
const TOP := 34.0  # 위 안내 띠 높이

var base: String  # art/trial/ 절대 경로
var who := "hero"  # 시트 폴더(art/trial/<who>/). 크로노스 쪽에서만 "chronos"
var opt := {"elev": 45, "outline": "D", "pal": "f24p", "n": 24, "wall": 24, "tiles": 0}
var page := 0
var zoom := 1
var world: Node2D
var hud: Label
var actors: Array[Callable] = []
var t := 0.0
var cache := {}
var fits := {}
var black: Shader
var flash: Shader
var shadow_tex: ImageTexture
var dragging := false
var shots := false
var frame := 0

class Keys extends Node:
	var on_event: Callable
	func _unhandled_input(e: InputEvent) -> void:
		on_event.call(e)

class Dummy extends Node2D:
	var white := false
	var kb := Vector2.ZERO
	func _draw() -> void:
		draw_circle(kb.round() + Vector2(0, -4), 6.0, Color("151a26"))
		draw_circle(kb.round() + Vector2(0, -4), 5.0, Color.WHITE if white else Color("9b1a0a"))

func _initialize() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT  # 게임 맵처럼 640×360에 그려 정수배로 키운다. 프로젝트 설정은 HUD 때문에 canvas_items다(S30)
	base = ProjectSettings.globalize_path("res://art/trial/")
	shots = OS.get_cmdline_user_args().has("shots")
	for u in ["hero", "chronos"]:
		var fj: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base + u + "/fit.json"))
		var fd: Dictionary = fj["fits"]
		fits[u] = {}
		for k in fd:
			fits[u][int(k)] = fd[k]
	black = Shader.new()
	black.code = "shader_type canvas_item; void fragment() { COLOR = vec4(0.0, 0.0, 0.0, texture(TEXTURE, UV).a); }"
	flash = Shader.new()
	flash.code = "shader_type canvas_item; uniform float flash = 0.0; void fragment() { vec4 c = texture(TEXTURE, UV); COLOR = vec4(mix(c.rgb, vec3(1.0), flash), c.a); }"
	var sh := Image.create_empty(10, 4, false, Image.FORMAT_RGBA8)  # 발밑 그림자: 검정 35% 타원. 반투명이라 시트에 굽지 않는다(lint H5)
	for y in 4:
		for x in 10:
			if pow((x - 4.5) / 5.0, 2) + pow((y - 1.5) / 2.0, 2) <= 1.0:
				sh.set_pixel(x, y, Color(0, 0, 0, 0.35))
	shadow_tex = ImageTexture.create_from_image(sh)
	world = Node2D.new()
	root.add_child(world)
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var bar := ColorRect.new()
	bar.color = Color(0, 0, 0, 0.75)
	bar.size = Vector2(640, TOP - 2)
	layer.add_child(bar)
	hud = Label.new()
	hud.position = Vector2(4, 0)
	hud.add_theme_font_size_override("font_size", 8)
	hud.add_theme_constant_override("line_spacing", -2)
	layer.add_child(hud)
	var keys := Keys.new()
	keys.on_event = on_input
	root.add_child(keys)
	goto(0)

func _process(delta: float) -> bool:
	t += delta
	for a in actors:
		a.call(t)
	if shots:  # 쪽마다 40프레임 뒤 캡처
		frame += 1
		if frame % 40 == 0:
			root.get_texture().get_image().save_png(base + "preview/view_%d.png" % (page + 1))
			if page == PAGES.size() - 1:
				return true
			goto(page + 1)
	return false

func on_input(e: InputEvent) -> void:
	if e is InputEventKey:
		var ke := e as InputEventKey
		if not ke.pressed or ke.echo:
			return
		match ke.keycode:
			KEY_RIGHT: goto((page + 1) % PAGES.size())
			KEY_LEFT: goto((page + PAGES.size() - 1) % PAGES.size())
			KEY_A: opt.elev = 60 if opt.elev == 45 else 45
			KEY_O: opt.outline = "B" if opt.outline == "D" else "D"
			KEY_P: opt.pal = "waldgeist" if opt.pal == "f24p" else "f24p"
			KEY_S: opt.n = {16: 24, 24: 32, 32: 16}[opt.n]
			KEY_H: opt.wall = {16: 24, 24: 32, 32: 16}[opt.wall]
			KEY_T: opt.tiles = (int(opt.tiles) + 1) % 3
			KEY_R: pass
			KEY_SPACE: goto(page)
			KEY_0: goto(9)
			_:
				if ke.keycode >= KEY_1 and ke.keycode <= KEY_9:
					goto(ke.keycode - KEY_1)
				return
		build()
	elif e is InputEventMouseButton:
		var mb := e as InputEventMouseButton
		if mb.pressed and (mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			var nz := clampi(zoom + (1 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else -1), 1, 3)
			if nz != zoom:  # 마우스 아래 점을 붙잡고 줌
				world.position = (mb.position - (mb.position - world.position) * nz / zoom).round()
				zoom = nz
				world.scale = Vector2(zoom, zoom)
				update_hud()
		elif mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = mb.pressed
	elif e is InputEventMouseMotion and dragging:
		world.position = (world.position + (e as InputEventMouseMotion).relative).round()

func goto(p: int) -> void:
	page = p
	zoom = DEFAULT_ZOOM[p]
	world.position = Vector2(0, TOP)
	build()

func build() -> void:
	for c in world.get_children():
		c.free()
	actors.clear()
	t = 0.0
	world.scale = Vector2(zoom, zoom)
	who = "chronos" if page == 9 else "hero"
	if who == "chronos":  # 크로노스는 45° D f24p 24px만 굽었다
		opt.merge({"elev": 45, "outline": "D", "pal": "f24p", "n": 24}, true)
	match page:
		0: page_variants()
		1: page_silhouette()
		2: page_walk_in_place()
		3: page_walk_moving()
		4: page_attack_fall()
		5: page_methods()
		6: page_diagonal()
		7: page_tiles()
		8: page_wall()
		9: page_chronos()
	update_hud()

func update_hud() -> void:
	var extra := ""
	if page == 8:
		extra = "  성벽 %dpx" % opt.wall
	hud.text = "[%d/%d] %s    %d° 외곽선 %s  %s  %dpx  줌 %d배%s\n%s\n←→·1~9·0 쪽  A 각도  O 외곽선  P 팔레트  S 크기  H 성벽  T 타일  R 처음부터  휠 줌  우클릭 끌기  Space 시점" % [
		page + 1, PAGES.size(), PAGES[page][0], opt.elev, opt.outline, opt.pal, opt.n, zoom, extra, PAGES[page][1]]

# --- 도우미 ---

func tex(rel: String) -> Texture2D:
	if not cache.has(rel):
		cache[rel] = ImageTexture.create_from_image(Image.load_from_file(base + rel))
	return cache[rel]

func sheet(anim: String, n: int, elev: int = 0, outline: String = "", pal: String = "") -> Texture2D:
	return tex("%s/%s_%d_%s_%s_%d.png" % [who, anim, elev if elev else opt.elev, outline if outline else opt.outline, pal if pal else opt.pal, n])

func cut(tx: Texture2D, size: int, row: int, col: int) -> AtlasTexture:
	var a := AtlasTexture.new()
	a.atlas = tx
	a.region = Rect2(col * size, row * size, size, size)
	return a

func anchor(n: int) -> Vector2:  # 발밑 기준점(hero.py fit)
	var f: Array = fits[who][n]
	return Vector2(f[1][0], f[1][1])

func ppu(n: int) -> float:
	var f: Array = fits[who][n]
	return f[0]

func canvas(n: int) -> int:  # 프레임 크기. 배율을 고정해서 크기 이름 n보다 크다(hero.py fit)
	var f: Array = fits[who][n]
	return int(f[2])

func sprite(tx: Texture2D, pos: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tx
	s.centered = false
	s.position = pos
	world.add_child(s)
	return s

func put(s: Sprite2D, ground: Vector2, n: int, big: bool) -> void:
	s.position = ground.round() - anchor(n) - (Vector2.ONE * canvas(n) / 2.0 if big else Vector2.ZERO)

func shadow(feet: Vector2) -> Sprite2D:  # 유닛보다 먼저 만들어 밑에 깐다
	return sprite(shadow_tex, feet.round() - SHADOW)

func knight(ground: Vector2, dir: int) -> Sprite2D:
	var n: int = opt.n
	shadow(ground)
	var s := sprite(cut(sheet("idle", n), canvas(n), dir, 0), Vector2.ZERO)
	put(s, ground, n, false)
	return s

func text(s: String, pos: Vector2) -> void:
	var l := Label.new()
	l.text = s
	l.position = pos
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 2)
	world.add_child(l)

func field(cols: int, rows: int, village_rows: int = 0) -> void:
	var at := tex("tiles/ground_%s.png" % opt.pal)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for y in rows:
		for x in cols:
			var v := rng.randi_range(0, 3)
			var dirt := y < village_rows
			var a := AtlasTexture.new()
			a.atlas = at
			if v == 0:
				a.region = Rect2(240 if dirt else 0, 0, 16, 16)
			else:
				a.region = Rect2((v - 1 + (3 if dirt else 0)) * 16, 16, 16, 16)
			sprite(a, Vector2(x, y) * 16)

func dir_row(v: Vector2, four: bool) -> int:
	var a := atan2(-v.y, v.x)
	var name: String
	if four:
		name = ["E", "N", "W", "S"][posmod(int(round(a / (PI / 2))), 4)]
	else:
		name = ["E", "NE", "N", "NW", "W", "SW", "S", "SE"][posmod(int(round(a / (PI / 4))), 8)]
	return DIRS.find(name)

func seg_ground(v: Vector2, n: int) -> float:  # 화면 이동 v(px)의 바닥 거리(모델 단위). 세로는 고도각의 sin배로 줄어 보인다
	return Vector2(v.x / ppu(n), v.y / (ppu(n) * sin(deg_to_rad(float(opt.elev))))).length()

func path_len(path: Array) -> float:
	var l := 0.0
	for k in path.size() - 1:
		var a: Vector2 = path[k]
		var b: Vector2 = path[k + 1]
		l += (b - a).length()
	return l

func walk_path(path: Array, d: float, n: int) -> Array:  # d px 갔을 때 [위치, 진행 방향, 걸은 바닥 거리]
	var g := 0.0
	for k in path.size() - 1:
		var a: Vector2 = path[k]
		var b: Vector2 = path[k + 1]
		var seg := b - a
		var l := seg.length()
		if d <= l:
			return [a + seg / l * d, seg, g + seg_ground(seg, n) * d / l]
		d -= l
		g += seg_ground(seg, n)
	var last: Vector2 = path[-1]
	var prev: Vector2 = path[-2]
	return [last, last - prev, g]

func walker(path: Array, four: bool, fixed_fps: float = 0.0) -> void:
	var n: int = opt.n
	var sh := shadow(Vector2.ZERO)
	var s := sprite(null, Vector2.ZERO)
	var tx := sheet("walk", n)
	var total := path_len(path)
	actors.append(func(tt: float) -> void:
		var r: Array = walk_path(path, fmod(tt * SPEED, total), n)
		var col := int(tt * fixed_fps) % 4 if fixed_fps > 0.0 else int(float(r[2]) / (STEP / 2.0)) % 4
		s.texture = cut(tx, canvas(n), dir_row(r[1], four), col)
		put(s, r[0], n, false)
		sh.position = (r[0] as Vector2).round() - SHADOW
	)

# --- 쪽 ---

func page_variants() -> void:
	field(40, 24)
	var n: int = opt.n
	var c := canvas(n)
	var y := 4
	for e in [45, 60]:
		for o in ["B", "D"]:
			for p in ["f24p", "waldgeist"]:
				text("%d° %s %s" % [e, o, p], Vector2(2, y + c / 2 - 6))
				var tx := sheet("idle", n, e, o, p)
				for d in 8:
					sprite(cut(tx, c, d, 0), Vector2(78 + d * (c + 8), y))
				y += c + 4

func page_silhouette() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(1000, 600)
	bg.position = Vector2(-200, -100)
	world.add_child(bg)
	var y := 6
	for n in [16, 24, 32]:
		var c := canvas(n)
		var tx := sheet("idle", n)
		for d in 8:
			var s := sprite(cut(tx, c, d, 0), Vector2(20 + d * (c + 10), y))
			var m := ShaderMaterial.new()
			m.shader = black
			s.material = m
		y += c + 12

func page_walk_in_place() -> void:
	field(40, 24)
	var y := 6
	for n in [16, 24, 32]:
		var c := canvas(n)
		text("%dpx" % n, Vector2(2, y + c / 2 - 6))
		var tx := sheet("walk", n)
		for d in 8:
			var sf := SpriteFrames.new()
			sf.set_animation_speed("default", 8)
			for f in 4:
				sf.add_frame("default", cut(tx, c, d, f))
			var a := AnimatedSprite2D.new()
			a.sprite_frames = sf
			a.centered = false
			a.position = Vector2(40 + d * (c + 10), y)
			world.add_child(a)
			a.play("default")
		y += c + 10

func page_walk_moving() -> void:
	field(40, 24)
	walker([Vector2(20, 30), Vector2(150, 30), Vector2(150, 140), Vector2(20, 140), Vector2(20, 30)], false)
	walker([Vector2(40, 85), Vector2(130, 85), Vector2(40, 85)], false, 8.0)
	walker([Vector2(185, 140), Vector2(295, 30), Vector2(185, 140)], false)
	walker([Vector2(185, 30), Vector2(295, 140), Vector2(185, 30)], false)
	text("8fps 고정", Vector2(60, 60))

func page_attack_fall() -> void:
	field(40, 24)
	var c := canvas(opt.n)
	for d in 8:
		attacker(Vector2(30 + (d % 4) * (2 * c + 12), 8 + c + (d / 4) * (2 * c)), d)
	var fg := Vector2(30, 8 + 3 * c + 2 * c)
	faller(fg)
	text("쓰러짐", fg + Vector2(2 * c, -12))

func attacker(ground: Vector2, d: int) -> void:  # 공격 3프레임을 1초마다
	var n: int = opt.n
	var c := canvas(n)
	var atk := sheet("attack", n)
	var idle := sheet("idle", n)
	shadow(ground)
	var s := sprite(null, Vector2.ZERO)
	actors.append(func(tt: float) -> void:
		var a := fmod(tt, 1.0)
		if a < 0.42:
			s.texture = cut(atk, 2 * c, d, 0 if a < 0.12 else (1 if a < 0.27 else 2))
			put(s, ground, n, true)
		else:
			s.texture = cut(idle, c, d, 0)
			put(s, ground, n, false)
	)

func faller(ground: Vector2) -> void:  # 쓰러짐 5프레임 뒤 0.5초 서 있기
	var n: int = opt.n
	var c := canvas(n)
	var fall := sheet("fall", n)
	var idle := sheet("idle", n)
	shadow(ground)
	var s := sprite(null, Vector2.ZERO)
	actors.append(func(tt: float) -> void:
		var a := fmod(tt, 2.5)
		if a < 2.0:
			s.texture = cut(fall, 2 * c, 0, mini(4, int(a / 0.1)))
			put(s, ground, n, true)
		else:
			s.texture = cut(idle, c, 0, 0)
			put(s, ground, n, false)
	)

func page_methods() -> void:
	field(40, 24)
	var specs := [["A", "A 8방향 프레임"], ["B", "B 림월드"], ["C", "C 절충"]]
	for i in specs.size():
		text(specs[i][1], Vector2(107 * i + 4, 2))
		unit_panel(specs[i][0], 107.0 * i)

func unit_panel(mode: String, ox: float) -> void:
	var n: int = opt.n
	var path := [Vector2(ox + 20, 40), Vector2(ox + 84, 40), Vector2(ox + 84, 80), Vector2(ox + 52, 112), Vector2(ox + 20, 80), Vector2(ox + 20, 40)]
	var dummy := Dummy.new()
	dummy.position = Vector2(ox + 42, 40)
	world.add_child(dummy)
	var sh := shadow(Vector2.ZERO)
	var s := sprite(null, Vector2.ZERO)
	var mat := ShaderMaterial.new()
	mat.shader = flash
	s.material = mat
	var walk_t := path_len(path) / SPEED
	var four := mode != "A"
	actors.append(func(tt: float) -> void:
		var c := fmod(tt, 12.0)
		var key := "idle"
		var col := 0
		var off := Vector2.ZERO
		var fl := 0.0
		var pos: Vector2 = path[0]
		var face := Vector2.RIGHT
		dummy.white = false
		dummy.kb = Vector2.ZERO
		if c < walk_t:  # 걷기: A 4프레임, B 정지 그림 미끄러짐, C 2위상
			var r: Array = walk_path(path, c * SPEED, n)
			pos = r[0]
			face = r[1]
			var step := int(float(r[2]) / (STEP / 2.0))
			if mode == "A":
				key = "walk"
				col = step % 4
			elif mode == "C":
				key = "walk"
				col = step % 2
		else:
			var s2 := c - walk_t
			for h in [0.3, 1.3, 2.3]:  # 공격 세 번
				var a: float = s2 - h
				if a >= 0.0 and a < 0.45:
					if mode == "A":
						key = "attack"
						col = 0 if a < 0.12 else (1 if a < 0.27 else 2)
					else:  # 돌진: 0.08초에 6px, 0.32초에 걸쳐 복귀. 가장 멀리 나간 순간에 친다
						var f := a / 0.08 if a < 0.08 else maxf(0.0, 1.0 - (a - 0.08) / 0.32)
						off = face * LUNGE * f
						if mode == "C" and a >= 0.08 and a < 0.22:
							key = "attack"
							col = 1
				var hit_at: float = h + (0.12 if mode == "A" else 0.08)
				if s2 >= hit_at and s2 < hit_at + 0.34:  # 허수아비: 흰 번쩍임 + 3px 밀림
					dummy.white = s2 < hit_at + FLASH
					dummy.kb = face * KB * (1.0 - (s2 - hit_at) / 0.34)
			if s2 >= 2.9 and s2 < 3.24:  # 영웅이 맞는다(세 안 같은 반응)
				fl = 1.0 if s2 < 2.9 + FLASH else 0.0
				off = -face * KB * (1.0 - (s2 - 2.9) / 0.34)
			if s2 >= 3.3:  # 쓰러짐: A는 5프레임, B·C는 누운 그림으로 바로
				key = "fall"
				col = mini(4, int((s2 - 3.3) / 0.1)) if mode == "A" else 4
		var big := key == "attack" or key == "fall"
		var row := 0 if key == "fall" else dir_row(face, four)
		s.texture = cut(sheet(key, n), canvas(n) * 2 if big else canvas(n), row, col if key != "idle" else 0)
		put(s, pos + off, n, big)
		sh.position = (pos + off).round() - SHADOW
		mat.set_shader_parameter("flash", fl)
		dummy.queue_redraw()
	)

func page_diagonal() -> void:
	field(40, 24)
	text("8방향", Vector2(4, 2))
	text("4방향", Vector2(164, 2))
	for i in 2:
		var ox := 160.0 * i
		walker([Vector2(ox + 25, 140), Vector2(ox + 125, 40), Vector2(ox + 25, 140)], i == 1)
		walker([Vector2(ox + 25, 40), Vector2(ox + 125, 140), Vector2(ox + 25, 40)], i == 1)

func page_tiles() -> void:
	var at := tex("tiles/ground_%s.png" % opt.pal)
	if opt.tiles == 1:  # 풀·흙 변종 8×8 무작위 반복
		var rng := RandomNumberGenerator.new()
		rng.seed = 1
		for k in 2:
			for y in 8:
				for x in 8:
					var v := rng.randi_range(0, 3)
					var a := AtlasTexture.new()
					a.atlas = at
					a.region = Rect2(240 * k, 0, 16, 16) if v == 0 else Rect2((v - 1 + 3 * k) * 16, 16, 16, 16)
					sprite(a, Vector2(8 + k * 140 + x * 16, 8 + y * 16))
		return
	if opt.tiles == 2:  # 아틀라스: 0행 꼭짓점 16꼴(번호 = 왼위 + 2오른위 + 4왼아래 + 8오른아래), 1행 변종
		sprite(at, Vector2(8, 20))
		for k in 16:
			text(str(k), Vector2(8 + k * 16 + 3, 6))
		return
	var ts := TileSet.new()  # 들판: TileSet terrain(Match Corners), 바깥 한 칸까지 칠한다(T3)
	ts.tile_size = Vector2i(16, 16)
	ts.add_terrain_set(0)
	ts.set_terrain_set_mode(0, TileSet.TERRAIN_MODE_MATCH_CORNERS)
	ts.add_terrain(0)
	ts.add_terrain(0)
	var src := TileSetAtlasSource.new()
	src.texture = at
	src.texture_region_size = Vector2i(16, 16)
	src.use_texture_padding = true
	ts.add_source(src)
	for k in 16:
		add_tile(src, Vector2i(k, 0), [k & 1, (k >> 1) & 1, (k >> 2) & 1, (k >> 3) & 1])
	for v in 3:
		add_tile(src, Vector2i(v, 1), [0, 0, 0, 0])
		add_tile(src, Vector2i(3 + v, 1), [1, 1, 1, 1])
	var layer := TileMapLayer.new()
	layer.tile_set = ts
	world.add_child(layer)
	var paint: Array[Vector2i] = []
	var dirt: Array[Vector2i] = []
	for y in range(-1, 13):
		for x in range(-1, 21):
			paint.append(Vector2i(x, y))
			if x >= 0 and y >= 0 and x < 20 and y < 12 and (pow(x - 8, 2) / 30.0 + pow(y - 6, 2) / 12.0 < 1 or pow(x - 16, 2) / 6.0 + pow(y - 3, 2) / 4.0 < 1):
				dirt.append(Vector2i(x, y))
	layer.set_cells_terrain_connect(paint, 0, 0)
	layer.set_cells_terrain_connect(dirt, 0, 1)
	for k in [[Vector2(3, 3), 0], [Vector2(6, 5), 2], [Vector2(9, 6), 4], [Vector2(12, 4), 6], [Vector2(14, 8), 1], [Vector2(17, 9), 7]]:
		var c: Vector2 = k[0]
		knight(c * 16 + Vector2(8, 8), k[1])

func add_tile(src: TileSetAtlasSource, at: Vector2i, c: Array) -> void:
	src.create_tile(at)
	for center in [0, 1]:  # 가운데 값이 둘 다 있어야 칠하는 쪽이 어떤 꼴이든 정확히 맞는 타일을 찾는다
		var alt: int = 0 if center == 0 else src.create_alternative_tile(at)
		var td := src.get_tile_data(at, alt)
		td.terrain_set = 0
		td.terrain = center
		for i in 4:
			td.set_terrain_peering_bit([TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER, TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
				TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER, TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER][i], c[i])

func page_wall() -> void:
	field(20, 11, 3)  # 0~2행 마을(흙), 3행 성벽(2~7칸), 4행부터 들판
	var h: int = opt.wall
	knight(Vector2(6.5, 2.5) * 16, 0)  # 성벽 바로 뒤 마을 첫 줄
	knight(Vector2(3.5, 1.5) * 16, 4)  # 마을 둘째 줄
	var wall_at := Vector2(2 * 16 - 4, 4 * 16 - 100)  # 성벽 그림의 원점 픽셀 (4, 100)
	sprite(tex("walls/wall_%d_%s_%d.png" % [opt.elev, opt.pal, h]), wall_at)
	sprite(tex("walls/shade_%d_%d.png" % [opt.elev, h]), wall_at)  # 열린 문 통로 그늘(반투명, wall.py)
	var top :=4 * 16 - 3 - h  # 성벽 위: 흉벽 바로 뒤(앞면에서 바닥 3px)에 서고, 앞면 높이만큼 올려 그린다(02 §2)
	knight(Vector2(3.5 * 16, top), 0)
	walker([Vector2(2.5 * 16, top), Vector2(7.5 * 16, top), Vector2(2.5 * 16, top)], false)
	# 흉벽·앞면 층을 성벽 위 유닛보다 나중에 그려 발을 가린다(바닥선 정렬). 성벽 뒤 유닛과 위아래로 쌓여 보였다(Gemini 2026-10-18)
	sprite(tex("walls/front_%d_%s_%d.png" % [opt.elev, opt.pal, h]), wall_at)
	knight(Vector2(3.5, 5.3) * 16, 4)  # 열린 문 앞(성벽 1.5칸)
	knight(Vector2(6.5, 5.3) * 16, 4)  # 닫힌 문 앞(성벽 4.5칸)
	knight(Vector2(8.5, 5.5) * 16, 2)
	walker([Vector2(1.5 * 16, 7.5 * 16), Vector2(12.5 * 16, 7.5 * 16), Vector2(1.5 * 16, 7.5 * 16)], false)

func page_chronos() -> void:  # 열마다 한 방향. 2배 캔버스(공격·쓰러짐)가 겹치지 않게 56px 간격
	field(40, 24)
	var n: int = opt.n
	var c := canvas(n)
	var idle := sheet("idle", n)
	var walk := sheet("walk", n)
	for k in [["정지", 18], ["걷기 8fps", 58], ["공격", 104], ["쓰러짐", 160], ["걷기 이동", 218]]:
		text(k[0], Vector2(2, k[1]))
	for d in 8:
		var x := 86.0 + d * 56
		var g := Vector2(x, 30)
		shadow(g)
		put(sprite(cut(idle, c, d, 0), Vector2.ZERO), g, n, false)
		var wg := Vector2(x, 70)
		shadow(wg)
		var w := sprite(null, Vector2.ZERO)
		put(w, wg, n, false)
		actors.append(func(tt: float) -> void: w.texture = cut(walk, c, d, int(tt * 8.0) % 4))
		attacker(Vector2(x, 116), d)
	faller(Vector2(86, 172))
	walker([Vector2(86, 230), Vector2(300, 230), Vector2(300, 310), Vector2(86, 310), Vector2(86, 230)], false)
	walker([Vector2(360, 230), Vector2(440, 310), Vector2(360, 230)], false)
	walker([Vector2(440, 230), Vector2(360, 310), Vector2(440, 230)], false)
