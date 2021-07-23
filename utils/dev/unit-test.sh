shopt -s extglob
source $HOME/Source/bash-scripts/logging.sh
source $HOME/Source/bash-scripts/string-utils.sh
source $HOME/Source/bash-scripts/io-utils.sh

test_parse_opts() (				# Runs in subshell to avoid polluting global namespace

	unset __OPTS__ && declare -A __OPTS__=()
	unset __FLAGS__ && declare -A __FLAGS__=()
	unset __PARAM_NAMES__ && declare -a __PARAM_NAMES__=()

	__LOGLEVEL__=$(( __LOGLEVELS__[TEST] ))
	declare -a testcases=(
		"normal_short_opts"
	)

	declare -A opts=()
	declare -a flags=()
	declare -a params=()
	declare -a args=()

	get_args_canonical() {
		for opt in "${!opts[@]}"; do
			local val="${opts[$opt]}"
			case "$val" in
				=*)
					args+=("${opt}${val}")
					;;
				*)
					args+=("$opt" "$val")
					;;
			esac
		done
		args+=("${flags[@]}")
		if (( ${#params} )); then
			args+=("--")
			args+=("${params[@]}")
		fi
	}

	run_all() (					# Runs in subshell to avoid state contamination between testcases
		echo "entering 'run_all'"
		for testcase in "${testcases[@]}"; do
			echo "$testcase"
			run_testcase "$testcase"
		done
	)

	run_testcase() (
		print_header "(BEGIN TESTCASE :: $1)"
		echo "calling testcase function '$1'"
		eval "$1"
		echo "printing results from testcase '$1'"
		print_results "$1"
		print_footer "(END TESTCASE :: $1)"
	)

	setup_globals() {
		__OPTS__=(
			[-d|--database]="DEFAULT_DB"
			[-b|--backup]="DEFAULT_BACKUP"
		)

		__FLAGS__=(
			[-q|--quiet]="__LOGLEVEL__=-2"
			[-v|--verbose]="(( __LOGLEVEL__++ ))"
			[-h|--help]="usage"
			[-T|--test]="__LOGLEVEL__=$(( __LOGLEVELS__[TEST] ))"				# Placeholder
			[-D|--debug]="__LOGLEVEL__=$(( __LOGLEVELS__[DEBUG] ))"
			[-f|--force]="__CONFIRM__=0"
		)
	}

	normal_short_opts() {
		setup_globals
		opts+=(
			[-d]="DATABASE"
			[-b]="BACKUP"
		)
		flags+=("-q" "-v" "-h" "-T" "-D" "-f")		# The handlers won't actually be called
		params+=("param1" "param2" "param3")
		echo "calling 'parse_opts'"
		print_state __PARSE__
		get_args_canonical
		parse_opts "${args[@]}"
	}

	print_results() {
		echo "OPTS:"
		for opt in "${!opts_ref[@]}"; do
			printf "\t$opt = ${opts_ref[$opt]}\n"
		done
		echo 
		echo "PARAMS:"
		for param in "${!__PARAMS__[@]}"; do
			printf "\t$param\n"
		done
		echo 
		echo "FLAGS:"
		for flag in "${!__FLAGS__[@]}"; do
			printf "\t$flag\n"
		done
		echo
		echo "ERRORS:"
		for name in "${!__PARSE_ERRORS__[@]}"; do
			printf "on ${name} --> ${__PARSE_ERRORS__[$name]}\n"
		done
	}

	print_header() {
		echo
		echo "$(fill_string "$1" "=" 80)"
	}

	print_footer() {
		echo "$(fill_string -l "$1" "=" 80)"
	}

	trap "echo && print_footer" EXIT
	
	echo "hi there"
	run_all
)

breakpoint() {
	(( $(( __LOGLEVEL__ )) >= __LOGLEVELS__[DEBUG] )) && wait_on_keypress 'c'
}
