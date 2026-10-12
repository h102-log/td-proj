extends SceneTree
# 자체 테스트 실행기: `-- <res:// 경로>`로 받은 파일의 test_로 시작하는 함수를 모두 돌리고 종료 코드로 알린다.
# test 함수는 통과면 "", 실패면 이유 문자열을 돌려준다. 런타임 오류로 null이 오면 실패다.

var done := false

func _initialize() -> void:
	var path: String = OS.get_cmdline_user_args()[0]
	var script = load(path)
	if script == null or not script.can_instantiate():
		_finish(1, "%s: 불러오지 못했다(문법 오류)" % path)
		return
	var obj = script.new()
	var fails := 0
	for m in script.get_script_method_list():
		var name: String = m.name
		if not name.begins_with("test_"):
			continue
		var res = obj.call(name)
		if res is String and res == "":
			print("PASS ", name)
		else:
			printerr("FAIL ", name, ": ", res)
			fails += 1
	_finish(fails, "" if fails == 0 else "%d개 실패" % fails)

func _finish(fails: int, why: String) -> void:
	done = true
	if fails == 0:
		print("ALL PASS")
	else:
		printerr("FAIL: ", why)
	quit(0 if fails == 0 else 1)

# _initialize가 결과 없이 중단돼도 첫 프레임에서 실패로 끝낸다(무한 대기 방지)
func _process(_delta: float) -> bool:
	if not done:
		printerr("FAIL: 실행기가 결과 없이 중단됐다")
		quit(1)
	return false
