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
