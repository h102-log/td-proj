def test_EV806_shooters_capped_at_four_then_eight(gd):
    gd("towercap", "EV806")


def test_EV807_battle_blueprints_count_and_unfinished_house_gives_none(gd):
    gd("towercap", "EV807")


def test_EV808_sold_house_keeps_towers_cannon_moves_no_village_no_cap(gd):
    gd("towercap", "EV808")


def test_EV809_tower_count_cell(gd):
    gd("towercap", "EV809")


def test_EV810_grid_dims_and_map_click_refused_when_full(gd):
    gd("towercap", "EV810")
