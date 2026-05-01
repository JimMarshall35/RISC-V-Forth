import argparse

#
# For debugging purposes forth vm can print addresses of each primitive about to be entered into,
# This simple script "greps" for the address in the .map file and prints it
#

def do_args():
    parser = argparse.ArgumentParser(
                prog='Resolve Trace Addresses',
                description='resolve trace addresses to their symbols',
                epilog='Jim Marshall - Riscv assembly forth 2025')
    parser.add_argument("input_file", type=str)
    parser.add_argument("map_file", type=str)
    return parser.parse_args()

def main():
    args = do_args()
    trace_lines = []
    map_lines = []
    with open(args.input_file, "r") as f:
        trace_lines = f.readlines()
    
    with open(args.map_file, "r") as f:
        map_lines = f.readlines()
    
    for line in trace_lines:
        matching_map_lines = [x for x in map_lines if line.strip() in x]
        assert len(matching_map_lines) == 1
        print(matching_map_lines[0], end="")

main()