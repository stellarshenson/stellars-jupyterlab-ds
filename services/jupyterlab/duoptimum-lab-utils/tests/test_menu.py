"""Menu config loading, directory scans, external menu files, aux injection."""

from duoptimum_lab_utils import menu


def test_load_menu_config(data_home):
    config = menu.load_menu_config()
    items = config["menu"]["items"]
    names = [i["name"] for i in items]
    assert names == ["Alpha", "Echo", "Sub Menu", "Picker", "Local Scripts"]


def test_aux_menu_injected_before_last(data_home, monkeypatch):
    monkeypatch.setenv("JUPYTERLAB_AUX_MENU_PATH", str(data_home / "aux"))
    config = menu.load_menu_config()
    items = config["menu"]["items"]
    # injected before the last root item (Local Scripts)
    assert items[-1]["name"] == "Local Scripts"
    assert items[-2]["name"] == "Auxiliary Menu"
    child_names = [c["name"] for c in items[-2]["submenu"]]
    assert "Aux Submenu" in child_names  # the .yml became a submenu
    assert "aux-tool" in child_names     # the executable became an item


def test_scan_directory_for_menu_items(data_home):
    items = menu.scan_directory_for_menu_items(str(data_home / "aux"))
    by_name = {i["name"]: i for i in items}
    assert by_name["aux-tool"]["marker"] == "custom"
    assert by_name["aux-menu"]["marker"] == "conda"
    assert by_name["aux-menu"]["_conda_env"] is True


def test_scan_directory_missing(data_home):
    assert menu.scan_directory_for_menu_items(str(data_home / "nope")) == []


def test_menu_file_dict_form(data_home):
    items = menu.load_menu_file_items(str(data_home / "extra-menu-dict.yml"))
    assert [i["name"] for i in items] == ["Extra Alpha"]


def test_menu_file_list_form(data_home):
    items = menu.load_menu_file_items(str(data_home / "extra-menu-list.yml"))
    assert [i["name"] for i in items] == ["Extra Beta"]


def test_menu_file_missing(data_home):
    assert menu.load_menu_file_items(str(data_home / "absent.yml")) == []
