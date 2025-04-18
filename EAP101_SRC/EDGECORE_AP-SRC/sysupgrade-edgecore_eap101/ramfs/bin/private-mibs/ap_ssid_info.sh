#!/bin/sh
product_name=$(cat /proc/device-tree/model | cut -d " " -f 2)

PLACE=".1.3.6.1.4.1.259.10.3.38.6.3"

OP="$1"
REQ="$2"

if [ "$OP" = "-s" ]; then
    #get type
    WRITE_TYPE="$3"
    shift;
    shift;
    shift;
    #get value
    WRITE_VALUE="$@"
fi

mesh_btn=$(uci get wireless.wmesh.disabled)
[ "$mesh_btn" -eq 1 ] && vap=16 || vap=15
rf="$(echo $REQ | cut -d "." -f 18)"
num="$(echo $REQ | cut -d "." -f 19)"

if [ "$OP" = "-n" ]; then
    case "$REQ" in
#-----------------------------GENERAL SETTINGS-------------------------------
    $PLACE|$PLACE.1|$PLACE.1.1|$PLACE.1.1.1|$PLACE.1.1.1.1\
          |$PLACE.1.1.1.1.1|$PLACE.1.1.1.1.1.1)         RET=$PLACE.1.1.1.1.1.1.0 ;;
    $PLACE.1.1.1.1.2)                                   RET=$PLACE.1.1.1.1.2.1.0 ;;
    $PLACE.1.1.1.2|$PLACE.1.1.1.2.$rf)                  [ -z "$rf" ] && RET=$PLACE.1.1.1.2.1.1.0 || RET=$PLACE.1.1.1.2.$rf.1.0 ;;
    $PLACE.1.1.1.3|$PLACE.1.1.1.3.$rf)                  [ -z "$rf" ] && RET=$PLACE.1.1.1.3.1.1.0 || RET=$PLACE.1.1.1.3.$rf.1.0 ;;
    $PLACE.1.1.1.4|$PLACE.1.1.1.4.$rf)                  [ -z "$rf" ] && RET=$PLACE.1.1.1.4.1.1.0 || RET=$PLACE.1.1.1.4.$rf.1.0 ;;
    $PLACE.1.1.1.5|$PLACE.1.1.1.5.$rf)                  [ -z "$rf" ] && RET=$PLACE.1.1.1.5.1.1.0 || RET=$PLACE.1.1.1.5.$rf.1.0 ;;
    $PLACE.1.1.1.6|$PLACE.1.1.1.6.$rf)                  [ -z "$rf" ] && RET=$PLACE.1.1.1.6.1.1.0 || RET=$PLACE.1.1.1.6.$rf.1.0 ;;
    $PLACE.1.1.1.7|$PLACE.1.1.1.7.$rf)                  [ -z "$rf" ] && RET=$PLACE.1.1.1.7.1.1.0 || RET=$PLACE.1.1.1.7.$rf.1.0 ;;
    $PLACE.1.1.1.8|$PLACE.1.1.1.8.$rf)                  [ -z "$rf" ] && RET=$PLACE.1.1.1.8.1.1.0 || RET=$PLACE.1.1.1.8.$rf.1.0 ;;
    #-------------------------------------------------------------------------
    $PLACE.1.1.1.1.1.1.0|$PLACE.1.1.1.1.1.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.1.1.1.1.1.$((num+1)).0 || RET=$PLACE.1.1.1.1.2.1.0 ;;
    $PLACE.1.1.1.1.2.1.0|$PLACE.1.1.1.1.2.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.1.1.1.1.2.$((num+1)).0 || RET=$PLACE.1.1.1.2.1.1.0 ;;
    $PLACE.1.1.1.2.1.1.0|$PLACE.1.1.1.2.1.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.1.1.1.2.1.$((num+1)).0 || RET=$PLACE.1.1.1.2.2.1.0 ;;
    $PLACE.1.1.1.2.2.1.0|$PLACE.1.1.1.2.2.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.1.1.1.2.2.$((num+1)).0 || RET=$PLACE.1.1.1.3.1.1.0 ;;
    $PLACE.1.1.1.3.1.1.0|$PLACE.1.1.1.3.1.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.1.1.1.3.1.$((num+1)).0 || RET=$PLACE.1.1.1.3.2.1.0 ;;
    $PLACE.1.1.1.3.2.1.0|$PLACE.1.1.1.3.2.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.1.1.1.3.2.$((num+1)).0 || RET=$PLACE.1.1.1.4.1.1.0 ;;
    $PLACE.1.1.1.4.1.1.0|$PLACE.1.1.1.4.1.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.1.1.1.4.1.$((num+1)).0 || RET=$PLACE.1.1.1.4.2.1.0 ;;
    $PLACE.1.1.1.4.2.1.0|$PLACE.1.1.1.4.2.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.1.1.1.4.2.$((num+1)).0 || RET=$PLACE.1.1.1.5.1.1.0 ;;
    $PLACE.1.1.1.5.1.1.0|$PLACE.1.1.1.5.1.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.1.1.1.5.1.$((num+1)).0 || RET=$PLACE.1.1.1.5.2.1.0 ;;
    $PLACE.1.1.1.5.2.1.0|$PLACE.1.1.1.5.2.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.1.1.1.5.2.$((num+1)).0 || RET=$PLACE.1.1.1.6.1.1.0 ;;
    $PLACE.1.1.1.6.1.1.0|$PLACE.1.1.1.6.1.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.1.1.1.6.1.$((num+1)).0 || RET=$PLACE.1.1.1.6.2.1.0 ;;
    $PLACE.1.1.1.6.2.1.0|$PLACE.1.1.1.6.2.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.1.1.1.6.2.$((num+1)).0 || RET=$PLACE.1.1.1.7.1.1.0 ;;
    $PLACE.1.1.1.7.1.1.0|$PLACE.1.1.1.7.1.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.1.1.1.7.1.$((num+1)).0 || RET=$PLACE.1.1.1.7.2.1.0 ;;
    $PLACE.1.1.1.7.2.1.0|$PLACE.1.1.1.7.2.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.1.1.1.7.2.$((num+1)).0 || RET=$PLACE.1.1.1.8.1.1.0 ;;
    $PLACE.1.1.1.8.1.1.0|$PLACE.1.1.1.8.1.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.1.1.1.8.1.$((num+1)).0 || RET=$PLACE.1.1.1.8.2.1.0 ;;
    $PLACE.1.1.1.8.2.1.0|$PLACE.1.1.1.8.2.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.1.1.1.8.2.$((num+1)).0 || RET=$PLACE.2.1.1.1.1.1.0 ;;
#-----------------------------SECURITY SETTINGS-------------------------------
    $PLACE.2|$PLACE.2.1|$PLACE.2.1.1\
            |$PLACE.2.1.1.1|$PLACE.2.1.1.1.$rf)         [ -z "$rf" ] && RET=$PLACE.2.1.1.1.1.1.0 || RET=$PLACE.2.1.1.1.$rf.1.0 ;;
    $PLACE.2.1.1.2|$PLACE.2.1.1.2.$rf)                  [ -z "$rf" ] && RET=$PLACE.2.1.1.2.1.1.0 || RET=$PLACE.2.1.1.2.$rf.1.0 ;;
    $PLACE.2.1.1.3|$PLACE.2.1.1.3.$rf)                  [ -z "$rf" ] && RET=$PLACE.2.1.1.3.1.1.0 || RET=$PLACE.2.1.1.3.$rf.1.0 ;;
    $PLACE.2.1.1.4|$PLACE.2.1.1.4.$rf)                  [ -z "$rf" ] && RET=$PLACE.2.1.1.4.1.1.0 || RET=$PLACE.2.1.1.4.$rf.1.0 ;;
    $PLACE.2.1.1.5|$PLACE.2.1.1.5.$rf)                  [ -z "$rf" ] && RET=$PLACE.2.1.1.5.1.1.0 || RET=$PLACE.2.1.1.5.$rf.1.0 ;;
    $PLACE.2.1.1.6|$PLACE.2.1.1.6.$rf)                  [ -z "$rf" ] && RET=$PLACE.2.1.1.6.1.1.0 || RET=$PLACE.2.1.1.6.$rf.1.0 ;;
    $PLACE.2.1.1.7|$PLACE.2.1.1.7.$rf)                  [ -z "$rf" ] && RET=$PLACE.2.1.1.7.1.1.0 || RET=$PLACE.2.1.1.7.$rf.1.0 ;;
    $PLACE.2.1.1.8|$PLACE.2.1.1.8.$rf)                  [ -z "$rf" ] && RET=$PLACE.2.1.1.8.1.1.0 || RET=$PLACE.2.1.1.8.$rf.1.0 ;;
    $PLACE.2.1.1.9|$PLACE.2.1.1.9.$rf)                  [ -z "$rf" ] && RET=$PLACE.2.1.1.9.1.1.0 || RET=$PLACE.2.1.1.9.$rf.1.0 ;;
    $PLACE.2.1.1.10|$PLACE.2.1.1.10.$rf)                [ -z "$rf" ] && RET=$PLACE.2.1.1.10.1.1.0 || RET=$PLACE.2.1.1.10.$rf.1.0 ;;
    $PLACE.2.1.1.11|$PLACE.2.1.1.11.$rf)                [ -z "$rf" ] && RET=$PLACE.2.1.1.11.1.1.0 || RET=$PLACE.2.1.1.11.$rf.1.0 ;;
    $PLACE.2.1.1.12|$PLACE.2.1.1.12.$rf)                [ -z "$rf" ] && RET=$PLACE.2.1.1.12.1.1.0 || RET=$PLACE.2.1.1.12.$rf.1.0 ;;
    $PLACE.2.1.1.13|$PLACE.2.1.1.13.$rf)                [ -z "$rf" ] && RET=$PLACE.2.1.1.13.1.1.0 || RET=$PLACE.2.1.1.13.$rf.1.0 ;;
    $PLACE.2.1.1.14|$PLACE.2.1.1.14.$rf)                [ -z "$rf" ] && RET=$PLACE.2.1.1.14.1.1.0 || RET=$PLACE.2.1.1.14.$rf.1.0 ;;
    $PLACE.2.1.1.15|$PLACE.2.1.1.15.$rf)                [ -z "$rf" ] && RET=$PLACE.2.1.1.15.1.1.0 || RET=$PLACE.2.1.1.15.$rf.1.0 ;;
    $PLACE.2.1.1.16|$PLACE.2.1.1.16.$rf)                [ -z "$rf" ] && RET=$PLACE.2.1.1.16.1.1.0 || RET=$PLACE.2.1.1.16.$rf.1.0 ;;
    $PLACE.2.1.1.17|$PLACE.2.1.1.17.$rf)                [ -z "$rf" ] && RET=$PLACE.2.1.1.17.1.1.0 || RET=$PLACE.2.1.1.17.$rf.1.0 ;;
    $PLACE.2.1.1.18|$PLACE.2.1.1.18.$rf)                [ -z "$rf" ] && RET=$PLACE.2.1.1.18.1.1.0 || RET=$PLACE.2.1.1.18.$rf.1.0 ;;
    $PLACE.2.1.1.19|$PLACE.2.1.1.19.$rf)                [ -z "$rf" ] && RET=$PLACE.2.1.1.19.1.1.0 || RET=$PLACE.2.1.1.19.$rf.1.0 ;;
    $PLACE.2.1.1.20|$PLACE.2.1.1.20.$rf)                [ -z "$rf" ] && RET=$PLACE.2.1.1.20.1.1.0 || RET=$PLACE.2.1.1.20.$rf.1.0 ;;
    $PLACE.2.1.1.21|$PLACE.2.1.1.21.$rf)                [ -z "$rf" ] && RET=$PLACE.2.1.1.21.1.1.0 || RET=$PLACE.2.1.1.21.$rf.1.0 ;;
    $PLACE.2.1.1.22|$PLACE.2.1.1.22.$rf)                [ -z "$rf" ] && RET=$PLACE.2.1.1.22.1.1.0 || RET=$PLACE.2.1.1.22.$rf.1.0 ;;
    $PLACE.2.1.1.23|$PLACE.2.1.1.23.$rf)                [ -z "$rf" ] && RET=$PLACE.2.1.1.23.1.1.0 || RET=$PLACE.2.1.1.23.$rf.1.0 ;;
    $PLACE.2.1.1.24|$PLACE.2.1.1.24.$rf)                [ -z "$rf" ] && RET=$PLACE.2.1.1.24.1.1.0 || RET=$PLACE.2.1.1.24.$rf.1.0 ;;
    $PLACE.2.1.1.25|$PLACE.2.1.1.25.$rf)                [ -z "$rf" ] && RET=$PLACE.2.1.1.25.1.1.0 || RET=$PLACE.2.1.1.25.$rf.1.0 ;;
    $PLACE.2.1.1.26|$PLACE.2.1.1.26.$rf)                [ -z "$rf" ] && RET=$PLACE.2.1.1.26.1.1.0 || RET=$PLACE.2.1.1.26.$rf.1.0 ;;
    $PLACE.2.1.1.27|$PLACE.2.1.1.27.$rf)                [ -z "$rf" ] && RET=$PLACE.2.1.1.27.1.1.0 || RET=$PLACE.2.1.1.27.$rf.1.0 ;;
    $PLACE.2.1.1.28|$PLACE.2.1.1.28.$rf)                [ -z "$rf" ] && RET=$PLACE.2.1.1.28.1.1.0 || RET=$PLACE.2.1.1.28.$rf.1.0 ;;
    $PLACE.2.1.1.29|$PLACE.2.1.1.29.$rf)                [ -z "$rf" ] && RET=$PLACE.2.1.1.29.1.1.0 || RET=$PLACE.2.1.1.29.$rf.1.0 ;;
    $PLACE.2.1.1.30|$PLACE.2.1.1.30.$rf)                [ -z "$rf" ] && RET=$PLACE.2.1.1.30.1.1.0 || RET=$PLACE.2.1.1.30.$rf.1.0 ;;
    $PLACE.2.1.1.31|$PLACE.2.1.1.31.$rf)                [ -z "$rf" ] && RET=$PLACE.2.1.1.31.1.1.0 || RET=$PLACE.2.1.1.31.$rf.1.0 ;;
    #-------------------------------------------------------------------------
    $PLACE.2.1.1.1.1.1.0|$PLACE.2.1.1.1.1.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.1.1.$((num+1)).0 || RET=$PLACE.2.1.1.1.2.1.0 ;;
    $PLACE.2.1.1.1.2.1.0|$PLACE.2.1.1.1.2.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.1.2.$((num+1)).0 || RET=$PLACE.2.1.1.2.1.1.0 ;;
    $PLACE.2.1.1.2.1.1.0|$PLACE.2.1.1.2.1.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.2.1.$((num+1)).0 || RET=$PLACE.2.1.1.2.2.1.0 ;;
    $PLACE.2.1.1.2.2.1.0|$PLACE.2.1.1.2.2.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.2.2.$((num+1)).0 || RET=$PLACE.2.1.1.3.1.1.0 ;;
    $PLACE.2.1.1.3.1.1.0|$PLACE.2.1.1.3.1.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.3.1.$((num+1)).0 || RET=$PLACE.2.1.1.3.2.1.0 ;;
    $PLACE.2.1.1.3.2.1.0|$PLACE.2.1.1.3.2.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.3.2.$((num+1)).0 || RET=$PLACE.2.1.1.4.1.1.0 ;;
    $PLACE.2.1.1.4.1.1.0|$PLACE.2.1.1.4.1.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.4.1.$((num+1)).0 || RET=$PLACE.2.1.1.4.2.1.0 ;;
    $PLACE.2.1.1.4.2.1.0|$PLACE.2.1.1.4.2.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.4.2.$((num+1)).0 || RET=$PLACE.2.1.1.5.1.1.0 ;;
    $PLACE.2.1.1.5.1.1.0|$PLACE.2.1.1.5.1.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.5.1.$((num+1)).0 || RET=$PLACE.2.1.1.5.2.1.0 ;;
    $PLACE.2.1.1.5.2.1.0|$PLACE.2.1.1.5.2.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.5.2.$((num+1)).0 || RET=$PLACE.2.1.1.6.1.1.0 ;;
    $PLACE.2.1.1.6.1.1.0|$PLACE.2.1.1.6.1.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.6.1.$((num+1)).0 || RET=$PLACE.2.1.1.6.2.1.0 ;;
    $PLACE.2.1.1.6.2.1.0|$PLACE.2.1.1.6.2.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.6.2.$((num+1)).0 || RET=$PLACE.2.1.1.7.1.1.0 ;;
    $PLACE.2.1.1.7.1.1.0|$PLACE.2.1.1.7.1.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.7.1.$((num+1)).0 || RET=$PLACE.2.1.1.7.2.1.0 ;;
    $PLACE.2.1.1.7.2.1.0|$PLACE.2.1.1.7.2.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.7.2.$((num+1)).0 || RET=$PLACE.2.1.1.8.1.1.0 ;;
    $PLACE.2.1.1.8.1.1.0|$PLACE.2.1.1.8.1.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.8.1.$((num+1)).0 || RET=$PLACE.2.1.1.8.2.1.0 ;;
    $PLACE.2.1.1.8.2.1.0|$PLACE.2.1.1.8.2.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.8.2.$((num+1)).0 || RET=$PLACE.2.1.1.9.1.1.0 ;;
    $PLACE.2.1.1.9.1.1.0|$PLACE.2.1.1.9.1.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.9.1.$((num+1)).0 || RET=$PLACE.2.1.1.9.2.1.0 ;;
    $PLACE.2.1.1.9.2.1.0|$PLACE.2.1.1.9.2.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.9.2.$((num+1)).0 || RET=$PLACE.2.1.1.10.1.1.0 ;;
    $PLACE.2.1.1.10.1.1.0|$PLACE.2.1.1.10.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.10.1.$((num+1)).0 || RET=$PLACE.2.1.1.10.2.1.0 ;;
    $PLACE.2.1.1.10.2.1.0|$PLACE.2.1.1.10.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.10.2.$((num+1)).0 || RET=$PLACE.2.1.1.11.1.1.0 ;;
    $PLACE.2.1.1.11.1.1.0|$PLACE.2.1.1.11.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.11.1.$((num+1)).0 || RET=$PLACE.2.1.1.11.2.1.0 ;;
    $PLACE.2.1.1.11.2.1.0|$PLACE.2.1.1.11.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.11.2.$((num+1)).0 || RET=$PLACE.2.1.1.12.1.1.0 ;;
    $PLACE.2.1.1.12.1.1.0|$PLACE.2.1.1.12.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.12.1.$((num+1)).0 || RET=$PLACE.2.1.1.12.2.1.0 ;;
    $PLACE.2.1.1.12.2.1.0|$PLACE.2.1.1.12.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.12.2.$((num+1)).0 || RET=$PLACE.2.1.1.13.1.1.0 ;;
    $PLACE.2.1.1.13.1.1.0|$PLACE.2.1.1.13.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.13.1.$((num+1)).0 || RET=$PLACE.2.1.1.13.2.1.0 ;;
    $PLACE.2.1.1.13.2.1.0|$PLACE.2.1.1.13.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.13.2.$((num+1)).0 || RET=$PLACE.2.1.1.14.1.1.0 ;;
    $PLACE.2.1.1.14.1.1.0|$PLACE.2.1.1.14.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.14.1.$((num+1)).0 || RET=$PLACE.2.1.1.14.2.1.0 ;;
    $PLACE.2.1.1.14.2.1.0|$PLACE.2.1.1.14.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.14.2.$((num+1)).0 || RET=$PLACE.2.1.1.15.1.1.0 ;;
    $PLACE.2.1.1.15.1.1.0|$PLACE.2.1.1.15.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.15.1.$((num+1)).0 || RET=$PLACE.2.1.1.15.2.1.0 ;;
    $PLACE.2.1.1.15.2.1.0|$PLACE.2.1.1.15.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.15.2.$((num+1)).0 || RET=$PLACE.2.1.1.16.1.1.0 ;;
    $PLACE.2.1.1.16.1.1.0|$PLACE.2.1.1.16.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.16.1.$((num+1)).0 || RET=$PLACE.2.1.1.16.2.1.0 ;;
    $PLACE.2.1.1.16.2.1.0|$PLACE.2.1.1.16.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.16.2.$((num+1)).0 || RET=$PLACE.2.1.1.17.1.1.0 ;;
    $PLACE.2.1.1.17.1.1.0|$PLACE.2.1.1.17.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.17.1.$((num+1)).0 || RET=$PLACE.2.1.1.17.2.1.0 ;;
    $PLACE.2.1.1.17.2.1.0|$PLACE.2.1.1.17.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.17.2.$((num+1)).0 || RET=$PLACE.2.1.1.18.1.1.0 ;;
    $PLACE.2.1.1.18.1.1.0|$PLACE.2.1.1.18.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.18.1.$((num+1)).0 || RET=$PLACE.2.1.1.18.2.1.0 ;;
    $PLACE.2.1.1.18.2.1.0|$PLACE.2.1.1.18.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.18.2.$((num+1)).0 || RET=$PLACE.2.1.1.19.1.1.0 ;;
    $PLACE.2.1.1.19.1.1.0|$PLACE.2.1.1.19.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.19.1.$((num+1)).0 || RET=$PLACE.2.1.1.19.2.1.0 ;;
    $PLACE.2.1.1.19.2.1.0|$PLACE.2.1.1.19.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.19.2.$((num+1)).0 || RET=$PLACE.2.1.1.20.1.1.0 ;;
    $PLACE.2.1.1.20.1.1.0|$PLACE.2.1.1.20.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.20.1.$((num+1)).0 || RET=$PLACE.2.1.1.20.2.1.0 ;;
    $PLACE.2.1.1.20.2.1.0|$PLACE.2.1.1.20.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.20.2.$((num+1)).0 || RET=$PLACE.2.1.1.21.1.1.0 ;;
    $PLACE.2.1.1.21.1.1.0|$PLACE.2.1.1.21.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.21.1.$((num+1)).0 || RET=$PLACE.2.1.1.21.2.1.0 ;;
    $PLACE.2.1.1.21.2.1.0|$PLACE.2.1.1.21.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.21.2.$((num+1)).0 || RET=$PLACE.2.1.1.22.1.1.0 ;;
    $PLACE.2.1.1.22.1.1.0|$PLACE.2.1.1.22.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.22.1.$((num+1)).0 || RET=$PLACE.2.1.1.22.2.1.0 ;;
    $PLACE.2.1.1.22.2.1.0|$PLACE.2.1.1.22.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.22.2.$((num+1)).0 || RET=$PLACE.2.1.1.23.1.1.0 ;;
    $PLACE.2.1.1.23.1.1.0|$PLACE.2.1.1.23.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.23.1.$((num+1)).0 || RET=$PLACE.2.1.1.23.2.1.0 ;;
    $PLACE.2.1.1.23.2.1.0|$PLACE.2.1.1.23.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.23.2.$((num+1)).0 || RET=$PLACE.2.1.1.24.1.1.0 ;;
    $PLACE.2.1.1.24.1.1.0|$PLACE.2.1.1.24.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.24.1.$((num+1)).0 || RET=$PLACE.2.1.1.24.2.1.0 ;;
    $PLACE.2.1.1.24.2.1.0|$PLACE.2.1.1.24.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.24.2.$((num+1)).0 || RET=$PLACE.2.1.1.25.1.1.0 ;;
    $PLACE.2.1.1.25.1.1.0|$PLACE.2.1.1.25.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.25.1.$((num+1)).0 || RET=$PLACE.2.1.1.25.2.1.0 ;;
    $PLACE.2.1.1.25.2.1.0|$PLACE.2.1.1.25.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.25.2.$((num+1)).0 || RET=$PLACE.2.1.1.26.1.1.0 ;;
    $PLACE.2.1.1.26.1.1.0|$PLACE.2.1.1.26.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.26.1.$((num+1)).0 || RET=$PLACE.2.1.1.26.2.1.0 ;;
    $PLACE.2.1.1.26.2.1.0|$PLACE.2.1.1.26.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.26.2.$((num+1)).0 || RET=$PLACE.2.1.1.27.1.1.0 ;;
    $PLACE.2.1.1.27.1.1.0|$PLACE.2.1.1.27.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.27.1.$((num+1)).0 || RET=$PLACE.2.1.1.27.2.1.0 ;;
    $PLACE.2.1.1.27.2.1.0|$PLACE.2.1.1.27.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.27.2.$((num+1)).0 || RET=$PLACE.2.1.1.28.1.1.0 ;;
    $PLACE.2.1.1.28.1.1.0|$PLACE.2.1.1.28.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.28.1.$((num+1)).0 || RET=$PLACE.2.1.1.28.2.1.0 ;;
    $PLACE.2.1.1.28.2.1.0|$PLACE.2.1.1.28.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.28.2.$((num+1)).0 || RET=$PLACE.2.1.1.29.1.1.0 ;;
    $PLACE.2.1.1.29.1.1.0|$PLACE.2.1.1.29.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.29.1.$((num+1)).0 || RET=$PLACE.2.1.1.29.2.1.0 ;;
    $PLACE.2.1.1.29.2.1.0|$PLACE.2.1.1.29.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.29.2.$((num+1)).0 || RET=$PLACE.2.1.1.30.1.1.0 ;;
    $PLACE.2.1.1.30.1.1.0|$PLACE.2.1.1.30.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.30.1.$((num+1)).0 || RET=$PLACE.2.1.1.30.2.1.0 ;;
    $PLACE.2.1.1.30.2.1.0|$PLACE.2.1.1.30.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.30.2.$((num+1)).0 || RET=$PLACE.2.1.1.31.1.1.0 ;;
    $PLACE.2.1.1.31.1.1.0|$PLACE.2.1.1.31.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.31.1.$((num+1)).0 || RET=$PLACE.2.1.1.31.2.1.0 ;;
    $PLACE.2.1.1.31.2.1.0|$PLACE.2.1.1.31.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.2.1.1.31.2.$((num+1)).0 || RET=$PLACE.2.1.1.32.1.1.0 ;;
#-----------------------------NETWORK SETTINGS--------------------------------
    $PLACE.3|$PLACE.3.1|$PLACE.3.1.1\
            |$PLACE.3.1.1.1|$PLACE.3.1.1.1.$rf)         [ -z "$rf" ] && RET=$PLACE.3.1.1.1.1.1.0 || RET=$PLACE.3.1.1.1.$rf.1.0 ;;
    $PLACE.3.1.1.2|$PLACE.3.1.1.2.$rf)                  [ -z "$rf" ] && RET=$PLACE.3.1.1.2.1.1.0 || RET=$PLACE.3.1.1.2.$rf.1.0 ;;
    $PLACE.3.1.1.3|$PLACE.3.1.1.3.$rf)                  [ -z "$rf" ] && RET=$PLACE.3.1.1.3.1.1.0 || RET=$PLACE.3.1.1.3.$rf.1.0 ;;
    $PLACE.3.1.1.4|$PLACE.3.1.1.4.$rf)                  [ -z "$rf" ] && RET=$PLACE.3.1.1.4.1.1.0 || RET=$PLACE.3.1.1.4.$rf.1.0 ;;
    $PLACE.3.1.1.5|$PLACE.3.1.1.5.$rf)                  [ -z "$rf" ] && RET=$PLACE.3.1.1.5.1.1.0 || RET=$PLACE.3.1.1.5.$rf.1.0 ;;
    $PLACE.3.1.1.6|$PLACE.3.1.1.6.$rf)                  [ -z "$rf" ] && RET=$PLACE.3.1.1.6.1.1.0 || RET=$PLACE.3.1.1.6.$rf.1.0 ;;
    $PLACE.3.1.1.7|$PLACE.3.1.1.7.$rf)                  [ -z "$rf" ] && RET=$PLACE.3.1.1.7.1.1.0 || RET=$PLACE.3.1.1.7.$rf.1.0 ;;
    $PLACE.3.1.1.8|$PLACE.3.1.1.8.$rf)                  [ -z "$rf" ] && RET=$PLACE.3.1.1.8.1.1.0 || RET=$PLACE.3.1.1.8.$rf.1.0 ;;
    $PLACE.3.1.1.9|$PLACE.3.1.1.9.$rf)                  [ -z "$rf" ] && RET=$PLACE.3.1.1.9.1.1.0 || RET=$PLACE.3.1.1.9.$rf.1.0 ;;
    $PLACE.3.1.1.10|$PLACE.3.1.1.10.$rf)                [ -z "$rf" ] && RET=$PLACE.3.1.1.10.1.1.0 || RET=$PLACE.3.1.1.10.$rf.1.0 ;;
    $PLACE.3.1.1.11|$PLACE.3.1.1.11.$rf)                [ -z "$rf" ] && RET=$PLACE.3.1.1.11.1.1.0 || RET=$PLACE.3.1.1.11.$rf.1.0 ;;
    $PLACE.3.1.1.12|$PLACE.3.1.1.12.$rf)                [ -z "$rf" ] && RET=$PLACE.3.1.1.12.1.1.0 || RET=$PLACE.3.1.1.12.$rf.1.0 ;;
    $PLACE.3.1.1.13|$PLACE.3.1.1.13.$rf)                [ -z "$rf" ] && RET=$PLACE.3.1.1.13.1.1.0 || RET=$PLACE.3.1.1.13.$rf.1.0 ;;
    $PLACE.3.1.1.14|$PLACE.3.1.1.14.$rf)                [ -z "$rf" ] && RET=$PLACE.3.1.1.14.1.1.0 || RET=$PLACE.3.1.1.14.$rf.1.0 ;;
    $PLACE.3.1.1.15|$PLACE.3.1.1.15.$rf)                [ -z "$rf" ] && RET=$PLACE.3.1.1.15.1.1.0 || RET=$PLACE.3.1.1.15.$rf.1.0 ;;
    $PLACE.3.1.1.16|$PLACE.3.1.1.16.$rf)                [ -z "$rf" ] && RET=$PLACE.3.1.1.16.1.1.0 || RET=$PLACE.3.1.1.16.$rf.1.0 ;;
    $PLACE.3.1.1.17|$PLACE.3.1.1.17.$rf)                [ -z "$rf" ] && RET=$PLACE.3.1.1.17.1.1.0 || RET=$PLACE.3.1.1.17.$rf.1.0 ;;
    $PLACE.3.1.1.18|$PLACE.3.1.1.18.$rf)                [ -z "$rf" ] && RET=$PLACE.3.1.1.18.1.1.0 || RET=$PLACE.3.1.1.18.$rf.1.0 ;;
    $PLACE.3.1.1.19|$PLACE.3.1.1.19.$rf)                [ -z "$rf" ] && RET=$PLACE.3.1.1.19.1.1.0 || RET=$PLACE.3.1.1.19.$rf.1.0 ;;
    $PLACE.3.1.1.20|$PLACE.3.1.1.20.$rf)                [ -z "$rf" ] && RET=$PLACE.3.1.1.20.1.1.0 || RET=$PLACE.3.1.1.20.$rf.1.0 ;;
    $PLACE.3.1.1.21|$PLACE.3.1.1.21.$rf)                [ -z "$rf" ] && RET=$PLACE.3.1.1.21.1.1.0 || RET=$PLACE.3.1.1.21.$rf.1.0 ;;
    $PLACE.3.1.1.22|$PLACE.3.1.1.22.$rf)                [ -z "$rf" ] && RET=$PLACE.3.1.1.22.1.1.0 || RET=$PLACE.3.1.1.22.$rf.1.0 ;;
    $PLACE.3.1.1.23|$PLACE.3.1.1.23.$rf)                [ -z "$rf" ] && RET=$PLACE.3.1.1.23.1.1.0 || RET=$PLACE.3.1.1.23.$rf.1.0 ;;
    $PLACE.3.1.1.24|$PLACE.3.1.1.24.$rf)                [ -z "$rf" ] && RET=$PLACE.3.1.1.24.1.1.0 || RET=$PLACE.3.1.1.24.$rf.1.0 ;;
    $PLACE.3.1.1.25|$PLACE.3.1.1.25.$rf)                [ -z "$rf" ] && RET=$PLACE.3.1.1.25.1.1.0 || RET=$PLACE.3.1.1.25.$rf.1.0 ;;
    #------------------------------------------------------------------------
    $PLACE.3.1.1.1.1.1.0|$PLACE.3.1.1.1.1.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.1.1.$((num+1)).0 || RET=$PLACE.3.1.1.1.2.1.0 ;;
    $PLACE.3.1.1.1.2.1.0|$PLACE.3.1.1.1.2.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.1.2.$((num+1)).0 || RET=$PLACE.3.1.1.2.1.1.0 ;;
    $PLACE.3.1.1.2.1.1.0|$PLACE.3.1.1.2.1.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.2.1.$((num+1)).0 || RET=$PLACE.3.1.1.2.2.1.0 ;;
    $PLACE.3.1.1.2.2.1.0|$PLACE.3.1.1.2.2.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.2.2.$((num+1)).0 || RET=$PLACE.3.1.1.3.1.1.0 ;;
    $PLACE.3.1.1.3.1.1.0|$PLACE.3.1.1.3.1.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.3.1.$((num+1)).0 || RET=$PLACE.3.1.1.3.2.1.0 ;;
    $PLACE.3.1.1.3.2.1.0|$PLACE.3.1.1.3.2.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.3.2.$((num+1)).0 || RET=$PLACE.3.1.1.4.1.1.0 ;;
    $PLACE.3.1.1.4.1.1.0|$PLACE.3.1.1.4.1.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.4.1.$((num+1)).0 || RET=$PLACE.3.1.1.4.2.1.0 ;;
    $PLACE.3.1.1.4.2.1.0|$PLACE.3.1.1.4.2.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.4.2.$((num+1)).0 || RET=$PLACE.3.1.1.5.1.1.0 ;;
    $PLACE.3.1.1.5.1.1.0|$PLACE.3.1.1.5.1.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.5.1.$((num+1)).0 || RET=$PLACE.3.1.1.5.2.1.0 ;;
    $PLACE.3.1.1.5.2.1.0|$PLACE.3.1.1.5.2.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.5.2.$((num+1)).0 || RET=$PLACE.3.1.1.6.1.1.0 ;;
    $PLACE.3.1.1.6.1.1.0|$PLACE.3.1.1.6.1.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.6.1.$((num+1)).0 || RET=$PLACE.3.1.1.6.2.1.0 ;;
    $PLACE.3.1.1.6.2.1.0|$PLACE.3.1.1.6.2.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.6.2.$((num+1)).0 || RET=$PLACE.3.1.1.7.1.1.0 ;;
    $PLACE.3.1.1.7.1.1.0|$PLACE.3.1.1.7.1.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.7.1.$((num+1)).0 || RET=$PLACE.3.1.1.7.2.1.0 ;;
    $PLACE.3.1.1.7.2.1.0|$PLACE.3.1.1.7.2.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.7.2.$((num+1)).0 || RET=$PLACE.3.1.1.8.1.1.0 ;;
    $PLACE.3.1.1.8.1.1.0|$PLACE.3.1.1.8.1.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.8.1.$((num+1)).0 || RET=$PLACE.3.1.1.8.2.1.0 ;;
    $PLACE.3.1.1.8.2.1.0|$PLACE.3.1.1.8.2.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.8.2.$((num+1)).0 || RET=$PLACE.3.1.1.9.1.1.0 ;;
    $PLACE.3.1.1.9.1.1.0|$PLACE.3.1.1.9.1.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.9.1.$((num+1)).0 || RET=$PLACE.3.1.1.9.2.1.0 ;;
    $PLACE.3.1.1.9.2.1.0|$PLACE.3.1.1.9.2.$num*)        [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.9.2.$((num+1)).0 || RET=$PLACE.3.1.1.10.1.1.0 ;;
    $PLACE.3.1.1.10.1.1.0|$PLACE.3.1.1.10.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.10.1.$((num+1)).0 || RET=$PLACE.3.1.1.10.2.1.0 ;;
    $PLACE.3.1.1.10.2.1.0|$PLACE.3.1.1.10.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.10.2.$((num+1)).0 || RET=$PLACE.3.1.1.11.1.1.0 ;;
    $PLACE.3.1.1.11.1.1.0|$PLACE.3.1.1.11.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.11.1.$((num+1)).0 || RET=$PLACE.3.1.1.11.2.1.0 ;;
    $PLACE.3.1.1.11.2.1.0|$PLACE.3.1.1.11.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.11.2.$((num+1)).0 || RET=$PLACE.3.1.1.12.1.1.0 ;;
    $PLACE.3.1.1.12.1.1.0|$PLACE.3.1.1.12.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.12.1.$((num+1)).0 || RET=$PLACE.3.1.1.12.2.1.0 ;;
    $PLACE.3.1.1.12.2.1.0|$PLACE.3.1.1.12.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.12.2.$((num+1)).0 || RET=$PLACE.3.1.1.13.1.1.0 ;;
    $PLACE.3.1.1.13.1.1.0|$PLACE.3.1.1.13.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.13.1.$((num+1)).0 || RET=$PLACE.3.1.1.13.2.1.0 ;;
    $PLACE.3.1.1.13.2.1.0|$PLACE.3.1.1.13.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.13.2.$((num+1)).0 || RET=$PLACE.3.1.1.14.1.1.0 ;;
    $PLACE.3.1.1.14.1.1.0|$PLACE.3.1.1.14.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.14.1.$((num+1)).0 || RET=$PLACE.3.1.1.14.2.1.0 ;;
    $PLACE.3.1.1.14.2.1.0|$PLACE.3.1.1.14.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.14.2.$((num+1)).0 || RET=$PLACE.3.1.1.15.1.1.0 ;;
    $PLACE.3.1.1.15.1.1.0|$PLACE.3.1.1.15.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.15.1.$((num+1)).0 || RET=$PLACE.3.1.1.15.2.1.0 ;;
    $PLACE.3.1.1.15.2.1.0|$PLACE.3.1.1.15.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.15.2.$((num+1)).0 || RET=$PLACE.3.1.1.16.1.1.0 ;;
    $PLACE.3.1.1.16.1.1.0|$PLACE.3.1.1.16.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.16.1.$((num+1)).0 || RET=$PLACE.3.1.1.16.2.1.0 ;;
    $PLACE.3.1.1.16.2.1.0|$PLACE.3.1.1.16.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.16.2.$((num+1)).0 || RET=$PLACE.3.1.1.17.1.1.0 ;;
    $PLACE.3.1.1.17.1.1.0|$PLACE.3.1.1.17.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.17.1.$((num+1)).0 || RET=$PLACE.3.1.1.17.2.1.0 ;;
    $PLACE.3.1.1.17.2.1.0|$PLACE.3.1.1.17.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.17.2.$((num+1)).0 || RET=$PLACE.3.1.1.18.1.1.0 ;;
    $PLACE.3.1.1.18.1.1.0|$PLACE.3.1.1.18.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.18.1.$((num+1)).0 || RET=$PLACE.3.1.1.18.2.1.0 ;;
    $PLACE.3.1.1.18.2.1.0|$PLACE.3.1.1.18.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.18.2.$((num+1)).0 || RET=$PLACE.3.1.1.19.1.1.0 ;;
    $PLACE.3.1.1.19.1.1.0|$PLACE.3.1.1.19.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.19.1.$((num+1)).0 || RET=$PLACE.3.1.1.19.2.1.0 ;;
    $PLACE.3.1.1.19.2.1.0|$PLACE.3.1.1.19.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.19.2.$((num+1)).0 || RET=$PLACE.3.1.1.20.1.1.0 ;;
    $PLACE.3.1.1.20.1.1.0|$PLACE.3.1.1.20.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.20.1.$((num+1)).0 || RET=$PLACE.3.1.1.20.2.1.0 ;;
    $PLACE.3.1.1.20.2.1.0|$PLACE.3.1.1.20.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.20.2.$((num+1)).0 || RET=$PLACE.3.1.1.21.1.1.0 ;;
    $PLACE.3.1.1.21.1.1.0|$PLACE.3.1.1.21.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.21.1.$((num+1)).0 || RET=$PLACE.3.1.1.21.2.1.0 ;;
    $PLACE.3.1.1.21.2.1.0|$PLACE.3.1.1.21.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.21.2.$((num+1)).0 || RET=$PLACE.3.1.1.22.1.1.0 ;;
    $PLACE.3.1.1.22.1.1.0|$PLACE.3.1.1.22.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.22.1.$((num+1)).0 || RET=$PLACE.3.1.1.22.2.1.0 ;;
    $PLACE.3.1.1.22.2.1.0|$PLACE.3.1.1.22.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.22.2.$((num+1)).0 || RET=$PLACE.3.1.1.23.1.1.0 ;;
    $PLACE.3.1.1.23.1.1.0|$PLACE.3.1.1.23.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.23.1.$((num+1)).0 || RET=$PLACE.3.1.1.23.2.1.0 ;;
    $PLACE.3.1.1.23.2.1.0|$PLACE.3.1.1.23.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.23.2.$((num+1)).0 || RET=$PLACE.3.1.1.24.1.1.0 ;;
    $PLACE.3.1.1.24.1.1.0|$PLACE.3.1.1.24.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.24.1.$((num+1)).0 || RET=$PLACE.3.1.1.24.2.1.0 ;;
    $PLACE.3.1.1.24.2.1.0|$PLACE.3.1.1.24.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.24.2.$((num+1)).0 || RET=$PLACE.3.1.1.25.1.1.0 ;;
    $PLACE.3.1.1.25.1.1.0|$PLACE.3.1.1.25.1.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.25.1.$((num+1)).0 || RET=$PLACE.3.1.1.25.2.1.0 ;;
    $PLACE.3.1.1.25.2.1.0|$PLACE.3.1.1.25.2.$num*)      [ "$num" -lt "$vap" ] && RET=$PLACE.3.1.1.25.2.$((num+1)).0 || exit ;;
    *) exit 0 ;;
    esac
else
    case "$REQ" in
    $PLACE)    exit 0 ;;
    *)         RET=$REQ ;;
    esac
fi

radio_num="$(($(echo $RET | cut -d "." -f 18)-1))"
vap_num="$(echo $RET | cut -d "." -f 19)"
ip_regex="\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b"
mac_regex="[0-9a-f][0-9a-f]:[0-9a-z][0-9a-f]:[0-9a-f][0-9a-f]:[0-9a-f][0-9a-f]:[0-9a-f][0-9a-f]:[0-9a-f][0-9a-f]"

 #Get or Set
function err_wrong_type() {
    echo "wrong-type"
    exit
}

function err_not_writeable() {
    echo "not-writeable"
    exit
}

function err_wrong_length() {
    echo "wrong-length"
    exit
}

function err_wrong_value() {
    echo "wrong-value"
    exit
}

function rename_rf() {
    local iface_cnt=$(uci show wireless | grep wifi-iface | grep $radio_num)

    for iface_in_cnt in $iface_cnt; do
        local cnt=${iface_in_cnt%=*}
        uci rename $cnt=${cnt#*.}
    done
}

function rename_usteer() {
    uci del usteer.@usteer[0].ssid_list
    local lists=$(uci show wireless | grep ssid | grep radio$radio_num | cut -d "=" -f 1)
    for list in $lists; do
        local name=$(uci get $list)
        uci add_list usteer.@usteer[0].ssid_list="$name"
    done
}
#-----------------------------GENERAL SETTINGS-------------------------------
function write_APSSIDStatus() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.disabled="$((2-WRITE_VALUE))"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}

function write_APSSIDName() {
    [ "$WRITE_TYPE" != "string" ] && err_wrong_type
    [ "${#WRITE_VALUE}" -lt "1" ] || [ "${#WRITE_VALUE}" -gt "64" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.ssid="$WRITE_VALUE"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}

function write_APSSIDBroadcast() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    [ "$WRITE_VALUE" -eq "1" ] && uci set wireless.radio$radio_num\_$vap_num.hidden="$((2-WRITE_VALUE))" || uci del wireless.radio$radio_num\_$vap_num.hidden
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}

function write_APSSIDLocalConfigurable() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.local_configurable="$((WRITE_VALUE-1))"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}

function write_APSSIDClientIsolation() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    [ "$WRITE_VALUE" -eq "2" ] && uci set wireless.radio$radio_num\_$vap_num.isolate="$((WRITE_VALUE-1))" || uci del wireless.radio$radio_num\_$vap_num.isolate
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}

function write_APRFMulticastToUnicastConversion() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.multicast_to_unicast="$((WRITE_VALUE-1))"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}

function write_APSSIDMaxClients() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt "1" ] || [ "$WRITE_VALUE" -gt "254" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.maxassoc="$WRITE_VALUE"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}

function write_APSSIDIdleTimeout() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt "60" ] || [ "$WRITE_VALUE" -gt "60000" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.max_inactivity="$WRITE_VALUE"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
#-----------------------------SECURITY SETTINGS-------------------------------
function write_APSSIDMethod() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt "1" ] || [ "$WRITE_VALUE" -gt "11" ] && err_wrong_value
    local encryption=$(uci show wireless | grep radio$radio_num\_$vap_num | grep tkip)
    local key=$(uci show wireless | grep radio$radio_num\_$vap_num | grep key)
    local ieee80211w=$(uci show wireless | grep radio$radio_num\_$vap_num | grep ieee80211w)
    local ieee80211r=$(uci show wireless | grep radio$radio_num\_$vap_num | grep ieee80211r)

    case "$WRITE_VALUE" in
        1)
            value="none"
            key_retries=0
            [ -n "$key" ] && uci del wireless.radio$radio_num\_$vap_num.key
            [ -n "$ieee80211w" ] && uci del wireless.radio$radio_num\_$vap_num.ieee80211w
            [ -n "$ieee80211r" ] && uci del wireless.radio$radio_num\_$vap_num.ieee80211r ;;
        2)
            key_retries=0
            [ -n "$encryption" ] && value="psk+tkip+ccmp" || value="psk+ccmp"
            [ -n "$ieee80211w" ] && uci del wireless.radio$radio_num\_$vap_num.ieee80211w
            [ -n "$ieee80211r" ] && uci del wireless.radio$radio_num\_$vap_num.ieee80211r ;;
        3)
            key_retries=0
            [ -n "$encryption" ] && value="psk2+tkip+ccmp" || value="psk2+ccmp" ;;
        4)
            key_retries=1
            [ -n "$encryption" ] && value="wpa+tkip+ccmp" || value="wpa+ccmp"
            [ -n "$key" ] && uci del wireless.radio$radio_num\_$vap_num.key
            [ -n "$ieee80211w" ] && uci del wireless.radio$radio_num\_$vap_num.ieee80211w
            [ -n "$ieee80211r" ] && uci del wireless.radio$radio_num\_$vap_num.ieee80211r ;;
        5)
            key_retries=1
            [ -n "$encryption" ] && value="wpa2+tkip+ccmp" || value="wpa2+ccmp"
            [ -n "$key" ] && uci del wireless.radio$radio_num\_$vap_num.key ;;
        6)  
            value="sae"
            key_retries=0
            [ -n "$ieee80211w" ] && uci del wireless.radio$radio_num\_$vap_num.ieee80211w ;;
        7)
            value="sae-mixed"
            key_retries=0
            [ -n "$key" ] && uci del wireless.radio$radio_num\_$vap_num.key
            [ -n "$ieee80211w" ] && uci del wireless.radio$radio_num\_$vap_num.ieee80211w ;;
        8)
            value="wpa3"
            key_retries=1
            [ -n "$key" ] && uci del wireless.radio$radio_num\_$vap_num.key
            [ -n "$ieee80211w" ] && uci del wireless.radio$radio_num\_$vap_num.ieee80211w ;;
        9)
            value="wpa3-mixed"
            key_retries=1
            [ -n "$key" ] && uci del wireless.radio$radio_num\_$vap_num.key ;;
        10)
            value="owe" 
            key_retries=0 ;;
        11)
            value="wpa3-192"
            [ -n "$key" ] && uci del wireless.radio$radio_num\_$vap_num.key
            [ -n "$ieee80211w" ] && uci del wireless.radio$radio_num\_$vap_num.ieee80211w
            [ -n "$ieee80211r" ] && uci del wireless.radio$radio_num\_$vap_num.ieee80211r ;;

    esac

    uci set wireless.radio$radio_num\_$vap_num.encryption="$value"
    uci set wireless.radio$radio_num\_$vap_num.wpa_disable_eapol_key_retries="$key_retries"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDEncryption() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    local method=$(uci get wireless.radio$radio_num\_$vap_num.encryption | cut -d "+" -f 1)
    case "$WRITE_VALUE" in
        1)      value=$method"+ccmp" ;;
        2)      value=$method"+tkip+ccmp" ;;
    esac
    uci set wireless.radio$radio_num\_$vap_num.encryption="$value"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDKey() {
    [ "$WRITE_TYPE" != "string" ] && err_wrong_type
    [ "${#WRITE_VALUE}" -lt "8" ] || [ "${#WRITE_VALUE}" -gt "64" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.key="$WRITE_VALUE"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDPMF() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    local encryption=$(uci get wireless.radio$radio_num\_$vap_num.encryption)
    case "$encryption" in
        sae-mixed|wpa3-mixed)   opt=2 ;;
        *)                      opt=1 ;;
    esac
    [ "$WRITE_VALUE" -lt "$opt" ] || [ "$WRITE_VALUE" -gt "3" ] && err_wrong_value
    case "$WRITE_VALUE" in
        1)      value=0 ;;
        2)      value=2 ;;
        3)      value=1 ;;
    esac
    uci set wireless.radio$radio_num\_$vap_num.ieee80211w="$value"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSID80211k() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt "1" ] || [ "$WRITE_VALUE" -gt "2" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.ieee80211k="$((WRITE_VALUE-1))"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSID80211r() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt "1" ] || [ "$WRITE_VALUE" -gt "2" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.ieee80211r="$((WRITE_VALUE-1))"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDRadiusMACAuth() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt "1" ] || [ "$WRITE_VALUE" -gt "2" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.radius_mac_acl="$((WRITE_VALUE-1))"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDRadiusAuthServer() {
    [ "$WRITE_TYPE" != "ipaddress" ] && err_wrong_type
    local ip_check=$(echo $WRITE_VALUE | egrep $ip_regex)
    [ -z "$ip_check" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.auth_server="$WRITE_VALUE"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDRadiusAuthPort() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt "0" ] || [ "$WRITE_VALUE" -gt "65535" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.auth_port="$WRITE_VALUE"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDRadiusAuthSecret() {
    [ "$WRITE_TYPE" != "string" ] && err_wrong_type
    [ "${#WRITE_VALUE}" -lt "1" ] || [ "${#WRITE_VALUE}" -gt "200" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.auth_secret="$WRITE_VALUE"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDBackupRadiusAuth() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt "1" ] || [ "$WRITE_VALUE" -gt "2" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.radius_auth_enable2="$((WRITE_VALUE-1))"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDBackupRadiusAuthServer() {
    [ "$WRITE_TYPE" != "ipaddress" ] && err_wrong_type
    local ip_check=$(echo $WRITE_VALUE | egrep $ip_regex)
    [ -z "$ip_check" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.auth_server2="$WRITE_VALUE"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDBackupRadiusAuthPort() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt "0" ] || [ "$WRITE_VALUE" -gt "65535" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.auth_port2="$WRITE_VALUE"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDBackupRadiusAuthSecret() {
    [ "$WRITE_TYPE" != "string" ] && err_wrong_type
    [ "${#WRITE_VALUE}" -lt "1" ] || [ "${#WRITE_VALUE}" -gt "200" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.auth_secret2="$WRITE_VALUE"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDAcctServer() {
    [ "$WRITE_TYPE" != "ipaddress" ] && err_wrong_type
    local ip_check=$(echo $WRITE_VALUE | egrep $ip_regex)
    [ -z "$ip_check" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.acct_server="$WRITE_VALUE"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDAcctPort() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt "0" ] || [ "$WRITE_VALUE" -gt "65535" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.acct_port="$WRITE_VALUE"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDAcctSecret() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "${#WRITE_VALUE}" -lt "1" ] || [ "${#WRITE_VALUE}" -gt "200" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.acct_secret="$WRITE_VALUE"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDAcctInterimInterval() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt "60" ] || [ "$WRITE_VALUE" -gt "600" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.acct_interval="$WRITE_VALUE"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDBackupRadiusAcct() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt "1" ] || [ "$WRITE_VALUE" -gt "2" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.acct_enable2="$((WRITE_VALUE-1))"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDRadiusAcctServer() {
    [ "$WRITE_TYPE" != "ipaddress" ] && err_wrong_type
    local ip_check=$(echo $WRITE_VALUE | egrep $ip_regex)
    [ -z "$ip_check" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.acct_server2="$WRITE_VALUE"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDRadiusAcctPort() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt "0" ] || [ "$WRITE_VALUE" -gt "65535" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.acct_port2="$WRITE_VALUE"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDRadiusAcctSecret() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "${#WRITE_VALUE}" -lt "1" ] || [ "${#WRITE_VALUE}" -gt "200" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.acct_secret2="$WRITE_VALUE"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDDynamicAuthorization() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.dae_enable="$((WRITE_VALUE-1))"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDDAEPort() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt "0" ] || [ "$WRITE_VALUE" -gt "65535" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.dae_port="$WRITE_VALUE"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDDAEClient() {
    [ "$WRITE_TYPE" != "ipaddress" ] && err_wrong_type
    local ip_check=$(echo $WRITE_VALUE | egrep $ip_regex)
    [ -z "$ip_check" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.dae_client="$WRITE_VALUE"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDDAESecret() {
    [ "$WRITE_TYPE" != "string" ] && err_wrong_type
    [ "${#WRITE_VALUE}" -lt "1" ] || [ "${#WRITE_VALUE}" -gt "200" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.dae_secret="$WRITE_VALUE"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDAccessControlList() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.macfilter_enable="$((WRITE_VALUE-1))"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDPolicy() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    case "$WRITE_VALUE" in
        1)      value="allow" ;;
        2)      value="deny" ;;
    esac
    uci set wireless.radio$radio_num\_$vap_num.macfilter="$value"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDFilteredMACs() {
    [ "$WRITE_TYPE" != "string" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt "0" ] || [ "$WRITE_VALUE" -gt "65535" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.maclist="$WRITE_VALUE"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDMultipleKeys() {
    [ "$WRITE_TYPE" != "string" ] && err_wrong_type
    local keys_list=$(echo $WRITE_VALUE | sed '{s/;/ /g}')
    for i in $keys_list; do
        local key=$(echo $i | cut -d "," -f 1)
        local mac=$(echo $i | cut -d "," -f 2)
        [ "${#key}" -lt "8" ] || [ "${#key}" -gt "63" ] && err_wrong_value
        [ -n "$mac" ] && [ -z $(echo $mac | egrep $mac_regex) ] && err_wrong_value
    done

    local radio_list=$(uci -q show wireless | grep wifi-station | grep -w radio$radio_num"_"$vap_num)
    while [ -n "$radio_list" ]; do
        local iface=$(echo $radio_list | awk '{print $1}' | cut -d "." -f 1,2)
        uci del $iface
        radio_list=$(uci -q show wireless | grep wifi-station | grep -w radio$radio_num"_"$vap_num)
    done

    for i in $keys_list; do
        local key=$(echo $i | cut -d "," -f 1)
        local mac=$(echo $i | cut -d "," -f 2)
        local sta_id=$(uci add wireless wifi-station)
        uci set wireless.$sta_id.iface="radio$radio_num"_"$vap_num"
        uci set wireless.$sta_id.key="$key"
        [ -n "$mac" ] && uci set wireless.$sta_id.mac="$mac"
    done
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSID80211v() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt "1" ] || [ "$WRITE_VALUE" -gt "2" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.ieee80211v="$((WRITE_VALUE-1))"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
#-----------------------------NETWORK SETTINGS-------------------------------
function write_APSSIDNetworkBehavior() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt "1" ] || [ "$WRITE_VALUE" -gt "6" ] && err_wrong_value
    case "$WRITE_VALUE" in
        1|6)    value="wan" ;;
        2)      value="lan" ;;
        3)      value="guest" ;;
        4)      value="hotspot" ;;
        5)      value="vlan4" ;;
    esac

    uci set wireless.radio$radio_num\_$vap_num.network="$value"

    if [ "$WRITE_VALUE" -eq 6 ]; then
        uci set wireless.radio$radio_num\_$vap_num.dynamic_vlan="2"
        uci set wireless.radio$radio_num\_$vap_num.vlan_tagged_interface="eth0"
        uci set wireless.radio$radio_num\_$vap_num.vlan_bridge="br-"
    else
        local dynamic_vlan_chk=$(uci show wireless.radio$radio_num\_$vap_num | grep dynamic_vlan)
        if [ -n "$dynamic_vlan_chk" ]; then
            uci del wireless.radio$radio_num\_$vap_num.dynamic_vlan
            uci del wireless.radio$radio_num\_$vap_num.vlan_tagged_interface
            uci del wireless.radio$radio_num\_$vap_num.vlan_bridge
        fi
    fi

    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDNetworkName() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    local cnt=0
    local names=$(uci show network | grep custom_ | grep =interface)
    for i in $names; do
        cnt=$((cnt+1))
    done
    [ "$WRITE_VALUE" -lt "1" ] || [ "$WRITE_VALUE" -gt "$((cnt+1))" ] && err_wrong_value
    value=""
    case "$WRITE_VALUE" in
        1)              value="lan" ;;
        2|3|4|5|6)      value="custom_$((WRITE_VALUE-2))" ;;
    esac
    uci set wireless.radio$radio_num\_$vap_num.network="$value"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDWalledGarden() {
    [ "$WRITE_TYPE" != "string" ] && err_wrong_type
    uci set wireless.radio$radio_num\_$vap_num.hs_wall="$WRITE_VALUE"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDVlanId() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt "2" ] || [ "$WRITE_VALUE" -gt "4094" ] && err_wrong_value
    local vlan_num=$(uci show network | grep vlan | grep ifname | grep "\.$WRITE_VALUE" | cut -d "." -f 2)
    [ -n "$vlan_num" ] && uci set wireless.radio$radio_num\_$vap_num.network="$vlan_num"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDCAPWAPTunnelInterface() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt "1" ] || [ "$WRITE_VALUE" -gt "3" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.CAPWAP_tunnel="$((WRITE_VALUE-1))"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDServiceZone() {
    [ "$WRITE_TYPE" != "string" ] && err_wrong_type
    uci set wireless.radio$radio_num\_$vap_num._s_zone_="$WRITE_VALUE"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDLimitUpload() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.limit_up_enable="$((WRITE_VALUE-1))"
    [ "$WRITE_VALUE" -eq "1" ] && uci del wireless.radio$radio_num\_$vap_num.limit_up
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDLimitUploadRate() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt "256" ] || [ "$WRITE_VALUE" -gt "10048576" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.limit_up="$WRITE_VALUE"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDLimitDownload() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.limit_down_enable="$((WRITE_VALUE-1))"
    [ "$WRITE_VALUE" -eq "1" ] && uci del wireless.radio$radio_num\_$vap_num.limit_down
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDLimitDownloadRate() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt "256" ] || [ "$WRITE_VALUE" -gt "10048576" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.limit_down="$WRITE_VALUE"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDAuthentication() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.cloud_aaa="$((WRITE_VALUE-1))"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDProxyARP() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    [ "$WRITE_VALUE" -eq "2" ] && uci set wireless.radio$radio_num\_$vap_num.proxy_arp="$((WRITE_VALUE-1))" || \
        uci del wireless.radio$radio_num\_$vap_num.proxy_arp
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDHotspot20() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    if [ "$WRITE_VALUE" -eq "2" ]; then
        uci set wireless.radio$radio_num\_$vap_num.hs20="1"
        uci set wireless.radio$radio_num\_$vap_num.anqp_domain_id="88"
        uci add_list wireless.radio$radio_num\_$vap_num.iw_venue_url="1:http://www.example.com/info-eng"
        uci set wireless.radio$radio_num\_$vap_num.hs20_oper_friendly_name="eng:EAP102"
    else
        uci set wireless.radio$radio_num\_$vap_num.hs20="0"
        uci del wireless.radio$radio_num\_$vap_num.anqp_domain_id
        uci del wireless.radio$radio_num\_$vap_num.iw_venue_url
        uci del wireless.radio$radio_num\_$vap_num.hs20_oper_friendly_name
    fi
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDInternetAccess() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.iw_internet="$((WRITE_VALUE-1))"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDInterworking() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    uci set wireless.radio$radio_num\_$vap_num.iw_enabled="$((WRITE_VALUE-1))"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDAccessNetworkType() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    case "$WRITE_VALUE" in
        1|2|3|4|5|6|15|16)
            uci del wireless.radio$radio_num\_$vap_num.iw_venue_url
            uci add_list wireless.radio$radio_num\_$vap_num.iw_venue_url="1:http://www.example.com/info-eng"
            uci set wireless.radio$radio_num\_$vap_num.iw_access_network_type="$((WRITE_VALUE-1))"
            rename_rf
            [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
            exit ;;
        *)  err_wrong_value ;;
    esac
}
function write_APSSIDVenueGroup() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt "1" ] || [ "$WRITE_VALUE" -gt "12" ] && err_wrong_value
    uci del wireless.radio$radio_num\_$vap_num.iw_venue_url
    uci add_list wireless.radio$radio_num\_$vap_num.iw_venue_url="1:http://www.example.com/info-eng"
    uci set wireless.radio$radio_num\_$vap_num.iw_venue_group="$((WRITE_VALUE-1))"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDVenueType() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt "1" ] || [ "$WRITE_VALUE" -gt "1" ] && err_wrong_value
    uci del wireless.radio$radio_num\_$vap_num.iw_venue_url
    uci add_list wireless.radio$radio_num\_$vap_num.iw_venue_url="1:http://www.example.com/info-eng"
    uci set wireless.radio$radio_num\_$vap_num.iw_venue_type="$((WRITE_VALUE-1))"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDVenueName() {
    [ "$WRITE_TYPE" != "string" ] && err_wrong_type
    uci del wireless.radio$radio_num\_$vap_num.iw_venue_url
    uci add_list wireless.radio$radio_num\_$vap_num.iw_venue_url="1:http://www.example.com/info-eng"
    local mode=$(echo $WRITE_VALUE | cut -d "," -f 1)
    case "$mode" in
        0)  uci del wireless.radio$radio_num\_$vap_num.iw_venue_name ;;
        1)  uci del_list wireless.radio$radio_num\_$vap_num.iw_venue_name="$(echo $WRITE_VALUE | cut -d "," -f 2)" ;;
        2)  uci add_list wireless.radio$radio_num\_$vap_num.iw_venue_name="$(echo $WRITE_VALUE | cut -d "," -f 2)" ;;
    esac
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDRoamingConsortiumList() {
    [ "$WRITE_TYPE" != "string" ] && err_wrong_type
    uci del wireless.radio$radio_num\_$vap_num.iw_venue_url
    uci add_list wireless.radio$radio_num\_$vap_num.iw_venue_url="1:http://www.example.com/info-eng"
    local mode=$(echo $WRITE_VALUE | cut -d "," -f 1)
    case "$mode" in
        0)  uci del wireless.radio$radio_num\_$vap_num.iw_roaming_consortium ;;
        1)  uci del_list wireless.radio$radio_num\_$vap_num.iw_roaming_consortium="$(echo $WRITE_VALUE | cut -d "," -f 2)" ;;
        2)  uci add_list wireless.radio$radio_num\_$vap_num.iw_roaming_consortium="$(echo $WRITE_VALUE | cut -d "," -f 2)" ;;
    esac
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDIPv4AddressType() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    case "$WRITE_VALUE" in
        0|4|8|12|16|20|24|28)
            uci del wireless.radio$radio_num\_$vap_num.iw_venue_url
            uci add_list wireless.radio$radio_num\_$vap_num.iw_venue_url="1:http://www.example.com/info-eng"
            uci set wireless.radio$radio_num\_$vap_num.iw_ipaddr_type_availability=$WRITE_VALUE
            rename_rf
            [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
            exit ;;
        *)  err_wrong_value ;;
    esac
}
function write_APSSIDIPv6AddressType() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt "1" ] || [ "$WRITE_VALUE" -gt "3" ] && err_wrong_value
    uci del wireless.radio$radio_num\_$vap_num.iw_venue_url
    uci add_list wireless.radio$radio_num\_$vap_num.iw_venue_url="1:http://www.example.com/info-eng"
    uci set wireless.radio$radio_num\_$vap_num.ipaddr_type_availability_ipv6=$((WRITE_VALUE-1))
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDNAIRealmList() {
    [ "$WRITE_TYPE" != "string" ] && err_wrong_type
    uci del wireless.radio$radio_num\_$vap_num.iw_venue_url
    uci add_list wireless.radio$radio_num\_$vap_num.iw_venue_url="1:http://www.example.com/info-eng"
    local mode=$(echo $WRITE_VALUE | cut -d "," -f 1)
    case "$mode" in
        0)  uci del wireless.radio$radio_num\_$vap_num.iw_nai_realm ;;
        1)  uci del_list wireless.radio$radio_num\_$vap_num.iw_nai_realm="$(echo $WRITE_VALUE | cut -d "," -f 2)" ;;
        2)  uci add_list wireless.radio$radio_num\_$vap_num.iw_nai_realm="$(echo $WRITE_VALUE | cut -d "," -f 2)" ;;
    esac
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDDomainNameList() {
    [ "$WRITE_TYPE" != "string" ] && err_wrong_type
    uci del wireless.radio$radio_num\_$vap_num.iw_venue_url
    uci add_list wireless.radio$radio_num\_$vap_num.iw_venue_url="1:http://www.example.com/info-eng"
    local mode=$(echo $WRITE_VALUE | cut -d "," -f 1)
    case "$mode" in
        0)  uci del wireless.radio$radio_num\_$vap_num.iw_domain_name ;;
        1)  uci del_list wireless.radio$radio_num\_$vap_num.iw_domain_name="$(echo $WRITE_VALUE | cut -d "," -f 2)" ;;
        2)  uci add_list wireless.radio$radio_num\_$vap_num.iw_domain_name="$(echo $WRITE_VALUE | cut -d "," -f 2)" ;;
    esac
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDCellularNetworkInformationList() {
    [ "$WRITE_TYPE" != "string" ] && err_wrong_type
    uci del wireless.radio$radio_num\_$vap_num.iw_venue_url
    uci add_list wireless.radio$radio_num\_$vap_num.iw_venue_url="1:http://www.example.com/info-eng"
    uci set wireless.radio$radio_num\_$vap_num.iw_anqp_3gpp_cell_net="$WRITE_VALUE"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}

function output_next() {
    local item=$1
    local item_num=$2
    if [ -z "$value" -a "$OP" == "-n" -a "$((vap_num+1))" -le "$vap" ]; then
        output $PLACE.$item.1.1.$item_num.$((radio_num+1)).$((vap_num+1)).0
    elif [ -z "$value" -a "$OP" == "-n" -a "$((vap_num+1))" -gt "$vap" ]; then
        [ "$radio_num" -eq 0 ] && output $PLACE.$item.1.1.$item_num.2.1.0 || {
            [ "$item" -eq 1 -a "$item_num" -eq 8 ] && output $PLACE.2.1.1.1.1.1.0
            [ "$item" -eq 2 -a "$item_num" -eq 30 ] && output $PLACE.3.1.1.1.1.1.0
            output $PLACE.$item.1.1.$((item_num+1)).1.1.0
        }
    fi
}

function output() {
    local RET_OID="$1"
    local radio_num=$(($(echo $RET_OID | cut -d "." -f 18)-1))
    local vap_num=$(echo $RET_OID | cut -d "." -f 19)

    case "$RET_OID" in
#-----------------------------GENERAL SETTINGS-------------------------------
        $PLACE.1.1.1.1.*) #APSSIDStatus
            [ "$OP" == "-s" ] && write_APSSIDStatus
            value=$(uci -q get wireless.radio$radio_num\_$vap_num.disabled)
            [ -n "$value" ] && value="$((2-value))"
            output_next 1 1
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.1.1.1.2.*) #APSSIDName
            [ "$OP" == "-s" ] && write_APSSIDName
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.ssid)"
            output_next 1 2
            echo "$RET_OID"
            echo "string"; echo $value; exit 0 ;;
        $PLACE.1.1.1.3.*) #APSSIDBroadcast
            [ "$OP" == "-s" ] && write_APSSIDBroadcast
            chk=$(uci show wireless | grep radio$radio_num\_$vap_num)
            [ -n "$chk" ] && value="2" || value=""
            hidden_chk=$(uci show wireless | grep radio$radio_num\_$vap_num | grep hidden)
            [ -n "$hidden_chk" ] && value="$((2-$(uci get wireless.radio$radio_num\_$vap_num.hidden)))"
            output_next 1 3
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.1.1.1.4.*) #APSSIDLocalConfigurable
            [ "$OP" == "-s" ] && write_APSSIDLocalConfigurable
            value=$(uci -q get wireless.radio$radio_num\_$vap_num.local_configurable)
            [ -n "$value" ] && value="$((value+1))"
            output_next 1 4
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.1.1.1.5.*) #APSSIDClientIsolation
            [ "$OP" == "-s" ] && write_APSSIDClientIsolation
            chk=$(uci show wireless | grep radio$radio_num\_$vap_num)
            [ -n "$chk" ] && value="1" || value=""
            isolate_chk=$(uci show wireless | grep radio$radio_num\_$vap_num | grep isolate)
            [ -n "$isolate_chk" ] && value="$(($(uci get wireless.radio$radio_num\_$vap_num.isolate)+1))"
            output_next 1 5
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.1.1.1.6.*) #APSSIDMaxClients
            [ "$OP" == "-s" ] && write_APSSIDMaxClients
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.maxassoc)"
            output_next 1 6
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.1.1.1.7.*) #APSSIDIdleTimeout
            [ "$OP" == "-s" ] && write_APSSIDIdleTimeout
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.max_inactivity)"
            output_next 1 7
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.1.1.1.8.*) #APRFMulticastToUnicastConversion
            [ "$OP" == "-s" ] && write_APRFMulticastToUnicastConversion
            chk=$(uci show wireless | grep radio$radio_num\_$vap_num)
            [ -n "$chk" ] && {
                mcast_chk=$(uci show wireless.radio$radio_num\_$vap_num | grep multicast_to_unicast)
                [ -n "$mcast_chk" ] && value="$(($(uci get wireless.radio$radio_num\_$vap_num.multicast_to_unicast)+1))" || value=""
            } || value=""
            output_next 1 8
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
#-----------------------------SECURITY SETTINGS-------------------------------
        $PLACE.2.1.1.1.*) #APSSIDMethod
            [ "$OP" == "-s" ] && write_APSSIDMethod
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.encryption)"
            case "$value" in
                none)                               value=1 ;; #"none"
                psk+ccmp|psk+tkip+ccmp)             value=2 ;; #"WPA-PSK"
                psk2+ccmp|psk2+tkip+ccmp)           value=3 ;; #"WPA2-PSK"
                wpa+ccmp|wpa+tkip+ccmp)             value=4 ;; #"WPA-EAP"
                wpa2+ccmp|wpa2+tkip+ccmp)           value=5 ;; #"WPA2-EAP"
                sae)                                value=6 ;; #"WPA3 Personal"
                sae-mixed)                          value=7 ;; #"WPA3 Personal Transition"
                wpa3)                               value=8 ;; #"WPA3 Enterprise"
                wpa3-mixed)                         value=9 ;; #"WPA3 Enterprise Transition"
                owe)                                value=10 ;; #"OWE"
                wpa3-192)                           value=11 ;; #"WPA3 Enterprise 192-bit"
            esac
            output_next 2 1
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.2.1.1.2.*) #APSSIDEncryption
            [ "$OP" == "-s" ] && write_APSSIDEncryption
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.encryption)"
            case "$value" in
                *tkip*)                             value=2 ;; #"Auto: TKIP+CCMP(AES)" ;;
                *ccmp)                              value=1 ;; #"CCMP(AES)" ;;
                none)                               value=0 ;;
            esac
            output_next 2 2
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.2.1.1.3.*) #APSSIDKey
            [ "$OP" == "-s" ] && write_APSSIDKey
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.key)"
            output_next 2 3
            echo "$RET_OID"
            echo "string"; echo $value; exit 0 ;;
        $PLACE.2.1.1.4.*) #APSSIDPMF
            [ "$OP" == "-s" ] && write_APSSIDPMF
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.ieee80211w)"
            case "$value" in
                0)      value=1 ;;
                1)      value=3 ;;
                2)      value=2 ;;
            esac
            output_next 2 4
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.2.1.1.5.*) #APSSID80211k
            [ "$OP" == "-s" ] && write_APSSID80211k
            value=$(uci -q get wireless.radio$radio_num\_$vap_num.ieee80211k)
            [ -n "$value" ] && value="$((value+1))"
            output_next 2 5
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.2.1.1.6.*) #APSSID80211r
            [ "$OP" == "-s" ] && write_APSSID80211r
            value=$(uci -q get wireless.radio$radio_num\_$vap_num.ieee80211r)
            [ -n "$value" ] && value="$((value+1))"
            output_next 2 6
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.2.1.1.7.*) #APSSIDRadiusMACAuth
            [ "$OP" == "-s" ] && write_APSSIDRadiusMACAuth
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.radius_mac_acl)"
            [ -n "$value" ] && value="$((value+1))"
            output_next 2 7
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.2.1.1.8.*) #APSSIDRadiusAuthServer
            [ "$OP" == "-s" ] && write_APSSIDRadiusAuthServer
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.auth_server)"
            output_next 2 8
            echo "$RET_OID"
            [ -n "$value" ] && echo "ipaddress" || echo "string"; echo $value; exit 0 ;;
        $PLACE.2.1.1.9.*) #APSSIDRadiusAuthPort
            [ "$OP" == "-s" ] && write_APSSIDRadiusAuthPort
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.auth_port)"
            output_next 2 9
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.2.1.1.10.*) #APSSIDRadiusAuthSecret
            [ "$OP" == "-s" ] && write_APSSIDRadiusAuthSecret
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.auth_secret)"
            output_next 2 10
            echo "$RET_OID"
            echo "string"; echo $value; exit 0 ;;
        $PLACE.2.1.1.11.*) #APSSIDBackupRadiusAuth
            [ "$OP" == "-s" ] && write_APSSIDBackupRadiusAuth
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.radius_auth_enable2)"
            [ -n "$value" ] && value="$((value+1))"
            output_next 2 11
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.2.1.1.12.*) #APSSIDBackupRadiusAuthServer
            [ "$OP" == "-s" ] && write_APSSIDBackupRadiusAuthServer
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.auth_server2)"
            output_next 2 12
            echo "$RET_OID"
            [ -n "$value" ] && echo "ipaddress" || echo "string"; echo $value; exit 0 ;;
        $PLACE.2.1.1.13.*) #APSSIDBackupRadiusAuthPort
            [ "$OP" == "-s" ] && write_APSSIDBackupRadiusAuthPort
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.auth_port2)"
            output_next 2 13
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.2.1.1.14.*) #APSSIDBackupRadiusAuthSecret
            [ "$OP" == "-s" ] && write_APSSIDBackupRadiusAuthSecret
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.auth_secret2)"
            output_next 2 14
            echo "$RET_OID"
            echo "string"; echo $value; exit 0 ;;
        $PLACE.2.1.1.15.*) #APSSIDAcctServer
            [ "$OP" == "-s" ] && write_APSSIDAcctServer
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.acct_server)"
            output_next 2 15
            echo "$RET_OID"
            [ -n "$value" ] && echo "ipaddress" || echo "string"; echo $value; exit 0 ;;
        $PLACE.2.1.1.16.*) #APSSIDAcctPort
            [ "$OP" == "-s" ] && write_APSSIDAcctPort
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.acct_port)"
            output_next 2 16
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.2.1.1.17.*) #APSSIDAcctSecret
            [ "$OP" == "-s" ] && write_APSSIDAcctSecret
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.acct_secret)"
            output_next 2 17
            echo "$RET_OID"
            echo "string"; echo $value; exit 0 ;;
        $PLACE.2.1.1.18.*) #APSSIDAcctInterimInterval
            [ "$OP" == "-s" ] && write_APSSIDAcctInterimInterval
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.acct_interval)"
            output_next 2 18
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.2.1.1.19.*) #APSSIDBackupRadiusAcct
            [ "$OP" == "-s" ] && write_APSSIDBackupRadiusAcct
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.acct_enable2)"
            [ -n "$value" ] && value="$((value+1))"
            output_next 2 19
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.2.1.1.20.*) #APSSIDRadiusAcctServer
            [ "$OP" == "-s" ] && write_APSSIDRadiusAcctServer
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.acct_server2)"
            output_next 2 20
            echo "$RET_OID"
            [ -n "$value" ] && echo "ipaddress" || echo "string"; echo $value; exit 0 ;;
        $PLACE.2.1.1.21.*) #APSSIDRadiusAcctPort
            [ "$OP" == "-s" ] && write_APSSIDRadiusAcctPort
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.acct_port2)"
            output_next 2 21
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.2.1.1.22.*) #APSSIDRadiusAcctSecret
            [ "$OP" == "-s" ] && write_APSSIDRadiusAcctSecret
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.acct_secret2)"
            output_next 2 22
            echo "$RET_OID"
            echo "string"; echo $value; exit 0 ;;
        $PLACE.2.1.1.23.*) #APSSIDDynamicAuthorization
            [ "$OP" == "-s" ] && write_APSSIDDynamicAuthorization
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.dae_enable)"
            [ -n "$value" ] && value="$((value+1))"
            output_next 2 23
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.2.1.1.24.*) #APSSIDDAEPort
            [ "$OP" == "-s" ] && write_APSSIDDAEPort
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.dae_port)"
            output_next 2 24
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.2.1.1.25.*) #APSSIDDAEClient
            [ "$OP" == "-s" ] && write_APSSIDDAEClient
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.dae_client)"
            output_next 2 25
            echo "$RET_OID"
            [ -n "$value" ] && echo "ipaddress" || echo "string"; echo $value; exit 0 ;;
        $PLACE.2.1.1.26.*) #APSSIDDAESecret
            [ "$OP" == "-s" ] && write_APSSIDDAESecret
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.dae_secret)"
            output_next 2 26
            echo "$RET_OID"
            echo "string"; echo $value; exit 0 ;;
        $PLACE.2.1.1.27.*) #APSSIDAccessControlList
            [ "$OP" == "-s" ] && write_APSSIDAccessControlList
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.macfilter_enable)"
            [ -n "$value" ] && value="$((value+1))"
            output_next 2 27
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.2.1.1.28.*) #APSSIDPolicy
            [ "$OP" == "-s" ] && write_APSSIDPolicy
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.macfilter)"
            case "$value" in
                allow)      value=1 ;;
                deny)       value=2 ;;
            esac
            output_next 2 28
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.2.1.1.29.*) #APSSIDFilteredMACs
            [ "$OP" == "-s" ] && write_APSSIDFilteredMACs
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.maclist)"
            output_next 2 29
            echo "$RET_OID"
            echo "string"; echo $value; exit 0 ;;
        $PLACE.2.1.1.30.*) #APSSIDMultipleKeys
            [ "$OP" == "-s" ] && write_APSSIDMultipleKeys
            sta_list=$(uci show wireless | grep =wifi-station | cut -d "=" -f 1)
            value=""
            if [ -n "$sta_list" ]; then
                for i in $sta_list; do
                    iface=$(uci -q get $i.iface)
                    [ "$iface" == "radio$radio_num"_"$vap_num" ] && {
                        key=$(uci -q get $i.key)
                        mac=$(uci -q get $i.mac)
                        value="$value$key,$mac;"
                    }
                done
            fi
            output_next 2 30
            echo "$RET_OID"
            echo "string"; echo $value; exit 0 ;;
        $PLACE.2.1.1.31.*) #APSSID80211v
            [ "$OP" == "-s" ] && write_APSSID80211v
            value=$(uci -q get wireless.radio$radio_num\_$vap_num.ieee80211v)
            [ -n "$value" ] && value="$((value+1))"
            output_next 2 31
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
#-----------------------------NETWORK SETTINGS-------------------------------
        $PLACE.3.1.1.1.*) #APSSIDNetworkBehavior
            [ "$OP" == "-s" ] && write_APSSIDNetworkBehavior
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.network)"
            case "$value" in
                wan)        dynamic_vlan=$(uci show wireless.radio$radio_num\_$vap_num | grep dynamic_vlan)
                            [ -z "$dynamic_vlan" ] && value=1 || value=6 ;;
                lan|custom_*)
                            value=2 ;;
                guest)      value=3 ;;
                hotspot)    value=4 ;;
                vlan*)      value=5 ;;
            esac
            output_next 3 1
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.3.1.1.2.*) #APSSIDNetworkName
            [ "$OP" == "-s" ] && write_APSSIDNetworkName
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.network)"
            case "$value" in
                lan)        value=1 ;;
                custom_*)   value=$(($(echo $value | cut -d "_" -f 2)+2)) ;;
            esac
            output_next 3 2
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.3.1.1.3.*) #APSSIDWalledGarden
            [ "$OP" == "-s" ] && write_APSSIDWalledGarden
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.hs_wall)"
            output_next 3 3
            echo "$RET_OID"
            echo "string"; echo $value; exit 0 ;;
        $PLACE.3.1.1.4.*) #APSSIDVlanId
            [ "$OP" == "-s" ] && write_APSSIDVlanId
            vlan=$(uci -q get wireless.radio$radio_num\_$vap_num.network)
            case "$vlan" in
                vlan*)      value=$(uci -q get network.$vlan.ifname | awk '{print $1}' | cut -d "." -f 2) ;;
            esac
            output_next 3 4
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.3.1.1.5.*) #APSSIDCAPWAPTunnelInterface
            [ "$OP" == "-s" ] && write_APSSIDCAPWAPTunnelInterface
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.CAPWAP_tunnel)"
            [ -n "$value" ] && value="$((value+1))"
            output_next 3 5
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.3.1.1.6.*) #APSSIDServiceZone
            [ "$OP" == "-s" ] && write_APSSIDServiceZone
            value="$(uci -q get wireless.radio$radio_num\_$vap_num._s_zone_)"
            output_next 3 6
            echo "$RET_OID"
            echo "string"; echo $value; exit 0 ;;
        $PLACE.3.1.1.7.*) #APSSIDLimitUpload
            [ "$OP" == "-s" ] && write_APSSIDLimitUpload
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.limit_up_enable)"
            [ -n "$value" ] && value="$((value+1))"
            output_next 3 7
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.3.1.1.8.*) #APSSIDLimitUploadRate
            [ "$OP" == "-s" ] && write_APSSIDLimitUploadRate
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.limit_up)"
            output_next 3 8
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.3.1.1.9.*) #APSSIDLimitDownload
            [ "$OP" == "-s" ] && write_APSSIDLimitDownload
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.limit_down_enable)"
            [ -n "$value" ] && value="$((value+1))"
            output_next 3 9
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.3.1.1.10.*) #APSSIDLimitDownloadRate
            [ "$OP" == "-s" ] && write_APSSIDLimitDownloadRate
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.limit_down)"
            output_next 3 10
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.3.1.1.11.*) #APSSIDAuthentication
            [ "$OP" == "-s" ] && write_APSSIDAuthentication
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.cloud_aaa)"
            [ -n "$value" ] && value="$((value+1))"
            output_next 3 11
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.3.1.1.12.*) #APSSIDProxyARP
            [ "$OP" == "-s" ] && write_APSSIDProxyARP
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.proxy_arp)"
            [ -n "$value" ] && value="$((value+1))"
            output_next 3 12
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.3.1.1.13.*) #APSSIDHotspot20
            [ "$OP" == "-s" ] && write_APSSIDHotspot20
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.hs20)"
            [ -n "$value" ] && value="$((value+1))"
            output_next 3 13
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.3.1.1.14.*) #APSSIDInternetAccess
            [ "$OP" == "-s" ] && write_APSSIDInternetAccess
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.iw_internet)"
            [ -n "$value" ] && value="$((value+1))"
            output_next 3 14
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.3.1.1.15.*) #APSSIDInterworking
            [ "$OP" == "-s" ] && write_APSSIDInterworking
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.iw_enabled)"
            [ -n "$value" ] && value="$((value+1))"
            output_next 3 15
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.3.1.1.16.*) #APSSIDAccessNetworkType
            [ "$OP" == "-s" ] && write_APSSIDAccessNetworkType
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.iw_access_network_type)"
            [ -n "$value" ] && value="$((value+1))"
            output_next 3 16
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.3.1.1.17.*) #APSSIDVenueGroup
            [ "$OP" == "-s" ] && write_APSSIDVenueGroup
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.iw_venue_group)"
            [ -n "$value" ] && value="$((value+1))"
            output_next 3 17
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.3.1.1.18.*) #APSSIDVenueType
            [ "$OP" == "-s" ] && write_APSSIDVenueType
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.iw_venue_type)"
            [ -n "$value" ] && value="$((value+1))"
            output_next 3 18
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.3.1.1.19.*) #APSSIDVenueName
            [ "$OP" == "-s" ] && write_APSSIDVenueName
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.iw_venue_name)"
            output_next 3 19
            echo "$RET_OID"
            echo "string"; echo $value; exit 0 ;;
        $PLACE.3.1.1.20.*) #APSSIDRoamingConsortiumList
            [ "$OP" == "-s" ] && write_APSSIDRoamingConsortiumList
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.iw_roaming_consortium)"
            output_next 3 20
            echo "$RET_OID"
            echo "string"; echo $value; exit 0 ;;
        $PLACE.3.1.1.21.*) #APSSIDIPv4AddressType
            [ "$OP" == "-s" ] && write_APSSIDIPv4AddressType
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.iw_ipaddr_type_availability)"
            output_next 3 21
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.3.1.1.22.*) #APSSIDIPv6AddressType
            [ "$OP" == "-s" ] && write_APSSIDIPv6AddressType
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.ipaddr_type_availability_ipv6)"
            [ -n "$value" ] && value="$((value+1))"
            output_next 3 22
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.3.1.1.23.*) #APSSIDNAIRealmList
            [ "$OP" == "-s" ] && write_APSSIDNAIRealmList
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.iw_nai_realm)"
            output_next 3 23
            echo "$RET_OID"
            echo "string"; echo $value; exit 0 ;;
        $PLACE.3.1.1.24.*) #APSSIDDomainNameList
            [ "$OP" == "-s" ] && write_APSSIDDomainNameList
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.iw_domain_name)"
            output_next 3 24
            echo "$RET_OID"
            echo "string"; echo $value; exit 0 ;;
        $PLACE.3.1.1.25.*) #APSSIDCellularNetworkInformationList
            [ "$OP" == "-s" ] && write_APSSIDCellularNetworkInformationList
            value="$(uci -q get wireless.radio$radio_num\_$vap_num.iw_anqp_3gpp_cell_net)"
            output_next 3 25
            echo "$RET_OID"
            echo "string"; echo $value; exit 0 ;;
        *) echo "string"; echo "ack... $RET_OID $REQ"; exit 0 ;;
    esac
}
output $RET
