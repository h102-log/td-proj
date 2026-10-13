class_name StructureDef
extends Resource
# 구조물 종류 하나의 수치(S31). data/structures/<종류>.tres, 파일 이름이 종류 이름이다(I66)
# 방벽·타워·생산 시설을 한 형식으로 둔다. produces가 있으면 생산 시설이라 마을 안에만 짓는다(S43)
# ponytail: 골드(cost)는 임시값이다(사용자 2026-10-12: 방벽 10·타워 30). 시설 비용·체력·build_time도 임시값. 시설 3종은 2.22

@export var cost := 0
@export var hp := 0.0
@export var build_time := 1.0  # 전투 중 짓는 데 드는 초(I62)
@export var range := 0.0  # 사거리(칸). 0보다 커야 적을 쏜다(타워)
@export var damage := 0.0
@export var fire_gap := 1.0  # 쏘는 간격(초)
@export var produces := ""  # 생산 시설이면 나오는 용병 종류(S20)
