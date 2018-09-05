#!/bin/sh

set -xeuo pipefail

QMK_ROOT=${QMK_ROOT:-"$HOME/src/hid/qmk_firmware"}

(cd $QMK_ROOT && make ergodox_ez:khutulun)
teensy_loader_cli -v -mmcu=atmega32u4 -w ${QMK_ROOT}/ergodox_ez_khutulun.hex
