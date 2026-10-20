def test_EV310_main_menu_buttons_and_confirm(gd):
    gd("menu", "EV310")


def test_EV311_esc_menu_pauses(gd):
    gd("menu", "EV311")


def test_EV312_esc_cancels_aim_first(gd):
    gd("menu", "EV312")


def test_EV314_quickcast_casts_on_key(gd):
    gd("menu", "EV314")


def test_EV315_settings_defaults_and_persist(gd):
    gd("menu", "EV315")


def test_EV316_settings_apply_now(gd):
    gd("menu", "EV316")


def test_EV317_menus_keyboard_reachable(gd):
    gd("menu", "EV317")


def test_EV318_start_window_mode(gd):
    gd("menu", "EV318")
