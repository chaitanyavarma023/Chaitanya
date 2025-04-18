--- ACN utility functions.
local fs = require "nixio.fs"
local json = require "cjson.safe"
local product = require "luci.acn.product"
local iwinfo = require "iwinfo"

local acn_util = {}
local uci = nil
local uci_state = nil
local WIFI_JSON = "/var/run/stats/wireless.json"
local pre_vap_name = "radio"

local has_hotspot = fs.access("/usr/sbin/chilli")
local has_ipv6 = fs.access("/proc/net/ipv6_route") and fs.access("/usr/sbin/ip6tables")

require("luci.i18n")
translate = luci.i18n.translate

-- Network names
mgmt_network = "managementvlan" -- (Mgmt vlan)
mgmt_vlan_network = mgmt_network
mgmt_vlan_network6 = mgmt_network .. "6"
wan_vlan_network = "wanvlan"
wan_vlan_network6 = "wanvlan6"
hotspot_network = "hotspot"
hotspot_tunnel = "hotspot_tunnel"
local_network = "local"
vpn_network = "vpn"
guest_network = "guest"
wan_network = "wan"
wds_vlan_link = "wds"
lan_network = "lan"
loopback_network = "loopback"
cf_network = "cf"
security_network = "security"
ipv6_network = "wan6"
ipoe_network = "ipoe"
bat0_network = "bat0"
bat0_mesh0_network = "bat0_hardif_mesh0"

-- Hidden network names
local hidden_lans = {}
hidden_lans[mgmt_network] = 1
hidden_lans[mgmt_vlan_network6] = 1
hidden_lans[wan_vlan_network] = 1
hidden_lans[wan_vlan_network6] = 1
hidden_lans[hotspot_network] = 1
hidden_lans[hotspot_tunnel] = 1
hidden_lans[wan_network] = 1
hidden_lans[loopback_network] = 1
hidden_lans[cf_network] = 1
hidden_lans[security_network] = 1
hidden_lans[ipv6_network] = 1
hidden_lans[ipoe_network] = 1
hidden_lans[bat0_network] = 1
hidden_lans[bat0_mesh0_network] = 1

function acn_util.log_to_file(file_name, msg)
    local fd = io.open(file_name, "a+")

    if fd then
        fd:write(msg .. "\n")
        fd:close()
    end
end

function acn_util.read_file(file_name)
    local fh, err = io.open(file_name, "r")

    if fh then
        local result = fh:read("*a")
        fh:close()

        if result then
            return result
        else
            return result, "Failed to read file content"
        end
    end

    return nil, err
end

function acn_util.read_json(file_name)
    local data, err = acn_util.read_file(file_name)
    if not data then
        return data, err
    end
    return json.decode(data)
end

-- Only load uci cursor once (maybe the original cursor() does that already)
function acn_util.cursor()
    if uci == nil then
        uci = require "luci.model.uci".cursor()
    end
    return uci
end

-- Only load uci cursor once (maybe the original cursor() does that already)
function acn_util.cursor_state()
    if uci_state == nil then
        uci_state = require "luci.model.uci".cursor_state()
    end

    return uci_state
end

-- We are going to assume here that the wireless radio VAPs gave static interface names
-- E.g. radio0_1 is always wlan0, radio0_2 is always wlan0-1, etc...
-- (can always change later)
function acn_util.wifi_iface_name(radio_id, vap_id)
    local iface = product.wifi_prefix  .. radio_id
    if tonumber(vap_id) > 1  then
        iface = string.format("%s%d", iface, (vap_id-1))
    end
    return iface
end

function acn_util.wifi_section(radio_id, vap_id)
    local r_id = radio_id
    local v_id = vap_id
    if #tostring(radio_id) > 1 then
        r_id = radio_id:sub(1,1)
        v_id = tonumber(radio_id:sub(2,2))+1
    end
    return product.radio(r_id).device .. "_" .. v_id
end

function acn_util.radio_section(radio_id)
    return product.radio(radio_id).device
end

function acn_util.shorten_str(str, max_len, ellipses)
    max_len = max_len or 10

    if ellipses == nil then
        ellipses = true
    end

    if not str then
        return ''
    end

    if #str > max_len then
        local ret = str:sub(1, max_len)
        if ellipses then ret = ret .. "..." end
        return ret
    else
        return str
    end

end

--[[==========================================================================
     Determine if logical name is an ethernet port, and if so, return id
]]
function acn_util.is_eth(logical)

    if logical == nil then return false end

    local nports = product.num_eth_ports
    for i=0, nports-1 do
        local eth = product.eth(i)
        if eth and (eth['logical_name'] == logical or eth['dev_name'] == logical) then
            return true, i
        end
    end

    return false, nil
end

--- Determines if specified port is SFP port
-- @param eth_id ethernet port ID (X form 'ethX')
-- @return `true` when specified port is SFP
function acn_util.is_sfp_port(eth_id)
    local eth = product.eth(eth_id)
    return eth and eth["type"] == "SFP"
end

--[[==========================================================================
     Determine if logical name is an wifi port, and if so, return radio id and vapid
     Logical name is radioX_Y
]]
function acn_util.is_wifi(logical)

    if not logical then
        return nil
    end

    local radio_id, vap_id = logical:match(pre_vap_name .. '(%d+)_(%d+)')
    local return_radio_id = radio_id

    for i=0, product.num_wifi_radios - 1 do
        local radio_device = product.radio(i).device

        if radio_id and radio_device == pre_vap_name .. radio_id then
            return_radio_id = i
        end
    end

    -- Vap id is always >=1
    return vap_id,  return_radio_id, vap_id
end

--[[==========================================================================
      Return the logical name for this wifi iface (just use section name for now)
]]
function acn_util.wifi_logical(radio_id, vap_id)
    return acn_util.wifi_section(radio_id, vap_id)
end

--[[==========================================================================
     Fetch an ethernet iface object based on linux dev name
]]

function acn_util.eth_from_iface(iface)

    for i=0, product.num_eth_ports -1 do
        if product.eth(i)['dev_name'] == iface then
            return product.eth(i)
        end
    end

    return nil
end

--[[==========================================================================
     Fetch an ethernet iface object based on port id (like 6 or 4, used with vlans)
]]

function acn_util.eth_from_port_id(port_id)
    for i=0, product.num_eth_ports -1 do
        if product.eth(i)['port_id'] == port_id then
            return product.eth(i)
        end
    end

    return nil
end

--[[==========================================================================
     Take radio id and return friendly name with frequency
]]
function acn_util.radio_to_friendly(id)
    local radio = product.radio(id)
    return translate('Radio #') .. id .. ' (' .. radio.freq  .. ' ' .. translate('GHz') .. ')'
end

--[[==========================================================================
     Take radio id and return friendly name
]]
function acn_util.radio_to_friendly_short(id)
    local radio = product.radio(id)
    return translate('Radio #') .. id
end

function acn_util.radio_freq_to_friendly(id)
    local radio = product.radio(id)
    return radio.freq  .. ' ' .. translate('GHz')
end

function acn_util.mode_to_friendly(mode)
    local mode = mode:lower()

    if mode == 'ap' or mode == 'master' then
        return translate('Access Point')
    elseif mode:match('ptp') then
        if (mode:match('ap') or mode:match('master')) then
            return translate('Point-to-Point Master')
        elseif (mode:match('sta') or mode:match('client')) then
            return translate('Point-to-Point Slave')
        end
    elseif mode:match('wds') and (mode:match('sta') or mode:match('client')) then
        return translate('Client WDS')
    elseif mode == 'sta' or mode == 'client' then
        return translate('Client')
    end

    return mode
end

function acn_util.inet_src_to_logical(ifname)
    local ifname_radio_id, ifname_vap_id = ifname:match(product.wifi_prefix .. "(%d+)[-]*(%d*)")

    -- Special case for inet_src set to client mode
    if ifname_radio_id and  (ifname_vap_id == nil or #ifname_vap_id == 0) then
        return acn_util.wifi_logical(ifname_radio_id, 1), 'wifi'
    end

    return acn_util.ifname_to_logical(ifname)
end

function acn_util.ifname_to_logical(ifname)
    local is_pppoe = ifname:match(product.pppoe_prefix)

    if is_pppoe then
        -- Don't really have a logical name here, just return ifname
        return ifname, 'pppoe'
    end

    local is_3g = ifname:match("3g") or ifname:match("wwan0")
    if is_3g then
        return ifname, '3g'
    end

    -- can't use id returned by is_eth here since it may be wrong b/c not using logical name
    local is_eth = acn_util.is_eth(ifname)

    if is_eth then
        local eth = acn_util.eth_from_iface(ifname)
        if eth then
            return eth['logical_name'], 'eth'
        else
            return nil
        end
    end

    local ifname_radio_id, ifname_vap_id, wds_id = ifname:match(product.wifi_prefix .. "(%d+)[-]*(%d*)(w*%d*)")

    if ifname_radio_id then
        local logical = acn_util.wiface_to_logical_table()[ifname]
        return logical, 'wifi'
    end
end

function acn_util.inet_src_to_friendly(ifname)
    local logical = acn_util.inet_src_to_logical(ifname)
    if logical then return acn_util.logical_to_friendly(logical) end
end


function acn_util.ifname_to_friendly(ifname)
    local logical = acn_util.ifname_to_logical(ifname)
    if logical then return
        acn_util.logical_to_friendly(logical)
    end
end

function acn_util.eth_to_friendly(eth_id)
    if acn_util.is_sfp_port(eth_id) then
        -- XXX Note: when we'll have devices with two SFP ports (or more) there
        --  will be the problem, but for now just cross our fingers :)
        return translate("SFP Port #0")
    else
        return translate("Ethernet Port #") .. eth_id
    end
end

function acn_util.eth_to_friendly_short(eth_id)
    if acn_util.is_sfp_port(eth_id) then
        -- XXX Note: when we'll have devices with two SFP ports (or more) there
        --  will be the problem, but for now just cross our fingers :)
        return translate("SFP0")
    else
        return translate("ETH") .. eth_id
    end
end

--[[==========================================================================
     Translate ifname (eth0, radio1_1, etc) to a more friendly version

    For Wireless:
        - return Radio #id: SSID where SSID is the value in UCI, not running
    For Ethernet:
        - return Ethernet Port#id
]]

function acn_util.logical_to_friendly(logical_name)
    if logical_name == nil then return "" end

    local is_pppoe = logical_name:match(product.pppoe_prefix)

    if is_pppoe then
        return translate('PPPoE')
    end

    local is_3g = logical_name:match("3g") or logical_name:match("wwan0")
    if is_3g then
        return translate('3G/LTE')
    end

    local is_eth, eth_id = acn_util.is_eth(logical_name)

    if is_eth then
        return  acn_util.eth_to_friendly(eth_id), eth_id
    end

    local is_wifi, radio_id, vap_id = acn_util.is_wifi(logical_name)

    if is_wifi then
        local radio = radio_id and product.radio(radio_id)
        local section_name = radio and radio.device .. "_" .. vap_id
        local alt_radio_id = radio and radio.device:match(pre_vap_name .. '(%d)')

        -- XXX TODO: Need to make sure these keys match up with other multi ssid keys
        -- Can't directly access an unnamed section, so let's name them all!
         local ssid = acn_util.cursor():get('wireless', section_name , 'ssid') or ''
         return translate('Radio #') .. radio_id .. ': ' .. ssid, alt_radio_id
    end

    return logical_name, nil
end

function acn_util.logical_to_friendly_short(logical_name)
    if logical_name == nil then
        return ""
    end

    local is_pppoe = logical_name:match(product.pppoe_prefix)
    if is_pppoe then return
        translate('PPPoE')
    end

    local is_3g = logical_name:match("3g") or logical_name:match("wwan0")
    if is_3g then return
        translate('3G/LTE')
    end

    local is_eth, eth_id = acn_util.is_eth(logical_name)
    if is_eth then
        return  acn_util.eth_to_friendly_short(eth_id), eth_id
    end

    local is_wifi, radio_id, vap_id = acn_util.is_wifi(logical_name)
    if is_wifi then
        local radio = product.radio(radio_id)
        if radio then
            local section_name  = radio.device .. "_" .. vap_id
            local alt_radio_id = radio.device:match(pre_vap_name .. '(%d)')
            -- XXX TODO: Need to make sure these keys match up with other multi ssid keys
            -- Can't directly access an unnamed section, so let's name them all!
             local ssid = acn_util.cursor():get('wireless', section_name , 'ssid') or ''
             return  radio['freq'] .. ' GHz: ' .. ssid, alt_radio_id
         else
            return 'n/a', nil
         end
    end

    return logical_name, nil
end

--[[==========================================================================
     Get a list of allowable wan interface options (aka Internet Source)
     These are logical names (eth0, radio1_1, not wlan1-1)
]]
function acn_util.wan_iface_options()
    local uci = acn_util.cursor()

    -- Return ethernet ports, and wifi interfaces in client mode for now
    local list = {}

    for i=0, product.num_eth_ports -1 do
        list[#list + 1] = product.eth(i)['dev_name']
    end

    for i=0, product.num_wifi_radios -1 do
        -- If this radio is in client mode then add it to the list
        -- need to make sure it's enabled as well

        local mode = uci:get('wireless',  acn_util.radio_section(i) , 'mode') or 'ap'
        local radio_disabled = uci:get('wireless', acn_util.radio_section(i) , 'disabled') or '0'
        local wifi_disabled = uci:get('wireless', acn_util.wifi_section(i, 1) , 'disabled') or '0'

        -- XXX TODO: Do we allow them to set as the internet source if the ssid or port is disabled? Sure...
        if mode == 'sta' and radio_disabled == '0' and wifi_disabled == '0' then
            list[#list + 1] = acn_util.wifi_iface_name(i, 1)
        end
    end

    return list
end

function acn_util.vlan_id_from_ifname(ifname)
    local res = ifname:match('.+%.(%d+)')
    if res == nil or res == '' then
        return nil
    end

    return res
end


--[[==========================================================================
     Set proto of networks to 'none' if they don't have any members
     Do we need to do this?
]]
function acn_util.clear_empty_networks()
    -- XXX TODO: Do we need to do this for VPN network?

    --[[uci:foreach('network', 'interface',
        function(s)
            -- s is a table with option values (also has keys .type, .name)
            if (s.ifname and acn_util.has_iface(s.ifname, iface)) or acn_util.has_vlan(s.ifname, iface) then -- strip it out
    ]]
end

--[[==========================================================================
     Set type of wan to bridge if it has more than one iface
]]
function acn_util.handle_wan_type(uci_instance)
    local uci = uci_instance or acn_util.cursor()
    local ifaces = uci:get("network", wan_network, "ifname")
    local count = 0

    if ifaces and #ifaces > 0 then
        count = count + (#luci.util.split(luci.util.trim(ifaces), ' ') or 0)
    end

    -- Check wireless networks
    if count <=1 then
        local list = acn_util.network_wifi_ifaces(false, uci, true)[wan_network]
        if list then count = count + #list end
    end

    uci:set("network", wan_network, "type", "bridge")

    --[[ if count > 1 then
        uci:set("network", wan_network, "type", "bridge")
    else
        uci:set("network", wan_network, "type", "")
    end ]]

    uci:save("network")
end

--[[==========================================================================
     Add a logical interface to a network list
]]
function acn_util.add_iface_to_network(network, logical_iface, uci_instance)
    local uci = uci_instance or acn_util.cursor()

    -- Wifi ifaces don't get added to networks
    local is_wifi, radio_id, vap_id = acn_util.is_wifi(logical_iface)
    local is_eth, eth_id = acn_util.is_eth(logical_iface)

    if is_eth then
        if logical_iface == nil or luci.util.trim(logical_iface) == '' then return end
        logical_iface = luci.util.trim(logical_iface)

        local ifname =  product.eth(eth_id)['dev_name']
        local list = uci:get('network', network, 'ifname') or ''

        if acn_util.has_iface(list, ifname) then
            return
        end

        -- Clear it out of other networks
        acn_util.remove_iface_all_nets(ifname, uci)

        list = list .. ' ' .. ifname
        list = luci.util.trim(list)

        uci:set('network', network, 'ifname', list)
        uci:save('network')
    end

    -- If this is a wireless iface, set it's network, but not if this is a vlan iface
    -- XXX TODO: deal with mgmt vlan later
    if is_wifi and network then --and network ~= 'management' then
        local section_name = logical_iface
        if section_name then
            uci:set('wireless', section_name, 'network', network)
            uci:save('wireless')
        end
    end

    -- XXX TODO: call this after all interfaces are processed
    acn_util.clear_empty_networks()
    acn_util.handle_wan_type(uci)
end

function acn_util.has_iface(iface_list, iface)
    iface_list = iface_list or ''
    local giface = acn_util.escape_iface(iface)

    return iface_list:match('^' .. giface .. '$')
        or iface_list:match('^' .. giface .. '%s+')
        or iface_list:match('%s+' .. giface .. '%s+')
        or iface_list:match('%s+' .. giface .. '$')
end

function acn_util.has_vlan(iface_list, iface)
    iface_list = iface_list or ''
    local giface = acn_util.escape_iface(iface)
    local res = iface_list:match(giface .. '[.](%d+)')

    if res == '' then
        res = nil
    end
    return res
end

function acn_util.escape_iface(iface)
    iface = iface or ''
    return iface:gsub('[%-.]', '%%%0')
end

--[[==========================================================================
     Remove an interface from all networks (to prepare to add to another one)
         (similar to function in add_ifname script)
]]
function acn_util.remove_iface_all_nets(iface, uci_instance)
    local uci = uci_instance or acn_util.cursor()

    uci:foreach('network', 'interface',
        function(s)
            -- s is a table with option values (also has keys .type, .name)
            if (s.ifname and acn_util.has_iface(s.ifname, iface)) or acn_util.has_vlan(s.ifname, iface) then -- strip it out
                local giface = acn_util.escape_iface(iface)

                -- replace double spaces with single
                local new_ifname = s.ifname:gsub('^' .. giface .. '$', '')
                new_ifname = new_ifname:gsub('^' .. giface .. '%s+', '')
                new_ifname = new_ifname:gsub('%s+' .. giface .. '%s+', ' ')
                new_ifname = new_ifname:gsub('%s+' .. giface .. '$', '')

                -- replace vlan ifaces
                -- XXX TODO: fix this when add mgmt vlans
                -- XXX TODO: need to take into account swconfig ethernet ifaces of the form eth0.2
                --new_ifname = new_ifname:gsub( giface .. '%.%d+', ' ')
                new_ifname = new_ifname:gsub('  ', ' ')
                new_ifname = luci.util.trim(new_ifname)

                uci:set('network', s['.name'], 'ifname', new_ifname)
                uci:save('network')

                acn_util.handle_wan_type(uci)
            end
        end
    )
end

-- Based on network iface name, like vlan3, return a friendly string descriptor
-- for this VLAN network.
-- Second returned param is for the ethernet ports included in the vlan.
function acn_util.vlan_net_friendly_name(uci_instance, net_name)
    local uci = uci_instance or acn_util.cursor()
    -- netname is something like vlan3, but 3 is just logical id
    local logical_id = net_name:match("vlan(%d+)")

    if logical_id then
    local ifname = uci:get("network", net_name, "ifname")
    local vlan_id = acn_util.vlan_id_from_ifname(ifname)
        return translate("VLAN-Tagged Network") .. " (VLAN ID# " .. vlan_id .. ")"
    end

    return net_name, ""
end

function acn_util.add_inet_src_alert(s, logical_name)
    setfenv(1, getfenv(2))

    if not s.has_inet_src then
        s.has_inet_src = true
        inet_src_alert = s:option(DummyValue, "inet_src","")
        inet_src_alert.template = "cbi/inet_src_alert"
        inet_src_alert.logical_name = logical_name
    end
end

function acn_util.add_hotspot_wallgarden_div(network, map)
    -- Set current function's environment to the callers so we can access things like
    -- translate, TypedSection, etc...
    setfenv(1, getfenv(2))

    local s = map:section(TypedSection, "hs_wall", translate("Walled Garden"))
    s.iface = network
    s.template = "cbi/hotspot_wallgarden"
    s.parse = function(self, novld)
        TypedSection.parse(self, novld)
        local hs_wall = self.map:formvalue('cbid.' .. self.config .. '.' .. self.iface .. '.hs_wall')
        if hs_wall then
          hs_wall = hs_wall:gsub("\r\n", " ")
          hs_wall = hs_wall:gsub("\n", " ")
          self.map.uci:set(self.config, self.iface, "hs_wall", hs_wall);
          self.map.uci:save(self.config)
        end
    end
end

-- Add the network behavior aka access policy section
--      include_vlans:
--            whether or not to include vlans in the list of networks (eth won't use this, for ex)
--        always_show: force showing network behavior section (even if inet src is same as this iface)
function acn_util.add_net_access_section(s, m, element_name, logical_name, include_vlans, always_show, is_controlled_by_cloud)
    local uci = uci_instance or acn_util.cursor()
    local user_name = luci.http.getcookie("user_name")
    local root_user = luci.util.root_user(user_name)
    local msp_disabled = (uci:get("acn", "settings", "msp_enable") == "0" or uci:get("acn", "settings", "msp_enable") == nil)

    setfenv(1, getfenv(2))

    logical_inet_src = logical_inet_src or acn_util.inet_src_to_logical(s.map.uci:get('network', wan_network, 'inet_src') or '')
    if (logical_inet_src ~= logical_name) or always_show then
        local is_ethernet = (element_name == "ethernet")

        network_behavior = s:option(ListValue, "network_behavior", translate("Network Behavior"))
        network_name = s:option(ListValue, "network_name", translate("Network Name"))

        if is_ethernet and (root_user or msp_disabled) then
            CAPWAP_tunnel = s:option(ListValue, "CAPWAP_tunnel", translate("CAPWAP Tunnel Interface"))
            CAPWAP_tunnel.rmempty = false
            CAPWAP_tunnel.optional = true
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
                local tun = m.uci:get("ethernet", section, "tun") or "-1"
                local split_tun = m.uci:get("ethernet", section, "split_tun") or "0"
                if tun == "1" then
                    tun_tamp = split_tun;
                end

                return tun_tamp or "-1"
            end

            sz = s:option(Value, "_s_zone_", translate("Service Zone"))
            sz.is_disabled = true
            sz.rmempty = false
            sz.optional = true
            sz:depends("CAPWAP_tunnel","0")
            sz:depends("CAPWAP_tunnel","1")
            function sz.cfgvalue(self, section)
                local tun_type = self.map:get(section, "split_tun") or "0"

                if tun_type == "0" then -- complete tunnel
                    service_zone = self.map:get(section, "vid") or "0"
                    sz_val = tonumber(service_zone)%1000 or "0"
                else                    -- split tunnel
                    service_zone = self.map:get(section, "split_sz") or "0"
                    sz_val = tonumber(service_zone)%1000 or "0"
                end

                sz_val_ret = "SZ"..sz_val

                if sz_val_ret == "SZ0" then
                    sz_val_ret = "Default"
                end

                return sz_val_ret
            end
        end

        if root_user == false and msp_disabled == false then
            network_behavior.header_style = "display:none"
        end

        local vlan_lans
        if include_vlans and (root_user or msp_disabled) then
            default_vlan_behavior = s:option(ListValue, "default_vlan_behavior", translate("Default VLAN Behavior"))
            default_vlan_behavior:depends("network_behavior", "dynamic_vlan")
            default_vlan_behavior.rmempty = false
            default_vlan_behavior:value("reject", translate("Reject"))
            default_vlan_behavior:value("accept", translate("Accept"))
            default_vlan_behavior.help_tip = translate("Reject: A client can't connect to this SSID when the client's VLAN Id is"
                .. " not designated in the RADIUS server.<br />"
                .. "Accept: A client can connect to this SSID with the assigned or untagged VLAN Id"
                .. " when the client's VLAN Id is not designated in the RADIUS server.")

            function default_vlan_behavior.cfgvalue(self, section)
                local dynamic_vlan = m.uci:get("wireless", section, "dynamic_vlan")
                if dynamic_vlan == "2" then
                    return "reject"
                elseif dynamic_vlan == "1" then
                    return "accept"
                end
            end

            function default_vlan_behavior.write(self, section, value)
                local val = "2"
                if value == "accept" then
                    val = "1"
                end

                m.uci:set("wireless", section, "dynamic_vlan", val)
                ListValue.write(self, section, value)
            end

            vlan_lans = acn_util.vlan_LANs(m.uci)
            vlan_network_name = s:option(ListValue, "vlan_network_name", translate("VLAN Id"))
            vlan_network_name:depends("network_behavior", "vlan")
            vlan_network_name:depends("default_vlan_behavior", "accept")
            function get_alt_radio_vlan(logical_name)
                local j = logical_name:match(pre_vap_name .. "(%d+)")
                local occupied_vlan = {}
                m.uci:foreach("wireless", "wifi-iface",
                    function(i_section)
                        local ifc = i_section[".name"]
                        if ifc:match(pre_vap_name .. "(%d+)") ~= j then -- exclude current radio
                            local ifc_network = m.uci:get("wireless", ifc, "network")
                            if ifc_network:find("vlan") then
                                occupied_vlan[#occupied_vlan+1] = ifc_network
                            end
                        end
                    end
                )
                return occupied_vlan
            end

            vlan_network_config = s:option(DummyValue, "_vlan_network", translate("VLAN Settings"))
            vlan_network_config.template = "cbi/vlan_btn"
            vlan_network_config.vlan_count =  #vlan_lans
            vlan_network_config.iface_id = logical_name
            vlan_network_config.iface_type = (logical_name:match('eth') or logical_name:match('lan')) and 'ethernet' or 'wireless'
            vlan_network_config.alt_radio_vlan = get_alt_radio_vlan(logical_name)
            vlan_network_config:depends("network_behavior", "vlan")

            -- Add vlan-type networks
            vlan_network_name:value("wan", translate("Untagged"))

            if #vlan_lans == 0 then
                vlan_network_name:value("", translate("Select a VLAN Id"))
            end

            for i, network in ipairs(vlan_lans) do
                vlan_network_name:value(network["dev_name"], network["friendly"])
            end

            function vlan_network_name.cfgvalue(self, section)
                -- #10565 "no_dynamic_vlan" is for eth
                if not (include_vlans == "no_dynamic_vlan") then
                    return m.uci:get("wireless", section, "network")
                else
                    return m.uci:get("ethernet", section, "vlan_network_name")
                end
            end

            function vlan_network_name.write(self, section, value)
                ListValue.write(self, section, value)
                if include_vlans ~= "no_dynamic_vlan" then
                    return m.uci:set("wireless", section, "network", value)
                else
                    m.uci:foreach("network", "interface",
                        function(i_section)
                            local ifc = i_section[".name"]
                            if ifc:match('vlan%d+') then
                                local vlan_iface_name = i_section.ifname
                                if ( vlan_iface_name and
                                     (vlan_iface_name:match("eth%d+%s") or vlan_iface_name:match("eth%d+$") or
                                     vlan_iface_name:match("lan%d+%s") or vlan_iface_name:match("lan%d+$"))
                                   ) then
                                    clean_ifname = i_section.ifname:gsub("("..section..")%s",""):gsub("(%s"..section..")$","")
                                    m.uci:set("network",ifc,"ifname",clean_ifname)
                                end
                            end
                        end
                    )
                    local new_vlan_interface_members = m.uci:get("network", value, "ifname", section) .. ' ' .. section
                    m.uci:set("network", value, "ifname", new_vlan_interface_members)
                    m.uci:save("network")
                    return m.uci:set("ethernet", section, "vlan_network_name", value)
                end
            end
--[[
            -- Uplink 802.1p
            if element_name == "wireless" then
                u8021p = s:option(ListValue, "u8021p", translate("Uplink 802.1p"))
                u8021p:depends("network_behavior", "vlan")

                u8021p:value("disable", "Disable")
                u8021p:value("0", "Best Effort")
                u8021p:value("1", "Background")
                u8021p:value("2", "Excellent Effort")
                u8021p:value("3", "Critical Applications")
                u8021p:value("4", "Video")
                u8021p:value("5", "Voice")
                u8021p:value("6", "Internetwork Control")
                u8021p:value("7", "Network Control")
                u8021p.default = "disable"

                function u8021p.cfgvalue(self, section)
                    local vlan_network_name, entry_exist
                    if not (include_vlans == "no_dynamic_vlan") then
                        vlan_network_name = m.uci:get("wireless", section, "network")
                    else
                        vlan_network_name = m.uci:get("ethernet", section, "vlan_network_name")
                    end

                    m.uci:foreach("network", "interface",
                       function(i_section)
                           local ifc = i_section[".name"]
                           if ( ifc == vlan_network_name ) then
                               entry_exist = m.uci:get("network",ifc,"u8021p") or "disable"
                           end
                       end
                    )
                    return entry_exist
                end

                function u8021p.write(self, section, value)
                    local vlan_network_name = luci.http.formvalue("cbid.wireless." .. logical_name .. ".vlan_network_name")
                    m.uci:foreach("network", "interface",
                        function(i_section)
                            local ifc = i_section[".name"]
                            if ( ifc == vlan_network_name ) then
                                local entry_exist = m.uci:get("network",ifc,"u8021p")
                                if value ~= "disable" then
                                    m.uci:set("network",ifc,"u8021p",value)
                                elseif entry_exist ~= nil then
                                    m.uci:delete("network",ifc,"u8021p")
                                end
                                m.uci:save("network")
                            end
                        end
                    )
                end
                if is_controlled_by_cloud then
                    u8021p.is_disabled = true
                end
            end --end u8021p
]]
        end

        if has_hotspot and (root_user or msp_disabled ) then
            hotspot = s:option(DummyValue, "_Link", translate("Hotspot Settings"))
        end

        network_behavior:value(wan_network, translate("Bridge to Internet"))
        network_behavior:value("route", translate("Route to Internet"))
        network_behavior:value(guest_network, translate("Add to Guest Network"))
        --hide vpn for U-AP-Pilot release
        --uapp network_behavior:value(vpn_network, translate("Bridge to VPN"))
        if has_hotspot and (root_user or msp_disabled) then
            network_behavior:value(hotspot_network, translate("Hotspot Controlled"))
        end

        if include_vlans then
            network_behavior:value("vlan", translate("VLAN Tag Traffic"))
            -- #10565 - do not need dynamic VLAN for Eth
            if not (include_vlans == "no_dynamic_vlan") then
                network_behavior:value("dynamic_vlan", translate("Dynamic VLAN"))
            end
        end

        network_behavior.logical_name = logical_name
        network_behavior.cfgvalue = function(self, section)
            local network
            local dynamic_vlan_selected = m.uci:get("wireless", section, "dynamic_vlan")

            if acn_util.is_eth(logical_name) then
                network = acn_util.eth_network(self.logical_name, m.uci) or ""
            else
                network = m.uci:get("wireless", section, "network") or 'lan'
            end

            if dynamic_vlan_selected then
                return "dynamic_vlan"
            else
                if acn_util.is_custom_LAN(network, m.uci) or network == lan_network then
                    return 'route'
                elseif acn_util.is_VLAN_LAN(network, m.uci) then
                    return 'vlan'
                else
                    return network
                end
            end
        end

        if has_hotspot and (root_user or msp_disabled) then
                hotspot.template = "cbi/hotspot"
                hotspot.radio_id = logical_name
                hotspot.is_controlled_by_cloud = is_controlled_by_cloud

                if m.config == "wireless" then
                    hotspot_wallgarden_btn = s:option( DummyValue, "_wallgarden", translate("Walled Garden"))
                    hotspot_wallgarden_btn.template = "cbi/hotspot_wallgarden_btn"
                    hotspot_wallgarden_btn:depends("network_behavior", hotspot_network)
                    hotspot_wallgarden_btn.help_tip = "These values will be appended to the global Walled Garden values from the Hotspot configuration page."
                    hotspot_wallgarden_btn.is_controlled_by_cloud = is_controlled_by_cloud
                end
        end
        local i, p
        local n = {}

        -- Also add the main LAN network
        network_name:value(lan_network, translate("Default local network"))

        -- Now add custom LANs (not built in)
        for i, network in ipairs(acn_util.custom_LANs(m.uci)) do
            network_name:value(network["dev_name"], network["friendly"])
        end

        network_name.logical_name = logical_name

        -- This is the name to show in the network list when route is chosen
        network_name.cfgvalue = function(self, section)
            local network
            if acn_util.is_eth(self.logical_name) then
                network = acn_util.eth_network(self.logical_name, m.uci) or ""
            else
                network = m.uci:get("wireless", section, "network")
            end
            return network
        end

        if has_hotspot and (root_user or msp_disabled) then
                hotspot:depends("network_behavior", hotspot_network)
        end
        network_name:depends("network_behavior",  "route")

        function network_behavior.write(self, section, value)
            if value == "dynamic_vlan" then
                local wlan_interface_idx = section:match(pre_vap_name .. "(%s+)") or "0"
                local rad_id, vap_id = section:match(pre_vap_name .. "(%d+)_(%d+)")
                m.uci:set("wireless", section, "dynamic_vlan", "2")
                m.uci:set("wireless", section, "vlan_tagged_interface", "eth0")
                m.uci:set("wireless", section, "vlan_bridge", "br-")
                value = "wan"
            else
                m.uci:delete("wireless", section, "dynamic_vlan")
                m.uci:delete("wireless", section, "vlan_tagged_interface")
                m.uci:delete("wireless", section, "vlan_bridge")
                m.uci:delete("wireless", section, "default_vlan_behavior")
            end

            -- DONT USE logical_name here - it uses last one in the loop

            -- If we switch from wifi client -> ap mode, we need to change the
            -- inet source if radiox_reset_inet_src is set

            -- Going from STA to AP mode
            local reset_inet_src = luci.http.formvalue(section ..'_reset_inet_src')

            -- Going from AP to STA mode
            local set_inet_src = luci.http.formvalue(section ..'_set_inet_src')

            if reset_inet_src == "1" then
                -- set inet src to first ethernet port
                local first_eth = product.eth(0)['dev_name']
                m.uci:set("network", wan_network, "inet_src", first_eth)
                acn_util.add_iface_to_network(wan_network, first_eth, m.uci)
            elseif set_inet_src == "1" then
                local logical_wlan_id = section:match(pre_vap_name .. "(%d+)") or "0"
                local wlan_inet = product.wifi_prefix .. logical_wlan_id
                m.uci:set("network", wan_network, "inet_src", wlan_inet)
                acn_util.add_iface_to_network(wan_network, wlan_inet, m.uci)
                m.uci:set("wireless", section, "network", "wan")
            end

            local proto = m.uci:get("network", wan_network, "proto")
            if (reset_inet_src == "1" or set_inet_src == "1") and proto == "3g" then
                m.uci:set("network", wan_network, "proto", "none")
            end

            -- if we're the wan interface, skip this
            local wan_iface = m.uci:get('network', wan_network, 'inet_src')
            local logical_wan_name = acn_util.ifname_to_logical(wan_iface)

            if logical_wan_name == section then
                return
            end

           local network = value
            if value == "route" then
                network = luci.http.formvalue("cbid." .. element_name .. "." .. section .. ".network_name")
            elseif value == "vlan" then
                network = luci.http.formvalue("cbid." .. element_name .. "." .. section .. ".vlan_network_name")
            end

            acn_util.add_iface_to_network(network, section, m.uci)

            if product.is_EAP104() then
                m.uci:save("network")
                return
            end

            local sw_vlans = {}
            m.uci:foreach("network", "switch_vlan", function(s) table.insert(sw_vlans, s) end)

            if (#sw_vlans ~= 0) then
                if (acn_util.has_iface(m.uci:get('network', 'wan', 'ifname'), "eth0") and acn_util.has_iface(m.uci:get('network', 'wan', 'ifname'), "eth1")) or
                (acn_util.has_iface(m.uci:get('network', 'lan', 'ifname'), "eth0") and acn_util.has_iface(m.uci:get('network', 'lan', 'ifname'), "eth1")) then
                    m.uci:set('network', sw_vlans[1][".name"], 'ports', '0 4 5')
                    if sw_vlans[2] then
                        m.uci:delete('network', sw_vlans[2][".name"])
                    end
                else
                    m.uci:set('network', sw_vlans[1][".name"], 'ports', '0 4')
                    if not sw_vlans[2] then
                        local new_sw_vlan = m.uci:add('network', 'switch_vlan')
                        m.uci:set('network', new_sw_vlan, 'device', 'switch0')
                        m.uci:set('network', new_sw_vlan, 'vlan', '2')
                        m.uci:set('network', new_sw_vlan, 'ports', '0 5')
                    end
                end
            end

            m.uci:save("network")
        end

        function network_name.write(self, section, value)
            -- Need to call network_behavior.write again since it may not be called in cases where the
            -- behavior value is not changed
            -- (so keeping 'route', but changing the routed network)
            --network_behavior.write(...) --trista
            local behavior = luci.http.formvalue("cbid." .. element_name .. "." .. section .. ".network_behavior")
            local network

            if behavior then
                if behavior == "route" then
                    network = luci.http.formvalue("cbid." .. element_name .. "." .. section .. ".network_name")
                elseif behavior == "vlan" then
                    network = luci.http.formvalue("cbid." .. element_name .. "." .. section .. ".vlan_network_name")
                end

                acn_util.add_iface_to_network(network, section, m.uci)
            end

        end
    end
    acn_util.add_inet_src_alert(s, logical_name)
end

function acn_util.add_ip_alias_div(network, map)
    -- Set current function's environment to the callers so we can access things like
    -- translate, TypedSection, etc...
    setfenv(1, getfenv(2))

    local s = map:section(TypedSection, "alias", translate("IP Aliases"))
    s.addremove = true
    s.anonymous = true
    s.acn_dialog = network
    s.max_count = 5

    -- Use javascript/dynamic add remove template
    s.template = "cbi/tblsection_js"

    s.table_name = "table_ip_alias_" .. network
    s.add_onclick = 'addIpAliasRow("' .. network .. '");'
    s.del_onclick = "removeIpAliasRow('" .. network .. "',this.id);"
    s.network = network

    if network then
        s:depends("interface", network)
        s.defaults.interface = network
    end

    s.defaults.proto = "static"

    ip = s:option(Value, "ipaddr", translate("IP"))
    netmask = s:option(Value, "netmask", translate("Netmask"))
    comment = s:option(Value, "comment", translate("Comment"))

    ip.rmempty = true

    s.parse = function(self, nvld)
        -- Have to do this first
        TypedSection.parse(self, nvld)

        local add_prefix = "acn.new." .. network
        local del_prefix = "acn.del"

        -- This gets a list of all form values that begin with the prefix

        local new_ip_aliases  = self.map:formvaluetable(add_prefix)
        -- want these sorted
        local keys = {}

        for k in pairs(new_ip_aliases) do
            keys[#keys+1] = k
        end

        table.sort(keys, function(a,b) return new_ip_aliases[a] < new_ip_aliases[b]  end)

        -- Need to use map.uci here so that the settings are saved
        for i, k in ipairs(keys) do
            local v = new_ip_aliases[k]

            if v then
                local ipaddr = self.map:formvalue('cbid.network.cfg' .. v .. '.ipaddr')
                local is_deleted = (self.map:formvalue(del_prefix .. ".network.cfg" .. v) == "1")

                if ipaddr and #ipaddr > 0 and not is_deleted then
                    -- Create our anon section
                    local cfg_name = self:create()

                    self.map.uci:set("network", cfg_name, "proto", self.defaults.proto);
                    self.map.uci:set("network", cfg_name, "ipaddr", ipaddr or '')
                    self.map.uci:set("network", cfg_name, "netmask", self.map:formvalue('cbid.network.cfg' .. v .. '.netmask') or '')
                    self.map.uci:set("network", cfg_name, "interface", self.defaults.interface)
                    self.map.uci:set("network", cfg_name, "comment", self.map:formvalue('cbid.network.cfg' .. v .. '.comment') or '')

                    self.map.uci:save("network")
                    self.map.uci:load("network")
                end
            end
        end

       local table = self.map:formvaluetable(del_prefix .. ".network")

        -- Need to use map.uci here so that the settings are saved correctly
        for k, v in pairs(table) do
            if v and (v == "1" or v == 1) then
                self.map.uci:delete("network", k)
            end
        end

        self.map.uci:save("network");
    end
end

function acn_util.add_acl_div(section, map)
    setfenv(1, getfenv(2))

    -- Don't want a whole new section for each mac address. We might have hundreds per SSID.
    -- Let's do OpenWRT Mac filter style, and include in a space delimited list
    -- We will keep this in case we decide to switch to sections later

    local s = map:section(TypedSection, "acl", translate("Access Control List"))
    s.addremove = true
    s.anonymous = true
    s.acn_dialog = section

    -- Use javascript/dynamic add remove template
    s.template = "cbi/tblsection_js"

    s.table_name = "table_acl_" .. section
    s.add_onclick = 'addAclRow("' .. section .. '");'
    s.del_onclick = "removeAclRow('" .. section .. "',this.id);"

    s:depends("interface", section)
    s.defaults.interface = section

    mac_addr = s:option(Value, "mac_addr", translate("MAC Address"))
    mac_addr.datatype = "macaddr"
    mac_addr.rmempty = true

    s.modal_style = 'width:500px'
end

function acn_util.is_custom_LAN(network, uci_instance)
    local uci = uci_instance or acn_util.cursor()

    -- XXX TODO: do we want to create a custom uci key for built-in networks?
    -- And... there it is!
    return network:find("custom%_")
    --return uci:get('network', network, 'custom') == '1'
end

function acn_util.is_VLAN_LAN(network, uci_instance)
    local uci = uci_instance or acn_util.cursor()
    return uci:get('network', network, 'vlan_net') == '1'
end

function acn_util.firewall_friendly_network(network, uci)
    if network:match("custom") then
        local uci = uci_instance or acn_util.cursor()
        return uci:get("network", network, "title") or network
    else
        if network == wan_network then return translate('Internet')
        elseif network == guest_network then return translate('Guest Network')
        elseif network == lan_network then return translate('Default Local Network')
    elseif network == hotspot_network then return translate('Hotspot Network')
        else return translate(network)
        end
    end
end

function acn_util.friendly_network(network, uci)

    if network == hotspot_network then return translate('Hotspot Network')
    elseif network == wan_network then return translate('Main WAN Bridge')
    elseif network == guest_network then return translate('Default Guest Network')
    elseif network == vpn_network then return translate('VPN Network')
    elseif network == mgmt_network then return translate('Mgmt VLAN Network')
    elseif network == local_network then return translate('Device-Only Network (No Other Access)')
    elseif network == lan_network then return translate('Default Local Network')
    end

    if uci then
        local custom_title = uci:get("network", network, "title")
        if custom_title then
            return custom_title
        end
    end
    return network
end

function acn_util.friendly_proto(proto)
  local wan_inet_src = uci:get("network", "wan", "inet_src")
    local proto = proto:lower()

  if proto == '3g' or (proto == 'dhcp' and wan_inet_src == "wwan0") then return translate('3G/LTE')
    elseif proto == 'dhcp' then return translate('DHCP-assigned')
    elseif proto == 'static' then return translate('Static IP')
    elseif proto == 'pppoe' then return translate('PPPoE')
    elseif proto == '' or proto == 'none'  then return translate('None')
    else return proto
    end

end


--[[==========================================================================
     Get a list of vlan-type LANs
]]
function acn_util.vlan_LANs(uci_instance)
    local uci = uci_instance or acn_util.cursor()
    local is_eap104 = product.is_EAP104()
    local lan_vlan_table = {}
    local vlan_dev_ifname = uci:get("network", "dev_lan1", "ifname") -- TODO

    if is_eap104 then

        for i = 1, 4 do
            local vlan_dev_vid = uci:get("network", "dev_lan" .. i, "vid")
            local vlan_dev_name = uci:get("network", "dev_lan" .. i, "name")

            if vlan_dev_vid and vlan_dev_name then
                lan_vlan_table[vlan_dev_vid] = vlan_dev_name
            end
        end
    end

    local networks = {}

    uci:foreach('network', 'interface',
        function(s)
            -- VLAN network names are like vlanXX, where XX is the vlan id (logical name, not real vlan id)
            local logical_vlan_id = s['.name']:match("vlan(%d+)")

            if logical_vlan_id and s.vlan_net == "1" then
                local lan = {}
                local ports = {}
                -- Protection for misconfigurations - missing ifname
                local ifname = s['ifname'] or ''

                -- #10565 real ifaces on wifi bridge
                local ifaces = {}

                if is_eap104 then
                    for vlan_port in string.gmatch(ifname, 'eth%d+%.%d+') do
                        if not vlan_port:match("^" .. vlan_dev_ifname .. ".-") then
                          port = vlan_port:match('eth%d')
                          ports[port] = vlan_port
                        end
                    end
                    for iface in string.gmatch(ifname, '(eth%d+)%s') do
                        ifaces[iface] = iface
                    end
                    for iface in string.gmatch(ifname, '(eth%d+)$') do
                        ifaces[iface] = iface
                    end
                    for iface in string.gmatch(ifname, '(lan%d+)%s') do
                        ifaces[iface] = iface
                    end
                    for iface in string.gmatch(ifname, '(lan%d+)$') do
                        ifaces[iface] = iface
                    end

                    local svlan_ports = uci:get("network", "svlan_" .. acn_util.vlan_net_name(logical_vlan_id), "ports")
                    if svlan_ports then
                        for svlan_port in string.gmatch(svlan_ports, "%d+%t") do
                            if svlan_port and svlan_port ~= "6t" then
                                local svlan_vid = svlan_port:match("%d+")
                                local vlan_dev_name = lan_vlan_table[svlan_vid]

                                if vlan_dev_name and vlan_dev_ifname then
                                    ports[vlan_dev_name] = vlan_dev_ifname
                                end
                            end
                        end -- for svlan_port
                    end
                else
                    for vlan_port in string.gmatch(ifname, 'eth%d+%.%d+') do
                        port = vlan_port:match('eth%d')
                        ports[port] = vlan_port
                    end
                    for iface in string.gmatch(ifname, '(eth%d+)%s') do
                        ifaces[iface] = iface
                    end
                    for iface in string.gmatch(ifname, '(eth%d+)$') do
                        ifaces[iface] = iface
                    end
                end
                lan['dev_name'] = s['.name']
                lan['dev_idx'] = tonumber(logical_vlan_id)
                lan['vlan_id'] = ifname:match('eth%d+%.(%d+)')
                lan['ports'] = ports
                lan['ifaces'] = ifaces
                lan['friendly'] = "VLAN # " .. (lan['vlan_id'] or "N/A")
                lan['logical_vlan_id'] = logical_vlan_id
                lan['__uid'] = uci:get("network", "vlan" .. logical_vlan_id, "__uid")
                lan['circuit_id'] = s.circuit_id
                lan['circuit_id_data'] = s.circuit_id_data

                lan['proto'] = s.proto
                lan['pppoe_username'] = s.username
                lan['pppoe_pwd'] = s.password
                lan['pppoe_ip'] = uci:get("network", s['.name'] .. "_" .. lan['vlan_id'], "ipaddr")

                networks[#networks+1] = lan

                -- sort the networks table in increasing order of the vlanX from lan['dev_idx']
                table.sort(networks,
                    function (k1, k2)
                        return k1.dev_idx < k2.dev_idx
                    end)
            end
        end)
    return networks
end

---
-- @param uci
-- @param net_name network name for VLAN (for example, 'vlan4')
-- @return list of ethernet ports in this VLAN
function acn_util.vlan_ports(uci, net_name)
    local ports = {}
    local is_eap104 = product.is_EAP104()
    local vlan_dev_ifname = uci:get("network", "dev_lan1", "ifname") -- TODO:

    local ifname = uci:get("network", net_name, "ifname") or ""
    for port in string.gmatch(ifname, "eth%d+%.%d+") do
        if is_eap104 then
            if not (vlan_dev_ifname and port:match("^" .. vlan_dev_ifname .. ".-")) then
              ports[#ports + 1] = port
            end
        else
          ports[#ports + 1] = port
        end
    end

    if is_eap104 then
        local lan_vlan_table = {}

        for i = 1, 4 do
            local vlan_dev_vid = uci:get("network", "dev_lan" .. i, "vid")
            local vlan_dev_name = uci:get("network", "dev_lan" .. i, "name")

            if vlan_dev_vid and vlan_dev_name then
                lan_vlan_table[vlan_dev_vid] = vlan_dev_name
            end
        end

        local svlan_ports = uci:get("network", "svlan_" .. net_name, "ports")
        local svlan_vid = uci:get("network", "svlan_" .. net_name, "vlan")
        if svlan_ports and svlan_vid then
            for svlan_port in string.gmatch(svlan_ports, "%d+%t") do
                if svlan_port and svlan_port ~= "6t" then
                    local svlan_port_vid = svlan_port:match("%d+")
                    if svlan_vid and lan_vlan_table[svlan_port_vid] then
                                ports[#ports + 1] = lan_vlan_table[svlan_port_vid] .. "." .. svlan_vid
                    end
                end
            end -- for svlan_port
        end
    end
    return ports
end

--[[==========================================================================
     Return the network interface name based on vlan id
]]
function acn_util.vlan_net_name(logical_vlan_id)
    return "vlan" .. logical_vlan_id
end

--[[==========================================================================
     Get a list of VLAN objects
]]
function acn_util.vlans(uci_instance)
    local uci = uci_instance or acn_util.cursor()
    local networks = acn_util.vlan_LANs(uci)
    return networks
end

function acn_util.is_mgmt_vlan_enabled(uci_instance)
    local uci = uci_instance or acn_util.cursor()
    local enabled = uci:get("network", mgmt_network, "enabled")

    return acn_util.is_enabled(enabled)
end

function acn_util.is_wan_vlan_enabled(uci_instance)
    local uci = uci_instance or acn_util.cursor()
    local enabled = uci:get("network", wan_vlan_network, "enabled")

    return acn_util.is_enabled(enabled)
end

---
-- @return `true` if value is "enabled" (according to UCI: "1", "true", "yes", "on")
function acn_util.is_enabled(value)
    return value == "1" or value == "true" or value == "yes" or value == "on"
end

--[[==========================================================================
     Get a list of custom LANs
]]
function acn_util.custom_LANs(uci_instance)
    local uci = uci_instance or acn_util.cursor()
    local networks = {}
    uci:foreach('network', 'interface',
        function(s)
            if s[".name"]:match("custom_") then
                local lan = {}
                lan['dev_name'] = s['.name']
                lan['friendly'] = s["title"] -- (Custom) " .. lan['dev_name']
                networks[#networks+1] = lan
            end
        end)
    return networks
end

--[[ Get the network for this ethernet port by dev name (eth0)
]]
function acn_util.eth_network_from_devname(dev_name, uci)
    local network = nil
    uci:foreach('network', 'interface',
        function(s)
            if acn_util.has_iface(s.ifname, dev_name) then
                network = s[".name"]
            end
        end)

    return network
end

--[[ Get the network for this logical ethernet
    port
]]
function acn_util.eth_network(logical_name, uci)
    local uci = uci or acn_util.cursor()
    local is_eth, eth_id = acn_util.is_eth(logical_name)
    if not is_eth then
        return nil
    end

    local dev_name = product.eth(eth_id)['dev_name']
    return acn_util.eth_network_from_devname(dev_name, uci)
end

--[[==========================================================================
    Convert the interface name (like wlan0) to the wireless section
    name.  Example: wlan0 -> radio0_1, wlan0-1 -> radio0_2
    UPDATE: since we don't know what interface may be given to a wifi section
            let's get it from uci state.
            (This may happen if you disable a VAP, say SSID#2, so that SSID#3 will
            have wlan0-2 instead of wlan0-3  )
    UCI state stores iface name, woo hoo
]]

local _wiface_to_logical_table, _ubuswificache = nil, nil

function acn_util.wiface_to_logical_table()
    if _wiface_to_logical_table == nil or _ubuswificache == nil then
        local utl = require "luci.util"

        _wiface_to_logical_table = {}
        _ubuswificache = utl.ubus("network.wireless", "status", {}) or {}

        -- UCI state not used for wireless anymore
        --local uci_st = acn_util.cursor_state()

        -- Taken from luci network model:
        for radio, radiostate in pairs(_ubuswificache) do
            for ifc, ifcstate in pairs(radiostate.interfaces) do

                -- https://accton-group.atlassian.net/browse/ECCLOUD-2997
                -- ubus can't get ifname sometimes. When it gets null value, it gets value from ubus config section.
                if not ifcstate.ifname then
                  local netconfig = ifcstate.config
                  if netconfig then
                    config_ifname = netconfig.ifname
                  end
                  if config_ifname then
                    ifcstate.ifname = config_ifname
                  end
                end

                if ifcstate.section and ifcstate.ifname then
                    _wiface_to_logical_table[ifcstate.ifname] = ifcstate.section
                end
            end
        end
    end
    return _wiface_to_logical_table
end

-- Maps logical interface to its network
-- (only used by network_members, but don't want to recreate for each LAN)

local _network_wifi_ifaces = nil

function acn_util.network_wifi_ifaces(include_disabled, uci_instance, force_reload)
    local uci = uci_instance or acn_util.cursor()

    if _network_wifi_ifaces == nil or force_reload then
        _network_wifi_ifaces = {}

        uci:foreach('wireless', 'wifi-iface', function(s)
            local device = uci:get('wireless', s['.name'], 'device')

            -- Also need to check root status
            local root_disabled = uci:get('wireless', device, 'disabled') or '0'

            -- Let's exclude disabled wifi SSIDs for now
            if (s.disabled ~= '1' and root_disabled ~= '1') or include_disabled then
                if _network_wifi_ifaces[s.network] == nil then
                    _network_wifi_ifaces[s.network] = {}
                end

                local wifi_list = _network_wifi_ifaces[s.network]

                wifi_list[#wifi_list + 1] = s['.name']
                _network_wifi_ifaces[s.network] = wifi_list

                 if s.wds == '1' then
                    if _network_wifi_ifaces[wds_vlan_link] == nil then
                        _network_wifi_ifaces[wds_vlan_link] = {}
                    end

                    local wds_vlan_pt_list = _network_wifi_ifaces[wds_vlan_link]

                    wds_vlan_pt_list[#wds_vlan_pt_list + 1] = s['.name']
                    _network_wifi_ifaces[wds_vlan_link] = wds_vlan_pt_list
                else
                    if _network_wifi_ifaces[wds_vlan_link] == nil then
                        _network_wifi_ifaces[wds_vlan_link] = {}
                    end
                end
            end
        end);
    end
    return _network_wifi_ifaces
end

--[[
    Return member label based on internet source
]]
function acn_util.inet_src_member_label(ifname)
    local logical_name, iface_type = acn_util.inet_src_to_logical(ifname)
    return acn_util.logical_member_label(logical_name, iface_type)
end

--[[
    Return member label based on linux iface name
     iface = ifname = dev_name (sorry for inconsistent naming...)
]]
function acn_util.iface_member_label(iface)
    local logical_name, iface_type = acn_util.ifname_to_logical(iface)
    return acn_util.logical_member_label(logical_name, iface_type)
end

-- Id is optional here
function acn_util.logical_member_label(logical_name, _type)
    local entry = {}

    -- This might happen if we send in a non-internal vlan iface, like eth0.55
    if logical_name == nil then
        return nil
    end

    -- Iface id is the main interface id, e.g. for radio0network1, it's 0, for eth0, it's 0, etc...
    -- Mainly used to generate links for menu items
    local iface_id

    entry['logical_name'] = logical_name
    entry['friendly'], iface_id = acn_util.logical_to_friendly(logical_name)
    entry['friendly_short'], iface_id = acn_util.logical_to_friendly_short(logical_name)
    entry['type'] = _type

    iface_id = iface_id or 0

    if _type == 'eth' then
        entry['url_params'] = '?id=' .. iface_id
        entry['link'] = 'admin/network/ethernet'
        entry['icon-class'] = 'icon-sitemap'
        local uci = acn_util.cursor()
        local status = uci:get("ethernet", logical_name, "status")
        entry['label-class']    = status == '1' and 'orange' or 'eth-gray'
    elseif _type == 'pppoe' or _type == '3g' or _type == 'wwan0' then
        entry['link'] =  '/admin/status/Internet'
        entry['icon-class'] =  'icon-sitemap'
        entry['label-class'] =  'purple' -- pppoe = girly color
    elseif _type == 'wifi' then
        entry['link'] = '/admin/wireless/wifi/' .. pre_vap_name .. iface_id .. '.network1'
        entry['icon-class'] = 'icon-signal'
        entry['label-class'] = 'wifi-green'
    else
        entry['link'] = ''
    end

    return entry
end

function acn_util.network_members(network, uci_instance)
    local res = {}
    local uci = uci_instance or acn_util.cursor()
    -- Get non-wifi ifaces here
    local ifaces = uci:get("network", network, "ifname")

    if ifaces then
        for i, v in ipairs(luci.util.split(ifaces, ' ')) do
            if v and v ~= '' then
                local eth = acn_util.eth_from_iface(v)
                if eth then
                    -- This is real device name, we need logical
                    -- XXX TODO, need to figure out non-standard interfaces like vlan, pppoe, tun, etc...
                    res[#res + 1] = acn_util.logical_member_label( eth['logical_name'] , 'eth')
                end
            end
        end
    end

    -- Now get wifi networks
    local wifi_list = acn_util.network_wifi_ifaces(false, uci)[network]
    if wifi_list then
        for k, v in ipairs(wifi_list) do
            res[#res + 1] =  acn_util.logical_member_label(v, 'wifi')
        end
    end

    return res
end

-- List of hidden lans for the LAN settings page
-- (including VLAN)

function acn_util.hide_from_lan_page(network, vlan_net)
    if vlan_net == "1" then
        return true
    end

    return hidden_lans[network]
end

function acn_util.is_sta_mode(mode)
    mode = mode or "ap"
    return mode:match("sta")
end

--- Retrieves WiFi encryption string for particular interface using nl80211 interface
-- @param interface to get encryption about, i.e. wlan0, wlan1-2 etc.
-- @return user friendly encryption description, e.g. WPA2-PSK+TKIP+CCMP
function acn_util.get_ifc_encryption_rtl(ifc)
    --log("trace", "get_ifc_encryption_rtl: %s", tostring(ifc))
    local enc = iwinfo.nl80211.encryption(ifc)
    local wireless_security

    if not enc or (not enc.wep and tonumber(enc.wpa) == 0) then
        wireless_security = "None"
    elseif enc.wep then
        wireless_security = "WEP-OPEN"
        for _, pair_cipher in ipairs(enc.pair_ciphers) do
            wireless_security = wireless_security .. "+" .. pair_cipher
        end
    elseif tonumber(enc.wpa) == 1 or tonumber(enc.wpa) == 2 then
        if tonumber(enc.wpa) == 2 then
            wireless_security = "WPA2"
        else
            wireless_security = "WPA"
        end

        if tostring(enc.auth_suites[1]):sub(1, 3) == '802' then
            wireless_security = wireless_security .. "-EAP"
        elseif enc.auth_suites[1] then
            wireless_security = wireless_security .. "-" .. tostring(enc.auth_suites[1])
        end

        for _, pair_cipher in ipairs(enc.pair_ciphers) do
            wireless_security = wireless_security .. "+" .. pair_cipher
        end
    else
        wireless_security = "Encrypted-unknown"
    end

    return wireless_security
end

function acn_util.get_ifc_encryption_qca(radio_id, ifname)
    local _encryption
    local vap_status = {}
    local get_vap_info = {}

    local p1 = io.popen("ubus call network.wireless status > /tmp/wireless_stat.json")
    local output = fs.readfile('/tmp/wireless_stat.json') or ""
    local wireless_stat = json.decode(output)

    if not (wireless_stat and wireless_stat[radio_id] and wireless_stat[radio_id].interfaces) then
        return
    else
        get_vap_info = wireless_stat[radio_id].interfaces
    end

    for idx, ifstat in ipairs(get_vap_info) do

        -- https://accton-group.atlassian.net/browse/ECCLOUD-2997
        -- ubus can't get ifname sometimes. When it gets null value, it gets value from ubus config section.
        if not ifstat.ifname then
          local netconfig = ifstat.config
          if netconfig then
            config_ifname = netconfig.ifname
          end
          if config_ifname then
            ifstat.ifname = config_ifname
          end
        end

        if ifname == ifstat.ifname then
            vap_status = ifstat.config
            _encryption = vap_status.encryption
            break
        end
    end

    p1:close()

    if _encryption == "none" then encryption = "None"
    elseif _encryption == "psk+ccmp" then encryption = "WPA-PSK (CCMP)"
    elseif _encryption == "psk+tkip+ccmp" then encryption = "WPA-PSK (TKIP, CCMP)"
    elseif _encryption == "psk2+ccmp" then encryption = "WPA2-PSK (CCMP)"
    elseif _encryption == "psk2-radius" then encryption = "WPA2-PSK (CCMP)"
    elseif _encryption == "psk2+tkip+ccmp" then encryption = "WPA2-PSK (TKIP, CCMP)"
    elseif _encryption == "wpa" then encryption = "WPA-EAP"
    elseif _encryption == "wpa+ccmp" then encryption = "WPA-EAP (CCMP)"
    elseif _encryption == "wpa+tkip+ccmp" then encryption = "WPA-EAP (TKIP, CCMP)"
    elseif _encryption == "wpa2" then encryption = "WPA2-EAP"
    elseif _encryption == "wpa2+ccmp" then encryption = "WPA2-EAP (CCMP)"
    elseif _encryption == "wpa2+tkip+ccmp" then encryption = "WPA2-EAP (TKIP, CCMP)"
    elseif _encryption == "sae" then encryption = "WPA3 Personal"
    elseif _encryption == "sae-mixed" then encryption = "WPA3 Personal Transition"
    elseif _encryption == "wpa3" then encryption = "WPA3 Enterprise"
    elseif _encryption == "wpa3-mixed" then encryption = "WPA3 Enterprise Transition"
    elseif _encryption == "wpa3-192" then encryption = "WPA3 Enterprise 192-bit"
    elseif _encryption == "owe" then encryption = "OWE"
    else encryption = _encryption
    end

    return encryption
end


function acn_util.detected_dongle()
    local fs = require "nixio.fs"
    local supports_3g = product.supports_3g() or false
    if supports_3g then
        return fs.access('/dev/ttyUSB0') or false
    else
        return false
    end
end

function acn_util.ordinal_number( ord_num )
    local ord
    if ord_num == 1 then
        return "1st"
    elseif ord_num == 2 then
        return "2nd"
    elseif ord_num == 3 then
        return "3rd"
    else
        return (ord_num .. "th")
    end
end

function acn_util.has_ipv6()
    return has_ipv6
end

function acn_util.add_nai_realm_div(section, map)
    -- Set current function's environment to the callers so we can access things like
    -- translate, TypedSection, etc...
    setfenv(1, getfenv(2))

    local s = map:section(TypedSection, "nai", translate("Nai Realms"))
    s.addremove = true
    s.anonymous = true
    s.acn_dialog = section
    s.max_count = 4

    -- Use javascript/dynamic add remove template
    s.template = "cbi/tblsection_js"

    s.table_name = "table_nai_realms_" .. section
    s.add_onclick = 'addNaiRealmsRow("' .. section .. '");'
    s.del_onclick = "removeNaiRealmsRow('" .. section .. "',this.id);"

    -- encoding = s:option(Flag, "encoding", translate("Encoding"))
    -- encoding.switch_type = "yes_no"
    -- encoding.default = 0
    -- encoding.custom_attr = "style='width:100px'"

    nai_url = s:option(Value, "url", translate("URL"))
    nai_url.custom_attr = "style='width:100px'"

    nai_method = s:option(ListValue, "method", translate("EAP Methods"))
    nai_method.custom_attr = "style='width:150px'"
    nai_method:value("tls", "TLS")
    nai_method:value("ttls", "TTLS")
    nai_method:value("peap", "PEAP")
    nai_method:value("fast", "FAST")

    nai_auth = s:option(ListValue, "auth", translate("Authentication"))
    nai_auth.custom_attr = "style='width:150px'"

end

function acn_util.hs20_profile(uci_instance)
  local uci = uci_instance or acn_util.cursor()
  local profile_list = {}
  uci:foreach("hotspot20", "profile",
    function (hs20)
      local bined_ssid = ""
      if hs20 then
        profile_list[#profile_list+1] = hs20.name
      end
    end
  )
  return profile_list
end

return acn_util
