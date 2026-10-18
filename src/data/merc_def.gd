class_name MercDef
extends Resource
# 용병 종류 하나의 수치(S31). data/mercs/<종류>.tres, 파일 이름이 종류 이름이다(I66)
# ponytail: 수치는 임시값이다. soldier의 range 1.2는 옆 칸(1)의 적을 치는 근접(EV26). 종류·밸런스는 3.1(I34)에서
# 공병(engineer)은 공격하지 않는다(I63). 공격력·사거리·인식 범위 0

@export var cost := 0  # soldier 20은 임시값(사용자 2026-10-12)
@export var hp := 0.0
@export var radius := 0.3  # 몸 반지름(칸, I51)
@export var speed := 0.0
@export var damage := 0.0
@export var range := 0.0  # 사거리(칸). 0보다 커야 적을 친다
@export var attack_gap := 1.0  # 공격 간격(초)
@export var block := 1  # 블록 수(S159): 동시에 붙잡는 적 수. 임시값
@export var sight := 0.0  # 인식 범위(칸, I36)
@export var hold_radius := 0.0  # 홀드 반경(칸, I37)
