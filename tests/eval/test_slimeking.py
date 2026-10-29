def test_EV530_slime_king_leap_lands_on_cluster(gd):
    gd("slimeking", "EV530")


def test_EV531_leap_picks_biggest_cluster(gd):
    gd("slimeking", "EV531")


def test_EV532_leap_skips_spots_behind_walls(gd):
    gd("slimeking", "EV532")


def test_EV533_crouch_cancels_but_air_does_not(gd):
    gd("slimeking", "EV533")


def test_EV534_airborne_king_is_not_hit(gd):
    gd("slimeking", "EV534")


def test_EV535_shrink_size_speed_haste(gd):
    gd("slimeking", "EV535")


def test_EV595_king_body_two_cells(gd):
    gd("slimeking", "EV595")
