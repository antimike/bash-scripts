#!/bin/bash
# https://askubuntu.com/questions/26248/how-to-get-keyboard-light-keys-working-on-macbook

declare -i VALUE=$(cat /sys/class/leds/smc::kbd_backlight/brightness)
declare -i INCREMENT=32
declare TOTAL=unset

case $1 in
    up)
        TOTAL=`expr $VALUE + $INCREMENT`
        ;;
    down)
        TOTAL=`expr $VALUE - $INCREMENT`
        ;;
    full)
        TOTAL=255
        ;;
    off)
        TOTAL=0
        ;;
esac

if [ $TOTAL == unset ]; then
    echo "Please specify up, down, full, or off"
    exit 1
fi

if [ $TOTAL -gt 255 ]; then TOTAL=255; fi
if [ $TOTAL -lt 0 ]; then TOTAL=0; fi 
echo $TOTAL > /sys/class/leds/smc::kbd_backlight/brightness
