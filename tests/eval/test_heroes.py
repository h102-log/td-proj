def test_EV172_hero_table_matches_s97(gd):
    gd("heroes", "EV172")


def test_EV173_hero_files_and_base_stats(gd):
    gd("heroes", "EV173")


def test_EV175_skill_keys_use_selected_hero(gd):
    gd("heroes", "EV175")


def test_EV191_heroes_return_home_and_skip_cap(gd):
    gd("heroes", "EV191")


def test_EV231_skill_falls_to_living_hero(gd):
    gd("heroes", "EV231")


def test_EV238_prep_ignores_q_and_w(gd):
    gd("heroes", "EV238")


def test_EV239_cooldowns_and_regen_pause_outside_battle(gd):
    gd("heroes", "EV239")


def test_EV881_select_all_heroes_key(gd):
    gd("heroes", "EV881")


def test_EV882_dash_selected_heroes(gd):
    gd("heroes", "EV882")


def test_EV883_dash_path_stops_and_passes(gd):
    gd("heroes", "EV883")


def test_EV884_dash_skips_and_clears_orders(gd):
    gd("heroes", "EV884")
