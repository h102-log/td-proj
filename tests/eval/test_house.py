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


def test_EV462_no_house_on_roads(gd):
    gd("house", "EV462")


def test_EV468_no_house_on_water_or_bridge(gd):
    gd("house", "EV468")


def test_EV471_residents_off_water(gd):
    gd("house", "EV471")


def test_EV473_household_types_and_looks(gd):
    gd("house", "EV473")


def test_EV474_household_type_spread(gd):
    gd("house", "EV474")


def test_EV475_family_moves_in_when_built_and_leaves_when_sold(gd):
    gd("house", "EV475")
