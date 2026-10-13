def test_EV43_battle_build_completes_over_time(gd):
    gd("engineer", "EV43")


def test_EV44_cancel_refunds_all(gd):
    gd("engineer", "EV44")


def test_EV45_engineer_death_leaves_partial_hp(gd):
    gd("engineer", "EV45")


def test_EV46_resume_by_other_engineer(gd):
    gd("engineer", "EV46")


def test_EV48_enemy_repaths_around_completed_wall(gd):
    gd("engineer", "EV48")


def test_EV49_unfinished_tower_does_not_fire(gd):
    gd("engineer", "EV49")


def test_EV51_nearest_idle_engineer_assigned(gd):
    gd("engineer", "EV51")


def test_EV52_no_idle_engineer_rejects_build(gd):
    gd("engineer", "EV52")


def test_EV69_engineer_counts_for_cap(gd):
    gd("engineer", "EV69")


def test_EV70_demolish_takes_time_no_refund(gd):
    gd("engineer", "EV70")


def test_EV71_battle_click_picks_tower(gd):
    gd("engineer", "EV71")


def test_EV72_finish_unfinished_in_prep(gd):
    gd("engineer", "EV72")


def test_EV73_workshop_makes_engineer(gd):
    gd("engineer", "EV73")
