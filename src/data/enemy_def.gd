class_name EnemyDef
extends Resource
# 적 종류 하나의 수치(S31). data/enemies/<종류>.tres, 파일 이름이 종류 이름이다(I66)
# ponytail: 수치는 임시값이다. 적 종류별 역할과 수치는 3.1(I34)에서 정한다

@export var hp := 0.0
@export var speed := 0.0
# ponytail: basic의 1.0은 가득 찬 방벽(100) 하나 = 100칸 걷기. EV6·9(돌아가기)와 EV7(뚫기)을 함께 넘는 임시값
@export var wall_k := 1.0  # 방벽을 뚫을지 돌아갈지 정하는 계수(S7, S34)
@export var damage := 0.0
@export var attack_gap := 1.0  # 공격 간격(초)
@export var radius := 0.3  # 몸 반지름(칸, I51)
@export var sight := 0.0  # 인식 범위(칸)
@export var reward := 0  # 처치 골드(I15). basic 5는 임시값(사용자 2026-10-12)
