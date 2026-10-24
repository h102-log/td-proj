def test_EV19_right_click_move(gd):
    gd("hero", "EV19")


def test_EV20_auto_attack(gd):
    gd("hero", "EV20")


def test_EV21_skill_only_on_command(gd):
    gd("hero", "EV21")


def test_EV22_down_until_wave_end_then_returns(gd):
    gd("hero", "EV22")


def test_EV23_no_return_when_revive_off(gd):
    gd("hero", "EV23")


def test_EV24_hero_down_is_not_defeat(gd):
    gd("hero", "EV24")


def test_EV246_hero_chases_enemy_within_sight(gd):
    gd("hero", "EV246")


def test_EV383_walking_hero_does_not_attack(gd):
    gd("hero", "EV383")


def test_EV384_hero_stands_through_attack_pose(gd):
    gd("hero", "EV384")


def test_EV385_hero_sent_onto_enemy_arrives_and_fights(gd):
    gd("hero", "EV385")


def test_EV391_blocked_hero_keeps_walking(gd):
    gd("hero", "EV391")


def test_EV393_hero_attack_move(gd):
    gd("hero", "EV393")


def test_EV394_target_attack(gd):
    gd("hero", "EV394")
