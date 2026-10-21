extends Translation
# 영어 번역기(S193, I167). 화면 글을 그릴 때 TranslationServer가 부른다. locale/en.po를 읽어 차례로 맞춘다:
# ① 정확한 msgid ② %d·%s 틀(%s 값도 다시 번역) ③ 줄바꿈·« · »·«, »·« — »·«: »로 나눈 조각마다 ④ 끝의 수를 떼고 앞부분.
# 어느 것도 맞지 않으면 그대로 둔다. 코드의 글은 한국어 그대로라, 이유 글을 비교하는 로직(hud_build.gd)이 언어와 상관없다

const SEPARATORS := ["\n", " · ", ", ", " — ", ": "]

var _exact := {}  # msgid → msgstr
var _templates := []  # [RegEx, msgstr, 자리표시자(«%d»·«%s») 배열]. 틀의 글자가 긴 것(더 구체적인 것)부터 맞춘다
var _tail := RegEx.create_from_string("^(.*\\S) (-?\\d+)$")  # 끝의 수(예: «기본 6»)
# ponytail: 바꾼 글을 지우지 않고 쌓는다. 수가 바뀌는 글(«남은 적 37»)도 하나씩 남지만 한 판에 수천 개 수준이다. 커지면 크기 상한을 둔다
var _memo := {}

func _init() -> void:
	locale = "en"
	var po: Translation = load("res://locale/en.po")
	var holes := RegEx.create_from_string("%[ds]")
	var found := []
	for id in po.get_message_list():
		var key := String(id)
		var to := String(po.get_message(id))
		var kinds := holes.search_all(key).map(func(m): return m.get_string())
		_exact[key] = to  # 틀 글도 그 글 그대로 오면 번역한다
		if not kinds.is_empty():
			found.append([key.length() - 2 * kinds.size(), RegEx.create_from_string("^" + _pattern(key) + "$"), to, kinds])
	found.sort_custom(func(a, b): return a[0] > b[0])
	_templates = found.map(func(t): return t.slice(1))

# 틀 글 → 정규식: 글자는 그대로, %d는 정수, %s는 아무 글(짧게)
func _pattern(key: String) -> String:
	var out := ""
	var i := 0
	while i < key.length():
		if key[i] == "%" and i + 1 < key.length() and key[i + 1] in "ds":
			out += "(-?\\d+)" if key[i + 1] == "d" else "(.+?)"
			i += 2
			continue
		out += ("\\" + key[i]) if key[i] in ".^$*+?()[]{}|\\" else key[i]
		i += 1
	return out

func _get_message(src_message: StringName, _context: StringName) -> StringName:
	return StringName(english(String(src_message)))

# 한국어 글 s의 영어. 바꿀 수 없으면 s 그대로
func english(s: String) -> String:
	if not s in _memo:
		_memo[s] = _translate(s)
	return _memo[s]

func _translate(s: String) -> String:
	if s in _exact:
		return _exact[s]
	for t in _templates:
		var m: RegExMatch = t[0].search(s)
		if m:
			var args := []
			for i in t[2].size():
				var g := m.get_string(i + 1)
				args.append(int(g) if t[2][i] == "%d" else english(g))
			return t[1] % args
	for sep in SEPARATORS:
		if sep in s:
			return sep.join(Array(s.split(sep)).map(func(p): return english(p)))
	var m := _tail.search(s)
	if m:
		return "%s %s" % [english(m.get_string(1)), m.get_string(2)]
	return s
