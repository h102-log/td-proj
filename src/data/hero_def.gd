class_name HeroDef
extends Resource
# 영웅 종류 하나의 수치(S31, I95). data/heroes/<종류>.tres, 파일 이름이 종류 이름이다(I66)
# 스킬·오라 수치는 S97 표, 기본 능력치는 S121 표의 임시값이다. 0인 효과는 그 영웅에게 없다

@export var grade := 1  # 등급(S94): 1 동 · 2 은 · 3 금
@export var hp := 0.0
@export var radius := 0.3  # 몸 반지름(칸, I51)
@export var speed := 0.0
@export var damage := 0.0
@export var range := 0.0  # 사거리(칸)
@export var attack_gap := 1.0  # 공격 간격(초)
# Q(S95, I98): 주변 skill_radius칸, 재사용 대기 skill_gap초. 적 피해·기절(초), 영웅·용병 회복, 구조물·성곽 칸 회복(S120)
@export var skill_radius := 0.0
@export var skill_gap := 0.0
@export var skill_damage := 0.0
@export var skill_stun := 0.0
@export var skill_heal := 0.0
@export var skill_mend := 0.0
# W(S84, I97, I99): 쓴 순간 주변 buff_radius칸 안의 대상에게 buff_time초, 재사용 대기 buff_gap초.
# 용병 공격력 ×buff_mult, 적이 받는 피해 +buff_expose, 아군이 받는 피해 −buff_guard, 구조물·성곽 칸이 받는 피해 −buff_ward, 적 이동 속도 −buff_slow
@export var buff_radius := 0.0
@export var buff_time := 0.0
@export var buff_gap := 0.0
@export var buff_mult := 1.0
@export var buff_expose := 0.0
@export var buff_guard := 0.0
@export var buff_ward := 0.0
@export var buff_slow := 0.0
# 오라(S96, I100): 살아 있는 동안 반경 aura_radius칸 안에 늘. 용병이 받는 피해 −aura_guard(I82), 원거리 아군 공격 속도 +aura_haste,
# 공병 일 속도 +aura_work, 용병 체력 초당 +aura_regen, 용병 공격력 +aura_might·이동 속도 +aura_stride, 쏘는 구조물 피해 +aura_gunnery
@export var aura_radius := 0.0
@export var aura_guard := 0.0
@export var aura_haste := 0.0
@export var aura_work := 0.0
@export var aura_regen := 0.0
@export var aura_might := 0.0
@export var aura_stride := 0.0
@export var aura_gunnery := 0.0
