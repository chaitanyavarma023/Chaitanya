-- Copyright 2008 Steven Barth <steven@midlink.org>
-- Copyright 2011-2018 Jo-Philipp Wich <jo@mein.io>
-- Licensed to the public under the Apache License 2.0.

module("luci.controller.admin.system", package.seeall)

local fs = require "nixio.fs"
local product = require("luci.acn.product")
local product_name = product.product_name:gsub(" ", "-")
local json = require "cjson.safe"
local DEVICE_DISCOVERY_CMD = "discoveryd -sf"
local DEVICE_DISCOVERY_FILE = "/var/run/discovery/devices.json"

function index()
    local page

    entry({"admin", "system", "system"}, cbi("system"), _("User Accounts"), 5)
    entry({"admin", "system", "user"}, cbi("user"), _("User Accounts"), 5)
    entry({"admin", "system", "services"}, cbi("services"), _("Services"), 5)
    entry({"admin", "system", "actions"}, call("ACN_actions"), _("System Actions"), 7)
    entry({"admin", "system", "syslog", "text_only"}, call("action_syslog_text"), _("System Log"), 7)
    -- Used by Syslog->"Open in new window"
    entry({"admin", "system", "syslog"}, call("action_syslog"), _("System Log"), 7)
    entry({"admin", "system", "acn_reboot"}, call("dev_reboot"), nil).leaf = true
    entry({"admin", "system", "reset_def"}, call("dev_reset_def"), nil).leaf = true

    entry({"admin", "system", "discovery"}, template("cbi/device_discovery"), _("Device Discovery"), 5)
    entry({"admin", "system", "discovery_start"}, call("discovery_start")).leaf = true
    entry({"admin", "system", "discovery_stop"}, call("discovery_stop")).leaf = true

    pagewifi = entry({"admin", "system", "ble_scan"}, call("get_ble_scan_results"), _("Scan"), 8)
    pagewifi.leaf   = true

    pagewizard = entry({"admin", "system", "set_wizard"}, call("set_wizard"), nil)
    pagewizard.leaf = true

    --entry({"admin", "system", "qrwizard_network"},  call("set_qrwizard_network"), nil)
    entry({"admin", "system", "qrwizard"},  call("set_qrwizard"), nil)

    entry({"admin", "system", "ezwizard"},  call("set_ezwizard"), nil)
    entry({"admin", "system", "ezwizard_mgmt"},  call("set_ezwizard_mgmt"), nil)
    entry({"admin", "system", "ezwizard_register"},  call("set_ezwizard_register"), nil)
    entry({"admin", "system", "ezwizard_success"},  call("set_ezwizard_success"), nil)
    entry({"admin", "system", "ezwizard_fail"},  call("set_ezwizard_fail"), nil)
    entry({"admin", "system", "certificate"}, call("ACN_ca_actions"), _("Upload Certificate"), 5)
    entry({"admin", "system", "reset_ca_default"}, call("reset_ca_default"), nil).leaf = true
    entry({"admin", "system", "ca_content"}, call("ca_content"), nil).leaf = true

    pagewizard = entry({"admin", "system", "wizard"}, template("admin_system/easy_wizard"), _("Wizard"), 2)
    pagewizard.leaf = true

    pagewizard = entry({"admin", "system", "qr_wizard"}, template("admin_system/qr_wizard"), _("QR Wizard"), 2)
    pagewizard.leaf = true

end

function get_ble_scan_results()

    local sys = require "luci.sys"
    os.execute("/usr/bin/blescan2file.sh >/dev/null 2>&1 &")
    local wait = require("socket").sleep
    wait(7)
    local file = io.open("/tmp/blescan.record", "a+")
    luci.template.render("cbi/ble_scan_table", {content = file})
    file:close()
end

function ltn12_popen(command)
    local fdi, fdo = nixio.pipe()
    local pid = nixio.fork()

    if pid > 0 then
        fdo:close()
        local close
        return function()
            local buffer = fdi:read(2048)
            local wpid, stat = nixio.waitpid(pid, "nohang")
            if not close and wpid and stat == "exited" then
                close = true
            end

            if buffer and #buffer > 0 then
                return buffer
            elseif close then
                fdi:close()
                return nil
            end
        end
    elseif pid == 0 then
        nixio.dup(fdo, nixio.stdout)
        fdi:close()
        fdo:close()
        nixio.exec("/bin/sh", "-c", command)
    end
end

function set_wizard()
    local http = require "luci.http"

    local radio_mode = http.formvalue("radio_mode")
    local template = http.formvalue("mode_template")
    local country_code  = http.formvalue("country_list") or "US"
    local ssid = http.formvalue("ssid")
    local psk_key = http.formvalue("psk_key")
    local controller_mode = http.formvalue("radio_controller")
    local cloud_server = "https://regsvc.ignitenet.com/register"

    local guest_ssid = http.formvalue("guest_ssid")
    local guest_psk_key = http.formvalue("guest_psk_key")

     local acn = require("luci.acn.util")
     local product = require("luci.acn.product")
     local uci = acn.cursor()

     local num_radios = product.num_wifi_radios
     local num_eth_ports = product.num_eth_ports

    local fcc_locked = product.fcc_locked()
    local thai_locked = product.thai_locked()
    local jp_locked = product.jp_locked()

    local cc = country_code

    local controlled = (controller_mode == "controlled")

    if fcc_locked then
        cc = "US"
    end

    if thai_locked then
        cc = "TH"
    end

    if jp_locked then
        cc = "JP"
    end

    if br_locked then
        cc = "BR"
    end

    if controlled then
        uci:set("acn", "mgmt", "enabled", "1" )
    else
        uci:set("acn", "mgmt", "enabled", "0" )
    end

    uci:set("acn", "register", "url", cloud_server)

     -- Not setting country_other to 0 so that wireless settings aren't touched
     -- causing unnecessary restart of networking

    for i=0, num_radios -1 do
        local wifi_section1 = acn.wifi_section(i, 1)
        uci:set("wireless", acn.radio_section(i), "country", cc )

        if not controlled and radio_mode == "easy" then

            uci:set("wireless", wifi_section1, "ssid", ssid  or "None")
            uci:set("wireless", wifi_section1, "created", "1")

            if psk_key and #psk_key > 0 then
                uci:set("wireless", wifi_section1, "key", psk_key or "")
                uci:set("wireless", wifi_section1, "disabled", "0")
                uci:set("wireless", wifi_section1, "encryption", "psk2+ccmp")
                uci:set("wireless", wifi_section1, "key_method", "psk")
            end

            if guest_ssid and #guest_ssid > 0 then
                local wifi_section2 = acn.wifi_section(i, 2)
                uci:set("wireless", wifi_section2, "ssid", guest_ssid  or "Guest-SSID")
                uci:set("wireless", wifi_section2, "disabled", "0")
                uci:set("wireless", wifi_section2, "created", "1")
                uci:set("wireless", wifi_section2, "network", "guest")
                uci:set("wireless", wifi_section2, "client_isolation", "1")

                if guest_psk_key and #guest_psk_key > 0 then
                    uci:set("wireless", wifi_section2, "key", guest_psk_key or "")
                    uci:set("wireless", wifi_section2, "encryption", "psk2+ccmp")
                    uci:set("wireless", wifi_section2, "key_method", "psk")
                end

            end
        end
    end

    if not controlled then
        if radio_mode ~= "easy" then
            if template == "ap-router" then
                -- Put first eth as inet_src
                -- add other eth's (if exist) to LAN

                -- assume wifi is okay

                --> This is default network config, so will leave for now
            elseif template == "ap-bridge" then

                for i=0, num_radios -1 do
                    acn.add_iface_to_network(wan_network, acn.wifi_section(i, 1), uci)
                end

                -- Also add all ethernet ports to the bridge
                for i=0, num_eth_ports -1 do
                    acn.add_iface_to_network(wan_network, product.eth(i)['logical_name'], uci)
                end

                if num_eth_ports >= 1 then
                    uci:set("network", wan_network, "inet_src", product.eth(0)['dev_name'])
                end
            end
        end
    end

    uci:set("acn", "wizard", "enabled", "0")

    uci:save("acn")
    uci:save("wireless")
    uci:save("network")

    luci.http.redirect(luci.dispatcher.build_url("admin/acn_status/overview"))
end

function set_qrwizard()
    local http = require "luci.http"
    local acn = require("luci.acn.util")
    local uci = acn.cursor()
    local wan_type = http.formvalue("cbid.network.wan.proto")
    local ez_setup = uci:get("acn", "wizard", "ez_setup")
    local step = http.formvalue("wiz_step")
    local utl = require("luci.util")

    if step and (step == "step1" or step == "step2") then
        uci:set("acn", "capwap", "state", "0" )
        uci:set("acn", "capwap", "dhcp_opt", "0" )
    end

    if step and step == "step0" then
        if ez_setup == "1" then
            os.execute("touch /tmp/.ez_setup_landing_done >/dev/null 2>&1")
        end
    elseif step and step == "step1" then
        -- setup wan type
        uci:set("network", "wan", "proto", wan_type)
        if wan_type == "static" then
            local wan_ip = http.formvalue("cbid.network.wan.ipaddr") or ""
            local wan_netmask = http.formvalue("cbid.network.wan.netmask") or ""
            local wan_gw = http.formvalue("cbid.network.wan.gateway") or ""
            local wan_dns = http.formvalue("cbid.network.wan.dns") or ""
            if wan_dns == "" then
                wan_dns = wan_gw
            end
            uci:set("network", "wan", "ipaddr", wan_ip)
            uci:set("network", "wan", "netmask", wan_netmask)
            uci:set("network", "wan", "gateway", wan_gw)
            uci:set("network", "wan", "dns", wan_dns)
        end

        if wan_type == "pppoe" then
            local pppoe_user = http.formvalue("cbid.network.wan.username") or ""
            local pppoe_pwd = http.formvalue("cbid.network.wan.password") or ""
            uci:set("network", "wan", "username", pppoe_user)
            uci:set("network", "wan", "password", pppoe_pwd)
        end
        uci:save("network")
        uci:commit("network")
        -- end setup wan type

        if ez_setup == "1" then
            os.execute("touch /tmp/.ez_setup_network_done >/dev/null 2>&1")
        end

        if wan_type == "pppoe" or wan_type == "static" then
            --luci.util.ubus("network.interface", "down", {interface = "wan"})
            --luci.util.ubus("network.interface", "up", {interface = "wan"})
            os.execute("ifdown wan; sleep 1; ifup wan; sleep 5")
        end
    elseif step and step == "step2" then
        local reg = require "luci.acn.reg"
        local default_register_url = require("luci.acn.brand").register_url
        local product = require("luci.acn.product")
        local radio_mode = http.formvalue("radio_mode")
        local template = http.formvalue("mode_template")
        local country_code  = http.formvalue("country_list") or "US"
        local ssid = http.formvalue("ssid")
        local psk_key = http.formvalue("psk_key")
        --local enable_adv = http.formvalue("enable_adv")
        local controller_mode = http.formvalue("radio_controller")
        local cloud_server = uci:get("acn", "register", "url") or default_register_url or "https://regsvc.ignitenet.com/register"
        local user_pwd = http.formvalue("user_pwd")

        local num_radios = product.num_wifi_radios
        local num_eth_ports = product.num_eth_ports

        local fcc_locked = product.fcc_locked()
        local thai_locked = product.thai_locked()
        local jp_locked = product.jp_locked()
        local in_locked = product.in_locked()
        local br_locked = product.br_locked()
        local is_EAP101 = product.is_EAP101()
        local is_EAP102 = product.is_EAP102()
        local is_EAP104 = product.is_EAP104()
        local is_OAP103 = product.is_OAP103()

        local cc = country_code

        local controlled = (controller_mode == "controlled")

        local client_ip = luci.sys.getenv("REMOTE_ADDR")

        if fcc_locked then
            cc = "US"
        end

        if thai_locked then
            cc = "TH"
        end

        if jp_locked then
            cc = "JP"
        end

        if in_locked then
            cc = "IN"
        end

        if br_locked then
            cc = "BR"
        end

        if controlled then
            uci:set("acn", "mgmt", "enabled", "1" )
            uci:set("acn", "mgmt", "management", "1" )
            uci:set("acn", "register", "url", cloud_server)
        else
            uci:set("acn", "mgmt", "enabled", "0" )
            uci:set("acn", "mgmt", "management", "0" )
            os.execute("touch /tmp/.ez_setup_alone_done >/dev/null 2>&1")
        end

        if user_pwd and user_pwd ~= "" then
            uci:set("users", "@login[1]", "passwd", user_pwd )
            uci:save("users")
            uci:commit("users")
        end

        -- Not setting country_other to 0 so that wireless settings aren't touched
        -- causing unnecessary restart of networking

        --if not controlled_ucentral then
            for i=0, num_radios -1 do

                uci:set("wireless", acn.radio_section(i), "country", cc)
                local channel = uci:get("wireless", acn.radio_section(i), "channel") or nil

                if not controlled then
                    -- setup main user as vap-1
                    local wifi_section = acn.wifi_section(i, 1)
                    uci:set("wireless", wifi_section, "ssid", ssid  or "None")
                    uci:set("wireless", wifi_section, "created", "1")

                    if psk_key and #psk_key > 0 then
                        uci:set("wireless", wifi_section, "key", psk_key or "")
                        uci:set("wireless", wifi_section, "disabled", "0")
                        uci:set("wireless", wifi_section, "encryption", "psk2+ccmp")
                        uci:set("wireless", wifi_section, "key_method", "psk")
                        uci:set("wireless", wifi_section, "wpa_strict_rekey", 0)
                        uci:set("wireless", wifi_section, "wpa_group_rekey", 86400)
                        uci:set("wireless", wifi_section, "eap_reauth_period", 0)
                        if i == 0 then
                            utl.ubus("meshd", "set_srv_config", {ssid = ssid, key = psk_key})
                        end
                    end

                    wifi_section = acn.wifi_section(i, 2)
                    uci:delete("wireless", wifi_section)
                    wifi_section = acn.wifi_section(i, 3)
                    uci:delete("wireless", wifi_section)
                end

                set_channels_txpwer(cc)
                uci:save("wireless")
                uci:commit("wireless")
            end
        --end

        if ez_setup == "1" then
            if controlled then
                uci:set("acn", "mgmt", "dev_ca_off", "1")
                uci:set("acn", "register", "state", "0")
                uci:set("acn", "mgmt", "register", cloud_server)
                uci:set("acn", "mgmt", "loglevel", "trace")

                -- let this client access internet via hidden ssid to setup cloud register 
                os.execute("ipset add open_ip " .. client_ip .. " >/dev/null 2>&1")
            else
                os.execute("touch /tmp/.ez_setup_alone >/dev/null 2>&1")
                fork_exec("sleep 5; /etc/init.d/network restart")
            end
        end

        uci:set("acn", "wizard", "enabled", "0")
        uci:set("acn", "wizard", "ez_setup", "2")

        uci:save("acn")
        uci:commit("acn")
        os.execute(
            ". /lib/wifi/regdomain.sh; " ..
            "cfg80211_set_regdomain %q >/dev/null"
            % cc
        )
    end
    luci.http.redirect(luci.dispatcher.build_url("admin/system/qr_wizard"))
end

function set_ezwizard()
    local http = require "luci.http"
    local reg = require "luci.acn.reg"
    local default_register_url = require("luci.acn.brand").register_url
    local acn = require("luci.acn.util")
    local product = require("luci.acn.product")
    local uci = acn.cursor()

    local radio_mode = http.formvalue("radio_mode")
    local template = http.formvalue("mode_template")
    local country_code  = http.formvalue("country_list") or "US"
    local ssid = http.formvalue("ssid")
    local psk_key = http.formvalue("psk_key")
    --local enable_adv = http.formvalue("enable_adv")
    local controller_mode = http.formvalue("radio_controller")
    local cloud_server = uci:get("acn", "register", "url") or default_register_url or "https://regsvc.ignitenet.com/register"
    local user_pwd = http.formvalue("user_pwd")

    local guest_ssid = http.formvalue("guest_ssid")
    local guest_psk_key = http.formvalue("guest_psk_key")

    local wan_type = http.formvalue("cbid.network.wan.proto")
    local ez_setup = uci:get("acn", "wizard", "ez_setup")

    local num_radios = product.num_wifi_radios
    local num_eth_ports = product.num_eth_ports

    local fcc_locked = product.fcc_locked()
    local thai_locked = product.thai_locked()
    local jp_locked = product.jp_locked()
    local in_locked = product.in_locked()
    local br_locked = product.br_locked()
    local is_EAP101 = product.is_EAP101()
    local is_EAP102 = product.is_EAP102()
    local is_EAP104 = product.is_EAP104()
    local is_OAP103 = product.is_OAP103()

    local cc = country_code

    local controlled = (controller_mode == "controlled")

    local controlled_ac = (controller_mode == "capwap")

    local controlled_ucentral = (controller_mode == "ucentral")

    local client_ip = luci.sys.getenv("REMOTE_ADDR")

    if fcc_locked then
        cc = "US"
    end

    if thai_locked then
        cc = "TH"
    end

    if jp_locked then
        cc = "JP"
    end

    if in_locked then
        cc = "IN"
    end

    if br_locked then
        cc = "BR"
    end

    uci:set("acn", "capwap", "state", "0" )
    uci:set("acn", "capwap", "dhcp_opt", "0" )

    if controlled then
        uci:set("acn", "mgmt", "enabled", "1" )
        uci:set("acn", "mgmt", "management", "1" )
        uci:set("acn", "register", "url", cloud_server)
    else
        uci:set("acn", "mgmt", "enabled", "0" )
        uci:set("acn", "mgmt", "management", "0" )
    end

    if controlled_ac then
        uci:set("acn", "mgmt", "management", "2" )
        local mode_capwap = http.formvalue("mode_capwap") or "0"

        -- mode_capwap 0:none, 1:auto, 2:manual
        if mode_capwap == "0" then
            uci:set("acn", "capwap", "state", "0" )
        elseif mode_capwap == "1" then
            uci:set("acn", "capwap", "state", "1" )
            uci:set("acn", "capwap", "broadcast", "255.255.255.255" )
            uci:set("acn", "capwap", "multicast", "224.0.1.140" )
            uci:set("acn", "capwap", "dns_srv", "1" )
            uci:set("acn", "capwap", "dhcp_opt", "1" )
        elseif mode_capwap == "2" then
            uci:set("acn", "capwap", "state", "1" )
            local dns_srv = "0"
            local srv_suffix = http.formvalue("srv_suffix") or ""
            local unicast = "0"

            if (http.formvalue("dns_srv") == "on") then
                dns_srv="1"
            else
                dns_srv="0"
            end

            if (http.formvalue("unicast") == "on") then
                unicast="1"
            else
                unicast="0"
            end

            uci:set("acn", "capwap", "dns_srv", dns_srv )
            uci:set("acn", "capwap", "srv_suffix", srv_suffix )
            uci:set("acn", "capwap", "unicast", unicast )

            -- Deal with list of ac
            local add_prefix = "acn.new"
            local del_prefix = "acn.del"

            -- This gets a list of all form values that begin with the prefix

            local new_rules = luci.http.formvaluetable(add_prefix) or ""
            -- want these sorted
            local keys = {}
            for k in pairs(new_rules) do keys[#keys+1] = k end
            table.sort(keys, function(a,b) return new_rules[a] < new_rules[b]  end)

            -- Need to use map.uci here so that the settings are saved
            for i,k in ipairs(keys) do

                local v = new_rules[k]
                -- value is our client-side generated section name (like 45f30e)

                if v then
                    -- v = cfg used for the temporary row
                    local deleted = luci.http.formvalue('acn.del.acn.cfg' .. v)
                    if deleted == "0" then
                        local ip = luci.http.formvalue('cbid.acn.cfg' .. v .. '.ip')
                        local remark = luci.http.formvalue('cbid.acn.cfg' .. v .. '.remark')

                        uci:section("acn", "capwap_ac", nil, {
                            ip      = ip,
                            remark  = remark,
                        })
                        -- If we don't do the save/load below, something messes up the internal counter
                        -- and uci sections start overwriting each other (see #497)
                        uci:save("acn")
                        uci:load("acn")
                    end
                end
            end

            table = luci.http.formvaluetable(del_prefix .. ".acn")

            for k, v in pairs(table) do
                if v and (v == "1" or v == 1) then
                    uci:delete_all("acn", "capwap_ac",
                    function(s) return s['.name'] == k end )
                end
            end
        end

    end

    if controlled_ucentral then
        uci:set("acn", "mgmt", "management", "3" )
    end

    if user_pwd and user_pwd ~= "" then
        uci:set("users", "@login[1]", "passwd", user_pwd )
        uci:save("users")
        uci:commit("users")
    end

     -- Not setting country_other to 0 so that wireless settings aren't touched
     -- causing unnecessary restart of networking

    if not controlled_ucentral then
        for i=0, num_radios -1 do

            uci:set("wireless", acn.radio_section(i), "country", cc )

            if not controlled then
                -- setup main user as vap-1
                local wifi_section = acn.wifi_section(i, 1)
                uci:set("wireless", wifi_section, "ssid", ssid  or "None")
                uci:set("wireless", wifi_section, "created", "1")

                if psk_key and #psk_key > 0 then
                    uci:set("wireless", wifi_section, "key", psk_key or "")
                    uci:set("wireless", wifi_section, "disabled", "0")
                    uci:set("wireless", wifi_section, "encryption", "psk2+ccmp")
                    uci:set("wireless", wifi_section, "key_method", "psk")
                    uci:set("wireless", wifi_section, "wpa_strict_rekey", 0)
                    uci:set("wireless", wifi_section, "wpa_group_rekey", 86400)
                    uci:set("wireless", wifi_section, "eap_reauth_period", 0)
                end
                -- Advanced settings
                --if enable_adv then
                    -- setup wan type
                    uci:set("network", "wan", "proto", wan_type)
                    if wan_type == "static" then
                        local wan_ip = http.formvalue("cbid.network.wan.ipaddr") or ""
                        local wan_netmask = http.formvalue("cbid.network.wan.netmask") or ""
                        local wan_gw = http.formvalue("cbid.network.wan.gateway") or ""
                        local wan_dns = http.formvalue("cbid.network.wan.dns") or ""
                        if wan_dns == "" then
                            wan_dns = wan_gw
                        end
                        uci:set("network", "wan", "ipaddr", wan_ip)
                        uci:set("network", "wan", "netmask", wan_netmask)
                        uci:set("network", "wan", "gateway", wan_gw)
                        uci:set("network", "wan", "dns", wan_dns)
                    end

                    if wan_type == "pppoe" then
                        local pppoe_user = http.formvalue("cbid.network.wan.username") or ""
                        local pppoe_pwd = http.formvalue("cbid.network.wan.password") or ""
                        uci:set("network", "wan", "username", pppoe_user)
                        uci:set("network", "wan", "password", pppoe_pwd)
                    end
                    uci:save("network")

                    -- setup guest ssid
                    if guest_ssid and #guest_ssid > 0 then
                        -- setup guest as vap-3, vap-2 is for hidden ssid
                        wifi_section = acn.wifi_section(i, 3)
                        if uci:get("wireless", wifi_section) ~= "wifi-iface" then
                            uci:set("wireless", wifi_section, "wifi-iface")
                        end

                        uci:set("wireless", wifi_section, "ssid", guest_ssid  or "Guest-SSID")
                        uci:set("wireless", wifi_section, "disabled", "0")
                        uci:set("wireless", wifi_section, "created", "1")
                        uci:set("wireless", wifi_section, "device", acn.radio_section(i))
                        uci:set("wireless", wifi_section, "network", "guest")
                        uci:set("wireless", wifi_section, "client_isolation", "1")

                        if guest_psk_key and #guest_psk_key > 0 then
                            uci:set("wireless", wifi_section, "key", guest_psk_key or "")
                            uci:set("wireless", wifi_section, "encryption", "psk2+ccmp")
                            uci:set("wireless", wifi_section, "key_method", "psk")
                            uci:set("wireless", wifi_section, "wpa_strict_rekey", 0)
                            uci:set("wireless", wifi_section, "wpa_group_rekey", 86400)
                            uci:set("wireless", wifi_section, "eap_reauth_period", 0)
                        end
                    end
                --end
            end

            wifi_section = acn.wifi_section(i, 2)
            uci:delete("wireless", wifi_section)
            wifi_section = acn.wifi_section(i, 3)
            uci:delete("wireless", wifi_section)

            set_channels_txpwer(cc)

            uci:save("wireless")

        end
    end

    if ez_setup == "1" then
        if controlled then
            uci:set("acn", "mgmt", "dev_ca_off", "1")
            uci:set("acn", "register", "state", "0")
            uci:set("acn", "mgmt", "register", cloud_server)
            uci:set("acn", "mgmt", "loglevel", "trace")

            -- let this client access internet via hidden ssid to setup cloud register 
            os.execute("ipset add open_ip " .. client_ip .. " >/dev/null 2>&1")
        --else
            --os.execute("touch /tmp/.ez_setup_alone >/dev/null 2>&1")
        end
        fork_exec("sh /sbin/enable_network_trigger.sh")
    end

    os.execute("touch /tmp/.ez_setup_alone >/dev/null 2>&1")
    uci:set("acn", "wizard", "enabled", "0")
    uci:set("acn", "wizard", "ez_setup", "2")

    uci:save("acn")
    uci:commit("acn")
    os.execute(
        ". /lib/wifi/regdomain.sh; " ..
        "cfg80211_set_regdomain %q >/dev/null"
        % cc
    )

    luci.http.redirect(luci.dispatcher.build_url("admin/system/wizard"))

end

function set_ezwizard_mgmt()
    local acn = require("luci.acn.util")
    local uci = acn.cursor()
    uci:commit("wireless")
    uci:commit("acn")
    os.execute("/etc/init.d/mgmt restart && /sbin/wifi reload_legacy")
end

function set_ezwizard_register()
    local acn = require("luci.acn.util")
    local uci = acn.cursor()
    uci:set("acn", "wizard", "ez_setup", "1")
--    uci:set("acn", "wizard", "enabled", "1")
    uci:save("acn")
    uci:commit("acn")
end

function set_ezwizard_success()
    local acn = require("luci.acn.util")
    local uci = acn.cursor()
	local utl = require("luci.util")

    local http = require "luci.http"
    local ssid = http.formvalue("ssid") or nil
    local key = http.formvalue("key") or nil

    if ssid and key then
        local product = require("luci.acn.product")
        local num_radios = product.num_wifi_radios

        utl.ubus("meshd", "set_srv_config", {ssid = ssid, key = key})
        for i=0, num_radios -1 do
            local wifi_section = acn.wifi_section(i, 2)
            uci:delete("wireless", wifi_section)
            wifi_section = acn.wifi_section(i, 3)
            uci:delete("wireless", wifi_section)
        end
		uci:commit("wireless")
    end

    uci:set("acn", "wizard", "ez_setup", "0")
    uci:save("acn")
    uci:commit("acn")
    fork_exec("sleep 1; /etc/init.d/network restart")
end

function set_ezwizard_fail()
    local acn = require("luci.acn.util")
    local uci = acn.cursor()
    uci:set("acn", "wizard", "ez_setup", "1")
    uci:save("acn")
    uci:commit("acn")
end

function set_channels_txpwer(country_val)
  local reg = require "luci.acn.reg"
  local cert = reg.get_TxPowerCert_info(country_val) or ""
  local setup_wiz = "1"
  luci.sys.call("/sbin/setup_default_max_txpower.sh " .. cert .. " " .. setup_wiz)
end

function fork_exec(command)
    local pid = nixio.fork()
    if pid > 0 then
        return
    elseif pid == 0 then
        -- change to root dir
        nixio.chdir("/")

        -- patch stdin, out, err to /dev/null
        local null = nixio.open("/dev/null", "w+")
        if null then
            nixio.dup(null, nixio.stderr)
            nixio.dup(null, nixio.stdout)
            nixio.dup(null, nixio.stdin)
            if null:fileno() > 2 then
                null:close()
            end
        end

        -- replace with target command
        nixio.exec("/bin/sh", "-c", command)
    end
end

function ACN_actions()
    local sys = require "luci.sys"

    local upgrade_avail = fs.access("/lib/upgrade/platform.sh")
    local reset_avail   = os.execute([[grep '"rootfs_data"' /proc/mtd >/dev/null 2>&1]]) == 0
    local has_openssl = fs.access("/usr/bin/openssl")

    local restore_cmd = "tar -xzC/ >/dev/null 2>&1"
    local post_restore_cmd = ". /lib/acn/post-restore.sh"
    local config_tmp = ""
    local backup_cmd = ""
    local key = ""

    if has_openssl then
        key = product.system_info("product_name"):gsub("\r", ""):gsub("\n", "")
        if key == "" then
            key = "ACN"
        end
        backup_cmd = "tar -czT %s | openssl des3 -e -pass pass:"..key.." 2>/dev/null"
        config_tmp = "/tmp/cfg.tmp"
    else
        backup_cmd  = "tar -czT %s 2>/dev/null"
    end

    local image_tmp   = "/tmp/firmware.img"

    local function image_supported()

        return ( 0 == os.execute(
            ". /lib/functions.sh; " ..
            "include /lib/upgrade; " ..
            "platform_check_image %q >/dev/null"
                % image_tmp
        ) )
    end

    local function image_checksum()
        return (luci.sys.exec("md5sum %q" % image_tmp):match("^([^%s]+)"))
    end

    local function storage_size()
        local size = 0
        local active_partname = luci.util.exec(". /lib/functions.sh; include /lib/upgrade; get_active_part"):gsub("\n", "")
        if fs.access("/proc/mtd") then
            for l in io.lines("/proc/mtd") do
                local d, s, e, n = l:match('^([^%s]+)%s+([^%s]+)%s+([^%s]+)%s+"([^%s]+)"')
                if n == active_partname then
                    size = tonumber(s, 16)
                    break
                else
                    if n == "linux" or n == "firmware" then
                        size = tonumber(s, 16)
                        break
                    end
                end
            end
        elseif fs.access("/proc/partitions") then
            for l in io.lines("/proc/partitions") do
                local x, y, b, n = l:match('^%s*(%d+)%s+(%d+)%s+([^%s]+)%s+([^%s]+)')
                if b and n and not n:match('[0-9]') then
                    size = tonumber(b) * 1024
                    break
                end
            end
        end
        return size
    end

    local function config_supported()
          return ( 0 == os.execute(
               "/usr/sbin/config_restore.sh %q %q >/dev/null"
            %{ config_tmp, key }
         ) )
       end

    local fp
    luci.http.setfilehandler(
        function(meta, chunk, eof)
            if not fp then
                if meta and meta.name == "image" then
                    luci.sys.call("rm -f /tmp/firmware*")
                    fp = io.open(image_tmp, "w")
                else
                    if has_openssl then
                        fp = io.open(config_tmp, "w")
                    else
                        fp = io.popen(restore_cmd, "w")
                    end
                end
            end
            if chunk then
                fp:write(chunk)
            end
            if eof then
                fp:close()
            end
        end
    )

    if not luci.http.formvalue("image") and not luci.http.formvalue("step") then
        os.execute("rm -rf "..image_tmp)
        os.execute("sync; echo 3 > /proc/sys/vm/drop_caches")
    end

    if luci.http.formvalue("backup") then
        --
        -- Assemble file list, generate backup
        --
        local filelist = "/tmp/luci-backup-list.%d" % os.time()
        sys.call(
            "( find $(sed -ne '/^[[:space:]]*$/d; /^#/d; p' /etc/sysupgrade.conf " ..
            "/lib/upgrade/keep.d/* 2>/dev/null) -type f 2>/dev/null; " ..
            "opkg list-changed-conffiles ) | sort -u > %s" % filelist
        )
        if fs.access(filelist) then
            local reader = ltn12_popen(backup_cmd:format(filelist))
            luci.http.header('Content-Disposition', 'attachment; filename="backup-%s-%s.tar.gz"' % {
                product_name, os.date("%Y-%m-%d")})
            luci.http.prepare_content("application/x-targz")
            luci.ltn12.pump.all(reader, luci.http.write)
            fs.unlink(filelist)
        end

    elseif luci.http.formvalue("download_troubleshooting") then
        local down_ts_cmd  = "cat %s 2>/dev/null"
        local ts_file = "/tmp/trouble.tgz"
        res = os.execute("/usr/sbin/trouble.sh " .. ts_file)

        if fs.access(ts_file) then
            local reader = ltn12_popen(down_ts_cmd:format(ts_file))
            local mac_addr = (fs.readfile("/sys/class/net/eth0/address") or ""):gsub("%c",""):gsub(":","")
            luci.http.header('Content-Disposition', 'attachment; filename="diagnostics_%s_%s_%s.tar.gz"' % {
                product_name, os.date("%Y%m%d"), mac_addr})
            luci.http.prepare_content("application/x-targz")
            luci.ltn12.pump.all(reader, luci.http.write)
            fs.unlink(ts_file)
        end

    elseif luci.http.formvalue("default") then
        luci.template.render("admin_system/applyreboot")
        
        luci.sys.call("sleep 1; /sbin/reset_to_defaults.sh -y")
        luci.sys.reboot()    
    elseif luci.http.formvalue("restore") then
        --
        -- Unpack received .tar.gz
        --
        local upload = luci.http.formvalue("config_file")
        if upload and #upload > 0 then
            if has_openssl then
                if config_supported() then
                    luci.template.render("cbi/actions", {
                            restore_in_progress   = true
                    })
                    os.execute(post_restore_cmd)
                    luci.sys.reboot()
                else
                    fs.unlink(config_tmp)
                    luci.template.render("cbi/actions", {
                        config_invalid = true,
                        restore_in_progress = true
                    })
                end
            else
                luci.template.render("cbi/actions", {
                    restore_in_progress   = true
                })
                os.execute(post_restore_cmd)
                luci.sys.reboot()
            end
        end
    elseif luci.http.formvalue("image") or luci.http.formvalue("step") then
        --
        -- Initiate firmware flash
        --
        local step = tonumber(luci.http.formvalue("step") or 1)
        if step == 1 then
            if image_supported() then
                luci.template.render("admin_system/upgrade", {
                    checksum = image_checksum(),
                    storage  = storage_size(),
                    size     = fs.stat(image_tmp).size,
                    keep     = (not not luci.http.formvalue("keep"))
                })
            else
                fs.unlink(image_tmp)
                luci.template.render("cbi/actions", {
                    reset_avail   = reset_avail,
                    upgrade_avail = upgrade_avail,
                    image_invalid = true,
                    upgrade_in_progress = true
                })
            end
        --
        -- Start sysupgrade flash
        --
        elseif step == 2 then
            local keep = (luci.http.formvalue("keep") == "1") and "" or "-n"

            luci.template.render("cbi/actions", {
                    upgrade_in_progress = true
            })

            fork_exec("sleep 1; /sbin/sysupgrade %s %q" %{ keep, image_tmp })
        end
    elseif reset_avail and luci.http.formvalue("reset") then
        --
        -- Reset system
        --
        luci.template.render("admin_system/applyreboot", {
            title = luci.i18n.translate("Erasing..."),
            msg   = luci.i18n.translate("The system is erasing the configuration partition now and will reboot itself when finished."),
            addr  = "192.168.1.1"
        })
        fork_exec("sleep 1; /sbin/reset_to_defaults.sh -y")
    else
        --
        -- Overview
        --
        luci.sys.call("rm -f /tmp/firmware*")
        luci.template.render("cbi/actions", {
            reset_avail   = reset_avail,
            upgrade_avail = upgrade_avail
        })
    end
end

function ACN_ca_actions()
    local sys = require "luci.sys"
    local ca_tmp = ""
    local function certificate_supported()
        return ( 0 == os.execute("certificate_upload.sh >/dev/null"))
    end
    local fp
    luci.http.setfilehandler(
        function(meta, chunk, eof)
            if not fp then
                if meta and (meta.name == "crt_file" or meta.name == "key_file") then
                    ca_tmp = "/tmp/server.tmp." .. meta.name
                    fp = io.open(ca_tmp, "w")
                end
            end

            if fp and chunk and chunk ~="" then
                fp:write(chunk)
            end

            if fp and eof then
                fp:close()
                fp = nil
            end
        end
    )
    if luci.http.formvalue("upload_crt") then
        local file_is_valid = false
        local has_crt_file = fs.access("/tmp/server.tmp.crt_file")
        local has_key_file = fs.access("/tmp/server.tmp.key_file")
        if has_crt_file and has_key_file then
            if certificate_supported() then
                luci.template.render("admin_system/certificate", {
                    upload_crt_in_progress   = true
                })
                fork_exec("sleep 3; /etc/init.d/dnsmasq restart; /ramfs/bin/run_uamd.sh start")
                file_is_valid = true
            end
        end
        if not file_is_valid then
            luci.template.render("admin_system/certificate", {
                crt_invalid = true,
                upload_crt_in_progress = true
            })
        end
    else
        luci.template.render("admin_system/certificate")
    end
end

function action_syslog()
    local syslog = luci.sys.syslog()
    luci.template.render("admin_status/syslog", {syslog=syslog})
end

function action_syslog_text()
    luci.http.write(luci.sys.syslog():pcdata())
end

function dev_reboot()
    luci.sys.reboot()
end

function reset_ca_default()
    luci.template.render("admin_system/certificate")
    fork_exec("sleep 1; /usr/sbin/certificate_upload.sh reset_factory")
end

function ca_content()
    local acn_status = require "luci.acn.status"
    local certificate_file = "/tmp/.certificate_parsed"
    if not fs.access(certificate_file) then
        luci.sys.call("/usr/sbin/certificate_read.sh")
    end
    local output = fs.readfile('/tmp/.certificate_parsed')
    local ca_stats = output and json.decode(output)
    luci.http.prepare_content("application/json")
    luci.http.write_json(ca_stats)
end

function dev_reset_def()
    luci.template.render("admin_system/applyreboot", {
        title = luci.i18n.translate("Erasing..."),
        msg = luci.i18n.translate("The system is erasing the configuration partition now and will reboot itself when finished."),
        addr = "192.168.1.10"
    })
    fork_exec("sleep 1; /sbin/reset_to_defaults.sh -y")
end

function discovery_start()
    os.execute(DEVICE_DISCOVERY_CMD .. " >/dev/null")
    local res = fs.readfile(DEVICE_DISCOVERY_FILE)
    local discovery_list = json.decode(res) or {}
    luci.http.prepare_content("application/json")
    luci.http.write_json(discovery_list)
end

function discovery_stop()
    os.execute("rm -f " .. DEVICE_DISCOVERY_FILE .. " >/dev/null")
    luci.http.prepare_content("application/json")
    luci.http.write_json("")
end
