import RPi.GPIO as GPIO
import time
import argparse

BOOT0_PIN = 20
RESET_PIN = 21

def enter_bootloader():
    GPIO.output(BOOT0_PIN, GPIO.HIGH)   # assert boot select
    time.sleep(0.05)
    GPIO.output(RESET_PIN, GPIO.LOW)    # hold reset
    time.sleep(0.1)
    GPIO.output(RESET_PIN, GPIO.HIGH)   # release reset — chip latches BOOT0 here
    time.sleep(0.1)
    GPIO.output(BOOT0_PIN, GPIO.LOW)    # drop boot select so NEXT reset is normal
    # chip is now sitting in the WCH system bootloader, ready for ISP/DFU

def normal_reset():
    GPIO.output(BOOT0_PIN, GPIO.LOW)
    time.sleep(0.05)
    GPIO.output(RESET_PIN, GPIO.LOW)
    time.sleep(0.1)
    GPIO.output(RESET_PIN, GPIO.HIGH)

def cmd_reset(args):
    print(f"Resetting")
    normal_reset()

def cmd_bootloader(args):
    print(f"Entering bootloader")
    enter_bootloader()

def build_parser():
    parser = argparse.ArgumentParser(
        description="Control CH32V203 BOOT0/RESET via Raspberry Pi GPIO"
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    p_reset = subparsers.add_parser("reset", help="Normal reset, boots flashed firmware")
    p_reset.set_defaults(func=cmd_reset)

    p_boot = subparsers.add_parser("bootloader", help="Reset into the WCH system bootloader")
    p_boot.set_defaults(func=cmd_bootloader)

    return parser

def main():
    parser = build_parser()
    args = parser.parse_args()
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(BOOT0_PIN, GPIO.OUT)
    GPIO.setup(RESET_PIN, GPIO.OUT)
    GPIO.output(RESET_PIN, GPIO.HIGH)  # idle high (not asserting reset)
    GPIO.output(BOOT0_PIN, GPIO.LOW)   # idle low (normal boot)
    args.func(args)
    GPIO.output(RESET_PIN, GPIO.HIGH)  # idle high (not asserting reset)
    GPIO.output(BOOT0_PIN, GPIO.LOW)   # idle low (normal boot)

main()