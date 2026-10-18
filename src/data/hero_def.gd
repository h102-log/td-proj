class_name HeroDef
extends Resource
# 영웅 종류 하나의 수치(S31, I95). data/heroes/<종류>.tres, 파일 이름이 종류 이름이다(I66). 종류는 S157의 6명이다
# 기본 능력치는 S121 표, 패시브·오라·Q·W·E·R은 S97 표의 임시값이다. 스킬 칸마다 id가 battle.gd의 _cast_<id>를 고른다

@export var title := ""  # 이명(S157). 영입 창에 이름과 함께 보인다
@export var grade := 1  # 등급(S94): 1 동 · 2 은 · 3 금
@export var hp := 0.0
@export var radius := 0.3  # 몸 반지름(칸, I51)
@export var speed := 0.0
@export var damage := 0.0
@export var range := 0.0  # 사거리(칸)
@export var sight := 2.5  # 인식 범위(칸, S141). 모든 영웅이 같은 임시값이라 파일마다 적지 않는다
@export var attack_gap := 1.0  # 공격 간격(초)
@export var block := 1  # 블록 수(S159): 동시에 붙잡는 적 수. 모든 영웅이 같은 임시값이라 파일마다 적지 않는다
@export var mana := 200.0  # 최대 마나(S146). 모든 영웅이 같은 임시값이라 파일마다 적지 않는다
@export var mana_regen := 2.0  # 전투 단계의 초당 마나 회복(S146)
# 패시브(S145): id와 수치. 바스티온 fortress · 실비아 weak_point · 세라피나 overflow · 베스퍼 contagion · 이그니스 overload. 없으면 비운다
@export var passive := {}
# 오라(S96, S145): radius칸 안에 늘. reach 사거리 +비율(영웅·쏘는 구조물) · armor 방어력 +(아군·방벽) · foe_armor 적 방어력 −
# mana 초당 마나 회복 +(영웅) · haste 공격 속도 +비율(영웅·쏘는 구조물) · stride 이동 속도 +비율(영웅). 없으면 비운다
@export var aura := {}
# 스킬 칸(S145~S148): id, aim(self 즉시 · point 지점 · dir 방향 · ally 아군 대상 · enemy 적 대상 · toggle 켜고 끄기), gap 재사용 대기(초), mana 마나, 그 밖의 수치
@export var q := {}
@export var w := {}
@export var e := {}
@export var r := {}
