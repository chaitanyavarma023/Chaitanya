#!/bin/sh
product_name=$(cat /proc/device-tree/model | cut -d " " -f 2)

PLACE=".1.3.6.1.4.1.259.10.3.38.6.1"

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

if [ "$OP" = "-n" ]; then
    user_num=$(echo $REQ | cut -d "." -f 17)

    case "$REQ" in
        $PLACE|$PLACE.1|$PLACE.1.1)                             RET=$PLACE.1.1.0 ;;
        $PLACE.1.1.0|$PLACE.1.2)                                RET=$PLACE.1.2.0 ;;
        $PLACE.1.2.0|$PLACE.1.3)                                RET=$PLACE.1.3.0 ;;
        $PLACE.1.3.0|$PLACE.1.4)                                RET=$PLACE.1.4.0 ;;
        $PLACE.1.4.0|$PLACE.1.5)                                RET=$PLACE.1.5.0 ;;
        $PLACE.1.5.0|$PLACE.1.6)                                RET=$PLACE.1.6.0 ;;
        $PLACE.1.6.0|$PLACE.1.7)                                RET=$PLACE.1.7.0 ;;
        $PLACE.1.7.0|$PLACE.1.8)                                RET=$PLACE.1.8.0 ;;
        $PLACE.1.8.0|$PLACE.1.9)                                RET=$PLACE.1.9.0 ;;
        $PLACE.1.9.0|$PLACE.1.10)                               RET=$PLACE.1.10.0 ;;
        $PLACE.1.10.0|$PLACE.1.11)                              RET=$PLACE.1.11.0 ;;
        $PLACE.1.11.0|$PLACE.1.12|$PLACE.1.12.1|\
            $PLACE.1.12.1.1|$PLACE.1.12.1.1.1)                  RET=$PLACE.1.12.1.1.1.0 ;;
        $PLACE.1.12.1.1.1.0|$PLACE.1.12.1.1.2)                  RET=$PLACE.1.12.1.1.2.0 ;;
        $PLACE.1.12.1.1.2.0|$PLACE.1.12.1.1.3)                  RET=$PLACE.1.12.1.1.3.0 ;;
        $PLACE.1.12.1.1.3.0|$PLACE.1.12.1.1.4)                  RET=$PLACE.1.12.1.1.4.0 ;;
        $PLACE.1.12.1.1.4.0|$PLACE.1.12.1.1.5)                  RET=$PLACE.1.12.1.1.5.0 ;;
        $PLACE.1.12.1.1.5.0|$PLACE.1.13)                        RET=$PLACE.1.13.0 ;;
        $PLACE.1.13.0|$PLACE.1.14)                              RET=$PLACE.1.14.0 ;;
        $PLACE.1.14.0|$PLACE.1.15)                              RET=$PLACE.1.15.0 ;;
        $PLACE.1.15.0|$PLACE.2|$PLACE.2.1)                      RET=$PLACE.2.1.0 ;;
        $PLACE.2.1.0|$PLACE.2.2)                                RET=$PLACE.2.2.0 ;;
        $PLACE.2.2.0|$PLACE.3|$PLACE.3.1|\
            $PLACE.3.1.1|$PLACE.3.1.1.1)                        RET=$PLACE.3.1.1.1.0 ;;
        $PLACE.3.1.1.$user_num.0|$PLACE.4.1)
            [ $user_num -lt 10 ] && RET=$PLACE.3.1.1.$((user_num+1)).0 || RET=$PLACE.4.1.0 ;;
        $PLACE.4.1.0|$PLACE.4.2)                                RET=$PLACE.4.2.0 ;;
        $PLACE.4.2.0|$PLACE.4.3)                                RET=$PLACE.4.3.0 ;;
        $PLACE.4.3.0|$PLACE.4.4)                                RET=$PLACE.4.4.0 ;;
        $PLACE.4.4.0|$PLACE.4.5)                                RET=$PLACE.4.5.0 ;;
        $PLACE.4.5.0|$PLACE.4.6)                                RET=$PLACE.4.6.0 ;;
        $PLACE.4.6.0|$PLACE.4.7)                                RET=$PLACE.4.7.0 ;;
        $PLACE.4.7.0|$PLACE.4.8)                                RET=$PLACE.4.8.0 ;;
        $PLACE.4.8.0|$PLACE.4.9)                                RET=$PLACE.4.9.0 ;;
        $PLACE.4.9.0|$PLACE.4.10)                               RET=$PLACE.4.10.0 ;;
        $PLACE.4.10.0|$PLACE.4.11)                              RET=$PLACE.4.11.0 ;;
        $PLACE.4.11.0|$PLACE.4.12)                              RET=$PLACE.4.12.0 ;;
        $PLACE.4.12.0|$PLACE.4.13)                              RET=$PLACE.4.13.0 ;;
        $PLACE.4.13.0|$PLACE.4.14)                              RET=$PLACE.4.14.0 ;;
        $PLACE.4.14.0|$PLACE.4.15)                              RET=$PLACE.4.15.0 ;;
        $PLACE.4.15.0|$PLACE.4.16)                              RET=$PLACE.4.16.0 ;;
        $PLACE.4.16.0|$PLACE.4.17)                              RET=$PLACE.4.17.0 ;;
        $PLACE.4.17.0|$PLACE.4.18)                              RET=$PLACE.4.18.0 ;;
        $PLACE.4.18.0|$PLACE.4.19)                              RET=$PLACE.4.19.0 ;;
        $PLACE.4.19.0|$PLACE.4.20)                              RET=$PLACE.4.20.0 ;;
        $PLACE.4.20.0|$PLACE.4.21)                              RET=$PLACE.4.21.0 ;;
        $PLACE.4.21.0|$PLACE.4.22)                              RET=$PLACE.4.22.0 ;;
        $PLACE.4.22.0|$PLACE.4.23)                              RET=$PLACE.4.23.0 ;;
        $PLACE.4.23.0|$PLACE.4.24)                              RET=$PLACE.4.24.0 ;;
        $PLACE.4.24.0|$PLACE.4.25)                              RET=$PLACE.4.25.0 ;;
        $PLACE.4.25.0|$PLACE.4.26)                              RET=$PLACE.4.26.0 ;;
        $PLACE.4.26.0|$PLACE.4.27)                              RET=$PLACE.4.27.0 ;;
        $PLACE.4.27.0|$PLACE.4.28)                              RET=$PLACE.4.28.0 ;;
        $PLACE.4.28.0|$PLACE.5)                                 RET=$PLACE.5.0 ;;
        $PLACE.5.0)                                             exit ;;
        *)                                                      exit 0 ;;
    esac
else
    case "$REQ" in
        $PLACE)                                                 exit 0 ;;
        *)                                                      RET=$REQ ;;
  esac
fi

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
#------------------------------System Settings---------------------------------
function write_APSysHostName() {
    [ "$WRITE_TYPE" != "string" ] && err_wrong_type
    [ "${#WRITE_VALUE}" -gt "32" ] && err_wrong_value
    uci set acn.settings.name="$WRITE_VALUE"
    uci set system.@system[0].hostname="$WRITE_VALUE"
    exit
}
function write_APSysManagement() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt "1" ] || [ "$WRITE_VALUE" -gt "3" ] && err_wrong_value
    uci set acn.mgmt.management="$((WRITE_VALUE-1))"

    if [ "$WRITE_VALUE" -ne 3 ]; then
        uci set acn.capwap.state='0'
        uci set acn.capwap.dns_srv='0'
        uci set acn.capwap.dhcp_opt='0'
        uci set acn.capwap.broadcast='0'
        uci set acn.capwap.multicast='0'
    fi
    exit
}
function write_APSysEnableAgent() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    local Management=$(uci get acn.mgmt.management)
    [ "$Management" -eq 1 ] && uci set acn.mgmt.enabled="$((WRITE_VALUE-1))"
    exit
}
function write_APSysRegistrationURL() {
    [ "$WRITE_TYPE" != "string" ] && err_wrong_type
    local Management=$(uci get acn.mgmt.management)
    local EnableAgent=$(uci get acn.mgmt.enabled)
    [ "$Management" -eq 1 ] && [ "$EnableAgent" -eq 1 ] && uci set acn.register.url="$WRITE_VALUE"
    exit
}
function write_APSysCAPWAP() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    local Management=$(uci get acn.mgmt.management)
    [ "$Management" -eq 2 ] && uci set acn.capwap.state="$((WRITE_VALUE-1))"
    exit
}
function write_APSysDNSSRVDiscovery() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    local Management=$(uci get acn.mgmt.management)
    [ "$Management" -eq 2 ] && uci set acn.capwap.dns_srv="$((WRITE_VALUE-1))"
    exit
}
function write_APSysDomainNameSuffix() {
    [ "$WRITE_TYPE" != "string" ] && err_wrong_type
    local Management=$(uci get acn.mgmt.management)
    local DNSSRVDiscovery=$(uci get acn.capwap.dns_srv)
    [ "$Management" -eq 2 ] && [ "$DNSSRVDiscovery" -eq 1 ] && uci set acn.capwap.srv_suffix="$WRITE_VALUE"
    exit
}
function write_APSysDHCPOptDiscovery() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    local Management=$(uci get acn.mgmt.management)
    [ "$Management" -eq 2 ] && uci set acn.capwap.dhcp_opt="$((WRITE_VALUE-1))"
    exit
}
function write_APSysBroadcastDiscovery() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    local Management=$(uci get acn.mgmt.management)
    [ "$Management" -eq 2 ] && uci set acn.capwap.broadcast="$((WRITE_VALUE-1))"
    exit
}
function write_APSysMulticastDiscovery() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    local Management=$(uci get acn.mgmt.management)
    [ "$Management" -eq 2 ] && uci set acn.capwap.multicast="$((WRITE_VALUE-1))"
    exit
}
function write_APSysStaticDiscovery() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    local Management=$(uci get acn.mgmt.management)
    [ "$Management" -eq 2 ] && uci set acn.capwap.unicast="$((WRITE_VALUE-1))"
    exit
}
function write_APSysACAddress() {
    [ "$WRITE_TYPE" != "string" ] && err_wrong_type
    local Management=$(uci get acn.mgmt.management)

    if [ $Management -eq 2 ]; then
        local num=$(echo $RET_OID | cut -d "." -f 18)
        local check=$(uci show acn | grep capwap_ac[$((num-1))])
        local AC_Address=$(echo $WRITE_VALUE | cut -d "," -f 1)
        local remark=$(echo $WRITE_VALUE | cut -d "," -f 2 | cut -d " " -f 2)

        if [ -n "$AC_Address" ]; then
            if [ -z $check ]; then
                local id=$(uci add acn capwap_ac)
                uci set acn.$id.ip="$AC_Address"
                uci set acn.$id.remark="$remark"
            else
                uci set acn.@capwap_ac[$((num-1))].ip="$AC_Address"
                uci set acn.@capwap_ac[$((num-1))].remark="$remark"
            fi
        else
            uci del acn.@capwap_ac[$((num-1))]
        fi
    fi
    exit
}
function write_APSysBootRetries() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt 1 ] || [ "$WRITE_VALUE" -gt 254 ] && err_wrong_value
    uci set acn.settings.bootmaxcnt="$WRITE_VALUE"
    exit
}
function write_APSysMSPMode(){
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -gt 2 ] || [ "$WRITE_VALUE" -lt 1 ] && err_wrong_value
    uci set acn.settings.msp_enable="$((WRITE_VALUE-1))"
    exit
}
#------------------------------Maintenance-------------------------------------
function write_APSysReboot() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && err_wrong_value
    reboot
    exit
}
function write_APSysReset() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && err_wrong_value
    reset
    exit
}
#------------------------------User Accounts-----------------------------------
function write_APSysUserAccounts() {
    [ "$WRITE_TYPE" != "string" ] && err_wrong_type
    local num=$(echo $RET_OID | cut -d "." -f 17)
    local account=$(uci show users | grep =login | wc -l)
    local enabled=$(echo $WRITE_VALUE | cut -d "," -f 1)
    local user=$(echo $WRITE_VALUE | cut -d "," -f 2 | cut -d " " -f 2)
    local passwd=$(echo $WRITE_VALUE | cut -d "," -f 3 | cut -d " " -f 2)

    if [ -n "$enabled" ] && [ -n "$user" ] && [ -n "$passwd" ]; then
        if [ "$num" -eq 1 ]; then
            uci set users.@login[$((num-1))].passwd="$passwd"
        elif [ "$num" -le "$account" ]; then
            uci set users.@login[$((num-1))].enabled="$enabled"
            uci set users.@login[$((num-1))].name="$user"
            uci set users.@login[$((num-1))].passwd="$passwd"
        else
            local login_user=$(uci add users login)
            uci set users.$login_user.enabled="$enabled"
            uci set users.$login_user.name="$user"
            uci set users.$login_user.passwd="$passwd"
        fi
    else
        [ "$num" -ne 1 ] && uci del users.@login[$((num-1))]
    fi
    exit
}
#------------------------------Services----------------------------------------
function write_APSysSSHServer() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    uci set dropbear.@dropbear[0].enable="$((WRITE_VALUE-1))"
    [ "WRITE_VALUE" -eq 1 ] && uci del dropbear.@dropbear[0].Port
    exit
}
function write_APSysSSHPort() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt 0 ] || [ "$WRITE_VALUE" -gt 65535 ] && err_wrong_value
    uci set dropbear.@dropbear[0].Port="$WRITE_VALUE"
    local rule_num=$(uci show firewall | grep Allow-SSH | cut -d "[" -f 2 | cut -d "]" -f 1)
    [ -n "$rule_num" ] && uci set firewall.@rule[$rule_num].dest_port="$WRITE_VALUE"
    exit
}
function write_APSysAllowSSH() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    local rule_num=$(uci show firewall | grep Allow-SSH | cut -d "[" -f 2 | cut -d "]" -f 1)

    if [ $WRITE_VALUE -eq 1 ]; then
        uci del firewall.@rule[$rule_num]
    elif [ $WRITE_VALUE -eq 2 ]; then
        local rule_id=$(uci add firewall rule)
        uci set firewall.$rule_id.enabled="1"
        uci set firewall.$rule_id.name="Allow-SSH"
        uci set firewall.$rule_id.src="wan"
        uci set firewall.$rule_id.proto="tcp"
        uci set firewall.$rule_id.dest_port="$(uci get dropbear.@dropbear[0].Port)"
        uci set firewall.$rule_id.target="ACCEPT"
        uci set firewall.$rule_id.family="ipv4"
    fi
    exit
}
function write_APSysTelnetServer() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    uci set telnetd.@telnetd[0].enable="$((WRITE_VALUE-1))"
    [ "WRITE_VALUE" -eq 1 ] && uci del telnetd.@telnetd[0].Port
    exit
}
function write_APSysTelnetPort() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt 0 ] || [ "$WRITE_VALUE" -gt 65535 ] && err_wrong_value
    uci set telnetd.@telnetd[0].Port="$WRITE_VALUE"
    local rule_num=$(uci show firewall | grep Allow-Telnet | cut -d "[" -f 2 | cut -d "]" -f 1)
    [ -n "$rule_num" ] && uci set firewall.@rule[$rule_num].dest_port="$WRITE_VALUE"
    exit
}
function write_APSysAllowTelnet() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    local rule_num=$(uci show firewall | grep Allow-Telnet | cut -d "[" -f 2 | cut -d "]" -f 1)

    if [ $WRITE_VALUE -eq 1 ]; then
        uci del firewall.@rule[$rule_num]
    elif [ $WRITE_VALUE -eq 2 ]; then
        local rule_id=$(uci add firewall rule)
        uci set firewall.$rule_id.enabled="1"
        uci set firewall.$rule_id.name="Allow-Telnet"
        uci set firewall.$rule_id.src="wan"
        uci set firewall.$rule_id.proto="tcp"
        uci set firewall.$rule_id.dest_port="$(uci get telnetd.@telnetd[0].Port)"
        uci set firewall.$rule_id.target="ACCEPT"
        uci set firewall.$rule_id.family="ipv4"
    fi
    exit
}
function write_APSysHttpPort() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt 0 ] || [ "$WRITE_VALUE" -gt 65535 ] && err_wrong_value
    uci set uhttpd.main.listen_http="$WRITE_VALUE"
    local rule_num=$(uci show firewall | grep Allow-WEBUI | cut -d "[" -f 2 | cut -d "]" -f 1)
    [ -n "$rule_num" ] && uci set firewall.@rule[$rule_num].dest_port="$WRITE_VALUE"
    exit
}
function write_APSysAllowHttp() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    local rule_num=$(uci show firewall | grep Allow-WEBUI | cut -d "[" -f 2 | cut -d "]" -f 1)

    if [ $WRITE_VALUE -eq 1 ]; then
        uci del firewall.@rule[$rule_num]
    elif [ $WRITE_VALUE -eq 2 ]; then
        local rule_id=$(uci add firewall rule)
        uci set firewall.$rule_id.enabled="1"
        uci set firewall.$rule_id.name="Allow-WEBUI"
        uci set firewall.$rule_id.src="wan"
        uci set firewall.$rule_id.proto="tcp"
        uci set firewall.$rule_id.dest_port="$(uci get uhttpd.main.listen_http)"
        uci set firewall.$rule_id.target="ACCEPT"
        uci set firewall.$rule_id.family="ipv4"
    fi
    exit
}
function write_APSysHttpsPort() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt 0 ] || [ "$WRITE_VALUE" -gt 65535 ] && err_wrong_value
    uci set uhttpd.main.listen_https="$WRITE_VALUE"
    local rule_num=$(uci show firewall | grep Allow-WEBUI-secure | cut -d "[" -f 2 | cut -d "]" -f 1)
    [ -n "$rule_num" ] && uci set firewall.@rule[$rule_num].dest_port="$WRITE_VALUE"
    exit
}
function write_APSysAllowHttps() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    local rule_num=$(uci show firewall | grep Allow-WEBUI-secure | cut -d "[" -f 2 | cut -d "]" -f 1)

    if [ $WRITE_VALUE -eq 1 ]; then
        uci del firewall.@rule[$rule_num]
    elif [ $WRITE_VALUE -eq 2 ]; then
        local rule_id=$(uci add firewall rule)
        uci set firewall.$rule_id.enabled="1"
        uci set firewall.$rule_id.name="Allow-WEBUI-secure"
        uci set firewall.$rule_id.src="wan"
        uci set firewall.$rule_id.proto="tcp"
        uci set firewall.$rule_id.dest_port="$(uci get uhttpd.main.listen_https)"
        uci set firewall.$rule_id.target="ACCEPT"
        uci set firewall.$rule_id.family="ipv4"
    fi
    exit
}
function write_APSysRemoteLog() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    uci set system.@system[0].log_remote="$((WRITE_VALUE-1))"

    if [ $WRITE_VALUE -eq 1 ]; then
        uci del system.@system[0].log_conntrackd_enable
        uci del system.@system[0].log_ip
        uci del system.@system[0].log_port
        uci del system.@system[0].log_prefix
    fi
    exit
}
function write_APSysLogTrackConnections() {
    [ "$WRITE_TYPE" != "" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    local log_remote=$(uci get system.@system[0].log_remote)
    [ "$log_remote" -eq 1 ] && uci set system.@system[0].log_conntrackd_enable="$((WRITE_VALUE-1))"
    exit
}
function write_APSysLogServerIp() {
    [ "$WRITE_TYPE" != "ipaddress" ] && err_wrong_type
    local log_remote=$(uci get system.@system[0].log_remote)
    [ "$log_remote" -eq 1 ] && uci set system.@system[0].log_ip="$WRITE_VALUE"
    exit
}
function write_APSysLogServerPort() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt 0 ] || [ "$WRITE_VALUE" -gt 65535 ] && err_wrong_value
    local log_remote=$(uci get system.@system[0].log_remote)
    [ "$log_remote" -eq 1 ] && uci set system.@system[0].log_port="$WRITE_VALUE"
    exit
}
function write_APSysLogPrefix() {
    [ "$WRITE_TYPE" != "string" ] && err_wrong_type
    local log_remote=$(uci get system.@system[0].log_remote)
    [ "$log_remote" -eq 1 ] && uci set system.@system[0].log_prefix="$WRITE_VALUE"
    exit
}
function write_APSysNtpService() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    uci set system.ntp.enable_server="$((WRITE_VALUE-1))"
    exit
}
function write_APSysNtpServers() {
    [ "$WRITE_TYPE" != "string" ] && err_wrong_type
    uci del system.ntp.server

    for ntp in $WRITE_TYPE; do
        uci add_list system.ntp.server="$ntp"
    done
    exit
}
function write_APSysTimezone() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt "1" ] || [ "$WRITE_VALUE" -gt "453" ] && err_wrong_value
    case "$WRITE_VALUE" in
        1) value="UTC" ;;
        2) value="Africa/Abidjan" ;;
        3) value="Africa/Accra" ;;
        4) value="Africa/Addis Ababa" ;;
        5) value="Africa/Algiers" ;;
        6) value="Africa/Asmara" ;;
        7) value="Africa/Bamako" ;;
        8) value="Africa/Bangui" ;;
        9) value="Africa/Banjul" ;;
        10) value="Africa/Bissau" ;;
        11) value="Africa/Blantyre" ;;
        12) value="Africa/Brazzaville" ;;
        13) value="Africa/Bujumbura" ;;
        14) value="Africa/Cairo" ;;
        15) value="Africa/Casablanca" ;;
        16) value="Africa/Ceuta" ;;
        17) value="Africa/Conakry" ;;
        18) value="Africa/Dakar" ;;
        19) value="Africa/Dar es Salaam" ;;
        20) value="Africa/Djibouti" ;;
        21) value="Africa/Douala" ;;
        22) value="Africa/El Aaiun" ;;
        23) value="Africa/Freetown" ;;
        24) value="Africa/Gaborone" ;;
        25) value="Africa/Harare" ;;
        26) value="Africa/Johannesburg" ;;
        27) value="Africa/Juba" ;;
        28) value="Africa/Kampala" ;;
        29) value="Africa/Khartoum" ;;
        30) value="Africa/Kigali" ;;
        31) value="Africa/Kinshasa" ;;
        32) value="Africa/Lagos" ;;
        33) value="Africa/Libreville" ;;
        34) value="Africa/Lome" ;;
        35) value="Africa/Luanda" ;;
        36) value="Africa/Lubumbashi" ;;
        37) value="Africa/Lusaka" ;;
        38) value="Africa/Malabo" ;;
        39) value="Africa/Maputo" ;;
        40) value="Africa/Maseru" ;;
        41) value="Africa/Mbabane" ;;
        42) value="Africa/Mogadishu" ;;
        43) value="Africa/Monrovia" ;;
        44) value="Africa/Nairobi" ;;
        45) value="Africa/Ndjamena" ;;
        46) value="Africa/Niamey" ;;
        47) value="Africa/Nouakchott" ;;
        48) value="Africa/Ouagadougou" ;;
        49) value="Africa/Porto-Novo" ;;
        50) value="Africa/Sao Tome" ;;
        51) value="Africa/Tripoli" ;;
        52) value="Africa/Tunis" ;;
        53) value="Africa/Windhoek" ;;
        54) value="America/Adak" ;;
        55) value="America/Anchorage" ;;
        56) value="America/Anguilla" ;;
        57) value="America/Antigua" ;;
        58) value="America/Araguaina" ;;
        59) value="America/Argentina/Buenos Aires" ;;
        60) value="America/Argentina/Catamarca" ;;
        61) value="America/Argentina/Cordoba" ;;
        62) value="America/Argentina/Jujuy" ;;
        63) value="America/Argentina/La Rioja" ;;
        64) value="America/Argentina/Mendoza" ;;
        65) value="America/Argentina/Rio Gallegos" ;;
        66) value="America/Argentina/Salta" ;;
        67) value="America/Argentina/San Juan" ;;
        68) value="America/Argentina/San Luis" ;;
        69) value="America/Argentina/Tucuman" ;;
        70) value="America/Argentina/Ushuaia" ;;
        71) value="America/Aruba" ;;
        72) value="America/Asuncion" ;;
        73) value="America/Atikokan" ;;
        74) value="America/Bahia" ;;
        75) value="America/Bahia Banderas" ;;
        76) value="America/Barbados" ;;
        77) value="America/Belem" ;;
        78) value="America/Belize" ;;
        79) value="America/Blanc-Sablon" ;;
        80) value="America/Boa Vista" ;;
        81) value="America/Bogota" ;;
        82) value="America/Boise" ;;
        83) value="America/Cambridge Bay" ;;
        84) value="America/Campo Grande" ;;
        85) value="America/Cancun" ;;
        86) value="America/Caracas" ;;
        87) value="America/Cayenne" ;;
        88) value="America/Cayman" ;;
        89) value="America/Chicago" ;;
        90) value="America/Chihuahua" ;;
        91) value="America/Costa Rica" ;;
        92) value="America/Creston" ;;
        93) value="America/Cuiaba" ;;
        94) value="America/Curacao" ;;
        95) value="America/Danmarkshavn" ;;
        96) value="America/Dawson" ;;
        97) value="America/Dawson Creek" ;;
        98) value="America/Denver" ;;
        99) value="America/Detroit" ;;
        100) value="America/Dominica" ;;
        101) value="America/Edmonton" ;;
        102) value="America/Eirunepe" ;;
        103) value="America/El Salvador" ;;
        104) value="America/Fort Nelson" ;;
        105) value="America/Fortaleza" ;;
        106) value="America/Glace Bay" ;;
        107) value="America/Goose Bay" ;;
        108) value="America/Grand Turk" ;;
        109) value="America/Grenada" ;;
        110) value="America/Guadeloupe" ;;
        111) value="America/Guatemala" ;;
        112) value="America/Guayaquil" ;;
        113) value="America/Guyana" ;;
        114) value="America/Halifax" ;;
        115) value="America/Havana" ;;
        116) value="America/Hermosillo" ;;
        117) value="America/Indiana/Indianapolis" ;;
        118) value="America/Indiana/Knox" ;;
        119) value="America/Indiana/Marengo" ;;
        120) value="America/Indiana/Petersburg" ;;
        121) value="America/Indiana/Tell City" ;;
        122) value="America/Indiana/Vevay" ;;
        123) value="America/Indiana/Vincennes" ;;
        124) value="America/Indiana/Winamac" ;;
        125) value="America/Inuvik" ;;
        126) value="America/Iqaluit" ;;
        127) value="America/Jamaica" ;;
        128) value="America/Juneau" ;;
        129) value="America/Kentucky/Louisville" ;;
        130) value="America/Kentucky/Monticello" ;;
        131) value="America/Kralendijk" ;;
        132) value="America/La Paz" ;;
        133) value="America/Lima" ;;
        134) value="America/Los Angeles" ;;
        135) value="America/Lower Princes" ;;
        136) value="America/Maceio" ;;
        137) value="America/Managua" ;;
        138) value="America/Manaus" ;;
        139) value="America/Marigot" ;;
        140) value="America/Martinique" ;;
        141) value="America/Matamoros" ;;
        142) value="America/Mazatlan" ;;
        143) value="America/Menominee" ;;
        144) value="America/Merida" ;;
        145) value="America/Metlakatla" ;;
        146) value="America/Mexico City" ;;
        147) value="America/Miquelon" ;;
        148) value="America/Moncton" ;;
        149) value="America/Monterrey" ;;
        150) value="America/Montevideo" ;;
        151) value="America/Montserrat" ;;
        152) value="America/Nassau" ;;
        153) value="America/New York" ;;
        154) value="America/Nipigon" ;;
        155) value="America/Nome" ;;
        156) value="America/Noronha" ;;
        157) value="America/North Dakota/Beulah" ;;
        158) value="America/North Dakota/Center" ;;
        159) value="America/North Dakota/New Salem" ;;
        160) value="America/Nuuk" ;;
        161) value="America/Ojinaga" ;;
        162) value="America/Panama" ;;
        163) value="America/Pangnirtung" ;;
        164) value="America/Paramaribo" ;;
        165) value="America/Phoenix" ;;
        166) value="America/Port of Spain" ;;
        167) value="America/Port-au-Prince" ;;
        168) value="America/Porto Velho" ;;
        169) value="America/Puerto Rico" ;;
        170) value="America/Punta Arenas" ;;
        171) value="America/Rainy River" ;;
        172) value="America/Rankin Inlet" ;;
        173) value="America/Recife" ;;
        174) value="America/Regina" ;;
        175) value="America/Resolute" ;;
        176) value="America/Rio Branco" ;;
        177) value="America/Santarem" ;;
        178) value="America/Santiago" ;;
        179) value="America/Santo Domingo" ;;
        180) value="America/Sao Paulo" ;;
        181) value="America/Scoresbysund" ;;
        182) value="America/Sitka" ;;
        183) value="America/St Barthelemy" ;;
        184) value="America/St Johns" ;;
        185) value="America/St Kitts" ;;
        186) value="America/St Lucia" ;;
        187) value="America/St Thomas" ;;
        188) value="America/St Vincent" ;;
        189) value="America/Swift Current" ;;
        190) value="America/Tegucigalpa" ;;
        191) value="America/Thule" ;;
        192) value="America/Thunder Bay" ;;
        193) value="America/Tijuana" ;;
        194) value="America/Toronto" ;;
        195) value="America/Tortola" ;;
        196) value="America/Vancouver" ;;
        197) value="America/Whitehorse" ;;
        198) value="America/Winnipeg" ;;
        199) value="America/Yakutat" ;;
        200) value="America/Yellowknife" ;;
        201) value="Antarctica/Casey" ;;
        202) value="Antarctica/Davis" ;;
        203) value="Antarctica/DumontDUrville" ;;
        204) value="Antarctica/Macquarie" ;;
        205) value="Antarctica/Mawson" ;;
        206) value="Antarctica/McMurdo" ;;
        207) value="Antarctica/Palmer" ;;
        208) value="Antarctica/Rothera" ;;
        209) value="Antarctica/Syowa" ;;
        210) value="Antarctica/Troll" ;;
        211) value="Antarctica/Vostok" ;;
        212) value="Arctic/Longyearbyen" ;;
        213) value="Asia/Aden" ;;
        214) value="Asia/Almaty" ;;
        215) value="Asia/Amman" ;;
        216) value="Asia/Anadyr" ;;
        217) value="Asia/Aqtau" ;;
        218) value="Asia/Aqtobe" ;;
        219) value="Asia/Ashgabat" ;;
        220) value="Asia/Atyrau" ;;
        221) value="Asia/Baghdad" ;;
        222) value="Asia/Bahrain" ;;
        223) value="Asia/Baku" ;;
        224) value="Asia/Bangkok" ;;
        225) value="Asia/Barnaul" ;;
        226) value="Asia/Beirut" ;;
        227) value="Asia/Bishkek" ;;
        228) value="Asia/Brunei" ;;
        229) value="Asia/Chita" ;;
        230) value="Asia/Choibalsan" ;;
        231) value="Asia/Colombo" ;;
        232) value="Asia/Damascus" ;;
        233) value="Asia/Dhaka" ;;
        234) value="Asia/Dili" ;;
        235) value="Asia/Dubai" ;;
        236) value="Asia/Dushanbe" ;;
        237) value="Asia/Famagusta" ;;
        238) value="Asia/Gaza" ;;
        239) value="Asia/Hebron" ;;
        240) value="Asia/Ho Chi Minh" ;;
        241) value="Asia/Hong Kong" ;;
        242) value="Asia/Hovd" ;;
        243) value="Asia/Irkutsk" ;;
        244) value="Asia/Jakarta" ;;
        245) value="Asia/Jayapura" ;;
        246) value="Asia/Jerusalem" ;;
        247) value="Asia/Kabul" ;;
        248) value="Asia/Kamchatka" ;;
        249) value="Asia/Karachi" ;;
        250) value="Asia/Kathmandu" ;;
        251) value="Asia/Khandyga" ;;
        252) value="Asia/Kolkata" ;;
        253) value="Asia/Krasnoyarsk" ;;
        254) value="Asia/Kuala Lumpur" ;;
        255) value="Asia/Kuching" ;;
        256) value="Asia/Kuwait" ;;
        257) value="Asia/Macau" ;;
        258) value="Asia/Magadan" ;;
        259) value="Asia/Makassar" ;;
        260) value="Asia/Manila" ;;
        261) value="Asia/Muscat" ;;
        262) value="Asia/Nicosia" ;;
        263) value="Asia/Novokuznetsk" ;;
        264) value="Asia/Novosibirsk" ;;
        265) value="Asia/Omsk" ;;
        266) value="Asia/Oral" ;;
        267) value="Asia/Phnom Penh" ;;
        268) value="Asia/Pontianak" ;;
        269) value="Asia/Pyongyang" ;;
        270) value="Asia/Qatar" ;;
        271) value="Asia/Qostanay" ;;
        272) value="Asia/Qyzylorda" ;;
        273) value="Asia/Riyadh" ;;
        274) value="Asia/Sakhalin" ;;
        275) value="Asia/Samarkand" ;;
        276) value="Asia/Seoul" ;;
        277) value="Asia/Shanghai" ;;
        278) value="Asia/Singapore" ;;
        279) value="Asia/Srednekolymsk" ;;
        280) value="Asia/Taipei" ;;
        281) value="Asia/Tashkent" ;;
        282) value="Asia/Tbilisi" ;;
        283) value="Asia/Tehran" ;;
        284) value="Asia/Thimphu" ;;
        285) value="Asia/Tokyo" ;;
        286) value="Asia/Tomsk" ;;
        287) value="Asia/Ulaanbaatar" ;;
        288) value="Asia/Urumqi" ;;
        289) value="Asia/Ust-Nera" ;;
        290) value="Asia/Vientiane" ;;
        291) value="Asia/Vladivostok" ;;
        292) value="Asia/Yakutsk" ;;
        293) value="Asia/Yangon" ;;
        294) value="Asia/Yekaterinburg" ;;
        295) value="Asia/Yerevan" ;;
        296) value="Atlantic/Azores" ;;
        297) value="Atlantic/Bermuda" ;;
        298) value="Atlantic/Canary" ;;
        299) value="Atlantic/Cape Verde" ;;
        300) value="Atlantic/Faroe" ;;
        301) value="Atlantic/Madeira" ;;
        302) value="Atlantic/Reykjavik" ;;
        303) value="Atlantic/South Georgia" ;;
        304) value="Atlantic/St Helena" ;;
        305) value="Atlantic/Stanley" ;;
        306) value="Australia/Adelaide" ;;
        307) value="Australia/Brisbane" ;;
        308) value="Australia/Broken Hill" ;;
        309) value="Australia/Currie" ;;
        310) value="Australia/Darwin" ;;
        311) value="Australia/Eucla" ;;
        312) value="Australia/Hobart" ;;
        313) value="Australia/Lindeman" ;;
        314) value="Australia/Lord Howe" ;;
        315) value="Australia/Melbourne" ;;
        316) value="Australia/Perth" ;;
        317) value="Australia/Sydney" ;;
        318) value="Etc/GMT" ;;
        319) value="Etc/GMT+1" ;;
        320) value="Etc/GMT+10" ;;
        321) value="Etc/GMT+11" ;;
        322) value="Etc/GMT+12" ;;
        323) value="Etc/GMT+2" ;;
        324) value="Etc/GMT+3" ;;
        325) value="Etc/GMT+4" ;;
        326) value="Etc/GMT+5" ;;
        327) value="Etc/GMT+6" ;;
        328) value="Etc/GMT+7" ;;
        329) value="Etc/GMT+8" ;;
        330) value="Etc/GMT+9" ;;
        331) value="Etc/GMT-1" ;;
        332) value="Etc/GMT-10" ;;
        333) value="Etc/GMT-11" ;;
        334) value="Etc/GMT-12" ;;
        335) value="Etc/GMT-13" ;;
        336) value="Etc/GMT-14" ;;
        337) value="Etc/GMT-2" ;;
        338) value="Etc/GMT-3" ;;
        339) value="Etc/GMT-4" ;;
        340) value="Etc/GMT-5" ;;
        341) value="Etc/GMT-6" ;;
        342) value="Etc/GMT-7" ;;
        343) value="Etc/GMT-8" ;;
        344) value="Etc/GMT-9" ;;
        345) value="Europe/Amsterdam" ;;
        346) value="Europe/Andorra" ;;
        347) value="Europe/Astrakhan" ;;
        348) value="Europe/Athens" ;;
        349) value="Europe/Belgrade" ;;
        350) value="Europe/Berlin" ;;
        351) value="Europe/Bratislava" ;;
        352) value="Europe/Brussels" ;;
        353) value="Europe/Bucharest" ;;
        354) value="Europe/Budapest" ;;
        355) value="Europe/Busingen" ;;
        356) value="Europe/Chisinau" ;;
        357) value="Europe/Copenhagen" ;;
        358) value="Europe/Dublin" ;;
        359) value="Europe/Gibraltar" ;;
        360) value="Europe/Guernsey" ;;
        361) value="Europe/Helsinki" ;;
        362) value="Europe/Isle of Man" ;;
        363) value="Europe/Istanbul" ;;
        364) value="Europe/Jersey" ;;
        365) value="Europe/Kaliningrad" ;;
        366) value="Europe/Kiev" ;;
        367) value="Europe/Kirov" ;;
        368) value="Europe/Lisbon" ;;
        369) value="Europe/Ljubljana" ;;
        370) value="Europe/London" ;;
        371) value="Europe/Luxembourg" ;;
        372) value="Europe/Madrid" ;;
        373) value="Europe/Malta" ;;
        374) value="Europe/Mariehamn" ;;
        375) value="Europe/Minsk" ;;
        376) value="Europe/Monaco" ;;
        377) value="Europe/Moscow" ;;
        378) value="Europe/Oslo" ;;
        379) value="Europe/Paris" ;;
        380) value="Europe/Podgorica" ;;
        381) value="Europe/Prague" ;;
        382) value="Europe/Riga" ;;
        383) value="Europe/Rome" ;;
        384) value="Europe/Samara" ;;
        385) value="Europe/San Marino" ;;
        386) value="Europe/Sarajevo" ;;
        387) value="Europe/Saratov" ;;
        388) value="Europe/Simferopol" ;;
        389) value="Europe/Skopje" ;;
        390) value="Europe/Sofia" ;;
        391) value="Europe/Stockholm" ;;
        392) value="Europe/Tallinn" ;;
        393) value="Europe/Tirane" ;;
        394) value="Europe/Ulyanovsk" ;;
        395) value="Europe/Uzhgorod" ;;
        396) value="Europe/Vaduz" ;;
        397) value="Europe/Vatican" ;;
        398) value="Europe/Vienna" ;;
        399) value="Europe/Vilnius" ;;
        400) value="Europe/Volgograd" ;;
        401) value="Europe/Warsaw" ;;
        402) value="Europe/Zagreb" ;;
        403) value="Europe/Zaporozhye" ;;
        404) value="Europe/Zurich" ;;
        405) value="Indian/Antananarivo" ;;
        406) value="Indian/Chagos" ;;
        407) value="Indian/Christmas" ;;
        408) value="Indian/Cocos" ;;
        409) value="Indian/Comoro" ;;
        410) value="Indian/Kerguelen" ;;
        411) value="Indian/Mahe" ;;
        412) value="Indian/Maldives" ;;
        413) value="Indian/Mauritius" ;;
        414) value="Indian/Mayotte" ;;
        415) value="Indian/Reunion" ;;
        416) value="Pacific/Apia" ;;
        417) value="Pacific/Auckland" ;;
        418) value="Pacific/Bougainville" ;;
        419) value="Pacific/Chatham" ;;
        420) value="Pacific/Chuuk" ;;
        421) value="Pacific/Easter" ;;
        422) value="Pacific/Efate" ;;
        423) value="Pacific/Enderbury" ;;
        424) value="Pacific/Fakaofo" ;;
        425) value="Pacific/Fiji" ;;
        426) value="Pacific/Funafuti" ;;
        427) value="Pacific/Galapagos" ;;
        428) value="Pacific/Gambier" ;;
        429) value="Pacific/Guadalcanal" ;;
        430) value="Pacific/Guam" ;;
        431) value="Pacific/Honolulu" ;;
        432) value="Pacific/Kiritimati" ;;
        433) value="Pacific/Kosrae" ;;
        434) value="Pacific/Kwajalein" ;;
        435) value="Pacific/Majuro" ;;
        436) value="Pacific/Marquesas" ;;
        437) value="Pacific/Midway" ;;
        438) value="Pacific/Nauru" ;;
        439) value="Pacific/Niue" ;;
        440) value="Pacific/Norfolk" ;;
        441) value="Pacific/Noumea" ;;
        442) value="Pacific/Pago Pago" ;;
        443) value="Pacific/Palau" ;;
        444) value="Pacific/Pitcairn" ;;
        445) value="Pacific/Pohnpei" ;;
        446) value="Pacific/Port Moresby" ;;
        447) value="Pacific/Rarotonga" ;;
        448) value="Pacific/Saipan" ;;
        449) value="Pacific/Tahiti" ;;
        450) value="Pacific/Tarawa" ;;
        451) value="Pacific/Tongatapu" ;;
        452) value="Pacific/Wake" ;;
        453) value="Pacific/Wallis" ;;
    esac
    uci set system.@system[0].zonename="$value"
    exit
}
function write_APSysSNMPServer() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    uci set snmpd.@agent[0].enabled="$((WRITE_VALUE-1))"
    exit
}
function write_APSysWriteCommunity() {
    [ "$WRITE_TYPE" != "string" ] && err_wrong_type
    local ro_community=$(uci -q get snmpd.ro_community.name)
    [ -z "$ro_community" ] && [ "$WRITE_VALUE" == "" ] && err_wrong_value
    [ -n "$(echo "$WRITE_VALUE" | grep ' ')" -o -n "$(echo "$WRITE_VALUE" | grep '"')" -o -n "$(echo "$WRITE_VALUE" | grep "'")" ] && err_wrong_value
    uci set snmpd.rw_community.name="$WRITE_VALUE"
    exit
}
function write_APSysReadCommunity() {
    [ "$WRITE_TYPE" != "string" ] && err_wrong_type
    local community=$(uci -q get snmpd.rw_community.name)
    [ -z "$community" ] && [ "$WRITE_VALUE" == "" ] && err_wrong_value
    [ -n "$(echo "$WRITE_VALUE" | grep ' ')" -o -n "$(echo "$WRITE_VALUE" | grep '"')" -o -n "$(echo "$WRITE_VALUE" | grep "'")" ] && err_wrong_value
    uci set snmpd.ro_community.name="$WRITE_VALUE"
    exit
}
function write_APSysIPv6ReadCommunity() {
    [ "$WRITE_TYPE" != "string" ] && err_wrong_type
    local community6=$(uci -q get snmpd.rw_community6.name)
    [ -z "$community6" ] && [ "$WRITE_VALUE" == "" ] && err_wrong_value
    [ -n "$(echo "$WRITE_VALUE" | grep ' ')" -o -n "$(echo "$WRITE_VALUE" | grep '"')" -o -n "$(echo "$WRITE_VALUE" | grep "'")" ] && err_wrong_value
    uci set snmpd.ro_community6.name="$WRITE_VALUE"
    exit
}
function write_APSysIPv6WriteCommunity() {
    [ "$WRITE_TYPE" != "string" ] && err_wrong_type
    local ro_community6=$(uci -q get snmpd.ro_community6.name)
    [ -z "$ro_community6" ] && [ "$WRITE_VALUE" == "" ] && err_wrong_value
    [ -n "$(echo "$WRITE_VALUE" | grep ' ')" -o -n "$(echo "$WRITE_VALUE" | grep '"')" -o -n "$(echo "$WRITE_VALUE" | grep "'")" ] && err_wrong_value
    uci set snmpd.rw_community6.name="$WRITE_VALUE"
    exit
}
function write_APSysmDNS() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    uci set uci get umdns.@umdns[0].enabled="$((WRITE_VALUE-1))"
    exit
}
function write_APSysLLDP() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    uci set lldp.settings.enabled="$((WRITE_VALUE-1))"
    if [ $WRITE_VALUE -eq 1 ]; then
        uci del lldp.settings.tx_interval
        uci del lldp.settings.tx_hold
    fi
    exit
}
function write_APSysTxInterval() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt 5 ] || [ "$WRITE_VALUE" -gt 32768 ] && err_wrong_value
    uci set lldp.settings.tx_interval="$WRITE_VALUE"
    exit
}
function write_APSysTxHold() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt 2 ] || [ "$WRITE_VALUE" -gt 10 ] && err_wrong_value
    uci set lldp.settings.tx_hold="$WRITE_VALUE"
    exit
}
function write_APSysiBeacon() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    uci set ibeacon.ibeacon.enabled="$((WRITE_VALUE-1))"

    if [ $WRITE_TYPE -eq 1 ]; then
        uci del ibeacon.ibeacon.uuid
        uci del ibeacon.ibeacon.major
        uci del ibeacon.ibeacon.minor
    fi
    exit
}
function write_APSysiBeaconMinor() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt 0 ] || [ "$WRITE_VALUE" -gt 65535 ] && err_wrong_value
    local iBeacon=$(uci get ibeacon.ibeacon.enabled)
    [ $iBeacon -eq 1 ] && uci set ibeacon.ibeacon.minor="$WRITE_VALUE"
    exit
}
function write_APSysiBeaconMajor() {
    [ "$WRITE_TYPE" != "" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt 0 ] || [ "$WRITE_VALUE" -gt 65535 ] && err_wrong_value
    local iBeacon=$(uci get ibeacon.ibeacon.enabled)
    [ $iBeacon -eq 1 ] && uci set ibeacon.ibeacon.major="$WRITE_VALUE"
    exit
}
function write_APSysiBeaconUUID() {
    [ "$WRITE_TYPE" != "string" ] && err_wrong_type
    local iBeacon=$(uci get ibeacon.ibeacon.enabled)
    [ $iBeacon -eq 1 ] && uci set ibeacon.ibeacon.uuid="$WRITE_VALUE"
    exit
}
function uci_revert_all() {
    for config in /etc/config/*; do
        uci revert $(basename ${config})
    done
}
function write_APSysCommitOrRevert() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    if [ "$WRITE_VALUE" == "1" ]; then
        uci commit
	reload_config
    elif [ "$WRITE_VALUE" == "2" ]; then
        uci_revert_all
    fi
    exit
}

function output() {
    local RET_OID="$1"

    case "$RET_OID" in
#------------------------------System Settings---------------------------------
        $PLACE.1.1.0) #APSysHostName
            [ "$OP" == "-s" ] && write_APSysHostName
            value="$(uci get acn.settings.name)"
            echo "$RET_OID"
            echo "string"; echo $value; exit 0 ;;
        $PLACE.1.2.0) #APSysManagement (APSysManagement=0)
            [ "$OP" == "-s" ] && write_APSysManagement
            value="$(($(uci get acn.mgmt.management)+1))"
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.1.3.0) #APSysEnableAgent (APSysManagement=1)
            [ "$OP" == "-s" ] && write_APSysEnableAgent
            local Management=$(uci get acn.mgmt.management)
            value=1
            [ "$Management" -eq 1 ] && value="$(($(uci get acn.mgmt.enabled)+1))"
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.1.4.0) #APSysRegistrationURL
            [ "$OP" == "-s" ] && write_APSysRegistrationURL
            local Management=$(uci get acn.mgmt.management)
            value=""
            [ "$Management" -eq 1 ] && value="$(uci get acn.register.url)"
            echo "$RET_OID"
            echo "string"; echo $value; exit 0 ;;
        $PLACE.1.5.0) #APSysCAPWAP (APSysManagement=2)
            [ "$OP" == "-s" ] && write_APSysCAPWAP
            local Management=$(uci get acn.mgmt.management)
            value=1
            [ "$Management" -eq 2 ] && value="$(($(uci get acn.capwap.state)+1))"
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.1.6.0) #APSysDNSSRVDiscovery
            [ "$OP" == "-s" ] && write_APSysDNSSRVDiscovery
            local Management=$(uci get acn.mgmt.management)
            value=1
            [ "$Management" -eq 2 ] && value="$(($(uci get acn.capwap.dns_srv)+1))"
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.1.7.0) #APSysDomainNameSuffix
            [ "$OP" == "-s" ] && write_APSysDomainNameSuffix
            local Management=$(uci get acn.mgmt.management)
            local DNSSRVDiscovery=$(uci get acn.capwap.dns_srv)
            value=""
            [ "$Management" -eq 2 ] && [ $DNSSRVDiscovery -eq 1 ] && value="$(uci get acn.capwap.srv_suffix)"
            echo "$RET_OID"
            echo "string"; echo $value; exit 0 ;;
        $PLACE.1.8.0) #APSysDHCPOptDiscovery
            [ "$OP" == "-s" ] && write_APSysDHCPOptDiscovery
            local Management=$(uci get acn.mgmt.management)
            value=1
            [ "$Management" -eq 2 ] && value="$(($(uci get acn.capwap.dhcp_opt)+1))"
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.1.9.0) #APSysBroadcastDiscovery
            [ "$OP" == "-s" ] && write_APSysBroadcastDiscovery
            local Management=$(uci get acn.mgmt.management)
            value=1
            [ "$Management" -eq 2 ] && value="$(uci get acn.capwap.broadcast)"
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.1.10.0) #APSysMulticastDiscovery
            [ "$OP" == "-s" ] && write_APSysMulticastDiscovery
            local Management=$(uci get acn.mgmt.management)
            value=1
            [ "$Management" -eq 2 ] && value="$(uci get acn.capwap.multicast)"
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.1.11.0) #APSysStaticDiscovery
            [ "$OP" == "-s" ] && write_APSysStaticDiscovery
            local Management=$(uci get acn.mgmt.management)
            value=1
            [ "$Management" -eq 2 ] && value="$(($(uci get acn.capwap.unicast)+1))"
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.1.12.*) #APSysACAddress
            [ "$OP" == "-s" ] && write_APSysACAddress
            local Management=$(uci get acn.mgmt.management)
            value=""

            if [ "$Management" -eq 2 ]; then
                local num=$(echo $RET_OID | cut -d "." -f 18)
                local AC_addr=$(uci show acn | grep =capwap_ac | wc -l)

                if [ -n "$AC_addr" ]; then
                    if [ "$num" -le "$AC_addr" ]; then
                        value="$(uci get acn.@capwap_ac[$((num-1))].ip), \
                                $(uci get acn.@capwap_ac[$((num-1))].remark)"
                    fi
                fi
            fi
            echo "$RET_OID"
            echo "string"; echo $value; exit 0 ;;
        $PLACE.1.13.0) #APSysLocalTime
            [ "$OP" == "-s" ] && err_not_writeable
            value="$(date)"
            echo "$RET_OID"
            echo "string"; echo $value; exit 0 ;;
        $PLACE.1.14.0) #APSysBootRetries
            [ "$OP" == "-s" ] && write_APSysBootRetries
            value="$(uci get acn.settings.bootmaxcnt)"
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.1.15.0) #APSysMSPMode
            [ "$OP" == "-s" ] && write_APSysMSPMode
            value="$(($(uci get acn.settings.msp_enable)+1))"
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
    #------------------------------Maintenance-------------------------------------
        $PLACE.2.1.0) #APSysReboot
            [ "$OP" == "-s" ] && write_APSysReboot
            value=0
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.2.2.0) #APSysReset
            [ "$OP" == "-s" ] && write_APSysReset
            value=0
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
    #------------------------------User Accounts-----------------------------------
        $PLACE.3.*) #APSysUserAccounts
            [ "$OP" == "-s" ] && write_APSysUserAccounts
            local num=$(echo $RET_OID | cut -d "." -f 17)
#			local item=$(echo $RET_OID | cut -d "." -f 16)
            local account=$(uci show users | grep =login | wc -l)
            value=""

            if [ "$num" -le "$account" ]; then
                value="$(($(uci get users.@login[$((num-1))].enabled)+1)), \
                        $(uci get users.@login[$((num-1))].name), \
                        $(uci get users.@login[$((num-1))].passwd)"
            fi
            echo "$RET_OID"
            echo "string"; echo $value; exit 0 ;;
    #------------------------------Services----------------------------------------
        $PLACE.4.1.0) #APSysSSHServer
            [ "$OP" == "-s" ] && write_APSysSSHServer
            value="$(($(uci get dropbear.@dropbear[0].enable)+1))"
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.4.2.0) #APSysSSHPort
            [ "$OP" == "-s" ] && write_APSysSSHPort
            local SSHServer=$(uci get dropbear.@dropbear[0].enable)
            value=""
            [ "$SSHServer" -eq 1 ] && value="$(uci get dropbear.@dropbear[0].Port)"
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.4.3.0) #APSysAllowSSH
            [ "$OP" == "-s" ] && write_APSysAllowSSH
            allow=$(uci show firewall | grep Allow-SSH)
            value=1
            [ -n "$allow" ] && value=2
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.4.4.0) #APSysTelnetServer
            [ "$OP" == "-s" ] && write_APSysTelnetServer
            value="$(($(uci get telnetd.@telnetd[0].enable)+1))"
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.4.5.0) #APSysTelnetPort
            [ "$OP" == "-s" ] && write_APSysTelnetPort
            local TelnetServer=$(uci get telnetd.@telnetd[0].enable)
            value=""
            [ "$TelnetServer" -eq 1 ] && value="$(uci get telnetd.@telnetd[0].Port)"
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.4.6.0) #APSysAllowTelnet
            [ "$OP" == "-s" ] && write_APSysAllowTelnet
            allow=$(uci show firewall | grep Allow-Telnet)
            value=1
            [ -n "$allow" ] && value=2
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.4.7.0) #APSysHttpPort
            [ "$OP" == "-s" ] && write_APSysHttpPort
            value="$(uci get uhttpd.main.listen_http)"
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.4.8.0) #APSysAllowHttp
            [ "$OP" == "-s" ] && write_APSysAllowHttp
            allow=$(uci show firewall | grep Allow-WEBUI | grep Allow-WEBUI-secure -v)
            value=1
            [ -n "$allow" ] && value=2
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.4.9.0) #APSysHttpsPort
            [ "$OP" == "-s" ] && write_APSysHttpsPort
            value="$(uci get uhttpd.main.listen_https)"
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.4.10.0) #APSysAllowHttps
            [ "$OP" == "-s" ] && write_APSysAllowHttps
            allow=$(uci show firewall | grep Allow-WEBUI-secure)
            value=1
            [ -n "$allow" ] && value=2
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.4.11.0) #APSysRemoteLog
            [ "$OP" == "-s" ] && write_APSysRemoteLog
            value=$(($(uci get system.@system[0].log_remote)+1))
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.4.12.0) #APSysLogTrackConnections
            [ "$OP" == "-s" ] && write_APSysLogTrackConnections
            RemoteLog=$(uci get system.@system[0].log_remote)
            value=1
            [ "$RemoteLog" -eq 1 ] && value=$(($(uci get system.@system[0].log_conntrackd_enable)+1))
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.4.13.0) #APSysLogServerIp
            [ "$OP" == "-s" ] && write_APSysLogServerIp
            RemoteLog=$(uci get system.@system[0].log_remote)
            value=""
            if [ "$RemoteLog" -eq 1 ]; then
                value="$(uci get system.@system[0].log_ip)"
                echo "$RET_OID"
                echo "ipaddress"; echo $value; exit 0
            else
                echo "$RET_OID"
                echo "string"; echo $value; exit 0
            fi ;;
        $PLACE.4.14.0) #APSysLogServerPort
            [ "$OP" == "-s" ] && write_APSysLogServerPort
            RemoteLog=$(uci get system.@system[0].log_remote)
            value=""
            [ "$RemoteLog" -eq 1 ] && value=$(uci get system.@system[0].log_port)
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.4.15.0) #APSysLogPrefix
            [ "$OP" == "-s" ] && write_APSysLogPrefix
            RemoteLog=$(uci get system.@system[0].log_remote)
            value=""
            [ "$RemoteLog" -eq 1 ] && value=$(uci get system.@system[0].log_prefix)
            echo "$RET_OID"
            echo "string"; echo $value; exit 0 ;;
        $PLACE.4.16.0) #APSysNtpService
            [ "$OP" == "-s" ] && write_APSysNtpService
            value=$(($(uci get system.ntp.enable_server)+1))
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.4.17.0) #APSysNtpServers
            [ "$OP" == "-s" ] && write_APSysNtpServers
            value=$(uci get system.ntp.server)
            echo "$RET_OID"
            echo "string"; echo $value; exit 0 ;;
        $PLACE.4.18.0) #APSysTimezone
            [ "$OP" == "-s" ] && write_APSysTimezone
            zonename=$(uci get system.@system[0].zonename)
            case "${zonename}" in
                "UTC") value=1 ;;
                "Africa/Abidjan") value=2 ;;
                "Africa/Accra") value=3 ;;
                "Africa/Addis Ababa") value=4 ;;
                "Africa/Algiers") value=5 ;;
                "Africa/Asmara") value=6 ;;
                "Africa/Bamako") value=7 ;;
                "Africa/Bangui") value=8 ;;
                "Africa/Banjul") value=9 ;;
                "Africa/Bissau") value=10 ;;
                "Africa/Blantyre") value=11 ;;
                "Africa/Brazzaville") value=12 ;;
                "Africa/Bujumbura") value=13 ;;
                "Africa/Cairo") value=14 ;;
                "Africa/Casablanca") value=15 ;;
                "Africa/Ceuta") value=16 ;;
                "Africa/Conakry") value=17 ;;
                "Africa/Dakar") value=18 ;;
                "Africa/Dar es Salaam") value=19 ;;
                "Africa/Djibouti") value=20 ;;
                "Africa/Douala") value=21 ;;
                "Africa/El Aaiun") value=22 ;;
                "Africa/Freetown") value=23 ;;
                "Africa/Gaborone") value=24 ;;
                "Africa/Harare") value=25 ;;
                "Africa/Johannesburg") value=26 ;;
                "Africa/Juba") value=27 ;;
                "Africa/Kampala") value=28 ;;
                "Africa/Khartoum") value=29 ;;
                "Africa/Kigali") value=30 ;;
                "Africa/Kinshasa") value=31 ;;
                "Africa/Lagos") value=32 ;;
                "Africa/Libreville") value=33 ;;
                "Africa/Lome") value=34 ;;
                "Africa/Luanda") value=35 ;;
                "Africa/Lubumbashi") value=36 ;;
                "Africa/Lusaka") value=37 ;;
                "Africa/Malabo") value=38 ;;
                "Africa/Maputo") value=39 ;;
                "Africa/Maseru") value=40 ;;
                "Africa/Mbabane") value=41 ;;
                "Africa/Mogadishu") value=42 ;;
                "Africa/Monrovia") value=43 ;;
                "Africa/Nairobi") value=44 ;;
                "Africa/Ndjamena") value=45 ;;
                "Africa/Niamey") value=46 ;;
                "Africa/Nouakchott") value=47 ;;
                "Africa/Ouagadougou") value=48 ;;
                "Africa/Porto-Novo") value=49 ;;
                "Africa/Sao Tome") value=50 ;;
                "Africa/Tripoli") value=51 ;;
                "Africa/Tunis") value=52 ;;
                "Africa/Windhoek") value=53 ;;
                "America/Adak") value=54 ;;
                "America/Anchorage") value=55 ;;
                "America/Anguilla") value=56 ;;
                "America/Antigua") value=57 ;;
                "America/Araguaina") value=58 ;;
                "America/Argentina/Buenos Aires") value=59 ;;
                "America/Argentina/Catamarca") value=60 ;;
                "America/Argentina/Cordoba") value=61 ;;
                "America/Argentina/Jujuy") value=62 ;;
                "America/Argentina/La Rioja") value=63 ;;
                "America/Argentina/Mendoza") value=64 ;;
                "America/Argentina/Rio Gallegos") value=65 ;;
                "America/Argentina/Salta") value=66 ;;
                "America/Argentina/San Juan") value=67 ;;
                "America/Argentina/San Luis") value=68 ;;
                "America/Argentina/Tucuman") value=69 ;;
                "America/Argentina/Ushuaia") value=70 ;;
                "America/Aruba") value=71 ;;
                "America/Asuncion") value=72 ;;
                "America/Atikokan") value=73 ;;
                "America/Bahia") value=74 ;;
                "America/Bahia Banderas") value=75 ;;
                "America/Barbados") value=76 ;;
                "America/Belem") value=77 ;;
                "America/Belize") value=78 ;;
                "America/Blanc-Sablon") value=79 ;;
                "America/Boa Vista") value=80 ;;
                "America/Bogota") value=81 ;;
                "America/Boise") value=82 ;;
                "America/Cambridge Bay") value=83 ;;
                "America/Campo Grande") value=84 ;;
                "America/Cancun") value=85 ;;
                "America/Caracas") value=86 ;;
                "America/Cayenne") value=87 ;;
                "America/Cayman") value=88 ;;
                "America/Chicago") value=89 ;;
                "America/Chihuahua") value=90 ;;
                "America/Costa Rica") value=91 ;;
                "America/Creston") value=92 ;;
                "America/Cuiaba") value=93 ;;
                "America/Curacao") value=94 ;;
                "America/Danmarkshavn") value=95 ;;
                "America/Dawson") value=96 ;;
                "America/Dawson Creek") value=97 ;;
                "America/Denver") value=98 ;;
                "America/Detroit") value=99 ;;
                "America/Dominica") value=100 ;;
                "America/Edmonton") value=101 ;;
                "America/Eirunepe") value=102 ;;
                "America/El Salvador") value=103 ;;
                "America/Fort Nelson") value=104 ;;
                "America/Fortaleza") value=105 ;;
                "America/Glace Bay") value=106 ;;
                "America/Goose Bay") value=107 ;;
                "America/Grand Turk") value=108 ;;
                "America/Grenada") value=109 ;;
                "America/Guadeloupe") value=110 ;;
                "America/Guatemala") value=111 ;;
                "America/Guayaquil") value=112 ;;
                "America/Guyana") value=113 ;;
                "America/Halifax") value=114 ;;
                "America/Havana") value=115 ;;
                "America/Hermosillo") value=116 ;;
                "America/Indiana/Indianapolis") value=117 ;;
                "America/Indiana/Knox") value=118 ;;
                "America/Indiana/Marengo") value=119 ;;
                "America/Indiana/Petersburg") value=120 ;;
                "America/Indiana/Tell City") value=121 ;;
                "America/Indiana/Vevay") value=122 ;;
                "America/Indiana/Vincennes") value=123 ;;
                "America/Indiana/Winamac") value=124 ;;
                "America/Inuvik") value=125 ;;
                "America/Iqaluit") value=126 ;;
                "America/Jamaica") value=127 ;;
                "America/Juneau") value=128 ;;
                "America/Kentucky/Louisville") value=129 ;;
                "America/Kentucky/Monticello") value=130 ;;
                "America/Kralendijk") value=131 ;;
                "America/La Paz") value=132 ;;
                "America/Lima") value=133 ;;
                "America/Los Angeles") value=134 ;;
                "America/Lower Princes") value=135 ;;
                "America/Maceio") value=136 ;;
                "America/Managua") value=137 ;;
                "America/Manaus") value=138 ;;
                "America/Marigot") value=139 ;;
                "America/Martinique") value=140 ;;
                "America/Matamoros") value=141 ;;
                "America/Mazatlan") value=142 ;;
                "America/Menominee") value=143 ;;
                "America/Merida") value=144 ;;
                "America/Metlakatla") value=145 ;;
                "America/Mexico City") value=146 ;;
                "America/Miquelon") value=147 ;;
                "America/Moncton") value=148 ;;
                "America/Monterrey") value=149 ;;
                "America/Montevideo") value=150 ;;
                "America/Montserrat") value=151 ;;
                "America/Nassau") value=152 ;;
                "America/New York") value=153 ;;
                "America/Nipigon") value=154 ;;
                "America/Nome") value=155 ;;
                "America/Noronha") value=156 ;;
                "America/North Dakota/Beulah") value=157 ;;
                "America/North Dakota/Center") value=158 ;;
                "America/North Dakota/New Salem") value=159 ;;
                "America/Nuuk") value=160 ;;
                "America/Ojinaga") value=161 ;;
                "America/Panama") value=162 ;;
                "America/Pangnirtung") value=163 ;;
                "America/Paramaribo") value=164 ;;
                "America/Phoenix") value=165 ;;
                "America/Port of Spain") value=166 ;;
                "America/Port-au-Prince") value=167 ;;
                "America/Porto Velho") value=168 ;;
                "America/Puerto Rico") value=169 ;;
                "America/Punta Arenas") value=170 ;;
                "America/Rainy River") value=171 ;;
                "America/Rankin Inlet") value=172 ;;
                "America/Recife") value=173 ;;
                "America/Regina") value=174 ;;
                "America/Resolute") value=175 ;;
                "America/Rio Branco") value=176 ;;
                "America/Santarem") value=177 ;;
                "America/Santiago") value=178 ;;
                "America/Santo Domingo") value=179 ;;
                "America/Sao Paulo") value=180 ;;
                "America/Scoresbysund") value=181 ;;
                "America/Sitka") value=182 ;;
                "America/St Barthelemy") value=183 ;;
                "America/St Johns") value=184 ;;
                "America/St Kitts") value=185 ;;
                "America/St Lucia") value=186 ;;
                "America/St Thomas") value=187 ;;
                "America/St Vincent") value=188 ;;
                "America/Swift Current") value=189 ;;
                "America/Tegucigalpa") value=190 ;;
                "America/Thule") value=191 ;;
                "America/Thunder Bay") value=192 ;;
                "America/Tijuana") value=193 ;;
                "America/Toronto") value=194 ;;
                "America/Tortola") value=195 ;;
                "America/Vancouver") value=196 ;;
                "America/Whitehorse") value=197 ;;
                "America/Winnipeg") value=198 ;;
                "America/Yakutat") value=199 ;;
                "America/Yellowknife") value=200 ;;
                "Antarctica/Casey") value=201 ;;
                "Antarctica/Davis") value=202 ;;
                "Antarctica/DumontDUrville") value=203 ;;
                "Antarctica/Macquarie") value=204 ;;
                "Antarctica/Mawson") value=205 ;;
                "Antarctica/McMurdo") value=206 ;;
                "Antarctica/Palmer") value=207 ;;
                "Antarctica/Rothera") value=208 ;;
                "Antarctica/Syowa") value=209 ;;
                "Antarctica/Troll") value=210 ;;
                "Antarctica/Vostok") value=211 ;;
                "Arctic/Longyearbyen") value=212 ;;
                "Asia/Aden") value=213 ;;
                "Asia/Almaty") value=214 ;;
                "Asia/Amman") value=215 ;;
                "Asia/Anadyr") value=216 ;;
                "Asia/Aqtau") value=217 ;;
                "Asia/Aqtobe") value=218 ;;
                "Asia/Ashgabat") value=219 ;;
                "Asia/Atyrau") value=220 ;;
                "Asia/Baghdad") value=221 ;;
                "Asia/Bahrain") value=222 ;;
                "Asia/Baku") value=223 ;;
                "Asia/Bangkok") value=224 ;;
                "Asia/Barnaul") value=225 ;;
                "Asia/Beirut") value=226 ;;
                "Asia/Bishkek") value=227 ;;
                "Asia/Brunei") value=228 ;;
                "Asia/Chita") value=229 ;;
                "Asia/Choibalsan") value=230 ;;
                "Asia/Colombo") value=231 ;;
                "Asia/Damascus") value=232 ;;
                "Asia/Dhaka") value=233 ;;
                "Asia/Dili") value=234 ;;
                "Asia/Dubai") value=235 ;;
                "Asia/Dushanbe") value=236 ;;
                "Asia/Famagusta") value=237 ;;
                "Asia/Gaza") value=238 ;;
                "Asia/Hebron") value=239 ;;
                "Asia/Ho Chi Minh") value=240 ;;
                "Asia/Hong Kong") value=241 ;;
                "Asia/Hovd") value=242 ;;
                "Asia/Irkutsk") value=243 ;;
                "Asia/Jakarta") value=244 ;;
                "Asia/Jayapura") value=245 ;;
                "Asia/Jerusalem") value=246 ;;
                "Asia/Kabul") value=247 ;;
                "Asia/Kamchatka") value=248 ;;
                "Asia/Karachi") value=249 ;;
                "Asia/Kathmandu") value=250 ;;
                "Asia/Khandyga") value=251 ;;
                "Asia/Kolkata") value=252 ;;
                "Asia/Krasnoyarsk") value=253 ;;
                "Asia/Kuala Lumpur") value=254 ;;
                "Asia/Kuching") value=255 ;;
                "Asia/Kuwait") value=256 ;;
                "Asia/Macau") value=257 ;;
                "Asia/Magadan") value=258 ;;
                "Asia/Makassar") value=259 ;;
                "Asia/Manila") value=260 ;;
                "Asia/Muscat") value=261 ;;
                "Asia/Nicosia") value=262 ;;
                "Asia/Novokuznetsk") value=263 ;;
                "Asia/Novosibirsk") value=264 ;;
                "Asia/Omsk") value=265 ;;
                "Asia/Oral") value=266 ;;
                "Asia/Phnom Penh") value=267 ;;
                "Asia/Pontianak") value=268 ;;
                "Asia/Pyongyang") value=269 ;;
                "Asia/Qatar") value=270 ;;
                "Asia/Qostanay") value=271 ;;
                "Asia/Qyzylorda") value=272 ;;
                "Asia/Riyadh") value=273 ;;
                "Asia/Sakhalin") value=274 ;;
                "Asia/Samarkand") value=275 ;;
                "Asia/Seoul") value=276 ;;
                "Asia/Shanghai") value=277 ;;
                "Asia/Singapore") value=278 ;;
                "Asia/Srednekolymsk") value=279 ;;
                "Asia/Taipei") value=280 ;;
                "Asia/Tashkent") value=281 ;;
                "Asia/Tbilisi") value=282 ;;
                "Asia/Tehran") value=283 ;;
                "Asia/Thimphu") value=284 ;;
                "Asia/Tokyo") value=285 ;;
                "Asia/Tomsk") value=286 ;;
                "Asia/Ulaanbaatar") value=287 ;;
                "Asia/Urumqi") value=288 ;;
                "Asia/Ust-Nera") value=289 ;;
                "Asia/Vientiane") value=290 ;;
                "Asia/Vladivostok") value=291 ;;
                "Asia/Yakutsk") value=292 ;;
                "Asia/Yangon") value=293 ;;
                "Asia/Yekaterinburg") value=294 ;;
                "Asia/Yerevan") value=295 ;;
                "Atlantic/Azores") value=296 ;;
                "Atlantic/Bermuda") value=297 ;;
                "Atlantic/Canary") value=298 ;;
                "Atlantic/Cape Verde") value=299 ;;
                "Atlantic/Faroe") value=300 ;;
                "Atlantic/Madeira") value=301 ;;
                "Atlantic/Reykjavik") value=302 ;;
                "Atlantic/South Georgia") value=303 ;;
                "Atlantic/St Helena") value=304 ;;
                "Atlantic/Stanley") value=305 ;;
                "Australia/Adelaide") value=306 ;;
                "Australia/Brisbane") value=307 ;;
                "Australia/Broken Hill") value=308 ;;
                "Australia/Currie") value=309 ;;
                "Australia/Darwin") value=310 ;;
                "Australia/Eucla") value=311 ;;
                "Australia/Hobart") value=312 ;;
                "Australia/Lindeman") value=313 ;;
                "Australia/Lord Howe") value=314 ;;
                "Australia/Melbourne") value=315 ;;
                "Australia/Perth") value=316 ;;
                "Australia/Sydney") value=317 ;;
                "Etc/GMT") value=318 ;;
                "Etc/GMT+1") value=319 ;;
                "Etc/GMT+10") value=320 ;;
                "Etc/GMT+11") value=321 ;;
                "Etc/GMT+12") value=322 ;;
                "Etc/GMT+2") value=323 ;;
                "Etc/GMT+3") value=324 ;;
                "Etc/GMT+4") value=325 ;;
                "Etc/GMT+5") value=326 ;;
                "Etc/GMT+6") value=327 ;;
                "Etc/GMT+7") value=328 ;;
                "Etc/GMT+8") value=329 ;;
                "Etc/GMT+9") value=330 ;;
                "Etc/GMT-1") value=331 ;;
                "Etc/GMT-10") value=332 ;;
                "Etc/GMT-11") value=333 ;;
                "Etc/GMT-12") value=334 ;;
                "Etc/GMT-13") value=335 ;;
                "Etc/GMT-14") value=336 ;;
                "Etc/GMT-2") value=337 ;;
                "Etc/GMT-3") value=338 ;;
                "Etc/GMT-4") value=339 ;;
                "Etc/GMT-5") value=340 ;;
                "Etc/GMT-6") value=341 ;;
                "Etc/GMT-7") value=342 ;;
                "Etc/GMT-8") value=343 ;;
                "Etc/GMT-9") value=344 ;;
                "Europe/Amsterdam") value=345 ;;
                "Europe/Andorra") value=346 ;;
                "Europe/Astrakhan") value=347 ;;
                "Europe/Athens") value=348 ;;
                "Europe/Belgrade") value=349 ;;
                "Europe/Berlin") value=350 ;;
                "Europe/Bratislava") value=351 ;;
                "Europe/Brussels") value=352 ;;
                "Europe/Bucharest") value=353 ;;
                "Europe/Budapest") value=354 ;;
                "Europe/Busingen") value=355 ;;
                "Europe/Chisinau") value=356 ;;
                "Europe/Copenhagen") value=357 ;;
                "Europe/Dublin") value=358 ;;
                "Europe/Gibraltar") value=359 ;;
                "Europe/Guernsey") value=360 ;;
                "Europe/Helsinki") value=361 ;;
                "Europe/Isle of Man") value=362 ;;
                "Europe/Istanbul") value=363 ;;
                "Europe/Jersey") value=364 ;;
                "Europe/Kaliningrad") value=365 ;;
                "Europe/Kiev") value=366 ;;
                "Europe/Kirov") value=367 ;;
                "Europe/Lisbon") value=368 ;;
                "Europe/Ljubljana") value=369 ;;
                "Europe/London") value=370 ;;
                "Europe/Luxembourg") value=371 ;;
                "Europe/Madrid") value=372 ;;
                "Europe/Malta") value=373 ;;
                "Europe/Mariehamn") value=374 ;;
                "Europe/Minsk") value=375 ;;
                "Europe/Monaco") value=376 ;;
                "Europe/Moscow") value=377 ;;
                "Europe/Oslo") value=378 ;;
                "Europe/Paris") value=379 ;;
                "Europe/Podgorica") value=380 ;;
                "Europe/Prague") value=381 ;;
                "Europe/Riga") value=382 ;;
                "Europe/Rome") value=383 ;;
                "Europe/Samara") value=384 ;;
                "Europe/San Marino") value=385 ;;
                "Europe/Sarajevo") value=386 ;;
                "Europe/Saratov") value=387 ;;
                "Europe/Simferopol") value=388 ;;
                "Europe/Skopje") value=389 ;;
                "Europe/Sofia") value=390 ;;
                "Europe/Stockholm") value=391 ;;
                "Europe/Tallinn") value=392 ;;
                "Europe/Tirane") value=393 ;;
                "Europe/Ulyanovsk") value=394 ;;
                "Europe/Uzhgorod") value=395 ;;
                "Europe/Vaduz") value=396 ;;
                "Europe/Vatican") value=397 ;;
                "Europe/Vienna") value=398 ;;
                "Europe/Vilnius") value=399 ;;
                "Europe/Volgograd") value=400 ;;
                "Europe/Warsaw") value=401 ;;
                "Europe/Zagreb") value=402 ;;
                "Europe/Zaporozhye") value=403 ;;
                "Europe/Zurich") value=404 ;;
                "Indian/Antananarivo") value=405 ;;
                "Indian/Chagos") value=406 ;;
                "Indian/Christmas") value=407 ;;
                "Indian/Cocos") value=408 ;;
                "Indian/Comoro") value=409 ;;
                "Indian/Kerguelen") value=410 ;;
                "Indian/Mahe") value=411 ;;
                "Indian/Maldives") value=412 ;;
                "Indian/Mauritius") value=413 ;;
                "Indian/Mayotte") value=414 ;;
                "Indian/Reunion") value=415 ;;
                "Pacific/Apia") value=416 ;;
                "Pacific/Auckland") value=417 ;;
                "Pacific/Bougainville") value=418 ;;
                "Pacific/Chatham") value=419 ;;
                "Pacific/Chuuk") value=420 ;;
                "Pacific/Easter") value=421 ;;
                "Pacific/Efate") value=422 ;;
                "Pacific/Enderbury") value=423 ;;
                "Pacific/Fakaofo") value=424 ;;
                "Pacific/Fiji") value=425 ;;
                "Pacific/Funafuti") value=426 ;;
                "Pacific/Galapagos") value=427 ;;
                "Pacific/Gambier") value=428 ;;
                "Pacific/Guadalcanal") value=429 ;;
                "Pacific/Guam") value=430 ;;
                "Pacific/Honolulu") value=431 ;;
                "Pacific/Kiritimati") value=432 ;;
                "Pacific/Kosrae") value=433 ;;
                "Pacific/Kwajalein") value=434 ;;
                "Pacific/Majuro") value=435 ;;
                "Pacific/Marquesas") value=436 ;;
                "Pacific/Midway") value=437 ;;
                "Pacific/Nauru") value=438 ;;
                "Pacific/Niue") value=439 ;;
                "Pacific/Norfolk") value=440 ;;
                "Pacific/Noumea") value=441 ;;
                "Pacific/Pago Pago") value=442 ;;
                "Pacific/Palau") value=443 ;;
                "Pacific/Pitcairn") value=444 ;;
                "Pacific/Pohnpei") value=445 ;;
                "Pacific/Port Moresby") value=446 ;;
                "Pacific/Rarotonga") value=447 ;;
                "Pacific/Saipan") value=448 ;;
                "Pacific/Tahiti") value=449 ;;
                "Pacific/Tarawa") value=450 ;;
                "Pacific/Tongatapu") value=451 ;;
                "Pacific/Wake") value=452 ;;
                "Pacific/Wallis") value=453 ;;
            esac
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.4.19.0) #APSysSNMPServer
            [ "$OP" == "-s" ] && write_APSysSNMPServer
            value=$(($(uci get snmpd.@agent[0].enabled)+1))
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.4.20.0) #APSysWriteCommunity
            [ "$OP" == "-s" ] && write_APSysWriteCommunity
            value=$(uci get snmpd.rw_community.name)
            echo "$RET_OID"
            echo "string"; echo $value; exit 0 ;;
        $PLACE.4.21.0) #APSysmDNS
            [ "$OP" == "-s" ] && write_APSysmDNS
            value=$(($(uci get umdns.@umdns[0].enabled)+1))
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.4.22.0) #APSysLLDP
            [ "$OP" == "-s" ] && write_APSysLLDP
            value=$(($(uci get lldp.settings.enabled)+1))
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.4.23.0) #APSysTxInterval
            [ "$OP" == "-s" ] && write_APSysTxInterval
            LLDP=$(uci get lldp.settings.enabled)
            value=""
            [ "$LLDP" -eq 1 ] && value=$(uci get lldp.settings.tx_interval)
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.4.24.0) #APSysTxHold
            [ "$OP" == "-s" ] && write_APSysTxHold
            LLDP=$(uci get lldp.settings.enabled)
            value=""
            [ "$LLDP" -eq 1 ] && value=$(uci get lldp.settings.tx_hold)
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.4.25.0) #APSysiBeacon
            [ "$OP" == "-s" ] && write_APSysiBeacon
            value=$(($(uci get ibeacon.ibeacon.enabled)+1))
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.4.26.0) #APSysiBeaconMinor
            [ "$OP" == "-s" ] && write_APSysiBeaconMinor
            iBeacon=$(uci get ibeacon.ibeacon.enabled)
            value=""
            [ "$iBeacon" -eq 1 ] && value=$(uci get ibeacon.ibeacon.minor)
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.4.27.0) #APSysiBeaconMajor
            [ "$OP" == "-s" ] && write_APSysiBeaconMajor
            iBeacon=$(uci get ibeacon.ibeacon.enabled)
            value=""
            [ "$iBeacon" -eq 1 ] && value=$(uci get ibeacon.ibeacon.major)
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.4.28.0) #APSysiBeaconUUID
            [ "$OP" == "-s" ] && write_APSysiBeaconUUID
            iBeacon=$(uci get ibeacon.ibeacon.enabled)
            value=""
            [ "$iBeacon" -eq 1 ] && value=$(uci get ibeacon.ibeacon.uuid)
            echo "$RET_OID"
            echo "string"; echo $value; exit 0 ;;
	$PLACE.4.29.0) #APSysReadCommunity
	    [ "$OP" == "-s" ] && write_APSysReadCommunity
	    value=$(uci -q get snmpd.ro_community.name)
	    echo "$RET_OID"
	    echo "string"; echo $value; exit 0 ;;
	$PLACE.4.30.0) #APSysIpv6ReadCommunity
	    [ "$OP" == "-s" ] && write_APSysIpv6ReadCommunity
	    value=$(uci -q get snmpd.ro_community6.name)
	    echo "$RET_OID"
	    echo "string"; echo $value; exit 0 ;;
	$PLACE.4.31.0) #APSysIpv6WriteCommunity
	    [ "$OP" == "-s" ] && write_APSysIpv6WriteCommunity
	    value=$(uci -q get snmpd.rw_community6.name)
	    echo "$RET_OID"
	    echo "string"; echo $value; exit 0 ;;
        $PLACE.5.0) #APSysCommitOrRevert
            [ "$OP" == "-s" ] && write_APSysCommitOrRevert
            value=0
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        *) echo "string"; echo "ack... $RET_OID $REQ"; exit 0 ;;
    esac
}
output $RET
