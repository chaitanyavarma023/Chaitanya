local product = require("luci.acn.product")
local acn_status = require "luci.acn.status"
local acn_util = require("luci.acn.util")
local util = require("luci.util")
local json = require "cjson.safe"
local acn_uci = acn_util.cursor()
local datatypes = require("luci.cbi.datatypes")

local is_sunspot = product.is_sunspot()
local support_ipv6 = acn_util.has_ipv6()
local fw_ver = acn_status.version()
local is_mgmt_vlan_disabled = not acn_util.is_mgmt_vlan_enabled()

-- Built in firewall rule names
local FW_SNMP_NAME         = 'Allow-SNMP'
local FW_SNMP_NAME_IPV6    = 'Allow-SNMP-IPv6'
local FW_TELNET_NAME     = 'Allow-Telnet'
local FW_SSH_NAME         = 'Allow-SSH'
local FW_HTTP_NAME         = 'Allow-WEBUI'
local FW_HTTPS_NAME     = 'Allow-WEBUI-secure'
local FW_DISCOVER_MCAST_NAME = 'Allow-Multicast-Discovery'
local FW_DISCOVER_BCAST_NAME = 'Allow-Broadcast-Discovery'

local has_snmpd =  nixio.fs.access("/usr/sbin/snmpd")
local has_ping_watchdog = nixio.fs.access("/usr/bin/ping_watchdog.lua")
local has_ibeacon = nixio.fs.access("/etc/config/ibeacon")
local has_umdns = nixio.fs.access("/usr/sbin/umdns")
local has_lldp = nixio.fs.access("/usr/sbin/lldpd")
local is_EAP101 = product.is_EAP101()
local is_EAP102 = product.is_EAP102()
local is_EAP104 = product.is_EAP104()
local is_OAP103 = product.is_OAP103()
local is_EAP104_lowcost = product.is_EAP104_lowcost()


if is_sunspot then
    support_ipv6 = true
end

-- For SNMP
local max_count = 20
-- End

luci.dispatcher.context.modal_template = luci.dispatcher.context.modal_template or {}
luci.dispatcher.context.modal_template[#luci.dispatcher.context.modal_template + 1] = "cbi/ble_scan_modal"

luci.dispatcher.context.page_js = '<script src="' .. luci.config.main.mediaurlbase .. '/js/service.js?ver="></script>\n'
.. '<script src="' .. luci.config.main.resourcebase .. '/common.js?ver="></script>\n'
.. '<script src="' .. luci.config.main.mediaurlbase .. '/js/snmpv3.js?ver="></script>\n'
.. '<script type="text/javascript"> \n'
..      "var ble_scan_url ='" .. luci.dispatcher.build_url("admin", "system", "ble_scan") .. "';\n"
.. '    var MAX_COUNT = ' .. max_count .. ';\n'
.. '</script>\n'

local perm_fw_rules = {}
--==============================================================================
--SSH
m_ssh = Map("dropbear", translate("Services"), "")
m_ssh:chain("firewall")

s = m_ssh:section(TypedSection, "dropbear", translate("SSH"))
s.anonymous = true
s.addremove = false

en = s:option(Flag, "enable", translate("SSH Server"))
pt = s:option(Value, "Port", translate("Port"))

if is_mgmt_vlan_disabled then
    local fw_ssh = s:option(Flag, "ssh_rule", translate("Allow SSH from WAN"))
    fw_ssh:depends("enable", "1")
    fw_ssh.rmempty = false -- Need this to force it to call write()
    fw_ssh.old_checkbox = true
    -- Firewall rule to allow ssh from the WAN
    fw_ssh.cfgvalue = function (self, section)
        return perm_fw_rules[FW_SSH_NAME] and "1" or "0"
    end

    fw_ssh.write = function (self, section, value)
        local port = self.map.uci:get("dropbear", "@dropbear[0]", "Port") or "22"
        return write_fw_rule(self, section, value, FW_SSH_NAME, port, "tcp")
    end
end

en.rmempty = false
pt.default  = 22
pt:depends("enable", "1")

m_ssh.uci:foreach("firewall", "rule",
    function(fw)
        if fw.name then
            perm_fw_rules[fw.name] = fw
        end
    end
)

function write_fw_rule(self, section, value, fw_rule_name, port, proto, dest_ip)

    local val = self.enabled == value
    local rule = perm_fw_rules[fw_rule_name]

    -- Add rule
    if val and not rule then

        -- Create our anon section
        local cfg_name = self.map.uci:add("firewall", "rule")

        if cfg_name then
            self.map.uci:set("firewall", cfg_name, "enabled", "1")
            self.map.uci:set("firewall", cfg_name, "name", fw_rule_name)
            self.map.uci:set("firewall", cfg_name, "src", "wan")
            self.map.uci:set("firewall", cfg_name, "proto", proto)

            if port ~= "" then
                self.map.uci:set("firewall", cfg_name, "dest_port", port)
            end

            if dest_ip then
                self.map.uci:set("firewall", cfg_name, "dest_ip", dest_ip)
               end

            self.map.uci:set("firewall", cfg_name, "target", "ACCEPT")
            if support_ipv6 and fw_rule_name == FW_SNMP_NAME_IPV6 then
                self.map.uci:set("firewall", cfg_name, "family", "ipv6")
            else
                self.map.uci:set("firewall", cfg_name, "family", "ipv4")
            end

            self.map.uci:save("firewall")
            self.map.uci:load("firewall")

            -- This is only used by cfgvalue in the UI
            perm_fw_rules[fw_rule_name] = cfg_name
        end
    end

    -- Remove rule
    if not val and rule then
        self.map.uci:delete("firewall", rule[".name"] )
        -- Unset
        perm_fw_rules[fw_rule_name] = nil
        -- kill current sessions
        luci.sys.call("/etc/init.d/dropbear killclients >/dev/null 2>&1")
    end

end

-- Generic function for setting firewall ports for these services
function write_fw_port(self, section, value, fw_rule_name)

    if perm_fw_rules[fw_rule_name]  then
        local rule = perm_fw_rules[fw_rule_name]
        local rule_name = ""

        if type(rule) == "string" then
            rule_name = rule
        elseif type(rule) == "table" then
            rule_name  = rule[".name"]
        end

        self.map.uci:set("firewall", rule_name, "dest_port", value)
    end

    return Value.write(self, section, value)
end

function pt.write(self, section, value)
    return write_fw_port(self, section, value, FW_SSH_NAME)
end

--==============================================================================
--telnet
m_telnet = Map("telnetd", "","")
m_telnet:chain("firewall")

s_telnet = m_telnet:section(TypedSection, "telnetd", translate("Telnet"))
s_telnet.anonymous = true
s_telnet.addremove = false

tel_en = s_telnet:option(Flag, "enable", translate("Telnet Server"))
tel_en.rmempty = false

tel_pt = s_telnet:option(Value, "Port", translate("Port"))

tel_pt:depends("enable", "1")
tel_pt.default  = 23

if is_mgmt_vlan_disabled then
    fw_telnet = s_telnet:option(Flag, "telnet_rule", translate("Allow Telnet from WAN"))
    fw_telnet.rmempty = false
    fw_telnet:depends("enable", "1")
    fw_telnet.old_checkbox = true
    -- Firewall rule to allow ssh from the WAN
    fw_telnet.cfgvalue = function (self, section)
        return perm_fw_rules[FW_TELNET_NAME] and "1" or "0"
    end

    fw_telnet.write = function (self, section, value)
        local port = tel_pt:formvalue("cbid.telnetd." .. section .. ".Port") or
            self.map.uci:get("telnetd", section, "Port") or "23"
        return write_fw_rule(self, section, value, FW_TELNET_NAME, port, "tcp")
    end
end

function tel_pt.write(self, section, value)
    return write_fw_port(self, section, value, FW_TELNET_NAME)
end

--==============================================================================
--DISCOVERY Tool

m_discover = Map("acn", "", "")
m_discover:chain("firewall")

s_discover = m_discover:section(NamedSection, "discovery", "acn", product.company_name() .. " Discovery Tool")
s_discover.anonymous = false
s_discover.addremove = false
s_discover.sub_title_class = true

discover_enable = s_discover:option(Flag, "enabled", translate("Discovery Agent"))
discover_enable.rmempty = false

discover_enable.write = function(self, section, value)
    -- uci set acn.discovery.enabled='0'
    self.map.uci:set("acn", section, "enabled", value)

    write_fw_rule(self, section, value, FW_DISCOVER_MCAST_NAME, "17371", "udp", "233.89.188.1" )
    return write_fw_rule(self, section, value, FW_DISCOVER_BCAST_NAME, "17371", "udp", "255.255.255.255")

end

--==============================================================================
--Web server port
m_httpd = Map("uhttpd", "","")
m_httpd:chain("firewall")

s4 = m_httpd:section(TypedSection, "uhttpd", translate("Web server"))
s4.anonymous = true
s4.addremove = false

http_pt = s4:option(Value, "listen_http", translate("Http Port"))
--http_pt.datatype = "port"
http_pt.default  = 80

if is_mgmt_vlan_disabled then
    fw_http = s4:option(Flag, "http_rule", translate("Allow HTTP from WAN"))
    fw_http.rmempty = false
    fw_http.old_checkbox = true
    -- Firewall rule to allow web access from the WAN
    fw_http.cfgvalue = function (self, section)
        return perm_fw_rules[FW_HTTP_NAME] and "1" or "0"
    end

    fw_http.write = function (self, section, value)
        local port =  fw_http:formvalue("cbid.uhttpd.main.listen_http")  or
            self.map.uci:get("uhttpd", section, "listen_http") or "80"
        return write_fw_rule(self, section, value, FW_HTTP_NAME, port, "tcp")
    end
end

https_pt = s4:option(Value, "listen_https", translate("Https Port"))
--https_pt.datatype = "port"
https_pt.default  = 443

if is_mgmt_vlan_disabled then
    fw_https = s4:option(Flag, "https_rule", translate("Allow HTTPS from WAN"))
    fw_https.rmempty = false
    fw_https.old_checkbox = true
    -- Firewall rule to allow secure web access from the WAN
    fw_https.cfgvalue = function (self, section)
        return perm_fw_rules[FW_HTTPS_NAME] and "1" or "0"
    end

    fw_https.write = function (self, section, value)
        local port = fw_https:formvalue("cbid.uhttpd.main.listen_https") or
            self.map.uci:get("uhttpd", section, "listen_https") or "443"
        return write_fw_rule(self, section, value, FW_HTTPS_NAME, port, "tcp")
    end
end

function http_pt.write(self, section, value)
    return write_fw_port(self, section, value, FW_HTTP_NAME)
end

function https_pt.write(self, section, value)
    return write_fw_port(self, section, value, FW_HTTPS_NAME)
end
--==============================================================================
--Time / NTP
require("luci.sys")
require("luci.sys.zoneinfo")
require("luci.tools.webadmin")
require("luci.config")

local m_ntp, s3, o, o1, o2, o3
local has_ntpd = nixio.fs.access("/usr/sbin/ntpd")

m_ntp = Map("system", "", "")
m_ntp:chain("luci")

if has_ntpd then

    s3 = m_ntp:section(TypedSection, "timeserver", translate("Network Time (NTP)"))
    s3.anonymous = true
    s3.addremove = false

    o = s3:option( DummyValue, "_systime", translate("Local Time"))
    o.template = "cbi/clock_time"

    s4 = m_ntp:section(TypedSection, "system", "")
    s4.anonymous = true

    o1 = s4:option( ListValue, "zonename", translate("Timezone"))

    o1:value("UTC")

    for i, zone in ipairs(luci.sys.zoneinfo.TZ) do
        o1:value(zone[1])
    end

    function o1.write(self, section, value)
        local function lookup_zone(title)
            for _, zone in ipairs(luci.sys.zoneinfo.TZ) do
                if zone[1] == title then return zone[2] end
            end
        end

        AbstractValue.write(self, section, value)
        local timezone = lookup_zone(value) or "GMT0"
        self.map.uci:set("system", section, "timezone", timezone)
        nixio.fs.writefile("/etc/TZ", timezone .. "\n")
    end

    o2 = s3:option(Flag, "enable_server", translate("NTP Service"))
    o2.rmempty = false

    o3 = s3:option(DynamicList, "server", translate("NTP servers"))
    o3.datatype = "host"
    o3:depends("enable_server", "1")

    -- retain server list even if disabled
    function o3.remove() end

end

--==============================================================================
--IGMP Snooping
--==============================================================================
--[[local m_igmp, s_igmp
m_igmp = Map("network", "", "")

s_igmp = m_igmp:section(TypedSection,  "interface", translate("IGMP Snooping"))
s_igmp:depends(".name", "lan")
s_igmp.anonymous = true
s_igmp.addremove = false

igmp_snooping = s_igmp:option(Flag, "igmp_snooping", translate("Enable IGMP Snooping"))
igmp_snooping.rmempty = false]]

--==============================================================================
--Ping Watchdog
local m_ping_watchdog, s5
m_ping_watchdog = Map("ping_watchdog", "", "")

if has_ping_watchdog then
    m_ping_watchdog:chain("system")

    s5 = m_ping_watchdog:section(TypedSection, "settings", translate("Ping Watchdog"))
    s5.anonymous = true
    s5.addremove = false

    ping_en = s5:option(Flag, "enabled", translate("Enable Ping Watchdog"))
    ping_en.rmempty = false

    ping_ip = s5:option(Value, "ip", translate("IP Address"))
    ping_ip.datatype = "ip4addr"
    ping_ip.default  = "192.168.2.1"
    ping_ip.force_required = true
    ping_ip:depends("enabled","1")

    failover_ip = s5:option(Value, "failover_ip", translate("Failover IP Address"))
    failover_ip.datatype = "ip4addr"
    failover_ip.default  = ""
    failover_ip.help_tip = "The (optional) failover IP address to ping if a ping probe to the the primary IP fails. Note: if the failover IP can successfully be pinged, the fail counter will reset to 0 again."
    failover_ip:depends("enabled","1")

    ping_interval = s5:option(Value, "ping_period", translate("Interval (min)"))
    ping_interval.datatype = "range(1,60)"
    ping_interval.default  = 1
    ping_interval.help_tip = "How often, in minutes, a ping check should be made."
    ping_interval.force_required = true
    ping_interval:depends("enabled", "1")

    ping_num = s5:option(Value, "count", translate("Failure count"))
    ping_num.datatype = "range(1,100)"
    ping_num.default  = 5
    ping_num.help_tip = "The number of consecutive pings that must fail before the device is rebooted."
    ping_num.force_required = true
    ping_num:depends("enabled", "1")
end

--==============================================================================
-- SNMP
local m_snmp = Map("snmpd", "", "")

if has_snmpd then
    local s6_enable, s6_ro_community, s6_community, s6_ro_ipv6community, s6_ipv6community, s6_wan, s6_public, s6_trap
    m_snmp:chain("firewall")

    s6_enable = m_snmp:section(TypedSection, "agent", translate("SNMP"))
    s6_enable.anonymous = true
    s6_enable.addremove = false

    snmp_en = s6_enable:option(Flag, "enabled", translate("SNMP Server"))
    snmp_en.rmempty = false

    --Community
    s6_ro_community = m_snmp:section(TypedSection, "ro_community", "")
    s6_ro_community.anonymous = true
    snmp_ro_com = s6_ro_community:option(Value, "name", translate("Read Community"))
    snmp_ro_permission = s6_ro_community:option(Value, "permission", translate("permission"))
    snmp_ro_permission.header_style = "display:none" -- not show in GUI

    s6_community = m_snmp:section(TypedSection, "rw_community", "")
    s6_community.anonymous = true
    snmp_com = s6_community:option(Value, "name", translate("Write Community"))
    snmp_permission = s6_community:option(Value, "permission", translate("permission"))
    snmp_permission.header_style = "display:none" -- not show in GUI

    if support_ipv6 then
        -- Community ipv6
        s6_ro_ipv6community = m_snmp:section(TypedSection, "ro_community6", "")
        s6_ro_ipv6community.anonymous = true
        snmp_ro_ipv6com = s6_ro_ipv6community:option(Value, "name", translate("IPv6 Read Community"))
        snmp_ro_ipv6permission = s6_ro_ipv6community:option(Value, "permission", translate("permission"))
        snmp_ro_ipv6permission.header_style = "display:none" -- not show in GUI

        s6_ipv6community = m_snmp:section(TypedSection, "rw_community6", "")
        s6_ipv6community.anonymous = true
        snmp_ipv6com = s6_ipv6community:option(Value, "name", translate("IPv6 Write Community"))
        snmp_ipv6permission = s6_ipv6community:option(Value, "ipv6permission", translate("permission"))
        snmp_ipv6permission.header_style = "display:none" -- not show in GUI

        function snmp_ipv6com.cfgvalue(self, section)
            local com = m_snmp.uci:get("snmpd", section, "name")
            return com
        end

        function snmp_ipv6com.write(self, section, value)
            m_snmp.uci:set("snmpd", section, "name", value)
        end

        function snmp_ipv6permission.cfgvalue(self, section)
            local com = m_snmp.uci:get("snmpd", section, "permission")
            return com
        end

        function snmp_ipv6permission.write(self, section, value)
            m_snmp.uci:set("snmpd", section, "permission", value)
        end
    end

    -- Trap
    s6_trap = m_snmp:section(TypedSection, "snmp_trap", "")
    s6_trap.anonymous = true
    snmp_trap = s6_trap:option(Flag, "enable", translate("Trap"))
    snmp_trap.rmempty = false
    snmp_trap.default = false

    -- Server IP: If the text is not the valid IP, please show the error message "Not a valid IP address".
    snmp_server_ip = s6_trap:option(Value, "server_ip", translate("Server IP"))
    snmp_server_ip.rmempty = false
    snmp_server_ip:depends("enable", "1")
    snmp_server_ip.datatype = "ip4addr"

-- SNMPV3 Users list
    s6_users = m_snmp:section(TypedSection, "user", "")
    s6_users.addremove = true
    s6_users.anonymous = true

    s6_users.template = "cbi/tblsection_js"
    s6_users.add_btn_small = true
    s6_users.add_btn_location = "bottom"
    s6_users.table_name = "table_snmpV3users"
    s6_users.no_stripe = true
    s6_users.add_onclick = "addUserRow();"
    s6_users.del_onclick = "removeSnmpV3UserRow(this.id);"
    s6_users.max_count = max_count
    s6_users.title = "SNMP V3 User"
    s6_users.title_fontsize = "h5"
    s6_users.title_margin = "margin-left:20px"

    snmp_user_name = s6_users:option(Value, "name", translate("Name"))
    snmp_user_access_auth = s6_users:option(ListValue, "permission", translate("Access Auth."))
    snmp_user_auth_type = s6_users:option(ListValue, "authen", translate("Auth. Type"))
    snmp_user_auth_pwd = s6_users:option(Value, "authenpw", translate("Auth. Pwd"))
    snmp_user_encry_type = s6_users:option(ListValue, "encryp", translate("Encrytion Type"))
    snmp_user_encry_pwd = s6_users:option(Value, "encryppw", translate("Encrytion Pwd"))

    snmp_user_name.force_required = true
    snmp_user_name.custom_attr = "style='width:70px'"

    snmp_user_access_auth:value("rw", translate("Write"))
    snmp_user_access_auth:value("ro", translate("Read"))
    snmp_user_access_auth.custom_attr = "style='width:80px'"

    snmp_user_auth_type:value("MD5", translate("MD5"))
    -- snmp_user_auth_type:value("SHA", translate("SHA"))
    snmp_user_auth_type.custom_attr = "style='width:80px'"

    snmp_user_auth_pwd.force_required = true
    snmp_user_auth_pwd.password = true
    snmp_user_auth_pwd.custom_attr = "style='width:80px'"

    snmp_user_encry_type:value("DES", translate("DES"))
    -- snmp_user_encry_type:value("AES", translate("AES"))
    snmp_user_encry_type.custom_attr = "style='width:80px'"

    snmp_user_encry_pwd.force_required = true
    snmp_user_encry_pwd.password = true

--     s6_wan = m_snmp:section(TypedSection, "system", "")
--     s6_wan.anonymous = true

--     if is_mgmt_vlan_disabled then
--         fw_snmp = s6_wan:option(Flag, "snmp_rule", translate("Allow SNMP from WAN"))
--         fw_snmp.rmempty = false
--         fw_snmp.old_checkbox = true
--         fw_snmp:depends("enable", "1")
--         --Firewall rule to allow ssh from the WAN
--         fw_snmp.cfgvalue = function (self, section)
--             if perm_fw_rules[FW_SNMP_NAME] then
--                 return "1"
--             else
--                 return "0"
--             end
--         end

--         fw_snmp.write = function (self, section, value)
--             local port =  "161"
--             if support_ipv6 then
--                 write_fw_rule(self, section, value, FW_SNMP_NAME_IPV6, port, "udp")
--             end
--             return write_fw_rule(self, section, value, FW_SNMP_NAME, port, "udp")
--         end
--     end

    -- save form
    local runned_s_parse = false

    s6_users.parse = function(self, nvld)
        if not runned_s_parse then
            runned_s_parse = true

            -- Have to do this first
            TypedSection.parse(self, nvld)

            local add_prefix = "acn.new"
            local del_prefix = "acn.del"

            -- This gets a list of all form values that begin with the prefix
            local new_users = self.map:formvaluetable(add_prefix)

            -- want these sorted
            local keys = {}
            for k in pairs(new_users) do
                keys[#keys+1] = k
            end

            table.sort(keys, function(a,b)
                return new_users[a] < new_users[b]
            end)

            -- Need to use map.uci here so that the settings are saved
            for i,k in ipairs(keys) do
                local v = new_users[k]
                -- value is our client-side generated section name (like 45f30e)
                if v then
                    -- v = cfg used for the temporary row
                    local username = self.map:formvalue('cbid.snmpd.cfg' .. v .. '.name')
                    local permission = self.map:formvalue('cbid.snmpd.cfg' .. v .. '.permission')
                    local authen = self.map:formvalue('cbid.snmpd.cfg' .. v .. '.authen')
                    local authenpw = self.map:formvalue('cbid.snmpd.cfg' .. v .. '.authenpw')
                    local encryp = self.map:formvalue('cbid.snmpd.cfg' .. v .. '.encryp')
                    local encryppw = self.map:formvalue('cbid.snmpd.cfg' .. v .. '.encryppw')

                    if username and #username > 0 and authenpw and #authenpw > 0 and encryppw and #encryppw > 0 then
                        -- Create our anon section
                        local section = acn_uci:add("snmpd", "user")
                        if section then
                            acn_uci:set("snmpd", section, "name", username)
                            acn_uci:set("snmpd", section, "permission", permission)
                            acn_uci:set("snmpd", section, "authen", authen)
                            acn_uci:set("snmpd", section, "authenpw", authenpw)
                            acn_uci:set("snmpd", section, "encryp", encryp)
                            acn_uci:set("snmpd", section, "encryppw", encryppw)
                            acn_uci:set("snmpd", section, "seclevel", "priv")
                            acn_uci:set("snmpd", section, "view", "all")

                            -- If we don't do the save/load below, something messes up the internal counter
                            -- and uci sections start overwriting each other (see #497)
                            acn_uci:save("snmpd")
                            acn_uci:load("snmpd")
                        end
                    end
                end
            end

            table = self.map:formvaluetable(del_prefix .. ".snmpd")

            -- Need to use map.uci here so that the settings are saved correctly
            for k, v in pairs(table) do
                if v and (v == "1" or v == 1) then
                    self.map.uci:delete("snmpd", k)
                end
            end
            acn_uci:save("snmpd")
            acn_uci:load("snmpd")

        end
    end
end

--==============================================================================
-- Remote Log
--==============================================================================
local m_remotelog, s_remotelog

m_remotelog = Map("system", "", "")
m_remotelog:chain("luci")

s_remotelog = m_remotelog:section(TypedSection, "system", translate("Remote System Log Setup"))
s_remotelog.anonymous = true
s_remotelog.addremove = false

remote_log_enable = s_remotelog:option( Flag, "log_remote", translate("Remote Syslog"))
remote_log_enable.rmempty = false

remote_log_ip = s_remotelog:option( Value, "log_ip", translate("Server IP"))
remote_log_ip.datatype    = "ipaddr"
remote_log_ip.force_required = true
remote_log_ip:depends("log_remote", "1")

remote_log_port = s_remotelog:option( Value, "log_port", translate("Server Port"))
remote_log_port.datatype    = "port"
remote_log_port.force_required = true
remote_log_port:depends("log_remote", "1")

remote_log_prefix = s_remotelog:option(Value, "log_prefix", translate("Log Prefix"))
remote_log_prefix.datatype = "limited_len_str(0, 255)"
remote_log_prefix:depends("log_remote", "1")

remote_conntrackd_enable = s_remotelog:option(Flag, "log_conntrackd_enable", translate("Track Connections"))
remote_conntrackd_enable.rmempty = false
remote_conntrackd_enable:depends("log_remote", "1")

-- mDNS
local m_mdns, s_mdns

m_mdns = Map("umdns", "", "")
if has_umdns then
  s_mdns = m_mdns:section(TypedSection, "umdns", translate("Multicast DNS"))
  s_mdns.anonymous = true
  s_mdns.addremove = false

  mdns_enable = s_mdns:option(Flag, "enabled", translate("mDNS"))
  mdns_enable.rmempty = false
end

-- LLDP
local m_lldp, s_lldp

m_lldp = Map("lldp", "", "")
if has_lldp then
    s_lldp = m_lldp:section(TypedSection, "lldp", translate("LLDP"))
    s_lldp.anonymous = true
    s_lldp.addremove = false

    lldp_enable = s_lldp:option(Flag, "enabled", translate("Send LLDP"))
    lldp_enable.rmempty = false

    tx_interval = s_lldp:option(Value, "tx_interval", translate("Tx Interval (seconds)"))
    tx_interval.default = 30
    tx_interval.datatype = "range(5, 32768)"
    tx_interval:depends("enabled", "1")

    tx_hode = s_lldp:option(Value, "tx_hold", translate("Tx Hold (time(s))"))
    tx_hode.default = 4
    tx_hode.datatype = "range(2, 10)"
    tx_hode:depends("enabled", "1")
end

-- iBeacon
local m_ibeacon, s_ibeacon

m_ibeacon = Map("ibeacon", "", "")
if has_ibeacon and is_EAP104_lowcost == false then
    s_ibeacon = m_ibeacon:section(TypedSection, "ibeacon", translate("BLE"))
    s_ibeacon.anonymous = true
    s_ibeacon.addremove = false

    ibeacon_enable = s_ibeacon:option(Flag, "enabled", translate("Send iBeacon"))
    ibeacon_enable.rmempty = false

    uuid = s_ibeacon:option(Value, "uuid", translate("UUID"))
    uuid.default = "e2c56db5dffb48d2b060d0f5a71096e0"
    uuid:depends("enabled", "1")
    uuid.render =  function(self, s, scope)
        luci.template.render("cbi/valueheader", {section = s, self = self})
        self.custom = "style=\"width:130px\" maxlength=\"8\""
        self.template = "cbi/value_inline"
        AbstractValue.render(self, s, nil)
        luci.http.write(' - <input title="" autocomplete="off" type="text" class="ace-tooltip" onchange="cbi_d_update(this.id)" name="cbid.ibeacon.ibeacon._uuid_2" id="cbid.ibeacon.ibeacon._uuid_2" value="" style="width:50px" maxlength="4">')
        luci.http.write(' - <input title="" autocomplete="off" type="text" class="ace-tooltip" onchange="cbi_d_update(this.id)" name="cbid.ibeacon.ibeacon._uuid_3" id="cbid.ibeacon.ibeacon._uuid_3" value="" style="width:50px" maxlength="4">')
        luci.http.write(' - <input title="" autocomplete="off" type="text" class="ace-tooltip" onchange="cbi_d_update(this.id)" name="cbid.ibeacon.ibeacon._uuid_4" id="cbid.ibeacon.ibeacon._uuid_4" value="" style="width:50px" maxlength="4">')
        luci.http.write(' - <input title="" autocomplete="off" type="text" class="ace-tooltip" onchange="cbi_d_update(this.id)" name="cbid.ibeacon.ibeacon._uuid_5" id="cbid.ibeacon.ibeacon._uuid_5" value="" style="width:130px" maxlength="12">')
        luci.template.render("cbi/valuefooter",  {section = s, self = self})
    end

    uuid.write = function (self, section, value)
      local uuid_2 = self.map:formvalue("cbid.ibeacon.ibeacon._uuid_2") or ""
      local uuid_3 = self.map:formvalue("cbid.ibeacon.ibeacon._uuid_3") or ""
      local uuid_4 = self.map:formvalue("cbid.ibeacon.ibeacon._uuid_4") or ""
      local uuid_5 = self.map:formvalue("cbid.ibeacon.ibeacon._uuid_5") or ""

      if value == "" or uuid_2 == "" or uuid_3 == "" or uuid_4 == "" or uuid_5 == "" then
          return
      else
          local new_val = value .. uuid_2 .. uuid_3 .. uuid_4 .. uuid_5
          self.map.uci:set("ibeacon", section, "uuid", new_val)
      end
    end

    major = s_ibeacon:option(Value, "major", translate("Major"))
    major.default = "21395"
    major:depends("enabled", "1")
    major.datatype = "range(0, 65535)"
    major.force_required = true
    major.optional = false

    minor = s_ibeacon:option(Value, "minor", translate("Minor"))
    minor.default = "100"
    minor:depends("enabled", "1")
    minor.datatype = "range(0, 65535)"
    minor.force_required = true
    minor.optional = false

    --[[ From https://redmine.ignitenet.com/issues/22457
        ibeacon.ibeacon.txpower  broadcaster ibeacon'power
        dbm       set_value                  set_value
        -20 dBm   0                          175
        -18 dBm   1                          177
        -15 dBm   2                          180
        -12 dBm   3                          183
        -10 dBm   4                          185
        -9  dBm   5                          186
        -6  dBm   6                          189
        -5  dBm   7                          190
        -3  dBm   8                          192
         0  dBm   9                          195
         1  dBm   10                         196
         2  dBm   11                         197
         3  dBm   12                         198
         4  dBm   13                         199
         5  dBm   14                         200
    ]]

    if not is_EAP102 then
        txpower = s_ibeacon:option(ListValue, "txpower", translate("Tx Power"))
        txpower:depends("enabled", "1")
        txpower.rmempty = false
        txpower.default = "14"
        txpower:value("0", translate("-20 dBm"))
        txpower:value("1", translate("-18 dBm"))
        txpower:value("2", translate("-15 dBm"))
        txpower:value("3", translate("-12 dBm"))
        txpower:value("4", translate("-10 dBm"))
        txpower:value("5", translate("-9 dBm"))
        txpower:value("6", translate("-6 dBm"))
        txpower:value("7", translate("-5 dBm"))
        txpower:value("8", translate("-3 dBm"))
        txpower:value("9", translate("0 dBm"))
        txpower:value("10", translate("1 dBm"))
        txpower:value("11", translate("2 dBm"))
        txpower:value("12", translate("3 dBm"))
        txpower:value("13", translate("4 dBm"))
        txpower:value("14", translate("5 dBm"))
    end

    if not is_EAP102 then
        scan1_title           = s_ibeacon:option( DummyValue, "_scan_title", translate("BLE Scan"))
        scan1_title.template = "cbi/valueheader"

        scan1           = s_ibeacon:option( DummyValue, "_scan", translate("Scan"))
        scan1.empty_next        = true
        scan1.cond_optional     = true
        scan1.optional          = false
        scan1.custom  = "style='width:50px' "
        scan1.is_controlled_by_cloud = is_controlled_by_cloud
        scan1.render =  function(self, s_ibeacon, scope)
            luci.http.write('<div style="display:inline-block" class="scan-btn" >')
            self.template = "cbi/ble_scan"
            AbstractValue.render(self, s_ibeacon, nil)
            luci.http.write('</div>')
            luci.template.render("cbi/valuefooter",  {section = s_ibeacon, self = self})
        end
    end

end

return m_ssh, m_telnet, m_discover, m_httpd, m_remotelog, m_ntp, m_snmp, m_mdns, m_lldp, m_ibeacon
