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
