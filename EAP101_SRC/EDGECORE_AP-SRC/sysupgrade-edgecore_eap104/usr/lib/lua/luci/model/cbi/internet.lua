require("luci.sys")
require("luci.util")
local ip = require("luci.ip")
local acn_util = require "luci.acn.util"
brand = require("luci.acn.brand")

local acn_uci = acn_util.cursor()
local product = require("luci.acn.product")
local supports_3g = product.supports_3g() or false
local linked_3g = false
local support_QUECTEL_dongle = product.support_QUECTEL_dongle()
local support_ipv6 = acn_util.has_ipv6()
local acn_status = require "luci.acn.status"
local is_internet_source_fixed = false

local ipvalidation = require "luci.acn.ipvalidation"
local ipdata = ipvalidation.getipdata()
local json = require "cjson.safe"
local json_ipdata = json.encode(ipdata)
hotspot_ip = acn_uci:get('hotspot', 'hotspot', 'listen') or ''
hotspot_netmask = acn_uci:get('hotspot', 'hotspot', 'dynip_mask') or ''
local_lan_ip = acn_uci:get('network', 'lan', 'ipaddr') or ''
local_lan_netmask = acn_uci:get('network', 'lan', 'netmask') or ''
guest_lan_ip = acn_uci:get('network', 'guest', 'ipaddr') or ''
guest_lan_netmask = acn_uci:get('network', 'guest', 'netmask') or ''

local MAX_CUSTOM_LANS = 10
local custom_lan_data = ""

for i = 0, (MAX_CUSTOM_LANS - 1) do
    local custom_lan_name = "custom_" .. i
    local custom_lan = acn_uci:get('network', custom_lan_name, 'proto')
    if custom_lan then
        local _ip = acn_uci:get('network', custom_lan_name, 'ipaddr')
        local _netmask = acn_uci:get('network', custom_lan_name, 'netmask')
        if custom_lan_data ~= "" then
            custom_lan_data = custom_lan_data .. ","
        end
        custom_lan_data = custom_lan_data .. "'" .. _ip .. "','" .. _netmask .. "'"
    end
end
custom_lan_data = "[" .. custom_lan_data .. "]";

-- #4707: verify the duplicated VLAN ID
local vlans = acn_util.vlans(acn_uci)
local vlan_data = ""

for i, vlan in ipairs(vlans) do
    local tmp_vlan = vlan['vlan_id'] or ""
    if tmp_vlan ~= "" then
        if vlan_data ~= "" then
            vlan_data = vlan_data .. ","
        end
        vlan_data = vlan_data .. "'" .. tmp_vlan .. "'"
    end
end
vlan_data = "[" .. vlan_data .. "]";
-- END

if supports_3g then
    linked_3g = acn_util.detected_dongle()
end

local bridged_ifaces = "false"

local isrc = acn_uci:get("network", "wan", "inet_src")
local ifaces = acn_util.network_members("wan", acn_uci)
if isrc and ifaces then
    for _, v in pairs(ifaces) do
        if v.logical_name and v.logical_name ~= acn_util.inet_src_to_logical(isrc) then
            bridged_ifaces = "true"
        end
    end
end

-- JS file for this page
local fw_ver = acn_status.version()
luci.dispatcher.context.page_js = '<script src="' .. luci.config.main.mediaurlbase .. '/js/internet.js?ver=' .. fw_ver .. '"></script>\n'
.. '<script src="' .. luci.config.main.resourcebase .. '/ip_alias.js?ver=' .. fw_ver .. '"></script>\n'
.. '<script src="' .. luci.config.main.resourcebase .. '/common.js?ver=' .. fw_ver .. '"></script>\n'
.. '<style>.cbi-section { padding-bottom: 0px }</style>\n'
.. '<style>.cbi-section-node { padding-top: 0px }</style>\n'
.. "<script type='text/javascript'>\n"
..    "var ipdata = " .. json_ipdata .. ";\n"
..    "var support_ipv6 = " .. tostring(support_ipv6) .. ";\n"
..    "var vlan_data = " .. vlan_data .. ";\n"
..    "var supports_3g = " .. tostring(supports_3g) .. ";\n"
..    "var linked_3g = " .. tostring(linked_3g) .. ";\n"
..    "var bridged_ifaces = "..bridged_ifaces..";\n"
.. "</script>\n"

local m,s,m_ipv6, s_ipv6,s3,wan_type, alert, vlantag, mgmt, wan_3g_iface_error

m = Map("network", translate("Internet Settings"))

    s = m:section(NamedSection, wan_network, "interface", "")

    s.addremove = false
    s.anonymous = true
    if not is_internet_source_fixed then
        inet_src = s:option(ListValue, "inet_src", translate("Internet Source"))
    end

    wan_3g_iface_error = s:option(DummyValue, "wan_3g_iface_error", "")
    wan_3g_iface_error.template = "cbi/wan_3g_iface_error"

    wan_type = s:option( ListValue, "proto", translate("IP Address Mode"))
    -- wan_ip_alias_btn = s:option(DummyValue, "_none", translate("IP Aliases"))
    --==================================================================================
    --DHCP
    fallback_ipaddr = s:option(Value, "fallback_ip", translate("Fallback IP"))
    fallback_mask = s:option(Value, "fallback_nm", translate("Fallback Netmask"))

    --fallback_ipaddr.help_tip = "<b>Advanced Option</b><br/>Default IP when DHCP server fail or doesn't exist."
    --fallback_mask.help_tip = "<b>Advanced Option</b><br/>Default netmask when DHCP server fail or doesn't exist."

    --===================================================================================
    --MTU
    mtu = s:option(Value, "mtu", translate("MTU Size"))
    --===================================================================================

    manual_hostname = s:option(Flag, "manual_hostname", translate("Manual DHCP Client Id"))
    hostname = s:option(Value, "hostname", translate("Hostname"))
    --===================================================================================
    --Static IP - ipv4
    static_ipaddr = s:option(Value, "ipaddr", translate("IP Address"))
    static_ipaddr:depends("proto", "static")
    static_ipaddr.default = "192.168.1.1"
    static_ipaddr.optional = false
    static_ipaddr.force_required = true

    static_mask = s:option(Value, "netmask", translate("Subnet Mask"))
    static_mask:depends("proto", "static")
    static_mask:value("255.255.255.0")
    static_mask:value("255.255.0.0")
    static_mask:value("255.0.0.0")
    static_mask.default = "255.255.255.0"
    static_mask.optional = false
    static_mask.force_required = true

    def_gateway = s:option(Value, "gateway", translate("Default Gateway"))
    def_gateway:depends("proto", "static")
    def_gateway.default = "192.168.1.254"
    def_gateway.optional = false
    def_gateway.force_required = true

    dns = s:option(Value, "dns", translate("DNS Servers"))
    dns:depends("proto", "static")
    dns.datatype = "custom_dns"
    dns.optional = false
    dns.force_required = true
    dns.cast = "string"
    dns.default = "8.8.8.8"
    -- dns.datatype = "ip4addr"
    --dns.help_tip = "<b>Info</b> If you want to input multiple DNS servers, please use spaces to separate the ip addresses.  The maximum number of servers allowed is 4."

    --===================================================================================
    --PPPoE
    service_name    = s:option(Value, "service", translate("Service Name"))
    --===================================================================================
    --3g
    if supports_3g then
        modem_device = s:option(ListValue, "device", translate("Modem Device"))
        modem_device:value("/dev/ttyUSB1", "FS020U/FS040U LTE Dongle")
        if support_QUECTEL_dongle then
            modem_device:value("/dev/ttyUSB1-qt", "QUECTEL LTE Dongle")
        end

        function modem_device.cfgvalue(self, section, value)
            local inet_src_value = m.uci:get("network", section, "inet_src") or ""
            if inet_src_value == "wwan0" then
                value = "/dev/ttyUSB1-qt"
            end
            return value
        end

        function modem_device.write(self, section, value)
            if value == "/dev/ttyUSB1-qt" then
                self.map.uci:set("network", section, "inet_src", "wwan0")
                self.map.uci:set("network", section, "proto", "dhcp")
                self.map.uci:set("network", section, "ifname", "wwan0")
            else
                self.map.uci:set("network", section, "inet_src", "3g-wan")
                self.map.uci:set("network", section, "proto", "3g")
                self.map.uci:delete("network", section, "ifname")
            end
            self.map.uci:set("network", section, "device", "/dev/ttyUSB1")
        end

        service_type = s:option(ListValue, "service_3g", translate("Service Type"))
        service_type:value("umts", "UMTS")
        function service_type.cfgvalue(self, section, value)
            local _value = m.uci:get("network", section, "service") or ""
            return _value
        end

        function service_type.write(self, section, value)
            self.map.uci:set("network", section, "service", value)
            self.map.uci:set("network", section, "pppd_options", "debug logfile /var/log/3g.log")
        end

        apn = s:option(Value, "apn", translate("APN"))
        pin = s:option(Value, "pincode", translate("PIN"))
    end
    --===================================================================================
    --PPPoE
    ---- fake_XXX: fix browser autofill issue.
    fake_user = s:option(Value, "fake_user", translate("fake_user"))
    fake_pass = s:option(Value, "fake_password", translate("fake_pass"))

    user = s:option(Value, "username", translate("Username"))
    pass = s:option(Value, "password", translate("Password"))

    --===================================================================================

    --manual_hostname.help_tip = "<b>Advanced Option</b><br/>Check this option to manually enter the client ID for the DHCP client. <br/><br/>If unchecked (recommended), the DHCP client id will be set to the system's hostname. "
    if not is_internet_source_fixed then
        --inet_src.help_tip = "Select which interface will act as your connection to the upstream network. "
    end
    --hostname.help_tip = "This is the name assigned to your DHCP client, and will be associated with the IP address assigned by the DHCP server. "
    --mtu.help_tip = "<b>Advanced Option</b><br/><b>Warning!</b> Only change this value if you're an advanced user. "
    --wan_type.help_tip = "Configure how you want your device to get its IP address.  DHCP is recommended for most cases."
    --wan_ip_alias_btn.help_tip = "<b>Advanced Option</b><br/>Add additional IP aliases to the WAN interface."

    --management VLAN

    -- XXX TODO DRY violation: firewall loading state loading dublicate with services.lua
    local fw_rules = {}

    m.uci:foreach("firewall", "rule", function (fw)
        if fw.name then
            fw_rules[fw.name] = fw
        end
    end)

    local function delete_fw_rule(uci, name)
        local rule = fw_rules[name]
        if rule then
            uci:delete("firewall", rule[".name"])
            fw_rules[name] = nil
        end
    end

    --[[ local function add_fw_rule_disabled(uci, rule)
        local cfg_name = uci:add("firewall", "rule")

        if cfg_name then
            uci:set("firewall", cfg_name, "enabled", "0")
            uci:set("firewall", cfg_name, "target", "ACCEPT")

            for key, value in pairs(rule) do
                uci:set("firewall", cfg_name, key, value)
            end

            fw_rules[rule.name] = cfg_name
        end
    end ]]

    local function add_fw_rule_enabled(uci, rule)
        local cfg_name = uci:add("firewall", "rule")

        if cfg_name then
            uci:set("firewall", cfg_name, "enabled", "1")
            uci:set("firewall", cfg_name, "target", "ACCEPT")

            for key, value in pairs(rule) do
                uci:set("firewall", cfg_name, key, value)
            end

            fw_rules[rule.name] = cfg_name
        end
    end

    local function update_lan_zone(uci, input)
        uci:foreach("firewall", "zone", function (zone)
            if zone.name == "lan" then
                uci:set("firewall", zone[".name"], "input", input)
                return false
            end
        end)
    end

    local function update_allow_ping(uci, state)
        local rule = fw_rules["Allow-Ping"]

        if rule then
            uci:set("firewall", rule[".name"], "enabled", state)
        end
    end

    local function update_firewall_for_mgmt_vlan_on(uci)
        delete_fw_rule(uci, "Allow-WEBUI")
        delete_fw_rule(uci, "Allow-WEBUI-secure")
        delete_fw_rule(uci, "Allow-SNMP")
        delete_fw_rule(uci, "Allow-SNMP-IPv6")
        delete_fw_rule(uci, "Allow-Multicast-Discovery")
        delete_fw_rule(uci, "Allow-Broadcast-Discovery")
        delete_fw_rule(uci, "Allow-Telnet")
        delete_fw_rule(uci, "Allow-SSH")

        -- add
        add_fw_rule_enabled(uci, {
            name = "Allow-lan-DHCP",
            src = "lan",
            proto = "udp",
            dest_port = "67-68"
        })
        add_fw_rule_enabled(uci, {
            name = "Allow-lan-DNS",
            src = "lan",
            dest_port = "53"
        })

        update_allow_ping(uci, "0")
        update_lan_zone(uci, "REJECT")

        uci:save("firewall")
    end


    local function update_firewall_for_mgmt_vlan_off(uci)
        add_fw_rule_enabled(uci, { name = "Allow-WEBUI", src = "wan", proto = "tcp", dest_port = "80", family = "ipv4" })
        add_fw_rule_enabled(uci, { name = "Allow-WEBUI-secure", src = "wan", proto = "tcp", dest_port = "443", family = "ipv4" })
        add_fw_rule_enabled(uci, { name = "Allow-SNMP", src = "wan", proto = "udp", dest_port = "161", family = "ipv4" })
        if support_ipv6 then
            add_fw_rule_enabled(uci, { name = "Allow-SNMP-IPv6", src = "wan", proto = "udp", dest_port = "161", family = "ipv6" })
        end
        add_fw_rule_enabled(uci, { name = "Allow-Multicast-Discovery", src = "wan", proto = "udp", dest_port = "17371", dest_ip = "233.89.188.1", family = "ipv4" })
        add_fw_rule_enabled(uci, { name = "Allow-Broadcast-Discovery", src = "wan", proto = "udp", dest_port = "17371", dest_ip = "255.255.255.255", family = "ipv4" })
        -- add_fw_rule_disabled(uci, { name = "Allow-SSH", src = "wan", proto = "tcp", dest_port = "22", family = "ipv4" })

        delete_fw_rule(uci, "Allow-lan-DHCP")
        delete_fw_rule(uci, "Allow-lan-DNS")

        update_allow_ping(uci, "1")
        update_lan_zone(uci, "ACCEPT")

        uci:save("firewall")
    end

    local function update_firewall_for_wan_vlan(uci, enabled, proto_val)
        uci:foreach("firewall", "zone", function (zone)
            if zone.name == "wan" then
                local network = { "wan" }
                if enabled and (proto_val == "dhcp" or proto_val == "static") then
                    network = { "wanvlan" }
                end
                uci:set("firewall", zone[".name"], "network", network)
            end
        end)
        uci:save("firewall")
    end

    local old_mgtm_vlan_enabled = acn_util.is_mgmt_vlan_enabled(acn_uci)
    --local old_wan_vlan_enabled = acn_util.is_wan_vlan_enabled(acn_uci)

    -- XXX maybe find better place for this hook?
    m.on_before_save = function (self)
        local val = self:get("managementvlan", "enabled")
        if (acn_util.is_enabled(val)) then
            if not old_mgtm_vlan_enabled then
                update_firewall_for_mgmt_vlan_on(self.uci)
            end

            -- static
            if self:get("managementvlan", "proto") == "static" then
                local netmask = self:get("managementvlan", "netmask")
                local ipaddr = self:get("managementvlan", "ipaddr")
                local target = ip.IPv4(ipaddr, netmask):network():string()
                self:set("managementvlannetwork", "target", target)
                self:set("managementvlannetwork", "netmask", netmask)
            end
        else
            if old_mgtm_vlan_enabled then
                update_firewall_for_mgmt_vlan_off(self.uci)
            end

            -- when disabled due none static/dhcp protocol, CBI removes keys
            -- we need to readd `enabled '0'` to prevent issues in Cloud #5838
            self:set("managementvlan", "enabled", "0")

            -- when disabling management VLAN, remove management IP rule/route
            self:del("managementvlanrule")
            self:del("managementvlanroute")
            self:del("managementvlannetwork")
        end

        val = self:get("wanvlan", "enabled")
        proto_val = self:get("wanvlan", "proto")

        if (acn_util.is_enabled(val)) then
            --if not old_wan_vlan_enabled then
            update_firewall_for_wan_vlan(self.uci, true, proto_val)
            if proto_val == "none" then
              self:set("wanvlan", "ip4table", "1")
            else
              self:del("wanvlan", "ip4table")
            end
            --end
        else
            --if old_wan_vlan_enabled then
            update_firewall_for_wan_vlan(self.uci, false, proto_val)
            --end
            self:del("wanvlan", "ip4table")
        end
    end

    ------ WAN VLAN ------
    local vlantag_network = "wanvlan"
    vlantag = m:section(NamedSection, vlantag_network, "interface", translate(""))
    vlantag.sub_title_class = true
    vlantag.addremove = false
    vlantag.anonymous = true
    vlantag.div_heading_id = "vlantag_title"
    vlantag.addl_classes = "hide"

    vlan_tag_enable = vlantag:option(Flag, "enabled", translate("VLAN Tag"))
    vlan_tag_enable.rmempty = false

    vlan_tag_id = vlantag:option(Value, "ifname", translate("VLAN Tag Id"))
    vlan_tag_id:depends("enabled", "1", vlantag_network)
    vlan_tag_id.force_required = true
    vlan_tag_id.optional = false
    vlan_tag_id.rmempty = true
    vlan_tag_id.custom = "style='width:50px' "
    vlan_tag_id.cfgvalue = function (self, section)
        local ifname = self.map:get(section, "ifname")
        return ifname and ifname:match('.+%.(%d+)')
    end
    vlan_tag_id.write = function (self, section, value)
        return self.map:set(section, "ifname", isrc .. "." .. value)
    end
    vlan_tag_id.datatype = "range(2, 4094)"

    vlan_tag_ipmode = vlantag:option(ListValue, "proto", translate("IP Address Mode"))
    vlan_tag_ipmode:depends("enabled", "1", vlantag_network)
    vlan_tag_ipmode:value("dhcp","DHCP")
    vlan_tag_ipmode:value("static",translate("Static IP"))
    vlan_tag_ipmode:value("none",translate("None"))
    --vlan_tag_ipmode.help_tip = "<b>Advanced Option</b><br/>Configure how you want your device to get its IP address.  DHCP is recommended for most cases."

    vlan_tag_ipaddr = vlantag:option(Value, "ipaddr", translate("IP Address"))
    vlan_tag_ipaddr:depends("proto", "static")
    vlan_tag_ipaddr.default = "192.168.1.1"
    vlan_tag_ipaddr.optional = false
    vlan_tag_ipaddr.cond_optional = true

    vlan_tag_netmask = vlantag:option(Value, "netmask", translate("Subnet Mask"))
    vlan_tag_netmask:depends("proto", "static")
    vlan_tag_netmask:value("255.255.255.0")
    vlan_tag_netmask:value("255.255.0.0")
    vlan_tag_netmask:value("255.0.0.0")
    vlan_tag_netmask.default = "255.255.255.0"
    vlan_tag_netmask.optional = false
    vlan_tag_netmask.cond_optional = true

    vlan_tag_gateway = vlantag:option(Value, "gateway", translate("Default Gateway"))
    vlan_tag_gateway:depends("proto", "static")
    vlan_tag_gateway.default = "192.168.1.254"
    vlan_tag_gateway.optional = false
    vlan_tag_gateway.cond_optional = true

    vlan_tag_dns = vlantag:option(Value, "dns", translate("DNS Servers"))
    vlan_tag_dns:depends("proto", "static")
    vlan_tag_dns.default = "8.8.8.8"
    vlan_tag_dns.optional = false
    vlan_tag_dns.cond_optional = true

    vlan_tag_fallback_ipaddr = vlantag:option(Value, "fallback_ip", translate("Fallback IP"))
    vlan_tag_fallback_ipaddr:depends("proto", "dhcp")
    vlan_tag_fallback_ipaddr.default = "192.168.1.10"
    vlan_tag_fallback_ipaddr.optional = false
    vlan_tag_fallback_ipaddr.cond_optional = true
    --vlan_tag_fallback_ipaddr.help_tip = "<b>Advanced Option</b><br/>Default IP when DHCP server fail or doesn't exist."

    vlan_tag_fallback_mask = vlantag:option(Value, "fallback_nm", translate("Fallback Netmask"))
    vlan_tag_fallback_mask:depends("proto", "dhcp")
    vlan_tag_fallback_mask:value("255.255.255.0")
    vlan_tag_fallback_mask:value("255.255.0.0")
    vlan_tag_fallback_mask:value("255.0.0.0")
    vlan_tag_fallback_mask.default = "255.255.255.0"
    vlan_tag_fallback_mask.optional = false
    vlan_tag_fallback_mask.cond_optional = true
    --vlan_tag_fallback_mask.help_tip = "<b>Advanced Option</b><br/>Default netmask when DHCP server fail or doesn't exist."

    ------ Management VLAN ------
    local mgmt_network = "managementvlan"
    mgmt = m:section(NamedSection, mgmt_network, "interface", translate(""))
    mgmt.sub_title_class = true
    mgmt.addremove = false
    mgmt.anonymous = true
    mgmt.div_heading_id = "mgmt_title"
    mgmt.addl_classes = "hide"

    mgmt_vlan = mgmt:option(Flag, "enabled", translate("Mgmt VLAN"))
    mgmt_vlan.rmempty = false
    --mgmt_vlan:depends("proto", "static", wan_network)
    --mgmt_vlan:depends("proto", "dhcp", wan_network)
    --mgmt_vlan:depends("proto", "none", wan_network)
    --mgmt_vlan.help_tip = "<b>Advanced Option</b><br/>Select this option to enable a management VLAN on this device. Once you enable this option, you will no longer be able to access the device on any of the built-in local networks (like 192.168.2.1, for example). You will only be able to access the device from the VLAN'ed network specified below. If this device's IP mode is set to DHCP, it will also request a new IP address in the subnet range assigned to the VLAN network."

    mgmt_vlan_tag = mgmt:option(Value, "ifname", translate("Mgmt VLAN Id"))
    mgmt_vlan_tag:depends("enabled", "1", mgmt_network)
    mgmt_vlan_tag.cond_optional = true
    mgmt_vlan_tag.default = "100"
    mgmt_vlan_tag.optional = false
    mgmt_vlan_tag.rmempty = true
    mgmt_vlan_tag.custom = "style='width:50px' "
    --mgmt_vlan_tag.help_tip = "<b>Advanced Option</b><br/>VLAN id for management VLAN."
    mgmt_vlan_tag.cfgvalue = function (self, section)
        local ifname = self.map:get(section, "ifname")
        return ifname and ifname:match('.+%.(%d+)')
    end
    mgmt_vlan_tag.write = function (self, section, value)
        return self.map:set(section, "ifname", isrc .. "." .. value)
    end

    mgmt_vlan_ipmode = mgmt:option(ListValue, "proto", translate("IP Address Mode"))
    mgmt_vlan_ipmode:depends("enabled", "1", mgmt_network)
    mgmt_vlan_ipmode:value("dhcp","DHCP")
    mgmt_vlan_ipmode:value("static",translate("Static IP"))
    --mgmt_vlan_ipmode.help_tip = "<b>Advanced Option</b><br/>Configure how you want your device to get its IP address.  DHCP is recommended for most cases."
    mgmt_vlan_ipmode.write = function (self, section, value)
        if value == "dhcp" then
            -- remove static mode related rules
            self.map:del("managementvlanrule")
            self.map:del("managementvlanroute")
            self.map:del("managementvlannetwork")
        else
            -- add static mode related rule
            self.map:set("managementvlanrule", nil, "rule")
            self.map:set("managementvlanrule", "lookup", "secdirect")
            self.map:set("managementvlanrule", "priority", "10")
            self.map:set("managementvlanrule", "in", "managementvlan")

            self.map:set("managementvlanroute", nil, "route")
            self.map:set("managementvlanroute", "interface", "managementvlan")
            self.map:set("managementvlanroute", "target", "0.0.0.0")
            self.map:set("managementvlanroute", "netmask", "0.0.0.0")
            -- Note: gateway is written directly with CBI option bellow
            self.map:set("managementvlanroute", "table", "secdirect")

            self.map:set("managementvlannetwork", nil, "route")
            self.map:set("managementvlannetwork", "interface", "managementvlan")
            -- target and netmask are written by 'on_before_save'
            self.map:set("managementvlannetwork", "table", "secdirect")
        end

        return Value.write(self, section, value)
    end

    mgmt_vlan_ipaddr = mgmt:option(Value, "ipaddr", translate("IP Address"))
    mgmt_vlan_ipaddr:depends("proto", "static")
    mgmt_vlan_ipaddr.default = "192.168.1.1"
    mgmt_vlan_ipaddr.optional = false
    mgmt_vlan_ipaddr.cond_optional = true

    mgmt_vlan_netmask = mgmt:option(Value, "netmask", translate("Subnet Mask"))
    mgmt_vlan_netmask:depends("proto", "static")
    mgmt_vlan_netmask:value("255.255.255.0")
    mgmt_vlan_netmask:value("255.255.0.0")
    mgmt_vlan_netmask:value("255.0.0.0")
    mgmt_vlan_netmask.default = "255.255.255.0"
    mgmt_vlan_netmask.optional = false
    mgmt_vlan_netmask.cond_optional = true

    mgmt_def_gateway = mgmt:option(Value, "gateway", translate("Default Gateway"))
    mgmt_def_gateway:depends("proto", "static")
    mgmt_def_gateway.default = "192.168.1.254"
    mgmt_def_gateway.optional = false
    mgmt_def_gateway.cond_optional = true
    -- Gateway lives in "network.managementvlanroute", so we redirecting readind/writing
    mgmt_def_gateway.cfgvalue = function (self, section)
        return self.map:get("managementvlanroute", "gateway")
    end
    mgmt_def_gateway.write = function (self, section, value)
        return self.map:set("managementvlanroute", "gateway", value)
    end

    mgmt_fallback_ipaddr = mgmt:option(Value, "fallback_ip", translate("Fallback IP"))
    mgmt_fallback_ipaddr:depends("proto", "dhcp")
    mgmt_fallback_ipaddr.default = "192.168.1.10"
    mgmt_fallback_ipaddr.optional = false
    mgmt_fallback_ipaddr.cond_optional = true
    --mgmt_fallback_ipaddr.help_tip = "<b>Advanced Option</b><br/>Default IP when DHCP server fail or doesn't exist."

    mgmt_fallback_mask = mgmt:option(Value, "fallback_nm", translate("Fallback Netmask"))
    mgmt_fallback_mask:depends("proto", "dhcp")
    mgmt_fallback_mask:value("255.255.255.0")
    mgmt_fallback_mask:value("255.255.0.0")
    mgmt_fallback_mask:value("255.0.0.0")
    mgmt_fallback_mask.default = "255.255.255.0"
    mgmt_fallback_mask.optional = false
    mgmt_fallback_mask.cond_optional = true
    --mgmt_fallback_mask.help_tip = "<b>Advanced Option</b><br/>Default netmask when DHCP server fail or doesn't exist."

    -- ipv6 Settings
    if support_ipv6 then
        s_ipv6 = m:section(NamedSection, "wan6", "interface", translate("IPv6 Settings"))
        s_ipv6.sub_title_class = true
        s_ipv6.addremove = false
        s_ipv6.anonymous = true

        wan_type_ipv6 = s_ipv6:option( ListValue, "proto", translate("IP Address Mode"))
        wan_type_ipv6:value("dhcpv6", "DHCP")
        wan_type_ipv6:value("static", translate("Static IP"))

        dhcp_ipv6_clientid = s_ipv6:option(Value, "clientid", translate("Client Id"))
        --dhcp_ipv6_clientid.datatype = "hostname_str(1, 63)"

        static_ipv6_ipaddr = s_ipv6:option(Value, "ip6addr", translate("IP Address"))
        static_ipv6_ipaddr.optional = false
        static_ipv6_ipaddr.force_required = true
        static_ipv6_ipaddr.datatype = "ip6addr"

        static_ipv6_gateway = s_ipv6:option(Value, "ip6gw", translate("Default Gateway"))
        static_ipv6_gateway.optional = false
        static_ipv6_gateway.force_required = true
        static_ipv6_gateway.datatype = "ip6addr"

        static_ipv6_dns = s_ipv6:option(Value, "dns", translate("DNS"))
        static_ipv6_dns.optional = false
        static_ipv6_dns.force_required = true
        static_ipv6_dns.datatype = "ip6addr"
    end
    --==================================================================================
	-- dslite(IPoE) Settings
	ipoe = m:section(NamedSection, "ipoe", "interface", translate(""))
	ipoe.sub_title_class = true
	ipoe.addremove = false
	ipoe.anonymous = true
	ipoe_enable = ipoe:option(Flag, "enabled", translate("DS-Lite(IPoE)"))
	ipoe_enable.rmempty = false

	ipoe_peeraddr = ipoe:option(Value, "peeraddr", translate("DS-Lite AFTR address"))
	ipoe_peeraddr:depends("enabled", "1", "ipoe")
	ipoe_peeraddr.optional = false
	ipoe_peeraddr.force_required = true
	ipoe_peeraddr.datatype = "ip6addr"

    --==================================================================================
    wan_type:value("dhcp","DHCP")
    wan_type:value("static",translate("Static IP"))
    wan_type:value("pppoe","PPPoE")
    --wan_type:value("3g","3g")
    wan_type:value("none","None")

    -- wan_ip_alias_btn.template = "cbi/ip_aliases"
    -- wan_ip_alias_btn.iface = wan_network

    -- acn_util.add_ip_alias_div(wan_ip_alias_btn.iface, m)

    fake_user.header_style = "display:none"
    fake_pass.password = true
    fake_pass.header_style = "display:none"
    pass.password = true

    wan_type.default = "dhcp"

    fallback_mask:value("255.255.255.0")
    fallback_mask:value("255.255.0.0")
    fallback_mask:value("255.0.0.0")

    fallback_ipaddr.default = "192.168.1.10"
    fallback_ipaddr.optional = false
    fallback_ipaddr.force_required = true

    fallback_mask.default = "255.255.255.0"
    fallback_mask.optional = false
    fallback_mask.force_required = true

    mtu.default = "1500"
    mtu.optional = false
    mtu.force_required = true
    mtu.datatype = "range(1400,1500)"

    manual_hostname.default = "0"
    manual_hostname.switch_type = "yes_no"
    manual_hostname.rmempty = false
    manual_hostname:depends("proto", "dhcp")

    hostname:depends("manual_hostname" , 1)
    hostname.default = product.company_name()
    --hostname.datatype = "hostname_str(1, 63)"

    user:depends("proto", "pppoe")
    user.datatype = "string"
    pass:depends("proto", "pppoe")
    pass.datatype = "string"
    service_name:depends("proto", "pppoe")

    if supports_3g then
        -- wan_ip_alias_btn:depends("proto", "static")
        mtu:depends("proto", "static")
        -- wan_ip_alias_btn:depends("proto", "dhcp")
        mtu:depends("proto", "dhcp")
        -- wan_ip_alias_btn:depends("proto", "pppoe")
        mtu:depends("proto", "pppoe")

        modem_device:depends("inet_src", "3g")
        service_type:depends("inet_src", "3g")
        user:depends("inet_src", "3g")
        user.datatype = "is_ascii(0, 50)"
        pass:depends("inet_src", "3g")
        pass.datatype = "is_ascii(0, 50)"
        apn:depends("inet_src", "3g")
        apn.datatype = "limited_len_str(0, 50)"
        pin:depends("inet_src", "3g")
        pin.datatype = "limited_len_str(0, 50)"
    end

    if support_ipv6 then
        dhcp_ipv6_clientid:depends("proto", "dhcpv6")

        static_ipv6_ipaddr.default = ""
        static_ipv6_ipaddr:depends("proto", "static")
        static_ipv6_gateway:depends("proto", "static")
        static_ipv6_dns:depends("proto", "static")
    end

    fallback_ipaddr:depends("proto", "dhcp")
    fallback_mask:depends("proto", "dhcp")

    -- Handle previously configured devies
    function manual_hostname.cfgvalue(self, section)
        local val = luci.http.formvalue('cbid.network.wan.manual_hostname')
        local value = m.uci:get("network", section, "manual_hostname") or ""
        if value == "" then return "1" end
        return value
    end

    function manual_hostname.remove(self, section)
        return
    end

    function hostname.remove(self, section)
        local manual_hostname = luci.http.formvalue('cbid.network.wan.manual_hostname') or ''
        if manual_hostname ~= "1" then
            return
        end
    end

    function manual_hostname.write(self, section, value)
        -- If value is set to no, set hostname to system hostname
        luci.util.exec("logger 'manual_hostname is " .. value .. "'")

        if value == "0" then
            local sys_hostname = product.company_name()
             self.map.uci:foreach("system", "system",
                    function(s)
                    sys_hostname = self.map.uci:get("system", s['.name'], "hostname")
                end
            )
            self.map.uci:set("network", section, "hostname", sys_hostname)
        end

        Flag.write(self, section, value)
    end

    function fake_user.write(self, section)
        return
    end

    function fake_pass.write(self, section)
        return
    end
--==================================================================================
--
-- Internet source
--
--==================================================================================
    if not is_internet_source_fixed then
        wan_iface_options = acn_util.wan_iface_options()

        for i, v in ipairs(wan_iface_options) do
            if not (v == "eth1" or v == "eth2" or v:match("^lan.*")) then
                local display_name, _ = acn_util.inet_src_to_friendly(v)
                inet_src:value(v, display_name)
            end
        end

        if supports_3g and linked_3g then
            inet_src:value("3g","3G/LTE")
        end

        function inet_src.cfgvalue(self, section)
            if supports_3g then
                local _value = m.uci:get("network", section, "proto") or ""
                local inet_src_value   = m.uci:get("network", section, "inet_src") or ""
                if _value == "3g" or (_value == "dhcp" and inet_src_value == "wwan0") and linked_3g then
                    return "3g"
                end
                return ListValue.cfgvalue(self, section)
            else
                return ListValue.cfgvalue(self, section)
            end
        end

        inet_src.write = function(self, section, value)
            local form_device_val = luci.http.formvalue('cbid.network.wan.device')
            local wan = value
            if wan == nil or wan == '' then
                return
            end

            if wan == "3g" then
                local ifaces = acn_util.network_members(section, self.map.uci)
                for _, v in pairs(ifaces) do
                    if v.logical_name then
                        acn_util.add_iface_to_network("lan", v.logical_name, self.map.uci)
                    end
                end

                if form_device_val == "/dev/ttyUSB1-qt" then
                    m.uci:set("network", "wan", "ifname", "wwan0")
                    ListValue.write(self, section, "wwan0")
                else
                    local devname = product.dev_name_3g or "3g-wan"
                    m.uci:delete("network", "wan", "ifname")
                    ListValue.write(self, section, devname)
                end
            else
                -- XXX TODO: make sure wan is in our allowed list before saving?:
                -- XXX TODO: revisit this once we know what we need to do for vlans
                --acn_util.remove_vlan_ifaces(old_vid)

                -- Save WAN
                -- add back to wan list
                m.uci:delete("network", "wan", "ifname")
                acn_util.add_iface_to_network(section, acn_util.inet_src_to_logical(wan) , self.map.uci)

                ListValue.write(self, section, value)
            end
        end
    end
--==================================================================================
--
-- WAN Type
--
--==================================================================================
if supports_3g and support_QUECTEL_dongle then
    function wan_type.cfgvalue(self, section)
        local inet_src = m.uci:get("network", section, "inet_src") or ""
        if inet_src == "wwwan0" then
            return "3g"
        else
            return ListValue.cfgvalue(self, section)
        end
    end

    wan_type.write = function(self, section, value)
        local form_device_val = luci.http.formvalue('cbid.network.wan.device')
        if form_device_val == "/dev/ttyUSB1-qt" then
            ListValue.write(self, section, "dhcp")
        else
            ListValue.write(self, section, value)
        end
    end
end

return m
