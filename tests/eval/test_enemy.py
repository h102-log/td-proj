def test_EV11_attacks_unit_in_sight(gd):
    gd("enemy", "EV11")


def test_EV12_unit_in_sight_beats_counterattack(gd):
    gd("enemy", "EV12")


def test_EV13_walks_to_base_and_attacks(gd):
    gd("enemy", "EV13")


def test_EV14_counterattacks_tower(gd):
    gd("enemy", "EV14")


def test_EV15_breaks_wall_to_reach_shooter(gd):
    gd("enemy", "EV15")


def test_EV16_body_block_enemy_attacks_blocker(gd):
    gd("enemy", "EV16")


def test_EV17_ignores_non_shooting_tower(gd):
    gd("enemy", "EV17")


def test_EV18_resumes_after_counter_target_dies(gd):
    gd("enemy", "EV18")
