
require("luci.sys")
require("luci.util")

local fs = require "nixio.fs"
local utl = require "luci.util"
local product = require "luci.acn.product"
local acn = require "luci.acn.util"
local acn_status = require "luci.acn.status"
local fw_ver = acn_status.version()
local flag = 0

m = Map("ethernet", translate("Ethernet Settings"))
luci.dispatcher.context.page_js = ''
.. '<script src="' .. luci.config.main.resourcebase .. '/common.js?ver=' .. fw_ver .. '"></script>\n'
.. '<script src="' .. luci.config.main.mediaurlbase .. '/js/ethernet.js?ver=' .. fw_ver .. '"></script>\n'

local map_render = m.render

m.render = function(...)
    luci.template.render("cbi/eth_header")
    map_render(...)
end

local logical_name_arr = ""

for k=0, product.num_eth_ports -1 do
    local eth = product.eth(k)
    local dev_name = eth['dev_name']
    local logical_name = eth['logical_name']

    if logical_name_arr ~= "" then
        logical_name_arr = logical_name_arr .. ","
    end
    logical_name_arr = logical_name_arr .. "'" .. logical_name .. "'"

    s = m:section(TypedSection, "eth_port", acn.eth_to_friendly(k))

    s.template = "cbi/eth"
    s.num_ports = product.num_eth_ports

    s.dev_name = dev_name
    s.logical_name = logical_name

    s.dev_id = k

    s.addremove = false
    s.anonymous = true
    s:depends(".name", logical_name)
    s.defaults.dev = logical_name

    -- internet src alert area (want it in different place other than default, so adding manually)
    acn.add_inet_src_alert(s, logical_name)

    --[[ status = s:option(Flag, "status", translate("Status"))
    status.rmempty = false

    function status.write(self, section, value)
        local write_status = m.uci:set("ethernet", section, "status", value)
        m.uci:set("network", section, "enabled", value)
        m.uci:save("network")
        return write_status
    end ]]

    -- #10565 - added VLAN control, but without Dynamic VLAN
    acn.add_net_access_section(s, m, "ethernet", logical_name, 'no_dynamic_vlan')

    if eth['poe_out'] then
        poe_out = s:option(Flag, "poe_out", translate("PoE Out"))
        poe_out.rmempty = false
    end

    local vlan_tag_iface_error = s:option(DummyValue, "vlan_tag_iface_error","")
    vlan_tag_iface_error.template     = "cbi/vlan_tag_iface_error"
    vlan_tag_iface_error.logical_name = logical_name

    local wan_bridge_iface_error = s:option(DummyValue, "wan_bridge_iface_error", "")
    wan_bridge_iface_error.template = "cbi/wan_bridge_iface_error"
    wan_bridge_iface_error.name = logical_name

    -- we can't change autoneg/speed for SFP, otherwise it stops working #5399
    --[[ if eth["type"] ~= "SFP" then
        auto_nego = s:option(Flag, "auto_nego", translate("Auto-negotiation"))
        auto_nego.rmempty = false

        link_speed = s:option(ListValue, "link_speed", translate("Link Speed"))
        link_speed:depends("auto_nego", "1")
        link_speed:value("10Mbps")
        link_speed:value("100Mbps")
        link_speed:value("1Gbps")

        local max_speed = eth['max']
        if max_speed and max_speed == 2500 then
          link_speed:value("2.5Gbps")
        end

        full_duplex = s:option(Flag, "full_duplex", translate("Full Duplex"))
        full_duplex.rmempty = false
        full_duplex:depends("auto_nego", "1")
    end ]]

end
local _uci = acn.cursor()
local vlan_ifaces_data = ''

_uci:foreach("network", "interface",
    function(i_section)
        local ifc = i_section[".name"]
        if ifc:match('vlan%d+') then
            if vlan_ifaces_data ~= '' then vlan_ifaces_data = vlan_ifaces_data .. ', ' end
            if i_section.ifname then
                if product.is_EAP104() then
                    local vlan_ports = acn.vlan_ports(_uci, ifc)
                    vlan_ifaces_data = vlan_ifaces_data .. '"' .. ifc .. '" : "' .. i_section.ifname .. " " .. table.concat(vlan_ports, " ") ..'"'
                else
                    vlan_ifaces_data = vlan_ifaces_data .. '"' .. ifc .. '" : "' .. i_section.ifname ..'"'
                end
            end
        end
    end
)

local wan_proto = _uci:get("network", "wan", "proto")
luci.dispatcher.context.page_js = luci.dispatcher.context.page_js .. "<script>\n"
.. "var logical_name_arr = [" .. logical_name_arr .. "];\n"
.. 'var vlan_ifaces = {' .. vlan_ifaces_data .. "};" .. "\n"
.. "var wan_proto = \""..wan_proto.."\";\n"
.. "</script>\n"

return m
