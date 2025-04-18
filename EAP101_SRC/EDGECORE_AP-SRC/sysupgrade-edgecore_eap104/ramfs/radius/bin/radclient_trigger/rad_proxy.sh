#!/bin/sh
. /conf/etc/profile
[ -z ${Auth_Server_Num} ] && Auth_Server_Num=5

generate_server_name() # ipaddr, port
{
    local ipaddr="${1}"
    local port="${2}"
    local name=$(echo ${ipaddr} | sed "s/\./_/g")"_${port}"

    echo -n "srv_${name}"
}

generate_server() # name, ipaddr, type, port, secret, msg_auth, status_check
{
    local name="${1}"
    local ipaddr="${2}"
    local type="${3}"
    local port="${4}"
    local secret="${5}"
    local msg_auth="${6}"
    local status_check="${7}"

    if [ -n "${name}" -a -n "${type}" -a -n "${ipaddr}" -a -n "${port}" -a -n "${secret}" ]; then
        [ -z "${msg_auth}" ] && msg_auth="yes"
        [ -z "${status_check}" ] && status_check="none"

        echo "home_server ${name} {"
        echo "    type = ${type}"
        echo "    ipaddr = ${ipaddr}"
        echo "    port = ${port}"
        echo "    secret = ${secret}"
        if [ "${status_check}" != "status-server" ]; then
            echo "    status_check = none"
        else
            echo "    status_check = status-server"
        fi
        echo "    require_message_authenticator = ${msg_auth}"
        echo "}"
        echo ""
    fi
}

generate_server_pool() # name, type, server_1, server_2, ...
{
    local name="${1}"
    local type="${2}"
    local tmp=""
    local index=3

    eval tmp='$'${index}
    if [ -n "${name}" -a -n "${type}" -a -n "${tmp}" ]; then
        echo "home_server_pool ${name} {"
        echo "    type = ${type}"
        while [ -n "${tmp}" ]; do
            echo "    home_server = ${tmp}"
            index=$((index+1))
            eval tmp='$'${index}
        done
        echo "}"
        echo ""
    fi
}

generate_realm() # realm, strip, authp_name, acctp_name
{
    local realm="${1}"
    local strip="${2}"
    local authp_name="${3}"
    local acctp_name="${4}"

    if [ -n "${realm}" ]; then
        echo "realm ${realm} {"
        if [ -n "${authp_name}" ]; then
            echo "    auth_pool = ${authp_name}"
        fi
        if [ -n "${acctp_name}" ]; then
            echo "    acct_pool = ${acctp_name}"
        fi
        if [ -n "${strip}" ]; then
            echo "    ${strip}"
        fi
        echo "}"
        echo ""
    fi
}

generate_proxy()
{
    local fallback="${1}"

    [ -z "${fallback}" ] && fallback="yes"
    echo "proxy server {"
    echo "    default_fallback = ${fallback}"
    echo "}"
    echo ""
}

srv_number="2"
tmp_proxy="/tmp/rproxy.conf"
config_proxy="/db/config/proxy.conf"
default_mgmt="$(< /db/subscriber/mgmt_default)"
null_mgmt="$(< /db/subscriber/mgmt_index)"
ppp_auth="/tmp/ppp_auth_en"

# main configuration
generate_proxy > "${tmp_proxy}"

# mgmt loop to generate config
for val_i in $(seq 1 ${Auth_Server_Num}) 103; do
    cfg="/db/subscriber/mgmt/${val_i}"
    mgmt_enable=$(< ${cfg}/mgmt_enable)
    postfix=$(< ${cfg}/postfix)
    strip_setting="nostrip"
    if [ "${mgmt_enable}" = "Enabled" -a -n "${postfix}" ]; then
        utype=$(< ${cfg}/utype)
        if [ "${utype}" = "RADIUS" ]; then
            eap=$(< ${cfg}/radius/8021x)
	    # reset variables
	    for i in server_ip auth_port acct_server_ip account_port secret_key acct_secret_key; do
		for j in $(seq 1 ${srv_number}); do
		    var="${i}_${j}"
		    eval unset $var
		done
	    done
            if [ "${eap}" = "Enabled" -o -f ${ppp_auth} ]; then
                for i in server_ip auth_port acct_server_ip account_port secret_key acct_secret_key; do
                    for j in $(seq 1 ${srv_number}); do
                        var="${i}_${j}"
                        eval $var=$(< ${cfg}/radius/${var})
                        # server_ip_n, auth_port_n, secret_key_n
                        # acct_server_ip_n, account_port_n, acct_secret_key_n
                    done
                done

            fi
            # server config
            authsrv_list=""
            acctsrv_list=""
            for i in $(seq 1 ${srv_number}); do
                # auth
                eval _server_ip='$'server_ip_${i}
                eval _port='$'auth_port_${i}
                eval _secret_key='$'secret_key_${i}
                _auth_name=$(generate_server_name "${_server_ip}" "${_port}")
                if [ -n "${_server_ip}" -a -n "${_port}" -a -n "${_secret_key}" ]; then
                    eval _tmp='$'${_auth_name}
                    if [ "${_tmp}" = "" ]; then
                        eval $_auth_name="set"
                        generate_server "${_auth_name}" "${_server_ip}" "auth" "${_port}" "${_secret_key}"
                    fi
                    authsrv_list="${authsrv_list}${_auth_name} "
                fi
                # acct
                eval _server_ip='$'acct_server_ip_${i}
                eval _port='$'account_port_${i}
                eval _secret_key='$'acct_secret_key_${i}
                _acct_name=$(generate_server_name "${_server_ip}" "${_port}")
                if [ -n "${_server_ip}" -a -n "${_port}" -a -n "${_secret_key}" ]; then
                    eval _tmp='$'${_acct_name}
                    if [ "${_tmp}" = "" ]; then
                        eval $_acct_name="set"
                        generate_server "${_acct_name}" "${_server_ip}" "acct" "${_port}" "${_secret_key}"
                    fi
                    acctsrv_list="${acctsrv_list}${_acct_name} "
                fi
            done
            # pool config
            if [ -n "${authsrv_list}" ]; then
                    generate_server_pool "auth_pool_${val_i}" "fail-over" ${authsrv_list}
            fi
            if [ -n "${acctsrv_list}" ]; then
                    generate_server_pool "acct_pool_${val_i}" "fail-over" ${acctsrv_list}
            fi
            # realm config
            if [ -n "${authsrv_list}" ]; then
                if [ -n "${acctsrv_list}" ]; then
                    generate_realm "${postfix}" "${strip_setting}" "auth_pool_${val_i}" "acct_pool_${val_i}"
                    [ "${null_mgmt}" = "${val_i}" ] && generate_realm "NULL" "${strip_setting}" "auth_pool_${val_i}" "acct_pool_${val_i}"
                    [ "${default_mgmt}" = "${val_i}" ] && generate_realm "DEFAULT" "${strip_setting}" "auth_pool_${val_i}" "acct_pool_${val_i}"
                else
                    generate_realm "${postfix}" "${strip_setting}" "auth_pool_${val_i}"
                    [ "${null_mgmt}" = "${val_i}" ] && generate_realm "NULL" "${strip_setting}" "auth_pool_${val_i}"
                    [ "${default_mgmt}" = "${val_i}" ] && generate_realm "DEFAULT" "${strip_setting}" "auth_pool_${val_i}"
                fi
            fi
        elif [ "${utype}" = "LOCAL" ]; then
            roaming_out=$(< ${cfg}/local_roamingout)
            local_8021x=$(< ${cfg}/radius/8021x)
            if [ "${roaming_out}" = "Enabled" -o "${local_8021x}" = "Enabled" -o -f ${ppp_auth} ]; then
                generate_realm "${postfix}" "${strip_setting}" ""
                    [ "${null_mgmt}" = "${val_i}" ] && generate_realm "NULL" "${strip_setting}" ""
                    [ "${default_mgmt}" = "${val_i}" ] && generate_realm "DEFAULT" "${strip_setting}" ""

            fi
        elif [ "${utype}" = "ONDEMAND" ]; then
            roaming_out=$(< ${cfg}/local_roamingout)
            local_8021x=$(< ${cfg}/radius/8021x)
            if [ "${roaming_out}" = "Enabled" -o "${local_8021x}" = "Enabled" ]; then
                generate_realm "${postfix}" "${strip_setting}" ""
                    [ "${null_mgmt}" = "${val_i}" ] && generate_realm "NULL" "${strip_setting}" ""
                    [ "${default_mgmt}" = "${val_i}" ] && generate_realm "DEFAULT" "${strip_setting}" ""

            fi
        fi

    fi
done >> ${tmp_proxy}

generate_realm "__FAKE__SERVER__" "nostrip" "" >> ${tmp_proxy}

# replace config
cp -a ${tmp_proxy} ${config_proxy}
chown 1001.1001 ${config_proxy}
rm -f ${tmp_proxy}
