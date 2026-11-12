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
@export var accuracy := 1.0  # 명중률(S178 2026-11-04 변경): 궁수의 한 발이 대상을 따라가는 화살이 될 확률. 아니면 논타겟팅 화살이다. 임시값(S254)
@export var block := 1  # 블록 수(S159): 동시에 붙잡는 적 수. 임시값
@export var sight := 0.0  # 인식 범위(칸, I36)
@export var hold_radius := 0.0  # 홀드 반경(칸, I37)
@export var light := 0.0  # 밤 불빛 반경(칸, S211): 어둠 1일 때. 어둠 d면 ÷ d
@export var armor := 0.0  # 방어력(S149). 방패병만 있다(S356)
@export var damage_kind := "phys"  # 기본 공격의 피해 종류(S149): "phys" | "magic". 불·번개·얼음 마법사는 magic(S356)
# 새 용병 여덟의 스킬 칸(S357~S364). 없으면 비운다. 칸의 키는 SPEC 문장의 손잡이 이름 그대로다
@export var parry := {}  # 방패병 돌진 막기(S357): stun
@export var blast := {}  # 불마법사 예고 범위(S358): windup, radius, dps, time
@export var chain := {}  # 번개마법사 전이(S359): odds, jumps, reach
@export var thrust := {}  # 창병 꿰뚫기(S360): reach, width
@export var frost := {}  # 얼음 마법사 냉기(S361): slow, stacks, time, freeze
@export var mend := {}  # 사제 회복(S362): range, heal. 간격은 attack_gap
@export var lance := {}  # 기병 돌진(S363): min, length, speed, damage, width, push, cd
@export var net := {}  # 그물 사수 그물(S364): cd, time, boss
@export var ranks := []  # 강화 단계(S254): 칸마다 {키: 값}. [0]이 1단계다. 값이 사전이면 그 칸 사전의 적힌 키만 덮는다(S356). 임시값
@export var rank_cost := []  # 단계마다 골드(S254). 임시값
