def test_EV61_attacker_remembers_target(gd):
    gd("show", "EV61")


def test_EV62_v_toggles_hp_bars(gd):
    gd("show", "EV62")


def test_EV362_boss_hp_bar_always(gd):
    gd("show", "EV362")


def test_EV504_boss_flag_hp_bar(gd):
    gd("show", "EV504")
