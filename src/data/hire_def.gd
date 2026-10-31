class_name HireDef
extends Resource
# 영입소 수치(S123, I103). data/hire.tres. 등급마다 나뉜 값은 [1성, 2성, 3성] 순서다(S94). 임시값이다

@export var slots := 0  # 목록 칸 수
@export var odds := []  # 칸마다 그 등급이 나올 확률
@export var cost := []  # 영입 비용(골드)
@export var reroll := 0  # 리롤 비용(골드)
@export var cap := 0  # 보유 상한
@export var lineup := 0  # 출전 인원
@export var gear_cost := []  # 전용장비 단계마다 비용(골드, S246). [0]이 제작(+0), [n]이 +n으로 강화. 장비 단계 수보다 짧으면 안 된다
@export var forge_cap := 0  # 라운드 사이 창 한 번에 장비 하나를 제작·강화하는 횟수(S246)
