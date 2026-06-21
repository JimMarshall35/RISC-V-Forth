import pytest

def pytest_addoption(parser):
    parser.addoption("--hardware", action="store_true", default=False, help="Run tests against real hardware connected to usb, if false, will run against qemu")

def pytest_sessionfinish(session, exitstatus):
    print(f"\nSession finished with exit status: {exitstatus}")
    # cleanup code here — always runs