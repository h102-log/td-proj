def test_EV25_drag_select(gd):
    gd("merc", "EV25")


def test_EV26_auto_attack(gd):
    gd("merc", "EV26")


def test_EV27_plain_move_ignores_enemies(gd):
    gd("merc", "EV27")


def test_EV28_attack_move_fights_on_the_way(gd):
    gd("merc", "EV28")


def test_EV29_hold_stays_in_radius(gd):
    gd("merc", "EV29")


def test_EV30_hold_attacks_inside_radius(gd):
    gd("merc", "EV30")


def test_EV31_no_hold_chases(gd):
    gd("merc", "EV31")


def test_EV381_merc_stands_through_attack_pose(gd):
    gd("merc", "EV381")


def test_EV388_drag_selects_heroes_too(gd):
    gd("merc", "EV388")


def test_EV392_attack_and_stop_commands(gd):
    gd("merc", "EV392")


def test_EV396_selection_survives_ground_and_enemy_clicks(gd):
    gd("merc", "EV396")


def test_EV397_merc_key_keeps_units_selected(gd):
    gd("merc", "EV397")


def test_EV398_empty_drag_and_hud_picks_keep_units(gd):
    gd("merc", "EV398")
