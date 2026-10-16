def test_EV222_gate_locks_for_gate_lock_seconds_in_battle(gd):
    gd("gates", "EV222")


def test_EV223_prep_toggles_have_no_lock(gd):
    gd("gates", "EV223")


def test_EV224_lock_is_per_gate(gd):
    gd("gates", "EV224")


def test_EV225_wave_end_clears_lock(gd):
    gd("gates", "EV225")


def test_EV226_refused_order_sets_no_lock(gd):
    gd("gates", "EV226")


def test_EV235_gate_toggle_reroutes_waiting_unit(gd):
    gd("gates", "EV235")
