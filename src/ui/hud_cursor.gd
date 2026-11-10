extends RefCounted
# 마우스 커서 모양(S278, I211). 상태 판정·도트 그림·하드웨어 커서 걸기를 static 함수로 둔다
# 상태: "arrow" 기본 · "sword" 적 위(곧 우클릭이 대상 공격) · "attack" A 모드 과녁 · "cross" 스킬 조준·놓기·대포 옮기기

const SIZE := 12  # 도트 그림 한 변(S278 Claude 임시값). 창의 정수 배율만큼 키워 건다
# 도트 색(S278 Claude 임시값). 과녁 빨강 r은 S205 공격 표식(BattleView.ORDER_COLORS)과 같은 색이다
const COLORS := {"#": Color("151a26"), "o": Color.WHITE, "s": Color("d0d6e0"), "g": Color("efac28"), "h": Color("ab5c1c"), "r": Color("ef3a0c")}
const DOTS := {
	"arrow": [  # 끝이 왼쪽 위인 화살표: 밝은 몸 + 어두운 테두리
		"#...........",
		"##..........",
		"#o#.........",
		"#oo#........",
		"#ooo#.......",
		"#oooo#......",
		"#ooooo#.....",
		"#oooooo#....",
		"#ooo####....",
		"#o#oo#......",
		"##.#oo#.....",
		"....##......",
	],
	"sword": [  # 끝이 왼쪽 위인 칼: 밝은 칼날 + 금빛 코등이·자루 끝 + 갈색 자루
		"##..........",
		"#s#.........",
		"#ss#........",
		".#ss#....#..",
		"..#ss#..#g#.",
		"...#ss##g#..",
		"....#ssg#...",
		".....#g#h#..",
		"....#g#.#h#.",
		"....##...#g#",
		"..........#.",
		"............",
	],
	"attack": [  # 빨강 과녁: 원 + 가운데 십자, 바깥 어두운 테두리
		"....####....",
		"..##rrrr##..",
		".#rr....rr#.",
		".#r......r#.",
		"#r...rr...r#",
		"#r..rrrr..r#",
		"#r..rrrr..r#",
		"#r...rr...r#",
		".#r......r#.",
		".#rr....rr#.",
		"..##rrrr##..",
		"....####....",
	],
	"cross": [  # 흰 십자: 어두운 테두리
		"....####....",
		"....#oo#....",
		"....#oo#....",
		"....#oo#....",
		"#####oo#####",
		"#oooooooooo#",
		"#oooooooooo#",
		"#####oo#####",
		"....#oo#....",
		"....#oo#....",
		"....#oo#....",
		"....####....",
	],
}

static var _set := []  # 마지막으로 건 [상태, 배율]. 같으면 다시 걸지 않는다(I211)

# 커서 상태(S278). at은 지금 마우스 자리(맵 px), over_hud는 커서가 HUD 조작 위인가
# 적 위 판정은 우클릭 대상 공격과 같다(controls의 _foes·_closest: 0.7칸 안, S213 숨은 적 빼고, S14)
static func kind(controls, at: Vector2, over_hud: bool) -> String:
	if controls.battle.state not in ["prep", "battle", "raid"] or over_hud:
		return "arrow"
	if controls.attacking:
		return "attack"
	if controls.placing != "" or controls.aiming != "" or controls.moving != null:
		return "cross"
	if controls.selected.any(func(u): return u.alive) and controls._closest(controls._foes(), at / controls.cell_px - Vector2(0.5, 0.5)) != null:
		return "sword"
	return "arrow"

# 상태 k의 그림: SIZE×SIZE 도트를 scale배 Nearest로 키운 것(RGBA8)
static func image(k: String, scale: int) -> Image:
	var rows: Array = DOTS[k]
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y in SIZE:
		for x in SIZE:
			img.set_pixel(x, y, COLORS.get(rows[y][x], Color.TRANSPARENT))
	img.resize(SIZE * scale, SIZE * scale, Image.INTERPOLATE_NEAREST)
	return img

# 핫스팟(그림 px): 화살표·칼은 끝(왼쪽 위), 과녁·십자는 가운데
static func hotspot(k: String, scale: int) -> Vector2:
	return Vector2.ZERO if k in ["arrow", "sword"] else Vector2(SIZE, SIZE) * scale / 2.0

# 하드웨어 커서로 건다(I211). 직전에 건 상태·배율과 같으면 걸지 않고 false
static func apply(k: String, scale: int) -> bool:
	if _set == [k, scale]:
		return false
	Input.set_custom_mouse_cursor(image(k, scale), Input.CURSOR_ARROW, hotspot(k, scale))  # ImageTexture로 넘기면 종료할 때 그 텍스처가 RenderingServer보다 늦게 풀려 오류가 난다
	_set = [k, scale]
	return true
