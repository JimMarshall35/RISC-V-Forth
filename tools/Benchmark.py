import argparse
import pexpect
import time
import hashlib
import subprocess

sha256 = hashlib.sha256()

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

file_hash = ""

git_hash = ""

forth_code_hash = ""

N = 1000000
EXPECTED_VAL = "0x928b54e2"

def get_git_commit_hash() -> str:
    result = subprocess.run(
        ["git", "rev-parse", "HEAD"],
        capture_output=True,
        text=True,
        check=True,
    )
    return result.stdout.strip()

def get_file_hash(path) -> str:
    sha256 = hashlib.sha256()
    with open(path, "rb") as f:
        while chunk := f.read(8192):
            sha256.update(chunk)
    return sha256.hexdigest()

def load_forth_fibonacci_src(proc):
    for l in fib_lines:
        proc.sendline(l)
        proc.expect("\n")

def collect_forth(args):
    with open(args.out,'wb') as logF:
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
            seconds_str = f"{elapsed:.6f}, {N}, {file_hash}, {git_hash}, {forth_code_hash}\n" 
            print(seconds_str)
            with open(args.out, "a") as dataF:
                dataF.write(seconds_str)

    pass

def collect_asm(args):
    with open(args.out,'wb') as logF:
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
            seconds_str = f"{elapsed:.6f}, {N}, {file_hash}, {git_hash}, {forth_code_hash}\n" 
            print(seconds_str)
            with open(args.out, "a") as dataF:
                dataF.write(seconds_str)

    pass

def write_key(path):
    with open(path, "w") as keyF:
        keyF.write("time in seconds, fibonacci number calculated, elf file sha256 hash, git commit hash, benchmark forth code hash")

def main():
    global file_hash, git_hash, forth_code_hash

    parser = argparse.ArgumentParser()

    subparsers = parser.add_subparsers(
        dest="mode",
        required=True,   # Python 3.7+
    )

    # Mode 1
    asm_mode_parser = subparsers.add_parser("asm")
    asm_mode_parser.add_argument("--numreps", type=int, default=10)
    asm_mode_parser.add_argument("--elf_path", type=str, default="../ASMBenchmark.elf")
    asm_mode_parser.add_argument("--out", type=str)
    asm_mode_parser.add_argument("--out_key", type=str)

    # Mode 2
    forth_mode_parser = subparsers.add_parser("forth")
    forth_mode_parser.add_argument("--numreps", type=int, default=10)
    forth_mode_parser.add_argument("--elf_path", type=str, default="../Forth.elf")
    forth_mode_parser.add_argument("--out", type=str)
    forth_mode_parser.add_argument("--out_key", type=str)

    args = parser.parse_args()
    write_key(args.out_key)
    file_hash = get_file_hash(args.elf_path)
    git_hash = get_git_commit_hash()
    forth_code_hash = hashlib.sha256(fib.encode("utf-8")).hexdigest()
    
    print(f"file_hash       {file_hash}")
    print(f"git_hash        {git_hash}")
    print(f"forth_code_hash {forth_code_hash}")

    if args.mode == "asm":
        collect_asm(args)

    elif args.mode == "forth":
        collect_forth(args)

main()
