def test_EV159_built_things_carry_to_next_round(gd):
    gd("rounds", "EV159")


def test_EV160_damage_and_mercs_carry_over(gd):
    gd("rounds", "EV160")


def test_EV161_gold_carries_over(gd):
    gd("rounds", "EV161")


def test_EV162_tax_once_at_round_end(gd):
    gd("rounds", "EV162")


def test_EV163_round_win_waits_between_rounds(gd):
    gd("rounds", "EV163")


def test_EV164_no_map_commands_between_rounds(gd):
    gd("rounds", "EV164")


def test_EV165_loss_ends_challenge_new_starts_fresh(gd):
    gd("rounds", "EV165")


def test_EV166_new_challenge_resets_village_castle_hero(gd):
    gd("rounds", "EV166")


def test_EV167_hero_across_rounds(gd):
    gd("rounds", "EV167")


def test_EV168_gate_state_carries_over(gd):
    gd("rounds", "EV168")


def test_EV169_test_challenge_rounds(gd):
    gd("rounds", "EV169")


def test_EV170_round_waves_from_resource(gd):
    gd("rounds", "EV170")


def test_EV243_downed_heroes_return_with_1_hp(gd):
    gd("rounds", "EV243")
