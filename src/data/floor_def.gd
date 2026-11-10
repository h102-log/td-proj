class_name FloorDef
extends Resource
# 던전 층 하나 = 보스방 하나(S316, I262). data/dungeon/<층 id>.tres, 파일 이름이 층 id다(I66 관례). 수치는 임시값이다

@export var title := ""  # 보스 이름(원정 버튼 툴팁·보스 막대)
@export var opens := 2  # 이 층이 열리는 라운드(1부터)
@export var kind := ""  # 그림·몸을 빌릴 적 종류(ENEMY_KINDS 키)
@export var stats := {}  # 종류 수치에 덮어쓸 수치. 라운드 체력 배율(S144)을 곱하지 않는다
@export var skills := {}  # 보스 스킬 이름 → 수치(S194). 종류의 skills를 통째로 바꾼다
@export var gens: Array = []  # 갈라지는 세대마다 {hp, radius, land(착지 원 반경), gap(뜀 간격 초)}(S322). 0번이 처음 몸이고, 비면 보스 하나가 걷고 친다(I266 ⑤)
@export var plan: Array = []  # 대본 [{id, wait}](S324, I268 ①): 처음 몸이 skills의 id 패턴을 차례로 되풀이하고, wait은 그 패턴 앞의 쉼(초)이다. 비면 대본이 없다
@export var ward := 0.0  # 평소 받는 피해 감소 비율(S323 ①). 0이면 경감이 없다
@export var groggy := {"time": 5.0, "mult": 1.5}  # 그로기 초와 그동안 받는 피해 배율(S323 ②)
@export var enrage := {}  # 광폭 {soft, step, ramp}: 불꽃이 soft초 넘게 타면 step초마다 착지 피해가 ramp씩 는다(S323 ⑤). 비면 늘지 않는다
@export var pull := 3.0  # 보스가 나와서 움직이기 전까지 서 있는 초(I262 ④)
@export var hard := 120.0  # 불꽃이 다 타는 초(I262 ⑥)
