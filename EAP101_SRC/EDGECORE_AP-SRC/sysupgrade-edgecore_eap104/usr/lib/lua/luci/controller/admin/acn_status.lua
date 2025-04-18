--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2011 Jo-Philipp Wich <xm@subsignal.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

$Id: status.lua 7810 2011-10-28 15:15:27Z jow $
]]--
local fs = require "nixio.fs"
local json = require "cjson.safe"
local nixio = require "nixio"

module("luci.controller.admin.acn_status", package.seeall)

function index()

    local fs = require "nixio.fs"
    local has_speedtest = fs.access("/usr/sbin/speedtest")

    entry({"admin", "acn_status"}, alias("admin", "acn_status", "overview"), _("System Status"), 20).index = true
    entry({"admin", "acn_status", "overview"}, template("admin_status/index"), _("System Status"), 1)

    entry({"admin", "acn_status", "traffic_graph_data"}, call("get_traffic_graph_data")).leaf = true
    entry({"admin", "acn_status", "connected_clients"}, call("get_connected_clients")).leaf = true
    entry({"admin", "acn_status", "client_status"}, call("get_client_status")).leaf = true

    entry({"admin", "acn_status", "remote_firmware_version"}, call("get_remote_firmware_version")).leaf = true
    entry({"admin", "acn_status", "dfs_status"}, call("get_dfs_status")).leaf = true

    entry({"admin", "acn_status", "dhcp_leases"}, template("cbi/dhcp_leases"), _("DHCP Leases"), 3)
    entry({"admin", "acn_status", "arp_table"}, template("cbi/arp_table"), _("ARP Table"), 1)

    pagewizard =entry({"admin", "acn_status", "wizard"},  call("set_wizard"), nil)
    pagewizard.leaf   = true


    --Renew dhcp in satauspage
    entry({"admin", "acn_status", "renewdhcp"}, call("renewdhcp"), _("Renewdhcp"), 4)

    entry({"admin", "acn_status", "monitor"}, template("admin_status/monitor"), _("Monitor"), 5)

    if has_speedtest then
        page = node("admin", "acn_status", "speedtest")
        page.target = template("admin_status/speedtest")
        page.title = _("Speed Test")
        page.order = 70

        page = entry({"admin", "acn_status", "run_speedtest"}, call("run_speedtest"), nil)
        page.leaf = true

        page = entry({"admin", "acn_status", "get_speedtest"}, call("get_speedtest"), nil)
        page.leaf = true

        page = entry({"admin", "acn_status", "stop_speedtest"}, call("stop_speedtest"), nil)
        page.leaf = true
    end

    -- for auth port 
    entry({"admin", "acn_status", "wi_anchor"}, template("admin_status/wi_anchor"), _("Smart Indoor Location Solution"), 1)
    entry({"admin", "acn_status", "set_wi_anchor_binding"}, call("set_wi_anchor_binding"), nil)
end

--=================================================================================================
-- Get connection status of client radio
--===================================================================================================
function get_client_status(ifname)
    local acn_status = require "luci.acn.status"
    local ifname = luci.http.formvalue("ifname") or ""

    local info = acn_status.client_link_info(ifname)

    luci.http.prepare_content("application/json")
    luci.http.write_json(info)
end

--===================================================================================================
-- Get connected clients for dashboard page
--===================================================================================================
function get_connected_clients()
    local acn_status = require "luci.acn.status"
    local res = { }
    local ifname = luci.http.formvalue("ifname") or ""
    local clients = acn_status.connected_clients(ifname)
    res.clients = clients
    luci.http.prepare_content("application/json")
    luci.http.write_json(res)
end

--- Returns network interfaces bandwidth statistics.
-- Initiates bwmonitor utility if one is not running
-- This method does not guarantee that bandwidth statistics will be available
-- when invoked (especially for the first call and during first 5sec period).
-- Multiple calls guaratees that.
function get_bwmonitor(precise)
    local product = require "luci.acn.product"
    local fs = require "nixio.fs"
    local res = luci.util.exec("ps | grep 'bwmonitor.sh' | grep -v grep 2>/dev/null") or nil

    if res == nil or res == "" then
        os.execute("/sbin/bwmonitor.sh")
        return
    end

    --bwmonitor_now record tx/rx info now
    --bwmonitor_old record tx/rx info around 5 secode before
    local bwnow = fs.readfile('/tmp/bwmonitor_now.json') or ""
    local bwnow_output = json.decode(bwnow)
    local bwold = fs.readfile('/tmp/bwmonitor_old.json') or ""
    local bwold_output = json.decode(bwold)

    local bwdata_decode = {}
    if bwnow_output then
        local time = bwnow_output["uptime"] - bwold_output["uptime"]

        for ifname, ifinfo in pairs(bwnow_output["interfaces"]) do
            local ifdata = bwold_output.interfaces[ifname]

            local delta_rxBytes = ifinfo["rxBytes"] - ifdata["rxBytes"]
            if delta_rxBytes < 0 then
                delta_rxBytes = ifinfo["rxBytes"]
            end
            local delta_txBytes = ifinfo["txBytes"] - ifdata["txBytes"]
            if delta_txBytes < 0 then
                delta_txBytes = ifinfo["txBytes"]
            end
            ifdata.rxRatePrecise = (delta_rxBytes*8) / time
            ifdata.txRatePrecise = (delta_txBytes*8) / time
            ifdata.rxCountPrecise = ifinfo["rxBytes"]
            ifdata.txCountPrecise = ifinfo["txBytes"]

            -- collect wlanX-Y.Z into wlanX-Y in dynamic vlan scenario
            local pre_wlan_iface = ifname:match(product.wifi_prefix .. '%d%-%d+') or ifname:match(product.wifi_prefix .. '%d+') or ifname

            if bwdata_decode[pre_wlan_iface] == nil then
                bwdata_decode[pre_wlan_iface] = ifdata
            else
                bwdata_decode[pre_wlan_iface]["rxRatePrecise"] = bwdata_decode[pre_wlan_iface]["rxRatePrecise"] + ifdata.rxRatePrecise
                bwdata_decode[pre_wlan_iface]["txRatePrecise"] = bwdata_decode[pre_wlan_iface]["txRatePrecise"] + ifdata.txRatePrecise
                bwdata_decode[pre_wlan_iface]["rxCountPrecise"] = bwdata_decode[pre_wlan_iface]["rxCountPrecise"] + ifdata.rxCountPrecise
                bwdata_decode[pre_wlan_iface]["txCountPrecise"] = bwdata_decode[pre_wlan_iface]["txCountPrecise"] + ifdata.txCountPrecise
            end

        end
    end
    return bwdata_decode
end 

--=================================================================================================
-- Get live stats for dashboard page
--===================================================================================================
function get_traffic_graph_data()

    local product = require "luci.acn.product"
    local acn = require "luci.acn.util"
    local uci = acn.cursor()

    num_eth_ports = product.num_eth_ports
    num_radios = product.num_wifi_radios

    local res = { time = os.time(), ifaces = {} }
    local devs = get_bwmonitor(true) or {}

    for i=0, num_eth_ports -1 do
        local iface = 'eth' .. i
        local eth = product.eth(i)
        local dev = devs[eth.dev_name]
        local tx, rx, tx_rate, rx_rate = 0, 0, 0, 0

        if dev then
            tx = dev.txCountPrecise
            rx = dev.rxCountPrecise
            tx_rate = dev.txRatePrecise
            rx_rate = dev.rxRatePrecise
        end

        local stats =  {
            tx_bytes = tx,
            rx_bytes = rx,
            tx_rate = tx_rate,
            rx_rate = rx_rate
        }

        res['ifaces'][iface] = stats
    end

    for i=0, num_radios -1 do
        local iface = 'radio' .. i
        local tx, rx, tx_rate, rx_rate = 0, 0, 0, 0
        local radio = product.radio(i)

        -- Add up stats for all ssids under this radio (not scanning/tmp ifaces tho)
        for s=0, radio.max_ssids -1 do
            local wiface = product.wifi_prefix .. i
            local dev

            if s == 0 then 
                dev = devs[wiface]
            else 
                dev = devs[wiface .. '-' .. s]
            end

            if dev then
                tx = tx + (dev.txCountPrecise or 0)
                rx = rx + (dev.rxCountPrecise or 0)
                tx_rate = tx_rate + (dev.txRatePrecise or 0)
                rx_rate = rx_rate + (dev.rxRatePrecise or 0)
            end
        end

        local stats =  {
            tx_bytes = tx,
            rx_bytes = rx,
            tx_rate = tx_rate,
            rx_rate = rx_rate
        }

        res['ifaces'][iface] = stats
    end

    if product.supports_3g() and acn.detected_dongle() then
        -- 3G/LTE
        local wan_inet_src = uci:get("network", "wan", "inet_src")
        local dev_name_3g = product.dev_name_3g or "3g-wan"
        if wan_inet_src == "wwan0" then
            dev_name_3g = wan_inet_src
        end
        local dev = devs[dev_name_3g]
        local tx, rx, tx_rate, rx_rate = 0, 0, 0, 0

        if dev then
            tx = dev.txCountPrecise
            rx = dev.rxCountPrecise
            tx_rate = dev.txRatePrecise
            rx_rate = dev.rxRatePrecise
        end

        local stats =  {
            tx_bytes = tx,
            rx_bytes = rx,
            tx_rate = tx_rate,
            rx_rate = rx_rate
        }

        res['ifaces'][dev_name_3g] = stats
    end

    if product.supports_mesh() and uci:get("wireless", "wmesh", "device") then
        local dev_name_mesh = product.dev_name_mesh or "mesh0"
        local dev = devs[dev_name_mesh]
        local tx, rx, tx_rate, rx_rate = 0, 0, 0, 0

        if dev then
            tx = dev.txCountPrecise
            rx = dev.rxCountPrecise
            tx_rate = dev.txRatePrecise
            rx_rate = dev.rxRatePrecise
        end

        local stats =  {
            tx_bytes = tx,
            rx_bytes = rx,
            tx_rate = tx_rate,
            rx_rate = rx_rate
        }

        res['ifaces'][dev_name_mesh] = stats
    end

    luci.http.prepare_content("application/json")
    luci.http.write_json(res)
end

--=================================================================================================
-- Get aming mode data
--===================================================================================================
function get_aiming_mode_tx_data()
    luci.sys.call("/usr/sbin/prs_aiming_mode_tx 2>/dev/null")
    local res = luci.util.exec("/usr/sbin/prs_aiming_mode_rssi 2>/dev/null")
    luci.http.prepare_content("application/json")
    luci.http.write_json(res)
end

function get_aiming_mode_rx_data()
    luci.sys.call("/usr/sbin/prs_aiming_mode_rx 2>/dev/null")
    local res = luci.util.exec("/usr/sbin/prs_aiming_mode_rssi 2>/dev/null")
    luci.http.prepare_content("application/json")
    luci.http.write_json(res)
end

--===================================================================================================
function get_remote_firmware_version()
    local product = require("luci.acn.product")
    local firmware_family = product.firmware_family
    local brand_website = require("luci.acn.brand").controller_url
    local check_remote_fw = require("luci.acn.brand").check_remote_fw;
    local res = "{}"
    if check_remote_fw then
        local url = brand_website .. "pub/v1/public/fw-check?name=" .. firmware_family
        url = string.gsub(url, ' ', '%%20') -- escape spaces
        res = luci.util.exec("wget -qO- --no-check-certificate '" .. url .. "'")
    end

    luci.http.prepare_content("application/json")
    luci.http.write(res)
end
--===================================================================================================
function renewdhcp()
    luci.sys.call("renewdhcp")
end


function action_iptables()
    if luci.http.formvalue("zero") then
        if luci.http.formvalue("zero") == "6" then
            luci.util.exec("ip6tables -Z")
        else
            luci.util.exec("iptables -Z")
        end
        luci.http.redirect(
            luci.dispatcher.build_url("admin", "acn_status", "iptables")
        )
    elseif luci.http.formvalue("restart") == "1" then
        luci.util.exec("/etc/init.d/firewall restart")
        luci.http.redirect(
            luci.dispatcher.build_url("admin", "acn_status", "iptables")
        )
    else
        luci.template.render("admin_status/iptables")
    end
end

--===================================================================================================
local function parse_dfs_cac_time()
    local stats_file = "/var/run/stats/wireless.json"
    local fs = require "nixio.fs"
    local fl = fs.readfile(stats_file) or ""
    local cac = fl:match("\"cac\":%s(%d+)") or "0"

    return json.encode({ ["cac"] = tonumber(cac) })
end

function get_dfs_status()
    local res = parse_dfs_cac_time()
    luci.http.prepare_content("application/json")
    luci.http.write_json(res)
end
--===================================================================================================

function set_wizard()
    local http = require "luci.http"

    local username = http.formvalue("username") or "root"
    local password = http.formvalue("password1") or "admin123"
    local radio_mode = http.formvalue("radio_mode")
    local template = http.formvalue("mode_template")
    local country_code  = http.formvalue("country_list") or "US"
    local ssid = http.formvalue("ssid")
    local psk_key = http.formvalue("psk_key")
    local controller_mode = http.formvalue("radio_controller")

    local guest_ssid = http.formvalue("guest_ssid")
    local guest_psk_key = http.formvalue("guest_psk_key")

    local acn = require("luci.acn.util")
    local product = require("luci.acn.product")
    local uci = acn.cursor()

    local num_radios = product.num_wifi_radios
    local num_eth_ports = product.num_eth_ports

    local fcc_locked = product.fcc_locked()
    local thai_locked = product.thai_locked()

    local cc = country_code

    local controlled = (controller_mode == "controlled")

    if fcc_locked then
        cc = "US"
    end

    if thai_locked then
        cc = "TH"
    end

    if controlled then
        uci:set("acn", "mgmt", "enabled", "1" )
    else
        uci:set("acn", "mgmt", "enabled", "0" )
    end

    -- Remove every default account, then add the current account and new password
    uci:foreach("users", "login",
    function(s)
        uci:delete("users", s['.name'])
    end)

    uci:section("users", "login", nil, {
        enabled = 1,
        name = username,
        passwd = password,
    })

     -- Not setting country_other to 0 so that wireless settings aren't touched
     -- causing unnecessary restart of networking

    for i=0, num_radios -1 do

        uci:set("wireless", acn.radio_section(i), "country", cc )

        if not controlled and radio_mode == "easy" then

            uci:set("wireless", acn.wifi_section(i, 1), "ssid", ssid  or "None")
            uci:set("wireless", acn.wifi_section(i, 1), "created", "1")

            if psk_key and #psk_key > 0 then
                uci:set("wireless", acn.wifi_section(i, 1), "key", psk_key or "")
                uci:set("wireless", acn.wifi_section(i, 1), "disabled", "0")
                uci:set("wireless", acn.wifi_section(i, 1), "encryption", "psk2")
            end

            if guest_ssid and #guest_ssid > 0 then
                uci:set("wireless", acn.wifi_section(i, 2), "ssid", guest_ssid  or "Guest-SSID")
                uci:set("wireless", acn.wifi_section(i, 2), "disabled", "0")
                uci:set("wireless", acn.wifi_section(i, 2), "created", "1")
                uci:set("wireless", acn.wifi_section(i, 2), "network", "guest")
                uci:set("wireless", acn.wifi_section(i, 2), "client_isolation", "1")

                if guest_psk_key and #guest_psk_key > 0 then
                    uci:set("wireless", acn.wifi_section(i, 2), "key", guest_psk_key or "")
                    uci:set("wireless", acn.wifi_section(i, 2), "encryption", "psk2")

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
    uci:save("users")

    os.execute(
        ". /lib/wifi/regdomain.sh; " ..
        "cfg80211_set_regdomain %q >/dev/null"
        % cc
    )

    luci.http.redirect(luci.dispatcher.build_url("admin/acn_status/overview"))
end

function run_speedtest()
    local nxo = require "nixio"
    local acn = require "luci.acn.util"
    local json = require "cjson.safe"
    local fs = require "nixio.fs"
    local acn_status = require "luci.acn.status"
    local uci = acn.cursor()
    local path = luci.dispatcher.context.requestpath
    local args = path[#path]
    local peer, size, dir = args:match("^([a-zA-Z0-9]+),([0-9]+),([a-z]+)$")
    local delay = "0"
    local sessions = "10"
    local packets = "100000"
    local tmpfile = "/tmp/speedtest.tmp"
    local pidfile = "/var/run/speedtest.pid"
    local wan_dev = acn_status.get_wan_device()
    if peer == nil or size == nil or dir == nil or wan_dev == nil then
        luci.http.status(500, "Bad address")
        return
    end
    local running = fs.access(pidfile)
    if running then
        luci.http.status(400, "Already running")
        return
    end
    local mac = acn.linkid_to_mac(acn.get_bond_linkid(peer))
    if mac == nil then
        luci.http.status(400, "Bad peer")
        return
    end
    if dir == "local" then
        dir = ""
    elseif dir == "remote" then
        -- remote direction should only be available from AP side
        local brwan_mac = fs.readfile("/sys/class/net/" .. wan_dev .. "/address")
        dir = "-r -n bond0 -m " .. brwan_mac:gsub("\n", "")
    else
        luci.http.status(400, "Bad direction")
        return
    end
    local mtu = uci:get("network", "wan", "mtu") or 1500
    if tonumber(size) > tonumber(mtu) or tonumber(size) < 64 then
        luci.http.status(400, "Bad packet size")
        return
    end
    local active = fs.readfile("/sys/class/net/" .. peer .. "/bonding/active_slave") or ""
    if active:match("ath") then
        -- increase delay for 5G link
        delay = "20000"
    end

    local cmd = "speedtest -j -t %d -c %d -d %d -s %d -p %s -i %s %s > %s &"
    cmd = cmd:format(sessions, packets, delay, size, mac, peer, dir, tmpfile)
    fs.remove(tmpfile)
    os.execute(cmd)
    local retry = 0

    -- os.execute returns before tmpfile is created so io.open can fail to find the file
    while not fs.access(tmpfile) do
        retry = retry + 1
        if retry > 10 then
            luci.http.status(500, "Timeout")
            return
        end
        nixio.nanosleep(1)
    end
    local res = {}
    local util = io.open(tmpfile)
    if util then
        retry = 0
        while true do
            if retry > 20 then
                luci.http.status(500, "Timeout")
                return
            end
            local ln = util:read("*l")
            if ln then
                -- return only the first line with results or error
                res[1] = json.decode(ln) or {}
                luci.http.prepare_content("application/json")
                luci.http.write_json({speedtest = res})
                break
            else
                retry = retry + 1
                nixio.nanosleep(1)
            end
        end

        util:close()
    end
    return
end

function get_speedtest()
    local json = require "cjson.safe"
    local tmpfile = "/tmp/speedtest.tmp"
    local res = {}
    luci.http.prepare_content("application/json")
    local util = io.open(tmpfile)
    if util then
        while true do
            local ln = util:read("*l")
            if not ln then break end
            res[#res+1] = json.decode(ln) or {}
        end

        util:close()
    end
    luci.http.write_json({speedtest = res})
    return
end

function stop_speedtest()
    local pidfile = "/var/run/speedtest.pid"
    local fs = require "nixio.fs"
    local pid = fs.readfile(pidfile)
    if pid then
        os.execute("kill -9 " .. pid)
        fs.remove(pidfile)
    end
    luci.http.prepare_content("application/json")
    luci.http.write_json("")
    return
end

function set_wi_anchor_binding()
    local acn = require "luci.acn.util"
    local uci = acn.cursor()
    local id_type = luci.http.formvalue("id_type")
    local os_type = luci.http.formvalue("os_type") -- 0:other/default , 1:ios , 2:android, 3:win
    local client_ip = tostring(luci.http.getenv("REMOTE_ADDR"))
    local emp_num, guest_name, guest_phone, client_mac

    if client_ip then
        -- format:2e32dcb3cd25
        client_mac = client_ip and luci.util.exec("arp -n | grep " .. client_ip .. " | awk '{print $4}' | sed 's/://g'  | xargs echo -n ") or ""
    end

    if id_type == "employee" then
      id_type = "0"
      emp_num = luci.http.formvalue("emp_num")

      if emp_num and client_mac then
        luci.util.exec("sleep 1; /sbin/wi_anchor_curl.sh " .. id_type .. " " .. client_mac .. " " .. client_ip .. " " .. emp_num .. " " .. os_type)
      end
    else
      id_type = "1"
      guest_name = luci.http.formvalue("guest_name")
      guest_phone = luci.http.formvalue("guest_phone")

      if guest_name and guest_phone and client_mac then
        luci.util.exec("sleep 1; /sbin/wi_anchor_curl.sh " .. id_type .. " " .. client_mac .. " " .. client_ip .. " " .. guest_name .. " " .. os_type .. " " .. guest_phone)
      end
    end

    luci.template.render("admin_status/wi_anchor", {
      return_val="success"
    })

end
