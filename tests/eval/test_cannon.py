def test_EV98_splash_hits_target_and_one_cell_around(gd):
    gd("cannon", "EV98")


def test_EV99_splashed_enemy_strikes_back(gd):
    gd("cannon", "EV99")


def test_EV100_only_cannon_builds_on_wall_cell(gd):
    gd("cannon", "EV100")


def test_EV101_wall_cannon_shoots_and_enemy_hits_wall(gd):
    gd("cannon", "EV101")


def test_EV102_wall_survives_broken_cannon(gd):
    gd("cannon", "EV102")


def test_EV103_cannon_falls_with_wall_cell(gd):
    gd("cannon", "EV103")


def test_EV104_engineer_moves_cannon_free_keeping_damage(gd):
    gd("cannon", "EV104")


def test_EV105_move_button_then_click_moves_to_wall(gd):
    gd("cannon", "EV105")


def test_EV106_carrier_dies_cannon_back_at_origin(gd):
    gd("cannon", "EV106")


def test_EV107_rebuilder_dies_cannon_unfinished_at_new_cell(gd):
    gd("cannon", "EV107")


def test_EV108_tower_and_prep_moves_refused(gd):
    gd("cannon", "EV108")


def test_EV109_key_8_places_cannon(gd):
    gd("cannon", "EV109")
