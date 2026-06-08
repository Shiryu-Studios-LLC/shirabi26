import sys
import pytest
from tests.helpers.cli_loader import load_script


@pytest.mark.skipif(sys.platform == "win32", reason="POSIX execution bits don't exist on Windows")
def test_is_runnable_subcommand_requires_executable_file(tmp_path):
    cli = load_script("shirabe")
    sub = tmp_path / "shirabe-demo"
    sub.write_text("#!/bin/sh\n")
    sub.chmod(0o644)

    assert cli._is_runnable_subcommand(sub) is False

    sub.chmod(0o755)
    assert cli._is_runnable_subcommand(sub) is True
