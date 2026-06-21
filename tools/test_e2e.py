import pexpect
# This script is used to run end-to-end tests for the RISC-V Forth system.
# It is run as one long "soak test" where we have a dialog with the forth running in QEMU.
# The tests are designed to be run in GitHub Actions.
# It uses pexpect to interact with a QEMU instance running the Forth system.
# The pexepect library does NOT work properly on windows so don't expect this to work on windows.
# The tests work on the principle of matching strings. Each test should call show at the end to
# display the data stack. Each test case has to reset the stack after it is run, and needs
# to call show at the end to prove to the test framework that the stack is in the expected state.
# If you change the way the stack is displayed you'll need to change this.
# If one test fails the rest won't be run.

# renamed to stop pytest thinking this is a test class

# calculate nth fibonacci number (with 0 being fibonacci number 1)
fib = """: fib         
  dup 0 = if
    drop
    r
  else dup 1 = if
    0 . cr
    drop
    r
  else dup 2 = if
    1 . cr
    drop
    r
  else
    0 1 rot 2 -
    0 do                                                                                                                                                 
        2dup +                                                                                                                                       
        rot drop                                                                                                                                              
    loop
  then
  then
  then
  . cr drop                                                                                                                                                                                                                          
;
"""

proc = None


fib_lines = [x.strip() + "\r" for x in fib.splitlines()]

class NotPyTestCase:
    def __init__(self, input_strs, expected_data_stack, cleanup, testName="anonymous"):
        self.input_strs = input_strs
        self.expected_data_stack_string = expected_data_stack
        self.cleanup = cleanup
        self.testName = testName

    def run(self, proc):
        for input_str in self.input_strs:
            proc.sendline(input_str)
        try:
            proc.expect_exact(self.expected_data_stack_string, timeout=10)
        except pexpect.TIMEOUT:
            print(f"Timeout waiting for expected output: {self.expected_data_stack_string}. Input strings: {' '.join(self.input_strs)} Test name: {self.testName}")
            assert False, f"Test '{self.testName}' failed due to timeout"
        except pexpect.EOF:
            print(f"EOF for expected output: {self.expected_data_stack_string}. Input strings: {' '.join(self.input_strs)}")
            assert False, "EOF"
        if self.cleanup:
            proc.sendline(self.cleanup)
            try:
                proc.expect_exact("[  ]", timeout=10)
            except pexpect.TIMEOUT:
                print(f"Timeout waiting for empty stack after cleanup. Input strings: {' '.join(self.input_strs)} . Cleanup: {self.cleanup}")
                assert False, "Test failed due to timeout"
            except pexpect.EOF:
                print(f"EOF waiting for empty stack after cleanup. Input strings: {' '.join(self.input_strs)} . Cleanup: {self.cleanup}")
                assert False, "EOF"

tests = [
    # the forth code checks for a carriage return to process the input line.
    # Windows terminal outputs \r\n and this code was developed on Windows, 
    # but the CI runs on Linux, so we need to add \r

    # push literals and show 
    NotPyTestCase(["1 2 show\r"], "[ 1, 2 ]", "drop drop show\r", 
                  "push literals and show"),

    # test +
    NotPyTestCase(["1 2 + show\r"], "[ 3 ]", "drop show\r", 
                  "test +"),

    # test -
    NotPyTestCase(["4 6 - show\r"], "[ -2 ]", "drop show\r", 
                  "test -"),

    # test : and ;
    NotPyTestCase([": jim 1 2 3 4 5 ;\r", "jim show\r"], "[ 1, 2, 3, 4, 5 ]", "drop drop drop drop drop show\r",
                  "test : and ;"),

    # test one word being compiled in another
    NotPyTestCase([": jim2 jim 6 7 8 ;\r", "jim2 show\r"], "[ 1, 2, 3, 4, 5, 6, 7, 8 ]", "drop drop drop drop drop drop drop drop show\r",
                  "test one word being compiled in another"),

    # test if / else
    NotPyTestCase([": jim if 1 2 3 else 4 5 6 then ;\r", "1 jim\r", "0 jim show\r"], "[ 1, 2, 3, 4, 5, 6 ]", "drop drop drop drop drop drop show\r", 
                  "test if / else"),

    # test begin / until
    NotPyTestCase([": begintest 0 begin 1 + dup 10 = if r then 0 until ;\r", "begintest show\r"], "[ 10 ]", "drop show\r",
                  "test begin / until"),

    # test do / loop
    NotPyTestCase([
        ": testloop 0 do i loop ;\r", 
        "4 testloop show\r"
    ], 
    "[ 0, 1, 2, 3 ]", 
    "drop drop drop drop show\r",
    "test do / loop"),
    NotPyTestCase(["3 testloop show\r"], "[ 0, 1, 2 ]", "drop drop drop show\r"),

    # test do / loop and if / else together
    NotPyTestCase([
        ": k 0 do i 2 mod if -1 else i then loop ;\r",
        "5 k show\r"
    ], 
    "[ 0, -1, 2, -1, 4 ]", 
    "drop drop drop drop drop show\r",
    "test do / loop and if / else together"),

    # test create
    NotPyTestCase([
        ": var create , ;\r",
        "42 var v1\r",
        "v1 @ show\r",
    ], 
    "[ 42 ]",  # expected stack picture
    "drop show\r",
    "test create"), # cleanup stack

    # test does>
    NotPyTestCase([
        ": const create , does> @ ;\r",
        "56 const c1\r",
        "c1 show\r",
    ], 
    "[ 56 ]", # expected stack picture
    "drop show\r",
    "test does>"), # cleanup stack

    # test print int
    NotPyTestCase([
        "8 . cr\r"
    ],
    "0x00000008",
    "show\r",
    "test print int"),

    # test multiline function
    NotPyTestCase([
        ": foo\r",
        "  3 0 do\r",
        "    i .\r",
        "  loop\r",
        "  cr\r",
        ";\r",
        "foo\r",
    ],
    "0x000000000x000000010x00000002",
    "show\r",
    "test multiline function"),

    NotPyTestCase(fib_lines + ["20 fib\r"], "0x00001055", "show\r", "test 20th fibonacci number"),
    NotPyTestCase(fib_lines + ["1 fib\r"], "0x00000000", "show\r", "test 1st fibonacci number"),
    NotPyTestCase(fib_lines + ["2 fib\r"], "0x00000001", "show\r", "test 2nd fibonacci number"),
    NotPyTestCase(fib_lines + ["3 fib\r"], "0x00000001", "show\r", "test 3rd fibonacci number"),
    NotPyTestCase(fib_lines + ["4 fib\r"], "0x00000002", "show\r", "test 4th fibonacci number"),
    NotPyTestCase(fib_lines + ["5 fib\r"], "0x00000003", "show\r", "test 5th fibonacci number"),
    NotPyTestCase(fib_lines + ["6 fib\r"], "0x00000005", "show\r", "test 6th fibonacci number"),
    NotPyTestCase(fib_lines + ["100 fib\r"], "0xcafb7902", "show\r", "test 100th fibonacci number"),
]

def test_run(request):
    global proc
    with open('testlog.txt','wb') as logF:
        try:
            if request.config.getoption("--hardware"):
                import hardware_test_runner.bootloader
                proc = pexpect.spawn("minicom -D /dev/ttyUSB0 -b 115200", timeout=10)
                hardware_test_runner.bootloader.normal_reset()
            else:
                proc = pexpect.spawn("qemu-system-riscv32 -nographic -serial mon:stdio -machine virt -bios QEMUForth.elf -qmp tcp:localhost:4444,server,wait=off", timeout=10)
        except pexpect.ExceptionPexpect as e:
            print(f"Error starting QEMU: {e}")
            assert False, "QEMU failed to start"

        proc.logfile = logF

        try:
            proc.expect("dict end: 0x[0-9a-fA-F]{8}", timeout=10)
        except pexpect.TIMEOUT:
            print("Timeout waiting for 'dict end:' prompt.")
            assert False, "QEMU did not output expected prompt"
        except pexpect.EOF:
            print("pexpect.EOF")
            assert False, "QEMU did not output expected prompt"

        for test in tests:
            test.run(proc)


    assert True