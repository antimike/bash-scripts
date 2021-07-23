shopt -s extglob

fill_string() {
	local left=
	[[ "$1" = @(-l|--left) ]] && left=1 && shift
	local append=
	local original="$1"
	local fill_char="$2"
	local target_length=$(( "$3" ))
	local diff=$(( target_length - ${#original} ))
	if (( diff > 0 )); then
		append=$(printf "${fill_char}%.0s" $(eval echo {1..$diff}))
	elif (( diff == 0 )); then
		echo "$original" && return 0
	else
		notify ERROR "Can't fill string to less than its original length!"
		notify DEBUG "orig = '$original', target = '$target', diff = '$diff'"
		return 1
	fi
	[[ -n $left ]] && echo "${append}${original}" || echo "${original}${append}"
	return 0
}

print_array() {
	local prefix=
	case "$1" in
		--prefix=*)
			prefix="${1#--prefix=}" && shift
			;;
		-p|--prefix)
			shift && prefix="$1" && shift
			;;
		*)
			;;
	esac
	local -n arr_ref="$1"
	echo "${1}:"
	for elem in "${arr_ref[@]}"; do
		printf "${prefix}\t'%s'\n" "$elem"
	done
}

print_assoc_array() {
	local prefix=
	case "$1" in
		--prefix=*)
			prefix="${1#--prefix=}" && shift
			;;
		-p|--prefix)
			shift && prefix="$1" && shift
			;;
		*)
			;;
	esac
	local -n arr_ref="$1"
	echo "${prefix}${1}:"
	for key in "${!arr_ref[@]}"; do
		printf "${prefix}\t'%s' = '%s'\n" "$key" "${arr_ref[$key]}"
	done
}
