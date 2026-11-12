class_name FloorDef
extends Resource
# 던전 층 하나 = 보스방 하나(S316, I262). data/dungeon/<층 id>.tres, 파일 이름이 층 id다(I66 관례). 수치는 임시값이다

@export var title := ""  # 보스 이름(원정 버튼 툴팁·보스 막대)
@export var opens := 2  # 이 층이 열리는 라운드(1부터)
@export var kind := ""  # 그림·몸을 빌릴 적 종류(ENEMY_KINDS 키)
@export var stats := {}  # 종류 수치에 덮어쓸 수치. 라운드 체력 배율(S144)을 곱하지 않는다
@export var skills := {}  # 보스 스킬 이름 → 수치(S194). 종류의 skills를 통째로 바꾼다
@export var gens: Array = []  # 갈라지는 세대마다 {hp, radius, land(착지 원 반경), gap(뜀 간격 초)}(S322). 0번이 처음 몸이고, 비면 보스 하나가 걷고 친다(I266 ⑤)
@export var plan: Array = []  # 대본 [{id, wait}](S326, I270 ①): 처음 몸이 skills의 id 패턴을 차례로 되풀이하고, wait은 그 패턴 앞의 쉼(초)이다. 비면 대본이 없다
@export var walks := true  # 거짓이면 보스가 걷지도 기본 공격도 하지 않고 대본 패턴으로만 움직이고 친다(S337, I280 ①)
@export var shift := {}  # 체력 문턱 {below, rest, twice, windup}(S337 ⑥, I286 ①②): 체력이 최대 체력의 below 이하가 된 뒤로는 대본의 쉼이 rest만큼 짧고, twice 패턴이 발동하면 예고 windup초로 한 번 더 잇는다. 비면 바뀌지 않는다
@export var hunts := false  # 참이면 화면이 사냥감(지금 보스에서 가장 먼 산 원정대 영웅)의 머리 위에 표시를 그린다(S337 ⑨, I286 ④)
@export var phase2 := {}  # 둘째 형태 {title, kind, stats, skills, plan}(S342 ④, I283 ①): 체력이 0이 되면 쓰러지지 않고 kind 종류로 바뀌어 이 수치·스킬·대본을 쓴다. 비면 한 형태다
@export var scale := 0.0  # 몸 그림 배율(I283 ⑨). 0이면 층 수치의 몸 반지름 ÷ 그 종류의 몸 반지름으로 그린다(I280 ①). phase2에도 같은 뜻의 scale 칸을 둘 수 있다
@export var pair: Array = []  # 함께 나오는 몸들 [{at, plan}](S354, I292 ①): 원정을 시작할 때 차례대로 보스 칸 + at 자리에 하나씩 낸다. 차례가 짝 번호이고 몸마다 제 plan을 돈다. 비면 몸 하나다
@export var alone := {}  # 홀로 대본 {rest, lead, plan}(S354 ⑦, I292 ⑤): pair의 한 몸이 쓰러지면 남은 몸이 lead를 한 번, 그 뒤 plan을 쉼 × (1 − rest)로 되풀이한다
@export var wreck := 0.0  # 첫 형태가 부서진 자리에 남는 수레 잔해 원의 반지름(칸, S342 ④·⑧). 둘째 형태의 돌진이 이 원 앞에서 멈춘다. 0이면 막지 않는다
@export var ward := 0.0  # 평소 받는 피해 감소 비율(S323 ①). 0이면 경감이 없다
@export var groggy := {"time": 5.0, "mult": 1.5}  # 그로기 초와 그동안 받는 피해 배율(S323 ②)
@export var enrage := {}  # 광폭 {soft, step, ramp}: 불꽃이 soft초 넘게 타면 step초마다 착지 피해가 ramp씩 는다(S323 ⑤). 비면 늘지 않는다
@export var pull := 3.0  # 보스가 나와서 움직이기 전까지 서 있는 초(I262 ④)
@export var hard := 120.0  # 불꽃이 다 타는 초(I262 ⑥)
@export var gold := 0  # 처치하면 받는 층 골드(S333). 처치 보상 배율을 받지 않는다
@export var relic := ""  # 처치하면 +0으로 받는 유물 id(data/relics 파일 이름, S333). 비면 유물이 없다
