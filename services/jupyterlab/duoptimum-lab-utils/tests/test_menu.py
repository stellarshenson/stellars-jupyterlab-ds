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


# --- enable_env gating (JUPYTERLAB_USER_ENV_ENABLE and friends) ---------------

def _gated(name, var="GATE_VAR"):
    return {"name": name, "enable_env": var}


def test_prune_disabled_hides_item_only_on_literal_zero(monkeypatch):
    items = [_gated("Gated"), {"name": "Plain"}]
    monkeypatch.setenv("GATE_VAR", "0")
    assert [i["name"] for i in menu.prune_disabled(list(items))] == ["Plain"]
    # unset, 1 and arbitrary values keep the item (platform switch convention)
    monkeypatch.delenv("GATE_VAR")
    assert [i["name"] for i in menu.prune_disabled(list(items))] == ["Gated", "Plain"]
    for value in ("1", "", "yes", "00"):
        monkeypatch.setenv("GATE_VAR", value)
        assert [i["name"] for i in menu.prune_disabled(list(items))] == ["Gated", "Plain"]
    monkeypatch.setenv("GATE_VAR", " 0 ")  # whitespace-tolerant, like the shell guards
    assert [i["name"] for i in menu.prune_disabled(list(items))] == ["Plain"]


def test_prune_disabled_recurses_into_submenus(monkeypatch):
    monkeypatch.setenv("GATE_VAR", "0")
    tree = [{"name": "Settings", "submenu": [_gated("Gated"), {"name": "Kept"}]}]
    pruned = menu.prune_disabled(tree)
    assert [i["name"] for i in pruned[0]["submenu"]] == ["Kept"]


def test_prune_disabled_passes_non_dict_items_through():
    assert menu.prune_disabled(["junk", None]) == ["junk", None]


def test_load_menu_config_applies_gating(data_home, monkeypatch):
    yml = data_home / "lab-utils.yml"
    yml.write_text(yml.read_text().replace(
        '    - id: "alpha.sh"\n',
        '    - id: "alpha.sh"\n      enable_env: "GATE_VAR"\n'))
    monkeypatch.setenv("GATE_VAR", "0")
    names = [i["name"] for i in menu.load_menu_config()["menu"]["items"]]
    assert "Alpha" not in names and "Echo" in names


def test_menu_file_items_apply_gating(data_home, monkeypatch):
    target = data_home / "gated-menu.yml"
    target.write_text(
        "items:\n"
        "  - id: \"echo a\"\n    name: \"Gated\"\n    enable_env: \"GATE_VAR\"\n"
        "  - id: \"echo b\"\n    name: \"Kept\"\n")
    monkeypatch.setenv("GATE_VAR", "0")
    assert [i["name"] for i in menu.load_menu_file_items(str(target))] == ["Kept"]
