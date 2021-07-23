#!/bin/bash
# Inspired by:
# https://unix.stackexchange.com/questions/551514/list-nearby-bluetooth-devices-on-raspberry-pi

# Have to run with `coproc`
# Otherwise call is blocking
coproc bluetoothctl
echo -e 'scan on' >&${COPROC[1]}

capture_bt_macs_and_signalstrengths() {
	sudo tshark -i bluetooth0 -Y "bthci_evt.le_meta_subevent == 0x2" -T fields -e bthci_evt.bd_addr -e bthci_evt.rssi
}

# from https://www.linuxquestions.org/questions/programming-9/control-bluetoothctl-with-scripting-4175615328/
bluetoothctl_coproc_example() {
	coproc bluetoothctl
	echo -e 'info 54:46:6B:01:6C:CC\nexit' >&${COPROC[1]}
	output="$(cat <&${COPROC[0]})"
	echo "$output"
}

tshark_alt_cmd() {
	bt_conditional="(bthci_evt.code == 0x2f) \
		|| (bthci_evt.le_meta_subevent == 0x2 && btcommon.eir_ad.entry.device_name != '')"
	sudo tshark -i bluetooth0 \
		-Y "${bt_conditional}" \
		-T fields \
		-e bthci_evt.bd_addr \
		-e bthci_evt.rssi \
		-e btcommon.eir_ad.entry.device_name
}
