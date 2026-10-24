extends RefCounted
# 재시작하면 판 위의 것이 모두 처음으로 돌아간다(WBS 2.10).
# 지키는 요구:
#   S64. 라운드에서 지면 도전이 끝난다. 보유 영웅, 지은 구조물, 골드가 모두 사라지고 다음 도전은 1라운드부터 새로 시작한다(하드리셋).

func test_restart_clears_built_and_placed():
	var b = load("res://src/sim/battle.gd").new({
		"size": Vector2i(10, 10), "base": Vector2i(9, 9), "base_hp": 100, "gold": 1000, "spawns": [Vector2i(0, 0)],
		"hero_start": Vector2i(2, 2), "waves": [[{"kind": "basic", "count": 3}]],
		"castle": {"walls": [Vector2i(7, 7)], "gates": [], "wall_hp": 300, "gate_hp": 150},
	})
	b.build("wall", Vector2i(5, 5))
	b.build("tower", Vector2i(2, 0))
	b.place_merc("soldier", Vector2i(4, 4))
	b.damage(b.castle[Vector2i(7, 7)], 100)
	b.start_battle()
	b.step(0.05)  # 적 하나가 나오고 타워가 쏜다
	var flying: int = b.shots.size()
	b.restart()
	var why := []
	if flying == 0 or not b.shots.is_empty():  # 남은 화살이 지워진 적에게 닿으면 처치 골드가 들어온다(S178)
		why.append("날아가는 투사체 %d → %d" % [flying, b.shots.size()])
	if not b.structures.is_empty():
		why.append("구조물 %d" % b.structures.size())
	if not b.enemies.is_empty():
		why.append("적 %d" % b.enemies.size())
	if b.units.size() != 1 or b.units[0] != b.hero or b.hero.pos != Vector2(2, 2):
		why.append("유닛 %d" % b.units.size())
	if b.castle[Vector2i(7, 7)].hp != 300:
		why.append("성곽 체력 %d" % b.castle[Vector2i(7, 7)].hp)
	b.start_battle()
	if b._queue.size() != 3:  # 남은 출현 대기열이 이어지지 않는다
		why.append("대기열 %d" % b._queue.size())
	return "" if why.is_empty() else "재시작 뒤 남은 것: %s" % ", ".join(why)
