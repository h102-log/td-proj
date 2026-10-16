def test_EV54_sell_refunds_tower_and_merc(gd):
    gd("sell", "EV54")


def test_EV55_sell_damaged_tower_refund_by_hp(gd):
    gd("sell", "EV55")


def test_EV56_no_selling_in_battle(gd):
    gd("sell", "EV56")


def test_EV57_hero_and_castle_not_sellable(gd):
    gd("sell", "EV57")


def test_EV58_click_tower_makes_sell_candidate(gd):
    gd("sell", "EV58")


def test_EV59_drag_picks_structures_and_merc_only(gd):
    gd("sell", "EV59")


def test_EV60_battle_click_no_sell_candidate(gd):
    gd("sell", "EV60")


def test_EV63_empty_click_clears_sell_candidate(gd):
    gd("sell", "EV63")


def test_EV237_battle_click_selects_merc(gd):
    gd("sell", "EV237")
