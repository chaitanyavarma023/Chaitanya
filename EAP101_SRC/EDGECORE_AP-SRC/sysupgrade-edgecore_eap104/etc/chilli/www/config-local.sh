#!/bin/sh
# Copyright (C) 2009-2012 David Bird (Coova Technologies) <support@coova.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

. ./functions.sh
. ./uam.sh
. ./wispr.sh

USERS=/etc/chilli/localusers
COOVA_USERURL=$COOKIE_COOVA_USERURL
COOVA_SESSIONID=$CHI_SESSION_ID
COOVA_CHALLENGE=$CHI_CHALLENGE
PORTAL_SESSIONID=${COOKIE_PORTAL_SESSIONID:-$SESSIONID}
FORM_userurl=${FORM_userurl:-http://www.coova.org/}
bindng_error_code=""

http_redirect2() {
cat <<EOF
HTTP/1.1 302 Redirect
Location: $1
Set-Cookie: PORTAL_SESSIONID=$PORTAL_SESSIONID
Set-Cookie: COOVA_USERURL=$COOVA_USERURL
Connection: close

EOF
    exit
}

http_redirect() {
    http_header
    cat <<EOF
<body onload="document.form1.submit();" style="background-color:#000">
<form action="$1" name="form1" id="form1" method="post">
<input name="res" value="$FORM_res" type="hidden">
<input name="reply" value="$FORM_reply" type="hidden">
</form>
</body>
EOF
    exit
}

http_header() {
    cat<<EOF
HTTP/1.1 200 OK
Content-Type: text/html
Set-Cookie: PORTAL_SESSIONID=$PORTAL_SESSIONID
Set-Cookie: COOVA_USERURL=$COOVA_USERURL
Connection: close
Cache: none

EOF
}

header() {
    echo "<html><head>"

    uamfile title 0

    echo "<meta http-equiv=\"Cache-control\" content=\"no-cache\"/>
<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"/>
<meta http-equiv=\"Pragma\" content=\"no-cache\"/>
<meta name=\"viewport\" content=\"width=device-width,height=device-height,initial-scale=1.0\"/>
<style>"

    uamfile "css" 0

    echo "</style>"
    echo "<script>"

    uamfile "js" 0

    echo "</script>"
    echo "$1</head><body$2>"

    if [ "$HS_CUSTOM_EASYSETUP" == "0" ]; then
        [ "$HS_CUSTOM_WIANCOR" == "1" ] && {
            uamfile "wi_anchor_header" 1
        } || {
    uamfile "header" 1
        }
    echo "<div id=\"body\">"
    else
        echo "<div id=\"body\" style=\"display:none\">"
    fi
}

footer() {
    echo "</div>"

    uamfile "footer" 1

    echo "<!--table style=\"clear:both;margin:auto;padding-top:10px;\" height=\"30\">
<tr><td valign=\"center\" align=\"center\" style=\"color:#666;font-size:60%;\">Powered by</td>
<td valign=\"center\" align=\"center\"><a href=\"http://coova.org/\"><img border=0 src=\"coova.jpg\"></a>
</td></tr></table--></body></html>"
}

error() { echo "<div class=\"err\">$1</div>"; }

href() {
    echo "<a href=\"$1\">$2</a>"
}

form() {
    echo "<form name=\"form\" method=\"post\" action=\"$1\"><INPUT TYPE=\"hidden\" NAME=\"userurl\" VALUE=\"$FORM_userurl\">$2</form>"
}

# bindng_error_code
#   1: binded
#   others: unbinded
get_binding_status() {
    verify_url="`uci -q get addon.wianchor.bindingStatusUrl`"
    ap_mac="$(echo $HS_NASMAC | sed 's/-//g' | awk '{print tolower($0)}')"
    client_mac="$(echo $REMOTE_MAC | sed 's/-//g' | awk '{print tolower($0)}')"

    _hash_val="$(echo -n $ap_mac$client_mac | md5sum | awk  '{print $1}')"
    hash_val_1=$(expr substr "$_hash_val" 1 4)
    hash_val_2=$(echo "$_hash_val" | grep -o '....$')
    hash_val="${hash_val_1}${hash_val_2}"

    bindng_error_code=$(curl -k -X POST -H 'Content-Type: application/json' -d '{"ap_mac":"'$ap_mac'","client_mac":"'$client_mac'","hash":"'$hash_val'"}' $verify_url --connect-timeout 5 -m 5 | jsonfilter -e "@.error_code")
}

loginform() {
    case "$AUTHENTICATED" in
    1)
      ;;

    *)
      [ "$HS_OPENIDAUTH" = "on" ] && { \
        echo "<div id=\"login-label\" style=\"display:none;\"><label><a href=\"javascript:toggleAuth('login')\">&lt;&lt; back</a></label></div>"
        form "login.chi" "$(uamfile openid_form 1)"
      }

      [ "$HS_CUSTOM_WIANCOR" == "1" ] && {
        get_binding_status
        sleep 1
        if [ "$bindng_error_code" == "1" ] ; then
          wi_anchor_dologin
        else
          form "login.chi" "$(uamfile wi_anchor_form 1)"
        fi
      } || {
        form "login.chi" "$(uamfile login_form 1)"
      }

      ;;
    esac
}

local_login_url() {
    if [ "$HS_USELOCALUSERS" = "on" ]; then
        line=$(head -1 $USERS)
        if [ "$line" = "" ]; then
            echo "tos:$(echo '$$$(date)'|md5sum|cut -f1)" >> $USERS
            line=$(head -1 $USERS)
        fi
        if [ "$line" != "" ]; then
            user=$(echo "$line" | cut -f1 -d:)
            pass=$(echo "$line" | cut -f2 -d:)
            echo -n $(chi_login_url "$user" "$pass")
        fi
    else
        user=$REMOTE_MAC
        pass=$HS_ADMPWD
        echo -n $(chi_login_url "$user" "$pass")
    fi
}

reply_message() {
    case "$AUTHENTICATED" in
    1)
      echo "You are now on-line!"
      ;;
    *)
      echo "$FORM_reply"
      ;;
    esac
}

image() {
    ext=$(echo "$1"|awk -v FS=. '{ print tolower($NF) }')
    base=$(echo "$1"|awk -v FS=/ '{ gsub(/[^a-zA-Z0-9_\/-]/,""); print tolower($NF) }')
    echo -n "img-$base.$ext"
}

registerform() {
    form "register.chi" "$(uamfile register_form 1)"
}

contactform() {
    form "contact.chi" "$(uamfile contact_form 1)"
}

termsform() {
    form "tos.chi" "$(uamfile terms_form 1)"
}

runlogin() {
    out=$($CHILLI_QUERY login sessionid "$COOVA_SESSIONID" username "$1" password "$2")
}

chi_login_url() {
    local https_on=$(uci get hotspot.hotspot.hs_https)
    local HTTP_url="http"
    local HS_URL=${HS_UAMLISTEN}
        [ $https_on == "1" ] && {
            HTTP_url="https"
            HS_URL=$(uci get hotspot.hotspot.hs_https_domain)
        }

    case "$HS_RAD_PROTO" in
    pap)
      response=$($CHILLI_RESPONSE -pap "$CHI_CHALLENGE" "$HS_UAMSECRET" "$2")
      echo -n "${HTTP_url}://${HS_URL}:$HS_UAMPORT/login?username=$1&password=${response}&userurl=${3:-$COOVA_USERURL}"
      ;;
    mschapv2)
      response=$($CHILLI_RESPONSE -nt "$CHI_CHALLENGE" "$HS_UAMSECRET" "$1" "$2")
      echo -n "${HTTP_url}://${HS_URL}:$HS_UAMPORT/login?username=$1&ntresponse=${response}&userurl=${3:-$COOVA_USERURL}"
      ;;
    *)
      response=$($CHILLI_RESPONSE "$CHI_CHALLENGE" "$HS_UAMSECRET" "$2")
      echo -n "${HTTP_url}://${HS_URL}:$HS_UAMUIPORT/login?username=$1&response=${response}&userurl=${3:-$COOVA_USERURL}"
      ;;
    esac
}

wi_anchor_dologin() {
    url=$(chi_login_url "default" "default" "$FORM_userurl")
    cat <<ENDHTML
<html><head>
<meta http-equiv="refresh" content="0;url=$url"/>
</head></html>
ENDHTML
    wisprLoginResultsURL "$url"
}

dologin() {
    url=$(chi_login_url "$FORM_username" "$FORM_password" "$FORM_userurl")
    cat <<ENDHTML
<html><head>
<meta http-equiv="refresh" content="0;url=$url"/>
</head></html>
ENDHTML
    wisprLoginResultsURL "$url"
}

dologin_auto() {
    url=$(chi_login_url "default" "default" "$FORM_userurl")
    cat <<ENDHTML
<meta http-equiv="refresh" content="0;url=$url"/>
<body style="background-color:#000"></body>
ENDHTML
}

domail() {
    from=$1;to=$2;file=$3
    (uamfile "$file" 0
      echo
      echo "-------------------------------------------------"
      echo "Powered by Coova - http://www.coova.org/"
      echo) | /usr/sbin/sendmail -t -f "$from" && return 0
    return 1;
}

FORM_username="${FORM_username:-$FORM_UserName}"
FORM_username="${FORM_username:-$FORM_Username}"
FORM_password="${FORM_password:-$FORM_Password}"

# For WISPr 2.0 EAP, bounce back to chilli
[ "$FORM_res" = "wispr" ] && \
    [ "$FORM_WISPrEAPMsg" != "" ] && \
    [ "$FORM_WISPrVersion" = "2.0" ] && {
    local https_on=$(uci get hotspot.hotspot.hs_https)
    HTTP_url="http"

    local HS_URL=${HS_UAMLISTEN}
    [ $https_on == "1" ] && {
        HTTP_url="https"
        HS_URL=$(uci get hotspot.hotspot.hs_https_domain)
    }

    http_redirect2 "${HTTP_url}://${HS_URL}:$HS_UAMPORT/login?username=$FORM_username&WISPrEAPMsg=$FORM_WISPrEAPMsg&WISPrVersion=2.0"

}

if [ "$FORM_uamip" != "" ] && [ "$HS_UAMSECRET" != "" ]; then
    if [ "$FORM_res" != "wispr" ]; then
      QS=$(echo $QUERY_STRING | sed 's/&md=[^&=]*$//')
      HTTP="http"
      [ "$HTTPS" = "on" ] && HTTP="https"
      URL="$HTTP://$SERVER_NAME/$REQUEST_URI?$QS"
      CHECK="$URL$HS_UAMSECRET"
      CHECK_MD5=$(echo -n "$CHECK" |md5sum|cut -d' ' -f1|tr 'a-z' 'A-Z');

      if [ "$CHECK_MD5" = "$FORM_md" ]; then
        COOVA_USERURL=$FORM_userurl
      else
        http_redirect "/www/error.chi"
      fi
    fi
fi
