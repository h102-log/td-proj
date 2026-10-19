def test_EV1_open_grid_every_edge_reaches_base(gd):
    gd("map", "EV1")


def test_EV2_base_zero_hp_is_defeat(gd):
    gd("map", "EV2")


def test_EV3_wave_spawns_on_map_edge(gd):
    gd("map", "EV3")


def test_EV4_integer_scaling(gd):
    gd("map", "EV4")


def test_EV303_window_fits_largest_integer_scale(gd):
    gd("map", "EV303")


def test_EV304_window_min_size_is_base(gd):
    gd("map", "EV304")
