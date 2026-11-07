def test_EV212_quest_files_match_table(gd):
    gd("quests", "EV212")


def test_EV213_mission_judged_when_round_won(gd):
    gd("quests", "EV213")


def test_EV215_no_commissions_missions_only(gd):
    gd("quests", "EV215")


def test_EV216_round_tally(gd):
    gd("quests", "EV216")


def test_EV217_mission_draw_and_no_quest_stage(gd):
    gd("quests", "EV217")


def test_EV218_test_stage_uses_all_quests(gd):
    gd("quests", "EV218")


def test_EV219_conditions_follow_tally(gd):
    gd("quests", "EV219")


def test_EV221_new_challenge_resets_quests(gd):
    gd("quests", "EV221")


def test_EV234_lost_round_fails_quests(gd):
    gd("quests", "EV234")
