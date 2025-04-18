local fs = require "nixio.fs"
local json = require "cjson.safe"
local acn_util = require "luci.acn.util"
local luci_util = (luci and luci.util) or require("luci.util")
local acn_uci = acn_util.cursor()
local reg = require "luci.acn.reg"
local product = require("luci.acn.product")
local is_EAP101 = product.is_EAP101()
local is_EAP102 = product.is_EAP102()
local is_OAP103 = product.is_OAP103()
local is_EAP104 = product.is_EAP104()

module("luci.controller.admin.wireless", package.seeall)

function index()
    entry({"admin", "wireless"}, alias("admin", "status", "overview"), _("Status"), 20).index = true

    pagewifi = entry({"admin", "wireless", "wifi"}, cbi("wifi"), _("Wireless"), 6)
    pagewifi.leaf   = true

    pagewifi = entry({"admin", "wireless", "vlans"}, template("admin_wireless/vlans"), _("Wireless"), 7)
    pagewifi.leaf   = true

    pagewifi = entry({"admin", "wireless", "scan"}, call("get_scan_results"), _("Scan"), 8)
    pagewifi.leaf   = true

    pagewifi = entry({"admin", "wireless", "get_channel_list"}, call("get_channel_list"), _("Scan"), 8)
    pagewifi.leaf   = true

    pagewifi = entry({"admin", "wireless", "setpower"}, call("setpower"), _("Set Power"), 9)
    pagewifi.leaf   = true

    pagewifi = entry({"admin", "wireless", "getmaxpower"}, call("getmaxpower"), _("Get Max Power"), 10)
    pagewifi.leaf   = true

    pagewifi = entry({"admin", "wireless", "kickStation"}, call("kickstation"), _("Kick Station"), 11)
    pagewifi.leaf   = true

    pagewifi = entry({"admin", "wireless", "getAllClientsInfo"}, call("getAllClientsInfo"), _("NMS client info"), 12)
    pagewifi.leaf   = true

    pagewifi = entry({"admin", "wireless", "setChannel"}, call("setChannel"), _("NMS max power"), 13)
    pagewifi.leaf   = true

    pagewifi = entry({"admin", "wireless", "getAPRunTimeInfo"}, call("getAPRunTimeInfo"), _("NMS AP runtime info"), 14)
    pagewifi.leaf   = true
end

function get_scan_results(dev, mode, show_join)

    local show_join = show_join and (show_join == "show_join")

    local sys = require "luci.sys"

    pre_dev_name = "wlan"
    ifname_idx = dev and dev:match(pre_dev_name .. "(%d+)")
    phyname = "phy" .. ifname_idx

    if mode == "ap" then -- use phyX when using AP mode
        dev = phyname
    end

    local iw = luci.sys.wifi.getiwinfo(dev)

    luci.template.render("cbi/wifi_scan_table",
            {scanlist = (iw and iw.scanlist) or {},
            show_join = show_join,
            radio_id = dev})
end

function get_channel_list(dev)
    local CHANNEL_JSON_FILE = "/tmp/channel_list.json"
    local channel_list = {}
    if dev then
        os.execute("radiotool -i " .. dev .. " -c - -j > " .. CHANNEL_JSON_FILE)
        local res = fs.readfile(CHANNEL_JSON_FILE)
        channel_list = json.decode(res) or {}
    end
    luci.http.prepare_content("application/json")
    luci.http.write_json(channel_list)
end

-- [for EAP101, EAP102, OAP103] from https://redmine.ignitenet.com/issues/21855
-- [for EAP104] from https://redmine.ignitenet.com/issues/22857
-- radio_num = 1 => radio0 (5GHz)
-- radio_num = 2 => radio1 (2.4 GHz)
if is_EAP101 or is_EAP102 or is_OAP103 or is_EAP104 then
    -- set=<tx_power>&rf=<radio_num>
    -- example ==> 10.73.16.153/cgi-bin/luci/admin/wireless/setpower?set=15&rf=1
    function setpower()
        local get_radio_power = luci.http.getenv("QUERY_STRING")

        if get_radio_power and #get_radio_power > 0 then
            local radio_power = luci.util.split(get_radio_power, "&") or {}
            local tx_power = radio_power[1]:match("(%d+)")
            local radio_num = radio_power[2]:match("(%d+)")

            if tx_power and radio_num then
                local radio_id = radio_num-1

                -- /sbin/set_txpower_hidden.sh will change the txpower at uci & use command: iw phy phyX set txpower fixed <power in dBm * 100>
                os.execute("/sbin/set_txpower_hidden.sh " .. tx_power .. " " .. radio_id)
            end
        end
    end

    -- rf=<radio_num>
    -- example ==> 10.73.16.153/cgi-bin/luci/admin/wireless/getmaxpower?rf=1
    function getmaxpower()
        local get_radio_num = luci.http.getenv("QUERY_STRING")

        if get_radio_num and #get_radio_num > 0 then
            local radio_num = get_radio_num:match("(%d+)")

            if radio_num then
                local tx_power_info = {}
                local tx_power_max, tx_power_max_reg, tx_power_info_max
                local radio_id = radio_num-1
                local is_5g = (radio_id == 0)
                local ifname = 'wlan' .. radio_id
                local iwinfo = luci.sys.wifi.getiwinfo(ifname)
                local radio_info    = product.radio(radio_id)
                local current_band  = radio_info.freq
                local radio_device = 'radio' .. radio_id
                local country_code = acn_uci:get('wireless', radio_device, 'country')
                local current_bw = acn_uci:get('wireless', radio_device, 'htmode') or "HT40"
                local current_channel = acn_uci:get('wireless', radio_device, 'channel') or 'auto'
                local current_bw_val = current_bw:match("(%d+)")
                local chan_detail = reg.channelListDetails(current_band, country_code)

                -- get selected channel from iwinfo
                local selected_channel = iwinfo and iwinfo.channel or current_channel

                -- get channel list info from reg.lua
                if chan_detail then
                    for chan_bw, _tab1 in pairs(chan_detail) do
                        for _idx, _tab2 in pairs(_tab1) do

                            -- return max_tx if the channel number matches the selected channel from iwinfo
                            if _tab2.chan == selected_channel then
                                tx_power_max_reg = _tab2.max_tx
                            end
                        end
                    end
                end

                if tx_power_max_reg then
                    -- from reg.lua product.radio(radio_id).freq:5 for 5g, 2.4 for 2.4g
                    tx_power_info = reg.get_custom_info(product.radio(radio_id).freq, country_code, "powertable")
                    tx_power_info_max = tx_power_info["max_txpwr"]

                    -- compare with the default max power set in the fake reg data (tx_power_info_max) with power limitation
                    -- (the smaller value must be returned)
                    if tx_power_max_reg < tx_power_info_max then
                        tx_power_max = tx_power_max_reg
                    else
                        tx_power_max = tx_power_info_max
                    end
                else
                    -- if txpower list not available in iwinfo, get it from wireless config
                    if is_EAP101 then
                        tx_power_max  = tonumber(acn_uci:get('wireless', radio_device, 'max_txpwr')) or 26
                    elseif is_EAP102 or is_OAP103 then
                        if is_5g then
                            tx_power_max  = tonumber(acn_uci:get('wireless', radio_device, 'max_txpwr')) or 26
                        else
                            tx_power_max  = tonumber(acn_uci:get('wireless', radio_device, 'max_txpwr')) or 23
                        end
                    elseif is_EAP104 then
                        tx_power_max  = tonumber(acn_uci:get('wireless', radio_device, 'max_txpwr')) or 26
                    end
                end

                luci.http.prepare_content("application/json")
                luci.http.write_json(tx_power_max)
            end
        end
    end

    -- example ==> 10.73.16.153/cgi-bin/luci/admin/wireless/kickStation?mac=xx:xx:xx:xx:xx:xx
    function kickstation()
        local get_mac = luci.http.getenv("QUERY_STRING")

        if get_mac and #get_mac > 0 then
            local victim = get_mac:match("^mac=([a-fA-F0-9:-]+)")
            local mac_validate = luci.util.split(victim, ":")

            if mac_validate[6] and #mac_validate[6] > 0 then
                local wlan_iface_json = luci.util.ubus("iwinfo", "devices", {}) or {}

                for i, wlan_iface in pairs(wlan_iface_json["devices"]) do
                    local output = luci.util.exec('iw ' .. wlan_iface .. ' station dump')
                    victim = victim:gsub("\n[^\n]*$", "")

                    if output:find(victim) then
                        luci.util.ubus("hostapd." .. wlan_iface , "del_client", {
                            addr=victim,
                            reason=5,
                            deauth="true",
                            ban_time=10000
                        })

                        break
                    end
                    --end of traverse devices
                end
                --end of legal victim
            end
        end
    end

end

-- https://redmine.ignitenet.com/issues/24205: Add hidden page & command for NMS
-- example: <IP address>/cgi-bin/luci/admin/wireless/getAllClientsInfo
function getAllClientsInfo()
    local num_radios=2
    local all_clients_info = {}

    for radio_id=0, num_radios-1 do
        local rf_num = radio_id+1
        local radio_info = product.radio(radio_id)
        local max_VAP = radio_info.max_ssids -- 16 for eap102

        for VAP_num=0, max_VAP-1 do
            local group_name ='rf' .. rf_num .. '_vap' .. VAP_num+1
            local wlan_name, wlan_ssid

            if VAP_num == 0 then
                wlan_name = 'wlan' .. radio_id
            else
                wlan_name = 'wlan' .. radio_id .. '-' .. VAP_num
            end

            -- get associated client info from ubus: ubus call iwinfo "assoclist" '{"device":"wlanX"}'
            local client_info = luci_util.ubus("iwinfo", "assoclist", { device = wlan_name }) or {}
            -- get wlan info from ubus: ubus call iwinfo "info" '{"device":"wlanX"}'
            local wlan_info = luci_util.ubus("iwinfo", "info", { device = wlan_name }) or {}
            wlan_ssid = wlan_info.ssid or ""

            if client_info["results"] and #client_info["results"] > 0 then
                local VAP_client_info = {}

                for _key, _val in pairs(client_info["results"]) do
                    VAP_client_info[_key] = {
                        group = group_name,
                        name = wlan_name,
                        ssid = wlan_ssid,
                        mac = _val.mac or "",
                        rssi = _val.signal or 0,
                        per = 0,
                        ht = ((_val.tx["ht"] == true) and 1 or 0),
                        idle = _val.inactive or 0,
                        assoc_time = _val.connected_time or 0
                    }
                end
                all_clients_info[#all_clients_info+1] = VAP_client_info
            else
                all_clients_info[#all_clients_info+1] = {}
            end
        end
    end
    luci.http.prepare_content("application/json")
    luci.http.write_json(all_clients_info)
end

-- example: <IP address>/cgi-bin/luci/admin/wireless/setChannel?set=<channel>&rf=<rf_num>
function setChannel()
    local get_radio_chan = luci.http.getenv("QUERY_STRING")

    if get_radio_chan and #get_radio_chan > 0 then
        local radio_power = luci.util.split(get_radio_chan, "&") or {}
        local set_channel = radio_power[1]:match("(%d+)")
        local radio_num = radio_power[2]:match("(%d+)")

        if set_channel and radio_num then
            local radio_id = radio_num-1
            -- /sbin/set_channel_hidden.sh will change the channel at uci & use command: iw dev wlanX set channel <set_channel>
            os.execute("/sbin/set_channel_hidden.sh " .. set_channel .. " " .. radio_id)
        end
    end
end

function get_bwmonitor(precise)
    local product = require "luci.acn.product"
    local fs = require "nixio.fs"
    local res = luci.util.exec("ps | grep 'bwmonitor.sh' | grep -v grep 2>/dev/null") or nil

    if res == nil or res == "" then
        os.execute("/sbin/bwmonitor.sh &")
        os.execute("sleep " .. 7) 
    end

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

function getAPRunTimeInfo()
    array = {}
    local product = require "luci.acn.product"
    local acn = require "luci.acn.util"
    local uci = acn.cursor()
    local res = { VAP_SUM = {}, RF = {}, SYSINFO = {}, AIRTIME = {}, CLIENTINFO = {} }

    num_eth_ports = product.num_eth_ports
    num_radios = product.num_wifi_radios

    local hostname = acn_uci:get('system', '@system[0]', 'hostname')
    local power_array = {}
    local channel_arrray = {}
    local radio_array = {}
    local out_str = {}
    local dev_type = 0

    if is_EAP101 then
        dev_type = 401
    end
    if is_EAP102 then
        dev_type = 402
    end
    if is_OAP103 then
        dev_type = 404
    end
    if is_EAP104 then
        dev_type = 405
    end

    for radio_id=0, num_radios-1 do
        local tx_power_info = {}
        local tx_power_max, tx_power_max_reg, tx_power_info_max
        local is_5g = (radio_id == 0)
        local ifname = 'wlan' .. radio_id
        local iwinfo = luci.sys.wifi.getiwinfo(ifname)
        local radio_info    = product.radio(radio_id)
        local current_band  = radio_info.freq
        local radio_device = 'radio' .. radio_id
        local country_code = acn_uci:get('wireless', radio_device, 'country')
        local current_bw = acn_uci:get('wireless', radio_device, 'htmode') or "HT40"
        local current_channel = acn_uci:get('wireless', radio_device, 'channel') or 'auto'
        -- local current_bw_val = current_bw:match("(%d+)")
        local chan_detail = reg.channelListDetails(current_band, country_code)

        -- get selected channel from iwinfo
        local selected_channel = iwinfo and iwinfo.channel or current_channel

        -- get channel list info from reg.lua
        if chan_detail then
            for chan_bw, _tab1 in pairs(chan_detail) do
                for _idx, _tab2 in pairs(_tab1) do
                    -- return max_tx if the channel number matches the selected channel from iwinfo
                    if _tab2.chan == selected_channel then
                        tx_power_max_reg = _tab2.max_tx
                    end
                end
            end
        end

        if tx_power_max_reg then
            -- from reg.lua product.radio(radio_id).freq:5 for 5g, 2.4 for 2.4g
            tx_power_info = reg.get_custom_info(product.radio(radio_id).freq, country_code, "powertable")
            tx_power_info_max = tx_power_info["max_txpwr"]

            -- compare with the default max power set in the fake reg data (tx_power_info_max) with power limitation
            -- (the smaller value must be returned)
            if tx_power_max_reg < tx_power_info_max then
                tx_power_max = tx_power_max_reg
            else
                tx_power_max = tx_power_info_max
            end
        else
            -- if txpower list not available in iwinfo, get it from wireless config
            if is_EAP101 then
                tx_power_max  = tonumber(acn_uci:get('wireless', radio_device, 'max_txpwr')) or 26
            elseif is_EAP102 or is_OAP103 then
                if is_5g then
                    tx_power_max  = tonumber(acn_uci:get('wireless', radio_device, 'max_txpwr')) or 26
                else
                    tx_power_max  = tonumber(acn_uci:get('wireless', radio_device, 'max_txpwr')) or 23
                end
            elseif is_EAP104 then
                tx_power_max  = tonumber(acn_uci:get('wireless', radio_device, 'max_txpwr')) or 26
            end
        end

        local iface = 'radio' .. radio_id
        local stats =  {
            ch = selected_channel,
            txp = tx_power_max,
            band = current_bw
        }

        res['RF'][iface] = stats
    end

    for radio_id=0, num_radios-1 do
        local rf_num = radio_id+1
        local radio_info = product.radio(radio_id)
        local max_VAP = radio_info.max_ssids -- 16 for eap102
        local client_cnt = 0

        for VAP_num=0, max_VAP-1 do
            local group_name ='rf' .. rf_num .. '_vap' .. VAP_num+1
            local wlan_name, wlan_ssid

            if VAP_num == 0 then
                wlan_name = 'wlan' .. radio_id
            else
                wlan_name = 'wlan' .. radio_id .. '-' .. VAP_num
            end

            -- get associated client info from ubus: ubus call iwinfo "assoclist" '{"device":"wlanX"}'
            local client_info = luci_util.ubus("iwinfo", "assoclist", { device = wlan_name }) or {}
            -- get wlan info from ubus: ubus call iwinfo "info" '{"device":"wlanX"}'
            local wlan_info = luci_util.ubus("iwinfo", "info", { device = wlan_name }) or {}
            wlan_ssid = wlan_info.ssid or ""

            if client_info["results"] and #client_info["results"] > 0 then
                local VAP_client_info = {}

                for _key, _val in pairs(client_info["results"]) do
                    client_cnt = client_cnt + 1
                end
            end
        end
        array[radio_id] = client_cnt
    end

    res['CLIENTINFO']['card_A'] = array[0]
    res['CLIENTINFO']['card_B'] = array[1]
    res['CLIENTINFO']['total'] = array[0] + array[1]

    local cpu_used = 0
    os.execute('mpstat -P ALL 1 1|grep \'all\'|grep \'Average\'|awk \'{print 100-$(NF)}\' >' .. "/tmp/tmp_cpu_used")
    cpu_used_f = io.open("/tmp/tmp_cpu_used", "r")
    if cpu_used_f then
        cpu_used = cpu_used_f:read()
        cpu_used_f:close()
    end

    local devs = get_bwmonitor(true) or {}

    local m_total = 0
    local m_free = 0
    local m_buffers = 0
    local m_cached = 0
    local m_usage = 0
    os.execute('cat /proc/meminfo|grep MemTotal|awk \'{print $2 "\t"}\' >' .. "/tmp/tmp_mem_total")
    mem_total = io.open("/tmp/tmp_mem_total", "r")
    if mem_total then
        m_total = mem_total:read()
        mem_total:close()
    end

    os.execute('cat /proc/meminfo|grep MemFree|awk \'{print $2 "\t"}\' > ' .. "/tmp/tmp_mem_free")
    mem_free = io.open("/tmp/tmp_mem_free", "r")
    if mem_free then
        m_free = mem_free:read()
        mem_free:close()
    end
    os.execute('cat /proc/meminfo|grep Buffers|awk \'{print $2 "\t"}\' > ' .. "/tmp/tmp_mem_buffers")
    mem_buffers = io.open("/tmp/tmp_mem_buffers", "r")
    if mem_buffers then
        m_buffers = mem_buffers:read()
        mem_buffers:close()
    end
    os.execute('cat /proc/meminfo|grep Cached|grep -v SwapCached|awk \'{print $2 "\t"}\' > ' .. "/tmp/tmp_mem_cached")
    mem_cached = io.open("/tmp/tmp_mem_cached", "r")
    if mem_cached then
        m_cached = mem_cached:read()
        mem_cached:close()
    end
    if m_total then
      m_usage = (1 - (m_free + m_buffers + m_cached) / m_total) * 100
    end

    res['SYSINFO']['dev_type'] = dev_type
    res['SYSINFO']['sysname'] = hostname
    res['SYSINFO']['time'] = os.time()
    res['SYSINFO']['cpu'] = cpu_used
    res['SYSINFO']['mem'] = m_usage

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
        res['VAP_SUM'][iface] = stats
    end

    luci.http.prepare_content("application/json")
    luci.http.write_json(res)

end

