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


def test_EV248_round3_ground_enemy_goes_to_nearest_gate(gd):
    gd("gates", "EV248")


def test_EV249_after_nearest_gate_falls_enemy_goes_to_base(gd):
    gd("gates", "EV249")


def test_EV250_enemy_passes_open_nearest_gate(gd):
    gd("gates", "EV250")


def test_EV251_flying_enemy_ignores_nearest_gate(gd):
    gd("gates", "EV251")


def test_EV252_round3_forecast_passes_nearest_gate(gd):
    gd("gates", "EV252")
