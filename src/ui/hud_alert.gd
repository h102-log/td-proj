extends Control
# 경보(S189): 거점·성문·성곽 칸·영웅의 피해와 화면 밖 들판 구조물의 절반 아래를 지난 프레임과 비교해 찾고, 토스트(누르면 그 자리로, I163)·
# 화면 밖 가장자리 표식(누르면 그 자리로)·C 키 목록(최근 KEEP개)으로 알린다. 시간은 step의 delta로만 센다(평가가 delta를 넣어 돌린다)

const HudTheme := preload("res://src/ui/hud_theme.gd")
const HudBuild := preload("res://src/ui/hud_build.gd")
const BattleView := preload("res://src/ui/battle_view.gd")
const ORDER := ["base", "gate", "hero", "broken", "field", "wall"]  # 한 프레임에 여럿이면 이 차례로 알린다(거점 > 성문 > 영웅 > 구조물)
const COOL := {"base": 10.0, "gate": 20.0}  # 같은 대상을 다시 알리는 간격(초, S189 임시값)
const NEAR := 4  # 거점·성문 밖의 경보는 같은 종류가 이 칸 안에서
const AGAIN := 15.0  # 이 초 안에 또 나면 다시 알리지 않는다(S189 임시값)
const SHOW := 4.0  # 가장자리 표식이 마지막 피해 뒤 남는 초(S189 임시값)
const KEEP := 5  # C 키가 도는 최근 경보 수(S189 임시값)
const REACH := 2.0  # 표식의 적 수: 그 자리에서 이 칸 안
const BANDS := {"left": Rect2(2, 66, 12, 230), "right": Rect2(626, 66, 12, 110), "bottom": Rect2(30, 344, 470, 12), "top": Rect2(320, 32, 110, 12)}  # 가장자리 표식 띠(S189)
const TURN := {"bottom": 0.0, "top": 180.0, "left": 90.0, "right": -90.0}  # 아래 화살(hud.ARROW)을 그쪽으로 돌린다
const ORANGE := Color("e08a2c")  # 성곽 피해 표식(ui_research 4.3 «가장자리 표식»)
const GATE := ["#######", "#.....#", "#.###.#", "#.#.#.#", "#.#.#.#", "#.#.#.#", "#######"]  # 성문 표식 그림

var hud
var battle
var recent := []  # 최근 경보 칸(Vector2i). 새 것이 앞이다
var _clock := 0.0
var _hp := {}  # 성곽 칸·거점 → 지난 프레임 체력
var _up := {}  # 영웅 → 지난 프레임에 살아 있었나
var _low := []  # 이미 알린 들판 구조물(구조물마다 한 번)
var _last := {}  # 거점·성문 → 마지막으로 알린 때
var _seen := []  # [종류, 칸, 때]: 거점·성문 밖 경보의 묶기
var _marks := {}  # 칸 → {kind, until, button}
var _back := -1  # C 키로 지금 가 있는 recent 차례

func _init(h) -> void:
	hud = h
	battle = h.battle
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

func step(delta: float) -> void:
	_clock += delta
	_seen = _seen.filter(func(s): return _clock - s[2] < AGAIN)
	var hits := []  # [종류, 칸, 대상, 토스트 글]
	_hit(battle.base, "base", "거점 공격받음! (C)", hits)
	var gates: Array = battle.castle.values().filter(func(k): return k.kind == "gate")
	gates.sort_custom(func(a, b): return a.cell.x < b.cell.x)
	for k in battle.castle.values():
		_hit(k, "gate" if k.kind == "gate" else "wall", "%s 공격받음 (C)" % _name(k, gates) if k.kind == "gate" else "", hits)
	for k in battle.rubble.values():  # 이번에 부서진 성곽 칸(I88)
		if _hp.get(k, 0.0) > 0.0:
			hits.append(["broken", k.cell, k, "%s 무너짐 (C)" % _name(k, gates)])
		_hp[k] = 0.0
	for h in battle.heroes:
		if _up.get(h, h.alive) and not h.alive:
			hits.append(["hero", Vector2i(h.pos.round()), h, "%s 쓰러짐 (C)" % hud.HEROES[h.kind].get_slice("(", 0)])
		_up[h] = h.alive
	for s in battle.structures.values():  # 화면 밖 들판 구조물이 처음 절반 아래로. 짓는 중인 것은 세지 않는다
		var half: float = s.max_hp / 2.0
		var at: Vector2 = hud.map.get_canvas_transform() * ((Vector2(s.cell) + Vector2(0.5, 0.5)) * BattleView.CELL)
		if s.alive and s.complete and s.hp < half and _hp.get(s, s.hp) >= half and not s in _low \
				and not battle.village.has_point(s.cell) and not hud.VIEW.has_point(at):
			_low.append(s)
			hits.append(["field", s.cell, s, "%s 위험 (C)" % hud.NAMES[s.kind]])
		_hp[s] = s.hp
	hits.sort_custom(func(a, b): return ORDER.find(a[0]) < ORDER.find(b[0]))
	var fresh := []  # 이번 프레임에 알린 자리. 우선순위가 높은 것이 C 키의 첫 행선지다
	for e in hits:
		if _raise(e[0], e[1], e[2], e[3]):
			fresh.append(e[1])
	if not fresh.is_empty():
		recent = (fresh + recent).slice(0, KEEP)
		_back = -1
	_show_marks()

func _hit(k, kind: String, text: String, hits: Array) -> void:
	if k.alive and k.hp < _hp.get(k, k.hp):
		hits.append([kind, k.cell, k, text])
	_hp[k] = k.hp

# ponytail: 성문 이름은 시험 스테이지(성문 셋: 왼쪽 쪽문·정문·오른쪽 쪽문) 차례다. 성문 수가 다른 맵이 생기면 x로 이름을 정한다
func _name(k, gates: Array) -> String:
	if k.kind != "gate":
		return "성벽"
	var i := gates.find(k)
	return "왼쪽 쪽문" if i == 0 else "오른쪽 쪽문" if i == gates.size() - 1 else "정문"

# 표식은 늘 이어 간다. 거점·성문은 대상마다 COOL초, 그 밖은 같은 종류 ±NEAR칸·AGAIN초 안이면 다시 알리지 않는다. 알렸으면 true
func _raise(kind: String, cell: Vector2i, who, text: String) -> bool:
	var m: Dictionary = _marks.get(cell, {"kind": kind, "button": null})
	m.until = _clock + SHOW
	_marks[cell] = m
	if COOL.has(kind):
		if _clock - _last.get(who, -INF) < COOL[kind]:
			return false
		_last[who] = _clock
	else:
		if _seen.any(func(s): return s[0] == kind and maxi(absi(s[1].x - cell.x), absi(s[1].y - cell.y)) <= NEAR):
			return false
		_seen.append([kind, cell, _clock])
	if text != "":
		hud.toasts.push(text, hud.toasts.LIFE, cell)
	return true

# C 키(S189): 마지막 경보 자리로 카메라, 다시 누르면 그 전 경보(최근 KEEP개를 돈다)
func back() -> void:
	if recent.is_empty():
		return
	_back = (_back + 1) % recent.size()
	hud._focus(Vector2(recent[_back]))

# 위 띠 아래 화면(hud.VIEW) 밖 경보 자리는 그쪽 가장자리 띠 안에 표식(화살·2칸 안 적 수, 성문은 성문 그림)을 둔다. 누르면 그 자리로
func _show_marks() -> void:
	var placed := []  # 이번에 둔 표식 사각형. 같은 띠에서 겹치면 띠를 따라 민다
	for cell in _marks.keys():
		var m: Dictionary = _marks[cell]
		if _clock > m.until:
			if m.button:
				m.button.queue_free()
			_marks.erase(cell)
			continue
		if m.button == null:
			m.button = _marker(m.kind, cell)
		var at: Vector2 = hud.map.get_canvas_transform() * ((Vector2(cell) + Vector2(0.5, 0.5)) * BattleView.CELL)
		var b: Button = m.button
		b.visible = not hud.VIEW.has_point(at)
		if not b.visible:
			continue
		var off: Vector2 = (at - hud.VIEW.get_center()) / hud.VIEW.size  # 화면 가운데에서 본 방향. 더 많이 벗어난 쪽 띠에 둔다
		var side := ("left" if off.x < 0.0 else "right") if absf(off.x) > absf(off.y) else ("top" if off.y < 0.0 else "bottom")
		var band: Rect2 = BANDS[side]
		b.position = Vector2(clampf(at.x - b.size.x / 2, band.position.x, maxf(band.end.x - b.size.x, band.position.x)), clampf(at.y - b.size.y / 2, band.position.y, maxf(band.end.y - b.size.y, band.position.y)))
		var step := Vector2(b.size.x + 2, 0) if side in ["top", "bottom"] else Vector2(0, b.size.y + 2)
		while placed.any(func(r): return r.intersects(Rect2(b.position, b.size))):  # ponytail: 띠 끝을 넘어도 민다. 표식이 띠에 넘칠 만큼 많아지면 묶는다
			b.position += step
		placed.append(Rect2(b.position, b.size))
		b.get_child(0).rotation_degrees = TURN[side]
		b.get_child(1).text = str(battle.enemies.filter(func(e): return e.alive and e.pos.distance_to(Vector2(cell)) <= REACH).size())

func _marker(kind: String, cell: Vector2i) -> Button:
	var gate := kind == "gate"
	var color: Color = HudTheme.DANGER if kind in ["base", "hero"] else ORANGE
	var b: Button = hud._bar_button(self, "", func(): hud._focus(Vector2(cell)))
	b.size = Vector2(34 if gate else 24, 14)
	var arrow: TextureRect = hud._pic(b, HudBuild.dots(hud.ARROW, {"#": color}), Vector2(10, 10))
	arrow.position = Vector2(2, 2)
	arrow.pivot_offset = Vector2(5, 5)
	var l: Label = hud._text(b, 8, HudTheme.TEXT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.position = Vector2(12, 0)
	l.size = Vector2(b.size.x - 14, 14)
	if gate:
		hud._pic(b, HudBuild.dots(GATE, {"#": color}), Vector2(7, 7)).position = Vector2(13, 3)
	for n in b.get_children():
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b
