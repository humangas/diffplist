#!/bin/bash

usage() {
cat << EOF
Usage: difp [subcommand] [<plist_name>]

Subcommand:
    list   [plist_name]:     List plist file (Under the \$WPLIST_PLIST_LOCATION)
    show   <plist_name>:     defaults read <plist_name>
    watch  <plist_name>:     Watch diff <plist_name> (Stop with Ctrl+C)
    before <plist_name>:     defaults read > <plist_name>.bef.txt
    after  <plist_name>:     defaults read > <plist_name>.aft.txt
    diff   <plist_name>:     diff \$WPLIST_DIFF_OPTIONS <plist_name>.bef.txt <plist_name>.aft.txt

Settings:
    export WPLIST_PLIST_LOCATION="~/Library/Preferences"
    export WPLIST_DIFF_OPTIONS="--side-by-side --left-column --width=150"

EOF
exit 1
}

# Settings
WPLIST_DIFF_OPTIONS=${WPLIST_DIFF_OPTIONS:="--side-by-side --left-column --width=150"}
WPLIST_PLIST_LOCATION=${WPLIST_PLIST_LOCATION:="~/Library/Preferences"}

_list_all() {
    (cd "$WPLIST_PLIST_LOCATION"; find . -type f -name "*.plist" | sed 's@./@@')
}

_list() {
    [[ -z "$1" ]] && _list_all || _list_all | grep -i "$1"
}

_get_plist() {
    [[ -z "$1" ]] && usage
    declare -a plists=($(_list_all | grep -i "$1"))
    if [[ ! ${#plists[@]} -eq 1 ]]; then
        if [[ ${#plists[@]} -eq 0 ]]; then
            echo "Error: \"$1\" is not found"
            exit 1
        fi
        _list_all | grep -i "$1"
        echo -e "----\nError: Please narrow down to one case"
        exit 1
    fi
    WPLIST_PLIST_NAME="${plists[0]}"
}

_show() {
    _get_plist "$1"
    defaults read "$WPLIST_PLIST_LOCATION/$WPLIST_PLIST_NAME"
}

_output_plist() {
    _get_plist "$1"
    # defaults read "$WPLIST_PLIST_LOCATION/$WPLIST_PLIST_NAME" | tee "$WPLIST_PLIST_NAME.$2.txt"
    defaults read "$WPLIST_PLIST_LOCATION/$WPLIST_PLIST_NAME" > "$WPLIST_PLIST_NAME.$2.txt"
}

_before() {
    _output_plist "$1" "bef"
}

_after() {
    _output_plist "$1" "aft"
}

_diff() {
    _check_file() {
        if [[ ! -f "$1" ]]; then
           echo "Error: \"$1\" is not found"
           return 1
        fi
    }

    is_err=0
    _get_plist "$1"
    local beffile="$WPLIST_PLIST_NAME.bef.txt"
    local aftfile="$WPLIST_PLIST_NAME.aft.txt"
    _check_file "$beffile" || is_err=1
    _check_file "$aftfile" || is_err=1
    if [[ $is_err -eq 0 ]]; then
        diff $WPLIST_DIFF_OPTIONS "$beffile" "$aftfile" | tee "$WPLIST_PLIST_NAME.diff.txt"
    else
        echo "==> Use the \"before\" and \"after\" commands beforehand"
        exit 1
    fi
}

_watch() {
    type watch > /dev/null 2>&1
    if [[ "$?" -ne 0 ]]; then
        echo "Error: \"watch\" command is required"
        echo "==> brew install watch"
        exit 1
    fi
    _before "$@"
    _after "$@"
    while true; do _after "$@"; sleep 1; kill -0 "$$" || exit; done 2>/dev/null &
    watch -n 1 -d -t bash "$0" diff "$@"
}

_options() {
    local sumcmd="$1"
    case "$sumcmd" in 
        list)   WPLIST_FUNC="_list";   shift; WPLIST_ARGS="$@" ;;
        show)   WPLIST_FUNC="_show";   shift; WPLIST_ARGS="$@" ;;
        before) WPLIST_FUNC="_before"; shift; WPLIST_ARGS="$@" ;;
        after)  WPLIST_FUNC="_after";  shift; WPLIST_ARGS="$@" ;;
        diff)   WPLIST_FUNC="_diff";   shift; WPLIST_ARGS="$@" ;;
        watch)  WPLIST_FUNC="_watch";  shift; WPLIST_ARGS="$@" ;;
        *) usage ;;
    esac
}

_check() {
    WPLIST_PLIST_LOCATION=$(echo $WPLIST_PLIST_LOCATION | sed "s@~@$HOME@")
    if [[ ! -d "$WPLIST_PLIST_LOCATION" ]]; then
        echo "Error: $WPLIST_PLIST_LOCATION is not found"
		echo "==> Please redefine or unset: \$WPLIST_PLIST_LOCATION"
        exit 1
    fi
}

main() {
	_check
    _options "$@"
    "$WPLIST_FUNC" "$WPLIST_ARGS" && return 0 || return 1
}

main "$@"
