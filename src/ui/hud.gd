extends CanvasLayer
# 위 띠(S185)의 정해진 자리에 상태 묶음(거점 체력·마을 레벨·골드·세금·라운드, S190)·임무 칸(I122)·공병 칸·출전 영웅 칸(I129)·진행 칸(«전투 시작»·계기판 I13, 다음 웨이브 S188)·메뉴 칸을 두고,
# 건설 격자(S186, hud_build.gd)와 토스트(I163, hud_toast.gd)와 라운드를 이기거나 도전이 끝난 뒤의 결과 창(S117)을 둔다.
# 판매 후보가 있으면 그 옆에 판매 버튼을 띄운다(S70, I58). 전투 단계에 생산 시설을 고르면 그 옆에 파는 용병마다 구매 버튼을 띄운다(S81, I61, I71).
# 고른 구조물에 따라 같은 자리에 철거(S74)·이어 짓기·취소(전투 단계, live 판의 준비 단계)와 완성(live가 아닌 준비 단계) 버튼도 띄운다(S83, I175). 대포면 옮기기(S91)도 띄운다.
# 성곽 칸을 고르면 같은 자리에 성문 열기·닫기(S85)와 업그레이드(S86) 버튼을 띄운다. 거점을 고르면 마을 레벨 올리기(S100) 버튼을 띄운다.
# 고른 것 가운데 깎인 것이 있으면 수리(S116, I90), 잔해를 고르면 복구(I89) 버튼도 같은 자리에 띄운다.
# 영입 창(도전 시작 전 S122·라운드 사이 S117)이면 결과 창 안에 영입 칸을 띄운다: 목록 영입·리롤·출전 전환·내보내기(S54, I110),
# 보유 영웅의 레벨·경험치(I117), 라운드 사이의 경험치 이관(S127, I116), 라운드 사이의 의뢰 목록과 수락(S77, I121).
# 준비·전투 단계에는 임무 칸에 미션·수락한 의뢰의 점을 보이고, 라운드 첫 준비 단계와 조건이 깨질 때 토스트를 띄운다. 결과 창에 지난 라운드의 달성·실패를 보인다(I122).
# 결과 창의 버튼만 키보드 포커스를 받는다. 창이 열리면 «1라운드 시작»·«다음 라운드»·«새 도전»에 포커스가 간다(I12, I110)
# 출전 영웅 칸마다 초상(누르면 고르기, 두 번이면 카메라, I165)·그림 상태 스킬 칸(좌클릭은 쓰기, 우클릭은 자동 시전, I151, skill_cell.gd)·체력·마나 막대와 쓰러짐(I129)을,
# 화면 오른쪽 가장자리에 고른 영웅·용병의 공격 이동·정지 태그와, 용병을 골랐으면 홀드 태그(그림이 상태, 상태 글은 툴팁)를 보인다(I139).
# 맵 위 팝업은 고른 칸의 바깥쪽 모서리에 HUD 사각형을 피해 뜨고(I58, I137), 버튼 줄은 정해져 있다. 철거는 두 번 눌러 확정한다(S74).
# 눌리지 않는 팝업 버튼은 어둡게 하고 이유는 툴팁·정보 칸의 빨간 줄이다(I123, I124, I128, I140). 놓기 중 닿는 공병이 없는 칸은 빨간 ✕와 안내 줄(I128)
# 위 띠의 조작과 팝업 버튼에는 툴팁을 단다(S187, I162). 테마는 hud_theme.gd
# 준비 단계에 화면 밖 출현 지점은 아래 가장자리에 그 지점 적 수 표식을 둔다(S188)
# 준비 단계 왼쪽 아래에 처음 하는 사람 힌트를 둔다(S191, hints.gd)
# 준비·전투 단계 왼쪽 아래 구석에 미니맵을 둔다(S209, hud_minimap.gd)

const NAMES := {"wall": "방벽", "tower": "타워", "magic": "마법 타워", "soldier": "용병", "barracks": "병영", "engineer": "공병", "workshop": "작업장", "archer": "궁수", "cannon": "대포", "archery": "사격장", "house": "집", "church": "교회", "shelter": "대피소"}
const HEROES := {"aias": "아이아스(탱커)", "sylvia": "실비아(원거리)", "seraphina": "세라피나(힐러)", "vesper": "베스퍼(디버퍼)", "ignis": "이그니스(마법사)", "chronos": "크로노스(버퍼)"}  # 이름(역할), S97·S157
const GRADES := ["1성", "2성", "3성"]  # S94
const GAPS := {"none": "공병 없음", "far": "닿는 공병 없음"}  # 공병 지시를 맡을 공병이 없는 이유(I128). 툴팁·정보 칸의 빨간 줄(✕는 그 줄이 붙인다)
const SKILLS := {  # 영웅마다 Q·W·E·R의 [이름, 요약](S97 표). 툴팁(S187)이 쓴다
	"aias": [["방패 강타", "부채꼴 기절"], ["전장의 포효", "도발·보호막"], ["반격의 태세", "감소 뒤 충격파"], ["절대 방어선", "에너지 성벽"]],
	"sylvia": [["관통의 바람살", "직선 관통"], ["돌풍 갈래살", "토글 4명 사격"], ["폭풍의 덫", "속박·치명타"], ["천공의 화살비", "처형"]],
	"seraphina": [["성스러운 빛줄기", "회복·피해 도약"], ["정화의 성역", "회복 장판"], ["수호 천사의 날개", "불사"], ["기적의 강림", "전체 회복·축복"]],
	"vesper": [["부식의 독안개", "방어력 −10"], ["쇠약의 저주", "둔화·공격력 감소"], ["영혼 사슬", "피해 나누기"], ["심연의 늪", "봉인"]],
	"ignis": [["화염구 작렬", "발화"], ["서리 고리", "열충격 빙결"], ["비전 블랙홀", "끌어당김"], ["메테오 스웜", "운석·용암"]],
	"chronos": [["무기 과충전", "자동 시전"], ["시간 되감기", "마나·대기"], ["황금의 율법", "골드 +30%"], ["시간 왜곡장", "가속·감속"]],
}
const HudTheme := preload("res://src/ui/hud_theme.gd")
const HudTip := preload("res://src/ui/hud_tip.gd")
const HudBuild := preload("res://src/ui/hud_build.gd")
const HudSelect := preload("res://src/ui/hud_select.gd")
const HudMinimap := preload("res://src/ui/hud_minimap.gd")
const HudToast := preload("res://src/ui/hud_toast.gd")
const HudAlert := preload("res://src/ui/hud_alert.gd")
const HudEvac := preload("res://src/ui/hud_evac.gd")
const Hints := preload("res://src/ui/hints.gd")
const BattleView := preload("res://src/ui/battle_view.gd")
const SkillCell := preload("res://src/ui/skill_cell.gd")
const BAR := {  # 위 띠 칸 자리(S185, 임시값)
	"status": Rect2(4, 2, 96, 24), "mission": Rect2(104, 2, 24, 24), "engineer": Rect2(130, 2, 20, 24),
	"hero0": Rect2(156, 2, 104, 24), "hero1": Rect2(264, 2, 104, 24), "hero2": Rect2(372, 2, 104, 24),
	"progress": Rect2(480, 2, 136, 24), "menu": Rect2(620, 2, 16, 24)}
const FLASH := 0.2  # 거점이 맞으면 체력 막대가 하얗게 번쩍이는 초(S190 임시값)
const MISSION_SECS := 6.0  # 라운드 첫 미션 토스트를 보이는 초(I122 임시값)
const SCROLL := [".oooooooooo.", "oppppppppppo", ".oooooooooo.", "..oppppppo..", "..opllllpo..", "..oppppppo..",
	"..opllllpo..", "..oppppppo..", "..opllpppo..", ".oooooooooo.", "oppppppppppo", ".oooooooooo."]  # 임무 칸 두루마리(I122)
const DOT := [".....", ".###.", ".###.", ".###.", "....."]  # 임무 칸: 조건을 지키는 중
const COIN := [".####.", "##oo##", "#o##o#", "#o##o#", "##oo##", ".####."]
const FLAG := ["|####.", "|#####", "|####.", "|.....", "|.....", "|....."]
const MENU := ["########", "........", "........", "########", "........", "........", "########"]  # ≡
const PLAY := ["#...", "##..", "###.", "####", "###.", "##..", "#..."]  # ▶
const SKULL := [".#####.", "#######", "#..#..#", "#######", ".##.##.", ".#####.", ".#.#.#."]  # 보스(S188)
const MOON := ["..###..", ".###...", "###....", "###....", "###....", ".###...", "..###.."]  # 밤 웨이브(S214)
const MOON_COLOR := Color("e8e0b0")
const ARROW := [".###.", ".###.", "#####", ".###.", "..#.."]  # 아래 가장자리 표식의 화살표(S188)
const ATTACK := [".....g....", "....hgssss", ".....g....", "......#...", "......##..", "#########.", "##########", "#########.", "......##..", "......#..."]  # 칼 + 화살. 공격 이동 태그(I139)
const STOP := ["..######..", ".#oooooo#.", "#oooooooo#", "#oooooooo#", "#oooooooo#", "#oooooooo#", "#oooooooo#", "#oooooooo#", ".#oooooo#.", "..######.."]  # 정지 태그(I139)
const SHIELD := ["..........", "..########", "..#oooooo#", "..#oooooo#", "..#oooooo#", "..#oooooo#", "...#oooo#.", "...#oooo#.", "....#oo#..", ".....##..."]  # 홀드(I139)
const HOLD_TIPS := ["홀드 끔\n켜면 기준 지점 반경 안의 적만 친다", "홀드 켬\n기준 지점 반경 안의 적만 친다", "홀드 섞임\n누르면 모두 켠다"]
const HOLD_LOOK := [Color(0.4, 0.4, 0.4), Color.WHITE, Color(0.7, 0.7, 0.7)]  # 홀드 방패 밝기: 끔·켬·섞임
const HAMMER := [".#####.", ".#####.", "...#...", "...#...", "...#...", "...#..."]  # 팝업 완성·수리(I58)
const UP := ["..#..", ".###.", "#####", ".###.", ".###."]  # 팝업 업그레이드(I58)
const TOP := Rect2(0, 0, 640, 30)  # 팝업이 피하는 위 띠(I137)
const POP_GAP := 2.0  # 팝업과 고른 칸 사이(I58)
const CONFIRM := 2.0  # 철거를 다시 눌러 확정하는 초(S74 임시값)
const REFUSE_MARK := 0.5  # 거부된 놓기 칸의 빨간 ✕ 초(I128 임시값)
const REFUSE_HINT := 1.5  # 그때 안내 줄을 거부 이유로 바꾸는 초. 놓기 모드가 끝나도 그동안 칩이 남는다(I128 임시값)
const ENEMIES := {"basic": "기본", "fast": "빠름", "armored": "장갑", "flying": "비행", "boss": "보스"}  # S106
const TRAITS := {"fast": "성벽을 오른다", "flying": "길을 무시한다", "armored": "받는 피해를 줄인다", "boss": "성벽을 뚫고 온다. 대지 강타·분노"}  # S107·S109·S108, 보스는 wall_k 0.3과 스킬(S195)
const SIDES := ["왼쪽", "가운데", "오른쪽"]  # ponytail: 출현 지점 이름은 시험 스테이지(왼쪽부터 셋) 차례다. 지점이 다른 맵이 생기면 x로 이름을 정한다
const VIEW := Rect2(0, 28, 640, 332)  # 위 띠 아래 맵이 보이는 화면. 출현 지점이 이 밖이면 아래 가장자리 표식(S188)
const EDGE_X := Vector2(68, 500)  # 아래 가장자리 표식이 놓이는 x 범위(S188 임시값). y는 344. 왼끝은 미니맵(S209) 오른쪽
const DOUBLE := 0.4  # 초상·F키를 이 초 안에 두 번 누르면 카메라가 그 영웅에게(I165 임시값)
const LOW := 0.33  # 체력이 이 비율 밑이면 초상이 빨갛게 맥박친다(I129)
const MANA := Color("4a8cff")  # 영웅 칸 마나 막대(ui_research 4.9)

signal menu_pressed  # 메뉴 칸(S185). main이 ESC 메뉴를 연다

var battle
var controls
var map: Viewport  # 맵(전장)을 그리는 뷰포트(S30, 2026-10-25부터 루트). 팝업 위치를 그 카메라 변환으로 잡는다. 기준 해상도 단위다
var bar: Panel  # 위 띠(S185). 칸은 좌표로 두고, 띠 바탕이 클릭을 받아 맵으로 흘리지 않는다
var cells := {}  # 위 띠 칸 이름(BAR) → Control
var hp_bar := ColorRect.new()  # 상태 묶음의 거점 체력 막대(S190)
var marks := []  # 임무 칸의 점 둘(I122): 왼쪽 미션·오른쪽 의뢰
var toasts := HudToast.new()  # 토스트(I163)
var alerts  # 경보(S189, hud_alert.gd)
var hints  # 처음 하는 사람 힌트(S191, hints.gd)
var tip := HudTip.new()  # 위 띠 조작의 툴팁(S187)
var grid  # 건설 격자·정보 칸(S186)
var select  # 선택 패널(S206). 건설 격자 바로 왼쪽
var minimap  # 미니맵(S209). 왼쪽 아래 구석
var evac  # 대피령 버튼(S230). 미니맵 바로 위
var view  # 맵 그림(BattleView). 미니맵이 구운 바닥을 빌린다. main이 넣는다
var _hp: Label
var _lv: Label
var _gold: Label
var _tax: Label
var _round: Label
var _eng: Label  # 공병 칸의 놀고 있는 공병 수
var start: Button  # 진행 칸의 «▶ 전투 시작»(I13). 준비 단계에만
var gauge: Button  # 진행 칸의 웨이브 버튼: 준비 단계 다음 웨이브(S188)·전투 단계 계기판·영입·승패(I13)
var skull: TextureRect  # 진행 칸의 보스 해골(S188)
var moon: TextureRect  # 진행 칸의 달(S214): 준비 단계·영입·라운드 사이는 다음 웨이브, 전투 단계는 이번 웨이브가 밤이면
var _dusk := []  # «해가 진다» 토스트를 띄운 웨이브 [라운드, 웨이브](S214). 준비 단계에 비운다
var edges := Control.new()  # 화면 밖 출현 지점의 아래 가장자리 표식(S188). 출현 지점마다 하나
var _g1: Label  # 웨이브 버튼 윗줄
var _g2: Label  # 웨이브 버튼 아랫줄
var _dots: TextureRect  # 웨이브 점
var _track := ColorRect.new()  # 전투 진행 막대 바탕
var _fill := ColorRect.new()  # 전투 진행 막대(나온 적 가운데 처치한 비율)
var _dot_tex := {}  # «웨이브 수/지금» → 웨이브 점 그림
var _laid := ""  # 진행 칸 자리를 마지막으로 정한 단계
var _flash := 0.0  # 거점 체력 막대가 하얗게 남은 초
var _hp_seen := -INF  # 지난 프레임의 거점 체력
var _ok := {}  # 이번 라운드 미션·의뢰 이름 → 지난 프레임에 조건을 지켰나(I122)
var _eng_next := -1  # 공병 칸을 누를 때 다음에 갈 놀고 있는 공병 차례
var _dot := HudBuild.dots(DOT)
var _cross := HudBuild.dots(HudBuild.CROSS)
var hint := Label.new()  # 안내 칩의 글(S147)
var chip := PanelContainer.new()  # 놓기·대포 옮기기·조준 중의 안내 칩(S147). 위 띠 툴팁이 뜨면 숨는다
var popup := VBoxContainer.new()  # 맵 위 팝업(I58). 줄(HBox)마다 정해진 버튼. 고른 칸(클릭하거나 드래그를 놓은 지점의 칸) 바깥쪽 모서리에 뜬다
var info_lines := ["", ""]  # 정보 칸 «고른 것»에 덧붙일 [설명, 빨간 이유](I124, I128, I132, I140). hud_build가 읽는다
var _why := {}  # 팝업 버튼 → 못 누르는 이유(툴팁 빨간 줄)
var _opens := ""  # 마을 레벨 버튼: 그 레벨에 열리는 시설(I132)
var _arm := -INF  # 철거를 처음 누른 때(S74)
var _arm_on := []  # 그때 고른 구조물. 고른 것이 바뀌면 첫 클릭부터 다시
var _refused := [Vector2i.ZERO, -INF, ""]  # 거부된 놓기 칸·그때·이유(I128)
var _mark := Control.new()  # 그 칸의 빨간 ✕를 그린다
var _sell: Button
var _finish: Button
var _buy := {}  # 용병 kind → 구매 버튼
var _demolish: Button
var _move: Button
var _resume: Button
var _cancel: Button
var _gate: Button
var _upgrade: Button
var _repair: Button
var _restore: Button
var _village: Button
var _heal := []  # 교회 팝업: 출전 영웅마다 치료 버튼(S137, I140)
var window := PanelContainer.new()  # 결과·영입 창(S117). 영입·라운드 사이는 [16,34] 폭 608, 결과는 [170,110,300,110](I136)
var dim := ColorRect.new()  # 창이 떠 있으면 띠 아래 맵을 덮는다(S117)
var _result_label := Label.new()
var _next: Button  # 결과 창의 «1라운드 시작»·«다음 라운드»·«새 도전»
var _hire := VBoxContainer.new()  # 결과 창 안의 영입 칸
var _hire_info := Label.new()
var _offers := []  # 목록 칸마다 영입 카드(I110)
var _offer_kinds := []  # 목록 칸마다 마지막으로 본 영웅 종류. 영입한 칸은 그 초상을 흐리게 남긴다
var _note := Label.new()  # 상한에서 리롤을 누르면 보이는 빨간 이유(I127)
var _reroll: Button
var _members := []  # 보유 영웅마다 [출전·대기 전환 버튼, 내보내기 버튼, 이관 버튼]
var _giver = null  # 이관(I116)에서 먼저 고른 주는 영웅
var _quests := VBoxContainer.new()  # 라운드 사이 영입 칸 안의 의뢰 목록(I121)
var _quests_info := Label.new()
var _commissions := []  # 의뢰 목록 칸마다 수락 버튼
var _seen := ""  # 마지막으로 본 판 단계. 바뀌었을 때 결과 창이 떠 있으면 포커스를 준다
var tags := []  # 고른 영웅·용병의 상황 태그 [A 공격 이동, S 정지, H 홀드](I139)
var _tag_pics := []  # 태그마다 그림
var _hold_tip := ""  # 홀드 태그 툴팁의 지금 상태 글
var portraits := []  # 출전 칸마다 초상 버튼(I129). 누르면 그 영웅을 고른다(I165)
var slots := []  # 출전 칸마다 {칸: 스킬 칸}(I151)
var _rows := []  # 출전 칸마다 {pic: 초상 그림, lv: 레벨 글, hp·mp: 막대, down: «쓰러짐»}(I129)
var _faces := {}  # 영웅 종류 → 초상 대역 그림(S30)
var _now := 0.0  # HUD 시계(초). 맥박·거부 표시·두 번 누름(I165)
var _taps := {}  # 출전 칸 → 마지막으로 F키·초상을 누른 때(_now)
var _gap := ""  # 고른 것의 칸에 공병 지시를 맡을 공병이 없는 이유(I128). _engineer_gap이 _gap_for 칸에서 _gap_at(ms)에 쟀다
var _gap_for := []
var _gap_at := 0

func _init(b, c, m) -> void:
	battle = b
	controls = c
	map = m

func _ready() -> void:
	var root := Control.new()  # 글자 크기를 한 번에 주는 틀. 클릭은 아래 맵으로 흘린다
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = HudTheme.make(10)
	add_child(root)
	bar = Panel.new()
	bar.size = Vector2(640, 28)
	bar.add_theme_stylebox_override("panel", HudTheme.box("panel", "PanelContainer", HudTheme.PANEL, HudTheme.LINE))
	root.add_child(bar)
	_make_status()
	var m := _cell("mission", _bar_button(bar, "", Callable()))
	_pic(m, HudBuild.dots(SCROLL, {"o": Color("6b5537"), "p": Color("e8d8a8"), "l": Color("8a7550")}), Vector2(12, 12)).position = Vector2(6, 2)
	for i in 2:
		marks.append(_pic(m, _dot, Vector2(5, 5)))
		marks[i].position = Vector2(5 + 9 * i, 17)
	tip.add(m, func(): return ["미션·의뢰", "", "", "\n".join(_quest_lines()), ""])
	var e := _cell("engineer", _bar_button(bar, "", _next_engineer))
	_pic(e, HudBuild.icon("engineer"), Vector2(12, 12)).position = Vector2(4, 1)
	_eng = _text(e, 8, HudTheme.TEXT)
	_eng.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_eng.position = Vector2(0, 12)
	_eng.size = Vector2(20, 11)
	tip.add(e, func(): return ["공병", "", "", "놀고 있는 공병 %d · 전체 %d — 누르면 놀고 있는 공병에게 카메라가 간다" % [_idle().size(), battle.units.filter(func(u): return u.kind == "engineer").size()], ""])
	for i in battle.HIRE.lineup:  # 영웅 칸: 초상 24×24, 스킬 칸 18×18 넷, 그 아래 체력·마나 막대(I129). 좌표는 임시값(ui_research 4.3)
		var cell := _cell("hero%d" % i, Control.new())
		cell.draw.connect(func(): _empty_slot(cell, i))
		var face := _bar_button(cell, "", func(): controls.pick_hero(i))
		face.size = Vector2(24, 24)
		var row := {"pic": _pic(face, null, Vector2(22, 22))}
		row.pic.position = Vector2(1, 1)
		var key := _text(face, 7, HudTheme.ACCENT)
		key.text = "F%d" % (i + 1)
		key.position = Vector2(1, -1)
		key.size = Vector2(12, 8)
		row.lv = _text(face, 7, HudTheme.TEXT)
		row.lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.lv.position = Vector2(12, 16)
		row.lv.size = Vector2(11, 8)
		tip.add(face, func(): return _hero_tip(i))
		portraits.append(face)
		var cells_of := {}
		for j in battle.SLOTS.size():
			var slot: String = battle.SLOTS[j]
			var sb := SkillCell.new()
			cell.add_child(sb)
			sb.position = Vector2(25 + 19 * j, 0)
			sb.pressed.connect(func(): _skill_press(i, slot))
			sb.gui_input.connect(func(ev): _auto_click(ev, i, slot))
			tip.add(sb, func(): return _skill_tip(i, slot))
			cells_of[slot] = sb
		slots.append(cells_of)
		for k in ["hp", "mp"]:
			var back := ColorRect.new()
			back.color = HudTheme.CELL
			back.position = Vector2(25, 19 if k == "hp" else 22)
			back.size = Vector2(75, 2)
			cell.add_child(back)
			row[k] = ColorRect.new()
			row[k].size = back.size
			back.add_child(row[k])
		row.mp.color = MANA
		row.down = _text(cell, 9, HudTheme.DANGER)
		row.down.text = "쓰러짐"
		row.down.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.down.position = Vector2(25, 0)
		row.down.size = Vector2(75, 18)
		_rows.append(row)
	controls.hero_key.connect(_tap)
	controls.skill_keyed.connect(_skill_refuse)
	_make_progress()
	var menu := _cell("menu", _bar_button(bar, "", func(): menu_pressed.emit()))
	_pic(menu, HudBuild.dots(MENU), Vector2(8, 7)).position = Vector2(4, 8)
	tip.add(menu, func(): return ["메뉴", "ESC", "", "계속·설정·메인 메뉴로·게임 종료", ""])
	for n in bar.find_children("*", "Control", true, false):  # 버튼 위의 그림·글은 클릭과 호버를 버튼에 넘긴다
		if not n is BaseButton:
			n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sword := {"g": HudTheme.ACCENT, "h": Color("6b5537"), "s": Color("d8dde6"), "#": HudTheme.TEXT}
	var looks := [HudBuild.dots(ATTACK, sword), HudBuild.dots(STOP, {"#": HudTheme.TEXT, "o": HudTheme.DANGER}), HudBuild.dots(SHIELD, {"#": Color("e8d8a8"), "o": SkillCell.TEAL})]
	for i in 3:  # 오른쪽 가장자리 태그 24×24, 자리는 고정(I139). 그림 10×10을 2배로, 왼쪽 위에 키 글자
		var t := _bar_button(root, "", [controls.attack_key, controls.stop, controls.toggle_hold][i])
		t.position = Vector2(616, 182 + 26 * i)
		t.size = Vector2(24, 24)
		_tag_pics.append(_pic(t, looks[i], Vector2(20, 20)))
		_tag_pics[i].position = Vector2(2, 2)
		var key := _text(t, 7, HudTheme.ACCENT)
		key.text = "ASH"[i]
		key.position = Vector2(1, -1)
		key.size = Vector2(8, 8)
		for n in t.get_children():
			n.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tags.append(t)
	tip.add(tags[0], func(): return ["공격 이동", "A", "", "누른 뒤 땅: 가는 길의 적을 친다\n적: 그 적만 친다", ""])  # 툴팁 폭 160이라 줄을 나눈다
	tip.add(tags[1], func(): return ["정지", "S", "", "그 자리에 선다", ""])
	tip.add(tags[2], func(): return ["홀드", "H", "", _hold_tip, ""])
	chip.position = Vector2(134, 30)  # 위 띠 바로 아래(S147 임시값). 글이 길면 오른쪽으로 는다
	chip.custom_minimum_size = Vector2(180, 14)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dark := StyleBoxFlat.new()
	dark.bg_color = Color(0, 0, 0, 0.65)
	dark.content_margin_left = 4
	dark.content_margin_right = 4
	chip.add_theme_stylebox_override("panel", dark)
	hint.add_theme_font_size_override("font_size", 9)
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip.add_child(hint)
	root.add_child(chip)
	controls.refused.connect(func(cell, why): _refused = [cell, _now, why])
	controls.facility_key.connect(func(f): _focus(Vector2(f.cell)))  # 용병 키로 고른 시설로 카메라(S81, I164)
	# 창은 윗변을 고정해 아래로만 자란다(I136). 영입·라운드 사이는 두 칸: 왼쪽 영입 카드·리롤, 오른쪽 보유 5칸, 아래 의뢰, 진행 버튼은 오른쪽 아래
	dim.position = VIEW.position
	dim.size = VIEW.size
	dim.color = Color(0, 0, 0, 0.5)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	root.add_child(window)
	var box := VBoxContainer.new()
	window.add_child(box)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_result_label)
	box.add_child(_hire)
	_hire_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hire.add_child(_hire_info)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 8)
	_hire.add_child(cols)
	var left := VBoxContainer.new()
	var right := VBoxContainer.new()
	for col in [left, right]:
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cols.add_child(col)
	for v in [box, _hire, _quests, left, right]:
		v.add_theme_constant_override("separation", 2)
	for i in battle.HIRE.slots:
		_offers.append(_card(left, i))
		_offer_kinds.append("")
	_reroll = _window_button(left, _reroll_press)
	tip.add(_reroll, func(): return ["리롤", "", "", "목록을 새로 뽑는다", _cap_note()])
	_note.add_theme_color_override("font_color", HudTheme.DANGER)
	_note.add_theme_font_size_override("font_size", 8)
	left.add_child(_note)
	for i in battle.HIRE.cap:  # 보유 칸은 늘 cap줄이다. 빈 칸도 자리를 지킨다(I136)
		var member := HBoxContainer.new()
		right.add_child(member)
		var toggle := _window_button(member, func(): battle.set_lineup(battle.roster[i], battle.roster[i] not in battle.lineup))
		toggle.toggle_mode = true
		toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var drop := _window_button(member, func(): battle.dismiss(battle.roster[i]))
		var give := _window_button(member, func(): _give(battle.roster[i]))
		tip.add(drop, func(): return ["내보내기", "", "", "보유에서 뺀다 · 골드는 돌려받지 못한다", ""])
		tip.add(give, func(): return _give_tip(i))
		_members.append([toggle, drop, give])
	_hire.add_child(_quests)
	_quests_info.text = "의뢰 — 다음 라운드에 걸린다. 하나만 수락한다"
	_quests.add_child(_quests_info)
	for i in battle.QUEST_OFFERS:
		var take := _window_button(_quests, func(): battle.accept(i))
		tip.add(take, func(): return ["의뢰", "", "", "다음 라운드에 걸린다 · 하나만 수락한다", ""])
		_commissions.append(take)
	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_END
	foot.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_SHRINK_END  # 결과 창(높이 110 고정)에서도 진행 버튼이 오른쪽 아래
	box.add_child(foot)
	_next = _window_button(foot, proceed)
	grid = HudBuild.new(self)
	root.add_child(grid)
	select = HudSelect.new(self)
	root.add_child(select)
	minimap = HudMinimap.new(self)
	root.add_child(minimap)
	evac = HudEvac.new(self)
	root.add_child(evac)
	_mark.set_anchors_preset(Control.PRESET_FULL_RECT)
	_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mark.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_mark.draw.connect(_draw_refused)
	root.add_child(_mark)
	root.add_child(popup)
	var rows := []  # 1줄 판매·완성·구매·공병 지시·마을 레벨·업그레이드·수리·복구, 2줄 성문, 그 아래 영웅마다 치료(I58)
	for i in 2 + battle.HIRE.lineup:
		rows.append(HBoxContainer.new())
		popup.add_child(rows[i])
	var coin := HudBuild.dots(COIN, {"#": HudTheme.ACCENT, "o": Color("b08a3a")})
	var hammer := HudBuild.dots(HAMMER, {"#": HudTheme.TEXT})
	_sell = _pop(rows[0], _sell_now, "판매", coin)
	_finish = _pop(rows[0], func(): _apply(battle.finish, battle.unfinished(controls.selling)), "완성", hammer)
	for kind in battle.MERC_KINDS:
		_buy[kind] = _pop(rows[0], func(): battle.recruit(controls.facility, kind), "%s 구매" % NAMES[kind], HudBuild.icon(kind))
	_demolish = _pop(rows[0], _demolish_press, "철거")
	_move = _pop(rows[0], _start_move, "옮기기")
	_resume = _pop(rows[0], func(): _apply(battle.resume, battle.unfinished(controls.picked)), "이어 짓기")
	_cancel = _pop(rows[0], func(): _apply(battle.cancel, battle.unfinished(controls.picked)), "취소")
	_village = _pop(rows[0], func(): battle.raise_village(), "마을 레벨 올리기")
	_upgrade = _pop(rows[0], func(): battle.upgrade(controls.fort), "업그레이드", HudBuild.dots(UP, {"#": HudTheme.ACCENT}))
	_repair = _pop(rows[0], func(): _apply(battle.repair, _to_repair()), "수리", hammer)
	_restore = _pop(rows[0], func(): battle.restore(controls.fort), "복구")
	_gate = _pop(rows[1], func(): battle.set_gate(controls.fort, not controls.fort.open), "성문")
	for i in battle.HIRE.lineup:
		_heal.append(_pop(rows[2 + i], func(): battle.heal(battle.heroes[i]), "치료"))
	_make_edges(root)
	alerts = HudAlert.new(self)
	root.add_child(alerts)
	controls.alert_key.connect(alerts.back)
	hints = Hints.new(battle, controls)
	root.add_child(hints)
	toasts.go.connect(func(cell): _focus(Vector2(cell)))  # 경보 토스트를 누르면 그 자리로(I163)
	toasts.tip = tip
	root.add_child(toasts)
	root.add_child(tip)  # 맨 위에 그린다(I162)

func _process(delta: float) -> void:
	_now += delta
	select.refresh()  # 정보 칸 자리(hud_build.info_box)가 패널이 보이는지를 본다. 자식(격자)보다 먼저 돈다
	var prep: bool = battle.state == "prep"
	var on: bool = battle.state in ["prep", "battle"]
	var round_no: int = battle.round_index + 1
	if prep and _seen != "prep" and battle.wave_index == 0:  # 라운드 첫 준비 단계(I122)
		_ok.clear()
		if battle.mission != "":
			toasts.push("이번 라운드 미션: %s" % battle.QUEST_KINDS[battle.mission].text, MISSION_SECS)
	if prep and _seen != "prep" and _boss(_next_wave()):  # S188
		toasts.push("다음 웨이브에 보스")
	if prep and _seen != "prep" and _night(_next_wave()):  # S214
		toasts.push("다음 웨이브는 밤")
	if prep:
		_dusk = []
	var dusk: Dictionary = battle.night(battle.round_index, battle.wave_index) if battle.state == "battle" else {}
	if not dusk.is_empty() and battle.wave_time >= dusk.get("at", 0.0) and _dusk != [battle.round_index, battle.wave_index]:  # 해가 지기 시작했다(S214)
		_dusk = [battle.round_index, battle.wave_index]
		toasts.push("해가 진다")
	_show_status(delta, round_no)
	for k in ["mission", "engineer"]:  # 준비·전투 단계에만(S185)
		cells[k].visible = on
	if on:
		_show_quests()
		_eng.text = str(_idle().size())
		_eng.add_theme_color_override("font_color", HudTheme.DANGER if battle.live() and _idle().is_empty() else HudTheme.TEXT)  # I128
	toasts.visible = on
	alerts.visible = on
	minimap.visible = on
	minimap.queue_redraw()
	if on:
		alerts.step(delta)
	hints.step()
	_show_progress()
	_show_edges()
	var picked: Array = controls.selected.filter(func(u): return u.alive)  # 고른 영웅·용병의 명령 태그, 용병의 홀드(I139)
	var mercs: Array = picked.filter(func(u): return not u.is_hero)
	tags[0].visible = on and not picked.is_empty()
	tags[1].visible = tags[0].visible
	tags[2].visible = on and not mercs.is_empty()
	if tags[2].visible:
		var held: int = mercs.filter(func(u): return u.hold).size()
		var h := 0 if held == 0 else 1 if held == mercs.size() else 2  # 끔·켬·섞임
		_tag_pics[2].modulate = HOLD_LOOK[h]
		_hold_tip = HOLD_TIPS[h]
	var refusing: bool = _now - _refused[1] < REFUSE_HINT
	chip.visible = (controls.placing != "" or controls.moving != null or controls.aiming != "" or controls.attacking or refusing) and not tip.shows_in(bar)  # 위 띠 툴팁이 뜨면 숨는다(S147)
	hint.text = "%s 놓기: 좌클릭 · 끝: 우클릭·ESC" % NAMES.get(controls.placing, "")
	if refusing:  # 거부된 놓기의 첫 이유(I128)
		hint.text = "✕ " + _refused[2]
	hint.self_modulate = HudTheme.DANGER if refusing else Color.WHITE
	_mark.queue_redraw()
	if controls.moving:
		hint.text = "대포 옮길 칸: 좌클릭 · 끝: 우클릭·ESC"
	if controls.aiming != "":  # 조준 중(S147)
		hint.text = "%s %s 대상: 좌클릭 · 취소: 우클릭·ESC" % [HEROES[controls.aim_hero.kind].get_slice("(", 0), controls.aiming.to_upper()]
	if controls.attacking:  # 공격 명령 조준(S35)
		hint.text = "공격 대상: 좌클릭 · 취소: 우클릭·ESC"
	chip.reset_size()
	_show_heroes()
	window.visible = battle.state in ["hiring", "cleared", "won", "lost"]
	dim.visible = window.visible
	window.position = Vector2(16, 34) if battle.hiring_open() else Vector2(170, 110)  # I136 임시값
	window.custom_minimum_size = Vector2(608, 0) if battle.hiring_open() else Vector2(300, 110)
	_result_label.text = {"hiring": "도전 시작 — 영웅 영입", "cleared": "%d라운드 승리" % round_no, "won": "도전 성공!", "lost": "%d라운드 패배 — 도전 끝" % round_no}.get(battle.state, "")
	for s in battle.settled:  # 지난 라운드의 미션·의뢰 판정(I120, I122)
		var q: Dictionary = battle.QUEST_KINDS[s[0]]
		_result_label.text += "\n%s «%s» %s" % ["의뢰" if q.commission else "미션", q.text, "달성 +%d골드" % q.reward if s[1] else "실패"]
	_next.text = {"hiring": "1라운드 시작 (Enter)", "cleared": "다음 라운드 (Enter)"}.get(battle.state, "새 도전 (Enter)")
	if battle.state != _seen:
		_seen = battle.state
		_giver = null
		_note.text = ""  # 상한 리롤 이유는 그 창에서만(I127)
		if window.visible:
			_next.grab_focus()
	_hire.visible = battle.hiring_open()
	if _hire.visible:
		_show_hire()
	window.reset_size()
	if not prep or controls.placing != "":  # 전투가 시작되거나 놓기 모드에 들어가면 판매 팝업을 닫는다(I58)
		controls.selling = []
	_why.clear()
	_sell.visible = not controls.selling.is_empty()
	_sell.text = "판매 +%d" % controls.selling.reduce(func(n, t): return n + battle.refund(t), 0)
	_finish.visible = not battle.unfinished(controls.selling).is_empty()
	if controls.facility and not controls.facility.alive:  # 파괴되거나 팔린 시설
		controls.facility = null
	for kind in _buy:
		_buy[kind].visible = battle.live() and controls.facility != null and kind in controls.facility.produces
		_buy[kind].text = "%s %d" % [NAMES[kind], battle.MERC_KINDS[kind].cost]
	if not battle.live() or controls.placing != "":
		controls.picked = []
	controls.picked = controls.picked.filter(func(s): return s.alive)  # 부서지거나 허물거나 취소된 것은 뺀다
	var todo: Array = battle.unfinished(controls.picked)
	_demolish.visible = controls.picked.any(battle.can_demolish)
	_move.visible = _cannon() != null
	_resume.visible = todo.any(func(s): return s.worker == null)
	_cancel.visible = not todo.is_empty()
	if controls.placing != "" or (controls.fort and not controls.fort.alive and battle.rubble.get(controls.fort.cell) != controls.fort):  # 놓기 모드거나 판에서 사라진 성곽 칸. 잔해는 남긴다(I89)
		controls.fort = null
	var k = controls.fort
	var live: bool = k != null and k.alive
	# 공병 지시 버튼(철거·옮기기·이어 짓기·업그레이드·수리·복구)은 고른 것의 칸에 맡을 공병이 없으면 끄고, 이유는 툴팁·정보 칸에(I128)
	var gap: String = GAPS.get(_engineer_gap((controls.picked + ([k] if k else []) + ([battle.base] if controls.village else []))), "")  # Block을 넘긴다(성벽 위 대포 칸은 성곽과 겹친다)
	var armed: bool = _now - _arm < CONFIRM and controls.picked == _arm_on  # 이 대상의 철거를 한 번 눌렀다(S74)
	_demolish.text = "철거?" if armed else "철거"
	for key in ["font_color", "font_hover_color"]:
		if armed:
			_demolish.add_theme_color_override(key, HudTheme.DANGER)
		else:
			_demolish.remove_theme_color_override(key)
	for b in [_demolish, _move, _resume, _upgrade, _repair]:
		b.disabled = gap != ""
		_why[b] = gap
	_gate.visible = live and k.kind == "gate" and not k.sealed and battle.state in ["prep", "battle"]  # 닫힌 문루는 여닫기 버튼이 없다(S39)
	if _gate.visible:  # 쿨타임 중이면 누르지 못하고 남은 초를 올림해 붙인다(I123). 성문 칸에 누가 있어 못 닫으면 어둡게(I124)
		var stuck: bool = k.open and battle.occupied_area(k)  # 문루 칸 어디든(S217)
		_gate.text = ("닫기" if k.open else "열기") + (" %d초" % ceili(k.lock) if k.lock > 0.0 else "")
		_gate.disabled = k.lock > 0.0 or stuck
		_why[_gate] = "칸 막힘" if stuck else "%d초 뒤에 여닫는다" % ceili(k.lock) if k.lock > 0.0 else ""
	# 공병이 올리는 중이면 숨긴다. 그만둔 업그레이드는 «계속»으로 골드 없이 이어 올린다(I68)
	_upgrade.visible = live and battle.state in ["prep", "battle"] and k.level < battle.UPGRADE_MAX and k.worker == null
	if _upgrade.visible:
		_upgrade.text = "업그레이드 계속" if k.lift >= 0.0 else "업그레이드 %d" % battle.upgrade_cost(k)
	if controls.placing != "":
		controls.village = false
	_village.visible = controls.village and prep and battle.village_level <= battle.VILLAGE_UP.size()
	_opens = ""
	if _village.visible:  # 그 레벨에 열리는 시설 이름은 툴팁·정보 칸에(I132)
		var opens: Array = battle.STRUCTURE_KINDS.keys().filter(func(s): return battle.STRUCTURE_KINDS[s].village_level == battle.village_level + 1).map(func(s): return NAMES[s])
		_village.text = "마을 Lv%d %d" % [battle.village_level + 1, battle.VILLAGE_UP[battle.village_level - 1]]
		_opens = "" if opens.is_empty() else "Lv%d에 %s" % [battle.village_level + 1, ", ".join(opens)]
	var fix := _to_repair()
	_repair.visible = not fix.is_empty()
	if _repair.visible:
		_repair.text = "수리 %d" % fix.reduce(func(n, t): return n + battle.repair_cost(t), 0)
	_restore.visible = k != null and battle.rubble.get(k.cell) == k and k.worker == null and battle.state in ["prep", "battle"]
	if _restore.visible:  # 잔해 칸에 누가 있으면 복구하지 못한다(I124)
		var blocked: bool = battle.occupied_area(k)
		_restore.text = "복구 %d" % battle.repair_cost(k)
		_restore.disabled = blocked or gap != ""
		_why[_restore] = "칸 막힘" if blocked else gap
	# 고른 교회의 치료 버튼(S137): 출전 영웅마다 늘. 전투 단계·체력 가득·쓰러짐이면 끄고 이유는 툴팁·정보 칸에(I140)
	var church: bool = (controls.selling + controls.picked).any(func(s): return s.kind == "church")
	for i in _heal.size():
		var h = battle.heroes[i] if i < battle.heroes.size() else null
		_heal[i].visible = church and h != null
		if _heal[i].visible:
			var full: bool = h.hp >= h.max_hp
			_heal[i].text = "치료 %s" % HEROES[h.kind].get_slice("(", 0) + ("" if full else " %d" % battle.heal_cost(h))
			_heal[i].icon = _faces.get(h.kind)
			_why[_heal[i]] = "준비 단계에만" if not prep else "쓰러짐" if not h.alive else "체력 가득" if full else ""
			_heal[i].disabled = _why[_heal[i]] != ""
	var shown: Array = _why.keys().filter(func(b): return b.visible and _why[b] != "")
	info_lines = [_opens, _why[shown[0]] if not shown.is_empty() else ""]
	for r in popup.get_children():
		r.visible = r.get_children().any(func(b): return b.visible)
	_place_popup()

# 키보드 포커스를 받지 않는다. 받으면 Enter·Space가 맵 대신 마지막에 누른 버튼을 누른다
func _button(parent: Control, text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	if on_press.is_valid():
		b.pressed.connect(on_press)
	parent.add_child(b)
	return b

# 맵 위 팝업 버튼(I58): 아이콘(10px 안) + 짧은 글 + 비용. 툴팁은 이름과 못 누르는 이유이고 팝업 전체 아래에 뜬다(S187)
func _pop(row: Control, on_press: Callable, name: String, icon: Texture2D = null) -> Button:
	var b := _button(row, "" if icon else name, on_press)  # 아이콘 없는 버튼은 이름을 글로 둔다(이어 짓기·취소·옮기기). 값을 붙이는 버튼은 _process가 글을 덮는다
	b.icon = icon
	b.add_theme_constant_override("icon_max_width", 10)
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tip.add(b, func(): return [name, "", "", _opens if b == _village else "", "✕ " + _why[b] if _why.get(b, "") != "" else ""], popup)
	return b

# 철거(S74): 첫 클릭은 «철거?», 같은 대상을 고른 채 CONFIRM초 안에 다시 누르면 철거한다
func _demolish_press() -> void:
	if _now - _arm < CONFIRM and controls.picked == _arm_on:
		_arm = -INF
		_apply(func(s): battle.demolish([s]), controls.picked)
	else:
		_arm = _now
		_arm_on = controls.picked.duplicate()

# 팝업을 고른 칸의 바깥쪽(화면 가운데 반대편) 모서리에 붙인다(I58). 화면 밖이거나 위 띠·건설 격자·정보 칸·태그와 겹치면
# 좌우·위아래·둘 다 뒤집은 모서리를 차례로 본다(I137). 맵 px → 화면은 맵 뷰포트의 카메라 변환이다(HUD와 같은 기준 해상도)
func _place_popup() -> void:
	popup.reset_size()
	var t := map.get_canvas_transform()
	var cell: Rect2 = t * Rect2((controls.sell_at / BattleView.CELL).floor() * BattleView.CELL, Vector2.ONE * BattleView.CELL)
	var screen := Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)
	var away := (cell.get_center() - screen.get_center()).sign()
	var avoid: Array = [TOP, grid.get_global_rect(), grid.info_box()] + tags.filter(func(g): return g.visible).map(func(g): return g.get_global_rect())
	var s := popup.size
	for flip in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
		var d: Vector2 = away * flip
		var r := Rect2(cell.end.x + POP_GAP if d.x >= 0 else cell.position.x - POP_GAP - s.x, cell.end.y + POP_GAP if d.y >= 0 else cell.position.y - POP_GAP - s.y, s.x, s.y)
		if screen.encloses(r) and not avoid.any(func(h): return h.intersects(r)):
			popup.position = r.position
			return
	# 들어맞는 모서리가 없으면 화면 안·위 띠 아래로 당기고, 오른쪽에 붙은 격자·정보 칸·태그와 겹치면 그 왼쪽으로 민다
	var at := (cell.end + Vector2(POP_GAP, POP_GAP)).clamp(Vector2(0, TOP.end.y), screen.size - s)
	for h in avoid.slice(1):
		if h.intersects(Rect2(at, s)):
			at.x = h.position.x - POP_GAP - s.x
	popup.position = at

# 닿는 공병이 없어 거부된 놓기 칸의 빨간 ✕(I128)
func _draw_refused() -> void:
	if _now - _refused[1] < REFUSE_MARK:
		_mark.draw_texture_rect(_cross, map.get_canvas_transform() * Rect2(Vector2(_refused[0]) * BattleView.CELL, Vector2.ONE * BattleView.CELL), false, HudTheme.DANGER)

# 위 띠의 칸 버튼: 안쪽 여백이 없어 좌표로 준 크기를 넘지 않는다
func _bar_button(parent: Control, text: String, on_press: Callable) -> Button:
	var b := _button(parent, text, on_press)
	b.theme_type_variation = "BarCell"
	return b

# 위 띠 칸 하나를 BAR 자리에 둔다(S185)
func _cell(name: String, c: Control) -> Control:
	if c.get_parent() == null:
		bar.add_child(c)
	c.position = BAR[name].position
	c.size = BAR[name].size
	cells[name] = c
	return c

func _text(parent: Control, font: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", font)
	l.add_theme_color_override("font_color", color)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent.add_child(l)
	return l

# 도트·대역 그림(S30). 컨테이너 안이면 size가 최소 크기다
func _pic(parent: Control, tex: Texture2D, size: Vector2) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.custom_minimum_size = size
	r.size = size
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	parent.add_child(r)
	return r

# 상태 묶음(S190): 1줄 거점 그림·체력 막대·숫자·마을 레벨, 2줄 동전·골드·세금·깃발·라운드. 누르면 카메라가 거점으로(I164)
func _make_status() -> void:
	var s := _cell("status", _bar_button(bar, "", func(): _focus(Vector2(battle.base.cell))))
	s.add_theme_stylebox_override("normal", StyleBoxEmpty.new())  # 띠 바탕 위에 테두리 없이. 올리면 테두리가 보인다
	var rows := []
	for y in [0, 12]:
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 2)
		r.position = Vector2(1, y)
		r.size = Vector2(94, 12)
		s.add_child(r)
		rows.append(r)
	_pic(rows[0], HudBuild.icon("base"), Vector2(10, 10))
	var back := ColorRect.new()
	back.color = HudTheme.CELL
	back.custom_minimum_size = Vector2(48, 5)
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rows[0].add_child(back)
	hp_bar.size = Vector2(48, 5)
	back.add_child(hp_bar)
	_hp = _text(rows[0], 9, HudTheme.TEXT)
	_lv = _text(rows[0], 7, HudTheme.DIM)
	_pic(rows[1], HudBuild.dots(COIN, {"#": HudTheme.ACCENT, "o": Color("b08a3a")}), Vector2(6, 6))
	_gold = _text(rows[1], 10, HudTheme.TEXT)
	_tax = _text(rows[1], 8, HudTheme.GOOD)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows[1].add_child(gap)
	_pic(rows[1], HudBuild.dots(FLAG, {"|": HudTheme.DIM, "#": HudTheme.DANGER}), Vector2(6, 6))
	_round = _text(rows[1], 9, HudTheme.TEXT)
	tip.add(s, func(): return ["거점 %d/%d" % [ceili(battle.base.hp), ceili(battle.base.max_hp)], "", "",
		"0이 되면 도전 끝 · 마을 Lv%d · 다음 준비 단계 세금 +%d · 라운드 %d/%d — 누르면 카메라가 거점으로 간다" % [battle.village_level, battle.tax(), battle.round_index + 1, battle.rounds.size()], ""])

# 상태 묶음 글과 거점 체력 막대(S190): 줄면 FLASH초 하얗고, 50% 밑 노랑, 25% 밑 빨강
func _show_status(delta: float, round_no: int) -> void:
	var hp: float = battle.base.hp
	if hp < _hp_seen:
		_flash = FLASH
	_hp_seen = hp
	_flash = maxf(_flash - delta, 0.0)
	var r: float = clampf(hp / battle.base.max_hp, 0.0, 1.0)
	hp_bar.size.x = 48.0 * r
	hp_bar.color = Color.WHITE if _flash > 0.0 else HudTheme.DANGER if r < 0.25 else HudBuild.WARN if r < 0.5 else HudTheme.GOOD
	_hp.text = str(ceili(hp))
	_lv.text = "Lv%d" % battle.village_level
	_gold.text = str(battle.gold)
	_tax.text = "+%d" % battle.tax()
	_round.text = "%d/%d" % [round_no, battle.rounds.size()]

# 진행 칸(S185): 준비 단계 금색 «▶ 전투 시작»과 다음 웨이브 버튼, 그 밖에는 칸 전체가 웨이브 버튼 하나다(I13)
func _make_progress() -> void:
	var p := _cell("progress", Control.new())
	start = _bar_button(p, "", _start_battle)
	start.size = Vector2(84, 24)
	for st in ["normal", "hover", "pressed", "hover_pressed"]:
		start.add_theme_stylebox_override(st, HudTheme.box(st, "Button", Color("3d3218") if st == "normal" else Color("5a4a22"), HudTheme.ACCENT))
	_pic(start, HudBuild.dots(PLAY, {"#": HudTheme.ACCENT}), Vector2(4, 7)).position = Vector2(6, 8)
	var go := _text(start, 9, HudTheme.ACCENT)
	go.text = "전투 시작"
	go.position = Vector2(14, 1)
	go.size = Vector2(68, 12)
	var key := _text(start, 7, HudTheme.DIM)
	key.text = "Enter"
	key.position = Vector2(14, 12)
	key.size = Vector2(68, 11)
	tip.add(start, func(): return ["전투 시작", "Enter", "", "웨이브 %d/%d를 부른다" % [battle.wave_index + 1, battle.waves.size()], ""])
	gauge = _bar_button(p, "", _to_enemy)
	_g1 = _text(gauge, 7, HudTheme.DIM)
	_g2 = _text(gauge, 9, HudTheme.TEXT)
	_dots = _pic(gauge, null, Vector2.ZERO)
	skull = _pic(gauge, HudBuild.dots(SKULL, {"#": HudTheme.DANGER}), Vector2(7, 7))
	moon = _pic(gauge, HudBuild.dots(MOON, {"#": MOON_COLOR}), Vector2(7, 7))
	_track.color = HudTheme.LINE
	gauge.add_child(_track)
	_fill.color = HudTheme.DANGER
	_track.add_child(_fill)
	tip.add(gauge, _wave_tip)

# 진행 칸 글과 자리(I13, S188)
func _show_progress() -> void:
	var st: String = battle.state
	var nw := _next_wave()
	if st != _laid:  # 단계가 바뀔 때만 자리·글꼴을 다시 정한다
		_laid = st
		start.visible = st == "prep"
		gauge.position.x = 86 if start.visible else 0
		gauge.size = Vector2(136 - gauge.position.x, 24)
		_track.visible = st == "battle"
		_dots.visible = st in ["prep", "battle"]
		_g2.visible = st not in ["battle", "won", "lost"]
		match st:
			"prep":
				_line(_g1, 7, HudTheme.DIM, Rect2(3, 1, 26, 11))
				_line(_g2, 9, HudTheme.TEXT, Rect2(3, 12, 32, 11))
				skull.position = Vector2(38, 14)
			"battle":
				_line(_g1, 10, HudTheme.TEXT, Rect2(4, 1, 90, 13))
				_track.position = Vector2(4, 17)
				_track.size = Vector2(128, 3)
			"hiring", "cleared":
				_line(_g1, 9, HudTheme.TEXT, Rect2(4, 1, 60, 11))
				_line(_g2, 8, HudTheme.DIM, Rect2(4, 12, 80, 11))
				skull.position = Vector2(124, 14)
			_:
				_line(_g1, 10, HudTheme.ACCENT if st == "won" else HudTheme.DANGER, Rect2(4, 1, 128, 22))
	skull.visible = st != "battle" and _boss(nw)
	match st:
		"prep":
			_g1.text = "웨이브"
			_g2.text = "적 %d" % _total(nw)
		"battle":
			_g1.text = "남은 적 %d" % battle.enemies_left()
			_fill.size = Vector2(128.0 * (1.0 - float(battle.enemies_left()) / maxi(_total([battle.round_index, battle.wave_index]), 1)), 3)
		"hiring", "cleared":
			_g1.text = "영입"
			_g2.text = "다음 적 %d" % _total(nw)
		_:
			_g1.text = {"won": "승리", "lost": "패배"}[st]
	if _dots.visible:
		_dots.texture = _wave_dots(battle.waves.size(), battle.wave_index)
		_dots.size = _dots.texture.get_size()
		_dots.position = Vector2(gauge.size.x - _dots.size.x - 4, 5)
	moon.visible = _night([battle.round_index, battle.wave_index] if st == "battle" else nw)  # S214
	moon.position = Vector2(_dots.position.x - 10, 3) if st == "battle" else skull.position + Vector2(9 if skull.visible else 0, 0)

func _line(l: Label, font: int, color: Color, at: Rect2) -> void:
	l.add_theme_font_size_override("font_size", font)
	l.add_theme_color_override("font_color", color)
	l.position = at.position
	l.size = at.size

# 웨이브 점: 지난 웨이브는 채움, 지금 웨이브는 강조색, 남은 웨이브는 테두리(ui_research 4.6)
func _wave_dots(n: int, now: int) -> Texture2D:
	var k := "%d/%d" % [n, now]
	if not _dot_tex.has(k):
		var rows := ["", "", ""]
		for i in n:
			var c := "#" if i < now else ("c" if i == now else "o")
			var gap := "" if i == 0 else "."
			rows[0] += gap + c + c + c
			rows[1] += gap + (c + "." + c if c == "o" else c + c + c)
			rows[2] += gap + c + c + c
		_dot_tex[k] = HudBuild.dots(rows, {"#": HudTheme.TEXT, "c": HudTheme.ACCENT, "o": HudTheme.DIM})
	return _dot_tex[k]

# 진행 칸이 보이는 웨이브 [라운드, 웨이브](S188): 준비 단계는 곧 부를 웨이브, 전투 단계는 그다음, 영입·라운드 사이는 다음 라운드 첫 웨이브. 없으면 []
func _next_wave() -> Array:
	match battle.state:
		"prep":
			return [battle.round_index, battle.wave_index]
		"battle":
			return [battle.round_index, battle.wave_index + 1] if battle.wave_index + 1 < battle.waves.size() else []
		"hiring":
			return [battle.round_index, 0]
		"cleared":
			return [battle.round_index + 1, 0]
	return []

func _total(rw: Array) -> int:
	return battle.rounds[rw[0]][rw[1]].reduce(func(n, e): return n + e.count, 0)

func _boss(rw: Array) -> bool:
	return not rw.is_empty() and battle.rounds[rw[0]][rw[1]].any(func(e): return battle.ENEMY_KINDS[e.kind].boss)  # 보스 표시(I185)

# 그 웨이브 [라운드, 웨이브]가 밤 웨이브다(S210, S214)
func _night(rw: Array) -> bool:
	return not rw.is_empty() and not battle.night(rw[0], rw[1]).is_empty()

# 출현 지점마다 «왼쪽 — 기본 3 · 빠름 2», 그 아래 웨이브에 든 종류마다 특성 한 줄(S188)
func _wave_lines(rw: Array) -> String:
	var counts: Array = battle.spawn_counts(rw[0], rw[1])
	var lines := []
	var kinds := {}
	for i in counts.size():
		lines.append("%s — %s" % [SIDES[i] if i < SIDES.size() else str(i + 1), " · ".join(counts[i].keys().map(func(k): return "%s %d" % [ENEMIES[k], counts[i][k]]))])
		kinds.merge(counts[i])
	lines.append_array(kinds.keys().filter(func(k): return TRAITS.has(k)).map(func(k): return "%s: %s" % [ENEMIES[k], TRAITS[k]]))
	if _night(rw):  # S214
		lines.append(tr("밤 — 전투 %d초에 해가 진다") % int(battle.night(rw[0], rw[1]).get("at", 0.0)))
	return "\n".join(lines)

# 웨이브 버튼 툴팁(S188): 준비 단계는 곧 부를 웨이브, 전투 단계는 그다음 웨이브, 영입·라운드 사이는 다음 라운드 첫 웨이브의 출현 지점별 구성
func _wave_tip() -> Array:
	var nw := _next_wave()
	match battle.state:
		"prep":
			return ["웨이브 %d/%d" % [battle.wave_index + 1, battle.waves.size()], "", "", _wave_lines(nw), ""]
		"battle":
			return ["남은 적 %d" % battle.enemies_left(), "", "", ("다음 웨이브\n" + _wave_lines(nw) if not nw.is_empty() else "이 라운드의 마지막 웨이브") + "\n누르면 거점에 가장 가까운 적을 비춘다", ""]
		"hiring", "cleared":
			return ["다음 라운드 첫 웨이브", "", "", _wave_lines(nw), ""]
	return [{"won": "승리", "lost": "패배"}[battle.state], "", "", "", ""]

# 전투 중 진행 칸을 누르면 거점에 가장 가까운 적에게 카메라가 간다(I13, I164)
func _to_enemy() -> void:
	var foes: Array = battle.enemies.filter(func(e): return battle.seen(e.pos))  # 어둠 속에 숨은 적(S213)은 비추지 않는다
	if battle.state != "battle" or foes.is_empty():
		return
	var keep := Vector2(battle.base.cell)
	_focus(foes.reduce(func(a, e): return e if e.pos.distance_to(keep) < a.pos.distance_to(keep) else a).pos)

# 아래 가장자리 표식(S188): 출현 지점마다 검은 바탕에 아래 화살표와 수
func _make_edges(root: Control) -> void:
	edges.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(edges)
	for c in battle.spawns:
		var m := Panel.new()
		m.add_theme_stylebox_override("panel", HudTheme.box("panel", "PanelContainer", Color.BLACK, HudTheme.DIM))
		m.size = Vector2(22, 12)
		edges.add_child(m)
		_pic(m, HudBuild.dots(ARROW), Vector2(5, 5)).position = Vector2(3, 4)
		var l := _text(m, 8, HudTheme.TEXT)
		l.position = Vector2(9, 0)
		l.size = Vector2(12, 12)
		for n in [m] + m.get_children():
			n.mouse_filter = Control.MOUSE_FILTER_IGNORE

# 준비 단계에 화면(VIEW) 밖 출현 지점의 표식을 그 x에 맞춰 아래 가장자리에 둔다. 선택 패널(S206)과 겹치는 표식은 패널 바로 위로 올린다(S188)
func _show_edges() -> void:
	edges.visible = battle.state == "prep"
	if not edges.visible:
		return
	var counts: Array = battle.spawn_counts(battle.round_index, battle.wave_index)
	for i in battle.spawns.size():
		var m: Control = edges.get_child(i)
		var at: Vector2 = map.get_canvas_transform() * ((Vector2(battle.spawns[i]) + Vector2(0.5, 0.5)) * BattleView.CELL)
		m.visible = not VIEW.has_point(at)
		m.get_child(1).text = str(counts[i].values().reduce(func(n, x): return n + x, 0))
		m.position = Vector2(clampf(at.x - m.size.x / 2, EDGE_X.x, EDGE_X.y - m.size.x), 344)
		if select.visible and m.position.x + m.size.x > select.position.x:
			m.position.y = select.position.y - 2 - m.size.y

# 임무 칸의 점(I122): 조건을 지키는 중이면 흰 점, 깨졌으면 빨간 ✕, 없으면 비운다. 깨지는 순간 토스트를 띄운다
func _show_quests() -> void:
	for i in 2:
		var name: String = [battle.mission, battle.commission][i]
		marks[i].visible = name != ""
		if name == "":
			continue
		var ok: bool = battle.quest_met(name)
		marks[i].texture = _dot if ok else _cross
		marks[i].modulate = Color.WHITE if ok else HudTheme.DANGER
		if _ok.get(name, true) and not ok:
			toasts.push("%s 실패: %s" % [["미션", "의뢰"][i], battle.QUEST_KINDS[name].text])
		_ok[name] = ok

# 놀고 있는 공병(engineer_gap과 같은 기준, I128)
func _idle() -> Array:
	return battle.units.filter(func(u): return u.kind == "engineer" and u.job == null)

# 공병 칸(S185): 놀고 있는 공병에게 차례로 카메라를 옮긴다
func _next_engineer() -> void:
	var idle := _idle()
	if not idle.is_empty():
		_eng_next = (_eng_next + 1) % idle.size()
		_focus(idle[_eng_next].pos)

# 칸 좌표(소수 가능) p의 가운데로 카메라를 미끄러지게 옮긴다(I164)
func _focus(p: Vector2) -> void:
	map.get_camera_2d().slide((p + Vector2(0.5, 0.5)) * BattleView.CELL)

func _start_battle() -> void:
	controls.placing = ""
	battle.start_battle()

# 결과 창의 버튼(S117): 영입 창이면 1라운드나 다음 라운드로, 도전이 끝났으면 새 도전을 시작한다. main이 Enter로도 부른다(I94)
func proceed() -> void:
	if battle.hiring_open():
		battle.next_round()
	elif battle.state in ["won", "lost"]:
		_restart()

# 결과 창 안의 버튼. 키보드 포커스를 받아 방향키로 옮기고 Enter로 누른다(I12, I110)
func _window_button(parent: Control, on_press: Callable) -> Button:
	var b := _button(parent, "", on_press)
	b.focus_mode = Control.FOCUS_ALL
	b.gui_input.connect(_refocus)
	return b

# 창 버튼을 마우스로 누른 뒤 포커스를 진행 버튼에 돌려준다. 안 그러면 Enter가 방금 누른 리롤·내보내기를 다시 누른다(I110)
func _refocus(e: InputEvent) -> void:
	if e is InputEventMouseButton and not e.pressed:
		_next.grab_focus.call_deferred()

# 영입 칸(I110): 골드·보유·출전 수, 목록 칸마다 영웅 이름(역할)·등급·영입 비용, 리롤, 보유 영웅마다 출전·대기와 내보내기
func _show_hire() -> void:
	var hire = battle.HIRE
	_hire_info.text = "골드 %d · 보유 %d/%d · 출전 %d/%d" % [battle.gold, battle.roster.size(), hire.cap, battle.lineup.size(), hire.lineup]
	if battle.state == "hiring":  # 도전 시작 전에는 지을 골드를 남기라고 알린다(O-1)
		_hire_info.text += " · 준비 단계에 지을 골드도 남긴다"
	var full: bool = battle.roster.size() >= hire.cap
	for i in _offers.size():  # 영입 카드(I110): 영입한 칸은 초상을 흐리게 «영입함», 골드가 모자라면 비용만 빨강
		var k: String = battle.offers[i]
		var card: Button = _offers[i]
		var cost: Label = card.get_child(0)
		if k != "":
			_offer_kinds[i] = k
		var was: String = _offer_kinds[i]
		card.icon = _face(was) if was != "" else null
		card.disabled = k == "" or full
		cost.visible = k != ""
		if k == "":
			card.text = ("%s — 영입함" % HEROES[was]) if was != "" else "영입함"
			continue
		var grade: int = battle.HERO_KINDS[k].grade
		card.text = "%s «%s» · %s" % [HEROES[k], battle.HERO_KINDS[k].title, GRADES[grade - 1]]  # 이명(S157)
		cost.text = str(hire.cost[grade - 1])
		cost.add_theme_color_override("font_color", HudTheme.DANGER if battle.gold < hire.cost[grade - 1] else HudTheme.TEXT)
	_reroll.text = "리롤 %d골드" % hire.reroll
	_reroll.disabled = battle.gold < hire.reroll and not full
	_reroll.modulate.a = 0.35 if full else 1.0  # 상한이면 흐리게 두고 누르면 이유를 보인다(I127)
	if not full:
		_note.text = ""
	_note.visible = _note.text != ""
	for i in _members.size():  # 보유 칸은 빈 칸도 자리를 지킨다(I136)
		var here: bool = i < battle.roster.size()
		_members[i][0].disabled = not here
		_members[i][1].visible = here
		_members[i][2].visible = here
		if not here:
			_members[i][0].text = "빈 자리"
			_members[i][0].button_pressed = false
		else:
			var h = battle.roster[i]
			var out: bool = h in battle.lineup
			_members[i][0].text = "%s · %s · %s · %s" % [HEROES[h.kind], GRADES[h.grade - 1], _level(h), "출전" if out else "대기"]
			_members[i][0].button_pressed = out
			_members[i][0].disabled = not out and battle.lineup.size() >= hire.lineup
			_members[i][1].text = "내보내기"
			_members[i][2].visible = battle.state == "cleared"  # 이관은 라운드 사이에만(S127)
			_members[i][2].text = "이관" if _giver == null else ("취소" if _giver == h else "여기로")
			_members[i][2].disabled = (_giver == null and h.xp == 0) or (_giver not in [null, h] and not battle.can_transfer(_giver, h))  # 넘치는 이관은 «여기로»를 끈다(I116)
	_quests.visible = battle.state == "cleared" and not battle.commission_offers.is_empty()  # 의뢰는 라운드 사이에만(I121)
	for i in _commissions.size():
		var here: bool = i < battle.commission_offers.size()
		_commissions[i].visible = here
		if here:
			var q: Dictionary = battle.QUEST_KINDS[battle.commission_offers[i]]
			var on: bool = battle.commission == battle.commission_offers[i]
			_commissions[i].text = "%s · +%d골드 · %s" % [q.text, q.reward, "수락함 (다시 누르면 무름)" if on else "수락"]

# 영입 카드(I110): 초상·이름(역할)·이명·등급, 오른쪽에 비용 숫자. 툴팁은 누르면 생기는 일과 모자란 조건만
func _card(parent: Control, i: int) -> Button:
	var b := _window_button(parent, func(): battle.hire(i))
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_constant_override("icon_max_width", 16)
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var cost := _text(b, 10, HudTheme.TEXT)
	cost.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	cost.offset_left = -40
	cost.offset_right = -4
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip.add(b, func(): return ["영입", "", "", "누르면 보유에 넣고 빈 출전 자리에 든다", _offer_why(i)])
	return b

func _offer_why(i: int) -> String:
	var k: String = battle.offers[i]
	if k == "":
		return ""
	if _cap_note() != "":
		return _cap_note()
	var cost: int = battle.HIRE.cost[battle.HERO_KINDS[k].grade - 1]
	return "골드 %d 모자람" % (cost - battle.gold) if battle.gold < cost else ""

# 이관 버튼 툴팁(I110, I116): 버튼 글(이관·여기로·취소)마다 누르면 생기는 일과 못 누르는 이유
func _give_tip(i: int) -> Array:
	if i >= battle.roster.size():
		return ["", "", "", "", ""]
	var h = battle.roster[i]
	if _giver == null:
		return ["이관", "", "", "경험치를 모두 다른 영웅에게 옮긴다 · 이 영웅은 Lv1로", "경험치가 없다" if h.xp == 0 else ""]
	if _giver == h:
		return ["취소", "", "", "이관을 그만둔다", ""]
	return ["여기로", "", "", "이 영웅이 경험치를 받는다", "" if battle.can_transfer(_giver, h) else "받으면 레벨 상한을 넘는다"]

# 보유가 상한이면 영입할 수 없는 이유(I127). 아니면 ""
func _cap_note() -> String:
	return "보유 %d/%d — 내보내야 영입할 수 있다" % [battle.roster.size(), battle.HIRE.cap] if battle.roster.size() >= battle.HIRE.cap else ""

# 리롤(I127): 상한이면 리롤해도 영입하지 못해 거부하고 이유를 창에 보인다
func _reroll_press() -> void:
	if _cap_note() != "":
		_note.text = _cap_note()
	else:
		battle.reroll()

# 영입 카드의 영웅 초상 대역(S30). 출전 칸·치료 버튼과 같은 _faces 사전을 쓴다
func _face(kind: String) -> Texture2D:
	if not _faces.has(kind):
		_faces[kind] = HudBuild.icon(kind)
	return _faces[kind]

# ESC 메뉴가 열리면 건설 격자·정보 칸·태그를 숨긴다(S183). 멈춘 동안 HUD가 돌지 않아 main이 부르고, 메뉴가 닫히면 다음 _process가 다시 보인다
func cover() -> void:
	grid.visible = false
	for t in tags:
		t.visible = false

# 미션·수락한 의뢰 줄(I122): «미션: 조건 (+N골드)»와 «의뢰: 조건 (+N골드)». 조건이 깨졌으면 «— 실패»를 붙인다(I131)
func _quest_lines() -> Array:
	var out := []
	for pair in [["미션", battle.mission], ["의뢰", battle.commission]]:
		if pair[1] != "":
			var q: Dictionary = battle.QUEST_KINDS[pair[1]]
			out.append("%s: %s (+%d골드)" % [pair[0], q.text, q.reward] + ("" if battle.quest_met(pair[1]) else " — 실패"))
	return out

# 출전 영웅 칸(I129, I151): 준비·전투 단계에 칸 셋이 늘 보이고, 빈 칸은 점선 테두리다. 초상(체력 LOW 밑이면 빨간 맥박, 쓰러지면 회색)·레벨,
# 스킬 칸 상태, 체력·마나 막대. 쓰러졌으면 스킬 칸 대신 «쓰러짐». 준비 단계 스킬 칸의 모래시계가 «스킬은 전투 단계에만»을 대신한다(S136)
func _show_heroes() -> void:
	var on: bool = battle.state in ["prep", "battle"]
	for i in _rows.size():
		var row: Dictionary = _rows[i]
		var cell: Control = cells["hero%d" % i]
		var h = battle.heroes[i] if i < battle.heroes.size() else null
		cell.visible = on
		cell.queue_redraw()
		for n in cell.get_children():
			n.visible = h != null
		if not on or h == null:
			continue
		if not _faces.has(h.kind):
			_faces[h.kind] = HudBuild.icon(h.kind)
		row.pic.texture = _faces[h.kind]
		var pulse := 0.5 + 0.5 * sin(_now * TAU * 2.0)
		row.pic.modulate = Color(0.4, 0.4, 0.4) if not h.alive else Color.WHITE.lerp(HudTheme.DANGER, pulse) if h.hp < h.max_hp * LOW else Color.WHITE
		row.lv.text = str(h.level)
		var r: float = clampf(h.hp / h.max_hp, 0.0, 1.0)
		row.hp.size.x = 75.0 * r
		row.hp.color = HudTheme.DANGER if r < 0.25 else HudBuild.WARN if r < 0.5 else HudTheme.GOOD
		row.mp.size.x = 75.0 * clampf(h.mana / maxf(h.max_mana, 1.0), 0.0, 1.0)
		row.down.visible = not h.alive
		for slot in battle.SLOTS:
			slots[i][slot].visible = h.alive
			slots[i][slot].show_state(_slot_state(h, slot))

# 빈 출전 칸은 점선 테두리로 자리를 지킨다(I129)
func _empty_slot(cell: Control, i: int) -> void:
	if i < battle.heroes.size():
		return
	var r := Rect2(Vector2(0.5, 0.5), cell.size - Vector2.ONE)
	var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	for k in 4:
		cell.draw_dashed_line(corners[k], corners[(k + 1) % 4], HudTheme.LINE, 1.0, 3.0)

# 초상 툴팁(I129): 이름(역할)·F키, 레벨·체력·마나 수치. 쓰러졌으면 빨간 줄에 돌아오는 때(I28·I93)
func _hero_tip(i: int) -> Array:
	var h = battle.heroes[i]
	var back := "" if h.alive else "쓰러짐 — " + ("다음 준비 단계에 복귀" if battle.revive else "다음 라운드에 복귀")
	return [HEROES[h.kind], "F%d" % (i + 1), "", "Lv%d · 체력 %d/%d · 마나 %d/%d\n누르면 고름 · 두 번이면 카메라" %[h.level, ceili(h.hp), ceili(h.max_hp), floori(h.mana), ceili(h.max_mana)], back]

# F키·초상을 DOUBLE초 안에 두 번 누르면 카메라가 그 영웅에게 간다(I165, I164)
func _tap(i: int) -> void:
	var again: bool = _now - _taps.get(i, -INF) <= DOUBLE
	_taps[i] = -INF if again else _now
	if again and i < battle.heroes.size():
		_focus(battle.heroes[i].pos)

# 스킬 칸 좌클릭(I151): 그 칸 키와 같다. 준비 단계이거나 마나가 모자라면 거부 표시와 토스트(I163)
func _skill_press(i: int, slot: String) -> void:
	if i >= battle.heroes.size():
		return
	_skill_refuse(battle.heroes[i], slot)
	controls.skill_for(battle.heroes[i], slot)

# 영웅 h가 칸 slot을 못 쓰면 그 칸 테두리를 번쩍이고 이유 토스트(I151). 차례는 준비 단계 → 재사용 대기 → 마나, 잠긴 칸은 조용히. Q·W·E·R 키도 온다
func _skill_refuse(h, slot: String) -> void:
	var i: int = battle.heroes.find(h)
	var sk: Dictionary = h.get(slot)
	var why := ""
	if battle.state != "battle":
		why = "스킬은 전투 단계에만"
	elif sk.is_empty() or h.level < battle.LEVELS.unlock[slot] or (sk.get("id") == "brace" and h.brace > 0.0) or (sk.get("aim") == "toggle" and h.toggle):  # 태세 중인 반격은 터뜨리고(S151) 켜진 토글은 끈다(S153)
		why = ""
	elif h.cd[slot] > 0.0:
		why = "재사용 대기 %d초" % ceili(h.cd[slot])
	elif h.mana < sk.mana:
		why = "마나 %d 더 필요" % ceili(sk.mana - h.mana)
	if why != "" and i >= 0:
		slots[i][slot].reject()
		toasts.push(why)

# 스킬 버튼 우클릭: 그 칸의 자동 시전을 켜고 끈다(S158, I151)
func _auto_click(e: InputEvent, i: int, slot: String) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_RIGHT and e.pressed and i < battle.heroes.size():
		battle.toggle_auto(battle.heroes[i], slot)

# 칸 하나의 상태(I151, skill_cell.gd의 show_state)
func _slot_state(h, slot: String) -> Dictionary:
	var sk: Dictionary = h.get(slot)
	return {"letter": slot.to_upper(), "cd": h.cd[slot], "gap": sk.gap, "mana": h.mana < sk.mana, "lock": h.level < battle.LEVELS.unlock[slot],
		"auto": h.auto and sk.get("auto", false), "aim": controls.aiming == slot and controls.aim_hero == h, "on": h.toggle and sk.get("aim") == "toggle",
		"prep": battle.state == "prep", "now": _now}

# 4.0 → «4», 1.5 → «1.5»
func _num(x: float) -> String:
	return str(int(x)) if x == roundf(x) else str(x)

# 스킬 버튼 툴팁(S187): 이름·키·마나, 요약·재사용 대기 초·자동 시전, 못 쓰는 이유 하나(S145 해금 > S136 단계 > 마나 > 대기)
func _skill_tip(i: int, slot: String) -> Array:
	var h = battle.heroes[i]
	var sk: Dictionary = h.get(slot)
	var name_about: Array = SKILLS[h.kind][battle.SLOTS.find(slot)]
	var why := ""
	if h.level < battle.LEVELS.unlock[slot]:
		why = "Lv%d에 열림" % battle.LEVELS.unlock[slot]
	elif battle.state != "battle":
		why = "스킬은 전투 단계에만"
	elif h.mana < sk.mana:
		why = "마나 %d 모자람" % ceili(sk.mana - h.mana)
	elif h.cd[slot] > 0.0:
		why = "재사용 대기 %d초" % ceili(h.cd[slot])
	var about := "%s · 재사용 %s초" % [name_about[1], _num(sk.gap)] + (" · 우클릭: 자동 시전" if sk.get("auto", false) else "")
	return [name_about[0], slot.to_upper(), "마나 %d" % sk.mana, about, why]

# 고른 것의 칸에 공병 지시를 맡을 공병이 없는 이유(I128). live()가 아니거나 고른 것이 없으면 ""
# ponytail: 닿는지 보는 A*가 무거워(성문이 모두 닫히면 1회 7ms) 같은 칸이면 0.3초마다만 다시 잰다. 그사이 바뀐 공병 사정은 늦게 보인다
func _engineer_gap(cells: Array) -> String:
	if not battle.live() or cells.is_empty():
		return ""
	if cells != _gap_for or Time.get_ticks_msec() - _gap_at > 300:
		_gap = battle.engineer_gap(cells)
		_gap_for = cells
		_gap_at = Time.get_ticks_msec()
	return _gap

# 레벨과 경험치(I117): «Lv2 35/50»(다음 레벨의 누적 경험치까지). 최대 레벨이면 «Lv5 최대»
func _level(h) -> String:
	var steps: Array = battle.LEVELS.steps
	if h.level > steps.size():
		return "Lv%d 최대" % h.level
	return "Lv%d %d/%d" % [h.level, h.xp, steps.slice(0, h.level).reduce(func(s, x): return s + x, 0)]

# 이관(S127, I116): 주는 영웅의 «이관»을 누른 뒤 받는 영웅의 «여기로»를 누른다. 주는 영웅을 다시 누르면 그만둔다
func _give(h) -> void:
	if _giver == null:
		_giver = h
	elif _giver == h:
		_giver = null
	else:
		battle.transfer(_giver, h)
		_giver = null

# 고른 유닛·놓기 모드도 비운다. 재시작 뒤의 영웅은 새 객체다. 새 도전도 영입 창에서 시작한다(S122)
func _restart() -> void:
	battle.restart()
	battle.begin_hiring()
	controls.selected = []
	controls.selling = []
	controls.placing = ""
	controls.facility = null
	controls.picked = []
	controls.fort = null
	controls.village = false

# 고른 구조물마다 f를 부르고 팝업을 닫는다
func _apply(f: Callable, things: Array) -> void:
	for t in things:
		f.call(t)
	controls.selling = []
	controls.picked = []

# 고른 것 가운데 고칠 수 있는 것(S116, I90): 판매·철거 후보, 고른 성곽 칸, 고른 거점
func _to_repair() -> Array:
	var all: Array = controls.selling + controls.picked + ([controls.fort] if controls.fort else []) + ([battle.base] if controls.village else [])
	return all.filter(battle.can_repair)

# 고른 구조물 가운데 옮길 수 있는 첫 대포(S44)
func _cannon():
	for s in controls.picked:
		if s.kind == "cannon" and battle.can_demolish(s):
			return s
	return null

func _start_move() -> void:
	controls.moving = _cannon()
	controls.picked = []

# 팔린 용병은 고른 상태에서도 뺀다
func _sell_now() -> void:
	battle.sell(controls.selling)
	controls.selling = []
	controls.selected = controls.selected.filter(func(u): return u.alive)
