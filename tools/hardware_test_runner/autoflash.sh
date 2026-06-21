#!/usr/bin/env bash
#
# autoflash.sh
# script for fully automated flashing of ch32v203
#
set -euo pipefail

# ---- Defaults ----
ELF=""
WCHISP=""
BOOTLOADER=""
POSITIONAL=()

usage() {
    cat <<EOF
Usage: ${0##*/} [OPTIONS] [POSITIONAL...]

Options:
  -b, --bootloader_script PATH  Path to bootloader python script
  -w, --wchisp PATH      Path to wchisp tool
  -e, --elf FILE         Input file
  -h, --help             Show this help message and exit

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
        -e|--elf)
            ELF="$2"
            shift 2
            ;;
	-w|--wchisp)
	    WCHISP="$2"
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

# ---- Validation (example) ----
if [[ -z "$ELF" ]]; then
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


# ---- Body ----
python3 $BOOTLOADER bootloader
sleep 2
$WCHISP flash $ELF
sleep 2
python3 $BOOTLOADER reset



