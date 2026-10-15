class_name QuestDef
extends Resource
# 미션·의뢰 하나의 정의(S77, I118). data/quests/<이름>.tres, 파일 이름이 이름이다(I66). 수치는 임시값이다
# 조건은 «라운드 집계(Battle.tally, I119)의 어떤 키가 0이어야 하나»와 «전투 시간 상한»으로 적는다. 둘 다 채워야 달성이다

@export var commission := false  # true면 의뢰(라운드 사이에 골라 수락, S77), false면 미션(라운드마다 자동)
@export var text := ""  # 화면에 보이는 조건 문장(I122)
@export var reward := 0  # 달성하면 받는 골드(S66)
@export var zero: Array[String] = []  # 라운드 동안 0이어야 하는 집계 키(I119): base_hit · castle_lost · structure_lost · merc_lost · hero_down · merc_bought · built
@export var time_limit := 0.0  # 0보다 크면 라운드의 전투 단계 시간 합(초)이 이 값 이하여야 한다
