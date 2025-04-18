local ipvalidation = {}

local acn_util   = require("luci.acn.util")
local acn_uci = acn_util.cursor()
local nixio = require "nixio"

function network_prefix(network_short)
    if network_short:match("custom_%d+") then
        local custom_lan_number = tonumber(network_short:match("%d+")) + 1
        return acn_util.ordinal_number(custom_lan_number) .. " custom LAN"
    end
    if network_short == "hotspot" or network_short == "hotspot_tunnel" then return "Hotspot" end
    if network_short == "wan" then return "WAN" end
    if network_short == "wan_gw" then return "WAN gateway" end
    if network_short == "wan_fallback" then return "WAN fallback" end
    if network_short == "lan" then return "default LAN" end
    if network_short == "guest" then return "default guest LAN" end
    if network_short == "mgmt" then return "management VLAN" end
    if network_short == "mgmt_gw" then return "management VLAN gateway" end
    if network_short == "mgmt_fallback" then return "management VLAN fallback" end
    if network_short == "vlantag" then return "WAN VLAN" end
    if network_short == "vlantag_gw" then return "WAN VLAN gateway" end
    if network_short == "vlantag_fallback" then return "WAN VLAN fallback" end
    -- prevent the null issue.
    return network_short
end


function wan_ipdata()
  local dr4 = luci.sys.net.defaultroute()
  local wan_runtime_info = {}
  if dr4 and dr4.device then
      local ntm = require "luci.model.network".init()
      wan = ntm:get_interface(dr4.device)
      local wan_network = wan and wan:get_network()
      if wan_network then
          wan_runtime_info['ip'] = wan_network:ipaddr()
          wan_runtime_info['nm'] = wan_network:netmask()
          wan_runtime_info['gw_ip'] = wan_network:gwaddr()
      end
  end
  return wan_runtime_info
end

function ipvalidation.getipdata()
    local ipdata = {}
    ipdata["hotspot"] = {}
    ipdata["hotspot"]["ip"] = acn_uci:get('hotspot', 'hotspot', 'listen') or ''
    ipdata["hotspot"]["nm"] = acn_uci:get('hotspot', 'hotspot', 'dynip_mask') or ''
    ipdata["lan"] = {}
    ipdata["lan"]["ip"] = acn_uci:get('network', 'lan', 'ipaddr') or ''
    ipdata["lan"]["nm"] = acn_uci:get('network', 'lan', 'netmask') or ''
    ipdata["guest"] = {}
    ipdata["guest"]["ip"] = acn_uci:get('network', 'guest', 'ipaddr') or ''
    ipdata["guest"]["nm"] = acn_uci:get('network', 'guest', 'netmask') or ''
    ipdata["wan"] = {}
    ipdata["wan_gw"] = {}
    ipdata["wan"]["proto"] = acn_uci:get("network", "wan", "proto") or ""
    ipdata["wan_fallback"] = {}
    ipdata["wan_fallback"]["ip"] = acn_uci:get("network", "wan", "fallback_ip") or ""
    ipdata["wan_fallback"]["nm"] = acn_uci:get("network", "wan", "fallback_nm") or ""
    if ipdata["wan"]["proto"] == "static" then
        ipdata["wan"]["ip"] = acn_uci:get("network", "wan", "ipaddr") or ""
        ipdata["wan"]["nm"] = acn_uci:get("network", "wan", "netmask") or ""
        ipdata["wan_gw"]["ip"] = acn_uci:get("network", "wan", "gateway") or ""
        ipdata["wan_gw"]["nm"] = ipdata["wan"]["nm"]
    else -- TODO retrieve WAN data when receiving IP from DHCP server
        local wan_data = wan_ipdata()
        ipdata["wan"]["ip"] = wan_data["ip"] or ''
        ipdata["wan"]["nm"] = wan_data["nm"] or ''
        ipdata["wan_gw"]["ip"] = wan_data["gw_ip"] or ''
        ipdata["wan_gw"]["nm"] = wan_data["nm"] or '' -- gw and device are in same WAN subnet
    end
    local mgmt_vlan_proto = acn_uci:get("network", "managementvlan", "proto")
    if mgmt_vlan_proto then
        ipdata["mgmt"] = {}
        ipdata["mgmt_gw"] = {}
        ipdata["mgmt"]["proto"] = mgmt_vlan_proto
        ipdata["mgmt"]["ip"] = acn_uci:get("network", "managementvlan", "ipaddr") or ''
        ipdata["mgmt"]["nm"] = acn_uci:get("network", "managementvlan", "netmask") or ''
        ipdata["mgmt_gw"]["ip"] = acn_uci:get("network", "managementvlanroute", "gateway") or ''
        ipdata["mgmt_gw"]["nm"] = ipdata["mgmt"]["nm"]
        if mgmt_vlan_proto ~= "static" then
            -- TODO get Mgmt VLAN ip received from DHCP server
            ipdata["mgmt_fallback"] = {}
            ipdata["mgmt_fallback"]["ip"] = acn_uci:get("network", "managementvlan", "fallback_ip") or ''
            ipdata["mgmt_fallback"]["nm"] = acn_uci:get("network", "managementvlan", "fallback_nm") or ''
        end
    end

    local vlantag_proto = acn_uci:get("network", "wanvlan", "proto")
    if vlantag_proto then
        ipdata["vlantag"] = {}
        ipdata["vlantag_gw"] = {}
        ipdata["vlantag"]["proto"] = vlantag_proto
        ipdata["vlantag"]["ip"] = acn_uci:get("network", "wanvlan", "ipaddr") or ''
        ipdata["vlantag"]["nm"] = acn_uci:get("network", "wanvlan", "netmask") or ''
        ipdata["vlantag_gw"]["ip"] = acn_uci:get("network", "wanvlan", "gateway") or ''
        ipdata["vlantag_gw"]["nm"] = ipdata["vlantag"]["nm"]
        if vlantag_proto ~= "static" then
            -- TODO get WAN VLAN ip received from DHCP server
            ipdata["vlantag_fallback"] = {}
            ipdata["vlantag_fallback"]["ip"] = acn_uci:get("network", "wanvlan", "fallback_ip") or ''
            ipdata["vlantag_fallback"]["nm"] = acn_uci:get("network", "wanvlan", "fallback_nm") or ''
        end
    end

    local MAX_CUSTOM_LANS = 10
    custom_lan_data = ""
    for i = 0, (MAX_CUSTOM_LANS - 1) do
        local custom_lan_name = "custom_" .. i
        local custom_lan = acn_uci:get('network', custom_lan_name, 'proto')
        if custom_lan then
            local custom_lan_descr = network_prefix(custom_lan_name)
            ipdata[custom_lan_name] = {}
            ipdata[custom_lan_name]["ip"] = acn_uci:get('network', custom_lan_name, 'ipaddr')
            ipdata[custom_lan_name]["nm"] = acn_uci:get('network', custom_lan_name, 'netmask')
        end
    end

    local iface_alias_counter = {}
    acn_uci:foreach("network","alias",
        function (alias)
            local alias_iface = alias.interface
            iface_alias_counter[alias_iface] = (iface_alias_counter[alias_iface] or 0) + 1
            local alias_number = iface_alias_counter[alias_iface]
            local alias_ipdata = {}
            alias_ipdata["ip"] = alias.ipaddr
            alias_ipdata["nm"] = alias.netmask
            alias_prefix = alias_iface .. "-alias_" .. tostring(alias_number)
            alias_ipdata["friendly"] = network_prefix(alias_iface) .." network " .. acn_util.ordinal_number(alias_number) .. " alias"
            ipdata[alias_prefix] = alias_ipdata
        end
    )
    for k,v in pairs(ipdata) do
        if not ipdata[k]["friendly"] then ipdata[k]["friendly"] = network_prefix(k) end
    end
    return ipdata
end

return ipvalidation