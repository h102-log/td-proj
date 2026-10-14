def test_EV119_house_built_in_village_only(gd):
    gd("house", "EV119")


def test_EV120_house_cap(gd):
    gd("house", "EV120")


def test_EV121_tax_from_complete_houses(gd):
    gd("house", "EV121")


def test_EV122_unfinished_house_pays_no_tax(gd):
    gd("house", "EV122")


def test_EV123_destroyed_house_stops_tax(gd):
    gd("house", "EV123")


def test_EV124_engineer_builds_house_in_battle(gd):
    gd("house", "EV124")


def test_EV125_key_0_builds_house(gd):
    gd("house", "EV125")


def test_EV126_enemy_in_village_hits_house(gd):
    gd("house", "EV126")


def test_EV127_enemy_in_village_hits_facility(gd):
    gd("house", "EV127")


def test_EV128_enemy_in_field_ignores_house(gd):
    gd("house", "EV128")


def test_EV129_residents_wander_in_village(gd):
    gd("house", "EV129")
