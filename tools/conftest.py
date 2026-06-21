import pytest

def pytest_addoption(parser):
    parser.addoption("--hardware", action="store_true", default=False, help="Run tests against real hardware connected to usb, if false, will run against qemu")