extends "res://tests/eval/gd/evac.gd"
# 주민 ⑤ 숙련·성장·인구 변화(S231~S233·I184). evac.gd 머리의 계약에 더하는 API:
#   res://src/sim/folk.gd — 손잡이 상수 SKILL_STEPS([숙련, 장인]이 되는 일한 웨이브) · SKILL_FRAME([견습, 숙련, 장인]의 일 자세 간격(초))
#     · GROW([최소, 최대] 가족이 정해질 때 아이의 남은 라운드) · TEEN(청소년으로 지내는 라운드) · BABY(태어난 아이의 남은 라운드)
#     · FOLK_MAX(한 집 인원 상한) · BIRTH(출생 확률)
#     · static skill(m) -> int(0 견습·1 숙련·2 장인) · static frame_gap(m) -> float(그 주민의 제자리 일 자세 간격)
#   주민 사전 m(집 folk[i]) — xp(일한 웨이브) · grow(자라기까지 남은 라운드) · grown(다 큰 자녀) · n(가족 안 차례). 청소년 몸은 "lad"·"lass"
#   Battle.folk_news — 라운드 사이 소식 "split"(분가)·"moved"(이사)·"born"(출생)
#   Battle.ROLE_JOBS — 역할(head·spouse·child·elder) → {직업: 무게}(I182 ②)

const NEED := ["SKILL_STEPS", "SKILL_FRAME", "GROW", "TEEN", "BABY", "FOLK_MAX", "BIRTH"]

# ⑤ 계약이 없으면 그 까닭(글), 있으면 ""
func _lacks5(b) -> String:
	var bad := _lacks(b)
	if bad != "":
		return bad
	var have: Dictionary = _F().get_script_constant_map()
	var miss := NEED.filter(func(k): return not have.has(k))
	return "src/sim/folk.gd에 %s가 없다" % [miss] if not miss.is_empty() else ""

# 라운드 n개(라운드마다 웨이브 하나·적 1)인 마을 판
func _rounds(n: int, over := {}):
	var rs := []
	for i in n:
		rs.append([WAVE1])
	var stage := {"rounds": rs}
	stage.merge(over, true)
	return _battle(stage)

# 웨이브 하나를 끝낸다(라운드를 이기면 라운드 사이에 머문다). 안 되면 그 까닭(글)
func _win(b) -> String:
	b.start_battle()
	if not clear_wave(b) or b.state == "battle":
		return "웨이브가 끝나지 않았다(%s)" % b.state
	return ""

# 집 h의 식구를 모두 죽인다(빈 집)
func _empty(b, h) -> void:
	for v in b.people.filter(func(x): return x.home == h):
		b.damage(v, _F().HP)

# 집 (10,3)이 cond(가족 배열)를 만족하는 첫 씨앗의 [판, 집]. 없으면 [null, null]
func _first(make: Callable, cond: Callable) -> Array:
	for sd in range(1, 120):
		var b = make.call(sd)
		var h = b.build("house", H1)
		if h != null and cond.call(h.folk):
			return [b, h]
	return [null, null]

func _has(fam: Array, m: Dictionary) -> bool:
	return fam.any(func(x): return is_same(x, m))

# EV504 · S231: 웨이브가 끝날 때마다 놀기가 아닌 주민의 일한 웨이브가 오르고, 숙련 단계와 일 자세 간격이 따라 바뀐다
func ev504():
	var F = _F()
	if F == null or not F.get_script_constant_map().has("SKILL_STEPS"):
		return "src/sim/folk.gd에 SKILL_STEPS가 없다"
	var steps: Array = F.SKILL_STEPS
	var waves := []
	for i in steps[1] + 1:
		waves.append(WAVE1)
	var got := _first(func(sd): return _battle({"seed": sd, "waves": waves}),
		func(fam): return fam.any(func(m): return m.job == "play") and fam.any(func(m): return m.job != "play"))
	var b = got[0]
	if b == null:
		return "놀기 아이와 일하는 주민이 함께 있는 씨앗이 없다"
	var bad := _lacks5(b)
	if bad != "":
		return bad
	var fam: Array = got[1].folk.duplicate()
	for m in fam:
		if F.skill(m) != 0 or not is_equal_approx(F.frame_gap(m), F.SKILL_FRAME[0]):
			return "짓자마자 %s skill %s · frame_gap %s" % [m.body, F.skill(m), F.frame_gap(m)]
	for w in range(1, steps[1] + 1):
		bad = _win(b)
		if bad != "":
			return "웨이브 %d: %s" % [w, bad]
		for m in fam:
			var play: bool = m.job == "play"
			var xp := 0 if play else w
			var tier := 0 if play else (2 if w >= steps[1] else (1 if w >= steps[0] else 0))
			if m.get("xp", -1) != xp or F.skill(m) != tier or not is_equal_approx(F.frame_gap(m), F.SKILL_FRAME[tier]):
				return "웨이브 %d 뒤 %s(%s) xp %s · skill %s · frame_gap %s, 기대 %d · %d · %s" % [w, m.body, m.job, m.get("xp"), F.skill(m), F.frame_gap(m), xp, tier, F.SKILL_FRAME[tier]]
	var fr: Array = F.SKILL_FRAME
	return check(fr.size() == 3 and fr[0] > fr[1] and fr[1] > fr[2], "SKILL_FRAME %s가 줄어드는 차례가 아니다" % [fr])

# EV505 · S232: 아이는 남은 라운드가 지나면 청소년(새 몸)이 되어 직업을 얻고, TEEN 라운드 뒤 어른이 된다. 도전에 성공할 때는 자라지 않는다
func ev505():
	var F = _F()
	var got := _first(func(sd): return _rounds(7, {"seed": sd}), func(fam): return fam.any(func(m): return m.body in ["boy", "girl"]))
	var b = got[0]
	if b == null:
		return "아이가 있는 씨앗이 없다"
	var bad := _lacks5(b)
	if bad != "":
		return bad
	var kids: Array = got[1].folk.filter(func(m): return m.body in ["boy", "girl"])
	var info: Array = kids.map(func(m): return [m.body, m.look, m.get("grow")])  # 처음 몸·look·남은 라운드(g0)
	for x in info:
		if not x[2] is int or x[2] < F.GROW[0] or x[2] > F.GROW[1]:
			return "짓자마자 아이의 grow %s, 기대 %s~%s" % [x[2], F.GROW[0], F.GROW[1]]
	var adult := {}
	for r in ["head", "spouse"]:
		adult.merge(b.ROLE_JOBS[r])
	var teen_job: Array = kids.map(func(_m): return "")
	for k in range(1, 7):
		bad = _win(b)
		if bad != "" or b.state != "cleared":
			return "%d라운드: %s %s" % [k, bad, b.state]
		for i in kids.size():
			var m: Dictionary = kids[i]
			var g0: int = info[i][2]
			var boy: bool = info[i][0] == "boy"
			var want: String = info[i][0] if k < g0 else (("lad" if boy else "lass") if k < g0 + F.TEEN else ("man" if boy else "woman"))
			if m.body != want or m.look != info[i][1]:
				return "%d라운드 끝 아이 %d(g0 %d) 몸 %s · look %s, 기대 %s · %s" % [k, i, g0, m.body, m.look, want, info[i][1]]
			if k == g0:
				if not adult.has(m.job) or m.get("xp", -1) != 0:
					return "청소년이 된 때 job %s · xp %s, 기대 가장·배우자 직업 · 0" % [m.job, m.get("xp")]
				teen_job[i] = m.job
			elif k > g0 and m.job != teen_job[i]:
				return "%d라운드 끝 job %s, 청소년 때 %s" % [k, m.job, teen_job[i]]
		b.next_round()
	var before: Array = kids.map(func(m): return [m.body, m.get("grow")])
	bad = _win(b)
	if bad != "" or b.state != "won":
		return "일곱째 라운드: %s %s" % [bad, b.state]
	var after: Array = kids.map(func(m): return [m.body, m.get("grow")])
	return check(after == before, "도전 성공 때 몸·grow %s, 그 전 %s" % [after, before])

# EV506 · S232: 청소년의 직업은 가업, 아니면 아무도 갖지 않은 고유 직업, 아니면 역할 목록에서 뽑는다
func ev506():
	var three := func(fam): return fam.size() >= 3 and fam[0].body in ["man", "woman"] and fam[1].body in ["man", "woman"] and fam[2].body in ["boy", "girl"]
	var out := []
	var spouse := {}
	for k in 3:  # 같은 씨앗의 새 판 셋
		var pick := _first(func(s): return _rounds(2, {"seed": s}), three)
		if pick[0] == null:
			return "어른 둘과 아이가 있는 씨앗이 없다"
		var b = pick[0]
		var h = pick[1]
		var bad := _lacks5(b)
		if bad != "":
			return bad
		spouse = b.ROLE_JOBS.spouse
		var kid: Dictionary = h.folk[2]
		kid.grow = 1
		if k == 0:
			h.folk[0].job = "farmer"
			kid.body = "boy"
		else:
			h.folk[0].job = "miller"
			kid.body = "girl"
			for m in h.folk:
				if m.job == "midwife":
					m.job = "washer"
			if k == 2:
				h.folk[1].job = "midwife"
		bad = _win(b)
		if bad != "" or b.state != "cleared":
			return "경우 %d: %s %s" % [k + 1, bad, b.state]
		out.append([kid.body, kid.job])
	if out[0] != ["lad", "farmer"]:
		return "① 가장이 농부 → %s, 기대 [lad, farmer]" % [out[0]]
	if out[1] != ["lass", "midwife"]:
		return "② 가장이 방앗간지기·산파 없음 → %s, 기대 [lass, midwife]" % [out[1]]
	return check(out[2][0] == "lass" and spouse.has(out[2][1]) and out[2][1] != "midwife", "③ 배우자가 산파 → %s, 기대 lass · 배우자 직업 · 산파 아님" % [out[2]])

# EV507 · S233 ①: 다 큰 자녀는 빈 집이 있으면 그 집으로 걸어가 혼자 새 가구가 되고, 그 집의 죽은 식구 몫이 0으로 돌아간다
func ev507():
	var got := _first(func(sd): return _rounds(2, {"seed": sd}), func(fam): return fam.size() >= 2)
	var b = got[0]
	var A = got[1]
	if b == null:
		return "식구 둘 이상인 씨앗이 없다"
	var B = b.build("house", H2)
	var bad := _lacks5(b)
	if bad != "":
		return bad
	var g: Dictionary = A.folk.back()
	g.body = "man"
	g.grown = true
	_empty(b, B)
	if not B.folk.is_empty() or B.lost <= 0:
		return "B가 빈 집이 되지 않았다(식구 %d · lost %d)" % [B.folk.size(), B.lost]
	b.folk_news.clear()
	bad = _win(b)
	if bad != "" or b.state != "cleared":
		return "%s %s" % [bad, b.state]
	if _has(A.folk, g) or B.folk.size() != 1 or not is_same(B.folk[0], g):
		return "분가 뒤 A %d명(g 있음 %s) · B %d명(g %s)" % [A.folk.size(), _has(A.folk, g), B.folk.size(), _has(B.folk, g)]
	if g.get("grown", false) or g.get("n", -1) != 0 or B.lost != 0:
		return "g grown %s · n %s · B lost %s, 기대 거짓 · 0 · 0" % [g.get("grown"), g.get("n"), B.lost]
	if b.folk_news.count("split") != 1 or b.folk_news.has("moved"):
		return "소식 %s, 기대 split 한 번·moved 없음" % [b.folk_news]
	var mine := func(): return b.people.filter(func(v): return is_same(v.m, g))
	var home := func(): return mine.call().size() == 1 and mine.call()[0].home == B and g.get("away") == null
	return check(run(b, 60.0, home), "60초 안에 g가 B에 들지 않았다(%s)" % [mine.call().map(func(v): return [v.home.cell, v.m.get("away", {}).get("to")])])

# EV508 · S233 ①: 빈 집이 없으면 다 큰 자녀는 기다렸다가 새로 지은 집에 들고, 혼자 사는 다 큰 자녀는 나가지 않는다
func ev508():
	var got := _first(func(sd): return _rounds(2, {"seed": sd}), func(fam): return fam.size() >= 2)
	var b = got[0]
	var A = got[1]
	if b == null:
		return "식구 둘 이상인 씨앗이 없다"
	var bad := _lacks5(b)
	if bad != "":
		return bad
	var g: Dictionary = A.folk.back()
	g.body = "man"
	g.grown = true
	bad = _win(b)
	if bad != "" or b.state != "cleared":
		return "① %s %s" % [bad, b.state]
	if not _has(A.folk, g):
		return "① 빈 집이 없는데 g가 A를 떠났다"
	b.next_round()
	var C = b.build("house", Vector2i(18, 3))
	if C == null:
		return "① 2라운드 준비 단계에 집 C를 짓지 못했다"
	if C.folk.size() != 1 or not is_same(C.folk[0], g) or _has(A.folk, g) or g.get("grown", false):
		return "① 새 집 C %d명(g %s) · A에 g %s · grown %s" % [C.folk.size(), _has(C.folk, g), _has(A.folk, g), g.get("grown")]
	got = _first(func(sd): return _rounds(2, {"seed": sd}), func(fam): return fam.size() == 1)
	b = got[0]
	var D = got[1]
	if b == null:
		return "② 식구 하나인 씨앗이 없다"
	var E = b.build("house", H2)
	var lone: Dictionary = D.folk[0]
	lone.body = "man"
	lone.grown = true
	_empty(b, E)
	b.trust = 2
	bad = _win(b)
	if bad != "" or b.state != "cleared":
		return "② %s %s" % [bad, b.state]
	return check(D.folk.size() == 1 and is_same(D.folk[0], lone) and E.folk.is_empty(), "② 혼자인 다 큰 자녀: D %d명(그 사람 %s) · E %d명" % [D.folk.size(), _has(D.folk, lone), E.folk.size()])

# EV509 · S233 ②: 신뢰가 3 이상이면 라운드 사이에 빈 집 하나에 새 가족이 정문 안쪽에서 걸어와 들고, 다음 세금부터 낸다
func ev509():
	for trust in [5, 2]:
		var b = _rounds(3, {"seed": 1})
		b.build("house", H1)
		var B = b.build("house", H2)
		var C = b.build("house", Vector2i(18, 3))
		var bad := _lacks5(b)
		if bad != "":
			return bad
		var R: int = b.ENEMY_KINDS.basic.reward
		var T: int = b.STRUCTURE_KINDS.house.tax
		_empty(b, B)
		_empty(b, C)
		b.trust = trust
		b.folk_news.clear()
		var gold0: int = b.gold
		bad = _win(b)
		if bad != "" or b.state != "cleared":
			return "신뢰 %d: %s %s" % [trust, bad, b.state]
		if trust == 2:
			return check(B.folk.is_empty() and C.folk.is_empty(), "신뢰 2인데 빈 집에 식구가 들었다(B %d · C %d)" % [B.folk.size(), C.folk.size()])
		if b.gold - gold0 != R + T:
			return "1라운드 끝 골드 +%d, 기대 +%d(처치 + A 세금)" % [b.gold - gold0, R + T]
		var bodies := ["man", "woman", "boy", "girl", "old_man", "old_woman"]
		if B.folk.size() < 1 or B.folk.size() > 5 or not B.folk.all(func(m): return m.body in bodies) or not C.folk.is_empty() or B.lost != 0:
			return "이사 뒤 B %s · C %d명 · B lost %d" % [B.folk.map(func(m): return m.body), C.folk.size(), B.lost]
		var mine: Array = b.people.filter(func(v): return v.home == B)
		var walking := func(v): return _to(v) == "home" and not v.m.away["in"] and v.pos.distance_to(Vector2(25, 5)) <= 1.0
		if mine.size() != B.folk.size() or not mine.all(walking):
			return "이사 오는 식구 %s" % [mine.map(func(v): return [_to(v), v.pos])]
		if b.folk_news.count("moved") != 1:
			return "소식 %s, 기대 moved 한 번" % [b.folk_news]
		if not run(b, 60.0, func(): return B.folk.all(func(m): return m.get("away") == null)):
			return "60초 안에 새 가족이 집에 들지 않았다"
		b.next_round()
		b.mission = ""
		b.commission = ""
		gold0 = b.gold
		bad = _win(b)
		if bad != "" or b.state != "cleared":
			return "2라운드: %s %s" % [bad, b.state]
		if b.gold - gold0 != R + 2 * T:
			return "2라운드 끝 골드 +%d, 기대 +%d(처치 + A·B 세금)" % [b.gold - gold0, R + 2 * T]
	return ""

# EV510 · S233 ③: 부부가 사는 집은 라운드 사이에 BIRTH 확률로 아이가 태어나 식구 끝에 붙는다. 비율은 3표준편차 안
func ev510():
	var F = _F()
	var can := 0
	var born := 0
	var sexes := {}
	for sd in range(1, 301):
		var b = _rounds(2, {"seed": sd})
		var h = b.build("house", H1)
		if sd == 1:
			var bad := _lacks5(b)
			if bad != "":
				return bad
		var before: Array = h.folk.duplicate()
		var adult := func(body): return before.any(func(m): return m.body == body and not m.get("grown", false))
		var ok: bool = adult.call("man") and adult.call("woman") and before.size() < F.FOLK_MAX
		b.folk_news.clear()
		var bad := _win(b)
		if bad != "" or b.state != "cleared":
			return "씨앗 %d: %s %s" % [sd, bad, b.state]
		var grew: int = h.folk.size() - before.size()
		if not ok or grew == 0:
			if grew != 0 or b.folk_news.has("born"):
				return "씨앗 %d: 늘 수 없는 집(%s)에 식구 %d · 소식 %s" % [sd, before.map(func(m): return m.body), grew, b.folk_news]
			can += 1 if ok else 0
			continue
		can += 1
		if grew != 1 or not range(before.size()).all(func(i): return is_same(h.folk[i], before[i])):
			return "씨앗 %d: 식구가 %d 늘었거나 앞 식구가 바뀌었다" % [sd, grew]
		var m: Dictionary = h.folk.back()
		var n: int = before.map(func(x): return x.get("n", 0)).max() + 1
		if not m.body in ["boy", "girl"] or m.look % 3 != before[0].look % 3 or m.get("grow") != F.BABY or m.get("xp") != 0 or m.get("n") != n \
				or not b.ROLE_JOBS.child.has(m.get("job", "")):
			return "씨앗 %d: 태어난 아이 %s, 기대 boy·girl · 피부 %d · grow %d · xp 0 · n %d · 아이 직업" % [sd, m, before[0].look % 3, F.BABY, n]
		if b.folk_news.count("born") != 1:
			return "씨앗 %d: 소식 %s, 기대 born 한 번" % [sd, b.folk_news]
		born += 1
		sexes[m.body] = true
	if can == 0:
		return "늘 수 있는 집이 없다"
	var rate := float(born) / can
	var tol := 3.0 * sqrt(F.BIRTH * (1.0 - F.BIRTH) / can)  # 표본 크기에 맞춘 3표준편차
	return check(absf(rate - F.BIRTH) <= tol and sexes.size() == 2, "태어난 비율 %d/%d = %.3f(기대 %s ± %.3f) · 몸 %s" % [born, can, rate, F.BIRTH, tol, sexes.keys()])
