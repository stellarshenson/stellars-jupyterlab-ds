"""Script resolution and directory walking."""

from duoptimum_lab_utils import resolver


def test_resolve_bare_name(data_home):
    path = resolver.resolve_script_path("alpha")
    assert path is not None
    assert path.name == "alpha.sh"


def test_resolve_with_suffix(data_home):
    assert resolver.resolve_script_path("alpha.sh").name == "alpha.sh"


def test_resolve_parent_child(data_home):
    path = resolver.resolve_script_path("parent/child")
    assert path is not None
    assert path.parent.name == "parent.d"
    assert path.name == "child.sh"


def test_resolve_in_lib_dir(data_home):
    assert resolver.resolve_script_path("mylib").name == "mylib.sh"


def test_resolve_absolute_path(data_home):
    target = data_home / "lab-utils.d" / "alpha.sh"
    assert resolver.resolve_script_path(str(target)) == target


def test_resolve_not_found(data_home):
    assert resolver.resolve_script_path("does-not-exist") is None


def test_description_from_marker(data_home):
    path = data_home / "lab-utils.d" / "alpha.sh"
    assert resolver.get_script_description(path) == "Alpha script"


def test_description_missing_marker(tmp_path):
    script = tmp_path / "plain.sh"
    script.write_text("#!/bin/bash\necho hi\n")
    assert resolver.get_script_description(script) == "No description available"


def test_get_all_scripts_structure(data_home):
    global_scripts, _ = resolver.get_all_scripts()
    by_name = {s["name"]: s for s in global_scripts}

    # top-level leaves
    assert by_name["alpha"]["level"] == "top"
    assert by_name["beta"]["level"] == "top"

    # top script with a matching .d subdir, plus its child
    assert by_name["tools"]["path"] is not None
    assert by_name["tools/sub"]["level"] == "child"

    # virtual parent (parent.d with no parent.sh)
    assert by_name["parent"]["path"] is None
    assert by_name["parent/child"]["level"] == "child"
