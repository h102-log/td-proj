def test_EV306_save_load_replays_same(gd):
    gd("save", "EV306")


def test_EV307_file_roundtrip_and_bad_files(gd):
    gd("save", "EV307")


def test_EV308_saves_when_quiet_not_in_battle(gd):
    gd("save", "EV308")


def test_EV309_end_of_challenge_erases_save(gd):
    gd("save", "EV309")


def test_EV313_leaving_saves_only_when_quiet(gd):
    gd("save", "EV313")

def test_EV421_game_scene_holds_live_prep(gd):
    gd("save", "EV421")


def test_EV422_save_keeps_engineer_jobs(gd):
    gd("save", "EV422")


def test_EV476_save_keeps_families(gd):
    gd("save", "EV476")


def test_EV482_save_version_6(gd):
    gd("save", "EV482")


def test_EV503_folk_state_saved(gd):
    gd("save", "EV503")
