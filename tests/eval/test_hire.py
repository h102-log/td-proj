def test_EV192_challenge_starts_with_pick_window(gd):
    gd("hire", "EV192")


def test_EV193_no_map_commands_while_hiring(gd):
    gd("hire", "EV193")


def test_EV194_hire_data_keeps_only_lineup(gd):
    gd("hire", "EV194")


def test_EV197_pick_is_free_up_to_lineup(gd):
    gd("hire", "EV197")


def test_EV198_lineup_change_between_rounds(gd):
    gd("hire", "EV198")


def test_EV201_no_hero_start_and_lineup_carries_over(gd):
    gd("hire", "EV201")


def test_EV202_hero_cells_in_front_of_gate_unbuildable(gd):
    gd("hire", "EV202")


def test_EV203_pick_order_and_hero_hotkeys(gd):
    gd("hire", "EV203")


def test_EV1127_pick_three_free_and_fixed(gd):
    gd("hire", "EV1127")


def test_EV1128_new_run_picks_again(gd):
    gd("hire", "EV1128")
