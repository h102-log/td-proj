extends "res://tests/eval/gd/lib.gd"
# WBS 5.4 한국어·영어(S193·I167). lib.gd 머리의 계약에 더하는 API:
#   res://src/locale.gd — 번역기(Translation 하위 클래스). new()가 locale/en.po를 읽고 언어는 «en»이다. get_message(한국어 글)이 영어 글을 준다
#   res://locale/en.po — 번역 파일(msgid는 한국어 원문)

const SKIP := ["assert(", "push_error", "번역 안 함"]  # 이 글이 든 줄은 번역 대상이 아니다(I167)
const EDGE := " ·—:,\n"  # 리터럴 앞뒤에서 떼는 구분자(조각으로 이어 붙이던 글)

# EV373 · I167: 코드·데이터의 한글 리터럴이 모두 번역기를 거치면 한글이 없어지고, en.po의 자리표시자가 msgstr에 같은 차례로 있다
func ev373():
	var tl = load("res://src/locale.gd").new()
	var hangul := RegEx.create_from_string("[가-힣]")
	var misses := []
	var total := 0
	for path in _files("res://src", ".gd") + _files("res://data/heroes", ".tres") + _files("res://data/quests", ".tres"):
		var n := 0
		for line in FileAccess.get_file_as_string(path).split("\n"):
			n += 1
			if SKIP.any(func(s): return s in line):
				continue
			for s in _literals(line, path.ends_with(".gd")):
				if not hangul.search(s):
					continue
				total += 1
				var key: String = s.lstrip(EDGE).rstrip(EDGE)
				var got := String(tl.get_message(key))
				if hangul.search(got):
					misses.append("%s:%d «%s» → «%s»" % [path, n, key.replace("\n", "⏎"), got.replace("\n", "⏎")])
	if total < 200:
		return "한글 리터럴을 %d개만 찾았다(200개 넘게 있어야 한다)" % total
	if not misses.is_empty():
		return "번역기를 거쳐도 한글이 남는 리터럴 %d개: %s" % [misses.size(), "; ".join(misses.slice(0, 6))]
	var po = load("res://locale/en.po")
	var holes := RegEx.create_from_string("%[ds]")
	var bad := []
	for id in po.get_message_list():
		var to := String(po.get_message(id))
		if to == "" or holes.search_all(id).map(func(m): return m.get_string()) != holes.search_all(to).map(func(m): return m.get_string()):
			bad.append("«%s» → «%s»" % [String(id).replace("\n", "⏎"), to.replace("\n", "⏎")])
	return check(bad.is_empty(), "msgstr이 비었거나 자리표시자가 다른 항목 %d개: %s" % [bad.size(), "; ".join(bad.slice(0, 6))])

# dir 아래(하위 폴더 포함) ext로 끝나는 파일 경로
func _files(dir: String, ext: String) -> Array:
	var out := []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(ext):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		out.append_array(_files(dir.path_join(d), ext))
	return out

# 줄의 큰따옴표 문자열 리터럴(이스케이프를 푼 값). .gd면 문자열 밖의 # 뒤(주석)는 보지 않는다
func _literals(line: String, code: bool) -> Array:
	var out := []
	var cur := ""
	var inside := false
	var i := 0
	while i < line.length():
		var c := line[i]
		if inside:
			if c == "\\" and i + 1 < line.length():
				var e := line[i + 1]
				cur += {"n": "\n", "t": "\t"}.get(e, e)
				i += 1
			elif c == "\"":
				out.append(cur)
				inside = false
			else:
				cur += c
		elif c == "\"":
			inside = true
			cur = ""
		elif c == "#" and code:
			break
		i += 1
	return out
