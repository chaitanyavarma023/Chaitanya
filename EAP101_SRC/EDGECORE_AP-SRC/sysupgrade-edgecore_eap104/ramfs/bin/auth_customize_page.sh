#!/bin/sh
web_path="/www/cgi-bin/examples"
root_path="/www"
ori_filename="index.htm"
html_filename="customize.html"
lp_filename="index.lp"
EXTERNAL_LOGIN_URL="external_login_url"
EXTERNAL_SUCCESS_URL="external_success_url"
EXTERNAL_FAIL_URL="external_fail_url"
EXTERNAL_CHECK_LOGIN_TMPL="/ramfs/uamd/check_external_login.tmpl"
EXTERNAL_REDIR_PORTAL_TMPL="/ramfs/uamd/redir_external_portal.tmpl"
EXTERNAL_LOGIN_TMPL="/ramfs/uamd/external_login.tmpl"
EXTERNAL_CHECK_LOGIN_PAGE="check_external_login.lp"
EXTERNAL_REDIR_PORTAL_PAGE="redir_external_portal.lp"
EXTERNAL_LOGIN_PAGE="login.lp"
MICROSOFT365_LOGIN_TMPL="/ramfs/uamd/microsoft365_login.tmpl"
MICROSOFT365_AUTH_TMPL="/ramfs/uamd/microsoft365_auth.tmpl"
MICROSOFT365_LOGIN_PAGE="microsoft365_login.lp"
MICROSOFT365_AUTH_PAGE="${root_path}/cgi-bin/m365_auth.lp"
WEB_URL_FILE="/tmp/web_url"

ifname=$1
vif=$2
[ "${ifname}" = "" ] && exit
auth_customize_page_run="/tmp/.auth_customize_page_run.${ifname}"

if [ -f "${auth_customize_page_run}" ]; then
    exit
else
    touch ${auth_customize_page_run}
fi

function add_zone()
{
    local dn=$1

    if expr "$dn" : '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/null; then
            ipset add zone_ip $dn
    else
        for ip_addr in $(nslookup "${dn}" |  awk '/Name:/{val=$NF;flag=1;next} /Address/ && flag{print $NF}')
        do
            if expr "$ip_addr" : '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/null; then
                ipset add zone_ip $ip_addr
            fi
        done
    fi
}

function parser_url()
{
    local url=$1

    if [ "$(echo $url | grep -c "://")" != "0" ]; then
        external_proto=${url%%:*}
        external_web_page=${url#*//}
    else
        external_web_page=${url}
        external_proto="https"
    fi
    external_ip=${external_web_page%%/*}
}

function check_hs20_portal()
{
	local vif="$1"
	local hs20_profile=$(uci -q get wireless.${vif}.hs20_profile)
	local iw_section_name=$(uci -q show hotspot20 | grep "$hs20_profile" | grep "name" | awk -F '.' '{print $2}')
	local iw_portal_en=$(uci -q get hotspot20.${iw_section_name}.iw_portal_enable)
	local iw_portal_url=$(uci -q get hotspot20.${iw_section_name}.iw_portal_url)
	local iw_portal_walls=$(uci -q get hotspot20.${iw_section_name}.iw_portal_wall)

	if [ -z "$iw_portal_en" ] || [ "$iw_portal_en" = "0" ]; then
		echo ""
		return
	fi

	# add walled garden to zone_ip
	for portal_wall in $iw_portal_walls; do
		ipset add zone_ip $portal_wall
	done

	echo $iw_portal_url
}

function m365_walled_garden()
{
	local vif="$1"
	local domain_list=$(uci -q get wireless.${vif}.m365_walled_garden)
	local m365_wall_file="/tmp/walledgarden_microsoft365"
	local dns_file="/tmp/hosts/microsoft365"

	echo -n "" > $m365_wall_file
	for domain in $domain_list; do
		echo "$domain" >> $m365_wall_file
	done
	
	/ramfs/bin/wall_ipsetadt.sh $m365_wall_file $dns_file
}

captive_portal_path=$(uci get wireless.${vif}.captive_portal_path)
if [ -d ${web_path}/${ifname} ]; then
    rm -f ${web_path}/${ifname}/*
    rm -f ${root_path}/${ifname}/*
else
    mkdir -p ${web_path}/${ifname}
    mkdir -p ${root_path}/${ifname}
fi

m365_auth_url=$(uci get wireless.${vif}.m365_auth_url)
if [ -n "$m365_auth_url" ]; then
    web_url=$(cat $WEB_URL_FILE)
    m365_auth_url=$(echo $m365_auth_url | sed 's/\//\\\//g')
    m365_token=$(uci get wireless.${vif}.m365_token)
    m365_token=$(echo $m365_token | sed 's/\//\\\//g')
    m365_client_id=$(uci get wireless.${vif}.m365_client_id)
    m365_permission=$(uci get wireless.${vif}.m365_permission)
    m365_permission=$(echo $m365_permission | sed 's/\//\\\//g')
    m365_client_secret=$(uci get wireless.${vif}.m365_client_secret)
    m365_redirect="${web_url}/cgi-bin/m365_auth.lp"
    m365_redirect=$(echo $m365_redirect | sed 's/\//\\\//g')
    m365_login="${web_url}/cgi-bin/examples/${ifname}/${MICROSOFT365_LOGIN_PAGE}"
    m365_login=$(echo $m365_login | sed 's/\//\\\//g')
    rep="s/__AUTHORIZE/$m365_auth_url/g"
    rep="${rep};s/__REDIRECT_URI/$m365_redirect/g"
    rep="${rep};s/__SCOPE/$m365_permission/g"
    rep="${rep};s/__CLIENT_ID/$m365_client_id/g"
    sed "$rep" $MICROSOFT365_LOGIN_TMPL > ${web_path}/${ifname}/${MICROSOFT365_LOGIN_PAGE}
    rep="s/__TOKEN_URI/$m365_token/g"
    rep="${rep};s/__REDIRECT_URI/$m365_redirect/g"
    rep="${rep};s/__CLIENT_ID/$m365_client_id/g"
    rep="${rep};s/__PERMISSION/$m365_permission/g"
    rep="${rep};s/__CLIENT_SECRET/$m365_client_secret/g"
    result_url="${web_url}/cgi-bin/examples/${ifname}/test1.lp"
    result_url=$(echo $result_url | sed 's/\//\\\//g')
    rep="${rep};s/__RESULT_URL/$result_url/g"
    plan_id=$(uci get wireless.${vif}.m365_plan_id)
    rep="${rep};s/__PLAN_ID/$plan_id/g"
    sed "$rep" $MICROSOFT365_AUTH_TMPL > $MICROSOFT365_AUTH_PAGE
    chmod 755 ${web_path}/${ifname}/${MICROSOFT365_LOGIN_PAGE}
    chmod 755 $MICROSOFT365_AUTH_PAGE
    m365_walled_garden $vif
fi

external_url=$(uci get wireless.${vif}.${EXTERNAL_LOGIN_URL})
if [ -n "$external_url" ]; then
    parser_url $external_url
    add_zone $external_ip
    EX_PAGE="${external_proto}://${external_web_page}"
    EX_PAGE=$(echo $EX_PAGE | sed 's/\//\\\//g')
    check_page=$(cat /ramfs/uamd/cfg.proxy.${ifname} | grep "NCS_URL=" | sed 's/NCS_URL=//g')
    POST_PAGE="${check_page%/*}/${EXTERNAL_LOGIN_PAGE}"
    POST_PAGE=$(echo $POST_PAGE | sed 's/\//\\\//g')
    rep="s/__EXTERNAL_POST_URL/$POST_PAGE/g"
    rep="${rep};s/__EXTERNAL_LOGIN_URL/$EX_PAGE/g"
    sed "$rep" $EXTERNAL_CHECK_LOGIN_TMPL > ${web_path}/${ifname}/${EXTERNAL_CHECK_LOGIN_PAGE}
    chmod 755 ${web_path}/${ifname}/${EXTERNAL_CHECK_LOGIN_PAGE}
    success_url=$(uci get wireless.${vif}.${EXTERNAL_SUCCESS_URL})
    parser_url $success_url
    add_zone $external_ip
    success_url="${external_proto}://${external_web_page}"
    success_url=$(echo $success_url | sed 's/\//\\\//g')
    fail_url=$(uci get wireless.${vif}.${EXTERNAL_FAIL_URL})
    parser_url $fail_url
    add_zone $external_ip
    fail_url="${external_proto}://${external_web_page}"
    fail_url=$(echo $fail_url | sed 's/\//\\\//g')
    rep="s/__EXTERNAL_SUCCESS_URL/$success_url/g"
    rep="${rep};s/__EXTERNAL_FAIL_URL/$fail_url/g"
    sed "$rep" $EXTERNAL_LOGIN_TMPL > ${web_path}/${ifname}/${EXTERNAL_LOGIN_PAGE}
    chmod 755 ${web_path}/${ifname}/${EXTERNAL_LOGIN_PAGE}
fi

external_iw_portal_url=$(check_hs20_portal "$vif")
if [ -n "$external_iw_portal_url" ]; then
    parser_url $external_iw_portal_url
    add_zone $external_ip
    EX_PAGE="${external_proto}://${external_web_page}"
    EX_PAGE=$(echo $EX_PAGE | sed 's/\//\\\//g')
    rep="s/__EXTERNAL_LOGIN_URL/$EX_PAGE/g"
    sed "$rep" $EXTERNAL_REDIR_PORTAL_TMPL > ${web_path}/${ifname}/${EXTERNAL_REDIR_PORTAL_PAGE}
    chmod 755 ${web_path}/${ifname}/${EXTERNAL_REDIR_PORTAL_PAGE}
fi

replace_path="\/${ifname}\/"
[ -n "${captive_portal_path}" ] && curl -4 -k --connect-timeout 5 -m 5 -o ${web_path}/${ifname}/${ori_filename} ${captive_portal_path} >/dev/null 2>&1

# Download src file
if [ ! -f "${web_path}/${ifname}/${ori_filename}" ]; then
    if [ -n "$m365_auth_url" ]; then
        cp -a ${web_path}/${ifname}/${MICROSOFT365_LOGIN_PAGE} ${web_path}/${ifname}/${lp_filename}
    else
        cp -a ${web_path}/test.lp ${web_path}/${ifname}/${lp_filename}
    fi
else
    sed '1i #!/usr/bin/env cgilua.cgi' < ${web_path}/${ifname}/${ori_filename} > ${web_path}/${ifname}/${html_filename}
    grep -o -e 'http[s]*://[^")]*' ${web_path}/${ifname}/${html_filename} | while read line; do
	path="${line%/*}/"
	path="${path%%)*}"
	filename=${path##*/}
	remain=""
	if [ "${filename}" = "" ]; then
 	    filename=${line##*/}
 	else
	    express=$(echo $path | sed 's/\//\\\//g')
	    remain=$(echo $line | sed "s/$express//g")
	    path=$(echo "$path" | sed "s/${filename}//g")
	fi
	curl -4 -k --connect-timeout 5 -m 5 -o ${root_path}/${ifname}/${filename} ${path}${filename}
	token=$(echo $path | sed 's/\//\\\//g')
	eval sed -i 's/${token}/${replace_path}/g' ${web_path}/${ifname}/${html_filename}

	while [ "${remain}" != "" ]; do
	    remain=$(echo "$remain" | grep -o -e 'http[s]*://[^"]*')
	    [ "${remain}" = "" ] && break
	    path="${remain%/*}/"
	    path="${path%%)*}"
	    filename=${remain##*/}
	    filename=${filename%%)*}
	    curl -4 -k --connect-timeout 5 -m 5 -o ${root_path}/${ifname}/${filename} ${path}${filename}
	    express=$(echo $path | sed 's/\//\\\//g')
	    remain=$(echo $remain | sed "s/${express}/${replace_path}/g")
	done
    done

    [ -n "${m365_login}" ] && eval sed -i 's/LINK-TO-365/${m365_login}/g' ${web_path}/${ifname}/${html_filename}
    mv ${web_path}/${ifname}/${html_filename} ${web_path}/${ifname}/${lp_filename}
    chmod +x ${web_path}/${ifname}/${lp_filename}

    login_url=$(grep NCS_URL /ramfs/uamd/cfg.proxy.${ifname} | cut -d= -f2)
    login_url=${login_url%/*}
    sed -i "/action/!b;n;c\"${login_url}/test1.lp\"" ${root_path}/${ifname}/captive-portal.js
fi
cp -a ${web_path}/test1.lp ${web_path}/${ifname}
rm -f ${auth_customize_page_run}
