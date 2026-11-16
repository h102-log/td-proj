def test_EV1133_bucket_twin_matches_full_scan_every_step(gd):
    gd("scale", "EV1133")


def test_EV1134_bucket_not_stale_after_outside_write(gd):
    gd("scale", "EV1134")


def test_EV1135_bucket_cuts_candidates_standing_field(gd):
    gd("scale", "EV1135")
