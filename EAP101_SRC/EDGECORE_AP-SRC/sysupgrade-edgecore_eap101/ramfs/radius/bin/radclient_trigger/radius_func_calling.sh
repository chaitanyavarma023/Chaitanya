#!/bin/sh

# $1 function name
# $* param for the function

func="$1"
. /ramfs/bin/radius_func
if [ -n "$func" ] && [ "$(type -t $func)" = "function" ]; then
    shift
    $func $*
    exit $?
fi
exit 0

