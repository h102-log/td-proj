def test_EV192_challenge_starts_with_hiring(gd):
    gd("hire", "EV192")


def test_EV193_no_map_commands_while_hiring(gd):
    gd("hire", "EV193")


def test_EV194_hire_numbers_match_s123(gd):
    gd("hire", "EV194")


def test_EV195_grade_odds_and_reroll_cost(gd):
    gd("hire", "EV195")


def test_EV196_equal_odds_within_grade_and_duplicates(gd):
    gd("hire", "EV196")


def test_EV197_hire_cost_lineup_and_roster_caps(gd):
    gd("hire", "EV197")


def test_EV198_lineup_change_between_rounds(gd):
    gd("hire", "EV198")


def test_EV199_offers_refresh_and_reroll_only_in_window(gd):
    gd("hire", "EV199")


def test_EV200_dismiss_without_refund(gd):
    gd("hire", "EV200")


def test_EV201_lineup_is_a_cap_and_carries_over(gd):
    gd("hire", "EV201")


def test_EV202_hero_cells_in_front_of_gate_unbuildable(gd):
    gd("hire", "EV202")


def test_EV203_lineup_order_and_hero_hotkeys(gd):
    gd("hire", "EV203")


def test_EV232_reroll_refused_at_roster_cap(gd):
    gd("hire", "EV232")
