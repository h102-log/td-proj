def test_EV81_gate_starts_closed_and_opens_by_order(gd):
    gd("castle", "EV81")


def test_EV82_enemy_passes_open_gate_without_damage(gd):
    gd("castle", "EV82")


def test_EV83_merc_crosses_castle_only_through_open_gate(gd):
    gd("castle", "EV83")


def test_EV84_gate_with_enemy_inside_does_not_close(gd):
    gd("castle", "EV84")


def test_EV85_prep_upgrade_raises_level_and_max_hp(gd):
    gd("castle", "EV85")


def test_EV86_battle_upgrade_needs_idle_engineer(gd):
    gd("castle", "EV86")


def test_EV87_upgrade_keeps_damage_taken(gd):
    gd("castle", "EV87")


def test_EV88_interrupted_upgrade_resumes_free(gd):
    gd("castle", "EV88")


def test_EV244_upgraded_gate_keeps_enemy_route(gd):
    gd("castle", "EV244")
