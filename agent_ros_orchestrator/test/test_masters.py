import pytest

from agent_ros_orchestrator.config import load_iolink_config
from agent_ros_orchestrator.models.modbus_m import SlaveIOLink


@pytest.fixture
def test_config():
    return load_iolink_config()


def test_masters(test_config):
    assert isinstance(test_config.iolinks[0], SlaveIOLink)
