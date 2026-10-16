class_name WavesDef
extends Resource
# 스테이지 하나의 웨이브(S31, I66). data/waves/<스테이지>.tres. 웨이브마다 {적 종류: 수}, 적은 순서대로 나온다

@export var waves: Array[Dictionary] = []
@export var hp_mult := 1.0  # 이 라운드 적의 체력 배율(S144). 처치 보상은 그대로다

# Battle stage의 waves 모양([[{kind, count}, ...], ...])으로 바꾼다
func to_stage() -> Array:
	var out := []
	for w in waves:
		out.append(w.keys().map(func(k): return {"kind": k, "count": w[k]}))
	return out
