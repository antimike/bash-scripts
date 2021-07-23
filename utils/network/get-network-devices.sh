#!/bin/bash
# A script to find and display information on all devices connected to the current wifi network

OUTFILE=
VERBOSITY=
CONFIRM=
declare -A CONFIRM_LEVELS=(
  [SILENT]=-1
  [OVERWRITE]=0
  [ALL]=1
)
declare -A VERB_LEVELS=(
  [SILENT]=-1
  [INFO]=0
  [DEBUG]=1
)

die() {
  echo "$*" 1>&2 && exit 1 || exit 2
}

inform() {
  local vb="${VERB_LEVELS[$1]}"
  [[ -n "$vb" ]] && shift
  (( VERBOSITY >= vb )) && printf $@ && echo && return 0 || return 1
}

confirm() {
  local ans=
  local cl="${CONFIRM_LEVELS[$1]}"
  [[ -n "$cl" ]] && shift
  (( CONFIRM >= cl )) && printf $@ || die
  read
  read -p "$(sed 's/\([^\s]\)$/\1 /g' "$1")"
  # && echo && return 0 || return 1
}

set_outfile() {
  local status=
  while
    touch "$OUTFILE" 2>&1 >/dev/null; status="$?"
    (( STATUS ))
  do
    inform 
  done
}

confirm_overwrite() {
  local file="${1:-$OUTFILE}"
  local ans=
  echo "File '${file} already exists!  Do you really want to overwrite it?"
  echo "Press [y/Y] to confirm, [n/N] to choose a new filename:"
  while :; do
    read -n1 -s ans
    case "$ans" in
      yY)
        break
        ;;
      nN)
        file="$(get_filename)"
        break
        ;;
      *)
        continue
        ;;
    esac
    echo "$file"
  done
}

get_ipaddr() {
  # Get IP address from `ifconfig`
  # First, remove paragraph with irrelevant loopback info using `sed`
  # Then, use `awk` to extract the address from the relevant line
#   ifconfig \
#     | sed '/lo:/,/^$/d' \
#     | awk '
#       /inet.*netmask/ {
#         print $2
#       }
# '
  ip a \
    | sed '/^[[:digit:]]: lo/,/^[[:digit:]]:/d' \
    | awk '
      /inet.*brd/ {
        print $2
      }
'
}

while getopts "qfvo:" opt; do
  case "$opt" in
    q)
      VERBOSITY=${VERB_LEVELS[SILENT]}
      ;;
    f)
      FORCE=${CONFIRM_LEVELS[SILENT]}
      ;;
    v)
      (( VERBOSITY++ ))
      ;;
    o)
      OUTFILE="$OPTARG"
      # TODO: Finish implementing file-check / pick logic here
      # if [[ -e "$OUTFILE" ]]; then
      #   [[ ! -f "$OUTFILE" ]] && die "Can't write to non-file ${OUTFILE}"
      #   OUTFILE="$(confirm_overwrite "$OUTFILE")"
      # fi
      touch "$OUTFILE" || die "Can't write to file ${OUTFILE}"
      ;;
    *)
      die "Unknown option ${opt}"
      ;;
  esac
done

# echo "IP address: $(get_ipaddr)"
sudo nmap -sn "$(get_ipaddr)" \
  | tee "$OUTFILE" \
  | awk '
    function removeParens(str) {
      if (str~/(.*)/) {
        idx=index(str, "(")
        return substr(str, idx+1, length(str)-2)
      }
      return str
    }
    function getParenthesized(str) {
      start=index(str, "("); end=index(str, ")");
      return substr(str, start+1, end-start-1)
    }
    /Nmap scan report/ {
      printf "\nip=\"%s\"", getParenthesized($0)
    }
    /MAC Address/ {
      printf " MAC=%s type=\"%s\"", $3, getParenthesized($0)
    }
' && echo \
  | tee -a "$OUTFILE" \
