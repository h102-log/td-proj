extends "res://tests/eval/gd/menu.gd"
# WBS 5.3 소리(S269~S271, S184 2026-11-01 변경, I205). menu.gd 머리의 계약에 더하는 API:
#   res://src/audio.gd — 장면 밖 소리 노드. static of(tree) -> 노드: 트리 root 아래 «Audio» 하나(없으면 만든다). 장면을 바꿔도 남는다
#     play(키) -> bool: 효과음 키를 낸다. 몰림 규칙(S270)에 막히면 false · played: 낸 효과음 키(Array, 마지막이 최근)
#     player(키) -> AudioStreamPlayer: 그 키의 효과음 재생기 · music: 지금 곡 재생기(AudioStreamPlayer)
#     song: 지금 곡 키(없으면 "") · starts: 곡을 처음부터 튼 횟수 · jingle: 마지막으로 튼 징글 키(없으면 "")
#     _process(delta): 시간이 흐른다. 몰림의 0.05초는 이 시간으로 센다
#   main.sfx — 게임 장면의 효과음 연결(res://src/sfx.gd). static key_for(사건) -> 효과음 키(소리 없으면 "")
#     사건은 화면 사건(I171) {kind, at, dir, src, dst, n, heavy, slot}. hear(사건 목록, seen: Rect2) — seen은 보이는 맵 영역(맵 px)
#     main._process가 프레임마다 화면 사건과 판 변화(놓기·완성·영입·레벨)를 소리로 낸다
#   settings.gd — static var music_volume · sfx_volume(0~100, 기본 100). apply_volume()이 «Music»·«SFX» 버스에도 건다
#   소리 파일: res://audio/sfx/<키>.wav · res://audio/music/<키>.wav (PCM WAV)

const KEYS := ["arrow", "bolt", "cannon", "swing", "hit", "boom", "hurt", "struct_hit", "enemy_die", "ally_down", "hero_down",
	"boss_skill", "interrupt", "collapse", "meteor", "burst", "loop", "resonate", "build", "complete", "sell", "hire",
	"level_up", "wave_start", "boss_appear", "alert", "click", "refuse"]  # S269 표에서 영웅 스킬 24개를 뺀 키
const SONGS := ["title", "prep", "battle", "boss"]
const JINGLES := ["clear", "win", "lose"]

# 새 소리 노드. 앞 EV가 남긴 기록·몰림 시간을 버린다
func _audio():
	var tree: SceneTree = Engine.get_main_loop()
	var old = tree.root.get_node_or_null("Audio")
	if old:
		old.free()
	return load("res://src/audio.gd").of(tree)

# 사건 하나(화면 사건 목록의 꼴)
func _ev(more: Dictionary) -> Dictionary:
	var e := {"kind": "", "at": Vector2.ZERO, "dir": Vector2.ZERO, "src": null, "dst": null, "n": 0, "heavy": false}
	e.merge(more, true)
	return e

func _hero(b, kind: String):
	for h in b.heroes:
		if h.kind == kind:
			return h
	return null

# 행동 뒤 한 프레임을 돌려 key가 났는가. 앞 소리의 몰림(0.05초)이 막지 않게 시간을 먼저 흘린다
func _after(main, audio, what: String, act: Callable, key: String) -> String:
	audio._process(1.0)
	audio.played.clear()
	act.call()
	_frame(main)
	return "" if key in audio.played else "%s 뒤 %s가 나지 않았다(난 것 %s)" % [what, key, audio.played]

# EV642 · S269: 화면 사건 → 효과음 키
func ev642():
	var Sfx = load("res://src/sfx.gd")
	var b = battle({"heroes": [{"kind": "aias", "cell": Vector2i(5, 5)}, {"kind": "sylvia", "cell": Vector2i(5, 7)}, {"kind": "ignis", "cell": Vector2i(5, 9)}]})
	var tower = b.build("tower", Vector2i(10, 3))
	var magic = b.build("magic", Vector2i(13, 3))
	var cannon = b.build("cannon", Vector2i(16, 3))
	var e = b.spawn_enemy("basic", Vector2i(1, 10))
	var merc = b.place_merc("soldier", Vector2i(20, 12))
	var aias = _hero(b, "aias")
	var sylvia = _hero(b, "sylvia")
	var ignis = _hero(b, "ignis")
	if [tower, magic, cannon, e, merc, aias, sylvia, ignis].has(null):
		return "시험 판을 만들지 못했다: %s" % [[tower, magic, cannon, e, merc, aias, sylvia, ignis]]
	var cases := [
		["궁수탑 쏨", {"kind": "fire", "src": tower, "dst": e}, "arrow"],
		["마법탑 쏨", {"kind": "fire", "src": magic, "dst": e}, "bolt"],
		["대포 쏨", {"kind": "fire", "src": cannon, "dst": e}, "cannon"],
		["아이아스 쏨", {"kind": "fire", "src": aias, "dst": e}, "swing"],
		["실비아 쏨", {"kind": "fire", "src": sylvia, "dst": e}, "arrow"],
		["적의 쏨", {"kind": "fire", "src": e, "dst": aias}, ""],
		["적이 맞음", {"kind": "hit", "src": aias, "dst": e}, "hit"],
		["영웅이 맞음", {"kind": "hit", "src": e, "dst": aias}, "hurt"],
		["구조물이 맞음", {"kind": "struct", "src": e, "dst": tower}, "struct_hit"],
		["무거운 닿음", {"kind": "hit", "src": cannon, "dst": e, "heavy": true}, "boom"],
		["적 처치", {"kind": "kill", "src": aias, "dst": e}, "enemy_die"],
		["용병 처치", {"kind": "kill", "src": e, "dst": merc}, "ally_down"],
		["영웅 처치", {"kind": "kill", "src": e, "dst": aias}, "hero_down"],
		["이그니스 Q", {"kind": "cast", "src": ignis, "slot": "q"}, "skill_fireball"],
		["운석 착탄", {"kind": "cast", "src": ignis, "slot": "meteor"}, "meteor"],
		["보스 스킬", {"kind": "boss", "src": e, "slot": "slam"}, "boss_skill"],
		["끊김", {"kind": "interrupt", "src": e}, "interrupt"],
		["붕괴", {"kind": "collapse"}, "collapse"],
	]
	for c in cases:
		var got: String = Sfx.key_for(_ev(c[1]))
		if got != c[2]:
			return "%s → «%s»(기대 «%s»)" % [c[0], got, c[2]]
	return ""

# EV643 · S269: 스킬 24개와 나머지 키의 소리 파일
func ev643():
	var ids := []
	for f in DirAccess.get_files_at("res://data/heroes"):
		if f.ends_with(".tres"):
			var d = load("res://data/heroes/" + f)
			for s in ["q", "w", "e", "r"]:
				ids.append(d.get(s).id)
	if ids.size() != 24:
		return "영웅 스킬 id가 %d개다(기대 24)" % ids.size()
	var sums := {}
	for id in ids:
		var p := "res://audio/sfx/skill_%s.wav" % id
		if not FileAccess.file_exists(p):
			return "%s가 없다" % p
		sums[FileAccess.get_md5(p)] = id
	if sums.size() != 24:
		return "스킬 효과음 24개 가운데 내용이 다른 것이 %d개다" % sums.size()
	for k in KEYS:
		if not FileAccess.file_exists("res://audio/sfx/%s.wav" % k):
			return "res://audio/sfx/%s.wav가 없다" % k
	return ""

# EV644 · S269: 판 흐름·건설·UI 소리
func ev644():
	_settings()
	var audio = _audio()
	var main = _game()
	var b = main.view.battle
	b.gold = BIG
	_frame(main)
	var hire_one := func():
		b.offers[0] = "sylvia"
		b.hire(0)
	var why := _after(main, audio, "영웅 영입", hire_one, "hire")
	var h = b.roster[0] if not b.roster.is_empty() else null
	if why == "" and (h == null or h.kind != "sylvia"):
		why = "실비아를 영입하지 못했다"
	if why == "":
		b.next_round()
		_frame(main)
		why = _after(main, audio, "레벨 오름", func(): b.add_xp(h, BIG), "level_up")
	var cell: Vector2i = b.placeable_cells("tower")[0] if why == "" else Vector2i.ZERO
	if why == "":
		why = _after(main, audio, "구조물 놓기", func(): b.build("tower", cell), "build")
	if why == "":
		why = _after(main, audio, "놓기 거부", func(): main.controls.refused.emit(cell, "시험"), "refuse")
	var s = b.structure_at(cell)
	if why == "" and s == null:
		why = "놓은 궁수탑이 없다"
	if why == "":
		s.complete = false
		_frame(main)
		why = _after(main, audio, "공사 끝", func(): s.complete = true, "complete")
	if why == "":
		var sell_it := func():
			main.controls.selling = [s]
			main.hud._sell_now()
		why = _after(main, audio, "판매", sell_it, "sell")
	if why == "":
		why = _after(main, audio, "웨이브 시작", func(): b.start_battle(), "wave_start")
	if why == "":
		why = _after(main, audio, "보스 출현", func(): b.spawn_enemy("boss", b.spawns[0]), "boss_appear")
	if why == "":
		var btn := Button.new()
		btn.text = "시험"
		main.add_child(btn)
		why = _after(main, audio, "버튼 누름", func(): btn.pressed.emit(), "click")
	_done(main)
	return why

# EV645 · S270: 몰림·화면 밖·일시정지
func ev645():
	_settings()
	var audio = _audio()
	var main = _game()
	var b = main.view.battle
	b.gold = BIG
	b.offers[0] = "ignis"
	b.hire(0)
	b.next_round()
	_frame(main)
	var ignis = b.roster[0] if not b.roster.is_empty() else null
	var e = b.spawn_enemy("basic", b.spawns[0])
	var why := ""
	if ignis == null or ignis.kind != "ignis" or e == null:
		why = "이그니스나 적을 만들지 못했다"
	var seen := Rect2(0, 0, 100, 100)
	var hit := _ev({"kind": "hit", "at": Vector2(50, 50), "src": ignis, "dst": e})
	var ten := []
	for i in 10:
		ten.append(hit)
	if why == "":
		audio._process(1.0)
		audio.played.clear()
		main.sfx.hear(ten, seen)
		if audio.played.count("hit") != 1:
			why = "같은 프레임 닿음 10개에 hit가 %d번 났다(기대 1)" % audio.played.count("hit")
	if why == "":
		audio._process(0.05)
		main.sfx.hear(ten, seen)
		if audio.played.count("hit") != 2:
			why = "0.05초 뒤 닿음 10개를 넣어 hit가 모두 %d번이다(기대 2)" % audio.played.count("hit")
	if why == "":
		audio._process(1.0)
		audio.played.clear()
		main.sfx.hear([_ev({"kind": "hit", "at": Vector2(500, 500), "src": ignis, "dst": e})], seen)
		main.sfx.hear([_ev({"kind": "cast", "at": Vector2(500, 500), "src": ignis, "slot": "q"})], seen)
		if "hit" in audio.played:
			why = "보이는 맵 영역 밖의 닿음에 hit가 났다"
		elif not "skill_fireball" in audio.played:
			why = "보이는 맵 영역 밖의 영웅 스킬에 소리가 없다(난 것 %s)" % [audio.played]
	if why == "" and audio.player("hit").max_polyphony != 4:
		why = "hit 재생기의 max_polyphony가 %d다" % audio.player("hit").max_polyphony
	if why == "":
		var tree: SceneTree = Engine.get_main_loop()
		tree.paused = true
		if audio.player("hit").can_process():
			why = "트리가 멈춰도 hit 재생기가 돈다"
		elif not audio.player("click").can_process():
			why = "트리가 멈추면 click 재생기도 멈춘다"
		elif not audio.music.can_process():
			why = "트리가 멈추면 음악 재생기도 멈춘다"
		tree.paused = false
	_done(main)
	return why

# EV646 · S271: 판 단계 → 곡·징글, 장면을 바꿔도 남는 음악
func ev646():
	_settings()
	var audio = _audio()
	var m = _menu()
	var why := "" if audio.song == "title" else "메인 메뉴의 곡이 «%s»다" % audio.song
	m.free()
	var main = _game()
	var b = main.view.battle
	_frame(main)
	var n: int = audio.starts
	if why == "" and audio.song != "prep":
		why = "새 게임(영입 창)의 곡이 «%s»다" % audio.song
	if why == "":
		b.next_round()
		_frame(main)
		if audio.song != "prep" or audio.starts != n:
			why = "준비 단계로 넘어가며 곡이 «%s», 시작 횟수 %d → %d다" % [audio.song, n, audio.starts]
	if why == "":
		b.start_battle()
		_frame(main)
		if audio.song != "battle":
			why = "전투의 곡이 «%s»다" % audio.song
		elif audio.music.stream == null or audio.music.stream.get("loop_mode") != AudioStreamWAV.LOOP_FORWARD:
			why = "전투 곡이 앞으로 반복(LOOP_FORWARD)이 아니다"
	var boss = b.spawn_enemy("boss", b.spawns[0]) if why == "" else null
	if why == "":
		_frame(main)
		if audio.song != "boss":
			why = "보스가 살아 있는 전투의 곡이 «%s»다" % audio.song
	if why == "":
		b.damage(boss, BIG)
		_frame(main)
		if boss.alive or audio.song != "battle":
			why = "보스가 쓰러진(%s) 뒤 곡이 «%s»다" % [not boss.alive, audio.song]
	for c in [["cleared", "clear", "prep"], ["won", "win", ""], ["lost", "lose", ""]]:
		if why != "":
			break
		b.state = c[0]
		_frame(main)
		if audio.jingle != c[1] or audio.song != c[2]:
			why = "%s로 넘어간 뒤 징글 «%s»·곡 «%s»다(기대 «%s»·«%s»)" % [c[0], audio.jingle, audio.song, c[1], c[2]]
	_done(main)
	if why == "" and Engine.get_main_loop().root.get_node_or_null("Audio") != audio:
		why = "게임 장면을 지우자 소리 노드가 트리에서 없어졌다"
	return why

# EV647 · S184(2026-11-01 변경): 음악·효과음 설정
func ev647():
	var st = _settings()
	var why := ""
	if [st.music_volume, st.sfx_volume] != [100, 100]:
		why = "설정 파일이 없을 때 음악·효과음이 %s다" % [[st.music_volume, st.sfx_volume]]
	if why == "":
		st.music_volume = 30
		st.sfx_volume = 0
		st.save_file()
		st.music_volume = 100
		st.sfx_volume = 100
		st.load_file()
		if [st.music_volume, st.sfx_volume] != [30, 0]:
			why = "30·0으로 저장하고 다시 읽은 값이 %s다" % [[st.music_volume, st.sfx_volume]]
	if why == "":
		st.apply_volume()
		var mi := AudioServer.get_bus_index("Music")
		var si := AudioServer.get_bus_index("SFX")
		if mi < 0 or si < 0:
			why = "Music·SFX 버스가 없다(%d, %d)" % [mi, si]
		elif not is_equal_approx(AudioServer.get_bus_volume_db(mi), linear_to_db(0.3)):
			why = "음악 30의 Music 버스 음량이 %.2f dB다" % AudioServer.get_bus_volume_db(mi)
		elif not AudioServer.is_bus_mute(si):
			why = "효과음 0인데 SFX 버스가 음소거가 아니다"
	st.music_volume = 100
	st.sfx_volume = 100
	st.apply_volume()
	if why == "":
		var m = _menu()
		_press(m, "설정")
		var first = _slider(m)
		if first == null or not first.get_parent().get_children().any(func(x): return x is Label and x.text == "음량"):
			why = "설정 화면의 첫 슬라이더가 «음량»이 아니다"
		for t in ["음악", "효과음"]:
			if why != "":
				break
			var found = null
			for n in m.find_children("*", "HSlider", true, false):
				if n.is_visible_in_tree() and n.get_parent().get_children().any(func(x): return x is Label and x.text == t):
					found = n
			if found == null:
				why = "설정 화면에 글자 «%s» 옆 슬라이더가 없다" % t
			elif [found.min_value, found.max_value, found.step] != [0.0, 100.0, 10.0]:
				why = "«%s» 슬라이더가 %s다(기대 0~100, 10씩)" % [t, [found.min_value, found.max_value, found.step]]
		m.free()
	_settings()
	return why

# WAV 파일의 채널 수·비트 수와 표본(-1~1)
func _wav(path: String) -> Dictionary:
	var f := FileAccess.get_file_as_bytes(path)
	var out := {"ch": 0, "bits": 0, "x": PackedFloat32Array()}
	var i := 12
	while i + 8 <= f.size():
		var id := f.slice(i, i + 4).get_string_from_ascii()
		var n := f.decode_u32(i + 4)
		if id == "fmt ":
			out.ch = f.decode_u16(i + 10)
			out.bits = f.decode_u16(i + 22)
		elif id == "data" and out.bits == 16:
			var x := PackedFloat32Array()
			x.resize(n / 2)
			for k in n / 2:
				x[k] = f.decode_s16(i + 8 + k * 2) / 32768.0
			out.x = x
		i += 8 + n + n % 2
	return out

# EV648 · I205: 소리 파일의 형식·크기·직류·이음매
func ev648():
	var files := []
	for dir in ["res://audio/sfx", "res://audio/music"]:
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(".wav"):
				files.append(dir + "/" + f)
	if files.size() < KEYS.size() + 24 + SONGS.size() + JINGLES.size():
		return "소리 파일이 %d개뿐이다" % files.size()
	for p in files:
		var w := _wav(p)
		var x: PackedFloat32Array = w.x
		if w.ch != 1 or w.bits != 16 or x.is_empty():
			return "%s가 모노 16비트가 아니다(채널 %d, %d비트, 표본 %d)" % [p, w.ch, w.bits, x.size()]
		var peak := 0.0
		var sum := 0.0
		for v in x:
			peak = maxf(peak, absf(v))
			sum += v
		if peak > 0.95:
			return "%s의 최대 절댓값이 %.3f다" % [p, peak]
		if absf(sum / x.size()) >= 0.01:
			return "%s의 직류(평균)가 %.4f다" % [p, sum / x.size()]
		var name: String = p.get_file().get_basename()
		if p.begins_with("res://audio/music") and name in SONGS:
			if absf(x[x.size() - 1] - x[0]) >= 0.05:
				return "%s의 끝 표본 %.3f와 첫 표본 %.3f가 이어지지 않는다" % [p, x[x.size() - 1], x[0]]
		elif absf(x[0]) >= 0.02 or absf(x[x.size() - 1]) >= 0.02:
			return "%s의 첫·끝 표본이 %.3f·%.3f다" % [p, x[0], x[x.size() - 1]]
	return ""
