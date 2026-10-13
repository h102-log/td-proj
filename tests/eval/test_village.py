def test_EV110_barracks_does_not_sell_archer(gd):
    gd("village", "EV110")


def test_EV111_archery_locked_at_level_1(gd):
    gd("village", "EV111")


def test_EV112_raise_village_unlocks_archery(gd):
    gd("village", "EV112")


def test_EV113_raise_rejected_when_poor_or_max(gd):
    gd("village", "EV113")


def test_EV114_raise_rejected_in_battle(gd):
    gd("village", "EV114")


def test_EV115_click_base_selects_village(gd):
    gd("village", "EV115")


def test_EV116_prep_buy_needs_facility_in_village(gd):
    gd("village", "EV116")


def test_EV117_prep_buy_without_village(gd):
    gd("village", "EV117")


def test_EV118_key_9_builds_archery(gd):
    gd("village", "EV118")
