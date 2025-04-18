#!/bin/sh

. /lib/acn/acn_functions.sh

MID="$(get_MID)"

CHANLIST_2G="1 2 3 4 5 6 7 8 9 10 11 12 13 14"
CHANLIST_5G="36 40 44 48 52 56 60 64 100 104 108 112 116 120 124 128 132 136 140 144 149 153 157 161 165"

usable_bw40_chan="5180 5220 5260 5300 5500 5540 5580 5620 5660 5700 5745 5785 5825"
usable_bw80_chan="5180 5260 5500 5580 5660 5745 5955"
usable_bw160_chan="5180 5500"

PHY_5G="phy#0"
PHY_2G="phy#1"

RADIO="$1"
COUNTRY="$2"

OUTPUT_FILE="/tmp/reg.json"

[ -n "$RADIO" -a -n "$COUNTRY" ] || {
    echo ""
    echo "Usage: $0 <radio> <country>"
    echo "         <radio>: 2.4 or 5"
    echo "       <country>: US or others"
    echo ""
    exit 1
}

custom_ETSI() {
  radio=$1
  mode=$2
  chan_num=$3

  if [ "$radio" == "5" ]; then
    [ "$mode" = "40" ] && {
      [ "$chan_num" = "140" ] && exclude_channel="1"

      # Refs#26173: Channel 116 should be hidden in 40MHz for EAP102 when Certification is CE
      if [ "$MID" == "EAP102" ]; then
        [ "$chan_num" = "116" ] && exclude_channel="1"
      fi
    }

    [ "$mode" = "80" ] && {
      [ "$chan_num" == "132" ] && exclude_channel="1"

      # Refs#26173: Channel 116 should be hidden in 80MHz for EAP102 when Certification is CE
      if [ "$MID" == "EAP102" ]; then
        [ "$chan_num" == "116" ] && exclude_channel="1"
      fi
    }
  fi
}

custom_CTICK() {
  radio=$1
  mode=$2
  chan_num=$3

  custom_ETSI $radio $mode $chan_num
}

custom_KR() {
  radio=$1
  mode=$2
  chan_num=$3

#  custom_ETSI $radio $mode $chan_num
  if [ "$radio" == "5" ]; then
    [ "$mode" = "40" ] && {
      # Refs#26173: Channel 116 should be hidden in 40MHz for EAP102 when Certification is CE
      if [ "$MID" == "EAP102" ]; then
        [ "$chan_num" = "116" ] && exclude_channel="1"
      fi
    }

    [ "$mode" = "80" ] && {
      # Refs#26173: Channel 116 should be hidden in 80MHz for EAP102 when Certification is CE
      if [ "$MID" == "EAP102" ]; then
        [ "$chan_num" == "116" ] && exclude_channel="1"
      fi
    }
  fi
}

custom_BR() {
  radio=$1
  mode=$2
  chan_num=$3

  if [ "$radio" == "5" -a "$mode" == "80" -a "$chan_num" == "132" ]; then
    exclude_channel="1"
  fi
}

custom_FCC() {
  radio=$1
  mode=$2
  chan_num=$3

  # Refs#26176: Fix channel list for EAP102 5G radio (FCC certification)
  if [ "$radio" == "5" ]; then
    [ "$mode" = "40" ] && {
      if [ "$MID" == "EAP102" ]; then
        [ "$chan_num" == "165" ] && exclude_channel="1"
      fi

      if [ "$MID" != "EAP104" ]; then
        [ "$chan_num" == "140" ] && exclude_channel="1"
      fi
    }

    [ "$mode" = "80" ] && {
      if [ "$MID" == "EAP102" ]; then
        [ "$chan_num" == "165" ] && exclude_channel="1"
      fi

      if [ "$MID" != "EAP104" ]; then
        [ "$chan_num" == "132" ] && exclude_channel="1"
      fi
    }
  fi
}

custom_TH() {
  radio=$1
  mode=$2
  chan_num=$3

  if [ "$radio" == "5" ]; then
    [ "$mode" = "40" ] && {
      if [ "$MID" == "EAP102" ]; then
        # Refs#26175: Channel 140 should be hidden in 40MHz for EAP102 when Certification is Thailand
        [ "$chan_num" = "140" ] && exclude_channel="1"
      fi
    }

    [ "$mode" = "80" ] && {
      if [ "$MID" == "EAP102" ]; then
        # Refs#26175: Channel 132 should be hidden in 80MHz for EAP102 when Certification is Thailand
        [ "$chan_num" == "132" ] && exclude_channel="1"
      fi
    }
  fi
}

print_json() {
    mode=$2
    #[ $mode == 160 ] && mode=80
    echo "  {"                    >> $OUTPUT_FILE
    echo '    "min":0,'           >> $OUTPUT_FILE
    echo '    "max":'$1','        >> $OUTPUT_FILE
    echo '    "mode":"'$mode'",'  >> $OUTPUT_FILE
    echo '    "freq":'$3','       >> $OUTPUT_FILE
    echo '    "chan":'$4','       >> $OUTPUT_FILE
    echo '    "dfs":'$5           >> $OUTPUT_FILE
    echo "  },"                   >> $OUTPUT_FILE
}

get_near_freq_2g(){
  local chan=0
  local freq1=0
  local freq2=0
  for chan in ${CHANLIST_2G}; do
    chan=$(($chan))
    freq1=$(( (($chan - 1) * 5) + 2412 ))
    freq2=$(( ($chan * 5) + 2412 ))
    if [ $freq1 -ge $1 ]; then
      freq=$freq1
      break
    fi
    if [ $freq1 -le $1 -a $freq2 -gt $1 ]; then
      freq=$freq1
      break
    fi
  done
}

get_near_freq_5g(){
  local chan=0
  local freq1=0
  local freq2=0
  for chan in ${CHANLIST_5G}; do
    chan=$(($chan))
    freq1=$(( ($chan * 5) + 5000 ))
    freq2=$(( (($chan + 1) * 5) + 5000 ))
    if [ $freq1 -ge $1 ]; then
      freq=$freq1
      break
    fi
    if [ $freq1 -le $1 -a $freq2 -gt $1 ]; then
      freq=$freq1
      break
    fi
  done
}

verify_channel() {
  radio="$1"
  freq="$2"
  mode="$3"
  is_valid_freq=""

  if [ "$radio" == "5" ]; then
    if [ "$mode" == "20" ]; then
      is_valid_freq="1"
    else
      if [ "$mode" == "40" ]; then
        valid_channel_list="${usable_bw40_chan}"
      elif [ "$mode" == "80" ]; then
        valid_channel_list="${usable_bw80_chan}"
      else
        valid_channel_list="${usable_bw160_chan}"
      fi
      is_valid_freq=$(echo "$valid_channel_list" | grep "$freq")
    fi
  fi

}

chan_list() {
  line_content="$1"
  radio="$2"

  [ "$line_content" == "" ] && return

  new_line_content=$(echo "$line_content" | sed 's/(//g' | sed 's/ //g' | sed 's/),/;/g' | sed 's/)//g')

  freq_range=$(echo "$new_line_content" | cut -d ';' -f 1 | sed 's/ @.*//g')
  first_freq=$(echo "$new_line_content" | awk -F '[;@,-]' '{print $1}')
  last_freq=$(echo "$new_line_content" | awk -F '[;@,-]' '{print $2}')
  last_freq=$(($last_freq - 10))

  max_power=$(echo "$new_line_content" | awk -F '[;@,-]' '{print $5}')
  mode=$(echo "$new_line_content" | awk -F '[;@,-]' '{print $3}')
  dfs=$(echo "$new_line_content" | grep 'DFS')

  if [ $first_freq -le 5000 -a "$radio" == "5" ]; then
    return
  fi

  if [ "$dfs" == "" ]; then
    dfs=false
  else
    dfs=true
  fi

  freq=$(($first_freq))
  if [ $freq -lt 5000 -a "$radio" == "2.4" ]; then
    # 2.4 GHz
    get_near_freq_2g $freq
    while [ $freq -le $last_freq ]; do
      chan_num=$(( (($freq - 2412) / 5) + 1 ))
      print_json $max_power $mode $freq $chan_num $dfs
      freq=$((freq + 5))
    done
  fi

  if [ $freq -ge 5000 -a "$radio" == "5" ]; then
    # 5 GHz
    # get_near_freq_5g $freq

    # while [ $freq -le $last_freq ]; do
    #   chan_num=$(( (($freq - 5000) / 5) ))
    #   verify_channel "$radio" "$freq" "$mode"
    #   if [ "$is_valid_freq" != "" ]; then
    #     print_json $max_power $mode $freq $chan_num $dfs
    #   fi
    #   freq=$((freq + 20))
    # done

    if [ "$mode" != "160" ]; then
      #20Mhz
      freq=$(($first_freq))
      mode="20"
      get_near_freq_5g $freq

      while [ $freq -le $last_freq ]; do
        chan_num=$(( (($freq - 5000) / 5) ))
        verify_channel "$radio" "$freq" "$mode"
        if [ "$is_valid_freq" != "" ]; then
          print_json $max_power $mode $freq $chan_num $dfs
        fi
        freq=$((freq + 20))
      done

      #40Mhz
      freq=$(($first_freq))
      mode="40"
      get_near_freq_5g $freq

      while [ $freq -le $last_freq ]; do
        exclude_channel=""
        chan_num=$(( (($freq - 5000) / 5) ))
        verify_channel "$radio" "$freq" "$mode"
        if [ "$is_valid_freq" != "" ]; then
          # check if the country is Vietnam or a European one
          if [ "$COUNTRY" == "VN" -o "$COUNTRY" == "AT" -o "$COUNTRY" == "BE" \
            -o "$COUNTRY" == "BG" -o "$COUNTRY" == "HR" -o "$COUNTRY" == "CZ" \
            -o "$COUNTRY" == "CY" -o "$COUNTRY" == "DK" -o "$COUNTRY" == "EE" \
            -o "$COUNTRY" == "FI" -o "$COUNTRY" == "FR" -o "$COUNTRY" == "DE" \
            -o "$COUNTRY" == "GR" -o "$COUNTRY" == "HU" -o "$COUNTRY" == "IS" \
            -o "$COUNTRY" == "IE" -o "$COUNTRY" == "IT" -o "$COUNTRY" == "LV" \
            -o "$COUNTRY" == "LT" -o "$COUNTRY" == "LI" -o "$COUNTRY" == "LU" \
            -o "$COUNTRY" == "MT" -o "$COUNTRY" == "NO" -o "$COUNTRY" == "NL" \
            -o "$COUNTRY" == "PL" -o "$COUNTRY" == "PT" -o "$COUNTRY" == "RO" \
            -o "$COUNTRY" == "SK" -o "$COUNTRY" == "SI" -o "$COUNTRY" == "ES" \
            -o "$COUNTRY" == "SE" -o "$COUNTRY" == "CH" -o "$COUNTRY" == "TR" \
            -o "$COUNTRY" == "GB" ]; then
            custom_ETSI $radio $mode $chan_num
          fi
          # check if the country is Australia or New Zealand
          if [ "$COUNTRY" == "AU" -o "$COUNTRY" == "NZ" ]; then
            custom_CTICK $radio $mode $chan_num
          fi
          if [ "$COUNTRY" == "KR" ]; then
            custom_KR $radio $mode $chan_num
          fi
          if [ "$COUNTRY" == "US" ]; then
            custom_FCC $radio $mode $chan_num
          fi
          if [ "$COUNTRY" == "TH" ]; then
            custom_TH $radio $mode $chan_num
          fi
          if [ "$exclude_channel" == "" ]; then
            print_json $max_power $mode $freq $chan_num $dfs
          fi
        fi
        freq=$((freq + 20))
      done

      #80Mhz
      freq=$(($first_freq))
      mode="80"
      get_near_freq_5g $freq

      while [ $freq -le $last_freq ]; do
        exclude_channel=""
        chan_num=$(( (($freq - 5000) / 5) ))
        verify_channel "$radio" "$freq" "$mode"
        if [ "$is_valid_freq" != "" ]; then
          # check if the country is Vietnam or a European one
          if [ "$COUNTRY" == "VN" -o "$COUNTRY" == "AT" -o "$COUNTRY" == "BE" \
            -o "$COUNTRY" == "BG" -o "$COUNTRY" == "HR" -o "$COUNTRY" == "CZ" \
            -o "$COUNTRY" == "CY" -o "$COUNTRY" == "DK" -o "$COUNTRY" == "EE" \
            -o "$COUNTRY" == "FI" -o "$COUNTRY" == "FR" -o "$COUNTRY" == "DE" \
            -o "$COUNTRY" == "GR" -o "$COUNTRY" == "HU" -o "$COUNTRY" == "IS" \
            -o "$COUNTRY" == "IE" -o "$COUNTRY" == "IT" -o "$COUNTRY" == "LV" \
            -o "$COUNTRY" == "LT" -o "$COUNTRY" == "LI" -o "$COUNTRY" == "LU" \
            -o "$COUNTRY" == "MT" -o "$COUNTRY" == "NO" -o "$COUNTRY" == "NL" \
            -o "$COUNTRY" == "PL" -o "$COUNTRY" == "PT" -o "$COUNTRY" == "RO" \
            -o "$COUNTRY" == "SK" -o "$COUNTRY" == "SI" -o "$COUNTRY" == "ES" \
            -o "$COUNTRY" == "SE" -o "$COUNTRY" == "CH" -o "$COUNTRY" == "TR" \
            -o "$COUNTRY" == "GB" ]; then
            custom_ETSI $radio $mode $chan_num
          fi
          # check if the country is Australia or New Zealand
          if [ "$COUNTRY" == "AU" -o "$COUNTRY" == "NZ" ]; then
            custom_CTICK $radio $mode $chan_num
          fi
          if [ "$COUNTRY" == "KR" ]; then
            custom_KR $radio $mode $chan_num
          fi
          # check if the country is Brazil
          if [ "$COUNTRY" == "BR" ]; then
            custom_BR $radio $mode $chan_num
          fi
          if [ "$COUNTRY" == "US" ]; then
            custom_FCC $radio $mode $chan_num
          fi
          if [ "$COUNTRY" == "TH" ]; then
            custom_TH $radio $mode $chan_num
          fi
          # check if any channel need to be excluded
          if [ "$exclude_channel" == "" ]; then
            print_json $max_power $mode $freq $chan_num $dfs
          fi
        fi
        freq=$((freq + 20))
      done
    else
      #160Mhz
      freq=$(($first_freq))
      mode="160"
      get_near_freq_5g $freq

      while [ $freq -le $last_freq ]; do
        exclude_channel=""
        chan_num=$(( (($freq - 5000) / 5) ))
        verify_channel "$radio" "$freq" "$mode"
        if [ "$is_valid_freq" != "" ]; then
          # check if the country is Vietnam or a European one
          if [ "$COUNTRY" == "VN" -o "$COUNTRY" == "AT" -o "$COUNTRY" == "BE" \
            -o "$COUNTRY" == "BG" -o "$COUNTRY" == "HR" -o "$COUNTRY" == "CZ" \
            -o "$COUNTRY" == "CY" -o "$COUNTRY" == "DK" -o "$COUNTRY" == "EE" \
            -o "$COUNTRY" == "FI" -o "$COUNTRY" == "FR" -o "$COUNTRY" == "DE" \
            -o "$COUNTRY" == "GR" -o "$COUNTRY" == "HU" -o "$COUNTRY" == "IS" \
            -o "$COUNTRY" == "IE" -o "$COUNTRY" == "IT" -o "$COUNTRY" == "LV" \
            -o "$COUNTRY" == "LT" -o "$COUNTRY" == "LI" -o "$COUNTRY" == "LU" \
            -o "$COUNTRY" == "MT" -o "$COUNTRY" == "NO" -o "$COUNTRY" == "NL" \
            -o "$COUNTRY" == "PL" -o "$COUNTRY" == "PT" -o "$COUNTRY" == "RO" \
            -o "$COUNTRY" == "SK" -o "$COUNTRY" == "SI" -o "$COUNTRY" == "ES" \
            -o "$COUNTRY" == "SE" -o "$COUNTRY" == "CH" -o "$COUNTRY" == "TR" \
            -o "$COUNTRY" == "GB" ]; then
            custom_ETSI $radio $mode $chan_num
          fi
          # check if the country is Australia or New Zealand
          if [ "$COUNTRY" == "AU" -o "$COUNTRY" == "NZ" ]; then
            custom_CTICK $radio $mode $chan_num
          fi
          if [ "$COUNTRY" == "KR" ]; then
            custom_KR $radio $mode $chan_num
          fi
          # check if the country is Brazil
          if [ "$COUNTRY" == "BR" ]; then
            custom_BR $radio $mode $chan_num
          fi
          if [ "$COUNTRY" == "US" ]; then
            custom_FCC $radio $mode $chan_num
          fi
          # check if any channel need to be excluded
          if [ "$exclude_channel" == "" ]; then
            print_json $max_power $mode $freq $chan_num $dfs
          fi
        fi
        freq=$((freq + 20))
      done
    fi

  fi
}


is_section=false
is_valid_freq=""
rm -f $OUTPUT_FILE

iw reg get | while read line; do
  # reading each line
  start_point=false
  if [ "$RADIO" == "2.4" ]; then
    phy_name="$PHY_2G"
  else
    phy_name="$PHY_5G"
  fi

  if [ "$(echo "$line" | grep phy#)" != "" ]; then
    start="1"
    start_point=true
    [ "$(echo "$line" | grep "$phy_name")" != "" ] && is_section=true
  fi

  if [ $is_section == true ]; then
    if [ "${start}" == "1" ]; then
      if [ "$(echo "$line" | grep phy#)" != "" -o "$(echo "$line" | grep "country")" != "" ]; then

        if [ $start_point == true ]; then
          echo "["
          start_point=false
        fi
      else
        chan_list "$line" "$RADIO"
      fi
    fi
    [ "$line" == "" ] && {
      #remove last ","
      sed -i '$ s/,$//' $OUTPUT_FILE
      echo "]" >> $OUTPUT_FILE
      cat $OUTPUT_FILE
      is_section=false
    }
  fi

done
rm -f $OUTPUT_FILE
