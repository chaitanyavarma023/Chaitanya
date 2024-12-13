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
    ac_vo_acm=$(echo $DATA|jsonfilter -e @.Voice.acm) ; ac_vo_acm=${ac_vo_acm:=1}
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