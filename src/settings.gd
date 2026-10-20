extends RefCounted
# 설정(S184, I160). user://의 설정 파일 하나에 저장해 다시 켜도 그대로다. 메인 메뉴 장면과 게임 장면이 함께 읽는다

static var path := ""  # 설정 파일. 비어 있으면 쓰지 않는다. 진입 장면(menu.gd)이 정하고, 평가는 평가용 파일로 바꾼다
static var quickcast := false  # 퀵캐스트(S147, I158)
static var revive := true  # 부활(I28)
static var fullscreen = null  # 창 모드. null이면 아직 고르지 않았다(첫 실행은 S163대로)
static var volume := 100  # 마스터 음량(%)

# 파일이 없으면 기본값이다
static func load_file() -> void:
	var c := ConfigFile.new()
	c.load(path)
	quickcast = c.get_value("settings", "quickcast", false)
	revive = c.get_value("settings", "revive", true)
	fullscreen = c.get_value("settings", "fullscreen") if c.has_section_key("settings", "fullscreen") else null
	volume = c.get_value("settings", "volume", 100)

static func save_file() -> void:
	if path == "":
		return
	var c := ConfigFile.new()
	c.set_value("settings", "quickcast", quickcast)
	c.set_value("settings", "revive", revive)
	c.set_value("settings", "fullscreen", fullscreen)  # null이면 칸이 생기지 않는다
	c.set_value("settings", "volume", volume)
	c.save(path)

# 시작할 때 전체화면인가. 고른 창 모드가 없으면 내보낸 빌드만 전체화면이다(S163)
static func fullscreen_at_start(exported: bool) -> bool:
	return exported if fullscreen == null else fullscreen

# 마스터 버스에 음량을 건다. 0%면 소리를 끈다(I160)
static func apply_volume() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(volume / 100.0))
	AudioServer.set_bus_mute(0, volume == 0)
