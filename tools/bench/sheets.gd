extends RefCounted
# 4.1a 스파이크용 그림 묶음: 영웅 6명·기사(4.0 시험)의 24px 시트와 성벽 시험 그림.
# packed면 모두 한 장(세로로 쌓은 아틀라스)에 모으고, 아니면 그림마다 텍스처를 따로 둔다(05 §5 P4)

const WHO := ["aias", "chronos", "ignis", "seraphina", "sylvia", "vesper", "hero"]
const ANIMS := ["idle", "walk", "attack", "fall"]
const WALLS := ["wall", "front"]
# 성벽 시험 그림(6칸, 원점 픽셀 (4, 100))에서 칸 하나 폭으로 자를 칸: 평범한 벽, 열린 문, 닫힌 문(tools/art/wall.py GATES)
const WALL_STRIP := {"castle_wall": 3, "open": 1, "gate": 4}

var sets := []  # WHO 순서: {c: 캔버스 px, anchor: 발밑 기준점}
var _tex := {}  # 그림 이름 → [텍스처, 아틀라스 안 위치]

func _init(packed: bool) -> void:
	var base := ProjectSettings.globalize_path("res://art/trial/")
	var names := []
	for who in WHO:
		var f: Array = JSON.parse_string(FileAccess.get_file_as_string("res://art/trial/%s/fit.json" % who)).fits["24"]
		sets.append({"c": int(f[2]), "anchor": Vector2(f[1][0], f[1][1])})
		for a in ANIMS:
			names.append("%s/%s_45_D_f24p_24.png" % [who, a])
	for w in WALLS:
		names.append("walls/%s_45_f24p_24.png" % w)
	var images := names.map(func(n): return Image.load_from_file(base + n))
	if not packed:
		for i in names.size():
			_tex[names[i]] = [ImageTexture.create_from_image(images[i]), Vector2.ZERO]
		return
	var w := 0
	var h := 0
	for im in images:
		w = maxi(w, im.get_width())
		h += im.get_height()
	var atlas := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var y := 0
	var off := []
	for im in images:
		im.convert(Image.FORMAT_RGBA8)
		atlas.blit_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i(0, y))
		off.append(Vector2(0, y))
		y += im.get_height()
	var tx := ImageTexture.create_from_image(atlas)
	for i in names.size():
		_tex[names[i]] = [tx, off[i]]

# 시트 s(WHO 번호)의 anim 한 칸: [텍스처, 영역]. 공격·쓰러짐은 2배 캔버스다(hero.py). 쓰러짐은 방향 없는 한 줄이다
func frame(s: int, anim: String, dir: int, col: int) -> Array:
	var t: Array = _tex["%s/%s_45_D_f24p_24.png" % [WHO[s], anim]]
	var size: int = sets[s].c * (2 if anim in ["attack", "fall"] else 1)
	var row := 0 if anim == "fall" else dir
	return [t[0], Rect2(t[1] + Vector2(col * size, row * size), Vector2(size, size))]

# 성벽 칸 하나: [텍스처, 영역]. layer는 "wall"(몸체) 또는 "front"(흉벽·앞면, 성벽 위 유닛의 발을 가린다)
func wall(layer: String, strip: String) -> Array:
	var t: Array = _tex["walls/%s_45_f24p_24.png" % layer]
	return [t[0], Rect2(t[1] + Vector2(4 + WALL_STRIP[strip] * 16, 0), Vector2(16, 104))]

# 화면 방향 v(y가 아래)의 시트 행: S, SE, E, NE, N, NW, W, SW(tools/art/render.py DIRS)
static func dir_of(v: Vector2) -> int:
	return posmod(roundi((90.0 - rad_to_deg(v.angle())) / 45.0), 8)
