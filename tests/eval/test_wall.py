def test_EV89_village_merc_climbs_wall_with_gates_closed(gd):
    gd("wall", "EV89")


def test_EV90_field_merc_climbs_only_through_open_gate(gd):
    gd("wall", "EV90")


def test_EV91_wall_merc_goes_down_and_out(gd):
    gd("wall", "EV91")


def test_EV92_archer_on_wall_shoots_field_enemy(gd):
    gd("wall", "EV92")


def test_EV93_melee_on_wall_does_not_attack_or_leave(gd):
    gd("wall", "EV93")


def test_EV94_enemy_ignores_merc_on_wall(gd):
    gd("wall", "EV94")


def test_EV95_merc_on_open_gate_blocks_and_fights(gd):
    gd("wall", "EV95")


def test_EV96_merc_drops_when_wall_cell_breaks(gd):
    gd("wall", "EV96")


def test_EV97_archery_sells_archer(gd):
    gd("wall", "EV97")


def test_EV233_wall_melee_hits_only_wall_enemies(gd):
    gd("wall", "EV233")
