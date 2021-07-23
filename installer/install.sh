#!/bin/bash
# A convenience script to call different package managers to install software, logging the relevant commands, timestamps, and stdout/stderr to specified files.
# Design goals:
# * Should be easy to `diff` installed packages from one machine to another
#     * Possibility: Sort logs by package name instead of timestamp?
#     * 2nd possibility: Write aux function to trim timestamps, sort, and diff
#     * 3rd possibility: Multiple logfiles
#         * "Verbose": Contains timestamps, actual commands run, and stdout/stderr
#         * "Bare": Just a list of installed packages, sorted by package manager and name
#             * Even this is problematic: Package names are frequently different for different distributions
#             * Can I somehow "fetch" a name common to .deb and .rpm packages from a shell script?  Doutful...
#             * Maybe based on executable/manpage name?
#         * "Host": Machine-specific information
#             * Source path
#             * Executable name and path
#             * Manpage/documentation path
#             * Installer/language version information
#             * Package/commit hash
#     * 4th: Use json!
#         * `jq` can be used to extract `diff`-able information...or even perform the diff itself?
#         * Perhaps a Python script would be a better idea?

INSTALLER_ROOT="${INSTALLER_ROOT:-$HOME/.install}"

main() {
	local install_script="$INSTALLER_ROOT"
	while [[ -d "$install_script" ]]; do
		# Descend one level further
		local install_script="${install_script}/$1" && shift
	done
	if [[ ! -f "$install_script" ]]; then
		goboom "Plugin script '${install_script}' not found!"
	fi
	# TODO: Check syntax
	if [[ ! -x "$install_script" ]]; then
		goboom "Plugin script '${install_script}' is not executable!"
	fi
	${install_script} "$@"
	return $?
}

usage() {
	cat <<-"USAGE" 1>&2
		This is a script to install things and log the relevant package names and commands to a series of specified files.
	USAGE
}

goboom() {
	echo "$1" && exit 1 || exit 2
}

trap 'goboom "Unknown error"' EXIT # TODO: Remember other signals to trap

log() {
	:
}

# DO NOT USE THIS, as some package managers SHOULD NOT be run as root
getroot() {
	# Uses recursion to make sure the script is run as root
	# Not sure if this is really necessary
	[ "$UID" -eq 0 ] || exec sudo "$0" "$@"
}
