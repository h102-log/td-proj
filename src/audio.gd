extends Node
# 장면 밖 소리 노드(S269~S271, I205). 효과음 재생기와 곡·징글 재생기를 갖고, 트리 root 아래 «Audio» 하나라 메인 메뉴와 게임 장면을 오가도 남는다.
# 효과음 키는 res://audio/sfx/<키>.wav, 곡·징글은 res://audio/music/<키>.wav(tools/audio/make.py가 합성한다)

const Settings := preload("res://src/settings.gd")
const GAP := 0.05  # 같은 효과음을 다시 내기까지의 초(S270)
const VOICES := 4  # 한 효과음이 동시에 울리는 수(S270). 넘으면 가장 오래된 것을 끊는다(max_polyphony)
const FADE := 0.5  # 곡이 바뀔 때 앞 곡을 줄이는 초(S271)
const ALWAYS := ["click"]  # ESC 메뉴(트리 멈춤)에도 나는 효과음(S270)
const JINGLE_AT := {"cleared": "clear", "won": "win", "lost": "lose"}  # 이 판 단계로 넘어가면 트는 징글(S271)
const LOG := 64  # played에 남기는 수

static var _one: Node  # of()가 만든 노드. 시작 장면의 _ready에서는 root에 바로 못 붙여 늦게 붙으므로, 붙기 전에도 같은 것을 준다

var played := []  # 낸 효과음 키(마지막이 최근)
var song := ""  # 지금 곡 키. 없으면 ""
var starts := 0  # 곡을 처음부터 튼 횟수
var jingle := ""  # 마지막으로 튼 징글 키
var music: AudioStreamPlayer  # 지금 곡 재생기
var clock := 0.0  # 몰림(GAP)을 세는 시간. 트리가 멈춰도 흐른다
var _players := {}  # 효과음 키 → 재생기
var _last := {}  # 효과음 키 → 마지막으로 낸 clock
var _decks := []  # 곡 재생기 둘. 곡이 바뀌면 번갈아 쓰고, 앞 곡은 줄어들며 끝난다
var _fades := {}  # 곡 재생기 → 줄이는 Tween
var _jingle: AudioStreamPlayer
var _state := ""  # follow가 마지막으로 본 판 단계

# 소리 노드. 없으면 만들어 트리 root에 붙인다
static func of(tree: SceneTree) -> Node:
	if is_instance_valid(_one) and not _one.is_queued_for_deletion():
		return _one
	_one = load("res://src/audio.gd").new()
	_one.name = "Audio"
	if tree.root.is_node_ready():
		tree.root.add_child(_one)
	else:  # 게임을 막 켠 시작 장면의 _ready: root가 아직 자식을 준비하는 중이라 바로 붙이면 실패한다
		tree.root.add_child.call_deferred(_one)
	return _one

# 판 단계 → 곡(S271). title은 메인 메뉴다
static func song_for(state: String, boss: bool) -> String:
	match state:
		"title":
			return "title"
		"battle":
			return "boss" if boss else "battle"
		"won", "lost":
			return ""
	return "prep"

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Settings.bus("SFX")
	Settings.bus("Music")
	for i in 2:
		var d := AudioStreamPlayer.new()
		d.bus = "Music"
		add_child(d)
		_decks.append(d)
	music = _decks[0]
	_jingle = AudioStreamPlayer.new()
	_jingle.bus = "Music"
	_jingle.finished.connect(_after_jingle)
	add_child(_jingle)

func _ready() -> void:
	get_tree().node_added.connect(_hook)
	for b in get_tree().root.find_children("*", "BaseButton", true, false):
		_hook(b)
	if song != "" and not _jingle.playing:  # 트리에 붙기 전에 고른 곡(시작 장면)
		music.play()

func _process(delta: float) -> void:
	clock += delta

# 버튼 누름(S269)
func _hook(n: Node) -> void:
	if n is BaseButton and not n.pressed.is_connected(_click):
		n.pressed.connect(_click)

func _click() -> void:
	play("click")

# 그 효과음 키의 재생기. 처음 부를 때 만든다
func player(key: String) -> AudioStreamPlayer:
	if not _players.has(key):
		var p := AudioStreamPlayer.new()
		p.stream = load("res://audio/sfx/%s.wav" % key)
		p.bus = "SFX"
		p.max_polyphony = VOICES
		p.process_mode = Node.PROCESS_MODE_ALWAYS if key in ALWAYS else Node.PROCESS_MODE_PAUSABLE  # 멈춘 트리에서 전투음은 멈춘다(S270)
		add_child(p)
		_players[key] = p
	return _players[key]

# 효과음을 낸다. 키가 비었거나 같은 키를 GAP초 안에 냈으면 내지 않고 false(S270)
func play(key: String) -> bool:
	if key == "" or clock - _last.get(key, -INF) < GAP:
		return false
	_last[key] = clock
	played.append(key)
	if played.size() > LOG:
		played.pop_front()
	var p := player(key)
	if p.is_inside_tree():
		p.play()
	return true

# 판 단계를 따라 곡을 고르고, 판 단계가 라운드 끝·성공·패배로 바뀌면 징글을 튼다(S271). quiet면 이번 바뀜에 징글을 틀지 않는다(이어하기)
func follow(state: String, boss: bool, quiet := false) -> void:
	if state != _state:
		if not quiet and JINGLE_AT.has(state):
			play_jingle(JINGLE_AT[state])
		_state = state
	want(song_for(state, boss))

# 곡을 바꾼다. 같은 곡이면 그대로 둔다. 징글이 울리는 동안 고른 곡은 징글이 끝난 뒤 처음부터 튼다
func want(key: String) -> void:
	if key == song:
		return
	song = key
	_fade(music)
	if key != "" and not _jingle.playing:
		_start()

# 징글을 한 번 튼다. 앞 곡은 멈춘다
func play_jingle(key: String) -> void:
	jingle = key
	_fade(music)
	_jingle.stream = load("res://audio/music/%s.wav" % key)
	if _jingle.is_inside_tree():
		_jingle.play()

func _after_jingle() -> void:
	if song != "":
		_start()

# 쉬는 곡 재생기에 지금 곡을 처음부터 튼다. 곡은 이음매 없이 반복한다(I205)
func _start() -> void:
	var d: AudioStreamPlayer = _decks[1] if music == _decks[0] else _decks[0]
	if _fades.has(d):
		_fades[d].kill()
		_fades.erase(d)
	var s: AudioStreamWAV = load("res://audio/music/%s.wav" % song)
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = roundi(s.get_length() * s.mix_rate)
	d.stream = s
	d.volume_db = 0.0
	music = d
	starts += 1
	if d.is_inside_tree():
		d.play()

# 곡 재생기를 FADE초에 걸쳐 줄이고 멈춘다
func _fade(d: AudioStreamPlayer) -> void:
	if not d.playing or not is_inside_tree():
		d.stop()
		return
	if _fades.has(d):
		return
	var tw := create_tween()
	tw.tween_property(d, "volume_db", -60.0, FADE)
	tw.tween_callback(func():
		d.stop()
		_fades.erase(d))
	_fades[d] = tw
