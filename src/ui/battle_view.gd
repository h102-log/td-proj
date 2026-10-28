extends Node2D
# 전투 상태를 칸 단위로 그린다. 바닥은 타일(4.1b), 영웅은 도트 스프라이트(S165), 용병·적은 4방향 스프라이트(4.1d), 시설은 그림(4.1e), 나머지는 아직 도형이다(그레이박스, 아트는 WBS 4.1).

const CELL := 16
const Camera := preload("res://src/ui/camera.gd")
const Settings := preload("res://src/settings.gd")
const Folk := preload("res://src/sim/folk.gd")
const COLORS := {
	"grid": Color(0, 0, 0, 0.15), "spawn": Color("c03030"), "merc": Color("50a0f0"),
	"engineer": Color("f0a030"), "archer": Color("60d0a0"),
}
const ENEMY_COLORS := {  # 적 종류마다 다른 색(I81)
	"basic": Color("d04040"), "fast": Color("f08030"), "armored": Color("807070"), "flying": Color("e050c0"), "boss": Color("801010"),
	"slime": Color("50b050"), "slimelet": Color("98e070"), "big_slime": Color("2f7a3a"), "slime_king": Color("3aa0a0"),
	"wolf": Color("8a7a68"), "leap_wolf": Color("b08850"), "night_wolf": Color("3a3a58"), "alpha_wolf": Color("d8d8d0"),  # 그림(2라운드 PR ③) 전까지 색 원
}
const HERO_COLORS := {  # 영웅 종류마다 다른 색(S56, S157, I101)
	"aias": Color("b060f0"), "sylvia": Color("a0ff40"), "seraphina": Color("f0f0f0"), "vesper": Color("40c060"), "ignis": Color("ff5020"), "chronos": Color("ffd020"),
}
# 구조물·성곽 칸에 걸린 효과의 테두리 색(I101): 받는 피해 감소·공격 속도. 에너지 성벽 칸은 벽 조각이다(_wards, fx-2).
# 유닛에 걸린 효과는 테두리 대신 효과마다 조각 하나다(status_marks, I101 2026-10-27 변경)
const MARKS := {"dr": Color("80c0ff"), "haste": Color.ORANGE}
const EYES := Color("f0e060")  # 어둠 속에 숨은 밤 늑대의 눈빛(S240, I193 ④)
const ZONES := {  # 장판 색(I101). 성기게 칠하고 테두리를 그린다. 이그니스(4.1s)·아이아스·실비아(fx-2) 장판은 재질이라 색표에 없다
	"seraphina_w": Color("fff0a0"), "vesper_q": Color("60c040"), "vesper_r": Color("402060"), "chronos_e": Color("ffd020"), "chronos_r": Color("40e0ff"),
}

const UNITS := preload("res://art/units/heroes.png")  # 영웅 6명과 용병·적 시트를 한 장에 모은 아틀라스(tools/art/atlas.py)
static var ART: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/units/heroes.json"))  # 종류 → 캔버스·발밑·시트 y
const LUNGE := 6.0  # 근접 돌진 거리(px). 림월드 0.35칸을 16px 칸으로 옮겼다(06 §4)
const CONTACT := 0.08  # 근접 공격이 대상에 닿는 때(친 뒤 초). 돌진(_lunge)이 가장 멀리 나간 때다
const FLASH := 0.1  # 피격 흰 번쩍임 길이(초, S177)
const FLINCH := 3.0  # 피격 밀림(px, S177). 림월드 0.17칸을 16px 칸으로 옮겼다(06 §4)
const FLINCH_BACK := 0.17  # 밀린 몸이 돌아오는 시간(초, 06 §4 약 10프레임)
const HITSTOP := 3.0 / 60.0  # 영웅이 치거나 맞은 타격에서 두 유닛의 그림만 멈추는 시간(초, S177). 시뮬레이션은 멈추지 않는다
const MUZZLE := {"tower": Vector2(0, -15), "magic": Vector2(0, -24), "cannon": Vector2(0, -6)}  # 칸 가운데에서 쏘는 곳(px, 4.1e 그림): 지붕 밑 발판, 수정, 포신
const BALL_ARC := 12.0  # 대포알 포물선 꼭대기 높이(px)
const BLAST := 0.25  # 대포알이 떨어진 곳의 범위 피해 고리가 퍼지는 시간(초)
const FX := 0.3  # 즉시 스킬 흔적(S179)이 퍼지고 사라지는 시간(초). 범위 원(S72)의 0.3초를 이었다
const FX_COLORS := {"slam": Color("ff3020")}  # 영웅 색이 아닌 흔적(S179): 보스 강타(S195)는 예고 색
const FX_TEX := preload("res://art/fx/fx.png")  # 이펙트 도트 조각 아틀라스(tools/art/fx.py, 4.1s)
static var FX_ART: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/fx/fx.json"))  # 조각 → [x, y, 폭, 높이, 프레임 수]
# 이펙트 색(4.1s): F24+와 이펙트 확장 램프(보라·연두)만 쓴다(tools/art/palettes.json f24p·fx)
const PX := {
	"cream": Color("efd8a1"), "gold": Color("efac28"), "orange": Color("ef692f"), "red": Color("ef3a0c"), "blood": Color("9b1a0a"), "maroon": Color("550f0a"),
	"soot": Color("2a1d0d"), "dark": Color("392a1c"), "smoke": Color("684c3c"), "ash": Color("927e6a"), "teal": Color("3c9f9c"), "deepteal": Color("183f39"),
	"ice0": Color("d0d6e0"), "ice1": Color("a4aec2"), "ice2": Color("7a86a0"), "ice3": Color("4f78ad"), "ice4": Color("3a4357"), "navy": Color("262d3d"), "night": Color("151a26"),
	"vio0": Color("e0c8f8"), "vio1": Color("b080e0"), "vio2": Color("8040c0"), "vio3": Color("4a2878"), "vio4": Color("2a1840"),
	"lime0": Color("e6f7a8"), "lime1": Color("b6e357"), "lime2": Color("7fbf3b"), "lime3": Color("4a8c2a"), "lime4": Color("28561e"),
}
const EMBER := ["gold", "orange", "red", "blood"]  # 불티가 식는 차례
const ZONE_OPEN := 0.2  # 장판이 펼쳐지는 시간(초, 4.1s)
const ZONE_CLOSE := 0.3  # 장판이 사라지며 줄어드는 시간(초, 4.1s)
const BOOM_STEP := 4.0 / 60.0  # 폭발 조각 한 프레임(초). Saint11 예시 80ms에 가깝게(vfx_research/02)
const FLAMES := 7  # 불길 장판의 불꽃 조각 수. 시안 C의 9개가 고블린을 가렸다(Gemini 고칠 점 2)
# 아이아스·실비아(fx-2). 시간은 초다
const SWEEP := 0.18  # 방패 강타 베기가 반경까지 퍼지는 시간. 그 뒤 FX까지 가는 호가 남는다
const CRY_ECHO := 0.08  # 전장의 포효 둘째 충격파가 늦게 나오는 시간
const SPARK_STEP := 3.0 / 60.0  # 스킬에 맞은 섬광 한 프레임
const GALE_REACH := 0.06  # 관통의 바람살이 맵 끝까지 뻗는 시간
const WALL_RISE := 0.2  # 에너지 성벽 칸이 아래에서부터 드러나는 시간
const RAIN := 14  # 화살비 장판 하나에 화살이 떨어지는 자리 수
const RAIN_CYCLE := 0.9  # 한 자리에 화살이 다시 떨어지는 주기
const RAIN_FALL := 0.12  # 화살이 떨어지는 시간. 그 뒤 꽂힌다
const RAIN_STUCK := 0.6  # 꽂힌 화살이 남는 시간
const ALLY_FX := ["dr", "haste", "shield", "invuln", "stun", "bleed"]  # 아군에 걸린 효과(I101, 기절은 I192, 출혈은 I193 ③)
const FOE_FX := ["stun", "root", "slow", "expose", "taunt", "seal", "chain", "dot"]  # 적에 걸린 효과(I101)
const TELL := Color("ff3020")  # 보스 스킬 예고(S194): 빨간 테두리, 안쪽이 차오른다
const RAGE := Color(1.5, 0.55, 0.55)  # 분노한 보스(S195)를 붉게 그리는 modulate
const CROUCH := Vector2(1.15, 0.75)  # 슬라임 킹이 웅크림 끝에 납작해지는 배율(가로·세로, S198). 임시값
const LEAP_UP := 10.0  # 뜬 슬라임 킹을 한가운데에서 들어 올리는 높이(px, S198). 임시값
const FALL := 0.5  # 운석이 보이며 떨어지는 시간(초). 이그니스 R의 첫 운석 지연(delay)과 같다
const CORPSE_FADE := 0.5  # 쓰러진 적·용병의 몸이 시뮬레이션에서 지워지기(battle.FALLEN) 전에 흐려지는 시간(초, S180)
const FALL_STEP := 0.08  # 영웅 쓰러짐 5프레임의 한 프레임 길이(초, S180)
const HEAVY := 6.0  # 보스가 친 타격·보스 스킬에 맞은 아군의 밀림(px, S198)
const HEAVY_BACK := 0.25  # 그 밀림이 돌아오는 시간(초, S198)
const KILL_PUSH := 6.0  # 막타가 닿은 쓰러진 몸이 번쩍이는 동안 밀리는 거리(px, S197). 밀린 자리에 눕는다
const LIFT := 0.4  # 보스 스킬 예고의 마지막 이만큼 그림을 들어 올린다(초, S198)
const SLAM_POSE := 0.15  # 보스 스킬이 발동한 뒤 공격 자세(초, S198)
const FILL := 2  # 발동한 처음 이만큼의 프레임은 예고 모양을 채운다(S198). 시간이 아니라 프레임으로 세어 프레임률과 상관없이 2프레임이다
const SLIDE := 400.0  # 넉백·끌어옴 미끄러짐: 거리/SLIDE초, 0.12~0.3초(S198)
const DUST := Color("927e6a")  # 먼지(F24+)
const CRACK := [Color("1f240a"), Color("a56243")]  # 바닥 균열의 어두운 금과 그 아래 밝은 가장자리(F24+). 어두운 금만으로는 풀 위에서 안 보였다(시안 V2)
const JOLT := 0.05  # 맞은 구조물·성곽 칸·거점 그림을 1px 옮겨 그리는 시간(초, 3프레임, S199)
const DEBRIS := Color("efd8a1")  # 구조물 부스러기(S199): 돌 회청색·나무 갈색과 다른 밝은 모래색(F24+). 시안의 재질 색은 거의 안 보였다
const BAR_TIERS := [Color("ef3a0c"), Color("e0c040"), Color("7cc85a")]  # 구조물·성곽·거점 막대(S199): 25% 밑·50% 밑·그 위. 위 띠 거점 막대(S190)의 HudTheme.DANGER·HudBuild.WARN·HudTheme.GOOD와 같은 값
const SOFT_FLASH := Color(255, 255, 255, 0.4)  # 번쩍임 줄이기(S184): 같은 그림을 255배·알파 0.4로 덧그리면 흰 40%다(S177, S197)
const STONE := Color("7a86a0")  # 무너진 성곽 칸에서 떨어지는 돌 조각(S200, F24+ 성벽 돌색)
const DROP := 0.15  # 무너진 성곽 칸 위 유닛이 땅으로 내려오는 시간(초, S200)
const RIM := 8  # 맵 둘레에 맵 밖 바닥색으로 칠하는 폭(px, S200). 화면 흔들림(최대 3 기준 화면 px)이 가장자리에서 빈 곳을 보이지 않게
const PIXEL_FONT := preload("res://art/fonts/Galmuri7.ttf")  # 맵 위 숫자(S167). 맵은 640×360을 정수배로 키우므로 벡터 글자는 뭉개진다
const GROUND_TILES := preload("res://art/tiles/ground.png")  # 0행 풀↔흙 꼭짓점 16꼴, 1행 풀·흙 변종과 깃발, 2·3행 전환 꼴 변종(tools/art/tiles.py)
const DECOR := preload("res://art/tiles/decor.png")  # 들판·마을 장식(S201·S202, tools/art/decor.py): 0행 16×16 바위 3·그루터기 2·구덩이 2·자갈 2·풀 2·풀꽃·우물, 1행 48×32 그을음 3, 2행 48×48 마른 나무 4, 3행 16×16 마당 소품(S215)
const YARD_ROW := 96  # decor.png 3행(마당 소품)의 y: 텃밭 2·울타리 2·장작더미·목재 더미·톱밥·판석. 그림은 칸 왼쪽 위에 붙어 있다
const YARDS := {"house": 0, "church": -4, "barracks": 10, "workshop": 0, "archery": 0}  # 터가 있는 시설(S215) → 터 가로 반지름에 더하는 px(yard_radius)
# 다 지은 시설의 마당 소품(S215): 변형마다 [decor.png 3행 열, 구조물의 칸 왼쪽 위에서 본 그림 자리(px)]. 칸 x+y로 변형을 고른다.
# 자리는 지금 크기(S216: 집 2×2·작업장 3×2·교회 2×3)에 맞춘 것이다. 크기를 바꾸면 다시 정한다
const YARD_PROPS := {
	"house": [[[0, Vector2(33, 3)], [2, Vector2(-14, 12)], [4, Vector2(-6, 9)]], [[1, Vector2(-15, 3)], [3, Vector2(32, 12)], [4, Vector2(31, 9)]]],
	"workshop": [[[5, Vector2(47, 9)], [6, Vector2(-4, 15)]]],
	"church": [[[7, Vector2(9, 16)]]],
}
const PAVE := Color("56607a")  # 돌길·광장 박석 색(S202)
# 수로·연못(S220, tools/art/water.py): 바닥 위 물 덮개와 북벽 수문 덮개, 얹는 맵 px 왼쪽 위.
# ponytail: 자리는 _plan의 물 칸(45열 수로·44~49열 연못)에 맞춘 지금 판 값이다. 판이 늘면 _plan과 함께 옮긴다
const WATER := preload("res://art/tiles/water.png")
const WATER_AT := Vector2i(672, 0)
const CULVERT := preload("res://art/castle/culvert.png")
const CULVERT_AT := Vector2i(712, 16)
const FOREST_FLOOR := Color("2a1d0d")  # 맵 아래 맵 밖 띠(I50)의 바닥(S201): 마른 나무가 선 그을린 흙
const CASTLE := preload("res://art/castle/walls.png")  # 성곽 조각(두께 3칸, S217): 행 단계 1~3마다 몸체·앞층, 통로 그늘, 잔해. 열 성벽 한 열·열린 문·닫힌 문·문 양옆 탑(tools/art/atlas.py castle)
const WALL_PIECE_H := 105  # 성곽 조각 높이(px). 맨 아랫줄이 앞줄 바닥선 바로 위 줄이고 윗줄은 양옆 탑 뒤 모서리다
const WALL_COLS := {"castle_wall": [0, 16], "open": [16, 48], "closed": [64, 48], "tower_l": [112, 16], "tower_r": [128, 16],
	"n_wall": [144, 16], "n_closed": [160, 48], "n_tower_l": [208, 16], "n_tower_r": [224, 16], "sc_l": [240, 48], "sc_r": [288, 48],
	"nc_l": [336, 48], "nc_r": [384, 48], "w_strip": [432, 48], "e_strip": [480, 48], "w_gate": [528, 48], "e_gate": [576, 48]}  # 조각 열 [x, 폭](px)
const WALL_TOP_UP := 25  # 성벽 그림 윗변이 성곽 윗줄 위끝보다 높은 px(S175)
const GATE_RISE := 17  # 문루 바닥이 성벽 통로보다 높은 px(S170, tools/art/wall.py와 같다)
const TOWER_RISE := 27  # 문 양옆 탑 바닥이 성벽 통로보다 높은 px(S170, tools/art/wall.py와 같다)
const SIDE_GATE_RISE := 8  # 동·서 닫힌 문루 바닥이 통로보다 높은 px(S219, tools/art/wall.py와 같다)
const CORNER_RISE := 12  # 모서리 탑 바닥이 통로보다 높은 px(S219, tools/art/wall.py와 같다)
const TOP_BAND := 92  # 맵 위 맵 밖 띠 높이(맵 px): 카메라가 위로 보이는 최대(1배 줌, I50 2026-10-26 변경). 4의 배수라 밤 덮개 디더가 맵 칸과 맞는다
const RING := 4  # 문루·탑 둘레 난간 높이(px). 그 그림 윗변은 바닥보다 이만큼 더 높다(wall.py ph 0.32 = 3.6px)
const KEEP := preload("res://art/castle/keep.png")  # 거점 망루 80×80, 마을 레벨 1·2. 칸 앞쪽 아래 왼쪽 모서리가 그림의 (32, 72)다(tools/art/keep.py)
const KEEP_AT := Vector2(-32, CELL - 72)  # 거점 칸 왼쪽 위에서 본 망루 그림 왼쪽 위
const KEEP_BODY := [Rect2(29, 23, 22, 49), Rect2(21, 13, 38, 59)]  # 마을 레벨 1·2 망루 그림의 불투명 사각형(keep.png를 잼). 그림을 바꾸면 다시 잰다
const FACILITY := preload("res://art/castle/facility.png")  # 시설 96×96: 0행 그림, 1행 청사진 바탕. 구조물의 칸(차지 칸의 앞 왼쪽 칸, S216) 앞쪽 아래 왼쪽 모서리가 그림의 FAC_FOOT다(tools/art/facility.py)
const FAC_N := 96  # 시설 그림 한 칸의 크기(px)
const FAC_FOOT := Vector2(16, 92)
static var FAC: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/castle/facility.json"))  # 종류 → [열, 그림 맨 윗줄, 맨 아랫줄 + 1]
# 금(S199)을 구운 성곽·시설·망루 아틀라스(I172). 원본 대신 이것으로 그려서 금이 생겨도 텍스처가 바뀌지 않는다. 성곽은 앞층(바깥 벽면)에만 긋는다
static var CASTLE_K: ImageTexture = crack_atlas(CASTLE, _wall_pieces())
static var FACILITY_K: ImageTexture = crack_atlas(FACILITY, FAC.values().map(func(f): return Rect2i(FAC_N * int(f[0]), int(f[1]), FAC_N, int(f[2] - f[1]))))
static var KEEP_K: ImageTexture = crack_atlas(KEEP, [Rect2i(0, 0, 80, 80), Rect2i(80, 0, 80, 80)])
const BLUEPRINT := Color(0.55, 0.78, 1.0, 0.6)  # 청사진 색(사용자 2026-10-20, 림월드 설계도). 회색 바탕에 곱한다
const GHOST := Color(1, 1, 1, 0.4)  # 거점에 가려진 유닛·시설을 덧그리는 색(C1, 사용자 2026-10-20). 성벽·거점에 가려진 영웅의 마나 막대도 이 색이다
const SHADE := Color(0, 0, 0, 0.55)  # 성벽에 가려진 부분의 실루엣 색(S175). 55%는 사용자가 고른 시안의 합성 색에 맞춘 Claude 값
const WALL_H := 24  # 성벽 앞면 높이(px, 4.0 확정값)
const TEAM := [Color("3c9f9c"), Color("ef3a0c")]  # 발밑 팀 색(S166): 아군 청록, 적 빨강(F24+ 팔레트)
const ORDER_MARK := 0.4  # 명령 표식이 보이는 시간(초, S205)
const ORDER_COLORS := [Color("40ff80"), Color("ef3a0c")]  # 명령 표식(S205): 이동 초록, 공격 빨강(적 발밑 색)
const SELECT_GLOW := 1.9  # 고른 것의 발밑 타원 밝기 배율(S207)
const SELECT_LINES := [Color("d8fff6"), Color("ffb0a0")]  # 발밑 선택 테두리(S207): 고른 유닛, 선택 패널의 적
const GHOST_OK := Color.WHITE  # 놓기 미리보기(S216): 지을 수 있음
const GHOST_NO := Color("ef3a0c")  # 지을 수 없음(적 발밑 빨강)
static var FEET: ImageTexture = _feet()  # 발밑 채운 타원 14×6px. 아군·적을 한 장에 나란히 둬서 draw call이 끊기지 않는다
const NIGHT_COLOR := Color("0b1030")  # 어둠 덮개 색(S212)
const TORCH := Color("ffb060")  # 불빛 가장자리에 엷게 비치는 횃불 색(S212)
const NIGHT_ALPHA := 0.85  # 불빛 밖 덮개 불투명도 = 이 값 × 어둠(S212)
const TORCH_ALPHA := 0.25  # 횃불 색이 가장 짙은 곳(불빛 단계의 가운데)의 불투명도 × 어둠(S212)
const NIGHT_LIGHTS := 128  # 덮개 셰이더에 넘기는 불빛 수 상한. 넘으면 앞의 것만 그린다. 적이 보이는지는 시뮬레이션이 모든 불빛으로 본다(S213)
# 어둠 덮개(S212): 맵 px마다 가장 밝은 불빛을 고르고(반경의 절반까지 1, 반경에서 0), 4×4 바이어 디더로 4단계로 끊는다.
# 화면 px마다 돌지만 맵 px(UV × 덮개 크기의 내림)로 끊어 도트처럼 보인다
const NIGHT_SHADER := """shader_type canvas_item;
uniform float dark = 0.0;
uniform float alpha;
uniform float torch_alpha;
uniform int count = 0;
uniform vec4 lights[%d];
uniform vec2 px_size = vec2(1.0);
uniform vec2 origin = vec2(0.0);
uniform vec4 night_color : source_color;
uniform vec4 torch_color : source_color;
const float BAYER[16] = float[](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
void fragment() {
	vec2 local = floor(UV * px_size) + 0.5;
	vec2 p = local + origin;
	float lit = 0.0;
	for (int i = 0; i < count; i++) {
		lit = max(lit, 1.0 - smoothstep(0.5, 1.0, distance(p, lights[i].xy) / lights[i].z));
	}
	ivec2 q = ivec2(local) %% 4;
	float s = clamp(floor(lit * 4.0 + BAYER[q.y * 4 + q.x] / 16.0) / 4.0, 0.0, 1.0);
	float a = alpha * dark * (1.0 - s);
	float g = torch_alpha * dark * 4.0 * s * (1.0 - s);
	COLOR = vec4((night_color.rgb * a + torch_color.rgb * g) / max(a + g, 0.0001), a + g);
}
""" % NIGHT_LIGHTS

var battle
var controls  # 고른 유닛에 테두리를 그린다
var _seen := {}  # 영웅·용병·적 → [지난 위치, 방향]
var _hits := {}  # 방금 맞은 영웅·용병·적 id → [맞은 뒤 지난 시간(초), 공격자 → 대상 방향, 무거운 타격](S177, S198). _bodies마다 다시 구한다
var ground: ImageTexture  # 바닥을 한 장으로 구운 것. 마을·출현 지점은 도전 내내 같아서(I91) 처음 한 번만 굽는다
var _decor := []  # 바닥 소품(S201·S202): [칸, decor.png 0행 열]. 바닥과 함께 처음 한 번만 정한다
var _under: Image  # 구운 바닥. 터(bake_yard)가 돌 위를 피하려고 읽는다
var _yards := {}  # [칸, 종류] → bake_yard 결과. 시설이 처음 보일 때 한 번 굽고, 없어지면 버린다(S215)
var _clip := -INF  # 덧그릴 때 이 화면 y보다 위 줄은 그리지 않는다(_shade)
var clock := 0.0  # 화면 시계(I170): 시뮬레이션 step과 같은 delta를 더한다(tick). ESC 메뉴면 main이 멈춰 같이 멈춘다
var events := []  # 이번 프레임에 새로 생긴 사건(I171): {kind, at, dir, src, dst, n, heavy}. 연출과 효과음(WBS 5.3)이 읽는다
var _n := 0  # 사건 번호. 효과 모양의 무작위 씨앗이다(I170)
var _live := false  # 이번 프레임에 사건을 내나(I171)
var _primed := false  # 첫 tick은 이미 있던 흔적·잔해·쓰러짐을 사건으로 내지 않고 기억만 한다
var _from_battle := false  # 전투에서 결과 단계로 넘어왔다(I171)
var _atk := {}  # 공격자 id → [지난 친 뒤 시간, 그 공격이 닿았나]. 공격 하나에 닿음은 한 번이다(I171)
var _dead := {}  # 처치 사건을 기다리는 쓰러진 대상 id → [대상, 처음 본 시각, 쓰러질 때 보던 방향]. 그동안 선 자세로 그린다(S197)
var _killed := {}  # 막타가 닿은 쓰러진 대상 id → [닿은 시각, 밀리는 방향(없으면 0), 대상, 보던 방향](S197). 몸이 남은 동안만 둔다
var _gone := {}  # 지난 프레임까지 본 쓰러짐(fallen) id
var _known := []  # 본 흔적. traces는 step마다 새 배열이라 is_same으로 견준다
var _rubble := {}  # 본 잔해 칸
var _tell := {}  # 보스 id → [예고 가운데(맵 px), 반경(px)]. 예고가 끊기면 둘레에 조각을 흩는다(S198)
var _dots := []  # 효과 점(I172): {p0, p1, rise, t0, life, fade, col, size, ground}
var _slides := {}  # id → [지난 화면 자리, 시작 시각, 길이](S198 미끄러짐)
var _fills := []  # [보스 스킬 흔적, 남은 프레임](S198 발동 채움). tick마다 하나씩 줄인다
var _zone_t0 := []  # [장판, 처음 본 화면 시각](4.1s 펼침). 장판은 Dictionary라 is_same으로 찾는다
static var _cells := {}  # Vector3i(반지름, 굵기, 0 고리 · 1 원판) → 아트 px 칸 오프셋
static var _runs := {}  # 같은 열쇠 → 줄마다 이은 Rect2i(draw_rect 수를 줄인다)
static var _noise := {}  # Vector3i(반지름, 밀도, 변형) → 성긴 칠 흰 마스크 텍스처
var _caps := {}  # 절대 방어선 둘레(fx-2): 칸 배치 + 반지름 → capsule_cells. 둘레가 없으면 비운다
var _last := {}  # id → [지난 프레임 화면 자리, 성벽 위·기어오르기 상태]
var _order := {}  # 마지막으로 본 명령(controls.order, S205)
var _order_t0 := 0.0  # 그 명령을 처음 본 화면 시각
var _shots := {}  # 날고 있는 투사체 id → 출발 자리(맵 px). 처음 그릴 때 쏜 쪽의 쏘는 곳이다
var _landed := {}  # 지난 프레임까지 본 닿은 투사체(battle.landed) id. 닿음·처치는 투사체 하나에 한 번이다(I171)
var night: ColorRect  # 어둠 덮개(S212): 바닥 그림(맵 밖 아래 띠까지)을 덮는 사각형 하나에 셰이더를 바른다. 맵의 자식이라 맵 그림 다음에 그린다
var _top: Node2D  # 덮개 위 층: 조준 미리보기·출현 배지·체력 막대·명령 표식·드래그 사각형(_draw_top). 덮개 다음 자식이다
var _cv: CanvasItem = self  # _draw_top의 그리기 함수가 그리는 곳. 층이 없으면(트리 밖에서 만든 맵) 맵 자신이다
var _foes := []  # 이번 프레임에 보이는 적(S213). 숨은 적은 몸·발밑·막대·효과 테두리·예고를 그리지 않는다
var _folk_now := []  # 이번 프레임의 주민 [주민 몸(battle.people), folk_of]. 덮개 위 층이 야경꾼 등불을 그 자리에 그린다(S223)

func _ready() -> void:
	if battle:
		_night_layer()

# 어둠 덮개(S212)와 그 위 층. 덮개는 클릭을 받지 않고, 낮에는 숨는다
func _night_layer() -> void:
	night = ColorRect.new()
	night.position = Vector2(0, -TOP_BAND)  # 맵 위 띠(I50)까지 덮는다
	night.size = Vector2(battle.size.x * CELL, TOP_BAND + battle.size.y * CELL + int(Camera.BOTTOM))
	night.mouse_filter = Control.MOUSE_FILTER_IGNORE
	night.visible = false
	var sh := Shader.new()
	sh.code = NIGHT_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("px_size", night.size)
	mat.set_shader_parameter("origin", night.position)
	mat.set_shader_parameter("alpha", NIGHT_ALPHA)
	mat.set_shader_parameter("torch_alpha", TORCH_ALPHA)
	mat.set_shader_parameter("night_color", NIGHT_COLOR)
	mat.set_shader_parameter("torch_color", TORCH)
	night.material = mat
	add_child(night)
	_top = Node2D.new()
	_top.draw.connect(func():
		_cv = _top
		_draw_top()
		_cv = self)
	add_child(_top)

# 눈빛만 그리는 적(S240): 어둠 속에 숨은 밤 늑대
func eyes() -> Array:
	return [] if battle.dark <= 0.0 else battle.enemies.filter(func(e): return not e.night.is_empty() and not battle.seen(e.pos))

# 맵에 그리는 적(S213): 어둠 속에 숨은 적은 뺀다
func foes() -> Array:
	return battle.enemies if battle.dark <= 0.0 else battle.enemies.filter(func(e): return battle.seen(e.pos))

# 덮개 셰이더에 지금 어둠과 불빛(맵 px 가운데·지금 반경 px)을 넘긴다. 낮이면 그리지 않는다
func night_params() -> Dictionary:
	var pts := PackedVector4Array()
	pts.resize(NIGHT_LIGHTS)
	var n := 0
	if battle.dark > 0.0:
		for l in battle.lights.slice(0, NIGHT_LIGHTS):
			var c: Vector2 = l[0] * CELL + Vector2(CELL, CELL) / 2.0
			pts[n] = Vector4(c.x, c.y, minf(l[1] / battle.dark, 4096.0) * CELL, 0.0)
			n += 1
	return {"dark": battle.dark, "count": n, "lights": pts}

func _draw() -> void:
	if ground == null:
		ground = bake_ground(battle)
		_decor = ground_props(battle)
		_under = ground.get_image()
	_foes = foes()
	# 맵 위 맵 밖 띠(I50): 사방 성곽의 북벽 그림이 맵 위로 솟는다(S219). 둘레 RIM까지 칠해 화면이 흔들려도(S200) 빈 곳이 안 보인다. 바닥 그림이 그 위를 덮는다
	draw_rect(Rect2(-RIM, -TOP_BAND - RIM, battle.size.x * CELL + 2 * RIM, TOP_BAND + battle.size.y * CELL + int(Camera.BOTTOM) + 2 * RIM), FOREST_FLOOR)
	draw_texture(ground, Vector2.ZERO)  # 카메라가 아래로 보이는 맵 밖(I50)까지 한 장이다
	var yards := {}
	for s in battle.structures.values():  # 시설 터(S215). 바닥을 다시 구우면 75ms라 시설마다 따로 구운 그림을 얹는다
		if YARDS.has(s.kind):
			var k := [s.cell, s.kind]
			yards[k] = _yards[k] if _yards.has(k) else bake_yard(battle, s, _under)
			draw_texture(yards[k][0], yards[k][1])
	_yards = yards
	for p in _decor:  # 시설이 선 칸의 소품은 감춘다(S201)
		if not battle.footprint.has(p[0]):
			draw_texture_rect_region(DECOR, Rect2(Vector2(p[0]) * CELL, Vector2(CELL, CELL)), Rect2(p[1] * CELL, 0, CELL, CELL))
	for s in battle.structures.values():
		for p in yard_props(s):
			if not battle.water.has(Vector2i((p[1] + Vector2(CELL, CELL) / 2.0) / CELL)):  # 소품 가운데가 물 칸이면 그리지 않는다(I181)
				draw_texture_rect_region(DECOR, Rect2(p[1], Vector2(CELL, CELL)), Rect2(p[0] * CELL, YARD_ROW, CELL, CELL))
	for r in battle.rubble.values():  # 잔해(I88)는 바닥 층: 몸통과 정렬하지 않고 장판·발밑·쓰러진 몸보다 먼저 깐다(S170 2026-10-28)
		_wall_piece(r, 0)
	if controls.placing != "":  # 격자선은 놓기 모드에서만(4.1b, 사용자 2026-10-20)
		var map := Vector2(battle.size) * CELL
		for x in battle.size.x + 1:
			draw_line(Vector2(x * CELL, 0), Vector2(x * CELL, map.y), COLORS.grid)
		for y in battle.size.y + 1:
			draw_line(Vector2(0, y * CELL), Vector2(map.x, y * CELL), COLORS.grid)
	for s in battle.structures.values():  # 시설 그림은 _bodies가 유닛과 함께 정렬해 그린다(4.1e)
		if s.dest != null:  # 옮겨 갈 칸(S44): 청사진 색 테두리와 대포에서 이어지는 점선. 칸의 대포 청사진은 _bodies가 그린다(S176)
			draw_rect(_rect(s.dest), Color(BLUEPRINT, 1.0), false, 1.0)
			draw_dashed_line(_center(Vector2(s.cell)), _center(Vector2(s.dest)), Color(1, 1, 1, 0.7), 1.0, 3.0)
	_zones()
	_wards()  # 에너지 성벽 칸(S151, fx-2): 장판 다음, 몸통 아래
	for e in _foes:  # 보스 스킬 예고(S194): 빨간 테두리 안쪽이 남은 시간만큼 차오른다. 숨은 보스(S213)는 그리지 않는다
		if e.cast:
			var sk: Dictionary = e.skills[e.cast.id]
			var at := _center(e.cast.get("at", e.pos))  # 점프(S236)는 착지 자리에, 뜬 동안은 가득 찬 채로(S198)
			var k: float = 1.0 if e.cast.get("air", false) else 1.0 - e.cast.left / sk.windup
			draw_circle(at, CELL * sk.radius * k, Color(TELL, 0.35))
			draw_arc(at, CELL * sk.radius, 0.0, TAU, 48, Color(TELL, 0.9), 1.0)
	for f in _fills.filter(func(f): return battle.seen(f[0].at)):  # 보스 스킬이 발동하면(S198) 처음 FILL프레임은 예고 모양 안을 예고색으로 채운다
		draw_circle(_center(f[0].at), CELL * f[0].radius, Color(TELL, 0.6))
	_fx_dots(true)  # 바닥 균열(S198)은 몸통 아래
	_traces(false)  # 폭발 연기·운석 그림자는 몸통 아래(4.1s, Gemini 고칠 점 2)
	for p in battle.forecast:  # 기본 적의 예상 경로(S142): 엷은 빨간 선, 유닛 아래에. 너비 1이면 1배 줌에서 칸 중심을 지나는 가로·세로 구간이 안 그려진다
		draw_polyline(PackedVector2Array(p.map(func(c): return _center(Vector2(c)))), Color(COLORS.spawn, 0.5), 1.5)
	for h in battle.heroes:  # 오라 반경(S113): 오라가 있는 살아 있는 영웅마다 둘레에 늘 엷게, 유닛 아래에(I101)
		if h.alive and not h.aura.is_empty():
			_aura_ring(h)
	_bodies()
	_marks()
	for u in battle.units:
		var at := _spot(u) + _slip(u)  # 넉백으로 미끄러지는 몸을 테두리·숫자가 따라간다(S198)
		if u.is_hero:  # 영웅 레벨(I117): 오른쪽 위에 작게
			draw_string(PIXEL_FONT, at + Vector2(CELL * 0.3, -CELL * 0.3), str(u.level), HORIZONTAL_ALIGNMENT_LEFT, -1, 8)
		if u in controls.selected and u.hold:  # 고른 유닛의 표시는 발밑(_feet_mark, S207). 홀드면 기준 반경을 그린다(S36)
			draw_arc(u.anchor * CELL + Vector2(CELL, CELL) / 2, CELL * u.hold_radius, 0.0, TAU, 48, Color(1, 1, 1, 0.4), 1.0)
		_status(u, true)  # 걸린 효과(I101 2026-10-27 변경): 효과마다 수단 하나
	for e in _foes:
		_status(e, false)
	for u in battle.units:  # 마나 막대(S146): 영웅 발밑. 붙잡힌 적에 가리지 않게 적보다 나중에 그린다. 성벽·거점에 가린 영웅은 덧그림처럼 반투명(사용자 2026-10-20)
		if u.is_hero and u.alive:
			var bar := Rect2(_spot(u) + _slip(u) + Vector2(-CELL, CELL) / 2.0, Vector2(CELL, 2))
			var tint := GHOST if _behind(u) else Color.WHITE
			draw_rect(bar, Color.BLACK * tint)
			draw_rect(Rect2(bar.position, Vector2(CELL * u.mana / u.max_mana, 2)), Color("4080ff") * tint)
	for h in battle.heroes:  # 쓰러진 영웅: 복귀할 때까지 쓰러진 자리에 그 영웅 색의 X(I130). 누운 몸(S180) 위에, 막타가 닿은 때부터 밀린 자리에(S197)
		var at = _cross_at(h)
		if at != null:
			var c: Vector2 = at
			var r := Vector2(CELL, CELL) * 0.3
			draw_line(c - r, c + r, HERO_COLORS[h.kind], 2.0)
			draw_line(c + Vector2(-r.x, r.y), c + Vector2(r.x, -r.y), HERO_COLORS[h.kind], 2.0)
	# 원거리 공격은 시뮬레이션 투사체(S178). 근접 공격은 선을 그리지 않는다(S71 변경). 선(화살)과 원(구슬·대포알)이 번갈아 그려지면 배치가 끊겨서 모양끼리 모아 그린다
	var shots: Array = battle.missiles.filter(func(m): return m.wait <= 0.0)
	shots.sort_custom(func(a, b): return a.look < b.look)
	var starts := {}
	for m in shots:
		_missile(m, starts)
	_shots = starts
	for m in battle.landed:  # 대포알이 떨어진 곳에 범위 피해 반경까지 퍼지는 고리
		if m.look == "ball" and m.age < BLAST:
			draw_arc(_spot(m.target), CELL * m.splash * m.age / BLAST, 0.0, TAU, 24, Color(1, 0.8, 0.3, 1.0 - m.age / BLAST), 1.0)
	_fx_dots(false)  # 먼지·조각(I172): 투사체 다음 층에 모아서
	_traces(true)
	# 어둠 덮개(S212)는 맵의 자식이라 여기까지(효과) 위에 그려진다. 그 위 층(_top)이 조준 미리보기·체력 막대·명령 표식·드래그 사각형이다
	if _top:
		_top.queue_redraw()
	else:
		_draw_top()

# 덮개 위 층(S212). 그리기는 _cv(층 또는 맵 자신)에 한다
func _draw_top() -> void:
	_aim_preview()
	if battle.state == "prep":
		_spawn_badges()
	for u in battle.units + _foes:
		var bar := hp_bar_size(u, controls.show_hp)
		if bar != Vector2.ZERO:
			_hp_bar(hp_bar_at(u), u, bar)
	for v in battle.people:  # 다친 주민(S227)은 V와 상관없이 막대를 그린다
		if v.hp < v.max_hp and not v.inside:
			_hp_bar(v.pos, v)
	if battle.dark > 0.0 and not _folk_now.is_empty():  # 야경꾼 등불(S223): 덮개 위 그림이라 불빛·숨긴 적은 그대로다
		for k in _folk_now[1].size():
			if _folk_now[1][k].job == "watchman" and not _folk_now[0][k].inside:
				var lamp := _center(_folk_now[0][k].pos) + LAMP
				_cv.draw_rect(Rect2(lamp - Vector2.ONE, Vector2(3, 3)), Color(TORCH, 0.6))
				_cv.draw_rect(Rect2(lamp, Vector2.ONE), Color("efd8a1"))
	for e in eyes():  # 숨은 밤 늑대의 눈빛(S240, I193 ④): 덮개 위라 어둠 속에서도 보인다. 몸 가운데보다 조금 위, 2px 간격 두 점
		var at := _spot(e) - Vector2(0, CELL * e.radius * 0.5)
		_cv.draw_rect(Rect2(at + Vector2(-2, 0), Vector2.ONE), EYES)
		_cv.draw_rect(Rect2(at + Vector2(1, 0), Vector2.ONE), EYES)
	var cue := order_ring()
	if not cue.is_empty():
		_cv.draw_arc(cue[0], cue[1], 0.0, TAU, 24, cue[2], 1.0)
	if controls.drag_rect.has_area():
		_cv.draw_rect(controls.drag_rect, Color.WHITE, false, 1.0)

# 명령 표식(S205): [가운데(맵 px), 반경(px), 색]. 새 명령을 처음 본 때부터 ORDER_MARK초 동안 줄어든다. 대상 공격은 그 적의 발밑을 따라간다. 없으면 []
func order_ring() -> Array:
	if not is_same(controls.order, _order):
		_order = controls.order
		_order_t0 = clock
	var age := clock - _order_t0
	if _order.is_empty() or age >= ORDER_MARK:
		return []
	var at: Vector2 = _spot(_order.foe) + _slip(_order.foe) if _order.foe else _order.at
	return [at, CELL * lerpf(0.6, 0.2, age / ORDER_MARK), ORDER_COLORS[int(_order.attack)]]

# 곧 부를 웨이브에서 출현 지점마다 나올 적 수(S188): 깃발 칸 바로 위, 풀밭에 묻히지 않게 검은 바탕에 Galmuri7 8px(S167)
func _spawn_badges() -> void:
	var counts: Array = battle.spawn_counts(battle.round_index, battle.wave_index)
	for i in battle.spawns.size():
		var text := str(counts[i].values().reduce(func(n, x): return n + x, 0))
		var w: float = PIXEL_FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		var box := Rect2((Vector2(battle.spawns[i]) * CELL + Vector2(CELL / 2.0 - w / 2.0 - 2.0, -10.0)).round(), Vector2(w + 4.0, 9.0).round())
		_cv.draw_rect(box, Color.BLACK)
		_cv.draw_string(PIXEL_FONT, box.position + Vector2(2, 8), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8)

# 날고 있는 투사체 하나(S178). 출발 자리(처음 그릴 때 쏜 쪽의 쏘는 곳 _muzzle, starts에 남긴다)에서 대상 가슴까지, 시뮬레이션에서 날아간 비율만큼 간 자리에 그린다.
# 화살은 짧은 선, 마법은 쏜 쪽 색 구슬, 대포알은 포물선이다. 대상이 쓰러져 마지막 자리로 가는 대포알은 쓰러진 몸 쪽으로 간다
func _missile(m, starts: Dictionary) -> void:
	var id: int = m.get_instance_id()
	var from: Vector2 = _shots.get(id, _muzzle(m.src))
	starts[id] = from
	var to := _chest(m.target)
	var gone: float = m.from.distance_to(m.pos)
	var k := gone / maxf(gone + m.pos.distance_to(m.at), 1e-6)
	var d := (to - from).normalized()
	var p := from.lerp(to, k)
	match m.look:
		"arrow":
			draw_line(p - d * 5, p, Color("e8dcc0"), 1.0)
		"bolt":
			var col: Color = HERO_COLORS.get(m.src.kind, Color("80b0ff"))
			_blob(p - d * 3, 1, Color(col, 0.5))
			_blob(p, 2, col)
			_blob(p, 0, Color.WHITE)
		"ball":
			_blob(_spot(m.src).lerp(_spot(m.target), k), 1, Color(0, 0, 0, 0.35))
			_blob(p - Vector2(0, 4.0 * BALL_ARC * k * (1.0 - k)), 2, Color("2a2a30"))

# 가운데 c, 반지름 r px의 십자형 도트 덩어리(r 0이면 1px). draw_circle은 원마다 draw call이 하나씩 늘어 사각형 둘로 그린다
func _blob(c: Vector2, r: int, col: Color) -> void:
	draw_rect(Rect2(c - Vector2(r, r - 1 if r > 0 else 0), Vector2(2 * r + 1, maxi(2 * r - 1, 1))), col)
	if r > 0:
		draw_rect(Rect2(c - Vector2(r - 1, r), Vector2(2 * r - 1, 2 * r + 1)), col)

# 쏘는 곳(맵 px). 타워는 그림 위의 쏘는 자리, 유닛은 손 높이다
func _muzzle(x) -> Vector2:
	return _spot(x) + MUZZLE.get(x.kind, Vector2(0, -10))

# 투사체가 닿는 곳: 몸통 가운데(발밑에서 6px 위)
func _chest(x) -> Vector2:
	return _spot(x) + Vector2(0, -6)

# 원거리: 타워, 사거리 2칸을 넘는 영웅·용병. 나머지는 근접이다
func _ranged(x) -> bool:
	return x.get("pos") == null or (x.get("range") != null and x.range > 2.0)

# 즉시 스킬 흔적(S179): 쓴 뒤 영웅 색으로. 범위 스킬은 반경까지 퍼지는 고리, 방향·대상 스킬은 영웅에서 잇는 선이다.
# 이그니스의 화염구 작렬·운석 착탄·서리 고리는 단계 있는 폭발·결정이다(4.1s fx-1). 아이아스·실비아는 베기·충격파·방패·터짐·바람이다(fx-2). 모두 아트 px로 그린다.
# top이 아니면 몸통 아래 층(폭발 연기·운석 그림자·포효 먼지·꽂힌 화살)만 그린다. 떨어지는 운석·화살과 영혼 사슬도 그린다. 무엇을 어디에 썼는지는 시뮬레이션이 남긴 흔적(traces)이 준다
func _traces(top: bool) -> void:
	for c in battle.traces:
		var h = c.hero
		var id: String = h.get(c.slot).id if c.slot in battle.SLOTS else c.slot
		var at := Vector2i(_center(c.at).floor())
		if _boss(h) and not battle.seen(c.at):  # 숨은 보스(S213)의 흔적은 그리지 않는다
			continue
		var seed := hash(str(c.at) + c.slot)
		match id:
			"fireball", "meteor":
				_boom(at, CELL * c.radius, c.age, seed, id == "meteor", top)
				continue
			"frost_ring":
				if top:
					_frost(at, CELL * c.radius, c.age, seed)
				continue
			"shield_bash":
				if top:
					_bash(at, CELL * c.radius, (c.aim - c.at).angle(), deg_to_rad(h.q.arc) / 2.0, c.age, c.hits)
				continue
			"war_cry":
				_cry(at, CELL * c.radius, c.age, seed, h, top)
				continue
			"brace":
				if top and c.age < FX:
					_spr("aegis", 0 if c.age < 0.05 else (1 if c.age < 0.2 else 2), Vector2i((_spot(h) + _slip(h) - Vector2(0, _head(h) * 0.5)).floor()))
				continue
			"burst":
				if top:
					_burst(at, CELL * c.radius, c.age, seed)
				continue
			"piercing_gale":
				if top:
					_gale(at, (c.aim - c.at).normalized(), c.age, seed, c.hits)
				continue
			"trap":
				_whirl(at, CELL * c.radius, c.age, seed, top)
				continue
		var k: float = c.age / FX
		if not top or k >= 1.0:
			continue
		var col: Color = FX_COLORS[id] if FX_COLORS.has(id) else HERO_COLORS[h.kind]
		if _boss(h):  # 보스 스킬(S198): 고리가 반경의 절반에서 1.1배까지 퍼진다
			_pring(at, int(CELL * c.radius * (0.5 + 0.6 * _out(k))), 2 if k < 0.5 else 1, Color(col.lerp(Color.WHITE, 0.4), 1.0 - k))
			continue
		match id:
			"enfeeble":
				_ring(at, CELL * c.radius, k, col)
			"holy_beam":  # 영웅에서 맞은 차례대로 잇는 줄
				var p0 := _center(h.pos)
				for t in c.hits:
					_pline(Vector2i(p0.floor()), Vector2i(_chest(t).floor()), Color(col, 1.0 - k), 2)
					p0 = _chest(t)
			"overcharge", "rewind", "guardian":  # 영웅에서 대상까지 줄과 대상 둘레 고리
				_pline(Vector2i(_center(h.pos).floor()), Vector2i(_chest(c.aim).floor()), Color(col, 1.0 - k), 2)
				_ring(_spot(c.aim), CELL * 0.8, k, col)
			"miracle":  # 회복받은 아군마다 고리
				for t in c.hits:
					_ring(_spot(t), CELL, k, col)
	for z in battle.zones:  # 떨어지는 운석(이그니스 R): 마지막 FALL초 동안 오른쪽 위에서 내려온다
		var d: float = z.get("delay", 0.0)
		if d > 0.0 and d < FALL:
			_fall(z, d, top)
		if z.src == "sylvia_r":  # 화살비(실비아 R): 떨어지는 화살은 몸통 위, 꽂힌 화살은 몸통 아래 층
			_rain(z, top)
	if not top:
		return
	var links := {}  # 영혼 사슬(S154): 같은 사슬에 묶인 적을 처음 적에게서 사슬 고리 도트로 잇는다. 숨은 적(S213)은 잇지 않는다
	for e in _foes:
		var v = e.fx.get("vesper_e")
		if v:
			if not links.has(v.chain):
				links[v.chain] = []
			links[v.chain].append(e)
	for es in links.values():
		for i in range(1, es.size()):
			var a := _chest(es[0])
			var b := _chest(es[i])
			var n := maxi(int(a.distance_to(b) / 4.0), 1)
			for j in n + 1:
				_spr("link", 0, Vector2i(a.lerp(b, float(j) / n).floor()))

# 퍼지는 고리: k(0~1)에 따라 반경 r까지 처음에 빠르게 퍼지며 옅어진다. 같은 영웅 색 장판 위에서도 보이게 40% 밝힌다. 아트 px다
func _ring(c: Vector2, r: float, k: float, col: Color) -> void:
	if k < 1.0:
		_pring(Vector2i(c.floor()), maxi(int(r * _out(k)), 1), 2 if k < 0.5 else 1, Color(col.lerp(Color.WHITE, 0.4), 1.0 - k))

# 범위 폭발(4.1s, 화염구 작렬·운석 착탄): 폭발 조각 6프레임(흰 섬광 → 날카로운 터짐 → 불 덩어리 → 초승달) + 앞 0.2초 고리(굵기 3 → 0) + 불티 방사선.
# 고리는 하나만 그리고 섬광은 밝게 채운다(Gemini 고칠 점 1). 연기는 몸통 아래 층(top = false)에 그린다(고칠 점 2). 운석은 돌 조각이 튄다
func _boom(c: Vector2i, rad: float, t: float, seed: int, big: bool, top: bool) -> void:
	if not top:
		var k := (t - 0.2) / 0.45
		if k >= 0.0 and k < 1.0:
			for i in 4:
				_spr("puff", int(k * 3.0), c + Vector2i(int((_hf(seed, i) - 0.5) * rad), int((_hf(seed, i + 5) - 0.5) * rad * 0.6) - int(8.0 * k)))
		return
	var fr := int(t / BOOM_STEP)
	if fr < int(FX_ART.boom[4]):
		_spr("boom", fr, c)
	if t < 0.2:
		var k := t / 0.2
		_pring(c, int(rad * (0.25 + 0.85 * _pow3(k))), int(ceil(3.0 * (1.0 - k))), _ramp(["cream", "gold", "orange"], k))
	var n := 12 if big else 8
	for i in n:  # 불티: 바깥으로 눕힌 짧은 선, 길이가 줄고 식는다
		var life := 0.32 + 0.16 * _hf(seed, i)
		if t >= life:
			continue
		var k := t / life
		var dir := Vector2.from_angle(TAU * i / n + _hf(seed, i + 20) * 0.6)
		var p0 := c + Vector2i(dir * rad * (0.2 + _pow3(k)) * (0.7 + 0.4 * _hf(seed, i + 40)))
		_pline(p0, p0 - Vector2i((dir * (4.0 * (1.0 - k) + 1.0)).round()), _ramp(EMBER, k))
	if big and t < 0.55:  # 운석: 튀는 돌 조각(중력)
		for i in 6:
			var dir := Vector2.from_angle(-PI * (0.15 + 0.7 * _hf(seed, i + 60)))
			var v := 70.0 + 50.0 * _hf(seed, i + 61)
			_spr("rock", i, c + Vector2i(Vector2(dir.x * v * t, dir.y * v * t + 160.0 * t * t)))

# 서리 고리(4.1s): 앞 0.25초 고리(굵기 2 → 1, 얼음 램프) + 고리 자리에 솟는 얼음 결정 10개(자람 · 다 자람 · 금 감) + 반짝이
func _frost(c: Vector2i, rad: float, t: float, seed: int) -> void:
	if t < 0.25:
		var k := t / 0.25
		_pring(c, int(rad * (0.2 + 0.9 * _pow3(k))), 2 if k < 0.5 else 1, _ramp(["ice0", "ice1", "ice2"], k))
	for i in 10:
		var k := (t - 0.06 - 0.12 * _hf(seed, i)) / 0.55
		if k >= 0.0 and k < 1.0:
			var p := c + Vector2i(Vector2.from_angle(TAU * i / 10.0 + _hf(seed, i + 30) * 0.5) * rad * (0.8 + 0.2 * _hf(seed, i + 31)))
			_spr("shard", 0 if k < 0.15 else (1 if k < 0.7 else 2), p, true)
	if t < 0.6:
		for i in 6:
			if posmod(int(t * 30.0) + i, 3) == 0:
				draw_rect(Rect2(Vector2(c + Vector2i(Vector2.from_angle(_hf(seed, i + 50) * TAU) * rad * _hf(seed, i + 51))), Vector2.ONE), PX.ice0)

# 떨어지는 운석(4.1s): 몸통 아래 층은 땅 그림자(성긴 칠이 짙어지고 커짐)와 떨어질 자리 점선, 위 층은 꼬리와 운석 조각
func _fall(z: Dictionary, d: float, top: bool) -> void:
	var k := 1.0 - d / FALL
	var g := Vector2i(_center(z.pos).floor())
	if not top:
		_pnoise(g, 2 + int(6.0 * k), PX.soot, 4 + int(8.0 * k))
		_pring(g, int(CELL * z.radius), 1, PX.orange, 2)
		return
	var dir := Vector2(0.5, -1.0).normalized()
	var p := g + Vector2i(Vector2(0.5, -1.0) * 80.0 * d / FALL)
	for i in range(5, 0, -1):  # 꼬리: 뒤로 갈수록 작고 어둡다
		_pdisc(p + Vector2i(dir * i * 4.0), maxi(2 - i / 2, 0), _ramp(["orange", "red", "blood", "smoke", "dark"], i / 5.0))
	_spr("meteor", int(clock * 12.0), p)

# 스킬에 맞은 적마다 작은 섬광(fx-2, 방패 강타·관통의 바람살): spark 3프레임. 숨은 적(S213)에는 그리지 않는다
func _sparks(hits: Array, t: float) -> void:
	var f := int(t / SPARK_STEP)
	if f >= int(FX_ART.spark[4]):
		return
	for e in hits:
		if battle.seen(e.pos):
			_spr("spark", f, Vector2i(_chest(e).floor()))

# 방패 강타(아이아스 Q, fx-2): 부채꼴 끝을 따라 굵은 초승달 베기가 SWEEP초에 반경까지 퍼진다(앞 가장자리 크림, 안쪽으로 보라 램프, 굵기 4 → 1).
# 그 뒤 FX초까지 반경 자리의 가는 호가 어두워지며 남는다. 맞은 적마다 작은 섬광
func _bash(c: Vector2i, rad: float, d: float, half: float, t: float, hits: Array) -> void:
	if t < SWEEP:
		var k := t / SWEEP
		var r := int(rad * (0.3 + 0.7 * _pow3(k)))
		var cols := ["cream", "vio0", "vio1", "vio2"]
		for i in maxi(int(ceil(4.0 * (1.0 - k))), 1):
			_parc(c, r - i, 1, d - half, d + half, PX[cols[i]])
	elif t < FX:
		_parc(c, int(rad), 1, d - half, d + half, _ramp(["vio1", "vio2", "vio3"], (t - SWEEP) / (FX - SWEEP)))
	_sparks(hits, t)

# 전장의 포효(아이아스 W, fx-2): 충격파 고리 둘(둘째는 CRY_ECHO초 늦게, 굵기 3·2 → 0, 보라 램프)과 영웅 머리 위로 뻗는 짧은 외침 선 셋.
# 몸통 아래 층에는 바닥 먼지가 바깥으로 퍼진다
func _cry(c: Vector2i, rad: float, t: float, seed: int, h, top: bool) -> void:
	if not top:
		if t < 0.4:
			var k := t / 0.4
			for i in 10:
				var dir := Vector2.from_angle(TAU * i / 10.0 + _hf(seed, i) * 0.5)
				var p := c + Vector2i((dir * rad * (0.25 + 0.6 * _pow3(k)) * (0.8 + 0.3 * _hf(seed, i + 10))).round())
				_px(p, _ramp(["ash", "smoke", "dark"], k), Vector2i(2, 1))
		return
	for j in 2:
		var tt := t - j * CRY_ECHO
		if tt >= 0.0 and tt < 0.25:
			var k := tt / 0.25
			_pring(c, int(rad * (0.15 + 0.85 * _pow3(k))), int(ceil((3 - j) * (1.0 - k))), _ramp(["vio0", "vio1", "vio2"], k))
	if t < 0.2:
		var head := Vector2i((_spot(h) + _slip(h)).floor()) - Vector2i(0, int(_head(h)) + 2)
		for a in [-PI * 0.75, -PI * 0.5, -PI * 0.25]:
			var dir := Vector2.from_angle(a)
			var p0 := head + Vector2i((dir * (2.0 + 6.0 * t / 0.2)).round())
			_pline(p0, p0 + Vector2i((dir * 3.0).round()), PX.cream if t < 0.1 else PX.gold)

# 반격의 태세 터뜨림(아이아스 E, fx-2): 터짐 조각 5프레임(크림 섬광 → 보라 8각 별 → 튀는 조각) + 앞 0.2초 고리 하나(굵기 3 → 0) + 바깥으로 눕힌 보라 조각선
func _burst(c: Vector2i, rad: float, t: float, seed: int) -> void:
	var fr := int(t / BOOM_STEP)
	if fr < int(FX_ART.burst[4]):
		_spr("burst", fr, c)
	if t < 0.2:
		var k := t / 0.2
		_pring(c, int(rad * (0.3 + 0.8 * _pow3(k))), int(ceil(3.0 * (1.0 - k))), _ramp(["cream", "vio0", "vio1"], k))
	for i in 8:
		var life := 0.28 + 0.12 * _hf(seed, i)
		if t >= life:
			continue
		var k := t / life
		var dir := Vector2.from_angle(TAU * i / 8.0 + 0.2 + _hf(seed, i + 20) * 0.4)
		var p0 := c + Vector2i(dir * rad * (0.3 + 0.8 * _pow3(k)))
		_pline(p0, p0 - Vector2i((dir * (4.0 * (1.0 - k) + 1.0)).round()), _ramp(["vio0", "vio1", "vio2", "vio3"], k))

# 관통의 바람살(실비아 Q, fx-2): GALE_REACH초에 맵 끝까지 뻗는 연두 몸통(굵기 3 → 1, 앞 절반은 밝은 심 1px)과 몸통 옆에서 앞으로 흐르는 바람 줄. 맞은 적마다 작은 섬광
func _gale(c: Vector2i, dir: Vector2, t: float, seed: int, hits: Array) -> void:
	if t < FX:
		var k := t / FX
		var far := CELL * 64.0 * _pow3(t / GALE_REACH)
		var end := c + Vector2i((dir * far).round())
		_pline(c, end, _ramp(["lime1", "lime2", "lime3"], k), 3 if k < 0.3 else (2 if k < 0.6 else 1))
		if k < 0.5:
			_pline(c, end, PX.lime0)
		var side := dir.orthogonal()
		for i in 8:
			var s := (0.1 + 0.8 * _hf(seed, i) + 0.5 * k) * CELL * 8.0
			if s + 6.0 > far:
				continue
			var p0 := c + Vector2i((dir * s + side * (3.0 if i % 2 == 0 else -3.0)).round())
			_pline(p0, p0 + Vector2i((dir * 6.0).round()), PX.lime0 if k < 0.5 else PX.lime2)
	_sparks(hits, t)

# 폭풍의 덫 터짐(실비아 E, fx-2): 앞 0.2초 고리 하나(굵기 2 → 0, 연두 램프) + 돌며 퍼지는 바람 호 셋. 몸통 아래 층에는 흙 부스러기가 튄다
func _whirl(c: Vector2i, rad: float, t: float, seed: int, top: bool) -> void:
	if not top:
		if t < 0.35:
			var k := t / 0.35
			for i in 6:
				var dir := Vector2.from_angle(TAU * i / 6.0 + _hf(seed, i))
				_px(c + Vector2i((dir * rad * (0.2 + 0.5 * _pow3(k))).round()) - Vector2i(0, int(6.0 * k)), _ramp(["ash", "smoke", "dark"], k))
		return
	if t < 0.2:
		var k := t / 0.2
		_pring(c, int(rad * (0.2 + 0.8 * _pow3(k))), int(ceil(2.0 * (1.0 - k))), _ramp(["lime0", "lime1", "lime2"], k))
	if t < 0.35:
		var k := t / 0.35
		for j in 3:
			var a := j * TAU / 3.0 + t * 9.0 + _hf(seed, j)
			_parc(c, int(rad * (0.35 + 0.55 * _pow3(k))), 1, a, a + 1.2, _ramp(["lime0", "lime1", "lime2"], k))

# 화살비(실비아 R, fx-2): 장판 안 RAIN 자리마다 RAIN_CYCLE초마다 화살 하나가 RAIN_FALL초에 떨어지고(위 층) 꽂힌 채 RAIN_STUCK초 남는다(아래 층).
# 자리는 주기마다 해시로 바뀌고, 장판이 펼쳐지고 줄어드는 반지름을 따른다
func _rain(z: Dictionary, top: bool) -> void:
	var age := _zone_age(z)
	var r := zone_r(z, age)
	if r < 4:
		return
	var c := Vector2i(_center(z.pos).floor())
	var seed := hash(str(z.pos) + z.src)
	for i in RAIN:
		var u := age + _hf(seed, i) * RAIN_CYCLE
		var ph := fmod(u, RAIN_CYCLE)
		var n := int(u / RAIN_CYCLE)
		var p := c + Vector2i((Vector2.from_angle(_hf(seed + n, i + 30) * TAU) * sqrt(_hf(seed + n, i + 60)) * (r - 3)).round())
		if ph < RAIN_FALL:
			if top:  # 왼쪽 위에서 비스듬히: 몸통은 크림, 깃은 연두
				var head := p - Vector2i((Vector2(2, 7) * 3.0 * (1.0 - ph / RAIN_FALL)).round())
				_pline(head - Vector2i(2, 7), head, PX.cream)
				_px(head - Vector2i(2, 7), PX.lime1)
		elif ph < RAIN_FALL + RAIN_STUCK and not top:
			_spr("stuck", 0, p + Vector2i(0, 1), true)
			if ph < RAIN_FALL + 0.06:  # 꽂힌 순간 흙먼지
				for sx in [-2, 2]:
					_px(p + Vector2i(sx, 0), PX.ash)

# 장판(I101, S168, 4.1s): 처음 본 때부터 ZONE_OPEN초에 펼쳐지고 마지막 ZONE_CLOSE초에 줄어든다. 판정 경계는 밝은 1px + 바깥 어두운 1px이고,
# 같은 종류 장판끼리 겹친 곳은 빼서 바깥 테두리만 남는다. 이그니스 장판 셋과 실비아 장판 둘은 재질, 나머지는 성긴 칠 + 아트 1px 무늬(S168).
# 떨어지는 중인 운석은 _fall, 화살비의 화살은 _rain, 절대 방어선 둘레는 _capsule이 그린다. 덫은 플레이어에게만 보인다
func _zones() -> void:
	_zone_t0 = _zone_t0.filter(func(e): return battle.zones.any(func(z): return is_same(z, e[0])))
	var caps := false
	for z in battle.zones:
		var col: Color = ZONES.get(z.src, Color.WHITE)
		if z.has("cells"):
			_capsule(z)
			caps = true
			continue
		if z.get("delay", 0.0) > 0.0:
			continue
		var age := _zone_age(z)
		var r := zone_r(z, age)
		if r < 2:
			continue
		var c := Vector2i(_center(z.pos).floor())
		var seed := hash(str(z.pos) + z.src)
		var others := []
		for o in battle.zones:
			if not is_same(o, z) and o.src == z.src and o.get("delay", 0.0) <= 0.0 and not o.has("cells"):
				others.append([_center(o.pos), CELL * o.radius])
		match z.src:
			"ignis_q":
				_fire_zone(c, r, seed, others)
			"ignis_e":
				_hole_zone(c, r, age, seed, others)
			"ignis_r":
				_lava_zone(c, r, z.left, seed, others)
			"sylvia_e":  # 덫: 엷은 연두 칠 + 가운데 덫 조각(1.2초마다 반짝)
				_pnoise(c, r - 1, PX.lime3, 2, posmod(seed, 4))
				_spr("trap", 1 if fmod(clock + _hf(seed, 1) * 1.2, 1.2) < 0.15 else 0, c)
				_edge(c, r, PX.lime1, PX.soot, others)
			"sylvia_r":  # 화살비: 연두 칠. 떨어지고 꽂히는 화살은 _rain이 그린다
				_pnoise(c, r - 1, PX.lime3, 3, posmod(seed, 4))
				_edge(c, r, PX.lime1, PX.soot, others)
			_:
				_pnoise(c, r, Color(col, 0.6), 3, posmod(seed, 4))
				_pattern(z.src, Vector2(c), r, Color(col, 0.9))
				_edge(c, r, Color(col, 0.9), PX.soot, others)
	if not caps:
		_caps.clear()

# 그릴 장판 반지름(아트 px): 처음 본 뒤 age초 동안 ZONE_OPEN초에 걸쳐 빠르게 펼쳐지고, 남은 시간이 ZONE_CLOSE초 밑이면 줄어든다
static func zone_r(z, age: float) -> int:
	return int(CELL * z.radius * _pow3(age / ZONE_OPEN) * clampf(z.left / ZONE_CLOSE, 0.0, 1.0))

func _zone_age(z) -> float:
	for e in _zone_t0:
		if is_same(e[0], z):
			return clock - e[1]
	_zone_t0.append([z, clock])
	return 0.0

# 불길(이그니스 Q): 그을린 땅(성긴 칠) + 일렁이는 불꽃 조각 + 떠오르는 불티
func _fire_zone(c: Vector2i, r: int, seed: int, others: Array) -> void:
	_pnoise(c, r - 1, PX.dark, 4, posmod(seed, 4))
	for i in FLAMES:
		_spr("flame", int(clock * 10.0) + i * 3, c + Vector2i(Vector2.from_angle(_hf(seed, i) * TAU) * sqrt(_hf(seed, i + 50)) * (r - 4)), true)
	for i in 5:
		var ph := fmod(clock + _hf(seed, i + 90) * 0.7, 0.7) / 0.7
		var p := c + Vector2i(Vector2.from_angle(_hf(seed, i + 70) * TAU) * _hf(seed, i + 80) * (r - 3)) + Vector2i(0, -int(12.0 * ph))
		draw_rect(Rect2(Vector2(p), Vector2.ONE), _ramp(EMBER, ph))
	_edge(c, r, PX.orange, PX.soot, others)

# 블랙홀(이그니스 E): 보라 성긴 칠 세 겹(바깥이 성기고 심은 꽉 참) + 안으로 말려 드는 조각(다섯은 돌) + 가운데 소용돌이 눈
func _hole_zone(c: Vector2i, r: int, age: float, seed: int, others: Array) -> void:
	_pnoise(c, r, PX.vio4, 4, posmod(seed, 4))
	_pnoise(c, int(r * 0.62), PX.vio3, 8, posmod(seed + 1, 4))
	_pdisc(c, int(r * 0.3), PX.night)
	for i in 20:
		var ph := fmod(age * 0.8 + _hf(seed, i), 1.0)
		var p := c + Vector2i(Vector2.from_angle(_hf(seed, i + 30) * TAU + ph * 3.2 + age * 0.6) * r * (1.0 - _pow3(ph)))
		if i % 4 == 0:
			_spr("rock", i, p)
		else:
			draw_rect(Rect2(Vector2(p), Vector2.ONE), PX.vio0 if ph > 0.7 else PX.vio1)
	_spr("eye", int(clock * 10.0), c)
	_edge(c, r, PX.vio2, PX.night, others)

# 용암(이그니스 R): 굳은 껍질과 가지 친 균열 자국 + 솟았다 터지는 거품. 마지막 0.8초는 식어 어두워진다
func _lava_zone(c: Vector2i, r: int, left: float, seed: int, others: Array) -> void:
	if left < 0.8:
		_pnoise(c, r - 2, PX.soot, int(4.0 + 6.0 * left / 0.8), posmod(seed, 4))
	else:
		_spr("lava", seed, c)
		for i in 3:
			var ph := fmod(clock + _hf(seed, i + 40) * 0.6, 0.6) / 0.6
			_spr("pop", int(ph * 3.0), c + Vector2i(Vector2.from_angle(_hf(seed, i + 41) * TAU) * _hf(seed, i + 42) * r * 0.6))
	_edge(c, r, PX.red if left >= 0.8 else PX.blood, PX.soot, others)

# 걸린 효과(I101 2026-10-27 변경): 효과마다 수단 하나로, 고리를 겹쳐 쌓지 않는다.
# 1차(기절·도발·봉인·속박·불사)는 머리 위 기호나 발밑 고리, 2차(둔화·받는 피해 증가·초당 피해·받는 피해 감소·공격 속도·보호막)는 몸·발의 작은 조각이다.
# 사슬은 적끼리 잇는 고리 도트(_traces)가 보인다. 돌려주는 것: {k 조각 이름 또는 "px"·"ring", p 아트 px 자리, f 프레임, c 색, r 반지름}
func status_marks(x, ally: bool) -> Array:
	var feet := Vector2i((_spot(x) + _slip(x)).floor())
	var tall := _head(x)
	var head := feet - Vector2i(0, int(tall))
	var n: int = x.get_instance_id()
	var out := []
	var icons := []
	for key in ALLY_FX if ally else FOE_FX:
		var on: bool
		if ally:
			on = (not x.shields.is_empty()) if key == "shield" else (battle.effect(x, key) != null if key in ["invuln", "stun"] else battle.effect_sum(x, key) > 0.0)
		else:
			on = battle.effect(x, key) != null
		if not on:
			continue
		match key:
			"stun":  # 머리 위를 도는 별 둘
				for i in 2:
					var a := clock * 5.0 + i * PI + _hf(n, 1) * TAU
					out.append({k = "star", p = head + Vector2i(int(cos(a) * 5.0), -3 + int(sin(a) * 2.0)), f = int(clock * 8.0) + i})
			"taunt", "seal":
				icons.append(key)
			"root":  # 발밑 밧줄 고리와 말뚝
				out.append({k = "bind", p = feet + Vector2i(0, 2), f = 0})
			"slow":  # 발밑 서리 껍질(Gemini 고칠 점 3: 발밑 타원 안)
				out.append({k = "frost", p = feet + Vector2i(0, 2), f = 0})
			"expose":  # 몸 옆 금 간 방패, 1초에 0.7초 보임
				if fmod(clock + _hf(n, 2), 1.0) < 0.7:
					out.append({k = "expose", p = feet + Vector2i(7, -int(tall * 0.55)), f = 0})
			"dot":  # 발화(이그니스)는 작은 불꽃과 불티, 그 밖(독)은 떨어지는 방울
				var burn: bool = x.fx.has("ignis_q")
				if burn:
					out.append({k = "flame_s", p = feet + Vector2i(posmod(n, 5) - 2, -4), f = int(clock * 10.0) + n})
				for i in 4:
					var ph := fmod(clock + _hf(n, i + 3) * 0.5, 0.5) / 0.5
					var dx := int(_hf(n, i + 9) * 10.0) - 5
					if burn:
						out.append({k = "px", p = feet + Vector2i(dx, -4 - int(14.0 * ph)), c = _ramp(EMBER, ph)})
					else:
						out.append({k = "px", p = feet + Vector2i(dx, -int(tall * 0.6) + int(8.0 * ph)), c = PX.teal if ph < 0.6 else PX.deepteal})
			"dr":  # 몸 양옆 작은 방패가 오르내린다
				var bob := int(round(sin(clock * 3.0 + _hf(n, 4) * TAU)))
				for sx in [-7, 7]:
					out.append({k = "guard", p = feet + Vector2i(sx, -int(tall * 0.5) + bob), f = 0})
			"haste":  # 발에서 오르는 작은 사각형
				for i in 3:
					var ph := fmod(clock * 1.5 + i / 3.0 + _hf(n, 5), 1.0)
					out.append({k = "px", p = feet + Vector2i(-4 + i * 4, -int(10.0 * ph)), c = PX.gold if ph < 0.5 else PX.orange})
			"shield":  # 몸 둘레 테 하나
				out.append({k = "ring", p = feet - Vector2i(0, int(tall * 0.45)), r = int(tall * 0.6), c = PX.ice0})
			"bleed":  # 출혈(I193 ③): 몸에서 떨어지는 핏방울
				for i in 3:
					var ph := fmod(clock + _hf(n, i + 7) * 0.6, 0.6) / 0.6
					out.append({k = "px", p = feet + Vector2i(int(_hf(n, i + 11) * 8.0) - 4, -int(tall * 0.5) + int(8.0 * ph)), c = PX.blood if ph < 0.6 else PX.maroon})
			"invuln":  # 금 테가 맥동하고 별 하나가 돈다
				var a := clock * 3.0 + _hf(n, 6) * TAU
				out.append({k = "ring", p = feet - Vector2i(0, int(tall * 0.45)), r = int(tall * 0.6) + 1, c = PX.gold if fmod(clock * 2.0, 1.0) < 0.5 else PX.cream})
				out.append({k = "star", p = feet + Vector2i(int(cos(a) * tall * 0.6), -int(tall * 0.45) + int(sin(a) * tall * 0.3)), f = 0})
	if ally and x.get("toggle"):  # 켜진 돌풍 갈래살(실비아 W, fx-2): 발 둘레를 도는 연두 바람 줄
		out.append({k = "gust", p = feet + Vector2i(0, 1), f = int(clock * 12.0)})
	for i in icons.size():  # 머리 위 기호는 별(기절) 위로 한 줄에
		out.append({k = icons[i], p = head + Vector2i(int((i - (icons.size() - 1) / 2.0) * 8.0), -9), f = 0})
	return out

func _status(x, ally: bool) -> void:
	for m in status_marks(x, ally):
		match m.k:
			"px":
				draw_rect(Rect2(Vector2(m.p), Vector2.ONE), m.c)
			"ring":
				_pring(m.p, m.r, 1, m.c)
			_:
				_spr(m.k, m.f, m.p, m.k in ["frost", "bind", "flame_s"])

# 몸의 높이(px): 발밑에서 머리까지. 그림이 있으면 시트의 발밑 기준점, 없으면 반지름으로
func _head(x) -> float:
	var a = ART.get(x.kind)
	return float(a.anchor[1]) if a else CELL * x.radius * 2.0 + 6.0

# ── 아트 px 그리기(4.1s): 맵을 창 해상도로 그려도(S30) 원·선이 도트 그림과 같은 격자에 찍힌다 ──

static func _hf(n: int, k: int) -> float:
	return _h(n, k, 0, 9999) / 9999.0

static func _pow3(k: float) -> float:
	return 1.0 - pow(1.0 - clampf(k, 0.0, 1.0), 3.0)

static func _ramp(names: Array, k: float) -> Color:
	return PX[names[clampi(int(k * names.size()), 0, names.size() - 1)]]

# 가운데가 칸 모서리 c인 아트 px 칸: 고리(반지름 r, 안쪽으로 굵기 th)나 원판(th = 0)
static func px_cells(r: int, th: int) -> Array:
	var key := Vector3i(r, th, 0)
	if not _cells.has(key):
		var out := []
		for y in range(-r - 1, r + 1):
			for x in range(-r - 1, r + 1):
				var d := Vector2(x + 0.5, y + 0.5).length()
				if d <= r + 0.5 and (th == 0 or d > r + 0.5 - th):
					out.append(Vector2i(x, y))
		_cells[key] = out
		var runs := []
		for o in out:  # 칸이 y·x 차례라 줄마다 이어 붙인다
			if not runs.is_empty() and runs[-1].position.y == o.y and runs[-1].end.x == o.x:
				runs[-1].size.x += 1
			else:
				runs.append(Rect2i(o, Vector2i.ONE))
		_runs[key] = runs
	return _cells[key]

func _pring(c: Vector2i, r: int, th: int, col: Color, dash := 0) -> void:
	if r < 1 or th < 1:
		return
	if dash == 0:
		px_cells(r, th)
		for run in _runs[Vector3i(r, th, 0)]:
			draw_rect(Rect2(Vector2(c + run.position), Vector2(run.size)), col)
		return
	for o in px_cells(r, th):  # 둘레를 dash px 길이로 끊어 하나 걸러
		if int(floor((atan2(o.y + 0.5, o.x + 0.5) + PI) * r / dash)) % 2 == 0:
			draw_rect(Rect2(Vector2(c + o), Vector2.ONE), col)

# 고리에서 각 a0~a1(라디안) 사이 칸만
func _parc(c: Vector2i, r: int, th: int, a0: float, a1: float, col: Color) -> void:
	if r < 1:
		return
	var mid := (a0 + a1) / 2.0
	var half := (a1 - a0) / 2.0
	for o in px_cells(r, th):
		if absf(angle_difference(mid, atan2(o.y + 0.5, o.x + 0.5))) <= half:
			draw_rect(Rect2(Vector2(c + o), Vector2.ONE), col)

func _pdisc(c: Vector2i, r: int, col: Color) -> void:
	if r < 0:
		return
	px_cells(r, 0)
	for run in _runs[Vector3i(r, 0, 0)]:
		draw_rect(Rect2(Vector2(c + run.position), Vector2(run.size)), col)

# 성긴 칠: 반투명 원판 대신 원 안 칸의 lim/16만 칠한다. 칸마다 그리지 않게 반지름·밀도·변형별 흰 마스크를 구워 색을 곱한다
func _pnoise(c: Vector2i, r: int, col: Color, lim: int, salt := 0) -> void:
	if r < 1:
		return
	var key := Vector3i(r, lim, salt)
	if not _noise.has(key):
		var img := Image.create(2 * r + 2, 2 * r + 2, false, Image.FORMAT_RGBA8)
		for o in px_cells(r, 0):
			if posmod(hash(Vector3i(o.x, o.y, salt)), 16) < lim:
				img.set_pixel(o.x + r + 1, o.y + r + 1, Color.WHITE)
		_noise[key] = ImageTexture.create_from_image(img)
	draw_texture(_noise[key], Vector2(c - Vector2i(r + 1, r + 1)), col)

# 아트 px 선(브레젠험). w > 1이면 w×w 칸으로 찍는다
func _pline(a: Vector2i, b: Vector2i, col: Color, w := 1) -> void:
	var d := (b - a).abs()
	var s := Vector2i(signi(b.x - a.x), signi(b.y - a.y))
	var err := d.x - d.y
	var p := a
	var o := Vector2i(w / 2, w / 2)
	for i in d.x + d.y + 1:
		draw_rect(Rect2(Vector2(p - o), Vector2(w, w)), col)
		if p == b:
			return
		var e2 := 2 * err
		if e2 > -d.y:
			err -= d.y
			p.x += s.x
		if e2 < d.x:
			err += d.x
			p.y += s.y

# 판정 경계(4.1s 1차 요소): 고리 r(밝은 색)과 그 바깥 r + 1(어두운 색). others([가운데 맵 px, 반지름 px])와 겹친 칸은 뺀다
static func edge_cells(c: Vector2i, r: int, others: Array) -> Array:
	var out := []
	for rr in [r + 1, r]:
		var cells := []
		for o in px_cells(rr, 1):
			var q := Vector2(c + o) + Vector2(0.5, 0.5)
			if not others.any(func(z): return q.distance_to(z[0]) < z[1] - 0.5):
				cells.append(c + o)
		out.append(cells)
	return out

func _edge(c: Vector2i, r: int, light: Color, dark: Color, others := []) -> void:
	var cells := edge_cells(c, r, others)
	for i in 2:
		for p in cells[i]:
			draw_rect(Rect2(Vector2(p), Vector2.ONE), dark if i == 0 else light)

# 이펙트 조각 한 프레임(art/fx/fx.png). bottom이면 at이 아래 가운데, 아니면 가운데
func _spr(name: String, frame: int, at: Vector2i, bottom := false) -> void:
	var m: Array = FX_ART[name]
	var w := int(m[2])
	var h := int(m[3])
	var pos := at - (Vector2i(w / 2, h) if bottom else Vector2i(w / 2, h / 2))
	draw_texture_rect_region(FX_TEX, Rect2(Vector2(pos), Vector2(w, h)), Rect2(m[0] + posmod(frame, int(m[4])) * w, m[1], w, h))

# 아트 px 칸 하나(또는 size 칸) 칠하기(fx-2). 시험의 기록 화면이 가로챈다
func _px(p: Vector2i, col: Color, size := Vector2i.ONE) -> void:
	draw_rect(Rect2(Vector2(p), Vector2(size)), col)

func _out(k: float) -> float:
	return 1.0 - (1.0 - k) * (1.0 - k)

# 아이아스 R 둘레(S179, I142, fx-2): 에너지 성벽 칸 가운데마다 반경 radius 원을 합친 모양(칸 줄을 감싼 캡슐)이다.
# 다른 장판처럼 펼쳐지고 줄어들며(zone_r), 얼음색 성긴 칠 + 밝은 1px + 바깥 어두운 1px 테두리다. 안에서 얼음색 점이 천천히 떠오른다.
# 모양은 칸 배치·반지름마다 한 번 굽는다(capsule_cells). 둘레가 없으면 _zones가 버린다
func _capsule(z) -> void:
	var r := zone_r(z, _zone_age(z))
	if r < 2:
		return
	var c := Vector2i(_center(Vector2(z.cells[0])).floor())
	var offs: Array = z.cells.map(func(q): return (q - z.cells[0]) * CELL)
	var key := str(offs) + str(r)
	if not _caps.has(key):
		_caps[key] = capsule_cells(offs, r)
	var m: Array = _caps[key]
	draw_texture(m[0], Vector2(c + m[1]), PX.ice3)
	for i in 2:
		for p in m[2 + i]:
			_px(c + p, PX.ice0 if i == 0 else PX.navy)
	var seed := hash(str(z.pos) + z.src)
	for i in 6:
		var ph := fmod(clock * 0.6 + _hf(seed, i), 1.0)
		var o: Vector2i = offs[i % offs.size()]
		var p := c + o + Vector2i((Vector2.from_angle(_hf(seed, i + 10) * TAU) * _hf(seed, i + 20) * r * 0.7).round()) - Vector2i(0, int(8.0 * ph))
		_px(p, PX.ice0 if ph < 0.5 else PX.ice1)

# 칸 가운데 offs(첫 칸 가운데에서 본 맵 px)마다 반지름 r 원을 합친 모양의 아트 px.
# 돌려주는 것: [안쪽 성긴 칠(2/16) 흰 마스크 텍스처, 그 왼쪽 위, 밝은 테두리 칸(반경 r), 어두운 테두리 칸(그 바깥 한 칸)]. 칸 판정은 px_cells와 같다(가운데가 칸 모서리)
static func capsule_cells(offs: Array, r: int) -> Array:
	var lo := Vector2i(offs[0])
	var hi := Vector2i(offs[0])
	for o in offs:
		lo = lo.min(o)
		hi = hi.max(o)
	lo -= Vector2i(r + 2, r + 2)
	hi += Vector2i(r + 2, r + 2)
	var img := Image.create(hi.x - lo.x, hi.y - lo.y, false, Image.FORMAT_RGBA8)
	var light := []
	var dark := []
	for y in range(lo.y, hi.y):
		for x in range(lo.x, hi.x):
			var q := Vector2(x + 0.5, y + 0.5)
			var d := INF
			for o in offs:
				d = minf(d, q.distance_to(Vector2(o)))
			if d <= r - 0.5:
				if posmod(hash(Vector2i(x, y)), 16) < 2:
					img.set_pixel(x - lo.x, y - lo.y, Color.WHITE)
			elif d <= r + 0.5:
				light.append(Vector2i(x, y))
			elif d <= r + 1.5:
				dark.append(Vector2i(x, y))
	return [ImageTexture.create_from_image(img), lo, light, dark]

# 에너지 성벽 칸(아이아스 R, S151·I101, fx-2): 칸 위에 선 얼음색 벽 조각(칸 윗면 + 앞면 6px, 성기게 칠해 비침). 이웃 칸과 한 벽으로 이어진다(ward_edges).
# 처음 WALL_RISE초는 아래에서부터 드러나고, 옅은 줄이 아래에서 위로 지나가며, 남은 시간이 ZONE_CLOSE초 밑이면 금 간 그림이다.
# 장판 다음, 몸통 아래 층이라 유닛을 가리지 않는다
func _wards() -> void:
	var of := {}
	for z in battle.zones:
		if z.has("cells"):
			for q in z.cells:
				of[q] = z
	var cells: Array = battle.barriers.keys()
	cells.sort_custom(func(p, q): return p.y < q.y)
	var m: Array = FX_ART.ward
	var w := int(m[2])
	var tall := float(m[3])
	for q in cells:
		var z = of.get(q)
		var f := 3 if z and z.left < ZONE_CLOSE else posmod(int(clock * 6.0) - q.y, 3)  # 줄은 남쪽 칸부터 북쪽 칸으로 이어 오른다
		var top := Vector2(q) * CELL - Vector2(0, tall - CELL)  # 그림 왼쪽 위(앞면 아래끝이 칸 아래끝)
		var shown := top.y + tall * (1.0 - (clampf(_zone_age(z) / WALL_RISE, 0.0, 1.0) if z else 1.0))  # 드러난 윗끝
		var e := ward_edges(battle.barriers, q)
		var end := top.y + (tall if e[0] else float(CELL))
		if shown < end:
			draw_texture_rect_region(FX_TEX, Rect2(top.x, shown, w, end - shown), Rect2(m[0] + f * w, m[1] + shown - top.y, w, end - shown))
		for i in 2:  # 윗면 뒤끝(그림 0줄)·앞끝(15줄)의 밝은 선
			if e[1 + i] and top.y + i * (CELL - 1) >= shown:
				_px(Vector2i(top) + Vector2i(0, i * (CELL - 1)), PX.ice0, Vector2i(w, 1))

# 에너지 성벽 칸 q를 어떻게 그리나(fx-2): [앞면, 윗면 뒤끝 밝은 선, 윗면 앞끝 밝은 선]. 북쪽·남쪽에 벽 칸이 있으면 그쪽 끝은 이어지므로 긋지 않고,
# 남쪽 벽 칸의 윗면이 덮을 자리라 앞면도 그리지 않는다. 동서로는 그림에 옆 테두리가 없어 그대로 이어진다
static func ward_edges(walls: Dictionary, q: Vector2i) -> Array:
	var south := walls.has(q + Vector2i(0, 1))
	return [not south, not walls.has(q - Vector2i(0, 1)), not south]

# 칸에 붙는 표시: 놓기 모드 칸, 효과 테두리, 고른 것 테두리, 집결 지점, 체력 막대. 성벽 그림에 가리지 않게 몸통 뒤에 그린다(4.1c)
func _marks() -> void:
	if controls.placing in battle.STRUCTURE_KINDS:  # 구조물 놓기: 커서 칸에 차지 칸 미리보기(S216, I138 2026-10-26 변경)
		var g := ghost(battle, controls.placing, Vector2i((controls.mouse / CELL).floor()))  # 클릭이 짓는 칸과 같은 좌표
		var area := Rect2(Vector2(g[0].position * CELL), Vector2(g[0].size * CELL))
		draw_rect(area, Color(GHOST_OK if g[1] else GHOST_NO, 0.25))
		draw_rect(area, GHOST_OK if g[1] else GHOST_NO, false, 1.0)
	elif controls.placing != "":  # 용병 놓기: 지금 놓을 수 있는 칸을 엷게(S45, I138)
		for c in battle.placeable_cells(controls.placing):
			draw_rect(_rect(c), Color(1, 1, 1, 0.25))
	for s in battle.structures.values() + battle.castle.values():  # 받는 피해 감소·공격 속도가 걸린 칸(I101)
		var ring := 1
		for key in ["dr", "haste"]:
			if battle.effect_sum(s, key) > 0.0:
				draw_rect(_box(s).grow(-ring), MARKS[key], false, 1.0)
				ring += 2
	for s in controls.picked + ([controls.fort] if controls.fort else []) + ([battle.base] if controls.village else []):  # 전투 단계에 고른 구조물(S74, S83)·고른 성곽 칸(S85)·고른 거점(S100)
		draw_rect(_box(s), Color.WHITE, false, 1.0)
	var f = controls.facility  # 고른 생산 시설: 테두리와 집결 지점 깃발(S82)
	if f and f.alive:
		draw_rect(_box(f), Color.WHITE, false, 1.0)
		draw_line(_center(battle.middle(f)), _center(Vector2(f.rally)), Color(1, 1, 1, 0.4), 1.0)
		draw_rect(_rect(f.rally).grow(-5), Color.WHITE)
	_hp_bar(Vector2(battle.base.cell) - Vector2(0, 1.75), battle.base, Vector2(CELL, 2), true)  # 망루 흉벽 위(칸 위 1.75칸). 칸 위에 그리면 앞면 휘장을 가로질렀다
	# 구조물·성곽은 깎였을 때만 체력 막대를 그린다(성곽 칸이 많아서). V로 켜면 구조물은 늘 그린다(S73, I59). 막대 색은 3단(S199)
	for b in battle.castle.values() + battle.structures.values():
		if b.hp < b.max_hp or (controls.show_hp and b.kind in battle.STRUCTURE_KINDS):
			var top: float = FAC_FOOT.y - CELL - FAC[b.kind][1] if FAC.has(b.kind) else 0.0  # 시설은 그림 위에(4.1e). 칸 위에 그리면 그림을 가로질렀다
			if battle.castle.get(b.cell) == b:
				top += rise_at(battle, b.cell)  # 문루·탑은 앞면이 높아진 만큼 위에(S170). 성벽과 같은 자리(흉벽 바로 아래)다
			_hp_bar(Vector2(battle.middle(b).x, b.cell.y) - Vector2(0, (_lift(b) + top) / CELL), b, Vector2(CELL, 2), true)  # 차지 칸 가운데 위(S173)

# 유닛·적·주민 몸통(S165, S172)과 성곽·거점(4.1c)·시설(4.1e). 잔해는 _draw가 바닥 층으로 먼저 깐다(S170). 땅의 쓰러진 몸(S180), 발밑 팀 색(S166)과 비행 적 그림자(I81)를 먼저 깔고, (층, 바닥선 y, 목록 순서)로 정렬해 그린다.
# 성곽 칸은 몸체(바닥선)와 앞층(바닥선 + 2) 두 조각이고, 성벽 위 유닛·대포와 기어오르는 적은 그 사이(바닥선 + 1)에 올려 그려 앞층이 발을 가린다(05 §2).
# 성벽 위 유닛의 발밑 팀 색만은 앞층 다음(바닥선 + 3)에 올려 그려 흉벽에 가리지 않게 한다(사용자 2026-10-20).
# 성벽·거점 그림에 가려진 땅 유닛과 시설은 끝에 한 번 더 그린다(_shade). 레벨·선택·효과 테두리는 _draw가 모든 몸통 뒤에 그린다
func _bodies() -> void:
	var all: Array = battle.units + _foes  # 숨은 적(S213)은 몸·발밑을 그리지 않는다
	var walls: Array = battle.castle.values()
	var blds: Array = battle.structures.values()
	for s in battle.structures.values():  # 옮겨 갈 칸의 대포 청사진(S176): 진행률 0인 미완성 대포로 그린다
		if s.dest != null:
			blds.append({"kind": s.kind, "cell": s.dest, "dest": null, "razed": 0.0, "complete": false, "progress": 0.0})
	_hits = hit_table(all + blds)
	var now := Time.get_ticks_msec() / 1000.0
	var day: Array = battle.people  # 주민(S223): 판이 스텝마다 구한 자리. 걷는 쪽은 지난 스텝 자리(was)와의 차다
	_folk_now = [day, day.map(func(v): return v.f)]
	var pl := _prop_list()
	var n := all.size()
	var m := n + 2 * walls.size()  # 이 번호부터 시설, 그다음 거점
	var feet := m + blds.size() + 1  # 이 번호부터 성벽 위 유닛의 발밑 표시
	var folk := feet + n  # 이 번호부터 주민
	var grave := folk + day.size()  # 이 번호부터 성벽 위의 쓰러진 몸
	var keys := PackedInt64Array()
	var dead := _fallen()
	for k in dead.size():
		var x = dead[k][0]
		if _last_blow(x)[0]:  # 막타를 기다리거나 번쩍이는 선 몸은 산 몸과 같은 차례(S197)
			keys.append((1 << 44) | ((int(_wall_line(Vector2i(x.pos.round())) if x.on_wall else _center(x.pos).y) + 64) << 20) | (grave + k))
		elif x.on_wall:  # 성벽 위의 쓰러진 몸은 낮아서 흉벽에 다 가리므로, 성벽 위 발밑 표시처럼 앞층 다음(바닥선 + 3)에
			keys.append((1 << 44) | ((_wall_line(Vector2i(x.pos.round())) + 5 + 64) << 20) | (grave + k))
		else:
			_corpse(dead[k])
	for i in n:
		var x = all[i]
		var fly: bool = x.get("flying") == true
		if not x.on_wall:
			_feet_mark(x, i)
		else:
			keys.append((1 << 44) | ((_wall_line(Vector2i(x.pos.round())) + 5 + 64) << 20) | (feet + i))
		if fly:
			draw_circle(_center(x.pos) + Vector2(0, CELL * 0.4), CELL * x.radius * 0.8, Color(0, 0, 0, 0.35))
		var y: float = _wall_line(Vector2i(x.pos.round())) if x.on_wall else ((roundf(x.pos.y) + 1) * CELL + 1 if x.get("climbed") else _center(x.pos).y)
		keys.append(((2 if fly else 1) << 44) | ((int(y) + 64) << 20) | i)
	for j in walls.size():
		var line: int = (walls[j].cell.y + 1) * CELL
		keys.append((1 << 44) | ((line - 3 + 64) << 20) | (n + 2 * j))
		keys.append((1 << 44) | ((line + 2 + 64) << 20) | (n + 2 * j + 1))
	for j in blds.size():  # 시설은 바닥선, 성벽 위 대포는 성곽 몸체와 앞층 사이(바닥선 + 1)
		var on: bool = battle.walls.has(blds[j].cell)
		keys.append((1 << 44) | (((_wall_line(blds[j].cell) if on else (blds[j].cell.y + 1) * CELL) + 64) << 20) | (m + j))
	keys.append((1 << 44) | (((battle.base.cell.y + 1) * CELL + 64) << 20) | (m + blds.size()))
	for k in day.size():
		if not day[k].inside:  # 집 안이면 그리지 않는다(S223)
			keys.append((1 << 44) | ((int(_center(day[k].pos).y) + 64) << 20) | (folk + k))
	var prop0 := grave + dead.size()  # 이 번호부터 일터 소품(S224)
	for k in pl.size():
		keys.append((1 << 44) | ((pl[k][2] + 64) << 20) | (prop0 + k))
	keys.sort()
	var next := {}
	for k in keys:
		var i: int = k & 0xFFFFF
		if i >= prop0:
			_prop(pl[i - prop0], now)
		elif i >= grave:
			_corpse(dead[i - grave])
		elif i >= folk:
			_folk_body(day[i - folk], now)
		elif i >= feet:
			_feet_mark(all[i - feet], i - feet)
		elif i == m + blds.size():  # 거점 망루: 마을 레벨(S99)마다 한 장. 맞으면 흔들리고 깎이면 금(S199)
			var at := Vector2(battle.base.cell * CELL) + KEEP_AT + _jolt(battle.base)
			draw_texture_rect_region(KEEP_K, Rect2(at, Vector2(80, 80)), Rect2(80 * (clampi(battle.village_level, 1, 2) - 1), crack_y(battle.base, KEEP.get_height()), 80, 80))
		elif i >= m:
			_facility(blds[i - m])
		elif i >= n:
			_wall_piece(walls[(i - n) / 2], (i - n) % 2)
		else:
			_body(all[i], i, next)
	for i in n:
		var t := _shade(all[i])
		if t.a > 0.0:
			_body(all[i], i, next, t)
	for s in blds:  # 시설도 같은 규칙으로 덧그린다(사용자 2026-10-20)
		var t := _shade(s)
		if t.a > 0.0:
			_facility(s, t)
	_clip = -INF
	for h in battle.heroes:  # 보스 그림에 가린 영웅(S198): S171처럼 40%로 덧그리되, 보스가 맞은 것처럼 보이지 않게 번쩍임은 곱하지 않는다
		if h.alive and _under_boss(h):
			_body(h, battle.units.find(h), next, GHOST, false)
	_seen = next

# 가려진 몸통을 덧그릴 색. 성곽 그림이 발(칸 가운데)을 4px 넘게 덮는 줄은 그림 윗변(_clip)보다 아래만 어두운 실루엣이고(S175),
# 그보다 적게(발만) 덮는 줄은 덧그리지 않는다(투명). 성벽은 바로 뒤 한 줄, 문루·문 양옆 탑은 뒤 세 줄이 실루엣이다. 거점 뒤는 통째로 40%다(S171)
func _shade(x) -> Color:
	_clip = -INF
	if not _behind(x):
		return Color.TRANSPARENT
	var c := Vector2i(_pos_of(x).round())
	var cover := _cover(c)
	if cover > CELL / 4.0:
		_clip = (c.y + 0.5) * CELL - cover  # 그 열 성곽 그림 윗변
		return SHADE
	return Color.TRANSPARENT if cover > 0 else GHOST

# 땅 칸 c 앞(아래) 세 줄 안의 첫 성곽 칸 그림이 c의 발(칸 가운데)보다 위로 덮는 px. 앞에 성곽이 없으면 -INF
func _cover(c: Vector2i) -> float:
	for k in range(1, 4):
		if battle.walls.has(c + Vector2i(0, k)):
			var r := rise_at(battle, c + Vector2i(0, k))
			return WALL_TOP_UP + (r + RING if r > 0 else 0) - CELL / 2.0 - CELL * (k - 1)
	return -INF

# 성곽 칸 c에 선 유닛·대포를 성벽 통로보다 더 올리는 px(S170): 문루는 GATE_RISE, 문 양옆 탑 열은 TOWER_RISE, 그 밖은 0
static func rise_at(bt, c: Vector2i) -> int:
	var k = bt.walls.get(c)
	if k == null:
		return 0
	if k.kind == "gate":
		return SIDE_GATE_RISE if k.size == Vector2i(3, 3) and (k.cell.x == 0 or k.cell.x + 3 == bt.size.x) else GATE_RISE
	if k.size == Vector2i(1, 3) and (k.cell.x < 3 or k.cell.x >= bt.size.x - 3):  # 모서리 탑(S219)
		return CORNER_RISE
	return TOWER_RISE if tower_of(bt, k) != "" else 0

# 성벽 열 k가 성문 바로 옆이면 그 탑 조각 이름(문 왼쪽 «tower_l», 오른쪽 «tower_r»), 아니면 «». 성문이 잔해여도 탑이다
static func tower_of(bt, k) -> String:
	for d in [1, -1]:
		var g = bt.walls.get(k.cell + Vector2i(d, 0))
		if g == null:
			g = bt.debris.get(k.cell + Vector2i(d, 0))
		if g != null and g.kind == "gate":
			return "tower_l" if d == 1 else "tower_r"
	return ""

# 맵 px p가 문루·문 양옆 탑 그림 가운데 성곽 뒤 땅 칸 쪽으로 솟은 부분이면 그 성곽 Block, 아니면 null(S218). 보통 성벽 열은 null이다
static func raised_at(bt, p: Vector2):
	var c := Vector2i((p / CELL).floor())
	for k in range(1, 4):
		var w = bt.walls.get(c + Vector2i(0, k))
		if w != null:
			var r := rise_at(bt, c + Vector2i(0, k))
			return w if r > 0 and p.y >= (c.y + k) * CELL - WALL_TOP_UP - r - RING else null  # 그 열 그림 윗변 아래
	return null

# 맵 px p가 동·서 성벽·닫힌 문루·모서리 탑 그림(통로 24px + 그 바닥 높이만큼 올려 그림, S219) 안이면 그 성곽 Block, 아니면 null.
# 남·북 성벽 열은 null이다(문루·탑은 raised_at)
static func side_at(bt, p: Vector2):
	var x := int(floor(p.x / CELL))
	if x >= 3 and x < bt.size.x - 3:
		return null
	for up in [WALL_H + CORNER_RISE, WALL_H + SIDE_GATE_RISE, WALL_H]:
		var c := Vector2i(x, int(floor((p.y + up) / CELL)))
		if bt.walls.has(c) and WALL_H + rise_at(bt, c) == up:
			return bt.walls[c]
	return null

# 그림 한 장을 대상 사각형에 그린다(보통 원본과 같은 크기, 슬라임 킹은 늘이고 줄인다). _clip보다 위 줄은 뺀다
func _region(tex: Texture2D, dst: Rect2, src: Rect2, tint: Color) -> void:
	var cut := clampf(_clip - dst.position.y, 0.0, dst.size.y)
	if cut < dst.size.y:
		draw_texture_rect_region(tex, dst.grow_side(SIDE_TOP, -cut), src.grow_side(SIDE_TOP, -cut * src.size.y / dst.size.y), tint)

# 시설 하나(4.1e, 사용자 2026-10-20). 미완성은 청사진 위에 진행률만큼 아래부터 그림을 채우고, 철거 중은 거꾸로 위부터 청사진으로 돌아간다.
# 다 접힌 대포는 접힌 그림이다(I74). 성벽 위 대포(I44)는 올려 그린다
func _facility(s, tint := Color.WHITE) -> void:
	var folded: bool = s.dest != null and s.razed >= 1.0
	var f: Array = FAC["cannon_folded" if folded else s.kind]
	var t: float = 1.0 if folded else (1.0 - s.razed if s.complete else s.progress)
	var cut := roundi(f[2] - t * (f[2] - f[1]))  # 이 줄부터 아래는 그림, 위는 청사진
	var at := Vector2(s.cell * CELL) + Vector2(-FAC_FOOT.x, CELL - FAC_FOOT.y - _lift(s)) + _jolt(s)  # 맞으면 흔들린다(S199)
	var x: float = FAC_N * f[0]
	if cut > 0:
		_region(FACILITY_K, Rect2(at, Vector2(FAC_N, cut)), Rect2(x, FAC_N, FAC_N, cut), BLUEPRINT * tint)
	if cut < FAC_N:  # 다 지은 시설이 깎이면 금(S199)
		_region(FACILITY_K, Rect2(at + Vector2(0, cut), Vector2(FAC_N, FAC_N - cut)), Rect2(x, cut + crack_y(s, FACILITY.get_height()), FAC_N, FAC_N - cut), tint)

# 유닛·적 몸통 하나. 영웅은 8방향 시트, 그림이 있는 용병·적은 4방향 시트, 나머지는 원으로
func _body(x, i: int, next: Dictionary, tint := Color.WHITE, flash := true) -> void:
	if x.get("skills") and battle.raging(x):  # 분노(S195)
		tint *= RAGE
	var white: bool = flash and _hits.get(x.get_instance_id(), [INF])[0] < FLASH  # 피격 번쩍임(S177): 255배 modulate가 그림을 흰 실루엣으로 만든다(유닛 그림에 0인 채널이 없다). 배치는 끊기지 않는다
	if white and not Settings.soft_flash:
		tint *= Color(255, 255, 255)
	_paint(x, i, next, tint)
	if white and Settings.soft_flash:  # 번쩍임 줄이기(S184): 원래 그림 위에 같은 그림을 흰 40%로 한 번 더(S177)
		_paint(x, i, next, tint * SOFT_FLASH)

func _paint(x, i: int, next: Dictionary, tint: Color) -> void:
	if ART.has(x.kind) and not x.get("is_hero"):
		_four_sprite(x, next, tint)
	elif i >= battle.units.size():  # 그림이 없는 적은 색 원(I81)
		draw_circle(_spot(x), CELL * x.radius, ENEMY_COLORS.get(x.kind, ENEMY_COLORS.basic) * tint)
	elif x.is_hero and ART.has(x.kind):
		_sprite(x, next, tint)
	else:
		draw_circle(_spot(x), CELL * x.radius, (HERO_COLORS.get(x.kind, COLORS.merc) if x.is_hero else COLORS.get(x.kind, COLORS.merc)) * tint)

# 줄어든 몸(S236)의 그림 배율: 지금 반지름 ÷ 나온 때 반지름. 줄어들지 않는 몸은 1
func _shrunk(x) -> float:
	return x.radius / x.girth if x.get("girth") else 1.0

# 몸통 그림의 [발밑 기준 배율, 들어 올림 px](S198 2026-10-27 둘째 변경). 방향 없는 그림의 보스(슬라임 킹)는 점프(S236) 웅크림 동안
# CROUCH까지 점점 납작해지고, 뜬 동안 포물선으로 한가운데 LEAP_UP까지 오르며, 착지한 뒤 SLAM_POSE 동안 CROUCH에서 돌아온다
func _look(x) -> Array:
	var s := Vector2.ONE * _shrunk(x)
	if not (_boss(x) and ART.has(x.kind) and ART[x.kind].get("one", false)):
		return [s, 0.0]
	var c = x.cast
	if c != null and c.has("at"):
		var sk: Dictionary = x.skills[c.id]
		if c.get("air", false):
			var t: float = 1.0 - c.left / sk.air
			return [s, LEAP_UP * 4.0 * t * (1.0 - t)]
		return [s * Vector2.ONE.lerp(CROUCH, 1.0 - c.left / sk.windup), 0.0]
	var tr = _boss_trace(x)
	if tr != null:
		return [s * CROUCH.lerp(Vector2.ONE, tr.age / SLAM_POSE), 0.0]
	return [s, 0.0]

# 뜬 몸의 그림자(S198): 땅 자리에 납작한 반투명 타원
func _shadow(at: Vector2, r: float) -> void:
	draw_set_transform(at, 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, r, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# 성벽·거점 그림이 덮는 자리에 선 땅 유닛이나 시설: 성곽 그림이 발을 덮는 뒤 줄(성벽 두 줄, 문루 세 줄, 탑 세 줄), 거점 칸 뒤 두 줄과 그 양옆(C1, 사용자 2026-10-20)
func _behind(x) -> bool:
	if x.get("on_wall") == true or x.get("flying") == true or x.get("climbed"):
		return false
	var c := Vector2i(_pos_of(x).round())
	if not battle.walls.has(c) and _cover(c) > 0:  # 문루 통로 안(성곽 칸)은 뒤가 아니다
		return true
	var d: Vector2i = c - battle.base.cell
	return absi(d.x) <= 1 and d.y >= -2 and d.y < 0

# 발밑 팀 색(S166). i는 battle.units + battle.enemies 안의 번호다. 비행 적은 그림자 자리에 그린다
func _feet_mark(x, i: int) -> void:
	var foot := (_spot(x) if x.on_wall else _center(x.pos)) + (Vector2(0, CELL * 0.4) if x.get("flying") == true else Vector2.ZERO) + _lunge(x) + _flinch(x) + _slip(x)
	var rect := Rect2(foot + Vector2(-7, -2), Vector2(14, 6))
	var region := Rect2(14 * int(i >= battle.units.size()), 0, 14, 6)
	draw_texture_rect_region(FEET, rect, region)
	var mark := foot_mark(x)
	if mark != "":  # 고른 유닛·패널의 적(S207): 타원을 밝게 덧그리고 테두리를 두른다
		draw_texture_rect_region(FEET, rect, region, Color(SELECT_GLOW, SELECT_GLOW, SELECT_GLOW))
		_ellipse(foot + Vector2(0, 1), Vector2(8.5, 4.5), SELECT_LINES[int(mark == "foe")])

# 발밑 선택 표시(S207): 고른 영웅·용병은 «pick», 선택 패널에 보인 적(S206)은 «foe», 그 밖은 «»
func foot_mark(x) -> String:
	if x in controls.selected:
		return "pick"
	return "foe" if x == controls.shown else ""

# 맵 px 타원 테두리 1px(S207). 점을 반 px 옮겨 1px 선이 그 점에서 시작하는 도트 칸을 덮게 한다
func _ellipse(c: Vector2, r: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 33:
		pts.append(c + Vector2(cos(TAU * k / 32.0) * r.x, sin(TAU * k / 32.0) * r.y) + Vector2(0.5, 0.5))
	draw_polyline(pts, col, 1.0)

# 성곽 칸 조각 하나(front 0 몸체, 1 앞층). 조각 맨 아랫줄이 바닥선 바로 아래 줄이다. 단계(S86)마다 그림이 다르고(사용자 2026-10-20),
# 열린 성문은 몸체 위에 통로 그늘을 겹친다(I67). 잔해(I88)는 몸체 자리에 돌무더기 하나이고 바닥 층이다(S170). 맞은 칸은 흔들리고 깎이면 금(S199)
func _wall_piece(b, front: int) -> void:
	var at := Vector2(b.cell.x * CELL, (b.cell.y + 1) * CELL - (WALL_PIECE_H - 1)) + _jolt(b)
	if battle.rubble.get(b.cell) == b:
		if front == 0:
			for i in b.size.x:  # 문루 잔해는 성벽 잔해 조각을 폭만큼 잇는다
				draw_texture_rect_region(CASTLE_K, Rect2(at + Vector2(i * CELL, 0), Vector2(16, WALL_PIECE_H)), Rect2(0, 7 * WALL_PIECE_H, 16, WALL_PIECE_H))
		return
	var col: Array = wall_col(battle, b)
	var dst := Rect2(at, Vector2(col[1], WALL_PIECE_H))
	draw_texture_rect_region(CASTLE_K, dst, Rect2(col[0], (2 * (b.level - 1) + front) * WALL_PIECE_H + crack_y(b, CASTLE.get_height()), col[1], WALL_PIECE_H))
	if front == 1 and not battle.water.is_empty() and b.size == Vector2i(1, 3) and b.cell.y < battle.base.cell.y:  # 수로 수문(S220): 북벽은 앞층이 마을 쪽 벽면이라 그 위에, 그 열 폭만큼
		var x0 := maxi(b.cell.x * CELL, CULVERT_AT.x)
		var x1 := mini((b.cell.x + 1) * CELL, CULVERT_AT.x + CULVERT.get_width())
		if x1 > x0:
			draw_texture_rect_region(CULVERT, Rect2(x0, CULVERT_AT.y, x1 - x0, CULVERT.get_height()), Rect2(x0 - CULVERT_AT.x, 0, x1 - x0, CULVERT.get_height()))
	if front == 0 and b.kind == "gate" and b.open:
		draw_texture_rect_region(CASTLE_K, dst, Rect2(col[0], 6 * WALL_PIECE_H, col[1], WALL_PIECE_H))

# 성곽 Block의 조각 열 [x, 폭](S219). 북벽(거점보다 위)은 흉벽이 뒤인 열, 동·서는 행 띠·닫힌 문루, 네 모서리 3열은 모서리 탑을 열마다 자른다
static func wall_col(bt, b) -> Array:
	var n: bool = b.cell.y < bt.base.cell.y
	if b.size == Vector2i(3, 1):
		return WALL_COLS["w_strip" if b.cell.x == 0 else "e_strip"]
	if b.kind == "gate" and b.cell.x == 0:
		return WALL_COLS.w_gate
	if b.kind == "gate" and b.cell.x + 3 == bt.size.x:
		return WALL_COLS.e_gate
	if b.kind == "gate":
		return WALL_COLS["n_closed"] if n else WALL_COLS["open" if b.open else "closed"]
	if b.cell.x < 3 or b.cell.x >= bt.size.x - 3:
		var c: Array = WALL_COLS[("nc" if n else "sc") + ("_l" if b.cell.x < 3 else "_r")]
		return [c[0] + (b.cell.x if b.cell.x < 3 else b.cell.x - (bt.size.x - 3)) * CELL, CELL]
	var t := tower_of(bt, b)
	if n:
		return WALL_COLS["n_wall" if t == "" else "n_" + t]
	return WALL_COLS["castle_wall" if t == "" else t]

# 성벽 위 유닛·대포·쓰러진 몸을 정렬할 바닥선(S217): 그 성곽 Block 앞줄 바닥선 − 2에서 앞줄로 올수록 1씩 뒤다.
# 몸체(바닥선 − 3)와 앞층(바닥선 + 2) 사이라서, 통로 뒤 줄에 선 유닛도 몸체에 가리지 않고 앞층이 앞줄 유닛의 발을 가린다
func _wall_line(c: Vector2i) -> int:
	var k = battle.walls.get(c)
	if k == null:
		return (c.y + 1) * CELL + 1
	return (k.cell.y + 1) * CELL - 2 + c.y - (k.cell.y - k.size.y + 1)

# 위로 올려 그리는 정도(맵 px). 성벽 위 유닛·대포는 흉벽 바로 뒤(앞면에서 바닥 3px)에 서고, 기어오르는 적은 오른 만큼 오른다(4.1c, 05 §2).
# 문루·문 양옆 탑 칸은 그 바닥 높이만큼 더 올린다(S170). 성벽 위는 선 자리대로 그려 칸 경계에서 튀지 않는다(S170 2026-10-28)
func _lift(x) -> float:
	var p := _pos_of(x)
	var top: bool = x.on_wall if x.get("pos") != null else (x.kind in battle.STRUCTURE_KINDS and battle.walls.has(x.cell))
	if top:
		return 3 + WALL_H - CELL / 2.0 + _rise(p)
	if x.get("climbed"):
		return (3 + WALL_H + rise_at(battle, Vector2i(p.round()) + Vector2i.UP)) * x.climbed / x.climb
	return 0.0

# 성벽 위 자리 p의 바닥 높이(px, S170 2026-10-28): 둘레 네 칸 가운데의 rise_at을 이어 칸 사이를 비탈로 만든다. 성곽이 아닌 이웃은 선 칸 높이로 본다
func _rise(p: Vector2) -> float:
	var c := Vector2i(p.floor())
	var f := p - Vector2(c)
	var own := float(rise_at(battle, Vector2i(p.round())))
	var h := func(d: Vector2i) -> float: return float(rise_at(battle, c + d)) if battle.walls.has(c + d) else own
	return lerpf(lerpf(h.call(Vector2i(0, 0)), h.call(Vector2i(1, 0)), f.x), lerpf(h.call(Vector2i(0, 1)), h.call(Vector2i(1, 1)), f.x), f.y)

# 유닛·적·칸을 그릴 자리(맵 px, 칸 가운데)와 칸 사각형. 성벽 위에 있으면 올린다
func _spot(x) -> Vector2:
	return _center(_pos_of(x)) - Vector2(0, _lift(x))

func _box(s) -> Rect2:
	var r: Rect2i = battle.area_of(s)
	return Rect2(Vector2(r.position * CELL) - Vector2(0, _lift(s)), Vector2(r.size * CELL))  # 차지 칸(S216)

# 영웅 한 명(S165): 움직이면 그쪽으로 걷기 4프레임(초당 8), 친 뒤 0.3초는 대상 쪽으로 공격 3프레임, 아니면 정지.
# 서 있으면 대상 쪽, 대상도 없으면 마지막 방향을 본다. 위치는 화면 픽셀로 반올림한다(insights/2026-10-20_render_spike.md X1)
func _sprite(x, next: Dictionary, tint := Color.WHITE) -> void:
	var id: int = x.get_instance_id()
	var seen = _seen.get(id)
	var v: Vector2 = x.pos - seen[0] if seen else Vector2.ZERO
	var dir: int = seen[1] if seen else 0
	var moving := v.length_squared() > 1e-8
	var t := _ago(x)
	var pose: bool = x.target != null and t < battle.HERO_POSE and (x.path.is_empty() or t < CONTACT)  # 걷기 명령은 닿은 뒤의 공격 자세를 끊는다(S196)
	if pose or (x.target and not moving):  # 공격 자세는 밀려도 대상 쪽을 친다(S165)
		dir = _dir_of(_pos_of(x.target) - x.pos)
	elif moving:
		dir = _dir_of(v)
	next[id] = [x.pos, dir]
	var a: Dictionary = ART[x.kind]
	var c := int(a.c)
	var anim := "idle"
	var col := 0
	if pose:
		anim = "attack"
		col = clampi(int(t / 0.1), 0, 2)
	elif moving:
		anim = "walk"
		col = int(Time.get_ticks_msec() / 125.0) % 4
	var size := c * (2 if anim == "attack" else 1)  # 공격은 2배 캔버스(tools/art/hero.py)
	var at := _spot(x) + _flinch(x) + _slip(x) - Vector2(a.anchor[0], a.anchor[1]) - Vector2.ONE * (size - c) / 2.0
	_region(UNITS, Rect2(at, Vector2(size, size)), Rect2(col * size, a[anim] + dir * size, size, size), tint)

# 용병·적 하나(C 절충안, 4.1d. 4.1a M1·M6에서 C만 통과했다): 4방향 정지, 움직이면 걷기 2위상(초당 8), 친 뒤 0.08~0.22초는 공격 키 포즈.
# 근접은 그동안 대상 쪽으로 돌진한다(_lunge). 방향 고르기는 _sprite와 같다(tools/bench/view_draw.gd C). 기어오르는 적은 성벽 쪽(N)을 보고 걷기 2위상으로 오른다(S180)
func _four_sprite(x, next: Dictionary, tint := Color.WHITE) -> void:
	var id: int = x.get_instance_id()
	var seen = _seen.get(id)
	var v: Vector2 = x.pos - seen[0] if seen else Vector2.ZERO
	var dir: int = seen[1] if seen else 0
	var moving := v.length_squared() > 1e-8
	var a := _ago(x)  # 친 뒤 지난 시간(초)
	var pose: bool = x.target != null and a >= CONTACT and a < battle.POSE
	if pose or (x.target and not moving):  # 공격 자세는 밀려도 대상 쪽을 친다(S172)
		dir = _four(_pos_of(x.target) - x.pos)
	elif moving:
		dir = _four(v)
	if x.get("climbed"):
		dir = 2
	var anim := "idle"
	var col := 0
	if pose:
		anim = "attack"
	elif moving or x.get("climbed"):
		anim = "walk"
		col = int(Time.get_ticks_msec() / 125.0) % 2
	var off := Vector2.ZERO
	if _boss(x):  # 보스 스킬(S198): 예고 끝에 들어 올렸다가 발동하면 내리찍는다. 원 모양 스킬은 화면 쪽(S)을, 방향 스킬은 그쪽을 본다
		var c = _boss_trace(x)
		if ART[x.kind].get("one", false):  # 방향 없는 그림(슬라임 킹, S198 2026-10-27 둘째 변경)은 웅크림·뜸·착지를 정지 그림으로 하고 모양은 _look이 정한다
			if c != null or x.cast:
				anim = "idle"
				col = 0
		elif c != null:
			anim = "attack"
			col = 0  # 4방향 시트의 공격은 키 포즈 한 칸이다. 밀려 걷는 위상이 남으면 빈 칸을 그린다
			dir = 0 if c.aim == null else _four(Vector2(c.aim) - c.at)
			off.y = 1.0
		elif x.cast and x.cast.left < LIFT:
			anim = "idle"
			col = 0
			dir = 0
			off.y = -2.0
		if x.fx.has("stagger"):  # 비틀거리는 동안 8프레임마다 좌우로 1px 떤다
			off.x = 1.0 if int(clock * 60.0 / 8.0) % 2 == 0 else -1.0
	next[id] = [x.pos, dir]
	var p := _spot(x) + _lunge(x) + _flinch(x) + _slip(x) + off
	var lk := _look(x)
	if x.get("cast") and x.cast.get("air", false):
		_shadow(p, CELL * x.radius)
	_frame(ART[x.kind], anim, dir, col, p - Vector2(0, lk[1]), tint, lk[0])

# 그릴 쓰러진 몸(S180) [몸, 쓰러진 뒤 초]: 시뮬레이션이 아직 지우지 않은 적·용병과 복귀 전 영웅. 영웅은 지워진 뒤에도 마지막 자세로 남는다
func _fallen() -> Array:
	var out := []
	for f in battle.fallen:  # 어둠 속에서 쓰러진 적(S213)은 그리지 않는다. 적에게는 is_hero가 없다
		if f.who.get("is_hero") != true and ART.has(f.who.kind) and (f.who.get("is_hero") != null or battle.seen(f.who.pos)):
			out.append([f.who, f.age])
	for h in battle.heroes:
		if not h.alive and ART.has(h.kind):
			var f: Array = battle.fallen.filter(func(e): return e.who == h)
			out.append([h, f[0].age if f else battle.FALLEN])
	return out

# 쓰러진 몸 하나(S180): 4.1d 누운 자세. 영웅은 쓰러짐 5프레임을 지나 누운 채 남고, 적·용병은 바로 누워 지워지기 전 CORPSE_FADE 동안 흐려진다.
# 성벽 위에서 쓰러지면 성벽 위에, 오르던 적은 성벽 밑에, 비행 적은 그림자 자리에 눕는다. 막타를 기다리거나 번쩍이는 동안은 선 자세다(S197)
func _corpse(d: Array) -> void:
	var x = d[0]
	var hero: bool = x.get("is_hero") == true
	var s := _last_blow(x, d[1])
	if s[0]:
		var soft: bool = s[1] and Settings.soft_flash  # 번쩍임 줄이기(S184)면 선 자세 위에 흰 40%를 덧그린다(S197)
		_frame(ART[x.kind], "idle", s[4], 0, _spot(x) + s[2], Color(255, 255, 255) if s[1] and not soft else Color.WHITE)  # 흰 실루엣은 _body의 피격 번쩍임과 같은 255배 modulate
		if soft:
			_frame(ART[x.kind], "idle", s[4], 0, _spot(x) + s[2], SOFT_FLASH)
		return
	var p: Vector2 = (_spot(x) if x.on_wall else _center(x.pos) + (Vector2(0, CELL * 0.4) if x.get("flying") == true else Vector2.ZERO)) + s[2]
	var a := 1.0 if hero else clampf((battle.FALLEN - d[1]) / CORPSE_FADE, 0.0, 1.0)
	_frame(ART[x.kind], "fall", 0, mini(int(s[3] / FALL_STEP), 4) if hero else 0, p, Color(1, 1, 1, a), Vector2.ONE * _shrunk(x))

# 4방향 시트(tools/art/atlas.py FOUR)의 한 칸을 발밑 p에 그린다. 행은 S·E·N·W, 공격·쓰러짐은 2배 캔버스. 방향 없는 칸(one, I189)은 늘 0행이다.
# scale은 발밑 기준 배율이다(슬라임 킹 웅크림·줄어듦, S198)
func _frame(a: Dictionary, anim: String, dir: int, col: int, p: Vector2, tint := Color.WHITE, scale := Vector2.ONE) -> void:
	var c := int(a.c)
	var size := c * (2 if anim == "attack" or anim == "fall" else 1)
	var at := p - (Vector2(a.anchor[0], a.anchor[1]) + Vector2.ONE * (size - c) / 2.0) * scale
	var row := 0 if a.get("one", false) else dir
	_region(UNITS, Rect2(at, Vector2(size, size) * scale), Rect2(a.get("x", 0) + col * size, a[anim] + row * size, size, size), tint)  # 주민 칸(S221)·방향 없는 칸(I189)은 x가 있다

# 화면 방향 v → 4방향 시트 행(S·E·N·W)
func _four(v: Vector2) -> int:
	return posmod(roundi((90.0 - rad_to_deg(v.angle())) / 90.0), 4)

# 주민 몸(S172·S223). 걷기·놀기는 움직이는 쪽을 보고 걷기 2위상, 들고 걷기도 같은 4방향 시트다. 제자리 일 자세는 일터 쪽(동·서)을
# 숙련에 따른 간격(Folk.frame_gap, S231)마다 2프레임 번갈고, 그 자세 그림이 없는 칸이면 정지·걷기로 그린다
func _folk_body(x, now: float) -> void:
	var a: Dictionary = ART["folk_%s_%d" % [x.f.body, x.f.look]]
	var v: Vector2 = x.pos - x.was
	var moving := v.length_squared() > 1e-8
	var at := _center(x.pos)
	if x.pose.begins_with("carry") and a.has(x.pose):
		_frame(a, x.pose, _four(v) if moving else 0, int(now * 8.0) % 2 if moving else 0, at)
	elif x.dir >= 0 and a.has(x.pose):
		_frame(a, x.pose, x.dir, int(now / Folk.frame_gap(x.m)) % 2, at)
	else:
		_frame(a, "walk" if moving else "idle", _four(v), int(now * 8.0) % 2 if moving else 0, at)

# 이번 판의 일터 소품(S224): [종류, 칸, 정렬 바닥선 y(px)]. 여관 간판은 집 앞줄 바닥선 바로 뒤에 그려 집 그림 위에 얹는다
func _prop_list() -> Array:
	var pr := props(battle)
	var out := []
	if not pr.mill.is_empty():
		out.append(["mill", pr.mill[0], (pr.mill[1].y + 1) * CELL])
	for c in pr.oven:
		out.append(["oven", c, (c.y + 1) * CELL])
	for k in pr.stalls.size():
		out.append(["stall%d" % k, pr.stalls[k], (pr.stalls[k].y + 1) * CELL])
	for c in pr.inn:
		out.append(["inn", c, (c.y + 1) * CELL + 1])
	return out

# 소품 하나(art/tiles/props.png, tools/art/props.py). 물레방아 바퀴는 PROP_WHEEL_FPS로 네 장을 돈다
func _prop(p: Array, now: float) -> void:
	var r: Rect2 = PROP_ART[p[0]]
	var at: Vector2 = Vector2(p[1]) * CELL + PROP_AT[p[0]]
	draw_texture_rect_region(PROPS, Rect2(at, r.size), r)
	if p[0] == "mill":
		var w: Rect2 = PROP_ART.wheel
		draw_texture_rect_region(PROPS, Rect2(Vector2(Folk.MILL[1]) * CELL + PROP_AT.wheel, w.size), Rect2(w.position + Vector2(w.size.x * (int(now * PROP_WHEEL_FPS) % 4), 0), w.size))

# 근접 용병·적의 돌진(px): 친 뒤 0.08초에 대상 쪽으로 LUNGE만큼 나가고 0.32초에 걸쳐 돌아온다. 발밑 표시도 함께 옮긴다.
# 영웅(8방향 공격 프레임, S165)과 원거리(사거리 2칸 초과)는 돌진하지 않는다
func _lunge(x) -> Vector2:
	var a := _ago(x)
	if x.get("is_hero") or (x.get("range") != null and x.range > 2.0) or not x.target or a >= 0.4:
		return Vector2.ZERO
	return (_pos_of(x.target) - x.pos).normalized() * LUNGE * (a / CONTACT if a < CONTACT else 1.0 - (a - CONTACT) / 0.32)

# 공격자 xs 가운데 방금 친 것의 대상 → [맞은 뒤 지난 시간(초), 공격자 → 대상 방향, 무거운 타격](S177). 여럿에게 맞으면 가장 최근 타격이다.
# 근접 기본 공격은 시뮬레이션에 상태를 두지 않고 공격자의 친 뒤 시간에서 구한다(06 §4). 원거리는 시뮬레이션 투사체가 닿은 때부터다(battle.landed, S178).
# 즉시 스킬은 시뮬레이션이 남긴 흔적(traces)의 맞은 대상이다(S179). 보스가 친 타격과 보스 스킬에 맞은 것은 무겁다(S198): 더 멀리 밀리고 늦게 돌아온다
func hit_table(xs: Array) -> Dictionary:
	var hits := {}
	for x in xs:
		if x.get("target") != null and not _ranged(x):
			var t: float = _ago(x) - _contact(x)
			var id: int = x.target.get_instance_id()
			var heavy := _boss(x)
			if t >= 0.0 and t < (HEAVY_BACK if heavy else FLINCH_BACK) and t < hits.get(id, [INF])[0]:
				hits[id] = [t, (_pos_of(x.target) - _pos_of(x)).normalized(), heavy]
	for m in battle.landed:  # 투사체에 맞은 적: 날아온 쪽 반대로 밀린다. 영웅이 쏜 것은 닿은 때 HITSTOP만큼 멈춘다(S177)
		var t: float = maxf(m.age - HITSTOP, 0.0) if m.src.get("is_hero") == true else m.age
		var id: int = m.target.get_instance_id()
		if t < FLINCH_BACK and t < hits.get(id, [INF])[0]:
			hits[id] = [t, (m.target.pos - m.from).normalized(), false]
	for c in battle.traces:  # 즉시 스킬에 맞은 적(S179): 쓴 때(운석은 떨어진 때)부터, 흔적 가운데의 반대쪽으로 밀린다
		var boss := _boss(c.hero)
		for t in c.hits if c.age < (HEAVY_BACK if boss else FLINCH_BACK) else []:
			var id: int = t.get_instance_id()
			if (t in battle.enemies or boss) and c.age < hits.get(id, [INF])[0]:  # 보스 스킬(S198)은 맞은 아군·구조물
				hits[id] = [c.age, (_pos_of(t) - c.at).normalized(), boss]
	return hits

# 친 뒤 보일 시간(초). 영웅이 치거나 맞은 근접 타격은 닿은 때(_contact)에서 HITSTOP만큼 멈췄다가 늦게 흐른다(S177). 원거리는 쏜 쪽이 멈추지 않는다
func _ago(x) -> float:
	var a: float = (x.attack_gap if x.get("attack_gap") != null else x.fire_gap) - x.cooldown
	var c := _contact(x)
	if a >= c and x.target != null and not _ranged(x) and (x.get("is_hero") == true or x.target.get("is_hero") == true):
		return maxf(a - HITSTOP, c)
	return a

# 근접 공격이 대상에 닿는 때(친 뒤 초)는 돌진 끝이다. 원거리는 투사체가 나가는 때(유닛 CONTACT, 타워 0)이고, 닿는 때는 시뮬레이션 투사체가 정한다(battle.landed, S178)
func _contact(x) -> float:
	return 0.0 if x.get("pos") == null else CONTACT

# 맞은 몸의 밀림(px, S177): 공격자 반대쪽으로 FLINCH만큼 밀렸다가 FLINCH_BACK에 걸쳐 돌아온다. 무거운 타격은 HEAVY·HEAVY_BACK(S198). 발밑 표시도 함께 옮긴다
func _flinch(x) -> Vector2:
	var h = _hits.get(x.get_instance_id())
	if h == null:
		return Vector2.ZERO
	return h[1] * (HEAVY * (1.0 - h[0] / HEAVY_BACK) if h[2] else FLINCH * (1.0 - h[0] / FLINCH_BACK))

# 맞은 구조물·성곽 칸·거점 그림의 흔들림(S199): 닿은 뒤 JOLT초 동안 공격자 반대쪽 주축으로 1px. 옮겨 갈 칸의 청사진(사전)은 맞지 않는다
func _jolt(x) -> Vector2:
	var h = _hits.get(x.get_instance_id()) if x is Object else null
	if h == null or h[0] >= JOLT:
		return Vector2.ZERO
	var d: Vector2 = h[1]
	return Vector2(signf(d.x), 0.0) if absf(d.x) >= absf(d.y) else Vector2(0.0, signf(d.y))

# 금 단계(S199): 다 지은 구조물·성곽 칸·거점의 체력이 75·50·25% 밑이면 1·2·3줄. 미완성·청사진(사전)은 0
static func crack_stage(b) -> int:
	if not b is Object or not b.complete:
		return 0
	var r: float = b.hp / b.max_hp
	return 3 if r < 0.25 else 2 if r < 0.5 else 1 if r < 0.75 else 0

# 금 단계와 무늬(칸 좌표 해시)가 고르는 crack_atlas 사본의 y. h는 원본 아틀라스 높이다. 금이 없으면 0(원본)
static func crack_y(b, h: int) -> int:
	var s := crack_stage(b)
	return 0 if s == 0 else ((s - 1) * 2 + _h(b.cell.x * 131 + b.cell.y, 0, 0, 1) + 1) * h

# 화면 시계와 사건 목록(I170, I171). main이 battle.step(delta) 바로 뒤에 같은 delta로 부른다. 그리기만 바꾸고 시뮬레이션은 건드리지 않는다
func tick(dt: float) -> void:
	clock += dt
	if night:  # 어둠 덮개(S212): 지금 어둠·불빛을 셰이더에 넘기고, 낮이면 숨긴다
		var mat: ShaderMaterial = night.material
		var params := night_params()
		for k in params:
			mat.set_shader_parameter(k, params[k])
		night.visible = battle.dark > 0.0
	events = []
	_fills = _fills.map(func(f): return [f[0], f[1] - 1]).filter(func(f): return f[1] > 0)
	_scan()
	for e in events:
		_react(e)
	_dots = _dots.filter(func(d): return clock - d.t0 < d.life)
	_slide_scan()

# 이번 프레임에 새로 생긴 사건(I171). 판 단계가 준비·전투일 때와, 전투에서 넘어온 라운드 사이·도전 성공·패배에서 낸다.
# 근접의 닿음·처치는 공격자의 친 뒤 시간이 닿는 때(_contact)를 넘은 프레임에 공격 하나에 한 번이고, 처치는 쓰러진 대상을 노린 마지막 공격이 닿을 때다(S197).
# 원거리는 시뮬레이션 투사체가 닿은 프레임에 투사체 하나에 한 번이다. 피해와 닿음이 같은 때라 처치가 기다리지 않는다(S178)
func _scan() -> void:
	var s: String = battle.state
	if s == "battle":
		_from_battle = true
	elif not s in ["cleared", "won", "lost"]:
		_from_battle = false
	_live = _primed and (s == "prep" or _from_battle)
	var gone := {}
	for f in battle.fallen:  # 쓰러진 대상은 마지막 공격이 닿을 때까지 처치 사건을 기다린다(한 번만)
		var id: int = f.who.get_instance_id()
		gone[id] = true
		if not _gone.has(id):
			_dead[id] = [f.who, clock, _seen.get(id, [null, 0])[1]]
	_gone = gone
	for id in _killed.keys():  # 몸이 지워졌거나 일어난 영웅의 막타 기록은 버린다
		var w = _killed[id][2]
		if w.alive or not (gone.has(id) or w.get("is_hero") == true):
			_killed.erase(id)
	var pend := {}  # 쓰러진 대상 id → 아직 닿지 않은 공격 수
	var found := []  # [공격자, 새 공격인가, 이번 프레임에 닿았나]
	var atk := {}  # 이번 프레임의 공격자만 남긴다(쓰러지거나 팔린 공격자는 지워진다)
	for x in battle.units + battle.enemies + battle.structures.values():
		var id: int = x.get_instance_id()
		if x.get("target") == null:  # 대상이 없으면 다음 공격이 첫 공격이어도 «쏨»이 나게 한다
			atk[id] = [INF, true]
			continue
		var raw: float = (x.attack_gap if x.get("attack_gap") != null else x.fire_gap) - x.cooldown  # 히트스톱으로 멈추지 않은 친 뒤 시간
		var near := not _ranged(x)  # 원거리의 닿음은 아래 battle.landed에서 낸다
		var hit: bool = near and _ago(x) >= _contact(x)
		var was = _atk.get(id)
		var fresh: bool = was != null and raw < was[0]  # 친 뒤 시간이 줄면 새 공격이다
		var landed: bool = hit if was == null else (false if fresh else was[1])
		var now: bool = hit and not landed
		atk[id] = [raw, landed or now]
		if near and not (landed or now) and _dead.has(x.target.get_instance_id()):
			pend[x.target.get_instance_id()] = true
		found.append([x, fresh, now])
	_atk = atk
	for f in found:
		var x = f[0]
		var t = x.target
		if f[1]:
			_emit("fire", _muzzle(x) if _ranged(x) else _spot(x), Vector2.ZERO, x, t)
		if f[2]:
			var kind := "struct" if t.get("pos") == null else "hit"
			var tid: int = t.get_instance_id()
			var dir: Vector2 = (_pos_of(t) - _pos_of(x)).normalized()
			if _dead.has(tid) and not pend.has(tid):
				kind = "kill"
				_kill(t, dir)
			_emit(kind, _chest(t) if t.get("pos") != null else _spot(t), dir, x, t, {"heavy": _boss(x)})
	var shots := {}
	for m in battle.landed:  # 원거리: 새로 닿은 투사체마다 닿음, 그 투사체에 쓰러졌으면 처치. 먼저 쓰러진 대상의 빈 자리에 떨어진 대포알은 내지 않는다
		var mid: int = m.get_instance_id()
		shots[mid] = true
		if _landed.has(mid):
			continue
		var t = m.target
		var tid: int = t.get_instance_id()
		var kind := "hit"
		var dir: Vector2 = (t.pos - m.from).normalized()
		if _dead.has(tid) and not pend.has(tid):
			kind = "kill"
			_kill(t, dir)
		elif not t.alive and not _dead.has(tid):
			continue
		_emit(kind, _chest(t), dir, m.src, t, {"heavy": m.src.kind == "cannon"})
	_landed = shots
	for tid in _dead.keys():  # 기다릴 공격이 없는 죽음(지속 피해·장판·범위 곁 대상, 쏜 쪽이 먼저 쓰러짐)과 1초 넘게 기다린 것
		if not pend.has(tid) or clock - _dead[tid][1] >= 1.0:
			var t = _dead[tid][0]
			var dir := Vector2.ZERO  # 바로 눕는다. 즉시 스킬·보스 스킬에 쓰러졌으면 이번 흔적 가운데의 반대쪽으로 밀린다(S197)
			if not pend.has(tid):
				for c in battle.traces:
					if c.hits.has(t) and not _known.any(func(k): return is_same(k, c)):
						dir = (t.pos - c.at).normalized()
			_kill(t, dir)
			_emit("kill", _spot(t), dir, null, t)
	for c in battle.traces:  # 새 흔적: 영웅 스킬 또는 보스 스킬 발동
		if not _known.any(func(k): return is_same(k, c)):
			_emit("boss" if _boss(c.hero) else "cast", _center(c.at), Vector2.ZERO, c.hero, null, {"ref": c, "slot": c.slot})
	_known = battle.traces.duplicate()
	var tell := {}
	for e in battle.enemies:  # 보스 스킬 예고가 기절·빙결로 끊김(S194, S198)
		var id: int = e.get_instance_id()
		if e.cast:
			tell[id] = [_center(e.cast.get("at", e.pos)), CELL * e.skills[e.cast.id].radius]  # 조각은 예고 원 둘레에(점프는 착지 자리, S198)
		elif _tell.has(id) and e.fx.has("stagger") and e.fx.stagger.left > battle.STAGGER - 0.25:  # 이번에 막 걸린 비틀거림만
			_emit("interrupt", _tell[id][0], Vector2.ZERO, e, null, {"radius": _tell[id][1]})
	_tell = tell
	for c in battle.rubble:  # 성곽 칸 붕괴
		if not _rubble.has(c):
			_emit("collapse", _center(battle.middle(battle.rubble[c])), Vector2.ZERO, null, battle.rubble[c], {"cell": c})
	_rubble = battle.rubble.duplicate()
	_primed = true

# 막타가 닿았다(S197): dir이 있으면 그 몸이 번쩍이며 밀려 눕고, 없으면 바로 눕는다
func _kill(t, dir: Vector2) -> void:
	var id: int = t.get_instance_id()
	_killed[id] = [clock, dir, t, _dead[id][2] if _dead.has(id) else 0]
	_dead.erase(id)

# 쓰러진 몸의 막타 단계(S197) [선 자세인가, 흰 번쩍임인가, 밀린 px, 누운 뒤 초, 보던 방향]. 막타 기록이 없으면 쓰러진 때(age) 바로 누운 것이다
func _last_blow(x, age := 0.0) -> Array:
	var id: int = x.get_instance_id()
	if _dead.has(id):  # 막타를 기다린다
		return [true, false, Vector2.ZERO, 0.0, _dead[id][2]]
	var k = _killed.get(id)
	if k == null:
		return [false, false, Vector2.ZERO, age, 0]
	var t: float = clock - k[0]
	var hit: bool = k[1] != Vector2.ZERO
	var up: bool = hit and t < FLASH
	return [up, up, k[1] * KILL_PUSH * minf(t / FLASH, 1.0), t - FLASH if hit else t, k[3]]

# 쓰러진 영웅의 X 자리(I130, S197): 막타가 닿은 때부터 밀린 자리에. 살아 있거나 막타를 기다리면 null
func _cross_at(h):
	if h.alive or _dead.has(h.get_instance_id()):
		return null
	return _spot(h) + _last_blow(h)[2]

func _emit(kind: String, at: Vector2, dir: Vector2, src, dst, more := {}) -> void:
	if not _live:
		return
	_n += 1
	var e := {"kind": kind, "at": at, "dir": dir, "src": src, "dst": dst, "n": _n, "heavy": false}
	e.merge(more, true)
	events.append(e)

# 사건에 붙는 그림(S198~S200): 보스 스킬 발동은 바닥 균열과 먼지, 끊김은 예고 둘레의 조각, 구조물이 맞으면 부스러기, 성곽 칸이 무너지면 먼지와 돌 조각
func _react(e: Dictionary) -> void:
	match e.kind:
		"struct":  # 근접 공격이 닿은 면(공격자 쪽)에서
			_debris(e.at - e.dir * CELL * 0.4, e.n)
		"collapse":  # 칸 아래(앞줄 바닥선)에서 먼지 12점이 퍼지고, 성벽 꼭대기에서 돌 조각 4개가 0.25초 안에 때를 엇갈려 떨어진다
			var k = e.dst
			var x0: float = k.cell.x * CELL
			var w: float = k.size.x * CELL
			var floor_y: float = (k.cell.y + 1) * CELL - 1
			for i in 12:
				var p := Vector2(roundf(x0 + w * (i + 0.5) / 12.0), floor_y)
				var d := Vector2.from_angle(deg_to_rad(i * 30.0 + _h(e.n, i, -12, 12)))
				_dot({"p0": p, "p1": p + Vector2(d.x, d.y * 0.5) * _h(e.n, 20 + i, 8, 16), "rise": _h(e.n, 40 + i, 2, 4), "col": DUST, "size": Vector2(2, 2), "life": 0.45, "fade": 0.2})
			var top: float = floor_y - 3 - WALL_H - rise_at(battle, k.cell)
			for i in 4:
				var wait := i * 0.03 + _h(e.n, 60 + i, 0, 2) * 0.01
				var p := Vector2(roundf(x0 + 2 + (w - 4) * (i + 0.5) / 4.0), top + _h(e.n, 70 + i, -3, 3))
				_dot({"p0": p, "p1": Vector2(p.x + _h(e.n, 80 + i, -3, 3), floor_y), "col": STONE, "size": Vector2(3, 3), "life": 0.25 - wait, "fade": 0.05, "wait": wait, "fall": true})
		"boss":
			for t in e.ref.hits:  # 보스 스킬에 맞은 구조물·성곽 칸·거점(Block에는 pos가 없다)
				if t.get("pos") == null:
					_debris(_spot(t), e.n * 31 + t.get_instance_id())
			_fills.append([e.ref, FILL])
			var foot: Vector2 = _center(e.ref.at)
			for i in 5:  # 균열 5줄: 발밑에서 바깥으로 8~14px, 1px 걸음마다 어두운 금과 그 아래 밝은 가장자리
				var d := Vector2.from_angle(deg_to_rad(i * 72.0 + _h(e.n, i, -17, 17)))
				for j in _h(e.n, 10 + i, 8, 14):
					var p := (foot + d * (j + 2)).round()
					_dot({"p0": p + Vector2(0, 1), "col": CRACK[1], "life": 1.3, "fade": 0.3, "ground": true})
					_dot({"p0": p, "col": CRACK[0], "life": 1.3, "fade": 0.3, "ground": true})
			for i in 8:  # 먼지 8점이 바깥으로 퍼진다
				var d := Vector2.from_angle(deg_to_rad(i * 45.0 + _h(e.n, 20 + i, -10, 10)))
				_dot({"p0": foot, "p1": foot + d * _h(e.n, 30 + i, 10, 18), "rise": _h(e.n, 40 + i, 1, 3), "col": DUST, "size": Vector2(2, 2), "life": 0.35, "fade": 0.15})
		"interrupt":  # 끊긴 예고 둘레에서 조각 12개가 바깥으로 흩어진다
			for i in 12:
				var d := Vector2.from_angle(deg_to_rad(i * 30.0 + _h(e.n, i, -5, 5)))
				var p: Vector2 = e.at + d * (e.radius + 1.0)
				_dot({"p0": p, "p1": p + d * _h(e.n, 20 + i, 6, 9), "col": TELL, "to": Color("efac28"), "size": Vector2(3, 3), "life": 0.3, "fade": 0.15})

# 부스러기 2점(S199): 좌우로 하나씩 4~7px 튀어 올랐다가 떨어진다
func _debris(at: Vector2, n: int) -> void:
	var p := at.round()
	for i in 2:
		_dot({"p0": p, "p1": p + Vector2((1 - 2 * i) * _h(n, 60 + i, 4, 7), _h(n, 62 + i, 2, 4)), "rise": _h(n, 64 + i, 3, 5), "col": DEBRIS, "size": Vector2(2, 2), "life": 0.35, "fade": 0.1})

# 효과 점 하나(I172). p1까지 _out으로 움직이며 가운데에서 rise만큼 솟는다. to가 있으면 그 색으로 바뀐다. 마지막 fade초에 흐려진다.
# wait초 뒤에 나타나고, fall이면 떨어지는 것처럼 점점 빨리 움직인다(S200 돌 조각)
func _dot(d: Dictionary) -> void:
	var p0: Vector2 = d.p0
	_dots.append({"p0": p0, "p1": d.get("p1", p0), "rise": float(d.get("rise", 0.0)), "t0": clock + d.get("wait", 0.0), "life": d.life, "fade": d.get("fade", 0.0),
		"col": d.col, "to": d.get("to", d.col), "size": d.get("size", Vector2.ONE), "ground": d.get("ground", false), "fall": d.get("fall", false)})

# 효과 점을 그린다(I172). 사각형만 써서 점이 몇 개든 배치 하나다. ground면 몸통 아래 바닥 점(균열)
func _fx_dots(ground: bool) -> void:
	for d in _dots:
		if d.ground != ground:
			continue
		var t: float = clock - d.t0
		if t < 0.0:  # 아직 나타나지 않았다(wait)
			continue
		var k := clampf(t / d.life, 0.0, 1.0)
		var p: Vector2 = d.p0 + (d.p1 - d.p0) * (k * k if d.fall else _out(k)) + Vector2(0, -d.rise * sin(PI * k))
		var a: float = 1.0 if t < d.life - d.fade else (d.life - t) / d.fade
		var col: Color = d.col
		draw_rect(Rect2(p - d.size / 2.0, d.size), Color(col.lerp(d.to, k), a))

# 사건 번호 n과 칸 k로 lo~hi 정수를 고른다. 모양의 무작위는 이것만 쓴다(시뮬레이션 난수는 저장되므로 쓰지 않는다, I170)
static func _h(n: int, k: int, lo: int, hi: int) -> int:
	return lo + posmod(hash(n * 7919 + k), hi - lo + 1)

# 넉백·끌어옴처럼 한 스텝에 8px 넘게 옮겨진 몸은 지난 자리에서 미끄러지게 그린다(S198). 보스 스킬에 맞은 것은 160px, 그 밖은 48px까지.
# 옮겨진 거리는 시뮬레이션 자리로 잰다(성벽 위 몸은 그리는 높이가 칸마다 바뀌어서 화면 자리로 재면 걷기도 튄다).
# 성벽을 오르내리거나 기어오르기를 마친 스텝(성벽 위·기어오르기 상태가 바뀜)은 미끄러지지 않는다.
# 다만 성곽 칸이 무너져 그 위에서 땅으로 내려온 몸은 DROP초에 걸쳐 내려온다(S200)
func _slide_scan() -> void:
	var far := {}
	var fell := {}  # 이번 프레임에 무너진 성곽 칸
	for e in events:
		if e.kind == "boss":
			for t in e.ref.hits:
				far[t.get_instance_id()] = true
		elif e.kind == "collapse":
			for c in battle.cells_in(battle.area_of(e.dst)):
				fell[c] = true
	var next := {}
	for x in battle.units + battle.enemies:
		var id: int = x.get_instance_id()
		var c := _center(x.pos)
		var state := [x.on_wall, x.get("climbed") != null and x.climbed > 0.0]
		var was = _last.get(id)  # [지난 그린 자리(미끄러짐 빼고), 지난 시뮬레이션 자리, 상태]
		if was != null and was[2] == state:
			var d: float = c.distance_to(was[1])
			if d > 8.0 and d <= (160.0 if far.has(id) else 48.0):
				var from: Vector2 = was[0]
				var s = _slides.get(id)
				if s != null:  # 미끄러지는 중에 또 옮겨지면 지금 그려진 자리에서 다시 미끄러진다
					from = s[0].lerp(was[0], _out(clampf((clock - s[1]) / s[2], 0.0, 1.0)))
				_slides[id] = [from, clock, clampf(d / SLIDE, 0.12, 0.3)]
		elif was != null and was[2][0] and not x.on_wall and fell.has(Vector2i(x.pos.round())):
			_slides[id] = [was[0], clock, DROP]
		next[id] = [_spot(x), c, state]
	_last = next
	for id in _slides.keys():
		if clock - _slides[id][1] >= _slides[id][2]:
			_slides.erase(id)

# 미끄러지는 몸을 그릴 자리와 시뮬레이션 자리의 차(S198)
func _slip(x) -> Vector2:
	var s = _slides.get(x.get_instance_id())
	if s == null:
		return Vector2.ZERO
	var p := _spot(x)
	return s[0].lerp(p, _out(clampf((clock - s[1]) / s[2], 0.0, 1.0))) - p

# 보스: 스킬(S194)이 있는 적
func _boss(x) -> bool:
	return x != null and x.get("skills") is Dictionary and not x.skills.is_empty()

# 보스 x가 SLAM_POSE초 안에 남긴 가장 최근 스킬 흔적. 없으면 null
func _boss_trace(x):
	for i in range(battle.traces.size() - 1, -1, -1):
		var c = battle.traces[i]
		if c.hero == x and c.age < SLAM_POSE:
			return c
	return null

# 보스 그림이 이 영웅 그림의 25% 넘게 덮나(S198). 보스가 정렬상 나중(바닥선이 같거나 아래)일 때만이다
func _under_boss(h) -> bool:
	if h.on_wall or not ART.has(h.kind):
		return false
	var a: Dictionary = ART[h.kind]
	var r := Rect2(_spot(h) - Vector2(a.anchor[0], a.anchor[1]), Vector2(a.c, a.c))
	for e in battle.enemies:  # 정렬 키는 바닥선 y의 정수다(_bodies)
		if _boss(e) and ART.has(e.kind) and int(_center(e.pos).y) >= int(_center(h.pos).y):
			var b: Dictionary = ART[e.kind]
			var lk := _look(e)  # 줄이고 늘이고 들어 올린 그대로 잰다(S198 2026-10-27 둘째 변경)
			var at: Vector2 = _spot(e) - Vector2(0, lk[1]) - Vector2(b.anchor[0], b.anchor[1]) * lk[0]
			if r.intersection(Rect2(at, Vector2(b.c, b.c) * lk[0])).get_area() > 0.25 * r.get_area():
				return true
	return false

static func _feet() -> ImageTexture:
	var im := Image.create_empty(28, 6, false, Image.FORMAT_RGBA8)
	for t in 2:
		for y in 6:
			for x in 14:
				if pow((x + 0.5 - 7.0) / 7.0, 2) + pow((y + 0.5 - 3.0) / 3.0, 2) <= 1.0:
					im.set_pixel(14 * t + x, y, TEAM[t])
	return ImageTexture.create_from_image(im)

# 바닥(4.1b, 사용자 2026-10-20): 풀 바탕에 마을 칸의 꼭짓점 일부와 들판 길이 흙이다. 마을 아래 변의 흙은 들판 쪽으로 꼭짓점 0~2개만큼 불규칙하게 번진다.
# 칸마다 네 꼭짓점으로 16꼴 가운데 하나를 고르고, 변종(풀·흙 한 가지인 칸은 넷, 전환 칸은 셋) 가운데 하나를 고른다. 출현 지점에는 깃발을 얹는다.
# 들판(S201)은 길(_road) 꼭짓점도 흙이고, 빈 들판 칸에 그을음·구덩이·자갈·풀을 찍는다. 맵 아래 맵 밖 띠(I50)에는 숲 바닥을 깔고 마른 나무를 세운다.
# 마을(S169·S202 2026-10-26 둘째·셋째 변경)은 길 골격(_plan)의 꼭짓점과 성곽 줄 꼭짓점만 흙이다. 박석(_pave)을 깔고, 텃밭과
# 우물 밑 판석·자갈 마당을 찍고, 풀꽃 무더기(_clusters)를 모은 뒤 성 안 풀을 바랜다(_worn). 물 칸이 있는 판은 그 위에 수로·연못 덮개를 섞는다(S220)
static func bake_ground(b) -> ImageTexture:
	var src := GROUND_TILES.get_image()
	var deco := DECOR.get_image()
	var img := Image.create_empty(b.size.x * CELL, b.size.y * CELL + int(Camera.BOTTOM), false, src.get_format())
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var spill := range(b.size.x + 1).map(func(_x): return rng.randi_range(0, 2))
	var vil: Rect2i = b.village
	var road := _road(b)
	var plan := _plan()
	var dirt := func(x: int, y: int) -> int:
		var inv: bool = vil.has_area() and x >= 0 and x <= b.size.x and y >= vil.position.y and y <= b.field_y - 1 + spill[x]  # 성곽(S217) 아래끝에서 들판 쪽으로 번진다
		return int(inv and (y >= vil.end.y or plan.dirt.has(Vector2i(x, y))) or road.has(Vector2i(x, y)))
	var vsrc := _village_tiles()
	for y in b.size.y:
		for x in b.size.x:
			var k: int = dirt.call(x, y) + 2 * dirt.call(x + 1, y) + 4 * dirt.call(x, y + 1) + 8 * dirt.call(x + 1, y + 1)
			var whole := k == 0 or k == 15
			var v := rng.randi_range(0, 3 if whole else 2)
			var at := Vector2i(k, 0)
			if v > 0:
				at = Vector2i(v - 1 + (3 if k == 15 else 0), 1) if whole else Vector2i(k, 1 + v)
			img.blit_rect(vsrc if vil.has_point(Vector2i(x, y)) else src, Rect2i(at * CELL, Vector2i(CELL, CELL)), Vector2i(x, y) * CELL)
	var open := _open_cells(b, road)
	var f := _field_scale(b)
	for i in roundi(9 * f):  # 그을음 48×32는 가운데 칸 둘레 3×3이 모두 빈 들판일 때만
		var c: Vector2i = open[rng.randi() % open.size()]
		if range(9).all(func(k): return open.has(c + Vector2i(k % 3 - 1, k / 3 - 1))):
			img.blend_rect(deco, Rect2i(48 * (i % 3), 16, 48, 32), c * CELL - Vector2i(16, 8))
	for k in [[5, 7], [7, 30], [9, 25]]:  # 구덩이 7·자갈 30·풀 25(40×22 들판 기준). 자갈·풀은 칸 안에서 조금씩 비낀다
		for i in roundi(k[1] * f):
			var off := Vector2i.ZERO if k[0] == 5 else Vector2i(rng.randi_range(-3, 3), rng.randi_range(-3, 3))
			img.blend_rect(deco, Rect2i(CELL * (k[0] + i % 2), 0, CELL, CELL), open[rng.randi() % open.size()] * CELL + off)
	var edge: int = b.size.y * CELL
	img.fill_rect(Rect2i(0, edge, img.get_width(), int(Camera.BOTTOM)), FOREST_FLOOR)
	for row in [14, 26, 40, 56]:  # 마른 나무 네 줄을 뒤에서 앞으로. row는 맵 아래끝에서 밑동까지(px), 그림의 밑동은 (24, 44)
		var x := rng.randf_range(-8.0, 4.0)
		while x < img.get_width():
			if rng.randf() < 0.6:
				img.blend_rect(deco, Rect2i(48 * rng.randi_range(0, 3), 48, 48, 48), Vector2i(int(x) - 24, edge + row + rng.randi_range(-3, 3) - 44))
			x += rng.randf_range(14.0, 24.0)
	if vil.has_area():
		_pave(b, img, rng, plan.pave)
		for c in plan.garden:  # 텃밭: 집 마당 텃밭 그림 두 가지를 번갈아
			img.blend_rect(deco, Rect2i(CELL * ((c.x + c.y) % 2), YARD_ROW, CELL, CELL), c * CELL)
		img.blend_rect(deco, Rect2i(CELL * 7, YARD_ROW, CELL, CELL), _well(b) * CELL + Vector2i(-2, 13))  # 우물 밑 판석
		for c in plan.slabs:  # 자갈 마당: 판석과 자갈 두 가지
			img.blend_rect(deco, Rect2i(CELL * 7, YARD_ROW, CELL, CELL), c * CELL + Vector2i(-2, 2))
		for c in plan.gravel:
			img.blend_rect(deco, Rect2i(CELL * (7 + c.x % 2), 0, CELL, CELL), c * CELL)
		_clusters(b, img, deco)
		_worn(b, img)
		_wall_shade(b, img)
	if not b.water.is_empty():
		var w := WATER.get_image()
		w.convert(img.get_format())
		img.blend_rect(w, Rect2i(Vector2i.ZERO, w.get_size()), WATER_AT)
	for c in (b.spawns if b.spawn_spread == 0 else []):  # 흩어져 나오는 스테이지는 깃발이 없다(I177). ponytail: 깃발도 바닥에 구워서 막 나온 적이 깃발 위에 그려진다. 거슬리면 깃발만 바닥선 정렬로 옮긴다
		img.blend_rect(src, Rect2i(Vector2i(6, 1) * CELL, Vector2i(CELL, CELL)), c * CELL)
	return ImageTexture.create_from_image(img)

# 들판 길(S201)의 흙 꼭짓점. 정문(거점 열)에서 맵 아래끝까지 두 꼭짓점 폭 큰길이고, 성곽 바로 앞 세 줄은 네 꼭짓점 폭이다.
# 다른 출현 지점에서는 한 꼭짓점 폭 오솔길이 여섯 줄 올라간 뒤, 옆으로 두 칸 갈 때마다 한 줄씩 올라 큰길에 닿는다
static func _road(b) -> Dictionary:
	var out := {}
	var gx: int = b.base.cell.x
	var top: int = b.field_y - 1  # 성곽 맨 아랫줄(S217)
	for y in range(top + 1, b.size.y + 1):
		for x in ([gx - 1, gx, gx + 1, gx + 2] if y <= top + 3 else [gx, gx + 1]):
			out[Vector2i(x, y)] = true
	for s in b.spawns:
		if s.x == gx:
			continue
		var dx := 1 if s.x < gx else -1
		var p := Vector2i(s.x if dx > 0 else s.x + 1, b.size.y)
		var start := p.x
		while p.y > b.size.y - 6:
			out[p] = true
			p.y -= 1
		while p.x != (gx if dx > 0 else gx + 1):
			out[p] = true
			p.x += dx
			out[p] = true
			if (p.x - start) % 2 == 0:
				p.y -= 1
				out[p] = true
	return out

# 장식을 놓을 빈 들판 칸(S201): 성곽 아래 둘째 줄부터 맨 아래 줄 전까지(맵 밖 마른 나무가 걸친다), 길 꼭짓점에 닿지 않고 출현 지점 둘레 1칸 밖이다
static func _open_cells(b, road: Dictionary) -> Array:
	var out := []
	for y in range(b.field_y + 1, b.size.y - 1):
		for x in b.size.x:
			var c := Vector2i(x, y)
			if not [c, c + Vector2i.RIGHT, c + Vector2i.DOWN, c + Vector2i.ONE].any(func(v): return road.has(v)) \
					and not b.spawns.any(func(s): return absi(s.x - x) <= 1 and absi(s.y - y) <= 1):
				out.append(c)
	return out

# 바닥 소품: 들판(S201)에는 바위 9·그루터기 6(40×22 들판 기준, 넓이에 비례)을 서로 한 칸 넘게 띄워 빈 들판 칸에, 마을(S202)에는 광장 모서리(_well)에 우물. [칸, decor.png 0행 열]
static func ground_props(b) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	var open := _open_cells(b, _road(b))
	var out := []
	var f := _field_scale(b)
	for k in roundi(15 * f):
		for _try in 50:
			var c: Vector2i = open[rng.randi() % open.size()]
			if out.all(func(p): return absi(p[0].x - c.x) > 1 or absi(p[0].y - c.y) > 1):
				out.append([c, rng.randi_range(0, 2) if k < roundi(9 * f) else rng.randi_range(3, 4)])
				break
	if b.village.has_area():
		out.append([_well(b), 12])
	return out

# 들판 장식 수의 배율: 수는 40×22 들판 기준이고 넓이에 비례한다(S203). 맵이 커져도 같은 밀도로 보인다
static func _field_scale(b) -> float:
	return b.size.x * (b.size.y - b.field_y) / 880.0

# 우물 칸(S202 2026-10-26 둘째 변경): 거점에서 오른쪽 5칸·아래 3칸, 광장 오른쪽 아래 모서리
static func _well(b) -> Vector2i:
	return Folk.well(b)

# 마을 길 골격(S202·S169 2026-10-26 넷째 변경, 사방 성곽): 박석 칸·흙 꼭짓점·텃밭 칸·자갈 마당, 짓지 못하는 길 칸(S43 2026-10-26 둘째 변경).
# 북동 두 고리 사이 블록(44~49열, 13~19행)은 연못, 그 북쪽 45열(4~12행)은 수로의 물 칸(S220)이다. 수로가 성벽 안쪽 길·바깥 고리 길과 만나는 다리 칸은 길 칸이다.
# ponytail: 자리는 거점 (30,30)·맵 60×93인 지금 판(main.gd stage) 하나에 맞춘 칸 값이다. 판이 늘면 거점 칸 기준 상대값으로 옮긴다
static func _plan() -> Dictionary:
	var pave := {}
	var dirt := {}
	var roads := {}
	var spans := {27: [27, 33], 28: [25, 35], 29: [24, 36], 30: [24, 36], 31: [24, 36], 32: [24, 36], 33: [24, 36], 34: [25, 35],  # 거점 광장(시장)
		53: [28, 32], 54: [27, 33], 55: [26, 34], 56: [26, 34],  # 남문 안 공터
		3: [27, 33], 4: [27, 33], 5: [28, 32]}  # 북문 안 공터
	for y in spans:
		for x in range(spans[y][0], spans[y][1] + 1):
			pave[Vector2i(x, y)] = true
	for y in range(28, 33):  # 서문·동문 안 공터
		for x in [3, 4, 55, 56] + ([5, 54] if y >= 29 and y <= 31 else []):
			pave[Vector2i(x, y)] = true
	for y in range(35, 53):  # 남쪽 큰길: 박석-흙-박석
		pave[Vector2i(29, y)] = true
		pave[Vector2i(31, y)] = true
		roads[Vector2i(30, y)] = true
		_cell4(dirt, Vector2i(30, y))
	for l in [[30, 6, 30, 26], [6, 30, 23, 30], [37, 30, 53, 30]]:  # 북·서·동 큰길 칸
		for y in range(l[1], l[3] + 1):
			for x in range(l[0], l[2] + 1):
				roads[Vector2i(x, y)] = true
				_cell4(dirt, Vector2i(x, y))
	for c in pave:
		roads[c] = true
		_cell4(dirt, c)
	for l in [  # 흙 꼭짓점 선 [x0, y0, x1, y1]
			[19, 21, 29, 21], [32, 20, 41, 20], [18, 22, 18, 29], [17, 32, 17, 38],  # 안 고리
			[42, 21, 42, 29], [43, 32, 43, 38], [18, 39, 28, 39], [33, 38, 42, 38],
			[11, 12, 29, 12], [32, 11, 49, 11], [10, 13, 10, 29], [9, 32, 9, 47],  # 바깥 고리
			[50, 12, 50, 29], [51, 32, 51, 47], [10, 48, 28, 48], [33, 47, 50, 47],
			[24, 12, 24, 21], [42, 25, 50, 25], [38, 38, 38, 47], [9, 35, 17, 35],  # 두 고리 사이 골목
			[40, 4, 40, 11], [4, 20, 10, 20], [20, 48, 20, 55], [51, 41, 56, 41],  # 바깥 고리 → 성벽 안쪽 길
			[3, 3, 57, 4], [3, 3, 4, 57], [56, 3, 57, 57], [3, 55, 57, 56]]:  # 성벽 안쪽 길(사방)
		for y in range(l[1], l[3] + 1):
			for x in range(l[0], l[2] + 1):
				dirt[Vector2i(x, y)] = true
	var garden := []
	for y in [5, 6, 7, 8, 49, 50, 51, 52]:  # 네 모서리 텃밭
		for x in [5, 6, 7, 8, 51, 52, 53, 54]:
			garden.append(Vector2i(x, y))
	for g in [[13, 6, 18, 7, 14, 17], [12, 15, 16, 16, 13, 15], [11, 40, 15, 41, 12, 14], [45, 40, 49, 41, 46, 48], [22, 50, 26, 51, 23, 25]]:  # 빈 블록 텃밭 북서·서·남서·남동·남: 사각형 [x0, y0, x1, y1] 아래에 짧은 줄 [x0, x1]
		for y in range(g[1], g[3] + 1):
			for x in range(g[0], g[2] + 1):
				garden.append(Vector2i(x, y))
		for x in range(g[4], g[5] + 1):
			garden.append(Vector2i(x, g[3] + 1))
	for c in garden:
		_cell4(dirt, c)
	var slabs := [Vector2i(34, 7), Vector2i(35, 7), Vector2i(35, 8), Vector2i(39, 50), Vector2i(40, 51)]  # 자갈 마당(북·남동 블록)
	var gravel := [Vector2i(33, 8), Vector2i(36, 6), Vector2i(37, 8), Vector2i(41, 50), Vector2i(38, 51)]
	var water := {}
	for y in [4, 5, 6, 7, 8, 9, 12]:  # 수로. 3행은 박석 덮개, 10·11행은 나무 다리
		water[Vector2i(45, y)] = true
	for y in range(13, 20):  # 연못
		for x in range(44, 50):
			water[Vector2i(x, y)] = true
	for c in [Vector2i(45, 3), Vector2i(45, 10), Vector2i(45, 11)]:  # 다리 칸: 집이 다리를 막지 못하게 길 칸으로 둔다
		roads[c] = true
	return {"pave": pave, "dirt": dirt, "garden": garden, "slabs": slabs, "gravel": gravel, "roads": roads, "water": water}

# 사방 성곽 안쪽 그늘(S219). 동·서 성벽은 마을 쪽에 남벽 앞면 벽돌색 벽면 띠 6px(원근 속임)과 그 바깥 땅 그늘 3px을, 통로처럼 24px 올린 자리에 그린다.
# 닫힌 문루 행은 그 높이만큼 더 올리고 띠 자리에 나무 문짝을 넣는다. 남벽 통로 뒤 모서리 위 마을 땅에는 4px 그늘을, 정문 문루 뒤(박석 길 위)에는 터널 입구 그늘을 깐다.
# 사방 성곽(마을이 맵 가장자리에서 떨어진 판)에서만 그린다
static func _wall_shade(b, img: Image) -> void:
	var v: Rect2i = b.village
	if v.position.x < 3:
		return
	var face := [Color("56607a"), Color("3a4357"), Color("151a26")]  # 앞면·줄눈·외곽(walls.png 남벽 앞면 색)
	for west in [true, false]:
		var xe: int = v.position.x * CELL if west else v.end.x * CELL - 1  # 띠가 시작하는 마을 쪽 경계 픽셀
		var d := 1 if west else -1
		for y in range(v.position.y * CELL - WALL_H, v.end.y * CELL - WALL_H):
			var gate: bool = y >= (b.base.cell.y - 1) * CELL - WALL_H - SIDE_GATE_RISE and y < (b.base.cell.y + 2) * CELL - WALL_H  # 문루 행(거점 줄 ±1)
			for k in 6:
				var c: Color = face[1] if y % 4 == 0 or (k + (y / 4 % 2) * 3) % 6 == 0 else face[0]
				if k == 5:
					c = face[2]
				if gate and k >= 1 and k <= 4 and y >= (b.base.cell.y + 2) * CELL - WALL_H - 30:  # 문짝: 나무 2px + 테두리
					c = Color("6b3f22") if k == 2 or k == 3 else face[2]
				img.set_pixel(xe + d * k, y, c)
			for k in 3:
				var x := xe + d * (6 + k)
				img.set_pixel(x, y, img.get_pixel(x, y).darkened(0.3 * (1.0 - k / 3.0)))
	var y1 := v.end.y * CELL - WALL_H  # 남벽 통로 뒤 모서리
	for x in range(v.position.x * CELL, v.end.x * CELL):
		for k in 4:
			img.set_pixel(x, y1 - 1 - k, img.get_pixel(x, y1 - 1 - k).darkened(0.26 * (1.0 - k / 4.0)))
	var gx: int = b.base.cell.x * CELL + CELL / 2  # 정문 문루 가운데(거점 열)
	var gy := y1 - GATE_RISE  # 문루 뒤 모서리
	for y in range(gy - 10, gy):
		for x in range(gx - 20, gx + 21):
			var t := float(gy - y) / 10.0 + pow(float(x - gx) / 20.0, 2.0)  # 아래가 넓은 반타원
			if t < 1.0:
				img.set_pixel(x, y, img.get_pixel(x, y).darkened(0.45 * (1.0 - t)))

# 시험 스테이지의 길 칸(S43 2026-10-26 변경). main.gd stage가 읽는다
static func roads() -> Dictionary:
	return _plan().roads

# 시험 스테이지의 물 칸(S220). main.gd stage가 읽는다
static func water() -> Dictionary:
	return _plan().water

# 시험 스테이지의 텃밭 칸(I182 ⑥). main.gd stage가 읽는다
static func garden() -> Array:
	return _plan().garden

# 시험 스테이지의 자갈 마당 칸(I182 ⑥). main.gd stage가 읽는다
static func yards() -> Array:
	var plan := _plan()
	return plan.slabs + plan.gravel

# 칸 c의 네 꼭짓점을 d에 넣는다
static func _cell4(d: Dictionary, c: Vector2i) -> void:
	for k in 4:
		d[c + Vector2i(k % 2, k / 2)] = true

static var _vtiles: Image
# 마을 칸 타일: 흙 타일의 어두운 점 2/3를 흙색으로 지운 사본(S202). 픽셀마다 지우면 큰 마을(S203)에서 느려 타일에서 한 번 지운다. 터(bake_yard)도 이 흙을 쓴다
static func _village_tiles() -> Image:
	if _vtiles == null:
		_vtiles = GROUND_TILES.get_image()
		var vrng := RandomNumberGenerator.new()
		vrng.seed = 3
		for y in _vtiles.get_height():
			for x in _vtiles.get_width():
				if _vtiles.get_pixel(x, y).is_equal_approx(Color("392a1c")) and vrng.randf() < 0.67:
					_vtiles.set_pixel(x, y, Color("684c3c"))
	return _vtiles

# 풀꽃 무더기(S202 2026-10-26 둘째·넷째 변경): 작은 풀·자갈·풀꽃을 성벽 밑 띠·광장 양 가장자리·갈림목·우물 둘레에 무더기로 모으고 넓은 안쪽은 비운다
static func _clusters(b, img: Image, deco: Image) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 11
	var y1: int = b.village.end.y * CELL
	var cx: int = b.base.cell.x * CELL + CELL / 2
	var spots := []
	var x := r.randi_range(1, 4)
	while x < b.size.x - 1:  # 남벽 밑 띠: 성벽 안쪽 길 위끝 둘레. 정문 안 공터와 모서리 텃밭은 비운다
		if absi(x - b.base.cell.x) > 6 and x > 5 and x < 54:
			spots.append(Vector2(x * CELL + 8, r.randf_range(y1 - 76, y1 - 60)))
		x += r.randi_range(5, 9)
	for side in [-1, 1]:  # 광장 양 가장자리: 광장 반폭 104px(6.5칸)보다 8~18px 바깥
		for y in [28, 33]:
			spots.append(Vector2(cx + side * r.randf_range(112, 122), y * CELL + r.randf_range(-6, 6)))
	for c in [Vector2i(24, 12), Vector2i(42, 25), Vector2i(38, 38), Vector2i(9, 35), Vector2i(18, 22), Vector2i(43, 33), Vector2i(10, 28), Vector2i(50, 32), Vector2i(40, 5), Vector2i(20, 54)]:  # 고리 길·골목 갈림목(_plan)
		spots.append(Vector2(c * CELL) + Vector2(12, 4))
	spots.append(Vector2(_well(b) * CELL) + Vector2(18, 4))
	spots.append(Vector2(_well(b) * CELL) + Vector2(-4, 10))
	for s in spots:
		for k in r.randi_range(3, 5):  # 한 무더기 3~5포기. 70%는 작은 풀·자갈, 나머지는 풀꽃
			var c := r.randi_range(7, 10) if r.randf() < 0.7 else 11
			img.blend_rect(deco, Rect2i(CELL * c, 0, CELL, CELL), Vector2i(s) - Vector2i(8, 8) + Vector2i(r.randi_range(-7, 7), r.randi_range(-4, 4)))

# 2026-10-26
# [동작] 성 안 풀(성곽 위 세 줄 위)에서 잡음 가중치 w = clamp(잡음 × 2, 0, 1)인 자리의 풀 바탕 픽셀을 w × 14%는 짙은 갈색, w × 8%는 흙색으로 바꾼다
# [의도] 성 안 풀을 덩어리진 자리만 바래게 해 성 밖 들판 풀과 가른다
# [이유] Gemini가 시안 B에서 «성 안팎 풀색이 같다»를 고칠 점으로 꼽았고, 고르게 흩은 첫 B′는 확대하면 자글자글해서 덩어리로 바꿨다.
#        사용자가 이 B′를 골랐다(insights/2026-10-25_village_research_mockup.md)
static func _worn(b, img: Image) -> void:
	var nz := FastNoiseLite.new()
	nz.seed = 5
	nz.frequency = 0.04
	var r := RandomNumberGenerator.new()
	r.seed = 21
	var g := Color("2d472d")
	for y in range(b.village.position.y * CELL, (b.village.end.y - 3) * CELL):
		for x in range(b.village.position.x * CELL, b.village.end.x * CELL):
			if img.get_pixel(x, y).is_equal_approx(g):
				var w := clampf(nz.get_noise_2d(x, y) * 2.0, 0.0, 1.0)
				var k := r.randf()
				if k < 0.14 * w:
					img.set_pixel(x, y, Color("392a1c"))
				elif k < 0.22 * w:
					img.set_pixel(x, y, Color("684c3c"))

# 시설 터(S215): 차지 칸(S216) 가운데보다 3px 아래를 중심으로 한 타원 얼룩에 흙 타일 무늬를 깐다. 가장자리는 칸마다 씨앗이 다른 잡음으로 흔들고,
# 거리 0.85~1.15 띠는 바깥으로 갈수록 성기게 풀과 섞는다. 외곽선은 없다. 바닥(under)의 박석 위·물 칸(S220)과 성벽 그늘 줄부터 아래에는 깔지 않는다. [그림, 맵 px 왼쪽 위]
static func bake_yard(b, s, under: Image) -> Array:
	var r: Rect2i = b.area_of(s)
	var center := (Vector2(r.position) + Vector2(r.size) / 2.0) * CELL + Vector2(0, 3)
	var radius := yard_radius(s)
	var blobs := [[center, radius]]
	if s.kind == "archery":
		blobs.append([center + Vector2(0, radius.y + 10), Vector2(8, 22)])  # 터 아래끝에서 아래로 난 밟힌 줄
	var box := Rect2i(Vector2i(center), Vector2i.ZERO)
	for bl in blobs:
		box = box.merge(Rect2i(Vector2i(bl[0] - bl[1]) - Vector2i(8, 8), Vector2i(bl[1] * 2) + Vector2i(17, 17)))
	box = box.intersection(Rect2i(0, 0, under.get_width(), b.village.end.y * CELL - 27))
	var nz := FastNoiseLite.new()
	nz.seed = s.cell.x * 31 + s.cell.y
	nz.frequency = 0.1
	var tile := _village_tiles().get_region(Rect2i(Vector2i(15, 0) * CELL, Vector2i(CELL, CELL)))  # 흙 한 가지 칸(16꼴의 15)
	var img := Image.create_empty(box.size.x, box.size.y, false, Image.FORMAT_RGBA8)
	for y in range(box.position.y, box.end.y):
		for x in range(box.position.x, box.end.x):
			if under.get_pixel(x, y).is_equal_approx(PAVE) or b.water.has(Vector2i(x, y) / CELL):
				continue
			var h := fposmod(sin(x * 12.9898 + y * 78.233) * 43758.5453, 1.0)
			for bl in blobs:
				var d: float = pow((x + 0.5 - bl[0].x) / bl[1].x, 2) + pow((y + 0.5 - bl[0].y) / bl[1].y, 2) - nz.get_noise_2d(x, y) * 0.5
				if d < 0.85 or d < 1.15 and h < (1.15 - d) / 0.3:
					img.set_pixel(x - box.position.x, y - box.position.y, tile.get_pixel(posmod(x, CELL), posmod(y, CELL)))
					break
	return [ImageTexture.create_from_image(img), Vector2(box.position)]

# 놓기 미리보기(S216): [커서 칸을 구조물의 칸으로 한 차지 칸, 지을 수 있나]
static func ghost(b, kind: String, cell: Vector2i) -> Array:
	return [b.area_at(cell, b.STRUCTURE_KINDS[kind].size), b.can_build(kind, cell)]

# 터 반지름(S215 2026-10-26 변경): (가로 칸 × 8 + 18 + 종류 보탬, 깊이 칸 × 8 + 12)px
static func yard_radius(s) -> Vector2:
	return Vector2(s.size.x * 8 + 18 + YARDS[s.kind], s.size.y * 8 + 12)

# 다 지은 시설의 마당 소품(S215): [decor.png 3행 열, 맵 px 왼쪽 위]. 짓는 중이면 없다
static func yard_props(s) -> Array:
	if not s.complete or not YARD_PROPS.has(s.kind):
		return []
	var v: Array = YARD_PROPS[s.kind]
	return v[(s.cell.x + s.cell.y) % v.size()].map(func(p): return [p[0], Vector2(s.cell * CELL) + p[1]])

# 마을 박석(S202 2026-10-26 둘째 변경): 박석 칸(_plan의 광장·남쪽 큰길·정문 안 공터)에만 깐다. 성벽 그림 위끝(성곽 줄 위끝에서 27px 위)
# 아래는 성벽 그림이 덮는다. 성벽 그림 바로 위 2px은 흙 1px과 그늘 1px로 남겨 성벽과 가른다.
# 2026-10-23
# [동작] 9×7px 격자를 흔든 점마다 박석 하나(보로노이). 점이 박석 칸 안인 돌만 통째로 깔고, 줄눈은 칠하지 않아 흙이 비친다
# [의도] 돌길·광장이 성벽의 일부나 높은 기단으로 읽히지 않게 한다
# [이유] Gemini가 5×4px 엇갈린 벽돌과 밝은 돌을 성벽과 같은 쌓은 벽돌로 읽었고, 사용자가 시안 «조합 1a + 2 + 3a»를 골랐다(insights/2026-10-23_village_decor.md)
static func _pave(b, img: Image, rng: RandomNumberGenerator, cells: Dictionary) -> void:
	var w := img.get_width()
	var y1: int = b.village.end.y * CELL
	var rows := y1 - 27  # 줄눈 판정에 아래 한 줄이 필요해서, 칠할 줄보다 한 줄 더 돌 번호를 매긴다
	var near := {}  # 박석 칸과 그 둘레 한 칸만 센다. 점이 칸 밖인 돌은 어차피 깔지 않는다
	for c in cells:
		for k in 9:
			near[c + Vector2i(k % 3 - 1, k / 3 - 1)] = true
	var gw := w / 9 + 3
	var gh := rows / 7 + 3
	var pts := []
	for j in gh:
		for i in gw:
			pts.append(Vector2(i * 9 + rng.randf_range(1.5, 7.5), j * 7 + rng.randf_range(1.0, 6.0)))
	var id := PackedInt32Array()
	id.resize(w * rows)
	for y in rows:
		for x in w:
			if not near.has(Vector2i(x / CELL, y / CELL)):
				continue
			var best := INF
			for j in range(maxi(y / 7 - 1, 0), mini(y / 7 + 2, gh)):
				for i in range(maxi(x / 9 - 1, 0), mini(x / 9 + 2, gw)):
					var d: float = pts[j * gw + i].distance_squared_to(Vector2(x + 0.5, y + 0.5))
					if d < best:
						best = d
						id[y * w + x] = j * gw + i
	for y in rows - 1:
		for x in w:
			if not near.has(Vector2i(x / CELL, y / CELL)):
				continue
			var k := id[y * w + x]
			var p: Vector2 = pts[k]
			if cells.has(Vector2i(int(p.x) / CELL, int(p.y) / CELL)) and (x == w - 1 or id[y * w + x + 1] == k) and id[(y + 1) * w + x] == k:
				img.set_pixel(x, y, PAVE)
	img.fill_rect(Rect2i(0, y1 - 27, w, 1), Color("392a1c"))

# 장판 안쪽 무늬(S168). 색이 비슷한 장판 쌍(블랙홀·늪, 화살비·독안개, 황금률·성역)을 무늬로 가른다. 무늬는 원 안에만 그린다.
# 2026-10-27: 아트 1px 선으로 그린다(S168 «맵 1px»). 10/25 맵을 창 해상도로 그린 뒤(S30) 굵기 없는 선이 화면 1px가 됐었다. 이그니스(4.1s)·실비아(fx-2) 장판은 재질이라 무늬가 없다
func _pattern(src: String, c: Vector2, r: float, col: Color) -> void:
	match src:
		"vesper_r":  # 늪: 물결 가로줄 4줄
			for k in 4:
				var y := (k - 1.5) * r / 2.5
				var half := sqrt(maxf(r * r - y * y, 0.0)) - 3.0
				var x := -half
				while x + 2.0 <= half:
					_pline(Vector2i((c + Vector2(x, y + 2.0 * sin(x * TAU / 8.0))).floor()), Vector2i((c + Vector2(x + 2.0, y + 2.0 * sin((x + 2.0) * TAU / 8.0))).floor()), col)
					x += 2.0
		"vesper_q":  # 독안개: 흩어진 거품(6px 격자)
			for p in _grid(c, r - 3.0, 6.0):
				_pring(Vector2i(p.floor()), 1, 1, col)
		"chronos_e":  # 황금률: 햇살 12줄
			for k in 12:
				var d := Vector2.from_angle(k * TAU / 12.0)
				_pline(Vector2i((c + d * r * 0.25).floor()), Vector2i((c + d * r * 0.9).floor()), col)
		"seraphina_w":  # 성역: 큰 십자
			_pline(Vector2i((c - Vector2(0, r * 0.8)).floor()), Vector2i((c + Vector2(0, r * 0.8)).floor()), col, 2)
			_pline(Vector2i((c + Vector2(-r * 0.5, -r * 0.3)).floor()), Vector2i((c + Vector2(r * 0.5, -r * 0.3)).floor()), col, 2)
		"chronos_r":  # 왜곡장: 안쪽 점선 고리 둘
			for rr in [r * 0.6, r * 0.3]:
				_pring(Vector2i(c.floor()), int(rr), 1, col, 2)

# 가운데 c에서 step 간격 격자점 가운데 반경 r 안의 점
static func _grid(c: Vector2, r: float, step: float) -> Array:
	var out := []
	var n := int(r / step)
	for i in range(-n, n + 1):
		for j in range(-n, n + 1):
			if Vector2(i, j).length() * step <= r:
				out.append(c + Vector2(i, j) * step)
	return out

# 화면 방향 v(y가 아래)의 시트 행: S, SE, E, NE, N, NW, W, SW(tools/art/render.py DIRS)
static func _dir_of(v: Vector2) -> int:
	return posmod(roundi((90.0 - rad_to_deg(v.angle())) / 45.0), 8)

# 조준 중(S147): 영웅 둘레에 시전 사거리, 커서에 범위(지점·범위), 영웅에서 커서 쪽으로 길이(방향)나 부채꼴(아이아스 Q), 에너지 성벽이 설 칸
func _aim_preview() -> void:
	if controls.aiming == "" or not controls.aim_hero:
		return
	var h = controls.aim_hero
	var sk: Dictionary = h.get(controls.aiming)
	var at: Vector2 = controls.mouse / CELL - Vector2(0.5, 0.5)
	_cv.draw_arc(_center(h.pos), CELL * battle.CAST_RANGE, 0.0, TAU, 64, Color(1, 1, 1, 0.3), 1.0)
	match sk.aim:
		"dir":
			var d: Vector2 = battle._toward(h, at)
			if sk.has("arc"):  # 아이아스 Q: 반경 radius·각도 arc의 부채꼴(S151)
				var half := deg_to_rad(sk.arc) / 2.0
				_cv.draw_arc(_center(h.pos), CELL * sk.radius, d.angle() - half, d.angle() + half, 24, Color.WHITE, 1.0)
				for side in [-half, half]:
					_cv.draw_line(_center(h.pos), _center(h.pos + d.rotated(side) * sk.radius), Color.WHITE, 1.0)
			else:
				_cv.draw_line(_center(h.pos), _center(h.pos + d * sk.get("radius", 40.0)), Color.WHITE, 1.0)  # 실비아 Q는 맵 끝까지
		"point":
			if sk.id == "bulwark":
				var d: Vector2 = battle._toward(h, at)
				var side := Vector2i(0, 1) if absf(d.x) > absf(d.y) else Vector2i(1, 0)
				for i in range(-1, 2):
					_cv.draw_rect(_rect(Vector2i(at.round()) + side * i), Color.WHITE, false, 1.0)
			else:
				_cv.draw_arc(_center(at), CELL * sk.get("radius", 0.5), 0.0, TAU, 48, Color.WHITE, 1.0)
		_:
			_cv.draw_arc(_center(at), CELL * 0.7, 0.0, TAU, 24, Color.WHITE, 1.0)

# at: 칸 단위 위치(칸 (x,y)의 중심 = Vector2(x,y)). 그 칸 위쪽 가운데에 그린다. tiers면 구조물·성곽·거점 막대의 3단 색(S199)
func _hp_bar(at: Vector2, b, size := Vector2(CELL, 2), tiers := false) -> void:
	var bar := Rect2(at * CELL + Vector2((CELL - size.x) / 2, -2 - size.y), size)
	_cv.draw_rect(bar, Color.BLACK)
	_cv.draw_rect(Rect2(bar.position, Vector2(size.x * b.hp / b.max_hp, size.y)), bar_color(b, tiers))

# 체력 막대 색(S73, S199): 구조물·성곽·거점(tiers)은 50% 밑 노랑·25% 밑 빨강, 영웅·용병·적·보스는 늘 초록
static func bar_color(b, tiers: bool) -> Color:
	if not tiers:
		return Color.GREEN
	var r: float = b.hp / b.max_hp
	return BAR_TIERS[0] if r < 0.25 else BAR_TIERS[1] if r < 0.5 else BAR_TIERS[2]

# 금 구운 아틀라스(S199, I172): 원본 아래에 금 단계 1~3 × 무늬 0·1 사본 여섯을 그 차례로 잇는다(crack_y가 고르는 행).
# pieces는 금을 긋는 원본 조각 사각형이다. 조각마다 금 i(0~2)는 무늬와 i만으로 정해, 단계가 오르면 앞 금은 그대로 두고 한 줄을 더한다
static func crack_atlas(tex: Texture2D, pieces: Array) -> ImageTexture:
	var src := tex.get_image()
	src.convert(Image.FORMAT_RGBA8)
	var h := src.get_height()
	var img := Image.create_empty(src.get_width(), h * 7, false, Image.FORMAT_RGBA8)
	for v in 7:
		img.blit_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i(0, h * v))
	for r in pieces:
		var spans := {}  # 불투명한 열 x → [맨 위 y, 맨 아래 y]. 6px보다 짧은 열은 뺀다
		for x in range(r.position.x + 1, r.end.x - 2):
			var top: int = r.position.y
			while top < r.end.y and src.get_pixel(x, top).a < 0.5:
				top += 1
			var bot: int = r.end.y - 1
			while bot > top and src.get_pixel(x, bot).a < 0.5:
				bot -= 1
			if bot - top >= 6:
				spans[x] = [top, bot]
		if spans.is_empty():
			continue
		var xs: Array = spans.keys()
		for v in 6:
			var n: int = r.position.x * 977 + r.position.y * 31 + (v % 2) * 7919
			for i in v / 2 + 1:  # 금 i는 불투명한 열의 3할·7할·5할 언저리에서, 그 열 아래쪽 절반에서 아래로 7~11px
				var x: int = xs[clampi(int(xs.size() * [0.3, 0.7, 0.5][i]) + _h(n, i, -1, 1), 0, xs.size() - 1)]
				var y: int = spans[x][0] + (spans[x][1] - spans[x][0]) * _h(n, 10 + i, 50, 70) / 100
				for j in _h(n, 20 + i, 7, 11):
					if j > 0:
						x = clampi(x + _h(n, 30 + 16 * i + j, -1, 1), r.position.x, r.end.x - 2)
					if y + j >= r.end.y:
						break
					var c := src.get_pixel(x, y + j)
					if c.a >= 0.5:  # 어두운 1px 줄과 그 오른쪽 밝은 1px 가장자리. 그림 밖(투명)에는 긋지 않는다
						img.set_pixel(x, y + j + h * (v + 1), c.darkened(0.6))
						var e := src.get_pixel(x + 1, y + j)
						if e.a >= 0.5:
							img.set_pixel(x + 1, y + j + h * (v + 1), e.lightened(0.35))
	return ImageTexture.create_from_image(img)

# 금을 긋는 성곽 조각(S199): 단계 1~3의 앞층 행(바깥 벽면)에서 조각 열마다. 모서리 탑은 칸마다 잘라 그리므로 16px씩
static func _wall_pieces() -> Array:
	var out := []
	for name in WALL_COLS:
		var c: Array = WALL_COLS[name]
		var w: int = CELL if name.begins_with("sc_") or name.begins_with("nc_") else c[1]
		for x in range(c[0], c[0] + c[1], w):
			for row in [1, 3, 5]:
				out.append(Rect2i(x, row * WALL_PIECE_H, w, WALL_PIECE_H))
	return out

# 거점 망루 그림의 불투명 사각형(맵 px). 이 안을 누르면 거점을 고른다(S100)
static func keep_rect(b) -> Rect2:
	var body: Rect2 = KEEP_BODY[clampi(b.village_level, 1, 2) - 1]
	return Rect2(Vector2(b.base.cell * CELL) + KEEP_AT + body.position, body.size)

# 유닛·적 체력바 자리(칸): 성벽 위와 미끄러짐을 따른다. 보스(I185) 그림은 기본 적보다 키가 커서 막대를 그만큼 올린다(머리 위).
# 줄어들고 늘고 뜬 보스 그림(S198 2026-10-27 둘째 변경)은 그린 그림의 머리를 따른다
func hp_bar_at(u) -> Vector2:
	var head := 0.0
	if u.get("boss") and ART.has(u.kind):
		var lk := _look(u)
		head = (ART[u.kind].anchor[1] * lk[0].y + lk[1] - ART.basic.anchor[1]) / CELL
	return u.pos - Vector2(0, _lift(u) / CELL + head) + _slip(u) / CELL

# 유닛·적 체력바 크기(S73). 보스(I185 boss 칸)는 V 표시와 상관없이 늘 크게, 나머지는 켰을 때만. 그리지 않으면 Vector2.ZERO
static func hp_bar_size(u, show_all: bool) -> Vector2:
	if u.get("boss"):
		return Vector2(24, 3)
	return Vector2(CELL, 2) if show_all else Vector2.ZERO

# 주민(S223·S225~S229)의 일과·자리는 판(src/sim/folk.gd)이 구하고, 화면은 판의 people을 그린다
const PROPS := preload("res://art/tiles/props.png")  # 일터 소품(S224, tools/art/props.py)
const PROP_ART := {"mill": Rect2(0, 0, 24, 28), "wheel": Rect2(24, 0, 16, 16), "oven": Rect2(88, 0, 16, 16), "stall0": Rect2(104, 0, 16, 16),
	"stall1": Rect2(120, 0, 16, 16), "inn": Rect2(136, 0, 10, 12)}  # props.png 안 자리. 바퀴는 오른쪽으로 네 장
const PROP_AT := {"mill": Vector2(-4, -12), "wheel": Vector2.ZERO, "oven": Vector2.ZERO, "stall0": Vector2(0, -4), "stall1": Vector2(0, -4),
	"inn": Vector2(26, -10)}  # 소품 칸(여관은 집의 칸) 왼쪽 위에서 그림 왼쪽 위까지(px). 방앗간은 수로 칸 (45,5) 위로 솟고, 바퀴는 그 아래 (45,6) 물 위다
const PROP_WHEEL_FPS := 4.0  # 물레방아 바퀴 네 장을 넘기는 빠르기(장/초)
const LAMP := Vector2(3, -6)  # 야경꾼 발밑에서 등불까지(px)

# 평가가 부르는 주민 일과(Folk 그대로): t초 때 자리 · 하는 일 · 주민 차례 · 고정 소품
static func residents(b, t: float) -> Array:
	return Folk.residents(b, t)

static func chores(b, t: float) -> Array:
	return Folk.chores(b, t)

static func folk_of(b) -> Array:
	return Folk.folk_of(b)

static func props(b) -> Dictionary:
	return Folk.props(b)

# 유닛·적은 pos, 구조물·성곽·거점은 cell로 자리를 갖는다
func _pos_of(x) -> Vector2:
	var p = x.get("pos")
	return p if p != null else Vector2(x.cell)

func _center(p: Vector2) -> Vector2:
	return p * CELL + Vector2(CELL, CELL) / 2

func _rect(c: Vector2i) -> Rect2:
	return Rect2(Vector2(c) * CELL, Vector2(CELL, CELL))

# 오라 반경 원(S113). 크로노스는 원 안쪽에 시계 문자판 눈금 12개를 더 그린다(S160). 컨셉 아트의 광륜(등 뒤 천문시계 고리)은
# 24px 스프라이트에서 뺐고 여기서 이펙트로 살린다(I152). 눈금은 크로노스 색(금)이고 12·3·6·9시가 길다. 불투명도 0.5·짧은 눈금 3px는
# 들판 위에서 흐리고 대각 눈금이 점으로 보였다. 원은 다른 영웅과 같은 하늘색이다. 금색으로 하면 반경이 같은 E 결계(S158 황금의 율법)와 테두리가 겹친다
# 2026-10-27: 원은 아트 px 점선(3px 간격, F24+ 하늘색 계열 a4aec2), 눈금은 아트 px 선(F24+ 금 efac28)이다(4.1s, S113 변경)
func _aura_ring(h) -> void:
	var c := Vector2i(_center(h.pos).floor())
	var r := int(CELL * h.aura.radius)
	_pring(c, r, 1, PX.ice1, 3)
	if h.kind != "chronos":
		return
	for k in 12:  # k = 0이 3시. 화면 y가 아래라 k가 늘면 시계 방향으로 돈다
		var d := Vector2.from_angle(k * TAU / 12)
		_pline(c + Vector2i((d * r).round()), c + Vector2i((d * (r - (7.0 if k % 3 == 0 else 4.0))).round()), PX.gold)
