local acn_status = require "luci.acn.status"
local fw_ver = acn_status.version()
local max_count = 20

m = Map("firewall", translate("Port forwarding"))

local arp_ip_list = ""
for i, dataset in ipairs(luci.sys.net.arptable()) do
    if arp_ip_list ~= "" then
        arp_ip_list = arp_ip_list .. ","
    end
    arp_ip_list = arp_ip_list .. "'" .. dataset["IP address"] .. "'"
end
arp_ip_list = "[" .. arp_ip_list .. "]"

-- JS file for this page
luci.dispatcher.context.page_js = '<script src="' .. luci.config.main.mediaurlbase .. '/js/firewall_portfw.js?ver=' .. fw_ver .. '"></script>\n'
.. '<script type="text/javascript"> \n'
.. '    var arp_ip_list = ' .. arp_ip_list .. '\n'
.. '    var max_count = ' .. max_count .. ';\n'
.. '</script>\n'
.. '<style>\n'
.. '#btn_save  { margin-left: 10px; }\n'
.. 'input  { width:150px; }\n'
.. '</style>'

local s = m:section(TypedSection, "redirect", "")
s:depends("src", "wan")
s.defaults.src = "wan"

s.addremove = true
s.anonymous = true

-- Use javascript/dynamic add remove template
s.template = "cbi/tblsection_js"
s.add_btn_small = true
s.add_btn_location = "top"
s.max_count = max_count

s.table_name = "table_portfw"
s.no_stripe  = true

s.add_onclick = "addPortfwRow();" -- "addUserRow();"
s.del_onclick = "removePortfwRow(this.id);" --"removeUserRow(this.id);"

local enabled   = s:option(Flag, "enabled", translate("Enabled"))
enabled.switch_type = "yes_no"
enabled.default = 1

name = s:option(Value, "name", translate("Name"))
name.custom_attr = "style='width:100px'"

proto = s:option(ListValue, "proto", translate("Protocol"))
proto:value("tcp", "TCP")
proto:value("udp", "UDP")
proto:value("tcpudp", "TCP+UDP")

dport = s:option(Value, "src_dport", translate("External port"))
dport.custom_attr = "style='width:100px'"
dport.datatype = "portrange"

dip = s:option(Value, "dest_ip", translate("Internal IP address"))
dip.custom_attr = "style='width:100px'"

toport = s:option(Value, "dest_port", translate("Internal port"))
toport.custom_attr = "style='width:100px'"
toport.datatype = "portrange"

-- Validation happens in firewall_portfw.js

--TODO: to avoid running s.parse twince. but it should have better solution.
local runned_s_parse = false
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
        for k in pairs(new_rules) do keys[#keys+1] = k end

        table.sort(keys, function(a,b) return new_rules[a] < new_rules[b]  end)

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
                    local proto = self.map:formvalue('cbid.firewall.cfg' .. v .. '.proto')
                    local dport = self.map:formvalue('cbid.firewall.cfg' .. v .. '.dest_port')
                    local dip = self.map:formvalue('cbid.firewall.cfg' .. v .. '.dest_ip')
                    local toport = self.map:formvalue('cbid.firewall.cfg' .. v .. '.src_dport')

                    -- Create our anon section
                    local section = self:create()

                    if section then
                        self.map.uci:set("firewall", section, "name", name)
                        self.map.uci:set("firewall", section, "enabled", "1")
                        self.map.uci:set("firewall", section, "custom", "1")
                        self.map.uci:set("firewall", section, "proto", proto)
                        self.map.uci:set("firewall", section, "dest_port", dport)
                        self.map.uci:set("firewall", section, "dest_ip", dip)
                        self.map.uci:set("firewall", section, "src_dport", toport)

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