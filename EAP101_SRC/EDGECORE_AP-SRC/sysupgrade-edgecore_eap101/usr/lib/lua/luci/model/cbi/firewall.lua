local acn_status = require "luci.acn.status"
local fw_ver = acn_status.version()
local utl = require "luci.util"
local fwm = require "luci.model.firewall".init()
local acn_util = require "luci.acn.util"

local zones = fwm:get_zones()
local zone_value_list = ""
local zone_name_list = ""
local max_count = 20

local uci = require "luci.model.uci".cursor()
local wan_type = uci:get("network", "wan", "type") or ""
local fw_alert = (wan_type == "bridge")

m = Map("firewall", translate("Firewall Rules"))

local s = m:section(TypedSection, "rule", "")

s.addremove = true
s.anonymous = true

-- Use javascript/dynamic add remove template
s.template = "cbi/tblsection_js"
s.add_btn_small = true
s.add_btn_location = "top"
s.max_count = max_count
s.is_disabled = true

s.table_name = "table_rule"
s.no_stripe = true

s.add_onclick = "addRuleRow();"
s.del_onclick = "removeRuleRow(this.id);"

local enabled = s:option(Flag, "enabled", translate("Enabled"))
enabled.switch_type = "yes_no"
enabled.default = 1
function enabled.cfgvalue(self, section)
    local value = ListValue.cfgvalue(self, section)

    if value == nil then return "1" end
    return value
end

name = s:option(Value, "name", translate("Name"))
name.force_required = true
name.custom_attr = "style='width:79px' disabled='disabled'"

target = s:option(ListValue, "target", translate("Target"))
target:value("ACCEPT", "ACCEPT")
target:value("REJECT", "REJECT")
target:value("DROP", "DROP")
target.force_required = true
target.custom_attr = "style='width:100px' disabled='disabled'"

family = s:option(ListValue, "family", translate("Family"))
family:value("any", translate("Any"))
family:value("ipv4", "ipv4")
family:value("ipv6", "ipv6")
family.force_required = true
family.custom_attr = "style='width:63px' disabled='disabled'"

src = s:option(ListValue, "src", translate("Source"))
src.custom_attr = "style='width:72px' disabled='disabled'"

src_ip = s:option(Value, "src_ip", translate("Source IP"))
src_ip.custom_attr = "disabled='disabled'"

src_port = s:option(Value, "src_port", translate("Source port"))
src_port.datatype = "portrange"
src_port.custom_attr = "style='width:57px'"
src_port:depends("proto", "all")
src_port:depends("proto", "tcp")
src_port:depends("proto", "udp")
src_port:depends("proto", "tcpudp")
src_port.custom_attr = "disabled='disabled'"

proto = s:option(ListValue, "proto", translate("Protocol"))
proto:value("all", translate("Any"))
proto:value("tcpudp", "TCP+UDP")
proto:value("tcp", "TCP")
proto:value("udp", "UDP")
proto:value("icmp", "ICMP")
proto:value("igmp", "IGMP")
proto:value("esp", "ESP")
proto.custom_attr = "style='width:96px' disabled='disabled'"

dest = s:option(ListValue, "dest", translate("Destination"))
dest.custom_attr = "style='width:72px' disabled='disabled'"

for _, zone in utl.spairs(zones, function(a,b) return (zones[a]:name() < zones[b]:name()) end) do
    local source_val = zone:name() or ""
    src:value("", translate("Any"))
    network_name = acn_util.firewall_friendly_network(source_val)
    src:value(source_val, network_name)
    dest:value("", translate("Any"))
    dest:value(source_val, network_name)
    if zone_name_list ~= "" then
        zone_name_list = zone_name_list .. ","
    end
    zone_name_list = zone_name_list .. "'" .. network_name .. "'"

    if zone_value_list ~= "" then
        zone_value_list = zone_value_list .. ","
    end
    zone_value_list = zone_value_list .. "'" .. source_val .. "'"
end

zone_name_list = "[" .. zone_name_list .. "]"
zone_value_list = "[" .. zone_value_list .. "]"

dest_ip = s:option(Value, "dest_ip", translate("Destination IP"))
dest_ip.custom_attr = "disabled='disabled'"

dest_port = s:option(Value, "dest_port", translate("Destination port"))
dest_port.datatype = "portrange"
dest_port.custom_attr = "style='width:85px' disabled='disabled'"
dest_port:depends("proto", "all")
dest_port:depends("proto", "tcp")
dest_port:depends("proto", "udp")
dest_port:depends("proto", "tcpudp")

-- JS file for this page
luci.dispatcher.context.page_js = '<script src="' .. luci.config.main.mediaurlbase .. '/js/firewall.js?ver=' .. fw_ver .. '"></script>\n'
.. '<script src="' .. luci.config.main.resourcebase .. '/common.js?ver=' .. fw_ver .. '"></script>\n'
.. '<script type="text/javascript"> \n'
.. '    var zone_name_list = ' .. zone_name_list .. ';\n'
.. '    var zone_value_list = ' .. zone_value_list .. ';\n'
.. '    var max_count = ' .. max_count .. ';\n'
.. '    var fw_alert =  '.. tostring(fw_alert) .. ';\n'
.. '    var is_support_ipv6 =  '.. tostring(acn_util.has_ipv6()) .. ';\n'
.. '</script>\n'
.. '<style>\n'
.. '#btn_save  { margin-left: 10px; }\n'
.. 'input { width:100px; }\n'
.. '</style>'

--TODO: to avoid running s.parse twince. but it should have better solution.
local runned_s_parse = false

-- Validation happens in firewall.js
s.parse = function(self, nvld)
    if not runned_s_parse then
        runned_s_parse = true
        -- Have to do this first
        TypedSection.parse(self, nvld)

        local add_prefix = "acn.new"
        local del_prefix = "acn.del"

        -- This gets a list of all form values that begin with the prefix

        local new_rules = self.map:formvaluetable(add_prefix) or ""
        -- want these sorted
        local keys = {}
        for k in pairs(new_rules) do
            keys[#keys+1] = k
        end
        table.sort(keys,
            function(a,b)
                return new_rules[a] < new_rules[b]
            end
        )

        -- Need to use map.uci here so that the settings are saved
        for i,k in ipairs(keys) do

            local v = new_rules[k]
            -- value is our client-side generated section name (like 45f30e)
            if v then
                -- v = cfg used for the temporary row
                local deleted = self.map:formvalue('acn.del.firewall.cfg' .. v)
                if deleted == "0" then
                    local name = self.map:formvalue('cbid.firewall.cfg' .. v .. '.name')
                    local enabled = self.map:formvalue('cbid.firewall.cfg' .. v .. '.enabled')
                    local target = self.map:formvalue('cbid.firewall.cfg' .. v .. '.target')
                    local family = self.map:formvalue('cbid.firewall.cfg' .. v .. '.family')
                    local src = self.map:formvalue('cbid.firewall.cfg' .. v .. '.src')
                    local src_ip = self.map:formvalue('cbid.firewall.cfg' .. v .. '.src_ip')
                    local src_port = self.map:formvalue('cbid.firewall.cfg' .. v .. '.src_port')
                    local proto = self.map:formvalue('cbid.firewall.cfg' .. v .. '.proto')
                    local dest = self.map:formvalue('cbid.firewall.cfg' .. v .. '.dest')
                    local dest_ip = self.map:formvalue('cbid.firewall.cfg' .. v .. '.dest_ip')
                    local dest_port = self.map:formvalue('cbid.firewall.cfg' .. v .. '.dest_port')

                    -- Create our anon section
                    local section = self:create()

                    if section then
                        self.map.uci:set("firewall", section, "name", name)

                        if enabled then
                            self.map.uci:set("firewall", section, "enabled", "1")
                        else
                            self.map.uci:set("firewall", section, "enabled", "0")
                        end
                        self.map.uci:set("firewall", section, "custom", "1")
                        self.map.uci:set("firewall", section, "target", target)
                        self.map.uci:set("firewall", section, "family", family)
                        self.map.uci:set("firewall", section, "src", src)
                        self.map.uci:set("firewall", section, "src_ip", src_ip)
                        self.map.uci:set("firewall", section, "src_port", src_port)
                        self.map.uci:set("firewall", section, "proto", proto)
                        self.map.uci:set("firewall", section, "dest", dest)
                        self.map.uci:set("firewall", section, "dest_ip", dest_ip)
                        self.map.uci:set("firewall", section, "dest_port", dest_port)

                        -- If we don't do the save/load below, something messes up the internal counter
                        -- and uci sections start overwriting each other (see #497)
                        self.map.uci:save("firewall")
                        self.map.uci:load("firewall")
                    end
                end
            end
        end

        table = self.map:formvaluetable(del_prefix .. ".firewall")
        -- Need to use map.uci here so that the settings are saved correctly
        for k, v in pairs(table) do
            if v and (v == "1" or v == 1) then
               self.map.uci:delete("firewall", k)
            end
        end
    end
end

return m
