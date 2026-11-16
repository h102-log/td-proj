def test_EV1155_mixed_group_number_key_keeps_group_and_moves_caster(gd):
    gd("herobar", "EV1155")


def test_EV1156_hero_only_or_absent_from_group_selects_one(gd):
    gd("herobar", "EV1156")


def test_EV1157_dead_or_missing_hero_key_changes_nothing(gd):
    gd("herobar", "EV1157")


def test_EV1158_skill_keys_skip_dead_first_hero_in_group(gd):
    gd("herobar", "EV1158")


def test_EV1159_caster_change_cancels_other_heros_aim(gd):
    gd("herobar", "EV1159")


def test_EV1160_portrait_pick_border_and_caster_pointer(gd):
    gd("herobar", "EV1160")


def test_EV1161_pointer_shape_and_dash_seconds_look(gd):
    gd("herobar", "EV1161")


def test_EV1162_portrait_dash_seconds_and_tooltip_line(gd):
    gd("herobar", "EV1162")


def test_EV1163_space_on_cooldown_flashes_portraits_toast_refuse(gd):
    gd("herobar", "EV1163")
