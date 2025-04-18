local nw = require "luci.model.network"
local fs = require "nixio.fs"
local acn_status = require "luci.acn.status"

local product = require "luci.acn.product"
local acn_util = require "luci.acn.util"
local reg = require "luci.acn.reg"
local bitwise = require "luci.acn.bitwise"
local json = require "cjson.safe"
local sys = require "luci.sys"

local num_wifi_radios = product.num_wifi_radios
local pre_vap_name = "radio"
local pre_ifname_name = "wlan"

local radio_id = arg[1]

local _rad_id, vap_id = radio_id:match(pre_vap_name .. "(%d+).network(%d+)")

if not _rad_id then return end

local rad_id = _rad_id
local nrad_id = tonumber(rad_id)

if not nrad_id or nrad_id < 0 or nrad_id > 3  then return end

for i=0, num_wifi_radios - 1 do
  local radio_info = product.radio(i)
  local radio_device = radio_info and radio_info.device
  if radio_device and radio_device == pre_vap_name .. _rad_id then
      rad_id = i
  end
end

local radio_info    = product.radio(rad_id)
local current_band  = radio_info.freq
local max_ssids     = radio_info.max_ssids
local radio_device = radio_info.device -- radioX
local ifname = radio_info.wifi_iface -- wlanX
local ifname_idx = ifname and ifname:match(pre_ifname_name .. "(%d+)")
local radio_pre_form = "cbid.wireless." .. radio_device .. "."

-- TIP OpenWiFi 2.0 support wifi steering
local bandsteering_allowed  = false
local show_bandsteering     = true
local max_tx_streams        = radio_info.max_tx_streams
local max_rx_streams        = radio_info.max_rx_streams

local acn_uci = acn_util.cursor()
local is_OAP = product.is_OAP()
local is_EAP101 = product.is_EAP101()
local is_EAP102 = product.is_EAP102()
local is_EAP104 = product.is_EAP104()
local is_OAP103 = product.is_OAP103()

local ssid_only_one = false
local has_network_behavior = true
local has_ssid_status = true
local is_2g = (current_band == "2.4")
local is_5g = (current_band == "5")
local iwinfo = sys.wifi.getiwinfo(ifname)
local dfs_channel_by_mesh = true

local root_user = luci.util.root_user(luci.http.getcookie("user_name"))
local msp_disabled = (acn_uci:get("acn", "settings", "msp_enable") == "0" or acn_uci:get("acn", "settings", "msp_enable") == nil)

nw.init()

--https://accton-group.atlassian.net/browse/ECCLOUD-1048
if is_EAP101 or is_EAP102 or is_EAP104 then
  dfs_channel_by_mesh = false
end

if show_bandsteering then
    -- Assuming dual radio for now
    bandsteering_allowed = not (acn_uci:get("wireless", radio_device .. "_1", "mode") or ""):match("sta")
end

--  Okay, let's see if this is a postback
local is_postback = luci.http.formvalue(radio_pre_form .. "mode")
local fetch_ssid = arg[2] or false
local fetch_ssid_id = false

if not is_postback and fetch_ssid and tonumber(fetch_ssid) and tonumber(fetch_ssid) > 0 and tonumber(fetch_ssid ) <= max_ssids then
    fetch_ssid_id = tonumber(fetch_ssid)
end

if fetch_ssid_id then
    luci.dispatcher.context.plain_page = true
end

local mode = luci.http.formvalue(radio_pre_form .. "mode") or
    acn_uci:get("wireless", radio_device, "mode") or "ap"
local ht_mode = luci.http.formvalue(radio_pre_form .. "htmode") or
    acn_uci:get("wireless", radio_device, "htmode") or "HT20"
ht_mode = ht_mode:match('[0-9]+')

local rename_wifi_sections, created_radios, uncreated_radios = false, {}, {}

-- #8645: lock down parts of the UI when the device is cloud managed
local mgmt_enabled = (acn_uci:get("acn", "mgmt", "enabled") == "1")
local is_controlled_by_cloud = (mgmt_enabled and mode == "ap")

-- First pass - figure out how many interfaces are still "created" and if we have to rename/reorder later on.
-- We can rename here or the posted back values will be saved under the wrong radio section.
if is_postback then
    -- #10953: if device is cloud controlled, don't save any of the ssids/don't reorder when other radio settings are changed
    if not mgmt_enabled then
        for j=1, max_ssids do

            local status = luci.http.formvalue("cbi.cbe.wireless." .. radio_device .. "_" .. j .. ".disabled")
            local created = "1"

            -- We do this check before non-client VAPs are disabled when changing from AP->STA
            if mode:match("sta") and j > 1 then
                created = "0"
            end

            if status then
                if acn_uci:get("wireless", radio_device .. "_" .. j) ~= "wifi-iface" then
                    local vap_idx = j - 1
                    local vap_ifname = ifname
                    if vap_idx > 0 then
                        vap_ifname = ifname .. "-" .. vap_idx
                    end

                    acn_uci:set("wireless", radio_device .. "_" .. j, "wifi-iface")
                    acn_uci:set("wireless", radio_device .. "_" .. j, "device", radio_device)
                    acn_uci:set("wireless", radio_device .. "_" .. j, "ifname", vap_ifname)
                    acn_uci:set("wireless", radio_device .. "_" .. j, "disabled", "0")
                    acn_uci:set("wireless", radio_device .. "_" .. j, "mode", "ap")
                    acn_uci:set("wireless", radio_device .. "_" .. j, "network", "lan")
                    acn_uci:set("wireless", radio_device .. "_" .. j, "wds", "1")
                    acn_uci:set("wireless", radio_device .. "_" .. j, "isolate", "0")
                end
            else
                created = "0"
                acn_uci:set("wireless", radio_device .. "_" .. j, "disabled", "1")
                acn_uci:delete("wireless", radio_device .. "_" .. j, "dynamic_vlan")
                acn_uci:delete("wireless", radio_device .. "_" .. j, "vlan_tagged_interface")
                acn_uci:delete("wireless", radio_device .. "_" .. j, "vlan_bridge")
            end

            acn_uci:set("wireless", radio_device .. "_" .. j, "created", created)

            if j == 1 or created == "1" then
                created_radios[#created_radios + 1] =  radio_device .. "_" .. j
            else
                uncreated_radios[#uncreated_radios + 1] = radio_device .. "_" .. j
            end

            if #uncreated_radios > 0 then
                rename_wifi_sections = true
            end

            acn_uci:save("wireless")
        -- Fix UCI order (do this later as well)
        end

        -- Okay, now let's make sure there are no gaps in the "uncreated" wifi-iface sections
        -- (ugh)
        -- BUT, do this rename task later! Otherwise, the postback values will not be saved to the
        -- correct radio section.
    end

    -- #19840: bridge bat0 to correct interface
    local mesh_status = luci.http.formvalue("cbid.wireless.wmesh.disabled")
    local mesh_network = luci.http.formvalue("cbid.wireless.wmesh.network_behavior")
----------mesh_custom _lan
    local mesh_network_ifname = luci.http.formvalue("cbid.wireless.wmesh.network_name")
    local mesh_network_name_config = acn_uci:get("wireless", "wmesh", "network_name")
    local mesh_network_behavior_config = acn_uci:get("wireless", "wmesh", "network_behavior")
    if mesh_network_name_config ~= "lan" then                     --Only route has "uci network_name".
        last_mesh_network_ifname_tmp = mesh_network_name_config   --When custom lan change to default lan, we use "tmp" to
    end                                                           --delte last custom lan.
    if mesh_network ~= mesh_network_behavior_config then
        last_mesh_network_behavior_config = mesh_network_behavior_config
    end
-----------end
    local bat_br_wan = acn_uci:get("network", "wan", "ifname")
    local bat_br_lan = acn_uci:get("network", "lan", "ifname")

    if mesh_network then
        if mesh_status == "0" then  --enable mesh
            local remove_iface = ""
            local add_iface = ""

            if mesh_network == "route" then
                if mesh_network_ifname == "lan" then
                    if last_mesh_network_ifname_tmp then
                        acn_uci:delete("network", last_mesh_network_ifname_tmp, "ifname")
                        last_mesh_network_ifname_tmp = nil
                    end
                    bat_br = bat_br_lan
                    add_iface = "lan"
                    
                    if bat_br_wan == "bat0" then
                        remove_mesh = bat_br_wan and bat_br_wan:gsub("bat0", "")
                    elseif bat_br_wan:find("bat0 ") then
                        remove_mesh = bat_br_wan and bat_br_wan:gsub("bat0%s", "")
                    else
                        remove_mesh = bat_br_wan and bat_br_wan:gsub("%sbat0", "")
                    end
                    remove_iface = "wan"
                else
                    if mesh_network_name_config == "lan" and mesh_network_behavior_config == "route" then
                        if bat_br_lan == "bat0" then
                            remove_mesh = bat_br_lan and bat_br_lan:gsub("bat0", "")
                        elseif bat_br_lan:find("bat0 ") then
                           remove_mesh = bat_br_lan and bat_br_lan:gsub("bat0%s", "")
                        else
                            remove_mesh = bat_br_lan and bat_br_lan:gsub("%sbat0", "")
                        end
                        remove_iface = "lan"
                    elseif last_mesh_network_behavior_config == "bridge" then
                        if bat_br_wan == "bat0" then
                            remove_mesh = bat_br_wan and bat_br_wan:gsub("bat0", "")
                        elseif bat_br_wan:find("bat0 ") then
                            remove_mesh = bat_br_wan and bat_br_wan:gsub("bat0%s", "")
                        else
                            remove_mesh = bat_br_wan and bat_br_wan:gsub("%sbat0", "")
                        end
                        remove_iface = "wan"
                    end
                    
                    acn_uci:set("network", mesh_network_ifname, "ifname", "bat0")
                    if mesh_network_name_config ~= mesh_network_ifname and mesh_network_name_config ~= "lan" then
                        acn_uci:delete("network", mesh_network_name_config, "ifname")
                    end
                end
            elseif mesh_network == "bridge" then
                if last_mesh_network_ifname_tmp then
                    acn_uci:delete("network", last_mesh_network_ifname_tmp, "ifname")
                    last_mesh_network_ifname_tmp = nil
                end

                bat_br = bat_br_wan
                add_iface = "wan"

                if bat_br_lan == "bat0" then
                    remove_mesh = bat_br_lan and bat_br_lan:gsub("bat0", "")
                elseif bat_br_lan and bat_br_lan:find("bat0 ") then
                    remove_mesh = bat_br_lan and bat_br_lan:gsub("bat0%s", "")
                else
                    remove_mesh = bat_br_lan and bat_br_lan:gsub("%sbat0", "")
                end
                remove_iface = "lan"
            end

            is_open_mesh = bat_br and bat_br:find("bat0")
            if mesh_status and not is_open_mesh then
                if bat_br ~= nil then
                    acn_uci:set("network", add_iface, "ifname", bat_br .. " " .. "bat0")
                else
                    acn_uci:set("network", add_iface, "ifname", "bat0")
                end
            end
            acn_uci:set("network", remove_iface, "ifname", remove_mesh)
        else
            -- remove bat0 interface
            bat_br_wan = bat_br_wan and bat_br_wan:gsub("%sbat0", "")
            acn_uci:set("network", "wan", "ifname", bat_br_wan)
            bat_br_lan = bat_br_lan and bat_br_lan:gsub("%sbat0", "")
            acn_uci:set("network", "lan", "ifname", bat_br_lan)
        end
        acn_uci:save("network")
    end
    -- #19840 END
end

local total_created_ssids = 0
local created_ssid_ids = {}
local sitelevel_ssid_status = {}
local lc_enabled_ids = {}

for j=1, max_ssids do
    local created = acn_uci:get("wireless", radio_device .. "_" .. j, "created") or "0"
    if created == "1" then
        total_created_ssids = total_created_ssids + 1
        created_ssid_ids[#created_ssid_ids+1] = tostring(total_created_ssids)
    end

    local local_config  = acn_uci:get("wireless", radio_device .. "_" .. j, "local_configurable") or "0"
    if local_config == "1" then
        lc_enabled_ids[#lc_enabled_ids+1] = j
    end

    if mgmt_enabled then
        local sitelevel_ssid = acn_uci:get("wireless", radio_device .. "_" .. j, "__uid") or ""
        sitelevel_ssid_status[#sitelevel_ssid_status+1] = sitelevel_ssid
    else
        sitelevel_ssid_status[#sitelevel_ssid_status+1] = ""
    end
end
sitelevel_ssid_status = sitelevel_ssid_status and json.encode(sitelevel_ssid_status) or ""
created_ssid_ids = created_ssid_ids and json.encode(created_ssid_ids) or ""
lc_enabled_ids = lc_enabled_ids and json.encode(lc_enabled_ids) or ""

-- If we're not a postback, and we're getting SSID stuff, then don't render physical radio settiongs.
-- That's right, this is ghetto.  But you know what? It works!  And keeps us from completely re-writing
-- the grande spaghetti feast that is this page.

local uci_st = acn_util.cursor_state()
local channel_list_cfg = acn_uci:get("wireless", radio_device, "channels")
local channel_cfg = acn_uci:get("wireless", radio_device, "channel") or "auto"

-- fetch wme config data
local wme_config = { BestEffort = "0", Background = "1", Video = "2", Voice = "3" }
local ordered_wme_config = { [1] = "BestEffort", [2] = "Background", [3] = "Video", [4] = "Voice" }
for i, cat in ipairs(ordered_wme_config) do
    local wme_i = acn_uci:get("wireless", radio_device, "wme_"..wme_config[cat])
    wme_config[cat] = {}
    if wme_i then
        for k, v in string.gmatch(wme_i, "%w+") do
            table.insert(wme_config[cat], k)
        end
    end
end
local wme_config_string = json.encode(wme_config)

local posted_wme = luci.http.formvalue(radio_pre_form .. "wme_0")
if posted_wme ~= nil then
    local posted_wme_config = { BestEffort = {}, Background = {}, Video = {}, Voice = {} }
    local posted_wme_index = 1
    for wme_i in posted_wme:gmatch("%w+,%w+,%w+,%w+,%w+,%w+,%w+,%w+") do
        local category = ordered_wme_config[posted_wme_index]
        for v in wme_i:gmatch("%w+") do
            table.insert(posted_wme_config[category], v)
        end
        posted_wme_index = posted_wme_index + 1
    end
    posted_wme = json.encode(posted_wme_config)
end

local m,s,s3

m = Map("wireless", translate("Wireless Settings") ..  "(" .. translate("Radio ") .. current_band .. " GHz)")

local posted_datarate = luci.http.formvalue(radio_pre_form .. "data_rate")
local posted_txpower = luci.http.formvalue(radio_pre_form .. "txpower")
local posted_channel = luci.http.formvalue(radio_pre_form .. "channel")

local phy_name = "phy" .. ifname_idx
local freq_json = iwinfo and iwinfo.freqlist
if not freq_json then
  freq_json = luci.util.ubus("iwinfo", "freqlist", {
    device = phy_name
  })
  if freq_json then
    freq_json = freq_json.results
  end
end

local country_code = ""
local chan_detail = ""
local chan_detail_string = ""

if not fetch_ssid_id then
    country_code = m.uci:get("wireless", radio_device , "country") or "US"
    chan_detail = reg.channelListDetails(current_band, country_code)
    chan_detail_string = json.encode(chan_detail)
end

local wan_proto = acn_uci:get("network", "wan", "proto")

--collect all dae port so far
local dae_ports = {}

acn_uci:foreach('wireless', 'wifi-iface',
    function(s)
        -- wifi-iface names are like radioX_X
        local logical_vap_id = s['.name']:match("radio(%d+)_(%d+)")

        if logical_vap_id then
            if s['dae_port'] then
                dae_ports[s['.name']] = s['dae_port'] or ""
            end
        end
    end)

dae_ports["hs_coaport"] = acn_uci:get('hotspot', 'hotspot', 'hs_coaport')

-- JS file for this page
local fw_ver = acn_status.version()
luci.dispatcher.context.page_js = '<script src="' .. luci.config.main.mediaurlbase .. '/js/wifi.js?ver=' .. fw_ver .. '"></script>\n'
.. '<script src="' .. luci.config.main.mediaurlbase .. '/js/acl.js?ver=' .. fw_ver .. '"></script>\n'
.. '<script src="' .. luci.config.main.mediaurlbase .. '/js/reg.js?ver=' .. fw_ver .. '"></script>\n'
.. '<script src="' .. luci.config.main.mediaurlbase .. '/js/wifi_frequency.js?ver=' .. fw_ver .. '"></script>\n'
.. '<script src="' .. luci.config.main.mediaurlbase .. '/js/wifi_wme_config.js?ver=' .. fw_ver .. '"></script>\n'
.. '<script src="' .. luci.config.main.resourcebase .. '/jquery.tablesorter.min.js?ver=' .. acn_status.version() .. '"></script>\n'
.. '<style>\n'
.. '.cbi-section-node { padding-bottom: 10px }\n'
.. '</style>\n'
.. "<script type='text/javascript'>\n"
..    "var current_band = '" .. current_band .. "';\n"
..    "var radio_id = " .. rad_id .. ";\n"
..    "var radio_iface = '" .. radio_device .. "';\n"
..    "var max_ssids = " .. max_ssids .. ";\n"
..    "var default_max_ssids = " .. max_ssids .. ";\n"
..    "var created_ssid_ids = " .. created_ssid_ids .. ";\n"
..    "var lc_enabled_ids = " .. lc_enabled_ids .. ";\n"
..    "var scan_url ='" .. luci.dispatcher.build_url("admin", "wireless", "scan", ifname, mode) .. "';\n"
..    "var ssid_url = '" .. luci.dispatcher.build_url("admin", "wireless", "wifi", radio_device .. ".network1") .. "';\n"
..    "var total_ssids_enabled = " .. total_created_ssids .. ";\n"
..    "var current_datarate = '" .. (posted_datarate or m.uci:get('wireless', radio_device, 'data_rate') or 'auto') .. "';\n"
..    "var chan_detail = " .. (chan_detail_string and chan_detail_string or "[]") .. ";\n"
..    "var bandsteering_allowed = " .. tostring(bandsteering_allowed) .. ";\n"
..    "var ssid_only_one = " .. tostring(ssid_only_one) .. ";\n"
..    "var has_ssid_status = " .. tostring(has_ssid_status) .. ";\n"
..    "var has_network_behavior = " .. tostring(has_network_behavior) .. ";\n"
..    "var sitelevel_ssid_status = " .. sitelevel_ssid_status .. ";\n"
..    "var previous_opmode = '" .. mode .. "';\n"
..    "var channel_val = '" .. (posted_channel or channel_list_cfg or channel_cfg):gsub(",", "-") .. "';\n"
..    "var is_OAP = " .. tostring(is_OAP) .. ";\n"
..    "var country_code = '" .. country_code .. "';\n"
..    "var max_tx_streams = " .. max_tx_streams .. ";\n"
..    "var mgmt_enabled = " .. tostring(mgmt_enabled) .. ";\n"
..    "var root_user = '" .. tostring(root_user) .. "';\n"
..    "var msp_disabled = '" .. tostring(msp_disabled) .. "';\n"
..    "var wan_proto = \""..wan_proto.."\";\n"
..    "var wme_config = " .. (posted_wme or wme_config_string) .. ";\n"
..    "var dae_ports = " .. json.encode(dae_ports) .. ";\n"
..    "var is_EAP104 = " .. tostring(is_EAP104) .. ";\n"
..    "var dfs_channel_by_mesh = " .. tostring(dfs_channel_by_mesh) .. ";\n"
.. "</script>\n"
.. '<style type="text/css">\n'
.. '  table.tablesorter {\n'
.. '    width: 100%;\n'
.. '    text-align: left;\n'
.. '  }\n'
.. '\n'
.. '  .header {\n'
.. '    background-image: url("/img/bg.gif");\n'
.. '    background-repeat: no-repeat;\n'
.. '    background-position: 95% center;\n'
.. '    cursor: pointer;\n'
.. '  }\n'
.. '\n'
.. '  th.headerSortDown {\n'
.. '    background-image: url("/img/desc.gif");\n'
.. '    background-repeat: no-repeat;\n'
.. '    background-position: 95% center;\n'
.. '    cursor: pointer;\n'
.. '  }\n'
.. '\n'
.. '  th.headerSortUp {\n'
.. '    background-image: url("/img/asc.gif");\n'
.. '    background-repeat: no-repeat;\n'
.. '    background-position: 95% center;\n'
.. '    cursor: pointer;\n'
.. '  }\n'
.. '</style>\n'

m:chain("network")
m:chain("firewall")
m:chain("openvswitch")
m:chain("atfpolicy")

local ifsection

local wnet, wdev, hw_modes, tx_power_cur , posted_hwmode, country
local radio_channel, htmode, radio_band, radio_mode, radio_status

if not fetch_ssid_id or is_postback then

    function m.on_commit(map)
        local wnet = nw:get_wifinet(radio_id)
        if ifsection and wnet then
            ifsection.section = wnet.sid
            m.title = luci.util.pcdata(wnet:get_i18n())
        end
    end

    nw.init(m.uci)

    wnet = nw:get_wifinet(radio_id)
    wdev = wnet and wnet:get_device()

    function txpower_current(pwr, list)
        pwr = tonumber(pwr)
        if pwr ~= nil then
            local _, item
            for _, item in ipairs(list) do
                if item.driver_dbm >= pwr then
                    return item.driver_dbm
                end
            end
        end
        return (list[#list] and list[#list].driver_dbm) or pwr or 0
    end

    posted_hwmode = luci.http.formvalue(radio_pre_form .. "hwmode")
    posted_txstreams =  luci.http.formvalue(radio_pre_form .. "tx_streams")

    hw_modes      = iwinfo.hwmodelist or { }

    tx_power_cur  = wnet and wnet:txpower() or 0

    -- limit max tx power by model
    if is_EAP101 then
        tx_power_max  = m.uci:get('wireless', radio_device, 'max_txpwr') or 26
    elseif is_EAP102 or is_OAP103 then
        if is_5g then
            tx_power_max  = m.uci:get('wireless', radio_device, 'max_txpwr') or 26
        else
            tx_power_max  = m.uci:get('wireless', radio_device, 'max_txpwr') or 23
        end
    elseif is_EAP104 then -- TODO: need to check
        tx_power_max  = m.uci:get('wireless', radio_device, 'max_txpwr') or 26
    end

    -- let the ghettoness resume
    luci.dispatcher.context.page_js = luci.dispatcher.context.page_js
        .. "<script type='text/javascript'>\n"
        ..  "var current_txpower = '" .. ( posted_txpower or m.uci:get('wireless', radio_device, 'txpower') or tx_power_cur) .. "';\n"
        ..  "var tx_power_max = '" .. tx_power_max .. "';\n"
        ..  "var txpwr_list_limit = 3;\n"
        .. "</script>"

    if root_user or msp_disabled then
        s = m:section(NamedSection, wdev:name(), "wifi-device", translate("Physical Radio Settings"))
    else
        s = m:section(NamedSection, wdev:name(), "wifi-device")
    end
    s.addremove = false
    -- Same as services page
    s.sub_title_class = true

    radio_status = s:option(Flag, "disabled", translate("Status"))
    radio_mode = s:option(ListValue, "mode", translate("Mode"))

-- Open Mesh create
    wmesh_device = m.uci:get("wireless", "wmesh", "device")
    if (is_5g and (wmesh_device == "nil" or wmesh_device == "radio0")) or
       (is_2g and (wmesh_device == "nil" or wmesh_device == "radio1")) then

        if root_user or msp_disabled then
            s4 = m:section(NamedSection, "wmesh", "wifi-iface", translate("Open Mesh Settings"))
        else
            s4 = m:section(NamedSection, "wmesh", "wifi-iface")
        end
        s4.addremove = false
        s4.sub_title_class = true
        s4.config = "advance"

        mesh_point = s4:option(Flag, "disabled", translate("Mesh Point"))
        mesh_point.enabled = "0"
        mesh_point.disabled = "1"
        mesh_point.rmempty = false

        mesh_ssid = s4:option(Value, "mesh_id", translate("Mesh Id"))
        mesh_ssid.rmempty = true
        mesh_ssid.default = "openmesh"

        mesh_encryption = s4:option(ListValue, "encryption", translate("Method"))
        mesh_encryption:value("none", translate("No Security"))
        mesh_encryption:value("sae", "WPA3 Personal")
        mesh_encryption.default = "none"

        mesh_wpakey = s4:option( Value, "_wpa_key", translate("Key"))
        mesh_wpakey.rmempty = true
        mesh_wpakey.password = true
        mesh_wpakey.force_required = true

        mesh_network_behavior = s4:option(ListValue, "network_behavior", translate("Network Behavior"))
        mesh_network_behavior:value("bridge", translate("Bridge to Internet"))
        mesh_network_behavior:value("route", translate("Route to Internet"))

        network_name = s4:option(ListValue, "network_name", translate("Network Name"))
        network_name:value(lan_network, translate("Default local network"))
        for i, network in ipairs(acn_util.custom_LANs(m.uci)) do
            network_name:value(network["dev_name"], network["friendly"])
        end

        if root_user == false and msp_disabled == false then
            mesh_point.header_style             = "display:none"
            mesh_ssid.header_style              = "display:none"
            mesh_encryption.header_style        = "display:none"
            mesh_wpakey.header_style            = "display:none"
            mesh_network_behavior.header_style  = "display:none"
            network_name.header_style           = "display:none"
        end

        local bat_br_wan = acn_uci:get("network", "wan", "ifname")
        local bat_br_lan = acn_uci:get("network", "lan", "ifname")
        local bat_mac = acn_uci:get("wireless", "wmesh", "macaddr") or "nil"

        function mesh_point.write(self, section, value)
            Flag.write(self, section, value)

            if value == self.enabled then
                m.uci:set("wireless", section, "mode", "mesh")
                if is_5g then
                    m.uci:set("wireless", section, "device", "radio0")
                else
                    m.uci:set("wireless", section, "device", "radio1")
                end
            else
                m.uci:delete("wireless", section, "mode")
                m.uci:set("wireless", section, "device", "nil")
                m.uci:delete("wireless", section, "macaddr")
            end
        end

        function mesh_encryption.write(self, section, value)
            local mesh_status = luci.http.formvalue("cbid.wireless.wmesh.disabled")
            if mesh_status == "0" then
                local e = mesh_encryption and tostring(mesh_encryption:formvalue(section))
                local c = mesh_cipher and tostring(mesh_cipher:formvalue(section))

                if value == "sta-wpa" or value == "sta-wpa2" or value == "sta-wpa3" or value == "sta-wpa3-mixed" then
                    e = value:gsub("sta%-", "")
                end

                if value == "wpa" or value == "wpa2" or value == "sae" then
                   self.map.uci:delete("wireless", section, "key")
                end

                if e and (c == "tkip" or c == "ccmp" or c == "tkip+ccmp") then
                   e = e .. "+" .. c
                end
                self.map:set(section, "encryption", e)
            end
        end

        function mesh_encryption.cfgvalue(self, section)
            local v = tostring(ListValue.cfgvalue(self, section))

            if v and v:match("%+") then
                return (v:gsub("%+.+$", ""))
            end

            local mode = m.uci:get("wireless", section, "mode")

            if acn_util.is_sta_mode(mode) and (v == "wpa" or v == "wpa2" or v == "wpa3" or v == "wpa3-mixed" or v == "wpa3-192") then
                return "sta-" .. v
            end
            return v
        end

        function mesh_wpakey.write(self, section, value)
            local mesh_status = luci.http.formvalue("cbid.wireless.wmesh.disabled")
            if mesh_status == "0" then
                self.map.uci:set("wireless", section, "key", value)
                self.map.uci:delete("wireless", section, "key1")
            end
        end

        function mesh_wpakey.cfgvalue(self, section, value)
            local key = m.uci:get("wireless", section, "key")
            if key == "1" or key == "2" or key == "3" or key == "4" then
                return nil
            end
            return key
        end

        function mesh_network_behavior.write(self, section, value)
            local mesh_status = luci.http.formvalue("cbid.wireless.wmesh.disabled")
            if mesh_status == "0" then
                ListValue.write(self, section, value)
            end
        end
    end

    radio_band = s:option(ListValue, "hwmode", translate("802.11 Mode"))

    htmode = s:option(ListValue, "htmode", translate("Channel Bandwidth"))

    radio_channel = s:option(ListValue, "channel", translate("Channel"), "")
    radio_channel.header_style = "display:none"
    radio_channel.rmempty = false
    radio_channel.force_keep = true

    local radio_channel_title = s:option(DummyValue, "_channel", translate("Channel"))
    radio_channel_title.render = function(self, s, scope)
        luci.template.render("cbi/valueheader", {section = s, self = self})
        self.template = "cbi/value_inline_right"
    end

    specific_channel_btn = s:option( DummyValue, "_specific_channel", translate("Channel"))
    specific_channel_btn.empty_next = true
    specific_channel_btn.cond_optional = true
    specific_channel_btn.optional = false
    specific_channel_btn.section = radio_device
    specific_channel_btn.custom = "style='width:50px' "
    specific_channel_btn.render = function(self, s, scope)
        luci.http.write('<div style="display:inline-block" class="channel-btn" >')
        self.template = "cbi/wifi_frequency_btn"
        AbstractValue.render(self, s, nil)
        luci.http.write('</div><br></div>')
    end

    -- WME Configuration
    wme_table = s:option(Value, "wme_0", translate("BestEffort"), "")
    wme_table.header_style = "display:none"
    wme_table.rmempty = false
    wme_table.force_keep = true

    local wme_config_title = s:option( DummyValue, "_wme", translate("WME Configure"))
    wme_config_title.render = function(self, s, scope)
        luci.template.render("cbi/valueheader", {section = s, self = self})
        self.template = "cbi/value_inline_right"
    end

    wme_config_btn = s:option( DummyValue, "_wme", translate("config btn"))
    wme_config_btn.empty_next = true
    wme_config_btn.cond_optional = true
    wme_config_btn.optional = false
    wme_config_btn.section = radio_info.device
    wme_config_btn.custom = "style='width:50px' "
    wme_config_btn.render = function(self, s, scope)
        luci.http.write('<div style="display:inline-block" class="channel-btn" >')
        self.template = "cbi/wifi_wme_btn"
        AbstractValue.render(self, s, nil)
        luci.http.write('</div><br></div>')
    end

    local beacon_interval = s:option( Value, "beacon_int", translate("Beacon Interval"))
    beacon_interval.default = "100"
    beacon_interval.rmempty = "false"

    if show_bandsteering then
        bandsteering    = s:option( Flag, "bandsteering", translate("Bandsteering"))
        bandsteering.rmempty = false
        bandsteering.help_tip = ("<b>") .. translate("5 GHz Bandsteering") .. ("</b>")
            .. ("<br/><br/>") .. translate("Clients with both 2.4 and 5 GHz capabilitles will connect first to the 5 GHz radio on this device. "
            .. "This feature helps you spread clients across the two bands, improving user experience.")
            .. ("<br/><br/>")
            .. ("<b>")
            .. translate("NOTE: The SSIDs and security settings on the 2.4 and 5 GHz radios must match for this feature to be fully enabled!")
            .. ("<b/>")

        if mode:match("sta") then
            bandsteering.header_style = "display:none"
        end
    end

    airtime_fairness    = s:option( Flag, "atfpolicy", translate("Airtime Fairness"))
    airtime_fairness.rmempty = false
    airtime_fairness.help_tip = ("<b>") .. translate("Airtime Fairness") .. ("</b>")
        .. ("<br/><br/>") .. translate("Enabling this feature improves the overall performance of wireless network.")
        .. ("</br></br>") .. translate("The faster device can get the better performance.")

    if mode:match("sta") then
        airtime_fairness.header_style = "display:none"
    end

    bss_color = s:option(Value, "he_bss_color", translate("BSS coloring"))
    bss_color.default = "64"
    bss_color:depends("hwmode", "11axa")
    bss_color:depends("hwmode", "11axg")
    bss_color.datatype = "range(1, 64)"
    bss_color.help_tip = ("<b>") .. translate("BSS color selection") .. ("</b>")
        .. ("<br/><br/>1-63 = ") .. translate("Pre-defined color")
        .. ("<br/>64 = ") .. translate("Random color")

    chan_util_delta = s:option( Value, "chan_util_delta", translate("Interference Detection"))
    chan_util_delta.force_required = true
    chan_util_delta.optional = false
    chan_util_delta.rmempty = false
    chan_util_delta.help_tip = ("<br/><b>") .. translate("Channel utilization threshold") .. ("</b>")
        .. ("<br/><br/>") .. translate("When Utilization of the current channel or adjacent channel reaches "
        ..  " the configured threshold (in %), the AP switches to a different Channel.")
        .. ("</br></br>") .. translate("Set this field to 0 to disable this feature.")

    chan_util_delta.default = "0"
    chan_util_delta.datatype = "range(0, 99)"
    if mode:match("sta") then
        chan_util_delta.header_style = "display:none"
    end

    enable_ofdma = s:option(Flag, "_ofdma", translate("OFDMA"))
    enable_ofdma.rmempty    = false
    enable_ofdma.default    = "1"
    enable_ofdma.is_disabled = true
    enable_ofdma:depends("hwmode", "11axa")
    enable_ofdma:depends("hwmode", "11axg")

    enable_ofdma.write = function(self, section, value)
        local var_hwmode = m.uci:get("wireless", section, "hwmode")
        if var_hwmode == "11axa" or var_hwmode == "11axg" then
            m.uci:set("wireless", section, "_ofdma", 1)
        end
    end

    twt_required = s:option(Flag, "he_twt_required", translate("Target Wake Time"))
    twt_required.rmempty    = false
    twt_required.default    = "0"
    twt_required:depends("hwmode", "11axa")
    twt_required:depends("hwmode", "11axg")

    basic_rate = s:option( ListValue, "basic_rate", translate("Broadcast Rate"))
    if is_5g then -- supported_rates = 6000 9000 12000 18000 24000 36000 48000 54000
        basic_rate:value("6000", "6M")
        basic_rate:value("9000", "9M")
        basic_rate:value("12000", "12M")
        basic_rate:value("18000", "18M")
        basic_rate:value("24000", "24M")
        basic_rate:value("36000", "36M")
        basic_rate:value("48000", "48M")
        basic_rate:value("54000", "54M")
        basic_rate.default = "6000"
    else -- supported_rates = 5500 6000 9000 11000 12000 18000 24000 36000 48000 54000
        basic_rate:value("5500", "5.5M")
        basic_rate:value("6000", "6M")
        basic_rate:value("9000", "9M")
        basic_rate:value("11000", "11M")
        basic_rate:value("12000", "12M")
        basic_rate:value("18000", "18M")
        basic_rate:value("24000", "24M")
        basic_rate:value("36000", "36M")
        basic_rate:value("48000", "48M")
        basic_rate:value("54000", "54M")
        basic_rate.default = "5500"
    end

    rf_isolate = s:option(Flag, "rf_isolate", translate("RF Isolation"))
    rf_isolate.rmempty = false
    rf_isolate.default = "0"
    rf_isolate.help_tip = ("<b>") .. translate("Clients are isolated between different radio cards.") .. ("</b>")

    rf_isolate.write = function(self, section, value)
        if value == self.enabled then
            self.map.uci:set("wireless", "radio0", "rf_isolate", 1)
            self.map.uci:set("wireless", "radio1", "rf_isolate", 1)
        else
            self.map.uci:set("wireless", "radio0", "rf_isolate", 0)
            self.map.uci:set("wireless", "radio1", "rf_isolate", 0)
        end
    end

    ssid_isolate = s:option(Flag, "ssid_isolate", translate("SSID Isolation"))
    ssid_isolate.rmempty = false
    ssid_isolate.default = "0"
    ssid_isolate.help_tip = ("<b>") .. translate("Clients are isolated on different SSIDs but the same radio cards.") .. ("</b>")

    ssid_isolate.write = function(self, section, value)
        if value == self.enabled then
            self.map.uci:set("wireless", "radio0", "ssid_isolate", 1)
            self.map.uci:set("wireless", "radio1", "ssid_isolate", 1)
        else
            self.map.uci:set("wireless", "radio0", "ssid_isolate", 0)
            self.map.uci:set("wireless", "radio1", "ssid_isolate", 0)
        end
    end

    if root_user == false and msp_disabled == false then
        radio_status.header_style           = "display:none"
        radio_mode.header_style             = "display:none"
        radio_band.header_style             = "display:none"
        htmode.header_style                 = "display:none"
        radio_channel.header_style          = "display:none"
        radio_channel_title.header_style    = "display:none"
        specific_channel_btn.header_style   = "display:none"
        beacon_interval.header_style        = "display:none"
        bandsteering.header_style           = "display:none"
        airtime_fairness.header_style       = "display:none"
        chan_util_delta.header_style        = "display:none"
        wme_config_title.header_style       = "display:none"
        wme_config_btn.header_style         = "display:none"
        bss_color.header_style              = "display:none"
        enable_ofdma.header_style           = "display:none"
        twt_required.header_style           = "display:none"
        basic_rate.header_style             = "display:none"
        rf_isolate.header_style             = "display:none"
	ssid_isolate.header_style           = "display:none"
    end

    function m.on_after_parse(map)

        if is_postback then
            local is_cbi_apply = luci.http.formvalue("cbi.apply")
            local is_del_vap = false
            local mode = map.uci:get("wireless", radio_device, "mode")

            -- Make sure first SSID is created and enabled
            if mode:match("sta") then
                map.uci:set("wireless", radio_device .. "_1", "disabled", "0")
                map.uci:set("wireless", radio_device .. "_1", "created", "1")
            end

            if rename_wifi_sections and not mode:match("sta") then
                -- #10953: if device is cloud controlled, don't save any of the ssids/don't reorder when other radio settings are changed
                if not mgmt_enabled then
                    for j=1, #created_radios do
                        local dynamic_vlan_exist = map.uci:get("wireless", created_radios[j], "dynamic_vlan")

                        if not dynamic_vlan_exist then
                            map.uci:delete("wireless", radio_device .. "_" .. j, "dynamic_vlan")
                            map.uci:delete("wireless", radio_device .. "_" .. j, "vlan_tagged_interface")
                            map.uci:delete("wireless", radio_device .. "_" .. j, "vlan_bridge")
                        end

                        map.uci:rename("wireless", created_radios[j], radio_device .. "_" .. j)
                        if map.uci:get("wireless", radio_device .. "_" .. j, "dae_enable") then
                            map.uci:rename("firewall", created_radios[j], radio_device .. "_" .. j)
                        end

                        -- update multiple key iface value
                        map.uci:foreach('wireless', 'wifi-station', function(s)
                          if created_radios[j] == s.iface then
                              map.uci:set('wireless', s['.name'], 'iface', radio_device .. "_" .. j)
                          end
                        end)

                    end

                    for j=1, #uncreated_radios do
                        map.uci:rename("wireless", uncreated_radios[j], radio_device .. "_" .. (#created_radios+ j) )
                        local del_res = map.uci:delete("wireless", radio_device .. "_" .. (#created_radios+ j))
                        if del_res then
                          is_del_vap = true
                        end
                    end
                end
            end

            -- #10953: if device is cloud controlled, don't save any of the ssids/don't reorder when other radio settings are changed
            if not mgmt_enabled then
                for j=1, #created_radios do
                    new_order = num_wifi_radios + (rad_id * max_ssids) + j-1
                    map.uci:reorder("wireless", radio_device .. "_" .. j, new_order)
                    if j ~= 1 then
                        local new_ifname = pre_ifname_name .. rad_id .. "-" .. (j-1)  --wlanX-Y
                        map.uci:set("wireless", radio_device .. "_" .. j, "ifname", new_ifname)
                    end
                end

                -- Fix UCI order of main wireless section
                map.uci:reorder("wireless", radio_device, rad_id)
            end
            if is_cbi_apply then
                map.apply_needed = true
            end
        end
    end
end

function get_scan_possible(radio_idx, vap_idx)
    -- This lines differ from rtk-wifi implementation, because qca may have 60G radio
    local path_prswifi = "/sys/devices/virtual/net/%s/%s"
    local runtime_radio_state
    local peraso_state_file = path_prswifi % {acn_util.wifi_iface_name(radio_idx, 1), "operstate"}
    local runtime_radio_state = (fs.access(peraso_state_file) and (fs.readfile(peraso_state_file)):match("(%a+)")) or "down"
    local wifi_is_up
    local ntm = nw.init()
    local wifi_info = ntm:get_interface(acn_util.wifi_iface_name(radio_idx, 1))
    if wifi_info then
        wifi_is_up = wifi_info:is_up()
    end

    return true
end

--=============================================================================================
-- SSID Configuration
--=========================================================================================================================

-- Modals for this page
luci.dispatcher.context.modal_template = luci.dispatcher.context.modal_template or {}
luci.dispatcher.context.modal_template[#luci.dispatcher.context.modal_template + 1] = "cbi/wifi_scan_modal"
--luci.dispatcher.context.modal_template[#luci.dispatcher.context.modal_template + 1] = "cbi/wifi_aiming_mode"
luci.dispatcher.context.modal_template[#luci.dispatcher.context.modal_template + 1] = "cbi/wifi_frequency_modal"
luci.dispatcher.context.modal_template[#luci.dispatcher.context.modal_template + 1] = "cbi/wifi_wme_modal"

ssid_num = max_ssids

-- Only do this if posting back...
function add_ssid_section(j, m, rad_id, render)
    local vap_pre_form = "cbid.wireless." .. radio_device .. "_" .. j .. "."

    -- #9639 forbid to scan while radio is down
    scan_possible = get_scan_possible(rad_id, tostring(j))

    -- This is used on tabs for the SSIDs
    s3 = m:section(NamedSection, acn_util.wifi_section(rad_id, j), "wifi-iface", translate("SSID") )
    s3.addremove = false

    if not render then
       s3.render = function() local dummy end
    end

    s3.template = "cbi/ssid_content"
    s3.radio_id = radio_id
    s3.ssid_id = tonumber(j)
    s3.mode = m.uci:get("wireless", radio_device, "mode") or "ap"

    if mgmt_enabled and (msp_disabled or root_user) then
        local wifi_mgmt_alert  = s3:option(DummyValue, "wifi_mgmt_alert","")
        wifi_mgmt_alert.template = "cbi/wifi_mgmt_alert"
        wifi_mgmt_alert.section = radio_device .. "_" .. tonumber(j)
    end

    ssid_title = s3:option(DummyValue, "ssid_title", translate("General Settings"))
    ssid_title.template = "cbi/plain_heading"
    ssid_title.addl_classes = "padding-bottom-10"
    ssid_title:depends(mode, "ap")
    ssid_title:depends(mode, "ap-wds")
    ssid_title.first = true
    ssid_title.addl_classes = "padding-bottom-10"

    wifi_status1 = s3:option(Flag, "disabled", translate("Status"))
    wifi_status1.rmempty    = false
    wifi_status1.enabled    = "0"
    wifi_status1.disabled   = "1"

    wifi_status1.force_keep   = true

    wifi_status1.write = function(self, section, value)
        if j > 1 and acn_util.is_sta_mode(self.map.uci:get("wireless", radio_device , "mode")) then
            self.map.uci:set("wireless", section, "disabled", "1")
        else
            self.map.uci:set("wireless", section, "disabled", value)
        end
        acn_util.handle_wan_type(self.map.uci)
    end

    ssid1 = s3:option( Value , "ssid", translate("SSID"))
    ssid1.datatype = "limited_len_str(1,32)"
    ssid1.render = function(self, s3, scope)
            luci.template.render("cbi/valueheader", {section = s3, self = self})
            self.template = "cbi/value_inline_right"
            AbstractValue.render(self, s3, nil)
    end
    ssid1.rmempty = false

    -- #9639 forbid to scan while radio is down
    if scan_possible then
        scan1           = s3:option( DummyValue, "_scan", translate("Scan"))
        scan1.empty_next        = true
        scan1.cond_optional     = true
        scan1.optional          = false
        scan1.custom  = "style='width:50px' "
        scan1.radio_id = rad_id
        scan1.section = radio_device .. "_" .. tonumber(j)
        scan1.is_controlled_by_cloud = is_controlled_by_cloud
        scan1.render =  function(self, s3, scope)
            luci.http.write('<div style="display:inline-block" class="scan-btn" >')
            self.template = "cbi/scan"
            self.idx = j
            luci.http.write('<span class="inline-control-label">&nbsp;' .. "</span>")
            AbstractValue.render(self, s3, nil)
            luci.http.write('</div>')
        end
        hidden1 = s3:option( Flag, "hidden", translate("Broadcast"))
    else
        hidden1 = s3:option( Flag, "hidden", translate("Broadcast"))
        scan_impossible_msg = s3:option(DummyValue, "scan_impossible_msg","")
        scan_impossible_msg.template = "cbi/scan_impossible_msg"
        scan_impossible_msg.logical_name = radio_device .. '_' .. tostring(j)
    end
    hidden1.enabled  = "0"
    hidden1.disabled = "1"
    hidden1.empty_next      = true
    hidden1.cond_optional   = true
    hidden1.optional        = false
    hidden1.rmempty         = true
    hidden1.old_checkbox    = true
    hidden1.custom  = "style='width:50px' "

    hidden1.render =  function(self, s3, scope)
        luci.http.write('<div style="display:inline-block" class="broadcast-checkbox">')
        self.template = "cbi/fvalue_inline"
        self.label = translate("Broadcast")
        AbstractValue.render(self, s3, nil)
        luci.http.write('</div>')
        luci.template.render("cbi/valuefooter",  {section = s3, self = self})
    end

    local_configurable = s3:option(Flag, "local_configurable", translate("Local Configurable"))
    local_configurable.rempty = false
    local_configurable.default = 0
    -- if MSP mode is disabled then Local configurable should be locked down
    if msp_disabled then
        local_configurable.is_disabled = true
    end

    client_isolation = s3:option( Flag, "isolate", translate("Client Isolation"))
    mcastenhance = s3:option( Flag, "multicast_to_unicast", translate("Multicast-to-Unicast Conversion"))
    mcastenhance.rmempty = false
    mcastenhance.is_disabled = true
    mcastenhance.write = function(self, section, value)
        local ap_isolate = luci.http.formvalue(vap_pre_form .. "isolate")

        if ap_isolate == "1" then
            Flag.write(self, section, value)
        else
            local network_behavior = luci.http.formvalue(vap_pre_form .. "network_behavior")
            if network_behavior ~= "dynamic_vlan" then
                Flag.write(self, section, "1")
            end
        end
    end
    wmm1            = s3:option( Flag, "wmm", translate("WMM"))
    wmm1.rmempty    = false
    wmm1.force_keep = true
    wmm1.default    = 1
    wmm1.render = function(self, s3, scope)
        luci.template.render("cbi/valueheader", {section = s3, self = self})
        self.template = "cbi/fvalue_inline"
        AbstractValue.render(self, s3, nil)
        luci.template.render("cbi/valuefooter",  {section = s3, self = self})
    end
    wmm1.write = function(self, section, value)
        -- Enable WMM if we need to
        if posted_hwmode and posted_hwmode ~= "11a" and posted_hwmode ~= "11g" then
            self.map.uci:set("wireless", section, "wmm", "1")
        else
            self.map.uci:set("wireless", section, "wmm", value)
        end
    end

    maxassoc= s3:option(  Value , "maxassoc", translate("Max Clients"))
    maxassoc.datatype = "range(1, 254)"
    maxassoc.default = 127
    maxassoc.rmempty = false

    min_allow_sig = s3:option( Value, "signal_stay", translate("Minimum signal allowed"))
    min_allow_sig.force_required = true
    min_allow_sig.optional = false
    min_allow_sig.rmempty = false
    min_allow_sig.help_tip = ("<br/><b>") .. translate("Min. allowed signal level") .. ("</b>")
        .. ("<br/><br/>") .. translate("A client will only be allowed to associate to this Radio if their signal (RSSI) "
        ..  " is greater than or equal to the value you specify the field.")
        .. ("<br/><br/><b>") .. translate("Suggested value") .. ("</b>")
        .. ("<br/>") .. translate("High Density: -70")
        .. ("<br/>") .. translate("Low Density: -80")
        .. ("<br/><br/>") .. translate("Set this field to -100 to disable this feature.")

    min_allow_sig.default = "-100"

    min_allow_sig.cfgvalue = function(self, section)
      local _value = Value.cfgvalue(self, section)
      if _value and value ~= "" and _value ~= "-128" then
        return _value
      else
        return "-100"
      end
    end

    min_allow_sig.write = function(self, section, value)
    local pre_signal_stay = tonumber(luci.http.formvalue(vap_pre_form .. "signal_stay"))
    local res=0
      if value and value ~= "" and value ~= "0" then
        res = pre_signal_stay-100
        self.map.uci:set("wireless", section, "signal_connect", tostring(res))

        return Value.write(self, section, tostring(res))
      else
        self.map.uci:set("wireless", section, "signal_connect", "-128")

        return Value.write(self, section, "-128")
      end
    end

    local max_inactivity = s3:option( Value, "max_inactivity", translate("Idle Timeout (sec)"))
    max_inactivity.datatype = "range(60, 60000)"
    max_inactivity.rmempty = "false"
    max_inactivity.default = 300

    local deny_os = s3:option(MultiValue, "deny_os", translate("Device OS Blacklist"))
    deny_os.rmempty = true
    deny_os.optional = false
    deny_os.template = "cbi/deny_os"
    deny_os:value("0", translate("Android"))
    deny_os:value("1", translate("iOS/macOS"))
    deny_os:value("2", translate("Windows"))
    deny_os:depends("wireless." .. radio_device .. ".mode", "ap")
    deny_os:depends("wireless." .. radio_device .. ".mode", "ap-wds")

    uapsd = s3:option(Flag, "uapsd", translate("U-APSD"))
    uapsd.rmempty = false
    uapsd.force_keep = true
    uapsd.default = "1"

    if root_user == false and msp_disabled == false then
        local_configurable.header_style     = "display:none"
        client_isolation.header_style       = "display:none"
        maxassoc.header_style               = "display:none"
        max_inactivity.header_style         = "display:none"
        mcastenhance.header_style           = "display:none"
        wmm1.header_style                   = "display:none"
        deny_os.header_style                = "display:none"
    end

    security_til1   = s3:option( DummyValue, "sec_til", translate("Security Settings"))
    security_til1.template  = "cbi/plain_heading"

    fake_user2 = s3:option(Value, "fake_user2", translate("fake_user"))
    fake_pass2 = s3:option(Value, "fake_password2", translate("fake_pass"))
    fake_user2.header_style = "display:none"
    fake_pass2.password = true
    fake_pass2.header_style = "display:none"

    encr1 = s3:option( ListValue, "encryption", translate("Method"))
    encr1:value("none", translate("No Security"))
    encr1:value("psk", "WPA-PSK")
    encr1:value("psk2", "WPA2-PSK")
    encr1:value("wpa", "WPA-EAP")
    encr1:value("wpa2", "WPA2-EAP")
    encr1:value("sta-wpa", "WPA-EAP")
    encr1:value("sta-wpa2", "WPA2-EAP")
    encr1:value("sae", "WPA3 Personal")
    encr1:value("sae-mixed", "WPA3 Personal Transition")
    encr1:value("wpa3", "WPA3 Enterprise")
    encr1:value("wpa3-mixed", "WPA3 Enterprise Transition")
    encr1:value("wpa3-192", "WPA3 Enterprise 192-bit")
    encr1:value("sta-wpa3", "WPA3 Enterprise")
    encr1:value("sta-wpa3-mixed", "WPA3 Enterprise Transition")
    encr1:value("owe", "OWE")

    encr1.default = "none"

    function encr1.cfgvalue(self, section)

        local v = tostring(ListValue.cfgvalue(self, section))
        if v and v:match("%+") then
            return (v:gsub("%+.+$", ""))
        end

        local mode = m.uci:get("wireless", radio_device, "mode")

        if acn_util.is_sta_mode(mode) and (v == "wpa" or v == "wpa2" or v == "wpa3" or v == "wpa3-mixed" or v == "wpa3-192") then
            return "sta-" .. v
        end

        -- for Dynamic MPSK
        if v == "psk2-radius" then
            v="psk2"
        end

        return v
    end

    function encr1.write(self, section, value)
        local e = encr1 and tostring(encr1:formvalue(section))
        local c = cipher1 and tostring(cipher1:formvalue(section))
        local km = key_method and tostring(key_method:formvalue(section))

        -- set broadcast key for security SSID, #20797
        if value ~= "none" then
            self.map.uci:set("wireless", section, "wpa_strict_rekey", 0)
            self.map.uci:set("wireless", section, "wpa_group_rekey", 86400)
            self.map.uci:set("wireless", section, "eap_reauth_period", 0)
        else
            self.map.uci:delete("wireless", section, "wpa_strict_rekey")
            self.map.uci:delete("wireless", section, "wpa_group_rekey")
            self.map.uci:delete("wireless", section, "eap_reauth_period")
        end

        if value == "sta-wpa" or value == "sta-wpa2" or value == "sta-wpa3" or value == "sta-wpa3-mixed" then
            e = value:gsub("sta%-", "")
        end

        if value == "wpa" or value == "wpa2" or value == "sae" or value=="sae-mixed" or value == "wpa3" or value == "wpa3-mixed" or value == "wpa3-192" then
            self.map.uci:delete("wireless", section, "key")
        end

        if e and (c == "tkip" or c == "ccmp" or c == "tkip+ccmp") then
            e = e .. "+" .. c
        end

        -- for WAP3-Personal
        if value == "sae" or e:find("sae") or value == "sae-mixed" or e:find("sae-mixed") then
            e = value
        end

        -- Set the uci configuration wpa_disable_eapol_key_retries=1 for WPA-EAP, WPA2-EAP, WPA3-Enterprise, ...
        -- ... WPA3-Enterprise Transistion, WPA3-Enterprise 192 bit
        if value == "wpa" or value == "wpa2" or value == "wpa3" or value == "wpa3-mixed" or value == "wpa3-192" then
            self.map.uci:set("wireless", section, "wpa_disable_eapol_key_retries", 1)
        else
            self.map.uci:set("wireless", section, "wpa_disable_eapol_key_retries", 0)
        end

        -- support Dynamic multiple PSK
        if(km == "dpsk") then
            e = "psk2-radius"
        end

        self.map:set(section, "encryption", e)
    end

    fake_user6 = s3:option(Value, "fake_user6", translate("fake_user"))
    fake_pass6 = s3:option(Value, "fake_password6", translate("fake_pass"))
    fake_user6.header_style = "display:none"
    fake_pass6.password = true
    fake_pass6.header_style = "display:none"

    cipher1 = s3:option( ListValue, "cipher", translate("Encryption"))
    cipher1:depends({encryption="wpa"})
    cipher1:depends({encryption="wpa2"})
    cipher1:depends({encryption="psk"})
    cipher1:depends({encryption="psk2"})
    cipher1:depends({encryption="wpa-mixed"})
    cipher1:depends({encryption="psk-mixed"})
    cipher1:value("ccmp", translate("CCMP (AES)"))
    cipher1:value("tkip+ccmp", translate("Auto: TKIP + CCMP (AES)"))
    function cipher1.cfgvalue(self, section)
        local v = tostring(ListValue.cfgvalue(encr1, section))

        -- for WAP3-Personal
        if v == "tkip+ccmp" then
            return v
        end

        if v and v:match("%+") then
            v = v:gsub("^[^%+]+%+", "")
            if v == "aes" then v = "ccmp"
            elseif v == "tkip+aes" then v = "tkip+ccmp"
            elseif v == "aes+tkip" then v = "tkip+ccmp"
            elseif v == "ccmp+tkip" then v = "tkip+ccmp"
            end
        end
        return v
    end

    function cipher1.write(self, section)
        return encr1:write(section)
    end

    key_method = s3:option( ListValue, "key_method", translate("Key Method"))

    key_method:depends("encryption", "psk")
    key_method:depends("encryption", "psk2")
    key_method:depends("encryption", "psk+psk2")
    key_method:depends("encryption", "psk-mixed")
    key_method:depends("encryption", "sae")
    key_method:depends("encryption", "sae-mixed")
    key_method:value("psk", translate("Single PSK"))
    key_method:value("mpsk", translate("Multiple PSK"))
    key_method:value("dpsk", translate("Dynamic PSK"))
    key_method.default = "psk"

    function key_method.write(self, section, value)
        -- support Dynamic multiple PSK
        if(value == "dpsk") then
            self.map.uci:set("wireless", section, "encryption", "psk2-radius")
        end

        return ListValue.write(self, section, value)
    end

    wpakey1 = s3:option( Value, "_wpa_key", translate("Key"))

    wpakey1:depends("key_method", "psk")
    wpakey1:depends("key_method", "mpsk")
    wpakey1.datatype = "wpakey"
    wpakey1.rmempty = false
    wpakey1.password = true
    wpakey1.force_required = true
    wpakey1.cfgvalue = function(self, section, value)
        local key = m.uci:get("wireless", section, "key")
        if key == "1" or key == "2" or key == "3" or key == "4" then
            return nil
        end
        return key
    end

    wpakey1.write = function(self, section, value)
        self.map.uci:set("wireless", section, "key", value)
        self.map.uci:delete("wireless", section, "key1")
    end

    -- Multiple keys for WPA-PSK, WPA2-PSK, WPA3-Personal Transition
    multi_key = s3:option(TextValue, "_multi_key", translate("Multiple Keys"))
    multi_key.header_style = "display:none"

    multi_key.help_text = translate("Enter one Key and optional MAC per line.")
    ..  ("<br/>") .. translate("Example: 12345678 00:12:34:56:78:9a")
    multi_key.width = "300px"
    multi_key.rows = 5
    multi_key.cust_style = 'font-family:monospace !important;font-size:12pt'

    function multi_key.cfgvalue(self, section)
        local iface_counter = {}
        local cfg_val = {}

        acn_uci:foreach('wireless', 'wifi-station', function(s)
            local wifi_station_iface = s.iface
            if wifi_station_iface == section then
                iface_counter[wifi_station_iface] = (iface_counter[wifi_station_iface] or 0) + 1
                local wifi_station_number = iface_counter[wifi_station_iface]
                local wifi_station_key = s.key
                local wifi_station_mac = s.mac or ""

                if wifi_station_key then
                    cfg_val[wifi_station_number] = wifi_station_key .. " " .. wifi_station_mac
                end
            end
        end)

        local ret_cfg_val = ""
        for i, key_mac in pairs(cfg_val) do
            ret_cfg_val = ret_cfg_val .. "\n" .. key_mac
        end
        return ret_cfg_val
    end

    function multi_key.write(self, section, value)
        acn_uci:foreach('wireless', 'wifi-station', function(s)
            if section == s.iface then
                acn_uci:delete('wireless', s['.name'])
            end
        end)

        local val = tostring(luci.util.trim(multi_key:formvalue(section))) or ""
        local entries = luci.util.split(val, "\n") or {}

        for i, key_mac in ipairs(entries) do
            key_mac = luci.util.trim(key_mac)

            local key_mac1 = luci.util.split(key_mac, " ") or {}
            if key_mac1 then
                local key1 = key_mac1[1]
                local mac1 = key_mac1[2]

                local section_name = self.map.uci:add("wireless", "wifi-station")
                if section_name then
                    self.map.uci:set("wireless", section_name, "iface", section)
                    self.map.uci:set("wireless", section_name, "key", key1)
                    self.map.uci:set("wireless", section_name, "mac", mac1)
                end
            end
        end
    end

    function multi_key.remove(self, section)
        acn_uci:foreach('wireless', 'wifi-station', function(s)
            if section == s.iface then
                acn_uci:delete('wireless', s['.name'])
            end
        end)
    end

    pmf = s3:option(ListValue, "ieee80211w", translate("PMF"))
    pmf:depends("encryption", "psk2")
    pmf:depends("encryption", "wpa2")
    pmf:depends("encryption", "sae-mixed")
    pmf:depends("encryption", "wpa3-mixed")
    pmf:value("0", translate("Disabled")) -- psk2 or wpa2, controlled by wifi.js
    pmf:value("1", translate("Optional"))
    pmf:value("2", translate("Mandatory"))
    pmf.default = "1"

    FT11k_enable    = s3:option( Flag, "ieee80211k", translate("802.11k"))
    FT11k_enable.rmempty = false

    FT11r_enable    = s3:option( Flag, "ieee80211r", translate("802.11r"))
    FT11r_enable:depends({encryption="wpa2"})
    FT11r_enable:depends({encryption="psk2"})
    FT11r_enable:depends({encryption="sae"})
    FT11r_enable:depends({encryption="sae-mixed"})
    FT11r_enable:depends({encryption="wpa3"})
    FT11r_enable:depends({encryption="wpa3-mixed"})
    FT11r_enable.rmempty = false

    FT11r_enable.write = function(self, section, value)
        Flag.write(self, section, value)

        if acn_util.is_enabled(value) then
            self.map.uci:set("wireless", section, "ft_over_ds", 0)
        else
            self.map.uci:delete("wireless", section, "ft_over_ds")
        end
    end

    FT11v_enable    = s3:option( Flag, "ieee80211v", translate("802.11v"))
    FT11v_enable.rmempty = false
    FT11v_enable.enabled  = "1"
    FT11v_enable.disabled = "0"

    FT11v_enable.write = function(self, section, value)
        Flag.write(self, section, value)

        if value == self.enabled then
            self.map.uci:set("wireless", section, "time_advertisement", 2)
            self.map.uci:set("wireless", section, "bss_transition", 1)
            self.map.uci:set("wireless", section, "wnm_sleep_mode", 1)
        else
            self.map.uci:delete("wireless", section, "time_advertisement")
            self.map.uci:delete("wireless", section, "bss_transition")
            self.map.uci:delete("wireless", section, "wnm_sleep_mode")
        end
    end

    rac_enable1 = s3:option( Flag, "radius_mac_acl", translate("Radius MAC Auth"))
    rac_enable1.rmempty = false

    radsec_enable = s3:option( Flag, "radsec_enable", translate("Enable RadSec"))
    radsec_enable.rmempty = false
    radsec_enable.enabled = "1"
    radsec_enable.disabled = "0"

    auth_server1 = s3:option( Value, "auth_server", translate("Radius Auth Server"))

    -- RADIUS Auth
    auth_server1.rmempty = true

    fake_user3 = s3:option(Value, "fake_user3", translate("fake_user"))
    fake_pass3 = s3:option(Value, "fake_password3", translate("fake_pass"))
    fake_user3.header_style = "display:none"
    fake_pass3.password = true
    fake_pass3.header_style = "display:none"

    auth_port1 = s3:option( Value, "auth_port", translate("Radius Auth Port"))
    auth_port1.rmempty = true
    auth_port1.default = "1812"
    function auth_port1.write(self, section, value)
      return Value.write(self, section, value)
    end

    auth_secret1 = s3:option( Value, "auth_secret", translate("Radius Auth Secret"))
    auth_secret1.rmempty = true
    auth_secret1.password = true

    nas_id = s3:option( Value, "nasid", translate("NAS ID"))
    nas_id.rmempty = true

    -- RADIUS Auth Backup
    auth_enable2 = s3:option( Flag, "radius_auth_enable2", translate("Backup Radius Auth"))
    auth_enable2.rmempty = true

    auth_server2 = s3:option( Value, "auth_server2", translate("Radius Auth Server"))
    auth_server2:depends("radius_auth_enable2","1")
    auth_server2.datatype = "ip4addr"
    auth_server2.rmempty = true

    auth_port2 = s3:option( Value, "auth_port2", translate("Radius Auth Port"))
    auth_port2:depends("radius_auth_enable2","1")
    auth_port2.rmempty = true
    auth_port2.default = "1812"
    auth_port2.datatype = "port"

    auth_secret2 = s3:option( Value, "auth_secret2", translate("Radius Auth Secret"))
    auth_secret2:depends("radius_auth_enable2", "1")
    auth_secret2.rmempty = true
    auth_secret2.password = true
    auth_secret2.datatype ="rangelength(1, 200)"

    -- RADIUS Account
    acct_enable1 = s3:option( Flag, "acct_enable", translate("Use Radius Accounting"))
    acct_enable1:depends( "encryption","wpa")
    acct_enable1:depends( "encryption","wpa2")
    acct_enable1:depends( "encryption","wpa3")
    acct_enable1:depends( "encryption","wpa3-mixed")
    acct_enable1:depends( "encryption","wpa3-192")
    acct_enable1:depends( "key_method","dpsk")
    acct_enable1.rmempty = true
    function acct_enable1.cfgvalue(self, section)
        local value = m.uci:get("wireless", section, "acct_server")
        if value then
            return "1"
        else
            return "0"
        end
    end
    function acct_enable1.write(self, section, value)
    end

    acct_server1 = s3:option( Value, "acct_server", translate("Acct Server"))
    acct_server1:depends( "acct_enable","1")
    acct_server1.rmempty = true
    acct_server1.datatype = "ip4addr"
    -- If clear out acct server, then clear out port, too
    -- Not best solution because it resets port to default value, but whatever
    function acct_server1.remove(self, section)
        self.map.uci:delete("wireless", section, "acct_port")
        Value.remove(self, section)
    end

    fake_user4 = s3:option(Value, "fake_user4", translate("fake_user"))
    fake_pass4 = s3:option(Value, "fake_password4", translate("fake_pass"))
    fake_user4.header_style = "display:none"
    fake_pass4.password = true
    fake_pass4.header_style = "display:none"

    acct_port1 = s3:option( Value, "acct_port", translate("Acct Port"))
    acct_port1:depends( "acct_enable","1")
    acct_port1.rmempty = true
    acct_port1.datatype = "port"
    acct_port1.default = "1813"
    -- Only set port if server is also set
    function acct_port1.write(self, section, value)
        local acct_server = luci.http.formvalue(vap_pre_form .. "acct_server")
        if acct_server ~= nil and #acct_server > 0 then
            Value.write(self, section, value)
        else
            Value.write(self, section, "")
        end
    end

    acct_secret1    = s3:option( Value, "acct_secret", translate("Acct Secret"))

    acct_secret1:depends( "acct_enable","1")
    acct_secret1.rmempty = true
    acct_secret1.password = true

    acct_interval1    = s3:option( Value, "acct_interval", translate("Acct Interim Interval"))
    acct_interval1:depends( "acct_enable", "1")
    acct_interval1:depends( "CAPWAP_tunnel", "1")
    acct_interval1.rmempty = true
    acct_interval1.datatype = "range(60, 600)"

    -- RADIUS Account backup
    acct_enable2    = s3:option( Flag, "acct_enable2", translate("Backup Radius Acct"))
    acct_enable2:depends( "acct_enable", "1")
    acct_enable2.rmempty = true

    acct_server2    = s3:option( Value, "acct_server2", translate("Radius Acct Server"))

    acct_server2:depends("acct_enable2", "1")
    acct_server2.rmempty = true
    acct_server2.datatype = "ip4addr"

    acct_port2      = s3:option( Value, "acct_port2", translate("Radius Acct Port"))

    acct_port2:depends( "acct_enable2","1")
    acct_port2.rmempty = true
    acct_port2.datatype = "port"
    acct_port2.default = "1813"

    acct_secret2    = s3:option( Value, "acct_secret2", translate("Radius Acct Secret"))

    acct_secret2:depends( "acct_enable2","1")
    acct_secret2.rmempty = true
    acct_secret2.password = true

    auth_method1    = s3:option( ListValue, "eap_type", translate("Auth Method"))
    auth_method1:value("peap", "EAP-PEAP")
    auth_method1:depends( "encryption","sta-wpa")
    auth_method1:depends( "encryption","sta-wpa2")
    auth_method1:depends( "encryption","sta-wpa3")
    auth_method1:depends( "encryption","sta-wpa3-mixed")

    fake_user5 = s3:option(Value, "fake_user5", translate("fake_user"))
    fake_pass5 = s3:option(Value, "fake_password5", translate("fake_pass"))
    fake_user5.header_style = "display:none"
    fake_pass5.password = true
    fake_pass5.header_style = "display:none"

    auth_user_name1 = s3:option( Value, "identity", translate("User name"))
    auth_user_name1:depends( "encryption","sta-wpa")
    auth_user_name1:depends( "encryption","sta-wpa2")
    auth_user_name1:depends( "encryption","sta-wpa3")
    auth_user_name1:depends( "encryption","sta-wpa3-mixed")
    auth_user_name1.rmempty = true

    auth_password1 = s3:option( Value, "password", translate("Password"))
    auth_password1:depends( "encryption","sta-wpa")
    auth_password1:depends( "encryption","sta-wpa2")
    auth_password1:depends( "encryption","sta-wpa3")
    auth_password1:depends( "encryption","sta-wpa3-mixed")
    auth_password1.rmempty = true
    auth_password1.password = true

    -- DAE
    dae_enable      = s3:option( Flag, "dae_enable", translate('Dynamic Authorization'))
    dae_enable.rmempty = false
    dae_enable.enabled  = "1"
    dae_enable.disabled = "0"

    function dae_enable.write(self, section, value)
        Flag.write(self, section, value)
        if value == self.enabled then
            m.uci:set("firewall", section, "rule")
            m.uci:set("firewall", section, "enabled", "1")
            m.uci:set("firewall", section, "name", "DAE-Allowd")
            m.uci:set("firewall", section, "src", "wan")
            m.uci:set("firewall", section, "proto", "udp")
            m.uci:set("firewall", section, "target", "ACCEPT")
            m.uci:set("firewall", section, "family", "ipv4")
        else
            m.uci:delete("firewall", section)
        end
    end

    function dae_enable.remove(self, section)
        m.uci:delete("firewall", section)
    end

    dae_port        = s3:option( Value, "dae_port", translate('DAE Port'))

    dae_port:depends("dae_enable","1")
    dae_port.rmempty = false
    dae_port.datatype = "port"

    function dae_port.write(self, section, value)
        Value.write(self, section, value)
        if value then
            m.uci:set("firewall", section, "dest_port", value)
        end
    end

    dae_client      = s3:option( Value, "dae_client", translate('DAE Client'))

    dae_client:depends("dae_enable","1")
    dae_client.rmempty = true
    dae_client.datatype = "ip4addr"

    dae_secret      = s3:option( Value, "dae_secret", translate('DAE Secret'))
    dae_secret:depends("dae_enable","1")
    dae_secret.rmempty = true
    dae_secret.password = true
    dae_secret.datatype = "rangelength(1, 200)"

    -- Access Control List
    macfilter_enable1 = s3:option(Flag, "macfilter_enable", translate("Access Control List"))
    macfilter_enable1.rmempty = false
    macfilter_enable1.render = function(self, s3, scope)
        luci.template.render("cbi/valueheader", {section = s3, self = self})
        self.template = "cbi/fvalue_inline"
        AbstractValue.render(self, s3, nil)
    end

    function macfilter_enable1.write(self, section, value)
        local mode = luci.http.formvalue(radio_pre_form .. "mode")
        if not acn_util.is_enabled(value) then
            self.map.uci:delete("wireless", section, "macfilter")
        end

        if acn_util.is_sta_mode(mode) then
            -- Don't set this unless mode is ap
            m.uci:set("wireless", radio_device .. "_1", "macfilter_enable", "0")
        else
            Flag.write(self, section, value)
        end
    end

    macfilter_select1 = s3:option(ListValue, "macfilter", translate(""))
    macfilter_select1.empty_next = true
    macfilter_select1.cond_optional = true
    macfilter_select1.rmempty = true
    macfilter_select1.custom = "style='width:50px' "
    macfilter_select1:value("allow", translate("Allow all MACs on list"))
    macfilter_select1:value("deny", translate("Deny all MACs on list"))

    macfilter_select1.render =  function(self, s3, scope)
        luci.http.write('<div class="cbi-value" style="display:inline-block" id="cbi-wireless-' .. radio_device ..'_' .. j .. '-macfilter">')
        luci.http.write('<span class="inline-control-label">&nbsp;' .. translate("Policy")  .. "</span>")
        self.template = "cbi/lvalue_inline"
        AbstractValue.render(self, s3, nil)
        luci.http.write('</div>')
        luci.http.write('</div>')
        luci.template.render("cbi/valuefooter",  {section = s3, self = self})
    end

    function macfilter_select1.write(self, section, value)
        local macfilter_enabled = tostring(macfilter_enable1:formvalue(section)) == "1" and true or false
        if macfilter_enabled then
            ListValue.write(self, section, value)
        else
            self.map.uci:delete("wireless", section, "macfilter")
        end
    end

    function macfilter_select1.remove ( ) end

    maclist1 = s3:option(TextValue, "maclist", translate("Filtered MACs"))
    maclist1.help_text = translate("Enter one mac address and optional comment per line.")
                ..  ("<br/>") .. translate("Example: 00:12:34:56:78:9a John Smiths PC")
    maclist1.width = "300px"
    maclist1.rows = 10
    maclist1.cust_style = 'font-family:monospace !important;font-size:8pt'
    function maclist1.cfgvalue(self, section)
        local value   = m.uci:get("wireless", section, "maclist")
        local str_val = ""

        if value then
            local macs  = luci.util.split(value, ";")

            for i, value in ipairs(macs) do
                value = luci.util.trim(value)
                if value and #value >= 12 then

                    local mac, friendly       = value:match("(%w+)[:]*(.*)")
                    friendly = friendly or ""
                    mac = mac:sub(1,2)..":"..mac:sub(3,4)..":"..mac:sub(5,6)..":"..mac:sub(7,8)..":"..mac:sub(9,10)..":"..mac:sub(11,12)
                    str_val = str_val .. mac .. " " .. friendly .. "\n"
                end
            end
        end
        return str_val
    end

    function  maclist1.write(self, section, value)
        local val = tostring(maclist1:formvalue(section)) or ""
        local cfg_val = ""

        -- Strip out any quotes, semicolons, and colons from macs
        val = val:gsub("['\":;]", "") or ""
        local entries = luci.util.split(val, "\n") or {}
        for i,v in ipairs(entries) do
            v = luci.util.trim(v)
            local mac, friendly = v:match("(%w+)[ ]*(.*)")
            friendly = friendly or ''
            -- Limit size of comment/friendly name for this mac
            if #friendly > 20 then
                friendly = friendly:sub(1, 20)
            end

            if mac and #mac == 12 then
                cfg_val = cfg_val .. mac ..  ":" .. friendly .. ";"
            end
        end
        self.map.uci:set("wireless", section, "maclist", cfg_val)
    end

    function maclist1.remove ( ) end

    -- Access Control List END

    band_til1       = s3:option( DummyValue, "band_til", translate("Network Settings"))
    band_til1.template       = "cbi/plain_heading"
    band_til1.addl_classes   = "padding-bottom-10 padding-top-10"

    -- Only first SSID can be a client
    if s3.ssid_id == 1 then
        local client_inet_src_alert = s3:option(DummyValue, "sta_inet_src", "")
        client_inet_src_alert.template = "cbi/sta_inet_src_alert"
        client_inet_src_alert.logical_name = acn_util.wifi_section(rad_id, j)
        -- warn if sta is set as bridge to internet (#7102)
        local sta_non_wds_bridge_alert  = s3:option(DummyValue, "sta_non_wds_bridge_alert","")
        sta_non_wds_bridge_alert.template     = "cbi/sta_non_wds_bridge_alert"
        sta_non_wds_bridge_alert.logical_name = acn_util.wifi_section(rad_id, j)
    end

    -- Include vlans, always show net behavior so we can switch from Client mode to AP
    acn_util.add_net_access_section(s3, m, "wireless", acn_util.wifi_section(rad_id, j), true, true, is_controlled_by_cloud)

    local wan_bridge_iface_error = s3:option(DummyValue, "wan_bridge_iface_error", "")
    wan_bridge_iface_error.template = "cbi/wan_bridge_iface_error"
    wan_bridge_iface_error.name = acn_util.wifi_section(rad_id, j)

    CAPWAP_tunnel = s3:option(ListValue, "CAPWAP_tunnel", translate("CAPWAP Tunnel Interface"))
    CAPWAP_tunnel.rmempty    = false
    CAPWAP_tunnel:value("-1", translate("Disable"))
    CAPWAP_tunnel:value("0", translate("Complete tunnel"))
    CAPWAP_tunnel:value("1", translate("Split tunnel"))
    CAPWAP_tunnel.default = "-1"
    CAPWAP_tunnel.is_disabled   = true
    local tun_tamp = "-1"
    --CAPWAP_tunnel.custom = "style='height:20px' "
    function CAPWAP_tunnel.cfgvalue(self, section)
        --tun: 1, split_tun: 0 (complete tunnel)
        --tun: 1, split_tun: 1 (split tunnel)
        local tun = m.uci:get("wireless", section, "tun")
        local split_tun = m.uci:get("wireless", section, "split_tun")
        if tun == "1" then
            tun_tamp = split_tun;
        end

        return tun_tamp or "-1"
    end

    sz = s3:option(Value, "_s_zone_", translate("Service Zone"))
    sz.is_disabled = true
    sz:depends("CAPWAP_tunnel","0")
    sz:depends("CAPWAP_tunnel","1")

    function sz.cfgvalue(self, section)
        local tun_type = self.map:get(section, "split_tun")

        if tun_type == "0" then -- complete tunnel
            service_zone = self.map:get(section, "vid") or "0"
            sz_val = tonumber(service_zone)%1000 or "0"
        else                    -- split tunnel
            service_zone = self.map:get(section, "split_sz") or "0"
            sz_val = tonumber(service_zone)%1000 or "0"
        end

        sz_val_ret = "SZ" .. sz_val

        if sz_val_ret == "SZ0" then
            sz_val_ret = "Default"
        end

        return sz_val_ret
    end

    proxy_arp = s3:option(Flag, "proxy_arp", translate("Proxy ARP"))
    proxy_arp.is_disabled = true
    proxy_arp.rmempty = false
    proxy_arp:depends("network_behavior", "wan")
    proxy_arp:depends("network_behavior", "vlan")

    proxy_arp.write = function(self, section, value)
        local ap_isolate = luci.http.formvalue(vap_pre_form .. "isolate")

        if ap_isolate == "1" then
            Flag.write(self, section, value)
        else
            local network_behavior = luci.http.formvalue(vap_pre_form .. "network_behavior")
            if network_behavior == "wan" or network_behavior == "vlan" then
                Flag.write(self, section, "1")
            end
        end
    end

    limit_up_on1 = s3:option(Flag, "limit_up_enable", translate("Limit Upload"))
    limit_up1 = s3:option(Value, "limit_up", "")
    limit_down_on1 = s3:option(Flag, "limit_down_enable", translate("Limit Download"))
    limit_down1 = s3:option(Value, "limit_down", "")

    limit_up_on1.rmempty    = false
    limit_up_on1.checkbox   = true

    -- Range start must be set to > 0 for the required message to show up
    -- if not use depends(), it should not use datatype either.
    -- datatype will create cbi_validate_field, it will check when submit no matter element is disable or not
    -- limit_up1.datatype      = "range(256, 10048576)"
    -- limit_down1.datatype    = "range(256, 10048576)"

    --limit_up1:depends("limit_up_enable", "1")
    --limit_down1:depends("limit_down_enable", "1")

    limit_up1.empty_next    = true
    limit_up1.cond_optional = true
    limit_up1.optional      = false
    limit_up1.rmempty       = true
    limit_up1.custom        = "style='width:50px' "

    limit_up_on1.render = function(self, s3, scope)
        luci.template.render("cbi/valueheader", {section = s3, self = self})
        self.template = "cbi/fvalue_inline"
        AbstractValue.render(self, s3, nil)
    end

    limit_up1.render =  function(self, s3, scope)
        luci.http.write('<div class="cbi-value" style="display:inline-block;margin-bottom:0px" id="cbi-wireless-' .. radio_device .. '_' .. j .. '-limit_up">')
        luci.http.write('<span class="inline-control-label">&nbsp;' .. translate("Limit rate to")  .. "&nbsp;</span>")
        self.template = "cbi/value_inline"
        AbstractValue.render(self, s3, nil)
        luci.http.write('<span class="inline-control-label">&nbsp;' .. translate("kbps")  .. "&nbsp;</span>")
        luci.http.write('</div>')
        luci.http.write('</div>')
        luci.template.render("cbi/valuefooter",  {section = s3, self = self})
    end

    limit_down_on1.rmempty      = false
    limit_down_on1.checkbox     = true
    limit_down1.empty_next      = true
    limit_down1.cond_optional   = true
    limit_down1.optional        = false
    limit_down1.rmempty         = true
    limit_down1.custom          = "style='width:50px' "

    limit_down_on1.render = function(self, s3, scope)
        luci.template.render("cbi/valueheader", {section = s3, self = self})
        self.template = "cbi/fvalue_inline"
        AbstractValue.render(self, s3, nil)
    end

    limit_down1.render =  function(self, s3, scope)
        luci.http.write('<div class="cbi-value" style="display:inline-block;margin-bottom:0px" id="cbi-wireless-' .. radio_device .. '_' .. j .. '-limit_down">')
        luci.http.write('<span class="inline-control-label">&nbsp;' .. translate("Limit rate to")  .. "&nbsp;</span>")
        self.template = "cbi/value_inline"

        AbstractValue.render(self, s3, nil)

        luci.http.write('<span class="inline-control-label">&nbsp;' .. translate("kbps")  .. "</span>")
        luci.http.write('</div>')
        luci.http.write('</div>')
        luci.template.render("cbi/valuefooter",  {section = s3, self = self})
    end

    cloud_aaa_on = s3:option(Flag, "cloud_aaa", translate("Authentication"))
    cloud_aaa_on.rmempty = false

    if is_controlled_by_cloud then
        cloud_aaa_on:depends("network_behavior", "wan")
        cloud_aaa_on:depends("network_behavior", "route")
        cloud_aaa_on:depends("network_behavior", "vlan")
    end

    if root_user == false and msp_disabled == false then
        CAPWAP_tunnel.header_style      = "display:none"
        limit_up_on1.header_style       = "display:none"
        limit_down_on1.header_style     = "display:none"
        cloud_aaa_on.header_style       = "display:none"
        proxy_arp.header_style          = "display:none"
    end

    -- OpenRoaming start
    hotspot_2_tile       = s3:option( DummyValue, "hotspot_2_0_tile", translate("OpenRoaming"))
    hotspot_2_tile.template       = "cbi/plain_heading"
    hotspot_2_tile.addl_classes   = "padding-bottom-10 padding-top-10"

    hs20 = s3:option(Flag, "hs20", translate("OpenRoaming"))
    hs20.help_tip = translate("Using Passpoint (Hotspot 2.0) technology.")
    hs20.rmempty = false
    hs20.is_disabled = true

    hs20_profile = s3:option(ListValue, "hs20_profile", translate("OpenRoaming Profile"))
    hs20_profile:depends("hs20", "1")
    local profile_list = acn_util.hs20_profile(m.uci)

    if #profile_list == 0 then
        hs20_profile:value("", translate("Select a profile"))
    end

    for i, profile_name in ipairs(profile_list) do
        hs20_profile:value(profile_name, profile_name)
    end

    hs20_profile_config = s3:option(DummyValue, "_hs20_profile", translate("OpenRoaming Settings"))
    hs20_profile_config:depends("hs20", "1")
    hs20_profile_config.template = "cbi/hs20_profile_btn"
    hs20_profile_config.profile_count =  #profile_list
    -- OpenRoaming end

    function fake_user3.write(self, section)
        return
    end

    function fake_pass3.write(self, section)
        return
    end

    function fake_user4.write(self, section)
        return
    end

    function fake_pass4.write(self, section)
        return
    end

    function fake_user5.write(self, section)
        return
    end

    function fake_pass5.write(self, section)
        return
    end

    --=========================================================================================
    function fake_user2.write(self, section)
        return
    end

    function fake_pass2.write(self, section)
        return
    end

    function fake_user6.write(self, section)
        return
    end

    function fake_pass6.write(self, section)
        return
    end
end

local mode = m.uci:get("wireless", radio_device, "mode")

if not fetch_ssid_id then
  for j=1, tonumber(max_ssids) do
    acn_util.add_hotspot_wallgarden_div(acn_util.wifi_section(rad_id, j), m)
  end
end

if not fetch_ssid_id then

    local dummy = s:option(DummyValue, "ssid_title", translate("General Settings"))

    dummy.template = "cbi/ssid_tabs"
    dummy.heading_id = "wireless_title"
    dummy.title = translate("Wireless Networks")
    dummy.total_tabs   = total_created_ssids
    dummy.max = max_ssids
    dummy.mode  = mode
    dummy.section = radio_device
    dummy.ssid_only_one = ssid_only_one
    dummy.is_controlled_by_cloud = is_controlled_by_cloud
end

if is_postback then
    for j=1, tonumber(max_ssids) do
        add_ssid_section(j, m, rad_id, false)
    end
end

if not is_postback and fetch_ssid_id then
    -- Fetching single SSID
    add_ssid_section(fetch_ssid_id, m, rad_id, true)
end

-- ===== END SSID SECTION

if not fetch_ssid_id then
    local s2
    if root_user or msp_disabled then
        s2 = m:section(NamedSection, wdev:name(), "wifi-device", translate("Advanced Radio Settings"))
    else
        s2 = m:section(NamedSection, wdev:name(), "wifi-device")
    end
    s2.addremove = false
    s2.sub_title_class = true
    s2.config = "advanced"

    txpower = s2:option(ListValue, "txpower", translate("Tx Power"))
    txpower.rmempty = false

    for i=1,tx_power_max do
        mw=0
        mw=math.floor(10^(i / 10))
        txpower:value(i, '%d dBm (%d mW)' %{ i, mw })
    end

    if root_user == false and msp_disabled == false then
        txpower.header_style = "display:none"
    end

    -- Support SGI
    sgi = s2:option(Flag , "sgi", translate("SGI"))
    sgi.rmempty = false
    sgi:depends("hwmode", "11a")
    sgi:depends("hwmode", "11na")
    sgi:depends("hwmode", "11ac")
    sgi:depends("hwmode", "11ng")

    function sgi.write(self, section, value)
        acn_uci:set("wireless", section, "sgi", value)
        acn_uci:set("wireless", section, "short_gi_20", value)
        acn_uci:set("wireless", section, "short_gi_40", value)
        acn_uci:set("wireless", section, "short_gi_80", value)
    end

    radio_band.default = "11ac"

    radio_mode.override_values   = true
    radio_status.rmempty         = false
    radio_mode:value("ap-wds", translate("Access Point (Auto-WDS)"))
    radio_mode:value("sta", translate("Client"))

    htmode:value("20", translate("20MHz"))
    htmode:value("40", translate("40MHz"))

    if is_5g then
        radio_band:value("11a", "802.11a")
        radio_band:value("11na", "802.11a+n")
        radio_band:value("11ac", "802.11ac+a+n")
        radio_band:value("11axa", "802.11ax")

        -- This is handled in wifi.js, but needed for postback validation I think
        htmode:value("80", translate("80MHz"))
        if is_EAP104 and country_code ~= "IN" then
            htmode:value("160", translate("160MHz"))
        end
    else
        radio_band:value("11ng", "802.11b+g+n")
        radio_band:value("11axg", "802.11ax")
    end

    local _channel_value = posted_channel or channel_list_cfg or channel_cfg
    _channel_value = _channel_value:gsub(",", "-")

    radio_channel:value("auto", translate("Auto"))
    radio_channel:value(_channel_value, translate("Specific Frequency"))
    if freq_json then
        for idx, cell in ipairs(freq_json) do
          radio_channel:value(cell.channel, cell.channel .. " (" .. cell.mhz .. " MHz)")
        end
    end

    if show_bandsteering then
        function bandsteering.cfgvalue(self, section)
            local val
                m.uci:foreach("usteer", "usteer", function (s)
                     val = m.uci:get("usteer", s['.name'], "enabled") or "0"
                end)

            return val
        end

        function bandsteering.write(self, section, value)
            if value ~= "0" then
                local ssid_list = {}

                m.uci:foreach("usteer", "usteer", function (s)
                    m.uci:set("usteer", s['.name'], "enabled", "1")
                    m.uci:set("usteer", s['.name'], "network", "wan")
                    m.uci:set("usteer", s['.name'], "min_snr", "-75")
                    m.uci:set("usteer", s['.name'], "assoc_steering", "1")
                    m.uci:set("usteer", s['.name'], "min_connect_snr", "-70")
                    m.uci:set("usteer", s['.name'], "roam_scan_snr", "-85")

                    for k=1, tonumber(total_created_ssids) do
                        ssid_list[k] = luci.http.formvalue("cbid.wireless." .. radio_device .. "_" .. k .. ".ssid")
                    end

                    m.uci:set_list("usteer", s['.name'], "ssid_list", ssid_list)

                end)
            else
                m.uci:foreach("usteer", "usteer", function (s)
                    m.uci:set("usteer", s['.name'], "enabled", "0")
                    m.uci:delete("usteer", s['.name'], "network")
                    m.uci:delete("usteer", s['.name'], "min_snr")
                    m.uci:delete("usteer", s['.name'], "assoc_steering")
                    m.uci:delete("usteer", s['.name'], "min_connect_snr")
                    m.uci:delete("usteer", s['.name'], "roam_scan_snr")
                    m.uci:delete("usteer", s['.name'], "ssid_list")
                end)
            end

            m.uci:save("usteer")
        end
    end

    function airtime_fairness.cfgvalue(self, section)
        local val
        m.uci:foreach("atfpolicy", "defaults", function (s)
             val = m.uci:get("atfpolicy", s['.name'], "enabled")
        end)

        if val ~= nil then
            return val
        else
            return "0"
        end
    end

    function airtime_fairness.write(self, section, value)
        if value == self.enabled then
            m.uci:foreach("atfpolicy", "defaults", function (s)
                m.uci:set("atfpolicy", s['.name'], "enabled", "1")
                m.uci:set("atfpolicy", s['.name'], "vo_queue_weight", "4")
                m.uci:set("atfpolicy", s['.name'], "update_pkt_threshold", "100")
                m.uci:set("atfpolicy", s['.name'], "bulk_percent_thresh", "50")
                m.uci:set("atfpolicy", s['.name'], "prio_percent_thresh", "30")
                m.uci:set("atfpolicy", s['.name'], "weight_normal", "256")
                m.uci:set("atfpolicy", s['.name'], "weight_bulk", "128")
                m.uci:set("atfpolicy", s['.name'], "weight_prio", "384")
            end)
        else
            m.uci:foreach("atfpolicy", "defaults", function (s)
                m.uci:set("atfpolicy", s['.name'], "enabled", "0")
                m.uci:delete("atfpolicy", s['.name'], "vo_queue_weight")
                m.uci:delete("atfpolicy", s['.name'], "update_pkt_threshold")
                m.uci:delete("atfpolicy", s['.name'], "bulk_percent_thresh")
                m.uci:delete("atfpolicy", s['.name'], "prio_percent_thresh")
                m.uci:delete("atfpolicy", s['.name'], "weight_normal")
                m.uci:delete("atfpolicy", s['.name'], "weight_bulk")
                m.uci:delete("atfpolicy", s['.name'], "weight_prio")
            end)
        end

        m.uci:save("atfpolicy")
    end

    function radio_status.write(self, section, value)
        if value == self.enabled then
            m.uci:set("wireless", section, "disabled", "0")
        else
            m.uci:set("wireless", section, "disabled", "1")
        end
        network_behavior.write(self, radio_device .. "_1", luci.http.formvalue("cbid.wireless." .. radio_device .. "_1.network_behavior"))
        acn_util.handle_wan_type(m.uci)
    end

    function radio_status.cfgvalue(self, section)
        local sta = ListValue.cfgvalue(self, section)
        if sta == "0" then
            return "1"
        else
            return "0"
        end
    end

    function radio_band.write(self, section, value)
        local ht_val = luci.http.formvalue(radio_pre_form .. "htmode")
        m.uci:set("wireless", section, "hwmode", value)
        set_htmode(m, section, ht_val)
    end

    if is_5g then
        function radio_band.cfgvalue(self, section)
            local mode = ListValue.cfgvalue(self, section)
            local cfg_htmode  = m.uci:get("wireless", section, "htmode")
            return mode
        end
    end

    -- XXX TODO: fix wds
    function radio_mode.write(self, section, value)
        local is_ap = true

        if value == "ap-wds" then
            ListValue.write(self, section, "ap")
            m.uci:set("wireless", section, "wds", 1)
            m.uci:set("wireless", radio_device .. "_1", "wds", 1)
            m.uci:set("wireless", radio_device .. "_1", "mode", "ap")
        elseif value == "sta-wds" then
            is_ap = false
            ListValue.write(self, section, "sta")
            m.uci:set("wireless", section, "wds", 1)
            m.uci:set("wireless", radio_device .. "_1", "wds", 1)
            m.uci:set("wireless", radio_device .. "_1", "mode", "sta")
        elseif value == "sta" then
            is_ap = false
            ListValue.write(self, section, value)
            m.uci:delete("wireless", section, "wds")
            m.uci:set("wireless", radio_device .. "_1", "mode", value)
            m.uci:delete("wireless", radio_device .. "_1", "wds")
        else
            is_ap = true
            ListValue.write(self, section, value)
            m.uci:set("wireless", radio_device .. "_1", "mode", value)
            m.uci:delete("wireless", section, "wds")
            m.uci:delete("wireless", radio_device .. "_1", "wds")
        end

        if not is_ap then
            for k=2, tonumber(ssid_num) do
                m.uci:delete("wireless", radio_device .. "_" .. k)
            end

            if show_bandsteering then
                -- Turn off bandsteering if switch to client mode
                local has_section = self.map.uci:get("wireless", "global")

                if not has_section then
                    self.map.uci:set("wireless", "global", "settings")
                end

                self.map.uci:set("wireless", "global", "bandsteering", "0")
            end
            self.map.uci:delete("wireless", section, "channels")
        end

        -- Changing from client -> AP mode requires some more processing from
        -- network behavior (network_behavior.write may not be called if radio.network was
        -- not changed)
        network_behavior.write(self, radio_device .. "_1", luci.http.formvalue("cbid.wireless." .. radio_device .. "_1.network_behavior"))
    end

    function radio_mode.cfgvalue(self, section)
        local mode = ListValue.cfgvalue(self, section)
        local wds  = m.uci:get("wireless", section, "wds") == "1"

        if mode == "ap" and wds then
            return "ap-wds"
        elseif mode == "sta" and wds then
            return "sta-wds"
    else
            return mode
        end
    end

    function htmode.cfgvalue(self, section)
        local _htmode = ListValue.cfgvalue(self, section)
        local rtk_priv  = m.uci:get("wireless", section, "rtk_priv_bw")

        if rtk_priv == "5M" then
            return "5"
        elseif rtk_priv == "10M" then
            return "10"
        elseif _htmode:find("160") then
            return "160"
        elseif _htmode:find("80") then
            return "80"
        elseif _htmode:find("40") then
            return "40"
        elseif _htmode:find("2160") then
            return "2160"
        else
            return "20"
        end
    end

    function radio_channel.cfgvalue(self, section)
        local val = ListValue.cfgvalue(self, section)
        if val == "auto" then
            local channel_list = m.uci:get("wireless", section , "channels")
            if channel_list then
                val = channel_list:gsub(",", "-")
            end
        end

        return val
    end

    function radio_channel.write(self, section, value)
        local mode_cfg = m.uci:get("wireless", radio_device, "mode")
        if value == "unknown" or value == "auto" or not mode_cfg == "ap" then
            --select all channels
            ListValue.write(self, section, "auto")
            m.uci:set("wireless", section, "channels", value)
        else
            if value:find("%-") then
                -- select more than one channel
                value = value:gsub("-", ",")

                -- if we use fake iw_reg_get
                -- because default channel list is incorrect, we can't use auto channel
                -- because of setting all channels to behave like auto all channel
                -- need another config to present auto all channel
                if value:find("all") then
                    value = value:gsub('all,','')
                end
                ListValue.write(self, section, "auto")
                m.uci:set("wireless", section, "channels", value)
            else
                --select one channel only
                ListValue.write(self, section, value)
                m.uci:delete("wireless", section, "channels")
            end
        end
    end

    function wme_table.write(self, section, value)
        value = value:gsub(",", " ")
        local cnt = 0
        for v in value:gmatch("%w+ %w+ %w+ %w+ %w+ %w+ %w+ %w+") do
            m.uci:set("wireless", section, "wme_" .. tostring(cnt), v)
            cnt = cnt + 1
        end
    end

    function set_htmode(m, section, htmode)
        local check_hwmode = (luci.http.formvalue(radio_pre_form .. "hwmode"))
        local pre_htmode = ""

        if is_2g then
            if htmode == "40" then
                m.uci:set("wireless", section, "noscan", "1")
                m.uci:set("wireless", section, "ht_coex", "0")
            elseif htmode == "20" then
                m.uci:set("wireless", section, "noscan", "0")
                m.uci:set("wireless", section, "ht_coex", "0")
            end
        end
        -- 2.4g: 11ng, 11axg
        --   5g:  11a, 11na, 11ac, 11axa
        if check_hwmode:find("11ax") then
            pre_htmode = "HE"
        elseif check_hwmode:find("11ac") then
            pre_htmode = "VHT"
        elseif check_hwmode:find("11ng") or check_hwmode:find("11na") then
            pre_htmode = "HT"
        end

        htmode = pre_htmode .. htmode
        if htmode then
            m.uci:set("wireless", section, "htmode", htmode)
        end

        -- rtk_priv_bw is only used for 5 and 10 M now
        m.uci:set("wireless", section, "rtk_priv_bw", "")
    end

    function htmode.write(self, section, value)
        set_htmode(m, section, value)
    end

    function txpower.cfgvalue(self, section)
        local val
        if Value.cfgvalue(self, section) then
            val = Value.cfgvalue(self, section)
        else
            val = tx_power_cur or tx_power_max
        end

        -- limit tx power not higher than max
        if tonumber(val) > tonumber(tx_power_max) then
            val = tx_power_max
        end

        return val
    end
end

return m
