def test_EV518_slime_splits_into_two_slimelets(gd):
    gd("split", "EV518")


def test_EV519_big_slime_splits_twice_wave_waits(gd):
    gd("split", "EV519")


def test_EV520_split_children_fresh_state(gd):
    gd("split", "EV520")


def test_EV521_split_no_spawn_signal_blocked_spot(gd):
    gd("split", "EV521")
