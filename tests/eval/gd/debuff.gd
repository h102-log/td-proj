extends "res://tests/eval/gd/lib.gd"
# 적 능력치 감소 줄(I101 2026-11-04 변경). lib.gd 머리의 계약에 더하는 API:
#   Battle._fx(대상, 출처, 효과 Dictionary, 초) — 효과를 건다(slow·weaken·armor·mr·dot 키)
#   BattleView: battle · controls · status_marks(몸, 아군) → [{k 조각 이름, p 조각 가운데(맵 px), f 프레임}] · _foot(몸) 발 자리(맵 px)
#     · hp_bar_rect(몸, 크기) 체력바 사각형(S276) · FX_ART 이름 → [x, y, 폭, 높이, 프레임 수](art/fx/fx.png 안)
#   Controls: show_hp — 체력바를 모두 그린다(S73)
# 줄의 조각은 «down»(5×4px)이고 프레임 0~3이 둔화·공격력·방어력·마법 저항이다

const View := preload("res://src/ui/battle_view.gd")
const STILL := {"speed": 0, "sight": 0, "damage": 0}
const COLORS := ["d0d6e0", "ef3a0c", "efac28", "b080e0"]
const NIGHT := "151a26"

func _view(b):
	var v = View.new()
	v.battle = b
	v.controls = controls(b)
	return v

func _down(v, e) -> Array:
	return v.status_marks(e, false).filter(func(m): return m.k == "down")

# EV728 · I101: 걸린 것만 왼쪽부터 둔화·공격력·방어력·마법 저항 차례로 4px 간격(테두리 1px 겹침)이고 눈송이는 없다.
# 방어력·마법 저항이 오른 적과 효과가 없는 적은 줄이 없다. 아틀라스 «down» 네 프레임의 알맹이 색과 어두운 테두리
func ev728():
	var b = battle()
	var v = _view(b)
	var cases := [
		[{"t_slow": {"slow": 0.3}}, [0]],
		[{"t_weaken": {"weaken": 0.4}}, [1]],
		[{"t_armor": {"armor": -5.0}}, [2]],
		[{"t_mr": {"mr": -0.2}}, [3]],
		[{"t_a": {"slow": 0.3, "weaken": 0.3}, "t_b": {"armor": -10.0, "mr": -0.25, "dot": 1.0}}, [0, 1, 2, 3]],
		[{"t_up": {"armor": 5.0, "mr": 0.2}}, []],
		[{}, []],
	]
	var why := ""
	for i in cases.size():
		var e = b.spawn_enemy("basic", Vector2i(2 + 3 * i, 5), STILL)
		for src in cases[i][0]:
			b._fx(e, src, cases[i][0][src], 99.0)
		var down := _down(v, e)
		var frames := down.map(func(m): return m.f)
		if frames != cases[i][1]:
			why = "경우 %d: 줄 프레임이 %s다(%s여야 한다)" % [i, frames, cases[i][1]]
			break
		for j in range(1, down.size()):
			if down[j].p - down[j - 1].p != Vector2i(4, 0):
				why = "경우 %d: 화살표 간격이 %s다((4, 0)이어야 한다)" % [i, down[j].p - down[j - 1].p]
		if why == "" and v.status_marks(e, false).any(func(m): return m.k == "frost"):
			why = "경우 %d: 둔화 눈송이가 남았다" % i
		if why != "":
			break
	v.free()
	if why != "":
		return why
	var a: Array = View.FX_ART.get("down", [])
	if a.size() < 5 or int(a[2]) != 5 or int(a[3]) != 4 or int(a[4]) != 4:
		return "아틀라스 down 조각이 5×4px 4프레임이 아니다: %s" % [a]
	var img: Image = load("res://art/fx/fx.png").get_image()
	var rows := ["NNNNN", "NCCCN", ".NCN.", "..N.."]
	for f in 4:
		for y in 4:
			for x in 5:
				var want: String = rows[y][x]
				var c: Color = img.get_pixel(int(a[0]) + f * 5 + x, int(a[1]) + y)
				var ok: bool = c.a == 0.0 if want == "." else c.a == 1.0 and c.to_html(false) == (NIGHT if want == "N" else COLORS[f])
				if not ok:
					return "down 프레임 %d의 (%d, %d)가 %s다(%s여야 한다)" % [f, x, y, c.to_html(true), "투명" if want == "." else (NIGHT if want == "N" else COLORS[f])]
	return ""

# 줄 조각들의 [왼쪽, 윗변, 폭] (맵 px). 조각 p는 5×4의 가운데라 왼쪽 위가 p − (2, 2)다
func _box(down: Array) -> Array:
	var xs := down.map(func(m): return m.p.x)
	var ys := down.map(func(m): return m.p.y)
	if down.is_empty() or ys.min() != ys.max():
		return [null, null, null]
	return [xs.min() - 2, ys.min() - 2, xs.max() - xs.min() + 5]

# EV729 · I101: 넷이 걸린 적의 줄(폭 17px)은 체력바를 끄면 윗변이 발 자리 + 4px, 켜면 막대 아랫변 + 1px이고 가운데가 발 자리 x다.
# 보스는 체력바를 꺼도 머리 위 막대가 보여 줄(화살표 하나)의 아랫변이 막대 윗변보다 2px 위(윗변이 막대 윗변 − 5px)이고 가운데가 막대 가운데다
func ev729():
	var b = battle()
	var v = _view(b)
	var e = b.spawn_enemy("basic", Vector2i(5, 8), STILL)
	b._fx(e, "t_a", {"slow": 0.3, "weaken": 0.3}, 99.0)
	b._fx(e, "t_b", {"armor": -10.0, "mr": -0.25}, 99.0)
	var boss = b.spawn_enemy("boss", Vector2i(15, 8), STILL)
	b._fx(boss, "t_c", {"weaken": 0.3}, 99.0)
	var foot: Vector2 = v._foot(e)
	var why := ""
	v.controls.show_hp = false
	var got := _box(_down(v, e))
	var want := [int(foot.x) - 8, int(foot.y) + 4, 17]
	if got != want:
		why = "체력바를 끈 적의 줄 [왼쪽, 윗변, 폭]이 %s다(%s여야 한다, 발 자리 %s)" % [got, want, foot]
	v.controls.show_hp = true
	var bar: Rect2 = v.hp_bar_rect(e, Vector2(16, 2))
	got = _box(_down(v, e))
	want = [int(foot.x) - 8, int(bar.end.y) + 1, 17]
	if why == "" and got != want:
		why = "체력바를 켠 적의 줄이 %s다(%s여야 한다, 막대 %s)" % [got, want, bar]
	v.controls.show_hp = false
	bar = v.hp_bar_rect(boss, Vector2(24, 3))
	got = _box(_down(v, boss))
	want = [int(bar.position.x + bar.size.x / 2) - 2, int(bar.position.y) - 5, 5]
	if why == "" and got != want:
		why = "보스의 줄이 %s다(%s여야 한다, 막대 %s)" % [got, want, bar]
	v.free()
	return why
