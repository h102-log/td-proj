class_name RelicDef
extends Resource
# 유물 하나(S334, I278). data/relics/<유물 id>.tres, 파일 이름이 유물 id다(I66 관례). 수치는 임시값이다

@export var title := ""  # 유물 이름. 장비 칸의 유물 줄과 층 보상 토스트에 보인다
@export var steps := []  # 인덱스 = 강화 수치(+0부터). 단계마다 효과 사전 {"cdr": 값}이고 뒤 단계가 앞 단계의 같은 키를 덮는다. cdr는 스킬 재사용 대기가 그만큼 빨리 주는 비율이고, cdr_q·cdr_w·cdr_e·cdr_r은 그 칸의 대기만 빨리 주는 비율이다(S343)
@export var notes := []  # 같은 인덱스 단계의 효과 한 줄. 강화 버튼 툴팁에 보인다
