class_name FloorDef
extends Resource
# 던전 층 하나 = 보스방 하나(S316, I262). data/dungeon/<층 id>.tres, 파일 이름이 층 id다(I66 관례). 수치는 임시값이다

@export var title := ""  # 보스 이름(원정 버튼 툴팁·보스 막대)
@export var opens := 2  # 이 층이 열리는 라운드(1부터)
@export var kind := ""  # 그림·몸을 빌릴 적 종류(ENEMY_KINDS 키)
@export var stats := {}  # 종류 수치에 덮어쓸 수치. 라운드 체력 배율(S144)을 곱하지 않는다
@export var skills := {}  # 보스 스킬 이름 → 수치(S194). 종류의 skills를 통째로 바꾼다
@export var gens: Array = []  # 갈라지는 세대마다 {hp, radius, land(착지 원 반경), gap(뜀 간격 초)}(S322). 0번이 처음 몸이고, 비면 보스 하나가 걷고 친다(I266 ⑤)
@export var pull := 3.0  # 보스가 나와서 움직이기 전까지 서 있는 초(I262 ④)
@export var hard := 120.0  # 불꽃이 다 타는 초(I262 ⑥)
