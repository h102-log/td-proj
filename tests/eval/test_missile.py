def test_EV401_hit_on_arrival(gd):
    gd("missile", "EV401")


def test_EV402_target_dies_midflight(gd):
    gd("missile", "EV402")


def test_EV403_homing(gd):
    gd("missile", "EV403")


def test_EV404_counter_and_bless_on_arrival(gd):
    gd("missile", "EV404")


def test_EV405_split_arrows_fly_apart(gd):
    gd("missile", "EV405")


def test_EV406_launch_wait_and_orphan_missile(gd):
    gd("missile", "EV406")


def test_EV407_wave_end_clears_missiles(gd):
    gd("missile", "EV407")


def test_EV408_stacks_at_launch_ignore_on_arrival(gd):
    gd("missile", "EV408")


def test_EV409_hit_kill_events_on_arrival(gd):
    gd("missile", "EV409")
