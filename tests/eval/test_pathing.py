def test_EV5_breaks_wall_when_cheaper(gd):
    gd("pathing", "EV5")


def test_EV6_open_maze_detours(gd):
    gd("pathing", "EV6")


def test_EV7_full_block_breaks_cheapest_wall(gd):
    gd("pathing", "EV7")


def test_EV8_prep_wall_reroutes_next_battle(gd):
    gd("pathing", "EV8")


def test_EV9_default_enemy_detours_longest_maze(gd):
    gd("pathing", "EV9")


def test_EV10_wall_coefficient_per_enemy_type(gd):
    gd("pathing", "EV10")


def test_EV247_forecast_path_per_spawn(gd):
    gd("pathing", "EV247")


def test_EV305_repath_eight_per_step(gd):
    gd("pathing", "EV305")


def test_EV469_cross_water_by_bridge_only(gd):
    gd("pathing", "EV469")


def test_EV472_order_into_water_stops_at_shore(gd):
    gd("pathing", "EV472")
