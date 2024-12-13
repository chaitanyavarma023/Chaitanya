#!/bin/sh

###############################################################################################
# JSON Data - '{"wlan": "WLAN1", "wmm": "0/1", "Background": {"aifs": "7", "cwmin": "4", "cwmax": "10", "txop": "0", "acm": "0"}, "Besteffort": {"aifs": "3", "cwmin": "4", "cwmax": "10", "txop": "0", "acm": "0"}, "Video": {"aifs": "2", "cwmin": "3", "cwmax": "4", "txop": "94", "acm": "0"}, "Voice": {"aifs": "2", "cwmin": "2", "cwmax": "3", "txop": "47", "acm": "0"},"RevisionNo":365,"DeviceRevisionNo":""}'
###############################################################################################

model=$(cat /etc/model)

# Define the bandwidth threshold (in kbps)
max_bandwidth=1000  # Maximum allowable bandwidth
threshold=800  # Threshold after which new calls will be blocked

# Function to check bandwidth usage
check_bandwidth_usage() {
    current_bandwidth=$(ifstat -i wlan0 1 1 | awk 'NR==3 {print $1}')  # Get current bandwidth usage in kbps
    echo "Current Bandwidth: $current_bandwidth kbps"
    if [ "$current_bandwidth" -gt "$threshold" ]; then
        echo "Bandwidth limit exceeded. Blocking new calls."
        return 1
    else
        echo "Sufficient bandwidth. Allowing new call."
        return 0
    fi
}

# Logic to process new call request
process_call_request() {
    if check_bandwidth_usage; then
        # Allow the call and set WMM configuration
        configure_wmm "$1"
    else
        # Block the call due to insufficient bandwidth
        echo "New call blocked due to low bandwidth."
        exit 1
    fi
}

configure_wmm() {
    DATA="$(echo $1|sed "s/null/0/g")"
    WLAN=$(echo $DATA|jsonfilter -e @.wlan) ; WLAN=${WLAN:=''}
    wmm=$(echo $DATA|jsonfilter -e @.wmm) ; wmm=${wmm:=1}
    ac_bk_aifs=$(echo $DATA|jsonfilter -e @.Background.aifs) ; ac_bk_aifs=${ac_bk_aifs:=7}
    ac_bk_cwmin=$(echo $DATA|jsonfilter -e @.Background.cwmin) ; ac_bk_cwmin=${ac_bk_cwmin:=4}
    ac_bk_cwmax=$(echo $DATA|jsonfilter -e @.Background.cwmax) ; ac_bk_cwmax=${ac_bk_cwmax:=10}
    ac_bk_txop=$(echo $DATA|jsonfilter -e @.Background.txop) ; ac_bk_txop=${ac_bk_txop:=0}
    ac_bk_acm=$(echo $DATA|jsonfilter -e @.Background.acm) ; ac_bk_acm=${ac_bk_acm:=0}
    ac_be_aifs=$(echo $DATA|jsonfilter -e @.Besteffort.aifs) ; ac_be_aifs=${ac_be_aifs:=3}
    ac_be_cwmin=$(echo $DATA|jsonfilter -e @.Besteffort.cwmin) ; ac_be_cwmin=${ac_be_cwmin:=4}
    ac_be_cwmax=$(echo $DATA|jsonfilter -e @.Besteffort.cwmax) ; ac_be_cwmax=${ac_be_cwmax:=10}
    ac_be_txop=$(echo $DATA|jsonfilter -e @.Besteffort.txop) ; ac_be_txop=${ac_be_txop:=0}
    ac_be_acm=$(echo $DATA|jsonfilter -e @.Besteffort.acm) ; ac_be_acm=${ac_be_acm:=0}
    ac_vi_aifs=$(echo $DATA|jsonfilter -e @.Video.aifs) ; ac_vi_aifs=${ac_vi_aifs:=2}
    ac_vi_cwmin=$(echo $DATA|jsonfilter -e @.Video.cwmin) ; ac_vi_cwmin=${ac_vi_cwmin:=3}
    ac_vi_cwmax=$(echo $DATA|jsonfilter -e @.Video.cwmax) ; ac_vi_cwmax=${ac_vi_cwmax:=4}
    ac_vi_txop=$(echo $DATA|jsonfilter -e @.Video.txop) ; ac_vi_txop=${ac_vi_txop:=94}
    ac_vi_acm=$(echo $DATA|jsonfilter -e @.Video.acm) ; ac_vi_acm=${ac_vi_acm:=0}
    ac_vo_aifs=$(echo $DATA|jsonfilter -e @.Voice.aifs) ; ac_vo_aifs=${ac_vo_aifs:=2}
    ac_vo_cwmin=$(echo $DATA|jsonfilter -e @.Voice.cwmin) ; ac_vo_cwmin=${ac_vo_cwmin:=2}
    ac_vo_cwmax=$(echo $DATA|jsonfilter -e @.Voice.cwmax) ; ac_vo_cwmax=${ac_vo_cwmax:=3}
    ac_vo_txop=$(echo $DATA|jsonfilter -e @.Voice.txop) ; ac_vo_txop=${ac_vo_txop:=47}
    ac_vo_acm=$(echo $DATA|jsonfilter -e @.Voice.acm) ; ac_vo_acm=${ac_vo_acm:=0}
    RevisionNo=$(echo $DATA | jsonfilter -e '@["RevisionNo"]'); RevisionNo=${RevisionNo:-0}
    DeviceRevisionNo=$(echo $DATA | jsonfilter -e '@["DeviceRevisionNo"]'); DeviceRevisionNo=${DeviceRevisionNo:-0}

    for wlan in $(echo $WLAN|tr ',' '\n')
    do
        for pos in $(uci show wireless|grep "\.name='"$wlan"_"|cut -f 2 -d .|sort -u)
        do
            uci -q del wireless."$pos".wmm
            uci -q del wireless."$pos".wmm_ac_bk_aifs
            uci -q del wireless."$pos".wmm_ac_bk_cwmin
            uci -q del wireless."$pos".wmm_ac_bk_cwmax
            uci -q del wireless."$pos".wmm_ac_bk_txop_limit
            uci -q del wireless."$pos".wmm_ac_bk_acm
            uci -q del wireless."$pos".wmm_ac_be_aifs
            uci -q del wireless."$pos".wmm_ac_be_cwmin
            uci -q del wireless."$pos".wmm_ac_be_cwmax
            uci -q del wireless."$pos".wmm_ac_be_txop_limit
            uci -q del wireless."$pos".wmm_ac_be_acm
            uci -q del wireless."$pos".wmm_ac_vi_aifs
            uci -q del wireless."$pos".wmm_ac_vi_cwmin
            uci -q del wireless."$pos".wmm_ac_vi_cwmax
            uci -q del wireless."$pos".wmm_ac_vi_txop_limit
            uci -q del wireless."$pos".wmm_ac_vi_acm
            uci -q del wireless."$pos".wmm_ac_vo_aifs
            uci -q del wireless."$pos".wmm_ac_vo_cwmin
            uci -q del wireless."$pos".wmm_ac_vo_cwmax
            uci -q del wireless."$pos".wmm_ac_vo_txop_limit
            uci -q del wireless."$pos".wmm_ac_vo_acm
            if [ "$wmm" == '1' ]; then
                uci -q set wireless."$pos".wmm="$wmm"
                uci -q set wireless."$pos".wmm_ac_bk_aifs="$ac_bk_aifs"
                uci -q set wireless."$pos".wmm_ac_bk_cwmin="$ac_bk_cwmin"
                uci -q set wireless."$pos".wmm_ac_bk_cwmax="$ac_bk_cwmax"
                uci -q set wireless."$pos".wmm_ac_bk_txop_limit="$ac_bk_txop"
                uci -q set wireless."$pos".wmm_ac_bk_acm="$ac_bk_acm"
                uci -q set wireless."$pos".wmm_ac_be_aifs="$ac_be_aifs"
                uci -q set wireless."$pos".wmm_ac_be_cwmin="$ac_be_cwmin"
                uci -q set wireless."$pos".wmm_ac_be_cwmax="$ac_be_cwmax"
                uci -q set wireless."$pos".wmm_ac_be_txop_limit="$ac_be_txop"
                uci -q set wireless."$pos".wmm_ac_be_acm="$ac_be_acm"
                uci -q set wireless."$pos".wmm_ac_vi_aifs="$ac_vi_aifs"
                uci -q set wireless."$pos".wmm_ac_vi_cwmin="$ac_vi_cwmin"
                uci -q set wireless."$pos".wmm_ac_vi_cwmax="$ac_vi_cwmax"
                uci -q set wireless."$pos".wmm_ac_vi_txop_limit="$ac_vi_txop"
                uci -q set wireless."$pos".wmm_ac_vi_acm="$ac_vi_acm"
                uci -q set wireless."$pos".wmm_ac_vo_aifs="$ac_vo_aifs"
                uci -q set wireless."$pos".wmm_ac_vo_cwmin="$ac_vo_cwmin"
                uci -q set wireless."$pos".wmm_ac_vo_cwmax="$ac_vo_cwmax"
                uci -q set wireless."$pos".wmm_ac_vo_txop_limit="$ac_vo_txop"
                uci -q set wireless."$pos".wmm_ac_vo_acm="$ac_vo_acm"
            fi
        done
    done
    uci commit wireless
}

# Entry point of the script
input_data=$1

# Process call request with bandwidth check and WMM configuration
process_call_request "$input_data"
