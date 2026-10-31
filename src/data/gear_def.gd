class_name GearDef
extends Resource
# 영웅 전용장비 하나(S246, S249). data/gear/<영웅 종류>.tres, 파일 이름이 주인 영웅 종류다(I66). 수치는 임시값이다

@export var title := ""  # 장비 이름. 장비 탭 줄에 보인다(S248)
@export var steps := []  # 인덱스 = 강화 수치(+0부터). 칸마다 {"칸.키": 값}. 칸은 passive·aura·q·w·e·r라 레벨 몸 수치(hp·damage)는 못 바꾼다(I200)
@export var notes := []  # 같은 인덱스 단계의 효과 한 줄. 제작·강화 버튼 툴팁에 보인다(S248)
