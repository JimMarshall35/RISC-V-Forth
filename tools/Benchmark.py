import argparse
import pexpect
import time

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

fib_lines = [x.strip() + "\r" for x in fib.splitlines()]

N = 1000000
EXPECTED_VAL = "0x928b54e2"

def load_forth_fibonacci_src(proc):
    for l in fib_lines:
        proc.sendline(l)
        proc.expect("\n")

def collect_forth(args):
    with open('benchmark_data/benchmark_log.txt','wb') as logF:
        proc = None
        try:
            proc = pexpect.spawn("minicom -D /dev/ttyUSB0 -b 115200", timeout=10)
        except pexpect.ExceptionPexpect as e:
            print(f"Error starting minicom: {e}")
            assert False, "minicom failed to start"
        time.sleep(2)
        proc.logfile = logF
        print("loading fibonacci src...")
        load_forth_fibonacci_src(proc)
        print("loading fibonacci src done.")

        for i in range(args.numreps):
            proc.send(f"{N} fib")
            start = time.perf_counter()
            proc.send("\r")
            proc.expect(EXPECTED_VAL, timeout=10)
            elapsed = time.perf_counter() - start
            seconds_str = f"{elapsed:.6f}\n" 
            print(seconds_str)
            with open("benchmark_data/benchmark_forth_data.txt", "a") as dataF:
                dataF.write(seconds_str)

    pass

def collect_asm(args):
    with open('benchmark_data/benchmark_log.txt','wb') as logF:
        proc = None
        try:
            proc = pexpect.spawn("minicom -D /dev/ttyUSB0 -b 115200", timeout=10)
        except pexpect.ExceptionPexpect as e:
            print(f"Error starting minicom: {e}")
            assert False, "minicom failed to start"

        proc.logfile = logF
        time.sleep(2)
        for i in range(args.numreps):
            start = time.perf_counter()
            proc.send(f"\r")
            proc.expect(EXPECTED_VAL, timeout=10)
            elapsed = time.perf_counter() - start
            seconds_str = f"{elapsed:.6f}\n" 
            print(seconds_str)
            with open("benchmark_data/benchmark_asm_data.txt", "a") as dataF:
                dataF.write(seconds_str)

    pass

def main():
    parser = argparse.ArgumentParser()

    subparsers = parser.add_subparsers(
        dest="mode",
        required=True,   # Python 3.7+
    )

    # Mode 1
    asm_mode_parser = subparsers.add_parser("asm")
    asm_mode_parser.add_argument("--numreps", type=int, default=10)

    # Mode 2
    forth_mode_parser = subparsers.add_parser("forth")
    forth_mode_parser.add_argument("--numreps", type=int, default=10)

    args = parser.parse_args()

    if args.mode == "asm":
        collect_asm(args)

    elif args.mode == "forth":
        collect_forth(args)

main()
