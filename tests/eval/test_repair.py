def test_EV151_prep_repair_costs_refund_remainder(gd):
    gd("repair", "EV151")


def test_EV152_castle_and_base_repair_rates(gd):
    gd("repair", "EV152")


def test_EV153_repair_refused_without_gold(gd):
    gd("repair", "EV153")


def test_EV154_castle_rubble_passable_unbuildable(gd):
    gd("repair", "EV154")


def test_EV155_prep_restore_keeps_level(gd):
    gd("repair", "EV155")


def test_EV156_battle_repair_by_engineer_over_time(gd):
    gd("repair", "EV156")


def test_EV157_interrupted_repair_resumes_free(gd):
    gd("repair", "EV157")


def test_EV158_battle_restore_rises_when_engineer_arrives(gd):
    gd("repair", "EV158")
