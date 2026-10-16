def test_EV204_kills_give_xp_to_living_lineup(gd):
    gd("levels", "EV204")


def test_EV205_level_numbers_match_s126(gd):
    gd("levels", "EV205")


def test_EV206_level_thresholds(gd):
    gd("levels", "EV206")


def test_EV207_level_raises_hp_and_damage_only(gd):
    gd("levels", "EV207")


def test_EV208_w_at_lv3_aura_at_lv5(gd):
    gd("levels", "EV208")


def test_EV209_start_levels(gd):
    gd("levels", "EV209")


def test_EV210_xp_transfer_between_rounds(gd):
    gd("levels", "EV210")


def test_EV211_level_up_mid_battle(gd):
    gd("levels", "EV211")


def test_EV227_overflowing_transfer_is_refused(gd):
    gd("levels", "EV227")


def test_EV228_transfer_keeps_hp_ratio(gd):
    gd("levels", "EV228")
