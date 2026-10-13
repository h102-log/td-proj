def test_EV40_battle_buy_spends_gold(gd):
    gd("production", "EV40")


def test_EV41_bought_merc_walks_to_rally(gd):
    gd("production", "EV41")


def test_EV42_new_rally_for_next_merc(gd):
    gd("production", "EV42")


def test_EV47_cap_blocks_place_and_buy(gd):
    gd("production", "EV47")


def test_EV50_walking_merc_counts_for_cap(gd):
    gd("production", "EV50")


def test_EV64_rally_change_redirects_only_walking(gd):
    gd("production", "EV64")


def test_EV65_facility_only_in_village(gd):
    gd("production", "EV65")


def test_EV66_destroyed_facility_cannot_buy(gd):
    gd("production", "EV66")


def test_EV67_battle_click_picks_facility(gd):
    gd("production", "EV67")


def test_EV68_right_click_sets_rally(gd):
    gd("production", "EV68")
