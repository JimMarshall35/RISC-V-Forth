#!/usr/bin/env bash
#
# benchmark.sh
# script for benchmarking forth against assembly, calling Benchmark.py
#
set -euo pipefail

# ---- Defaults ----
ELF_FORTH=""
ELF_ASM=""
BENCHMARK_PY=""
WCHISP=""
BOOTLOADER=""
OUTPUT_ASM=""
OUTPUT_FORTH=""

POSITIONAL=()

usage() {
    cat <<EOF
Usage: ${0##*/} [OPTIONS] [POSITIONAL...]

Options:
  -b, --bootloader_script PATH  Path to bootloader python script
  -w, --wchisp PATH             Path to wchisp tool
  -e, --elf_forth FILE          Input forth elf file
  -a, --elf_asm FILE            Input assembly elf file
  -m, --benchmark_py FILE       Python benchmark script
  -oa, --output_asm             ASM output file
  -of, --output_forth           forth output file
  -h, --help                    Show this help message and exit
Positional:
  Any remaining arguments after options are collected as positional args.

Examples:
  ${0##*/} -e Forth.elf
EOF
}

# ---- Parse ----
while [[ $# -gt 0 ]]; do
    case "$1" in
	-b|--bootloader_script)
        BOOTLOADER="$2"
	    shift 2
	    ;;
    -e|--elf_forth)
        ELF_FORTH="$2"
        shift 2
        ;;
    -a|--elf_asm)
        ELF_ASM="$2"
        shift 2
        ;;
    -m|--benchmark_py)
        BENCHMARK_PY="$2"
        shift 2
        ;;
	-w|--wchisp)
	    WCHISP="$2"
	    shift 2
	    ;;
    -oa|--output_asm)
	    OUTPUT_ASM="$2"
	    shift 2
	    ;;
    -of|--output_forth)
	    OUTPUT_FORTH="$2"
	    shift 2
	    ;;
    -h|--help)
        usage
        exit 0
        ;;
    --)
        shift
        POSITIONAL+=("$@")
        break
        ;;
    -*)
        echo "Unknown option: $1" >&2
        usage
        exit 1
        ;;
    *)
        POSITIONAL+=("$1")
        shift
        ;;
    esac
done

# Restore positional args into $1, $2, ...
set -- "${POSITIONAL[@]:-}"

# ---- Validation ----
if [[ -z "$ELF_FORTH" ]]; then
    echo "Error: --elf is required" >&2
    usage
    exit 1
fi

if [[ -z "$ELF_ASM" ]]; then
    echo "Error: --elf is required" >&2
    usage
    exit 1
fi

if [[ -z "$BENCHMARK_PY" ]]; then
    echo "Error: --elf is required" >&2
    usage
    exit 1
fi

if [[ -z "$WCHISP" ]]; then
   echo "Error: --wchisp is required" >&2
   usage
   exit 1
fi

if [[ -z "$BOOTLOADER" ]]; then
   echo "Error: --bootloader_script is required" >&2
   usage
   exit 1
fi

if [[ -z "$OUTPUT_ASM" ]]; then
   echo "Error: --oa is required" >&2
   usage
   exit 1
fi

if [[ -z "$OUTPUT_FORTH" ]]; then
   echo "Error: --of is required" >&2
   usage
   exit 1
fi



flash_elf() {
    python3 $BOOTLOADER bootloader
    sleep 2
    $WCHISP flash $1
    sleep 2
    python3 $BOOTLOADER reset
    sleep 2
}


# ---- Body ----
flash_elf "$ELF_FORTH"

python3 "$BENCHMARK_PY" forth \
    --numreps 10 \
    --elf_path "$ELF_FORTH" \
    --out "$OUTPUT_FORTH" \
    --out_key "key.forth"

flash_elf "$ELF_ASM"

python3 "$BENCHMARK_PY" asm \
    --numreps 10 \
    --elf_path "$ELF_ASM" \
    --out "$OUTPUT_ASM" \
    --out_key "key.asm"

echo "*************  FORTH DATA *************\n\n"

cat "$OUTPUT_FORTH"


echo "\n\n*************  ASM DATA *************\n\n"

cat "$OUTPUT_ASM"
