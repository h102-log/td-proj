class_name WavesDef
extends Resource
# 스테이지 하나의 웨이브(S31, I66). data/waves/<스테이지>.tres. 웨이브마다 {적 종류: 수}, 적은 순서대로 나온다

@export var waves: Array[Dictionary] = []
@export var hp_mult := 1.0  # 이 라운드 적의 체력 배율(S144). 처치 보상은 그대로다
# 웨이브 차례마다 밤(S210): {at: 전투 시작 뒤 해가 지기 시작하는 초, dark: 어둠 0~1, fade: 어둠이 dark까지 오르는 초}. 비었거나 없으면 낮
@export var nights: Array[Dictionary] = []

# Battle stage의 waves 모양([[{kind, count}, ...], ...])으로 바꾼다
func to_stage() -> Array:
	var out := []
	for w in waves:
		out.append(w.keys().map(func(k): return {"kind": k, "count": w[k]}))
	return out
