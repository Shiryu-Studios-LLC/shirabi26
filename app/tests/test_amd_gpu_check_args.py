import subprocess
import shutil
import pytest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parent.parent / "scripts" / "check-docker-amd-gpu.sh"


def _has_functional_bash():
    if not shutil.which("bash"):
        return False
    try:
        res = subprocess.run(["bash", "-c", "echo ok"], capture_output=True, text=True, timeout=2)
        return res.returncode == 0 and "ok" in res.stdout
    except Exception:
        return False


HAS_BASH = _has_functional_bash()


@pytest.mark.skipif(not HAS_BASH, reason="Functional bash shell not available")
def test_amd_gpu_check_rejects_unknown_extra_arg_before_diagnostics():
    proc = subprocess.run(
        ["bash", str(SCRIPT), "--bad-option"],
        capture_output=True,
        text=True,
        check=False,
    )

    assert proc.returncode == 1
    assert "Unknown option: --bad-option" in proc.stderr


@pytest.mark.skipif(not HAS_BASH, reason="Functional bash shell not available")
def test_amd_gpu_check_shell_syntax():
    subprocess.run(["bash", "-n", str(SCRIPT)], check=True)

