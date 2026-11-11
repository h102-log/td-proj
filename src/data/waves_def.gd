class_name WavesDef
extends Resource
# 스테이지 하나의 웨이브(S31, I66). data/waves/<스테이지>.tres. 웨이브마다 {적 종류: 수}, 적은 순서대로 나온다

@export var waves: Array[Dictionary] = []
@export var hp_mult := 1.0  # 이 라운드 적의 체력 배율(S144). 처치 보상은 그대로다
# 웨이브 차례마다 밤(S210): {at: 전투 시작 뒤 해가 지기 시작하는 초, dark: 어둠 0~1, fade: 어둠이 dark까지 오르는 초}. 비었거나 없으면 낮
@export var nights: Array[Dictionary] = []
# 웨이브 차례마다 출현 지점 묶음(S337, I280 ①): {적 종류: 출현 지점 차례(0부터 — 시험 스테이지는 0 왼쪽 · 1 가운데 · 2 오른쪽)}.
# 묶인 종류는 그 출현 지점에서만 나온다. 비었거나 없는 종류는 차례마다 출현 지점을 돌아간다
@export var fronts: Array[Dictionary] = []

# Battle stage의 waves 모양([[{kind, count}, ...], ...])으로 바꾼다. 출현 지점에 묶인 종류는 항목에 front가 붙는다
func to_stage() -> Array:
	var out := []
	for i in waves.size():
		var w: Dictionary = waves[i]
		var at: Dictionary = fronts[i] if i < fronts.size() else {}
		out.append(w.keys().map(func(k): return {"kind": k, "count": w[k], "front": at[k]} if at.has(k) else {"kind": k, "count": w[k]}))
	return out
