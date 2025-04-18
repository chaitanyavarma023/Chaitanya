local acn_status = require "luci.acn.status"
local acn_util = require "luci.acn.util"
local fw_ver = acn_status.version()
local uci = require "luci.model.uci".cursor()

-- JS file for this page
luci.dispatcher.context.page_js = ''
.. '<script src="/javascript/common.js?ver=' .. fw_ver .. '"></script>\n'
.. '<script type="text/javascript"> \n'
.. '</script>\n'
.. '<style>\n'
.. '</style>'

local m, s
m = Map("dhcp", translate("DHCP Relay"))
m:chain("network")

local s = m:section(NamedSection, "dhcprelay", "dhcprelay", "")
s.anonymous = true
s.addremove = false

dhcprelay_enable = s:option(Flag, "enabled", translate("Enable DHCP Relay"))
dhcprelay_enable.rmempty = false

dhcprelay_server1 = s:option( Value, "server_1", translate("DHCP Relay Server"))
dhcprelay_server1:depends("enabled", '1')
dhcprelay_server1.force_required = true
dhcprelay_server1.default = "192.168.10.1"
dhcprelay_server1.datatype = "ip4addr"

dhcprelay_port1 = s:option( Value, "server_port_1", translate("DHCP Relay Port"))
dhcprelay_port1:depends("enabled", '1')
dhcprelay_port1.rmempty = true
dhcprelay_port1.default = "67"
dhcprelay_port1.datatype = "port"
function dhcprelay_port1.write(self, section, value)
--    local radius_mac_auth_status = luci.http.formvalue(vap_pre_form .. "radius_mac_acl")
--    if radius_mac_auth_status then
        return Value.write(self, section, value)
--    end
end

backup_enable = s:option(Flag, "backup_enabled", translate("Backup DHCP Relay"))
backup_enable:depends("enabled", '1')
backup_enable.rmempty = false


dhcprelay_server2 = s:option( Value, "server_2", translate("DHCP Relay Server"))
dhcprelay_server2:depends("backup_enabled", '1')
dhcprelay_server2.force_required = true
dhcprelay_server2.datatype = "ip4addr"

dhcprelay_port2 = s:option( Value, "server_port_2", translate("DHCP Relay Port"))
dhcprelay_port2:depends("backup_enabled", '1')
dhcprelay_port2.rmempty = true
dhcprelay_port2.default = "67"
dhcprelay_port2.datatype = "port"
function dhcprelay_port2.write(self, section, value)
--    local radius_mac_auth_status = luci.http.formvalue(vap_pre_form .. "radius_mac_acl")
--    if radius_mac_auth_status then
        return Value.write(self, section, value)
--    end
end

remote_id = s:option(ListValue, "remote_id", translate("Remote ID"))
remote_id:depends("enabled", "1")
remote_id:value("hostname", translate("Hostname"))
remote_id:value("manual", translate("Manual"))

remote_id_data = s:option( Value, "remote_id_data", translate("Manual Name"))
remote_id_data:depends("remote_id", 'manual')
remote_id_data.datatype = "limited_len_str(1, 32)"

function dhcprelay_enable.write(self, section, value)
    local ignore = "0"

    if value == self.enabled then
        ignore = "1"

        m.uci:foreach("network", "interface",
            function (section)
                if section['.name']:match('^(lan)') or section['.name']:match('^(guest)') or section['.name']:match('^(vlan%d+)') or section['.name']:match('^(custom_%d+)') then
                    if not m.uci:get("network", section['.name'], "circuit_id_data") then
                        m.uci:set("network", section['.name'], "circuit_id", "manual")
                        m.uci:set("network", section['.name'], "circuit_id_data", "br-" .. section['.name'])
                    end
                end
            end)
    else
        m.uci:foreach("network", "interface",
            function (section)
                m.uci:delete("network", section['.name'], "circuit_id")
                m.uci:delete("network", section['.name'], "circuit_id_data")
            end)
    end

    m.uci:foreach("dhcp", "dhcp",
        function (section)
            m.uci:set("dhcp", section['.name'], "ignore", ignore)
        end)

    return Flag.write(self, section, value)
end


return m
