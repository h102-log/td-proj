extends RefCounted
# 설정(S184, I160)과 끝낸 힌트(I166). user://의 설정 파일 하나에 저장해 다시 켜도 그대로다. 메인 메뉴 장면과 게임 장면이 함께 읽는다

static var path := ""  # 설정 파일. 비어 있으면 쓰지 않는다. 진입 장면(menu.gd)이 정하고, 평가는 평가용 파일로 바꾼다
static var quickcast := false  # 퀵캐스트(S147, I158)
static var revive := true  # 부활(I28)
static var fullscreen = null  # 창 모드. null이면 아직 고르지 않았다(첫 실행은 S163대로)
static var volume := 100  # 마스터 음량(%)
static var camera_speed := 100  # 카메라 속도(%, S184). 가장자리·방향키 이동 속도에 곱한다(S53)
static var shake := 2  # 화면 흔들림(S184, S200): 0 끔 · 1 약하게 · 2 보통
static var soft_flash := false  # 번쩍임 줄이기(S184): 흰 실루엣 대신 흰 40% 덧그림(S177, S197)
static var hints := true  # 처음 하는 사람 힌트(S191)
static var hints_done := []  # 끝낸 힌트 이름(I166). 설정 파일의 hints 칸에 둔다
static var language := "ko"  # 게임 글의 언어 «ko»·«en»(S193). 설정 파일에 없으면 OS 언어로 정한다
static var _english = null  # 영어 번역기(I167). apply_language가 처음 한 번 만들어 TranslationServer에 넣는다

# 파일이 없으면 기본값이다
static func load_file() -> void:
	var c := ConfigFile.new()
	c.load(path)
	quickcast = c.get_value("settings", "quickcast", false)
	revive = c.get_value("settings", "revive", true)
	fullscreen = c.get_value("settings", "fullscreen") if c.has_section_key("settings", "fullscreen") else null
	volume = c.get_value("settings", "volume", 100)
	camera_speed = c.get_value("settings", "camera_speed", 100)
	shake = c.get_value("settings", "shake", 2)
	soft_flash = c.get_value("settings", "soft_flash", false)
	hints = c.get_value("settings", "hints", true)
	hints_done = c.get_value("hints", "done", [])
	language = c.get_value("settings", "language", default_language(OS.get_locale()))

static func save_file() -> void:
	if path == "":
		return
	var c := ConfigFile.new()
	c.set_value("settings", "quickcast", quickcast)
	c.set_value("settings", "revive", revive)
	c.set_value("settings", "fullscreen", fullscreen)  # null이면 칸이 생기지 않는다
	c.set_value("settings", "volume", volume)
	c.set_value("settings", "camera_speed", camera_speed)
	c.set_value("settings", "shake", shake)
	c.set_value("settings", "soft_flash", soft_flash)
	c.set_value("settings", "hints", hints)
	c.set_value("hints", "done", hints_done)
	c.set_value("settings", "language", language)
	c.save(path)

# 언어를 고른 적이 없을 때 OS 언어(OS.get_locale())가 한국어면 «ko», 그 밖이면 «en»(S193)
static func default_language(os_locale: String) -> String:
	return "ko" if os_locale.begins_with("ko") else "en"

# 게임 글의 언어를 건다. 처음 부를 때 영어 번역기(locale.gd)를 넣는다. 자동 번역하는 글은 그 자리에서 다시 그린다(I167)
static func apply_language() -> void:
	if _english == null:
		_english = load("res://src/locale.gd").new()
		TranslationServer.add_translation(_english)
	TranslationServer.set_locale(language)

# 시작할 때 전체화면인가. 고른 창 모드가 없으면 내보낸 빌드만 전체화면이다(S163)
static func fullscreen_at_start(exported: bool) -> bool:
	return exported if fullscreen == null else fullscreen

# 마스터 버스에 음량을 건다. 0%면 소리를 끈다(I160)
static func apply_volume() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(volume / 100.0))
	AudioServer.set_bus_mute(0, volume == 0)
