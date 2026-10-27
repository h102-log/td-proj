class_name StructureDef
extends Resource
# 구조물 종류 하나의 수치(S31). data/structures/<종류>.tres, 파일 이름이 종류 이름이다(I66)
# 방벽·타워·대포·생산 시설·집·교회·대피소를 한 형식으로 둔다. produces가 비어 있지 않거나(생산 시설) tax(집)·heal(교회)·seats(대피소)가 있으면 마을 안에만 짓는다(S43·S226)
# ponytail: 골드(cost)는 임시값이다(사용자 2026-10-12: 방벽 10·타워 30). 시설 비용·체력·build_time도 임시값

@export var cost := 0
@export var hp := 0.0
@export var build_time := 1.0  # 전투 중 짓는 데 드는 초(I62)
@export var range := 0.0  # 사거리(칸). 0보다 커야 적을 쏜다(타워)
@export var damage := 0.0
@export var fire_gap := 1.0  # 쏘는 간격(초)
@export var splash := 0.0  # 범위 피해 반경(칸). 맞은 적에서 이 거리 안의 적도 같은 피해를 입는다(대포, S90)
@export var pierce := false  # 적의 장갑을 무시한다(마법 타워, S110)
@export var produces: Array[String] = []  # 생산 시설이면 파는 용병 종류들. 첫째가 기본이다(S20, S87)
@export var village_level := 1  # 이 마을 레벨부터 짓는다(S99)
@export var tax := 0  # 집이면 준비 단계마다 내는 세금(S101, I46)
@export var heal := 0.0  # 교회면 영웅 체력 1당 치료비(골드, S137)
@export var seats := 0  # 대피소면 대피령 때 들어가는 주민 수(S226)
@export var light := 0.0  # 다 지었을 때 밤 불빛 반경(칸, S211). 0이면 빛이 없다(방벽)
@export var size := Vector2i.ONE  # 차지 칸 가로 × 깊이(S216). 구조물의 칸은 차지 칸의 앞 왼쪽 칸이다
