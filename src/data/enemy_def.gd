class_name EnemyDef
extends Resource
# 적 종류 하나의 수치(S31). data/enemies/<종류>.tres, 파일 이름이 종류 이름이다(I66)
# 수치는 임시값이다(S106, 3.1에서 정했다). 무시하는 판정 층은 flying·climb 가운데 하나뿐이다(S11, I80)

@export var hp := 0.0
@export var speed := 0.0
# ponytail: basic의 1.0은 가득 찬 방벽(100) 하나 = 100칸 걷기. EV6·9(돌아가기)와 EV7(뚫기)을 함께 넘는 임시값
@export var wall_k := 1.0  # 방벽을 뚫을지 돌아갈지 정하는 계수(S7, S34)
@export var damage := 0.0
@export var attack_gap := 1.0  # 공격 간격(초)
@export var radius := 0.3  # 몸 반지름(칸, I51)
@export var sight := 0.0  # 인식 범위(칸)
@export var reward := 0  # 처치 골드(I15). basic 5는 임시값(사용자 2026-10-12)
@export var xp := 1  # 처치되면 그때 살아 있는 출전 영웅이 저마다 받는 경험치(S125, S126). 임시값
@export var armor := 0.0  # 방어력. 받는 물리 피해를 워크3식 비율로 줄인다(S108, S149)
@export var flying := false  # 경로 층을 무시하고 대상으로 곧장 난다(S109, I79)
@export var climb := 0.0  # 성곽 성벽을 기어오르는 시간(초). 0이면 오르지 않는다(S107, I76)
@export var skills := {}  # 보스 스킬 이름 → 수치(S194, I169). slam 대지 강타·rage 분노(S195). 비어 있으면 스킬이 없다
@export var boss := false  # 보스 표시(I185). 체력바·미니맵 점·진행 칸 해골·실비아 R은 종류 이름 대신 이 칸으로 가른다
@export var split := {}  # 죽으면 갈라져 나올 {kind, count}(S234). count가 갈라지는 수의 손잡이다. 비어 있으면 갈라지지 않는다
@export var pack := 1  # 한 무리로 함께 나오는 마릿수(S238). 1이면 한 마리씩 나온다
@export var together := false  # 함께 나옴(S294): 참이면 웨이브의 이 종류는 모두 한 차례에 출현 지점마다 고르게 나뉘어 같은 순간 나온다. pack보다 우선한다
@export var vault := {}  # 도약(S239): {shove 밀어내는 칸, stun 기절 초, slow 뛴 뒤 둔화, slow_time 둔화 초}. 비어 있으면 성벽에 올라도 밀치지 않는다
@export var dash := {}  # 돌진(S293): {stride 돌진하는 동안의 이동 속도 배율}. 비어 있으면 웨이브에서 나와도 돌진하지 않는다
@export var night := {}  # 어둠에 세짐(S240): {stride 이동, haste 공격 속도}에 어둠을 곱해 더한다. 비어 있으면 어둠과 상관없다
@export var bleed := {}  # 물면 거는 출혈(S240): {dps 초당 물리 피해, time 초}. 비어 있으면 걸지 않는다
@export var siege := false  # 공성(S280~S282): 유닛·반격 대상·도발·마을 구조물을 노리지 않고 성문 → 거점만 노린다
@export var fuse := {}  # 폭파병 도화선(S280): {time 예고 초, radius 원 반경, structure 구조물 피해, unit 아군 피해}. 비어 있으면 치는 대신 터지지 않는다
@export var range := 0.0  # 멈춰서 행동하는 거리(칸, I216). 0이면 닿는 거리(1칸)에서 친다
@export var throw := {}  # 투석기 던지기(S282): {radius 원 반경, windup 예고 초, cd 대기 초, structure 구조물 피해, unit 아군 피해}
@export var ranged_cut := 0.0  # 투사체로 맞은 물리 피해를 이만큼 덜 받는다(I217). 봉인되면 꺼진다(S281)
@export var ignore_units := false  # 아군 몸에 막히지 않고 밀어낸다(I218). 봉인되면 꺼진다(S281)
@export var glide := 0.0  # 글라이더(S283, I220): 마을에 들어선 뒤 이만큼(칸) 더 날면 내려앉는다. 0이면 내려앉지 않는다
@export var ladder := {}  # 공성탑 사다리(S284): {windup 내리는 초, climb 오르는 초}. 비어 있으면 공성탑이 아니다
@export var cargo := 0  # 탄 고블린 수(S284 공성탑, S286 수송 비행선). 0이면 태우지 않는다
@export var bomb := {}  # 폭탄 열기구(S285): {radius 원 반경, windup 예고 초, cd 대기 초, structure 구조물 피해, unit 아군 피해}
@export var drop := {}  # 수송 비행선 투하(S286): {range 거점 둘레 칸, house 집 거리 칸, windup 표식 초, crash_hp 투하 전 격추 때 체력 배율}
@export var phase2 := ""  # 체력이 0이 되면 쓰러지지 않고 이 종류가 된다(S288 전쟁 기계 → 대장). 비어 있으면 쓰러진다
@export var guard := 0.0  # 방패 내구도(S301, I248): 궁수탑·궁수 용병의 화살 피해를 방어력보다 먼저 받는다. 라운드 체력 배율(S144)을 곱한다. 0이면 방패가 없다
@export var escort := {}  # 호위(S301, I248 ⑤): 웨이브에서 나올 때 한 차례에 함께 나오는 {kind, count}. 비어 있으면 혼자 나온다
@export var flame := {}  # 불화살(S302, I249): {windup 예고 초, cd 대기 초, hit 화살 피해, dps 불 초당 피해, time 불 초, spread 번지는 때(붙은 뒤 초)}
@export var feather := {}  # 깃털(S304, I250): {range 사거리 칸, speed 초당 칸}. 피해·쏘는 간격은 damage·attack_gap이다. 비어 있으면 쏘지 않는다
@export var dive := {}  # 박치기(S305, I251): {windup 예고 초, air 활강 초, cd 대기 초, damage 피해, radius 반경, push 미는 칸, stun 방패병에 박았을 때 기절 초, shields 방패병 종류}. 대상은 인식 범위 안이다
@export var song := {}  # 노래(S306, I252): {radius 반경, heal 초당 최대 체력 비율, lag 아군 공격 속도 감소}. 비어 있으면 노래하지 않는다
@export var gust := {}  # 돌풍(S307, I253): {range 멈추는 성곽 거리 칸, reach 부채꼴 반경 칸, arc 각도°, windup 예고 초, cd 끊긴 뒤 대기 초}. 비어 있으면 뿜지 않는다
@export var snatch := {}  # 낚아채기(S308, I254): {range 탐색 칸, reach 드는 거리 칸, toss 떨어뜨릴 자리 거리 칸, windup 예고 초, radius 원 반경, hit 아군 피해, structure 구조물 피해, fall 낙하 피해, pick 돌 줍기 초, cd 대기 초}. 비어 있으면 낚아채지 않는다
@export var nest := {}  # 둥지 짓기(S309, I255): {build 짓는 초, cd 끊긴 뒤 대기 초, kind 다 지으면 될 종류}. 비어 있으면 짓지 않는다
@export var brood := {}  # 새끼 낳기(S309, I255): {kind 새끼 종류, every 낳는 간격 초, cap 살아 있는 새끼 상한}. 비어 있지 않으면 둥지다(움직이지도 치지도 않는다)
@export var wall := {}  # 방패벽(S319, I263): {near 방패벽을 서는 거리 칸, cover 둘레 칸, cut 정면 화살·구슬 피해를 덜 받는 비율}. 비어 있으면 방패벽을 서지 않는다
@export var frenzy := {}  # 격노(S320, I264): {haste 공격 속도, stride 이동 속도}에 잃은 체력 비율을 곱해 더한다. 비어 있으면 격노하지 않는다
@export var drum := {}  # 전쟁 북(S321, I265): {radius 반경, haste 둘레 적 공격 속도, stride 둘레 적 이동 속도, keep 들을 적이 있을 때 대상에서 서는 거리 칸}. 비어 있으면 북을 치지 않는다
