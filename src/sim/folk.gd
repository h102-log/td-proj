extends RefCounted
# 주민 일과·대피(S223·S224·S225~S229, I182·I183). 정적 함수만 있다. 판(battle.gd)이 스텝마다 주민 자리를 구하고, 화면은 판이 구한 자리를 그린다

# 대피·다침·신뢰 손잡이(I183 ⑪). 난이도에 닿는 값이라 사용자가 잰다
const HP := 15.0  # 주민 체력(S227)
const SLOW := 0.3  # 다친 주민 걸음의 밑(평소 대비, S227)
const HEAL := 1.0  # 교회 안 회복(초당 체력, S227)
const HOME_HEAL := 0.5  # 교회가 없을 때 집 안 회복 배율(S227)
const NEAR := 3  # «성벽 근처»: 성곽 바깥 칸 수(S229)
const TRUST := 5  # 신뢰 칸 수이자 처음 신뢰(S229)
const REFUSE := 0.2  # 신뢰 한 칸이 빌 때마다 대피령을 따르지 않는 주민 비율(S229)
const CALM := 2  # 대피령 없이 이만큼 라운드가 지나면 신뢰 +1(S229)
const TRUST_AFTER_LEAVE := 1  # 가구가 떠난 뒤 신뢰(S229)

# 주민 일과(S223, I182 ⑤). 수치는 손잡이(Claude 값)
const WORK := 20.0  # 일터에서 일하는 시간(초)
const HOME := 6.0  # 집 둘레에 있는 시간(초)
const SPEED := 1.2  # 주민 걸음(칸/초)
const DUSK := 0.3  # 이 어둠부터 야경꾼 말고 모두 집 안이다
const PRIEST_LOOK := 8  # 사제의 검은 옷 프리셋(folk_man_8, S172)
# 직업 → 일 자세(S172 2026-10-27 변경). carry_로 시작하면 4방향 들고 걷기, 나머지는 동·서 제자리 2프레임. play는 놀기(걷기)
const POSE := {"farmer": "hoe", "gleaner": "squat", "herbalist": "squat", "washer": "squat", "fisher": "fish", "woodcutter": "axe",
	"blacksmith": "hammer", "mason": "hammer", "carpenter": "saw", "spinner": "sit", "weaver": "sit", "bowyer": "sit",
	"merchant": "stir", "brewer": "stir", "baker": "stir", "innkeeper": "stir", "priest": "stir",
	"water_carrier": "carry_water", "porter": "carry_sack", "miller": "carry_sack", "midwife": "carry_basket",
	"watchman": "carry_lantern", "goose_herd": "carry_stick", "play": "walk"}
# 시험 스테이지 일터 자리(I182 ⑦). ponytail: 지금 판(main.gd stage) 하나의 칸 값이다. 판이 늘면 _plan처럼 거점 기준 상대값으로 옮긴다
const MILL := [Vector2i(45, 5), Vector2i(45, 6)]  # 수로 위 물레방아(방앗간 지붕, 바퀴)
const OVEN := [Vector2i(25, 28)]  # 광장 서북쪽 공동 화덕
const STALLS := [Vector2i(25, 33), Vector2i(35, 28)]  # 광장 좌판 둘
const FISH_SPOTS := [[Vector2i(43, 14), 0], [Vector2i(50, 17), 1], [Vector2i(44, 8), 0], [Vector2i(46, 8), 1]]  # 물가 낚시 자리 [칸, 보는 쪽 0 동·1 서]
const WASH_SPOTS := [Vector2i(43, 16), Vector2i(43, 17)]  # 연못 서쪽 빨래 판석
const WATCH_RING := [Vector2i(18, 21), Vector2i(42, 21), Vector2i(42, 38), Vector2i(18, 38)]  # 야경꾼 길: 안 고리 직사각형 꼭짓점
const POND_RING := [Vector2i(43, 12), Vector2i(50, 12), Vector2i(50, 20), Vector2i(43, 20)]  # 거위 지기 길: 연못 둘레
const NONE := Vector2i(-1, -1)

# t초 때 주민 위치(칸 단위, folk_of 차례). 집 안(chores의 inside)인 주민은 문 칸에 둔다
static func residents(b, t: float) -> Array:
	return day(b, t).map(func(x): return x.pos)

# t초 때 주민이 하는 일(folk_of 차례): {pose, inside}. pose는 "idle"·"walk"·일 자세(POSE 값)이고, inside면 집 안이라 그리지 않는다(S223)
static func chores(b, t: float) -> Array:
	return day(b, t).map(func(x): return {"pose": x.pose, "inside": x.inside})

# residents와 같은 차례의 주민: 완성된 집마다 가족(S221), 끝에 교회에 사는 사제(S222).
# {body, look, job(지금 직업), home(사는 구조물의 칸), i(가족 안 원래 차례), m(그 주민의 가족 사전)}
static func folk_of(b) -> Array:
	var out := []
	for church in [false, true]:
		for s in b.structures.values():
			if s.complete and not s.folk.is_empty() and (s.tax > 0 if not church else s.kind == "church"):
				for i in s.folk.size():
					var m: Dictionary = s.folk[i]
					out.append({"body": m.body, "look": m.look, "job": b.trade(s, i), "home": s.cell, "i": m.get("n", i), "m": m})
	return out

# 고정 소품(S224, I182 ⑦): 그 칸이 마을 안의 물 칸(물레방아)·길 칸(화덕·좌판)인 판에만 선다. inn은 여관 주인이 사는 집의 칸
static func props(b) -> Dictionary:
	var on := func(cells: Array, d: Dictionary): return cells.all(func(c): return b.village.has_point(c) and d.has(c))
	var inn := []
	for s in b.structures.values():
		if s.tax > 0 and s.complete and range(s.folk.size()).any(func(i): return b.trade(s, i) == "innkeeper"):
			inn.append(s.cell)
	return {"mill": MILL if on.call(MILL, b.water) else [], "oven": OVEN if on.call(OVEN, b.roads) else [],
		"stalls": STALLS if on.call(STALLS, b.roads) else [], "inn": inn}

# 우물 칸(S202 2026-10-26 둘째 변경): 거점에서 오른쪽 5칸·아래 3칸, 광장 오른쪽 아래 모서리
static func well(b) -> Vector2i:
	return b.base.cell + Vector2i(5, 3)

# 다 지은 그 종류의 첫 구조물. 없으면 null
static func first(b, kind: String):
	for s in b.structures.values():
		if s.kind == kind and s.complete and s.alive:
			return s
	return null

# 집·식구마다 다른 일과 위상(I182 ⑤)
static func phase(home, i: int) -> float:
	return float(home.cell.x * 7 + home.cell.y * 13 + i * 5)

# 주민마다 t초 때 {pos, pose, inside, dir}. dir은 제자리 일 자세가 보는 쪽(0 동·1 서), -1이면 움직이는 쪽을 본다(그리기가 구한다)
static func day(b, t: float) -> Array:
	var who := folk_of(b)
	if who.is_empty():  # 주민이 없는 판(평가 대부분)은 길 격자를 만들지 않는다
		return []
	var P := paths(b)
	var nth := {}  # 직업마다 몇째 사람인가. 낚시 자리·좌판·텃밭을 나눈다. 길 위의 주민도 세어 남의 자리가 바뀌지 않게 한다
	var out := []
	for f in who:
		var k: int = nth.get(f.job, 0)
		nth[f.job] = k + 1
		out.append(_one(b, P, f, k, t, who))
	return out

# 2026-10-27
# [동작] 주민 하나의 자리·자세를 시각 t와 어둠으로 구한다: 집 둘레 → 일터로 걸음 → 일 → 집으로 걸음을 되풀이하고, 어둠이 오르면 집 쪽으로 물러난다.
#        대피·치료·떠남으로 길 위에 있는 주민(m.away)은 판이 걸린 만큼(away.s)의 자리다
# [의도] 일과는 상태 없이 시각으로만 구하고, 일과를 벗어난 주민만 판이 상태로 걷게 한다(I183 ⑧). 같은 판·같은 시각이면 같은 자리다
# [이유] 어둠 d에서 일터 쪽으로 간 몫을 (1 − d/DUSK)배로 줄이는 것은 상태 없이 «해가 지면 집으로 걸어 들어감»을 내려는 Claude 값이다(I182 ⑤).
#        m.t0은 일과로 돌아온 때 일과가 문에서 다시 시작하게 하는 시각 차다(battle._rejoin)
# ponytail: 걷는 직업이 일하던 중에 해가 지기 시작하면 일터 첫 자리로 한 번 튄다. 밤 웨이브 시작 때만이라 그대로 둔다
static func _one(b, P: Dictionary, f: Dictionary, k: int, t: float, who: Array) -> Dictionary:
	var away = f.m.get("away")
	if away != null:
		return {"pos": _along(away, away.s), "pose": "idle" if away["in"] else "walk", "inside": away["in"], "dir": -1}
	t += f.m.get("t0", 0.0)
	var home = b.structures[f.home]
	var door := door_of(b, P, home)
	var dv := Vector2(door)
	var ph := phase(home, f.i)
	var roam := _roam(b, home, t, ph)
	var d: float = b.dark
	if f.job == "watchman" and d > 0.0:  # 야경꾼만 밤에 등불을 들고 돈다
		var lap := _lap(P, _circuit(b, P, home, WATCH_RING))
		return {"pos": _along(lap, fposmod((t + ph) * SPEED, maxf(lap.len, 0.001))), "pose": "carry_lantern", "inside": false, "dir": -1}
	if d >= DUSK:
		return {"pos": dv, "pose": "idle", "inside": true, "dir": 0}
	if f.job in ["play", "watchman"]:
		return {"pos": dv.lerp(roam, 1.0 - d / DUSK), "pose": "walk", "inside": false, "dir": -1}
	var wk := [f.home, f.i, f.job, k]  # 일터는 막힌 칸·짓는 중인 구조물이 바뀔 때까지 같다(paths가 memo를 비운다)
	if not P.memo.has(wk):
		P.memo[wk] = _work(b, P, f, k, home, door, who)
	var w: Dictionary = P.memo[wk]
	var go := _route(P, door, w.at)
	var walk: float = go.len / SPEED
	var lap := {}
	var busy := WORK
	if w.has("route"):  # 걷는 직업: 일하는 동안 길을 몇 바퀴 돌고 일터 첫 자리에서 끝난다
		lap = _lap(P, w.route)
		var once: float = lap.len / SPEED
		busy = maxf(1.0, roundf(WORK / once)) * once if once > 0.0 else WORK
	var tau := fposmod(t + ph * 1.7, HOME + walk + busy + walk)
	var keep := 1.0 - d / DUSK
	if tau < HOME:  # 집 둘레: 문에서 나왔다가 문으로 돌아간다
		return {"pos": dv.lerp(dv.lerp(roam, clampf(minf(tau, HOME - tau), 0.0, 1.0)), keep), "pose": "walk", "inside": false, "dir": -1}
	tau -= HOME
	var s: float
	if tau < walk:
		s = tau * SPEED
	elif tau < walk + busy and d <= 0.0:
		if lap.is_empty():
			return {"pos": Vector2(w.at), "pose": POSE[f.job], "inside": false, "dir": w.face}
		return {"pos": _along(lap, fposmod((tau - walk) * SPEED, maxf(lap.len, 0.001))), "pose": POSE[f.job], "inside": false, "dir": -1}
	elif tau < walk + busy:
		s = go.len
	else:
		s = go.len - (tau - walk - busy) * SPEED
	return {"pos": _along(go, s * keep), "pose": "walk", "inside": false, "dir": -1}

# 집 둘레를 떠도는 자리(S104, I178): 차지 칸 가운데에서 1.5칸 + (가로 칸 − 1)/2 안. 마을 밖으로 나가지 않고, 가운데에서 가는 선 위에 물 칸(S220)이 있으면 그 앞에 선다(I181)
static func _roam(b, s, t: float, k: float) -> Vector2:
	var mid: Vector2 = b.middle(s)
	var p: Vector2 = (mid + Vector2(sin(t * 0.7 + k), sin(t * 0.5 + k * 1.3)) * (1.5 + (s.size.x - 1) / 2.0)).clamp(Vector2(b.village.position), Vector2(b.village.end - Vector2i.ONE))
	for i in range(1, 9):
		if b.water.has(Vector2i(mid.lerp(p, i / 8.0).round())):
			return mid.lerp(p, (i - 1) / 8.0)
	return p

# 일터(S224, I182 ⑥): {at: 일하는 칸, face: 보는 쪽}, 걷는 직업이면 route(둘러 갈 칸들, 처음이 at)도. 그 판에 일터가 없으면 자기 집 문 앞이다
static func _work(b, P: Dictionary, f: Dictionary, k: int, home, door: Vector2i, who: Array) -> Dictionary:
	var pr := props(b)
	var here := {"at": open_cell(P, door + Vector2i([0, 1, -1][f.i % 3], 0)), "face": f.i % 2}  # 자기 집 문 앞. 식구끼리 겹치지 않게 옆 칸으로
	var garden := _nearest(P, door, P.garden, k % 3)
	var yard := _nearest(P, door, P.yard, 0)
	var plaza: Vector2i = b.base.cell + Vector2i(-3, 3)  # 광장 서남쪽 박석(짐꾼이 짐을 내리는 곳)
	var to_plaza: bool = b.roads.has(plaza) and b.village.has_point(plaza)
	match f.job:
		"farmer", "gleaner", "herbalist":
			return {"at": garden, "face": k % 2} if garden != NONE else here
		"mason":
			return {"at": yard, "face": k % 2} if yard != NONE else here
		"carpenter":
			for s in b.structures.values():  # 마을 안에 짓는 중인 구조물 옆
				if not s.complete and b.village.has_point(s.cell):
					return {"at": open_cell(P, door_of(b, P, s)), "face": 0}
			return {"at": yard, "face": k % 2} if yard != NONE else here
		"fisher":
			var spot: Array = FISH_SPOTS[k % FISH_SPOTS.size()]
			return {"at": open_cell(P, spot[0]), "face": spot[1]} if b.village.has_point(spot[0]) and _wet(b, spot[0]) else here
		"washer":
			var c: Vector2i = WASH_SPOTS[k % WASH_SPOTS.size()]
			return {"at": open_cell(P, c), "face": 0} if b.village.has_point(c) and _wet(b, c) else here
		"baker":
			return {"at": open_cell(P, OVEN[0] + Vector2i(1, 0)), "face": 1} if not pr.oven.is_empty() else here
		"merchant":
			return {"at": open_cell(P, STALLS[k % STALLS.size()] + Vector2i(1, 0)), "face": 1} if not pr.stalls.is_empty() else here
		"blacksmith", "bowyer", "priest":
			var at = first(b, {"blacksmith": "workshop", "bowyer": "archery", "priest": "church"}[f.job])
			return {"at": open_cell(P, door_of(b, P, at) + Vector2i(1, 0)), "face": 1} if at else here
		"miller":
			if pr.mill.is_empty():
				return here
			var mill := open_cell(P, MILL[1] + Vector2i(-1, 0))
			return {"at": mill, "face": 0, "route": [mill, open_cell(P, OVEN[0] + Vector2i(1, 1)) if not pr.oven.is_empty() else door, mill]}
		"water_carrier":
			var w := well(b) + Vector2i(-1, 0)
			if not b.village.has_point(w):
				return here
			var at := open_cell(P, w)
			return {"at": at, "face": 0, "route": [at, door, at]}
		"porter":
			if garden == NONE or not to_plaza:
				return here
			return {"at": garden, "face": 0, "route": [garden, open_cell(P, plaza), garden]}
		"midwife":
			var homes: Array = []
			for g in who:
				if g.home != home.cell and not g.home in homes and b.structures[g.home].tax > 0:
					homes.append(g.home)
			if homes.is_empty():
				return here
			var other := door_of(b, P, b.structures[homes[k % homes.size()]])
			return {"at": here.at, "face": 0, "route": [here.at, other, here.at]}
		"goose_herd":
			if b.water.is_empty() or not POND_RING.all(func(c): return b.village.has_point(c)):
				return here
			var ring := _circuit(b, P, home, POND_RING)
			return {"at": ring[0], "face": 0, "route": ring}
	return here

# 이 칸 옆(위아래좌우)에 물 칸이 있나. 물가 일터(낚시·빨래)를 쓸 수 있는 판인지 본다
static func _wet(b, c: Vector2i) -> bool:
	return [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN].any(func(o): return b.water.has(c + o))

# 둘러 도는 길(야경꾼 안 고리·거위 지기 연못 둘레): 꼭짓점 칸들(돌아온다). 마을 밖이면 그 집 둘레 작은 고리
static func _circuit(b, P: Dictionary, home, pts: Array) -> Array:
	if pts.all(func(c): return b.village.has_point(c)):
		return pts.map(func(c): return open_cell(P, c)) + [open_cell(P, pts[0])]
	var d := door_of(b, P, home)
	return [d, open_cell(P, d + Vector2i(2, 0)), open_cell(P, d + Vector2i(2, 1)), open_cell(P, d + Vector2i(0, 1)), d]

# 구조물의 문 칸(I182 ⑥): 차지 칸 앞줄 가운데 바로 아래 칸. 막혔으면 가장 가까운 열린 칸
static func door_of(b, P: Dictionary, s) -> Vector2i:
	var key := ["door", s.cell]
	if not P.memo.has(key):
		P.memo[key] = open_cell(P, s.cell + Vector2i((s.size.x - 1) / 2, 1))
	return P.memo[key]

# c 가운데 from에서 가까운 열린 칸 가운데 nth째(가까운 순). 없으면 NONE
static func _nearest(P: Dictionary, from: Vector2i, cells: Array, nth: int) -> Vector2i:
	var ok := cells.filter(func(c): return P.region.has_point(c) and not P.grid.is_point_solid(c))
	if ok.is_empty():
		return NONE
	ok.sort_custom(func(a, z): return Vector2(a - from).length_squared() < Vector2(z - from).length_squared())
	return ok[mini(nth, ok.size() - 1)]

# c가 마을 안의 열린 칸이면 그대로, 아니면 가장 가까운 열린 칸(고리를 넓혀 가며 찾는다)
static func open_cell(P: Dictionary, c: Vector2i) -> Vector2i:
	var r: Rect2i = P.region
	for n in 12:
		for y in range(c.y - n, c.y + n + 1):
			for x in range(c.x - n, c.x + n + 1):
				var q := Vector2i(x, y)
				if maxi(absi(x - c.x), absi(y - c.y)) == n and r.has_point(q) and not P.grid.is_point_solid(q):
					return q
	return c

# 주민 길 격자(S223, I182 ⑥): 마을 칸에서 물 칸·구조물 차지 칸·거점을 막는다. 막힌 칸이나 다 지은 구조물이 바뀌면 다시 만들고,
# 길·문 칸·일터 기억(memo)도 그때 비운다. 텃밭·자갈 마당 칸은 스테이지가 정한다(b.garden·b.yards)
static var _pc := {}
static func paths(b) -> Dictionary:
	var stamp := hash([b.get_instance_id(), b.footprint.keys(), b.structures.values().map(func(s): return s.complete), b.water.size(), b.village])
	if _pc.get("stamp") == stamp:
		return _pc
	var g := AStarGrid2D.new()
	g.region = b.village
	g.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	g.update()
	for c in b.footprint.keys() + b.water.keys() + b.cells_in(b.area_of(b.base)):
		if b.village.has_point(c):
			g.set_point_solid(c)
	_pc = {"stamp": stamp, "grid": g, "region": b.village, "memo": {}, "garden": b.garden, "yard": b.yards}
	return _pc

# a에서 z까지 걷는 가장 짧은 길(기억하지 않는다): {pts: 칸 가운데들, len: 칸 단위 길이}
static func trail(P: Dictionary, a: Vector2i, z: Vector2i) -> Dictionary:
	var pts: Array = [Vector2(a)]
	if a != z and P.region.has_point(a) and P.region.has_point(z):
		pts = Array(P.grid.get_id_path(a, z, true)).map(func(c): return Vector2(c))
		if pts.is_empty():
			pts = [Vector2(a)]
	var n := 0.0
	for i in range(1, pts.size()):
		n += pts[i].distance_to(pts[i - 1])
	return {"pts": pts, "len": n}

# trail을 기억해 둔 것. 일과의 길(문·일터 사이)처럼 같은 두 칸을 되풀이해 묻는 길에 쓴다
static func _route(P: Dictionary, a: Vector2i, z: Vector2i) -> Dictionary:
	var key := [a, z]
	if not P.memo.has(key):
		P.memo[key] = trail(P, a, z)
	return P.memo[key]

# 칸들을 차례로 잇는 길(걷는 직업의 일터 길·둘러 도는 길)
static func _lap(P: Dictionary, stops: Array) -> Dictionary:
	var pts: Array = [Vector2(stops[0])]
	var n := 0.0
	for i in range(1, stops.size()):
		var r := _route(P, stops[i - 1], stops[i])
		pts += r.pts.slice(1)
		n += r.len
	return {"pts": pts, "len": n}

# 길 위에서 처음부터 s칸 간 자리
static func _along(r: Dictionary, s: float) -> Vector2:
	var pts: Array = r.pts
	for i in range(1, pts.size()):
		var l: float = pts[i].distance_to(pts[i - 1])
		if s <= l:
			return pts[i - 1].lerp(pts[i], s / l if l > 0.0 else 0.0)
		s -= l
	return pts.back()
