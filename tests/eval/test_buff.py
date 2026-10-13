def test_EV74_buff_raises_nearby_merc_damage(gd):
    gd("buff", "EV74")


def test_EV75_buff_ends_after_duration(gd):
    gd("buff", "EV75")


def test_EV76_buff_cooldown_separate_from_q(gd):
    gd("buff", "EV76")


def test_EV77_buff_only_for_mercs_in_range_at_cast(gd):
    gd("buff", "EV77")
