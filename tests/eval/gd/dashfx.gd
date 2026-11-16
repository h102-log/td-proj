extends "res://tests/eval/gd/sound.gd"
# 대시 연출(S315 2026-11-16 변경, I261 ⑧). sound.gd 머리의 계약에 더하는 API:
#   Battle.dash(영웅 배열, 칸 좌표) · start_raid() · retreat() — 있는 API다(heroes.gd·den.gd 머리)
#   BattleView: battle · tick(dt) · events(이번 프레임 화면 사건, I171) · clock · _dots(효과 점 {p0, p1, t0, col, to, ...}) · _slides(id → [자리, 시작, 길이])
#     _dash_ghosts() — 잔상을 그린다(그림 한 장마다 _region) · _sprite(몸, next, 색) — 영웅 그림 한 장(_region) · _seen · ART · UNITS · PX · DUST
#   화면 사건 «dash»: src(대시한 영웅) · at(내린 자리 가운데, 맵 px) · from(출발 자리 가운데, 맵 px)
# 판: 30×20 시험 판(lib.gd battle)에 영웅을 두고 전투 단계를 연다(heroes.gd의 _start와 같다)

const View := preload("res://src/ui/battle_view.gd")
const F := 1.0 / 60.0
const ONE := [{"kind": "basic", "count": 1}]
const TEAM := [{"kind": "aias", "cell": Vector2i(31, 65)}, {"kind": "ignis", "cell": Vector2i(33, 65)}, {"kind": "seraphina", "cell": Vector2i(32, 65)}]

# 그림 한 장을 그리는 대신 모으는 화면
class Rec extends "res://src/ui/battle_view.gd":
	var cuts := []  # [텍스처, 대상 사각형, 원본 사각형, 색]

	func _region(tex: Texture2D, dst: Rect2, src: Rect2, tint: Color) -> void:
		cuts.append([tex, dst, src, tint])

func _board(team: Array, towers := []):
	var b = battle({"heroes": team, "base_hp": BIG, "waves": [ONE]})
	b.gold = BIG
	for t in towers:
		b.build("tower", t)
	b.start_battle()
	run(b, 5.0, func(): return not b.enemies.is_empty())
	var idle = b.spawn_enemy("basic", Vector2i(0, 19), {"speed": 0, "sight": 0, "damage": 0})
	for x in b.enemies.duplicate():
		if x != idle:
			b.damage(x, BIG)
	return b

func _view(b, rec := false):
	var v = Rec.new() if rec else View.new()
	v.battle = b
	v.tick(F)
	v.tick(F)
	return v

func _dashes(v) -> Array:
	return v.events.filter(func(e): return e.kind == "dash")

func _px(cell: Vector2) -> Vector2:
	return (cell + Vector2(0.5, 0.5)) * CELL_PX

# EV1164 · I261 ⑧: 대시마다 화면 사건 «dash» 하나(효과음 swing). 대기 중·한 걸음도 못 나감·원정에 들고 남에는 없다
func ev1164():
	var Sfx = load("res://src/sfx.gd")
	var b = _board([{"kind": "aias", "cell": Vector2i(10, 10)}, {"kind": "ignis", "cell": Vector2i(10, 12)}, {"kind": "seraphina", "cell": Vector2i(10, 14)}], [Vector2i(11, 14)])
	var h: Array = b.heroes
	h[2].pos = Vector2(10.3, 14)
	var v = _view(b)
	var from := [_px(h[0].pos), _px(h[1].pos)]
	b.dash([h[0]], Vector2(20, 10))
	b.dash([h[1]], Vector2(20, 12))
	b.dash([h[2]], Vector2(20, 14))
	v.tick(F)
	var got := _dashes(v)
	var out := ""
	if got.size() != 2 or h[2].pos != Vector2(10.3, 14):
		out = "대시 둘(셋째는 막힘, 자리 %s) 뒤 «dash» 사건 %d개(2)" % [h[2].pos, got.size()]
	for i in 2:
		if out != "":
			break
		var e: Dictionary = got.filter(func(x): return x.src == h[i]).front() if got.any(func(x): return x.src == h[i]) else {}
		if e.is_empty() or not e.at.is_equal_approx(_px(h[i].pos)) or not e.get("from", Vector2.INF).is_equal_approx(from[i]) or Sfx.key_for(e) != "swing":
			out = "%s의 «dash» 사건 %s(기대 at %s · from %s · 효과음 swing)" % [h[i].kind, e, _px(h[i].pos), from[i]]
	if out == "":
		v.tick(F)
		b.dash([h[0]], Vector2(20, 10))
		v.tick(F)
		if not _dashes(v).is_empty():
			out = "다음 프레임·대기 중 대시에 «dash» 사건 %d개(0)" % _dashes(v).size()
	v.free()
	if out != "":
		return out
	var st := _stage()
	st.heroes = TEAM
	var r = _new(st)
	r.state = "cleared"
	r.next_round()
	var w = _view(r)
	for x in r.heroes:
		x.dash_cd = 4.0
	var went: bool = r.start_raid()
	w.tick(F)
	var into := _dashes(w).size()
	for x in r.heroes:
		x.dash_cd = 0.0
	w.tick(F)
	r.retreat()
	w.tick(F)
	var back := _dashes(w).size()
	var cds: Array = r.heroes.map(func(x): return x.dash_cd)
	w.free()
	return check(went and into == 0 and back == 0 and cds.all(func(c): return c == 4.0), "원정 들어감 %s · 들어간 프레임 «dash» %d(0) · 철수한 프레임 %d(0) · 돌아온 대시 대기 %s(4)" % [went, into, back, cds])

func _cam(main):
	return main.find_children("*", "Camera2D", true, false)[0]

func _move(at: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = at
	e.global_position = at
	Engine.get_main_loop().root.push_input(e, true)

# EV1165 · I261 ⑧: 게임 장면에서 Space로 대시하면 swing이 나고, 보이는 맵 영역 밖의 «dash» 사건도 swing을 낸다
func ev1165():
	_settings()
	var audio = _audio()
	var main = _game()
	var b = main.view.battle
	b.gold = BIG
	for i in 2:
		b.hire(i)
	b.next_round()
	_frame(main)
	b.start_battle()
	_frame(main)
	var h = b.heroes[0]
	h.pos = Vector2(32, 40)
	main.controls.selected = [h]
	var cam = _cam(main)
	cam.position = _px(h.pos)
	cam.force_update_scroll()
	_move(cam.steady() * _px(h.pos + Vector2(3, 0)))
	_frame(main)
	audio._process(1.0)
	audio.played.clear()
	_key(KEY_SPACE)
	_frame(main)
	var went: bool = h.dash_cd > 0.0 and h.pos.x > 33.9
	var heard: Array = audio.played.duplicate()
	audio._process(1.0)
	audio.played.clear()
	main.sfx.hear([_ev({"kind": "dash", "at": Vector2(-800, -800), "src": h, "from": Vector2(-832, -800)})], Rect2(0, 0, 1, 1))
	var far: Array = audio.played.duplicate()
	_done(main)
	return check(went and "swing" in heard and "swing" in far, "Space 대시 %s(자리 %s) 뒤 소리 %s · 화면 밖 «dash» 사건 뒤 소리 %s(둘 다 swing이 있어야 한다)" % [went, h.pos, heard, far])

# 실루엣 그림(UNITS가 아닌 텍스처) [발 자리, 색, 텍스처]. 대상 사각형 왼쪽 위 + 발밑(anchor)이 발 자리다
func _ghosts(v, kind: String) -> Array:
	var a: Dictionary = v.ART[kind]
	var out := []
	for k in v.cuts:
		if k[0] != v.UNITS:
			out.append([k[1].position + Vector2(a.anchor[0], a.anchor[1]), k[3], k[0]])
	v.cuts.clear()
	return out

# EV1166 · I261 ⑧: 잔상 — 길의 0·25·50·75% 자리, 지난 때부터 cream 0.8 → tan 0.55 → ash 0.35, 0.31초에 없음. 실루엣은 걷기 동쪽 둘째 칸. 0.25칸 대시는 출발 자리 하나
func ev1166():
	var b = _board([{"kind": "ignis", "cell": Vector2i(10, 10)}])
	var h = b.heroes[0]
	var v = _view(b, true)
	var start: Vector2 = _px(h.pos)
	b.dash([h], Vector2(20, 10))
	var land: Vector2 = _px(h.pos)
	var steps := {}  # 발 자리 → [처음 나타난 프레임, 지난 색 단계들]
	var bad := []
	var late := 0
	var tex = null
	var want := {[0.8, "cream"]: 0, [0.55, "tan"]: 1, [0.35, "ash"]: 2}
	for f in 25:
		v.tick(F)
		v.cuts.clear()
		v._dash_ghosts()
		for g in _ghosts(v, "ignis"):
			tex = g[2]
			var stage := -1
			for k in want:
				if g[1].is_equal_approx(Color(v.PX[k[1]], k[0])):
					stage = want[k]
			if stage < 0:
				bad.append(["색", g[1]])
			var key: Vector2 = g[0]
			if not steps.has(key):
				steps[key] = [f, []]
			if steps[key][1].is_empty() or steps[key][1][-1] != stage:
				steps[key][1].append(stage)
			if (f + 1) * F > 0.31:
				late += 1
	var spots: Array = steps.keys()
	spots.sort_custom(func(p, q): return p.x < q.x)
	var expect := [0.0, 0.25, 0.5, 0.75].map(func(u): return start.lerp(land, u).round())
	var out := ""
	if spots != expect or not bad.is_empty() or late > 0:
		out = "잔상 자리 %s(기대 %s) · 팔레트 밖 색 %s · 0.31초 뒤 그림 %d" % [spots, expect, bad, late]
	for i in spots.size():
		if out != "":
			break
		var s: Array = steps[spots[i]][1]
		if (i > 0 and steps[spots[i]][0] < steps[spots[i - 1]][0]) or s != [0, 1, 2].slice(0, s.size()) or s.is_empty():
			out = "자리 %s: 처음 프레임 %d · 색 단계 %s(앞 자리보다 이르지 않고 0→1→2 차례)" % [spots[i], steps[spots[i]][0], s]
	if out == "":
		var a: Dictionary = v.ART["ignis"]
		var c := int(a.c)
		var art: Image = v.UNITS.get_image().get_region(Rect2i(c, int(a.walk) + 2 * c, c, c))
		var sil: Image = tex.get_image() if tex else null
		var diff := -1
		if sil and sil.get_size() == Vector2i(c, c):
			diff = 0
			for y in c:
				for x in c:
					if (art.get_pixel(x, y).a > 0.5) != (sil.get_pixel(x, y).a > 0.5):
						diff += 1
		if diff != 0:
			out = "실루엣 텍스처 %s가 이그니스 걷기 동쪽 둘째 칸 모양과 %d점 다르다" % [sil.get_size() if sil else null, diff]
	v.free()
	if out != "":
		return out
	var b2 = _board([{"kind": "ignis", "cell": Vector2i(10, 10)}], [Vector2i(11, 10)])
	var h2 = b2.heroes[0]
	var w = _view(b2, true)
	var p0: Vector2 = _px(h2.pos)
	b2.dash([h2], Vector2(20, 10))
	var short: float = h2.pos.x - 10.0
	var seen := {}
	for f in 25:
		w.tick(F)
		w.cuts.clear()
		w._dash_ghosts()
		for g in _ghosts(w, "ignis"):
			seen[g[0]] = true
	w.free()
	return check(absf(short - 0.25) < 0.001 and seen.keys() == [p0.round()], "막혀 %.2f칸(0.25) 간 대시의 잔상 자리 %s(기대 [%s])" % [short, seen.keys(), p0.round()])

# 효과 점 가운데 크림 → DUST
func _dusts(v) -> Array:
	return v._dots.filter(func(d): return d.col == v.PX.cream and d.to == v.DUST)

# EV1167 · I261 ⑧: 먼지 7(출발 뒤쪽)+4(착지, 미끄러짐 뒤), 짧은 대시 3+2. 미끄러지는 동안 대상이 있어도 대시 쪽 걷기 그림
func ev1167():
	var b = _board([{"kind": "ignis", "cell": Vector2i(10, 10)}])
	var h = b.heroes[0]
	var v = _view(b, true)
	var start: Vector2 = _px(h.pos)
	var a: Dictionary = v.ART["ignis"]
	var c := int(a.c)
	var foe = b.spawn_enemy("basic", Vector2i(4, 10), {"speed": 0, "sight": 0, "damage": 0})
	h.sight = 0.0
	h.target = foe
	var pose := func():
		v.cuts.clear()
		var next := {}
		v._sprite(h, next)
		v._seen = next
		var src: Rect2 = v.cuts[-1][2] if not v.cuts.is_empty() else Rect2()
		for anim in ["idle", "walk", "attack"]:
			var size := c * (2 if anim == "attack" else 1)
			var y0: float = a[anim]
			if src.position.y >= y0 and src.position.y < y0 + 8 * size and src.size.x == size:
				return [anim, int((src.position.y - y0) / size), int(src.position.x / size)]
		return [src]
	pose.call()
	var before: Array = pose.call()
	var n0: int = _dusts(v).size()
	b.dash([h], Vector2(20, 10))
	var land: Vector2 = _px(h.pos)
	v.tick(F)
	var t0: float = v.clock
	var s = v._slides.get(h.get_instance_id())
	var dust: Array = _dusts(v)
	var kick: Array = dust.filter(func(d): return d.t0 <= t0 + 0.0001)
	var drop: Array = dust.filter(func(d): return d.t0 > t0 + 0.0001)
	var poses := []
	for f in 6:
		poses.append(pose.call())
		v.tick(F)
	var out := ""
	if s == null or absf(s[2] - 0.12) > 0.001:
		out = "2칸 대시의 미끄러짐 %s(길이 0.12)" % [s]
	elif dust.size() - n0 != 11 or kick.size() != 7 or drop.size() != 4:
		out = "2칸 대시의 먼지 %d(11) · 출발 %d(7) · 착지 %d(4)" % [dust.size() - n0, kick.size(), drop.size()]
	elif kick.any(func(d): return d.p0.distance_to(start) > 4.0 or d.p1.x >= d.p0.x):
		out = "출발 먼지가 출발 자리 %s 둘레에서 서쪽으로 퍼지지 않는다: %s" % [start, kick.map(func(d): return [d.p0, d.p1])]
	elif drop.any(func(d): return absf(d.t0 - (t0 + 0.12)) > 0.001 or d.p0.distance_to(land) > 4.0):
		out = "착지 먼지가 0.12초 뒤 내린 자리 %s 둘레가 아니다: %s" % [land, drop.map(func(d): return [d.p0, d.t0 - t0])]
	elif before.size() != 3 or before[1] != 6:
		out = "대시 전 서쪽 대상을 둔 그림 %s(방향 6 = 서쪽)" % [before]
	elif poses.any(func(p): return p != ["walk", 2, 1]):
		out = "대시 뒤 0.1초 동안 그림 %s(기대 모두 walk·동쪽 2·둘째 칸 1)" % [poses]
	v.free()
	if out != "":
		return out
	var b2 = _board([{"kind": "ignis", "cell": Vector2i(10, 10)}], [Vector2i(11, 10)])
	var h2 = b2.heroes[0]
	var w = _view(b2, true)
	var m0: int = _dusts(w).size()
	var p0: Vector2 = _px(h2.pos)
	b2.dash([h2], Vector2(20, 10))
	var p1: Vector2 = _px(h2.pos)
	w.tick(F)
	var d2: Array = _dusts(w)
	var k2: int = d2.filter(func(d): return d.p0.distance_to(p0) < d.p0.distance_to(p1)).size()  # 출발 먼지는 출발 자리, 착지 먼지는 내린 자리에서 난다
	w.free()
	return check(d2.size() - m0 == 5 and k2 == 3 and p1.x - p0.x == 4.0, "0.25칸(%.1fpx) 대시의 먼지 %d(5) · 출발 %d(3)" % [p1.x - p0.x, d2.size() - m0, k2])
