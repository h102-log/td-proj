extends SceneTree
# EVAL 실행기: `-- <스위트> <EV>...`로 tests/eval/gd/<스위트>.gd의 ev<번호>()를 차례로 돌린다.
# ev 함수는 통과면 "", 실패면 이유 문자열을 돌려준다. 런타임 오류로 null이 오면 실패다.
# EV마다 «== EV» 줄 뒤에 PASS/FAIL 줄을 찍고, 하나라도 실패하면 종료 코드 1이다.

var started := false
var done := false

func _run() -> void:
	TranslationServer.set_locale("ko")  # 평가는 한국어 화면 글을 잰다. OS 언어가 영어여도 같게(I167)
	var args := OS.get_cmdline_user_args()
	var script = load("res://tests/eval/gd/%s.gd" % args[0])
	var loaded: bool = script != null and script.can_instantiate()
	var all_ok := true
	for ev in args.slice(1):
		print("== ", ev)
		var res = script.new().call(ev.to_lower()) if loaded else "스위트를 불러오지 못했다(문법 오류)"
		var ok: bool = res is String and res == ""
		if ok:
			print("PASS ", ev)
		else:
			printerr("FAIL ", ev, ": ", res)
		all_ok = all_ok and ok
	done = true
	quit(0 if all_ok else 1)

# 2026-10-20
# [동작] ev를 _initialize가 아니라 첫 프레임에 돌린다. _run이 결과 없이 중단되면 다음 프레임에서 실패로 끝낸다(무한 대기 방지)
# [이유] _initialize 때는 root가 아직 트리 밖이라 붙인 장면의 _ready가 돌지 않는다. 메뉴·저장 평가(EV308~EV317)는
#        게임 장면(main.tscn)과 메뉴 장면을 붙여 잰다. 유닛 실행기(tests/unit/gd/runner.gd)와 같은 방식이다
func _process(_delta: float) -> bool:
	if not started:
		started = true
		_run()
	elif not done:
		printerr("FAIL: 실행기가 결과 없이 중단됐다")
		quit(1)
	return false
