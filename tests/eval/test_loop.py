def test_EV34_prep_battle_alternate(gd):
    gd("loop", "EV34")


def test_EV35_prep_build_is_instant(gd):
    gd("loop", "EV35")


def test_EV36_restart_resets(gd):
    gd("loop", "EV36")


def test_EV37_last_wave_cleared_is_victory(gd):
    gd("loop", "EV37")


def test_EV38_kill_gives_gold(gd):
    gd("loop", "EV38")


def test_EV39_not_enough_gold_rejects_build(gd):
    gd("loop", "EV39")
