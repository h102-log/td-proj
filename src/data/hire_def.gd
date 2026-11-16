class_name HireDef
extends Resource
# 영웅 고르기·장비·유물 수치(S123, S246, S334). data/hire.tres. lineup은 고르는 수 = 출전 인원이다(S373). 임시값이다

@export var lineup := 0  # 출전 인원 = 고르기 창에서 고르는 수(S123 2026-11-16 변경)
@export var gear_cost := []  # 전용장비 단계마다 비용(골드, S246). [0]이 제작(+0), [n]이 +n으로 강화. 장비 단계 수보다 짧으면 안 된다
@export var forge_cap := 0  # 라운드 사이 창 한 번에 장비 하나를 제작·강화하는 횟수(S246)
@export var relic_cost := []  # 유물 강화 단계마다 비용(골드, S334). [0]이 +1로 강화. 유물 단계 수 − 1보다 짧으면 안 된다
@export var relic_cap := 0  # 라운드 사이 창 한 번에 유물 하나를 강화하는 횟수(S334)
