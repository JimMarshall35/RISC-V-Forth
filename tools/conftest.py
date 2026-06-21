import pytest
import test_e2e
import pexpect

def pytest_addoption(parser):
    parser.addoption("--hardware", action="store_true", default=False, help="Run tests against real hardware connected to usb, if false, will run against qemu")

def pytest_sessionfinish(session, exitstatus):
    print(f"\nSession finished with exit status: {exitstatus}")
    # cleanup code here — always runs
    if session.config.getoption("--hardware"):
        # Send Ctrl-A then 'x' to bring up exit dialog
        test_e2e.proc.send("\x01")   # Ctrl-A
        test_e2e.proc.send("x")
        # minicom asks "Leave without reset?" - confirm
        test_e2e.proc.expect("Leave")
        test_e2e.proc.sendline("")

        # Wait for the process to actually terminate
        test_e2e.proc.expect(pexpect.EOF)
        test_e2e.proc.close()
    else:
        # todo: handle qemu exit here - or just send a KILL signal to the process regardless of which one it is
        pass