
local io = require "io"
local json = require "cjson.safe"
local fs = require "nixio.fs"
local acn_util = require "luci.acn.util"
local luci_util = (luci and luci.util) or require("luci.util")

local acn_status = {}
local uci = require "luci.model.uci".cursor()

-- I don't really understand when this stuff is loaded...
if not product then
    product = require "luci.acn.product"
end

function acn_status.format_uptime(secs)
    local nxo = require "nixio"

    -- stolen from other parts of luci
    local suff = {"min", "h", "d"}
    local mins = 0
    local hour = 0
    local days = 0

    secs = nxo.bit.div(secs, 1)
    if secs > 60 then
        mins = nxo.bit.div(secs, 60)
        secs = secs % 60
    end

    if mins > 60 then
        hour = nxo.bit.div(mins, 60)
        mins = mins % 60
    end

    if hour > 24 then
        days = nxo.bit.div(hour, 24)
        hour = hour % 24
    end

    if days > 0 then
        return string.format("%.0fd %02.0fh %02.0fmin", days, hour, mins)
    else
        return string.format("%02.0fh %02.0fmin", hour, mins)
    end

end

function acn_status.get_wan_device()
    local wan_status = luci_util.ubus("network.interface.wan", "status", {}) or {}
    if wan_status then
        return wan_status.device
    end

    return nil
end

function acn_status.eth_status()
    local res = {}
    local eth_stats = luci_util.ubus("network.device", "status", {}) or {}
    local is_eap104 = product.is_EAP104()
    local switch_stats = nil

    if is_eap104 then
        switch_stats = luci_util.ubus("luci", "getSwconfigPortState", {switch = "switch1"})
    end

    for i=0, product.num_eth_ports -1 do
        local status = { linked = false }
        local eth =  product.eth(i)
        local interface_stat = nil

        if eth_stats and eth_stats[eth.logical_name] then
            interface_stat = eth_stats[eth.logical_name]
        end

        if interface_stat then
            if is_eap104 and (interface_stat.type == "VLAN" or interface_stat.type == "8021q") and switch_stats then
                for idx, port in ipairs(switch_stats.result) do
                    if tonumber(eth.port_id) == port.port then
                        status.linked = port.link
                        status.enabled = interface_stat.up
                        status.speed = port.speed or 0
                        status.full_duplex = port.duplex
                        status.friendly = status.linked and translate("Linked at ") .. translate(status.speed .. "M/" .. (status.full_duplex and "Full" or "Half") .. " duplex") or ""
                        if port.auto == false then
                            status.friendly = status.friendly .. ", " .. translate("manual")
                        end
                    end
                end
            else
                status.linked = interface_stat.carrier
                status.enabled = interface_stat.up
                status.speed = interface_stat.speed:match("([%d%.]+)") or 0
                status.full_duplex = interface_stat.speed:match("([%a])") == "F"
                status.friendly = status.linked and translate("Linked at ") .. translate(status.speed .. "M/" .. (status.full_duplex and "Full" or "Half") .. " duplex") or ""
                if interface_stat.autoneg == false then
                    status.friendly = status.friendly .. ", " .. translate("manual")
                end
            end
        end

        res[eth.logical_name] = status

        if product.supports_3g() then
             -- 3G/LTE connection info
            local wan_inet_src = uci:get("network", "wan", "inet_src")
            local logical_name = product.dev_name_3g or "3g-wan"
            if wan_inet_src == "wwan0" then
                logical_name = wan_inet_src
            end
            linked = acn_util.detected_dongle()
            local status = {  linked = linked}
            res[logical_name] = status
        end
    end
    return res
end

function acn_status.mesh_status()
    local res = {}
    local status = { linked = false, connected = false }
    local mesh =  product.dev_name_mesh
    local interface_stat = nil
    local link_supported = {}

    local eth_stats = luci_util.ubus("network.device", "status", {}) or {}
    local mesh_connect_stats = luci_util.ubus("iwinfo", "assoclist", { device = mesh }) or {}

    if eth_stats and eth_stats[mesh] then
        interface_stat = eth_stats[mesh]
    end

    if interface_stat then
        status.linked = interface_stat.carrier
        status.enabled = interface_stat.up
    end

    if mesh_connect_stats["results"] and #mesh_connect_stats["results"] > 0 then
        status.connected = true
    end

    res[mesh] = status

    return res
end

function acn_status.version()
    local output = fs.readfile('/etc/edgecore_release') or ""
    if output then
        local release = output:match([[DISTRIB_RELEASE='([^']+)]])
        local revision = output:match([[DISTRIB_REVISION='([^']+)]])

        output = release .. "-" .. revision
    end
    return output
end

function acn_status.chan_bw(ifname)
    local cmd = "iw " .. ifname .. " info"
    local out = nil

    if (product.wifi_prefix and ifname:find(product.wifi_prefix)) or (product.dev_name_mesh and ifname:find(product.dev_name_mesh)) then
        out = luci.sys.exec(cmd)
    end

    if not out then 
        return 'N/A'
    end

    local chan_bw = out:match(".*width: (%d+)")

    if not chan_bw then
        return '20' -- 11A or 11G always have chan bw 20MHz
    end

    return chan_bw
end

function acn_status.client_link_info(ifname)

    local res = {} -- will be returned from function

    local rssi_percentage  =  0
    local rssi_str, rssi_class = ""
    local rssi_values = {}
    local snr, snr_str = "", ""
    local snr_values = {}
    local rssi
    local rssi_offset
    res.state = "down"

    local ntm = require "luci.model.network".init()
    local net = ntm:get_wifinet(ifname)

    if net then


      res.state = "up"
      rssi_offset =  product.rssi_offset or -100
      local rssi_max = -255
      rssi = 0

      --for idx, sig in ipairs(net:signal()) do
      sig = net:signal()

        sig = tonumber(sig)
        if rssi_max < sig then 
          rssi_max = sig
        end
        rssi = rssi + sig
      --end
      rssi = tonumber(string.format("%.0f", rssi / 1))
    end

    if rssi then
        snr = rssi - rssi_offset
        if rssi > -30 then
            rssi_class = "bar-danger"
        elseif rssi <= -30 and rssi >= -60 then
            rssi_class = "bar-success"
        elseif rssi <= -70 and rssi >= -80 then
            rssi_class = "bar-warning"
        elseif rssi <= -80 then
            rssi_class = "bar-danger"
        end

        rssi_percentage = math.ceil(math.abs((90 + rssi) / (-90 - -30))*100)

        if rssi <= -90 then 
          rssi_percentage = 0
        elseif rssi >= -30 then 
          rssi_percentage = 100
        end
        res.rssi_str = rssi_str
        res.rssi_percentage = rssi_percentage
        res.rssi_class = rssi_class
        res.rssi = rssi
        res.rssi_offset = rssi_offset
    end
    return res
end


--===================================================================================================
-- Convert ieee mode returned by realtek to more friendly version
-- Example: "ANAC" -> "802.11 a/n/ac"
--===================================================================================================
function acn_status.clean_ieee_mode(mode_str)
    local return_val = ""
    if not mode_str then return nil end

    local mode = mode_str:lower()
    local modes = {}

    if mode:match("11(.*)") then
      mode = mode:gsub("1", "")
    end

    if mode:match("ac") then
        modes[#modes + 1] = "ac"
        mode = mode:gsub("ac", "")
    end

    for i = 1, #mode do
        modes[#modes + 1] = mode:sub(i,i)
    end

    return_val = "802.11 " .. table.concat(modes, "/")
    if return_val == "802.11 a/x/a" then
        return_val = "802.11 ax/a"
    end

    if return_val == "802.11 a/x/g" then
        return_val = "802.11 ax/g"
    end

    return return_val
end

--===================================================================================================
-- Convert datarate returned by realtek to a numeric value only
-- Example: "MCS15 130" -> 130
--===================================================================================================
function acn_status.clean_datarate(rate_str)

    if not rate_str then return 0 end

    -- Handle 11n MCS Rates
    local mcs, rate = rate_str:match("(MCS%d+)[ ]+([%d%p]+)")

    if not mcs then
        -- Handle 11ac data rates
         rate = rate_str:match("VHT %w+%s+(%d+)")

        if not rate then
            -- Handle plain data rates
            rate = rate_str:match("([%d%p]+)")
        end
    end

    return rate, mcs
end

function acn_status.wifi_status(ifname)

  local status = {}
  local output = fs.readfile('/var/run/stats/wireless.json') or ""
  local json_tab = json.decode(output)

  if not ifname or not json_tab then
    return nil, "Cannot find radio statistics"
  end
  if not json_tab.vaps then
    return nil, "Vaps stats not found" ..tostring(ifname)
  end

  for idx, _val in ipairs(json_tab.vaps) do
    if ifname == _val.name then
      status.radio = _val.radio
    end
  end

  if not status.radio then
   return nil, "Radio status not found"
  end

  status.ieee_mode = json_tab.radios.dev[status.radio].protocol or "N/A"
  status.mac = json_tab.radios.dev[status.radio].mac or "N/A"
  return status
end

function acn_status.connected_clients(ifname)
    local clients = {}

    -- hostname and ip address
    local dhcplist_json = luci_util.ubus("luci", "getECDhcpList", {}) or {}
    -- wifi interface list
    local wlan_iface_json = luci_util.ubus("iwinfo", "devices", {}) or {}

    local _section = acn_util.ifname_to_logical(ifname) -- section = radioX_Y
    local dynamic_vlan_val = uci:get("wireless", _section, "dynamic_vlan")
    local is_dynamic_vlan = (dynamic_vlan_val and dynamic_vlan_val ~= "0")

    for i, wlan_iface in pairs(wlan_iface_json["devices"]) do
        local new_ifname = ifname
        if is_dynamic_vlan then
            local pre_wlan_iface = wlan_iface:match('wlan%d%-%d+') or wlan_iface:match('wlan%d+')

            if pre_wlan_iface == ifname and (wlan_iface:match('wlan%d+%.(%d+)') or wlan_iface:match('wlan%d%-%d+%.(%d+)')) then
                new_ifname = wlan_iface
            end
        end
        ifname = new_ifname

        if wlan_iface == ifname or (is_dynamic_vlan and (wlan_iface:match('-') and ifname:match('-') and (wlan_iface:match('wlan%d%-%d+') == ifname or wlan_iface:match('wlan%d%-%d+') == ifname:match('wlan%d%-%d+')) or (wlan_iface:match('(.+)%.') and ifname:match('(.+)%.') and wlan_iface:match('(.+)%.') == ifname:match('(.+)%.')))) then
            local output = luci_util.exec('iw ' .. wlan_iface .. ' station dump')
            if output then
                local status = {}

                -- traverse every line of output
                for line in output:gmatch("([^\n]*)\n?") do
                    if line:match('^Station') then
                        local value = luci_util.split(line, " ")
                        status = {}
                        status["mac"] = value[2]

                        if dhcplist_json and dhcplist_json[value[2]:upper()] then
                            status["name"] = dhcplist_json[value[2]:upper()]["name"] or "N/A"
                            status["ip"] = dhcplist_json[value[2]:upper()]["ipv4"] or "N/A"
                        else
                            status["name"] = "N/A"
                            status["ip"] = "N/A"
                        end
                    else
                        local value = luci_util.split(line, ":")
                        local res =""

                        if value[1]:find('Usage') then
                            -- vap doesn't have station info
                            break
                        end

                        if value[1]:find('inactive time') then
                            if value[2] then
                                res = value[2]:match("([+-]?%d+)") or "N/A"
                            end
                            status["idleTime"] = tostring(res)
                        end

                        if value[1]:find('rx bytes') then
                            if value[2] then
                                res = value[2]:match("([+-]?%d+)") or "N/A"
                            end
                            status["rx_bytes"] = tostring(res)
                        end

                        if value[1]:find('rx packets') then
                            if value[2] then
                                res = value[2]:match("([+-]?%d+)") or "N/A"
                            end
                            status["rx_packets"] = tostring(res)
                        end

                        if value[1]:find('tx bytes') then
                            if value[2] then
                                res = value[2]:match("([+-]?%d+)") or "N/A"
                            end
                            status["tx_bytes"] = tostring(res)
                        end

                        if value[1]:find('tx packets') then
                            if value[2] then
                                res = value[2]:match("([+-]?%d+)") or "N/A"
                            end
                            status["tx_packets"] = tostring(res)
                        end

                        if value[1]:find('signal') then
                            if value[2] then
                                res = value[2]:match("([+-]?%d+)") or "N/A"
                            end
                            status["signal"] = tostring(res)
                        end

                        if value[1]:find('tx bitrate') then
                            if value[2] then
                                res = value[2]:match("([+-]?%d+)") or "N/A"
                            end
                            status["tx_rate"] = tostring(res)
                        end

                        if value[1]:find('rx bitrate') then
                            if value[2] then
                                res = value[2]:match("([+-]?%d+)") or "N/A"
                            end
                            status["rx_rate"] = tostring(res)
                        end

                        if value[1]:find('connected time') then
                            if value[2] then
                                res = value[2]:match("([+-]?%d+)") or "N/A"
                            end
                            status["duration"] = tostring(res)

                            clients[#clients+1] = status

                        end
                        --end of client's status
                    end
                    --end of output line parse
                end
                --end of if output
            end
            --end of device match ifname
        end
        --end of for device list
    end

    return clients
end

return acn_status
