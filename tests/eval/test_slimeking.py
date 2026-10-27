def test_EV522_slime_king_leap_lands_on_cluster(gd):
    gd("slimeking", "EV522")


def test_EV523_leap_picks_biggest_cluster(gd):
    gd("slimeking", "EV523")


def test_EV524_leap_skips_spots_behind_walls(gd):
    gd("slimeking", "EV524")


def test_EV525_crouch_cancels_but_air_does_not(gd):
    gd("slimeking", "EV525")


def test_EV526_airborne_king_is_not_hit(gd):
    gd("slimeking", "EV526")


def test_EV527_shrink_size_speed_haste(gd):
    gd("slimeking", "EV527")
