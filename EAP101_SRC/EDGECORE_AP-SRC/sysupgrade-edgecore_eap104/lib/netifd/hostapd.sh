. /lib/functions/network.sh
. /lib/functions.sh

country_DEFALT="0"
country_FCC="1"
country_DE="2"

country_idx="${country_DEFALT}"

wpa_supplicant_add_rate() {
	local var="$1"
	local val="$(($2 / 1000))"
	local sub="$((($2 / 100) % 10))"
	append $var "$val" ","
	[ $sub -gt 0 ] && append $var "."
}

hostapd_add_rate() {
	local var="$1"
	local val="$(($2 / 100))"
	append $var "$val" " "
}

hostapd_append_wep_key() {
	local var="$1"

	wep_keyidx=0
	set_default key 1
	case "$key" in
		[1234])
			for idx in 1 2 3 4; do
				local zidx
				zidx=$(($idx - 1))
				json_get_var ckey "key${idx}"
				[ -n "$ckey" ] && \
					append $var "wep_key${zidx}=$(prepare_key_wep "$ckey")" "$N$T"
			done
			wep_keyidx=$((key - 1))
		;;
		*)
			append $var "wep_key0=$(prepare_key_wep "$key")" "$N$T"
		;;
	esac
}

hostapd_append_wpa_key_mgmt() {
	local auth_type_l="$(echo $auth_type | tr 'a-z' 'A-Z')"

	case "$auth_type" in
		psk|eap)
			append wpa_key_mgmt "WPA-$auth_type_l"
			[ "${ieee80211r:-0}" -gt 0 ] && append wpa_key_mgmt "FT-${auth_type_l}"
			[ "${ieee80211w:-0}" -gt 0 ] && append wpa_key_mgmt "WPA-${auth_type_l}-SHA256"
		;;
		eap192)
			append wpa_key_mgmt "WPA-EAP-SUITE-B-192"
			# for https://redmine.ignitenet.com/issues/21811
			# append wpa_key_mgmt "WPA-EAP-SHA256"
			# [ "${ieee80211r:-0}" -gt 0 ] && append wpa_key_mgmt "FT-EAP"
		;;
		eap-eap256)
			append wpa_key_mgmt "WPA-EAP"
			append wpa_key_mgmt "WPA-EAP-SHA256"
			[ "${ieee80211r:-0}" -gt 0 ] && append wpa_key_mgmt "FT-EAP"
		;;
		eap256)
			append wpa_key_mgmt "WPA-EAP-SHA256"
			[ "${ieee80211r:-0}" -gt 0 ] && append wpa_key_mgmt "FT-EAP"
		;;
		sae)
			append wpa_key_mgmt "SAE"
			[ "${ieee80211r:-0}" -gt 0 ] && append wpa_key_mgmt "FT-SAE"
		;;
		psk-sae)
			append wpa_key_mgmt "WPA-PSK"
			[ "${ieee80211r:-0}" -gt 0 ] && append wpa_key_mgmt "FT-PSK"
			[ "${ieee80211w:-0}" -gt 0 ] && append wpa_key_mgmt "WPA-PSK-SHA256"
			append wpa_key_mgmt "SAE"
			[ "${ieee80211r:-0}" -gt 0 ] && append wpa_key_mgmt "FT-SAE"
		;;
		owe)
			append wpa_key_mgmt "OWE"
		;;
	esac

	[ "$auth_osen" = "1" ] && append wpa_key_mgmt "OSEN"
}

hostapd_add_log_config() {
	config_add_boolean \
		log_80211 \
		log_8021x \
		log_radius \
		log_wpa \
		log_driver \
		log_iapp \
		log_mlme

	config_add_int log_level
}

hostapd_common_add_device_config() {
	config_add_array basic_rate
	config_add_array supported_rates
	config_add_string beacon_rate

	config_add_string country country3
	config_add_boolean country_ie doth
	config_add_boolean spectrum_mgmt_required
	config_add_int local_pwr_constraint
	config_add_int maxassoc
	config_add_string require_mode
	config_add_boolean legacy_rates
	config_add_int cell_density
	config_add_int rts_threshold
	config_add_int rssi_reject_assoc_rssi
	config_add_int rssi_ignore_probe_request
	config_add_int maxassoc

	config_add_string acs_chan_bias
	config_add_array hostapd_options

	config_add_int airtime_mode

	config_add_boolean multiple_bssid rnr_beacon he_co_locate ema
	hostapd_add_log_config

	config_add_string 'wme_0:string' 'wme_1:string' 'wme_2:string' 'wme_3:string'
}

hostapd_prepare_device_config() {
	local config="$1"
	local driver="$2"

	local base_cfg=

	json_get_vars country country3 country_ie beacon_int:100 dtim_period:2 doth require_mode legacy_rates \
		acs_chan_bias local_pwr_constraint spectrum_mgmt_required airtime_mode cell_density \
		rts_threshold beacon_rate rssi_reject_assoc_rssi rssi_ignore_probe_request maxassoc \
		multiple_bssid he_co_locate rnr_beacon ema wme_0 wme_1 wme_2 wme_3

	hostapd_set_log_options base_cfg

	set_default country_ie 1
	set_default spectrum_mgmt_required 0
	set_default doth 1
	set_default legacy_rates 1
	set_default airtime_mode 0
	set_default cell_density 1
	set_default he_co_locate 0
	set_default rnr_beacon 0
	set_default multiple_bssid 0
	set_default ema 0
	set_default maxassoc 0

	[ -n "$country" ] && {
		default_countrycode_change_to_FCC
		if [ "$country_idx" == "$country_FCC" ]; then
			append base_cfg "country_code=US" "$N"
		elif [ "$country_idx" == "$country_DE" ]; then
			append base_cfg "country_code=DE" "$N"
		else
			append base_cfg "country_code=$country" "$N"
		fi
		[ -n "$country3" ] && append base_cfg "country3=$country3" "$N"

		[ "$country_ie" -gt 0 ] && {
			append base_cfg "ieee80211d=1" "$N"
			[ -n "$local_pwr_constraint" ] && append base_cfg "local_pwr_constraint=$local_pwr_constraint" "$N"
			[ "$spectrum_mgmt_required" -gt 0 ] && append base_cfg "spectrum_mgmt_required=$spectrum_mgmt_required" "$N"
		}
		[ "$hwmode" = "a" -a "$doth" -gt 0 ] && append base_cfg "ieee80211h=1" "$N"
	}

	[ "$maxassoc" -gt 0 ] && append base_cfg "iface_max_num_sta=$maxassoc" "$N"
	[ -n "$acs_chan_bias" ] && append base_cfg "acs_chan_bias=$acs_chan_bias" "$N"

	local brlist= br
	json_get_values basic_rate_list basic_rate
	local rlist= r
	json_get_values rate_list supported_rates

	[ -n "$hwmode" ] && append base_cfg "hw_mode=$hwmode" "$N"
	if [ "$hwmode" = "g" ] || [ "$hwmode" = "a" ]; then
		[ -n "$require_mode" ] && legacy_rates=0
		case "$require_mode" in
			n) append base_cfg "require_ht=1" "$N";;
			ac) append base_cfg "require_vht=1" "$N";;
		esac
	fi
	case "$hwmode" in
		b)
			if [ "$cell_density" -eq 1 ]; then
				set_default rate_list "5500 11000"
				set_default basic_rate_list "5500 11000"
			elif [ "$cell_density" -ge 2 ]; then
				set_default rate_list "11000"
				set_default basic_rate_list "11000"
			fi
		;;
		g)
			if [ "$cell_density" -eq 0 ] || [ "$cell_density" -eq 1 ]; then
				if [ "$legacy_rates" -eq 0 ]; then
					set_default rate_list "6000 9000 12000 18000 24000 36000 48000 54000"
					set_default basic_rate_list "6000 12000 24000"
				elif [ "$legacy_rates" -eq 1 ]; then
					set_default rate_list "5500 6000 9000 11000 12000 18000 24000 36000 48000 54000"
					set_default basic_rate_list "5500 11000"
				fi
			elif [ "$cell_density" -ge 3 ] && [ "$legacy_rates" -ne 0 ] || [ "$cell_density" -eq 2 ]; then
				if [ "$legacy_rates" -eq 0 ]; then
					set_default rate_list "12000 18000 24000 36000 48000 54000"
					set_default basic_rate_list "12000 24000"
				else
					set_default rate_list "11000 12000 18000 24000 36000 48000 54000"
					set_default basic_rate_list "11000"
				fi
			elif [ "$cell_density" -ge 3 ]; then
				set_default rate_list "24000 36000 48000 54000"
				set_default basic_rate_list "24000"
			fi
		;;
		a)
			if [ "$cell_density" -eq 1 ]; then
				set_default rate_list "6000 9000 12000 18000 24000 36000 48000 54000"
				set_default basic_rate_list "6000 12000 24000"
			elif [ "$cell_density" -eq 2 ]; then
				set_default rate_list "12000 18000 24000 36000 48000 54000"
				set_default basic_rate_list "12000 24000"
			elif [ "$cell_density" -ge 3 ]; then
				set_default rate_list "24000 36000 48000 54000"
				set_default basic_rate_list "24000"
			fi
		;;
	esac

	for r in $rate_list; do
		hostapd_add_rate rlist "$r"
	done

	for br in $basic_rate_list; do
		hostapd_add_rate brlist "$br"
	done

	[ -n "$rssi_reject_assoc_rssi" ] && append base_cfg "rssi_reject_assoc_rssi=$rssi_reject_assoc_rssi" "$N"
	[ -n "$rssi_ignore_probe_request" ] && append base_cfg "rssi_ignore_probe_request=$rssi_ignore_probe_request" "$N"
	[ -n "$beacon_rate" ] && append base_cfg "beacon_rate=$beacon_rate" "$N"
	[ -n "$rlist" ] && append base_cfg "supported_rates=$rlist" "$N"
	[ -n "$brlist" ] && append base_cfg "basic_rates=$brlist" "$N"
	append base_cfg "beacon_int=$beacon_int" "$N"
	[ -n "$rts_threshold" ] && append base_cfg "rts_threshold=$rts_threshold" "$N"
	append base_cfg "dtim_period=$dtim_period" "$N"
	[ "$airtime_mode" -gt 0 ] && append base_cfg "airtime_mode=$airtime_mode" "$N"
	[ -n "$maxassoc" ] && append base_cfg "iface_max_num_sta=$maxassoc" "$N"
	[ "$rnr_beacon" -gt 0 ] && append base_cfg "rnr_beacon=$rnr_beacon" "$N"
	[ "$he_co_locate" -gt 0 ] && append base_cfg "he_co_locate=$he_co_locate" "$N"
	[ "$multiple_bssid" -gt 0 ] && append base_cfg "multiple_bssid=$multiple_bssid" "$N"
	[ "$ema" -gt 0 ] && append base_cfg "ema=$ema" "$N"

	json_get_values opts hostapd_options
	for val in $opts; do
		append base_cfg "$val" "$N"
	done

	# BestEffort wme_0
	[ -n "$wme_0" ] && {
		wmm_ac_be_cwmin=$(echo $wme_0 | cut -d" " -f5)
		wmm_ac_be_cwmax=$(echo $wme_0 | cut -d" " -f6)
		wmm_ac_be_aifs=$(echo $wme_0 | cut -d" " -f7)
		wmm_ac_be_txop_limit=$(echo $wme_0 | cut -d" " -f8)

		append base_cfg "wmm_ac_be_cwmin=$wmm_ac_be_cwmin" "$N"
		append base_cfg "wmm_ac_be_cwmax=$wmm_ac_be_cwmax" "$N"
		append base_cfg "wmm_ac_be_aifs=$wmm_ac_be_aifs" "$N"
		append base_cfg "wmm_ac_be_txop_limit=$(( wmm_ac_be_txop_limit/32 ))" "$N"
	}

	# BackGround wme_1
	[ -n "$wme_1" ] && {
		wmm_ac_bk_cwmin=$(echo $wme_1 | cut -d" " -f5)
		wmm_ac_bk_cwmax=$(echo $wme_1 | cut -d" " -f6)
		wmm_ac_bk_aifs=$(echo $wme_1 | cut -d" " -f7)
		wmm_ac_bk_txop_limit=$(echo $wme_1 | cut -d" " -f8)

		append base_cfg "wmm_ac_bk_cwmin=$wmm_ac_bk_cwmin" "$N"
		append base_cfg "wmm_ac_bk_cwmax=$wmm_ac_bk_cwmax" "$N"
		append base_cfg "wmm_ac_bk_aifs=$wmm_ac_bk_aifs" "$N"
		append base_cfg "wmm_ac_bk_txop_limit=$(( wmm_ac_bk_txop_limit/32 ))" "$N"
	}

	# Video wme_2
	[ -n "$wme_2" ] && {
		wmm_ac_vi_cwmin=$(echo $wme_2 | cut -d" " -f5)
		wmm_ac_vi_cwmax=$(echo $wme_2 | cut -d" " -f6)
		wmm_ac_vi_aifs=$(echo $wme_2 | cut -d" " -f7)
		wmm_ac_vi_txop_limit=$(echo $wme_2 | cut -d" " -f8)

		append base_cfg "wmm_ac_vi_cwmin=$wmm_ac_vi_cwmin" "$N"
		append base_cfg "wmm_ac_vi_cwmax=$wmm_ac_vi_cwmax" "$N"
		append base_cfg "wmm_ac_vi_aifs=$wmm_ac_vi_aifs" "$N"
		append base_cfg "wmm_ac_vi_txop_limit=$(( wmm_ac_vi_txop_limit/32 ))" "$N"
	}

	# Voice wme_3
	[ -n "$wme_3" ] && {
		wmm_ac_vo_cwmin=$(echo $wme_3 | cut -d" " -f5)
		wmm_ac_vo_cwmax=$(echo $wme_3 | cut -d" " -f6)
		wmm_ac_vo_aifs=$(echo $wme_3 | cut -d" " -f7)
		wmm_ac_vo_txop_limit=$(echo $wme_3 | cut -d" " -f8)

		append base_cfg "wmm_ac_vo_cwmin=$wmm_ac_vo_cwmin" "$N"
		append base_cfg "wmm_ac_vo_cwmax=$wmm_ac_vo_cwmax" "$N"
		append base_cfg "wmm_ac_vo_aifs=$wmm_ac_vo_aifs" "$N"
		append base_cfg "wmm_ac_vo_txop_limit=$(( wmm_ac_vo_txop_limit/32 ))" "$N"
	}

	cat > "$config" <<EOF
driver=$driver
$base_cfg
EOF
}

hostapd_common_add_bss_config() {
	config_add_string 'bssid:macaddr' 'ssid:string'
	config_add_boolean wds wmm uapsd hidden utf8_ssid

	config_add_int maxassoc max_inactivity
	config_add_boolean disassoc_low_ack isolate short_preamble skip_inactivity_poll \
		radius_mac_acl radsec_enable

	config_add_int \
		wep_rekey eap_reauth_period \
		wpa_group_rekey wpa_pair_rekey wpa_master_rekey
	config_add_boolean wpa_strict_rekey
	config_add_boolean wpa_disable_eapol_key_retries

	config_add_boolean tdls_prohibit

	config_add_boolean rsn_preauth auth_cache
	config_add_int ieee80211w
	config_add_int eapol_version

	config_add_string 'auth_server:host' 'server:host'
	config_add_string auth_secret key
	config_add_int 'auth_port:port' 'port:port'

	config_add_string 'auth_server2:host2'
	config_add_string auth_secret2
	config_add_int 'auth_port2:port2'

	config_add_string acct_server acct_server2
	config_add_string acct_secret acct_secret2
	config_add_int acct_port acct_port2
	config_add_int acct_interval

	config_add_int bss_load_update_period chan_util_avg_period

	config_add_string dae_client
	config_add_string dae_secret
	config_add_int dae_port
	config_add_boolean dae_enable

	config_add_string nasid
	config_add_string ownip
	config_add_string radius_client_addr
	config_add_string iapp_interface
	config_add_string eap_type ca_cert client_cert identity anonymous_identity auth priv_key priv_key_pwd
	config_add_boolean ca_cert_usesystem ca_cert2_usesystem
	config_add_string subject_match subject_match2
	config_add_array altsubject_match altsubject_match2
	config_add_array domain_match domain_match2 domain_suffix_match domain_suffix_match2
	config_add_string ieee80211w_mgmt_cipher

	config_add_int dynamic_vlan vlan_naming vlan_no_bridge
	config_add_string vlan_tagged_interface vlan_bridge
	config_add_string vlan_file

	config_add_string 'key1:wepkey' 'key2:wepkey' 'key3:wepkey' 'key4:wepkey' 'password:wpakey'

	config_add_string sae_password

	config_add_string wpa_psk_file

	config_add_int multi_ap

	config_add_boolean wps_pushbutton wps_label ext_registrar wps_pbc_in_m1
	config_add_int wps_ap_setup_locked wps_independent
	config_add_string wps_device_type wps_device_name wps_manufacturer wps_pin
	config_add_string multi_ap_backhaul_ssid multi_ap_backhaul_key

	config_add_boolean ieee80211v wnm_sleep_mode wnm_sleep_mode_no_keys bss_transition
	config_add_int time_advertisement
	config_add_string time_zone
	config_add_string vendor_elements

	config_add_boolean ieee80211k rrm_neighbor_report rrm_beacon_report

	config_add_boolean ftm_responder stationary_ap
	config_add_string lci civic

	config_add_boolean ieee80211r pmk_r1_push ft_psk_generate_local ft_over_ds
	config_add_int r0_key_lifetime reassociation_deadline
	config_add_string mobility_domain r1_key_holder
	config_add_array r0kh r1kh

	config_add_int ieee80211w_max_timeout ieee80211w_retry_timeout

	config_add_string macfilter 'macfile:file'
	config_add_array 'maclist:list(macaddr)'

	config_add_array bssid_blacklist
	config_add_array bssid_whitelist

	config_add_int mcast_rate
	config_add_array basic_rate
	config_add_array supported_rates

	config_add_boolean sae_require_mfp
	config_add_int sae_pwe

	config_add_boolean eap_require_mfp

	config_add_string 'owe_transition_bssid:macaddr' 'owe_transition_ssid:string'

	config_add_boolean iw_enabled iw_internet iw_asra iw_esr iw_uesa
	config_add_int iw_access_network_type iw_venue_group iw_venue_type
	config_add_int iw_ipaddr_type_availability iw_gas_address3
	config_add_string iw_hessid iw_network_auth_type iw_qos_map_set hs20_profile
	config_add_array iw_roaming_consortium iw_domain_name iw_anqp_3gpp_cell_net iw_nai_realm
	config_add_array iw_anqp_elem iw_venue_name iw_venue_url

	config_add_int beacon_rate
	config_add_int rssi_reject_assoc_rssi
	config_add_int rssi_ignore_probe_request
	config_add_int signal_connect signal_stay signal_poll_time signal_strikes signal_drop_reason

	config_add_boolean hs20 disable_dgaf osen
	config_add_int anqp_domain_id
	config_add_int hs20_deauth_req_timeout hs20_release
	config_add_array hs20_oper_friendly_name
	config_add_array osu_provider
	config_add_array operator_icon
	config_add_array hs20_conn_capab
	config_add_string osu_ssid hs20_wan_metrics hs20_operating_class hs20_t_c_filename hs20_t_c_timestamp

	config_add_string hs20_t_c_server_url

	config_add_array airtime_sta_weight
	config_add_int airtime_bss_weight airtime_bss_limit

	config_add_boolean multicast_to_unicast proxy_arp per_sta_vif

	config_add_array hostapd_bss_options
	config_add_boolean default_disabled

	config_add_boolean request_cui
	config_add_array radius_auth_req_attr
	config_add_array radius_acct_req_attr

	config_add_int eap_server
	config_add_string eap_user_file ca_cert server_cert private_key private_key_passwd server_id

	config_add_boolean tun
	config_add_boolean split_tun
	config_add_boolean external_radius
	config_add_int split_sz
	config_add_int vid
	config_add_int is_uam
	config_add_boolean ratelimit
}

hostapd_set_vlan_file() {
	local config="$1"
	local ifname="$2"
	local vlan_net vid
	config_get vlan_net "$config" vlan_net
	if [ "$vlan_net" = "1" ]; then
		vid=$(uci -q get network.$config.ifname | awk -F '.' '{print $NF}')
		echo "${vid} ${ifname}.${vid} br-${config}" >> /var/run/hostapd-${ifname}.vlan
	fi
}

hostapd_set_vlan() {
	local ifname="$1"

	rm -f /var/run/hostapd-${ifname}.vlan

	config_load network
	config_foreach hostapd_set_vlan_file interface ${ifname}
	echo "* ${ifname}.#" >> /var/run/hostapd-${ifname}.vlan
}

hostapd_set_psk_file() {
	local ifname="$1"
	local vlan="$2"
	local vlan_id=""

	json_get_vars mac vid key
	set_default mac "00:00:00:00:00:00"
	[ -n "$vid" ] && vlan_id="vlanid=$vid "
	echo "${vlan_id} ${mac} ${key}" >> /var/run/hostapd-${ifname}.psk
}

hostapd_set_psk() {
	local ifname="$1"

	rm -f /var/run/hostapd-${ifname}.psk
	for_each_station hostapd_set_psk_file ${ifname}
}

hotspot20_set_iw() {
	section="$1"
	wireless_hs_profile_name="$2"
	config_get name "$section" name

	if [ "${wireless_hs_profile_name}" == "${name}" ]; then
		_vars="iw_enabled iw_internet iw_asra iw_esr iw_uesa iw_access_network_type iw_hessid iw_venue_group iw_venue_type iw_network_auth_type iw_roaming_consortium iw_domain_name iw_anqp_3gpp_cell_net iw_nai_realm iw_anqp_elem iw_qos_map_set iw_ipaddr_type_availability iw_gas_address3 iw_venue_name iw_venue_url anqp_domain_id hs20_operating_class hs20_oper_friendly_name"
		for _val in $_vars; do
			config_get ${_val} "$section" ${_val}
		done
	fi
}

append_iw_roaming_consortium() {
	[ -n "$1" ] && append bss_conf "roaming_consortium=$1" "$N"
}

append_iw_domain_name() {
	if [ -z "$iw_domain_name_conf" ]; then
		iw_domain_name_conf="$1"
	else
		iw_domain_name_conf="$iw_domain_name_conf,$1"
	fi
}

append_iw_anqp_3gpp_cell_net() {
	if [ -z "$iw_anqp_3gpp_cell_net_conf" ]; then
		iw_anqp_3gpp_cell_net_conf="$1"
	else
		iw_anqp_3gpp_cell_net_conf="$iw_anqp_3gpp_cell_net_conf;$1"
	fi
}

append_iw_anqp_elem() {
	[ -n "$1" ] && append bss_conf "anqp_elem=$1" "$N"
}

append_iw_nai_realm() {
	[ -n "$1" ] && append bss_conf "nai_realm=$1" "$N"
}

append_iw_venue_name() {
	[ -n "$1" ] && append bss_conf "venue_name=$1" "$N"
}

append_iw_venue_url() {
	[ -n "$1" ] && append bss_conf "venue_url=$1" "$N"
}

append_hs20_oper_friendly_name() {
	if [ -z "$iw_hs20_oper_friendly_name_conf" ]; then
		iw_hs20_oper_friendly_name_conf="$1"
	else
		iw_hs20_oper_friendly_name_conf="$iw_hs20_oper_friendly_name_conf $1"
	fi
}

append_osu_provider_friendly_name() {
	append bss_conf "osu_friendly_name=$1" "$N"
}

append_osu_provider_service_desc() {
	append bss_conf "osu_service_desc=$1" "$N"
}

append_hs20_icon() {
	local width height lang type path
	config_get width "$1" width
	config_get height "$1" height
	config_get lang "$1" lang
	config_get type "$1" type
	config_get path "$1" path

	append bss_conf "hs20_icon=$width:$height:$lang:$type:$1:$path" "$N"
}

append_hs20_icons() {
	config_load wireless
	config_foreach append_hs20_icon hs20-icon
}

append_operator_icon() {
	append bss_conf "operator_icon=$1" "$N"
}

append_osu_icon() {
	append bss_conf "osu_icon=$1" "$N"
}

append_osu_provider() {
	local cfgtype osu_server_uri osu_friendly_name osu_nai osu_nai2 osu_method_list

	config_load wireless
	config_get cfgtype "$1" TYPE
	[ "$cfgtype" != "osu-provider" ] && return

	append bss_conf "# provider $1" "$N"
	config_get osu_server_uri "$1" osu_server_uri
	config_get osu_nai "$1" osu_nai
	config_get osu_nai2 "$1" osu_nai2
	config_get osu_method_list "$1" osu_method

	append bss_conf "osu_server_uri=$osu_server_uri" "$N"
	append bss_conf "osu_nai=$osu_nai" "$N"
	append bss_conf "osu_nai2=$osu_nai2" "$N"
	append bss_conf "osu_method_list=$osu_method_list" "$N"

	config_list_foreach "$1" osu_service_desc append_osu_provider_service_desc
	config_list_foreach "$1" osu_friendly_name append_osu_friendly_name
	config_list_foreach "$1" osu_icon append_osu_icon

	append bss_conf "$N"
}

append_hs20_conn_capab() {
	[ -n "$1" ] && append bss_conf "hs20_conn_capab=$1" "$N"
}

append_radius_acct_req_attr() {
	[ -n "$1" ] && append bss_conf "radius_acct_req_attr=$1" "$N"
}

append_radius_auth_req_attr() {
	[ -n "$1" ] && append bss_conf "radius_auth_req_attr=$1" "$N"
}

append_airtime_sta_weight() {
	[ -n "$1" ] && append bss_conf "airtime_sta_weight=$1" "$N"
}

append_nas_port_id() {
	local tun="$1"
	local split_tun="$2"
	local split_sz="$3"
	local vid="$4"

	local rfname=${ifname##*wlan}
	local rfno=$(echo $rfname | awk -F'-' '{print $1}')
	local vapno=$(echo $rfname | awk -F'-' '{print $2}')

	if [ -z "$vapno" ]; then
		vapno=1
	else
		vapno=$((vapno + 1))
	fi

	if [ -z "$rfno" ]; then
		rfno=1
	else
		rfno=$((rfno + 1))
	fi

	if [ "$tun" = "1" -a "$split_tun" = "1" ]; then
		# split tunnel
		local split_SZ=$((split_sz%1000))
		local split_type=2
		append bss_conf "nas_port_id=vap=${rfno}.${vapno},sz=${split_SZ}.${split_type},vid=${vid}.${split_sz}" "$N"
	elif [ "$tun" = "1" ]; then
		local complete_SZ=$((vid%1000))
		append bss_conf "nas_port_id=vap=${rfno}.${vapno},sz=${complete_SZ}.1,vid=${vid}" "$N"
	else
		append bss_conf "nas_port_id=vap=${rfno}.${vapno},sz=-1.0,vid=${vid}" "$N"
	fi
}

hostapd_set_bss_options() {
	local var="$1"
	local phy="$2"
	local vif="$3"

	wireless_vif_parse_encryption

	local bss_conf bss_md5sum
	local wep_rekey wpa_group_rekey wpa_pair_rekey wpa_master_rekey wpa_key_mgmt

	json_get_vars \
		wep_rekey wpa_group_rekey wpa_pair_rekey wpa_master_rekey wpa_strict_rekey \
		wpa_disable_eapol_key_retries tdls_prohibit \
		maxassoc max_inactivity disassoc_low_ack isolate auth_cache \
		wps_pushbutton wps_label ext_registrar wps_pbc_in_m1 wps_ap_setup_locked \
		wps_independent wps_device_type wps_device_name wps_manufacturer wps_pin \
		macfilter ssid utf8_ssid wmm uapsd hidden short_preamble rsn_preauth \
		iapp_interface eapol_version dynamic_vlan ieee80211w nasid \
		acct_server acct_secret acct_port acct_interval acct_server2 acct_secret2 acct_port2 \
		bss_load_update_period chan_util_avg_period sae_require_mfp sae_pwe eap_require_mfp \
		multi_ap multi_ap_backhaul_ssid multi_ap_backhaul_key skip_inactivity_poll radius_mac_acl \
		airtime_bss_weight airtime_bss_limit airtime_sta_weight \
		multicast_to_unicast proxy_arp per_sta_vif \
		eap_server eap_user_file ca_cert server_cert private_key private_key_passwd server_id \
		signal_connect signal_stay signal_poll_time signal_strikes signal_drop_reason \
		vendor_elements tun split_tun external_radius vid split_sz is_uam \
		dae_enable radsec_enable

	set_default isolate 0
	set_default maxassoc 0
	set_default max_inactivity 0
	set_default short_preamble 1
	set_default disassoc_low_ack 0
	set_default skip_inactivity_poll 0
	set_default hidden 0
	set_default wmm 1
	set_default uapsd 1
	set_default wpa_disable_eapol_key_retries 0
	set_default tdls_prohibit 0
	set_default eapol_version $((wpa & 1))
	set_default acct_port 1813
	set_default bss_load_update_period 60
	set_default chan_util_avg_period 600
	set_default utf8_ssid 1
	set_default multi_ap 0
	set_default radius_mac_acl 0
	set_default airtime_bss_weight 0
	set_default airtime_bss_limit 0
	set_default eap_server 0
	set_default tun 0
	set_default split_tun 0
	set_default external_radius 0
	set_default signal_connect -128
	set_default signal_stay -128
	set_default signal_poll_time 5
	set_default signal_strikes 3
	set_default signal_drop_reason 3
	set_default dae_enable 0
	set_default radsec_enable 0

	append bss_conf "ctrl_interface=/var/run/hostapd"

	if [ "$isolate" -gt 0 ]; then
		append bss_conf "ap_isolate=$isolate" "$N"
	else
		if [ "$(uci -q get acn.mgmt.management)" -ne 3 ] && [ -z "$dynamic_vlan" ] || [ "$dynamic_vlan" -eq 0 ]; then
			append bss_conf "ap_isolate=1" "$N"
		fi
	fi
	if [ "$maxassoc" -gt 0 ]; then
		append bss_conf "max_num_sta=$maxassoc" "$N"
	fi
	if [ "$max_inactivity" -gt 0 ]; then
		append bss_conf "ap_max_inactivity=$max_inactivity" "$N"
	fi

	[ "$airtime_bss_weight" -gt 0 ] && append bss_conf "airtime_bss_weight=$airtime_bss_weight" "$N"
	[ "$airtime_bss_limit" -gt 0 ] && append bss_conf "airtime_bss_limit=$airtime_bss_limit" "$N"
	json_for_each_item append_airtime_sta_weight airtime_sta_weight

	append bss_conf "bss_load_update_period=$bss_load_update_period" "$N"
	append bss_conf "chan_util_avg_period=$chan_util_avg_period" "$N"
	append bss_conf "disassoc_low_ack=$disassoc_low_ack" "$N"
	append bss_conf "skip_inactivity_poll=$skip_inactivity_poll" "$N"
	append bss_conf "preamble=$short_preamble" "$N"
	append bss_conf "wmm_enabled=$wmm" "$N"
	append bss_conf "ignore_broadcast_ssid=$hidden" "$N"
	append bss_conf "uapsd_advertisement_enabled=$uapsd" "$N"
	append bss_conf "utf8_ssid=$utf8_ssid" "$N"
	append bss_conf "multi_ap=$multi_ap" "$N"

	if [ "$signal_stay" -gt -128 -a "$signal_stay" -lt 0 ]; then
		append bss_conf "signal_stay=$signal_stay" "$N"
	fi
	if [ "$signal_connect" -gt -128 -a "$signal_connect" -lt 0 ]; then
		append bss_conf "signal_connect=$signal_connect" "$N"
	fi
	#if [ "$signal_poll_time" -ge 3 ]; then
	#	append bss_conf "signal_poll_time=$signal_poll_time" "$N"
	#fi
	#if [ "$signal_strikes" -gt 0 ]; then
	#	append bss_conf "signal_strikes=$signal_strikes" "$N"
	#fi
	#if [ "$signal_drop_reason" -ge 1 -a "$signal_drop_reason" -le 54 ]; then
	#	append bss_conf "signal_drop_reason=$signal_drop_reason" "$N"
	#fi

	[ -n "$vendor_elements" ] && append bss_conf "vendor_elements=$vendor_elements" "$N"

	[ -n "$(uci_get system.@system[0].hostname)" ] && {
		local sys_host_str=$(uci_get system.@system[0].hostname)
		local sys_host_hex=$(echo -n $sys_host_str | hexdump -v -e '/1 "%02x"')
		local host_ie="dd"$(printf %02x $((${#sys_host_str} + 4)))"8cea1b01"${sys_host_hex}
		append bss_conf "vendor_elements=$host_ie" "$N"
	}

	[ "$tdls_prohibit" -gt 0 ] && append bss_conf "tdls_prohibit=$tdls_prohibit" "$N"

	[ "$wpa" -gt 0 ] && {
		[ -n "$wpa_group_rekey" ] && append bss_conf "wpa_group_rekey=$wpa_group_rekey" "$N"
		[ -n "$wpa_pair_rekey" ] && append bss_conf "wpa_ptk_rekey=$wpa_pair_rekey"    "$N"
		[ -n "$wpa_master_rekey" ] && append bss_conf "wpa_gmk_rekey=$wpa_master_rekey"  "$N"
		[ -n "$wpa_strict_rekey" ] && append bss_conf "wpa_strict_rekey=$wpa_strict_rekey" "$N"
	}

	[ -n "$nasid" ] && append bss_conf "nas_identifier=$nasid" "$N"
	[ -n "$acct_server" ] && {
		append bss_conf "acct_server_addr=$acct_server" "$N"
		append bss_conf "acct_server_port=$acct_port" "$N"
		[ -n "$acct_secret" ] && \
			append bss_conf "acct_server_shared_secret=$acct_secret" "$N"
		[ -n "$acct_interval" ] && \
			append bss_conf "radius_acct_interim_interval=$acct_interval" "$N"
		json_for_each_item append_radius_acct_req_attr radius_acct_req_attr
	}
	[ -n "$acct_server2" ] && {
		append bss_conf "acct_server_addr=$acct_server2" "$N"
		append bss_conf "acct_server_port=$acct_port2" "$N"
		[ -n "$acct_secret2" ] && \
			append bss_conf "acct_server_shared_secret=$acct_secret2" "$N"
		[ -n "$acct_interval" ] && \
			append bss_conf "radius_acct_interim_interval=$acct_interval" "$N"
	}

	case "$auth_type" in
		sae|owe|eap192|eap256)
			set_default ieee80211w 2
			set_default sae_require_mfp 1
		;;
		psk-sae|psk2-radius|eap-eap256)
			set_default ieee80211w 1
			set_default sae_require_mfp 1
		;;
	esac

	case "$auth_type" in
		sae)
			append bss_conf "transition_disable=1" "$N"
			;;
		eap192)
			set_default eap_require_mfp 1
			;;
		eap256)
			append bss_conf "transition_disable=4" "$N"
			set_default eap_require_mfp 1
			;;
	esac

	[ -n "$sae_require_mfp" ] && append bss_conf "sae_require_mfp=$sae_require_mfp" "$N"
	[ -n "$sae_pwe" ] && append bss_conf "sae_pwe=$sae_pwe" "$N"

	[ -n "$eap_require_mfp" ] && append bss_conf "eap_require_mfp=$eap_require_mfp" "$N"

	local vlan_possible=""

	case "$auth_type" in
		none|owe)
			json_get_vars owe_transition_bssid owe_transition_ssid

			[ -n "$owe_transition_ssid" ] && append bss_conf "owe_transition_ssid=\"$owe_transition_ssid\"" "$N"
			[ -n "$owe_transition_bssid" ] && append bss_conf "owe_transition_bssid=$owe_transition_bssid" "$N"

			wps_possible=1
			# Here we make the assumption that if we're in open mode
			# with WPS enabled, we got to be in unconfigured state.
			wps_not_configured=1
		;;
		psk|sae|psk-sae)
			json_get_vars key wpa_psk_file sae_password

			if [ ${#key} -eq 64 ]; then
				append bss_conf "wpa_psk=$key" "$N"
			elif [ ${#key} -ge 8 ] && [ ${#key} -le 63 ]; then
				append bss_conf "wpa_passphrase=$key" "$N"
			elif [ -n "$key" ] || [ -z "$wpa_psk_file" ]; then
				wireless_setup_vif_failed INVALID_WPA_PSK
				return 1
			fi

			# for WPA3 Personal (SAE)
			if [ -n "$sae_password" ]; then
				append bss_conf "sae_password=$sae_password" "$N"
			fi

			[ -z "$wpa_psk_file" ] && set_default wpa_psk_file /var/run/hostapd-$ifname.psk
			[ -n "$wpa_psk_file" ] && {
				[ -e "$wpa_psk_file" ] || touch "$wpa_psk_file"
				append bss_conf "wpa_psk_file=$wpa_psk_file" "$N"
			}
			[ "$eapol_version" -ge "1" -a "$eapol_version" -le "2" ] && append bss_conf "eapol_version=$eapol_version" "$N"

			set_default dynamic_vlan 0
			vlan_possible=1
			wps_possible=1
		;;
		eap|eap192|eap-eap256|eap256)
			json_get_vars \
				auth_server auth_secret auth_port \
				ownip radius_client_addr \
				eap_reauth_period request_cui \
				auth_server2 auth_secret2 auth_port2

			# radius can provide VLAN ID for clients
			vlan_possible=1

			# legacy compatibility
			[ -n "$auth_server" ] || json_get_var auth_server server
			[ -n "$auth_port" ] || json_get_var auth_port port
			[ -n "$auth_secret" ] || json_get_var auth_secret key

			set_default auth_port 1812
			set_default auth_port2 1812

			set_default request_cui 0

			[ "$eap_server" -eq 0 ] && {
				append bss_conf "auth_server_addr=$auth_server" "$N"
				append bss_conf "auth_server_port=$auth_port" "$N"
				append bss_conf "auth_server_shared_secret=$auth_secret" "$N"

				# backup authentication server exist
				[ -n "$auth_server2" -a -n "$auth_port2" -a -n "$auth_secret2" ] && {
					append bss_conf "auth_server_addr=$auth_server2" "$N"
					append bss_conf "auth_server_port=$auth_port2" "$N"
					append bss_conf "auth_server_shared_secret=$auth_secret2" "$N"
				}
			}

			[ "$request_cui" -gt 0 ] && append bss_conf "radius_request_cui=$request_cui" "$N"
			[ -n "$eap_reauth_period" ] && append bss_conf "eap_reauth_period=$eap_reauth_period" "$N"

			json_for_each_item append_radius_auth_req_attr radius_auth_req_attr

			[ -n "$ownip" ] && append bss_conf "own_ip_addr=$ownip" "$N"
			[ -n "$radius_client_addr" ] && append bss_conf "radius_client_addr=$radius_client_addr" "$N"
			append bss_conf "eapol_key_index_workaround=1" "$N"
			append bss_conf "ieee8021x=1" "$N"

			[ "$eapol_version" -ge "1" -a "$eapol_version" -le "2" ] && append bss_conf "eapol_version=$eapol_version" "$N"
		;;
		wep)
			local wep_keyidx=0
			json_get_vars key
			hostapd_append_wep_key bss_conf
			append bss_conf "wep_default_key=$wep_keyidx" "$N"
			[ -n "$wep_rekey" ] && append bss_conf "wep_rekey_period=$wep_rekey" "$N"
		;;
		psk2-radius)
			append bss_conf "wpa_psk_radius=3" "$N"

			json_get_vars \
				auth_server auth_secret auth_port \
				ownip radius_client_addr \
				eap_reauth_period request_cui \
				auth_server2 auth_secret2 auth_port2

			# legacy compatibility
			[ -n "$auth_server" ] || json_get_var auth_server server
			[ -n "$auth_port" ] || json_get_var auth_port port
			[ -n "$auth_secret" ] || json_get_var auth_secret key

			set_default auth_port 1812
			set_default auth_port2 1812
			set_default request_cui 0

			[ "$eap_server" -eq 0 ] && {
				append bss_conf "auth_server_addr=$auth_server" "$N"
				append bss_conf "auth_server_port=$auth_port" "$N"
				append bss_conf "auth_server_shared_secret=$auth_secret" "$N"

				# backup authentication server exist
				[ -n "$auth_server2" -a -n "$auth_port2" -a -n "$auth_secret2" ] && {
					append bss_conf "auth_server_addr=$auth_server2" "$N"
					append bss_conf "auth_server_port=$auth_port2" "$N"
					append bss_conf "auth_server_shared_secret=$auth_secret2" "$N"
				}
			}

			[ "$request_cui" -gt 0 ] && append bss_conf "radius_request_cui=$request_cui" "$N"
			[ -n "$eap_reauth_period" ] && append bss_conf "eap_reauth_period=$eap_reauth_period" "$N"

			json_for_each_item append_radius_auth_req_attr radius_auth_req_attr

			[ -n "$ownip" ] && append bss_conf "own_ip_addr=$ownip" "$N"
			[ -n "$radius_client_addr" ] && append bss_conf "radius_client_addr=$radius_client_addr" "$N"

			vlan_possible=1
		;;
	esac

	local auth_algs=$((($auth_mode_shared << 1) | $auth_mode_open))
	append bss_conf "auth_algs=${auth_algs:-1}" "$N"
	append bss_conf "wpa=$wpa" "$N"
	[ -n "$wpa_pairwise" ] && append bss_conf "wpa_pairwise=$wpa_pairwise" "$N"

	set_default wps_pushbutton 0
	set_default wps_label 0
	set_default wps_pbc_in_m1 0

	config_methods=
	[ "$wps_pushbutton" -gt 0 ] && append config_methods push_button
	[ "$wps_label" -gt 0 ] && append config_methods label

	# WPS not possible on Multi-AP backhaul-only SSID
	[ "$multi_ap" = 1 ] && wps_possible=

	[ -n "$wps_possible" -a -n "$config_methods" ] && {
		set_default ext_registrar 0
		set_default wps_device_type "6-0050F204-1"
		set_default wps_device_name "OpenWrt AP"
		set_default wps_manufacturer "www.openwrt.org"
		set_default wps_independent 1

		wps_state=2
		[ -n "$wps_not_configured" ] && wps_state=1

		[ "$ext_registrar" -gt 0 -a -n "$network_bridge" ] && append bss_conf "upnp_iface=$network_bridge" "$N"

		append bss_conf "eap_server=1" "$N"
		[ -n "$wps_pin" ] && append bss_conf "ap_pin=$wps_pin" "$N"
		append bss_conf "wps_state=$wps_state" "$N"
		append bss_conf "device_type=$wps_device_type" "$N"
		append bss_conf "device_name=$wps_device_name" "$N"
		append bss_conf "manufacturer=$wps_manufacturer" "$N"
		append bss_conf "config_methods=$config_methods" "$N"
		append bss_conf "wps_independent=$wps_independent" "$N"
		[ -n "$wps_ap_setup_locked" ] && append bss_conf "ap_setup_locked=$wps_ap_setup_locked" "$N"
		[ "$wps_pbc_in_m1" -gt 0 ] && append bss_conf "pbc_in_m1=$wps_pbc_in_m1" "$N"
		[ "$multi_ap" -gt 0 ] && [ -n "$multi_ap_backhaul_ssid" ] && {
			append bss_conf "multi_ap_backhaul_ssid=\"$multi_ap_backhaul_ssid\"" "$N"
			if [ -z "$multi_ap_backhaul_key" ]; then
				:
			elif [ ${#multi_ap_backhaul_key} -lt 8 ]; then
				wireless_setup_vif_failed INVALID_WPA_PSK
				return 1
			elif [ ${#multi_ap_backhaul_key} -eq 64 ]; then
				append bss_conf "multi_ap_backhaul_wpa_psk=$multi_ap_backhaul_key" "$N"
			else
				append bss_conf "multi_ap_backhaul_wpa_passphrase=$multi_ap_backhaul_key" "$N"
			fi
		}
	}

	append bss_conf "ssid=$ssid" "$N"

	if [ "$(uci -q get acn.capwap.state)" = "1" ]; then
		if [ "${tun}" = "1" ] && [ "${split_tun}" = "1" ]; then
			append bss_conf "is_uam=1" "$N"
			append bss_conf "capwap_status=0" "$N"
			append bss_conf "split_sz=$split_sz" "$N"
			local SPLIT_TUNNEL_IP_FILE="/tmp/capwap/split_tunnel_ip"
			if [ "${external_radius}" = "1" ]; then
				external_radius_ifname=$(grep "$ifname " /tmp/split_tunnel_external_radius)
				[ -z "$external_radius_ifname" ] && echo "$ifname $split_sz" >> /tmp/split_tunnel_external_radius
			fi
			if [ -f "${SPLIT_TUNNEL_IP_FILE}" ]; then
				local split_tunnel=
				read split_tunnel_ip < "${SPLIT_TUNNEL_IP_FILE}"
				append bss_conf "own_ip_addr=${split_tunnel_ip}" "$N"
			fi
			append_nas_port_id "$tun" "$split_tun" "$split_sz" "$vid"
		fi
		if [ "${tun}" = "1" ] && [ "${split_tun}" = "0" ]; then
			network_bridge=brTun${vid}
			brctl show brTun0
			if [ "$?" != "0" ]; then
				brctl addbr brTun0
				ifconfig brTun0 up
			fi
			vconfig add brTun0 $vid
			ip link set vlan${vid} name brTun0.${vid}
			brctl addbr brTun${vid}
			brctl addif brTun${vid} brTun0.${vid}
			ifconfig brTun${vid} up
			ifconfig brTun0.${vid} up
			append_nas_port_id "$tun" "$split_tun" "$split_sz" "$vid"
		fi
	fi

	[ -n "$network_bridge" ] && append bss_conf "bridge=$network_bridge${N}wds_bridge=" "$N"
	#[ -n "$network_ifname" ] && append bss_conf "snoop_iface=$network_ifname" "$N"

	#local lan_dev wan_dev

	#network_get_physdev lan_dev "lan"
	#network_get_physdev wan_dev "wan"

	#if [ "$network_bridge" = "$lan_dev" ] || [ "$network_bridge" = "$wan_dev" ]; then
	#	if [ -z "$vlan_tagged_interface" ]; then
	#		append bss_conf "iapp_interface=$network_bridge" "$N"
	#	fi
	#fi

	[ -n "$iapp_interface" ] && {
		local ifname
		network_get_device ifname "$iapp_interface" || ifname="$iapp_interface"
		append bss_conf "iapp_interface=$ifname" "$N"
	}

	json_get_vars ieee80211v
	set_default ieee80211v 0
	if [ "$ieee80211v" -eq "1" ]; then
		json_get_vars time_advertisement time_zone wnm_sleep_mode wnm_sleep_mode_no_keys bss_transition
		set_default bss_transition 0
		set_default wnm_sleep_mode 0
		set_default wnm_sleep_mode_no_keys 0

		[ -n "$time_advertisement" ] && append bss_conf "time_advertisement=$time_advertisement" "$N"
		[ -n "$time_zone" ] && append bss_conf "time_zone=$time_zone" "$N"
		if [ "$wnm_sleep_mode" -eq "1" ]; then
			append bss_conf "wnm_sleep_mode=1" "$N"
			[ "$wnm_sleep_mode_no_keys" -eq "1" ] && append bss_conf "wnm_sleep_mode_no_keys=1" "$N"
		fi
		[ "$bss_transition" -eq "1" ] && append bss_conf "bss_transition=1" "$N"
	fi

	json_get_vars ieee80211k rrm_neighbor_report rrm_beacon_report
	set_default ieee80211k 0
	if [ "$ieee80211k" -eq "1" ]; then
		set_default rrm_neighbor_report 1
		set_default rrm_beacon_report 1
	else
		set_default rrm_neighbor_report 0
		set_default rrm_beacon_report 0
	fi

	[ "$rrm_neighbor_report" -eq "1" ] && append bss_conf "rrm_neighbor_report=1" "$N"
	[ "$rrm_beacon_report" -eq "1" ] && append bss_conf "rrm_beacon_report=1" "$N"

	json_get_vars ftm_responder stationary_ap lci civic
	set_default ftm_responder 0
	if [ "$ftm_responder" -eq "1" ]; then
		set_default stationary_ap 0
		iw phy "$phy" info | grep -q "ENABLE_FTM_RESPONDER" && {
			append bss_conf "ftm_responder=1" "$N"
			[ "$stationary_ap" -eq "1" ] && append bss_conf "stationary_ap=1" "$N"
			[ -n "$lci" ] && append bss_conf "lci=$lci" "$N"
			[ -n "$civic" ] && append bss_conf "civic=$civic" "$N"
		}
	fi

	if [ "$wpa" -ge "1" ]; then
		json_get_vars ieee80211r
		set_default ieee80211r 0

		if [ "$ieee80211r" -gt "0" ]; then
			json_get_vars mobility_domain ft_psk_generate_local ft_over_ds reassociation_deadline

			set_default mobility_domain "$(echo "$ssid" | md5sum | head -c 4)"
			set_default ft_over_ds 1
			set_default reassociation_deadline 1000

			case "$auth_type" in
				psk)
					set_default ft_psk_generate_local 1
				;;
				*)
					set_default ft_psk_generate_local 0
				;;
			esac

			[ -n "$network_ifname" ] && append bss_conf "ft_iface=$network_ifname" "$N"
			append bss_conf "mobility_domain=$mobility_domain" "$N"
			append bss_conf "ft_psk_generate_local=$ft_psk_generate_local" "$N"
			append bss_conf "ft_over_ds=$ft_over_ds" "$N"
			append bss_conf "reassociation_deadline=$reassociation_deadline" "$N"
			[ -n "$nasid" ] || append bss_conf "nas_identifier=${macaddr//\:}" "$N"

			if [ "$ft_psk_generate_local" -eq "0" ]; then
				json_get_vars r0_key_lifetime r1_key_holder pmk_r1_push
				json_get_values r0kh r0kh
				json_get_values r1kh r1kh

				set_default r0_key_lifetime 10000
				set_default pmk_r1_push 0

				[ -n "$r0kh" -a -n "$r1kh" ] || {
					sha256_ssid="$(echo -n "$ssid" | sha256sum | head -n1 | sed -e 's/\s.*$//')"

					set_default r0kh "ff:ff:ff:ff:ff:ff,*,$sha256_ssid"
					set_default r1kh "00:00:00:00:00:00,00:00:00:00:00:00,$sha256_ssid"
				}

				[ -n "$r1_key_holder" ] && append bss_conf "r1_key_holder=${macaddr//\:}" "$N"
				append bss_conf "r0_key_lifetime=$r0_key_lifetime" "$N"
				[ -n "$pmk_r1_push" ] || append bss_conf "pmk_r1_push=1" "$N"

				for kh in $r0kh; do
					append bss_conf "r0kh=${kh//,/ }" "$N"
				done
				for kh in $r1kh; do
					append bss_conf "r1kh=${kh//,/ }" "$N"
				done
			fi
		fi

		append bss_conf "wpa_disable_eapol_key_retries=$wpa_disable_eapol_key_retries" "$N"

		hostapd_append_wpa_key_mgmt
		[ -n "$wpa_key_mgmt" ] && append bss_conf "wpa_key_mgmt=$wpa_key_mgmt" "$N"
	fi

	if [ "$wpa" -ge "2" ]; then
		if [ -n "$network_bridge" -a "$rsn_preauth" = 1 ]; then
			set_default auth_cache 1
			append bss_conf "rsn_preauth=1" "$N"
			append bss_conf "rsn_preauth_interfaces=$network_bridge" "$N"
		else
			case "$auth_type" in
			sae|psk-sae|owe)
				set_default auth_cache 1
			;;
			*)
				set_default auth_cache 0
			;;
			esac
		fi

		append bss_conf "okc=$auth_cache" "$N"
		[ "$auth_cache" = 0 ] && append bss_conf "disable_pmksa_caching=1" "$N"

		# RSN -> allow management frame protection
		case "$ieee80211w" in
			[012])
				json_get_vars ieee80211w_mgmt_cipher ieee80211w_max_timeout ieee80211w_retry_timeout
				append bss_conf "ieee80211w=$ieee80211w" "$N"
				[ "$ieee80211w" -gt "0" ] && {
					case "$auth_type" in
					eap192)
						append bss_conf "group_mgmt_cipher=BIP-GMAC-256" "$N"
						append bss_conf "group_cipher=GCMP-256" "$N"
						# for https://redmine.ignitenet.com/issues/21811
						append bss_conf "rsn_pairwise=GCMP-256" "$N"
						;;
					*)
						append bss_conf "group_mgmt_cipher=${ieee80211w_mgmt_cipher:-AES-128-CMAC}" "$N"
						;;
					esac

					[ -n "$ieee80211w_max_timeout" ] && \
						append bss_conf "assoc_sa_query_max_timeout=$ieee80211w_max_timeout" "$N"
					[ -n "$ieee80211w_retry_timeout" ] && \
						append bss_conf "assoc_sa_query_retry_timeout=$ieee80211w_retry_timeout" "$N"
				}
			;;
		esac
	fi

	_macfile="/var/run/hostapd-$ifname.maclist"
	case "$macfilter" in
		allow)
			append bss_conf "macaddr_acl=1" "$N"
			append bss_conf "accept_mac_file=$_macfile" "$N"
			# accept_mac_file can be used to set MAC to VLAN ID mapping
			vlan_possible=1
		;;
		deny)
			append bss_conf "macaddr_acl=0" "$N"
			append bss_conf "deny_mac_file=$_macfile" "$N"
		;;
		*)
			_macfile=""
		;;
	esac

	[ -n "$_macfile" ] && {
		json_get_vars macfile
		json_get_values maclist maclist

		rm -f "$_macfile"
		(
			IFS=';'
			for mac in $maclist; do
				str=$(echo $mac | awk -F':' '{print $1}')
				echo "$str" | sed -e 's/\([0-9A-Fa-f]\{2\}\)/\1:/g' -e 's/\(.*\):$/\1/'
			done
			[ -n "$macfile" -a -f "$macfile" ] && cat "$macfile"
		) > "$_macfile"
	}

	# Dynamic Authorization
	if [ $dae_enable -gt 0 ]; then
		json_get_vars \
			dae_client dae_secret dae_port

		set_default dae_port 3799

		[ -n "$dae_client" -a -n "$dae_secret" ] && {
			append bss_conf "radius_das_port=$dae_port" "$N"
			append bss_conf "radius_das_client=$dae_client $dae_secret" "$N"
		}
	fi

	# RADIUS MAC authentication
	if [ $radius_mac_acl -gt 0 ]; then
		json_get_vars \
			auth_server auth_secret auth_port \
			auth_server2 auth_secret2 auth_port2

		[ -n "$auth_server" -a -n "$auth_port" -a -n "$auth_secret" ] && {
			append bss_conf "macaddr_acl=2" "$N"
			append bss_conf "auth_server_addr=$auth_server" "$N"
			append bss_conf "auth_server_port=$auth_port" "$N"
			append bss_conf "auth_server_shared_secret=$auth_secret" "$N"
		}
		[ -n "$auth_server2" -a -n "$auth_port2" -a -n "$auth_secret2" ] && {
			append bss_conf "auth_server_addr=$auth_server2" "$N"
			append bss_conf "auth_server_port=$auth_port2" "$N"
			append bss_conf "auth_server_shared_secret=$auth_secret2" "$N"
		}
		vlan_possible=1
	fi

	# RadSec
	if [ $radsec_enable -gt 0 ]; then
		append bss_conf "auth_server_type=TLS" "$N"

		if [ -n "$acct_interval" ]; then
			append bss_conf "acct_server_type=TLS" "$N"
		fi
		#Future usage, if client certificate is necessary
		#append bss_conf "auth_server_ca_cert=<PATH_TO_CA>" "$N"
		#append bss_conf "auth_server_client_cert=<PATH_TO_CERT>" "$N"
		#append bss_conf "auth_server_private_key=<PATH_TO_KEY>" "$N"
		#append bss_conf "auth_server_private_key_passwd=<KEY>" "$N"
	fi

	json_get_vars vlan_naming
	set_default vlan_naming 1
	append bss_conf "vlan_naming=$vlan_naming" "$N"
	[ -n "$vlan_possible" -a -n "$dynamic_vlan" ] && {
		json_get_vars vlan_tagged_interface vlan_bridge vlan_file vlan_no_bridge
		[ -z "$vlan_file" ] && set_default vlan_file /var/run/hostapd-$ifname.vlan
		append bss_conf "dynamic_vlan=$dynamic_vlan" "$N"
		append bss_conf "not_pre_add_vif=1" "$N"
		if [ -n "$vlan_bridge" ]; then
			append bss_conf "vlan_bridge=$vlan_bridge" "$N"
		else
			set_default vlan_no_bridge 1
		fi
		append bss_conf "vlan_no_bridge=$vlan_no_bridge" "$N"
		[ -n "$vlan_tagged_interface" ] && \
			append bss_conf "vlan_tagged_interface=$vlan_tagged_interface" "$N"
		[ -n "$vlan_file" ] && {
			[ -e "$vlan_file" ] || touch "$vlan_file"
			append bss_conf "vlan_file=$vlan_file" "$N"
		}
	}

	local hs20 disable_dgaf osen anqp_domain_id hs20_deauth_req_timeout \
		osu_ssid hs20_wan_metrics hs20_operating_class hs20_t_c_filename hs20_t_c_timestamp \
		hs20_t_c_server_url hs20_release
	json_get_vars hs20 disable_dgaf osen anqp_domain_id hs20_deauth_req_timeout \
		osu_ssid hs20_wan_metrics hs20_operating_class hs20_t_c_filename hs20_t_c_timestamp \
		hs20_t_c_server_url hs20_release

	json_get_vars iw_enabled iw_internet iw_asra iw_esr iw_uesa iw_access_network_type
	json_get_vars iw_hessid iw_venue_group iw_venue_type iw_network_auth_type
	json_get_vars iw_roaming_consortium iw_domain_name iw_anqp_3gpp_cell_net iw_nai_realm
	json_get_vars iw_anqp_elem iw_qos_map_set iw_ipaddr_type_availability iw_gas_address3
	json_get_vars iw_venue_name iw_venue_url

	json_get_vars hs20_profile
	[ -n "${hs20_profile}" ] && {
		config_load hotspot20
		config_foreach hotspot20_set_iw profile ${hs20_profile}
	}

	set_default iw_enabled 0
	if [ "$iw_enabled" = "1" ]; then
		append bss_conf "interworking=1" "$N"
		set_default iw_internet 1
		set_default iw_asra 0
		set_default iw_esr 0
		set_default iw_uesa 0

		append bss_conf "internet=$iw_internet" "$N"
		append bss_conf "asra=$iw_asra" "$N"
		append bss_conf "esr=$iw_esr" "$N"
		append bss_conf "uesa=$iw_uesa" "$N"

		[ -n "$iw_access_network_type" ] && \
			append bss_conf "access_network_type=$iw_access_network_type" "$N"
		[ -n "$iw_hessid" ] && {
		  iw_hessid=$(echo $iw_hessid | tr '[a-z]' '[A-Z]')
		  [ ${iw_hessid} == "FF:FF:FF:FF:FF:FF" ] && iw_hessid=$(cat /sys/class/net/eth0/address | tr '[a-z]' '[A-Z]')
		  append bss_conf "hessid=$iw_hessid" "$N"
		}
		[ -n "$iw_venue_group" ] && \
			append bss_conf "venue_group=$iw_venue_group" "$N"
		[ -n "$iw_venue_type" ] && append bss_conf "venue_type=$iw_venue_type" "$N"
		[ -n "$iw_network_auth_type" ] && \
			append bss_conf "network_auth_type=$iw_network_auth_type" "$N"
		[ -n "$iw_gas_address3" ] && append bss_conf "gas_address3=$iw_gas_address3" "$N"

		[ -n "${hs20_profile}" ] && {
			for _val in ${iw_roaming_consortium}; do
				append_iw_roaming_consortium ${_val}
			done

			for _val in ${iw_anqp_elem}; do
				append_iw_anqp_elem ${_val}
			done

			for _val in ${iw_nai_realm}; do
				append_iw_nai_realm ${_val}
			done

			for _val in ${iw_venue_name}; do
				append_iw_venue_name ${_val}
			done

			for _val in ${iw_venue_url}; do
				append_iw_venue_url ${_val}
			done

			iw_domain_name_conf=
			for _val in ${iw_domain_name}; do
				append_iw_domain_name ${_val}
			done
			[ -n "$iw_domain_name_conf" ] && \
				append bss_conf "domain_name=$iw_domain_name_conf" "$N"

			iw_anqp_3gpp_cell_net_conf=
			for _val in ${iw_anqp_3gpp_cell_net}; do
				append_iw_anqp_3gpp_cell_net ${_val}
			done
			[ -n "$iw_anqp_3gpp_cell_net_conf" ] && \
				append bss_conf "anqp_3gpp_cell_net=$iw_anqp_3gpp_cell_net_conf" "$N"

		} || {
			json_for_each_item append_iw_roaming_consortium iw_roaming_consortium
			json_for_each_item append_iw_anqp_elem iw_anqp_elem
			json_for_each_item append_iw_nai_realm iw_nai_realm
			json_for_each_item append_iw_venue_name iw_venue_name
			json_for_each_item append_iw_venue_url iw_venue_url

			iw_domain_name_conf=
			json_for_each_item append_iw_domain_name iw_domain_name
			[ -n "$iw_domain_name_conf" ] && \
				append bss_conf "domain_name=$iw_domain_name_conf" "$N"

			iw_anqp_3gpp_cell_net_conf=
			json_for_each_item append_iw_anqp_3gpp_cell_net iw_anqp_3gpp_cell_net
			[ -n "$iw_anqp_3gpp_cell_net_conf" ] && \
				append bss_conf "anqp_3gpp_cell_net=$iw_anqp_3gpp_cell_net_conf" "$N"
		}
	fi

	set_default iw_qos_map_set 0,0,2,16,1,1,255,255,18,22,24,38,40,40,44,46,48,56
	case "$iw_qos_map_set" in
		*,*);;
		*) iw_qos_map_set="";;
	esac
	[ -n "$iw_qos_map_set" ] && append bss_conf "qos_map_set=$iw_qos_map_set" "$N"

	set_default hs20 0
	set_default hs20_release 1
	set_default disable_dgaf $hs20
	set_default osen 0
	set_default anqp_domain_id 0
	set_default hs20_deauth_req_timeout 60
	if [ "$hs20" = "1" ]; then
		append bss_conf "hs20=1" "$N"
		append_hs20_icons
		append bss_conf "hs20_release=$hs20_release" "$N"
		append bss_conf "disable_dgaf=$disable_dgaf" "$N"
		append bss_conf "osen=$osen" "$N"
		append bss_conf "anqp_domain_id=$anqp_domain_id" "$N"
		append bss_conf "hs20_deauth_req_timeout=$hs20_deauth_req_timeout" "$N"
		[ -n "$osu_ssid" ] && append bss_conf "osu_ssid=$osu_ssid" "$N"
		[ -n "$hs20_wan_metrics" ] && append bss_conf "hs20_wan_metrics=$hs20_wan_metrics" "$N"
		[ -n "$hs20_operating_class" ] && append bss_conf "hs20_operating_class=$hs20_operating_class" "$N"
		[ -n "$hs20_t_c_filename" ] && append bss_conf "hs20_t_c_filename=$hs20_t_c_filename" "$N"
		[ -n "$hs20_t_c_timestamp" ] && append bss_conf "hs20_t_c_timestamp=$hs20_t_c_timestamp" "$N"
		[ -n "$hs20_t_c_server_url" ] && append bss_conf "hs20_t_c_server_url=$hs20_t_c_server_url" "$N"

		iw_hs20_oper_friendly_name_conf=
		[ -n "${hs20_profile}" ] && {
			for _val in ${hs20_oper_friendly_name}; do
				append_hs20_oper_friendly_name ${_val}
			done
		} || {
			json_for_each_item append_hs20_oper_friendly_name hs20_oper_friendly_name
		}
		[ -n "$iw_hs20_oper_friendly_name_conf" ] && \
			append bss_conf "hs20_oper_friendly_name=$iw_hs20_oper_friendly_name_conf" "$N"

		json_for_each_item append_hs20_conn_capab hs20_conn_capab
		json_for_each_item append_osu_provider osu_provider
		json_for_each_item append_operator_icon operator_icon
	fi

	if [ "$eap_server" = "1" ]; then
		append bss_conf "eap_server=1" "$N"
		[ -n "$eap_user_file" ] && append bss_conf "eap_user_file=$eap_user_file" "$N"
		[ -n "$ca_cert" ] && append bss_conf "ca_cert=$ca_cert" "$N"
		[ -n "$server_cert" ] && append bss_conf "server_cert=$server_cert" "$N"
		[ -n "$private_key" ] && append bss_conf "private_key=$private_key" "$N"
		[ -n "$private_key_passwd" ] && append bss_conf "private_key_passwd=$private_key_passwd" "$N"
		[ -n "$server_id" ] && append bss_conf "server_id=$server_id" "$N"
	fi

	set_default multicast_to_unicast 0
	if [ "$multicast_to_unicast" -gt 0 ]; then
		append bss_conf "multicast_to_unicast=$multicast_to_unicast" "$N"
	fi
	set_default proxy_arp 0
	#if [ "$proxy_arp" -gt 0 ]; then
	#	append bss_conf "proxy_arp=$proxy_arp" "$N"
	#fi

	set_default per_sta_vif 0
	if [ "$per_sta_vif" -gt 0 ]; then
		append bss_conf "per_sta_vif=$per_sta_vif" "$N"
	fi

	json_get_values opts hostapd_bss_options
	for val in $opts; do
		append bss_conf "$val" "$N"
	done

	bss_md5sum=$(echo $bss_conf | md5sum | cut -d" " -f1)
	append bss_conf "config_id=$bss_md5sum" "$N"

	append "$var" "$bss_conf" "$N"
	return 0
}

hostapd_set_log_options() {
	local var="$1"

	local log_level log_80211 log_8021x log_radius log_wpa log_driver log_iapp log_mlme
	json_get_vars log_level log_80211 log_8021x log_radius log_wpa log_driver log_iapp log_mlme

	set_default log_level 2
	set_default log_80211  1
	set_default log_8021x  1
	set_default log_radius 1
	set_default log_wpa    1
	set_default log_driver 1
	set_default log_iapp   1
	set_default log_mlme   1

	local log_mask=$(( \
		($log_80211  << 0) | \
		($log_8021x  << 1) | \
		($log_radius << 2) | \
		($log_wpa    << 3) | \
		($log_driver << 4) | \
		($log_iapp   << 5) | \
		($log_mlme   << 6)   \
	))

	append "$var" "logger_syslog=$log_mask" "$N"
	append "$var" "logger_syslog_level=$log_level" "$N"
	append "$var" "logger_stdout=$log_mask" "$N"
	append "$var" "logger_stdout_level=$log_level" "$N"

	return 0
}

_wpa_supplicant_common() {
	local ifname="$1"

	_rpath="/var/run/wpa_supplicant"
	_config="${_rpath}-$ifname.conf"
}

wpa_supplicant_teardown_interface() {
	_wpa_supplicant_common "$1"
	rm -rf "$_rpath/$1" "$_config"
}

wpa_supplicant_prepare_interface() {
	local ifname="$1"
	_w_driver="$2"

	_wpa_supplicant_common "$1"

	json_get_vars mode wds multi_ap
	json_get_vars max_inactivity

	[ -n "$network_bridge" ] && {
		fail=
		case "$mode" in
			adhoc)
				fail=1
			;;
			#sta)
			#	[ "$wds" = 1 -o "$multi_ap" = 1 ] || fail=1
			#;;
		esac

		[ -n "$fail" ] && {
			wireless_setup_vif_failed BRIDGE_NOT_ALLOWED
			return 1
		}
	}

	local ap_scan=

	_w_mode="$mode"

	[ "$mode" = adhoc ] && {
		ap_scan="ap_scan=2"
	}

	local country_str=
	[ -n "$country" ] && {
		default_countrycode_change_to_FCC
		if [ "$country_idx" == "$country_FCC" ]; then
			country_str="country=US"
		elif [ "$country_idx" == "$country_DE" ]; then
			append base_cfg "country_code=DE" "$N"
		else
			country_str="country=$country"
		fi
	}

	set_default max_inactivity 60
	local max_inactivity_str=
	[ "$mode" = mesh ] && {
		[ -n "$max_inactivity" ] && max_inactivity_str="mesh_max_inactivity=$max_inactivity"
	}

	multiap_flag_file="${_config}.is_multiap"
	if [ "$multi_ap" = "1" ]; then
		touch "$multiap_flag_file"
	else
		[ -e "$multiap_flag_file" ] && rm "$multiap_flag_file"
	fi
	wpa_supplicant_teardown_interface "$ifname"
	cat > "$_config" <<EOF
${scan_list:+freq_list=$scan_list}
$ap_scan
$country_str
$max_inactivity_str
EOF
	return 0
}

wpa_supplicant_set_fixed_freq() {
	local freq="$1"
	local htmode="$2"

	append network_data "fixed_freq=1" "$N$T"
	append network_data "frequency=$freq" "$N$T"
	case "$htmode" in
		NOHT) append network_data "disable_ht=1" "$N$T";;
		HT20|VHT20|HE20) append network_data "disable_ht40=1" "$N$T";;
		HT40*|VHT40*|VHT80*|VHT160*) append network_data "ht40=1" "$N$T";;
	esac
	case "$htmode" in
		VHT*) append network_data "vht=1" "$N$T";;
	esac
	case "$htmode" in
		HE80|VHT80) append network_data "max_oper_chwidth=1" "$N$T";;
		HE160|VHT160) append network_data "max_oper_chwidth=2" "$N$T";;
		HE20|HE40|VHT20|VHT40) append network_data "max_oper_chwidth=0" "$N$T";;
		*) append network_data "disable_vht=1" "$N$T";;
	esac
}

wpa_supplicant_add_network() {
	local ifname="$1"
	local freq="$2"
	local htmode="$3"
	local noscan="$4"

	_wpa_supplicant_common "$1"
	wireless_vif_parse_encryption

	json_get_vars \
		ssid bssid key \
		basic_rate mcast_rate \
		ieee80211w ieee80211r \
		multi_ap \
		default_disabled

	case "$auth_type" in
		sae|owe|eap-eap256)
			set_default ieee80211w 2
		;;
		psk-sae|eap192|eap256)
			set_default ieee80211w 1
		;;
	esac

	set_default ieee80211r 0
	set_default multi_ap 0
	set_default default_disabled 0

	local key_mgmt='NONE'
	local network_data=
	local T="	"

	local scan_ssid="scan_ssid=1"
	local freq wpa_key_mgmt

	[ "$_w_mode" = "adhoc" ] && {
		append network_data "mode=1" "$N$T"
		[ -n "$freq" ] && wpa_supplicant_set_fixed_freq "$freq" "$htmode"
		[ "$noscan" = "1" ] && append network_data "noscan=1" "$N$T"

		scan_ssid="scan_ssid=0"

		[ "$_w_driver" = "nl80211" ] ||	append wpa_key_mgmt "WPA-NONE"
	}

	[ "$_w_mode" = "mesh" ] && {
		json_get_vars mesh_id mesh_fwding mesh_rssi_threshold
		[ -n "$mesh_id" ] && ssid="${mesh_id}"

		append network_data "mode=5" "$N$T"
		[ -n "$mesh_fwding" ] && append network_data "mesh_fwding=${mesh_fwding}" "$N$T"
		[ -n "$mesh_rssi_threshold" ] && append network_data "mesh_rssi_threshold=${mesh_rssi_threshold}" "$N$T"
		[ -n "$freq" ] && wpa_supplicant_set_fixed_freq "$freq" "$htmode"
		[ "$noscan" = "1" ] && append network_data "noscan=1" "$N$T"
		append wpa_key_mgmt "SAE"
		scan_ssid=""
	}

	[ "$_w_mode" = "sta" ] && {
		[ "$multi_ap" = 1 ] && append network_data "multi_ap_backhaul_sta=1" "$N$T"
		[ "$default_disabled" = 1 ] && append network_data "disabled=1" "$N$T"
	}

	case "$auth_type" in
		none) ;;
		owe)
			hostapd_append_wpa_key_mgmt
			key_mgmt="$wpa_key_mgmt"
		;;
		wep)
			local wep_keyidx=0
			hostapd_append_wep_key network_data
			append network_data "wep_tx_keyidx=$wep_keyidx" "$N$T"
		;;
		wps)
			key_mgmt='WPS'
		;;
		psk|sae|psk-sae)
			local passphrase

			if [ "$_w_mode" != "mesh" ]; then
				hostapd_append_wpa_key_mgmt
			fi

			key_mgmt="$wpa_key_mgmt"

			if [ ${#key} -eq 64 ]; then
				passphrase="psk=${key}"
			else
				if [ "$_w_mode" = "mesh" ]; then
					passphrase="sae_password=\"${key}\""
				else
					passphrase="psk=\"${key}\""
				fi
			fi
			append network_data "$passphrase" "$N$T"
		;;
		eap|eap192|eap-eap256|eap256)
			hostapd_append_wpa_key_mgmt
			key_mgmt="$wpa_key_mgmt"

			json_get_vars eap_type identity anonymous_identity ca_cert ca_cert_usesystem

			if [ "$ca_cert_usesystem" -eq "1" -a -f "/etc/ssl/certs/ca-certificates.crt" ]; then
				append network_data "ca_cert=\"/etc/ssl/certs/ca-certificates.crt\"" "$N$T"
			else
				[ -n "$ca_cert" ] && append network_data "ca_cert=\"$ca_cert\"" "$N$T"
			fi
			[ -n "$identity" ] && append network_data "identity=\"$identity\"" "$N$T"
			[ -n "$anonymous_identity" ] && append network_data "anonymous_identity=\"$anonymous_identity\"" "$N$T"
			case "$eap_type" in
				tls)
					json_get_vars client_cert priv_key priv_key_pwd
					append network_data "client_cert=\"$client_cert\"" "$N$T"
					append network_data "private_key=\"$priv_key\"" "$N$T"
					append network_data "private_key_passwd=\"$priv_key_pwd\"" "$N$T"

					json_get_vars subject_match
					[ -n "$subject_match" ] && append network_data "subject_match=\"$subject_match\"" "$N$T"

					json_get_values altsubject_match altsubject_match
					if [ -n "$altsubject_match" ]; then
						local list=
						for x in $altsubject_match; do
							append list "$x" ";"
						done
						append network_data "altsubject_match=\"$list\"" "$N$T"
					fi

					json_get_values domain_match domain_match
					if [ -n "$domain_match" ]; then
						local list=
						for x in $domain_match; do
							append list "$x" ";"
						done
						append network_data "domain_match=\"$list\"" "$N$T"
					fi

					json_get_values domain_suffix_match domain_suffix_match
					if [ -n "$domain_suffix_match" ]; then
						local list=
						for x in $domain_suffix_match; do
							append list "$x" ";"
						done
						append network_data "domain_suffix_match=\"$list\"" "$N$T"
					fi
				;;
				fast|peap|ttls)
					json_get_vars auth password ca_cert2 ca_cert2_usesystem client_cert2 priv_key2 priv_key2_pwd
					set_default auth MSCHAPV2

					if [ "$auth" = "EAP-TLS" ]; then
						if [ "$ca_cert2_usesystem" -eq "1" -a -f "/etc/ssl/certs/ca-certificates.crt" ]; then
							append network_data "ca_cert2=\"/etc/ssl/certs/ca-certificates.crt\"" "$N$T"
						else
							[ -n "$ca_cert2" ] && append network_data "ca_cert2=\"$ca_cert2\"" "$N$T"
						fi
						append network_data "client_cert2=\"$client_cert2\"" "$N$T"
						append network_data "private_key2=\"$priv_key2\"" "$N$T"
						append network_data "private_key2_passwd=\"$priv_key2_pwd\"" "$N$T"
					else
						append network_data "password=\"$password\"" "$N$T"
					fi

					json_get_vars subject_match
					[ -n "$subject_match" ] && append network_data "subject_match=\"$subject_match\"" "$N$T"

					json_get_values altsubject_match altsubject_match
					if [ -n "$altsubject_match" ]; then
						local list=
						for x in $altsubject_match; do
							append list "$x" ";"
						done
						append network_data "altsubject_match=\"$list\"" "$N$T"
					fi

					json_get_values domain_match domain_match
					if [ -n "$domain_match" ]; then
						local list=
						for x in $domain_match; do
							append list "$x" ";"
						done
						append network_data "domain_match=\"$list\"" "$N$T"
					fi

					json_get_values domain_suffix_match domain_suffix_match
					if [ -n "$domain_suffix_match" ]; then
						local list=
						for x in $domain_suffix_match; do
							append list "$x" ";"
						done
						append network_data "domain_suffix_match=\"$list\"" "$N$T"
					fi

					phase2proto="auth="
					case "$auth" in
						"auth"*)
							phase2proto=""
						;;
						"EAP-"*)
							auth="$(echo $auth | cut -b 5- )"
							[ "$eap_type" = "ttls" ] &&
								phase2proto="autheap="
							json_get_vars subject_match2
							[ -n "$subject_match2" ] && append network_data "subject_match2=\"$subject_match2\"" "$N$T"

							json_get_values altsubject_match2 altsubject_match2
							if [ -n "$altsubject_match2" ]; then
								local list=
								for x in $altsubject_match2; do
									append list "$x" ";"
								done
								append network_data "altsubject_match2=\"$list\"" "$N$T"
							fi

							json_get_values domain_match2 domain_match2
							if [ -n "$domain_match2" ]; then
								local list=
								for x in $domain_match2; do
									append list "$x" ";"
								done
								append network_data "domain_match2=\"$list\"" "$N$T"
							fi

							json_get_values domain_suffix_match2 domain_suffix_match2
							if [ -n "$domain_suffix_match2" ]; then
								local list=
								for x in $domain_suffix_match2; do
									append list "$x" ";"
								done
								append network_data "domain_suffix_match2=\"$list\"" "$N$T"
							fi
						;;
					esac
					append network_data "phase2=\"$phase2proto$auth\"" "$N$T"
				;;
			esac
			append network_data "eap=$(echo $eap_type | tr 'a-z' 'A-Z')" "$N$T"
		;;
	esac

	[ "$wpa_cipher" = GCMP ] && {
		append network_data "pairwise=GCMP" "$N$T"
		append network_data "group=GCMP" "$N$T"
	}

	[ "$mode" = mesh ] || {
		case "$wpa" in
			1)
				append network_data "proto=WPA" "$N$T"
			;;
			2)
				append network_data "proto=RSN" "$N$T"
			;;
		esac

		case "$ieee80211w" in
			[012])
				[ "$wpa" -ge 2 ] && append network_data "ieee80211w=$ieee80211w" "$N$T"
			;;
		esac
	}
	[ -n "$bssid" ] && append network_data "bssid=$bssid" "$N$T"
	[ -n "$beacon_int" ] && append network_data "beacon_int=$beacon_int" "$N$T"

	local bssid_blacklist bssid_whitelist
	json_get_values bssid_blacklist bssid_blacklist
	json_get_values bssid_whitelist bssid_whitelist

	[ -n "$bssid_blacklist" ] && append network_data "bssid_blacklist=$bssid_blacklist" "$N$T"
	[ -n "$bssid_whitelist" ] && append network_data "bssid_whitelist=$bssid_whitelist" "$N$T"

	[ -n "$basic_rate" ] && {
		local br rate_list=
		for br in $basic_rate; do
			wpa_supplicant_add_rate rate_list "$br"
		done
		[ -n "$rate_list" ] && append network_data "rates=$rate_list" "$N$T"
	}

	[ -n "$mcast_rate" ] && {
		local mc_rate=
		wpa_supplicant_add_rate mc_rate "$mcast_rate"
		append network_data "mcast_rate=$mc_rate" "$N$T"
	}

	if [ "$key_mgmt" = "WPS" ]; then
		echo "wps_cred_processing=1" >> "$_config"
	else
		cat >> "$_config" <<EOF
network={
	$scan_ssid
	ssid="$ssid"
	key_mgmt=$key_mgmt
	$network_data
}
EOF
	fi
	return 0
}

wpa_supplicant_run() {
	local ifname="$1"
	local hostapd_ctrl="$2"

	_wpa_supplicant_common "$ifname"

	ubus wait_for wpa_supplicant
	local supplicant_res="$(ubus call wpa_supplicant config_add "{ \
		\"driver\": \"${_w_driver:-wext}\", \"ctrl\": \"$_rpath\", \
		\"iface\": \"$ifname\", \"config\": \"$_config\" \
		${network_bridge:+, \"bridge\": \"$network_bridge\"} \
		${hostapd_ctrl:+, \"hostapd_ctrl\": \"$hostapd_ctrl\"} \
		}")"

	ret="$?"

	[ "$ret" != 0 -o -z "$supplicant_res" ] && wireless_setup_vif_failed WPA_SUPPLICANT_FAILED

	wireless_add_process "$(jsonfilter -s "$supplicant_res" -l 1 -e @.pid)" "/usr/sbin/wpa_supplicant" 1 1

	return $ret
}

hostapd_common_cleanup() {
	killall meshd-nl80211
}

default_countrycode_change_to_FCC() {
	cur_country="$(uci -q get wireless.radio0.country)"
	MID=`acc hw get product_name | cut -d'=' -f2 | cut -d'-' -f1`

	if [ "$MID" == "EAP104" ]; then
		case $cur_country in
			"JP")
				country_idx="${country_DEFALT}"
				;;
			"KR")
				country_idx="${country_DEFALT}"
				;;
			"IN")
				country_idx="${country_DEFALT}"
				;;
			"AT"|"BE"|"BG"|"HR"|"CZ"|"CY"|"DK"|"EE"|"FI"|"FR"|"DE"|"GR"|"HU"|"IS"|"IE"|"IT"|"LV"|"LT"|"LI"|"LU"|"MT"|"NO"|"NL"|"PL"|"PT"|"RO"|"SK"|"SI"|"ES"|"SE"|"CH"|"TR"|"GB")
				country_idx="${country_DEFALT}"
				;;
			*)
				#others country using FCC
				country_idx="${country_FCC}"
				;;
			esac
	else
		case $MID in
			"EAP102")
			;;
			"EAP101")
			;;
			*)
				#OAP103-BR all country set to US except BR
				if [ "$cur_country" != "BR" ]; then
					country_idx="$country_FCC"
				fi
			;;
		esac

		case $cur_country in
			"JP")
				;;
			"KR")
				;;
			"CA")
				;;
			"AU"|"NZ")
				if [ "$MID" == "EAP102" ]; then
					country_idx="$country_FCC"
				fi
				;;
			"TW")
				;;
			"IN")
				;;
			"ID")
				;;
			"PH")
				if [ "$MID" == "EAP101" ]; then
					country_idx="$country_FCC"
				fi
				;;
			"TH")
				;;
			"BR")
				;;
			"VN")
				;;
			"AT"|"BE"|"BG"|"HR"|"CZ"|"CY"|"DK"|"EE"|"FI"|"FR"|"DE"|"GR"|"HU"|"IS"|"IE"|"IT"|"LV"|"LT"|"LI"|"LU"|"MT"|"NO"|"PL"|"PT"|"RO"|"SK"|"SI"|"ES"|"SE"|"CH"|"TR"|"GB")
				;;
			"NL")
				country_idx="$country_DE"
				;;
			*)
				#others country using FCC
				country_idx="$country_FCC"
				;;
		esac
	fi
}

