#!/bin/sh
. /lib/functions.sh
. /lib/acn/acn_functions.sh

country_val="$1"
setup_wiz="$2"
MID="$(get_MID)"

#can't get board data, so use fake iw reg get and custom data to set
txpwr_2g=0
txpwr_5g=0
maxtxpwr_2g=0
maxtxpwr_5g=0
section_name_5g="radio0"
section_name_2g="radio1"
channel_2g='auto'
channel_5g='auto'
channels_2g=""
channels_5g=""

radio_info() {
  _radio="$1"
  config_get band $_radio band
  if [ "$band" == "5g" ]; then
    section_name_5g="$_radio" #radio0
  else
    section_name_2g="$_radio" #radio1
  fi
}

config_load wireless
config_foreach radio_info wifi-device

htmode_5g="`uci get wireless.$section_name_5g.htmode 2>/dev/null | grep -o -E '[0-9]+'`"
htmode_2g="`uci get wireless.$section_name_2g.htmode 2>/dev/null | grep -o -E '[0-9]+'`"

case $MID in
"EAP101"*)
  case $country_val in
  "CTICK")
    txpwr_2g=13
    txpwr_5g=15
    maxtxpwr_2g=13
    maxtxpwr_5g=26

    if [ "$htmode_5g" == "20" ]; then
        channels_5g="36,40,44,48,52,56,60,64,100,104,108,112,116,120,124,128,132,136,140,149,153,157,161,165"
    elif [[ "$htmode_5g" == "40" ]]; then
        channels_5g="36,44,52,60,100,108,116,124,132,149,157"
    else
        channels_5g="36,52,100,116,149"
    fi

    if [ "$htmode_2g" == "20" ]; then
        channels_2g="1,2,3,4,5,6,7,8,9,10,11,12,13"
    elif [[ "$htmode_2g" == "40" ]]; then
        channels_2g="1,2,3,4,5,6,7,8,9"
    fi
    ;;
  "ETSI")
    txpwr_2g=13
    txpwr_5g=16
    maxtxpwr_2g=13
    maxtxpwr_5g=23

    if [ "$htmode_5g" == "20" ]; then
        channels_5g="36,40,44,48,52,56,60,64,100,104,108,112,116,120,124,128,132,136,140"
    elif [[ "$htmode_5g" == "40" ]]; then
        channels_5g="36,44,52,60,100,108,116,124,132"
    else
        channels_5g="36,52,100,116"
    fi

    if [ "$htmode_2g" == "20" ]; then
        channels_2g="1,2,3,4,5,6,7,8,9,10,11,12,13"
    elif [[ "$htmode_2g" == "40" ]]; then
        channels_2g="1,2,3,4,5,6,7,8,9"
    fi
    ;;
  "KR")
    txpwr_2g=23
    txpwr_5g=23
    maxtxpwr_2g=23
    maxtxpwr_5g=23

    if [ "$htmode_5g" == "20" ]; then
        channels_5g="36,40,44,48,52,56,60,64,100,104,108,112,116,120,124,128,132,136,140,144,149,153,157,161,165"
    elif [[ "$htmode_5g" == "40" ]]; then
        channels_5g="36,44,52,60,100,108,116,124,132,140,149,157"
    else
        channels_5g="36,52,100,116,132,149"
    fi

    if [ "$htmode_2g" == "20" ]; then
        channels_2g="1,2,3,4,5,6,7,8,9,10,11,12,13"
    elif [[ "$htmode_2g" == "40" ]]; then
        channels_2g="1,2,3,4,5,6,7,8,9"
    fi
    ;;
  "IC")
    txpwr_2g=22
    txpwr_5g=13
    maxtxpwr_2g=22
    maxtxpwr_5g=26

    if [ "$htmode_5g" == "20" ]; then
        channels_5g="36,40,44,48,149,153,157,161,165"
    elif [[ "$htmode_5g" == "40" ]]; then
        channels_5g="36,44,149,157"
    else
        channels_5g="36,149"
    fi

    if [ "$htmode_2g" == "20" ]; then
        channels_2g="1,2,3,4,5,6,7,8,9,10,11"
    elif [[ "$htmode_2g" == "40" ]]; then
        channels_2g="1,2,3,4,5,6,7"
    fi
    ;;
  "IN")
    txpwr_2g=20
    txpwr_5g=23
    maxtxpwr_2g=20
    maxtxpwr_5g=23

    if [ "$htmode_5g" == "20" ]; then
        channels_5g="36,40,44,48,149,153,157,161,165"
    elif [[ "$htmode_5g" == "40" ]]; then
        channels_5g="36,44,149,157"
    else
        channels_5g="36,149"
    fi

    if [ "$htmode_2g" == "20" ]; then
        channels_2g="1,2,3,4,5,6,7,8,9,10,11,12,13"
    elif [[ "$htmode_2g" == "40" ]]; then
        channels_2g="1,2,3,4,5,6,7,8,9"
    fi
    ;;
  "JP")
    txpwr_2g=14
    txpwr_5g=14
    maxtxpwr_2g=14
    maxtxpwr_5g=20

    if [ "$htmode_5g" == "20" ]; then
      channels_5g="36,40,44,48,52,56,60,64,100,104,108,112,116,120,124,128,132,136,140,144"
    elif [[ "$htmode_5g" == "40" ]]; then
      channels_5g="36,44,52,60,100,108,116,124,132,140"
    else
      channels_5g="36,52,100,116,132"
    fi

    if [ "$htmode_2g" == "20" ]; then
      channels_2g="1,2,3,4,5,6,7,8,9,10,11,12,13"
    elif [[ "$htmode_2g" == "40" ]]; then
      channels_2g="1,2,3,4,5,6,7,8,9"
    fi
    ;;
  "NCC")
    txpwr_2g=22
    txpwr_5g=21
    maxtxpwr_2g=22
    maxtxpwr_5g=26

    if [ "$htmode_5g" == "20" ]; then
      channels_5g="36,40,44,48,149,153,157,161,165"
    elif [[ "$htmode_5g" == "40" ]]; then
      channels_5g="36,44,149,157"
    else
      channels_5g="36,149"
    fi

    if [ "$htmode_2g" == "20" ]; then
      channels_2g="1,2,3,4,5,6,7,8,9,10,11"
    elif [[ "$htmode_2g" == "40" ]]; then
      channels_2g="1,2,3,4,5,6,7"
    fi
    ;;
  "TH")
    txpwr_2g=13
    txpwr_5g=15
    maxtxpwr_2g=13
    maxtxpwr_5g=22

    if [ "$htmode_5g" == "20" ]; then
      channels_5g="36,40,44,48,52,56,60,64,100,104,108,112,116,120,124,128,132,136,140,149,153,157,161,165"
    elif [[ "$htmode_5g" == "40" ]]; then
      channels_5g="36,44,52,60,100,108,116,124,132,140,149,157"
    else
      channels_5g="36,52,100,116,132,149"
    fi

    if [ "$htmode_2g" == "20" ]; then
      channels_2g="1,2,3,4,5,6,7,8,9,10,11,12,13"
    elif [[ "$htmode_2g" == "40" ]]; then
      channels_2g="1,2,3,4,5,6,7,8,9"
    fi
    ;;
  "FCC"|"US")
    #others use us setting as standard
    txpwr_2g=22
    txpwr_5g=20
    maxtxpwr_2g=22
    maxtxpwr_5g=26

    if [ "$htmode_5g" == "20" ]; then
      channels_5g="36,40,44,48,52,56,60,64,100,104,108,112,116,120,124,128,132,136,140,149,153,157,161,165"
    elif [[ "$htmode_5g" == "40" ]]; then
      channels_5g="36,44,52,60,100,108,116,124,132,149,157"
    else
      channels_5g="36,52,100,116,149"
    fi

    if [ "$htmode_2g" == "20" ]; then
      channels_2g="1,2,3,4,5,6,7,8,9,10,11"
    elif [[ "$htmode_2g" == "40" ]]; then
      channels_2g="1,2,3,4,5,6,7"
    fi
    ;;
  "BR")
    txpwr_2g=20
    txpwr_5g=26
    maxtxpwr_2g=20
    maxtxpwr_5g=26

    if [ "$htmode_5g" == "20" ]; then
      channels_5g="36,40,44,48,52,56,60,64,100,104,108,112,116,120,124,128,132,136,140,149,153,157,161,165"
    elif [[ "$htmode_5g" == "40" ]]; then
      channels_5g="36,44,52,60,100,108,116,124,132,140,149,157"
    elif [[ "$htmode_5g" == "80" ]]; then
      channels_5g="36,52,100,116,132,149"
    else
      channels_5g="100,116,132,149"
    fi

    if [ "$htmode_2g" == "20" ]; then
      channels_2g="1,2,3,4,5,6,7,8,9,10,11,12,13"
    elif [[ "$htmode_2g" == "40" ]]; then
      channels_2g="1,2,3,4,5,6,7,8,9"
    fi
  ;;
  "VN")
    txpwr_2g=13
    txpwr_5g=16
    maxtxpwr_2g=13
    maxtxpwr_5g=23

    if [ "$htmode_5g" == "20" ]; then
      channels_5g="36,40,44,48,52,56,60,64,100,104,108,112,116,120,124,128,132,136,140"
    elif [[ "$htmode_5g" == "40" ]]; then
      channels_5g="36,44,52,60,100,108,116,124,132"
    else
      channels_5g="36,52,100,116"
    fi

    if [ "$htmode_2g" == "20" ]; then
    channels_2g="1,2,3,4,5,6,7,8,9,10,11,12,13"
    elif [[ "$htmode_2g" == "40" ]]; then
    channels_2g="1,2,3,4,5,6,7,8,9"
    fi
  ;;
  "ID")
    txpwr_2g=19
    txpwr_5g=15
    maxtxpwr_2g=19
    maxtxpwr_5g=15

    if [ "$htmode_5g" == "20" ]; then
      channels_5g="36,40,44,48,52,56,60,64,149,153,157,161"
    elif [[ "$htmode_5g" == "40" ]]; then
      channels_5g="36,44,52,60,149,157"
    else
      channels_5g="36,52,149"
    fi

    if [ "$htmode_2g" == "20" ]; then
      channels_2g="1,2,3,4,5,6,7,8,9,10,11,12,13"
    elif [[ "$htmode_2g" == "40" ]]; then
      channels_2g="1,2,3,4,5,6,7,8,9"
    fi
  ;;
  *)
    #others use us setting as standard
    txpwr_2g=22
    txpwr_5g=21
    maxtxpwr_2g=22
    maxtxpwr_5g=26
    ;;
  esac
  ;;
"EAP102"*|"OAP103"*)
  case $country_val in
  "CTICK")
    txpwr_2g=20
    txpwr_5g=8
    maxtxpwr_2g=20
    maxtxpwr_5g=26

    if [ "$htmode_5g" == "20" ]; then
        channels_5g="36,40,44,48,149,153,157,161,165"
    elif [[ "$htmode_5g" == "40" ]]; then
        channels_5g="36,44,149,157"
    else
        channels_5g="36,149"
    fi

    if [ "$htmode_2g" == "20" ]; then
        channels_2g="1,2,3,4,5,6,7,8,9,10,11,12,13"
    elif [[ "$htmode_2g" == "40" ]]; then
        channels_2g="1,2,3,4,5,6,7,8,9"
    fi
    ;;
  "ETSI"|"KR")
    txpwr_2g=12
    txpwr_5g=13
    maxtxpwr_2g=12
    maxtxpwr_5g=20

    if [ "$htmode_5g" == "20" ]; then
        channels_5g="36,40,44,48,52,56,60,64,100,104,108,112,116,132,136,140"
    elif [[ "$htmode_5g" == "40" ]]; then
        channels_5g="36,44,52,60,100,108,132"
    else
        channels_5g="36,52,100"
    fi

    if [ "$htmode_2g" == "20" ]; then
        channels_2g="1,2,3,4,5,6,7,8,9,10,11,12,13"
    elif [[ "$htmode_2g" == "40" ]]; then
        channels_2g="1,2,3,4,5,6,7,8,9"
    fi
    ;;
  "IC")
    txpwr_2g=20
    txpwr_5g=9
    maxtxpwr_2g=22
    maxtxpwr_5g=20

    if [ "$htmode_5g" == "20" ]; then
        channels_5g="36,40,44,48,149,153,157,161,165"
    elif [[ "$htmode_5g" == "40" ]]; then
        channels_5g="36,44,149,157"
    else
        channels_5g="36,149"
    fi

    if [ "$htmode_2g" == "20" ]; then
        channels_2g="1,2,3,4,5,6,7,8,9,10,11"
    elif [[ "$htmode_2g" == "40" ]]; then
        channels_2g="1,2,3,4,5,6,7"
    fi
    ;;
  "IN")
    txpwr_2g=18
    txpwr_5g=20
    maxtxpwr_2g=18
    maxtxpwr_5g=20

    if [ "$htmode_5g" == "20" ]; then
      channels_5g="36,40,44,48,149,153,157,161,165"
    elif [[ "$htmode_5g" == "40" ]]; then
      channels_5g="36,44,149,157"
    else
      channels_5g="36,149"
    fi

    if [ "$htmode_2g" == "20" ]; then
      channels_2g="1,2,3,4,5,6,7,8,9,10,11,12,13"
    elif [[ "$htmode_2g" == "40" ]]; then
      channels_2g="1,2,3,4,5,6,7,8,9"
    fi
    ;;
  "JP")
    txpwr_2g=13
    txpwr_5g=11
    maxtxpwr_2g=13
    maxtxpwr_5g=19

    if [ "$htmode_5g" == "20" ]; then
      channels_5g="36,40,44,48,52,56,60,64,100,104,108,112,116,120,124,128,132,136,140,144"
    elif [[ "$htmode_5g" == "40" ]]; then
      channels_5g="36,44,52,60,100,108,116,124,132,140"
    else
      channels_5g="36,52,100,116,132"
    fi

    if [ "$htmode_2g" == "20" ]; then
      channels_2g="1,2,3,4,5,6,7,8,9,10,11,12,13"
    elif [[ "$htmode_2g" == "40" ]]; then
      channels_2g="1,2,3,4,5,6,7,8,9"
    fi
    ;;
  "NCC")
    txpwr_2g=20
    txpwr_5g=22
    maxtxpwr_2g=20
    maxtxpwr_5g=26

    if [ "$htmode_5g" == "20" ]; then
      channels_5g="36,40,44,48,149,153,157,161,165"
    elif [[ "$htmode_5g" == "40" ]]; then
      channels_5g="36,44,149,157"
    else
      channels_5g="36,149"
    fi

    if [ "$htmode_2g" == "20" ]; then
      channels_2g="1,2,3,4,5,6,7,8,9,10,11"
    elif [[ "$htmode_2g" == "40" ]]; then
      channels_2g="1,2,3,4,5,6,7"
    fi
    ;;
  "PH")
    txpwr_2g=16
    txpwr_5g=14
    maxtxpwr_2g=16
    maxtxpwr_5g=14

    if [ "$htmode_5g" == "20" ]; then
      channels_5g="36,40,44,48,52,56,60,64,100,104,108,112,116,120,124,128,132,136,140,144,149,153,157,161,165"
    elif [[ "$htmode_5g" == "40" ]]; then
      channels_5g="36,44,52,60,100,108,116,124,132,140,149,157"
    else
      channels_5g="36,52,100,116,132,149"
    fi

    if [ "$htmode_2g" == "20" ]; then
      channels_2g="1,2,3,4,5,6,7,8,9,10,11,12,13"
    elif [[ "$htmode_2g" == "40" ]]; then
      channels_2g="1,2,3,4,5,6,7,8,9"
    fi
    ;;
  "TH")
    txpwr_2g=12
    txpwr_5g=13
    maxtxpwr_2g=12
    maxtxpwr_5g=20

    if [ "$htmode_5g" == "20" ]; then
      channels_5g="36,40,44,48,52,56,60,64,100,104,108,112,116,120,124,128,132,136,140,149,153,157,161,165"
    elif [[ "$htmode_5g" == "40" ]]; then
      channels_5g="36,44,52,60,100,108,116,124,132,149,157"
    else
      channels_5g="36,52,100,116,149"
    fi

    if [ "$htmode_2g" == "20" ]; then
      channels_2g="1,2,3,4,5,6,7,8,9,10,11,12,13"
    elif [[ "$htmode_2g" == "40" ]]; then
      channels_2g="1,2,3,4,5,6,7,8,9"
    fi
    ;;
  "FCC"|"US")
    #others use us setting as standard
    txpwr_2g=20
    txpwr_5g=15
    maxtxpwr_2g=20
    maxtxpwr_5g=26

    if [ "$htmode_5g" == "20" ]; then
      channels_5g="36,40,44,48,52,56,60,64,100,104,108,112,116,120,124,128,132,136,140,149,153,157,161,165"
    elif [[ "$htmode_5g" == "40" ]]; then
      channels_5g="36,44,52,60,100,108,116,124,132,149,157"
    else
      channels_5g="36,52,100,116,149"
    fi

    if [ "$htmode_2g" == "20" ]; then
      channels_2g="1,2,3,4,5,6,7,8,9,10,11"
    elif [[ "$htmode_2g" == "40" ]]; then
      channels_2g="1,2,3,4,5,6,7"
    fi
    ;;
  "VN")
    txpwr_2g=12
    txpwr_5g=13
    maxtxpwr_2g=12
    maxtxpwr_5g=20

    if [ "$htmode_5g" == "20" ]; then
      channels_5g="36,40,44,48,52,56,60,64,100,104,108,112,116,132,136,140"
    elif [[ "$htmode_5g" == "40" ]]; then
      channels_5g="36,44,52,60,100,108,132"
    else
      channels_5g="36,52,100"
    fi

    if [ "$htmode_2g" == "20" ]; then
    channels_2g="1,2,3,4,5,6,7,8,9,10,11,12,13"
    elif [[ "$htmode_2g" == "40" ]]; then
    channels_2g="1,2,3,4,5,6,7,8,9"
    fi
  ;;
  "ID")
    txpwr_2g=18
    txpwr_5g=13
    maxtxpwr_2g=18
    maxtxpwr_5g=13

    if [ "$htmode_5g" == "20" ]; then
      channels_5g="36,40,44,48,52,56,60,64,149,153,157,161"
    elif [[ "$htmode_5g" == "40" ]]; then
      channels_5g="36,44,52,60,149,157"
    else
      channels_5g="36,52,149"
    fi

    if [ "$htmode_2g" == "20" ]; then
      channels_2g="1,2,3,4,5,6,7,8,9,10,11,12,13"
    elif [[ "$htmode_2g" == "40" ]]; then
      channels_2g="1,2,3,4,5,6,7,8,9"
    fi
    ;;
  *)
    #others use us setting as standard
    txpwr_2g=20
    txpwr_5g=21
    maxtxpwr_2g=20
    maxtxpwr_5g=26
    ;;
  esac

  if [ "$MID" == "OAP103" -o "$MID" == "OAP103-BR" ]; then
    if [ "$country_val" == "BR" ]; then
      txpwr_2g=20
      txpwr_5g=24
      maxtxpwr_2g=20
      maxtxpwr_5g=24

      if [ "$htmode_5g" == "20" ]; then
        channels_5g="100,104,108,112,116,120,124,128,132,136,140,149,153,157,161,165"
      elif [[ "$htmode_5g" == "40" ]]; then
        channels_5g="100,108,116,124,132,140,149,157"
      elif [[ "$htmode_5g" == "80" ]]; then
        channels_5g="100,116,132,149"
      else
        channels_5g="100,116,132,149"
      fi

      if [ "$htmode_2g" == "20" ]; then
        channels_2g="1,2,3,4,5,6,7,8,9,10,11"
      elif [[ "$htmode_2g" == "40" ]]; then
        channels_2g="1,2,3,4,5,6,7,8,9"
      fi
    fi
  fi
  ;;
"EAP104"*)
  case $country_val in
  "JP")
    txpwr_2g=17
    txpwr_5g=12
    maxtxpwr_2g=17
    maxtxpwr_5g=19

    if [ "$htmode_5g" == "20" ]; then
      channels_5g="36,40,44,48,52,56,60,64,100,104,108,112,116,120,124,128,132,136,140,144"
    elif [ "$htmode_5g" == "40" ]; then
      channels_5g="36,44,52,60,100,108,116,124,132,140"
    elif [ "$htmode_5g" == "80" ]; then
      channels_5g="36,52,100,116,132"
    else #160
      channels_5g="36,100"
    fi

    if [ "$htmode_2g" == "20" ]; then
      channels_2g="1,2,3,4,5,6,7,8,9,10,11,12,13"
    elif [[ "$htmode_2g" == "40" ]]; then
      channels_2g="1,2,3,4,5,6,7,8,9"
    fi
    ;;

   "TH")
    txpwr_2g=15
    txpwr_5g=15
    maxtxpwr_2g=15
    maxtxpwr_5g=22

    if [ "$htmode_5g" == "20" ]; then
      channels_5g="36,40,44,48,52,56,60,64,100,104,108,112,116,120,124,128,132,136,140,149,153,157,161,165"
    elif [[ "$htmode_5g" == "40" ]]; then
      channels_5g="36,44,52,60,100,108,116,124,132,140,149,157"
    elif [ "$htmode_5g" == "80" ]; then
      channels_5g="36,52,100,116,132,149"
    else
      channels_5g="36,100"
    fi

    if [ "$htmode_2g" == "20" ]; then
      channels_2g="1,2,3,4,5,6,7,8,9,10,11,12,13"
    elif [[ "$htmode_2g" == "40" ]]; then
      channels_2g="1,2,3,4,5,6,7,8,9"
    fi
    ;;
  "IN")
    txpwr_2g=20
    txpwr_5g=23
    maxtxpwr_2g=20
    maxtxpwr_5g=23

    if [ "$htmode_5g" == "20" ]; then
        channels_5g="36,40,44,48,149,153,157,161,165"
    elif [[ "$htmode_5g" == "40" ]]; then
        channels_5g="36,44,149,157"
    else
        channels_5g="36,149"
    fi

    if [ "$htmode_2g" == "20" ]; then
        channels_2g="1,2,3,4,5,6,7,8,9,10,11,12,13"
    elif [[ "$htmode_2g" == "40" ]]; then
        channels_2g="1,2,3,4,5,6,7,8,9"
    fi
    ;;
  "AT"|"BE"|"BG"|"HR"|"CZ"|"CY"|"DK"|"EE"|"FI"|"FR"|"DE"|"GR"|"HU"|"IS"|"IE"|"IT"|"LV"|"LT"|"LI"|"LU"|"MT"|"NO"|"NL"|"PL"|"PT"|"RO"|"SK"|"SI"|"ES"|"SE"|"CH"|"TR"|"GB"|"KR")
    txpwr_2g=14
    txpwr_5g=16
    maxtxpwr_2g=14
    maxtxpwr_5g=23

    if [ "$htmode_5g" == "20" ]; then
      channels_5g="36,40,44,48,52,56,60,64,100,104,108,112,116,120,124,128,132,136,140"
    elif [ "$htmode_5g" == "40" ]; then
      channels_5g="36,44,52,60,100,108,116,124,132"
    elif [ "$htmode_5g" == "80" ]; then
      channels_5g="36,52,100,116"
    else #160
      channels_5g="36,100"
    fi

    if [ "$htmode_2g" == "20" ]; then
      channels_2g="1,2,3,4,5,6,7,8,9,10,11,12,13"
    elif [ "$htmode_2g" == "40" ]; then
      channels_2g="1,2,3,4,5,6,7,8,9"
    fi
    ;;
  *) #FCC, US and others
    #others use us setting as standard
    txpwr_2g=20
    txpwr_5g=16
    maxtxpwr_2g=20
    maxtxpwr_5g=23

    if [ "$htmode_5g" == "20" ]; then
      channels_5g="36,40,44,48,52,60,64,100,104,108,112,116,120,124,128,132,136,140,144,149,153,157,161,165"
    elif [ "$htmode_5g" == "40" ]; then
      channels_5g="36,44,52,60,100,108,116,124,132,140,149,157"
    elif [ "$htmode_5g" == "80" ]; then
      channels_5g="36,52,100,116,132,149"
    else
      channels_5g="36,100"
    fi

    if [ "$htmode_2g" == "20" ]; then
      channels_2g="1,2,3,4,5,6,7,8,9,10,11"
    elif [[ "$htmode_2g" == "40" ]]; then
      channels_2g="1,2,3,4,5,6,7"
    fi
    ;;
  esac
  ;;
*);;
esac

original_ch_5g="`uci get wireless.$section_name_5g.channel 2>/dev/null`"
original_ch_2g="`uci get wireless.$section_name_2g.channel 2>/dev/null`"
original_chs_5g="`uci get wireless.$section_name_5g.channels 2>/dev/null`"
original_chs_2g="`uci get wireless.$section_name_2g.channels 2>/dev/null`"

[ "$setup_wiz" = "1" ] || {
  # don't need migration when setup wizard is being used

  #channel:auto => all channels or some channels; specific channel => only one channel selected
  #channels: list of channels
  if [ "$original_ch_5g" == "" ] || [ "$original_ch_5g" == "auto" ]; then
    if [ "$original_chs_5g" != "" ]; then
      channels_5g="$original_chs_5g"
    fi
  else
    #one channel selected
    channel_5g="$original_ch_5g"
    channels_5g=""
  fi

  if [ "$original_ch_2g" == "" ] || [ "$original_ch_2g" == "auto" ]; then
    if [ "$original_chs_2g" != "" ]; then
      channels_2g="$original_chs_2g"
    fi
  else
    #one channel selected
    channel_2g="$original_ch_2g"
    channels_2g=""
  fi

  # migrate txpower from previous config
  original_txp_5g="`uci get wireless.$section_name_5g.txpower 2>/dev/null`"
  original_txp_2g="`uci get wireless.$section_name_2g.txpower 2>/dev/null`"

  if [ "$original_txp_5g" != "" ]; then
    txpwr_5g="$original_txp_5g"
  fi

  if [ "$original_txp_2g" != "" ]; then
    txpwr_2g="$original_txp_2g"
  fi
}

#can't get really data to set device
#txpower: default tx power
#max_txpwr: default max tx power for EAP101/EAP102/EAP104/OAP103, hw upper limit
#channels: set all channels to perform auto all channels
uci -q batch <<-EOF >/dev/null
  set wireless.$section_name_5g.txpower='$txpwr_5g'
  set wireless.$section_name_2g.txpower='$txpwr_2g'
  set wireless.$section_name_5g.max_txpwr='$maxtxpwr_5g'
  set wireless.$section_name_2g.max_txpwr='$maxtxpwr_2g'
  set wireless.$section_name_5g.channels='$channels_5g'
  set wireless.$section_name_2g.channels='$channels_2g'
  set wireless.$section_name_5g.channel='$channel_5g'
  set wireless.$section_name_2g.channel='$channel_2g'
EOF

uci commit wireless

exit 0

