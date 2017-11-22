#!/usr/bin/env bash

usage() {
cat << EOF
Usage: difp [subcommand] [<plist_name>]

Subcommand:
    list   [plist_name]:     List plist file (Under the \$DIFP_PLIST_LOCATION)
    show   <plist_name>:     defaults read <plist_name>
    watch  <plist_name>:     Watch diff <plist_name> (Stop with Ctrl+C)
    before <plist_name>:     defaults read > <plist_name>.bef.txt
    after  <plist_name>:     defaults read > <plist_name>.aft.txt
    diff   <plist_name>:     diff \$DIFP_DIFF_OPTIONS <plist_name>.bef.txt <plist_name>.aft.txt

Settings:
    export DIFP_PLIST_LOCATION="~/Library/Preferences"
    export DIFP_DIFF_OPTIONS="--side-by-side --left-column --width=150"

EOF
exit 1
}

# Settings
DIFP_DIFF_OPTIONS=${DIFP_DIFF_OPTIONS:="--side-by-side --left-column --width=150"}
DIFP_PLIST_LOCATION=${DIFP_PLIST_LOCATION:="~/Library/Preferences"}

_list_all() {
    (cd "$DIFP_PLIST_LOCATION"; find . -type f -name "*.plist" | sed 's@./@@')
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
    DIFP_PLIST_NAME="${plists[0]}"
}

_show() {
    _get_plist "$1"
    defaults read "$DIFP_PLIST_LOCATION/$DIFP_PLIST_NAME"
}

_output_plist() {
    _get_plist "$1"
    # defaults read "$DIFP_PLIST_LOCATION/$DIFP_PLIST_NAME" | tee "$DIFP_PLIST_NAME.$2.txt"
    defaults read "$DIFP_PLIST_LOCATION/$DIFP_PLIST_NAME" > "$DIFP_PLIST_NAME.$2.txt"
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
    local beffile="$DIFP_PLIST_NAME.bef.txt"
    local aftfile="$DIFP_PLIST_NAME.aft.txt"
    _check_file "$beffile" || is_err=1
    _check_file "$aftfile" || is_err=1
    if [[ $is_err -eq 0 ]]; then
        diff $DIFP_DIFF_OPTIONS "$beffile" "$aftfile" | tee "$DIFP_PLIST_NAME.diff.txt"
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
        list)   DIFP_FUNC="_list";   shift; DIFP_ARGS="$@" ;;
        show)   DIFP_FUNC="_show";   shift; DIFP_ARGS="$@" ;;
        before) DIFP_FUNC="_before"; shift; DIFP_ARGS="$@" ;;
        after)  DIFP_FUNC="_after";  shift; DIFP_ARGS="$@" ;;
        diff)   DIFP_FUNC="_diff";   shift; DIFP_ARGS="$@" ;;
        watch)  DIFP_FUNC="_watch";  shift; DIFP_ARGS="$@" ;;
        *) usage ;;
    esac
}

_check() {
    DIFP_PLIST_LOCATION=$(echo $DIFP_PLIST_LOCATION | sed "s@~@$HOME@")
    if [[ ! -d "$DIFP_PLIST_LOCATION" ]]; then
        echo "Error: $DIFP_PLIST_LOCATION is not found"
        echo "==> Please redefine or unset: \$DIFP_PLIST_LOCATION"
        exit 1
    fi
}

main() {
    _check
    _options "$@"
    "$DIFP_FUNC" "$DIFP_ARGS" && return 0 || return 1
}

main "$@"
