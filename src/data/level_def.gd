class_name LevelDef
extends Resource
# 영웅 레벨 수치(S126, I111). data/levels.tres. 임시값이다

@export var steps := []  # 다음 레벨까지 필요한 경험치 [Lv2, Lv3, Lv4, Lv5]. 길이 + 1이 최대 레벨이다
@export var growth := 0.0  # 레벨마다 Lv1 최대 체력·공격력에 더하는 비율(I112)
@export var unlock := {}  # 스킬 칸마다 열리는 레벨(S76, S145). 패시브·오라는 Lv1부터다
