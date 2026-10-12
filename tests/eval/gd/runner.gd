extends SceneTree
# EVAL 실행기: `-- <스위트> <EV>`로 tests/eval/gd/<스위트>.gd의 ev<번호>()를 돌리고 종료 코드로 알린다.
# ev 함수는 통과면 "", 실패면 이유 문자열을 돌려준다. 런타임 오류로 null이 오면 실패다.

var done := false

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var script = load("res://tests/eval/gd/%s.gd" % args[0])
	if script == null or not script.can_instantiate():
		_finish(false, args[1], "스위트를 불러오지 못했다(문법 오류)")
		return
	var res = script.new().call(args[1].to_lower())
	_finish(res is String and res == "", args[1], res)

func _finish(ok: bool, ev: String, why) -> void:
	done = true
	if ok:
		print("PASS ", ev)
	else:
		printerr("FAIL ", ev, ": ", why)
	quit(0 if ok else 1)

# _initialize가 결과 없이 중단돼도 첫 프레임에서 실패로 끝낸다(무한 대기 방지)
func _process(_delta: float) -> bool:
	if not done:
		printerr("FAIL: 실행기가 결과 없이 중단됐다")
		quit(1)
	return false
